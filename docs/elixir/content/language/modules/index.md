# F3.03 — Functions, modules & the pipe (module hub)

- Route (served): `/elixir/language/modules`
- File: `elixir/language/modules/index.html`
- Place in the chapter: the third module of F3 · The Elixir Language, after `/elixir/language/values` (F3.01) and `/elixir/language/match` (F3.02). It frames the unit of work — a function — the namespace that groups functions — a module — and the pipe `|>` that composes them, then opens three deep dives. The running example is a learning `Portal`: a learner's quiz scores turned into an average and then a letter grade.
- Accent: elixir (purple) — `--elixir:#b39ddb` / `--elixir-bright:#cdb8f0`.
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `F3 · Syntax & flow · module 3`

Hero h1: Functions, modules & the `pipe`

Lede (verbatim):

> A function is the unit of work in Elixir: it takes arguments and returns a value, with no objects and no mutation in sight. A **module** is the namespace that groups related functions under one name. And the pipe operator `|>` is the glue — it threads a value through a sequence of functions so a nested call reads as a left-to-right pipeline.

Kicker (verbatim):

> The running example is a learning `Portal`: a learner's quiz scores, turned into an average and then a letter grade. Three angles open the module — what a function is, how a module groups functions, and how `|>` composes them.

## What the page frames

The page carries a `#flow` teaching section ("A value, transformed", with the angle-select interactive) and a `#dives` directory of three dive cards. The dives, in order:

- F3.03.1 — Defining functions — `def` and `defp`, multiple clauses with guards, arity, anonymous functions, and the capture operator. Route `/elixir/language/modules/functions`. Built (left-border accent `--elixir`).
- F3.03.2 — Organising with modules — `defmodule`, attributes, `alias` and `import`, and documentation — the `Portal` namespace. Route `/elixir/language/modules/organising`. Built (left-border accent `--blue`).
- F3.03.3 — The pipe operator — `|>` threads a value as the first argument, turning a nested call into a readable pipeline. Route `/elixir/language/modules/pipe`. Built (left-border accent `--gold`).

A `.bridge` connects from F3.02 (the match operator binds variables by shape) to F3.03 (function clauses match their arguments the same way; modules group the functions; `|>` composes them). The closing `.note` orders the dives functions → organising → pipe, then points to the next module `/elixir/language/enum-streams` (F3.04 — Enumerables & streams).

## The interactives

### Hero figure — "Two ways to write one call"

- `<figure class="hero-fig">`, labelled by `#puTitle` (`.fc-lbl` text: `Two ways to write one call`).
- The SVG (`#puChain` is the swappable group) opens with a static default in markup: the nested call `Portal.grade(Portal.average([80, 92, 74]))`, captioned `NESTED CALL · reads inside-out` and `innermost call runs first`, with a fixed `RESULT` node showing `:b` and a header node `scores → average → grade` under `ONE COMPUTATION`.
- Controls (`.hp-ctrls`): button `#puBtn` (label `▸ unfold the pipe`) and button `#puReset` (label `reset`).
- The toggle is driven by a `render()` closure flipping a `piped` boolean; it rebuilds `#puChain` from the `PIPE` array of rows: `[80, 92, 74]` ("the score list"), `|> Portal.average()` ("pipes the list in as the first argument"), `|> Portal.grade()` ("pipes 82.0 in, returns :b"). The button text becomes `▸ fold it back` when piped.
- Readout `#puCap` (verbatim, default / nested state):

  `Portal.grade(Portal.average(scores))`
  `The nested call reads inside-out: the innermost runs first.`

  Piped state (verbatim):

  `scores |> Portal.average() |> Portal.grade()`
  `The pipe reads top to bottom, in the order it runs.`

### `#flow` figure — "The angle · select one"

- `<figure class="fig">`, labelled by `#moTitle`.
- Control group id `#moSel` (role `group`, label `The angle`). Buttons: `data-k="function"` `data-c="elixir"` (label `function`, default active); `data-k="module"` `data-c="blue"` (label `module`); `data-k="pipe"` `data-c="gold"` (label `pipe`).
- SVG element ids: arrow labels `#moA1` / `#moA2`, pipe glyphs `#moP1` / `#moP2`, nodes `#moN1` / `#moN2` / `#moN3`, caption `#moCaption`. The pipeline reads `[80, 92, 74]` `|>` `82.0` `|>` `:b`.
- Output ids: `#moCode` (syntax-highlighted code), `#moOut` (`.geo-readout`), `#moRole`, `#moExpr`. The pure function is `pick(k)`: it reads `CASES[k]` and repaints the SVG fills, the code block, the prose readout, the role, and the expression. `pick('function')` runs on load.
- Readout strings (verbatim from `CASES`):
  - function — caption `each step is a function returning a value`; role `map an input to an output`; expr `Portal.average([80, 92, 74]) #=> 82.0`; out `A function takes arguments and returns a value. average/1 turns a list of scores into one number; nothing is assigned in place, a fresh value comes back.`
  - module — caption `both functions live in the Portal module`; role `group related functions`; expr `Portal.average/1 · Portal.grade/1`; out `A module is a namespace. defmodule Portal groups average/1 and grade/1 under one name, called as Portal.average and Portal.grade.`
  - pipe — caption `the pipe threads the value through each function`; role `thread the value left to right`; expr `[80, 92, 74] |> Portal.average() |> Portal.grade() #=> :b`; out `The pipe |> passes the value on its left as the first argument of the call on its right, so the chain reads in the order it runs instead of inside-out.`
- Static default in markup: `#moCaption` is `each step is a function returning a value`, `#moRole` is `map an input to an output`, `#moExpr` is `Portal.average([80, 92, 74]) #=> 82.0` — so the figure is legible before JS runs.

Degrade behaviour: the hero SVG ships the nested-call state inline (visible without JS); `.hp-row.hp-new` carries the `hpIn` slide-in animation only under `@media (prefers-reduced-motion: no-preference)` and is set to `animation:none` under `prefers-reduced-motion: reduce`. The `#flow` figure's default angle is hard-coded in the SVG markup. The `.reveal` References section is shown immediately when `IntersectionObserver` is absent or reduced motion is set.

Footer build-stamp: `#stampId` reads `TSK0Nbb7JHZCjI`, decoded by `decodeBranded` (base62 after a 3-char namespace `TSK`, snowflake epoch `1704067200000`). The `#st-ts` markup shows `2026-05-31 19:46:26 UTC`.

## References (#refs, verbatim)

Intro line: `Primary sources for this lesson, and where it connects in the course.`

Sources:
- `Modules and functions — Elixir documentation` — `https://hexdocs.pm/elixir/modules-and-functions.html` — defining and grouping functions.
- `Kernel — Elixir documentation` — `https://hexdocs.pm/elixir/Kernel.html` — `def`, `defp`, and the pipe.

Related in this course:
- `/elixir/language` — F3 · The Elixir Language
- `/elixir/language/match` — F3.02 · Pattern matching & the match operator
- `/elixir/language/enum-streams` — F3.04 · Enumerables & streams

## Wiring

- route-tag (verbatim): `/ elixir / language / modules` (the `modules` segment is the current `.rcur`).
- crumbs (verbatim): `F3 · The Elixir Language` `/` `F3.03 · functions, modules & the pipe`.
- toc-mini: `#flow` → `A value, transformed`; `#dives` → `Three deep dives`.
- pager: prev → `/elixir/language/match` (`← F3.02 · match`); next → `/elixir/language/modules/functions` (`Start · defining functions →`).
- footer:
  - Brand column: `jonnify` logo (`/elixir`) + tag `Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir.`
  - Chapters: `F1 · Algebra` (`/elixir/algebra`), `F2 · Functional Programming` (`/elixir/functional`), `F3 · The Elixir Language` (`/elixir/language`), `F4 · Algorithms & Data Structures` (`/elixir/algorithms`), `F5 · Pragmatic Programming` (`/elixir/pragmatic`), `F6 · Phoenix Framework` (`/elixir/phoenix`).
  - The course: `Course home` (`/elixir`), `Contents & history` (`/elixir/course`), `Start · F1.01` (`/elixir/algebra/functions`).
- Page meta:
  - `<title>`: `Functions, modules & the pipe — F3.03 · jonnify`
  - `<meta name="description">`: `Functions are the unit of work, modules group them, and the pipe composes them. This module builds the learning portal's first real modules — Accounts, Auth, Catalog, Progress — and the functions they expose. Three deep dives follow.`

## Build instruction

To rebuild this hub, copy the `<head>…</style>`, the `header.site`, the `footer.site-foot`, and the two trailing `<script>` blocks (the hero-figure + figure-select + Snowflake decoder, and the reveal-on-scroll enhancer) verbatim from a recent built sibling on the elixir (purple) accent — the model sibling is `/elixir/language/modules` itself as currently built, or any F3 hub on the same accent. Change only the `<title>`/`<meta>`, the `.route-tag`, and the `<main>` body. No-invent guards: use only the real Portal surfaces as written — the running example is the learning `Portal` with `Portal.average/1` and `Portal.grade/1`; do not introduce APIs the page does not show, do not redefine the branded store / event-sourced engine behind the single `Portal` facade or the Phoenix web app, and cite the companion course for OTP internals rather than re-teaching them. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously.
