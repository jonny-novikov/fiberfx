# EchoMQ Course — Progress Dashboard

> The build status of the **"EchoMQ, In Depth" course** (`/echomq`) on the **three-pillar spine** — chapter by
> chapter. This file reports the course OUTPUT; the program canon it grounds in is [`../emq.roadmap.md`](../emq.roadmap.md)
> (incl. the §stream-tier canon the Bus teaches from) and the structural authority is
> [`echo_mq.course.md`](./echo_mq.course.md). Each built page has a **route-mirror md** under `markdown/<route>.md`
> carrying the **`[RECONCILE]` shadow**; the HTML never contains a `[RECONCILE]` marker.
>
> **Re-true** whenever a chapter's pages / md change. Counts are filesystem truth (`html/echomq/` + `markdown/`).

**One-line state.** The course was **re-pivoted** to "EchoMQ, In Depth" — one shipped system, three pillars (Queue ·
Bus · Cache) over a Protocol substrate, with a Proof chapter, taught Elixir-canonical, as shipped. **Batch 1 SHIPPED
the foundation: the Overview (5) + The Protocol (18) = 23 pages**; **The Queue pillar (22) is now SHIPPED** — all
gate-PASS A+, `[RECONCILE]` = 0 (all real code), fresh-built to the target via the new shell-assembler tool
(`tool/build_page.py`). The old `core/substrate/groups/…` dirs are **transitional** (superseded as their pillar chapter
lands). **Spine: ~91 pages planned · 45 / 91 built (foundation + the Queue) · next: the Bus + the Cache + the Proof.**

---

## Legend

| Symbol | State | Meaning |
|---|---|---|
| ✅ | **DONE** | every planned page built + md-mirrored (with `[RECONCILE]` markers where canon-grounded) |
| 🔨 | **BUILDING** | this batch's scope — partly built |
| 📋 | **PLANNED** | on the spine, no page built yet |
| ⏚ | **TRANSITIONAL** | an old-structure dir on disk, superseded when its pillar chapter lands |

ANSI bars are 20 cells: `█` built · `░` remaining. A chapter's planned count = landing + (content modules × 4: hub + 3
dives) + workshop.

---

## At a glance — the three-pillar spine

```
EchoMQ, In Depth        ██████████░░░░░░░░░░    45 / 91 pages   (foundation + the Queue shipped)

  Overview              ████████████████████    5 / 5     ✅  home + landing + 3 dives
  The Protocol          ████████████████████   18 / 18    ✅  4 modules + workshop · REAL code
  ── pillar I ──────────────────────────────────────────────
  The Queue             ████████████████████   22 / 22    ✅  5 modules + workshop · REAL code · [RECONCILE]=0
  ── pillar II ─────────────────────────────────────────────
  The Bus               ░░░░░░░░░░░░░░░░░░░░    0 / 18    📋  Events real · streams CANON ([RECONCILE]-heavy)
  ── pillar III ────────────────────────────────────────────
  The Cache             ░░░░░░░░░░░░░░░░░░░░    0 / 14    📋  3 modules + workshop · REAL code
  ── cross-cut ─────────────────────────────────────────────
  The Proof             ░░░░░░░░░░░░░░░░░░░░    0 / 14    📋  conformance · telemetry · benchmark

  ⏚ transitional (old structure, on disk, superseded as pillars land):
     html/echomq/{core, substrate, groups, batches, lifecycle, production}
```

---

## Per-chapter module breakdown (the spine)

### Overview — `/echomq` + `/echomq/overview` — 🔨 Batch 1 (rebuilt in place)
Orientation, flat dives (no `.applied` block). 5 pages.

| Page | Route | Grounding | Status |
|---|---|---|---|
| Home (the six-section map) | `/echomq` | thesis | 🔨 |
| Overview landing | `/echomq/overview` | thesis | 🔨 |
| The three pillars | `/echomq/overview/the-three-pillars` | thesis | 🔨 |
| The protocol below the line | `/echomq/overview/the-protocol-below-the-line` | real (Keyspace/Lua) | 🔨 |
| The door & the BCS family | `/echomq/overview/the-door` | thesis + doors | 🔨 |

### The Protocol — `/echomq/protocol` — 🔨 Batch 1 (rebuilt in place) — REAL code
The four-layer substrate. Landing + 4 modules (hub + 3 dives) + workshop. 18 pages.

| Module | Route | Grounding | Status |
|---|---|---|---|
| Landing | `/echomq/protocol` | real | 🔨 |
| The owned keyspace | `/echomq/protocol/the-owned-keyspace` | `EchoMQ.Keyspace` | 🔨 |
| The record hash | `/echomq/protocol/the-record-hash` | `EchoMQ.Jobs` (the row) | 🔨 |
| The Lua layer & EVALSHA | `/echomq/protocol/the-lua-layer` | `EchoMQ.Script`/`Connector` + inline Lua | 🔨 |
| Immutability & branded ids | `/echomq/protocol/immutability-and-branded-ids` | the gate + version fence | 🔨 |
| Workshop | `/echomq/protocol/workshop` | real | 🔨 |

### The Queue — `/echomq/queue` — ✅ DONE — REAL code
Distribute work. Landing + 5 modules (hub + 3 dives) + workshop = 22 pages, all gate-PASS A+, `[RECONCILE]` = 0 (all
real code, verified in `echo/apps/echo_mq`). Built via the shell-assembler tool (`tool/build_page.py`) — the donor shell
is `the-lifecycle/claim-and-the-lease.html` (dive) + `the-lifecycle/index.html` (hub).

| Module | Route | Grounding | Status |
|---|---|---|---|
| Landing | `/echomq/queue` | real | ✅ |
| The lifecycle | `/echomq/queue/the-lifecycle` | `EchoMQ.Jobs` + `Keyspace` (the four sets, claim/lease, completion/recovery) | ✅ |
| Jobs, lanes & the consumer | `/echomq/queue/jobs-lanes-consumer` | `EchoMQ.{Jobs,Lanes,Consumer}` (enqueue/claim, fair lanes/ring, the loop) | ✅ |
| Batches | `/echomq/queue/batches` | `EchoMQ.{Jobs,Flows}` (enqueue-many, bulk-flows, batch lease-extension) | ✅ |
| Lifecycle controls | `/echomq/queue/lifecycle-controls` | `EchoMQ.{Backoff,Repeat,Cancel,Stalled,Admin,Jobs}` (scheduling/recurrence, cancellation/checkpoints, the operator plane) | ✅ |
| Flows | `/echomq/queue/flows` | `EchoMQ.Flows` (parent/children, reading results, cross-queue & failure policy) | ✅ |
| Workshop | `/echomq/queue/workshop` | real | ✅ |

### The Bus — `/echomq/bus` — 📋 planned — Events REAL, streams CANON
`pub-sub-events` (real `EchoMQ.Events`) · `the-event-log` · `consumer-groups` · `time-travel-and-archive` (canon →
`[RECONCILE]`) · `workshop` (18 pages). The streams depth grounds in `emq.roadmap.md` §stream-tier + `emq3.specs.md`.

### The Cache — `/echomq/cache` — 📋 planned — REAL code
`cache-aside-two-layers · single-flight-and-ttl · coherence-on-the-bus · workshop` (14 pages). Grounds in
`EchoStore.{Table,Ring,Journal,Coherence}`.

### The Proof — `/echomq/proof` — 📋 planned
`the-conformance-suite · telemetry-and-tracing · the-benchmark-gate · workshop` (14 pages). Grounds in
`EchoMQ.{Conformance,Meter,Metrics}` (benchmark partial → some `[RECONCILE]`).

---

## The `[RECONCILE]` ledger (the iteration-2 worklist)

Every claim written **ahead of the as-built code** carries a `[RECONCILE]` marker in its route-mirror md
(`markdown/<route>.md`). They are the worklist for **iteration 2** — swept and resolved against the shipped upstream
stream tier when it lands. Re-index with:

```bash
grep -rn '\[RECONCILE' docs/echo_mq/course/markdown/   # the live ledger
```

| Area | Expected `[RECONCILE]` density | Why |
|---|---|---|
| Overview · `the-three-pillars` / `the-door` | light | the Bus paragraph names the event log + streams (canon) |
| The Protocol (all) | ~none | all real code (`EchoMQ.Keyspace` + the inline Lua) |
| The Queue (all) | **none — 0 on disk (confirmed)** | all real code (`EchoMQ.{Jobs,Lanes,Consumer,Cancel,Stalled,Backoff,Repeat,Admin,Flows}` + `Keyspace`) |
| The Bus · `the-event-log` / `consumer-groups` / `time-travel-and-archive` | **heavy** | the whole streams depth is design canon, not yet on disk |
| The Proof · `the-benchmark-gate` | some | the benchmark surface is partial |

(Batch 1 populated the Overview + Protocol markers; the Queue carries **0** `[RECONCILE]` markers — all real code,
swept clean on the 22 pages. The heavy Bus markers land when the Bus pillar is built.)

---

## Next build front
1. ~~**Overview** + **The Protocol** — Batch 1~~ ✅ shipped (the foundation).
2. ~~**The Queue** — the dominant pillar, all real code (`EchoMQ.Jobs`/`Lanes`/`Consumer`/`Flows`).~~ ✅ shipped (22 pages, `[RECONCILE]`=0).
3. **The Bus** — the big new construction: `EchoMQ.Events` real + the stream tier from canon (`[RECONCILE]`-heavy). **← next.**
4. **The Cache** + **The Proof**.

---

## Sources
- **Course output:** `html/echomq/` (served) · `docs/echo_mq/course/markdown/` (md mirror + `[RECONCILE]` shadow) ·
  [`echo_mq.course.md`](./echo_mq.course.md) (the spine) · `<chapter>.prompt.md` (the persistent fan-out briefs).
- **Structure & grounding:** [`../emq.roadmap.md`](../emq.roadmap.md) (incl. §stream-tier) · `../emq3.specs.md` · the
  skill digest `.claude/skills/echo-mq-writer/references/course-map.md`.
- **Authoring:** `/echo-mq-reconcile` (wipe + rebuild to target) · `/echo-mq-write` (greenfield) · the
  `echo-mq-expert` agent + the `echo-mq-writer` skill.
