# Functional partitioning: let the identity decide placement

> R8.03.1 · Pinterest: task queues & partitioning — dive 1 · route `/redis-patterns/production-operations/pinterest-task-queue/functional-partitioning`

Pinterest did not run one store for everything. They put each kind of data on the store that fits how it is
read, and they built the row's location *into its id* so a lookup never has to ask where the row lives. Two
moves — polyglot by access pattern, and the shard-in-the-id — and both reduce to one principle: **placement is
a property of identity, computed and never looked up.**

Grounding: the Pinterest case study (*Sharding Pinterest: How we scaled our MySQL fleet*), and the BCS echo —
the `{q}` hashtag and CRC16 slot in `echo/apps/echo_mq/lib/echo_mq/keyspace.ex`, and the branded-id placement
in `echo/apps/echo_data/lib/echo_data/branded_id.ex`. Valkey is the only engine named for the BCS side;
Pinterest's Redis, MySQL, and memcache are theirs, quoted as the case study.

## §1 · Polyglot by access pattern

By September 2011 every piece of Pinterest's infrastructure was over capacity. The sharding work they launched
in early 2012 — *"still the system we use today"* — carried 50 billion Pins across one billion boards. Part of
that design was refusing to force every kind of data into one engine.

The split they describe is verbatim:

> We keep `pin_id → pin object` cache in a memcache cluster, but we keep `board_id → pin_ids` in a redis
> cluster.

Two kinds of data, two stores, chosen by how each is read. A pin object is a value fetched by key — a cache
read, served well by memcache. A board's list of pin ids is an ordered collection that grows and is scanned —
a list, served well by Redis. The data did not pick the engine; the access pattern did.

This is **functional partitioning**: divide the system by *function* (by what a piece of data is for and how
it is touched), not by carving one homogeneous store into ranges. The store that fits the read is the store
the data goes on.

## §2 · The shard in the id

The second move is sharper. Pinterest gave every id its location. The scheme is verbatim a 64-bit id:

```text
ID = (shard ID << 46) | (type ID << 36) | (local ID<<0)
```

- **shard id — 16 bits** in the high part: which of the shards this row lives on.
- **type id — 10 bits**: which kind of object (a pin, a board, a comment).
- **local id — 36 bits**: the row's id within that type on that shard.

A new Pin is assigned *"to the same shard ID as the board it's inserted into."* So a board and the pins on it
land on one shard, and the id alone tells a reader where the row is. There is no lookup table mapping id to
location: you read the location straight out of the id's high bits.

That is the property that lets the fleet grow. A read goes to one shard, found by arithmetic on the id, with
no directory in the path. Pinterest paired it with a move-cost rule — *"We hated moving data around,
especially item by item… If we had to move data, it was better to move an entire virtual node to a different
physical node"* — so re-balancing moves a whole virtual node, never a row at a time.

## §3 · The BCS echo — placement computed from identity

The BCS bus reaches the same property by a different mechanism, and the difference is the lesson. EchoMQ does
not embed a shard in the high bits of a branded id and read it back out. It does two computed things.

**A queue's keys are co-located by a hashtag.** Every key of one queue is built as `emq:{q}:<type>` — the
queue name sits inside the braces. `EchoMQ.Keyspace` computes the cluster slot client-side, with no server
round trip:

```elixir
# echo/apps/echo_mq/lib/echo_mq/keyspace.ex
def slot(key) when is_binary(key), do: rem(crc16(hashtag(key), 0), 16384)
```

`hashtag/1` takes the substring inside the first `{...}`, `crc16/2` is CRC16-XMODEM, and the result is taken
modulo 16384 — the cluster specification's algorithm. Because the slot is a function of the braced substring,
**every key of one queue lands on the same slot** (the module's own words). The known vector on disk is
`slot("123456789") == 12739`. The queue name decides the location; nothing is looked up.

**A branded id is hashed to a placement.** The id itself carries placement too — not by reading a field, but
by hashing the whole id to a bucket. `EchoData.BrandedId` exposes the contract vector:

```elixir
# echo/apps/echo_data/lib/echo_data/branded_id.ex
iex> EchoData.BrandedId.encode!("USR", 274557032793636864)
"USR0KHTOWnGLuC"
iex> EchoData.BrandedId.hash32(274557032793636864)
234878118
```

`placement("USR0KHTOWnGLuC") → 234878118`: decode the id to its snowflake, hash the snowflake to 32 bits, and
that number is the consistent-hash bucket. The placement is derived from the identity, computed the same way
on any node, with no registry.

The honest parallel is the **principle**, not the mechanism. Pinterest *embeds* the shard in the id's high
bits and bit-extracts it; echo *hashes* the id to a placement and co-locates a queue with the `{q}` hashtag.
Both make placement a property of the identity — found by computation, never by a directory lookup. (Note: the
branded snowflake's `node` field is the *minting* node, the machine that created the id — not a storage shard.
The placement comes from the hash and the hashtag, not from that field.)

## §4 · Bridge — the pattern → its EchoMQ application

**The pattern.** Put data on the store that fits its access pattern, and make a row's placement a function of
its id — Pinterest by `pin_id → memcache`, `board_id → pin_ids → redis`, and `ID = (shard ID << 46) | …`, so a
read finds its shard by arithmetic with no lookup table.

**Its EchoMQ application.** A queue's keys are `emq:{q}:<type>`; `slot/1 = rem(crc16(hashtag(key), 0), 16384)`
sends every key of one queue to one of 16384 slots, and a branded id hashes to a placement
(`placement("USR0KHTOWnGLuC") → 234878118`). Placement is computed from identity client-side, no registry —
the same property by a hash, not a bit-extract.

**Take.** Pinterest put the shard in the id and the data on the store that fit it; echo computes a slot from
the queue's hashtag and a placement from the branded id. Different mechanisms, one principle: identity carries
location, so a read never has to ask where a row lives.

## §5 · Notes on Valkey

Valkey divides the keyspace into **16384 hash slots**; a key's slot is `CRC16(key) mod 16384`, and a `{...}`
hashtag pins every key that shares the tag to the same slot. That is exactly what `EchoMQ.Keyspace` computes
client-side so a queue's keys co-locate and a multi-key Lua script stays legal. The algorithm and the hashtag
rule are the engine's own: [valkey.io/topics/cluster-spec](https://valkey.io/topics/cluster-spec/).

## References

### Sources

- [Pinterest Engineering — Sharding Pinterest: How we scaled our MySQL fleet](https://medium.com/pinterest-engineering/sharding-pinterest-how-we-scaled-our-mysql-fleet-3f341e96ca6f) — the polyglot split, the shard-in-the-id scheme, and the virtual-node move principle.
- [Valkey — Cluster specification](https://valkey.io/topics/cluster-spec/) — the 16384 hash slots, `CRC16 mod 16384`, and the `{...}` hashtag the BCS keyspace computes.
- [GitHub — pinterest/pinlater](https://github.com/pinterest/pinlater) — the async-job service whose queues are split across shards; the shard id rides in the job descriptor.

### Related in this course

- [R8.03 · Pinterest: task queues & partitioning](/redis-patterns/production-operations/pinterest-task-queue) — the module hub.
- [R8.03.2 · List-based reliable queues](/redis-patterns/production-operations/pinterest-task-queue/list-based-reliable-queues) — the next dive: never lose a job between claim and ack.
- [R8 · Production & Operations](/redis-patterns/production-operations) — the chapter.
- [/bcs/overview](/bcs/overview) — the branded id and how placement falls out of it.
- [/echomq/queue](/echomq/queue) — the Queue pillar: jobs, lanes, and the braced keyspace behind co-location.
