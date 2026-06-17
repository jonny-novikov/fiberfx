# TRD.2.1 · The Pure Matching Core — OrderBook and Decider

<show-structure depth="2"/>

> First slice of rung TRD.2 ([`trd.2.specs.md`](trd.2.specs.md)). The quad: this chapter narrates;
> [`trd.2.1.specs.md`](trd.2.1.specs.md) is authoritative for the slice; the trd.2 stories
> ([`trd.2.stories.md`](trd.2.stories.md)) and runbook ([`trd.2.llms.md`](trd.2.llms.md)) cover the full rung, of
> which AS-1/AS-2/AS-5/AS-6/AS-7 are this slice's. Feedback edits the spec. **Status: PROPOSED.** Stands on TRD.1.1
> (the typed `{:place, …}` command, as-built) and the canon (the `FIL` mint, as-built). The stateful shell —
> `Exchange.Book`, the Ring drain, admission-reconcile, cancel, the per-account index — is **TRD.2.2**.

## Overview

TRD.2 is the matching engine; TRD.2.1 is its pure heart, shipped standalone. Two modules and no process: `Exchange.OrderBook`
is a price ladder per side — an ordered tree keyed by price, each level a FIFO resolved by branded mint order — and
`Exchange.Decider` is the matching rule as a pure function over events (`decide/2` returns the facts a command produces;
`evolve/2` folds one fact into the book). Two crossing orders fill at the maker's price; the remainder of a limit order
rests; a market order's remainder never rests; a same-account cross is rejected at the aggressor; no float ever appears;
every fill mints its own branded `FIL` id. Price-time priority is not coded — it falls out of the id law, the byte order
of the mint stamped at the Gateway. The whole slice is exhaustively property-testable without starting a single process.

## Rationale

TRD.2's design ([`trd.2.md`](trd.2.md)) reads two questions out of the Disruptor seat: *in what order, at what cost of
admission* (the Ring's question) and *what happens when a command meets the book* (the Decider's question). The first is
a concurrency-and-overload property of the stateful shell — one batching writer draining a bounded buffer, admission
answered at the door. The second is a property of a function — price-time priority, self-trade prevention, partial-fill
arithmetic — testable without a process or a store, replayable as a fold. **The two are separable, and separating them is
loss-free for the matching invariants.** The four named matching gates (a crossing pair fills at the maker price;
price-time priority holds; no float survives; a self-trade is prevented) are all expressible over `decide/2` alone. The
single-writer and admission-reconcile gates need the Book and the Ring, which add nothing to the matching rule itself.

So TRD.2.1 carves the function out and ships it first. This is the reductive cut: the smallest increment that proves the
matching rule correct, deferring the GenServer shell to a sibling rung where the concurrency and overload properties live.
A pure core also pays three ways at once — testability as a property rather than a feature, replay as a left fold over
emitted events, and an audit trail that *is* the event stream — and it pays them before any process exists to complicate
the proof.

The sequence that orders the book is not a counter beside the data — it is the branded id inside it. Mint order, stamped
at the Gateway (TRD.1), is price-time priority's time component, so the ladder needs no separate clock and no comparator
beyond the id's byte order. This is the Appendix F order theorem doing the matching engine's ordering for free, and it is
why `Exchange.Decider` can be pure modulo a single sanctioned effect: it reads no clock to break a tie, because the
maker's existing mint order already breaks it.

## Design

`Exchange.OrderBook` (pure) is a price ladder per side — an ordered tree keyed by price (`gb_trees`, the house pattern) —
each level a FIFO resolved by branded mint order, so price-time priority falls out of the id law. A resting entry carries
at least `{id, account, side, price, quantity}`: the `account` is **required**, because the matching rule must detect a
same-account cross (the self-trade rule, below) against a resting maker, and the maker's account is knowable only if the
ladder holds it. `new/0` is the empty book; `best/2` reads the top of a side — the best price and its level's FIFO, or
`:empty`. The slice builds the structure and its reads; the per-account `EchoData.BrandedTree` index a book needs for
cancel and pagination is **TRD.2.2**, not this rung.

`Exchange.Decider` (pure modulo the mint) is `decide(command, book) -> [event]` and `evolve(book, event) -> book`: the only
place matching rules live. `decide/2` handles the `:place` command (limit and market) — cross, partial-fill, rest a limit
remainder, reject — returning facts (`{:fill, …}`, `{:rested, …}`, `{:rejected, …}`) and never mutating. `evolve/2` folds
one fact into the book, and the book's state is exactly the fold of `evolve` over the events `decide` has emitted, in mint
order; there is no state reachable except through the fold (INV-4). The one sanctioned effect is the `FIL` id minted inside
`decide` at the instant a `:fill` is constructed — the same id-effect the Gateway is granted at TRD.1.1. A reviewer greps
`decider.ex` for `GenServer`, `:ets`, `System.monotonic_time`, `System.os_time`, and `Process.`, and the set is empty.

The matching rule, stated once and pinned in the spec: an aggressor crosses the opposite side in price-time order (best
price first; within a price, earliest mint order first), emitting one `:fill` per maker consumed, each at the **maker's**
price and each carrying its own branded `FIL` id. A **limit** order's unfilled remainder rests at its limit price; a
**market** order's remainder never rests — it cannot, being unpriced — so the unfilled remainder of a market order yields
a `{:rejected, …}` with the reason `:no_liquidity`. A cross against a resting order of the **same account** rejects the
**incoming** order in full — `{:rejected, %{order: <taker id>, reason: :self_trade}}` — leaving the book unchanged
(all-or-nothing; no partial fill against others ahead of the self-cross). The `:rejected` reason set is closed at
`:self_trade` and `:no_liquidity` — no other reason atom is emitted this rung.

## The five W's

**Why.** A pure decider gives testability, replay, and audit as properties rather than features, and it gives them before
a process exists to complicate the proof. Carving the function out of the stateful shell is loss-free for every matching
invariant the rung names — the cut that ships the proof soonest.

**What.** `Exchange.OrderBook` (the pure price-time ladder, `new/0` + `best/2`) and `Exchange.Decider` (pure `decide`/`evolve`,
events out) — matching two crossing orders into fill events at the maker's price, resting a limit remainder, rejecting a
self-cross and a market remainder, all over the typed `{:place, …}` command and `{units, nano}` money.

**Who.** The two modules (PROPOSED, this rung). Upstream: the Gateway (TRD.1.1, as-built — the typed command this rung
consumes). Downstream: the `Exchange.Book` that drives the Decider (TRD.2.2), and the Go pricing/risk workers that consume
the *fills* this rung emits. The Author ships the slice; the Operator has ruled the matching edge cases (self-trade =
reject the aggressor; the market remainder rejects `:no_liquidity`) in the settled forks.

**When.** First slice of the second rung of milestone A; stands on TRD.1.1 and the canon, both as-built — no unbuilt
dependency. The `EchoCache.Ring` and `EchoData.BrandedTree` exist in the tree but are TRD.2.2's to consume.

**Where.** `echo/apps/exchange/lib/exchange/{order_book,decider}.ex`, with tests under `echo/apps/exchange/test/exchange/`
and a gate script + committed transcript at `echo/rungs/exchange/trd_2_1_check.{exs,out}`, beside the TRD.1.1 gate.

## Deferred to TRD.2.2 (named, not built here)

The stateful shell is a sibling rung. This slice does **not** build, edit, or gate:

- **`Exchange.Book`** — the one GenServer per instrument that drains the Ring as the single writer (INV-1, gate G3,
  story AS-3). The Decider and the OrderBook this rung ships are the pure modules the Book will call.
- **The `EchoCache.Ring` drain + admission-reconcile** — the bounded buffer whose `publish/2` answers `:ok | :dropped`
  with the drop counted, drained in batches (INV-2, INV-7, gate G4, story AS-4). `EchoCache.Ring.{publish/2, occupancy/1,
  stats/1, start_link/1}` exist (`echo/apps/echo_cache/lib/echo_cache/ring.ex:38,62,68,85`) and are consumed there, not
  here.
- **Cancel-against-the-book** — matching a `:cancel` command against a resting order pairs with the Book's order
  lifecycle and the per-account index, → TRD.2.2. This rung matches `:place` only.
- **The per-account `EchoData.BrandedTree` index** — the oldest-first / pagination verbs a book needs for cancel and
  queries (`first/2`, `last/2`, `page_after/4`, `echo/apps/echo_data/lib/echo_data/branded_tree.ex:59,71,83`) — consumed
  by the Book, → TRD.2.2.
- **INV-1 (single writer), INV-2 (admission reconciles), INV-7 (overload is an answer)** — all three are properties of
  the Ring-draining Book; this rung holds INV-3/4/5/6 only.
- **Gates G3 (single writer), G4 (admission reconciles)** and stories **AS-3, AS-4** — they need the Book.

The deferral is the boundary the Director's Stage-3 reconcile verifies held: no `Exchange.Book`, no Ring code, no cancel
matching, no `BrandedTree` index in this rung's diff.

## The Go pricing seam, named (the contract this slice freezes)

The matching core is BEAM-only and pure — it must be, to stay testable and replayable. The money-math that surrounds
matching is the Go workers' tier: mark-to-market, margin and risk computation, analytics over fills — numeric work where
Go's throughput and GPU acceleration pay, and where the TInvest Go SDK is the venue client. The seam is the *event*: a
fill emitted by the Decider becomes a job the Go workers drain, carrying the fill's branded `FIL` id as the job key and
the `{units, nano}` money verbatim. The Decider never calls a worker — it returns a fact; the fact becomes work. TRD.2.1
fixes exactly the part of that contract a pure function can fix: **every `:fill` carries a branded `FIL` id (namespace
`"FIL"`, `valid?`) and integer `{units, nano}` money, so a downstream job is keyable and no float crosses the boundary.**
The job payload schema and the worker's idempotent-handler contract are a later rung's; this slice freezes only that the
fills are branded and the money is integer.

## Map

Authoritative spec: [`trd.2.1.specs.md`](trd.2.1.specs.md). The full rung: [`trd.2.md`](trd.2.md) ·
[`trd.2.specs.md`](trd.2.specs.md) · [`trd.2.stories.md`](trd.2.stories.md) · [`trd.2.llms.md`](trd.2.llms.md). Previous
rung (the door): [`trd.1.1.md`](trd.1.1.md) (the typed command this slice consumes). The patterns:
[`exchange.patterns.md`](exchange.patterns.md). The order theorem (mint order is price-time priority's time component):
Appendix F in `bcs.toc.md`. The Ring (TRD.2.2's to consume): Chapter 4.3 in `bcs.toc.md`.

## References

**External patterns.** The functional-event-sourcing *Decider* (Chassaing) —
[thinkbeforecoding.com/post/2021/12/17/functional-event-sourcing-decider](https://thinkbeforecoding.com/post/2021/12/17/functional-event-sourcing-decider)
— is the source of the `decide`/`evolve` shape this pure core takes (the stateful Book that drives it is the LMAX
single-writer ring, TRD.2.2 — [martinfowler.com/articles/lmax.html](https://martinfowler.com/articles/lmax.html)).
Commands arrive already typed via *Parse, don't validate* (TRD.1.1); the fills and money are grounded in the Tinkoff
Invest contract at [github.com/Tinkoff/investAPI](https://github.com/Tinkoff/investAPI), and the Go workers that price
them use [github.com/Tinkoff/invest-api-go-sdk](https://github.com/Tinkoff/invest-api-go-sdk).

**BCS.** `bcs.toc.md` Appendix F (the order theorem — mint order is price-time priority's time component, so the book
needs no clock and no comparator); Appendix G (the claim-check law the Go seam honors). The canon `contract/contract.md`
mints the `FIL` fill ids.
