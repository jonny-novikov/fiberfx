# F5.08.3 — Error contracts for the UI (dive)

- Route (served): `/elixir/pragmatic/boundaries/errors`
- File: `elixir/pragmatic/boundaries/errors.html`
- Place in the chapter: the third and final dive of module F5.08 · Boundaries & integration seams. After F5.08.1 builds the driven port and F5.08.2 builds the facade, this dive makes failure part of the contract — a closed set of `%Portal.Error{}` codes mapped at the boundary — turning the `to_contract/1` step from the facade into a finite, renderable error vocabulary. It closes F5.08 and hands off to F5.09 · the engine lab.
- Accent: burgundy (the F5 · Pragmatic Programming chapter accent).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `F5.08 · part 3 of 3`

Title: Error contracts for the UI

Hero lede (verbatim):

> A boundary that hands the UI a raw exception, an Ecto changeset, or the engine's internal reason has not finished the job. The UI then has to know the internals to render a message, and the coupling the facade removed comes back in through the error path. The fix is to make failure part of the contract: a closed set of typed errors — `%Portal.Error{}` with a `code` drawn from a fixed union — that the boundary produces and the UI renders. This is where the tagged tuples of F5.04 grow up: an expected failure becomes a named code with a human message; an *impossible* state stays a crash, caught by the supervisor from F5.06, because a bug is not an error contract. The UI is left with a finite list of outcomes it can render exhaustively.

Kicker (verbatim):

> Three failures, three rendered shapes. Select a case to see its internal cause and what the UI receives.

## Sections

In order:

1. `#closed` — **A closed set of outcomes** — a fixed union of codes makes the UI's rendering *total*; each code pairs an internal cause with a readable message. Carries the first interactive figure.
2. `#struct` — **The Error struct** — `Portal.Error` with a `code` union type, a `message`, and an optional `field`; the union is the closed set. Real code: the `Portal.Error` struct.
3. `#translate` — **Translating at the boundary** — `Error.from/1` with one clause per known domain failure and *no catch-all*; an unmodelled reason raises `FunctionClauseError`. Real code: the `from/1` clauses; carries the second (static) flow figure.
4. `#tested` — **Errors as part of the contract** — the closed union lets the LiveView branch exhaustively in one total `case`; adding a failure is a three-part move (new code, new `from/1` clause, new UI branch). Real code: the LiveView `case Portal.enroll(...)`. A `.bridge` two-cell and the closing `.note` pointing to F5.09.

Running example: the three boundary failures of the Portal engine — `already_enrolled`, `course_not_found`, `invalid_progress` — mapped from internal reasons to `%Portal.Error{}` and rendered by the F6 LiveView.

Real Elixir shown: the `Portal.Error` struct (`@type code`, `@type t`, `@enforce_keys`, `defstruct`); the `Portal.Error.from/1` clauses (`:already_enrolled`, `:course_not_found`, `{:invalid_progress, _value}`, with no catch-all); the LiveView `case` matching `:ok`, `%Portal.Error{field: nil}`, and `%Portal.Error{field: field}`.

## The interactives

Two figures (one interactive, one static).

### Figure — "Error case · select one"
- `<figure class="fig">`, `aria-labelledby="erTitle"`, heading id `erTitle` reading `Error case · select one`.
- Control group `id="erSel"` (`role="group"`, `aria-label="Error case"`), three buttons by `data-k`: `enrolled` (`already_enrolled`, active by default), `notfound` (`course_not_found`), `progress` (`invalid_progress`).
- SVG rows toggled: `id="erRow_enrolled"`, `id="erRow_notfound"`, `id="erRow_progress"`. Each row pairs a code, a UI message, and an HTTP-style status (`409 conflict`, `404 not found`, `422 · field`).
- Readout `id="erOut"` (`aria-live="polite"`); role label `id="erRole"` (default `already_enrolled`) and `id="erResult"` (default `you are already on this course`).
- Pure function `pick(k)` reads the `ERRS` table and writes code, message, and the `erOut` sentence. Error descriptions (verbatim from `ERRS`):
  - `enrolled` — code `already_enrolled`, message `you are already on this course`, desc: `The engine’s decide returned {:error, :already_enrolled} when a learner tried to join a course twice. The boundary maps it to a 409-style conflict the UI shows as a flash.`
  - `notfound` — code `course_not_found`, message `we could not find that course`, desc: `A lookup missed: the course id does not exist. The boundary maps it to a 404-style code so the UI can show a not-found message rather than a stack trace.`
  - `progress` — code `invalid_progress`, message `progress must be between 0 and 100`, desc: `The F5.04 precondition rejected a progress value outside 0..100. The error carries a field, so the UI can attach the message to the form input rather than a page-level flash.`
- `erOut` template (verbatim): `<b>:...code...</b> — the UI shows “...message...”. ...desc`.

### Figure — "From reason to render"
- `<figure class="fig">`, `aria-labelledby="erFlowTitle"`, heading id `erFlowTitle` reading `From reason to render`.
- Static three-step SVG (no controls): `INTERNAL` (`{:error, reason}`) → `Error.from/1` → `CONTRACT` (`%Portal.Error{}`) → `render` → `UI` (`flash / field error`). Footer text: `every reason maps to a code, or it raises — nothing reaches the UI unnamed`.

### Footer build-stamp
- `id="stampId"` text: `TSK0Nd7na0I1x2`. Static panel timestamp: `2026-06-01 17:51:23 UTC`. The branded-Snowflake decoder (namespace `TSK`, epoch `1704067200000`) decodes the id to that UTC timestamp on activation.

Degrade behaviour: SVG rows and labels are present in static markup; `pick('enrolled')` runs on load to populate the live readout; the `.reveal` references section is shown without JS, with the reveal-on-scroll transition disabled under `prefers-reduced-motion: reduce`.

## References (#refs, verbatim)

Intro line: `Primary sources for this lesson, and where it connects in the course.`

Sources:
- `Alistair Cockburn — Hexagonal architecture` — https://alistair.cockburn.us/hexagonal-architecture/ — ports and adapters around a core.
- `Elixir — Typespecs and behaviours` — https://hexdocs.pm/elixir/typespecs.html — @callback defines the port contract.
- `José Valim — Mocks and explicit contracts` — https://dashbit.co/blog/mocks-and-explicit-contracts — test seams without mutating globals.

Related in this course:
- `/elixir/pragmatic/boundaries/facade` — F5.08.2 · The facade as the one door
- `/elixir/pragmatic/contracts/fail-fast` — F5.04 · Fail fast — tagged tuples for expected failure
- `/elixir/pragmatic/testing/contract-tests` — F5.07 · Contract tests for each error code

## Wiring

- route-tag (verbatim): `/ ` `elixir` `/ ` `pragmatic` `/ ` `boundaries` `/ ` current `errors`.
- crumbs (verbatim): `F5` (`/elixir/pragmatic`) `/` `F5.08` (`/elixir/pragmatic/boundaries`) `/` `errors` (here).
- toc-mini: `#closed` → `A closed set of outcomes`; `#struct` → `The Error struct`; `#translate` → `Translating at the boundary`; `#tested` → `Errors as part of the contract`.
- pager: prev → `/elixir/pragmatic/boundaries/facade` label `F5.08.2 · facade`; next → `/elixir/pragmatic/boundaries` label `Back to F5.08`.
- footer: identical to the module hub — `Chapters` column links to `/elixir/algebra`, `/elixir/functional`, `/elixir/language`, `/elixir/algorithms`, `/elixir/pragmatic`, `/elixir/phoenix`; `The course` column links to `/elixir`, `/elixir/course`, `/elixir/algebra/functions`.
- Page meta:
  - `<title>`: `Error contracts for the UI — F5.08.3 · jonnify`
  - `<meta name="description">`: `Failure is part of the contract: a closed set of %Portal.Error{} codes, mapped from internal reasons at the boundary, so the UI renders a finite list of outcomes exhaustively. Expected failures become typed errors; impossible states stay crashes for the supervisor, and an unmodelled reason raises rather than leaking.`

## Build instruction

To rebuild this page, copy the `head`…`</style>`, the `header`, the `footer`, and the two trailing `<script>` blocks verbatim from a recent built sibling on the burgundy F5 accent — the model sibling is `elixir/pragmatic/boundaries/facade.html` (the immediately preceding dive in the same module, identical head and lesson-page lede styling); change only `<title>`/`<meta description>`, the `route-tag`, and the `<main>` body. This is a dive: keep the lesson hero (`.hero` with `.crumbs`, `.eyebrow`, `h1`, `.lede`, `.kicker`, `.toc-mini`), four teaching sections, two `.fig` figures (one with the `solid-select` interactive shell, one static flow), real `pre.code` Portal listings, the `.bridge`, and the `.reveal` `#refs` block. Respect the no-invent guards: use only the real Portal surfaces as written — `Portal.Error` as the closed code union, `Portal.Error.from/1` as the boundary translation with no catch-all, and the `case Portal.enroll(...)` LiveView branch; cite the companion course for OTP internals (the supervisor from F5.06) and do not re-teach them. Voice rules: no first person, no exclamation marks, no emoji, and none of just / simply / obviously.
