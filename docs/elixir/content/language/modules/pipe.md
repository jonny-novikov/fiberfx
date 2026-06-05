# F3.03.3 — The pipe operator (dive)

- Route (served): `/elixir/language/modules/pipe`
- File: `elixir/language/modules/pipe.html`
- Place in the chapter: the third and last dive under the F3.03 module hub (`/elixir/language/modules`). It closes the dive arc functions → organising → pipe: after F3.03.1 defines functions and F3.03.2 groups them into a module, this dive shows how `|>` composes them into one readable pipeline — the same composition seen with folds in F2, written as syntax.
- Accent: elixir (purple).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `F3.03 · part 3 of 3`

Hero h1: The `pipe` operator

Lede (verbatim):

> The pipe operator `|>` takes the value on its left and passes it as the *first* argument to the function call on its right. That single rule turns a nest of function calls, read inside-out, into a top-to-bottom pipeline read in the order it runs — the same composition you saw with folds in F2, written as syntax.

Kicker (verbatim):

> The same grade computation, two ways: nested calls versus a pipeline. Both produce `:b`; one is far easier to read.

## Sections

In order:

1. `#shape` — "Inside-out vs left-to-right" — averaging then grading a score list is two function calls; nested, the inner call reads first; piped, the steps read in run order; the data flow is identical, only the reading changes. Carries the form-select interactive.
2. `#first` — "The value goes first" — the whole rule: `x |> f(a, b)` is rewritten to `f(x, a, b)`; the piped value becomes the first argument; Elixir's core functions take their main subject first so they pipe cleanly. Carries a static code block plus a `.bridge`.

Running example: the learning `Portal` — `Portal.average/1` then `Portal.grade/1` over `[80, 92, 74]`, plus `Enum.filter`/`Enum.sum` showing the first-argument rule.

Real Elixir code shown (the `#first` static `pre.code`, verbatim):

```
# x |> f(a, b)  is  f(x, a, b) — the value is inserted as the first argument
[80, 92, 74]
|> Enum.filter(&(&1 >= 80))   # Enum.filter([80, 92, 74], fun) => [80, 92]
|> Enum.sum()                 # Enum.sum([80, 92])            => 172

# the nested equivalent, read inside-out:
Enum.sum(Enum.filter([80, 92, 74], &(&1 >= 80)))
```

## The interactives

### `#shape` figure — "The form · select one"

- `<figure class="fig">`, labelled by `#piTitle`.
- Control group id `#piSel` (role `group`, label `The form`). Buttons: `data-k="piped"` `data-c="gold"` (label `piped`, default active); `data-k="nested"` `data-c="blue"` (label `nested`).
- SVG element ids: arrow labels `#piA1` / `#piA2`, the flow glyphs `#piP1` / `#piP2`, nodes `#piN1` / `#piN2` / `#piN3`, caption `#piCaption`. The pipeline reads `[80, 92, 74]` `→` `82.0` `→` `:b`.
- Output ids: `#piCode`, `#piOut` (`.geo-readout`), `#piForm`, `#piResult`, `#piExpr`. The pure function is `pick(k)`: reads `CASES[k]`, recolours `#piP1`/`#piP2`, swaps the caption / form / expression, and repaints the code and prose. `pick('piped')` runs on load. Static defaults in markup: `#piCaption` = `source reads in run order, left to right`, `#piForm` = `piped`, `#piResult` = `:b`, `#piExpr` = `[80, 92, 74] |> Portal.average() |> Portal.grade()`.
- Readout strings (verbatim from `CASES`):
  - piped — caption `source reads in run order, left to right`; form `piped`; expr `[80, 92, 74] |> Portal.average() |> Portal.grade()`; out `The piped form reads in execution order: take the scores, average them, grade the result. Each step receives the previous value as its first argument.`
  - nested — caption `source reads inside-out: the inner call runs first`; form `nested`; expr `Portal.grade(Portal.average([80, 92, 74]))`; out `The nested form runs identically, but you read it inside-out: the innermost average evaluates first, then grade wraps it. Harder to scan as the chain grows.`

Degrade behaviour: the SVG ships the piped default state inline (the `→` glyphs and the run-order caption), legible without JS; the `.reveal` References section is shown immediately when `IntersectionObserver` is absent or `prefers-reduced-motion: reduce` is set.

Footer build-stamp: `#stampId` reads `TSK0Nbb7JzZ1tI`, decoded by `decodeBranded` (namespace `TSK`, snowflake epoch `1704067200000`). The `#st-ts` markup shows `2026-05-31 19:46:27 UTC`.

## References (#refs, verbatim)

Intro line: `Primary sources for this lesson, and where it connects in the course.`

Sources:
- `Modules and functions — Elixir documentation` — `https://hexdocs.pm/elixir/modules-and-functions.html` — defining and grouping functions.
- `Kernel — Elixir documentation` — `https://hexdocs.pm/elixir/Kernel.html` — `def`, `defp`, and the pipe.

Related in this course:
- `/elixir/language/modules` — F3.03 · Functions, modules & the pipe
- `/elixir/language/match` — F3.02 · Pattern matching & the match operator
- `/elixir/language/enum-streams` — F3.04 · Enumerables & streams

## Wiring

- route-tag (verbatim): `/ elixir / language / modules / pipe` (the `pipe` segment is the current `.rcur`).
- crumbs (verbatim): `F3` `/` `F3.03` `/` `pipe`.
- toc-mini: `#shape` → `Inside-out vs left-to-right`; `#first` → `The value goes first`.
- pager: prev → `/elixir/language/modules/organising` (`← F3.03.2 · organising`); next → `/elixir/language` (`Back to F3 · The Elixir Language →`).
- footer:
  - Brand column: `jonnify` logo (`/elixir`) + tag `Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir.`
  - Chapters: `F1 · Algebra` (`/elixir/algebra`), `F2 · Functional Programming` (`/elixir/functional`), `F3 · The Elixir Language` (`/elixir/language`), `F4 · Algorithms & Data Structures` (`/elixir/algorithms`), `F5 · Pragmatic Programming` (`/elixir/pragmatic`), `F6 · Phoenix Framework` (`/elixir/phoenix`).
  - The course: `Course home` (`/elixir`), `Contents & history` (`/elixir/course`), `Start · F1.01` (`/elixir/algebra/functions`).
- Page meta:
  - `<title>`: `The pipe operator — F3.03 · jonnify`
  - `<meta name="description">`: `|> threads a value as the first argument to the next call, turning nested calls into a readable pipeline — composing Portal and Enum functions over a learner's progress.`

## Build instruction

To rebuild this dive, copy the `<head>…</style>`, the `header.site`, the `footer.site-foot`, and the two trailing `<script>` blocks (the form-select `pick` + Snowflake decoder, and the reveal-on-scroll enhancer) verbatim from a recent built sibling on the elixir (purple) accent — the model sibling is `/elixir/language/modules/organising` (the previous dive in the same module, identical head, footer, and decoder). Change only the `<title>`/`<meta>`, the `.route-tag`, and the `<main>` body. No-invent guards: use only the real Portal surfaces as written — `Portal.average/1`, `Portal.grade/1`, and the standard-library `Enum.filter`/`Enum.sum` shown; do not invent functions or change the first-argument rule the page states, do not redefine the branded store / event-sourced engine behind the single `Portal` facade or the Phoenix web app, and cite the companion course for OTP internals rather than re-teaching them. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously.
