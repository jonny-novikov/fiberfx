# F4.03 — Sorting & searching (module hub)

- Route (served): `/elixir/algorithms/sorting`
- File: `elixir/algorithms/sorting/index.html`
- Place in the chapter: the third module of `F4 · Algorithms & Data Structures` (family `/elixir/algorithms`). It sits after `F4.01 · lists` and `F4.02 · trees`, and frames three dives — `sorts`, `search`, `cost` — that turn F4.02's divide-and-conquer tree recursion into flat-sequence sorting and searching, then prove the comparison-sort lower bound. The running sequence is the sorted output of F4.02's search tree, `[5, 8, 10, 12, 20, 30, 42]`. Next module is `F4.04 — Maps, sets & hashing`.
- Accent: sage (the F4 chapter accent; the hub's hero `<span class="ex">searching</span>` renders in `--elixir-bright`, but the chapter accent and the dive figures use sage `#a7c9b1`).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F4 · Foundations · module 3`

`h1` (verbatim): `Sorting & searching` (the word `searching` is the `.ex` accent span).

Hero lede (`.lede`, verbatim): "Sorting and searching are two halves of one bargain. Put a sequence in order once — at a cost of about `n log n` comparisons — and every later lookup drops from an O(n) scan to an O(log n) binary search. The two best comparison sorts, merge sort and quicksort, are the same divide-and-conquer recursion you met as a tree in F4.02, and binary search is the same halving as a balanced tree's descent."

Kicker (`.kicker`, verbatim): "The running sequence is the sorted output of F4.02's search tree, `[5, 8, 10, 12, 20, 30, 42]`. Three angles open the module: sorting a sequence, searching it, and the cost model that says `n log n` is the floor."

## What the page frames

The hub is built as a landing with a hero, an "Order, once" framing section (`#bargain`), a three-dive list (`#dives`), and an advanced section (`#advanced`). The three dives are presented as full-width `<a>` cards, each on its own accent left-border:

- F4.03.1 · Merge & quicksort — "Two divide-and-conquer sorts: merge splits and combines, quicksort partitions around a pivot — the tree-fold recursion from F4.02, applied to a list." — route `/elixir/algorithms/sorting/sorts` — left-border sage `--sage`, number tinted `--sage-bright`. Built.
- F4.03.2 · Linear & binary search — "O(n) over anything, O(log n) over a sorted sequence with random access — and why a linked list cannot do the fast one." — route `/elixir/algorithms/sorting/search` — left-border blue `--blue`, number tinted `--blue-bright`. Built.
- F4.03.3 · Stability & sort cost — "Best, average, and worst case for each sort, what stability preserves, and the Ω(n log n) lower bound on comparison sorts." — route `/elixir/algorithms/sorting/cost` — left-border gold `--gold`, number tinted `--gold-bright`. Built.

(The hub uses these accent-bordered dive cards rather than a `.mods` grid; there are no `soon`/`planned` pills on this hub — all three dives are built links.)

The `#advanced` section "Advanced: sort once, search many — and the comparison floor" argues the investment break-even (linear scan beats sorting for a single lookup; sort-once-then-binary-search wins after a handful) and previews the `n!`-leaf decision-tree floor proved in the cost dive. It carries a `.bridge` (F4.02 balanced tree → F4.03 sorted-sequence halving) and a closing `.note` listing the three dives in order and naming `F4.04 — Maps, sets & hashing` as the next module.

## The interactives

### Hero figure — "Insertion sort · one comparison per step" (`#hpBars` + `#hpCap`)

- `<figure class="hero-fig" aria-labelledby="hpTitle">`, figcaption `#hpTitle` "Insertion sort · one comparison per step".
- SVG `viewBox="0 0 320 280"`: seven bar groups in `#hpBars` (`.hp-bar`), each a `<rect>` + value `<text>`, over initial array `[5, 2, 6, 1, 4, 3, 7]`; the first comparison pair (slots 0 and 1) is tinted sage in the static markup.
- Controls: `#hpStep` button (label `▸ step`) and `#hpReset` button (label `reset`, `.hp-btn.ghost`).
- Caption readout `#hpCap` (`aria-live="polite"`); static default (verbatim): "`[5, 2, 6, 1, 4, 3, 7]` / `compare a[0]=5 & a[1]=2` — comparisons: 0 · swaps: 0."
- Pure functions in an IIFE: `init()` resets state to `INITIAL = [5, 2, 6, 1, 4, 3, 7]`; `step()` runs one insertion-sort comparison (and a swap when the left bar is taller), incrementing `comparisons`/`swaps`; `render()` repositions every bar (`BASE=240, UNIT=24, BARW=32, X0=24, STEP=40`), recolors hot/settled/idle (`FILL_HOT='#a7c9b1'`, `STROKE_DONE='#7ba387'`, `FILL_IDLE='#10162b'`), and rewrites `#hpCap`. On completion the hint reads "`sorted` — ascending order" and the step button is disabled.
- Degrades: the static SVG already shows `[5, 2, 6, 1, 4, 3, 7]` with the first pair tinted; the script binds `step`/`reset` but does NOT render on load (comment in source: "No render on load…"). Bar transitions are gated by `@media (prefers-reduced-motion: no-preference)` and disabled under `prefers-reduced-motion: reduce`. No browser storage.

### Content figure — "The angle · select one" (`#soSel` selector + `#soOut`/`#soCode` readouts)

- `<figure class="fig" aria-labelledby="soTitle">`, heading `#soTitle` "The angle · select one".
- Control group `#soSel` (role="group", aria-label "The angle"), three `<button>`s:
  - `data-k="sort" data-c="sage"` — label "sort" — starts `active`
  - `data-k="search" data-c="blue"` — label "search"
  - `data-k="cost" data-c="gold"` — label "cost"
- SVG `viewBox="0 0 720 176"`: seven boxes `#soBox0`–`#soBox6` holding the sorted array `5, 8, 10, 12, 20, 30, 42` (with index labels), plus a `#soCaption` annotation. Below: `<pre class="code" id="soCode">`, `.geo-readout#soOut`, and `#soRole`/`#soSeq` spans.
- Pure function `pick(k)` over `CASES = {sort, search, cost}`: toggles `#soSel` button `active`/`aria-pressed`, restrokes each `soBox{i}` from `c.box[i]`/`c.boxW`, and writes `caption`/`role`/`seq`/`code`/`out`. Colour constants: `SAGE='#a7c9b1'`, `BLUE='#9fc0ea'`, `GOLD='#f0cd7f'`, `DIM='#4a5474'`. Initial call `pick('sort')`.
- Readout strings (`CASES`, verbatim):
  - sort — caption "sorted from [12, 8, 30, 5, 10, 20, 42]"; role "rearrange into order"; seq "[5, 8, 10, 12, 20, 30, 42]"; `#soOut`: "**Sorting** rearranges the sequence into ascending order. A good comparison sort does it in about `n log n` comparisons — the subject of the first and third dives."
  - search — caption "binary search for 20: compare 12, then 30, then 20"; role "halve the search"; seq "found 20 at index 4"; `#soOut`: "**Binary search** checks the middle (12), discards the half that cannot hold 20, and repeats — 30, then 20. Three comparisons instead of five, because the data is sorted."
  - cost — caption "pay n log n once, then every search is log n"; role "n log n is the floor"; seq "sort n log n · search log n"; `#soOut`: "**Cost** is the whole point: order is an up-front O(n log n) payment that makes each later lookup O(log n). And n log n is a floor no comparison sort can break."

### Footer build-stamp decoder (`#stamp`)

- Stamp id `TSK0NbZlvOU0UC` (in `#stampId`); panel `#st-ts` hard-codes "2026-05-31 19:27:37 UTC".
- `decodeBranded(id)` splits `ns = id.slice(0,3)` (`TSK`) and `snow = b62decode(id.slice(3))` over `B62 = "0123…XYZabc…xyz"`, then `ts = snow >> 22n`, `node = (snow >> 12n) & 0x3FFn`, `seq = snow & 0xFFFn`, with `EPOCH_MS = 1704067200000`. Decoded: namespace `TSK`, snowflake `319557553174347776`, node `0`, seq `0`, timestamp `2026-05-31 19:27:37 UTC`. Click / Enter / Space toggles `.open` and `aria-expanded`.

## References (#refs, verbatim)

Intro line: "Primary sources for this lesson, and where it connects in the course."

**Sources**
- Merge sort — Wikipedia (`https://en.wikipedia.org/wiki/Merge_sort`) — a stable functional sort.
- Cormen, Leiserson, Rivest & Stein (2022). *Introduction to Algorithms* (4th ed.) — sorting and searching, in depth.

**Related in this course**
- `/elixir/algorithms` — F4 · Algorithms & Data Structures
- `/elixir/algorithms/lists` — F4.01 · Lists, recursion & complexity
- `/elixir/functional/recursion` — F2.04 · Recursion patterns & tail calls

## Wiring

- route-tag (verbatim): `<span class="rsep">/</span>` `elixir` (`/elixir`) `/` `algorithms` (`/elixir/algorithms`) `/` `<span class="rcur">sorting</span>` (current, no link).
- crumbs (verbatim): `F4 · Algorithms & Data Structures` → `/elixir/algorithms` · sep `/` · here `F4.03 · sorting` (no link).
- toc-mini: `#bargain` ("Order, once") · `#dives` ("Three deep dives") · `#advanced` ("Advanced: the comparison floor").
- pager: prev → `/elixir/algorithms/trees` ("← F4.02 · trees"); next → `/elixir/algorithms/sorting/sorts` ("Start · merge & quicksort →").
- footer (3-column `.foot-nav`):
  - brand: `.foot-logo` → `/elixir`; tag "Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir."
  - Chapters column: `/elixir/algebra` (F1 · Algebra), `/elixir/functional` (F2 · Functional Programming), `/elixir/language` (F3 · The Elixir Language), `/elixir/algorithms` (F4 · Algorithms & Data Structures), `/elixir/pragmatic` (F5 · Pragmatic Programming), `/elixir/phoenix` (F6 · Phoenix Framework).
  - The course column: `/elixir` (Course home), `/elixir/course` (Contents & history), `/elixir/algebra/functions` (Start · F1.01).
  - Header `.brand` → `/elixir`; the `Contents` nav link → `/elixir/course`.
- Page meta: `<title>` "Sorting &amp; searching — F4.03 · jonnify"; `<meta description>` "Sorting and searching are two halves of one bargain: sort once at O(n log n), and every later lookup drops to an O(log n) binary search. Merge sort and quicksort are the divide-and-conquer recursion of F4.02; binary search is its halving descent. Three dives plus the comparison-sort lower bound."

## Build instruction

To rebuild this hub, copy the `<head>…</style>`, `<header class="site">`, `<footer class="site-foot">`, and the two trailing `<script>` blocks verbatim from a recent BUILT sibling on the sage F4 accent — the model page is this module's own dive `elixir/algorithms/sorting/sorts.html` (or `search.html`/`cost.html`), which share the identical head/header/footer/decoder. Change only `<title>`/`<meta description>`, the `.route-tag` (current segment `sorting`, with `algorithms` linked), and the `<main>` body. Keep the clamp-spacing in `h1{font-size:clamp(2.7rem,1.9rem + 4.2vw,5.1rem)}` (spaces around the `+`) intact. No-invent guards: use only the real Portal surfaces as written — the branded store (`TSK…` Snowflake ids decoded by the footer stamp), an event-sourced engine behind ONE `Portal` facade, the Phoenix web app; cite the companion course for OTP internals (this page predates the migration and stays pure algorithms content) and do not re-teach them. Voice rules: no first person, no exclamation marks, no emoji, none of "just"/"simply"/"obviously". Keep the running sequence `[5, 8, 10, 12, 20, 30, 42]` and the dive-card accents (sage/blue/gold) consistent with the dives.
