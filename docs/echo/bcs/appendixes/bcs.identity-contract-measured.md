# BCS · The Identity Contract, Measured — Six Encodings Across jemalloc, Valkey 8+, and the BEAM

<show-structure depth="2"/>

The Branded Component System draws its boundaries around systems, not objects: the only values that cross a system's edge are identities and messages about identities, so the encoding of that identity is the one representation every store, cache, and runtime must agree on. This article fixes the contract from the committed `echo_data` modules, then measures six candidate encodings — three taken faithfully from published specifications and three designed here — for mint speed, comparison and sort cost, per-key memory on the Valkey 8+ hashtable, per-key cost on the BEAM's `ordered_set`, and developer experience. Numbers are recorded for wins and losses alike; the decision of record is stated at the end.

## Scope and method

Everything measured ran on one host: an Intel Xeon at 2.80 GHz, one vCPU, with a 32 KiB L1d, a 1 MiB L2, and a 33 MiB L3 over 64-byte lines. Four measurement spines, each with its committed evidence file:

- **jemalloc 5.3.0** (git `54eaed1d`), built with Valkey's own flags `--with-lg-quantum=3 --with-jemalloc-prefix=je_`, probed through `je_nallocx` and `je_malloc_usable_size` — evidence in `evidence/jemalloc.out`. This is the allocator Valkey links; the server banner reports `malloc=jemalloc-5.3.0`.
- **Valkey** built from the development branch (`v=255.255.255`, Redis-OSS-compat 7.2.4), carrying the new `hashtable`. `used_memory` deltas were taken with a fresh server per length, N = 300,000 — evidence in `evidence/valkey.out`.
- **C**, gcc 13.3.0 `-O2 -march=native`, `CLOCK_MONOTONIC`, best-of-5, allocator glibc — evidence in `evidence/idbench-c.out`.
- **Pure Elixir**, 1.14.0 on Erlang/OTP 25 (erts 13.2.2.5, BEAM JIT), 8-byte words — evidence in `evidence/idbench-elixir.out`.

The contract itself is cited, not invented: it is read from the uploaded `EchoData.Bcs.PropertyStore`, `EchoData.Bcs.EdgeStore`, and `EchoStore.Table`. Mint speed, comparison, sort, and memory are measured. Developer experience is assessed against a fixed rubric and labelled as assessment, not measurement. Out of frame: multi-node behaviour, network round-trips, persistence, and the C cache micro-benchmark's allocator (glibc, not jemalloc — pre-allocated arrays make that choice immaterial for access-pattern timing).

## The contract, read from the modules

A branded id in the canon is a fourteen-byte text value: a three-byte ASCII namespace followed by an eleven-character base62 body that encodes a sixty-three-bit snowflake of the shape `ts(41) | node(10) | seq(12)` against the 2024-01-01 epoch. The shape is the one Twitter announced in 2010 to replace coordinated auto-increment ids [1]. The uploaded code makes the width and the boundary law explicit. `EchoStore.Table` frames its level-two value as `<<version::binary-14, value::binary>>` and asserts its kind is three bytes; its door is a single function:

```elixir
defp gate(kind, id) do
  if is_binary(id) and byte_size(id) == 14 and binary_part(id, 0, 3) == kind and
       BrandedId.valid?(id) do
    :ok
  else
    {:error, :kind}
  end
end
```

`EchoData.Bcs.PropertyStore` keys a private `:ordered_set` by that fourteen-byte string and computes placement as `BrandedId.hash32(snow)` — a hash any holder runs, never a coordinator's assignment. The contract reads as four properties: the namespace lives in the value and the type; mint order is byte order; placement is the hash, computed not coordinated; and the format is one specification. An encoding is a candidate for BCS only if it preserves those four. The base62 body is written in ASCII order, so a fixed-width body compares lexicographically exactly as the snowflake compares numerically — mint order is byte order falls out for free, and the smoke test confirms it: ids minted in sequence satisfy `ids == Enum.sort(ids)`.

## The Valkey 8+ substrate, per encoding

Because the systems share one level-two store, 'how much does an id cost in Valkey' is part of the contract, and Valkey 8+ changed the answer. The development branch's `hashtable` packs a bucket into one 64-byte cache line holding up to seven entries: one byte of chained-plus-presence bits, seven one-byte secondary hashes, and seven 8-byte pointers [2]. A lookup reads the bucket, eliminates non-matching slots by the secondary hash without touching the key, and follows at most one pointer to the object. Crucially, the bucket cost is pointer-and-metadata only — it does not change with the id's byte length. Where length lands is the object the pointer reaches: Valkey 8+ embeds the key into that object rather than allocating it separately, removing one random memory access per key [3]. So the per-key cost is the bucket's amortized share plus the embedded-key object's size class — and the size class is jemalloc's.

## Derivation: the jemalloc lattice predicts the cliffs

Before any Valkey number, the allocator predicts the result. Built with Valkey's `--with-lg-quantum=3`, jemalloc 5.3.0's small classes step by eight bytes [6]: 8, 16, 24, 32, 40, 48, 56, 64, then 80, 96, 112, 128. A bare key of 13, 14, 15, or 16 bytes therefore lands in the same 16-byte class:

```text
14  canon text key (3ns + 11 base62)          -> class 16   usable 16   slack 2
15  4-letter ns + 11 base62                   -> class 16   usable 16   slack 1
16  4-letter ns + 12 base62 / u128 binary     -> class 16   usable 16   slack 0
17  namespace+body+flagbyte                   -> class 24   usable 24   slack 7
```

Two predictions follow. First, widening the namespace from three letters to four, or spending the two unused bytes the canon already pays for, costs nothing up to and including sixteen bytes — the fourteen-byte key wastes two bytes of slack, the sixteen-byte key wastes none. Second, the sixteenth byte is a cliff: a seventeenth byte, the first that a flags lane would add past sixteen, jumps to the 24-byte class and pays seven bytes of slack. The design rule writes itself — keep the encoding at or under sixteen bytes and the widening is free; cross it and pay a class.

## Measured: Valkey 8+ memory per key

```text
## SET keyspace: bytes of used_memory per key (object incl. embedded key + bucket share)
len   empty        after        delta        bytes_per_key
14    687448       17345288     16657840     55.53  (keys=300000)
16    688280       17357000     16668720     55.56  (keys=300000)
26    687576       19742408     19054832     63.52  (keys=300000)
36    688280       24549384     23861104     79.54  (keys=300000)

## SADD one big set -> hashtable: bytes of used_memory per member
14    687512       10150072     9462560      31.54  (enc=hashtable card=300000)
16    688152       12551800     11863648     39.55  (enc=hashtable card=300000)
26    687384       14948984     14261600     47.54  (enc=hashtable card=300000)
36    688024       17348088     16660448     55.53  (enc=hashtable card=300000)
```

**In the keyspace, fourteen and sixteen bytes cost the same.** A SET key with an embedded one-byte value lands at 55.53 bytes per key at fourteen bytes and 55.56 at sixteen — within noise, the prediction holds, and the four-letter namespace is free. The twenty-six-byte ULID text rises to 63.52 (one class), the thirty-six-byte UUID text to 79.54 (heavier still). **In a collection, the boundary bites earlier.** A large set stores each member as a bare sds, so the fourteen-byte member sits a class below the sixteen-byte member: 31.54 against 39.55, an eight-byte step exactly where the bare-key lattice predicts it. The reading for BCS: the keyspace tolerates a wider id at no cost, while id collections — sets of orders, indexes of fills — pay for every byte over fourteen, so a sixteen-byte binary belongs in the keyspace and the slimmest text belongs in a large set.

## The six encodings

Three encodings are taken without invention from published specifications; three are designed here, free to lay out bits and build tables. All six preserve the four contract properties.

The NO-INVENT three. **N1, the branded snowflake**, is the canon: fourteen-byte text, the 2010 snowflake shape branded with a three-byte namespace [1]. **N2, branded UUIDv7**, is RFC 9562: a forty-eight-bit big-endian Unix-millisecond prefix, version and variant bits, then seventy-four bits of randomness, sixteen bytes binary or thirty-six characters of canonical hex text [4]. **N3, branded ULID**, is the ULID specification: a forty-eight-bit millisecond prefix and eighty random bits, sixteen bytes binary or twenty-six characters of Crockford base32, the alphabet chosen to drop look-alike letters [5].

The INVENT three. **I1, BID16**, packs sixteen big-endian bytes as `[ts48 | node16 | seq16 | ns24 | flags8 | rsv16]`: byte order is mint order, comparison is one 128-bit integer compare via two byte-swapped loads, and a dedicated flags lane carries `deleted`, `tomb`, and tier bits low in the value, where toggling them never reorders by time. This is the 'attribute bits' idea made concrete — and the smoke test confirms setting `deleted` leaves the time-ordered prefix unchanged. **I2, the near-table**, is a structural experiment rather than an encoding: an open-addressing directory that stores the sixteen-byte key inline in the bucket beside its secondary-hash tag, measured against a bucket of indices into a contiguous array and a bucket of pointers into scattered allocations — the Valkey object model. **I3, the system lane**, places the System tag as the most-significant field, so a whole system's ids form one contiguous key range; per-system scans become a single slice, trading global time order for per-system time order. This is the 'TRC tracing tree' lane generalised: the boundary BCS draws around a system becomes a contiguous region of the key space.

### Perf in C: mint, compare, sort

```text
## mint: ns per id        ## compare: ns/op       ## sort: ms for 2,000,000
N1 snowflake   12.60      N1 strcmp14   18.26     N1 14B text    572.0
N2 uuidv7      10.18      N2 memcmp16   19.71     N2 16B memcmp  557.2
N3 ulid         5.96      I1 u128cmp    16.82     I1 16B u128    435.7
I1 bid16        4.05
```

**I1 mints fastest and sorts fastest.** Writing sixteen bytes from integers with no base62 division and no random draw costs 4.05 ns, against 12.60 ns for the snowflake whose mint includes the base62 encode. On comparison the three are close — 18.26, 19.71, 16.82 ns — because a sixteen-byte big-endian key compares as two sixty-four-bit loads, the same work `memcmp` does, and I1's two-word integer compare edges ahead. The sort of two million keys separates them: the fourteen-byte text at 572.0 ms, the sixteen-byte binary at 557.2, and I1's integer-ordered sixteen bytes at 435.7 — roughly a quarter faster than text. The loss to record is encode cost (in `evidence/idbench-c.out`): rendering a ULID to its twenty-six Crockford characters costs more than base62 or hex once written competently, and any text form pays an encode the binary forms never owe.

### Perf on the BEAM: where the BCS stores live

```text
## mint ns/id   ## sort ms 500k   ## ETS :ordered_set bytes/key (N=200,000)
N1   608.32     N1 14B  1305.9    14B text (3ns+11)   112.01
N2   533.29     N2 16B   525.7    16B binary (bid16)   96.01
N3   417.30     I1 16B   459.4    26B text (ulid)     112.01
I1    62.67                       36B text (uuid)     112.01
```

The BEAM amplifies the same ordering. I1 mints at 62.67 ns where the base62 snowflake costs 608.32, because building a binary from integers avoids the division loop and the bignum randomness the other forms incur. **The sixteen-byte binary is the cheapest key the `ordered_set` holds**: 96.01 bytes per key against 112.01 for the fourteen-byte text — and, notably, the twenty-six- and thirty-six-byte text forms also sit at 112.01, because within the heap-binary regime the tree node and word granularity dominate and length barely moves the per-key cost. The packed binary's advantage is that it is constructed as a clean four-word term rather than a six-word concatenation. Sorting agrees: the sixteen-byte binary sorts in roughly 460–525 ms against 1305.9 ms for the fourteen-byte text. For `EchoData.Bcs.PropertyStore`, which keys an `ordered_set` by the branded id, the binary form is the cheaper and faster key — at the cost of readability, addressed below.

### The cache experiment: indirection is the tax, not length

```text
## I2 lookup: ns/lookup across cache levels
# n_keys  inline_ns  idxarr_ns  scattered_ns   (resident: <32K L1, <1M L2, <33M L3)
1024     20.72      20.22      21.22
262144   38.01      31.67      48.95
1048576  80.38      67.07      105.39
4194304  102.88     87.58      124.94
```

The third I2 variant models Valkey's object layout: the bucket holds a pointer into a pool larger than the L3, so a confirmed key lives on a random line. While the working set fits in cache the three are even, near 20 ns. Past the L3 the picture separates: the scattered-pointer lookup reaches 124.94 ns where the index-into-a-contiguous-array reaches 87.58 and the inline-key bucket 102.88. The finding is candid and useful — **the cost is indirection to scattered allocations, not the id's length.** Inline keys help against scattered objects but lose to a compact index into one contiguous structure, because the inline bucket spans two cache lines where the index bucket fits in one. This is the measured argument for the BCS shape the modules already use: the id as the key in one sorted, contiguous table beats scattering ids behind pointers, and it tempers the intuition that packing the id inline is always the win.

### The system lane: a boundary you can scan

```text
## I3 system-lane (C, N=2,000,000, G=16 systems)    ## I3 on ETS :ordered_set (N=1,000,000)
system-first   125141 visited   0.32 ms             system-first   found=62500    12.03 ms
time-first    2000000 visited   3.25 ms             time-first     found=62500   154.20 ms
```

When the System tag is the most-significant field, collecting one system's ids visits only that system's contiguous block: 125,141 keys and 0.32 ms in the flat-array case, against scanning all two million at 3.25 ms when time order interleaves the systems. On the `ordered_set` the BCS stores use, the same layout collects one system in 12.03 ms against 154.20 ms — about thirteen times less work. The trade is named: a system-first key orders globally by system and only then by time, so the canon's 'a table is a timeline' becomes 'a table is a timeline per system.' For a tracing tree, where queries are nearly always scoped to one system, that is the better order; for a global recent-activity feed it is the wrong one.

## Inside a single-namespace component table

A component store in BCS holds one namespace: a `PropertyStore` of users keys only `USR…` ids. That raises the project's question — if the namespace is constant across the table, must every key still carry its three letters? The coherence module answers half of it already: `EchoStore.Coherence.newer?/2` orders two ids by their eleven-byte base62 bodies alone, `<<_::binary-3, pa::binary-11>>` against `pb`, because the order theorem makes the body lexicographically equal to mint order regardless of namespace. Mint order does not need the namespace, so the namespace can move from the key into the table's metadata and the key can shrink. Whether that *saves* anything is a measurement, and the measurement splits the intuition in two.

```text
## ETS :ordered_set bytes/key (N=200000) and sort 500k — order-preserving key forms
key form                      val=true   val=true+compressed   sort 500k    flat_size
text14 (USR + body)           96.01      104.01                 171.0 ms     4 words
body11 (namespace stripped)   96.01      104.01                  75.2 ms     4 words
snow8  (u64 big-endian)       88.01       96.01                  13.8 ms     3 words
int63  (integer, fixnum)      64.01       72.01                  84.2 ms     0 words
int63  (integer, bignum)      80.01         —                       —        2 words

## Valkey 8+ SADD member bytes/member — stripping has no effect below the 16-byte class
 8 bytes 31.31    11 bytes 31.30    14 bytes 31.54    16 bytes 39.55
```

On the BEAM's `:ordered_set`, dropping the three namespace letters does not move per-key memory: the fourteen-byte text id and the eleven-byte body both occupy 96.01 bytes per key, four heap-binary words, because both round to the same word bucket. As a memory optimization, **stripping the namespace is rejected**. It is not without effect — the shorter key more than halves sort time, 171.0 ms to 75.2 ms over five hundred thousand keys, because the comparator scans fewer bytes. In Valkey the memory verdict is the same: an eight-, eleven-, or fourteen-byte set member each cost about 31.3 bytes, one jemalloc class, and only the sixteenth byte crosses to the next, so removing three text bytes stays inside the class.

The saving that does exist is representational, not truncational. **Keyed by the snowflake as a fixed eight-byte big-endian binary**, an ordered component holds 88.01 bytes per key — three words, constant as the timestamp grows — and sorts in 13.8 ms, about twelve times faster than the text id. Keyed by the snowflake as an **integer** it holds 64.01 bytes while the value is a sixty-bit fixnum and 80.01 once it crosses into a bignum (for this epoch, a few years of timestamps before the fixnum window closes). Both preserve mint order, so a range over the column is a chronological window with no secondary index, and both move the namespace into metadata where it is recovered on read. The win is the fixed-width form, not the deleted letters.

Compression earns its own rejection. The `:compressed` table flag — the BEAM-native lever — adds about eight bytes per key on a key-only row (96.01 to 104.01) and changes nothing on a small twenty-four-byte value (136.01 either way): term-level compression targets large objects, and a component row is not one. For an ordered property map the compaction is the key representation, not a compression flag.

`EchoData.Bcs.Column` is that structure: an `:ordered_set` keyed by the snowflake (`:snow8` by default, `:int` where the smallest key matters), the namespace held once as the column's kind, the gate run on entry so a wrong-namespace id is refused, and `reconstruct/2` rebuilding the full branded id from the kind and the stored snowflake on the way out — the id a caller receives is whole while the id the table stores is compact. `EchoData.Buckets` is the companion for lifetime-bounded components: it derives time buckets from the same snowflake, so `expire_older_than/2` drops whole buckets in O(buckets) and a session or rate-limit window pays nothing per entry for expiry. Where value semantics over a shared structure are wanted, `:gb_trees` keyed by the snowflake integer is the persistent alternative, at a higher per-entry word cost.

## The chooser

| Encoding | Bytes (bin / text) | Valkey 8+ keyspace B/key | BEAM ordered_set B/key | Mint (C / BEAM ns) | Readable in a log | Native DB type | Carries flags |
|---|---|---|---|---|---|---|---|
| N1 branded snowflake | — / 14 | 55.53 | 112.01 | 12.60 / 608.32 | yes (ns + base62) | no | no |
| N2 branded UUIDv7 | 16 / 36 | 55.56 (bin) · 79.54 (text) | 96.01 (bin) · 112.01 (text) | 10.18 / 533.29 | partial | yes (uuid) | no |
| N3 branded ULID | 16 / 26 | 55.56 (bin) · 63.52 (text) | 96.01 (bin) · 112.01 (text) | 5.96 / 417.30 | yes (base32) | rarely | no |
| I1 BID16 | 16 / — | 55.56 | 96.01 | 4.05 / 62.67 | no (raw bytes) | no | yes (8-bit lane) |
| I3 system lane | 16 / — | 55.56 | 96.01 | comparable to I1 | no | no | per-system order |

DX is the column set on the right, assessed not measured. N1 reads in a log as a namespace and a short body and double-click-selects; its loss is no native database type and a per-id base62 cost. N2 owns the strongest external case: RFC 9562 means a native `uuid` column in PostgreSQL and a generator in nearly every standard library, the lowest-friction path for a team — at thirty-six text characters and no room for a namespace brand without convention. N3 is shorter and URL-safe and sorts as text, with a smaller ecosystem than N2. I1 and I3 trade all readability for the cheapest, fastest key and, for I1, an explicit attribute lane; their loss is that a raw sixteen-byte value is opaque in logs and needs tooling to inspect.

## The decision for BCS

The contract does not change: the boundary is the id, the gate is the namespace, and every store opens its mutating paths with it. What this measurement settles is the encoding, and the answer is layered rather than singular. Keep N1, the fourteen-byte branded text, as the canonical boundary value that crosses systems and appears in logs, payloads, and the level-two frame — it reads, it brands, and in the Valkey keyspace it costs exactly what a sixteen-byte id costs, so the four-letter namespace the project considered is admissible at no memory penalty whenever a system outgrows three letters. Inside hot internal indexes — the `ordered_set` a `PropertyStore` keys, a per-system trace store — prefer the sixteen-byte packed binary of I1: it is the cheapest BEAM key at 96.01 bytes, mints at 62.67 ns, sorts a quarter faster, and carries the `deleted`/tier flags lane the canon lacks, with the system-lane ordering of I3 available where per-system scans dominate. The strongest case against this split is N2's: a team that values one standardised, database-native identifier over a custom binary has a coherent reason to adopt UUIDv7 everywhere and pay the text width. The measurement does not refute that choice; it shows what the project trades for it — readability and ecosystem against per-key memory, mint cost, and the absence of a brand and a flags lane.

The two winners, stated plainly: **N1, the fourteen-byte branded text, wins the boundary** — the value that crosses systems, reads in a log, and frames the level-two row, free at four letters in the Valkey keyspace. **The snowflake-keyed `EchoData.Bcs.Column` wins the internal property map** — inside a single-namespace component table the namespace is metadata, not key, and the snowflake as a fixed eight-byte binary holds 88.01 bytes per key with the fastest ordered scan, lighter than the sixteen-byte packed form because in-table it needs neither the brand nor the node and flags lanes. I1's sixteen bytes remain the choice where those lanes are needed — a cross-namespace binary index, or a row that must carry `deleted`/tier flags — and `EchoData.Bcs.Column` with `key_form: :int` is the lowest-memory variant where scan throughput matters less than the sixty-four bytes a fixnum key costs.

## Boundaries

The memory figures are specific to jemalloc 5.3.0 at `lg-quantum=3` and to the Valkey development branch's embedded-key hashtable; a different allocator quantum or a pre-8 Valkey moves the class boundaries and the per-key deltas. The Valkey numbers use a one-byte value to isolate key cost; real values shift the object into larger classes where a few key bytes matter less. The C cache experiment uses glibc and a synthetic pool; it argues about access patterns, not about a specific server's fragmentation. The BEAM per-key figures are for an `ordered_set` with a trivial value and do not model a populated property bundle. DX is one team's rubric, not a measurement. No figure here claims anything about multi-node placement, replication, or the wire.

## Companion files

The package carries the measured artifacts and the runnable canon. C: `c/idbench.c`, `c/sizeclass.c`, and the dedicated encoder `c/idencode.c`. The identity engine and the four-width library: `elixir/branded_id.ex` (minting both the three-letter fourteen-byte and four-letter fifteen-byte namespace), `elixir/bcs.ex`, `elixir/bcs_ids.ex`, `elixir/snowflake.ex`, and the component column `elixir/column.ex`. Harnesses and checks: `elixir/idbench.exs`, `elixir/idkeys.exs` (the component-key and compression bake-off), `elixir/column_check.exs`, `elixir/smoke.exs`, `elixir/ids_check.exs`, `elixir/check_offline.exs`. The BCS canon as uploaded, running on the implemented engine: `elixir/property_store.ex`, `elixir/edge_store.ex`, `elixir/archetypes.ex`, `elixir/supervisor.ex`, `elixir/echo_store.ex`, `elixir/table.ex`, `elixir/buckets.ex`. The level-two connection layer that backs `EchoStore` with Valkey: `elixir/connector.ex`, `elixir/resp.ex`, `elixir/script.ex`, `elixir/keyspace.ex`, `elixir/emq_keyspace.ex`. The coherence lane: `elixir/coherence.ex` (newer-wins by the eleven-byte body) and `elixir/ring.ex` (the single-producer apply ring). Two end-to-end checks drive `EchoStore.Table` against a live Valkey through `EchoMQ.Connector`: `elixir/ec_live.exs` confirms the level-two frame `<<version::binary-14, value::binary>>` on the wire, and `elixir/rb_live.exs` drives the broadcast coherence lane through the ring and shows newer-wins and idempotent replay. Valkey memory harness: `valkey/vkmem.sh`, `valkey/vkmem.py`. Evidence: `evidence/jemalloc.out`, `evidence/valkey.out`, `evidence/idbench-c.out`, `evidence/idbench-elixir.out`, `evidence/idkeys.out`.

## References

1. Snowflake ID — the 2010 Twitter format, a 41-bit timestamp, 10-bit machine field, and 12-bit sequence in a 64-bit value: [en.wikipedia.org/wiki/Snowflake_ID](https://en.wikipedia.org/wiki/Snowflake_ID)
2. Valkey — A new hash table (64-byte buckets, seven entries, secondary-hash metadata): [valkey.io/blog/new-hash-table](https://valkey.io/blog/new-hash-table/)
3. Valkey — Storing more with less: Memory Efficiency in Valkey 8 (key embedding removes a random pointer access): [valkey.io/blog/valkey-memory-efficiency-8-0](https://valkey.io/blog/valkey-memory-efficiency-8-0/)
4. Davis, Peabody, Leach — RFC 9562, Universally Unique IDentifiers, version 7: [rfc-editor.org/rfc/rfc9562.html](https://www.rfc-editor.org/rfc/rfc9562.html)
5. Feerasta, A. — ULID specification, 48-bit time plus 80-bit randomness in Crockford base32: [github.com/ulid/spec](https://github.com/ulid/spec)
6. jemalloc 5.3.0 release — the size-class allocator Valkey links: [github.com/jemalloc/jemalloc/releases/tag/5.3.0](https://github.com/jemalloc/jemalloc/releases/tag/5.3.0)
