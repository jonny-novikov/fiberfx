# F4.10.1 — Idiomatic patterns (dive)

- Route (served): `/elixir/algorithms/recipes/patterns`
- File: `/Users/jonny/dev/jonnify/elixir/algorithms/recipes/patterns.html`
- Place in the chapter: part 1 of 3 of module `F4.10` (Practical recipes) in F4 · Algorithms & Data Structures. It is the request-lifecycle recipe — a `with` chain that threads validate → authenticate → load → authorize for a "view a lesson" request — and reuses the F4.08 edge validation as the chain's first step. First dive off the `F4.10` hub.
- Accent: sage (F4 · Algorithms & Data Structures).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F4.10 · part 1 of 3 · the request lifecycle`

Hero h1 (verbatim): Idiomatic `patterns`

Hero lede (verbatim):

> A request to view a lesson has to clear four gates before it renders: the id must be well-formed, the caller authenticated, the lesson present, and the caller allowed to see it. Written as nested `case` expressions that is a pyramid. Written as a `with` chain it is four lines that read top to bottom, each binding the happy path and every failure falling through to one `else` that maps a tagged error to a status.

Kicker line (verbatim):

> The same chain, five outcomes. Choose which gate fails and watch where the `with` stops and what it returns.

## Sections

In order:

1. `#chain` — **Where the chain stops** (teaching). The interactive "Outcome · select one" figure plus its take.
2. `#advanced` — **Advanced: one else, tagged errors** (advanced). Why every step returns a tagged result, why the chain binds only what the body needs, and how an `else`-less `with` would leak an untagged `nil`. Carries the static `show/2` controller code.

Running example: a Phoenix-style `show(conn, %{"id" => raw, "sid" => sid})` action threading four gates then `render`. Real Elixir shown (advanced block, verbatim): a `with` over `Portal.Id.validate(raw, :LSN)`, `Auth.current_user(sid)`, `Catalog.fetch_lesson(id)`, `Catalog.authorize(user, lesson)`, body `render(conn, "lesson.json", lesson: lesson)` (`# 200 — the happy path`), and an `else` mapping `{:error, :bad_id}` → `400`, `{:error, :unauthenticated}` → `401`, `{:error, :not_found}` → `404`, `{:error, :forbidden}` → `403` via `send_resp`.

## The interactives

### Figure — "Outcome · select one"

- `<figure class="fig">`, labelled by `id="ptTitle"` (`Outcome · select one`).
- Control group `id="ptSel"` (role `group`, aria-label `Request outcome`) with buttons: `data-k="ok"` `data-c="sage"` (active, label `all pass`); `data-k="bad"` `data-c="gold"` (`bad id`); `data-k="auth"` `data-c="gold"` (`not signed in`); `data-k="missing"` `data-c="gold"` (`no lesson`); `data-k="forbid"` `data-c="gold"` (`not enrolled`).
- SVG ids: row group `ptRows` (five rows `ptRow0`..`ptRow4` with tags `ptTag0`..`ptTag4`, built in JS), status bar text `ptStatus`. Code/readout ids: `ptCode`, `ptOut`, `ptRole`, `ptResult`.
- Pure logic: `STEPS` array (`validate_id`, `current_user`, `fetch_lesson`, `authorize`, `render`) each with an `ok`/`err` tagged tuple; `SCN` maps each outcome to a `fail` index, `status`, `code`, and `reason`. `pick(k)` colours the rows green up to the last that ran, burgundy at the failing step, dim/`skipped` after it.
- Readout strings (VERBATIM):
  - Static default markup: `ptStatus` `200 OK · lesson rendered`; `ptRole` `nothing — all pass`; `ptResult` `200`.
  - Scenario statuses: `200 OK · lesson rendered`, `400 Bad Request`, `401 Unauthorized`, `404 Not Found`, `403 Forbidden`.
  - Row tags: per-step `ok`/`err` tuple followed by ` ✓` (passed) or ` ✗` (failed), or `skipped`.
  - `ptRole`: `nothing — all pass`, else `<step name> (<reason>)`.
  - Readout `ptOut` (all pass): `All four gates pass, so the with reaches its body and renders the lesson — 200 OK.`
  - Readout `ptOut` (a failure): `The chain reaches <step name>, which returns <err tuple>. It bails to the else, the clause for <reason> maps it to <status>, and the steps below it are skipped.`
- Take (verbatim): `The happy path is the body; everything that can fail is named once and handled once. The reader sees the four preconditions in order, not a staircase of nested branches.`

### Bridge

`nested cases` (A pyramid that drifts right with every precondition.) → `a with chain` (A flat happy path; one `else` maps each tagged error to a status.).

### Footer build-stamp decoder

- `id="stamp"` keyboard-activatable; `id="stampId"` text `TSK0NcdRbcf98q`.
- Decodes namespace `TSK`, snowflake, node, seq, timestamp via the B62 / epoch `1704067200000` decoder; markup pre-decoded timestamp dd `2026-06-01 10:46:37 UTC`.

## References (#refs, verbatim)

Intro line: `Primary sources for this lesson, and where it connects in the course.`

Sources:
- Elixir — `with/1` — the chaining special form and its `else`. — `https://hexdocs.pm/elixir/Kernel.SpecialForms.html#with/1`
- Elixir — case, cond, and if — the nested branches `with` flattens. — `https://hexdocs.pm/elixir/case-cond-and-if.html`
- Elixir — Pattern matching — matching tagged tuples in heads and clauses. — `https://hexdocs.pm/elixir/pattern-matching.html`

Related in this course:
- `/elixir/algorithms/recipes` — F4.10 · Practical recipes in Elixir — the module hub.
- `/elixir/algorithms/persistence` — F4.08 · Branded ids & persistence — the edge validation that is the chain's first step.
- `/elixir/algorithms` — F4 · Algorithms & Data Structures

## Wiring

- route-tag (verbatim): `/` `elixir` `/` `algorithms` `/` `recipes` `/` `patterns` (`patterns` is `.rcur`; `elixir` → `/elixir`, `algorithms` → `/elixir/algorithms`, `recipes` → `/elixir/algorithms/recipes`).
- crumbs (verbatim): `F4` (→ `/elixir/algorithms`) / `F4.10` (→ `/elixir/algorithms/recipes`) / `patterns` (here).
- toc-mini: `#chain` → `Where the chain stops`; `#advanced` → `Advanced: one else, tagged errors`.
- pager: prev → `/elixir/algorithms/recipes` label `F4.10 · recipes`; next → `/elixir/algorithms/recipes/pipelines` label `Next · streams & pipelines`.
- footer: column **Chapters** — `/elixir/algebra` F1 · Algebra, `/elixir/functional` F2 · Functional Programming, `/elixir/language` F3 · The Elixir Language, `/elixir/algorithms` F4 · Algorithms & Data Structures, `/elixir/pragmatic` F5 · Pragmatic Programming, `/elixir/phoenix` F6 · Phoenix Framework. Column **The course** — `/elixir` Course home, `/elixir/course` Contents & history, `/elixir/algebra/functions` Start · F1.01. Foot-tag: `Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir.`
- Page meta:
  - `<title>`: `Idiomatic patterns — F4.10.1 · jonnify`
  - `<meta description>`: `A request to view a lesson clears four gates — validate the id, authenticate the caller, fetch the lesson, authorize access — then renders. Written as a with chain it is four lines that bind the happy path while every failure falls through to one else that maps a tagged error ({:error, :bad_id}, :unauthenticated, :not_found, :forbidden) to a status, and the steps after a failure never run.`

## Build instruction

To rebuild this dive, copy the `<head>…</style>`, `header`, `footer`, and trailing `<script>` blocks verbatim from a recent built sibling on the sage F4 accent — copy from the chapter-mate dive `/elixir/algorithms/recipes/pipelines` (`/Users/jonny/dev/jonnify/elixir/algorithms/recipes/pipelines.html`), which shares this dive's exact anatomy (hero lede, one teaching `.fig` + one advanced section, bridge, refs, pager). Change only `<title>`/`<meta>`, the `route-tag`, and the `<main>` body. No-invent guards: use only the real Portal surfaces as written — `Portal.Id.validate/2`, `Auth.current_user/1`, `Catalog.fetch_lesson/1`, `Catalog.authorize/2`, the branded store, the event-sourced engine behind one Portal facade, the Phoenix web app; cite the companion course for OTP internals, do not re-teach them; do not invent ids, routes, readout strings, status codes, or reference URLs beyond those above. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously.
