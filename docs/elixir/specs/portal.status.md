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
| **F5** · [The engine](pragmatic/pragmatic.md) | headless core | — | ✓ F5.1–F5.9 | F5.1–F5.3 shipped ✓ · F5.4 next | **building** (M1) |
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
F5 :  F5.1 ▸ F5.2 ▸ F5.3 ▸ [F5.4] ▸ F5.5 ▸ F5.6 ▸ F5.7 ▸ F5.8 ▸ F5.9
      └ shipped ──────┘   ↑next   └────────── specced ───────────┘
F6 :  F6.1 ▸ F6.2 ▸ F6.3 ▸ F6.4 ▸ F6.5 ▸ F6.6 ▸ F6.7 ▸ (F6.8 ▸ F6.9 planned)
F0 :  D1 ▸ D2 ▸ D3 ▸ D4 ▸ D5 ▸ D6 ▸ D7 ▸ D8     (D6–D8 already tooled in jonnify-cms)
F10:  F10.1 ▸ … ▸ F10.5 (near-term) ▸ … ▸ F10.9 (scale-out seam)   — abstracts
```

## F5 · The engine — rung status (the active chapter)

Implemented in `echo/apps/portal`; `mix test` green (13 `portal` + 2 `echo_data` example tests, no mocks); a live node
returns `201 / 200 / 404 / 200 / 404` on `:4000`; the supervision-kill gate and the `lib/portal_web/` boundary-purity
grep pass. See the retrospective in [`pragmatic/f5.progress.md`](pragmatic/f5.progress.md).

| Rung | Increment | Spec | Stories | Brief | Impl | Status |
| --- | --- | :-: | :-: | :-: | :-: | --- |
| [F5.1](pragmatic/f5.1.md) | Start thin: a running Portal | ✓ | ✓ | ✓ | ✓ | **shipped** |
| [F5.2](pragmatic/f5.2.md) | Model the Portal domain | ✓ | ✓ | ✓ | ✓ | **shipped** |
| [F5.3](pragmatic/f5.3.md) | Tracer bullets: a walking skeleton | ✓ | ✓ | ✓ | ✓ | **shipped** |
| [F5.4](pragmatic/f5.4.md) | The enroll contract | ✓ ◐refined | ✓ | ✓ | — | **next** ◀ |
| [F5.5](pragmatic/f5.5.md) | Commands, queries & events | ✓ | ✓ | ✓ | — | **specced** |
| [F5.6](pragmatic/f5.6.md) | Where engine state lives | ✓ | ✓ | ✓ | — | **specced** |
| [F5.7](pragmatic/f5.7.md) | Pragmatic testing | ✓ | ✓ | ✓ | — | **specced** |
| [F5.8](pragmatic/f5.8.md) | Boundaries & integration seams | ✓ | ✓ | ✓ | — | **specced** |
| [F5.9](pragmatic/f5.9.md) | The engine, LiveView-ready (lab) | ✓ | ✓ | ✓ | — | **specced** |

**Carried-forward stubs** (from F5.1–F5.3, to close downstream): `Portal.Store` is an in-memory stand-in (real branded
CHAMP at F4 / F5.8); `Portal.Engine` is a `GenServer.call` boundary, not event-sourced yet (F5.5 `decide`/`evolve`,
F5.6 supervised replay); no durable `EventStore` (F5.8); no `%Portal.Error{}` struct yet (**introduced at F5.4**).

## F6 · The web — rung status

None implemented; `apps/portal_web` is added when F6.1 starts. F6.1–F6.7 carry full triads; F6.8–F6.9 are named but
unwritten. (Housekeeping per the program roadmap: confirm F6.2/F6.3 are uniform in the triad format.)

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
| **M1** · The engine | F5 | a correct, recoverable, testable engine behind the facade | **in progress** — F5.1–F5.3 shipped, F5.4 next; near-term F5.1–F5.5 |
| **M2** · The web platform | F6 | browse · enroll · live · authed · deployed | **specced** — catalog (F6.1–F6.5) → live (F6.6–F6.7) → users (F6.8–F6.9) |
| **M3** · The bot | F10 | the learner loop from Telegram | **roadmapped** — near-term F10.1–F10.5 |
| **M4** · Multi-runtime | F7–F9 | scale surfaces out over an EchoMQ bus | **open** — defined when a real need arrives |

M2 and M3 are parallel surfaces over M1's facade; either can lead. F0 underpins M2's rendering and is migration-tracked
independently. The sequencing rule is dependency-down, then product priority.

---

## Upcoming next sprint — Claude session · X-Mode rigorous execution

**Increment: [F5.4](pragmatic/f5.4.md) · the enroll contract.** The first rung whose spec was sharpened by a build
retrospective (see the refinement table in [`pragmatic/f5.progress.md`](pragmatic/f5.progress.md)). It turns the F5.3
happy-path `enroll` slice into a contracted command: preconditions parsed at the boundary, a closed error vocabulary,
and the postcondition + progress invariant pinned by property tests.

**Why X-Mode, and why rigorous.** This Portal API has previously been redefined by fan-out authoring — wrong arity,
arg-order, or return types that the gates pass anyway. The progress log's standing instruction is therefore a
ground-facts brief, a do-not-invent rule, and an adversarial verify pass. That is a Flat-L2 X-Mode session: a Director
who does not implement, a single coherent implementor, and an independent skeptic who tries to refute the result before
it is accepted.

**Where.** The Elixir umbrella `echo/apps/portal` (asdf 1.18.4 / OTP 28). Build and verify with `cd echo && mix test`
(this is the Elixir engine, not the Go `jonnify` server — no `GOWORK`). Touch nothing under the `Portal` boundary that
F5.1–F5.3 froze.

**Topology (Flat-L2, all Opus).**

| Role | Does | Closes on |
| --- | --- | --- |
| **Director** | locks scope from `f5.4.md` (refined); hands down the ground-facts surface; coordinates; ratifies one commit | the DoD below holds and Apollo confirms no invented API |
| **Venus** (architect) | pins the contract: the `with` precondition chain, the `%Portal.Error{code, message}` struct + closed code set, fail-fast order, the property the tests must hold | a written contract Mars cannot drift from |
| **Mars** (implementor) | implements in `apps/portal`: preconditions, the error struct, the router 422 mapping, the `StreamData` properties | `mix test` green, no boundary breach |
| **Apollo** (evaluator) | adversarially verifies: each public call cites the spec (no invention); `valid?/1` is the guard (not `namespace/1`); 422 mapping; the supervision + boundary-purity gates still pass | a refute-first verdict + a re-run of `mix test` |

**Ground-facts brief (hand to Mars; the no-invent guard).** The real surface, cited, not recalled:
`Portal.ID.{new, valid?, namespace, snowflake, at}/1` (a branded id is 14 chars: 3-letter namespace + 11-char Base62 —
`"USR1"` is **not** valid; the precondition uses `valid?/1`, never `namespace/1`); the `Portal.Engine` boundary
`dispatch/1` + `query/2`; `Portal.Store.{get/2, all/2, put/1}`; the seven Accounts / Catalog / Learning entity shapes.
Rule: *do not invent; cite the spec line for every public call.*

**Deliverables (from `f5.4.md`, refined).**

- The enroll precondition `with` chain: `valid?/1` on the ids → course exists → not already enrolled, fail-fast ordered.
- The closed `%Portal.Error{code, message}` struct, codes `:course_not_found | :already_enrolled` (F5.8 later *extends*
  this set + threads the facade — it does not introduce it).
- The router maps every error `code` to `422`, through the single `status_for` clause set (add clauses, do not rewrite).
- `StreamData` property tests: the enroll postcondition, and the `0..100` progress invariant.

**Definition of done / gates.**

- [ ] `cd echo && mix test` green, including the new `StreamData` properties (no mocks).
- [ ] Every `%Portal.Error{}` code renders `422`; an unknown/duplicate enroll yields the typed error, never a crash.
- [ ] The boundary holds: `grep -rE "Portal\.Engine|GenServer\.call" lib/portal_web/` empty; supervision-kill gate green.
- [ ] Apollo confirms zero invented API — every public call traces to a spec line; `valid?/1` is the precondition guard.
- [ ] One Director commit; the retrospective is appended to `f5.progress.md` (Iteration 2) with any spec refinements.

**After F5.4:** [F5.5](pragmatic/f5.5.md) — commands, queries & events: the engine collapses to `decide`/`evolve` over
an event log (the [decider pattern](pragmatic/decider-pattern.md)), then F5.6 gives the fold a supervised home.

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
