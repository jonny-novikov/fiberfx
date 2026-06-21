---
title: "echo_graft — the Elixir/Rust engine split (design)"
id: echo-graft-engine-split
status: Draft — decision pending (Operator)
owner: Fireheadz
author: Venus (architect)
date: 2026-06-21
supersedes-banner: "Reconciliation input for eg.4. The roadmap (graft.roadmap.md) and graft.4.md assumed ONE durability engine (Rust, sidecar-driven). As-built there are TWO complete native engines plus a separate outbox facade. This design records the as-built ground truth and surfaces the collision for an Operator decision; it does NOT itself retire either engine."
---

# echo_graft — what we build in Elixir vs. in Rust { id="echo-graft-engine-split" }

> _The eg.4 build paused on a collision: the spec names `EchoStore.Graft` as the **thin Elixir client** to a Rust sidecar, but `EchoStore.Graft` already exists as a **complete native-BEAM page-store engine**. This document gathers the requirements from both as-built engines, separates the durability concerns the BEAM owns from the ones a Rust engine owns, lays out the resolution options, and gives a recommendation — but the consequential call (coexist / supersede / reframe) is the Operator's._

---

## 0. The decision in one paragraph (read first)

There are **two independently-complete durability engines** in the umbrella, both transactional page-stores that replicate Volume state to Tigris: **`EchoStore.Graft.*`** (pure Elixir, on CubDB) and **`apps/echo_graft`** (Rust, on Fjall, eg.1–eg.3 shipped). They are **functional twins**, not layers — each on its own owns the write-lock, the OCC commit, the conditional-write fence, the segment rollup, the Tigris remote, lazy reads, and a change-feed. Separately, **`EchoStore.Durability.*`** is a *third, smaller* concern: a pluggable **outbox** facade for the EchoMQ transactional-enqueue path, which states in its own moduledoc that the intents it carries are **low-volume** and that **the bus stays on Valkey**. The eg.4 spec collided because it tried to introduce the Rust engine's Elixir client under the name (`EchoStore.Graft`) the native engine already holds. **The recommendation is Option A (coexist) with a renamed Rust client** — but Options B and C are real and are laid out in full for the Operator.

---

## 1. 5W + H — what this design decides { id="engine-split-5wh" }

| | |
|---|---|
| **Who** | Platform/architecture (Fireheadz). The decision binds: the Rust epic (`apps/echo_graft`, eg.4+), the native Elixir engine (`EchoStore.Graft.*`), the outbox facade (`EchoStore.Durability.*`), and downstream durability callers on the BEAM. |
| **What** | A documented division of labour between an Elixir durability layer and a Rust durability engine, the resolution of the `EchoStore.Graft` name/architecture collision, and the reconciled scope of eg.4. |
| **When** | Now — eg.4 is blocked on it. Movement I of `echo_mq` is closed; `echo_graft` eg.1–eg.3 are shipped (Rust) and `EchoStore.Graft.*` is code-complete (Elixir, untracked on the `echo_mq` branch). |
| **Where** | Specs only: this doc + edits to `docs/graft/specs/graft.4.md`. No production code is touched by this rung (neither Rust nor Elixir). |
| **Why** | The Operator's framing — **increasing durability beyond Champ's bounded-loss window**, **async** shipping, **Tigris** as the durable floor — is already served *twice*. A build cannot proceed until it is decided which engine serves which need and what the cross-runtime contract (eg.4) actually is. Two engines silently competing for one name is a diff no one can review. |
| **How** | Read both engines from source (no invented signatures — every capability below is cited to a module/function), separate the genuinely-complementary concerns from the duplicated ones, present the resolution options with tradeoffs, recommend one, and restate eg.4 to match — all as spec edits, with an explicit "Open decisions (Operator)" block. |

---

## 2. Needs vs. reality — what echo_store actually needs from a durability tier { id="needs-vs-reality" }

The decisive question is not *"which engine is better"* but *"what does the consumer actually need, and where does each engine over- or under-serve that need?"* The consumer's own code answers the first half.

**The stated need (from the consumer's own moduledocs):**

- `EchoStore.Durability` (`durability.ex:6-9`): the durable concern is the **EchoMQ transactional-enqueue outbox** — *"the bus stays on Valkey (fast, reliable, D-2 volatile) and only the low-volume outbox intents land in the journal — so a single-instance Postgres is a small, mostly-idle dependency, not the hot path Oban puts every dequeue/heartbeat/ack through."*
- `EchoStore.Durability.Adapter` (`adapter.ex:4-7`): *"an outbox standing beside the bus (D-2 holds: the durable write never enters the enqueue hot path)."*
- The shipped, dependency-free outbox backends are **`SQLite`** (`exqlite`) and **`Memory`** (ETS). A heavier backend (Postgres, or the Graft commit-log-as-outbox) is a **bring-your-own plugin** a host adds in its own app (`adapter.ex:9-21`).

**The separate need (page/Volume durability + replication):** beyond the outbox, the platform wants to lift Champ off bounded-loss — *transactional commits with an LSN log, segment data, conditional-write commit, and instant read replicas over object storage* (`graft.roadmap.md:15-17`). This is a **page-store** need (raw pages, snapshots, replica recovery), not an outbox need.

| Real need | Volume / cadence | What it actually requires | Outbox engine fit | Page-store engine fit |
|---|---|---|---|---|
| **Transactional-enqueue outbox** — record intent, enqueue, replay the crash window | **Low** (intents only; the bus carries the hot path) | An atomic intent+enqueue, replay, compaction, newer-wins memory — `EchoStore.Durability.Adapter`'s eight callbacks | **Exact fit.** `SQLite`/`Memory` serve it today with zero new deps. | **Over-serves.** A full page-fault engine is far more than the outbox needs; `Durability.Graft` adapts the log only because the Volume is *already there* for the page need. |
| **Page/Volume durability beyond Champ** — durable pages, LSN log, snapshots | Medium | Copy-on-write page versioning, immutable snapshots, an LSN log, OCC commit | **Under-serves.** An outbox is not a page-store; it has no page model. | **Exact fit.** This is what a Graft-class engine *is*. |
| **Async replication to Tigris** — ship segments off the write path | Medium | A real-time segment shipper that does not block the commit, with crash-safe resume | n/a (outbox concern) | **Exact fit** (Elixir `Streamer`; Rust `RemoteCommit` action + autosync). |
| **Instant replica recovery / lazy partial reads** | On-demand | A reader that faults missing pages from object storage, caches, and serves | n/a | **Exact fit** (Elixir `Reader` lazy-fetch; Rust `read_page` `FetchSegment`). |

**The conclusion that drives the split:** the **outbox** need (the only durability the consumer's hot path actually touches, and explicitly *low-volume*) is already met natively in Elixir with no foreign engine, and a full transactional page-store engine is the **wrong size** for it. A page-store engine earns its place on the *page/Volume durability + replica recovery* need — a **different consumer** (raw page workloads, replica reads), not the outbox. So the live question is narrowly: **for the page/Volume tier, do we want one engine or two, and in which runtime?** — not "Rust outbox vs. Elixir outbox" (that contest does not exist).

---

## 3. As-built capability map — both engines, cited to source { id="capability-map" }

> No signature below is invented; each is read from the cited file. Forward-tense marks anything unshipped.

### 3a. RUST — `apps/echo_graft` (eg.1–eg.3 shipped; Rust, Fjall + OpenDAL)

| Concern | As-built surface (cited) |
|---|---|
| Engine handle | `echo_graft::rt::runtime::Runtime` — `Clone`, wraps `Arc<RuntimeInner>` (`runtime.rs:38-51`). |
| Open / identity | `volume_open` (`runtime.rs:170`), `volume_open_branded(&BrandedId,…)` writing the branded↔native pair in one Fjall batch (`runtime.rs:185-195`); `resolve_branded` (`:198`). `identity::BrandedId` validates `{NS}{base62}`, **caller-supplied — no Rust minter** (`identity.rs:10-12,45-60`). |
| Write / OCC | `volume_writer` (`runtime.rs:298`); local commit OCC is **snapshot-version-level** (`README.md:107-109` → `fjall_storage::commit` `is_latest_snapshot`) — a stale-base commit aborts `VolumeConcurrentWrite` even on disjoint pages. |
| Durable commit + fence | `volume_push` → `run_action(RemoteCommit)` (`runtime.rs:239-243`); fence = `Remote::put_commit` `WriteOptions{ if_not_exists: true }` ⇒ `ConditionNotMatch` ⇒ `RemoteErr::precondition_failed()` (`remote.rs:195-211, 66-72`). Multi-writer model is **sync-then-race** (`README.md:140-144`). |
| Remote (Tigris) | `remote::Remote` over **OpenDAL** `Operator` (`remote.rs:107-148`); `RemoteConfig::{Memory,Fs,S3Compatible}`; `S3Compatible` reads `AWS_ENDPOINT_URL` (`:122`). `put_segment`/`get_segment_range`/`get_commit`/`stream_commits_ordered` (`remote.rs:154-257`). **Live-Tigris verified** (`README.md:146-152`). |
| Read / lazy fault | `read_page` resolves the page, else `run_action(FetchSegment)` from the remote and re-reads (`runtime.rs:91-120`). |
| Change-feed | `feed()` → `InMemoryFeed` (`runtime.rs:83`); byte-frozen `FeedEvent{volume_branded_id,log_id,lsn,ts}` (`feed.rs:25-38,166`); ordered + idempotent-per-LSN, `events_since` replay (`feed.rs:69-111`); `lane_for → "egraft:feed:{vol}"` (`feed.rs:42`). Published **only on a durable remote-LSN advance** (`runtime.rs:250-279`) — a lost fence publishes nothing. |
| Local store | `local::fjall_storage::FjallStorage` (`lib.rs:1-3`); partitions `tags / volumes / log / pages / brands`. |
| Integration posture | A supervised **Rust sidecar** the BEAM drives over EchoMQ RESP3; **not** an in-VM NIF (`README.md:49-51`). **eg.4 is the as-yet-unbuilt seam.** |

### 3b. ELIXIR — `EchoStore.Graft.*` (code-complete; pure Elixir, CubDB + Tigris)

| Concern | As-built surface (cited) |
|---|---|
| Facade / engine | `EchoStore.Graft` — `open_volume/2`, `new_volume_id/0`, `begin`/`commit`/`snapshot`/`head_lsn`/`push`, `read/2`, `read_at/3` (`graft.ex:27-67`). Moduledoc: *"Native-BEAM Graft … with no foreign engine"* (`graft.ex:2-4`). |
| Write-lock | `EchoStore.Graft.VolumeServer` — one single-writer process per Volume; **its mailbox is the global write lock** (`volume_server.ex:2-8`). |
| OCC commit | `commit/3` rejects a stale base `base_lsn != head → {:error,{:conflict,head}}` (`volume_server.ex:129-159`). |
| Local store | `EchoStore.Graft.Store` on **CubDB** (append-only immutable B-tree, zero-cost MVCC snapshots) — `append` in one tx, `page_at` (reverse-select), `index_at`, `commits` (`store.ex:1-20,42-106`). |
| Replication | `EchoStore.Graft.Streamer` — *"the native, real-time replacement for the Litestream sidecar"*; rolls the LSN range into a Segment, ships to Tigris, writes the conditional commit, advances the watermark, announces on the bus; capped-exp-backoff; crash-safe resume from the watermark (`streamer.ex:1-15,88-112`). |
| Remote (Tigris) | `EchoStore.Graft.Remote.Tigris` — `put_segment`/`get_segment`/`put_commit` (create-only `If-None-Match:"*"`, `X-Tigris-Consistent`)/`list_commits` (`tigris.ex:1-44`). |
| Read / lazy fault | `EchoStore.Graft.Reader` — L1 ETS (`:ets.lookup` on `EchoStore.Table`) → CubDB head/snapshot → **lazy segment fetch** over the remote (`reader.ex:1-18,24-77`). |
| Bus notices | `EchoStore.Graft.Sync` — `publish_notice`/`subscribe_commits`/`decode_notice` over `EchoMQ.Connector` `PUBLISH`/`subscribe`; channel `graft:{vol}:commits` (`sync.ex:1-12,20-41`). |
| Outbox drain | `EchoStore.Graft.Committer` — *"the commit-log-as-outbox drain"*; subscribes to the commit channel, re-publishes each commit's names to a work queue at-least-once, persisted frontier (`committer.ex:1-18,99-114`). |
| Fencing | `EchoStore.Graft.Epoch` — a monotonic fencing token closing the restarted/partitioned-writer double-append gap (`epoch.ex:1-14,18-29`). |
| No-merge guard | `EchoStore.Graft.Divergence` — `check/3` returns `:ok` / `{:fast_forward,:remote,n}` / `{:error,{:diverged,l,r}}`; *"divergence is reported, never resolved by guessing"* (`divergence.ex:1-25`). |
| IDs | `EchoData.Graft.Id` — `VOL`/`SEG`/`CMT` branded GIDs, snowflake suffix monotonic = commit order (`id.ex:1-39`). |
| Supervision | `EchoStore.Graft.Supervisor` — a `Registry` + a `DynamicSupervisor` (`supervisor.ex:1-27`). |

### 3c. ELIXIR — `EchoStore.Durability.*` (the separate, smaller concern)

| Concern | As-built surface (cited) |
|---|---|
| Facade | `EchoStore.Durability` — reads the configured adapter and dispatches; **outbox-beside-the-volatile-bus**; intents **low-volume**, bus on Valkey (`durability.ex:1-19,30-57`). |
| Contract | `EchoStore.Durability.Adapter` — 8 callbacks: `child_spec`, `intend_and_enqueue`, `record`, `mark_enqueued`, `record_many`, `replay`, `compact`, `last_applied`, `stats` (`adapter.ex:28-45`). |
| Shipped backends | `SQLite` (over `exqlite`, the shipped `EchoStore.Journal`) + `Memory` (ETS, tests) — **zero new deps** (`adapter.ex:9-15`). |
| BYO plugin | `EchoStore.Durability.Graft` — *"the outbox IS the Graft commit log"*: an intent is a page commit in a reserved high range `@obx_base = 1 <<< 48`; replay scans that range above a watermark; **a host brings it because it needs the Graft tier** (`plugins/graft.ex:1-33,46,82-92`). |

**The seam to notice:** `EchoStore.Durability.Graft` consumes `EchoStore.Graft.VolumeServer`/`Store` (`plugins/graft.ex:39-41`). The outbox-on-Graft adapter is **built on the native Elixir engine** — it is *not* a Rust-engine client. Whatever the Operator chooses for the page tier, this adapter's contract is the native engine's API.

---

## 4. The proposed split — what lives on the BEAM, what lives in Rust { id="proposed-split" }

Separating **duplicated** concerns (where the two engines genuinely compete) from **complementary** ones (where each adds something the other lacks):

### Genuinely COMPLEMENTARY — the BEAM keeps these regardless

These are orchestration/bus concerns no Rust page-store replaces; they stay on the BEAM in every option:

- **The outbox / intents path** — `EchoStore.Durability.*` (`SQLite`/`Memory` core; Postgres/Graft as BYO). The only durability the enqueue hot path touches; low-volume by its own statement; **not a page-store concern**.
- **L1 ETS + coherence** — `EchoStore.Table` + `EchoStore.Coherence` (newer-wins, *a message about a name*). The cache-aside head cache is a BEAM concern; a Rust engine produces page bytes, it does not own the L1.
- **The bus** — `EchoMQ` stays on Valkey. Commit *notices* (`Sync`) and the change-feed lane (`egraft:feed:{vol}`) ride the bus; the Rust feed is a **producer into** that lane, not a replacement for it.
- **Supervision / lifecycle / single-writer addressing** — the `Registry` + `DynamicSupervisor`, the per-Volume write-lock *addressing*, and crash-domain isolation are BEAM-native (a Rust engine crash becomes a supervised sidecar restart, `graft.roadmap.md:17`).

### DUPLICATED — the page/Volume engine itself (this is the collision)

Both engines independently provide **all** of: the write-lock, OCC commit, the LSN log, CubDB-vs-Fjall local page store, segment rollup, the Tigris remote + conditional-write fence, lazy partial reads, the LSN-driven change-feed, and a no-merge divergence stance. This is **one role implemented twice**:

| Page-engine concern | Elixir (`EchoStore.Graft.*`) | Rust (`apps/echo_graft`) |
|---|---|---|
| Write-lock | `VolumeServer` mailbox | (single-writer per Volume; Fjall) |
| OCC commit | `{:conflict, head}` (`volume_server.ex:131`) | `VolumeConcurrentWrite` (`README.md:107`) |
| Local store | CubDB MVCC | Fjall LSM |
| Remote + fence | `Remote.Tigris` `If-None-Match` | OpenDAL `if_not_exists` |
| Async ship | `Streamer` | `RemoteCommit` action + autosync |
| Lazy reads | `Reader` lazy-fetch | `read_page` `FetchSegment` |
| Change-feed | `Sync` notices | `InMemoryFeed`/`FeedEvent` |
| Divergence | `Divergence.check/3` | sync-then-race + `plan_commit` |

**The split therefore reduces to one Operator decision:** *who owns the page/Volume engine role* — the native Elixir engine, the Rust engine, or both (each aimed at a different workload). Everything else (outbox, L1, bus, supervision) is settled and BEAM-side.

---

## 5. Resolve the collision — the options for the Operator { id="collision-options" }

The `EchoStore.Graft` name and the page-engine role are claimed twice. Three coherent resolutions; the call is the Operator's (architecture choice + a name change + a possible retirement = above the architect's line).

### Option A — Coexist (RECOMMENDED), with a renamed Rust client

- **Native Elixir `EchoStore.Graft.*` stays the canonical page/Volume engine** for the BEAM-resident durability path (the outbox-on-Graft adapter, projection/replica needs served in-process). No foreign engine on the default path → fewer moving parts, one crash domain, no cross-runtime wire for the common case.
- **The Rust `apps/echo_graft` engine is the engine for raw page/Volume + replica-recovery workloads** that want Rust's page-fault performance or a deployable sidecar beside Go workers — and it is driven over the bus under a **non-colliding name**. Proposed: **`EchoStore.GraftSidecar`** (Elixir client) ↔ **`echo_graft_sidecar`** (the Rust binary) ↔ **`echo_graft_proto`** (the wire). `EchoStore.Graft` (native) and `EchoStore.GraftSidecar` (Rust client) sit side by side, distinct.
- **Tradeoffs:** (+) nothing is removed; both investments live; the decision is reversible; eg.4 proceeds immediately with a rename. (−) two page-engines to maintain long-term; the Operator must later decide whether they converge or stay specialized (deferred, not forced now). (−) the eg.6 shootout must say *which workload* each wins, not just a single number.

### Option B — Rust supersedes the native Elixir engine

- The Rust sidecar becomes the **one** page/Volume durability tier. The native `EchoStore.Graft.*` engine is **retired**; the Rust client takes the `EchoStore.Graft` name. `EchoStore.Durability.Graft` (the outbox adapter) is **rewritten** onto the sidecar client (it currently calls `VolumeServer`/`Store` directly — `plugins/graft.ex:39-41`).
- **What gets removed (named, per the no-silent-retire rule):** the entire `apps/echo_store/lib/echo_store/graft/` subtree — `volume_server`, `store`, `streamer`, `sync`, `committer`, `reader`, `segment`, `epoch`, `divergence`, `remote`, `remote/tigris`, `supervisor` — plus the `EchoData.Graft.*` helpers if unused elsewhere, plus every test over them.
- **Tradeoffs:** (+) one engine, one contract, no duplication; the shootout is a single comparison. (−) **highest blast radius** — deletes a complete, working, dependency-free native engine and re-grounds the outbox adapter on a cross-runtime wire; the common in-process case now pays a sidecar hop; a Rust crash domain enters the default path. (−) irreversible without resurrecting deleted code.

### Option C — Native Elixir is canonical; Rust `echo_graft` is a research / shootout track

- `EchoStore.Graft.*` is **the** durability engine. `apps/echo_graft` is reframed as a **research + benchmark track**: eg.4 stops being "the integration spine" and becomes "a sidecar harness sufficient to run the eg.6 durability shootout against the native engine, Champ, and Oban." No production BEAM path depends on the Rust engine until/unless the shootout justifies it.
- **Tradeoffs:** (+) zero risk to the shipping path; preserves the Rust work as a measured bet; defers the heavy integration until evidence demands it. (−) the Rust eg.1–eg.3 investment does not reach production soon; eg.4/eg.5 shrink to a harness; the "transactional+replicated quadrant" claim is then carried by the *Elixir* engine, and `graft.roadmap.md`'s framing (Rust fills the quadrant) needs a rewrite.

### Recommendation

**Option A.** Rationale: (1) **needs vs. reality** — the only durability the consumer's hot path touches is the *low-volume outbox*, already served natively with no foreign engine; nothing forces a Rust engine onto the default path, so removing the native engine (B) spends the most blast radius for the least pressing need. (2) **Both investments are real and not actually competing for the same workload** — the native engine wins the in-process/low-dep case; the Rust engine wins raw-page performance + a deployable sidecar. Coexistence names that split instead of forcing a premature winner. (3) **Reversibility** — A keeps the door open to B *or* C after the eg.6 shootout produces evidence; B and C foreclose. (4) **eg.4 unblocks today** with a pure rename (`EchoStore.Graft` native stays; the Rust client becomes `EchoStore.GraftSidecar`). The one thing A defers — long-term convergence of two page-engines — is exactly the kind of horizon decision that should wait for the shootout, not be fused into this rung.

> **This recommendation does not retire either engine.** It proposes a name for the Rust client and a coexistence boundary. The choice between A / B / C is the Operator's.

---

## 6. Reconciled eg.4 — what `graft.4.md` should build under Option A { id="eg4-reconciled" }

Under the recommendation, eg.4 keeps its **shape** (sidecar + versioned proto + Elixir client + conformance) but loses the **name collision** and narrows its **claim**:

- **The Elixir client is `EchoStore.GraftSidecar`, NOT `EchoStore.Graft`.** `EchoStore.Graft` remains the native engine. Every eg.4 reference to "the Elixir client `EchoStore.Graft`" → `EchoStore.GraftSidecar`.
- **eg.4 is no longer "THE integration spine" — it is "the sidecar integration for the Rust page-engine."** The native engine needs no sidecar; eg.4 drives the *Rust* engine for the workloads Option A assigns it. The roadmap's "the BEAM never links the engine in-process during the spine" stays true *of the Rust engine*, not of all durability.
- **The change-feed lane is shared, not duplicated:** the Rust `egraft:feed:{vol}` lane (`feed.rs:42`) is one producer onto the EchoMQ bus the native `Sync` path already uses (`graft:{vol}:commits`). eg.4 must declare whether the sidecar publishes on `egraft:feed:{vol}` (its own lane, recommended — keeps the two engines' feeds distinct) and `EchoStore.GraftSidecar` subscribes there.
- **Scope unchanged otherwise:** `echo_graft_proto` (byte-frozen, version-negotiated), `echo_graft_sidecar` (the EchoMQ participant), the error taxonomy, backpressure, and the dual-side conformance suite all stand — they are about the *cross-runtime contract*, which is real under A.
- **If the Operator picks B instead:** eg.4 takes the `EchoStore.Graft` name, AND a new precondition is added — "retire `apps/echo_store/lib/echo_store/graft/*` and re-ground `EchoStore.Durability.Graft` on the sidecar client" — which is a separate, high-blast-radius rung that must be specced before eg.4 builds.
- **If the Operator picks C:** eg.4 is rewritten to "a benchmark harness driving the Rust engine for the eg.6 shootout" — no production `EchoStore.*` client, no version-negotiated wire beyond what the harness needs.

The concrete spec edits to `graft.4.md` (Reconciliation banner + renamed client throughout + an "Open decisions (Operator)" block) are applied in this rung; see §7 for the exact decision list.

---

## 7. Open decisions (Operator) { id="open-decisions" }

Every call below is the Operator's; the architect proposes, does not dispose.

| # | Decision | Options | Architect's recommendation |
|---|---|---|---|
| **D-1** | The collision resolution | **A** coexist (rename Rust client) · **B** Rust supersedes (retire native engine) · **C** native canonical, Rust = research track | **A** |
| **D-2** | The Rust client's name (if A or C) | `EchoStore.GraftSidecar` · `EchoGraft.Client` · other | `EchoStore.GraftSidecar` (mirrors `echo_graft_sidecar`; keeps the `EchoStore.*` family) |
| **D-3** | eg.4's claim | "the integration spine for all durability" · "the sidecar integration for the Rust page-engine" | the latter (under A) |
| **D-4** | Long-term convergence of the two page-engines | converge later · stay specialized (Elixir=in-process/low-dep, Rust=raw-page/sidecar) · decide after the eg.6 shootout | **decide after eg.6** — do not fuse into this rung |
| **D-5** | The eg.6 shootout's shape | one number (engine vs. Champ vs. Oban) · per-workload (Elixir-engine vs. Rust-engine vs. Champ vs. Oban, named workloads) | per-workload (A makes "best engine" workload-dependent) |
| **D-6** | If B is chosen | confirm the retirement of `echo_store/lib/echo_store/graft/*` + the `Durability.Graft` re-grounding is a **separate pre-eg.4 rung** | yes — do not bundle a high-blast-radius deletion into eg.4 |

---

## 8. What this rung does NOT do { id="non-actions" }

- **It does not retire either engine.** No code is deleted, renamed, or moved by this rung; the rename in §6 is a *proposal* contingent on D-1/D-2.
- **It does not touch production code** — Rust (`apps/echo_graft`) or Elixir (`apps/echo_store`) — nor the read-only reference checkout `github.local/graft`.
- **It does not pick D-1.** The recommendation is Option A; the decision is the Operator's, and B/C are specified in full so either can proceed without re-discovery.

## 9. References { id="references" }

- Rust engine: `apps/echo_graft/README.md`, `crates/echo_graft/src/{lib,rt/runtime,remote,feed,identity}.rs`.
- Elixir engine: `apps/echo_store/lib/echo_store/graft/{volume_server,store,streamer,sync,committer,reader,divergence,epoch,supervisor}.ex`, `graft.ex`, `graft/remote/tigris.ex`; `EchoData.Graft.Id` (`apps/echo_data/lib/echo_data/graft/id.ex`).
- Outbox: `apps/echo_store/lib/echo_store/{durability,durability/adapter,plugins/graft}.ex`.
- Specs: `docs/graft/graft.roadmap.md`, `docs/graft/specs/graft.4.md`, `docs/graft/graft.integration.md`.
- Memory: `memory/echo_graft/echo-graft-fork.md`.
