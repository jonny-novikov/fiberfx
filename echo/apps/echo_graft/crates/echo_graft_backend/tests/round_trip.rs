//! eg.4 Step 2 + Step 3 — the in-process round-trip proof (criteria 1, 2, 4).
//!
//! These drive a real `echo_graft::Runtime` (memory remote, temporary storage) through a
//! [`Session`] over the in-memory [`InMemorySink`] — no bus, no socket. They assert the
//! engine-side facts the eg.4 wire must surface end-to-end:
//!   * a commit-then-push acks the LSN and publishes a matching feed frame on
//!     `egraft:feed:{vol}` (S-1 / criterion 1);
//!   * the published frame is a `Msg::Feed` carrying the OPAQUE eg.3 `FeedEvent` blob — no
//!     re-encode (the two freeze-points compose);
//!   * two conflicting commits from the same base: one acks, the other is `conflict`
//!     (S-4 / criterion 4);
//!   * an incompatible handshake is refused and touches NO Volume (S-2 / criterion 2).

use std::sync::Arc;

use echo_graft::{
    core::{PageIdx, VolumeId, page::Page},
    feed::lane_for,
    identity::BrandedId,
    local::fjall_storage::FjallStorage,
    remote::RemoteConfig,
    rt::runtime::Runtime,
    volume_writer::VolumeWrite,
};
use echo_graft_backend::{Handshake, InMemorySink, Session, dispatch};
use echo_graft_proto::{ErrKind, Mode, Msg};
use std::str::FromStr;

const BRANDED: &str = "VOL0O5fmcxbds8";

/// Build a deterministic in-process runtime: a paused-clock current-thread tokio runtime, a
/// memory remote, and a fresh temporary store — the `runtime_sanity` construction.
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

/// A 4 KiB page filled with `b` (the engine's fixed `PAGESIZE`).
fn page(b: u8) -> Page {
    let bytes = vec![b; echo_graft::core::page::PAGESIZE.as_usize()];
    Page::try_from(bytes.as_slice()).unwrap()
}

/// Page index 1.
fn idx(i: u32) -> PageIdx {
    PageIdx::try_from(i).unwrap()
}

/// Establish a session and open a branded Volume, returning its native vid string.
fn open_session(rt: &Runtime) -> (Session<InMemorySink>, InMemorySink, String) {
    let sink = InMemorySink::new();
    let mut session = Session::new(rt.clone(), sink.clone());
    let (hs, welcome) = session.hello(&Msg::Hello {
        proto_min: 2,
        proto_max: 2,
        client: "test".into(),
    });
    assert_eq!(hs, Handshake::Established(2));
    assert!(matches!(welcome, Msg::Welcome { proto: 2 }));

    let resp = session.handle(&Msg::OpenVolume {
        corr: 1,
        branded: BRANDED.into(),
        local: None,
        remote: None,
    });
    assert!(matches!(resp, Msg::Ack { corr: 1, .. }), "open failed: {resp:?}");

    // resolve the native vid (the engine minted it)
    let branded = BrandedId::parse(BRANDED).unwrap();
    let vid = rt.resolve_branded(&branded).unwrap().expect("branded mapping").to_string();
    (session, sink, vid)
}

#[test]
fn commit_push_acks_lsn_and_publishes_feed() {
    let (rt, _guard) = test_runtime();
    let (mut session, sink, vid) = open_session(&rt);

    // commit one page
    let commit = session.handle(&Msg::Commit {
        corr: 2,
        vid: vid.clone(),
        base: 0,
        mode: Mode::Sync,
        pages: vec![(1, vec![0xAB; 4096])],
    });
    assert!(matches!(commit, Msg::Ack { corr: 2, lsn } if lsn >= 1), "commit: {commit:?}");

    // no feed yet — a local commit is not a durable advance
    assert_eq!(sink.count_on(&lane_for(BRANDED)), 0, "feed must not fire before push");

    // push: the conditional-write fence advances the remote and publishes the feed
    let push = session.handle(&Msg::Push { corr: 3, vid });
    assert!(matches!(push, Msg::Ack { corr: 3, lsn } if lsn >= 1), "push: {push:?}");

    // exactly one feed frame landed on egraft:feed:{vol}, and it is a Msg::Feed
    let published = sink.drain();
    assert_eq!(published.len(), 1, "exactly one feed frame on a single-commit push");
    assert_eq!(published[0].lane, lane_for(BRANDED));
    let decoded = Msg::decode(&published[0].frame).expect("feed frame decodes");
    let Msg::Feed { blob } = decoded else {
        panic!("expected Msg::Feed, got {decoded:?}");
    };

    // the blob is the OPAQUE eg.3 FeedEvent — decode it and confirm the LSN matches the ack
    use bilrost::OwnedMessage;
    let event = echo_graft::feed::FeedEvent::decode(blob.as_slice()).expect("opaque bilrost blob");
    assert_eq!(event.volume_branded_id, BRANDED);
    let Msg::Ack { lsn: ack_lsn, .. } = push else { unreachable!() };
    assert_eq!(event.lsn, ack_lsn, "feed event LSN matches the push ack LSN");
}

#[test]
fn no_op_push_publishes_nothing() {
    // The liveness negative (S-1 invariant): a push with no local changes advances no remote
    // LSN, so it publishes nothing.
    let (rt, _guard) = test_runtime();
    let (mut session, sink, vid) = open_session(&rt);

    let push = session.handle(&Msg::Push { corr: 9, vid });
    assert!(matches!(push, Msg::Ack { corr: 9, .. }), "push: {push:?}");
    assert_eq!(sink.count_on(&lane_for(BRANDED)), 0, "a no-op push publishes nothing");
}

#[test]
fn conflicting_commits_one_acks_one_conflicts() {
    // S-4 / criterion 4: two writers from the same base; the engine OCC fences one, and the
    // dispatch maps that fence to ErrKind::Conflict on the wire.
    let (rt, _guard) = test_runtime();
    let (_session, _sink, vid) = open_session(&rt);
    let vid_typed = VolumeId::from_str(&vid).unwrap();

    // two writers built from the SAME base snapshot (sync-then-race, README:140-144)
    let mut w1 = rt.volume_writer(vid_typed.clone()).unwrap();
    let mut w2 = rt.volume_writer(vid_typed).unwrap();
    w1.write_page(idx(1), page(0x11)).unwrap();
    w2.write_page(idx(1), page(0x22)).unwrap();

    // first commit wins
    assert!(w1.commit().is_ok(), "first commit acks");

    // second commit, from the now-stale base, loses with VolumeConcurrentWrite — the REAL
    // engine conflict (not simulated)
    let conflict = w2.commit().expect_err("second commit must conflict");
    assert!(
        matches!(
            conflict,
            echo_graft::GraftErr::Logical(echo_graft::LogicalErr::VolumeConcurrentWrite(_))
        ),
        "expected VolumeConcurrentWrite, got {conflict:?}"
    );

    // the wire surfaces that conflict as ErrKind::Conflict (the dispatch mapping, asserted
    // on the real engine error — no tautology)
    assert_eq!(
        dispatch::err_kind_of(&conflict),
        ErrKind::Conflict,
        "VolumeConcurrentWrite maps to the proto Conflict kind"
    );
}

#[test]
fn incompatible_handshake_touches_no_volume() {
    // S-2 / criterion 2: a client whose range is disjoint from [PROTO_MIN, PROTO_MAX] is
    // refused, and NO Volume is opened — the volume set is byte-identical before and after.
    let (rt, _guard) = test_runtime();
    let before: Vec<String> = rt.volume_iter().map(|v| v.unwrap().vid.to_string()).collect();

    let sink = InMemorySink::new();
    let mut session = Session::new(rt.clone(), sink.clone());
    let (hs, resp) = session.hello(&Msg::Hello {
        proto_min: 99,
        proto_max: 100,
        client: "too-new".into(),
    });
    assert_eq!(hs, Handshake::Refused);
    assert!(
        matches!(resp, Msg::Incompatible { .. }),
        "expected Incompatible, got {resp:?}"
    );
    assert!(!session.is_established());

    // a request after a refused handshake is also refused, no Volume touched
    let after_req = session.handle(&Msg::OpenVolume {
        corr: 1,
        branded: BRANDED.into(),
        local: None,
        remote: None,
    });
    assert!(
        matches!(after_req, Msg::Err { kind: ErrKind::Unavailable, .. }),
        "request before handshake must be refused: {after_req:?}"
    );

    let after: Vec<String> = rt.volume_iter().map(|v| v.unwrap().vid.to_string()).collect();
    assert_eq!(before, after, "a refused handshake must not open a Volume");
    assert_eq!(sink.drain().len(), 0, "a refused handshake publishes nothing");
}

#[test]
fn short_page_commits_and_reads_back_zero_filled() {
    // REMEDIATE-1(b): the `to_page` realization end-to-end through the dispatch. A wire page
    // shorter than PAGESIZE is right-padded to PAGESIZE, so a commit→read round-trips it as the
    // zero-filled 4 KiB page (not a panic, not a truncation).
    let (rt, _guard) = test_runtime();
    let (mut session, _sink, vid) = open_session(&rt);

    // commit a 3-byte page at index 1 through the real Commit dispatch
    let commit = session.handle(&Msg::Commit {
        corr: 2,
        vid: vid.clone(),
        base: 0,
        mode: Mode::Sync,
        pages: vec![(1, vec![0x01, 0x02, 0x03])],
    });
    assert!(matches!(commit, Msg::Ack { corr: 2, .. }), "short-page commit acks: {commit:?}");

    // read it back through the real Read dispatch — PAGESIZE bytes, prefix preserved, tail zero
    let read = session.handle(&Msg::Read { corr: 3, vid, pageidx: 1 });
    let Msg::Pages { corr: 3, data } = read else {
        panic!("expected Pages, got {read:?}");
    };
    assert_eq!(data.len(), echo_graft::core::page::PAGESIZE.as_usize(), "read-back is a full page");
    assert_eq!(&data[..3], &[0x01, 0x02, 0x03], "the supplied prefix is preserved");
    assert!(data[3..].iter().all(|&b| b == 0), "the rest is zero-filled");
}

#[test]
fn oversize_page_commit_is_unavailable_not_a_panic() {
    // REMEDIATE-1(a): an over-PAGESIZE wire page is refused through the real Commit dispatch as
    // ErrKind::Unavailable (the proto overload kind), never a panic — the anti-panic branch the
    // build pass left unexercised.
    let (rt, _guard) = test_runtime();
    let (mut session, _sink, vid) = open_session(&rt);

    let oversize = vec![0xFF_u8; echo_graft::core::page::PAGESIZE.as_usize() + 1];
    let resp = session.handle(&Msg::Commit { corr: 2, vid, base: 0, mode: Mode::Sync, pages: vec![(1, oversize)] });
    assert!(
        matches!(resp, Msg::Err { corr: 2, kind: ErrKind::Unavailable, .. }),
        "an over-PAGESIZE page maps to Unavailable, not a panic: {resp:?}"
    );
}
