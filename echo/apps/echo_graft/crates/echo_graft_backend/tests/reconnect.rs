//! eg.4 Step 5 — reconnect + resubscribe-from-last-seen-LSN (S-3 / criterion 3).
//!
//! The feed cursor (the client's last-seen LSN) is the recovery key. On a supervised backend
//! restart the engine + its change-feed persist (the supervisor restarts the session wrapper
//! over the same `Runtime` handle, the OTP-style restart the brief names); a reconnecting
//! client resubscribes and calls `replay_since(branded, cursor)`. The engine's
//! `events_since` (`feed.rs:69-80`) returns the strictly-greater LSNs in monotone, gap-free
//! order, so the client observes every committed LSN `> cursor` with no loss and no
//! duplication beyond at-least-once.

use std::sync::Arc;

use echo_graft::{
    identity::BrandedId,
    local::fjall_storage::FjallStorage,
    remote::RemoteConfig,
    rt::runtime::Runtime,
};
use echo_graft_backend::{Handshake, InMemorySink, Session};
use echo_graft_proto::{Mode, Msg};

const BRANDED: &str = "VOL0O5fmcxbds8";

fn test_runtime() -> (Runtime, tokio::runtime::Runtime) {
    let tokio_rt = tokio::runtime::Builder::new_current_thread()
        .start_paused(true)
        .enable_all()
        .build()
        .unwrap();
    let remote = Arc::new(RemoteConfig::Memory.build().unwrap());
    let storage = Arc::new(FjallStorage::open_temporary().unwrap());
    let rt = Runtime::new(tokio_rt.handle().clone(), remote, storage, None);
    (rt, tokio_rt)
}

/// Establish a session + open the branded Volume, returning the native vid.
fn open(rt: &Runtime) -> (Session<InMemorySink>, InMemorySink, String) {
    let sink = InMemorySink::new();
    let mut session = Session::new(rt.clone(), sink.clone());
    let (hs, _w) = session.hello(&Msg::Hello { proto_min: 2, proto_max: 2, client: "c".into() });
    assert_eq!(hs, Handshake::Established(2));
    let _ = session.handle(&Msg::OpenVolume { corr: 1, branded: BRANDED.into(), local: None, remote: None });
    let vid = rt
        .resolve_branded(&BrandedId::parse(BRANDED).unwrap())
        .unwrap()
        .unwrap()
        .to_string();
    (session, sink, vid)
}

/// Commit one page (filled with `b`) and push; returns the pushed remote head LSN.
fn commit_and_push(session: &mut Session<InMemorySink>, vid: &str, b: u8, corr: u64) -> u64 {
    let c = session.handle(&Msg::Commit { corr, vid: vid.into(), base: 0, mode: Mode::Sync, pages: vec![(1, vec![b; 4096])] });
    assert!(matches!(c, Msg::Ack { .. }), "commit: {c:?}");
    let p = session.handle(&Msg::Push { corr: corr + 100, vid: vid.into() });
    let Msg::Ack { lsn, .. } = p else { panic!("push: {p:?}") };
    lsn
}

#[test]
fn reconnect_replays_from_last_seen_lsn_no_loss_no_dup() {
    let (rt, _guard) = test_runtime();
    let (mut session, sink, vid) = open(&rt);

    // advance through three durable LSNs
    let lsn1 = commit_and_push(&mut session, &vid, 0x11, 2);
    let lsn2 = commit_and_push(&mut session, &vid, 0x22, 3);
    let lsn3 = commit_and_push(&mut session, &vid, 0x33, 4);
    assert!(lsn1 < lsn2 && lsn2 < lsn3, "LSNs advance: {lsn1} {lsn2} {lsn3}");

    // the live feed published all three (one per push)
    let lane = echo_graft::feed::lane_for(BRANDED);
    assert_eq!(sink.count_on(&lane), 3, "three live feed frames");

    // the client crashed having seen only lsn1. The supervisor restarts the session wrapper
    // over the SAME engine handle (the feed persists). The reconnecting client resubscribes
    // and replays from its last-seen cursor = lsn1.
    let mut restarted = Session::new(rt, InMemorySink::new());
    let (hs, _w) = restarted.hello(&Msg::Hello { proto_min: 2, proto_max: 2, client: "c".into() });
    assert_eq!(hs, Handshake::Established(2));

    let frames = restarted.replay_since(BRANDED, lsn1);

    // exactly the LSNs strictly after the cursor (lsn2, lsn3) — no loss, no dup, in order
    let replayed: Vec<u64> = frames
        .iter()
        .map(|f| {
            let Msg::Feed { blob } = Msg::decode(f).unwrap() else { panic!("not a feed frame") };
            use bilrost::OwnedMessage;
            echo_graft::feed::FeedEvent::decode(blob.as_slice()).unwrap().lsn
        })
        .collect();
    assert_eq!(replayed, vec![lsn2, lsn3], "replay yields exactly LSNs > cursor, monotone");

    // replaying again from the SAME cursor is idempotent in content (at-least-once: it returns
    // the same set; it never invents or skips an LSN)
    let again: Vec<u64> = restarted
        .replay_since(BRANDED, lsn1)
        .iter()
        .map(|f| {
            let Msg::Feed { blob } = Msg::decode(f).unwrap() else { panic!() };
            use bilrost::OwnedMessage;
            echo_graft::feed::FeedEvent::decode(blob.as_slice()).unwrap().lsn
        })
        .collect();
    assert_eq!(again, vec![lsn2, lsn3], "replay from the same cursor is content-stable");

    // replaying from the head cursor yields nothing (fully caught up)
    assert!(restarted.replay_since(BRANDED, lsn3).is_empty(), "caught-up replay is empty");
}

#[test]
fn replay_from_zero_yields_full_history() {
    // a fresh subscriber (cursor 0) replays the whole history in order.
    let (rt, _guard) = test_runtime();
    let (mut session, _sink, vid) = open(&rt);
    let a = commit_and_push(&mut session, &vid, 0x01, 2);
    let b = commit_and_push(&mut session, &vid, 0x02, 3);

    let mut fresh = Session::new(rt, InMemorySink::new());
    let _ = fresh.hello(&Msg::Hello { proto_min: 2, proto_max: 2, client: "c".into() });
    let frames = fresh.replay_since(BRANDED, 0);
    let lsns: Vec<u64> = frames
        .iter()
        .map(|f| {
            let Msg::Feed { blob } = Msg::decode(f).unwrap() else { panic!() };
            use bilrost::OwnedMessage;
            echo_graft::feed::FeedEvent::decode(blob.as_slice()).unwrap().lsn
        })
        .collect();
    assert_eq!(lsns, vec![a, b], "cursor 0 replays the full history");
}
