# The Order Theorem — string order is mint order

> Route: `/bcs/ideas/identity-contract/the-order-theorem` (dive 2 of 4, B1.2). Teaches the *ordered* property
> of `content/bcs1.2.md`; evidence per `content/echo_data/runtimes/elixir/bcs_rung_1_1_check.out` and
> `content/out/streams_bench.out`; constants per `content/vectors.json`. Build stamp: `BCS0NtMmOUSmDQ`.

## Hero

Kicker: `B1.2 · DIVE 2 OF 4 — the ordered property`. Title: **String order is mint order.** Lede — because the
payload is a fixed-width encoding of a strictly increasing integer, string order equals numeric order equals
mint order. A table keyed by branded ids is a timeline with no clock in the process. Heronote — the lineage:
Twitter's 2010 generator promised ids that were uncoordinated, 64-bit, and roughly sortable. The contract
hardens *roughly* into *exactly* per node — the minting law makes each node's sequence strictly monotonic.

### Three sorts, one order (interactive SVG)

The proof sketch as a picture: the alphabet ascending in byte value (`0–9` < `A–Z` < `a–z`), the fixed width
removing length ambiguity, the timestamp in the most significant bits. Three buttons — byte order · numeric
order · mint order — each sorts the same fixed dataset (the six committed snowflakes of
`content/vectors.json`, encoded live by a pure function) and prints the resulting sequence; all three agree.
Degrades to a static diagram plus the two committed encode/decode vectors.

## §1 · The theorem, and its lineage (#theorem)

Twitter 2010: uncoordinated, 64-bit, roughly sortable. The contract's payload is fixed-width and zero-padded
over a strictly ascending alphabet, so comparison is positional with no length ambiguity — payload byte order
*is* base62 numeric order, and the timestamp occupies the most significant bits. *Roughly* becomes *exactly*
per node.

## §2 · Proven on a table (#table)

Frozen (content/echo_data/runtimes/elixir/bcs_rung_1_1_check.out · G4):

    G4 ordered ok -- page_desc(2000) == byte-sort desc over 2000 minted ids; store holds no clock

Two thousand mints paged newest-first from byte comparison alone. The store holds no clock — the chronology is
in the keys.

## §3 · Extended across a stream (#stream)

Frozen (content/out/streams_bench.out · the window addressed by id arithmetic):

    window [+10ms, +20ms) via branded-derived ids: 40960 entries (expected 40960)
    first id in window: "1781000000010-28672"  (low 22 bits = node 7 << 12 | seq 0 = 28672)

A ten-millisecond window addressed purely by id arithmetic returned its predicted 40960 entries.

## §4 · Cursors without a clock (#cursors)

Interactive: the synthetic cursor `min_for(t) = (t − EPOCH_MS) << 22` — the smallest snowflake mintable at or
after instant `t`, the half-open lower bound for every time-range scan. Buttons compute the cursor for the two
committed instants (`1769526697641`, `1780512970164`) and compose the half-open window; the readout shows the
cursor snowflake and its branded form, computed live by a pure function.

## §5 · What systems do with it (#corollaries)

A table keyed by branded ids is a timeline. A feed is a descending sort. A window is two synthetic cursors —
in a table or a stream alike. Consult the theorem when choosing keys, cursors, and replay windows; any system
applying a collation to branded text must use byte order, because a language collation breaks the theorem and
the range gate at once. Retired: the second clock — the `created_at` column an id-keyed table no longer needs.

## References (#refs)

Sources: King — Announcing Snowflake
(`https://blog.twitter.com/engineering/en_us/a/2010/announcing-snowflake`) · Valkey (`https://valkey.io/`).
Related: `/bcs/ideas/identity-contract` (the hub) · `/bcs/ideas` · `/bcs` · `/redis-patterns`.

## Pager

Previous: dive 1 · `/bcs/ideas/identity-contract/the-namespace-discriminant`. Next: dive 3 ·
`/bcs/ideas/identity-contract/placement-not-security`.
