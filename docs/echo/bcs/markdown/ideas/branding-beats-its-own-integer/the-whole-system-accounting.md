# B1.6.3 · The Whole-System Accounting

> Dive · served at `/bcs/ideas/branding-beats-its-own-integer/the-whole-system-accounting` · teaches
> `content/bcs1.a1.md` §§ "The whole-system accounting" + "Boundaries".

An id is rendered once and then stored, compared, and transmitted for the rest of its life. The
brand's per-mint cost ranges from minus 13 nanoseconds (Rust) to plus 335 (today's Node); its
per-life return is fixed: **8 bytes per key at rest** on the measured table (65 against 73), **5
bytes on every wire hop**, and a fixed-width, type-bearing token at every gate.

## Hero interactive — the life of an id

An SVG of the four stations (mint → store → wire → gate) with four buttons. Selecting a station
reads out its line of the ledger — per-mint cost range at the mint, 8 bytes at rest in the store, 5
bytes per hop on the wire, the fixed-width type-bearing token at the gate — a pure lookup over the
committed accounting. Static fallback states all four lines.

## §1 Minted once, cheaper forever

Even the worst case amortizes immediately — a Node service minting ten thousand ids a second spends
3.35 milliseconds of CPU per second, a third of one percent of a core, while every one of those keys
is cheaper in the store and shorter on every message it ever rides. The sentence from Chapter 1.3
survives the CPU question intact, with one runtime's asterisk and its remedy already named: the
contract's wire form is cheaper than the "lean" alternative it is usually defended against.

```text
v22.22.2
node branded ns/op=381
node decimal ns/op=45.6
```

Source: `content/echo_data/bench/branding-vs-decimal/node_bench.out` — the worst case the arithmetic
amortizes.

## §2 The worst-case arithmetic, stepped

A three-step stepper over fixed inputs, each step computed live by a pure function: the per-mint
premium (381 − 45.6 → plus 335 nanoseconds), the per-second bill at ten thousand mints a second
(10,000 × 335 ns → 3.35 milliseconds of CPU per second), and the share of a core (3.35 ms in 1,000
ms → a third of one percent). Static fallback carries the full arithmetic.

## §3 Boundaries

One host, the recorded toolchains; ratios travel better than absolute numbers. The Go rows compare
what the APIs return, so the regime note is part of the result, not a caveat to it. The Elixir row
is the native path; the pure path is conformance-covered but not separately timed here. The Node row
is the pure-TypeScript implementation by construction — the wasm encode export does not exist yet,
which is the point of measuring its absence. Storage figures and their allocator-class mechanics are
Chapter 1.3's, inherited verbatim.

```text
fmt     keylen  redis7  valkey81  saved
brd14   14      88      65        23
u64dec  19      104     73        31
```

Source: `content/echo_data/bench/valkey-id/valkey_id_bench.out` — the per-life return at rest, 65
against 73.

## References

Sources:
- Söderqvist — A new hash table (Valkey project): https://valkey.io/blog/new-hash-table/ — the
  single-allocation entries behind the 65-against-73 step.
- Wikipedia — Snowflake ID: https://en.wikipedia.org/wiki/Snowflake_ID — the integer whose decimal
  shadow loses the accounting.

Related:
- /bcs/ideas/branding-beats-its-own-integer — the module hub.
- /bcs/ideas/id-system — B1.3 · the storage record (65 vs 73) the return column inherits.
- /echomq — the bus where every key rides the wire hops this ledger counts.
- /bcs/ideas — B1 · Ideas Behind.

Pager: previous `/bcs/ideas/branding-beats-its-own-integer/the-five-runtimes` · next
`/bcs/ideas/branding-beats-its-own-integer` (back to the hub).

Stamp: `BCS0NtfDC4mOAq` (2026-06-11 17:00:39 UTC).
