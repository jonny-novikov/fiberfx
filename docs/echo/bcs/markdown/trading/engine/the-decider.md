# B8.1.2 · The Decider

> Dive 2 of B8.1 · route `/bcs/trading/engine/the-decider` · teaches `docs/trading/trading.patterns.md` Part one
> (the Decider) + the BEAM placement. **Grounding:** the `decide` / `evolve` signature is quoted verbatim from
> the corpus (Chassaing's pattern). `Exchange.Decider`, `Exchange.OrderBook`, and `Exchange.Book` are the trading
> **engine** on top of a real substrate — **PROPOSED**: not built, not measured, taught in design voice. The
> substrate they compose is real, shipped Elixir — `EchoCache.Ring` and `EchoCache.Journal` in the live umbrella,
> hardened by the rung-gated EchoMQ program (`docs/echo_mq/emq.roadmap.md`), which names the trading platform as
> its downstream consumer. The replay corollary leans on the committed B4.4 journal posture, named as the as-built
> mechanic the design inherits. No engine number invented.

The Decider.

The decision half of the engine answers the second question: what a command means when it meets a book. The
functional event-sourcing Decider, as Chassaing fixed it, is three types and three elements
(`docs/trading/trading.patterns.md`):

```
initialState : State
decide       : Command -> State -> Event list
evolve       : State -> Event -> State
```

`decide` is the only place business rules live: given a command and the current state, it returns the facts that
follow — possibly several, possibly none, never a mutation. `evolve` folds a fact into state, and it is
deliberately trivial — a field set, a list append, a counter move; decision has already been taken.
`initialState` makes the fold total from nothing.

`Exchange.Decider` and `Exchange.OrderBook` are **PROPOSED** pure modules; `Exchange.Book` is the **PROPOSED**
GenServer shell. They are taught as design (`docs/trading/trading.specs.md`); none has a rung yet, and none claims
a number.

Interactive 1 (hero): a decide/evolve stepper over a tiny fixed book. Feed a fixed command against a two-level
book state; the stepper computes the `decide` events (pure), then folds `evolve` over them to the new state — the
fold law made visible, the priority resolved by mint order, no process and no store.

## §1 Why it is the right seat for a matching engine

Three properties a matching engine cannot negotiate away, each a direct corollary of the signatures
(`docs/trading/trading.patterns.md`).

**Testability without machinery** — price-time priority, self-trade prevention, partial-fill arithmetic are
properties over `decide` alone: feed a book state and a command, assert on the returned events; no process, no
store, no mock — which is what makes property tests on the matching rules cheap enough to be exhaustive.

**Replay as identity, not feature** — fold `evolve` over the log and the book *is* its history; the Chapter 4.4
journal already gates exactly this shape (replay reproduces live state), so milestone A inherits a certified
mechanic rather than promising one. That inheritance is the as-built floor under a PROPOSED design: the journal's
record is committed; the book's replay rung is not yet run.

**Audit as a property** — every fill is explainable as `decide(cmd, state_at_seq)`, and because sequence is the
branded mint order, "state at sequence" is a well-defined point, not a race.

## §2 Event sourcing, not command sourcing

One distinction worth pinning because the literature blurs it: this is **event** sourcing, not command sourcing.
The log stores `decide`'s *outputs* — the facts — not its inputs. Storing commands and re-deciding on replay
couples history to every past version of the rules; storing events makes replay a pure fold under `evolve`, which
rarely changes and changes safely. The platform logs facts.

The three corollaries follow from the one choice: testability is a property over `decide`; replay is the fold the
B4.4 journal already gates; audit is `decide` re-applied at a sequence the id law makes exact.

Interactive 2: an alternatives comparator — Decider vs the mutating aggregate vs the saga-as-decision-seat — each
read against the three properties (testability, replay, audit) and the seam it costs, drawn from the corpus.

## §3 Alternatives weighed

The pattern earns its seat against the alternatives, named honestly (`docs/trading/trading.patterns.md`).

**The mutating aggregate** — the classic OO shape: an entity with `apply` methods that validate and mutate in one
move. It works, and most of the industry runs on it; what it costs here is the seam — decision and mutation are
one body, so property-testing the rules drags the mutation machinery along, and replay requires the entity to be
built for it rather than getting it free.

**Transaction-script validation over CRUD rows** — no fold, no replay, audit reconstructed forensically from row
diffs; disqualified by the audit requirement alone.

**A process manager / saga as the decision seat** — the right tool one level up (a workflow across aggregates
reacting to events with new commands), and the wrong tool for one book's rules: a saga that contains matching
logic is "a Decider wearing a trench coat," with worse tests.

**Actor state without events** — a plain GenServer mutating its own state, no log: the BEAM's default and a fine
one for session state; it surrenders the fold law, and with it replay and audit, which this domain cannot
surrender.

Where the Decider is the wrong tool, named: cross-aggregate invariants — "this account's margin across all books"
— do not belong inside one book's `decide`; they are the saga's job, downstream of the log, with compensating
events. Long or effectful work inside `decide` is a category error: `decide` is pure by signature, and IO belongs
at the shell.

## §4 The BEAM placement — functional core, imperative shell

The functional core, imperative shell, as the house already practices it: `Exchange.Decider` and
`Exchange.OrderBook` are pure modules; `Exchange.Book` is the GenServer shell that owns the process identity,
drains the ingress Ring, calls `decide`, appends the events to the log, folds `evolve`, and answers. The shell is
thin enough to be boring, which is the point — everything worth testing is underneath it, and everything worth
supervising is the shell.

All three `Exchange.*` modules are **PROPOSED**. The shell composes a real substrate — `EchoCache.Ring` (dive 1)
and, at the next module, `EchoCache.Journal`, both shipped Elixir in the live umbrella and hardened by the
rung-gated EchoMQ program (`docs/echo_mq/emq.roadmap.md`), which names the trading platform as its downstream
consumer. The pure cores are the engine's to build, and they earn their first numbers at their own rungs; the
substrate beneath them already has its numbers.

## References

Sources:

- Chassaing — Functional Event Sourcing Decider — https://thinkbeforecoding.com/post/2021/12/17/functional-event-sourcing-decider (the decide / evolve signatures, initial state, the command-sourcing distinction)
- Fowler — The LMAX Architecture — https://martinfowler.com/articles/lmax.html (in-memory event sourcing on a single writer — the architecture the decider sits inside)
- The LMAX Disruptor — technical paper — https://lmax-exchange.github.io/disruptor/disruptor.html (the ring that feeds the single-writer processor the Decider runs in)

Related:

- /bcs/trading/engine — B8.1 · The Engine, the module hub
- /bcs/trading/engine/the-disruptor-seat — B8.1.1, the ingress the Book's shell drains
- /bcs/elixir-core — B2 · The Elixir BCS Core, the functional core the Decider is written in
- /bcs/cache — B4 · EchoCache, the journal the replay corollary leans on
- /elixir — Functional Programming in Elixir, the umbrella
- /echomq — EchoMQ, the protocol in depth

Pager: previous `/bcs/trading/engine/the-disruptor-seat` · next `/bcs/trading/engine/price-time-by-mint-order`.
