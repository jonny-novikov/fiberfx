# B1.3 · Choosing the ID System

> Route: `/bcs/ideas/id-system` (module hub, B1.3). The route-mirror source-of-record. Teaches
> `content/bcs1.3.md`; every figure verbatim from the committed outputs under
> `content/echo_data/bench/valkey-id/`. Build stamp: `BCS0NtORwuEJ4i`.

## Hero

Kicker: `B1.3 · CHOOSING THE ID SYSTEM — manuscript chapter 1.3`. Title: **Settled by the table.** Lede — the
Branded Component System sends exactly one kind of value across every boundary, and beneath every boundary that
value lands as a key in a hash table. Valkey 8.1 rebuilt that table from first principles — an open-addressing,
cache-line-bucket design — and changed what an identifier costs at rest. Heronote — this module settles the
chooser question on that ground: which ID system the BCS standardizes on, decided by measurement rather than
taste, with seven key shapes pushed through a million keys each on the old table and the new.

### The cost sheet (interactive SVG)

Paired bars per key shape — Redis 7.0.15 beside Valkey 9.1.0, drawn to the measured byte values (88/65 ·
104/73 · 120/97 · 104/65 · 104/81 · 104/81 · 128/99). Buttons per shape; the readout prints the verbatim row
and computes the gap to the branded form live. Degrades to the static labelled chart.

## §1 · Why this chapter exists (#why)

Two decisions of record frame the question. EchoMQ 2.0 is backed by Valkey through a custom optimized Elixir
connector — so the engine under the bus is the engine whose economics matter. And EchoMQ 3.0 plans Streams with
PubSub — so the identifier's cost inside a *second* data structure, the stream entry, is first-class now rather
than later. Between them sits the trading registry: every `AST`, `TXN`, `PRT`, `ORD`, `RSK`, and `STR` identity
this series mints will live as keys, fields, and entries in this store, multiplied by every replica. A chooser
settled by folklore would be a tax on all of it; this one is settled by the table.

## §2 · The evidence (#evidence)

Setup: Redis 7.0.15 against Valkey 9.1.0, both jemalloc 5.3.0, one million keys per shape, constant 8-byte
value, `used_memory` delta per key after settle.

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

The branded form ties binary UUID-16 (65 against 65) while staying printable, typed, and ordered; it beats its
own decimal rendering (65 against 73); the canonical UUID string pays two size classes (97); the 26-byte
`emq:{q}:job:` envelope lands at 81. jemalloc's 16-byte size classes make cost a staircase.

## §3 · The verdict, in one line (#verdict)

The branded snowflake is the only row of the candidate table with every column filled, and the measured table
removed the last argument against it: the contract's wire form is also the cheapest printable one.

## §4 · The dives (#dives)

- **the-new-hash-table** — the engine change: the retired chained `dict` against the 8.1 cache-line design;
  one allocation, two memory reads; the size-class staircase.
- **the-measured-table** — seven shapes, one million keys each; the four findings; the prefix budget.
- **the-chooser** — the candidate table; UUIDv7 the strongest outsider; the only row with every column filled.
- **the-streams-horizon** — the entry-id injection; the 40960-entry window; the key recipes in Elixir and Go.

## References (#refs)

Sources: Söderqvist — A new hash table (`https://valkey.io/blog/new-hash-table/`) · Valkey 8.1.0 GA
(`https://valkey.io/blog/valkey-8-1-0-ga/`) · Streams intro (`https://valkey.io/topics/streams-intro/`) · XADD
(`https://valkey.io/commands/xadd/`).
Related: `/bcs/ideas` (the chapter) · `/bcs` (the course home) · `/echomq` (the engine under EchoMQ) ·
`/redis-patterns` (the substrate patterns) · `/elixir`.

## Pager

Previous: `/bcs/ideas` — B1 · Ideas Behind. Next: dive 1 · `/bcs/ideas/id-system/the-new-hash-table`.
