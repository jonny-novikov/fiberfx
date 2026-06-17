# B8.1 · The Engine — Ring, Book, and Decider

> Module hub for `/bcs/trading/engine`, the first module of the capstone. Bootstrapped from the built B4 hub
> `single-writer-ring` — the ring it teaches *is* this engine's Disruptor seat. **Grounding posture (the B8
> rule):** two layers, never confused. The substrate is **real, shipped, tested Elixir**: `EchoCache.Ring` lives
> in the live umbrella at `echo/apps/echo_cache/lib/echo_cache/ring.ex` and is actively hardened by the
> rung-gated EchoMQ program (`docs/echo_mq/emq.roadmap.md`, "measured, rung-gated code"); its behavior is also on
> the committed B4.3 record (`content/bcs4.3.md`, `bcs_rung_4_3_check.out`, `PASS 6/6`), and every ring figure is
> verbatim from there, source-labelled. What is **PROPOSED** is only the trading **engine** that stands on the
> substrate — `Exchange.Book`, `Exchange.Decider`, `Exchange.OrderBook`, `Exchange.Gateway` (`docs/trading/`):
> taught in design voice, with no match, fill, or latency number, because the engine has run no rung yet. The
> substrate's numbers are real; the engine's are not yet (BCS.8-INV2).

## Hero

**B8.1 · The Engine — manuscript Part VIII, the trading corpus.** The hot path answers two questions, and they
are different questions.

The match path answers exactly two questions, and they are different (`docs/trading/trading.patterns.md`). **In
what order, and at what cost of admission** — a question of sequencing and overload, answered by a
**Disruptor-style ingress**: `EchoCache.Ring`, real umbrella source at
`echo/apps/echo_cache/lib/echo_cache/ring.ex`, a bounded buffer whose `publish/2` answers `:ok` or `:dropped`
with the drop counted. **What it means** when a command meets a book — a question of decision, answered by a
functional **Decider**: `decide` and `evolve`, pure, events out. The Ring exists, is tested, and is hardened; what
is **PROPOSED** is the trading engine on top of it — the Book and the Decider (`Exchange.*`), taught as design
because they have run no rung, never the substrate.

## The three shapes, narrowed to the engine

The capstone's rule is three messaging shapes, each served by the primitive built for it. The engine occupies the
first two seats: the **command** seat — one ordered stream per instrument, one writer — served by `EchoCache.Ring`
ingress draining into a pure Decider, sequence carried by the branded Snowflake stamped at admission; and the
read into the **event** log the Decider's facts land in, the subject of the next module. The engine's own
boundary is exact: the Ring is ingress, drained by one process; the log is the bus the rest of the platform
reads. The queue is never a log.

## The as-built seat — the ring, real and hardened

The engine invents nothing under the hot path. The Disruptor seat is `EchoCache.Ring` — real, shipped Elixir at
`echo/apps/echo_cache/lib/echo_cache/ring.ex`, whose surface is `publish/2` (`:ok`, or `:dropped` with the drop
counted when full), `occupancy/1` (tail minus head), `stats/1` (the counter snapshot plus occupancy,
`max_batch`, and `capacity`), `stop/1`, and `start_link/1`; its moduledoc states it in the house's own words:
"This is the Disruptor's shape translated to the BEAM — sequences, preallocated slots, batched consumption —
standing beside the bus's park-don't-poll: both replace discovery with arrival." The Ring, the bus, and the cache
are the convergence target of the rung-gated EchoMQ program (`docs/echo_mq/emq.roadmap.md`), and the trading
platform is named there as the program's downstream consumer — "the proposed `Exchange.*` suite standing on
exactly this tree; the program's named consumer." The Ring's committed behavior is on the B4.3 record, quoted
verbatim (source: `content/echo_data/runtimes/elixir/bcs_rung_4_3_check.out`, `PASS 6/6`):

```
G1 surface ok -- the ring's surface is whole -- publish, occupancy, stats, stop, a generic one-batch apply function -- and the declaration tells the truth: the broadcast table carries its ring name and capacity 512 in the directory, the :none table carries nil, and a fresh ring stands at occupancy 0
G4 full ok -- the bound held its shape: 64 accepted, 136 refused with :dropped and counted -- never blocked, never overwritten -- then the release drained all 64 and publish 201 landed and applied: a storm bends the lane's at-most-once contract no further than the contract already bends
G3 occupancy ok -- mid-storm the gauge read 600 of 4096 and drained to exactly 0; priced, the ring moved 100000 items in 99 ms -- 1005116 items per second end to end on one scheduler, inside the derived band, largest batch 200, nothing dropped
```

These are the **Ring's** committed numbers — the seat — real today. They are not the trading **engine's** numbers:
the `Exchange.*` suite that drains this Ring has run no rung yet, so its match, fill, and latency figures do not
exist, and the engine's first such number lands when its first rung's harness runs.

## The Disruptor's provenance

LMAX's published architecture centers a Business Logic Processor that runs in memory by event sourcing and handles
*"6 million orders per second on a single thread"* (Fowler), surrounded by ring buffers where producers claim
slots, a single writer applies in batches, and consumers chase a sequence. The figure is external and quoted with
its attribution; the engine takes the *principles*, not the Java mechanics. What transfers and what the BEAM
deliberately does not copy is the subject of dive 1.

## The three dives

- **B8.1.1 · The Disruptor Seat** — `the-disruptor-seat` — the Ring as bounded ingress: `publish/2` answers
  `:ok`/`:dropped`, the drop counted; one drainer; what transfers from LMAX and what the BEAM does not copy; the
  chase sequence is the branded Snowflake *inside* the data, read by `EchoData.BrandedTree.page_after/4`.
- **B8.1.2 · The Decider** — `the-decider` — the pure core `initialState` / `decide` / `evolve` (Chassaing);
  **event** sourcing, not command sourcing; testability, replay, and audit as corollaries of the signatures;
  functional core / imperative shell — `Exchange.Book` the GenServer shell, `Exchange.Decider` and
  `Exchange.OrderBook` pure (all PROPOSED); the alternatives weighed.
- **B8.1.3 · Price-Time by Mint Order** — `price-time-by-mint-order` — the order book as a price ladder per side
  over `gb_trees`, each level a FIFO resolved by branded mint order, so price-time priority falls out of the id
  law rather than a comparator; the single-writer reconcile (publishes equal applies plus counted drops), a
  PROPOSED gate.

## The doors

- **/echomq — EchoMQ, the protocol in depth** — the bus the log and the work lanes ride, and the rung-gated
  program (`docs/echo_mq/emq.roadmap.md`) that hardens this substrate, with the trading platform as its named
  consumer.
- **/redis-patterns — Redis Patterns Applied** — the substrate: the bounded ring, sorted sets, atomic Lua, the
  single-writer move.
- **/elixir — Functional Programming in Elixir** — the umbrella, and the functional core the Decider and the order
  book are written in.

## References

Sources:

- Fowler — The LMAX Architecture (the Business Logic Processor, the single-writer case, the ring that feeds it): https://martinfowler.com/articles/lmax.html
- The LMAX Disruptor — technical paper (the bounded ring, sequences, batching, wait strategies): https://lmax-exchange.github.io/disruptor/disruptor.html
- Chassaing — Functional Event Sourcing Decider (decide / evolve / initial state, the command-sourcing distinction): https://thinkbeforecoding.com/post/2021/12/17/functional-event-sourcing-decider

Related:

- /bcs/trading — B8 · The Trading System, the chapter landing
- /bcs/cache/single-writer-ring — B4.3 · The Single Writer and the Ring, the as-built Disruptor seat
- /bcs/cache — B4 · EchoCache, the cache and ring the engine admits through
- /bcs/bus — B3 · The Bus, the log and the work lanes
- /bcs/elixir-core — B2 · The Elixir BCS Core, the functional core the Decider is written in
- /echomq — EchoMQ, the protocol in depth
- /redis-patterns — Redis Patterns Applied, the substrate
- /elixir — Functional Programming in Elixir, the umbrella

Pager: previous `/bcs/trading` (B8 · The Trading System) · next `/bcs/trading/engine/the-disruptor-seat`.
