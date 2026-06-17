# TRD.9.2 · The Read Services — Design and Implementation (specs)

<show-structure depth="2"/>

> Authoritative for rung **TRD.9.2** — the second shippable slice of TRD.9 ([`trd.9.specs.md`](trd.9.specs.md) is the
> full rung; this file is the read-services carve-out the build delivers now). The chapter ([`trd.9.2.md`](trd.9.2.md))
> narrates it. The transport spine it builds on is [`trd.9.1.specs.md`](trd.9.1.specs.md) (shipped, reused unchanged).
> **Status: PROPOSED.** Definition of done: a committed transcript at `echo/rungs/exchange/trd_9_2_check.out`, exit
> zero, every Tier-1 gate line green (the `trd_9_1_check.exs` rung-gate pattern), AND the live representative-subset
> round-trip PASSED (the Operator's hard gate). Feedback edits this file, not the implementation. **Framing (propagate
> this clause): third person for any agent; no gendered pronouns; no perceptual or interior-state verbs; no first-person
> narration.** **Secret hygiene (INV-9, hard): the `INVEST_TOKEN` value appears in nothing this rung writes — read it
> from the environment only.**

## What TRD.9.2 is — and is not

TRD.9.2 builds the **read services** as a thin parity layer over the 9.1 transport, reused unchanged. It adds three
new stateless modules — `Investex.Instruments` (27 RPCs) · `Investex.MarketData` (7) · `Investex.Operations` (7) =
**41 read-only unary functions** — each a 1:1 pass-through that mirrors the as-built `Investex.Users`: it takes a typed
`%Proto.<Request>{}` and delegates to `Investex.Caller.unary(client, &…Service.Stub.<fun>/3, request)`, returning
`{:ok, %Proto.<Response>{}} | {:error, Investex.Error.t()}`. It grows the parity scaffold (`@implemented` **7 → 48**,
pending **65 → 24**), exercises `Investex.Money` against the money-dense read responses (pure **and** against real
venue data), and adds a network-free **pass-through-fidelity** structural gate over all 41. It is pure-gated
(network-free, deterministic) AND live-verified on a representative subset against the real sandbox endpoint.

**In TRD.9.2 (this slice):**

- `Investex.Instruments` — the 27 unary `InstrumentsService` RPCs (instruments.pb.ex:1870-1985), each a 1:1 pass-through;
- `Investex.MarketData` — the 7 unary `MarketDataService` RPCs (marketdata.pb.ex:901-935); the 2 `MarketDataStreamService`
  RPCs are **9.5**;
- `Investex.Operations` — the 7 unary `OperationsService` RPCs (operations.pb.ex:1040-1075); the 2 `OperationsStreamService`
  RPCs are **9.5**;
- the **grown parity scaffold** (`test/parity_test.exs`): `@implemented` 7 → 48, the count assertions (pending 65 → 24,
  implemented 7 → 48), the touched-services assertion generalized to exactly `{Users, Sandbox, Instruments, MarketData,
  Operations}`;
- the **Money exercise** — a pure property over the `Quotation` / `MoneyValue` field shapes the read responses carry,
  AND the live subset decoding real `LastPrice.price` / a real `MoneyValue` total (no new `Investex.Money` function);
- the **pass-through-fidelity** check (NEW, 9.2, G-FID) — a network-free structural assertion that each read function
  delegates to its **identically-named** `Stub` function (`snake(RPC) == fun name == stub fun name`);
- the rung gate `echo/rungs/exchange/trd_9_2_check.exs` + its committed transcript (the Tier-1 gates: the grown
  scaffold, the Money property, the fidelity check; one printed line each; nonzero exit on fail; network-free);
- the **live read tier** extending `test/sandbox_live_test.exs`: the representative subset (open → Instruments read →
  Money-decode last-prices → Money-decode portfolio → close), `@tag :sandbox`, excluded by default, flunks loud keyless
  under `--include sandbox`;
- gates **G1-scaffold@48, G2, G-FID, G5, G6 (9.2 scope), G7** + INV-1/2/3/8/9 (INV-5/6 reaffirmed-unchanged, the
  transport reused, not edited).

**Deferred to 9.3–9.5 (NOT built here — the full rung [`trd.9.specs.md`](trd.9.specs.md) carries them):**

- the branded `ORD` edge-validation seam (INV-4, **gate G3**) — `post_order` / `replace_order` / `Sandbox.post_order`
  and the `EchoData` ORD validation → **9.3** (this slice places no order; every read is read-only; `{:echo_data,
  in_umbrella: true}` stays declared but **not exercised**, exactly as in 9.1);
- `OrdersService` (5) + `OrdersStreamService` (1) + `StopOrdersService` (3) + the 5 sandbox order methods → **9.3**;
- the rest of `SandboxService` (6 methods: `pay_in` + the positions / operations / operations-by-cursor / portfolio /
  withdraw-limits mirror) → **9.4** *(9.2 builds the non-sandbox `Operations.get_portfolio/2` etc.; the `Sandbox.*`
  mirrors of those are 9.4)*;
- the 5 streams (`MarketDataStream`, `MarketDataServerSideStream`, `TradesStream`, `PortfolioStream`, `PositionsStream`;
  INV-7) → **9.5**;
- full 72-RPC parity (**G1 complete**, the "count prints 72 implemented" assertion) → **9.5**. 9.2 grows the scaffold
  to 48 implemented / 24 pending.
- **No transport change.** `Client`, `Caller`, `Retry`, `Config`, `Error`, `Money` (the public surfaces) are reused
  unchanged; `Money` gains tests, not new functions. `echo/mix.lock` is **not** touched — no new dep (`grpc` /
  `protobuf` / `stream_data` / `echo_data` all already locked).

The boundary is the Director's Stage-3 reconcile target: no order method, no `EchoData` ORD validation call, no stream
GenServer, no edit to a transport module's public surface in this slice's diff.

## Invariants (the subset this slice gates)

Inherited verbatim from [`trd.9.specs.md`](trd.9.specs.md); the ones this slice builds and gates:

- **INV-1 — full parity, measured (the growing scaffold, this slice grows it 7 → 48).** The parity-check test
  enumerates the proto service definitions and asserts the **48 implemented** RPCs (UsersService 4 + the sandbox trio 3
  + Instruments 27 + MarketData 7 + Operations 7) map to their named `Investex.<Service>.<fun>/n`, carrying the
  **24 unimplemented** as an explicit pending list; a later un-mapped function (a 9.3+ row landing without its Elixir
  function) or a renamed/dropped function fails the growing gate; rows move pending → asserted monotonically. The full
  "count prints 72 implemented" assertion is **9.5** (inherits 9.1 D-3).
- **INV-2 — one function per RPC.** Each of the 41 read unary RPCs is exactly one public Elixir function on its
  per-service module; no RPC is hidden, merged, or duplicated. The function name is `snake(RPC)` (the generated `Stub`
  function name), the arity is uniform `/2` (client + typed request).
- **INV-3 — money is `{units, nano}` integers, never float (exercised this slice, D-4/G2).** `Quotation` and
  `MoneyValue` decode to `{units, nano}` integer pairs through `Investex.Money`; no float appears in any decoded money
  value, request, or response shape the codec exposes. This slice **exercises** the existing codec against the field
  shapes the read responses carry (`LastPrice.price` / `Order.price` / `PortfolioPosition.quantity` / `expected_yield`
  = `Quotation`; `PortfolioResponse.total_amount_*` = `MoneyValue`) — pure (a property over generated field shapes)
  and live (real venue data). The Go `ToFloat` / `FloatToQuotation` bridge stays **not** ported; `Investex.Money` gains
  **no new public function** (D-4).
- **INV-5 — the client owns the channel (reaffirmed, UNCHANGED).** The supervised `Investex.Client` owns the
  `GRPC.Channel` and the resolved `Investex.Config`; the per-service modules — including the 3 new ones — are stateless
  given a client handle. investex stays **lib-only** — no `mod:`, nothing booted at app start. This slice **reuses**
  the transport, it does not edit it.
- **INV-6 — pure retry decision (reaffirmed, UNCHANGED).** `Investex.Retry.decide/3` is unchanged; the read functions
  inherit retry transparently through the shared `Investex.Caller` seam. This slice adds no retry surface and edits
  none.
- **INV-8 — two test tiers, and the live tier proves its own liveness.** A pure default suite (`mix test` + the
  `--no-start` rung gate): the grown parity scaffold, the Money round-trip property, the pass-through-fidelity check —
  no network, deterministic. An opt-in sandbox suite (`@tag :sandbox`, **excluded by default**). Once the caller opts
  in with `--include sandbox` it is a TRUE hard gate responsible for its OWN liveness: (a) with `INVEST_TOKEN` present
  the live representative subset MUST actually dial — it asserts a positive dialed-proof (a non-empty Instruments read
  result AND a successful `Investex.Money` decode of a real money-dense field), so a no-op self-skip cannot satisfy the
  gate's letter; (b) with the token **absent under `--include sandbox`**, the suite **FAILS loudly** (the `setup`
  `flunk`s). A read the sandbox genuinely does not serve is a **named, loud SKIP** with the reason (never a silent
  pass); if the venue is unreachable, or **neither** money-dense read is served (so Money is never exercised live),
  9.2 **BLOCKS** (Apollo escalates via `AskUserQuestion`). A test in this tier (or any tier) must never decide its own
  runnability by reading process-global state a concurrent test can mutate (the L-9 class, removed by the
  default-exclude + the keyless-`flunk`).
- **INV-9 — secret hygiene (hard).** `INVEST_TOKEN` is read from the environment only (`System.get_env` /
  `System.fetch_env!`) — never hardcoded, committed, logged, or written into a transcript, fixture, gate `.out`, or
  any doc. `.env.test` stays in `github.local` (gitignored) and is read at test time, never copied into the repo. The
  token **value** appears in nothing this rung writes; sandbox account ids and instrument ids are not dumped raw into
  the ledger or a gate `.out`.

**Deferred to later rungs (named so their absence is a decision, not an omission):** INV-4 (the branded `ORD` seam) →
9.3; INV-7 (streams resubscribe on reconnect) → 9.5. This slice holds INV-1/2/3/8/9 fully and reaffirms INV-5/6 (the
reused transport).

## The as-built surfaces this rung consumes (pinned, not rebuilt)

### The transport spine — reused UNCHANGED (TRD.9.1, shipped)

```elixir
# echo/apps/investex/lib/investex/ — the 9.1 transport, the FIXED substrate 9.2 reads through.
Investex.Caller.unary(client, stub_fun, request)  # caller.ex:28-34 — the ONE unary-call seam; the
                                                   # read functions delegate here exactly as Users does.
                                                   # Captures stub_fun as /3, calls
                                                   # stub_fun.(channel, request, metadata: metadata).
Investex.Client.channel(client)                    # client.ex — the resolved GRPC.Channel (read by Caller)
Investex.Client.request_metadata(client)           # client.ex — the frozen Bearer + x-app-name map (read by Caller)
Investex.Client.t()                                # client.ex:35 — GenServer.server() (the @spec arg type)
Investex.Money.from_quotation(%Proto.Quotation{})  # money.ex:35 — {units, nano}; EXERCISED, not changed
Investex.Money.to_quotation({units, nano})         # money.ex:49
Investex.Money.from_money_value(%Proto.MoneyValue{}) # money.ex:62 — {{units, nano}, currency}
Investex.Error.t()                                 # error.ex — the typed {:error, _} value the reads return
```

### The pass-through house style — `Investex.Users` (the exact shape to mirror)

```elixir
# echo/apps/investex/lib/investex/users.ex:1-55 — the template for all 41 read functions.
defmodule Investex.Users do
  @moduledoc "... cites the spec + the proto ..."
  alias Investex.Caller
  alias Tinkoff.Public.Invest.Api.Contract.V1, as: Proto
  alias Tinkoff.Public.Invest.Api.Contract.V1.UsersService.Stub

  @doc "GetAccounts — ... (users.proto:19; empty request)."
  @spec get_accounts(Investex.Client.t()) ::
          {:ok, Proto.GetAccountsResponse.t()} | {:error, Investex.Error.t()}
  def get_accounts(client) do
    Caller.unary(client, &Stub.get_accounts/3, %Proto.GetAccountsRequest{})
  end
  # ... one @doc + @spec + def per RPC ...
end
```

Each read module mirrors this exactly: `alias …V1, as: Proto`; `alias ….<Service>.Stub`; one `@doc` (citing the proto
RPC line) + `@spec` + `def` per RPC; `Caller.unary(client, &Stub.<fun>/3, request)`. The 9.2 reads take the **typed
request as an argument** (RQ-1/D-1), not an `account_id`: the caller pre-builds `%Proto.<Request>{}` and the function
forwards it.

### The generated Service / Stub modules — the contract of names (committed, confirmed this rung)

```text
# echo/apps/investex/lib/investex/proto/tinkoff/public/invest/api/contract/v1/
#   instruments.pb.ex:1870  InstrumentsService.Service — 27 unary `rpc :Name, Req, Resp`
#   instruments.pb.ex:1986  InstrumentsService.Stub     — `use GRPC.Stub` ⇒ one snake-case /3 fun per RPC
#   marketdata.pb.ex:901    MarketDataService.Service  — 7 unary RPCs
#   marketdata.pb.ex:937    MarketDataService.Stub
#   marketdata.pb.ex:943    MarketDataStreamService.Service — the 2 STREAM RPCs (9.5, NOT here)
#   operations.pb.ex:1040   OperationsService.Service  — 7 unary RPCs
#   operations.pb.ex:1076   OperationsService.Stub
#   operations.pb.ex:1082   OperationsStreamService.Service — the 2 STREAM RPCs (9.5, NOT here)
#
# GRPC.Stub generates the function name as snake(RPC): deps/grpc/lib/grpc/stub.ex:69
#   `func_name = name |> to_string |> Macro.underscore()`; the unary form is /3
#   `def <fun>(%GRPC.Channel{} = channel, request, opts \\ [])` (stub.ex:93).
#   ⇒ :Shares → shares, :GetLastPrices → get_last_prices, :GetBrandBy → get_brand_by, :OptionsBy → options_by.
#   This symmetry (snake(RPC) == manifest fun name == Stub fun name) is what makes G-FID exact.
```

### The money-dense response structs — the decode paths (committed, confirmed)

```text
# marketdata.pb.ex
#   GetLastPricesResponse.last_prices : repeated LastPrice (:683)
#   LastPrice.price                   : Quotation (:697, field 2)        → from_quotation/1
#   GetOrderBookResponse + Order.price: Quotation (field 1)             → from_quotation/1 (a 2nd Quotation path)
# operations.pb.ex
#   PortfolioResponse.total_amount_shares : MoneyValue (:220, field 1)  → from_money_value/1
#   PortfolioResponse.expected_yield      : Quotation (field 6)         → from_quotation/1
#   PortfolioPosition (:335).quantity     : Quotation                   → from_quotation/1
# The hard floor (≥1 Money decode from a real money-dense response) is satisfiable from either the
# get_last_prices Quotation OR the get_portfolio MoneyValue — both paths exist on the generated structs.
```

### The parity scaffold + the live tier — the files this rung grows

```text
# echo/apps/investex/test/parity_test.exs — @services (the 10 Service modules), @implemented (the 7 rows
#   today), all_rpcs/0 via service.__rpc_calls__() ⇒ 72; the count + pending + touched-services tests. GROW it.
# echo/apps/investex/test/sandbox_live_test.exs — @moduletag :sandbox, async: false, the keyless `flunk` setup,
#   the dialed-proof assertions (the liveness contract the read subset EXTENDS).
# echo/apps/investex/test/test_helper.exs — ExUnit.start(exclude: [:sandbox]); the GRPC.Client.Supervisor start (L-6).
# echo/rungs/exchange/trd_9_1_check.{exs,out} — the rung-gate precedent (compiled-umbrella `mix run --no-start`,
#   one printed line per gate, nonzero exit, committed `.out`, network-free) — 9.2's gate copies and re-points it.
```

### The secret (read, never copied)

```text
# github.local/invest-api-go-sdk/.env.test holds INVEST_TOKEN= (key name only; value never read).
# github.local is git-ignored. Read the token from the env at test time; never copy .env.test into the repo.
```

## The realization decisions (RQ-1/RQ-2/RQ-3/RQ-4 — settled; each a locked D-n, the alternative a V-n)

The chapter quad fixed F-1..F-11; 9.1 fixed the transport realizations R-1/R-2/R-3 (the `Proto` alias, Money-at-9.1,
the growing scaffold). 9.2 inherits all of them and re-opens none. These are the 9.2-specific realization questions.

**RQ-1 — the pass-through pattern (D-1; alternative V-1).** Each read function takes a **pre-built typed
`%Proto.<Request>{}`** as its single argument (after the client) and forwards it — **NO request-builder / constructor
layer this rung** (the proto struct IS the typed request). Exactly mirrors `Investex.Users`. **Locked: pass-through,
arity uniform `/2`** (client + request) for all 41. The alternative — typed request builders per function — is rejected
as scope-widening gold-plating (V-1): it multiplies the surface by an unbounded set of convenience arities, each a new
contract and a new drift surface, and investex's established 9.1 contract is that the caller pre-builds the typed struct
and investex forwards it raw. Defer any ergonomics to a consumer rung. The uniform `/2` is also what makes G-FID a
clean structural check. Grounding: `users.ex:27-54` (the as-built pass-through); `Caller.unary/3` (`caller.ex:28-34`,
the 3-arity seam); `trd.9.specs.md` §"the per-argument shape is the build rung's to realize".

**RQ-2 — the scaffold transition (D-2).** Grow `@implemented` by the 41 read RPC rows (each `{Proto.<Service>.Service,
:<RPC>} => {Investex.<Mod>, :<snake(RPC)>, 2}`), update the pending assertion **65 → 24**, the implemented count
**7 → 48**, retain the `pending + implemented == 72` partition invariant, and generalize the "touched services" test to
assert exactly `{Users, Sandbox, Instruments, MarketData, Operations}` (sorted). **Locked.** The "count prints 72
implemented" full assertion stays **9.5** (24 pending: Orders 5 + OrdersStream 1 + StopOrders 3 + MarketDataStream 2 +
OperationsStream 2 + the 11 remaining Sandbox = 24). Grounding: `test/parity_test.exs` (the as-built `@implemented` /
`all_rpcs` / pending / touched-services tests); the manifest below.

**RQ-3 — the live gate posture (D-3; Operator-settled 2026-06-14, NOT re-opened).** **Live, HARD, representative
subset.** The chain `open → Instruments read → Money-decode(last-prices) → Money-decode(portfolio) → close`; the hard
floor = **≥1 Instruments read dialed and returned data AND ≥1 Money decode from a real money-dense response**;
sandbox-unserved reads are named loud SKIPs; venue-unreachable or no live Money exercise → **BLOCK** (Apollo escalates
via `AskUserQuestion`). The pure Tier-1 `.out` remains the committed deterministic rung gate in every case. The gate's
own liveness: the live test asserts a non-empty Instruments result AND a successful `Investex.Money` decode of a real
field — a no-op cannot satisfy either. Grounding: the Operator ruling (`trd.9.2.prompt.md` §"The Operator decision");
`trd.9.1.specs.md` INV-8 (the liveness contract `sandbox_live_test.exs` realizes). **Locked — do not re-open.**

**RQ-4 — the Money exercise shape (D-4; alternative V-2).** `Investex.Money` is **exercised, not extended** — **no new
public function**. The pure G2 property is extended to cover the field shapes the read responses carry (a `Quotation`
with negative `nano`, zero, large `units`; a `MoneyValue` with its currency), and the live subset decodes real
`LastPrice.price` (`from_quotation/1`) and/or a real `MoneyValue` total (`from_money_value/1`). **Locked.** The
alternative — a money-mapping helper over a whole response — is rejected (V-2): investex returns the raw
`%Proto.<Response>{}` (the established 9.1 contract; the caller decodes the fields it needs), and a whole-response
mapper would bake a view the consumer should own AND be a new public function. Grounding: `money.ex` (the as-built
codec, unchanged); the money-dense structs cited above; `trd.9.specs.md` INV-3.

> Venus may refine shape, not re-open the spine; a genuine re-opening escalates to the Director.

## The 41-function surface (pinned — Mars cites the proto RPC + the generated `Stub.<fun>` per call)

Every function below is a 1:1 pass-through: `def <fun>(client, %Proto.<Request>{} = request), do: Caller.unary(client,
&Stub.<fun>/3, request)`, returning `{:ok, %Proto.<Response>{}} | {:error, Investex.Error.t()}`, arity **`/2`**. The
`<fun>` is `snake(RPC)` (the generated `Stub` function name); the `Stub` is the per-service one (`InstrumentsService.Stub`
/ `MarketDataService.Stub` / `OperationsService.Stub`). Mars cites the proto message, never invents a field.

### `Investex.Instruments` — 27 (instruments.pb.ex:1870-1985 — `InstrumentsService.Service` / `.Stub` :1986)

| RPC (proto) | request → response | Investex function | `&Stub.<fun>/3` |
|---|---|---|---|
| `TradingSchedules` | `%Proto.TradingSchedulesRequest{}` → `Proto.TradingSchedulesResponse` | `Investex.Instruments.trading_schedules/2` | `&Stub.trading_schedules/3` |
| `BondBy` | `%Proto.InstrumentRequest{}` → `Proto.BondResponse` | `Investex.Instruments.bond_by/2` | `&Stub.bond_by/3` |
| `Bonds` | `%Proto.InstrumentsRequest{}` → `Proto.BondsResponse` | `Investex.Instruments.bonds/2` | `&Stub.bonds/3` |
| `GetBondCoupons` | `%Proto.GetBondCouponsRequest{}` → `Proto.GetBondCouponsResponse` | `Investex.Instruments.get_bond_coupons/2` | `&Stub.get_bond_coupons/3` |
| `CurrencyBy` | `%Proto.InstrumentRequest{}` → `Proto.CurrencyResponse` | `Investex.Instruments.currency_by/2` | `&Stub.currency_by/3` |
| `Currencies` | `%Proto.InstrumentsRequest{}` → `Proto.CurrenciesResponse` | `Investex.Instruments.currencies/2` | `&Stub.currencies/3` |
| `EtfBy` | `%Proto.InstrumentRequest{}` → `Proto.EtfResponse` | `Investex.Instruments.etf_by/2` | `&Stub.etf_by/3` |
| `Etfs` | `%Proto.InstrumentsRequest{}` → `Proto.EtfsResponse` | `Investex.Instruments.etfs/2` | `&Stub.etfs/3` |
| `FutureBy` | `%Proto.InstrumentRequest{}` → `Proto.FutureResponse` | `Investex.Instruments.future_by/2` | `&Stub.future_by/3` |
| `Futures` | `%Proto.InstrumentsRequest{}` → `Proto.FuturesResponse` | `Investex.Instruments.futures/2` | `&Stub.futures/3` |
| `OptionBy` | `%Proto.InstrumentRequest{}` → `Proto.OptionResponse` | `Investex.Instruments.option_by/2` | `&Stub.option_by/3` |
| `Options` | `%Proto.InstrumentsRequest{}` → `Proto.OptionsResponse` | `Investex.Instruments.options/2` | `&Stub.options/3` |
| `OptionsBy` | `%Proto.FilterOptionsRequest{}` → `Proto.OptionsResponse` | `Investex.Instruments.options_by/2` | `&Stub.options_by/3` |
| `ShareBy` | `%Proto.InstrumentRequest{}` → `Proto.ShareResponse` | `Investex.Instruments.share_by/2` | `&Stub.share_by/3` |
| `Shares` | `%Proto.InstrumentsRequest{}` → `Proto.SharesResponse` | `Investex.Instruments.shares/2` | `&Stub.shares/3` |
| `GetAccruedInterests` | `%Proto.GetAccruedInterestsRequest{}` → `Proto.GetAccruedInterestsResponse` | `Investex.Instruments.get_accrued_interests/2` | `&Stub.get_accrued_interests/3` |
| `GetFuturesMargin` | `%Proto.GetFuturesMarginRequest{}` → `Proto.GetFuturesMarginResponse` | `Investex.Instruments.get_futures_margin/2` | `&Stub.get_futures_margin/3` |
| `GetInstrumentBy` | `%Proto.InstrumentRequest{}` → `Proto.InstrumentResponse` | `Investex.Instruments.get_instrument_by/2` | `&Stub.get_instrument_by/3` |
| `GetDividends` | `%Proto.GetDividendsRequest{}` → `Proto.GetDividendsResponse` | `Investex.Instruments.get_dividends/2` | `&Stub.get_dividends/3` |
| `GetAssetBy` | `%Proto.AssetRequest{}` → `Proto.AssetResponse` | `Investex.Instruments.get_asset_by/2` | `&Stub.get_asset_by/3` |
| `GetAssets` | `%Proto.AssetsRequest{}` → `Proto.AssetsResponse` | `Investex.Instruments.get_assets/2` | `&Stub.get_assets/3` |
| `GetFavorites` | `%Proto.GetFavoritesRequest{}` → `Proto.GetFavoritesResponse` | `Investex.Instruments.get_favorites/2` | `&Stub.get_favorites/3` |
| `EditFavorites` | `%Proto.EditFavoritesRequest{}` → `Proto.EditFavoritesResponse` | `Investex.Instruments.edit_favorites/2` | `&Stub.edit_favorites/3` |
| `GetCountries` | `%Proto.GetCountriesRequest{}` → `Proto.GetCountriesResponse` | `Investex.Instruments.get_countries/2` | `&Stub.get_countries/3` |
| `FindInstrument` | `%Proto.FindInstrumentRequest{}` → `Proto.FindInstrumentResponse` | `Investex.Instruments.find_instrument/2` | `&Stub.find_instrument/3` |
| `GetBrands` | `%Proto.GetBrandsRequest{}` → `Proto.GetBrandsResponse` | `Investex.Instruments.get_brands/2` | `&Stub.get_brands/3` |
| `GetBrandBy` | `%Proto.GetBrandRequest{}` → `Proto.Brand` *(bare `Brand` message, NOT `BrandResponse` — instruments.pb.ex:1980-1983)* | `Investex.Instruments.get_brand_by/2` | `&Stub.get_brand_by/3` |

### `Investex.MarketData` — 7 (marketdata.pb.ex:901-935 — `MarketDataService.Service` / `.Stub` :937)

| RPC (proto) | request → response | Investex function | `&Stub.<fun>/3` |
|---|---|---|---|
| `GetCandles` | `%Proto.GetCandlesRequest{}` → `Proto.GetCandlesResponse` | `Investex.MarketData.get_candles/2` | `&Stub.get_candles/3` |
| `GetLastPrices` | `%Proto.GetLastPricesRequest{}` → `Proto.GetLastPricesResponse` *(money-dense: `last_prices` repeated `LastPrice`, `LastPrice.price` = `Quotation`)* | `Investex.MarketData.get_last_prices/2` | `&Stub.get_last_prices/3` |
| `GetOrderBook` | `%Proto.GetOrderBookRequest{}` → `Proto.GetOrderBookResponse` *(money-dense: `Order.price` = `Quotation`)* | `Investex.MarketData.get_order_book/2` | `&Stub.get_order_book/3` |
| `GetTradingStatus` | `%Proto.GetTradingStatusRequest{}` → `Proto.GetTradingStatusResponse` | `Investex.MarketData.get_trading_status/2` | `&Stub.get_trading_status/3` |
| `GetTradingStatuses` | `%Proto.GetTradingStatusesRequest{}` → `Proto.GetTradingStatusesResponse` | `Investex.MarketData.get_trading_statuses/2` | `&Stub.get_trading_statuses/3` |
| `GetLastTrades` | `%Proto.GetLastTradesRequest{}` → `Proto.GetLastTradesResponse` | `Investex.MarketData.get_last_trades/2` | `&Stub.get_last_trades/3` |
| `GetClosePrices` | `%Proto.GetClosePricesRequest{}` → `Proto.GetClosePricesResponse` | `Investex.MarketData.get_close_prices/2` | `&Stub.get_close_prices/3` |

### `Investex.Operations` — 7 (operations.pb.ex:1040-1075 — `OperationsService.Service` / `.Stub` :1076)

| RPC (proto) | request → response | Investex function | `&Stub.<fun>/3` |
|---|---|---|---|
| `GetOperations` | `%Proto.OperationsRequest{}` → `Proto.OperationsResponse` | `Investex.Operations.get_operations/2` | `&Stub.get_operations/3` |
| `GetPortfolio` | `%Proto.PortfolioRequest{}` → `Proto.PortfolioResponse` *(money-dense: `total_amount_*` = `MoneyValue`, `expected_yield` = `Quotation`, `PortfolioPosition.quantity` = `Quotation`)* | `Investex.Operations.get_portfolio/2` | `&Stub.get_portfolio/3` |
| `GetPositions` | `%Proto.PositionsRequest{}` → `Proto.PositionsResponse` | `Investex.Operations.get_positions/2` | `&Stub.get_positions/3` |
| `GetWithdrawLimits` | `%Proto.WithdrawLimitsRequest{}` → `Proto.WithdrawLimitsResponse` | `Investex.Operations.get_withdraw_limits/2` | `&Stub.get_withdraw_limits/3` |
| `GetBrokerReport` | `%Proto.BrokerReportRequest{}` → `Proto.BrokerReportResponse` | `Investex.Operations.get_broker_report/2` | `&Stub.get_broker_report/3` |
| `GetDividendsForeignIssuer` | `%Proto.GetDividendsForeignIssuerRequest{}` → `Proto.GetDividendsForeignIssuerResponse` | `Investex.Operations.get_dividends_foreign_issuer/2` | `&Stub.get_dividends_foreign_issuer/3` |
| `GetOperationsByCursor` | `%Proto.GetOperationsByCursorRequest{}` → `Proto.GetOperationsByCursorResponse` | `Investex.Operations.get_operations_by_cursor/2` | `&Stub.get_operations_by_cursor/3` |

**Surface total: 27 + 7 + 7 = 41 read-only unary functions, each arity `/2`.** Every RPC name above is quoted from the
generated `…Service.Service` module (the `rpc :Name, Req, Resp` declarations confirmed this rung); every response struct
named is the proto's `…Response` (or the bare `Brand` for `GetBrandBy`); every `Stub` function is the snake-case the
`use GRPC.Stub` macro generates (`stub.ex:69`).

## The Money exercise (pure — the read responses' field shapes)

The existing `Investex.Money` codec is exercised, not extended (RQ-4/D-4). A property over generated field shapes:

```elixir
# Tier 1, pure (G2). No new Money function — the read responses carry the same Quotation/MoneyValue
# the codec already decodes. Cover the field shapes a real read response carries:
#   from_quotation(%Proto.Quotation{units, nano}) round-trips to_quotation/1 with no float, for
#     units ∈ {0, large +/-}, nano ∈ {0, negative, +/-} — the LastPrice.price / Order.price /
#     PortfolioPosition.quantity / expected_yield shape.
#   from_money_value(%Proto.MoneyValue{units, nano, currency}) yields {{units, nano}, currency}, the
#     PortfolioResponse.total_amount_* shape, currency a non-empty ISO string.
# A generator asserts no float appears in any decoded value (INV-3).
```

The live subset (below) decodes a **real** `LastPrice.price` and/or a **real** `MoneyValue` total — the hard floor's
money half.

## The pass-through-fidelity gate (G-FID — NEW, 9.2; network-free)

```elixir
# Tier 1, pure. For each of {Investex.Instruments, Investex.MarketData, Investex.Operations}:
#   read each public `def <name>(client, %Proto.<Request>{} ...)`; assert the function body captures
#   `&<Service>.Stub.<name>/3` with the SAME <name> (snake(RPC) == def-name == stub-fun-name).
# Closes the gap the parity scaffold leaves open: the scaffold proves existence + arity + RPC-membership,
# but `def shares, do: Caller.unary(client, &Stub.bonds/3, request)` COMPILES (bonds is a real Stub fun)
# and PASSES the scaffold — the copy-paste wrong-stub class. The fidelity check reads the body and pairs
# each def-name to its captured stub-fun-name.
# LIVENESS (the gate's teeth): a mutated pairing in any of the 41 functions MUST turn the gate red
#   (the Stage-3 mutation spot-check: Edit `shares` → `&Stub.bonds/3`, confirm red, revert net-zero;
#   Apollo re-runs it independently).
```

The realization (read the AST, or the source, or a `@stub_fun` registry per module) is Mars's; the spec pins the
**contract** (per-function name-match across all 41, network-free, mutated-pairing → red) and its liveness.

## Acceptance gates (scoped to 9.2 — Tier 1 one printed line each; G6 is the live hard gate)

- **G1-scaffold (at 48) — parity is measured and growing.** The parity-check test enumerates the proto service
  definitions and asserts each of the **48 implemented** RPCs (Users 4 + the sandbox trio 3 + Instruments 27 +
  MarketData 7 + Operations 7) maps to its named `Investex.<Service>.<fun>/n`, carrying the **24 unimplemented** as an
  explicit pending list; the touched-services test asserts exactly `{Users, Sandbox, Instruments, MarketData,
  Operations}`; a later un-mapped (or a renamed 9.2) function fails it; exit zero. *(INV-1/2; the "count prints 72"
  full assertion is 9.5.)*
- **G2 — money round-trips as integers (exercised over the read shapes).** `from_quotation` / `to_quotation` /
  `from_money_value` round-trip `{units, nano}` integer pairs (plus the ISO currency for `MoneyValue`) over the field
  shapes the read responses carry, with no float in any value; a property holds over generated money; no new
  `Investex.Money` function; exit zero. *(INV-3, D-4.)*
- **G-FID — the pass-through-fidelity check passes.** Every read function delegates to its identically-named `Stub`
  function (`snake(RPC) == def-name == stub-fun-name`) across all 41; network-free; a mutated pairing fails it; exit
  zero. *(NEW, 9.2.)*
- **G5 — the pure suite is network-free and the sandbox tier is excluded by default.** The default `mix test` (and the
  `--no-start` rung gate) touches no network and is deterministic; the `@tag :sandbox` suite is **excluded by default**
  (a bare `mix test` never dials); the rung gate `trd_9_2_check.{exs,out}` is committed and reproducible (run twice,
  identical); exit zero. *(INV-8.)*
- **G6 (9.2 scope) — the live representative subset works (key present).** With `INVEST_TOKEN` set, the live read
  subset opens a sandbox account, calls ≥1 `Investex.Instruments` read that returns data, `get_last_prices/2` for an
  instrument id from that read and decodes `LastPrice.price` through `Investex.Money.from_quotation/1`,
  `get_portfolio/2` for the account and decodes a `MoneyValue` through `from_money_value/1`, and closes the account —
  a real round trip against the real sandbox endpoint; exit zero. **This is the Operator's hard ship gate: it MUST
  PASS to ship 9.2.** The hard floor: **≥1 Instruments read dialed AND ≥1 Money decode from a real money-dense
  response**. A read the sandbox does not serve is a **named loud SKIP**; if the venue is unreachable or neither
  money-dense read is served (Money never exercised live), **9.2 BLOCKS** (Apollo escalates via `AskUserQuestion`).
  *(INV-8, the sandbox tier; D-3.)*
- **G7 — no token value anywhere.** A grep of the 3 modules, the tests, the generated modules, the gate `.out`, and
  the ledger for a token-shaped string finds none; the token is read from the environment only; sandbox account /
  instrument ids are not dumped raw. *(INV-9.)*

**Deferred (named — they need a later rung):** **G3 — the branded `ORD` id is validated at the edge** (INV-4) → 9.3;
**G1 complete — the count prints 72 implemented** → 9.5.

### Each gate as a Given/When/Then (the acceptance contract — a no-op must not satisfy its letter)

- **G1-scaffold@48.** *Given* the 3 read modules and the grown `@implemented` (48 rows). *When* `mix test` runs the
  parity scaffold. *Then* it asserts `map_size(@implemented) == 48`, `length(pending) == 24`,
  `length(pending) + map_size(@implemented) == 72`, each implemented RPC is a real proto RPC AND its named function is
  exported at the named arity, and the touched-services set is exactly the sorted 5. **Liveness:** mutate/drop one
  `@implemented` row (or rename one read function) → the gate fails (the Director's Stage-3 mutation spot-check
  exercises this).
- **G2.** *Given* the unchanged `Investex.Money` codec. *When* the property generates `Quotation`/`MoneyValue` field
  shapes the read responses carry (negative/zero/large `nano`/`units`; a currency string). *Then* `from_*`/`to_*`
  round-trip the integer pair (+ currency) with no float in any value, and `Investex.Money` exports no function it did
  not export at 9.1. **Liveness:** a float introduced into any round-tripped value fails the property; a new public
  `Investex.Money/_` function fails the "exercised, not extended" check.
- **G-FID.** *Given* the 3 read modules. *When* the fidelity check pairs each `def <name>` to its captured
  `&Stub.<fun>/3`. *Then* every pair has `name == fun` (both `snake(RPC)`), across all 41. **Liveness:** Edit one
  function's capture to a different valid stub fun (`shares` → `&Stub.bonds/3`) → the gate turns red (revert
  net-zero); the parity scaffold alone does NOT (proving the gate adds real coverage).
- **G5.** *Given* the committed `trd_9_2_check.exs`. *When* it runs twice via `mix run --no-start`. *Then* both runs
  print byte-identical `.out`, touch no network, exit zero; and a bare `mix test` excludes `:sandbox` (0 sandbox tests
  run). **Liveness:** a network call in any Tier-1 path, or a non-reproducible line, fails the gate.
- **G6 (9.2).** *Given* `INVEST_TOKEN` in the env under `--include sandbox`. *When* the live read subset runs. *Then*
  it opens an account, an Instruments read returns non-empty data (dialed-proof), `Investex.Money` decodes a real
  `LastPrice.price` and/or a real portfolio `MoneyValue` (the money half of the hard floor), and it closes the
  account — exit zero. **Liveness (own-liveness, INV-8):** with the token **absent** under `--include sandbox` the
  `setup` `flunk`s loudly (never a silent skip); a money-dense read the sandbox does not serve is a NAMED loud SKIP;
  if **neither** money-dense read is served (Money never decoded live) the subset reports BLOCK, not green.
- **G7.** *Given* the full 9.2 diff (3 modules, tests, gate `.out`) and the ledger. *When* grepped for a token-shaped
  string and for a raw account/instrument id dump. *Then* none is found; the token is read from the env only.
  **Liveness:** a literal token, or a `.env.test` copied into the repo, or a raw id in the `.out`/ledger, fails the
  grep.

## Coverage — every Deliverable → its gate (completion provable from the text)

| Deliverable | Story (in [`trd.9.2.md`](trd.9.2.md) / the trd.9 stories) | Invariant(s) | Gate |
|---|---|---|---|
| `Investex.Instruments` (27) | the read-services story | INV-2, INV-5 | G1-scaffold@48, G-FID |
| `Investex.MarketData` (7) | the read-services story | INV-2, INV-5 | G1-scaffold@48, G-FID |
| `Investex.Operations` (7) | the read-services story | INV-2, INV-5 | G1-scaffold@48, G-FID |
| The grown parity scaffold (7 → 48 / 65 → 24 / 5 services) | the measured-parity story | INV-1 | G1-scaffold@48 |
| The Money exercise (pure property over the read shapes) | the integer-money story | INV-3 | G2 |
| The pass-through-fidelity check (all 41) | the correct-delegation story | INV-2 | G-FID |
| The rung gate `trd_9_2_check.{exs,out}` (network-free, reproducible) | the deterministic-gate story | INV-8 | G5 |
| The live read tier (the representative subset) | the live-verification story | INV-8 | G6 (9.2) |
| Secret hygiene (env-only, no raw ids) | the secret-hygiene story | INV-9 | G7 |

## Definition of done

`echo/apps/investex` gains its read services: `Investex.Instruments` (27) + `Investex.MarketData` (7) +
`Investex.Operations` (7) = 41 read-only unary functions, each a 1:1 pass-through over the fixed 9.1 transport, named
**exactly** per the parity manifest (`snake(RPC)`), arity `/2`, delegating to its identically-named `&Stub.<fun>/3`;
compiles `--warnings-as-errors` clean; the diff touches no transport module's public surface, no order method, no
stream. The parity scaffold asserts **48 implemented / 24 pending / 72 enumerated**; the touched-services test is
exactly `{Users, Sandbox, Instruments, MarketData, Operations}`; a mutated/dropped row fails it (INV-1/2; "count prints
72" is still 9.5). The pass-through-fidelity check passes across all 41 (G-FID). `Investex.Money` round-trips integer
`{units, nano}` over the read responses' `Quotation`/`MoneyValue` field shapes with no float and **no new function**
(G2). Tier 1 is network-free and green; `echo/rungs/exchange/trd_9_2_check.{exs,out}` committed, reproducible (run
twice, identical), exit zero (G5). **The live representative subset PASSED** against the real sandbox endpoint — the
hard floor (≥1 Instruments read dialed AND ≥1 Money decode from real money-dense data); unserved reads are named loud
SKIPs (G6, 9.2 scope; INV-8). No token-shaped string anywhere in the 3 modules, tests, generated modules, gate `.out`,
or ledger; the token is env-only; no raw account/instrument id dumped (G7). The slice boundary held (no order method,
no `EchoData` ORD validation, no stream, no transport-surface edit this rung). The deferred set is named (INV-4/G3 →
9.3; INV-7 → 9.5; the 9.3/9.4/9.5 surfaces; full G1 → 9.5).

## Map

Chapter: [`trd.9.2.md`](trd.9.2.md). The full rung: [`trd.9.specs.md`](trd.9.specs.md) ·
[`trd.9.stories.md`](trd.9.stories.md) · [`trd.9.llms.md`](trd.9.llms.md). The transport spine it builds on:
[`trd.9.1.specs.md`](trd.9.1.specs.md). The runbook: [`trd.9.2.prompt.md`](trd.9.2.prompt.md). System:
[`exchange.specs.md`](exchange.specs.md). The parity source: the committed generated modules
(`echo/apps/investex/lib/investex/proto/.../v1/{instruments,marketdata,operations}.pb.ex`) and the Tinkoff Invest
contracts (`github.local/invest-api-go-sdk/proto/{instruments,marketdata,operations}.proto`); the Go SDK
(`investgo/{instruments,marketdata,operations}.go`); transport (`github.local/investAPI/src/docs/grpc.md`). The
pass-through template: `echo/apps/investex/lib/investex/users.ex` (+ `caller.ex`, `money.ex`). The grown files:
`echo/apps/investex/test/{parity_test.exs,sandbox_live_test.exs}`. The rung-gate precedent:
`echo/rungs/exchange/trd_9_1_check.exs`. The canon (the declared, unexercised dep):
`echo/apps/echo_data/lib/echo_data/{snowflake,branded_id}.ex`.
