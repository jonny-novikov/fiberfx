# F5.08.1 — Ports & adapters (dive)

- Route (served): `/elixir/pragmatic/boundaries/ports`
- File: `elixir/pragmatic/boundaries/ports.html`
- Place in the chapter: the first dive of module F5.08 · Boundaries & integration seams. It builds the *driven* seam — the engine's event-store port as a `@behaviour`, two interchangeable adapters, and the dependency arrow pointing inward — before F5.08.2 builds the driving port (the facade) and F5.08.3 builds the error contract.
- Accent: burgundy (the F5 · Pragmatic Programming chapter accent).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `F5.08 · part 1 of 3`

Title: Ports & adapters

Hero lede (verbatim):

> The engine has to persist its event log somewhere — Postgres in production, something throwaway in a test. The wrong way to allow that is a conditional buried in the core (`if Mix.env() == :test`); the right way is the move at the heart of Cockburn's hexagonal architecture: the core declares **what it needs** as an interface — a **port** — and the outside world supplies an **adapter** that satisfies it. In Elixir the port is a `@behaviour` with typespecs, and an adapter is a module that carries `@behaviour Portal.EventStore` and implements the callbacks. The core depends on the behaviour; the adapters depend on the behaviour; configuration decides which adapter is loaded. This is the "explicit contracts" approach José Valim argues for over ad-hoc mocking: the behaviour *is* the contract, so the test adapter and the production adapter are interchangeable by construction.

Kicker (verbatim):

> One contract, two implementations. Select a piece to see what it is and where it runs.

## Sections

In order:

1. `#seam` — **Driven and driving ports** — the two kinds of port and their symmetry; the event store is a driven (secondary) port. Carries the first interactive figure.
2. `#behaviour` — **The port is a behaviour** — `@callback` specs checked at compile time, a thin resolver reading the adapter from config. Real code: `Portal.EventStore` (with `append/2`, `read_stream/1`, `adapter/0`) plus the two config lines.
3. `#adapters` — **Two adapters, one contract** — `Portal.EventStore.InMemory` (Agent-backed) and `Portal.EventStore.Postgres` (Ecto-backed), each carrying `@behaviour Portal.EventStore`. Carries the dependency-direction figure.
4. `#inward` — **Which way the arrows point** — dependency inversion drawn literally; not everything deserves a port (reach for one at a real seam: I/O, time, an external service). A `.bridge` two-cell.
5. `#stubTitle` (`.reveal`) — advanced section **A test double is a module, not a mutated global** — the "mock is a noun, not a verb" point; a third adapter `Portal.EventStore.Stub` selected by config, with its own interactive comparison figure. Real code: the stub module and the `config :portal, :event_store, Portal.EventStore.Stub` line with a call site using `Portal.Events.LearnerEnrolled`.

Running example: the Portal engine's event-store port — one event-store contract resolved by config to `InMemory` (dev/test), `Postgres` (production), or a hand-written `Stub` (a single failing-store test).

Real Elixir shown: the `Portal.EventStore` behaviour module; the production and test `config` lines; the `InMemory` adapter (`use Agent`, `start_link/1`, `append/2`, `read_stream/1`); the `Postgres` adapter (`import Ecto.Query`, `Repo.insert_all`, an `Ecto.Query` `from`); the `Portal.EventStore.Stub` test adapter returning `{:error, :store_unavailable}` and `{:ok, []}`.

## The interactives

Two interactive figures.

### Figure — "The event-store seam · select a piece"
- `<figure class="fig">`, `aria-labelledby="paTitle"`, heading id `paTitle` reading `The event-store seam · select a piece`.
- Control group `id="paSel"` (`role="group"`, `aria-label="Event-store piece"`), three buttons by `data-k`: `port` (`the port`, active by default), `memory` (`InMemory`), `postgres` (`Postgres`).
- SVG rows toggled: `id="paRow_port"`, `id="paRow_memory"`, `id="paRow_postgres"`.
- Readout `id="paOut"` (`aria-live="polite"`); role label `id="paRole"` (default `EventStore`) and `id="paResult"` (default `the behaviour the core calls`).
- Pure function `pick(k)` reads the `PIECES` table and writes role, detail, and the `paOut` sentence. Piece descriptions (verbatim from `PIECES`):
  - `port` — name `EventStore`, detail `the behaviour the core calls`, desc: `The port itself: two callbacks, append/2 and read_stream/1, declared with typespecs. The core calls these through a thin resolver and never names a concrete store — the contract is all it knows.`
  - `memory` — name `InMemory`, detail `an Agent table, for dev and tests`, desc: `An adapter that keeps streams in a map inside an Agent. Fast and disposable, it is the store the F5.07 example and property tests run against — no database to seed, set by one config line.`
  - `postgres` — name `Postgres`, detail `an Ecto adapter, for production`, desc: `An adapter that writes events as rows through Ecto and reads a stream back in sequence order. It satisfies the same behaviour as InMemory, so the core code is identical in production and in tests.`
- `paOut` template (verbatim): `<b>...</b> — ...detail.... ...desc`.

### Figure — "Dependency direction"
- `<figure class="fig">`, `aria-labelledby="paDirTitle"`, heading id `paDirTitle` reading `Dependency direction`.
- Static SVG (no controls): three boxes — `ENGINE CORE` / `calls the port`, `PORT` / `@behaviour EventStore` (burgundy), `ADAPTER` / `InMemory · Postgres` — with arrows labelled `depends on` and `implements`, both pointing at the behaviour. Footer text: `dependencies point at the behaviour, never at an adapter`. A `.take` follows inside the figure.

### Figure — "Mock the verb, or define the mock as a noun"
- `<figure class="fig">`, `aria-labelledby="stubFigTitle"`, heading id `stubFigTitle` reading `Mock the verb, or define the mock as a noun`.
- Static comparison SVG (no controls): left column `VERB · mutate a shared global` (`redefine InMemory.append/2 at runtime`, `every test shares it · cannot run concurrently`); right column `NOUN · a module that conforms` (`@behaviour Portal.EventStore`, `a separate Stub · config selects it · concurrent-safe`).

### Footer build-stamp
- `id="stampId"` text: `TSK0Nd7nZWlkQK`. Static panel timestamp: `2026-06-01 17:51:23 UTC`. The branded-Snowflake decoder (namespace `TSK`, epoch `1704067200000`) decodes the id to that UTC timestamp on activation.

Degrade behaviour: the SVG rows and labels are all present in static markup; `pick('port')` runs on load to populate the live readout; the `.reveal` advanced section is shown without JS (the reveal-on-scroll only adds an entry transition, and is disabled under `prefers-reduced-motion: reduce`).

## References (#refs, verbatim)

Intro line: `Primary sources for this lesson, and where it connects in the course.`

Sources:
- `Alistair Cockburn — Hexagonal architecture` — https://alistair.cockburn.us/hexagonal-architecture/ — ports and adapters around a core.
- `Elixir — Typespecs and behaviours` — https://hexdocs.pm/elixir/typespecs.html — @callback defines the port contract.
- `José Valim — Mocks and explicit contracts` — https://dashbit.co/blog/mocks-and-explicit-contracts — test seams without mutating globals.

Related in this course:
- `/elixir/pragmatic/boundaries` — F5.08 · Boundaries & integration seams
- `/elixir/pragmatic/boundaries/facade` — The engine facade — the driving port
- `/elixir/pragmatic/testing` — F5.07 · Pragmatic testing

## Wiring

- route-tag (verbatim): `/ ` `elixir` `/ ` `pragmatic` `/ ` `boundaries` `/ ` current `ports`.
- crumbs (verbatim): `F5` (`/elixir/pragmatic`) `/` `F5.08` (`/elixir/pragmatic/boundaries`) `/` `ports` (here).
- toc-mini: `#seam` → `Driven and driving ports`; `#behaviour` → `The port is a behaviour`; `#adapters` → `Two adapters, one contract`; `#inward` → `Which way the arrows point`.
- pager: prev → `/elixir/pragmatic/boundaries` label `F5.08 · boundaries`; next → `/elixir/pragmatic/boundaries/facade` label `Next · the engine facade`.
- footer: identical to the module hub — `Chapters` column links to `/elixir/algebra`, `/elixir/functional`, `/elixir/language`, `/elixir/algorithms`, `/elixir/pragmatic`, `/elixir/phoenix`; `The course` column links to `/elixir`, `/elixir/course`, `/elixir/algebra/functions`.
- Page meta:
  - `<title>`: `Ports & adapters — F5.08.1 · jonnify`
  - `<meta name="description">`: `A port is an Elixir behaviour the core depends on; an adapter is a module that implements it; configuration decides which adapter is loaded. One EventStore contract, an in-memory adapter for dev and tests and an Ecto adapter for production, and a dependency arrow that points inward at the behaviour, never at an adapter.`

## Build instruction

To rebuild this page, copy the `head`…`</style>`, the `header`, the `footer`, and the two trailing `<script>` blocks verbatim from a recent built sibling on the burgundy F5 accent — the model sibling is `elixir/pragmatic/boundaries/facade.html` (a peer dive in the same module, identical head and lesson-page lede styling); change only `<title>`/`<meta description>`, the `route-tag`, and the `<main>` body. This is a dive: keep the lesson hero (`.hero` with `.crumbs`, `.eyebrow`, `h1`, `.lede`, `.kicker`, `.toc-mini`), four teaching sections plus the `.reveal` advanced section, two-to-three `.fig` figures with the `solid-select` interactive shell, real `pre.code` Portal listings, the `.bridge`, and the `#refs` block. Respect the no-invent guards: use only the real Portal surfaces as written — `Portal.EventStore` as the behaviour, `InMemory`/`Postgres`/`Stub` as adapters chosen by `config :portal, :event_store, ...`, and the event types from F5.05 such as `Portal.Events.LearnerEnrolled`; cite the companion course for OTP internals (`Agent`, `Ecto`) and do not re-teach them. Voice rules: no first person, no exclamation marks, no emoji, and none of just / simply / obviously.
