# echo_data — the Branded Component System (BCS)

`echo_data` is the identity layer of the Echo platform: the successor of an
Entity-Component System that is **id-centric** rather than table-centric. Every
entity is a branded snowflake — `{ns}{base62}` — and components are stored against
that id. Encapsulation is drawn around systems; only identities and messages about
them cross a boundary. This is the half of the `echo_mq → echo_data → echo_store`
stack that lives in the BEAM's term space (ETS), and the source of the keys every
other app — including the Codemojex game — uses as primary keys.

## Branded ids — `EchoData.BrandedId`

A branded id is **14 bytes**: a 3-character namespace prefix followed by an
11-character Base62 payload that encodes a 63-bit snowflake. The namespace is the
developer-facing tag (`USR`, `RND`, `GES`, `EMS`, `TXN`, …); the payload is the
time-ordered snowflake. Because the namespace question — "is the fourth letter
free?" — comes out yes on the pinned jemalloc (a 14-, 15-, or 16-byte key lands in
the same 16-byte size class), the prefix costs nothing at the L2.

| Function | Purpose |
|---|---|
| `generate!(ns)` | mint a fresh id in namespace `ns` (calls `Snowflake.next/0`) |
| `parse/1`, `parse_hash/1` | split an id into `{ns, snowflake}` (or with the hash) |
| `decode/1`, `decode!/1` | recover the snowflake integer from an id |
| `encode/2`, `encode!/2` | build an id from a namespace and a snowflake |
| `namespace/1` | the 3-char prefix |
| `unix_ms/1` | the mint time, in ms, read straight from the id |
| `hash32/1` | a 32-bit hash of the snowflake |
| `valid?/1`, `self_check!/0` | validation and a boot-time invariant check |

Ids sort by time because the payload is a snowflake: a lexical range over branded
ids is a chronological range.

## Snowflakes — `EchoData.Snowflake`

A 64-bit, epoch-shifted, monotonic id generator: `timestamp_ms` in the high bits,
then a node id, then a per-ms sequence. The generator is a process started by the
app; ids are strictly increasing within a node.

| Function | Purpose |
|---|---|
| `next/0`, `next/1` | the next snowflake (optionally for a node id) |
| `next_branded(ns)` | mint and brand in one call |
| `unix_ms/1`, `to_datetime/1` | the embedded mint time |
| `node_id/1`, `sequence/1`, `extract/1` | decompose a snowflake |
| `min_for(datetime)` | the smallest snowflake at/after a time (range scans) |

`min_for/1` plus the ordered-set property below is how a time window becomes a key
range with no secondary index.

## Base62 — `EchoData.Base62`

The payload codec: an 11-character, fixed-width Base62 string encodes the 63-bit
snowflake (`encode/1,2`, `decode/1`, `decode!/1`, `valid?/1`, `alphabet/0`).
Fixed width is what keeps branded ids sortable as plain binaries.

## Components — `EchoData.Bcs` and the stores

`EchoData.Bcs.gate/2` (and `gate!/2`) enforce that an id belongs to an expected
namespace before a system acts on it — the boundary check that keeps a `USR` out
of a code path that expects a `RND`.

### `EchoData.Bcs.PropertyStore` — a component column

An ETS **`:ordered_set` keyed by the branded id**, so the table is itself a
chronological index of the component. There is no secondary index to maintain: a
range over the snowflake-ordered keys is a time window.

| Function | Purpose |
|---|---|
| `start_link/1` | start a column for a namespace |
| `put/3`, `get/2` | write / read a component value by id |
| `record_entity/2` | note an entity exists in the column |
| `window/3` | the ids in `[lo, hi]` — a chronological slice |
| `page_desc/2` | the newest `n` ids, descending |
| `placement/1` | which shard/partition an id falls in |

### `EchoData.Bcs.EdgeStore` — relationships

Directed edges between branded ids with optional properties — the graph half of
the component model.

| Function | Purpose |
|---|---|
| `link/4`, `unlink/3` | create / drop an edge `subj → obj` (with props) |
| `props/3` | the properties on an edge |
| `from/3`, `to/3` | out-edges of a subject / in-edges of an object |
| `degree/2` | the out-degree of a subject |

## Why the versions are pinned

The per-key memory results (a 14-byte and a 15-byte id sharing a word bucket, the
snowflake-as-8-byte-binary undercutting the text id) are properties of *this*
BEAM's term layout and `:ordered_set` representation — which is why the bench pins
`erts 13.2.2.5`. Reproduce the version and the figures reproduce.

## Where Codemojex uses it

Every Codemojex entity is a branded id minted here: `USR` players, `RND` rounds,
`GES` guesses, `EMS` emoji sets, `RMM` rooms, `TXN` ledger rows, `JOB` lane jobs.
The ids are the primary keys in Postgres — BCS supplies identity, the relational
store supplies durability.
