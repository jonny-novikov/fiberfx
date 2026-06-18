# EchoMQ — Program Progress Dashboard

> **The single consolidated status view of the EchoMQ engineering program** — the 2.x bus
> (`emq.0–emq.8`) and the 3.x stream tier (`emq3.1–emq3.6`), grounded chapter-by-chapter in the **BCS
> manuscript**. This file *reports*; the binding artifacts *define* — the design canon
> [`emq.design.md`](./emq.design.md), the single consolidated roadmap [`emq.roadmap.md`](./emq.roadmap.md)
> (the program ladder + the 2.x line view + the 3.x stream tier), and the rung triads under
> [`specs/`](./specs/).
>
> **Per-rung ship detail** — commit ids, conformance deltas, fork rulings, gate tallies, risk grades — lives in
> the frozen [`specs/progress/`](./specs/progress/) ledgers + git; this dashboard stays compact and is re-trued
> at each rung close. Worked consumer: **codemoji** (`echo/apps/codemoji`, live); headline-planned consumer:
> **echo_bot** (`echo/apps/echo_bot` — Telegram notifications at scale).

**One-line state.** The foundation (EchoMQ protocol v2 + the BCS substrate) is **established** (`emq.0`).
**Movement I is CLOSED** — the opener `emq.1` (scheduler + retry), the **emq.2 parity cluster** (read → operator
→ watch → close, 4/4), and the **emq.3 flow family** (single-queue → child-result reads → cross-queue →
failure-policy/bulk → grandchildren/deep recursion, 5/5). The bus is real, measured, and conformance-gated at
**52/52** (Movement I close; **54/54** live with emq.4.1). **Movement II (emq.4–emq.8) opens on a complete core**; its opener **emq.4 (groups deepened) is BUILDING** — **emq.4.1 the control plane SHIPPED** (HIGH-risk: lane re-assignment `reassign/4` + the lane-scoped destructive drain `drain/3`); emq.4.2–4.4 build next. The build team is echo_mq-specialized (the
`echo-mq-{architect,implementor,evaluator}` skills + the tuned [`program/`](./program/) calibrations, driven by
the `echo-mq-ship` /x-mode binding).

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

```text
EchoMQ 2.x — the bus core · convergence target echo/apps/echo_mq

Foundation · land + prove
  emq.0     ✅ established  ████████████████████  EchoMQ protocol v2 + BCS substrate · wire extraction · the store's durable Graft engine · §5 pass

Movement I · scheduler + retry · the parity floor · flows   ✅ CLOSED (conformance 52/52)
  emq.1     ✅ shipped     ████████████████████  scheduler + retry vocabulary (delayed/repeatable · backoff · resubscribe)
  emq.2     ✅ CLOSED      ████████████████████  full-parity rewrite — read → operator → watch → close (2.1–2.4)
  emq.3     ✅ CLOSED      ████████████████████  parent/flow family — single-queue → reads → cross-queue → failure-policy/bulk → grandchildren (3.1–3.5)

Movement II · the extension family
  emq.4     🔨 building    █████░░░░░░░░░░░░░░░  groups deepened — 4.1 control plane ✅ SHIPPED (reassign + lane-drain · HIGH-risk · 54/54) · 4.2 group recovery · 4.3 metronome HIGH · 4.4 weighted/deficit+drill
  emq.5     📋 planned     ░░░░░░░░░░░░░░░░░░░░  batches · bulk consume · shaping · affinity · finish
  emq.6     📋 planned     ░░░░░░░░░░░░░░░░░░░░  lifecycle controls · TTL · distributed cancel · checkpoints
  emq.7     📋 planned     ░░░░░░░░░░░░░░░░░░░░  cache deepened · BCAST · compaction · FULL · invalidation
  emq.8     📋 planned     ░░░░░░░░░░░░░░░░░░░░  proof stack · conformance · engine matrix · telemetry · benchmark

EchoMQ 3.x stream tier · emq3.1–emq3.6 (NO dot — a SEPARATE next-major track, emq3.5 ≠ emq.3.5)   🔒 PROPOSED — Operator slot, hard-gated on emq.0

── roll-up ──
  established  emq.0 — the foundation
  shipped     Movement I — emq.1 · emq.2 (2.1–2.4) · emq.3 (3.1–3.5) · conformance 52/52
  building    emq.4 — groups deepened · 4.1 control plane ✅ SHIPPED (reassign + lane-drain) · 4.2–4.4 build next
  planned     emq.5 · emq.6 · emq.7 · emq.8
  ───────────────────────────────────────────
  Movement I CLOSED → Movement II (emq.4–emq.8) opens on a complete core
```

**Convergence target:** all EchoMQ code lands in `echo/apps/echo_mq` above `echo/apps/echo_wire`. The legacy v1
line was rewritten *fresh* into `echo_mq` (the emq.2 parity cluster + the family rungs), never migrated, then
removed — single source of truth, no compatibility layer.

---

## Milestones — required components per milestone

### EchoMQ 2.x · the foundation + two movements

| Stage | Required components (what it must ship) | Rungs | State |
|---|---|---|---|
| **Foundation** | the measured drop in the production umbrella: `echo_wire` (extracted wire), `echo_mq` (the bus modules), `echo_store` (the store; durable replication via the `EchoStore.Graft` engine, the `Shadow` behaviour retired — `store.design.md` §2), the `EchoData.Bcs*` subtree, the `echo/rungs/` gate ladder, the §5 test/coverage pass | `emq.0` | ✅ established |
| **I · The Core** | the v1 capability surface rewritten state-of-the-art inside `echo_mq`: scheduler + retry (emq.1) · the full-parity read/operator/watch/close floor (emq.2.1–2.4) · the parent/flow family (emq.3.1–3.5) | `emq.1`–`emq.3` | ✅ CLOSED |
| **II · The Extension** | the family ladder: groups deepened · batches · lifecycle controls · cache deepened · the three-layer proof stack (conformance + engine matrix + telemetry + benchmark gate) | `emq.4`–`emq.8` | 📋 planned · **emq.4 🔨 BUILDING (4.1 ✅)** |

### EchoMQ 3.x · the stream tier

Event streams on the certified wire, under the v2 laws, no second protocol. Hard-gates on `emq.0`.

| Milestone | Required components | Rungs | State |
|---|---|---|---|
| **S1 · the writer** | stream verbs on the connector (`XADD`/`XRANGE`/`XREADGROUP`/`XACK`/`XAUTOCLAIM`); `EchoMQ.Stream` — hash-tagged, branded record ids, append == mint order | `emq3.1`–`emq3.2` | 🔒 PROPOSED |
| **S2 · the readers** | BEAM consumer group + one non-BEAM reader, crash re-delivery; retention as declared policy (`MAXLEN` approx, mint-time `MINID` windows) | `emq3.3`–`emq3.4` | 🔒 PROPOSED |
| **S3 · the memory** | the archive — segments folded into the `EchoStore.Graft` engine (local CubDB → Tigris), box-loss restore, merge reads; time-travel (mint-instant → `XRANGE` bound) + Table hydration | `emq3.5`–`emq3.6` | 🔒 PROPOSED |

### The consumers

- **codemoji** (`echo/apps/codemoji`) — the **worked consumer today**. The Mastermind-style game mints branded
  ids (`RND`/`USR`/`JOB`/`GES`), enqueues guesses on per-player `EchoMQ.Lanes`, drains them with two
  `EchoMQ.Consumer` instances, scores under a single authority, publishes `EchoMQ.Events`, holds a Valkey
  sorted-set leaderboard, and settles prizes on a second queue (the move-then-settle pattern). A live exercise
  of the bus + the `EchoData.Bcs` property stores.
- **echo_bot** (`echo/apps/echo_bot`) — the **headline-planned consumer**. Telegram-bot notifications at scale;
  the integration seam is `EchoBot.Platform.Telegram.send_reply/3`. As built today echo_bot sends Telegram
  replies synchronously with no bus coupling — forward-tense: a planned `EchoMQ` enqueue/drain in front of the
  notification fan-out.

---

## Consolidation with BCS — the grounding map

The BCS manuscript is the **spec source**; the `echo/apps/*` module is the **as-built**; an `emq.N` rung is the
**ship vehicle**. This is the join that ties the three document sets to one truth — every EchoMQ component traces
to a BCS chapter with a committed `PASS n/n` rung record (the figures live in the frozen ledgers).

| BCS chapter / appendix | Component | As-built module | Shipped by |
|---|---|---|---|
| **B3.1** Fence & Keyspace (`PASS 5/5`) | the `emq:{q}:` grammar + live fence (`echomq:2.0.0`) | `EchoMQ.Keyspace` | `emq.0` ✅ |
| **B3.2** Jobs Are Entities (`PASS 5/5`) | the `JOB` row · score-0 pending zset · idempotent enqueue | `EchoMQ.Jobs` | `emq.0` ✅ |
| **B3.3** State Machine in Lua (`PASS 6/6`) | claim / complete / retry / dead-letter · attempts as fencing token | `EchoMQ.Jobs` (Lua) | `emq.0` ✅ · retry-vocab `emq.1` ✅ |
| **B3.4** Fair Lanes (`PASS 8/8`, G1–G8) | per-group rotation · ceilings · pause/resume · park-don't-poll | `EchoMQ.Lanes` | `emq.0` ✅ (structural) · deepened `emq.4` 🔨 (4.1 control plane ✅ reassign + lane-drain · 4.2–4.4 next) |
| **B3.5** Bus Meets Stores (`PASS 6/6`) | commands out, results back; exactly-once by provenance | `EchoMQ.Consumer` | `emq.0` ✅ |
| **B3.6** Conformance (`14/14` → … → `52/52`) | the scenario harness · the referee habit | `EchoMQ.Conformance` | `emq.0` ✅ (14) → `emq.1` (18) → `emq.2.1–2.4` ✅ (read/operator/watch/depth → 43) → `emq.3.1–3.5` ✅ (the flow family → **52**) · proof stack `emq.8` 📋 |
| **B3.7 / App. A / App. H** The Connector | one-pass RESP2/3 · EVALSHA-first · typed fence · auto-resubscribe | `EchoMQ.Connector` over `EchoWire` | `emq.0` ✅ (extraction) · resubscribe `emq.1` ✅ · the event pub/sub seam `emq.2.3` ✅ |
| **B4.1** Cache-Aside (`PASS 6/6`) | declared directory · single-flight fills | `EchoStore.Table` | `emq.0` ✅ · deepened `emq.7` 📋 |
| **B4.2** Coherence by Mint Time (`PASS 6/6`) | the 29-byte message · newer-wins | `EchoStore.Coherence` | `emq.0` ✅ · `emq.7` 📋 |
| **B4.3** Single Writer & the Ring (`PASS 6/6`) | two atomic sequences · counted drops (the Disruptor seat) | `EchoStore.Ring` | `emq.0` ✅ |
| **B4.4** The Lane That Remembers (`PASS 6/6`) | per-group SQLite journal · replay == live | `EchoStore.Journal` | `emq.0` ✅ · `synchronous=FULL` `emq.7` 📋 |
| **App. D** The Shadow (retired) | superseded by the native replication engine — durable, replicated state is `EchoStore.Graft` streamed to Tigris (`store.design.md` §2) | `EchoStore.Graft` | `emq.0` imported · retired |
| **App. F** The Canon | the 14-byte branded snowflake · `hash32` placement | `EchoData.*` | pre-program ✅ |
| **App. G** The Claim Check | claims-only on the bus (never an object) | coherence payloads | `emq.0` ✅ |
| **App. I** Partitioned-log examined & **rejected** | → the stream tier built instead | — | `emq3.1–emq3.6` 🔒 |
| **the v1 capability reference** | introspection · operator lifecycle verbs · events/telemetry/locks/stalled — the parity floor | `EchoMQ.{Metrics, Admin, Events, Meter}` + `Jobs` verbs | **`emq.2.1`–`emq.2.4` ✅** (the full-parity rewrite, cluster CLOSED) |
| **drop ROADMAP 2.1** (the gap) | scheduled/repeatable jobs · backoff · resubscribe | `EchoMQ.{Repeat, Backoff, Pump}` | **`emq.1` ✅** |

---

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
- **Roadmap (single, consolidated):** [`emq.roadmap.md`](./emq.roadmap.md) — the program ladder + the 2.x line view + the 3.x stream tier; the binding line laws are the design canon [`emq.design.md`](./emq.design.md)
- **Rung triads / ledgers:** the triads under [`specs/`](./specs/) (`emq.0`/`emq.1`/`emq.2`/`emq.3` shipped); the per-rung ship ledgers under [`specs/progress/`](./specs/progress/)
- **Build-team tooling:** `.claude/skills/echo-mq-{program,surface}.md` + `.claude/skills/echo-mq-{architect,implementor,evaluator}/SKILL.md` · the tuned [`program/`](./program/) calibrations (`emq.{venus,mars,apollo}.md`)
- **BCS grounding:** [`../echo/bcs/bcs.toc.md`](../echo/bcs/bcs.toc.md) · [`../echo/bcs/bcs.roadmap.md`](../echo/bcs/bcs.roadmap.md)
- **As-built:** `echo/apps/echo_mq` · `echo/apps/echo_wire` · `echo/apps/echo_store` · `echo/apps/echo_data` · the consumers `echo/apps/codemoji` · `echo/apps/echo_bot`
