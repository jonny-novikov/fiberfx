# F6 · Phoenix — the decomposition reference (for A2.07 "Workshop — decomposing Portal")

- **Role:** the distilled, self-contained reference the three A2.07 dive writers read *instead of* the raw
  `docs/elixir/specs/phoenix/` spec system. Everything a dive needs to cite the F6 decomposition correctly is here.
- **Source of truth:** `docs/elixir/specs/phoenix/` — `phoenix.roadmap.md` (the delivery view),
  `phoenix.md` (the value-ladder index), and each rung's triad `f6.N.md` / `f6.N.stories.md` / `f6.N.llms.md`.
- **Course route family it documents:** the live `/elixir/phoenix` chapter (the companion course that *builds*
  these rungs). The agile course's A2.07 module *decomposes* them.
- **No-invent rule (relaxed to the real F6 API):** you may cite the real surfaces that appear in the specs —
  `Portal` facade, `Catalog`, `Enrollment`, `Accounts`, `CatalogLive`, `DashboardLive`, `Portal.search_courses/1`,
  `%Portal.Error{}`, etc. — **only as written in the source**. Quote; do not invent. Every user story and every
  Given/When/Then a dive prints must be verbatim from `f6.N.stories.md` (see `rungs.md`, the citable-string source).

## The one-line vision, decomposed

The F6 chapter is one product vision — **serve the Portal to people** — decomposed into **nine vertical rungs**,
`f6.1`–`f6.9`. Each rung ships one capability a real role can use, calls only the unchanged `Portal` facade, and
leaves the platform running. This is the iconic, concrete artifact A2.07 teaches decomposition on: not an abstract
pipeline, but a real chapter that was specified, built, and proven in a repository the student can read.

## The nine-rung ladder

`delivers` is the verbatim first line of each rung's `> …` summary blockquote / Goal in `f6.N.md`, compressed to
one line. `status`/`dates` are derived from the git history (see the timeline below). The `/elixir` route is the
live companion-course chapter that builds the rung.

| Rung | Title | Delivers (from `f6.N.md`) | Status | Dates | Milestone | `/elixir` route |
|---|---|---|---|---|---|---|
| F6.1 | Bootstrap the Phoenix Portal | the headless F5 engine stands up as a real Phoenix web app — `PortalWeb.Endpoint` joins the supervision tree, a thin controller calls only the `Portal` facade, a `GET /health` route proves it is up | shipped | specced 02 Jun · shipped 03 Jun | M1 · ship the catalog | `/elixir/phoenix/lifecycle` |
| F6.2 | Routing & the access surface | a real routing surface on F6.1's endpoint — read/write/REST/live routes, the `:browser`/`:api`/`:require_auth` pipelines, a protected scope, a reusable `RequireUser` plug, every URL a verified `~p` path | shipped | specced 02 Jun · shipped 04 Jun | M1 | `/elixir/phoenix/routing` |
| F6.3 | Persistence with Ecto | durability without coupling the core to a database — Ecto as one adapter behind the F5 `Portal.EventStore` port, Snowflake `:bigint` ids, a parse-at-the-boundary `Course.changeset/2` | shipped | specced 02 Jun · shipped 04 Jun | M1 | `/elixir/phoenix/ecto` |
| F6.4 | Contexts & domain on the web | the real domain behind one surface — `Catalog`, `Enrollment`, and `Accounts` contexts, with the `Portal` facade `defdelegate`-ing to all three, composing only through public functions | shipped | specced 02 Jun · shipped 04 Jun | M1 | `/elixir/phoenix/contexts` |
| F6.5 | Views with HEEx | the catalog server-rendered — an index over `@courses` with `:for`/`~p`/escaping/`:if`, a `course_card` component, a slot-based `panel`, a local `input/1`, a changeset-backed create form with inline errors | shipped | specced 02 Jun · shipped 04 Jun | M1 | `/elixir/phoenix/heex` |
| F6.6 | LiveView | F6.5's catalog made interactive without reloads — `CatalogLive` streams from the facade, a two-stage mount, a live search box via `Portal.search_courses/1`, a live create form | shipped | specced 02 Jun · shipped 05 Jun | M2 · make it live | `/elixir/phoenix/liveview` |
| F6.7 | Real-time (PubSub & Presence) | F6.6's per-socket state pushed across every client — a facade `subscribe`/`broadcast` wrapper, context broadcasts only after a successful write, `stream_insert/3` in `handle_info/2`, a cluster-correct `Presence` viewer count | specified | specced 02 Jun · reconciled 04 Jun | M2 | `/elixir/phoenix/pubsub` |
| F6.8 | Auth & deployment | the running app turned into a deployed product — `mix phx.gen.auth`, `on_mount` guards, `runtime.exs` secrets, a `Portal.Release` migration task, a libcluster topology | specified | specced 02 Jun · reconciled 04 Jun | M3 · ship to users | `/elixir/phoenix/deployment` |
| F6.9 | The live dashboard (capstone) | the whole chapter composed into one read-only live page — `DashboardLive` seeds counts, folds domain broadcasts into a read model, prepends a capped feed, shows a `Presence` count, under auth, cluster-correct | specified | specced 02 Jun · reconciled 04 Jun | M3 | `/elixir/phoenix/live-dashboard` |

The rungs depend only downward: F6.2 assumes F6.1's endpoint; F6.5 renders what F6.3/F6.4 make queryable; F6.6
makes F6.5's pages live; F6.7 pushes F6.6's state across clients; F6.9 composes all of it.

## The three milestones — the delivery arc

Verbatim from `phoenix.roadmap.md`, "The delivery arc":

| Milestone | Rungs | What you can do at the end |
|---|---|---|
| 1 · Ship the catalog | F6.1–F6.5 | browse a persistent catalog and add courses, server-rendered, with inline errors |
| 2 · Make it live | F6.6–F6.7 | search and create without reloads; every client updates live with a viewer count |
| 3 · Ship to users | F6.8–F6.9 | sign in, run behind auth on a deployed clustered release, watch an operations dashboard |

The arc is **the first deployable product first, then layer interactivity, real-time, and operations on top**.
M1 is a persistent, server-rendered catalog you can browse and add to. M2 makes it interactive and live. M3
(auth, deployment, dashboard) follows once the live catalog earns feedback. This ordering is the value-ladder
move A2.06 taught, applied for real: each milestone rests on the ones below it and the system stays runnable.

## The four artifacts per rung

Every rung is carried by exactly four artifacts. This mapping is what A2.07.2 (split-and-test) shows on one rung:

| Artifact | File | Role |
|---|---|---|
| The roadmap line | a row in `phoenix.roadmap.md` | the rung's place in the delivery order — what it ships, its demo, its harness, the feedback asked |
| The spec | `f6.N.md` | Goal · Rationale (5W) · Scope · Deliverables · Invariants · Definition of Done |
| The stories | `f6.N.stories.md` | Connextra user stories ("As a `<role>`, I want… so that…") + Given/When/Then acceptance, each tagged INVEST + priority + size |
| The agent brief | `f6.N.llms.md` | the references, requirements, execution topology, and the paste-ready prompt an agent runs to build and self-check the rung |

## The master invariant

Verbatim from `phoenix.roadmap.md` and `phoenix.md`:

> The web layer calls only the `Portal` facade and renders only the closed `%Portal.Error{}` set. No controller,
> LiveView, plug, or template names `Portal.Engine`, a repo, or `GenServer.call`.

This single rule is what makes the ladder cheap: every rung adds web surface without reaching below the facade, so
nothing under the F5 engine ever changes. The only structural change to the F5 supervision tree across all of F6 is
adding `PortalWeb.Endpoint` (F6.1); later rungs add `Phoenix.PubSub` and `Phoenix.Presence` only as the real-time
features require them (F6.7). `%Portal.Error{}` is the closed set
`:already_enrolled | :course_not_found | :lesson_locked | :invalid_progress`.

## Where F6 starts and ends (the handoff)

- **Start — the F5 handoff (`../pragmatic/f5.9.md`).** A supervised application — the `Portal.EventStore` adapter
  and `{Portal.Engine, []}` — behind a single facade `Portal` (commands `enroll/2`, `deliver_lesson/2`; queries
  `progress_of/1`, `courses_of/1`) returning `:ok | {:ok, data} | {:error, %Portal.Error{}}`, with `%Portal.Error{}`
  a closed set. F6 starts here and changes nothing below the facade.
- **End — after F6.9.** The same engine, unchanged, deployed as a live, multi-client platform: server-rendered
  pages, interactive LiveViews, real-time updates across clients, authenticated users, and an operations dashboard
  — all calling only the facade.

## The git evolution timeline

The decomposition is not hypothetical — it left a trail in the repository. A2.07 reads that trail. The cadence is
**spec → build → reconcile**: feedback edits the spec (the single source of truth), and downstream specs are
re-grounded against the as-built surface before they are built (a "lag-1 reconcile").

| Date | Commit | What changed |
|---|---|---|
| 02 Jun | `d2f959d` | the nine f6.N specs written — `[portal] f6 phoenix specs` (the whole ladder specced up front) |
| 03 Jun | `470cd90` | **F6.1 built** — `feat(portal_web): bootstrap the Phoenix Portal web app (F6.1)` |
| 04 Jun | `c98dabe` | F6.2 reconciled to the as-built F6.1, F6.1 marked shipped (the lag-1 reconcile) |
| 04 Jun | `98ef445` | F6.3 spec remediated to branded-string-surface / `:bigint`-column identity; F6.2 marked shipped |
| 04 Jun | `5a440fd` | **F6.5 reconcile** — `/courses` = catalog, `/my/courses` = enrollments (resolves a route collision) |
| 04 Jun | `47a15f1` | F6.6–F6.9 backlog groomed — the F6.5 direction folded forward into each downstream spec |
| 04 Jun | `0911b4d` | Specification-by-Example applied to the F6.6–F6.9 stories |
| 05 Jun | `3cf2480` | **F6.6 built** — `LiveView catalog: live search + live create over the facade` |
| 05 Jun | `706df05` | F6.6 feedback loop: Stage 6 reconcile of F6.7–F6.9 (the next rungs re-grounded against shipped F6.6) |

The shape A2.07.3 (order-the-backlog) reads from this: **F6.1–F6.6 are shipped** (a feat commit + a marked-shipped
line each); **F6.7–F6.9 are specified and reconciled forward**, not yet built — the frontier the hub slider draws
after F6.6. Each downstream rung carries a `[RECONCILE]` callout at the top of its body folding the shipped
direction forward, and takes a pre-build lag-1 reconcile before it is built.

## For the dives

The module has three dives, in the arc **write → slice → order** (what & why → how → when). Each maps to a
section of these references and a specific set of rungs to feature:

| Dive | Focus | Read here | Feature these rungs |
|---|---|---|---|
| **A2.07.1 · vision-to-stories** | *what & why* — read the one-line vision into its ladder of **real** stories | this file's "nine-rung ladder" + the **whole of `rungs.md`** (the verbatim story per rung) | the ladder end to end; lead with F6.1 (`US1`/`US2`), F6.5 (`US1`), and F6.6 (`US1` "Search as I type") as the cleanest "As a `<role>`, I want…" exemplars |
| **A2.07.2 · split-and-test** | *how* — show ONE rung as its four artifacts + its Given/When/Then proof | "The four artifacts per rung" (this file) + **`rungs.md` § F6.6** | **F6.6 (LiveView)** only — its four artifacts and its `US1` Given/When/Then (`phx-change="search"` → `handle_event("search", …)` → `Portal.search_courses/1`) |
| **A2.07.3 · order-the-backlog** | *when* — order the rungs into milestones; read the git timeline | "The three milestones" + "The git evolution timeline" (this file) | the three milestones across all nine rungs; the shipped/specified frontier after F6.6; the spec→build→reconcile cadence |

Each dive's `/elixir/phoenix` cross-link(s): A2.07.1 → `/elixir/phoenix` (the chapter) + `/elixir/phoenix/liveview`;
A2.07.2 → `/elixir/phoenix/liveview` (where F6.6 is built); A2.07.3 → `/elixir/phoenix` + `/elixir/phoenix/deployment`
(the M3 frontier). All resolve `200` against the live server.

---

Companion reference (the citable verbatim strings): [`rungs.md`](rungs.md). Sources of truth:
`docs/elixir/specs/phoenix/phoenix.roadmap.md`, `phoenix.md`, `f6.N.md` / `f6.N.stories.md`.
