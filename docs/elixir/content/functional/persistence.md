# F2.02 — Immutability & persistent data (dive)

- Route (served): `/elixir/functional/persistence`
- File: `elixir/functional/persistence.html`
- Place in the chapter: the second module of F2 · Functional Programming and its Foundations movement. It follows F2.01 · Pure functions and supplies the mechanism that makes purity affordable — structural sharing — before F2.03 turns to the verbs (higher-order functions) that act on these values.
- Accent: chapter accent `elixir` (purple — `--elixir`/`--elixir-bright`).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F2 · Functional Programming`

H1 (verbatim): `Immutability & persistent data`

Hero lede (verbatim):

> Immutable data never changes in place. An "update" returns a new value and leaves the old one intact. The obvious worry is cost — but the new value shares almost everything with the old, so copying is cheap.

Kicker line (verbatim):

> F2.01 needed immutability for purity: if a function could mutate your data, calling it would be an effect. F1.04 introduced binding without mutation. Here is the mechanism that makes it affordable. A persistent data structure preserves its previous versions; updating one builds only the parts that change and **shares** the rest. Prepending to a list is one new cell; updating a map rebuilds one path through a tree. The old version stays valid, which is why immutable values can be passed freely between functions and processes.

## Sections

In order, three teaching sections (each closes with a `.bridge` and a `.take`), then a synthesis:

1. `#list` — "Sharing a list". An Elixir list is a chain of cons cells; prepending `[0 | list]` makes one new cell and shares the tail, while appending rebuilds the spine. Carries a `deflist` defining `immutable`, `structural sharing`, `persistent`, `cons cell`. Running example: `list = [10, 20, 30]`, prepend vs append.
2. `#map` — "Updating a map". A map is held as a tree; updating one key rebuilds only the path from root to that key (depth ≈ `log₂ n`) and shares the other subtrees. Running example: `Map.put` on keys `:a`–`:d`.
3. `#cost` — "Why copying is cheap". Full copy is linear (`n` cells) vs structural sharing (`≈ log₂ n` cells); the gap widens with size. Running example: a size slider `n` from 4 to 64.
4. Synthesis "What this lands", then the pager.

Real Elixir shown across the sections (verbatim): `[0 | list]`, `list ++ [40]`, `[head | tail]`, `Map.put(m, :a, …)`, `Map.put/3`; the worked list is `[10, 20, 30]`.

## The interactives

### Figure 1 — Prepend vs append · what gets built
- `<figure>` title (verbatim `<h4 id="listTitle">`): `Prepend vs append · what gets built`.
- Control group `#listSel` (`role="group"`), two buttons (`data-op`): `prepend` `data-c="sage"` (active by default) label `[0 | list]`; `append` `data-c="elixir"` label `list ++ [40]`.
- SVG element ids: `#listChain` (the rendered cons-cell chain); plus `#listCode` and `#listOut` readouts (`aria-live="polite"`).
- Pure function: the section script renders the cons-cell chain over `[10, 20, 30]`, marking new vs shared cells, and writes the code + readout for the chosen op.
- Readout (verbatim default `#listOut`): `[0 | list] · 1 new cell · 3 shared · O(1)` (the `1` in `--gold-bright`, the `3` in `--sage-bright`).

### Figure 2 — Map.put · rebuild the path, share the rest
- `<figure>` title (verbatim `<h4 id="mapTitle">`): `Map.put · rebuild the path, share the rest`.
- Control group `#mapSel` (`role="group"`), four buttons (`data-key`), all `data-c="gold"`: `a` (active) label `put :a`; `b` label `put :b`; `c` label `put :c`; `d` label `put :d`.
- SVG element ids: `#mapEdges` (tree edges), `#mapNodes` (tree nodes), with static legend labels `rebuilt` (gold) and `shared` (sage); plus `#mapCode` and `#mapOut` readouts.
- Pure function: the section script draws the map as a tree and, for the chosen key, recolours the root-to-key path as rebuilt and the rest as shared, writing the code + readout.
- Readout (verbatim default `#mapOut`): `Map.put(m, :a, …) · 3 nodes rebuilt · 4 shared · O(log n)` (the `3` in `--gold-bright`, the `4` in `--sage-bright`).

### Figure 3 — One update · cells built
- `<figure>` title (verbatim `<h4 id="costTitle">`): `One update · cells built`.
- Control: a `.fold-ctrl` slider `#costN` (`min=4 max=64 step=4 value=32`) with value label `#costNval` (default `32`).
- SVG element ids: `#barNaive`/`#barNaiveT` (the full-copy bar, burgundy), `#barShare`/`#barShareT` (the sharing bar, sage); readout `#costOut` (`aria-live="polite"`).
- Pure function: the section script sizes the two bars from `n` — full copy ≈ `n` cells, structural sharing ≈ `log₂ n` cells — and writes the readout.
- Readout (verbatim default `#costOut`): `n = 32 · full copy ≈ 32 cells · structural sharing ≈ 6 cells` (the `32` in `#e08f8b`, the `6` in `--sage-bright`).

### Bridge cell (`#cost` section)
- `F0.2 · the BEAM` → `F2 · Functional`. The BEAM cell (verbatim): "Processes share nothing and pass immutable data — safe because no one can mutate it."

### Degrade behaviour
Each figure renders its static default in the markup (the active button + the verbatim default readouts above), so the lesson reads without JS. `html.js .reveal` is JS-gated; `prefers-reduced-motion: reduce` disables the reveal transition; `scroll-behavior` falls back to `auto` under reduced motion.

### Footer build-stamp decoder
- Stamp id (verbatim `#stampId`): `TSK0NZZy2xJuaG`.
- Decoded UTC timestamp (verbatim `#st-ts`): `2026-05-30 14:35:09 UTC`.
- `decodeBranded` splits the `TSK` namespace from the base-62 Snowflake (`EPOCH_MS = 1704067200000`) and fills the panel rows; toggles open on click/Enter/Space.

## References (#refs, verbatim)

This page has no `#refs` References block — no intro line, no Sources list, and no "Related in this course" list are present in the markup. The cross-links it carries are inline: the `.bridge` cells cite `Idea`, `Elixir`, and `F0.2 · the BEAM`; the synthesis and `.note` point back to F2.01 / F0.2, forward to F2.03, and to `/elixir/functional` (the F2 overview).

## Wiring

- route-tag (verbatim): `/ ` `elixir` `/ ` `functional` `/ ` `persistence` (`<a href="/elixir">elixir</a>`, `<a href="/elixir/functional">functional</a>`, `<span class="rcur">persistence</span>`).
- crumbs (verbatim): `F2 · Functional` → `/elixir/functional` / `F2.01` → `/elixir/functional/pure` / `F2.02` (`here`).
- toc-mini (`.toc-mini`, in-page anchors): `Sharing a list` → `#list`; `Updating a map` → `#map`; `Why copying is cheap` → `#cost`.
- pager: prev → `/elixir/functional/pure` label `← F2.01 · pure functions`; next → `/elixir/functional` label `More in F2 · Functional →`.
- footer columns (verbatim): identical to the chapter hub — foot-brand `jonnify` → `/elixir` with the "functional thinking taught twice" tagline; Chapters `F1 · Algebra`/`F2 · Functional Programming`/`F3 · The Elixir Language`/`F4 · Algorithms & Data Structures`/`F5 · Pragmatic Programming`/`F6 · Phoenix Framework` → `/elixir/algebra`/`/elixir/functional`/`/elixir/language`/`/elixir/algorithms`/`/elixir/pragmatic`/`/elixir/phoenix`; The course `Course home`/`Contents & history`/`Start · F1.01` → `/elixir`/`/elixir/course`/`/elixir/algebra/functions`.
- Page meta:
  - `<title>` (verbatim): `Immutability & persistent data — F2.02 · jonnify`
  - `<meta name="description">` (verbatim): `Why copying is cheap: immutable values, structural sharing in lists and maps, and the memory cost of a full copy versus rebuilding only what changed.`

## Build instruction

To (re)build this page, copy the `<head>…</style>`, the `header.site`, the `footer.site-foot`, and the trailing `<script>` blocks verbatim from a recent BUILT sibling on this chapter accent — the model sibling is `elixir/functional/pure.html` (the previous F2 leaf: same three-section hero/`toc-mini`/`bridge`/`take`/`deflist` anatomy and the same footer). Change only the `<title>`/`<meta name="description">`, the `route-tag`, the crumbs, and the `<main>` body (hero, the `#list`/`#map`/`#cost` figures and their data, and the synthesis). Keep the `elixir` purple accent on the append/list controls, gold on the `Map.put` keys, sage on shared/cheap markers, and keep the stamp decoder verbatim. No-invent guards: cite only the real Elixir surfaces as written (`[head | tail]`, `Map.put/3`, the cons-cell list model) and the real course routes; if later editions reach the F5/F6 platform, name only the real Portal surfaces as written — the branded store, the event-sourced engine behind ONE `Portal` facade, the Phoenix web app — and cite the companion course for OTP/BEAM internals rather than re-teaching them; do not invent a readout string, complexity claim, code token, or route. Voice rules: no first person, no exclamation marks, no emoji, and none of "just"/"simply"/"obviously".
