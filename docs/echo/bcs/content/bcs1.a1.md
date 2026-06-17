# BCS · Appendix 1.1 — Branding beats its own integer

<show-structure depth="2"/>

Chapter 1.3 measured a sentence worth promoting to its own appendix: the same snowflake rendered as decimal text (19 digits) costs 73 bytes per key on Valkey's new table, eight more than its 14-byte branded base62 form at 65 — the namespace plus the denser alphabet is not a tax over the raw id; at the storage layer it is a discount. This appendix asks the follow-up the finding deserves: does the CPU agree? The encode path — u64 in, text out — is measured here in all five runtimes of the canon, against the real implementations, with the decimal rendering as the opponent in each. The answer has texture: the compiled runtimes agree emphatically, the BEAM calls it a tie, and V8 records the one loss — in exactly the place the contract already prescribes a native crossing.

## Scope and method

The storage rows are inherited from Chapter 1.3 ([`bcs1.3.md`](bcs1.3.md)) and its committed `bench/valkey-id/valkey_id_bench.out`; nothing storage-side is re-measured. The CPU rows are new: each runtime encodes snowflakes with the low 20 bits varied (to defeat constant folding), accumulates a byte of each output into a sink (to defeat dead-code elimination), and reports the best of three runs (five on Node, matching the runtime's existing bench helper). Toolchains as recorded in the committed outputs under `bench/branding-vs-decimal/`: cc 13.3.0 at `-O2`, rustc 1.75.0 (the rlib rebuilt for the bench with the no_std panic handler stripped, so a std example can link — noted in the output header), go 1.22.2 on the recorded CPU, Elixir with the native codec loaded (the output records `elixir(native)`), and Node v22.22.2 running the TypeScript implementation directly. The decimal opponents are the idiomatic forms per runtime, with a no-allocation variant added where the idiom allocates.

## The two renderings, derived

A decimal rendering of a 60-something-bit snowflake performs about 19 divmods by 10 into a variable-width buffer whose length is only known at the end. The branded rendering performs exactly 11 divmods by 62 into fixed positions 3 through 13 of a 14-byte buffer, then copies 3 namespace bytes into positions 0 through 2. Fewer divisions, no width computation, no length to return — the structure predicts a win for the brand wherever both forms run as compiled userland code, a question mark wherever one side gets engine-level help, and it predicts the storage column unconditionally: five fewer bytes per key pushed the embedded object down one allocator size class in Chapter 1.3's measurement, 65 against 73 on Valkey 8.1's single-allocation entries [1].

## The five implementations

The encode under test is the same contract in five tongues, each cited at its surface:

```text
contract/include/branded_id.h:37   branded_status branded_encode(const char ns[3], uint64_t snowflake, char out[…])
contract/branded-id-rs/src/lib.rs:71   pub fn encode(ns: &[u8; NS_LEN], snowflake: u64) -> Result<[u8; LEN], Error>
runtimes/go/brandedid/brandedid.go:40   func Encode(ns string, snow uint64) (string, error)
runtimes/elixir/lib/echo_data/branded_id.ex:67   def encode(<<_::binary-size(3)>> = ns, snow)
runtimes/node/branded_id.ts:82   export const encode = <N extends string>(ns: N, snow: bigint): Result<BrandedId<N>>
```

The harnesses live beside the outputs: `c_bench.c`, the crate's `examples/branding_bench.rs`, `branding_bench_test.go` in the Go module, `bench_branding.exs`, and `branding_bench.ts`.

## Measured

```text
runtime              branded encode      decimal encode                  committed output
C (cc 13.3, -O2)     7.21 ns/op          20.49 ns/op  (itoa)             c_bench.out
Rust 1.75 (-O)       5.14 ns/op          21.77 itoa · 31.61 to_string    rust_bench.out
Go 1.22.2            40.02 ns/op         48.29 FormatUint · 25.87 AppendUint   go_bench.out
Elixir (native)      132.5 ns/op         133.6 ns/op                     elixir_bench.out
Node 22 (pure TS)    381 ns/op           45.6 ns/op  (BigInt toString)   node_bench.out
```

**C and Rust: the derivation cashes.** The brand encodes 2.8× faster than a tight hand itoa in C (7.21 against 20.49) and 4.2× faster in Rust (5.14 against the fair fixed-buffer 21.77; 6.1× against the idiomatic allocating `to_string` at 31.61). Eleven divisions into fixed positions beat nineteen into a width the code must then account for. Anywhere a hot path renders ids in compiled code — the C extension, the Rust core under the NIF and the wasm — the branded form is the cheap one, in bytes and in cycles at once.

**Go: a split decided by allocation, not by alphabet.** `MustEncode` returns a string and beats its allocation-fair twin `FormatUint` (40.02 against 48.29), while the no-allocation `AppendUint` floor wins at 25.87 — the comparison crosses API regimes, not encoding costs. The obvious closer is an append-style branded encode writing into a caller buffer, which the derivation says would land near the C number; it is recorded as a follow-up rather than claimed.

**Elixir: a tie, and an informative one.** 132.5 against 133.6 nanoseconds — the cost of crossing into the native codec equals the BEAM's own integer-to-string machinery almost exactly. The brand is free where it matters most in this series' reference runtime, and the conformance suite already guarantees the pure path agrees on every byte.

**Node: the recorded loss, in the prescribed place.** Userland BigInt base62 pays interpreter-level costs per divmod; V8's decimal conversion is engine C++ — 381 against 45.6, an 8.4× deficit. This is precisely the boundary the contract tells this runtime to cross: the wasm codec already serves `decode` and `hash32` through the loader, and an `encode` export is the carried follow-up. Until it lands, the arithmetic below keeps the loss in proportion.

## The whole-system accounting

An id is rendered once and then stored, compared, and transmitted for the rest of its life. The brand's per-mint cost ranges from minus 13 nanoseconds (Rust) to plus 335 (today's Node); its per-life return is fixed: 8 bytes per key at rest on the measured table (65 against 73), 5 bytes on every wire hop, and a fixed-width, type-bearing token at every gate. Even the worst case amortizes immediately — a Node service minting ten thousand ids a second spends 3.35 milliseconds of CPU per second, a third of one percent of a core, while every one of those keys is cheaper in the store and shorter on every message it ever rides. The sentence from Chapter 1.3 survives the CPU question intact, with one runtime's asterisk and its remedy already named: the contract's wire form is cheaper than the "lean" alternative it is usually defended against.

## Boundaries

One host, the recorded toolchains; ratios travel better than absolute numbers. The Go rows compare what the APIs return, so the regime note above is part of the result, not a caveat to it. The Elixir row is the native path; the pure path is conformance-covered but not separately timed here. The Node row is the pure-TypeScript implementation by construction — the wasm encode export does not exist yet, which is the point of measuring its absence. Storage figures and their allocator-class mechanics are Chapter 1.3's, inherited verbatim.

## Companion files

`bench/branding-vs-decimal/{c,rust,go,elixir,node}_bench.out` and the five harness sources named above; the storage record at `bench/valkey-id/valkey_id_bench.out`.

## References

1. Söderqvist, V. — A new hash table. Valkey project, technical deep dive, 2025-03-28 (the single-allocation entry layout behind the size-class step the storage rows ride): [valkey.io/blog/new-hash-table](https://valkey.io/blog/new-hash-table/)
