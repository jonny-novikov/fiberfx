# F5.06.3 — Supervision (dive)

- Route (served): `/elixir/pragmatic/state/supervision`
- File: `elixir/pragmatic/state/supervision.html`
- Place in the chapter: the third and last dive under the F5.06 module hub. It follows F5.06.2 (the engine GenServer) and closes the module: a supervisor that restarts the engine when it crashes, with `init/1` replaying the log to rebuild the state. It returns to the F5.06 overview / the chapter and points ahead to F5.07 · Pragmatic testing.
- Accent: burgundy (the F5 · Pragmatic Programming chapter accent).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `F5.06 · part 3 of 3`

Title: Supervision

Hero lede (verbatim):

> A process that holds state will eventually meet a bug or a bad message and crash. The BEAM answer is not to wrap every line in defensive code but to **let it crash** and put a **supervisor** above it. When the engine dies, the supervisor starts a fresh one; `init/1` folds the event log again, and the state is back. This is exactly why the F5.05 fold matters: because the log is the source of truth and replay is deterministic, a restart loses nothing. A strategy of `:one_for_one` restarts only the child that failed, and `:permanent` means it is always brought back.

Kicker (`.kicker`, verbatim):

> Crash, restart, replay — a full cycle. Select a step to see what happens to the engine and its state.

## Sections

In order:

1. `#cycle` — **The crash-restart cycle** (teaching). Engine running and holding state → a bad message crashes it (in-memory state gone) → the supervisor starts a fresh engine whose `init` folds the log and rebuilds the state. Carries the step-select interactive.
2. `#code` — **In code** (teaching). A small supervision tree, with a `pre.code` block and a `.bridge` (`let it crash` → `restart replays`).

Running example: the Portal enrollment engine under a supervisor.

Real Elixir shown (the `pre.code` block):

```
defmodule Portal.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Portal.Engine, load_events()}    # the engine, started with its event log
    ]
    # one_for_one: if a child crashes, restart only that child
    opts = [strategy: :one_for_one, name: Portal.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

# when Portal.Engine crashes, the supervisor starts a fresh one;
# init/1 folds the log again, so the state is rebuilt — the log is the source of truth.
```

## The interactives

### Figure — `Crash, restart, replay · select a step` (`#svTitle`)

- `<figure class="fig">`; control group `#svSel` (`role="group"`, label `Supervision step`) with three `data-k` buttons: `run` (active default, label `running`), `crash`, `restart`.
- SVG ids: nodes `svNode_run` (gold stroke `#d4a85a`, `live` / `holds state`), `svNode_down` (`down` / `state lost`), `svNode_back` (`live` / `state replayed`); arrows `svArrow_crash`, `svArrow_restart`. Node list `['svNode_run','svNode_down','svNode_back']`, arrow list `['svArrow_crash','svArrow_restart']`.
- Readout target `#svOut` (`aria-live="polite"`), plus `#svRole` (`step:`) and `#svResult` (`what happens:`).
- Pure JS: a `STEPS` map keyed `run`/`crash`/`restart`, each with `name`, `res`, `node`, `arrow`, `desc`; `ORDER = ['run','crash','restart']`; `pick(k)` highlights the active node (gold `#f0cd7f` / mute `#d4a85a`, dim `#46506f`) and its arrow, and writes the readout. Initial `pick('run')`.
- Readout strings (verbatim):
  - running: name `running`, res `engine holds the folded state`, desc `The engine is alive and holding the state it folded from the log. Commands change it and queries read it — the normal operating state.`
  - crash: name `crash`, res `a bad message kills the process`, desc `A bug or an impossible message takes the process down. Its in-memory state is gone with it — and on the BEAM that is acceptable, because nothing durable lived only in that snapshot.`
  - restart: name `restart`, res `supervisor restarts; init replays`, desc `The supervisor starts a fresh engine. Its init folds the event log again, rebuilding the same state — recovery is replay from the log, not repair of the old process.`
- Static defaults in markup: `#svRole` `running`; `#svResult` `engine holds the folded state`.

### Second diagram — the `.bridge` (in `#code`)

A static two-cell bridge: `let it crash` (`Instead of defending every line, let a broken process die and have a supervisor replace it.`) → `restart replays` (`A fresh engine's init folds the log, so the state returns on its own.`).

### Degrade behaviour

The `#cycle` figure renders the running node and the full cycle directly in SVG markup, so it reads without JS. The `.reveal` References section appears immediately when JS is off or under `prefers-reduced-motion: reduce`. `scroll-behavior` falls back to `auto` under reduced motion. This page has no flow/keyframe animations beyond the global reveal transition.

### Footer build-stamp decoder

The footer stamp `#stamp` carries id `TSK0Nd2lolmBn6` (namespace `TSK`). The inline branded-Snowflake decoder (base-62, epoch `1704067200000`) splits it on click into namespace / snowflake / node / seq / timestamp. The markup pre-fills the timestamp as `2026-06-01 16:41:01 UTC`.

## References (#refs, verbatim)

Intro line: `Primary sources for this lesson, and where it connects in the course.`

Sources:

- `Elixir — GenServer` — `https://hexdocs.pm/elixir/GenServer.html` — a process that holds state behind a contract.
- `Elixir — Agent` — `https://hexdocs.pm/elixir/Agent.html` — the minimal state-holding process.
- `Erlang — ets` — `https://www.erlang.org/doc/man/ets.html` — in-memory tables for shared, fast reads.

Related in this course:

- `/elixir/pragmatic/state` — F5.06 · Where engine state lives
- `/elixir/pragmatic/state/genserver` — F5.06.2 · The GenServer that owns state
- `/elixir/pragmatic/cqrs` — F5.05 · Commands, queries & events

## Wiring

- route-tag (verbatim): `/ ` `elixir` `/` `pragmatic` `/` `state` `/` `supervision` (current segment `supervision`; links to `/elixir`, `/elixir/pragmatic`, `/elixir/pragmatic/state`).
- crumbs (verbatim): `F5` `/` `F5.06` `/` `supervision` (here).
- toc-mini: `#cycle` → `The crash-restart cycle`; `#code` → `In code`.
- pager: prev → `/elixir/pragmatic/state/genserver` label `← F5.06.2 · genserver`; next → `/elixir/pragmatic/state` label `Back to F5.06 →`.
- footer columns (verbatim): **Chapters** — `/elixir/algebra` (F1 · Algebra), `/elixir/functional` (F2 · Functional Programming), `/elixir/language` (F3 · The Elixir Language), `/elixir/algorithms` (F4 · Algorithms & Data Structures), `/elixir/pragmatic` (F5 · Pragmatic Programming), `/elixir/phoenix` (F6 · Phoenix Framework). **The course** — `/elixir` (Course home), `/elixir/course` (Contents & history), `/elixir/algebra/functions` (Start · F1.01).
- Page meta — `<title>`: `Supervision — F5.06.3 · jonnify`. `<meta description>`: present (the page head carries a full description of let-it-crash, the supervisor restart, and `init` replaying the log).

## Build instruction

To rebuild this page, copy the `<head>…</style>`, the `header.site`, the `footer.site-foot`, and the trailing `<script>` blocks (the step-select controller + branded-Snowflake decoder, and the reveal-on-scroll enhancer) verbatim from a recent built dive on the burgundy F5 accent — the closest model is its sibling `elixir/pragmatic/state/genserver.html`. Change only the `<title>`/`<meta description>`, the route-tag (`supervision` current segment), and the `<main>` body (hero, the `#cycle` figure, the `#code` block with the `Portal.Application` listing and the bridge, references, pager). Keep the no-invent guards: present only the real Portal surfaces as written — `Portal.Application` with `use Application`, a `children` list holding `{Portal.Engine, load_events()}`, `strategy: :one_for_one`, `name: Portal.Supervisor`, and `Supervisor.start_link(children, opts)`; `init/1` replays the log on restart. Cite the companion course for OTP supervision internals; do not re-teach supervisor strategies, restart intensity, or `:permanent`/`:transient` semantics here beyond what the lede states. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously. Model sibling to copy from: `elixir/pragmatic/state/genserver.html`.
