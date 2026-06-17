# Reading the results — the parent runs on its children's outcomes

> Route: `/echomq/queue/flows/reading-the-results` · surface: dive · pillar: The Queue
> Grounding: **all real code** in `echo/apps/echo_mq` (`flows.ex` `children_values/3`, `dependencies/3`, `ignored_failures/3`; the `@complete` HSET into `:processed`). No `[RECONCILE]` markers.

## The fact

A flow parent does not merely run *after* its children — it runs *on* their outcomes. EchoMQ records
what each child produced as the fan-in fires, in subkeys composed onto the parent's job key, and exposes
three **pure reads** of them. Each gates the parent id, issues one read-class command, and effects no
state change:

- `children_values/3` — `HGETALL` the parent's `:processed` hash → `%{child_id => result}`.
- `dependencies/3` — `GET` the parent's `:dependencies` counter → a non-negative integer (`0` when none).
- `ignored_failures/3` — `HGETALL` the parent's `:unsuccessful` hash → `%{child_id => error}`.

## Where the results come from

The fan-in branch inside `@complete` writes each child's result into `:processed` keyed by the child's
id at the same moment it decrements the counter: `redis.call('HSET', KEYS[4], ARGV[1], ARGV[5])`. So
after `k` of `N` children complete, `:processed` holds exactly those `k` results — a partial read is an
honest snapshot, not a wait.

## children_values/3 — the results

A pure `HGETALL` of the parent's `:processed` hash, decoded to a `%{child_id => result}` map. A parent
with no completed children yet returns `{:ok, %{}}`:

```elixir
# echo_mq — EchoMQ.Flows.children_values/3
# Read the completed children's results keyed by child id — the parent reads
# what its legs produced. A PURE HGETALL of the parent's :processed hash
# (composed onto the gated parent job key the way :logs composes), no state
# change. After k of N children complete, the map holds exactly those k results.
def children_values(conn, queue, parent_id) when is_binary(queue) and is_binary(parent_id) do
  key = Keyspace.job_key(queue, parent_id) <> ":processed"  # gates the id; raises if ill-formed

  case Connector.command(conn, ["HGETALL", key]) do
    {:ok, map} when is_map(map) -> {:ok, map}        # RESP3 returns a native map
    {:ok, flat} when is_list(flat) -> {:ok, hash_pairs(flat)}  # RESP2 [k, v, k, v] fallback
    other -> other
  end
end
```

Each value is the real result the child carried at completion; a child completed through the shipped
arity (no result) records a presence marker — its own id — instead.

## dependencies/3 — the outstanding count

A pure `GET` of the `:dependencies` string counter, parsed to a non-negative integer. It is `0` once
every child has completed, and `{:ok, 0}` when there is no counter at all (not a flow parent, or already
swept):

```elixir
# echo_mq — EchoMQ.Flows.dependencies/3
# Read the parent's outstanding-child COUNT (how many legs are still running).
# A PURE GET of the :dependencies string counter add/3 wrote with SET and the
# fan-in decrements. 0 once every child has completed; {:ok, 0} when there is no
# counter — the honest "zero outstanding" floor, no new error vocabulary.
def dependencies(conn, queue, parent_id) when is_binary(queue) and is_binary(parent_id) do
  key = Keyspace.job_key(queue, parent_id) <> ":dependencies"

  case Connector.command(conn, ["GET", key]) do
    {:ok, nil} -> {:ok, 0}                                  # no counter -> zero outstanding
    {:ok, n} when is_binary(n) -> {:ok, String.to_integer(n)}
    {:ok, n} when is_integer(n) and n >= 0 -> {:ok, n}
    other -> other
  end
end
```

This reads the **count**, not which children remain — `:dependencies` is a counter, so the count is the
only shape a `GET` of it yields.

## ignored_failures/3 — the failures the parent proceeded past

The failure counterpart of `children_values/3`. A child marked ignore-on-failure that dies is recorded
in the parent's `:unsuccessful` hash keyed by its id with its error as the value. A pure `HGETALL`
reads it back:

```elixir
# echo_mq — EchoMQ.Flows.ignored_failures/3
# Read the children that DIED but were ignored-on-failure, keyed by child id with
# their error. A PURE HGETALL of the parent's :unsuccessful hash. Disjoint from
# children_values/3 by construction: a child is in :processed (it completed, with
# a result) XOR :unsuccessful (it died and was ignored) — never both. A
# fail-the-parent death lands in :failed and appears in NEITHER read.
def ignored_failures(conn, queue, parent_id) when is_binary(queue) and is_binary(parent_id) do
  key = Keyspace.job_key(queue, parent_id) <> ":unsuccessful"

  case Connector.command(conn, ["HGETALL", key]) do
    {:ok, map} when is_map(map) -> {:ok, map}
    {:ok, flat} when is_list(flat) -> {:ok, hash_pairs(flat)}
    other -> other
  end
end
```

`:processed` and `:unsuccessful` are disjoint: a child completed (a result) XOR died-and-ignored (an
error). A child that fails the parent lands in `:failed` and appears in neither.

## The worked example (hero + main interactives)

- **Hero — the three subkeys.** Picking a read shows which subkey it touches (`:processed`,
  `:dependencies`, `:unsuccessful`), the command class, and the shape it returns over a fixed flow.
- **Main — read a flow's state.** A parent with three children at a chosen progress point. The readout
  computes `children_values` (the completed map), `dependencies` (the outstanding count), and
  `ignored_failures` (the ignored-failure map) as pure functions of how many children have completed and
  which one was ignored-on-failure.

## Pattern & implementation (bridge)

- **The pattern (Redis Patterns Applied).** A parent step reading its dependencies' results is the
  flow-control / orchestration angle, **R6 · Flow control**. The near, resolvable door is
  **R3 · Reliable Queues** (`/redis-patterns/queues`): each child is one reliable-queue job whose result
  the parent reads.
- **The implementation (echo_mq).** The fan-in HSETs each result into `:processed`;
  `children_values/3` / `dependencies/3` / `ignored_failures/3` read it back with one read-class command
  each, id-gated, no state change.

## Recap

The parent runs on its children's outcomes through three pure reads: `:processed` (the results),
`:dependencies` (the outstanding count), `:unsuccessful` (the ignored failures). The next dive reads
what changes when a child runs in a different queue, and how a failing child resolves.

## References

### Sources
- Valkey — HGETALL (`https://valkey.io/commands/hgetall/`) — the read `children_values/3` and `ignored_failures/3` issue.
- Valkey — GET (`https://valkey.io/commands/get/`) — the read `dependencies/3` issues over the counter.
- Valkey — HSET (`https://valkey.io/commands/hset/`) — the write the fan-in records each child's result with.
- Valkey — Documentation (`https://valkey.io/docs/`) — the substrate of record EchoMQ is backed by.

### Related in this course
- `/echomq/queue/flows` — the Flows module hub.
- `/echomq/queue/flows/parent-and-children` — the held parent, the atomic add, and the fan-in hook.
- `/echomq/queue/flows/cross-queue-and-failure-policy` — the cross-queue add and the failure policy.
- `/echomq/protocol` — the owned keyspace the flow subkeys compose onto.
- `/redis-patterns/queues` — the reliable-queue pattern, the near side of the door.
