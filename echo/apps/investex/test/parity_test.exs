defmodule Investex.ParityTest do
  @moduledoc """
  Tier 1 (pure): the parity scaffold — the growing gate (trd.9.1.specs.md
  G1-scaffold; trd.9.2.specs.md INV-1, RQ-2/D-2).

  This test enumerates the proto service definitions (the 10 generated
  `…Service.Service` modules, 72 RPCs in all) at runtime via `__rpc_calls__/0`,
  and asserts that each of the **48 implemented** RPCs (UsersService 4 + the
  sandbox bootstrap trio 3 + InstrumentsService 27 + MarketDataService 7 +
  OperationsService 7) maps to its named, exported `Investex.<Service>.<fun>/n`.
  The **24 unimplemented** RPCs are carried as an explicit pending list. A later
  un-mapped function (a 9.3+ row that lands without its Elixir function) or a
  renamed/dropped function FAILS the growing gate; rows move pending → asserted
  monotonically across 9.1-9.5.

  9.2 grew this scaffold 7 → 48 implemented (the 41 read RPCs, RQ-2/D-2);
  the 24 pending are Orders 5 + OrdersStream 1 + StopOrders 3 + MarketDataStream
  2 + OperationsStream 2 + the 11 remaining Sandbox = 24. The full "count prints
  72 implemented" assertion completes at 9.5 (R-3); this slice asserts 48
  implemented + 24 pending = 72 enumerated.
  """
  use ExUnit.Case, async: true

  alias Tinkoff.Public.Invest.Api.Contract.V1, as: Proto

  # The 10 service definitions across the 8 committed contracts. The full RPC
  # surface enumerated by the gate; the source of the 72 (trd.9.specs.md).
  @services [
    Proto.InstrumentsService.Service,
    Proto.MarketDataService.Service,
    Proto.MarketDataStreamService.Service,
    Proto.OperationsService.Service,
    Proto.OperationsStreamService.Service,
    Proto.OrdersService.Service,
    Proto.OrdersStreamService.Service,
    Proto.SandboxService.Service,
    Proto.StopOrdersService.Service,
    Proto.UsersService.Service
  ]

  # The implemented map: {Service module, proto RPC name} → {Elixir module,
  # function, arity}. The 48 RPCs this slice ships (the 7 transport-bootstrap
  # RPCs from 9.1 + the 41 read RPCs added in 9.2, trd.9.2.specs.md §"The
  # 41-function surface", RQ-2/D-2). For 9.1: a no-field request → /1, an
  # account-id-bearing request → /2. For 9.2: every read function is a 1:1
  # pass-through taking a typed request → uniform /2.
  @implemented %{
    # --- 9.1 — UsersService (4) + the SandboxService bootstrap trio (3) ---
    {Proto.UsersService.Service, :GetAccounts} => {Investex.Users, :get_accounts, 1},
    {Proto.UsersService.Service, :GetMarginAttributes} =>
      {Investex.Users, :get_margin_attributes, 2},
    {Proto.UsersService.Service, :GetUserTariff} => {Investex.Users, :get_user_tariff, 1},
    {Proto.UsersService.Service, :GetInfo} => {Investex.Users, :get_info, 1},
    {Proto.SandboxService.Service, :OpenSandboxAccount} => {Investex.Sandbox, :open_account, 1},
    {Proto.SandboxService.Service, :GetSandboxAccounts} => {Investex.Sandbox, :get_accounts, 1},
    {Proto.SandboxService.Service, :CloseSandboxAccount} => {Investex.Sandbox, :close_account, 2},
    # --- 9.2 — InstrumentsService (27) ---
    {Proto.InstrumentsService.Service, :TradingSchedules} =>
      {Investex.Instruments, :trading_schedules, 2},
    {Proto.InstrumentsService.Service, :BondBy} => {Investex.Instruments, :bond_by, 2},
    {Proto.InstrumentsService.Service, :Bonds} => {Investex.Instruments, :bonds, 2},
    {Proto.InstrumentsService.Service, :GetBondCoupons} =>
      {Investex.Instruments, :get_bond_coupons, 2},
    {Proto.InstrumentsService.Service, :CurrencyBy} => {Investex.Instruments, :currency_by, 2},
    {Proto.InstrumentsService.Service, :Currencies} => {Investex.Instruments, :currencies, 2},
    {Proto.InstrumentsService.Service, :EtfBy} => {Investex.Instruments, :etf_by, 2},
    {Proto.InstrumentsService.Service, :Etfs} => {Investex.Instruments, :etfs, 2},
    {Proto.InstrumentsService.Service, :FutureBy} => {Investex.Instruments, :future_by, 2},
    {Proto.InstrumentsService.Service, :Futures} => {Investex.Instruments, :futures, 2},
    {Proto.InstrumentsService.Service, :OptionBy} => {Investex.Instruments, :option_by, 2},
    {Proto.InstrumentsService.Service, :Options} => {Investex.Instruments, :options, 2},
    {Proto.InstrumentsService.Service, :OptionsBy} => {Investex.Instruments, :options_by, 2},
    {Proto.InstrumentsService.Service, :ShareBy} => {Investex.Instruments, :share_by, 2},
    {Proto.InstrumentsService.Service, :Shares} => {Investex.Instruments, :shares, 2},
    {Proto.InstrumentsService.Service, :GetAccruedInterests} =>
      {Investex.Instruments, :get_accrued_interests, 2},
    {Proto.InstrumentsService.Service, :GetFuturesMargin} =>
      {Investex.Instruments, :get_futures_margin, 2},
    {Proto.InstrumentsService.Service, :GetInstrumentBy} =>
      {Investex.Instruments, :get_instrument_by, 2},
    {Proto.InstrumentsService.Service, :GetDividends} =>
      {Investex.Instruments, :get_dividends, 2},
    {Proto.InstrumentsService.Service, :GetAssetBy} => {Investex.Instruments, :get_asset_by, 2},
    {Proto.InstrumentsService.Service, :GetAssets} => {Investex.Instruments, :get_assets, 2},
    {Proto.InstrumentsService.Service, :GetFavorites} =>
      {Investex.Instruments, :get_favorites, 2},
    {Proto.InstrumentsService.Service, :EditFavorites} =>
      {Investex.Instruments, :edit_favorites, 2},
    {Proto.InstrumentsService.Service, :GetCountries} =>
      {Investex.Instruments, :get_countries, 2},
    {Proto.InstrumentsService.Service, :FindInstrument} =>
      {Investex.Instruments, :find_instrument, 2},
    {Proto.InstrumentsService.Service, :GetBrands} => {Investex.Instruments, :get_brands, 2},
    {Proto.InstrumentsService.Service, :GetBrandBy} => {Investex.Instruments, :get_brand_by, 2},
    # --- 9.2 — MarketDataService (7) ---
    {Proto.MarketDataService.Service, :GetCandles} => {Investex.MarketData, :get_candles, 2},
    {Proto.MarketDataService.Service, :GetLastPrices} =>
      {Investex.MarketData, :get_last_prices, 2},
    {Proto.MarketDataService.Service, :GetOrderBook} => {Investex.MarketData, :get_order_book, 2},
    {Proto.MarketDataService.Service, :GetTradingStatus} =>
      {Investex.MarketData, :get_trading_status, 2},
    {Proto.MarketDataService.Service, :GetTradingStatuses} =>
      {Investex.MarketData, :get_trading_statuses, 2},
    {Proto.MarketDataService.Service, :GetLastTrades} =>
      {Investex.MarketData, :get_last_trades, 2},
    {Proto.MarketDataService.Service, :GetClosePrices} =>
      {Investex.MarketData, :get_close_prices, 2},
    # --- 9.2 — OperationsService (7) ---
    {Proto.OperationsService.Service, :GetOperations} =>
      {Investex.Operations, :get_operations, 2},
    {Proto.OperationsService.Service, :GetPortfolio} => {Investex.Operations, :get_portfolio, 2},
    {Proto.OperationsService.Service, :GetPositions} => {Investex.Operations, :get_positions, 2},
    {Proto.OperationsService.Service, :GetWithdrawLimits} =>
      {Investex.Operations, :get_withdraw_limits, 2},
    {Proto.OperationsService.Service, :GetBrokerReport} =>
      {Investex.Operations, :get_broker_report, 2},
    {Proto.OperationsService.Service, :GetDividendsForeignIssuer} =>
      {Investex.Operations, :get_dividends_foreign_issuer, 2},
    {Proto.OperationsService.Service, :GetOperationsByCursor} =>
      {Investex.Operations, :get_operations_by_cursor, 2}
  }

  # All {service, rpc_name} pairs the proto declares, enumerated from the real
  # service modules — never a hardcoded list.
  defp all_rpcs do
    for service <- @services,
        {name, _req, _resp, _opts} <- service.__rpc_calls__(),
        do: {service, name}
  end

  test "the proto enumerates exactly 72 RPCs across 10 services (the full surface)" do
    assert length(@services) == 10
    assert length(all_rpcs()) == 72
  end

  test "each of the 48 implemented RPCs maps to its named, exported Investex function" do
    declared = MapSet.new(all_rpcs())

    for {{service, rpc_name} = key, {mod, fun, arity}} <- @implemented do
      # The implemented RPC is a REAL proto RPC (catches a typo'd mapping).
      assert MapSet.member?(declared, key),
             "#{inspect(service)} declares no RPC #{rpc_name} — the mapping is stale"

      # The named Elixir function actually exists at the named arity.
      Code.ensure_loaded!(mod)

      assert function_exported?(mod, fun, arity),
             "#{inspect(mod)}.#{fun}/#{arity} is not exported — the surface drifted from the parity map"
    end

    assert map_size(@implemented) == 48
  end

  test "the unimplemented RPCs are carried as an explicit pending list of 24" do
    implemented_keys = @implemented |> Map.keys() |> MapSet.new()
    pending = all_rpcs() |> Enum.reject(&MapSet.member?(implemented_keys, &1))

    # 72 enumerated − 48 implemented = 24 pending (the growing-gate ledger:
    # Orders 5 + OrdersStream 1 + StopOrders 3 + MarketDataStream 2 +
    # OperationsStream 2 + the 11 remaining Sandbox = 24).
    assert length(pending) == 24

    # The pending list is the complement: no implemented RPC hides in it, and
    # together they partition the 72.
    assert length(pending) + map_size(@implemented) == 72
  end

  test "the implemented map names only RPCs on the 5 touched services (Users, Sandbox, Instruments, MarketData, Operations)" do
    services_touched =
      @implemented |> Map.keys() |> Enum.map(fn {service, _name} -> service end) |> Enum.uniq()

    assert Enum.sort(services_touched) ==
             Enum.sort([
               Proto.UsersService.Service,
               Proto.SandboxService.Service,
               Proto.InstrumentsService.Service,
               Proto.MarketDataService.Service,
               Proto.OperationsService.Service
             ])
  end
end
