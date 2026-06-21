//! eg.1 acceptance backfill — direct Volume-API tests on the Memory backend for
//! page read-back (criterion #3) and concurrent-commit conflict detection
//! (criteria #4 / #5).
//!
//! Conflict model (verified against the pinned source, `fjall_storage::commit`
//! → `is_latest_snapshot`): echo_graft's local commit OCC is **snapshot-version
//! level, not page level**. Every commit must be based on the volume's *latest*
//! snapshot; otherwise it aborts with `LogicalErr::VolumeConcurrentWrite`. So two
//! concurrent writers from the *same base* conflict on the second commit
//! **regardless of whether their pages are disjoint** — disjoint-merge is a
//! property of the remote sync layer (eg.2/eg.3), not local commit. The spec's
//! #4 wording assumed page-level resolution; `test_concurrent_disjoint_pages_
//! still_conflict` documents the real behavior. See FORK.md.

use echo_graft::{
    GraftErr, LogicalErr,
    core::{LogId, PageIdx, page::Page},
    pageidx,
    volume_reader::VolumeRead,
    volume_writer::VolumeWrite,
};
use echo_graft_test::GraftTestRuntime;

/// Acceptance #3 — a Volume with N committed pages, read at the head snapshot,
/// yields exactly those N pages (and nothing beyond).
#[test]
fn test_read_back_n_committed_pages() -> anyhow::Result<()> {
    echo_graft_test::ensure_test_env();

    const N: u32 = 8;
    let runtime = GraftTestRuntime::with_memory_remote();
    let vid = runtime.volume_open(None, None, Some(LogId::random()))?.vid;

    // write N distinct pages in a single commit
    let mut writer = runtime.volume_writer(vid.clone())?;
    for i in 1..=N {
        writer.write_page(PageIdx::try_from(i).unwrap(), Page::test_filled(i as u8))?;
    }
    writer.commit()?;

    // read them all back at the head snapshot
    let reader = runtime.volume_reader(vid.clone())?;
    for i in 1..=N {
        let page = reader.read_page(PageIdx::try_from(i).unwrap())?;
        assert_eq!(page, Page::test_filled(i as u8), "page {i} reads back exactly");
    }
    // a page that was never written is empty
    assert_eq!(reader.read_page(PageIdx::try_from(N + 1).unwrap())?, Page::EMPTY);

    runtime.shutdown().unwrap();
    Ok(())
}

/// Acceptance #4 (as the engine realizes it) — disjoint-page writes both land in
/// the log with distinct LSNs when each commit is based on the latest snapshot.
#[test]
fn test_disjoint_commits_both_succeed_with_distinct_lsns() -> anyhow::Result<()> {
    echo_graft_test::ensure_test_env();

    let runtime = GraftTestRuntime::with_memory_remote();
    let vid = runtime.volume_open(None, None, Some(LogId::random()))?.vid;

    // commit page 1
    let mut w1 = runtime.volume_writer(vid.clone())?;
    w1.write_page(pageidx!(1), Page::test_filled(1))?;
    w1.commit()?;
    let lsn1 = runtime.volume_snapshot(&vid)?.head().map(|(_, lsn)| lsn);

    // commit a DISJOINT page 2, based on the now-latest snapshot
    let mut w2 = runtime.volume_writer(vid.clone())?;
    w2.write_page(pageidx!(2), Page::test_filled(2))?;
    w2.commit()?;
    let lsn2 = runtime.volume_snapshot(&vid)?.head().map(|(_, lsn)| lsn);

    // both commits succeeded -> two distinct LSNs, both pages visible
    assert!(lsn1.is_some() && lsn2.is_some(), "both commits advanced the log");
    assert_ne!(lsn1, lsn2, "each commit advances the log to a distinct LSN");

    let reader = runtime.volume_reader(vid.clone())?;
    assert_eq!(reader.read_page(pageidx!(1))?, Page::test_filled(1));
    assert_eq!(reader.read_page(pageidx!(2))?, Page::test_filled(2));

    runtime.shutdown().unwrap();
    Ok(())
}

/// Acceptance #5 — two concurrent writers from the *same base snapshot* writing
/// the *same page*: exactly one commit succeeds, the other aborts with a conflict.
#[test]
fn test_same_page_concurrent_commit_conflicts() -> anyhow::Result<()> {
    echo_graft_test::ensure_test_env();

    let runtime = GraftTestRuntime::with_memory_remote();
    let vid = runtime.volume_open(None, None, Some(LogId::random()))?.vid;

    // two writers created from the same base snapshot, before either commits
    let mut a = runtime.volume_writer(vid.clone())?;
    let mut b = runtime.volume_writer(vid.clone())?;
    a.write_page(pageidx!(1), Page::test_filled(1))?;
    b.write_page(pageidx!(1), Page::test_filled(2))?;

    // first commit wins; the second (stale base) is rejected as a concurrent write
    a.commit()?;
    match b.commit() {
        Err(GraftErr::Logical(LogicalErr::VolumeConcurrentWrite(_))) => {}
        other => panic!("expected VolumeConcurrentWrite, got {other:?}"),
    }

    // exactly one survived: the winner's value is what's visible
    let reader = runtime.volume_reader(vid.clone())?;
    assert_eq!(reader.read_page(pageidx!(1))?, Page::test_filled(1));

    runtime.shutdown().unwrap();
    Ok(())
}

/// The engine's OCC is *version-level, not page-level*: two concurrent writers
/// from the same base conflict on the second commit even when their pages are
/// DISJOINT. Documents the divergence from the eg.1 spec's #4 wording (which
/// assumed page-level resolution). Disjoint-merge lives at the remote sync layer.
#[test]
fn test_concurrent_disjoint_pages_still_conflict() -> anyhow::Result<()> {
    echo_graft_test::ensure_test_env();

    let runtime = GraftTestRuntime::with_memory_remote();
    let vid = runtime.volume_open(None, None, Some(LogId::random()))?.vid;

    let mut a = runtime.volume_writer(vid.clone())?;
    let mut b = runtime.volume_writer(vid.clone())?;
    a.write_page(pageidx!(1), Page::test_filled(1))?;
    b.write_page(pageidx!(2), Page::test_filled(2))?; // DISJOINT page

    a.commit()?;
    match b.commit() {
        Err(GraftErr::Logical(LogicalErr::VolumeConcurrentWrite(_))) => {}
        other => panic!("expected VolumeConcurrentWrite even for a disjoint page, got {other:?}"),
    }

    runtime.shutdown().unwrap();
    Ok(())
}
