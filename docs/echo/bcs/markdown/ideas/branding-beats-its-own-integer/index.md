# B1.6 · Branding Beats Its Own Integer

> Module hub · served at `/bcs/ideas/branding-beats-its-own-integer` · teaches `content/bcs1.a1.md`
> (Appendix 1.1 — taught as module B1.6 per D-B1.2). Storage rows inherited from Chapter 1.3
> (`content/bcs1.3.md` · `bench/valkey-id/valkey_id_bench.out`).

Chapter 1.3 measured a sentence worth promoting to its own appendix: the same snowflake rendered as
decimal text (19 digits) costs 73 bytes per key on Valkey's new table, eight more than its 14-byte
branded base62 form at 65. The namespace plus the denser alphabet is not a tax over the raw id — at
the storage layer it is a discount. This module asks the follow-up the finding deserves: **does the
CPU agree?** The encode path — u64 in, text out — is measured in all five runtimes of the canon,
against the real implementations, with the decimal rendering as the opponent in each.

The answer has texture: the compiled runtimes agree emphatically, the BEAM calls it a tie, and V8
records the one loss — in exactly the place the contract already prescribes a native crossing.

## Hero interactive — the verdict, per runtime

Five buttons (C · Rust · Go · Elixir · Node) over an SVG of the five runtime stations. Selecting a
runtime reads out its measured branded and decimal encode costs and the one-line verdict, a pure
lookup over the committed table. Static fallback summarizes all five rows.

## §1 The question the storage record earned

The storage verdict is already committed: 65 bytes per key for the 14-byte branded form against 73
for its own 19-digit decimal rendering, on Valkey 8.1's single-allocation entries — five fewer bytes
pushed the embedded object down one allocator size class. A discount at rest says nothing about the
clock. The appendix puts the encode path itself on the bench, runtime by runtime, and inherits the
storage rows verbatim rather than re-measuring them.

Method, as recorded in the committed outputs: the low 20 bits varied to defeat constant folding; a
byte of each output accumulated into a sink to defeat dead-code elimination; best of three runs
(five on Node). Toolchains as recorded: cc 13.3.0 at `-O2`, rustc 1.75.0, go 1.22.2, Elixir with the
native codec loaded, Node v22.22.2 running the TypeScript implementation directly.

## §2 Measured — the committed record

```text
runtime              branded encode      decimal encode                        committed output
C (cc 13.3, -O2)     7.21 ns/op          20.49 ns/op  (itoa)                   c_bench.out
Rust 1.75 (-O)       5.14 ns/op          21.77 itoa · 31.61 to_string          rust_bench.out
Go 1.22.2            40.02 ns/op         48.29 FormatUint · 25.87 AppendUint   go_bench.out
Elixir (native)      132.5 ns/op         133.6 ns/op                           elixir_bench.out
Node 22 (pure TS)    381 ns/op           45.6 ns/op  (BigInt toString)         node_bench.out
```

Source: `content/echo_data/bench/branding-vs-decimal/{c,rust,go,elixir,node}_bench.out`.

## §3 The dives

- **B1.6.1 — The Two Renderings** (`the-two-renderings`): exactly 11 divmods by 62 into fixed
  positions 3–13 of a 14-byte buffer plus a 3-byte namespace copy, against about 19 divmods by 10
  into a width known only at the end. The structure derived before any clock runs.
- **B1.6.2 — The Five Runtimes** (`the-five-runtimes`): the measured table in full — C and Rust cash
  the derivation, Go records a split across API regimes, the BEAM calls a tie, and Node records the
  one loss in exactly the prescribed place.
- **B1.6.3 — The Whole-System Accounting** (`the-whole-system-accounting`): an id is rendered once
  and then stored, compared, and transmitted for the rest of its life — 8 bytes per key at rest, 5
  bytes on every wire hop, and the Node worst case amortized to a third of one percent of a core.

## References

Sources:
- Söderqvist — A new hash table (Valkey project): https://valkey.io/blog/new-hash-table/ — the
  single-allocation entry layout behind the size-class step the storage rows ride.
- Wikipedia — Snowflake ID: https://en.wikipedia.org/wiki/Snowflake_ID — the integer the brand is
  measured against.

Related:
- /bcs/ideas — B1 · Ideas Behind, the chapter landing.
- /bcs/ideas/id-system — B1.3 · the storage record this appendix follows up (65 vs 73).
- /bcs — the course home.
- /elixir — the umbrella where echo_data and its native codec live (the Elixir tie).
- /echomq — the bus where branded keys ride the wire.

Pager: previous `/bcs/ideas` · next `/bcs/ideas/branding-beats-its-own-integer/the-two-renderings`.

Stamp: `BCS0NtfDBmc3qi` (2026-06-11 17:00:39 UTC).
