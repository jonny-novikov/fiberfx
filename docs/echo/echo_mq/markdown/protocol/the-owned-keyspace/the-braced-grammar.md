# The braced grammar

> Dive 1 · The owned keyspace · The Protocol · route `/echomq/protocol/the-owned-keyspace/the-braced-grammar`
> Grounding: all real code in `echo/apps/echo_mq/lib/echo_mq/keyspace.ex`. No `[RECONCILE]` markers.

## The fact

Every key EchoMQ writes has the same shape: `emq:{q}:<type>`. The literal `emq:`, the queue name in braces, a colon,
then the type. This is the **L1 grammar** — the data layer of the protocol — and it is **total**: there is no key the
system writes that is not composed by `EchoMQ.Keyspace`. The grammar has exactly two productions in this module: the
per-queue key (`queue_key/2`) and the job row (`job_key/2`), which is itself a per-queue key with a validated branded
id appended.

## The worked example — `queue_key/2`

`queue_key(queue, type)` builds the per-queue key as iodata, then flattens it to a binary:

```elixir
# echo_mq — EchoMQ.Keyspace
# Per-queue keys are emq:{q}:<type>. The braces are not decoration —
# they are the cluster hashtag, and they pin every key of one queue to
# one slot. Built as iodata, then flattened once.
def queue_key(queue, type) when is_binary(queue) and is_binary(type),
  do: IO.iodata_to_binary(["emq:{", queue, "}:", type])
```

The `<type>` is the role of the key within the queue: `pending` (the ready set), `active` (the claimed set),
`schedule` (the delayed set), and so on. So one queue named `orders` owns a whole family of co-located keys:

- `emq:{orders}:pending`
- `emq:{orders}:active`
- `emq:{orders}:schedule`
- `emq:{orders}:job:<id>`

All four carry the same `{orders}` hashtag, so all four land on one slot — which is what lets one atomic Lua script
move a job between them in a single round.

## The worked example — `job_key/2`

The job row is a per-queue key with the type `job:` and a **validated** branded id appended:

```elixir
# echo_mq — EchoMQ.Keyspace
# The job row is a per-queue key whose type is "job:" plus the branded id.
# The id is GATED first: the keyspace refuses to address an unbranded row,
# so a malformed id never becomes a key.
def job_key(queue, branded) when is_binary(branded) do
  if EchoData.BrandedId.valid?(branded) do
    queue_key(queue, "job:") <> branded
  else
    raise ArgumentError, "job_key requires a valid branded id"
  end
end
```

So `job_key("orders", "JOB0Nb1VTbfnu4")` yields `emq:{orders}:job:JOB0Nb1VTbfnu4`. The branded id is the long part of
the key by design — 14 bytes, namespace plus Base62 payload — and the validity check is the first place the wire
enforces it. (The same id is gated a second time inside the Lua, on the kind prefix — that is the next module.)

## The bridge — pattern → implementation

- **The pattern (Redis Patterns Applied):** a key naming convention becomes a contract when every writer agrees on the
  exact string shape — the prefix, the separators, the field positions. (`/redis-patterns/coordination/hash-tag-colocation`.)
- **The implementation (echo_mq):** `EchoMQ.Keyspace.queue_key/2` and `job_key/2` make `emq:{q}:<type>` the only way
  a key is built, so the convention is total — the grammar is the protocol, not a style guide.

## Recap

The braced grammar is `emq:{q}:<type>`. `queue_key/2` builds the per-queue key; `job_key/2` builds the job row from a
per-queue key plus a validated branded id. Every key of one queue shares the `{q}` hashtag, so they co-locate. Next:
what the hashtag computes — the slot.

## References

### Sources
- Redis — Keyspace & cluster hash tags — `https://redis.io/docs/` — the `{...}` hashtag convention the braces use.
- Valkey — Documentation — `https://valkey.io/docs/` — the store the grammar addresses; the substrate of record.
- Valkey — HSET — `https://valkey.io/commands/hset/` — the hash write that fills a job row.

### Related in this course
- `/echomq/protocol/the-owned-keyspace` — the module hub.
- `/echomq/protocol/the-owned-keyspace/the-hashtag-and-the-slot` — the next dive: the slot the brace computes.
- `/echomq/protocol/the-owned-keyspace/the-reserve` — the cross-queue reserve.
- `/echomq/protocol/the-record-hash` — what the job row holds.
- `/redis-patterns/coordination/hash-tag-colocation` — the near side of the door.
