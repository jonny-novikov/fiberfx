# F2.05.3 — reduce (dive)

- Route (served): `/elixir/functional/folds/reduce`
- File: `elixir/functional/folds/reduce.html`
- Place in the chapter: Third of the four F2.05 deep dives (part 3 of 4). It takes `reduce` as the general fold the others are built from — the accumulator can be any shape — between `filter` and `advanced`. Belongs to the folds teaching arc.
- Accent: `elixir` (purple).
- Status: built and published; A+ on the nine Apollo gates.

## Lead
Eyebrow (verbatim): `F2.05 · part 3 of 4`

Hero h1 (verbatim): `reduce`

Hero lede (verbatim):

> Reduce is the general fold — the one map and filter are built from. Its power is that the accumulator can be any shape. A number gives you a sum; a list lets you rebuild the collection; a map lets you tally or index it.

Kicker (verbatim):

> The hub showed reduce collapsing a list to a number. The accumulator does not have to stay a number. Start it as an empty list and reduce builds a list; start it as an empty map and reduce builds a map. The combiner decides how each element folds into whatever the accumulator is.

## Sections
In order:

1. `Accumulators of any shape` (`#shapes`) — teaching. A `deflist` defines `reduce`, `accumulator`, `initial value`, `reducer` (`fn element, acc -> new_acc end`). Bridge to `F2.05 · universal` (a list accumulator is how map and filter fall out of reduce).
2. `Build a map` (`#freq`) — teaching. A frequency tally over `[:a, :b, :a, :c, :a]` from `%{}` using `Map.update(acc, key, 1, &(&1 + 1))`. Bridge to `Enum.frequencies/1` (this exact fold, packaged).
3. `Worked examples` (`#gallery`) — advanced/gallery. Four reduces, four accumulator shapes: a number, a tuple, a map, and an early exit.

Real Elixir code shown (verbatim across the interactives):
- Shapes: number/list/map accumulator forms of `Enum.reduce` over `[3, 1, 4]` (number `# => 8`).
- Frequency fold: `reduce([:a, :b, :a, :c, :a], %{}, …)` with `Map.update(acc, x, 1, &(&1 + 1))`.
- Gallery: `Enum.reduce([3, 1, 4], 0, &+/2)   # => 8`; `Enum.reduce([3, 1, 4], {99, 0}, fn x, {lo, hi} -> {min(lo, x), max(hi, x)} end)   # => {1, 4}`; `Enum.reduce([:a, :b, :a], %{}, fn x, acc -> Map.update(acc, x, 1, &(&1 + 1)) end)   # => %{a: 2, b: 1}`; `Enum.reduce_while([1, 2, 3, 4], 0, fn x, acc -> if acc + x > 5, do: {:halt, acc}, else: {:cont, acc + x} end)   # => 3  (stops before exceeding 5)`.

## The interactives

### Section 1 — "One reduce, three accumulator types" (`#shapes`)
- `<figure class="fig">` labelled by `#shTitle`.
- Control group `#shSel`: `data-k="number"` (`data-c="sage"`, active) `a number`; `data-k="list"` (`blue`) `a list`; `data-k="map"` (`gold`) `a map`.
- SVG ids: type box `#shTypeBox` / text `#shType`, init `#shInit`, result `#shRes`. Code `#shCode`; readout `#shOut`.
- Pure-function logic: each key selects the accumulator type, initial value, combiner, and result type.
- Default readout (verbatim): `a number · start at 0, add each element · [3, 1, 4] → 8`.

### Section 2 — "reduce([:a, :b, :a, :c, :a], %{}, …) · tally into a map" (`#freq`)
- `<figure class="fig">` labelled by `#frTitle`.
- Control: range slider `#frStep` (min 0, max 5) with value label `#frStepval` (`1 / 6`).
- SVG ids: list group `#frList`, accumulator-map group `#frMap`. Code `#frCode`; readout `#frOut`.
- Pure-function logic: steps fold each symbol into the map accumulator, bumping per-key counts.
- Default readout (verbatim): `step 1 · start with the empty map %{}`.

### Section 3 — "Worked examples" (`#gallery`)
- Control group `#gSel`: `data-g="sum"` (`data-c="sage"`, active) `sum`; `data-g="minmax"` (`blue`) `min & max`; `data-g="freq"` (`gold`) `frequencies`; `data-g="while"` (`elixir`) `reduce_while`.
- Code `#gCode`; readout `#gOut`. Pure-function logic: `GAL` keyed by `sum`/`minmax`/`freq`/`while` → `{code, note}`.
- Default readout (verbatim): `sum · a number accumulator, the simplest fold`. Notes: `a number accumulator, the simplest fold`; `a tuple accumulator carries two running values at once`; `a map accumulator tallies counts`; `reduce_while can stop early by returning :halt`.

Degrade behaviour: figures render once on load; `.reveal` is JS-gated and shown immediately under reduced-motion or no `IntersectionObserver`. Footer build-stamp decoder: id `TSK0NZkbnycYW8`, decoded timestamp `2026-05-30 17:04:03 UTC`.

## References (#refs, verbatim)
This page has no `#refs` References block — there is no Sources or "Related in this course" section in the markup. The page ends at the gallery and the pager; cross-references appear only in the `.bridge` cells (to `F2.05 · universal` and `Enum.frequencies/1`) and the footer links (listed under Wiring).

## Wiring
- route-tag (verbatim): `/ elixir / functional / folds / reduce` — `<a href="/elixir">elixir</a>` · `<a href="/elixir/functional">functional</a>` · `<a href="/elixir/functional/folds">folds</a>` · `<span class="rcur">reduce</span>`.
- crumbs (verbatim): `F2` (`/elixir/functional`) / `F2.05` (`/elixir/functional/folds`) / `reduce` (here).
- toc-mini: `#shapes` "Accumulators of any shape"; `#freq` "Build a map"; `#gallery` "Worked examples".
- pager: prev → `/elixir/functional/folds/filter` "Part 2 · filter"; next → `/elixir/functional/folds/advanced` "Part 4 · advanced".
- footer: column "Chapters" — `/elixir/algebra` F1 · Algebra, `/elixir/functional` F2 · Functional Programming, `/elixir/language` F3 · The Elixir Language, `/elixir/algorithms` F4 · Algorithms & Data Structures, `/elixir/pragmatic` F5 · Pragmatic Programming, `/elixir/phoenix` F6 · Phoenix Framework. Column "The course" — `/elixir` Course home, `/elixir/course` Contents & history, `/elixir/algebra/functions` Start · F1.01.
- Page meta — `<title>` (verbatim): `reduce — F2.05.3 · jonnify`. `<meta name="description">` (verbatim): `The general fold: accumulators of any shape — numbers, lists, maps — and building a frequency map step by step.`

## Build instruction
To rebuild this dive, copy the `<head>…</style>`, `<header class="site">`, `<footer class="site-foot">`, and the two trailing `<script>` blocks verbatim from a recent BUILT sibling on the elixir (purple) accent; change only the `<title>`/`<meta description>`, the `route-tag` segments, and the `<main>` body. No-invent guards: use only the real Elixir surfaces shown — `Enum.reduce/3`, `Enum.reduce_while/3`, `Enum.frequencies/1`, `Map.update/4`, `min/2`, `max/2`, the `&+/2` capture, and `{:cont, …}` / `{:halt, …}` tuples — exactly as written; do not introduce Portal/Phoenix surfaces on an F2 page, and cite the companion course for OTP internals rather than re-teaching. Voice rules: no first person, no exclamation marks, no emoji, none of "just", "simply", "obviously". Model sibling to copy from: `elixir/functional/folds/advanced.html` (the adjacent dive — identical shell, same accent, slider + toolkit/gallery shape).
