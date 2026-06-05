# F5.09 — Lab: the Portal engine, LiveView-ready (module hub / lab)

- Route (served): `/elixir/pragmatic/engine-lab`
- File: `elixir/pragmatic/engine-lab/index.html`
- Place in the chapter: the finale of F5 · Pragmatic Programming. After eight modules built the parts (F5.01 foundations → F5.08 boundaries), this lab assembles them into one running Portal — a supervision tree with the engine behind its facade — mounts it behind a LiveView sketch, and states the handoff to F6. It frames three dives: the engine facade end to end, a LiveView mount sketch, and what ships in F6.
- Accent: burgundy (the F5 · Pragmatic Programming chapter accent; `--burgundy:#c4504c`).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F5 · the engine · the lab`

H1 (verbatim): The Portal engine, *assembled*

Hero lede (verbatim):

> Eight modules built the parts. F5.01 stood up a thin server; F5.02 modelled the domain; F5.03 drove a walking skeleton through every layer; F5.04 gave the enroll command a contract; F5.05 split commands from queries and recorded each change as an event; F5.06 put the folded state in a supervised GenServer; F5.07 pinned it with tests; F5.08 drew the boundary — ports, a facade, a closed error contract. This lab is the finale: it **assembles** them into one running Portal — a supervision tree with the engine behind its facade, fed by an event-store port — **mounts** it behind a LiveView sketch, and states the **handoff** to F6. It ships with a spec and copy-paste build prompts, so the same assembly can be generated end to end and verified against a definition of done.

Kicker (verbatim):

> One assembled system, three phases. Select a phase to see what it produces and which dive builds it.

## What the page frames

The landing has no `.mods` card grid; it frames three deep dives in a custom dive list (`#dives`), plus two in-page teaching sections (`#stack` the assembled Portal, `#prompts` build it with prompts).

The three dives (`#dives`, in order):

- `F5.09.1` — The engine facade end to end — the full supervision tree: the Application starts the store and the engine, `init` reads the stream through the port and replays, and an enroll runs facade → engine → store and persists. Route: `/elixir/pragmatic/engine-lab/end-to-end`. Built.
- `F5.09.2` — A LiveView mount sketch — `mount/3` loads state via a query, `handle_event` calls a command and branches on the closed error contract, and `render/1` shows assigns — the LiveView touches only the facade. Route: `/elixir/pragmatic/engine-lab/mount`. Built.
- `F5.09.3` — What ships in F6 — the handoff: F6 replaces the thin web layer with Phoenix and adds its endpoint to the tree, but the facade, the error contract, and the tests carry over unchanged. Route: `/elixir/pragmatic/engine-lab/handoff`. Built.

The `#prompts` section ships a representative copy-paste build prompt verbatim:

```
PROMPT — Assemble the supervision tree
In the portal app, wire Portal.Application to start the configured event-store
adapter and the engine under one supervisor, strategy :one_for_one:
- children: [Portal.EventStore.adapter(), {Portal.Engine, []}]
- Portal.Engine.init/1 reads its stream through the EventStore port and folds it
  with replay/1 (F5.05) into the starting state, returning {:ok, state}.
- the facade (Portal) and the Engine.command/query wrappers are the only callers
  of GenServer.call; results pass through Portal.Error.from/1 at the boundary.
Acceptance: the app boots with `mix run`; a fresh enroll persists an event and a
restart of Portal.Engine replays the log to the same state.
```

## The interactives

Two interactive figures.

### Hero figure — `A crash is recovered, not lost` (`#rsTitle`)

- `<figure class="hero-fig">` labelled by `rsTitle`; figcaption text `A crash is recovered, not lost`.
- SVG (`viewBox="0 0 320 300"`) draws the `APPLICATION · SUPERVISOR` (`strategy :one_for_one`) over two children: `STORE · the log` holding three events (`enrolled`, `lesson_done`, `lesson_done`) and `ENGINE · running` with `progress: 2/3`, `state folded from` `3 events`. Group id `rsEngine`; replay line id `rsReplay`; replay label id `rsReplayTxt` (`init replays the log`).
- Controls (no `data-key` control-group; two buttons): `rsBtn` (`▸ crash the engine`) and `rsReset` (`reset`, ghost). The button cycles three stages: running → crashed (restarting) → recovered (replayed).
- Pure helpers: `engine(stroke, lbl, big, sub, bigFill, isNew)` builds the engine `<g>`; `render(isNew)` swaps the engine group per `stage` (0 running, 1 crashed, 2 recovered) and toggles the replay line/text opacity.
- Readout id `rsCap` (`aria-live="polite"`), strings VERBATIM:
  - stage 0 (also the static default in markup): `[ running · progress 2/3 ]` / `State is folded from the 3 events in the store.`
  - stage 1: `[ crashed · supervisor restarts ]` / `The process is gone, but the event log in the store is not.`
  - stage 2: `[ recovered · progress 2/3 ]` / `init replays the same 3 events — the identical state returns.`
  - Engine sub-labels per stage: running `state folded from` / `3 events`; crashed `supervisor restarts` / `:one_for_one` (label `ENGINE · crashed`, big `restarting…`); recovered `replayed from` / `3 events` (label `ENGINE · recovered`, big `progress: 2/3`).
- Button label cycles: `▸ crash the engine` → `▸ replay the log` → `▸ crash again`.

### Stack figure — `The running stack · select a phase` (`#lbTitle`)

- `<figure class="fig">` labelled by `lbTitle`.
- Control group id `lbSel` (`role="group"`, `aria-label="Lab phase"`), three buttons with `data-k`: `assemble` (active default), `mount`, `handoff`.
- SVG (`viewBox="0 0 720 268"`) is a five-layer stack with highlightable rects: `lbPart_web` (`WEB · LiveView (F6)`, `calls only the facade`), `lbPart_facade` (`FACADE · Portal`, `enroll · deliver_lesson · progress_of`), `lbPart_engine` (`ENGINE · GenServer`, `decide · evolve · folded state`), plus static `PORT · EventStore` (`append · read_stream`) and `ADAPTER · Postgres / InMemory` (`the event log`). A rotated `SUPERVISED` bracket spans engine→adapter.
- Pure function `pick(k)`: toggles active button, recolours the matching part rect to the burgundy mute (`#c4504c` stroke, `#1d1320` fill), and writes the readout/role/result. The phase→part map is `assemble → lbPart_engine`, `mount → lbPart_web`, `handoff → lbPart_facade`.
- Readout id `lbOut` (`aria-live="polite"`) renders `The <b>{name}</b> phase — <code>{detail}</code>. {desc}` from the `PHASES` table. Role id `lbRole` and result id `lbResult` are also set. VERBATIM phase data:
  - `assemble` → name `Assemble`, detail `the supervised engine, end to end`, desc: `F5.09.1. The Application starts the event-store adapter and the engine under one supervisor; the engine’s init reads its stream through the port and replays it into state, and a command runs facade to engine to store.`
  - `mount` → name `Mount`, detail `a LiveView calls the facade`, desc: `F5.09.2. A LiveView sketch loads state in mount, calls a command in handle_event, and renders from assigns — touching only the Portal facade and the error contract, never the engine or the store.`
  - `handoff` → name `Handoff`, detail `a UI-ready boundary for F6`, desc: `F5.09.3. F6 replaces the thin web layer with Phoenix and adds its endpoint to the supervision tree, but the facade, the closed error contract, and the tests carry over unchanged — the seam holds.`
- Static markup defaults: phase role `Assemble`, result `the supervised engine, end to end`.

Degrade behaviour: the hero figure's static SVG already shows the running engine (`progress: 2/3`, `state folded from 3 events`) and the running readout, so it reads with JS off; the `.hp-row.hp-new` entry animation is suppressed under `prefers-reduced-motion: reduce`. The stack figure ships with `assemble` pre-marked `active` and a `lbRole`/`lbResult` default in markup. Reveal sections (`.reveal`) are JS-gated but visible without JS, and `prefers-reduced-motion` disables the reveal transition.

Footer build-stamp: id `TSK0Nd9oPwy5su` (namespace `TSK`); the panel's `st-ts` decodes to `2026-06-01 18:19:34 UTC`. The decoder splits the 3-char namespace, base62-decodes the snowflake, and shifts out timestamp (`>> 22`, epoch `1704067200000`), node (`>> 12 & 0x3FF`), and seq (`& 0xFFF`).

## References (#refs, verbatim)

Intro line: `The supervision tree, the engine boundary, and the LiveView layer F6 mounts it in.`

Sources:

- `https://hexdocs.pm/elixir/Supervisor.html` — Elixir — Supervisor — the assembled supervision tree.
- `https://hexdocs.pm/elixir/GenServer.html` — Elixir — GenServer — the engine boundary behind the facade.
- `https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html` — Phoenix — LiveView — the UI layer F6 mounts the engine in.
- `https://hexdocs.pm/phoenix/overview.html` — Phoenix — Overview — the framework that replaces the thin server in F6.

Related in this course:

- `/elixir/pragmatic/engine-lab/end-to-end` — F5.09.1 · The engine facade end to end
- `/elixir/pragmatic/engine-lab/mount` — F5.09.2 · A LiveView mount sketch
- `/elixir/pragmatic/engine-lab/handoff` — F5.09.3 · What ships in F6
- `/elixir/pragmatic/boundaries` — F5.08 · Boundaries & integration seams — the boundary this mounts.
- `/elixir/pragmatic/state` — F5.06 · Where engine state lives — the engine this assembles.
- `/elixir/pragmatic/flow` — F5.0.3 · The command & event flow — the runtime path, start to finish.

## Wiring

- route-tag (verbatim): `/ ` `elixir` `/` `pragmatic` `/` `engine-lab` — i.e. `<a href="/elixir">elixir</a>` / `<a href="/elixir/pragmatic">pragmatic</a>` / `<span class="rcur">engine-lab</span>`.
- crumbs (verbatim): `F5 · Pragmatic Programming` (→ `/elixir/pragmatic`) `/` `F5.09 · the lab` (here).
- toc-mini: `#stack` The assembled Portal · `#prompts` Build it with prompts · `#dives` Three deep dives.
- pager: prev → `/elixir/pragmatic` label `F5 · overview`; next → `/elixir/pragmatic/engine-lab/end-to-end` label `Start · the engine facade end to end`.
- footer: column **Chapters** — `/elixir/algebra` (F1 · Algebra), `/elixir/functional` (F2 · Functional Programming), `/elixir/language` (F3 · The Elixir Language), `/elixir/algorithms` (F4 · Algorithms & Data Structures), `/elixir/pragmatic` (F5 · Pragmatic Programming), `/elixir/phoenix` (F6 · Phoenix Framework). Column **The course** — `/elixir` (Course home), `/elixir/course` (Contents & history), `/elixir/algebra/functions` (Start · F1.01). Brand links to `/elixir` with foot-tag `Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir.`
- Page meta — `<title>`: `Lab: the Portal engine, LiveView-ready — F5.09 · jonnify`. `<meta description>`: `The finale assembles eight modules into one running Portal: a supervision tree with the engine behind its facade, fed by an event-store port, mounted behind a LiveView sketch, with the handoff to F6 stated. It ships with a spec and copy-paste build prompts that generate the Portal logic end to end. Three dives: the engine facade end to end, a LiveView mount sketch, and what ships in F6.`

## Build instruction

To rebuild this page, copy the `<head>…</style>`, the `<header class="site">`, the `<footer class="site-foot">`, and both trailing `<script>` blocks verbatim from a recent built sibling on this burgundy chapter — the model sibling is `elixir/pragmatic/engine-lab/end-to-end.html` (same chapter, same accent, same stamp/reveal machinery). Change only the `<title>`/`<meta description>`, the `route-tag` (ending in `<span class="rcur">engine-lab</span>` with no deeper segment, since this is the hub), and the `<main>` body (hero with the `.hero-art` figure, `#stack`, `#prompts`, `#dives`, references, pager). No-invent guards: use only the real Portal surfaces as written — the branded store, an event-sourced engine behind ONE `Portal` facade (`enroll`, `deliver_lesson`, `progress_of`), the `EventStore` port (`append`, `read_stream`) with a Postgres/InMemory adapter, `decide`/`evolve`/`replay`, the closed `%Portal.Error{}` contract, and the Phoenix web app added only in F6; cite the companion course for OTP internals rather than re-teaching `Supervisor`/`GenServer`. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously.
