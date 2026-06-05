# F6.02.2 — Pipelines & scopes (dive)

- Route (served): `/elixir/phoenix/routing/pipelines`.
- File: `/Users/jonny/dev/jonnify/elixir/phoenix/routing/pipelines.html`.
- Place in the chapter: the second of the three F6.02 dives (routes → pipelines → plugs). It names the cross-cutting work that runs before an action as a reusable stack, then runs groups of routes through it.
- Accent: blue (the F6 · Phoenix chapter accent).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F6.02 · part 2 of 3`

Hero h1 (verbatim): Pipelines & `scopes`

Hero lede (verbatim): "Some work has to happen on the way to almost every action — fetch the session, reject a forged form, set security headers, require a logged-in user. A **pipeline** is how you name that work once: an ordered stack of plugs given a name like `:browser` or `:api`. A **scope** then runs a group of routes through one or more pipelines with `pipe_through`, so the cross-cutting steps are declared in a single place rather than copied into every controller. Stack pipelines and a route can require both the browser basics and authentication before it is ever reached — and the action stays as thin as it was in F6.01."

Kicker (verbatim): "See three common pipelines, how scopes route groups of paths through them, then the router that declares them. Auth is not special — it is one more pipeline."

## Sections

In order:
1. `#pipelines` — **Three pipelines**: `:browser`, `:api`, `:require_auth`. Interactive selector. Takeaway: "Name the work, not the repetition. A pipeline is the difference between "every action remembers to check auth" and "these routes go through `:require_auth`" — the second cannot be forgotten."
2. `#scopes` — **Scopes route through pipelines**: a scope is a group of routes with a shared prefix and a `pipe_through`. Static three-scope figure. Takeaway: "Scopes are how one app serves a browser and an API without tangling them: the routes can even share a path, because the pipeline in front decides what kind of request each scope expects."
3. `#code` — **The router**: the real Elixir code block (below). Closes with a `.bridge` (name the work → route groups through it) and a `.note` pointing to plugs.

Running example: a `:browser`/`:require_auth` split between a public root scope and a protected `/dashboard` scope.

Real Elixir code shown (`#code`, verbatim):
```
pipeline :browser do
  plug :fetch_session
  plug :fetch_live_flash
  plug :protect_from_forgery
  plug :put_secure_browser_headers
end

pipeline :require_auth do
  plug PortalWeb.RequireUser         # a plug we write in F6.02.3
end

scope "/", PortalWeb do
  pipe_through :browser
  get "/courses/:id", CourseController, :show
end

scope "/dashboard", PortalWeb do
  pipe_through [:browser, :require_auth]   # stack pipelines
  live "/", DashboardLive
end
```

## The interactives

Figure 1 — `Pipelines · select one` (`#plTitle`).
- Control group `#plSel` (`role="group"`, `aria-label="Pipeline"`), buttons `data-k`: `browser` (label `:browser`, active default), `api` (label `:api`), `auth` (label `:require_auth`).
- SVG row ids: `#plRow_browser`, `#plRow_api`, `#plRow_auth`; readouts `#plOut`, `#plRole`, `#plResult`.
- Pure function: `pick(k)` highlights the selected row and writes the readout from the `PIPES` table; `pick('browser')` runs on load.
- Readout strings (verbatim from `PIPES`):
  - `browser` — `:browser` / `session, CSRF, headers` / "The pipeline for HTML pages: fetch_session, fetch_live_flash, protect_from_forgery, and secure browser headers. Almost every user-facing route pipes through it."
  - `api` — `:api` / `accepts JSON` / "The pipeline for machine clients: plug :accepts, ["json"]. No session and no CSRF — a token-authenticated JSON API does not need them."
  - `auth` — `:require_auth` / `require a logged-in user` / "A pipeline whose plug loads the current user from the session and halts with a redirect if none is present. Stacked after :browser on protected scopes. The plug itself is written in F6.02.3."
- `#plOut` template (verbatim): `The <b>{name}</b> pipeline — {runs}. {desc}`. The SVG row text for `:browser` reads `fetch_session · fetch_live_flash · protect_from_forgery · headers`; `:api` reads `accepts ["json"] — no session, no CSRF`; `:require_auth` reads `RequireUser — load the user, halt if missing (F6.02.3)`.

Figure 2 — static, `Three scopes, three pipe_through choices` (`#plScopeTitle`). No controls; three boxed scopes: `scope "/"` → `pipe_through :browser`; `scope "/dashboard"` → `:browser, :require_auth` (`user loaded & checked` `before any route`); `scope "/api"` → `pipe_through :api` (`JSON in / JSON out`, `no session`).

Footer build-stamp decoder: the real id is `TSK0NdO31QGFnc`. Its decoded timestamp is `2026-06-01 21:38:46 UTC` (`#st-ts`). The `#stamp` decodes namespace/snowflake/node/seq/timestamp via the inline base-62 + epoch `1704067200000` decoder.

Degrade behaviour: all content is visible without JS (the SVGs carry the default state in markup). `prefers-reduced-motion: reduce` disables the scroll-reveal transition.

## References (#refs, verbatim)

Intro line: "Primary sources for this lesson, and where it connects in the course."

Sources:
- `https://hexdocs.pm/phoenix/routing.html` — Routing — Phoenix documentation — verbs, paths, and scopes.
- `https://hexdocs.pm/phoenix/controllers.html` — Controllers — Phoenix documentation — actions and rendering.
- `https://hexdocs.pm/plug/readme.html` — `Plug` — the composable middleware spec — the contract a pipeline stacks.

Related in this course:
- `/elixir/phoenix/routing` — F6.02 · Routing, controllers & plugs
- `/elixir/phoenix/routing/routes` — F6.02.1 · Routes & verbs
- `/elixir/phoenix/routing/plugs` — F6.02.3 · Writing a plug

## Wiring

- route-tag (verbatim): `/` `elixir` `/` `phoenix` `/` `routing` `/` `pipelines` (the last segment `pipelines` is the current `.rcur`; `elixir`, `phoenix`, `routing` link to `/elixir`, `/elixir/phoenix`, `/elixir/phoenix/routing`).
- crumbs (verbatim): `F6` (→ `/elixir/phoenix`) `/` `F6.02` (→ `/elixir/phoenix/routing`) `/` `pipelines` (the `.here`).
- toc-mini (verbatim): `#pipelines` "Three pipelines"; `#scopes` "Scopes route through pipelines"; `#code` "The router".
- pager: prev → `/elixir/phoenix/routing/routes` label `← F6.02.1 · routes & verbs`; next → `/elixir/phoenix/routing/plugs` label `Next · writing a plug →`.
- footer columns (verbatim): brand column with foot-tag "Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir." · **Chapters** — `/elixir/algebra` F1 · Algebra; `/elixir/functional` F2 · Functional Programming; `/elixir/language` F3 · The Elixir Language; `/elixir/algorithms` F4 · Algorithms & Data Structures; `/elixir/pragmatic` F5 · Pragmatic Programming; `/elixir/phoenix` F6 · Phoenix Framework · **The course** — `/elixir` Course home; `/elixir/course` Contents & history; `/elixir/algebra/functions` Start · F1.01.
- Page meta — `<title>` (verbatim): `Pipelines & scopes — F6.02.2 · jonnify`. `<meta description>` (verbatim): "A named pipeline is a reusable, ordered stack of plugs; a scope runs a group of routes through one with pipe_through. The :browser pipeline fetches the session and protects from forgery; :api accepts JSON; auth becomes one more pipeline that requires a logged-in user before a route is reached."

## Build instruction

To rebuild this dive, copy the `head…</style>`, the `header.site`, the `footer.site-foot`, and the trailing `<script>` blocks verbatim from a recent built sibling on this blue chapter accent — the model sibling is `/Users/jonny/dev/jonnify/elixir/phoenix/routing/routes.html` (the adjacent F6.02.1 dive, identical shell). Change only the `<title>`/`<meta description>`, the `route-tag`, and the `<main>` body. Use only the real Portal surfaces as written — the named `:browser`/`:api`/`:require_auth` pipelines, `PortalWeb.RequireUser`, `CourseController`, `DashboardLive`, the single `Portal` facade, the closed `%Portal.Error{}` set; cite the companion course for OTP internals rather than re-teaching, and invent no route, id, readout string, code token, or reference URL. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously.
