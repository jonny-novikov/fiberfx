# TRD · Patterns — Deciders and Disruptors Under the Hot Path

<show-structure depth="2"/>

The match path of a trading platform answers exactly two questions, and they are different questions. **What
happens** when this command meets this book — a question of decision, owed purity so it can be tested, replayed, and
audited. **In what order, and at what cost of admission** — a question of sequencing and overload, owed a mechanism
so it can be measured and refused with a receipt. This article is the deep argument for the two patterns this suite places
under those questions — the functional **Decider** for the first, a **Disruptor-style ingress** for the second —
each with its provenance, its alternatives weighed, the cases where it is the wrong tool, and the final choice as
this platform's specification ([`exchange.specs.md`](exchange.specs.md)) takes it. Status note: this is an expertise
article, not a record; every platform claim in it becomes a gate at the rung that ships it.

## Part one — the Decider

### The pattern, at its source

The functional event-sourcing Decider, as Chassaing fixed it [3], is three types and three elements:

```
initialState : State
decide       : Command -> State -> Event list
evolve       : State -> Event -> State
```

`decide` is the only place business rules live: given a command and the current state, it returns the facts that
follow — possibly several, possibly none, never a mutation. `evolve` folds a fact into state, and it is deliberately
trivial — "Given current State, when Event occurs, here is the new State" [3] — a field set, a list append, a
counter move; decision has already been taken. `initialState` makes the fold total from nothing. The discipline the
two signatures enforce is the whole value: rules cannot hide in mutation, because there is no mutation; state cannot
drift from the log, because state *is* the fold of the log.

### Why it is the right seat for a matching engine

Three properties a matching engine cannot negotiate away, each a direct corollary of the signatures. **Testability
without machinery** — price-time priority, self-trade prevention, partial-fill arithmetic are properties over
`decide` alone: feed a book state and a command, assert on the returned events; no process, no store, no mock, which
is what makes `StreamData` properties on the matching rules cheap enough to be exhaustive. **Replay as identity, not
feature** — fold `evolve` over the log and the book *is* its history; the Chapter 4.4 journal already gates exactly
this shape (replay reproduces live state), so milestone A inherits a certified mechanic rather than promising one.
**Audit as a property** — every fill is explainable as `decide(cmd, state_at_seq)`, and because sequence is the
branded mint order, "state at sequence" is a well-defined point, not a race.

One distinction worth pinning because the literature blurs it: this is **event** sourcing, not command sourcing. The
log stores `decide`'s *outputs* — the facts — not its inputs. Storing commands and re-deciding on replay couples
history to every past version of the rules; storing events makes replay a pure fold under `evolve`, which rarely
changes and changes safely. The platform logs facts.

### Alternatives weighed

**The mutating aggregate** (the classic OO shape: an entity with `apply` methods that validate and mutate in one
move). It works, and most of the industry runs on it; what it costs here is the seam — decision and mutation are one
body, so property-testing the rules drags the mutation machinery along, and replay requires the entity to be built
for it rather than getting it free. **Transaction-script validation over CRUD rows** — no fold, no replay, audit
reconstructed forensically from row diffs; disqualified by the audit requirement alone. **A process manager / saga as
the decision seat** — the right tool one level up (a workflow across aggregates reacting to events with new
commands), and the wrong tool for one book's rules: a saga that contains matching logic is a Decider wearing a
trench coat, with worse tests. **Actor state without events** (a plain GenServer mutating its own state, no log) —
the BEAM's default and a fine one for session state; it surrenders the fold law, and with it replay and audit, which
this domain cannot surrender.

### Where the Decider is the wrong tool, named

Cross-aggregate invariants — "this account's margin across all books" — do not belong inside one book's `decide`;
they are the saga's job, downstream of the log, with compensating events (the rule TRD.8 names). Long or effectful
work inside `decide` is not a smaller wrong but a category error: `decide` is pure by signature, and IO belongs at
the shell. And trivial administrative commands with no audit story can stay plain calls — the pattern earns its keep
where the fold law pays, not everywhere a command exists.

### The BEAM placement

The functional core, imperative shell, as the house already practices it: `Exchange.Decider` and
`Exchange.OrderBook` are pure modules; `Exchange.Book` is the GenServer shell that owns the process identity, drains
the ingress, calls `decide`, appends the events, folds `evolve`, and answers. The shell is thin enough to be boring,
which is the point — everything worth testing is underneath it, and everything worth supervising is the shell.

## Part two — the Disruptor

### The pattern, at its source

LMAX's published architecture centers a Business Logic Processor that runs entirely in memory by event sourcing and
handles "6 million orders per second on a single thread" [1], surrounded by Disruptors — pre-allocated ring buffers
where producers claim slots, a single writer applies in batches, and consumers chase sequence numbers without locks
[2]. The team's reported conclusion is the part that generalizes: contended queues are at odds with how modern CPUs
run, and the cure is the single-writer principle plus mechanical sympathy — one owner per mutable thing,
batch when behind, make waiting policy explicit [1][2].

### What transfers to the BEAM, and what does not

The BEAM cannot and should not imitate the Java mechanics — and does not need to, because the principles transfer
without them. **Transfers whole:** the bounded buffer with an explicit overload answer; the single writer applying in
batches; sequence as the coordination primitive; journaling beside the hot path so recovery is replay. **Does not
transfer, deliberately:** busy-spin wait strategies (a scheduler-hostile move on the BEAM; the Ring parks and the
wake is a message); cache-line padding and slot pre-allocation across process heaps (the win evaporates across heap
boundaries; the BEAM's copying semantics are the price of its isolation, already paid); and multi-consumer barriers
on the hot buffer itself — downstream consumers here read the *log*, never the ingress buffer, which keeps the Ring
a Disruptor seat and not a second bus.

The as-built seat is exact, not analogical: `EchoCache.Ring` is a bounded buffer whose `publish/2` answers `:ok` or
`:dropped` with the drop counted — admission control as a typed answer at the door — whose occupancy is observable,
and whose drain is single-consumer by construction, batch-shaped, with the largest batch drained already a reported
stat. The one twist this house adds to the pattern: the chase sequence is not a slot counter beside the data but the
branded Snowflake *inside* it. Mint order is the sequence, so a consumer's resume cursor is an id
(`EchoData.BrandedTree.page_after/4` reads strictly after it in creation order), the same order holds in every store
by the byte-sort theorem, and there is no second numbering scheme to reconcile with the first.

### Alternatives weighed

**The unbounded GenServer mailbox** — the BEAM default, and the proper baseline: it preserves order and the single
writer for free. What it lacks is an admission answer; overload arrives as mailbox depth, which arrives as latency,
which arrives as a page at 3 a.m. The Ring's `:dropped` is the same architecture with the truth told at the door.
**GenStage / Broadway** — demand-driven pull is the right shape where the consumer should set the pace: draining a
queue, consuming a stream, batching work — which is exactly where this platform uses that family's territory (the
Work side). It is the wrong shape at market ingress, where producers are external, the answer must be immediate
accept-or-shed, and a multi-stage pipeline adds hops to the path whose budget is microseconds. **A stream as the
ingress** (XADD first, decide later) — durable, replayable, and one wire round trip *before* every decision; LMAX
itself journals in the input disruptor, so the shape is principled, but it logs commands, not facts, and re-opens the
command-sourcing coupling above. This platform logs after `decide` — facts — and covers admission truth with the
Ring's counted drops instead. The trade is named: a command accepted-then-crashed before append is lost and the
caller knows nothing; the TRD.2 gate therefore reconciles publishes against applies-plus-drops, and the
acknowledge-after-append rule is the spec's law. **A hand-rolled atomics ring in a NIF** — regular-scheduler-legal
and unnecessary: the committed records put the BEAM-side costs (sub-microsecond codec, hundred-nanosecond resolves)
orders below the wire and the match work; buying nanoseconds with supervision-hostile machinery is the wrong end of
the budget.

### Where the Disruptor seat is the wrong tool, named

Low-rate aggregates — an admin book, a reference-data writer — gain nothing from a Ring over a plain call; the
pattern is for paths where overload is a *when*, not an *if*. Fan-out is never the Ring's job (one drainer, by law).
And durability is never the Ring's job either — the Ring may drop by design; the log may not lose by design; the two
truths are different and both are stated.

## The final choice

| Question | Choice | Because | Proven at |
|---|---|---|---|
| Where do the rules live | `Exchange.Decider`, pure, events out | properties without machinery; replay as a fold; audit as a corollary | TRD.2's price-time and single-writer properties |
| What is stored | facts (events), never commands | replay decoupled from rule versions | TRD.3's replay-equals-live gate |
| How do commands enter | `EchoCache.Ring`, one drainer per book | bounded, counted, batch-drained; overload is a typed answer | TRD.2's publishes = applies + drops reconcile |
| What is the sequence | the branded Snowflake, stamped at admission | one ordering across buffer, log, and every store; cursors are ids | the order theorem (Appendix F) re-gated on book data |
| Who reads the hot buffer | exactly one process; everyone else reads the log | the Ring stays ingress, the log stays the bus | the claims-only sweep, TRD.4 |
| When neither pattern | cross-aggregate workflows; trivial admin paths | sagas over the log; plain calls | the rule named at TRD.8 |

The pair composes into one sentence the specification can hold: *the Ring decides who gets in and in what order; the
Decider decides what it means; the log remembers; everything else reads.* Every claim above that is a number becomes
a committed record at its rung, and none is claimed before.

## References

1. Fowler, M. — The LMAX Architecture (the Business Logic Processor, in-memory event sourcing, the case against
   contended queues): [martinfowler.com/articles/lmax.html](https://martinfowler.com/articles/lmax.html)
2. Thompson, Farley, Barker, Gee, Stewart — Disruptor: High performance alternative to bounded queues (the technical
   paper: ring mechanics, sequences, batching, wait strategies):
   [lmax-exchange.github.io/disruptor/disruptor.html](https://lmax-exchange.github.io/disruptor/disruptor.html)
3. Chassaing, J. — Functional Event Sourcing Decider (the decide / evolve signatures, initial state, the
   command-sourcing distinction):
   [thinkbeforecoding.com/post/2021/12/17/functional-event-sourcing-decider](https://thinkbeforecoding.com/post/2021/12/17/functional-event-sourcing-decider)
