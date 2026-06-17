# TRD.9.2 · The Read Services — Instruments, MarketData, Operations over the Fixed Transport

<show-structure depth="2"/>

> Second slice of rung TRD.9 ([`trd.9.specs.md`](trd.9.specs.md)). The quad: this chapter narrates;
> [`trd.9.2.specs.md`](trd.9.2.specs.md) is authoritative for the slice; the trd.9 stories
> ([`trd.9.stories.md`](trd.9.stories.md)) and runbook ([`trd.9.llms.md`](trd.9.llms.md)) cover the full rung. It builds
> on the shipped transport spine ([`trd.9.1.specs.md`](trd.9.1.specs.md)), reused unchanged. Feedback edits the spec,
> not the implementation. **Status: PROPOSED.** The trading + branded-`ORD` seam (9.3), the rest of SandboxService (9.4),
> and the streams (9.5) are LATER rungs. **Framing (propagate this clause): third person for any agent; no gendered
> pronouns; no perceptual or interior-state verbs; no first-person narration.** **Secret hygiene (INV-9, hard): the
> `INVEST_TOKEN` value appears in nothing this rung writes — read it from the environment only.**

## Overview

TRD.9.1 founded `echo/apps/investex` and shipped the transport spine — Config, the committed codegen, the supervised
TLS `Investex.Client`, the pure `Investex.Retry.decide/3`, the integer-`{units, nano}` `Investex.Money` codec, the
typed `Investex.Error`, the shared `Investex.Caller` unary seam, UsersService (4), the sandbox bootstrap (3), the
growing parity scaffold, and the two-tier harness. TRD.9.2 is the **read services**: the next thin vertical, built as a
parity layer **over** that spine, which it reuses without editing.

It adds three stateless modules — `Investex.Instruments` (27 RPCs), `Investex.MarketData` (7), `Investex.Operations`
(7) = **41 read-only unary functions**. Each is a 1:1 pass-through that mirrors the as-built `Investex.Users`: it takes
a typed `%Proto.<Request>{}` and delegates to `Investex.Caller.unary(client, &…Service.Stub.<fun>/3, request)`,
returning `{:ok, %Proto.<Response>{}} | {:error, Investex.Error.t()}`. The function name is `snake(RPC)` — the same
name the `use GRPC.Stub` macro generates for the `Stub` function it calls — and the arity is uniform `/2` across all
41. There is no request-builder layer this rung: the proto struct IS the typed request the caller pre-builds (RQ-1).

Three things make the read layer a *measured* increment, not just more functions:

- **The parity scaffold grows.** `test/parity_test.exs`'s `@implemented` map moves from 7 rows to **48**; the pending
  list from 65 to **24**; the touched-services assertion from `{Users, Sandbox}` to exactly `{Users, Sandbox,
  Instruments, MarketData, Operations}`. The growing gate is the spec's parity contract: a 9.3+ RPC landing without its
  Elixir function, or a renamed read, fails it. The "count prints 72 implemented" full assertion stays 9.5.
- **`Investex.Money` is exercised against real venue data.** The read responses are the first to carry money — a
  `GetLastPricesResponse` whose `LastPrice.price` is a `Quotation`, a `PortfolioResponse` whose `total_amount_*` are
  `MoneyValue`. The codec lands in 9.1 but had no implemented RPC's response to decode; 9.2 decodes the real fields, in
  a pure property over the field shapes AND in the live subset against the sandbox. `Investex.Money` gains tests, not a
  new function (RQ-4).
- **A new pass-through-fidelity gate guards all 41.** A network-free structural check asserts each read function
  delegates to its **identically-named** `Stub` function (`snake(RPC) == fun name == stub fun name`). The parity
  scaffold proves a function of the right name and arity exists; the fidelity gate proves its body calls the *right*
  stub — closing the copy-paste wrong-stub class (`def shares` calling `&Stub.bonds/3`, which compiles and passes the
  scaffold).

The vertical is proven both ways, like 9.1. A **pure** Tier-1 suite (the committed `--no-start` rung gate, network-free,
deterministic) gates the grown scaffold, the Money property, and the fidelity check. A **live** representative subset
runs against the real sandbox endpoint with `INVEST_TOKEN` (read from the env only): open a sandbox account → an
Instruments read that returns data → `get_last_prices/2` and a `Money.from_quotation/1` decode → `get_portfolio/2` and a
`Money.from_money_value/1` decode → close. The hard floor is **≥1 Instruments read dialed AND ≥1 Money decode from a
real money-dense response** (RQ-3, the Operator's hard gate).

## What this slice builds

The authoritative surface — the 41 functions, each with its proto RPC, request, response, and the `&Stub.<fun>/3` it
delegates to — is the 41-function table in [`trd.9.2.specs.md`](trd.9.2.specs.md). In summary:

- **`Investex.Instruments` (27)** — the unary `InstrumentsService` reads: the `*By` single-instrument reads
  (`bond_by`, `share_by`, `currency_by`, …) and the list / metadata reads (`shares`, `bonds`, `find_instrument`,
  `get_dividends`, `get_assets`, `get_brands`, …). One subtlety the spec pins so it is not invented: `GetBrandBy`
  returns the **bare `Brand`** message, not a `BrandResponse`.
- **`Investex.MarketData` (7)** — the unary `MarketDataService` reads: `get_candles`, `get_last_prices`,
  `get_order_book`, `get_trading_status(es)`, `get_last_trades`, `get_close_prices`. `get_last_prices` and
  `get_order_book` are the money-dense ones (a `Quotation` price). The 2 `MarketDataStreamService` RPCs are 9.5.
- **`Investex.Operations` (7)** — the unary `OperationsService` reads: `get_operations`, `get_portfolio`,
  `get_positions`, `get_withdraw_limits`, `get_broker_report`, `get_dividends_foreign_issuer`,
  `get_operations_by_cursor`. `get_portfolio` is the money-dense one (`MoneyValue` totals + a `Quotation`
  `expected_yield`). The 2 `OperationsStreamService` RPCs are 9.5. (The `Sandbox.*` mirrors of these reads are 9.4.)

Plus the grown `test/parity_test.exs` (7 → 48), the Money exercise (pure property + live decode), the
pass-through-fidelity gate (G-FID, all 41), the rung gate `echo/rungs/exchange/trd_9_2_check.{exs,out}` (the Tier-1
gates, network-free, reproducible), and the live read tier extending `test/sandbox_live_test.exs`.

## The pass-through, in one function

Every read function is the `Investex.Users` shape, with the typed request passed in rather than built from an
`account_id`:

```elixir
defmodule Investex.MarketData do
  alias Investex.Caller
  alias Tinkoff.Public.Invest.Api.Contract.V1, as: Proto
  alias Tinkoff.Public.Invest.Api.Contract.V1.MarketDataService.Stub

  @doc "GetLastPrices — last prices for instruments (marketdata.proto; money-dense: LastPrice.price = Quotation)."
  @spec get_last_prices(Investex.Client.t(), Proto.GetLastPricesRequest.t()) ::
          {:ok, Proto.GetLastPricesResponse.t()} | {:error, Investex.Error.t()}
  def get_last_prices(client, %Proto.GetLastPricesRequest{} = request) do
    Caller.unary(client, &Stub.get_last_prices/3, request)
  end
  # ... 6 more, the same shape ...
end
```

The retry policy, the Bearer + `x-app-name` metadata, the channel, and the typed-error folding all come from the shared
`Investex.Caller` seam — the read functions add no transport behavior, they only name an RPC and forward a request. That
is why the diff stays inside the three new modules and the two grown test files, and touches no transport surface.

## What this slice does NOT build (deferred — named so the absence is a decision)

- **The branded `ORD` edge-validation seam (INV-4 / G3) → 9.3.** Every read here is read-only; no order is placed.
  `post_order` / `replace_order` / `Sandbox.post_order` and the `EchoData` ORD validation are 9.3. `{:echo_data,
  in_umbrella: true}` stays declared but **not exercised**, exactly as in 9.1.
- **`OrdersService` (5) + `OrdersStreamService` (1) + `StopOrdersService` (3) + the 5 sandbox order methods → 9.3.**
- **The rest of `SandboxService` (6 methods: `pay_in` + the positions / operations / operations-by-cursor / portfolio /
  withdraw-limits mirror) → 9.4.** 9.2 builds the non-sandbox `Operations.get_portfolio/2` etc.; the `Sandbox.*`
  mirrors are 9.4.
- **The 5 streams (`MarketDataStream`, `MarketDataServerSideStream`, `TradesStream`, `PortfolioStream`,
  `PositionsStream`; INV-7) → 9.5.** They live in the separate `*StreamService` modules; 9.2 maps none of them.
- **Full 72-RPC parity (G1 complete, the "count prints 72 implemented" assertion) → 9.5.** 9.2 grows the scaffold to 48
  implemented / 24 pending.
- **No transport change.** `Client`, `Caller`, `Retry`, `Config`, `Error`, `Money` (the public surfaces) are reused
  unchanged; `Money` gains tests, not new functions. `echo/mix.lock` is **not** touched — no new dep.

## The Exchange seam (unchanged, named for context)

investex is the BEAM-native venue client; 9.2 grows its read surface but does not change the two seams TRD.9 fixes. The
branded `ORD` order-id seam (the Gateway-minted id passed to `PostOrder` as the venue idempotency key, INV-4) is 9.3's
to build — 9.2 reads the venue, it does not write to it. The Go worker tier stays alongside for GPU money-math over the
`{units, nano}` data investex decodes; no float crosses either boundary (INV-3). The read services are the data source
that feeds both the matching core and that worker tier.

## Map

The slice spec (authoritative): [`trd.9.2.specs.md`](trd.9.2.specs.md). The full rung: [`trd.9.specs.md`](trd.9.specs.md)
· [`trd.9.stories.md`](trd.9.stories.md) · [`trd.9.llms.md`](trd.9.llms.md). The transport spine it builds on:
[`trd.9.1.specs.md`](trd.9.1.specs.md) · [`trd.9.1.md`](trd.9.1.md). The runbook: [`trd.9.2.prompt.md`](trd.9.2.prompt.md).
System: [`exchange.specs.md`](exchange.specs.md). Ladder: [`exchange.roadmap.md`](exchange.roadmap.md). The pass-through
template: `echo/apps/investex/lib/investex/users.ex`. The parity source: the committed generated modules
(`echo/apps/investex/lib/investex/proto/.../v1/{instruments,marketdata,operations}.pb.ex`) and the Tinkoff Invest
contracts (`github.local/invest-api-go-sdk/proto/{instruments,marketdata,operations}.proto`).
