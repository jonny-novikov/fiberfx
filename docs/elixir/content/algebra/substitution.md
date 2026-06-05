# F1.02 — The substitution model (dive / lesson)

- **Route (served):** `/elixir/algebra/substitution`
- **File:** `elixir/algebra/substitution.html`
- **Place in the chapter:** the second lesson of F1 · Algebra, in the Foundations movement. It follows `F1.01` (which settled that a function returns exactly one output) and turns single-valuedness into a way of computing and reasoning — evaluation by substitution, referential transparency, and purity; it precedes `F1.03` (composition).
- **Accent:** gold chapter accent (gold/elixir token palette; the `.ex` heading word renders in elixir-bright when present).
- **Status:** built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F1 · Algebra`

`h1`: `The substitution model`

Hero lede (verbatim): "Evaluating an expression is nothing more than replacing equals with equals until a value is left. The catch is that the move is only sound when a function is pure."

Kicker (verbatim): "F1.01 settled that a function returns exactly one output, so f(a) is a single definite value. This module turns that into a way of computing — and a way of reasoning. We step through an evaluation by substitution, find the property that makes substitution valid, and name the kind of function that guarantees it."

## Sections

Three teaching sections, each closing with a `.bridge` and a `.take`:

1. **Equals for equals** (`#substitution`) — evaluation as reduction by substitution; the running example is `square(x) + double(x)` (i.e. `x² + 2x`) stepped one substitution at a time. References β-reduction from F0.1. Bridge: `x = 3` binds `x` to an immutable value.
2. **Referential transparency** (`#referential-transparency`) — an expression that always denotes the same value can be replaced by it. Running example: two definitions of `next()` evaluating `next() + next()` — a pure one (always 7) vs an impure one reading a counter via `Agent`.
3. **Purity** (`#purity`) — pure = output depends only on arguments + no side effect. A `.deflist` defines pure / side effect / transparent. Classifier over four functions.

Synthesis "What this lands" closes the arc, naming F1.03, F2, and F0.2 (the BEAM keeping effects isolated), and forwards to F1.03.

## The interactives

Three interactive figures plus the footer build-stamp decoder.

### Figure — "Substitution · evaluate one step at a time" (`#subTitle`)

- Controls: `.fold-ctrl` slider `#subX` (bind x; min 0, max 9, step 1, value 3) with `#subXval`; `.fold-ctrl` slider `#subStep` (step; min 0, max 6, step 1, value 6) with `#subStepval` (shows `6 / 6`). No `.solid-select`.
- Code block `#subCode` (the stepper trace, filled by JS), readout `#subOut`.
- Pure function: `subTrace(x)` returns the seven-line reduction of `square(x) + double(x)` (substitute → apply square → arithmetic → apply double → arithmetic → result), with `H(s)` wrapping the just-rewritten term in `.rdx`; `renderSub()` shows lines `0..step`. Initial call `renderSub()`.
- Readout `#subOut` (verbatim default): `x = 3 · square(x) + double(x) = 15 · (x² + 2x)`.

### Figure — "Substitute, or not · two definitions of next()" (`#rtTitle`)

- Control group `#rtSel` (`role="group"`, `aria-label="Choose a definition"`), two buttons: `data-rt="pure" data-c="sage"` label "pure · always 7" (starts `active`); `data-rt="impure" data-c="elixir"` label "impure · reads a counter". Plus a `.solid-select` "Evaluate" group with one button `#rtRun` (`data-c="gold"`) label "call next() twice".
- SVG (`viewBox="0 0 720 130"`): two call boxes `#rtC1` / `#rtC2`, equality badge `#rtBadge` in `#rtBadgeBox`. Code block `#rtCode`, readout `#rtOut`.
- Pure functions: `rtMode()`, `rtRender(c1,c2)` (sets the two values, the `=`/`≠` badge and box stroke, the code, and the readout), `rtEvaluate()` (pure → `rtRender(7,7)`; impure → two successive `counter++` values). The impure code shows `Agent.start_link` and `Agent.get_and_update`. Initial call `rtEvaluate()`.
- Readout `#rtOut` (verbatim default): `call 1 → 7 · call 2 → 7 · next() + next() = 14 = 2 × next() · referentially transparent`. (Impure form: `… ≠ 2 × next() · not referentially transparent`.)

### Figure — "Is it pure? · check both conditions" (`#purTitle`)

- Control group `#purSel` (`role="group"`, `aria-label="Choose a function"`), four buttons: `data-fn="square" data-c="sage"` label "x * x" (starts `active`); `data-fn="rand" data-c="elixir"` label "x + rand"; `data-fn="io" data-c="gold"` label "IO.puts"; `data-fn="time" data-c="blue"` label "clock". A `.deflist` defines pure / side effect / transparent.
- SVG (`viewBox="0 0 720 150"`): two condition lamps `#lamp1` ("output depends only on the arguments") / `#lamp2` ("no side effect"), verdict stamp `#stampText` in `#stampBox`. Code block `#purCode`, readout `#purOut`.
- Pure function: `purRender()` reads `SPECS` (`square` pure; `rand` `:rand.uniform(6)` — fails inputs; `io` `IO.puts` — has effects; `time` `System.monotonic_time()` — fails inputs), lights the lamps green/red, stamps PURE/IMPURE, sets the code, and writes the verdict (with the spec's `why` when impure). Initial call `purRender()`.
- Readout `#purOut` (verbatim default): `depends only on arguments: yes · no side effect: yes · pure — replace any call with its result`.

### Degrade behaviour

Controls, SVGs, and the default readouts render in static markup; `#subCode`, `#rtCode`, `#purCode` are filled by JS on init (`renderSub`/`rtEvaluate`/`purRender`). The page respects `prefers-reduced-motion` globally; no browser storage (the `counter` and `rtEvaluate` state is in-memory only).

### Footer build-stamp decoder (`#stamp`)

- Stamp id: `TSK0NZIckDkA2y` (in `#stampId`); panel `#st-ts` hard-codes "2026-05-30 10:32:27 UTC" (the decoded UTC timestamp).
- Pure functions: `b62decode(s)`, `pad2(x)`, `decodeBranded(id)` (`ns = id.slice(0,3)`, `snow = b62decode(id.slice(3))`; `ts = snow >> 22n`, `node = (snow >> 12n) & 0x3FFn`, `seq = snow & 0xFFFn`; `EPOCH_MS = 1704067200000`). Toggle on click / Enter / Space.

## References (#refs, verbatim)

No `#refs` References section is present on this page. The lesson's cross-links are the crumbs, toc-mini, `.note`, pager, and footer (see Wiring); the synthesis `.note` forwards to F1.03 and the prose cites F0.1 (β-reduction), F0.2 (the BEAM), F1.01, and F2.

## Wiring

- **route-tag:** `<span class="rsep">/</span><a href="/elixir">elixir</a><span class="rsep">/</span><a href="/elixir/algebra">algebra</a><span class="rsep">/</span><span class="rcur">substitution</span>`.
- **crumbs:** `F1 · Algebra` → `/elixir/algebra` · sep `/` · `F1.01` → `/elixir/algebra/functions` · sep `/` · here `F1.02` (no link).
- **toc-mini:** `#substitution` ("Equals for equals") · `#referential-transparency` ("Referential transparency") · `#purity` ("Purity").
- **pager:** prev → `/elixir/algebra/functions` ("← F1.01 · functions"); next → `/elixir/algebra/composition` ("Next · F1.03 composition →").
- **footer:** identical three-column footer — brand → `/elixir`; `Chapters` F1–F6; `The course` `/elixir`, `/elixir/course`, `/elixir/algebra/functions`.
- **Page meta:** `<title>` "The substitution model — F1.02 · jonnify"; `<meta description>` "Equals for equals: evaluation by substitution, referential transparency, and the purity that makes a function safe to replace with its result."

## Build instruction

To (re)build this lesson, copy the `<head>…</style>`, `<header class="site">`, `<footer class="site-foot">`, and the two trailing `<script>` blocks verbatim from a recent built gold-accent sibling — the model is `elixir/algebra/functions.html` (F1.01, the same lesson template: crumbs, toc-mini, three figures, `.bridge`/`.take` rhythm, and the substitution-stepper / purity-classifier patterns) — then change only `<title>`/`<meta>`, the route-tag, the crumbs, and the `<main>` body. No-invent guards: use only the real Portal surfaces as written (branded store, event-sourced engine behind one `Portal` facade, Phoenix web app); this lesson is pure algebra and names no engine internals — cite the companion course for OTP internals (the `Agent` example here is illustrative, not a Portal surface), do not re-teach. Voice rules: no first person, no exclamation marks, no emoji, none of just/simply/obviously.
