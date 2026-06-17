# B8.1.1 · The Disruptor Seat

> Dive 1 of B8.1 · route `/bcs/trading/engine/the-disruptor-seat` · teaches `docs/trading/trading.patterns.md`
> Part two (the Disruptor) + `docs/trading/trading.specs.md` (the Disruptor seat, named precisely). **Grounding:**
> the seat is `EchoCache.Ring` — **real, shipped, tested Elixir** at
> `echo/apps/echo_cache/lib/echo_cache/ring.ex`, actively hardened by the rung-gated EchoMQ program
> (`docs/echo_mq/emq.roadmap.md`); every ring figure verbatim from `bcs_rung_4_3_check.out` (`PASS 6/6`),
> source-labelled. The drainer `Exchange.Book` (the trading engine on top) is **PROPOSED**. The LMAX figure is
> external, quoted with attribution to Fowler. No engine number invented.

The Disruptor seat.

The ingress half of the engine answers one question: in what order, and at what cost of admission.
`EchoCache.Ring` is the seat — real, shipped Elixir at `echo/apps/echo_cache/lib/echo_cache/ring.ex`, a bounded
buffer whose `publish/2` answers `:ok` or `:dropped` with the drop counted, drained by exactly one process.
Admission control is a typed answer at the door rather than an incident discovered as latency. The committed gate
fixes the shape: `64 accepted, 136 refused with :dropped and counted -- never blocked, never overwritten`.

Source: the Ring is real umbrella source at `echo/apps/echo_cache/lib/echo_cache/ring.ex` — its surface is
`publish/2`, `occupancy/1`, `stats/1`, `stop/1`, `start_link/1`, two atomics carry the tail/head sequences, an
ETS table the preallocated slots — and its behavior is on the committed B4.3 record (`content/bcs4.3.md`,
`content/echo_data/runtimes/elixir/bcs_rung_4_3_check.out`). The Ring, the bus, and the cache are the convergence
target of the rung-gated EchoMQ program (`docs/echo_mq/emq.roadmap.md`), and the trading platform is named there
as the program's downstream consumer — "the proposed `Exchange.*` suite standing on exactly this tree; the
program's named consumer." The drainer that sits in front of the Ring, `Exchange.Book`, is **PROPOSED**
(`docs/trading/trading.specs.md`).

Interactive 1 (hero): a ring-admission simulator over a fixed capacity of 64 — `publish` answers `:ok` until the
ring is full, then `:dropped` with a running count, mirroring the committed `64 accepted, 136 refused` shape; a
drain releases the held applier and the next publish lands. The readout computes accepted, refused, and occupancy
by the structure's own arithmetic.

## §1 The pattern, at its source

LMAX's published architecture centers a Business Logic Processor that runs entirely in memory by event sourcing
and handles *"6 million orders per second on a single thread"* (Fowler), surrounded by Disruptors — pre-allocated
ring buffers where producers claim slots, a single writer applies in batches, and consumers chase sequence numbers
without locks. The team's reported conclusion is the part that generalizes: contended queues are at odds with how
modern CPUs run, and the cure is the single-writer principle plus mechanical sympathy — one owner per mutable
thing, batch when behind, make waiting policy explicit.

The 6-million figure is external and quoted with its attribution. It is not a number the trading engine claims;
the `Exchange.*` suite on top of the Ring has run no rung yet. The Ring itself is real and measured — its numbers
are on the B4.3 record.

## §2 What transfers to the BEAM, and what does not

The BEAM cannot and should not imitate the Java mechanics — and does not need to, because the principles transfer
without them.

**Transfers whole:** the bounded buffer with an explicit overload answer; the single writer applying in batches;
sequence as the coordination primitive; journaling beside the hot path so recovery is replay.

**Does not transfer, deliberately:** busy-spin wait strategies — a scheduler-hostile move on the BEAM; the Ring
parks and the wake is a message; cache-line padding and slot pre-allocation across process heaps — the win
evaporates across heap boundaries, and the BEAM's copying semantics are the price of its isolation, already paid;
and multi-consumer barriers on the hot buffer itself — downstream consumers read the *log*, never the ingress
buffer, which keeps the Ring a Disruptor seat and not a second bus.

Interactive 2: a transfer table — toggle each LMAX element between *transfers whole* and *does not transfer
(deliberately)* and read why, drawn from `docs/trading/trading.patterns.md`.

## §3 The seat is exact, not analogical

The seat is real source, and it matches the pattern part for part. The moduledoc names the correspondence in the
house's own words (source: `echo/apps/echo_cache/lib/echo_cache/ring.ex`): "This is the Disruptor's shape
translated to the BEAM — sequences, preallocated slots, batched consumption — standing beside the bus's
park-don't-poll: both replace discovery with arrival," and "the single-producer requirement is structural, not
advisory." The committed B4.3 record carries the shape in numbers (source: `bcs_rung_4_3_check.out`). The bound is
real: `the bound held its shape: 64 accepted, 136 refused with :dropped and counted -- never blocked, never
overwritten -- then the release drained all 64 and publish 201 landed and applied`. The gauge is observable:
`mid-storm the gauge read 600 of 4096 and drained to exactly 0`. The drain is single-consumer and batch-shaped,
with the largest batch a reported stat: `largest batch 200, nothing dropped`. The ring under storm refuses,
recovers, and keeps serving — which is exactly the admission contract a match path needs.

The `Exchange.Book` that drains it is **PROPOSED**: the single writer, woken to drain whole batches, shelling out
to a pure Decider. It is the trading engine on top of a real, hardened substrate — taught as design because it has
run no rung, and so it claims no number; the Ring beneath it is shipped and measured.

## §4 The chase sequence is the id

The one twist this house adds to the pattern: the chase sequence is not a slot counter beside the data but the
branded Snowflake *inside* it. Mint order is the sequence, so a consumer's resume cursor is an id —
`EchoData.BrandedTree.page_after/4` reads strictly after it in creation order — the same order holds in every store
by the byte-sort theorem, and there is no second numbering scheme to reconcile with the first. A counter beside the
data is a second source of truth; the id is the first one, already paid for at mint.

## §5 Alternatives weighed, and where the seat is wrong

The pattern earns its keep against the alternatives, named honestly (`docs/trading/trading.patterns.md`). **The
unbounded GenServer mailbox** — the BEAM default and the proper baseline: it preserves order and the single writer
for free; what it lacks is an admission answer, so overload arrives as mailbox depth, which arrives as latency.
The Ring's `:dropped` is the same architecture with the truth told at the door. **GenStage / Broadway** —
demand-driven pull is the right shape where the consumer sets the pace (draining work), and the wrong shape at
market ingress, where producers are external and the answer must be immediate accept-or-shed. **A stream as the
ingress** (XADD first, decide later) — durable and replayable, but one wire round trip before every decision, and
it logs commands, not facts, re-opening the command-sourcing coupling the next dive names.

Where the seat is the wrong tool, stated: low-rate aggregates — an admin book, a reference-data writer — gain
nothing from a Ring over a plain call; fan-out is never the Ring's job (one drainer, by law); and durability is
never the Ring's job either — the Ring may drop by design, the log may not lose by design, and the two truths are
different and both stated.

## References

Sources:

- Fowler — The LMAX Architecture — https://martinfowler.com/articles/lmax.html (the Business Logic Processor, the single-thread figure quoted, the case against contended queues)
- The LMAX Disruptor — technical paper — https://lmax-exchange.github.io/disruptor/disruptor.html (the bounded ring, sequences, batching, wait strategies — the pattern the seat fills)
- Chassaing — Functional Event Sourcing Decider — https://thinkbeforecoding.com/post/2021/12/17/functional-event-sourcing-decider (the fact-vs-command distinction the stream-as-ingress alternative trips on)

Related:

- /bcs/trading/engine — B8.1 · The Engine, the module hub
- /bcs/cache/single-writer-ring — B4.3 · The Single Writer and the Ring, the as-built ring quoted here
- /bcs/cache — B4 · EchoCache, the chapter the ring lives in
- /bcs/bus — B3 · The Bus, the log downstream consumers read instead of the ring
- /redis-patterns — Redis Patterns Applied, the bounded-ring substrate
- /echomq — EchoMQ, the protocol in depth

Pager: previous `/bcs/trading/engine` (the hub) · next `/bcs/trading/engine/the-decider`.
