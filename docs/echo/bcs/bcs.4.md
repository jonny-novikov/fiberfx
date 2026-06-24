# BCS · B4 — EchoStore
<show-structure depth="2"/>

B4 is EchoStore: the declared near-cache of Part IV — L1 ETS tables in front of the L2 Valkey systems already share. Three dives carry it — the declared cache and its two tiers, the cache-aside read path with its single fill per herd, and coherence by mint-time version. The chapter is served at `/bcs/store`; its dives at `/bcs/store/the-near-cache`, `/bcs/store/one-fill-per-herd`, and `/bcs/store/coherence`.

EchoStore is Part IV: the declared near-cache. L1 ETS tables sit in front of the L2 Valkey systems already share, and the cache is declared, not discovered — every table registers its kind, its TTL, and its coherence mode in a directory, and a cache absent from the directory does not exist. A read is a caller-side lookup that never enters the owning process; a miss is one fill per herd, coalesced onto a single flight; expiry is jittered so no cohort dies together; and coherence travels as a two-identity message — the name and the writer's mint-time version — over a broadcast lane and a job lane. The durable floor beneath it, the Graft engine, is B5.

Every surface here is real source under `echo_store`. EchoStore is the cache; the durable Graft engine beneath it — and the stream archive that folds trimmed `EchoMQ.Stream` segments into it — is the persistence floor of B5. No engine number is cited that the committed tree does not assert.

## B4.1 · The declared near-cache

Part IV adds a cache, and its first law is that the cache is declared, not discovered. `EchoStore` is the near-cache layer: L1 ETS tables in front of the L2 Valkey that systems already share. Every table registers its full specification in a directory at start; an operator enumerates every cache on the node with `tables/0`; and a cache absent from the directory does not exist. There is no ambient, accidental cache — only declared ones, each with a kind, a TTL, and a coherence mode written down.

The two tiers divide by reach. L1 is an in-process ETS table, public and read-concurrent, local to one node; L2 is the shared Valkey the bus already runs on, addressed through the cache's own keyspace, `ecc:{table}:id` — a fresh prefix beside `emq:`, the table name hashtagged so every key of one cache lands on one slot when clustering arrives. The id in the key's value position is checked for shape before any key is composed, so a malformed name never reaches the wire.

The directory is alive. It monitors each table it registers, so a crashed cache leaves the roster the moment it leaves the node, and the enumeration is never stale. A cache, in BCS, is a declared component with a boundary and an owner, registered and watched — not a map someone reached for. It is the discipline the law applies to systems, applied to the things that make them fast.

## B4.2 · One fill per herd

The read path never enters the owning process. A hit is a caller-side `:ets.lookup` against the public L1 table, so reads cost nothing but the lookup and scale with schedulers, not with one GenServer's mailbox. The owner is consulted only on a miss, and that is where the second law holds: one fill per herd. Concurrent misses on the same key coalesce onto a single in-flight load — the first caller's flight checks L2, falls through to the declared loader, writes both layers, and every waiter reads that one answer.

Expiry is deliberately uneven. Rows expire on a jittered clock, `ttl` plus or minus `ttl` times a jitter fraction, so a cohort filled together never expires together and a herd never forms at the second boundary; a sweeper reclaims dead rows on a fixed tick, so memory is bounded by the declaration rather than by luck. The cache's footprint is what its tables declared, held to by a clock, not an accident of traffic.

A full cache degrades, it does not fail. When the table is at capacity and nothing has expired, a fill still serves its caller and skips the insert: the cache becomes a pass-through, answering from L2 and the loader without caching the result, never refusing a read. And the kind law runs before either layer is touched — a wrong-namespace id is refused at the door, the series' oldest rule riding into the cache unchanged.

## B4.3 · Coherence

When a row is written, the caches holding it must learn. An EchoStore coherence message carries exactly two identities — the cached name and the writer's mint-time version — and nothing else. Newer wins by comparing the eleven snowflake bytes of the two branded ids: the order theorem makes those bytes lexicographically equal to mint order, regardless of namespace, so coherence needs no coordinator, no lock, and no clock but the one already inside every id. Application is idempotent — applying the same version twice answers stale the second time, so a retry or a duplicate changes nothing.

Two lanes carry that message, chosen by what a stale read costs. The broadcast lane is a `PUBLISH` on the table's channel — fire-and-forget, one wire hop, at-most-once — for surfaces where a lost message costs one TTL of staleness. The job lane is an enqueue on the table's coherence queue over EchoMQ — at-least-once and crash-surviving — for surfaces where a stale read costs money. The same drop runs in Lua on the bus, comparing the same eleven bytes, so the wire and the heap never disagree about which write is current.

The broadcast lane is served by a ring. `EchoStore.Ring` is the Disruptor's shape on the BEAM: two atomics for head and tail sequences, an ETS table of preallocated slots reused by index, a single producer and a single applier, and edge-triggered wakes — one message when the ring goes from empty to non-empty, however many items then flow. When the ring is full the publish is refused and counted, never blocked and never overwritten, because the broadcast lane is at-most-once by its substrate's contract and a counted drop preserves that where silent overwriting would not. Surfaces that cannot accept a drop ride the job lane, which does not pass through here.

## References

- [Erlang/OTP — the ets module](https://www.erlang.org/doc/apps/stdlib/ets.html) — the public read-concurrent L1 table a hit reads directly.
- [Valkey — Cluster specification](https://valkey.io/topics/cluster-spec/) — the hash tag that lands one cache's ecc: keys on one slot.
- [Helland — Life Beyond Distributed Transactions (CIDR 2007)](https://ics.uci.edu/~cs223/papers/cidr07p15.pdf) — the entity addressed by a key, cached close to its use.
- [Söderqvist — A new hash table (Valkey, 2025)](https://valkey.io/blog/new-hash-table/) — the L2 the near-cache fronts, costed at rest.
- [King — Announcing Snowflake (2010)](https://blog.twitter.com/engineering/en_us/a/2010/announcing-snowflake) — the time-high id whose eleven payload bytes decide which write is newer.
- [DeCandia et al. — Dynamo (SOSP 2007)](https://www.allthingsdistributed.com/files/amazon-dynamo-sosp2007.pdf) — last-writer-wins by version, here a monotone mint-time id.
- [Thompson et al. — The LMAX Disruptor (2011)](https://lmax-exchange.github.io/disruptor/disruptor.html) — the single-writer pre-allocated ring the broadcast applier mirrors.
