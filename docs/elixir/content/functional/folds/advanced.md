# F2.05.4 — Advanced folds (dive)

- Route (served): `/elixir/functional/folds/advanced`
- File: `elixir/functional/folds/advanced.html`
- Place in the chapter: Last of the four F2.05 deep dives (part 4 of 4). It reads the rest of the `Enum` toolkit as folds with extra structure — scan, map_reduce, flat_map, group_by, frequencies, chunk_every — and closes F2.05, handing off to F2.06 (Closures & partial application).
- Accent: `elixir` (purple).
- Status: built and published; A+ on the nine Apollo gates.

## Lead
Eyebrow (verbatim): `F2.05 · part 4 of 4`

Hero h1 (verbatim): `Advanced folds`

Hero lede (verbatim):

> Once reduce is clear, the rest of the `Enum` toolkit reads as folds with extra structure. Scan keeps every intermediate result; map_reduce maps and accumulates at once; flat_map, group_by, and chunk only choose a different accumulator shape.

Kicker (verbatim):

> Reduce throws away every intermediate accumulator and returns the last one. Many useful operations want those intermediates, or a second value alongside the result, or a particular grouping. Each is a small variation on the same left-to-right fold — worth recognising so you reach for the packaged one instead of rebuilding it.

## Sections
In order:

1. `scan: a running fold` (`#scan`) — teaching. A `deflist` defines `scan`, `running fold`, `map_reduce`, `group_by`. Steps through `scan([1, 2, 3, 4], &+/2)` building the running totals. Bridge to `Enum.scan/2` vs `Enum.reduce/3`.
2. `The toolkit` (`#toolkit`) — advanced. Five Enum operations as folds: map_reduce, flat_map, group_by, frequencies, chunk_every. Bridge to `F2 · Functional` (reach for the named operation; fall back to `reduce`).
3. `Where this goes` (`#close`) — synthesis close. Summarises folds and forwards to F2.06.

Real Elixir code shown: `scan([1, 2, 3, 4], &+/2)` running totals (`reduce would keep only 10`); the toolkit code blocks for `map_reduce`, `flat_map`, `group_by`, `frequencies`, `chunk_every`, each described as reduce with a chosen accumulator shape.

## The interactives

### Section 1 — "scan([1, 2, 3, 4], &+/2) · reduce keeps the last; scan keeps them all" (`#scan`)
- `<figure class="fig">` labelled by `#scTitle`.
- Control: range slider `#scStep` (min 0, max 3) with value label `#scStepval` (`1 / 4`).
- SVG ids: input chips `#scIn`, running-totals chips `#scOut`, the static note `#scReduce` (text `reduce would keep only 10`). Code `#scCode`; readout `#scOut2`.
- Pure-function logic: each step appends the running total to the output list.
- Default readout (verbatim): `step 1 · first total is 1 · running [1]`.

### Section 2 — "Enum operations · folds with extra structure" (`#toolkit`)
- `<figure class="fig">` labelled by `#tkTitle`.
- Control group `#tkSel`: `data-k="map_reduce"` (`data-c="gold"`, active) `map_reduce`; `data-k="flat_map"` (`blue`) `flat_map`; `data-k="group_by"` (`sage`) `group_by`; `data-k="frequencies"` (`elixir`) `frequencies`; `data-k="chunk_every"` (`gold`) `chunk_every`.
- SVG ids: accumulator box `#tkAccBox` / text `#tkAcc`, "does" line `#tkDoes`. Code `#tkCode`; readout `#tkOut`.
- Pure-function logic: `TK` keyed by the five operations → `{acc, stroke, col, does, code}`. Accumulator labels (verbatim): `the mapped list + an accumulator`; `a list, flattened one level`; `a map of key => elements`; `a map of element => count`; `a list of fixed-size lists`. "does" descriptions (verbatim): `maps and accumulates in one pass, returning both`; `maps each element to a list, then concatenates them`; `folds into a map from a key to the elements that share it`; `tallies how many times each element appears`; `folds elements into batches of a fixed size`.
- Default readout (verbatim): `map_reduce · map and accumulate at once · returns {mapped, acc}`.

Degrade behaviour: figures render once on load; the scan note ships static in markup; `.reveal` is JS-gated and shown immediately under reduced-motion or no `IntersectionObserver`. Footer build-stamp decoder: id `TSK0NZkcRWG0xM`, decoded timestamp `2026-05-30 17:04:12 UTC` (note: slightly later than the sibling pages' `17:04:03`).

## References (#refs, verbatim)
This page has no `#refs` References block — there is no Sources or "Related in this course" section in the markup. The page ends with the `Where this goes` close and the pager; cross-references appear only in the `.bridge` cells (to `Enum.scan/2` / `Enum.reduce/3` and `F2 · Functional`), the close `.note` (to the `F2.05 hub` and `F2 overview`), and the footer links (listed under Wiring).

## Wiring
- route-tag (verbatim): `/ elixir / functional / folds / advanced` — `<a href="/elixir">elixir</a>` · `<a href="/elixir/functional">functional</a>` · `<a href="/elixir/functional/folds">folds</a>` · `<span class="rcur">advanced</span>`.
- crumbs (verbatim): `F2` (`/elixir/functional`) / `F2.05` (`/elixir/functional/folds`) / `advanced` (here).
- toc-mini: `#scan` "scan: a running fold"; `#toolkit` "The toolkit".
- pager: prev → `/elixir/functional/folds/reduce` "Part 3 · reduce"; next → `/elixir/functional/closures` "F2.06 · Closures & partial application".
- footer: column "Chapters" — `/elixir/algebra` F1 · Algebra, `/elixir/functional` F2 · Functional Programming, `/elixir/language` F3 · The Elixir Language, `/elixir/algorithms` F4 · Algorithms & Data Structures, `/elixir/pragmatic` F5 · Pragmatic Programming, `/elixir/phoenix` F6 · Phoenix Framework. Column "The course" — `/elixir` Course home, `/elixir/course` Contents & history, `/elixir/algebra/functions` Start · F1.01.
- Page meta — `<title>` (verbatim): `Advanced folds — F2.05.4 · jonnify`. `<meta name="description">` (verbatim): `The Enum toolkit as folds with extra structure: scan as a running fold, plus map_reduce, flat_map, group_by, and frequencies.`

## Build instruction
To rebuild this dive, copy the `<head>…</style>`, `<header class="site">`, `<footer class="site-foot">`, and the two trailing `<script>` blocks verbatim from a recent BUILT sibling on the elixir (purple) accent; change only the `<title>`/`<meta description>`, the `route-tag` segments, and the `<main>` body. No-invent guards: use only the real Elixir surfaces shown — `Enum.scan/2`, `Enum.reduce/3`, `Enum.map_reduce`, `Enum.flat_map`, `Enum.group_by`, `Enum.frequencies`, `Enum.chunk_every`, and the `&+/2` capture — keeping each described accurately as a fold variation; do not introduce Portal/Phoenix surfaces on an F2 page, and cite the companion course for OTP internals rather than re-teaching. Voice rules: no first person, no exclamation marks, no emoji, none of "just", "simply", "obviously". Model sibling to copy from: `elixir/functional/folds/reduce.html` (the adjacent dive — identical shell, same accent, slider + toolkit/gallery shape).
