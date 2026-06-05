# F2.08.3 — Building pipelines (dive)

- Route (served): `/elixir/functional/composition/pipeline`
- File: `elixir/functional/composition/pipeline.html`
- Place in the chapter: the third and closing dive under the `F2.08` composition hub. It follows the pipe operator (`F2.08.2`) and hands forward to the data-pipeline lab (`F2.09`). It belongs to the arc that ends the conceptual half of F2: composition over collections, with `map`/`filter`/`reduce` from `F2.05` as the stages.
- Accent: elixir (purple).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `F2.08 · part 3 of 3`

Hero lede (verbatim):

> A pipeline strings the higher-order functions together: a value enters, each stage transforms it, and the last stage hands back the result. Read top to bottom, the whole transformation is one legible sequence — map to reshape, filter to select, reduce to combine.

Kicker (verbatim):

> This is how most real Elixir reads. The data starts as a collection; each stage is a small, independent step; nothing is mutated, so every intermediate is a value you could inspect. Building a pipeline is choosing the stages and their order — the same composition as before, now over collections.

## Sections

In order:

1. **Stage by stage** (`#stages`) — teaching section. Step through a numeric pipeline one stage at a time: start with a list, triple every element, keep those past nine, then sum what remains; each stage shows the value it produces. Carries a `deflist`: `pipeline` (a sequence of stages a value flows through), `stage` (one step — a map, a filter, a reduce), `intermediate` (the value between two stages; with immutability, always inspectable), `end to end` (from the input collection to the final result).
2. **A string pipeline** (`#strings`) — teaching section. Pipelines are not only for numbers: split a sentence into words, keep the longer ones, upcase them, and join them back — four stages over text.
3. **Worked examples** (`#gallery`) — advanced gallery section. A numeric pipeline, a string pipeline, a counting pipeline, and the shape they all share.

Running example: a numeric pipeline (`map(&1 * 3)` → `filter(> 9)` → `sum`) stepped stage by stage, and a string pipeline (`String.split` → `filter(len ≥ k)` → `map(upcase)` → `join(" ")`) over `"the quick brown fox"`. The real Elixir shown chains `Enum`/`String` functions with `|>`.

## The interactives

### Figure 1 — `map → filter → sum · one stage at a time` (`#stTitle`)
- Control `.fold-ctrl`: range `#stStep` (`stages applied`, `0`–`3`, value `0`), readout `#stStepval` (default `0 of 3`).
- SVG ids: `#stL0`, `#stL1`, `#stV1`, `#stL2`, `#stV2`, `#stL3`, plus the sum box group `#stSumBox`.
- Pure function `renderSt`: reveals the pipeline up to the chosen stage — input `[1, 2, 3, 4, 5, 6]`, `map(&1 * 3)`, `filter(> 9)`, `sum()`.
- Code block `#stCode` shows the pipeline with stages applied so far highlighted.
- Readout `#stOut` (verbatim default): `nothing applied yet · the input is [1, 2, 3, 4, 5, 6]`.

### Figure 2 — `split → filter → upcase → join` (`#srTitle`)
- Control `.fold-ctrl`: range `#srK` (`keep length ≥`, `1`–`5`, value `4`), readout `#srKval`.
- SVG ids: `#srSplit`, `#srFilter`, `#srMap`, `#srJoin`.
- Pure function `renderSr`: over `"the quick brown fox"` — `String.split()`, `filter(len ≥ k)`, `map(upcase)`, `join(" ")`.
- Code block `#srCode` + readout `#srOut` (verbatim default): `keep words ≥ 4 letters · 2 of 4 words kept · "QUICK BROWN"`.

### Figure 3 — Worked examples gallery (`#gSel`)
- Example toggle `#gSel` (`role="group"`): button `data-g="numeric"` `data-c="blue"` `numeric` (active default); `data-g="string"` `data-c="gold"` `string`; `data-g="count"` `data-c="sage"` `count`; `data-g="shape"` `data-c="elixir"` `the shape`.
- Code block `#gCode` + readout `#gOut`. Gallery entries (`GAL`):
  - `numeric` — `1..10` / `|> Enum.map(&(&1 * &1))` / `|> Enum.filter(&(rem(&1, 2) == 0))` / `|> Enum.sum()` / `# => 220`; note `square, keep evens, sum`.
  - `string` — `"a,b,c"` / `|> String.split(",")` / `|> Enum.map(&String.upcase/1)` / `|> Enum.join("-")` / `# => "A-B-C"`; note `split, upcase each, rejoin`.
  - `count` — `~w(a b a c a)` / `|> Enum.frequencies()` / `# => %{"a" => 3, "b" => 1, "c" => 1}`; note `count occurrences in one stage`.
  - `shape` — `data` / `|> transform   # map` / `|> select      # filter` / `|> aggregate   # reduce`; note `the shape under most pipelines`.
- Readout `#gOut` (verbatim default): `numeric · square, keep evens, sum`.

Degrade behaviour: the stage figure starts at `0 of 3` with later SVG lines drawn in near-invisible dim colours until JS (`renderSt`/`renderSr`/`renderG`) drives them on input; defaults are present in static markup. The `.arc-flow` dashed animation is `@media (prefers-reduced-motion: no-preference)` only; reveal-on-scroll (`.reveal`) is JS-gated and collapses to visible under `prefers-reduced-motion: reduce` or when `IntersectionObserver` is absent.

Footer build-stamp: `#stamp` with `#stampId` = `TSK0Nau6DxFUUi`; the decoder (`decodeBranded`, namespace `TSK`, epoch `1704067200000`) populates the panel, whose `#st-ts` default reads `2026-05-31 09:44:28 UTC`.

## References (#refs, verbatim)

This page has no `#refs` References section (no Sources / Related-in-this-course block). Cross-links are carried inline: the `.bridge` cells reference `Idea`, `F2.05 · folds` (`map, filter, and sum are the folds this pipeline is assembled from.`), and `F2.09 · the lab` (`The lab runs a longer pipeline over a real dataset, stage by stage.`); the `Where this goes` close (`#close`) and `.note` name **F2.09 — The data-pipeline lab** and link `/elixir/functional/composition` and `/elixir/functional`.

## Wiring

- route-tag (verbatim): `/` `elixir` `/` `functional` `/` `composition` `/` `pipeline` (the `pipeline` segment is the current `.rcur`).
- crumbs (verbatim): `F2` `/` `F2.08` `/` `pipeline` (the last is `.here`), linking `/elixir/functional` and `/elixir/functional/composition`.
- toc-mini: `#stages` Stage by stage · `#strings` A string pipeline · `#gallery` Worked examples.
- pager: prev → `/elixir/functional/composition/pipe` (`← Part 2 · the pipe`); next → `/elixir/functional/pipeline-lab` (`F2.09 · The data-pipeline lab →`).
- footer: column **Chapters** — `/elixir/algebra` F1 · Algebra, `/elixir/functional` F2 · Functional Programming, `/elixir/language` F3 · The Elixir Language, `/elixir/algorithms` F4 · Algorithms & Data Structures, `/elixir/pragmatic` F5 · Pragmatic Programming, `/elixir/phoenix` F6 · Phoenix Framework. Column **The course** — `/elixir` Course home, `/elixir/course` Contents & history, `/elixir/algebra/functions` Start · F1.01. Foot brand links `/elixir`.
- Page meta — `<title>`: `Building pipelines — F2.08.3 · jonnify`. `<meta description>`: `Composing map, filter, and reduce into a pipeline over a dataset, watching the value transform at each stage.`

## Build instruction

To rebuild this dive, copy the `head…</style>`, the `header.site`, the `footer.site-foot`, and the two trailing `<script>` blocks (the figure renderers `renderSt`/`renderSr`/`renderG` + the Snowflake decoder, then the JS-on / reveal-on-scroll bootstrap) verbatim from a recent BUILT dive on the elixir (purple) accent; change only the `<title>`/`<meta description>`, the header `route-tag` (ending `.rcur` = `pipeline`), the crumbs, and the `<main>` body (eyebrow `part 3 of 3`, hero `.lede`/`.kicker`, the three `<section>` figures, the `Where this goes` close, the pager). The model sibling to copy from is its own sibling dive on this accent — `elixir/functional/composition/pipe.html` (`F2.08.2`, identical dive shell: hero, two teaching figures, a gallery, pager). No-invent guards: this is a mathematics-then-Elixir lesson and does not touch the live Portal product surface — do not invent Portal APIs, and defer OTP/Phoenix internals to the companion chapters (`F5 · Pragmatic`, `F6 · Phoenix`) rather than re-teaching them. Use only the real Elixir surfaces shown (`|>`, `Enum.map`/`Enum.filter`/`Enum.sum`/`Enum.join`/`Enum.frequencies`, `String.split`/`String.upcase`, `rem/2`, `~w` sigil, capture syntax). Voice rules: no first person, no exclamation marks, no emoji, and none of just / simply / obviously.
