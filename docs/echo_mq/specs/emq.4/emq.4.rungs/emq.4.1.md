# EMQ.4.1 · The control plane — lane re-assignment + deepened operator verbs (Movement II, the groups family, the first buildable slice)

> **Status: ✅ SHIPPED — the rung's spec body, reconciled to as-built (post-build, pre-ship).** The FIRST
> sub-rung of the emq.4 "groups deepened" family — the family OPENED on the operator control plane, the
> most-exercised surface; the family contract + the carve + the forks are [`../emq.4.md`](../emq.4.md)
> (authoritative — if this carve disagrees with the body, the body wins). emq.4.1 deepened the **operator control
> plane** over the **shipped** fair-lanes surface (`EchoMQ.Lanes`): a **lane re-assignment** (`reassign/4` — a
> member from one lane to another) **and** a **lane-scoped destructive drain** (`drain/3`), plus the carried
> pause/resume/limit, so an operator re-shapes live group traffic; it re-aims the two RETIRED v1 priority commands.
> **Risk: HIGH** — the lane-scoped drain is a **destructive at-rest delete** (it `DEL`s drained members' rows + logs
> + the lane set), so the Director's verify was the **blast-radius mutation battery** (over-reach *and* under-clean
> both caught), NOT the ≥100 determinism loop (the drain mints no branded id, touches no `TIME`, starts no process —
> the loop would forge load, not catch the real hazard). It adds **two** host control verbs + **two** new inline
> scripts (`@greassign`, `@gdrain`) over the shipped `g:`-segment keyspace; it edits **no** shipped lane script
> (`@gclaim`/`@genqueue`/`@gpause`/`@gresume`/`@glimit` byte-unchanged — INV3) and founds no process/lease surface.
> The standard per-app gate ladder + a blast-radius mutation battery + a multi-seed sweep (no id-mint/process/lease
> hazard is introduced — the determinism posture stays an honest multi-seed statement, no ≥100 loop). The v2 master
> invariant binds (braced keys · branded group ids gated at the lane-key builder · declared Lua keys · additive-minor
> conformance 52 → 54 · no wire break). The two verbs shipped at `echo/apps/echo_mq/lib/echo_mq/lanes.ex`
> (`@greassign` :119 / `reassign/4` :262; `@gdrain` :294 / `drain/3` :319).

## 0 · The slice — what emq.4.1 deepens, and why first

The family ([`../emq.4.md`](../emq.4.md)) deepens the shipped fair-lanes mechanism to production multi-tenant depth
along four axes. emq.4.1 carved the **control plane**: the verbs an operator uses to **re-shape contention live** —
move a member between lanes, drain a lane, and pause/resume/limit a lane while traffic flows. It was the **first
buildable** slice because it deepens the most-exercised operator surface, founding the chapter's vocabulary before
the higher-risk metronome (emq.4.3) and weighted fairness (emq.4.4) rungs. It edits **no** shipped lane script (the
two new verbs are **additive** inline scripts), but the lane-scoped drain is a **destructive at-rest delete**, which
is why the rung graded **HIGH** and the verify was the **blast-radius mutation battery** (the destructive verb's
over-reach and under-clean are the real hazards — not a same-millisecond mint, so not the ≥100 loop). It also
discharges the two RETIRED v1 priority commands — the groups feature record already re-aimed them to this rung
([`../../emq.commands/features/groups/changePriority-7.md`](../../emq.commands/features/groups/changePriority-7.md),
[`../../emq.commands/features/groups/getCountsPerPriority-4.md`](../../emq.commands/features/groups/getCountsPerPriority-4.md)).

## Goal

emq.4.1 built, inside `echo/apps/echo_mq`, the **fair-lanes operator control plane**: (a) a **lane re-assignment**
verb `EchoMQ.Lanes.reassign(conn, queue, job_id, dst_group)` (arity 4, **src-derived**) over the inline `@greassign`
(`lanes.ex:119`) that moves a **pending** member from its current lane to `dst` — `HGET <row> 'group'` (src read
in-script — the row is authoritative, so src cannot mismatch), `ZREM emq:{q}:g:<src>:pending`, `ZADD
emq:{q}:g:<dst>:pending` at **score 0**, **`HSET <row> 'group' dst`** (the load-bearing rewrite — the later
`@gclaim`/`@complete`/`@retry`/`@reap` read `HGET <row> 'group'` to find the lane and the active counter:
`jobs.ex:182/259/320/349`), and the ring re-shaped (`dst` returned if serviceable + a wake; `src` dropped if its
lane is now empty) — in **one atomic script** (both lanes share the one `{q}` slot, so a **cross-queue move is not
expressible** at arity 4 — atomic by construction, not by rejection), `job_id` gated `Keyspace.job_key/2` and
`dst_group` gated `lane_key!/2` before any wire. The verdict is a **numeric sentinel** the host maps to an atom (the
`@genqueue`/`@update_data` return idiom — no `error_reply`, so the closed wire-class registry stays **unextended**,
INV1): `1 → {:ok, :reassigned}`, `0 → {:ok, :noop}` (dst already equals src), `-1 → {:error, :not_found}` (no row /
no group), `-2 → {:error, :not_pending}` (the member is claimed/in-flight — `ZREM` returns 0, the row left
untouched since its `gactive` sits under src). (b) a **lane-scoped destructive drain**
`EchoMQ.Lanes.drain(conn, queue, group)` (arity 3) over the inline `@gdrain` (`lanes.ex:294`) — the `Admin.@drain`
wipe scoped to **one** lane: `ZRANGE` the lane → `DEL` each member's row + its §6 `:logs` subkey (the job key
derived from the declared base root by the A-1 convention) → `DEL` the lane set → `LREM` the group from the ring;
answers `{:ok, n}`. **Blast radius:** ONLY the target lane's pending rows + logs + set + the ring entry — NOT
`active`/in-flight (not in the lane), NOT `gactive` (it counts in-flight, not pending), NOT `paused`/`glimit` (the
lane's config survives), NOT any sibling lane, NOT the repeat registry. (c) the carried `Lanes.{pause,resume,limit}`
(byte-unchanged) + the **re-aim** of the two RETIRED v1 priority commands — `changePriority-7` → **lane
re-assignment** (there is **no numeric per-job priority**; mint order IS the order theorem; per-group lanes replace
priority) and `getCountsPerPriority-4` → `EchoMQ.Metrics.lane_depths/3` (the **shipped** per-lane backlog read, no
new read) — all under the A-1 declared-keys law, branded group ids gated at the builder, and additive-minor
conformance growth (52 → 54). emq.4.1 edits **no** shipped lane script and founds **no** process/lease surface; the
two new verbs are **additive** inline scripts, and the drain's destructiveness (not a mint hazard) is what graded
the rung HIGH.

## Rationale (5W)

- **Why** — the control plane is the **foundation** of the groups-deepened family: it is the surface a multi-tenant
  operator reaches for first (move a tenant's work, yield a noisy lane, raise a starved lane's ceiling), and it
  carries the **least** risk, so it founds the chapter's vocabulary and gate posture before the metronome and the
  fairness rungs build on a proven control surface. It also closes the two RETIRED v1 priority commands the canon
  re-aimed here — completing the groups feature record's emq.4 obligation for the priority surface.
- **What** — emq.4.1 built (as-built, two verbs): (1) `EchoMQ.Lanes.reassign(conn, queue, job_id, dst_group)`
  (arity 4, **src-derived** — the Director ruled the name/arity D-2) over the inline `@greassign` (`lanes.ex:119`):
  `HGET <row> 'group'` reads src in-script, `ZREM src_lane`, `ZADD dst_lane` at score 0, **`HSET <row> 'group' dst`**
  (the load-bearing rewrite), the ring re-shaped (`dst` returned if serviceable + a wake; `src` dropped if emptied) —
  one atomic script, both `{q}`-co-located, every key a declared `KEYS[n]` or grammar-rooted; the verdict is a
  numeric sentinel (`1`/`0`/`-1`/`-2` → `{:ok, :reassigned}`/`{:ok, :noop}`/`{:error, :not_found}`/`{:error,
  :not_pending}`); (2) `EchoMQ.Lanes.drain(conn, queue, group)` (arity 3 — **R3 ruled BUILD**, the Director/Operator's
  call, D-5) over the inline `@gdrain` (`lanes.ex:294`): the `Admin.@drain` wipe scoped to one lane (`ZRANGE` → `DEL`
  rows + logs → `DEL` lane set → `LREM` ring), answering `{:ok, n}`, blast radius bounded to the target lane's
  pending rows/logs/set + the ring entry; (3) the carried `Lanes.{pause,resume,limit}` (byte-unchanged); (4) the
  re-aim — `changePriority-7` → re-assignment, `getCountsPerPriority-4` → `Metrics.lane_depths/3` (the shipped read —
  no new read, Fork C parked); (5) the conformance scenarios `reassign` + `lane_drain` (additive minor, the prior 52
  byte-unchanged, count re-pinned 52 → 54); (6) the `:valkey` test suites + a multi-seed sweep + the blast-radius
  mutation battery.
- **Who** — the program (the rung that founds the groups control plane and discharges the RETIRED v1 priority
  commands); multi-tenant **operators** of the bus, who gain live re-shaping of group traffic (move a tenant's work,
  drain a decommissioned tenant's lane, raise a starved lane's ceiling); the conformance harness, which grows by the
  `reassign` + `lane_drain` scenarios (additive minor). **codemojex** (the worked consumer): a player whose work must
  move to a different lane (a re-grouped player), or a player whose lane is decommissioned (drained), is the
  prospective shape — recorded, not asserted.
- **When** — Movement II, the groups family's **first** sub-rung, SHIPPED after Movement I closed; this body is
  reconciled to as-built (post-build, pre-ship). **Fork C** (the intra-group priority dimension — below) was surfaced
  and **ruled PARK** (D-1) — emq.4.1 lanes stay score-0, so no re-scope was needed; the `@greassign` `ZADD`s at score
  0.
- **Where** — `echo/apps/echo_mq` only (as-built): `lanes.ex` (EDIT — `reassign/4` + `@greassign`, `drain/3` +
  `@gdrain`; the shipped `@gclaim`/`@genqueue`/`@gpause`/`@gresume`/`@glimit` byte-frozen), `conformance.ex` (EDIT —
  the `reassign` + `lane_drain` scenarios + the count re-pin 52 → 54), `test/*_test.exs` (NEW/EDIT — the `:valkey`
  re-assignment + lane-drain proofs), the two pinning tests `conformance_run_test.exs` + `conformance_scenarios_test.exs`
  (EDIT — the count 52 → 54). `metrics.ex` is **UNTOUCHED** (the `getCountsPerPriority-4` re-aim target
  `lane_depths/3` was already shipped — Fork C parked, no Fork-A score dimension). `jobs.ex` is **UNTOUCHED** (the
  move WRITES the `group` field `jobs.ex` READS — no `jobs.ex` edit needed). `echo_wire` is **untouched** (the control
  plane rides the shipped connector `eval`/`command`). `apps/echomq` is **untouched** (the capability reference). The
  §6 grammar in `keyspace.ex` is **unedited** (no new key family — the lane keys already compose).

## Scope

- **In** — the operator control plane: (1) the **lane re-assignment** verb `reassign/4` (a **pending** member
  `g:<src>:pending` → `g:<dst>:pending`, one atomic script, src-derived from the row, dst branded-gated, the row's
  `group` rewritten, the ring re-shaped — `@greassign`); (2) the **lane-scoped destructive drain** `drain/3` (one
  lane's pending rows + logs + set + ring entry wiped — `@gdrain`, the `Admin.@drain` pattern scoped to a lane);
  (3) the carried `Lanes.{pause,resume,limit}` (byte-unchanged); (4) the **re-aim** of `changePriority-7`
  (→ re-assignment) and `getCountsPerPriority-4` (→ the shipped `Metrics.lane_depths/3`); (5) the `reassign` +
  `lane_drain` conformance scenarios (additive minor, the prior 52 byte-unchanged, 52 → 54); (6) the `:valkey` suites
  + the **blast-radius mutation battery** (the destructive drain's over-reach + under-clean) + an honest multi-seed
  sweep (a determinism-posture statement — no id-mint/process/lease hazard introduced).
- **Out** — any **numeric per-job priority** (retired by design — the v1 packed-score scheme does not return; INV1);
  any **new lane key family** (both verbs ride the shipped `g:<group>:pending` keys + the ring; no `prioritized` key,
  no `pc` counter — INV1); the **intra-group priority dimension** (a non-zero lane score — **Fork C**, **ruled
  parked**, NOT built); a **cross-queue** lane move (**not expressible at arity 4** — src is derived in-script from
  the row and the dst lane is a `lane_key!` of *this* queue, so both lanes share the one `{q}` slot and the move is
  atomic **by construction**, never a rejected case; a member moving to a lane in a *different* queue inherits the
  emq.3 cross-queue posture and is not built here); a **re-assignment of a claimed/in-flight member** (a claimed
  member is in `active`, not in its lane — `@greassign` answers `{:error, :not_pending}` and leaves the row
  untouched, since its `gactive` sits under the source group); any **shipped lane-script edit** (`@gclaim`/
  `@genqueue`/`@gpause`/`@gresume`/`@glimit` are byte-unchanged — INV3); any **process/lease surface** (the metronome
  is emq.4.3); the **weighted/deficit rotation** (emq.4.4); the **group-scoped recovery sweep** (emq.4.2); any
  **`echo_wire`/transport** change; any **edit to the frozen v1 line**.

## Invariants (the subset emq.4.1 carries, from the family EMQ.4-INV1–8)

- **EMQ.4.1-INV1 (← EMQ.4-INV1) — the wire law (no break, no new key family, no numeric priority).** emq.4.1 adds
  **no new lane key family** (`@greassign` + `@gdrain` + the carried verbs ride the shipped `emq:{q}:g:<group>:pending`
  / `ring` / `paused` / `glimit` / `gactive` / `wake` keys + the declared `job:<id>` row); **no numeric per-job
  priority** (the v1 packed-score scheme does not return — re-assignment moves the member between lanes); **no new
  wire class** (`@greassign` returns numeric sentinels via the `@genqueue`/`@update_data` idiom, no `error_reply`, so
  the closed registry stays unextended; the kind law reuses `EMQKIND` where a kind check applies); **no new
  transport**. *Check:* a grep of `@greassign`/`@gdrain` for a lane key not in the shipped `g:`-segment family returns
  empty; a grep for a numeric-priority score / `prioritized` key returns empty; `{emq}:version` reads `echomq:2.0.0`
  after connect; the §6 grammar is unedited.
- **EMQ.4.1-INV2 (← EMQ.4-INV4) — branded group identity at both lane boundaries.** `reassign/4` derives the source
  group from the row (`HGET <row> 'group'` — the row is authoritative) and gates the **destination** group +
  the `job_id` at the builders (`lane_key!/2` + `Keyspace.job_key/2`, each raising on an ill-formed branded id)
  **before** any wire; `drain/3` gates its group at `lane_key!/2`. *Check:* an ill-formed destination group or
  `job_id` (reassign) / group (drain) raises before the wire; the `reassign` scenario uses two distinct branded
  groups.
- **EMQ.4.1-INV3 (← EMQ.4-INV3) — the shipped lane surface is byte-unchanged.** emq.4.1 edits **no** shipped lane
  script — `@gclaim` (the ring rotation), `@genqueue`, `@gpause`, `@gresume`, `@glimit` are **byte-identical to
  HEAD** (`grep redis.call` on those scripts in the lib diff = 0 — verified: the only `redis.call` diff lines are `+`
  additions in `@greassign`/`@gdrain`, zero changes to the frozen five); the prior fair-lanes conformance scenarios
  (`rotate`, `pause`, `limit`, `lane_depth`, `stalled_group`, `obliterate_grouped`) pass **byte-unchanged**
  (git-verified). *Check:* the byte-freeze grep on the five shipped lane scripts = 0; the prior scenarios
  git-verified unchanged.
- **EMQ.4.1-INV4 (← EMQ.4-INV6) — the additive-minor conformance law.** The `reassign` + `lane_drain` scenarios are
  registered in `scenarios/0` **with their probes in the same change** (`conformance.ex:118`/`:119`); the prior **52**
  scenarios pass **byte-unchanged**; the count re-pins **52 → 54** in **both** pinning tests
  (`conformance_scenarios_test.exs` + `conformance_run_test.exs:47` `{:ok, 54}`). *Check:* the git-diff shows only
  additions to `scenarios/0`; both count assertions updated; `Conformance.run/2` prints 54 lines.
- **EMQ.4.1-INV5 (← EMQ.4-INV1/INV2) — slot soundness (the move is atomic by construction; the drain is
  declared-keys + bounded).** `@greassign`'s source and destination lanes share **one** `{q}` slot — src is derived
  in-script from the row and dst is a `lane_key!` of *this* queue, so a **cross-queue move is not expressible** at
  arity 4 (atomic **by construction**, not by a rejected case); every key is a declared `KEYS[n]` or grammar-rooted
  (the source lane derives from the declared ARGV queue base `base..'g:'..src..':pending'`, the `@gclaim` convention).
  `@gdrain` declares its keys + derives each member's job key from the declared base root; its destructive blast
  radius is **bounded** to the target lane's pending rows + logs + set + the ring entry (NOT `active`/`gactive`/
  `paused`/`glimit`/sibling-lanes/repeat). *Check:* `@greassign`/`@gdrain` declare keys of exactly one `{q}`; no
  cross-queue destination is constructible (arity 4, dst gated to this queue); the lane-drain blast-radius scenario
  asserts a sibling lane + the in-flight `gactive` counter + the repeat registry survive; no
  script claims atomicity across slots.

## The rung's fork — Venus surfaced, the Operator (via the Director) RULED

### FORK C — the intra-group priority dimension: land at emq.4.1 vs park — **RULED: PARK (Arm B, D-1)**

> **The canon-recorded delta.** The groups feature record names a PROPOSED emq.4 delta: an intra-lane priority
> dimension as a **non-zero score on the existing `g:<group>:pending` ZSET** (a `ZCOUNT`/`ZRANGEBYSCORE` over a
> score window — **no new key**), the forward equivalent of the v1 `getCountsPerPriority`/`changePriority` band.
> Does it land at **emq.4.1** (alongside the control plane) or **park** past the chapter?
> - **Arm A — land it at emq.4.1.** Full v1 parity for the priority surface within this rung. *Cost:* a score
>   dimension on the lane ZSET complicates the **score-0 invariant** the ring rotation assumes — the shipped
>   `@gclaim` `ZPOPMIN`s the lane head (`lanes.ex:41`), so a non-zero score changes which member is the head, and
>   touching the ring's head-selection is exactly the byte-freeze-sensitive surface emq.4.1 is authored to leave
>   untouched (INV3).
> - **Arm B — park it (RECOMMENDED).** Keep lanes score-0 (the ring IS the fairness); the named consumers (codemojex
>   one-lane-per-player) need **lane** fairness, not intra-lane priority. *Cost:* the intra-group priority band is
>   not available in emq.4.
>
> **RULED: Arm B (park) — D-1.** The score-0 lane invariant is load-bearing for the ring's head-selection; the
> shipped `@greassign` `ZADD`s the moved member at **score 0** (`lanes.ex:125`), keeping lanes score-0 exactly as the
> ruling requires — so no Arm-A re-scope was needed. The intra-group priority band is recorded as **parked** (a real
> but unrequested surface). An Arm-A ruling would have threaded a score dimension into emq.4.1 and re-examined the
> ring's head-selection (a larger, `@gclaim`-touching scope) — that ruling was not made. (This was never Venus's to
> decide — surfaced, the Operator ruled.)

## Definition of Done

- [x] **Fork C** surfaced to the Director with both arms + costs + the recommendation (park); **RULED PARK (D-1)** —
      lanes stay score-0, the `@greassign` `ZADD`s at score 0; no Arm-A re-scope needed.
- [x] The **lane re-assignment** verb + its inline atomic script built: `Lanes.reassign/4` + `@greassign`
      (`lanes.ex:119/262`) — a **pending** member moves `g:<src>:pending` → `g:<dst>:pending` (src derived from the
      row, dst branded-gated, one slot), the row's `group` rewritten, the ring re-shaped; a **cross-queue move is not
      expressible at arity 4** (atomic by construction, not a rejected case); the verdict is the numeric-sentinel set
      (`{:ok, :reassigned}`/`{:ok, :noop}`/`{:error, :not_found}`/`{:error, :not_pending}`).
- [x] The **lane-scoped destructive drain** built (**R3 ruled BUILD, D-5**): `Lanes.drain/3` + `@gdrain`
      (`lanes.ex:294/319`) — one lane's pending rows + logs + set + ring entry wiped, `{:ok, n}`, blast radius
      bounded; the carried `Lanes.{pause,resume,limit}` byte-unchanged.
- [x] The **re-aim** discharged: `changePriority-7` → re-assignment (no numeric priority), `getCountsPerPriority-4`
      → the shipped `Metrics.lane_depths/3` (no new read), recorded in the rung's record.
- [x] The `reassign` + `lane_drain` conformance scenarios registered (additive minor — the prior **52**
      byte-unchanged; the count re-pinned **52 → 54** in both pinning tests).
- [x] The proof: the `:valkey` suites green per-app; the **blast-radius mutation battery** (the destructive drain's
      over-reach + under-clean both caught) + a multi-seed sweep + an honest determinism-posture statement (no
      id-mint/process/lease hazard introduced — the drain mints no id/`TIME`/process, so **no ≥100 loop**; the rung
      grades **HIGH** on the destructive at-rest delete, not a mint hazard); no shipped lane script edited (INV3);
      honest-row reporting (Valkey on 6390 the truth row).
- [x] INV1–INV5 verified as runnable checks; the spec body ([`../emq.4.md`](../emq.4.md)) remains authoritative;
      this seed reconciled to as-built (post-build, pre-ship).

Family: [`../emq.4.md`](../emq.4.md) (the contract, the carve, the forks — authoritative) · Chapter stories:
[`../emq.4.stories.md`](../emq.4.stories.md) (US1 — the control plane) · Chapter brief:
[`../emq.4.llms.md`](../emq.4.llms.md) (R1, AS1) · As-built surface (SHIPPED; line numbers are the Stage-5
reconcile's): `echo/apps/echo_mq/lib/echo_mq/lanes.ex` — **the two new verbs:** `reassign/4` (`:262`) + `@greassign`
(`:119`, the atomic move — `HGET <row> 'group'` src-derive, `ZREM`/`ZADD` score-0, `HSET <row> 'group' dst`, the ring
re-shape) and `drain/3` (`:319`) + `@gdrain` (`:294`, the lane-scoped wipe); **the byte-frozen five:** `enqueue/5`
`@genqueue`, `claim/3` `@gclaim` (the ring `LMOVE` + `ZPOPMIN` head — score-0, undisturbed), `pause/3` `@gpause`,
`resume/3` `@gresume`, `limit/4` `@glimit`; plus `depth/3`, `lane_key!/2` the branded-gated builder; the
`g:<group>:pending` / `ring` / `paused` / `glimit` / `gactive` / `wake` keyspace + the declared `job:<id>` row.
+ `jobs.ex` (the `group`-field readers the move rewrites for — `@complete:182` / `@retry:259` / `@promote:320` /
`@reap:349`; **UNTOUCHED** — the move writes the field they read) + `metrics.ex` (`lane_depth/3`, `lane_depths/3` =
`@lane_counts` — the `getCountsPerPriority-4` re-aim target, already shipped, **UNTOUCHED**) + `admin.ex` (`drain/3`
`@drain` — the queue-wide drain the lane-scoped `@gdrain` mirrors) + `conformance.ex` (the **54**-scenario set —
`reassign:118` + `lane_drain:119`; `conformance_run_test.exs:47` `{:ok, 54}`) · The v1 capability reference (the
re-aim record, READ-ONLY — the form NOT to lift):
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
