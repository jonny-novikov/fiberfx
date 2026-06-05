# F2.05 — map / filter / reduce (folds) (module hub)

- Route (served): `/elixir/functional/folds`
- File: `elixir/functional/folds/index.html`
- Place in the chapter: F2.05 is the folds hub in chapter F2 · Functional Programming. It follows F2.04 (recursion) and frames four deep dives — `map`, `filter`, `reduce`, and `advanced` — that take the three core list operations one at a time and then the wider toolkit they all belong to. It hands off to F2.06 (Closures & partial application).
- Accent: `elixir` (purple) — `--elixir:#b39ddb` / `--elixir-bright:#cdb8f0`.
- Status: built and published; A+ on the nine Apollo gates.

## Lead
Eyebrow (verbatim): `F2 · Functional Programming`

Hero h1 (verbatim): `map / filter / reduce (folds)`

Hero lede (verbatim):

> A fold collapses a list to a single value by threading an accumulator through it, combining one element at a time. `Enum.reduce` is that fold — and it is the one list operation the others are built from.

Kicker (verbatim):

> F2.04 ended on the observation that sum, length, reverse, map, and filter are all the same recursion with a different combiner. This module makes the combiner the subject. Give `reduce` a starting value and a function of `(element, accumulator)`, and it walks the list left to right, replacing the accumulator at each step. Change the combiner and the same machine computes a sum, a product, a maximum, a count — or builds a whole new list, which is how map and filter fall out of it.

## What the page frames
The hub teaches three inline teaching sections, then frames the four dives as full cards (a column of `<a>` cards, not the `.mods`/`.dives` grid). The dive cards:

- F2.05.1 — `map` — "Transform every element with a function — one to one, length and order preserved." — route `/elixir/functional/folds/map` — built.
- F2.05.2 — `filter` — "Keep the elements that pass a predicate — and its inverse, reject, then filter into map." — route `/elixir/functional/folds/filter` — built.
- F2.05.3 — `reduce` — "The general fold — an accumulator of any shape: a number, a list, or a map." — route `/elixir/functional/folds/reduce` — built.
- F2.05.4 — `Advanced folds` — "scan, map_reduce, flat_map, group_by — the Enum toolkit as folds with extra structure." — route `/elixir/functional/folds/advanced` — built.

Inline teaching sections (in order): `How a fold runs` (`#steps`), `Change the combiner` (`#combiner`), `The universal fold` (`#universal`), `Four deep dives` (`#dives`), `What this lands`, and the pager. A `deflist` defines `fold`, `reduce` (`Enum.reduce(list, acc, fun)`), `accumulator`, `combiner`.

## The interactives

### Hero figure — "A left fold · sum [1, 2, 3, 4]"
- `<figure class="hero-fig">` labelled by `#hfTitle` (text `A left fold · sum [1, 2, 3, 4]`).
- Controls: `<button id="hfStep">▸ step</button>` and `<button id="hfReset" class="ghost">reset</button>`.
- SVG ids: list group `#hfList` with `.hf-cell[data-i="0..3"]` over `[1, 2, 3, 4]`; the "next" marker `#hfMark` / `#hfMarkTxt` / `#hfMarkArr` / `#hfMarkHead`; accumulator text `#hfAcc` (seeded `0`); caption `#hfCap`.
- Pure-function logic: `HF_LIST = [1, 2, 3, 4]`, `HF_ACCS = [0, 1, 3, 6, 10]` (running sum after each consumed element); combiner label `acc = acc + x`; `paintCell(i)`/`render(isNew)` recolour cells (done = sage, queued next = gold) and advance the accumulator.
- Initial caption readout (verbatim): `acc = 0 · queued 1` then `Each step folds the next element in: acc = acc + x.` Subsequent steps render `acc = <prev> + <x> = <now>` with `sum: 0 → 1 → 3 → 6 → 10` trail and `· done` at the end.

### Section 1 — "reduce([3, 1, 4, 1], 0, &+/2) · the accumulator threads through" (`#steps`)
- `<figure class="fig">` labelled by `#stepsTitle`.
- Control: range slider `#fdStep` (min 0, max 4) with value label `#fdStepval` (`1 / 5`).
- SVG ids: chip group `#fdChips`, accumulator text `#fdAcc`, combiner line `#fdCombine`, note `#fdNote`. Code block `#fdCode`; readout `#fdOut`.
- Pure-function logic: `LIST = [3, 1, 4, 1]`, `ACCS = [0, 3, 4, 8, 9]`; `renderFold()` chips the current/consumed elements and updates the accumulator.
- Readout strings (verbatim): step 0 → `step 1 · initial accumulator = 0`; otherwise `step <s+1> · <prev> + <elem> · acc = <ACCS[s]>` with ` (result)` at step 4. Code (verbatim): `Enum.reduce([3, 1, 4, 1], 0, fn elem, acc -> acc + elem end)` then `# => 9`.

### Section 2 — "One skeleton, four results · over [3, 1, 4, 1]" (`#combiner`)
- `<figure class="fig">` labelled by `#cmbTitle`.
- Control group `#cmbSel` (role group): `data-k="sum"` (`data-c="sage"`, active) label `sum`; `data-k="product"` (`blue`) `product`; `data-k="max"` (`gold`) `max`; `data-k="count"` (`elixir`) `count`.
- SVG ids: init box `#cmbInitBox` / text `#cmbInit`, combiner box text `#cmbFn`, result `#cmbRes`. Code `#cmbCode`; readout `#cmbOut`.
- Pure-function logic: `CMB` map keyed by combiner → `{init, fn, res, note, code}`. Values: sum (`0`, `fn x, acc -> acc + x end`, `9`); product (`1`, `fn x, acc -> acc * x end`, `12`); max (`0`, `fn x, acc -> max(x, acc) end`, `4`); count (`0`, `fn _, acc -> acc + 1 end`, `4`). Result colours `CMB_COLORS`.
- Default readout (verbatim): `sum · start at 0, add each element · [3, 1, 4, 1] → 9`.

### Section 3 — "map and filter, built from reduce" (`#universal`)
- `<figure class="fig">` labelled by `#uniTitle`.
- Control group `#uniSel`: `data-k="map"` (`data-c="gold"`, active) `map`; `data-k="filter"` (`sage`) `filter`.
- SVG ids: `#uniMapBox`/`#uniMapT`/`#uniEdgeMap`, `#uniFilterBox`/`#uniFilterT`/`#uniEdgeFilter`. Code `#uniCode`; readout `#uniOut`.
- Pure-function logic: `UNI` map keyed by `map`/`filter` → `{code, out}`. The `map` code defines `map(list, f)` as `Enum.reduce(list, [], fn x, acc -> acc ++ [f.(x)] end)` with `map([1, 2, 3], &(&1 * 2))   # => [2, 4, 6]`; the `filter` code defines `filter(list, p)` as a `reduce` appending `acc ++ [x]` when `p.(x)`, with `filter([1, 2, 3], &(rem(&1, 2) == 0))   # => [2]`.
- Default readout (verbatim): `map · reduce with a list accumulator, appending each transformed element · [1, 2, 3] → [2, 4, 6]`.

Degrade behaviour: the hero SVG ships a static initial state in markup (seed `acc = 0` with `[1,2,3,4]` queued, comment: "No render on load: the static SVG already shows the seed"); section figures render once on load via `renderFold()`/`renderCmb()`/`renderUni()`. `.hf-new` entry animation and the `.arc-flow` dash animation are wrapped in `@media (prefers-reduced-motion: no-preference)` and cancelled under `reduce`; `.reveal` is JS-gated and shown immediately when reduced-motion or no `IntersectionObserver`.

Footer build-stamp decoder: id `TSK0NZkbnJkJmq`, decoded timestamp `2026-05-30 17:04:03 UTC` (`#st-ts`). The decoder (`decodeBranded`) splits the 3-char namespace `TSK`, b62-decodes the rest, and extracts snowflake/node/seq using `EPOCH_MS = 1704067200000`.

## References (#refs, verbatim)
This page has no `#refs` References block — there is no Sources or "Related in this course" section in the markup. The synthesis closes with a `.note` that links forward to the four dives and `F2.06 — Closures & partial application`; the footer carries the standard chapter and course links (listed under Wiring).

## Wiring
- route-tag (verbatim): `/ elixir / functional / folds` — `<a href="/elixir">elixir</a>` · `<a href="/elixir/functional">functional</a>` · `<span class="rcur">folds</span>`.
- crumbs (verbatim): `F2 · Functional` (`/elixir/functional`) / `F2.04` (`/elixir/functional/recursion`) / `F2.05` (here).
- toc-mini: `#steps` "How a fold runs"; `#combiner` "Change the combiner"; `#universal` "The universal fold"; `#dives` "Four deep dives".
- pager: prev → `/elixir/functional/recursion/patterns` "F2.04 · patterns"; next → `/elixir/functional/folds/map` "Start · map".
- footer: column "Chapters" — `/elixir/algebra` F1 · Algebra, `/elixir/functional` F2 · Functional Programming, `/elixir/language` F3 · The Elixir Language, `/elixir/algorithms` F4 · Algorithms & Data Structures, `/elixir/pragmatic` F5 · Pragmatic Programming, `/elixir/phoenix` F6 · Phoenix Framework. Column "The course" — `/elixir` Course home, `/elixir/course` Contents & history, `/elixir/algebra/functions` Start · F1.01.
- Page meta — `<title>` (verbatim): `map / filter / reduce (folds) — F2.05 · jonnify`. `<meta name="description">` (verbatim): `reduce as the universal fold: how the accumulator threads through a list, how swapping the combiner changes the result, and how map and filter are reduce with a list accumulator.`

## Build instruction
To rebuild this hub, copy the `<head>…</style>`, the `<header class="site">`, the `<footer class="site-foot">`, and the two trailing `<script>` blocks verbatim from a recent BUILT sibling on the elixir (purple) accent; change only the `<title>`/`<meta description>`, the `route-tag` segments, and the `<main>` body. Keep the chapter accent tokens (`--elixir`/`--elixir-bright`) and the snowflake decoder unchanged. No-invent guards: when describing the Elixir surface, use only the real functions shown here — `Enum.reduce/3` (left fold, tail-recursive), `Enum.map`, `Enum.filter`; do not introduce Portal store / event-sourced engine surfaces (this is an F2 page, not F5/F6) and cite the companion course for OTP internals rather than re-teaching them. Voice rules: no first person, no exclamation marks, no emoji, and none of "just", "simply", or "obviously". Model sibling to copy from: `elixir/functional/folds/reduce.html` (same chapter, same accent, dive shell) or the F2 chapter landing `elixir/functional/index.html`.
