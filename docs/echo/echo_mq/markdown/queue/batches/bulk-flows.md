# Bulk flows — many flows, fail-closed per flow

**Route:** `/echomq/queue/batches/bulk-flows` · **section:** queue · **pillar:** The Queue · **surface:** dive

> Source-of-record. All grounding is real code in `echo/apps/echo_mq/lib/echo_mq/flows.ex` — no `[RECONCILE]` markers.

## The fact

A flow is a parent job and a list of children (the flows module is the orchestration surface). `EchoMQ.Flows.add_bulk/3`
admits **many flows in one call** — and its honesty is **per flow, not per batch**.

Each flow lands by the existing single `add/3` mechanism, issued one flow at a time. The bulk verb's contract is the
single add's contract, repeated:

- **Fail-closed per flow.** A flow that fails to land leaves **its own parent held** — never claimable, never spuriously
  executed — exactly as a single `add/3` does. A poison flow does not abort the others; the batch continues with the
  next flow.
- **Input order, landed only.** The result is `{:ok, [{parent_id, [child_id]}]}` — one `{parent_id, [child_id]}` per
  flow that landed, in input order. A flow that failed to land is **omitted** from the list (its parent is left held,
  host-retryable by id).
- **Every id gated first.** Before any wire, every id across every flow — each parent and each child — is gated at
  `Keyspace.job_key/2`, which raises on an ill-formed id. An ill-formed id in any flow raises before the first wire, so
  no flow lands.

The shape mirrors the per-flow honesty the single add already carries: a flow lands as a whole or its parent stays
held. The batch carries that same all-or-held guarantee **independently per flow** — one bad flow's parent stays held
while the good flows beside it land and their parents await their children.

## The worked example — add_bulk/3 on the real grounding

```elixir
# echo_mq — EchoMQ.Flows
# add_bulk/3 lands many flows, each through the single add/3, FAIL-CLOSED PER FLOW.
# First gate EVERY id across EVERY flow (an ill-formed id raises before any wire,
# so no flow lands). Then fold over the flows: a flow that lands records its
# {parent_id, child_ids}; a flow that fails is SKIPPED — its parent stays held,
# the batch continues. The result is input order, landed flows only.
def add_bulk(conn, queue, flows) when is_binary(queue) and is_list(flows) do
  Enum.each(flows, fn %{parent: %{id: pid}, children: cs} ->
    _ = Keyspace.job_key(queue, pid)                                  # gate the parent id
    Enum.each(cs, fn %{id: cid} = c -> Keyspace.job_key(child_queue(c, queue), cid) end)
  end)

  landed =
    Enum.reduce(flows, [], fn flow, acc ->
      case add(conn, queue, flow) do
        {:ok, {parent_id, child_ids}} -> [{parent_id, child_ids} | acc]  # this flow landed
        # fail-closed PER FLOW: this flow's parent stays held; the batch
        # continues with the next flow (a poison flow does not abort the others,
        # and its held parent is host-retryable by id).
        _ -> acc
      end
    end)

  {:ok, Enum.reverse(landed)}    # input order (the fold prepended; reverse restores it)
end
```

The bulk verb adds no new Lua. It reuses `add/3` — which lands a same-queue flow atomically in one script and a
cross-queue flow host-orchestrated and fail-closed — and applies the per-flow honesty across the batch. (The fold
prepends each landed flow onto an accumulator, so `Enum.reverse/1` at the end restores input order.)

## Interactive — the per-flow ledger (hero) + the held-parent rule (main)

- **Hero — the per-flow ledger.** A fixed batch of four flows over a fixed keyspace, one of them poison (a child that
  fails to land). Step the ledger to read which flows landed (their `{parent, [children]}` recorded) and which failed
  (its parent left held, omitted from the result) — and confirm the batch continued past the poison flow. Pure over the
  fixed dataset.
- **Main — the held-parent rule.** Pick a flow to read its outcome: a landed flow's parent awaits its children; a
  failed flow's parent is held, host-retryable by id, and absent from the result list. Pure lookup.

## Pattern & implementation

- **The pattern (Redis Patterns Applied):** batching a set of related writes still demands each unit be all-or-nothing
  — a partial unit must leave a safe, recoverable state, not a half-built one. `/redis-patterns/queues` teaches reliable
  queues; the per-unit-safety angle is the near side of this door.
- **The implementation (echo_mq):** `add_bulk/3` issues `add/3` per flow and is fail-closed per flow — a flow that
  fails to land leaves its own parent held and the batch continues, returning the landed flows in input order.

## Recap

Bulk flows is many single adds, fail-closed per flow: each flow lands as a whole or its parent stays held, a poison
flow does not abort the others, and the result lists the landed flows in input order. The batch repeats the single
add's honesty independently per flow.

## References

### Sources
- Valkey — SET (`https://valkey.io/commands/set/`) — the `:dependencies` counter each flow's parent is held by.
- Redis — EVALSHA (`https://redis.io/commands/evalsha/`) — the run-by-SHA dispatch each `add/3` lands its flow with.
- Valkey — ZADD (`https://valkey.io/commands/zadd/`) — the pending-set insertion each flow's claimable children enter through.
- Valkey — Documentation (`https://valkey.io/docs/`) — the substrate of record EchoMQ is backed by.

### Related in this course
- `/echomq/queue/batches` — Batches, the module this dive belongs to.
- `/echomq/queue/batches/enqueue-many` — admit many jobs in one flush.
- `/echomq/queue/batches/batch-lease-extension` — extend many leases under one clock read.
- `/echomq/queue` — The Queue, where flows are taught in depth.
- `/redis-patterns/queues` — reliable queues, the near side of the door.
