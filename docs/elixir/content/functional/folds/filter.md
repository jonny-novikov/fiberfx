# F2.05.2 — filter (dive)

- Route (served): `/elixir/functional/folds/filter`
- File: `elixir/functional/folds/filter.html`
- Place in the chapter: Second of the four F2.05 deep dives (part 2 of 4). It takes `filter` — keep what passes a predicate, drop the rest — between `map` and `reduce`, then pairs filter with map into a pipeline. Belongs to the folds teaching arc.
- Accent: `elixir` (purple).
- Status: built and published; A+ on the nine Apollo gates.

## Lead
Eyebrow (verbatim): `F2.05 · part 2 of 4`

Hero h1 (verbatim): `filter`

Hero lede (verbatim):

> Filter keeps the elements that pass a test and drops the rest. The predicate — a function returning true or false — decides each element's fate. Order is preserved; length can only shrink.

Kicker (verbatim):

> Where map transforms every element and keeps the count, filter keeps the values unchanged and changes the count. Its mirror image is `reject`, which keeps exactly what filter drops. And filter composes naturally with map: narrow the list, then transform what remains.

## Sections
In order:

1. `Keep what passes` (`#keep`) — teaching. A `deflist` defines `filter`, `predicate`, `reject`, `Enum.filter` (`Enum.filter(list, pred)`). Bridge to `F2.05 · reduce` (filter is reduce that appends only when the predicate holds).
2. `Filter, then map` (`#pipeline`) — teaching. Two-stage pipeline `filter(pred)` then `map(&1 * 10)` over `[1, 2, 3, 4]`. Bridge to `F2.08 · pipelines`.
3. `Worked examples` (`#gallery`) — advanced/gallery. Filter, reject (its inverse), and filter + map.

Real Elixir code shown (verbatim across the interactives):
- `Enum.filter([1, 2, 3, 4, 5, 6], &(rem(&1, 2) == 0))` (and `&(&1 > 3)`, `&(rem(&1, 2) == 1)` predicate variants).
- Pipeline: `[1, 2, 3, 4] |> Enum.filter(<pred>)   # [...] ` `|> Enum.map(&(&1 * 10))   # [...]`.
- Gallery: `Enum.filter([1, 2, 3, 4], &(rem(&1, 2) == 0))   # => [2, 4]`; `Enum.reject([1, 2, 3, 4], &(rem(&1, 2) == 0))   # => [1, 3]`; `[1, 2, 3, 4, 5, 6] |> Enum.filter(&(&1 > 2)) |> Enum.map(&(&1 * &1))   # => [9, 16, 25, 36]`.

## The interactives

### Section 1 — "Enum.filter · pass or drop" (`#keep`)
- `<figure class="fig">` labelled by `#kTitle`.
- Control group `#kSel`: `data-k="even"` (`data-c="sage"`, active) label `&(rem(&1, 2) == 0)`; `data-k="gt3"` (`blue`) `&(&1 > 3)`; `data-k="odd"` (`gold`) `&(rem(&1, 2) == 1)`.
- SVG ids: input chips `#kIn`, kept chips `#kOut`. Code `#kCode`; readout `#kOutTxt`.
- Pure-function logic: predicate over the base list; passing elements kept in order, dropped ones faded.
- Default readout (verbatim): `&(rem(&1, 2) == 0) · [1, 2, 3, 4, 5, 6] → [2, 4, 6] · 3 kept, 3 dropped`.

### Section 2 — "filter(pred) then map(&1 * 10) · over [1, 2, 3, 4]" (`#pipeline`)
- `<figure class="fig">` labelled by `#pTitleF`.
- Control group `#pSel`: `data-k="even"` (`data-c="sage"`, active) `keep even`; `data-k="gt2"` (`blue`) `keep > 2`.
- SVG ids: row group `#pRows` (chips by `chip`/`label`). Code `#pCode`; readout `#pOut`.
- Pure-function logic: `renderP()` over `base = [1, 2, 3, 4]`, computes `base.filter(spec.f)` then maps `x * 10`; rows are input, the filtered (`spec.plabel`) and `map(&1 * 10)`.
- Default readout (verbatim): `keep even · [1, 2, 3, 4] → filter → [2, 4] → map ×10 → [20, 40]`.

### Section 3 — "Worked examples" (`#gallery`)
- Control group `#gSel`: `data-g="filter"` (`data-c="sage"`, active) `filter`; `data-g="reject"` (`gold`) `reject`; `data-g="both"` (`blue`) `filter + map`.
- Code `#gCode`; readout `#gOut`. Pure-function logic: `GAL` keyed by `filter`/`reject`/`both` → `{code, note}`.
- Default readout (verbatim): `filter · keep the even numbers`. Notes: `keep the even numbers`; `reject keeps exactly what filter drops`; `narrow first, then square what remains`.

Degrade behaviour: figures render once on load (`renderK`/`renderP`/`renderG`); `.reveal` is JS-gated and shown immediately under reduced-motion or no `IntersectionObserver`. Footer build-stamp decoder: id `TSK0NZkbnlZ0XA`, decoded timestamp `2026-05-30 17:04:03 UTC`.

## References (#refs, verbatim)
This page has no `#refs` References block — there is no Sources or "Related in this course" section in the markup. The page ends at the gallery and the pager; cross-references appear only in the `.bridge` cells (to `F2.05 · reduce` and `F2.08 · pipelines`) and the footer links (listed under Wiring).

## Wiring
- route-tag (verbatim): `/ elixir / functional / folds / filter` — `<a href="/elixir">elixir</a>` · `<a href="/elixir/functional">functional</a>` · `<a href="/elixir/functional/folds">folds</a>` · `<span class="rcur">filter</span>`.
- crumbs (verbatim): `F2` (`/elixir/functional`) / `F2.05` (`/elixir/functional/folds`) / `filter` (here).
- toc-mini: `#keep` "Keep what passes"; `#pipeline` "Filter, then map"; `#gallery` "Worked examples".
- pager: prev → `/elixir/functional/folds/map` "Part 1 · map"; next → `/elixir/functional/folds/reduce` "Part 3 · reduce".
- footer: column "Chapters" — `/elixir/algebra` F1 · Algebra, `/elixir/functional` F2 · Functional Programming, `/elixir/language` F3 · The Elixir Language, `/elixir/algorithms` F4 · Algorithms & Data Structures, `/elixir/pragmatic` F5 · Pragmatic Programming, `/elixir/phoenix` F6 · Phoenix Framework. Column "The course" — `/elixir` Course home, `/elixir/course` Contents & history, `/elixir/algebra/functions` Start · F1.01.
- Page meta — `<title>` (verbatim): `filter — F2.05.2 · jonnify`. `<meta name="description">` (verbatim): `Keeping elements that pass a predicate: filter and its inverse reject, and filtering then mapping as a pipeline.`

## Build instruction
To rebuild this dive, copy the `<head>…</style>`, `<header class="site">`, `<footer class="site-foot">`, and the two trailing `<script>` blocks verbatim from a recent BUILT sibling on the elixir (purple) accent; change only the `<title>`/`<meta description>`, the `route-tag` segments, and the `<main>` body. No-invent guards: use only the real Elixir surfaces shown — `Enum.filter`, `Enum.reject`, `Enum.map`, `rem/2`, and the `&(…)` capture; keep predicate semantics exact (filter keeps true, reject keeps false); do not introduce Portal/Phoenix surfaces on an F2 page, and cite the companion course for OTP internals rather than re-teaching. Voice rules: no first person, no exclamation marks, no emoji, none of "just", "simply", "obviously". Model sibling to copy from: `elixir/functional/folds/map.html` (the adjacent dive — identical shell, same accent, same three-section teaching + gallery shape).
