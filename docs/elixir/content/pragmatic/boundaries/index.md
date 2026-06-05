# F5.08 — Boundaries & integration seams (module hub)

- Route (served): `/elixir/pragmatic/boundaries`
- File: `elixir/pragmatic/boundaries/index.html`
- Place in the chapter: the eighth module of F5 · Pragmatic Programming. Seven modules in, the framework-free Portal engine works (pure core, supervised GenServer, test suite); this module gives it a *boundary*, drawing the hexagonal seams that F6 Phoenix will plug into. It frames three dives — ports & adapters, the engine facade, and error contracts — and hands off to F5.09 (the engine lab).
- Accent: burgundy (the F5 · Pragmatic Programming chapter accent).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `F5 · the engine · module 8`

Title: Boundaries & integration **seams**

Hero lede (verbatim):

> Seven modules in, the engine works: a pure core of `decide` and `evolve`, a supervised GenServer that holds the fold, and a test suite that pins it down. What it does not yet have is a **boundary**. Right now a caller would have to know the engine is a process, know the message shapes it accepts, and know how state is stored. That is three kinds of coupling the web layer in F6 should never carry. This module draws the boundary the way Alistair Cockburn frames **ports and adapters** — the application core defines its edges as interfaces and the outside world plugs into them — rendered in Elixir as **behaviours**. The core states what it needs (a **driven port** such as an event store) and how it is invoked (a **driving port**, the facade the UI calls); adapters supply the implementations; and every failure that crosses the line does so as a typed **error contract** the UI can render.

Kicker (verbatim):

> One core, two kinds of port, one error vocabulary. Select a seam to see what it is and which dive builds it.

## What the page frames

The landing carries three teaching sections (`#hexagon`, `#seams`, `#dives`) and then the three deep-dive cards:

- `F5.08.1` — **Ports & adapters** — a port is a `@behaviour`; adapters implement it; config swaps them. One event-store contract, an in-memory adapter and a Postgres adapter, and a core that never names either. Route `/elixir/pragmatic/boundaries/ports`. Built.
- `F5.08.2` — **The engine facade** — a small, intention-revealing context (`enroll/2`, `deliver_lesson/2`, `progress_of/1`) that hides the GenServer, the log, and the reducer behind one door. Route `/elixir/pragmatic/boundaries/facade`. Built.
- `F5.08.3` — **Error contracts for the UI** — a closed set of `%Portal.Error{}` codes, mapped at the boundary, so the UI renders a finite set of outcomes and never sees a raw exception or an internal struct. Route `/elixir/pragmatic/boundaries/errors`. Built.

The `#seams` section shows all three constructs side by side in one `pre.code` block: a driven port (`Portal.EventStore` behaviour), the driving port (`Portal`), and the error contract (`Portal.Error`). A `.note` records the wiring line `config :portal, :event_store, Portal.EventStore.Postgres` (tests set `Portal.EventStore.InMemory`).

The `.bridge` two-cell pairs `F5.07 · a tested engine` (the core is pure and pinned but callers still know it is a process) with `F5.08 · a usable boundary` (ports invert the dependencies, a facade hides the runtime, errors cross in a shape the UI knows). The trailing `.note` orders the dives and points forward to F5.09 · the engine lab, with cross-links to `/elixir/pragmatic/state` and `/elixir/pragmatic/flow`.

## The interactives

Two interactive figures.

### Hero figure — "What the caller must know"
- `<figure class="hero-fig">`, `aria-labelledby="bhTitle"`, caption label id `bhTitle` reading `What the caller must know`.
- Controls: two buttons — `id="bhBtn"` (`▸ draw the boundary`) and `id="bhReset"` (`reset`).
- SVG group `id="bhChain"`; the static default (visible without JS) draws three burgundy rows: `knows it’s a process`, `knows the message shapes`, `knows the store`, plus a vertical rail.
- Caption readout `id="bhCap"` (`aria-live="polite"`). Coupled (default) state, verbatim: `[ process · messages · store ]` then `Three couplings the caller must carry.` Bounded state, verbatim: `[ one call · Portal.enroll/2 ]` then `One seam. The process, messages, and store are hidden behind it.` Toggling `bhBtn` flips the SVG to a single sage row `Portal.enroll(user, course)` / sub-label `the facade — one call`, and the button label toggles between `▸ draw the boundary` and `▸ show the coupling`.
- The pure-function shape: an inner IIFE builds SVG rows via `el`/`rail`/`row` helpers; `render()` switches between the `COUPLED` array of three rows and the single bounded facade row driven by the boolean `bounded`. No formula — it computes which rows to draw.
- Degrade: the three coupled rows are present in static markup, so the figure reads with JS off. New-row entry animation `hpIn` is suppressed under `prefers-reduced-motion: reduce`.

### Diagram figure — "The hexagon · select a seam"
- `<figure class="fig">`, `aria-labelledby="bdTitle"`, heading id `bdTitle` reading `The hexagon · select a seam`.
- Control group `id="bdSel"` (`role="group"`, `aria-label="Boundary seam"`), three buttons by `data-k`: `ports` (`driven ports`, active by default), `facade` (`driving port`), `errors` (`error contract`).
- SVG parts toggled: `id="bdPart_ports"`, `id="bdPart_facade"`, `id="bdPart_errors"`. The hexagon core text reads `ENGINE CORE` / `decide · evolve · state`; the error part reads `%Portal.Error{} → UI`.
- Readout `id="bdOut"` (`aria-live="polite"`); role label `id="bdRole"` (default `Driven ports`) and `id="bdResult"` (default `behaviours the core needs`).
- Pure function `pick(k)` looks up the `SEAMS` table and writes role, detail, and the `bdOut` sentence. The three seam descriptions (verbatim from the `SEAMS` object):
  - `ports` — name `Driven ports`, detail `behaviours the core needs`, desc: `The seam of F5.08.1. The core states what it needs — an event store, a clock — as a behaviour, and adapters implement it. The core depends on the behaviour, never the adapter, and config picks which adapter runs.`
  - `facade` — name `Driving port`, detail `the API the UI calls`, desc: `The seam of F5.08.2. A small context of intention-revealing functions — enroll, deliver_lesson, progress_of — is the only surface the UI knows. Behind it the GenServer, the event log, and the reducer can change freely.`
  - `errors` — name `Error contract`, detail `a closed set the UI renders`, desc: `The seam of F5.08.3. Every failure that crosses the boundary becomes a %Portal.Error{} with a code from a closed set, so the UI renders a finite list of outcomes — never a raw exception, never an internal struct.`
- The `bdOut` template (verbatim): `The <b>...</b> seam — <code>...detail...</code>. ...desc`.
- Degrade: `pick('ports')` runs on load to populate the readout; the `.arc-flow` animation is gated behind `prefers-reduced-motion: no-preference`.

### Footer build-stamp
- `id="stampId"` text: `TSK0Nd7nZI0bey`. Static timestamp printed in the panel: `2026-06-01 17:51:23 UTC`. The branded-Snowflake decoder (namespace `TSK`, base62 body, epoch `1704067200000`) decodes the id to the same UTC timestamp on click/Enter/Space.

## References (#refs, verbatim)

Intro line: `Ports and adapters, behaviours as the port mechanism, and adapters chosen by configuration.`

Sources:
- `Alistair Cockburn — Hexagonal architecture` — https://alistair.cockburn.us/hexagonal-architecture/ — the ports-and-adapters pattern.
- `Elixir — Typespecs & behaviours` — https://hexdocs.pm/elixir/typespecs.html — defining a port as a behaviour.
- `José Valim — Mocks and explicit contracts` — https://dashbit.co/blog/mocks-and-explicit-contracts — adapters behind a behaviour, chosen in config.

Related in this course:
- `/elixir/pragmatic/boundaries/ports` — F5.08.1 · Ports & adapters
- `/elixir/pragmatic/boundaries/facade` — F5.08.2 · The engine facade
- `/elixir/pragmatic/boundaries/errors` — F5.08.3 · Error contracts for the UI
- `/elixir/pragmatic/state` — F5.06 · Where engine state lives — the engine behind the boundary.
- `/elixir/pragmatic/contracts` — F5.04 · Design by contract — where the error vocabulary begins.
- `/elixir/pragmatic/testing` — F5.07 · Pragmatic testing — the seams are also test seams.

## Wiring

- route-tag (verbatim): `/ ` `elixir` `/ ` `pragmatic` `/ ` `boundaries` — i.e. `<a href="/elixir">elixir</a>` · `<a href="/elixir/pragmatic">pragmatic</a>` · current `boundaries`.
- crumbs (verbatim): `F5 · Pragmatic Programming` (`/elixir/pragmatic`) `/` `F5.08 · boundaries` (here).
- toc-mini: `#hexagon` → `The shape of the boundary`; `#seams` → `Three seams in code`; `#dives` → `Three deep dives`.
- pager: prev → `/elixir/pragmatic` label `F5 · overview`; next → `/elixir/pragmatic/boundaries/ports` label `Start · ports & adapters`.
- footer: column `Chapters` — `/elixir/algebra` (F1 · Algebra), `/elixir/functional` (F2 · Functional Programming), `/elixir/language` (F3 · The Elixir Language), `/elixir/algorithms` (F4 · Algorithms & Data Structures), `/elixir/pragmatic` (F5 · Pragmatic Programming), `/elixir/phoenix` (F6 · Phoenix Framework). Column `The course` — `/elixir` (Course home), `/elixir/course` (Contents & history), `/elixir/algebra/functions` (Start · F1.01). Foot tag: `Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir.`
- Page meta:
  - `<title>`: `Boundaries & integration seams — F5.08 · jonnify`
  - `<meta name="description">`: `The engine works, but its callers still have to know it is a process with message shapes and a chosen store. F5.08 draws the boundary with hexagonal architecture: the core declares its needs as ports (behaviours), adapters implement them, a facade is the one door the UI calls, and failures cross the line as a closed set of typed errors. Three dives on ports and adapters, the engine facade, and error contracts for the UI.`

## Build instruction

To rebuild this page, copy the `head`…`</style>`, the `header`, the `footer`, and the two trailing `<script>` blocks verbatim from a recent built sibling on the burgundy F5 accent — the model sibling is `elixir/pragmatic/boundaries/index.html` itself (or, if rebuilding from a peer module hub, another F5 module landing such as `elixir/pragmatic/testing/index.html`); change only `<title>`/`<meta description>`, the `route-tag`, and the `<main>` body. This is a module hub: keep the hero (`.hero-copy` + `.hero-lede` + `.hero-art` figure), the `#hexagon`/`#seams`/`#dives` sections, the three dive cards, the `.bridge`, and the `#refs` block. Respect the no-invent guards: use only the real Portal surfaces as written — the branded store, the event-sourced engine behind ONE `Portal` facade, and the Phoenix web app to come in F6; cite the companion course for OTP internals and do not re-teach GenServer mechanics. Voice rules: no first person, no exclamation marks, no emoji, and none of just / simply / obviously.
