# F5.06 — Where engine state lives (module hub)

- Route (served): `/elixir/pragmatic/state`
- File: `elixir/pragmatic/state/index.html`
- Place in the chapter: the sixth module of F5 · Pragmatic Programming. It follows F5.05 (the pure CQRS fold) and gives that folded state a runtime home — picking the process that owns it, building the engine around `decide` and `evolve`, and putting a supervisor over it. It frames three dives (choosing the holder, the engine GenServer, supervision) and leads into F5.07 · Pragmatic testing.
- Accent: burgundy (the F5 · Pragmatic Programming chapter accent).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `F5 · the engine · module 6`

Kicker (in `h1`): Where engine state *lives*

Hero lede (verbatim):

> The fold from F5.05 is pure: it takes the event log and returns the current state, then forgets it. That is fine for a calculation, but the Portal must keep the state alive between thousands of HTTP requests — the next request needs to see the enrollment the last one recorded. On the BEAM, live in-memory state lives in a **process**. F5.06 picks the process that owns the folded state — a **GenServer**, an **Agent**, or **ETS** — builds it around `decide` and `evolve`, and puts a **supervisor** around that so a crash restarts cleanly and replays the log.

Kicker line (`.kicker`, verbatim):

> One process holds the state; one supervisor keeps it alive. Select a piece to see what it does and which dive builds it.

## What the page frames

Three deep dives (`.dives`-style card stack in the `#dives` section), each linking out at the deeper standard:

- F5.06.1 — Choosing where state lives — A GenServer holds state and runs logic, an `Agent` holds a value, ETS is a shared table — the engine needs the first. Route `/elixir/pragmatic/state/choosing`. Built.
- F5.06.2 — The engine GenServer — `init` folds the log into state; a command call runs `decide` then `evolve`; a query call reads and replies. Route `/elixir/pragmatic/state/genserver`. Built.
- F5.06.3 — Supervision — Let it crash: a supervisor restarts the engine, and `init` replays the log so the state returns. Route `/elixir/pragmatic/state/supervision`. Built.

Bridge (`.bridge`, in the `#dives` section): `F5.05 · state as a fold` → `F5.06 · a home for it`.

## The interactives

### Hero figure — `Three BEAM homes, one fit` (`#bhTitle`)

- `<figure class="hero-fig">` titled `Three BEAM homes, one fit`.
- Controls: button `#bhBtn` (`▸ next home`) and ghost button `#bhReset` (`reset`). No `data-key` control group; the figure steps a pointer through three home cards.
- Home cards (SVG `rect`/`text` ids): `bhCard_gen` + `bhMark_gen` (GENSERVER · state + logic), `bhCard_agent` + `bhMark_agent` (AGENT · a held value), `bhCard_ets` + `bhMark_ets` (ETS · a shared table). Capability ticks: `bhTick_hold` (holds state across requests), `bhTick_logic` (runs decide · evolve per call), `bhTick_super` (restarts under a supervisor). Score group `bhScores`, caption `#bhCap`.
- Pure JS data: a `HOMES` array scored on `hold`/`logic`/`super`. GenServer scores `3/3`; Agent `hold:true, logic:false, super:true`; ETS `hold:true, logic:false, super:false`. The `render` function sets the active card/mark/ticks and recomputes the met count.
- Readout notes (`HOMES[i].note`, verbatim):
  - GenServer: `Holds state, runs logic per call, and restarts under a supervisor — the fit the engine needs.`
  - Agent: `Holds a value and restarts under a supervisor, but a query passes a function in; decide and evolve do not live here.`
  - ETS: `A fast shared table that holds rows, but it runs no command logic and an owner crash drops the table.`
- Caption template: `[ <name> · <met> / 3 ]` then the note line. Initial static caption in markup: `[ GenServer · 3 / 3 ]` / `Holds state, runs logic per call, and restarts under a supervisor — the fit the engine needs.`

### Body figure — `The running engine · select a piece` (`#wlTitle`)

- `<figure class="fig">`; control group `#wlSel` (`role="group"`, label `Engine piece`) with three `data-k` buttons: `holder` (active default), `engine`, `supervisor`.
- SVG part ids toggled on select: `wlPart_supervisor`, `wlPart_holder` (ENGINE · GenServer, burgundy stroke `#c4504c`), `wlPart_engine` (init · handle_call).
- Readout target `#wlOut` (`aria-live="polite"`), plus `#wlRole` (`piece:`) and `#wlResult` (`in the Portal:`).
- Pure JS: a `PIECES` map keyed `holder`/`engine`/`supervisor`, each with `name`, `detail`, `part`, `desc`; `ORDER = ['holder','engine','supervisor']`; `pick(k)` recolours the active SVG part (burgundy `#e08f8b` / mute `#c4504c`) and writes the readout. Initial `pick('holder')`.
- Readout strings (verbatim):
  - Holder: name `Holder`, detail `a GenServer owns the state`, desc `The choice of F5.06.1. Live state on the BEAM lives in a process; the engine uses a GenServer because it must hold state and run logic on every command, not only stash a value.`
  - Engine: name `Engine`, detail `fold on init, decide on call`, desc `The build of F5.06.2. init folds the event log into the starting state once; a command call runs decide then evolve and keeps the new state; a query call reads and replies, state unchanged.`
  - Supervisor: name `Supervisor`, detail `restart, then replay`, desc `The boundary of F5.06.3. If the engine crashes, the supervisor starts a fresh one and init folds the log again — the log is the source of truth, so the state comes back.`
- Static default `#wlRole` text in markup: `Holder`; `#wlResult`: `a GenServer owns the state`.

### Degrade behaviour

The hero figure renders its initial state (GenServer under test, all three capabilities met) directly in the SVG markup, so it is meaningful without JS. The `.reveal` References section is shown immediately when JS is off or when `prefers-reduced-motion: reduce`; the `.hp-row` slide-in animation (`@keyframes hpIn`) is suppressed under reduced motion. `scroll-behavior` falls back to `auto` under reduced motion.

### Footer build-stamp decoder

The footer stamp `#stamp` carries id `TSK0Nd2lnmBEZ6` (namespace `TSK`). The inline branded-Snowflake decoder (base-62, epoch `1704067200000`) splits it on click into namespace / snowflake / node / seq / timestamp. The markup pre-fills the timestamp as `2026-06-01 16:41:01 UTC`.

## References (#refs, verbatim)

Intro line: `Holding state in a process, and the choices for where it lives.`

Sources:

- `Elixir — GenServer` — `https://hexdocs.pm/elixir/GenServer.html` — stateful server processes.
- `Elixir — Agent` — `https://hexdocs.pm/elixir/Agent.html` — simple shared state.
- `Erlang — ETS` — `https://www.erlang.org/doc/man/ets.html` — in-memory term storage.

Related in this course:

- `/elixir/pragmatic/state/choosing` — F5.06.1 · Choosing where state lives
- `/elixir/pragmatic/state/genserver` — F5.06.2 · The engine GenServer
- `/elixir/pragmatic/state/supervision` — F5.06.3 · Supervision
- `/elixir/pragmatic/cqrs` — F5.05 · Commands, queries & events — the fold this state comes from.
- `/elixir/pragmatic/flow` — F5.0.3 · The command & event flow — the runtime path this sits on.

## Wiring

- route-tag (verbatim): `/ ` `elixir` `/` `pragmatic` `/` `state` (current segment `state`, links to `/elixir` and `/elixir/pragmatic`).
- crumbs (verbatim): `F5 · Pragmatic Programming` `/` `F5.06 · state` (here).
- toc-mini: `#runtime` → `A home for the fold`; `#dives` → `Three deep dives`.
- pager: prev → `/elixir/pragmatic` label `← F5 · overview`; next → `/elixir/pragmatic/state/choosing` label `Start · choosing where state lives →`.
- footer columns (verbatim): **Chapters** — `/elixir/algebra` (F1 · Algebra), `/elixir/functional` (F2 · Functional Programming), `/elixir/language` (F3 · The Elixir Language), `/elixir/algorithms` (F4 · Algorithms & Data Structures), `/elixir/pragmatic` (F5 · Pragmatic Programming), `/elixir/phoenix` (F6 · Phoenix Framework). **The course** — `/elixir` (Course home), `/elixir/course` (Contents & history), `/elixir/algebra/functions` (Start · F1.01). Foot tag: `Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir.`
- Page meta — `<title>`: `Where engine state lives — F5.06 · jonnify`. `<meta description>`: `The F5.05 fold is pure: it computes the current state from the event log and forgets it. At runtime the Portal must keep that state alive between requests, and on the BEAM live state lives in a process. F5.06 picks the process that owns the folded state — a GenServer, an Agent, or ETS — builds it around decide and evolve, and puts a supervisor around it. Three dives on choosing the holder, the engine GenServer, and supervision.`

## Build instruction

To rebuild this page, copy the `<head>…</style>`, the `header.site`, the `footer.site-foot`, and the two trailing `<script>` blocks (the interactive controllers + branded-Snowflake decoder, and the reveal-on-scroll enhancer) verbatim from a recent built sibling on the burgundy F5 accent — the closest model is `elixir/pragmatic/cqrs/index.html` (the F5.05 module hub) or another F5 module-hub `index.html`; this page's own `index.html` is the canonical hub layout. Change only the `<title>`/`<meta description>`, the route-tag (`state` current segment), and the `<main>` body (hero, the two figures, the three dive cards, the bridge, references, pager). Keep the no-invent guards: use only the real Portal surfaces as written — the branded store, the event-sourced engine behind one Portal facade, and the Phoenix web app — and present state holders only as `GenServer`, `Agent`, and `ETS` with the scores shown. Cite the companion course for OTP internals; do not re-teach GenServer or supervision mechanics here. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously. Model sibling to copy from: `elixir/pragmatic/cqrs/index.html`.
