# F6.01 — Architecture & the request lifecycle (module hub)

- **Route (served):** `/elixir/phoenix/lifecycle`
- **File:** `elixir/phoenix/lifecycle/index.html`
- **Place in the chapter:** the first module hub of F6 · Phoenix Framework. It frames the path a request travels and the one point where the web meets the F5 engine, then routes the reader to three dives: the lifecycle end to end (`request-path`), the endpoint as a supervised process (`endpoint`), and the controller/view seam (`controllers`). It sits on the F5→F6 handoff — F5 left a headless supervised facade; this module is the front door onto it.
- **Accent:** blue (the F6 · Phoenix chapter accent; the hero `<span class="ex">lifecycle</span>` renders in `--elixir-bright`, interactive highlights in `--blue` / `--blue-bright`).
- **Status:** built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F6 · the architecture · module 1`

`h1` (verbatim): `Architecture & the request lifecycle` ("lifecycle" is the accent `.ex` span).

Hero lede (`.lede`, verbatim):

> Phoenix is, at heart, one long function from a request to a response — a stack of small `plugs` that each take a connection and hand back a connection. A request enters at the `Endpoint`, the router matches it to a controller through a pipeline, the controller does the one piece of real work — it calls the `Portal` facade from F5 — and a view renders the result. Understanding that path is the whole of this module, because every later module plugs a capability into it: routing shapes the match, Ecto and contexts sit behind the facade, HEEx and LiveView own the render. Learn the lifecycle once and the rest of F6 is filling in stages.

Kicker (`.kicker`, verbatim):

> This module maps the path a request travels and the one point where your code meets the engine: the request lifecycle end to end, the endpoint as a supervised process, and the controller/view seam.

## What the page frames

This hub is not a `.mods` directory; it presents the module map as the section `#dives` with three `<a>` dive cards (each linked, with a left-border accent), plus a `.bridge` (F5→F6.01) and a `.note` reading order.

- **F6.01.1 · The request lifecycle** — "A request from the browser to the response: `endpoint` → `router` → `controller` → `view`, with one call to `Portal` in the middle." Route `/elixir/phoenix/lifecycle/request-path`. Built. (Left-border accent `--blue`.)
- **F6.01.2 · The endpoint, supervised** — "The outermost plug — static, parsers, session — and a child of the OTP tree the F5.09 lab assembled. Where HTTP meets OTP." Route `/elixir/phoenix/lifecycle/endpoint`. Built. (Left-border accent `--gold`.)
- **F6.01.3 · Controllers, views & the facade seam** — "A thin controller calls only `Portal`, branches on `%Portal.Error{}`, and picks a view; the view renders `assigns`." Route `/elixir/phoenix/lifecycle/controllers`. Built. (Left-border accent `--sage`.)

`#path` section ("The path, at a glance") carries the lifecycle stage selector and a `.take`. The `.bridge` two cells: idea `F5 · a headless engine` ("F5 left a supervised facade — correct and tested, but with no way for a browser to reach it.") → elix `F6.01 · a way in` ("The lifecycle is the path from a URL to a facade call. Once it runs, the platform has a front door."). The `.note` reading order (verbatim): "Start with the request lifecycle, then the endpoint, then the controller and view seam. The next module, F6.02 — Routing, controllers & plugs, builds out the match in the middle. See also the design brief: wiring Phoenix onto the F5 engine." — links to `/elixir/phoenix/lifecycle/request-path`, `/elixir/phoenix/lifecycle/endpoint`, `/elixir/phoenix/lifecycle/controllers`, `/elixir/phoenix/wiring`.

## The interactives

### Hero figure — "One request, four stages" (`#hpTitle`)

- **`<figure class="hero-fig">`** with figcaption `.fc-lbl#hpTitle` "One request, four stages". A vertical-track `<svg viewBox="0 0 320 250">` with a request `circle#hpTok` (class `hp-tok`) and four stage groups: `#hpStage_endpoint`, `#hpStage_router`, `#hpStage_controller`, `#hpStage_view`. The endpoint is the active stage in static markup (stage 0).
- **Controls:** `.hp-ctrls` with `button#hpAdv` ("▸ advance") and `button.ghost#hpReset` ("reset"). Caption `.hp-cap#hpCap` (`aria-live="polite"`).
- **Pure logic:** an IIFE walks a `PATH` array of four stages (`endpoint cy:52`, `router cy:96`, `controller cy:140`, `view cy:184`); `paint()` moves `#hpTok`'s `cy`, restrokes the active stage group rect to `BLUE_MUTE`/width `2`/fill `ACTIVE_FILL`, and writes `step.cap + SEAM` into `#hpCap`. `advBtn` advances `at = (at + 1) % PATH.length` (wraps after the view); `resetBtn` returns to `at = 0`.
- **Caption strings (`PATH[*].cap`, verbatim):**
  - endpoint: "Endpoint — the request enters the plug stack."
  - router: "Router — the verb and path match one action through a pipeline."
  - controller: "Controller — the action calls the Portal facade from F5."
  - view: "View — the result renders, and the response leaves."
  - `SEAM` (appended each paint): "The controller is the one stage that calls the Portal facade."
- **Static `#hpCap` default (verbatim):** "Endpoint — the request enters the plug stack. / The controller is the one stage that calls the Portal facade."

### Content figure — "The request lifecycle · select a stage" (`#lcTitle`)

- **`<figure class="fig">`**, heading `#lcTitle` "The request lifecycle · select a stage". Control group `.solid-select#lcSel` (role `group`, label "Lifecycle stage") with four buttons by `data-k`: `endpoint`, `router`, `controller` (starts `.active`), `view`. SVG `viewBox="0 0 720 170"` with chips `#lcChip_endpoint`, `#lcChip_router`, `#lcChip_controller`, `#lcChip_view`. Readout `.geo-readout#lcOut`; spans `#lcRole` (default "Controller") and `#lcResult` (default "calls the Portal facade").
- **Pure function:** `pick(k)` — toggles the `#lcSel` button `.active`/`aria-pressed`; restrokes each chip in `ORDER = ['endpoint','router','controller','view']` (`BLUE_MUTE`/`2`/`#11203a` when on, `#3a4263`/`1.3`/`#10162b` off); sets `#lcRole`←`S.name`, `#lcResult`←`S.does`, and writes the bold name + does + built-out module + desc into `#lcOut.innerHTML`. Initial call `pick('controller')`.
- **`STAGES` dataset (`name` · `does` · built-out `by` · `desc`, verbatim):**
  - endpoint — "Endpoint" · "the entry plug + tree child" · `F6.01.2` · "The outermost plug and a supervised process. It runs a fixed stack — static files, request parsers, session — and then calls the router. It is also a child of the OTP tree from F5."
  - router — "Router" · "matches a route, runs a pipeline" · `F6.02` · "Matches the verb and path to one controller action, running a named pipeline of plugs (for example :browser) first. The route is the only place that names the controller."
  - controller — "Controller" · "calls the Portal facade" · `F6.01.3` · "The one stage that touches the domain: the action calls Portal.enroll, Portal.progress_of, and friends, branches on the closed error contract, and assigns the result for a view. This is where your code lives."
  - view — "View" · "renders the result" · `F6.05` · "Turns the controller's assigns into markup — HEEx in F6.05, and live HEEx under LiveView in F6.06. It renders data; it never calls the engine itself."
- **`.take` (verbatim):** "You are not learning four unrelated things; you are learning one pipeline. The endpoint, router, and view are configured once and rarely touched again — the controller is where you work, and all it does is call the facade and choose how to render the answer."

### Degrade behaviour

The hero SVG ships its static initial state (the request at the endpoint, stage 0) readable without JS; `#hpCap` carries its default text in markup. The `#lcSel` controls and chips and the default `#lcOut`/`#lcRole`/`#lcResult` strings are JS-painted on `pick('controller')` but the markup is intact. `.hp-tok` transitions are gated to `prefers-reduced-motion: no-preference` and set to `none` under reduce; the `.arc-flow` animation is similarly motion-gated. No browser storage.

### Footer build-stamp decoder (`#stamp`)

- **Stamp id:** `TSK0NdLjF1gJfc` (in `#stampId`); panel `#st-ts` hard-codes "2026-06-01 21:06:19 UTC".
- **Pure functions:** `b62decode(s)` (base62 over `0123…XYZabc…xyz` → BigInt), `pad2(x)`, `decodeBranded(id)` — splits `ns = id.slice(0,3)` and `snow = b62decode(id.slice(3))`, then `ts = snow >> 22n`, `node = (snow >> 12n) & 0x3FFn`, `seq = snow & 0xFFFn`, epoch `EPOCH_MS = 1704067200000`, formatting a UTC timestamp; fills `#st-ns`/`#st-snow`/`#st-node`/`#st-seq`/`#st-ts`. Toggle on click / Enter / Space sets `.open` and `aria-expanded`. Decoding `TSK0NdLjF1gJfc` resolves to the panel timestamp 2026-06-01 21:06:19 UTC.

## References (`#refs`, verbatim)

Intro line: "The request lifecycle, the plug abstraction it is built from, and the endpoint at its head."

**Sources**
- [Phoenix — Request life-cycle](https://hexdocs.pm/phoenix/request_lifecycle.html) — endpoint to view, the canonical walkthrough.
- [Phoenix — Overview](https://hexdocs.pm/phoenix/overview.html) — the framework at a glance.
- [Elixir — Plug](https://hexdocs.pm/plug/readme.html) — the connection-in, connection-out contract every stage shares.
- [Phoenix — Endpoint](https://hexdocs.pm/phoenix/Phoenix.Endpoint.html) — the plug at the head of the pipeline.

**Related in this course**
- F6.01.1 · The request lifecycle → `/elixir/phoenix/lifecycle/request-path`
- F6.01.2 · The endpoint, supervised → `/elixir/phoenix/lifecycle/endpoint`
- F6.01.3 · Controllers, views & the facade seam → `/elixir/phoenix/lifecycle/controllers`
- F6.0.3 · Wiring Phoenix onto the F5 engine → `/elixir/phoenix/wiring` — the seam this module walks.
- F5.09 · The engine lab → `/elixir/pragmatic/engine-lab` — the facade the controller calls.

## Wiring

- **route-tag (verbatim):** `<span class="rsep">/</span><a href="/elixir">elixir</a><span class="rsep">/</span><a href="/elixir/phoenix">phoenix</a><span class="rsep">/</span><span class="rcur">lifecycle</span>` — `/ elixir / phoenix / lifecycle`, current segment `lifecycle`.
- **crumbs (verbatim):** `F6 · Phoenix Framework` → `/elixir/phoenix` · sep `/` · here `F6.01 · lifecycle` (no link).
- **toc-mini:** `#path` ("The path, at a glance") · `#dives` ("Three deep dives").
- **pager:** prev → `/elixir/phoenix` ("← F6 · overview"); next → `/elixir/phoenix/lifecycle/request-path` ("Start · the request lifecycle →"). A `.spacer` sits between them; no `.p-left` text.
- **footer (`.foot-nav`, 3 columns):**
  - Brand: `.foot-logo` → `/elixir`; `.foot-tag` "Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir."
  - Chapters: `/elixir/algebra` ("F1 · Algebra"), `/elixir/functional` ("F2 · Functional Programming"), `/elixir/language` ("F3 · The Elixir Language"), `/elixir/algorithms` ("F4 · Algorithms & Data Structures"), `/elixir/pragmatic` ("F5 · Pragmatic Programming"), `/elixir/phoenix` ("F6 · Phoenix Framework").
  - The course: `/elixir` ("Course home"), `/elixir/course` ("Contents & history"), `/elixir/algebra/functions` ("Start · F1.01").
- **Page meta:** `<title>` "Architecture & the request lifecycle — F6.01 · jonnify"; `<meta description>` "How a request travels through Phoenix and where it meets the F5 engine: the endpoint plug stack, the router match and pipeline, the controller action that calls the Portal facade, and the view that renders the result. Three dives — the lifecycle end to end, the endpoint as a supervised process in F5's tree, and the controller/view seam where the web calls only the facade."

## Build instruction

To rebuild this hub, copy the `<head>…</style>`, `<header class="site">`, `<footer class="site-foot">`, and both trailing `<script>` blocks verbatim from a recent BUILT blue-accent F6 sibling — the model page is `elixir/phoenix/lifecycle/request-path.html` (the first dive in this same module, identical head and footer chrome) — then change only the `<title>`/`<meta description>`, the `.route-tag` (current segment `lifecycle`), and the `<main>` body (the hero, the `#path` stage selector, the `#dives` cards, the `.bridge`, and the references). Keep the blue interactive palette (`--blue` / `--blue-bright`) and the hero `.ex` accent. No-invent guards: use only the real Portal surfaces as written — the branded store, the event-sourced engine behind the one `Portal` facade (`Portal.enroll/2`, `Portal.courses_of/1`, `Portal.progress_of/1`), the closed `%Portal.Error{}` set, and the Phoenix web modules `PortalWeb.Endpoint`/`PortalWeb.Router`; cite the companion F5 course (`/elixir/pragmatic/engine-lab`) for OTP internals rather than re-teaching them. Voice rules: no first person, no exclamation marks, no emoji, and none of just / simply / obviously.
