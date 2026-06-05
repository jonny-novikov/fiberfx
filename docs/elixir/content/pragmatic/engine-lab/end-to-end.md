# F5.09.1 — The engine facade end to end (dive)

- Route (served): `/elixir/pragmatic/engine-lab/end-to-end`
- File: `elixir/pragmatic/engine-lab/end-to-end.html`
- Place in the chapter: first of the three dives under the F5.09 lab. It wires the supervision tree and the facade so a command runs end to end and a restart replays the log — the teaching arc that turns eight finished modules into one running system before the LiveView (F5.09.2) and the handoff (F5.09.3).
- Accent: burgundy (the F5 · Pragmatic Programming chapter accent; `--burgundy:#c4504c`).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F5.09 · part 1 of 3`

H1 (verbatim): The engine facade end to end

Hero lede (verbatim):

> Assembly is where the contracts pay off. The `Portal.Application` starts two children under one supervisor: the configured event-store adapter (F5.08.1) and the engine (F5.06). When the engine starts, its `init/1` reads the whole stream through the port and folds it with `replay/1` (F5.05) into the starting state. A command then runs the full path: `Portal.enroll/2` calls the engine, which runs `decide` (the F5.04 contract), **appends** the events through the port so they are durable, folds them with `evolve`, and replies. Because the log is the source of truth, a crash and restart replays it back to the same state. Nothing here is new code; it is eight modules wired into one running system.

Kicker (verbatim):

> One supervised system, three parts. Select a part to see its role at runtime.

## Sections

In order:

1. `#system` — The running system (teaching). Three named parts — Application (supervisor), engine (GenServer holding folded state), store (the resolved adapter) — with the interactive part-selector figure.
2. `#tree` — The supervision tree. The `Portal.Application` start function: store first, then engine, under `:one_for_one`.
3. `#boot` — Boot: read, replay, ready. The engine `init/1` reading the stream and folding with `replay/1`, plus `handle_call` for command and query; carries the boot-sequence diagram.
4. `#persist` — A command, persisted (advanced). An `iex` transcript proving boot, a command, and a restart that replays the log to the same state; a bridge and a forward note.

Running example: the Portal enrollment engine — `Portal.enroll/2`, `Portal.progress_of/1`, append-before-evolve, and a `Process.exit(... :kill)` restart that replays.

Real Elixir code shown:

- `Portal.Application` — `use Application`; `start/2` building `children = [Portal.EventStore.adapter(), {Portal.Engine, []}]` and `Supervisor.start_link(children, strategy: :one_for_one, name: Portal.Supervisor)`.
- `Portal.Engine` — `use GenServer`; `start_link/1`; `init/1` doing `{:ok, events} = EventStore.read_stream("portal")` then `{:ok, replay(events)}`; `handle_call({:command, cmd}, …)` that `decide`s, `EventStore.append("portal", events)`, `Enum.reduce(events, state, &evolve/2)`; `handle_call({:query, q}, …)` returning `answer(state, q)`.
- `iex` transcript: `Portal.enroll("USR0KH...", "CRS0KH...")` → `:ok`; `Portal.progress_of(enrollment_id)` → `{:ok, 0}`; `Process.exit(Process.whereis(Portal.Engine), :kill)`; `Portal.progress_of(enrollment_id)` → `{:ok, 0}` (state returns from the log).

## The interactives

One interactive figure plus one static diagram.

### Running-system figure — `The running system · select a part` (`#eeTitle`)

- `<figure class="fig">` labelled by `eeTitle`.
- Control group id `eeSel` (`role="group"`, `aria-label="Running part"`), three buttons with `data-k`: `app` (active default, `Application`), `engine` (`Engine`), `store` (`EventStore`).
- SVG (`viewBox="0 0 720 200"`) draws three highlightable rows: `eeRow_app` (`APPLICATION · supervisor`, `start_link([store, engine], strategy: :one_for_one)`, side label `supervises`), `eeRow_engine` (`ENGINE · GenServer`, `init reads + replays · handle_call decides + appends`, side label `holds state`), `eeRow_store` (`EVENTSTORE · the port`, `append/2 · read_stream/1 — the adapter holds the log`, side label `durable`).
- Pure function `pick(k)`: toggles active button, recolours the matching row to the burgundy mute (`#c4504c` stroke, `#1d1320` fill), and writes the readout/role/result from the `PARTS` table.
- Readout id `eeOut` (`aria-live="polite"`) renders `<b>{name}</b> — {detail}. {desc}`. Role id `eeRole`, result id `eeResult`. VERBATIM part data:
  - `app` → name `Application`, detail `starts the store and the engine, supervised`, desc: `The supervisor. It starts two children — the configured store adapter and the engine — with a one_for_one strategy, so a crash in either is restarted on its own without taking the other down.`
  - `engine` → name `Engine`, detail `init reads the stream and replays`, desc: `The GenServer. Its init reads the whole log through the port and folds it with replay into state; a command clause decides, appends the new events, and evolves, so the in-memory state always matches the log.`
  - `store` → name `EventStore`, detail `the port the engine appends to`, desc: `The port, resolved by config to an adapter. The engine appends events to it before folding them and reads the stream from it on boot — the adapter is the only thing that actually holds the durable log.`
- Static markup defaults: role `Application`, result `starts the store and the engine, supervised`.

### Boot-sequence diagram — `Boot sequence` (`#eeBootTitle`)

Static (non-interactive) SVG (`viewBox="0 0 720 150"`): four boxes left to right — `APP.START` (`Supervisor`) → `STORE READY` (`adapter started`) → `ENGINE.INIT` (`read_stream + replay`, burgundy) → `READY` (`{:ok, state}`), with the caption `a restart re-runs init; the same log folds to the same state — recovery is replay`.

Degrade behaviour: the running-system figure ships with `app` pre-marked `active` and `eeRole`/`eeResult` defaults in markup; `pick('app')` runs on load. The boot diagram is static. Reveal sections (`.reveal`) are visible without JS, and `prefers-reduced-motion: reduce` disables the reveal transition; the page has no per-figure motion beyond reveal.

Footer build-stamp: id `TSK0Nd9oQBA2O8` (namespace `TSK`); the panel's `st-ts` decodes to `2026-06-01 18:19:34 UTC`. Decoder as on the hub (base62 snowflake; timestamp `>> 22` over epoch `1704067200000`, node `>> 12 & 0x3FF`, seq `& 0xFFF`).

## References (#refs, verbatim)

Intro line: `Primary sources for this lesson, and where it connects in the course.`

Sources:

- `https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html` — Phoenix — Phoenix.LiveView — server-rendered, stateful UI over the engine.
- `https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html` — Phoenix — Phoenix.Component (HEEx) — function components and the HEEx template.
- `https://hexdocs.pm/elixir/Supervisor.html` — Elixir — Supervisor — the engine runs under a supervision tree.

Related in this course:

- `/elixir/pragmatic/state/supervision` — F5.06 · The supervision tree
- `/elixir/pragmatic/cqrs/reducer` — F5.05 · Replay as a reducer
- `/elixir/pragmatic/boundaries/ports` — F5.08 · Ports and the event store

## Wiring

- route-tag (verbatim): `<a href="/elixir">elixir</a>` / `<a href="/elixir/pragmatic">pragmatic</a>` / `<a href="/elixir/pragmatic/engine-lab">engine-lab</a>` / `<span class="rcur">end-to-end</span>`.
- crumbs (verbatim): `F5` (→ `/elixir/pragmatic`) `/` `F5.09` (→ `/elixir/pragmatic/engine-lab`) `/` `end-to-end` (here).
- toc-mini: `#system` The running system · `#tree` The supervision tree · `#boot` Boot: read, replay, ready · `#persist` A command, persisted.
- pager: prev → `/elixir/pragmatic/engine-lab` label `F5.09 · the lab`; next → `/elixir/pragmatic/engine-lab/mount` label `Next · a LiveView mount sketch`.
- footer: column **Chapters** — `/elixir/algebra`, `/elixir/functional`, `/elixir/language`, `/elixir/algorithms`, `/elixir/pragmatic`, `/elixir/phoenix` (same labels F1–F6 as the hub). Column **The course** — `/elixir` (Course home), `/elixir/course` (Contents & history), `/elixir/algebra/functions` (Start · F1.01). Same foot-tag as the hub.
- Page meta — `<title>`: `The engine facade end to end — F5.09.1 · jonnify`. `<meta description>`: `The full supervision tree: Portal.Application starts the configured store adapter and the engine; the engine's init reads the whole stream through the port and replays it into state; a command decides, appends events through the port, and evolves, so a crash and restart replays the log back to the same state.`

## Build instruction

To rebuild this page, copy the `<head>…</style>`, the `<header class="site">`, the `<footer class="site-foot">`, and both trailing `<script>` blocks verbatim from a recent built sibling on this burgundy chapter — the model sibling is `elixir/pragmatic/engine-lab/mount.html` (same lab, same accent, identical stamp/reveal/`solid-select` machinery). Change only the `<title>`/`<meta description>`, the `route-tag` (ending in `<span class="rcur">end-to-end</span>`), and the `<main>` body (hero, `#system`, `#tree`, `#boot`, `#persist`, references, pager). No-invent guards: use only the real Portal surfaces as written — the branded store (`USR…`/`CRS…` ids), the event-sourced engine behind ONE `Portal` facade (`enroll/2`, `progress_of/1`), the `EventStore` port (`append/2`, `read_stream/1`) over a configured adapter, and `decide`/`evolve`/`replay`/`answer`; cite the companion course for OTP internals (`Supervisor`, `GenServer`) rather than re-teaching them, and keep `:one_for_one` and append-before-evolve as written. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously.
