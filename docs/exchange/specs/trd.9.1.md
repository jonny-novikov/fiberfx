# TRD.9.1 · The Transport Spine — Config, Codegen, Client, Retry, the First Vertical

<show-structure depth="2"/>

> First slice of rung TRD.9 ([`trd.9.specs.md`](trd.9.specs.md)). The quad: this chapter narrates;
> [`trd.9.1.specs.md`](trd.9.1.specs.md) is authoritative for the slice; the trd.9 stories
> ([`trd.9.stories.md`](trd.9.stories.md)) and runbook ([`trd.9.llms.md`](trd.9.llms.md)) cover the full rung, of
> which AS-1/AS-2/AS-5/AS-6/AS-7 are this slice's. Feedback edits the spec, not the implementation. **Status:
> PROPOSED.** Stands on the as-built canon (`echo/apps/echo_data`, declared but not exercised this slice), the
> lib-only `echo/apps/exchange` template, and the committed Tinkoff Invest contracts. The read services (9.2), the
> trading + branded-`ORD` seam (9.3), the rest of SandboxService (9.4), and the streams (9.5) are LATER rungs. **Framing
> (propagate this clause): third person for any agent; no gendered pronouns; no perceptual or interior-state verbs; no
> first-person narration.**

## Overview

TRD.9 is the BEAM-native Tinkoff Invest client — 10 services, 72 RPCs. TRD.9.1 is its **transport spine**, shipped
standalone: the smallest surface that proves the whole venue-client vertical end to end. It founds the umbrella app
`echo/apps/investex` (OTP `:investex`, modules `Investex.*`, lib-only) and builds, in one vertical: `Investex.Config`
(auth + endpoint + retry knobs, defaults) → the protoc-gen-elixir codegen of the 8 committed contracts into committed
generated message modules + a documented regen task → a supervised `Investex.Client` owning the TLS `GRPC.Channel` and
the per-RPC `Bearer` + `x-app-name` metadata → the **pure** `Investex.Retry.decide/3` → `Investex.Money` (the integer
`{units, nano}` codec) → **UsersService end to end** (4 functions; `get_accounts/1` the canonical sandbox smoke) → the
**minimal sandbox bootstrap** (`Investex.Sandbox.{open_account/1, get_accounts/1, close_account/2}`) → `Investex.Error`
→ the parity-check **scaffold** → the **two-tier test harness**.

The vertical is proven both ways. A **pure** default suite (the committed `--no-start` rung gate, network-free,
deterministic) gates Config, Retry, Money, and the parity scaffold over the compiled umbrella. A **live** sandbox
round-trip (`open_account → get_accounts → close_account`) runs against the real sandbox endpoint with `INVEST_TOKEN`,
read from the environment only. The 7 implemented RPCs are the whole RPC surface this slice ships; the other 65 are
carried in the parity scaffold as an explicit pending list that the later rungs move from pending to asserted.

## Rationale

TRD.9's design reads the client as a stack — transport, codec, auth, retry, the per-service functions, the streams —
and the question this slice answers is *which thin vertical proves the stack is sound before any breadth is added*. The
answer is the transport spine: everything every later RPC will stand on, plus exactly one service end to end
(UsersService) and the minimal sandbox bootstrap that makes a live test possible at all.

The cut is reductive and it is load-bearing in three ways. **First, it de-risks the dependency surface once.** `:grpc`
and `:protobuf` are new top-level hex deps the umbrella has never carried; the codegen of the 8 contracts is a
one-time, commit-the-output step with its own regen task; the TLS dial against a real venue is a posture that has to be
got right exactly once. Proving all three on the smallest RPC set means the read services (9.2) and the trading
services (9.3) inherit a settled transport rather than re-litigating it. **Second, UsersService is the honest smoke.**
`GetAccounts` is a no-argument read returning the caller's accounts — the lightest possible real call, the same one the
Go SDK uses to confirm a client is alive (`client.go:90-111`). It exercises the channel, the bearer, the metadata, and
the response decode without needing an instrument, an order, or money on the wire. **Third, the sandbox bootstrap is a
prerequisite, not a feature.** A live test needs an account to test against; the Go SDK auto-opens one inside its
constructor; so the open/get/close trio lands here — enough to obtain and dispose of a sandbox account — while the
sandbox *order* methods wait for 9.3's order lifecycle and the rest of SandboxService waits for 9.4.

`Investex.Money` lands here too, though no implemented RPC's response carries money: it is pure, network-free, its
input structs exist the instant the codegen runs, and it is the integer-`{units, nano}` contract the whole Exchange
platform speaks (INV-3). Landing it now carries the money invariant from the first rung and de-risks the money-dense
read services. The Go float bridge (`converters.go`'s `ToFloat`/`FloatToQuotation`) is deliberately **not** ported —
that is the divergence INV-3 names.

The retry **decision** is carved out as a pure function — `decide(status, attempt, headers) -> {:retry, wait_ms} |
:give_up` — exactly as the matching core (TRD.2.1) carved the decider out of the stateful shell. The Go SDK's policy
lives inside an impure gRPC interceptor (`client.go:19-70`); the decision it encodes is a deterministic function of a
status, an attempt count, and the response headers, and pulling it out makes it unit-testable with no endpoint. The
interceptor that *applies* the decision (sleeping, re-dialing) is the impure shell that may stay thin this slice and
harden in later rungs; the decision is proven offline now.

## Design

`Investex.Config` is a struct mirroring the Go `Config` (`config.go`): `endpoint`, `token`, `app_name`, `account_id`,
`disable_resource_exhausted_retry`, `disable_all_retry`, `max_retries`. `new/1` builds it from a keyword/map applying
the defaults `setDefaultConfig` applies (`client.go:116-128`) — endpoint `sandbox-invest-public-api.tinkoff.ru:443`,
`app_name` `jonnify.investex` (the own-repo `<nick>.<repo>` rename of the Go `invest-api-go-sdk`), `max_retries` 3,
both disable flags false, `account_id` nil; `disable_all_retry: true` forces `max_retries` 0. `resolve/1` reads
`INVEST_TOKEN` from the environment (`System.fetch_env!`/`System.get_env`, INV-9) into the `token` field — the token is
never a struct literal and never a default.

The **codegen** runs protoc-gen-elixir against the 8 committed contracts once, with `-I proto/` so the bare imports
(`import "common.proto"`, `import "google/protobuf/timestamp.proto"`) resolve against protoc's bundled well-known types
and the sibling contracts; the generated message modules are **committed** to the repo with a documented regen task,
and protoc stays off the compile path. The generated namespace is `Tinkoff.Public.Invest.Api.Contract.V1.*` (the
plugin derives it from the proto `package tinkoff.public.invest.api.contract.v1`); investex modules `alias` it as
`Proto` so call sites read `%Proto.Quotation{}` as the chapter spec's prose intends (R-1).

`Investex.Client` is the one supervised process (INV-5): it owns the TLS `GRPC.Channel` and the resolved `Config`, and
it attaches the per-RPC `authorization: "Bearer <token>"` and `x-app-name: <app_name>` metadata in one place
(`client.go:37-39,72-78`; grpc.md). `start_link/1` dials the endpoint over TLS; `channel/1` returns the resolved
channel the per-service functions call with; `stop/1` closes the connection (`client.go:271-274`). investex is
**lib-only** — no `mod:`, nothing booted at app start — so the *consumer's* supervision tree (or a test) starts the
client; `:investex` never opens a connection by merely being loaded.

`Investex.Retry.decide/3` is the pure policy (INV-6): `(status, attempt, headers) -> {:retry, wait_ms} | :give_up`. On
`Unavailable`/`Internal` under the cap it returns `{:retry, 500}` (the Go `WAIT_BETWEEN` linear backoff,
`client.go:21,42-44`); on `ResourceExhausted` under the cap it returns a longer wait honoring the `x-ratelimit-reset`
header (seconds until the per-minute counter resets, grpc.md:92) — a refinement over the Go interceptor, which sleeps
an attempt-indexed interval header-blind (`client.go:48-54`), justified because the header carries the right value and
a pure function can read it offline (L-2); past `max_retries`, or with the resource-exhausted retry disabled on that
code, it returns `:give_up`. The function holds no clock, no sleep, no `Process.*`, no network — those live in the
shell that applies it.

`Investex.Money` is the integer codec (INV-3): `from_quotation/1` and `to_quotation/1` round-trip `{units, nano}`
against `%Proto.Quotation{}`; `from_money_value/1` decodes `%Proto.MoneyValue{}` to `{{units, nano}, currency}` (the
ISO currency string rides alongside). `Quotation` is `{units :: int64, nano :: int32}` and `MoneyValue` adds
`currency` (common.proto:28-48). No float appears in any value, request, or response shape the codec exposes.

`Investex.Users` and `Investex.Sandbox` are stateless given a client handle. Each unary function takes the client (and
a typed request or an id where the proto request carries a field) and returns `{:ok, response} | {:error,
Investex.Error.t()}`. UsersService maps the 4 RPCs (`users.proto:19-28`); the sandbox bootstrap maps the 3 lifecycle
RPCs (`sandbox.proto:20-26`). `Investex.Error` is the typed `{:error, reason}` value the per-service functions return.

The **parity scaffold** (G1, R-3) enumerates the proto service definitions and asserts the 7 implemented RPCs each map
to their named `Investex.<Service>.<fun>/n`, while carrying the unimplemented 65 as an explicit pending list — so a
later un-mapped function fails the growing gate, and the gate moves rows from pending to asserted monotonically across
9.2–9.5. The "count prints 72" full assertion completes at 9.5.

The **two-tier harness** splits the suite. Tier 1 is the pure default — Config defaults, the Retry decision, the Money
round-trip, the parity scaffold — network-free, deterministic, the rung gate. Tier 2 is `@tag :sandbox`, excluded by
default; its `setup` reads `INVEST_TOKEN` and `ExUnit`-skips on `nil`; with the key it runs the live round-trip. The
rung gate `echo/rungs/exchange/trd_9_1_check.{exs,out}` is a `mix run --no-start` runner (so `:investex` boots no
connection) over the **compiled** umbrella, one printed line per gate, nonzero exit on failure, the transcript
committed — it dials nothing (D-4).

## The five W's

**Why.** A transport spine proven on the smallest RPC set de-risks the new dependency surface, the codegen, and the
TLS posture exactly once, so the read and trading rungs inherit a settled transport. It ships the proof the client
trades — a live sandbox round-trip — before any breadth is added.

**What.** `echo/apps/investex` (lib-only) with `Investex.Config`, the committed generated proto modules + a regen task,
`Investex.Client` (TLS channel, Bearer + `x-app-name`, lib-only), the pure `Investex.Retry.decide/3`, `Investex.Money`
(integer `{units, nano}`), `Investex.Error`, UsersService (4), the sandbox bootstrap (3), the parity scaffold, and the
two-tier harness — pure-gated and live-sandbox-verified. **[RECONCILE — corrected by TRD.9.1.1
([`trd.9.1.1.specs.md`](trd.9.1.1.specs.md)): the "live-sandbox-verified" claim was a FALSE-GREEN — the as-built
transport could not dial the venue (DEFECT A, the stale `…tinkoff.ru` endpoint; DEFECT B, the untrusted Russian root).
The genuine live verification is re-proven by TRD.9.1.1's 3-way harness after the A+B fix.]**

**Who.** The investex app (PROPOSED, this slice). Upstream: the committed Tinkoff Invest contracts and the Go SDK (the
parity source, read not run); the canon `echo_data` (declared `{:echo_data, in_umbrella: true}`, **not exercised** this
slice — its branded-`ORD` seam is 9.3). Downstream: the read services (9.2) that reuse this transport, and the Exchange
platform that will pass branded `ORD` ids through `PostOrder` at 9.3. The Operator ruled the one venue-facing fork: the
live sandbox tier RUNS this build and MUST PASS to ship (the hard gate).

**When.** First slice of the venue-client rung. Stands on the as-built canon, the lib-only exchange template, and the
committed contracts — no unbuilt dependency. The read/trading/sandbox-remainder/stream services exist as later rungs,
not consumed here.

**Where.** `echo/apps/investex/**` (`mix.exs`, `lib/investex/*.ex`, the committed generated modules under
`lib/investex/proto/` or the codegen's output dir, the regen `Mix.Task`, `test/**`, `test/test_helper.exs`), and the
rung gate + committed transcript at `echo/rungs/exchange/trd_9_1_check.{exs,out}`, beside the TRD.2.1 gate.

## Deferred to 9.2–9.5 (named, not built here)

This slice does **not** build, edit, or gate:

- **The branded `ORD` edge-validation seam (INV-4 / G3) → 9.3.** This slice places no order. `post_order` /
  `replace_order` / `Sandbox.post_order` and the `EchoData` ORD validation are 9.3. `{:echo_data, in_umbrella: true}`
  is still declared as the canon dep, but 9.1 does not exercise the branded seam — `echo_data` is a declared edge, a
  mint/validate surface the trading rung consumes, not a 9.1 call site.
- **Full 72-RPC parity (G1 complete) → 9.5.** This slice ships the scaffold + the 7-RPC subset; the count completes
  when the last stream lands.
- **The read services (9.2)** — InstrumentsService (27) + MarketDataService (7) + OperationsService (7), unary,
  read-only.
- **The trading services (9.3)** — OrdersService (5) + StopOrdersService (3), the write side, the branded `ORD` seam,
  and the sandbox order lifecycle (the 5 sandbox order methods).
- **The rest of SandboxService (9.4)** — `pay_in` + positions / operations / operations-by-cursor / portfolio /
  withdraw-limits (the 6 remaining sandbox methods).
- **The streaming services (9.5)** — the 5 supervised stream GenServers (INV-7): resubscribe-on-reconnect, the `Ping`
  keepalive, decoded delivery.
- **INV-4 (the branded seam), INV-7 (streams resubscribe)** — properties of rungs this slice does not build; this
  slice holds INV-5/6/8/9 fully, INV-3 (Money landed here), and INV-1 as the growing scaffold.

The deferral is the boundary the Director's Stage-3 reconcile verifies held: no order method, no `EchoData` ORD
validation, no stream GenServer, no read-service function in this slice's diff.

## The seam forward to 9.2

9.1 freezes the transport every later RPC stands on: the Config struct + defaults, the committed generated codec, the
supervised channel-owning client, the pure retry decision, and the integer-money codec. 9.2 (the read services) adds
unary per-service functions over **this** transport — `Investex.Instruments.*`, `Investex.MarketData.*`,
`Investex.Operations.*` — reusing the client handle, the metadata, the retry shell, and `Investex.Money` (now
exercised by money-dense responses) unchanged, and moving its RPC rows from the parity scaffold's pending list to
asserted. No transport decision re-opens; the spine set here is the contract 9.2 builds against.

## Map

Authoritative spec: [`trd.9.1.specs.md`](trd.9.1.specs.md). The full rung: [`trd.9.md`](trd.9.md) ·
[`trd.9.specs.md`](trd.9.specs.md) · [`trd.9.stories.md`](trd.9.stories.md) · [`trd.9.llms.md`](trd.9.llms.md). The
slice-form precedent (the prior build-rung slice): [`trd.2.1.md`](trd.2.1.md) · [`trd.2.1.specs.md`](trd.2.1.specs.md).
System: [`exchange.specs.md`](exchange.specs.md). Ladder: [`exchange.roadmap.md`](exchange.roadmap.md). The parity
source: the committed Tinkoff Invest contracts (`github.local/invest-api-go-sdk/proto/*.proto`) and the Go SDK
(`investgo/*.go`), cited by path in [`trd.9.specs.md`](trd.9.specs.md). The canon (the declared, unexercised dep):
`echo/apps/echo_data/lib/echo_data/{snowflake,branded_id}.ex`.
