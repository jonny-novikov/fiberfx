# F6 · Roadmap — the Portal on the web (Phoenix)

> A delivery plan for the web chapter: climb F6.1–F6.9 to turn the F5 engine into a deployed, multi-client learning
> platform, one shippable capability per rung, all of it over the unchanged `Portal` facade. This file is the
> delivery view; the per-rung feature abstracts and the value ladder live in the chapter index
> [`phoenix.md`](phoenix.md), and each rung's detail is in its triad (`f6.N.md` / `.stories.md` / `.llms.md`).

## What we are delivering

The Portal, served to people: a real web application that renders the catalog, lets learners enroll and progress,
turns the pages interactive, pushes changes live across clients, puts it behind authentication, deploys it as a
clustered release, and finishes with an operations dashboard. Every rung is a vertical slice that ships a capability a
real role can use and leaves the platform running, and every rung calls only the `Portal` facade — so the F5 engine,
its event log, and its supervision tree never change underneath.

The near-term goal is the first deployable web product: a persistent, server-rendered catalog you can browse and add
to (F6.1–F6.5), then made interactive and live (F6.6–F6.7). Authentication, deployment, and the dashboard
(F6.8–F6.9) follow once the live catalog earns feedback.

## Where this starts and ends

- **Start (the F5 handoff).** A supervised application — the `Portal.EventStore` adapter and `{Portal.Engine, []}` —
  behind a single facade `Portal` (commands `enroll/2`, `deliver_lesson/2`; queries `progress_of/1`, `courses_of/1`)
  returning `:ok | {:ok, data} | {:error, %Portal.Error{}}`, with `%Portal.Error{}` a closed set
  (`:already_enrolled | :course_not_found | :lesson_locked | :invalid_progress`). See
  [`../pragmatic/f5.9.md`](../pragmatic/f5.9.md).
- **End (after F6.9).** The same engine, unchanged, deployed as a live, multi-client platform: server-rendered pages,
  interactive LiveViews, real-time updates across clients, authenticated users, and an operations dashboard — all
  calling only the facade.

## Architecture decision — standard Phoenix on the BEAM

The stack is standard Phoenix, Ecto, and LiveView on the BEAM — the conventional, well-supported path — with no
separate frontend application. The reasoning matches the in-BEAM choice the bot makes
([`../bot/f10.roadmap.md`](../bot/f10.roadmap.md)): the UI is a driving adapter over an engine already running in the
same VM, so server-rendered LiveView gives interactivity and real-time without a second language, a parallel API
contract, or a separate deploy target. PubSub and Presence ride the same runtime, so multi-client freshness and a
cluster-correct viewer count are a few lines rather than a messaging subsystem.

The cost — that interactivity runs over a stateful socket — is a fit for the BEAM, not a strain on it, and the trade
stays reversible: a non-LiveView client can attach over a channel (F6.7), and a separate frontend could consume the
same facade later if a product reason appears. None of that is needed for the platform this roadmap delivers.

## The master invariant

> The web layer calls only the `Portal` facade and renders only the closed `%Portal.Error{}` set. No controller,
> LiveView, plug, or template names `Portal.Engine`, a repo, or `GenServer.call`.

This single rule is what makes the ladder cheap: every rung adds web surface without reaching below the facade, so
nothing under F5.8 ever changes. The only structural change to the F5 supervision tree across all of F6 is adding
`PortalWeb.Endpoint` (F6.1); later rungs add `Phoenix.PubSub` and `Phoenix.Presence` only as the real-time features
require them (F6.7).

## How this roadmap runs

Two roles, the same loop the F5 roadmap uses (see [`../pragmatic/pragmatic.roadmap.md`](../pragmatic/pragmatic.roadmap.md)):

- **Author (Claude)** turns each rung into a spec triad and a build plan at the F5 quality bar — Goal, Rationale (5W),
  Scope, Deliverables, Invariants, Definition of Done; user stories; an agent brief with a paste-ready prompt.
- **Operator (the person in this conversation)** reviews the delivered specs and the shipped increment, then returns
  feedback asking for the next rung's specs or a change to a shipped one.

The loop per rung is **sharpen → build → ship → demo → review → feedback → adapt**. Feedback edits the spec, because
the spec is the single source of truth; the build follows the spec.

## "Thin but robust" for the web

Each rung is a narrow vertical slice built to production quality, not a prototype. Concretely:

- **Over the facade.** Every controller, LiveView, and template calls only `Portal` and renders only the closed
  `%Portal.Error{}` set; the web invents no domain logic and no new error vocabulary.
- **Harnessed.** Controllers are tested with `Phoenix.ConnTest`, LiveViews with `Phoenix.LiveViewTest`
  (`render_change`, `render_submit`), and enrollment runs against the in-memory `EventStore` adapter — so the suite is
  fast and needs no live browser. The F6.3 changeset stays the parse boundary; the view adds no validation.
- **Verified and safe.** Links are `~p` verified routes (a path typo fails to compile), interpolation is
  HEEx-escaped, and component `attr`s are declared.
- **Rendered in the system.** Every page is emitted through the F0 root layout and the shared head — the tokens and
  base CSS declared once (F0-INV2), never re-declared per page — and the rendered look is gated against the static
  baseline by computed style, not pixels (F6.5.5).
- **Honest real-time.** Broadcasts fire only after a successful write, so clients only ever learn of facts.
- **Supervised.** New runtime pieces (the endpoint, PubSub, Presence) are supervised children; the engine's crash
  isolation is untouched.
- **Always live.** Every rung leaves the dev node booting clean and serving on `:4000` — `GET /health` answers `200`
  and the rung's route renders, checked after the gate is green (the liveness criterion). The Portal is kept *hot*
  across rungs by a long-lived `iex -S mix` + `recompile()` (this umbrella has no `phoenix_live_reload`; "hot" means
  BEAM code-load, not browser reload). Runbook: [`phoenix.operator.md`](phoenix.operator.md).

Every rung ships behind the same Definition-of-Done gates the Portal specs use, and the table below names the demo and
the harness for each.

## The delivery arc

Three milestones, climbing the ladder. The first is the first deployable product; the rest layer interactivity,
real-time, and operations on top.

| Milestone | Rungs | What you can do at the end |
| --- | --- | --- |
| 1 · Ship the catalog | F6.1–F6.5.5 | browse a persistent catalog and add courses, server-rendered **in the jonnify design system**, with inline errors |
| 2 · Make it live | F6.6–F6.7 | search and create without reloads; every client updates live with a viewer count |
| 3 · Ship to users | F6.8–F6.9 | sign in, run behind auth on a deployed clustered release, watch an operations dashboard |

Per-rung iterations (each a PR-sized increment — a spec triad, the slice, a green harness, a demo, a feedback note):

| Rung | Ships (the slice) | Demo | Harness | Feedback asked |
| --- | --- | --- | --- | --- |
| F6.1 | the engine served as a web app (endpoint, request → facade → render) | hit the root, see a page | `ConnTest` GET smoke | shell and layout right? |
| F6.2 | the route surface (read/write/REST/live routes, pipelines, plugs) | navigate routes; a protected pipeline | route + pipeline tests | route shape and scopes right? |
| F6.3 | durable catalog and enrollments (Postgres adapter behind the F5 port) | data survives a restart | schema/changeset tests; sandbox; restart-replay | schema fields and constraints? |
| F6.4 | the domain over the facade (`Catalog`/`Enrollment`/`Accounts`) | the web reads and writes real domain | context API tests; adapter-agnostic enrollment | context boundaries and naming? |
| F6.5 | the rendered catalog (index, `course_card`, form, inline errors) | browse the catalog; create with inline errors | HTML render tests; valid/invalid create | layout, UX, error wording? |
| F6.5.5 | the design system applied (root layout, `app.css` tokens, restyled `CatalogComponents`) | the catalog renders in the dark-editorial look | render-parity (computed-style/geometry e2e) vs the static baseline | does the rendered look match `/elixir`? |
| F6.6 | interactivity (live search, live create, streams) | search as you type; create without a reload | `LiveViewTest` (`render_change`/`render_submit`) | does the interaction feel right? |
| F6.7 | multi-client live updates and a viewer count (PubSub, Presence) | two windows; one creates, the other updates; a viewer count | broadcast tests; presence diff; two-LiveView test | what should propagate; count semantics? |
| F6.8 | real users and a deployed clustered release | sign in; a protected area; a deployed URL | auth flow tests; release boot; cluster smoke | auth model and deploy target? |
| F6.9 | an operations/learning dashboard folding live events, under auth, clustered | the dashboard updates live | dashboard render + live-event test | which metrics and views? |

**Status — F6.5 + F6.6 shipped; the design-system rung inserted.** The engine (F5) and **F6.1–F6.6** are **shipped** — F6.5 (HEEx views) and F6.6 (LiveView, `3cf2480`) have landed past the original draft. **F6.5.5 · Apply the design system** is the new styling rung — F0's Portal-rendering (its milestones 4–5) scheduled as a deliverable — specced here with its triad and ship-prompt; the build is pending (*prompt before run*). F6.7–F6.9 remain **specced backlog, groomed**: each opens with a `[RECONCILE]` callout at the top of its body folding the shipped direction forward (routes + components, and now the F6.5.5 styling fold), and each takes a pre-build lag-1 `/reconcile` (Venus step 1) before it is built — retiring up front the ambiguity that accrues when a story is written rungs ahead of its build.

| Rung | Status |
| --- | --- |
| F6.1 endpoint · F6.2 routing · F6.3 Ecto · F6.4 contexts · F6.5 HEEx views · F6.6 LiveView | **shipped** |
| F6.5.5 Apply the design system | **specced** — triad + ship-prompt authored; build pending (*prompt before run*) |
| F6.7 PubSub · F6.8 auth & deploy · F6.9 dashboard | **specced backlog, groomed** — each opens with a `[RECONCILE]` callout (now incl. the F6.5.5 styling fold) |

## Seams & open decisions

- **Routing & component direction (set at F6.5, `5a440fd`).** The catalog is `resources "/courses"` (`CourseController`: index/show/new/create); a learner's enrollments are `get "/my/courses"` (`EnrollmentController.index`, protected); `/courses/:user_id` and `/learn` are retired; one controller per context; a successful enroll redirects to the joined course's `:show`. Form-field components are a minimal LOCAL set in `PortalWeb.CatalogComponents` (`input/1`, `course_card`, `panel`) imported via `portal_web.ex` `html_helpers` — there is NO `CoreComponents` until F6.8's `phx.gen.auth` forces the decision. Each downstream rung (F6.6–F6.9) carries a `[RECONCILE]` callout folding this forward. **F6.5.5 · Apply the design system lands the F0 root layout + a committed `app.css` over this same LOCAL set, proving a styled UI is reachable without `CoreComponents` — so the `CoreComponents` reckoning stays deferred to F6.8, where it becomes also a theming decision (the generated auth UI must render in the F0 tokens).**

- **Authentication (F6.8).** The likely path is `mix phx.gen.auth` for password accounts, with the `Accounts` context
  from F6.4 as the seam; the choice of social/SSO and session model is decided then.
- **Deployment & clustering (F6.8).** An Elixir release plus a clustering strategy (for example `libcluster`) makes
  Presence and PubSub correct across nodes; the deploy target (a managed platform or containers) is decided then.
- **Dashboard data (F6.9).** The dashboard folds live events (the same broadcasts F6.7 emits) and read-model queries;
  which metrics it shows and whether it embeds `LiveDashboard` is decided then.
- **Catalog browsing read.** Browsing the available catalog uses `Catalog.list_courses/0` (F6.4), distinct from the
  learner-scoped `courses_of/1` on the F5 facade; F6.5/F6.6 read the former.
- **The Postgres `EventStore` adapter.** Its body, schema, and migration land in F6.3 behind the F5.8 port, so
  enrollment is durable in production while tests stay on the in-memory adapter.

## Conventions

- The master invariant holds at every rung: the web calls only `Portal` and renders only the closed `%Portal.Error{}`
  set; it names no engine, repo, or `GenServer.call`.
- Branded Snowflake ids for any new identifier (integer column; branded transport form with a namespace prefix and
  base62 encoding).
- Phoenix idioms: verified `~p` routes, HEEx-escaped interpolation, declared component `attr`s, `LiveViewTest` and
  `ConnTest` for the harness, and the F6.3 changeset as the parse boundary.
- A+ quality gates and Writerside-friendly markdown throughout: prose over heavy formatting, clean voice, balanced
  fences, resolving links.

---

Chapter index & feature abstracts: [`phoenix.md`](phoenix.md). Rungs: [`f6.1.md`](f6.1.md) · [`f6.2.md`](f6.2.md) ·
[`f6.3.md`](f6.3.md) · [`f6.4.md`](f6.4.md) · [`f6.5.md`](f6.5.md) · [`f6.5.5.md`](f6.5.5.md) · [`f6.6.md`](f6.6.md) · [`f6.7.md`](f6.7.md) ·
[`f6.8.md`](f6.8.md) · [`f6.9.md`](f6.9.md).
Sibling roadmaps: [`../pragmatic/pragmatic.roadmap.md`](../pragmatic/pragmatic.roadmap.md) ·
[`../bot/f10.roadmap.md`](../bot/f10.roadmap.md). Engine handoff: [`../pragmatic/f5.9.md`](../pragmatic/f5.9.md).
Operator's guide: [`phoenix.operator.md`](phoenix.operator.md). Approach: [`../specs.approach.md`](../specs.approach.md).
