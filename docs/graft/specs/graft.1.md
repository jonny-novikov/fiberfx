---
title: "eg.1 — Core fork & workspace"
id: echo-graft-1-core-fork
rung: eg.1
size: M
risk: NORMAL
status: Draft
stands-on: "orbitinghail/graft (MIT OR Apache-2.0)"
---

# eg.1 — Core fork & workspace { id="echo-graft-1-core-fork" }

> _Carve Graft's Volume runtime into an owned workspace, remove the SQLite extension, keep the Fjall local store, and prove the carve by passing upstream's own Volume tests unchanged._

## Summary

Establish `echo_graft` as a hard fork of Graft's core with full freedom to modify, the SQLite extension removed, and a green upstream test baseline. This is the trustworthy floor every later rung stands on; it contains no logic rewrite.

## Rationale

Graft's value is a working transactional Volume engine — LSN log, segment/snapshot model, conditional-write commit, lazy page loading — that would cost months to reimplement. Its MIT/Apache-2.0 license grants an outright fork. The SQLite extension is the one part this platform rejected (no SQLite/C-binding path), and it is the cleanest seam to cut. Doing the carve first, with upstream's tests as the acceptance bar, means later seam rewrites start from a known-correct engine rather than a half-understood one.

## 5W + H { id="eg1-5wh" }

| | |
|---|---|
| **Who** | Platform (Fireheadz); no external consumers yet — this rung produces a library, not a service. |
| **What** | A Cargo workspace holding the carved `echo_graft` runtime (Volume/Reader/Writer/sync, Fjall local store, the remote-storage trait with Memory + FS backends for tests), minus `libgraft_ext`. |
| **When** | First; blocks everything. |
| **Where** | `crates/echo_graft*` in the monorepo; pinned to a specific upstream commit. |
| **Why** | Own the engine under a permissive license, drop dead weight, and lock a correctness baseline before any rewrite. |
| **How** | Vendor the upstream runtime crate(s), delete the extension crate and its SQLite VFS/pragma code, retain license headers, and run upstream's Volume/transaction suite against the result. |

## Scope { id="eg1-scope" }

### In scope

- Fork the runtime crate(s); pin the upstream commit; record it in `README.md` (the former `FORK.md`) with the owned divergence points (for provenance/reference, not for re-merging upstream).
- Delete `libgraft_ext` (SQLite VFS + pragma) and every SQLite dependency it pulls.
- Retain the Fjall local store and its partitions (tags, volumes, log, pages) as-is.
- Retain the remote-storage trait surface plus the Memory and FS backends (needed for tests; Tigris is eg.2).
- `cargo build --workspace` and `cargo test --workspace` green.

### Out of scope

- The Tigris backend (eg.2), branded-ID mapping and EchoMQ feed (eg.3), the sidecar and protocol (eg.4), the low-latency tier (eg.5), packaging (eg.6).
- Any change to the engine's transaction logic or storage format.

## Specification { id="eg1-spec" }

Workspace layout: `crates/echo_graft` (runtime), `crates/echo_graft_remote` (trait + Memory/FS now, Tigris later). Public surface preserved verbatim from upstream: Volume open, `VolumeReader` (snapshot reads), `VolumeWriter` (staged segment, read-your-write), commit (OCC + LSN append + conflict detection), and the sync operations (push/pull/fetch). The remote-storage trait keeps its method set so eg.2 only adds a new implementor. `README.md` (the former `FORK.md`) declares: the upstream commit hash, the files deleted, and any patch applied to make the runtime build without the extension.

## Acceptance criteria { id="eg1-acceptance" }

1. **Given** upstream Graft's Volume/transaction test suite, **when** run against `echo_graft`, **then** it passes unchanged.
2. **Given** a fresh checkout, **when** `cargo build --workspace` runs, **then** it compiles with zero references to `libgraft_ext` or any SQLite crate.
3. **Given** a Volume with N committed pages on the Memory backend, **when** a `VolumeReader` opens a snapshot at the head LSN, **then** it reads back exactly those N pages.
4. **Given** two `VolumeWriter`s touching disjoint pages, **when** each commits based on the **latest** snapshot, **then** both succeed and the log shows two distinct LSNs. (echo_graft's commit OCC is **snapshot-version-level, not page-level**: a second commit from a **stale** base aborts with a conflict *regardless of page disjointness* — see #5. Page-level merge across writers is a remote-sync property, eg.2/eg.3. Confirmed against `fjall_storage::commit` → `is_latest_snapshot`; recorded in `README.md`.)
5. **Given** two concurrent `VolumeWriter`s touching the same page from the same base snapshot, **when** both commit, **then** exactly one succeeds and the other aborts with a conflict.
6. **Given** any carried source file, **when** inspected, **then** it retains its upstream MIT/Apache-2.0 header.

## Dependencies & risks { id="eg1-risks" }

- **Depends on:** upstream `orbitinghail/graft` (alpha quality — pin a commit).
- **Risk — upstream churn:** moot under the no-compatibility direction — upstream is a frozen reference, not a sync target. The pinned commit + the owned-divergence notes in `README.md` exist for provenance/reproducibility, not for re-merging.
- **Risk — local-store coupling:** keep Fjall; swapping the local store is out of scope and would invalidate the upstream-parity baseline.
