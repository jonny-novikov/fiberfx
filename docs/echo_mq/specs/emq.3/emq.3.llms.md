# EMQ.3 · agent brief — the parent/flow family (the Mars build brief)

> The build brief for the emq.3 **family** — what Mars reads first, the requirements traced to stories +
> invariants, the execution topology, and the agent stories (Directive + Acceptance gate). This is the
> **family** brief; the actual build runs per sub-rung against the sub-rung's own brief (emq.3.1 first —
> [`./emq.3.1.llms.md`](./emq.3.rungs/emq.3.1.llms.md)). The spec **body** [`./emq.3.md`](emq.3.md) is authoritative;
> this brief and [`./emq.3.stories.md`](emq.3.stories.md) DERIVE from it — when a derived artifact disagrees
> with the body, the body wins. **No code is built this design cycle**; the family build is gated on the
> Operator ruling Fork A.

## References (read first, in order)

1. **The spec body** — [`./emq.3.md`](emq.3.md): the A-1-compatible flow design (the load-bearing section),
   the carve, the invariants, the three surfaced forks. **Read it before any build story.**
2. **The design canon** — [`../emq.design.md`](../../emq.design.md): **§11.10** (the deferral + "an A-1-compatible
   flow design is real design work"), **§6** (the grammar — the `job:<id>:{dependencies,processed,failed,unsuccessful}`
   subkeys the flow representation reuses; the totality property), **§5** (the closed wire-class registry — no
   new class), **S-6** (the declared-keys A-1 law), **S-1** (the braced keyspace — the slot constraint behind
   Fork A), **§11.12** (the escalation protocol).
3. **The v1 capability reference (READ-ONLY — the FORM NOT to lift)** —
   `echo/apps/echomq/lib/echomq/flow_producer.ex`: `add/2`, `add_bulk/2`, and the **data-value-rooted** tree
   (`parent_key = "#{queue_key}:#{job_id}"` from a data-value `job_id`, line 354; the `parent_info` threaded
   into each child). This NAMES the flow behaviour to port; it is **NOT** the target form — its data-value
   rooting is exactly the A-1 violation emq.3 redesigns away. Also
   `echo/apps/echomq/priv/scripts/moveToFinished-15.lua:140-141` — where v1 names the `:dependencies`/`:processed`/
   `:failed`/`:unsuccessful` subkeys (the §6 reservation's origin) and records "dedup keys are derived ONLY from
   KEYS[1]".
4. **The as-built floor (the real surface to build ON + the A-1 derivation precedent)** —
   `echo/apps/echo_mq/lib/echo_mq/jobs.ex`: `@enqueue` (the kind law first act, `EMQKIND`; declares
   `KEYS[1]=job row`, `KEYS[2]=pending`), `@claim` (`ZPOPMIN pending`, lease on `TIME`), `@complete` (the fan-in
   hook's host — note the `was_active` guard and the `p` base-derivation of lane keys), and **`@extend_locks`**
   (`jobs.ex:581-601`, **the A-1 precedent**: `local jk = base .. 'job:' .. id`, ids gated host-side at
   `jobs.ex:675`); `keyspace.ex` (`job_key/2` the gated builder that raises on an ill-formed id, `queue_key/2`);
   `conformance.ex` (the **43**-scenario set the additive-minor law grows — re-probe the live count at the
   sub-rung's reconcile). **Re-probe these at each sub-rung's pre-build reconcile** — the line numbers are
   hints; the emq.2 cluster moved the surface.
5. **The shape model** — [`./emq.2.4.md`](../emq.2/emq.2.rungs/emq.2.4.md) / [`./emq.2.4.llms.md`](../emq.2/emq.2.rungs/emq.2.4.llms.md) (the rung
   triad body + brief shape) and [`./emq.2.design.md`](../emq.2/emq.2.design.md) ADR-1 (the dependency-ordered carve
   precedent). The program law: `.claude/skills/echo-mq-program.md`; the as-built map:
   `.claude/skills/echo-mq-surface.md`.

## Requirements (numbered; each traced back to a story, forward to an invariant)

> These are the **family** requirements; each sub-rung's brief restates the subset it builds. No requirement is
> built until Fork A is ruled.

1. **R1 — the dependency tree is declared §6 subkeys of the PARENT, never data values.** The parent→child link
   is `emq:{q}:job:<parent>:dependencies` (+ `:processed`/`:failed`/`:unsuccessful`), each rooted at the parent's
   declared job key, on the parent's `{q}` slot; **no child carries a `parent_key` data value**, and **no flow
   script derives a key from a hash field**. (US3 → INV2, INV1.)
2. **R2 — the fan-in gate: a parent is in `pending` IFF its `:dependencies` count is zero.** `@enqueue_flow`
   writes the parent `state = awaiting_children` and **does not** add it to `pending`; the fan-in hook on
   `@complete` decrements the parent's count and, at zero, adds the parent to `pending`. (US2 → INV4.)
3. **R3 — the shipped `@claim` is byte-unchanged; the gate is the parent's absence from `pending`.** No new
   check inside `@claim`; a parent not yet released is simply not a `pending` member (the emq.2.2-D2
   separate-gate discipline). (US2, US4 → INV3.)
4. **R4 — the fan-in hook on `@complete` is conditioned on a parent reference; the non-flow path is
   byte-unchanged.** A child with **no** parent completes exactly as the shipped `@complete`; the decrement +
   release branch is reached ONLY when the completing child carries a parent reference. The decrement is
   **idempotent** w.r.t. a redelivered child (the double-complete guard — gate the decrement on the child's own
   state transition succeeding, the `was_active`-style guard `@complete` already uses; or use the children-id
   SET, Fork B Arm 2, which is idempotent for free). (US4 → INV3; Fork B.)
5. **R5 — every flow job is gated + minted distinct.** Parent and every child keyed through `Keyspace.job_key/2`
   (gates `BrandedId.valid?/1`, raises before any wire); a flow of N children mints **N+1 distinct** branded
   `JOB` ids in mint order. (US5 → INV5.)
6. **R6 — no new key type, no new wire class, no new transport.** The flow keys are already-registered §6
   subkeys; the kind law reuses `EMQKIND`; a flow-precondition refusal reuses an existing class or is a
   host-side guard; the flow rides the shipped connector `eval`/`pipeline` (no `echo_wire` change, no
   `SSUBSCRIBE`). (US3, US-GATE → INV1.)
7. **R7 — additive-minor conformance.** Each genuine new flow behaviour is a `scenarios/0` addition registered
   with its probe in the same change; the prior **43** are byte-unchanged; the count re-pins **43 → N** in both
   pinning tests. (US4, US-GATE → INV6.)
8. **R8 — single-queue is atomic; cross-queue is honest (Fork A).** emq.3.1's single-queue flow scripts each
   declare keys of exactly one `{q}` (one slot → atomic); the cross-queue crossing (emq.3.3) states its
   consistency model explicitly (no "atomic across queues" claim) — per the ruled Fork A arm. (US1 → INV7.)
9. **R9 — the family boundary.** Flow surface only; no Movement-II pre-emption (groups → emq.4, batches → emq.5,
   distributed-cancel → emq.6, cache → emq.7, proof/telemetry-contract → emq.8); no re-ship of an emq.2 surface;
   the flow is a dependency graph, NOT the batch family. (US6 → INV8.)

## Execution topology

- **Runtime shape.** `EchoMQ.Flows` — a new lib module (host-side API) over new inline `Script.new/2`
  attributes, calling the **shipped `EchoWire` connector** (`Connector.eval`/`pipeline`) the way `EchoMQ.Jobs`
  does. **No new process** for emq.3.1 (the single-queue flow is enqueue + fan-in-on-complete, both wire calls);
  a cross-queue completion-signal sweep (emq.3.3, Fork A Arm A) would be a `EchoMQ.Pump`-shaped opt-in child
  (the promote precedent) — designed at that sub-rung. The flow stands ON the as-built supervision tree
  unchanged.
- **The build-order task DAG (per sub-rung; emq.3.1 first).** (1) pre-build reconcile (re-probe `jobs.ex`
  `@enqueue`/`@claim`/`@complete` + `conformance.ex` count + the `@extend_locks` derivation pattern — pin the
  lag-1 anchors); (2) the flow scripts (`@enqueue_flow`; the `@complete` fan-in hook); (3) the `EchoMQ.Flows`
  host API; (4) the row-state thread (`awaiting_children` into `Metrics` state-set membership — Fork C Arm A);
  (5) the conformance scenarios (additive minor); (6) the `:valkey` + process test suites + the ≥100 loop on the
  mint-touching ones; (7) the gate ladder.
- **The EXACT files touched (emq.3.1 — the first slice; later sub-rungs extend).**
  - `echo/apps/echo_mq/lib/echo_mq/flows.ex` — **NEW** (`EchoMQ.Flows`, the host API + the inline
    `@enqueue_flow` script).
  - `echo/apps/echo_mq/lib/echo_mq/jobs.ex` — **EDIT** (the fan-in hook folded into `@complete`; the ONE
    shipped-script edit — **HIGH-RISK, Apollo MANDATORY**).
  - `echo/apps/echo_mq/lib/echo_mq/metrics.ex` — **EDIT** (the `awaiting_children` state in the state-set
    membership `get_job_state/3` reads — Fork C Arm A; a small additive change).
  - `echo/apps/echo_mq/lib/echo_mq/conformance.ex` — **EDIT** (the new flow scenarios; the count re-pin).
  - `echo/apps/echo_mq/test/flow_*_test.exs` — **NEW** (`:valkey` + process: `flow_add`, `flow_fanin`).
  - `echo/apps/echo_mq/test/conformance_scenarios_test.exs` + `conformance_run_test.exs` — **EDIT** (re-pin the
    count **43 → N**).
  - **Untouched:** `apps/echomq` (the capability reference); `echo_wire` (the flow rides the shipped connector);
    the §6 grammar in `keyspace.ex` (no new key type — `job_key/2` already builds `job:<id>` and the subkeys
    compose with `<> ":dependencies"` the way `add_log/5` composes `<> ":logs"`, `jobs.ex:458`).
- **The boundary.** The diff stays inside `echo/apps/echo_mq`. A change that reaches a third app is out of
  bounds. Agents run **NO git** (the Director commits by pathspec at the rung's close). The Operator commits
  out-of-band — watch for `AM`-status files and exclude them.

## Agent stories (Directive + Acceptance gate; per the family — each sub-rung restates its subset)

> Stated as contracts (precondition / postcondition / invariant) so the Operator and Apollo accept at the
> boundary, not by re-reading the diff. **None runs until Fork A is ruled.**

- **AS1 — the flow keyspace + the `@enqueue_flow` transition (emq.3.1).**
  *Directive:* build `EchoMQ.Flows.add/3` for a parent + same-queue children over a new inline `@enqueue_flow`
  script: kind law FIRST (`EMQKIND`); write + `ZADD pending` the child rows; write the parent
  `state = awaiting_children` and set `emq:{q}:job:<parent>:dependencies` to the child count; **do not** add the
  parent to `pending`. *Precondition:* a flow of a parent + N same-queue children, every id `JOB`-namespaced.
  *Postcondition:* N children in `pending` (claimable), the parent row present with `awaiting_children` + the
  count = N, the parent NOT in `pending`. *Invariant:* every key declared/grammar-rooted on one `{q}` slot
  (INV2, INV7); every id gated host-side (INV5); no new key type (INV1).
  *Acceptance gate:* the `flow_add` `:valkey` scenario — add a parent + 2 children, read 3 distinct `JOB…` ids,
  the 2 children claimable, the parent `:empty` with `:dependencies` = 2.

- **AS2 — the fan-in hook on `@complete` (emq.3.1 — HIGH-RISK).**
  *Directive:* fold the fan-in into the shipped `@complete`: when the completing child carries a parent
  reference (a declared `KEYS[n]` = the parent's `:dependencies` key), decrement it idempotently and, at zero,
  `ZADD` the parent to `pending` and record the child's result in the parent's `:processed` subkey; a child with
  no parent is the **byte-unchanged** shipped completion. *Precondition:* a child of a flow completes (the
  current token holder). *Postcondition:* the parent's count decremented exactly once; at zero, the parent is in
  `pending` (claimable). *Invariant:* the non-flow `@complete` path byte-unchanged (INV3); the decrement
  idempotent under a redelivered child (R4); declared keys on one slot (INV2, INV7).
  *Acceptance gate:* the `flow_fanin` `:valkey` scenario — claim the parent → `:empty` until the Nth child
  completes, claimable after; the 43 prior scenarios byte-unchanged (INV6); **Apollo re-verifies INV3 + the
  order theorem** (the shipped-script edit).

- **AS3 — the conformance additive-minor + the determinism loop (emq.3.1).**
  *Directive:* register `flow_add` + `flow_fanin` in `scenarios/0` with their probes in the same change; re-pin
  the count **43 → N** in both pinning tests; run the mint-touching flow suites under the **≥100-iteration
  determinism loop** owning the machine. *Precondition:* the prior 43 byte-unchanged. *Postcondition:* the count
  is the live total; the prior set is git-verified byte-unchanged. *Invariant:* additive minor (INV6); one green
  run is NOT proof (INV5 — the loop).
  *Acceptance gate:* `Conformance.run/2` prints N lines; both pinning tests assert N; the ≥100 loop is green for
  the flow suites; honest-row reporting (Valkey on 6390).

- **AS-FORK — the fork gate (FIRST, before any build).**
  *Directive:* present Fork A (single-queue-first vs cross-queue-from-the-start) to the Director with both arms
  steelmanned + the recommendation (Arm A); record the Operator's ruling; re-derive emq.3.1 to the ruled arm at
  the pre-build reconcile (Forks B/C are cheap pre-build re-scopes — surface, do not block). *Precondition:* the
  family body's surfaced forks. *Postcondition:* Fork A ruled, recorded BEFORE any build artifact.
  *Invariant:* no build runs until Fork A is ruled (INV7); the triad ships authored to the recommended arms.
  *Acceptance gate:* the ledger records the Fork A ruling; the emq.3.1 touch-set matches the ruled arm.

## Propagation clause (put in any sub-rung brief authored from this)

No gendered pronouns for agents; no perceptual or interior-state verbs ("sees" / "wants" / "feels") for agents
or software (components read, compute, refuse, return); no first-person narration ("we" / "I think"). Forward
tense for the unbuilt surface ("emq.3 builds …"). Every reference is a real `echo_mq`/`echo_wire` module, a real
v1 file (READ-ONLY, the form NOT lifted), or a design §. The v1 `flow_producer` is a **capability reference**,
never a thing migrated from. NO git.
