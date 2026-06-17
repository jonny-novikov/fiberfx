# The protocol below the line

> Route: `/echomq/overview/the-protocol-below-the-line` (Overview dive 02 · why). The route-mirror source-of-record the
> HTML reflects. Grounding: the as-built keyspace + wire (`echo/apps/echo_mq/lib/echo_mq/keyspace.ex`,
> `echo/apps/echo_wire/lib/echo_mq/{script,connector}.ex`) and one real inline Lua script
> (`echo/apps/echo_mq/lib/echo_mq/jobs.ex`, the `@enqueue` handle). All real code — no `[RECONCILE]` markers on this
> page. Discipline: as-shipped (no versions), extract-and-annotate (two-beat Lua, no `file:line`), no-invent.

## The fact

The three pillars interoperate, and any runtime can drive them, for one reason: the protocol lives **below the language
line**. Read EchoMQ as a stack. **L0** is Valkey, the engine. **L1** is the data layer — which key holds which
structure and what the field names are. **L2** is the set of atomic Lua scripts that move a record between states.
**L3** is the script executor — load a script once, run it by SHA. **L4** is the language API a caller invokes. The
shared line falls between **L2 and L3**: everything at L2 and below is the protocol — fixed and shared by everything
that speaks it; everything at L3 and above is the runtime's own. That single placement is what lets one wire serve
three pillars, and what lets any runtime speak the same wire.

## The line, on a real key

The data layer is concrete: a real key the system builds for every queue. `EchoMQ.Keyspace.queue_key/2` composes the
per-queue key `emq:{q}:<type>` — the literal `emq:`, the queue name wrapped in braces, the type suffix:

```elixir
# echo_mq — EchoMQ.Keyspace
# Per-queue keys are emq:{q}:<type>. The braces are not decoration —
# they are the cluster hashtag, and they pin every key of one queue to
# one slot.
def queue_key(queue, type) when is_binary(queue) and is_binary(type),
  do: IO.iodata_to_binary(["emq:{", queue, "}:", type])
```

The `{q}` is the **hashtag**. A Valkey cluster routes a key by a CRC16 of the substring inside the first `{...}`, so
wrapping the queue name pins every key of that queue — `emq:{orders}:pending`, `emq:{orders}:active`,
`emq:{orders}:job:<id>` — to **one slot**. One atomic script can touch the pending set, the active set, and the job row
in a single round because they are guaranteed co-resident. That key format is **L1**: it is the same wherever the
protocol runs. Change the literal `emq:`, or move the braces, and you are speaking a different wire.

## The line, on a real script — two beats

The state transitions are **L2**. They are not application code that happens to touch Valkey — they are server-side Lua
that runs *inside* the engine, atomically. The discipline that makes them portable: every key a script touches is
**declared in `KEYS[]`**; `ARGV` carries values only. Read the enqueue transition in two beats.

**Beat one — the named handle.** `EchoMQ.Jobs.enqueue/4` builds the two keys it will touch and runs the `@enqueue`
script through the connector. The keys are built host-side, by the keyspace; the script receives them declared:

```elixir
# echo_mq — EchoMQ.Jobs
# The host builds the two keys the script touches — the job row and the
# pending set — and hands them in declared. The connector runs @enqueue
# EVALSHA-first (load-on-NOSCRIPT once). KEYS = [row, pending]; the values
# (the id and the payload) ride ARGV.
def enqueue(conn, queue, job_id, payload) when is_binary(job_id) and is_binary(payload) do
  keys = [Keyspace.job_key(queue, job_id), Keyspace.queue_key(queue, "pending")]

  case Connector.eval(conn, @enqueue, keys, [job_id, payload]) do
    {:ok, 1} -> {:ok, :enqueued}
    {:ok, 0} -> {:ok, :duplicate}
    {:error, {:server, "EMQKIND" <> _}} -> {:error, :kind}
    other -> other
  end
end
```

**Beat two — the script body.** `@enqueue` is the protocol: admit by kind, refuse a duplicate, write the row, insert
the pending entry — one atomic step. `KEYS[1]` is the job row, `KEYS[2]` the pending set; `ARGV[1]` is the branded id,
`ARGV[2]` the payload.

```lua
-- the @enqueue script (L2) — one atomic transition, every key declared
-- The branded-id gate: the id must be JOB-namespaced, refused at the wire.
if string.sub(ARGV[1], 1, 3) ~= 'JOB' then
  return redis.error_reply('EMQKIND job id must be JOB-namespaced')
end
-- Idempotent: a row that already exists is a no-op (a duplicate enqueue).
if redis.call('EXISTS', KEYS[1]) == 1 then
  return 0
end
-- The three-field row: state, attempts, payload — the shape every speaker reads.
redis.call('HSET', KEYS[1], 'state', 'pending', 'attempts', '0', 'payload', ARGV[2])
-- The pending set: the id is the member, so byte order is mint order.
redis.call('ZADD', KEYS[2], 0, ARGV[1])
return 1
```

This is the deep treatment's preview — the full key taxonomy and the script inventory are the **Protocol** chapter.
What the excerpt shows is the boundary: the `KEYS`/`ARGV` contract, the branded-id gate, the three named fields. None
of it is language-specific. The executor that runs it — load-once, run-by-SHA — is **L3**, above the line, and each
runtime writes that its own way.

## The polyglot consequence, in one line

Because the keys and the Lua are the whole agreement, any runtime that speaks them is a peer — so EchoMQ is supported
in, and ported to, other runtimes; the depth of this course is the canonical one, Elixir.

## Why L1 and L2 are fixed — change a field, who breaks?

The fields `state`, `attempts`, `payload` are L1, and so is the key prefix. They are the contract, not an
implementation detail. Rename `payload` to `data` in one runtime's executor and that runtime's `@enqueue` writes a
field nobody else reads — `claim` returns the row, every other speaker reads `payload`, and finds nothing. The data is
not lost; it is invisible across the wire. The same is true of the key: change `emq:` and your jobs land in a keyspace
no other speaker looks in. That is why L1 and L2 do not move. The L4 verb is the opposite: `enqueue` could be spelled
any way in any language — it is above the line, and renaming it breaks nothing on the wire. (Interactive: change a
field name or the key prefix and read who can still find the row; rename the L4 verb and watch the wire stay intact.)

## The bridge (pattern → implementation)

- **The pattern (Redis Patterns Applied):** a Redis convention becomes a protocol when the agreement is pushed below
  the line — the keys plus the atomic scripts — and the runtime is left above it. `/redis-patterns` teaches that move;
  this is the system that applies it.
- **The implementation (echo_mq):** `EchoMQ.Keyspace.queue_key/2` fixes the key `emq:{q}:<type>` with the `{q}`
  hashtag; the `@enqueue` script fixes the transition with every key declared in `KEYS[]`. L1 and L2, shared and fixed
  — the executor and the API above them.

**Take:** draw the line between L2 and L3, and a Valkey convention becomes a protocol three pillars share and any
runtime can speak. Below it: one key format, one set of declared-key scripts. Above it: your language.

## Recap

The protocol below the line is the keys and the Lua. `EchoMQ.Keyspace.queue_key/2` builds `emq:{q}:<type>`, where the
`{q}` hashtag pins one queue to one slot so one atomic script can touch its sets and rows together. `EchoMQ.Jobs`'s
`@enqueue` script declares every key it touches in `KEYS[]`, gates the branded id, and writes the three-field row and
the pending entry atomically. That shared substrate — L1 and L2 — is fixed; the executor (L3) and the API (L4) are the
runtime's own. The next dive reads where EchoMQ lands: the door from Redis Patterns Applied and the BCS family.

## References

### Sources
- [Valkey — Documentation](https://valkey.io/docs/) — the BSD-licensed, foundation-governed store EchoMQ is backed by; the substrate of record.
- [Valkey — EVALSHA](https://valkey.io/commands/evalsha/) — the load-once, run-by-SHA dispatch the L3 executor uses to run an L2 script.
- [Redis — Keyspace & hash tags](https://redis.io/docs/) — cluster key routing by the hashtag inside `{...}`, the L1 mechanism the `{q}` brace uses.
- [DragonflyDB — Server flags](https://www.dragonflydb.io/docs/managing-dragonfly/flags) — `--lock_on_hashtags`: the thread-per-shard placement the declared-key, per-queue-hashtag keyspace is built for.

### Related in this course
- [Overview](/echomq/overview) — the chapter this dive belongs to; the three pillars over one wire.
- [The Protocol](/echomq/protocol) — the owned keyspace, the record hash, and the Lua layer in depth (the next chapter the line opens onto).
- [redis-patterns · Patterns become protocol](/redis-patterns/overview/patterns-become-protocol) — the near side of the door: the move from convention to protocol.
- [The Branded Component System](/bcs) — the architecture EchoMQ is the bus of; the branded id the `@enqueue` gate enforces is its identity contract.
- [Course home](/echomq) — the full six-chapter map.
