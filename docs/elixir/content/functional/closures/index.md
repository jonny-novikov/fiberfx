# F2.06 — Closures & partial application (module hub)

- Route (served): `/elixir/functional/closures`
- File: `elixir/functional/closures/index.html`
- Place in the chapter: the sixth module of F2 · Functional Programming. It frames closures as one mechanism — a function remembering its environment — and continues across three deep-dive subpages (`environment`, `capture`, `currying`). It follows F2.05 folds (whose combiners are usually closures over a factor or threshold) and hands off to F2.07 algebraic data types.
- Accent: elixir (purple), `--elixir #b39ddb` / `--elixir-bright #cdb8f0`.
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `F2 · Functional Programming`

Hero `h1`: Closures & partial application

Hero lede (verbatim):

> A closure is a function bundled with the environment it was defined in. It can read the variables that were in scope when it was created — carrying them along after that scope is gone. That is what lets one function build another, tailored to a value decided earlier.

Kicker (verbatim):

> The folds in F2.05 took small functions as their combiners. Those functions usually need a value from their surroundings — a factor to multiply by, a threshold to compare against. A closure captures that value. Partial application is the same idea pointed at arguments: fix some of a function’s inputs now and supply the rest later. Both are built from one mechanism — a function remembering its environment.

## What the page frames

The hub carries three in-page teaching sections, then a `#dives` directory of three deep-dive subpages.

In-page teaching sections (each a `.fig` interactive with an `Idea → Elixir/folds` `.bridge` and a `.take`):
- `#capture` — A function that remembers. `make_adder` captures `n`; the returned function adds `n`. Carries a `.deflist` of four terms (`closure`, `capture`, `partial application`, `&`).
- `#partial` — Partial application. From a two-argument `add`, fixing the first gives a one-argument function; the fixed value is captured.
- `#amp` — The `&` shorthand. The capture operator `&` as a compact `fn`; `&1` / `&2` stand for the first and second arguments.

The `#dives` directory (`.dives`-style cards; each links a built subpage):
- F2.06.1 · Capturing the environment — what a closure captures and when — the value at definition time, and why immutability makes it stable. Route `/elixir/functional/closures/environment`. Built.
- F2.06.2 · The capture operator — the `&` shorthand in full: positional placeholders, and capturing named functions with `&Mod.fun/arity`. Route `/elixir/functional/closures/capture`. Built.
- F2.06.3 · Partial application & currying — fixing arguments to specialise a function, and currying by hand — one argument at a time. Route `/elixir/functional/closures/currying`. Built.

A closing `What this lands` synthesis section restates the single mechanism and forward-links F2.07.

## The interactives

### Hero figure — `A closure carries its captured environment`
- `<figure class="hero-fig">`, labelled by `id="hcTitle"` (`A closure carries its captured environment`).
- SVG element ids: `hcBody`, `hcEnvBox`, `hcEnv`, `hcCall`, `hcResBox`, `hcRes`; caption `hcCap` (`aria-live="polite"`).
- Controls: `<button id="hcStep">` (`▸ apply · multiplier.(5)`) and `<button id="hcReset">` (`reset`).
- A stepper (`stage` 0→1→2) over fixed constants `N = 3`, `X = 5`. Stage 0 readout (static markup, visible without JS): `make_multiplier(3)` returned a closure that captured `n = 3`. / It is awaiting an argument `x`. Stage 1: `Applying reads the captured n = 3: multiplier.(5) computes 5 × 3 = 15.` Stage 2: `Partial application is the same idea: a 2-argument multiply(n, x) with n = 3 fixed becomes the 1-argument closure multiplier.(x).` Button labels step `▸ apply · multiplier.(5)` → `▸ same as partial application` → `▸ applied` (disabled).

### `#capture` figure — `make_adder · the returned function captures n`
- `<figure class="fig">`, labelled by `id="capTitle"`.
- Controls (`.fold-ctrl`): `capN` (`n (captured)`, 0–10, value 10, readout `capNval`); `capX` (`x (later)`, 0–10, value 5, readout `capXval`).
- SVG ids: `capBuild`, `capClosure`, `capResult`, `capEq`. Code `pre#capCode`; readout `geo-readout#capOut`.
- Pure function `renderCap()` computes `r = x + n` and rewrites: `make_adder.(n)`, `fn x -> x + n end`, `x + n  =  x + n  =  r`.
- Default readout (verbatim): `captures n = 10 · apply x = 5 · 5 + 10 = 15`.

### `#partial` figure — `fix a, wait for b · from a two-argument add`
- `<figure class="fig">`, labelled by `id="parTitle"`.
- Controls: `parA` (`a (fixed)`, 0–9, value 5, readout `parAval`); `parB` (`b (later)`, 0–9, value 3, readout `parBval`).
- SVG ids: `parMid`, `parRes`, `parEq`. Code `pre#parCode`; readout `geo-readout#parOut`.
- Pure function `renderPar()` computes `r = a + b` and rewrites `fn b -> a + b end`, `add_a = fn b -> add.(a, b) end`.
- Default readout (verbatim): `fix a = 5 · apply b = 3 · 5 + 3 = 8`.

### `#amp` figure — `& form and fn form · the same function`
- `<figure class="fig">`, labelled by `id="ampTitle"`.
- Control group `id="ampSel"` (`.solid-select`), buttons: `data-k="inc"` `data-c="elixir"` (`add one`, active default); `data-k="mul"` `data-c="gold"` (`multiply`); `data-k="up"` `data-c="blue"` (`upcase`).
- SVG ids: `ampShort`, `ampLong`. Code `pre#ampCode`; readout `geo-readout#ampOut`.
- Pure function `renderAmp()` keyed by the `AMP` dict — `inc`: `&(&1 + 1)` ≡ `fn x -> x + 1 end`, note `one argument: &1 is x`; `mul`: `&(&1 * &2)` ≡ `fn x, y -> x * y end`, note `two arguments: &1 and &2`; `up`: `&String.upcase/1` ≡ `fn s -> String.upcase(s) end`, note `capture a named function by name and arity`.
- Default readout (verbatim): `add one · the & form and the fn form are the same function`.

Degrade behaviour: each SVG ships a static default state in markup (the hero stage-0 frame, the default slider/select values), so the page reads with JS off. The reveal-on-scroll is JS-gated (`html.js .reveal`) and disabled under `prefers-reduced-motion: reduce`; the hero arrive animation (`.hc-arrive`) and the `arc-flow` dash animation are gated to `prefers-reduced-motion: no-preference`. The hero does not render on load (the static SVG already shows the awaiting-x frame).

Footer build-stamp decoder: `<span id="stampId">TSK0NarZY0cWRc</span>`, namespace `TSK`, base-62 Snowflake over epoch `1704067200000`; decoded timestamp shown in the panel as `2026-05-31 09:09:06 UTC`.

## References (#refs, verbatim)

This page has no `#refs` References block. There is no References section in the markup — no `Sources` list and no `Related in this course` list to transcribe.

## Wiring

- route-tag (verbatim): `/ elixir / functional / closures` — `<a href="/elixir">elixir</a>` · `<a href="/elixir/functional">functional</a>` · `<span class="rcur">closures</span>`.
- crumbs (verbatim): `F2 · Functional` (`/elixir/functional`) / `F2.05` (`/elixir/functional/folds`) / `F2.06` (here).
- toc-mini: `#capture` A function that remembers · `#partial` Partial application · `#amp` The & shorthand · `#dives` Three deep dives.
- pager: prev → `/elixir/functional/folds/advanced` (`F2.05 · advanced folds`); next → `/elixir/functional/closures/environment` (`Start · environment`).
- footer: column `Chapters` — `/elixir/algebra` (F1 · Algebra), `/elixir/functional` (F2 · Functional Programming), `/elixir/language` (F3 · The Elixir Language), `/elixir/algorithms` (F4 · Algorithms & Data Structures), `/elixir/pragmatic` (F5 · Pragmatic Programming), `/elixir/phoenix` (F6 · Phoenix Framework). Column `The course` — `/elixir` (Course home), `/elixir/course` (Contents & history), `/elixir/algebra/functions` (Start · F1.01). Brand tagline: `Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir.`
- Page meta: `<title>` = `Closures & partial application — F2.06 · jonnify`; `<meta name="description">` = `A closure is a function plus the environment it captured. Building specialised functions by capturing a value, partial application, and the & capture operator.`

## Build instruction

To rebuild this hub, copy the `<head>…</style>`, the `<header class="site">`, the `<footer class="site-foot">`, and the two trailing `<script>` blocks (the page IIFE plus the Snowflake decoder and the reveal-on-scroll enhancer) verbatim from a recent built sibling on the elixir purple accent — the model sibling is `elixir/functional/folds/index.html` (the adjacent F2.05 hub, same accent and same `.mods`/`.dives` directory shape). Change only `<title>`/`<meta description>`, the `route-tag`, the crumbs, the `<main>` body, and the four interactive figure ids/data. No-invent guards: this page teaches only closure mechanics in plain Elixir — do not introduce Portal surfaces here; where the migrated course references its runtime, use only the real surfaces as written (the branded store, the event-sourced engine behind the one `Portal` facade, the Phoenix web app), and cite the companion course for OTP internals rather than re-teaching them. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously.
