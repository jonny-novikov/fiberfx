# EMQ.3.4 · user stories — the flow failure-policy + bulk add (the fourth sub-rung)

> Who wants the flow failure-policy + bulk add, what they need, and how we knew it works. **SHIPPED 2026-06-15
> (every story PASSED — Apollo Y-4); the Given/When/Then below are the acceptance criteria the build was verified
> against.** Each story is Connextra with Given/When/Then acceptance, an INVEST line naming the invariant(s) it
> encodes, and a Priority/Size/Implements line; the file ends with a Coverage line mapping every Deliverable to ≥1
> story. The standing **`EMQ.3.4-US-GATE`** carries the Valkey gate (design §7) — a structural gate. emq.3.4 closes
> the flow family's **failure half**: a flow parent was released only when a child **COMPLETES**, so a child that
> **DIES** (`@retry`'s dead-letter arm, `jobs.ex:281-303` as-built) left the parent **hanging forever** — emq.3.4
> closes that. It adds the v1 failure-policy options — `fail_parent_on_failure` (the parent fails too) and
> `ignore_dependency_on_failure` (the parent proceeds, the failure recorded) — over the **already-§6-reserved**
> `:failed`/`:unsuccessful` subkeys, plus `add_bulk/3` (N flows in one call). The cross-queue failure rides the
> **same** `flow:outbox` + sweep emq.3.3 founded, so it is **eventually-consistent** (delivered on the next sweep
> tick, never synchronously, never "atomic across queues") and **idempotent** (a re-delivered fail is a no-op).
> **HIGH-risk** — a shipped `@retry` edit (the existing dead-letter body byte-frozen) → Apollo MANDATORY.

## EMQ.3.4-US1 — the grandchildren scope fork is settled before the build

As a **program Director**, I want the one open scope question (does emq.3.4 include grandchildren / deep
recursion, or is that a separate later rung?) ruled before emq.3.4 builds, so that the rung's scope is
**decided, recorded, and the triad authored to it** — not improvised mid-build.

Acceptance criteria
- Given the family carve ([`./emq.3.md`](../emq.3.md):198) scopes emq.3.4 to "failure-policy + bulk" while the
  frozen emq-3-3 ledger (D-5a) lumped grandchildren with it, when emq.3.4 opens, then the **V-1 scope fork** is
  surfaced to the Director with both arms steelmanned + a recommendation (Arm A: failure-policy + bulk;
  grandchildren a separate rung, emq.3.5), and **no build artifact exists** until it is ruled.
- Given the fork is **RULED → Arm A** (the Director, recorded as **D-2** in the `emq-3-4` ledger), when emq.3.4
  builds, then the build's touch-set is exactly the failure-policy + bulk deliverables (no recursive-tree add, no
  multi-level fan-in), and **grandchildren is the locked Out → emq.3.5**.
- Given Arm B (grandchildren joins emq.3.4) was the steelmanned alternative, when the ruling is examined, then it
  was a **cheap re-scope** that would have only **ADDED** the grandchildren deliverables — the failure-policy
  core (the `@retry` branch, the fail-deliver, the policy flags) is identical either way — so the Arm-A ruling
  costs the Operator nothing it cannot still choose later.

INVEST — independent (the scope gate that precedes the build); testable by the ledger record (V-1 + the
Director's ruling) + the build's touch-set; encodes EMQ.3.4-INV11. Priority: must · Size: 1 · Implements:
EMQ.3.4-D1.

## EMQ.3.4-US2 — a consumer adds a flow with failure policy (and adds flows in bulk)

As a **bus consumer building a flow**, I want to declare per-child what happens when a child fails — the parent
fails too (the default), or the parent ignores that dependency and proceeds — and to submit many flows in one
call, so that my flow's failure behaviour is **explicit** and bulk submission is **one round-trip**.

Acceptance criteria
- Given a flow `%{parent: …, children: [%{…, fail_parent_on_failure: true | false,
  ignore_dependency_on_failure: true | false}]}`, when `EchoMQ.Flows.add/3` is called, then each child's policy
  is recorded — a **same-queue** child needs no new field, a **cross-queue** child's row carries a new
  **`parent_policy`** field (alongside the emq.3.1 `parent` + emq.3.3 `parent_queue`) — and the flow lands by the
  existing mechanism (same-queue atomic; cross-queue host-orchestrated parent-first).
- Given the default, when no policy flag is set, then `fail_parent_on_failure` defaults to `true` (the v1
  default — a failed child fails the parent) and `ignore_dependency_on_failure` defaults to `false`.
- Given a list of flows, when `EchoMQ.Flows.add_bulk/3` is called, then each flow lands by the existing `add/3`
  mechanism (pipelined), the call returns `{:ok, [{parent_id, [child_id]}]}`, and the add is **fail-closed per
  flow** (a flow that fails to land leaves its own parent HELD — the emq.3.3 B2 add-side honesty, per flow).
- Given an **ill-formed** id (any parent or child, any flow), when `add/3`/`add_bulk/3` is called, then it
  **raises** at `Keyspace.job_key/2` (the gated key builder) before any wire.

INVEST — independent (the failure-policy options + bulk add capability); testable by a `:valkey` scenario adding
a flow with each policy (asserting the cross-queue child carries `parent_policy`) + an `add_bulk/3` of N flows
(asserting N parents land + the per-flow fail-closed) + an ill-formed-id raise; encodes EMQ.3.4-INV4,
EMQ.3.4-INV11. Priority: must · Size: 3 · Implements: EMQ.3.4-D2.

## EMQ.3.4-US3 — a failed child no longer hangs its parent (the gap closed)

As a **bus operator running flows**, I want a flow whose child **dies** to **terminate** — the parent fails (the
default) or proceeds past the ignored failure — instead of hanging in `awaiting_children` forever, so that one
poison child can never stall a flow indefinitely.

Acceptance criteria
- Given a flow with `fail_parent_on_failure` (the default), when a **same-queue** child exhausts its retries and
  lands in the morgue (`@retry`'s dead-letter arm), then — atomically in the same EVAL — the child is recorded in
  the parent's `:failed` subkey AND the parent is moved to `dead` (the parent's `:dependencies`/`pending`
  membership cleared as the morgue transition requires); the parent is **NOT** left in `awaiting_children`.
- Given a flow with `ignore_dependency_on_failure`, when a same-queue child dies, then — atomically — the child
  is recorded in the parent's `:unsuccessful` subkey AND the parent's `:dependencies` is **DECR**'d (as if the
  child were satisfied); at zero the parent is released to `pending` (the satisfy-and-release, mirroring the
  `@complete` fan-in's at-zero release).
- Given the same-queue failure propagation, when the `@retry` `git diff` is examined, then the **existing
  dead-letter body** (`jobs.ex:254-259` — the FULL five statements `HSET last_error`/`HSET state 'dead'`/
  `ZADD <dead>`/**`HINCRBY metrics:failed`**/`return 'dead'`) and the schedule arm are **byte-identical**; the new failure branch runs **after** the existing morgue transition (the child
  lands in its own morgue first, then the parent is notified) and fires **only** when the host supplies the
  parent-fail keys (a key the shipped `retry` callers never pass).

INVEST — independent (the same-queue failure propagation — the gap closed); testable by the `flow_fail_parent`
`:valkey` scenario (same-queue: child dies → parent `dead`, `:failed` holds the child) + the `flow_ignore_dep`
scenario (same-queue: child dies → parent proceeds, `:unsuccessful` holds the child) + the `@retry` byte-diff
(only-added-lines, the dead-letter body `:254-259` byte-frozen); encodes EMQ.3.4-INV5, EMQ.3.4-INV6,
EMQ.3.4-INV3, EMQ.3.4-INV1. Priority: must · Size: 5 · Implements: EMQ.3.4-D3.

## EMQ.3.4-US4 — a cross-queue child's death reaches its parent (eventually-consistent, durable, idempotent)

As a **bus operator running a cross-queue flow**, I want a cross-queue child's **death** to reach the parent — on
the **next sweep tick**, durably, and exactly once — so that cross-queue flows terminate on failure the same way
same-queue flows do, with the same honesty the cross-queue completion has.

Acceptance criteria
- Given a **cross-queue** flow child (its row carries `parent_queue` + `parent_policy`), when it dies (`@retry`
  past `max_attempts`), then the `@retry` **cross-flow branch** RPUSHes a **fail-entry** (a distinct KIND beside
  the emq.3.3 complete-entry — carrying `parent_queue`, `parent_id`, `child_id`, the error, the policy) into the
  child's own-slot `emq:{C}:flow:outbox` **atomically with the dead-letter transition** — **one EVAL on the
  child's slot {C}**; before any sweep, the outbox holds the fail-entry AND the child is in its own queue's morgue
  (`dead`) — so a dead cross-queue child **always** has a durable signal (no drop window).
- Given the fail-entry in the outbox, when the child queue's `EchoMQ.Pump.sweep/1` runs its existing third pass
  `deliver_flow_completions`, then it drains the entry and — recognizing the fail KIND — issues a
  **`@flow_fail_deliver`** EVAL on the **parent's slot** (the parent key rebuilt host-side via
  `Keyspace.job_key(parent_queue, parent_id)`) that, by the entry's policy, fails the parent (record `:failed`,
  move `dead`) or satisfies-and-records (record `:unsuccessful`, DECR `:dependencies`, at-zero release); the
  existing complete-deliver `@flow_deliver` is **byte-unchanged**.
- Given a cross-queue child dies but **before** any sweep tick, when the parent is examined, then the parent is
  **unchanged** (still `awaiting_children`; `dependencies/3` unchanged) — the death alone does **NOT**
  fail/satisfy the parent (eventually-consistent, never synchronous, never "atomic across queues").
- Given the **same** fail-entry is delivered **twice** (a sweep crash AFTER the deliver, BEFORE the
  outbox-clear), when the second deliver runs, then it is a **no-op** (`HSETNX` of the child into
  `:failed`/`:unsuccessful` returns 0 → no second parent-fail / no second DECR) — the parent is
  failed-or-satisfied **exactly once**.

INVEST — independent (the cross-queue fail-deliver — durable, eventually-consistent, idempotent); testable by the
`flow_fail_parent`/`flow_ignore_dep` `:valkey` scenarios in their **cross-queue** form (child dies → fail-entry
in outbox + child `dead` pre-sweep → parent unchanged pre-sweep → sweep → parent failed/proceeded; a double
fail-deliver is a no-op) + the `@flow_deliver` byte-unchanged check; encodes EMQ.3.4-INV8 (no-drop),
EMQ.3.4-INV7 (idempotent), EMQ.3.4-INV5/INV6 (the cross-queue forms), EMQ.3.4-INV2 (slot soundness). Priority:
must · Size: 5 · Implements: EMQ.3.4-D4.

## EMQ.3.4-US5 — a parent handler reads which children were ignored-on-failure

As a **flow parent's handler**, I want to read which of my children were **ignored on failure** (and why),
distinct from which **completed** with a result, so that I can branch on the partial outcome (the v1
`get_ignored_children_failures` parity).

Acceptance criteria
- Given a parent whose flow used `ignore_dependency_on_failure`, when `EchoMQ.Flows.ignored_failures/3` is called,
  then it returns `{:ok, %{child_id => error}}` — a pure `HGETALL` of the parent's `:unsuccessful` subkey (the v1
  `get_ignored_children_failures` parity), composed via `Keyspace.job_key(queue, parent_id) <> ":unsuccessful"`
  (the `children_values/3` `<> ":processed"` precedent).
- Given a parent with **no** ignored failures, when `ignored_failures/3` is called, then it returns `{:ok, %{}}`.
- Given the two reads, when both are called, then `children_values/3` (the `:processed` results) and
  `ignored_failures/3` (the `:unsuccessful` failures) are **disjoint** — a child is in `:processed` XOR
  `:unsuccessful`, never both (it either completed or was ignored-on-failure; a `fail_parent_on_failure` death
  lands in `:failed` and fails the parent, in neither read).

INVEST — independent (the ignored-failures read — the read half, NORMAL-risk, no script); testable by a
`:valkey` scenario reading `ignored_failures/3` after an `ignore_dependency_on_failure` death (the ignored child
present) + the empty-parent `{:ok, %{}}` + the `:processed`/`:unsuccessful` disjointness; encodes EMQ.3.4-INV6.
Priority: should · Size: 2 · Implements: EMQ.3.4-D6.

## EMQ.3.4-US6 — the new failure subkeys' lifecycle is named, not discovered

As a **future maintainer of the flow family**, I want the newly-populated `:failed`/`:unsuccessful` subkeys'
cleanup disposition named in the spec body (not discovered later as production accumulation), so that the
deferred lifecycle rung knows to retire them — the §2 subkey-lifecycle guardrail (the emq.3.1 L-5 lesson).

Acceptance criteria
- Given emq.3.4 populates `emq:{q}:job:<id>:failed` and `…:unsuccessful` (already §6-reserved —
  `emq.design.md:307` — so no grammar edit), when the spec body is read, then it **names** their cleanup home:
  both FIXED-list destructive sweeps (`obliterate`'s `del_job` `admin.ex:152` **and** `@drain`'s `wipe()`
  `admin.ex:90`) gaining `:failed`/`:unsuccessful`, routed to the **emq.3.x lifecycle rung** — joining the
  emq.3.2-N1 `:dependencies`/`:processed` + emq.3.3-B5 `flow:outbox` carry.
- Given they **persist** past the parent row (unlike the self-clearing `flow:outbox`), when the at-rest concern
  is examined, then they are recorded as a NAMED carry (like `:dependencies`/`:processed`), retired by the
  lifecycle rung's sweep.
- Given emq.3.4's scope, when its touch-set is examined, then it adds **ZERO** cleanup (no `DEL`/`HDEL`/`UNLINK`
  of a flow subkey) and `admin.ex` is **untouched**.

INVEST — independent (the lifecycle-naming guardrail); testable by the body naming the subkeys' cleanup home +
the owning rung, the touch-set containing no flow-subkey deletion, and `admin.ex` untouched; encodes
EMQ.3.4-INV10. Priority: must · Size: 1 · Implements: EMQ.3.4-D5.

## EMQ.3.4-US7 — the failure behaviour is conformance-proven and regression-bounded

As a **program maintainer**, I want `flow_fail_parent`, `flow_ignore_dep`, and `flow_add_bulk` registered in the
conformance set with their probes in the same change, the prior 47 scenarios byte-unchanged, and the `@retry`
existing dead-letter body byte-frozen, so that the failure-policy does not silently regress the wire and the
HIGH-risk shipped-script edit is **proven** purely additive.

Acceptance criteria
- Given `flow_fail_parent`/`flow_ignore_dep`/`flow_add_bulk` are added to `EchoMQ.Conformance.scenarios/0` with
  their `apply_scenario` probes, when the suite runs, then the prior **47** scenarios pass **byte-unchanged**
  (name + contract + verdict body, git-verified) and the count re-pins **47 → 50** in **both** pinning tests;
  `Conformance.run/2` returns `{:ok, 50}`.
- Given the HIGH-risk shipped-script edit, when the `@retry` `git diff` is examined, then it shows **only ADDED
  lines** (the new cross-flow failure branch); the existing dead-letter body (`jobs.ex:254-259`) + the schedule
  arm are **byte-identical**; `@complete` (incl. the fan-in `:212-219` + the cross-queue emit `:205-206`) and
  `@flow_deliver` are **byte-unchanged**; the emq.1 + emq.2.{1,2,3,4} + emq.3.{1,2,3} suites + `Conformance.run/2`
  pass unchanged.
- Given the cross-slot risk (the engine on 6390 is single-node and will **not** catch a cross-slot key), when the
  new scripts are reviewed, then a **declared-keys grep** confirms the same-queue failure branch + the
  cross-queue fail-emit pass only child-slot `{C}` keys and `@flow_fail_deliver` passes only parent-slot `{P}`
  keys (no cross-slot key — the F-1 trap), and **Apollo's explicit byte-check** + the ≥100 determinism loop
  ratify it.

INVEST — independent (the conformance + regression + cross-slot proof); testable by the three new scenarios +
both pin tests at 50 + the `@retry` byte-diff (only-added-lines) + the declared-keys grep + Apollo's verdict;
encodes EMQ.3.4-INV9, EMQ.3.4-INV1, EMQ.3.4-INV2, EMQ.3.4-INV3. Priority: must · Size: 3 · Implements:
EMQ.3.4-D7.

## EMQ.3.4-US-GATE — the Valkey gate (the standing structural story)

As a **program maintainer**, I want the standing Valkey gate to hold on emq.3.4, so that the flow failure-policy
is proven on the engine of record with honest-row reporting and the protocol invariants intact.

Acceptance criteria
- Given a live Valkey on **6390** (`redis-cli -p 6390 ping` → `PONG`), when the emq.3.4 `:valkey` failure suite +
  `Conformance.run/2` run, then every scenario passes and `run/2` returns `{:ok, 50}`; a host without Valkey runs
  the probes elsewhere and reports them as **that** row, never the truth row (honest-row reporting, S-4, design
  §7).
- Given the protocol invariants, when the gate runs, then: every key of the same-queue failure branch + the
  cross-queue fail-emit carries the **child's** hashtag and every key of `@flow_fail_deliver` carries the
  **parent's** hashtag (slot soundness, INV2); the new failure keys are **declared-or-rooted** (the A-1 law); the
  `:failed`/`:unsuccessful` subkeys are §6-reserved (no grammar edit — INV1); the `{emq}:version` record reads
  `echomq:2.0.0` (the fence unbroken); and the cross-queue failure is observed **eventually-consistent** (the
  parent failed/proceeded on the sweep tick, never synchronously — INV5/INV6).
- Given the ≥100-iteration determinism loop owning the machine, when the mint/process-touching cross-queue
  failure scenario runs 100+ times, then it is **green every iteration** (a cross-queue flow mints a parent + N
  children across queues — the same-millisecond mint hazard surfaces only across runs).

INVEST — independent (the standing gate, every rung); testable by the `:valkey` suite + `Conformance.run/2` ==
`{:ok, 50}` on 6390 + the ≥100 loop + the slot/declared-keys/fence checks; encodes the design §7 gate + S-4 +
EMQ.3.4-INV1, EMQ.3.4-INV2, EMQ.3.4-INV5, EMQ.3.4-INV6, EMQ.3.4-INV9. Priority: must · Size: 1 · Implements:
EMQ.3.4-D7 (the proof) — the standing gate.

## Coverage

Every Deliverable maps to ≥1 story (and every story to ≥1 invariant):

| Deliverable | Story(ies) | Invariant(s) exercised |
|---|---|---|
| **D1** — the scope gate (V-1 grandchildren fork ruled) | US1 | INV11 |
| **D2** — the failure-policy options + `add_bulk/3` (host-orchestrated, fail-closed per flow) | US2 | INV4, INV11 |
| **D3** — the same-queue failure propagation (the additive `@retry` branch, dead-letter body byte-frozen) | US3 | INV5, INV6, INV3, INV1 |
| **D4** — the cross-queue fail-deliver (the `flow:outbox` fail-entry + `@flow_fail_deliver`, idempotent) | US4 | INV8, INV7, INV5, INV6, INV2 |
| **D5** — the lifecycle disposition (the `:failed`/`:unsuccessful` cleanup NAMED, deferred) | US6 | INV10 |
| **D6** — the ignored-failures read (`ignored_failures/3`, host-only) | US5 | INV6 |
| **D7** — the proof (conformance 47→50, regression bound, ≥100 loop, Apollo MANDATORY) | US7, US-GATE | INV1, INV2, INV3, INV5, INV6, INV9 |

The standing **EMQ.3.4-US-GATE** carries the Valkey gate (design §7) for every rung — a structural gate. Every
invariant INV1–INV11 is exercised by ≥1 story; every Deliverable D1–D7 is covered. The headline observable — a
failed child no longer hangs its parent (the parent **fails** or **proceeds**), and the cross-queue failure is
**eventually-consistent** (delivered on the sweep tick, never "atomic across queues"), **durable** (no drop
window), and **idempotent** (a re-delivered fail is a no-op) — is stated in US3 + US4 + US-GATE (INV5/INV6/INV7/
INV8) and is the acceptance face of the failure half emq.3.4 closes.
