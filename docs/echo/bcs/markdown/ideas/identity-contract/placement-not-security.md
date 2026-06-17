# Placement, Not Security — hash32's one round

> Route: `/bcs/ideas/identity-contract/placement-not-security` (dive 3 of 4, B1.2). Teaches the *placed*
> property of `content/bcs1.2.md`; the formula per `content/contract.md` §6; vectors per
> `content/vectors.json`. Build stamp: `BCS0NtMmOgNvg8`.

## Hero

Kicker: `B1.2 · DIVE 3 OF 4 — the placed property`. Title: **Placement, not security.** Lede — `hash32` is one
finalizer round from MurmurHash3: xor-shift, the `fmix64` multiply constant, xor-shift, truncated to 32 bits.
Any holder of an id computes where its row lives — trie slot, cache shard, partition, queue lane — with no
directory and no rendezvous. Heronote — the same answer everywhere: `234878118` for the reference id,
reproduced by Elixir, Rust, C, TypeScript, wasm, Go, and SQL in this repository's committed outputs, at
`0.9586` nanoseconds in pure Go.

### The round, step by step (interactive SVG)

The four stages as a pipeline — `k XOR (k >> 33)` · `k × 0xFF51AFD7ED558CCD mod 2⁶⁴` · `k XOR (k >> 33)` ·
`mod 2³²` — applied to the reference snowflake `274557032793636864`. Select a stage to see the value after it,
computed live; the final readout lands on the committed `234878118`. Degrades to the static formula.

## §1 · The formula, frozen (#formula)

Frozen (content/contract.md §6 · the placement hash):

    k = snowflake
    k = k XOR (k >> 33)
    k = (k × 0xFF51AFD7ED558CCD) mod 2^64
    k = k XOR (k >> 33)
    hash32 = k mod 2^32

The constant carries Appleby's public-domain lineage, but the full finalizer's avalanche certificate does not
transfer to a single round — so the distribution this series relies on is measured directly over
snowflake-shaped inputs in the committed hash audit.

## §2 · The same answer everywhere (#everywhere)

Frozen (content/vectors.json · the hash32 vectors):

    hash32(274557032793636864)   = 234878118
    hash32(274557032793636865)   = 989747343
    hash32(0)                    = 0
    hash32(1)                    = 2466077478
    hash32(4611686018427387904)  = 3201652940
    hash32(9223372036854775807)  = 2186628710

Seven runtimes — Elixir, Rust, C, TypeScript, wasm, Go, SQL — reproduce `234878118` for the reference id.
Adjacent inputs land far apart: one trailing bit between `…864` and `…865` separates `234878118` from
`989747343`.

## §3 · Lanes, run by hand (#lanes)

Interactive: placement over the six committed vectors. Select a snowflake; a pure function takes
`hash32 mod 2⁸` and the readout shows the lane — the power-of-two modulus the contract bounds
uniformity-critical consumers to (`k ≤ 8`). One function routes a CHAMP slot, a cache shard, and a hash
partition; the routing table is retired.

## §4 · The hard edge (#edge)

This is placement, not security. A non-cryptographic finalizer with no key is exactly the wrong tool wherever
an adversary chooses inputs: the odd multiply and the xor-shift are both invertible, so truncation's 2³²
preimages are the only veil. The contract states the edge and the manuscript repeats it — the round's virtue
is spread, not secrecy. Should a future measurement find pathology, the successor is `hash32/v2` — the full
two-round finalizer — behind a wire-version bump with a dual-placement migration window: placement evolution
is a planned lane, not an emergency.

## References (#refs)

Sources: Appleby — SMHasher/MurmurHash3 (`https://github.com/aappleby/smhasher`) · King — Announcing Snowflake
(`https://blog.twitter.com/engineering/en_us/a/2010/announcing-snowflake`).
Related: `/bcs/ideas/identity-contract` (the hub) · `/bcs/ideas` · `/bcs` · `/redis-patterns`.

## Pager

Previous: dive 2 · `/bcs/ideas/identity-contract/the-order-theorem`. Next: dive 4 ·
`/bcs/ideas/identity-contract/the-minting-law-and-the-canon`.
