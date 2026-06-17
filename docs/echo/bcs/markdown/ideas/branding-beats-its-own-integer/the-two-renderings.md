# B1.6.1 · The Two Renderings

> Dive · served at `/bcs/ideas/branding-beats-its-own-integer/the-two-renderings` · teaches
> `content/bcs1.a1.md` § "The two renderings, derived". Storage rows inherited from Chapter 1.3
> (`bench/valkey-id/valkey_id_bench.out`).

A decimal rendering of a 60-something-bit snowflake performs about 19 divmods by 10 into a
variable-width buffer whose length is only known at the end. The branded rendering performs exactly
**11 divmods by 62 into fixed positions 3 through 13 of a 14-byte buffer**, then copies **3
namespace bytes into positions 0 through 2**. Fewer divisions, no width computation, no length to
return.

## Hero interactive — the two renderings, side by side

Two buttons (branded · decimal) over an SVG of the two buffers: the 14 fixed cells of the branded
form (3 namespace + 11 payload) against the variable-width decimal lane. Selecting a rendering reads
out its operation accounting — a pure lookup over the derivation. Static fallback states both
accountings.

## §1 The derivation

The structure predicts a win for the brand wherever both forms run as compiled userland code, a
question mark wherever one side gets engine-level help — and it predicts the storage column
unconditionally: five fewer bytes per key pushed the embedded object down one allocator size class
in Chapter 1.3's measurement, 65 against 73 on Valkey 8.1's single-allocation entries.

Three accountings separate the renderings:

- **Divisions** — 11 divmods by 62 against about 19 divmods by 10. The denser alphabet retires
  eight divisions before any clock runs.
- **Width** — the branded buffer is 14 bytes before the first division; the decimal width is known
  only at the end, so the code must account for it afterward.
- **Length** — the branded rendering returns no length; positions 0 through 2 take the namespace
  copy, positions 3 through 13 take the payload, fixed before the first division runs.

## §2 The storage column, unconditional

```text
fmt     keylen  redis7  valkey81  saved
brd14   14      88      65        23
u64dec  19      104     73        31
```

Source: `content/echo_data/bench/valkey-id/valkey_id_bench.out` (Chapter 1.3's record, inherited
verbatim; value = 8-byte embstr, N = 1,000,000 per run).

## §3 The ledger interactive — three accountings

Three buttons (divisions · width · length); each reads out the branded answer against the decimal
answer, a pure comparison over the fixed derivation. Static fallback carries all three rows.

What the structure cannot predict is what happens where one side gets engine-level help — V8's
decimal conversion is engine C++ while a userland BigInt base62 pays interpreter costs per divmod.
That question mark is the next dive's subject; the measured table resolves it runtime by runtime.

## References

Sources:
- Söderqvist — A new hash table (Valkey project): https://valkey.io/blog/new-hash-table/ — the
  single-allocation entries the size-class step rides.
- Wikipedia — Snowflake ID: https://en.wikipedia.org/wiki/Snowflake_ID — the 60-something-bit
  integer both renderings encode.

Related:
- /bcs/ideas/branding-beats-its-own-integer — the module hub.
- /bcs/ideas/id-system — B1.3 · the storage record (65 vs 73) this derivation inherits.
- /bcs/ideas — B1 · Ideas Behind.
- /bcs — the course home.

Pager: previous `/bcs/ideas/branding-beats-its-own-integer` · next
`/bcs/ideas/branding-beats-its-own-integer/the-five-runtimes`.

Stamp: `BCS0NtfDBsZda4` (2026-06-11 17:00:39 UTC).
