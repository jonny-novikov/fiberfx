# TRD · System Specification

<show-structure depth="2"/>

Status: **PROPOSED — a draft for Operator review.** This is the system specification of the platform fronted by
[`exchange.md`](exchange.md) (rationale, five W's, why this shape) and delivered by
[`exchange.roadmap.md`](exchange.roadmap.md); the two patterns under the hot path are argued in
[`exchange.patterns.md`](exchange.patterns.md). No module is cited below unless it exists in this repository with a
committed record; everything new is marked PROPOSED. Nothing in this file is a record — it is what the rungs will be
authored against, and feedback edits this file, not an implementation.

## The master invariant

> One instrument's book is mutated by exactly one process — the sole drainer of that instrument's Ring — and its state
> is reconstructable as a fold over an append-only event log. Sequence is mint order: every command carries a branded
> Snowflake stamped at admission, and no ordering claim exists apart from it. Every primitive keeps its role — the
> queue is never a log, the log is never a fan-out bus, the bus never carries an object (claims only, the Appendix G
> law) — and nothing on any hot path runs heavier than regular-scheduler work (the Appendix H rule). Every id is
> branded and refused at the wrong door.

Mechanics, gated at the rung that ships each part: a single-writer property under concurrent publishes — the Ring's
accepted count reconciles exactly with the Book's applied count plus the counted drops; the replay property — folding
the log reproduces live state, the Chapter 4.4 posture re-gated per book; and the claims-only sweep on every bus
payload.

## Components

PROPOSED, this suite's to build: `Exchange.Gateway` (parse once, typed commands, closed errors, ids minted at the
edge), `Exchange.Book` (the single writer, sole drainer of its Ring), `Exchange.OrderBook` and `Exchange.Decider`
(pure cores the Book shells out to), `Exchange.Projection` (idempotent log consumers into Tables),
`Exchange.Placement` (milestone C's consistent ring), `Trading.Ledger` (double-entry postings).

As-built, adopted whole: `EchoCache.Ring` (the ingress buffer), `EchoCache.Journal` under `EchoCache.Shadow`
(the milestone-A log and its replica), `EchoCache.Table` and `EchoCache.Coherence` (reads and fan-out),
`EchoMQ.Jobs` / `Lanes` / `Consumer` (work), `EchoData.*` (the canon), all over `EchoMQ.Connector` via the `EchoWire`
facade.

## The Disruptor seat, named precisely

The LMAX shape is a pre-allocated bounded buffer, one writer applying in batches, consumers chasing a sequence. The
BEAM translation this platform takes, on as-built parts: `EchoCache.Ring` is the bounded buffer with explicit loss
semantics — `publish/2` answers `:dropped` when full and the drop is counted, so admission control is a typed answer
at the door rather than an incident discovered as latency; `Exchange.Book` is the one writer, woken to drain whole
batches (the Ring's stats already report the largest batch drained); and the chase sequence is not a counter beside
the data but the branded Snowflake inside it — any consumer at any layer resumes from an id cursor, which
`EchoData.BrandedTree.page_after/4` serves in creation order. What this deliberately does not copy from LMAX:
busy-spin waiting (the BEAM parks; the wake is a message) and multi-consumer barriers on the hot buffer (downstream
consumers read the log, never the Ring — the Ring is ingress only, drained by exactly one process, which is what
keeps it a Disruptor seat and not a second bus). The full argument, with alternatives weighed, is
[`exchange.patterns.md`](exchange.patterns.md).

## Data structures

**Ids are the spine.** Order (`ORD`), fill (`FIL`), command (`CMD`), event version (`TXN`), account (`ACC`),
instrument (`INS`) — minted at the edge, validated at every door, byte-ordered by mint time so every store sorts by
time for free (Appendix F's order theorem, held in SQLite, Valkey, and Postgres `COLLATE "C"` alike).

**The book (pure core, PROPOSED).** `Exchange.OrderBook`: a price ladder per side — an ordered tree keyed by price,
`gb_trees` per the house pattern — each level a FIFO resolved by branded mint order, so price-time priority falls out
of the id law rather than a comparator. Open-order indexes per account ride `EchoData.BrandedTree` (namespaced
`gb_trees` with `first/2`, `last/2`, and `page_after/4` — the oldest-first and pagination shapes a book needs are
already its verbs). Snapshots for projections freeze through the CHAMP / FrozenIndex family rather than copying
mutable maps.

**The log.** Milestone A: one `EchoCache.Journal` per book — append-only events, dedup at admission, fold-to-state
replay, `busy_timeout` hardened — under a pluggable `EchoCache.Shadow`: Litestream to object storage in production,
the Copy shadow on a development laptop, the same contract either way. Milestone B: the log moves to per-instrument
stream lanes (hash-tagged `XADD`, consumer groups for risk and polyglot readers) per conn.1–conn.2 of
`bcsH.specs.md` — the recorded dependency; the Journal keeps its as-built role on the consumer side,
idempotency and replay for projections and settlement.

**The bus.** Claims only: `Coherence.payload(id, version)` — twenty-nine bytes whatever the object weighs; consumers
resolve through a term cache keyed by the immutable `(id, version)` pair, constant-time warm with no invalidation
story (Appendix G, measured). Market-data fan-out is the coherence broadcast and, for read-registered consumers,
RESP3 tracking on the same connection (Chapter 4.5's lag rows are the budget).

**The read path.** Positions, balances, reference data: `EchoCache.Table` declared per kind, loader-backed, one fill
per herd, newer-wins by mint order — the committed 4.1–4.2 behavior, unmodified.

**The regulated ledger.** Double-entry in Postgres, branded id columns under the SQL canon with the domain's reject
table as the floor, every posting one `Ecto.Multi`. The stream (B) is the source of truth for *unsettled* state; the
Postgres ledger is the regulated record of *settled* positions — decided in that direction here, revisitable only by
editing this specification.

## Jobs

Settlement, notifications, end-of-day reporting, reconciliation: `EchoMQ.Jobs` with branded job ids, drained by
`EchoMQ.Consumer`, shaped by `EchoMQ.Lanes` with one group per venue — pause, resume, per-group limits, and depth
behind one identity are committed behavior (Chapter 3.4), so the fairness story is adopted, not promised. Batched
settlement maps to the as-built one-flush pipeline posture (Appendix E's batch rows) until a batching rung earns its
own record; scheduled and repeatable jobs remain the EchoMQ roadmap's 2.1 row, with this platform's needs recorded
there as an input.

## Placement and partitions (milestone C)

`Exchange.Placement` (PROPOSED): a consistent ring over `EchoData.BrandedId.hash32/1` — the hash whose cross-runtime
agreement is an audited record — mapping instrument ids to owning nodes; data co-location already follows `Keyspace`
hash tags, so a book's keys live in one slot by construction. On partition: matching is CP — orders for a book whose
owner is unreachable are refused rather than risking a split-brain ladder; market data is AP — a stale tick is served
and marked. The full per-subsystem table is fixed at TRD.7's rung, not assumed here. Cross-shard trades are a saga
over the event log with compensating events — the rule is named at TRD.8 and built only when a real instrument pair
needs it.

## Seams and open decisions

Stream retention (`MAXLEN` versus `MINID`, decided by the compliance window at TRD.6); the log-tier boundary (a
partitioned-log adoption was examined and rejected — the record is Appendix I, `bcsI.md` — and the trigger
stays named there with nothing pre-built);
FLAME-style ephemeral execution of Work consumers (a seam the journal-beside-consumer pattern already permits); and
the canonical-store seam for unsettled state, decided above in the stream's favor.

## Map

Front door: [`exchange.md`](exchange.md). Ladder: [`exchange.roadmap.md`](exchange.roadmap.md). Patterns:
[`exchange.patterns.md`](exchange.patterns.md). Records: `bcs.toc.md`, the claim check
(`bcsG.md`), the connector referee (`bcsH.md`), the connector's forward specification
(`bcsH.specs.md`).
