# F5.01.2 — A thin web server in Elixir (dive)

- Route (served): `/elixir/pragmatic/foundations/thin-server`
- File: `elixir/pragmatic/foundations/thin-server.html`
- Place in the chapter: the second of F5.01's three dives (part 2 of 3). After the roadmap names the path, this dive shows the actual server — a `Plug.Router` on `Bandit`, supervised — that makes the Portal runnable today, before the third dive turns its thinness into the replaceability discipline.
- Accent: burgundy (`--burgundy: #c4504c`; the F5 chapter accent). The in-page figure accents use blue (`--blue`, the engine-call step) and sage (the boot-path supervisor).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F5.01 · part 2 of 3`

Hero `h1` (verbatim): A thin web server in Elixir

Hero lede (`.lede`, verbatim):

> The server that makes the Portal runnable is small enough to read in one screen: a `Plug.Router` matched and dispatched by **Bandit**, a pure-Elixir HTTP server, added as one child in the supervision tree. Each route does exactly one thing — turn the request into a command or a query, call `Portal.Engine`, and send back the result. There is no framework here and no business logic; the router knows how to speak HTTP and nothing about the Portal's rules.

Kicker (`.kicker`, verbatim):

> Follow a request through the four steps of the server, then read the whole thing in code. You can `curl` it on day one.

## Sections

The teaching arc runs request-path → whole-server, with an advanced supervised-boot section:

1. **A request, four steps** (`#flow`) — Bandit accepts the connection, the router matches, the handler calls the engine, the result is sent; only the third step is real work. The `#tsSel` figure steps through it. `.take` (verbatim): "A thin server is mostly other people's code: Bandit speaks HTTP, Plug routes, Jason encodes. Your part is the one line in the middle that calls the Portal."
2. **The whole server** (`#code`) — the router IS the entire web layer; a `get` reads a query, a `post` writes a command mapped onto a status code, an unmatched request is a 404, and adding it to the tree as a `Bandit` child puts the Portal on a port. `.bridge`: "a request" → "one engine call". `.note` (verbatim): "Next: [**a web layer built for replacement**](/elixir/pragmatic/foundations/replaceable) — why this thinness is what lets Phoenix take over in F6."
3. **Booting the Portal as a supervised application** (`#bootTitle`, advanced `.reveal` section) — an OTP application is a started, supervised unit, not a folder of modules; `use Application` + `start/2`, the `mix.exs` `mod: {Portal.Application, []}` entry, and `Supervisor.start_link` with `strategy: :one_for_one`. Carries the `#bootFigTitle` boot-path diagram and a second `pre.code`. `.bridge`: "an application" → "one mod: line". `.take` (verbatim): "Wired through `mod:` from the first commit, the Portal boots as a supervised tree, so a falling child is restarted in place rather than dragging the node down with it."

Running example: a `POST /enroll` command and a `GET /courses/:user_id` query traced through the server.

The real Elixir code shown — first `pre.code`, the router:

```
defmodule Portal.Web.Router do
  use Plug.Router

  plug :match
  plug Plug.Parsers, parsers: [:urlencoded, :json], json_decoder: Jason
  plug :dispatch

  # read: a query, no side effects
  get "/courses/:user_id" do
    {:ok, courses} = Portal.Engine.query(:courses_of, user_id)
    send_resp(conn, 200, Jason.encode!(courses))
  end

  # write: a command, mapped onto a status code
  post "/enroll" do
    cmd = %Portal.Commands.EnrollLearner{
      user_id: conn.params["user"],
      course_id: conn.params["course"]
    }
    case Portal.Engine.dispatch(cmd) do
      {:ok, _event}    -> send_resp(conn, 201, "enrolled")
      {:error, reason} -> send_resp(conn, 422, to_string(reason))
    end
  end

  match _, do: send_resp(conn, 404, "not found")
end

# the whole server: one child in the supervision tree
children = [
  Portal.Engine,
  {Bandit, plug: Portal.Web.Router, port: 4000}
]
```

The second `pre.code` (the OTP entry point) shows `Portal.Application` with `use Application` and `start/2` starting `Supervisor.start_link(children, opts)` under `strategy: :one_for_one`, the `mix.exs` `application/0` carrying `mod: {Portal.Application, []}`, and `mix run --no-halt` plus `Process.whereis(Portal.Supervisor)` / `Supervisor.which_children/1` proving the tree is up.

## The interactives

### Figure — "The request path · select a step" (`#tsSel` selector + `#tsOut` readout)

- `<figure class="fig" aria-labelledby="tsTitle">`, title `#tsTitle` "The request path · select a step". A `.solid-select#tsSel` group of four `<button data-k>`s and an `<svg viewBox="0 0 720 170">` of four chips.
- Buttons (`data-k`, label): `request` "request" · `route` "route" · `engine` "engine" (`class="active"`) · `response` "response".
- SVG chip ids: `#tsChip_request`, `#tsChip_route`, `#tsChip_engine` (blue `#5a87c4`, the only real work), `#tsChip_response`.
- Pure function: `pick(k)` looks up `STEPS[k]`, toggles each `#tsSel` button's `active`/`aria-pressed`, restrokes each chip (`BLUE_MUTE = '#5a87c4'` when on, else `#3a4263`), and writes `#tsRole` (name), `#tsResult` (does), and `#tsOut.innerHTML` (`name — does. desc`). `ORDER = ['request','route','engine','response']`; initial call `pick('engine')`.
- Readout `STEPS` desc strings (verbatim; the desc embeds inline `<code class="inl">` markup):
  - request: name "HTTP request", does "arrives at the port" — "A raw request reaches Bandit on its port — a verb, a path, headers, maybe a body. Nothing Portal-specific yet; this is plain HTTP."
  - route: name "Plug.Router", does "match + dispatch" — "A tiny router matches the verb and path to one handler with `plug :match` and `plug :dispatch`. No controllers, no framework — a function per route."
  - engine: name "Portal.Engine", does "calls the engine" — "The handler turns the request into a command or a query and calls `dispatch/1` or `query/2`. This is the only real work; everything around it is plumbing."
  - response: name "send_resp", does "status + body" — "The engine's result is encoded — JSON via Jason — and sent with a status code: 200 for a read, 201 for a write, 422 for a rejected command."
- Static default: the `engine` button is `active` and the static labels (`step: Portal.Engine`, `does: calls the engine`) render in markup; `#tsOut` is empty until `pick('engine')` fills it.

### Second diagram — "The boot path · mix.exs to a running tree" (`#bootFigTitle`, static)

- `<figure class="fig" aria-labelledby="bootFigTitle">`, title "The boot path · mix.exs to a running tree". A static `<svg viewBox="0 0 720 196">`: `mix.exs` (`mod: {Portal.Application, []}`) → `Portal.Application` (`start/2`, sage `#7ba387`) → `Portal.Supervisor` (`strategy :one_for_one`) over two children, `Portal.Engine` (the domain core) and `Bandit` (`Plug.Router · port 4000`). Non-interactive; it illustrates the second `pre.code`.
- This section is a `.reveal` block, revealed by `IntersectionObserver` when JS is on; content is visible without JS, and the reveal is disabled under `prefers-reduced-motion`.

### Footer build-stamp decoder (`#stamp`)

- Stamp id: `TSK0NcqelSDYjQ` (in `#stampId`); panel `#st-ts` hard-codes "2026-06-01 13:51:30 UTC".
- Pure functions: `b62decode(s)`, `pad2(x)`, `decodeBranded(id)` — `ns = id.slice(0,3)`, `snow = b62decode(id.slice(3))`, `ts = snow >> 22n`, `node = (snow >> 12n) & 0x3FFn`, `seq = snow & 0xFFFn`, epoch `EPOCH_MS = 1704067200000`, formatted UTC. Toggle on click / Enter / Space.
- Decoding `TSK0NcqelSDYjQ`: namespace `TSK`; the snowflake over epoch `2024-01-01` resolves to the panel's stamped "2026-06-01 13:51:30 UTC".

## References (#refs, verbatim)

Intro line: "Primary sources for this lesson, and where it connects in the course."

**Sources**
- [Supervisor and Application — Elixir documentation](https://hexdocs.pm/elixir/supervisor-and-application.html) — `use Application`, the `mix.exs` `mod:` entry, `start/2`, and starting a supervisor with `strategy: :one_for_one`.

**Related in this course**
- F5.01 · Foundations → `/elixir/pragmatic/foundations`
- A web layer built for replacement → `/elixir/pragmatic/foundations/replaceable`
- F3.08 · Supervisors → `/elixir/language/otp/supervisors`

## Wiring

- route-tag (verbatim): `<span class="rsep">/</span><a href="/elixir">elixir</a><span class="rsep">/</span><a href="/elixir/pragmatic">pragmatic</a><span class="rsep">/</span><a href="/elixir/pragmatic/foundations">foundations</a><span class="rsep">/</span><span class="rcur">thin-server</span>`.
- crumbs: `F5` → `/elixir/pragmatic` · sep `/` · `F5.01` → `/elixir/pragmatic/foundations` · sep `/` · here `thin-server` (no link).
- toc-mini: `#flow` ("A request, four steps") · `#code` ("The whole server").
- pager: prev → `/elixir/pragmatic/foundations/roadmap` ("← F5.01.1 · roadmap"); next → `/elixir/pragmatic/foundations/replaceable` ("Next · built for replacement →").
- footer (3-column `.foot-nav`): Brand → `/elixir`; Chapters column `/elixir/algebra` ("F1 · Algebra"), `/elixir/functional` ("F2 · Functional Programming"), `/elixir/language` ("F3 · The Elixir Language"), `/elixir/algorithms` ("F4 · Algorithms & Data Structures"), `/elixir/pragmatic` ("F5 · Pragmatic Programming"), `/elixir/phoenix` ("F6 · Phoenix Framework"); The course column `/elixir` ("Course home"), `/elixir/course` ("Contents & history"), `/elixir/algebra/functions` ("Start · F1.01").
- Page meta: `<title>` "A thin web server in Elixir — F5.01.2 · jonnify"; `<meta description>` "A minimal HTTP front end for the Portal: a Plug.Router matched and dispatched by Bandit, where each route does one thing — turn the request into a command or a query, call Portal.Engine, and send the result. No framework, a handful of lines, and a running server you can curl today."

## Build instruction

To rebuild this page, copy the head…`</style>`, the `<header class="site">`, the `<footer class="site-foot">`, and both trailing `<script>` blocks verbatim from a recent BUILT sibling on the burgundy F5 accent — the model is its sibling dive `elixir/pragmatic/foundations/replaceable.html` (same `--burgundy` chapter, same single-column lesson `.hero`, same stamp/decoder and reveal scripts) — and change only `<title>`/`<meta>`, the route-tag, the crumbs, and the `<main>` body. The dive body carries the single-column `.hero`, the `#flow` section with the `#tsSel` request-path figure, the `#code` section with the router `pre.code` + `.bridge`, the advanced `.reveal` boot section (`#bootFigTitle` boot-path SVG + the `Portal.Application` `pre.code`), then `#refs` and pager. No-invent guards: use only the real Portal surfaces as written — `Portal.Engine.dispatch/1` / `Portal.Engine.query(:courses_of, …)`, the `Portal.Commands.EnrollLearner` command struct, `Portal.Web.Router`, `Portal.Application`, `Portal.Supervisor`, `Bandit`/`Plug`/`Jason` — and cite the companion `/elixir` course (F3.08 · Supervisors) for OTP internals rather than re-teaching them. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously.
