# Functional Programming in Elixir — content-tree index (`llms.md`)

> A per-route markdown **source-of-record** for the `/elixir` course: one `.md` per live page (204 pages across
> six numbered chapters plus an optional history chapter), each documenting its page anatomy — route, file,
> verbatim hero lede, the module/dive map, every interactive figure, references, and the wiring — and ending with
> a build instruction. This file is the machine-readable map of that tree for an agent reading, navigating, or
> regenerating it; links point at the `.md` files, each tagged with its served `/elixir/...` route.

The live course is hand-authored static HTML served at `/elixir` by the jonnify Fiber server (folder-routed via
`serveDirTree`; the URL tree mirrors `elixir/`). Every page is built and graded A+ on the nine Apollo gates. This
tree (`docs/elixir/content/`) is its documentation analogue, modelled on `docs/agile-agent-workflow/content/` and
the `phoenix/index.md` decomposition reference. Reading the layout below: a **chapter landing** is the `###`
heading; top-level bullets are modules and front-matter pages; indented bullets are a module's deep-dive subpages.

- Course home · [index.md](index.md) — `/elixir` — the contents / route manifest: six chapters + optional history, 54+ modules.

## The content tree — chapters · modules · dives

### F0 · History — where this came from — [/elixir/course](course/index.md)
The two histories behind the language: functional languages & runtimes, and Erlang/BEAM/OTP, plus a C# onramp. Accent blue.

- [F0 onramp — Elixir for C# developers](course/csharp.md) — `/elixir/course/csharp`
- [F0.1 — The evolution of functional languages & runtimes](course/fp-evolution.md) — `/elixir/course/fp-evolution`
- [F0.2 — The evolution of Erlang, the BEAM & OTP](course/beam-evolution.md) — `/elixir/course/beam-evolution`

### F1 · Algebra — [/elixir/algebra](algebra/index.md)
The maths foundation — functions, substitution, composition, immutability, collections, recursion, higher-order operators, pattern matching, and a plotting lab. Accent gold.

- [F1.01 — What a function really is](algebra/functions.md) — `/elixir/algebra/functions`
- [F1.02 — The substitution model](algebra/substitution.md) — `/elixir/algebra/substitution`
- [F1.03 — Composition, f∘g](algebra/composition.md) — `/elixir/algebra/composition`
- [F1.04 — Immutability & binding](algebra/immutability.md) — `/elixir/algebra/immutability`
- [F1.05 — Sets, sequences & mappings](algebra/collections.md) — `/elixir/algebra/collections`
- [F1.06 — Recursion & induction](algebra/recursion.md) — `/elixir/algebra/recursion`
- [F1.07 — Higher-order operators (Σ, Π)](algebra/higher-order.md) — `/elixir/algebra/higher-order`
- [F1.08 — Equations & pattern matching](algebra/pattern-matching.md) — `/elixir/algebra/pattern-matching`
- [F1.09 — Functions on the plane](algebra/plotting-lab.md) — `/elixir/algebra/plotting-lab`

### F2 · Functional Programming — [/elixir/functional](functional/index.md)
Pure functions to pipelines: purity, persistence, higher-order functions, recursion, folds, closures, ADTs, composition, and a data-pipeline lab. Accent elixir-purple.

- [F2.01 — Pure functions & side effects](functional/pure.md) — `/elixir/functional/pure`
- [F2.02 — Immutability & persistent data](functional/persistence.md) — `/elixir/functional/persistence`
- [F2.03 — Higher-order functions](functional/higher-order.md) — `/elixir/functional/higher-order`
- [F2.04 — Recursion patterns & tail calls](functional/recursion/index.md) — `/elixir/functional/recursion`
  - [F2.04.1 — The shape of recursion](functional/recursion/shape.md) — `/elixir/functional/recursion/shape`
  - [F2.04.2 — Tail calls & accumulators](functional/recursion/tail-calls.md) — `/elixir/functional/recursion/tail-calls`
  - [F2.04.3 — Recursion patterns](functional/recursion/patterns.md) — `/elixir/functional/recursion/patterns`
- [F2.05 — map / filter / reduce (folds)](functional/folds/index.md) — `/elixir/functional/folds`
  - [F2.05.1 — map](functional/folds/map.md) — `/elixir/functional/folds/map`
  - [F2.05.2 — filter](functional/folds/filter.md) — `/elixir/functional/folds/filter`
  - [F2.05.3 — reduce](functional/folds/reduce.md) — `/elixir/functional/folds/reduce`
  - [F2.05.4 — Advanced folds](functional/folds/advanced.md) — `/elixir/functional/folds/advanced`
- [F2.06 — Closures & partial application](functional/closures/index.md) — `/elixir/functional/closures`
  - [F2.06.1 — Capturing the environment](functional/closures/environment.md) — `/elixir/functional/closures/environment`
  - [F2.06.2 — The capture operator](functional/closures/capture.md) — `/elixir/functional/closures/capture`
  - [F2.06.3 — Partial application & currying](functional/closures/currying.md) — `/elixir/functional/closures/currying`
- [F2.07 — Algebraic data types](functional/adt/index.md) — `/elixir/functional/adt`
  - [F2.07.1 — Product types](functional/adt/product.md) — `/elixir/functional/adt/product`
  - [F2.07.2 — Sum types](functional/adt/sum.md) — `/elixir/functional/adt/sum`
  - [F2.07.3 — Pattern matching on data](functional/adt/matching.md) — `/elixir/functional/adt/matching`
- [F2.08 — Composition & pipelines](functional/composition/index.md) — `/elixir/functional/composition`
  - [F2.08.1 — Function composition](functional/composition/compose.md) — `/elixir/functional/composition/compose`
  - [F2.08.2 — The pipe operator](functional/composition/pipe.md) — `/elixir/functional/composition/pipe`
  - [F2.08.3 — Building pipelines](functional/composition/pipeline.md) — `/elixir/functional/composition/pipeline`
- [F2.09 — The data-pipeline lab](functional/pipeline-lab/index.md) — `/elixir/functional/pipeline-lab`

### F3 · The Elixir Language — [/elixir/language](language/index.md)
The language itself — values, pattern matching, modules & the pipe, Enum/streams, structs, protocols, processes, OTP, and a process playground. Accent elixir-purple.

- [F3 — A short history of Elixir](language/history.md) — `/elixir/language/history`
- [F3 — The release timeline](language/timeline.md) — `/elixir/language/timeline`
- [F3 — Under the hood](language/under-the-hood.md) — `/elixir/language/under-the-hood`
- [F3.01 — Values, types & IEx](language/values.md) — `/elixir/language/values`
- [F3.02 — Pattern matching](language/match/index.md) — `/elixir/language/match`
  - [F3.02.1 — The match operator](language/match/operator.md) — `/elixir/language/match/operator`
  - [F3.02.2 — Destructuring portal data](language/match/destructuring.md) — `/elixir/language/match/destructuring`
  - [F3.02.3 — Branching with case, with & guards](language/match/branching.md) — `/elixir/language/match/branching`
- [F3.03 — Functions, modules & the pipe](language/modules/index.md) — `/elixir/language/modules`
  - [F3.03.1 — Defining functions](language/modules/functions.md) — `/elixir/language/modules/functions`
  - [F3.03.2 — Organising with modules](language/modules/organising.md) — `/elixir/language/modules/organising`
  - [F3.03.3 — The pipe operator](language/modules/pipe.md) — `/elixir/language/modules/pipe`
- [F3.04 — Enumerables & streams](language/enum-streams/index.md) — `/elixir/language/enum-streams`
  - [F3.04.1 — Enum, the eager workhorse](language/enum-streams/enum.md) — `/elixir/language/enum-streams/enum`
  - [F3.04.2 — Comprehensions](language/enum-streams/comprehensions.md) — `/elixir/language/enum-streams/comprehensions`
  - [F3.04.3 — Lazy streams](language/enum-streams/streams.md) — `/elixir/language/enum-streams/streams`
- [F3.05 — Structs, maps & keyword lists](language/structs/index.md) — `/elixir/language/structs`
  - [F3.05.1 — Defining a struct](language/structs/define.md) — `/elixir/language/structs/define`
  - [F3.05.2 — Enforcing keys & defaults](language/structs/defaults.md) — `/elixir/language/structs/defaults`
  - [F3.05.3 — Matching on a struct's type](language/structs/matching.md) — `/elixir/language/structs/matching`
- [F3.06 — Polymorphism: protocols & behaviours](language/protocols/index.md) — `/elixir/language/protocols`
  - [F3.06.1 — Defining a protocol](language/protocols/define.md) — `/elixir/language/protocols/define`
  - [F3.06.2 — Implementing for a struct](language/protocols/defimpl.md) — `/elixir/language/protocols/defimpl`
  - [F3.06.3 — Behaviours & callbacks](language/protocols/behaviours.md) — `/elixir/language/protocols/behaviours`
- [F3.07 — Processes & the actor model](language/processes/index.md) — `/elixir/language/processes`
  - [F3.07.1 — Spawning a process](language/processes/spawn.md) — `/elixir/language/processes/spawn`
  - [F3.07.2 — Sending & receiving messages](language/processes/messages.md) — `/elixir/language/processes/messages`
  - [F3.07.3 — Holding state in a loop](language/processes/state.md) — `/elixir/language/processes/state`
- [F3.08 — OTP: GenServer & supervisors](language/otp/index.md) — `/elixir/language/otp`
  - [F3.08.1 — The GenServer behaviour](language/otp/genserver.md) — `/elixir/language/otp/genserver`
  - [F3.08.2 — Synchronous call, asynchronous cast](language/otp/call-cast.md) — `/elixir/language/otp/call-cast`
  - [F3.08.3 — Supervisors & restart strategies](language/otp/supervisors.md) — `/elixir/language/otp/supervisors`
- [F3.09 — The process playground](language/playground.md) — `/elixir/language/playground`

### F4 · Algorithms & Data Structures — [/elixir/algorithms](algorithms/index.md)
Twelve modules from lists to a branded-CHAMP store: the persistent-map spine (HAMT → CHAMP → Snowflake/branded ids → persistence → branded-CHAMP GenServer), recipes, DP, and a lab. Accent sage.

- [F4.01 — Lists, recursion & complexity](algorithms/lists/index.md) — `/elixir/algorithms/lists`
  - [F4.01.1 — Cons cells & the shape of a list](algorithms/lists/cons.md) — `/elixir/algorithms/lists/cons`
  - [F4.01.2 — Recursion over lists](algorithms/lists/recursion.md) — `/elixir/algorithms/lists/recursion`
  - [F4.01.3 — Complexity & big-O on the BEAM](algorithms/lists/big-o.md) — `/elixir/algorithms/lists/big-o`
- [F4.02 — Trees & traversals](algorithms/trees/index.md) — `/elixir/algorithms/trees`
  - [F4.02.1 — Binary trees & recursive shape](algorithms/trees/shape.md) — `/elixir/algorithms/trees/shape`
  - [F4.02.2 — Depth-first: pre, in, post-order](algorithms/trees/dfs.md) — `/elixir/algorithms/trees/dfs`
  - [F4.02.3 — Breadth-first & balance](algorithms/trees/bfs.md) — `/elixir/algorithms/trees/bfs`
- [F4.03 — Sorting & searching](algorithms/sorting/index.md) — `/elixir/algorithms/sorting`
  - [F4.03.1 — Merge & quicksort](algorithms/sorting/sorts.md) — `/elixir/algorithms/sorting/sorts`
  - [F4.03.2 — Linear & binary search](algorithms/sorting/search.md) — `/elixir/algorithms/sorting/search`
  - [F4.03.3 — Stability & sort cost](algorithms/sorting/cost.md) — `/elixir/algorithms/sorting/cost`
- [F4.04 — Maps, sets & hashing](algorithms/maps/index.md) — `/elixir/algorithms/maps`
  - [F4.04.1 — Maps & key lookup](algorithms/maps/lookup.md) — `/elixir/algorithms/maps/lookup`
  - [F4.04.2 — MapSet & membership](algorithms/maps/sets.md) — `/elixir/algorithms/maps/sets`
  - [F4.04.3 — Hashing & collisions](algorithms/maps/hashing.md) — `/elixir/algorithms/maps/hashing`
- [F4.05 — Hash array mapped tries](algorithms/hamt/index.md) — `/elixir/algorithms/hamt`
  - [F4.05.1 — Bitmapped nodes](algorithms/hamt/bitmap.md) — `/elixir/algorithms/hamt/bitmap`
  - [F4.05.2 — Hash-prefix indexing](algorithms/hamt/indexing.md) — `/elixir/algorithms/hamt/indexing`
  - [F4.05.3 — Structural sharing](algorithms/hamt/sharing.md) — `/elixir/algorithms/hamt/sharing`
- [F4.06 — CHAMP maps](algorithms/champ/index.md) — `/elixir/algorithms/champ`
  - [F4.06.1 — Compressed node layout](algorithms/champ/layout.md) — `/elixir/algorithms/champ/layout`
  - [F4.06.2 — Cache-friendly iteration](algorithms/champ/iteration.md) — `/elixir/algorithms/champ/iteration`
  - [F4.06.3 — Canonical equality](algorithms/champ/equality.md) — `/elixir/algorithms/champ/equality`
- [F4.07 — Identifiers, Snowflake & branded ids](algorithms/identifiers/index.md) — `/elixir/algorithms/identifiers`
  - [F4.07.1 — Choosing an identifier](algorithms/identifiers/choosing.md) — `/elixir/algorithms/identifiers/choosing`
  - [F4.07.2 — The Snowflake bigint](algorithms/identifiers/snowflake.md) — `/elixir/algorithms/identifiers/snowflake`
  - [F4.07.3 — Branded ids](algorithms/identifiers/branded.md) — `/elixir/algorithms/identifiers/branded`
- [F4.08 — Branded ids & persistence](algorithms/persistence/index.md) — `/elixir/algorithms/persistence`
  - [F4.08.1 — Branded ids as keys](algorithms/persistence/keys.md) — `/elixir/algorithms/persistence/keys`
  - [F4.08.2 — SQLite & PostgreSQL](algorithms/persistence/sql.md) — `/elixir/algorithms/persistence/sql`
  - [F4.08.3 — Redis keys](algorithms/persistence/redis.md) — `/elixir/algorithms/persistence/redis`
- [F4.09 — Branded CHAMP maps & GenServer](algorithms/branded-champ/index.md) — `/elixir/algorithms/branded-champ`
  - [F4.09.1 — Partition by namespace](algorithms/branded-champ/partition.md) — `/elixir/algorithms/branded-champ/partition`
  - [F4.09.2 — Structural sharing](algorithms/branded-champ/trie.md) — `/elixir/algorithms/branded-champ/trie`
  - [F4.09.3 — Own it with a GenServer](algorithms/branded-champ/genserver.md) — `/elixir/algorithms/branded-champ/genserver`
- [F4.10 — Practical recipes in Elixir](algorithms/recipes/index.md) — `/elixir/algorithms/recipes`
  - [F4.10.1 — Idiomatic patterns](algorithms/recipes/patterns.md) — `/elixir/algorithms/recipes/patterns`
  - [F4.10.2 — Streams & pipelines](algorithms/recipes/pipelines.md) — `/elixir/algorithms/recipes/pipelines`
  - [F4.10.3 — Profiling & complexity](algorithms/recipes/profiling.md) — `/elixir/algorithms/recipes/profiling`
- [F4.11 — Dynamic programming & advanced problems](algorithms/dynamic-programming/index.md) — `/elixir/algorithms/dynamic-programming`
  - [F4.11.1 — Memoization & overlapping subproblems](algorithms/dynamic-programming/memoization.md) — `/elixir/algorithms/dynamic-programming/memoization`
  - [F4.11.2 — Tabulation & bottom-up](algorithms/dynamic-programming/tabulation.md) — `/elixir/algorithms/dynamic-programming/tabulation`
  - [F4.11.3 — Classic DP problems](algorithms/dynamic-programming/problems.md) — `/elixir/algorithms/dynamic-programming/problems`
- [F4.12 — Lab: build a branded CHAMP store](algorithms/lab/index.md) — `/elixir/algorithms/lab`
  - [F4.12.1 — Watch a branded CHAMP grow](algorithms/lab/grow.md) — `/elixir/algorithms/lab/grow`
  - [F4.12.2 — A Snowflake registry](algorithms/lab/registry.md) — `/elixir/algorithms/lab/registry`
  - [F4.12.3 — Query by time range](algorithms/lab/range.md) — `/elixir/algorithms/lab/range`

### F5 · Pragmatic Programming — [/elixir/pragmatic](pragmatic/index.md)
Builds the framework-free Portal engine technique by technique: foundations, domain, tracer bullets, contracts, CQRS, state, testing, boundaries, and the engine lab. Accent burgundy.

- [F5.0.1 — The Portal engine blueprint](pragmatic/architecture.md) — `/elixir/pragmatic/architecture`
- [F5.0.2 — The domain model](pragmatic/domain-model.md) — `/elixir/pragmatic/domain-model`
- [F5.0.3 — The command & event flow](pragmatic/flow.md) — `/elixir/pragmatic/flow`
- [F5.01 — A running Portal from day one](pragmatic/foundations/index.md) — `/elixir/pragmatic/foundations`
  - [F5.01.1 — The development roadmap](pragmatic/foundations/roadmap.md) — `/elixir/pragmatic/foundations/roadmap`
  - [F5.01.2 — A thin web server in Elixir](pragmatic/foundations/thin-server.md) — `/elixir/pragmatic/foundations/thin-server`
  - [F5.01.3 — A web layer built for replacement](pragmatic/foundations/replaceable.md) — `/elixir/pragmatic/foundations/replaceable`
- [F5.02 — Modeling the Portal domain](pragmatic/domain/index.md) — `/elixir/pragmatic/domain`
  - [F5.02.1 — Structs & typespecs](pragmatic/domain/structs.md) — `/elixir/pragmatic/domain/structs`
  - [F5.02.2 — Bounded contexts](pragmatic/domain/contexts.md) — `/elixir/pragmatic/domain/contexts`
  - [F5.02.3 — A context's public API](pragmatic/domain/api.md) — `/elixir/pragmatic/domain/api`
- [F5.03 — Tracer bullets: a walking skeleton](pragmatic/tracer-bullets/index.md) — `/elixir/pragmatic/tracer-bullets`
  - [F5.03.1 — Tracer bullets vs prototypes](pragmatic/tracer-bullets/prototypes.md) — `/elixir/pragmatic/tracer-bullets/prototypes`
  - [F5.03.2 — The walking skeleton](pragmatic/tracer-bullets/skeleton.md) — `/elixir/pragmatic/tracer-bullets/skeleton`
  - [F5.03.3 — Iterating the slice](pragmatic/tracer-bullets/iterating.md) — `/elixir/pragmatic/tracer-bullets/iterating`
- [F5.04 — Design by contract](pragmatic/contracts/index.md) — `/elixir/pragmatic/contracts`
  - [F5.04.1 — Preconditions, postconditions & invariants](pragmatic/contracts/conditions.md) — `/elixir/pragmatic/contracts/conditions`
  - [F5.04.2 — Assertions in Elixir](pragmatic/contracts/assertions.md) — `/elixir/pragmatic/contracts/assertions`
  - [F5.04.3 — Failing fast](pragmatic/contracts/fail-fast.md) — `/elixir/pragmatic/contracts/fail-fast`
- [F5.05 — Commands, queries & events](pragmatic/cqrs/index.md) — `/elixir/pragmatic/cqrs`
  - [F5.05.1 — Command/query separation](pragmatic/cqrs/cqs.md) — `/elixir/pragmatic/cqrs/cqs`
  - [F5.05.2 — Domain events](pragmatic/cqrs/events.md) — `/elixir/pragmatic/cqrs/events`
  - [F5.05.3 — The engine as a reducer](pragmatic/cqrs/reducer.md) — `/elixir/pragmatic/cqrs/reducer`
- [F5.06 — Where engine state lives](pragmatic/state/index.md) — `/elixir/pragmatic/state`
  - [F5.06.1 — Choosing where state lives](pragmatic/state/choosing.md) — `/elixir/pragmatic/state/choosing`
  - [F5.06.2 — The engine GenServer](pragmatic/state/genserver.md) — `/elixir/pragmatic/state/genserver`
  - [F5.06.3 — Supervision](pragmatic/state/supervision.md) — `/elixir/pragmatic/state/supervision`
- [F5.07 — Pragmatic testing](pragmatic/testing/index.md) — `/elixir/pragmatic/testing`
  - [F5.07.1 — Testing the pure core](pragmatic/testing/pure-core.md) — `/elixir/pragmatic/testing/pure-core`
  - [F5.07.2 — Property-based testing](pragmatic/testing/property.md) — `/elixir/pragmatic/testing/property`
  - [F5.07.3 — Contract tests](pragmatic/testing/contract-tests.md) — `/elixir/pragmatic/testing/contract-tests`
- [F5.08 — Boundaries & integration seams](pragmatic/boundaries/index.md) — `/elixir/pragmatic/boundaries`
  - [F5.08.1 — Ports & adapters](pragmatic/boundaries/ports.md) — `/elixir/pragmatic/boundaries/ports`
  - [F5.08.2 — The engine facade](pragmatic/boundaries/facade.md) — `/elixir/pragmatic/boundaries/facade`
  - [F5.08.3 — Error contracts for the UI](pragmatic/boundaries/errors.md) — `/elixir/pragmatic/boundaries/errors`
- [F5.09 — Lab: the Portal engine, LiveView-ready](pragmatic/engine-lab/index.md) — `/elixir/pragmatic/engine-lab`
  - [F5.09.1 — The engine facade end to end](pragmatic/engine-lab/end-to-end.md) — `/elixir/pragmatic/engine-lab/end-to-end`
  - [F5.09.2 — A LiveView mount sketch](pragmatic/engine-lab/mount.md) — `/elixir/pragmatic/engine-lab/mount`
  - [F5.09.3 — What ships in F6](pragmatic/engine-lab/handoff.md) — `/elixir/pragmatic/engine-lab/handoff`

### F6 · Phoenix Framework — [/elixir/phoenix](phoenix/index.md)
Serves the Portal engine to people: lifecycle, routing, Ecto, contexts, HEEx, LiveView, PubSub, deployment, and the live-dashboard capstone. The web layer calls only the Portal facade. Accent blue.

- [F6.0.1 — The developer journey](phoenix/journey.md) — `/elixir/phoenix/journey`
- [F6.0.2 — What we're building](phoenix/blueprint.md) — `/elixir/phoenix/blueprint`
- [F6.0.3 — Wiring Phoenix onto the F5 engine](phoenix/wiring.md) — `/elixir/phoenix/wiring`
- [F6.01 — Architecture & the request lifecycle](phoenix/lifecycle/index.md) — `/elixir/phoenix/lifecycle`
  - [F6.01.1 — The request lifecycle](phoenix/lifecycle/request-path.md) — `/elixir/phoenix/lifecycle/request-path`
  - [F6.01.2 — The endpoint, supervised](phoenix/lifecycle/endpoint.md) — `/elixir/phoenix/lifecycle/endpoint`
  - [F6.01.3 — Controllers, views & the facade seam](phoenix/lifecycle/controllers.md) — `/elixir/phoenix/lifecycle/controllers`
- [F6.02 — Routing, controllers & plugs](phoenix/routing/index.md) — `/elixir/phoenix/routing`
  - [F6.02.1 — Routes & verbs](phoenix/routing/routes.md) — `/elixir/phoenix/routing/routes`
  - [F6.02.2 — Pipelines & scopes](phoenix/routing/pipelines.md) — `/elixir/phoenix/routing/pipelines`
  - [F6.02.3 — Writing a plug](phoenix/routing/plugs.md) — `/elixir/phoenix/routing/plugs`
- [F6.03 — Ecto: schemas, changesets & queries](phoenix/ecto/index.md) — `/elixir/phoenix/ecto`
  - [F6.03.1 — Schemas & migrations](phoenix/ecto/schemas.md) — `/elixir/phoenix/ecto/schemas`
  - [F6.03.2 — Changesets & validation](phoenix/ecto/changesets.md) — `/elixir/phoenix/ecto/changesets`
  - [F6.03.3 — Queries & the repo](phoenix/ecto/repo.md) — `/elixir/phoenix/ecto/repo`
- [F6.04 — Contexts & domain design](phoenix/contexts/index.md) — `/elixir/phoenix/contexts`
  - [F6.04.1 — Context boundaries](phoenix/contexts/boundaries.md) — `/elixir/phoenix/contexts/boundaries`
  - [F6.04.2 — Contexts vs the F5 facade](phoenix/contexts/vs-facade.md) — `/elixir/phoenix/contexts/vs-facade`
  - [F6.04.3 — Composing contexts](phoenix/contexts/composition.md) — `/elixir/phoenix/contexts/composition`
- [F6.05 — Templates, components & HEEx](phoenix/heex/index.md) — `/elixir/phoenix/heex`
  - [F6.05.1 — Templates & assigns](phoenix/heex/templates.md) — `/elixir/phoenix/heex/templates`
  - [F6.05.2 — Function components & slots](phoenix/heex/components.md) — `/elixir/phoenix/heex/components`
  - [F6.05.3 — Forms & inputs](phoenix/heex/forms.md) — `/elixir/phoenix/heex/forms`
- [F6.06 — Phoenix LiveView fundamentals](phoenix/liveview/index.md) — `/elixir/phoenix/liveview`
  - [F6.06.1 — mount & assigns](phoenix/liveview/mount.md) — `/elixir/phoenix/liveview/mount`
  - [F6.06.2 — handle_event & state](phoenix/liveview/events.md) — `/elixir/phoenix/liveview/events`
  - [F6.06.3 — render & diffs](phoenix/liveview/render.md) — `/elixir/phoenix/liveview/render`
- [F6.07 — PubSub, channels & real-time](phoenix/pubsub/index.md) — `/elixir/phoenix/pubsub`
  - [F6.07.1 — Broadcasting engine events](phoenix/pubsub/broadcast.md) — `/elixir/phoenix/pubsub/broadcast`
  - [F6.07.2 — Subscribing a LiveView](phoenix/pubsub/subscribe.md) — `/elixir/phoenix/pubsub/subscribe`
  - [F6.07.3 — Channels & presence](phoenix/pubsub/presence.md) — `/elixir/phoenix/pubsub/presence`
- [F6.08 — Auth, deployment & going live](phoenix/deployment/index.md) — `/elixir/phoenix/deployment`
  - [F6.08.1 — Sessions & authentication](phoenix/deployment/auth.md) — `/elixir/phoenix/deployment/auth`
  - [F6.08.2 — Releases & config](phoenix/deployment/releases.md) — `/elixir/phoenix/deployment/releases`
  - [F6.08.3 — Deploying to production](phoenix/deployment/deploy.md) — `/elixir/phoenix/deployment/deploy`
- [F6.09 — The live dashboard](phoenix/live-dashboard/index.md) — `/elixir/phoenix/live-dashboard`
  - [F6.09.1 — Build the dashboard](phoenix/live-dashboard/build.md) — `/elixir/phoenix/live-dashboard/build`
  - [F6.09.2 — Broadcast engine events](phoenix/live-dashboard/stream.md) — `/elixir/phoenix/live-dashboard/stream`
  - [F6.09.3 — Many clients, live](phoenix/live-dashboard/multi-client.md) — `/elixir/phoenix/live-dashboard/multi-client`
