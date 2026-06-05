# F2.06.1 — Capturing the environment (dive)

- Route (served): `/elixir/functional/closures/environment`
- File: `elixir/functional/closures/environment.html`
- Place in the chapter: the first of three deep dives under the F2.06 closures hub (`part 1 of 3`). It pins down what a closure captures and when — capture by value at definition time, immutability keeping the snapshot stable, lexical scope, and capturing several variables at once. It precedes the capture-operator dive (`capture`).
- Accent: elixir (purple), `--elixir #b39ddb` / `--elixir-bright #cdb8f0`.
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `F2.06 · part 1 of 3`

Hero `h1`: Capturing the environment

Hero lede (verbatim):

> A closure captures the *value* of each variable as it stood when the function was defined — not a live link to the variable. Because Elixir bindings are immutable, that captured value never shifts underneath the function. The environment it carries is a fixed snapshot.

Kicker (verbatim):

> In languages with mutable variables, a closure capturing a loop variable is a classic trap: every closure ends up seeing the final value. Elixir sidesteps this. Rebinding a name creates a new binding; the closure still holds the value it captured. So a closure’s behaviour is settled the moment it is created.

## Sections

Three teaching sections, in order, each an interactive `.fig` with an `Idea/F1.04/F2.06.3 → Elixir` `.bridge` and a `.take`.

- `#definition` — Captured at definition. A closure copies the values it needs; rebinding afterwards leaves it unaffected. Carries a `.deflist` of four terms (`capture by value`, `lexical scope`, `immutability`, `snapshot`). Running example: `x = 1; f = fn -> x end; x = 2; f.() => 1`.
- `#multiple` — Several variables at once. `make_line` captures a slope and an intercept, returning a function of `x`. Running example: `make_line.(slope, intercept)` → `line.(x)` = `slope * x + intercept`.
- `#gallery` — Worked examples. A `.solid-select` of four function factories, each capturing a value and returning a specialised function.

Real Elixir code shown (verbatim from the JS templates):
- `make_adder = fn n -> fn x -> x + n end end` / `add3 = make_adder.(3)` / `add3.(10)   # => 13`
- `make_multiplier = fn k -> fn x -> x * k end end` / `double = make_multiplier.(2)` / `double.(21)   # => 42`
- `greeter = fn name -> fn msg -> "#{msg}, #{name}!" end end` / `hi = greeter.("Ada")` / `hi.("Hello")   # => "Hello, Ada!"`
- `at_most = fn cap -> fn x -> min(x, cap) end end` / `clamp = at_most.(100)` / `clamp.(240)   # => 100`
- `make_line = fn slope, intercept -> fn x -> slope * x + intercept end end` / `line = make_line.(s, i)` / `line.(x)`

## The interactives

### `#definition` figure — `rebinding x does not change the closure`
- `<figure class="fig">`, labelled by `id="defTitle"`.
- Controls (`.fold-ctrl`): `dfA` (`x at capture`, 0–9, value 1, readout `dfAval`); `dfB` (`x after rebind`, 0–9, value 2, readout `dfBval`).
- SVG ids: `df1`, `df2`, `df3`, `df4` (the four numbered lines). Code `pre#dfCode`; readout `geo-readout#dfOut`.
- Pure function `renderDf()` rewrites the four lines and the code `x = a / f = fn -> x end / x = b / f.()   # => a`.
- Default readout (verbatim): `captured x = 1 · rebound to 2 · f.() = 1, not 2`. (When `a === b` the readout shows ` (same here)` instead of `, not b`.)

### `#multiple` figure — `make_line captures slope and intercept`
- `<figure class="fig">`, labelled by `id="mulTitle"`.
- Controls: `mlS` (`slope`, 0–5, value 2, readout `mlSval`); `mlI` (`intercept`, 0–9, value 3, readout `mlIval`); `mlX` (`x`, 0–9, value 4, readout `mlXval`).
- SVG ids: `mlClosure`, `mlRes`, `mlEq`. Code `pre#mlCode`; readout `geo-readout#mlOut`.
- Pure function `renderMl()` computes `r = s * x + i` and rewrites `fn x -> s * x + i end` and the `make_line` block.
- Default readout (verbatim): `captures slope = 2, intercept = 3 · x = 4 · result 11`.

### `#gallery` selector — `gSel`
- Control group `id="gSel"` (`.solid-select`), buttons: `data-g="adder"` `data-c="elixir"` (`make_adder`, active default); `data-g="mult"` `data-c="gold"` (`make_multiplier`); `data-g="greet"` `data-c="blue"` (`greeter`); `data-g="limit"` `data-c="sage"` (`at_most`).
- Code `pre#gCode`; readout `geo-readout#gOut`. Pure function `renderG()` keyed by the `GAL` dict; per-key notes: `captures n, returns a function that adds n`; `captures the factor k`; `captures a string and builds a greeting`; `captures a ceiling and clamps to it`.
- Default readout (verbatim): `make_adder · captures n, returns a function that adds n`.

Degrade behaviour: each SVG and readout ships a static default in markup (the default slider values and the `make_adder` gallery state), so the page reads with JS off. Reveal-on-scroll is JS-gated (`html.js .reveal`) and disabled under `prefers-reduced-motion: reduce`; the `arc-flow` dash animation is gated to `prefers-reduced-motion: no-preference`.

Footer build-stamp decoder: `<span id="stampId">TSK0NarZ37SvqK</span>`, namespace `TSK`, base-62 Snowflake over epoch `1704067200000`; decoded timestamp shown in the panel as `2026-05-31 09:09:00 UTC`.

## References (#refs, verbatim)

This page has no `#refs` References block. There is no References section in the markup — no `Sources` list and no `Related in this course` list to transcribe.

## Wiring

- route-tag (verbatim): `/ elixir / functional / closures / environment` — `<a href="/elixir">elixir</a>` · `<a href="/elixir/functional">functional</a>` · `<a href="/elixir/functional/closures">closures</a>` · `<span class="rcur">environment</span>`.
- crumbs (verbatim): `F2` (`/elixir/functional`) / `F2.06` (`/elixir/functional/closures`) / `environment` (here).
- toc-mini: `#definition` Captured at definition · `#multiple` Several variables at once · `#gallery` Worked examples.
- pager: prev → `/elixir/functional/closures` (`F2.06 · hub`); next → `/elixir/functional/closures/capture` (`Part 2 · capture operator`).
- footer: column `Chapters` — `/elixir/algebra` (F1 · Algebra), `/elixir/functional` (F2 · Functional Programming), `/elixir/language` (F3 · The Elixir Language), `/elixir/algorithms` (F4 · Algorithms & Data Structures), `/elixir/pragmatic` (F5 · Pragmatic Programming), `/elixir/phoenix` (F6 · Phoenix Framework). Column `The course` — `/elixir` (Course home), `/elixir/course` (Contents & history), `/elixir/algebra/functions` (Start · F1.01). Brand tagline: `Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir.`
- Page meta: `<title>` = `Capturing the environment — F2.06.1 · jonnify`; `<meta name="description">` = `What a closure captures and when: the value at definition time, immutability, lexical scope, and capturing several variables at once.`

## Build instruction

To rebuild this dive, copy the `<head>…</style>`, the `<header class="site">`, the `<footer class="site-foot">`, and the two trailing `<script>` blocks (the page IIFE plus the Snowflake decoder and the reveal-on-scroll enhancer) verbatim from a built sibling on the elixir purple accent — the model sibling is its companion dive `elixir/functional/closures/capture.html` (same accent, same dive hero layout, same `.solid-select` gallery shell). Change only `<title>`/`<meta description>`, the `route-tag`, the crumbs, the `<main>` body, and the figure ids/data. No-invent guards: this dive teaches closure capture semantics in plain Elixir — do not introduce Portal surfaces here; where the migrated course references its runtime, use only the real surfaces as written (the branded store, the event-sourced engine behind the one `Portal` facade, the Phoenix web app), and cite the companion course for OTP internals rather than re-teaching them. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously.
