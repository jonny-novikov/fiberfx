//! eg.3 — branded-ID identity & the `EchoMQ` change-feed, driven through the real
//! engine surface (`volume_open_branded` / `resolve_branded` / `volume_push` +
//! `Runtime::feed`).
//!
//! Criteria proven here (the byte-frozen event encoding, #5, is an inline test in
//! `echo_graft::feed` where the bilrost codec lives):
//!   * #1 — a branded Volume id resolves to the internal Volume and round-trips.
//!   * #2 — a durable commit publishes exactly one feed event at the commit LSN,
//!     and only after the commit is durable (a local commit publishes nothing).
//!   * #3 — a subscriber reconnecting with a last-seen LSN replays every later
//!     event, monotone and gap-free.
//!   * #4 — two Volumes committing concurrently keep per-Volume LSN-monotone feeds
//!     (cross-Volume interleaving allowed).
//!   * #6 — a commit that loses the conditional write publishes no event.

use echo_graft::{
    core::{LogId, page::Page},
    identity::BrandedId,
    pageidx,
    volume_writer::VolumeWrite,
};
use echo_graft_test::{GraftTestRuntime, ensure_test_env};

const VOL_A: &str = "VOL0O5fmcxbds8";
const VOL_B: &str = "VOLaaaaaaaaaaa";

fn branded(s: &str) -> BrandedId {
    BrandedId::parse(s).expect("valid branded id")
}

/// #1 — branded id ↔ internal Volume, resolved and round-tripped.
#[test]
fn branded_volume_resolves_and_round_trips() -> anyhow::Result<()> {
    ensure_test_env();
    let rt = GraftTestRuntime::with_memory_remote();
    let id = branded(VOL_A);

    // unknown until opened
    assert_eq!(rt.resolve_branded(&id)?, None);

    let vol = rt.volume_open_branded(&id, None, None)?;
    let vid = vol.vid.clone();
    assert_eq!(vol.branded_id(), Some(VOL_A));

    // resolves to the same native id, and re-opening returns the same Volume
    assert_eq!(rt.resolve_branded(&id)?, Some(vid.clone()));
    let reopened = rt.volume_open_branded(&id, None, None)?;
    assert_eq!(reopened.vid, vid);
    assert_eq!(reopened.branded_id(), Some(VOL_A));
    Ok(())
}

/// #2 — a durable commit publishes exactly one event, gated on durability.
#[test]
fn durable_commit_publishes_one_feed_event() -> anyhow::Result<()> {
    ensure_test_env();
    let rt = GraftTestRuntime::with_memory_remote();
    let id = branded(VOL_A);
    let vid = rt.volume_open_branded(&id, None, None)?.vid;

    assert!(rt.feed().is_empty(VOL_A));

    let mut w = rt.volume_writer(vid.clone())?;
    w.write_page(pageidx!(1), Page::test_filled(0xA1))?;
    w.commit()?; // local commit — NOT durable
    assert!(
        rt.feed().is_empty(VOL_A),
        "a local commit must not publish a feed event"
    );

    rt.volume_push(vid)?; // the durable, conditional-write commit

    let events = rt.feed().all(VOL_A);
    assert_eq!(events.len(), 1, "exactly one event for the durable commit");
    assert_eq!(events[0].volume_branded_id, VOL_A);
    assert_eq!(events[0].lsn, 1, "the first remote commit is LSN 1");
    Ok(())
}

/// #3 — replay from a last-seen LSN is monotone and gap-free.
#[test]
fn feed_replays_from_last_seen_lsn() -> anyhow::Result<()> {
    ensure_test_env();
    let rt = GraftTestRuntime::with_memory_remote();
    let id = branded(VOL_A);
    let vid = rt.volume_open_branded(&id, None, None)?.vid;

    for i in 1..=5u8 {
        let mut w = rt.volume_writer(vid.clone())?;
        w.write_page(pageidx!(1), Page::test_filled(i))?;
        w.commit()?;
        rt.volume_push(vid.clone())?;
    }

    let all: Vec<u64> = rt.feed().all(VOL_A).iter().map(|e| e.lsn).collect();
    assert_eq!(all, vec![1, 2, 3, 4, 5]);

    // a subscriber that last saw LSN 2 catches up with 3,4,5 — no gaps, in order
    let caught_up: Vec<u64> = rt.feed().events_since(VOL_A, 2).iter().map(|e| e.lsn).collect();
    assert_eq!(caught_up, vec![3, 4, 5]);
    Ok(())
}

/// #4 — two Volumes committing concurrently keep per-Volume monotone feeds.
#[test]
fn concurrent_volumes_have_per_volume_monotone_feeds() -> anyhow::Result<()> {
    ensure_test_env();
    let rt = GraftTestRuntime::with_memory_remote();
    let va = rt.volume_open_branded(&branded(VOL_A), None, None)?.vid;
    let vb = rt.volume_open_branded(&branded(VOL_B), None, None)?.vid;

    // interleave pushes across the two Volumes
    for i in 1..=3u8 {
        for vid in [&va, &vb] {
            let mut w = rt.volume_writer(vid.clone())?;
            w.write_page(pageidx!(1), Page::test_filled(i))?;
            w.commit()?;
            rt.volume_push(vid.clone())?;
        }
    }

    for id_str in [VOL_A, VOL_B] {
        let events = rt.feed().all(id_str);
        let lsns: Vec<u64> = events.iter().map(|e| e.lsn).collect();
        assert_eq!(lsns, vec![1, 2, 3], "each Volume's feed is LSN-monotone");
        assert!(
            events.iter().all(|e| e.volume_branded_id == id_str),
            "every event carries its own Volume's branded id"
        );
    }
    Ok(())
}

/// #6 — a lost conditional write publishes no event (sync-then-race fence).
#[test]
fn lost_conditional_write_publishes_no_event() -> anyhow::Result<()> {
    ensure_test_env();
    let rt = GraftTestRuntime::with_memory_remote();
    let shared_remote = LogId::random();

    // writer A: branded against the shared remote, commits + pushes LSN 1
    let va = rt
        .volume_open_branded(&branded(VOL_A), None, Some(shared_remote.clone()))?
        .vid;
    {
        let mut w = rt.volume_writer(va.clone())?;
        w.write_page(pageidx!(1), Page::test_filled(0x11))?;
        w.commit()?;
    }
    rt.volume_push(va.clone())?;
    let a_lsns: Vec<u64> = rt.feed().all(VOL_A).iter().map(|e| e.lsn).collect();
    assert_eq!(a_lsns, vec![1]);

    // writer B (a peer on its own feed): pull to sync, then write from that base
    let peer = rt.spawn_peer();
    let vb = peer
        .volume_open_branded(&branded(VOL_B), None, Some(shared_remote))?
        .vid;
    peer.volume_pull(vb.clone())?; // sync to remote LSN 1
    {
        let mut w = peer.volume_writer(vb.clone())?;
        w.write_page(pageidx!(2), Page::test_filled(0x22))?;
        w.commit()?;
    }

    // A wins the next remote slot (LSN 2)
    {
        let mut w = rt.volume_writer(va.clone())?;
        w.write_page(pageidx!(3), Page::test_filled(0x33))?;
        w.commit()?;
    }
    rt.volume_push(va)?;
    let a_lsns: Vec<u64> = rt.feed().all(VOL_A).iter().map(|e| e.lsn).collect();
    assert_eq!(a_lsns, vec![1, 2]);

    // B races the same LSN and loses the conditional write → no event published
    let result = peer.volume_push(vb);
    assert!(
        result.is_err(),
        "the losing writer's push must fail, got {result:?}"
    );
    assert!(
        peer.feed().is_empty(VOL_B),
        "a lost conditional write publishes no feed event"
    );
    Ok(())
}
