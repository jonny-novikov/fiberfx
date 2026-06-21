---
title: "eg.2 — Tigris remote backend & commit/fence"
id: echo-graft-2-tigris-remote
rung: eg.2
size: M
risk: NORMAL
status: Draft
stands-on: "eg.1 · blue-green SigV4 path"
---

# eg.2 — Tigris remote backend & commit/fence { id="echo-graft-2-tigris-remote" }

> _Implement the remote-storage trait against Tigris (SigV4), so commits and segments land in object storage with the conditional-write commit doubling as the multi-writer fence._

## Reconciliation (as-built) { id="eg2-reconcile" }

> eg.2 was **reconciled** against the carried upstream before building: most of what the forward-tense spec below calls for already exists in `echo_graft::remote` (opendal). eg.2 therefore **proves** the seam rather than implementing it. Deltas from the spec language (grounded in the pinned source + `README.md`, the former `FORK.md`):
>
> - **No `echo_graft_remote` crate; no hand-rolled SigV4.** The "remote-storage trait" is the carried `Remote` method set (`put_commit` / `put_segment` / `get_commit` / `get_segment_range` / `stream_commits_ordered`); the "SigV4 client" is opendal's `S3` service. `RemoteConfig::S3Compatible` already reads `AWS_ENDPOINT_URL`. (R1 from eg.1.)
> - **The fence already exists.** The conditional create-once is `put_commit`'s `WriteOptions { if_not_exists: true }` ⇒ `If-None-Match: *`; a losing race surfaces as `RemoteErr::precondition_failed()` (`opendal::ErrorKind::ConditionNotMatch`), and `RemoteCommit` already routes it to recovery.
> - **Local test backend is in-process, not MinIO.** opendal's `Memory` and `Fs` services **both** honor `if_not_exists` (verified against pinned `opendal@06f088d`: each returns `ConditionNotMatch` on collision — Memory via compare-and-set, Fs via `O_EXCL`) — the same conditional-create contract as S3. The suite proves fence/rollup/pull/framing on those (deterministic, no daemon); the **live MinIO/Tigris leg is env-gated** (`ECHO_GRAFT_TEST_S3_BUCKET` + `AWS_ENDPOINT_URL`), matching upstream Graft's own no-live-S3 posture. "Repoint at Tigris = config only" holds by construction: no engine code branches on backend.
>
> **eg.2 added:** the `echo_graft_test` suites `remote_fence.rs` (the conditional-write fence + provider conformance, on Memory **and** Fs) and `remote_sync.rs` (push-rollup → one segment, lazy pull, ≤64-page Zstd framing, the end-to-end *sync-then-race* fence, Fs backend-parity), plus a `testutil`-gated `Remote::testutil_list` for object-count assertions. **Finding:** the engine's multi-writer model is *sync-then-race* — a never-synced volume may not blind-push to a non-empty remote (a `plan_commit` invariant); the realistic fence race is established via a pull, then a push from a stale base.

## Summary

Make `echo_graft` durable and replicated against real object storage by implementing the remote-storage trait for Tigris. Reuse Graft's segment/commit layout and its conditional-write commit, which provides multi-writer safety without a separate lease.

## Rationale

The transactional-and-replicated quadrant is the whole reason for the fork, and it lives in the remote backend. Graft already defines the seam (a remote-storage trait writing checkpoints, commits, and segments) and the commit protocol (a conditional write to the commit key detects conflicts). Implementing that seam against Tigris — for which a working SigV4 path already exists from the blue-green Champ work — yields durable, replicated commits and, as a free consequence, the fenced head: two writers racing a commit resolve by the loser's conditional write failing.

## 5W + H { id="eg2-5wh" }

| | |
|---|---|
| **Who** | Platform; consumed by the engine's sync path. |
| **What** | `echo_graft_remote`'s Tigris implementor: object put/get/list/delete plus conditional create/replace, segment upload, commit append, checkpoint write. |
| **When** | After eg.1; parallel-eligible with eg.3. |
| **Where** | `crates/echo_graft_remote`; remote state in a Tigris bucket; MinIO as the local test double. |
| **Why** | Durability and replication over object storage, and a fence for safe overlapping writers, with no new lease surface. |
| **How** | A SigV4 client (reused from the bench or the sidecar's own) backing the trait; conditional writes via `If-None-Match`/`If-Match`; Zstd-framed segments as upstream. |

## Scope { id="eg2-scope" }

### In scope

- Implement the remote-storage trait for Tigris: `put`, `get`, `list(prefix)`, `delete`, and conditional `put` (`If-None-Match: *` for create-once; `If-Match` where replace-if-unchanged is needed).
- Segment upload to `/segments/{SegmentId}`; commit metadata to `/logs/{LogId}/commits/{LSN}` via conditional write; checkpoint objects.
- Reuse upstream's frame format: Zstd, up to 64 pages per frame.
- Reuse upstream's push-with-rollup (dedup to the latest version of each page, many local commits → one remote commit) and pull (fetch missing LSNs, lazy page fetch).
- MinIO as the local backend for the suite; Tigris reachable by changing only configuration.

### Out of scope

- Branded-ID mapping and the change-feed (eg.3); the sidecar/protocol (eg.4); the low-latency buffer (eg.5).
- Multipart beyond a single frame cap (cap frame size; revisit if segments exceed the limit).

## Specification { id="eg2-spec" }

Declared remote keys: `/segments/{SegmentId}`, `/logs/{LogId}/commits/{LSN}`, and the checkpoint prefix. The create-once commit uses `If-None-Match: *`; a provider that returns `412 Precondition Failed` on a losing write is the conflict signal, surfaced as the engine's existing commit-conflict error. Push builds a segment by snapshotting an LSN range, collecting referenced pages, deduplicating to the latest version of each, Zstd-framing (≤64 pages/frame), uploading the segment, then conditionally committing. Pull streams only the commits whose LSNs are absent locally and leaves page data to be faulted in on read. A provider-conformance test asserts Tigris honors `If-None-Match`; MinIO stands in locally and the endpoint is the only difference.

## Acceptance criteria { id="eg2-acceptance" }

1. **Given** two writers sharing a `LogId`, **when** both attempt to commit LSN _n_ with a conditional write, **then** exactly one receives a success and the other a `412`/abort, and the log holds a single commit at _n_.
2. **Given** M local commits over a page set, **when** pushed, **then** one remote segment is written containing only the latest version of each page (verified by object count and content).
3. **Given** a remote log ahead by _k_ commits, **when** a fresh reader pulls, **then** it observes the head LSN and reads pages on demand without downloading the whole Volume.
4. **Given** a 50,000-page Volume, **when** a segment is uploaded, **then** each frame holds ≤64 pages and is Zstd-compressed (frame count and codec asserted).
5. **Given** an S3-conditional-write backend — opendal `Memory`/`Fs` in-process (both honoring `if_not_exists`→`ConditionNotMatch`, the same contract as S3), with MinIO/Tigris reachable via the env-gated live leg — **when** the eg.2 suite runs, **then** push/pull/commit/fence pass; **and** repointing the endpoint to Tigris changes only configuration, not code (no engine code branches on backend). _(Reconciled from "MinIO as the backend": MinIO is not a local dependency here; the in-process backends are faithful S3-conditional-create doubles, and the live leg is `ECHO_GRAFT_TEST_S3_BUCKET`-gated — see Reconciliation.)_ **Verified live against Tigris** (`fly.storage.tigris.dev`, 2026-06-21): the fence leg plus all four sync legs (rollup / pull / framing / race) pass against the real provider — Tigris honors `If-None-Match` and the engine code is unchanged from the Memory/Fs path.
6. **Given** a provider that does not honor `If-None-Match`, **when** the conformance test runs, **then** it fails loudly rather than silently losing the fence.

## Dependencies & risks { id="eg2-risks" }

- **Depends on:** eg.1; the existing SigV4 client.
- **Risk — provider conditional-write semantics:** Tigris supports `If-None-Match`; assert it in the conformance test rather than assuming it.
- **Risk — large segments:** cap frame size and document the cap; add multipart only if a workload exceeds it.
