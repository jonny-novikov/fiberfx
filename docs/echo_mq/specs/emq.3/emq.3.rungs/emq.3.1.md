# EMQ.3.1 · The single-queue flow — the first buildable slice (Movement I, the flow family)

> **Status: SHIPPED** (built 2026-06-15; the FIRST sub-rung of the emq.3 parent/flow family — the flow family
> OPENS on a proven single-queue core; the family contract + the carve + the forks are [`./emq.3.md`](../emq.3.md)).
> As-built green: **CONFORMANCE 45/45** (the prior 43 byte-unchanged + `flow_add` + `flow_fanin`; the shipped
> `unknown_state` still `{:ok, :unknown}` — INV3 held), the `:valkey` flow suites + the ≥100 determinism loop
> green, compile clean (warnings-as-errors), Erlang 28.5.0.1 / Elixir 1.18.4 / Valkey 6390. **Apollo
> BUILD-GRADE.** The cross-queue (emq.3.3), child-result reads (emq.3.2), and failure-policy + bulk (emq.3.4)
> stay the honest **Out**. This body is synced to the as-built surface (each `[RECONCILE]` marked). emq.3.1
> carves the **single-queue flow** — a parent and its children **in the same queue** — the smallest coherent
> slice that exercises the WHOLE A-1-compatible flow mechanism (the declared-subkey dependency tree + the
> fan-in completion + the claim gate) on **one slot**, so every flow script is **fully atomic** and the design
> is founded and proven before the cross-queue hop (the fork-gated emq.3.3) is built. The v1 line
> (`apps/echomq/lib/echomq/flow_producer.ex`) is a **capability reference** — the behaviour to port, NEVER the
> data-value-rooted form to lift. **HIGH-RISK** — it edits the shipped `EchoMQ.Jobs.@complete` (the fan-in
> hook) and mints multiple ids per call → **Apollo MANDATORY at build** + the **≥100-iteration determinism
> loop**. emq.3.1 builds **only after the Operator rules Fork A** ([`./emq.3.md`](../emq.3.md) — single-queue
> first is the recommended arm this triad is authored to).

## 0 · The slice — what emq.3.1 carves, and why first

The family ([`./emq.3.md`](../emq.3.md)) redesigns flows so the parent→child dependency graph rides **declared
§6 subkeys of the parent** (not v1's data-value `parent_key`), and a parent is invisible to `claim` until its
children complete (fan-in). emq.3.1 carves the **single-queue** case: parent and children in **one queue**, so
every flow key shares the one `{q}` slot, so **every flow script is atomic** (one slot, one EVAL). This is the
first buildable slice because it founds and proves the **whole** new mechanism — the `:dependencies` counter,
the fan-in hook, the `awaiting_children` claim gate — with **zero** cross-slot complication; the cross-queue
crossing (the genuinely hard, eventually-consistent part — Fork A) is isolated to emq.3.3. The tracer bullet
for the family (the master-invariant discipline — one thin vertical slice, the skeleton running).

## Goal

emq.3.1 builds, inside `echo/apps/echo_mq`, the **single-queue parent/child flow**: a new `EchoMQ.Flows.add/3`
that enqueues a parent + its same-queue children atomically via a new inline `@enqueue_flow` script (the
children claimable immediately; the parent held out of `pending` with its outstanding-child count in
`emq:{q}:job:<parent>:dependencies` and its row `state = awaiting_children`), plus a **fan-in hook** folded into
the shipped `EchoMQ.Jobs.@complete` that decrements the parent's count on each child completion and, at zero,
**releases the parent to `pending`** (recording the child's result in the parent's `:processed` subkey) — all
under the A-1 declared-keys law (every key declared/grammar-rooted on the one `{q}` slot), branded `JOB` ids
gated at the key builder, and the additive-minor conformance growth (`flow_add`, `flow_fanin`). The non-flow
path is **byte-unchanged**, and the shipped `@claim` is **untouched** (the gate is the parent's absence from
`pending`, not a check inside `@claim`).

## Rationale (5W)

- **Why** — the single-queue flow is the **foundation** of the flow family: it establishes the declared-subkey
  dependency representation and the fan-in gate on the simplest topology (one slot → fully atomic), proving the
  A-1-compatible design before the cross-queue hop complicates it. Until a flow can be added and its parent
  held-then-released, the family has no working surface; emq.3.1 is that surface. It is the rung that lets
  emq.3.2 (child-result reads), emq.3.3 (cross-queue), and emq.3.4 (failure-policy + bulk) build on a proven
  core.
- **What** — emq.3.1 builds: (1) **`EchoMQ.Flows.add/3`** — the host API taking a parent spec + a list of
  same-queue child specs, minting a distinct branded `JOB` id per node, gating every id at `Keyspace.job_key/2`
  before the wire, and calling `@enqueue_flow`; (2) **`@enqueue_flow`** — the inline `Script.new/2` transition:
  kind law FIRST (`EMQKIND`), write + `ZADD pending` the child rows, write the parent row
  `state = awaiting_children` + set `:dependencies` to the child count, **do not** add the parent to `pending`;
  (3) **the fan-in hook** folded into `@complete` — on a child carrying a parent reference (a declared `KEYS[n]`
  = the parent's `:dependencies` key), decrement it idempotently and at zero `ZADD` the parent to `pending` +
  `HSET` the child's result into the parent's `:processed` subkey; a child with no parent is the byte-unchanged
  shipped completion; (4) the **`awaiting_children`** row state threaded into `EchoMQ.Metrics.get_job_state/3`'s
  `@state_lookup` row-field branch (NOT `@set_states` — Fork C Arm A, the byte-safe mechanism in D4); (5) the
  conformance scenarios `flow_add` + `flow_fanin` (additive minor);
  (6) the `:valkey`/process test suites + the ≥100 loop. Authored to **Fork A·A** (single-queue), **Fork
  B·counter+guard** (the `:dependencies` counter + the double-complete idempotency guard), **Fork C·Arm A**
  (`awaiting_children`).
- **Who** — the program (the rung that founds the flow family and unblocks 3.2–3.4); the bus's consumers, who
  gain single-queue fan-out/fan-in (do the parts, then the whole, within one queue); the conformance harness,
  which grows by `flow_add` + `flow_fanin`; Apollo, who re-runs the gate ladder + the ≥100 loop independently
  (MANDATORY — the rung edits a shipped script + mints multiple ids per call). **codemojex** (prospective): a
  same-queue job whose parent gates on its child legs (it names no flows today — recorded, not
  asserted).
- **When** — Movement I, the flow family's **first** sub-rung, after the emq.2 cluster ships (emq.3.1 stands ON
  the as-built `EchoMQ.Jobs` `@enqueue`/`@claim`/`@complete`, proven at depth at emq.2.4). SPECCED this design
  cycle; **built only after the Operator rules Fork A** (single-queue first is the recommended arm; an Arm-B
  ruling re-scopes emq.3.1 to the cross-queue shape before the build). Forks B and C are cheap pre-build
  re-scopes (surface, do not block).
- **Where** — `echo/apps/echo_mq` only: `flows.ex` (NEW — `EchoMQ.Flows` + the inline `@enqueue_flow`),
  `jobs.ex` (EDIT — the fan-in hook in `@complete`, the ONE shipped-script edit), `metrics.ex` (EDIT — the
  `awaiting_children` `@state_lookup` row-field branch + the typespec — NOT `@set_states`, D4), `conformance.ex` (EDIT — `flow_add` + `flow_fanin` + the count
  re-pin), `test/flow_*_test.exs` (NEW — `:valkey`/process), the two pinning tests (EDIT — the count). `echo_wire`
  is **untouched** (the flow rides the shipped connector `eval`/`pipeline` — no new transport, no new connector
  verb). `apps/echomq` is **untouched** (the capability reference). The §6 grammar in `keyspace.ex` is
  **unedited** (the flow subkeys compose with `<> ":dependencies"`/`<> ":processed"` the way `add_log/5`
  composes `<> ":logs"`, `jobs.ex:458` — already-registered §6 subkeys, no new type). Exact line anchors pinned
  at the pre-build reconcile (the lag-1 law — the emq.2 cluster moved the surface).

## Scope

- **In** — the single-queue parent/child flow: (1) `EchoMQ.Flows.add/3` (a parent + a flat list of same-queue
  children; one level of children — the deeper recursive tree is a later concern, see **Out**); (2) the
  `@enqueue_flow` atomic transition (kind law, child rows + `pending`, the parent row `awaiting_children` + the
  `:dependencies` count, the parent withheld from `pending`); (3) the fan-in hook in `@complete` (the
  idempotent decrement + the at-zero release + the `:processed` result record; the non-flow path byte-unchanged);
  (4) the `awaiting_children` row state in `Metrics.get_job_state/3`; (5) `flow_add` + `flow_fanin` conformance
  scenarios (additive minor, the prior count byte-unchanged); (6) the `:valkey` + process test suites; the
  process/mint-touching suite under the **≥100-iteration determinism loop**; honest-row reporting (Valkey on
  6390 the truth row).
- **Out** — the **cross-queue** flow (a parent and children in *different* queues — the slot-boundary crossing
  is **emq.3.3**, gated on Fork A; emq.3.1 refuses or rejects a cross-queue child spec with a typed/host-side
  error, never silently mis-keys); the **deep recursive tree** (a child that is itself a parent of
  grandchildren — emq.3.1 builds one parent level; the recursive build is folded in at emq.3.3/3.4 where the
  cross-queue and bulk shapes are settled, OR carved as emq.3.1's own follow-up — recorded, NOT built here);
  the **child-result READS** (`Flows.children_values/3`/`dependencies/3` over `:processed`/`:dependencies` — the
  v1 `get_children_values`/`get_dependencies` surface is **emq.3.2**; emq.3.1 *writes* the `:processed` record,
  it does not add the read API). **The `:processed` VALUE is a DELIBERATE presence marker, not a result payload**
  (honest bound **O1**): the fan-in `HSET`s `child_id → child_id` (recording **that** a child completed, keyed by
  child id), because `complete/4` carries **no result argument** (`jobs.ex:377-381`); the real child-result write
  + the read are **emq.3.2**, named here rather than faked; the **failure-policy options** (`fail_parent_on_failure`/
  `ignore_dependency_on_failure` over `:failed`/`:unsuccessful` — **emq.3.4**; emq.3.1's children that *fail*
  exhaust retries to `dead` as the shipped `@retry` does, and the parent's count is **not** decremented by a
  dead child — a flow whose child dies hangs its parent by design until emq.3.4 adds the failure policy, stated
  honestly, NOT silently); **`add_bulk`** (multiple flows in one call — **emq.3.4**); any **new key type** or
  **new wire class** (none — the §6 subkeys + `EMQKIND` are reused); any **`@claim` edit** (the gate is the
  parent's absence from `pending`); any **`echo_wire`/transport** change; any **edit to the frozen v1 line**.

### The honest bounds + carried follow-ups (as-built, surfaced at the build — recorded, not papered over)

emq.3.1 ships the single-queue write-side flow; these are its honest bounds — each a **correct-for-scope** limit
the build surfaced, never a defect — alongside the **dead-child limit** (a child to `dead` does not decrement;
the parent hangs `awaiting_children` until emq.3.4 — **Out**, above) and **O1** (the `:processed` presence
marker — **Out**, above):

- **O2 — the `parent_of` read per completion (a carried emq.3.2 perf follow-up, correctness-neutral).**
  `Jobs.complete/4` does one host-side `HGET <job> 'parent'` on **every** completion (flow or not, `parent_of/3`,
  `jobs.ex:382-389`) — one extra round-trip on the hot completion path. Correctness-neutral (a `nil` parent → the
  byte-unchanged non-flow completion), accepted by the build. **emq.3.2** can fold the parent-read into the claim
  result (the worker already holds the row), retiring the extra round-trip.
- **L-5 — the flow-subkey lifecycle (an honest bound; the cleanup is an emq.3.x concern).** The parent's
  `:dependencies`/`:processed` subkeys **outlive** the parent row: `@complete` `DEL`s only the row (`KEYS[2]`,
  `jobs.ex:189`) and `obliterate`'s `del_job` enumerates only `:logs`/`:lock` (`admin.ex:152`), so **neither
  sweeps the flow subkeys**. This is **correct** for emq.3.1's write-side scope — `:processed` **must** outlive
  the parent row so **emq.3.2**'s read API can read it. The flow-subkey cleanup/lifecycle (including `obliterate`
  sweeping `:dependencies`/`:processed`) is an **emq.3.x** concern. **Carry:** `EchoMQ.Admin`'s `obliterate`
  moduledoc (`admin.ex`, "every reachable job row + its subkeys") will need a one-line honest-bound note **when**
  that emq.3.x lifecycle rung adds flow-subkey cleanup — **NOT this rung** (the moduledoc accurately describes
  `obliterate`'s current row + `:logs` + `:lock` sweep; `admin.ex` is **untouched** here).

## Deliverables

emq.3.1 builds (forward-named; the flow surface does not yet exist in `echo_mq`):

- **EMQ.3.1-D1 — the fork gate (FIRST):** Fork A ([`./emq.3.md`](../emq.3.md)) **settled by the Operator** before
  any build artifact — Arm A (single-queue first; the carve this triad is authored to) vs Arm B (cross-queue
  from emq.3.1, the non-atomic host-orchestrated shape). Recorded BEFORE any build story runs (the cluster
  precedent — the design-make/fork gate is the relocated gate). Forks B (counter vs set) and C
  (`awaiting_children` vs `scheduled`) recorded with their recommendations (counter+guard; `awaiting_children`)
  — cheap pre-build re-scopes, surfaced for the Operator's optional ruling, not blockers. The triad re-derives
  to the ruled arms at the pre-build reconcile.
- **EMQ.3.1-D2 — `EchoMQ.Flows.add/3` + the `@enqueue_flow` transition (AS-BUILT — `[RECONCILE]` the concrete
  shape):** the host API `add(conn, queue, %{parent: %{id, payload}, children: [%{id, payload}]}) :: {:ok,
  {parent_id, [child_id]}} | {:error, term()}` (`flows.ex:71-104`) — the flow is a **map** `%{parent: spec,
  children: [spec]}`, each spec `%{id: <branded JOB id>, payload: <binary>}` with the ids **host-minted by the
  caller** (the parent + each child a distinct branded `JOB` id). `add/3` **gates every id at
  `Keyspace.job_key/2`** (raises on an ill-formed id — INV6) BEFORE the wire and calls the inline
  `@enqueue_flow`. The script declares `KEYS[1]`=the parent row, `KEYS[2]`=the parent's `:dependencies` key,
  `KEYS[3]`=the queue `pending` set, `KEYS[4..]`=the child rows (each same-`{q}`, in `KEYS[]`); `ARGV[1]`=parent
  id, `ARGV[2]`=parent payload, `ARGV[3]`=N, `ARGV[4..]`=(child id, payload) pairs. It runs the **kind law
  FIRST** (`EMQKIND` on any non-`JOB` id — over the parent **and** every child, in a check-all loop before any
  write), writes each child row `state = pending` (+ the `'parent'` data field, D3) + `ZADD`s them to `pending`,
  writes the parent row `state = awaiting_children` + `SET`s `:dependencies` = N, and **does NOT** add the parent
  to `pending`. Atomic (one slot). A child spec carrying a `:queue` field ≠ `queue` is **rejected**
  `{:error, :cross_queue}` (`reject_cross_queue/2`, `flows.ex:109-115` — host-side, **Out**); a non-`JOB` id maps
  to `{:error, :kind}`.
- **EMQ.3.1-D3 — the fan-in hook on `@complete` (the ONE shipped-script edit — HIGH-RISK; AS-BUILT —
  `[RECONCILE]` the parent-reference + the THREE declared keys):** the parent reference is a **`'parent'` data
  field** on each child row (the bare parent branded id, written by `@enqueue_flow` `flows.ex:45`), read
  **host-side** by `Jobs.complete/4` via `parent_of/3` (`HGET <child> 'parent'`, `jobs.ex:382-389`). When that
  read returns a parent, `complete/4` derives the parent's keys host-side and **appends THREE declared keys**
  after the two shipped `@complete` keys (as-built `KEYS[1]`=active, `KEYS[2]`=row): `KEYS[3]`=the parent's
  `:dependencies` key, `KEYS[4]`=the parent's `:processed` key, `KEYS[5]`=the parent row key (+ `ARGV[4]`=parent
  id, `ARGV[5]`=the completing child's result) — passed **only** for a flow child. The `@complete` flow branch
  (`if KEYS[3] and was_active == 1 then …`) **decrements the parent's count idempotently** (the double-complete
  guard — Fork B: the `DECR KEYS[3]` is **inside the `was_active == 1` branch** the shipped script computes at
  `jobs.ex:147` (`was_active = ZREM KEYS[1] ARGV[1]`), and a retired/already-completed child short-circuits at
  the `if not att then return 0` guard before the branch is even reached — so the decrement fires exactly once
  per the child's own `active`→done transition), `HSET`s the child's result into `KEYS[4]` (the parent's
  `:processed`, keyed by child id), and **at zero** (`left <= 0`) `ZADD`s the parent (`ARGV[4]`) to its `pending`
  set (`p .. 'pending'`, grammar-derived from the ARGV-carried `{q}` base `ARGV[3]`) + `HSET`s `KEYS[5]`
  `state = pending`. **INV2 holds — no key is read from a data value *in Lua*:** the `'parent'` field is a
  **host-side** `HGET` (the legal v2 form), and inside Lua every key is a declared `KEYS[n]`; the v1 form (the
  v1 *Lua script* rooting keys in the child's data-value `parent_key`) is **not** lifted. A child with **no**
  `'parent'` field is the **byte-unchanged** shipped completion (the hook is a conditioned branch on the absence
  of `KEYS[3]`, not a rewrite — both the existing flat and grouped-lane branches are untouched). The shipped
  `@claim` is **untouched**.
- **EMQ.3.1-D4 — the `awaiting_children` row state (threaded WITHOUT breaking the shipped `unknown_state`
  verdict — `[RECONCILE]`, the precise mechanism):** the parent's row reads `state = awaiting_children` while it
  waits; `EchoMQ.Metrics.get_job_state/3` reports it as a distinct state (Fork C Arm A); the read plane stays
  truthful (a waiting parent is neither `pending`, `scheduled`, nor on any set the existing states name). **The
  threading is row-FIELD-conditioned, NOT a set + NOT a row-existence check.** As-built (`metrics.ex:98-106`),
  `@state_lookup` is a strict precedence ladder — it `ZSCORE`-checks `KEYS[1..4]` (pending/active/scheduled/dead)
  in order and, only when all four miss, `EXISTS KEYS[5]` → `'unknown'`, else `'absent'`. A flow parent is a
  **row-in-no-set**, and so is the shipped **`unknown_state`** scenario's in-flight job (`conformance.ex:853-870`
  asserts `{:ok, :unknown}` for a row that exists in no set, its `state` field still `"active"`) — a row-existence
  check **cannot tell them apart**, so a naive "any row in no set → `awaiting_children`" would silently flip
  `unknown_state`'s verdict (an INV3/INV7 break). **The sound form:** after the four set checks miss, `@state_lookup`
  reads the row's `state` field (`HGET KEYS[5] 'state'`) and returns `'awaiting_children'` **only** for the exact
  value `"awaiting_children"`; every other extant-row state still returns `'unknown'`; no row returns `'absent'`.
  This keeps `unknown_state` **byte-unchanged** (its row's `state` field `"active"` ≠ `"awaiting_children"` → still
  `'unknown'`). **AS-BUILT (`[RECONCILE]` — a hardening beyond the Stage-0 typespec note):** the host
  `get_job_state/3` adds `:awaiting_children` to its `{:ok, …}` typespec union **and** maps the wire string →
  atom through a **closed `@lookup_states` literal table** (`metrics.ex`), **not** `String.to_existing_atom` — the
  literal table is the `:awaiting_children` atom's **creation site** (guaranteeing it exists at runtime without
  depending on another module to create it), and an unexpected wire string answers a typed
  `{:error, {:unknown_state, state}}`, never an open `to_existing_atom` raise. **`awaiting_children` does NOT join
  `@set_states`** (`~w(pending active schedule dead)`, `metrics.ex:23`) — it is a row-field state with **no
  ZSET**, so the `counts`/`get_counts` scenario (which refuses an *unregistered name*) stays byte-unchanged. Only
  the `@state_lookup` tail + the `@lookup_states` table + the typespec change.
- **EMQ.3.1-D5 — the conformance scenarios (additive minor — AS-BUILT 43 → 45):** `flow_add` (a parent + 2
  children → 3 distinct `JOB…` ids; the 2 children claimable; the parent `:empty` with `:dependencies` = 2; the
  parent row `awaiting_children`; a cross-queue child rejected) and `flow_fanin` (claim the parent → `:empty`
  until the Nth child completes, claimable after; the `:processed` subkey records the children; a double-complete
  decrements exactly once). Registered in `scenarios/0` **with their probes in the same change**; the prior **43**
  conformance scenarios pass **byte-unchanged** (the additive-minor law `N_prior → N_prior+2`, here **43 → 45**);
  the count is re-pinned **43 → 45** in **both** pinning tests (`conformance_scenarios_test.exs` "forty-five names
  in run order" + `conformance_run_test.exs` `{:ok, 45}`). As-built: `Conformance.run/2` prints `CONFORMANCE
  45/45`.
- **EMQ.3.1-D6 — the proof:** the `:valkey` + process flow suites green per-app; the process/mint-touching flow
  suite (the multi-id mint + the fan-in across completions) under the **≥100-iteration determinism loop** owning
  the machine (one green run is NOT proof — the master-invariant hazard); the prior emq.1 + emq.2.{1,2,3,4}
  suites + `Conformance.run/2` pass **unchanged** (no regression); honest-row reporting (Valkey on 6390 the
  truth row); **Apollo re-runs the whole ladder + the loop independently** (MANDATORY — the `@complete` edit +
  the multi-id mint). The hang-on-dead-child limit (a flow child that dies to `dead` does not decrement its
  parent — **Out**, emq.3.4) is documented as the honest bound, not papered over.

## Invariants (runnable checks)

- **EMQ.3.1-INV1 — the wire law (no break, no new type/class/transport).** emq.3.1 adds **no §6 key type**
  outside the grammar (the flow keys are the already-registered `job:<id>:{dependencies,processed}` subkeys);
  **no new wire class** (the kind law reuses `EMQKIND`; the cross-queue-child rejection is a host-side guard or
  an existing class — never a new fence code); **no `SSUBSCRIBE`/new transport** (the flow rides the shipped
  connector). The five-code fence union stands unextended. *Check:* a grep of `@enqueue_flow` + the `@complete`
  hook for any key not matching the §6 grammar returns empty; `keyspace.ex`'s grammar is unedited.
- **EMQ.3.1-INV2 — declared keys, self-justified (the A-1 law).** Every Lua key in `@enqueue_flow` + the
  `@complete` fan-in hook is in `KEYS[]` or derived from a declared `KEYS[n]` root by the §6 grammar; **no key
  is read out of a data value** (the parent's `:dependencies` key is a declared `KEYS[n]`, NEVER a `parent_key`
  read out of the child's hash — the v1 form is not lifted). *Check:* the A-1 lint over the new/edited scripts
  passes; a reviewer names the declared `KEYS[n]` root of every key touched; a grep for a hash-field-to-key
  derivation in the flow path returns empty.
- **EMQ.3.1-INV3 — the shipped surface is byte-unchanged for the non-flow case.** A job with **no parent**
  flows through `@enqueue`/`@claim`/`@complete` exactly as the emq.2 cluster shipped; the fan-in branch in
  `@complete` is reached ONLY when the completing child carries a parent reference; the shipped `@claim` and
  `@enqueue` are **byte-unchanged**. *Check:* the emq.1 + emq.2.{1,2,3,4} suites + `Conformance.run/2` pass
  unchanged; the prior conformance scenarios are byte-identical (git-verified); a `git diff` of `@enqueue`/
  `@claim` is empty.
- **EMQ.3.1-INV4 — the fan-in gate is sound (a parent is in `pending` IFF its `:dependencies` is zero), and the
  new state is byte-safe against `unknown_state`.** A parent with N children is **never** in `pending` while
  `:dependencies` > 0, and **is** in `pending` once it reaches 0; `get_job_state/3` reads `awaiting_children`
  while waiting and `pending` after release, and the shipped `unknown_state` verdict is **untouched** (a
  row-in-no-set whose `state` field is **not** `"awaiting_children"` still reads `'unknown'` — the row-FIELD
  branch, D4). *Check:* the `flow_fanin` `:valkey` scenario — `claim` the parent answers `:empty` until the Nth
  child completes, claimable after; the parent's row reads `awaiting_children` throughout; the parent is not a
  `pending` member while waiting (`ZSCORE pending <parent>` is nil); **and the shipped `unknown_state` scenario
  still answers `{:ok, :unknown}` byte-unchanged** (the regression the row-field branch must not cause).
- **EMQ.3.1-INV5 — the decrement is idempotent (exactly-once fan-in per child).** A child decrements its
  parent's `:dependencies` **exactly once**, even under a redelivered/double completion (the Fork B guard — the
  decrement is gated on the child's own `active`→done transition succeeding, so a second completion of an
  already-completed child does not decrement again). *Check:* a `:valkey` scenario completes a child twice
  (the second a stale-token or already-completed retry) and asserts the parent's count dropped by exactly 1; the
  ≥100 loop surfaces any race.
- **EMQ.3.1-INV6 — branded identity + determinism.** Every flow node (parent + each child) is keyed through
  `Keyspace.job_key/2` (gates `BrandedId.valid?/1`, raises before any wire); a flow of N children mints **N+1
  distinct** branded `JOB` ids in mint order; the mint-touching flow suite runs under the **≥100-iteration
  determinism loop** owning the machine (one green run is NOT proof — a flow mints many ids per call, the
  collision-prone surface). *Check:* `flow_add` reads N+1 distinct `JOB…` ids; an ill-formed id raises at the
  key builder; the ≥100 loop is green.
- **EMQ.3.1-INV7 — the additive-minor conformance law.** `flow_add` + `flow_fanin` are registered in
  `scenarios/0` **with their probes in the same change**; the prior scenarios pass **byte-unchanged**; the count
  re-pins in **both** pinning tests. *Check:* the git-diff shows only additions to `scenarios/0`; both pin tests
  assert the new total; `Conformance.run/2` prints the new line count.
- **EMQ.3.1-INV8 — slot soundness (single-queue is atomic).** Every key `@enqueue_flow` + the `@complete`
  fan-in hook touch shares **one** `{q}` slot (parent and children in the same queue), so every flow script is
  **atomic** (one slot, one EVAL); a cross-queue child spec is rejected at `add/3` (it would break this
  invariant — the cross-queue flow is emq.3.3). *Check:* `@enqueue_flow` declares keys of exactly one `{q}`; a
  cross-queue child spec answers the typed/host-side rejection; no flow script claims atomicity across slots.
- **EMQ.3.1-INV9 — the family boundary + the honest bounds.** emq.3.1 ships the **single-queue, one-level,
  write-side** flow only — no cross-queue (emq.3.3), no child-result read API (emq.3.2), no failure policy
  (emq.3.4), no bulk (emq.3.4), no deep recursion; it re-ships no emq.2 surface and pre-empts no Movement-II
  family. Its **four honest bounds** are **documented**, never silently dropped: (a) the **hang-on-dead-child**
  limit (a child to `dead` does not decrement its parent → the parent hangs `awaiting_children` until emq.3.4
  adds the failure policy); (b) **O1** — the `:processed` value is a **presence marker** (`child_id → child_id`),
  not a result payload (the real write + read are emq.3.2); (c) **O2** — the `parent_of` `HGET` runs on **every**
  completion (a correctness-neutral perf follow-up emq.3.2 folds into the claim result); (d) **L-5** — the flow
  subkeys **outlive** the parent row (correct — `:processed` must survive for emq.3.2's read; the cleanup is an
  emq.3.x concern). *Check:* the deliverable touch-set is single-queue flow only; a triad note + a test record the
  dead-child limit (a flow with a dead child leaves the parent `awaiting_children`, asserted, not papered over);
  the body's honest-bounds paragraph records O1/O2/L-5.

## Definition of Done

- [x] EMQ.3.1-D1: Fork A settled by the Operator (Arm A recommended / Arm B if ruled), recorded BEFORE any build
      artifact (the gate that opens the build); Forks B/C recorded with recommendations (cheap pre-build
      re-scopes); the triad re-derived to the ruled arms at the pre-build reconcile.
- [x] `EchoMQ.Flows.add/3` + `@enqueue_flow` built (D2): a parent + same-queue children enqueued atomically;
      N+1 distinct gated branded ids; children claimable; the parent `awaiting_children` + `:dependencies` = N,
      withheld from `pending`; a cross-queue child spec rejected.
- [x] The fan-in hook on `@complete` built (D3 — HIGH-RISK): the idempotent decrement + the at-zero release +
      the `:processed` record; the non-flow path byte-unchanged; the shipped `@claim` untouched.
- [x] The `awaiting_children` row state threaded (D4): `Metrics.get_job_state/3` reports it distinctly.
- [x] `flow_add` + `flow_fanin` registered (D5, additive minor): the prior conformance set byte-unchanged; the
      count re-pinned in both pinning tests.
- [x] The proof (D6): the `:valkey` + process flow suites green per-app; the **≥100 determinism loop** green for
      the mint/process-touching flow suite; the emq.1 + emq.2.{1,2,3,4} suites + `Conformance.run/2` pass
      unchanged (no regression — INV3); honest-row reporting (Valkey on 6390); the hang-on-dead-child limit
      documented (INV9); **Apollo MANDATORY** — the dedicated evaluator re-ran the whole ladder + the loop
      independently and re-verified the byte-unchanged conformance + the byte-unchanged `@enqueue`/`@claim`.
- [x] INV1–INV9 verified as runnable checks; the spec body remains authoritative and the as-built reconcile
      syncs it post-build.

Stories: [`./emq.3.1.stories.md`](emq.3.1.stories.md) · Agent brief: [`./emq.3.1.llms.md`](emq.3.1.llms.md)
· Runbook: [`./emq.3.1.prompt.md`](emq.3.1.prompt.md) · Family: [`./emq.3.md`](../emq.3.md) (the contract, the
carve, the forks — authoritative for the family) · The v1 capability reference (READ-ONLY, the form NOT to
lift): `echo/apps/echomq/lib/echomq/flow_producer.ex` (`add/2` — the parent + children shape; the data-value
`parent_key`/`parent_info` tree NOT lifted) + the dependency-subkey names at
`echo/apps/echomq/priv/scripts/moveToFinished-15.lua:140-141` · As-built floor (the build target + the A-1
precedent): `echo/apps/echo_mq/lib/echo_mq/jobs.ex` (`@enqueue` the kind-law/declared-keys shape, `@complete`
the fan-in hook host + the `was_active` guard, `@extend_locks` the `base .. 'job:' .. id` declared-root
derivation, `add_log/5` the `<> ":logs"` subkey-compose precedent) + `keyspace.ex` (`job_key/2` the gated
builder, `queue_key/2`) + `metrics.ex` (`get_job_state/3` + `@state_lookup` the row-field branch — D4) + `conformance.ex` (the
scenario set the additive-minor law grows — re-probe the live count) · Design:
[`../emq.design.md`](../../../emq.design.md) §11.10 (the deferral + the owed design), §6 (the grammar — the flow
subkeys + the totality property), §5 (no new wire class), S-6 (the A-1 law), S-1/§6 (the braced keyspace — the
slot constraint), §11.12 (the escalation protocol) · Roadmap: [`../emq.roadmap.md`](../../../emq.roadmap.md) Movement
I (the parity thesis) · The feature catalog: [`../emq.features.md`](../../../emq.features.md) (the emq.3 row) ·
Approach: [`../../elixir/specs/specs.approach.md`](../../../../elixir/specs/specs.approach.md)
