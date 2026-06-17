# TRD.9 · investex — the BEAM-native Tinkoff Invest client

<show-structure depth="2"/>

> Rung TRD.9 of the trading suite ([`exchange.specs.md`](exchange.specs.md)). The quad: this chapter narrates;
> [`trd.9.specs.md`](trd.9.specs.md) is authoritative; [`trd.9.stories.md`](trd.9.stories.md) holds the acceptance
> stories for both audiences; [`trd.9.llms.md`](trd.9.llms.md) is the agent runbook. Feedback edits the spec.
> **Status: PROPOSED.** Founds a new umbrella app, `echo/apps/investex`, on the as-built `echo_data` canon and the
> committed Tinkoff Invest contracts. This rung is the *specification* — no code ships here.

## Overview

investex is the Elixir-native client for the Tinkoff Invest API: `echo/apps/investex`, OTP `:investex`, modules
`Investex.*`. It covers the same surface the Go SDK covers — **10 gRPC services, 72 RPCs** — as a gRPC transport over
TLS with bearer-token auth, generated protobuf message modules, one Elixir function per RPC across stateless
per-service modules, supervised processes for the five bidirectional streams, money decoded to the Exchange canon's
`{units, nano}` integer pair, and a two-tier test strategy: a pure default suite and an opt-in sandbox-keyed
integration suite. The roadmap named a *Go worker tier — the Tinkoff Invest gRPC client tier* with an open question
on whether to give it its own quad. The Operator answered by asking for a first-class Elixir client, so the BEAM is
never blocked on the Go tier for venue I/O. TRD.9 founds that subsystem; the build is the 9.1–9.5 ladder.

## Rationale

The platform already has a venue-client seat — it is the Go worker tier, the fleet that prices and settles fills with
GPU-accelerated math, and whose I/O leg is the Tinkoff Invest gRPC client. That seat is right for numeric throughput
and wrong for everything the BEAM does best: placing an order from a LiveView, supervising a market-data stream that
resubscribes itself on reconnect, validating a branded id at the edge before it crosses the wire. A BEAM-native client
puts venue I/O where the rest of the platform lives, under OTP supervision, speaking the same `{units, nano}` money
and the same branded ids — and it removes a coupling: the BEAM no longer waits on the Go fleet to reach the venue.

The shape is ecosystem-determined, which is why this rung specifies rather than re-decides. gRPC in Elixir is
elixir-grpc over the Mint adapter with elixir-protobuf for codegen — and the umbrella already locks the HTTP/2 stack
(`mint`, `castore`, `hpax`), so the transport adds no new substrate, only the grpc/protobuf codegen pair. A client
that owns its channel and a set of stateless per-service modules is the Go SDK's own shape (`Client{conn, Config}`
plus thin per-service wrappers), translated to a supervised process and modules. The one place the translation
deliberately diverges is money: the Go SDK offers a float bridge (`Quotation.ToFloat()`); investex does not mirror it,
because the canon is the integer `{units, nano}` pair the whole platform speaks and a float boundary would re-introduce
the type the canon refuses.

Parity is the headline, and parity must be measurable. "Covers the same surface the Go SDK covers" is a green/red gate
here — a parity manifest of all 72 RPCs mapped to named functions, and a check that enumerates the proto and asserts
each mapping — not a claim a reviewer takes on faith.

## Design

`Investex.Client` is one supervised process owning the `GRPC.Channel` and the resolved `Investex.Config`: the
endpoint, the TLS dial, the bearer token (read from the environment, never a literal), the `x-app-name` metadata, and
the reconnect. The per-service modules — `Investex.Instruments`, `MarketData`, `Operations`, `Orders`, `StopOrders`,
`Users`, `Sandbox` — are stateless given a client handle; each public function is one RPC, taking a typed request and
returning `{:ok, response} | {:error, reason}`. The client is **lib-only**: nothing boots at app start, so the
consumer (a supervision tree, or a test) starts the client when a venue connection is needed, and the matching core
stays pure, with no coupling to the network.

The message modules are protoc-generated and committed. The eight contracts (common, instruments, marketdata,
operations, orders, sandbox, stoporders, users) compile once through protoc + protoc-gen-elixir into `Investex.Proto.*`
modules checked into the repo, with a documented regen task — the Go SDK's own posture (it commits its `.pb.go`),
keeping protoc off the compile path and the build reproducible.

Money decodes through `Investex.Money`: `from_quotation/1`, `to_quotation/1`, `from_money_value/1`, every value an
integer `{units, nano}` pair (`from_money_value/1` also returns the ISO currency). Retry mirrors the Go interceptor —
linear 500 ms on `Unavailable`/`Internal`, a separate silent wait on `ResourceExhausted` honoring `x-ratelimit-reset` —
but the *decision* is extracted as a pure function `(status, attempt, headers) -> {:retry, wait_ms} | :give_up`, so
the policy is unit-tested with no network and the impure interceptor is only the shell that applies it.

The five streaming RPCs are the hardest surface and land last. Each is a supervised GenServer owning the gRPC stream,
the subscription set, and the `Ping` keepalive; on reconnect it resubscribes the full set and keeps delivering decoded
messages to its subscriber. The raw stream is never handed to the caller — that would lose exactly the resubscribe and
subscription management the Go SDK makes a headline feature.

The whole thing is gated in two tiers. The pure tier — codegen round-trip, money codec, config defaults, request
builders, branded-id validation, the retry decision — touches no network and is the CI-safe rung gate. The sandbox
tier, tagged and excluded by default, opens a real sandbox account with `INVEST_TOKEN` and trades against the sandbox
endpoint; it skips, rather than fails, when the key is absent, so the deterministic gate and the real proof coexist
without one blocking the other.

## The five W's

**Why.** A BEAM-native venue client puts order placement, stream supervision, and edge validation under OTP where the
platform lives, speaks the canon's integer money and branded ids, and unblocks the BEAM from the Go fleet for venue
I/O — while the Go tier keeps the heavy money-math it is right for.

**What.** `Investex.Client` (the supervised channel owner), the seven unary per-service modules and the five stream
processes (72 RPCs, one function or one stream each), `Investex.Money` (the `{units, nano}` codec), `Investex.Config`
(the auth + endpoint + retry config), `Investex.Retry` (the pure decision), and the committed `Investex.Proto.*`
generated modules — all PROPOSED, built across the 9.1–9.5 ladder.

**Who.** investex is the BEAM's venue client (PROPOSED, this subsystem). Upstream: the Exchange Gateway (TRD.1) mints
the branded `ORD` id investex carries as the venue idempotency key. Alongside: the Go worker tier, which prices and
settles the fills the matching core emits. The Author ships the quad and the build rungs; the Operator rules the
venue-facing edges (which environment, which retry posture, the sandbox-vs-production cutover).

**When.** TRD.9, after the specced milestone-A rungs. It stands on the as-built `echo_data` canon and the committed
contracts — no unbuilt dependency for the spec. Each build rung 9.1–9.5 is a separate, later x-mode run.

**Where.** `echo/apps/investex` (`Investex.*`), with the generated `Investex.Proto.*` committed and a gate script plus
committed transcript beside the other rung gates at `echo/rungs/exchange/trd_9_N_check.{exs,out}`. The contracts and
the Go reference live in `github.local/invest-api-go-sdk` and `github.local/investAPI`; investex builds against them,
never edits them.

## The Exchange seam, named

investex is the BEAM-native venue client; it complements the Go worker tier rather than replacing it. Two seams join
investex to the platform.

The first is **inward, and it is one field**: the branded `ORD` id. When the platform places a venue order, the `ORD`
id minted at the Gateway (TRD.1) is the `order_id` investex passes to `PostOrder` as the venue idempotency key, and
the fresh id of a `ReplaceOrder` is the proto `IdempotencyKey`. This is not an investex invention — it is the
platform's own decision, recorded in two places already: the system spec names `ORD` a first-class id "minted at the
edge, validated at every door," and the roadmap's *Go worker tier* names `PostOrderRequest.order_id` "the branded id
is the job key and the venue idempotency key." investex attaches the edge validation at exactly that field, so the same
id the platform sequences with is the id the venue dedups on.

The second is **alongside**: the Go worker tier stays for the GPU-accelerated money-math it is right for — mark-to-
market, margin, risk, analytics over fills — fed by the data investex and the BEAM matching core produce, consuming the
same `{units, nano}` integer money investex decodes. No float crosses either boundary. investex does not carry the heavy
math onto the BEAM; it gives the BEAM a first-class venue client so venue I/O is supervised, branded, and never blocked
on the Go fleet. The Go tier's job payload schema and idempotent-handler contract are its own rungs; this rung fixes
the BEAM-native client and freezes the branded-id seam.

## Map

Authoritative spec: [`trd.9.specs.md`](trd.9.specs.md). Stories: [`trd.9.stories.md`](trd.9.stories.md). Runbook:
[`trd.9.llms.md`](trd.9.llms.md). System: [`exchange.specs.md`](exchange.specs.md). Ladder:
[`exchange.roadmap.md`](exchange.roadmap.md). The seam's other end: [`trd.2.md`](trd.2.md) ("The Go pricing seam,
named") and the *Go worker tier* section of [`trd.progress.md`](trd.progress.md).

## References

**The API surface (the parity target).** The Tinkoff Invest API contracts — [github.com/Tinkoff/investAPI](https://github.com/Tinkoff/investAPI) —
are the 10 services and 72 RPCs investex covers; the committed copy under `github.local/invest-api-go-sdk/proto/*.proto`
is the per-method ground for the parity manifest. The Go SDK — [github.com/Tinkoff/invest-api-go-sdk](https://github.com/Tinkoff/invest-api-go-sdk) —
is the wrap-pattern reference: the stateful client and TLS/bearer dial, the thin per-service wrappers, the per-stream
clients that resubscribe on reconnect. The transport conventions (endpoints, `Authorization: Bearer`, `x-app-name`,
`x-tracking-id`, `x-ratelimit-*`) are documented in the API's gRPC protocol page.

**The Elixir gRPC stack.** elixir-grpc — [github.com/elixir-grpc/grpc](https://github.com/elixir-grpc/grpc) — over the
Mint adapter (Mint — [github.com/elixir-mint/mint](https://github.com/elixir-mint/mint), already locked) is the
transport; elixir-protobuf — [github.com/elixir-protobuf/protobuf](https://github.com/elixir-protobuf/protobuf) — with
`protoc-gen-elixir` is the codegen. These are the new dependencies this rung adds, beside the in-umbrella `echo_data`.

**The canon and the platform.** `exchange.specs.md` (the master invariant; money never float; the branded id spine
ORD/FIL/CMD/TXN/ACC/INS minted at the edge and validated at every door); `echo_data` (the Ecto-free minting and
`{units, nano}` canon investex shares in-umbrella); the *Go worker tier* of `trd.progress.md` (the seat investex takes
as the BEAM-native venue client, the `PostOrderRequest.order_id` idempotency-key seam); `trd.2.md` (the fill seam the
Go tier prices). The contract figures — `MoneyValue`/`Quotation` as `{units, nano}`, the 72 RPCs, the endpoints — are
quoted from the committed contracts and the Go SDK, never invented.
