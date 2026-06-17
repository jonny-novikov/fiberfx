# TRD.2 · The Book — One Ring, One Writer, One Pure Decider

<show-structure depth="2"/>

> Rung TRD.2 of the trading suite ([`exchange.specs.md`](exchange.specs.md)). The quad: this chapter narrates;
> [`trd.2.specs.md`](trd.2.specs.md) is authoritative; [`trd.2.stories.md`](trd.2.stories.md) holds the acceptance
> stories for both audiences; [`trd.2.llms.md`](trd.2.llms.md) is the agent runbook. Feedback edits the spec.
> **Status: PROPOSED.** Stands on TRD.1 (typed commands) and the as-built `EchoCache.Ring` (Chapter 4.3).

## Overview

TRD.2 is the matching engine, and it is where the Disruptor seat stops being an analogy. An instrument's commands
enter a bounded `EchoCache.Ring`; exactly one process — `Exchange.Book` — drains that Ring in batches; for each
command it consults a pure `Exchange.Decider` that returns events (fills, rests, rejects); the Book folds those
events into a pure `Exchange.OrderBook` and answers the caller. The Ring decides who gets in and in what order; the
Decider decides what it means; the book state is a fold. No lock, no second writer, no float, and overload answered
at the door as `:dropped` rather than discovered downstream as latency.

## Rationale

Two questions, two patterns ([`exchange.patterns.md`](exchange.patterns.md)). **In what order, at what cost of
admission** is the Ring's question: a bounded buffer whose `publish/2` answers `:ok` or `:dropped` with the drop
counted, drained by one consumer in batches. This is the single-writer principle the LMAX architecture is built on,
translated to the BEAM — the parts that transfer (bounded buffer, one batching writer, sequence as coordination,
journaling beside the path) kept, the parts that do not (busy-spin, shared-heap slot pre-allocation, multi-consumer
barriers on the hot buffer) deliberately dropped. **What happens** when a command meets the book is the Decider's
question, and it is pure: price-time priority, self-trade prevention, partial-fill arithmetic are properties over a
function, testable without a process or a store, replayable as a fold.

The sequence is not a counter beside the data — it is the branded id inside it. Mint order (stamped at the Gateway,
TRD.1) is price-time priority's time component, so the book needs no separate clock and no comparator beyond the id's
byte order. This is the Appendix F property doing the matching engine's ordering for free.

## Design

`Exchange.Book` is one GenServer per instrument — the sole drainer of that instrument's Ring, by construction the
single writer of that instrument's state. It is woken to drain whole batches (the Ring already reports its largest
batch drained); for each command in a batch it calls `Exchange.Decider.decide/2`, appends the returned events to its
running log, folds them through `Exchange.OrderBook`, and replies. The Book is a thin shell: process identity, the
drain loop, the reply. Everything worth testing is beneath it.

`Exchange.OrderBook` (pure) is a price ladder per side — an ordered tree keyed by price (`gb_trees`, the house
pattern) — each level a FIFO resolved by branded mint order, so price-time priority falls out of the id law. Open
orders per account index through `EchoData.BrandedTree` (`first/2`, `last/2`, `page_after/4` — the oldest-first and
pagination verbs a book needs are already there).

`Exchange.Decider` (pure) is `decide(command, state) -> [event]` and `evolve(state, event) -> state`: the only place
matching rules live, returning facts (`{:fill, ...}`, `{:rested, ...}`, `{:rejected, reason}`) and never mutating.
The Book stores the facts and folds them; the facts are the audit trail and the replay source.

Admission is the gate's headline property: under concurrent submits, the Ring's accepted count reconciles exactly
with the Book's applied count plus the counted drops — every command is matched, rested, or dropped-and-counted, none
silently lost. A flood answers `:dropped` at the door, observably, instead of swelling a mailbox.

## The five W's

**Why.** A single writer per instrument gives sequencing no lock can match as cheaply; a pure decider gives
testability, replay, and audit as properties rather than features; a bounded ring gives overload a typed answer
instead of an unbounded mailbox and a 3 a.m. page.

**What.** `Exchange.Book` (the Ring drainer and single writer), `Exchange.OrderBook` (the pure price-time ladder),
`Exchange.Decider` (pure `decide`/`evolve`, events out) — matching two crossing orders into fill events, resting the
remainder, rejecting what cannot stand, all over typed commands and `{units, nano}` money.

**Who.** The three modules (PROPOSED, this rung). Upstream: the Gateway (TRD.1). Downstream: the log and projections
(TRD.3–TRD.5), and the Go pricing/risk workers that consume the *fills* this rung emits. The Author ships the quad;
the Operator rules the matching edge cases (self-trade, partial fills).

**When.** Second rung of milestone A; stands on TRD.1 and the as-built Ring and BrandedTree — no unbuilt dependency.

**Where.** `runtimes/elixir/lib/exchange/{book,order_book,decider}.ex`, with a gate script and committed transcript
beside the other rung gates. The Ring is `EchoCache.Ring` (Chapter 4.3), used, not rebuilt.

## The Go pricing seam, named

The matching core is BEAM-only and pure — it must be, to stay testable and replayable. The money-math that surrounds
matching is the Go workers' tier: mark-to-market, margin and risk computation, analytics over fills — numeric work
where Go's throughput and GPU acceleration pay, and where the TInvest Go SDK is the venue client. The seam is the
*event*: a fill emitted by the Decider becomes a job the Go workers drain (settlement, pricing, risk), carrying the
fill's branded id as the job key and the `{units, nano}` money verbatim. The Decider never calls a worker — it
returns a fact; the fact becomes work. This keeps the hot path pure and the heavy math off the BEAM, joined only by a
claim-keyed job. The job payload is specified at the worker rung; this rung fixes that fills carry branded ids and
integer money so that boundary is frozen.

## Map

Authoritative spec: [`trd.2.specs.md`](trd.2.specs.md). Stories: [`trd.2.stories.md`](trd.2.stories.md). Runbook:
[`trd.2.llms.md`](trd.2.llms.md). Previous rung (the door): [`trd.1.md`](trd.1.md). The patterns:
[`exchange.patterns.md`](exchange.patterns.md). The Ring: Chapter 4.3 in `bcs.toc.md`.

## References

**External patterns.** The LMAX architecture (Fowler) — [martinfowler.com/articles/lmax.html](https://martinfowler.com/articles/lmax.html) — and the Disruptor technical paper — [lmax-exchange.github.io/disruptor/disruptor.html](https://lmax-exchange.github.io/disruptor/disruptor.html) — are the source of the single-writer ring seat this rung translates to the BEAM (bounded buffer, one batching writer, sequence as coordination), with the parts that do not transfer named in [`exchange.patterns.md`](exchange.patterns.md). The functional-event-sourcing *Decider* (Chassaing) — [thinkbeforecoding.com/post/2021/12/17/functional-event-sourcing-decider](https://thinkbeforecoding.com/post/2021/12/17/functional-event-sourcing-decider) — is the source of the `decide`/`evolve` shape the matching core takes. Commands arrive already typed via *Parse, don't validate* (TRD.1); the fills and money are grounded in the Tinkoff Invest contract at [github.com/Tinkoff/investAPI](https://github.com/Tinkoff/investAPI), and the Go workers that price them use [github.com/Tinkoff/invest-api-go-sdk](https://github.com/Tinkoff/invest-api-go-sdk).

**BCS.** `bcs.toc.md` Chapter 4.3 (the as-built `EchoCache.Ring` — bounded `publish/2` answering `:ok` or `:dropped`, counted drops, the largest batch drained); Appendix F (the order theorem — mint order is price-time priority's time component, so the book needs no clock and no comparator); Appendix G (the claim-check law); Chapter 4.4 (the journal's fold-to-state replay, the posture TRD.3 stands the book's recovery on). The canon `contract/contract.md` mints the `FIL` fill ids.

**Redis-patterns course.** The keyspace and hash-tag conventions the downstream log and lanes apply; the course is the series' patterns reference for the Valkey-resident structures the book's events flow into past this rung.

**echo_mq.** The as-built lanes and jobs (`emq2.specs.md`, BCS Chapter 3.4) the emitted fills feed as settlement, pricing, and risk work; the stream tier `emq3.specs.md`, the durable log the book's events retarget to at TRD.6.
