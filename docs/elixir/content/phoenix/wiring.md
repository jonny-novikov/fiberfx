# F6.0.3 — Wiring Phoenix onto the F5 engine (dive — design front-matter)

- Route (served): `/elixir/phoenix/wiring`
- File: `elixir/phoenix/wiring.html`
- Place in the chapter: the third and last of three design front-matter subpages on the F6 chapter landing (`/elixir/phoenix`). It closes the design brief by showing the **seam in code** — three wiring points (supervision tree, router, LiveView) that connect Phoenix to the F5 engine — and hands off to F6.01, where the chapter proper begins. It follows `journey` (1 of 3) and `blueprint` (2 of 3).
- Accent: blue (the F6 · Phoenix Framework chapter accent).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `F6 · system design · 3 of 3`

H1: Wiring Phoenix onto the F5 *engine* (the word "engine" is the accented `.ex` span).

Hero lede (verbatim):

> This is the seam the whole chapter turns on, and it is smaller than it sounds. There are three wiring points. First, the **supervision tree**: Phoenix's `Endpoint` becomes one more child of the tree the F5.09 lab assembled, supervised alongside the engine and the store. Second, the **router**: a live route maps a URL to a LiveView after the plug pipeline runs. Third, the **LiveView** itself, which — exactly like the F5.09 sketch — calls only the `Portal` facade. No part of this reaches into the engine; F6 adds a child, a route, and a caller, and the engine stays the framework-free core F5 built.

Kicker (verbatim):

> Select a wiring point to see what connects to what. All three are additions on top of the F5 engine, never edits inside it.

## Sections

Three teaching sections, plus a References section and a pager.

1. `#points` — **Three wiring points.** Each point is a one-way connection from Phoenix to the engine: the tree supervises the endpoint; the router sends a request to a LiveView; the LiveView calls the facade. Nothing points the other way. Carries the primary interactive (the three-point selector). Takeaway (verbatim): "Three additions, one direction. Phoenix depends on the engine; the engine depends on nothing above it. That asymmetry is the entire reason the wiring is small."
2. `#tree` — **The endpoint joins the tree.** F6 adds exactly one child — `PortalWeb.Endpoint` — under the same `:one_for_one` strategy; the engine and store entries do not change. Carries the second SVG (a static supervisor tree diagram, no selector) and the `Portal.Application` code block.
3. `#code` — **The route and the LiveView.** The second and third points: the router maps a URL to a LiveView (running the plug pipeline first); the LiveView loads its state from a facade query in `mount`. Carries the `PortalWeb.Router` and the `EnrollmentLive.mount/3` code blocks and the `.bridge` two-cell summary.

Running example: `Portal.Application.start/2` adding `PortalWeb.Endpoint` to the children list; the router `live "/enroll/:id", EnrollmentLive`; and `EnrollmentLive.mount/3` calling `Portal.progress_of(id)`.

Real Elixir code shown (three `pre.code` blocks, verbatim):

```
# F6 adds one child to the tree the F5.09 lab assembled
defmodule Portal.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Portal.EventStore.adapter(),   # F5 — unchanged
      {Portal.Engine, []},            # F5 — unchanged
      PortalWeb.Endpoint             # F6 — supervised alongside
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Portal.Supervisor)
  end
end
```

```
# the router: a live route maps a URL to a LiveView, after the pipeline
defmodule PortalWeb.Router do
  use PortalWeb, :router

  scope "/", PortalWeb do
    pipe_through :browser
    live "/enroll/:id", EnrollmentLive
  end
end
```

```
# the LiveView from the F5.09 sketch, now real — still only the facade
def mount(%{"id" => id}, _session, socket) do
  case Portal.progress_of(id) do
    {:ok, percent} -> {:ok, assign(socket, progress: percent, error: nil)}
    {:error, %Portal.Error{message: msg}} -> {:ok, assign(socket, error: msg)}
  end
end
```

## The interactives

Two figures (one interactive selector; one static diagram).

- **Figure 1 — interactive** (`aria-labelledby="wrTitle"`): title `Wiring points · select one`.
  - **Control group** id `wrSel` (`role="group"`, `aria-label="Wiring point"`), three buttons by `data-k`:
    - `tree` — label `supervision tree` (initial `active`)
    - `router` — label `router`
    - `liveview` — label `LiveView`
  - **SVG element ids** (three stacked rows toggled by the selector): `wrRow_tree`, `wrRow_router`, `wrRow_liveview`. Static row labels: `SUPERVISION TREE` / `PortalWeb.Endpoint added as a supervised child (F5's tree)` / `supervises`; `ROUTER` / `live "/enroll/:id" → EnrollmentLive (after the pipeline)` / `routes`; `LIVEVIEW` / `mount / handle_event call the Portal facade — nothing else` / `calls`.
  - **Pure function:** `pick(k)` — sets the active button, restyles the three rows (active row stroke `#5a87c4`, fill `#11203a`), and writes the readouts. The `POINTS` table keys each point to its `name`, `detail`, and `desc`; `ORDER` is `['tree','router','liveview']`. Default call on load: `pick('tree')`.
  - **Readout strings (verbatim):**
    - `#wrRole` default `Supervision tree`; `#wrResult` default `PortalWeb.Endpoint joins F5's tree`.
    - `#wrOut` (aria-live) composes `<b>{name}</b> — {detail}. {desc}` where:
      - tree (detail `PortalWeb.Endpoint joins F5's tree`): "F6 adds one child — the Phoenix endpoint — to the tree the F5.09 lab assembled, under the same one_for_one strategy. The engine and store entries are unchanged; the web is supervised next to them."
      - router (detail `live "/enroll/:id" → EnrollmentLive`): "A live route maps a URL to a LiveView after the plug pipeline runs. The route is the only place that names the LiveView; the LiveView is the only place that names the facade."
      - liveview (detail `calls Portal.enroll and progress_of`): "The same EnrollmentLive the F5.09 lab sketched: mount loads state from a facade query and handle_event issues a facade command. It references only Portal and the closed error contract."
- **Figure 2 — static** (`aria-labelledby="wrTreeTitle"`): title `One tree, one new child`. A non-interactive SVG of `PORTAL.SUPERVISOR` (`:one_for_one`) with three children: `EVENTSTORE` (`F5 · store`), `ENGINE` (`F5 · GenServer`), and the new `PORTALWEB.ENDPOINT` (`F6 · web (new)`, drawn in blue). Caption: "the endpoint is one more supervised child; the engine and store entries are unchanged."
- **Degrade behaviour:** the interactive SVG ships with the `tree` row pre-highlighted in static markup; the second SVG is static; all prose and code are visible without JS. Reveal-on-scroll is JS-gated (`html.js .reveal`) and disabled under `prefers-reduced-motion: reduce`; `scroll-behavior` falls back to `auto` under reduced motion.
- **Footer build-stamp decoder:** stamp id `TSK0NdK1i7iYqG`. Decoded: namespace `TSK`, snowflake `319938784198131712`, node `0`, seq `0`, timestamp `2026-06-01 20:42:30 UTC`.

## References (#refs, verbatim)

Intro line: "The three things F6 wires onto the engine: the endpoint, the router, and the LiveView."

Sources:
- [Phoenix — Endpoint](https://hexdocs.pm/phoenix/Phoenix.Endpoint.html) — the supervised child that joins the tree.
- [Phoenix — Router](https://hexdocs.pm/phoenix/Phoenix.Router.html) — mapping a live route to a LiveView.
- [Elixir — Supervisor](https://hexdocs.pm/elixir/Supervisor.html) — the F5 tree the endpoint is added to.

Related in this course:
- `/elixir/phoenix/journey` — F6.0.1 · The developer journey — where this seam sits on the path.
- `/elixir/phoenix/blueprint` — F6.0.2 · What we're building — the stack this connects.
- `/elixir/pragmatic/engine-lab/handoff` — F5.09.3 · What ships in F6 — the handoff this implements.
- `/elixir/pragmatic/engine-lab/mount` — F5.09.2 · A LiveView mount sketch — the LiveView, sketched.

## Wiring

- route-tag (verbatim): `/ elixir / phoenix / wiring` (rendered `<a>elixir</a> / <a>phoenix</a> / <span class="rcur">wiring</span>`).
- crumbs (verbatim): `Contents` / `F6 · Phoenix Framework` / `Wiring` (the last as `.here`).
- toc-mini: `#points` → "Three wiring points"; `#tree` → "The endpoint joins the tree"; `#code` → "The route and the LiveView".
- pager: prev → `/elixir/phoenix/blueprint` label "F6.0.2 · what we're building"; next → `/elixir/phoenix` label "Back to F6 · overview".
- footer: three columns. *Chapters* — `/elixir/algebra` (F1 · Algebra), `/elixir/functional` (F2 · Functional Programming), `/elixir/language` (F3 · The Elixir Language), `/elixir/algorithms` (F4 · Algorithms & Data Structures), `/elixir/pragmatic` (F5 · Pragmatic Programming), `/elixir/phoenix` (F6 · Phoenix Framework). *The course* — `/elixir` (Course home), `/elixir/course` (Contents & history), `/elixir/algebra/functions` (Start · F1.01). Foot-brand tagline: "Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir." Copyright `© jonnify`.
- Page meta:
  - `<title>`: `Wiring Phoenix onto the F5 engine — F6.0.3 · jonnify`
  - `<meta name="description">`: `The seam the chapter turns on, in code: PortalWeb.Endpoint joins the supervision tree the F5.09 lab assembled, a live route maps a URL to a LiveView, and the LiveView's mount and handle_event call only the Portal facade. Three additions on top of the engine — a child, a route, and a caller — never edits inside it.`

## Build instruction

To (re)build this page, copy the `head…</style>`, the `<header class="site">`, the `<footer class="site-foot">`, and the two trailing `<script>` blocks (the figure controller + Snowflake decoder, and the reveal-on-scroll enhancer) verbatim from a recent BUILT sibling on the blue F6 accent — its immediate neighbours `elixir/phoenix/blueprint.html` and `elixir/phoenix/journey.html` carry the identical design front-matter shell. Change only `<title>` / `<meta description>`, the `route-tag` (last segment `wiring`), and the `<main>` body (hero, the `#points` three-point selector figure with its `POINTS`/`pick(k)` script, the `#tree` static supervisor SVG + `Portal.Application` code, the `#code` `Router` and `mount/3` blocks + bridge, and the References block). No-invent guards: use only the real Portal surfaces as written — the branded store (`Portal.EventStore.adapter()`), the event-sourced engine (`{Portal.Engine, []}`) behind ONE `Portal` facade (`enroll/2`, `deliver_lesson/2`, `progress_of/1`, returning `:ok | {:ok, data} | {:error, %Portal.Error{}}`), and the Phoenix web app (`PortalWeb.Endpoint`, `PortalWeb.Router`, `PortalWeb.EnrollmentLive`, the `:one_for_one` `Portal.Supervisor`); cite the companion course for OTP internals (supervision, GenServer) rather than re-teaching them. Voice rules: no first person, no exclamation marks, no emoji, and none of "just", "simply", or "obviously". Model sibling to copy from: `elixir/phoenix/blueprint.html`.
