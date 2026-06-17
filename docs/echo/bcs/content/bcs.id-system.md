# BCS · Choosing the ID system — the key under Valkey's new hash table

<show-structure depth="2"/>

The Branded Component System sends exactly one kind of value across every boundary: an identity. Beneath every boundary it crosses sits a hash table, and in Valkey 8.1 that table was rebuilt from first principles — Viktor Söderqvist's open-addressing, cache-line-bucket design that retires the chained `dict` and, per its own publication, saves roughly 20 bytes per key-value pair, roughly 30 with a TTL [1]. This article does three things with that fact. It reads the design closely enough to predict what an identifier costs inside it; it measures seven key shapes through one million keys each on both the old table and the new; and it lets the numbers settle the question in the title — which ID system the BCS should standardize on, now that the store under EchoMQ rewards some shapes and taxes others.

Two architecture facts are recorded here as decisions of record. **EchoMQ is backed by Valkey, through a custom optimized connector in Elixir** — this supersedes the earlier second-engine target, and the series TOC is amended accordingly; the v2 protocol's load-bearing properties (the owned `emq:{q}:*` keyspace, hashtag slot locality, every Lua key declared) carry over unchanged, since they were never engine folklore but cluster-and-scripting discipline. And **EchoMQ 3.0 plans Streams enhancements with PubSub**, which is why this article measures stream *entry* IDs alongside plain keys: in a streams-shaped 3.0, the identifier lives inside a second data structure with its own economics.

## Scope and method

Two servers on one host, same allocator family: Redis 7.0.15 (the chained `dict`, Ubuntu build, jemalloc 5.3.0) as the before, and Valkey 9.1.0 with default jemalloc 5.3.0 as the after. Each measurement loads 1,000,000 keys of one shape with a constant 8-byte embstr value via a generated RESP pipe, polls `used_memory` until stable (incremental rehash settled), and reports the delta divided by `DBSIZE` — whole-table amortized bytes per key, which is the figure that includes the bucket arrays the design is about. The streams experiment loads 200,000 entries per stream and reads `MEMORY USAGE … SAMPLES 0`. Design claims cite the Valkey publication [1][2] and the 8.1.8 source in this repository's build (`src/object.c`); everything numeric is in the committed `valkey_id_bench.out` and `streams_bench.out`. This is a single-node memory study — cluster behavior and I/O threading are out of frame.

## The table under the keys

The retired `dict` is a chained table: a bucket array of pointers, each entry a separately allocated `dictEntry` holding three pointers (key, value, next), the key its own sds allocation, the value its own object — four memory reads to resolve one key, plus two more per collision hop, plus a second table during incremental rehash [1].

The 9.x design inverts the layout around the cache line. The table is an array of 64-byte buckets — one cache line each — holding up to seven entries apiece. One bucket byte carries a child-pointer flag and seven presence bits; the remaining seven metadata bytes hold a one-byte secondary hash per slot, built from the hash bits not spent addressing the bucket, so a lookup eliminates mismatched slots without touching their keys — a 1-in-256 false-positive rate, which the publication rounds to 99.6% of mismatches skipped for free [1]. The `dictEntry` is gone entirely: key and value embed in the `serverObject`, one allocation per entry, and a lookup is two memory reads — bucket, then object — with same-bucket collisions costing nothing further. Overflow chains to child buckets of the same shape, rare under a fair hash. The features that ruled out adopting Swiss tables wholesale — incremental rehash, the `SCAN` guarantee, random sampling — are kept by construction [1]. One more detail from the source matters to ID design: every key embeds regardless of length, and keys of 128 bytes or more pre-reserve an expire slot so a later TTL needs no reallocation (`KEY_SIZE_TO_INCLUDE_EXPIRE_THRESHOLD`, `object.c:47`); short keys take the expire field only when one is set.

## What an identifier costs, derived

Before measuring, the layouts predict the shape of the result. The old table charges each key a share of the bucket-pointer array, a 24-byte `dictEntry` plus its allocation overhead, a separate sds key allocation, and — with a TTL — a second `dictEntry` in the expires dict. The new table charges a share of 64 bytes across up to seven entries (≈9.1 bytes at occupancy) and one object that already contains the key, the value, and, when set, an inline 8-byte expire. Two consequences follow. First, the per-key saving should sit near the publication's ~20 bytes, rising toward ~30 when a TTL is involved [1]. Second — and this is the ID-system lever — jemalloc allocates in discrete size classes (16-byte steps in this range), so key length stops mattering *within* a class and matters sharply *at its edges*: an identifier's storage cost is a staircase, and the design question is which step each ID format stands on.

## Measured

```text
fmt        keylen   redis7   valkey8.1   saved      (bytes per key, 1M keys)
brd14        14       88        65         23       IMG + base62, the contract form
u64dec       19      104        73         31       the same snowflake, decimal text
uuid36       36      120        97         23       canonical UUID string
uuid16       16      104        65         39       UUID raw bytes
ulid26       26      104        81         23       ULID, Crockford base32
emq26        26      104        81         23       emq:{q}:job: + branded
brd14+ttl    14      128        99         29       branded with EX 86400
```

The publication's claims reproduce on keys this project mints: 23–39 bytes saved per key, 29 on the TTL row — the user-visible "20–30 bytes" of the 8.1 release, validated here rather than quoted [1][2]. The ID findings sit inside the columns:

**The branded form ties raw binary.** On Valkey, the 14-byte branded id costs 65 bytes — the same as a 16-byte *binary* UUID — while remaining a printable, typed, ordered string. The usual argument for binary keys (storage) is gone on this table; the staircase put both shapes on one step.

**Branding beats its own integer.** The same snowflake rendered as decimal text (19 digits) costs 73 bytes — eight more than its branded base62 form. The namespace plus the denser alphabet is not a tax over the raw id; at the storage layer it is a discount. The contract's wire form is cheaper than the "lean" alternative it is usually defended against.

**Canonical UUID strings pay a full class.** 36-character UUIDs cost 97 bytes against branded's 65 — +32 per key, two size-class steps. At one hundred million keys that difference alone is 3.2 GB of resident memory, before any replica multiplies it.

**The queue envelope costs one step.** The realistic EchoMQ job key — `emq:{q}:job:` plus the branded id, 26 bytes — lands at 81, one 16-byte class above the bare id and exactly even with ULID's 26 characters: at this layer length is destiny and charset is free. The operational rule falls out directly: every byte of queue name rides on every key of that queue, so the hashtag-and-prefix budget deserves the same scrutiny as a schema.

## Choosing the ID system for the BCS

The BCS requirements, fixed by the preface and the contract: the type discriminant must live in the value and in the type system; string order must equal mint order; a placement hash must be a pure function of the id; the form must be one fixed-width printable token; and the whole must be conformant across the BEAM, Node, Go, and wasm. Against those, the measured and structural facts per candidate:

| Candidate | Valkey B/key | Time-ordered | Type tag | Placement fn | Coordination |
| --- | --- | --- | --- | --- | --- |
| serial integer | ~57–65 | insertion only | none | none | central sequence |
| UUIDv4 (hex 36) | 97 | no | none | none | none |
| UUIDv7 (hex 36) | 97 | yes | none | none | none |
| UUID (binary 16) | 65 | v7 only | none | none | none |
| ULID (26) | 81 | yes | none | none | none |
| snowflake, decimal | 73 | yes | none | by convention | node id |
| **branded snowflake (14)** | **65** | **yes, lexicographic** | **3-byte namespace** | **hash32, in-contract** | **node id** |

UUIDv7 is the strongest outside candidate — time-ordered without node coordination — but its canonical string stands two classes up the staircase, its binary form surrenders readability and grep-ability, and in either form there is no namespace and no placement contract: the wrong-table join compiles, and partition routing becomes a per-system convention. ULID matches branded on the staircase logic but carries the same two absences. KSUID and NanoID inherit the same analysis at 27 and 21 characters respectively. The serial integer minimizes bytes and maximizes coupling — a central sequence is the one coordination cost BCS refuses by design. The branded snowflake is the only row with every column filled, and the measurement removed the last argument against it: it is also the cheapest printable form on the new table, cheaper than its own undecorated integer. The decision stands as the contract already states it; this article's contribution is that the storage layer now agrees.

## The 3.0 horizon: streams

Stream entry IDs are two 64-bit numbers — a Unix-millisecond timestamp and a sequence for entries inside the same millisecond — and because the ID carries time, range queries over time come from the ID itself [3]. The server enforces the same monotonic law the contract's minter does: an explicit ID must exceed the stream's current top entry, and a backward clock is absorbed by reusing the top time and incrementing the sequence [4]. A branded snowflake therefore maps onto a stream ID by an order-preserving injection that is two shifts:

```text
stream_id(snow) = unix_ms(snow) "-" (snow AND 0x3FFFFF)
```

— the mint instant as the milliseconds part, the node-and-sequence low 22 bits as the sequence part. Lexicographic order on the pairs equals numeric order on the snowflakes, so `min_for`, the synthetic cursor, becomes a stream cursor for free. Measured on Valkey 9.1.0 with 200,000 entries per stream:

```text
s_auto  (XADD *)                 20 bytes/entry
s_brd   (explicit branded ids)   20 bytes/entry
window [+10ms, +20ms)            40960 entries returned, 40960 expected
first id in window               1781000000010-28672   (node 7 << 12 | seq 0)
```

Carrying the contract into the entry ID costs nothing — the explicit stream is 13 KB *smaller* than the auto-ID stream at 200k entries, delta encoding being indifferent to the larger-but-regular sequence values — and buys exact time-window reads addressed by the same arithmetic every runtime already implements. For an EchoMQ 3.0 built on Streams with PubSub, that means a job's queue key, its stream entry, its ack in a consumer group, and its cache key are one identifier in four positions, and a replay window is one `min_for` at each end.

## What this buys EchoMQtoday

The connector is Elixir's and the keyspace is owned, so the economics compose directly: one million in-flight job keys in the `emq:{q}:job:` shape cost 81 MB on the 8.1 table against 104 MB on the table Redis 7 still runs — 23 MB per million keys per node returned by the engine swap alone, before the protocol does anything clever. The guidance the staircase adds to the v2 conventions: keep queue names inside the prefix budget (the branded payload should be the long part of the key), prefer the 14-byte form over any decimal rendering in every key and field, and treat a TTL as 34 bytes of object growth on this table rather than a second table's entry. The 9.x line is already extending the same structure — SIMD lookups and batch prefetching land on top of these buckets — so the staircase is the durable model, not a release note.

## Boundaries

Single node, one allocator: the class edges are jemalloc-5.3.0's and shift under a different malloc. `used_memory` deltas include table and allocator effects by design; per-object `MEMORY USAGE` accounting differs across the two engines and was deliberately not the metric. UUIDv4 and v7 are storage-identical — the column difference is order, not bytes. The streams comparison ran on Valkey only, and the 22-bit sequence mapping assumes the contract's minter; foreign snowflake layouts need their own injection. Nothing here measures cluster mode: hashtag locality is a correctness-and-routing property, argued in the protocol documents, not a number in this file.

## Companion files

`bench/valkey-id/` — `gen_resp.py`, `valkey_id_bench.out`, `streams_bench.out` — in the `echo_data` package; the Valkey 9.1.0 build tree at `/tmp/valkey-src` reproduces with `make`.

## References

1. Söderqvist, V. — A new hash table. Valkey project, technical deep dive, 2025-03-28: [valkey.io/blog/new-hash-table](https://valkey.io/blog/new-hash-table/)
2. Valkey 8.1.0 GA announcement — the release the hash table shipped in: [valkey.io/blog/valkey-8-1-0-ga](https://valkey.io/blog/valkey-8-1-0-ga/)
3. Valkey documentation — Streams introduction (entry-ID structure; time ranges from the ID): [valkey.io/topics/streams-intro](https://valkey.io/topics/streams-intro/)
4. Valkey command reference — XADD (explicit IDs, total order, the monotonic top-ID rule): [valkey.io/commands/xadd](https://valkey.io/commands/xadd/)
