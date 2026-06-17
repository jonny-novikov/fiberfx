# TRD.1.1 · The Gateway MVP — the Door, Made Real

<show-structure depth="2"/>

> The first shippable slice of rung TRD.1 ([`trd.1.md`](trd.1.md) is the full chapter; this one narrates the MVP the
> build delivers now). The authoritative spec is [`trd.1.1.specs.md`](trd.1.1.specs.md). Feedback edits the spec, never
> the implementation. **Status: PROPOSED.** **Framing (propagate this clause): third person for any agent; no gendered
> pronouns; no perceptual or interior-state verbs; no first-person narration.**

## Overview

TRD.1.1 turns the Gateway from a specified door into a built one. The parent rung TRD.1 specifies the platform's only
entry point in full — three command kinds, three order types, the idempotency seam. This slice ships the load-bearing
core of it: a new lib-only umbrella app `echo/apps/exchange` holding one stateless module, `Exchange.Gateway`, that
parses an untrusted map into a **place** (limit or market) or **cancel** command carrying a branded id — or one member
of the closed six-atom error set — and nothing else. It is the smallest change that makes parse-don't-validate true at
the system's edge and gives the rest of the platform a typed vocabulary to consume.

## Rationale — why a slice, and why this slice

The full TRD.1 is correct but broad. Two of its pieces carry design weight out of proportion to the rest: `replace` (a
command that overwrites an open order's quantity and price, which needs the order-reference semantics the book has not
yet defined) and the idempotency seam (INV-6 — how a caller presents a replay token, and where the branded id sits in
the command's outward shape as the venue's `order_id`). Shipping those by guess would bake a decision the book and the
venue contract should make. So this slice defers both and builds the part that is unambiguous and immediately load-
bearing: the total parser, the integer money type, minting at acceptance, and the two command kinds every later rung
depends on.

The slice is also a forcing function for honesty elsewhere. The `/bcs` capstone (Part VIII, B8) teaches `Exchange.*` —
the gateway, the book, the decider — as a PROPOSED consumer with no backing code, grounded only in the as-built
substrate beneath it. TRD.1.1 makes the first of those modules real, so the course's parse-don't-validate lesson points
at a module that exists, not a promise. The platform rename that lands with this slice — `docs/trading/` →
`docs/exchange/`, the system fronted by [`exchange.md`](exchange.md) now named the **Exchange Platform** — is the same
alignment at the documentation layer.

## Design

One module, `Exchange.Gateway`, with one public verb per in-scope command kind (`parse_place/1`, `parse_cancel/1`) over
a set of field parsers, exactly as the parent specifies — minus the `replace` assembler and the `parse/1` dispatcher.
The parser is total over its inputs: every map either produces a typed command or one member of the closed error set,
with `{:error, :malformed}` as the classify-failure floor, so there is no exception path and no partial command. Money
is a `Quotation`-shaped pair of integers from the first byte parsed; a float-bearing price is `{:error, :bad_price}`,
refused here, so no float ever reaches the book. The branded id is minted at the moment of acceptance through
`EchoData.Snowflake.next_branded/1` — `"CMD"` for the command, `"ORD"` for the order — stamping mint order, the
platform's only sequence. Instrument and account identifiers arrive as caller-supplied opaque strings and are carried
verbatim, never branded (INV-4).

The command @type is authored **wide** — it names `:bestprice` and the `{:replace, …}` constructor — so the type is the
full vocabulary the platform speaks and stays stable across the 1.1 → 1.2 boundary; only the *parsers* grow when 1.2
wires `replace` and `:bestprice`. The Gateway holds no state, starts no process, opens no ETS, reads no app-env, and
adds no external dependency: it is one file plus its gate script, depending on the canon (`{:echo_data, in_umbrella:
true}`) for minting alone. That single in-umbrella edge is the minting prerequisite INV-3 mandates — not the new
external dependency the statelessness story forbids.

## The five W's

**Why.** One parse boundary, built now, means every later layer — the Ring, the book, the decider, the Go workers —
trusts its inputs by type rather than by re-checking, and a malformed order is refused at the door with a named reason.
Shipping the slice (not the whole rung) keeps the genuinely-design-bearing pieces — `replace`, the idempotency seam —
out of a guess and in their own rung.

**What.** A new lib-only app `echo/apps/exchange`; `Exchange.Gateway` with `parse_place/1` (limit and market) and
`parse_cancel/1`, the field parsers, the closed six-atom error set, `{units, nano}` integer money, and branded
`CMD`/`ORD` ids minted at acceptance; a rung gate (G1–G5 + cancel + a totality property) with a committed transcript.

**Who.** `Exchange.Gateway` (new, this slice). Upstream: API clients and the market-data relay (later rungs).
Downstream: the instrument Ring (TRD.2) and, past matching, the Go workers. Underneath: the canon `EchoData.*`, reused,
never edited. The Author ships the slice; the Operator selected the MVP scope (place limit+market + cancel; replace,
best-price, and the idempotency seam to TRD.1.2).

**When.** The first slice of milestone A; it stands on the `echo_data` canon alone — branded ids and the minting
generator are committed — so it ships on today's tree with no unbuilt dependency.

**Where.** `echo/apps/exchange/lib/exchange/gateway.ex`, its test under `echo/apps/exchange/test/`, and its gate script
`echo/rungs/exchange/trd_1_1_check.exs` with the committed transcript beside the other rung gates
(`echo/rungs/{bus,cache,journal}/`). The command and money @types are the shared headers the Go workers later bind,
named in [`trd.1.1.specs.md`](trd.1.1.specs.md).

## What this slice does not build (deferred to TRD.1.2)

`parse_replace/1` (the third command kind); the `parse/1` kind-dispatcher; `:bestprice` (the third order type); and the
INV-6 / G6 idempotency seam — replay-token reconciliation and the venue `order_id` outward position. These are named in
the authoritative spec as a decision, not a surprise; the full statement of each lives in the parent
[`trd.1.specs.md`](trd.1.specs.md).

## The Go-worker seam, named (not built here)

The slice fixes the two invariants the later Go-worker boundary honors — money is `{units, nano}` integers on both
runtimes, and the branded id is the job key and the venue idempotency key (`PostOrderRequest.order_id`) — by realizing
typed money (INV-2) and minting-at-acceptance (INV-3) in the door. A worker consumes the *typed* command this slice
emits and never parses a raw order. The job payload schema and the worker's idempotent-handler contract are the trading
roadmap's later rungs ([`exchange.roadmap.md`](exchange.roadmap.md)); the idempotency seam itself is TRD.1.2.

## Map

Authoritative spec: [`trd.1.1.specs.md`](trd.1.1.specs.md). The full rung: [`trd.1.md`](trd.1.md) ·
[`trd.1.specs.md`](trd.1.specs.md) · [`trd.1.stories.md`](trd.1.stories.md) · [`trd.1.llms.md`](trd.1.llms.md). The next
rung (the Ring and the book): [`trd.2.md`](trd.2.md). The system: [`exchange.specs.md`](exchange.specs.md). The id
canon: `bcs.toc.md` — Appendix F. The capstone this slice grounds: `/bcs` B8 (`docs/echo/bcs/bcs.toc.md`).

## References

**External patterns.** *Parse, don't validate* (Alexis King, 2019) —
[lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate](https://lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate/)
— is the discipline this Gateway embodies. The external venue is Tinkoff Invest: the gRPC contract at
[github.com/Tinkoff/investAPI](https://github.com/Tinkoff/investAPI) is the source of the command vocabulary
(`ORDER_DIRECTION_*`, `ORDER_TYPE_*`), the `Quotation` money type (integer `units` and `nano`), and the
`PostOrderRequest.order_id` idempotency seam (which TRD.1.2 maps onto the branded id).

**BCS.** The identity canon `contract/contract.md` (the kind law, branded `parse`); `bcs.toc.md` Appendix F (the order
theorem — branded ids as sequence, key, sort, claim, and cache key in one paid form, which is why minting at acceptance
gives the platform its only ordinal). The B8 capstone (`docs/echo/bcs/bcs.toc.md`) is the course consumer this slice
makes real.

**echo_data (the canon, as-built).** `echo/apps/echo_data/lib/echo_data/snowflake.ex` (`next_branded/1`, `start/1`,
`next/0`) and `branded_id.ex` (`valid?/1`, `namespace/1`, `encode!/2`) — the minting and parse surface this slice
builds **on**, never edits.
