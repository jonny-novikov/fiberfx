# EMQ.4.2 · Group-aware recovery — the group-scoped stalled-sweep (Movement II, the groups family)

> **Status: 📐 PROPOSED — the rung's spec body (the seed the full triad grows from at build time).** The SECOND
> sub-rung of the emq.4 "groups deepened" family; the family contract + the carve + the forks are
> [`../emq.4.md`](../emq.4.md) (authoritative — if this carve disagrees with the body, the body wins). emq.4.2
> deepens recovery so a lapsed grouped lease can be swept **per group, on demand** — a **group-scoped
> stalled-sweep** that returns an expired-lease member to **its own lane** (`emq:{q}:g:<group>:pending`), not a
> global pool, respecting the ring, on the **server clock**. It stands on TWO **shipped, already-group-aware**
> recovery surfaces — `EchoMQ.Jobs.@reap` (the server-clock dead-lease scan) and `EchoMQ.Stalled.check/3` (the
> stall-threshold sweep that dead-letters past `max_stalled`), both of which **already** recover a grouped job
> **into its lane** (`jobs.ex` `@reap`'s group branch; `stalled.ex:29-31,76`). **Risk: NORMAL** — it deepens a
> proven group-aware recovery pattern; the genuine delta is the **group-SCOPED** entry (recover one named group's
> lapsed leases, not a queue-wide scan). The v2 master invariant binds (braced keys · branded group ids gated ·
> declared Lua keys · **server clock where a lease is touched** · additive-minor conformance · no wire break).
> Forward-tense: every emq.4.2 surface is PROPOSED, NOT shipped.

## 0 · The slice — what emq.4.2 deepens

The family ([`../emq.4.md`](../emq.4.md)) deepens the shipped fair-lanes mechanism. emq.4.2 carves **group-aware
recovery**: today recovery is **queue-wide** — `@reap` scans the whole `active` set for expired leases, and
`Stalled.check/3` does the same with a dead-letter threshold; both correctly return a **grouped** member to its lane
(not the flat pending), but neither lets an operator recover **one group's** lapsed leases on demand. emq.4.2 adds
the **group-scoped** sweep: recover the expired-lease members of a **named** group (or recover per-group while
respecting each group's ceiling/pause state and the ring), returning each to its `g:<group>:pending` lane,
decrementing `gactive`, re-ringing the lane if serviceable, and waking a parked consumer — all on the server clock.
It is NORMAL-risk because the **recovery-into-the-lane** mechanism is already shipped and proven (the `stalled_group`
conformance scenario — "a lapsed GROUPED lease recovers into the lane `g:<g>:pending` set, not the flat pending");
the delta is the group-scoped entry, not a new recovery shape.

## Goal

emq.4.2 builds, inside `echo/apps/echo_mq`, a **group-scoped stalled-sweep / reap** that recovers a named group's
expired-lease members into **their own lane** (`emq:{q}:g:<group>:pending`, NOT the flat `emq:{q}:pending`),
respecting the ring (re-ring the lane only if serviceable — unpaused, below its `glimit`), decrementing the group's
`gactive`, and pushing a `wake` for any parked consumer — reading `TIME` **server-side** inside the script (the
as-built `@reap`/`@gclaim`/`Stalled` pattern, never a host clock). The **non-group recovery path is byte-unchanged**
(the shipped per-job `@reap` and the queue-wide `Stalled.check/3` behave exactly as before for a job with no group —
emq.4.2 adds the group-scoped sweep **beside** them, or edits the recovery surface only if the reconcile shows that
is the sound form — see **The build choice**), under the A-1 declared-keys law, branded group ids gated at the
lane-key builder, and additive-minor conformance growth.

## Rationale (5W)

- **Why** — a multi-tenant operator needs to recover **one tenant's** stuck work without a queue-wide scan: when a
  group's worker fleet crashes, its in-flight leases must return to **that group's** lane (preserving fairness — the
  crashed tenant's work re-queues behind its own identity, never jumping the ring), on demand, not only on the next
  queue-wide reaper tick. The recovery-into-the-lane mechanism is shipped and proven; emq.4.2 gives it a
  **group-scoped** entry, completing the groups family's recovery axis.
- **What** — emq.4.2 builds (forward-named; the group-scoped sweep does not yet exist — re-probe at the pre-build
  reconcile): (1) a **group-scoped recovery** host verb *(proposed verb name withheld — pinned at the pre-build
  reconcile; a `reap_group/_` or a `:group` option on the existing recovery entry is the candidate, the
  Director/Operator's call)* over an inline `Script.new/2` that scans the expired-lease members of a named group (or
  iterates the ring/lanes), `ZADD`s each back to its `g:<group>:pending` lane, `HINCRBY gactive -1`, re-rings + wakes
  if serviceable, on the server clock; (2) the conformance scenario(s) for group-scoped recovery (additive minor,
  the prior 52 byte-unchanged); (3) the `:valkey` + (if a process/lease surface) determinism suites.
- **Who** — the program (the rung that completes the groups recovery axis); multi-tenant **operators**, who gain
  on-demand per-group recovery; the conformance harness, which grows by the group-scoped recovery scenario(s). The
  shipped `EchoMQ.Stalled` / `@reap` are the proven precedent it deepens.
- **When** — Movement II, the groups family's **second** sub-rung, after emq.4.1 founds the control plane. SPECCED
  this design cycle as a seed; the full triad + the build follow one increment per run. No fork blocks emq.4.2 (it
  carries no wire-shaping fork — the recovery shape is settled by the shipped pattern); the one open question is the
  **build choice** below (additive-beside vs an edit), a pre-build reconcile decision, not an Operator fork.
- **Where** — `echo/apps/echo_mq` only: `jobs.ex` and/or `stalled.ex` (EDIT — the group-scoped sweep; whether it
  lands **additive-beside** the shipped `@reap`/`Stalled` or **edits** one of them is the reconcile's call — **The
  build choice**), `conformance.ex` (EDIT — the group-scoped recovery scenario(s) + the count re-pin),
  `test/*_test.exs` (NEW/EDIT — the `:valkey` recovery proof), the two pinning tests (EDIT — the count). `echo_wire`
  is **untouched** (the sweep rides the shipped connector `eval`). `apps/echomq` is **untouched** (the capability
  reference). The §6 grammar in `keyspace.ex` is **unedited** (no new key family — the lane keys already compose).
  Exact line anchors pinned at the pre-build reconcile.

## Scope

- **In** — group-aware recovery: (1) the **group-scoped** stalled-sweep (a named group's expired-lease members
  returned to their `g:<group>:pending` lane, ring-respecting, `gactive` decremented, the lane re-rung + a `wake`
  pushed if serviceable); (2) the **server clock** (`TIME` read inside the script — INV2); (3) the group-scoped
  recovery conformance scenario(s) (additive minor, the prior 52 byte-unchanged); (4) the `:valkey` suites + (if the
  sweep is a new process/lease surface) the **≥100-iteration determinism loop**, else a multi-seed sweep + an honest
  determinism-posture statement.
- **Out** — any change to the **non-group** recovery path (the shipped per-job `@reap` and the queue-wide
  `Stalled.check/3` stay **byte-unchanged** for a job with no group — INV1); a **host clock** on the lease (server
  clock only — INV2); any **new lane key family** (the sweep rides the shipped `g:`-segment keys — INV3); the
  **dead-letter policy change** (`Stalled`'s `max_stalled` threshold + dead-lettering is the shipped policy emq.4.2
  reuses, it does not redesign it); the **control plane** (emq.4.1); the **metronome** (emq.4.3); the
  **weighted/deficit rotation** (emq.4.4); any **`echo_wire`/transport** change; any **edit to the frozen v1 line**.

### The build choice (additive-beside vs an edit — a pre-build reconcile decision, flag BOTH; do NOT pre-decide)

emq.4.2's group-scoped sweep can land two ways, and the choice is the **pre-build reconcile's** to make (re-probe
the shipped `@reap` (`jobs.ex`) + `EchoMQ.Stalled.check/3`/`@stalled` (`stalled.ex`) — the emq.4.1 build may have
moved the surface), NOT this seed's to pre-decide:

- **Additive-beside (the lower-risk default).** A **new** inline script + host verb scopes the scan to a named group
  (e.g. iterate the group's in-flight members, or filter the `active` scan by the group), leaving the shipped
  `@reap` and `Stalled.check/3` **byte-unchanged** (INV1). NORMAL-risk, no shipped-script edit.
- **An edit to the shipped recovery surface.** If the reconcile shows the sound form is a `:group` option threaded
  **into** the shipped `@reap`/`@stalled` (re-using the proven group branch rather than duplicating it), that edit
  touches a shipped recovery script — then the **non-group path stays byte-unchanged** (the group filter is a
  conditioned branch, not a rewrite — INV1), and the rung re-grades to NORMAL+ with a byte-diff of the unedited
  branches. **Apollo's mandate** attaches only if the edit reaches a lease-critical shipped script — the reconcile
  states which, the Director rules the gate.

This seed **flags both** and withholds the choice for the reconcile; the chapter brief ([`../emq.4.llms.md`](../emq.4.llms.md))
records the same.

## Invariants (the subset emq.4.2 carries, from the family EMQ.4-INV1–8)

- **EMQ.4.2-INV1 (← EMQ.4-INV3) — the non-group recovery path is byte-unchanged.** A job with **no group** flows
  through the shipped per-job `@reap` and the queue-wide `Stalled.check/3` exactly as before; the group-scoped sweep
  is reached ONLY for a named group / a grouped member; if emq.4.2 edits a shipped recovery script, the non-group
  branch is **byte-identical to HEAD** (a conditioned group branch, not a rewrite). *Check:* the shipped `stalled` +
  `reap` conformance scenarios pass **byte-unchanged** (git-verified); a `git diff` of the non-group recovery branch
  is empty; the prior 52 scenarios byte-unchanged.
- **EMQ.4.2-INV2 (← EMQ.4-INV5) — server clock where the lease is touched.** The group-scoped sweep reads `TIME`
  **server-side** inside the script to compute lease expiry (the as-built `@reap` `redis.call('TIME')` pattern,
  `jobs.ex`; the `Stalled` `@stalled` pattern, `stalled.ex`); no host clock crosses the lease. *Check:* a grep of
  the new sweep script for a host-supplied timestamp returns empty; expiry is computed from `redis.call('TIME')`.
- **EMQ.4.2-INV3 (← EMQ.4-INV1) — the wire law (no new key family, ring-respecting recovery).** The sweep rides the
  shipped `emq:{q}:g:<group>:pending` / `ring` / `paused` / `glimit` / `gactive` / `wake` keys; recovery is
  **ring-respecting** (a recovered lane is re-ringed only if unpaused and below its `glimit`, mirroring the shipped
  `@reap` group branch); **no new key family**, **no new wire class**, **no new transport**. *Check:* a grep of the
  sweep for a lane key not in the shipped family returns empty; the re-ring guard matches the shipped `@reap`
  pattern (`SISMEMBER paused` + `glimit` check); the §6 grammar is unedited.
- **EMQ.4.2-INV4 (← EMQ.4-INV4) — branded group identity at the recovery boundary.** A group-scoped recovery names
  a **valid branded group**, gated `EchoData.BrandedId.valid?/1` at the lane-key builder before any wire; a
  recovered member returns to **its own** `g:<group>:pending` lane (the `'group'` field on the job row, the as-built
  `@reap` reads `HGET jk 'group'`). *Check:* an ill-formed group raises before the wire; the recovery scenario reads
  the recovered member back on its own lane, not the flat pending.
- **EMQ.4.2-INV5 (← EMQ.4-INV6) — the additive-minor conformance law.** The group-scoped recovery scenario(s) are
  registered in `scenarios/0` **with their probes in the same change**; the prior **52** scenarios pass
  **byte-unchanged**; the count re-pins **52 → N** in **both** pinning tests. *Check:* the git-diff shows only
  additions to `scenarios/0`; both count assertions updated; `Conformance.run/2` prints N lines.

## Definition of Done

- [ ] The **build choice** (additive-beside vs an edit) settled at the pre-build reconcile against the re-probed
      shipped `@reap` + `Stalled.check/3`; the gate (Apollo's mandate, if any) ruled by the Director from the
      reconcile's finding.
- [ ] The **group-scoped** stalled-sweep built: a named group's expired-lease members return to their
      `g:<group>:pending` lane (not the flat pending), the lane re-ringed if serviceable, `gactive` decremented, a
      `wake` pushed; **server clock** (INV2).
- [ ] The **non-group** recovery path byte-unchanged (the shipped `@reap` + `Stalled.check/3` for a no-group job —
      INV1).
- [ ] The group-scoped recovery conformance scenario(s) registered (additive minor — the prior **52** byte-unchanged;
      the count re-pinned **52 → N** in both pinning tests).
- [ ] The proof: the `:valkey` recovery suites green per-app; the **≥100 determinism loop** if the sweep is a
      process/lease surface, else a multi-seed sweep + an honest determinism-posture statement; honest-row reporting
      (Valkey on 6390 the truth row).
- [ ] INV1–INV5 verified as runnable checks; the spec body ([`../emq.4.md`](../emq.4.md)) remains authoritative; the
      as-built reconcile syncs this seed post-build.

Family: [`../emq.4.md`](../emq.4.md) (the contract, the carve, the forks — authoritative) · Chapter stories:
[`../emq.4.stories.md`](../emq.4.stories.md) (US2 — group-aware recovery) · Chapter brief:
[`../emq.4.llms.md`](../emq.4.llms.md) (R2, AS2) · As-built floor (the build target — re-probe at the pre-build
reconcile; line numbers are hints): `echo/apps/echo_mq/lib/echo_mq/jobs.ex` (`@reap` — the **shipped group-aware**
dead-lease scan: `redis.call('TIME')`, an expired grouped lease `ZADD`ed back to `p .. 'g:' .. g .. ':pending'`,
`HINCRBY gactive -1`, the re-ring guard `SISMEMBER paused` + `glimit`, the `wake` push) +
`echo/apps/echo_mq/lib/echo_mq/stalled.ex` (`EchoMQ.Stalled.check/3` + `@stalled` — the **shipped group-aware**
stall-threshold sweep: `KEYS[1]`=active / `KEYS[2]`=pending / `KEYS[3]`=dead, `max_stalled` dead-lettering, a grouped
job recovered into its lane `stalled.ex:76`, mirroring the reaper's group branch) +
`echo/apps/echo_mq/lib/echo_mq/lanes.ex` (the `g:<group>:pending` / `ring` / `gactive` / `paused` / `glimit` / `wake`
keyspace) + `conformance.ex` (the **52**-scenario set — the `stalled` + `stalled_group` scenarios are the proven
precedent; re-probe the live count) · The v1 capability reference (READ-ONLY — the form NOT to lift; named in the
surface map): `echo/apps/echomq` `stalled_checker` + `moveStalledJobsToWait` (the v1 9-key LIST shape — NOT lifted;
the v2 form is declared-keys + lane recovery) · Design: [`../../../emq.design.md`](../../../emq.design.md) §10 seam 2
/ §4 cluster 2 (the displaced groups family RULED → emq.4), §4 (the server-clock law — `TIME` in transition scripts),
S-6 (the declared-keys A-1 law), S-1/§6 (the braced keyspace) · Roadmap:
[`../../../emq.roadmap.md`](../../../emq.roadmap.md) (the emq.4 row · Movement II) · Approach:
[`../../../../elixir/specs/specs.approach.md`](../../../../elixir/specs/specs.approach.md)
