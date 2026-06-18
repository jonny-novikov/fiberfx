# The branded-id gate — dive

> Route: `/echomq/protocol/immutability-and-branded-ids/the-branded-id-gate` · surface: **dive**.
> Grounding: **real code** in `echo/apps/echo_mq` + `echo/apps/echo_data`. **No `[RECONCILE]` markers.**

## The fact

A job's identity is not a number the caller picks. It is a **14-byte branded id**: a three-letter uppercase namespace
followed by an eleven-character Base62 encoding of a Snowflake. For a job the namespace is `JOB`. The branding is not
decoration — it is checked at the wire, in the Lua script, before a row is ever written. The first line of the
`@enqueue` script reads the first three bytes of the id and refuses anything that is not `JOB`. An id from the wrong
namespace is rejected with the `EMQKIND` error class and never reaches a key.

This is identity enforced where it counts: on the server, atomically, as part of the same script that writes the row.
A caller cannot smuggle a bare integer, a UUID, or another component's id into the job keyspace. The gate is three
bytes of Lua, and it is the protocol's identity contract made executable.

## The worked example (real grounding) — two beats

**Beat one — the named handle.** `EchoMQ.Jobs.enqueue/4` builds the keys and runs `@enqueue`, then maps the server's
verdict — including the `EMQKIND` refusal — back to a typed result.

```elixir
# echo_mq — EchoMQ.Jobs
# The host builds the declared keys and runs @enqueue. The server's verdict
# is mapped: 1 enqueued, 0 a duplicate, and an EMQKIND error reply (the
# branded-id gate firing) becomes the typed {:error, :kind}.
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

**Beat two — the gate, in the script body.** The first thing `@enqueue` does is check the namespace. `ARGV[1]` is the
branded id; `string.sub(ARGV[1], 1, 3)` is its first three bytes. Not `'JOB'` → `redis.error_reply('EMQKIND …')`, and
the script stops before `EXISTS`, before `HSET`, before `ZADD`.

```lua
-- the @enqueue script — the branded-id gate is the first statement
-- ARGV[1] is the 14-byte branded id. Its first three bytes are the
-- namespace. A job id must be JOB-namespaced; anything else is refused at
-- the wire, before a row exists.
if string.sub(ARGV[1], 1, 3) ~= 'JOB' then
  return redis.error_reply('EMQKIND job id must be JOB-namespaced')
end
-- only a JOB-namespaced id reaches the idempotency check and the row write
if redis.call('EXISTS', KEYS[1]) == 1 then
  return 0
end
redis.call('HSET', KEYS[1], 'state', 'pending', 'attempts', '0', 'payload', ARGV[2])
redis.call('ZADD', KEYS[2], 0, ARGV[1])
return 1
```

A second gate runs host-side, earlier: `EchoMQ.Keyspace.job_key/2` calls `EchoData.BrandedId.valid?/1` and raises on an
ill-formed id, so a malformed id never even reaches the key builder. The Lua gate is the wire's own check — the one that
holds for every speaker, in any runtime, because it lives in the shared script rather than in one runtime's host code.

The 14-byte layout (real, from `EchoData.BrandedId`): `3 × [A-Z]` namespace ++ `base62(snowflake)` padded to 11. The
Snowflake packs `ts(41) << 22 | node(10) << 12 | seq(12)` against epoch `1704067200000`. The namespace the gate reads is
the first three of those fourteen bytes.

## The interactives

1. **Hero — the 14-byte branded-id decoder.** Pick a sample id (a real `JOB…` id, a `USR…` id, a malformed id) and read
   it apart: namespace, Snowflake, the unpacked timestamp / node / sequence, and the gate verdict (`JOB` → admitted,
   else → `EMQKIND` refused). Pure decode functions over a fixed set, live `.geo-readout`, an `<svg>` of the byte
   layout (3 namespace bytes + 11 Base62 bytes).
2. **Main — the gate, byte by byte.** Type or pick a candidate namespace and watch `string.sub(id, 1, 3)` compared to
   `'JOB'`, with the exact verdict the script returns. Pure comparison over the fixed model, with a live readout.

## The bridge (pattern → implementation)

- **The pattern (Redis Patterns Applied):** a branded key carries its type in its bytes, and the atomic script that
  touches it can check that type before it acts. `/redis-patterns/coordination` teaches the atomic, check-then-act move
  the gate is an instance of.
- **The implementation (echo_mq):** `@enqueue`'s first statement is `string.sub(ARGV[1], 1, 3) ~= 'JOB'` →
  `EMQKIND`; the 14-byte id (`EchoData.BrandedId`) is `JOB` + Base62 Snowflake; `Keyspace.job_key/2` gates it again
  host-side via `valid?/1`.

## Recap + take

A job id is a 14-byte branded Snowflake under `JOB`, and the gate that enforces it is the first line of the `@enqueue`
script — three bytes compared, the wrong namespace refused with `EMQKIND` before any write. **Take:** identity is
checked in the shared script, not in one runtime's host code, so the gate holds for every speaker of the wire.

## References

### Sources
- Redis — EVALSHA (`https://redis.io/commands/evalsha/`) — the dispatch that runs the gate atomically.
- Valkey — Documentation (`https://valkey.io/docs/`) — the substrate of record; Lua semantics.
- Valkey — HSET (`https://valkey.io/commands/hset/`) — the row write that only a gated id reaches.

### Related in this course
- `/echomq/protocol/the-lua-layer` — the script layer the gate is the first statement of.
- `/echomq/protocol/immutability-and-branded-ids/the-immutable-line` — the previous dive: the fixed line.
- `/echomq/protocol/immutability-and-branded-ids/the-version-fence` — the next dive: the connection's fence.
- `/bcs` — the Branded Component System, where the 14-byte branded id is the identity contract.
