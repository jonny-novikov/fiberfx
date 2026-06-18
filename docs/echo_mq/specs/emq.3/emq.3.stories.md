# EMQ.3 · user stories — the parent/flow family (the A-1-compatible flow design)

> Who wants the flow family, what they need, and how we will know it works. Each story is Connextra with
> Given/When/Then acceptance, an INVEST line naming the invariant(s) it encodes, and a Priority/Size/Implements
> line; the file ends with a Coverage line mapping every family Deliverable/Fork to ≥1 story. The standing
> **`EMQ.3-US-GATE`** carries the Valkey gate (design §7) — a structural gate. emq.3 is the rung that **closes
> Movement I**; this is the **family** stories file (the family contract + the carve + the forks); the
> per-sub-rung acceptance lives in each sub-rung's `.stories.md` (emq.3.1 first — [`./emq.3.1.stories.md`](./emq.3.rungs/emq.3.1.stories.md)).

## EMQ.3-US1 — the flow shape is settled before the first build

As a **program Operator**, I want the flow-shape fork (Fork A — single-queue-first vs cross-queue-from-the-start)
settled before emq.3.1 builds, so that the rung does not silently commit a consistency model — whether the first
slice is the fully-atomic single-queue flow (Arm A) or the non-atomic cross-queue flow (Arm B) is **my** call,
recorded, and the triad re-derives to the ruled arm.

Acceptance criteria
- Given the design body surfaces Fork A with both arms steelmanned (Arm A single-queue-first over a later
  completion-signal hop; Arm B cross-queue-from-emq.3.1 via a host-orchestrated non-atomic completion) and the
  recommendation (Arm A), when emq.3 opens, then **no emq.3.1 build artifact exists** until the Operator records
  the Fork A ruling.
- Given the Operator rules Arm A, when emq.3.1 builds, then the first slice is the **single-queue** flow (one
  slot, every flow script atomic), and the cross-queue crossing is emq.3.3.
- Given the Operator rules Arm B, when emq.3.1 builds, then emq.3.1 is re-scoped to the cross-queue shape (the
  non-atomic host-orchestrated fan-in + its recovery sweep) before the build — a cheap pre-build re-scope.
- Given Forks B (counter vs set) and C (`awaiting_children` vs reuse `scheduled`) are recorded with
  recommendations (counter+guard; `awaiting_children`), when emq.3.1 opens, then each is a cheap pre-build
  re-scope of a representation (not a build blocker), surfaced for the Operator's optional ruling.

INVEST — independent (the gate that precedes every build story); testable by the ledger record + emq.3.1's
touch-set (Arm A → single-queue atomic scripts; Arm B → the cross-queue host-orchestrated shape); encodes
EMQ.3-INV7. Priority: must · Size: 1 · Implements: Fork A/B/C, the family DoD gate.

## EMQ.3-US2 — a parent waits for its children (the fan-in gate)

As a **bus consumer running a fan-out/fan-in pipeline**, I want a parent job that becomes claimable **only** once
all its children complete, so that I can model "do the parts, then the whole" without polling — the parent never
runs early and runs exactly once the last child finishes.

Acceptance criteria
- Given a flow of a parent + N same-queue children enqueued by `EchoMQ.Flows.add/3`, when `Jobs.claim/3` is
  called for the parent's queue, then the **children** are claimable immediately (they are in `pending`) and the
  **parent** answers `:empty` (it is NOT in `pending`) while its `emq:{q}:job:<parent>:dependencies` count > 0.
- Given the children complete one by one, when the (N−1)th child completes, then the parent is **still**
  `:empty` (count = 1); when the Nth child completes, then the parent is **claimable** (the fan-in hook added it
  to `pending` at count = 0).
- Given the parent is waiting, when its state is read (`Metrics.get_job_state/3`), then it reads
  `awaiting_children` (Fork C Arm A — the honest distinct state), NOT `scheduled` and NOT a `pending` member.

INVEST — independent (the family's headline capability); testable by the `flow_fanin` `:valkey` scenario
(claim → `:empty` until the Nth child completes); encodes EMQ.3-INV4, EMQ.3-INV3 (the gate is the parent's
absence from `pending`, `@claim` byte-unchanged). Priority: must · Size: 3 · Implements: emq.3.1 (the fan-in
gate); the family Goal.

## EMQ.3-US3 — the dependency graph is keyed without data-value rooting (the A-1 law)

As a **protocol maintainer**, I want every flow key declared in `KEYS[]` or grammar-rooted at the parent — never
read out of a data value — so that the flow family obeys the A-1 declared-keys law the v1 form violated, and a
polyglot reader receives the same auditable key contract.

Acceptance criteria
- Given the flow scripts, when the A-1 lint scans them, then **every** key the scripts touch is `emq:{q}:job:<id>`
  / `…:<sub>` / `emq:{q}:pending` — each in `KEYS[]` or derived from a declared `KEYS[n]` queue base root by the
  §6 grammar (the `@extend_locks` `base .. 'job:' .. id` pattern) — and **no** key is derived from a hash field
  (no `parent_key` read out of a child's data, the v1 form).
- Given the parent→child link, when a child's completion follows it, then the parent's `:dependencies` subkey is
  a **declared `KEYS[n]`** passed into the completion script, NOT a value the script reads out of the child's
  row — the link is the parent's declared subkey, not the child's data.
- Given the flow keyspace, when it is enumerated, then it adds **no §6 key type** (the `dependencies`/`processed`/
  `failed`/`unsuccessful` subkeys are already-registered §6 `job:<id>:<sub>` members) and **no new wire class**
  (the kind law reuses `EMQKIND`).

INVEST — independent (the law the family is judged by); testable by the A-1 lint + a grep for hash-field-to-key
derivation (empty) + the §6 grammar unedited; encodes EMQ.3-INV1, EMQ.3-INV2. Priority: must · Size: 2 ·
Implements: the A-1-compatible flow design; the family Goal.

## EMQ.3-US4 — the non-flow surface is byte-unchanged (no regression)

As a **bus operator on the shipped surface**, I want a job with no parent to flow through enqueue/claim/complete
exactly as before emq.3, so that adding flows costs the existing surface nothing — every shipped scenario passes
byte-unchanged.

Acceptance criteria
- Given a job with **no parent**, when it is enqueued/claimed/completed, then it traverses `@enqueue`/`@claim`/
  `@complete` exactly as the emq.2 cluster shipped — the fan-in hook on `@complete` is reached **only** when the
  completing child carries a parent reference; the shipped `@claim` is **byte-unchanged**.
- Given the prior conformance set, when emq.3's scenarios are added, then the **43** prior scenarios pass
  **byte-unchanged** (name + contract + verdict body identical, git-verified) and the count re-pins **43 → N**
  in **both** pinning tests (the additive-minor law).
- Given the prior suites, when emq.3 lands, then the emq.1 + emq.2.{1,2,3,4} suites + `Conformance.run/2` pass
  unchanged; a flow scenario that fails reveals a real defect (a finding, escalated — design §11.12), never a
  spec defect papered over.

INVEST — independent (the regression contract); testable by the git-verified byte-unchanged 43 + the prior
suites green; encodes EMQ.3-INV3, EMQ.3-INV6. Priority: must · Size: 2 · Implements: the family DoD (no
regression).

## EMQ.3-US5 — every flow job is a distinct branded JOB id (identity + determinism)

As a **protocol maintainer**, I want every job in a flow (parent and every child) keyed through the gated branded
builder and minted as a distinct id, so that the order theorem holds across a flow and a same-millisecond mint
collision is surfaced by the determinism loop, not shipped.

Acceptance criteria
- Given a flow of a parent + N children, when it is added, then **N+1 distinct** branded `JOB` ids are minted in
  mint order (the order theorem — distinct ids, no second index), and **every** id is keyed through
  `Keyspace.job_key/2` (which gates `BrandedId.valid?/1` and raises before any wire).
- Given the flow mint surface (a flow mints many ids per call — the collision-prone surface), when the
  mint-touching flow suites run, then they run under the **≥100-iteration determinism loop** owning the machine
  (one green run is NOT proof — the master-invariant hazard), and a same-millisecond collision is caught there.
- Given an ill-formed id at any flow boundary, when the key is built, then `Keyspace.job_key/2` raises
  (INV5 — wellformedness at the key), before any wire.

INVEST — independent (the identity + determinism contract); testable by the three-distinct-ids `flow_add`
scenario + the ≥100 loop on the flow suites; encodes EMQ.3-INV5. Priority: must · Size: 2 · Implements: the
family DoD (identity + the loop).

## EMQ.3-US6 — the family boundary holds (no pre-emption, no re-ship)

As a **program Director**, I want emq.3 to ship the flow family and nothing else, so that no later Movement-II
rung is pre-empted and no emq.2 surface is re-shipped — the carve is auditable and the ladder stays clean.

Acceptance criteria
- Given emq.3's deliverables, when they are read, then they touch the **flow** surface only — no groups-deepened
  (emq.4), no batch-consume (emq.5), no distributed-cancel/lifecycle (emq.6), no cache (emq.7), no
  telemetry-contract/proof (emq.8) surface; the flow's child fan-out is a **dependency graph**, NOT the batch
  family (emq.5 is bulk *consumption*).
- Given the carve, when the sub-rungs are listed, then they are dependency-ordered (emq.3.1 single-queue · 3.2
  child-result reads · 3.3 cross-queue · 3.4 failure-policy + bulk), each a full triad + a runbook, one
  increment per run.
- Given a shipped emq.2 surface, when emq.3 lands, then emq.3 **re-ships none of it** (it stands ON
  `EchoMQ.Jobs`, it does not rebuild the state machine).

INVEST — independent (the boundary contract); testable by the deliverable touch-set (flow-only) + the carve
order; encodes EMQ.3-INV8. Priority: must · Size: 1 · Implements: the carve; the family boundary.

## EMQ.3-US-GATE — the Valkey gate (specification by example)

As a **release gate**, I want the flow family proven on the certified wire under honest-row reporting, so that the
v2 laws bind at the wire and a host without Valkey reports its row honestly (design §7, S-4).

Acceptance criteria
- Given the engine-hygiene allowlist {Valkey, Redis-as-the-historical-row}, when the flow suites run, then they
  run against **Valkey on port 6390** (the truth row; `redis-cli -p 6390 ping` → `PONG`); a host without Valkey
  runs the probes elsewhere and reports them as that row, never the truth row.
- Given `GET {emq}:version`, when read after the bus connects, then it returns `echomq:2.0.0` (the connect-scoped
  fence — emq.3 changes nothing about the fence; the five-code union stands unextended, INV1).
- Given grammar totality, when a flow key is parsed, then it classifies under the §6 grammar (the
  `job:<id>:<sub>` subkeys), the queue name extracts as the `{q}` hashtag, and `q ≠ "emq"` keeps the slot
  families disjoint — emq.3 edits the grammar's shape **not at all** (INV1).
- Given the conformance run, when `EchoMQ.Conformance.run/2` executes over a live connection, then it prints one
  line per scenario, the prior **43** are byte-unchanged, and the new flow scenarios are present (the count
  re-pinned in both pinning tests — the additive-minor law).

INVEST — independent (the standing structural gate); testable by the honest-row run + `{emq}:version` +
grammar totality + the additive-minor conformance; encodes EMQ.3-INV1, EMQ.3-INV6. Priority: must · Size: 1 ·
Implements: design §7, S-4 (the structural gate).

## Coverage

| Family Deliverable / Fork | Story |
|---|---|
| The A-1-compatible flow design (the declared-subkey dependency tree; no data-value rooting) | US3 |
| The fan-in gate (a parent claimable IFF all children complete; the `awaiting_children` state) | US2 |
| Fork A (single-queue-first vs cross-queue-from-the-start) — Operator-ruled before emq.3.1 | US1 |
| Forks B (counter vs set) + C (`awaiting_children` vs `scheduled`) — pre-build re-scopes | US1 |
| No regression (the non-flow path byte-unchanged; the 43 byte-unchanged; the additive-minor count) | US4 |
| Branded identity + the determinism loop (N+1 distinct ids; the gated builder; the ≥100 loop) | US5 |
| The carve into sub-rungs (emq.3.1 · 3.2 · 3.3 · 3.4, dependency-ordered) + the family boundary | US6 |
| The Valkey structural gate (honest-row; `{emq}:version`; grammar totality; additive-minor conformance) | US-GATE |

The per-sub-rung Deliverables (emq.3.1's D1–Dn) trace in [`./emq.3.1.stories.md`](./emq.3.rungs/emq.3.1.stories.md); this
file covers the **family** contract, the carve, and the forks. Spec body: [`./emq.3.md`](emq.3.md) (authoritative)
· Agent brief: [`./emq.3.llms.md`](emq.3.llms.md).
