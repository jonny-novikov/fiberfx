# F6.02 · Routing, controllers & plugs

> The second web module builds out the middle of the F6.01 lifecycle. A route maps a verb and path to a controller
> action; a named pipeline is a reusable stack of plugs that runs first; a scope runs a group of routes through one.
> Underneath all three is the plug contract — `init/1`, `call/2`, and `halt/1`. This guide ships the copy-paste
> **build prompts** that produce the router, the `:browser` and `:require_auth` pipelines, a `RequireUser` module
> plug, and a function plug. Run them in order and verify against the definition of done. The controllers stay as thin
> as they were in F6.01.

Module guide · part of [F6 · Phoenix Framework](phoenix.md) · prev: [F6.01 · the lifecycle](f6-01-lifecycle.md)

## What you'll build

The match in the middle of the request lifecycle, with cross-cutting work named once instead of copied per action:

- a **router** with read and write routes (`get`, `post`), a `resources` route, and a `live` route, all ending at a
  thin controller (or a LiveView);
- **verified `~p` paths** so every URL you build is checked against the router at compile time;
- a **`:browser` pipeline** (session, flash, CSRF, secure headers) and an **`:api` pipeline** (`accepts ["json"]`);
- a **`:require_auth` pipeline** running a `RequireUser` plug, stacked after `:browser` on a protected scope;
- a **`RequireUser` module plug** — `init/1` plus `call/2`, loading the user from the session and `halt/1`-ing with a
  redirect when none is present;
- a **function plug** — a one-line `(conn, opts)` step, to show the same contract without a module.

## Concepts

- **Routes name actions once.** The router is the only place a controller action is named; everything else builds URLs
  with `~p`, which the compiler verifies. A renamed path breaks the build, not the page.
- **A pipeline names the work, not the repetition.** Auth, sessions, and headers are declared once as a named stack of
  plugs. A route either goes through `:require_auth` or it does not — it cannot "forget" to check.
- **A scope is a group with a `pipe_through`.** Public pages run through `:browser`; a protected area stacks
  `[:browser, :require_auth]`; an API runs through `:api`. The same path can appear in two scopes with different plugs
  in front.
- **Everything is a plug.** `call(conn, opts)` takes a connection and returns one; `init/1` prepares options at
  compile time. The endpoint, each pipeline step, and the router are all plugs, which is why they compose.
- **`halt/1` is enforcement.** A plug that halts stops the pipeline — no later plug and no action runs — and its
  response is sent. That is the difference between a plug that checks and one that enforces.

## Specs

**Route kinds (`PortalWeb.Router`):**

| Kind | Example | Maps to |
| --- | --- | --- |
| `get` | `get "/courses/:id", CourseController, :show` | a read action; `:id` arrives in params |
| `post` | `post "/enroll", EnrollmentController, :create` | a write action issuing a facade command |
| `resources` | `resources "/lessons", LessonController, only: [:show]` | the RESTful set (trimmed with `only:`/`except:`) |
| `live` | `live "/enroll/:id", EnrollmentLive` | a LiveView over the endpoint's socket |

**Pipelines:**

| Pipeline | Plugs | For |
| --- | --- | --- |
| `:browser` | `fetch_session`, `fetch_live_flash`, `protect_from_forgery`, `put_secure_browser_headers` | HTML pages |
| `:api` | `accepts ["json"]` | JSON clients |
| `:require_auth` | `PortalWeb.RequireUser` | protected scopes (stacked after `:browser`) |

**The plug contract (`PortalWeb.RequireUser`):**

| Callback | Does | Returns |
| --- | --- | --- |
| `init/1` | prepare options once, at compile time | the opts passed to `call/2` |
| `call/2` | load `:user_id` from the session; `assign` it, or `halt` with a redirect | a `conn` |

**Touched files:** `lib/portal_web/router.ex`, `lib/portal_web/plugs/require_user.ex`,
`lib/portal_web/controllers/course_controller.ex` (from F6.01).

## Build it

1. **Routes.** Add read, write, resources, and live routes inside a `:browser` scope.

   ```elixir
   scope "/", PortalWeb do
     pipe_through :browser

     get  "/courses",     CourseController, :index
     get  "/courses/:id", CourseController, :show
     post "/enroll",      EnrollmentController, :create
     resources "/lessons", LessonController, only: [:show]
     live "/enroll/:id", EnrollmentLive
   end
   ```

2. **Pipelines.** Declare `:browser`, `:api`, and `:require_auth` at the top of the router.

   ```elixir
   pipeline :browser do
     plug :fetch_session
     plug :fetch_live_flash
     plug :protect_from_forgery
     plug :put_secure_browser_headers
   end

   pipeline :api do
     plug :accepts, ["json"]
   end

   pipeline :require_auth do
     plug PortalWeb.RequireUser
   end
   ```

3. **A protected scope.** Stack pipelines so a dashboard requires both the browser basics and a logged-in user.

   ```elixir
   scope "/dashboard", PortalWeb do
     pipe_through [:browser, :require_auth]
     live "/", DashboardLive
   end
   ```

4. **The `RequireUser` plug.** Load the user, assign on success, halt on failure.

   ```elixir
   defmodule PortalWeb.RequireUser do
     import Plug.Conn
     import Phoenix.Controller, only: [redirect: 2, put_flash: 3]

     def init(opts), do: opts

     def call(conn, _opts) do
       case get_session(conn, :user_id) do
         nil ->
           conn
           |> put_flash(:error, "Please sign in")
           |> redirect(to: "/login")
           |> halt()

         user_id ->
           assign(conn, :current_user_id, user_id)
       end
     end
   end
   ```

5. **A function plug.** The same contract, inline.

   ```elixir
   def put_request_time(conn, _opts), do: assign(conn, :req_at, DateTime.utc_now())
   ```

6. **Verify.** `mix phx.routes` lists every route; an unauthenticated request to `/dashboard` redirects to `/login`
   and never reaches the LiveView; a logged-in request reaches it with `@current_user_id` assigned; a `~p` path with a
   typo produces a compile warning.

## Real-world example

A real router has a public surface and a guarded one, and the difference is which pipeline a scope runs through. The
browser scope serves pages; an `/admin` scope runs the same `:browser` plus a `:require_admin` pipeline; an `/api`
scope runs a token pipeline that answers JSON, not redirects:

```elixir
scope "/", PortalWeb do
  pipe_through :browser
  get "/", PageController, :home
  resources "/courses", CourseController, only: [:index, :show]
end

scope "/admin", PortalWeb.Admin, as: :admin do
  pipe_through [:browser, :require_admin]          # two stacks, composed
  resources "/courses", CourseController            # full CRUD, gated
  live "/dashboard", DashboardLive
end

scope "/api", PortalWeb.Api do
  pipe_through :api_auth                            # token in, 401 JSON on failure
  resources "/courses", CourseController, only: [:index, :show]
end
```

The `:require_admin` plug is the same `RequireUser` shape from the module — load the current user, check a role, and
`halt/1` with a redirect when it fails. The API path differs only in its failure response: `halt/1` after sending a
401 JSON body, because an API client cannot follow a login redirect. One router, three trust levels, no per-action
auth checks.

## Build prompts

> Paste into an agent in order. Each prompt carries its spec and acceptance criteria. The Portal stays runnable after
> each one.

```text
PROMPT 1 — Routes and verified paths
In PortalWeb.Router, inside scope "/", PortalWeb with pipe_through :browser, add: get "/courses" -> CourseController
:index; get "/courses/:id" -> CourseController :show; post "/enroll" -> EnrollmentController :create;
resources "/lessons", LessonController, only: [:show]; and live "/enroll/:id", EnrollmentLive. Replace any hand-built
path strings elsewhere with the ~p sigil so they are verified against the router.
Acceptance: mix phx.routes lists all five routes; the controller actions are named only in the router; a ~p path that
does not match a route produces a compile-time warning.
```

```text
PROMPT 2 — Pipelines and a protected scope
Declare three pipelines in the router. :browser with plug :fetch_session, :fetch_live_flash, :protect_from_forgery,
:put_secure_browser_headers. :api with plug :accepts, ["json"]. :require_auth with plug PortalWeb.RequireUser (built
next). Add scope "/dashboard", PortalWeb with pipe_through [:browser, :require_auth] and live "/", DashboardLive.
Acceptance: public routes pipe through :browser only; the dashboard scope pipes through :browser then :require_auth;
mix phx.routes shows the dashboard route under the stacked pipeline.
```

```text
PROMPT 3 — The RequireUser module plug
Create PortalWeb.RequireUser implementing the Plug contract: init(opts), do: opts and call(conn, _opts) that reads
get_session(conn, :user_id). When nil, put_flash an error, redirect to "/login", and halt(). Otherwise assign the
conn with :current_user_id. Import Plug.Conn and the needed Phoenix.Controller functions.
Acceptance: an unauthenticated request to a :require_auth route is halted and redirected, and no controller action or
LiveView mount runs; an authenticated request continues with conn.assigns.current_user_id set; the plug returns a conn
in both branches.
```

```text
PROMPT 4 — A function plug
Add a function plug put_request_time(conn, _opts) that assigns :req_at with DateTime.utc_now(), and plug it into the
:browser pipeline. Explain in a comment that a function plug is the same conn-in/conn-out contract as a module plug,
without a separate module.
Acceptance: every browser request has conn.assigns.req_at set; the function plug takes and returns a conn; it is added
to the pipeline with a plain plug :put_request_time line.
```

```text
PROMPT 5 — Verify the routing layer
Confirm the layer end to end: mix phx.routes lists the public, dashboard, and resource routes; GET /dashboard while
logged out redirects to /login (the plug halted); GET /dashboard while logged in renders with current_user_id
assigned; and a deliberately mistyped ~p path is reported at compile time. The controllers and the facade are
unchanged from F6.01.
Acceptance: the halt path and the assign path both behave as specified; verified paths catch the typo; no controller
gained domain logic; the F6.01 lifecycle still serves a rendered request.
```

```text
PROMPT 6 — An API pipeline that answers JSON, plus a rate-limit plug
Add an :api_auth pipeline (plug :accepts, ["json"]) with a module plug PortalWeb.Plugs.RequireToken that reads the
Authorization bearer token, verifies it, assigns :current_user on success, and on failure sends a 401 JSON body and
halt/1s — never a redirect. Add a function plug rate_limit/2 that halts with 429 when a per-token counter exceeds a
threshold. Mount an /api scope through :api_auth and rate_limit.
Acceptance: a request to /api with no or a bad token gets a 401 JSON response and the action never runs; a valid token
reaches the action with conn.assigns.current_user set; exceeding the limit returns 429; the browser pipeline and its
redirect-based auth are unaffected.
```

## Definition of done

- [ ] The router has read, write, `resources`, and `live` routes, and actions are named only there.
- [ ] URLs are built with verified `~p` paths; a mismatch is a compile warning.
- [ ] `:browser`, `:api`, and `:require_auth` pipelines exist; the dashboard scope stacks `[:browser, :require_auth]`.
- [ ] `RequireUser` implements `init/1` and `call/2`, assigns on success, and `halt/1`-s with a redirect on failure.
- [ ] A function plug demonstrates the same `conn`-in / `conn`-out contract.
- [ ] An unauthenticated request to a protected route never reaches an action; an authenticated one does.

## Next

F6.03 · Ecto: schemas, changesets & queries — put a database behind the engine's port as one more adapter, so the
core still names no repo.
