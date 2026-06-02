# The Decider pattern (`decide` / `evolve`) in the Portal

> A reference article on the functional event-sourcing core the Portal engine is built on — what `decide`/`evolve`
> is, how it lands in the F5 specs, what it buys, what can sink it, and which other functional patterns could satisfy
> the same specs. Companion to the engine specs in [`pragmatic.md`](pragmatic.md); the foundations and control-flow
> matrix are in [`../specs.approach.md`](../specs.approach.md).

## 1. What the pattern is

`decide`/`evolve` is the **Decider pattern**, the functional formulation of event sourcing introduced by Jérémie
Chassaing. A Decider is four pure pieces: an initial state, `decide`, `evolve`, and (optionally) a terminal predicate.
Its canonical signatures are:

```text
initialState : State
decide       : Command -> State -> Event list
evolve       : State  -> Event -> State
isTerminal   : State  -> bool        -- optional
```

The mental model is a strict separation of two questions. A **command** is an intent in the imperative mood ("enroll
this learner") and may be refused. An **event** is a fact in the past tense ("this learner was enrolled") and is never
refused once recorded. `decide` answers *what happened* — it runs the business rules against the current state and
returns the event(s) to record. `evolve` answers *given it happened, what is the new state* — it folds exactly one
event in. The current state is then the left fold of the whole event log:

```text
replay(log) = List.foldl(evolve, initialState, log)
```

Two clarifications matter, because they are easy to get wrong:

- **`decide` returns events, not an error tuple.** In the canonical pattern, `decide` produces an `Event list`. A
  rejected command is handled by `decide` raising, by emitting a rejection event, or by a guard at the boundary before
  `decide` runs. The success/failure result a *caller* sees (`:ok | {:error, reason}`) belongs to the command handler
  that wraps `decide`, not to `decide` itself.
- **`decide` and `evolve` are pure.** No I/O, no clock, no process. Side effects (reading reference data, persisting
  events, stamping time, holding state) live outside, in the imperative shell. This is the functional-core /
  imperative-shell split.

## 2. Applying it in the Portal

The pattern is spread across three F5 rungs, each owning one concern:

| Rung | What it contributes |
| --- | --- |
| [F5.4](f5.4.md) · the contract | the rules `decide` enforces, and the closed reason set (`:course_not_found`, `:already_enrolled`) |
| [F5.5](f5.5.md) · commands, queries & events | the pure core — `Portal.Engine.Core.decide/2`, `evolve/2`, `replay/1` — and the past-tense events |
| [F5.6](f5.6.md) · where state lives | the imperative shell — a supervised `Portal.Engine` GenServer that hosts the fold and recovers by replay |

In Portal terms, the write path for an enrollment is:

```elixir
# F5.5 — the pure core (Portal.Engine.Core): decide returns events only
def decide(_state, {:enroll, user_id, course_id}) do
  [%Portal.Learning.Events.LearnerEnrolled{user_id: user_id, course_id: course_id, at: now()}]
end

def evolve(%Portal.Learning.Events.LearnerEnrolled{} = e, state) do
  put_enrollment(state, e.user_id, e.course_id)                   # fold one fact into state
end

def replay(log), do: Enum.reduce(log, initial_state(), &evolve/2) # state is the fold of the log
```

```elixir
# F5.4 — the contract guards the boundary and owns the rejection (tagged tuples)
def authorize_enroll(state, user_id, course_id) do
  with :ok            <- valid_ref(user_id, "USR"),
       :ok            <- valid_ref(course_id, "CRS"),
       {:ok, _course} <- Portal.Catalog.course(course_id),        # reference data, at the boundary
       :ok            <- refute_enrolled(state, user_id, course_id) do
    :ok
  end                                                             # else: {:error, :course_not_found | :already_enrolled}
end
```

```elixir
# F5.6 — the imperative shell (Portal.Engine, a GenServer)
def init(events), do: {:ok, Portal.Engine.Core.replay(events)}    # fold the log once at boot

def handle_call({:command, cmd}, _from, state) do
  case Portal.Engine.Core.decide(state, cmd) do
    events when is_list(events) ->
      new_state = Enum.reduce(events, state, &Portal.Engine.Core.evolve/2)
      :ok = append(events)                                        # persist the facts (F5.8 port)
      {:reply, :ok, new_state}
    {:error, reason} ->
      {:reply, {:error, reason}, state}                           # state unchanged
  end
end

def handle_call({:query, q}, _from, state), do: {:reply, read(state, q), state}  # CQS: reads never mutate
```

Three Portal-specific choices are worth calling out:

- **Argument order is the Elixir idiom, not Chassaing's.** Portal uses `evolve(event, state)` (not `evolve(state,
  event)`) so the function drops straight into `Enum.reduce(events, initial_state(), &evolve/2)`, whose reducer is
  `(element, accumulator)`. `decide(state, command)` is likewise a local style choice. Both are reversed from the F#
  original and that is fine.
- **Rejection is resolved at the boundary.** Whether a course exists is reference data in the F4 store, and whether a
  learner is already enrolled is read from the folded state; both checks run in the F5.4 contract guard at the command
  boundary, which returns the closed reasons as tagged tuples before `decide` is reached. `decide` returns events
  only, so the pure core takes no I/O and carries no error channel. The catalog stays CRUD; only enrollment/progress is
  event-sourced.
- **The durable log is a port.** In [F5.6](f5.6.md) `load_events()`/`append` are good enough to survive a process
  crash; F5.8 formalizes them as the `Portal.EventStore` behaviour with swappable in-memory and Postgres adapters, and
  F6.3 makes the Postgres adapter durable across deploys. The web layer never sees any of this — it calls only the
  `Portal` boundary (the master invariant).

### 2.1 Portal's `decide` return type (resolved)

Portal opts in to the **canonical Decider**: `decide/2 :: (state, command) -> [event]` returns events only. The
expected rejections (`:course_not_found`, `:already_enrolled`) are returned as tagged tuples by the F5.4 contract
guarding the command boundary, *before* `decide` runs (see the second code block above). This keeps F5.4's "expected
failures are tagged tuples, never raised" rule intact and the pure core free of an error channel — `decide` proposes
facts, the boundary decides admissibility. The railway-pipeline alternative (where the validation flow itself is the
write path) remains a distinct option, listed as pattern (c) in the decision matrix in §8.

## 3. Why it fits the Portal (benefits)

- **A pure, exhaustively testable engine.** `decide`/`evolve`/`replay` are tested with plain example and `StreamData`
  property tests — no database, no mocks, no processes. The headline property is `replay(log) == incremental fold`.
- **An audit log for free.** Every enrollment and lesson delivery is a recorded fact with a timestamp. Streaks,
  progress analytics, and "what happened and when" all read off the same history rather than needing extra bookkeeping.
- **Crash recovery is the fold.** [F5.6](f5.6.md) needs no bespoke recovery code: a crashed `Portal.Engine` is
  restarted by its supervisor and `init/1` re-folds the log to the same state.
- **The read model is the fold.** At Portal's current scope the held state *is* the query model — no separate
  projection store to build or keep consistent yet.
- **It is BEAM-shaped.** A single GenServer serialises commands and queries over one consistent state; OTP supervision
  turns "rebuild from the source of truth" into automatic recovery. The pattern and the runtime fit each other.
- **It feeds the roadmap.** Events are the natural trigger for the Telegram bot's notifications and for LiveView/PubSub
  fan-out — a `LearnerEnrolled` becoming a push or a live counter is a small step, not a redesign.

## 4. Pros (general strengths)

- Decision logic and state transition are separated, each pure and independently testable.
- The event log is an immutable, append-only source of truth — strong auditability and debuggability (same inputs,
  same output).
- Time travel: rebuild state as of any point, replay into new read models, or rebuild a model after a bug fix.
- Deciders compose (you can combine two Deciders into one) and are framework-agnostic — the pattern stands alone.
- A clean fit for CQRS: the write side decides and folds; read models are derived.

## 5. Cons (general weaknesses)

- More moving parts than CRUD: events, a log, a fold, a process, eventually a port and adapters.
- Queries that do not match the fold need separate read models, which add eventual-consistency surface.
- The append-only log grows; long streams make `replay` expensive without snapshots.
- It is unfamiliar to many teams and easy to over-apply.

## 6. Killers (what can sink an event-sourced Decider)

These are the failure modes that turn the pattern from an asset into a liability if ignored.

- **Event versioning is the defining problem.** Events written long ago must still be readable after the code changes.
  Greg Young's rule: a new event version must be convertible from the old, or it is a *new event*, not a version. The
  common mechanism is **upcasting** — middleware between deserialization and the fold that maps old shapes to new —
  plus copy-replace for structural rewrites. Budget for this from the start; it is the central question of an
  event-sourced system.
- **Snapshots have their own versioning cost.** They speed up `replay` on long streams but, per Young, are "often not
  worth implementing" early because a changed snapshot must usually be *rebuilt*, not upgraded. Add them only when
  replay time actually hurts.
- **Eventual consistency.** The moment read models become asynchronous projections, reads lag writes. Designing the UI
  and the API for that lag is real work; in-process folds (Portal today) avoid it, asynchronous projections (later) do
  not.
- **Whole-system event sourcing is an anti-pattern.** Young himself frames CQRS as the stepping stone and event
  sourcing as something to apply where it earns its keep, not everywhere. In Portal, enrollment/progress is event
  sourced; the catalog is not.
- **Set-based and cross-aggregate invariants are awkward.** "This email is unique across all users" cannot be checked
  by one aggregate's fold; it needs a reservation pattern or a database unique constraint (which is exactly what
  F6.3's `unique_constraint` provides for the catalog). Do not try to enforce global uniqueness inside `decide`.
- **Erasure fights immutability.** Append-only logs cannot be edited, so "delete this user's data" (GDPR) needs
  crypto-shredding (discard the key) or copy-replace, not a `DELETE`.
- **The single-writer ceiling.** One GenServer per stream serialises writes; that is the consistency win and the
  throughput cap ([F5.6](f5.6.md) accepts it deliberately). Hot streams need partitioning or a different home.
- **Reference data does not belong in the log.** Slowly changing lookup data (the course catalog) is clearer as CRUD;
  event-sourcing it adds cost for no benefit.

## 7. Alternatives (beyond functional style)

- **Event-sourced aggregate, `execute`/`apply` (Commanded).** The same idea in an object/aggregate shape, batteries
  included: a GenServer per aggregate, command routing, projections, process managers, and a real event store
  (EventStore/EventStoreDB). `execute` ≈ `decide`, `apply` ≈ `evolve`. Reach for it when you want the framework rather
  than a hand-rolled core.
- **CRUD with a transaction script.** Validate, then write current-state rows in one transaction (`Ecto.Multi`), no
  events. Simplest by far; no audit, no replay. This is the right tool for the catalog and most reference data.
- **State-stored functional core.** Keep a pure transition function but persist *state*, not events — recovery loads
  the last state instead of replaying. You keep the pure, testable core and lose the log.
- **Actor with mutable internal state.** A process that mutates its own fields per message. Familiar, but loses both
  purity and the log.

## 8. Other functional patterns for the same F5 specs

The Decider is one functional way to satisfy [F5.5](f5.5.md) and [F5.6](f5.6.md). Several other functional patterns
could meet the *same* specs — some fully, some only in part. Each is described as it would land against the F5.5
core (CQS, events, `decide`/`evolve`/`replay`) and the F5.6 state home (held state, crash recovery).

- **(a) Decider — `decide`/`evolve`/`replay` (chosen).** Event-sourced fold. Satisfies F5.5 as written and recovers by
  replay in F5.6. Splits validation (`decide` → events) from application (`evolve` → state).
- **(b) State-stored transition function.** `handle(state, command) :: {:ok, new_state} | {:error, reason}`, pure, with
  state persisted directly. Meets F5.5's CQS and purity, but not "state is the fold of the log" (F5.5-INV4): recovery
  loads stored state rather than replaying. No versioning pain, no audit. Best when history is not required.
- **(c) Railway `with` pipeline.** The [F5.4](f5.4.md) contract style as the whole write path: each command is a `with`
  chain that validates and writes transactionally. Meets F5.4 strongly; produces no fold or event log, so it does not
  meet F5.5-INV3/INV4 unless events are bolted on. This is effectively the CRUD/`Ecto.Multi` path Portal uses for the
  catalog (F6.3).
- **(d) Elm-style `update` / reducer.** `update(state, message) :: state` (optionally `{state, [effect]}`), one total
  pure function, recovered by replaying messages. It *fuses* decide and evolve into a single step, where the Decider
  *splits* them — cleaner for a domain engine when you want validation separate from application, but the Elm `update`
  is ideal for UI/LiveView state. The Elixir library TeaVent does Elm-style event dispatch on the BEAM.
- **(e) Finite state machine (`gen_statem` or explicit).** Model the lifecycle (enrollment, lesson lock/availability)
  as explicit states and transitions. OTP-native and makes illegal transitions unrepresentable, satisfying F5.6's
  "state in a supervised process." It is not inherently event-sourced; transitions can emit events to recover F5.5.
  Overkill for today's light enrollment, attractive later if lesson-locking grows rules.
- **(f) Effects-as-data interpreter (free-monad-style).** `decide` returns a *program* of effect descriptions that a
  thin shell interprets. Maximizes purity and lets you test orchestration without running it, at the cost of
  indirection. Rarely worth it in Elixir, where `with` plus a small shell suffices.

### Decision matrix

Legend: ✓ strong · △ partial / with work · ✗ weak or absent. "Cheap to evolve" means low schema-versioning cost.

| Pattern | Audit log | Replay recovery | Query out of the box | Write throughput | Cheap to evolve | OTP fit | Low complexity | Meets F5.5/F5.6 as written | Pure core | Best when |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| (a) Decider `decide`/`evolve` | ✓ | ✓ | △ (fold is the model) | △ (single writer) | ✗ | ✓ | △ | ✓ | ✓ | history, audit, and replay matter; hand-rolled core |
| (g) Aggregate `execute`/`apply` (Commanded) | ✓ | ✓ | ✓ (projections) | △ | ✗ | ✓ | △ (framework) | ✓ (equivalent) | ✓ | batteries-included ES with projections and process managers |
| (b) State-stored transition | ✗ (unless events added) | ✗ (loads state) | ✓ | ✓ | ✓ | ✓ | ✓ | △ (pure yes, fold no) | ✓ | robustness without an audit requirement |
| (c) Railway `with` pipeline | ✗ | ✗ | ✓ | ✓ | ✓ | ✓ | ✓ | ✗ (no fold/events) | ✓ (per step) | straightforward transactional writes; the catalog |
| (d) Elm `update` / reducer | △ (messages as log) | ✓ (replay messages) | △ | △ | △ | ✓ | ✓ | △ (fuses decide+evolve) | ✓ | UI / LiveView state, message-driven flows |
| (e) FSM (`gen_statem`) | ✗ (unless emits events) | ✗ | ✓ | △ | ✓ | ✓ | △ | △ | △ (process) | rich lifecycle and transition rules |
| (f) Effects interpreter | △ | △ | △ | △ | △ | △ | ✗ | △ | ✓ | heavy effect orchestration needing pure tests |

**Recommendation for Portal.** F5.5/F5.6 already specify the Decider, and it is the right default: audit (streaks,
analytics), replay-based recovery, and a pure testable core all carry weight, while the costs that bite — versioning,
snapshots, eventual consistency — are deferrable and bounded at the current scale. Keep the catalog on the railway /
CRUD path (c) as F6.3 does. Adopt the aggregate framework (g) only if the hand-rolled core outgrows itself. Hold
`gen_statem` (e) in reserve for lesson-locking and progress if they become a real state machine, and use the Elm
`update` (d) inside LiveView for UI state in F6 — kept distinct from the domain engine. If the open question in §2.1
resolves toward the canonical pattern, narrow `decide` to `-> [event]` and move rejection to the boundary.

## 9. Sources (with use cases)

**The Decider pattern**

- Jérémie Chassaing, *Functional Event Sourcing Decider* — <https://thinkbeforecoding.com/post/2021/12/17/functional-event-sourcing-decider>.
  The origin and canonical signatures. Use it as the definition of record for `decide`/`evolve`/`initialState`.
- Kuba Zalas, *Functional event sourcing* — <https://zalas.pl/functional-event-sourcing/>. A worked Kotlin
  derivation that arrives at the Decider and contrasts `Decide` with Khononov's `Execute` naming; good for seeing the
  pattern emerge from first principles.
- DeltaBase, *Functional Event Sourcing with the Decider Pattern* —
  <https://delta-base.com/docs/concepts/functional-event-sourcing-decider/>. A TypeScript framing emphasizing the
  three pure functions and test-without-mocks; useful when explaining the pattern to a JS/TS audience.
- `decide.rb` — <https://github.com/jandudulski/decide.rb>. A small Ruby port; handy reference implementation showing
  `decide`/`evolve` and Decider composition in a few lines.

**Event sourcing and CQRS foundations**

- Martin Fowler, *Event Sourcing* — <https://martinfowler.com/eaaDev/EventSourcing.html>. The baseline definition;
  use for the "state as a log of events" framing and the rebuild/replay idea.
- Martin Fowler, *CommandQuerySeparation* — <https://martinfowler.com/bliki/CommandQuerySeparation.html>. The CQS rule
  behind F5.5's split: commands change state and return nothing; queries return data and change nothing.
- Greg Young, *A Whole System Based on Event Sourcing is an Anti-Pattern* (InfoQ) —
  <https://www.infoq.com/EventDrivenArchitecture/news/142>. Read this before deciding what to event-source; it argues
  for CQRS first and event sourcing where it earns its place.

**Versioning and operating event-sourced systems (the killers)**

- Greg Young, *Versioning in an Event Sourced System* (free e-book) — <https://leanpub.com/esversioning/read>. The
  definitive treatment of upcasting, weak schema, copy-replace, and snapshot versioning. Essential before you ship a
  log you intend to keep.
- Oskar Dudycz, *How to (not) do the events versioning?* — <https://event-driven.io/en/how_to_do_event_versioning/>.
  A practical menu of versioning tactics (non-breaking extension, new schema, upcasting, double-publishing) with
  trade-offs; the field guide to accompany the book.
- Marten, *Events Versioning* — <https://martendb.io/events/versioning>. A concrete library view of storing type
  metadata and mapping events across renames; useful even if you are not on .NET, for how a store handles evolution.

**Elixir CQRS / event sourcing (the framework alternative)**

- Commanded — <https://github.com/commanded/commanded>. The mainstream Elixir CQRS/ES framework: aggregates as
  GenServers, command routers, projections, process managers, EventStore/EventStoreDB adapters. Reach for it when you
  want batteries-included ES rather than a hand-rolled core.
- *Implementing CQRS in Elixir* — <https://github.com/slashdotdash/implementing-cqrs-in-elixir>. Shows the
  `execute`/`apply` aggregate-root mechanics by hand: command functions return events or raise, state is a left fold
  via `apply/2`. The closest mirror of Portal's `decide`/`evolve`, minus the framework.
- Incident — <https://hexdocs.pm/incident/readme.html>. Lighter ES/CQRS building blocks favouring functions and
  reducers for stateless tests; a middle ground between hand-rolled and Commanded.
- Curiosum, *Elixir Commanded: CQRS and Event Sourcing* — <https://curiosum.com/blog/segregate-responsibilities-with-elixir-commanded>.
  A readable benefits/eventual-consistency overview; good for orienting a team new to the patterns on the BEAM.

**Functional-core and other functional patterns**

- Gary Bernhardt, *Boundaries* (functional core, imperative shell) — <https://www.destroyallsoftware.com/talks/boundaries>.
  The architecture under both the Decider and the state-stored transition: pure core, effects at the edges. Use it to
  justify why `decide`/`evolve` stay pure and the GenServer/EventStore stay impure.
- Scott Wlaschin, *Railway Oriented Programming* — <https://fsharpforfunandprofit.com/rop/>. The `with` + tagged-tuple
  pipeline (option c) and the model behind the railway variant of `decide`. Use it for command validation flows.
- The Elm Architecture (official guide) — <https://guide.elm-lang.org/architecture/>. `update : Msg -> Model -> Model`
  (option d) — the reducer that fuses decide and evolve; the right shape for LiveView/UI state, distinct from the
  domain engine.
- Erlang/OTP `gen_statem` — <https://www.erlang.org/doc/man/gen_statem.html>. The state-machine option (e) for
  lifecycle-heavy domains; makes illegal transitions unrepresentable in a supervised process.

**Spec system cross-references**

- Engine specs and the value ladder: [`pragmatic.md`](pragmatic.md); the contract [`f5.4.md`](f5.4.md), the core
  [`f5.5.md`](f5.5.md), the state home [`f5.6.md`](f5.6.md).
- Foundations, control-flow matrix, and the master invariant: [`../specs.approach.md`](../specs.approach.md).
- Near-term delivery plan: [`pragmatic.roadmap.md`](pragmatic.roadmap.md).

---

> Part of the jonnify toolkit. Markdown is the source; this article is reviewed alongside the F5 specs it explains.
