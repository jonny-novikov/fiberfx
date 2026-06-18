# EMQ.4 · Groups deepened — the fair-lanes family taken to production depth (Movement II, the opener)

> **Status: 📐 PROPOSED — the family spec + the carve, this design cycle** (no production code this cycle; the
> family decomposes into four sub-rungs the way emq.2 and emq.3 did, and the sub-rung carves
> [`./emq.4.rungs/emq.4.1.md`](./emq.4.rungs/emq.4.1.md) … [`./emq.4.4.md`](./emq.4.rungs/emq.4.4.md) are a SEPARATE
> fan-out, not authored here). emq.4 is **the rung that OPENS Movement II**: the displaced fair-lanes (groups)
> family the roadmap RULED into this slot ([`../emq.roadmap.md`](../../emq.roadmap.md) seam 2, CLOSED; design §10
> seam 2 / §4 cluster 2), **deepened** from the shipped `EchoMQ.Lanes` basics to the depth a multi-tenant
> production bus needs. The basics ALREADY shipped (B3.4 "Fair Lanes", PASS 8/8 G1–G8) — emq.4 does not found the
> family, it deepens it; every axis is **additive over the shipped `g:`-segment keyspace**, nothing here is a wire
> break.
> **Risk: MIXED** — emq.4.1 (control plane) and emq.4.2 (group-aware recovery) are **NORMAL** (they deepen shipped
> surfaces); emq.4.3 (the metronome) is **HIGH** (it founds a new process/lease surface over the shipped park loop —
> Apollo mandatory, the Director's verify deepens to the ≥100 determinism loop when it builds); emq.4.4
> (weighted/deficit rotation) is **HIGH iff it edits the shipped `@gclaim` ring rotation** (then byte-freeze
> discipline + Apollo mandatory). Each per-rung grade is stated forward in **Per-rung risk** below.

## 0 · The basics shipped — what "deepened" means, and why now

**What the basics already are (as-built, present-tense — `echo/apps/echo_mq/lib/echo_mq/lanes.ex`).** A *lane* is a
per-group pending set named by a branded identity (`emq:{q}:g:<group>:pending`, a score-0 ZSET); the *ring*
(`emq:{q}:ring`, a LIST) is the rota holding exactly the lanes serviceable right now (nonempty, unpaused, below their
ceiling); every claim **rotates the ring one step** (`LMOVE ring ring LEFT RIGHT`) before serving that lane's head,
so fairness between identities is **constructed, not hashed** (design decision D-9). The shipped surface:
`EchoMQ.Lanes.enqueue/5` (`@genqueue` — kind law first, duplicate refusal, the row with its group, the score-0 lane
entry, the ring bookkeeping with a wake), `claim/3` (`@gclaim` — rotate, `ZPOPMIN` the head, the **server-clock**
lease, attempts as the fencing token, the group returned beside the job), `pause/3`/`resume/3` (`@gpause`/`@gresume`
— park/return ONE lane, distinct from the queue-wide pause), `limit/4` (`@glimit` — the concurrency ceiling that
parks a lane at the limit and reopens it on complete), and `depth/3`. `EchoMQ.Metrics.lane_depth/3` and
`lane_depths/3` (`@lane_counts`) read per-lane backlog. `EchoMQ.Jobs.@reap` is **already group-aware** (an expired
grouped lease returns to its lane, not a global pool — the `stalled_group` conformance scenario is its proof). And
`EchoMQ.Consumer` (`consumer.ex`) **already parks, doesn't poll** — its loop is `reap → promote → drain (the
rotating claim) → park (`BLPOP` the `wake` key, the beat as the fallback)`, and every transition that makes a lane
serviceable (`@genqueue`/`@gclaim`/`@gresume`/`@glimit`/`@reap`/`@complete`/`@retry`/`@promote`) pushes the `wake`.

**What "deepened" means.** The foundation proved the *mechanism* — fair rotation, ceilings, pause/resume, the wake
protocol — on the happy path under the foundation's gates. emq.4 takes that mechanism to **production multi-tenant
depth** along the four axes the roadmap's emq.4 row names verbatim: **a control plane** (move a member between lanes;
deepen pause/resume/limit/drain so an operator can re-shape live traffic), **group-aware recovery** (a group-scoped
stalled-sweep that respects the ring, beyond the per-job `@reap`), **the park-don't-poll metronome** (the wake/notify
beat made robust — no lost wakeups, fair across parked consumers), and **weighted/deficit rotation** (fair-share
*beyond* round-robin, with a drill that proves no lane starves under skew). None of these is a new family; each is the
shipped family carried to where a noisy-neighbour-resistant, operator-controllable, starvation-proof bus needs it.

**Why now.** Movement I is CLOSED (the parity floor emq.2, the parent/flow family emq.3 —
[`../emq.roadmap.md`](../../emq.roadmap.md)); Movement II opens on a complete core. The groups family is the FIRST
Movement-II rung because it is the most-exercised production surface (the worked consumer **codemojex** already rides
per-player `EchoMQ.Lanes` as branded `JOB` work — one lane per player, no noisy-neighbour starvation), and because the
fair-lanes family's rung slot was **RULED** here at the Stage-1b checkpoint (seam 2 closed). Deepening it first turns
the shipped mechanism into the operator-grade, fairness-proven surface the rest of Movement II (batches, lifecycle,
the cache, the proof stack) builds beside.

## The family contract

emq.4 deepens, inside `echo/apps/echo_mq` (+ no `echo_wire` seam — the family rides the shipped connector
`eval`/`pipeline`/`command`), the **fair-lanes (groups)** surface so that: (a) an operator can **re-shape live
group traffic** — move a member between lanes, pause/resume/limit/drain a lane — through `EchoMQ.Lanes` control
verbs, with **no numeric per-job priority** (mint order IS the order theorem; per-group lanes replace priority);
(b) a **group-scoped recovery** sweep returns expired-lease members to **their own lane** (respecting the ring),
deepening the shipped per-job group-aware `@reap`; (c) the **park-don't-poll metronome** wakes parked consumers on
admission/availability **without busy-polling and without a lost wakeup**, deepening the shipped `Consumer` park
loop; (d) **weighted/deficit rotation** gives fair-share beyond round-robin over the ring, with a **starvation
drill** proving no lane starves under skew — all under the declared-keys A-1 law, branded group ids gated at the
lane-key builder, the server clock on any lease, and additive-minor conformance growth. The family carves into four
dependency-ordered sub-rungs; each ships independently and **nothing here is a wire break**.

**The grounding discipline (NO-INVENT).** Every proposed deepening rides a **shipped key or script** or re-aims a
**named v1 capability**, never a coined surface. The canon already recorded the emq.4 deltas: intra-group priority is
a **non-zero score on the existing `g:<group>:pending` ZSET** (a `ZCOUNT` over a score window — **no new key**), never
a global `prioritized` key or a `pc` counter ([`../emq.commands/features/groups/addPrioritizedJob-9.md`](../emq.commands/features/groups/addPrioritizedJob-9.md));
lane re-assignment moves a member **between two existing lane ZSETs**, never a priority re-score
([`../emq.commands/features/groups/changePriority-7.md`](../emq.commands/features/groups/changePriority-7.md)). Where
a script body is undetermined this cycle, it is **WITHHELD** and pinned at the sub-rung's pre-build reconcile (the
lag-1 discipline), not invented.

## The carve into sub-rungs (the Operator-ruled spine — D-1; not re-decomposed)

emq.4 decomposes the way emq.2 and emq.3 did (a dependency-ordered carve, one increment per run, each a full triad +
an `emq.4.N.prompt.md` runbook). The four rungs are the Operator's ruled spine — authored exactly as ruled, not
re-decomposed:

| Rung | Ships (PROPOSED) | Stands on (as-built) | Gate sketch |
|---|---|---|---|
| **emq.4.1** — the control plane | group **move / re-assignment** (a member from one lane to another); **deepened** group pause/resume/limit/**drain**. Re-aims the RETIRED v1 commands: `changePriority-7` → **lane re-assignment** (NO numeric priority — per-group Lanes replace priority); `getCountsPerPriority-4` → `EchoMQ.Metrics.lane_depths/3` *(proposed: an intra-lane priority dimension = `ZCOUNT` over a score window on the same `g:<group>:pending` ZSET — no new key)*. | `Lanes.{pause,resume,limit}/_`, `Metrics.lane_depths/3`, the lane ZSET + the ring | a re-assignment moves the member between two declared lane ZSETs (one slot → atomic); deepened control verbs re-shape the ring; `lane_depths/3` reads the live per-lane backlog; **conformance +N** (prior 52 byte-unchanged). NORMAL-risk. |
| **emq.4.2** — group-aware recovery | a **group-scoped stalled-sweep / reap** that respects the ring (returns expired-lease members to **their lane** `g:<g>:pending`, not a global pool); **server clock** (`TIME`). | the shipped group-aware `@reap` (`jobs.ex`), the `stalled_group` scenario, the ring/`gactive`/`wake` protocol | a group-scoped sweep recovers a lapsed grouped lease into its own lane, re-rings it, wakes a parked consumer; the per-job `@reap` path byte-unchanged for the non-group case; **conformance +N**. NORMAL-risk. |
| **emq.4.3** — the park-don't-poll metronome | the **wake/notify beat deepened**: consumers PARK (block) and are woken on admission/availability instead of busy-polling — robust against lost wakeups and fair across parked consumers. | the shipped `Consumer` park loop (`BLPOP wake`), the `wake` push protocol baked into every serviceable transition | a parked consumer costs the wire nothing and wakes within the beat on availability; no lost wakeup under concurrent admit+park; the ≥100 determinism loop owns the proof. **HIGH-risk** — founds a new process/lease surface; **Apollo MANDATORY** at its build; the Director's verify deepens (≥100 loop). |
| **emq.4.4** — weighted/deficit rotation + the starvation drill | **fair-share beyond round-robin** (weighted / deficit round-robin over the ring) + the **starvation drill** (a proof no lane starves under skew). The capstone. | the `@gclaim` ring rotation (`LMOVE`), the lane ZSET, the ring | weighted rotation serves lanes in proportion to weight; the starvation drill shows every lane drains under sustained skew; **conformance +N**. **HIGH-risk iff it edits the shipped `@gclaim` ring** → byte-freeze discipline (`grep redis.call` on the lib diff for the frozen scripts = 0) + **Apollo MANDATORY**. |

emq.4.1 is the **first buildable workload** because it deepens the most-exercised operator surface with the least
risk (pure control over shipped keys, no shipped-script edit), founding the chapter's vocabulary before the
higher-risk metronome (emq.4.3) and fairness (emq.4.4) rungs. The four sub-rungs are carved into
[`./emq.4.rungs/`](./emq.4.rungs/) (a separate fan-out — **not authored this cycle**).

## Invariants (runnable checks)

- **EMQ.4-INV1 — the wire law (no break, no new key family).** emq.4 adds **no new lane key family** (the deepenings
  ride the shipped `emq:{q}:g:<group>:pending` / `ring` / `paused` / `glimit` / `gactive` / `wake` keys); **no new
  wire class** (the kind law reuses `EMQKIND`); **no new fence code** (the five-code union stands unextended); **no
  new transport** (the family rides the shipped connector). *Check:* a grep of any new scripts for a lane key not in
  the shipped `g:`-segment family returns empty; `{emq}:version` reads `echomq:2.0.0` after connect; the §6 grammar is
  unedited.
- **EMQ.4-INV2 — declared keys, slot-rooted (the A-1 law).** Every Lua key a rung adds is in `KEYS[]` or derived
  in-script **only** from a declared `KEYS[n]` root by the registered grammar (the as-built `@gclaim`/`@reap`
  `base .. 'g:' .. g .. ':pending'` derivation from a declared queue-base operand — the ratified ARGV-slot-rooted
  convention, design §1 S-6); **no key is read out of a data value**. *Check:* the A-1 lint over the new scripts
  passes; a reviewer can name the declared root of every key the script touches.
- **EMQ.4-INV3 — the shipped lane surface is byte-unchanged where a rung does not edit it.** A rung that does not
  touch `@gclaim` leaves the ring rotation **byte-identical to HEAD** (`grep redis.call` on the frozen scripts in the
  lib diff = 0); a deepening of recovery (emq.4.2) leaves the **non-group** `@reap` path byte-unchanged; the prior
  fair-lanes conformance scenarios (`rotate`, `pause`, `limit`, `lane_depth`, `stalled_group`) pass **byte-unchanged**.
  *Check:* the byte-freeze grep; the prior scenarios git-verified unchanged; the foundation's lane suites green.
- **EMQ.4-INV4 — branded group identity at every lane boundary.** Every group a rung touches is gated through
  `Lanes.lane_key!/2` (which raises unless `EchoData.BrandedId.valid?/1`) before any wire; a re-assignment names a
  **valid branded source and destination group**; per-lane reads gate every group id. *Check:* an ill-formed group at
  any control/recovery boundary raises before the wire; the re-assignment scenario uses two distinct branded groups.
- **EMQ.4-INV5 — server clock where a lease is touched.** Any recovery or claim transition emq.4 adds or deepens
  reads `TIME` **server-side** inside the script (the as-built `@gclaim`/`@reap` pattern); no host clock crosses the
  lease. *Check:* a grep of any new lease-touching script for a host-supplied timestamp returns empty; the lease is
  computed from `redis.call('TIME')`.
- **EMQ.4-INV6 — the additive-minor conformance law.** Each genuine new group behaviour is a `scenarios/0` addition
  registered **with its probe in the same change**; the prior **52** scenarios pass **byte-unchanged** (name +
  contract + verdict body, git-verified); the count re-pins **52 → N** in **both** pinning tests
  (`conformance_scenarios_test.exs` + `conformance_run_test.exs`). *Check:* the git-diff shows only additions to
  `scenarios/0`; both count assertions updated.
- **EMQ.4-INV7 — fairness is sound (the metronome wakes, the rotation does not starve).** *emq.4.3:* a parked
  consumer is woken within the beat when its lane becomes serviceable, with **no lost wakeup** under a concurrent
  admit-then-park (the load-bearing metronome proof — the ≥100 determinism loop owns it). *emq.4.4:* under sustained
  skew **every** lane drains (the starvation drill); weighted rotation serves lanes in proportion to weight, never
  monopolizing one lane. *Check:* the `:valkey` metronome scenario (admit while parked → wake before the beat
  elapses); the starvation-drill scenario (skewed load → every lane's depth reaches zero); the ≥100 loop green for the
  process/lease suites.
- **EMQ.4-INV8 — the family boundary (no pre-emption, no re-ship).** emq.4 ships the **groups** family only; it does
  **not** re-ship an emq.2/emq.3 surface and does **not** pre-empt a later Movement-II family rung (batches → emq.5,
  lifecycle/distributed-cancel → emq.6, the cache → emq.7, the proof/telemetry contract → emq.8). A lane is **not** a
  batch (emq.5 is bulk *consumption*; a lane is *fair admission*) and **not** a flow (emq.3 is a *dependency graph*).
  *Check:* the spec body names the boundary; no emq.4 deliverable touches a later-family surface.

## Per-rung risk (stated forward)

- **emq.4.1 — NORMAL.** Pure control over shipped keys + a read re-aim; no shipped-script edit. Standard per-app gate
  ladder; a multi-seed sweep + an honest determinism statement (no id-mint/process/lease hazard introduced).
- **emq.4.2 — NORMAL.** Deepens a **shipped** group-aware `@reap` and the `stalled_group` scenario; a new group-scoped
  sweep over the shipped ring/`gactive`/`wake` protocol. The non-group `@reap` path stays byte-unchanged (INV3). A
  lease is touched → server clock (INV5) + the ≥100 loop if the sweep is a new process/lease surface.
- **emq.4.3 — HIGH.** Founds a **new process/lease surface** over the shipped park loop (the metronome's robustness —
  lost-wakeup hardening / per-lane wake / multi-consumer fairness). **Apollo MANDATORY** at its build; the Director's
  verify deepens to the **≥100 determinism loop** (the same-millisecond mint + the lost-wakeup race are exactly the
  cross-run hazards one green run does not surface). Stated forward so the build runs at this rigor.
- **emq.4.4 — HIGH iff it edits `@gclaim`.** Weighted/deficit rotation may re-shape the shipped ring rotation. If it
  **edits the shipped `@gclaim`**, the **byte-freeze discipline** does NOT apply to that script (it is the rung's
  target) but applies to every OTHER frozen lane script, and **Apollo is MANDATORY** (a shipped-script edit on the
  fairness-critical path); if it can land **additively** (a separate weighted-claim path leaving `@gclaim`
  byte-unchanged), it drops to NORMAL+. Which of the two — the **weighted-rotation mechanism fork** below — is the
  Operator's call at emq.4.4's pre-build reconcile.

## The surfaced fork — Venus surfaces, the Operator (via the Director) rules

> **None of these is Venus's to decide.** Each is a process/representation/boundary call the Director routes to the
> Operator. The family ships authored to the ruled spine (the four rungs above); these are the open shaping
> decisions the sub-rung builds settle, recorded here so they are decisions, not drift.

### FORK A — the emq.4.3 boundary: "founds a process/lease surface" vs "the park loop is already shipped"

> **The reconcile delta.** The Operator-ruled spine grades emq.4.3 as founding a process/lease surface (HIGH-risk,
> Apollo mandatory, the deepened verify). The as-built reconcile finds the **park-don't-poll core already shipped** —
> `EchoMQ.Consumer` parks on `BLPOP wake` and is woken by the wake-push baked into every serviceable transition
> (`consumer.ex:144–147`; the wake protocol across `lanes.ex`/`jobs.ex`). So emq.4.3 does **not** found the
> mechanism; it **deepens** it. What, exactly, is the new process/lease surface the HIGH-risk grade attaches to?
> - **Arm A — emq.4.3 hardens the shipped metronome (recommended reading).** The deepening is **lost-wakeup
>   robustness** + **multi-consumer wake fairness** + possibly a **per-lane wake** (today a single per-queue `wake`
>   LIST, capped 64, is shared by all lanes and all parked consumers — a thundering-herd / cross-lane-wake question).
>   The new surface is the hardened wake protocol and any process change it implies; HIGH-risk stands because a
>   lost-wakeup race and a same-millisecond mint are cross-run hazards (the ≥100 loop is the proof).
> - **Arm B — emq.4.3 founds a genuinely new blocking-claim surface.** If the Operator intends a new primitive
>   (e.g. a server-side blocking grouped claim beyond `BLPOP wake`, or a dedicated metronome process distinct from
>   `Consumer`), that is a larger founding and a different touch-set.
>
> **Recommendation: Arm A** — the as-built park loop is the foundation; emq.4.3 deepens its robustness and fairness.
> The triad is authored to "deepen the shipped metronome." An Arm-B ruling re-scopes emq.4.3 to a new primitive
> before its build. **This fork settles before the emq.4.3 build** (it is gate-relevant: HIGH-risk + Apollo either
> way, but the touch-set differs).

### FORK B — the weighted-rotation mechanism (emq.4.4): a ring deficit counter vs a weighted multi-pop vs a per-lane budget

> **The fairness representation.** Weighted/deficit rotation over the ring can be realized three ways, and the choice
> decides whether `@gclaim` is edited (HIGH-risk) or a separate path is added (NORMAL+):
> - **Arm 1 — a deficit counter on the ring (DRR).** Each lane carries a deficit credited per rotation and consumed
>   per serve; a lane serves while it has credit. *Steelman:* the textbook deficit-round-robin; bounded, fair,
>   starvation-free by construction. *Cost:* a new per-lane counter (a HASH field — rides an existing key shape) and
>   an edit to the `@gclaim` rotation (HIGH-risk → byte-freeze every OTHER script + Apollo).
> - **Arm 2 — a weighted multi-pop.** A higher-weight lane serves K heads per rotation. *Steelman:* additive — a
>   separate weighted-claim path can leave `@gclaim` byte-unchanged (NORMAL+). *Cost:* weight granularity is integer
>   multiples; less smooth than DRR.
> - **Arm 3 — a per-lane budget refreshed by the metronome.** The beat refreshes a per-lane serve budget. *Steelman:*
>   couples cleanly to emq.4.3's metronome. *Cost:* the fairness is only as fine as the beat; couples two rungs.
>
> **Recommendation: surface all three at emq.4.4's pre-build reconcile** with the as-built `@gclaim` re-probed (the
> emq.4.1–4.3 builds will have moved the surface). The triad records the trade-off (the `@gclaim` edit decides the
> risk grade); the Operator rules the mechanism. **No new key family any way** (every arm rides an existing key
> shape — INV1).

### FORK C — the intra-group priority dimension (emq.4.1 vs parked)

> **The canon-recorded delta.** The groups feature record names a PROPOSED emq.4 delta: an intra-lane priority
> dimension as a **non-zero score on the existing `g:<group>:pending` ZSET** (a `ZCOUNT`/`ZRANGEBYSCORE` over a score
> window — **no new key**), the forward equivalent of the v1 `getCountsPerPriority`/`changePriority` band. Does it
> land at **emq.4.1** (alongside the control plane) or **park** past the chapter (lanes-only fairness is sufficient
> for the named consumers)?
> - **Arm A — land it at emq.4.1.** Full v1 parity for the priority surface within the chapter. *Cost:* a score
>   dimension on the lane ZSET complicates the score-0 invariant the ring rotation assumes (the rotation reads the
>   lane head; a non-zero score changes which member is the head).
> - **Arm B — park it (recommended).** Keep lanes score-0 (the ring IS the fairness); the named consumers (codemojex
>   one-lane-per-player) need lane fairness, not intra-lane priority. *Cost:* the intra-group priority band is not
>   available in emq.4.
>
> **Recommendation: Arm B (park)** — the score-0 lane invariant is load-bearing for the ring rotation; intra-group
> priority is a real but unrequested surface. The triad keeps lanes score-0 and records the band as parked. An Arm-A
> ruling threads the score dimension into emq.4.1 (and re-examines the ring's head-selection). Surfaced for the
> Operator's call.

## Definition of Done (the family)

- [ ] The deepening contract recorded (this body): the shipped basics (as-built), what "deepened" means per axis, why
      groups open Movement II, and the NO-INVENT grounding (every delta rides a shipped key or re-aims a named v1
      capability).
- [ ] The carve into four sub-rungs recorded (emq.4.1 control plane · 4.2 group-aware recovery · 4.3 the metronome ·
      4.4 weighted/deficit + the starvation drill), dependency-ordered, each a full triad + a runbook — the
      Operator-ruled spine, not re-decomposed.
- [ ] INV1–INV8 stated as runnable checks; the family DoD traces every axis to a story (the `.stories.md` Coverage
      map).
- [ ] Forks A/B/C surfaced to the Director with arms + costs + a recommendation; **Fork A settled before emq.4.3
      builds** (the touch-set depends on it); Forks B/C settle at their sub-rung's pre-build reconcile.
- [ ] Per-rung risk stated forward (emq.4.1/4.2 NORMAL · emq.4.3 HIGH, Apollo mandatory + ≥100 loop · emq.4.4 HIGH
      iff `@gclaim` is edited).
- [ ] (At each sub-rung's build, NOT this design cycle) the surface built inside `echo/apps/echo_mq`; the shipped lane
      surface byte-unchanged where the rung does not edit it (INV3); the new scenarios additive-minor with the prior
      52 byte-unchanged (INV6); the ≥100 determinism loop green for any process/lease suite (INV7); Apollo MANDATORY
      for emq.4.3 and for emq.4.4 if it edits `@gclaim`.

Stories: [`./emq.4.stories.md`](emq.4.stories.md) · Agent brief: [`./emq.4.llms.md`](emq.4.llms.md) ·
Sub-rungs (a separate fan-out, NOT authored this cycle): [`./emq.4.rungs/emq.4.1.md`](./emq.4.rungs/emq.4.1.md) ·
[`./emq.4.rungs/emq.4.2.md`](./emq.4.rungs/emq.4.2.md) · [`./emq.4.rungs/emq.4.3.md`](./emq.4.rungs/emq.4.3.md) ·
[`./emq.4.rungs/emq.4.4.md`](./emq.4.rungs/emq.4.4.md) ·
As-built floor (the surface this family deepens — re-probe at each sub-rung's reconcile):
`echo/apps/echo_mq/lib/echo_mq/lanes.ex` (`@genqueue`/`@gclaim`/`@gpause`/`@gresume`/`@glimit`; `enqueue/5`, `claim/3`,
`pause/3`, `resume/3`, `limit/4`, `depth/3`; the `g:`-segment keyspace + the ring + the wake) +
`metrics.ex` (`lane_depth/3`, `lane_depths/3` = `@lane_counts`) + `jobs.ex` (`@reap` — already group-aware) +
`consumer.ex` (the park-don't-poll loop + `BLPOP wake`) + `conformance.ex` (the 52-scenario set the additive-minor
law grows — re-probe the live count) · The v1 capability reference (the re-aim record, READ-ONLY — the form NOT to
lift): [`../emq.commands/features/groups/`](../emq.commands/features/groups/) (`addPrioritizedJob-9` SHIPPED re-aimed ·
`changePriority-7` + `getCountsPerPriority-4` RETIRED) · Design: [`../emq.design.md`](../../emq.design.md) §10 seam 2
/ §4 cluster 2 (the displaced groups family RULED → emq.4), §4 row 4 (the *park, don't poll* law re-aimed to the
fair-lanes rung), S-1/§6 (the braced keyspace), S-6 (the declared-keys A-1 law) · Roadmap:
[`../emq.roadmap.md`](../../emq.roadmap.md) (the emq.4 row · Movement II · seam 2 CLOSED) · The carve precedents:
[`../emq.2/emq.2.design.md`](../emq.2/emq.2.design.md) + [`../emq.3/emq.3.md`](../emq.3/emq.3.md) (the dependency-ordered carve) ·
Approach: [`../../elixir/specs/specs.approach.md`](../../../elixir/specs/specs.approach.md)
