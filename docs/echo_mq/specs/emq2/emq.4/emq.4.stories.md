# EMQ.4 · user stories — groups deepened (the fair-lanes family at production depth)

> Who wants the groups family deepened, what they need, and how we will know it works. Each story is Connextra with
> Given/When/Then acceptance, an INVEST line naming the invariant(s) it encodes, and a Priority/Size/Implements line;
> the file ends with a Coverage map (story → rung → invariant). The standing **`EMQ.4-US-GATE`** carries the Valkey
> gate (design §7) — a structural gate. emq.4 is the rung that **OPENS Movement II**; this is the **family** stories
> file (the family contract + the carve + the forks), and the per-sub-rung acceptance lives in each sub-rung's
> `.stories.md` (a separate fan-out — `./emq.4.rungs/emq.4.N.stories.md`).

## EMQ.4-US1 — an operator re-shapes live group traffic (the control plane — emq.4.1)

As a **multi-tenant bus operator**, I want to move a member from one lane to another and to pause/resume/limit/drain a
lane while traffic flows, so that I can re-shape contention live — without a numeric per-job priority and without
stopping the queue — when one tenant's work must move or yield.

Acceptance criteria
- Given a member on lane A and a valid branded destination lane B (same queue), when `EchoMQ.Lanes` re-assignment
  moves it, then the member leaves A's `g:<A>:pending` ZSET and enters B's `g:<B>:pending` ZSET (one slot → one atomic
  move), and the ring reflects both lanes' new serviceability — **no numeric priority is involved** (the v1
  `changePriority-7` re-aim: mint order IS the order theorem; per-group lanes replace priority).
- Given several lanes with backlog, when `Metrics.lane_depths/3` is read (the v1 `getCountsPerPriority-4` re-aim),
  then it answers each group's separate live backlog over its lane ZSET, branded-gated.
- Given a deepened control verb (pause/resume/limit/drain) on a live lane, when it is issued, then it re-shapes the
  ring (parks/returns/ceilings the lane) with a wake for any parked consumer, leaving other lanes' rotation
  unaffected.

INVEST — independent (the operator surface); testable by the re-assignment `:valkey` scenario (member moves A→B, the
ring updates) + a `lane_depths/3` read; encodes EMQ.4-INV1 (no new key family), EMQ.4-INV4 (branded source/dest),
EMQ.4-INV6. Priority: must · Size: 3 · Implements: emq.4.1 (the control plane).

## EMQ.4-US2 — a stalled grouped member recovers into its own lane (group-aware recovery — emq.4.2)

As a **bus consumer running per-tenant lanes**, I want an expired-lease member to return to **its own lane** (not a
global pool) when a worker dies, so that recovery respects fairness — a crashed tenant's work re-queues behind that
tenant's identity, never jumping the ring.

Acceptance criteria
- Given a grouped job whose lease lapses, when the group-scoped sweep runs, then the member returns to its lane
  `g:<g>:pending` (NOT the flat `pending`), `gactive` for the group is decremented, the lane re-rings if serviceable,
  and a parked consumer is woken — deepening the shipped group-aware `@reap` and its `stalled_group` scenario.
- Given the sweep reads a lease, when it computes expiry, then it reads `TIME` **server-side** inside the script (the
  as-built `@reap`/`@gclaim` pattern), never a host clock.
- Given a **non-grouped** job whose lease lapses, when recovery runs, then the shipped per-job `@reap` path is
  **byte-unchanged** (the deepening adds the group-scoped sweep beside it, it does not rewrite the non-group path).

INVEST — independent (the recovery surface); testable by the group-scoped recovery `:valkey` scenario (lapsed grouped
lease → lane, not pool) + the byte-unchanged non-group `@reap`; encodes EMQ.4-INV3, EMQ.4-INV5, EMQ.4-INV6.
Priority: must · Size: 3 · Implements: emq.4.2 (group-aware recovery).

## EMQ.4-US3 — a consumer parks and is woken, never busy-polls (the metronome — emq.4.3)

As a **bus consumer at rest**, I want to PARK (block) and be woken the moment my lane becomes serviceable instead of
busy-polling, so that an idle consumer costs the wire nothing and a ready job is served within the beat — with **no
lost wakeup** when work arrives exactly as I park.

Acceptance criteria
- Given a parked consumer (`BLPOP` on the `wake` key, the beat as the fallback — the shipped `Consumer` loop deepened),
  when a member is admitted to its lane while it is parked, then the consumer is woken **within the beat** and serves
  the member — the wake is pushed by the admitting transition (the shipped wake protocol), and **no wakeup is lost**
  under a concurrent admit-then-park.
- Given several parked consumers on one queue, when wakes arrive, then they are distributed fairly across the parked
  consumers (the deepening's multi-consumer fairness — no permanent starvation of one parked consumer).
- Given the metronome's process/lease surface (a lost-wakeup race and a same-millisecond mint are cross-run hazards),
  when the metronome suites run, then they run under the **≥100-iteration determinism loop** owning the machine (one
  green run is NOT proof — the master-invariant hazard), and a lost wakeup or a mint collision is caught there.

INVEST — independent (the metronome contract); testable by the admit-while-parked `:valkey` scenario (wake before the
beat) + the ≥100 loop on the process/lease suites; encodes EMQ.4-INV7, EMQ.4-INV5. Priority: must · Size: 5 ·
Implements: emq.4.3 (the park-don't-poll metronome — HIGH-risk).

## EMQ.4-US4 — no lane starves under skew (weighted/deficit rotation + the drill — emq.4.4)

As a **multi-tenant bus operator under load skew**, I want fair-share rotation beyond round-robin and a drill that
proves no lane starves, so that a heavy tenant cannot monopolize the machine and a quiet tenant is still served — fair
share is a server-side guarantee, not a client hint.

Acceptance criteria
- Given lanes with assigned weights, when claims rotate, then lanes are served **in proportion to weight** (weighted /
  deficit round-robin over the ring) — a higher-weight lane gets proportionally more serves, never all of them.
- Given sustained load skew (one lane flooded, others trickling), when the **starvation drill** runs, then **every**
  lane's depth reaches zero (no lane is starved), proven over the drill's window.
- Given the rung's realization, when the diff is read, then either it lands **additively** (a separate weighted-claim
  path, `@gclaim` byte-unchanged) OR it **edits `@gclaim`** under the byte-freeze discipline (every OTHER frozen lane
  script byte-identical to HEAD, `grep redis.call` = 0) with **Apollo MANDATORY** — the weighted-rotation mechanism
  fork (Fork B) ruled at the pre-build reconcile.

INVEST — independent (the fairness capstone); testable by the weighted-proportion scenario + the starvation-drill
scenario (every lane drains under skew); encodes EMQ.4-INV7, EMQ.4-INV3 (byte-freeze the unedited scripts).
Priority: must · Size: 5 · Implements: emq.4.4 (weighted/deficit rotation + the drill).

## EMQ.4-US5 — the deepening costs the wire nothing (no break, declared keys, additive minor)

As a **protocol maintainer**, I want every emq.4 deepening to ride the shipped lane keyspace under the declared-keys
law and to grow conformance only additively, so that the multi-tenant depth costs the wire nothing — no new key
family, no new fence code, no broken scenario.

Acceptance criteria
- Given any new script a rung adds, when the A-1 lint scans it, then **every** key is a shipped `g:`-segment lane key
  (`g:<group>:pending`/`ring`/`paused`/`glimit`/`gactive`/`wake`) — each in `KEYS[]` or derived from a declared
  `KEYS[n]` queue-base root by the registered grammar — and **no** key is a new family or read out of a data value.
- Given the wire, when `{emq}:version` is read after connect, then it returns `echomq:2.0.0` (the five-code fence
  union stands unextended; no new wire class — the kind law reuses `EMQKIND`; no new transport).
- Given the prior conformance set, when emq.4's scenarios are added, then the **52** prior scenarios pass
  **byte-unchanged** (name + contract + verdict body, git-verified) and the count re-pins **52 → N** in **both**
  pinning tests (the additive-minor law).

INVEST — independent (the wire-cost contract); testable by the A-1 lint + the `{emq}:version` read + the git-verified
byte-unchanged 52; encodes EMQ.4-INV1, EMQ.4-INV2, EMQ.4-INV6. Priority: must · Size: 2 · Implements: the family DoD
(no break).

## EMQ.4-US6 — the family boundary holds (no pre-emption, no re-ship)

As a **program Director**, I want emq.4 to deepen the groups family and nothing else, so that no later Movement-II
rung is pre-empted and no emq.2/emq.3 surface is re-shipped — the carve is auditable and the ladder stays clean.

Acceptance criteria
- Given emq.4's deliverables, when they are read, then they touch the **groups (lanes)** surface only — no
  batch-consume (emq.5), no lifecycle/distributed-cancel (emq.6), no cache (emq.7), no telemetry-contract/proof
  (emq.8) surface; a lane is **not** a batch (emq.5 is bulk *consumption*) and **not** a flow (emq.3 is a *dependency
  graph*).
- Given the carve, when the sub-rungs are listed, then they are dependency-ordered (emq.4.1 control plane · 4.2
  group-aware recovery · 4.3 the metronome · 4.4 weighted/deficit + the drill), each a full triad + a runbook, one
  increment per run — the Operator-ruled spine, not re-decomposed.
- Given a shipped emq.2/emq.3 surface, when emq.4 lands, then emq.4 **re-ships none of it** (it stands ON
  `EchoMQ.Lanes`/`Consumer`/`@reap`, it does not rebuild them).

INVEST — independent (the boundary contract); testable by the deliverable touch-set (groups-only) + the carve order;
encodes EMQ.4-INV8. Priority: must · Size: 1 · Implements: the carve; the family boundary.

## EMQ.4-US-FORK — the shaping forks are settled at the right gate (Venus surfaces, the Operator rules)

As a **program Operator**, I want the emq.4 shaping forks surfaced with arms + costs + a recommendation and ruled at
the right gate, so that no sub-rung silently commits a process/representation/boundary decision that is mine to make.

Acceptance criteria
- Given **Fork A** (the emq.4.3 boundary — deepen the shipped metronome vs found a new blocking primitive), when
  emq.4.3 opens, then the fork is recorded with both arms steelmanned + the recommendation (Arm A, deepen), and it is
  **settled before the emq.4.3 build** (the touch-set depends on it).
- Given **Fork B** (the weighted-rotation mechanism — deficit counter vs weighted multi-pop vs per-lane budget), when
  emq.4.4 opens, then all three arms are surfaced at its pre-build reconcile with the `@gclaim`-edit risk trade-off,
  and the Operator rules the mechanism (no new key family any arm).
- Given **Fork C** (the intra-group priority dimension — land at emq.4.1 vs park), when emq.4.1 opens, then the fork
  is recorded with the score-0-lane-invariant cost and the recommendation (Arm B, park), surfaced for the Operator's
  optional ruling.

INVEST — independent (the gate that precedes the fork-bearing builds); testable by the ledger record + each
sub-rung's touch-set matching the ruled arm; encodes EMQ.4-INV7 (Fork A/B), EMQ.4-INV1 (Fork B/C). Priority: must ·
Size: 1 · Implements: Forks A/B/C, the family DoD gate.

## EMQ.4-US-GATE — the Valkey gate (specification by example)

As a **release gate**, I want the deepened groups family proven on the certified wire under honest-row reporting, so
that the v2 laws bind at the wire and a host without Valkey reports its row honestly (design §7, S-4).

Acceptance criteria
- Given the engine-hygiene allowlist {Valkey, Redis-as-the-historical-row}, when the lane suites run, then they run
  against **Valkey on port 6390** (the truth row; `redis-cli -p 6390 ping` → `PONG`); a host without Valkey runs the
  probes elsewhere and reports them as that row, never the truth row.
- Given `GET {emq}:version`, when read after the bus connects, then it returns `echomq:2.0.0` (the connect-scoped
  fence — emq.4 changes nothing about the fence; the five-code union stands unextended, INV1).
- Given grammar totality, when a lane key is parsed, then it classifies under the §6 grammar (the `g:<group>:pending`
  / `ring` / `paused` / `glimit` / `gactive` / `wake` members), the queue name extracts as the `{q}` hashtag, and
  `q ≠ "emq"` keeps the slot families disjoint — emq.4 edits the grammar's shape **not at all** (INV1).
- Given the conformance run, when `EchoMQ.Conformance.run/2` executes over a live connection, then it prints one line
  per scenario, the prior **52** are byte-unchanged, and the new group scenarios are present (the count re-pinned in
  both pinning tests — the additive-minor law).

INVEST — independent (the standing structural gate); testable by the honest-row run + `{emq}:version` + grammar
totality + the additive-minor conformance; encodes EMQ.4-INV1, EMQ.4-INV6. Priority: must · Size: 1 · Implements:
design §7, S-4 (the structural gate).

## Coverage

| Family Deliverable / Fork | Rung | Story | Invariant(s) |
|---|---|---|---|
| The control plane (lane move/re-assignment; deepened pause/resume/limit/drain; the v1 priority-command re-aims) | emq.4.1 | US1 | INV1, INV4, INV6 |
| Group-aware recovery (the group-scoped stalled-sweep returning members to their lane, ring-respecting, server clock) | emq.4.2 | US2 | INV3, INV5, INV6 |
| The park-don't-poll metronome (park + wake on availability, no lost wakeup, multi-consumer fairness, the ≥100 loop) | emq.4.3 | US3 | INV7, INV5 |
| Weighted/deficit rotation + the starvation drill (fair-share beyond round-robin; no lane starves under skew) | emq.4.4 | US4 | INV7, INV3 |
| No wire break (no new key family; declared keys; the 52 byte-unchanged; the additive-minor count) | all | US5 | INV1, INV2, INV6 |
| The family boundary (groups-only; the dependency-ordered carve; no re-ship of emq.2/emq.3) | all | US6 | INV8 |
| Forks A (emq.4.3 boundary) · B (weighted mechanism) · C (intra-group priority) — Operator-ruled at the right gate | per-rung | US-FORK | INV7, INV1 |
| The Valkey structural gate (honest-row; `{emq}:version`; grammar totality; additive-minor conformance) | all | US-GATE | INV1, INV6 |

The per-sub-rung Deliverables (each emq.4.N's D1–Dn) trace in the sub-rung's `.stories.md` (a separate fan-out —
`./emq.4.rungs/emq.4.N.stories.md`); this file covers the **family** contract, the carve, and the forks. Spec body:
[`./emq.4.md`](emq.4.md) (authoritative).
