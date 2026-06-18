# EMQ.4.1 · The control plane — lane re-assignment + deepened operator verbs (Movement II, the groups family, the first buildable slice)

> **Status: 📐 PROPOSED — the rung's spec body (the seed the full triad grows from at build time).** The FIRST
> sub-rung of the emq.4 "groups deepened" family — the family OPENS on the operator control plane, the
> least-risky, most-exercised surface; the family contract + the carve + the forks are [`../emq.4.md`](../emq.4.md)
> (authoritative — if this carve disagrees with the body, the body wins). emq.4.1 deepens the **operator control
> plane** over the **shipped** fair-lanes surface (`EchoMQ.Lanes`): a **lane move / re-assignment** (a member from
> one lane to another) plus **deepened** pause/resume/limit/drain so an operator re-shapes live group traffic, and
> it re-aims the two RETIRED v1 priority commands. **Risk: NORMAL** — it adds host control verbs + at most one new
> inline script over the shipped `g:`-segment keyspace; it edits **no** shipped lane script (`@gclaim`/`@genqueue`
> byte-unchanged) and founds no process/lease surface. The standard per-app gate ladder + a multi-seed sweep (no
> id-mint/process/lease hazard is introduced). The v2 master invariant binds (braced keys · branded group ids
> gated at the lane-key builder · declared Lua keys · additive-minor conformance · no wire break). Forward-tense:
> every emq.4.1 surface is PROPOSED, NOT shipped.

## 0 · The slice — what emq.4.1 deepens, and why first

The family ([`../emq.4.md`](../emq.4.md)) deepens the shipped fair-lanes mechanism to production multi-tenant depth
along four axes. emq.4.1 carves the **control plane**: the verbs an operator uses to **re-shape contention live** —
move a member between lanes, and pause/resume/limit/drain a lane while traffic flows. It is the **first buildable**
slice because it deepens the most-exercised operator surface with the **least risk** (pure control over shipped
keys, no shipped-script edit, no new process), founding the chapter's vocabulary before the higher-risk metronome
(emq.4.3) and weighted fairness (emq.4.4) rungs. It also discharges the two RETIRED v1 priority commands — the
groups feature record already re-aimed them to this rung
([`../../emq.commands/features/groups/changePriority-7.md`](../../emq.commands/features/groups/changePriority-7.md),
[`../../emq.commands/features/groups/getCountsPerPriority-4.md`](../../emq.commands/features/groups/getCountsPerPriority-4.md)).

## Goal

emq.4.1 builds, inside `echo/apps/echo_mq`, the **fair-lanes operator control plane**: (a) a **lane re-assignment**
verb that moves a member from one lane to another — `ZREM emq:{q}:g:<src>:pending` then `ZADD
emq:{q}:g:<dst>:pending` — in **one atomic script** (both lanes share the one `{q}` slot), each group id gated
`EchoData.BrandedId.valid?/1` at the lane-key builder, with the ring re-shaped so both lanes reflect their new
serviceability; (b) **deepened** pause/resume/limit/drain control over the shipped lane keys so an operator can
re-shape a live lane (the shipped `Lanes.{pause,resume,limit}/_` carried forward, plus the operator-grade depth the
chapter body names); (c) the **re-aim** of the two RETIRED v1 priority commands — `changePriority-7` → **lane
re-assignment** (there is **no numeric per-job priority**; mint order IS the order theorem; per-group lanes replace
priority) and `getCountsPerPriority-4` → `EchoMQ.Metrics.lane_depths/3` (the per-lane backlog read) — all under the
A-1 declared-keys law, branded group ids gated at the builder, and additive-minor conformance growth. emq.4.1 edits
**no** shipped lane script and founds **no** process/lease surface.

## Rationale (5W)

- **Why** — the control plane is the **foundation** of the groups-deepened family: it is the surface a multi-tenant
  operator reaches for first (move a tenant's work, yield a noisy lane, raise a starved lane's ceiling), and it
  carries the **least** risk, so it founds the chapter's vocabulary and gate posture before the metronome and the
  fairness rungs build on a proven control surface. It also closes the two RETIRED v1 priority commands the canon
  re-aimed here — completing the groups feature record's emq.4 obligation for the priority surface.
- **What** — emq.4.1 builds (forward-named; the re-assignment surface does not yet exist in `echo_mq` — re-probe at
  the pre-build reconcile): (1) a **lane re-assignment** host verb on `EchoMQ.Lanes` *(proposed verb name
  withheld — pinned at the pre-build reconcile; `reassign/4` or `move/4` is the candidate, the Director/Operator's
  naming call)* over a new inline `Script.new/2` that `ZREM`s the member from the source lane and `ZADD`s it to the
  destination lane atomically (both `{q}`-co-located, both declared `KEYS[n]`), re-shaping the ring; (2) the
  **deepened** pause/resume/limit/drain control verbs over the shipped lane keys; (3) the re-aim surfacing —
  `changePriority-7` → re-assignment, `getCountsPerPriority-4` → `Metrics.lane_depths/3` (the shipped read, carried
  as the v1 re-aim target — no new read surface unless Fork C lands); (4) the conformance scenario(s) for
  re-assignment (additive minor, the prior 52 byte-unchanged); (5) the `:valkey` test suites + a multi-seed sweep.
- **Who** — the program (the rung that founds the groups control plane and discharges the RETIRED v1 priority
  commands); multi-tenant **operators** of the bus, who gain live re-shaping of group traffic; the conformance
  harness, which grows by the re-assignment scenario(s) (additive minor). **codemoji** (the worked consumer): a
  player whose work must move to a different lane (a re-grouped player) is the prospective shape — recorded, not
  asserted.
- **When** — Movement II, the groups family's **first** sub-rung, after Movement I closed. SPECCED this design
  cycle as a seed; the full triad (`.stories.md` / `.llms.md` / `.prompt.md`) + the build follow one increment per
  run. **Fork C** (the intra-group priority dimension — below) is surfaced for the Operator's optional ruling at
  the pre-build reconcile; the recommended arm (park) keeps emq.4.1 lanes score-0, so a park ruling needs **no**
  re-scope.
- **Where** — `echo/apps/echo_mq` only: `lanes.ex` (EDIT — the re-assignment verb + its inline script + the
  deepened control verbs), `metrics.ex` (EDIT — only if the re-aim deepens `lane_depths/3`; else untouched —
  re-probe), `conformance.ex` (EDIT — the re-assignment scenario(s) + the count re-pin), `test/*_test.exs`
  (NEW/EDIT — the `:valkey` re-assignment proof), the two pinning tests (EDIT — the count). `echo_wire` is
  **untouched** (the control plane rides the shipped connector `eval`/`command`). `apps/echomq` is **untouched**
  (the capability reference). The §6 grammar in `keyspace.ex` is **unedited** (no new key family — the lane keys
  already compose). Exact line anchors pinned at the pre-build reconcile (the lag-1 law).

## Scope

- **In** — the operator control plane: (1) the **lane re-assignment** verb (member `g:<src>:pending` →
  `g:<dst>:pending`, one atomic script, both branded-gated, the ring re-shaped); (2) **deepened**
  pause/resume/limit/drain over the shipped lane keys; (3) the **re-aim** of `changePriority-7` (→ re-assignment)
  and `getCountsPerPriority-4` (→ `Metrics.lane_depths/3`); (4) the re-assignment conformance scenario(s) (additive
  minor, the prior 52 byte-unchanged); (5) the `:valkey` suites + an honest multi-seed sweep (a determinism-posture
  statement — no id-mint/process/lease hazard introduced).
- **Out** — any **numeric per-job priority** (retired by design — the v1 packed-score scheme does not return; INV1);
  any **new lane key family** (the re-assignment rides the shipped `g:<group>:pending` keys + the ring; no
  `prioritized` key, no `pc` counter — INV1); the **intra-group priority dimension** (a non-zero lane score — **Fork
  C**, recommended **parked**, NOT built here unless the Operator rules otherwise); a **cross-queue** lane move (a
  member moving to a lane in a *different* queue crosses a slot, so it inherits the emq.3 cross-queue posture —
  honest, not atomic; emq.4.1 builds the **same-queue** move and **rejects** a cross-queue destination with a
  typed/host-side error, never silently mis-keying); any **shipped lane-script edit** (`@gclaim`/`@genqueue` are
  byte-unchanged — INV3); any **process/lease surface** (the metronome is emq.4.3); the **weighted/deficit rotation**
  (emq.4.4); the **group-scoped recovery sweep** (emq.4.2); any **`echo_wire`/transport** change; any **edit to the
  frozen v1 line**.

## Invariants (the subset emq.4.1 carries, from the family EMQ.4-INV1–8)

- **EMQ.4.1-INV1 (← EMQ.4-INV1) — the wire law (no break, no new key family, no numeric priority).** emq.4.1 adds
  **no new lane key family** (the re-assignment + control verbs ride the shipped `emq:{q}:g:<group>:pending` /
  `ring` / `paused` / `glimit` / `gactive` / `wake` keys); **no numeric per-job priority** (the v1 packed-score
  scheme does not return — re-assignment moves the member between lanes); **no new wire class** (the kind law reuses
  `EMQKIND` where a kind check applies); **no new transport**. *Check:* a grep of any new script for a lane key not
  in the shipped `g:`-segment family returns empty; a grep for a numeric-priority score / `prioritized` key returns
  empty; `{emq}:version` reads `echomq:2.0.0` after connect; the §6 grammar is unedited.
- **EMQ.4.1-INV2 (← EMQ.4-INV4) — branded group identity at both lane boundaries.** A re-assignment names a **valid
  branded source AND destination group**, each gated `EchoData.BrandedId.valid?/1` at the lane-key builder
  (`Lanes.lane_key!/2`, which raises on an ill-formed group) **before** any wire. *Check:* an ill-formed source or
  destination group raises before the wire; the re-assignment scenario uses two distinct branded groups.
- **EMQ.4.1-INV3 (← EMQ.4-INV3) — the shipped lane surface is byte-unchanged.** emq.4.1 edits **no** shipped lane
  script — `@gclaim` (the ring rotation), `@genqueue`, `@gpause`, `@gresume`, `@glimit` are **byte-identical to
  HEAD** (`grep redis.call` on those scripts in the lib diff = 0); the prior fair-lanes conformance scenarios
  (`rotate`, `pause`, `limit`, `lane_depth`, `stalled_group`) pass **byte-unchanged** (git-verified). *Check:* the
  byte-freeze grep on the shipped lane scripts = 0; the prior scenarios git-verified unchanged.
- **EMQ.4.1-INV4 (← EMQ.4-INV6) — the additive-minor conformance law.** The re-assignment scenario(s) are
  registered in `scenarios/0` **with their probes in the same change**; the prior **52** scenarios pass
  **byte-unchanged**; the count re-pins **52 → N** in **both** pinning tests (`conformance_scenarios_test.exs` +
  `conformance_run_test.exs`). *Check:* the git-diff shows only additions to `scenarios/0`; both count assertions
  updated; `Conformance.run/2` prints N lines.
- **EMQ.4.1-INV5 (← EMQ.4-INV1/INV2) — slot soundness (the same-queue move is atomic).** The re-assignment's source
  and destination lanes share **one** `{q}` slot, so the move script is **atomic** (one slot, one EVAL); every key
  is a declared `KEYS[n]` or grammar-rooted; a cross-queue destination is **rejected** at the host verb (it would
  break this invariant — the cross-queue move inherits the emq.3 cross-queue posture). *Check:* the re-assignment
  script declares keys of exactly one `{q}`; a cross-queue destination answers the typed/host-side rejection; no
  script claims atomicity across slots.

## The rung's fork — Venus surfaces, the Operator (via the Director) rules

### FORK C — the intra-group priority dimension: land at emq.4.1 vs park (recommended: park)

> **The canon-recorded delta.** The groups feature record names a PROPOSED emq.4 delta: an intra-lane priority
> dimension as a **non-zero score on the existing `g:<group>:pending` ZSET** (a `ZCOUNT`/`ZRANGEBYSCORE` over a
> score window — **no new key**), the forward equivalent of the v1 `getCountsPerPriority`/`changePriority` band.
> Does it land at **emq.4.1** (alongside the control plane) or **park** past the chapter?
> - **Arm A — land it at emq.4.1.** Full v1 parity for the priority surface within this rung. *Cost:* a score
>   dimension on the lane ZSET complicates the **score-0 invariant** the ring rotation assumes — the shipped
>   `@gclaim` `ZPOPMIN`s the lane head (`lanes.ex:41`), so a non-zero score changes which member is the head, and
>   touching the ring's head-selection is exactly the byte-freeze-sensitive surface emq.4.1 is authored to leave
>   untouched (INV3).
> - **Arm B — park it (RECOMMENDED).** Keep lanes score-0 (the ring IS the fairness); the named consumers (codemoji
>   one-lane-per-player) need **lane** fairness, not intra-lane priority. *Cost:* the intra-group priority band is
>   not available in emq.4.
>
> **Recommendation: Arm B (park)** — the score-0 lane invariant is load-bearing for the ring's head-selection;
> intra-group priority is a real but **unrequested** surface, and landing it would pull emq.4.1 toward the
> byte-freeze-sensitive `@gclaim` it is designed to avoid. This carve keeps lanes score-0 and records the band as
> parked. An Arm-A ruling threads the score dimension into emq.4.1 (and re-examines the ring's head-selection — a
> larger, `@gclaim`-touching scope). **None of this is Venus's to decide** — surfaced for the Operator's call at the
> pre-build reconcile.

## Definition of Done

- [ ] **Fork C** surfaced to the Director with both arms + costs + the recommendation (park); the Operator's
      optional ruling recorded; the carve re-derived if Arm A is ruled (the score-dimension + the `@gclaim`
      head-selection re-examination).
- [ ] The **lane re-assignment** verb + its inline atomic script built: a member moves `g:<src>:pending` →
      `g:<dst>:pending` (both branded-gated, one slot), the ring re-shaped; a cross-queue destination rejected.
- [ ] The **deepened** pause/resume/limit/drain control verbs built over the shipped lane keys.
- [ ] The **re-aim** discharged: `changePriority-7` → re-assignment (no numeric priority), `getCountsPerPriority-4`
      → `Metrics.lane_depths/3`, recorded in the rung's record.
- [ ] The re-assignment conformance scenario(s) registered (additive minor — the prior **52** byte-unchanged; the
      count re-pinned **52 → N** in both pinning tests).
- [ ] The proof: the `:valkey` suites green per-app; a multi-seed sweep + an honest determinism-posture statement
      (no id-mint/process/lease hazard introduced — NORMAL-risk); no shipped lane script edited (INV3); honest-row
      reporting (Valkey on 6390 the truth row).
- [ ] INV1–INV5 verified as runnable checks; the spec body ([`../emq.4.md`](../emq.4.md)) remains authoritative;
      the as-built reconcile syncs this seed post-build.

Family: [`../emq.4.md`](../emq.4.md) (the contract, the carve, the forks — authoritative) · Chapter stories:
[`../emq.4.stories.md`](../emq.4.stories.md) (US1 — the control plane) · Chapter brief:
[`../emq.4.llms.md`](../emq.4.llms.md) (R1, AS1) · As-built floor (the build target — re-probe at the pre-build
reconcile; line numbers are hints): `echo/apps/echo_mq/lib/echo_mq/lanes.ex` (`enqueue/5` `@genqueue`, `claim/3`
`@gclaim` — the ring `LMOVE` + `ZPOPMIN` head the move must NOT disturb, `pause/3` `@gpause`, `resume/3` `@gresume`,
`limit/4` `@glimit`, `depth/3`, `lane_key!/2` the branded-gated builder; the `g:<group>:pending` / `ring` / `paused`
/ `glimit` / `gactive` / `wake` keyspace) + `metrics.ex` (`lane_depth/3`, `lane_depths/3` = `@lane_counts` — the
`getCountsPerPriority-4` re-aim target) + `admin.ex` (`drain/3` `@drain` — the deepened-drain precedent, `del_job`
enumerates lanes) + `conformance.ex` (the **52**-scenario set the additive-minor law grows — re-probe the live
count) · The v1 capability reference (the re-aim record, READ-ONLY — the form NOT to lift):
[`../../emq.commands/features/groups/changePriority-7.md`](../../emq.commands/features/groups/changePriority-7.md)
(RETIRED → lane re-assignment) +
[`../../emq.commands/features/groups/getCountsPerPriority-4.md`](../../emq.commands/features/groups/getCountsPerPriority-4.md)
(RETIRED → `Metrics.lane_depths/3`) +
[`../../emq.commands/features/groups/addPrioritizedJob-9.md`](../../emq.commands/features/groups/addPrioritizedJob-9.md)
(SHIPPED, re-aimed — the score-0-lane-no-new-key discipline) · Design:
[`../../../emq.design.md`](../../../emq.design.md) §10 seam 2 / §4 cluster 2 (the displaced groups family RULED →
emq.4), S-1/§6 (the braced keyspace — the slot constraint), S-6 (the declared-keys A-1 law) · Roadmap:
[`../../../emq.roadmap.md`](../../../emq.roadmap.md) (the emq.4 row · Movement II) · Approach:
[`../../../../elixir/specs/specs.approach.md`](../../../../elixir/specs/specs.approach.md)
