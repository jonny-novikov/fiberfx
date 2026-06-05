# F2.08.1 — Function composition (dive)

- Route (served): `/elixir/functional/composition/compose`
- File: `elixir/functional/composition/compose.html`
- Place in the chapter: the first of the three dives under the `F2.08` composition hub. It teaches composition by hand — `f after g` — before the pipe operator (`F2.08.2`) rewrites the same chain in execution order. It belongs to the arc that turns small functions into larger ones, opening with non-commutativity and ending with a three-function chain.
- Accent: elixir (purple).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `F2.08 · part 1 of 3`

Hero lede (verbatim):

> Composing two functions produces a third that runs them in turn: the inner function first, its result fed to the outer. Written `f(g(x))`, or `f ∘ g`, it is read "f after g." The composed function is an ordinary function, ready to compose again.

Kicker (verbatim):

> Order is not a detail. `f ∘ g` and `g ∘ f` usually differ — adding one then doubling is not doubling then adding one. Composition is, however, associative: grouping three functions either way gives the same result. And one function leaves any other unchanged under composition — the identity.

## Sections

In order:

1. **Order matters** (`#order`) — teaching section. Swapping two functions generally changes the result; `inc` then `double` versus `double` then `inc`. Carries a `deflist`: `composition` (feeding one function's output into another: `f(g(x))`), `order` (which runs first — the inner function, named last), `associative` (grouping three either way gives the same result), `identity` (the function that returns its input unchanged).
2. **Chaining three** (`#three`) — teaching section. Composition extends to any number of functions; `inc`, `double`, `square` flow a value through all three; associativity means grouping does not matter.
3. **Worked examples** (`#gallery`) — advanced gallery section. A compose combinator, the composition rule, the identity, and a three-function chain.

Running example: `inc` (`+1`), `double` (`×2`), `square` (`×self`), starting from a slider value. The real Elixir shown uses capture syntax (`inc = &(&1 + 1)`, `double = &(&1 * 2)`, `square = &(&1 * &1)`) and anonymous functions (`fn x -> square.(double.(inc.(x))) end`).

## The interactives

### Figure 1 — `f ∘ g versus g ∘ f` (`#orTitle`)
- Order toggle `#orSel` (`role="group"`): button `data-k="di"` `data-c="blue"` `double ∘ inc` (active default); button `data-k="id"` `data-c="gold"` `inc ∘ double`.
- Control `.fold-ctrl`: range `#orX` (`0`–`9`, value `3`), readout `#orXval`.
- SVG ids: `#orIn`, `#orOp1`, `#orMid`, `#orOp2`, `#orRes`, `#orAlt`.
- Pure functions per order (script `OR`): `di` main = `(x + 1) * 2`, alt = `x * 2 + 1`; `id` main = `x * 2 + 1`, alt = `(x + 1) * 2` — computes the chosen order and its swap.
- Code block `#orCode` shows `inc = &(&1 + 1)` / `double = &(&1 * 2)` / `double(inc(3))   # => 8`.
- Readout `#orOut` (verbatim default): `double(inc(3)) = 8 · inc(double(3)) = 7 · order matters` (the trailing phrase becomes `equal here` when both orders agree).

### Figure 2 — `square ∘ double ∘ inc · three stages` (`#thTitle`)
- Control `.fold-ctrl`: range `#thX` (`0`–`5`, value `2`), readout `#thXval`.
- SVG ids: `#thIn`, `#thM1`, `#thM2`, `#thM3`, `#thRes`.
- Pure function `renderTh`: `m1 = x + 1`, `m2 = m1 * 2`, `m3 = m2 * m2`.
- Code block `#thCode` shows `inc = &(&1 + 1)` / `double = &(&1 * 2)` / `square = &(&1 * &1)` / `f = fn x -> square.(double.(inc.(x))) end` / `f.(2)   # => 36`.
- Readout `#thOut` (verbatim default): `square(double(inc(2))) = square(double(3)) = square(6) = 36`.

### Figure 3 — Worked examples gallery (`#gSel`)
- Example toggle `#gSel` (`role="group"`): button `data-g="combinator"` `data-c="blue"` `compose` (active default); `data-g="rule"` `data-c="gold"` `the rule`; `data-g="identity"` `data-c="sage"` `identity`; `data-g="three"` `data-c="elixir"` `three`.
- Code block `#gCode` + readout `#gOut`. Gallery entries (`GAL`):
  - `combinator` — `compose = fn f, g -> fn x -> f.(g.(x)) end end` / `f = compose.(&(&1 * 2), &(&1 + 1))` / `f.(3)   # => 8`; note `a combinator that builds f after g`.
  - `rule` — `# (f ∘ g)(x) = f(g(x))` / `# g runs first, then f`; note `the composition rule, in one line`.
  - `identity` — `id = &Function.identity/1` / `id.(42)   # => 42` / `# composing with id leaves a function unchanged`; note `identity returns its input untouched`.
  - `three` — `square = &(&1 * &1)` / `f = fn x -> square.(double.(inc.(x))) end` / `f.(2)   # => 36`; note `three functions composed into one`.
- Readout `#gOut` (verbatim default): `compose · a combinator that builds f after g`.

Degrade behaviour: every figure renders its default values from static SVG markup, with the JS renderers (`renderOr`/`renderTh`/`renderG`) re-driving them on input. The `.arc-flow` dashed animation is `@media (prefers-reduced-motion: no-preference)` only; reveal-on-scroll (`.reveal`) is JS-gated and collapses to visible when `prefers-reduced-motion: reduce` is set or `IntersectionObserver` is missing.

Footer build-stamp: `#stamp` with `#stampId` = `TSK0Nau6DYGn32`; the decoder (`decodeBranded`, namespace `TSK`, epoch `1704067200000`) populates the panel, whose `#st-ts` default reads `2026-05-31 09:44:28 UTC`.

## References (#refs, verbatim)

This page has no `#refs` References section (no Sources / Related-in-this-course block). Cross-links are carried inline: the `.bridge` cells reference `Idea` and `F2.08.2 · pipe` (`The pipe writes this same chain in the order the stages run.`); the pager links the hub and the next dive.

## Wiring

- route-tag (verbatim): `/` `elixir` `/` `functional` `/` `composition` `/` `compose` (the `compose` segment is the current `.rcur`).
- crumbs (verbatim): `F2` `/` `F2.08` `/` `compose` (the last is `.here`), linking `/elixir/functional` and `/elixir/functional/composition`.
- toc-mini: `#order` Order matters · `#three` Chaining three · `#gallery` Worked examples.
- pager: prev → `/elixir/functional/composition` (`← F2.08 · hub`); next → `/elixir/functional/composition/pipe` (`Part 2 · the pipe →`).
- footer: column **Chapters** — `/elixir/algebra` F1 · Algebra, `/elixir/functional` F2 · Functional Programming, `/elixir/language` F3 · The Elixir Language, `/elixir/algorithms` F4 · Algorithms & Data Structures, `/elixir/pragmatic` F5 · Pragmatic Programming, `/elixir/phoenix` F6 · Phoenix Framework. Column **The course** — `/elixir` Course home, `/elixir/course` Contents & history, `/elixir/algebra/functions` Start · F1.01. Foot brand links `/elixir`.
- Page meta — `<title>`: `Function composition — F2.08.1 · jonnify`. `<meta description>`: `Composing functions by hand — f after g — why the order matters, and chaining three together.`

## Build instruction

To rebuild this dive, copy the `head…</style>`, the `header.site`, the `footer.site-foot`, and the two trailing `<script>` blocks (the figure renderers `renderOr`/`renderTh`/`renderG` + the Snowflake decoder, then the JS-on / reveal-on-scroll bootstrap) verbatim from a recent BUILT dive on the elixir (purple) accent; change only the `<title>`/`<meta description>`, the header `route-tag` (ending `.rcur` = `compose`), the crumbs, and the `<main>` body (eyebrow `part 1 of 3`, hero `.lede`/`.kicker`, the three `<section>` figures, the pager). The model sibling to copy from is its own sibling dive on this accent — `elixir/functional/composition/pipe.html` (`F2.08.2`, identical dive shell: hero, two teaching figures with `solid-select` toggles, a gallery, pager). No-invent guards: this is a mathematics-then-Elixir lesson and does not touch the live Portal product surface — do not invent Portal APIs, and defer OTP/Phoenix internals to the companion chapters (`F5 · Pragmatic`, `F6 · Phoenix`) rather than re-teaching them. Use only the real Elixir surfaces shown (`&(&1 …)` captures, `fn x -> … end`, `Function.identity/1`). Voice rules: no first person, no exclamation marks, no emoji, and none of just / simply / obviously.
