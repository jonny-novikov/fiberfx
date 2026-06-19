# EMQ.3.5 · Grandchildren / deep recursion — the fifth sub-rung (Movement I, the flow family's closer)
> ✅ **Shipped** — the as-built deliverable (verbs · conformance delta · commit) is in the [changelog](../../../../emq.changelog.md). This body is the historical spec.

> **Status: ✅ SHIPPED 2026-06-15 (NORMAL-risk, Arm A)** — the FIFTH and FINAL sub-rung of the emq.3 parent/flow
> family, BUILD-GRADE on this machine (the Director's Stage-3 review + Apollo's post-build reconcile: every D1–D6 +
> INV1–INV11 MATCH; the gate green — compile clean, 4 doctests / 346 tests / 0 failures, `Conformance.run/2` →
> `{:ok, 52}`, the ≥100 determinism loop 100/100). The family contract + the carve are [`./emq.3.md`](../emq.3.md);
> the floor it stands on shipped 2026-06-15: [`./emq.3.1.md`](emq.3.1.md) the single-queue flow at CONFORMANCE 45,
> [`./emq.3.2.md`](emq.3.2.md) the child-result reads at 46, [`./emq.3.3.md`](emq.3.3.md) the cross-queue flow at
> 47, [`./emq.3.4.md`](emq.3.4.md) the failure-policy + bulk at **50**. emq.3.5 carved the family's **sole
> remaining slice**: **grandchildren / deep recursion** — a flow tree more than one level deep (a parent → a child
> that is **itself** a flow-parent of grandchildren), the recursive cross-queue tree + multi-level fan-in the v1
> `flow_producer` provided through its recursive `build_flow_commands` (`flow_producer.ex:51-56`/`:238`/`:364-374`).
> It was the **V-1 Arm-A Out** the Director locked at emq.3.4 (grandchildren ruled OUT of emq.3.4 → **routed here**,
> recorded NOT built — the `emq-3-4` ledger D-2). **Closing emq.3.5 CLOSES Movement I**
> ([`../emq.roadmap.md`](../../../../emq.roadmap.md):101-102, :143): with the whole flow family parity-complete, the
> `apps/echomq` dissolution thesis closes for the flow surface and Movement II (the family-depth ladder, emq.4–emq.8)
> opens on a complete core.
>
> **The headline design finding (grounded against the as-built tree — §0) — AS BUILT.** Completion composes
> recursively for (almost) FREE: an intermediate node, when its children complete, is RELEASED to `pending` by the
> **byte-frozen** `@complete` fan-in (`jobs.ex:216-217`) as a REAL claimable job — claimed, processed, completed, its
> own `@complete` fans into the grandparent. So completion recursion needs only the **recursive ENQUEUE** (each
> intermediate node enqueued as a flow-parent over its children AND carrying its own
> `parent`/`parent_queue`/`parent_policy` fields — built as the unified `add/3` nested-tree clause, `flows.ex` `add/3`
> + `add_tree`/`land_node`/`hold_node`/`land_children_tree`). **FAILURE was the genuine NEW design**: emq.3.4 froze
> failure propagation at **ONE** level (`jobs.ex` `@retry` `sq:fp` arm moves a dead child's parent to `dead`,
> **inert** — no signal to the grandparent). The **recursive failure hook** — propagating an intermediate node's
> death UP to ITS parent — was the **sole genuinely-new mechanism**, built as `EchoMQ.Pump.maybe_reemit_parent_death`
> (the deliver-loop site, gated on the parent→`dead` transition via `dead_before?`) + `on_same_queue_child_death`
> (the synchronous `retry/7` site), both host-orchestrated over the byte-frozen failure machinery.
>
> **Risk: the risk TIER was itself a fork (S1, the gate fork) — RULED → NORMAL-risk.** Whether emq.3.5 edited a
> shipped Lua script again (→ HIGH-risk + Apollo MANDATORY, the emq.3.1/3.3/3.4 `@complete`/`@retry` precedent) or
> stayed host/sweep-orchestrated over the byte-frozen scripts (→ **NORMAL-risk**, the emq.3.2 reads precedent) was
> decided by the **recursive-failure mechanism fork (S2)**. **S2 RULED → Arm A** (a host/sweep-orchestrated re-emit
> over the byte-frozen scripts → **NORMAL-risk**); the build held it — every shipped `Script.new/2` body byte-frozen
> (proven by an extract-and-diff of all 19 script bodies against HEAD). Apollo ran as the fast finisher (the
> rebalance), not a mandatory adversary.

## 0 · The slice — what emq.3.5 carves, why fifth, and the design finding stated plainly

emq.3.1–3.4 built the flow family **one parent level deep** (FLAT), end to end: a parent → a flat list of children
(same-queue atomic at emq.3.1; cross-queue eventually-consistent via the `flow:outbox` + sweep at emq.3.3), the
parent held in `state = awaiting_children` with its `:dependencies` STRING counter, released when the counter
reaches zero on a child **completing** (the `@complete` fan-in, `jobs.ex:212-219` same-slot / the sweep's
`@flow_deliver` cross-slot, `pump.ex:42`) — and, since emq.3.4, **terminating on failure too** (a dead child
**fails** the parent via `@retry`'s `sq:fp`/`xq:fp` arms / `@flow_fail_deliver`, or is **ignored** and the parent
proceeds via the `sq:id`/`xq:id` arms). Every one of those mechanisms is **flat**: a child is a leaf, a parent is a
root, and a child's outcome reaches its **direct** parent and stops (emq.3.4-B3: "`fail_parent_on_failure`
propagates ONE parent level").

A **grandchildren** flow is a tree deeper than one level: a parent (the **root**), an **intermediate node** that is
itself a flow-parent of grandchildren, and the grandchildren (leaves) — the v1 module's own example
(`flow_producer.ex:40-56`: `parent_job` in `main_queue` → `child2` in `queue2` → `grandchild` in `queue3`). The
intermediate node is structurally **BOTH** a child (it carries a `parent` ref UP to the root and its own
`:dependencies` toward release) **AND** a parent (it has its own `:dependencies` counter DOWN over its
grandchildren). emq.3.5 carves exactly the recursion the flat family deferred:

1. **The recursive ENQUEUE** — `EchoMQ.Flows.add/3` accepts a **nested** flow tree (a child spec may itself carry
   `:children`), and the host **walks the tree** enqueuing each non-leaf node as a flow-parent over its children
   (the v1 `build_flow_commands` tree walk, re-derived under v2 — host-side, not in Lua), so an intermediate node
   lands held (`state = awaiting_children`, its `:dependencies` = its child count) AND carries its own
   `parent`/`parent_queue`/`parent_policy` fields toward its own parent.
2. **Multi-level COMPLETION fan-in** — proven to compose over the **byte-frozen** `@complete` (§0's finding): when
   an intermediate node's grandchildren complete, the existing fan-in releases the node to `pending`; it is then a
   real claimable job, and when its handler completes it, its own `@complete` fans into the root. **No new
   completion mechanism** — only the recursive enqueue makes it a multi-level tree.
3. **The recursive FAILURE hook** (the genuine new design, the fork S2) — when an intermediate node is moved to
   `dead` (its grandchild died under `fail_parent_on_failure`, or the node itself died), that death must **itself**
   signal the node's parent (the root) by the node's OWN policy, recursively up every hop — the multi-level analogue
   of emq.3.4's one-level propagation.

It is the **fifth** sub-rung because recursion is meaningful only after the flat core is complete: the happy-path
fan-in exists (emq.3.1), is readable (emq.3.2), crosses the slot boundary (emq.3.3), and the failure half closes
(emq.3.4). Grandchildren stand entirely **ON** those four proven mechanisms — the recursive enqueue is a host
tree-walk over the existing `add/3` admit machinery; the multi-level completion is the byte-frozen `@complete`
fan-in composing recursively; the recursive failure hook is a re-emit over the byte-frozen failure machinery (the
recommended arm). It is the family's residue: closing it closes Movement I.

## Goal

emq.3.5 builds, inside `echo/apps/echo_mq` (the family rides the shipped connector — **no `echo_wire` seam**), the
**grandchildren / deep-recursion** capability the v1 `flow_producer` named through its recursive
`build_flow_commands`, **redesigned under the v2 laws** so that:

(1) **the recursive enqueue** — `EchoMQ.Flows.add/3` accepts a **nested** flow tree (a child spec may carry its own
`:children`; the leaf shape is the emq.3.4 child spec), and the host walks the tree DEPTH-FIRST, enqueuing each
non-leaf node as a flow-parent over its children by the **existing** admit machinery (same-queue subtree atomic via
the byte-frozen `@enqueue_flow`; a cross-queue boundary host-orchestrated parent-first via the byte-frozen
`@hold_parent` + `@enqueue_flow_child`, the emq.3.3/3.4 pattern), so an intermediate node lands held
(`state = awaiting_children`, `:dependencies` = its OWN child count) AND carries its OWN
`parent`/`parent_queue`/`parent_policy` fields toward its own parent — **the v1 data-value `parent_key`
(`flow_producer.ex:354`) is NOT lifted; the parent→child link at EVERY level is the declared §6 subkey of the node
+ the host-read `parent`/`parent_queue` fields, the emq.3.1/3.3 pattern applied recursively**;

(2) **multi-level completion fan-in** — proven (not built) to compose over the **byte-frozen** `@complete`: an
intermediate node, when its grandchildren complete, is released to `pending` by the existing fan-in
(`jobs.ex:216-217`) as a real claimable job, claimed + processed + completed, its own `@complete` fanning into the
root — recursion through the existing mechanism, no new completion script;

(3) **the recursive failure hook** (the fork S2, authored to **Arm A** — host/sweep-orchestrated, the byte-frozen
scripts unedited → **NORMAL-risk**) — when an intermediate node is moved to `dead` (a grandchild died under
`fail_parent_on_failure`, or the node itself exhausted retries), the host detects the node's death-as-a-flow-child
and **re-emits** the death to the node's own parent by the node's OWN `parent_policy` — over the **same**
`@retry`/`@flow_fail_deliver`/`flow:outbox`+sweep machinery emq.3.4 founded, recursively up every hop, **idempotent**
by the same `:failed`/`:unsuccessful` HSETNX-class guard, **eventually-consistent** per hop;

(4) the conformance scenarios **`flow_grandchild`** (multi-level completion) and **`flow_grandchild_fail`**
(multi-level failure propagation) — additive minor, **50 → 52**, the prior 50 byte-unchanged, both pinning tests
re-pinned;

(5) the `:valkey` recursion suite (a three-level flow whose grandchild completes → the multi-level fan-in releases
the root; a three-level flow whose grandchild dies under each policy → the death propagates UP to the root) under
the **≥100-iteration determinism loop** (a recursive flow mints **many** ids across **many** queues — the
same-millisecond mint hazard is at its most exposed here).

The recursion adds **no new §6 key type** (every node's keys are the already-reserved `:dependencies`/`:processed`/
`:failed`/`:unsuccessful` subkeys rooted at THAT node's own `emq:{q}:job:<id>`, `emq.design.md:307`) and **no new
wire class** (the kind law reuses `EMQKIND`; the failure re-emit reuses the existing fail-entry KIND) — INV1. Under
the recommended arm (S2 · Arm A) the shipped `@enqueue_flow`/`@hold_parent`/`@enqueue_flow_child`/`@complete`/
`@retry`/`@flow_deliver`/`@flow_fail_deliver` **Lua** is **byte-unchanged** (the recursion is the host tree-walk +
the host re-emit) → **NORMAL-risk**; an S2 · Arm B ruling (in-script recursive emit) edits a shipped script →
**HIGH-risk + Apollo MANDATORY** (the S1 gate fork). `apps/echomq` is **untouched** (the capability reference).

## Rationale (5W)

- **Why** — emq.3.5 is **the rung that CLOSES Movement I** ([`../emq.roadmap.md`](../../../../emq.roadmap.md):101-102, :143).
  The flat flow family (emq.3.1–3.4) brought `echo_mq` to parity for a **one-level** flow, but the v1 `flow_producer`
  provides **arbitrary-depth** trees (its recursive `build_flow_commands`, `flow_producer.ex:238`/`:364-374`, and its
  documented `grandchild` example, `:51-56`) — so until grandchildren ship the flow parity is **incomplete** and the
  `apps/echomq` dissolution thesis cannot close for the flow surface ([`../emq.roadmap.md`](../../../../emq.roadmap.md)
  Movement I). It is the family's **sole remaining slice** (the V-1 Arm-A Out, the `emq-3-4` ledger D-2 — recorded
  NOT built), and it is **genuine new design only for FAILURE**: completion recursion falls out of the existing
  mechanism (§0), so the rung's design weight is the recursive failure hook + the recursive enqueue's correctness
  bounds (termination, slot-soundness per level).
- **What** — emq.3.5 builds: **the recursive enqueue** (`add/3` accepts a nested tree; the host walks it
  depth-first over the existing admit machinery, each intermediate node held as a flow-parent AND carrying its own
  `parent`/`parent_queue`/`parent_policy`); **multi-level completion** (proven to compose over the byte-frozen
  `@complete`); **the recursive failure hook** (the host/sweep re-emits an intermediate node's death to its own
  parent by the node's policy, over the existing fail machinery — Arm A); the **`flow_grandchild` /
  `flow_grandchild_fail`** conformance scenarios; the `:valkey` recursion suite. **Authored to S2 · Arm A** (the
  recursive-failure mechanism → host/sweep-orchestrated, the byte-frozen scripts unedited → NORMAL-risk); the
  recursive-enqueue shape is **S3** (authored to S3 · Arm A — the unified `add/3` tree walk); the **risk tier** is
  **S1** (the gate fork, decided by S2). All three OPEN for the Operator.
- **Who** — the program (the rung that **closes Movement I** and unblocks the `apps/echomq` dissolution for the
  whole flow surface); the bus's consumers, who gain **arbitrary-depth** fan-out/fan-in pipelines (a multi-stage
  pipeline whose stages are themselves sub-pipelines — the v1 `grandchild` shape). **codemojex** (prospective): a
  multi-stage job whose legs are themselves sub-pipelines (a tree, not a flat fan) — *it names no flows
  today* ([`../emq.features.md`](../../../../emq.features.md) — recorded, not asserted). The conformance
  harness, which grows by two scenarios (additive minor).
- **When** — Movement I, the flow family's **fifth and final** sub-rung, after emq.3.1 + emq.3.2 + emq.3.3 + emq.3.4
  shipped (emq.3.5 walks the `add/3` admit machinery emq.3.1/3.3 built, composes over the `@complete` fan-in
  emq.3.1 built + the `flow:outbox`+sweep emq.3.3 built, and re-emits over the failure machinery emq.3.4 built).
  SPECCED this design cycle; the forks **S1 (risk tier) / S2 (recursive-failure mechanism) / S3 (recursive-enqueue
  shape)** are surfaced to the Director for the Operator's gate. The triad is authored to the recommended arms
  (S2 · Arm A → S1 · NORMAL-risk, S3 · Arm A), so the rung is **build-ready** with no pre-build re-scope; a ruling
  the other way (chiefly S2 · Arm B → S1 · HIGH-risk) is a cheap pre-build re-scope. **Exact line anchors are
  re-pinned at the pre-build reconcile** (the lag-1 law — these anchors are the emq.3.4 post-build surface; a later
  rung between this spec and the emq.3.5 build would move them again).
- **Where** — `echo/apps/echo_mq` only: `flows.ex` (EDIT — `add/3` accepts a nested tree + the host depth-first
  tree walk; under Arm A the recursive failure re-emit lives host-side / in `EchoMQ.Pump`), `pump.ex` (EDIT under
  Arm A — the sweep's fail-deliver, on moving a node to `dead`, re-emits a fail-entry for the node's own parent —
  **the byte-frozen `@flow_fail_deliver` Lua unedited**, the re-emit host-orchestrated; an Arm-B ruling instead
  edits the `@flow_fail_deliver`/`@retry` Lua → HIGH-risk), `jobs.ex` (READ — `parent_fail_of/3`:535 is reused to
  read an intermediate node's own `parent`/`parent_queue`/`parent_policy`; under Arm A **no shipped `@retry`/
  `@complete` edit**; under Arm B an additive `@retry` recursive branch), `conformance.ex` (EDIT —
  `flow_grandchild`/`flow_grandchild_fail` + the count re-pin **50 → 52**), `test/flow_recursion_test.exs` (NEW —
  `:valkey`), the two pinning tests (EDIT — the count). **`keyspace.ex` is UNEDITED** (every node's subkeys compose
  via the existing `job_key/2`, already §6-reserved). **`admin.ex` is UNTOUCHED** (the recursion populates the SAME
  subkeys at more levels — the cleanup carry deepens, NAMED, deferred — D5). `echo_wire` is **untouched** (the
  recursion rides the shipped connector `eval`/`pipeline`). `apps/echomq` is **untouched**. Exact anchors re-pinned
  at the pre-build reconcile (the lag-1 law — the emq.3.4 build moved the surface; emq.3.5 re-pins it at its
  Stage-0).

## Scope

- **In** — the RECURSIVE flow (grandchildren / arbitrary depth): (1) **the recursive enqueue** — `add/3` accepts a
  nested flow tree (a child spec may carry `:children`); the host walks it DEPTH-FIRST over the **existing** admit
  machinery (same-queue subtree atomic via the byte-frozen `@enqueue_flow`; cross-queue host-orchestrated
  parent-first via the byte-frozen `@hold_parent` + `@enqueue_flow_child`), each intermediate node held
  (`awaiting_children`, `:dependencies` = its own child count) AND carrying its own `parent`/`parent_queue`/
  `parent_policy`; (2) **multi-level completion** — proven to compose over the byte-frozen `@complete` (an
  intermediate node released to `pending` by the existing fan-in is a real claimable job whose completion fans into
  the root); (3) **the recursive failure hook** (Arm A — host/sweep-orchestrated, the byte-frozen scripts
  unedited) — an intermediate node moved to `dead` re-emits its death to its own parent by the node's
  `parent_policy`, over the existing `@retry`/`@flow_fail_deliver`/`flow:outbox`+sweep machinery, idempotent,
  eventually-consistent per hop, recursively up every level; (4) the `flow_grandchild` / `flow_grandchild_fail`
  conformance (additive minor, the prior 50 byte-unchanged); (5) the `:valkey` recursion suite under the
  **≥100-iteration determinism loop** (the many-id, many-queue mint surface); honest-row reporting (Valkey on 6390
  the truth row).
- **Out** — (a) any **edit to a shipped Lua script** UNDER THE RECOMMENDED ARM (S2 · Arm A keeps
  `@enqueue_flow`/`@hold_parent`/`@enqueue_flow_child`/`@complete`/`@retry`/`@promote`/`@reap`/`@schedule`/
  `@flow_deliver`/`@flow_fail_deliver` **all byte-frozen** — the recursion is the host tree-walk + the host re-emit;
  an S2 · Arm-B ruling re-scopes this to an additive `@retry`/`@flow_fail_deliver` edit → HIGH-risk, the S1 gate
  fork); (b) any **new wire class** (none — the re-emit reuses the existing fail-entry KIND; no fence code, no
  `EMQ…` class); (c) any **new transport** (none — the connector `eval`/`pipeline` carries the recursion); (d) any
  **`keyspace.ex` grammar edit** (none — every node's subkeys are §6-reserved and compose via the existing
  `job_key/2`); (e) a **cycle in the flow graph** — the input is a TREE (host-validated acyclic at the add; B5), not
  a general DAG; a re-converging DAG (a node with two parents) is **Out** (the v1 form is a tree too); (f) a
  **`remove_dependency`** verb (the v1 third option, `flow_producer.ex` `encode_job_opts:480` — a manual
  dependency-removal verb; deferred with the family's residue unless the Director folds it); (g) the **TTL
  auto-cancel** of a stuck recursive flow (a node that neither completes nor dies — that is **emq.6** lifecycle
  controls, the distributed/TTL cancel, [`../emq.features.md`](../../../../emq.features.md) Movement II — not a flow rung);
  (h) the **flow-subkey CLEANUP/lifecycle** at any level (a **NAMED CARRY** to the emq.3.x lifecycle rung, D5 + the
  honest bounds — emq.3.5 **populates** the same subkeys at MORE levels, it does not retire them); (i) any **edit to
  the frozen v1 line**; the Operator's concurrent
  `echo/apps/mercury*` / `docs/mercury/**` and `docs/echo/{art,mesh}/**` work; the repo-root `html/` (and **never**
  `html/ru/`).

### The honest bounds + carried follow-ups (surfaced at authoring — recorded, not papered over)

emq.3.5 ships the RECURSIVE flow on the proven flat core; these are its honest bounds, each a **correct-for-scope**
limit, never a defect:

- **B1 — cross-queue recursion is EVENTUALLY-CONSISTENT PER HOP; latency × depth (inherited from emq.3.3/3.4
  INV5/INV6, compounded by depth).** A multi-level cross-queue flow fans in/propagates failure ONE HOP PER SWEEP
  TICK: a grandchild's completion releases the intermediate node on the node-queue's NEXT sweep tick, and the node's
  own completion (after it is claimed + processed) releases the root on the root-queue's next tick — so a D-deep
  cross-queue flow's end-to-end fan-in is bounded by **≈ D × `:tick_ms`** (default 1000ms — `pump.ex`), NOT a single
  synchronous transaction. The SAME holds for failure propagation (each hop is a sweep deliver). A **same-queue**
  subtree (every node in one queue → one slot) fans in/propagates atomically per `@complete`/`@retry` EVAL, exactly
  as the flat same-queue case does — so a same-queue D-deep flow is **D atomic hops**, each on the one slot, with no
  per-hop tick latency. **No page, story, doc, or comment may claim "atomic across queues" or "synchronous deep
  recursion."**
- **B2 — TERMINATION rests on the TREE input being ACYCLIC (host-gated at the add).** The recursive enqueue
  terminates because the input is a finite TREE — the host walk validates acyclicity (no node id appears twice in
  the tree) and bounded depth (B3) **before any wire**, raising on a malformed tree, so no cycle is ever enqueued
  (a cycle would deadlock fan-in — a node waiting on a descendant that waits on it). The engine never receives a cycle;
  the guard is host-side, at the add, the v2 grain (the tree is built host-side, not discovered in Lua). A general
  re-converging DAG (a node with two parents) is **Out** (B-Out-e): the input contract is a tree, the v1 contract
  too.
- **B3 — a DEPTH BOUND is declared (the host caps recursion depth — the fork S-Bound).** The recursive enqueue
  enforces a **maximum tree depth** (a host-side guard, raising on a deeper tree), so a pathological or accidental
  deeply-nested tree cannot enqueue an unbounded number of jobs in one call nor build a fan-in chain longer than the
  cap. The exact cap value is the fork **S-Bound** (a small finite default, surfaced for the Operator); a deeper
  tree is rejected at the add with a typed error, never silently truncated. The bound is on STRUCTURAL depth at
  enqueue, not on the runtime count of jobs (which the existing per-queue mechanics already bound).
- **B4 — SLOT-SOUNDNESS holds at EVERY level (the F-1 CROSSSLOT trap is invisible on the single-node 6390).** Each
  node's subkeys (`:dependencies`/`:processed`/`:failed`/`:unsuccessful`) are rooted at THAT node's own
  `emq:{q}:job:<id>`, carrying THAT node's `{q}` hashtag — so every same-queue subtree's flow script touches keys
  of exactly one slot (atomic), and every cross-queue boundary is host-orchestrated parent-first (separate one-slot
  EVALs, never a cross-slot script), exactly as the flat family. **The single-node engine on 6390 will NOT raise
  CROSSSLOT** (it has one slot), so the per-level slot soundness is enforced by the declared-keys review + grep at
  EACH level, never by the engine — the recursion does not relax this; it RE-ASSERTS it per hop (a deeper tree is
  more boundaries, each one a slot-soundness obligation).
- **B5 — branded ids are gated at EVERY node (the order theorem, at scale).** Every node in the tree (the root,
  every intermediate node, every leaf grandchild) is keyed through `Keyspace.job_key/2`, which gates
  `BrandedId.valid?/1` and raises before any wire (INV4); a D-deep, B-wide tree mints **one distinct branded `JOB`
  id per node** in mint order (the order theorem — distinct ids, no second index). The recursion is the rung's most
  **mint-dense** surface (a tree of many nodes minted in one `add/3` call across many queues), so the
  ≥100-iteration determinism loop (INV9) is the load-bearing proof here — a same-millisecond mint collision flakes
  only across runs, and a recursive flow gives it the most chances to fire.
- **B6 — the flow subkeys at EVERY level join the lifecycle carry, NAMED, deferred (D5, the §2 guardrail).** The
  recursion **populates** `:dependencies`/`:processed`/`:failed`/`:unsuccessful` at intermediate nodes too (every
  node is a parent of its subtree), so the at-rest carry **deepens** — but the cleanup home is the SAME: both
  FIXED-list destructive sweeps (`obliterate`'s `del_job` `admin.ex:152` **and** `@drain`'s `wipe()` `admin.ex:90`)
  gaining the flow subkeys, routed to the emq.3.x lifecycle rung, joining the emq.3.2-N1 `:dependencies`/`:processed`
  + emq.3.3-B5 `flow:outbox` + emq.3.4-B6 `:failed`/`:unsuccessful` carry. emq.3.5 adds **ZERO** cleanup (named,
  deferred); `admin.ex` is **untouched**. The recursion does not introduce a NEW subkey type to clean — it widens
  the population of the already-carried ones.
- **B7 — the family boundary (no pre-emption, no re-ship).** emq.3.5 ships the **recursive flow** only; it does
  **not** re-ship an emq.2 surface and does **not** pre-empt a Movement-II family rung (groups → emq.4, batches →
  emq.5, lifecycle/distributed-cancel → emq.6, the cache → emq.7, the proof/telemetry contract → emq.8). The
  recursive fan-out is **not** the batch family (emq.5 is bulk *consumption*; a recursive flow is a *dependency
  tree*). Closing emq.3.5 CLOSES Movement I — it is the family's last slice, not a Movement-II opener.

## Deliverables

emq.3.5 builds the recursive flow (forward-named — the surface is PLANNED, not shipped; the `file:line` below are
the **emq.3.4 post-build anchors** the recursion composes over, re-pinned at emq.3.5's pre-build reconcile, NOT
emq.3.5's own surface). The Stage-0 baseline emq.3.5 closes: `add/3` accepts a FLAT child list (no nested
`:children`), failure propagation stops at ONE level (`jobs.ex:286-290` / `pump.ex:79-84` move a dead child's parent
to `dead`, inert), and there is no `flow_grandchild`/`flow_grandchild_fail` scenario.

- **EMQ.3.5-D1 — the scope/risk gate (the forks S1/S2/S3, surfaced FIRST):** the risk-tier fork **S1** (does
  emq.3.5 edit a shipped script → HIGH-risk + Apollo, or stay host/sweep-orchestrated → NORMAL-risk), the
  recursive-failure-mechanism fork **S2** (in-script recursive emit vs host/sweep-orchestrated re-emit), and the
  recursive-enqueue-shape fork **S3** (a unified `add/3` tree walk vs a separate `add_tree/3` verb) are surfaced to
  the Director with each arm steelmanned + a recommendation (§"The surfaced forks"), routed to the Operator (the
  §11.12 escalation protocol). The triad is authored to the recommended arms (**S2 · Arm A → S1 · NORMAL-risk,
  S3 · Arm A**) so the rung is build-ready; **S2 is the gate that decides S1** and must be ruled before the
  build's risk tier (and thus Apollo's mandatoriness) is fixed. Recorded BEFORE any build artifact.
- **EMQ.3.5-D2 — the recursive enqueue (`EchoMQ.Flows.add/3` accepts a nested tree; the host depth-first tree
  walk):** `add/3` accepts a flow whose children may **themselves** carry `:children` (a nested tree; the leaf shape
  is the emq.3.4 child spec, incl. the per-child failure policy). The host **walks the tree depth-first** (the v1
  `build_flow_commands` `flow_producer.ex:238`/`:364-374` re-derived under v2 — host-side, NOT in Lua), enqueuing
  each **non-leaf** node as a flow-parent over its **direct** children by the **existing** admit machinery: a node
  whose whole subtree is same-queue lands atomically via the byte-frozen `@enqueue_flow`; a node with any
  cross-queue child lands host-orchestrated parent-first via the byte-frozen `@hold_parent` + `@enqueue_flow_child`
  (the emq.3.3/3.4 pattern). Each intermediate node lands **held** (`state = awaiting_children`, its `:dependencies`
  = its OWN direct-child count) AND, because it is itself a child of its parent, carries its own
  `parent`/`parent_queue`/`parent_policy` fields (written by the SAME host `HSET` / `@enqueue_flow_child` ARGV the
  flat family uses). **The v1 data-value `parent_key` (`flow_producer.ex:354`) is NOT lifted** — the parent→child
  link at EVERY level is the declared §6 subkey of the node + the host-read fields (INV2). The add is **fail-closed
  per node** (a node that fails to land leaves its own subtree's parent held; B-flat parity, per node) and validates
  the tree **acyclic + within the depth bound** before any wire (B2/B3). Returns a nested result
  `{:ok, tree}` mirroring the input (each node's minted id), the recursive analogue of the flat
  `{:ok, {parent_id, [child_id]}}`. Every id (every node) is gated at `Keyspace.job_key/2` (raises on an ill-formed
  id — INV4) BEFORE any wire. *Forward-named:* `EchoMQ.Flows.add/3` (the nested-tree clause) + the host tree walk,
  `flows.ex`. *(S3 · Arm A: the recursion is a clause of the existing `add/3`; an S3 · Arm-B ruling re-scopes it to
  a separate `add_tree/3` verb.)*
- **EMQ.3.5-D3 — multi-level completion fan-in (PROVEN to compose over the byte-frozen `@complete` — no new
  completion mechanism):** an intermediate node, when its **direct children** (the grandchildren of its parent)
  complete, has its `:dependencies` driven to zero by the **existing** `@complete` fan-in (`jobs.ex:212-219`
  same-slot / the sweep's `@flow_deliver` `pump.ex:42-51` cross-slot), which ZADDs the node to its `pending` set and
  HSETs its row `state = pending` (`jobs.ex:216-217`) — **the node becomes a REAL claimable job**. Claimed +
  processed + completed, the node's own `complete/5` reads ITS `parent`/`parent_queue` field (`parent_of/3:503`) and
  fans into the **root** by the same same-slot / cross-slot mechanism. So multi-level completion is the **byte-frozen
  `@complete` composing recursively** — emq.3.5 **builds no new completion script** (INV3); D2's recursive enqueue
  is what makes the tree multi-level. *Check:* the `flow_grandchild` scenario (a root → an intermediate node → a
  grandchild) — the grandchild completes → the node is released to `pending` (claimable; the node's `:dependencies`
  == 0; row `pending`) → the node is claimed + completed → the root is released. *Forward-named:* the proof is the
  scenario; the mechanism is the byte-frozen `@complete`/`@flow_deliver`.
- **EMQ.3.5-D4 — the recursive failure hook (the genuine new design; Arm A — host/sweep-orchestrated, the
  byte-frozen scripts unedited):** when an intermediate node is moved to `dead` — its grandchild died under
  `fail_parent_on_failure` (the `@retry` `sq:fp`/`xq:fp` arm `jobs.ex:286-302` or `@flow_fail_deliver` fp arm
  `pump.ex:79-84` failed it), or the node itself exhausted retries — the host detects the node's
  **death-as-a-flow-child** (the node carries its own `parent`/`parent_queue`/`parent_policy`, read HOST-SIDE via the
  reused `parent_fail_of/3:535`) and **re-emits** the death to the node's own parent by the node's OWN policy, over
  the **same** failure machinery: a **same-queue** node's death re-emits to the parent's same-slot
  subkeys; a **cross-queue** node's death re-emits a **fail-entry** into the node's own-slot `flow:outbox` (the
  existing KIND, `pump.ex:299-301`), delivered on the parent's slot by the existing sweep + `@flow_fail_deliver`. The
  re-emit is **idempotent** by the same `:failed`/`:unsuccessful` HSETNX-class guard (a re-delivered death recorded
  once), **eventually-consistent** per hop (B1), and recurses up EVERY level (the node's parent's death, if it too
  is an intermediate node, re-emits to ITS parent — the multi-level analogue of emq.3.4's one-level propagation).
  **Under Arm A the shipped `@retry`/`@flow_fail_deliver`/`@complete` Lua is BYTE-UNCHANGED** — the re-emit is
  host/sweep-orchestrated (the trigger is the sweep's fail-deliver observing a node moved to `dead`, or the host
  observing a `retry/7` that returned `:dead` for a node carrying a parent). *(S2 · Arm B re-scopes this to an
  additive in-script recursive emit on `@retry`/`@flow_fail_deliver` → HIGH-risk + Apollo MANDATORY — the S1 gate
  fork.)* *Check:* the `flow_grandchild_fail` scenario (a root → an intermediate node → a grandchild) — the
  grandchild dies under `fail_parent_on_failure` → the node is failed (`dead`, the grandchild in the node's
  `:failed`) → the node's death is re-emitted → the ROOT is failed (`dead`, the node in the root's `:failed`); under
  `ignore_dependency_on_failure` at the top hop the root proceeds; a re-delivered death propagates exactly once.
  *Forward-named:* the host/sweep recursive re-emit, `pump.ex` + `flows.ex` (the byte-frozen Lua unedited under
  Arm A).
- **EMQ.3.5-D5 — the lifecycle disposition (NAMED, a carry — the §2 guardrail discharged):** emq.3.5 **populates**
  the SAME flow subkeys (`:dependencies`/`:processed`/`:failed`/`:unsuccessful`) at INTERMEDIATE nodes too (every
  node is a parent of its subtree), so the at-rest carry **deepens** — but introduces **no new subkey type**.
  emq.3.5 **re-affirms** the carry: both FIXED-list destructive sweeps (`obliterate`'s `del_job` `admin.ex:152`
  **and** `@drain`'s `wipe()` `admin.ex:90`) enumerate the flow subkeys, routed to the emq.3.x lifecycle rung,
  joining the emq.3.2-N1 / emq.3.3-B5 / emq.3.4-B6 carry. **emq.3.5 adds ZERO cleanup** (named, deferred);
  `admin.ex` is **untouched**. *Check:* the body names the subkeys' cleanup home (both sweeps) + the owning rung;
  emq.3.5's touch-set adds no `DEL`/`HDEL`/`UNLINK` of a flow subkey; `admin.ex` is untouched.
- **EMQ.3.5-D6 — the proof:** the `:valkey` recursion suite green per-app (a three-level flow whose grandchild
  completes → the multi-level fan-in releases the root; a three-level flow whose grandchild dies under
  `fail_parent_on_failure` → the death propagates UP to the root, which moves to `dead` with the node in the root's
  `:failed`; a three-level flow with `ignore_dependency_on_failure` at the top hop → the root proceeds; both
  same-queue AND cross-queue trees); the **≥100-iteration determinism loop** owning the machine (a recursive flow
  mints MANY ids across MANY queues — the same-ms mint hazard at its most exposed, B5); the prior emq.1 +
  emq.2.{1,2,3,4} + emq.3.{1,2,3,4} suites + `Conformance.run/2` pass **unchanged** (no regression — INV3); under
  Arm A the **shipped flow + state-machine Lua is byte-unchanged** (the recursion is host-orchestrated; a per-attr
  `git diff` shows ZERO Lua-body changes — INV1/INV3); honest-row reporting (Valkey on 6390 the truth row); the two
  scenarios registered additive-minor with the prior 50 byte-unchanged; **Apollo's mandatoriness is set by S1**
  (NORMAL-risk under Arm A → Apollo a fast finisher per the rebalance; HIGH-risk under Arm B → Apollo MANDATORY).

## Invariants (runnable checks)

- **EMQ.3.5-INV1 — the wire law (no break, no new key type, no new wire class, no new transport; under Arm A no
  shipped-script edit).** emq.3.5 adds **no §6 key type** (every node's keys are the already-§6-reserved
  `:dependencies`/`:processed`/`:failed`/`:unsuccessful` subkeys rooted at THAT node's own `emq:{q}:job:<id>` —
  `emq.design.md:307`; the recursion adds NO subkey type, only more nodes); **no new wire class** (the kind law
  reuses `EMQKIND`; the recursive failure re-emit reuses the existing fail-entry KIND — no fence code, no `EMQ…`
  class); **no new transport** (the connector `eval`/`pipeline` carries the recursion). The five-code fence union
  stands unextended; the closed wire-class registry is unchanged; the §6 `suffix` production is **unedited**.
  **Under the recommended arm (S2 · Arm A) the shipped Lua is byte-unchanged** — no `Script.new/2` body in `jobs.ex`
  / `flows.ex` / `pump.ex` changes (the recursion is the host tree-walk + the host re-emit). *Check:* a `git diff`
  of every `@… Script.new/2` attribute shows **zero** body changes under Arm A; a grep of any new/changed code for a
  key not matching the §6 grammar returns empty; `keyspace.ex`'s grammar is unedited. *(An S2 · Arm-B ruling instead
  shows ONLY ADDED lines in `@retry`/`@flow_fail_deliver` — the recursive emit branch — and INV1's check becomes the
  emq.3.4 only-added-lines byte-proof; the S1 gate fork.)*
- **EMQ.3.5-INV2 — the declared-keys A-1 law at EVERY level (S-6, the slot-soundness obligation, per hop).** Every
  key any flow script touches at any level is **declared in `KEYS[]`** or grammar-rooted from a declared `KEYS[n]`
  (the `@extend_locks` `base .. 'job:' .. id` form; the byte-frozen flow scripts already satisfy this); **no key is
  read out of a data value in Lua** at any level (the v1 `parent_key` data-value form, `flow_producer.ex:354`, is
  NOT lifted — every node's `parent`/`parent_queue`/`parent_policy` are read HOST-SIDE and the host passes declared
  keys, the emq.3.1/3.3/3.4 pattern applied recursively). Each same-queue subtree's flow script touches keys of
  **exactly one slot**; each cross-queue boundary is host-orchestrated parent-first (separate one-slot EVALs). **No
  script mixes slots at any level.** *Check:* a reviewer names the single slot of every flow script's key set at
  every level the recursion reaches; a grep over any new code confirms every node's keys are host-built declared
  `KEYS[n]` or `ARGV[base] .. <literal>`, never a hash-field-to-key derivation (the F-1 CROSSSLOT trap is invisible
  on the single-node 6390 — the review + grep, not the engine, enforces it; the recursion RE-ASSERTS this per hop,
  never relaxes it — B4).
- **EMQ.3.5-INV3 — the shipped surface is byte-unchanged (under Arm A, the whole flat core — the regression
  bound).** A non-recursive flow (a flat parent + flat children) flows through emq.3.1–3.4 **exactly as shipped**;
  a non-flow job flows through `@enqueue`/`@claim`/`@complete`/`@retry` exactly as shipped; multi-level completion
  rides the **byte-frozen** `@complete` + `@flow_deliver` (INV3 is WHY D3 needs no new script). **Under Arm A every
  shipped Lua script is byte-identical** (the recursion is host-orchestrated). *Check:* the emq.1 + emq.2.{1,2,3,4}
  + emq.3.{1,2,3,4} suites + `Conformance.run/2` pass **unchanged**; the prior **50** conformance scenarios are
  byte-identical (name + contract + verdict body, git-verified); under Arm A the `git diff` of every `@…
  Script.new/2` attribute is empty. *(Under Arm B, INV3 narrows to "byte-unchanged except the additive
  `@retry`/`@flow_fail_deliver` recursive branch", proved by the emq.3.4 only-added-lines byte-check + Apollo
  MANDATORY.)*
- **EMQ.3.5-INV4 — branded identity at EVERY node (the order theorem, at scale).** `add/3` (the nested-tree clause)
  gates **every** node's id (the root, every intermediate node, every leaf) at `Keyspace.job_key/2` (which gates
  `BrandedId.valid?/1` and raises before any wire); a D-deep, B-wide tree mints **one distinct branded `JOB` id per
  node** in mint order (the order theorem — distinct ids, no second index). *Check:* an `add/3` of a nested tree
  with an ill-formed id at any node raises at `Keyspace.job_key/2` before any wire (no node lands); a well-formed
  three-level flow reads distinct `JOB…` ids at every node; the **≥100-iteration determinism loop** (INV9) is green
  every iteration over the recursion suite (the most mint-dense surface — B5).
- **EMQ.3.5-INV5 — multi-level completion is sound (a root is claimable IFF its whole subtree completed).** In a
  recursive flow, an intermediate node is released to `pending` IFF all its direct children completed, and the root
  is released IFF every intermediate node beneath it was released and then completed — completion propagates UP
  every level through the byte-frozen `@complete` fan-in. *Check (the `flow_grandchild` scenario):* a root → an
  intermediate node → a grandchild; `claim` the root → `:empty` while the grandchild is outstanding; the grandchild
  completes → the node is released (`dependencies/3` of the node == 0; node row `pending`; node claimable); the node
  is claimed + completed → the root is released (root claimable; root `dependencies/3` == 0; root row `pending`).
  Same-queue: each hop atomic; cross-queue: each hop on a sweep tick (B1).
- **EMQ.3.5-INV6 — the recursive failure hook propagates a death UP every level (the genuine new behaviour).** A
  death at any node propagates to its parent by the node's `parent_policy`, recursively to the root: under
  `fail_parent_on_failure` at every hop, a grandchild's death fails the intermediate node, whose death fails the
  root; under `ignore_dependency_on_failure` at a hop, that hop's death satisfies-and-records (the parent proceeds).
  *Check (the `flow_grandchild_fail` scenario):* a root → an intermediate node → a grandchild, all
  `fail_parent_on_failure`; the grandchild dies (exhausts retries) → the node moves to `dead` with the grandchild in
  the node's `:failed` → the node's death is re-emitted → the root moves to `dead` with the node in the root's
  `:failed`. A variant with `ignore_dependency_on_failure` at the top hop: the root **proceeds** (the node recorded
  in the root's `:unsuccessful`, the root's `:dependencies` decremented). Cross-queue: the propagation is per-hop on
  a sweep tick, never synchronous (B1).
- **EMQ.3.5-INV7 — idempotent recursive failure delivery (at-least-once → effectively-once, per hop, inherited from
  emq.3.4's keystone).** A re-delivered death at any hop **does not** double-fail or double-DECR: the re-emit
  applies its effect only when its `HSETNX` of the dead node into the parent's `:failed`/`:unsuccessful` succeeds
  (returns 1), so re-running the propagation for an already-recorded node is a **no-op** — each parent is
  failed-or-satisfied **exactly once** per child, at every level. *Check (the `flow_grandchild_fail` scenario):* the
  recursive re-emit for the same dead node runs **twice** (simulating a sweep re-delivery at the top hop) and
  asserts the root's state changed **once** (the root is `dead`, the root's `:failed` HASH has one entry for the
  node); the second deliver is a no-op.
- **EMQ.3.5-INV8 — TERMINATION + the tree contract (acyclic, depth-bounded, host-gated).** The recursive enqueue
  terminates because the input is a finite acyclic TREE within the depth bound — the host validates BOTH before any
  wire and raises on a malformed tree (a repeated node id → a cycle; a tree deeper than the B3 cap → a depth-limit
  error), so the engine never receives a cycle or an unbounded tree (B2/B3). *Check:* an `add/3` of a tree with a
  repeated node id raises a typed cycle error before any wire; an `add/3` of a tree deeper than the cap raises a
  typed depth-limit error before any wire; a valid tree enqueues exactly one job per node; no flow deadlocks on a
  descendant (the acyclicity guard precludes it).
- **EMQ.3.5-INV9 — the additive-minor conformance law.** `flow_grandchild` and `flow_grandchild_fail` are
  registered in `scenarios/0` **with their probes in the same change**; the prior **50** scenarios pass
  **byte-unchanged**; the count re-pins **50 → 52** in **both** pinning tests (`conformance_scenarios_test.exs` +
  `conformance_run_test.exs`). *Check:* the `git diff` shows only additions to `scenarios/0`; both pin tests assert
  the new total **52**; `Conformance.run/2` prints the new line count and returns `{:ok, 52}`.
- **EMQ.3.5-INV10 — the flow subkeys' lifecycle is NAMED at every level (the §2 guardrail, D5).** The spec body
  **names** the cleanup disposition for the flow subkeys the recursion populates at INTERMEDIATE nodes too — both
  FIXED-list destructive sweeps (`obliterate`'s `del_job` `admin.ex:152` **and** `@drain`'s `wipe()` `admin.ex:90`)
  enumerating the flow subkeys, routed to the emq.3.x lifecycle rung, joining the emq.3.2-N1 / emq.3.3-B5 /
  emq.3.4-B6 carry. The recursion introduces **no new subkey type** (it widens the population of the carried ones);
  emq.3.5 adds **no** cleanup. *Check:* the body names the subkeys' cleanup home (both sweeps) + the owning rung;
  emq.3.5's touch-set contains **no** `DEL`/`HDEL`/`UNLINK` of a flow subkey; `admin.ex` is untouched.
- **EMQ.3.5-INV11 — slot soundness per level + the family boundary (CLOSES Movement I).** Every same-queue subtree's
  flow script touches keys of exactly one slot; every cross-queue boundary is host-orchestrated parent-first; the
  recursion holds B4 (slot soundness per hop) at every level; emq.3.5 ships the recursive flow only — it re-ships no
  emq.2 surface and pre-empts no Movement-II family (groups → emq.4, batches → emq.5, lifecycle/TTL-cancel → emq.6,
  cache → emq.7, proof → emq.8); a recursive flow is a dependency TREE, **not** the batch family (emq.5 is bulk
  consumption). **Closing emq.3.5 CLOSES Movement I** (the flow family's last slice). *Check:* the flow scripts at
  every level build keys of exactly one slot; the deliverable touch-set is the recursive enqueue + the recursive
  failure re-emit + the two conformance scenarios; the body names the boundary and the honest bounds B1–B7; no
  deliverable touches a Movement-II surface; the body states that closing emq.3.5 closes Movement I.

## The surfaced forks — RESOLVED (the Operator ruled the recommended arms)

The recursive flow had genuine open design decisions. Each was surfaced (Arm A / Arm B, costs, a RECOMMENDATION)
and routed to the Operator (the §11.12 escalation protocol + the surface-the-fork law). **All four RULED to the
recommended arms:** **S2 · Arm A** (the keystone — a host/sweep-orchestrated re-emit over the byte-frozen scripts)
→ **S1 · NORMAL-risk** (no shipped-script edit, Apollo the fast finisher), **S3 · Arm A** (the unified `add/3`
nested-tree clause), **S-Bound · 8** (the depth cap). The build held every ruling; the steelmanned arms below are
kept as the RECORD of why each was chosen (the as-built honors the recommended arm in each case).

### FORK S1 — the RISK TIER (the gate fork): NORMAL-risk (host/sweep-orchestrated) vs HIGH-risk (a shipped-script edit)

> **The gate fork — it sets Apollo's mandatoriness.** Does emq.3.5 edit a shipped Lua script again, or stay
> host/sweep-orchestrated over the byte-frozen scripts? This is **DECIDED BY S2** (the recursive-failure mechanism):
> S2 · Arm A (host/sweep re-emit) keeps every shipped script byte-frozen → **NORMAL-risk**; S2 · Arm B (in-script
> recursive emit) edits `@retry`/`@flow_fail_deliver` → **HIGH-risk**. It is surfaced as its own fork because the
> risk tier governs the FORMATION (Apollo MANDATORY on HIGH-risk — the emq.3.1/3.3/3.4 precedent; Apollo a fast
> finisher on NORMAL-risk — the emq.3.2 precedent + the 2026-06-15 rebalance) and is the Operator's call to confirm.
>
> - **Arm A — NORMAL-risk (RECOMMENDED, the consequence of S2 · Arm A).** The recursion is host-orchestrated end to
>   end: the recursive enqueue is a host tree-walk over the byte-frozen `@enqueue_flow`/`@hold_parent`/
>   `@enqueue_flow_child`; multi-level completion is the byte-frozen `@complete`/`@flow_deliver` composing
>   recursively; the recursive failure hook is a host/sweep re-emit over the byte-frozen `@retry`/`@flow_fail_deliver`.
>   **No shipped Lua script is edited** (INV1/INV3: a `git diff` of every `Script.new/2` body is empty). *Steelman:*
>   the whole flat core (the four shipped sub-rungs) is byte-frozen, so the regression surface is the host code only;
>   the rung's risk matches emq.3.2's NORMAL-risk reads precedent; the formation is the fast lead-team (Apollo the
>   finisher, not a mandatory adversary). *Cost:* the recursive failure re-emit is host/sweep-orchestrated, so it
>   carries the same eventually-consistent-per-hop + idempotency-by-HSETNX-guard discipline the cross-queue failure
>   already has (B1) — correct, but it is host logic to get right, not a single atomic script.
> - **Arm B — HIGH-risk (the consequence of S2 · Arm B).** The recursive failure hook is an **additive in-script
>   branch** on `@retry` / `@flow_fail_deliver` (the script that fails a node ALSO emits the node's-parent fail-entry
>   in the same EVAL). *Steelman:* the death-and-re-emit is atomic on the node's slot (one EVAL), tightening the
>   no-drop window a hair beyond the host re-emit. *Cost:* it edits a **shipped** Lua script again (the emq.3.1/3.3/3.4
>   HIGH-risk surface), so **Apollo MANDATORY** + the per-attr only-added-lines byte-proof + the full HIGH-risk
>   formation — for a propagation the host can do correctly over the byte-frozen scripts (Arm A). It re-opens the
>   most-scrutinized script for marginal atomicity the eventually-consistent model does not need.
>
> **RULED: Arm A (NORMAL-risk)** — the consequence of S2 · Arm A (the ruled mechanism); it kept the whole flat core
> byte-frozen and matched the rung's true risk (host-orchestrated recursion over a proven core). INV1/INV3 and D6's
> "shipped Lua byte-unchanged" check held against the as-built (the 19-body extract-and-diff is empty); Apollo ran as
> the fast finisher.

### FORK S2 — the recursive-failure MECHANISM (the keystone): host/sweep-orchestrated re-emit vs in-script recursive emit

> **The genuine new design (§0's finding: completion composes for free; failure does not).** When an intermediate
> node is moved to `dead` (its grandchild died under `fail_parent_on_failure`, or the node itself died), that death
> must signal the node's OWN parent. By what mechanism?
>
> - **Arm A — a host/sweep-orchestrated RE-EMIT over the byte-frozen failure machinery (RECOMMENDED).** When the
>   failure machinery moves a node to `dead` (the `@retry` `sq:fp`/`xq:fp` arm `jobs.ex:286-302`, or the sweep's
>   `@flow_fail_deliver` fp arm `pump.ex:79-84`), a **host/sweep** step detects the node carries its own
>   `parent`/`parent_queue`/`parent_policy` (the reused `parent_fail_of/3:535`) and **re-emits** the node's death to
>   the node's parent by the node's policy — a same-queue node's death applied to the parent's same-slot subkeys; a
>   cross-queue node's death RPUSHed as a fail-entry (the existing KIND) into the node's own-slot `flow:outbox`,
>   delivered on the parent's slot by the existing sweep + `@flow_fail_deliver`. The natural trigger is the **sweep's
>   fail-deliver itself**: when `@flow_fail_deliver` (or the synchronous `@retry` arm) reports a node moved to `dead`
>   AND the node has a parent, the deliver loop re-emits the next hop's fail-entry (one more outbox push, drained on
>   the next tick). **No shipped Lua is edited** (→ S1 · NORMAL-risk). *Steelman:* it reuses the ENTIRE emq.3.4
>   failure machinery (the fail-entry KIND, `@flow_fail_deliver`, the HSETNX idempotency guard, the durable outbox)
>   unchanged — the recursion is "one more hop of the same delivery"; it matches the v2 grain (work + signals cross a
>   boundary by a sweep, never a cross-slot script — the promote/deliver precedent); it keeps the most-scrutinized
>   scripts byte-frozen; the eventually-consistent-per-hop model is already the cross-queue contract (B1). *Cost:* a
>   D-deep cross-queue failure takes up to D sweep ticks to reach the root (latency × depth, B1); the host/sweep must
>   be careful to re-emit **exactly once per hop** (the same HSETNX-guard discipline the flat fail-deliver already
>   uses — a re-delivered death must not re-emit a duplicate next-hop entry; the guard is "re-emit only when THIS
>   hop's `:failed`/`:unsuccessful` HSETNX succeeded", so a redelivery that finds the node already recorded does not
>   re-push).
> - **Arm B — an in-script RECURSIVE emit (an additive branch on the shipped failure scripts).** The script that
>   fails a node (`@retry`'s `sq:fp`/`xq:fp` arm, and `@flow_fail_deliver`'s fp arm) gains an additive branch: when it
>   moves a node to `dead`, IF the node carries a parent reference, it ALSO RPUSHes the node's-parent fail-entry in
>   the same EVAL. *Steelman:* the death-and-re-emit is atomic on the node's slot; the no-drop window is a hair
>   tighter (the next-hop entry is durable the instant the node dies, not on the next host step). *Cost:* the
>   parent's-parent reference is a **DATA field** on the node's row (`parent`/`parent_queue`/`parent_policy`) — reading
>   it IN Lua to build the next-hop key is the **A-1 violation** (S-6: a key derived from a hash field), so Arm B
>   must pass the node's-parent coordinates as ADDITIONAL host-supplied ARGV at the original `retry/7`/fail-deliver
>   call — meaning the HOST must, at the time it fails a node, ALREADY know the node's parent (it does — `parent_of`)
>   AND the node's-parent's parent (it would need a deeper host read), so Arm B **still needs the host to walk the
>   ancestry** and gains little over Arm A while **editing a shipped script** (→ S1 · HIGH-risk + Apollo MANDATORY).
>   It also bakes a fixed re-emit into the most-scrutinized scripts for an atomicity the eventually-consistent model
>   does not require.
>
> **RULED: Arm A (host/sweep-orchestrated re-emit)** — completion already composes for free over the byte-frozen
> scripts (§0); failure composes the same way, reusing the emq.3.4 failure machinery as "one more hop of the same
> delivery" without re-opening a shipped script. It kept emq.3.5 NORMAL-risk (S1 · Arm A), held the A-1 law cleanly
> (every ancestry read is host-side, via `Jobs.parent_fail_link/3`), and matched the v2 grain. **AS BUILT:** D4 is
> `EchoMQ.Pump.maybe_reemit_parent_death/4` (the deliver-loop re-emit, gated on the parent→`dead` transition the
> `dead_before?` read detects) + `on_same_queue_child_death/4` (the synchronous trigger `retry/7` calls on a
> same-queue child's death-to-`dead`); both re-emit a byte-faithful fail-entry (`push_fail_entry/7`) into the node's
> own-slot `flow:outbox`, delivered on the parent's slot by the byte-frozen `@flow_fail_deliver`. INV6/INV7 hold; no
> shipped Lua edited.

### FORK S3 — the recursive-enqueue SHAPE: a unified `add/3` nested-tree clause vs a separate `add_tree/3` verb

> **The producer surface.** The recursive enqueue accepts a tree. Is it a new CLAUSE of the existing
> `EchoMQ.Flows.add/3` (a child spec may carry `:children`), or a SEPARATE `EchoMQ.Flows.add_tree/3` verb?
>
> - **Arm A — a unified `add/3` nested-tree clause (RECOMMENDED).** `add/3` accepts a flow whose children may carry
>   their own `:children`; a flat flow (no nested `:children`) is the existing emq.3.1–3.4 behaviour byte-for-byte,
>   and a nested tree triggers the host tree-walk. *Steelman:* one producer verb for the whole flow family (flat is
>   the depth-1 case of a tree); the flat call is unchanged (a child with no `:children` is a leaf — the existing
>   path); it matches the v1 surface (`flow_producer.add/2` takes an arbitrarily-nested `flow_node`,
>   `flow_producer.ex:89-95`/`:122`). *Cost:* `add/3`'s `@spec` + doc grow a recursive type (a child spec's optional
>   `:children`); the flat-flow path must be provably unchanged (a leaf is the base case).
> - **Arm B — a separate `add_tree/3` verb.** A new `EchoMQ.Flows.add_tree/3` takes the nested tree; `add/3` stays
>   flat-only. *Steelman:* the flat `add/3` is untouched (zero regression surface on the existing verb); the
>   recursive verb is opt-in and separately documented. *Cost:* two producer verbs for one family (a flat flow is
>   just a depth-1 tree, so `add/3` becomes a special case of `add_tree/3` — a redundant surface); it diverges from
>   the v1 single-`add` surface; a consumer must choose the verb by depth, an avoidable API seam.
>
> **RULED: Arm A (the unified `add/3` clause)** — a flat flow is the depth-1 case of a tree, so one producer verb is
> the honest surface (the v1 grain), and the flat path stays byte-for-byte unchanged (a leaf is the base case,
> proven by the unchanged flat scenarios — `flow_add`/`flow_fanin`/… green). **AS BUILT:** `add/3` (`flows.ex`)
> branches on a pure shape test (`Enum.any?(children, &has_children?/1)`) to `add_tree/3`; a flat flow never enters
> the recursive branch (the all-same-queue flat flow still lands in one atomic `@enqueue_flow`).

### FORK S-Bound — the DEPTH CAP value (a sub-fork of B3)

> **A small operational parameter, surfaced for completeness.** B3 caps recursion depth host-side. What is the cap?
> A small finite default (e.g. **8** levels — far beyond any realistic pipeline, yet a hard stop on a pathological or
> accidental deeply-nested tree) is RECOMMENDED, configurable per-call if the Operator wants. *Steelman of a fixed
> default:* a predictable hard stop; a tree deeper than the cap is almost certainly a bug, caught at the add with a
> typed error. *Cost:* a legitimate very-deep pipeline (unlikely) would need the cap raised. This is the smallest
> fork — a single integer. **RULED: 8.** **AS BUILT:** `@max_tree_depth 8` (`flows.ex`); `validate_tree/4` raises
> `{:error, {:flow_too_deep, 8}}` on a deeper tree before any wire (the root at level 1).

**S1/S2/S3/S-Bound were the Operator's to rule, surfaced via the Director (the §11.12 escalation protocol).** All
RULED to the recommended arms (S1 · NORMAL-risk via S2 · Arm A, S3 · Arm A, S-Bound · 8); the build was performed to
those rulings and the as-built honors each. **S2 was the keystone — its Arm-A ruling fixed S1 · NORMAL-risk, so
Apollo ran as the fast finisher (the rebalance), not a mandatory adversary.**

## Definition of Done — ✅ MET (shipped 2026-06-15, NORMAL-risk, Arm A)

- [x] EMQ.3.5-D1: the forks S1 (risk tier) / S2 (recursive-failure mechanism, the keystone) / S3 (recursive-enqueue
      shape) + S-Bound (depth cap) surfaced to the Director with each arm steelmanned + a recommendation; **S2 RULED
      → Arm A** (the standing Operator instruction "build to the recommended Arm A", per the team-lead tasking — the
      `emq-3-5` ledger E-1/P-4); S1 thereby NORMAL-risk; S3 · Arm A, S-Bound · 8. Recorded BEFORE the build artifact
      (the ledger A-3).
- [x] The recursive enqueue built (D2): `EchoMQ.Flows.add/3` accepts a nested tree (S3 · Arm A — `flows.ex` `add/3`
      branches to `add_tree/3` on a pure `has_children?` shape test); the host walks it depth-first over the
      **byte-frozen** `@enqueue_flow`/`@hold_parent`/`@enqueue_flow_child` (`land_node`/`hold_node`/`land_one_child`/
      `land_children_tree`); each intermediate node held (`awaiting_children`, its own `:dependencies`) AND carrying
      its own `parent`/`parent_queue`/`parent_policy` (`write_parent_link`, all `{node}`); the v1 data-value
      `parent_key` NOT lifted (INV2); fail-closed per node (`land_children_tree`'s `reduce_while`); the tree
      validated acyclic + within the depth bound before any wire (`validate_tree/4` → `{:error, {:flow_cycle, id}}` /
      `{:error, {:flow_too_deep, 8}}`, INV8); every id gated at `Keyspace.job_key/2` at every depth (INV4).
- [x] Multi-level completion proven (D3): the `flow_grandchild` scenario (`conformance.ex`) shows an intermediate
      node released to `pending` by the **byte-frozen** `@complete` fan-in (a real claimable job) whose completion
      fans into the root, same-queue AND cross-queue — **no new completion script** (INV3, INV5); `@complete`/
      `@flow_deliver` byte-identical to HEAD.
- [x] The recursive failure hook built (D4, S2 · Arm A): a node moved to `dead` re-emits its death to its own parent
      by the node's `parent_policy`, over the existing `@retry`/`@flow_fail_deliver`/`flow:outbox`+sweep machinery,
      host/sweep-orchestrated — `EchoMQ.Pump.maybe_reemit_parent_death/4` (the deliver-loop site, gated on the
      parent→`dead` transition via `dead_before?`) + `on_same_queue_child_death/4` (the synchronous `retry/7` site,
      `jobs.ex` `retry/7` `{:ok, "dead"}` arm); the shipped Lua byte-frozen (INV1/INV3); idempotent per hop (the
      `@flow_fail_deliver` HSETNX guard + the transition gate, INV7); eventually-consistent per hop (B1); recursing
      up every level (the depth-4 proof, INV6).
- [x] The lifecycle disposition NAMED (D5, B6): the flow subkeys the recursion populates at intermediate nodes
      routed to the emq.3.x lifecycle rung (both destructive sweeps — `obliterate`'s `del_job` + `@drain`'s
      `wipe()`), joining the existing carry; emq.3.5 adds no cleanup; `admin.ex` untouched (INV10 — confirmed: no
      `admin.ex` in the rung's touch-set).
- [x] `flow_grandchild`/`flow_grandchild_fail` registered (D6/INV9, additive minor): the prior 50 scenarios
      byte-unchanged (zero removed name atoms — only the predecessor `flow_add_bulk` gained a trailing comma); the
      count re-pinned **50 → 52** in both pinning tests; `Conformance.run/2` returns `{:ok, 52}` (reproduced).
- [x] The proof (D6): the `:valkey` recursion suite green per-app (multi-level completion + multi-level failure under
      each policy, same-queue AND cross-queue, plus the same-queue depth-4 chain); the **≥100 determinism loop** green
      for the mint-dense recursion scenario (B5 — Mars 110/110, the Director 100/100; Apollo reproduced one confirming
      full suite 346/0 + a scoped 69/70 recursion loop, the one break non-reproducing in 40 → the pre-existing
      connector-teardown artifact, not the rung's mint); the emq.1 + emq.2.{1,2,3,4} + emq.3.{1,2,3,4} suites +
      `Conformance.run/2` pass unchanged (no regression — INV3); the shipped flow + state-machine Lua byte-unchanged
      (a 19-body extract-and-diff against HEAD is empty — INV1/INV3); honest-row reporting (Valkey on 6390);
      **Apollo's mandatoriness set by S1** (NORMAL-risk under Arm A → the fast finisher).
- [x] INV1–INV11 verified as runnable checks (Apollo's post-build reconcile: every one MATCH against the as-built
      surface); the spec body is synced to the as-built surface (this Z-close — the lag-1 law: the build moved the
      surface, the spec records what shipped).
- [x] **Movement I CLOSED** — with emq.3.5 shipped the flow family is parity-complete; Movement II (emq.4–emq.8)
      opens on a complete core.

### Recorded lesson — the same-queue production gap (a real bug the harden cycle closed) + the proof-depth that hid it

Two distinct facts, kept separate so the audit trail is honest (this CORRECTS an earlier "proof-depth only / feature
always correct" framing):

**(1) The same-queue half of D4 had a GENUINE PRODUCTION GAP in the first build.** `on_same_queue_child_death` existed
as a correct function but was **UNWIRED from `retry/7`** — only the tests called it. So a same-queue flow child's death
would have **HUNG its parent in production** (`:awaiting_children` forever, the node never in the root's `:failed`): no
re-emit ever propagated the node's death up the tree. The **cross-queue half WAS correct from the first build** (the
deliver-loop hook `maybe_reemit_parent_death` fires for sweep-delivered deaths). The fix (Y-1, the harden/reconcile
cycle): wire `on_same_queue_child_death` into `retry/7`'s `:dead` arm (`jobs.ex:695`) + remove **4 test-only hand-calls**
that masked the gap — a **false-green** (the L-2 "a wire fixture counts only if it byte-mirrors the producer" class: the
hand-calls simulated a re-emit the production path never ran). So D4 is complete for BOTH topologies, green for the
RIGHT reason — but the same-queue half was a real gap the harden cycle CLOSED, not a thinness in the design. **Why the
"byte-identical feature code → always correct" reasoning missed it:** it compared two POST-wiring states (the feature
code was indeed byte-identical across Mars's two reports) — but the gap was the *missing wire*, invisible to a diff of
two trees that both already carried it.

**(2) Proof-depth: a depth-3 same-queue chain cannot exercise the recursive deliver-loop hop — so depth-4 is the real
proof.** When a grandchild dies in a depth-3 chain (root → node → grandchild), `@retry`'s `sq:fp` arm fails the node
atomically and the synchronous `retry/7` trigger re-emits the node's death **straight to the root** in one hop — the
root has no parent, so the deliver loop's OWN re-emit (`maybe_reemit_parent_death` firing on a node failed BY a sweep
delivery) never runs. The recursion *generalizing* is proven only by a depth-**4** chain (root → n1 → n2 → leaf),
asserted tick-by-tick: the leaf's death fails n2 and `retry/7` re-emits n2→n1; the next sweep tick fails n1 and the
**deliver-loop** re-emits n1→root; the following tick fails the root; a further tick is a no-op. `flow_grandchild_fail`'s
`same_queue_recursion_depth4/2` helper is what proves the multi-level recursion, NOT the depth-3 case. **The Director's
mutation probe confirmed it bites:** disabling the deliver-loop re-emit (`pump.ex:301`) left the depth-4 assertion RED
while the depth-3 case stayed GREEN (and cross-queue RED), then restored net-zero. (The `emq-3-5` ledger E-1/E-2/L-1 +
the `{emq-3-5-build}` Z-closure carry the full timeline.)

Stories: [`./emq.3.5.stories.md`](emq.3.5.stories.md) ·
Runbook: `./emq.3.5.prompt.md` (the build runbook — authored at the ship run, NOT this design cycle) · Family:
[`./emq.3.md`](../emq.3.md) (the contract, the carve — emq.3.5 = "grandchildren", `:198`; INV3 byte-unchanged, INV7
cross-queue honesty) · The shipped slices (the flat core emq.3.5 composes over): [`./emq.3.1.md`](emq.3.1.md)
(`EchoMQ.Flows.add/3`, the `:dependencies`/`:processed` subkeys, the byte-frozen `@complete` fan-in branch,
`awaiting_children`) + [`./emq.3.2.md`](emq.3.2.md) (`children_values/3`/`dependencies/3`, the real-result
`complete/5`, the N1 lifecycle carry) + [`./emq.3.3.md`](emq.3.3.md) (the `flow:outbox` + `EchoMQ.Pump.sweep/1`'s
`deliver_flow_completions` + the byte-frozen `@flow_deliver` + the `:processed` HSETNX idempotency guard + the
`parent_queue` field + the B5 carry — the cross-queue completion mechanism the multi-level fan-in composes over) +
[`./emq.3.4.md`](emq.3.4.md) (the failure-policy + bulk: `parent_policy`, the byte-frozen `@retry` `sq:*`/`xq:*`
failure arms + `@flow_fail_deliver`, `parent_fail_of/3`, `policy_arm/1`, `ignored_failures/3`, the `:failed`/
`:unsuccessful` subkeys — the failure machinery the recursive failure hook re-emits over) · This rung's ledger:
`../progress/emq-3-5.progress.md` (A-1 the headline design finding; A-2 the
reconcile delta; the forks S1/S2/S3 the arms this triad is authored to) · The v1 capability reference (READ-ONLY,
the FORM not to lift): `echo/apps/echomq/lib/echomq/flow_producer.ex` (the recursive `build_flow_commands` `:238`
the depth-first tree walk + `build_parent_node_commands` `:334` + the recursion `:364-374`; `add/2` `:122`/
`add_bulk/2` `:183`; the `grandchild` example `:40-56`; the data-value `parent_key = "#{queue_key}:#{job_id}"`
`:354` v2 does NOT lift — the parent→child link at EVERY level is the declared subkey of the node + the host-read
`parent`/`parent_queue` fields) · As-built floor (the flat-core anchors emq.3.5 composes over, **the emq.3.4
post-build surface — RE-PINNED at emq.3.5's pre-build reconcile, the lag-1 law**): `echo/apps/echo_mq/lib/echo_mq/
flows.ex` (`add/3` `:181`, `add_bulk/3` `:218`, `children_values/3` `:261`, `ignored_failures/3` `:295`,
`dependencies/3` `:332`, `policy_token/1` `:359`, `add_cross_queue` `:420` + `land_children` `:452` the
host-orchestration the recursive enqueue extends, the host `HSET` of `parent`/`parent_queue`/`parent_policy` on the
child row) + `echo/apps/echo_mq/lib/echo_mq/jobs.ex` (`@complete` `:175` the fan-in `:212-219` + cross-queue emit
`:204-211` **BYTE-FROZEN**, `complete/5` `:456`, `parent_of/3` `:503`; `@retry` `:252` the dead-letter arm
`:281-303` with the failure branch `:286-302` (`sq:fp`/`sq:id`/`xq:fp`/`xq:id` on combined marker `ARGV[7]`) **the
flat-core failure machinery the recursive hook re-emits over**, `parent_fail_of/3` `:535` the host read of
`parent`/`parent_queue`/`parent_policy` **reused for an intermediate node's ancestry**, `policy_arm/1` `:559`,
`retry/7` `:593`, `@extend_locks` the A-1 slot-rooted-ARGV precedent) + `echo/apps/echo_mq/lib/echo_mq/pump.ex`
(`@flow_deliver` `:42` **BYTE-FROZEN**, `@flow_fail_deliver` `:78` the HSETNX-guarded fail-deliver all `{P}` **the
failure deliver the recursive hop re-uses**, `deliver_flow_completions/3` `:205`, `sweep/1` `:170`,
`split_entry/1` + `split_fail_entry`/`split_complete_entry` the KIND-dispatch by leading-empty-field tag,
`deliver_one/2` `:254`) + `echo/apps/echo_mq/lib/echo_mq/keyspace.ex` (`queue_key/2` `:14`, `job_key/2` `:18` the
gated builder — composes every node's `:<sub>` subkeys, **UNEDITED**) + `echo/apps/echo_mq/lib/echo_mq/
conformance.ex` (the **50**-scenario set; the 7 flow scenarios `:106-112`; emq.3.5 grows `50 → 52`, the prior 50
byte-unchanged) + `echo/apps/echo_mq/lib/echo_mq/admin.ex` (`del_job` `:152` / `@drain` `wipe()` `:90` the FIXED
enumerations — the lifecycle carry, **UNTOUCHED**) · Design: [`../emq.design.md`](../../../../emq.design.md) §6 (the
grammar — the `job:<id>:{lock,logs,dependencies,processed,failed,unsuccessful}` subkeys ALL reserved, `:305-308`;
the recursion adds no key type), §11.10 (the flow deferral + the owed design, `:447-450`), §5 (the closed
wire-class registry — no new class, `:278`), §11.12 (the escalation protocol, `:457-459`), S-6 (the declared-keys
A-1 law), S-1/§6 (the braced keyspace — the per-level slot constraint) · Roadmap:
[`../emq.roadmap.md`](../../../../emq.roadmap.md) Movement I (the closer — emq.3.5 closes it, `:101-102`/`:143`) · The
feature catalog: [`../emq.features.md`](../../../../emq.features.md) (the emq.3 row, the recursive `flow_producer →
emq.3.5` parity row) · Approach: [`../../elixir/specs/specs.approach.md`](../../../../../elixir/specs/specs.approach.md)
