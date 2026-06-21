# echo_graft

**A from-scratch, durable + replicated backend storage engine for the EchoMQ platform.**

> **This file supersedes the former `FORK.md`.** It is both the provenance record *and* the
> standing development brief every agent reads before touching this crate.

---

## ⚠️ IMPORTANT — development direction (read first, especially Agents)

`echo_graft` is **not a maintained fork** of Graft. It is a **brand-new system, built from
scratch**, that was *seeded* from [`orbitinghail/graft`](https://github.com/orbitinghail/graft)
(a transactional, object-storage-replicated Volume engine) under its MIT licence. From here
forward the rules are:

- **NO backward compatibility with upstream Graft.** Not API-compatible, not wire-compatible,
  not cherry-pick-compatible. We do **not** track upstream and we do **not** preserve
  mergeability. Upstream is a finished reference, not a moving target we chase.
- **EXPLICIT ALLOWANCE to modify any file and break any upstream API contract** when it improves
  efficiency, correctness, or developer experience for EchoMQ. Owning the engine end-to-end is
  the entire point of the fork — never trade that away for compatibility.
- **The mission is endurance.** `echo_graft` is the platform's **durability tier**: it makes
  EchoMQ state **durable** (every commit is a transactional, conditional-write-fenced LSN append)
  and **replicated** (page-level segments over object storage, instant read replicas). It sits
  beside **Champ** (bounded-loss, in-memory) and **Oban** (strict, single-node) and fills the
  transactional-**and**-replicated quadrant neither covers.
- **The reference checkout is a read-only *idea source*, not a cherry-pick source.**
  `github.local/graft` @ `b07d9312` is kept pristine so we can *read* how upstream solved a
  problem and copy ideas (and, early on, code) FROM it. We never sync back; a later rung is free
  to diverge from it entirely.

**Working rule for every rung:** ground each change in the rung spec under `docs/graft/`
(`graft.roadmap.md` + `graft.<n>.md`). The specs are the contract; this README is the standing
direction. When upstream's shape and EchoMQ's needs disagree, **EchoMQ wins, every time.**

---

## What it is

A transactional Volume engine — an LSN-ordered commit log, segment/snapshot page data,
conditional-write commit (which doubles as the multi-writer fence), and lazy page loading —
re-seamed for this platform across six rungs (`eg.1`–`eg.6`):

- a **Tigris** (S3-compatible) remote backend over [Apache OpenDAL](https://opendal.apache.org/),
- **branded-Snowflake identity** (`{ns}{base62}`) at the external edge,
- an **EchoMQ change-feed** driven off the commit LSN,

driven as a supervised **Rust sidecar** the BEAM orchestrates over EchoMQ (RESP3) — not an in-VM
NIF (that's a deferred post-`eg.6` hot-read optimization). The full program, rung ladder, and
acceptance gates live in `docs/graft/graft.roadmap.md`.

## Upstream basis & licence (provenance, not a compatibility promise)

- **Seeded from:** https://github.com/orbitinghail/graft (MIT OR Apache-2.0)
- **Pinned reference:** `github.local/graft` @ `b07d9312dfdccc0c2de3c49fab890381d3436e0e` (read-only)
- **Licence:** MIT — attribution retained in `LICENSE-MIT` / `LICENSE-APACHE`. This is a
  **legal-provenance obligation** (the MIT permission notice travels with copied code); it is
  **not** an engineering-compatibility commitment. Licensing is repo-level (upstream carries no
  per-file SPDX headers — we add none).

## What was adopted (`eg.1`)

Seeded from the pinned reference, renamed under the `echo_graft` identity:

| Reference crate | This crate           | Role                                                             |
|-----------------|----------------------|------------------------------------------------------------------|
| `graft`         | `echo_graft`         | the Volume runtime (core, local Fjall store, OpenDAL remote, rt) |
| `graft-tracing` | `echo_graft_tracing` | tracing setup helper (test/antithesis)                           |
| `graft-test`    | `echo_graft_test`    | Volume/transaction parity harness + integration tests            |

Third-party dependency versions are pinned via the vendored `Cargo.lock` (incl. `opendal` @
`06f088d9`).

## What was removed (the SQLite extension)

The one part the platform rejected (no SQLite / C-binding path). Not adopted:

- `graft-ext` (`libgraft_ext`, the cdylib SQLite extension) and `graft-sqlite` (the VFS + pragma
  logic).
- The SQLite-coupled parts of `graft-test`: `src/workload.rs` (the rusqlite bank workload),
  `src/bin/test_client.rs`, and the integration tests that drive the engine *through* the VFS
  (`tests/sqlite.rs`, `tests/remote_commit_faults.rs`, `tests/workload_sanity.rs`).
- The SQLite tooling/fixtures (`tasks/sqlite`, `tests/sql`, `datasets/*.sql`, `DEMO.md`,
  `sqlite-dist.toml`, `sqlpkg.json`) and the `sqlite-plugin`/`rusqlite` workspace deps.

Consequence: the parity baseline is carried by the engine's inline `#[test]`s + the two
pure-Volume integration tests (`verify_snapshot`, `verify_soft_truncate`) + the eg.1-added direct
concurrent-commit tests (`echo_graft_test/tests/concurrent_commit.rs`).

## Owned divergences from the seed

These are deliberate, permanent departures — **we own them; there is nothing to re-merge.**

- **`crates/echo_graft/src/remote.rs` — `tcp_user_timeout` cfg-gate.** `reqwest`'s
  `tcp_user_timeout` maps to the Linux `TCP_USER_TIMEOUT` socket option and only compiles on
  Linux/Android; it is `cfg`-gated so the engine builds on macOS (a named build target).
- **No `echo_graft_remote` crate.** The remote is an in-crate module (`echo_graft::remote`)
  backed by **OpenDAL** (`RemoteConfig::{Memory, Fs, S3Compatible}` over an `opendal::Operator`),
  not an extractable trait. Splitting it out would force a core/remote/runtime restructure no rung
  requires. (`eg.2` points `S3Compatible` at Tigris via `AWS_ENDPOINT_URL`; the commit fence is
  `put_commit`'s `WriteOptions { if_not_exists: true }` ⇒ `If-None-Match: *` ⇒
  `RemoteErr::precondition_failed()`.)
- **Remote backend is OpenDAL, not `object_store`** (the original integration sketch predates the
  upstream switch; the as-built is OpenDAL).
- **Commit OCC is snapshot-version-level, not page-level** (`fjall_storage::commit` →
  `is_latest_snapshot`): a second commit from a *stale* base aborts with
  `LogicalErr::VolumeConcurrentWrite` even on disjoint pages. Page-level merge across writers is a
  remote-sync property (`eg.2`/`eg.3`), not a local-commit one.

## What was added (`eg.2` — remote fence & sync proof)

`eg.2` is a **verification** rung: the remote seam (OpenDAL `Remote`) was carried whole in `eg.1`,
so `eg.2` proves it rather than reimplementing it. Additions, all additive over the frozen carry:

- **`crates/echo_graft/src/remote.rs` — `Remote::testutil_list(prefix)`** (gated
  `#[cfg(feature = "testutil")]`): a recursive object lister so the suite can assert remote object
  counts (one segment per rolled-up push; one commit at a contested LSN). Not compiled into
  production builds.
- **`crates/echo_graft_test/src/lib.rs` — harness extensions**: `GraftTestRuntime::remote()`
  (inspect what landed in object storage); `with_live_remote` / `live_s3(tag)` (a harness for a
  **live network backend** — an *unpaused* tokio clock, since `start_paused` auto-advances time
  and fires reqwest's connect/retry timeouts instantly against a real endpoint); `on_remote(fut)`
  (drive an inspection op on the harness runtime so the live backend's connection pool / DNS
  resolver are reused); `spawn_peer` matches the parent's liveness.
- **`crates/echo_graft_test/tests/remote_fence.rs`**: the conditional-write fence (criterion #1) +
  provider conformance (#6), run against OpenDAL `Memory` **and** `Fs`, with an env-gated
  (`ECHO_GRAFT_TEST_S3_BUCKET` + `AWS_ENDPOINT_URL`) live MinIO/Tigris leg (#5).
- **`crates/echo_graft_test/tests/remote_sync.rs`**: each scenario is a backend-agnostic `run_*`
  helper run twice — a Memory entrypoint (always) and an env-gated `*_on_tigris` entrypoint (the
  same assertions against live Tigris): push-with-rollup → one segment of latest pages (#2), lazy
  pull to head (#3), ≤64-page Zstd framing through the push path (#4), the end-to-end
  sync-then-race fence (#1); plus Fs backend-parity (#5).
- **`crates/echo_graft_test/Cargo.toml`**: `tempfile` added (the Fs-backend temp root).

Verified ground truths (pinned `opendal@06f088d`, do not re-derive): `Memory` and `Fs` both
declare `write_with_if_not_exists` and return `ErrorKind::ConditionNotMatch` on collision
(Memory = compare-and-set, Fs = `O_EXCL`) — the same conditional-create contract as `S3`. No
`Remote`/`RemoteCommit` byte changes; the engine fence path is unchanged from the seed.

**Engine finding — the multi-writer model is *sync-then-race*.** A never-synced volume may not
blind-push to a non-empty remote (a `plan_commit` invariant); the realistic fence race is
established by a pull (to set a sync point), then a push from a stale base.

**Live Tigris validation (2026-06-21).** All env-gated legs verified green against real Tigris
(`https://fly.storage.tigris.dev`, region `auto`): the fence leg (`remote_fence`) and all four
sync legs (`remote_sync` rollup / pull / framing / race). Run them with
`set -a; . echo/.env.test; set +a; export ECHO_GRAFT_TEST_S3_BUCKET="$TIGRIS_BUCKET"` then
`cargo test -p echo_graft_test tigris` (+ the fence leg by name). Note: OpenDAL reads
`AWS_ENDPOINT_URL` (not Fly's `AWS_ENDPOINT_URL_S3`); both are in `echo/.env.test`. Tigris honors
`If-None-Match` (the fence) and path-style addressing (OpenDAL default) — no code differs from the
Memory/Fs path, only `RemoteConfig`.

## Build & test

```bash
cd /Users/jonny/dev/jonnify/echo/apps/echo_graft
TMPDIR=/tmp cargo test --workspace          # parity baseline + eg.2 fence/sync (Memory/Fs)
TMPDIR=/tmp cargo clippy --workspace         # warnings-as-errors clean
# live Tigris legs (env-gated):
set -a; . /Users/jonny/dev/jonnify/echo/.env.test; set +a
export ECHO_GRAFT_TEST_S3_BUCKET="$TIGRIS_BUCKET"
TMPDIR=/tmp cargo test -p echo_graft_test tigris
```

It is a Cargo workspace living *inside* the Elixir umbrella's `apps/` (Mix ignores it — no
`mix.exs`). Homebrew `cargo`; workspace `rust-version = 1.91`, edition 2024.
