# Portal · status board

> A single-screen view of where the Portal program stands: every chapter and rung across spec / stories / brief /
> implementation, the `f[N]` dependency DAG that orders them, the program milestones, and the next sprint queued for a
> rigorous Claude X-Mode session. The narrative plans live in [`portal.roadmap.md`](portal.roadmap.md) and the
> per-chapter roadmaps; this file is the dashboard. The specs stay the single source of truth; this board reports them.

**Legend.** Artifact columns: `✓` present · `—` absent · `◐` partial. Status: **shipped** (built + tested) ·
**next** (queued sprint) · **specced** (full triad written) · **planned** (named, no file) · **roadmapped** (abstract
only) · **open** (reserved, undesigned) · **given** (assumed foundation). Implementation lives in the Elixir umbrella
at `echo/` (apps `echo_data` + `portal`; asdf Elixir 1.18.4 / OTP 28); the design system is built and tooled in the Go
`apps/jonnify-cms`.

## Program at a glance

| Chapter | Theme | Surface | Spec | Implementation | Status |
| --- | --- | --- | --- | --- | --- |
| **F0** · [Design System](design/f0.md) | rendering foundation | — | ✓ triad + [roadmap](design/f0.roadmap.md) | static `/elixir` + `jonnify-cms` content store parity ✓; Portal HEEx — | **specced** |
| **F4** · Branded store | given foundation | — | — (assumed by F5) | in-memory stand-in ✓ · branded CHAMP — | **given** |
| **F5** · [The engine](pragmatic/pragmatic.md) | headless core | — | ✓ F5.1–F5.9 | F5.1–F5.9 shipped ✓ (the ladder is closed) | **complete** (M1) |
| **F6** · [The web](phoenix/phoenix.md) | web | LiveView / HEEx | ◐ F6.1–F6.7 triads · F6.8–F6.9 named | `apps/portal_web` — | **specced** |
| **F7–F9** · Multi-runtime | messaging / workers | — | — | — | **open** |
| **F10** · [The bot](bot/f10.roadmap.md) | chat | Telegram (ex_gram) | ◐ abstracts F10.1–F10.9 | — | **roadmapped** |

## The `f[N]` DAG

Chapters stack the way rungs do — depend only downward. The store grounds the engine; the engine exposes one facade;
every surface sits on that facade and renders only the closed `%Portal.Error{}` set. F0 is orthogonal: the rendering
foundation that the web surface (and the static course) draw on.

```text
        F0  Design System ............ tokens · envelope · anatomy · 9 gates · jonnify-cms store
         ┊  (rendering foundation; reproduced by F6's HEEx)            (byte-parity proven)
         ┊
F4  Branded store (given)
     │  Portal.Store: get/2 · all/2 · put/1
     ▼
F5  The engine ───────────────▶  Portal facade  +  closed %Portal.Error{}
     │  decide/evolve · EventStore port · supervised by OTP
     │  (the one public surface — the boundary the master invariant protects)
     ├──────────────────┬───────────────────────────────┐
     ▼                  ▼                               ▼
F6  The web         F10 The bot                   F7–F9  Multi-runtime (open)
 (LiveView/HEEx)     (ex_gram, in-BEAM)             EchoMQ bus · Fastify/Go workers
     ╎  renders F0       │  F10.8 webhook leans on F6.1's endpoint
     └── both call only the facade ──┘  F10.9 scale-out seam ─▶ EchoMQ (F7–F9)
```

**Rung ladders** (each rung depends only on those below it):

```text
F5 :  F5.1 ▸ F5.2 ▸ F5.3 ▸ F5.4 ▸ F5.5 ▸ F5.6 ▸ F5.7 ▸ F5.8 ▸ F5.9
      └──────────── shipped (the ladder is closed) ──────────────┘
F6 :  F6.1 ▸ F6.2 ▸ F6.3 ▸ F6.4 ▸ F6.5 ▸ F6.6 ▸ F6.7 ▸ (F6.8 ▸ F6.9 planned)
      ↑next
F0 :  D1 ▸ D2 ▸ D3 ▸ D4 ▸ D5 ▸ D6 ▸ D7 ▸ D8     (D6–D8 already tooled in jonnify-cms)
F10:  F10.1 ▸ … ▸ F10.5 (near-term) ▸ … ▸ F10.9 (scale-out seam)   — abstracts
```

## F5 · The engine — rung status (the closed chapter)

Implemented in `echo/apps/portal`; `mix test` green (echo_data 2; portal 6 doctests / 4 properties / 50 tests / 0
failures, no mocks); a live node answers on `:4000`; the supervision-kill gate, the determinism loop (150/150 green
under a PORT override — the Director's ratification gate on `PORT=4222`, convergent with Apollo's `PORT=4123`), and the
`lib/portal_web/` boundary-purity grep pass. **The F5 ladder is closed — F5.1 → F5.9 are shipped.** F5.1 → F5.8 landed
at `b099eee`; F5.9 (the confirmed assembled tree + the compile-only `PortalWeb.EnrollmentLive` sketch + the F6 handoff)
ratified at 150/150 green and ships in the Director's single LAW-4 F5.9 commit alongside the closure docs. See the
closure retrospective in [`pragmatic/f5.progress.md`](pragmatic/f5.progress.md).

| Rung | Increment | Spec | Stories | Brief | Impl | Status |
| --- | --- | :-: | :-: | :-: | :-: | --- |
| [F5.1](pragmatic/f5.1.md) | Start thin: a running Portal | ✓ | ✓ | ✓ | ✓ | **shipped** |
| [F5.2](pragmatic/f5.2.md) | Model the Portal domain | ✓ | ✓ | ✓ | ✓ | **shipped** |
| [F5.3](pragmatic/f5.3.md) | Tracer bullets: a walking skeleton | ✓ | ✓ | ✓ | ✓ | **shipped** |
| [F5.4](pragmatic/f5.4.md) | The enroll contract | ✓ | ✓ | ✓ | ✓ | **shipped** |
| [F5.5](pragmatic/f5.5.md) | Commands, queries & events | ✓ | ✓ | ✓ | ✓ | **shipped** |
| [F5.6](pragmatic/f5.6.md) | Where engine state lives | ✓ | ✓ | ✓ | ✓ | **shipped** |
| [F5.7](pragmatic/f5.7.md) | Pragmatic testing | ✓ | ✓ | ✓ | ✓ | **shipped** |
| [F5.8](pragmatic/f5.8.md) | Boundaries & integration seams | ✓ ◐refined | ✓ | ✓ | ✓ | **shipped** |
| [F5.9](pragmatic/f5.9.md) | The engine, LiveView-ready (lab) | ✓ ◐refined | ✓ | ✓ | ✓ | **shipped** |

**Carried-forward gaps** (recorded in the F5.9 closure retrospective, to close downstream): the dual-write
`Portal.Store` `%Enrollment{}` projection is retained until F6.3/F6.4 collapse it; the two reserved `%Portal.Error{}`
codes (`:lesson_locked`, `:invalid_progress`) have no producer until a later lesson-delivery contract; `progress_of/1`
reads a structural `0`; `event_log.ex` is dead code retained do-no-harm; the `:courses_of` vs `:enrollments` two-layer
naming unifies at F6.4. The single F6-resume reconciliation: `f6.1.md`'s tree omits the `Portal.Store` that
`courses_of/1` needs (below).

## F6 · The web — rung status

None implemented; `apps/portal_web` is added when F6.1 starts — the next chapter now that the F5 ladder is closed.
F6.1–F6.7 carry full triads; F6.8–F6.9 are named but unwritten. **One F6-resume reconciliation is recorded** (in the
F5.9 closure retrospective): `f6.1.md` F6.1-D2's three-child tree `[Portal.EventStore.adapter(), {Portal.Engine, []},
PortalWeb.Endpoint]` omits the `Portal.Store` that F6.1-D4's `CourseController.index/2 → Portal.courses_of/1` reads, so
as specced F6.1 would boot a controller over an unstarted read model; F6.1's tree should become `[Portal.Store,
Portal.EventStore.adapter(), Portal.Engine, PortalWeb.Endpoint]` (a Bandit → `Endpoint` swap, `Portal.Store` retained
until F6.3/F6.4 collapses the dual-write). (Housekeeping per the program roadmap: confirm F6.2/F6.3 are uniform in the
triad format.)

| Rung | Feature | Spec | Stories | Brief | Status |
| --- | --- | :-: | :-: | :-: | --- |
| [F6.1](phoenix/f6.1.md) | Bootstrap the Phoenix Portal | ✓ | ✓ | ✓ | **specced** |
| [F6.2](phoenix/f6.2.md) | Routing & the access surface | ✓ | ✓ | ✓ | **specced** |
| [F6.3](phoenix/f6.3.md) | Persistence with Ecto | ✓ | ✓ | ✓ | **specced** |
| [F6.4](phoenix/f6.4.md) | Contexts & domain on the web | ✓ | ✓ | ✓ | **specced** |
| [F6.5](phoenix/f6.5.md) | Views with HEEx | ✓ | ✓ | ✓ | **specced** |
| [F6.6](phoenix/f6.6.md) | LiveView | ✓ | ✓ | ✓ | **specced** |
| [F6.7](phoenix/f6.7.md) | Real-time (PubSub & Presence) | ✓ | ✓ | ✓ | **specced** |
| F6.8 | Auth & deployment | — | — | — | **planned** |
| F6.9 | The live dashboard (capstone) | — | — | — | **planned** |

## F0 · The Design System — deliverable status

The spec documents the system the static `/elixir` pages already render in; its tooling (D6–D8) is built in
`apps/jonnify-cms`. The Portal HEEx reproduction is the migration tracked in [`design/f0.roadmap.md`](design/f0.roadmap.md).

| Deliverable | What | Spec | Tooled (jonnify-cms) | Status |
| --- | --- | :-: | :-: | --- |
| F0-D1 | The token palette + four font stacks | ✓ | — | **specced** |
| F0-D2 | The shared head (`_head.html` / `HEAD_CSS`) | ✓ | ✓ | **specced** |
| F0-D3 | The document envelope (byte contract) | ✓ | ✓ | **specced** |
| F0-D4 | Page anatomy + container vocabulary | ✓ | — | **specced** |
| F0-D5 | The progressive-enhancement bootstrap | ✓ | ✓ | **specced** |
| F0-D6 | The branded Snowflake build stamp | ✓ | ✓ `internal/snowflake` | **specced** |
| F0-D7 | The nine Apollo gates | ✓ | ✓ `internal/apollo` | **specced** |
| F0-D8 | `jonnify-cms` build + gate + content store | ✓ | ✓ store + byte-parity (204/204) | **shipped** |

## F10 · The bot — abstract status

[`bot/f10.roadmap.md`](bot/f10.roadmap.md) carries the F10.1–F10.9 feature abstracts (a supervised ex_gram bot, the
chat→learner identity seam, the `/enroll · /courses · /lesson · /progress` loop, a webhook fronted by F6.1, and a
scale-out seam into F7–F9). Near-term: F10.1–F10.5. No abstract has graduated to a triad and nothing is built; a `bot/bot.md`
index lands when the abstracts become triads.

## Program milestones

| Milestone | Chapters | Outcome | Status |
| --- | --- | --- | --- |
| **M1** · The engine | F5 | a correct, recoverable, testable engine behind the facade | **done** — F5.1–F5.9 shipped (`b099eee` + the F5.9 commit); the assembled, supervised, replay-recoverable engine behind the `Portal` facade, ratified at 150/150 green |
| **M2** · The web platform | F6 | browse · enroll · live · authed · deployed | **specced** — catalog (F6.1–F6.5) → live (F6.6–F6.7) → users (F6.8–F6.9) |
| **M3** · The bot | F10 | the learner loop from Telegram | **roadmapped** — near-term F10.1–F10.5 |
| **M4** · Multi-runtime | F7–F9 | scale surfaces out over an EchoMQ bus | **open** — defined when a real need arrives |

M2 and M3 are parallel surfaces over M1's facade (frozen since F5.8, `b099eee`); either can lead. F0 underpins M2's
rendering and is migration-tracked independently. The sequencing rule is dependency-down, then product priority — now
F5.9 has shipped and M1 is done, the next rung is F6.1 (the Phoenix bootstrap over the engine).

---

## Upcoming next sprint — Claude session · X-Mode rigorous execution

**Increment: [F6.1](phoenix/f6.1.md) · bootstrap the Phoenix Portal.** The first F6 rung now that the F5 ladder is
closed: stand the headless F5 engine up as a Phoenix web application — `PortalWeb.Endpoint` joins the existing
supervision tree, a `:browser`-pipelined route reaches a thin `PortalWeb.CourseController` that calls only
`Portal.courses_of/1` and renders a HEEx view, and a liveness route proves the service is up — **with nothing below
the `Portal` facade changed** (the F5.9 handoff invariant, F5.9-INV5). This is where Phoenix (and, at F6.3, Ecto)
first enter the dependency tree, as a new `apps/portal_web` app above the boundary.

**Why X-Mode, and why rigorous.** This Portal API has previously been redefined by fan-out authoring — wrong arity,
arg-order, or return types that the gates pass anyway — and the F5.8/F5.9 triads drifted from the as-built core in
lockstep until a fourteen-delta reconciliation. The standing instruction is therefore a ground-facts brief, a
do-not-invent rule, and an adversarial verify pass. That is a Flat-L2 X-Mode session: a Director who does not
implement, a single coherent implementor, and an independent skeptic who tries to refute the result before it is
accepted.

**Where.** The Elixir umbrella `echo/` (asdf 1.18.4 / OTP 28). Build and verify with `cd echo && TMPDIR=/tmp mix test`
(this is the Elixir engine, not the Go `jonnify` server — no `GOWORK`); ratify any Store- or process-touching change
with the multi-run determinism loop under a PORT override, never a single run. Touch **nothing below the `Portal`
facade** — the entire F5 ladder froze it; F6.1 adds only `PortalWeb.Endpoint` and the `PortalWeb` web layer above it.

**Topology (Flat-L2, all Opus).**

| Role | Does | Closes on |
| --- | --- | --- |
| **Director** | locks scope from `f6.1.md`; hands down the ground-facts surface (the closed F5 facade); coordinates; ratifies one commit | the DoD below holds and the evaluator confirms no invented API and no boundary breach |
| **Venus** (architect) | pins the contract: the `PortalWeb.Endpoint` plug stack + the one supervision-tree change (resolving the Store-omission below), the `:browser` pipeline, the controller-over-facade call graph, the closed-error render path | a written contract the implementor cannot drift from |
| **Mars** (implementor) | implements `apps/portal_web`: the endpoint, the router + `:browser` pipeline, `CourseController.index/2`, `CourseHTML` + the HEEx, the liveness route, the one `Portal.Application` line | `mix test` green, no boundary breach |
| **Apollo** (evaluator) | adversarially verifies: `PortalWeb` calls only `Portal.courses_of/1` (no `Portal.Engine`, repo, or `GenServer.call` under `lib/portal_web/`); the closed-error render → `422`; the endpoint-restart gate; the tree starts the Store | a refute-first verdict + a re-run of `mix test` |

**Ground-facts brief (hand to the implementor; the no-invent guard).** The closed F5 facade, cited, not recalled —
`Portal.{enroll/2, deliver_lesson/2, progress_of/1, courses_of/1, lesson/1}` returning `:ok | {:ok, data} | {:error,
%Portal.Error{}}`; the closed four-code `%Portal.Error{code, message, field}` union; the assembled four-child tree
`[Portal.Store, Portal.EventStore.adapter(), Portal.Engine, {Bandit, …}]`, `:one_for_one`. **F6.1 adds only
`PortalWeb.Endpoint` (replacing Bandit) and its `CourseController.index/2` calls only `Portal.courses_of/1`.** Rule:
*do not invent; cite the spec line for every public call; name nothing below the facade.*

**Pinned reconciliation (resolve before the tree edit).** `f6.1.md` F6.1-D2's three-child tree omits the
`Portal.Store` that `courses_of/1` reads (recorded in the F5.9 closure retrospective). Venus pins the corrected tree:
`[Portal.Store, Portal.EventStore.adapter(), Portal.Engine, PortalWeb.Endpoint]` — a Bandit → `Endpoint` swap with the
store and engine unmoved and started before the endpoint, `:one_for_one` (F6.1-INV2), `Portal.Store` retained until
F6.3/F6.4 collapses the dual-write.

**Deliverables (from `f6.1.md`).**

- `PortalWeb.Endpoint` (the outermost plug: `Plug.Static`, `RequestId`, `Telemetry`, `Parsers`, `Session`, a
  `"/live"` socket), ending in `PortalWeb.Router`.
- the one `Portal.Application` change — the corrected four-child tree above, `:one_for_one`, endpoint last.
- `PortalWeb.Router` with a `:browser` pipeline and `get "/courses/:user_id", CourseController, :index`.
- `PortalWeb.CourseController.index/2` calling **only** `Portal.courses_of/1`, rendering `:index` on `{:ok, courses}`
  and the closed-error view (`422`) on `{:error, %Portal.Error{}}`.
- `PortalWeb.CourseHTML` + `course_html/index.html.heex`; a liveness route `get "/health", …` → `200 "ok"`.

**Definition of done / gates.**

- [ ] `cd echo && TMPDIR=/tmp mix test` green; the app boots under `Portal.Application` with the Store started.
- [ ] `GET /courses/:user_id` renders a known user's courses (and an empty state for an unknown user); a malformed id
      renders a `422` from the closed error set, never a `500`.
- [ ] `GET /health` returns `200`; killing `PortalWeb.Endpoint` restarts it and a subsequent request succeeds.
- [ ] The boundary holds: `grep -rE "Portal\.Engine|GenServer\.call|Repo" lib/portal_web/` empty.
- [ ] The evaluator confirms zero invented API — every public call traces to a spec line; `PortalWeb` names only the
      facade.
- [ ] One Director commit; the retrospective is appended to `f5.progress.md`/the F6 progress log with any refinements.

**After F6.1:** [F6.2](phoenix/f6.2.md) — routing & the access surface, then [F6.3](phoenix/f6.3.md) — persistence with
Ecto (which fills the `Portal.EventStore.Postgres` body behind its F5.8 signature-only stub and makes the raw infra
`{:error, term}` channel reachable).

---

## Map

- Program plan: [`portal.roadmap.md`](portal.roadmap.md) · spec-system contract: [`specs.approach.md`](specs.approach.md).
- F0 · design system: [`design/f0.md`](design/f0.md) · [`design/f0.roadmap.md`](design/f0.roadmap.md).
- F5 · engine: [`pragmatic/pragmatic.md`](pragmatic/pragmatic.md) · [`pragmatic/pragmatic.roadmap.md`](pragmatic/pragmatic.roadmap.md) · [`pragmatic/f5.progress.md`](pragmatic/f5.progress.md).
- F6 · web: [`phoenix/phoenix.md`](phoenix/phoenix.md) · [`phoenix/phoenix.roadmap.md`](phoenix/phoenix.roadmap.md).
- F10 · bot: [`bot/f10.roadmap.md`](bot/f10.roadmap.md).

---

> Part of the jonnify toolkit. One core, many surfaces, one facade. The roadmaps plan; the specs define and prove; this
> board reports where each stands and what ships next.
