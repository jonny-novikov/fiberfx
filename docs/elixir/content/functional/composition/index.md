# F2.08 — Composition & pipelines (module hub)

- Route (served): `/elixir/functional/composition`
- File: `elixir/functional/composition/index.html`
- Place in the chapter: the eighth module of F2 · Functional Programming, the last conceptual hub before the closing lab (`F2.09`). It gathers what the earlier modules built — pure functions, higher-order functions, the folds `map`/`filter`/`reduce` from `F2.05` — and frames how small functions are joined into larger programs. It opens onto three dive subpages (`compose`, `pipe`, `pipeline`) and hands forward to the data-pipeline lab.
- Accent: elixir (purple).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `F2 · Functional Programming`

Hero lede (verbatim):

> Functional programs are built by joining small functions into larger ones. Composition wires the output of one function into the input of the next; the pipe operator writes that wiring left to right. A pipeline is a run of stages, each transforming the value on its way through.

Kicker (verbatim):

> Two notations describe the same idea. `f(g(x))` composes `f` after `g` — `g` runs first, even though it is written second. The pipe rewrites this as `x |> g() |> f()`, reading in the order things happen. Most Elixir is pipelines: take a value, thread it through map, filter, and reduce, and read it top to bottom.

## What the page frames

The hub is built from three on-page teaching sections plus a `.dives` directory and a synthesis. The teaching sections each carry an interactive figure:

1. `Compose: f after g` — `#compose` — composing two functions feeds the result of the first into the second; the inner function runs first.
2. `The pipe` — `#pipe` — the pipe operator writes the same chain in execution order, `x |> inc() |> double()`.
3. `A pipeline of stages` — `#pipeline` — chain the higher-order functions from `F2.05` and a pipeline emerges; `map → filter → sum`.

The `Three deep dives` directory (`#dives`) lists the three child pages:

- `F2.08.1` — **Function composition** — Composing by hand — f after g — why the order matters, and chaining three together. Route `/elixir/functional/composition/compose`. Built.
- `F2.08.2` — **The pipe operator** — Threading a value as the first argument, reading left to right, and passing extra arguments. Route `/elixir/functional/composition/pipe`. Built.
- `F2.08.3` — **Building pipelines** — Composing map, filter, and reduce over a dataset, watching the value transform at each stage. Route `/elixir/functional/composition/pipeline`. Built.

A `deflist` in the compose section defines: `composition`, `pipe operator` (`|>` — passes the value on its left as the first argument on its right), `pipeline`, `point-free`. The closing `What this lands` synthesis names the next module: **F2.09 — The data-pipeline lab** (`/elixir/functional/pipeline-lab`).

## The interactives

### Hero figure — `x |> f |> g |> h`
- `<figure class="hero-fig">`, labelled by `#hpTitle` (`x |> f |> g |> h`).
- Step-through control group `.hp-ctrls`: button `#hpStep` (`▸ step`), button `#hpReset` (`reset`).
- SVG stage rail `#hpPipe` with stage boxes `#hpS0`..`#hpS4` (input, `f` add one `+1`, `g` double `×2`, `h` take four `−4`, result), value texts `#hpV0` (`3`) and `#hpV4`, travelling token `#hpToken` with `#hpTokV`.
- The pure stage functions (in script `STAGES`): `f` = `v + 1`, `g` = `v * 2`, `h` = `v - 4`, over the start value `X0 = 3`.
- Caption `#hpCap` (`aria-live="polite"`) default (verbatim): `3 |> f |> g |> h` — the value 3 waits at the input. / nested: h(g(f(3))) — same computation, read inside-out.
- Stepped caption strings name each stage's evaluation, e.g. `f(3) = 3 + 1 = 4`, ending `3 |> f |> g |> h = 0 — the result leaves the pipe.` and `nested: h(g(f(3))) = h(g(4)) = h(8) = 0 — same value.`

### Figure 1 — `double(inc(x)) · inc runs first` (`#coTitle`)
- Control `.fold-ctrl`: range `#coX` (`0`–`9`, value `3`), readout `#coXval`.
- SVG ids: `#coIn`, `#coMid`, `#coDbl`, `#coRes`.
- Pure function `renderCo`: `mid = x + 1`, `res = mid * 2` — `double` after `inc`.
- Code block `#coCode` shows `inc = &(&1 + 1)` / `double = &(&1 * 2)` / `composed = fn x -> double.(inc.(x)) end` / `composed.(3)   # => 8`.
- Readout `#coOut` (verbatim default): `double(inc(3)) = double(4) = 8`.

### Figure 2 — `x |> inc() |> double() · left to right` (`#piTitle`)
- Control `.fold-ctrl`: range `#piX` (`0`–`9`, value `3`), readout `#piXval`.
- SVG ids: `#piIn`, `#piRes`, `#piNest`.
- Pure function `renderPi`: `res = (x + 1) * 2`.
- Code block `#piCode` shows `3` / `|> inc()` / `|> double()` / `# => 8`.
- Readout `#piOut` (verbatim default): `3 |> inc() |> double() · reads left to right · 8`.

### Figure 3 — `map → filter → sum · each stage transforms the value` (`#plTitle`)
- Controls `.fold-ctrl`: range `#plN` (`range 1..n`, `3`–`8`, value `6`), readout `#plNval`; range `#plK` (`keep > k`, `0`–`15`, value `6`), readout `#plKval`.
- SVG ids: `#plIn`, `#plMap`, `#plFil`, `#plSum`.
- Pure function `renderPl`: `input = 1..n`, `mapped = input.map(v * 2)`, `filtered = mapped.filter(v > k)`, `sum = filtered.reduce(a + v, 0)`.
- Code block `#plCode` shows `1..6` / `|> Enum.map(&(&1 * 2))` / `|> Enum.filter(&(&1 > 6))` / `|> Enum.sum()` / `# => 30`.
- Readout `#plOut` (verbatim default): `1..6 → doubled → kept 3 over 6 → sum 30`.

Degrade behaviour: the hero notes in markup `No render on load: the static SVG already shows the value 3 waiting at the input.` The travelling-token animation `.hp-token.moved` (keyframes `hpIn`) and the `.arc-flow` dashed flow are wrapped in `@media (prefers-reduced-motion: no-preference)` and explicitly disabled under `prefers-reduced-motion: reduce`. Reveal-on-scroll (`.reveal`) is JS-gated and collapses to visible when reduced motion is set or `IntersectionObserver` is absent.

Footer build-stamp: `#stamp` with `#stampId` = `TSK0Nau6DKe2nw`; the decoder (`decodeBranded`, base62 over namespace `TSK` + snowflake, epoch `1704067200000`) populates the panel, whose `#st-ts` default reads `2026-05-31 09:44:28 UTC`.

## References (#refs, verbatim)

This page has no `#refs` References section (no Sources / Related-in-this-course block). Cross-links are carried inline instead: the `.bridge` cells reference `F1.03 · composition`, `F2.05 · folds`, and `F2.09 · the lab`; the synthesis and `.note` link to the three dives `/elixir/functional/composition/compose`, `/elixir/functional/composition/pipe`, `/elixir/functional/composition/pipeline`, and name **F2.09 — The data-pipeline lab**.

## Wiring

- route-tag (verbatim): `/` `elixir` `/` `functional` `/` `composition` (the `composition` segment is the current `.rcur`).
- crumbs (verbatim): `F2 · Functional` `/` `F2.07` `/` `F2.08` (the last is `.here`), linking `/elixir/functional` and `/elixir/functional/adt`.
- toc-mini: `#compose` Compose: f after g · `#pipe` The pipe · `#pipeline` A pipeline of stages · `#dives` Three deep dives.
- pager: prev → `/elixir/functional/adt/matching` (`← F2.07 · matching`); next → `/elixir/functional/composition/compose` (`Start · composition →`).
- footer: column **Chapters** — `/elixir/algebra` F1 · Algebra, `/elixir/functional` F2 · Functional Programming, `/elixir/language` F3 · The Elixir Language, `/elixir/algorithms` F4 · Algorithms & Data Structures, `/elixir/pragmatic` F5 · Pragmatic Programming, `/elixir/phoenix` F6 · Phoenix Framework. Column **The course** — `/elixir` Course home, `/elixir/course` Contents & history, `/elixir/algebra/functions` Start · F1.01. Foot brand links `/elixir`.
- Page meta — `<title>`: `Composition & pipelines — F2.08 · jonnify`. `<meta description>`: `Building programs by combining functions: composing two so one feeds the next, the pipe operator that threads a value left to right, and pipelines of map, filter, and reduce.`

## Build instruction

To rebuild this hub, copy the `head…</style>`, the `header.site`, the `footer.site-foot`, and the two trailing `<script>` blocks (the per-figure renderers + Snowflake decoder, then the JS-on / reveal-on-scroll bootstrap) verbatim from a recent BUILT sibling on the elixir (purple) accent; change only the `<title>`/`<meta description>`, the header `route-tag` (ending `.rcur` = `composition`), the crumbs, and the `<main>` body. The model sibling to copy from is another F2 module hub on this accent — `elixir/functional/adt/index.html` (`F2.07`, the immediately prior hub, same hero/dives/synthesis shape) — or, for a sibling that already carries the `x |> f |> g |> h` hero figure, copy the hero markup from this page's own pattern. No-invent guards: this chapter is mathematics-then-Elixir and does not touch the live Portal product surface; do not invent Portal APIs, and where the Phoenix/OTP layer is relevant defer to the companion chapters (`F5 · Pragmatic`, `F6 · Phoenix`) rather than re-teaching internals. Use only the real Elixir surfaces shown (`Enum.map`/`Enum.filter`/`Enum.sum`, `|>`, capture syntax `&(&1 …)`). Voice rules: no first person, no exclamation marks, no emoji, and none of just / simply / obviously.
