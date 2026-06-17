# B2.3.1 · The Forest and the Placement Law — the brand routes; the integer hashes

> Route: `/bcs/elixir-core/champ/the-forest-and-the-placement-law` (dive 1 of B2.3). The route-mirror
> source-of-record. Teaches the H1 slice of `content/bcs2.3.md`; figures verbatim from
> `bcs_rung_2_3_check.out` and `content/contract.md`. Build stamp: `BCS0Nuxm8dHTXc`.

## Hero

Kicker: `B2.3 · DIVE 1 — THE FOREST AND THE PLACEMENT LAW`. Title: **The brand routes; the integer hashes.**
Lede — `EchoData.BrandedChamp` is a forest: a top-level map from the 3-byte namespace to a CHAMP trie, with
the trie keyed by the *snowflake integer* — the id is split at the boundary, the base62 payload decoded once,
and the integer enters the trie. Heronote — source: `content/bcs2.3.md`; the gate is H1 in
`bcs_rung_2_3_check.out`; the integrated modules are committed at `runtimes/elixir/lib/echo_data/champ/`
(`branded_champ.ex`, `champ_node.ex`, `champ_server.ex`).

### The forest, drawn (interactive SVG)

The two-stage placement drawn as a diagram: a branded id splits into brand and integer; the brand selects a
trie in the forest map; the integer hashes into that trie's nodes. Segments to select — **the brand** (routes:
the namespace picks the trie), **the integer** (hashes: the decoded snowflake is the trie key), **datamap**
(the bitmap for inline pairs), **nodemap** (the bitmap for children), **the compact array** (popcount-indexed;
no empty slots). Live readout per segment; degrades to the static labelled diagram.

## §1 · The transcript (#transcript)

`bcs_rung_2_3_check.out`, verbatim — this dive reads H1:

```text
H1 canon ok -- placement delegated to the contract hash: compute_hash_int -> BrandedId.hash32; reference snowflake round-trips
```

(The full record, all seven gates and the mid-record `[debug]` boot line, is frozen on the module hub.)

## §2 · The amendment — one placement law, in-process too (#amendment)

Source: `content/bcs2.3.md` · What, How. The drop's `compute_hash_int` carried a single mixing round — the
first `fmix64` constant, once — under a comment claiming it matches the Go side. The canon's Go *is* the full
`fmix64` behind `hash32` (the committed `234878118` vector, at 0.9586 ns), and Chapter 1.2's law admits
exactly one placement function. The integration performs the alignment as a delegation — the amendment is
three lines and a comment:

```elixir
# Chapter 2.3 integration review: placement delegated to the contract hash.
defp compute_hash_int(key) when is_integer(key) and key >= 0 do
  EchoData.BrandedId.hash32(key)
end
```

H1 gates it from both sides: `compute_hash_int -> BrandedId.hash32` asserted in the integrated source, and
the reference snowflake round-tripping through the trie. The comment's intent is now true. The decision the
manuscript records: any future structure that hashes identities delegates to the contract or does not merge.

## §3 · The two-bitmap node (#node)

Source: `content/bcs2.3.md` · What, citing Steindorfer & Vinju. The nodes are the CHAMP design proper: two
32-bit bitmaps per node — `datamap` for inline pairs, `nodemap` for children — over a popcount-indexed compact
array, 5-bit hash fragments for 32-way branching, and the canonical representation the paper introduced so
that equal maps are equal structures. Around the core: an O(1) cached census per namespace
(`namespace_size/2`), the `Access`, `Enumerable`, and `Collectable` protocols, and a by-snowflake operation
family that skips string handling when the caller already holds the integer.

### The placement path, computed (interactive)

A pure function decomposes the committed canonical vector — `hash32(274557032793636864) = 234878118`, the
contract's own test vector — into its 5-bit fragments, level by level: each level consumes five bits of the
hash, a number from 0 to 31 selecting one of 32 ways down. Buttons step the levels; the readout shows the
fragment's bits, its value, and the slot it selects. Without JavaScript the figure reads as a static
description of the same walk.

## References (#refs)

Sources: Steindorfer & Vinju — OOPSLA 2015 (`https://dl.acm.org/doi/10.1145/2814270.2814312`) · Erlang/OTP —
the ets module (`https://www.erlang.org/doc/apps/stdlib/ets.html`).
Related: `/bcs/elixir-core/champ` (B2.3 — the module hub) · `/bcs/elixir-core` (B2 · The Elixir BCS Core) ·
`/bcs/elixir-core/property-stores` (B2.2 — the flat table this module measures against) · `/elixir` (the
umbrella where `echo_data` lives).

## Pager

Previous: `/bcs/elixir-core/champ` — B2.3 · the hub. Next:
`/bcs/elixir-core/champ/sharing-at-the-honest-metric` — Sharing at the Honest Metric.
