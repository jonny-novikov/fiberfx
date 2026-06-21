# FORK.md — echo_graft

`echo_graft` is a hard fork of **Graft** (`orbitinghail/graft`, MIT OR Apache-2.0), vendored into
this workspace and re-seamed for the EchoMQ platform. This file records the provenance and every
divergence from upstream so fixes stay cherry-pickable.

## Upstream basis

- **Source:** https://github.com/orbitinghail/graft
- **Pinned commit:** `b07d9312dfdccc0c2de3c49fab890381d3436e0e` (2026-06-17)
- **License:** MIT OR Apache-2.0 (retained — see `LICENSE-MIT`, `LICENSE-APACHE`)
- **Local reference checkout:** `github.local/graft` (kept pristine as the cherry-pick source)

Upstream licenses at the repo level (no per-file SPDX headers); this fork preserves that convention —
the `LICENSE-*` files + the workspace `license = "MIT OR Apache-2.0"` field. No per-file headers were added.

## What was vendored (eg.1)

Copied from the pinned reference, renamed under the fork's identity:

| Upstream crate | Fork crate | Role |
|---|---|---|
| `graft` | `echo_graft` | the Volume runtime (core, local Fjall store, opendal remote, rt) |
| `graft-tracing` | `echo_graft_tracing` | tracing setup helper (test/antithesis) |
| `graft-test` | `echo_graft_test` | Volume/transaction parity test harness + integration tests |

Dependency versions are pinned via the vendored `Cargo.lock` (incl. `opendal` @ `06f088d9`).

## What was removed (the SQLite extension)

The one part the platform rejected (no SQLite/C-binding path). Not vendored:

- `graft-ext` (`libgraft_ext`, the cdylib SQLite extension) and `graft-sqlite` (the VFS + pragma logic).
- The SQLite-coupled parts of `graft-test`: `src/workload.rs` (the rusqlite bank workload),
  `src/bin/test_client.rs`, and the integration tests that drive the engine *through* the VFS
  (`tests/sqlite.rs`, `tests/remote_commit_faults.rs`, `tests/workload_sanity.rs`).
- The SQLite tooling/fixtures (`tasks/sqlite`, `tests/sql`, `datasets/*.sql`, `DEMO.md`,
  `sqlite-dist.toml`, `sqlpkg.json`) and the `sqlite-plugin`/`rusqlite` workspace deps.

Consequence: upstream Volume/transaction tests exercised only through the SQLite workload do not survive.
The parity baseline is carried by the engine's inline `#[test]`s + the two pure-Volume integration tests
(`verify_snapshot`, `verify_soft_truncate`) + the eg.1-added direct concurrent-commit tests
(`echo_graft_test/tests/concurrent_commit.rs`).

## Build patches (divergence points to re-apply on cherry-pick)

1. **`crates/echo_graft/src/remote.rs` — `tcp_user_timeout` cfg-gate.** `reqwest`'s `tcp_user_timeout`
   maps to the Linux `TCP_USER_TIMEOUT` socket option and is only compiled on Linux/Android; it is
   `cfg`-gated so the fork builds on macOS (a named build target). Upstream Linux behavior is preserved
   verbatim.

## Structural divergences (vs. the eg.1 spec sketch)

- **No `echo_graft_remote` crate.** Upstream's remote is a module (`echo_graft::remote`) backed by
  **opendal** (`RemoteConfig::{Memory, Fs, S3Compatible}` over an `opendal::Operator`), not an extractable
  trait. Splitting it out would force a core/remote/runtime restructure the rung does not require; it stays
  in-crate. (eg.2 points `S3Compatible` at Tigris via `AWS_ENDPOINT_URL`; the commit fence already exists as
  `RemoteErr::precondition_failed` ⇒ `opendal::ErrorKind::ConditionNotMatch`.)
- **Remote backend is opendal, not `object_store`** (the integration sketch predates the upstream switch).

## What was added (eg.2 — remote fence & sync proof)

eg.2 is a **verification** rung: the remote seam (opendal `Remote`) was carried whole in eg.1, so eg.2 proves it rather than reimplementing it. Additions, all additive over the frozen carry:

- **`crates/echo_graft/src/remote.rs` — `Remote::testutil_list(prefix)`** (gated `#[cfg(feature = "testutil")]`): a recursive object lister so the suite can assert remote object counts (one segment per rolled-up push; one commit at a contested LSN). Not compiled into production builds.
- **`crates/echo_graft_test/src/lib.rs` — `GraftTestRuntime::remote()`**: exposes the harness's `Arc<Remote>` so a test can inspect what landed in object storage after a push.
- **`crates/echo_graft_test/tests/remote_fence.rs`**: the conditional-write fence (criterion #1) + provider conformance (#6), run against opendal `Memory` **and** `Fs`, with an env-gated (`ECHO_GRAFT_TEST_S3_BUCKET` + `AWS_ENDPOINT_URL`) live MinIO/Tigris leg (#5).
- **`crates/echo_graft_test/tests/remote_sync.rs`**: push-with-rollup → one segment of latest pages (#2), lazy pull to head (#3), ≤64-page Zstd framing through the push path (#4), the end-to-end sync-then-race fence (#1), and Fs backend-parity (#5).
- **`crates/echo_graft_test/Cargo.toml`**: `tempfile` added (the Fs-backend temp root).

Verified ground truths (pinned `opendal@06f088d`, do not re-derive): `Memory` and `Fs` both declare `write_with_if_not_exists` and return `ErrorKind::ConditionNotMatch` on collision (Memory = compare-and-set, Fs = `O_EXCL`) — the same conditional-create contract as `S3`. No `Remote`/`RemoteCommit` byte changes; the engine fence path is unchanged from upstream.
