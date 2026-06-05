# F3.02.2 — Destructuring portal data (dive)

- Route (served): `/elixir/language/match/destructuring`
- File: `elixir/language/match/destructuring.html`
- Place in the chapter: part 2 of 3 in module F3.02 (Pattern matching). It turns the match operator outward — the same `=` that asserts and binds now pulls values out of compound data: tuples, maps, structs, and lists. Sits between `operator` and `branching`.
- Accent: elixir (purple), `--elixir` / `--elixir-bright`.
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `F3.02 · part 2 of 3`

H1: Destructuring portal data

Hero lede (verbatim):

> The same match operator pulls values _out_ of compound data. Put the shape you expect on the left, with names where the interesting parts are, and those names bind to the matching pieces — tuples by position, maps and structs by key, lists by head and tail.

Kicker line (verbatim):

> The portal moves a handful of shapes around: the claims decoded from a magic-link token, the params from a sign-in request, a progress record, and the list of lessons a learner has finished. Each is taken apart with one pattern.

## Sections

In order:

1. `Take it apart` (`#destr`) — the teaching section. The reader selects a piece of Portal data to see the destructuring pattern and the names it binds. Carries the interactive figure.
2. `What binds, what is ignored` (`#rules`) — the advanced section. States the rules: a map pattern matches on listed keys and ignores extras; a struct pattern additionally asserts the type; `[head | tail]` splits a list; `_` matches without binding. Includes a `.deflist` (tuple / map / struct / list) and an F2→F3 `.bridge` (algebraic data types → destructuring).

Running example: four real Portal shapes — auth claims, request params, a `%Progress{}` record, and a learner's completed-lesson list — each destructured by one match.

Real Elixir shown (verbatim from the figure's `DE` table):
- claims — `%{email: email, course: course} = claims` over `%{email: "ada@portal.dev", course: "elixir", exp: 1769900000}`.
- params — `%{"email" => email, "token" => token} = params` over `%{"email" => "ada@portal.dev", "token" => "MLT0NbAb2XfIjA"}`.
- progress — `%Progress{lesson_id: lesson_id, completed_at: at} = progress` over `%Progress{user_id: "USR0NbAb1xcFCy", lesson_id: "LSN0NbAb2Lk9GS", completed_at: ~U[...]}`.
- completed — `[first | rest] = completed` over `["LSN0NbAb2Lk9GS", "LSN0NbCc7gH1Qm", "LSN0NbDd9kL3Rn"]`.

## The interactives

### `Destructuring · select a shape` (`aria-labelledby="dTitle"`)
- Title id `dTitle`: `Destructuring · select a shape`.
- Control group `deSel` (`.solid-select`, `aria-label="Portal data shape"`): `auth claims` (`data-k="claims"`, `data-c="elixir"`, active default); `request params` (`data-k="params"`, `data-c="blue"`); `progress record` (`data-k="progress"`, `data-c="sage"`); `lesson list` (`data-k="completed"`, `data-c="gold"`).
- Code `pre` id `deCode` (the comment + pattern). SVG id `deRows` (the dynamically built `BINDS` rows; each row is a name pill on the left, a `←` arrow, and a value pill on the right). Readout `deOut` (`.geo-readout`, `aria-live="polite"`).
- Pure functions: `render(key)` reads the `DE` table, writes the code, rebuilds the `deRows` bind pills, and writes the note. `mk(tag, a)` creates an SVG node; `pill(x, y, w, text, stroke, tf, anchorStart)` builds one rounded label. Default `render('claims')`.
- Bind rows per shape (name ← value, verbatim): claims — `email` ← `"ada@portal.dev"`, `course` ← `"elixir"`; params — `email` ← `"ada@portal.dev"`, `token` ← `"MLT0NbAb2XfIjA"`; progress — `lesson_id` ← `"LSN0NbAb2Lk9GS"`, `at` ← `~U[2026-01-27 15:11:37Z]`; completed — `first` ← `"LSN0NbAb2Lk9GS"`, `rest` ← `["LSN0NbCc7gH1Qm", "LSN0NbDd9kL3Rn"]`.
- `deOut` notes (verbatim):
  - claims: `A map pattern matches on the keys it lists and ignores the rest — exp is present but not bound here.`
  - params: `Request params arrive with string keys, so the pattern uses "key" => var. Both fields bind in one step.`
  - progress: `A struct pattern names the struct and the fields you want; omitted fields are not bound, and the struct type is asserted.`
  - completed: `The list pattern [head | tail] splits a list into its first element and the rest — the basis of recursion over lists.`
- Takeaway (verbatim): One line replaces a fistful of accessor calls. The pattern reads like the data it expects, so the shape of the input is visible at the point you use it.

### Degrade behaviour
The figure renders the `claims` default on load via `render('claims')`. The `.arc-flow` and `.hp-row` animations are gated to `prefers-reduced-motion: no-preference`; reveal-on-scroll is JS-gated and disabled under reduced motion. The `deRows` group is JS-built, so without JS the `deCode` shows the default-selected pattern and the bind pills are absent.

### Footer build-stamp decoder
Stamp id `TSK0NbBlxptToO`. `decodeBranded` base-62-decodes after the 3-char namespace and splits the Snowflake against `EPOCH_MS = 1704067200000`; the page hard-codes the decoded `st-ts` panel value `2026-05-31 13:51:47 UTC`.

## References (#refs, verbatim)

Intro line: Primary sources for this lesson, and where it connects in the course.

Sources:
- `https://hexdocs.pm/elixir/pattern-matching.html` — Pattern matching — Elixir documentation — `=` as the match operator.
- `https://hexdocs.pm/elixir/case-cond-and-if.html` — case, cond, and if — Elixir documentation — matching in control flow.

Related in this course:
- `/elixir/language/match` — F3.02 · Pattern matching
- `/elixir/language/match/operator` — The match operator
- `/elixir/functional/adt` — F2.07 · Algebraic data types

## Wiring

- route-tag (verbatim): `/` `elixir` `/` `language` `/` `match` `/` `destructuring` (with `destructuring` as the current `.rcur` segment).
- crumbs (verbatim): `F3` (links `/elixir/language`) `/` `F3.02` (links `/elixir/language/match`) `/` `destructuring` (`.here`).
- toc-mini: `#destr` → `Take it apart`; `#rules` → `What binds, what is ignored`.
- pager: prev → `/elixir/language/match/operator` label `The match operator`; next → `/elixir/language/match/branching` label `Next · branching`.
- footer: column `Chapters` — `/elixir/algebra` (F1 · Algebra), `/elixir/functional` (F2 · Functional Programming), `/elixir/language` (F3 · The Elixir Language), `/elixir/algorithms` (F4 · Algorithms & Data Structures), `/elixir/pragmatic` (F5 · Pragmatic Programming), `/elixir/phoenix` (F6 · Phoenix Framework). Column `The course` — `/elixir` (Course home), `/elixir/course` (Contents & history), `/elixir/algebra/functions` (Start · F1.01). Brand links `/elixir`.
- Page meta — `<title>`: `Destructuring portal data — F3.02 · jonnify`. `<meta description>`: `Pulling fields out of tuples, lists, maps, and structs in a single match — the auth claims, request params, and progress records the learning portal passes around.`

## Build instruction

To rebuild this dive, copy the `head…</style>`, `header`, `footer`, and the two trailing `<script>` blocks (the figure IIFE + the Snowflake decoder, and the reveal-on-scroll enhancer) verbatim from a recent built sibling on this chapter accent, then change only `<title>`/`<meta>`, the `route-tag`, and the `<main>` body (hero, the two sections, the figure, references, pager). The canonical model sibling is `elixir/language/match/operator.html` — the same dive shell on the same elixir accent (this page swaps that figure's box diagram for an SVG-built bind table driven by the `DE` data table). No-invent guards: use only the real Portal surfaces as written — the branded `USR…`/`LSN…`/`MLT…` ids, the `%Progress{}` struct with `user_id`/`lesson_id`/`completed_at`, the string-keyed params, and `course: "elixir"`; do not invent new fields, ids, or struct names, and cite the companion course for OTP internals rather than re-teaching them. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously.
