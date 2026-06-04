# F6 · per-rung detail (the citable-string source)

- **Role:** the **verbatim** story + Given/When/Then for each of `f6.1`–`f6.9`, transcribed exactly from
  `docs/elixir/specs/phoenix/f6.N.stories.md`. This is the citable source the A2.07 dives quote from. **Quote
  EXACTLY** — do not paraphrase a story or a Given/When/Then. Where a dive prints a story or a scenario, it must
  match the block below character-for-character (these blocks are themselves copied from the source).
- For the one-line "delivers" and the dates/milestone, see [`index.md`](index.md).

Each rung lists: the representative Connextra story (the `As a … I want … so that …` line), **one** verbatim
Given/When/Then acceptance scenario, the story count, and the `/elixir` cross-link.

---

## F6.1 · Bootstrap the Phoenix Portal

- **Stories:** 5 (`F6.1-US1`…`US5`). · **Delivers:** the engine served as a Phoenix app; a request reaches the
  facade and renders; a `GET /health` liveness route. · **Milestone:** M1. · **`/elixir`:** `/elixir/phoenix/lifecycle`.

Representative story — `F6.1-US1` (Serve the Portal as a Phoenix app):

> As an **operator**, I want the Portal to boot as a Phoenix application, so that I can run and serve it with the
> standard Elixir/Phoenix toolchain.

Verbatim Given/When/Then (`F6.1-US1`):

> Given the running app, when I request `GET /health`, then I receive `200` with body `ok`.

Also citable (`F6.1-US2`, the first real page): "As a **visitor**, I want to open a course page for a given user,
so that I can see the courses that user is enrolled in." — GWT: "Given a known user id with enrollments, when I
request `GET /courses/:user_id`, then the page renders that user's courses."

---

## F6.2 · Routing & the access surface

- **Stories:** 6 (`F6.2-US1`…`US6`). · **Delivers:** read/write/REST/live routes; the `:browser`/`:api`/`:require_auth`
  pipelines; a protected scope; a reusable `RequireUser` plug; verified `~p` paths. · **Milestone:** M1. ·
  **`/elixir`:** `/elixir/phoenix/routing`.

Representative story — `F6.2-US2` (Protect pages behind authentication):

> As a **learner**, I want protected pages to require me to be signed in, so that my learning area is not open to
> anyone.

Verbatim Given/When/Then (`F6.2-US2`):

> Given no `:user_id` in the session, when I request a protected route, then I am redirected to the public landing
> with a flash, and the protected action does not run.

Also citable (`F6.2-US4`, compile-time-safe links): "As a **developer**, I want every internal URL verified at
compile time, so that a renamed or mistyped route is a build error, not a broken link in production." — GWT:
"Given a deliberately wrong `~p` path, when I compile, then the build fails; when I fix it, the build passes."

---

## F6.3 · Persistence with Ecto

- **Stories:** 6 (`F6.3-US1`…`US6`). · **Delivers:** Ecto as one adapter behind the F5 `Portal.EventStore` port;
  Snowflake `:bigint` ids; a parse-at-the-boundary changeset; the closed-error bridge. · **Milestone:** M1. ·
  **`/elixir`:** `/elixir/phoenix/ecto`.

Representative story — `F6.3-US1` (Data survives restarts and deploys):

> As an **operator**, I want catalog and event data stored in PostgreSQL, so that nothing is lost when a node restarts or
> a new release is deployed.

Verbatim Given/When/Then (`F6.3-US1`):

> Given a running app with the Postgres adapter, when a course is inserted and the node restarts, then the course is
> still retrievable.

Also citable (`F6.3-US6`, the master invariant under persistence): "As a **developer**, I want no `Repo`, schema,
or query in the web layer, so that the facade boundary that makes F6 safe is preserved as persistence is
introduced." — GWT: "Given the web layer, when I search `lib/portal_web/`, then no module references `Repo`,
`Ecto.Schema`, or `Ecto.Query`."

---

## F6.4 · Contexts & domain on the web

- **Stories:** 6 (`F6.4-US1`…`US6`). · **Delivers:** `Catalog`, `Enrollment`, `Accounts` contexts; the `Portal`
  facade `defdelegate`-ing to all three; a one-way dependency graph. · **Milestone:** M1. · **`/elixir`:**
  `/elixir/phoenix/contexts`.

Representative story — `F6.4-US4` (Contexts compose cleanly):

> As a **developer**, I want contexts to call each other only through public functions, so that boundaries hold and the
> dependency graph stays acyclic.

Verbatim Given/When/Then (`F6.4-US4`):

> Given `Enrollment.enroll/2`, when it needs a course, then it calls `Catalog.fetch_course/1` and branches on the
> public struct.

Also citable (`F6.4-US1`, one import for the web): "As a **developer**, I want a single `Portal` facade to call,
so that controllers depend on one surface and never reach into a context or `Repo`." — GWT: "Given `Portal`, when
inspected, then each public function is a `defdelegate` to a context and it owns no logic."

---

## F6.5 · Views with HEEx

- **Stories:** 7 (`F6.5-US0`…`US6`). · **Delivers:** an index over `@courses`; a `course_card` component; a
  slot-based `panel`; a local `input/1`; a changeset-backed create form that re-renders errors inline. ·
  **Milestone:** M1. · **`/elixir`:** `/elixir/phoenix/heex`.

Representative story — `F6.5-US5` (See my mistakes inline):

> As a **learner**, I want validation errors shown on the form, so that I can fix a bad submission without losing
> context.

Verbatim Given/When/Then (`F6.5-US5`):

> Given invalid params, when submitted, then the action re-renders `new.html.heex` with `to_form(changeset)`.

Also citable (`F6.5-US0`, the route reconcile — the spec→build→reconcile moment A2.07.3 features): "As an
**architect**, I want each URL named after the resource it returns, so that the catalog and a learner's enrollments
stop colliding on `/courses`." — GWT: "Given a successful enroll, when it redirects, then the target is
`~p\"/courses/#{course_id}\"` (the catalog show of the joined course), not a `user_id`."

---

## F6.6 · LiveView  ← the rung A2.07.2 (split-and-test) features

- **Stories:** 6 (`F6.6-US0`…`US5`). · **Delivers:** `CatalogLive` streams from the facade; a two-stage mount; a
  live search box via `Portal.search_courses/1`; a live create form. · **Milestone:** M2. · **`/elixir`:**
  `/elixir/phoenix/liveview`.

Representative story — `F6.6-US1` (Search as I type):

> As a **learner**, I want the course list to filter as I type, so that I find a course without submitting or reloading.

Verbatim Given/When/Then (`F6.6-US1`) — this is the proof A2.07.2 shows:

> Given the search box, when I type, then `phx-change="search"` fires `handle_event("search", params, socket)`.

The full `F6.6-US1` acceptance set (all three lines, verbatim — A2.07.2 may print the whole scenario):

> - Given the search box, when I type, then `phx-change="search"` fires `handle_event("search", params, socket)`.
> - Given the event, when it runs, then it filters through the `Portal.search_courses/1` facade function (not the
>   `Catalog` context directly, per [`f6.6.md`](f6.6.md) `## [RECONCILE]`, facade-only) and re-streams `:courses` with
>   `reset: true` (the list is `@streams.courses`, never an assign — INV4 — so the narrowing query drops non-matches).
> - Given each keystroke, when handled, then the rendered list narrows without a reload, and the view names only `Portal`.

The **four artifacts** of F6.6 (what A2.07.2 walks):
1. roadmap line — `phoenix.roadmap.md`: "F6.6 | interactivity (live search, live create, streams) | search as you
   type; create without a reload | `LiveViewTest` (`render_change`/`render_submit`) | does the interaction feel right?"
2. spec — `f6.6.md` (Goal: "After F6.6, the catalog is interactive without a page reload. `CatalogLive`
   (`use PortalWeb, :live_view`) streams the…").
3. stories — `f6.6.stories.md` (`US0`…`US5`, the block above).
4. agent brief — `f6.6.llms.md`.

Also citable (`F6.6-US2`, Create without a reload): "As a **learner** (an author), I want to add a course inline,
so that I see it appear without leaving the page." — GWT: "Given the form, when I submit, then `phx-submit=\"create\"`
calls `Portal.create_course/1`."

---

## F6.7 · Real-time (PubSub & Presence)

- **Stories:** 7 (`F6.7-US0`…`US6`). · **Delivers:** a facade `subscribe`/`broadcast` wrapper; context broadcasts
  only after a successful write; `stream_insert/3` in `handle_info/2`; a cluster-correct `Presence` viewer count. ·
  **Milestone:** M2 (specified). · **`/elixir`:** `/elixir/phoenix/pubsub`.

Representative story — `F6.7-US1` (See others' changes live):

> As a **learner**, I want the catalog to update when someone else changes it, so that what I see stays fresh without
> reloading.

Verbatim Given/When/Then (`F6.7-US1`):

> Given two connected sessions, when one creates a course, then the other shows it without a reload.

Also citable (`F6.7-US2`, Broadcasts are honest — the "clients only ever learn of facts" rule): "As a
**developer**, I want broadcasts to fire only after a successful write, so that clients never see a change that did
not happen." — GWT: "Given a write, when it returns `{:error, _}`, then nothing is broadcast."

---

## F6.8 · Auth & deployment

- **Stories:** 8 (`F6.8-US0`…`US7`). · **Delivers:** `phx.gen.auth`; `on_mount` guards; `runtime.exs` secrets; a
  `Portal.Release` migration task; a libcluster topology. · **Milestone:** M3 (specified). · **`/elixir`:**
  `/elixir/phoenix/deployment`.

Representative story — `F6.8-US1` (Register and sign in):

> As a **learner**, I want to create an account and sign in, so that I have a real identity on the platform.

Verbatim Given/When/Then (`F6.8-US2`, Protected areas turn anonymous visitors away):

> Given an anonymous request to a protected controller route, when it arrives, then `require_authenticated_user`
> redirects it to the login path with a `302` — it is never served a `200`.

Also citable (`F6.8-US3`, Deploy from the environment): "As an **operator**, I want secrets and host read from the
environment at boot, so that I deploy without compiling them in." — GWT: "Given a boot, when `config/runtime.exs`
runs, then it reads `DATABASE_URL`, `SECRET_KEY_BASE`, and `PHX_HOST` from the environment."

---

## F6.9 · The live dashboard (capstone)

- **Stories:** 8 (`F6.9-US1`…`US8`). · **Delivers:** `DashboardLive` seeds counts, folds domain broadcasts into a
  read model, prepends a capped feed, shows a `Presence` count; read-only, under auth, cluster-correct. ·
  **Milestone:** M3 (specified). · **`/elixir`:** `/elixir/phoenix/live-dashboard`.

Representative story — `F6.9-US1` (Live metrics seeded then folded):

> As an **operator**, I want course and enrollment counts that seed once and then update live, so that I read platform
> activity as it happens without ever re-querying.

Verbatim Given/When/Then (`F6.9-US1`):

> Given a `{:course_created, _}` broadcast, when `handle_info/2` folds it, then `courses_count` increases by exactly 1
> via `update(socket, :courses_count, &(&1 + 1))`.

Also citable (`F6.9-US4`, Read-only by construction — the capstone composes, never writes): "As an **operator**, I
want the dashboard to be strictly read-only, so that watching it can never change platform state." — GWT: "Given
the LiveView, when any callback runs, then it issues no command and no write — it only seeds and folds broadcasts."

---

## Transcription note

These blocks are copied from `docs/elixir/specs/phoenix/f6.N.stories.md` (read 05 Jun). If a dive needs a story or
scenario not listed here, read the source `.stories.md` directly and quote it verbatim — never reconstruct one from
memory. `f6.7.stories.md` has two stray `</content>`/`</invoke>` lines at its tail (lines 113–114) that are file
noise, not content; ignore them.
