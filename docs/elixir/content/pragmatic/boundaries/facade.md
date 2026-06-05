# F5.08.2 — The engine facade (dive)

- Route (served): `/elixir/pragmatic/boundaries/facade`
- File: `elixir/pragmatic/boundaries/facade.html`
- Place in the chapter: the second dive of module F5.08 · Boundaries & integration seams. It builds the *driving* port — the single `Portal` context module the UI calls — after F5.08.1 builds the driven port (ports & adapters) and before F5.08.3 turns the `to_contract/1` translation step into a closed error vocabulary.
- Accent: burgundy (the F5 · Pragmatic Programming chapter accent).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `F5.08 · part 2 of 3`

Title: The engine facade

Hero lede (verbatim):

> If ports are how the engine reaches the outside, the facade is how the outside reaches the engine — the **driving port**. It is a single context module, `Portal`, whose functions read like the domain rather than the runtime: `enroll/2`, `deliver_lesson/2`, `progress_of/1`. A caller never writes `GenServer.call(Portal.Engine, {:command, {:enroll, …}})`; it writes `Portal.enroll(user_id, course_id)`. Everything behind that door — the GenServer from F5.06, the event log, the reducer — is free to change without touching a caller. The facade also keeps the command/query split from F5.05 visible in its signatures: commands return `:ok` or a typed error, queries return data. It is small on purpose; a boundary earns its keep by being narrow.

Kicker (verbatim):

> Three functions, one door. Select one to see its signature and the call it makes underneath.

## Sections

In order:

1. `#door` — **One small surface** — a facade function names an intention and hides a mechanism; the surface stays the same whether the engine is one process or a pool. Carries the first interactive figure.
2. `#code` — **The facade in code** — the `Portal` module of typed functions delegating to `Engine.command/1` / `Engine.query/1`, with `@spec`s that keep the CQS split in the public type. Real code: the `Portal` facade module and the `Portal.Engine` helper module (the only place `GenServer.call` and `to_contract/1` appear).
3. `#flow` — **An enroll, end to end** — one synchronous call crosses the boundary, runs the engine, and returns `:ok` or a typed error. Carries the second (static) flow figure.
4. `#why` — **Why a facade, not the GenServer** — calling the GenServer directly pins callers to three private facts (it is a process, the message tuples, the raw replies); a facade buys back all three. A `.bridge` two-cell.

Running example: the `Portal` facade for the event-sourced engine — `enroll/2` and `deliver_lesson/2` (commands) and `progress_of/1` (query), routed through `Portal.Engine.command/1` and `Portal.Engine.query/1`.

Real Elixir shown: the `Portal` module (`@moduledoc`, `alias Portal.{Engine, Error}`, three `@spec`'d functions); the `Portal.Engine` module with `command/1`, `query/1`, and the private `to_contract/1` clauses mapping internal replies to the boundary contract (`{:error, reason} -> {:error, Portal.Error.from(reason)}`).

## The interactives

Two figures (one interactive, one static).

### Figure — "The facade surface · select a function"
- `<figure class="fig">`, `aria-labelledby="fcTitle"`, heading id `fcTitle` reading `The facade surface · select a function`.
- Control group `id="fcSel"` (`role="group"`, `aria-label="Facade function"`), three buttons by `data-k`: `enroll` (`enroll/2`, active by default), `deliver` (`deliver_lesson/2`), `progress` (`progress_of/1`).
- SVG rows toggled: `id="fcRow_enroll"`, `id="fcRow_deliver"`, `id="fcRow_progress"`.
- Readout `id="fcOut"` (`aria-live="polite"`); role label `id="fcRole"` (default `enroll/2`) and `id="fcResult"` (default `a command that returns :ok or an error`).
- Pure function `pick(k)` reads the `FCNS` table and writes role, kind, and the `fcOut` sentence. Function descriptions (verbatim from `FCNS`):
  - `enroll` — name `enroll/2`, kind `a command that returns :ok or an error`, desc: `A command. It names the intent to put a learner on a course and delegates to Engine.command, which runs the F5.04 contract and the F5.05 fold behind the door. The caller sees :ok or a typed error, never a read model.`
  - `deliver` — name `deliver_lesson/2`, kind `a command that returns :ok or an error`, desc: `A command. It records that a lesson was delivered for an enrollment. Same shape as enroll: it changes state and reports only success or a typed error, keeping the command side of CQS honest at the boundary.`
  - `progress` — name `progress_of/1`, kind `a query that returns the percent`, desc: `A query. It reads an enrollment’s progress and returns {:ok, percent} without changing anything. Because it is a read, it is safe to call repeatedly — the query half of CQS, surfaced on the facade.`
- `fcOut` template (verbatim): `<b>...name...</b> — ...kind.... ...desc`.

### Figure — "enroll, across the boundary"
- `<figure class="fig">`, `aria-labelledby="fcFlowTitle"`, heading id `fcFlowTitle` reading `enroll, across the boundary`.
- Static four-hop SVG (no controls): `UI · LiveView` (`Portal.enroll(u, c)`) → `FACADE` (`Engine.command(...)`) → `ENGINE · call` (`decide · evolve · reply`) → `RESULT` (`:ok | {:error, %Error{}}`). Footer text: `one synchronous call; the UI waits for :ok or a typed error, nothing else`.

### Footer build-stamp
- `id="stampId"` text: `TSK0Nd7nZlWtBg`. Static panel timestamp: `2026-06-01 17:51:23 UTC`. The branded-Snowflake decoder (namespace `TSK`, epoch `1704067200000`) decodes the id to that UTC timestamp on activation.

Degrade behaviour: SVG rows and labels are present in static markup; `pick('enroll')` runs on load to populate the live readout; the `.reveal` references section is shown without JS, with the reveal-on-scroll transition disabled under `prefers-reduced-motion: reduce`.

## References (#refs, verbatim)

Intro line: `Primary sources for this lesson, and where it connects in the course.`

Sources:
- `Alistair Cockburn — Hexagonal architecture` — https://alistair.cockburn.us/hexagonal-architecture/ — ports and adapters around a core.
- `Elixir — Typespecs and behaviours` — https://hexdocs.pm/elixir/typespecs.html — @callback defines the port contract.
- `José Valim — Mocks and explicit contracts` — https://dashbit.co/blog/mocks-and-explicit-contracts — test seams without mutating globals.

Related in this course:
- `/elixir/pragmatic/boundaries` — F5.08 · Boundaries & integration seams
- `/elixir/pragmatic/boundaries/ports` — Ports — the driven seam
- `/elixir/pragmatic/boundaries/errors` — Error contracts for the UI

## Wiring

- route-tag (verbatim): `/ ` `elixir` `/ ` `pragmatic` `/ ` `boundaries` `/ ` current `facade`.
- crumbs (verbatim): `F5` (`/elixir/pragmatic`) `/` `F5.08` (`/elixir/pragmatic/boundaries`) `/` `facade` (here).
- toc-mini: `#door` → `One small surface`; `#code` → `The facade in code`; `#flow` → `An enroll, end to end`; `#why` → `Why a facade, not the GenServer`.
- pager: prev → `/elixir/pragmatic/boundaries/ports` label `F5.08.1 · ports`; next → `/elixir/pragmatic/boundaries/errors` label `Next · error contracts`.
- footer: identical to the module hub — `Chapters` column links to `/elixir/algebra`, `/elixir/functional`, `/elixir/language`, `/elixir/algorithms`, `/elixir/pragmatic`, `/elixir/phoenix`; `The course` column links to `/elixir`, `/elixir/course`, `/elixir/algebra/functions`.
- Page meta:
  - `<title>`: `The engine facade — F5.08.2 · jonnify`
  - `<meta name="description">`: `The driving port: a small context module — enroll/2, deliver_lesson/2, progress_of/1 — that names intentions and hides the GenServer, the event log, and the reducer. It keeps the command/query split in its specs and is the only place GenServer.call appears, so the runtime can change without touching callers.`

## Build instruction

To rebuild this page, copy the `head`…`</style>`, the `header`, the `footer`, and the two trailing `<script>` blocks verbatim from a recent built sibling on the burgundy F5 accent — the model sibling is `elixir/pragmatic/boundaries/ports.html` (the immediately preceding dive in the same module, identical head and lesson-page lede styling); change only `<title>`/`<meta description>`, the `route-tag`, and the `<main>` body. This is a dive: keep the lesson hero (`.hero` with `.crumbs`, `.eyebrow`, `h1`, `.lede`, `.kicker`, `.toc-mini`), four teaching sections, two `.fig` figures (one with the `solid-select` interactive shell, one static flow), real `pre.code` Portal listings, the `.bridge`, and the `.reveal` `#refs` block. Respect the no-invent guards: use only the real Portal surfaces as written — `Portal` as the one facade with `enroll/2`/`deliver_lesson/2`/`progress_of/1`, `Portal.Engine.command/1`/`query/1` as the only `GenServer.call` site, and `Portal.Error.from/1` as the contract translation; cite the companion course for OTP internals (`GenServer`) and do not re-teach them. Voice rules: no first person, no exclamation marks, no emoji, and none of just / simply / obviously.
