# EMQ.3.1 · agent brief — the single-queue flow (the Mars build brief)

> The build brief for **emq.3.1** — the FIRST sub-rung of the parent/flow family (the single-queue flow). What
> Mars reads first, the requirements traced to stories + invariants, the execution topology, and the agent
> stories (Directive + Acceptance gate). The spec **body** [`./emq.3.1.md`](emq.3.1.md) is authoritative; this
> brief and [`./emq.3.1.stories.md`](emq.3.1.stories.md) DERIVE from it — when a derived artifact disagrees
> with the body, the body wins. **No code is built until the Operator rules Fork A** ([`./emq.3.md`](../../emq.3.md)
> — single-queue first is the recommended arm this triad is authored to).

## References (read first, in order)

1. **The sub-rung body** — [`./emq.3.1.md`](emq.3.1.md): the slice (§0), the Goal, the Scope (In/Out — note
   the honest **Out** list: cross-queue, deep recursion, child-result reads, failure policy, bulk), the
   Deliverables (D1–D6), the invariants (INV1–INV9). **Read it before any build story.**
2. **The family body** — [`./emq.3.md`](../../emq.3.md): the A-1-compatible flow design (the load-bearing section —
   the declared-subkey dependency tree, the fan-in gate, the claim gate), and the three surfaced forks (A·A,
   B·counter+guard, C·`awaiting_children` — the arms emq.3.1 is authored to).
3. **The design canon** — [`../emq.design.md`](../../../emq.design.md): **§11.10** (the deferral + "an A-1-compatible
   flow design is real design work"), **§6** (the grammar — the `job:<id>:{dependencies,processed,failed,unsuccessful}`
   subkeys + the totality property), **§5** (no new wire class), **S-6** (the A-1 declared-keys law), **S-1**
   (the braced keyspace — the slot constraint), **§11.12** (the escalation protocol — a failing flow test is a
   finding, not a spec defect to paper over).
4. **The v1 capability reference (READ-ONLY — the FORM NOT to lift)** —
   `echo/apps/echomq/lib/echomq/flow_producer.ex`: `add/2` (the parent + children shape). The
   **data-value-rooted** tree (`parent_key = "#{queue_key}:#{job_id}"` from a data-value `job_id`, line 354;
   `parent_info` threaded into each child) is **NOT** lifted — its data-value rooting is the A-1 violation
   emq.3.1 redesigns away. Also `echo/apps/echomq/priv/scripts/moveToFinished-15.lua:140-141` — where v1 names
   the `:dependencies`/`:processed` subkeys (the §6 reservation's origin).
5. **The as-built floor (the build TARGET + the A-1 precedent — RE-PROBE every anchor at the pre-build
   reconcile, the lag-1 law)** — `echo/apps/echo_mq/lib/echo_mq/jobs.ex`:
   - `@enqueue` (the **shape to model `@enqueue_flow` on**: the kind law FIRST act `string.sub(ARGV[1],1,3) ~=
     'JOB'` → `EMQKIND`; the existence guard; `HSET` the row `state/attempts/payload`; `ZADD` to `pending`;
     declares `KEYS[1]=job row`, `KEYS[2]=pending` — `jobs.ex:14-24`).
   - `@complete` (the **fan-in hook host**: the `was_active = redis.call('ZREM', KEYS[1], ARGV[1])` guard and
     the `p` base-derivation of lane keys; the `was_active`-style guard gates the idempotent decrement —
     `jobs.ex:139-171`). **As-built (post-build):** the shipped shape is `KEYS[1]`=active, `KEYS[2]`=row,
     `ARGV[1]`=id, `ARGV[2]`=token, `ARGV[3]`=`p` (the queue base). The parent reference is a **`'parent'` data
     field** on the child row, read **host-side** by `complete/4` (`parent_of/3`, `jobs.ex:382-389`); when
     present, `complete/4` **appends THREE declared keys** — `KEYS[3]`=parent `:dependencies`, `KEYS[4]`=parent
     `:processed`, `KEYS[5]`=parent row (+ `ARGV[4]`=parent id, `ARGV[5]`=child result). The flow branch (`if
     KEYS[3] and was_active == 1 then …`) `DECR`s `KEYS[3]` inside the `was_active == 1` guard (exactly-once),
     `HSET`s `KEYS[4]`, and at zero `ZADD`s the parent to `p .. 'pending'` + `HSET`s `KEYS[5]` `state = pending`.
     INV2 holds: the `'parent'` field is a host-side `HGET`; inside Lua every key is a declared `KEYS[n]`.
   - `@extend_locks` (the **A-1 derivation precedent**: `local jk = base .. 'job:' .. id`, `jobs.ex:591`; ids
     gated host-side at `jobs.ex:675` before the wire).
   - `add_log/5` (the **subkey-compose precedent**: `Keyspace.job_key(queue, job_id) <> ":logs"`, `jobs.ex:458`
     — the flow subkeys compose the same way: `<> ":dependencies"`, `<> ":processed"`).
   - `keyspace.ex`: `job_key/2` (gates `BrandedId.valid?/1`, RAISES on an ill-formed id — INV6), `queue_key/2`.
   - `metrics.ex`: `get_job_state/3` + `@state_lookup` (`metrics.ex:98-125`) — the **row-FIELD branch** the
     `awaiting_children` value threads into (NOT `@set_states` — D4/D-3): the script tail reads `HGET KEYS[5]
     'state'` after the four set checks miss, returning `'awaiting_children'` only for that exact value, every
     other extant-row state still `'unknown'` (the shipped `unknown_state` verdict byte-unchanged). The host
     adds `:awaiting_children` to the typespec union (`metrics.ex:116`); `@set_states` (line 23) is unchanged.
   - `conformance.ex`: `scenarios/0` (the scenario set the additive-minor law grows — **re-probe the live
     count** at the reconcile; do NOT hardcode it; the count is whatever exists at B0). **Stage-0 reconcile
     (2026-06-15) confirmed the live count = 43** (`scenarios/0` 43 keys ending `obliterate_grouped`;
     `conformance_run_test.exs:40` `{:ok, 43}`; `conformance_scenarios_test.exs` `@run_order` 43 names) — so the
     re-pin is **43 → 45** (`flow_add` + `flow_fanin`), the literal Mars writes in both pin tests + their
     moduledocs ("forty-three" → "forty-five"). Re-confirm at B0 before editing (the lag-1 law — a sibling rung
     could move it).
6. **The shape model** — [`./emq.2.4.md`](../../emq.2/emq.2.rungs/emq.2.4.md) / [`./emq.2.4.llms.md`](../../emq.2/emq.2.rungs/emq.2.4.llms.md) (the rung
   triad + brief shape). The program law: `.claude/skills/echo-mq-program.md` (the v2 laws, the gate ladder, the
   conformance additive-minor law); the as-built map: `.claude/skills/echo-mq-surface.md`. The implementor
   skill: `.claude/skills/echo-mq-implementor.md` (the inline `Script.new/2` law, the declared-keys / branded /
   server-clock laws, the per-app gate ladder).

## Requirements (numbered; each traced back to a story, forward to an invariant)

> None is built until Fork A is ruled. The build is authored to **Fork A·Arm A** (single-queue),
> **Fork B·counter+guard**, **Fork C·`awaiting_children`**.

1. **R1 — `EchoMQ.Flows.add/3` gates every flow node (AS-BUILT).** The host API `add(conn, queue, %{parent:
   %{id, payload}, children: [%{id, payload}]}) :: {:ok, {parent_id, [child_id]}} | {:error, term()}` takes the
   flow as a **map**, each node's branded `JOB` id **host-minted by the caller** (a distinct id per node — parent
   + each child), and gates **every** id at `Keyspace.job_key/2` (raises on an ill-formed id — INV6) BEFORE the
   wire, then calls `@enqueue_flow`. A child spec carrying a `:queue` field ≠ `queue` is **rejected**
   `{:error, :cross_queue}` (`reject_cross_queue/2` — host-side; the cross-queue flow is emq.3.3); a non-`JOB` id
   maps to `{:error, :kind}`. (US2 → INV6, INV8.)
2. **R2 — `@enqueue_flow` is one atomic transition on one slot.** Inline `Script.new/2`. Declares the parent row
   `KEYS[1]`, the parent's `:dependencies` key `KEYS[2]`, the queue `pending` set `KEYS[3]`, the child rows
   `KEYS[4..]` (each same-`{q}`, in `KEYS[]`). Body: kind law FIRST (`EMQKIND` on any non-`JOB` id — the
   `@enqueue` first act); `HSET` + `ZADD pending` each child row (`state = pending`); `HSET` the parent row
   `state = awaiting_children`; set `:dependencies` to the child count; **do NOT** `ZADD` the parent to
   `pending`. Every key shares the one `{q}` slot (atomic). (US2 → INV2, INV8.)
3. **R3 — the fan-in hook on `@complete` is a conditioned branch, idempotent, at-zero releasing (AS-BUILT).** The
   parent reference is a **`'parent'` data field** on the child row, read **host-side** by `complete/4`
   (`parent_of/3`); when present, `complete/4` **appends THREE declared keys** — `KEYS[3]`=parent `:dependencies`,
   `KEYS[4]`=parent `:processed`, `KEYS[5]`=parent row (+ `ARGV[4]`=parent id, `ARGV[5]`=child result). The
   `@complete` flow branch (`if KEYS[3] and was_active == 1 then …`) **`DECR`s `KEYS[3]` idempotently** (inside
   the `was_active == 1` guard — Fork B's double-complete guard; a retired child also short-circuits at `if not
   att`), `HSET`s `KEYS[4]` with the child's result, and at zero `ZADD`s the parent to `p .. 'pending'` + `HSET`s
   `KEYS[5]` `state = pending`. **INV2 holds — no Lua key from a data value:** the `'parent'` field is a host-side
   `HGET`, every script key is a declared `KEYS[n]`. A child with **no** `'parent'` field is the **byte-unchanged**
   shipped completion. The shipped `@claim` is **untouched**. (US3 →
   INV3, INV4, INV5.)
4. **R4 — the gate is the parent's absence from `pending`, never an `@claim` edit.** The parent's row exists
   (`awaiting_children`, introspectable) but is **not** a `pending` member while `:dependencies` > 0, so the
   shipped `ZPOPMIN pending` never returns it (the emq.2.2-D2 separate-gate discipline). `@claim` is
   byte-unchanged. (US3 → INV3, INV4.)
5. **R5 — the `awaiting_children` row state is threaded into the read plane (a row-FIELD branch, NOT a set).**
   `@state_lookup` (`metrics.ex:98-106`), after the four set checks (`KEYS[1..4]`) miss, reads the row's `state`
   field (`HGET KEYS[5] 'state'`) and returns `'awaiting_children'` **only** for the exact value
   `"awaiting_children"`; every other extant-row state still returns `'unknown'` (preserving the shipped
   `unknown_state` verdict **byte-unchanged** — D4/D-3). The host `get_job_state/3` adds `:awaiting_children` to
   its `{:ok, …}` typespec union **and** maps the wire string → atom through a **closed `@lookup_states` literal
   table** (the as-built choice — the atom's creation site; an unexpected string → `{:error, {:unknown_state,
   state}}`, never an open `to_existing_atom` raise). **`awaiting_children` must NOT join `@set_states`**
   (`~w(pending active schedule dead)`, `metrics.ex:23`) — it is a row-field state with **no
   ZSET**, so `get_counts`/the `counts` scenario stays byte-unchanged. A waiting parent reports
   `awaiting_children` distinctly (NOT `scheduled`, NOT `pending`); the parent is **not** on the `schedule` set
   (released by fan-in, not by time). (US4 → INV4.)
6. **R6 — additive-minor conformance (43 → 45).** Register `flow_add` + `flow_fanin` in `scenarios/0` **with
   their probes in the same change**; keep the prior **43** byte-unchanged (git-verified — name + contract +
   verdict body identical); re-pin the count **43 → 45** in **both** pinning tests (`conformance_run_test.exs`
   `{:ok, 45}` + `conformance_scenarios_test.exs` `@run_order`) and their moduledocs ("forty-three" →
   "forty-five"). (Stage-0 confirmed N_prior = 43; re-confirm at B0 — the lag-1 law.) (US5 → INV7.)
7. **R7 — no new key type, no new wire class, no new transport.** The flow keys are already-registered §6
   subkeys (compose with `<> ":dependencies"`/`<> ":processed"` — the `add_log/5` precedent); `EMQKIND` reused;
   the cross-queue-child rejection is a host-side guard; the flow rides the shipped connector `eval`/`pipeline`
   (no `echo_wire` change, no `SSUBSCRIBE`); `keyspace.ex`'s grammar is unedited. (US5, US-GATE → INV1.)
8. **R8 — the proof + the honest bound.** The `:valkey` + process flow suites green per-app; the
   mint/process-touching flow suite under the **≥100-iteration determinism loop** owning the machine; the prior
   emq.1 + emq.2.{1,2,3,4} suites + `Conformance.run/2` **unchanged** (no regression); the **four honest bounds**
   documented (the **hang-on-dead-child** limit — a dead child does not decrement, emq.3.4 adds the policy; **O1**
   the `:processed` presence marker; **O2** the `parent_of` `HGET`-per-completion perf follow-up; **L-5** the
   flow-subkey lifecycle — all emq.3.2/3.x, named not faked); Apollo MANDATORY. (US6 → INV3, INV6, INV9.)

## Execution topology

- **Runtime shape.** `EchoMQ.Flows` — a new lib module (host-side API) over a new inline `@enqueue_flow`
  `Script.new/2` attribute, calling the **shipped `EchoWire` connector** (`Connector.eval`) the way
  `EchoMQ.Jobs` does. **No new process** (the single-queue flow is enqueue + fan-in-on-complete, both wire
  calls). The flow stands ON the as-built supervision tree unchanged.
- **The build-order task DAG.** (0) **pre-build reconcile** — re-probe `jobs.ex` `@enqueue`/`@claim`/`@complete`
  + `@extend_locks` + `add_log/5`, `keyspace.ex` `job_key/2`, `metrics.ex` `get_job_state/3`, `conformance.ex`
  count; pin the lag-1 anchors; confirm Fork A is ruled. (1) `@enqueue_flow` (the script) + `EchoMQ.Flows.add/3`
  (the host API + the per-id gate + the cross-queue-child rejection). (2) the `@complete` fan-in hook (the
  conditioned branch + the idempotent decrement + the at-zero release + the `:processed` record). (3) the
  `awaiting_children` state in `metrics.ex`. (4) `flow_add` + `flow_fanin` in `conformance.ex` + the count
  re-pin in both pin tests. (5) the `:valkey`/process suites + the ≥100 loop on the mint/process-touching one.
  (6) the gate ladder.
- **The EXACT files touched.**
  - `echo/apps/echo_mq/lib/echo_mq/flows.ex` — **NEW** (`EchoMQ.Flows.add/3` + the inline `@enqueue_flow`).
  - `echo/apps/echo_mq/lib/echo_mq/jobs.ex` — **EDIT** (the fan-in hook folded into `@complete`; the ONE
    shipped-script edit — **HIGH-RISK, Apollo MANDATORY**).
  - `echo/apps/echo_mq/lib/echo_mq/metrics.ex` — **EDIT** (the `awaiting_children` **row-field branch** in
    `@state_lookup` + the `get_job_state/3` typespec — NOT `@set_states`, D4; a small additive change that keeps
    the shipped `unknown_state` verdict byte-unchanged).
  - `echo/apps/echo_mq/lib/echo_mq/conformance.ex` — **EDIT** (`flow_add` + `flow_fanin`; the count re-pin).
  - `echo/apps/echo_mq/test/flow_add_test.exs` + `flow_fanin_test.exs` — **NEW** (`:valkey` + process).
  - `echo/apps/echo_mq/test/conformance_scenarios_test.exs` + `conformance_run_test.exs` — **EDIT** (re-pin the
    count).
  - **Untouched:** `apps/echomq` (the capability reference); `echo_wire` (the flow rides the shipped connector);
    `keyspace.ex`'s grammar (no new key type — the subkeys compose).
- **The gate ladder (run before reporting — the program craft).** `asdf current erlang` (re-probe, do not
  hardcode; a switch implies a full rebuild); `redis-cli -p 6390 ping` → `PONG`; `TMPDIR=/tmp mix compile
  --warnings-as-errors` in `echo/apps/echo_mq`; `TMPDIR=/tmp mix test` in the app dir (the `:valkey` suites
  included for this wire rung: `--include valkey`); `EchoMQ.Conformance.run/2` over a live connection prints the
  new line count `{:ok, N}`; the **≥100-iteration determinism loop** for the mint/process-touching flow suite:
  `for i in $(seq 1 100); do TMPDIR=/tmp mix test test/flow_fanin_test.exs --include valkey || break; done` —
  the loop OWNS the machine (no concurrent liveness server, no sibling heavy I/O). **Umbrella-wide `mix test` is
  BANNED.**
- **The boundary.** The diff stays inside `echo/apps/echo_mq`. A change reaching a third app is out of bounds.
  Agents run **NO git** (the Director commits by pathspec at the rung's close: `git commit -F <msg> --
  <paths>`; never `git add -A`). The Operator commits out-of-band — watch for `AM`-status files and exclude
  them.

## Agent stories (Directive + Acceptance gate; stated as contracts)

> Each surface is a contract (precondition / postcondition / invariant) so the Operator and Apollo accept at the
> boundary, not by re-reading the diff. **None runs until Fork A is ruled.**

- **AS-FORK — the fork gate (FIRST).**
  *Directive:* confirm the Operator has ruled Fork A (Arm A recommended) and recorded it; if unruled, STOP and
  report (no build artifact until ruled); note Forks B/C's recorded recommendations (counter+guard;
  `awaiting_children`). *Precondition:* the family body's surfaced forks. *Postcondition:* Fork A ruled, recorded
  BEFORE any build artifact. *Invariant:* the build proceeds only on the ruled arm (INV8).
  *Acceptance gate:* the ledger records the Fork A ruling; the build's touch-set matches the ruled arm
  (Arm A → single-queue atomic scripts; a cross-queue child rejected).

- **AS1 — `EchoMQ.Flows.add/3` + `@enqueue_flow` (D2).**
  *Directive:* build the host API (mint + gate every id, reject a cross-queue child) + the inline `@enqueue_flow`
  (kind law FIRST; child rows + `pending`; the parent row `awaiting_children` + `:dependencies` = N; the parent
  withheld from `pending`). *Precondition:* a flow of a parent + N same-queue children, every id `JOB`-namespaced.
  *Postcondition:* N children in `pending` (claimable), the parent row present (`awaiting_children`, `:dependencies`
  = N), the parent NOT in `pending`; a cross-queue child spec rejected. *Invariant:* every key
  declared/grammar-rooted on one `{q}` slot (INV2, INV8); every id gated host-side (INV6); no new key type
  (INV1).
  *Acceptance gate:* the `flow_add` `:valkey` scenario — add a parent + 2 children → 3 distinct `JOB…` ids; the
  2 children claimable; the parent `:empty` with `:dependencies` = 2; the parent row `awaiting_children`; a
  cross-queue child rejected.

- **AS2 — the fan-in hook on `@complete` (D3 — HIGH-RISK; AS-BUILT).**
  *Directive:* the parent reference is a **`'parent'` data field** on the child row (written by `@enqueue_flow`),
  read **host-side** by `complete/4` (`parent_of/3`); when present, `complete/4` appends **THREE declared keys** —
  `KEYS[3]`=parent `:dependencies`, `KEYS[4]`=parent `:processed`, `KEYS[5]`=parent row (+ `ARGV[4]`=parent id,
  `ARGV[5]`=child result). The `@complete` flow branch (`if KEYS[3] and was_active == 1 then …`) `DECR`s `KEYS[3]`
  **inside the `was_active == 1` branch** (`jobs.ex:147`) so it fires exactly once per the child's own
  `active`→done transition (the Fork-B double-complete guard; a retired child also short-circuits at `if not
  att`); `HSET`s `KEYS[4]` with the child result; at zero `ZADD`s the parent (`ARGV[4]`) to `p .. 'pending'`
  (grammar-derived from `ARGV[3]`) + `HSET`s `KEYS[5]` `state = pending`. A child with no `'parent'` field takes
  the **untouched** flat/grouped branches (the byte-unchanged completion). *Precondition:* a flow child completes
  (the token holder).
  *Postcondition:* the parent's count decremented exactly once; at zero, the parent in `pending`; the child
  result in `:processed`. *Invariant:* the non-flow `@complete` byte-unchanged (INV3); the decrement idempotent
  (INV5); declared keys on one slot (INV2); the shipped `@claim` untouched.
  *Acceptance gate:* the `flow_fanin` `:valkey` scenario (claim the parent → `:empty` until the Nth child, then
  claimable) + a double-complete scenario (count drops by exactly 1); the prior conformance set byte-unchanged
  (INV7); **Apollo re-verifies INV3 + the order theorem + the byte-unchanged `@enqueue`/`@claim`** (the
  shipped-script edit).

- **AS3 — the `awaiting_children` state + the conformance additive-minor (D4 + D5).**
  *Directive:* thread `awaiting_children` into `@state_lookup`'s **row-FIELD branch** (`HGET KEYS[5] 'state'`
  after the four set checks miss → `'awaiting_children'` only for that exact value; NOT `@set_states`) + the
  `get_job_state/3` typespec union; register `flow_add` + `flow_fanin` in `scenarios/0` with probes; re-pin the
  count **43 → 45** in both pin tests + their moduledocs. *Precondition:* the prior **43** byte-unchanged; the
  read plane's `@state_lookup`/`@set_states` as-built. *Postcondition:* a waiting parent reads
  `awaiting_children`; the shipped `unknown_state` still reads `:unknown`; the count is 45; the prior set
  git-verified byte-unchanged. *Invariant:* read-plane honesty (INV4); the `unknown_state` verdict byte-unchanged
  (INV3); additive minor (INV7).
  *Acceptance gate:* `get_job_state/3` reads `awaiting_children` while waiting + `pending` after release;
  **the shipped `unknown_state` scenario still answers `{:ok, :unknown}` byte-unchanged**; `Conformance.run/2`
  prints `{:ok, 45}`; both pin tests assert 45.

- **AS4 — the proof + the honest bound (D6).**
  *Directive:* run the gate ladder; gate the mint/process-touching flow suite under the ≥100 loop; confirm no
  regression on the prior suites; document the hang-on-dead-child limit (a triad note + a test asserting a flow
  with a dead child leaves the parent `awaiting_children`). *Precondition:* the build complete. *Postcondition:*
  all suites green; the loop green; the prior suites unchanged; the dead-child limit asserted. *Invariant:* one
  green run is NOT proof (INV6); no regression (INV3); the bound honest, not papered over (INV9).
  *Acceptance gate:* the ≥100 loop green for the flow suite; the emq.1 + emq.2.{1,2,3,4} suites +
  `Conformance.run/2` unchanged; the dead-child limit test green; honest-row reporting (Valkey on 6390); Apollo's
  independent re-run BUILD-GRADE.

## Propagation clause

No gendered pronouns for agents; no perceptual or interior-state verbs ("sees" / "wants" / "feels") for agents
or software (components read, compute, refuse, return); no first-person narration ("we" / "I think"). Forward
tense for the unbuilt surface ("emq.3.1 builds …"). Every reference is a real `echo_mq`/`echo_wire` module, a
real v1 file (READ-ONLY, the form NOT lifted), or a design §. The v1 `flow_producer` is a **capability
reference**, never a thing migrated from. The inline `Script.new/2` law (no `priv/`). NO git.
