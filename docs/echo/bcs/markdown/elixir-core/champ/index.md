# B2.3 · The CHAMP Property Database — a snapshot is a structure, not a copy

> Route: `/bcs/elixir-core/champ` (module hub, B2.3). The route-mirror source-of-record. Teaches
> `content/bcs2.3.md`; every figure verbatim from the committed `bcs_rung_2_3_check.out` (`PASS 7/7`).
> Build stamp: `BCS0Nuxm8X2IgC`.

## Hero

Kicker: `B2.3 · THE CHAMP PROPERTY DATABASE — manuscript chapter 2.3`. Title: **A snapshot is a structure,
not a copy.** Lede — Chapter 2.2's stores own the present perfectly; the desk asks questions in other tenses —
*what did the book look like at 14:30*, *show me the portfolio as-of yesterday's close*, *fork this risk
scenario and mutate the copy*. The CHAMP forest is the BEAM-native answer: structural sharing as the snapshot
mechanism, the contract hash as the trie's placement function, and the part preface's guideline cashed here
with words counted. Heronote — the chapter is `content/bcs2.3.md`; the implementation is the Operator's
production drop — three modules, 1,458 lines, delivered on June 7 — integrated under review with one gated
amendment; the rung is bcs2.3 and its committed transcript closes `PASS 7/7`.

### The seven gates, mapped to the dives (interactive SVG)

Seven gates in transcript order. Select a gate to read its verbatim line and the dive that teaches it:

- **H1** — `placement delegated to the contract hash: compute_hash_int -> BrandedId.hash32; reference
  snowflake round-trips` → dive 1, The Forest and the Placement Law.
- **H2** — `the old snapshot is intact: v1 holds 1000, v2 holds 1001, and v1 cannot see the new row` → dive 2,
  Sharing at the Honest Metric.
- **H3** — `structural sharing measured: v2 costs 122 words beside v1 (one path copy) against 6688 standalone
  -- 98% of v2 is shared with v1` → dive 2.
- **H4** — `two kinds, one forest: namespace_size AST=500 ORD=500 from the cached census, partition exact` →
  dive 3, The Crossover.
- **H5** — `by-snowflake 1858 ns/op vs string-id 2344 ns/op over 20000 puts` → dive 3.
- **H6** — `at 20000 rows -- build: champ 41 ms vs ets 7 ms; point read: champ 799 ns vs ets 315 ns; snapshot:
  1000 champ snapshots in 90 us (a snapshot is a binding) vs one ets copy-out in 2540 us` → dive 3.
- **H7** — `read scale-out: 10000 server calls 28 ms vs snapshot-once-then-pure 8 ms (copy cost included)` →
  dive 3.

Degrades to a static labelled diagram without JavaScript.

## §1 · Why — the tenses the flat table cannot serve (#why)

Source: `content/bcs2.3.md` · Why. The moment history or hypotheticals become product features, every answer
from the flat table is a snapshot, and a snapshot of an ETS table is a copy-out priced per row. Structural
sharing is the BEAM-native alternative — the immutable heap was built for exactly this. Four cards:

- **THE DROP** — the production-drop pattern returns in its original direction: three modules, 1,458 lines,
  delivered on June 7, integrated under review — and the review earned its keep.
- **THE AMENDMENT** — the drop's placement hash was a one-round mix; it now delegates to the contract's
  `hash32` — one placement law, in-process too. Gated by H1.
- **THE HONEST METRIC** — the first sharing metric capped near fifty and failed a correct implementation;
  marginal cost is the metric of record. Gated by H2 and H3.
- **THE CROSSOVER** — both directions measured, neither hidden: the flat table wins the present, the forest
  wins history. Gated by H4–H7.

## §2 · The proof (#proof)

The full committed transcript (`content/bcs2.3.md`, quoting `bcs_rung_2_3_check.out`), verbatim — the
`[debug]` boot line stays because the drop logs its starts, and the record keeps the drop's voice:

```text
H1 canon ok -- placement delegated to the contract hash: compute_hash_int -> BrandedId.hash32; reference snowflake round-trips
H2 persist ok -- the old snapshot is intact: v1 holds 1000, v2 holds 1001, and v1 cannot see the new row
H3 sharing ok -- structural sharing measured: v2 costs 122 words beside v1 (one path copy) against 6688 standalone -- 98% of v2 is shared with v1
H4 forest ok -- two kinds, one forest: namespace_size AST=500 ORD=500 from the cached census, partition exact
H5 hotpath ok -- by-snowflake 1858 ns/op vs string-id 2344 ns/op over 20000 puts
H6 crossover ok -- at 20000 rows -- build: champ 41 ms vs ets 7 ms; point read: champ 799 ns vs ets 315 ns; snapshot: 1000 champ snapshots in 90 us (a snapshot is a binding) vs one ets copy-out in 2540 us

07:31:13.583 [debug] ChampServer started with 0 entries
H7 server ok -- read scale-out: 10000 server calls 28 ms vs snapshot-once-then-pure 8 ms (copy cost included)
PASS 7/7
```

The integrated modules live at `runtimes/elixir/lib/echo_data/champ/` — `branded_champ.ex`, `champ_node.ex`,
`champ_server.ex` — with the drop's provenance and the single amendment recorded in the source comment. The
documented surface: `put/3`, `fetch/2`, the `*_by_snowflake` family, `get_namespace/2`, `namespace_size/2`,
`get_champ/1`. Boundaries, as the manuscript states them: writes serialize through the owning process;
chronological reads over the forest are a sort or a sibling index; no disk persistence; GC interplay under
heavy version churn is real and unmeasured here. The BCS-grade shell — namespace-scoped, `Bcs.gate` at every
call, typed errors — is the carried integration rung, not a patch smuggled into the drop.

## §3 · The dives (#dives)

- **The Forest and the Placement Law** (`the-forest-and-the-placement-law`) — H1: the namespace→trie forest
  keyed by the snowflake integer; `compute_hash_int -> BrandedId.hash32` — one placement law, in-process too;
  the two-bitmap CHAMP node (datamap/nodemap, popcount-indexed, 5-bit fragments).
- **Sharing at the Honest Metric** (`sharing-at-the-honest-metric`) — H2: `v1 holds 1000, v2 holds 1001`, the
  new row absent from v1; H3: 122 words beside v1, 98% shared, against 6688 standalone; the denominator trap.
- **The Crossover** (`the-crossover`) — H4–H7: the forest census, the by-snowflake hot path, the crossover
  stated plainly in both directions, chronology lost to hash order, the snapshot-out pattern, the tense
  litmus.

Booknote: Part II continues past this module — **Archetypes and Composition** (B2.4) composes definitions at
read time by a pure fold, and **Relations Are Systems** (B2.5) promotes edges to systems.

## References (#refs)

Sources: Steindorfer & Vinju — Optimizing Hash-Array Mapped Tries for Fast and Lean Immutable JVM Collections,
OOPSLA 2015 (`https://dl.acm.org/doi/10.1145/2814270.2814312`) · Erlang/OTP — the ets module
(`https://www.erlang.org/doc/apps/stdlib/ets.html`).
Related: `/bcs/elixir-core` (B2 · The Elixir BCS Core) · `/bcs/elixir-core/property-stores` (B2.2 — the flat
table the crossover measures against) · `/bcs/elixir-core/archetypes` (B2.4 — the snapshot lane resolving
against this forest) · `/bcs/elixir-core/relations` (B2.5 — the next promotion: edges under their own owner) ·
`/redis-patterns` (the substrate door) · `/elixir` (the umbrella where `echo_data` lives).

## Pager

Previous: `/bcs/elixir-core` — B2 · The Elixir BCS Core. Next:
`/bcs/elixir-core/champ/the-forest-and-the-placement-law` — The Forest and the Placement Law.
