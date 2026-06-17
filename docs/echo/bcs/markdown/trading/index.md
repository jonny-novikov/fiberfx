# B8 · The Trading System — the capstone

> Chapter landing for `/bcs/trading`, the capstone. Orchestrator-authored; bootstrapped from the built B4
> chapter landing. **Grounding posture (the B8 rule):** the trading platform is a *design* — the Operator's
> corpus under `docs/trading/` (status **PROPOSED**) — taught in living-status voice; the primitives it composes
> are *as-built*, quoted from their committed BCS records. No platform figure is invented (BCS.8-INV2).

## Hero

**B8 · The Trading System — manuscript Part VIII.** The capstone: the proven primitives, assembled.

B1 gave every row a name, B2 gave the names a home, B3 put them in motion, B4 made reading them cheap. B8
assembles them into the worked project the whole series has pointed at — a trading platform on the as-built tree.
The design is the Operator's, written in `docs/trading/`; its status is **PROPOSED**, and it states its own law:
*"Nothing here is a record — the first rung's harness produces the first number this platform may ever claim."*
This chapter teaches that design — and quotes the committed floor it stands on, never a number the platform has
not yet earned.

## The four jobs that pull apart

A trading platform has four jobs that pull in different directions (`docs/trading/trading.md`): **sequence**
commands per instrument with a guarantee no lock gives as cheaply as a single writer; hold a **latency** budget
in microseconds on the match path; stay **durable and auditable** — every fill explainable as a fold over facts;
and **fan out and follow up** — ticks to many readers, settlement and risk as retriable work. The classic failure
is answering all four with one primitive: a queue pressed into a log, a log pressed into a bus, a bus carrying
objects. The design rule is the opposite — **three messaging shapes, each served by the primitive built for it.**

## The three shapes

| Shape | Carries | Served by (as-built unless marked PROPOSED) |
|---|---|---|
| Command / sequencing | one ordered command stream per instrument, one writer | `EchoCache.Ring` ingress → `Exchange.Book` (PROPOSED) draining a pure Decider; sequence is branded mint order |
| Event / fan-out | facts emitted once, read by many, replayable | the claim-check bus (Appendix G) for fan-out; the Journal (B4.4) then per-instrument stream lanes for the log |
| Work | retriable follow-ups: settlement, risk, reporting | `EchoMQ.Jobs` / `Lanes` / `Consumer` — fair per-venue lanes (B3.4) |

## The master invariant (the design's law)

> One instrument's book is mutated by exactly one process — the sole drainer of that instrument's Ring — and its
> state is reconstructable as a fold over an append-only event log. Sequence is mint order. Every primitive keeps
> its role — the queue is never a log, the log is never a fan-out bus, the bus never carries an object (claims
> only). Nothing on any hot path runs heavier than regular-scheduler work. Every id is branded and refused at the
> wrong door.

## The four modules

- **B8.1 · The Engine — Ring, Book, and Decider** — `engine` — the hot path: the Disruptor seat
  (`EchoCache.Ring` ingress, bounded `publish/2`, counted drops), the single-writer Book draining a pure Decider,
  price-time priority falling out of the id law.
- **B8.2 · The Log and the Ledger** — `log-and-ledger` — the memory: one `EchoCache.Journal` per book under a
  pluggable Shadow, replay equals live, double-entry settlement in Postgres, idempotent projections.
- **B8.3 · Strategies as Deciders** — `strategies` — the layer above: a strategy is a Decider emitting intents;
  the four-stage pipeline; risk as gating deciders and the kill switch that is already a lane verb; the backtest
  is the live system replayed.
- **B8.4 · Fan-Out and the Scale-Out** — `scale-out` — claims-only on the bus, placement by the audited hash,
  CP matching and AP market data on partition, the cross-shard saga.

## The three milestones (`docs/trading/trading.roadmap.md`)

- **A · the walking skeleton** (TRD.1–TRD.5) — submit an order, watch it match in a Ring-fed single-writer book,
  replay the book from its Journal, read a position at hit speed, see the fill posted double-entry, watch
  settlement drain a fair lane. No unbuilt dependency — every component it stands on carries a committed record.
- **B · the durable core** (TRD.6) — replay any instrument from a per-instrument stream lane; attach a polyglot
  risk consumer through a consumer group. Gates on the connector's stream rungs (Appendix H, conn.1–conn.2).
- **C · the scale-out** (TRD.7–TRD.8) — place books across nodes by the audited hash, lose a node and watch a
  book hand off under the CP rule, flood a venue and watch the others hold.

## The floor under the floor (as-built, committed)

The platform invents nothing under the hot path — it composes primitives this course has already taught from
frozen records. The committed records B8 stands on (`content/echo_data/runtimes/elixir/`):

- `bcs_rung_3_4_check.out` — fair lanes (rotation, pause/resume/limit — the kill switch) — `PASS 8/8`
- `bcs_rung_4_1_check.out` — cache-aside at ETS speed (the read path) — `PASS 6/6`
- `bcs_rung_4_3_check.out` — the single-writer ring (the ingress buffer) — `PASS 6/6`
- `bcs_rung_4_4_check.out` — the journal (append, dedup, fold-to-state replay) — `PASS 6/6`
- `bcs_hash_audit.out` — the cross-runtime `hash32` placement function — `PASS 4/4`

The claim check (`content/bcsG.md`, Appendix G) and the connector referee (`content/bcsH.md`, Appendix H) are the
two further committed records the bus and the wire stand on.

## The doors

- **/echomq — EchoMQ, the protocol in depth** — the bus the work lanes and the log ride.
- **/redis-patterns — Redis Patterns Applied** — the substrate: the ring, the sorted sets, atomic Lua.
- **/elixir — Functional Programming in Elixir** — the umbrella, and the decider/strategy functional core.

## References

Sources:

- Fowler — The LMAX Architecture (the Business Logic Processor, the single-writer case): https://martinfowler.com/articles/lmax.html
- Thompson, Farley, Barker, Gee, Stewart — The Disruptor (the bounded ring, sequences, batching): https://lmax-exchange.github.io/disruptor/disruptor.html
- Chassaing — Functional Event Sourcing Decider (decide / evolve / initial state): https://thinkbeforecoding.com/post/2021/12/17/functional-event-sourcing-decider

Related:

- /bcs — BCS, the course home: the law, the id anatomy, the chapter map
- /bcs/cache — B4 · EchoCache, the cache and ring the engine reads and admits through
- /bcs/bus — B3 · The Bus, the work lanes and the log
- /echomq — EchoMQ, the protocol in depth
- /redis-patterns — Redis Patterns Applied, the substrate
- /elixir — Functional Programming in Elixir, the umbrella
