# F6.0.2 — What we're building (dive — design front-matter)

- Route (served): `/elixir/phoenix/blueprint`
- File: `elixir/phoenix/blueprint.html`
- Place in the chapter: the second of three design front-matter subpages on the F6 chapter landing (`/elixir/phoenix`). After `journey` sets the *what & why*, this page shows the **full stack** — the F5 layers with one Phoenix web band added on top and an Ecto adapter at the bottom — and where each layer is built. It sits between `journey` (1 of 3) and `wiring` (3 of 3).
- Accent: blue (the F6 · Phoenix Framework chapter accent).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `F6 · system design · 2 of 3`

H1: What we're *building* (the word "building" is the accented `.ex` span).

Hero lede (verbatim):

> A real learning platform, not a framework demo. A learner opens the Portal, browses a catalog, enrolls in a course, works through lessons, and watches their progress — and when an instructor publishes a lesson or another learner finishes one, the page updates **live**, with no refresh. Underneath, the picture is the F5 stack with one band added on top: a **Phoenix web layer** — endpoint, router, controllers, and LiveViews — that calls the F5 facade and renders the result. The engine, the domain core, and the F4 store are exactly as F5 left them. F6 builds the top band and the persistence adapter beneath; everything between stays put.

Kicker (verbatim):

> Select a layer to see what it does and which chapter builds it. The new work in F6 is the web band on top and the Ecto adapter at the bottom; the two middle layers are the F5 engine.

## Sections

Two teaching sections, plus a References section and a pager.

1. `#stack` — **The full stack.** A request travels down and a render travels back up, as in the F5 blueprint — only now the top layer is Phoenix rather than a thin server. Carries the page's primary interactive (the four-layer selector). Takeaway (verbatim): "The product is the platform, but the new code is a thin band on top and an adapter at the bottom. The two layers that hold the rules were finished in F5; F6 does not reopen them."
2. `#web` — **The web layer in code.** Every handler has the same shape: receive a request, call the facade, render the result. A controller does it for a classic request; a LiveView does it in `mount` and `handle_event`. Neither reaches past `Portal` and `%Portal.Error{}`. Carries the `EnrollmentController` code block and the `.bridge` two-cell summary.

Running example: a `PortalWeb.EnrollmentController.create/2` action calling `Portal.enroll(u, c)` and branching on `:ok` vs `{:error, %Portal.Error{message: msg}}`.

Real Elixir code shown (one `pre.code` block, verbatim):

```
# the web layer is thin: call the facade, branch on its result, render
defmodule PortalWeb.EnrollmentController do
  use PortalWeb, :controller

  def create(conn, %{"user" => u, "course" => c}) do
    case Portal.enroll(u, c) do
      :ok ->
        redirect(conn, to: ~p"/courses/#{c}")

      {:error, %Portal.Error{message: msg}} ->
        conn |> put_flash(:error, msg) |> redirect(to: ~p"/courses")
    end
  end
end

# a LiveView is the same shape, live: mount queries, handle_event commands (F6.06)
```

## The interactives

One interactive figure.

- **Figure** (`aria-labelledby="bpTitle"`): title `The stack · select a layer`.
- **Control group** id `bpSel` (`role="group"`, `aria-label="Layer"`), four buttons by `data-k`:
  - `web` — label `Web` (initial `active`)
  - `facade` — label `Facade`
  - `core` — label `Core`
  - `store` — label `Store`
- **SVG element ids** (four stacked layer rows + their right-edge build tags): boxes `bpBox_web`, `bpBox_facade`, `bpBox_core`, `bpBox_store`; tags `bpTag_web` (`F6`), `bpTag_facade` (`F5.08`), `bpTag_core` (`F5.02–F5.06`), `bpTag_store` (`F4 / F6.03`). Static SVG row labels: `PHOENIX WEB` / `endpoint · router · controllers · LiveView`; `ENGINE FACADE` / `Portal — the one public API`; `DOMAIN CORE` / `contexts · commands · queries · events`; `PERSISTENCE` / `branded CHAMP store + Ecto adapter`. Edge captions `request ↓` and `↑ render · live updates`.
- **Pure function:** `pick(k)` — sets the active button, restyles the four boxes (active box stroke `#5a87c4`, fill `#11203a`) and their tags (active tag fill `#9fc0ea`), and writes the readouts. The `LAYERS` table keys each layer to its `name`, `by`, and `desc`; `ORDER` is `['web','facade','core','store']`. Default call on load: `pick('web')`.
- **Readout strings (verbatim):**
  - `#bpRole` default `Phoenix web`; `#bpResult` default `F6`.
  - `#bpOut` (aria-live) composes `The <b>{name}</b> layer — built by <b>{by}</b>. {desc}` where:
    - web (`F6`): "Endpoint, router, controllers, and LiveViews. The only layer that touches the browser. It calls the facade and renders the result — and the engine never reaches up into it."
    - facade (`F5.08`): "The one public API the web layer calls: enroll, deliver_lesson, progress_of, returning plain results and a closed error contract. Built in F5, unchanged in F6."
    - core (`F5.02–F5.06`): "The Portal's rules and state: bounded contexts, commands and queries, domain events, and the supervised engine. Framework-free, finished in F5."
    - store (`F4 / F6.03`): "The branded CHAMP store and Snowflake ids from F4, plus an Ecto adapter F6.03 adds behind the engine's port — persistence is one more adapter, not a new dependency for the core."
- **Degrade behaviour:** the SVG ships with the `web` row pre-highlighted in static markup (drawn `active` with no JS); prose, code, and figure are visible without JS. Reveal-on-scroll is JS-gated (`html.js .reveal`) and disabled under `prefers-reduced-motion: reduce`; `scroll-behavior` falls back to `auto` under reduced motion.
- **Footer build-stamp decoder:** stamp id `TSK0NdK1hq7QmG`. Decoded: namespace `TSK`, snowflake `319938783938084864`, node `0`, seq `0`, timestamp `2026-06-01 20:42:30 UTC`.

## References (#refs, verbatim)

Intro line: "The layers F6 adds on top of the F5 engine."

Sources:
- [Phoenix — Overview](https://hexdocs.pm/phoenix/overview.html) — the web layer on top of the stack.
- [Ecto](https://hexdocs.pm/ecto/Ecto.html) — the persistence adapter at the bottom.
- [Phoenix — LiveView](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html) — the live surface of the platform.

Related in this course:
- `/elixir/phoenix/journey` — F6.0.1 · The developer journey — the path to this platform.
- `/elixir/phoenix/wiring` — F6.0.3 · Wiring Phoenix onto the F5 engine — how the bands connect.
- `/elixir/pragmatic/architecture` — F5.0.1 · The Portal engine blueprint — the stack F6 extends.
- `/elixir/pragmatic/boundaries` — F5.08 · Boundaries & integration seams — the facade the web band calls.

## Wiring

- route-tag (verbatim): `/ elixir / phoenix / blueprint` (rendered `<a>elixir</a> / <a>phoenix</a> / <span class="rcur">blueprint</span>`).
- crumbs (verbatim): `Contents` / `F6 · Phoenix Framework` / `What we're building` (the last as `.here`).
- toc-mini: `#stack` → "The full stack"; `#web` → "The web layer in code".
- pager: prev → `/elixir/phoenix/journey` label "F6.0.1 · the developer journey"; next → `/elixir/phoenix/wiring` label "Next · wiring Phoenix onto the F5 engine".
- footer: three columns. *Chapters* — `/elixir/algebra` (F1 · Algebra), `/elixir/functional` (F2 · Functional Programming), `/elixir/language` (F3 · The Elixir Language), `/elixir/algorithms` (F4 · Algorithms & Data Structures), `/elixir/pragmatic` (F5 · Pragmatic Programming), `/elixir/phoenix` (F6 · Phoenix Framework). *The course* — `/elixir` (Course home), `/elixir/course` (Contents & history), `/elixir/algebra/functions` (Start · F1.01). Foot-brand tagline: "Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir." Copyright `© jonnify`.
- Page meta:
  - `<title>`: `What we're building — F6.0.2 · jonnify`
  - `<meta name="description">`: `The Portal as a real learning platform: browse, enroll, lessons, live progress, and a dashboard. Underneath is the F5 stack with one band added on top — a Phoenix web layer (endpoint, router, controllers, LiveView) that calls the F5 facade — and an Ecto adapter beneath. The two middle layers, the engine and the domain core, are exactly as F5 left them.`

## Build instruction

To (re)build this page, copy the `head…</style>`, the `<header class="site">`, the `<footer class="site-foot">`, and the two trailing `<script>` blocks (the figure controller + Snowflake decoder, and the reveal-on-scroll enhancer) verbatim from a recent BUILT sibling on the blue F6 accent — its immediate neighbours `elixir/phoenix/journey.html` and `elixir/phoenix/wiring.html` carry the identical design front-matter shell. Change only `<title>` / `<meta description>`, the `route-tag` (last segment `blueprint`), and the `<main>` body (hero, the `#stack` four-layer selector figure with its `LAYERS`/`pick(k)` script, the `#web` `EnrollmentController` code + bridge, and the References block). No-invent guards: use only the real Portal surfaces as written — the branded store, the event-sourced engine behind ONE `Portal` facade (`enroll/2`, `deliver_lesson/2`, `progress_of/1`, returning `:ok | {:ok, data} | {:error, %Portal.Error{}}`), and the Phoenix web app (`PortalWeb.Endpoint`, `PortalWeb.EnrollmentController`, `~p` verified paths); cite the companion course for OTP internals rather than re-teaching them. Voice rules: no first person, no exclamation marks, no emoji, and none of "just", "simply", or "obviously". Model sibling to copy from: `elixir/phoenix/journey.html`.
