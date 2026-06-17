# The New Hash Table — one allocation, two reads

> Route: `/bcs/ideas/id-system/the-new-hash-table` (dive 1 of 4, B1.3). Teaches the engine change of
> `content/bcs1.3.md` (What); evidence per `content/echo_data/bench/valkey-id/valkey_id_bench.out`. Build
> stamp: `BCS0NtOSgEejvU`.

## Hero

Kicker: `B1.3 · DIVE 1 OF 4 — the engine change`. Title: **One allocation, two reads.** Lede — the retired
`dict` resolved one key in four memory reads across three allocations. Valkey 8.1 inverts the layout around the
cache line: a 64-byte bucket holds up to seven entries, key and value embed in one object, and a lookup costs
two memory reads. Heronote — the design is Viktor Söderqvist's open-addressing, cache-line-bucket table; the
chapter is content/bcs1.3.md, and the threshold detail below is read from the 8.1.8 tree the chapter built.

### Two lookup paths (interactive SVG)

The retired chained `dict` drawn beside the 8.1 bucket design. Two buttons — the retired dict · the 8.1
bucket — highlight one path and print its exact anatomy in the readout: reads, allocations, what each box is.
Degrades to the static two-path diagram.

## §1 · The retired dict (#dict)

A chained table: a bucket array of pointers, each entry a separately allocated `dictEntry` of three pointers,
the key its own allocation — four memory reads to resolve one key, plus two per collision hop, plus a second
table during rehash. The cost ledger: a bucket-pointer share, a 24-byte `dictEntry` plus allocation overhead, a
separate key allocation, and — with a TTL — a second entry in the expires dict.

## §2 · The cache-line bucket (#bucket)

The 8.1 design inverts the layout around the cache line: buckets of 64 bytes holding up to seven entries, an
8-byte metadata section — one child-pointer bit, seven presence bits, and seven one-byte secondary hashes built
from the bits not spent addressing the bucket, so mismatched slots are skipped without touching their keys at a
1-in-256 false-positive rate. The `dictEntry` is gone; key and value embed in the `serverObject`, one
allocation per entry, two memory reads per lookup. Incremental rehash, the `SCAN` guarantee, and random
sampling — the features that ruled out adopting Swiss tables wholesale — are kept by construction. One source
detail matters to ID design: every key embeds regardless of length, and keys of 128 bytes or more pre-reserve
an expire slot (`KEY_SIZE_TO_INCLUDE_EXPIRE_THRESHOLD`, `object.c:47` in the 8.1.8 tree).

## §3 · The headline, reproduced (#headline)

The new table charges a share of 64 bytes across up to seven entries and one object that already contains key,
value, and, when set, an inline 8-byte expire; the publication's headline is roughly 20 bytes saved per pair,
roughly 30 with a TTL. The claims reproduce on this project's own keys — 23 to 39 bytes saved, 29 on the TTL
row.

Frozen (content/echo_data/bench/valkey-id/valkey_id_bench.out · three rows):

    fmt keylen redis7 valkey81 saved
    brd14 14 88 65 23
    uuid16 16 104 65 39
    brd14+ttl 14 128 99 29

## §4 · The staircase (#staircase)

jemalloc allocates in 16-byte classes in this range, so key length stops mattering within a class and matters
sharply at its edges: an identifier's storage cost is a staircase, and the design question is which step each
format stands on. Interactive: buttons per measured key length (14 · 16 · 19 · 26 · 36) read the measured
Valkey 9.1.0 cost from the table — 14 and 16 share the 65-byte step; 19 stands at 73; 26 at 81; 36 at 97 — over
a static step-plot SVG of the same five points.

## References (#refs)

Sources: Söderqvist — A new hash table (`https://valkey.io/blog/new-hash-table/`) · Valkey 8.1.0 GA
(`https://valkey.io/blog/valkey-8-1-0-ga/`).
Related: `/bcs/ideas/id-system` (the hub) · `/bcs/ideas` · `/bcs` · `/redis-patterns` (the substrate patterns).

## Pager

Previous: the hub · `/bcs/ideas/id-system`. Next: dive 2 · `/bcs/ideas/id-system/the-measured-table`.
