# EMQ.3.3 · user stories — the cross-queue flow (the third sub-rung)

> Who wants the cross-queue flow, what they need, and how we will know it works. Each story is Connextra with
> Given/When/Then acceptance, an INVEST line naming the invariant(s) it encodes, and a Priority/Size/Implements
> line; the file ends with a Coverage line mapping every Deliverable to ≥1 story. The standing
> **`EMQ.3.3-US-GATE`** carries the Valkey gate (design §7) — a structural gate. emq.3.3 crosses the slot
> boundary the v1 flow lived on: a parent and its DIRECT children in **different queues**, fanned in by a
> **completion-signal hop** (the child emits to a durable outbox on its own slot; a per-queue sweep delivers the
> decrement to the parent's slot). The fan-in is **eventually-consistent** — the observable everywhere is the
> parent released **on the next sweep tick**, **never** synchronously, **never** "atomic across queues." Delivery
> is **at-least-once made effectively-once** (a re-delivered completion is a no-op). **HIGH-risk** — a shipped
> `@complete` edit (the single-queue fan-in branch byte-frozen) + a new cross-slot mechanism → Apollo MANDATORY.

## EMQ.3.3-US1 — the cross-queue forks are settled before the build

As a **program Director (delegated authority, 2026-06-15)**, I want the four cross-queue forks (the signal-key
shape, the sweep cadence, the crash-recovery model, the shipped-script touch) ruled before emq.3.3 builds, so
that the rung does not improvise its cross-slot consistency model — the outbox-on-the-child's-slot, the piggybacked
sweep, the `:processed` idempotency guard, and the additive `@complete` branch are **decided, recorded, and the
triad authored to them**.

Acceptance criteria
- Given the rung's ledger surfaces the four forks (V-1..V-4) with both arms steelmanned and a recommendation,
  when emq.3.3 opens, then **no build artifact exists** until the four forks are ruled (D-1..D-4) + the scope
  bound locked (D-5).
- Given the forks are ruled to the recommended arms (D-1 outbox-on-child's-slot · D-2 piggyback `Pump.sweep/1` ·
  D-3 the `:processed` HSETNX guard · D-4 the additive `@complete` branch), when emq.3.3 builds, then the build's
  touch-set matches the ruled arms — the outbox is on the **child's** slot, the deliver is a **Pump** pass, the
  deliver is **idempotent** via `:processed`, and `@complete`'s single-queue branch is **byte-frozen**.
- Given Fork 4 was the flagged judgment call (an additive `@complete` branch vs a separate `@complete_xq`), when
  it is ruled, then the ruling is **deliberate** (recorded with its decisive argument: atomic emission requires
  the emit inside the `@complete` EVAL, so a byte-frozen `@complete` would re-open the drop window) — not
  defaulted.

INVEST — independent (the gate that precedes every build story); testable by the ledger record (D-1..D-5) + the
build's touch-set; encodes EMQ.3.3-INV1, EMQ.3.3-INV3, EMQ.3.3-INV7. Priority: must · Size: 1 · Implements:
EMQ.3.3-D1.

## EMQ.3.3-US2 — a consumer adds a cross-queue flow

As a **bus consumer running a cross-queue pipeline**, I want to add a flow whose parent and children live in
**different queues** (a parent in `orders`, children in `validation` / `inventory` / `payments` — the v1 shape),
so that the parent runs after its legs complete **even when the legs run in other queues**, without my tracking
each leg myself.

Acceptance criteria
- Given a flow `%{parent: %{id, payload}, children: [%{id, payload, queue: other}]}` where a child's `:queue`
  differs from the parent's, when `EchoMQ.Flows.add/3` is called, then the flow is **admitted** (the
  `reject_cross_queue/2` host-refusal is gone) and returns `{:ok, {parent_id, [child_id]}}`.
- Given the cross-queue add, when it lands, then the **parent lands FIRST** (held, `state = awaiting_children`,
  `:dependencies` = N, on the parent's slot) and **then** each child lands on **its own slot**, its row carrying
  the `parent` field (the bare parent id) **plus** a `parent_queue` field (the parent's queue) — the add is
  **host-orchestrated and NON-atomic across slots** (no single `@enqueue` spans the children's slots).
- Given a **partial** add (a child fails to land cross-slot), when the add returns, then the parent is left
  **HELD** (never claimable, never spuriously executed) and is **host-retryable by id** (fail-closed) — the
  parent-first order guarantees the `:dependencies` counter exists before any child can complete.
- Given an **ill-formed** id (parent or any child), when `add/3` is called, then it **raises** at
  `Keyspace.job_key/2` (the gated key builder) before any wire.

INVEST — independent (the cross-queue add capability); testable by a `:valkey` scenario adding a cross-queue flow
(asserting the parent held on its slot with `:dependencies` = N + each child claimable on its own slot carrying
`parent_queue`), a partial-add fail-closed assertion, and an ill-formed-id raise; encodes EMQ.3.3-INV4,
EMQ.3.3-INV5 (add-side B2), EMQ.3.3-INV10. Priority: must · Size: 3 · Implements: EMQ.3.3-D2.

## EMQ.3.3-US3 — a cross-queue child's completion is durably signalled

As a **bus operator**, I want a cross-queue child's completion to be **durably recorded the instant it
completes** (not lost if a process crashes before the parent is updated), so that the parent's release is
**guaranteed** even across a crash — the at-least-once foundation.

Acceptance criteria
- Given a cross-queue child (its row carries `parent_queue`), when it completes (`complete/5`), then the host
  supplies the outbox key `emq:{C}:flow:outbox` and the `@complete` **cross-queue branch** RPUSHes the entry
  `(parent_queue, parent_id, child_id, result)` into the outbox **atomically with the active-set ZREM** — **one
  EVAL on the child's slot {C}**.
- Given the completion, when the one EVAL runs, then **both** effects are observable before any sweep: the child
  is **gone from `active`** AND the outbox holds **exactly one entry** for it — so a completed cross-queue child
  **always** has a durable signal (there is **no state** where the child completed but produced no signal — the
  drop window does not exist).
- Given a **single-queue** flow child or a **non-flow** job, when it completes, then the `@complete` **byte-frozen**
  branches run (the single-queue fan-in branch `jobs.ex:181-188` unchanged; the non-flow path unchanged) — the
  cross-queue branch is **not** reached (it fires only on the host-supplied outbox key).

INVEST — independent (the durable-emit capability — the no-drop guarantee); testable by a `:valkey` scenario
completing a cross-queue child and asserting (before any sweep) the outbox holds its entry AND it is gone from
`active` (one EVAL, both effects) + a single-queue/non-flow completion taking the byte-frozen path; encodes
EMQ.3.3-INV1, EMQ.3.3-INV3, EMQ.3.3-INV7. Priority: must · Size: 3 · Implements: EMQ.3.3-D3.

## EMQ.3.3-US4 — the sweep delivers the decrement and releases the parent (eventually-consistent)

As a **bus operator running a pump on the child queue**, I want the per-queue sweep to drain the outbox and
release a cross-queue parent once **all** its children have completed, so that cross-queue fan-in works — and I
want the contract to be **honest** that the release happens on the **next sweep tick**, never synchronously.

Acceptance criteria
- Given a cross-queue child has completed (its entry in `emq:{C}:flow:outbox`), when the child queue's
  `EchoMQ.Pump.sweep/1` runs its **third pass** `deliver_flow_completions`, then it drains the entry and issues a
  **`@flow_deliver`** EVAL on the **parent's slot** (the parent key rebuilt host-side via
  `Keyspace.job_key(parent_queue, parent_id)`) that records the child in `:processed` (HSETNX) and **DECRs** the
  parent's `:dependencies`; `sweep/1` returns `{:ok, %{promoted, fired, delivered}}`.
- Given a cross-queue child completes but **before** any sweep tick, when the parent is examined, then the parent
  is **still held** (`claim` on the parent's queue answers `:empty`; `dependencies/3` still > 0) — **the
  completion alone does NOT release the parent** (eventually-consistent, never synchronous).
- Given the **last** outstanding child's completion has been delivered (sweep run), when the parent is examined,
  then the parent is **released** to `pending` (claimable; `dependencies/3` == 0; row `state = pending`) — the
  parent moved on the **sweep tick**, not on the completion.
- Given a queue that hosts cross-queue children but runs **no** pump, when its children complete, then their
  outbox entries are **durable** and the parents are **delayed, never dropped** — when a pump is **later** started
  on that queue, the backlog drains and every waiting parent is released (the named recovery, B4).

INVEST — independent (the sweep-deliver + the eventually-consistent release); testable by the `flow_cross_queue`
`:valkey` scenario (a cross-queue flow → child completes → parent **still held** pre-sweep → sweep → parent
**released**) + a pump-absent durability assertion (the outbox survives, a later sweep drains it); encodes
EMQ.3.3-INV5 (the cross-queue honesty headline), EMQ.3.3-INV2, EMQ.3.3-INV10. Priority: must · Size: 5 ·
Implements: EMQ.3.3-D4.

## EMQ.3.3-US5 — a re-delivered completion never double-counts (the crash-recovery keystone)

As a **bus operator**, I want a sweep crash that re-delivers an already-applied completion to be a **no-op**, so
that a parent is **never** released early (before its other children finish) and **never** under-counted — the
at-least-once → effectively-once guarantee.

Acceptance criteria
- Given a cross-queue child's completion has already been delivered (the child recorded in the parent's
  `:processed`, `:dependencies` decremented once), when the **same** completion is delivered **again** (a sweep
  crash AFTER the deliver, BEFORE the outbox-clear, re-runs `@flow_deliver`), then the deliver is a **no-op**:
  `HSETNX` of the child into `:processed` returns 0 → **no DECR** → `:dependencies` is decremented **exactly
  once** total.
- Given a parent with N children, when **all** complete and each is delivered (some re-delivered), then the
  parent is released **exactly once** (not early on a double-count, not twice) — the release fires on the **first**
  delivery that drives `:dependencies` to zero.
- Given the deliver's idempotency, when examined, then it **mirrors the shipped single-queue record-then-decrement**
  (`jobs.ex:181-188`) — the same shape, now gated by HSETNX on the parent's slot, reusing the **existing**
  `:processed` subkey (the emq.3.2 result store).

INVEST — independent (the crash-recovery keystone — the design's correctness centre); testable by the
`flow_cross_queue` `:valkey` scenario running `@flow_deliver` for the same child **twice** and asserting
`:dependencies` decremented **once** + `:processed[child]` = the result + the parent released exactly once + the
second deliver's no-op verdict; encodes EMQ.3.3-INV6, EMQ.3.3-INV3. Priority: must · Size: 3 · Implements:
EMQ.3.3-D4 (the idempotency half of the deliver).

## EMQ.3.3-US6 — the new outbox subkey's lifecycle is named, not discovered

As a **future maintainer of the flow family**, I want the new `flow:outbox` subkey's cleanup disposition named in
the spec body (not discovered later as production accumulation), so that the deferred lifecycle rung knows to
retire it — the §2 subkey-lifecycle guardrail (the emq.3.1 L-5 lesson).

Acceptance criteria
- Given emq.3.3 introduces `emq:{q}:flow:outbox`, when the spec body is read, then it **names** the outbox's
  cleanup home: both FIXED-list destructive sweeps (`obliterate`'s `del_job` `admin.ex:152` **and** `@drain`'s
  `wipe()` `admin.ex:90`) gaining `emq:{q}:flow:outbox`, routed to the **emq.3.x lifecycle rung** — joining the
  emq.3.2-N1 `:dependencies`/`:processed` carry.
- Given the outbox is **self-clearing** in steady state (its own sweep drains it to empty), when the at-rest
  concern is examined, then it is **only** a queue that STOPS being swept — unlike `:dependencies`/`:processed`
  which persist past the parent row.
- Given emq.3.3's scope, when its touch-set is examined, then it adds **ZERO** cleanup (no `DEL`/`HDEL`/`UNLINK`
  of a flow subkey) and `admin.ex` is **untouched**.

INVEST — independent (the lifecycle-naming guardrail); testable by the body naming the outbox's cleanup home +
the owning rung, the touch-set containing no flow-subkey deletion, and `admin.ex` untouched; encodes
EMQ.3.3-INV9. Priority: must · Size: 1 · Implements: EMQ.3.3-D5.

## EMQ.3.3-US7 — the cross-queue behaviour is conformance-proven and regression-bounded

As a **program maintainer**, I want `flow_cross_queue` registered in the conformance set with its probe in the
same change, the prior 46 scenarios byte-unchanged, and the single-queue `@complete` fan-in branch byte-frozen,
so that the cross-queue add does not silently regress the wire and the HIGH-risk shipped-script edit is **proven**
purely additive.

Acceptance criteria
- Given `flow_cross_queue` is added to `EchoMQ.Conformance.scenarios/0` with its `apply_scenario` probe, when the
  suite runs, then the prior **46** scenarios pass **byte-unchanged** (name + contract + verdict body,
  git-verified) and the count re-pins **46 → 47** in **both** pinning tests; `Conformance.run/2` returns
  `{:ok, 47}`.
- Given the HIGH-risk shipped-script edit, when the `@complete` `git diff` is examined, then it shows **only
  ADDED lines** (the new cross-queue branch); the existing non-flow / flat / grouped-lane / single-queue-flow
  branches (`jobs.ex:152-191`) are **byte-identical**; the emq.1 + emq.2.{1,2,3,4} + emq.3.{1,2} suites +
  `Conformance.run/2` pass unchanged.
- Given the cross-slot risk (the engine on 6390 is single-node and will **not** catch a cross-slot key), when the
  new scripts are reviewed, then a **declared-keys grep** confirms the emit branch passes only child-slot keys
  and `@flow_deliver` passes only parent-slot keys (no parent-slot key into the child-slot EVAL — the F-1 trap),
  and **Apollo's explicit byte-check** + the ≥100 determinism loop ratify it.

INVEST — independent (the conformance + regression + cross-slot proof); testable by the `flow_cross_queue`
scenario + both pin tests at 47 + the `@complete` byte-diff (only-added-lines) + the declared-keys grep + Apollo's
verdict; encodes EMQ.3.3-INV8, EMQ.3.3-INV1, EMQ.3.3-INV2, EMQ.3.3-INV3. Priority: must · Size: 3 · Implements:
EMQ.3.3-D6.

## EMQ.3.3-US-GATE — the Valkey gate (the standing structural story)

As a **program maintainer**, I want the standing Valkey gate to hold on emq.3.3, so that the cross-queue flow is
proven on the engine of record with honest-row reporting and the protocol invariants intact.

Acceptance criteria
- Given a live Valkey on **6390** (`redis-cli -p 6390 ping` → `PONG`), when the emq.3.3 `:valkey` cross-queue
  suite + `Conformance.run/2` run, then every scenario passes and `run/2` returns `{:ok, 47}`; a host without
  Valkey runs the probes elsewhere and reports them as **that** row, never the truth row (honest-row reporting,
  S-4, design §7).
- Given the protocol invariants, when the gate runs, then: every key of the emit branch carries the **child's**
  hashtag and every key of `@flow_deliver` carries the **parent's** hashtag (slot soundness, INV2); the new
  cross-queue keys are **declared-or-rooted** (the A-1 law); the `{emq}:version` record reads `echomq:2.0.0`
  (the fence unbroken); and the cross-queue fan-in is observed **eventually-consistent** (the parent released on
  the sweep tick, never synchronously — INV5).
- Given the ≥100-iteration determinism loop owning the machine, when the mint/process-touching cross-queue
  scenario runs 100+ times, then it is **green every iteration** (a cross-queue flow mints a parent + N children
  across queues — the same-millisecond mint hazard surfaces only across runs).

INVEST — independent (the standing gate, every rung); testable by the `:valkey` suite + `Conformance.run/2` ==
`{:ok, 47}` on 6390 + the ≥100 loop + the slot/declared-keys/fence checks; encodes the design §7 gate + S-4 +
EMQ.3.3-INV1, EMQ.3.3-INV2, EMQ.3.3-INV5, EMQ.3.3-INV8. Priority: must · Size: 1 · Implements: EMQ.3.3-D6 (the
proof) — the standing gate.

## Coverage

Every Deliverable maps to ≥1 story (and every story to ≥1 invariant):

| Deliverable | Story(ies) | Invariant(s) exercised |
|---|---|---|
| **D1** — the fork gate (D-1..D-5 ruled) | US1 | INV1, INV3, INV7 |
| **D2** — the cross-queue add (host-orchestrated, parent-first, fail-closed) | US2 | INV4, INV5(add-side B2), INV10 |
| **D3** — the outbox emit (the additive `@complete` branch, single-queue byte-frozen) | US3 | INV1, INV3, INV7 |
| **D4** — the sweep-deliver (`deliver_flow_completions` + `@flow_deliver`, idempotent) | US4 (release, eventually-consistent), US5 (idempotency keystone) | INV2, INV5, INV6, INV10 |
| **D5** — the lifecycle disposition (the outbox cleanup NAMED, deferred) | US6 | INV9 |
| **D6** — the proof (conformance 46→47, regression bound, ≥100 loop, Apollo MANDATORY) | US7, US-GATE | INV1, INV2, INV3, INV5, INV8 |

The standing **EMQ.3.3-US-GATE** carries the Valkey gate (design §7) for every rung — a structural gate. Every
invariant INV1–INV10 is exercised by ≥1 story; every Deliverable D1–D6 is covered. The headline observable —
the cross-queue fan-in is **eventually-consistent**, the parent released **on the sweep tick**, never "atomic
across queues" — is stated in US4 + US-GATE (INV5) and is the acceptance face of INV7's honesty bound.
