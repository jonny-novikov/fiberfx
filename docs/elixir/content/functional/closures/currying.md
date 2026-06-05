# F2.06.3 — Partial application & currying (dive)

- Route (served): `/elixir/functional/closures/currying`
- File: `elixir/functional/closures/currying.html`
- Place in the chapter: the third and last deep dive under the F2.06 closures hub (`part 3 of 3`). It takes capture toward arguments: partial application fixes some arguments to specialise a function, and currying — built by hand — turns an n-argument function into a chain of one-argument functions. It closes F2.06 and hands off to F2.07 algebraic data types.
- Accent: elixir (purple), `--elixir #b39ddb` / `--elixir-bright #cdb8f0`.
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `F2.06 · part 3 of 3`

Hero `h1`: Partial application & currying

Hero lede (verbatim):

> Partial application fixes some of a function’s arguments and returns a function awaiting the rest. Currying takes it to the limit: a function of many arguments becomes a chain of one-argument functions, each capturing its argument and returning the next.

Kicker (verbatim):

> Elixir does not curry automatically — a two-argument function wants both at once. But closures let you build either pattern by hand. Fix one argument and you have specialised the function; nest a function per argument and you have curried it. Both are capture, applied to arguments instead of free variables.

## Sections

Three teaching sections, in order, with an `Idea/F2.06.1 → Elixir` `.bridge` and a `.take`; closes with a `Where this goes` synthesis (`#close`).

- `#partial` — Specialise by fixing. From a general `multiply`, fixing the first argument produces a named specialist (`double` at 2, `triple` at 3). Carries a `.deflist` of four terms (`partial application`, `currying`, `arity reduction`, `point-free`).
- `#curry` — Currying by hand. `fn a -> fn b -> fn c -> a + b + c end end end` takes one argument at a time; each application captures its argument and returns the next function.
- `#gallery` — Worked examples. Currying, partial application with the capture operator, and the point-free style they enable.

Real Elixir code shown (verbatim from the JS templates):
- `multiply = fn a, b -> a * b end` / `double = fn b -> multiply.(2, b) end` / `double.(4)   # => 8` (name/factor vary per selection: `double`/2, `triple`/3, `times10`/10).
- `curried = fn a -> fn b -> fn c -> a + b + c end end end` / `curried.(1).(2).(3)   # => 6`
- `curry = fn a -> fn b -> a + b end end` / `curry.(3).(4)   # => 7`
- `add = fn a, b -> a + b end` / `add5 = &add.(5, &1)` / `add5.(3)   # => 8`
- `[1, 2, 3] |> Enum.map(&(&1 * 2)) |> Enum.sum()   # => 12`

## The interactives

### `#partial` figure — `fix the factor · from a general multiply`
- `<figure class="fig">`, labelled by `id="parTitle"`.
- Control group `id="pfSel"` (`.solid-select`), buttons: `data-k="double"` `data-c="gold"` (`double (2)`, active default); `data-k="triple"` `data-c="sage"` (`triple (3)`); `data-k="ten"` `data-c="blue"` (`times10 (10)`). Plus a `.fold-ctrl` slider `pfX` (`input`, 0–9, value 4, readout `pfXval`).
- SVG ids: `pfMid`, `pfRes`, `pfEq`. Code `pre#pfCode`; readout `geo-readout#pfOut`.
- Pure function `renderPf()` (keyed by the `PF` dict — `double` k=2, `triple` k=3, `ten` k=10/name `times10`) computes `r = k * x` and rewrites `fn b -> k * b end` and `name.(x)  =  k * x  =  r`.
- Default readout (verbatim): `double · factor fixed at 2 · input 4 → 8`.

### `#curry` figure — `curried.(1).(2).(3) · one argument at a time`
- `<figure class="fig">`, labelled by `id="curTitle"`.
- Control: `.fold-ctrl` slider `curStep` (`applied`, 0–3, value 0, readout `curStepval` showing `0 of 3`).
- SVG ids: `curSlots` (`<g>` of three slots built by `slot()`), `curCall`, `curRetBox`, `curRet`. Code `pre#curCode`; readout `geo-readout#curOut`. Fixed args `ARGS = [1, 2, 3]`, names `['a', 'b', 'c']`.
- Pure function `renderCur()` rebuilds the captured slots and the returns box per step. Returns strings: step 0 `a function awaiting a`; step 1 `fn b -> fn c -> 1 + b + c end end`; step 2 `fn c -> 1 + 2 + c end`; step 3 `6`.
- Readouts (verbatim): step 0 `nothing applied yet · curried awaits its first argument, a`; step 3 `all three applied · 1 + 2 + 3 = 6`; intermediate steps `<captures> captured · awaiting <next name>`. Default (step 0): `nothing applied yet · curried awaits its first argument, a`.

### `#gallery` selector — `gSel`
- Control group `id="gSel"` (`.solid-select`), buttons: `data-g="curry"` `data-c="elixir"` (`curry`, active default); `data-g="partial"` `data-c="gold"` (`partial with &`); `data-g="point"` `data-c="blue"` (`point-free`).
- Code `pre#gCode`; readout `geo-readout#gOut`. Pure function `renderG()` keyed by the `GAL` dict; per-key notes: `a two-step chain, one argument each`; `the capture operator fixes the first argument`; `each stage names no argument; the pipe threads the value`.
- Default readout (verbatim): `curry · a two-step chain, one argument each`.

Degrade behaviour: the SVGs and readouts ship static default states in markup (the `double` partial, the step-0 currying frame, the `curry` gallery), so the page reads with JS off; the currying slots are built by JS at default step 0. Reveal-on-scroll is JS-gated (`html.js .reveal`) and disabled under `prefers-reduced-motion: reduce`; the `arc-flow` dash animation is gated to `prefers-reduced-motion: no-preference`.

Footer build-stamp decoder: `<span id="stampId">TSK0NarZ3bGoV6</span>`, namespace `TSK`, base-62 Snowflake over epoch `1704067200000`; decoded timestamp shown in the panel as `2026-05-31 09:09:00 UTC`.

## References (#refs, verbatim)

This page has no `#refs` References block. There is no References section in the markup — no `Sources` list and no `Related in this course` list to transcribe.

## Wiring

- route-tag (verbatim): `/ elixir / functional / closures / currying` — `<a href="/elixir">elixir</a>` · `<a href="/elixir/functional">functional</a>` · `<a href="/elixir/functional/closures">closures</a>` · `<span class="rcur">currying</span>`.
- crumbs (verbatim): `F2` (`/elixir/functional`) / `F2.06` (`/elixir/functional/closures`) / `currying` (here).
- toc-mini: `#partial` Specialise by fixing · `#curry` Currying by hand · `#gallery` Worked examples.
- pager: prev → `/elixir/functional/closures/capture` (`Part 2 · capture operator`); next → `/elixir/functional/adt` (`F2.07 · Algebraic data types`).
- footer: column `Chapters` — `/elixir/algebra` (F1 · Algebra), `/elixir/functional` (F2 · Functional Programming), `/elixir/language` (F3 · The Elixir Language), `/elixir/algorithms` (F4 · Algorithms & Data Structures), `/elixir/pragmatic` (F5 · Pragmatic Programming), `/elixir/phoenix` (F6 · Phoenix Framework). Column `The course` — `/elixir` (Course home), `/elixir/course` (Contents & history), `/elixir/algebra/functions` (Start · F1.01). Brand tagline: `Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir.`
- Page meta: `<title>` = `Partial application & currying — F2.06.3 · jonnify`; `<meta name="description">` = `Fixing arguments to specialise a function, and building curried functions by hand — applying arguments one at a time.`

## Build instruction

To rebuild this dive, copy the `<head>…</style>`, the `<header class="site">`, the `<footer class="site-foot">`, and the two trailing `<script>` blocks (the page IIFE plus the Snowflake decoder and the reveal-on-scroll enhancer) verbatim from a built sibling on the elixir purple accent — the model sibling is its companion dive `elixir/functional/closures/capture.html` (same accent, same dive hero layout, same `.solid-select` selector shell; note this page additionally uses `var SVGNS` to build the currying slots, so keep the IIFE intact). Change only `<title>`/`<meta description>`, the `route-tag`, the crumbs, the `<main>` body, and the figure ids/data. No-invent guards: this dive teaches partial application and hand-rolled currying in plain Elixir — keep `Enum.map`/`Enum.sum` and the `&add.(5, &1)` capture form at their real shapes and do not introduce Portal surfaces here; where the migrated course references its runtime, use only the real surfaces as written (the branded store, the event-sourced engine behind the one `Portal` facade, the Phoenix web app), and cite the companion course for OTP internals rather than re-teaching them. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously.
