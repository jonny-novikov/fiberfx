# B2.3.2 · Sharing at the Honest Metric — a version is a path, not a map

> Route: `/bcs/elixir-core/champ/sharing-at-the-honest-metric` (dive 2 of B2.3). The route-mirror
> source-of-record. Teaches the H2/H3 slice of `content/bcs2.3.md`; figures verbatim from
> `bcs_rung_2_3_check.out`. Build stamp: `BCS0Nuxm8ixS8u`.

## Hero

Kicker: `B2.3 · DIVE 2 — SHARING AT THE HONEST METRIC`. Title: **A version is a path, not a map.** Lede — H2
writes a thousand `ORD` rows into `v1`, derives `v2` with one more put, and gates the defining property:
`v1 holds 1000, v2 holds 1001`, and the new row never appears in v1. H3 then counts heap words — and records
a methods lesson worth keeping. Heronote — source: `content/bcs2.3.md`; the gates are H2 and H3 in
`bcs_rung_2_3_check.out`.

### Two versions, one structure (interactive SVG)

The derivation drawn: v1's root, v2's root, the one copied root-to-leaf path between them, and the subtrees
both roots reach. Segments to select — **v1** (holds 1000; unchanged by the derivation), **v2** (holds 1001;
one put away), **the path** (the 122 words v2 costs beside v1), **the shared region** (98% of v2 is shared
with v1). Live readout per segment with the verbatim gate line; degrades to the static labelled diagram.

## §1 · The transcript (#transcript)

`bcs_rung_2_3_check.out`, verbatim — this dive reads H2 and H3:

```text
H2 persist ok -- the old snapshot is intact: v1 holds 1000, v2 holds 1001, and v1 cannot see the new row
H3 sharing ok -- structural sharing measured: v2 costs 122 words beside v1 (one path copy) against 6688 standalone -- 98% of v2 is shared with v1
```

(The full record is frozen on the module hub.)

## §2 · H2 — the old snapshot is intact (#persist)

Source: `content/bcs2.3.md` · What. Persistence in the data-structure sense: deriving `v2` does not edit
`v1`. H2 writes a thousand rows, derives a successor with one more put, and gates the defining property —
each version is a complete, immutable value, and the new row is absent from the old binding. Holding a
version is holding a snapshot; nothing about the derivation reaches back.

## §3 · H3 — the denominator trap, and the metric of record (#metric)

Source: `content/bcs2.3.md` · What, Decisions. The first metric — "percent of the pair shared" —
mathematically caps near fifty for two near-identical structures and *failed a correct implementation*: when
two structures of about the same size share nearly everything, the shared words divided by the words of the
pair approach one half no matter how complete the sharing is. The denominator carries both copies; the
ceiling is structural, not a defect in the trie. The metric of record is marginal cost:
`v2 costs 122 words beside v1 (one path copy) against 6688 standalone -- 98% of v2 is shared with v1`. The
manuscript documents the trap so it is paid for once.

A write is a root-to-leaf path — 122 words at a thousand entries — and everything off the path is the
previous version, shared. A version is a path; a thousand versions are a thousand paths, not a thousand maps.

### The word-cost calculator (interactive)

A pure function over the two committed figures — 122 words per derived version, 6688 words standalone —
extends the gate's arithmetic to n versions: forest words = 6688 + (n − 1) × 122 against n × 6688 standalone
copies, with the model labelled as the model and the committed pair as its anchor. Buttons select n = 1, 10,
100, 1000; the readout shows both totals and the ratio. Degrades to the static one-row table for the
committed pair.

## References (#refs)

Sources: Steindorfer & Vinju — OOPSLA 2015 (`https://dl.acm.org/doi/10.1145/2814270.2814312`) · Erlang/OTP —
the ets module (`https://www.erlang.org/doc/apps/stdlib/ets.html`).
Related: `/bcs/elixir-core/champ` (B2.3 — the module hub) · `/bcs/elixir-core` (B2 · The Elixir BCS Core) ·
`/bcs/elixir-core/property-stores` (B2.2 — the flat table whose snapshot is a copy-out) · `/elixir` (the
umbrella where `echo_data` lives).

## Pager

Previous: `/bcs/elixir-core/champ/the-forest-and-the-placement-law` — The Forest and the Placement Law. Next:
`/bcs/elixir-core/champ/the-crossover` — The Crossover.
