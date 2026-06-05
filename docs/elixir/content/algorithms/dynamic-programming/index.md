# F4.11 — Dynamic programming & advanced problems (module hub)

- Route (served): `/elixir/algorithms/dynamic-programming`
- File: `elixir/algorithms/dynamic-programming/index.html`
- Place in the chapter: the eleventh of F4's twelve modules (`F4.01` lists → `F4.12` lab), and the last teaching module before the closing lab `F4.12`. Its predecessor is `F4.10 — Practical recipes in Elixir`; it frames three dives — memoisation (top-down), tabulation (bottom-up), and a classic two-dimensional problem (edit distance) — each grounded in a Portal use case (prerequisite depth, a credit target, typo-tolerant search). The cache and the table are the maps introduced earlier in the chapter (`F4.04`).
- Accent: sage (the F4 · Algorithms & Data Structures chapter accent).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F4 · Dynamic programming · module 11`

Hero `h1` (verbatim): Dynamic `programming` & advanced problems

Hero lede (verbatim):

> Dynamic programming is the move you reach for when a problem breaks into **overlapping subproblems**: solve each one once, remember the answer, and reuse it. Two styles do this — memoisation caches a recursion top-down, tabulation fills a table bottom-up. The Portal leans on both wherever it would otherwise recompute the same thing: the depth of a prerequisite chain, the fewest modules to reach a credit target, the closest catalog entry to a misspelled search.

Kicker (verbatim):

> A bottom-up table makes the idea concrete: each cell `f[i]` is a stored subproblem, computed once from cells already filled to its left, then read back instead of recomputed. The figure fills a Fibonacci memo table cell by cell, drawing the two dependencies into each new entry.

## What the page frames

The hub carries three teaching sections (`#pace`, `#styles`, `#advanced`) and a card list of three dives in `#styles`. Each dive card:

- **`F4.11.1 · prerequisite depth` — Memoization & overlapping subproblems** — top-down: compute the longest prerequisite chain to a lesson recursively and cache each lesson's depth, so a shared prerequisite is evaluated once instead of along every path that reaches it. Route: `/elixir/algorithms/dynamic-programming/memoization`. Built. (Card left-border accent: sage.)
- **`F4.11.2 · the credit target` — Tabulation & bottom-up** — bottom-up: fill a table of the fewest modules to reach each credit total from zero upward, so the answer for the target reads off a row built from smaller answers — where greedy choice fails, the table is optimal. Route: `/elixir/algorithms/dynamic-programming/tabulation`. Built. (Card left-border accent: blue.)
- **`F4.11.3 · typo-tolerant search` — Classic DP problems** — edit distance, the textbook two-dimensional DP, put to work: how many single-character edits turn a misspelled query into a catalog title, filled cell by cell to power a "did you mean" suggestion. Route: `/elixir/algorithms/dynamic-programming/problems`. Built. (Card left-border accent: gold.)

Section `#pace` ("The cost of recomputing") sets up the recurrence `ways(n) = ways(n-1) + ways(n-2)` — the Fibonacci recurrence on track pacings. Section `#advanced` ("Advanced: when DP applies") gives the optimal-substructure-plus-overlapping-subproblems condition and contrasts the two styles, closing with a `.bridge` and a `.note`.

## The interactives

### Hero figure — `aria-labelledby="hpTitle"`
- Figcaption title (`#hpTitle`): `A memo table fills left to right`.
- The SVG draws a one-dimensional Fibonacci memo table, cells indexed 0 to 7, with `FIB = [0, 1, 1, 2, 3, 5, 8, 13]` for the recurrence `f[i]=f[i-1]+f[i-2]`. Static default markup (visible without JS): cells `f[0]=0` and `f[1]=1` filled (base cases), `f[2..7]` empty; no dependency arrows drawn yet.
- Control group: `.hp-ctrls`. Buttons: `#hpFill` (label `▸ fill next cell`) and `#hpReset` (label `reset`, `.ghost`).
- Element ids: `#hpArrows` (the dependency-arrow group), `#hpRow` (the cell row), `#hpCap` (`aria-live="polite"` caption).
- Pure functions (in the hero IIFE): `cell(i, isNew)` renders one cell; `depArrows(i)` arcs two dependency arrows into cell `i` from `i-1` and `i-2`; `render(newIdx)` rebuilds the row and the caption; `filled` tracks how many cells hold a value, starting at 2 (the base cases).
- Readout strings (verbatim). Initial / reset caption: `f[i] = f[i-1] + f[i-2]` then `Base cases f[0]=0, f[1]=1 are filled. Fill the next cell from the two to its left.` On filling cell `newIdx ≥ 2`, line 1 is `f[newIdx] = f[newIdx-1] + f[newIdx-2] = … + … = …` (computed); line 2 is `Stored once, then read back — the next cell reuses it instead of recomputing.`, or on the last cell `Table full: f[0..7] computed once each, every later cell read instead of recomputed.`

### `#pace` figure — `aria-labelledby="dpTitle"`
- Figcaption `h4` (`#dpTitle`): `Track length · select one`.
- Control group `#dpSel` (`role="group"`, `aria-label="Track length"`). Buttons: `data-n="5" data-c="sage"` (label `5 lessons`, default `.active`), `data-n="10" data-c="blue"` (label `10 lessons`), `data-n="20" data-c="gold"` (label `20 lessons`).
- SVG element ids: `#dpWays`, `#dpBarNaive`, `#dpNaiveN`, `#dpBarDP`, `#dpDPN`, `#dpCaption`. Below the figure: `#dpCode` (`pre.code`, `aria-live="polite"`), `#dpOut` (`.geo-readout`), `#dpRole` (naive calls), `#dpResult` (cached subproblems).
- Pure function: `compute(n)` returns `{ ways, calls, subs }` — `ways[n]` by the DP recurrence, `calls[n] = 1 + calls[n-1] + calls[n-2]` (the naive call count by the same recurrence), and `subs: n` (one distinct subproblem per lesson). Bars are drawn on a logarithmic scale against `MAXLOG = Math.log10(compute(20).calls)`.
- Readout strings (verbatim). Static SVG default (n=5): `distinct pacings: ways(5) = 8`, `naive recursion · calls`, `9 calls`, `with a cache · subproblems`, `5 subproblems`, `bars are on a logarithmic scale; labels are the actual counts`, `about 2× fewer evaluations`. The JS sets `#dpWays` to `distinct pacings: ways(<n>) = <ways>`, the caption to `about <speed>× fewer evaluations`, and `#dpOut` to `There are <ways> ways to pace an <n>-lesson track. The naive recursion makes <calls> calls to find that, against <subs> distinct subproblems with a cache — about <speed>× fewer evaluations, and the gap widens with length.`

### `#styles`
No interactive figure — three static dive-card anchors (the three dives).

### `#advanced`
No interactive figure — a static `pre.code` (the `memo`/`tab` recurrence both ways), a `.bridge` (`overlapping subproblems → solve each once`), and a `.note`.

### Degrade behaviour
Static SVG content is authored in the markup so both figures read without JS (hero shows the two base cases filled, `#pace` shows the n=5 default counts). `prefers-reduced-motion: reduce` disables `scroll-behavior`, the `.hp-new` cell-in animation, and the `.arc-flow` dash animation; `.reveal` sections show immediately when JS or `IntersectionObserver` is unavailable.

### Footer build-stamp decoder
Stamp id `TSK0Ncfoe3NiFs`. Decoded by the inline base-62 / Snowflake decoder: namespace `TSK`, snowflake `319797177482215424`, node `0`, seq `0`, timestamp `2026-06-01 11:19:48 UTC` (the value shown in the `#st-ts` panel).

## References (#refs, verbatim)

Intro line: `Primary sources for this lesson, and where it connects in the course.`

Sources:
- [Dynamic programming — Wikipedia](https://en.wikipedia.org/wiki/Dynamic_programming) — optimal substructure and overlapping subproblems.
- [Memoization — Wikipedia](https://en.wikipedia.org/wiki/Memoization) — caching a recursion top-down.
- [Elixir — Map](https://hexdocs.pm/elixir/Map.html) — the cache and the table are maps.

Related in this course:
- `/elixir/algorithms/recipes` — F4.10 · Practical recipes in Elixir — the idioms these solutions are written in.
- `/elixir/algorithms/maps` — F4.04 · Maps, sets & hashing — the map behind the cache.
- `/elixir/algorithms` — F4 · Algorithms & Data Structures.

## Wiring

- route-tag (verbatim): `/ ` `elixir` `/` `algorithms` `/` `dynamic-programming` (current segment `dynamic-programming` in `.rcur`; `elixir` → `/elixir`, `algorithms` → `/elixir/algorithms`).
- crumbs (verbatim): `F4 · Algorithms & Data Structures` (→ `/elixir/algorithms`) `/` `F4.11 · dynamic-programming` (`.here`).
- toc-mini: `#pace` → `The cost of recomputing`; `#styles` → `Two styles, three dives`; `#advanced` → `Advanced: when DP applies`.
- pager: prev → `/elixir/algorithms/recipes` label `F4.10 · recipes`; next → `/elixir/algorithms/dynamic-programming/memoization` label `Start · memoisation`.
- footer columns. **Chapters:** `/elixir/algebra` (F1 · Algebra), `/elixir/functional` (F2 · Functional Programming), `/elixir/language` (F3 · The Elixir Language), `/elixir/algorithms` (F4 · Algorithms & Data Structures), `/elixir/pragmatic` (F5 · Pragmatic Programming), `/elixir/phoenix` (F6 · Phoenix Framework). **The course:** `/elixir` (Course home), `/elixir/course` (Contents & history), `/elixir/algebra/functions` (Start · F1.01). Foot tag: `Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir.`
- Page meta. `<title>`: `Dynamic programming & advanced problems — F4.11 · jonnify`. `<meta name="description">`: `Dynamic programming solves a problem with overlapping subproblems by solving each once and reusing it, in two styles: memoisation caches a recursion top-down, tabulation fills a table bottom-up. The hub counts how a learner can pace a track one or two lessons at a time — the Fibonacci recurrence — contrasting the exponential naive call count against one subproblem per lesson, and points to three Portal cases: prerequisite depth, a credit target, and typo-tolerant search.`

## Build instruction

To rebuild this page, copy the `head`…`</style>`, the `header`, the `footer`, and the two trailing `<script>` blocks (the figure-and-stamp IIFE plus the reveal-on-scroll enhancer) verbatim from a recent BUILT sibling on the sage F4 accent — the closest model is the sibling hub `elixir/algorithms/recipes/index.html` (`F4.10`, same chapter accent, same hub anatomy of three teaching sections plus a dive-card list). Change only the `<title>`/`<meta name="description">`, the route-tag, the crumbs/toc-mini/pager, and the `<main>` body (hero figure, the `#pace`/`#styles`/`#advanced` sections, and the References block). No-invent guards: cite only the real Portal surfaces as written — the branded `Store`, the event-sourced engine behind the single `Portal` facade, and the Phoenix web app; cite the companion course for any OTP internals rather than re-teaching them, and do not invent a route, id, readout string, code token, or reference URL. Voice rules: no first person, no exclamation marks, no emoji, and none of `just`/`simply`/`obviously`. Model sibling to copy from: `elixir/algorithms/recipes/index.html`.
