# F5.09.2 — A LiveView mount sketch (dive)

- Route (served): `/elixir/pragmatic/engine-lab/mount`
- File: `elixir/pragmatic/engine-lab/mount.html`
- Place in the chapter: second of the three dives under the F5.09 lab. After the engine is assembled end to end (F5.09.1), this dive puts a LiveView on top of the facade — the same boundary, now viewed from the web — before the handoff to F6 (F5.09.3).
- Accent: burgundy (the F5 · Pragmatic Programming chapter accent; `--burgundy:#c4504c`). The interactive uses the F5.09.2 blue (`#9fc0ea` / `#5a87c4`) to match its dive-card border.
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F5.09 · part 2 of 3`

H1 (verbatim): A LiveView mount sketch

Hero lede (verbatim):

> The facade was built to be called by a UI, and a LiveView is that UI. This is a sketch — F6 builds the real thing — but it shows the discipline the boundary buys: the LiveView touches only `Portal` and `%Portal.Error{}`, never the engine or the store. `mount/3` loads the starting state with a facade query and puts it in `assigns`. `handle_event/3` turns a click into a facade command and branches on the closed error contract from F5.08.3. `render/1` draws from `assigns` and knows nothing about how progress is computed. The loop — event, command, re-assign, re-render — is the whole of how a LiveView and the engine talk.

Kicker (verbatim):

> Three callbacks, one boundary. Select a callback to see what it does and which facade function it calls.

## Sections

In order:

1. `#callbacks` — Three callbacks at the edge (teaching). The three LiveView callbacks and the rule that each reaches the engine only through the facade; carries the interactive callback-selector figure.
2. `#code` — Mount and handle_event. The `PortalWeb.EnrollmentLive` module: `mount/3` loads via a query, `handle_event/3` issues a command, both branching on `%Portal.Error{}`.
3. `#render` — Render from assigns. A `render/1` whose `~H` template draws only from `assigns`, with `:if` guards.
4. `#loop` — The event loop. The event → command → re-assign → re-render cycle; carries the loop diagram, a bridge, and the forward note.
5. `#comp` (advanced; `A function component for engine state`) — factors the markup into a named function component declared with `Phoenix.Component` and `attr`, fed by two facade queries (`progress_of/1`, `next_lesson_for/1`); carries the `engine state → assigns → markup` diagram.

Running example: the Portal enrollment LiveView — `Portal.progress_of/1`, `Portal.deliver_lesson/2`, `Portal.next_lesson_for/1`, the `deliver_lesson` event, and a `progress_card` function component.

Real Elixir code shown:

- `PortalWeb.EnrollmentLive` — `use PortalWeb, :live_view`; `alias Portal.Error`; `mount/3` casing `Portal.progress_of(enrollment_id)` into `assign(socket, …)` or the error branch `{:error, %Error{message: msg}}`; `handle_event("deliver_lesson", …)` casing `Portal.deliver_lesson(...)` into `{:ok, percent} = Portal.progress_of(...)` re-assign or the error branch.
- `render/1` — `~H` template `<section class="enrollment">` with `<h1>Your progress</h1>`, `<p :if={@error} class="flash">{@error}</p>`, `<progress :if={@progress} value={@progress} max="100">{@progress}%</progress>`, and a `<button phx-click="deliver_lesson" phx-value-lesson={@next_lesson}>Mark lesson done</button>`.
- `PortalWeb.EnrollmentComponents` — `use Phoenix.Component`; `attr :progress, :integer, default: nil`; `attr :error, :string, default: nil`; `attr :next_lesson, :string, required: true`; `def progress_card(assigns)` returning the same `~H` markup with no `Portal`/engine/`%Error{}` mention.
- The `render/1` call site — `import PortalWeb.EnrollmentComponents` then `<.progress_card progress={@progress} error={@error} next_lesson={@next_lesson} />`, with a worked comment showing `@progress = 60, @error = nil, @next_lesson = "m3-evolve"` rendering server-rendered markup.

## The interactives

One interactive figure plus two static diagrams.

### Callback figure — `LiveView callbacks · select one` (`#mtTitle`)

- `<figure class="fig">` labelled by `mtTitle`.
- Control group id `mtSel` (`role="group"`, `aria-label="LiveView callback"`), three buttons with `data-k`: `mount` (active default, `mount/3`), `event` (`handle_event/3`), `render` (`render/1`).
- SVG (`viewBox="0 0 720 200"`) draws three highlightable rows: `mtRow_mount` (`MOUNT/3 · once`, `Portal.progress_of(id) → assign(socket, progress: ...)`, side label `query`, default blue-highlighted), `mtRow_event` (`HANDLE_EVENT/3 · per action`, `Portal.deliver_lesson(...) → case :ok / {:error, %Error{}}`, side label `command`), `mtRow_render` (`RENDER/1 · on change`, `~H from @progress, @error — no engine details`, side label `assigns`).
- Pure function `pick(k)`: toggles active button, recolours the matching row to blue (`#5a87c4` stroke, `#11203a` fill), and writes the readout/role/result from the `CBS` table.
- Readout id `mtOut` (`aria-live="polite"`) renders `<b>{name}</b> — {detail}. {desc}`. Role id `mtRole`, result id `mtResult`. VERBATIM callback data:
  - `mount` → name `mount/3`, detail `loads state via a query`, desc: `Runs once when the LiveView connects. It calls Portal.progress_of — a facade query — and puts the result in assigns, or assigns the error message if the query returns a typed error. No engine, no store.`
  - `event` → name `handle_event`, detail `calls a command, branches on the result`, desc: `Runs on each user action. It turns a click into Portal.deliver_lesson — a facade command — and branches on the closed error contract: on :ok it re-queries and re-assigns, on {:error, %Error{}} it assigns the message.`
  - `render` → name `render/1`, detail `shows assigns, no engine details`, desc: `Runs whenever assigns change. It draws from @progress and @error only, with :if guards so both the loaded and the error cases render something. It never names the engine, the log, or how progress is computed.`
- Static markup defaults: role `mount/3`, result `loads state via a query`.

### Loop diagram — `event → command → re-render` (`#mtLoopTitle`)

Static SVG (`viewBox="0 0 720 170"`): `RENDER` (`assigns → DOM`) —`phx-click`→ `HANDLE_EVENT` (`Portal.deliver_lesson`, blue) —`command`→ `FACADE` (`:ok | {:error}`), with a return path captioned `re-assign · re-render — the loop never reaches past the facade`.

### Mapping diagram — `engine state → assigns → markup` (`#compMapTitle`)

Static SVG (`viewBox="0 0 720 150"`): `ENGINE STATE` (`progress_of/1 → {:ok, percent}`, `next_lesson_for/1 → {:ok, id}`, `@progress · @next_lesson`) → `ASSIGNS` (`@progress, @error, @next_lesson`, sage) → `MARKUP` (`<.progress_card>`, `~H via attr`), captioned `two queries hand over` / `attr-checked`.

Degrade behaviour: the callback figure ships with `mount` pre-marked `active` and `mtRole`/`mtResult` defaults in markup; `pick('mount')` runs on load. The loop and mapping diagrams are static. The advanced component section and references are `.reveal` (visible without JS; `prefers-reduced-motion: reduce` disables the reveal transition). No per-figure motion beyond reveal.

Footer build-stamp: id `TSK0Nd9oQPLytM` (namespace `TSK`); the panel's `st-ts` decodes to `2026-06-01 18:19:34 UTC`. Decoder as on the hub (base62 snowflake; timestamp `>> 22` over epoch `1704067200000`, node `>> 12 & 0x3FF`, seq `& 0xFFF`).

## References (#refs, verbatim)

Intro line: `Primary sources for this lesson, and where it connects in the course.`

Sources:

- `https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html` — Phoenix — Phoenix.LiveView — server-rendered, stateful UI over the engine.
- `https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html` — Phoenix — Phoenix.Component (HEEx) — function components and the HEEx template.
- `https://hexdocs.pm/elixir/Supervisor.html` — Elixir — Supervisor — the engine runs under a supervision tree.

Related in this course:

- `/elixir/pragmatic/engine-lab` — F5.09 · the Portal engine lab
- `/elixir/pragmatic/boundaries/facade` — F5.08 · the facade boundary
- `/elixir/pragmatic/engine-lab/end-to-end` — F5.09.1 · end to end

## Wiring

- route-tag (verbatim): `<a href="/elixir">elixir</a>` / `<a href="/elixir/pragmatic">pragmatic</a>` / `<a href="/elixir/pragmatic/engine-lab">engine-lab</a>` / `<span class="rcur">mount</span>`.
- crumbs (verbatim): `F5` (→ `/elixir/pragmatic`) `/` `F5.09` (→ `/elixir/pragmatic/engine-lab`) `/` `mount` (here).
- toc-mini: `#callbacks` Three callbacks at the edge · `#code` Mount and handle_event · `#render` Render from assigns · `#loop` The event loop.
- pager: prev → `/elixir/pragmatic/engine-lab/end-to-end` label `F5.09.1 · end to end`; next → `/elixir/pragmatic/engine-lab/handoff` label `Next · what ships in F6`.
- footer: column **Chapters** — `/elixir/algebra`, `/elixir/functional`, `/elixir/language`, `/elixir/algorithms`, `/elixir/pragmatic`, `/elixir/phoenix` (F1–F6). Column **The course** — `/elixir`, `/elixir/course`, `/elixir/algebra/functions`. Same foot-tag as the hub.
- Page meta — `<title>`: `A LiveView mount sketch — F5.09.2 · jonnify`. `<meta description>`: `A LiveView that touches only the facade: mount/3 loads state with a query, handle_event/3 issues a command and branches on the closed error contract, and render/1 draws from assigns. The event loop — click, command, re-assign, re-render — never reaches past Portal and %Portal.Error{}.`

## Build instruction

To rebuild this page, copy the `<head>…</style>`, the `<header class="site">`, the `<footer class="site-foot">`, and both trailing `<script>` blocks verbatim from a recent built sibling on this burgundy chapter — the model sibling is `elixir/pragmatic/engine-lab/end-to-end.html` (same lab, same accent, identical stamp/reveal/`solid-select` machinery; this dive only re-colours the figure to the F5.09.2 blue and adds the advanced function-component section). Change only the `<title>`/`<meta description>`, the `route-tag` (ending in `<span class="rcur">mount</span>`), and the `<main>` body (hero, `#callbacks`, `#code`, `#render`, `#loop`, the function-component `.reveal`, references, pager). No-invent guards: use only the real Portal surfaces as written — the LiveView (`PortalWeb.EnrollmentLive`) and components (`PortalWeb.EnrollmentComponents`) touch ONLY the `Portal` facade (`progress_of/1`, `deliver_lesson/2`, `next_lesson_for/1`) and the closed `%Portal.Error{}` contract, never the engine or store; the `attr`-declared `progress_card/1` is a pure function from assigns to `~H`; cite Phoenix's `Phoenix.LiveView`/`Phoenix.Component` rather than re-teaching them. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously.
