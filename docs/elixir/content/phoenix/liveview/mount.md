# F6.06.1 — mount & assigns (dive)

- Route (served): `/elixir/phoenix/liveview/mount`
- File: `elixir/phoenix/liveview/mount.html`
- Place in the chapter: the first of the three F6.06 (LiveView) deep dives. It opens the LiveView lifecycle — the socket as process state and `mount/3` as the callback that sets the first state — and is the foundation the other two dives read from (`events` turns a browser event into new assigns; `render` ships only the diff). It belongs to the "make it live" arc of Milestone 2.
- Accent: blue (F6 · Phoenix; `<h1 .ex>` word "assigns" in `--elixir-bright`).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F6.06 · part 1 of 3`

`<h1>` (verbatim): mount & `assigns` (the word "assigns" is the `.ex` accent span).

Hero lede (`.lede`, verbatim):

> A LiveView is a stateful process connected to the browser over a socket, and `mount/3` is the one callback that gives it its first state.

Kicker (`.kicker`, verbatim):

> The `socket` is the process state. `mount/3` receives the route params, the session, and that socket, and returns `{:ok, socket}` — the LiveView analogue of a GenServer `init/1` from F5. It runs in two stages: a disconnected HTTP render for the first paint, then a connected render once the socket is established, so `connected?/1` guards the side effects that must happen exactly once. Assigns go on with `assign/3`, or with `assign_new/4` when a value should be computed only if it is not already present.

## Sections

Teaching sections in order:

1. `#socket` — "The socket is the state". Prose + a `.deflist` defining `socket` (`%Phoenix.LiveView.Socket{}`), `assigns`, `mount/3`, and `connected?/1`.
2. `#twostage` — "The two-stage connect". Carries the page's one interactive figure (the stage drag).
3. `#assigns` — "assign and assign_new". A `pre.code` block contrasting `assign/3` (unconditional) and `assign_new/4` (set only if absent), with a `.note` on the keyword-list form.
4. `#code` — "mount, on the Portal". The Elixir `pre.code` showing `mount/3` on `PortalWeb.EnrollmentLive`.
5. `#downstream` — "Why it matters". A `.bridge` (F5 GenServer `init/1` → F6 LiveView `mount/3`), a "Recap" `<ul>`, and the closing `.note`.

Running example: `PortalWeb.EnrollmentLive` — a LiveView for one enrollment that loads state via the `Portal` facade.

Real Elixir code shown:
- Assign helpers block — `assign(socket, :progress, 42)` returns a new socket (`# => 42`); `assign_new(socket, :progress, fn -> 99 end)` keeps the existing value (`# => 42 (kept; the fun is not called)`).
- `PortalWeb.EnrollmentLive` block — `use PortalWeb, :live_view`; `alias Portal.Error`; `def mount(%{"id" => enrollment_id}, _session, socket)`; one-time side effect `if connected?(socket), do: Process.send_after(self(), :refresh, 30_000)`; a `case Portal.progress_of(enrollment_id)` matching `{:ok, percent}` (`# percent :: 0..100`) and `{:error, %Error{message: msg}}` (`# the closed error contract`), each calling `assign(socket, enrollment_id: ..., progress: ..., error: ...)`. Closing comments: `# iex> {:ok, socket} = EnrollmentLive.mount(%{"id" => "enr_42"}, %{}, socket)` … `# => 42`.

## The interactives

### Figure — "The two-stage connect · drag through it" (`#stageRange` + `#mtOut`)

- `<figure class="fig" aria-labelledby="mtTitle">`; `<h4 id="mtTitle">` text "The two-stage connect · drag through it".
- Control: a `.fold-ctrl` range slider `#stageRange` (`min=0 max=1 step=1 value=0`, `aria-describedby="mtOut"`), with value display `#stageVal` (default `1 / 2`).
- SVG element ids: stage box `#stg1` (disconnected HTTP, active at start), stage box `#stg2` (connected socket); `connected?` lines `#c1`/`#c2`; stage-2 label `#s2lab`; stage-2 note `#s2note`. Below the figure: readout `.geo-readout#mtOut`, plus `#mtRole` (default `disconnected HTTP`) and `#mtFlag` (default `false`).
- Pure function: `paint(i)` re-strokes `#stg1`/`#stg2` (the active box gets `stroke #5a87c4`, width `2`, fill `#11203a`), recolors the `connected?` lines and labels, and writes `#stageVal`, `#mtRole`, `#mtFlag`, and `#mtOut`. Wired on the slider's `input` event; initial call `paint(0)`.
- `STAGES` data (`role` / `flag` / `desc`, verbatim):
  - stage 0: role "disconnected HTTP", flag "false", desc "Stage 1 — the first request is plain HTTP. mount/3 runs, renders the markup once, and sends static HTML for a fast, indexable first paint. No socket is open, so connected?(socket) is false and any side effect guarded by it is skipped."
  - stage 1: role "connected socket", flag "true", desc "Stage 2 — the browser opens a WebSocket and mount/3 runs again, now live. The process stays alive and exchanges diffs. connected?(socket) is true, so this is the run where one-time work — subscriptions, timers — starts, exactly once."
- Static SVG strings worth noting (verbatim): `#c1` "connected?(socket) == false", `#c2` "connected?(socket) == true".
- Degrade: `#mtOut` is empty in markup and filled by `paint(0)` on load; the SVG renders statically with stage 1 active. No browser storage; `prefers-reduced-motion` respected globally.

### Footer build-stamp decoder (`#stamp`)

- Stamp id `TSK0NdUKtdLpLs` (in `#stampId`); panel `#st-ts` hard-codes "2026-06-01 23:06:46 UTC".
- Decoded: `ns=TSK`, `snowflake=319975090093555712`, `node=0`, `seq=0`, timestamp `2026-06-01 23:06:46 UTC` (epoch `EPOCH_MS = 1704067200000`).
- Functions: `b62decode(s)`, `pad2(x)`, `decodeBranded(id)` (`ts = snow >> 22n`, `node = (snow >> 12n) & 0x3FFn`, `seq = snow & 0xFFFn`). Toggle on click / Enter / Space sets `.open` and `aria-expanded`.

## References (#refs, verbatim)

Intro line: "The mount callback, the socket, and the assign helpers."

Sources
- `https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#c:mount/3` — `mount/3` — Phoenix.LiveView — params, session, socket, and the two-stage connect.
- `https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#connected?/1` — `connected?/1` — Phoenix.LiveView — guarding one-time side effects.
- `https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html#assign/3` — `assign/3` & `assign_new/4` — Phoenix.Component — writing the socket assigns.

Related in this course
- `/elixir/phoenix/liveview` — F6.06 · Phoenix LiveView fundamentals
- `/elixir/phoenix/liveview/events` — F6.06.2 · handle_event & state
- `/elixir/phoenix/liveview/render` — F6.06.3 · render & diffs
- `/elixir/language/otp/genserver` — F5 · GenServer — `init/1` and the callback loop
- `/elixir/phoenix/lifecycle/controllers` — F6.01.3 · the facade seam the mount reuses

## Wiring

- route-tag (verbatim, segmented): `/` `elixir` `/` `phoenix` `/` `liveview` `/` `mount` (the `mount` segment is the current `.rcur`; `elixir`, `phoenix`, `liveview` are links).
- crumbs (verbatim): `F6` → `/elixir/phoenix` · sep `/` · `F6.06` → `/elixir/phoenix/liveview` · sep `/` · here `mount` (no link).
- toc-mini: `#socket` ("The socket is the state") · `#twostage` ("The two-stage connect") · `#assigns` ("assign and assign_new") · `#code` ("mount, on the Portal") · `#downstream` ("Why it matters").
- pager: prev → `/elixir/phoenix/liveview` ("← F6.06 · liveview"); next → `/elixir/phoenix/liveview/events` ("Next · handle_event & state →").
- footer (`.foot-nav`, three columns):
  - brand: `.foot-logo` → `/elixir`; `.foot-tag` "Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir."
  - Chapters: `/elixir/algebra`, `/elixir/functional`, `/elixir/language`, `/elixir/algorithms`, `/elixir/pragmatic`, `/elixir/phoenix` (F1–F6, same labels as the hub).
  - The course: `/elixir` (Course home), `/elixir/course` (Contents & history), `/elixir/algebra/functions` (Start · F1.01).
- Page meta: `<title>` "mount & assigns — F6.06.1 · jonnify"; `<meta description>` "A LiveView is a stateful process connected to the browser over a socket. mount/3 returns its initial state, and it runs twice — once for the disconnected HTTP first paint, once for the connected socket — so connected?(socket) guards the one-time side effects, exactly as a GenServer init/1 sets up a process once."

## Build instruction

To rebuild this page, copy the `<head>`…`</style>`, `<header class="site">`, the `<footer class="site-foot">`, and the two trailing `<script>` blocks verbatim from a recent BUILT F6 (blue-accent) dive, then change only the `<title>`/`<meta description>`, the segmented `.route-tag`, and the `<main>` body. The model sibling is `/elixir/phoenix/liveview/events` (`elixir/phoenix/liveview/events.html`) — its lesson-hero `.lede`/`.kicker` typography, the same four-section deeper-standard layout, the same `.deflist`/`.bridge`/Recap furniture, and the same blue accent. No-invent guards: use only the real Portal surfaces as written — `Portal.progress_of/1`, the closed `%Portal.Error{}` set, `PortalWeb` `:live_view`, the `socket`/`assigns`/`mount/3`/`connected?/1`/`assign/3`/`assign_new/4` LiveView surface — and the branded store / one-facade / event-sourced engine model; cite the F5 companion (`/elixir/language/otp/genserver`) for GenServer `init/1` internals rather than re-teaching them. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously.
