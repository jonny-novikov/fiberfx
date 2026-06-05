# F6.01.1 — The request lifecycle (dive)

- **Route (served):** `/elixir/phoenix/lifecycle/request-path`
- **File:** `elixir/phoenix/lifecycle/request-path.html`
- **Place in the chapter:** the first of the three F6.01 dives (part 1 of 3). It traces one request end to end — the "what & why" of the lifecycle — before the endpoint dive (part 2) zooms into the entry plug and the controllers dive (part 3) reaches the facade seam.
- **Accent:** blue (F6 · Phoenix; hero `.ex` accent on "lifecycle"; interactive highlights `--blue` / `--blue-bright`).
- **Status:** built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F6.01 · part 1 of 3`

`h1` (verbatim): `The request lifecycle` ("lifecycle" is the accent `.ex` span).

Hero lede (`.lede`, verbatim):

> Trace one request all the way through and Phoenix stops being a framework and becomes a pipeline you can read. A browser sends `GET /courses/42`; **Bandit** accepts the connection and hands a `conn` to `PortalWeb.Endpoint`; the endpoint runs a fixed stack of plugs; the router matches the path to a controller action through a pipeline; the action calls `Portal.courses_of/1` — the one line of domain work — and a view renders the result back into the same `conn`. Every stage has the same shape, a connection in and a connection out, which is why the whole path composes.

Kicker (`.kicker`, verbatim):

> Follow the five steps, see what the endpoint's plug stack actually contains, then read the path in code. You can `curl` the result.

## Sections

In order:

1. **A request, five steps** (`#steps`) — the connection threaded through five stages, each a plain function of `conn`; only the controller action does domain work. Carries the step-selector figure and a `.take`.
2. **Inside the endpoint** (`#stack`) — the endpoint plug stack made concrete: a short ordered list of plugs ending in the router; order matters (sessions fetched before a controller reads them). Carries the static plug-stack figure and a `.take`.
3. **The path in code** (`#code`) — a route that names a controller action plus the action itself; the action calls the facade, branches on the closed error contract, hands a view its data. Carries the Elixir code block, a `.bridge`, and a forward `.note`.

**Running example:** `GET /courses/42` (a browser request) resolved by `Portal.courses_of/1`.

**Real Elixir code shown** (`pre.code`, the router line + the controller action):

```elixir
# 1. the router maps a path to a controller action (F6.02 builds this out)
get "/courses/:user_id", CourseController, :index

# 2. the action — the one step in the lifecycle that calls the engine
defmodule PortalWeb.CourseController do
  use PortalWeb, :controller

  def index(conn, %{"user_id" => uid}) do
    case Portal.courses_of(uid) do      # a facade query
      {:ok, courses} ->
        render(conn, :index, courses: courses)

      {:error, %Portal.Error{message: m}} ->
        conn |> put_status(422) |> render(:error, message: m)
    end
  end
end
```

## The interactives

### Figure 1 — "The request path · select a step" (`#rlTitle`)

- **`<figure class="fig">`**, heading `#rlTitle` "The request path · select a step". Control group `.solid-select#rlSel` (role `group`, label "Request step") with five buttons by `data-k`: `request`, `endpoint`, `router`, `action` (starts `.active`), `response`. SVG `viewBox="0 0 720 170"` with chips `#rlChip_request`, `#rlChip_endpoint`, `#rlChip_router`, `#rlChip_action`, `#rlChip_response`. Readout `.geo-readout#rlOut`; spans `#rlRole` (default "Controller action") and `#rlResult` (default "calls the Portal facade").
- **Pure function:** `pick(k)` over `ORDER = ['request','endpoint','router','action','response']` — toggles `#rlSel` button `.active`/`aria-pressed`; restrokes each chip (`BLUE_MUTE`/`2`/`#11203a` on, `#3a4263`/`1.3`/`#10162b` off); sets `#rlRole`←`S.name`, `#rlResult`←`S.does`, writes the bold name + does + desc into `#rlOut.innerHTML`. Initial call `pick('action')`.
- **`STEPS` dataset (`name` · `does` · `desc`, verbatim):**
  - request — "HTTP request" · "arrives at the endpoint" · "Bandit accepts the TCP connection and builds a Plug.Conn — verb, path, headers, body. Nothing Portal-specific yet; this is plain HTTP at the door."
  - endpoint — "Endpoint" · "runs the plug stack" · "PortalWeb.Endpoint threads the conn through its ordered plugs — static files, request id, parsers, session — and ends by calling the router. It is the outermost plug and a supervised process."
  - router — "Router" · "matches route + pipeline" · "The router runs a named pipeline (for example :browser: fetch session, protect from forgery) and matches the verb and path to exactly one controller action."
  - action — "Controller action" · "calls the Portal facade" · "The action is the only step that touches the domain: it calls Portal.courses_of/1, branches on the closed %Portal.Error{} contract, and assigns the result for a view. This is your code."
  - response — "Response" · "render + send" · "A view turns assigns into markup, the conn gets a status and body, and Phoenix sends it back down the same pipeline to the browser. The conn that entered is the conn that leaves."
- **`.take` (verbatim):** "The pipeline is composition, plug after plug. That uniformity is why you can insert authentication, logging, or parsing as one more plug without touching the others — and why the action stays small."

### Figure 2 — "The endpoint plug stack, top to bottom" (`#rlStackTitle`)

- **`<figure class="fig">`**, heading `#rlStackTitle` "The endpoint plug stack, top to bottom". Static `<svg viewBox="0 0 720 226">` — no controls, no JS — an ordered column of plug rows: `plug Plug.Static` (serves /assets), `plug Plug.RequestId · Plug.Telemetry` (trace + measure), `plug Plug.Parsers` (decode the body), `plug Plug.Session` (cookie session), and `plug PortalWeb.Router` (match → controller, the highlighted last row). Footer text: "each plug takes the conn and returns it; the router is the last plug in the stack".
- **`.take` (verbatim):** "There is no magic entry point — the endpoint is a plug whose last step is another plug, the router. \"Phoenix routing\" is what happens when the connection reaches the bottom of this list."

### Degrade behaviour

The static plug-stack figure needs no JS. The `#rlSel` step selector renders all five buttons and chips in markup; `pick('action')` paints the default `#rlOut`/`#rlRole`/`#rlResult` on load but the controls and SVG are intact without JS. The `.arc-flow` animation and `html.js .reveal` are motion-gated (`prefers-reduced-motion: reduce` disables them; reveal content is visible without JS). No browser storage.

### Footer build-stamp decoder (`#stamp`)

- **Stamp id:** `TSK0NdLjFKhRNw` (in `#stampId`); panel `#st-ts` hard-codes "2026-06-01 21:06:19 UTC".
- **Pure functions:** `b62decode(s)` (base62 over `0123…XYZabc…xyz` → BigInt), `pad2(x)`, `decodeBranded(id)` — `ns = id.slice(0,3)`, `snow = b62decode(id.slice(3))`, `ts = snow >> 22n`, `node = (snow >> 12n) & 0x3FFn`, `seq = snow & 0xFFFn`, epoch `EPOCH_MS = 1704067200000`, formatted to a UTC string; fills `#st-ns`/`#st-snow`/`#st-node`/`#st-seq`/`#st-ts`. Toggle on click / Enter / Space sets `.open` and `aria-expanded`. Decoding `TSK0NdLjFKhRNw` resolves to the panel timestamp 2026-06-01 21:06:19 UTC.

## References (`#refs`, verbatim)

Intro line: "Primary sources for this lesson, and where it connects in the course."

**Sources**
- [Overview — Phoenix documentation](https://hexdocs.pm/phoenix/overview.html) — the framework at a glance.
- [Request life-cycle — Phoenix documentation](https://hexdocs.pm/phoenix/request_lifecycle.html) — endpoint to view.

**Related in this course**
- The endpoint, supervised → `/elixir/phoenix/lifecycle/endpoint`
- Controllers & actions → `/elixir/phoenix/lifecycle/controllers`
- F6.02 · Routing, controllers & plugs → `/elixir/phoenix/routing`

## Wiring

- **route-tag (verbatim):** `<span class="rsep">/</span><a href="/elixir">elixir</a><span class="rsep">/</span><a href="/elixir/phoenix">phoenix</a><span class="rsep">/</span><a href="/elixir/phoenix/lifecycle">lifecycle</a><span class="rsep">/</span><span class="rcur">request-path</span>` — `/ elixir / phoenix / lifecycle / request-path`, current segment `request-path`.
- **crumbs (verbatim):** `F6` → `/elixir/phoenix` · sep `/` · `F6.01` → `/elixir/phoenix/lifecycle` · sep `/` · here `request-path` (no link).
- **toc-mini:** `#steps` ("A request, five steps") · `#stack` ("Inside the endpoint") · `#code` ("The path in code").
- **pager:** prev → `/elixir/phoenix/lifecycle` ("← F6.01 · overview"); next → `/elixir/phoenix/lifecycle/endpoint` ("Next · the endpoint, supervised →").
- **footer (`.foot-nav`, 3 columns):**
  - Brand: `.foot-logo` → `/elixir`; `.foot-tag` "Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir."
  - Chapters: `/elixir/algebra` ("F1 · Algebra"), `/elixir/functional` ("F2 · Functional Programming"), `/elixir/language` ("F3 · The Elixir Language"), `/elixir/algorithms` ("F4 · Algorithms & Data Structures"), `/elixir/pragmatic` ("F5 · Pragmatic Programming"), `/elixir/phoenix` ("F6 · Phoenix Framework").
  - The course: `/elixir` ("Course home"), `/elixir/course` ("Contents & history"), `/elixir/algebra/functions` ("Start · F1.01").
- **Page meta:** `<title>` "The request lifecycle — F6.01.1 · jonnify"; `<meta description>` "A request from the browser to the response, step by step: Bandit hands the connection to PortalWeb.Endpoint, the endpoint runs its plug stack, the router matches a route through a pipeline, the controller action calls the Portal facade, and the view renders the result. Only the facade call is domain work; the rest is the framework's pipeline."

## Build instruction

To rebuild this dive, copy the `<head>…</style>`, `<header class="site">`, `<footer class="site-foot">`, and both trailing `<script>` blocks verbatim from a recent BUILT blue-accent F6 sibling — the model page is `elixir/phoenix/lifecycle/endpoint.html` (the adjacent F6.01.2 dive, identical chrome and a structurally identical `.solid-select`-driven figure) — then change only the `<title>`/`<meta description>`, the `.route-tag` (current segment `request-path`), and the `<main>` body. Keep the blue interactive palette. No-invent guards: use only the real Portal surfaces as written — the branded store, the event-sourced engine behind the one `Portal` facade (`Portal.courses_of/1`, the closed `%Portal.Error{}` set), the Phoenix web modules `PortalWeb.Endpoint`/`PortalWeb.Router`/`CourseController`, and the actual endpoint plugs (`Plug.Static`, `Plug.RequestId`, `Plug.Telemetry`, `Plug.Parsers`, `Plug.Session`); Bandit is the HTTP server. Cite the companion F5 course for OTP internals rather than re-teaching them. Voice rules: no first person, no exclamation marks, no emoji, and none of just / simply / obviously.
