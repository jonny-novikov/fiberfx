# F3.03.1 — Defining functions (dive)

- Route (served): `/elixir/language/modules/functions`
- File: `elixir/language/modules/functions.html`
- Place in the chapter: the first of three dives under the F3.03 module hub (`/elixir/language/modules`). It belongs to the dive arc functions → organising → pipe: this dive defines the unit of work — named functions, clauses, guards, arity, anonymous functions, and the capture operator — before the next dive groups them into a module.
- Accent: elixir (purple).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `F3.03 · part 1 of 3`

Hero h1: Defining `functions`

Lede (verbatim):

> A named function is written with `def`, and it can have several **clauses** — alternative bodies chosen by matching the arguments, refined by **guards** like `when s >= 80`. The first clause whose head matches and whose guard holds is the one that runs. The same logic can be written as an anonymous function with `fn`, or captured as a value with `&`.

Kicker (verbatim):

> Grading a single score, `82`, three ways: as a named function, as an anonymous one, and as a captured value handed to another function.

## Sections

In order:

1. `#clauses` — "One function, many clauses" — three guarded clauses tried top to bottom; for `82` the first guard (`>= 90`) fails, the second (`>= 80`) holds, so the answer is `:b`. Carries the form-select interactive.
2. `#arity` — "Arity, privacy, and captures" — name + arity identify a function (`grade/1` vs `grade/2`); `def` exports, `defp` keeps private; the capture operator `&` turns a function into a value (`&Portal.grade/1`) and `&(&1 >= 80)` is shorthand for `fn x -> x >= 80 end`. Carries a static code block plus a `.bridge`.

Running example: the learning `Portal` — `Portal.grade/1` grading a single score `82`.

Real Elixir code shown (the `#arity` static `pre.code`, verbatim):

```
# name + arity identify a function; defaults generate both arities
def grade(score, pass \\ @pass) when score >= pass, do: :pass
def grade(_score, _pass), do: :fail

defp clamp(s), do: max(0, min(100, s))   # private helper

# capture a named function, or write a tiny anonymous one with &
Enum.map([80, 92, 74], &Portal.grade/1)   # => [:b, :a, :c]
Enum.filter([80, 92, 74], &(&1 >= 80))    # => [80, 92]
```

## The interactives

### `#clauses` figure — "The form · select one"

- `<figure class="fig">`, labelled by `#fuTitle`.
- Control group id `#fuSel` (role `group`, label `The function form`). Buttons: `data-k="def"` `data-c="elixir"` (label `named (def)`, default active); `data-k="fn"` `data-c="blue"` (label `anonymous (fn)`); `data-k="capture"` `data-c="gold"` (label `capture (&)`).
- SVG element ids: input node `#fuIn`, the call label `#fuCall` (default text `Portal.grade(82)`), and the three clause rows `#fuC0` (`score ≥ 90  →  :a`), `#fuC1` (`score ≥ 80  →  :b`, highlighted), `#fuC2` (`true        →  :c`).
- Output ids: `#fuCode`, `#fuOut` (`.geo-readout`), `#fuForm`, `#fuResult`. The pure function is `pick(k)`: reads `CASES[k]`, sets the form label / call label, and repaints the code and prose. `pick('def')` runs on load. Static defaults in markup: `#fuForm` = `named function · def/1`, `#fuResult` = `:b`, `#fuCall` = `Portal.grade(82)`.
- Readout strings (verbatim from `CASES`):
  - def — form `named function · def/1`; call `Portal.grade(82)`; out `A named function with three def clauses. The guards are checked top to bottom; 82 fails >= 90 and matches >= 80, returning :b.`
  - fn — form `anonymous function · fn`; call `grade.(82)`; out `An anonymous function bound to a variable. It can have clauses and guards too; the difference is the call syntax — grade.(82) with a dot, because the name is a plain variable, not a defined function.`
  - capture — form `captured function · &/1`; call `&Portal.grade/1`; out `A captured function. &Portal.grade/1 is the function as a value — the same thing an fn produces — ready to hand to Enum.map or any function that takes a function.`

Degrade behaviour: the SVG ships its labelled default state in markup (the three clause rows with `:b` pre-highlighted), legible without JS; the `.reveal` References section is shown immediately when `IntersectionObserver` is absent or `prefers-reduced-motion: reduce` is set.

Footer build-stamp: `#stampId` reads `TSK0Nbb7JVl9EW`, decoded by `decodeBranded` (namespace `TSK`, snowflake epoch `1704067200000`). The `#st-ts` markup shows `2026-05-31 19:46:27 UTC`.

## References (#refs, verbatim)

Intro line: `Primary sources for this lesson, and where it connects in the course.`

Sources:
- `Modules and functions — Elixir documentation` — `https://hexdocs.pm/elixir/modules-and-functions.html` — defining and grouping functions.
- `Kernel — Elixir documentation` — `https://hexdocs.pm/elixir/Kernel.html` — `def`, `defp`, and the pipe.

Related in this course:
- `/elixir/language/modules` — F3.03 · Functions, modules & the pipe
- `/elixir/language/modules/pipe` — The pipe operator
- `/elixir/language/enum-streams` — F3.04 · Enumerables & streams

## Wiring

- route-tag (verbatim): `/ elixir / language / modules / functions` (the `functions` segment is the current `.rcur`).
- crumbs (verbatim): `F3` `/` `F3.03` `/` `functions`.
- toc-mini: `#clauses` → `One function, many clauses`; `#arity` → `Arity, privacy, and captures`.
- pager: prev → `/elixir/language/modules` (`← F3.03 · modules`); next → `/elixir/language/modules/organising` (`Next · organising →`).
- footer:
  - Brand column: `jonnify` logo (`/elixir`) + tag `Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir.`
  - Chapters: `F1 · Algebra` (`/elixir/algebra`), `F2 · Functional Programming` (`/elixir/functional`), `F3 · The Elixir Language` (`/elixir/language`), `F4 · Algorithms & Data Structures` (`/elixir/algorithms`), `F5 · Pragmatic Programming` (`/elixir/pragmatic`), `F6 · Phoenix Framework` (`/elixir/phoenix`).
  - The course: `Course home` (`/elixir`), `Contents & history` (`/elixir/course`), `Start · F1.01` (`/elixir/algebra/functions`).
- Page meta:
  - `<title>`: `Defining functions — F3.03 · jonnify`
  - `<meta name="description">`: `Named functions with def and defp, multiple clauses that dispatch by pattern and guard, arity, anonymous functions, and the capture operator — seen through the portal's progress and auth helpers.`

## Build instruction

To rebuild this dive, copy the `<head>…</style>`, the `header.site`, the `footer.site-foot`, and the two trailing `<script>` blocks (the form-select `pick` + Snowflake decoder, and the reveal-on-scroll enhancer) verbatim from a recent built sibling on the elixir (purple) accent — the model sibling is `/elixir/language/modules/organising` (the next dive in the same module, identical head, footer, and decoder). Change only the `<title>`/`<meta>`, the `.route-tag`, and the `<main>` body. No-invent guards: use only the real Portal surfaces as written — `Portal.grade/1`, `Portal.average/1`, and the captured/anonymous forms shown; do not invent arities or helpers the page does not display, do not redefine the branded store / event-sourced engine behind the single `Portal` facade or the Phoenix web app, and cite the companion course for OTP internals rather than re-teaching them. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously.
