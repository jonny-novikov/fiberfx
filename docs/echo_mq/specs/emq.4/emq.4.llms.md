# EMQ.4 · agent brief — groups deepened (the Mars build brief)

> The build brief for the emq.4 **family** — what Mars reads first, the requirements traced to stories + invariants,
> the execution topology, and the per-rung agent-story seeds (Directive + Acceptance gate). This is the **family**
> brief; the actual build runs per sub-rung against the sub-rung's own brief (a separate fan-out —
> `./emq.4.rungs/emq.4.N.llms.md`). The spec **body** [`./emq.4.md`](emq.4.md) is authoritative; this brief and
> [`./emq.4.stories.md`](emq.4.stories.md) DERIVE from it — when a derived artifact disagrees with the body, the body
> wins. **No code is built this design cycle.**

## References (read first, in order)

1. **The spec body** — [`./emq.4.md`](emq.4.md): the deepening contract, the carve, the invariants, the three
   surfaced forks. **Read it before any build story.**
2. **The as-built floor (the real surface to deepen — re-probe at each sub-rung's reconcile; line numbers drift)** —
   - `echo/apps/echo_mq/lib/echo_mq/lanes.ex`: `EchoMQ.Lanes.enqueue/5` (`@genqueue`), `claim/3` (`@gclaim` — the
     ring `LMOVE`, the server-clock lease, the lane derived `ARGV[1] .. 'g:' .. g .. ':pending'`), `pause/3`
     (`@gpause`), `resume/3` (`@gresume`), `limit/4` (`@glimit`), `depth/3`, `lane_key!/2` (the branded-gated lane-key
     builder). The keyspace: `g:<group>:pending` · `ring` · `paused` · `glimit` · `gactive` · `wake` (all
     `Keyspace.queue_key/2`).
   - `echo/apps/echo_mq/lib/echo_mq/metrics.ex`: `lane_depth/3`, `lane_depths/3` (`@lane_counts`) — the per-lane
     backlog reads (the `getCountsPerPriority-4` re-aim target).
   - `echo/apps/echo_mq/lib/echo_mq/jobs.ex`: `@reap` (**already group-aware** — `jobs.ex:341`: an expired grouped
     lease returns to its lane, decrements `gactive`, re-rings, wakes); the `base .. 'g:' .. g .. ':pending'`
     derivation precedent.
   - `echo/apps/echo_mq/lib/echo_mq/consumer.ex`: the **shipped park-don't-poll loop** (`reap → promote → drain
     (rotating claim) → park (`BLPOP wake`)`); a `spawn_link` loop, NOT a GenServer.
   - `echo/apps/echo_mq/lib/echo_mq/conformance.ex`: the **52**-scenario set the additive-minor law grows (lane
     scenarios present: `rotate`, `pause`, `limit`, `lane_depth`, `stalled_group`) — re-probe the live count at the
     sub-rung's reconcile.
3. **The v1 capability reference (the re-aim record, READ-ONLY — NAMES what to re-aim, never the form to lift)** —
   `docs/echo_mq/specs/emq.commands/features/groups/`: `addPrioritizedJob-9.md` (SHIPPED, re-aimed to `Lanes.enqueue/5`;
   the PROPOSED emq.4 delta = a non-zero lane score on the existing ZSET, **no new key**), `changePriority-7.md`
   (RETIRED → lane re-assignment / weighted rotation, **no numeric priority**), `getCountsPerPriority-4.md` (RETIRED →
   `Metrics.lane_depths/3`).
4. **The design canon** — `docs/echo_mq/emq.design.md`: §10 seam 2 / §4 cluster 2 (the displaced groups family RULED
   → emq.4), §4 row 4 (the *park, don't poll* law re-aimed to the fair-lanes rung), **S-1/§6** (the braced keyspace —
   the slot constraint), **S-6** (the declared-keys A-1 law — the ARGV-slot-rooted convention), **§5** (the closed
   wire-class registry — no new class). The roadmap: `docs/echo_mq/emq.roadmap.md` (the emq.4 row · Movement II ·
   seam 2 CLOSED). The program law: `.claude/skills/echo-mq-program.md`; the as-built map:
   `.claude/skills/echo-mq-surface.md`.

## Requirements (numbered; each traced back to a story, forward to an invariant)

> These are the **family** requirements; each sub-rung's brief restates the subset it builds. No requirement is built
> this design cycle.

1. **R1 — the control plane deepens shipped keys; no numeric priority.** Lane move/re-assignment moves a member
   **between two existing lane ZSETs** (`g:<src>:pending` → `g:<dst>:pending`, both branded-gated, one slot →
   atomic); deepened pause/resume/limit/drain re-shape the ring; the v1 `changePriority-7` re-aims to re-assignment
   (mint order IS the order theorem), `getCountsPerPriority-4` to `Metrics.lane_depths/3`. **No new key family.**
   (US1 → INV1, INV4.) *(emq.4.1)*
2. **R2 — group-aware recovery returns members to their lane, not a pool.** A group-scoped stalled-sweep returns an
   expired-lease member to its `g:<g>:pending` lane (NOT flat `pending`), decrements `gactive`, re-rings, wakes —
   deepening the shipped group-aware `@reap`; the **non-group** `@reap` path stays byte-unchanged. The sweep reads
   `TIME` server-side. (US2 → INV3, INV5.) *(emq.4.2)*
3. **R3 — the metronome deepens the shipped park loop; no lost wakeup.** Consumers PARK (`BLPOP wake`, the beat the
   fallback) and are woken on admission/availability by the shipped wake protocol; the deepening hardens against a
   **lost wakeup** under a concurrent admit-then-park and distributes wakes fairly across parked consumers. (US3 →
   INV7, INV5.) **HIGH-risk — Apollo MANDATORY; the ≥100 determinism loop owns the proof.** *(emq.4.3)*
4. **R4 — weighted/deficit rotation is fair and starvation-free.** Weighted/deficit round-robin over the ring serves
   lanes in proportion to weight; the **starvation drill** proves every lane drains under sustained skew. Realized
   **additively** (`@gclaim` byte-unchanged) OR by **editing `@gclaim`** under the byte-freeze discipline (every
   OTHER frozen lane script byte-identical to HEAD) with **Apollo MANDATORY** — Fork B ruled at the pre-build
   reconcile. **No new key family.** (US4 → INV7, INV3.) *(emq.4.4)*
5. **R5 — declared keys, slot-rooted.** Every Lua key a rung adds is in `KEYS[]` or derived from a declared `KEYS[n]`
   queue-base root by the registered grammar (the `@gclaim`/`@reap` `base .. 'g:' .. g .. ':pending'` pattern); no
   key read out of a data value. (US5 → INV2.)
6. **R6 — no new key family, no new wire class, no new transport.** Every deepening rides the shipped `g:`-segment
   keys; the kind law reuses `EMQKIND`; the family rides the shipped connector `eval`/`pipeline`/`command` (no
   `echo_wire` change). (US5, US-GATE → INV1.)
7. **R7 — server clock where a lease is touched.** Any recovery/claim transition reads `TIME` server-side inside the
   script (the as-built pattern); no host clock crosses the lease. (US2, US3 → INV5.)
8. **R8 — additive-minor conformance.** Each genuine new group behaviour is a `scenarios/0` addition registered with
   its probe in the same change; the prior **52** are byte-unchanged; the count re-pins **52 → N** in both pinning
   tests. (US5, US-GATE → INV6.)
9. **R9 — the family boundary.** Groups (lanes) surface only; no Movement-II pre-emption (batches → emq.5,
   lifecycle/distributed-cancel → emq.6, cache → emq.7, proof/telemetry-contract → emq.8); no re-ship of an
   emq.2/emq.3 surface; a lane is not a batch and not a flow. (US6 → INV8.)

## Execution topology

- **Runtime shape.** The family deepens existing lib modules over the **shipped `EchoWire` connector** — `EchoMQ.Lanes`
  (control + recovery + weighted claim), `EchoMQ.Metrics` (the re-aimed reads), `EchoMQ.Consumer` (the metronome), and
  inline `Script.new/2` attributes beside the shipped `@g*` scripts. The **only** rung that founds a new process/lease
  surface is **emq.4.3** (the metronome's robustness — over the shipped `Consumer` park loop, NOT a new transport);
  emq.4.1/4.2/4.4 are wire calls + at most one shipped-script edit (emq.4.4 `@gclaim`, fork-gated). The family stands
  ON the as-built supervision tree unchanged.
- **The build-order task DAG (per sub-rung).** (1) pre-build reconcile (re-probe `lanes.ex` `@g*` + `consumer.ex` the
  park loop + `jobs.ex` `@reap` + `conformance.ex` count + the `base .. 'g:' .. g .. ':pending'` derivation — pin the
  lag-1 anchors; the prior sub-rungs moved the surface); (2) the new/edited scripts (declared keys, server clock); (3)
  the host API on `Lanes`/`Metrics`/`Consumer`; (4) the conformance scenarios (additive minor, re-pin 52 → N); (5) the
  `:valkey` + process suites + the ≥100 loop on any process/lease one; (6) the gate ladder.
- **The EXACT files touched (per the carve — re-probe at each reconcile).**
  - `echo/apps/echo_mq/lib/echo_mq/lanes.ex` — **EDIT** (emq.4.1 control verbs + re-assignment; emq.4.2 the
    group-scoped sweep; emq.4.4 weighted rotation — the `@gclaim` edit is fork-gated, byte-freeze the others).
  - `echo/apps/echo_mq/lib/echo_mq/metrics.ex` — **EDIT** (emq.4.1 the `lane_depths/3` re-aim surface, if deepened).
  - `echo/apps/echo_mq/lib/echo_mq/consumer.ex` — **EDIT** (emq.4.3 the metronome — **HIGH-RISK, Apollo MANDATORY**).
  - `echo/apps/echo_mq/lib/echo_mq/jobs.ex` — **EDIT** (emq.4.2 only if the group-scoped sweep edits the shipped
    `@reap`; the non-group path byte-unchanged — re-probe whether the sweep is additive beside `@reap` or an edit).
  - `echo/apps/echo_mq/lib/echo_mq/conformance.ex` — **EDIT** (the new group scenarios; the count re-pin).
  - `echo/apps/echo_mq/test/*_test.exs` — **NEW/EDIT** (`:valkey` + process: re-assignment, group recovery, the
    metronome wake, the starvation drill).
  - `echo/apps/echo_mq/test/conformance_scenarios_test.exs` + `conformance_run_test.exs` — **EDIT** (re-pin **52 →
    N**).
  - **Untouched:** `apps/echomq` (the capability reference); `echo_wire` (the family rides the shipped connector); the
    §6 grammar in `keyspace.ex` (no new key family — the lane keys already compose).
- **The boundary.** The diff stays inside `echo/apps/echo_mq`. A change that reaches a third app is out of bounds.
  Agents run **NO git** (the Director commits by pathspec at the rung's close). The Operator commits out-of-band —
  watch for `AM`-status files and exclude them.

## Per-rung agent-story seeds (Directive + Acceptance gate; each sub-rung restates its subset)

> Stated as contracts (precondition / postcondition / invariant) so the Operator and Apollo accept at the boundary,
> not by re-reading the diff. **None runs this design cycle.**

- **AS1 — the control plane (emq.4.1, NORMAL).** *Directive:* deepen `EchoMQ.Lanes` with lane move/re-assignment (a
  member from `g:<src>:pending` to `g:<dst>:pending`, both branded-gated, one slot) + deepened pause/resume/limit/drain
  over the shipped keys; re-aim `changePriority-7` → re-assignment, `getCountsPerPriority-4` → `Metrics.lane_depths/3`.
  *Precondition:* a member on a source lane + a valid branded destination, same queue. *Postcondition:* the member is
  on the destination lane, the ring reflects both lanes' serviceability, no numeric priority involved. *Invariant:*
  no new key family (INV1); branded source/dest (INV4); declared keys on one slot (INV2). *Acceptance gate:* the
  re-assignment `:valkey` scenario (member moves A→B, the ring updates, both lanes' depth correct) + a `lane_depths/3`
  read; conformance +N (the 52 byte-unchanged).
- **AS2 — group-aware recovery (emq.4.2, NORMAL).** *Directive:* add a group-scoped stalled-sweep that returns an
  expired-lease member to its lane (deepening the shipped group-aware `@reap`), server clock, re-ring + wake; the
  non-group `@reap` path byte-unchanged. *Precondition:* a grouped job whose lease lapsed. *Postcondition:* the member
  is back on its `g:<g>:pending` lane (not flat `pending`), `gactive` decremented, the lane re-rung, a parked consumer
  woken. *Invariant:* the non-group path byte-unchanged (INV3); server clock (INV5). *Acceptance gate:* the
  group-scoped recovery `:valkey` scenario (lapsed grouped lease → lane, not pool); the non-group `@reap` byte-frozen.
- **AS3 — the park-don't-poll metronome (emq.4.3, HIGH-RISK).** *Directive:* deepen the shipped `Consumer` park loop
  for robustness — no lost wakeup under concurrent admit-then-park, fair wakes across parked consumers — over the
  shipped `BLPOP wake` protocol (NOT a new transport). *Precondition:* a parked consumer. *Postcondition:* a member
  admitted while parked wakes the consumer within the beat and is served; no wakeup lost. *Invariant:* the metronome
  is sound under the race (INV7); server clock on any lease (INV5). *Acceptance gate:* the admit-while-parked
  `:valkey` scenario (wake before the beat) + the **≥100 determinism loop** owning the machine; **Apollo MANDATORY**
  (the process/lease surface).
- **AS4 — weighted/deficit rotation + the drill (emq.4.4, HIGH iff `@gclaim` edited).** *Directive:* add weighted /
  deficit round-robin over the ring (the ruled Fork-B mechanism) + the starvation drill; realize additively
  (`@gclaim` byte-unchanged) or by editing `@gclaim` under byte-freeze (every OTHER frozen script byte-identical).
  *Precondition:* lanes with assigned weights. *Postcondition:* lanes served in proportion to weight; under sustained
  skew every lane drains. *Invariant:* fairness is starvation-free (INV7); the unedited scripts byte-frozen (INV3).
  *Acceptance gate:* the weighted-proportion scenario + the starvation-drill scenario (every lane reaches zero);
  **Apollo MANDATORY** if `@gclaim` is edited.
- **AS-FORK — the fork gate (at the right sub-rung, before its build).** *Directive:* present **Fork A** (the emq.4.3
  boundary) to the Director **before emq.4.3 builds** (the touch-set depends on it; recommendation Arm A, deepen);
  present **Fork B** (the weighted mechanism) at emq.4.4's pre-build reconcile with the `@gclaim`-edit trade-off;
  present **Fork C** (intra-group priority) at emq.4.1 (recommendation Arm B, park). *Precondition:* the family body's
  surfaced forks. *Postcondition:* each fork ruled at its gate, recorded before the dependent build artifact.
  *Invariant:* no fork-bearing build runs until its fork is ruled. *Acceptance gate:* the ledger records each ruling;
  each sub-rung's touch-set matches the ruled arm.

## What NOT to do (the guardrails)

- **Do NOT coin a new key family.** Every deepening rides the shipped `g:`-segment keys (`g:<group>:pending` · `ring`
  · `paused` · `glimit` · `gactive` · `wake`). No `prioritized` key, no `pc` counter, no new lane family (INV1; the
  canon re-aim record).
- **Do NOT introduce a numeric per-job priority.** Mint order IS the order theorem; per-group lanes replace priority.
  The v1 `changePriority`/`addPrioritizedJob` packed-score scheme **does not return** (re-assign the lane, weight the
  rotation).
- **Do NOT edit a shipped lane script except where the rung names it.** `@gclaim` is byte-frozen unless emq.4.4's
  ruled mechanism edits it (then byte-freeze every OTHER `@g*`); the non-group `@reap` path stays byte-unchanged
  (INV3). `grep redis.call` on the frozen scripts in the lib diff = 0.
- **Do NOT host-clock a lease.** Server clock (`TIME`) inside the script wherever a lease is touched (INV5).
- **Do NOT break the conformance contract.** The prior **52** scenarios stay byte-unchanged and git-verified; grow
  only additively; re-pin the count in **both** pinning tests (INV6).
- **Do NOT pre-empt a later family or re-ship emq.2/emq.3.** Groups only; a lane is not a batch (emq.5) and not a flow
  (emq.3) (INV8).

## Propagation clause (put in any sub-rung brief authored from this)

No gendered pronouns for agents; no perceptual or interior-state verbs ("sees" / "wants" / "feels") for agents or
software (components read, compute, refuse, return); no first-person narration ("we" / "I think"). Forward tense for
the unbuilt surface ("emq.4 deepens …"). Every reference is a real `echo_mq`/`echo_wire` module, a real v1 file
(READ-ONLY, the form NOT lifted), or a design §. The v1 groups commands are a **capability reference / re-aim
record**, never a thing migrated from. NO git.
