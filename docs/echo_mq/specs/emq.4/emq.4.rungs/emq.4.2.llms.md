# EMQ.4.2 · agent brief — group-aware recovery (the Mars build brief)

> The build brief for **emq.4.2** — the SECOND sub-rung of the groups-deepened family (group-aware recovery: a
> group-scoped stalled-sweep). What Mars reads first, the requirements traced to stories + invariants, the execution
> topology, and the agent stories (Directive + Acceptance gate). The spec **body** [`./emq.4.2.md`](emq.4.2.md) is
> authoritative; this brief and [`./emq.4.2.stories.md`](emq.4.2.stories.md) DERIVE from it — when a derived artifact
> disagrees with the body, the body wins.
>
> **⟢ FORWARD-TENSE (pre-build, the strawman brief).** Every emq.4.2 surface is **PROPOSED, NOT shipped** — written
> "emq.4.2 builds …". The Venus-2 reconcile (Stage-0, 2026-06-18) is recorded in the run ledger
> [`../../progress/emq-4-2.progress.md`](../../progress/emq-4-2.progress.md) (T-2 reconcile, V-1 build-choice).
> **Two rulings the Director makes before AS1 builds:** (1) the **build choice** — **additive-beside (Arm A)** is the
> reconcile's recommendation (a NEW inline script + NEW host verb; `@reap` + `@sweep_stalled` byte-frozen; stays
> NORMAL-risk); Arm B (edit a shipped sweep) re-grades HIGH + mandates Apollo — the Director rules the gate; (2) the
> **host verb name/arity** — **`reap_group(conn, queue, group)`, arity 3** is the candidate (the `drain/3` precedent);
> confirm or re-pin before R1 builds. **The pre-build reconcile (B0) re-probes every anchor below** — the line numbers
> are the Stage-0 reconcile's, re-confirm at B0 (the lag-1 law; a sibling rung could move them).

## References (read first, in order)

1. **The sub-rung body** — [`./emq.4.2.md`](emq.4.2.md): the slice (§0), the Goal, the Scope (In/Out — note the honest
   **Out**: any change to the non-group recovery path, a host clock on the lease, a new lane key family, the dead-letter
   policy change, the control plane [emq.4.1], the metronome [emq.4.3], the weighted/deficit rotation [emq.4.4]), the
   build choice (additive-beside vs an edit — the reconcile's call), the invariants (INV1–INV5). **Read it before any
   build story.**
2. **The family body** — [`../emq.4.md`](../emq.4.md): the deepening contract (§0 — the shipped basics as-built, what
   "deepened" means per axis — emq.4.2 is the **group-aware recovery** axis), the NO-INVENT grounding (every delta
   rides a shipped key or re-aims a named v1 capability), the per-rung risk (emq.4.2 NORMAL), and the surfaced forks
   (A/B/C — none blocks emq.4.2; the recovery shape is settled by the shipped pattern).
3. **The design canon** — [`../../../emq.design.md`](../../../emq.design.md): **§10 seam 2 / §4 cluster 2** (the
   displaced groups family RULED → emq.4), **§4** (the **server-clock law** — `TIME` in any lease-touching transition
   script; the reaper/stall sweep precedent), **S-1/§6** (the braced keyspace — the slot constraint; the closed
   `g:`-segment key registry), **S-6** (the A-1 declared-keys law — every Lua key in `KEYS[]` or derived from a declared
   `KEYS[n]` root), **§5** (no new wire class — a count return, no `error_reply`), **§11.12** (the escalation protocol —
   a failing test is a finding, not a spec defect to paper over).
4. **The v1 capability reference (READ-ONLY — the FORM NOT to lift)** — `echo/apps/echomq` `stalled_checker` +
   `moveStalledJobsToWait` (named in [`.claude/skills/echo-mq-surface.md`](../../../../../.claude/skills/echo-mq-surface.md)):
   the v1 sweep roots its keys in a **9-key LIST shape** and a caller clock — **NOT** lifted; its data-value rooting and
   its host clock are exactly what the v2 form retires. The v2 group-scoped recovery is **declared-keys + lane recovery
   + server clock**, modelled on the **shipped** `@reap` group branch, never the v1 checker.
5. **The as-built floor (the build TARGET + the A-1 precedent — RE-PROBE every anchor at the pre-build reconcile, the
   lag-1 law; the line numbers below are the Stage-0 (2026-06-18) reconcile's, re-confirm at B0 — a sibling rung could
   move them)** — `echo/apps/echo_mq/lib/echo_mq/`:
   - **`jobs.ex` `@reap` (the EXACT mechanism the new sweep models on — `jobs.ex:341-369`): BYTE-FROZEN (INV1).** Its
     group branch is the template: `local t = redis.call('TIME')` + `local now = t[1]*1000 + math.floor(t[2]/1000)`
     (**the server clock — INV2**); `redis.call('ZRANGEBYSCORE', KEYS[1], '-inf', now, 'LIMIT', 0, 100)` (the
     expired-lease window over `active`); per expired id — `ZREM active id`; `local jk = p..'job:'..id`; `local g =
     redis.call('HGET', jk, 'group')` (**the group read — the filter point**); **if `g`** then `HINCRBY p..'gactive' g
     -1` (`HDEL` at `<=0`), `local lane = p..'g:'..g..':pending'`, `ZADD lane 0 id`, and the **re-ring guard**
     (`if SISMEMBER p..'paused' g == 0` and `(not glimit or act < glimit)` and `not LPOS p..'ring' g` then `RPUSH
     p..'ring' g` + `LPUSH p..'wake' '1'` + `LTRIM p..'wake' 0 63`); `HSET jk 'state' 'pending'`. The new
     `@greap_group` is **this group branch byte-modelled into a NEW script with a `g == ARGV[group]` filter** added —
     NOT a lift of `@reap` (it is byte-frozen). `reap/2` host verb (`jobs.ex:719`): `KEYS=[active, pending]`, `ARGV=
     [Keyspace.queue_key(queue, "")]`.
   - **`stalled.ex` `@sweep_stalled` + `Stalled.check/3` (the second group-aware recovery surface — `stalled.ex:50-95`,
     `:106-129`): BYTE-FROZEN (INV1).** The count-thresholded sweep: `KEYS[1]`=active / `KEYS[2]`=pending / `KEYS[3]`=
     dead, `ARGV[1]`=base / `[2]`=max_stalled / `[3]`=limit; server clock; a grouped recovery into its lane at
     `stalled.ex:76-85`, mirroring the reaper's group branch + the same re-ring guard. This is **byte-frozen** under
     Arm A (the new sweep does **not** edit it). It is the **proof the group-recovery branch is already duplicated**
     across two scripts — a third additive copy in `@greap_group` is consistent with the as-built pattern (V-1
     steward).
   - **`lanes.ex` (where the new verb lives — beside `drain/3`/`reassign/4`):**
     - `lane_key!/2` (`lanes.ex:337`, **`defp`**): `if EchoData.BrandedId.valid?(group) then Keyspace.queue_key(queue,
       "g:"<>group<>":pending") else raise ArgumentError`. **The branded-group gate — INV4.** The new `reap_group/3`
       gates `group` here BEFORE the wire (the `drain/3` pattern, `lanes.ex:322`).
     - `drain/3` (`lanes.ex:319`) + `@gdrain` (`lanes.ex:294`) — **the host-verb structural precedent**: `KEYS=
       [Keyspace.queue_key(queue,""), lane_key!(queue,group), Keyspace.queue_key(queue,"ring")]`, `ARGV=[group]`;
       the script declares `KEYS[1]`=base, derives `jk = base..'job:'..id` (the **KEYS-rooted** A-1 form), no clock,
       `{:ok, n}`. The new `reap_group/3` is **this host-verb shape** with `active` added to `KEYS[]` and the server
       clock inside the script.
     - `@genqueue` (`lanes.ex:16-35`) — the **ring-add guard shape** (`RPUSH ring` + `LPUSH wake` + `LTRIM wake 0 63`
       under the paused/ceiling/`LPOS` guard) the new sweep's re-ring branch models (already identical to `@reap`'s).
       **BYTE-FROZEN (INV1/INV3).** `@gclaim`/`@gpause`/`@gresume`/`@glimit`/`@greassign` — **BYTE-FROZEN (INV1/INV3).**
     - The keyspace: `g:<group>:pending` / `ring` / `paused` / `glimit` / `gactive` / `wake` (all `Keyspace.queue_key/2`
       of the queue, one `{q}` slot); `active` = `Keyspace.queue_key(queue, "active")`.
   - **`jobs.ex` — the `group`-field-read consumers the sweep must keep honest (NOT edited; the sweep does NOT rewrite
     `group`):** `@complete` reads `HGET <row> 'group'` (`jobs.ex:182`), `@retry` (`:259`), `@promote` (`:320`),
     `@reap` (`:349`); `stalled.ex` reads it (`:62`). **The sweep is a PURE READER of `group`** (it reads to filter
     `g == target` + to find the lane; it never `HSET`s `group` — only emq.4.1's `reassign` does that). So **no
     read-site of `group` drifts** — the move returns the member to **its own** lane, the `group` value unchanged. The
     write→read cycle the scenario MUST prove is **`gactive`**: the sweep `HINCRBY gactive g -1` on recovery, so a later
     claim/complete of the recovered member touches an honest `gactive[g]` (the same accounting `@reap` keeps).
   - **`admin.ex`: `drain/3` + `@drain` (`admin.ex:84-122`)** — the queue-wide destructive drain (NOT a recovery; named
     only to disambiguate: `Lanes.drain/3` is the lane-scoped delete, `reap_group/3` is the lane-scoped **recover**;
     different ops, do not conflate).
   - **`conformance.ex`: `scenarios/0`** (the scenario set the additive-minor law grows — **re-probe the live count** at
     the reconcile; do NOT hardcode). **Stage-0 reconcile (2026-06-18) confirmed the live count = 54** (`scenarios/0`
     54 keys ending `flow_grandchild_fail`; the emq.4.1 entries `reassign` + `lane_drain` present at `:118`/`:119`;
     `conformance_run_test.exs:47` `{:ok, 54}`; `conformance_scenarios_test.exs` `@run_order` 54 names; both moduledocs
     "fifty-four"). **The seed's "52" is STALE (pre-emq.4.1); the floor is 54 → 55.** Re-confirm at B0 (the lag-1 law).
6. **The shape model** — [`./emq.4.1.llms.md`](emq.4.1.llms.md) (the sibling rung's brief — the host-verb-over-inline-
   script shape, the `@gdrain`/`reassign` precedent, the additive-minor mechanics, the honest determinism posture for a
   lease-touching/mint-free rung). The program law: `.claude/skills/echo-mq-program.md` (the v2 laws, the gate ladder,
   the conformance additive-minor law); the as-built map: `.claude/skills/echo-mq-surface.md`. The implementor skill:
   `.claude/skills/echo-mq-implementor/SKILL.md` (the inline `Script.new/2` law — never `priv/`; the declared-keys /
   branded / server-clock laws; the per-app gate ladder).

## Requirements (numbered; each traced back to a story, forward to an invariant)

> The build choice is the Director's ruling: **Arm A (additive-beside)** is the reconcile's recommendation — a NEW
> inline script + NEW host verb, `@reap` + `@sweep_stalled` byte-frozen, NORMAL-risk. The requirements below are written
> to Arm A; if the Director rules Arm B (edit a shipped sweep), R1/R2 re-scope to a `:group` ARGV filter threaded into
> the shipped script (NORMAL→HIGH + Apollo + a byte-diff of the unedited non-group branch) — STOP and re-confirm before
> building. The host verb name/arity (`reap_group/3`) is confirmed before R1.

1. **R1 — `EchoMQ.Lanes.reap_group/3`, the host verb (emq.4.2 builds — proposed `lanes.ex`, beside `drain/3`).** The
   host API recovers the **expired-lease** members of **one named group**. **Proposed: `reap_group(conn, queue, group)`
   (arity 3 — the `drain/3` precedent)** — the group is gated at `Lanes.lane_key!/2` (raises on an ill-formed branded
   id — INV4) **before** the wire, then calls `@greap_group` with `KEYS = [Keyspace.queue_key(queue, "active"),
   Keyspace.queue_key(queue, "")]` (the `active` set + the declared queue-base root) and `ARGV = [group]` (the target
   group; optionally a `:limit`, default 100, matching the shipped reaper's `LIMIT 0 100`). The verdict is a **count**
   the host returns as `{:ok, n}` (the number recovered) — no `error_reply`, so the closed wire-class registry stays
   unextended (INV3). A well-formed group with no expired members answers `{:ok, 0}`. (US1, US2 → INV2, INV3, INV4.)
2. **R2 — the inline group-scoped sweep script (declared keys, server clock, the `@reap` group branch + a filter).**
   Inline `Script.new(:greap_group, …)` (a NEW attribute; **never** `priv/`). Declares: `KEYS[1]` = `active`, `KEYS[2]`
   = the queue base (`emq:{q}:`) — every lane/`gactive`/`ring`/`wake`/`paused`/`glimit` key and the job row derive from
   `KEYS[2]` by the registered grammar (the `@gdrain` KEYS-rooted A-1 form). Body (the shape; the EXACT lines pinned at
   B0 against the re-probed `@reap`, WITHHELD here — pin, do not invent — **byte-model the `@reap` group branch, do not
   lift it**):
   - **Server clock (INV2):** `local t = redis.call('TIME')`; `local now = t[1]*1000 + math.floor(t[2]/1000)` — exactly
     the shipped `@reap`/`@sweep_stalled` clock; **no host timestamp crosses the lease** (a grep of the new script for a
     host-supplied time returns empty).
   - **The expired-lease window:** `local exp = redis.call('ZRANGEBYSCORE', KEYS[1], '-inf', now, 'LIMIT', 0, lim)` (the
     `@reap` window over `active`).
   - **The group-scoping filter (the delta):** per expired `id` — `local jk = KEYS[2]..'job:'..id`; `local g =
     redis.call('HGET', jk, 'group')`; **`if g == ARGV[1] then`** (recover **only** this group's members) `ZREM KEYS[1]
     id`; `HINCRBY KEYS[2]..'gactive' g -1` (`HDEL` at `<=0`); `local lane = KEYS[2]..'g:'..g..':pending'`; `ZADD lane 0
     id`; the **re-ring guard** (`if SISMEMBER KEYS[2]..'paused' g == 0` and `(not glimit or act < glimit)` and `not
     LPOS KEYS[2]..'ring' g` then `RPUSH KEYS[2]..'ring' g` + `LPUSH KEYS[2]..'wake' '1'` + `LTRIM KEYS[2]..'wake' 0
     63`); `HSET jk 'state' 'pending'`; count it. A member whose `g ≠ ARGV[1]` is **left in `active`** (no `ZREM`, no
     recover) — the group-scoping (US1's headline; the proof the filter fires).
   - **No `HSET <row> 'group'`** — the sweep returns the member to **its own** lane; `group` is a **pure read** (the
     reconcile finding — no read-site of `group` drifts).
   - Every key is a declared `KEYS[n]` or grammar-rooted from `KEYS[2]` (the A-1 lint passes; no key is read out of a
     data value — `g` is an `HGET` of a `KEYS[2]`-derived row, `ARGV[1]` is the gated host group). (US1, US2 → INV2,
     INV3, INV4.)
3. **R3 — the non-group recovery path is byte-unchanged (INV1).** Under Arm A, the shipped per-job `@reap` (`jobs.ex`)
   and the queue-wide `@sweep_stalled` (`stalled.ex`) are **byte-identical to HEAD** (`grep redis.call` on those scripts
   in the lib diff = 0); a job with **no group** flows through them exactly as before; the group-scoped sweep is reached
   **only** through the new `reap_group/3` verb. The `Stalled.check/3` queue-wide sweep and the consumer-loop reaper are
   **untouched**. (US3 → INV1.)
4. **R5 — additive-minor conformance (54 → 55).** Register `reap_group` in `scenarios/0` **with its probe in the same
   change** (`conformance.ex`); the prior **54** byte-unchanged (git-verified — name + contract + verdict body
   identical); the count re-pinned **54 → 55** in **both** pinning tests (`conformance_run_test.exs` `{:ok, 55}` +
   `conformance_scenarios_test.exs` `@run_order` + the assertion) and their moduledocs ("fifty-four" → "fifty-five").
   **The `reap_group` scenario (the group-scoping proof — must defeat a no-op):** enqueue **two** grouped jobs in
   **distinct** branded groups `g` and `h`; claim both with a **short lease** (e.g. 30ms); sleep past expiry (e.g.
   80ms); call `reap_group(conn, q, g)`; assert **(a)** `g`'s member is in `g:<g>:pending` (`ZSCORE` present) and absent
   from `active` (`ZSCORE active <id_g>` nil) and absent from flat `pending`; **(b)** `h`'s member is **still in
   `active`** (`ZSCORE active <id_h>` present) — the group-scoping; **(c)** `gactive[g]` decremented (the in-flight
   accounting honest); **(d)** a `Lanes.claim/3` returns `g`'s member with `group = g` and attempts incremented, and a
   completion charges `gactive[g]`. Mirror the **shipped `stalled_group` scenario** (`conformance.ex:1007`) as the
   precedent for the enqueue/claim/expire/recover/re-claim shape, extended to TWO groups for the scoping assertion.
   (US1, US3 → INV4, INV5.)
5. **R6 — no new key family, no shipped-recovery-script edit, no host clock, no transport.** The sweep rides the shipped
   `g:`-segment keys + `active` + the declared job row; **`@reap`/`@sweep_stalled`/`@gclaim`/`@genqueue`/`@gpause`/
   `@gresume`/`@glimit`/`@greassign`/`@gdrain` are byte-identical to HEAD** (`grep redis.call` on those scripts in the
   lib diff = 0 — INV1/INV3); the server clock only (no host clock — INV2); the sweep rides the shipped connector
   `eval` (no `echo_wire` change); `keyspace.ex`'s grammar is **unedited** (the `g:`-segment keys + `active` already
   compose — INV3). (US3, US-GATE → INV1, INV3.)
6. **R7 — the proof + the honest determinism posture (NORMAL-risk).** The `reap_group` + the group-scoped recovery
   `:valkey` suites green per-app (`TMPDIR=/tmp`, `--include valkey`, **never** umbrella-wide). The rung grades
   **NORMAL** — a NEW additive script, no shipped-recovery-script edit, **no destructive at-rest op** (the sweep
   **moves** a lease back to a lane, it does **not** delete — distinct from emq.4.1's `drain/3`), no new process/lease
   surface. The proof is a **multi-seed sweep** + an **honest determinism-posture statement**: the **≥100-iteration loop
   is NOT run** — the sweep touches a lease (reads `TIME`) but **mints no branded id**, **starts no process**, and does
   **not** contend on a same-millisecond mint (the only hazard the ≥100 loop guards), so the loop would forge load
   rather than catch a real hazard; state it explicitly. The prior emq.1 + emq.2.{1,2,3,4} + emq.3.{1,2,3,4,5} + emq.4.1
   suites + `Conformance.run/2` pass **unchanged** (no regression — INV1); honest-row reporting (Valkey on 6390 the
   truth row). **The version climbs in lockstep `2.4.1 → 2.4.2`** — both the `mix.exs` label AND the connector
   `@wire_version` / `{emq}:version` fence move together per rung (D-3, the reopened Fork-2: the single-owner wire
   makes per-rung climbing safe; the connector fence **logic** is frozen, only the constant moves; the `:fence`
   conformance scenario is version-agnostic). (US4 → INV1, INV2.)

## Execution topology

- **Runtime shape (emq.4.2 builds).** `EchoMQ.Lanes` gains **one** host-side verb — `reap_group/3` over the inline
  `@greap_group` — calling the **shipped `EchoWire` connector** (`Connector.eval`) the way the existing `Lanes` verbs
  do. **No new process** (it is one wire call). **No new lease** (it reads `TIME` to compute expiry but mints no new
  lease — it returns a lapsed one to its lane). The recovery stands ON the as-built supervision tree unchanged.
- **The build-order task DAG (emq.4.2 builds).** (0) **pre-build reconcile (B0)** — re-probe `jobs.ex` `@reap`
  (the group branch + the server clock + the re-ring guard), `stalled.ex` `@sweep_stalled`/`check/3`, `lanes.ex`
  (`lane_key!/2` + `drain/3`/`@gdrain` the host-verb precedent + the byte-frozen lane scripts), the `jobs.ex`
  `group`-field readers (`@complete`/`@retry`/`@promote`/`@reap` — `HGET <row> 'group'` at `:182/259/320/349`),
  `conformance.ex` count (**54**, re-confirm); **confirm the build choice (Arm A) + the verb name/arity (`reap_group/3`)
  ruled.** (1) the `@greap_group` script (the `@reap` group branch byte-modelled + the `g == ARGV[group]` filter + the
  server clock) + the `reap_group/3` host verb (the `lane_key!/2` gate + the `KEYS=[active, base]` layout). (2)
  `reap_group` in `conformance.ex` (the two-group scoping scenario) + the count re-pin (54 → 55) in both pin tests +
  their moduledocs. (3) the `:valkey` recovery suite (group-scoping + `gactive` coherence + the re-claim). (4) the
  version bump `mix.exs` 2.4.1 → 2.4.2. (5) the gate ladder + the multi-seed sweep + the honest determinism statement.
- **The EXACT files touched (emq.4.2 builds).**
  - `echo/apps/echo_mq/lib/echo_mq/lanes.ex` — **EDIT** (the `reap_group/3` host verb + the inline `@greap_group`
    script, beside `drain/3`/`@gdrain`). The shipped `@gclaim`/`@genqueue`/`@gpause`/`@gresume`/`@glimit`/`@greassign`/
    `@gdrain` **byte-frozen** (only `+` `redis.call` additions in the new `@greap_group`).
  - `echo/apps/echo_mq/lib/echo_mq/conformance.ex` — **EDIT** (the `reap_group` scenario + the count re-pin 54 → 55).
  - `echo/apps/echo_mq/test/*_test.exs` — **NEW/EDIT** (the `:valkey` group-scoped recovery proof — two groups lapse,
    one recovered into its lane, the sibling left in `active`, `gactive` coherent, the re-claim).
  - `echo/apps/echo_mq/test/conformance_scenarios_test.exs` + `conformance_run_test.exs` — **EDIT** (re-pin the count
    54 → 55).
  - `echo/apps/echo_mq/mix.exs` — **EDIT** (version 2.4.1 → 2.4.2, additive minor).
  - **Untouched:** `jobs.ex` (`@reap` byte-frozen — INV1; the sweep WRITES no field `jobs.ex` reads — `group` is a pure
    read, `gactive` is the same counter `@reap` keeps); `stalled.ex` (`@sweep_stalled` byte-frozen — INV1); `apps/echomq`
    (the capability reference); `echo_wire` (the sweep rides the shipped connector); `keyspace.ex`'s grammar (no new
    key type — the `g:`-segment keys + `active` compose).
- **The gate ladder (run before reporting — the program craft).** `asdf current erlang` (re-probe from the app dir, do
  not hardcode; a switch implies a full rebuild); `redis-cli -p 6390 ping` → `PONG`; `TMPDIR=/tmp mix compile
  --warnings-as-errors` in `echo/apps/echo_mq`; `TMPDIR=/tmp mix test` in the app dir (the `:valkey` suites included for
  this wire rung: `--include valkey`); `EchoMQ.Conformance.run/2` over a live connection prints `{:ok, 55}`; the
  **byte-freeze grep** on the shipped recovery + lane scripts (`@reap`/`@sweep_stalled`/`@gclaim`/`@genqueue`/`@gpause`/
  `@gresume`/`@glimit`/`@greassign`/`@gdrain` `grep redis.call` diff = 0); a **multi-seed sweep** (e.g.
  `for s in 0 1 2 3 4; do TMPDIR=/tmp mix test --include valkey --seed $s || break; done`) + the honest
  determinism-posture statement (**no ≥100 loop** — the sweep touches a lease but mints no id and starts no process;
  state it explicitly). **Umbrella-wide `mix test` is BANNED.**
- **The boundary.** The diff stays inside `echo/apps/echo_mq`. A change reaching a third app is out of bounds. Agents
  run **NO git** (the Director commits by pathspec at the rung's close: `git commit -F <msg> -- <paths>`; never `git add
  -A`). The Operator commits out-of-band — watch for `AM`-status files and exclude them.

## Agent stories (Directive + Acceptance gate; stated as contracts)

> Each surface is a contract (precondition / postcondition / invariant) so the Operator and Apollo accept at the
> boundary, not by re-reading the diff. The build choice (Arm A) + the verb name/arity (`reap_group/3`) are confirmed
> before AS1 builds.

- **AS-CHOICE — the build-choice gate (FIRST).**
  *Directive:* confirm the Director's rulings are recorded — the **build choice** = **Arm A (additive-beside)** (a NEW
  inline `@greap_group` + a NEW `reap_group/3` verb; `@reap` + `@sweep_stalled` byte-frozen; NORMAL-risk, no Apollo
  mandate) and the **verb name/arity** = `reap_group(conn, queue, group)` (arity 3). If the Director rules **Arm B**
  (edit a shipped sweep), STOP — R1/R2 re-scope to a `:group` ARGV filter threaded into the shipped `@reap`/
  `@sweep_stalled` (the rung re-grades NORMAL→HIGH, Apollo mandatory, a byte-diff of the unedited non-group branch
  required). *Precondition:* the body's flagged build choice + the reconcile's Arm-A recommendation (ledger V-1).
  *Postcondition:* the build choice + the verb/arity recorded BEFORE any build artifact. *Invariant:* the build proceeds
  on the ruled arm (Arm A → `@reap`/`@sweep_stalled` byte-frozen — INV1).
  *Acceptance gate:* the ledger records the rulings; the build's recovery-script posture matches the ruled arm (Arm A →
  the new sweep is a separate `@greap_group`, the shipped recovery scripts byte-frozen).

- **AS1 — `EchoMQ.Lanes.reap_group/3` + the inline `@greap_group` (D2 — the headline; emq.4.2 builds).**
  *Directive:* the host verb `reap_group/3` gates the `group` at `Lanes.lane_key!/2` (raises on an ill-formed branded id
  — INV4) before the wire; the inline `@greap_group` reads the **server clock** (`redis.call('TIME')` — INV2), windows
  the expired leases over `active` (`ZRANGEBYSCORE active -inf now`), and for **each** expired id whose row `group ==
  ARGV[1]` — `ZREM`s `active`, `HINCRBY gactive g -1` (`HDEL` at `<=0`), `ZADD`s `g:<g>:pending` **score 0**, re-rings
  `g` by the shipped `@reap` guard (`SISMEMBER paused == 0` + `gactive < glimit` + `not LPOS ring` → `RPUSH ring` +
  `LPUSH wake` + `LTRIM wake 0 63`), and `HSET`s `state pending`; a member whose `g ≠ ARGV[1]` is **left in `active`**;
  **no `TIME` host clock, no `HSET 'group'`** (the member returns to its own lane, `group` a pure read).
  *Precondition:* a named branded group `g` with one or more expired-lease members in `active`. *Postcondition:* only
  `g`'s expired members are recovered into `g:<g>:pending` (score 0), `gactive[g]` decremented, the lane re-rung if
  serviceable + a wake; a sibling group's expired members are left in `active`; a group with no expiry answers
  `{:ok, 0}`; the row `group` field is **unchanged** (no read-site drifts). *Invariant:* every key declared/grammar-
  rooted on one `{q}` slot (INV3); the group gated host-side (INV4); the lease computed from the server clock (INV2);
  no new key family / no new wire class — a count return, not `error_reply` (INV3); `@reap` + `@sweep_stalled`
  byte-frozen (INV1).
  *Acceptance gate:* the `reap_group` `:valkey` scenario — enqueue two grouped members in distinct groups `g`/`h`, claim
  both short-lease, expire; `reap_group(q, g)` → `g`'s member in `g:<g>:pending` and absent from `active`/flat-pending,
  `h`'s member **still in `active`**, `gactive[g]` decremented; `Lanes.claim/3` returns `g`'s member with `group = g`; a
  completion charges `gactive[g]`; `Apollo (if engaged) re-verifies INV1 (the byte-frozen @reap + @sweep_stalled) + the
  declared-keys grep on @greap_group + the server-clock grep (no host timestamp)`.

- **AS2 — additive-minor conformance + the proof + the version bump (D5 + D6; NORMAL-risk).**
  *Directive:* register `reap_group` in `scenarios/0` with its probe (the two-group scoping scenario — defeats a no-op);
  re-pin the count **54 → 55** in both pin tests + their moduledocs ("fifty-four" → "fifty-five"); climb the version
  `2.4.1 → 2.4.2` in lockstep (the `mix.exs` label AND the connector `@wire_version` fence together — D-3; the
  `:fence` scenario is version-agnostic, so re-seed `{emq}:version` once via `DEL`); run the gate ladder; run the **byte-freeze grep**
  on the shipped recovery + lane scripts + a **multi-seed sweep** and **state the determinism posture explicitly**
  (NORMAL — the sweep touches a lease but mints no id and starts no process, **no ≥100 loop**); confirm no regression on
  the prior suites; confirm the boundary grep is empty. *Precondition:* the prior **54** byte-unchanged; the build
  complete. *Postcondition:* the scenario registered + probed; the count is 55; the prior set git-verified byte-
  unchanged; the `:valkey` suites green; the multi-seed sweep green; the posture stated; the version 2.4.2; the prior
  suites unchanged. *Invariant:* additive minor (INV5); the prior set + the shipped recovery/lane scripts byte-unchanged
  (INV1); the multi-seed sweep (not the ≥100 loop) is the honest proof for a NORMAL lease-touching/mint-free rung (no
  false-green).
  *Acceptance gate:* `Conformance.run/2` prints `{:ok, 55}`; both pin tests assert 55; the prior 54 git-verified byte-
  unchanged; the shipped recovery + lane scripts `grep redis.call` diff = 0; the emq.1/2/3/4.1 suites unchanged; the
  boundary grep empty; the version is 2.4.2; the determinism posture recorded (NORMAL, multi-seed sweep, no ≥100 loop).

## Propagation clause

No gendered pronouns for agents; no perceptual or interior-state verbs ("sees" / "wants" / "feels") for agents or
software (components read, compute, refuse, return); no first-person narration ("we" / "I think"). Forward tense for
the unbuilt surface ("emq.4.2 builds …"). Every reference is a real `echo_mq`/`echo_wire` module, a real v1 command
record (READ-ONLY, the form NOT lifted), or a design §. The v1 `stalled_checker`/`moveStalledJobsToWait` is a
**capability reference**, never a thing migrated from. The inline `Script.new/2` law (no `priv/`). NO git.
