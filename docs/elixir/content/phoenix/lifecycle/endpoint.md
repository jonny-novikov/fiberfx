# F6.01.2 — The endpoint, supervised (dive)

- **Route (served):** `/elixir/phoenix/lifecycle/endpoint`
- **File:** `elixir/phoenix/lifecycle/endpoint.html`
- **Place in the chapter:** the second of the three F6.01 dives (part 2 of 3). It zooms into the entry plug from part 1 (`request-path`) and shows its second hat — a supervised child of the F5.09 OTP tree — before part 3 (`controllers`) reaches the facade seam.
- **Accent:** blue (F6 · Phoenix; hero `.ex` accent on "supervised"; interactive highlights `--blue` / `--blue-bright`).
- **Status:** built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F6.01 · part 2 of 3`

`h1` (verbatim): `The endpoint, supervised` ("supervised" is the accent `.ex` span).

Hero lede (`.lede`, verbatim):

> The endpoint wears two hats, and seeing both is what connects Phoenix to everything F5 built. As a **plug**, `PortalWeb.Endpoint` is the outermost layer of the request lifecycle — the fixed stack of static files, parsers, and session that every request passes through before the router. As a **process**, it is a supervised child of the OTP tree: when the application boots, the endpoint starts listening, and if it crashes its supervisor restarts it, exactly like the engine and the store from F5. That second hat is the whole structural change F6 makes — one more child added to the tree the F5.09 lab assembled, sitting beside the engine rather than wrapping it.

Kicker (`.kicker`, verbatim):

> See the endpoint's two roles, where it sits in the supervision tree, and the code for both — the plug stack and the one-line addition to the tree.

## Sections

In order:

1. **Two roles, one module** (`#roles`) — the same module configured two ways: its `plug` declarations make it the head of the request pipeline; its place in `Application.start/2` makes it a supervised process owning the listening socket. Carries the role-selector figure and a `.take`.
2. **Where it sits in the tree** (`#tree`) — the endpoint added to the F5.09 supervision tree under `:one_for_one`; the store and engine entries do not move; the endpoint is one more child. Carries the supervision-tree figure and a `.take`.
3. **The endpoint in code** (`#code`) — the endpoint module as an ordered list of plugs ending in the router, and the one-line addition to `Application.start/2`. Carries the Elixir code block, a `.bridge`, and a forward `.note`.

**Running example:** `PortalWeb.Endpoint` as both plug and supervised child of `Portal.Supervisor`, beside `Portal.EventStore` and `Portal.Engine`.

**Real Elixir code shown** (`pre.code`, the endpoint module + the tree addition):

```elixir
# the endpoint: the head of the request pipeline (a plug) ...
defmodule PortalWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :portal

  socket "/live", Phoenix.LiveView.Socket     # LiveView entry (F6.06)

  plug Plug.Static, at: "/", from: :portal
  plug Plug.RequestId
  plug Plug.Parsers, parsers: [:urlencoded, :multipart, :json], json_decoder: Jason
  plug Plug.Session, store: :cookie, key: "_portal_key"
  plug PortalWeb.Router                       # the last plug: match → controller
end

# ... and a supervised child of the F5.09 tree (one line added)
children = [
  Portal.EventStore.adapter(),   # F5 — unchanged
  {Portal.Engine, []},            # F5 — unchanged
  PortalWeb.Endpoint             # F6 — supervised alongside
]
Supervisor.start_link(children, strategy: :one_for_one, name: Portal.Supervisor)
```

## The interactives

### Figure 1 — "The endpoint's roles · select one" (`#epTitle`)

- **`<figure class="fig">`**, heading `#epTitle` "The endpoint's roles · select one". Control group `.solid-select#epSel` (role `group`, label "Endpoint role") with three buttons by `data-k`: `stack` (label "plug stack", starts `.active`), `socket` (label "socket"), `tree` (label "tree child"). SVG `viewBox="0 0 720 180"` with rows `#epRow_stack`, `#epRow_socket`, `#epRow_tree`. Readout `.geo-readout#epOut`; spans `#epRole` (default "Plug stack") and `#epResult` (default "static files, parsers, session, router").
- **Pure function:** `pick(k)` over `ORDER = ['stack','socket','tree']` — toggles `#epSel` button `.active`/`aria-pressed`; restrokes the matching `ROLES[id].row` rect (`BLUE_MUTE`/`2`/`#11203a` on, `#3a4263`/`1.3`/`#10162b` off); sets `#epRole`←`R.name`, `#epResult`←`R.is`, writes "The <b>name</b> role — is. desc" into `#epOut.innerHTML`. Initial call `pick('stack')`.
- **`ROLES` dataset (`name` · `is` · `row` · `desc`, verbatim):**
  - stack — "Plug stack" · "static files, parsers, session, router" · `epRow_stack` · "As a plug, the endpoint runs a fixed, ordered stack and ends by calling the router. This is the head of the request lifecycle — the first code every request touches."
  - socket — "Socket" · "LiveView & channel entry" · `epRow_socket` · "The endpoint also declares sockets: socket \"/live\" is the WebSocket entry LiveView uses in F6.06, and channels use the same mechanism in F6.07. HTTP and the live connection share one front door."
  - tree — "Tree child" · "supervised in F5's tree" · `epRow_tree` · "In Application.start/2 the endpoint is a child spec, started and supervised beside Portal.Engine and the store under :one_for_one. A crash is restarted by the supervisor — the same fault tolerance the engine has."
- **`.take` (verbatim):** "One module, two contracts: a plug for the request path and a child spec for the supervisor. The first makes it part of the lifecycle; the second makes it part of OTP — the bridge between HTTP and the BEAM."

### Figure 2 — "Portal.Supervisor · one new child" (`#epTreeTitle`)

- **`<figure class="fig">`**, heading `#epTreeTitle` "Portal.Supervisor · one new child". Static `<svg viewBox="0 0 720 200">` — no controls, no JS — the `PORTAL.SUPERVISOR` (`:one_for_one`) node over three children: `EVENTSTORE` (F5 · store), `ENGINE` (F5 · GenServer), and the highlighted `PORTALWEB.ENDPOINT` (F6 · web (new)). Footer text: "the endpoint owns the listening socket; the engine and store are unchanged siblings".
- **`.take` (verbatim):** "A web server that is a supervised process is a BEAM idea, not a Phoenix one. The endpoint inherits the same fault tolerance as the engine: if it falls over, the supervisor brings it back, and the engine beside it never noticed."

### Degrade behaviour

The static supervision-tree figure needs no JS. The `#epSel` role selector renders all three buttons and rows in markup; `pick('stack')` paints the default `#epOut`/`#epRole`/`#epResult` on load but the controls and SVG are intact without JS. The `.arc-flow` animation and `html.js .reveal` are motion-gated (reveal content is visible without JS). No browser storage.

### Footer build-stamp decoder (`#stamp`)

- **Stamp id:** `TSK0NdLjFdQxyC` (in `#stampId`); panel `#st-ts` hard-codes "2026-06-01 21:06:19 UTC".
- **Pure functions:** `b62decode(s)` (base62 → BigInt), `pad2(x)`, `decodeBranded(id)` — `ns = id.slice(0,3)`, `snow = b62decode(id.slice(3))`, `ts = snow >> 22n`, `node = (snow >> 12n) & 0x3FFn`, `seq = snow & 0xFFFn`, epoch `EPOCH_MS = 1704067200000`; fills `#st-ns`/`#st-snow`/`#st-node`/`#st-seq`/`#st-ts`. Toggle on click / Enter / Space sets `.open` and `aria-expanded`. Decoding `TSK0NdLjFdQxyC` resolves to the panel timestamp 2026-06-01 21:06:19 UTC.

## References (`#refs`, verbatim)

Intro line: "Primary sources for this lesson, and where it connects in the course."

**Sources**
- [Overview — Phoenix documentation](https://hexdocs.pm/phoenix/overview.html) — the framework at a glance.
- [Request life-cycle — Phoenix documentation](https://hexdocs.pm/phoenix/request_lifecycle.html) — endpoint to view.

**Related in this course**
- F6.01 · Architecture & the request lifecycle → `/elixir/phoenix/lifecycle`
- The request path through the lifecycle → `/elixir/phoenix/lifecycle/request-path`
- F5.09 · The Portal engine, supervised → `/elixir/pragmatic/engine-lab`

## Wiring

- **route-tag (verbatim):** `<span class="rsep">/</span><a href="/elixir">elixir</a><span class="rsep">/</span><a href="/elixir/phoenix">phoenix</a><span class="rsep">/</span><a href="/elixir/phoenix/lifecycle">lifecycle</a><span class="rsep">/</span><span class="rcur">endpoint</span>` — `/ elixir / phoenix / lifecycle / endpoint`, current segment `endpoint`.
- **crumbs (verbatim):** `F6` → `/elixir/phoenix` · sep `/` · `F6.01` → `/elixir/phoenix/lifecycle` · sep `/` · here `endpoint` (no link).
- **toc-mini:** `#roles` ("Two roles, one module") · `#tree` ("Where it sits in the tree") · `#code` ("The endpoint in code").
- **pager:** prev → `/elixir/phoenix/lifecycle/request-path` ("← F6.01.1 · request lifecycle"); next → `/elixir/phoenix/lifecycle/controllers` ("Next · controllers & the facade seam →").
- **footer (`.foot-nav`, 3 columns):**
  - Brand: `.foot-logo` → `/elixir`; `.foot-tag` "Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir."
  - Chapters: `/elixir/algebra` ("F1 · Algebra"), `/elixir/functional` ("F2 · Functional Programming"), `/elixir/language` ("F3 · The Elixir Language"), `/elixir/algorithms` ("F4 · Algorithms & Data Structures"), `/elixir/pragmatic` ("F5 · Pragmatic Programming"), `/elixir/phoenix` ("F6 · Phoenix Framework").
  - The course: `/elixir` ("Course home"), `/elixir/course` ("Contents & history"), `/elixir/algebra/functions` ("Start · F1.01").
- **Page meta:** `<title>` "The endpoint, supervised — F6.01.2 · jonnify"; `<meta description>` "PortalWeb.Endpoint has two roles: the outermost plug — static files, parsers, session, the router — and a supervised process, one more child of the OTP tree the F5.09 lab assembled. The endpoint is where HTTP and OTP meet, and adding it to the tree is the whole structural change F6 makes."

## Build instruction

To rebuild this dive, copy the `<head>…</style>`, `<header class="site">`, `<footer class="site-foot">`, and both trailing `<script>` blocks verbatim from a recent BUILT blue-accent F6 sibling — the model page is `elixir/phoenix/lifecycle/request-path.html` (the adjacent F6.01.1 dive, identical chrome and a structurally identical `.solid-select`-driven figure) — then change only the `<title>`/`<meta description>`, the `.route-tag` (current segment `endpoint`), and the `<main>` body. Keep the blue interactive palette. No-invent guards: use only the real Portal surfaces as written — the branded store, the event-sourced engine behind the one `Portal` facade, the closed `%Portal.Error{}` set, and the Phoenix web modules `PortalWeb.Endpoint`/`PortalWeb.Router` with the actual plugs (`Plug.Static`, `Plug.RequestId`, `Plug.Parsers`, `Plug.Session`), the `socket "/live"` LiveView entry, and the supervised children `Portal.EventStore`/`Portal.Engine` under `Portal.Supervisor` (`:one_for_one`). Cite the companion F5 course (`/elixir/pragmatic/engine-lab`) for the OTP tree internals rather than re-teaching them. Voice rules: no first person, no exclamation marks, no emoji, and none of just / simply / obviously.
