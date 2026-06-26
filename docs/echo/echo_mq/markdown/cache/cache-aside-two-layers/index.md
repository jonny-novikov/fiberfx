# Cache-aside, two layers

**Module 01 of the Cache pillar · `/echomq/cache/cache-aside-two-layers`**

The Cache is pillar III: an L1 ETS table in front of the L2 Valkey the bus already runs on, read
cache-aside. A hit is a caller-side `:ets.lookup` — it never enters the owning process. A miss falls
through to L2, then to a declared loader. Every value is framed with its writer's mint-time version, the
seed of the coherence that keeps the caches honest.

This module frames the declared near-cache: the directory that says what exists, the two tiers (ETS and
Valkey) and their keyspace, the read path from hit through fill, and the write that frames a value with its
version. Module 02 picks up single-flight and jittered TTL — the mechanisms that keep the read cheap under
a herd and bounded under pressure.

## The two laws of this module

**The cache is declared, not discovered.** Every table registers its full spec in
`EchoStore.Directory` at start. An operator reads `EchoStore.tables/0` to see every live cache.
A cache absent from the directory does not exist — there is no discovery, no scanning, no inference.
The directory monitors each owner, so a `:DOWN` drops the row the moment the cache leaves the node.

**Every value is framed with its mint-time version.** `put/3` mints a branded id of the table's kind
as the version; `put/4` carries the writer's own. The L2 frame is `version <> value` — a 14-byte branded
id prepended to the binary. A read that hits L2 splits the frame (`<<version::binary-14, value::binary>>`)
and restores both. The version is the hook coherence (module 03) will use: newer wins.

## The two tiers

**L1 — a public, read-concurrent ETS table.** Created with
`:ets.new(name, [:set, :public, :named_table, read_concurrency: true])`. Reads happen in the caller's
process — no GenServer round-trip on a hit, no mailbox bottleneck. Rows are `{id, value, expires_at,
version}`.

**L2 — the shared Valkey.** Addressed through `EchoStore.Keyspace.key/2` → `"ecc:{" <> table <> "}:" <>
id`. A fresh prefix beside `emq:`, never inside it. The `{table}` hashtag means every key of one cache
lands on one of 16384 Valkey Cluster slots — one multi-key script stays legal (no CROSSSLOT) and co-located
when clustering arrives. The Valkey Cluster specification governs the CRC16 slot assignment.

## The three dives

1. **Declared, not discovered** — the directory, the two tiers, the keyspace.
2. **The cache-aside read** — `fetch/3`, the kind gate, the three sources.
3. **Writing both layers** — `put/3`, `put/4`, `invalidate/3`, the framed value.

## References

### Sources
- Erlang/OTP — the ets module: https://www.erlang.org/doc/apps/stdlib/ets.html
- Valkey — Cluster specification: https://valkey.io/topics/cluster-spec/
- Valkey — GET command: https://valkey.io/commands/get/
- Valkey — SET command: https://valkey.io/commands/set/
- Valkey — DEL command: https://valkey.io/commands/del/
- Helland — Life Beyond Distributed Transactions: https://ics.uci.edu/~cs223/papers/cidr07p15.pdf
- Söderqvist — A new hash table (Valkey, 2025): https://valkey.io/blog/new-hash-table/
- King — Announcing Snowflake (2010): https://blog.twitter.com/engineering/en_us/a/2010/announcing-snowflake

### Related in this course
- `/echomq/cache` — the Cache chapter landing
- `/echomq/protocol` — the keyspace and branded-id gate the `ecc:` prefix stands beside
- `/echomq/queue` — the Queue, the other pillar over the same wire
- `/echomq/bus` — the Bus, the broadcast tier
- `/bcs/store` — the BCS manuscript chapter this module realizes
