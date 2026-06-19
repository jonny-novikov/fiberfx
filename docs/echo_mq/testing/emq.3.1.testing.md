# emq.3.1 — testing tasks

> Living test ledger for the **single-queue flow** rung (the FIRST sub-rung of the emq.3 parent/flow family —
> `EchoMQ.Flows.add/3` + `@enqueue_flow` + the `@complete` fan-in hook + `awaiting_children`; the `emq-3-1`
> lead-team 2026-06-15, conformance 43 → **45**). Strategy: [`../emq.testing.md`](../emq.testing.md). Spec
> family + carve: [`../specs/emq.3.md`](../specs/emq1/emq.3/emq.3.md) · Rung triad:
> [`../specs/emq.3.1.md`](../specs/emq1/emq.3/emq.3.rungs/emq.3.1.md) · [`.stories.md`](../specs/emq1/emq.3/emq.3.rungs/emq.3.1.stories.md). **HIGH-risk rung** — it edited the shipped `@complete` Lua (the fan-in
> hook), so Apollo was mandatory (BUILD-GRADE, mutation kill 3/3); the durable harness is
> `echo/rungs/bus/emq_3_1_check.sh` (PASS 9/9 + the ≥100 loop
> 100/100). Re-probe the tree before trusting a `file:line` here (the lag-1 law).

## Proof state (as-built)

- **The single-queue flow founded under the v2 A-1 declared-keys law.** A parent + same-queue children land in
  **one atomic `@enqueue_flow` script** (one `{q}` slot); the parent is held out of `pending`
  (`state = awaiting_children`, `:dependencies = N`) until the `@complete` fan-in hook decrements the count to
  zero and releases it. The dependency graph rides **declared §6 subkeys of the parent**
  (`emq:{q}:job:<parent>:dependencies` the STRING counter, `…:processed` the HASH) — **not** the v1 data-value
  `parent_key` (the form NOT lifted, design §11.10).
- **Test files** (both `@moduletag :valkey`, `async: false`):
  - `flow_add_test.exs` — **9 tests** (the atomic add + the refusals).
  - `flow_fanin_test.exs` — **6 tests** (the fan-in release + the idempotent decrement + the dead-child bound).
- **Conformance**: +2 scenarios — `flow_add`, `flow_fanin` → `{:ok, 45}` (the prior **43** byte-unchanged); the
  mint/process-touching flow suites run under the **≥100 determinism loop** owning the machine (a flow mints
  N+1 ids per call — the same-millisecond mint-collision surface).

### Surface map (PIN — the real `EchoMQ.Flows` + the `EchoMQ.Jobs` seams the fan-in edits)

| Symbol | Where | Role |
|---|---|---|
| `EchoMQ.Flows.add/3` | `flows.ex` | `add(conn, queue, %{parent: %{id, payload}, children: [spec]})` → `{:ok, {parent_id, [child_id]}}`; one atomic `@enqueue_flow` for same-queue children |
| `@enqueue_flow` | `flows.ex` | the atomic flow script: child rows → `pending` (claimable); parent row → `awaiting_children`; `SET KEYS[2] n` (the `:dependencies` STRING counter); the parent NOT added to `pending` (the fan-in gate) |
| the `@complete` fan-in branch | `jobs.ex` | **the one shipped-script edit (HIGH-risk)** — when a child with a parent completes: `DECR` the parent's `:dependencies` (`KEYS[3]`), `HSET` the parent's `:processed` (`KEYS[4]`), and at zero `ZADD` the parent to `pending` + flip its row to `pending`; gated on `was_active == 1` (idempotent — INV5) |
| `EchoMQ.Jobs.complete/4` | `jobs.ex` | the host wrapper; passes `[parent_id, job_id]` as `ARGV[4..5]` — `ARGV[5] = job_id` is the **presence marker** (the honest bound O1, closed at emq.3.2) |
| `reject_cross_queue/2` | `flows.ex` | the host-side refusal — a child in a different queue is rejected before any write (the single-queue carve, Fork A·A) |

## Proof table

| US | Given → When → Then (essence) | Proven by | Lane | Conf. |
|---|---|---|---|---|
| US1 atomic add | a parent + N same-queue children → `add/3` → N+1 distinct `JOB` ids on one slot; children claimable; parent withheld (`awaiting_children`, `:dependencies = N`) | `flow_add_test.exs` (mint/slot · claimable+withheld · awaiting_children) | wire | `flow_add` |
| US2 fan-in release | the parent claims `:empty` until the last child completes, then claimable | `flow_fanin_test.exs` (held-until-last · three-child release) | wire+proc | `flow_fanin` |
| US3 idempotent decrement | a double-complete of a child decrements the parent **exactly once** (the `was_active == 1` gate) | `flow_fanin_test.exs` (double-complete · the was_active gate) | wire+proc | `flow_fanin` |
| US4 the refusals | a cross-queue child → rejected host-side, nothing written; a non-`JOB` parent/child → `EMQKIND` before any write (atomic rollback); an ill-formed id → raises at `Keyspace.job_key/2` | `flow_add_test.exs` (the refusals describe — 4 tests) | wire+pure | `flow_add` |
| US5 the claim gate | `@claim` byte-unchanged — the gate is the parent's **absence from `pending`**, not a check inside `@claim` | `flow_fanin_test.exs` (claim returns `:empty` while withheld) + the empty `@claim` diff | wire | (via `flow_fanin`) |
| US6 design gate / the dead-child bound (INV9) | the A-1 flow ADR before any artifact; a child that dies to `dead` does **NOT** decrement — the parent stays `awaiting_children` (the honest bound, the dead-child handling routed to emq.3.4) | `emq.3.1.md` D1 + `flow_fanin_test.exs` (the INV9 dead-child describe) | ledger+wire | — |
| US· GATE | prior **43** byte-unchanged + 2 new → `{:ok, 45}`; the flow suites under the **≥100 loop** | `conformance_run_test.exs` · `conformance_scenarios_test.exs` | wire+pure | all 45 |

## Hot places (this rung)

- **The fan-in hook is a SHIPPED-SCRIPT edit.** The `@complete` Lua gained the fan-in branch — the highest-risk
  surface in the family. The proof that the **non-flow** path is byte-unchanged is the branch's `KEYS[3]`-nil
  guard (a non-flow job never reaches the fan-in code); the emq.1 + emq.2.{1–4} suites passing unchanged is the
  regression proof (INV3). Any future `@complete` touch must re-prove this.
- **The idempotent decrement is the correctness keystone.** A redelivered child completion must `DECR` the
  parent **exactly once** — the `was_active == 1` gate is what makes the double-complete a no-op. A regression
  here double-releases (or hangs) a parent and would flake only under redelivery, not a single happy run.
- **The mint-collision surface.** A flow mints N+1 branded ids in **one** `add/3` call — the densest
  same-millisecond mint in the program. One green run is NOT proof (the master-invariant hazard); the ≥100 loop
  owning the machine is the gate (the harness's loop).
- **The dead-child honest bound (INV9 — a NAMED carry, not a defect).** A child that exhausts its retries to
  `dead` does **not** decrement the parent (the parent stays `awaiting_children` indefinitely). This is
  **correct for emq.3.1's scope** (the failure-policy options — `fail_parent_on_failure` /
  `ignore_dependency_on_failure` over `:failed`/`:unsuccessful` — are **emq.3.4**); the bound is **tested**
  (the parent provably stays held), not papered over. The dead-child release is the emq.3.4 design.
- **The O1 presence-marker carry (closed at emq.3.2).** emq.3.1's `:processed` value is the child id, not a
  real result (`complete/4` carries no result arg) — the honest bound **O1**, **closed by emq.3.2** (the
  real-result-carrying completion through the existing `ARGV[5]` seam). See
  [`emq.3.2.testing.md`](./emq.3.2.testing.md).
- **The flow-subkey lifecycle (the L-5/N1 carry).** `:dependencies`/`:processed` **outlive** the parent row
  (`@complete` `DEL`s only the row) AND `obliterate`/`@drain` (their `del_job`/`wipe()` enumerate a FIXED
  subkey list that excludes the flow subkeys). A NAMED carry to the emq.3.x lifecycle rung — see the strategy
  §5 hot-place and [`emq.3.2.testing.md`](./emq.3.2.testing.md) (where the read rung re-affirmed it).

## Near-term tasks

### Harden (close the thin proofs)
- [ ] Keep `flow_add` + `flow_fanin` under the **≥100 loop owning the machine**; the harness
      `emq_3_1_check.sh` is the durable artifact (re-run it, do not
      hand-run) — the mint-collision flake surface.
- [ ] **Property/generative proof of the order theorem at flow width** — a flow mints N+1 ids; a property over
      many flows in a tight same-millisecond loop is the un-built generative proof (strategy §5.7; proven by
      example today, two/three occurrences).

### Gaps (missing tests — routed forward)
- [ ] **The dead-child release (INV9 → emq.3.4).** Today the parent stays `awaiting_children` when a child
      dies; the `fail_parent_on_failure` / `ignore_dependency_on_failure` policies (the `:failed`/`:unsuccessful`
      subkeys) are emq.3.4 — when they land, the bound flips from "stays held" to "the policy fires," and this
      test re-derives.
- [ ] **The flow-subkey lifecycle (L-5/N1 → the emq.3.x lifecycle rung).** A test that asserts
      `:dependencies`/`:processed` are **retired** (by the `obliterate`-sweep + per-flow cleanup) does not exist —
      because the cleanup is **not built** (the NAMED carry). emq.3.2 added the honest-bound test that they
      **survive** today; the lifecycle rung flips it.

### Maintenance (keep green)
- [ ] Keep the **surface map PIN** current — `EchoMQ.Flows` is new at emq.3.1 and the `@complete` fan-in seam
      drifts as later rungs edit `jobs.ex` (emq.3.2's `complete/5` already moved the surrounding lines).
- [ ] Re-pin conformance (`{:ok, 45}` → new) on any flow change; the prior 43 byte-unchanged.

## Done-when

`redis-cli -p 6390 ping` → `TMPDIR=/tmp mix test --include valkey` green in `echo/apps/echo_mq` →
`Conformance.run/2 → {:ok, 45}` → `flow_add` + `flow_fanin` green across `seq 1 100` owning the machine (the
HIGH-risk shipped-script-edit posture — Apollo's re-run discipline) → the `@complete` regression proof (the
emq.1 + emq.2.{1–4} non-flow suites unchanged).
