# EMQ.4.1 · agent brief — the fair-lanes control plane (the Mars build brief)

> The build brief for **emq.4.1** — the FIRST sub-rung of the groups-deepened family (the operator control plane).
> What Mars read first, the requirements traced to stories + invariants, the execution topology, and the agent
> stories (Directive + Acceptance gate). The spec **body** [`./emq.4.1.md`](emq.4.1.md) is authoritative; this brief
> and [`./emq.4.1.stories.md`](emq.4.1.stories.md) DERIVE from it — when a derived artifact disagrees with the body,
> the body wins.
>
> **⟢ AS-BUILT RECONCILE (post-build, pre-ship).** The rung SHIPPED — this brief is reconciled to what was built.
> The rulings: Fork C → **PARK** (D-1, lanes stay score-0); version → **additive minor** (D-1, `echomq:2.0.0`); the
> verb name/arity → **`reassign(conn, queue, job_id, dst_group)`, arity 4, src-derived** (D-2, ruled as recommended);
> **R3 → BUILD** (D-5, the lane-scoped destructive drain `drain/3` shipped too). The rung graded **HIGH** (the drain
> is a destructive at-rest delete; the verify was the **blast-radius mutation battery**, NOT the ≥100 loop — the drain
> mints no id/`TIME`/process). Two verbs shipped at `echo/apps/echo_mq/lib/echo_mq/lanes.ex`: `reassign/4` (`:262`) +
> `@greassign` (`:119`) and `drain/3` (`:319`) + `@gdrain` (`:294`); conformance **52 → 54** (`reassign` +
> `lane_drain`). The R-requirements below are kept as the build contract Mars built to; where a requirement was
> forward-tense, the as-built shape is noted inline.

## References (read first, in order)

1. **The sub-rung body** — [`./emq.4.1.md`](emq.4.1.md): the slice (§0), the Goal, the Scope (In/Out — note the
   honest **Out**: numeric per-job priority, a new lane key family, the intra-group priority dimension [Fork C,
   parked], a cross-queue move, any shipped-lane-script edit, any process/lease surface, the metronome/recovery/
   weighted rungs), the invariants (INV1–INV5). **Read it before any build story.**
2. **The family body** — [`../emq.4.md`](../emq.4.md): the deepening contract (§0 — the shipped basics as-built, what
   "deepened" means per axis), the NO-INVENT grounding (every delta rides a shipped key or re-aims a named v1
   capability), and the three surfaced forks (A/B at later rungs; **C** at this rung — park, the arm this triad is
   authored to).
3. **The design canon** — [`../../../emq.design.md`](../../../emq.design.md): **§10 seam 2 / §4 cluster 2** (the
   displaced groups family RULED → emq.4), **§4 row 4** (the *park, don't poll* law re-aimed to the fair-lanes rung),
   **S-1/§6** (the braced keyspace — the slot constraint; the closed `g:`-segment key registry), **S-6** (the A-1
   declared-keys law — the ARGV-slot-rooted derivation convention), **§5** (no new wire class — the kind law reuses
   `EMQKIND`), **§11.12** (the escalation protocol — a failing test is a finding, not a spec defect to paper over).
4. **The v1 capability reference (READ-ONLY — the FORM NOT to lift)** —
   [`../../emq.commands/features/groups/changePriority-7.md`](../../emq.commands/features/groups/changePriority-7.md):
   the v1 `changePriority-7.lua` roots its keys in **data values** (`jobKey = ARGV[2] .. jobId` from a data-value
   `jobId`; the global `prioritized` ZSET + the `pc` priority counter) — **NOT** lifted; its data-value rooting and
   its priority-score model are exactly what the re-aim retires. The forward equivalent of "matters more now" is
   **changing the job's lane** (this rung), never a per-job re-score.
   [`../../emq.commands/features/groups/getCountsPerPriority-4.md`](../../emq.commands/features/groups/getCountsPerPriority-4.md):
   re-aimed to the **shipped** `Metrics.lane_depths/3` (`@lane_counts` — `ZCARD base..'g:'..g..':pending'` per group,
   declared-base-rooted) — no new read.
   [`../../emq.commands/features/groups/addPrioritizedJob-9.md`](../../emq.commands/features/groups/addPrioritizedJob-9.md):
   SHIPPED, re-aimed — the **score-0-lane, no-new-key** discipline (`ZADD KEYS[2] 0 ARGV[1]`; fairness CONSTRUCTED by
   rotation, not a priority number). The reason lanes are score-0, and why Fork C's non-zero score would fight the
   ring.
5. **The as-built floor (the build TARGET + the A-1 precedent — RE-PROBE every anchor at the pre-build reconcile, the
   lag-1 law; the line numbers below are the Stage-1 (2026-06-18) reconcile's, re-confirm at B0 — a sibling rung
   could move them)** — `echo/apps/echo_mq/lib/echo_mq/lanes.ex`:
   - `@genqueue` (the **shape the move's ring re-add models on**: `lanes.ex:16-35`): stores the row with its group
     (`HSET KEYS[1] 'state','pending','attempts','0','payload',ARGV[2],'group',ARGV[3]` — **line 23**, the proof the
     `group` field lives on the row), `ZADD KEYS[2] 0 ARGV[1]` (score-0 lane entry), and the **ring-add guard** (`if
     not SISMEMBER paused & (no glimit or gactive < glimit) & not LPOS ring then RPUSH ring + LPUSH wake + LTRIM wake
     0 63` — lines 25-32). The move's `dst`-lane ring re-add is **this guard**, byte-modelled, not lifted from
     `@genqueue` (a NEW script — the existing one is byte-frozen).
   - `@gclaim` (the **ring rotation the move must NOT disturb**: `lanes.ex:37-61`): `LMOVE ring ring LEFT RIGHT` (the
     rotation), `ZPOPMIN lane` (the **score-0 head selection** — Fork C park is load-bearing here, line 41), the
     server-clock lease, the group returned beside the job, `LREM ring 0 g` when the lane is emptied/maxed (the
     **lane-drop-from-ring pattern** the move's `src`-empty branch models — lines 56-59). **BYTE-FROZEN (INV3).**
   - `@gpause`/`@gresume`/`@glimit` (`lanes.ex:63-99`) — the deepened control verbs' shipped basis; **BYTE-FROZEN
     (INV3)**. `pause/3`/`resume/3`/`limit/4` (`lanes.ex:146-190`) host wrappers + `depth/3` (`lanes.ex:193-195`).
   - `lane_key!/2` (`lanes.ex:197-203`): gates `EchoData.BrandedId.valid?/1`, **RAISES** on an ill-formed group —
     INV2. The src AND dst groups gate here before the wire.
   - The keyspace: `g:<group>:pending` / `ring` / `paused` / `glimit` / `gactive` / `wake` (all `Keyspace.queue_key/2`
     of the queue, one `{q}` slot).
   - `jobs.ex` — the **group-field-read consumers** the move's row rewrite must keep honest: `@complete` reads `HGET
     KEYS[2] 'group'` (**jobs.ex:182**) to find the lane + decrement `gactive[g]`; `@reap` reads `HGET jk 'group'`
     (**jobs.ex:349**); `@promote` reads it (**jobs.ex:320**). **The move MUST `HSET <row> 'group' dst`** so a later
     claim/complete/reap of the moved member touches `gactive[dst]`, not `gactive[src]` (the correctness finding —
     T-2). These scripts are NOT edited; the move writes the field they read.
   - `metrics.ex`: `lane_depths/3` + `@lane_counts` (`metrics.ex:279-310`) — the `getCountsPerPriority-4` re-aim
     target, **already shipped**; `lane_depth/3` (`metrics.ex:270-277`) delegates to `Lanes.depth`. **No new read
     unless Fork C lands (parked).**
   - `admin.ex`: `drain/3` + `@drain` (`admin.ex:84-122`) — the **slot-rooted derived-key A-1 precedent** for a
     lane-scoped drain: `base .. 'job:' .. id` from a declared `KEYS[1]` base, `DEL jk, jk..':logs'` per drained id,
     `DEL setkey`. A lane-scoped drain (if R3 adds one) is this pattern over `g:<g>:pending` instead of `pending`.
   - `conformance.ex`: `scenarios/0` (the scenario set the additive-minor law grows — **re-probe the live count** at
     the reconcile; do NOT hardcode). **Stage-1 reconcile (2026-06-18) confirmed the live count = 52** (`scenarios/0`
     52 keys ending `flow_grandchild_fail`; `conformance_run_test.exs:45` `{:ok, 52}`; `conformance_scenarios_test.exs`
     references `{:ok, 52}`; module doc "fifty-two"). Re-confirm at B0 (the lag-1 law).
6. **The shape model** — [`../../emq.3/emq.3.rungs/emq.3.1.md`](../../emq.3/emq.3.rungs/emq.3.1.md) /
   [`./emq.3.1.llms.md`](../../emq.3/emq.3.rungs/emq.3.1.llms.md) (the rung triad + brief shape — host-side row read,
   declared-keys move, the additive-minor mechanics). The program law: `.claude/skills/echo-mq-program.md` (the v2
   laws, the gate ladder, the conformance additive-minor law); the as-built map: `.claude/skills/echo-mq-surface.md`.
   The implementor skill: `.claude/skills/echo-mq-implementor.md` (the inline `Script.new/2` law, the declared-keys /
   branded / server-clock laws, the per-app gate ladder).

## Requirements (numbered; each traced back to a story, forward to an invariant)

> The forks are **ruled**: Fork C → **park** (lanes stay score-0); version → **additive minor**; the verb name/arity →
> **`reassign/4`, src-derived** (D-2); **R3 → BUILD** (the lane-scoped drain shipped — D-5).

1. **R1 — `EchoMQ.Lanes.reassign/4`, the host verb (BUILT — `lanes.ex:262`).** The host API moves a **pending** member
   from its current lane to a destination lane. **As built: `reassign(conn, queue, job_id, dst_group)` (arity 4,
   src-derived; the D-2 ruling, as Venus recommended)** — the source group is **not** passed: it is read from the job
   row's `group` field **inside the atomic script** (`HGET KEYS[1] 'group'`; the row is authoritative — `@genqueue`
   wrote it at `lanes.ex:23` — so src cannot mismatch). The verb gates the `job_id` at `Keyspace.job_key/2` and the
   `dst_group` at `Lanes.lane_key!/2` (each raises on an ill-formed id — INV2) **before** the wire, then calls
   `@greassign`. **A cross-queue destination is NOT expressible** at arity 4 (the `dst` lane is a `lane_key!` of
   *this* queue and src is derived from the row, so both lanes share the one `{q}` slot — atomic **by construction**,
   not a `{:error, :cross_queue}` case; the cross-queue posture is emq.3's). The verdict is a **numeric sentinel** the
   host maps to an atom (`{:ok, 1}→{:ok, :reassigned}`, `{:ok, 0}→{:ok, :noop}` dst==src, `{:ok, -1}→{:error,
   :not_found}` no row/no group, `{:ok, -2}→{:error, :not_pending}` claimed/in-flight) — the `@genqueue`/`@update_data`
   return idiom, no `error_reply`, so the closed wire-class registry stays unextended (INV1). (US1, US2 → INV1, INV2,
   INV5.)
2. **R2 — the inline atomic move script is one transition on one slot (declared keys, no clock).** Inline
   `Script.new/2` (a NEW attribute — e.g. `@greassign`; **never** `priv/`). Declares: `KEYS[1]` = the job row,
   `KEYS[2]` = the `src` lane `g:<src>:pending`, `KEYS[3]` = the `dst` lane `g:<dst>:pending`, `KEYS[4]` = `ring`,
   `KEYS[5]` = `paused`, `KEYS[6]` = `glimit`, `KEYS[7]` = `gactive`, `KEYS[8]` = `wake` (the `dst`-ring re-shape needs
   the same keys `@genqueue` declares — all one `{q}` slot). Body (the shape; the EXACT ring lines pinned at B0,
   WITHHELD here — pin, do not invent):
   - **Read + guard:** `local src = redis.call('HGET', KEYS[1], 'group')` (src derived from the row, arity 4); refuse
     a missing row / non-grouped job / a job not pending in `src` with a typed verdict that changes nothing (the
     `@complete` `if not att` short-circuit style).
   - **Move:** `ZREM KEYS[2] id`; **only if removed** (the member was pending in `src`), `ZADD KEYS[3] 0 id` (**score
     0** — Fork C park) and `HSET KEYS[1] 'group' dst` (**the correctness rewrite** — the later `@gclaim`/`@complete`/
     `@reap` read this field; T-2).
   - **Re-ring `dst`** (the `@genqueue` guard, byte-modelled into this new script): if `dst` is not paused
     (`SISMEMBER KEYS[5] dst == 0`), below its ceiling (`HGET KEYS[6] dst` vs `HGET KEYS[7] dst`), and not already in
     the ring (`not LPOS KEYS[4] dst`), then `RPUSH KEYS[4] dst` + `LPUSH KEYS[8] '1'` + `LTRIM KEYS[8] 0 63` (the wake
     for any parked consumer).
   - **Drop `src` from the ring** if its lane is now empty (`if ZCARD KEYS[2] == 0 then LREM KEYS[4] 0 src` — the
     `@gclaim` lane-drop pattern, lines 56-59).
   - **No `redis.call('TIME')`** — the move touches no lease (INV5 holds trivially; a grep of the new script for a
     host or server timestamp returns empty, no clock needed). Every key is a declared `KEYS[n]` (the A-1 lint passes;
     no key is read out of a data value — `src`/`dst` are an `HGET` of a declared key / a gated host arg). (US1, US2 →
     INV1, INV2, INV5.)
3. **R3 — the carried pause/resume/limit + the lane-scoped destructive drain (BUILT — R3 ruled BUILD, D-5).** The
   shipped `Lanes.{pause/3, resume/3, limit/4}` are **carried forward byte-unchanged** (they already re-shape the ring
   with a wake). **The lane-scoped drain** (the chapter body's "deepen … drain" axis) shipped as
   `Lanes.drain(conn, queue, group)` (arity 3 — `lanes.ex:319`) + `@gdrain` (`lanes.ex:294`), distinct from the
   queue-wide `Admin.drain/3`: it `ZRANGE`s **one lane's** `g:<group>:pending`, `DEL`s each drained member's row + its
   §6 `:logs` subkey (the `Admin.@drain` slot-rooted `base .. 'job:' .. id` pattern scoped to the lane), `DEL`s the
   lane set, and `LREM`s the group from the ring; an inline `Script.new/2`, declared-keys, no clock; answers
   `{:ok, n}`. **It is a destructive at-rest delete** — its blast radius is **bounded** to the target lane's pending
   rows + logs + set + the ring entry (NOT `active`/in-flight, NOT `gactive`, NOT `paused`/`glimit`, NOT a sibling
   lane, NOT the repeat registry) — which is what graded the rung **HIGH** and drove the **blast-radius mutation
   battery** verify (R7). It carries the `lane_drain` conformance scenario (R5). (US3 → INV1, INV2, INV5.)
4. **R4 — the re-aim discharged (no new surface).** `changePriority-7` → **lane re-assignment** (R1/R2 — no numeric
   priority; the v1 `prioritized` ZSET + `pc` counter do not return); `getCountsPerPriority-4` →
   **`Metrics.lane_depths/3`** (the **shipped** read — carried as the re-aim target, no new read surface while Fork C
   is parked). The discharge is **recorded** in the rung's record (the body's DoD + the post-build reconcile);
   the build adds **no new read** for the re-aim. (US3 → INV1.)
5. **R5 — additive-minor conformance (52 → 54, BUILT).** Registered `reassign` + `lane_drain` in `scenarios/0` **with
   their probes in the same change** (`conformance.ex:118`/`:119`); the prior **52** byte-unchanged (git-verified —
   name + contract + verdict body identical); the count re-pinned **52 → 54** in **both** pinning tests
   (`conformance_run_test.exs:47` `{:ok, 54}` + `conformance_scenarios_test.exs`) and their moduledocs ("fifty-two" →
   "fifty-four"). The `reassign` scenario: a grouped pending member on lane `src` → re-assign to `dst` → the member is
   in `g:<dst>:pending` (not `g:<src>:pending`), the row `group` = `dst`, a claim returns it with `group = dst`, and a
   completion charges `gactive[dst]` not the source's. The `lane_drain` scenario: draining one lane deletes its
   pending rows + logs + set + ring entry and returns the count, while a sibling lane + the in-flight `gactive`
   counter + the repeat registry are untouched (the blast-radius assertion). (US4 → INV4.)
6. **R6 — no new key family, no shipped-lane-script edit, no clock, no transport.** The re-assignment rides the
   shipped `g:`-segment keys + the declared job row; **`@gclaim`/`@genqueue`/`@gpause`/`@gresume`/`@glimit` are
   byte-identical to HEAD** (`grep redis.call` on those scripts in the lib diff = 0 — INV3); `EMQKIND`/`EMQSTALE`
   reused where a typed refusal applies (no new wire class); the control plane rides the shipped connector
   `eval`/`command` (no `echo_wire` change); `keyspace.ex`'s grammar is **unedited** (the `g:`-segment keys already
   compose). (US4, US-GATE → INV1, INV3.)
7. **R7 — the proof + the honest determinism posture (HIGH-risk, the destructive drain).** The `reassign` +
   `lane_drain` + the carried-control `:valkey` suites green per-app (`TMPDIR=/tmp`, `--include valkey`, **never**
   umbrella-wide). The rung graded **HIGH** on the **destructive at-rest delete** (`drain/3`/`@gdrain`), so the verify
   was the **blast-radius mutation battery**: the drain's **over-reach** (deleting beyond the target lane) and its
   **under-clean** (leaving a row/log/set/ring entry) were both caught. A **multi-seed sweep** + an **honest
   determinism-posture statement** — the **≥100-iteration loop is NOT run**, because emq.4.1 introduces **no** id-mint
   / process / lease hazard (both verbs mint no branded id, touch no `TIME`, start no process — the
   same-millisecond-mint hazard the loop guards does not exist; the loop would forge load, not catch the real
   destructive hazard). The prior emq.1 + emq.2.{1,2,3,4} + emq.3.{1,2,3,4,5} suites + `Conformance.run/2` pass
   **unchanged** (no regression — INV3); honest-row reporting (Valkey on 6390 the truth row). (US5 → INV3, INV5.)

## Execution topology

- **Runtime shape (as-built).** `EchoMQ.Lanes` gained **two** host-side verbs — `reassign/4` over the inline
  `@greassign` and `drain/3` over the inline `@gdrain` — each calling the **shipped `EchoWire` connector**
  (`Connector.eval`) the way the existing `Lanes` verbs do. **No new process** (each is one wire call). **No new
  lease** (no `TIME` in either). The control plane stands ON the as-built supervision tree unchanged.
- **The build-order task DAG (as-built).** (0) **pre-build reconcile** — re-probed `lanes.ex` (`@genqueue`/`@gclaim`/
  `@gpause`/`@gresume`/`@glimit` + `lane_key!/2` + the verb wrappers), the `jobs.ex` group-field readers
  (`@complete`/`@retry`/`@promote`/`@reap` — confirmed `HGET <row> 'group'` at `:182/259/320/349`), `metrics.ex`
  `lane_depths/3`, `admin.ex` `@drain`, `conformance.ex` count (52); the verb-name/arity D-2 ruled (`reassign/4`);
  R3 ruled BUILD. (1) the `@greassign` script + the `reassign/4` host verb (the per-id gate + the src-derive; a
  cross-queue dst not expressible at arity 4). (2) the `@gdrain` script + the `drain/3` host verb (R3 BUILD — the
  lane-scoped destructive drain). (3) the re-aim recording (no new read). (4) `reassign` + `lane_drain` in
  `conformance.ex` + the count re-pin (52 → 54) in both pin tests. (5) the `:valkey` suites + the blast-radius
  mutation battery + the multi-seed sweep. (6) the gate ladder.
- **The EXACT files touched (as-built).**
  - `echo/apps/echo_mq/lib/echo_mq/lanes.ex` — **EDIT** (the `reassign/4` host verb + the inline `@greassign` `:119`;
    the `drain/3` host verb + the inline `@gdrain` `:294`). The shipped `@gclaim`/`@genqueue`/`@gpause`/`@gresume`/
    `@glimit` **byte-frozen** (verified — only `+` `redis.call` additions in the two new scripts).
  - `echo/apps/echo_mq/lib/echo_mq/conformance.ex` — **EDIT** (the `reassign` + `lane_drain` scenarios `:118`/`:119`;
    the count re-pin).
  - `echo/apps/echo_mq/test/*_test.exs` — **NEW/EDIT** (the `:valkey` re-assignment proof — group-aware claim +
    completion charging `gactive[dst]` + the row group rewrite; the lane-drain proof — the bounded blast radius).
  - `echo/apps/echo_mq/test/conformance_scenarios_test.exs` + `conformance_run_test.exs` — **EDIT** (re-pin the count
    52 → 54).
  - `echo/apps/echo_mq/lib/echo_mq/metrics.ex` — **UNTOUCHED** (the `getCountsPerPriority-4` re-aim target
    `lane_depths/3` was already shipped; Fork C parked, no score dimension).
  - **Untouched:** `apps/echomq` (the capability reference); `echo_wire` (the control plane rides the shipped
    connector); `keyspace.ex`'s grammar (no new key type — the `g:`-segment keys compose); `jobs.ex` (the move WRITES
    the `group` field `jobs.ex` READS — confirmed no `jobs.ex` change needed).
- **The gate ladder (run before reporting — the program craft).** `asdf current erlang` (re-probe, do not hardcode; a
  switch implies a full rebuild); `redis-cli -p 6390 ping` → `PONG`; `TMPDIR=/tmp mix compile --warnings-as-errors` in
  `echo/apps/echo_mq`; `TMPDIR=/tmp mix test` in the app dir (the `:valkey` suites included for this wire rung:
  `--include valkey`); `EchoMQ.Conformance.run/2` over a live connection prints `{:ok, 54}`; the **blast-radius
  mutation battery** on `@gdrain` (the destructive verb's over-reach + under-clean); a **multi-seed sweep** (e.g.
  `for s in 0 1 2 3 4; do TMPDIR=/tmp mix test --include valkey --seed $s || break; done`) + the honest
  determinism-posture statement (**no ≥100 loop** — no id-mint/process/lease hazard; the rung grades HIGH on the
  destructive delete, not a mint hazard; state it explicitly). **Umbrella-wide `mix test` is BANNED.**
- **The boundary.** The diff stays inside `echo/apps/echo_mq`. A change reaching a third app is out of bounds. Agents
  run **NO git** (the Director commits by pathspec at the rung's close: `git commit -F <msg> -- <paths>`; never `git
  add -A`). The Operator commits out-of-band — watch for `AM`-status files and exclude them.

## Agent stories (Directive + Acceptance gate; stated as contracts)

> Each surface is a contract (precondition / postcondition / invariant) so the Operator and Apollo accept at the
> boundary, not by re-reading the diff. The forks are **ruled** (C park / additive minor); the verb-name/arity D-2
> ruling is confirmed before AS1 builds.

- **AS-FORK — the fork gate (FIRST).**
  *Directive:* confirm the Director's rulings are recorded — Fork C → **park** (lanes score-0; no non-zero lane score
  threaded) and version → **additive minor** (`echomq:2.0.0`, no fence code); confirm the verb-name/arity D-2 ruling
  (`reassign/4` recommended). If the verb/arity is unruled, STOP and report (R1's layout depends on it).
  *Precondition:* the body's surfaced Fork C + the Director's bootstrap rulings. *Postcondition:* C park + additive
  minor + the verb/arity recorded BEFORE any build artifact. *Invariant:* the build proceeds on the ruled arms (lanes
  score-0 — INV1).
  *Acceptance gate:* the ledger records the rulings; the build's lane-score posture is score-0 (park); the script's
  key/ARGV layout matches the ruled verb/arity.

- **AS1 — `EchoMQ.Lanes.reassign/4` + the inline `@greassign` (D2 — the headline; BUILT).**
  *Directive:* the host verb `reassign/4` gates the `job_id` at `Keyspace.job_key/2` + the `dst_group` at
  `Lanes.lane_key!/2`; the inline `@greassign` reads+guards the row's `group` = src (`HGET KEYS[1] 'group'`), `ZREM`s
  the src lane; on removal `ZADD`s the dst lane **score 0** + `HSET <row> 'group' dst`; re-rings dst by the `@genqueue`
  guard + wake; drops src from the ring if emptied; **no `TIME`**. *Precondition:* a grouped member pending in `src`,
  a valid branded `dst` in this queue. *Postcondition:* the member is in `g:<dst>:pending` (not `g:<src>:pending`),
  the row `group` = `dst`, the ring reflects both lanes; a claimed member is left untouched (`{:error, :not_pending}`);
  dst==src is `{:ok, :noop}`. *Invariant:* every key declared/grammar-rooted on one `{q}` slot (INV5); every gated id
  host-side (INV2); a cross-queue dst **not expressible** at arity 4 (atomic by construction); no new key family /
  no numeric priority / no new wire class — numeric sentinels, not `error_reply` (INV1); no clock (INV5); the 5
  shipped lane scripts byte-frozen (INV3).
  *Acceptance gate:* the `reassign` `:valkey` scenario — enqueue a grouped member on `src`; re-assign to `dst`; assert
  the member in `g:<dst>:pending` and absent from `g:<src>:pending`, the row `group` = `dst`; `Lanes.claim/3` returns
  it with `group = dst`; a completion charges `gactive[dst]` not the source's; `Apollo (if engaged) re-verifies INV3 +
  the declared-keys grep + the byte-frozen 5 lane scripts`.

- **AS2 — the lane-scoped destructive drain + the carried control verbs + the re-aim (D3 + D4 + D5; R3 BUILD).**
  *Directive:* carry the shipped `Lanes.{pause,resume,limit}` forward byte-unchanged (they already re-shape the ring
  with a wake); build the **lane-scoped drain** `drain/3` + `@gdrain` (R3 ruled BUILD — a NEW verb over one lane's
  `g:<g>:pending`, the `Admin.@drain` slot-rooted `base..'job:'..id` pattern scoped to the lane: `ZRANGE` → `DEL` rows
  + logs → `DEL` lane set → `LREM` ring; declared-keys, no clock; `{:ok, n}`); record the re-aim discharge
  (`changePriority-7` → re-assignment, `getCountsPerPriority-4` → `Metrics.lane_depths/3` — **no new read**).
  *Precondition:* the shipped control verbs + `lane_depths/3` as-built; a lane with pending members.
  *Postcondition:* the drain empties exactly its lane (rows + logs + set + ring entry), leaving `active`/`gactive`/
  `paused`/`glimit`/sibling-lanes/repeat untouched; `lane_depths/3` answers per-lane backlog; the re-aim recorded.
  *Invariant:* rides shipped keys (INV1); branded group ids (INV2); the drain is declared-keys + bounded (INV5) — a
  destructive at-rest delete, the HIGH-risk surface.
  *Acceptance gate:* the `lane_drain` `:valkey` scenario (one lane emptied — rows + logs + set + ring entry gone — a
  sibling lane + `gactive` + the repeat registry intact, the count returned); a `lane_depths/3` read returns per-lane
  depths; the re-aim discharge recorded in the rung's record.

- **AS3 — additive-minor conformance + the proof (D5 + D6; HIGH-risk).**
  *Directive:* register `reassign` + `lane_drain` in `scenarios/0` with probes; re-pin the count **52 → 54** in both
  pin tests + their moduledocs ("fifty-two" → "fifty-four"); run the gate ladder; run the **blast-radius mutation
  battery** on `@gdrain` (the destructive verb's over-reach + under-clean) + a **multi-seed sweep** and **state the
  determinism posture explicitly** (HIGH on the destructive delete — no id-mint/process/lease hazard, **no ≥100
  loop**); confirm no regression on the prior suites; confirm the boundary grep is empty. *Precondition:* the prior
  **52** byte-unchanged; the build complete. *Postcondition:* the two scenarios registered + probed; the count is 54;
  the prior set git-verified byte-unchanged; the `:valkey` suites green; the blast-radius battery + the multi-seed
  sweep green; the posture stated; the prior suites unchanged. *Invariant:* additive minor (INV4); the prior set + the
  5 lane scripts byte-unchanged (INV3); the blast-radius battery (not the ≥100 loop) is the honest proof for a
  destructive HIGH rung (no false-green).
  *Acceptance gate:* `Conformance.run/2` prints `{:ok, 54}`; both pin tests assert 54; the prior 52 git-verified
  byte-unchanged; the 5 shipped lane scripts `grep redis.call` diff = 0; the emq.1/2/3 suites unchanged; the boundary
  grep empty; the determinism posture recorded (HIGH on the destructive delete, blast-radius battery, no ≥100 loop).

## Propagation clause

No gendered pronouns for agents; no perceptual or interior-state verbs ("sees" / "wants" / "feels") for agents or
software (components read, compute, refuse, return); no first-person narration ("we" / "I think"). Forward tense for
the unbuilt surface ("emq.4.1 builds …"). Every reference is a real `echo_mq`/`echo_wire` module, a real v1 command
record (READ-ONLY, the form NOT lifted), or a design §. The v1 `changePriority-7`/`getCountsPerPriority-4` are
**capability re-aim records**, never things migrated from. The inline `Script.new/2` law (no `priv/`). NO git.
