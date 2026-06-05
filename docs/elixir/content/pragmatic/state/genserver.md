# F5.06.2 — The engine GenServer (dive)

- Route (served): `/elixir/pragmatic/state/genserver`
- File: `elixir/pragmatic/state/genserver.html`
- Place in the chapter: the second of three dives under the F5.06 module hub. It follows F5.06.1 (the choice of a GenServer) and builds that process: three callbacks — `init/1` folds the log, a command `handle_call` runs `decide` and `evolve`, a query `handle_call` reads and replies. It hands to F5.06.3 (supervision).
- Accent: burgundy (the F5 · Pragmatic Programming chapter accent).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `F5.06 · part 2 of 3`

Title: The engine GenServer

Hero lede (verbatim):

> Three callbacks carry the whole engine. `init/1` runs once on start: it folds the event log into the starting state — the F5.05 reduce, run here. `handle_call` for a **command** runs `decide` (the F5.04 contract, emitting events) and `evolve` (folding them in), replies `:ok`, and keeps the new state. `handle_call` for a **query** reads the state and replies with data, leaving it unchanged. The command/query split from F5.05 becomes two clauses, and because a GenServer handles one message at a time, writes serialize for free.

Kicker (`.kicker`, verbatim):

> One process, three callbacks. Select one to see what runs and how the state threads through.

## Sections

In order:

1. `#calls` — **Three callbacks** (teaching). Each callback takes the current state and returns the next one alongside a reply; the single mailbox means they never overlap. Carries the callback-select interactive.
2. `#code` — **In code** (teaching). The engine in three callbacks, with a `pre.code` block and a `.bridge` (`one message at a time` → `split into clauses`).

Running example: the Portal enrollment engine — `{:enroll, user_id, course_id}` commands and a `{:courses_of, user_id}` query.

Real Elixir shown (the `pre.code` block):

```
defmodule Portal.Engine do
  use GenServer

  # init folds the event log (F5.05) into the starting state, once
  @impl true
  def init(events), do: {:ok, replay(events)}

  # a command: run decide (contract + emit), evolve, keep the new state
  @impl true
  def handle_call({:enroll, user_id, course_id}, _from, state) do
    case decide(state, {:enroll, user_id, course_id}) do
      {:ok, events}      -> {:reply, :ok, Enum.reduce(events, state, &evolve/2)}
      {:error, _} = err -> {:reply, err, state}
    end
  end

  # a query: read the state and reply with data; state is unchanged
  @impl true
  def handle_call({:courses_of, user_id}, _from, state),
    do: {:reply, State.enrollments_for(state, user_id), state}
end
```

## The interactives

### Figure — `Engine callback · select one` (`#gsTitle`)

- `<figure class="fig">`; control group `#gsSel` (`role="group"`, label `GenServer callback`) with three `data-k` buttons: `init` (active default, label `init/1`), `command`, `query`.
- SVG row ids toggled on select: `gsRow_init` (blue stroke `#5a87c4`), `gsRow_command`, `gsRow_query`. The row map is `{ init: 'gsRow_init', command: 'gsRow_command', query: 'gsRow_query' }`.
- Readout target `#gsOut` (`aria-live="polite"`), plus `#gsRole` (`callback:`) and `#gsResult` (`does:`).
- Pure JS: a `CALLS` map keyed `init`/`command`/`query`, each with `name`, `does`, `desc`; `ORDER = ['init','command','query']`; `pick(k)` recolours the active row (blue `#9fc0ea` / mute `#5a87c4`) and writes the readout. Initial `pick('init')`.
- Readout strings (verbatim):
  - init/1: name `init/1`, does `fold the log into state`, desc `Runs once when the process starts. It folds the event log with replay (F5.05) and returns {:ok, state} — the starting state the engine then holds between calls.`
  - command: name `handle_call (command)`, does `decide, evolve, reply :ok`, desc `A write. It runs decide — the F5.04 contract that emits events — folds them with evolve into a new state, and replies :ok. A bad command replies {:error, _} and the state is left alone.`
  - query: name `handle_call (query)`, does `read state, reply data`, desc `A read. It reads the held state and replies with data, returning the same state unchanged. Because queries do not write, the reply is a free, repeatable observation.`
- Static defaults in markup: `#gsRole` `init/1`; `#gsResult` `fold the log into state`.

### Second diagram — the `.bridge` (in `#code`)

A static two-cell bridge: `one message at a time` (`A GenServer's mailbox serializes calls, so writes never race — ordering is free.`) → `split into clauses` (`The F5.05 command/query split becomes two handle_call clauses.`).

### Degrade behaviour

The `#calls` figure renders the active `init/1` row directly in markup, so it reads without JS. The `.reveal` References section appears immediately when JS is off or under `prefers-reduced-motion: reduce`. `scroll-behavior` falls back to `auto` under reduced motion. This page has no flow/keyframe animations beyond the global reveal transition.

### Footer build-stamp decoder

The footer stamp `#stamp` carries id `TSK0Nd2loR3TIO` (namespace `TSK`). The inline branded-Snowflake decoder (base-62, epoch `1704067200000`) splits it on click into namespace / snowflake / node / seq / timestamp. The markup pre-fills the timestamp as `2026-06-01 16:41:01 UTC`.

## References (#refs, verbatim)

Intro line: `Primary sources for this lesson, and where it connects in the course.`

Sources:

- `Elixir — GenServer` — `https://hexdocs.pm/elixir/GenServer.html` — a process that holds state behind a contract.
- `Elixir — Agent` — `https://hexdocs.pm/elixir/Agent.html` — the minimal state-holding process.
- `Erlang — ets` — `https://www.erlang.org/doc/man/ets.html` — in-memory tables for shared, fast reads.

Related in this course:

- `/elixir/pragmatic/state/choosing` — F5.06.1 · Choosing where state lives
- `/elixir/pragmatic/state/supervision` — F5.06.3 · Supervision
- `/elixir/pragmatic/cqrs/reducer` — F5.05 · The reducer

## Wiring

- route-tag (verbatim): `/ ` `elixir` `/` `pragmatic` `/` `state` `/` `genserver` (current segment `genserver`; links to `/elixir`, `/elixir/pragmatic`, `/elixir/pragmatic/state`).
- crumbs (verbatim): `F5` `/` `F5.06` `/` `genserver` (here).
- toc-mini: `#calls` → `Three callbacks`; `#code` → `In code`.
- pager: prev → `/elixir/pragmatic/state/choosing` label `← F5.06.1 · choosing`; next → `/elixir/pragmatic/state/supervision` label `Next · supervision →`.
- footer columns (verbatim): **Chapters** — `/elixir/algebra` (F1 · Algebra), `/elixir/functional` (F2 · Functional Programming), `/elixir/language` (F3 · The Elixir Language), `/elixir/algorithms` (F4 · Algorithms & Data Structures), `/elixir/pragmatic` (F5 · Pragmatic Programming), `/elixir/phoenix` (F6 · Phoenix Framework). **The course** — `/elixir` (Course home), `/elixir/course` (Contents & history), `/elixir/algebra/functions` (Start · F1.01).
- Page meta — `<title>`: `The engine GenServer — F5.06.2 · jonnify`. `<meta description>`: `Three callbacks carry the engine. init folds the event log into the starting state; a command handle_call runs decide and evolve and keeps the new state; a query handle_call reads and replies, unchanged. The command/query split becomes two clauses, and one mailbox serializes writes for free.`

## Build instruction

To rebuild this page, copy the `<head>…</style>`, the `header.site`, the `footer.site-foot`, and the trailing `<script>` blocks (the callback-select controller + branded-Snowflake decoder, and the reveal-on-scroll enhancer) verbatim from a recent built dive on the burgundy F5 accent — the closest model is its sibling `elixir/pragmatic/state/choosing.html`. Change only the `<title>`/`<meta description>`, the route-tag (`genserver` current segment), and the `<main>` body (hero, the `#calls` figure, the `#code` block with the `Portal.Engine` listing and the bridge, references, pager). Keep the no-invent guards: present only the real Portal surfaces as written — `Portal.Engine` is the event-sourced GenServer behind one Portal facade; `init/1` returns `{:ok, replay(events)}`; the command clause is `handle_call({:enroll, user_id, course_id}, ...)` running `decide` then `Enum.reduce(events, state, &evolve/2)`; the query clause is `handle_call({:courses_of, user_id}, ...)` calling `State.enrollments_for(state, user_id)`. Cite the companion course for GenServer internals; do not re-teach the OTP callback contract here. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously. Model sibling to copy from: `elixir/pragmatic/state/choosing.html`.
