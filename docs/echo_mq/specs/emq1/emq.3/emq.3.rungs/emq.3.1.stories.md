# EMQ.3.1 · user stories — the single-queue flow (the first buildable slice)

> Who wants the single-queue flow, what they need, and how we will know it works. Each story is Connextra with
> Given/When/Then acceptance, an INVEST line naming the invariant(s) it encodes, and a Priority/Size/Implements
> line; the file ends with a Coverage line mapping every Deliverable to ≥1 story. The standing
> **`EMQ.3.1-US-GATE`** carries the Valkey gate (design §7) — a structural gate. emq.3.1 founds the flow
> family: a parent + same-queue children, the parent held until the children complete, the whole mechanism
> proven atomically on one slot.

## EMQ.3.1-US1 — the flow shape is settled before the build

As a **program Operator**, I want Fork A (single-queue-first vs cross-queue-from-the-start) settled before
emq.3.1 builds, so that the rung does not silently commit a consistency model — whether the first slice is the
fully-atomic single-queue flow (Arm A) or the non-atomic cross-queue flow (Arm B) is **my** call, recorded, and
the triad re-derives to the ruled arm.

Acceptance criteria
- Given the family body surfaces Fork A with both arms steelmanned and the recommendation (Arm A), when emq.3.1
  opens, then **no build artifact exists** until the Operator records the Fork A ruling.
- Given the Operator rules Arm A, when emq.3.1 builds, then the slice is the **single-queue** flow (one slot →
  every flow script atomic), and a cross-queue child spec is rejected (the cross-queue flow is emq.3.3).
- Given Forks B (counter vs set) and C (`awaiting_children` vs `scheduled`) are recorded with recommendations
  (counter+guard; `awaiting_children`), when emq.3.1 opens, then each is a cheap pre-build re-scope of a
  representation, surfaced for the Operator's optional ruling, not a blocker.

INVEST — independent (the gate that precedes every build story); testable by the ledger record + the build's
touch-set (Arm A → single-queue atomic scripts); encodes EMQ.3.1-INV8. Priority: must · Size: 1 · Implements:
EMQ.3.1-D1.

## EMQ.3.1-US2 — a flow is added atomically; the children run, the parent waits

As a **bus consumer running a same-queue fan-out/fan-in job**, I want to enqueue a parent + its children in one
atomic call, so that either the whole flow lands or none of it does, the children become claimable immediately,
and the parent waits — without my polling or coordinating.

Acceptance criteria
- Given a flow of a parent + N same-queue children, when `EchoMQ.Flows.add/3` is called, then **N+1 distinct**
  branded `JOB` ids are minted (the parent + each child), every id gated at `Keyspace.job_key/2`, and the whole
  flow lands in **one atomic `@enqueue_flow`** (one slot) — all children in `pending`, the parent NOT in
  `pending`.
- Given the flow landed, when the children's queue is claimed (`Jobs.claim/3`), then the **children** are
  returned (claimable), and the **parent** answers `:empty` (it is not a `pending` member) with its
  `emq:{q}:job:<parent>:dependencies` count = N.
- Given a child spec names a **different** queue than the parent, when `add/3` is called, then it is **rejected**
  (a typed/host-side error — the cross-queue flow is emq.3.3), never silently mis-keyed across slots.

INVEST — independent (the family's enqueue capability); testable by the `flow_add` `:valkey` scenario (3
distinct ids; 2 children claimable; the parent `:empty` with `:dependencies` = 2; a cross-queue child rejected);
encodes EMQ.3.1-INV2, EMQ.3.1-INV6, EMQ.3.1-INV8. Priority: must · Size: 3 · Implements: EMQ.3.1-D2.

## EMQ.3.1-US3 — the parent runs exactly once all its children complete (fan-in)

As a **bus consumer**, I want the parent to become claimable the instant the last child completes — and not
before — so that "do the parts, then the whole" is enforced by the bus, the parent never runs early, and it
runs exactly once.

Acceptance criteria
- Given a parent with N children waiting, when the children complete one by one, then the parent stays `:empty`
  while `:dependencies` > 0 (after the (N−1)th: count = 1, still `:empty`), and becomes **claimable** after the
  Nth (count = 0, the fan-in hook added it to `pending`).
- Given a child completes, when it carried a parent reference, then the parent's `:dependencies` is decremented
  and the child's result is recorded in the parent's `emq:{q}:job:<parent>:processed` subkey; when it carried
  **no** parent, then `@complete` is the **byte-unchanged** shipped completion.
- Given a child is completed **twice** (a redelivered or stale-token retry), when the second completion is
  processed, then the parent's count drops by **exactly 1** (the idempotent decrement — gated on the child's own
  `active`→done transition succeeding), never twice.

INVEST — independent (the family's headline fan-in); testable by the `flow_fanin` `:valkey` scenario (claim →
`:empty` until the Nth child, claimable after) + a double-complete scenario (count drops by exactly 1); encodes
EMQ.3.1-INV4, EMQ.3.1-INV5, EMQ.3.1-INV3. Priority: must · Size: 3 · Implements: EMQ.3.1-D3.

## EMQ.3.1-US4 — a waiting parent reads honestly (the `awaiting_children` state)

As a **bus operator introspecting a flow**, I want a waiting parent to report a distinct `awaiting_children`
state, so that I can tell a flow parent (released by fan-in) from a delayed job (released by time) and never
mistake a waiting parent for a stuck scheduled job.

Acceptance criteria
- Given a parent waiting on its children, when `Metrics.get_job_state/3` reads its state, then it reports
  `awaiting_children` (the distinct state — Fork C Arm A, the `@state_lookup` row-field branch), NOT `scheduled`
  and NOT `pending`.
- Given the parent is `awaiting_children`, when the `schedule` set is inspected, then the parent is **not** a
  member (it is not released by the `promote` pump on a timer — it is released by fan-in).
- Given the last child completes, when the parent is released to `pending`, then its state transitions to
  `pending` (claimable) and a subsequent claim returns it.
- Given the shipped `unknown_state` scenario (a row that exists in no set, its `state` field NOT
  `"awaiting_children"`), when `get_job_state/3` reads it after the new state is threaded, then it still answers
  `:unknown` **byte-unchanged** (the row-field branch returns `awaiting_children` only for the exact value — D4;
  the regression the threading must not cause).

INVEST — independent (the read-plane honesty); testable by `get_job_state/3` reading `awaiting_children` while
waiting + `pending` after release + the parent absent from `schedule`; encodes EMQ.3.1-INV4. Priority: should ·
Size: 2 · Implements: EMQ.3.1-D4.

## EMQ.3.1-US5 — the new behaviors are conformance scenarios; the prior set is untouched

As a **protocol maintainer**, I want each genuine new flow behavior registered as a conformance scenario with
its probe in the same change and the prior set byte-unchanged, so that the protocol grows by additive minor and
the wire contract stays provable.

Acceptance criteria
- Given `flow_add` + `flow_fanin`, when they are added to `scenarios/0`, then each is registered **with its
  probe in the same change**, and the prior scenarios pass **byte-unchanged** (name + contract + verdict body
  identical, git-verified).
- Given the additions, when the count is re-pinned, then **both** pinning tests
  (`conformance_scenarios_test.exs` + `conformance_run_test.exs`) assert the new total **45** (Stage-0 confirmed
  the prior count = 43; 43 + 2 = 45), and `EchoMQ.Conformance.run/2` over a live connection prints `{:ok, 45}`.
- Given the wire, when a flow key is parsed, then emq.3.1 adds **no §6 key type** (the flow subkeys are
  already-registered `job:<id>:<sub>` members) and **no new wire class** (the kind law reuses `EMQKIND`); the
  five-code fence union stands unextended.

INVEST — independent (the additive-minor contract); testable by the git-verified byte-unchanged prior set + the
re-pinned count in both tests + the §6 grammar unedited; encodes EMQ.3.1-INV1, EMQ.3.1-INV7. Priority: must ·
Size: 2 · Implements: EMQ.3.1-D5.

## EMQ.3.1-US6 — the flow is proven, the bound is honest, no regression

As a **program Director**, I want the flow suites proven under the determinism loop, the shipped surface
unregressed, and the dead-child limit documented, so that emq.3.1 closes on a proven core and an honest bound —
not a false-green and not a hidden gap.

Acceptance criteria
- Given the mint/process-touching flow suite (a flow mints many ids per call + fans in across completions), when
  it is gated, then it runs under the **≥100-iteration determinism loop** owning the machine (one green run is
  NOT proof — the master-invariant hazard), and a same-millisecond mint collision is caught there.
- Given the shipped surface, when emq.3.1 lands, then the emq.1 + emq.2.{1,2,3,4} suites + `Conformance.run/2`
  pass **unchanged** (no regression — INV3), and `git diff` of `@enqueue`/`@claim` is empty.
- Given a flow child that **fails** to `dead` (exhausts retries), when its parent is read, then the parent stays
  `awaiting_children` (a dead child does **not** decrement — the **honest bound**, documented; the failure
  policy is emq.3.4), asserted, NOT papered over.
- Given the write-side scope, when emq.3.1 closes, then its **other three honest bounds** are documented in the
  body, never papered over: **O1** — the `:processed` value is a presence marker (`child_id → child_id`), not a
  result payload (the real write + read are emq.3.2); **O2** — the `parent_of` `HGET` runs on every completion (a
  correctness-neutral perf follow-up emq.3.2 folds into the claim result); **L-5** — the flow subkeys outlive the
  parent row (correct — `:processed` must survive for emq.3.2's read; the cleanup is an emq.3.x concern).
- Given the rung is HIGH-RISK (the `@complete` edit + the multi-id mint), when it closes, then **Apollo** has
  re-run the whole ladder + the ≥100 loop independently and re-verified the byte-unchanged conformance + the
  byte-unchanged shipped scripts (MANDATORY).

INVEST — independent (the proof + the honest bound); testable by the ≥100 loop green + the prior suites green +
the documented dead-child limit + Apollo's independent re-run; encodes EMQ.3.1-INV3, EMQ.3.1-INV6, EMQ.3.1-INV9.
Priority: must · Size: 2 · Implements: EMQ.3.1-D6.

## EMQ.3.1-US-GATE — the Valkey gate (specification by example)

As a **release gate**, I want the single-queue flow proven on the certified wire under honest-row reporting, so
that the v2 laws bind at the wire (design §7, S-4).

Acceptance criteria
- Given the engine-hygiene allowlist {Valkey, Redis-as-the-historical-row}, when the flow suites run, then they
  run against **Valkey on port 6390** (the truth row; `redis-cli -p 6390 ping` → `PONG`); a host without Valkey
  reports its row honestly, never the truth row.
- Given `GET {emq}:version`, when read after the bus connects, then it returns `echomq:2.0.0` (the connect-scoped
  fence — emq.3.1 changes nothing about the fence; the five-code union stands unextended).
- Given grammar totality, when a flow key (`emq:{q}:job:<parent>:dependencies` / `:processed`) is parsed, then it
  classifies under the §6 grammar (the `job:<id>:<sub>` subkeys), the queue name extracts as the `{q}` hashtag,
  and `q ≠ "emq"` keeps the slot families disjoint — emq.3.1 edits the grammar's shape not at all.
- Given the conformance run, when `Conformance.run/2` executes, then it prints one line per scenario, the prior
  set is byte-unchanged, and `flow_add` + `flow_fanin` are present (the count re-pinned in both pinning tests).

INVEST — independent (the standing structural gate); testable by the honest-row run + `{emq}:version` + grammar
totality + the additive-minor conformance; encodes EMQ.3.1-INV1, EMQ.3.1-INV7. Priority: must · Size: 1 ·
Implements: design §7, S-4 (the structural gate).

## Coverage

| Deliverable | Story |
|---|---|
| EMQ.3.1-D1 — the fork gate (Fork A ruled; B/C recorded) | US1 |
| EMQ.3.1-D2 — `EchoMQ.Flows.add/3` + `@enqueue_flow` (atomic enqueue; children run; parent waits) | US2 |
| EMQ.3.1-D3 — the fan-in hook on `@complete` (idempotent decrement; at-zero release; `:processed`) | US3 |
| EMQ.3.1-D4 — the `awaiting_children` row state (the read-plane honesty) | US4 |
| EMQ.3.1-D5 — `flow_add` + `flow_fanin` conformance (additive minor; prior set byte-unchanged) | US5 |
| EMQ.3.1-D6 — the proof (the ≥100 loop; no regression; the documented dead-child bound; Apollo) | US6 |
| The Valkey structural gate (honest-row; `{emq}:version`; grammar totality; additive-minor conformance) | US-GATE |

Spec body: [`./emq.3.1.md`](emq.3.1.md) (authoritative)
· Family: [`./emq.3.md`](../emq.3.md) (the contract + the carve + the forks).
