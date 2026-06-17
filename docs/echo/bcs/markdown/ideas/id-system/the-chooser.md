# The Chooser — every column filled

> Route: `/bcs/ideas/id-system/the-chooser` (dive 3 of 4, B1.3). Teaches the chooser of `content/bcs1.3.md`
> (The chooser); the storage column per `content/echo_data/bench/valkey-id/valkey_id_bench.out`. Build stamp:
> `BCS0NtOSgPj600`.

## Hero

Kicker: `B1.3 · DIVE 3 OF 4 — the candidate table`. Title: **Every column filled.** Lede — against the BCS
requirements — discriminant in the value and the type, lexicographic mint order, in-contract placement, fixed
printable width, cross-runtime canon — seven candidates enter the table. One row has every column filled.
Heronote — the storage column is the measured table's; the remaining columns are the contract's properties.
Nothing in this table is taste.

### The candidate matrix (interactive SVG)

The seven candidates as rows, the five columns as cells — empty cells drawn empty. Buttons per candidate; the
readout prints the verbatim row and the chapter's commentary where it has one. Degrades to the static matrix
plus the full table below it.

## §1 · The requirements (#requirements)

Five columns: **Valkey B/key** (the measured table's verdict at rest) · **Time-ordered** (string order as mint
order, the order theorem's demand) · **Type tag** (the namespace discriminant, carried in the value) ·
**Placement fn** (in-contract placement arithmetic any holder may run) · **Coordination** (what the scheme
asks of the fleet to mint safely).

## §2 · The candidates (#candidates)

The table, verbatim (content/bcs1.3.md · The chooser):

| Candidate | Valkey B/key | Time-ordered | Type tag | Placement fn | Coordination |
| --- | --- | --- | --- | --- | --- |
| serial integer | ~57–65 | insertion only | none | none | central sequence |
| UUIDv4 (hex 36) | 97 | no | none | none | none |
| UUIDv7 (hex 36) | 97 | yes | none | none | none |
| UUID (binary 16) | 65 | v7 only | none | none | none |
| ULID (26) | 81 | yes | none | none | none |
| snowflake, decimal | 73 | yes | none | by convention | node id |
| **branded snowflake (14)** | **65** | **yes, lexicographic** | **3-byte namespace** | **hash32, in-contract** | **node id** |

Frozen (content/echo_data/bench/valkey-id/valkey_id_bench.out · the storage column's source):

    fmt keylen redis7 valkey81 saved
    brd14 14 88 65 23
    u64dec 19 104 73 31
    uuid36 36 120 97 23
    uuid16 16 104 65 39
    ulid26 26 104 81 23

## §3 · The strongest outsider, and the verdict (#verdict)

UUIDv7 is the strongest outsider — ordered without coordination — but pays two classes as text, surrenders
readability as binary, and carries no namespace and no placement contract in either form. The branded snowflake
is the only row with every column filled, and the table removed the last argument against it: the contract's
wire form is also the cheapest printable one.

Interactive: five buttons, one per requirement column; each reads the column down all seven candidates and
names where it goes empty.

## References (#refs)

Sources: Söderqvist — A new hash table (`https://valkey.io/blog/new-hash-table/`) · Valkey 8.1.0 GA
(`https://valkey.io/blog/valkey-8-1-0-ga/`) · Snowflake ID (`https://en.wikipedia.org/wiki/Snowflake_ID`).
Related: `/bcs/ideas/id-system` (the hub) · `/bcs/ideas` · `/bcs` · `/redis-patterns`.

## Pager

Previous: dive 2 · `/bcs/ideas/id-system/the-measured-table`. Next: dive 4 ·
`/bcs/ideas/id-system/the-streams-horizon`.
