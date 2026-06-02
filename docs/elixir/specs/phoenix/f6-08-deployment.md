# F6.08 · Auth, deployment & going live

> The production module. Everything built so far — the F5 engine, the contexts, controllers, LiveView, PubSub and
> Presence — now runs as one supervised system in production. This guide ships the **build prompts** that generate
> authentication, protect routes and LiveViews, package the app as a release with runtime config, run migrations
> without `mix`, cluster the nodes for real-time, and deploy with build-migrate-boot. None of it replaces the
> foundations: auth is a context, a release packages the same supervision tree, and the deploy boots that tree. Run
> the prompts in order and verify against the definition of done.

Module guide · part of [F6 · Phoenix Framework](phoenix.md) · prev: [F6.07 · PubSub](f6-07-pubsub.md)

## What you'll build

The application, made deployable:

- **authentication** — `mix phx.gen.auth Accounts User users` generates an Accounts context, a `User` schema, a token
  schema, the login/registration LiveViews, and the session plumbing;
- **protected routes** — `fetch_current_user` in the `:browser` pipeline, `require_authenticated_user` on protected
  scopes, and `on_mount` enforcement for LiveViews;
- **runtime config** — `config/runtime.exs` reading `DATABASE_URL`, `SECRET_KEY_BASE`, and `PHX_HOST` from the
  environment at boot, distinct from compile-time `prod.exs`;
- **a release migrate command** — a `Portal.Release` module run via `bin/portal eval`, since a release has no `mix`;
- **clustering** — a libcluster topology so PubSub and Presence span every node;
- **the deploy** — build, migrate, boot, with the F5 supervision tree serving.

## Concepts

- **Auth is a context, not a subsystem.** `phx.gen.auth` writes the Accounts context (F6.04 shape), a `User` schema
  with a bcrypt-hashed password, and standard plugs. You own and adjust the generated code.
- **The session stores a token.** On login the app verifies the password with bcrypt and writes a token to a signed
  cookie — never the password, never the user struct. The token can be invalidated server-side.
- **A plug loads the user per request.** `fetch_current_user` runs in the `:browser` pipeline, reads the cookie, and
  assigns `current_user`. Protected routes add `require_authenticated_user` to a pipeline.
- **LiveView enforces with on_mount.** A LiveView holds a socket, not a request, so it uses an `on_mount` hook under a
  `live_session` that returns `{:cont, socket}` or `{:halt, redirect(...)}` before connecting.
- **Authentication vs authorization.** The router answers "is there a user?"; the context answers "may this user do
  this?" with the `current_user`.
- **A release bundles the BEAM.** `mix release` produces a self-contained artifact (code + deps + ERTS) that runs with
  no Elixir installed, with a `bin/portal` launcher.
- **Config timing is the key distinction.** `config.exs`/`prod.exs` are compile-time and baked in (fixed settings
  only); `runtime.exs` is evaluated at boot and reads the environment (secrets, URLs). `System.fetch_env!/1` raises on
  a missing variable, so a misconfigured deploy fails loudly.
- **No mix in a release.** Migrations run through a small `Portal.Release` module invoked with `bin/portal eval`.
- **Deploy is build, migrate, boot.** Migrate before boot so new code never meets an old schema. Booting starts the
  F5 supervision tree, which starts everything and restarts a crashed child.
- **Clustering is a connection concern.** libcluster joins nodes; once connected, the F6.07 broadcast code spans the
  cluster unchanged.

## Specs

**Auth pieces:**

| Piece | Role |
| --- | --- |
| the session | a signed cookie carrying a token |
| `fetch_current_user` | a plug; loads `current_user` into `conn.assigns` per request |
| `on_mount` | enforces auth in a LiveView before it connects |

**Config split:**

| File | When | Holds |
| --- | --- | --- |
| `config.exs` / `prod.exs` | compile time | fixed, committable settings |
| `runtime.exs` | boot time | `DATABASE_URL`, `SECRET_KEY_BASE`, `PHX_HOST` from env |

**Deploy sequence:**

| Step | Command |
| --- | --- |
| build | `MIX_ENV=prod mix release` |
| migrate | `bin/portal eval "Portal.Release.migrate()"` |
| boot | `bin/portal start` |

**Touched files:** the generated `Accounts` context + `User`/token schemas + auth modules, the router, `runtime.exs`,
`lib/portal/release.ex`, `Portal.Application` (Presence + libcluster children), and deploy config.

## Build it

1. **Generate auth.**

   ```text
   mix phx.gen.auth Accounts User users
   mix deps.get
   mix ecto.migrate
   ```

2. **Protect routes** in the router.

   ```elixir
   pipeline :browser do
     plug :fetch_session
     plug :fetch_current_user
   end

   scope "/", PortalWeb do
     pipe_through [:browser, :require_authenticated_user]
     live "/catalog", CatalogLive
   end
   ```

3. **Enforce in LiveView** with `on_mount`.

   ```elixir
   live_session :authenticated, on_mount: [{PortalWeb.UserAuth, :ensure_authenticated}] do
     live "/catalog", CatalogLive
   end
   ```

4. **Runtime config** reading the environment.

   ```elixir
   # config/runtime.exs
   import Config
   if config_env() == :prod do
     config :portal, Portal.Repo, url: System.fetch_env!("DATABASE_URL"), pool_size: 10
     config :portal, PortalWeb.Endpoint,
       url: [host: System.fetch_env!("PHX_HOST"), port: 443, scheme: "https"],
       secret_key_base: System.fetch_env!("SECRET_KEY_BASE")
   end
   ```

5. **A release migrate command.**

   ```elixir
   defmodule Portal.Release do
     @app :portal
     def migrate do
       Application.load(@app)
       for repo <- Application.fetch_env!(@app, :ecto_repos) do
         {:ok, _, _} = Ecto.Migrator.with_repo(repo, fn r -> Ecto.Migrator.run(r, :up, all: true) end)
       end
     end
   end
   ```

6. **Cluster + deploy.**

   ```elixir
   # config/runtime.exs
   config :libcluster, topologies: [portal: [strategy: Cluster.Strategy.Kubernetes, config: [service: "portal-headless", application_name: "portal"]]]
   ```
   ```text
   MIX_ENV=prod mix release
   bin/portal eval "Portal.Release.migrate()"
   bin/portal start
   ```

## Build prompts

> Paste into an agent in order. Each prompt carries its spec and acceptance criteria. The app stays runnable after
> each one.

```text
PROMPT 1 — Generate authentication
Run mix phx.gen.auth Accounts User users, then mix deps.get and mix ecto.migrate. Review the generated Accounts context,
the User schema with its bcrypt-hashed password, the token schema, and the session plumbing. Confirm the session stores
a token (not the password) in a signed cookie and that get_user_by_email_and_password/2 verifies with bcrypt.
Acceptance: registration and login work; the Accounts context follows the F6.04 shape; the password is stored only as a
bcrypt hash; the session cookie carries a token; the generated migration has run.
```

```text
PROMPT 2 — Protect routes
Ensure :fetch_current_user is in the :browser pipeline so current_user is assigned on every request. Add a
require_authenticated_user plug to a pipeline (or pipe_through list) and move the routes that need a login — including
live "/catalog" — into a scope that pipes through it. Leave public routes outside.
Acceptance: anonymous visitors are redirected away from protected routes; current_user is available in conn.assigns on
all browser routes; public routes remain reachable without a login; the pipeline composition matches F6.02.
```

```text
PROMPT 3 — Enforce auth in LiveView
Group protected LiveViews under a live_session with on_mount: [{PortalWeb.UserAuth, :ensure_authenticated}]. Implement
on_mount(:ensure_authenticated, _params, session, socket) to load the current user from the session and return
{:cont, socket} when present or {:halt, redirect(socket, to: ~p"/users/log_in")} when absent.
Acceptance: a protected LiveView redirects an anonymous visitor before it connects or loads data; an authenticated user
proceeds; the check runs at mount via on_mount, not only in a request-time plug.
```

```text
PROMPT 4 — Runtime configuration
Write config/runtime.exs (guarded by config_env() == :prod) to read DATABASE_URL, SECRET_KEY_BASE, and PHX_HOST with
System.fetch_env!/1 and configure Portal.Repo and PortalWeb.Endpoint from them. Keep fixed settings in prod.exs. Confirm
no secrets are present in compile-time config.
Acceptance: the release reads secrets and URLs from the environment at boot; a missing required variable raises and the
release refuses to start; no secret appears in config.exs or prod.exs; the same artifact runs in any environment.
```

```text
PROMPT 5 — Migrate without mix
Add lib/portal/release.ex with a Portal.Release module exposing migrate/0 that loads the app and runs Ecto.Migrator for
each repo in :ecto_repos. Document running it with bin/portal eval "Portal.Release.migrate()". Do not rely on mix
ecto.migrate in production.
Acceptance: Portal.Release.migrate/0 runs pending migrations against the configured repos; it works from a built release
with no mix; the command is bin/portal eval "Portal.Release.migrate()"; the migrations are the same ones from F6.03.
```

```text
PROMPT 6 — Cluster and deploy
Add a libcluster topology in runtime.exs so nodes connect (e.g. the Kubernetes strategy), and ensure PortalWeb.Presence
and the PubSub server are in the supervision tree. Document the deploy as three ordered steps: MIX_ENV=prod mix release,
bin/portal eval "Portal.Release.migrate()", bin/portal start. Confirm a broadcast on "courses" reaches subscribers on
every node once clustered.
Acceptance: nodes form a cluster on boot; a F6.07 broadcast reaches subscribers across nodes with no code change; the
deploy runs build then migrate then boot in that order; booting starts the supervision tree, which serves and restarts
crashed children.
```

## Definition of done

- [ ] `phx.gen.auth` is generated and reviewed; login/registration work; the session stores a bcrypt-backed token.
- [ ] `fetch_current_user` assigns the user per request; protected scopes require `require_authenticated_user`.
- [ ] Protected LiveViews enforce auth with `on_mount` before connecting.
- [ ] `runtime.exs` reads secrets and URLs from the environment at boot; none are baked into compile-time config.
- [ ] `Portal.Release.migrate/0` runs migrations from a release via `bin/portal eval`, without `mix`.
- [ ] Nodes cluster so PubSub and Presence span them; the deploy is build, migrate, boot, starting the F5 tree.

## Next

F6.09 · The live dashboard (lab) — assemble everything from F5 and F6 into a real-time dashboard over a socket,
broadcasting to many connected clients: the capstone of the chapter.
