# F4.03.1 — Merge & quicksort (dive)

- Route (served): `/elixir/algorithms/sorting/sorts`
- File: `elixir/algorithms/sorting/sorts.html`
- Place in the chapter: the first of the three `F4.03 · sorting` dives (part 1 of 3). It opens the sorting half — the two workhorse divide-and-conquer comparison sorts — and hands off to `search` (part 2) and `cost` (part 3). It applies the tree-fold recursion of `F4.02` to a flat list.
- Accent: sage (F4 chapter accent; the merge-sort figure case uses blue/sage, quicksort uses gold for the pivot).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F4.03 · part 1 of 3`

`h1` (verbatim): `Merge & quicksort`

Lede (`.lede`, verbatim): "The two workhorse comparison sorts are both divide-and-conquer — the same split-and-combine recursion you wrote over a tree in F4.02, now applied to a list. Merge sort splits the list in half, sorts each half, and merges the two sorted halves. Quicksort picks a pivot, partitions the rest into smaller and larger, and recurses on each side. Both average O(n log n); they differ in where the work lands."

Kicker (`.kicker`, verbatim): "Merge sort does its work on the way back up, in the merge step; quicksort does it on the way down, in the partition. Select one to see the split over `[8, 3, 5, 1]`."

## Sections

In order:

1. `#split` — "Divide, then conquer" (teaching). Merge sort divides positionally (halve regardless of values) and spends effort merging; quicksort divides by value around a pivot and spends effort partitioning. Carries the interactive figure (running example `[8, 3, 5, 1]`), a `.take` noting both reduce a sort of `n` to two sorts of about `n/2`, hence both average `n log n` (about `log n` halving levels, each O(n) work).
2. `#worst` — "Advanced: worst cases & Enum.sort" (advanced). Quicksort's cost depends on the pivot — a bad pivot (e.g. first element of an already-sorted list) degrades to O(n²); median-of-three or random pivots make that rare. Merge sort always halves, is O(n log n) in every case, and is stable. This is why Elixir's `Enum.sort/1` (and the `:lists.sort/1` it builds on) is a stable adaptive merge sort; you reach for `Enum.sort/2` with a comparator or `Enum.sort_by/2` with a key.

Real Elixir code shown (`pre.code` in `#worst`, verbatim): a `msort/1` definition — `def msort([]), do: []`, `def msort([x]), do: [x]`, and `def msort(list) do {l, r} = Enum.split(list, div(length(list), 2)); merge(msort(l), msort(r)) end` — with `merge/2` (`defp merge([], r), do: r`; `defp merge(l, []), do: l`; `defp merge([h1 | t1] = l, [h2 | t2] = r) do if h1 <= h2, do: [h1 | merge(t1, r)], else: [h2 | merge(l, t2)] end`) and a `qsort/1` (`def qsort([]), do: []`; `def qsort([pivot | rest]) do {less, greater} = Enum.split_with(rest, &(&1 < pivot)); qsort(less) ++ [pivot] ++ qsort(greater) end`).

`.bridge`: "The idea" — "Split the problem in two, solve each, and combine — the tree recursion of F4.02, now sorting a list." → "In Elixir" — "Merge splits then merges; quicksort pivots then partitions. `Enum.sort` is a stable merge sort."

Closing `.note`: "Next: **linear & binary search** — what a sorted sequence buys you when you go looking for one element." (links `/elixir/algorithms/sorting/search`.)

## The interactives

### Figure — "The algorithm · select one" (`#srSel` selector + `#srOut`/`#srCode` readouts)

- `<figure class="fig" aria-labelledby="srTitle">`, heading `#srTitle` "The algorithm · select one".
- Control group `#srSel` (role="group", aria-label "The algorithm"), two `<button>`s:
  - `data-k="merge" data-c="sage"` — label "merge sort" — starts `active`
  - `data-k="quick" data-c="gold"` — label "quicksort"
- SVG `viewBox="0 0 720 220"`: four bars `#srBar0`–`#srBar3` holding values `8, 3, 5, 1`, a `#srDivider` split line, a `#srPivotTag` ("pivot") label, and a `#srCaption` annotation. Below: `<pre class="code" id="srCode">`, `.geo-readout#srOut`, and `#srStep`/`#srResult` spans.
- Pure function `pick(k)` over `CASES = {merge, quick}`: toggles `#srSel` button `active`/`aria-pressed`, restrokes each `srBar{i}` from `c.bars[i]`, sets `#srDivider`/`#srPivotTag` opacity from `c.divider`/`c.pivot`, and writes `caption`/`step`/`code`/`out`. Colours: `SAGE='#a7c9b1'`, `BLUE='#9fc0ea'`, `GOLD='#f0cd7f'`. Initial call `pick('merge')`.
- Readout strings (`CASES`, verbatim):
  - merge — caption "split [8, 3] | [5, 1] — sort each half, then merge"; step "split, then merge: [3, 8] + [1, 5] → [1, 3, 5, 8]"; `#srOut`: "**Merge sort** halves the list down the middle, sorts each half, then walks the two sorted halves together, always taking the smaller front element. The work is in the merge."
  - quick — caption "pivot 5 — partition into less [3, 1] and greater [8]"; step "pivot 5: [3, 1] | 5 | [8] → [1, 3, 5, 8]"; `#srOut`: "**Quicksort** takes a **pivot**, splits the rest into elements smaller and larger, and recurses on each side. The work is in the partition; the combine is a plain concatenation."
- Static defaults in markup (the `merge` state): `#srCaption` "split [8, 3] | [5, 1] — sort each half, then merge"; `#srStep` "split, then merge: [3, 8] + [1, 5] → [1, 3, 5, 8]"; `#srResult` "[1, 3, 5, 8]". The `#srDivider` starts at `opacity="1"`, `#srPivotTag` at `opacity="0"`.
- Degrades: the static SVG shows the four bars and divider; `pick('merge')` on load re-applies the default state and fills `#srCode`/`#srOut`. Global `prefers-reduced-motion` respected; no browser storage.

### Footer build-stamp decoder (`#stamp`)

- Stamp id `TSK0NbZlvef8ts` (in `#stampId`); panel `#st-ts` hard-codes "2026-05-31 19:27:37 UTC".
- `decodeBranded(id)` over `B62 = "0123…XYZabc…xyz"` with `EPOCH_MS = 1704067200000`, `ts = snow >> 22n`, `node = (snow >> 12n) & 0x3FFn`, `seq = snow & 0xFFFn`. Decoded: namespace `TSK`, snowflake `319557553413423104`, node `0`, seq `0`, timestamp `2026-05-31 19:27:37 UTC`. Click / Enter / Space toggles `.open`/`aria-expanded`.

## References (#refs, verbatim)

Intro line: "Primary sources for this lesson, and where it connects in the course."

**Sources**
- Merge sort — Wikipedia (`https://en.wikipedia.org/wiki/Merge_sort`) — a stable functional sort.
- Cormen, Leiserson, Rivest & Stein. *Introduction to Algorithms* (4th ed., 2022) — sorting and searching, in depth.

**Related in this course**
- `/elixir/algorithms/sorting` — F4.03 · Sorting & searching
- `/elixir/algorithms/lists` — F4.01 · Lists, recursion & complexity
- `/elixir/functional/recursion` — F2.04 · Recursion patterns & tail calls

## Wiring

- route-tag (verbatim): `elixir` (`/elixir`) `/` `algorithms` (`/elixir/algorithms`) `/` `sorting` (`/elixir/algorithms/sorting`) `/` `<span class="rcur">sorts</span>` (current, no link).
- crumbs (verbatim): `F4` → `/elixir/algorithms` · sep `/` · `F4.03` → `/elixir/algorithms/sorting` · sep `/` · here `sorts`.
- toc-mini: `#split` ("Divide, then conquer") · `#worst` ("Advanced: worst cases & Enum.sort").
- pager: prev → `/elixir/algorithms/sorting` ("← F4.03 · sorting"); next → `/elixir/algorithms/sorting/search` ("Next · search →").
- footer (3-column `.foot-nav`): identical to the hub — brand → `/elixir`; Chapters column `/elixir/algebra`, `/elixir/functional`, `/elixir/language`, `/elixir/algorithms`, `/elixir/pragmatic`, `/elixir/phoenix`; The course column `/elixir`, `/elixir/course`, `/elixir/algebra/functions`. Header `.brand` → `/elixir`, `Contents` → `/elixir/course`.
- Page meta: `<title>` "Merge &amp; quicksort — F4.03.1 · jonnify"; `<meta description>` "The two workhorse comparison sorts are both divide-and-conquer. Merge sort halves the list, sorts each half, and merges; quicksort picks a pivot, partitions the rest into smaller and larger, and recurses. Both average O(n log n); merge sort is stable and O(n log n) worst case, quicksort can hit O(n^2)."

## Build instruction

To rebuild this dive, copy the `<head>…</style>`, `<header class="site">`, `<footer class="site-foot">`, and the two trailing `<script>` blocks verbatim from a recent BUILT sibling on the sage F4 accent — the model page is its sibling `elixir/algorithms/sorting/search.html`, which shares the identical head/header/footer/decoder and the lesson-hero lede CSS (`.hero-copy .lede`). Change only `<title>`/`<meta description>`, the `.route-tag` (current segment `sorts`), the crumbs/eyebrow ("part 1 of 3"), the pager, and the `<main>` body. Keep the clamp-spacing in `h1{font-size:clamp(2.7rem,1.9rem + 4.2vw,5.1rem)}` intact. No-invent guards: use only the real Portal surfaces as written — the branded store (`TSK…` Snowflake stamp), the event-sourced engine behind ONE `Portal` facade, the Phoenix web app; cite the companion course for OTP internals and do not re-teach. The Elixir shown (`Enum.sort/1`, `Enum.sort/2`, `Enum.sort_by/2`, `Enum.split/2`, `Enum.split_with/2`, `:lists.sort/1`) is standard-library API — quote it as written, do not invent functions. Voice rules: no first person, no exclamation marks, no emoji, none of "just"/"simply"/"obviously".
