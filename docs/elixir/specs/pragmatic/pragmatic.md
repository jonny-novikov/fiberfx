# F5 · Pragmatic Programming — the Portal engine as a value ladder

> The chapter that builds the Portal engine, re-told as a sequence of value-adding increments. Starting from F4's
> branded CHAMP store, F5 climbs a ladder — a thin running app, a modeled domain, a walking skeleton, contracts,
> commands/queries/events, a supervised state home, tests, boundaries, and the assembled engine — each rung shipping a
> more capable Portal that still runs. Every spec is built story-first and proven by invariants, following
> [the specs approach](../specs.approach.md). F6 then puts a web platform on top without reaching into the core.

This index is the map. Each rung links to its three artifacts: the spec (`f5.N.md`), the user stories
(`f5.N.stories.md`), and the agent brief (`f5.N.llms.md`). The near-term delivery plan for the first five rungs —
shipped to production as Agile iterations — is in [`pragmatic.roadmap.md`](pragmatic.roadmap.md).

## Where F5 starts and ends

**Start (the F4 handoff).** A branded CHAMP store — `Portal.Store` (`get/2`, `all/2`, `put/1`) — a fast, persistent
key/value structure keyed by branded ids, plus the language and OTP. Nothing web, nothing domain yet.

**End (after F5.9).** A supervised, headless Portal **engine** behind a single facade `Portal` — commands
(`enroll/2`, `deliver_lesson/2`), queries (`progress_of/1`, `courses_of/1`) returning `:ok | {:ok, data} | {:error,
%Portal.Error{}}`, with `%Portal.Error{}` a closed set (`:already_enrolled | :course_not_found | :lesson_locked |
:invalid_progress`). The engine is a pure core (`decide`/`evolve`) folded over an event log, kept alive in a
supervised GenServer, persisted through an `EventStore` port — and LiveView-ready for F6.

## The master invariant (seeded here, inherited by F6)

> The domain core is framework-free and depends on nothing above it. The web/UI layer calls only the engine boundary —
> a thin engine stub in F5.1, the `Portal` facade by F5.8 — and never reaches into the core.

F5.1 establishes the seam (a replaceable web layer over a stubbed engine boundary); F5.8 completes it (the `Portal`
facade + the closed `%Portal.Error{}` set); F6 inherits it unchanged. This is what lets F6 add Phoenix without
touching anything below the facade.

## The value ladder

| Spec | Increment | Value it adds | Primary roles | Status |
| --- | --- | --- | --- | --- |
| [F5.1](f5.1.md) | Start thin: a running Portal | a supervised app answering real HTTP from day one, behind a replaceable web layer; branded Snowflake ids | Operator, Developer, Architect | **specced** |
| [F5.2](f5.2.md) | Model the Portal domain | the domain as structs in bounded contexts (Accounts/Catalog/Learning) with small public APIs | Developer, Architect, Learner | **specced** |
| [F5.3](f5.3.md) | Tracer bullets: a walking skeleton | one use case (enroll) wired end to end through every layer; the architecture proven runnable | Developer, Operator | **specced** |
| [F5.4](f5.4.md) | The enroll contract | the enroll command parsed at the boundary into a typed result; postcondition and invariant pinned by property tests | Developer, Learner | **specced** |
| [F5.5](f5.5.md) | Commands, queries & events | writes/reads separated; changes recorded as events; the engine collapses to `decide`/`evolve` over a log | Developer, Architect | **specced** |
| [F5.6](f5.6.md) | Where engine state lives | the folded state kept alive in a supervised GenServer; crash recovery by replay | Operator, Developer | **specced** |
| F5.7 | Pragmatic testing | the pure core pinned by example, property, and contract tests; a fast, deterministic suite | Developer | planned |
| F5.8 | Boundaries & integration seams | the `EventStore` port + adapters, the `Portal` facade, and the closed `%Portal.Error{}` contract | Architect, Developer | planned |
| F5.9 | The engine, LiveView-ready (lab) | the whole engine assembled and supervised, a LiveView mount sketch, the F6 handoff | Developer, Operator | planned |

The rungs depend only downward: F5.3 wires the F5.2 domain end to end; F5.4 hardens that use case; F5.5 reframes it as
events; F5.6 gives the fold a home; F5.7 pins it; F5.8 draws its edges; F5.9 assembles all of it.

## How to read a rung

Read the spec (`f5.N.md`) first — Goal, Rationale (5W), Scope, Deliverables, Invariants, Definition of Done. Then the
user stories (`f5.N.stories.md`) for the acceptance criteria. Then the agent brief (`f5.N.llms.md`) when you are ready
to implement: its references, requirements, execution topology, and the comprehensive prompt an agent runs to build
and self-check the increment.

This index pairs with the teaching guide [`build-guide/pragmatic.md`](../../build-guide/pragmatic.md): the guide
explains the pragmatic-programming concepts module by module; these specs frame the same work as value increments with
stories and proof gates. The build-guide modules `f5-01`…`f5-09` are the conceptual companions to specs `F5.1`…`F5.9`.
The web chapter that builds on this engine is [`../phoenix/phoenix.md`](../phoenix/phoenix.md).

## Conventions

- **Stack.** Elixir (OTP) · a thin `Bandit` + `Plug` web layer in F5.1 (replaced by Phoenix in F6) · the F4 branded
  CHAMP store (`Portal.Store`) · `Jason` for JSON. Pure functions in the core; side effects at the edges (functional
  core, imperative shell).
- **Control flow.** Railway-oriented: `with` + tagged tuples for sequential steps; parse untrusted input at the
  boundary; exceptions only for truly exceptional faults. See the matrix in [the specs approach](../specs.approach.md).
- **Identifiers.** Every entity is identified by a Snowflake — a 64-bit, time-ordered integer (the canonical id) —
  whose transport form is a branded id: a three-letter namespace prefix plus the Base62-encoded snowflake (e.g.
  `ENR0KHTOWnGLuC`, epoch `1704067200000`). `Portal.ID.new/1` mints and `Portal.ID.snowflake/1` decodes.
- **Proof.** Each spec's Invariants and acceptance criteria are the gates; a rung is done only under the completion
  rule in [the specs approach](../specs.approach.md).

---

> Part of the jonnify toolkit. Branded id format: `TSK` + Base62(snowflake), e.g. `TSK0KHTOWnGLuC`.
