# The four sets

> Route: `/echomq/queue/the-lifecycle/the-four-sets` · surface: dive · pillar: The Queue.
> Grounded entirely in real code (`echo/apps/echo_mq/lib/echo_mq/{jobs,keyspace}.ex`). No reconcile shadow needed — all surfaces verified on disk.

## The fact

A job's whole position in its life is held by **which sorted set its id is a member of**. There are four:
`emq:{q}:pending`, `emq:{q}:active`, `emq:{q}:schedule`, `emq:{q}:dead`. They are sorted sets, and the member is **the
branded id itself** — not a pointer to the id, not a row reference, the id. Because the id is a branded Snowflake
(`EchoData.BrandedId`: a 3-letter `JOB` namespace + an 11-char Base62 of a time-ordered Snowflake, 14 bytes), **the byte
order of the ids is their mint order**. A sorted set kept at one score and ordered lexically by member is therefore a
queue ordered oldest-first by construction — with **no second index** to maintain.

## The keys are built by the keyspace, not the data

Every set key comes from `EchoMQ.Keyspace.queue_key/2`, which composes `emq:{` + the queue + `}:` + the type. The
per-queue `{q}` is a cluster hashtag, so all four of one queue's sets land on **one slot** — every transition can touch
them in one atomic script.

```elixir
# echo_mq — EchoMQ.Keyspace
# queue_key builds emq:{q}:<type>. The braces are a cluster hashtag: every key
# of one queue hashes on the {q} substring, so pending/active/schedule/dead all
# land on ONE slot — which is what lets one Lua script touch them atomically.
def queue_key(queue, type) when is_binary(queue) and is_binary(type),
  do: IO.iodata_to_binary(["emq:{", queue, "}:", type])

# job_key gates the id BEFORE it ever reaches a key. A malformed id raises here,
# never reaching the wire — the row key cannot be forged from bad data.
def job_key(queue, branded) when is_binary(branded) do
  if EchoData.BrandedId.valid?(branded) do
    queue_key(queue, "job:") <> branded
  else
    raise ArgumentError, "job_key requires a valid branded id"
  end
end
```

The grammar is `emq:{q}:job:<id>` for the row and `emq:{q}:<type>` for the four sets — the id is the member of the set,
and the same id (gated) composes the row key.

## Mint order is byte order, so browse needs no index

Because the member is the id and the id sorts by mint, the newest-first browse is a plain lexical range over the set —
reverse, by member, no score sort and no auxiliary structure:

```elixir
# echo_mq — EchoMQ.Jobs
# browse the pending set newest-first. The members ARE the ids, ordered by their
# own bytes (mint order), so ZRANGE ... REV BYLEX walks newest-to-oldest with no
# second index. + and - are the lexical max/min bounds.
def browse(conn, queue, n) when is_integer(n) and n > 0 do
  key = Keyspace.queue_key(queue, "pending")
  Connector.command(conn, ["ZRANGE", key, "+", "-", "BYLEX", "REV", "LIMIT", "0", Integer.to_string(n)])
end

# depth is one count. ZCARD over the pending set — no scan, no index.
def pending_size(conn, queue) do
  Connector.command(conn, ["ZCARD", Keyspace.queue_key(queue, "pending")])
end
```

`browse/3` returns the `n` newest pending ids; `pending_size/2` returns the pending depth. Both read the set directly
because the set already holds the answer.

## Interactives

- **Hero — the four sets diagram.** A fixed five-job dataset; pick a set and read its members (the branded ids in mint
  order) and what the score means. Pure function over the dataset.
- **Main — the set inspector.** Run `browse/3` (newest-first, by N) and `pending_size/2` over the fixed pending set; the
  readout shows the actual `ZRANGE … REV BYLEX` slice and the `ZCARD` count.

## Pattern & implementation

- The pattern (Redis Patterns Applied): a job's state is encoded by **which collection it lives in**, not a status
  column — *States as locations* in `/redis-patterns/queues`.
- The implementation (echo_mq): four sorted sets keyed by `queue_key/2`, members the branded ids, so byte order is mint
  order and `browse/3` + `pending_size/2` read the set with no index.

## The durable floor (the door to Echo Persistence)

The `dead` set is the only finished-and-retained state — a job kept for inspection, in memory. Retention does not have
to mean resident: when a queue trims its history, `EchoStore.StreamArchive` folds the trimmed segments into the durable
`EchoStore.Graft` floor (CubDB's append-only B-tree, on to Tigris), keeping deep history off-heap and readable beside
the live tail. The fold is real code (`echo/apps/echo_store/lib/echo_store/{stream_archive,graft}.ex`); the durable
floor is taught in full in Echo Persistence (`/echo-persistence`), per `docs/echo/bcs/bcs.3.md` B3.3 / `bcs.5.md`.

## References

### Sources
- Valkey — ZRANGEBYLEX — `https://valkey.io/commands/zrangebylex/` — the lexical range the newest-first browse runs.
- Valkey — ZCARD — `https://valkey.io/commands/zcard/` — the set cardinality the pending depth reads.
- Valkey — ZADD — `https://valkey.io/commands/zadd/` — the member-and-score insertion every set is built with.
- Valkey — Documentation — `https://valkey.io/docs/` — the substrate of record the sets live in.

### Related in this course
- `/echomq/queue/the-lifecycle` — the module this dive belongs to.
- `/echomq/protocol/the-owned-keyspace` — where the four set keys are built.
- `/echomq/protocol/immutability-and-branded-ids` — the branded id whose bytes are mint order.
- `/redis-patterns/queues` — states as locations, the pattern this implements.
- `/echo-persistence` — the durable floor a trimmed, retained history folds into.
