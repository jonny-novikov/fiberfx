# R7.02 · Memory optimization

> Route: `/redis-patterns/data-modeling/memory-optimization` · module hub · the source-of-record markdown the HTML mirrors.

Reduce Redis memory consumption by leveraging compact encodings (listpack, intset), using Hashes for small object storage, and choosing memory-efficient data structures.

Redis stores everything in memory, so efficient memory usage is critical. Understanding the engine's internal encoding optimizations enables significant savings — often a 50–80% reduction for small objects. The grounding here is EchoMQ's memory discipline (`echo/apps/echo_mq`): its job HASH stays a listpack, its wake list is `LTRIM`-capped at 64, its streams are `XTRIM … MAXLEN ~`-capped — the structures are bounded by design, not by tuning after the fact.

## §1 · Small object encoding

Redis automatically uses compact encodings for small collections. A Hash with few fields is stored as a **listpack** — a single sequential byte array — rather than a hash table. The listpack eliminates the per-entry pointer and bucket overhead, which can consume up to 80% of memory for small objects.

The engine switches from the compact encoding to the standard one when a structure crosses a configured threshold. The defaults:

```
hash-max-listpack-entries 512
hash-max-listpack-value 64
list-max-listpack-size -2
zset-max-listpack-entries 128
zset-max-listpack-value 64
set-max-intset-entries 512
```

A Hash with fewer than 512 entries, where each value is under 64 bytes, uses the memory-efficient listpack encoding. An all-integer Set under 512 members uses the even tighter **intset** — a sorted array of fixed-width integers, no hashing at all.

**Applied.** EchoMQ's job HASH carries exactly three fields — `state`, `attempts`, `payload` (`echo/apps/echo_mq/lib/echo_mq/jobs.ex`). Three is far under 512; the values are short; so Valkey stores the row as a listpack — not because EchoMQ tuned the thresholds (the committed `infra/valkey/conf/valkey.conf` sets no encoding thresholds), but because the row is deliberately minimal.

## §2 · The bucketing pattern

Each individual key has overhead — memory for the key name, the expiration metadata, and internal bookkeeping. For millions of small values, that per-key overhead dominates the values themselves.

Instead of storing each item as a separate String key:

```
SET user:1:name "John"
SET user:2:name "Jane"
... (1 million keys)
```

group items into Hash buckets:

```
HSET users:0 "1:name" "John"
HSET users:0 "2:name" "Jane"
...
HSET users:1 "1001:name" "Alice"
```

With 1000 items per bucket you have 1000 Hash keys instead of 1 million String keys. Each Hash stays small enough for the compact encoding, and the per-key overhead is paid for 1000 keys, not 1,000,000. For item ID 12345 with bucket size 1000: `bucket_number = 12345 / 1000 = 12`, `key = "users:12"`, `field = "12345:name"`.

## §3 · Key name length

Every byte in a key name consumes memory, and a key's name is stored on every key. At scale, short keys matter. Instead of `user:profile:12345:display_name`, consider `u:12345:dn` — or, better, use a Hash so the prefix is stored once rather than repeated per field: `HGET u:12345 dn`.

**Applied.** EchoMQ names its job-HASH fields `state`, `attempts`, `payload` — short, but **not abbreviated to noise**. Readability and byte-tightness pull against each other, and three short, whole words are already small enough to keep the value under `hash-max-listpack-value`. The win is the encoding, not a cryptic schema. (The `short-field-names` dive carves this slice.)

## §4 · Integer encoding

Redis automatically uses an integer encoding for numeric strings, and these values share a pool of pre-allocated small integers:

```
SET counter "42"        # efficient integer encoding
SET counter "42 items"  # string encoding, more memory
```

When a value can be a pure number, store it as one. EchoMQ's `attempts` field holds the bare integer fence advanced by `HINCRBY` — a pure number, never `"3 tries"` — so it benefits from the integer encoding.

## §5 · Expiration overhead

Every key with a TTL needs additional memory to store the expiration time. For millions of keys with individual TTLs, that adds up. If many keys should expire together, consider grouping them in a Hash under a single TTL on the Hash key rather than a TTL on every entry. EchoMQ's job rows carry no TTL — a job lives until it is completed or reaped, so there is no per-key expiration cost on the hot path.

## §6 · Analyzing memory usage

Measure before optimizing. Overall memory: `INFO memory`. A specific key: `MEMORY USAGE user:12345`. Sampled statistics: `MEMORY STATS`. A health report (use with caution in production): `MEMORY DOCTOR`. The discipline is the same as everywhere: measure, change the lowest-effort technique, measure again.

## §7 · Eviction policies

When memory is exhausted, the `maxmemory-policy` setting determines what happens. The cache policies (`allkeys-lru`, `allkeys-lfu`, `volatile-ttl`, `allkeys-random`, …) **delete keys** to keep serving; `noeviction` **returns errors on writes** instead. For a cache, an LRU or LFU policy makes sense. For data that must not be lost, `noeviction` is the only safe posture — and EchoMQ runs it, because the job HASH is the record of truth.

This is the same posture taught in depth in R7.1. → **[R7.01.2 · noeviction](/redis-patterns/data-modeling/primary-database/noeviction)** carves it; this module presents it only as one of the memory techniques and does not re-teach it.

## §8 · Compression

For large string values, compress before storing: compress in the application (gzip, lz4, snappy), store the compressed bytes, decompress on read. This trades CPU for memory and is effective for values over a few hundred bytes where the compression ratio is meaningful. EchoMQ does not compress the small job payload — the win is not there at three short fields — but a large opaque body is a candidate.

## §9 · Summary of techniques

| Technique | Impact | Effort |
|---|---|---|
| Bucketing | 5–10x reduction | Moderate |
| Short key names | 10–30% reduction | Low |
| Integer encoding | Variable | Low |
| Expiration grouping | 10–20% reduction | Moderate |
| Compression | 50–90% reduction | Higher |
| Choosing the right data type | Variable | Low |
| Capped structures (`LTRIM`, `MAXLEN ~`) | Bounds memory absolutely | Low |

Start with the low-effort techniques and measure. Bucketing offers the largest gains for datasets with millions of small items; capped structures are the cheapest way to guarantee a structure cannot leak.

## The bridge — pattern → application

**Pattern.** Compact encodings and small objects save 50–80% of memory; a structure that is bounded cannot leak it.

**EchoMQ application.** The three-field job HASH stays a **listpack** (far under the 512-entry / 64-byte thresholds); the per-group **wake list** is `LTRIM`-capped at 64 (`lanes.ex`); the **streams** are `XTRIM … MAXLEN ~`-capped (`stream.ex`). The memory ceiling is a property of the design, not a tuning knob turned later.

**Take.** Memory optimization in Redis is mostly choosing the right structure small enough to stay in the compact encoding, and bounding the ones that grow. EchoMQ does both by construction: a deliberately minimal row, and lists and streams that are capped where they are written.

## The three dives

- **[listpack-and-intset](/redis-patterns/data-modeling/memory-optimization/listpack-and-intset)** — small-object encoding and integer encoding: a small Hash becomes a listpack, a small all-integer Set becomes an intset; the thresholds; the 3-field job HASH as the worked example; what crossing a threshold does.
- **[short-field-names](/redis-patterns/data-modeling/memory-optimization/short-field-names)** — key and field name length: few, short fields keep the value under `hash-max-listpack-value` and the row in the compact encoding; EchoMQ's `state`/`attempts`/`payload` (short, not abbreviated); the readable-vs-byte-tight trade, multiplied by N rows.
- **[capped-structures](/redis-patterns/data-modeling/memory-optimization/capped-structures)** — bound a structure so it cannot leak: `LTRIM list 0 N` (the wake list at 64) and `XTRIM … MAXLEN ~` (the stream); the `~` accuracy-for-speed trade.

## References

### Sources

- [Valkey — Memory optimization](https://valkey.io/topics/memory-optimization/) — listpack and intset encodings, the configuration thresholds, and how Redis stores small collections compactly.
- [Valkey — LTRIM](https://valkey.io/commands/ltrim/) — trim a List to a range so it becomes a bounded ring; the wake-list cap.
- [Valkey — XADD](https://valkey.io/commands/xadd/) — append to a stream with `MAXLEN ~`, the approximate cap that trims in whole macro-nodes.
- [Valkey — OBJECT ENCODING](https://valkey.io/commands/object-encoding/) — read the internal encoding of a key (`listpack`, `intset`, `hashtable`).
- [DoorDash Engineering — Redis memory at scale](https://careersatdoordash.com/blog/) — the listpack-Hash memory technique measured in production.

### Related in this course

- [R7.02.1 · listpack-and-intset](/redis-patterns/data-modeling/memory-optimization/listpack-and-intset) — the compact encodings and the threshold flip.
- [R7.02.2 · short-field-names](/redis-patterns/data-modeling/memory-optimization/short-field-names) — few short fields keep the row compact.
- [R7.02.3 · capped-structures](/redis-patterns/data-modeling/memory-optimization/capped-structures) — `LTRIM` and `MAXLEN ~` bound memory.
- [R7.01.2 · noeviction](/redis-patterns/data-modeling/primary-database/noeviction) — the eviction-policy posture for a record of truth.
- [/bcs · The store](/bcs/store) — EchoStore, the compact near-cache tier.
- [/bcs · Production on Fly](/bcs/fly) — the `maxmemory 512mb` guardrail in the committed config.
