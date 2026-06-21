//! eg.2 — the remote conditional-write fence & provider conformance.
//!
//! The multi-writer fence is `Remote::put_commit`'s conditional create
//! (`WriteOptions { if_not_exists: true }`). opendal maps that one code path to
//! an in-memory compare-and-set (Memory), an `O_EXCL` create (Fs), or
//! `If-None-Match: *` (S3/Tigris) — three providers, one contract. On a losing
//! race the provider returns `ErrorKind::ConditionNotMatch`, which the engine
//! surfaces as `RemoteErr::precondition_failed()`.
//!
//! Mapping to the eg.2 acceptance criteria:
//!   * #1 — two writers race the same commit key; exactly one wins, the other
//!     is rejected, and the log holds a single commit at that LSN.
//!   * #5 — the fence holds identically on Memory and Fs, so repointing at
//!     Tigris (`RemoteConfig::S3Compatible`) changes only configuration; the
//!     live leg is env-gated below.
//!   * #6 — a provider that fails to honor the condition is caught *loudly*
//!     (the assertions below fail) rather than silently losing the fence.
//!
//! The in-process backends faithfully implement S3's conditional-create
//! contract — verified against the pinned opendal source (`Memory`/`Fs` both
//! declare `write_with_if_not_exists` and return `ConditionNotMatch`). This
//! matches upstream Graft's own posture: its suite stands up no live S3 either.

use echo_graft::{
    core::{LogId, PageCount, commit::Commit, lsn::LSN},
    remote::{Remote, RemoteConfig},
};

/// Two writers race the same commit key `(log, LSN::FIRST)`. The first
/// conditional write wins; the second is rejected with a precondition failure;
/// and `get_commit` shows the winner's single commit preserved at that LSN.
///
/// This doubles as the acceptance #6 conformance probe: were the provider to
/// silently ignore the condition, the second `put_commit` would succeed (or
/// overwrite), and the `is_err()` / winner-preserved assertions would fail
/// loudly — exactly the "fail loudly rather than silently lose the fence"
/// guarantee.
async fn assert_conditional_commit_fence(remote: &Remote) {
    let log = LogId::random();

    // Writer A claims (log, FIRST), tagged with page_count = 1.
    let commit_a = Commit::new(log.clone(), LSN::FIRST, PageCount::new(1));
    remote
        .put_commit(&commit_a)
        .await
        .expect("the first conditional commit must win");

    // Writer B races the SAME key with a DIFFERENT commit (page_count = 2).
    let commit_b = Commit::new(log.clone(), LSN::FIRST, PageCount::new(2));
    let losing = remote.put_commit(&commit_b).await;

    assert!(
        losing.is_err(),
        "CONFORMANCE FAILURE: the provider accepted a second write to an \
         existing commit key — it is silently losing the multi-writer fence \
         (If-None-Match / if_not_exists not honored)"
    );
    assert!(
        losing.unwrap_err().precondition_failed(),
        "the losing write must surface as a precondition failure (ConditionNotMatch)"
    );

    // The log holds exactly the winner's commit at the contested LSN.
    let got = remote
        .get_commit(&log, LSN::FIRST)
        .await
        .expect("get_commit must succeed")
        .expect("a commit must exist at the contested LSN");
    assert_eq!(
        got, commit_a,
        "the winner (A) must be preserved verbatim; the loser (B) must not overwrite"
    );
    assert_eq!(got.page_count, PageCount::new(1), "winner's page_count, not the loser's");
}

/// Acceptance #1 / #6 against the in-memory backend (the deterministic default).
#[tokio::test]
async fn test_conditional_commit_fence_memory() {
    let remote = RemoteConfig::Memory.build().expect("build memory remote");
    assert_conditional_commit_fence(&remote).await;
}

/// Acceptance #5 / #6 against the on-disk backend. Fs realizes the same
/// conditional-create contract via `O_EXCL` — a structurally different mechanism
/// from Memory's compare-and-set. The fence passing on both is evidence the
/// guard is the *contract*, not a backend accident, and that repointing the
/// endpoint at Tigris changes only configuration, not code.
#[tokio::test]
async fn test_conditional_commit_fence_fs() {
    let root = tempfile::tempdir().expect("tempdir for fs remote");
    let remote = RemoteConfig::Fs {
        root: root.path().to_string_lossy().into_owned(),
    }
    .build()
    .expect("build fs remote");
    assert_conditional_commit_fence(&remote).await;
}

/// Acceptance #5 (the live leg): the identical fence against MinIO/Tigris,
/// reached by pointing `AWS_ENDPOINT_URL` + the standard `AWS_*` credentials at
/// the provider and naming a bucket via `ECHO_GRAFT_TEST_S3_BUCKET`. Skipped
/// (not failed) when unconfigured — the in-process legs above prove the same
/// contract, and this leg asserts only that "the endpoint is the only
/// difference." Uses a per-process key prefix so a re-run never collides with a
/// prior run's objects (which would itself trip the fence).
#[tokio::test]
async fn test_conditional_commit_fence_s3_compatible_when_configured() {
    let Ok(bucket) = std::env::var("ECHO_GRAFT_TEST_S3_BUCKET") else {
        eprintln!(
            "skipping live S3/Tigris fence leg: set ECHO_GRAFT_TEST_S3_BUCKET \
             (+ AWS_ENDPOINT_URL and AWS_* creds) to exercise it"
        );
        return;
    };
    let remote = RemoteConfig::S3Compatible {
        bucket,
        prefix: Some(format!("echo-graft-eg2-fence/{}", std::process::id())),
    }
    .build()
    .expect("build s3-compatible remote");
    assert_conditional_commit_fence(&remote).await;
}
