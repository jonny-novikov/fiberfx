# TRD.9 · investex — Design and Implementation (specs)

<show-structure depth="2"/>

> Authoritative for rung TRD.9. The chapter ([`trd.9.md`](trd.9.md)) narrates it; the runbook
> ([`trd.9.llms.md`](trd.9.llms.md)) derives from it; the stories ([`trd.9.stories.md`](trd.9.stories.md)) are its
> acceptance gates. Feedback edits this file, not the implementation. **Status: PROPOSED.** This rung is the
> *specification* — no code ships here. Definition of done for each later build rung: a committed transcript at
> `echo/rungs/exchange/trd_9_N_check.out`, exit zero, every gate line green. Stands on the as-built `echo_data` canon
> and the committed Tinkoff Invest contracts; it founds a new umbrella app, `echo/apps/investex`.

## What this rung is

investex is the BEAM-native Tinkoff Invest API client — `echo/apps/investex`, OTP `:investex`, modules `Investex.*` —
covering the same surface the Go SDK (`invest-api-go-sdk`) covers: **10 gRPC services, 72 RPCs**. It is the
Elixir-side equivalent of the Go SDK's venue-client seat: a gRPC transport over TLS with bearer-token auth, generated
protobuf message modules, one Elixir function per RPC across stateless per-service modules, supervised processes for
the bidirectional streams, money decoded to the Exchange canon's `{units, nano}` integer pair, and a two-tier test
strategy — a pure default suite plus an opt-in sandbox-keyed integration suite. The roadmap named a *Go worker tier —
the Tinkoff Invest gRPC client tier* with an open question on whether to give it a dedicated quad; the Operator
answered by asking for a first-class Elixir client, so the BEAM is never blocked on the Go tier for venue I/O.

**This rung authors the chapter quad and the sub-rung ladder.** Each build rung TRD.9.1–9.5 is a separate, later
x-mode run, **HIGH risk** (real network I/O, a live secret, auth) and therefore warranting a dedicated Apollo
evaluator and the secret-hygiene gate (INV-9) at build time.

## Invariants

- **INV-1 — full parity, measured.** Every one of the 10 Tinkoff Invest gRPC services and all 72 RPCs the Go SDK
  covers maps to exactly one named `Investex.<Service>.<fun>/n`. Parity is a green/red gate (a test enumerating the
  proto service definitions against the investex functions), never an informal claim. The manifest below is the
  contract.
- **INV-2 — one function per RPC.** Each unary RPC is one public Elixir function on its per-service module; each of
  the 5 streaming RPCs is one supervised stream process. No RPC is hidden, merged, or duplicated.
- **INV-3 — money is `{units, nano}` integers, never float.** `Quotation` and `MoneyValue` decode to `{units, nano}`
  integer pairs through `Investex.Money`. No float appears in any decoded money value, request, or response shape the
  client exposes. The Go SDK's `Quotation.ToFloat()` / `FloatToQuotation` is deliberately **not** mirrored.
- **INV-4 — the branded `ORD` seam.** The `order_id` of `PostOrder` / `PostSandboxOrder` (the venue idempotency key)
  accepts a branded `ORD` id minted by `EchoData` and validates it at the edge before the request crosses the wire;
  `ReplaceOrder`'s fresh-id field (the proto `IdempotencyKey`) accepts a branded id likewise. This one field is the
  seam joining the Exchange platform to the venue.
- **INV-5 — the client owns the channel.** A supervised `Investex.Client` owns the `GRPC.Channel` and the resolved
  `Investex.Config` (reconnect and the bearer / `x-app-name` metadata in one place). The per-service modules are
  stateless given a client handle. investex is **lib-only** — no `mod:`, nothing booted at app start; the consumer
  supervises the client.
- **INV-6 — pure retry decision.** The retry policy mirrors the Go interceptor: linear 500 ms backoff on
  `Unavailable` / `Internal` up to `max_retries`, and a separate, longer, silent wait on `ResourceExhausted` honoring
  `x-ratelimit-reset`. The retry **decision** — `(status, attempt, headers) -> {:retry, wait_ms} | :give_up` — is a
  pure function, unit-tested with no network.
- **INV-7 — streams resubscribe on reconnect.** Each streaming RPC is a supervised GenServer owning the stream, the
  subscription set, and the `Ping` keepalive; on reconnect it resubscribes the full set. The raw gRPC stream is not
  exposed to the caller (it would lose resubscribe and subscription management).
- **INV-8 — two test tiers.** A pure default suite (`mix test` + the `--no-start` rung gate): codegen round-trip,
  money codec, config defaults, request builders, branded-id validation, the retry-decision function — no network,
  deterministic, CI-safe. An opt-in sandbox suite (`@tag :sandbox`, excluded by default): the real sandbox endpoint
  with `INVEST_TOKEN`. The sandbox suite **skips** (does not fail) when the key is absent.
- **INV-9 — secret hygiene (hard).** `INVEST_TOKEN` is read from the environment only (`System.get_env` /
  `System.fetch_env!`) — never hardcoded, never committed, never logged, never written into a transcript or any doc.
  The `.env.test` file stays in `github.local` (a gitignored external repo) and is read at test time, never copied
  into the repo. The token **value** appears in nothing this rung or any build rung writes — not the spec, not the
  ledger, not a gate `.out`.

## The as-built surface this rung consumes (pinned, not rebuilt)

```elixir
# The canon, in-umbrella (echo/apps/echo_data) — the {units,nano} money pair and the branded id spine.
# investex depends on {:echo_data, in_umbrella: true}; it mints/validates branded ORD ids through the
# as-built EchoData branded-id surface (the exact mint/validate arity is cited by the build rung against
# echo_data, not invented here). echo_data is Ecto-free; the dependency arrow points one way.
EchoData            # branded ids: ORD/FIL/CMD/TXN/ACC/INS, minted at the edge, validated at every door
                    # (exchange.specs.md "Data structures"); byte-ordered by mint time (Appendix F)
```

```text
# The committed Tinkoff Invest contracts — the parity source (github.local/invest-api-go-sdk/proto/*.proto):
#   common.proto · instruments.proto · marketdata.proto · operations.proto
#   orders.proto · sandbox.proto · stoporders.proto · users.proto
# The Go parity reference (github.local/invest-api-go-sdk/investgo/*.go): client.go, config.go,
#   orders.go, sandbox.go, the per-stream clients (md_stream*.go, *_stream_client.go,
#   portfolio_stream.go, positions_stream.go, trades_stream.go).
# Transport reference: github.local/investAPI/src/docs/grpc.md + the per-service heads.
```

The umbrella's HTTP/2 stack (`mint`, `castore`, `hpax`) is already locked in `mix.lock`, so elixir-grpc over the Mint
adapter adds **no new transport stack**. `:grpc` and `:protobuf` are themselves new hex deps that
`echo/apps/investex/mix.exs` declares — an umbrella app does not inherit a transitive lock as a compile-visible edge.

## The umbrella app (pinned)

```elixir
# echo/apps/investex/mix.exs — lib-only (the apps/exchange precedent: no mod:, extra_applications: [:logger]).
def application, do: [extra_applications: [:logger]]      # NO mod: — the consumer supervises Investex.Client

defp deps do
  [
    {:echo_data, in_umbrella: true},      # the {units,nano} + branded-id canon
    {:grpc, "~> 0.9"},                    # elixir-grpc over the Mint adapter (exact minor pinned at build)
    {:protobuf, "~> 0.13"},               # elixir-protobuf — the generated message codec
    {:stream_data, "~> 1.0", only: :test} # property tests; already locked at the umbrella root
  ]
end
```

## The money vocabulary (the canon, decoded — never float)

```elixir
@type money :: {units :: integer(), nano :: integer()}   # Quotation / MoneyValue; common.proto:28-48

Investex.Money.from_quotation(%Investex.Proto.Quotation{}) :: money()
Investex.Money.to_quotation(money()) :: %Investex.Proto.Quotation{}
Investex.Money.from_money_value(%Investex.Proto.MoneyValue{}) :: {money(), currency :: String.t()}
```

`Quotation` is `{units :: int64, nano :: int32}` and `MoneyValue` is `{currency, units, nano}` (common.proto:28-48).
Both decode to the integer `{units, nano}` pair the whole Exchange platform speaks; `from_money_value/1` additionally
returns the ISO currency string. No conversion to or from a float exists in the surface — that is the deliberate
divergence from the Go SDK (converters.go's `FloatToQuotation`/`ToFloat`), recorded as INV-3.

## Config & auth (pinned — mirroring investgo Config)

```elixir
%Investex.Config{
  endpoint: String.t(),                       # default "sandbox-invest-public-api.tinkoff.ru:443"
  token: String.t(),                          # read from INVEST_TOKEN env (INV-9) — never a literal in the struct
  app_name: String.t(),                       # default "jonnify.investex" (the recommended <nick>.<repo> form)
  account_id: String.t() | nil,
  disable_resource_exhausted_retry: boolean(), # default false
  disable_all_retry: boolean(),                # default false (true => max_retries 0)
  max_retries: non_neg_integer()               # default 3
}
```

Auth is per-RPC metadata: `authorization: "Bearer <token>"` and `x-app-name: <app_name>` (client.go:37-39,72-78;
grpc.md). Endpoints: production `invest-public-api.tinkoff.ru:443`, sandbox
`sandbox-invest-public-api.tinkoff.ru:443`, both TLS (grpc.md). Defaults mirror `setDefaultConfig`
(client.go:116-128), with the app-name renamed from the Go `invest-api-go-sdk` to the own-repo `jonnify.investex`.

## Surface, pinned (the client, the per-service modules, the streams)

```elixir
# The supervised client — owns the channel + config (INV-5). The Go Client{conn, Config} (client.go:26-31).
Investex.Client.start_link(config :: %Investex.Config{}) :: {:ok, pid} | {:error, term}
Investex.Client.channel(client) :: GRPC.Channel.t()        # the resolved channel, for the per-service calls
Investex.Client.stop(client) :: :ok                        # conn close (client.go:271-274)

# Each unary per-service function: (client, typed_request) -> {:ok, response} | {:error, Investex.Error.t()}.
# The seven unary modules: Instruments, MarketData, Operations, Orders, StopOrders, Users, Sandbox.
# (The full 72-RPC mapping is the parity manifest below.) Example shapes:
Investex.Users.get_accounts(client) :: {:ok, %Investex.Proto.GetAccountsResponse{}} | {:error, ...}
Investex.Orders.post_order(client, %Investex.Orders.PostOrder{}) :: {:ok, ...} | {:error, ...}

# Each of the 5 streaming RPCs: a supervised GenServer owning the stream (INV-7).
Investex.MarketDataStream.start_link(client, subscriber :: pid, opts) :: {:ok, pid}
Investex.MarketDataStream.subscribe_candles(stream, instrument_ids, interval, opts) :: :ok
# (the subscription verbs mirror the Go MarketDataStream Subscribe*/UnSubscribe*; md_stream.go)
```

The retry decision is pinned as a pure function (INV-6):

```elixir
Investex.Retry.decide(status :: atom(), attempt :: non_neg_integer(), headers :: map())
  :: {:retry, wait_ms :: non_neg_integer()} | :give_up
```

## The parity manifest (10 services · 72 RPCs → named functions)

Every RPC below is quoted from its proto `service`/`rpc` definition (cited per service). Each maps to one
`Investex.<Service>.<fun>/n`. Convention: the client handle is the first argument; a request-bearing RPC takes a typed
request struct (`/2`); a read taking only an account id takes the id (`/2`); a no-argument read is `/1`. The build
rung pins exact arities against the as-built request builders — the names are frozen here, the per-argument shape is
the build rung's to realize against the proto request messages.

### InstrumentsService — 27 (instruments.proto:21-101)

| RPC (proto) | request → response | Investex function |
|---|---|---|
| `TradingSchedules` | `TradingSchedulesRequest` → `TradingSchedulesResponse` | `Investex.Instruments.trading_schedules/2` |
| `BondBy` | `InstrumentRequest` → `BondResponse` | `Investex.Instruments.bond_by/2` |
| `Bonds` | `InstrumentsRequest` → `BondsResponse` | `Investex.Instruments.bonds/2` |
| `GetBondCoupons` | `GetBondCouponsRequest` → `GetBondCouponsResponse` | `Investex.Instruments.get_bond_coupons/2` |
| `CurrencyBy` | `InstrumentRequest` → `CurrencyResponse` | `Investex.Instruments.currency_by/2` |
| `Currencies` | `InstrumentsRequest` → `CurrenciesResponse` | `Investex.Instruments.currencies/2` |
| `EtfBy` | `InstrumentRequest` → `EtfResponse` | `Investex.Instruments.etf_by/2` |
| `Etfs` | `InstrumentsRequest` → `EtfsResponse` | `Investex.Instruments.etfs/2` |
| `FutureBy` | `InstrumentRequest` → `FutureResponse` | `Investex.Instruments.future_by/2` |
| `Futures` | `InstrumentsRequest` → `FuturesResponse` | `Investex.Instruments.futures/2` |
| `OptionBy` | `InstrumentRequest` → `OptionResponse` | `Investex.Instruments.option_by/2` |
| `Options` | `InstrumentsRequest` → `OptionsResponse` | `Investex.Instruments.options/2` |
| `OptionsBy` | `FilterOptionsRequest` → `OptionsResponse` | `Investex.Instruments.options_by/2` |
| `ShareBy` | `InstrumentRequest` → `ShareResponse` | `Investex.Instruments.share_by/2` |
| `Shares` | `InstrumentsRequest` → `SharesResponse` | `Investex.Instruments.shares/2` |
| `GetAccruedInterests` | `GetAccruedInterestsRequest` → `GetAccruedInterestsResponse` | `Investex.Instruments.get_accrued_interests/2` |
| `GetFuturesMargin` | `GetFuturesMarginRequest` → `GetFuturesMarginResponse` | `Investex.Instruments.get_futures_margin/2` |
| `GetInstrumentBy` | `InstrumentRequest` → `InstrumentResponse` | `Investex.Instruments.get_instrument_by/2` |
| `GetDividends` | `GetDividendsRequest` → `GetDividendsResponse` | `Investex.Instruments.get_dividends/2` |
| `GetAssetBy` | `AssetRequest` → `AssetResponse` | `Investex.Instruments.get_asset_by/2` |
| `GetAssets` | `AssetsRequest` → `AssetsResponse` | `Investex.Instruments.get_assets/2` |
| `GetFavorites` | `GetFavoritesRequest` → `GetFavoritesResponse` | `Investex.Instruments.get_favorites/2` |
| `EditFavorites` | `EditFavoritesRequest` → `EditFavoritesResponse` | `Investex.Instruments.edit_favorites/2` |
| `GetCountries` | `GetCountriesRequest` → `GetCountriesResponse` | `Investex.Instruments.get_countries/2` |
| `FindInstrument` | `FindInstrumentRequest` → `FindInstrumentResponse` | `Investex.Instruments.find_instrument/2` |
| `GetBrands` | `GetBrandsRequest` → `GetBrandsResponse` | `Investex.Instruments.get_brands/2` |
| `GetBrandBy` | `GetBrandRequest` → `Brand` | `Investex.Instruments.get_brand_by/2` |

### MarketDataService — 7 (marketdata.proto:18-36)

| RPC (proto) | request → response | Investex function |
|---|---|---|
| `GetCandles` | `GetCandlesRequest` → `GetCandlesResponse` | `Investex.MarketData.get_candles/2` |
| `GetLastPrices` | `GetLastPricesRequest` → `GetLastPricesResponse` | `Investex.MarketData.get_last_prices/2` |
| `GetOrderBook` | `GetOrderBookRequest` → `GetOrderBookResponse` | `Investex.MarketData.get_order_book/2` |
| `GetTradingStatus` | `GetTradingStatusRequest` → `GetTradingStatusResponse` | `Investex.MarketData.get_trading_status/2` |
| `GetTradingStatuses` | `GetTradingStatusesRequest` → `GetTradingStatusesResponse` | `Investex.MarketData.get_trading_statuses/2` |
| `GetLastTrades` | `GetLastTradesRequest` → `GetLastTradesResponse` | `Investex.MarketData.get_last_trades/2` |
| `GetClosePrices` | `GetClosePricesRequest` → `GetClosePricesResponse` | `Investex.MarketData.get_close_prices/2` |

### MarketDataStreamService — 2 (marketdata.proto:41-44) · streaming

| RPC (proto) | shape | Investex stream |
|---|---|---|
| `MarketDataStream` | bidi: `stream MarketDataRequest` → `stream MarketDataResponse` | `Investex.MarketDataStream` (GenServer) |
| `MarketDataServerSideStream` | server: `MarketDataServerSideStreamRequest` → `stream MarketDataResponse` | `Investex.MarketDataStream` server-side mode |

### OperationsService — 7 (operations.proto:20-39)

| RPC (proto) | request → response | Investex function |
|---|---|---|
| `GetOperations` | `OperationsRequest` → `OperationsResponse` | `Investex.Operations.get_operations/2` |
| `GetPortfolio` | `PortfolioRequest` → `PortfolioResponse` | `Investex.Operations.get_portfolio/2` |
| `GetPositions` | `PositionsRequest` → `PositionsResponse` | `Investex.Operations.get_positions/2` |
| `GetWithdrawLimits` | `WithdrawLimitsRequest` → `WithdrawLimitsResponse` | `Investex.Operations.get_withdraw_limits/2` |
| `GetBrokerReport` | `BrokerReportRequest` → `BrokerReportResponse` | `Investex.Operations.get_broker_report/2` |
| `GetDividendsForeignIssuer` | `GetDividendsForeignIssuerRequest` → `GetDividendsForeignIssuerResponse` | `Investex.Operations.get_dividends_foreign_issuer/2` |
| `GetOperationsByCursor` | `GetOperationsByCursorRequest` → `GetOperationsByCursorResponse` | `Investex.Operations.get_operations_by_cursor/2` |

### OperationsStreamService — 2 (operations.proto:44-47) · streaming

| RPC (proto) | shape | Investex stream |
|---|---|---|
| `PortfolioStream` | `PortfolioStreamRequest` → `stream PortfolioStreamResponse` | `Investex.PortfolioStream` (GenServer) |
| `PositionsStream` | `PositionsStreamRequest` → `stream PositionsStreamResponse` | `Investex.PositionsStream` (GenServer) |

### OrdersService — 5 (orders.proto:24-36)

| RPC (proto) | request → response | Investex function |
|---|---|---|
| `PostOrder` | `PostOrderRequest` → `PostOrderResponse` | `Investex.Orders.post_order/2` *(branded `ORD` order_id — INV-4)* |
| `CancelOrder` | `CancelOrderRequest` → `CancelOrderResponse` | `Investex.Orders.cancel_order/2` |
| `GetOrderState` | `GetOrderStateRequest` → `OrderState` | `Investex.Orders.get_order_state/2` |
| `GetOrders` | `GetOrdersRequest` → `GetOrdersResponse` | `Investex.Orders.get_orders/2` |
| `ReplaceOrder` | `ReplaceOrderRequest` → `PostOrderResponse` | `Investex.Orders.replace_order/2` *(branded idempotency key — INV-4)* |

### OrdersStreamService — 1 (orders.proto:17) · streaming

| RPC (proto) | shape | Investex stream |
|---|---|---|
| `TradesStream` | `TradesStreamRequest` → `stream TradesStreamResponse` | `Investex.TradesStream` (GenServer) |

### StopOrdersService — 3 (stoporders.proto:19-25)

| RPC (proto) | request → response | Investex function |
|---|---|---|
| `PostStopOrder` | `PostStopOrderRequest` → `PostStopOrderResponse` | `Investex.StopOrders.post_stop_order/2` |
| `GetStopOrders` | `GetStopOrdersRequest` → `GetStopOrdersResponse` | `Investex.StopOrders.get_stop_orders/2` |
| `CancelStopOrder` | `CancelStopOrderRequest` → `CancelStopOrderResponse` | `Investex.StopOrders.cancel_stop_order/2` |

### UsersService — 4 (users.proto:19-28)

| RPC (proto) | request → response | Investex function |
|---|---|---|
| `GetAccounts` | `GetAccountsRequest` → `GetAccountsResponse` | `Investex.Users.get_accounts/1` *(the canonical sandbox smoke)* |
| `GetMarginAttributes` | `GetMarginAttributesRequest` → `GetMarginAttributesResponse` | `Investex.Users.get_margin_attributes/2` |
| `GetUserTariff` | `GetUserTariffRequest` → `GetUserTariffResponse` | `Investex.Users.get_user_tariff/1` |
| `GetInfo` | `GetInfoRequest` → `GetInfoResponse` | `Investex.Users.get_info/1` |

### SandboxService — 14 (sandbox.proto:20-59)

| RPC (proto) | request → response | Investex function | Build rung |
|---|---|---|---|
| `OpenSandboxAccount` | `OpenSandboxAccountRequest` → `OpenSandboxAccountResponse` | `Investex.Sandbox.open_account/1` | 9.1 |
| `GetSandboxAccounts` | `GetAccountsRequest` → `GetAccountsResponse` | `Investex.Sandbox.get_accounts/1` | 9.1 |
| `CloseSandboxAccount` | `CloseSandboxAccountRequest` → `CloseSandboxAccountResponse` | `Investex.Sandbox.close_account/2` | 9.1 |
| `PostSandboxOrder` | `PostOrderRequest` → `PostOrderResponse` | `Investex.Sandbox.post_order/2` *(branded `ORD` — INV-4)* | 9.3 |
| `ReplaceSandboxOrder` | `ReplaceOrderRequest` → `PostOrderResponse` | `Investex.Sandbox.replace_order/2` | 9.3 |
| `GetSandboxOrders` | `GetOrdersRequest` → `GetOrdersResponse` | `Investex.Sandbox.get_orders/2` | 9.3 |
| `CancelSandboxOrder` | `CancelOrderRequest` → `CancelOrderResponse` | `Investex.Sandbox.cancel_order/2` | 9.3 |
| `GetSandboxOrderState` | `GetOrderStateRequest` → `OrderState` | `Investex.Sandbox.get_order_state/2` | 9.3 |
| `GetSandboxPositions` | `PositionsRequest` → `PositionsResponse` | `Investex.Sandbox.get_positions/2` | 9.4 |
| `GetSandboxOperations` | `OperationsRequest` → `OperationsResponse` | `Investex.Sandbox.get_operations/2` | 9.4 |
| `GetSandboxOperationsByCursor` | `GetOperationsByCursorRequest` → `GetOperationsByCursorResponse` | `Investex.Sandbox.get_operations_by_cursor/2` | 9.4 |
| `GetSandboxPortfolio` | `PortfolioRequest` → `PortfolioResponse` | `Investex.Sandbox.get_portfolio/2` | 9.4 |
| `SandboxPayIn` | `SandboxPayInRequest` → `SandboxPayInResponse` | `Investex.Sandbox.pay_in/2` | 9.4 |
| `GetSandboxWithdrawLimits` | `WithdrawLimitsRequest` → `WithdrawLimitsResponse` | `Investex.Sandbox.get_withdraw_limits/2` | 9.4 |

**Total: 27 + 7 + 2 + 7 + 2 + 5 + 1 + 3 + 4 + 14 = 72 RPCs across 10 services.** (The runbook's "~75" prose estimate
resolves to an exact 72; the two trading-status RPCs the prose collapsed are distinct in the proto and carried as
distinct functions — L-1.)

## Decomposition (the sub-rung ladder — the build order)

Each sub-rung is a separate, later x-mode run with its own Apollo (HIGH risk: network / live secret / auth).

- **TRD.9.1 — the transport spine.** `Investex.Config` + the protoc-gen-elixir codegen of the 8 contracts (the
  committed `Investex.Proto.*` modules + the regen task) + `Investex.Client` (channel, TLS, Bearer + `x-app-name`
  metadata, endpoint select) + the retry / rate-limit policy (the pure `Investex.Retry.decide/3`) + **UsersService**
  end-to-end (4 functions; `get_accounts/1` the canonical sandbox smoke) + the **minimal sandbox bootstrap**
  (`Investex.Sandbox.open_account/1` · `get_accounts/1` · `close_account/2` — enough to obtain an account to test
  against, L-4) + the two-tier test harness. Proves the whole vertical: pure-gated and sandbox-verified.
- **TRD.9.2 — the read services.** InstrumentsService (27) + MarketDataService (7) + OperationsService (7) — unary,
  read-only. The parity-manifest rows, pure request builders, and sandbox reads.
- **TRD.9.3 — the trading services.** OrdersService (5) + StopOrdersService (3) — the write side, the branded `ORD`
  seam (INV-4), and the sandbox order lifecycle via SandboxService's 5 order methods (`post_order` · `replace_order`
  · `get_orders` · `cancel_order` · `get_order_state`).
- **TRD.9.4 — the full SandboxService.** The remaining 6 sandbox methods (`pay_in` + the positions / operations /
  operations-by-cursor / portfolio / withdraw-limits mirror) — complete sandbox parity.
- **TRD.9.5 — the streaming services.** MarketDataStream (bidi) + MarketDataServerSideStream + TradesStream +
  PortfolioStream + PositionsStream — the OTP stream-process model (INV-7): resubscribe-on-reconnect, the `Ping`
  keepalive, decoded delivery to a subscriber. The hardest rung, last.

**SandboxService placement (recorded, not an Operator fork — D-12).** SandboxService is split across 9.1 / 9.3 / 9.4
rather than one block. Reasoning: the Go SDK auto-bootstraps a sandbox account inside its client constructor
(client.go:90-111), so the bootstrap trio is needed at 9.1 to make the harness testable at all; the sandbox order
methods take the same `PostOrderRequest` as OrdersService and belong with 9.3's order lifecycle; the remainder
completes at 9.4. Each sandbox method lands beside the real service it mirrors (3 + 5 + 6 = 14).

## Mars implementation notes (for the build rungs)

- **No float, anywhere.** Money is integer `{units, nano}` through `Investex.Money`; a property asserts no float
  appears in any decoded money value. Do **not** port `FloatToQuotation` / `ToFloat` (converters.go) — INV-3.
- **The branded `ORD` id is validated at the edge, not minted blindly.** `post_order` / `replace_order` /
  `Sandbox.post_order` accept a branded id and validate it through the as-built `echo_data` surface before building
  the proto request; an unbranded or wrong-namespace id is refused at the door (INV-4). Cite the real `echo_data`
  mint/validate arity at build time — do not invent it.
- **The token is env-only.** Read `INVEST_TOKEN` via `System.get_env` / `System.fetch_env!`; never put a literal
  token in a struct default, a config file, a log line, a test fixture, or a gate transcript (INV-9). The sandbox
  `setup` reads the env and `ExUnit`-skips on `nil`.
- **The retry decision is pure.** `Investex.Retry.decide/3` takes a status, an attempt count, and the response
  headers and returns `{:retry, wait_ms} | :give_up` with no `Process.sleep`, no clock, no network — the interceptor
  that *applies* it is the impure shell; the decision is unit-tested alone (INV-6).
- **The generated proto modules are committed.** Run protoc + protoc-gen-elixir once against the 8 contracts, commit
  `Investex.Proto.*`, and document the regen task; do not put protoc on the compile path (INV / D-3).
- **The client is lib-only.** No `mod:` in `mix.exs`; `Investex.Client.start_link/1` is started by the *consumer's*
  supervision tree (or a test), never by `:investex` itself (INV-5).
- **One function per RPC, named exactly as the manifest.** The parity-check test enumerates the proto and asserts each
  RPC has its mapped function; a missing or misnamed function fails the gate (INV-1, INV-2).

## The cross-runtime / Exchange seam (how investex meets the platform)

investex is the BEAM-native venue client; it does **not** replace the Go worker tier — it complements it. The two
seams this rung fixes:

- **The branded `ORD` order-id seam (inward).** When the Exchange platform places a venue order, the branded `ORD` id
  minted at the Gateway (TRD.1) is the `order_id` investex passes to `PostOrder` as the venue idempotency key (INV-4).
  This is the same id the platform uses as the job key and the venue idempotency key already named in the roadmap's
  *Go worker tier* — one id, validated at every door, now also the venue's dedup key.
- **The Go worker tier (alongside).** The Go worker tier stays for GPU-accelerated money-math (mark-to-market,
  margin, risk, analytics over fills) — numeric throughput where Go pays — fed by the data investex (and the BEAM
  matching core) produce. investex gives the BEAM a first-class venue client so venue I/O is never blocked on the Go
  fleet; the Go tier consumes `{units, nano}` money and branded ids verbatim, the same integer money investex decodes.
  No float crosses either boundary (INV-3). The job payload schema and the worker idempotent-handler contract are the
  Go tier's own rungs; TRD.9 fixes only the BEAM-native client and its branded-id seam.

## Acceptance gates (folded; the stories expand them)

- **G1 — parity is complete and measured.** A parity-check test enumerates the 10 proto service definitions and
  asserts each of the 72 RPCs has its mapped `Investex.<Service>.<fun>/n`; the count prints 72; exit zero (INV-1).
- **G2 — money round-trips as integers.** `from_quotation` / `to_quotation` / `from_money_value` round-trip
  `{units, nano}` integer pairs with no float in any value; a property holds over generated money; exit zero (INV-3).
- **G3 — the branded `ORD` id is validated at the edge.** `post_order` / `replace_order` accept a branded `ORD` id and
  refuse an unbranded or wrong-namespace id before the request is built; asserted without a network; exit zero (INV-4).
- **G4 — the retry decision is pure and correct.** `Investex.Retry.decide/3` returns `{:retry, 500}` on
  `Unavailable` / `Internal` under the cap, a longer wait honoring `x-ratelimit-reset` on `ResourceExhausted`, and
  `:give_up` past `max_retries` — unit-tested with no network; a grep shows no clock / sleep / `Process.*` in the
  decision function; exit zero (INV-6).
- **G5 — the pure suite is network-free and the sandbox suite skips keyless.** The default `mix test` (and the
  `--no-start` rung gate) touches no network and is deterministic; the `@tag :sandbox` suite is excluded by default
  and **skips** (does not fail) when `INVEST_TOKEN` is absent; exit zero (INV-8).
- **G6 — the sandbox vertical works (key present).** With `INVEST_TOKEN` set, the sandbox suite opens a sandbox
  account, reads it via `get_accounts`, places and reads a sandbox order, and closes the account — a real round trip
  against the sandbox endpoint; exit zero (INV-8, the sandbox tier).
- **G7 — no token value anywhere.** A grep of the repo (spec, code, fixtures, gate `.out`, ledger) for a
  token-shaped string finds none; the token is read from the environment only (INV-9). *(This gate also guards this
  spec rung.)*

## Map

Chapter: [`trd.9.md`](trd.9.md). Stories: [`trd.9.stories.md`](trd.9.stories.md). Runbook:
[`trd.9.llms.md`](trd.9.llms.md). System: [`exchange.specs.md`](exchange.specs.md). Ladder:
[`exchange.roadmap.md`](exchange.roadmap.md). The seam: [`trd.2.md`](trd.2.md) ("The Go pricing seam, named") and the
*Go worker tier* section of [`trd.progress.md`](trd.progress.md). The parity source: the committed Tinkoff Invest
contracts and the Go SDK, cited by path in [`trd.9.llms.md`](trd.9.llms.md).
