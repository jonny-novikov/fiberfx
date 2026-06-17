# Parent and children — the shape of a flow

> Route: `/echomq/queue/flows/parent-and-children` · surface: dive · pillar: The Queue
> Grounding: **all real code** in `echo/apps/echo_mq` (`flows.ex` `@enqueue_flow`/`add/3`, `jobs.ex` `@complete` fan-in branch, `keyspace.ex`). No `[RECONCILE]` markers.

## The fact

A flow has two parts: a **parent** job and a flat list of **children**, all in the same queue. The
children are written claimable in `pending`; the parent is **held out of `pending`** with its
outstanding-child count in a string counter at `<parent job key>:dependencies` and its row
`state = awaiting_children`. The whole same-queue flow lands in one atomic `@enqueue_flow` — all of it,
or none of it. When the last child completes, the **fan-in hook inside `@complete`** releases the
parent to `pending`.

## The held parent

The grammar is `emq:{q}:job:<id>` for a row; the flow subkeys compose onto it the way `:logs` does:
`<job key>:dependencies` is the counter, `<job key>:processed` is the result hash. A held parent is in
none of the four state sets — `pending`, `active`, `schedule`, `dead` — so no claim can ever reach it.
Only the fan-in puts it into `pending`.

## Beat one — the handle

`EchoMQ.Flows.add/3` gates every id at the key builder first (an ill-formed id raises before any wire),
then routes a same-queue flow to one atomic `@enqueue_flow`:

```elixir
# echo_mq — EchoMQ.Flows (the same-queue path)
# Gate the parent and every child id at the key builder BEFORE any wire: an
# ill-formed id raises here, never reaching a key. Then build the declared keys
# and the positional ARGV and run @enqueue_flow as one EVAL on one slot.
defp add_same_queue(conn, queue, parent_id, parent_payload, children) do
  parent_key = Keyspace.job_key(queue, parent_id)
  child_keys = Enum.map(children, fn %{id: cid} -> Keyspace.job_key(queue, cid) end)

  keys =
    [
      parent_key,                       # KEYS[1] the parent row
      parent_key <> ":dependencies",    # KEYS[2] the parent's outstanding-child counter
      Keyspace.queue_key(queue, "pending")  # KEYS[3] the queue's pending set
    ] ++ child_keys                     # KEYS[4..] one row per child, same slot

  argv =
    [parent_id, parent_payload, Integer.to_string(length(children))] ++   # ARGV[1..3]
      Enum.flat_map(children, fn %{id: cid, payload: cp} -> [cid, cp] end)  # ARGV[4..] (id, payload) pairs

  case Connector.eval(conn, @enqueue_flow, keys, argv) do
    {:ok, n} when is_integer(n) ->
      # after the atomic land, the host writes each child's parent_policy token
      # on its row (a plain HSET on the same slot) so @enqueue_flow stays byte-frozen
      {:ok, {parent_id, Enum.map(children, & &1.id)}}
    {:error, {:server, "EMQKIND" <> _}} -> {:error, :kind}
    other -> other
  end
end
```

`add/3` returns `{:ok, {parent_id, [child_id]}}` — the parent id and the child ids in spec order.

## Beat two — the script body

`@enqueue_flow` is the protocol of a same-queue flow. It gates every id first, then lands the children
and holds the parent, all in one indivisible step:

```lua
-- the @enqueue_flow script — one atomic transition on one slot
-- The kind law runs FIRST over the parent and every child id: a non-JOB id
-- refuses with EMQKIND before any write.
if string.sub(ARGV[1], 1, 3) ~= 'JOB' then
  return redis.error_reply('EMQKIND job id must be JOB-namespaced')
end
local n = tonumber(ARGV[3])
for i = 1, n do
  if string.sub(ARGV[2 + 2 * i], 1, 3) ~= 'JOB' then
    return redis.error_reply('EMQKIND job id must be JOB-namespaced')
  end
end
-- Each child: write its row claimable (state pending), carrying the parent id,
-- and add it to the pending set. The child is immediately claimable.
for i = 1, n do
  local child = KEYS[3 + i]              -- KEYS[4], KEYS[5], ... one per child
  local cid = ARGV[2 + 2 * i]
  local cpayload = ARGV[3 + 2 * i]
  redis.call('HSET', child, 'state', 'pending', 'attempts', '0', 'payload', cpayload, 'parent', ARGV[1])
  redis.call('ZADD', KEYS[3], 0, cid)   -- KEYS[3] the pending set
end
-- The parent: held out of pending (state awaiting_children) and the counter set
-- to N. The parent is in NO state set, so no claim can reach it.
redis.call('HSET', KEYS[1], 'state', 'awaiting_children', 'attempts', '0', 'payload', ARGV[2])
redis.call('SET', KEYS[2], n)
return n
```

Either every child row + pending entry and the held parent + counter appear, or none of them do — one
slot, one atomic step.

## The fan-in hook

The release is not a coordinator. It is the same-queue branch already inside the `@complete` script
each completing flow child runs. `KEYS[3]` is the parent's `:dependencies`, `KEYS[4]` its `:processed`,
`KEYS[5]` the parent row; `ARGV[1]` is the completing child's id, `ARGV[4]` the parent's bare id, `ARGV[5]`
the child's result:

```lua
-- the fan-in branch of @complete (excerpt — the single-queue flow path).
-- A non-flow completion passes KEYS[3] nil and never enters here. The DECR sits
-- inside the `was_active == 1` branch the script already computed at ZREM, so it
-- fires EXACTLY once per the child's own active->done transition (a redelivered
-- or stale-token completion never re-enters it — the idempotent fan-in).
if KEYS[3] and was_active == 1 then
  local left = redis.call('DECR', KEYS[3])     -- one fewer outstanding child
  redis.call('HSET', KEYS[4], ARGV[1], ARGV[5]) -- record this child's result in :processed
  if left <= 0 then
    redis.call('ZADD', p .. 'pending', 0, ARGV[4])  -- release the parent to pending
    redis.call('HSET', KEYS[5], 'state', 'pending') -- flip the parent row to pending
  end
end
```

The counter ticks down from N as children finish. At zero, the parent enters `pending` and becomes
claimable like any other job — its own lifecycle begins.

## The worked example (hero + main interactives)

- **Hero — the flow shape.** A parent and three children. Stepping the moves of `@enqueue_flow` shows
  the children landing in pending and the parent held with `:dependencies = 3`.
- **Main — the fan-in counter.** Complete the children one at a time; the readout shows `:dependencies`
  decrementing 3 → 2 → 1 → 0 and, at zero, the parent released to pending. Pure functions over a fixed
  flow: the count is a deterministic function of how many children have completed.

## Pattern & implementation (bridge)

- **The pattern (Redis Patterns Applied).** Orchestrating dependent work — a parent step that waits on
  its legs — is the flow-control angle, **R6 · Flow control**. The near, resolvable door is
  **R3 · Reliable Queues** (`/redis-patterns/queues`): each child is one reliable-queue job.
- **The implementation (echo_mq).** `EchoMQ.Flows.add/3` lands the held parent + the claimable children
  in one `@enqueue_flow`; the fan-in branch inside `@complete` decrements `:dependencies` and at zero
  releases the parent. Composition is a counter and an atomic script.

## Recap

A flow is a held parent + claimable children. `@enqueue_flow` lands a same-queue flow atomically; the
fan-in branch inside `@complete` releases the parent at zero outstanding. The next dive reads how the
parent runs *on* its children's outcomes.

## References

### Sources
- Valkey — SET (`https://valkey.io/commands/set/`) — the `:dependencies` counter the parent is held with.
- Valkey — DECR (`https://valkey.io/commands/decr/`) — the fan-in decrement inside `@complete`.
- Redis — EVALSHA (`https://redis.io/commands/evalsha/`) — the atomic load-once dispatch `@enqueue_flow` runs by.
- Valkey — ZADD (`https://valkey.io/commands/zadd/`) — the pending-set insertion the children and the released parent take.

### Related in this course
- `/echomq/queue/flows` — the Flows module hub.
- `/echomq/queue/flows/reading-the-results` — the three pure reads the parent runs on its children's outcomes.
- `/echomq/queue/flows/cross-queue-and-failure-policy` — the cross-queue add and the failure policy.
- `/echomq/protocol` — the owned keyspace and the Lua layer the flow scripts are built on.
- `/redis-patterns/queues` — the reliable-queue pattern, the near side of the door.
