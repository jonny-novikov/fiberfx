# F6.09 — The live dashboard (module hub)

- **Route (served):** `/elixir/phoenix/live-dashboard`
- **File:** `elixir/phoenix/live-dashboard/index.html`
- **Place in the chapter:** the capstone module of F6 · Phoenix Framework — the ninth and final rung, where the whole chapter converges into one read-only live screen. It frames three deep dives (`build`, `stream`, `multi-client`) and sits last in the F6 arc, after F6.08 deployment, over the F5 engine beneath it.
- **Accent:** blue (the F6 · Phoenix chapter accent; the `<h1>` accent word `dashboard` carries `class="ex"` in `--elixir` lilac per the shared token, while the chapter family colour throughout the figures is `--blue`/`#5a87c4`).
- **Status:** built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F6 · the capstone lab · module 9`.

`<h1>`: "The live `dashboard`" (the word `dashboard` is the `.ex` accent span).

Hero lede (`.lede`, verbatim):

> This is the lab where the whole course converges. The goal is a real-time operations dashboard: a single screen that shows how many courses and enrollments exist, a live feed of what is happening, and how many people are watching right now — all updating the instant anything changes, for everyone at once, with no reload. Nothing here is new machinery. The dashboard is a **LiveView** (F6.06) holding a small **read model** on its socket: counts **seeded from the contexts** (F6.04) at mount, plus a capped **stream** for the activity feed. It comes alive because the **engine emits domain events** (F5) and the domain **broadcasts** them on a topic (F6.07); the dashboard subscribes on its connected mount and, in `handle_info/2`, *folds* each event into the read model — bump a count, prepend a feed row. Because one broadcast fans out to every subscribed LiveView, every open dashboard updates together, and **Presence** turns "who is subscribed" into a live viewer count. Protected by the auth from F6.08 and clustered across nodes in production, it is the same supervised system you have built all along — now observing itself in real time.

Kicker (`.kicker`, verbatim):

> Three dives: build the dashboard as a read model, broadcast engine events into it, and serve many clients live — F5, F6.04, F6.06, F6.07, and F6.08, wired into one screen.

## What the page frames

The hub is not a `.mods` card grid; it frames its three dives through the `#dives` section as `<a>` deep-dive cards (each on a left accent stripe), plus two narrative sections (`#pieces`, `#converge`) that restate the same three-move arc.

The three deep dives:

- **F6.09.1 · Build the dashboard** — "A LiveView read model: counts seeded from the F6.04 contexts at mount, a capped stream for the feed, and the render." → `/elixir/phoenix/live-dashboard/build` — built (blue stripe).
- **F6.09.2 · Broadcast engine events** — "Subscribe on the connected mount, then fold each broadcast into the read model in `handle_info/2`." → `/elixir/phoenix/live-dashboard/stream` — built (gold stripe).
- **F6.09.3 · Many clients, live** — "One broadcast, every dashboard; a `Presence` viewer count; read-only, clustered across nodes." → `/elixir/phoenix/live-dashboard/multi-client` — built (sage stripe).

`#pieces` ("Three moves of the lab") prose (verbatim): "The lab is three moves, one per dive. **Build** the dashboard LiveView and seed its read model from the contexts. **Broadcast** engine events and fold them in as they arrive. Serve **many clients** so every viewer stays in sync, with a live count. Select a move."

`.bridge` cells (verbatim): left "eight modules of parts" / "an engine, contexts, routing, templates, LiveView, PubSub, and a deploy." → right "one live screen" / "the dashboard assembles them into a real-time view of the running system."

`.note` (verbatim): "Start with [building the dashboard](/elixir/phoenix/live-dashboard/build), then [broadcasting engine events](/elixir/phoenix/live-dashboard/stream), then [many clients, live](/elixir/phoenix/live-dashboard/multi-client). This is the final module of the Phoenix chapter and of the course — the capstone over everything in [F6](/elixir/phoenix) and the F5 engine beneath it."

## The interactives

This hub carries the hero concept figure, one selector figure, one static convergence diagram, and the footer build-stamp decoder.

### Hero figure — "One event, every dashboard live" (`#hpScene`, `#hpEmit`/`#hpReset`)

- **`<figure class="hero-fig" aria-labelledby="hpTitle">`** titled (`#hpTitle`, `.fc-lbl`) "One event, every dashboard live". Inline `<svg viewBox="0 0 340 290">` with the scene group `#hpScene`.
- **Controls (`.hp-ctrls`):** button `#hpEmit` label "▸ emit event"; ghost button `#hpReset` label "reset". No `data-key` keys — these are emit/reset, not a `.solid-select` group.
- **SVG element ids:** `#hpEvent` (the `:event` token, `.hp-pulse`), `#hpCount` (the enrollments count, static `41`), `#hpFeed` / `#hpFeed0`+`#hpFeed0t` ("enrollment created") / `#hpFeed1`+`#hpFeed1t` ("course published"), `#hpC0`/`#hpC1`/`#hpC2` (the three client mirrors, each static `41`), `#hpWatch` (Presence count, static `3`), `#hpFolded` (static "0 events").
- **Pure functions (inline IIFE):** `render(opts)` computes `count = BASE + folded` where `BASE = 41`; sets `#hpCount`, mirrors the count into all three `#hpC*`, sets `#hpWatch` to `WATCHING` (= 3 clients), writes the feed top row from the `EVENTS` list `['enrollment created','lesson completed','enrollment created','course published','enrollment created']` and the second row, and rewrites `#hpCap`. `flash(el)` re-triggers the `.hp-changed` pulse. `emitBtn` increments `folded` and calls `render({bump:true})`; `resetBtn` sets `folded = 0`.
- **Readout strings (`#hpCap`, `aria-live="polite"`, verbatim default in markup):**
  - `<span class="stg">`: "read model — enrollments 41, 3 clients live"
  - `<span class="art">`: "Emit an event: the engine broadcasts on \"events\", handle_info/2 folds it, and every client mirrors the new count."
  - After an emit (`render`, verbatim JS): stg "event folded → enrollments {count}, {WATCHING} clients live"; art "handle_info/2 bumped the count and prepended \"{top}\"; one diff reached all {WATCHING} dashboards."
- **Degrade:** the static SVG shows the seed state (enrollments 41, three clients mirroring 41, Presence 3, 0 folded) and the default `#hpCap`; there is no `render` on load. `.hp-pulse`/`.hp-changed` animations are gated behind `@media (prefers-reduced-motion: no-preference)` and disabled under `reduce`. No browser storage.

### Section figure — "The lab · select a move" (`#ldSel` selector + `#ldOut` readout)

- **`<figure class="fig" aria-labelledby="ldTitle">`** ("Three moves of the lab" section, `#pieces`); inner `<h4>` "The lab · select a move".
- **Control group `#ldSel`** (`.solid-select`, `role="group"`, `aria-label="Lab move"`), three `<button data-k>`:
  - `data-k="build"` — label "build" — starts `active`
  - `data-k="broadcast"` — label "broadcast"
  - `data-k="clients"` — label "many clients"
- **SVG row ids:** `#ldRow_build` (F6.09.1), `#ldRow_broadcast` (F6.09.2), `#ldRow_clients` (F6.09.3).
- **Pure function:** `pick(k)` toggles the active button + `aria-pressed`, sets each row's `stroke`/`stroke-width`/`fill` (active = `#5a87c4`/`2`/`#11203a`), writes `#ldRole`/`#ldResult`, and renders `#ldOut.innerHTML`. Initial call `pick('build')`. Readout dataset `PARTS` (verbatim `name` · `does` · `desc`):
  - build · "a read model seeded from contexts" · "The dashboard is a LiveView holding a read model on its socket: counts seeded from the F6.04 contexts at mount, plus a capped stream for the activity feed. It renders metric cards and the feed."
  - broadcast · "fold engine events into the read model" · "The domain broadcasts an event on a topic after a write; the dashboard subscribes on its connected mount and folds each event in handle_info/2 — bumping a count and prepending a feed row."
  - clients · "every dashboard in sync, with a count" · "One broadcast fans out to every subscribed dashboard, so all viewers update together, and Presence reports a live count of who is watching — correct across a cluster."
  - `#ldOut` renders as `<b>{name}</b> — {does}. {desc}`. The markup defaults `#ldRole` "build", `#ldResult` "a read model seeded from contexts".
- **Take (`.take`, verbatim):** "The dashboard writes nothing. It seeds from the read side of the domain and then keeps itself current by listening — a projection over the event stream, not another source of truth."

### Static figure — "engine → broadcast → every dashboard, folded & live" (`#ldConvTitle`)

- **`<figure class="fig" aria-labelledby="ldConvTitle">`** (`#converge` "Where the course converges"); `<svg viewBox="0 0 720 226">`, no controls (static diagram): F5 engine → context broadcast "events" → PubSub fan-out → dashboards A/B/C (fold → diff), with the strip "F5 emits · F6.07 broadcasts · F6.06 folds & renders · F6.08 protects & clusters".
- **Take (`.take`, verbatim):** "There is no orchestrator in the middle deciding who needs what. Each dashboard independently folds the same event into its own view, and the runtime delivers the message to all of them. That is the BEAM model, end to end."

### Footer build-stamp decoder (`#stamp`)

- **Stamp id:** `TSK0NdeUSAqxP6` (in `#stampId`); panel `#st-ts` hard-codes "2026-06-02 01:28:51 UTC".
- **Pure functions:** `b62decode(s)` (base62 over `"0123…XYZabc…xyz"` → BigInt); `pad2(x)`; `decodeBranded(id)` — splits `ns = id.slice(0,3)` and `snow = b62decode(id.slice(3))`, then `ts = snow >> 22n`, `node = (snow >> 12n) & 0x3FFn`, `seq = snow & 0xFFFn`, epoch `EPOCH_MS = 1704067200000`. Decoding `TSK0NdeUSAqxP6` yields `ns=TSK`, `snow=320010849085292544`, `node=0`, `seq=0`, timestamp `2026-06-02 01:28:51 UTC` (matches the hard-coded panel). Toggle on click / Enter / Space sets `.open` and `aria-expanded`.

## References (`#refs`, verbatim)

Intro line (verbatim): "Live state over a socket, handling broadcasts, streams for collections, and the built-in dashboard as a real-world example of the pattern."

**Sources**
- [Phoenix.LiveView](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html) — live state over a socket.
- [Phoenix.LiveView — handle_info/2](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#c:handle_info/2) — folding broadcasts into a LiveView.
- [Phoenix.LiveView — stream/3](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#stream/3) — large, append-only collections.
- [Phoenix LiveDashboard](https://hexdocs.pm/phoenix_live_dashboard/) — the built-in monitoring UI, a real-world LiveView fed by telemetry.

**Related in this course**
- F6.09.1 · Build the dashboard → `/elixir/phoenix/live-dashboard/build`
- F6.09.2 · Broadcast engine events → `/elixir/phoenix/live-dashboard/stream`
- F6.09.3 · Many clients, live → `/elixir/phoenix/live-dashboard/multi-client`
- F6.07 · PubSub → `/elixir/phoenix/pubsub` — the fan-out the dashboard rides on.
- F6 · Phoenix Framework → `/elixir/phoenix`

## Wiring

- **route-tag:** `<span class="rsep">/</span><a href="/elixir">elixir</a><span class="rsep">/</span><a href="/elixir/phoenix">phoenix</a><span class="rsep">/</span><span class="rcur">live-dashboard</span>` (segmented, current segment `live-dashboard`).
- **crumbs:** `F6 · Phoenix Framework` → `/elixir/phoenix` · sep `/` · here `F6.09 · the live dashboard` (no link).
- **toc-mini:** `#pieces` ("Three moves of the lab") · `#converge` ("Where the course converges") · `#dives` ("Three deep dives").
- **pager:** prev → `/elixir/phoenix/deployment` ("← F6.08 · deployment"); next → `/elixir/phoenix/live-dashboard/build` ("Start · build the dashboard →").
- **footer (`foot-nav`, three columns):**
  - Brand: `.foot-logo` → `/elixir`; tag "Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir."
  - Chapters column: `/elixir/algebra` ("F1 · Algebra"), `/elixir/functional` ("F2 · Functional Programming"), `/elixir/language` ("F3 · The Elixir Language"), `/elixir/algorithms` ("F4 · Algorithms & Data Structures"), `/elixir/pragmatic` ("F5 · Pragmatic Programming"), `/elixir/phoenix` ("F6 · Phoenix Framework").
  - The course column: `/elixir` ("Course home"), `/elixir/course` ("Contents & history"), `/elixir/algebra/functions` ("Start · F1.01").
  - Header `.brand` and footer `.foot-logo` both point at `/elixir`.
- **Page meta:** `<title>` "The live dashboard — F6.09 · jonnify"; `<meta name="description">` "The capstone lab: a real-time operations dashboard that converges the whole course. The F5 engine emits events, the domain broadcasts them on a topic (F6.07), and a LiveView (F6.06) folds each event into a read model — live counts and an activity feed — that every connected client sees at once, with a Presence viewer count and auth and clustering from F6.08. Three dives: build the dashboard, broadcast engine events, and many clients live."

## Build instruction

To rebuild this hub, copy the `<head>`…`</style>`, `<header class="site">`, `<footer class="site-foot">`, and the two trailing `<script>` blocks verbatim from a recent built F6 (blue accent) sibling — the model page is the chapter landing `elixir/phoenix/index.html`, with the hero concept figure pattern mirrored from this module's own dive `elixir/phoenix/live-dashboard/build.html`; change only `<title>`/`<meta>`, the route-tag (current segment `live-dashboard`), the crumbs, and the `<main>` body. No-invent guards: use only the real Portal surfaces as written — a branded store, an event-sourced engine behind ONE `Portal` facade (`Portal.subscribe/1`, `Portal.broadcast/2`), the contexts `Catalog`/`Enrollment`, the `PortalWeb.Presence` viewer count, and the Phoenix web app (`DashboardLive`); the web layer reads only through the facade and renders only the closed `%Portal.Error{}` set. Cite the companion course for OTP internals (PubSub fan-out, Presence, BEAM distribution) — do not re-teach them. Voice: no first person, no exclamation marks, no emoji, and none of "just"/"simply"/"obviously".
