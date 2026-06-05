# F2.05.1 — map (dive)

- Route (served): `/elixir/functional/folds/map`
- File: `elixir/functional/folds/map.html`
- Place in the chapter: First of the four F2.05 deep dives (part 1 of 4). It takes `map` on its own terms — transform every element, preserve shape — before `filter`, `reduce`, and `advanced`. Belongs to the folds teaching arc: each core operation, then the wider toolkit.
- Accent: `elixir` (purple).
- Status: built and published; A+ on the nine Apollo gates.

## Lead
Eyebrow (verbatim): `F2.05 · part 1 of 4`

Hero h1 (verbatim): `map`

Hero lede (verbatim):

> Map applies one function to every element and collects the results. The output has the same length as the input and the same order — one element in, one element out. It transforms contents without touching shape.

Kicker (verbatim):

> Because each element is handled independently, map says nothing about order of effects and everything about the transformation. That independence is also why two maps in a row collapse into one: doing `f` then `g` to every element is the same as doing `g(f(x))` once.

## Sections
In order:

1. `One function, every element` (`#transform`) — teaching. A `deflist` defines `map`, `transform`, `one to one`, `Enum.map` (`Enum.map(list, fun)`). Running example: `Enum.map([1, 2, 3, 4], …)`. Bridge to `F2.05 · reduce` (map is reduce with a list accumulator that appends each transformed element).
2. `Chained maps fuse` (`#fuse`) — teaching. Two passes versus one fused map; `map(&1 * 2)` then `map(&1 + 1)` over `[1, 2, 3]`. Bridge to `F1.03 · composition`.
3. `Worked examples` (`#gallery`) — advanced/gallery. Three everyday maps: double, word lengths, with index.

Real Elixir code shown (verbatim across the interactives):
- `Enum.map([1, 2, 3, 4], &(&1 * 2))   # => [2, 4, 6, 8]` (and `&(&1 + 10)`, `&(&1 * &1)`, `&(-&1)` variants).
- Two passes: `[1, 2, 3] |> Enum.map(&(&1 * 2))   # [2, 4, 6]` `|> Enum.map(&(&1 + 1))   # [3, 5, 7]`. Fused: `Enum.map([1, 2, 3], &(&1 * 2 + 1))   # => [3, 5, 7]`.
- Gallery: `Enum.map([1, 2, 3], &(&1 * 2))   # => [2, 4, 6]`; `Enum.map(["a", "to", "cat"], &String.length/1)   # => [1, 2, 3]`; `["a", "b", "c"] |> Enum.with_index() |> Enum.map(fn {v, i} -> "#{i}:#{v}" end)   # => ["0:a", "1:b", "2:c"]`.

## The interactives

### Section 1 — "Enum.map · one in, one out" (`#transform`)
- `<figure class="fig">` labelled by `#mTitle`.
- Control group `#mSel`: `data-k="dbl"` (`data-c="gold"`, active) label `&(&1 * 2)`; `data-k="add10"` (`blue`) `&(&1 + 10)`; `data-k="sq"` (`sage`) `&(&1 * &1)`; `data-k="neg"` (`elixir`) `&(-&1)`.
- SVG ids: input chips `#mIn`, function text `#mFn`, output chips `#mOut`. Code `#mCode`; readout `#mOutTxt`.
- Pure-function logic: `BASE = [1, 2, 3, 4]`; `MAPF` keyed by `dbl`/`add10`/`sq`/`neg` with a JS `f` (`x*2`, `x+10`, `x*x`, `-x`), label, code, colour, stroke. `renderM()` chips input and `BASE.map(spec.f)` output.
- Default readout (verbatim): `&(&1 * 2) · [1, 2, 3, 4] → [2, 4, 6, 8] · 4 in, 4 out`.

### Section 2 — "map(&1 * 2) then map(&1 + 1)" (`#fuse`)
- `<figure class="fig">` labelled by `#fuseTitle`.
- Control group `#fuseSel`: `data-k="two"` (`data-c="blue"`, active) `two passes`; `data-k="fused"` (`sage`) `fused`.
- SVG ids: row group `#fuseRows` (chips built by `chipRow`/`rowLabel`). Code `#fuseCode`; readout `#fuseOut`.
- Pure-function logic: `renderFuse()` lays out input `[1, 2, 3]` → `map(&1 * 2)` `[2, 4, 6]` → `map(&1 + 1)` `[3, 5, 7]` for two passes, or `map(&1 * 2 + 1)` `[3, 5, 7]` for fused with the row label `one pass, same result`.
- Default readout (verbatim): `two passes · ×2 then +1 · [1, 2, 3] → [2, 4, 6] → [3, 5, 7]`. Fused readout (verbatim): `fused · x → x * 2 + 1 in one pass · [1, 2, 3] → [3, 5, 7]`.

### Section 3 — "Worked examples" (`#gallery`)
- Control group `#gSel`: `data-g="double"` (`data-c="gold"`, active) `double`; `data-g="lengths"` (`blue`) `word lengths`; `data-g="index"` (`sage`) `with index`.
- Code `#gCode`; readout `#gOut`. Pure-function logic: `GAL` keyed by `double`/`lengths`/`index` → `{code, note}`.
- Default readout (verbatim): `double · each number times two`. Notes: `each number times two`; `a function reference transforms each string to its length`; `pair each element with its index, then map the pair`.

Degrade behaviour: figures render once on load (`renderM`/`renderFuse`/`renderG`); `.reveal` is JS-gated and shown immediately under reduced-motion or no `IntersectionObserver`. Footer build-stamp decoder: id `TSK0NZkbnYVSYC`, decoded timestamp `2026-05-30 17:04:03 UTC`.

## References (#refs, verbatim)
This page has no `#refs` References block — there is no Sources or "Related in this course" section in the markup. The page ends at the gallery and the pager; cross-references appear only in the `.bridge` cells (to `F2.05 · reduce` and `F1.03 · composition`) and the footer links (listed under Wiring).

## Wiring
- route-tag (verbatim): `/ elixir / functional / folds / map` — `<a href="/elixir">elixir</a>` · `<a href="/elixir/functional">functional</a>` · `<a href="/elixir/functional/folds">folds</a>` · `<span class="rcur">map</span>`.
- crumbs (verbatim): `F2` (`/elixir/functional`) / `F2.05` (`/elixir/functional/folds`) / `map` (here).
- toc-mini: `#transform` "One function, every element"; `#fuse` "Chained maps fuse"; `#gallery` "Worked examples".
- pager: prev → `/elixir/functional/folds` "F2.05 · hub"; next → `/elixir/functional/folds/filter` "Part 2 · filter".
- footer: column "Chapters" — `/elixir/algebra` F1 · Algebra, `/elixir/functional` F2 · Functional Programming, `/elixir/language` F3 · The Elixir Language, `/elixir/algorithms` F4 · Algorithms & Data Structures, `/elixir/pragmatic` F5 · Pragmatic Programming, `/elixir/phoenix` F6 · Phoenix Framework. Column "The course" — `/elixir` Course home, `/elixir/course` Contents & history, `/elixir/algebra/functions` Start · F1.01.
- Page meta — `<title>` (verbatim): `map — F2.05.1 · jonnify`. `<meta name="description">` (verbatim): `Transforming every element with a function: one-to-one output, length and order preserved, and why chained maps fuse into one.`

## Build instruction
To rebuild this dive, copy the `<head>…</style>`, `<header class="site">`, `<footer class="site-foot">`, and the two trailing `<script>` blocks verbatim from a recent BUILT sibling on the elixir (purple) accent; change only the `<title>`/`<meta description>`, the `route-tag` segments, and the `<main>` body. No-invent guards: use only the real Elixir surfaces shown — `Enum.map`, `Enum.with_index`, `String.length` and the capture syntax `&(…)`; do not introduce Portal store / event-sourced engine / Phoenix surfaces on an F2 page, and cite the companion course for OTP internals rather than re-teaching. Voice rules: no first person, no exclamation marks, no emoji, none of "just", "simply", "obviously". Model sibling to copy from: `elixir/functional/folds/filter.html` (the adjacent dive — identical shell, same accent, same three-section teaching + gallery shape).
