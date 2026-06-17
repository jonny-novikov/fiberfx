# The Branded Snowflake Contract — Specification

<show-structure depth="2"/>

**Version 1.0.0 · Status: normative.** This document, the data file `contract/vectors.json`, and the Rust crate `contract/branded-id-rs` together constitute the canon of the branded snowflake contract. Every implementation in every runtime conforms to this document; where an implementation and this document disagree, the implementation is wrong. The key words MUST, MUST NOT, SHOULD, and MAY are to be read as requirements, strong recommendations, and permissions respectively.

## 1. Purpose and terms

A **branded id** is a fixed-width, namespace-tagged, time-ordered identifier designed to serve as one pivot key across runtimes, queues, caches, and databases. It is the composition of two parts: a **namespace** (three bytes naming the entity kind, e.g. `USR`, `CRS`, `IMG`) and a **snowflake** (a 63-bit unsigned integer carrying mint time, minting node, and sequence). The **text form** is the only wire representation; the **integer form** is the only storage and arithmetic representation. An implementation that lets either form appear on the other side of that line is non-conformant by design intent, even where no vector catches it.

## 2. The integer form

The snowflake follows the layout introduced by Twitter's generator — a 64-bit value composed of milliseconds since an epoch, a worker number, and a sequence [2] — with the contract's own epoch and the sign bit forbidden:

```text
snowflake = timestamp(41) << 22  |  node(10) << 12  |  sequence(12)
```

- `EPOCH_MS` MUST be `1704067200000` (2024-01-01T00:00:00Z). `timestamp` is milliseconds since this epoch.
- The value MUST lie in `[0, 2^63)`. The top bit is never set, so the snowflake survives signed 64-bit containers (BEAM integers, `int64`, `BIGINT`) without reinterpretation.
- 41 timestamp bits cover the epoch plus ~69.7 years; 10 node bits address 1,024 concurrent minters; 12 sequence bits allow 4,096 mints per node per millisecond before borrowing (§7).
- Derived quantities are normative: `unix_ms(s) = (s >> 22) + EPOCH_MS`, and the **synthetic cursor** `min_for(t) = (t - EPOCH_MS) << 22` — the smallest snowflake mintable at or after instant `t`, the half-open lower bound for every time-range scan in the system.

## 3. The text form

```text
branded_id = NS ++ payload          14 bytes, fixed, no terminator
NS         = 3 × [A-Z]
payload    = 11 × base62(snowflake), fixed width, zero-padded
```

The base62 alphabet MUST be exactly, in this order:

```text
0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz
```

Eleven digits of this alphabet express values up to `62^11 − 1 ≈ 2^65.5`, which exceeds the integer range; the excess is closed by the range gate (§4). `base62(2^63 − 1)` is the constant `MAX_PAYLOAD = "AzL8n0Y58m7"`, and a conformant payload MUST compare less-than-or-equal to it under byte order. Values shorter than eleven digits MUST be left-padded with `0`; the fixed width is what the order theorem (§5) stands on.

## 4. The gates

Validation is a total function from arbitrary bytes to either a parsed `(ns, snowflake)` pair or a rejection naming one gate. The gates, with their normative names and evaluation order:

| Gate | Rejects when | C status |
|---|---|---|
| `length` | input is not exactly 14 bytes | `BRANDED_ERR_LENGTH` |
| `namespace` | any of the first 3 bytes is outside `[A-Z]` | `BRANDED_ERR_NAMESPACE` |
| `charset` | any payload byte is outside the alphabet | `BRANDED_ERR_CHARSET` |
| `range` | payload compares greater than `MAX_PAYLOAD`, or an encode input lies outside `[0, 2^63)` or has an invalid namespace | `BRANDED_ERR_RANGE` |

Hosts with structured errors SHOULD surface these names verbatim (`:error` tuples, `Result` unions, exception classes, SQLSTATE detail). Hosts without them MUST still reject — a Boolean `valid?` is conformant; silent acceptance is not. The range gate on parse MUST be performed as a byte-order string comparison against `MAX_PAYLOAD` before or during digit accumulation; implementations MUST NOT rely on native overflow behavior to detect excess.

## 5. The order theorem

**Theorem.** For branded ids sharing a namespace, lexicographic byte order of the text form equals numeric order of the snowflakes, which equals mint-time order up to sequence.

**Proof sketch.** The alphabet is strictly ascending in byte value (`0–9` < `A–Z` < `a–z` in ASCII), so each digit position preserves order; the payload is fixed-width and zero-padded, so comparison is positional with no length ambiguity; therefore payload byte order is base62 numeric order, and the timestamp occupies the most significant bits of that number. The 3-byte namespace prefix is equal within a namespace and partitions between them. ∎

**Corollaries, all normative.** String comparison is time comparison — feeds, cursors, and "latest N" queries MAY sort the text form directly. Any system applying a collation to branded text MUST use byte order (`COLLATE "C"` in PostgreSQL); a language collation silently breaks both this theorem and the range gate. The namespace-first property means a sorted index over branded ids *is* the per-namespace timeline.

## 6. The placement hash

`hash32` maps a snowflake to a 32-bit placement key used identically by the CHAMP trie, the cache layer, and hash partitioning. It MUST be the first half of MurmurHash3's 64-bit finalizer (`fmix64`) [1], truncated to the low 32 bits:

```text
k = snowflake
k = k XOR (k >> 33)
k = (k × 0xFF51AFD7ED558CCD) mod 2^64
k = k XOR (k >> 33)
hash32 = k mod 2^32
```

The multiply is an unsigned wraparound multiply; hosts without native unsigned 64-bit arithmetic MUST emulate it exactly (the BEAM uses bignums then masks, SQL splits 32-bit halves through `numeric`, JavaScript uses `BigInt`). Where a host's hashing interface supplies a seed (PostgreSQL's extended hash support function), the implementation MUST ignore the seed and return `hash32` zero-extended: placement is a pure function of the id, reproducible from any runtime, and that property outranks seed mixing.

### Consumers and evolution

Uniformity-critical consumers MUST take power-of-two moduli of at most `2^8` (`hash32 mod 2^k`, k <= 8 -- the committed hash audit measures k=8 comfortably clean, k=10 at the very edge of a five-percent gate, the joint skewed from k=12 and collapsing at k=13, because inputs above the low bits reach the low word only through the single fold); wider hash-derived fan-out escalates to `hash32/v2` below. Fairness across small or odd lane counts is constructed by round-robin assignment, never hashed. The 5-bit trie windows are clean at every level on the same evidence. The single-round formula is frozen by the vectors in this document and validated for snowflake-shaped inputs by the committed hash audit (`bcs_hash_audit.out`). Should a future measurement find pathology, the successor is `hash32/v2` -- the full two-round finalizer -- introduced behind a wire-version bump with a dual-placement migration window: placement evolution is a planned lane, not an emergency.

## 7. Minting

A conformant minter is monotonic per node, unique across nodes, and burst-tolerant. Normative design, distilled from the reference implementation and from a defect found in an unfaithful port:

- The minter's mutable state MUST be the pair `timestamp ++ sequence` — concretely `state = (ts << 12) | seq` — and MUST NOT embed the node bits. Each mint computes `state' = max(now_state, state + 1)` (compare-and-swap where schedulers race; a plain closure where the host is single-threaded per worker) and composes the id as `(state' >> 12) << 22 | node << 12 | (state' AND 0xFFF)`.
- **Burst borrow:** when more than 4,096 ids are minted in one millisecond, `state + 1` carries from the sequence field into the *timestamp* field — the node borrows ids from its own future milliseconds. Because node bits are outside the counter, the borrow can never reassign an id into another node's space. A state layout with node bits inside the counter exhibits exactly that failure past sequence exhaustion and is non-conformant.
- **Clock regression:** when the wall clock moves backward, `now_state < state` and minting continues from `state + 1`; ids never repeat and never decrease.
- **Node identity** is the deployment's responsibility: each concurrently minting process MUST hold a distinct `node` in `[0, 1023]`, sourced from configuration or a registry. Hash-derived fallbacks MAY be used for development and MUST be documented as collision-possible.

## 8. The C ABI

The boundary contract for native consumers (the BEAM NIF links it; Go measures it; PostgreSQL compiles the C reference behind it) is `contract/include/branded_id.h`, normative as written:

```c
typedef enum {
  BRANDED_OK            = 0,
  BRANDED_ERR_LENGTH    = 1,
  BRANDED_ERR_NAMESPACE = 2,
  BRANDED_ERR_CHARSET   = 3,
  BRANDED_ERR_RANGE     = 4
} branded_status;

branded_status branded_encode(const char ns[3], uint64_t snowflake, char out[14]);
branded_status branded_decode(const char *id, size_t len,
                              char ns_out[3], uint64_t *snowflake_out);
uint32_t branded_hash32(uint64_t key);
uint64_t branded_unix_ms(uint64_t snowflake);
```

`branded_encode` writes exactly 14 bytes with no terminator; `branded_decode` requires `len == 14` and fills its outputs only on `BRANDED_OK`. Implementations of this ABI MUST be callable with no allocator and MUST NOT panic or unwind across the boundary on any input.

## 9. Normative vectors

The machine-readable form of this section is `contract/vectors.json`; the two MUST stay identical, and a release in which they differ is void.

```text
encode("USR", 274557032793636864)        = "USR0KHTOWnGLuC"
decode("USR0NgWEfAEJfs")                 = ("USR", 320636799581945856)
hash32(274557032793636864)               = 234878118
unix_ms(274557032793636864)              = 1769526697641     2026-01-27T15:11:37.641Z
unix_ms(320636799581945856)              = 1780512970164
base62(2^63 − 1)                         = "AzL8n0Y58m7"

reject "USRzzzzzzzzzzz"                  → range
reject "usr0KHTOWnGLuC"                  → namespace
reject "USR0KHTOWnGLu"                   → length
reject "USR0KHTOWnGL!C"                  → charset
```

## 10. Conformance

An implementation is conformant when it passes, in its own test harness: every vector and every reject above; a roundtrip property over at least 5,000 uniformly random snowflakes in `[0, 2^63)`; the order theorem over at least 1,000 minted ids (string sort compared against numeric sort); and, where it implements minting, uniqueness across a concurrent burst exceeding one sequence window. The canon itself is exercised by `make -C contract test` (the crate suite, including a one-million-id roundtrip). Current conformant suites: `runtimes/elixir/verify.exs` (pure and native paths, asserted against each other at boot by `self_check!/0`), `contract/branded-id-rs` tests, `runtimes/node/bench.ts` and `wasm_bench.ts`, `runtimes/go/brandedid` tests, and `runtimes/postgres/branded_sql.sql` plus the extension's reject and vector blocks.

## 11. Canon and change control

`contract/branded-id-rs/src/lib.rs` is the **only** Rust source of the contract and builds every binary form: `make -C contract cdylib` produces the host shared object the BEAM links (installed by the Elixir Makefile as `priv/libbranded_rs.so`); `make -C contract dist` builds `branded_id.wasm` once and places the identical artifact with both Node consumers. `contract/c/branded_id.c` is the C reference implementation, consumed **by reference** (the PostgreSQL extension compiles it from this path; no tree may carry a copy). The header in `contract/include/` is the single ABI declaration.

Any behavioral change to the contract MUST arrive as: a version bump here and in `vectors.json` and the crate, new or amended vectors, and a same-change update to every conformant suite — in that order, spec first. A runtime MAY lag the canon only while its boot- or import-time self-check still passes the shipped vectors; the moment it cannot, it is out of contract and MUST fail loudly rather than serve.

## References

1. Appleby, A. — SMHasher / MurmurHash3 (public-domain reference; `fmix64` finalizer): [github.com/aappleby/smhasher](https://github.com/aappleby/smhasher)
2. Twitter Engineering — Announcing Snowflake (the 64-bit time/worker/sequence layout and its uncoordinated, roughly-sortable design goals): [blog.twitter.com/engineering/en_us/a/2010/announcing-snowflake](https://blog.twitter.com/engineering/en_us/a/2010/announcing-snowflake)
