# F6 · Phoenix — the Portal as a value ladder

> The web chapter, re-told as a sequence of value-adding feature specs. F5 left a supervised Portal engine behind one
> public facade; F6 climbs a ladder of increments — bootstrap, routing, persistence, contexts, views, LiveView,
> real-time, auth & deploy, and the live-dashboard capstone — each of which ships a capability a real role can use and
> leaves the platform running. Every spec is built story-first and proven by invariants, following
> [the specs approach](../specs.approach.md).

This index is the map. Each rung links to its three artifacts: the spec (`f6.N.md`), the user stories
(`f6.N.stories.md`), and the agent brief (`f6.N.llms.md`).

## Where F6 starts and ends

**Start (the F5 handoff).** A supervised application — `Portal.EventStore` adapter, `{Portal.Engine, []}` — behind a
single facade `Portal` (commands `enroll/2`, `deliver_lesson/2`; queries `progress_of/1`, `courses_of/1`) that returns
`:ok | {:ok, data} | {:error, %Portal.Error{}}`. `%Portal.Error{}` is a closed set:
`:already_enrolled | :course_not_found | :lesson_locked | :invalid_progress`.

**End (after F6.9).** The same engine, unchanged, deployed as a live, multi-client learning platform: server-rendered
pages, interactive LiveViews, real-time updates across clients, authenticated users, and an operations dashboard —
all of it calling only the facade.

## The master invariant

> The web layer calls only the `Portal` facade and renders only the closed `%Portal.Error{}` set. No controller,
> LiveView, plug, or template names `Portal.Engine`, a repo, or `GenServer.call`.

This single rule is what makes the whole ladder safe: every rung adds web surface without reaching below the facade,
so nothing under F5.08 ever changes. The only structural change to the F5 supervision tree across all of F6 is the
addition of `PortalWeb.Endpoint` (F6.1); later rungs add `Phoenix.PubSub` and `Phoenix.Presence` as the real-time
features require them.

## The liveness criterion — keep the Portal live (every rung)

> Every rung leaves the Portal **running and serving** in dev: the umbrella boots clean, the endpoint binds `:4000`,
> `GET /health` answers `200`, and the rung's own route renders. A rung is not done until the platform it changed is
> still live.

This is the second standing gate, beside the master invariant, and it holds at the same scope — every rung, no
exceptions. The ladder's whole promise is that each increment "ships a capability a real role can use and leaves the
platform running"; the liveness criterion makes that promise *checkable* rather than assumed. After a rung's build
gate is green (compile `--warnings-as-errors`, tests, the determinism loop), the rung is accepted only if:

- the dev node boots — `iex -S mix` (or `mix phx.server`) binds `http://localhost:4000` with `server: true`
  (`config/runtime.exs`, every env but `:test`); `Portal.Repo` is a supervision child, so `portal_dev` must exist
  first (`mix ecto.create`);
- the liveness probe is `200` — `curl -fsS localhost:4000/health` (the `PortalWeb.CourseController` `:health` action,
  no session or CSRF — the operator probe);
- the rung's surface renders — e.g. after F6.6, `curl -fsS localhost:4000/courses` returns the live catalog.

**"Hot" in this umbrella is BEAM hot-code-load, not Phoenix live-reload.** This app is hand-built without
`mix phx.gen.*`, so it carries no `phoenix_live_reload` dependency and no `CodeReloader`/`LiveReloader` plug. The dev
loop that keeps the Portal hot is a long-lived `iex -S mix` session: after each edit, `recompile()` in that shell
loads the changed modules into the running node — the warm node keeps its bound socket and its in-memory
engine/event-store state across rungs, so a demo built up interactively survives the next rung's code change. The full
runbook — preconditions, the boot, the per-rung check, the determinism loop — is in
[`phoenix.operator.md`](phoenix.operator.md).

## The value ladder

| Spec | Feature | Value it adds | Primary roles | Status |
| --- | --- | --- | --- | --- |
| [F0](../design/f0.md) | The design system (foundation) | the dark-editorial tokens, page anatomy, and build/parity gates every page renders in — the look the Portal inherits | Author, Reader, Developer | **foundation** — static system built; Portal-rendering → F6.5.5 |
| [F6.1](f6.1.md) | Bootstrap the Phoenix Portal | the engine is served as a real web app; a request reaches the facade and renders | Operator, Visitor, Developer | **shipped** |
| [F6.2](f6.2.md) | Routing & the access surface | a navigable, protectable surface: read/write/REST/live routes, pipelines, plugs | Visitor, Learner, Developer, Operator | **shipped** |
| [F6.3](f6.3.md) | Persistence with Ecto | durable catalog & enrollments via a Postgres adapter behind the F5 port | Operator, Developer, Learner | **shipped** |
| [F6.4](f6.4.md) | Contexts & domain on the web | the web reads and writes real domain through the facade and bounded contexts | Developer, Learner | **shipped** |
| [F6.5](f6.5.md) | Views with HEEx | a rendered UI: templates, function components, forms with inline errors | Visitor, Learner | **shipped** |
| [F6.5.5](f6.5.5.md) | Apply the design system | the catalog renders in the F0 dark-editorial system — root layout, tokens, page anatomy — over the facade, no CoreComponents | Visitor, Learner | **specced** |
| [F6.6](f6.6.md) | LiveView | interactive pages — live search and live create — without full reloads | Learner | **shipped** |
| [F6.7](f6.7.md) | Real-time (PubSub & Presence) | multi-client live updates and a live viewer count | Learner, Instructor | **specced** |
| [F6.8.1](f6.8.1.md) | Authentication — the honest door | real sign-in: the static login page ported over a `Portal.Auth` facade; protected areas; `current_user` + `on_mount` | Learner, Operator | **specced** |
| [F6.8.2](f6.8.2.md) | Deployment | a scoped umbrella release, the config split, `Portal.Release` migrate, libcluster, a distilled `fly.toml` (the live deploy is the Operator's) | Operator, Developer | **specced** |
| [F6.9](f6.9.md) | The live dashboard (capstone) | an operations/learning dashboard folding live events, under auth, clustered | Instructor, Operator | **specced** |

The rungs depend only downward: F6.2 assumes F6.1's endpoint and pipeline; F6.5 renders what F6.3/F6.4 make
queryable; F6.5.5 renders F6.5's pages in the F0 design system, and every later rung inherits that look; F6.6
makes F6.5's pages live; F6.7 pushes F6.6's state across clients; F6.9 composes all of it.

The delivery plan — the milestones, the build order, and the per-rung shipping iterations — is in
[`phoenix.roadmap.md`](phoenix.roadmap.md).

## How to read a rung

Read the spec (`f6.N.md`) first — Goal, Rationale (5W), Scope, Deliverables, Invariants, Definition of Done. Then the
user stories (`f6.N.stories.md`) for the acceptance criteria. Then the agent brief (`f6.N.llms.md`) when you are ready
to implement: its references, requirements, execution topology, and the comprehensive prompt that an agent runs to
build and self-check the increment.

This index pairs with the design-system foundation [`F0 · The Design System`](../design/f0.md): F0 specifies the
tokens, page anatomy, build pipeline, and quality gates every page renders in. F0's own delivery books the Portal's
HEEx rendering as milestone 4 and a static-vs-Portal parity gate as milestone 5 — both **planned**; the
[**F6.5.5 · Apply the design system**](f6.5.5.md) rung is where they land, turning F0 from a cited backdrop into a
scheduled web deliverable. The rungs above then render in it.

## Conventions

- **Stack.** Elixir (OTP) · Phoenix (endpoint, router, controllers, LiveView) · Ecto as one adapter behind the
  engine's port (F6.3) · the F4 branded CHAMP store · `Jason` for JSON. Side effects stay at the edges.
- **Identifiers.** Every entity is identified by a Snowflake — a 64-bit, time-ordered integer — whose transport form
  is a branded id: a three-letter namespace prefix plus the Base62-encoded snowflake (e.g. `ENR0KHTOWnGLuC`).
  `Portal.ID.new/1` mints and `Portal.ID.snowflake/1` decodes, exactly as in F5.
- **Proof.** Each spec's Invariants and acceptance criteria are the gates; a rung is done only under the completion
  rule in [the specs approach](../specs.approach.md).
- **Always live.** Every rung leaves the Portal serving in dev — `:4000` bound, `GET /health` → `200`, the rung's
  route renders — checked after the build gate is green (the liveness criterion above). The Operator's runbook for
  keeping it live and hot is [`phoenix.operator.md`](phoenix.operator.md).

---

> Part of the jonnify toolkit. Branded id format: `TSK` + Base62(snowflake), e.g. `TSK0KHTOWnGLuC`.
