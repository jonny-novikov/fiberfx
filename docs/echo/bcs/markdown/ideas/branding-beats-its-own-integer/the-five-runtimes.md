# B1.6.2 · The Five Runtimes

> Dive · served at `/bcs/ideas/branding-beats-its-own-integer/the-five-runtimes` · teaches
> `content/bcs1.a1.md` §§ "The five implementations" + "Measured".

The encode under test is the same contract in five tongues, each cited at its surface — and each
measured against the idiomatic decimal rendering of the same runtime. The compiled runtimes agree
emphatically, the Go rows split across API regimes, the BEAM calls a tie, and V8 records the one
loss in exactly the place the contract prescribes the wasm crossing.

## Hero interactive — pick a runtime, read its clock

Five buttons (C · Rust · Go · Elixir · Node) over an SVG of the five stations. Selecting a runtime
reads out its branded and decimal ns/op and computes the ratio live from the fixed table — pure
division over committed numbers. Static fallback summarizes all five verdicts.

## §1 The five implementations

```text
contract/include/branded_id.h:37   branded_status branded_encode(const char ns[3], uint64_t snowflake, char out[…])
contract/branded-id-rs/src/lib.rs:71   pub fn encode(ns: &[u8; NS_LEN], snowflake: u64) -> Result<[u8; LEN], Error>
runtimes/go/brandedid/brandedid.go:40   func Encode(ns string, snow uint64) (string, error)
runtimes/elixir/lib/echo_data/branded_id.ex:67   def encode(<<_::binary-size(3)>> = ns, snow)
runtimes/node/branded_id.ts:82   export const encode = <N extends string>(ns: N, snow: bigint): Result<BrandedId<N>>
```

The harnesses live beside the outputs: `c_bench.c`, the crate's `examples/branding_bench.rs`,
`branding_bench_test.go` in the Go module, `bench_branding.exs`, and `branding_bench.ts`.

## §2 Measured

```text
runtime              branded encode      decimal encode                        committed output
C (cc 13.3, -O2)     7.21 ns/op          20.49 ns/op  (itoa)                   c_bench.out
Rust 1.75 (-O)       5.14 ns/op          21.77 itoa · 31.61 to_string          rust_bench.out
Go 1.22.2            40.02 ns/op         48.29 FormatUint · 25.87 AppendUint   go_bench.out
Elixir (native)      132.5 ns/op         133.6 ns/op                           elixir_bench.out
Node 22 (pure TS)    381 ns/op           45.6 ns/op  (BigInt toString)         node_bench.out
```

Source: `content/echo_data/bench/branding-vs-decimal/{c,rust,go,elixir,node}_bench.out`. Method as
recorded: low 20 bits varied to defeat constant folding; a byte of each output accumulated into a
sink to defeat dead-code elimination; best of three runs, five on Node.

## §3 The verdicts

- **C and Rust — the derivation cashes.** The brand encodes 2.8× faster than a tight hand itoa in C
  (7.21 against 20.49) and 4.2× faster in Rust (5.14 against the fair fixed-buffer 21.77; 6.1×
  against the idiomatic allocating `to_string` at 31.61). Eleven divisions into fixed positions beat
  nineteen into a width the code must then account for.
- **Go — a split across API regimes, allocation not alphabet.** `MustEncode` returns a string and
  beats its allocation-fair twin `FormatUint` (40.02 against 48.29), while the no-allocation
  `AppendUint` floor wins at 25.87 — the comparison crosses API regimes, not encoding costs. An
  append-style branded encode writing into a caller buffer is recorded as a follow-up rather than
  claimed.
- **Elixir — a tie, and an informative one.** 132.5 against 133.6 nanoseconds — the cost of crossing
  into the native codec equals the BEAM's own integer-to-string machinery almost exactly.
- **Node — the recorded loss, in the prescribed place.** Userland BigInt base62 pays
  interpreter-level costs per divmod; V8's decimal conversion is engine C++ — 381 against 45.6, an
  8.4× deficit. This is precisely the boundary where the contract prescribes the wasm crossing: the
  wasm codec already serves `decode` and `hash32` through the loader, and an `encode` export is the
  carried follow-up.

## §4 The Go split interactive

Three buttons (`MustEncode` · `FormatUint` · `AppendUint`); each reads out the measured number and
its API regime — string-returning against append-into-caller-buffer — a pure lookup that teaches the
regime reading, not a re-measurement.

## References

Sources:
- Söderqvist — A new hash table (Valkey project): https://valkey.io/blog/new-hash-table/ — the table
  the storage rows this appendix follows up were measured on.
- Wikipedia — Snowflake ID: https://en.wikipedia.org/wiki/Snowflake_ID — the integer under both
  encoders.

Related:
- /bcs/ideas/branding-beats-its-own-integer — the module hub.
- /bcs/ideas/id-system — B1.3 · the storage record the appendix inherits.
- /elixir — the umbrella where echo_data's native codec lives (the Elixir tie's other half).
- /bcs — the course home.

Pager: previous `/bcs/ideas/branding-beats-its-own-integer/the-two-renderings` · next
`/bcs/ideas/branding-beats-its-own-integer/the-whole-system-accounting`.

Stamp: `BCS0NtfDByooRU` (2026-06-11 17:00:39 UTC).
