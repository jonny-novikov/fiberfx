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

## The value ladder

| Spec | Feature | Value it adds | Primary roles | Status |
| --- | --- | --- | --- | --- |
| [F6.1](f6.1.md) | Bootstrap the Phoenix Portal | the engine is served as a real web app; a request reaches the facade and renders | Operator, Visitor, Developer | **specced** |
| [F6.2](f6.2.md) | Routing & the access surface | a navigable, protectable surface: read/write/REST/live routes, pipelines, plugs | Visitor, Learner, Developer, Operator | **specced** |
| F6.3 | Persistence with Ecto | durable catalog & enrollments via a Postgres adapter behind the F5 port | Operator, Developer, Learner | planned |
| F6.4 | Contexts & domain on the web | the web reads and writes real domain through the facade and bounded contexts | Developer, Learner | planned |
| F6.5 | Views with HEEx | a rendered UI: templates, function components, forms with inline errors | Visitor, Learner | planned |
| F6.6 | LiveView | interactive pages — live search and live create — without full reloads | Learner | planned |
| F6.7 | Real-time (PubSub & Presence) | multi-client live updates and a live viewer count | Learner, Instructor | planned |
| F6.8 | Auth & deployment | real users, protected areas, and a deployed, clustered release | Learner, Operator | planned |
| F6.9 | The live dashboard (capstone) | an operations/learning dashboard folding live events, under auth, clustered | Instructor, Operator | planned |

The rungs depend only downward: F6.2 assumes F6.1's endpoint and pipeline; F6.5 renders what F6.3/F6.4 make
queryable; F6.6 makes F6.5's pages live; F6.7 pushes F6.6's state across clients; F6.9 composes all of it.

## How to read a rung

Read the spec (`f6.N.md`) first — Goal, Rationale (5W), Scope, Deliverables, Invariants, Definition of Done. Then the
user stories (`f6.N.stories.md`) for the acceptance criteria. Then the agent brief (`f6.N.llms.md`) when you are ready
to implement: its references, requirements, execution topology, and the comprehensive prompt that an agent runs to
build and self-check the increment.

This index pairs with the teaching guide [`build-guide/phoenix.md`](../../build-guide/phoenix.md): the guide explains
the framework concepts module by module; these specs frame the same work as value increments with stories and proof
gates. The build-guide modules `f6-01`…`f6-09` are the conceptual companions to specs `F6.1`…`F6.9`.

## Conventions

- **Stack.** Elixir (OTP) · Phoenix (endpoint, router, controllers, LiveView) · Ecto as one adapter behind the
  engine's port (F6.3) · the F4 branded CHAMP store · `Jason` for JSON. Side effects stay at the edges.
- **Identifiers.** Every entity is identified by a Snowflake — a 64-bit, time-ordered integer — whose transport form
  is a branded id: a three-letter namespace prefix plus the Base62-encoded snowflake (e.g. `ENR0KHTOWnGLuC`).
  `Portal.ID.new/1` mints and `Portal.ID.snowflake/1` decodes, exactly as in F5.
- **Proof.** Each spec's Invariants and acceptance criteria are the gates; a rung is done only under the completion
  rule in [the specs approach](../specs.approach.md).

---

> Part of the jonnify toolkit. Branded id format: `TSK` + Base62(snowflake), e.g. `TSK0KHTOWnGLuC`.
