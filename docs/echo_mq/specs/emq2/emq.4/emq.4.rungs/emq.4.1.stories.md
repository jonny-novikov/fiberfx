# EMQ.4.1 · user stories — the fair-lanes control plane (lane re-assignment + lane-scoped drain)

> Who wants the groups control plane, what they need, and how we know it works. Each story is Connextra with
> Given/When/Then acceptance, an INVEST line naming the invariant(s) it encodes, and a Priority/Size/Implements line;
> the file ends with a Coverage line mapping every Deliverable to ≥1 story. The standing **`EMQ.4.1-US-GATE`** carries
> the Valkey gate (design §7) — a structural gate. emq.4.1 OPENED the groups-deepened family (Movement II's opener):
> the operator control plane — move a member between lanes, drain a lane, and pause/resume/limit a lane while traffic
> flows — over the **shipped** `EchoMQ.Lanes` keyspace, **no** shipped-lane-script edit. This file is reconciled to
> **as-built** (post-build, pre-ship); the spec **body** [`./emq.4.1.md`](emq.4.1.md) (and the family
> [`../emq.4.md`](../emq.4.md)) is authoritative — when a derived artifact disagrees with the body, the body wins.
> **The rung shipped HIGH-risk** — the lane-scoped drain is a destructive at-rest delete, verified by the
> blast-radius mutation battery (not the ≥100 loop — the drain mints no id/`TIME`/process).

## EMQ.4.1-US1 — an operator moves a pending member between lanes (the headline re-assignment)

As a **multi-tenant bus operator**, I want to move a pending member from one lane to another in one atomic step, so
that I can re-home a re-grouped tenant's work live — without a numeric per-job priority and without the member ever
existing in two lanes or neither.

Acceptance criteria
- Given a **pending** member on lane `src` (in `emq:{q}:g:<src>:pending`) and a valid branded destination group `dst`,
  when `EchoMQ.Lanes.reassign(conn, queue, job_id, dst_group)` is called, then the member **leaves** `g:<src>:pending`
  and **enters** `g:<dst>:pending` at **score 0** in **one atomic `@greassign` script** (`lanes.ex:119`), the member's
  row `group` field is **rewritten to `dst`**, and the ring reflects both lanes' new serviceability (`dst` re-rings if
  serviceable, with a wake; `src` drops from the ring if it is now empty) — the call answers `{:ok, :reassigned}`.
  **No numeric priority is involved** (the v1 `changePriority-7` re-aim: mint order IS the order theorem; per-group
  lanes replace priority).
- Given the **source group is the row's authority**, when `reassign/4` runs, then it does **not** take `src` as an
  argument (arity 4): it reads `src` in-script (`HGET <row> 'group'`), so the move cannot disagree with what the row
  records; a `dst` that already equals the member's current group answers `{:ok, :noop}` (changing nothing).
- Given a **cross-queue** destination, when re-assignment is attempted, then it is **not expressible at arity 4** — the
  `dst` lane is a `lane_key!` of *this* queue and `src` is derived from the row, so both lanes share the one `{q}`
  slot and the move is atomic **by construction** (a member moving to a lane in a *different* queue is not a rejected
  case but an impossible one; the cross-queue posture is emq.3's, not built here).

INVEST — independent (the family's headline control verb); testable by the `reassign` `:valkey` scenario (a pending
member moves `src`→`dst`; both lanes' ZSETs reflect it; the row `group` = `dst`; the ring updates; `{:ok, :noop}` on
dst==src); encodes EMQ.4.1-INV1 (no new key family, no numeric priority), EMQ.4.1-INV2 (branded dst, src-derived),
EMQ.4.1-INV5 (one-slot atomic move; cross-queue not expressible). Priority: must · Size: 3 · Implements: EMQ.4.1-D2.

## EMQ.4.1-US2 — the re-assigned member is served in its new lane's rotation, the ceiling is honest

As a **bus consumer running per-tenant lanes**, I want a re-assigned member to be claimed as part of its **new** lane's
fair rotation and counted against the **new** lane's concurrency, so that the move is complete — fairness and the
ceiling follow the member to its new home, with no stale accounting left behind.

Acceptance criteria
- Given a member moved from `src` to `dst`, when the ring is rotated and `dst` is served (`EchoMQ.Lanes.claim/3`),
  then the member is returned **with `group = dst`** (the shipped `@gclaim` reads the lane head and the row's group),
  and a subsequent completion decrements **`gactive[dst]`**, not `gactive[src]` — because `@greassign` rewrote the
  row's `group` field (`HSET <row> 'group' dst`, `lanes.ex:126`), the field the shipped `@complete`/`@retry`/
  `@promote`/`@reap` read (`HGET <row> 'group'` at `jobs.ex:182/259/320/349`) to find the lane and the active counter.
  This row-rewrite is the **load-bearing** half of the move — a ZSET swap alone would silently corrupt the ceiling
  accounting on the next claim/complete.
- Given a **claimed (in-flight)** member, when re-assignment is attempted, then `@greassign` finds it **not pending in
  `src`** (`ZREM` returns 0) and answers `{:error, :not_pending}`, leaving the row untouched (its `gactive` sits under
  the source group) — a claimed member is in `active`, not in its lane, so it is not moved.
- Given the `src` lane is emptied by the move (its last member left), when the ring is next rotated, then `src` is
  **not** served (it was dropped from the ring by `@greassign`'s `LREM` on `ZCARD == 0`); and given `dst` was paused or
  at its ceiling, when the member is moved into it, then the member enters `g:<dst>:pending` but `dst` is **not** added
  to the ring (the move respects `dst`'s serviceability exactly as `@genqueue`/`@promote` do).

INVEST — independent (the move's correctness past the ZSET swap); testable by the `reassign` scenario claiming the
member from `dst` (group = `dst`) and a completion decrementing `gactive[dst]`, plus the `{:error, :not_pending}` and
the `src`-emptied-lane drop; encodes EMQ.4.1-INV1, EMQ.4.1-INV5 (the move is sound, not just a ZSET swap). Priority:
must · Size: 3 · Implements: EMQ.4.1-D2.

## EMQ.4.1-US3 — an operator drains a lane and reads per-lane backlog (the destructive drain + the re-aim)

As a **multi-tenant bus operator**, I want to drain a decommissioned tenant's lane down to nothing and to read each
lane's separate backlog, so that I can reclaim a lane's keyspace footprint and see where contention is — the
operator-grade control the chapter names, with the destruction bounded to exactly the target lane.

Acceptance criteria
- Given a lane with pending members, when `EchoMQ.Lanes.drain(conn, queue, group)` is called, then the `@gdrain`
  script (`lanes.ex:294`) empties the lane's `g:<group>:pending` set, **deletes** each drained member's row + its §6
  `:logs` subkey (the job key derived from the declared base root), deletes the lane set, and drops the group from the
  ring — answering `{:ok, n}`, the count drained.
- Given the drain is **destructive at rest**, when it runs, then its **blast radius is bounded** to the target lane's
  pending rows + logs + set + the ring entry: an `active`/in-flight member is **not** drained (it is not in the lane),
  the lane's `gactive` counter is **not** touched (it counts in-flight, not pending), the lane's `paused`/`glimit`
  config **survives**, **every sibling lane survives**, and the **repeat registry survives** — the over-reach (it
  deletes more than the lane) and the under-clean (it leaves a row/log/set/ring entry) are both caught by the verify's
  blast-radius mutation battery.
- Given several lanes with backlog, when `EchoMQ.Metrics.lane_depths/3` is read (the v1 `getCountsPerPriority-4`
  re-aim — the **shipped** read, **no new read surface** while Fork C is parked), then it answers each group's
  separate live backlog over its lane ZSET, branded-gated; and the re-aim record discharges `changePriority-7` → lane
  re-assignment, `getCountsPerPriority-4` → `Metrics.lane_depths/3`, recorded in the rung's record.

INVEST — independent (the operator destructive + read surface); testable by the `lane_drain` `:valkey` scenario (one
lane emptied — rows + logs + set + ring entry gone, a sibling lane + `gactive` + the repeat registry intact) + a
`lane_depths/3` read; encodes EMQ.4.1-INV1 (rides shipped keys), EMQ.4.1-INV2 (branded group), EMQ.4.1-INV5 (the
drain is declared-keys + bounded). Priority: must · Size: 3 · Implements: EMQ.4.1-D3, EMQ.4.1-D4, EMQ.4.1-D5.

## EMQ.4.1-US4 — the shipped lane surface is byte-unchanged; the new behavior is conformance; the prior set is untouched

As a **protocol maintainer**, I want the two new verbs to ride the shipped lane keyspace under the declared-keys law,
to edit **no** shipped lane script, and to grow conformance only additively, so that the control plane costs the wire
nothing — no new key family, no broken scenario, no fairness-critical-script edit, no new wire class.

Acceptance criteria
- Given `@greassign` + `@gdrain`, when the A-1 lint scans them, then **every** key is a shipped `g:`-segment lane key
  (`g:<group>:pending`/`ring`/`paused`/`glimit`/`gactive`/`wake`) plus the declared job row — each in `KEYS[]` or
  derived from a declared `KEYS[n]` queue-base root by the registered grammar (`@greassign`'s source lane derives from
  the ARGV base `base..'g:'..src..':pending'`, the `@gclaim` convention) — and **no** key is a new family, a numeric
  priority score, a `prioritized` key, or read out of a data value; `@greassign` returns **numeric sentinels** (no
  `error_reply`, so the closed wire-class registry stays unextended).
- Given the shipped lane scripts, when emq.4.1 lands, then `@gclaim` (the ring rotation + `ZPOPMIN` head), `@genqueue`,
  `@gpause`, `@gresume`, `@glimit` are **byte-identical to HEAD** (`grep redis.call` on those scripts in the lib diff
  = 0 — verified: the only `redis.call` diff lines are `+` additions in `@greassign`/`@gdrain`), and the prior
  fair-lanes scenarios (`rotate`, `pause`, `limit`, `lane_depth`, `stalled_group`, `obliterate_grouped`) pass
  **byte-unchanged** (git-verified).
- Given the prior conformance set, when `reassign` + `lane_drain` are added, then the **52** prior scenarios pass
  **byte-unchanged** (name + contract + verdict body, git-verified), each new scenario is registered **with its probe
  in the same change** (`conformance.ex:118`/`:119`), and the count re-pins **52 → 54** in **both** pinning tests
  (`conformance_scenarios_test.exs` + `conformance_run_test.exs:47` `{:ok, 54}`); `EchoMQ.Conformance.run/2` prints 54
  lines.

INVEST — independent (the wire-cost contract); testable by the A-1 lint + the byte-freeze grep on the 5 shipped lane
scripts + the git-verified byte-unchanged 52 + the re-pinned 54; encodes EMQ.4.1-INV1, EMQ.4.1-INV3, EMQ.4.1-INV4.
Priority: must · Size: 2 · Implements: EMQ.4.1-D5.

## EMQ.4.1-US5 — the control plane is proven; HIGH-risk on the destructive delete; the determinism posture is honest; no regression

As a **program Director**, I want the control-plane suites proven on the certified wire, the destructive drain
verified by a blast-radius mutation battery, the determinism posture stated honestly, and the shipped surface
unregressed, so that emq.4.1 closes on a proven control surface, not a false-green.

Acceptance criteria
- Given the `reassign` + `lane_drain` + the deepened-control `:valkey` suites, when they run per-app inside
  `echo/apps/echo_mq` (`TMPDIR=/tmp`, `--include valkey`), then they are green against **Valkey on port 6390** (the
  truth row), and `EchoMQ.Conformance.run/2` over a live connection prints `{:ok, 54}` with the prior 52 byte-unchanged.
- Given the lane-scoped drain is a **destructive at-rest delete**, when the rung is verified, then the verify is the
  **blast-radius mutation battery** (the drain's **over-reach** — deleting beyond the target lane — and its
  **under-clean** — leaving a row/log/set/ring entry — are both caught), which is the right gate for a destructive
  op (the **≥100-iteration loop is NOT run** — the drain mints no branded id, touches no `TIME`, starts no process, so
  the loop would forge load rather than catch the real hazard); the rung grades **HIGH** on the destructive delete,
  not a mint hazard, and that posture is recorded.
- Given the shipped surface, when emq.4.1 lands, then the emq.1 + emq.2.{1,2,3,4} + emq.3.{1,2,3,4,5} suites +
  `Conformance.run/2` pass **unchanged** (no regression — INV3), the diff stays inside `echo/apps/echo_mq`
  (no `echo_wire`, no `keyspace.ex` grammar edit, no `jobs.ex` edit, no `metrics.ex` edit, no `apps/echomq`), and the
  boundary grep is empty.

INVEST — independent (the proof + the honest HIGH-risk posture); testable by the `:valkey` suites green + the
blast-radius mutation battery + the stated determinism posture (HIGH on the destructive delete, no ≥100 loop) + the
prior suites unchanged + the boundary grep empty; encodes EMQ.4.1-INV3, EMQ.4.1-INV5. Priority: must · Size: 2 ·
Implements: EMQ.4.1-D6.

## EMQ.4.1-US-FORK — Fork C is settled at the right gate (Venus surfaced, the Operator RULED)

As a **program Operator**, I want Fork C (the intra-group priority dimension — land at emq.4.1 vs park) surfaced with
arms + costs + a recommendation and ruled, so that emq.4.1 does not silently thread a score dimension onto the lane
ZSET that is mine to rule.

Acceptance criteria
- Given the family body and this rung's body surface **Fork C** with both arms steelmanned and the recommendation
  (Arm B, park — keep lanes score-0; the score-0 invariant is load-bearing for the `@gclaim` `ZPOPMIN` head-selection),
  when emq.4.1 opens, then the fork is recorded for the Operator's ruling.
- Given the Operator **RULED PARK (D-1)**, when emq.4.1 built, then lanes stay **score-0** — the `@greassign` `ZADD`s
  the moved member at **score 0** (`lanes.ex:125`), no non-zero lane score is threaded, and **no** Arm-A re-scope was
  needed (the ruled arm is the built arm).
- Given an Arm-A ruling would have landed intra-group priority at emq.4.1, when it is weighed, then it would have
  re-derived the carve (the score dimension on the lane ZSET + the `@gclaim` head-selection re-examination — a larger,
  `@gclaim`-touching scope) — that ruling was not made.

INVEST — independent (the gate that precedes the build's score decision); testable by the ledger record of Fork C's
ruling + the build's lane-score posture matching the ruled arm (park → score-0 at `lanes.ex:125`); encodes
EMQ.4.1-INV1 (no numeric priority while parked). Priority: must · Size: 1 · Implements: EMQ.4.1-D1.

## EMQ.4.1-US-GATE — the Valkey gate (specification by example)

As a **release gate**, I want the deepened control plane proven on the certified wire under honest-row reporting, so
that the v2 laws bind at the wire and a host without Valkey reports its row honestly (design §7, S-4).

Acceptance criteria
- Given the engine-hygiene allowlist {Valkey, Redis-as-the-historical-row}, when the lane suites run, then they run
  against **Valkey on port 6390** (the truth row; `redis-cli -p 6390 ping` → `PONG`); a host without Valkey runs the
  probes elsewhere and reports them as that row, never the truth row.
- Given `GET {emq}:version`, when read after the bus connects, then it returns `echomq:2.0.0` (the connect-scoped
  fence — emq.4.1 changes nothing about the fence; the five-code union stands unextended, INV1).
- Given grammar totality, when a lane key is parsed, then it classifies under the §6 grammar (the `g:<group>:pending`
  / `ring` / `paused` / `glimit` / `gactive` / `wake` members + the `job:<id>` row), the queue name extracts as the
  `{q}` hashtag, and `q ≠ "emq"` keeps the slot families disjoint — emq.4.1 edits the grammar's shape **not at all**
  (INV1).
- Given the conformance run, when `EchoMQ.Conformance.run/2` executes over a live connection, then it prints one line
  per scenario, the prior **52** are byte-unchanged, and `reassign` + `lane_drain` are present (the count re-pinned
  52 → 54 in both pinning tests — the additive-minor law).

INVEST — independent (the standing structural gate); testable by the honest-row run + `{emq}:version` + grammar
totality + the additive-minor conformance; encodes EMQ.4.1-INV1, EMQ.4.1-INV4. Priority: must · Size: 1 · Implements:
design §7, S-4 (the structural gate).

## Coverage

| Deliverable | Story |
|---|---|
| EMQ.4.1-D1 — Fork C surfaced + RULED PARK (D-1); lanes stay score-0 | US-FORK |
| EMQ.4.1-D2 — `Lanes.reassign/4` + `@greassign` (member `src`→`dst` at score 0, the row group rewritten, the ring re-shaped, the numeric-sentinel verdict, cross-queue not expressible) | US1, US2 |
| EMQ.4.1-D3 — the carried pause/resume/limit (byte-unchanged) over the shipped lane keys | US3 |
| EMQ.4.1-D4 — the re-aim discharged (`changePriority-7` → re-assignment; `getCountsPerPriority-4` → `Metrics.lane_depths/3`) | US3 |
| EMQ.4.1-D5 — `Lanes.drain/3` + `@gdrain` (the lane-scoped destructive drain, bounded blast radius) + the `reassign` + `lane_drain` conformance (additive minor; 52 → 54; the 5 shipped lane scripts byte-frozen) | US3, US4 |
| EMQ.4.1-D6 — the proof (the `:valkey` suites; the blast-radius mutation battery; HIGH-risk on the destructive delete; the honest no-≥100-loop posture; no regression; the boundary clean) | US5 |
| The Valkey structural gate (honest-row; `{emq}:version`; grammar totality; additive-minor conformance) | US-GATE |

Spec body: [`./emq.4.1.md`](emq.4.1.md) (authoritative) · Family: [`../emq.4.md`](../emq.4.md) (the contract + the carve + the forks) · Chapter stories:
[`../emq.4.stories.md`](../emq.4.stories.md) (US1 — the control plane).
