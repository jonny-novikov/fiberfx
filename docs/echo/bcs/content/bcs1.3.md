# BCS · Chapter 1.3 — Choosing the ID system: the key under Valkey's new hash table

<show-structure depth="2"/>

The Branded Component System sends exactly one kind of value across every boundary, and beneath every boundary that value lands as a key in a hash table. Valkey 8.1 rebuilt that table from first principles — Viktor Söderqvist's open-addressing, cache-line-bucket design [1] — and changed what an identifier costs at rest. This chapter settles the chooser question on that ground: which ID system the BCS standardizes on, decided by measurement rather than taste, with seven key shapes pushed through a million keys each on the old table and the new. The spec of record for the keyspace rules that fall out is [`bcs1.3.specs.md`](bcs1.3.specs.md); the agent guide for applying them is [`bcs1.3.llms.md`](bcs1.3.llms.md); every figure below is verbatim from the committed outputs under `bench/valkey-id/`.

## Why

Two decisions of record frame the question (recorded in [`bcs.progress.md`](bcs.progress.md)). EchoMQ 2.0 is backed by Valkey through a custom optimized Elixir connector — so the engine under the bus is the engine whose economics matter. And EchoMQ 3.0 plans Streams with PubSub — so the identifier's cost inside a *second* data structure, the stream entry, is first-class now rather than later. Between them sits the trading registry: every `AST`, `TXN`, `PRT`, `ORD`, `RSK`, and `STR` identity this series mints will live as keys, fields, and entries in this store, multiplied by every replica. A chooser settled by folklore would be a tax on all of it; this one is settled by the table.

## What

**The table under the keys.** The retired `dict` was a chained table: a bucket array of pointers, each entry a separately allocated `dictEntry` of three pointers, the key its own allocation — four memory reads to resolve one key, plus two per collision hop, plus a second table during rehash [1]. The 8.1 design inverts the layout around the cache line: buckets of 64 bytes holding up to seven entries, an 8-byte metadata section — one child-pointer bit, seven presence bits, and seven one-byte secondary hashes built from the bits not spent addressing the bucket, so mismatched slots are skipped without touching their keys at a 1-in-256 false-positive rate [1]. The `dictEntry` is gone; key and value embed in the `serverObject`, one allocation per entry, two memory reads per lookup. Incremental rehash, the `SCAN` guarantee, and random sampling — the features that ruled out adopting Swiss tables wholesale — are kept by construction [1]. One source detail matters to ID design: every key embeds regardless of length, and keys of 128 bytes or more pre-reserve an expire slot (`KEY_SIZE_TO_INCLUDE_EXPIRE_THRESHOLD`, `object.c:47` in the 8.1.8 tree this chapter built).

**What an identifier costs, derived.** The old table charges a bucket-pointer share, a 24-byte `dictEntry` plus allocation overhead, a separate key allocation, and — with a TTL — a second entry in the expires dict. The new table charges a share of 64 bytes across up to seven entries (≈9.1 bytes) and one object that already contains key, value, and, when set, an inline 8-byte expire; the publication's headline is roughly 20 bytes saved per pair, roughly 30 with a TTL [1][2]. And jemalloc allocates in 16-byte classes in this range, so key length stops mattering within a class and matters sharply at its edges: an identifier's storage cost is a staircase, and the design question is which step each format stands on.

**Measured.** Redis 7.0.15 against Valkey 9.1.0, both jemalloc 5.3.0, one million keys per shape, constant 8-byte value, `used_memory` delta per key after settle:

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

The publication's claims reproduce on this project's own keys — 23 to 39 bytes saved, 29 on the TTL row [1][2] — and the ID findings sit inside the columns. **The branded form ties raw binary:** 65 bytes against binary UUID-16's 65, while staying printable, typed, and ordered; the storage argument for binary keys is gone. **Branding beats its own integer:** the same snowflake as 19 decimal digits costs 73 — the namespace plus the denser alphabet is a discount, not a tax, and Appendix 1.1 ([`bcs1.a1.md`](bcs1.a1.md)) extends the same verdict to CPU in the compiled runtimes. **Canonical UUID strings pay two classes:** 97 against 65, 32 bytes a key, 3.2 GB per hundred million keys before replication. **The envelope costs one step:** the realistic 26-byte `emq:{q}:job:` key lands at 81, even with ULID's 26 characters — at this layer length is destiny and charset is free, so the prefix budget is a design surface (INV-K2 in the spec).

**The chooser.** Against the BCS requirements — discriminant in the value and the type, lexicographic mint order, in-contract placement, fixed printable width, cross-runtime canon:

| Candidate | Valkey B/key | Time-ordered | Type tag | Placement fn | Coordination |
| --- | --- | --- | --- | --- | --- |
| serial integer | ~57–65 | insertion only | none | none | central sequence |
| UUIDv4 (hex 36) | 97 | no | none | none | none |
| UUIDv7 (hex 36) | 97 | yes | none | none | none |
| UUID (binary 16) | 65 | v7 only | none | none | none |
| ULID (26) | 81 | yes | none | none | none |
| snowflake, decimal | 73 | yes | none | by convention | node id |
| **branded snowflake (14)** | **65** | **yes, lexicographic** | **3-byte namespace** | **hash32, in-contract** | **node id** |

UUIDv7 is the strongest outsider — ordered without coordination — but pays two classes as text, surrenders readability as binary, and carries no namespace and no placement contract in either form. The branded snowflake is the only row with every column filled, and the table removed the last argument against it: the contract's wire form is also the cheapest printable one.

**The streams horizon.** Stream entry ids are millisecond-sequence pairs, range-queryable by time because the id carries it [3], under the same monotonic top-id law the contract's minter obeys [4]. The injection `unix_ms(snow)` dash `low-22-bits(snow)` is therefore order-preserving, and measured on 200,000 entries per stream:

```text
s_auto  (XADD *)                 20 bytes/entry
s_brd   (explicit branded ids)   20 bytes/entry
window [+10ms, +20ms)            40960 entries returned, 40960 expected
first id in window               1781000000010-28672   (node 7 << 12 | seq 0)
```

Carrying the contract into the entry id costs nothing, and buys exact replay windows addressed by the same `min_for` arithmetic every runtime already implements — the groundwork EchoMQ 3.0 stands on.

## Who

Whoever shapes a key: the author of a new system choosing its entity keys, the owner of the EchoMQ keyspace and its envelope grammar, the agent working from the guide beside this chapter, and the trading registry — whose six namespaces inherit this chapter's verdict wholesale, one decision amortized over every identity the platform will ever mint.

## When

Consult this chapter when the economics bind: keyspaces in the millions per node, TTL-heavy families (an expire is plus-34 bytes of object growth here, not a second table), and anything stream-shaped from now on. Consult the spec's runbook — not this chapter — when the engine bumps: re-validation re-checks the directional invariants on a dated new output; it does not reopen the chooser. And the verdict does not wait for scale to apply: the branded form is chosen for its contract properties first, and the storage layer's agreement removed the cost objection rather than creating the reason.

## Where

The engine under EchoMQ is Valkey, reached through the custom Elixir connector; the measured pair is Redis 7.0.15 and Valkey 9.1.0 built from its tag, both on jemalloc 5.3.0. The harness and evidence live at `bench/valkey-id/` (`gen_resp.py`, `valkey_id_bench.out`, `streams_bench.out`), the CPU record at `bench/branding-vs-decimal/`, and the standing decisions in [`bcs.progress.md`](bcs.progress.md). This chapter's triad sits beside it: the spec and the agent guide linked above.

## How — the keys, produced identically in Elixir and in Go

The fleet guarantee is that two runtimes shaping the same key produce the same bytes — which the canon's conformance suites already prove for the branded payload, leaving only the envelope to discipline:

```elixir
# Elixir — the connector side
job_key   = "emq:{" <> queue <> "}:job:" <> EchoData.Snowflake.next_branded("ORD")
stream_id = "#{EchoData.Snowflake.unix_ms(snow)}-#{Bitwise.band(snow, 0x3FFFFF)}"
```

```go
// Go — the consumer side
jobKey   := "emq:{" + queue + "}:job:" + brandedid.MustEncode("ORD", snow)
streamID := fmt.Sprintf("%d-%d", brandedid.UnixMs(snow), snow&0x3FFFFF)
```

Same grammar, same accessors-by-contract, byte-identical keys — so the hashtag's slot decision agrees across the fleet, and a `PRT` page or an `ORD` replay window computes the same range on either side of the bus. The recipes above are the discipline; the equality claim rests on the conformance suites, not on review.

## Decisions

**The verdict stands as the contract states it:** branded snowflake, every column filled, cheapest printable form on the measured table. **The staircase is the durable model:** the 9.x line extends the same bucket structure with SIMD lookups and batch prefetching [2], so class-edge thinking outlives this release. **Prefixes are budgeted** (INV-K2) and **decimal renderings are banned from keys** (INV-K1) — the table and Appendix 1.1 close that door from both sides. **The injection is the one stream-id scheme** (INV-K4); a parallel mapping would be the second clock in new clothing. And the engine supersession that frames all of this is recorded where decisions live, not relitigated here.

## Boundaries

Single node, one allocator: the class edges are jemalloc-5.3.0's and move with the malloc. `used_memory` deltas include table and allocator effects by design; per-object accounting differs across the engines and was deliberately not the metric. UUIDv4 and v7 are storage-identical — the column difference is order, not bytes. The streams numbers are Valkey-only, and the 22-bit mapping assumes the contract's layout. Nothing here measures cluster mode, and nothing here compares engines the architecture no longer targets.

## Companion files

The triad: [`bcs1.3.specs.md`](bcs1.3.specs.md) and [`bcs1.3.llms.md`](bcs1.3.llms.md). The evidence: `bench/valkey-id/gen_resp.py`, `valkey_id_bench.out`, `streams_bench.out`; the CPU record under `bench/branding-vs-decimal/`; the Valkey 9.1.0 build tree reproduces with `make`.

## References

1. Söderqvist, V. — A new hash table. Valkey project, technical deep dive, 2025-03-28: [valkey.io/blog/new-hash-table](https://valkey.io/blog/new-hash-table/)
2. Valkey 8.1.0 GA announcement — the release the hash table shipped in: [valkey.io/blog/valkey-8-1-0-ga](https://valkey.io/blog/valkey-8-1-0-ga/)
3. Valkey documentation — Streams introduction (entry-id structure; time ranges from the id): [valkey.io/topics/streams-intro](https://valkey.io/topics/streams-intro/)
4. Valkey command reference — XADD (explicit ids, total order, the monotonic top-id rule): [valkey.io/commands/xadd](https://valkey.io/commands/xadd/)
