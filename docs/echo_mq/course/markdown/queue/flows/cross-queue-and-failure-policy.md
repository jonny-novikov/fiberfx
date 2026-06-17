# Cross-queue & the failure policy

> Route: `/echomq/queue/flows/cross-queue-and-failure-policy` · surface: dive · pillar: The Queue
> Grounding: **all real code** in `echo/apps/echo_mq` (`flows.ex` `add_cross_queue`/`land_children`, `@hold_parent`, `@enqueue_flow_child`; `jobs.ex` `@complete` cross-queue branch + `@retry` failure arms + `parent_fail_of/3`; `pump.ex` `deliver_flow_completions/3` + `@flow_deliver`/`@flow_fail_deliver`). No `[RECONCILE]` markers.

## The fact

When every child runs in the parent's queue, the flow lands in one atomic script — one slot. When **any**
child runs in a **different** queue, that child's keys live on a **different slot**, and no single script
can span two slots. So a cross-queue add is **host-orchestrated, non-atomic across slots, parent-first,
and fail-closed**, and its fan-in is **eventually-consistent** — delivered by the per-queue Pump sweep,
not synchronously at completion.

## Why one script cannot span the queues

A queue's keys are pinned to one slot by the `{q}` hashtag — `emq:{q}:...`. A child in `validation`
lands on `slot("validation")`; its parent in `orders` lands on `slot("orders")`. A Lua script may touch
only keys on one slot, so the parent's `:dependencies` and the cross-queue child's row cannot be written
by the same EVAL. The host orchestrates the steps instead.

## Parent-first, fail-closed

`add_cross_queue` lands the parent **first** — held, with `:dependencies = N` (the total child count) —
then each child on its own slot. Parent-first is the safe order: the counter exists before any child can
complete and try to deliver, so no delivery ever races an absent counter. A child that fails to land
short-circuits and stops; the parent stays **held** — never claimable, never spuriously executed — and
the caller retries by id.

```elixir
# echo_mq — EchoMQ.Flows (the cross-queue path)
# Host-orchestrated, NON-atomic across slots, parent-first, fail-closed. The
# parent lands HELD first (its :dependencies counter exists before any child can
# complete), then each child lands on ITS OWN slot. A failure at any step returns
# the error and STOPS: the parent stays held, the caller retries by id.
defp add_cross_queue(conn, queue, parent_id, parent_payload, children) do
  n = length(children)
  parent_key = Keyspace.job_key(queue, parent_id)

  with {:ok, 1} <-
         hold(
           Connector.eval(
             conn,
             @hold_parent,                                       # all on the parent's slot {P}
             [parent_key, parent_key <> ":dependencies"],
             [parent_id, parent_payload, Integer.to_string(n)]   # N = the TOTAL child count
           )
         ),
       :ok <- land_children(conn, queue, parent_id, children) do  # each child on its own slot
    {:ok, {parent_id, Enum.map(children, & &1.id)}}
  end
end
```

Each child carries its `parent` id, and — for a cross-queue child — a `parent_queue` field, so its
completion knows which outbox to emit to and the sweep knows which slot the parent is on. `@hold_parent`
holds the parent (`state = awaiting_children`, the counter set, **not** added to pending);
`@enqueue_flow_child` lands one child claimable on its own slot.

## The eventually-consistent fan-in

A cross-queue child cannot reach its parent's other-slot `:dependencies` atomically. So its `@complete`
**emits** instead: it RPUSHes a completion entry into the child's own-slot outbox `emq:{q}:flow:outbox`,
atomically with the active-set removal — so a completed cross-queue child always leaves a durable signal
(there is no drop window). The decrement is delivered later, on the parent's slot, by the per-queue Pump
sweep:

```elixir
# echo_mq — EchoMQ.Pump.deliver_flow_completions/3 (the parent-slot half)
# Drain this queue's cross-queue flow outbox and deliver each child's decrement
# to its parent on the PARENT's slot. Read NON-DESTRUCTIVELY, deliver, then trim:
# a crash between read and trim RE-DELIVERS (idempotent via the :processed HSETNX
# guard), never drops — at-least-once becomes effectively-once, no drop window.
def deliver_flow_completions(conn, queue, batch) when is_integer(batch) and batch > 0 do
  outbox = Keyspace.queue_key(queue, "flow:outbox")

  case Connector.command(conn, ["LRANGE", outbox, "0", Integer.to_string(batch - 1)]) do
    {:ok, []} -> {:ok, 0}
    {:ok, entries} when is_list(entries) ->
      # count the CONTIGUOUS delivered prefix; LTRIM removes exactly those,
      # never a not-yet-delivered entry behind a poison one (deliver-before-remove)
      delivered =
        Enum.reduce_while(entries, 0, fn entry, acc ->
          if deliver_one(conn, entry) == 1, do: {:cont, acc + 1}, else: {:halt, acc}
        end)

      if delivered > 0 do
        Connector.command(conn, ["LTRIM", outbox, Integer.to_string(delivered), "-1"])
      end

      {:ok, delivered}
    _ -> {:ok, 0}
  end
end
```

The deliver runs `@flow_deliver` on the parent's slot — an `HSETNX`-guarded `DECR`, so a re-delivered
entry decrements nothing and the parent is released exactly once. A queue that hosts cross-queue children
must run a Pump for its parents to be released; the durable outbox survives a Pump-absent window and
drains on the next start — delayed, never lost.

## The failure policy

A flow declares, per child, what a **dead** child means for the parent:

- **fail_parent_on_failure** — the default. A dead child fails the parent: it is recorded in the parent's
  `:failed`, and the parent moves to `dead`.
- **ignore_dependency_on_failure** — opt-in. A dead child is treated as a satisfied dependency: it is
  recorded in the parent's `:unsuccessful`, `:dependencies` is decremented, and the parent proceeds.

The policy rides each child row as a `parent_policy` token — `'fp'` or `'id'` — read **host-side** at
retry, never as a data-rooted Lua key. `EchoMQ.Jobs.retry/7` reads it and drives the failure branch of
`@retry`:

```elixir
# echo_mq — EchoMQ.Jobs.parent_fail_of/3 (read host-side at retry)
# Read the dead child's parent + failure policy in one HMGET, returning the shape
# the @retry failure branch is driven by. The token defaults to 'fp' (fail the
# parent) when a child carries no parent_policy — the safe default.
defp policy_arm("id"), do: "id"
defp policy_arm(_), do: "fp"
```

A same-queue dead child resolves atomically in the same `@retry` EVAL (the parent shares its slot). A
cross-queue dead child **emits a fail-entry** into its own-slot outbox; the Pump's `@flow_fail_deliver`
applies the policy on the parent's slot — `'fp'` moves the parent to `dead`, `'id'` decrements and at
zero releases — `HSETNX`-guarded, so the parent is failed-or-satisfied exactly once.

## The worked example (hero + main interactives)

- **Hero — same-queue vs cross-queue.** A parent in `orders` with children in `orders`, `validation`,
  `payments`. Picking a child shows whether it lands atomically with the parent (same slot) or on its own
  slot through the host-orchestrated, eventually-consistent path.
- **Main — the failure policy.** Pick a child's policy (fail-parent vs ignore-dependency) and a death,
  and the readout computes where the death is recorded (`:failed` vs `:unsuccessful`), what happens to
  `:dependencies`, and whether the parent dies or proceeds — a pure function of the policy token and the
  outcome.

## Pattern & implementation (bridge)

- **The pattern (Redis Patterns Applied).** Composing dependent work across queues with a declared
  failure policy is the flow-control / orchestration angle, **R6 · Flow control**. The near, resolvable
  door is **R3 · Reliable Queues** (`/redis-patterns/queues`): each leg is one reliable-queue job whose
  death the flow resolves.
- **The implementation (echo_mq).** `add_cross_queue` lands parent-first and fail-closed; the child's
  `@complete` emits to its own-slot outbox; the Pump's `deliver_flow_completions/3` delivers on the
  parent's slot; the `parent_policy` token routes a death through `@flow_fail_deliver`.

## Recap

A cross-queue child lands on a different slot, so the add is host-orchestrated, non-atomic, parent-first,
fail-closed, with an eventually-consistent fan-in through the Pump's outbox sweep. The failure policy —
fail-parent vs ignore-dependency — rides the `parent_policy` token and resolves a dead child either way.

## References

### Sources
- Valkey — RPUSH (`https://valkey.io/commands/rpush/`) — the outbox emit a cross-queue child's completion takes.
- Valkey — DECR (`https://valkey.io/commands/decr/`) — the decrement the Pump delivers on the parent's slot.
- Valkey — SET (`https://valkey.io/commands/set/`) — the `:dependencies` counter the parent is held with, total child count.
- Redis — EVALSHA (`https://redis.io/commands/evalsha/`) — the load-once dispatch the cross-queue scripts run by.
- Valkey — Documentation (`https://valkey.io/docs/`) — the substrate of record EchoMQ is backed by.

### Related in this course
- `/echomq/queue/flows` — the Flows module hub.
- `/echomq/queue/flows/parent-and-children` — the same-queue atomic add and the fan-in hook.
- `/echomq/queue/flows/reading-the-results` — the three pure reads, including `ignored_failures/3`.
- `/echomq/protocol` — the owned keyspace and the per-queue hashtag that pins a queue to one slot.
- `/redis-patterns/queues` — the reliable-queue pattern, the near side of the door.
