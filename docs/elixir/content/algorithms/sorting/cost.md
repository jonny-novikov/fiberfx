# F4.03.3 — Stability & sort cost (dive)

- Route (served): `/elixir/algorithms/sorting/cost`
- File: `elixir/algorithms/sorting/cost.html`
- Place in the chapter: the third and last of the `F4.03 · sorting` dives (part 3 of 3). It follows `sorts` (part 1) and `search` (part 2). It ranks the sorts on average / worst / space / stability and proves the comparison-sort `Ω(n log n)` lower bound, then hands the chapter forward to `F4.04 — Maps, sets & hashing`.
- Accent: sage (F4 chapter accent; the cost-card uses sage for good metrics and burgundy `#e08f8b` for the bad ones; the decision-tree height-bar is gold). Note: this page's `.refs a` is styled sage `#a7c9b1` (the sibling dives use elixir), and it has no `.colophon`-adjacent variation otherwise.
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F4.03 · part 3 of 3`

`h1` (verbatim): `Stability & sort cost`

Lede (`.lede`, verbatim): "Sorts are ranked on more than their average speed. Three numbers matter — average case, worst case, and extra space — plus one yes/no property: **stability**, whether elements with equal keys keep their original order. And over all of them sits a hard floor: any sort that works purely by comparing elements needs at least about `n log n` comparisons in the worst case. No cleverness escapes it."

Kicker (`.kicker`, verbatim): "Compare the three sorts on the numbers that decide which one to reach for, then see why `n log n` is a wall."

## Sections

In order:

1. `#card` — "Ranking the sorts" (teaching). Merge sort wins on guarantees: O(n log n) every case and stable, at O(n) extra space. Quicksort is often fastest in practice and sorts in place, but worst case O(n²) and not stable. Insertion sort is O(n²) but tiny and stable, and unbeatable on nearly-sorted input. Carries the cost-card interactive and a `.take`: there is no single best sort — there is the one whose trade-offs fit your data.
2. `#bound` — "Advanced: the n log n lower bound" (advanced). A comparison sort is a decision tree; each comparison is one yes/no branch, and to sort correctly it must reach a different leaf for every input ordering. There are `n!` orderings, so the tree needs at least that many leaves, and a binary tree with `n!` leaves is at least `log₂(n!)` deep — by Stirling's approximation about `n log n`. The escape hatch is to stop comparing: counting sort and radix sort use keys as indices and run in O(n), but only for bounded integers. This section carries the second figure (the decision tree) plus a `pre.code` block.

Real Elixir code shown (`pre.code` in `#bound`, verbatim): "`# Elixir's Enum.sort is a stable merge sort — O(n log n), guaranteed`" then `Enum.sort([3, 1, 2])` (`# => [1, 2, 3]`) and `Enum.sort_by(users, & &1.age)` (`# stable: equal ages keep input order`), followed by the informal floor comment block ("n elements have n! orderings; one comparison = one yes/no branch; distinguishing n! outcomes needs >= log2(n!) ~ n*log2(n) comparisons").

`.bridge`: "The idea" — "A comparison answers one yes/no question; ordering `n` things needs about `log₂(n!)` of them." → "In Elixir" — "`Enum.sort` meets the `n log n` floor and is stable; only key-based sorts go lower."

Closing `.note`: "That completes F4.03. Next module: **F4.04 — Maps, sets & hashing** (in production), where hashing trades ordering away to make lookup O(1) on average — the door into the trie family that closes out the chapter."

## The interactives

### Figure 1 — "The algorithm · select one" (cost card; `#coSel` selector + `#coOut`/`#coCode` readouts)

- `<figure class="fig" aria-labelledby="coTitle">`, heading `#coTitle` "The algorithm · select one".
- Control group `#coSel` (role="group", aria-label "The algorithm"), three `<button>`s:
  - `data-k="merge" data-c="sage"` — label "merge" — starts `active`
  - `data-k="quick" data-c="blue"` — label "quick"
  - `data-k="insertion" data-c="gold"` — label "insertion"
- SVG `viewBox="0 0 720 212"`: a card with `#coName` (title), and four metric `<text>`s — `#coBadge` (AVERAGE), `#coWorst` (WORST CASE), `#coStable` (STABLE), `#coSpace` (EXTRA SPACE). Below: `<pre class="code" id="coCode">` and `.geo-readout#coOut`.
- Pure function `pick(k)` over `CASES = {merge, quick, insertion}`: toggles `#coSel` button `active`/`aria-pressed`, then sets `#coName`/`#coBadge`/`#coWorst`/`#coStable`/`#coSpace` text and fill, and writes `code`/`out`. Colours: `SAGE='#a7c9b1'`, `BURG='#e08f8b'`, `CREAM='#e8e2d0'`. Initial call `pick('merge')`.
- Readout strings (`CASES`, verbatim):
  - merge — name "Merge sort"; badge "O(n log n)"; worst "O(n log n)"; stable "stable"; space "O(n)"; `#coOut`: "**Merge sort** is the safe default: a guaranteed O(n log n) and stable output, paying O(n) scratch space for the merge. It is what `Enum.sort/1` uses."
  - quick — name "Quicksort"; badge "O(n log n)"; worst "O(n²)" (burgundy); stable "not stable" (burgundy); space "O(log n)"; `#coOut`: "**Quicksort** is usually the fastest in practice and sorts in place, but a bad pivot gives O(n²), and it does not preserve the order of equal keys. A random or median pivot tames the worst case."
  - insertion — name "Insertion sort"; badge "O(n²)" (burgundy); worst "O(n²)" (burgundy); stable "stable" (sage); space "O(1)"; `#coOut`: "**Insertion sort** is O(n²) and small, stable, and in place. On nearly-sorted data it approaches O(n), which is why adaptive merge sorts fall back to it for short runs."
- Static defaults in markup (the `merge` state): `#coName` "Merge sort", `#coBadge` "O(n log n)", `#coWorst` "O(n log n)", `#coStable` "stable", `#coSpace` "O(n)".

### Figure 2 — "A comparison sort is a decision tree · n! leaves, height ≈ n log n" (static)

- `<figure class="fig" aria-labelledby="coBoundTitle">`, heading `#coBoundTitle` "A comparison sort is a decision tree · n! leaves, height ≈ n log n".
- SVG `viewBox="0 0 720 236"`: a three-level decision tree (internal nodes labelled `a:b`, `b:c`, `a:c`), `n!`-leaf annotation ("n! leaves — one per possible ordering"), and a gold height-bar labelled "height ≥ log₂(n!) ≈ n log n". This figure is purely static (no controls, no JS hook).
- Static `.geo-readout` (verbatim): "Each level is one comparison; reaching `n!` distinct leaves takes at least `log₂(n!)` levels. That is the O(n log n) floor — merge sort touches it, quicksort touches it on average, and nothing comparison-based goes below it."

### Footer build-stamp decoder (`#stamp`)

- Stamp id `TSK0NbZlw6TpeC` (in `#stampId`); panel `#st-ts` hard-codes "2026-05-31 19:27:37 UTC".
- `decodeBranded(id)` over `B62 = "0123…XYZabc…xyz"` with `EPOCH_MS = 1704067200000`, `ts = snow >> 22n`, `node = (snow >> 12n) & 0x3FFn`, `seq = snow & 0xFFFn`. Decoded: namespace `TSK`, snowflake `319557553824464896`, node `0`, seq `0`, timestamp `2026-05-31 19:27:37 UTC`. Click / Enter / Space toggles `.open`/`aria-expanded`.

## References (#refs, verbatim)

Intro line: "Primary sources for this lesson, and where it connects in the course."

**Sources**
- Merge sort — Wikipedia (`https://en.wikipedia.org/wiki/Merge_sort`) — a stable functional sort.
- Cormen, Leiserson, Rivest & Stein (2022). *Introduction to Algorithms* (4th ed.). — sorting and searching, including the comparison-sort lower bound.

**Related in this course**
- `/elixir/algorithms/sorting` — F4.03 · Sorting & searching
- `/elixir/algorithms/lists` — F4.01 · Lists, recursion & complexity
- `/elixir/functional/recursion` — F2.04 · Recursion patterns & tail calls

## Wiring

- route-tag (verbatim): `elixir` (`/elixir`) `/` `algorithms` (`/elixir/algorithms`) `/` `sorting` (`/elixir/algorithms/sorting`) `/` `<span class="rcur">cost</span>` (current, no link).
- crumbs (verbatim): `F4` → `/elixir/algorithms` · sep `/` · `F4.03` → `/elixir/algorithms/sorting` · sep `/` · here `cost`.
- toc-mini: `#card` ("Ranking the sorts") · `#bound` ("Advanced: the n log n lower bound").
- pager: prev → `/elixir/algorithms/sorting/search` ("← F4.03.2 · search"); next → `/elixir/algorithms` ("Back to F4 · overview →").
- footer (3-column `.foot-nav`): identical to the hub — brand → `/elixir`; Chapters column `/elixir/algebra`, `/elixir/functional`, `/elixir/language`, `/elixir/algorithms`, `/elixir/pragmatic`, `/elixir/phoenix`; The course column `/elixir`, `/elixir/course`, `/elixir/algebra/functions`. Header `.brand` → `/elixir`, `Contents` → `/elixir/course`.
- Page meta: `<title>` "Stability &amp; sort cost — F4.03.3 · jonnify"; `<meta description>` "Sorts are ranked on average, worst case, space, and stability — whether equal keys keep their order. Over all of them sits a hard floor: a comparison sort is a decision tree with n! leaves, so it needs at least log2(n!) ~ n log n comparisons. Merge sort meets the floor and is stable."

## Build instruction

To rebuild this dive, copy the `<head>…</style>`, `<header class="site">`, `<footer class="site-foot">`, and the two trailing `<script>` blocks verbatim from a recent BUILT sibling on the sage F4 accent — the model page is its sibling `elixir/algorithms/sorting/search.html` or `sorts.html` (this page's `<style>` omits the `.colophon`/extra rules and styles `.refs a` sage; align to the chosen model). Change only `<title>`/`<meta description>`, the `.route-tag` (current segment `cost`), the crumbs/eyebrow ("part 3 of 3"), the pager (forward link to `/elixir/algorithms`), and the `<main>` body. Keep the clamp-spacing in `h1{font-size:clamp(2.7rem,1.9rem + 4.2vw,5.1rem)}` intact. No-invent guards: use only the real Portal surfaces as written — the branded store (`TSK…` Snowflake stamp), the event-sourced engine behind ONE `Portal` facade, the Phoenix web app; cite the companion course for OTP internals and do not re-teach. The Elixir shown (`Enum.sort/1`, `Enum.sort_by/2`) is standard-library API — quote it as written, do not invent functions; the `Ω(n log n)` argument is the textbook decision-tree bound and must stay faithful to the cited source. Voice rules: no first person, no exclamation marks, no emoji, none of "just"/"simply"/"obviously".
