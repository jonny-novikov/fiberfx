# F4.11.2 — Tabulation & bottom-up (dive)

- Route (served): `/elixir/algorithms/dynamic-programming/tabulation`
- File: `elixir/algorithms/dynamic-programming/tabulation.html`
- Place in the chapter: the second of the three dives under the `F4.11` hub (`/elixir/algorithms/dynamic-programming`), part 2 of 3. It teaches the bottom-up style — fill a table from the base case up — on the Portal use case of the fewest modules to reach a credit target, contrasting it with greedy choice, and hands off to `problems` (the two-dimensional classic).
- Accent: sage (the F4 · Algorithms & Data Structures chapter accent).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F4.11 · part 2 of 3 · the credit target`

Hero `h1` (verbatim): Tabulation & `bottom-up`

Hero lede (verbatim):

> A certificate needs a fixed number of credits, and modules are worth one, three, or four credits each. What is the fewest modules that sum to the target exactly? The answer for a total is one more than the best answer for that total minus a module's worth — optimal substructure. Tabulation builds it **bottom-up**: fill a table of the fewest modules for every total from zero upward, and the target's answer is the last cell, read off the smaller ones already computed.

Kicker (verbatim):

> Pick a target and watch the table fill from zero. The grabby choice — take the biggest module that fits — is not always optimal; the table always is.

## Sections

In order:

1. **`#fill` · Fill from zero up** (teaching) — running example: modules worth `1, 3, 4` credits; cell `dp[c]` is `1 + min(dp[c-1], dp[c-3], dp[c-4])` over the worths that fit, with `dp[0] = 0`. Carries the interactive figure.
2. **`#advanced` · Advanced: why greedy can lose** — greedy takes the largest module that fits (for a target of six: four, then two ones — three modules), while `dp[c]` compares every module worth and keeps the best (two threes — two modules); tabulation suits this because the table is dense, and it is the same solve-each-once as memoisation run eagerly from the base case up.

Real Elixir code shown (in `#advanced`) — the fewest-modules table filled in one reduce pass:

```elixir
def fewest(target, worths \\ [1, 3, 4]) do
  Enum.reduce(1..target//1, %{0 => 0}, fn c, dp ->
    best =
      worths
      |> Enum.filter(&(&1 <= c))
      |> Enum.map(&(dp[c - &1] + 1))    # 1 + a smaller, already-filled cell
      |> Enum.min(fn -> :infinity end)
    Map.put(dp, c, best)
  end)[target]
end
```

The `.bridge` reads `greedy (largest module first — can strand a remainder and lose) → a bottom-up table (every total solved from zero up, weighing all worths; the target is optimal)`.

## The interactives

### `#fill` figure — `aria-labelledby="tbTitle"`
- Figcaption `h4` (`#tbTitle`): `Target credits · select one · modules worth 1, 3, 4`.
- Control group `#tbSel` (`role="group"`, `aria-label="Target credits"`). Buttons: `data-n="6" data-c="sage"` (label `6 credits`, default `.active`), `data-n="8" data-c="blue"` (label `8 credits`), `data-n="11" data-c="gold"` (label `11 credits`).
- SVG element ids: `#tbCells` (the cell row built in JS), `#tbArcLabel`, `#tbCaption`. Below the figure: `#tbCode` (`pre.code`, `aria-live="polite"`), `#tbOut` (`.geo-readout`), `#tbRole` (target), `#tbResult` (fewest modules).
- Pure function: `table(n)` fills `dp[0..n]` bottom-up over `WORTHS = [1, 3, 4]`, recording in `from[c]` which worth gives each cell's minimum (preferring the larger worth on a tie); returns `{ dp, from }`.
- Readout strings (verbatim). Static SVG default (target 6): header `dp[c] = fewest modules summing to c credits`; `#tbArcLabel` `dp[6] = 1 + dp[3] = 2`; `#tbCaption` `two modules (3 + 3) — greedy would use three`. Below the figure the static labels read `target: 6 credits` and `fewest modules: 2 modules`.
- `#fill` takeaway (verbatim): `Every cell is solved once, smallest first, and the target reads straight off the table. Because each cell weighs all module choices, the table never gets trapped by a greedy first move.`

### Degrade behaviour
The cell row, code, and prose are written by JS; the SVG ships with the static `dp[6]` labels (`dp[6] = 1 + dp[3] = 2` and the greedy-comparison caption) in markup so the default state reads without JS. `prefers-reduced-motion: reduce` disables smooth scrolling, the `.arc-flow` animation, and `.reveal` transitions; `.reveal` sections show immediately without JS / `IntersectionObserver`.

### Footer build-stamp decoder
Stamp id `TSK0NcfoeasNbU`. Decoded by the inline base-62 / Snowflake decoder: namespace `TSK`, snowflake `319797177977143296`, node `0`, seq `0`, timestamp `2026-06-01 11:19:48 UTC` (the value shown in the `#st-ts` panel).

## References (#refs, verbatim)

Intro line: `Primary sources for this lesson, and where it connects in the course.`

Sources:
- [Change-making problem — Wikipedia](https://en.wikipedia.org/wiki/Change-making_problem) — fewest coins, and where greedy fails.
- [Dynamic programming — Wikipedia](https://en.wikipedia.org/wiki/Dynamic_programming) — bottom-up tabulation and optimal substructure.
- [Elixir — `Enum.reduce/3`](https://hexdocs.pm/elixir/Enum.html#reduce/3) — filling the table in one pass.

Related in this course:
- `/elixir/algorithms/dynamic-programming` — F4.11 · Dynamic programming & advanced problems — the module hub.
- `/elixir/algorithms/recipes` — F4.10 · Practical recipes in Elixir — the reduce pipeline that fills the table.
- `/elixir/algorithms` — F4 · Algorithms & Data Structures.

## Wiring

- route-tag (verbatim): `/ ` `elixir` `/` `algorithms` `/` `dynamic-programming` `/` `tabulation` (current segment `tabulation` in `.rcur`; `elixir`, `algorithms`, `dynamic-programming` are links).
- crumbs (verbatim): `F4` (→ `/elixir/algorithms`) `/` `F4.11` (→ `/elixir/algorithms/dynamic-programming`) `/` `tabulation` (`.here`).
- toc-mini: `#fill` → `Fill from zero up`; `#advanced` → `Advanced: why greedy can lose`.
- pager: prev → `/elixir/algorithms/dynamic-programming/memoization` label `F4.11.1 · memoization`; next → `/elixir/algorithms/dynamic-programming/problems` label `Next · classic problems`.
- footer columns. **Chapters:** `/elixir/algebra`, `/elixir/functional`, `/elixir/language`, `/elixir/algorithms`, `/elixir/pragmatic`, `/elixir/phoenix`. **The course:** `/elixir` (Course home), `/elixir/course` (Contents & history), `/elixir/algebra/functions` (Start · F1.01). Foot tag: `Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir.`
- Page meta. `<title>`: `Tabulation & bottom-up — F4.11.2 · jonnify`. `<meta name="description">`: `The fewest modules (worth 1, 3, or 4 credits) summing to a target is one more than the best answer for the target minus a module's worth — optimal substructure. Tabulation fills a table of the fewest modules for every total from zero up, so the target reads off smaller cells. For six credits the table finds two (3 + 3) where greedy takes three (4 + 1 + 1), because greedy commits to a locally largest step and the table weighs all worths.`

## Build instruction

To rebuild this page, copy the `head`…`</style>`, the `header`, the `footer`, and the two trailing `<script>` blocks (the figure-and-stamp IIFE plus the reveal-on-scroll enhancer) verbatim from a recent BUILT sibling dive on the sage F4 accent — the closest model is the sibling dive `memoization.html` in this same module directory (same hero-without-art lesson layout, the same one-teaching-plus-one-advanced section shape, the same `.solid-select` figure shell). Change only the `<title>`/`<meta name="description">`, the route-tag, the crumbs/toc-mini/pager, and the `<main>` body (the `#fill` figure, the `#advanced` section with its `pre.code` and `.bridge`, and the References block). No-invent guards: cite only the real Portal surfaces as written — the branded `Store`, the event-sourced engine behind the single `Portal` facade, and the Phoenix web app; cite the companion course for any OTP internals rather than re-teaching them, and do not invent a route, id, readout string, code token, or reference URL. Voice rules: no first person, no exclamation marks, no emoji, and none of `just`/`simply`/`obviously`. Model sibling to copy from: `elixir/algorithms/dynamic-programming/memoization.html`.
