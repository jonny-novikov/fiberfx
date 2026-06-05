# F5.02.3 — A context's public API (dive)

- Route (served): `/elixir/pragmatic/domain/api`
- File: `elixir/pragmatic/domain/api.html`
- Place in the chapter: the third and closing dive of F5.02, building the top layer of the domain model — the public surface. It puts a small API over the structs (F5.02.1) and contexts (F5.02.2), closing the data → boundary → interface arc; the next module, F5.03 — Tracer bullets, drives one use case through this model end to end.
- Accent: burgundy (the F5 · Pragmatic Programming chapter accent).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `F5.02 · part 3 of 3`

Kicker (after the lede): "The public functions of the Learning context, and what each one promises. Select a function to see its shape."

Hero lede (verbatim):

> A context is only as decoupled as its surface is small. Each one exposes a handful of **public functions** — a smart constructor that validates and returns `{:ok, struct}` or `{:error, reason}`, a command or two, a query — and keeps its structs, validations, and helpers `defp`-private. Callers depend on the API, not the data, so the context can rearrange its internals freely. This is the contract every caller leans on: the thin server today, Phoenix in F6, and the tests in between.

## Sections

In order:

1. `#surface` — **Public surface, private core** (teaching section): everything above the line is callable, everything below it is not. A command returns a tagged result so the caller can branch; a query returns data with no side effects; a smart constructor refuses to build an invalid entity. Carries the interactive figure.
2. `#code` — **In code**: the public functions carry `@spec`s and return tagged tuples; the smart constructor runs validation through a `with` chain then builds the struct; the validation itself is `defp`. A `.bridge` (a small surface → a hidden core) and a closing `.note` that ends F5.02 and points to F5.03.

Running example: the `Portal.Learning` context's public API — `enroll/2`, `record_progress/2`, `courses_of/1` — over a private core of `%Enrollment{}` / `%Progress{}` and `defp validate_ids/2`.

Real Elixir code shown (the `#code` block): `defmodule Portal.Learning` with `alias Portal.Learning.Enrollment`; `@spec enroll(String.t(), String.t()) :: {:ok, Enrollment.t()} | {:error, atom()}` and `def enroll(user_id, course_id)` using a `with :ok <- validate_ids(user_id, course_id)` chain that returns `{:ok, %Enrollment{id: Portal.ID.new("ENR"), user_id: user_id, course_id: course_id}}`; `@spec courses_of(String.t()) :: [Enrollment.t()]` and `def courses_of(user_id), do: # a query — no side effects`; and the private `defp validate_ids("USR" <> _ = _u, "CRS" <> _ = _c), do: :ok` / `defp validate_ids(_, _), do: {:error, :bad_reference}`.

## The interactives

### Section figure — "The Learning API · select a function"

`<figure class="fig">` labelled by `#apTitle`. Control group `#apSel` (`role="group"`, `aria-label="API function"`) with three buttons:

- `data-k="enroll"` — label `enroll/2` (active by default)
- `data-k="progress"` — label `record_progress/2`
- `data-k="courses"` — label `courses_of/1`

SVG element ids (the highlighted public-function chips over a private-core panel): `#apFn_enroll`, `#apFn_progress`, `#apFn_courses`. Below the `public ↑ / private ↓` dashed line the static PRIVATE CORE band shows `%Enrollment{} · %Progress{}` and `defp validate_ids/2 · helpers`.

Pure function `pick(k)`: looks up the `FNS` table, toggles the active button + chip stroke/fill, and writes `#apRole` (function name), `#apResult` (its kind), and `#apOut` (readout). `pick('enroll')` runs on load.

Readout `#apOut` composed as: "<b>{name}</b> — a {kind}. {desc}". The `FNS` table values VERBATIM:

- `enroll`: name "enroll/2", kind "command (constructor)", desc "Validates the input, then builds the struct: `enroll(user_id, course_id)` returns `{:ok, %Enrollment{}}` or `{:error, reason}`. A smart constructor — no invalid Enrollment ever leaves it."
- `progress`: name "record_progress/2", kind "command", desc "Advances a learner: `record_progress(enrollment_id, lesson_id)` returns `{:ok, %Progress{}}` or an error. It changes the world and reports what changed."
- `courses`: name "courses_of/1", kind "query", desc "Reads without changing: `courses_of(user_id)` returns the learner's enrollments. No side effects — the read side of the context."

Static labels under the figure: `function: enroll/2` (`#apRole`) and `kind: command (constructor)` (`#apResult`).

Note: this dive carries one interactive figure and one in-code listing; it does not have a second standalone SVG diagram. Degrade: content is visible without JS; the `.reveal` sections show fully under `prefers-reduced-motion: reduce` or without `IntersectionObserver`.

### Build-stamp decoder

Footer stamp `#stamp` carries id `TSK0Ncs2SnpPo8` (`#stampId`). `decodeBranded` (base62, `EPOCH_MS = 1704067200000`) splits namespace `TSK` and decodes snowflake/node/seq; displayed `#st-ts` is `2026-06-01 14:10:51 UTC`.

## References (#refs, verbatim)

Intro line: "Primary sources for this lesson, and where it connects in the course."

Sources:
- `https://hexdocs.pm/ex_unit/ExUnit.html` — `ExUnit` — Elixir documentation — the test framework that exercises a context's API.
- `https://hexdocs.pm/ex_unit/ExUnit.DocTest.html` — `ExUnit.DocTest` — Elixir documentation — tests built from documentation examples.

Related in this course:
- `/elixir/pragmatic/domain` — F5.02 · Modeling the Portal domain
- `/elixir/pragmatic/domain/contexts` — Contexts as boundaries
- `/elixir/pragmatic/tracer-bullets` — F5.03 · Tracer bullets

## Wiring

- route-tag (verbatim): `/ elixir / pragmatic / domain / api` — `elixir`, `pragmatic`, `domain` are links; `api` is the current segment (`.rcur`).
- crumbs (verbatim): `F5` (links `/elixir/pragmatic`) / `F5.02` (links `/elixir/pragmatic/domain`) / `api` (`.here`).
- toc-mini: `#surface` "Public surface, private core"; `#code` "In code".
- pager: prev → `/elixir/pragmatic/domain/contexts` label "F5.02.2 · contexts"; next → `/elixir/pragmatic/domain` label "Back to F5.02".
- footer: column "Chapters" → `/elixir/algebra`, `/elixir/functional`, `/elixir/language`, `/elixir/algorithms`, `/elixir/pragmatic`, `/elixir/phoenix`. Column "The course" → `/elixir`, `/elixir/course`, `/elixir/algebra/functions`.
- Page meta: `<title>` is `A context's public API — F5.02.3 · jonnify`; `<meta name="description">` is "Each context exposes a small set of public functions — a smart constructor that validates and returns {:ok, struct} or {:error, reason}, a command, a query — and keeps its structs and helpers private. The API is the contract every caller depends on, from the thin server today to Phoenix in F6."

## Build instruction

To (re)build this page, copy the `<head>…</style>`, `header.site`, `footer.site-foot`, and the two trailing `<script>` blocks (the interactive `pick()`/`FNS` shell + Snowflake decoder, and the reveal enhancer) verbatim from a recent BUILT sibling on this burgundy F5 accent — the closest model is the companion dive `elixir/pragmatic/domain/contexts.html` (same dive anatomy: hero lede, a `select-a-function` figure, an `#code` listing, `.bridge`, `#refs`, pager). Change only `<title>`/`<meta>`, the route-tag's current segment, and the `<main>` body. No-invent guards: use only the real Portal surfaces as written — the branded store (`Portal.ID.new("ENR")`, the `USR`/`CRS`/`ENR` namespaces), the `Portal.Learning` API `enroll/2`/`record_progress/2`/`courses_of/1`, the private `validate_ids/2`, the event-sourced engine behind ONE `Portal` facade, and Phoenix in F6; cite the companion course for OTP internals rather than re-teaching, and do not invent new public functions, change arities, or alter the tagged-tuple return contracts. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously.
