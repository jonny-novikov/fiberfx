# F5.06.1 — Choosing where state lives (dive)

- Route (served): `/elixir/pragmatic/state/choosing`
- File: `elixir/pragmatic/state/choosing.html`
- Place in the chapter: the first of three dives under the F5.06 module hub. It opens the runtime question — which BEAM construct should hold the folded engine state — and answers it: a `GenServer`, because the engine must hold state and run logic together. It also carries the front-matter ETS read-through-cache advanced section, then hands to F5.06.2 (the engine GenServer).
- Accent: burgundy (the F5 · Pragmatic Programming chapter accent).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `F5.06 · part 1 of 3`

Title: Choosing where state lives

Hero lede (verbatim):

> Three places can hold live in-memory state on the BEAM, and they are not interchangeable. A **GenServer** is a process with a state loop: it serializes access and can run real logic on each message, so it can fold events and evolve. An **Agent** is a GenServer narrowed to one job — hold a value, answer get and update — with no place to put command logic. **ETS** is a shared in-memory table with concurrent, lock-free reads, but it is a key-value store, not a place to run a reducer, and it lives only as long as its owner process. The engine runs the F5.04 contract and the F5.05 fold on every command, so it needs the one that holds state and executes code: a GenServer. ETS can join later for read-heavy projections.

Kicker (`.kicker`, verbatim):

> Three holders, one job each. Select one to see what it gives and whether the engine can use it.

## Sections

In order:

1. `#three` — **Three holders** (teaching). Frames the question as "which can do the engine's work" — logic plus state, in order, one write at a time — and carries the holder-select interactive.
2. `#code` — **In code** (teaching). The three shapes side by side, then the choice, with a `pre.code` block contrasting `Agent.update`, `:ets.insert`, and `Portal.Engine` (`use GenServer`).
3. `An ETS read-through cache` (`#cacheTitle`, advanced/front-matter). Splits read path from write path: hot reads served from an `:ets` table, writes funnelling through the single-writer `Portal.Engine`. Carries a two-path diagram and a full `pre.code` engine listing.

Running example: the Portal enrollment engine — `{:enroll, user_id, course_id}` commands and a `progress_of/1` read.

Real Elixir shown:

- The three-holder contrast block: `Agent.update(pid, fn state -> Map.put(state, k, v) end)`, `:ets.insert(table, {k, v})`, and `defmodule Portal.Engine do use GenServer end` (`state is the fold of the log (F5.05), held between calls`).
- The ETS read-through-cache `Portal.Engine`: `init` runs `replay(events)`, creates `:ets.new(:portal_cache, [:named_table, :protected, read_concurrency: true])`, then `refresh_cache(state)`; the command `handle_call({:enroll, user_id, course_id}, _from, state)` runs `decide` → `Enum.reduce(events, state, &evolve/2)` → `refresh_cache(next)`; `defp refresh_cache(state)` writes `{user_id, progress}` rows via `State.all_progress(state)`; the hot read `progress_of(user_id)` does `:ets.lookup(:portal_cache, user_id)` returning `{:ok, progress}` or `{:error, :not_enrolled}`. Worked output: `Portal.Engine.progress_of("u-7")` → `{:ok, 0.4}`; `Portal.Engine.progress_of("u-stranger")` → `{:error, :not_enrolled}`.

## The interactives

### Figure — `State holder · select one` (`#chTitle`)

- `<figure class="fig">`; control group `#chSel` (`role="group"`, label `State holder`) with three `data-k` buttons: `genserver` (active default), `agent`, `ets`.
- SVG row ids toggled on select: `chRow_genserver` (burgundy stroke `#c4504c`), `chRow_agent`, `chRow_ets`.
- Readout target `#chOut` (`aria-live="polite"`), plus `#chRole` (`holder:`) and `#chResult` (`for the engine:`).
- Pure JS: a `HOLDERS` map keyed `genserver`/`agent`/`ets`, each with `name`, `verdict`, `desc`; `ORDER = ['genserver','agent','ets']`; `pick(k)` recolours the active row (burgundy `#e08f8b` / mute `#c4504c`) and writes the readout. Initial `pick('genserver')`.
- Readout strings (verbatim):
  - GenServer: verdict `holds state + runs decide/evolve`, desc `A process with its own loop. It serializes access and runs code on each message, so it can hold the folded state and run the contract, decide, and evolve. This is the engine.`
  - Agent: verdict `holds a value, no command logic`, desc `A GenServer narrowed to one job: hold a value and answer get and update. Convenient for shared settings, but there is no place to run the command contract — wrong fit for the engine.`
  - ETS: verdict `shared table, concurrent reads`, desc `A shared in-memory table with concurrent, lock-free reads, owned by a process. Excellent for read-heavy projections later, but it is a key-value store, not a place to fold a log.`
- Static defaults in markup: `#chRole` `GenServer`; `#chResult` `holds state + runs decide/evolve`.

### Second diagram — `Two paths · one source of truth` (`#caTitle`)

A static (non-interactive) SVG in the ETS read-through-cache section. The write path: `COMMAND` (`{:enroll, …}`) → mailbox → `PORTAL.ENGINE` (single writer · decide / evolve · owns the table) → refresh → `:ETS` (`:portal_cache`). The read path: `READERS` (`progress_of/1`) → concurrent · lock-free · `:ets.lookup/2`, served straight off the table. The two `.arc-flow` dashed lines animate (suppressed under `prefers-reduced-motion: reduce`). Note below it: `Writes funnel through one process; reads fan out across many. The dashed lines are the live paths — one in, one out of the table.`

### Degrade behaviour

The `#three` figure renders the active GenServer row directly in markup, so it reads without JS. The two `.reveal` sections (the ETS cache and References) appear immediately when JS is off or under `prefers-reduced-motion: reduce`. The `.arc-flow` flow animation is disabled under reduced motion; `scroll-behavior` falls back to `auto`.

### Footer build-stamp decoder

The footer stamp `#stamp` carries id `TSK0Nd2lo6tx3o` (namespace `TSK`). The inline branded-Snowflake decoder (base-62, epoch `1704067200000`) splits it on click into namespace / snowflake / node / seq / timestamp. The markup pre-fills the timestamp as `2026-06-01 16:41:01 UTC`.

## References (#refs, verbatim)

Intro line: `Primary sources for this lesson, and where it connects in the course.`

Sources:

- `Elixir — GenServer` — `https://hexdocs.pm/elixir/GenServer.html` — a process that holds state behind a contract.
- `Elixir — Agent` — `https://hexdocs.pm/elixir/Agent.html` — the minimal state-holding process.
- `Erlang — ets` — `https://www.erlang.org/doc/man/ets.html` — in-memory tables for shared, fast reads.

Related in this course:

- `/elixir/pragmatic/state` — F5.06 · Where engine state lives
- `/elixir/pragmatic/state/genserver` — The engine GenServer
- `/elixir/pragmatic/cqrs/reducer` — F5.05 · The reducer fold

(The ETS-cache prose also links inline to `https://www.erlang.org/doc/man/ets.html` and `https://hexdocs.pm/elixir/GenServer.html`.)

## Wiring

- route-tag (verbatim): `/ ` `elixir` `/` `pragmatic` `/` `state` `/` `choosing` (current segment `choosing`; links to `/elixir`, `/elixir/pragmatic`, `/elixir/pragmatic/state`).
- crumbs (verbatim): `F5` `/` `F5.06` `/` `choosing` (here).
- toc-mini: `#three` → `Three holders`; `#code` → `In code`.
- pager: prev → `/elixir/pragmatic/state` label `← F5.06 · state`; next → `/elixir/pragmatic/state/genserver` label `Next · the engine GenServer →`.
- footer columns (verbatim): **Chapters** — `/elixir/algebra` (F1 · Algebra), `/elixir/functional` (F2 · Functional Programming), `/elixir/language` (F3 · The Elixir Language), `/elixir/algorithms` (F4 · Algorithms & Data Structures), `/elixir/pragmatic` (F5 · Pragmatic Programming), `/elixir/phoenix` (F6 · Phoenix Framework). **The course** — `/elixir` (Course home), `/elixir/course` (Contents & history), `/elixir/algebra/functions` (Start · F1.01).
- Page meta — `<title>`: `Choosing where state lives — F5.06.1 · jonnify`. `<meta description>`: present (the page head carries a full description of the three holders and the GenServer choice).

## Build instruction

To rebuild this page, copy the `<head>…</style>`, the `header.site`, the `footer.site-foot`, and the trailing `<script>` blocks (the holder-select controller + branded-Snowflake decoder, and the reveal-on-scroll enhancer) verbatim from a recent built dive on the burgundy F5 accent — the closest model is its sibling `elixir/pragmatic/state/genserver.html`. Change only the `<title>`/`<meta description>`, the route-tag (`choosing` current segment), and the `<main>` body (hero, the `#three` figure, the `#code` block, the ETS read-through-cache section with its two-path diagram, references, pager). Keep the no-invent guards: present only the real Portal surfaces as written — `Portal.Engine` is the event-sourced GenServer behind one Portal facade; state holders are exactly `GenServer`, `Agent`, and `ETS`; the cache table is `:portal_cache`, `:protected`, `read_concurrency: true`. Cite the companion course for OTP internals; do not re-teach GenServer, Agent, or ETS mechanics. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously. Model sibling to copy from: `elixir/pragmatic/state/genserver.html`.
