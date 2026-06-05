# F4.03.2 — Linear & binary search (dive)

- Route (served): `/elixir/algorithms/sorting/search`
- File: `elixir/algorithms/sorting/search.html`
- Place in the chapter: the second of the three `F4.03 · sorting` dives (part 2 of 3). It follows `sorts` (part 1) and precedes `cost` (part 3). It is the searching half of the bargain — linear over anything, binary over a sorted, randomly-accessible sequence — and explains why the BEAM's linked lists send sorted data into tuples or trees.
- Accent: sage (F4 chapter accent; the search figure uses blue for linear and sage for the binary-found target).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F4.03 · part 2 of 3`

`h1` (verbatim): `Linear & binary search`

Lede (`.lede`, verbatim): "Linear search checks elements one at a time and works on any sequence — O(n). Binary search checks the middle, throws away the half that cannot contain the target, and repeats — O(log n) — but it only works on data that is *sorted* and supports jumping to the middle in one step. That second condition is the catch on the BEAM, and it is what sends sorted data into tuples or trees rather than lists."

Kicker (`.kicker`, verbatim): "Searching the sorted array `[5, 8, 10, 12, 20, 30, 42]` for `20`. Select a strategy and watch which elements it touches."

## Sections

In order:

1. `#find` — "Two ways to find 20" (teaching). Linear search walks from the left, comparing each element until it hits 20 at index 4 — five checks. Binary search starts in the middle and halves: 12 too small, go right; 30 too big, go left; 20 — found, in three checks. Carries the interactive figure and a `.take`: each binary comparison discards half of what remains, so it needs about `log₂ n` of them — three for seven elements, twenty for a million.
2. `#access` — "Advanced: binary search needs random access" (advanced). Binary search's halving assumes reaching the middle in one step. On a tuple or `:array`, `elem/2` does that in O(1), so binary search is genuinely O(log n). On a linked list it is a trap: reaching the middle is itself an O(n) walk, so "binary search" over a list is O(n log n) — slower than a plain linear scan. This is why `Enum.at/2` on a list is O(n), and why sorted data lives in a tuple. A balanced BST (F4.02) gives O(log n) search without contiguous memory; a hash-based map (F4.04) drops the cost to O(1) on average.

Real Elixir code shown (`pre.code` in `#access`, verbatim): a `linear/3` definition — `def linear([x | _], x, i), do: {:ok, i}`; `def linear([_ | t], x, i), do: linear(t, x, i + 1)`; `def linear([], _x, _i), do: :error` — and a `binary/2`/`binary/4` definition: `def binary(arr, x), do: binary(arr, x, 0, tuple_size(arr) - 1)`; `defp binary(_arr, _x, lo, hi) when lo > hi, do: :error`; `defp binary(arr, x, lo, hi) do mid = div(lo + hi, 2); case elem(arr, mid) do ^x -> {:ok, mid}; v when v < x -> binary(arr, x, mid + 1, hi); _ -> binary(arr, x, lo, mid - 1) end end`.

`.bridge`: "The idea" — "Sorted data lets each comparison discard half — but only if you can reach the middle in one step." → "In Elixir" — "Binary search wants a tuple (`elem/2` is O(1)); a list forces O(n), a tree gives O(log n)."

Closing `.note`: "Next: **stability & sort cost** — ranking the sorts, and the lower bound none of them can beat." (links `/elixir/algorithms/sorting/cost`.)

## The interactives

### Figure — "The strategy · select one" (`#seSel` selector + `#seOut`/`#seCode` readouts)

- `<figure class="fig" aria-labelledby="seTitle">`, heading `#seTitle` "The strategy · select one".
- Control group `#seSel` (role="group", aria-label "The strategy"), two `<button>`s:
  - `data-k="linear" data-c="blue"` — label "linear" — starts `active`
  - `data-k="binary" data-c="sage"` — label "binary"
- SVG `viewBox="0 0 720 176"`: seven boxes `#seBox0`–`#seBox6` holding the sorted array `5, 8, 10, 12, 20, 30, 42` (with index labels), and a `#seCaption` annotation. Below: `<pre class="code" id="seCode">`, `.geo-readout#seOut`, and `#seBadge`/`#seSteps`/`#seResult` spans.
- Pure function `pick(k)` over `CASES = {linear, binary}`: toggles `#seSel` button `active`/`aria-pressed`, restrokes each `seBox{i}` from `c.b[i]` (a `[colour, width]` pair), and writes `caption`/`badge`/`steps`/`code`/`out`. Colours: `SAGE='#a7c9b1'`, `BLUE='#9fc0ea'`, `DIM='#2a3252'`. Initial call `pick('linear')`.
- Readout strings (`CASES`, verbatim):
  - linear — caption "check each from the left until 20 — 5 checks"; badge "O(n)"; steps "checks elements one by one — 5 here"; `#seOut`: "**Linear search** compares from the left until it finds 20 — five elements here, and up to all seven if the target were last or absent. It needs no ordering, but it is O(n)."
  - binary — caption "mid 12 → right; mid 30 → left; mid 20 → found"; badge "O(log n)"; steps "halves the range — 3 comparisons"; `#seOut`: "**Binary search** compares the middle, discards the impossible half, and repeats: 12, then 30, then 20. Three comparisons — but only because the array is sorted and indexable."
- Static defaults in markup (the `linear` state): `#seCaption` "check each from the left until 20 — 5 checks"; `#seBadge` "O(n)"; `#seSteps` "checks elements one by one — 5 here"; `#seResult` "found 20 at index 4". Box 4 (value 20) starts stroked sage `#a7c9b1` width 3; boxes 5–6 start dim.
- Degrades: the static SVG shows all seven boxes with the linear-search highlight; `pick('linear')` on load re-applies and fills `#seCode`/`#seOut`. Global `prefers-reduced-motion` respected; no browser storage.

### Footer build-stamp decoder (`#stamp`)

- Stamp id `TSK0NbZlvsr5P6` (in `#stampId`); panel `#st-ts` hard-codes "2026-05-31 19:27:37 UTC".
- `decodeBranded(id)` over `B62 = "0123…XYZabc…xyz"` with `EPOCH_MS = 1704067200000`, `ts = snow >> 22n`, `node = (snow >> 12n) & 0x3FFn`, `seq = snow & 0xFFFn`. Decoded: namespace `TSK`, snowflake `319557553623138304`, node `0`, seq `0`, timestamp `2026-05-31 19:27:37 UTC`. Click / Enter / Space toggles `.open`/`aria-expanded`.

## References (#refs, verbatim)

Intro line: "Primary sources for this lesson, and where it connects in the course."

**Sources**
- Merge sort — Wikipedia (`https://en.wikipedia.org/wiki/Merge_sort`) — a stable functional sort.
- Cormen, Leiserson, Rivest & Stein (2022). *Introduction to Algorithms* (4th ed.) — sorting and searching, in depth.

**Related in this course**
- `/elixir/algorithms/sorting` — F4.03 · Sorting & searching
- `/elixir/algorithms/lists` — F4.01 · Lists, recursion & complexity
- `/elixir/functional/recursion` — F2.04 · Recursion patterns & tail calls

## Wiring

- route-tag (verbatim): `elixir` (`/elixir`) `/` `algorithms` (`/elixir/algorithms`) `/` `sorting` (`/elixir/algorithms/sorting`) `/` `<span class="rcur">search</span>` (current, no link).
- crumbs (verbatim): `F4` → `/elixir/algorithms` · sep `/` · `F4.03` → `/elixir/algorithms/sorting` · sep `/` · here `search`.
- toc-mini: `#find` ("Two ways to find 20") · `#access` ("Advanced: binary search needs random access").
- pager: prev → `/elixir/algorithms/sorting/sorts` ("← F4.03.1 · sorts"); next → `/elixir/algorithms/sorting/cost` ("Next · cost →").
- footer (3-column `.foot-nav`): identical to the hub — brand → `/elixir`; Chapters column `/elixir/algebra`, `/elixir/functional`, `/elixir/language`, `/elixir/algorithms`, `/elixir/pragmatic`, `/elixir/phoenix`; The course column `/elixir`, `/elixir/course`, `/elixir/algebra/functions`. Header `.brand` → `/elixir`, `Contents` → `/elixir/course`.
- Page meta: `<title>` "Linear &amp; binary search — F4.03.2 · jonnify"; `<meta description>` "Linear search checks elements one by one over any sequence — O(n). Binary search halves a sorted, randomly-accessible sequence — O(log n) — but a linked list has no O(1) middle, so binary search wants a tuple or a balanced tree, not a list."

## Build instruction

To rebuild this dive, copy the `<head>…</style>`, `<header class="site">`, `<footer class="site-foot">`, and the two trailing `<script>` blocks verbatim from a recent BUILT sibling on the sage F4 accent — the model page is its sibling `elixir/algorithms/sorting/sorts.html`, which shares the identical head/header/footer/decoder and the lesson-hero lede CSS (`.hero-copy .lede`). Change only `<title>`/`<meta description>`, the `.route-tag` (current segment `search`), the crumbs/eyebrow ("part 2 of 3"), the pager, and the `<main>` body. Keep the clamp-spacing in `h1{font-size:clamp(2.7rem,1.9rem + 4.2vw,5.1rem)}` intact. No-invent guards: use only the real Portal surfaces as written — the branded store (`TSK…` Snowflake stamp), the event-sourced engine behind ONE `Portal` facade, the Phoenix web app; cite the companion course for OTP internals and do not re-teach. The Elixir shown (`elem/2`, `tuple_size/1`, `div/2`, `Enum.at/2`, the `:array` reference) is standard-library API — quote it as written, do not invent functions. Voice rules: no first person, no exclamation marks, no emoji, none of "just"/"simply"/"obviously".
