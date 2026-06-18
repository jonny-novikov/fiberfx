# EMQ.3 · The parent/flow family — the A-1-compatible flow design (Movement I, the closer)

> **Status: 🔨 OPEN — building sub-rung by sub-rung** (the family spec + the carve, authored the founding design
> cycle; **emq.3.1 the single-queue flow SHIPPED 2026-06-15** + **emq.3.2 the child-result reads SHIPPED
> 2026-06-15** (ratified — the durable harness `emq_3_2_check.sh` 8/8 Director-reproduced; forks R1·B + R2·A
> ruled, conformance 46, O1 closed); the cross-queue flow (emq.3.3) + failure-policy/bulk (emq.3.4) ahead — see
> **The carve** below). emq.3 is **the cluster that CLOSES Movement I**:
> the parent/child *flow* family the v1
> `flow_producer` provided, **redesigned from scratch** so a parent becomes claimable only when its children
> complete (fan-in) **under the v2 A-1 declared-keys law** — the design work design §11.10 / decision 10 named
> as owed ("an A-1-compatible flow design is real design work for the family rungs"). The v1 line
> (`apps/echomq`) is a **capability reference** — the list of flow behaviour to port — never a thing migrated
> from, and its *form* is the thing this rung must NOT lift (its scripts root key operands in data values).
> The family decomposes into sub-rungs (**emq.3.1**, 3.2, …) the way emq.2 decomposed (emq.2.1–2.4); this body
> is the family contract + the carve, and [`./emq.3.1.md`](./emq.3.rungs/emq.3.1.md) carves the first buildable slice.
> **Risk: HIGH** — it founds a new key-derivation shape (the flow subkeys) and a completion-gate transition on
> the shipped `@complete`; Apollo is mandatory at the build of any sub-rung that edits a shipped script.

## 0 · The challenge — why flows were deferred, and what makes the redesign possible

**The deferral, stated exactly (design §11.10 / decision 10).** "The parent/flow and scheduler script families
are not in the 2.0 bundle (their v1 forms **root key operands in data values**, structurally inexpressible
under the declared-keys invariant); calls land on the existing typed `{:error, {:script_not_found, name}}`; an
**A-1-compatible flow design is real design work** for the family rungs." The scheduler family was solved at
emq.1 (`EchoMQ.Repeat`/`EchoMQ.Pump`, the schedule-set visibility fence); the **flow** family is the residue,
and it owes a genuine redesign, not a port.

**What "roots key operands in data values" means in the v1 form (the thing NOT to lift).** The v1
`EchoMQ.FlowProducer` (`echo/apps/echomq/lib/echomq/flow_producer.ex`, FROZEN, READ-ONLY) builds the
parent→child dependency graph from the flow's **data**: `parent_key = "#{queue_key}:#{job_id}"` (line 354,
composed from a **data-value** `job_id` the producer generates, `generate_id/0` line 485) and threads that
`parent_key` into each child's job hash; the v1 completion script (`moveToFinished-15.lua`) then derives the
parent's dependency sets *from those stored data values* and decrements the parent's pending-children count.
Two structural facts make that v1 form illegal under v2:

1. **Data-rooted keys.** The parent reference a child's completion follows is a **stored data value** (the
   `parent_key` in the child's hash), not a key declared in `KEYS[]` or derived from a declared `KEYS[n]` root
   by the registered grammar — the **A-1 violation** (S-6; design §11.10). A v2 Lua key MUST be declared or
   grammar-rooted; a key read out of a hash field is neither.
2. **Cross-queue spanning under braces.** A v1 flow spans queues (the module's own example: parent in
   `orders`, children in `validation`/`inventory`/`payments`). Under the v2 braced keyspace
   (`emq:{q}:<type>`, S-1; design §6) the parent and a child in different queues land on **different cluster
   slots**, so a **single** Lua script — atomic only within one slot — **cannot** touch both the parent's
   completion-gate key and the child's row in one call.

**What makes the redesign possible — the grammar already reserved the representation.** The §6 grammar
(design §6, the `suffix` production) reserved, at the founding, exactly the flow subkeys:

```
suffix := … | "job:" jid [":" sub]   sub ∈ {lock, logs, dependencies, processed, failed, unsuccessful}
```

So `emq:{q}:job:<parent-id>:dependencies` and `…:processed` (and `:failed`/`:unsuccessful`) are **declared §6
job subkeys**, each **rooted at the parent's declared job key**, each carrying the **parent's `{q}` hashtag**
— i.e. on the parent's slot. The dependency tree, expressed as *these subkeys of the parent* (not as a
`parent_key` stuffed into the child's data), is **A-1-clean and slot-sound by construction**. The v1
completion script already *names* these very subkeys (`moveToFinished-15.lua:140-141`:
`jk .. ":dependencies", jk .. ":processed", jk .. ":failed", jk .. ":unsuccessful"`) and records the v2 rule in
its own header ("dedup keys are derived ONLY from KEYS[1]") — the founding reserved the slots for exactly this
rung. The redesign's job is to **carry the dependency tree in the declared subkeys** and to settle the one
thing the grammar does not decide for you: **what happens at a queue boundary**, where atomicity stops.

**The as-built derivation precedent (the A-1 pattern to extend).** `EchoMQ.Jobs.@extend_locks`
(`jobs.ex:581-601`) already iterates a list of ids and derives each per-job key **in-script from a declared
queue base root** — `local jk = base .. 'job:' .. id` (line 591), where `base = ARGV[1]` carries the queue's
`{q}` (and **every id is gated `Keyspace.job_key/2` host-side before the wire**, `jobs.ex:675`). That is the
exact A-1 grammar-derived shape the flow scripts extend: declare the parent base root, derive the
dependency/processed subkeys and the child rows **of the same queue** from it; gate every branded id at the
key builder before any wire.

## Goal

emq.3 builds, inside `echo/apps/echo_mq` (+ no `echo_wire` seam — the family rides the shipped connector),
the **parent/child flow** capability the v1 `flow_producer` named, **redesigned under the v2 laws** so that:
(a) a flow's parent→child dependency graph is carried in **declared §6 job subkeys rooted at the parent** (not
in data values); (b) a parent is **invisible to `claim` until all its children complete** (the fan-in gate);
(c) a child's completion **decrements the parent's outstanding-dependency count** and, at zero, **releases the
parent** to `pending` — all under the A-1 declared-keys law, branded `JOB` ids gated at the key builder, the
server clock on any lease, and the additive-minor conformance growth. The family carves into sub-rungs;
**emq.3.1** carries the first buildable slice (the single-queue flow — see [`./emq.3.1.md`](./emq.3.rungs/emq.3.1.md)) and
the later sub-rungs extend it (the cross-queue completion signal, the child-result reads, the failure-policy
options) per **The carve** below.

## Rationale (5W)

- **Why** — emq.3 is **the rung that closes Movement I**. The emq.2 parity cluster (emq.2.1 read · emq.2.2 ops
  · emq.2.3 watch · emq.2.4 the closer) brought `echo_mq` to feature parity for the v1 read/ops/watch floor,
  but the flow family was **explicitly deferred** at the 2.0 founding as owed design work (design §11.10; the
  emq.2.4 gap table G11). Until flows ship, the program thesis — `apps/echomq` dissolves when nothing depends
  on what it alone provides ([`../emq.roadmap.md`](../../emq.roadmap.md) Movement I) — **cannot close** for
  Movement I: the v1 line alone carries fan-out/fan-in pipelines. emq.3 is the last Movement-I parity surface;
  closing it lets Movement I close and Movement II (the family-depth ladder, emq.4–emq.8) open on a complete
  core. It is **genuine new design** (not a port) precisely because the v1 form is structurally illegal under
  v2 — the design canon named this and assigned it here.
- **What** — emq.3 builds the flow surface as a new module (forward-named **`EchoMQ.Flows`**) over new inline
  `Script.new/2` transitions, **plus** a fan-in hook on the shipped `@complete` path, plus the declared §6 flow
  subkeys of the parent. The carved first slice (emq.3.1) is the **single-queue flow**: a parent and its
  children **in the same queue** (one slot → one atomic script the whole way), with the parent's
  outstanding-dependency count in `emq:{q}:job:<parent>:dependencies` and the parent held out of `pending`
  until the count reaches zero. The later sub-rungs (the carve) add the **cross-queue** flow (the
  completion-signal hop across slots — the fork below), the **child-result reads** (the v1
  `get_children_values`/`get_dependencies` surface over the `:processed` subkey), and the **failure-policy
  options** (`fail_parent_on_failure` / `ignore_dependency_on_failure` over `:failed`/`:unsuccessful`).
- **Who** — the program (the rung that closes Movement I and unblocks the `apps/echomq` dissolution for the
  flow surface); the bus's consumers, who gain fan-out/fan-in pipelines (a parent job that completes only when
  a set of child jobs do); the conformance harness, which grows by the new flow scenarios (additive minor).
  **codemojex** (the worked consumer) does not name flows today — a round that gates on a set of per-player
  scoring jobs is the prospective shape ([`../emq.features.md`](../../emq.features.md)
  lines 178-180 — recorded, not asserted).
- **When** — **Movement I, the closer**, after the emq.2 cluster ships (the flow scripts stand ON the as-built
  state machine `EchoMQ.Jobs` — `@enqueue`/`@claim`/`@complete` — which the cluster proved at depth at
  emq.2.4). SPECCED this design cycle; the **flow-shape fork (Fork A)** settles with the Operator BEFORE the
  emq.3.1 build (the recommended arm is the one this triad is authored to). emq.3.1 builds first; 3.2+ follow
  one increment per run.
- **Where** — `echo/apps/echo_mq` only: the new `EchoMQ.Flows` module + its inline `Script.new/2` attributes,
  the fan-in hook folded into the shipped `EchoMQ.Jobs.@complete` (the one shipped-script edit — HIGH-RISK),
  the new flow conformance scenarios in `conformance.ex`, the new `:valkey`/process test suites. `apps/echomq`
  is untouched (the capability reference). `echo_wire` is **untouched** — the flow rides the shipped connector
  `eval`/`pipeline` (no new transport, no new connector verb). Exact key, structure, and script anchors are
  pinned at each sub-rung's pre-build reconcile (the lag-1 discipline — the emq.2 cluster moved the `echo_mq`
  surface this family builds on).

## The A-1-compatible flow design (the load-bearing section)

The design carries the **dependency graph** and the **fan-in completion** entirely in **declared §6 keys
rooted at the parent**, on the parent's slot, under the A-1 law. Stated as the keyspace, the transitions, and
the claim gate.

### The flow keyspace (declared §6 subkeys of the parent — no new key TYPE)

Every flow key is an **already-registered §6 `job:<id>:<sub>` subkey of the PARENT**, so emq.3 adds **no new
§6 key type** and **no grammar change** (INV1):

| Key | §6 form | Slot | Holds |
|---|---|---|---|
| the parent's pending-children counter | `emq:{q}:job:<parent>:dependencies` | parent's (`{q}`) | the **outstanding** child count (a STRING counter, or the child-id SET — Fork B); zero ⇒ the parent's deps are met |
| the parent's processed-children record | `emq:{q}:job:<parent>:processed` | parent's (`{q}`) | the completed children's results (the `:processed` subkey the v1 `get_children_values` reads), keyed by child id |
| the parent's failed-children record | `emq:{q}:job:<parent>:failed` | parent's (`{q}`) | a failed child under `fail_parent_on_failure` (the later failure-policy sub-rung) |
| the parent's ignored-children record | `emq:{q}:job:<parent>:unsuccessful` | parent's (`{q}`) | an ignored failure under `ignore_dependency_on_failure` (the later sub-rung) |

A child carries **no `parent_key` data value** (the v1 form retired). The link is **the parent's subkey**, not
**the child's data**. The parent is identified to the child's completion path **by a declared `KEYS[n]`** (the
parent's dependency-subkey key, passed in `KEYS[]`), never by a value read out of the child's hash.

### The new transitions (inline `Script.new/2`, declared keys, branded ids gated host-side)

Forward-named; the exact script bodies are authored at emq.3.1's build to the as-built `@enqueue`/`@complete`
shape (the lag-1 reconcile pins them). The contract:

- **`@enqueue_flow`** (the parent + same-queue children, one atomic script — emq.3.1). Declares: the parent
  row `KEYS[1]`, the parent's `:dependencies` counter `KEYS[2]`, the queue's `pending` set `KEYS[3]`, and the
  child rows `KEYS[4..]` (each a `Keyspace.job_key/2`-gated, same-`{q}` child key passed in `KEYS[]`). The
  script: (a) the kind law FIRST (`JOB`-namespaced, `EMQKIND` — the `@enqueue` first act); (b) writes the
  child rows `state = pending` and `ZADD`s them to `pending` (the children are immediately claimable); (c)
  writes the parent row `state = awaiting_children` (a new row state — INV2 names it) and **sets the parent's
  `:dependencies` counter to the child count**; (d) does **NOT** add the parent to `pending` (the fan-in gate
  — the parent is invisible to `claim` until the counter hits zero). The whole flow is **one atomic script**
  because every key shares the one `{q}` slot (the single-queue carve — Fork A, Arm A).
- **the fan-in hook on `@complete`** (the one shipped-script edit — HIGH-RISK). When a child with a parent
  completes, the completion path **decrements the parent's `:dependencies` counter** and, **at zero**, **adds
  the parent to its `pending` set** (the parent becomes claimable) and records the child's result in the
  parent's `:processed` subkey. The hook is conditioned on the child carrying a parent reference — a **child
  with no parent is the unchanged v2 completion** (the shipped `@complete` path byte-unchanged for the
  non-flow case; INV3). *Single-queue (emq.3.1):* the parent's subkeys share the child's `{q}` slot, so the
  decrement-and-release is **inside the child's `@complete` script, atomically** (one declared `KEYS[n]` = the
  parent's `:dependencies` key). *Cross-queue (a later sub-rung):* the parent is on a different slot, so the
  decrement crosses a slot boundary — **the fork below (Fork A)** decides the mechanism (a completion-signal
  hop, not an atomic in-script touch).

### The claim gate (the parent is invisible until fan-in completes)

The fan-in gate needs **no new claim path**: emq.3.1's `@enqueue_flow` simply **does not put the parent in
`pending`** until the fan-in hook releases it, so the **shipped `@claim` is byte-unchanged** — it pops from
`pending`, and a parent not yet in `pending` is simply not there to pop. The parent's row exists
(`state = awaiting_children`, browseable/introspectable) but is **not a `pending` member**, so `ZPOPMIN
pending` never returns it. This is the **separate-gate form** the cluster favored (emq.2.2-D2 kept `@claim`
byte-unchanged by gating *outside* it); emq.3.1 reuses that discipline — **the gate is the parent's absence
from `pending`, enforced at enqueue and lifted at fan-in**, not a new check inside `@claim`.

**Why this is A-1-clean.** Every key the flow scripts touch is `emq:{q}:job:<id>[:sub]` or `emq:{q}:pending` —
each declared in `KEYS[]` or derived from the declared queue base root by the §6 grammar (the `@extend_locks`
precedent); every branded `<id>` is gated `Keyspace.job_key/2` host-side before the wire (INV5); in the
single-queue carve every key shares the one `{q}` slot, so every script is **slot-sound and atomic** (S-6, the
A-1 law). The data-value rooting is **gone**: the parent→child link is a declared subkey of the parent, never
a value stuffed into a child's hash.

## The carve into sub-rungs

emq.3 decomposes the way emq.2 did (the [`./emq.2.design.md`](../emq.2/emq.2.design.md) ADR-1 precedent — a
dependency-ordered carve, one increment per run, each a full triad + an `emq.3.N.prompt.md` runbook). The
carve is authored to **Fork A, Arm A** (single-queue first — see **The surfaced forks**):

| Sub-rung | The slice | Builds | Depends on |
|---|---|---|---|
| **emq.3.1** ✅ SHIPPED | **the single-queue flow (the first buildable slice)** | `EchoMQ.Flows.add/3` for a parent + same-queue children; `@enqueue_flow`; the `:dependencies` counter; the fan-in hook on `@complete` releasing the parent at zero; the `awaiting_children` row state; the claim gate (parent absent from `pending`). Conformance: `flow_add`, `flow_fanin` (43→**45**). HIGH-risk (the `@complete` fan-in edit; Apollo BUILD-GRADE, kill 3/3). | the as-built `EchoMQ.Jobs` (`@enqueue`/`@claim`/`@complete`) — the emq.2 cluster |
| **emq.3.2** ✅ SHIPPED | the **child-result reads** | `EchoMQ.Flows.children_values/3` (`HGETALL` of `:processed` → `{:ok, %{child_id => result}}`) + `dependencies/3` (`GET` of the `:dependencies` STRING counter → `{:ok, non_neg_integer()}`, `{:ok, 0}` sentinel) — the v1 `get_children_values`/`get_dependencies` parity; the parent handler reads its children's results; **closes emq.3.1's O1** (the `:processed` value → a real result via the existing `ARGV[5]` seam, the `@complete` Lua byte-unchanged — `complete/5` with `result \\ nil`, host-only). Conformance: `flow_children_values` (45→**46**). **NORMAL-risk** (no shipped-script edit); forks **R1** (result-payload) → **Arm B** + **R2** (deps-read) → **Arm A** RULED (Operator 2026-06-15). Ratified — the durable harness `emq_3_2_check.sh` 8/8, Director-reproduced (the `emq-3-2` cycle). | emq.3.1 (shipped) |
| **emq.3.3** | the **cross-queue flow** (the slot-boundary crossing) | the completion-signal hop **per Fork A's ruled cross-queue mechanism** (a parent and children in *different* queues; the fan-in decrement crosses a slot via the chosen signal — a per-queue promote-style sweep, or a pipelined two-key call, NOT an atomic single script). Conformance: `flow_cross_queue`. | emq.3.1 (+ Fork A ruled) |
| **emq.3.4** ✅ SHIPPED | the **failure-policy options + bulk** | `fail_parent_on_failure` / `ignore_dependency_on_failure` (the `:failed`/`:unsuccessful` subkeys, the v1 options) + `EchoMQ.Flows.add_bulk/3` (the v1 `add_bulk/2` parity, **sequential** — one `add/3` per flow, fail-closed per flow) + `ignored_failures/3`; the additive `@retry` dead-letter branch + `@flow_fail_deliver` (idempotent), the existing `@retry` body + `@complete`/`@flow_deliver`/`@enqueue_flow*` byte-frozen. Conformance: `flow_fail_parent`, `flow_ignore_dep`, `flow_add_bulk` (47→50). Apollo BUILD-GRADE, HIGH-risk. | emq.3.1 |

emq.3.1 is the **first buildable workload** because it is the **smallest coherent flow that exercises the whole
new mechanism** (the declared-subkey dependency tree + the fan-in gate + the claim gate) **without** the
cross-slot complication — the single-queue case is fully atomic, so it founds and proves the A-1-compatible
design on one slot before the cross-queue hop (the genuinely hard, fork-gated part) is built. It is the tracer
bullet for the family (the master-invariant discipline — one thin vertical slice, the skeleton running).

## Invariants (runnable checks)

- **EMQ.3-INV1 — the wire law (no break, no new key type).** emq.3 adds **no §6 key type outside the grammar**
  (the flow keys are the already-registered `job:<id>:{dependencies,processed,failed,unsuccessful}` subkeys);
  **no new wire class** (the kind law reuses `EMQKIND`; a flow-precondition refusal reuses an existing class or
  is a host-side guard — never a new fence code); **no `SSUBSCRIBE`/new transport**. The five-code fence union
  stands unextended. *Check:* a grep of the new scripts for any key not matching `emq:{q}:…` of the §6 grammar
  returns empty; the §6 `suffix` production is unedited.
- **EMQ.3-INV2 — declared keys, self-justified (the A-1 law — the headline).** Every Lua key in the flow
  scripts is in `KEYS[]` or derived in-script **only** from a declared `KEYS[n]` root by the registered
  grammar (the `@extend_locks` `base .. 'job:' .. id` pattern); **no key is read out of a data value** (the v1
  form is NOT lifted — the parent→child link is a declared subkey of the parent, never a `parent_key` stored
  in a child's hash). *Check:* the A-1 lint over the new scripts passes (no hash-field-to-key derivation); a
  reviewer can name the declared `KEYS[n]` root of every key the script touches.
- **EMQ.3-INV3 — the shipped surface is byte-unchanged for the non-flow case.** A job with **no parent** flows
  through `@enqueue`/`@claim`/`@complete` **exactly as before** — the fan-in hook on `@complete` is reached
  ONLY when the completing child carries a parent reference; the shipped `@claim` is **byte-unchanged** (the
  fan-in gate is the parent's absence from `pending`, not a check inside `@claim`). *Check:* the emq.1 +
  emq.2.{1,2,3,4} suites + `Conformance.run/2` pass **unchanged**; the 43 prior conformance scenarios are
  byte-identical (name + contract + verdict body, git-verified).
- **EMQ.3-INV4 — the fan-in gate is sound (a parent is claimable IFF all its children completed).** A parent
  with N children is **never** in `pending` while its `:dependencies` counter > 0, and **is** in `pending`
  once it reaches 0 (every child completed). *Check:* a `:valkey` scenario `flow_fanin` — enqueue a flow of N
  children, `claim` the parent → `:empty` until the (N−1)th child completes, then claimable after the Nth; the
  parent's row reads `state = awaiting_children` throughout the wait.
- **EMQ.3-INV5 — branded identity at every flow boundary.** Every flow job (parent and every child) is keyed
  through `Keyspace.job_key/2`, which gates `BrandedId.valid?/1` and raises before any wire (INV5, the gate);
  a flow of N children mints **N+1 distinct branded `JOB` ids** in mint order (the order theorem — distinct
  ids, no second index). *Check:* the `flow_add` scenario mints a parent + 2 children and reads three distinct
  `JOB…` ids; the **≥100-iteration determinism loop** surfaces a same-millisecond mint collision (the
  master-invariant hazard — one green run is not proof; a flow mints many ids per call, so it is exactly the
  collision-prone surface).
- **EMQ.3-INV6 — the additive-minor conformance law.** Each genuine new flow behaviour is a conformance
  scenario registered **with its probe in the same change**; the prior **43** scenarios pass **byte-unchanged**;
  the count re-pins **43 → N** in **both** pinning tests (`conformance_scenarios_test.exs` +
  `conformance_run_test.exs`). *Check:* the git-diff shows only additions to `scenarios/0`; the count assertion
  is updated in both tests.
- **EMQ.3-INV7 — slot soundness (single-queue is atomic; cross-queue is honest).** In the single-queue carve
  (emq.3.1) every flow key shares the one `{q}` slot, so every flow script is **atomic** (one slot, one
  EVAL). The **cross-queue** crossing (emq.3.3) is **NOT** claimed atomic — its completion signal is a hop
  across slots (the Fork A mechanism), stated honestly (at-least-once / eventually-consistent per the ruled
  arm), never pretended to be a single-script transaction. *Check:* emq.3.1's scripts each declare keys of
  exactly one `{q}`; emq.3.3's contract states its consistency model explicitly (no "atomic across queues"
  claim).
- **EMQ.3-INV8 — the family boundary (no pre-emption, no re-ship).** emq.3 ships the **flow** family only; it
  does **not** re-ship an emq.2 surface and does **not** pre-empt a Movement-II family rung (groups → emq.4,
  batches → emq.5, lifecycle/distributed-cancel → emq.6, the cache → emq.7, the proof/telemetry contract →
  emq.8). The flow's child fan-out is **not** the batch family (emq.5 is bulk *consumption*; a flow is a
  *dependency graph*). *Check:* the spec body names the boundary; no flow deliverable touches a Movement-II
  surface.

## The surfaced forks — Venus surfaces, the Operator rules

> **→ ALL FOUR RULED to the recommended arms (Operator, 2026-06-14; ledger [`emq-3.progress.md`](../progress/emq-3.progress.md)
> D-2):** Fork A = **single-queue first** · the @extend_locks A-1-wording = **ratify the convention** (the S-6
> slot-rooted-ARGV clarification, design canon §1 S-6) · Fork B = **counter + the idempotency guard** · Fork C =
> **`awaiting_children`**. The triad is authored to exactly these arms, so **emq.3.1 is build-ready with NO
> pre-build re-scope** — Fork A's build gate is CLEARED. The Arm-by-Arm surfacing below is kept as the decision record.

The A-1-compatible flow design has genuine open wire-shaping decisions. Each is recorded here (Arm 1 / Arm 2,
costs, a RECOMMENDATION) and flagged to the Director for the Operator's gate (the §11.12 escalation protocol +
the surface-the-fork law). **The triad is authored to the recommended arm so emq.3.1 is buildable**, with the
fork marked OPEN; a ruling the other way is a cheap pre-build re-scope.

### FORK A — the flow SHAPE: single-queue-first (atomic) vs cross-queue-from-the-start (the slot crossing)

> **The headline fork.** v1 flows **span queues** (parent in `orders`, children in
> `validation`/`inventory`/`payments`). Under the braced keyspace, a cross-queue parent and child land on
> **different slots**, so a single Lua script cannot atomically touch both. How does emq.3 sequence — and
> shape — the queue-boundary crossing?
>
> - **Arm A — single-queue flows first; cross-queue as a later sub-rung over a completion-signal hop
>   (RECOMMENDED).** emq.3.1 carves the **same-queue** flow (parent + children in one queue → one slot → every
>   flow script is fully atomic), founding and proving the declared-subkey dependency tree + the fan-in gate on
>   one slot. The **cross-queue** flow is emq.3.3, built over a **completion-signal hop**: when a cross-queue
>   child completes, its `@complete` cannot atomically reach the parent's other-slot `:dependencies` counter,
>   so the decrement is delivered by a **second mechanism** — a per-queue **promote-style sweep** that reads a
>   declared "parent-waiting" signal and decrements the parent on the parent's slot (the `EchoMQ.Pump`/promote
>   precedent — a sweep is the v2 way to move work across a boundary without a cross-slot transaction), giving
>   **eventually-consistent** fan-in across queues (stated honestly — INV7). *Steelman:* the single-queue case
>   is the **common** flow shape and is **fully atomic and A-1-trivial**; it founds the whole mechanism with
>   zero slot risk; the cross-queue hop — the genuinely hard part — is isolated to its own rung where the
>   consistency model is designed deliberately, not rushed; it matches the v2 grain (work crosses a boundary by
>   a sweep, never a cross-slot script — the promote precedent). *Cost:* a cross-queue flow is not available
>   until emq.3.3; the cross-queue fan-in is eventually-consistent, not atomic (a child completes, the parent
>   is released on the next sweep tick, not synchronously).
> - **Arm B — cross-queue flows from emq.3.1, via a host-orchestrated (non-atomic) completion.** emq.3.1
>   builds the **general** (cross-queue) flow immediately: the host (the consumer/`EchoMQ.Flows`) orchestrates
>   the fan-in — each child's completion is a normal `@complete`, and a **host-side** step (in the completing
>   worker, or a dedicated flow process) issues a **second** call to the parent's queue to decrement its
>   counter and release it. *Steelman:* full v1 feature parity (cross-queue flows) in the first sub-rung; no
>   deferral. *Cost:* the fan-in is **not** atomic even within a queue (it is two host-issued calls — the child
>   complete, then the parent decrement — with a crash window between them: a child completes, the worker dies
>   before the decrement, the parent hangs); the recovery for that window is itself new design (a
>   reconciliation sweep), so Arm B **pulls the hard part into the first rung** and still needs the sweep Arm A
>   defers — it does not avoid the complexity, it front-loads it onto the riskiest first slice; and it dilutes
>   the single-queue atomicity Arm A banks.
>
> **Recommendation: Arm A** — single-queue-first is the smaller, fully-atomic, A-1-trivial first slice that
> founds the mechanism with no slot risk; the cross-queue hop gets its own rung where its consistency model is
> designed, not improvised. This triad's carve, emq.3.1, the `@enqueue_flow` "one atomic script" claim, and
> INV7 are all authored to **Arm A**. An Arm-B ruling re-scopes emq.3.1 to the cross-queue shape (a larger,
> non-atomic first slice) before the build.

### FORK B — the dependency representation: a decrementing COUNTER vs a children-id SET

> **The fan-in mechanism.** The parent's outstanding-children count lives in `emq:{q}:job:<parent>:dependencies`.
> Is it a **counter** or a **set**?
>
> - **Arm 1 — a decrementing STRING counter (RECOMMENDED).** `:dependencies` is a string integer = the
>   outstanding child count; `@enqueue_flow` sets it to N; the fan-in hook `DECR`s it; zero ⇒ release the
>   parent. *Steelman:* O(1) per completion; minimal storage; the fan-in test is a single integer read;
>   *Cost:* the counter alone does not record *which*
>   children remain (only how many) — a "which deps are pending" read (the v1 `get_dependencies`) needs the
>   `:processed` subkey's complement, computed from the child list the parent's `add` recorded, not from
>   `:dependencies` itself.
> - **Arm 2 — a children-id SET.** `:dependencies` is a SET of the outstanding child ids; `@enqueue_flow`
>   `SADD`s every child id; the fan-in hook `SREM`s the completing child; `SCARD == 0` ⇒ release. *Steelman:*
>   the set **is** the "which children are pending" answer (the v1 `get_dependencies` reads it directly); it is
>   **idempotent** under a double-complete (re-`SREM`ing an absent member is a no-op — a redelivered child
>   completion cannot double-decrement, a real robustness win over a counter a retry could `DECR` twice). *Cost:*
>   more storage (the id set vs one integer); `SCARD` per check (still O(1)).
>
> **Recommendation: Arm 1 (the counter) for emq.3.1**, with **Arm 2's idempotency concern noted as a real
> risk** the build must address either way (a child must decrement the parent **exactly once** — a counter
> needs a guard against a redelivered child double-`DECR`ing; a set gets it free). This triad authors emq.3.1
> to the **counter** (Arm 1) and records that **the double-complete idempotency guard is a build requirement**
> (the child's completion must be idempotent w.r.t. the parent decrement — e.g. gate the `DECR` on the child's
> own state transition succeeding, the `was_active`-style guard the as-built `@complete` already uses). If the
> Operator prefers the set's free idempotency over the counter's minimality, Arm 2 is a cheap pre-build
> re-scope of the `:dependencies` representation (the §6 subkey is the same key either way — string vs set is
> not a grammar change).

### FORK C — the parent's waiting state: a new `awaiting_children` row state vs reuse `scheduled`

> **The held-parent row.** While the parent waits for its children, its row needs a state. A **new**
> `awaiting_children` state, or **reuse** the existing `scheduled` state (the parent is "scheduled" until its
> deps clear)?
>
> - **Arm 1 — a new `awaiting_children` row state (RECOMMENDED).** The parent's row reads
>   `state = awaiting_children`; introspection (`Metrics.get_job_state/3`) reports it distinctly; the
>   conformance scenario asserts it. *Steelman:* honest and legible — a flow parent is **not** a delayed job
>   (it is not on the `schedule` set, it is not released by `promote` on a timer); a distinct state keeps the
>   read plane truthful and the two release mechanisms (promote-on-time vs release-on-fan-in) un-conflated.
>   *Cost:* the read plane (`Metrics.get_job_state/3`, the conformance state scenarios) gains one state value —
>   a small additive change the rung must thread (and a `Metrics` state-set membership update).
> - **Arm 2 — reuse `scheduled`.** The parent sits in `state = scheduled` with no `schedule`-set membership.
>   *Steelman:* no new state value; the read plane is unchanged. *Cost:* **dishonest** — a `scheduled` job is
>   one the `promote` pump releases when its run-at time arrives; a flow parent is released by **fan-in**, not
>   by time, and is **not** on the `schedule` set, so a `scheduled` row with no `schedule` membership is a
>   read-plane lie (an operator querying "what is scheduled" gets a job that will never promote on time). It
>   also risks the `promote` pump or a state reconciliation treating it as a stuck scheduled job.
>
> **Recommendation: Arm 1** — a distinct `awaiting_children` state is the honest, legible representation and
> keeps the two release mechanisms un-conflated; the read-plane cost is one additive state value. The triad and
> INV4 are authored to `awaiting_children`. An Arm-2 ruling drops the new state at the cost of read-plane
> honesty (surfaced for the Operator's call).

**None of Forks A/B/C is Venus's to decide** — each is a wire-shaping / read-plane / representation call the
Director routes to the Operator. The triad ships authored to the recommended arms (A·A, B·counter+guard,
C·`awaiting_children`) so emq.3.1 is buildable; nothing in emq.3.1's build runs until Fork A is ruled (Forks B
and C are cheap pre-build re-scopes of a representation, not blockers).

## Definition of Done (the family)

- [ ] The A-1-compatible flow design recorded (this body): the deferral's exact ground (design §11.10), the
      data-value-rooting the v1 form commits, the §6 subkeys that make the redesign A-1-clean, and the carve.
- [ ] Forks A/B/C surfaced to the Director with Arm 1/Arm 2 + costs + a recommendation; **Fork A ruled by the
      Operator before the emq.3.1 build** (the gate that opens the build); the triad re-derived to the ruled
      arm at the pre-build reconcile.
- [ ] The carve into sub-rungs recorded (emq.3.1 the single-queue flow · 3.2 child-result reads · 3.3
      cross-queue · 3.4 failure-policy + bulk), dependency-ordered, each a full triad + a runbook.
- [ ] emq.3.1 specced (this design cycle): [`./emq.3.1.md`](./emq.3.rungs/emq.3.1.md) + `.stories.md` + `.llms.md` +
      `.prompt.md` — the first buildable single-queue-flow slice.
- [ ] INV1–INV8 stated as runnable checks; the family DoD traces every deliverable to a story (the `.stories.md`
      Coverage map).
- [ ] (At each sub-rung's build, NOT this design cycle) the surface built inside `echo/apps/echo_mq`; the
      shipped non-flow path byte-unchanged (INV3); the new flow scenarios additive-minor with the prior set
      byte-unchanged (INV6); the ≥100 determinism loop green for the mint-touching flow suites (INV5); Apollo
      MANDATORY for any sub-rung editing a shipped script (the `@complete` fan-in hook — HIGH-RISK).

Stories: [`./emq.3.stories.md`](emq.3.stories.md) · Agent brief: [`./emq.3.llms.md`](emq.3.llms.md) ·
First sub-rung: [`./emq.3.1.md`](./emq.3.rungs/emq.3.1.md) (+ `.stories.md` / `.llms.md` / `.prompt.md`) ·
The v1 capability reference (READ-ONLY, the form NOT to lift): `echo/apps/echomq/lib/echomq/flow_producer.ex`
(`add/2`, `add_bulk/2`, the `parent_key`/`parent_info` data-value tree) + the dependency-subkey names in
`echo/apps/echomq/priv/scripts/moveToFinished-15.lua:140-141` ·
As-built floor (the A-1 derivation precedent + the transitions the flow stands on):
`echo/apps/echo_mq/lib/echo_mq/jobs.ex` (`@enqueue`/`@claim`/`@complete`/`@extend_locks` — the
`base .. 'job:' .. id` declared-root derivation) + `keyspace.ex` (`job_key/2` the gated builder,
`queue_key/2`) + `conformance.ex` (the 43-scenario set the additive-minor law grows — re-probe the live count) ·
Design: [`../emq.design.md`](../../emq.design.md) §11.10 (the deferral + the owed design), §6 (the grammar — the
`job:<id>:{dependencies,processed,failed,unsuccessful}` subkeys), §5 (the closed wire-class registry — no new
class), §11.12 (the escalation protocol), S-6 (the declared-keys A-1 law), S-1/§6 (the braced keyspace — the
slot constraint that forces Fork A) · Roadmap: [`../emq.roadmap.md`](../../emq.roadmap.md) Movement I (the parity
thesis — emq.3 closes it) · The feature catalog + the parity proof:
[`../emq.features.md`](../../emq.features.md) (the emq.3 row, lines 172-180; the B.1 `flow_producer → emq.3` row) ·
The carve precedent: [`./emq.2.design.md`](../emq.2/emq.2.design.md) (ADR-1 the dependency-ordered carve) · Approach:
[`../../elixir/specs/specs.approach.md`](../../../elixir/specs/specs.approach.md)
