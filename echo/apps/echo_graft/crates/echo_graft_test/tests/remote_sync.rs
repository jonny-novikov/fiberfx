//! eg.2 — the remote sync path: push-with-rollup, lazy pull, segment framing,
//! and the end-to-end multi-writer fence, driven through the real
//! `volume_push` / `volume_pull` engine surface (the carried Graft runtime).
//!
//! Where `remote_fence.rs` exercises the conditional write directly at the
//! `Remote` layer, this suite proves the *engine* consequences against object
//! storage:
//!   * #2 — M local commits roll up into exactly one remote segment holding
//!     only the latest version of each page.
//!   * #3 — a fresh reader pulls the head and faults pages in on demand.
//!   * #4 — an uploaded segment caps frames at 64 pages and Zstd-compresses them.
//!   * #1 — two writers racing the same remote LSN resolve to a single history.
//!   * #5 — the whole path is backend-independent: every scenario runs against
//!     the in-process Memory backend AND (env-gated) against **live Tigris**,
//!     proving "repoint at Tigris is configuration, not code." A backend-parity
//!     leg on Fs rounds out the in-process coverage.
//!
//! Each scenario is a backend-agnostic `run_*` helper exercised twice: a Memory
//! entrypoint that always runs, and a `live_s3` entrypoint that runs the same
//! assertions against Tigris when `ECHO_GRAFT_TEST_S3_BUCKET` (+ `AWS_ENDPOINT_URL`
//! / `AWS_*`) is set, else skips. Remote object inspection runs via
//! `GraftTestRuntime::on_remote`, on the harness's own runtime, so a live
//! backend's connection pool / DNS resolver are reused.

use std::sync::Arc;

use echo_graft::{
    core::{LogId, PageIdx, lsn::LSN, page::Page},
    pageidx,
    remote::RemoteConfig,
    volume_reader::VolumeRead,
    volume_writer::VolumeWrite,
};
use echo_graft_test::GraftTestRuntime;

// ---------------------------------------------------------------------------
// Scenario bodies — backend-agnostic; the caller supplies a Memory, Fs, or
// live-Tigris-backed runtime.
// ---------------------------------------------------------------------------

/// #2 — three local commits over a two-page set (page 1 written twice) push into
/// exactly one remote segment carrying only the latest version of each distinct
/// page (two pages, not three writes).
fn run_push_rollup(rt: &GraftTestRuntime) -> anyhow::Result<()> {
    let remote_log = LogId::random();
    let vid = rt.volume_open(None, None, Some(remote_log.clone()))?.vid;

    let mut w = rt.volume_writer(vid.clone())?;
    w.write_page(pageidx!(1), Page::test_filled(0xA1))?;
    w.commit()?;
    let mut w = rt.volume_writer(vid.clone())?;
    w.write_page(pageidx!(1), Page::test_filled(0xB2))?; // newest version of page 1
    w.commit()?;
    let mut w = rt.volume_writer(vid.clone())?;
    w.write_page(pageidx!(2), Page::test_filled(0xC3))?;
    w.commit()?;

    // one push rolls all three local commits into one remote commit + segment
    rt.volume_push(vid.clone())?;

    let remote = rt.remote();
    let segments = rt.on_remote(remote.testutil_list("segments/"))?;
    assert_eq!(
        segments.len(),
        1,
        "M local commits roll up to exactly one remote segment, got {segments:?}"
    );

    // the remote commit (first push -> remote LSN::FIRST) references only the
    // two distinct pages, deduplicated to their latest versions
    let commit = rt
        .on_remote(remote.get_commit(&remote_log, LSN::FIRST))?
        .expect("a remote commit at LSN::FIRST after push");
    let idx = commit.segment_idx.as_ref().expect("commit references a segment");
    assert_eq!(
        idx.pageset().iter().count(),
        2,
        "the segment holds the 2 distinct pages, not the 3 individual writes"
    );

    // content proof: a fresh peer pulling the remote sees the LATEST values
    let peer = rt.spawn_peer();
    let pvid = peer.volume_open(None, None, Some(remote_log.clone()))?.vid;
    peer.volume_pull(pvid.clone())?;
    let reader = peer.volume_reader(pvid.clone())?;
    assert_eq!(reader.read_page(pageidx!(1))?, Page::test_filled(0xB2), "newest page 1");
    assert_eq!(reader.read_page(pageidx!(2))?, Page::test_filled(0xC3), "page 2");
    peer.shutdown().unwrap();
    Ok(())
}

/// #3 — a remote log ahead by K commits is observed by a fresh reader after a
/// single pull: it reaches the head and faults each page in on read (pull
/// streams commit metadata; pages are fetched lazily from the segment).
fn run_fresh_reader_pull(rt: &GraftTestRuntime) -> anyhow::Result<()> {
    let remote_log = LogId::random();
    let vid = rt.volume_open(None, None, Some(remote_log.clone()))?.vid;

    const K: u32 = 5;
    for i in 1..=K {
        let mut w = rt.volume_writer(vid.clone())?;
        w.write_page(PageIdx::try_from(i).unwrap(), Page::test_filled(i as u8))?;
        w.commit()?;
        rt.volume_push(vid.clone())?;
    }

    // a fresh peer pulls once ...
    let peer = rt.spawn_peer();
    let pvid = peer.volume_open(None, None, Some(remote_log.clone()))?.vid;
    peer.volume_pull(pvid.clone())?;

    // ... observes a head (it reached the end of the remote log) ...
    let has_head = peer.volume_snapshot(&pvid)?.head().is_some();
    assert!(has_head, "the fresh reader observes the remote head after pull");

    // ... and reads any page on demand, faulting it from the remote at read time
    let reader = peer.volume_reader(pvid.clone())?;
    for i in 1..=K {
        assert_eq!(
            reader.read_page(PageIdx::try_from(i).unwrap())?,
            Page::test_filled(i as u8),
            "page {i} faulted in on demand"
        );
    }
    peer.shutdown().unwrap();
    Ok(())
}

/// #4 — an uploaded segment caps each frame at 64 pages and Zstd-compresses it.
/// The 64-page cap is the const `FRAME_MAX_PAGES`, so the bound is
/// scale-independent (the carried `segment::test::test_segment` covers the exact
/// 64/96 boundary at the builder). Proven end-to-end through the push path: 130
/// pages must split into ceil(130/64) = 3 frames, and the segment bytes must
/// begin with the Zstd magic.
fn run_segment_framing(rt: &GraftTestRuntime) -> anyhow::Result<()> {
    let remote_log = LogId::random();
    let vid = rt.volume_open(None, None, Some(remote_log.clone()))?.vid;

    const N: u32 = 130; // ceil(130 / 64) == 3 frames
    let mut w = rt.volume_writer(vid.clone())?;
    for i in 1..=N {
        w.write_page(PageIdx::try_from(i).unwrap(), Page::test_filled((i % 251) as u8))?;
    }
    w.commit()?;
    rt.volume_push(vid.clone())?;

    let remote = rt.remote();
    let commit = rt
        .on_remote(remote.get_commit(&remote_log, LSN::FIRST))?
        .expect("a remote commit at LSN::FIRST after push");
    let idx = commit.segment_idx.as_ref().expect("commit references a segment");

    let frame_count = idx.iter_frames(|_| true).count();
    assert_eq!(
        frame_count, 3,
        "130 pages split into ceil(130/64) = 3 frames; a frame over the 64 cap would yield fewer"
    );

    // the uploaded segment bytes are a Zstd stream (magic 0x28 B5 2F FD)
    let head = rt.on_remote(remote.get_segment_range(idx.sid(), 0..4))?;
    assert_eq!(
        &head[..4],
        &[0x28, 0xB5, 0x2F, 0xFD],
        "segment frames are Zstd-compressed"
    );
    Ok(())
}

/// #1 (end to end) — the engine's multi-writer fence is *sync then race*: two
/// writers that share a sync point both build a commit on it and push to the
/// same next remote LSN. The conditional write fences them — exactly one commit
/// lands at the contested LSN, and a fresh reader sees the winner's value. (A
/// never-synced volume may not blind-push to a non-empty remote; that is an
/// engine invariant, so the realistic race is established via a pull.)
fn run_concurrent_race(rt: &GraftTestRuntime) -> anyhow::Result<()> {
    let remote_log = LogId::random();
    let vid1 = rt.volume_open(None, None, Some(remote_log.clone()))?.vid;
    let vid2 = rt.volume_open(None, None, Some(remote_log.clone()))?.vid;

    // vid1 seeds the remote at LSN 1, then vid2 pulls to share that sync point
    let mut w1 = rt.volume_writer(vid1.clone())?;
    w1.write_page(pageidx!(1), Page::test_filled(0x01))?;
    w1.commit()?;
    rt.volume_push(vid1.clone())?; // remote LSN 1
    rt.volume_pull(vid2.clone())?; // vid2 now synced at LSN 1

    // both writers stage a different value for page 1 atop the shared LSN-1 base;
    // each will target remote LSN 2 on push
    let mut w1 = rt.volume_writer(vid1.clone())?;
    w1.write_page(pageidx!(1), Page::test_filled(0x11))?;
    w1.commit()?;
    let mut w2 = rt.volume_writer(vid2.clone())?;
    w2.write_page(pageidx!(1), Page::test_filled(0x22))?;
    w2.commit()?;

    // vid1 wins the conditional commit at remote LSN 2
    rt.volume_push(vid1.clone())?;
    // vid2 races the same LSN from its now-stale base; the conditional write
    // loses and the engine takes the recovery branch. We assert the invariant,
    // not the loser's exact surfaced variant.
    let _losing = rt.volume_push(vid2.clone());

    // the remote log holds exactly two commits (LSN 1, LSN 2) — the fence
    // prevented vid2 from appending a divergent third
    let remote = rt.remote();
    let commits =
        rt.on_remote(remote.testutil_list(&format!("logs/{}/commits/", remote_log.serialize())))?;
    assert_eq!(
        commits.len(),
        2,
        "the fence keeps a single commit at the contested LSN (LSN 1 + LSN 2 only), got {commits:?}"
    );

    // a fresh reader converges on the winner's value at the head
    let peer = rt.spawn_peer();
    let pvid = peer.volume_open(None, None, Some(remote_log.clone()))?.vid;
    peer.volume_pull(pvid.clone())?;
    let reader = peer.volume_reader(pvid.clone())?;
    assert_eq!(
        reader.read_page(pageidx!(1))?,
        Page::test_filled(0x11),
        "the winner's value is the one durable history at the contested LSN"
    );
    peer.shutdown().unwrap();
    Ok(())
}

/// Skip a live-Tigris leg cleanly when the backend isn't configured.
macro_rules! live_or_skip {
    ($tag:expr) => {
        match GraftTestRuntime::live_s3($tag) {
            Some(rt) => rt,
            None => {
                eprintln!(
                    "skipping live S3/Tigris leg '{}': set ECHO_GRAFT_TEST_S3_BUCKET \
                     (+ AWS_ENDPOINT_URL and AWS_* creds) to run it",
                    $tag
                );
                return Ok(());
            }
        }
    };
}

// ---------------------------------------------------------------------------
// #2 — push rollup
// ---------------------------------------------------------------------------

#[test]
fn test_push_rolls_up_to_a_single_segment_with_latest_pages() -> anyhow::Result<()> {
    echo_graft_test::ensure_test_env();
    let rt = GraftTestRuntime::with_memory_remote();
    run_push_rollup(&rt)?;
    rt.shutdown().unwrap();
    Ok(())
}

#[test]
fn test_push_rollup_on_tigris() -> anyhow::Result<()> {
    echo_graft_test::ensure_test_env();
    let rt = live_or_skip!("rollup");
    run_push_rollup(&rt)?;
    rt.shutdown().unwrap();
    Ok(())
}

// ---------------------------------------------------------------------------
// #3 — lazy pull
// ---------------------------------------------------------------------------

#[test]
fn test_fresh_reader_pulls_head_and_reads_pages_on_demand() -> anyhow::Result<()> {
    echo_graft_test::ensure_test_env();
    let rt = GraftTestRuntime::with_memory_remote();
    run_fresh_reader_pull(&rt)?;
    rt.shutdown().unwrap();
    Ok(())
}

#[test]
fn test_fresh_reader_pull_on_tigris() -> anyhow::Result<()> {
    echo_graft_test::ensure_test_env();
    let rt = live_or_skip!("pull");
    run_fresh_reader_pull(&rt)?;
    rt.shutdown().unwrap();
    Ok(())
}

// ---------------------------------------------------------------------------
// #4 — segment framing
// ---------------------------------------------------------------------------

#[test]
fn test_pushed_segment_frames_cap_at_64_pages_and_are_zstd() -> anyhow::Result<()> {
    echo_graft_test::ensure_test_env();
    let rt = GraftTestRuntime::with_memory_remote();
    run_segment_framing(&rt)?;
    rt.shutdown().unwrap();
    Ok(())
}

#[test]
fn test_segment_framing_on_tigris() -> anyhow::Result<()> {
    echo_graft_test::ensure_test_env();
    let rt = live_or_skip!("framing");
    run_segment_framing(&rt)?;
    rt.shutdown().unwrap();
    Ok(())
}

// ---------------------------------------------------------------------------
// #1 — end-to-end multi-writer fence (sync-then-race)
// ---------------------------------------------------------------------------

#[test]
fn test_concurrent_push_to_same_remote_lsn_keeps_a_single_history() -> anyhow::Result<()> {
    echo_graft_test::ensure_test_env();
    let rt = GraftTestRuntime::with_memory_remote();
    run_concurrent_race(&rt)?;
    rt.shutdown().unwrap();
    Ok(())
}

#[test]
fn test_concurrent_race_on_tigris() -> anyhow::Result<()> {
    echo_graft_test::ensure_test_env();
    let rt = live_or_skip!("race");
    run_concurrent_race(&rt)?;
    rt.shutdown().unwrap();
    Ok(())
}

// ---------------------------------------------------------------------------
// #5 — backend parity on Fs (the full path on a non-Memory in-process backend)
// ---------------------------------------------------------------------------

/// The full push/pull path is backend-independent: the same engine code, pointed
/// at the on-disk Fs backend instead of Memory, completes a round trip. With
/// Memory, Fs, and (env-gated) Tigris all driven by the same `RemoteConfig`-
/// selected operator, "repoint at Tigris" is configuration only.
#[test]
fn test_full_sync_path_is_backend_independent_on_fs() -> anyhow::Result<()> {
    echo_graft_test::ensure_test_env();

    let root = tempfile::tempdir().expect("tempdir for fs remote");
    let remote = Arc::new(
        RemoteConfig::Fs {
            root: root.path().to_string_lossy().into_owned(),
        }
        .build()
        .expect("build fs remote"),
    );

    let rt = GraftTestRuntime::with_remote(remote);
    let remote_log = LogId::random();
    let vid = rt.volume_open(None, None, Some(remote_log.clone()))?.vid;

    let mut w = rt.volume_writer(vid.clone())?;
    w.write_page(pageidx!(1), Page::test_filled(0x5A))?;
    w.write_page(pageidx!(2), Page::test_filled(0x6B))?;
    w.commit()?;
    rt.volume_push(vid.clone())?;

    let peer = rt.spawn_peer();
    let pvid = peer.volume_open(None, None, Some(remote_log.clone()))?.vid;
    peer.volume_pull(pvid.clone())?;
    let reader = peer.volume_reader(pvid.clone())?;
    assert_eq!(reader.read_page(pageidx!(1))?, Page::test_filled(0x5A));
    assert_eq!(reader.read_page(pageidx!(2))?, Page::test_filled(0x6B));

    peer.shutdown().unwrap();
    rt.shutdown().unwrap();
    Ok(())
}
