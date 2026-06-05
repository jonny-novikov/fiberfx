# F6.0.1 — The developer journey (dive — design front-matter)

- Route (served): `/elixir/phoenix/journey`
- File: `elixir/phoenix/journey.html`
- Place in the chapter: the first of three design front-matter subpages on the F6 chapter landing (`/elixir/phoenix`), before the nine numbered modules begin. It opens the design brief — the *what & why* of the chapter — framing F6 as four short arcs from the F5 facade to a deployed, real-time platform. It precedes `blueprint` (2 of 3) and `wiring` (3 of 3).
- Accent: blue (the F6 · Phoenix Framework chapter accent).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `F6 · system design · 1 of 3`

H1: The developer *journey* (the word "journey" is the accented `.ex` span).

Hero lede (verbatim):

> You arrive at F6 holding the thing F5 built: a supervised **Portal engine** behind a small facade — `enroll/2`, `deliver_lesson/2`, `progress_of/1` — that returns plain results and a closed error contract, and that imports no web framework. You leave F6 with a **deployed, real-time learning platform**: a browser that loads a page, enrolls a learner, watches progress update live as other clients act, behind sessions and auth, running as a release in production. The journey between is four short arcs, and the rule never changes — Phoenix sits on top of the engine and calls only its facade, so each milestone adds a layer without reaching into the engine.

Kicker (verbatim):

> Select an arc to see what you build and which modules deliver it. The path runs left to right, from the F5 facade to a live platform.

## Sections

Two teaching sections, plus a References section and a pager.

1. `#path` — **Four arcs.** The chapter is four arcs of roughly two modules each: the first stands Phoenix up; the second gives it data and domain boundaries; the third renders and makes the UI live; the fourth makes it real-time, secure, and shipped. Carries the page's primary interactive (the journey arc selector). Takeaway (verbatim): "A journey, not a pile of features. Each arc leaves a platform that runs, so you can ship after any one of them and keep going — the same way F5 left the engine runnable after every module."
2. `#ends` — **Where you start, where you land.** The two ends of the journey: F5 hands you a facade callable from anywhere; F6 ends with a real-time route the browser reaches, calling that exact facade. Everything between is wiring, rendering, and broadcasting — never new domain logic. Carries the START/FINISH code block and the `.bridge` two-cell summary.

Running example: the `Portal` facade (`enroll/2`, `progress_of/1`) at START and a `live "/enroll/:id"`, `PortalWeb.EnrollmentLive` route at FINISH.

Real Elixir code shown (one `pre.code` block, verbatim):

```
# START — what F5 hands you: a supervised, framework-free facade
Portal.enroll(user_id, course_id)        # :ok | {:error, %Portal.Error{}}
Portal.progress_of(enrollment_id)        # {:ok, 0..100} | {:error, _}

# FINISH — what F6 ships: a real-time route the browser reaches, calling the same facade
live "/enroll/:id", PortalWeb.EnrollmentLive   # mount/handle_event call Portal.*
```

## The interactives

One interactive figure.

- **Figure** (`aria-labelledby="jrTitle"`): title `The journey · select an arc`.
- **Control group** id `jrSel` (`role="group"`, `aria-label="Journey arc"`), four buttons by `data-k`:
  - `serve` — label `stand it up` (initial `active`)
  - `data` — label `data & domain`
  - `live` — label `the live UI`
  - `ship` — label `real-time & ship`
- **SVG element ids** (the four arc boxes, toggled by the selector): `jrBox_serve`, `jrBox_data`, `jrBox_live`, `jrBox_ship`. Static SVG labels read `STAND IT UP` / `F6.01–F6.02`, `DATA & DOMAIN` / `F6.03–F6.04`, `THE LIVE UI` / `F6.05–F6.06`, `REAL-TIME & SHIP` / `F6.07–F6.09`, framed by `START · F5 facade` and `FINISH · live platform`.
- **Pure function:** `pick(k)` — sets the active button, restyles the four arc boxes (active box gets stroke `#5a87c4`, fill `#11203a`), and writes the readouts. The arc data table `ARCS` keys each arc to its `name`, `mods`, `box`, and `desc`; `ORDER` is `['serve','data','live','ship']`. Default call on load: `pick('serve')`.
- **Readout strings (verbatim):**
  - `#jrRole` default `Stand it up`; `#jrResult` default `F6.01–F6.02`.
  - `#jrOut` (aria-live) composes `The <b>{name}</b> arc — <code>{mods}</code>. {desc}` where each arc's `desc` is:
    - serve: "Mount the Phoenix endpoint as a child of the F5 supervision tree, then route a request through the plug pipeline to a handler that calls the Portal facade. The engine is unchanged."
    - data: "Bring in Ecto for schemas, changesets, and queries — as one more adapter behind the engine's port — and align Phoenix contexts with the F5 facade rather than duplicating the domain."
    - live: "Render server-side with HEEx components, then make the UI interactive with LiveView: mount loads state from a query, handle_event issues a command, render draws from assigns — all over the facade."
    - ship: "Broadcast engine events over PubSub so every client updates live, add sessions and authentication, cut a release for production, and finish with the live dashboard — the platform, running."
- **Degrade behaviour:** the SVG ships with `serve` pre-highlighted in the static markup (the box is drawn `active` with no JS); the prose, code, and figure are fully visible without JS. Reveal-on-scroll is JS-gated via `html.js .reveal` and disabled under `prefers-reduced-motion: reduce`; `scroll-behavior` falls back to `auto` under reduced motion. The arc-flow animation in CSS only runs under `prefers-reduced-motion: no-preference`.
- **Footer build-stamp decoder:** stamp id `TSK0NdK1hXx6S8`. Decoded: namespace `TSK`, snowflake `319938783669649408`, node `0`, seq `0`, timestamp `2026-06-01 20:42:30 UTC`.

## References (#refs, verbatim)

Intro line: "The framework the journey adds, and the engine it sits on."

Sources:
- [Phoenix — Overview](https://hexdocs.pm/phoenix/overview.html) — what Phoenix adds on top of an Elixir app.
- [Phoenix — LiveView](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html) — the interactive UI the journey ends in.
- [Elixir — Supervisor](https://hexdocs.pm/elixir/Supervisor.html) — the tree the endpoint joins.

Related in this course:
- `/elixir/phoenix/blueprint` — F6.0.2 · What we're building — the platform, layer by layer.
- `/elixir/phoenix/wiring` — F6.0.3 · Wiring Phoenix onto the F5 engine — the seam in code.
- `/elixir/pragmatic/engine-lab` — F5.09 · The engine lab — the facade this journey starts from.
- `/elixir/phoenix` — F6 · Phoenix Framework.

## Wiring

- route-tag (verbatim): `/ elixir / phoenix / journey` (rendered `<a>elixir</a> / <a>phoenix</a> / <span class="rcur">journey</span>` with `/` separators).
- crumbs (verbatim): `Contents` / `F6 · Phoenix Framework` / `The journey` (the last as `.here`).
- toc-mini: `#path` → "Four arcs"; `#ends` → "Where you start, where you land".
- pager: prev → `/elixir/phoenix` label "F6 · chapter overview"; next → `/elixir/phoenix/blueprint` label "Next · what we're building".
- footer: three columns. *Chapters* — `/elixir/algebra` (F1 · Algebra), `/elixir/functional` (F2 · Functional Programming), `/elixir/language` (F3 · The Elixir Language), `/elixir/algorithms` (F4 · Algorithms & Data Structures), `/elixir/pragmatic` (F5 · Pragmatic Programming), `/elixir/phoenix` (F6 · Phoenix Framework). *The course* — `/elixir` (Course home), `/elixir/course` (Contents & history), `/elixir/algebra/functions` (Start · F1.01). Foot-brand tagline: "Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir." Copyright `© jonnify`.
- Page meta:
  - `<title>`: `The developer journey — F6.0.1 · jonnify`
  - `<meta name="description">`: `The path F6 walks, from the F5 facade to a deployed, real-time learning platform, in four arcs: stand Phoenix up (F6.01–F6.02), add data and domain with Ecto and contexts (F6.03–F6.04), render and go live with HEEx and LiveView (F6.05–F6.06), then make it real-time, secure, and shipped (F6.07–F6.09). The rule never changes: Phoenix calls only the Portal facade.`

## Build instruction

To (re)build this page, copy the `head…</style>`, the `<header class="site">`, the `<footer class="site-foot">`, and the two trailing `<script>` blocks (the figure controller + Snowflake decoder, and the reveal-on-scroll enhancer) verbatim from a recent BUILT sibling on the blue F6 accent — the natural model is `elixir/phoenix/blueprint.html`, its immediate chapter neighbour, which carries the identical design front-matter shell. Change only `<title>` / `<meta description>`, the `route-tag` (last segment `journey`), and the `<main>` body (hero, the `#path` arc-selector figure with its `ARCS`/`pick(k)` script, the `#ends` START/FINISH code + bridge, and the References block). No-invent guards: use only the real Portal surfaces as written — the branded store, the event-sourced engine behind ONE `Portal` facade (`enroll/2`, `deliver_lesson/2`, `progress_of/1`, returning `:ok | {:ok, data} | {:error, %Portal.Error{}}`), and the Phoenix web app (`PortalWeb.Endpoint`, `PortalWeb.EnrollmentLive`); cite the companion course for OTP internals (supervision trees, GenServer) rather than re-teaching them. Voice rules: no first person, no exclamation marks, no emoji, and none of "just", "simply", or "obviously". Model sibling to copy from: `elixir/phoenix/blueprint.html`.
