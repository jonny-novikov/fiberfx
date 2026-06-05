# F6.06 — Phoenix LiveView fundamentals (module hub)

- Route (served): `/elixir/phoenix/liveview`
- File: `elixir/phoenix/liveview/index.html`
- Place in the chapter: the sixth module hub of the F6 · Phoenix Framework chapter (F6.06), opening Milestone 2 ("make it live"). It frames the three deep dives that make F6.05's server-rendered catalog interactive without reloads — `mount` & assigns, `handle_event` & state, and `render` & diffs — over the same HEEx and the same `Portal` contexts. It follows `/elixir/phoenix/heex` (F6.05) and precedes F6.07 (PubSub).
- Accent: blue (the F6 · Phoenix chapter accent; the `<h1 .ex>` word "LiveView" renders in `--elixir-bright`).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F6 · the architecture · module 6`

`<h1>` (verbatim): Phoenix `LiveView` fundamentals (the word "LiveView" is the `.ex` accent span).

Hero lede (`.lede`, verbatim):

> Everything so far has been one stateless round trip: a request arrives, a controller builds a response, HEEx renders it, the connection closes. LiveView changes the shape. A LiveView is a **stateful server process** connected to the browser over a WebSocket — an OTP process, the same kind of long-lived, message-driven actor the F5 engine was built from. It holds **socket assigns** as its state, renders the same HEEx from F6.05 as a function of those assigns, and when state changes it re-renders and pushes only the **diff** down the wire. The lifecycle is small and regular: `mount/3` sets the initial state, `render/1` produces markup, `handle_event/3` turns a browser event into new state, and the loop continues. You write no JavaScript for the common interactions — a search box, a button, a live-updating list — because the server holds the state and the client only applies diffs. The same contexts from F6.04 still supply the data; LiveView adds the statefulness and the live connection on top of the view you already have.

Kicker (`.kicker`, verbatim):

> Three dives: mounting a LiveView and its socket assigns, handling events to update state, and how render diffs reach the browser — the interactive layer over the same HEEx and contexts.

## What the page frames

This is a module hub, not a chapter landing. There is no `.mods` grid; the three dives are presented as a vertical stack of full-width `<a>` cards under the `#dives` section (each card a left-accent-bordered link), and re-listed under `#refs` "Related in this course". All three are built.

- F6.06.1 · mount & assigns — "The socket as process state, `mount/3`, the two-stage connect, and `connected?/1` for side effects." → `/elixir/phoenix/liveview/mount` — built (left accent `--blue`).
- F6.06.2 · handle_event & state — "`phx-click`, `phx-change`, `phx-submit` into `handle_event/3`, a live search box, and a live create form." → `/elixir/phoenix/liveview/events` — built (left accent `--gold`).
- F6.06.3 · render & diffs — "Change tracking on the HEEx static/dynamic split, the diff over the wire, and streams for large collections." → `/elixir/phoenix/liveview/render` — built (left accent `--sage`).

Two further teaching sections precede the dives: `#pieces` ("Three parts of the loop") and `#shift` ("From request to process"). The closing `.bridge` (verbatim): "F5 gave us — OTP processes — stateful actors that hold state and respond to messages." `→` "LiveView is — that actor with a browser attached and HEEx as its rendered state." The `.note` after the dives (verbatim): "Start with `mount and assigns`, then `handle_event and state`, then `render and diffs`. This module follows F6.05 — `HEEx` — whose templates it now renders live, and the next, F6.07, adds PubSub so many LiveViews update at once."

## The interactives

This hub carries two interactive `<figure>`s plus the footer build-stamp decoder.

### Hero figure — "One turn of the live loop" (`#hpScene`)

- `<figure class="hero-fig" aria-labelledby="hpTitle">`; figcaption `.fc-lbl#hpTitle` text "One turn of the live loop".
- Controls (`.hp-ctrls`): `<button id="hpStepBtn">▸ advance loop</button>` and `<button id="hpReset" class="ghost">reset</button>`.
- SVG element ids: phase boxes `.hp-phase[data-phase="0..3"]`; moving cursor `#hpCursor`; socket-assign value `#hpCount` (default `0`); rendered-HEEx value `#hpOut` (default `0`); phase label `#hpPhaseLbl` (default `mount/3`); step counter `#hpStep` (default `step 1 / 4`); live caption `#hpCap`.
- Phase order (`PHASES`, the cursor walks these): `mount/3` → `render/1` → `handle_event/3` → `diff ↔ socket`. The `@count` assign bumps only when the cursor reaches phase 2 (`handle_event/3`); `flash()` re-triggers the change animation on `#hpCount`/`#hpOut`.
- Pure functions: `render(opts)` repositions the cursor, lights the active phase via `lightPhase(active)`, and writes the count, step label, and caption; `flash(el)` restarts the `hp-changed` animation by removing/re-adding the class and forcing a `getBBox()` reflow.
- Caption strings (verbatim): default in markup `mount/3 — @count = 0, rendered as "Clicked 0"` / hint `Advance once to walk the cursor; a click reaches handle_event, bumps the assign, and only the diff returns.` Per-phase notes (`PHASES[].note`, verbatim): mount/3 — `mount/3 set the initial assign — @count = 0 — then the loop falls through to render.`; render/1 — `render/1 projected the assigns into HEEx — "Clicked N" reflects @count.`; handle_event/3 — `A phx-click sent "inc"; handle_event/3 bumped @count and returned {:noreply, socket}.`; diff ↔ socket — `Change tracking sent only the changed value over the socket; render runs next.`
- Degrade: the static SVG already shows the cursor on `mount/3` with `@count = 0` rendered ("No render on load"); JS only enhances. `prefers-reduced-motion: reduce` disables the cursor transition and the `hpIn` animation. No browser storage.

### Section figure — "The LiveView loop · select a part" (`#lvSel` + `#lvOut`)

- `<figure class="fig" aria-labelledby="lvTitle">`; `<h4 id="lvTitle">` text "The LiveView loop · select a part".
- Control group `.solid-select#lvSel` (role="group"), three buttons with `data-k`: `mount` (starts `active`), `event`, `render`. (No `data-c` on these buttons — the F5/F6 active-tab attribute note applies.)
- SVG row ids: `#lvRow_mount`, `#lvRow_event`, `#lvRow_render`; below the figure, readout `.geo-readout#lvOut`, plus `#lvRole` (default `mount/3`) and `#lvResult` (default `set the socket's initial state`).
- Pure function: `pick(k)` toggles the active button + `aria-pressed`, re-strokes the three rows (active row `stroke #5a87c4`, width `2`, fill `#11203a`), and writes `#lvRole`, `#lvResult`, and `#lvOut`. Initial call `pick('mount')`.
- `PARTS` data (`name` / `does` / `desc`, verbatim):
  - mount: name `mount/3`, does "set the socket's initial state", desc "mount/3 runs when the LiveView starts and assigns the initial state — usually data from the facade. It runs twice: a disconnected HTTP render, then a connected mount over the socket."
  - event: name `handle_event/3`, does "update state on an event", desc "handle_event/3 receives a named event from a binding like phx-click, transforms the socket assigns, and returns {:noreply, socket}. The state change triggers a re-render automatically."
  - render: name `render/1`, does "diff and push over the socket", desc "render/1 returns HEEx as a function of assigns. LiveView tracks which assigns changed and sends only those values over the socket — the static markup is never re-sent."
- Degrade: `#lvOut` is empty in markup and filled by `pick('mount')` on load; the SVG rows render statically. No storage; `prefers-reduced-motion` respected globally.

### Second teaching figure — "Stateless request vs stateful LiveView" (`#lvShiftTitle`)

- `<figure class="fig" aria-labelledby="lvShiftTitle">`, a static (non-interactive) diagram contrasting a controller request that "request → response / connection closes — nothing persists" against a LiveView's three-step "disconnected HTTP render (first paint) / socket connects — process holds state / diffs ↔ browser, over the wire". No controls or pure functions.

### Footer build-stamp decoder (`#stamp`)

- Stamp id `TSK0NdUKtdLpLs` (in `#stampId`); panel `#st-ts` hard-codes "2026-06-01 23:06:46 UTC".
- Decoded: `ns=TSK`, `snowflake=319975090093555712`, `node=0`, `seq=0`, timestamp `2026-06-01 23:06:46 UTC` (epoch `EPOCH_MS = 1704067200000`).
- Functions: `b62decode(s)`, `pad2(x)`, `decodeBranded(id)` (splits `ns = id.slice(0,3)`, `snow = b62decode(id.slice(3))`, then `ts = snow >> 22n`, `node = (snow >> 12n) & 0x3FFn`, `seq = snow & 0xFFFn`). Toggle on click / Enter / Space sets `.open` and `aria-expanded`.

## References (#refs, verbatim)

Intro line: "The LiveView programming model, its callbacks, bindings, and change tracking."

Sources
- `https://hexdocs.pm/phoenix_live_view/welcome.html` — Phoenix LiveView — Welcome — the LiveView programming model.
- `https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html` — Phoenix.LiveView — `mount/3`, `handle_event/3`, and the socket.
- `https://hexdocs.pm/phoenix_live_view/bindings.html` — Phoenix LiveView — Bindings — `phx-click`, `phx-change`, `phx-submit`.
- `https://hexdocs.pm/phoenix_live_view/assigns-eex.html` — Phoenix LiveView — Assigns & change tracking — how diffs are computed.

Related in this course
- `/elixir/phoenix/liveview/mount` — F6.06.1 · mount & assigns
- `/elixir/phoenix/liveview/events` — F6.06.2 · handle_event & state
- `/elixir/phoenix/liveview/render` — F6.06.3 · render & diffs
- `/elixir/phoenix/heex` — F6.05 · HEEx — the templates a LiveView renders.
- `/elixir/phoenix` — F6 · Phoenix Framework

## Wiring

- route-tag (verbatim, segmented): `/` `elixir` `/` `phoenix` `/` `liveview` (the `liveview` segment is the current `.rcur`; `elixir` and `phoenix` are links).
- crumbs (verbatim): `F6 · Phoenix Framework` → `/elixir/phoenix` · sep `/` · here `F6.06 · liveview` (no link).
- toc-mini: `#pieces` ("Three parts of the loop") · `#shift` ("From request to process") · `#dives` ("Three deep dives").
- pager: prev → `/elixir/phoenix/heex` ("← F6.05 · HEEx"); next → `/elixir/phoenix/liveview/mount` ("Start · mount & assigns →").
- footer (`.foot-nav`, three columns):
  - brand: `.foot-logo` → `/elixir`; `.foot-tag` "Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir."
  - Chapters: `/elixir/algebra` (F1 · Algebra), `/elixir/functional` (F2 · Functional Programming), `/elixir/language` (F3 · The Elixir Language), `/elixir/algorithms` (F4 · Algorithms & Data Structures), `/elixir/pragmatic` (F5 · Pragmatic Programming), `/elixir/phoenix` (F6 · Phoenix Framework).
  - The course: `/elixir` (Course home), `/elixir/course` (Contents & history), `/elixir/algebra/functions` (Start · F1.01).
- Page meta: `<title>` "Phoenix LiveView fundamentals — F6.06 · jonnify"; `<meta description>` "LiveView makes the F6.05 templates live: instead of a stateless request, a stateful server process holds the socket assigns, renders HEEx from them, and pushes only the diff over a WebSocket on every change. Three dives: mount and assigns, handle_event and state, and render and diffs — the same HEEx and the same contexts, now interactive without hand-written JavaScript."

## Build instruction

To rebuild this page, copy the `<head>`…`</style>`, `<header class="site">`, the `<footer class="site-foot">`, and the two trailing `<script>` blocks verbatim from a recent BUILT F6 (blue-accent) sibling, then change only the `<title>`/`<meta description>`, the segmented `.route-tag`, and the `<main>` body. The model sibling for this hub is `/elixir/phoenix/heex` (`elixir/phoenix/heex/index.html`) — the preceding F6.05 module hub on the same blue accent and the same hub anatomy (hero figure + a `.solid-select` loop figure + a vertical dive-card stack + bridge + note). No-invent guards: use only the real Portal surfaces as written — a branded store, an event-sourced engine behind ONE `Portal` facade (`Portal.search_courses/1`, `Portal.progress_of/1`, `Portal.create_course/1`, `Portal.list_courses/0`), the closed `%Portal.Error{}` set, and the Phoenix web app (`PortalWeb`, `CatalogLive`); cite the F5 companion (`/elixir/pragmatic`, `/elixir/language`) for OTP/GenServer internals rather than re-teaching them. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously.
