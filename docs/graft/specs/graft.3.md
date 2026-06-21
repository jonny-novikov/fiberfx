---
title: "eg.3 — Branded-ID identity & EchoMQ change-feed"
id: echo-graft-3-identity-feed
rung: eg.3
size: M
risk: NORMAL+
status: Draft
stands-on: "eg.1 · eg.2 · EchoMQ"
---

# eg.3 — Branded-ID identity & EchoMQ change-feed { id="echo-graft-3-identity-feed" }

> _Address Volumes by branded Snowflake at the edge while keeping Graft's identifiers internal, and publish every commit-LSN advance on an EchoMQ lane so consumers see new versions without polling._

## Reconciliation (as-built) { id="eg3-reconcile" }

> eg.3 was **built** against the carried engine (the spec below is the contract; this block records the as-built decisions, grounded in the source):
>
> - **Branded ids are caller-supplied; the engine never mints one.** A `BrandedId` (`echo_graft::identity`) validates the shape `{NS}{base62}` — 3 uppercase ASCII + 11 Base62 = 14 chars — and the platform supplies it on open. So there is **no Snowflake minter in Rust**: criterion #1 is "opened *by* a branded id", which the engine stores and round-trips, not generates.
> - **The mapping is single-source-of-truth + a forward index.** `Volume::branded_id` (a new `#[bilrost(6)]` field in the `volumes` partition) is authoritative; a new `brands` keyspace (`branded id → VolumeId`) is the forward-resolution index. `volume_open_branded` writes both **in one batch**, so resolution never races creation. The engine's native id (`VolumeId`/`LogId`, base58 `Gid`) stays internal — a clean layering seam.
> - **The change-feed is the in-process `InMemoryFeed` stub** (`echo_graft::feed`), held by the `Runtime` and reached via `Runtime::feed()`. The live `egraft:feed:{volume}` EchoMQ transport is eg.4 (the `ChangeFeed` trait is the seam; `lane_for` already yields the eg.4 lane string).
> - **The publish gate is `volume_push`'s remote-LSN advance — the engine action is untouched.** After `RemoteCommit` returns `Ok`, the Runtime compares the volume's remote sync LSN before/after and publishes one `FeedEvent` per new LSN. A lost conditional write advances nothing (it routes to recovery), so it publishes nothing — criterion #6 holds *by construction*, with zero edits to `remote_commit.rs`.
> - **The event's `log_id` is the remote `LogId` native string** (the replication-cursor coordinate paired with `lsn`), not a branded LOG id. The `brands` index is namespace-generic (a `LOG{base62}` ↔ `LogId` mapping is zero new code), but only the `VOL` path is exercised — no acceptance criterion supplies a branded LOG id, and minting one would re-introduce the minter eg.3 deliberately omits.
>
> **Finding (pre-existing, surfaced by eg.3's timing):** the carried `verify_snapshot.rs` fault-injection tests share **process-global** precept fault state and race under cargo's default parallelism (the `set_pending(1)` in one test can be consumed by a concurrent push in the other). Confirmed pre-existing — the original one-liner `volume_push` also races (~1/8 in parallel) — so it is **not** an eg.3 regression. Fault-injection suites must run `--test-threads=1`; the authoritative gate run is serial.

## Summary

Add a bidirectional `{ns}{base62}` ↔ Volume/Log mapping (branded id external, the engine's native id internal — a clean layering seam, *not* a compatibility concession) and a change-feed that publishes commit-LSN advances over EchoMQ. The LSN is the synchronization cursor; EchoMQ carrying it is the synchronization mechanism.

## Rationale

The platform addresses everything by branded Snowflake, and the rest of the stack should address Volumes the same way rather than learning the engine's internal identifier scheme. Keeping the engine's native identifier internal is a clean layering boundary — the edge speaks one identity dialect (branded), the core another (its native id) — and the mapping is the only translation point. (This is an engineering seam, not an upstream-mergeability concession: `echo_graft` keeps no compatibility with upstream — see the roadmap's development-direction note.) Separately, consumers need to know when a Volume advances; polling object storage is wasteful, and the commit already produces a monotonic LSN — publishing that LSN on EchoMQ turns the commit into a notification and gives followers an exact cursor to pull from.

## 5W + H { id="eg3-5wh" }

| | |
|---|---|
| **Who** | Platform; consumed by BEAM change-feed subscribers and the durability dashboard. |
| **What** | A persisted branded-id ↔ Volume/Log mapping, and an LSN-advance publisher emitting `{volume_branded_id, log_id, lsn, ts}` on a declared EchoMQ lane. |
| **When** | After eg.1/eg.2; parallel-eligible with eg.2. |
| **Where** | Mapping persisted in the Fjall volumes partition; the feed on EchoMQ lane `egraft:feed:{volume}`. |
| **Why** | One identity scheme across the stack, and push-based version notification with an exact replay cursor. |
| **How** | Store the branded id beside the Volume on create; gate feed publication on commit durability; make the feed replayable from a last-seen LSN. |

## Scope { id="eg3-scope" }

### In scope

- A bidirectional mapping: `VOL{base62}` ↔ internal Volume id, `LOG{base62}` ↔ internal Log id, persisted in the volumes partition as the single source of truth.
- A change-feed publisher: on a durable commit (LSN/SyncPoint advance), emit one event per advance on `egraft:feed:{volume}`.
- A replayable feed: a subscriber passing a last-seen LSN receives a gap-free, LSN-monotone catch-up.
- Defined here against an in-process EchoMQ stub; the live transport is eg.4.

### Out of scope

- The sidecar transport and protocol framing (eg.4); the low-latency tier (eg.5).
- Cross-Volume ordering guarantees (only per-Volume order is promised).

## Specification { id="eg3-spec" }

Branded-id decode (example): `VOL0O5fmcxbds8` → namespace `VOL`, an 11-char Base62 Snowflake. The mapping lives in the volumes partition and is written atomically with Volume creation, so id resolution never races commit. Feed event schema (declared, byte-frozen): `volume_branded_id` (string), `log_id` (string), `lsn` (u64), `ts` (epoch ms). Publication is gated on commit durability — the event is emitted only after the conditional-write commit acks, never before. Per-Volume ordering is LSN-monotone; cross-Volume ordering is unconstrained. Replay: a subscriber supplies its last-seen LSN and the publisher (or the engine on its behalf) streams every event for LSN greater than it, in order.

## Acceptance criteria { id="eg3-acceptance" }

1. **Given** a branded Volume id, **when** a Volume is opened by it, **then** the engine resolves it to the internal Volume and round-trips the same branded id on read.
2. **Given** a commit at LSN _n_, **when** it succeeds, **then** exactly one feed event for that Volume with `lsn = n` is published, **and** it is published only after the commit is durable.
3. **Given** a subscriber that reconnects with last-seen LSN _m_, **when** it resubscribes, **then** it receives every event for LSN > _m_ in monotone order, with no gaps (duplicates allowed only as at-least-once).
4. **Given** two Volumes committing concurrently, **when** events publish, **then** each Volume's events are LSN-monotone (cross-Volume interleaving is allowed).
5. **Given** the feed event schema, **when** an event is encoded, **then** it matches the byte-frozen fixture.
6. **Given** a commit that fails the conditional write, **when** the abort returns, **then** no feed event is published for that LSN.

### Verification (as-built) { id="eg3-verified" }

All six criteria pass against the carried engine (`echo_graft_test`, `--test-threads=1` for parity):

| # | Proving test |
|---|---|
| 1 | `identity_feed::branded_volume_resolves_and_round_trips` (+ `identity::tests::parse_*`) |
| 2 | `identity_feed::durable_commit_publishes_one_feed_event` (local commit publishes nothing; push publishes one at LSN 1) |
| 3 | `identity_feed::feed_replays_from_last_seen_lsn` (K=5 → `events_since(2)` = 3,4,5) |
| 4 | `identity_feed::concurrent_volumes_have_per_volume_monotone_feeds` |
| 5 | `feed::tests::feed_event_encoding_is_byte_frozen` (bilrost fixture, 51 bytes) |
| 6 | `identity_feed::lost_conditional_write_publishes_no_event` (sync-then-race fence) |

**Declared keys (eg.3):**
- Fjall keyspace `brands` — `branded id (ByteString) → VolumeId` (the forward-resolution index).
- `Volume.branded_id` — `#[bilrost(6)] Option<String>` in the `volumes` partition (the authoritative mapping).
- Feed lane `egraft:feed:{volume_branded_id}` (`feed::lane_for`) — the in-process key now, the eg.4 bus lane later.
- `FeedEvent` byte-frozen schema — `#[bilrost]` 1 `volume_branded_id: String` · 2 `log_id: String` · 3 `lsn: u64` · 4 `ts: u64`.

## Dependencies & risks { id="eg3-risks" }

- **Depends on:** eg.1, eg.2, EchoMQ.
- **Risk — publish-before-durable:** a correctness hazard; the publish must be gated on the commit ack (criterion 2/6).
- **Risk — id ↔ Volume drift:** single source of truth in the volumes partition; never derive the mapping in two places.
