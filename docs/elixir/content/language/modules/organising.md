# F3.03.2 — Organising with modules (dive)

- Route (served): `/elixir/language/modules/organising`
- File: `elixir/language/modules/organising.html`
- Place in the chapter: the second of three dives under the F3.03 module hub (`/elixir/language/modules`). It sits in the dive arc functions → organising → pipe: after F3.03.1 defines the functions, this dive gives them a home — the `Portal` namespace, its attributes, `alias`, `import`, and documentation — before F3.03.3 composes them with the pipe.
- Accent: elixir (purple).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `F3.03 · part 2 of 3`

Hero h1: Organising with `modules`

Lede (verbatim):

> A module is declared with `defmodule` and groups related functions under one name. Inside it, three facilities keep code tidy: module **attributes** hold compile-time constants, `alias` shortens a long module name, and `import` pulls another module's functions into scope so you can call them without a prefix.

Kicker (verbatim):

> Building up the `Portal` module: a pass-mark constant, an alias for a nested report module, and an import that drops a prefix. Select a facility to see what it changes.

## Sections

In order:

1. `#module` — "The Portal module" — everything lives inside `defmodule Portal do … end`; attributes, aliases, and imports are directives that shape how functions are written and called. Carries the facility-select interactive.
2. `#docs` — "Documentation & structure" — `@moduledoc` documents the module and `@doc` the function beneath it, both readable in IEx with `h Portal`; one module per file, named to match (`Portal.Report` lives in `portal/report.ex`); modules nest by dotting the name, which is organisational, not containment. Carries a static code block plus a `.bridge`.

Running example: the learning `Portal` module — `@pass_mark`, `alias Portal.Report`, `import Integer`, `Portal.grade/1`, and the nested `Portal.Report`.

Real Elixir code shown (the `#docs` static `pre.code`, verbatim):

```
defmodule Portal do
  @moduledoc "Scoring and grading for the learning portal."
  @pass_mark 60

  @doc "Grades an average score into :a, :b, or :c."
  def grade(avg), do: ...
end

defmodule Portal.Report do   # nested name, own file: portal/report.ex
  def render(grades), do: ...
end
```

## The interactives

### `#module` figure — "The facility · select one"

- `<figure class="fig">`, labelled by `#orTitle`.
- Control group id `#orSel` (role `group`, label `The module facility`). Buttons: `data-k="attr"` `data-c="elixir"` (label `@attribute`, default active); `data-k="alias"` `data-c="blue"` (label `alias`); `data-k="import"` `data-c="gold"` (label `import`).
- SVG element ids: the highlighted directive rows `#orL1` (`@pass_mark 60`), `#orL2` (`alias Portal.Report`), `#orL3` (`import Integer, only: [is_even: 1]`), inside the `defmodule Portal do` box with a `def grade(score), do: ...` line.
- Output ids: `#orCode`, `#orOut` (`.geo-readout`), `#orRole`, `#orWhat`. The pure function is `pick(k)`: reads `CASES[k]`, repaints the three rows via `row(id, fill, stroke, w)`, sets the role and effect, and swaps the code and prose. `pick('attr')` runs on load. Static defaults in markup: `#orRole` = `a compile-time constant`, `#orWhat` = `@pass_mark 60 — one value, fixed at compile time`.
- Readout strings (verbatim from `CASES`):
  - attr — role `a compile-time constant`; effect `@pass_mark 60 — one value, fixed at compile time`; out `A module attribute is a named constant resolved when the module compiles. @pass_mark reads as 60 wherever it appears — one place to change the threshold.`
  - alias — role `shorten a module name`; effect `alias Portal.Report — now write Report`; out `alias creates a short local name for a module. After alias Portal.Report, Report.render means Portal.Report.render — shorter call sites, same function.`
  - import — role `drop the module prefix`; effect `import Integer — call is_even/1 directly`; out `import brings another module's functions into scope so you call them bare. only: keeps it narrow — importing only is_even/1 rather than everything.`

Degrade behaviour: the SVG ships the module box with the `@pass_mark` row pre-highlighted in markup, legible without JS; the `.reveal` References section is shown immediately when `IntersectionObserver` is absent or `prefers-reduced-motion: reduce` is set.

Footer build-stamp: `#stampId` reads `TSK0Nbb7JlegW8`, decoded by `decodeBranded` (namespace `TSK`, snowflake epoch `1704067200000`). The `#st-ts` markup shows `2026-05-31 19:46:27 UTC`.

## References (#refs, verbatim)

Intro line: `Primary sources for this lesson, and where it connects in the course.`

Sources:
- `Modules and functions — Elixir documentation` — `https://hexdocs.pm/elixir/modules-and-functions.html` — defining and grouping functions.
- `Kernel — Elixir documentation` — `https://hexdocs.pm/elixir/Kernel.html` — `def`, `defp`, and the pipe.

Related in this course:
- `/elixir/language/modules` — F3.03 · Functions, modules & the pipe
- `/elixir/language/match` — F3.02 · Pattern matching
- `/elixir/language/enum-streams` — F3.04 · Enumerables & streams

## Wiring

- route-tag (verbatim): `/ elixir / language / modules / organising` (the `organising` segment is the current `.rcur`).
- crumbs (verbatim): `F3` `/` `F3.03` `/` `organising`.
- toc-mini: `#module` → `The Portal module`; `#docs` → `Documentation & structure`.
- pager: prev → `/elixir/language/modules/functions` (`← F3.03.1 · functions`); next → `/elixir/language/modules/pipe` (`Next · the pipe →`).
- footer:
  - Brand column: `jonnify` logo (`/elixir`) + tag `Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir.`
  - Chapters: `F1 · Algebra` (`/elixir/algebra`), `F2 · Functional Programming` (`/elixir/functional`), `F3 · The Elixir Language` (`/elixir/language`), `F4 · Algorithms & Data Structures` (`/elixir/algorithms`), `F5 · Pragmatic Programming` (`/elixir/pragmatic`), `F6 · Phoenix Framework` (`/elixir/phoenix`).
  - The course: `Course home` (`/elixir`), `Contents & history` (`/elixir/course`), `Start · F1.01` (`/elixir/algebra/functions`).
- Page meta:
  - `<title>`: `Organising with modules — F3.03 · jonnify`
  - `<meta name="description">`: `defmodule, module attributes, alias and import, and documentation — how the Portal namespace is structured and how its modules refer to one another.`

## Build instruction

To rebuild this dive, copy the `<head>…</style>`, the `header.site`, the `footer.site-foot`, and the two trailing `<script>` blocks (the facility-select `pick` + `row` repainter + Snowflake decoder, and the reveal-on-scroll enhancer) verbatim from a recent built sibling on the elixir (purple) accent — the model sibling is `/elixir/language/modules/functions` (the previous dive in the same module, identical head, footer, and decoder). Change only the `<title>`/`<meta>`, the `.route-tag`, and the `<main>` body. No-invent guards: use only the real Portal surfaces as written — the `Portal` module with `@pass_mark`, `alias Portal.Report`, `import Integer`, `Portal.grade/1`, and the nested `Portal.Report` in `portal/report.ex`; do not invent further modules or functions, do not redefine the branded store / event-sourced engine behind the single `Portal` facade or the Phoenix web app, and cite the companion course for OTP internals rather than re-teaching them. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously.
