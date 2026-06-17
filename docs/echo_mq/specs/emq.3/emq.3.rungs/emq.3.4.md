# EMQ.3.4 · The flow failure-policy + bulk add — the fourth sub-rung (Movement I, the flow family)

> **Status: SHIPPED 2026-06-15** (BUILD-GRADE — the HIGH-risk Apollo MANDATORY pass complete, Y-4; the FOURTH
> sub-rung of the emq.3 parent/flow family — the family contract + the carve are [`./emq.3.md`](../../emq.3.md);
> the first slice [`./emq.3.1.md`](emq.3.1.md) SHIPPED 2026-06-15 at CONFORMANCE 45/45, the second
> [`./emq.3.2.md`](emq.3.2.md) SHIPPED at 46/46, the third [`./emq.3.3.md`](emq.3.3.md) SHIPPED (cross-queue
> flow) at 47/47, and emq.3.4 at **50/50**). emq.3.4 carves the **flow failure-policy + bulk add**: a flow parent
> was released **only** when a child **COMPLETES** (the `@complete` fan-in, same-slot at emq.3.1 / cross-slot via
> the outbox+sweep at emq.3.3); a child that **FAILS** — exhausts its retries and lands in the morgue via
> `@retry`'s dead-letter arm (`jobs.ex:281-303`) — did **not** signal the parent, so the parent **hung in
> `awaiting_children` forever**. emq.3.4 closes that gap with the v1 failure-policy options
> (`fail_parent_on_failure` / `ignore_dependency_on_failure`, `flow_producer.ex:80-81`) over the
> **already-§6-reserved** `:failed` / `:unsuccessful` parent subkeys, plus `EchoMQ.Flows.add_bulk/3`
> (the v1 `add_bulk/2` parity, `flow_producer.ex:183`). **Risk was HIGH** — emq.3.4 (a) edits a **shipped Lua
> script** (`@retry`'s dead-letter arm gained an additive failure-propagation branch `:286-302`; the existing
> dead-letter body stays BYTE-FROZEN — Apollo's per-attr `git diff`: 0 removed Lua lines, 17 added) and (b) crosses
> the same slot boundary the cross-queue completion does (a cross-queue child's DEATH reaches the parent's slot
> over the **same** outbox+sweep mechanism emq.3.3 founded) → **Apollo MANDATORY** + the **≥100 determinism loop**
> both PASSED, the inverse of emq.3.2's NORMAL-risk reads.
> **Grandchildren / deep recursion** (a cross-queue child that is itself a flow-parent — the v1 recursive
> `build_flow_commands`, `flow_producer.ex:51-56/:238`) are the honest **Out**, **routed to emq.3.5** — the
> **V-1 scope fork is RULED → Arm A** (the Director, recorded as **D-2** in this rung's ledger
> [`./emq-3-4.progress.md`](../../progress/emq-3-4.progress.md): emq.3.4 = failure-policy + bulk per the family carve
> [`./emq.3.md`](../../emq.3.md):198; grandchildren is a separate later rung, **emq.3.5**, recorded NOT built). A
> later Arm-B re-scope (folding grandchildren into emq.3.4) stays a zero-cost option for the Operator — the
> failure-policy core is identical — but this triad is authored to the ruled Arm A.

## 0 · The slice — what emq.3.4 carves, and why fourth

emq.3.1–3.3 built the flow family's **happy path** end to end: a parent → its children (same-queue, atomic at
emq.3.1; cross-queue, eventually-consistent via the outbox+sweep at emq.3.3), the parent held out of `pending`
in `state = awaiting_children` with its `:dependencies` STRING counter, **released when the counter reaches
zero** — and a child reaches zero by **COMPLETING**: the `@complete` fan-in records the child in the parent's
`:processed` and DECRs `:dependencies` (same-slot, `jobs.ex:212-219`), or the cross-queue child emits to its
own-slot `flow:outbox` and the sweep delivers the DECR via `@flow_deliver` on the parent's slot
(`pump.ex:42`/`:161`). emq.3.2 made `:processed` carry a real result and added the read API
(`children_values/3` / `dependencies/3`).

Every one of those mechanisms fires on **success**. The **failure** half is unbuilt: a flow child that **dies**
— a worker `retry/7` past `max_attempts` runs `@retry`'s dead-letter arm (`jobs.ex:254-259`:
`HSET KEYS[4] last_error`; at-max-attempts `HSET KEYS[4] state 'dead'`; `ZADD KEYS[3] 0 id`;
`HINCRBY p..'metrics:failed' count 1`; `return 'dead'` — **five** statements, re-pinned at Stage-0:
the `HINCRBY metrics:failed` at `:258` is part of the byte-frozen morgue branch the failure branch adds
**after**) — **never touches the parent's `:dependencies`**. So the parent's counter stays above zero, the parent is **never released**, and the flow
**hangs**: every sibling can complete and the parent still waits on the one dead child. This is not a corner
case — it is the **default** v1 behaviour the flow API promises (`flow_producer.ex:76-82`: "By default, if a
child fails, the parent will also fail").

emq.3.4 carves exactly the failure semantics + the bulk add:

1. **`fail_parent_on_failure`** (the v1 default) — when a flow child **dies**, the parent **fails too**: the
   parent is moved to the morgue (`dead`) with the child's failure recorded in the parent's **`:failed`**
   subkey, rather than left hanging. The death **propagates up** the one parent level emq.3.4 builds.
2. **`ignore_dependency_on_failure`** — the opt-in inverse: a dead child is treated as a **satisfied**
   dependency (the parent's `:dependencies` is **DECR**'d as if the child completed) and recorded in the
   parent's **`:unsuccessful`** subkey, so the parent **proceeds** once its other children finish, and its
   handler can read the ignored failures (the v1 `get_ignored_children_failures` parity).
3. **`EchoMQ.Flows.add_bulk/3`** — the v1 `add_bulk/2` parity: add **N flows in one call** (pipelined), each
   flow landing by the existing `add/3` mechanism (same-queue atomic via `@enqueue_flow`, or cross-queue
   host-orchestrated parent-first via `@hold_parent` + `@enqueue_flow_child`).

It is the **fourth** sub-rung because failure propagation is meaningful only after the happy-path fan-in exists
(emq.3.1), is readable (emq.3.2), and crosses the slot boundary (emq.3.3) — the failure delivery rides the
**same** mechanisms (the same-slot fan-in for a same-queue child's death; the **same** `flow:outbox` + sweep for
a cross-queue child's death). It stays **one parent level** (flat): a cross-queue child that is itself a parent
of grandchildren (the recursive tree) is the honest **Out** (V-1 RULED → Arm A, D-2 — grandchildren is emq.3.5).

## Goal

emq.3.4 ships, inside `echo/apps/echo_mq`, the **flow failure-policy + bulk add** (SHIPPED — the as-built surface;
post-build `file:line` in the References):
(1) **the failure-policy options on the add** — `EchoMQ.Flows.add/3` (and `add_bulk/3`) accept the per-child
`fail_parent_on_failure` (default `true`) / `ignore_dependency_on_failure` flags (the v1 options,
`flow_producer.ex:80-81`); a cross-queue child additionally carries them so its own-slot death-handler knows the
policy (the emq.3.1 `parent`/emq.3.3 `parent_queue` pattern extended with a `parent_policy` field — host-read,
never a data-rooted Lua key);
(2) **the failure propagation on `@retry`'s dead-letter arm** (the one shipped-script edit — HIGH-risk) — when
a flow child lands in the morgue, an **additive branch** in `@retry` (the existing dead-letter body
`jobs.ex:254-259` **BYTE-FROZEN**) routes the death to the parent by policy: *same-queue child* → atomically (one
EVAL, one slot) either fail the parent (`fail_parent_on_failure`: record the child in the parent's `:failed`,
move the parent to `dead`) or satisfy-and-record (`ignore_dependency_on_failure`: record in `:unsuccessful`,
DECR `:dependencies`, at-zero release); *cross-queue child* → **emit a fail-entry into the child's own-slot
`flow:outbox`** (the **same** outbox emq.3.3 founded, a distinct entry KIND) atomically with the dead-letter
transition, and the sweep delivers it on the parent's slot;
(3) **the cross-queue fail-deliver** — `EchoMQ.Pump.sweep/1`'s existing third pass (`deliver_flow_completions`,
`pump.ex:161`) drains both entry kinds; a **fail-entry** dispatches to a new **`@flow_fail_deliver`** EVAL on the
parent's slot that, by the entry's policy, either fails the parent (record `:failed`, move `dead`) or
satisfy-and-records (record `:unsuccessful`, HSETNX-guarded DECR, at-zero release) — idempotent by the SAME
`:processed`-class guard the complete-deliver uses (a re-delivered fail is a no-op);
(4) **`EchoMQ.Flows.add_bulk/3`** — N flows in one call (the v1 `add_bulk/2` parity), pipelined, each landing by
the existing `add/3` mechanism; the bulk add is **fail-closed per flow** (a flow that fails to land leaves its
parent held — the emq.3.3 B2 add-side honesty, per flow);
(5) the conformance scenarios **`flow_fail_parent`**, **`flow_ignore_dep`**, **`flow_add_bulk`** (additive minor,
`47 → 50`), the prior 47 byte-unchanged, both pinning tests re-pinned;
(6) the `:valkey` failure suite (a flow whose child dies under each policy, same-queue AND cross-queue, the
parent failed / proceeded; a bulk add) under the **≥100-iteration determinism loop** (the mint/process-touching
surface).
The `:failed` / `:unsuccessful` subkeys are **already in the §6 grammar** (`emq.design.md:307` — `sub ∈ {lock,
logs, dependencies, processed, failed, unsuccessful}`), so emq.3.4 adds **no §6 key type** and **no grammar
change** (INV1); they join the flow-subkey **lifecycle carry** (N1) — their cleanup is **NAMED, deferred** to the
emq.3.x lifecycle rung (D-5). The shipped `@enqueue`/`@claim`/`@complete`/`@promote`/`@reap`/`@schedule` **Lua**
is **untouched**; the `@enqueue_flow`/`@hold_parent`/`@enqueue_flow_child`/`@flow_deliver` **Lua** is
**untouched**; `@retry`'s existing dead-letter body (`jobs.ex:254-259`) is **byte-frozen** (only an additive
branch is added); `apps/echomq` is **untouched** (the capability reference). **Grandchildren / deep recursion are
Out** (V-1, the scope fork — recorded NOT built).

## Rationale (5W)

- **Why** — emq.3.4 closes a **correctness gap**, not a nicety: today a flow whose child **dies** **hangs
  forever** (the parent is released only by a child *completing*; `@retry`'s dead-letter arm `jobs.ex:254-259`
  never touches the parent). The v1 flow API promises the opposite as its **default** ("if a child fails, the
  parent will also fail" — `flow_producer.ex:76-82`), so without emq.3.4 the flow family's parity is incomplete
  AND a real consumer's flow can stall on one poison child. It is the flow family's **failure half** — emq.3.1
  founded the happy-path fan-in, 3.2 made it readable, 3.3 crossed the slot boundary, and 3.4 makes a flow
  **terminate either way** (the parent fails, or proceeds past an ignored failure — never hangs). `add_bulk`
  completes the v1 `flow_producer` producer surface (the last unported public verb). It is the **closer of the
  flow family's core** (with grandchildren the one recursive depth deferred — V-1).
- **What** — emq.3.4 builds: the **failure-policy options** on `add/3`/`add_bulk/3` (the `fail_parent_on_failure`
  / `ignore_dependency_on_failure` flags; the cross-queue child carries `parent_policy`); the **failure
  propagation** (an additive branch in the shipped `@retry`'s dead-letter arm — the existing body byte-frozen —
  routing a same-queue child's death atomically by policy, and a cross-queue child's death into the child's
  own-slot `flow:outbox` as a fail-entry); the **cross-queue fail-deliver** (the existing sweep drains both entry
  kinds; a fail-entry → a new `@flow_fail_deliver` EVAL on the parent's slot, idempotent); **`add_bulk/3`** (N
  flows pipelined, fail-closed per flow); the **`flow_fail_parent` / `flow_ignore_dep` / `flow_add_bulk`**
  conformance scenarios; the `:valkey` failure suite. **Authored to Arm A** (the V-1 scope fork RULED → Arm A,
  D-2): failure-policy + bulk; grandchildren the locked Out → emq.3.5.
- **Who** — the program (the rung that closes the flow family's failure half and the last v1 producer verb); the
  bus's consumers, who gain robust flows (a parent that **fails** when a child dies, or **proceeds** past an
  ignored failure — never an indefinitely-hung parent) and bulk flow submission. **codemoji** (prospective): a
  job whose one failed leg must **fail the parent** (`fail_parent_on_failure`) or be
  **recorded-and-skipped** (`ignore_dependency_on_failure`) — *it names no flows today*
  ([`../emq.features.md`](../../../emq.features.md) — recorded, not asserted). The conformance harness, which grows by
  three scenarios (additive minor).
- **When** — Movement I, the flow family's **fourth** sub-rung, after emq.3.1 + emq.3.2 + emq.3.3 shipped
  (emq.3.4 extends the `add/3` admit path, edits the `@retry` dead-letter arm emq.1 built, rides the
  `flow:outbox` + sweep emq.3.3 built, and writes the `:failed`/`:unsuccessful` subkeys §6 reserved at the
  founding). SPECCED this design cycle; the **scope fork (V-1, grandchildren)** is **RULED → Arm A** (the
  Director, D-2) — failure-policy + bulk; grandchildren the locked Out → emq.3.5 — so the rung is build-ready
  with no pre-build re-scope (a later Arm-B fold stays a zero-cost Operator option, not this rung).
- **Where** — `echo/apps/echo_mq` only: `flows.ex` (EDIT — `add/3` accepts the policy flags + writes them on each
  child; the cross-queue child carries `parent_policy`; `add_bulk/3` NEW), `jobs.ex` (EDIT — the **additive
  failure-propagation branch** in `@retry`'s dead-letter arm; the existing dead-letter body `jobs.ex:254-259`
  BYTE-FROZEN; the host `retry`/`parent_of` extended to read `parent_policy` and supply the parent-fail keys or
  the outbox key), `pump.ex` (EDIT — the existing `deliver_flow_completions` pass dispatches a fail-entry to the
  new `@flow_fail_deliver` script; the complete-deliver path `@flow_deliver` byte-unchanged), `conformance.ex`
  (EDIT — `flow_fail_parent`/`flow_ignore_dep`/`flow_add_bulk` + the count re-pin `47 → 50`),
  `test/flow_failure_test.exs` (NEW — `:valkey`), the two pinning tests (EDIT — the count). **`keyspace.ex` is
  UNEDITED**: `:failed`/`:unsuccessful` compose via the existing `job_key/2` (`Keyspace.job_key(queue, parent) <>
  ":failed"` / `<> ":unsuccessful"`, the `children_values/3` `<> ":processed"` precedent at `flows.ex:191`) with
  no runtime registry allowlist, and they are **already §6-reserved** (`emq.design.md:307`), so their
  "registration" is the `flow_fail_parent`/`flow_ignore_dep` conformance scenarios, not a code-allowlist edit.
  `echo_wire` is **untouched** (the propagation + deliver ride the shipped connector `eval`). `apps/echomq` is
  **untouched**. Exact line anchors re-pinned at the pre-build reconcile (the lag-1 law — emq.3.1/3.2/3.3 moved
  the surface; this triad re-pinned it at Stage-0, the [`./emq-3-4.progress.md`](../../progress/emq-3-4.progress.md) T-1
  delta).

## Scope

- **In** — the FLAT flow failure-policy + bulk add (one parent level): (1) the **failure-policy options** —
  `add/3`/`add_bulk/3` accept per-child `fail_parent_on_failure` (default `true`) + `ignore_dependency_on_failure`;
  **every** child's row carries `parent_policy` (a host `HSET`, same-queue AND cross-queue — as-built E-1/R1,
  alongside the emq.3.1 `parent` + emq.3.3 `parent_queue`);
  (2) the **failure propagation** (the additive `@retry` dead-letter branch — D-3/D-4): a same-queue dead child
  routes atomically (one EVAL, one slot) — `fail_parent_on_failure` records the child in the parent's `:failed`
  + moves the parent to `dead`; `ignore_dependency_on_failure` records in `:unsuccessful` + DECRs `:dependencies`
  + at-zero releases; the existing dead-letter body byte-frozen; (3) the **cross-queue fail-deliver** — a
  cross-queue dead child emits a **fail-entry** into its own-slot `flow:outbox` (the same outbox, a distinct KIND)
  atomically with the dead-letter transition; the existing sweep (`deliver_flow_completions`) drains it and
  dispatches a `@flow_fail_deliver` EVAL on the parent's slot, idempotent by the `:processed`-class guard;
  (4) **`EchoMQ.Flows.add_bulk/3`** (N flows pipelined, fail-closed per flow — the v1 `add_bulk/2` parity);
  (5) the **child-failure read** — `EchoMQ.Flows.ignored_failures/3` (`HGETALL` of `:unsuccessful` →
  `{:ok, %{child_id => error}}`, the v1 `get_ignored_children_failures` parity), the read counterpart of
  `children_values/3`; (6) `flow_fail_parent`/`flow_ignore_dep`/`flow_add_bulk` conformance (additive minor, the
  prior 47 byte-unchanged); (7) the `:valkey` failure suite under the **≥100-iteration determinism loop**;
  honest-row reporting (Valkey on 6390 the truth row).
- **Out** — **grandchildren / deep recursion** (a cross-queue child that is itself a flow-parent of grandchildren
  — the v1 recursive `build_flow_commands`, `flow_producer.ex:51-56/:238`; the multi-level fan-in where a
  grandchild's completion releases the child whose completion then signals the parent) — the **V-1 scope fork is
  RULED → Arm A** (D-2): grandchildren is the locked Out, **routed to emq.3.5** (a separate later rung, recorded
  NOT built); a later Arm-B re-scope (folding it in) stays a zero-cost Operator option but is not this rung; the
  **TTL auto-cancel** of a stuck flow
  (a flow whose child neither completes nor dies — that is **emq.6** lifecycle controls, the distributed/TTL
  cancel, [`../emq.features.md`](../../../emq.features.md) Movement II — not a flow rung); **`remove_dependency`** (the
  v1 third option, `flow_producer.ex` `encode_job_opts` `:480` — a manual dependency-removal verb, deferred with
  grandchildren to the family's residue rung unless the Director folds it); the **flow-subkey CLEANUP/lifecycle**
  (the `obliterate`/`@drain` sweep of `:dependencies`/`:processed`/`:failed`/`:unsuccessful`/`flow:outbox` — a
  **NAMED CARRY** to the emq.3.x lifecycle rung, D-5 + the honest bounds below; emq.3.4 **adds** the
  `:failed`/`:unsuccessful` writes, it does not retire them); any **edit to a shipped Lua script other than the
  additive `@retry` dead-letter branch** (`@enqueue`/`@claim`/`@complete`/`@promote`/`@reap`/`@schedule`/
  `@enqueue_flow`/`@hold_parent`/`@enqueue_flow_child`/`@flow_deliver` — none; the `@retry` existing dead-letter
  body `jobs.ex:254-259` is byte-frozen, only an additive branch is added); any **new wire class** (none — the
  propagation/deliver are plain `HSET`/`HSETNX`/`DECR`/`ZADD`/`RPUSH`; no fence code, no `EMQ…` class); any **new
  transport** (none — the connector `eval` carries both new scripts); any **`keyspace.ex` grammar edit** (none —
  `:failed`/`:unsuccessful` are §6-reserved and compose via the existing `job_key/2`); any **edit to the frozen
  v1 line**; the Operator's concurrent
  `docs/echo/mesh/**` course work.

### The honest bounds + carried follow-ups (surfaced at authoring — recorded, not papered over)

emq.3.4 ships the FLAT flow failure-policy + bulk add; these are its honest bounds, each a **correct-for-scope**
limit, never a defect:

- **B1 — the cross-queue failure is EVENTUALLY-CONSISTENT, exactly as the cross-queue completion is (INV5,
  inherited from emq.3.3).** A cross-queue child's **death** does **NOT** synchronously fail/satisfy its parent.
  The fail-entry rides the same `flow:outbox` and is delivered on the **next sweep tick** of the child's queue
  (latency bounded by `:tick_ms`, default 1000ms — `pump.ex`). The **same-queue** failure propagation IS atomic
  (one EVAL, one slot — the parent's `:failed`/`:dependencies` share the dead child's slot), exactly as the
  same-queue completion fan-in is. **No page, story, doc, or comment may claim "atomic across queues."**
- **B2 — failure delivery is AT-LEAST-ONCE made EFFECTIVELY-ONCE; the drop window is PROVABLY ABSENT (D-3/D-4,
  inherited from emq.3.3's keystone).** The fail-emit is **atomic with the dead-letter transition** (the
  `flow:outbox` RPUSH and the `@retry` `HSET state 'dead'` + `ZADD <dead>` are **one EVAL on the child's slot
  {C}**), so a dead cross-queue child **always** has a durable fail-entry — no drop window. The fail-deliver is
  **idempotent** by the **same** `:processed`-class guard the complete-deliver uses (a re-delivered fail finds the
  child already recorded → no second DECR / no second parent-fail). The parent is failed-or-satisfied **exactly
  once** per child. A queue whose pump **never runs** lingers its fail-entries → its parents are **delayed, never
  dropped** (the durable outbox, B4 of emq.3.3).
- **B3 — `fail_parent_on_failure` propagates ONE parent level (FLAT).** A dead child fails its **direct** parent
  (records `:failed`, moves the parent to `dead`). Whether the parent's OWN death then propagates to a
  **grandparent** (the recursive tree) is **grandchildren / deep recursion — Out (V-1)**. emq.3.4 propagates one
  level; the recursive propagation is the deferred rung. The contract states this explicitly: a failed flow
  parent under emq.3.4 is moved to `dead` like any other dead job (it does not auto-propagate further unless the
  recursive rung ships).
- **B4 — `ignore_dependency_on_failure` treats the dead child as SATISFIED, not COMPLETED.** The ignored child
  DECRs `:dependencies` (so the parent proceeds) and is recorded in `:unsuccessful` (the failure reason, the v1
  `get_ignored_children_failures` read) — but it is **NOT** recorded in `:processed` (it produced no result), so
  `children_values/3` (the completed-children results) does **not** include it; `ignored_failures/3` does. The
  two reads are disjoint by construction (a child is in `:processed` XOR `:unsuccessful`, never both — it either
  completed or was ignored-on-failure; a `fail_parent_on_failure` death lands in `:failed`, not `:unsuccessful`,
  and fails the parent rather than satisfying it).
- **B5 — the failure path edits the SHIPPED `@retry`, additively (the HIGH-risk bound, the emq.3.1/3.3 @complete
  precedent applied to `@retry`).** The propagation is a **new branch** in `@retry`'s dead-letter arm, gated on
  the host supplying the parent-fail keys (a same-queue dead child) or the outbox key + a fail marker (a
  cross-queue dead child) — keys/markers the shipped callers (a non-flow job's `retry`, a flow child with no
  policy / not yet dead) **never** pass; the existing dead-letter body (`jobs.ex:254-259`) and the schedule arm
  are **BYTE-UNCHANGED**. A non-flow job's `@retry` is byte-identical. Apollo MANDATORY byte-proves it (the
  git-diff shows only ADDED lines), exactly as emq.3.1/3.3 proved the `@complete` edits.
- **B6 — the `:failed`/`:unsuccessful` subkeys join the lifecycle carry, NAMED, deferred (N1, D-5).** They are
  **§6-reserved** (`emq.design.md:307`) so they need no grammar edit, but — like `:dependencies`/`:processed`
  (emq.3.2-N1) and `flow:outbox` (emq.3.3-B5) — they **persist** past the parent row until a lifecycle rung
  sweeps them. emq.3.4 **names** their cleanup home (both FIXED-list destructive sweeps — `obliterate`'s
  `del_job` and `@drain`'s `wipe()` — gaining `:failed`/`:unsuccessful`, routed to the emq.3.x lifecycle rung,
  joining the existing carry); emq.3.4 adds **ZERO** cleanup; `admin.ex` is **untouched**.

## Deliverables

> **[POST-BUILD RECONCILE — Stage 5, the line-anchor re-pin, stated once]** The build moved the surface (the
> lag-1 law). The authoritative post-build `file:line` live in the **As-built-surface block of the References**;
> the inline citations in the prose below are PRE-build (the design-time numbers) and are FAITHFUL on substance
> (the dead-letter arm IS the byte-frozen bound; only the line moved). The load-bearing global re-pins, once:
> the dead-letter morgue body **`jobs.ex:254-259` → `:281-303`** (the FIVE statements byte-frozen; the additive
> failure branch inserted **`:286-302`**, between `HINCRBY metrics:failed` `:285` and `return 'dead'` `:303`);
> `@retry` `:225`→`:252`; `add/3` `:152`→`:181`; `complete/5` `:412`→`:456`; `parent_of/3` `:459`→`:503`;
> `retry/7` `:474`→`:593`; `children_values/3` `:190`→`:261`; `@complete` `:175` + `@flow_deliver` `pump.ex:42`
> **UNCHANGED** (byte-frozen). The NEW symbols: `add_bulk/3` `flows.ex:218`, `ignored_failures/3` `:295`,
> `parent_fail_of/3` `jobs.ex:535`, `@flow_fail_deliver` `pump.ex:78`, the conformance set at **50**. (One
> surgical note, not a reflow of every inline ref — the emq.3.3 L-2 spec-sync discipline.)

emq.3.4 SHIPPED (the failure surface, built and Apollo-verified — the forward-named deliverables below are
**as-built**; the post-build `file:line` are re-pinned in the As-built-surface block of the References. The
Stage-0 baseline this rung closed: `add/3` took no policy flags, `@retry`'s dead-letter arm wrote only
`last_error`/`dead`/the morgue with no parent touch, and there was no `@flow_fail_deliver`, no `add_bulk/3`, no
`parent_policy` field, no `ignored_failures/3` read):

- **EMQ.3.4-D1 — the scope gate (RULED → Arm A, FIRST):** the **V-1 scope fork** (grandchildren IN emq.3.4 or a
  separate rung) was surfaced to the Director with both arms steelmanned + a recommendation, and **RULED → Arm A**
  (recorded as **D-2** in this rung's ledger [`./emq-3-4.progress.md`](../../progress/emq-3-4.progress.md)): emq.3.4 =
  failure-policy + bulk (the family carve [`./emq.3.md`](../../emq.3.md):198 scope); **grandchildren / deep recursion
  is the locked Out → emq.3.5** (a separate later rung, recorded NOT built). The triad is authored to Arm A → no
  pre-build re-scope. A later Arm-B re-scope (folding grandchildren into emq.3.4) stays a zero-cost Operator
  option — the failure-policy core is identical — but is not this rung. Recorded BEFORE any build artifact.
- **EMQ.3.4-D2 — the failure-policy options on the add (`EchoMQ.Flows.add/3` + `add_bulk/3` extended):** `add/3`
  accepts per-child `fail_parent_on_failure` (default `true`) + `ignore_dependency_on_failure` (default `false`)
  flags (the v1 options, `flow_producer.ex:80-81`). Each child's row records its policy in a **`parent_policy`**
  field. *(As-built realization, synced — E-1/R1: `parent_policy` is written by a host `HSET` on the child row for
  **every** child, same-queue AND cross-queue, AFTER the byte-frozen enqueue script — because `@enqueue_flow` and
  `@enqueue_flow_child` stayed **BYTE-FROZEN** (R1, INV1: the policy could not ride a new script ARGV without
  editing a shipped/new-frozen script), so the uniform host `HSET` is the realization. The design-time plan —
  "a same-queue child needs no new field, only a cross-queue child carries `parent_policy`" — is superseded: a
  same-queue child ALSO carries it, written symmetrically by the host. The policy then drives the `@retry` failure
  arm host-side; INV2 holds — `parent_policy` is host-read, never a data-rooted Lua key.)* `add_bulk/3` accepts a
  **list of flows** and lands each (the v1 `add_bulk/2` parity), **SEQUENTIALLY** over the connector (one `add/3`
  per flow — the as-built realization; the design-time "pipelined" is superseded), **fail-closed per flow** (a flow
  that fails to land leaves its parent held — the emq.3.3 B2 add-side honesty, per flow); it returns
  `{:ok, [{parent_id, [child_id]}]}`. Each id (parent + every child, every flow) is gated at `Keyspace.job_key/2`
  (raises on an ill-formed id — INV4) BEFORE the wire. *As-built:* `EchoMQ.Flows.add/3` `:181` (the policy flags),
  `EchoMQ.Flows.add_bulk/3` `:218` (SHIPPED), `flows.ex`.
- **EMQ.3.4-D3 — the same-queue failure propagation (the additive `@retry` dead-letter branch — D-4; the
  existing body BYTE-FROZEN):** when a **same-queue** flow child lands in the morgue (`@retry` past
  `max_attempts`), an **additive branch** runs by the child's policy, atomically in the same EVAL (one slot — the
  parent's subkeys share the dead child's `{q}`): `fail_parent_on_failure` → `HSET` the child into the parent's
  **`:failed`** (the failure reason) + move the parent to `dead` (`HSET <parent row> state 'dead'`; `ZADD
  <parent dead> 0 <parent>`; remove the parent's `:dependencies`/`pending` membership as the morgue transition
  requires); `ignore_dependency_on_failure` → `HSET` the child into the parent's **`:unsuccessful`** + `DECR` the
  parent's `:dependencies` + at-zero `ZADD <parent pending> 0 <parent>` + `HSET <parent row> state 'pending'`
  (the satisfy-and-release, mirroring the `@complete` fan-in's at-zero release). The branch fires **only** when
  the host supplies the parent-fail keys (`KEYS[n]` = the parent's `:failed`/`:unsuccessful`/`:dependencies`/row,
  host-built + gated) and the policy ARGV — keys the shipped `retry` callers never pass. **The EXISTING
  dead-letter body (`jobs.ex:254-259` — the FULL **five-statement** morgue branch, re-pinned at Stage-0:
  `HSET KEYS[4] last_error ARGV[5]` `:254`; at `att >= max` `HSET KEYS[4] state 'dead'` `:256`;
  `ZADD KEYS[3] 0 ARGV[1]` `:257`; `HINCRBY p..'metrics:failed' count 1` `:258`; `return 'dead'` `:259`) stays
  BYTE-UNCHANGED** — including the `HINCRBY metrics:failed` (the brief's pre-Stage-0 three-statement abbreviation
  omitted it; the byte-freeze covers all five). The new branch runs **after** it (the child still lands in its own
  morgue first, then the parent is notified), and the schedule arm (`@retry`'s non-terminal arm) is byte-unchanged. *Forward-named:* the
  `@retry` dead-letter cross-flow branch + the host `retry` extension, `jobs.ex`.
- **EMQ.3.4-D4 — the cross-queue fail-deliver (the existing sweep + `@flow_fail_deliver`):** a **cross-queue**
  flow child's death emits a **fail-entry** into its own-slot `flow:outbox` (the **same** outbox emq.3.3 founded
  — a distinct entry KIND, e.g. a leading kind tag the splitter reads) **atomically with the `@retry` dead-letter
  transition** (one EVAL on the child's slot {C}, the same shape as emq.3.3's complete-emit). `EchoMQ.Pump.sweep/1`'s
  existing third pass `deliver_flow_completions` (`pump.ex:161`) drains **both** entry kinds; a **complete-entry**
  dispatches the existing `@flow_deliver` (byte-unchanged); a **fail-entry** dispatches a NEW **`@flow_fail_deliver`**
  EVAL on the **parent's slot** (the parent key rebuilt host-side via `Keyspace.job_key(parent_queue,
  parent_id)`): by the entry's policy, `fail_parent_on_failure` → `HSETNX` the child into `:failed` + (on first
  record) move the parent to `dead`; `ignore_dependency_on_failure` → `HSETNX` the child into `:unsuccessful` +
  (on first record) `DECR` `:dependencies` + at-zero release. The HSETNX guard makes the fail-deliver **idempotent**
  (a re-delivered fail is a no-op — the same `:processed`-class guard the complete-deliver uses, now over
  `:failed`/`:unsuccessful`). The drained entry is removed only after the deliver succeeds (deliver-before-remove,
  the emq.3.3 drain order). *Forward-named:* the fail-entry KIND in the emit + the `deliver_flow_completions`
  dispatch + `@flow_fail_deliver`, `jobs.ex` + `pump.ex`.
- **EMQ.3.4-D5 — the lifecycle disposition (NAMED, a carry — the §2 guardrail discharged):** emq.3.4 **names**
  what retires the **newly-populated** `:failed` / `:unsuccessful` subkeys (and re-affirms the
  `:dependencies`/`:processed`/`flow:outbox` carry): the deferred emq.3.x lifecycle rung enumerates
  `emq:{q}:job:<id>:failed` and `…:unsuccessful` in **both** `Admin`-surface destructive sweeps — `obliterate`'s
  `del_job` (`admin.ex:152`) **and** `@drain`'s `wipe()` (`admin.ex:90`) — joining the
  `:dependencies`/`:processed` (emq.3.2-N1) and `flow:outbox` (emq.3.3-B5) carry. **emq.3.4 adds ZERO cleanup**
  (named, deferred); `admin.ex` is untouched. *Check:* the body names the subkeys' cleanup home (both sweeps) +
  the owning rung; emq.3.4's touch-set adds no `DEL`/`HDEL`/`UNLINK` of a flow subkey; `admin.ex` is untouched.
- **EMQ.3.4-D6 — the child-failure read (`EchoMQ.Flows.ignored_failures/3` — the v1 parity, host-only):** a PURE
  `HGETALL` of the parent's `:unsuccessful` subkey → `{:ok, %{child_id => error}}` (the v1
  `get_ignored_children_failures` parity, `job.ex:885`), the read counterpart of `children_values/3`
  (`flows.ex:190`). It composes the key via `Keyspace.job_key(queue, parent_id) <> ":unsuccessful"` (the
  `children_values/3` `<> ":processed"` precedent); a parent with no `:unsuccessful` key returns `{:ok, %{}}`.
  **NORMAL-risk** (a host-only read, no script) — the read half of emq.3.4. *Forward-named:*
  `EchoMQ.Flows.ignored_failures/3`, `flows.ex`.
- **EMQ.3.4-D7 — the proof:** the `:valkey` failure suite green per-app (a flow whose child dies under each
  policy, same-queue AND cross-queue: `fail_parent_on_failure` → the parent moves to `dead` with the child in
  `:failed`; `ignore_dependency_on_failure` → the parent proceeds with the child in `:unsuccessful`; a bulk add
  of N flows); the mint/process-touching cross-queue failure scenario under the **≥100-iteration determinism
  loop** owning the machine (a flow mints many ids across queues — the same-ms mint hazard); the prior emq.1 +
  emq.2.{1,2,3,4} + emq.3.{1,2,3} suites + `Conformance.run/2` pass **unchanged** (no regression — INV3); the
  **`@retry` existing dead-letter body byte-unchanged** (git-diff shows only ADDED lines; the existing
  `jobs.ex:254-259` + the schedule arm untouched — INV3, the HIGH-risk regression bound); honest-row reporting
  (Valkey on 6390 the truth row); the three scenarios registered additive-minor with the prior 47 byte-unchanged;
  **Apollo MANDATORY** (HIGH-risk — a shipped-script edit on `@retry`; D-1 risk-tier).

## Invariants (runnable checks)

- **EMQ.3.4-INV1 — the wire law (no break, no new key type, no new wire class, no new transport; additive
  shipped-script branches only).** emq.3.4 adds **no §6 key type** (the `:failed`/`:unsuccessful` subkeys are
  **already in the §6 closed set** — `emq.design.md:307` `sub ∈ {lock, logs, dependencies, processed, failed,
  unsuccessful}`; emq.3.4 populates pre-reserved subkeys); **no new wire class** (the propagation/deliver are
  plain `HSET`/`HSETNX`/`DECR`/`ZADD`/`RPUSH` — no fence code, no `EMQ…` class); **no new transport** (the
  connector `eval` carries `@retry` + `@flow_fail_deliver`; no `SSUBSCRIBE`); and edits **exactly one** shipped
  Lua script — `@retry`, **additively** (a new dead-letter branch gated on host-supplied keys/markers the shipped
  callers never pass). The five-code fence union stands unextended; the closed wire-class registry is unchanged;
  the §6 `suffix` production is **unedited**. *Check:* a `git diff` of every `@… Script.new/2` attribute in
  `jobs.ex` + `flows.ex` + `pump.ex` shows **only** (a) ADDED lines in `@retry`'s body (the new cross-flow
  failure branch; the existing dead-letter body `:254-259` + the schedule arm byte-identical) and (b) the NEW
  `@flow_fail_deliver` attribute; no other `Script.new/2` body changes (`@flow_deliver` byte-unchanged);
  `keyspace.ex`'s grammar is unedited; a grep of the new scripts for a key not matching the §6 grammar returns
  empty.
- **EMQ.3.4-INV2 — the declared-keys A-1 law over the new scripts (S-6, the slot-soundness obligation).** Every
  key in the `@retry` failure branch and in `@flow_fail_deliver` is **declared in `KEYS[]`** or grammar-rooted
  from a declared `KEYS[n]` (the `@extend_locks` `base .. 'job:' .. id` form, ratified 2026-06-14,
  `design.md:102-113`). The same-queue failure branch's keys are **all on the dead child's slot {C}** (the
  child's morgue keys + the parent's `:failed`/`:unsuccessful`/`:dependencies`/row — all `{C}` because the parent
  is same-queue); the cross-queue fail-emit's keys are **all on the child's slot {C}** (the morgue keys + the
  `flow:outbox`); `@flow_fail_deliver`'s keys are **all on the parent's slot {P}** (the parent's
  `:failed`/`:unsuccessful`/`:dependencies`/row). **No script mixes slots; no key is read out of a data value in
  Lua** (the v1 `parent_key` data-value form, `flow_producer.ex:354/327`, is NOT lifted — the host reads the
  child's `parent`/`parent_queue`/`parent_policy` fields HOST-SIDE and passes declared keys, the emq.3.1/3.3
  pattern extended). *Check:* a grep over the new failure branch + `@flow_fail_deliver` confirms every
  `redis.call` key argument is a `KEYS[n]` or `ARGV[base] .. <literal>`; a reviewer names the single slot of each
  script's key set (the CROSSSLOT-invisible-on-single-node-6390 F-1 trap — the engine on 6390 will NOT catch a
  cross-slot key; the review + the declared-keys grep must).
- **EMQ.3.4-INV3 — the shipped surface is byte-unchanged except the one additive `@retry` branch (the HIGH-risk
  regression bound).** A **non-flow** job retried/dead-lettered flows through `@retry` exactly as emq.3.3
  shipped; a job that completes flows through `@complete` exactly as shipped (incl. the emq.3.1 same-queue fan-in
  branch `jobs.ex:212-219` and the emq.3.3 cross-queue emit branch `:205-206` — both byte-frozen); the existing
  cross-queue complete-deliver `@flow_deliver` (`pump.ex:42`) is byte-unchanged; the `@retry` failure branch
  fires **only** on the host-supplied parent-fail keys / fail marker (provably false for every non-flow and every
  completing-child path). *Check:* the emq.1 + emq.2.{1,2,3,4} + emq.3.{1,2,3} suites + `Conformance.run/2` pass
  **unchanged**; the prior **47** conformance scenarios are byte-identical (name + contract + verdict body,
  git-verified); the `git diff` of `@retry` shows the existing dead-letter body (`:254-259`) + the schedule arm
  **byte-identical** (only ADDED lines for the new branch); `@complete` and `@flow_deliver` are byte-unchanged;
  Apollo's explicit byte-check confirms it.
- **EMQ.3.4-INV4 — branded identity at every boundary.** `add/3`/`add_bulk/3` gate **every** id (parent + each
  child, every flow) at `Keyspace.job_key/2` (which gates `BrandedId.valid?/1` and raises before any wire); the
  fail-deliver rebuilds the parent key through `Keyspace.job_key(parent_queue, parent_id)` (gated). An ill-formed
  id raises at the key builder, never reaching a key. *Check:* an `add/3`/`add_bulk/3` with an ill-formed child
  id raises at `Keyspace.job_key/2`; a fail-deliver of an entry whose parent id is valid issues a well-formed
  `:failed`/`:unsuccessful`/`:dependencies` key on the parent's slot.
- **EMQ.3.4-INV5 — `fail_parent_on_failure` fails the parent (the default, the gap closed).** A flow with
  `fail_parent_on_failure` (the default) whose child **dies** (exhausts retries) results in the parent moving to
  `dead` with the child recorded in the parent's `:failed` — the parent is **NOT** left hanging. *Check (the
  `flow_fail_parent` scenario, same-queue AND cross-queue):* a flow of a parent + a child with
  `fail_parent_on_failure`; the child is failed past `max_attempts` (it lands `dead`); then the parent is
  observed `dead` (`claim` on the parent's queue never returns it; `get_job_state/3` reads `:dead`), and the
  parent's `:failed` subkey holds the child id → its error. (Cross-queue: the parent fails **on the sweep tick**
  after the child's death, never synchronously — INV6.)
- **EMQ.3.4-INV6 — `ignore_dependency_on_failure` satisfies-and-records (the parent proceeds).** A flow with
  `ignore_dependency_on_failure` whose child **dies** results in the parent's `:dependencies` decremented (as if
  satisfied), the child recorded in `:unsuccessful` (the failure reason, NOT in `:processed`), and the parent
  **released** once its other children finish — the parent **proceeds** past the ignored failure. *Check (the
  `flow_ignore_dep` scenario):* a flow of a parent + 2 children, one with `ignore_dependency_on_failure`; the
  ignored child dies (DECRs `:dependencies`, recorded in `:unsuccessful`), the other completes (DECRs to zero),
  then the parent is **released** (claimable; `dependencies/3` == 0; row `pending`); `ignored_failures/3` returns
  the ignored child → its error; `children_values/3` returns **only** the completed child (the ignored child is
  in `:unsuccessful` XOR `:processed`, never both — B4).
- **EMQ.3.4-INV7 — idempotent failure delivery (at-least-once → effectively-once; inherited from emq.3.3's
  keystone, D-3/D-4).** A re-delivered fail-entry **does not** double-fail or double-DECR: `@flow_fail_deliver`
  applies its effect only when its `HSETNX` of the child into `:failed`/`:unsuccessful` succeeds (returns 1), so
  re-running the fail-deliver for an already-recorded child is a **no-op** — the parent is failed-or-satisfied
  **exactly once**. *Check (the `flow_fail_parent`/`flow_ignore_dep` scenarios):* the scenario runs
  `@flow_fail_deliver` for the same dead child **twice** (simulating a sweep re-delivery) and asserts the parent's
  state changed **once** (`fail_parent_on_failure`: the parent is `dead`, the `:failed` HASH has one entry for the
  child; `ignore_dependency_on_failure`: `:dependencies` decremented once, the `:unsuccessful` HASH has one
  entry); the second deliver returns its no-op verdict.
- **EMQ.3.4-INV8 — emission atomic with the dead-letter transition (the no-drop guarantee, inherited from
  emq.3.3, D-1/D-4).** A cross-queue child's fail-entry RPUSH and its `@retry` dead-letter transition (`HSET state
  'dead'` + `ZADD <dead>`) are **one EVAL** on the child's slot {C}: a dead cross-queue child **always** has a
  durable fail-entry — there is **no state** where the child died but produced no signal (the drop window does
  not exist). *Check:* the `@retry` cross-queue failure branch performs the `flow:outbox` `RPUSH` and the morgue
  transition in the **same** `Script.new/2` body (one EVAL); a `:valkey` scenario fails a cross-queue child and
  asserts (before any sweep) the outbox holds exactly one fail-entry for it AND the child is in its own queue's
  morgue (`dead`) — both effects of the one EVAL.
- **EMQ.3.4-INV9 — the additive-minor conformance law.** `flow_fail_parent`, `flow_ignore_dep`, and
  `flow_add_bulk` are registered in `scenarios/0` **with their probes in the same change**; the prior **47**
  scenarios pass **byte-unchanged**; the count re-pinned **47 → 50** in **both** pinning tests
  (`conformance_scenarios_test.exs` + `conformance_run_test.exs`). *Check:* the `git diff` shows only additions to
  `scenarios/0`; both pin tests assert the new total **50**; `Conformance.run/2` prints the new line count and
  returns `{:ok, 50}`.
- **EMQ.3.4-INV10 — the `:failed`/`:unsuccessful` subkeys' lifecycle is NAMED (the §2 guardrail, D-5).** The spec
  body **names** the cleanup disposition for the newly-populated `:failed`/`:unsuccessful` subkeys — both
  FIXED-list destructive sweeps (`obliterate`'s `del_job` `admin.ex:152` **and** `@drain`'s `wipe()`
  `admin.ex:90`) gaining `emq:{q}:job:<id>:failed`/`…:unsuccessful`, routed to the emq.3.x lifecycle rung (D-5),
  joining the emq.3.2-N1 `:dependencies`/`:processed` + emq.3.3-B5 `flow:outbox` carry. emq.3.4 adds **no**
  cleanup. *Check:* the body names the subkeys' cleanup home (both sweeps) + the owning rung; emq.3.4's touch-set
  contains **no** `DEL`/`HDEL`/`UNLINK` of a flow subkey; `admin.ex` is untouched.
- **EMQ.3.4-INV11 — slot soundness + the family boundary (FLAT, one parent level; grandchildren Out).** The
  same-queue failure branch's keys are exactly the dead child's `{C}` slot (the parent is same-queue); the
  cross-queue fail-emit's keys are exactly the child's `{C}` slot; `@flow_fail_deliver`'s keys are exactly the
  parent's `{P}` slot; emq.3.4 ships the FLAT failure-policy + bulk only — `fail_parent_on_failure` propagates
  **one** parent level (B3), no grandchildren / deep recursion (V-1, Out), no TTL auto-cancel (emq.6); it
  re-ships no emq.2 surface and pre-empts no Movement-II family. *Check:* the failure/fail-deliver scripts each
  build keys of exactly one slot; the deliverable touch-set is the policy flags + the `@retry` failure branch +
  the fail-deliver + `add_bulk/3` + `ignored_failures/3` + the conformance scenarios; the body names the boundary
  and the honest bounds B1–B6; no deliverable recurses past one parent level.

## Definition of Done

- [x] EMQ.3.4-D1: the V-1 scope fork (grandchildren) surfaced to the Director with both arms + a recommendation,
      **RULED → Arm A** (D-2, the `emq-3-4` ledger): emq.3.4 = failure-policy + bulk; grandchildren the locked
      Out → emq.3.5. The triad is authored to Arm A → no pre-build re-scope. Recorded BEFORE any build artifact.
- [x] The failure-policy options built (D2): `EchoMQ.Flows.add/3` (`flows.ex:177` — the policy flags on the
      `@spec`/doc) + `add_bulk/3` (`flows.ex:212`) accept per-child `fail_parent_on_failure` (default `true`) +
      `ignore_dependency_on_failure`; the cross-queue child carries `parent_policy` (a host `HSET` in
      `land_children` after the byte-frozen `@enqueue_flow_child` EVAL, `flows.ex:462`); a same-queue child also
      carries it (a host `HSET` after the atomic `@enqueue_flow`, `flows.ex:391`); every id gated at
      `Keyspace.job_key/2`; `add_bulk/3` fail-closed per flow, returns `{:ok, [{parent_id, [child_id]}]}`.
      *(As-built realization, synced: a child naming BOTH flags `true` resolves to `ignore_dependency_on_failure`
      — the proceed policy is the explicit opt-in; `policy_token/1` `flows.ex:358`. Recorded in the `add/3` doc.)*
- [x] The same-queue failure propagation built (D3, the additive `@retry` branch `jobs.ex:251`): a same-queue
      dead child routes atomically by policy in the `sq:fp`/`sq:id` arms (`jobs.ex` the failure branch
      `:286-298`) — `fail_parent_on_failure` → record `:failed` + parent to `dead`; `ignore_dependency_on_failure`
      → record `:unsuccessful` + DECR + at-zero release; the existing dead-letter body (the 5-statement morgue) +
      the schedule arm **byte-frozen** (per-attr `git diff`: 0 removed Lua lines, 17 added). The host
      `parent_fail_of/3` (`jobs.ex:527`) reads `parent`/`parent_queue`/`parent_policy`; `retry/7` (`jobs.ex:590`)
      appends the per-arm keys/ARGV.
- [x] The cross-queue fail-deliver built (D4): a cross-queue dead child emits a fail-entry into `flow:outbox`
      atomically with the dead-letter transition (one EVAL, the `xq:fp`/`xq:id` arms `jobs.ex:299-302`); the
      existing sweep `deliver_one/2` (`pump.ex`) drains both entry kinds via the KIND-dispatch `split_entry/1`
      (`pump.ex:316`, leading-empty-field → `split_fail_entry`); a fail-entry → `@flow_fail_deliver`
      (`pump.ex:53`) on the parent's slot (idempotent by the `:processed`-class HSETNX guard); `@flow_deliver`
      **byte-unchanged**.
- [x] `add_bulk/3` built (D2, `flows.ex:212`) + `ignored_failures/3` built (D6, the `:unsuccessful` HGETALL read,
      host-only, NORMAL-risk, `flows.ex:286`). *(As-built realization, synced: `add_bulk/3` lands each flow in
      SEQUENCE over the shipped connector, not a single pipelined batch — the spec's "pipelined" was the intent;
      the honest as-built is one `add/3` per flow, fail-closed per flow. Recorded in the `add_bulk/3` doc.)*
- [x] The lifecycle disposition NAMED (D5, B6): `:failed`/`:unsuccessful` routed to the emq.3.x lifecycle rung
      (both destructive sweeps), joining the `:dependencies`/`:processed`/`flow:outbox` carry; emq.3.4 added no
      cleanup; `admin.ex` **untouched** (no diff, git-verified).
- [x] `flow_fail_parent`/`flow_ignore_dep`/`flow_add_bulk` registered (D7/INV9, additive minor,
      `conformance.ex:110-112` + the probes `:1281`/`:1340`/`:1397`): the prior 47 conformance scenarios'
      contract registry byte-unchanged (the keyword-list keys + contract strings git-verified identical); the
      count re-pinned **47 → 50** in both pinning tests (`conformance_run_test.exs:44` → `{:ok, 50}`,
      `conformance_scenarios_test.exs` `@run_order` 50 names). *(FINDING, Apollo: ~36 lines of mix-format reflow
      on PRE-EXISTING `apply_scenario` probe BODIES remain in `conformance.ex` — a partial-revert of D-1's R3;
      the contract registry is byte-identical and every prior scenario drives identical commands/verdicts, so
      INV9's behavioral guarantee holds, but R3's "do not run mix format here" lock is not fully honored. Routed
      to the Director.)*
- [x] The proof (D7): the `:valkey` failure suite green per-app (each policy, same-queue AND cross-queue; a bulk
      add; `flow_failure_test.exs` NEW, 25 tests); the **≥100 determinism loop** green for the
      mint/process-touching cross-queue failure scenario (Mars 2× 120/120 uncontended; Apollo SCOPED 100/100
      uncontended); the emq.1 + emq.2.{1,2,3,4} + emq.3.{1,2,3} suites + `Conformance.run/2` passed unchanged (no
      regression — INV3; full per-app suite 4 doctests + 328 tests, 0 failures); the `@retry` existing dead-letter
      body + `@complete` + `@flow_deliver` **byte-unchanged** (Apollo's per-attr `git diff` byte-check); honest-row
      reporting (Valkey on 6390, erlang 28.5.0.1 — the canonical line); **Apollo MANDATORY** verified (HIGH-risk).
- [x] INV1–INV11 verified as runnable checks (Apollo Stage-4, T-3); the spec body remains authoritative; the
      post-build reconcile (Stage 5/Stage 7) syncs it to the as-built surface.
- [x] EMQ.3.4-D7 acceptance story (the user-facing proof, Apollo Job 1): `test/stories/flows_failure_story_test.exs`
      (NEW, `:valkey`, 4 passing BDD scenarios on the real surface) regenerates
      `docs/echo_mq/stories/flow-failure-handling.stories.md` via `mix echo_mq.stories` (3 features / 12 scenarios).

Stories: [`./emq.3.4.stories.md`](emq.3.4.stories.md) · Agent brief: [`./emq.3.4.llms.md`](emq.3.4.llms.md) ·
Runbook: [`./emq.3.4.prompt.md`](emq.3.4.prompt.md) (the build runbook) · Family: [`./emq.3.md`](../emq.3.md)
(the contract, the carve — emq.3.4 = "failure-policy + bulk", `:198`; INV3 byte-unchanged, INV7 cross-queue
honesty) · The shipped slices (the floor emq.3.4 extends): [`./emq.3.1.md`](emq.3.1.md) (`EchoMQ.Flows.add/3`,
the `:dependencies`/`:processed` subkeys, the `@complete` fan-in branch, `awaiting_children`) +
[`./emq.3.2.md`](emq.3.2.md) (`children_values/3` / `dependencies/3`, the real-result `complete/5`, the N1
lifecycle carry emq.3.4 extends) + [`./emq.3.3.md`](emq.3.3.md) (the `flow:outbox` + `EchoMQ.Pump.sweep/1`'s
`deliver_flow_completions` + `@flow_deliver` + the `:processed` HSETNX idempotency guard + the `parent_queue`
field + the B5 lifecycle carry — the cross-queue mechanism the fail-deliver rides) · This rung's ledger (the
scope fork): [`./emq-3-4.progress.md`](../../progress/emq-3-4.progress.md) (T-1 the reconcile; **V-1** the grandchildren scope
fork — the arm this triad is authored to) · The v1 capability reference (READ-ONLY, the FORM not to lift):
`echo/apps/echomq/lib/echomq/flow_producer.ex` (`add/2` `:123`, `add_bulk/2` `:183`, the `fail_parent_on_failure`/
`ignore_dependency_on_failure`/`remove_dependency` options `:78-82`/`encode_job_opts` `:468-483`, the recursive
`build_flow_commands` `:238`/`:364-374` the grandchildren tree, the data-value `parent_key` `:354/327` v2 does
NOT lift) + `echo/apps/echomq/lib/echomq/job.ex` (`get_ignored_children_failures/1` `:885` over `job_failed`
`:298` the `:failed` HASH — the `ignored_failures/3` parity; `job_unsuccessful` `:302` the `:unsuccessful` set) ·
As-built surface (the floor, **re-pinned at the POST-build reconcile, Stage 5 — the lag-1 law, the emq.3.4 build
moved it; these are the anchors emq.3.5 reconciles against**): `echo/apps/echo_mq/lib/echo_mq/flows.ex`
(`add/3` `:181` — the policy flags; **`add_bulk/3` `:218`** SHIPPED (N flows, fail-closed per flow, SEQUENTIAL
over the connector); **`ignored_failures/3` `:295`** SHIPPED (the `:unsuccessful` HGETALL); `children_values/3`
`:261` the `<> ":processed"` read precedent; `dependencies/3` `:332`; **`policy_token/1` `:359`** the host
both-flags-true→ignore-dep resolver; `add_cross_queue/5` + `land_children/4` `:444-460` the host-orchestration
`add_bulk/3` reuses, where the host `HSET` writes `parent_policy` on the child row after the byte-frozen
`@enqueue_flow_child` EVAL; same-queue `parent_policy` via a host `HSET` after the byte-frozen `@enqueue_flow`)
+ `echo/apps/echo_mq/lib/echo_mq/jobs.ex` (`@retry` `:252`, the **dead-letter arm `:281-303`** — the 5-statement
morgue body byte-frozen (`HSET last_error` `:281` … `HINCRBY metrics:failed` `:285` … `return 'dead'` `:303`)
with the **ADDITIVE failure branch inserted `:286-302`** (the `sq:fp`/`sq:id`/`xq:fp`/`xq:id` arms, dispatched on
a single combined marker `ARGV[7]`, BETWEEN `HINCRBY metrics:failed` and `return 'dead'`); `@complete` `:175`
with the fan-in + cross-queue emit `:204-219` **BYTE-UNCHANGED**, `complete/5` `:456`, `parent_of/3` `:503` +
**`parent_fail_of/3` `:535`** SHIPPED (the host read of `parent`/`parent_queue`/`parent_policy`), `policy_arm/1`
`:559`, `retry/7` `:593` (extended to append the per-arm keys/ARGV), `@extend_locks` the A-1 slot-rooted-ARGV
precedent) + `echo/apps/echo_mq/lib/echo_mq/pump.ex` (`@flow_deliver` `:42` **BYTE-UNCHANGED**; **`@flow_fail_deliver`
`:78`** SHIPPED (the HSETNX-guarded fail-deliver, all `{P}`); `deliver_flow_completions/3` `:205`; `sweep/1`
`:170`; `split_entry/1` + `split_fail_entry`/`split_complete_entry` the KIND-dispatch by leading-empty-field tag;
`deliver_one/2` the per-entry KIND branch) + `echo/apps/echo_mq/lib/echo_mq/keyspace.ex` (`queue_key/2` `:14` +
`job_key/2` `:18` the gated builder — `job_key(q, parent) <> ":failed"`/`":unsuccessful"` composes the subkeys,
**UNEDITED, git-verified 0 diff**) + `echo/apps/echo_mq/lib/echo_mq/conformance.ex` (the **50**-scenario set;
`flow_fail_parent` `:110` / `flow_ignore_dep` `:111` / `flow_add_bulk` `:112` + their `apply_scenario` probes
SHIPPED; the prior-47 contract registry byte-unchanged) + `echo/apps/echo_mq/lib/echo_mq/admin.ex`
(`del_job` `:152` / `@drain` `wipe()` `:90` the FIXED enumerations — the N1 carry, **UNTOUCHED, git-verified 0
diff**) · Design: [`../emq.design.md`](../../../emq.design.md) §6 (the grammar — the
`job:<id>:{…,failed,unsuccessful}` subkeys ALREADY reserved, `:298-324`; `:failed`/`:unsuccessful` at `:307`),
§11.10 (the flow deferral + the owed design), §5 (no new wire class), S-6 (the declared-keys A-1 law; `:95-113`),
S-1/§6 (the braced keyspace — the slot constraint), §11.12 (the escalation protocol) · Roadmap:
[`../emq.roadmap.md`](../../../emq.roadmap.md) Movement I (the closer) · The feature catalog:
[`../emq.features.md`](../../../emq.features.md) (the emq.3 row, the `flow_producer → emq.3.4` parity row) · Approach:
[`../../elixir/specs/specs.approach.md`](../../../../elixir/specs/specs.approach.md)
