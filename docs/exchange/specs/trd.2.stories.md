# TRD.2 · Stories — the Book

<show-structure depth="2"/>

> Acceptance stories for rung TRD.2, two audiences. **Developer stories** for a human engineer; **Agent stories** for
> a Claude agent under the house loop — third person, no gendered pronouns, no perceptual or interior-state verbs, no
> first-person narration. Both trace to the invariants and gates in [`trd.2.specs.md`](trd.2.specs.md). **Status:
> PROPOSED.**

## Developer stories

**DS-1 — two orders match.** As a desk, I place a buy that crosses a resting sell, and I see a fill at the resting
order's price for the matched quantity, with the remainder of the larger order resting on the book. *Acceptance:* a
crossing pair produces a `:fill` at the maker's price with a branded `FIL` id and a `:rested` remainder (G1).

**DS-2 — fairness is price-time.** As a market participant, I trust that the best price fills first and, at one price,
the order that arrived first fills first — no reordering, no favoritism. *Acceptance:* price-time priority holds as a
property over the Decider (G2).

**DS-3 — overload is answered, not hidden.** As an operator, when order flow exceeds what an instrument can absorb, I want the
system to refuse at the door and count the refusals, not silently swell a queue and degrade into latency I discover
in a dashboard an hour later. *Acceptance:* after a flood, accepted equals applied plus dropped, exactly, and the
drop count is observable (G4).

**DS-4 — one book, one writer.** As a correctness owner, I need the guarantee that an instrument's book is mutated by
exactly one process, so no concurrent match can corrupt the ladder. *Acceptance:* under concurrent submits, one Book
applies all commands in a single order with no interleaved mutation (G3).

**DS-5 — the Go worker prices the fill.** As an engineer on the risk tier, my Go worker consumes a fill that already
carries a branded id and integer money, computes margin and mark-to-market with GPU-accelerated math, and never
parses an order or sees a float. *Acceptance:* fills are branded and money is `{units, nano}` on both runtimes
([`trd.2.specs.md`](trd.2.specs.md) §cross-runtime); the Decider emits the fact, the fact becomes the job.

## Agent stories (Directive + Acceptance gate)

**AS-1 — the pure ladder first.** *Directive:* the agent builds `Exchange.OrderBook` as a per-side `gb_trees` price
ladder with mint-order level FIFOs and pure read verbs, before any matching. *Gate:* a property shows reads return
price-time order over generated orders; the module has no process and no store; the line prints green, exit zero.

**AS-2 — matching as a pure decider.** *Directive:* the agent writes `decide/2` and `evolve/2` with no side effects,
implementing cross, partial-fill, rest, and reject, returning events. *Gate:* G1 and G2 hold as properties over
`decide` with no process started; a grep shows no `GenServer`, `:ets`, clock call, or `Process.*` in the Decider
module; exit zero.

**AS-3 — the shell is the single writer.** *Directive:* the agent builds `Exchange.Book` as one GenServer per
instrument that drains the Ring in order, applies via the Decider, and folds. *Gate:* G3 shows one application order
under concurrent submits with no interleaving; exit zero.

**AS-4 — admission reconciles.** *Directive:* the agent floods the Ring past capacity and reconciles counts. *Gate:*
G4 shows accepted == applied + `stats.dropped`, exactly, with no silent loss; the line prints the three counts; exit
zero.

**AS-5 — no float anywhere.** *Directive:* the agent does money arithmetic in integer `{units, nano}` with integer
carry, and asserts structurally that no event or state value is a float. *Gate:* G5 holds over a matched run; exit
zero.

**AS-6 — self-trade prevented.** *Directive:* the agent implements the self-trade rule in `decide` and property-tests
that two same-account crossing orders do not self-fill. *Gate:* G6 holds as a property; exit zero.

**AS-7 — fills are branded, money integer (freeze the Go seam).** *Directive:* the agent mints a `FIL` id at each
fill via the canon and emits `{units, nano}` money, so a downstream job can be keyed by the fill id. *Gate:* every
`:fill` event carries a branded `FIL` id and integer money; no fill is emitted without an id; exit zero.

## Map

Spec: [`trd.2.specs.md`](trd.2.specs.md). Chapter: [`trd.2.md`](trd.2.md). Runbook: [`trd.2.llms.md`](trd.2.llms.md).
Previous rung: [`trd.1.stories.md`](trd.1.stories.md).
