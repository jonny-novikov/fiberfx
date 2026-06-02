# F5 · Roadmap — the Portal engine (Pragmatic Programming)

> A delivery plan for the engine chapter: climb F5.1–F5.9 to turn the F4 branded CHAMP store into a supervised,
> headless Portal engine behind one facade `Portal`, one shippable increment per rung, the core framework-free and
> ready for F6. This file is the delivery view; the value ladder and the per-rung increments live in the chapter index
> [`pragmatic.md`](pragmatic.md), and each rung's detail is in its triad (`f5.N.md` / `.stories.md` / `.llms.md`).

## What we are delivering

The Portal engine, built as thin vertical slices: a running supervised app that answers real HTTP from day one, then a
modeled domain, a walking skeleton that wires one use case through every layer, the enroll contract, commands/queries
recorded as events, a supervised home for the folded state, a test suite weighted to the pure core, explicit
boundaries with a closed error contract, and the whole engine assembled behind a single facade. Every rung is a
vertical slice that ships value and leaves the engine runnable, and the domain core stays framework-free — it depends
on nothing above it, so F6 can put Phoenix on top without reaching below the facade.

The near-term goal is the first five rungs shipped to production as Agile iterations (F5.1–F5.5): a supervised app, a
modeled domain, a walking skeleton, the contract that hardens it, and the `decide`/`evolve` core that reframes it as
events. The runtime home, the test pyramid, the boundaries, and the assembled lab (F5.6–F5.9) follow once the first
arc is reviewed.

## Where this starts and ends

- **Start (the F4 handoff).** A branded CHAMP store — `Portal.Store` (`get/2`, `all/2`, `put/1`), a fast, persistent
  key/value structure keyed by branded ids — plus the language and OTP. Nothing web, nothing domain yet. See
  [`pragmatic.md`](pragmatic.md).
- **End (after F5.9).** A supervised, headless Portal engine behind a single facade `Portal` — commands (`enroll/2`,
  `deliver_lesson/2`), queries (`progress_of/1`, `courses_of/1`) returning `:ok | {:ok, data} | {:error,
  %Portal.Error{}}`, with `%Portal.Error{}` a closed set (`:already_enrolled | :course_not_found | :lesson_locked |
  :invalid_progress`). The engine is a pure core (`decide`/`evolve`) folded over an event log, kept alive in a
  supervised GenServer, persisted through an `EventStore` port — LiveView-ready for F6. See
  [`f5.9.md`](f5.9.md), then the F6 chapter [`../phoenix/phoenix.md`](../phoenix/phoenix.md).

## Architecture decision — functional core, imperative shell over an event log

The engine is a functional core wrapped in an imperative shell, and the core is the Decider: `decide` turns a command
into events, `evolve` folds one event into state, and the current state is the fold of the whole log. The reasoning
matches the in-BEAM choice the bot makes ([`../bot/f10.roadmap.md`](../bot/f10.roadmap.md)): pure functions of their
arguments carry the business rules — no I/O, no clock, no process — while side effects (HTTP, the clock, persistence,
holding state) live at the edges, so the part that holds the value is the part that is simplest to test exhaustively.
Recording every change as a past-tense event makes behaviour auditable and reconstructible: state stops being a thing
that is mutated and becomes the replay of a history, which is what turns crash recovery into a fold rather than a
restore. The pattern, its benefits, its killers, the alternatives, and a decision matrix are set out in
[`decider-pattern.md`](decider-pattern.md).

The cost — that a single supervised GenServer serialises commands and queries over one folded state, a throughput
ceiling — is a fit for the BEAM, not a strain on it, and the trade stays reversible: the read model is the held fold
today, and the `EventStore` port (F5.8) lets storage swap from in-memory to Postgres by config without touching the
core. None of that is needed for the engine this roadmap delivers; it is the seam that keeps the choice open.

## The master invariant (seeded here, inherited by F6)

> The domain core is framework-free and depends on nothing above it. The web/UI layer calls only the engine boundary —
> a thin engine stub in F5.1, the `Portal` facade by F5.8 — and never reaches into the core.

F5.1 establishes the seam (a replaceable web layer over a stubbed engine boundary); F5.8 completes it (the `Portal`
facade plus the closed `%Portal.Error{}` set); F6 inherits it unchanged. This single rule is what lets the ladder stay
cheap: every rung adds capability without reaching below the boundary, so nothing under F5.8 changes when F6 adds
Phoenix.

## How this roadmap runs

Two roles, one loop:

- **Author (Claude)** turns each rung into a spec triad and a build plan at the F5 quality bar — Goal, Rationale (5W),
  Scope, Deliverables, Invariants, Definition of Done; user stories; an agent brief with a paste-ready prompt.
- **Operator (the person in this conversation)** reviews the delivered specs and the shipped increment, then returns
  feedback asking for the next rung's specs or a change to a shipped one.

The loop per rung is **sharpen → build → ship → demo → review → feedback → adapt**. Feedback edits the spec, because
the spec is the single source of truth; the build follows the spec, never the other way around. "Adopt / learn /
evolve / move forward" names this feature-development process, not end-user telemetry. The build order is value-first —
each rung is independently demoable — following tracer bullets and walking-skeleton delivery (Pragmatic Programmer),
small releases (XP), and the Lean MVP, as sourced in [the specs approach](../specs.approach.md).

## "Thin but robust" for the engine

Each rung is a narrow vertical slice — one slice through the layers — built to production quality, not a prototype.
Concretely:

- **Supervised.** Every rung runs under OTP with the failure path designed, not hoped for: a crashed child restarts
  `:one_for_one` (F5.1), and from F5.6 the engine recovers its state by replaying the log (F5.6, F5.9).
- **Contract-guarded.** Untrusted input is parsed at the boundary into a well-formed command or a typed `{:error,
  reason}` from the closed set (the F5.4 contract), so bad or duplicate input is rejected before it reaches the core,
  and a rejected command leaves the store unchanged.
- **Harnessed.** A suite weighted to the pure core: ExUnit example tests on `decide`/`evolve`/`replay`, `StreamData`
  properties for the invariants (identity round-trips, `replay == fold`, `0 ≤ progress ≤ 100`), contract tests for the
  closed error set, doctests that keep the documentation true, and exactly one process smoke test at the tip (F5.7).
  From F5.6 the harness adds a crash-recovery test and a single command→query process test.
- **Pure at the centre.** `decide`, `evolve`, and `replay` are pure and deterministic; side effects stay at the edges,
  so the layers that hold the value need no process and no mocks to test.
- **Over the boundary.** The web names only the engine boundary and renders only tagged results; by F5.8 the closed
  `%Portal.Error{}` set crosses the seam, and a no-catch-all `from/1` forces a new failure mode to be named rather than
  leak untyped.

Every rung ships behind the same Definition-of-Done gates, and the table below names the demo and the harness for each.

## The near-term plan — first five rungs as iterations

F5.1–F5.5 are the production-bound iterations — thin in scope, robust in code, fully harnessed. They go out as Agile
iterations: each rung is sharpened to a crisp spec, built to its Definition of Done, shipped, demoed on its observable,
and reviewed before the next begins. F5.6–F5.9 are specced and queued, planned after the first arc earns feedback.

| It. | Rung | Ships to production | Demo (observable) | Harness & robustness | Feedback asked |
| --- | --- | --- | --- | --- | --- |
| 1 | [F5.1](f5.1.md) · Start thin | a supervised app serving HTTP on `:4000`; branded Snowflake ids | boot; `curl` enroll → `422`, unknown path → `404`; kill the engine → it restarts | `:one_for_one` supervision; `Portal.ID` round-trip tests; F5.1 DoD gates | the web/engine seam; id format and namespaces; the supervision posture |
| 2 | [F5.2](f5.2.md) · Model the domain | the Accounts/Catalog/Learning contexts and entities; enroll builds an enrollment | `iex` → `Learning.enroll(Portal.ID.new("USR"), Portal.ID.new("CRS"))` → `{:ok, %Enrollment{progress: 0}}`, retrievable | enforced-keys tests; `@type t`/`@spec` (Dialyzer-checkable); context-ownership check | the domain model and fields; context boundaries; the public API surface |
| 3 | [F5.3](f5.3.md) · Tracer bullets | enroll round-trips end to end over HTTP and persists; a deliver-lesson read slice | `curl` enroll → `201` + id, retrievable; `GET /lessons/:id` → `200`/`404` | an end-to-end test with no mocks; deterministic result→status mapping | the first real feature's behaviour; the JSON envelope; which slice next |
| 4 | [F5.4](f5.4.md) · The enroll contract | bad/duplicate enroll rejected at the door with nothing written | `curl` bad/duplicate → `422 :course_not_found`/`:already_enrolled`, store unchanged; valid → `201` | `StreamData` properties (postcondition, `0..100`); examples per error; fail-fast (no partial writes) | the closed error vocabulary (reasons and statuses); the contract's strictness |
| 5 | [F5.5](f5.5.md) · Commands, queries & events | enroll/deliver recorded as events; the engine collapses to `decide`/`evolve` over a log; state rebuildable by `replay` | `decide` → events + `:ok`; a query → data; `replay(log)` reconstructs state | pure-core example tests; a `replay == fold` property; CQS enforced | the event model and tuples; whether CQS is right before the state home (F5.6) |

Each row is one iteration: sharpen the spec, build it robustly and harnessed, ship, demo on the observable shown,
review, and fold the Operator's feedback into the spec before the next.

## The build order through F5.9

The rungs depend only downward, so the build order is the ladder itself. After the near-term arc:

- **F5.6 · Where engine state lives** — the F5.5 pure core gets a runtime home: `Portal.Engine`, a supervised
  GenServer whose `init/1` replays the log once into the held state, a command call that runs `decide` then `evolve`,
  a query call that only reads — recovering by replay on a crash.
- **F5.7 · Pragmatic testing** — the suite is shaped like the engine: a wide base of example and property tests on the
  pure core, the F5.4 contract turned into assertions, doctests that keep the docs true, and exactly one process test
  at the tip; `mix test` stays fast and deterministic.
- **F5.8 · Boundaries & integration seams** — the edges are drawn as explicit ports: the driven `Portal.EventStore`
  behaviour with interchangeable `InMemory` and `Postgres` adapters chosen by config, the driving `Portal` facade as
  the only web surface, and the closed `Portal.Error` contract produced by a no-catch-all `from/1`. This is the F5→F6
  contract.
- **F5.9 · The engine, LiveView-ready (lab)** — the parts are assembled into one running system: the supervision tree
  (store, then engine, `:one_for_one`), the append-before-evolve command path, the facade over the engine wrappers,
  the error contract end to end, and a LiveView mount sketch that touches only the facade — then the F6 handoff, whose
  one structural change is adding `PortalWeb.Endpoint` to the same tree.

The handoff is the engine itself: a supervised application behind the `Portal` facade and the closed `%Portal.Error{}`
set, which F6 consumes unchanged ([`../phoenix/phoenix.roadmap.md`](../phoenix/phoenix.roadmap.md)) and the F10 bot
consumes as a second driving adapter ([`../bot/f10.roadmap.md`](../bot/f10.roadmap.md)).

## Status

Per the chapter index [`pragmatic.md`](pragmatic.md), all nine rungs F5.1–F5.9 are **specced** (each has a complete
spec triad). No rung is marked shipped here; "ships to production" above is the planned posture of each iteration, the
delivery target the rung is built and reviewed against, not a completion claim. The first arc (F5.1–F5.5) is the
production-bound near-term plan; F5.6–F5.9 are specced and queued so the next iteration can start without delay.

## Conventions

- The master invariant holds at every rung: the web calls only the engine boundary — the F5.1 stub, the F5.8 facade —
  and the domain core names nothing above it.
- Railway-oriented control flow: `with` plus tagged tuples for sequential steps; untrusted input parsed at the
  boundary; exceptions only for truly exceptional faults. See the matrix in [the specs approach](../specs.approach.md).
- Branded Snowflake ids for every identifier: a 64-bit time-ordered integer (canonical) whose transport form is a
  three-letter namespace prefix plus the Base62 encoding; `Portal.ID.new/1` mints and `Portal.ID.snowflake/1` decodes.
- A+ quality gates and Writerside-friendly markdown throughout: prose over heavy formatting, clean voice, balanced
  fences, resolving links.

---

Chapter index & value ladder: [`pragmatic.md`](pragmatic.md). Pattern: [`decider-pattern.md`](decider-pattern.md).
Rungs: [`f5.1.md`](f5.1.md) · [`f5.2.md`](f5.2.md) · [`f5.3.md`](f5.3.md) · [`f5.4.md`](f5.4.md) ·
[`f5.5.md`](f5.5.md) · [`f5.6.md`](f5.6.md) · [`f5.7.md`](f5.7.md) · [`f5.8.md`](f5.8.md) · [`f5.9.md`](f5.9.md).
Sibling roadmaps: [`../phoenix/phoenix.roadmap.md`](../phoenix/phoenix.roadmap.md) ·
[`../bot/f10.roadmap.md`](../bot/f10.roadmap.md). Next chapter (F6): [`../phoenix/phoenix.md`](../phoenix/phoenix.md).
Approach: [`../specs.approach.md`](../specs.approach.md).

> Part of the jonnify toolkit. Branded id format: `TSK` + Base62(snowflake), e.g. `TSK0KHTOWnGLuC`.
