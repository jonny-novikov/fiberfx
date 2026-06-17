# TRD.1 · The Gateway — Parse Once, At the Edge

<show-structure depth="2"/>

> Rung TRD.1 of the trading suite ([`exchange.specs.md`](exchange.specs.md)). The quad: this chapter narrates;
> [`trd.1.specs.md`](trd.1.specs.md) is authoritative (decomposition and the Mars build); [`trd.1.stories.md`](trd.1.stories.md)
> holds the acceptance stories for both audiences; [`trd.1.llms.md`](trd.1.llms.md) is the agent runbook. Feedback edits
> the spec, never the implementation. **Status: PROPOSED.**

## Overview

The Gateway is the platform's only door. Untrusted input — an order from a desk, a command from an API client, a
market-data tick relayed from the external feed — becomes, at this boundary and nowhere else, a typed command
carrying a branded id, or a typed rejection naming exactly what was wrong. Past the Gateway, no string from the
outside survives: the matching core, the log, the bus, and the Go workers all speak the closed command vocabulary
this rung defines. TRD.1 builds that vocabulary, the parser that produces it, and the closed error set that is its
only other output.

## Rationale

Parse, don't validate. A validator checks a value and hands the same loose value onward, so every downstream layer
re-checks or trusts blindly; a parser turns a loose value into a precise type once, and the type is the proof that
the check happened. The matching engine ([`trd.2.specs.md`](trd.2.specs.md)) is a pure function over typed commands —
it cannot be handed a malformed order because the type it consumes cannot represent one. This is the same discipline
the bus holds with claims (a 29-byte `(id, version)` cannot carry a malformed object) and the canon holds with
branded ids (a wrong-namespace id is refused at the gate, not deep in a store); the Gateway is that discipline at the
system's edge.

The command set is grounded in a real venue. The external market is the TInvest service, whose order contract
(`PostOrderRequest`) carries a direction (`ORDER_DIRECTION_BUY` / `_SELL`), an order type
(`ORDER_TYPE_LIMIT` / `_MARKET` / `_BESTPRICE`), a quantity in lots, a price as a `Quotation` (an integer `units`
plus a `nano` fraction — the venue's money-math type, never a float), and — load-bearing for this architecture — its
own `order_id`, a client-supplied UID the venue treats as the idempotency key. That last field is the seam the whole
platform turns on: the branded intent id this Gateway mints *is* the venue's idempotency key, so a resubmission after
a crash collides on the same id at both the venue and every internal layer.

## Design

One module, `Exchange.Gateway`, with one public verb per command kind and a single private parser beneath them. The
parser is total: every input either produces a typed command or one member of the closed error set
(`:unknown_instrument`, `:bad_direction`, `:bad_order_type`, `:nonpositive_quantity`, `:bad_price`,
`:malformed`) — there is no third outcome, no exception path, no partial command. Money is a `Quotation`-shaped pair
of integers from the first byte parsed; a price that does not parse to integers is `:bad_price`, refused here, so no
float ever reaches the book. The branded id is minted at the moment of acceptance: a valid parse calls
`Snowflake.next_branded("CMD")` (and `"ORD"` for the resulting order), stamping mint order — the platform's only
sequence — onto the command at the instant it enters. Instrument and account identifiers arrive as caller-supplied
opaque strings (the venue's FIGI or instrument UID) and are wrapped, not minted; they become Keyspace hash tags
downstream.

The Gateway holds no state and touches no store — it is a pure boundary function with a minting effect, which makes
it trivial to property-test and impossible to corrupt. Its output is handed to the instrument's Ring (TRD.2); its
rejections are returned to the caller as tagged tuples.

## The five W's

**Why.** One parse boundary means every downstream layer trusts its inputs by type rather than by re-checking, and a
malformed order is refused at the door with a named reason instead of failing somewhere expensive and ambiguous
later.

**What.** A closed command vocabulary (limit, market, best-price orders; cancel; replace — the TInvest verb set), a
total parser from untrusted input to that vocabulary or the closed error set, branded `CMD`/`ORD` ids minted at
acceptance, and `Quotation`-shaped integer money from the first byte.

**Who.** `Exchange.Gateway` (PROPOSED, this rung). Upstream: API clients and the market-data relay. Downstream: the
instrument Ring (TRD.2) and, past matching, the Go workers that price and risk-check against the same typed commands
and the same money type. The Author ships the quad; the Operator selects the command-set v1 scope.

**When.** First rung of milestone A; it stands on the canon (branded ids, the kind law) alone, so it ships on
today's tree with no unbuilt dependency.

**Where.** `runtimes/elixir/lib/exchange/gateway.ex`, with its gate script and committed transcript beside the other
rung gates. The command and money types are shared headers the Go workers also bind, named here and specified in
[`trd.1.specs.md`](trd.1.specs.md).

## The Go-worker seam, named

TRD.1 is BEAM-only — it builds the door, not the workers. But the door's shape is chosen for them. The external
processor that prices instruments, runs the money-math, and talks to the TInvest venue is a fleet of Go workers
(the TInvest Go SDK is their client), drained as EchoMQ jobs and reading through EchoCache; Go carries that tier for
its numeric throughput and GPU-accelerated math. Those workers consume the *typed* command and the `Quotation` money
type this rung defines — a worker never parses a raw order, because parsing happened once, here. The job payloads and
the cross-runtime money contract are specified in [`trd.1.specs.md`](trd.1.specs.md); the worker tier itself is the
trading roadmap's later rungs, named so the boundary is a decision, not a surprise.

## Map

Authoritative spec: [`trd.1.specs.md`](trd.1.specs.md). Stories: [`trd.1.stories.md`](trd.1.stories.md). Runbook:
[`trd.1.llms.md`](trd.1.llms.md). The next rung (the Ring and the book): [`trd.2.md`](trd.2.md). The system:
[`exchange.specs.md`](exchange.specs.md). The id canon: `bcs.toc.md` — Appendix F.

## References

**External patterns.** *Parse, don't validate* (Alexis King, 2019) — [lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate](https://lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate/) — is the discipline this Gateway embodies: a parser turns loose input into a precise type once, so downstream layers trust by type rather than re-checking. The external venue is Tinkoff Invest: the gRPC contract at [github.com/Tinkoff/investAPI](https://github.com/Tinkoff/investAPI) is the source of the command vocabulary (`ORDER_DIRECTION_*`, `ORDER_TYPE_*`), the `Quotation` money type (integer `units` and `nano`), and the `PostOrderRequest.order_id` idempotency seam this rung maps onto the branded id; the Go workers that price against these commands use its Go SDK at [github.com/Tinkoff/invest-api-go-sdk](https://github.com/Tinkoff/invest-api-go-sdk).

**BCS.** The identity canon `contract/contract.md` (the kind law, branded `parse`); `bcs.toc.md` Appendix F (the order theorem — branded ids as sequence, key, sort, claim, and cache key in one paid form, which is why minting at acceptance gives the platform its only ordinal); Appendix G (the claim-check law — the bus never carries an object).

**Redis-patterns course.** The keyspace and hash-tag conventions the opaque instrument and account identifiers feed into downstream (a book's keys co-locate in one slot by hash tag); the course is the series' patterns reference for every Valkey-resident structure the platform builds on.

**echo_mq.** The as-built work surface the parsed commands ultimately feed — `EchoMQ.Jobs` drained by `EchoMQ.Consumer`, shaped by `EchoMQ.Lanes` (the fair per-venue lanes, BCS Chapter 3.4) — and the line specification `emq2.specs.md`, whose scheduler rung (emq.1) is the named consumer of this platform's settlement and reporting jobs.
