# EMQ.3.5 · user stories — grandchildren / deep recursion (the fifth sub-rung, Movement I's closer)

> Who wants the recursive flow, what they need, and how the build was verified. **✅ SHIPPED 2026-06-15 (NORMAL-risk,
> Arm A) — the Given/When/Then below are the acceptance criteria the build was verified against, and all hold against
> the as-built (Apollo's post-build reconcile: every story's criteria MATCH; the gate green — 346/0, `Conformance.run/2`
> → `{:ok, 52}`, the ≥100 loop 100/100).** Each story is Connextra with Given/When/Then acceptance, an INVEST line
> naming the invariant(s) it encodes, and a Priority/Size/Implements line; the file ends with a Coverage line mapping
> every Deliverable to ≥1 story. The standing **`EMQ.3.5-US-GATE`** carries the Valkey gate (design §7) — a structural
> gate. emq.3.5 carved the flow family's **sole remaining slice**: **grandchildren / deep recursion** (a flow tree
> deeper than one level), the **V-1 Arm-A Out** the Director locked at emq.3.4. **The headline finding (the spec body
> §0):** completion composes recursively for FREE over the **byte-frozen** `@complete` (an intermediate node, released
> to `pending` by the existing fan-in, is a real claimable job whose completion fans into the root) — so the
> **recursive failure hook** (propagating an intermediate node's death UP to its own parent) was the **sole
> genuinely-new mechanism**. **The forks RULED → S2 · Arm A** (a host/sweep-orchestrated re-emit over the byte-frozen
> scripts → S1 · NORMAL-risk), S3 · Arm A, S-Bound · 8. **Closing emq.3.5 CLOSED Movement I.**

## EMQ.3.5-US1 — the recursive-failure mechanism (and the risk tier it sets) is ruled before the build

As a **program Director**, I want the keystone fork — the recursive-failure mechanism **S2** (a host/sweep-
orchestrated re-emit over the byte-frozen scripts, or an in-script recursive emit on a shipped script) — ruled
before emq.3.5 builds, so that the rung's **risk tier S1** (and thus whether Apollo is MANDATORY) is **decided,
recorded, and the formation chosen** — not improvised mid-build.

Acceptance criteria
- Given the spec body surfaces S1 (risk tier) / S2 (recursive-failure mechanism, the keystone) / S3 (recursive-
  enqueue shape) + S-Bound (depth cap) with each arm steelmanned + a recommendation, when emq.3.5 opens, then the
  forks are surfaced to the Director and routed to the Operator (the §11.12 escalation protocol), and **no build
  artifact exists** until **S2 is ruled** (because S2 decides S1 → Apollo's mandatoriness).
- Given S2 is **RULED → Arm A** (host/sweep-orchestrated re-emit; the recommendation), when emq.3.5 builds, then
  the build's touch-set keeps every shipped Lua script **byte-frozen** (S1 · NORMAL-risk), Apollo is the fast
  finisher (the emq.3.2 precedent + the 2026-06-15 rebalance), and the recursive failure hook is host/sweep-
  orchestrated.
- Given S2 · Arm B (an in-script recursive emit) was the steelmanned alternative, when the ruling is examined, then
  it would have re-scoped D4 to an additive `@retry`/`@flow_fail_deliver` branch and flipped S1 to **HIGH-risk +
  Apollo MANDATORY** (the emq.3.4 only-added-lines byte-proof) — so the Arm-A ruling fixes the formation and the
  Operator can still choose Arm B at a known cost.

INVEST — independent (the scope/risk gate that precedes the build); testable by the ledger record (S1/S2/S3 + the
Operator's ruling) + the build's touch-set (byte-frozen Lua under Arm A); encodes EMQ.3.5-INV1, EMQ.3.5-INV11.
Priority: must · Size: 1 · Implements: EMQ.3.5-D1.

## EMQ.3.5-US2 — a consumer adds an arbitrarily-deep flow tree (grandchildren)

As a **bus consumer building a multi-stage pipeline**, I want to submit a flow **tree** — a parent whose children
may themselves be flow-parents of grandchildren, to any depth — in one call, so that a pipeline whose stages are
themselves sub-pipelines is **one submission** with the failure policy declared per node.

Acceptance criteria
- Given a nested flow `%{parent: …, children: [%{…, children: [%{…}]}]}` (a child spec may carry its own
  `:children`; the leaf shape is the emq.3.4 child spec incl. the per-child failure policy), when
  `EchoMQ.Flows.add/3` is called (the unified nested-tree clause, S3 · Arm A), then the host walks the tree
  **depth-first** and enqueues each **non-leaf** node as a flow-parent over its **direct** children by the existing
  admit machinery (a same-queue subtree atomic via the byte-frozen `@enqueue_flow`; a cross-queue boundary
  host-orchestrated parent-first via the byte-frozen `@hold_parent` + `@enqueue_flow_child`), each intermediate node
  landing **held** (`state = awaiting_children`, its `:dependencies` = its OWN direct-child count) AND carrying its
  own `parent`/`parent_queue`/`parent_policy` fields toward its own parent.
- Given a **flat** flow (no nested `:children`), when `add/3` is called, then the behaviour is the emq.3.1–3.4
  flat-flow path **byte-for-byte unchanged** (a child with no `:children` is a leaf — the base case).
- Given the parent→child link at every level, when the enqueue is examined, then it is the **declared §6 subkey of
  the node + the host-read `parent`/`parent_queue` fields** — the v1 data-value `parent_key`
  (`flow_producer.ex:354`) is **NOT** lifted (no key read out of a hash field in Lua, at any level).
- Given an **ill-formed** id at **any** node, when `add/3` is called, then it **raises** at `Keyspace.job_key/2`
  (the gated key builder) before any wire — no node lands; given a tree with a **cycle** (a repeated node id) or
  **deeper than the depth cap**, it raises a typed cycle / depth-limit error before any wire.

INVEST — independent (the recursive enqueue capability); testable by a `:valkey` scenario adding a three-level flow
(each intermediate node held with its own `:dependencies`, carrying its own `parent`/`parent_queue`/`parent_policy`)
+ the flat-flow-unchanged proof + an ill-formed-id raise + a cycle / over-depth raise; encodes EMQ.3.5-INV2,
EMQ.3.5-INV4, EMQ.3.5-INV8, EMQ.3.5-INV11. Priority: must · Size: 5 · Implements: EMQ.3.5-D2.

## EMQ.3.5-US3 — a deep flow completes bottom-up (the multi-level fan-in, for free)

As a **bus operator running a deep flow**, I want a grandchild's completion to release its intermediate node, and
the node's completion to release the root — completion propagating UP every level — so that a multi-stage pipeline
finishes only when its whole subtree has, exactly as a flat flow finishes only when its children have.

Acceptance criteria
- Given a three-level flow (a root → an intermediate node → a grandchild), when the **grandchild completes**, then
  the **byte-frozen** `@complete` fan-in (same-slot `jobs.ex:212-219`, or the sweep's `@flow_deliver` cross-slot)
  drives the node's `:dependencies` to zero and releases the node to `pending` (the node's `dependencies/3` == 0;
  the node's row `state = pending`; the node is **claimable**) — the node is now a **real job**.
- Given the released node, when it is **claimed + processed + completed**, then its own `complete/5` reads ITS
  `parent`/`parent_queue` field (`parent_of/3`) and fans into the **root** by the same same-slot / cross-slot
  mechanism, releasing the root once every intermediate node beneath it completed.
- Given the multi-level completion, when the `@complete`/`@flow_deliver` `git diff` is examined, then they are
  **byte-unchanged** — emq.3.5 builds **no new completion script** (the recursion is D2's enqueue making the tree
  multi-level; completion is the existing mechanism composing recursively).

INVEST — independent (the multi-level completion, proven to compose for free); testable by the `flow_grandchild`
`:valkey` scenario (grandchild completes → node released to `pending` → node claimed + completed → root released;
same-queue atomic, cross-queue per sweep tick) + the `@complete`/`@flow_deliver` byte-unchanged check; encodes
EMQ.3.5-INV5, EMQ.3.5-INV3, EMQ.3.5-INV1. Priority: must · Size: 3 · Implements: EMQ.3.5-D3.

## EMQ.3.5-US4 — a deep flow fails up every level (the recursive failure hook — the genuine new mechanism)

As a **bus operator running a deep flow**, I want a grandchild's **death** to propagate UP every level — failing
its intermediate node, whose death fails the root (or, where a hop opts to ignore, letting that hop's parent
proceed) — so that a poison node deep in a tree **terminates** the whole flow correctly, instead of failing one
level and leaving the ancestors hanging.

Acceptance criteria
- Given a three-level flow all `fail_parent_on_failure` (the default), when the **grandchild dies** (exhausts its
  retries), then the intermediate node is moved to `dead` with the grandchild in the node's `:failed` (the emq.3.4
  one-level propagation), AND — the recursive hook — the node's death is **re-emitted** to the node's own parent by
  the node's `parent_policy`, moving the **root** to `dead` with the node in the **root's** `:failed`. The death
  propagates UP every level to the root.
- Given a three-level flow with `ignore_dependency_on_failure` at the **top** hop (the node→root edge), when the
  node dies, then the node is recorded in the root's `:unsuccessful` and the root's `:dependencies` is **DECR**'d
  (the root **proceeds** past the ignored node) — the recursive hook honors the policy at each hop.
- Given the recursive failure hook is **host/sweep-orchestrated** (S2 · Arm A), when the `git diff` is examined,
  then **every shipped Lua script is byte-unchanged** (the re-emit reuses the existing `@retry`/`@flow_fail_deliver`/
  `flow:outbox`+sweep machinery as "one more hop"; the node's ancestry is read HOST-SIDE via the reused
  `parent_fail_of/3`, never out of a hash field in Lua — the A-1 law).
- Given a **cross-queue** deep flow, when a death propagates, then it is **eventually-consistent PER HOP** (each hop
  delivered on the next sweep tick — a D-deep cross-queue failure reaches the root in ≈ D ticks, never synchronously,
  never "atomic across queues"); a **same-queue** subtree propagates atomically per hop.
- Given the **same** death is re-delivered at a hop (a sweep crash after the deliver, before the outbox-clear), when
  the second deliver runs, then it is a **no-op** (the `HSETNX` of the dead node into the parent's
  `:failed`/`:unsuccessful` returns 0 → no second parent-fail / no second DECR / no duplicate next-hop re-emit) —
  each parent is failed-or-satisfied **exactly once** per child, at every level.

INVEST — independent (the recursive failure hook — the genuine new design); testable by the `flow_grandchild_fail`
`:valkey` scenario (a grandchild's death → the node `dead` with the grandchild in its `:failed` → the root `dead`
with the node in the root's `:failed`; an `ignore_dependency_on_failure` top-hop variant → the root proceeds;
same-queue atomic, cross-queue per sweep tick; a double re-deliver a no-op) + the shipped-Lua byte-unchanged check;
encodes EMQ.3.5-INV6, EMQ.3.5-INV7, EMQ.3.5-INV2, EMQ.3.5-INV1, EMQ.3.5-INV3. Priority: must · Size: 8 · Implements:
EMQ.3.5-D4.

## EMQ.3.5-US5 — a deep flow always terminates (acyclic, depth-bounded, host-gated)

As a **bus operator**, I want a recursive flow to be **guaranteed to terminate** — the input a finite acyclic tree
within a depth bound, validated before any wire — so that no flow can deadlock on a descendant that waits on it, and
no pathological deeply-nested tree can enqueue an unbounded number of jobs in one call.

Acceptance criteria
- Given a flow tree, when `add/3` is called, then the host validates the tree **acyclic** (no node id appears twice)
  and **within the depth cap** (S-Bound, a small finite default, e.g. 8) **before any wire**, raising a typed cycle
  error on a repeated node id and a typed depth-limit error on a too-deep tree — so the engine never receives a cycle or
  an unbounded tree.
- Given a valid tree, when it is enqueued, then exactly **one job per node** is enqueued, and no flow deadlocks on a
  descendant (the acyclicity guard precludes it).
- Given the tree contract, when a re-converging **DAG** (a node with two parents) is submitted, then it is **Out of
  scope** — the input contract is a tree (the v1 contract too); a DAG is rejected or not supported, never silently
  mis-fanned.

INVEST — independent (termination + the tree contract); testable by an over-depth raise, a cycle raise, and a valid
tree enqueuing exactly one job per node with no deadlock; encodes EMQ.3.5-INV8. Priority: must · Size: 2 ·
Implements: EMQ.3.5-D2 (the tree-validation half).

## EMQ.3.5-US6 — the deepened subkey lifecycle is named, not discovered

As a **future maintainer of the flow family**, I want the flow subkeys the recursion populates at **intermediate
nodes** (not just leaves and roots) named in the spec body as a deepened — but not new-typed — lifecycle carry, so
that the deferred lifecycle rung knows to retire them at every level — the §2 subkey-lifecycle guardrail.

Acceptance criteria
- Given emq.3.5 populates `:dependencies`/`:processed`/`:failed`/`:unsuccessful` at intermediate nodes too (every
  node is a parent of its subtree; already §6-reserved — `emq.design.md:307` — so no grammar edit), when the spec
  body is read, then it **names** their cleanup home: both FIXED-list destructive sweeps (`obliterate`'s `del_job`
  `admin.ex:152` **and** `@drain`'s `wipe()` `admin.ex:90`) enumerating the flow subkeys, routed to the **emq.3.x
  lifecycle rung** — joining the emq.3.2-N1 / emq.3.3-B5 / emq.3.4-B6 carry.
- Given the recursion widens the **population** of the carried subkeys (more nodes hold them) but introduces **no
  new subkey type**, when the at-rest concern is examined, then it is recorded as a deepened carry (the same cleanup
  home, more members), retired by the lifecycle rung's sweep.
- Given emq.3.5's scope, when its touch-set is examined, then it adds **ZERO** cleanup (no `DEL`/`HDEL`/`UNLINK` of
  a flow subkey) and `admin.ex` is **untouched**.

INVEST — independent (the lifecycle-naming guardrail); testable by the body naming the subkeys' cleanup home + the
owning rung, the touch-set containing no flow-subkey deletion, and `admin.ex` untouched; encodes EMQ.3.5-INV10.
Priority: must · Size: 1 · Implements: EMQ.3.5-D5.

## EMQ.3.5-US7 — the recursion is conformance-proven and regression-bounded (and closes Movement I)

As a **program maintainer**, I want `flow_grandchild` and `flow_grandchild_fail` registered in the conformance set
with their probes in the same change, the prior 50 scenarios byte-unchanged, and (under Arm A) every shipped Lua
script byte-frozen, so that the recursion does not silently regress the wire and the rung that **closes Movement I**
is proven on a byte-stable flat core.

Acceptance criteria
- Given `flow_grandchild`/`flow_grandchild_fail` are added to `EchoMQ.Conformance.scenarios/0` with their
  `apply_scenario` probes, when the suite runs, then the prior **50** scenarios pass **byte-unchanged** (name +
  contract + verdict body, git-verified) and the count re-pins **50 → 52** in **both** pinning tests;
  `Conformance.run/2` returns `{:ok, 52}`.
- Given the recommended arm (S2 · Arm A → S1 · NORMAL-risk), when the `git diff` of every `@… Script.new/2`
  attribute in `jobs.ex` + `flows.ex` + `pump.ex` is examined, then it is **empty** (zero Lua-body changes — the
  recursion is host-orchestrated); the emq.1 + emq.2.{1,2,3,4} + emq.3.{1,2,3,4} suites + `Conformance.run/2` pass
  unchanged.
- Given the cross-slot risk (the engine on 6390 is single-node and will **not** catch a cross-slot key), when the
  recursive enqueue + failure re-emit are reviewed, then a **declared-keys grep** confirms every flow script at
  every level touches keys of exactly one slot (no cross-slot key — the F-1 trap), enforced by the review + grep,
  not the engine.
- Given the rung's place in the ladder, when emq.3.5 ships, then the body and the dashboard record that **Movement I
  is CLOSED** (the flow family parity-complete) and Movement II (emq.4–emq.8) opens on a complete core.

INVEST — independent (the conformance + regression + cross-slot proof + the Movement-I close); testable by the two
new scenarios + both pin tests at 52 + (under Arm A) the empty Lua `git diff` + the declared-keys grep + the
Movement-I-closed record; encodes EMQ.3.5-INV9, EMQ.3.5-INV1, EMQ.3.5-INV2, EMQ.3.5-INV3, EMQ.3.5-INV11. Priority:
must · Size: 3 · Implements: EMQ.3.5-D6.

## EMQ.3.5-US-GATE — the Valkey gate (the standing structural story)

As a **program maintainer**, I want the standing Valkey gate to hold on emq.3.5, so that the recursive flow is
proven on the engine of record with honest-row reporting and the protocol invariants intact at every level.

Acceptance criteria
- Given a live Valkey on **6390** (`redis-cli -p 6390 ping` → `PONG`), when the emq.3.5 `:valkey` recursion suite +
  `Conformance.run/2` run, then every scenario passes and `run/2` returns `{:ok, 52}`; a host without Valkey runs
  the probes elsewhere and reports them as **that** row, never the truth row (honest-row reporting, S-4, design §7).
- Given the protocol invariants, when the gate runs, then: every flow script's key set at every level carries a
  **single** hashtag (slot soundness per hop, INV2); every node's keys are **declared-or-rooted** (the A-1 law); the
  flow subkeys at every level are §6-reserved (no grammar edit — INV1); the `{emq}:version` record reads
  `echomq:2.0.0` (the fence unbroken); the cross-queue propagation is observed **eventually-consistent per hop** (a
  D-deep cross-queue completion/failure reaching the root in ≈ D sweep ticks, never synchronously — B1); and under
  Arm A every shipped Lua script is byte-identical (INV1/INV3).
- Given the ≥100-iteration determinism loop owning the machine, when the mint-dense recursion scenario runs 100+
  times, then it is **green every iteration** (a recursive flow mints one branded `JOB` id per node across many
  queues — the same-millisecond mint hazard at its most exposed, B5 — surfaces only across runs).

INVEST — independent (the standing gate, every rung); testable by the `:valkey` suite + `Conformance.run/2` ==
`{:ok, 52}` on 6390 + the ≥100 loop + the per-level slot/declared-keys/fence checks; encodes the design §7 gate +
S-4 + EMQ.3.5-INV1, EMQ.3.5-INV2, EMQ.3.5-INV4, EMQ.3.5-INV5, EMQ.3.5-INV6, EMQ.3.5-INV9. Priority: must · Size: 1 ·
Implements: EMQ.3.5-D6 (the proof) — the standing gate.

## Coverage

Every Deliverable maps to ≥1 story (and every story to ≥1 invariant):

| Deliverable | Story(ies) | Invariant(s) exercised |
|---|---|---|
| **D1** — the scope/risk gate (forks S1/S2/S3 + S-Bound; S2 the keystone ruling) | US1 | INV1, INV11 |
| **D2** — the recursive enqueue (`add/3` nested-tree clause + the host depth-first tree walk; acyclic + depth-bounded) | US2, US5 | INV2, INV4, INV8, INV11 |
| **D3** — multi-level completion (proven to compose over the byte-frozen `@complete` — no new script) | US3 | INV5, INV3, INV1 |
| **D4** — the recursive failure hook (host/sweep re-emit, idempotent per hop, eventually-consistent per hop, up every level) | US4 | INV6, INV7, INV2, INV1, INV3 |
| **D5** — the deepened lifecycle disposition (the flow subkeys at intermediate nodes NAMED, deferred) | US6 | INV10 |
| **D6** — the proof (conformance 50→52, regression bound, ≥100 loop, byte-frozen Lua under Arm A, Movement I closed) | US7, US-GATE | INV1, INV2, INV3, INV5, INV6, INV9, INV11 |

The standing **EMQ.3.5-US-GATE** carries the Valkey gate (design §7) for every rung — a structural gate. Every
invariant INV1–INV11 is exercised by ≥1 story; every Deliverable D1–D6 is covered. The headline observable — a deep
flow **completes bottom-up** (the multi-level fan-in, free over the byte-frozen `@complete`) and **fails up every
level** (the recursive failure hook, the genuine new mechanism), with cross-queue propagation **eventually-consistent
per hop** (never "atomic across queues"), **terminating** (acyclic + depth-bounded), and **idempotent per hop** (a
re-delivered death exactly once) — is stated in US2 + US3 + US4 + US5 + US-GATE (INV5/INV6/INV7/INV8) and is the
acceptance face of the family's last slice that **closes Movement I**.
