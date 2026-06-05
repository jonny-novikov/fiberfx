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

## A dedicated dynamic-UI styling pass (recommended; NO LONGER folded into F6.8.1 — it re-defers here)

[Source: the **Components & theming** `[RECONCILE]` in the original `f6.8.md`, now [RECONCILE 2] in [`f6.8.1.md`](f6.8.1.md).]

**Update (the F6.8 split):** [`f6.8.1.md`](f6.8.1.md) RECONCILE 2 establishes that the auth UI is a STATIC login-page
port (per-page extracted CSS, like F6.5.5) — so it is NOT a dynamic styled page and does NOT force the reckoning. The
dynamic-UI styling pass below therefore **re-defers to the first genuinely-dynamic styled page** (the live `/courses`
restyle, or the F6.9 dashboard) — it is no longer "folded into F6.8." The deliverables stand; only its trigger moves.

The "style the live catalog" work that F6.5.5 legitimately deferred (it styled static documents, not the dynamic UI). A dynamic LiveView **cannot** carry a per-page extracted static stylesheet, so this is ONE reckoning:

| Deliverable (proposed) | Detail |
|---|---|
| Shared token stylesheet | The canonical F0 `:root` declared **once** — F0-INV2, **not yet realized in the Portal** (F6.5.5's tokens live per-page in `elixir-index.css`). |
| Root layout | A root layout the dynamic LiveViews render through (the Portal still sets `layouts: []`). |
| `CatalogComponents` restyle | `course_card` / `panel` / `input` → the F0 anatomy (`.mod` / `.fig` / `.pill.live` / `.btn`). |
| `CoreComponents` decision | Adopt the generated `CoreComponents` **restyled to F0** (superseding F6.5-INV8 as the UI surface grows) **OR** port the auth templates onto the local `CatalogComponents` set. |

**Why pull it forward:** it unblocks BOTH the F6.7 live catalog's eventual styling and the F6.8 auth LiveViews (the first dynamic styled pages), and it keeps F6.8 to auth + ops. If not pulled forward, it lands *inside* F6.8 (see below).

---

## F6.8 · Auth & deployment — SPLIT into F6.8.1 (auth) + F6.8.2 (deploy)

[Parent pointer: [`f6.8.md`](f6.8.md)] The original "convergence point" rung was split (the decimal-insertion split,
mirroring F6.5 → F6.5.5) so the visible auth surface and the deploy machinery ship and accept independently. Both
spec triads are authored (**specced**); the parent [`f6.8.md`](f6.8.md) is a thin pointer.

### F6.8.1 · Authentication — the honest door

[Spec: [`f6.8.1.md`](f6.8.1.md)] · Goal: real sign-in + a protected area, the visible surface ported the F6.5.5 way.

| ID | Deliverable |
|---|---|
| D1–D2 | The static `login.html` ported (a `PageController.login/2` + a complete-document `login.html.heex` + extracted `login.css`/`login.js` + `GET /login`) — NOT `phx.gen.auth` (the `%User{}`/`%Session{}` entities already exist from F6.4). |
| D3–D5 | A NET-NEW `Portal.Auth` facade: `sign_in/2` (the honest door — the SAME `{:error, :invalid_credentials}` for wrong-name and wrong-password) + `request_reset/1` (always `:ok`, no enumeration), over the existing entities + a private `password_hash` (Store-backed + `bcrypt_elixir`, RATIFIED — no schema). |
| D6–D8 | `SessionController` (`POST /auth/session` writes the signed session + redirects; `POST /auth/reset` answers 200 either way) + the routes + the F6.2 `RequireUser` gate evolved into `PortalWeb.UserAuth` (`fetch_current_user/2`, `require_authenticated_user/2` → redirect to `/login`, `on_mount/4` `:ensure_authenticated`). |
| D9–D10 | `/my/courses` reconciled to the loaded `current_user`; registration DEFERRED (the *"Soon"* footer preserved); verification (the honest door + the redirect + the parity envelope). |

**`[RECONCILE]` rationales** (why / what):

| Callout | Rationale |
|---|---|
| **Static login port over `Portal.Auth`, NOT `phx.gen.auth`** | *Why: `%User{}`/`%Session{}` already exist (F6.4); the Operator wants the static `login.html` ported in the F6.5.5 design system* → a `PageController.login/2` static-parity page + a net-new `Portal.Auth` facade backing the `/auth/*` POSTs; generated auth LiveViews + `CoreComponents` NOT adopted. |
| **The dynamic-UI styling reckoning DISSOLVES here (re-defers)** | A static login port carries per-page extracted CSS (like F6.5.5) → there are NO dynamic auth LiveViews. *Why: the reckoning the combined rung pinned to "the auth UI" has no dynamic auth UI to attach to* → it re-defers to the dedicated dynamic-UI styling pass (the live `/courses` restyle or F6.9). The F6.6 flash-paint deferral moves with it. |
| **`UserAuth` supersedes interim `RequireUser`** | *Why: F6.5's protected `/my/courses` + the `RequireUser` moduledoc ("F6.8 later swaps the redirect target") ride the interim auth this rung replaces* → `current_user_id` → a loaded `current_user`, the redirect → `~p"/login"`, the named surface F6.9's `{PortalWeb.UserAuth, :ensure_authenticated}` forward-ref expects. |
| **Persistence — Store-backed + bcrypt (RATIFIED)** | *Why: F6.4 `Accounts` is a Store stand-in with no credential* → add a private `password_hash` + `bcrypt_elixir` (one net-new dep in `apps/portal/mix.exs`), no schema, no migration. The Ecto-tables alternative is documented, not built. |
| **`live /courses` stays PUBLIC; inline-create gating deferred** | *Why: F6.6 added a public read+write surface* → browsing stays public; gating the inline create behind auth is deferred to the dynamic-UI pass (F6.8.1 ships the gate, that pass applies it). |

### F6.8.2 · Deployment

[Spec: [`f6.8.2.md`](f6.8.2.md)] · Goal: a deployable, clustered release — the ARTIFACTS, gated BUILD-LOCAL (the live `fly deploy` is the Operator's).

| ID | Deliverable |
|---|---|
| D1–D2 | A scoped umbrella `releases/0` (`portal_web`/`portal`/`echo_data`, EXCLUDING `echo_bot`) + a completed Dockerfile built FROM the Operator's template (corrected to Elixir 1.18.4 / OTP 28.1, de-Codemoji'd, a runtime stage + `ENTRYPOINT`). |
| D3–D4 | The completed config split: `runtime.exs` reads `DATABASE_URL`/`SECRET_KEY_BASE`/`PHX_HOST` at boot + binds `{0,0,0,0}` under prod (dev loopback); `prod.exs` holds the endpoint `url`/`cache_static_manifest`/`server`-toggle. |
| D5–D7 | `Portal.Release.migrate/0` (via `bin/portal eval`); a libcluster topology (F6.7 single-node Presence → cluster-correct); a per-machine `worker_id` (the F6.6 mint-collision fix). |
| D8–D10 | A distilled `fly.toml` (the Portal essentials, the `/health` check matching `router.ex:93`); the strangler-fig boundary stated + the deployed `:deep_link_base_url` set; BUILD-LOCAL verification. |

**`[RECONCILE]` rationales** (why / what):

| Callout | Rationale |
|---|---|
| **Image version skew — the templates pin OTP 27** | `Dockerfile.template:3` + `fly.toml:35` carry `OTP_VERSION="27.3.4.1"`. *Why: this umbrella is Elixir 1.18.4 / OTP 28.1 (`.tool-versions`)* → correct to `28.1` (the Operator confirms the exact 28.x tag); `ELIXIR_VERSION=1.18.4` matches; drop `NODE_VERSION`. |
| **Dockerfile builds `apps/echo` (Codemoji), absent here** | `Dockerfile.template:32-45` copies/builds `apps/echo`. *Why: this umbrella's apps are portal/portal_web/echo_data/echo_bot* → a scoped `releases/0` (the Portal apps, `echo_bot` excluded), the umbrella-root build, a runtime stage + `ENTRYPOINT`. |
| **`fly.toml` DISTILL** | *Why: the template is the full Codemoji v8 config (Fastify/Redis/SQLitestream/Datadog)* → keep the Portal essentials (app/region/PHX env/the IPv6-cluster trio/`[build]`/rolling+auto_rollback/`:4000` + 80→443 + the `GET /health` check matching `router.ex:93`); drop all worker/Redis/BullMQ/SQLitestream/`DD_*`/`GAME_DB` config. |
| **Endpoint bind hardcodes `127.0.0.1`** | `runtime.exs:34` binds loopback in every non-test env → a deployed release the Fly edge can't reach. *Why: the F6.6 liveness boot surfaced it; deployment makes it load-bearing* → set `{0,0,0,0}`/`:any` under release/`:prod`, keep `127.0.0.1` for dev. The config split is partly done (the `SECRET_KEY_BASE`/`DATABASE_URL` raises); F6.8.2 completes it (+ `PHX_HOST`). |
| **Branded-id mint unguarded under concurrency** | `id.ex:13` `@node 1` (its comment "F6.8 derives it per machine") + the same-ms collision (`echo/CLAUDE.md §4`). *Why: F6.6's ≥100 loop surfaced it; a multi-node deploy makes it live* → derive `worker_id` per machine (`FLY_MACHINE_ID`), and/or `unique_constraint(:id)`. |
| **Clustering realizes F6.7's single-node real-time** | *Why: F6.7 shipped PubSub/Presence single-node* → a `libcluster` topology (one net-new dep in `apps/portal_web/mix.exs`; the `fly.toml` IPv6/`ERL_AFLAGS` trio its substrate) so broadcasts + viewer counts span nodes. |
| **The two-origin strangler-fig boundary becomes prod** | *Why: F6.5.5 introduced a two-origin strangler-fig the deploy rung first ships to prod* → state which routes Portal owns (`/`,`/elixir`,`/course/agile-agent-workflow`,`/login`,`/auth/*`,`live /courses`,`/my/courses`,`/health`) vs. fall back to Fiber via `:deep_link_base_url`; set the base in `runtime.exs`. |

> **DEFERRED to the Operator:** the live `fly deploy` (+ `fly apps create`, the machines) — *"the user will create the fly app and machines."* F6.8.2's gate is BUILD-LOCAL (`MIX_ENV=prod mix release` builds; `Portal.Release.migrate/0` runs; `fly config validate`; a local prod boot answers `/health` 200).

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
| **Auth — `/dashboard` rides the F6.8.1 reconcile** | The `live_session` `on_mount` inherits F6.8.1's `PortalWeb.UserAuth` / `current_user` (`{PortalWeb.UserAuth, :ensure_authenticated}`). *Why: depends on the F6.8.1 auth reconcile.* |
| **The live-list pattern is set by F6.6/F6.7** | Reuse `stream(:courses)` + `course_card` + the `handle_info` `stream_insert` fold. *Why: F6.6 established the stream + component reuse; F6.9 composes it.* |
| **Styling — inherits F0 through the dynamic-UI styling pass, not F6.8.1 directly** | The metric cards + feed render in the F0 anatomy through the **root layout + shared token stylesheet the dynamic-UI styling pass introduces** (F6.8.1 RECONCILE 2 re-defers it there — the static login port adds no dynamic shell). *Why: F6.9 composes everything below; the dynamic-UI look is set by the styling pass, with F6.5.5 supplying the token VALUES + the static-parity proof, not a live shell.* |

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
- The recommended insertion of a **dedicated dynamic-UI styling pass** is a Director recommendation, not yet a
  spec; if adopted, give it its own triad (the F6.5.5 template). F6.8.1 RECONCILE 2 re-defers the dynamic-UI
  reckoning to it (the static login port adds no dynamic shell), so the F6.9 styling `[RECONCILE]` resolves to
  "inherited from the styling pass," not from F6.8.

---

Index: [`phoenix.md`](phoenix.md) · delivery view [`phoenix.roadmap.md`](phoenix.roadmap.md) · L0 field manual
[`phoenix.operator.md`](phoenix.operator.md) · retrospective [`f6.progress.md`](f6.progress.md) · rungs
[`f6.7.md`](f6.7.md) · [`f6.8.md`](f6.8.md) ([`f6.8.1.md`](f6.8.1.md) · [`f6.8.2.md`](f6.8.2.md)) · [`f6.9.md`](f6.9.md). Approach: [`../specs.approach.md`](../specs.approach.md).

> Part of the jonnify toolkit. Branded id format: `TSK` + Base62(snowflake), e.g. `TSK0KHTOWnGLuC`.
