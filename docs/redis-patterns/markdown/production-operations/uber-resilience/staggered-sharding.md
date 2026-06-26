# Staggered sharding

> R8.05.1 · Uber: resilience & staggered sharding — dive 1 · route `/redis-patterns/production-operations/uber-resilience/staggered-sharding`

Uber sharded its Redis cache using a scheme **deliberately different** from the Docstore database sharding
scheme, so that when a single Redis cluster goes down, its missed traffic spreads **across multiple database
shards** instead of concentrating on one. Misaligning the two sharding schemes is what turns a correlated failure
into a spread one — no hot shard.

Grounding: the Uber case study (*How Uber Uses Integrated Redis Cache*) for the sharding scheme; the BCS echo —
the `{q}` hashtag and CRC16 slot from R8.03, not re-derived here. Valkey is the BCS engine; Uber's Redis and
Docstore are the case study.

## §1 · The aligned-sharding trap

Put a cache in front of a database and the cache absorbs the read load. The question staggered sharding answers
is: *when a piece of the cache fails, where does its load go?*

The naive design shards the cache the same way the database is sharded. It feels clean — Redis cluster *k* fronts
Docstore shard *k*, the mapping is one to one, a key's cache home and its database home are found the same way.
The problem appears only on failure. If Redis cluster *k* goes down, every read that would have hit it now misses
and falls through to Docstore — and because the sharding is aligned, all of that traffic lands on the **one**
Docstore shard *k* that backed it. That shard now carries its own normal load plus the entire missed load of the
cache cluster in front of it. It becomes a **hot shard**: an overloaded database shard, a correlated failure that
can take the database shard down too, which makes more of the cache miss, which piles more onto the shard.

Aligned sharding makes the cache and the database fail *together*, one region of the keyspace at a time.

## §2 · Misalign the schemes

Uber's design refuses the alignment. The Redis cluster is sharded by a scheme **different** from the database's,
so the set of keys held by one Redis cluster does **not** correspond to the set of keys on one database shard.
When a Redis cluster goes down, the keys it held are scattered — by the database's own scheme — across **many**
database shards. The missed load fans out instead of concentrating. No single Docstore shard inherits the whole
failure; each absorbs a fraction it can carry.

The principle is general: **decorrelate the failure domains.** A cache cluster and a database shard are two
failure domains; if their boundaries line up, a failure in one maps directly onto a failure in the other. Stagger
the boundaries — make the two sharding functions independent — and a failure in one domain disperses across the
other instead of striking a single matching unit. The cost is that a cache cluster and a database shard no longer
share a tidy one-to-one map, which is exactly the property that disperses the load.

## §3 · The BCS echo — placement is the hashtag

The BCS bus places keys with a scheme too, and it is worth being precise about what that scheme is and is not.

EchoMQ pins a queue's keys to one Valkey hash slot with a **hashtag**. Every key of a queue is built as
`emq:{q}:<type>` — the queue name sits inside the braces — and Valkey hashes a key only over the substring
between the first `{` and `}`. So every `emq:{orders}:*` key hashes to the same slot, one of 16384, decided by
the queue name. `EchoMQ.Keyspace` computes the slot client-side as `slot/1 = rem(crc16(hashtag(key), 0), 16384)`
— the cluster-spec algorithm. The full derivation is R8.03; this dive reuses the result, it does not re-derive
it.

The connection to staggered sharding is a contrast, not an equivalence:

- **Uber decorrelates two schemes** — the cache's sharding and the database's sharding are deliberately
  *different*, so a cache failure disperses across database shards.
- **EchoMQ correlates one scheme on purpose** — a queue's keys are deliberately pinned to *one* slot by the `{q}`
  hashtag, so a multi-key Lua script over one queue is always a single-slot operation (no CROSSSLOT) and the
  queue's state is co-located.

Both are deliberate placement decisions made by the sharding function — one chosen to *spread* (Uber, for failure
isolation across two stores), one chosen to *gather* (EchoMQ, for atomic multi-key scripts within one queue). The
shared lesson is that placement is a design choice the sharding scheme encodes, not an accident: decide where
keys land, and decide it for the failure and consistency properties you want.

### Notes on Valkey

Valkey divides the keyspace into 16384 hash slots; a key's slot is `CRC16(key) mod 16384`, and a `{...}` hashtag
pins every key sharing the tag to the same slot. That co-location is what keeps a multi-key Lua script over one
queue legal — every key lands on one slot, so there is no CROSSSLOT error. The algorithm and the hashtag rule are
the engine's own — [valkey.io/topics/cluster-spec](https://valkey.io/topics/cluster-spec/).

## Recap — placement is a design choice

Staggered sharding is one move with a clear root: do not let the cache's failure domains line up with the
database's. Shard the cache by a different scheme, and a cache cluster's failure disperses across many database
shards instead of striking one as a hot shard. The BCS bus makes the opposite placement choice with the same kind
of deliberateness — the `{q}` hashtag gathers a queue's keys onto one slot for atomic scripts. The next dive
stops the bus from hammering a node that is failing: the sliding-window circuit breaker, and the connector's
backpressure cousin.

## References

### Sources

- [Uber Engineering — How Uber Serves Over 40 Million Reads Per Second Using an Integrated Cache](https://www.uber.com/blog/how-uber-serves-over-40-million-reads-per-second-using-an-integrated-cache/)
- [ByteByteGo — How Uber Uses Integrated Redis Cache to Serve 40M Reads/Second](https://blog.bytebytego.com/p/how-uber-uses-integrated-redis-cache)
  — the staggered sharding scheme: misaligning the Redis and database sharding so a cache cluster's failure
  spreads across many database shards instead of creating a hot shard.
- [Valkey — Cluster specification](https://valkey.io/topics/cluster-spec/) — the 16384 hash slots, `CRC16 mod
  16384`, and the `{...}` hashtag the BCS keyspace computes to co-locate a queue.

### Related in this course

- [R8.05 · Uber: resilience & staggered sharding](/redis-patterns/production-operations/uber-resilience) — the module hub.
- [R8.05.2 · Circuit breakers](/redis-patterns/production-operations/uber-resilience/circuit-breakers) — the next dive: stop hammering a sick node.
- [R8.03 · Pinterest: task queues & partitioning](/redis-patterns/production-operations/pinterest-task-queue) — the `{q}` hashtag and CRC16 slot derived in full.
- [R8 · Production & Operations](/redis-patterns/production-operations) — the chapter.
- [/echomq/queue](/echomq/queue) — the Queue pillar: the braced keyspace behind co-location.
