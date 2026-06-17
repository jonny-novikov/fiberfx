# The Measured Table — seven shapes, one million keys

> Route: `/bcs/ideas/id-system/the-measured-table` (dive 2 of 4, B1.3). Teaches the measurement of
> `content/bcs1.3.md` (Measured); the table verbatim from
> `content/echo_data/bench/valkey-id/valkey_id_bench.out`. Build stamp: `BCS0NtOSgK37Oi`.

## Hero

Kicker: `B1.3 · DIVE 2 OF 4 — seven shapes, one million keys`. Title: **Seven shapes, four findings.** Lede —
Redis 7.0.15 against Valkey 9.1.0, both jemalloc 5.3.0, one million keys per shape, a constant 8-byte value,
`used_memory` delta per key after settle. Seven key shapes enter; four findings come out. Heronote — the rows
below are the committed output, character for character; the comparator computes deltas live from the same
fixed dataset and nothing else.

### The comparator (interactive SVG)

Single bars per shape at the measured Valkey 9.1.0 cost (65 · 73 · 97 · 65 · 81 · 81 · 99) over dashed
16-byte class lines. Buttons per shape; the readout prints the verbatim row, the gap to `brd14` computed live,
and the projection of that gap per hundred million keys — the function that yields the chapter's own 3.2 GB
for `uuid36`. Degrades to the static labelled chart.

## §1 · The protocol (#protocol)

One million keys per shape, written to each engine, the `used_memory` delta divided by the key count after
settle. Both engines on jemalloc 5.3.0, so the allocator's size classes are held constant and the table is the
variable. The constant 8-byte value keeps the value's cost identical across rows.

## §2 · The table (#table)

Frozen (content/echo_data/bench/valkey-id/valkey_id_bench.out · verbatim):

    # engines: v=7.0.15 jemalloc-5.3.0  |  v=8.1.8 jemalloc-5.3.0  | N=1,000,000/run | value=8B embstr
    fmt keylen redis7 valkey81 saved
    brd14 14 88 65 23
    u64dec 19 104 73 31
    uuid36 36 120 97 23
    uuid16 16 104 65 39
    ulid26 26 104 81 23
    emq26 26 104 81 23
    brd14+ttl 14 128 99 29

The publication's claims reproduce on this project's own keys — 23 to 39 bytes saved, 29 on the TTL row.

## §3 · The four findings (#findings)

1. **The branded form ties raw binary:** 65 bytes against binary UUID-16's 65, while staying printable,
   typed, and ordered; the storage argument for binary keys is gone.
2. **Branding beats its own integer:** the same snowflake as 19 decimal digits costs 73 — the namespace plus
   the denser alphabet is a discount, not a tax. Decimal renderings are banned from keys (INV-K1 in the
   chapter's spec of record).
3. **Canonical UUID strings pay two classes:** 97 against 65, 32 bytes a key, 3.2 GB per hundred million keys
   before replication.
4. **The envelope costs one step:** the realistic 26-byte `emq:{q}:job:` key lands at 81, even with ULID's 26
   characters — at this layer length is destiny and charset is free, so the prefix budget is a design surface
   (INV-K2).

Interactive: four buttons, one per finding; each highlights its rows on the chart and prints the finding with
its verbatim numbers in the readout.

## References (#refs)

Sources: Söderqvist — A new hash table (`https://valkey.io/blog/new-hash-table/`) · Valkey 8.1.0 GA
(`https://valkey.io/blog/valkey-8-1-0-ga/`).
Related: `/bcs/ideas/id-system` (the hub) · `/bcs/ideas` · `/bcs` · `/echomq` (the `emq:{q}:job:` envelope's
owner) · `/redis-patterns`.

## Pager

Previous: dive 1 · `/bcs/ideas/id-system/the-new-hash-table`. Next: dive 3 ·
`/bcs/ideas/id-system/the-chooser`.
