# F6.02.3 — Writing a plug (dive)

- Route (served): `/elixir/phoenix/routing/plugs`.
- File: `/Users/jonny/dev/jonnify/elixir/phoenix/routing/plugs.html`.
- Place in the chapter: the third and last of the three F6.02 dives (routes → pipelines → plugs). It teaches the connection-in, connection-out contract every stage of the request path shares, and `halt/1` as the basis of auth. It closes the F6.02 module and hands off to F6.03 (Ecto).
- Accent: blue (the F6 · Phoenix chapter accent).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F6.02 · part 3 of 3`

Hero h1 (verbatim): Writing a `plug`

Hero lede (verbatim): "Everything in the request path is a plug, so writing one is how you add behaviour anywhere along it. The contract is tiny: a **module plug** implements `init/1`, which runs once at compile time and returns the options, and `call/2`, which takes a `conn` and the options and returns a `conn`. A **function plug** is a plain function of `(conn, opts)` that returns a `conn`. The one extra move that matters is `halt/1`: a plug that halts the connection stops the rest of the pipeline from running, which is exactly how an auth plug refuses a request before any action sees it. Master this contract and pipelines, the router, and the endpoint stop being framework magic."

Kicker (verbatim): "See the three parts of the contract, watch `halt` short-circuit the chain, then read a real `RequireUser` plug and a function plug."

## Sections

In order:
1. `#contract` — **The plug contract**: `call/2`, `init/1`, `halt/1`. Interactive selector. Takeaway: "A plug is a function from a connection to a connection. Once that clicks, the endpoint, every pipeline step, and the router are all the same thing — and you can add your own step anywhere in the line."
2. `#flow` — **How halt short-circuits**: plugs run in order; a `halt/1` stops the walk so no later plug or action runs. Static flow figure (`:fetch_session` → `RequireUser` → controller action, with a `halt() + redirect` branch). Takeaway: "`halt` is the difference between a plug that *checks* and a plug that *enforces*. Without it, returning a redirect still lets the action run; with it, the request stops where the decision was made."
3. `#code` — **A real plug**: the real Elixir code block (below). Closes with a `.bridge` (conn in, conn out → halt to enforce) and a `.note` that completes F6.02 and hands off to F6.03 (Ecto).

Running example: the `PortalWeb.RequireUser` module plug (the one the `:require_auth` pipeline runs) plus a one-line function plug.

Real Elixir code shown (`#code`, verbatim):
```
defmodule PortalWeb.RequireUser do
  import Plug.Conn
  import Phoenix.Controller, only: [redirect: 2, put_flash: 3]

  # init/1 runs at compile time; its result is passed to call/2
  def init(opts), do: opts

  # call/2 takes the conn and returns a conn
  def call(conn, _opts) do
    case get_session(conn, :user_id) do
      nil ->
        conn
        |> put_flash(:error, "Please sign in")
        |> redirect(to: "/login")
        |> halt()                       # stop the pipeline — no action runs

      user_id ->
        assign(conn, :current_user_id, user_id)
    end
  end
end

# a function plug: a plain function of (conn, opts) that returns a conn
def put_request_time(conn, _opts), do: assign(conn, :req_at, DateTime.utc_now())
```

## The interactives

Figure 1 — `The contract · select a part` (`#pgTitle`).
- Control group `#pgSel` (`role="group"`, `aria-label="Plug contract part"`), buttons `data-k`: `call` (label `call/2`, active default), `init` (label `init/1`), `halt` (label `halt/1`).
- SVG row ids: `#pgRow_call`, `#pgRow_init`, `#pgRow_halt`; readouts `#pgOut`, `#pgRole`, `#pgResult`.
- Pure function: `pick(k)` highlights the selected row and writes the readout from the `PARTS` table; `pick('call')` runs on load.
- Readout strings (verbatim from `PARTS`):
  - `call` — `call/2` / `conn in, conn out` / "The work, run on every request: call(conn, opts) takes the connection and the init options and returns a connection — assign a value, set a header, or branch and halt."
  - `init` — `init/1` / `compile-time options` / "Runs once when the pipeline is compiled, not per request. Its return value is the opts passed to call/2, so any expensive option preparation happens at build time."
  - `halt` — `halt/1` / `stop the pipeline` / "conn |> halt() marks the connection halted; Phoenix stops walking the pipeline, so no later plug and no action runs. The response the halting plug set is what the client receives."
- The SVG row text reads: `call/2` — `def call(conn, opts), do: conn — the work, per request` (`conn → conn`); `init/1` — `def init(opts), do: opts — runs once, at compile time` (`compile time`); `halt/1` — `conn |> halt() — stop; no later plug or action runs` (`early exit`).

Figure 2 — static, `A conn through the pipeline · halt stops the chain` (`#pgFlowTitle`). No controls; a conn flows `:fetch_session` → `RequireUser` (`user? halt : assign`) → `controller action` (`skipped when halted`), with a `halt() + redirect` box (`response sent here`) and the foot text `no later plug or action runs after halt; the connection set by the halting plug is the response`.

Footer build-stamp decoder: the real id is `TSK0NdO31kPm2C`. Its decoded timestamp is `2026-06-01 21:38:46 UTC` (`#st-ts`). The `#stamp` decodes namespace/snowflake/node/seq/timestamp via the inline base-62 + epoch `1704067200000` decoder.

Degrade behaviour: all content is visible without JS (the SVGs carry the default state in markup). `prefers-reduced-motion: reduce` disables the scroll-reveal transition.

## References (#refs, verbatim)

Intro line: "Primary sources for this lesson, and where it connects in the course."

Sources:
- `https://hexdocs.pm/plug/readme.html` — Plug — the composable middleware spec — the `init/1` + `call/2` contract and `halt/1`.
- `https://hexdocs.pm/phoenix/routing.html` — Phoenix — Routing — verbs, paths, scopes, and the pipelines plugs run in.
- `https://hexdocs.pm/phoenix/controllers.html` — Phoenix — Controllers — actions and rendering, the stage a plug guards.

Related in this course:
- `/elixir/phoenix/routing` — F6.02 · Routing, controllers & plugs
- `/elixir/phoenix/routing/pipelines` — Pipelines & scopes

## Wiring

- route-tag (verbatim): `/` `elixir` `/` `phoenix` `/` `routing` `/` `plugs` (the last segment `plugs` is the current `.rcur`; `elixir`, `phoenix`, `routing` link to `/elixir`, `/elixir/phoenix`, `/elixir/phoenix/routing`).
- crumbs (verbatim): `F6` (→ `/elixir/phoenix`) `/` `F6.02` (→ `/elixir/phoenix/routing`) `/` `plugs` (the `.here`).
- toc-mini (verbatim): `#contract` "The plug contract"; `#flow` "How halt short-circuits"; `#code` "A real plug".
- pager: prev → `/elixir/phoenix/routing/pipelines` label `← F6.02.2 · pipelines & scopes`; next → `/elixir/phoenix/routing` label `Back to F6.02 · overview →`.
- footer columns (verbatim): brand column with foot-tag "Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir." · **Chapters** — `/elixir/algebra` F1 · Algebra; `/elixir/functional` F2 · Functional Programming; `/elixir/language` F3 · The Elixir Language; `/elixir/algorithms` F4 · Algorithms & Data Structures; `/elixir/pragmatic` F5 · Pragmatic Programming; `/elixir/phoenix` F6 · Phoenix Framework · **The course** — `/elixir` Course home; `/elixir/course` Contents & history; `/elixir/algebra/functions` Start · F1.01.
- Page meta — `<title>` (verbatim): `Writing a plug — F6.02.3 · jonnify`. `<meta description>` (verbatim): "The contract every stage of the pipeline shares: a plug is init/1 plus call(conn, opts), taking a conn and returning a conn. A module plug that loads the current user and halt/1 to stop the pipeline early; a function plug for small steps. Everything in the request path — endpoint, pipeline, router — is a plug."

## Build instruction

To rebuild this dive, copy the `head…</style>`, the `header.site`, the `footer.site-foot`, and the trailing `<script>` blocks verbatim from a recent built sibling on this blue chapter accent — the model sibling is `/Users/jonny/dev/jonnify/elixir/phoenix/routing/pipelines.html` (the adjacent F6.02.2 dive, identical shell). Change only the `<title>`/`<meta description>`, the `route-tag`, and the `<main>` body. Use only the real Portal surfaces as written — the `PortalWeb.RequireUser` plug, the `init/1` + `call/2` + `halt/1` contract, `Plug.Conn`/`Phoenix.Controller` imports, the single `Portal` facade, the closed `%Portal.Error{}` set; cite the companion course for OTP internals rather than re-teaching, and invent no route, id, readout string, code token, or reference URL. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously.
