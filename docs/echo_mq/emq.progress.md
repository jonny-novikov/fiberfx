# EchoMQ — Program Progress Dashboard

> **The single consolidated status view of the EchoMQ engineering program** — the 2.x bus
> (`emq.0–emq.8`), the 3.x stream tier (`emq3.1–emq3.6`), and their named consumer, 
> grounded chapter-by-chapter in the **BCS manuscript**. This file
> *reports*; the binding artifacts *define* — the design canon
> [`emq.design.md`](./emq.design.md), the single consolidated roadmap
> [`emq.roadmap.md`](./emq.roadmap.md) (the program ladder + the 2.x line view + the 3.x stream tier;
> the rung triads under [`specs/`](./specs/), and the Exchange suite under [`../exchange/`](../exchange/).
>
> **Generated 2026-06-13** from the as-built tree + the committed records. Re-true at each rung close.
> **Reconciled 2026-06-13** — emq.2 re-scoped from "the v1→v2 migration path" to the **full-parity
> rewrite cluster** (emq.2.1/2.2/2.3); the carve + ADRs are [`specs/emq.2.design.md`](specs/emq.2/emq.2.design.md).
> **Reconciled 2026-06-14** — emq.2.1 (the read plane) **shipped** (`7d98ef86`; conformance grew
> 18→**24**); **emq.2.2 (the operator plane) shipped** (`76fc947c`; conformance **24→32**, pause form-b, EMQLOCK+EMQSTATE) — the `emq-2-2` lead-team
> closed it via the `echo-mq-ship` binding; **emq.2.3 (the watch plane) shipped** (`3c6461ff` —
> the watch surface: `EchoMQ.{Events, Meter, Stalled, Cancel, Locks}` + `Jobs.extend_lock(s)`; 5 suites;
> conformance **32→37**; both determinism flakes fixed at root; the ≥100 gate GREEN 100/0; Apollo BUILD-GRADE). **The
> `emq-2-4` design cycle is open** (2026-06-14, Director + Venus): catalog EchoMQ 3.0, prove v2 full-parity,
> and spec **emq.2.4** as the cluster-closing stage — the missing-feature fill + the complete test suite that
> closes the v1↔v2 coverage gap (v1 `echomq` 534 tests / 41 files vs v2 `echo_mq` 201 / 28 — the Operator's
> flag). Per-rung findings & learnings consolidated below (§ Findings & learnings — consolidated per rung).

**One-line state.** Movement 0 **shipped** (`a2d599c8`); Movement I's opener `emq.1` **shipped**
(`e0fa9b03`); **the emq.2 cluster CLOSED** (read→ops→watch→close, 4/4 — `7d98ef86`/`76fc947c`/`3c6461ff`/
`3298e4bc`); the **emq.3 flow family CLOSED** — `emq.3.1` (single-queue) + `emq.3.2` (child-result reads) +
`emq.3.3` (cross-queue, the `flow:outbox` + sweep, eventually-consistent) + `emq.3.4` (failure-policy + bulk,
`4c401479`, conf 47→50, HIGH-risk) + **`emq.3.5` (grandchildren / deep recursion — the V-1 Arm-A Out) SHIPPED**
(`emq-3-5`, conf 50→**52**, Apollo BUILD-GRADE, **NORMAL-risk, Arm A** — the recursive enqueue + the recursive
failure hook host-orchestrated over byte-frozen scripts; the depth-4 multi-tick proof). **Closing emq.3.5 CLOSED
Movement I → Movement II (emq.4–emq.8) opens on a complete core.** The build team is echo_mq-specialized (the
`echo-mq-architect/implementor/evaluator` skills + tuned charters, driven by the `echo-mq-ship` /x-mode binding).
The bus is real, measured, and conformance-gated at **52/52**; the platform door is real on top of it.

---

## Legend

| Symbol | State | Meaning |
|---|---|---|
| ✅ | **SHIPPED** | committed, gate-green, BUILD-GRADE on this machine |
| 🔨 | **IN FLIGHT** | building now — partial artifacts on disk, not yet committed |
| 📐 | **SPECCED** | spec triad/quad authored & gate-checked, no build artifact yet |
| 📋 | **PLANNED** | abstract fixed on the confirmed ladder, triad not yet authored |
| 🔒 | **PROPOSED** | awaiting Operator slot-ratification against the program ladder |

ANSI bars: `█` done · `░` remaining. A rung is one shippable increment; a milestone ships when all its rungs do.

---

## Development Progress

Legend: ✅ shipped · 🔨 in flight · 📐 specced · 📋 planned · 🔒 proposed.

```text
EchoMQ 2.x — the bus core · convergence target echo/apps/echo_mq

Movement 0 · land + prove
  emq.0     ✅ shipped     ████████████████████  wire extraction · pluggable shadow · §5 pass        a2d599c8

Movement I · scheduler + retry · the parity floor · flows
  emq.1     ✅ shipped     ████████████████████  scheduler + retry vocabulary                         e0fa9b03
  emq.2     ✅ CLOSED      ████████████████████  full-parity rewrite — read→ops→watch→close · 4/4 shipped
    emq.2.1 ✅ shipped     ████████████████████  read plane · introspection & metrics (conf 18→24)    7d98ef86
    emq.2.2 ✅ shipped     ████████████████████  operator plane · lifecycle & mutation (conf 24→32)   76fc947c
    emq.2.3 ✅ shipped     ████████████████████  watch plane · events/telemetry/locks/stalled/cancel (conf 32→37)   3c6461ff
    emq.2.4 ✅ shipped     ████████████████████  parity closer · depth suite + obliterate fix + harness  3298e4bc
  emq.3     ✅ CLOSED      ████████████████████  parent/flow family · A-1-compat flow design · 3.1–3.5 shipped · emq.3.5 grandchildren the last slice (V-1 Arm-A) → CLOSED Movement I
    emq.3.1 ✅ shipped     ████████████████████  single-queue flow · Flows.add/3 + @enqueue_flow + @complete fan-in · awaiting_children (conf 43→45)   emq-3-1
    emq.3.2 ✅ shipped     ████████████████████  child-result reads · Flows.children_values/3 + dependencies/3 · O1 closed (host-only, @complete Lua byte-unchanged) (conf 45→46)   emq-3-2
    emq.3.3 ✅ shipped     ████████████████████  cross-queue flow · flow:outbox + Pump.sweep deliver_flow_completions + @flow_deliver (:processed HSETNX guard) · eventually-consistent (conf 46→47)   emq-3-3
    emq.3.4 ✅ shipped     ████████████████████  failure-policy + bulk · @retry dead-letter branch + @flow_fail_deliver over §6-reserved :failed/:unsuccessful + add_bulk/3 (conf 47→50)   emq-3-4-build
    emq.3.5 ✅ shipped     ████████████████████  grandchildren / deep recursion · recursive add/3 tree-walk + multi-level fan-in (free over byte-frozen @complete) + the recursive failure hook (Pump host re-emit) · forks RULED S2·A→S1·NORMAL, S3·A, S-Bound·8 · byte-frozen · depth-4 proof (conf 50→52)   emq-3-5

Movement II · the extension family
  emq.4     📋 planned     ░░░░░░░░░░░░░░░░░░░░  groups deepened (split 4.1–4.4; basics shipped M0 as EchoMQ.Lanes)
    emq.4.1 📋 planned     ░░░░░░░░░░░░░░░░░░░░  group control plane · per-group pause/resume + ceilings
    emq.4.2 📋 planned     ░░░░░░░░░░░░░░░░░░░░  group-aware recovery · stalled/crash recovery per group
    emq.4.3 📋 planned     ░░░░░░░░░░░░░░░░░░░░  park-don't-poll metronome · idle groups park, no busy-poll
    emq.4.4 📋 planned     ░░░░░░░░░░░░░░░░░░░░  weighted/deficit rotation + the starvation drill
  emq.5     📋 planned     ░░░░░░░░░░░░░░░░░░░░  batches · bulk consume · shaping · affinity · finish
  emq.6     📋 planned     ░░░░░░░░░░░░░░░░░░░░  lifecycle controls · TTL · distributed cancel · checkpoints
  emq.7     📋 planned     ░░░░░░░░░░░░░░░░░░░░  cache deepened · BCAST · compaction · FULL · invalidation
  emq.8     📋 planned     ░░░░░░░░░░░░░░░░░░░░  proof stack · conformance · engine matrix · telemetry · benchmark

EchoMQ 3.x stream tier · emq3.1–emq3.6 (NO dot — a SEPARATE next-major track, emq3.5 ≠ emq.3.5)   🔒 PROPOSED — Operator slot, hard-gated on emq.0

── roll-up · emq.2 = its 4 sub-rungs · emq.4 = one rung (4.1–4.4 split above) ──
  shipped   11   emq.0 · emq.1 · emq.2.1 · emq.2.2 · emq.2.3 · emq.2.4 · emq.3.1 · emq.3.2 · emq.3.3 · emq.3.4 · emq.3.5
  specced    0   —
  in flight  0   —
  planned    5   emq.4 (→4.1–4.4) · emq.5 · emq.6 · emq.7 · emq.8
  ───────────────────────────────────────────
  11 shipped   ·   emq.2 cluster CLOSED   ·   emq.3 flow family CLOSED (3.1–3.5 ✅ — 3.5 grandchildren / deep recursion, conf 52, Apollo BUILD-GRADE, NORMAL-risk, Arm A) — **Movement I CLOSED → Movement II (emq.4–emq.8) opens**
```

**Convergence target:** all EchoMQ code lands in `echo/apps/echo_mq` above `echo/apps/echo_wire`.
`apps/echomq` is a **capability reference** — its surface is rewritten *fresh* into `echo_mq` (the emq.2
parity cluster + the family rungs), never migrated; once `echo_mq` carries the parity surface,
`apps/echomq` is removed (no compatibility layer, single source of truth).

---

## Milestones — required components per milestone

### EchoMQ 2.x · the three movements

| Movement | Required components (what it must ship) | Rungs | Progress | State |
|---|---|---|---|---|
| **0 · BCS Migration** | the measured drop in the production umbrella: `echo_wire` (extracted wire), `echo_mq` (the 6 bus modules), `echo_cache` (with pluggable `Shadow`), the `EchoData.Bcs*` subtree, the `echo/rungs/` gate ladder tracked, the §5 test/coverage pass | `emq.0` | `████████████████████ 100%` | ✅ shipped `a2d599c8` |
| **I · The Core** | the v1 capability surface rewritten to state-of-the-art inside `echo_mq`: **scheduler + retry vocabulary** (emq.1) · the **full-parity rewrite** — the read/operator/watch/**close** floor (emq.2.1/2.2/2.3/2.4 — cluster CLOSED) · the **parent/flow family CLOSED** — emq.3.1 single-queue + emq.3.2 child-result reads + emq.3.3 cross-queue + emq.3.4 failure-policy/bulk + **emq.3.5 grandchildren/deep recursion** (all SHIPPED) | `emq.1`–`emq.3` | `████████████████████ 100%` | ✅ CLOSED |
| **II · The Extension** | the family ladder: **groups deepened** · **batches** · **lifecycle controls** · **cache deepened** · the **three-layer proof stack** (conformance + engine matrix + telemetry + benchmark gate) | `emq.4`–`emq.8` | `░░░░░░░░░░░░░░░░░░░░ 0%` | 📋 planned |

### EchoMQ 3.x · the stream tier (IN PROGRESS)

Event streams on the certified wire, under the v2 laws, no second protocol. Hard-gates on `emq.0`.

| Milestone | Required components | Rungs | State |
|---|---|---|---|
| **S1 · the writer** | stream verbs on the connector (`XADD`/`XRANGE`/`XREADGROUP`/`XACK`/`XAUTOCLAIM`); `EchoMQ.Stream` — hash-tagged, branded record ids, append == mint order | `emq3.1`–`emq3.2` | 🔒 PROPOSED |
| **S2 · the readers** | BEAM consumer group + one non-BEAM reader, crash re-delivery; retention as declared policy (`MAXLEN` approx, mint-time `MINID` windows) | `emq3.3`–`emq3.4` | 🔒 PROPOSED |
| **S3 · the memory** | the archive — segments folded to SQLite under `EchoCache.Shadow`, box-loss restore, merge reads; time-travel (mint-instant → `XRANGE` bound) + Table hydration | `emq3.5`–`emq3.6` | 🔒 PROPOSED |

### Exchange Platform · the consumer milestones

| Milestone | At the end you can | Rungs | Hard dependency | State |
|---|---|---|---|---|
| **A · walking skeleton** | submit an order → match in a Ring-fed single-writer book → replay from the Journal → post double-entry → drain a settlement lane → read a position at hit speed → watch market data arrive as claims | `TRD.1`–`TRD.5` | as-built only (`+ emq.1` for scheduled settlement) | 🔨 `trd.1.1` building |
| **B · durable core** | replay any instrument from a per-instrument stream lane; attach a non-BEAM (Go/Python) risk consumer through a consumer group with crash re-delivery | `TRD.6` | **`emq3.1–emq3.2` + `emq.0`** | 📋 planned |
| **C · scale-out** | run books partitioned across a BEAM cluster placed by the audited hash; kill a node → book hands off (CP); flood one venue → others hold cluster-wide | `TRD.7`–`TRD.8` | the audited `hash32` + `Keyspace` (as-built) | 📋 planned |

---

## Consolidation with BCS — the grounding map

The BCS manuscript is the **spec source**; the `echo/apps/*` module is the **as-built**; an `emq.N`
rung is the **ship vehicle**. This is the join that ties the three document sets to one truth — every
EchoMQ component traces to a BCS chapter with a committed `PASS n/n` rung record.

| BCS chapter / appendix | Component | As-built module | Shipped by                                                                                                                                                                                              |
|---|---|---|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **B3.1** Fence & Keyspace (`PASS 5/5`) | the `emq:{q}:` grammar + live fence (`echomq:2.0.0`) | `EchoMQ.Keyspace` | `emq.0` ✅                                                                                                                                                                                               |
| **B3.2** Jobs Are Entities (`PASS 5/5`) | the `JOB` row · score-0 pending zset · idempotent enqueue | `EchoMQ.Jobs` | `emq.0` ✅                                                                                                                                                                                               |
| **B3.3** State Machine in Lua (`PASS 6/6`) | claim / complete / retry / dead-letter · attempts as fencing token | `EchoMQ.Jobs` (Lua) | `emq.0` ✅ · retry-vocab `emq.1` ✅                                                                                                                                                                       |
| **B3.4** Fair Lanes (`PASS 8/8`, G1–G8) | per-group rotation · ceilings · pause/resume · park-don't-poll | `EchoMQ.Lanes` | `emq.0` ✅ (structural) · deepened `emq.4` 📋                                                                                                                                                            |
| **B3.5** Bus Meets Stores (`PASS 6/6`) | commands out, results back; exactly-once by provenance | `EchoMQ.Consumer` | `emq.0` ✅                                                                                                                                                                                               |
| **B3.6** Conformance (`PASS 6/6` + `14/14`→…→**`43/43`**) | the scenario harness · the referee habit | `EchoMQ.Conformance` | `emq.0` ✅ (14) · 18 in `emq.1` ✅ · **24** in `emq.2.1` ✅ (+6 read) · **32** in `emq.2.2` ✅ (+8 operator) · **37** in `emq.2.3` ✅ (+5 watch) · **43** in `emq.2.4` ✅ (+6 depth) · proof stack `emq.8` 📋 |
| **B3.7 / App. A / App. H** The Connector (`PASS 8/8`; 454,483 ops/s) | one-pass RESP2/3 · EVALSHA-first · typed fence · auto-resubscribe | `EchoMQ.Connector` over `EchoWire` | `emq.0` ✅ (extraction) · resubscribe `emq.1` ✅ · the event pub/sub seam `emq.2.3` ✅                                                                                                                     |
| **B4.1** Cache-Aside (`PASS 6/6`; 762 ns hit) | declared directory · single-flight fills | `EchoCache.Table` | `emq.0` ✅ · deepened `emq.7` 📋                                                                                                                                                                         |
| **B4.2** Coherence by Mint Time (`PASS 6/6`) | the 29-byte message · newer-wins | `EchoCache.Coherence` | `emq.0` ✅ · `emq.7` 📋                                                                                                                                                                                  |
| **B4.3** Single Writer & the Ring (`PASS 6/6`) | two atomic sequences · counted drops (the Disruptor seat) | `EchoCache.Ring` | `emq.0` ✅                                                                                                                                                                                               |
| **B4.4** The Lane That Remembers (`PASS 6/6`) | per-group SQLite journal · replay == live | `EchoCache.Journal` | `emq.0` ✅ · `synchronous=FULL` `emq.7` 📋                                                                                                                                                               |
| **App. D** The Shadow | pluggable `Shadow` behaviour · Litestream + Copy impls | `EchoCache.Shadow` | `emq.0` ✅                                                                                                                                                                                               |
| **App. F** The Canon | the 14-byte branded snowflake · `hash32` placement | `EchoData.*` | pre-program ✅ (`ee9e5948`)                                                                                                                                                                              |
| **App. G** The Claim Check | claims-only on the bus (never an object) | coherence payloads | `emq.0` ✅                                                                                                                                                                                               |
| **App. I** Partitioned-log examined & **rejected** | → the stream tier built instead | — | `emq3.1–emq3.5` 🔒                                                                                                                                                                                      |
| **the v1 capability reference** (`apps/echomq`) | introspection · operator lifecycle verbs · events/telemetry/locks/stalled — the parity floor | `EchoMQ.{Metrics, Admin, Events, Meter}` + `Jobs` verbs (proposed names) | **`emq.2.1/2.2/2.3` ✅** (the full-parity rewrite; emq.2.4 closer 📐)                                                                                                                                    |
| **drop ROADMAP 2.1** (the gap) | scheduled/repeatable jobs · backoff · resubscribe | `EchoMQ.{Repeat, Backoff, Pump}` | **`emq.1` ✅ (NEW)**                                                                                                                                                                                     |

---

## The program flow

[RECONCILE]

## Master invariant (held at every rung)

> The fork happened exactly once — the v2 key universe is grammar-total (braced `emq:{q}:`, the
> first-byte-disjoint `{emq}:` reserve, the gated branded `job:` position), every Lua key
> declared-or-rooted, the version record (`{emq}:version` = `echomq:2.0.0`) monotone behind the
> five-code fence — and **no later rung re-breaks the wire**. Additive registration is a protocol
> minor; a wire break or computed-floor raise is a major. Claims are phrased against **Valkey,
> current stable line**, enforced as a gate, with honest-row reporting. Process laws: per-app
> testing only (umbrella-wide `mix test` banned), agents run no git, the Director commits by pathspec.

---

## Sources

- **Design canon:** [`emq.design.md`](./emq.design.md) (Operator-approved, S-1…S-7) · **References:** [`emq.references.md`](./emq.references.md)
- **Roadmap (single, consolidated):** [`emq.roadmap.md`](./emq.roadmap.md) — the program ladder + the 2.x line view + the 3.x stream tier (§EchoMQ 3.x); the line/tier specifications are [`emq2.specs.md`](./emq2.specs.md) · [`emq3.specs.md`](./emq3.specs.md)
- **emq.2 parity cluster:** [`specs/emq.2.design.md`](specs/emq.2/emq.2.design.md) (the carve + the 5 ADRs + the Arm A/B fork) · the triads [`specs/emq.2.1.md`](specs/emq.2/emq.2.rungs/emq.2.1.md) · [`specs/emq.2.2.md`](specs/emq.2/emq.2.rungs/emq.2.2.md) · [`specs/emq.2.3.md`](specs/emq.2/emq.2.rungs/emq.2.3.md) · [`specs/emq.2.4.md`](specs/emq.2/emq.2.rungs/emq.2.4.md) (+ `.stories.md` / `.llms.md` each) · the cluster runbook [`specs/emq.2.prompt.md`](specs/emq.2/emq.2.prompt.md) · the 3.0 feature catalog + the v1→v2 parity proof [`emq.features.md`](./emq.features.md)
- **Rung triads / ledgers:** [`specs/emq.0.md`](specs/emq.0/emq.0.md) · [`specs/emq.1.md`](specs/emq.1/emq.1.md)
- **Build-team tooling:** `.claude/skills/echo-mq-{program,surface}.md` + `.claude/skills/echo-mq-{architect,implementor,evaluator}/SKILL.md` · the tuned `.claude/agents/{venus,mars,apollo}.md` (the `## echo_mq program` blocks)
- **BCS grounding:** [`../echo/bcs/bcs.toc.md`](../echo/bcs/bcs.toc.md) · [`../echo/bcs/bcs.roadmap.md`](../echo/bcs/bcs.roadmap.md)
- **As-built:** `echo/apps/echo_mq` · `echo/apps/echo_wire` · `echo/apps/echo_cache` · `echo/apps/echo_data`

