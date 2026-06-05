# F2.06.2 — The capture operator (dive)

- Route (served): `/elixir/functional/closures/capture`
- File: `elixir/functional/closures/capture.html`
- Place in the chapter: the second of three deep dives under the F2.06 closures hub (`part 2 of 3`). It teaches the `&` capture operator in full — positional placeholders `&1`/`&2` that build a function from an expression, and `&Module.fun/arity` that captures a named function as a value. It follows the environment dive and precedes the currying dive.
- Accent: elixir (purple), `--elixir #b39ddb` / `--elixir-bright #cdb8f0`.
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `F2.06 · part 2 of 3`

Hero `h1`: The capture operator

Hero lede (verbatim):

> The capture operator `&` writes a small anonymous function in one compact form. Inside `&(…)`, the placeholders `&1`, `&2`, and so on stand for the arguments. It also captures a named function directly, as `&Module.function/arity`.

Kicker (verbatim):

> There are two distinct uses sharing the symbol. The first wraps an expression: `&(&1 + 1)` is the same function as `fn x -> x + 1 end`. The second names an existing function: `&String.upcase/1` is the function `String.upcase` itself, ready to pass along. Both produce ordinary functions.

## Sections

Three teaching sections, in order, each with an `Idea/F1.07 → Elixir` `.bridge` and a `.take`.

- `#placeholders` — Positional placeholders. Wrap an expression in `&(…)`; `&1` is the first argument, `&2` the second; the highest placeholder sets the arity; the result equals the matching `fn`. Carries a `.deflist` of four terms (`capture operator`, `placeholder`, `function capture`, `arity`).
- `#funcs` — Capturing named functions. `&String.upcase/1` is the function itself, ready to hand to `Enum.map`; the arity says which function of that name.
- `#gallery` — In the wild. Where `&` is met most: as the function argument to `Enum`.

Real Elixir code shown (verbatim from the JS templates):
- `Enum.map([1, 2, 3], &(&1 + 1))   # => [2, 3, 4]`
- `Enum.reduce([1, 2, 3, 4], &(&1 + &2))   # => 10`
- `Enum.map([1, 2, 3], &(&1 * 2))   # => [2, 4, 6]`
- `Enum.zip_with([1, 2], [:a, :b], &{&1, &2})` / `# => [{1, :a}, {2, :b}]`
- `String.upcase("ab")   # "AB"` / `Enum.map(["a", "b"], &String.upcase/1)   # => ["A", "B"]`
- `Enum.map(["a", "to", "cat"], &String.length/1)` / `# => [1, 2, 3]`
- `Enum.map([1, 2, 3], &Integer.to_string/1)` / `# => ["1", "2", "3"]`
- `Enum.map([-1, 2, -3], &abs/1)   # => [1, 2, 3]`
- `Enum.map([1, 2, 3], &(&1 * &1))` / `# => [1, 4, 9]`
- `Enum.filter([1, -2, 3], &(&1 > 0))` / `# => [1, 3]`
- `Enum.sort_by(["bb", "a", "ccc"], &String.length/1)` / `# => ["a", "bb", "ccc"]`

## The interactives

### `#placeholders` figure — `& form and fn form · same function`
- `<figure class="fig">`, labelled by `id="phTitle"`.
- Control group `id="phSel"` (`.solid-select`), buttons: `data-k="inc"` `data-c="elixir"` (`&(&1 + 1)`, active default); `data-k="add"` `data-c="gold"` (`&(&1 + &2)`); `data-k="dbl"` `data-c="blue"` (`&(&1 * 2)`); `data-k="pair"` `data-c="sage"` (`&{&1, &2}`).
- SVG ids: `phShort`, `phLong`, `phArity`. Code `pre#phCode`; readout `geo-readout#phOut`.
- Pure function `renderPh()` keyed by the `PH` dict (each carries `short`, `long`, `arity`, `note`, `code`). Notes: `&1 is the first argument` (arity 1); `&1 and &2 are the two arguments` (arity 2); `a literal 2 mixes with the placeholder` (arity 1); `build a tuple from both arguments` (arity 2).
- Default readout (verbatim): `&(&1 + 1) · arity 1 · &1 is the first argument`.

### `#funcs` figure — `&Module.fun/arity · a named function as a value`
- `<figure class="fig">`, labelled by `id="fnTitle"`.
- Control group `id="fnSel"` (`.solid-select`), buttons: `data-k="upcase"` `data-c="gold"` (`&String.upcase/1`, active default); `data-k="length"` `data-c="blue"` (`&String.length/1`); `data-k="to_str"` `data-c="sage"` (`&Integer.to_string/1`); `data-k="abs"` `data-c="elixir"` (`&abs/1`).
- SVG ids: `fnCap`, `fnLong`, `fnEx`. Code `pre#fnCode`; readout `geo-readout#fnOut`.
- Pure function `renderFn()` keyed by the `FN` dict (each carries `cap`, `long`, `ex`, `short`, `code`). Example strings: `apply to "ab"  =>  "AB"`; `apply to "cat"  =>  3`; `apply to 42  =>  "42"`; `apply to -5  =>  5`.
- Default readout (verbatim): `&String.upcase/1 · the function itself, ready to pass · "ab" → "AB"`.

### `#gallery` selector — `gSel`
- Control group `id="gSel"` (`.solid-select`), buttons: `data-g="map"` `data-c="gold"` (`map`, active default); `data-g="filter"` `data-c="sage"` (`filter`); `data-g="sort"` `data-c="blue"` (`sort_by`).
- Code `pre#gCode`; readout `geo-readout#gOut`. Pure function `renderG()` keyed by the `GAL` dict; per-key notes: `a placeholder expression squares each element`; `a placeholder predicate keeps the positives`; `a captured function gives the sort key`.
- Default readout (verbatim): `map · a placeholder expression squares each element`.

Degrade behaviour: each SVG and readout ships a static default in markup (the `&(&1 + 1)` / `&String.upcase/1` / `map` default states), so the page reads with JS off. Reveal-on-scroll is JS-gated (`html.js .reveal`) and disabled under `prefers-reduced-motion: reduce`; the `arc-flow` dash animation is gated to `prefers-reduced-motion: no-preference`.

Footer build-stamp decoder: `<span id="stampId">TSK0NarZ3ME4bg</span>`, namespace `TSK`, base-62 Snowflake over epoch `1704067200000`; decoded timestamp shown in the panel as `2026-05-31 09:09:00 UTC`.

## References (#refs, verbatim)

This page has no `#refs` References block. There is no References section in the markup — no `Sources` list and no `Related in this course` list to transcribe.

## Wiring

- route-tag (verbatim): `/ elixir / functional / closures / capture` — `<a href="/elixir">elixir</a>` · `<a href="/elixir/functional">functional</a>` · `<a href="/elixir/functional/closures">closures</a>` · `<span class="rcur">capture</span>`.
- crumbs (verbatim): `F2` (`/elixir/functional`) / `F2.06` (`/elixir/functional/closures`) / `capture` (here).
- toc-mini: `#placeholders` Positional placeholders · `#funcs` Capturing named functions · `#gallery` In the wild.
- pager: prev → `/elixir/functional/closures/environment` (`Part 1 · environment`); next → `/elixir/functional/closures/currying` (`Part 3 · currying`).
- footer: column `Chapters` — `/elixir/algebra` (F1 · Algebra), `/elixir/functional` (F2 · Functional Programming), `/elixir/language` (F3 · The Elixir Language), `/elixir/algorithms` (F4 · Algorithms & Data Structures), `/elixir/pragmatic` (F5 · Pragmatic Programming), `/elixir/phoenix` (F6 · Phoenix Framework). Column `The course` — `/elixir` (Course home), `/elixir/course` (Contents & history), `/elixir/algebra/functions` (Start · F1.01). Brand tagline: `Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir.`
- Page meta: `<title>` = `The capture operator — F2.06.2 · jonnify`; `<meta name="description">` = `The & shorthand for anonymous functions: positional placeholders &1 and &2, and capturing named functions with &Module.fun/arity.`

## Build instruction

To rebuild this dive, copy the `<head>…</style>`, the `<header class="site">`, the `<footer class="site-foot">`, and the two trailing `<script>` blocks (the page IIFE plus the Snowflake decoder and the reveal-on-scroll enhancer) verbatim from a built sibling on the elixir purple accent — the model sibling is its companion dive `elixir/functional/closures/environment.html` (same accent, same dive hero layout, same `.solid-select` selector shell). Change only `<title>`/`<meta description>`, the `route-tag`, the crumbs, the `<main>` body, and the figure ids/data. No-invent guards: this dive teaches the `&` operator and `Enum` usage in plain Elixir — keep `Enum.map`/`Enum.reduce`/`Enum.filter`/`Enum.sort_by`/`Enum.zip_with` at their real arities and do not introduce Portal surfaces here; where the migrated course references its runtime, use only the real surfaces as written (the branded store, the event-sourced engine behind the one `Portal` facade, the Phoenix web app), and cite the companion course for OTP internals rather than re-teaching them. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously.
