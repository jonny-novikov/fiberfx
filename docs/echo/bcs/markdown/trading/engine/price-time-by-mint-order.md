# B8.1.3 · Price-Time by Mint Order

> Dive 3 of B8.1 · route `/bcs/trading/engine/price-time-by-mint-order` · teaches `docs/trading/trading.specs.md`
> (the book as a price ladder, the single-writer reconcile) + the order theorem (Appendix F). **Grounding:**
> `Exchange.OrderBook` is the trading **engine** on top of a real substrate — **PROPOSED**: a pure price ladder,
> not built, not measured; its FIFO leans on the committed branded mint-order law (the byte-sort theorem). The
> substrate it stands on is real, shipped Elixir — `EchoCache.Ring` in the live umbrella
> (`echo/apps/echo_cache/lib/echo_cache/ring.ex`), hardened by the rung-gated EchoMQ program
> (`docs/echo_mq/emq.roadmap.md`), which names the trading platform as its downstream consumer. The single-writer
> reconcile is a **PROPOSED** gate (TRD.2), design-voiced, never asserted as measured. No engine number invented.

Price-time by mint order.

A matching engine resolves two crossing orders by **price-time priority**: best price first, and within a price,
the order that arrived first. This platform's order book gets the second half for free. `Exchange.OrderBook`
(**PROPOSED**, pure) is a price ladder per side — an ordered tree keyed by price, `gb_trees` per the house pattern
— and each level is a FIFO resolved by branded mint order, "so price-time priority falls out of the id law rather
than a comparator" (`docs/trading/trading.specs.md`). The comparator a book would otherwise write is replaced by
the ordering the id already carries.

The order book is **PROPOSED**: a design object, not a shipped module. It claims no fill count and no match
latency; those land at its rung.

Interactive 1 (hero): a price-ladder matcher over a fixed book. Two crossing orders meet a small fixed ladder; the
matcher fills them in price-time order, the within-level priority resolved by mint-ordered ids — the comparator
falling out of the id law, computed live.

## §1 The ladder, and why mint order is the comparator

The book is a price ladder per side: an ordered tree keyed by price (`gb_trees`), the bids descending and the asks
ascending, so the best price is a tree edge. Within one price level, orders queue in a FIFO — and the FIFO key is
the branded Snowflake stamped at admission. Mint order *is* arrival order, by construction, so "first at this
price" is "smallest id at this price," and the same order holds in SQLite, Valkey, and Postgres `COLLATE "C"`
alike by Appendix F's order theorem.

The consequence is a design with one ordering, not two: the sequence, the sort, the cursor, and the within-level
priority are the same fourteen bytes, paid for once at mint. A separate sequence counter beside each level would be
a second source of truth to keep in step with the first; the id removes it.

## §2 The open-order indexes ride the branded tree

Open-order indexes per account ride `EchoData.BrandedTree` — namespaced `gb_trees` with `first/2`, `last/2`, and
`page_after/4`, "the oldest-first and pagination shapes a book needs already its verbs"
(`docs/trading/trading.specs.md`). A book asks for the oldest open order, or the next page after a cursor, and the
branded tree answers in creation order without a sort step — the same `page_after/4` the ingress consumer uses to
resume from an id cursor in dive 1. Snapshots for projections freeze through the CHAMP / FrozenIndex family rather
than copying mutable maps.

Interactive 2: a single-writer reconcile — `publishes = applies + drops`. Over a fixed admission run, the readout
reconciles the Ring's accepted count against the Book's applied count plus the counted drops, the TRD.2 gate's
shape; crossing orders show as fills. This is a **PROPOSED** gate — it becomes a committed record at its rung — so
the readout reports the reconcile arithmetic, never a measured throughput.

## §3 The single-writer reconcile (a PROPOSED gate)

The master invariant binds the two halves of the engine: one instrument's book is mutated by exactly one process —
the sole drainer of its Ring — and the Ring's accepted count reconciles exactly with the Book's applied count plus
the counted drops (`docs/trading/trading.specs.md`). Crossing orders produce fills; the publishes that were
accepted equal the applies plus the drops, with nothing lost in between and nothing applied twice.

This is the TRD.2 gate, and it is **PROPOSED** — "the single-writer property under concurrent publishes" the
design will gate at the rung that ships the Book. The reconcile is the shape the harness will check, not a number
already on the record. The acknowledge-after-append rule is the spec's law: a command accepted then crashed before
its events are appended is lost and the caller knows nothing, so the gate reconciles publishes against
applies-plus-drops precisely to make that boundary visible.

## §4 The seat the engine fills — the ring, real and quoted

The reconcile stands on a real, hardened seat. `EchoCache.Ring` — shipped Elixir at
`echo/apps/echo_cache/lib/echo_cache/ring.ex`, the convergence target of the rung-gated EchoMQ program
(`docs/echo_mq/emq.roadmap.md`) that names the trading platform as its downstream consumer — already proves the
admission half of the arithmetic, its committed behavior on the B4.3 record (source:
`content/echo_data/runtimes/elixir/bcs_rung_4_3_check.out`, `PASS 6/6`): `64 accepted, 136 refused with :dropped
and counted -- never blocked, never overwritten -- then the release drained all 64 and publish 201 landed and
applied`. The accepted count, the counted drops, and the drained applies are the three terms the PROPOSED Book's
reconcile will balance — the Ring's record fixes the ingress side today; the Book's rung will fix the apply side.
The ring's surface declares its truth too: `a fresh ring stands at occupancy 0`.

That is the two-layer discipline in one paragraph: the seat is real, shipped, and quoted; the trading engine on
top — the `Exchange.*` writer that fills it — is PROPOSED and design-voiced; and no fill count, match latency, or
throughput is claimed for an engine that has run no rung yet, while the substrate beneath it already has its
numbers.

## References

Sources:

- The LMAX Disruptor — technical paper — https://lmax-exchange.github.io/disruptor/disruptor.html (sequences as the coordination primitive — the ordering the book's mint-keyed FIFO takes onto branded ids)
- Fowler — The LMAX Architecture — https://martinfowler.com/articles/lmax.html (the single-writer matching processor the reconcile gates)
- Chassaing — Functional Event Sourcing Decider — https://thinkbeforecoding.com/post/2021/12/17/functional-event-sourcing-decider (the events the reconcile counts are decide's outputs, not commands)

Related:

- /bcs/trading/engine — B8.1 · The Engine, the module hub
- /bcs/trading/engine/the-disruptor-seat — B8.1.1, the ingress whose accepted/dropped counts the reconcile balances
- /bcs/trading/engine/the-decider — B8.1.2, the pure core the book shells out to
- /bcs/cache/single-writer-ring — B4.3 · The Single Writer and the Ring, the as-built ring quoted here
- /bcs/cache — B4 · EchoCache, the chapter the ring and tables live in
- /elixir — Functional Programming in Elixir, the gb_trees and CHAMP cores the book is built on

Pager: previous `/bcs/trading/engine/the-decider` · next `/bcs/trading/engine` (back to the hub).
