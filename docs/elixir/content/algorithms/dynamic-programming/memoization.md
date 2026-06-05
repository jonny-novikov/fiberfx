# F4.11.1 — Memoization & overlapping subproblems (dive)

- Route (served): `/elixir/algorithms/dynamic-programming/memoization`
- File: `elixir/algorithms/dynamic-programming/memoization.html`
- Place in the chapter: the first of the three dives under the `F4.11` hub (`/elixir/algorithms/dynamic-programming`), part 1 of 3. It teaches the top-down style of dynamic programming — keep the natural recursion, add a cache — on the Portal use case of prerequisite depth, and hands off to `tabulation` (the bottom-up style).
- Accent: sage (the F4 · Algorithms & Data Structures chapter accent).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F4.11 · part 1 of 3 · prerequisite depth`

Hero `h1` (verbatim): Memoization & overlapping `subproblems`

Hero lede (verbatim):

> Every lesson sits at the end of a chain of prerequisites, and the Portal wants the **longest** such chain — how deep a learner must go before reaching it. `depth(lesson)` is one plus the deepest of its prerequisites, which is naturally recursive. The catch is that prerequisites are shared, so a plain recursion re-derives the depth of a popular prerequisite once for every path that passes through it. Memoisation caches each lesson's depth the first time it is computed, and every later visit is a lookup.

Kicker (verbatim):

> Six lessons, each building on the two before it. Switch between the plain recursion and the memoised one and count how many times each lesson's depth is evaluated.

## Sections

In order:

1. **`#eval` · Count the evaluations** (teaching) — running example: six lessons `L1…L6`, each depending on the two before it, computing `depth(L6)`. Carries the interactive figure.
2. **`#advanced` · Advanced: lazy by construction** — memoisation keeps the recursion exactly as written and threads a cache through it; it is lazy by construction, evaluating only the prerequisites the target depends on, at the cost of recursion depth and a cache lookup per call. The cache is one of this chapter's maps, threaded through the calls in a pure language or parked in an `Agent` / process dictionary when threading is noisy.

Real Elixir code shown (in `#advanced`) — the longest-prerequisite-chain recursion with a threaded cache:

```elixir
def depth(lesson, cache) do
  case cache do
    %{^lesson => d} -> {d, cache}                       # cache hit — O(1)
    _ ->
      {d, cache} =
        lesson
        |> Catalog.prerequisites()
        |> Enum.reduce({0, cache}, fn p, {mx, c} ->
          {dp, c} = depth(p, c)                       # recurse, reusing the cache
          {max(mx, dp), c}
        end)
      {d + 1, Map.put(cache, lesson, d + 1)}   # store and return
  end
end
```

The `.bridge` reads `a recursion (depth(l) = 1 + max(depth(prereqs)), re-deriving shared lessons) → a recursion plus a cache (each lesson evaluated once; the rest are lookups. Lazy — only what the target needs)`.

## The interactives

### `#eval` figure — `aria-labelledby="mzTitle"`
- Figcaption `h4` (`#mzTitle`): `Mode · select one`.
- Control group `#mzSel` (`role="group"`, `aria-label="Recursion mode"`). Buttons: `data-k="naive" data-c="gold"` (label `plain recursion`, default `.active`), `data-k="memo" data-c="sage"` (label `memoised`).
- SVG element ids: `#mzNodes` (six nodes built in JS — for each `L1…L6` a `#mzN_<id>` circle, depth label, a `#mzB_<id>` badge rect, and a `#mzC_<id>` count text), and `#mzTotalT` (the total). Below the figure: `#mzCode` (`pre.code`, `aria-live="polite"`), `#mzOut` (`.geo-readout`), `#mzRole` (evaluations), `#mzResult` (`depth(L6)`).
- Pure data and function: per-lesson layout `XS`, order `ORDER`, depths `DEPTH = { L1:1 … L6:6 }`; the naive evaluation multiplicities for `depth(L6)` are `NAIVE = { L1:8, L2:5, L3:3, L4:2, L5:1, L6:1 }` (the Fibonacci numbers), with `NAIVE_TOTAL = 20` and `MEMO_TOTAL = 6`. `pick(k)` recolours the badges (repeated counts gold, ones sage) and writes the total, code, and prose.
- Readout strings (verbatim). Static SVG default: `total: 20 evaluations`; footnote `badge = times depth() is evaluated · arcs = prerequisites`. Plain-recursion (`naive`) prose: `The plain recursion evaluates depth 20 times to find depth(L6) = 6 — L1 alone eight times, because eight recursion paths reach it. The per-lesson counts are the Fibonacci numbers, so the total grows exponentially with the chain.` Memoised prose: `With the cache, each of the six lessons is evaluated once and every later visit is a lookup — 6 evaluations for the same depth(L6) = 6. The exponential repetition collapses to one pass over the lessons the target depends on.`
- `#eval` takeaway (verbatim): `The plain recursion evaluates the deepest-shared lessons many times over — the counts are the Fibonacci numbers, growing with the chain. The cache flattens every count to one, so the work is one evaluation per lesson.`

### Degrade behaviour
The figure's nodes/badges and the readouts are populated by JS (`pick('naive')` on load); the SVG ships with the static `total: 20 evaluations` and the prerequisite arcs in markup. `prefers-reduced-motion: reduce` disables smooth scrolling, the `.arc-flow` animation, and `.reveal` transitions; `.reveal` sections show immediately without JS / `IntersectionObserver`.

### Footer build-stamp decoder
Stamp id `TSK0NcfoeKhFBo`. Decoded by the inline base-62 / Snowflake decoder: namespace `TSK`, snowflake `319797177738067968`, node `0`, seq `0`, timestamp `2026-06-01 11:19:48 UTC` (the value shown in the `#st-ts` panel).

## References (#refs, verbatim)

Intro line: `Primary sources for this lesson, and where it connects in the course.`

Sources:
- [Memoization — Wikipedia](https://en.wikipedia.org/wiki/Memoization) — caching a recursion by argument.
- [Overlapping subproblems — Wikipedia](https://en.wikipedia.org/wiki/Overlapping_subproblems) — why the plain recursion repeats work.
- [Elixir — Agent](https://hexdocs.pm/elixir/Agent.html) — a place to park a cache when threading is noisy.

Related in this course:
- `/elixir/algorithms/dynamic-programming` — F4.11 · Dynamic programming & advanced problems — the module hub.
- `/elixir/algorithms/maps` — F4.04 · Maps, sets & hashing — the map behind the cache.
- `/elixir/algorithms` — F4 · Algorithms & Data Structures.

## Wiring

- route-tag (verbatim): `/ ` `elixir` `/` `algorithms` `/` `dynamic-programming` `/` `memoization` (current segment `memoization` in `.rcur`; `elixir`, `algorithms`, `dynamic-programming` are links).
- crumbs (verbatim): `F4` (→ `/elixir/algorithms`) `/` `F4.11` (→ `/elixir/algorithms/dynamic-programming`) `/` `memoization` (`.here`).
- toc-mini: `#eval` → `Count the evaluations`; `#advanced` → `Advanced: lazy by construction`.
- pager: prev → `/elixir/algorithms/dynamic-programming` label `F4.11 · dynamic-programming`; next → `/elixir/algorithms/dynamic-programming/tabulation` label `Next · tabulation`.
- footer columns. **Chapters:** `/elixir/algebra`, `/elixir/functional`, `/elixir/language`, `/elixir/algorithms`, `/elixir/pragmatic`, `/elixir/phoenix`. **The course:** `/elixir` (Course home), `/elixir/course` (Contents & history), `/elixir/algebra/functions` (Start · F1.01). Foot tag: `Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir.`
- Page meta. `<title>`: `Memoization & overlapping subproblems — F4.11.1 · jonnify`. `<meta name="description">`: `The longest prerequisite chain to a lesson is one plus the deepest of its prerequisites — a recursion. Because prerequisites are shared, the plain recursion re-derives a popular one along every path that reaches it: over six lessons each built on the two before it, depth(L6) evaluates the lessons 8, 5, 3, 2, 1, 1 times — the Fibonacci numbers, 20 in all — while a cache evaluates each once, 6 in all, for the same answer.`

## Build instruction

To rebuild this page, copy the `head`…`</style>`, the `header`, the `footer`, and the two trailing `<script>` blocks (the figure-and-stamp IIFE plus the reveal-on-scroll enhancer) verbatim from a recent BUILT sibling dive on the sage F4 accent — the closest model is the sibling dive `tabulation.html` in this same module directory (same hero-without-art lesson layout, the same one-teaching-plus-one-advanced section shape, the same `.solid-select` figure shell). Change only the `<title>`/`<meta name="description">`, the route-tag, the crumbs/toc-mini/pager, and the `<main>` body (the `#eval` figure, the `#advanced` section with its `pre.code` and `.bridge`, and the References block). No-invent guards: cite only the real Portal surfaces as written — here `Catalog.prerequisites/1`, the branded `Store`, and the event-sourced engine behind the single `Portal` facade; cite the companion course for OTP internals (the `Agent` reference) rather than re-teaching them, and do not invent a route, id, readout string, code token, or reference URL. Voice rules: no first person, no exclamation marks, no emoji, and none of `just`/`simply`/`obviously`. Model sibling to copy from: `elixir/algorithms/dynamic-programming/tabulation.html`.
