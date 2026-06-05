# F2.09 — The data-pipeline lab (lab)

- Route (served): `/elixir/functional/pipeline-lab`
- File: `elixir/functional/pipeline-lab/index.html`
- Place in the chapter: the capstone single-page lab of `F2 · Functional Programming`. It closes the chapter that begins with the leaf pages `F2.01 pure` / `F2.02 persistence` / `F2.03 higher-order` and the hub modules `F2.04 recursion` / `F2.05 folds` / `F2.06 closures` / `F2.07 adt` / `F2.08 composition`, drawing every chapter idea into one configurable pipeline over a dataset. It is the next page after `F2.08 · composition`'s `pipeline` dive and returns the reader to the `F2` overview.
- Accent: elixir (purple), `--elixir:#b39ddb` / `--elixir-bright:#cdb8f0`.
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F2 · Functional Programming · the lab`

H1 (verbatim): `The data-pipeline lab`

Hero lede (verbatim):

> The capstone of the chapter. Take a small dataset and build a pipeline over it — select rows, transform them, order them, then reduce them to an answer. Each stage shows the rows it produces, and the configuration writes the idiomatic Elixir it stands for.

Kicker (verbatim):

> Every idea from F2 meets here. Each stage is a *pure function* of the rows before it (F2.01); each intermediate is a new *immutable* value, never an edit of the last (F2.02); every stage takes a *function* as its argument (F2.03); map, filter, and reduce are the *folds* (F2.05); and the pipe *composes* them into one expression (F2.08). Configure the four stages below and read the result, the rows, and the code together.

## Sections

This is a single-page lab, not a hub: it carries no `.mods`/`.dives` card list. The teaching arc is three in-page sections plus the hero figure.

1. Hero — `The data-pipeline lab`: the lede and kicker, plus the hero figure `One record through the pipeline` (a vertical four-stage SVG pipeline run one record at a time).
2. `#lab` — `The lab`: the working surface. A `deflist` defines the vocabulary, then the four-stage interactive figure runs the configured pipeline over the dataset.
   - `deflist` terms (verbatim): `pipeline` — "a sequence of stages a dataset flows through."; `stage` — "one pure step — filter, map, sort, or reduce."; `immutable intermediate` — "the rows between two stages; a new value, always inspectable."; `aggregation` — "the reduce that collapses many rows into one answer."
   - Takeaway (verbatim): "A pipeline is composition over data: each stage a pure function of the rows before it, the whole chain a single expression you can read top to bottom."
3. `#bridge` — `The whole chapter, in one expression`: the synthesis `bridge` (idea cell -> Elixir cell) closing F2 and pointing forward to F3.
   - Bridge idea cell (verbatim): "Describe a result as a series of transformations of data, not as steps that mutate it."
   - Bridge Elixir cell (verbatim): "A pipe of `Enum` calls: filter, map, sort, reduce — each pure, each composable."
   - Closing note (verbatim): "That completes **F2 · Functional Programming** — nine modules from pure functions to pipelines. Next chapter: **F3 — The Elixir Language**. Revisit the F2 overview to see the full journey, or the composition module that leads here." (links to `/elixir/functional` and `/elixir/functional/composition`).

The running example is a fixed dataset of eight products (`name`, `price`, `category`, `rating`): Keyboard `$80 ★4 :gear`, Mouse `$25 ★5 :gear`, Monitor `$300 ★4 :gear`, Desk `$220 ★3 :home`, Lamp `$40 ★5 :home`, Chair `$180 ★4 :home`, Notebook `$6 ★5 :office`, Pen `$2 ★3 :office`.

The real Elixir shown is the generated pipeline (id `labCode`), emitted by `genCode`. It starts from `products` and conditionally appends only the active stages: `|> Enum.filter(fn p -> … end)` (conjoining `p.category == :<cat>` and/or `p.rating >= <minR>`), `|> Enum.map(fn p -> %{p | price: round(p.price * <0.9|0.75>)} end)`, `|> Enum.sort_by(& &1.price, :desc)` / `(& &1.price, :asc)` / `(& &1.rating, :desc)` / `(& &1.name)`, and a final reduce: `|> Enum.map(& &1.price) |> Enum.sum()` (sum), `|> Enum.count()` (count), `|> Enum.group_by(& &1.category) |> Map.new(fn {k, v} -> {k, length(v)} end)` (by category), or `|> Enum.max_by(& &1.price)` (top price). The neutral `keep list` setting appends nothing.

## The interactives

### Hero figure — `One record through the pipeline` (`figcaption` id `hpTitle`)

A vertical pipeline SVG (`viewBox="0 0 320 360"`) with five `hp-stage` groups stacked on a flow spine: `hpSource` (label `SOURCE`, the static record `"Mouse,25,gear,5"`), `hpParse` (`PARSE`, `String.split |> to struct`), `hpFilter` (`FILTER`, `keep when rating >= 4`), `hpMap` (`MAP`, `price × 0.9 (discount)`), and `hpSink` (`COLLECT`, readout id `hpSinkTxt`, initial `[ ] — waiting`). A moving record chip `hpToken` (text id `hpTokenTxt`) rides the spine.

- Controls (no `data-key` set; two id'd buttons): `hpRun` initial label `▸ run one record` (advances one stage per click: relabels `▸ advance stage`, then `↻ run again` at the end); `hpReset` label `reset`.
- Caption (id `hpCap`, `aria-live="polite"`) initial (verbatim): record line `"Mouse,25,gear,5"`; stage line `At the source — run it through parse → filter → map → collect.`
- The four advance steps set caption record/stage lines verbatim:
  - PARSE: rec `%{name: "Mouse", price: 25, cat: :gear, rating: 5}`; stg `PARSE — the line splits into a typed record.`
  - FILTER: rec `%{name: "Mouse", price: 25, cat: :gear, rating: 5}`; stg `FILTER — rating 5 passes the test; the record is kept.` (token chip `rating 5 ≥ 4`)
  - MAP: rec `%{name: "Mouse", price: 23, cat: :gear, rating: 5}`; stg `MAP — price × 0.9 yields a new record; the old one is untouched.` (token chip `price 25 → 23`)
  - COLLECT: rec `[%{name: "Mouse", price: 23, ...}]`; stg `COLLECT — the kept, transformed record lands in the accumulator.`; sets `hpSinkTxt` to `[%{name: "Mouse", ...}]` (token chip `collected`).
- Pure functions: `clearLit` / `setToken` / `show` / `resetState` drive the step machine; no row computation — the hero is a fixed walkthrough.

### Lab figure — `products |> filter |> map |> sort |> reduce` (`figcaption` id `labTitle`)

Four stage panels, each a control group, plus the dataset chip strip (id `dsChips`), the generated pipeline `<pre>` (id `labCode`, `aria-live="polite"`), the funnel SVG (`<g id="funnel">`, `viewBox="0 0 720 250"`), and the readout (id `labOut`).

- `filter` stage — `Enum.filter/2` (count id `cntFilter`, output id `outFilter`):
  - control group `flCat` (role group "Filter by category") — buttons `data-k="all"` label `all` (active default), `data-k="gear"` label `:gear`, `data-k="home"` label `:home`, `data-k="office"` label `:office`.
  - range `flRating` (`min=1 max=5 step=1 value=1`, value readout id `flRatingval`), label `rating ≥`.
- `map` stage — `Enum.map/2` (count id `cntMap`, output id `outMap`):
  - control group `mpDisc` (role group "Transform the price") — `data-k="none"` label `no change` (active default), `data-k="d10"` label `price −10%`, `data-k="d25"` label `price −25%`.
- `sort` stage — `Enum.sort_by/3` (count id `cntSort`, output id `outSort`):
  - control group `srMode` (role group "Sort the rows") — `data-k="none"` label `unsorted` (active default), `data-k="price_desc"` label `price ↓`, `data-k="price_asc"` label `price ↑`, `data-k="rating_desc"` label `rating ↓`, `data-k="name_asc"` label `name A–Z`.
- `reduce` stage — `Enum.reduce · sum · count · group_by` (count id `cntReduce`, output id `outReduce`):
  - control group `rdAgg` (role group "Aggregate the rows") — `data-k="list"` label `keep list` (active default), `data-k="sum"` label `sum price`, `data-k="count"` label `count`, `data-k="cat"` label `by category`, `data-k="top"` label `top price`.

Pure functions and what they compute:
- `compute()` — reads the four selections (`sel`) and the rating range, clones the dataset, conditionally applies filter / map (factor `0.9` for `d10`, `0.75` for `d25`, `Math.round` on price) / sort, then folds to the chosen aggregation; returns the stage list, the current rows, and the result.
- `genCode(s)` — emits the idiomatic Elixir pipeline string for the active stages (see Sections).
- `renderFunnel(s)` — draws one bar per stage scaled by row count (`(n/8)*360`) with the per-stage row-count label, then the elixir reduce bar with the headline.
- `chip` / `chipRow` / `catText` / `render` — render the per-stage row chips, the category breakdown, and the readout.

Count-readout strings (verbatim): `cntFilter` -> `→ <n> rows` when active else `all rows pass`; `cntMap` -> `→ prices changed` else `no change`; `cntSort` -> `→ <sort label>` else `unsorted`; `cntReduce` -> `keeps the list` (list), `→ one value` (sum/count/top), or `→ a map` (by category). Empty filter output (verbatim): `empty — no rows pass`. Inactive stage output (verbatim): filter/map `not applied — rows pass through`; sort `not applied — order kept`.

Funnel stage labels (verbatim, `LBL`): `dataset`, `after filter`, `after map`, `after sort`; reduce row label `reduce`. Sort labels (`SORTLBL`): `price ↓`, `price ↑`, `rating ↓`, `name A–Z`.

Readout (id `labOut`) format (verbatim): the dash-joined active-stage chain (e.g. `filter(:gear, ★≥4) → map(−10%) → sort(price ↓) → sum prices`) then `· <bold headline>`; neutral configuration reads `identity · 8 rows`. The default-state markup ships `identity · 8 rows`.

Degrade behaviour: the hero SVG ships its static initial state in markup (the record sits at `SOURCE`, `hpToken` `opacity="0"`, sink reads `[ ] — waiting`) — no JS run on load; with JS the step machine animates the token (`transition` on `.hp-token`, `hpPulse` on the lit stage) and is disabled under `@media (prefers-reduced-motion: reduce)` (token transition `none`, smooth-scroll off). The lab figure's controls require JS; with JS off the static dataset strip and empty stage outputs remain readable. The `.reveal` scroll animation is JS-gated and disabled under reduced motion.

Footer build-stamp decoder: stamp id `TSK0Nb1VSTYsm8`; the inline `decodeBranded` (base62, epoch `1704067200000`) splits the `TSK` namespace from the snowflake and decodes the timestamp the markup pre-prints — `2026-05-31 11:28:07 UTC`.

## References (#refs, verbatim)

This page has no `#refs` References section. There is no Sources block and no "Related in this course" block on the page. The only in-prose cross-links are in the closing `#bridge` note: `/elixir/functional` (the F2 overview) and `/elixir/functional/composition` (the composition module that leads here).

## Wiring

- route-tag (verbatim): `/ elixir / functional / pipeline-lab` — markup `<span class="rsep">/</span><a href="/elixir">elixir</a><span class="rsep">/</span><a href="/elixir/functional">functional</a><span class="rsep">/</span><span class="rcur">pipeline-lab</span>`.
- crumbs (verbatim): `F2 · Functional` (`/elixir/functional`) · `/` · `F2.08` (`/elixir/functional/composition`) · `/` · `F2.09 · lab` (here).
- toc-mini (verbatim): `The lab` (`#lab`), `The whole chapter` (`#bridge`).
- pager: prev -> `/elixir/functional/composition/pipeline` label `← F2.08 · building pipelines`; next -> `/elixir/functional` label `F2 complete · the journey →`.
- footer columns and links (verbatim):
  - foot-brand: logo -> `/elixir`; tag "Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir."
  - `Chapters`: `F1 · Algebra` (`/elixir/algebra`), `F2 · Functional Programming` (`/elixir/functional`), `F3 · The Elixir Language` (`/elixir/language`), `F4 · Algorithms & Data Structures` (`/elixir/algorithms`), `F5 · Pragmatic Programming` (`/elixir/pragmatic`), `F6 · Phoenix Framework` (`/elixir/phoenix`).
  - `The course`: `Course home` (`/elixir`), `Contents & history` (`/elixir/course`), `Start · F1.01` (`/elixir/algebra/functions`).
  - foot-bar: `© jonnify`; build stamp `TSK0Nb1VSTYsm8`.
- Page meta:
  - `<title>` (verbatim): `The data-pipeline lab — F2.09 · jonnify`
  - `<meta name="description">` (verbatim): `The F2 capstone: compose filter, map, sort, and reduce stages over a dataset, watch the rows transform at each stage, and read the idiomatic Elixir pipeline the configuration generates.`

## Build instruction

To rebuild this page, copy the head through `</style>`, the `header.site`, the `footer.site-foot`, and the trailing `<script>` blocks verbatim from a recent built sibling on the F2 elixir-purple accent, then change only the `<title>`/`<meta name="description">`, the `route-tag` segments, and the `<main>` body. This is a single-page lab, so the model sibling is its leading module `elixir/functional/composition/pipeline/index.html` (`/elixir/functional/composition/pipeline`, the same elixir accent and pipe vocabulary that flows directly into this capstone); for the dataset-chip / stage-panel / funnel CSS additions and the second `<script>` lab engine, this page is its own canonical exemplar — the `stage`/`ds-chip`/`cat-row` styles live in the second inline `<style>` block. Keep the elixir tokens (`--elixir:#b39ddb` / `--elixir-bright:#cdb8f0`) and the per-stage accent map (filter blue, map sage, sort gold, reduce elixir). No-invent guards: use only the real Portal surfaces as written — the branded store, the event-sourced engine behind one Portal facade, and the Phoenix web app — and cite the companion course for OTP internals rather than re-teaching them; the Elixir shown here is plain `Enum`/`Map` pipeline code, so do not introduce Portal APIs this lab does not use. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously.
