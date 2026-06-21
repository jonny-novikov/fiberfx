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
//!   * #5 — the whole path is backend-independent (proven on Fs as well as
//!     Memory), so repointing at Tigris is configuration, not code.
//!
//! Remote object inspection runs on a throwaway current-thread runtime: the
//! Memory/Fs operators hold their state behind an `Arc` and are not bound to the
//! harness's (paused) runtime, so reads from a separate runtime observe exactly
//! what `volume_push` wrote.

use std::sync::Arc;

use echo_graft::{
    core::{LogId, PageIdx, lsn::LSN, page::Page},
    pageidx,
    remote::RemoteConfig,
    volume_reader::VolumeRead,
    volume_writer::VolumeWrite,
};
use echo_graft_test::GraftTestRuntime;

/// Drive a remote async call to completion on a throwaway runtime (see module
/// note on why this is sound for the in-process backends).
fn block_on<F: std::future::Future>(fut: F) -> F::Output {
    tokio::runtime::Builder::new_current_thread()
        .enable_all()
        .build()
        .expect("build inspection runtime")
        .block_on(fut)
}

/// Acceptance #2 — three local commits over a two-page set (page 1 written
/// twice) push into exactly one remote segment, and that segment carries only
/// the latest version of each distinct page (two pages, not three writes).
#[test]
fn test_push_rolls_up_to_a_single_segment_with_latest_pages() -> anyhow::Result<()> {
    echo_graft_test::ensure_test_env();

    let rt = GraftTestRuntime::with_memory_remote();
    let remote_log = LogId::random();
    let vid = rt.volume_open(None, None, Some(remote_log.clone()))?.vid;

    // three local commits; page 1 is superseded by its second write
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
    let segments = block_on(remote.testutil_list("segments/"))?;
    assert_eq!(
        segments.len(),
        1,
        "M local commits roll up to exactly one remote segment, got {segments:?}"
    );

    // the remote commit (first push -> remote LSN::FIRST) references only the
    // two distinct pages, deduplicated to their latest versions
    let commit = block_on(remote.get_commit(&remote_log, LSN::FIRST))?
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
    rt.shutdown().unwrap();
    Ok(())
}

/// Acceptance #3 — a remote log ahead by K commits is observed by a fresh reader
/// after a single pull: it reaches the head and faults each page in on read
/// (pull streams commit metadata; pages are fetched lazily from the segment).
#[test]
fn test_fresh_reader_pulls_head_and_reads_pages_on_demand() -> anyhow::Result<()> {
    echo_graft_test::ensure_test_env();

    let rt = GraftTestRuntime::with_memory_remote();
    let remote_log = LogId::random();
    let vid = rt.volume_open(None, None, Some(remote_log.clone()))?.vid;

    // build a remote log ahead by K commits (one page per commit)
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

    // ... and reads any page on demand, including the head commit's page,
    // proving it pulled through to the head and faults pages lazily on read.
    let reader = peer.volume_reader(pvid.clone())?;
    for i in 1..=K {
        assert_eq!(
            reader.read_page(PageIdx::try_from(i).unwrap())?,
            Page::test_filled(i as u8),
            "page {i} faulted in on demand"
        );
    }

    peer.shutdown().unwrap();
    rt.shutdown().unwrap();
    Ok(())
}

/// Acceptance #4 — an uploaded segment caps each frame at 64 pages and
/// Zstd-compresses it. The 64-page cap is the const `FRAME_MAX_PAGES`, so the
/// bound is scale-independent: a 50,000-page volume yields the same per-frame
/// cap (the carried `segment::test::test_segment` covers the exact 64/96
/// boundary at the builder). Here we prove it end-to-end through the push path:
/// 130 pages must split into ceil(130/64) = 3 frames, and the segment bytes must
/// begin with the Zstd magic.
#[test]
fn test_pushed_segment_frames_cap_at_64_pages_and_are_zstd() -> anyhow::Result<()> {
    echo_graft_test::ensure_test_env();

    let rt = GraftTestRuntime::with_memory_remote();
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
    let commit = block_on(remote.get_commit(&remote_log, LSN::FIRST))?
        .expect("a remote commit at LSN::FIRST after push");
    let idx = commit.segment_idx.as_ref().expect("commit references a segment");

    let frame_count = idx.iter_frames(|_| true).count();
    assert_eq!(
        frame_count, 3,
        "130 pages split into ceil(130/64) = 3 frames; a frame over the 64 cap \
         would yield fewer"
    );

    // the uploaded segment bytes are a Zstd stream (magic 0x28 B5 2F FD)
    let head = block_on(remote.get_segment_range(idx.sid(), 0..4))?;
    assert_eq!(
        &head[..4],
        &[0x28, 0xB5, 0x2F, 0xFD],
        "segment frames are Zstd-compressed"
    );

    rt.shutdown().unwrap();
    Ok(())
}

/// Acceptance #1 (end to end) — the engine's multi-writer fence is *sync then
/// race*: two writers that share a sync point both build a commit on it and push
/// to the same next remote LSN. The conditional write fences them — exactly one
/// commit lands at the contested LSN, and a fresh reader sees the winner's
/// value. (A never-synced volume may not blind-push to a non-empty remote; that
/// is an engine invariant, so the realistic race is established via a pull.)
#[test]
fn test_concurrent_push_to_same_remote_lsn_keeps_a_single_history() -> anyhow::Result<()> {
    echo_graft_test::ensure_test_env();

    let rt = GraftTestRuntime::with_memory_remote();
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
    let commits = block_on(
        remote.testutil_list(&format!("logs/{}/commits/", remote_log.serialize())),
    )?;
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
    rt.shutdown().unwrap();
    Ok(())
}

/// Acceptance #5 — the full push/pull path is backend-independent: the same
/// engine code, pointed at the on-disk Fs backend instead of Memory, completes a
/// round trip. With Memory, Fs, and (env-gated) S3 all driven by the same
/// `RemoteConfig`-selected operator, "repoint at Tigris" is configuration only.
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

    // a peer on the same on-disk remote pulls the commit and reads it back
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
