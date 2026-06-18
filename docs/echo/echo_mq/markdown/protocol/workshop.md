# The Protocol · Workshop — decode a key, trace a script

> Route: `/echomq/protocol/workshop` · single page (no sub-dives). Md source-of-record for
> `html/echomq/protocol/workshop.html`. Grounded entirely in `echo/apps/echo_mq` + `echo_wire` — **no `[RECONCILE]`
> markers** (nothing here is ahead of code). Crumbs: EchoMQ › The Protocol › Workshop. Pager prev =
> `/echomq/protocol/immutability-and-branded-ids`, next = `/echomq/protocol` (closes the chapter loop).

## The fact

The Protocol is two things a reader can hold in one hand: a **key** and a **script**. A key tells you the queue, the
slot, and (when it is a job row) the kind. A script tells you which keys it touches and in what atomic order. This page
closes the chapter by doing both by hand on real artifacts — no new surface, only the ones the chapter already taught,
exercised.

Two moves:

1. **Decode a key.** Given `emq:{quotes}:job:JOB0KHTOWnGLuC`, read off the queue (`quotes`), compute the cluster slot,
   and read the kind from the branded id.
2. **Trace a script.** Take the `EchoMQ.Jobs @enqueue` handle, read its decoded Lua body, and point at the keys it
   declares in `KEYS[]`.

## The worked example — decode `emq:{quotes}:job:JOB0KHTOWnGLuC`

The grammar is fixed by `EchoMQ.Keyspace`. A per-queue key is the literal `emq:`, the queue name wrapped in a single
brace pair, then the type suffix — `emq:{q}:<type>`. A job row's type is `job:<id>`, so `job_key/2` composes
`emq:{q}:job:<branded-id>`.

```elixir
# echo_mq — EchoMQ.Keyspace
# A per-queue key is emq:{q}:<type>. A job row's type is "job:" then the
# branded id, so job_key/2 is queue_key(queue, "job:") with the id appended.
# The id is gated before it is used — an ill-formed id raises, never reaches a key.
def queue_key(queue, type) when is_binary(queue) and is_binary(type),
  do: IO.iodata_to_binary(["emq:{", queue, "}:", type])

def job_key(queue, branded) when is_binary(branded) do
  if EchoData.BrandedId.valid?(branded) do
    queue_key(queue, "job:") <> branded
  else
    raise ArgumentError, "job_key requires a valid branded id"
  end
end
```

Read the key in three fields:

- **The queue** is the substring inside the first `{...}` — `quotes`. That brace is the hashtag.
- **The slot** is `CRC16-XMODEM(hashtag) % 16384`. `slot/1` computes it client-side over the hashtag, so the connector
  routes and partitions without a server round trip. For `quotes` the slot is `3378`. Because the slot is taken over
  the hashtag, every key of one queue — the pending set, the active set, this job row — lands on the same slot:
  `slot("emq:{quotes}:job:JOB0KHTOWnGLuC") == slot("quotes") == 3378`. The canon vector confirms the algorithm:
  `slot("123456789") == 12739`.
- **The kind** is the first three bytes of the branded id. `JOB0KHTOWnGLuC` parses to namespace `JOB` plus an 11-char
  Base62 payload — 14 bytes, fixed. `EchoData.BrandedId.parse/1` returns `{:ok, "JOB", 274557032793636864}`; the
  namespace `JOB` is the kind, the part the `@enqueue` script gates at the wire.

```elixir
# echo_mq — EchoMQ.Keyspace.slot/1 (CRC16-XMODEM over the hashtag, % 16384)
# Client-side cluster routing: the connector knows the slot without asking the
# server. Known vector: slot("123456789") == 12739.
def slot(key) when is_binary(key), do: rem(crc16(hashtag(key), 0), 16384)

def hashtag(key) do
  with [_, rest] <- :binary.split(key, "{"),
       [tag, _] when tag != "" <- :binary.split(rest, "}") do
    tag           # the substring inside the first {...}
  else
    _ -> key      # no brace pair → the whole key is its own hashtag
  end
end
```

```elixir
# echo_data — EchoData.BrandedId: the 14-byte branded id = 3 [A-Z] namespace ++ base62(snowflake) padded to 11.
# parse/1 splits the namespace from the snowflake; namespace/1 reads the first 3 bytes — the "kind".
iex> EchoData.BrandedId.parse("JOB0KHTOWnGLuC")
{:ok, "JOB", 274557032793636864}
iex> EchoData.BrandedId.namespace("JOB0KHTOWnGLuC")
"JOB"
```

So the key decodes to: queue `quotes`, slot `3378`, kind `JOB` — a job row on the queue's slot.

**Interactive 1 — the key decoder.** Type or pick a key; the readout shows the queue, the computed slot, and (for a
job row) the kind read from the branded id, with a verdict on whether the kind is `JOB`. Pure functions mirror
`hashtag/1`, `slot/1`, and `BrandedId.parse/1` over the typed string. A malformed key (no `emq:{q}:` grammar) is named
as such rather than guessed.

## The worked example — trace `@enqueue` to its declared keys

A verb is a named handle over a Lua script; the script is the protocol. `EchoMQ.Jobs.enqueue/4` builds the two keys
the script will touch — the job row and the pending set — and runs the `@enqueue` handle through the connector. The
keys are built host-side, by the keyspace, and handed in declared.

```elixir
# echo_mq — EchoMQ.Jobs
# Beat one: the named handle. The host builds the two keys the script touches
# — the job row (KEYS[1]) and the pending set (KEYS[2]) — and hands them in
# declared. The connector runs @enqueue EVALSHA-first. The values (the id and
# the payload) ride ARGV.
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

The handle resolves to a script. EVALSHA-first means the connector runs the script by its precomputed SHA1, reloading
the source once on a `NOSCRIPT` miss — `EchoMQ.Script.new/2` precomputes the SHA, `EchoMQ.Connector.eval/5` dispatches.

```lua
-- the @enqueue script (EchoMQ.Jobs) — one atomic transition, every key declared
-- KEYS[1] = the job row    KEYS[2] = the pending set
-- ARGV[1] = the branded id  ARGV[2] = the payload
-- The branded-id gate: the id must be JOB-namespaced — refused at the wire.
if string.sub(ARGV[1], 1, 3) ~= 'JOB' then
  return redis.error_reply('EMQKIND job id must be JOB-namespaced')
end
-- Idempotent: a row that already exists is a no-op (a duplicate enqueue).
if redis.call('EXISTS', KEYS[1]) == 1 then
  return 0
end
-- The three-field row: state, attempts, payload — the shape every speaker reads.
redis.call('HSET', KEYS[1], 'state', 'pending', 'attempts', '0', 'payload', ARGV[2])
-- The pending set: the id is the member at score 0, so byte order is mint order.
redis.call('ZADD', KEYS[2], 0, ARGV[1])
return 1
```

The script declares **two** keys — `KEYS[1]` the job row, `KEYS[2]` the pending set — and constructs none in-script.
That is the law: every key a script touches is passed in `KEYS[]`; `ARGV` carries values only. The decoded key from the
first move is exactly the `KEYS[1]` this script writes: `emq:{quotes}:job:JOB0KHTOWnGLuC` is the job row, on slot
`3378`, with the kind `JOB` the gate admits.

**Interactive 2 — the script tracer.** Pick a verb (`enqueue` / `claim` / `complete`); the readout names its handle and
lists the keys it declares plus the ARGV it carries. The dataset is the real declared-key contract of each handle. The
move teaches a different thing from the decoder: the decoder reads one key, the tracer reads the *set* of keys a
transition touches.

## The bridge — pattern → implementation

- **The pattern (Redis Patterns Applied).** A Valkey convention becomes a protocol when the agreement is pushed below
  the line — the keys plus the atomic scripts — and read directly off the wire. Redis Patterns Applied teaches that move
  (`patterns-become-protocol`); this workshop reads it back off real artifacts.
- **The implementation (echo_mq).** `EchoMQ.Keyspace.queue_key/2` fixes `emq:{q}:<type>` with the `{q}` hashtag, and
  `slot/1` reads the routing off the key; the `EchoMQ.Jobs @enqueue` script fixes the transition with every key declared
  in `KEYS[]`. Decoding a key and tracing a script is reading the protocol with no runtime in the way.

**Take.** The protocol is legible by hand: a key gives you the queue, the slot, and the kind; a handle gives you the
declared keys and the atomic order. Read one of each and you have read the wire.

## Recap

The chapter taught the owned keyspace, the record hash, the Lua layer, and immutability with branded ids. This close
exercised them: `emq:{quotes}:job:JOB0KHTOWnGLuC` decodes to queue `quotes`, slot `3378`, kind `JOB`; the
`EchoMQ.Jobs @enqueue` handle resolves to a script declaring `KEYS[1]` the row and `KEYS[2]` the pending set. The next
step is the chapter map: the three pillars that all stand on this substrate.

## References

### Sources
- Valkey — Documentation — `https://valkey.io/docs/` — the BSD-licensed, foundation-governed store EchoMQ is backed by; the substrate of record.
- Valkey — EVALSHA — `https://valkey.io/commands/evalsha/` — the load-once, run-by-SHA dispatch the connector uses to run the `@enqueue` script.
- Redis — Keyspace & hash tags — `https://redis.io/docs/` — cluster key routing by the hashtag inside `{...}`, the mechanism the `{q}` brace and `slot/1` use.
- Redis — ZADD — `https://redis.io/commands/zadd/` — the same-score sorted-set insert the `@enqueue` script uses for the pending set, so byte order is mint order.

### Related in this course
- `/echomq/protocol` — the chapter this workshop closes; the owned keyspace, the record hash, the Lua layer, immutability.
- `/echomq/protocol/immutability-and-branded-ids` — the last module hub: the branded-id gate this page reads off a real key.
- `/redis-patterns/overview/patterns-become-protocol` — the near side of the door: the move from convention to protocol.
- `/echomq` — the full six-chapter course map.
