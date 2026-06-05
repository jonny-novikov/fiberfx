# F2.08.2 — The pipe operator (dive)

- Route (served): `/elixir/functional/composition/pipe`
- File: `elixir/functional/composition/pipe.html`
- Place in the chapter: the second of the three dives under the `F2.08` composition hub. It follows function composition (`F2.08.1`) and precedes building pipelines (`F2.08.3`). It belongs to the arc that takes the same composition and rewrites it forwards: the pipe operator threads a value through a series of functions in execution order.
- Accent: elixir (purple).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `F2.08 · part 2 of 3`

Hero lede (verbatim):

> The pipe operator `|>` takes the value on its left and passes it as the first argument to the call on its right. Chained, it threads a value through a series of functions, written in the order they run — the opposite of reading nested calls from the inside out.

Kicker (verbatim):

> It is purely a rewrite. `x |> f()` is `f(x)`; `x |> f(a)` is `f(x, a)`. Nothing is added but clarity: a long `f(g(h(x)))` becomes a top-to-bottom list of steps. The one thing to keep in mind is that the piped value always lands in the first argument position.

## Sections

In order:

1. **Nested or piped** (`#forms`) — teaching section. The nested call `square(double(inc(x)))` and the pipe `x |> inc() |> double() |> square()` compute the same value; nested reads inside out, the pipe reads in order. Carries a `deflist`: `pipe operator` (`|>` — feeds the left value as the first argument on the right), `first argument` (where the piped value lands in the call), `desugar` (the plain nested call a pipe is shorthand for), `readability` (steps read top to bottom, in execution order).
2. **Extra arguments** (`#args`) — teaching section. When a piped function takes more arguments, the piped value fills the first slot and the rest follow; `x |> f(a)` is `f(x, a)`, never `f(a, x)`.
3. **Worked examples** (`#gallery`) — advanced gallery section. A string pipeline, a list pipeline, a call with extra arguments, and the first-argument rule.

Running example: `inc`/`double`/`square` over an integer for the forms figure; `Kernel.+`, `Enum.take`, `Enum.map`, `Enum.join` for the extra-arguments figure. The real Elixir shown threads values with `|>` and demonstrates desugaring to plain nested calls.

## The interactives

### Figure 1 — `same value · two ways to write it` (`#fmTitle`)
- Form toggle `#fmSel` (`role="group"`): button `data-k="nested"` `data-c="blue"` `nested` (active default); button `data-k="piped"` `data-c="gold"` `piped`.
- Control `.fold-ctrl`: range `#fmX` (`0`–`5`, value `2`), readout `#fmXval`.
- SVG ids: `#fmForm`, `#fmReads`, `#fmFlow`, `#fmRes`.
- Pure function `renderFm`: `m1 = x + 1`, `m2 = m1 * 2`, `m3 = m2 * m2`; the nested form prints `square(double(inc(x)))`, the piped form prints `x |> inc() |> double() |> square()`.
- Code block `#fmCode` shows either `square(double(inc(2)))   # => 36` (nested) or `2` / `|> inc()` / `|> double()` / `|> square()` / `# => 36` (piped).
- Readout `#fmOut` (verbatim default): `both forms compute ((x+1) × 2)² · nested reads inside out, piped reads in order · 36`.

### Figure 2 — `x |> f(a) becomes f(x, a)` (`#agTitle`)
- Call toggle `#agSel` (`role="group"`): button `data-k="add"` `data-c="gold"` `Kernel.+` (active default); `data-k="take"` `data-c="blue"` `Enum.take`; `data-k="map"` `data-c="sage"` `Enum.map`; `data-k="join"` `data-c="elixir"` `Enum.join`.
- SVG ids: `#agPiped`, `#agDesugar`, `#agResult`.
- Pure renderer (script `AG`) maps each call to its piped form, desugared nested form, and result — the piped value always lands first.
- Code block `#agCode` + readout `#agOut` (verbatim default): `5 |> Kernel.+(3) · 5 is the first argument · 8`.

### Figure 3 — Worked examples gallery (`#gSel`)
- Example toggle `#gSel` (`role="group"`): button `data-g="string"` `data-c="gold"` `string` (active default); `data-g="list"` `data-c="blue"` `list`; `data-g="args"` `data-c="sage"` `with args`; `data-g="rule"` `data-c="elixir"` `first arg`.
- Code block `#gCode` + readout `#gOut`. Gallery entries (`GAL`):
  - `string` — `"  Hello  "` / `|> String.trim()` / `|> String.downcase()` / `# => "hello"`; note `trim then downcase, read top to bottom`.
  - `list` — `[3, 1, 2]` / `|> Enum.sort()` / `|> Enum.reverse()` / `# => [3, 2, 1]`; note `sort then reverse a list`.
  - `args` — `data` / `|> Enum.filter(&(&1 > 0))` / `|> Enum.take(3)` / `# extra args follow the piped value`; note `each stage carries its own extra arguments`.
  - `rule` — `x |> f(a)   # => f(x, a), not f(a, x)` / `# the pipe fills the first argument`; note `the piped value lands first, always`.
- Readout `#gOut` (verbatim default): `string · trim then downcase, read top to bottom`.

Degrade behaviour: every figure renders default values from static SVG markup, with JS renderers (`renderFm`/`renderAg`/`renderG`) re-driving them on input. The `.arc-flow` dashed animation is `@media (prefers-reduced-motion: no-preference)` only; reveal-on-scroll (`.reveal`) is JS-gated and collapses to visible under `prefers-reduced-motion: reduce` or when `IntersectionObserver` is absent.

Footer build-stamp: `#stamp` with `#stampId` = `TSK0Nau6Dkl8ls`; the decoder (`decodeBranded`, namespace `TSK`, epoch `1704067200000`) populates the panel, whose `#st-ts` default reads `2026-05-31 09:44:28 UTC`.

## References (#refs, verbatim)

This page has no `#refs` References section (no Sources / Related-in-this-course block). Cross-links are carried inline: the `.bridge` cells reference `Idea` and `F2.08.1 · compose` (`This is the same composition, written forwards instead of nested.`); the pager links the prior and next dives.

## Wiring

- route-tag (verbatim): `/` `elixir` `/` `functional` `/` `composition` `/` `pipe` (the `pipe` segment is the current `.rcur`).
- crumbs (verbatim): `F2` `/` `F2.08` `/` `pipe` (the last is `.here`), linking `/elixir/functional` and `/elixir/functional/composition`.
- toc-mini: `#forms` Nested or piped · `#args` Extra arguments · `#gallery` Worked examples.
- pager: prev → `/elixir/functional/composition/compose` (`← Part 1 · composition`); next → `/elixir/functional/composition/pipeline` (`Part 3 · pipelines →`).
- footer: column **Chapters** — `/elixir/algebra` F1 · Algebra, `/elixir/functional` F2 · Functional Programming, `/elixir/language` F3 · The Elixir Language, `/elixir/algorithms` F4 · Algorithms & Data Structures, `/elixir/pragmatic` F5 · Pragmatic Programming, `/elixir/phoenix` F6 · Phoenix Framework. Column **The course** — `/elixir` Course home, `/elixir/course` Contents & history, `/elixir/algebra/functions` Start · F1.01. Foot brand links `/elixir`.
- Page meta — `<title>`: `The pipe operator — F2.08.2 · jonnify`. `<meta description>`: `The |> operator: threading a value as the first argument, reading left to right instead of inside out, and passing extra arguments.`

## Build instruction

To rebuild this dive, copy the `head…</style>`, the `header.site`, the `footer.site-foot`, and the two trailing `<script>` blocks (the figure renderers `renderFm`/`renderAg`/`renderG` + the Snowflake decoder, then the JS-on / reveal-on-scroll bootstrap) verbatim from a recent BUILT dive on the elixir (purple) accent; change only the `<title>`/`<meta description>`, the header `route-tag` (ending `.rcur` = `pipe`), the crumbs, and the `<main>` body (eyebrow `part 2 of 3`, hero `.lede`/`.kicker`, the three `<section>` figures, the pager). The model sibling to copy from is its own sibling dive on this accent — `elixir/functional/composition/compose.html` (`F2.08.1`, identical dive shell: hero, two teaching figures with `solid-select` toggles, a gallery, pager). No-invent guards: this is a mathematics-then-Elixir lesson and does not touch the live Portal product surface — do not invent Portal APIs, and defer OTP/Phoenix internals to the companion chapters (`F5 · Pragmatic`, `F6 · Phoenix`) rather than re-teaching them. Use only the real Elixir surfaces shown (`|>`, `String.trim`/`String.downcase`, `Enum.sort`/`Enum.reverse`/`Enum.filter`/`Enum.take`/`Enum.map`/`Enum.join`, `Kernel.+`, capture syntax). Voice rules: no first person, no exclamation marks, no emoji, and none of just / simply / obviously.
