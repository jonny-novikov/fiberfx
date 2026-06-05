# F6 · Grooming — the Phoenix backlog, refined

> The backlog-grooming view for the F6 (Phoenix web) value ladder: the recommended build order for the
> remaining rungs (**F6.7 → a dedicated dynamic-UI styling pass → F6.8 → F6.9**), each rung's upcoming
> deliverables, and — the load-bearing part — the `[RECONCILE]` rationales that turn each rung from *discover*
> into *decide*. The per-rung specs (`f6.N.{md,stories.md,llms.md}`) are the **source of truth**; this file is
> the planning view that sequences them and surfaces the decisions each one forces. Companion to the delivery
> view [`phoenix.roadmap.md`](phoenix.roadmap.md) and the L0 field manual [`phoenix.operator.md`](phoenix.operator.md).

## Status — where the ladder stands

F6.1–F6.6 shipped. **F6.5.5** (the design system — two STATIC parity pages, `/` ↔ `html/courses.html` and
`/elixir` ↔ `elixir/index.html`, + the configurable deep-link base URL) shipped + Operator-accepted, verified
live at `:4000`. The **AAW-parity** follow-on (`/course/agile-agent-workflow`, the third parity page) shipped.
The Portal now serves **three strangler-fig parity pages** (`/`, `/elixir`, `/course/agile-agent-workflow`)
over the `Portal` facade, plus — from **F6.7 · Real-time (SHIPPED, `ae7f986` + `2d1ab1c`)** — a `live "/courses"`
catalog that updates across every connected client over the same facade: PubSub broadcasts on `{:ok, _}` writes
(incl. the ratified new `update_course/2`), `stream_insert` gated on the active `@query`, and a **single-node**
`Presence` viewer count. **Forward-folds for F6.8/F6.9:** Presence is single-node — **F6.8's libcluster** makes it
cluster-correct (F6.7-INV4 is realized single-node, pending the cluster); the `{:course_created/updated, _}`
broadcast helper is the pattern **F6.9 inherits** for `{:enrolled, _}`; `:portal` now declares a `phoenix_pubsub`
dep-edge (framework-free infra, `mix.lock` unchanged). **F6.8–F6.9 are the open backlog.**

## Recommended build order

| # | Rung | Why here |
|---|---|---|
| 1 | **F6.7 · Real-time** ✅ | **SHIPPED** (`ae7f986` + `2d1ab1c`) — structural reconciles were RESOLVED, two new tree children, no styling dependency. |
| 2 | **A dedicated dynamic-UI styling pass** (recommended; not yet specced) | The F6.5.5 precedent — land the root layout + shared token stylesheet + the `CatalogComponents`/`CoreComponents` decision *separately* from the auth/deploy load. |
| 3 | **F6.8 · Auth & deployment** | The convergence point; heaviest rung. Lighter if the styling pass lands first. |
| 4 | **F6.9 · The live dashboard** | The capstone — composes everything below; introduces no new domain. |

**Why F6.7 first.** Its two *structural* `[RECONCILE]`s are already RESOLVED — F6.6 shipped `live "/courses"`
(no route to add) and pre-built the `connected?/1` seam this rung extends. It adds only two supervision children
(`Phoenix.PubSub`, `PortalWeb.Presence`), and it depends on **no styling work** (it renders the broadcast row
through the same `course_card/1` the mount uses — *consistency*, not styling). It carries exactly **one new
surface to ratify** (`update_course/2`) and **one interaction to decide** (live-search × broadcast).

**Why a dedicated styling pass before F6.8.** F6.8 is already the heaviest rung (auth + deploy + clustering +
the id-collision fix + the loopback-bind fix), and the *dynamic-UI styling reckoning* now lands there too
(F6.5.5 styled STATIC pages only; the auth LiveViews are the first DYNAMIC styled pages). F6.5.5 proved a
dedicated styling rung de-risks the work; the F6.7/F6.8 specs leave the door open ("F6.8, **or an earlier
dedicated pass**"). Pulling it forward keeps F6.8 to auth + ops.

---

## F6.7 · Real-time (PubSub & Presence) — ✅ SHIPPED (`ae7f986` + `2d1ab1c`)

[Spec: [`f6.7.md`](f6.7.md)] · Goal: the catalog updates live across every connected client, over the same facade.

**Deliverables**

| ID | Deliverable |
|---|---|
| D1 | Facade `Portal.subscribe/1` + `broadcast/2` over a supervised `Portal.PubSub` (`{Phoenix.PubSub, name: Portal.PubSub}` in `Portal.Application`). |
| D2 | Context broadcasts: `create_course/1` + `update_course/2` emit `{:course_created/updated, course}` via a `broadcast/2` helper that fires **only** on `{:ok, _}`. |
| D3 | `CatalogLive` subscribes to `"courses"` on its connected mount (behind `connected?/1`) and handles the events in `handle_info/2`. |
| D4 | Stream updates: `stream_insert(:courses, course, at: 0)` on create, `stream_insert(:courses, course)` on update — every client patches its own DOM, no reload. |
| D5 | `Presence`: `track/3` on connected mount + a `presence_diff` handler → a `viewers` count correct across the cluster. |
| D6 | (optional) a minimal channel (`join/3` + `handle_in/3` + `UserSocket`) for a non-LiveView client. |
| D7 | Verification: a create in one session appears in another without reload; an update replaces the row everywhere; the count tracks connect/disconnect across nodes; a failed write broadcasts nothing; only PubSub + Presence are new tree children; the LiveView still calls only the facade. |

**`[RECONCILE]` rationales** (why / what):

| Callout | Rationale |
|---|---|
| **`update_course/2` does not exist** | D2 broadcasts from an edit path F6.4/F6.5 never built (`Catalog` has list/get/fetch/create/change + F6.6's read-only `search_courses/1`). *Why: no update path is built yet* → define `update_course/2` (+ facade delegate) as the rung's **one new write surface below the facade** — Venus pins, Director ratifies — **or** drop `:course_updated` until an edit flow exists. |
| **Route inheritance — RESOLVED** | `live "/courses"` shipped at F6.6 (`3cf2480`), superseding the static index; reference by module, add no route. *Was the F6.6 reconcile; now shipped — no longer open.* |
| **`connected?/1` seam — built & waiting** | F6.6's two-stage mount left `connected?/1` guarding a no-op `:connected?` marker *explicitly as the F6.7 seam*; D3's `subscribe("courses")` lands in exactly that branch. *Why: F6.6 built the seam for this rung* → extend it, do not restructure the mount. |
| **Live-search × broadcast insert — new interaction** | F6.6's search re-streams on `@query` with `reset: true`; F6.7's `stream_insert` ignores `@query`, so a broadcast can insert a row **outside an active filter**. *Why: F6.6 shipped a live filter the broadcast path must reckon with* → decide at build: gate the insert on a `@query` match, or accept the interaction and record it. |
| **Styling — CONSISTENCY, not inheritance** | F6.5.5 styled STATIC pages, so `course_card` + the `live "/courses"` `CatalogLive` are **still unstyled**. *Why: F6.5.5 styled static documents, not the LiveView component F6.7 streams through* → a broadcast-inserted row must render through the **same `course_card/1`** the mount uses (styled if a prior pass styled it, bare if not). F6.7 does **not** own the live-catalog styling, only the match-the-mount invariant. |

**Decisions as shipped:** (1) `update_course/2` RATIFIED + built (`course |> Course.changeset/2 |> Repo.update/1`, the create-mirror) + the `Portal.update_course/2` delegate; (2) the live-search × broadcast-insert was **gated** on a `@query` substring match (mirrors `search_courses/1`'s title `ilike`). **As-built notes:** D6 (channel) DEFERRED; `Portal.subscribe/broadcast` are `def` (no delegate target); `apps/portal/mix.exs` += `phoenix_pubsub` visibility edge (`mix.lock` unchanged, F6.1-INV1 intent preserved); `Presence` single-node pending F6.8's libcluster. **Carried gap (NOT F6.7 code):** the pre-existing F6.1 endpoint-kill ETS-repopulation harness race flakes the full `portal_web` ≥100 loop (F6.7's own surface is 60/60 deterministic); fix in flight as its own scoped commit.

---

## A dedicated dynamic-UI styling pass (recommended; currently folded into F6.8)

[Source: the **Components & theming** `[RECONCILE]` in [`f6.8.md`](f6.8.md) — extracted here as a recommended standalone rung.]

The "style the live catalog" work that F6.5.5 legitimately deferred (it styled static documents, not the dynamic UI). A dynamic LiveView **cannot** carry a per-page extracted static stylesheet, so this is ONE reckoning:

| Deliverable (proposed) | Detail |
|---|---|
| Shared token stylesheet | The canonical F0 `:root` declared **once** — F0-INV2, **not yet realized in the Portal** (F6.5.5's tokens live per-page in `elixir-index.css`). |
| Root layout | A root layout the dynamic LiveViews render through (the Portal still sets `layouts: []`). |
| `CatalogComponents` restyle | `course_card` / `panel` / `input` → the F0 anatomy (`.mod` / `.fig` / `.pill.live` / `.btn`). |
| `CoreComponents` decision | Adopt the generated `CoreComponents` **restyled to F0** (superseding F6.5-INV8 as the UI surface grows) **OR** port the auth templates onto the local `CatalogComponents` set. |

**Why pull it forward:** it unblocks BOTH the F6.7 live catalog's eventual styling and the F6.8 auth LiveViews (the first dynamic styled pages), and it keeps F6.8 to auth + ops. If not pulled forward, it lands *inside* F6.8 (see below).

---

## F6.8 · Auth & deployment — THE CONVERGENCE POINT

[Spec: [`f6.8.md`](f6.8.md)] · Goal: authenticated users + a deployed, clustered release. **The heaviest rung — most deferred threads come due here.**

**Deliverables**

| ID | Deliverable |
|---|---|
| D1 | `mix phx.gen.auth Accounts User users` — the `Accounts` context (extending F6.4's), `User` + token schemas, login/registration/reset LiveViews, session plumbing. |
| D2 | Protected routes: `fetch_current_user` in `:browser`, `require_authenticated_user` on protected scopes, `on_mount` for LiveViews. |
| D3 | The facade fronts auth queries (`get_user_by_session_token/1`, `register_user/1`) — `UserAuth` + auth LiveViews call only `Portal`. |
| D4 | Config split: `runtime.exs` reads `DATABASE_URL` / `SECRET_KEY_BASE` / `PHX_HOST` at boot; compile-time config holds no secret. |
| D5 | `Portal.Release.migrate/0` (+ `rollback/2`) via `bin/portal eval` (a release has no `mix`). |
| D6 | Clustering: a libcluster topology so `Phoenix.PubSub` + `PortalWeb.Presence` span every node. |
| D7 | The deploy sequence: build (`MIX_ENV=prod mix release`) → migrate → boot. |
| D8 | Verification: register/login work; protected routes gate anonymous; a LiveView enforces on connect; the release builds/migrates/boots from env; PubSub/Presence correct across two nodes; the web still calls only the facade. |

**`[RECONCILE]` rationales** (why / what):

| Callout | Rationale |
|---|---|
| **Dynamic-UI styling reckoning comes due HERE** | The auth LiveViews are the **first dynamic styled pages**; a LiveView can't carry per-page extracted static CSS. *Why: F6.5.5 proved F0 reachable but only for static pages* → decide as ONE reckoning: **(1)** a shared token stylesheet (F0-INV2, not yet realized) + a root layout; **AND (2)** `CoreComponents` restyled to F0 (superseding INV8) **or** auth ported onto local `CatalogComponents`. *(Recommend extracting to the dedicated pass above.)* |
| **Deploy — the two-origin strangler-fig boundary** | A deployed Portal is an **index-only slice** in front of Fiber; deep links use the configurable `:deep_link_base_url` (default `jonnify.fly.dev`, one config read). *Why: F6.5.5 introduced a two-origin strangler-fig the deploy rung first ships to prod* → state which routes Portal owns vs. fall back to Fiber; set the base in `runtime.exs`; the dynamic UI **inherits the same key** (no second mechanism); migrating deep pages off Fiber is a later rung. |
| **Auth — generated `UserAuth` supersedes interim `RequireUser`** | *Why: F6.5's protected `/my/courses` rides the interim auth this rung replaces* → reconcile `current_user_id` → `current_user.id`, the pipeline → `require_authenticated_user`, the redirect → the generated login path. |
| **Context — generated `Accounts` is Repo-backed** | *Why: F6.4 `Accounts` is a Store stand-in* → reconcile Store stand-in (`user/1`/`welcome/1`) → Ecto `users` / tokens. |
| **Identity — branded-id mint unguarded under concurrency** | `create_course/1` mints + inserts outside the single-writer engine; `courses` has no `unique_constraint(:id)`, so two same-ms seq-0 mints RAISE `Ecto.ConstraintError`. *Why: F6.6's ≥100 loop surfaced it; a multi-node deploy makes it live* → derive `worker_id` per machine (`echo/CLAUDE.md` §4), and/or `unique_constraint(:id)` + graceful handling, and/or route create through the engine. |
| **`live /courses` shipped PUBLIC** | *Why: F6.6 added a public read+write surface the auth rung must classify* → decide: browsing stays public (likely)? gate the inline create behind `require_authenticated_user`? |
| **Endpoint bind hardcodes `127.0.0.1`** | `runtime.exs` binds loopback in every non-test env → a deployed release the Fly edge can't reach. *Why: the F6.6 liveness boot surfaced it; deployment makes it load-bearing* → set `{0,0,0,0}`/`:any` under release/`:prod`, keep `127.0.0.1` for dev. |

---

## F6.9 · The live dashboard — THE CAPSTONE

[Spec: [`f6.9.md`](f6.9.md)] · Goal: a read-only, real-time operations dashboard folding the events the system already broadcasts.

**Deliverables**

| ID | Deliverable |
|---|---|
| D1 | `DashboardLive` with a socket read model: `courses_count` / `enrollments_count` seeded from the F6.4 contexts at mount + a capped `stream(:events, …)`. |
| D2 | On connected mount: `Portal.subscribe("events")` + `Presence.track/3` in `"dashboard"`. |
| D3 | The `handle_info/2` fold: `{:course_created,_}` / `{:enrolled,_}` bump the count + prepend a feed row; `presence_diff` recomputes `viewers`. |
| D4 | Render: HEEx metric cards from assigns + the feed under `phx-update="stream"`; read-only, no write control. |
| D5 | A `Presence` viewer count = `map_size(Presence.list("dashboard"))`, cluster-correct. |
| D6 | The route in a `live_session` under F6.8 auth, read-only. |
| D7 | Verification: counts seed at mount; events bump the right count + prepend live; the viewer count tracks across nodes; the page is read-only + authed; the feed is a capped stream. |

**`[RECONCILE]` rationales** — all *inheritance* (the capstone composes everything below):

| Callout | Rationale |
|---|---|
| **Facade — new counts go through `Portal`** | `Catalog.count_courses/0` + `Enrollment.count/0` are new context additions surfaced on the facade. *Why: web names only the facade.* |
| **Surface — the `{:enrolled, _}` broadcast is new** | F6.7 broadcasts course events; D3 folds enrollment. *Why: F6.7 covers courses, not enrollment* → the ok-only enrollment broadcast is added here. |
| **Auth — `/dashboard` rides the F6.8 reconcile** | The `live_session` `on_mount` inherits F6.8's `UserAuth` / `current_user`. *Why: depends on the F6.8 auth reconcile.* |
| **The live-list pattern is set by F6.6/F6.7** | Reuse `stream(:courses)` + `course_card` + the `handle_info` `stream_insert` fold. *Why: F6.6 established the stream + component reuse; F6.9 composes it.* |
| **Styling — inherits F0 through the F6.8 shell, not F6.5.5 directly** | The metric cards + feed render in the F0 anatomy through the **root layout + shared token stylesheet F6.8 introduces**. *Why: F6.9 composes everything below; the dynamic-UI look is set by F6.8, with F6.5.5 supplying the token VALUES + the static-parity proof, not a live shell.* |

---

## Parallel track — F10 bot (operator-authored, out-of-band)

The **F10 bot chapter** (`docs/elixir/specs/bot/f10.*`) is authored concurrently by the Operator — a Telegram-bot
surface over the **same `Portal` facade**. It is downstream of the F6 web ladder and **not** part of this F6
sequence, but it inherits the master invariant (web/bot names only `Portal`, never the engine/repo/`GenServer.call`).
Out-of-band for the lead-team; excluded from every F6 commit.

---

## How to use this file

- **Source of truth is the per-rung spec triad**, not this view. When a rung is groomed into the build, its
  `f6.N.{md,stories.md,llms.md}` is updated; this file tracks the *plan + sequencing*, and the `[RECONCILE]`
  rationales are mirrored from the spec bodies (re-sync if a spec's callout changes).
- Each rung's **open decisions** (the surfaces to ratify, the interactions to decide) are the Director's pre-build
  agenda — settle them in Venus's reconcile before Mars builds (the lag-1 discipline).
- The recommended insertion of a **dedicated dynamic-UI styling pass** before F6.8 is a Director recommendation,
  not yet a spec; if adopted, give it its own triad (the F6.5.5 template) and the F6.8 styling `[RECONCILE]`
  resolves to "inherited from the styling pass."

---

Index: [`phoenix.md`](phoenix.md) · delivery view [`phoenix.roadmap.md`](phoenix.roadmap.md) · L0 field manual
[`phoenix.operator.md`](phoenix.operator.md) · retrospective [`f6.progress.md`](f6.progress.md) · rungs
[`f6.7.md`](f6.7.md) · [`f6.8.md`](f6.8.md) · [`f6.9.md`](f6.9.md). Approach: [`../specs.approach.md`](../specs.approach.md).

> Part of the jonnify toolkit. Branded id format: `TSK` + Base62(snowflake), e.g. `TSK0KHTOWnGLuC`.
