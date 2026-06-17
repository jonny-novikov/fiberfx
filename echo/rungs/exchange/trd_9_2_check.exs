# trd_9_2_check.exs -- gates G1-scaffold@48, G2, G-FID, G5, G7: the investex read services.
#   cd /Users/jonny/dev/jonnify/echo && mix run --no-start rungs/exchange/trd_9_2_check.exs
#
# A COMPILED-umbrella `mix run --no-start` runner (the trd_9_1_check.exs pattern, D-4) --
# NOT a Code.require_file pure runner, because the parity scaffold + the Money codec +
# the 3 read modules reference the GENERATED :protobuf structs
# (Tinkoff.Public.Invest.Api.Contract.V1.*) + the InstrumentsService/MarketDataService/
# OperationsService Stub modules, which exist only as compiled artifacts. The runner
# aliases the compiled modules directly, dials NOTHING (`:investex` is lib-only -- no
# mod: -- so loading it opens no connection), and stays network-free: it exercises only
# the pure surface (the grown parity scaffold, the Money round-trip over the read-response
# field shapes, the pass-through-fidelity AST check) plus two structural greps (the
# :sandbox exclusion, the no-token scan). One printed line per gate; nonzero exit on any
# failure. The generators are self-contained seeded :rand (no StreamData dep, so
# --no-start-safe and deterministic -- two runs are byte-identical).
# Spec: docs/exchange/trd.9.2.specs.md ("Acceptance gates"); the trd_9_1_check.exs pattern.

alias Investex.Money
alias Tinkoff.Public.Invest.Api.Contract.V1, as: Proto

defmodule G do
  def line(tag, ok, detail) do
    IO.puts("#{tag} #{if ok, do: "ok", else: "FAIL"} -- #{detail}")
    ok
  end

  # The 10 generated service definitions across the 8 committed contracts (the
  # source of the 72 RPCs); the parity scaffold enumerates them via
  # __rpc_calls__/0 -- never a hardcoded list.
  def services do
    [
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
  end

  # The 48 implemented RPCs: {Service, proto RPC name} -> {Elixir module, fun, arity}.
  # The 7 transport-bootstrap RPCs (9.1) + the 41 read RPCs (9.2). Kept in lockstep
  # with test/parity_test.exs @implemented -- both grow pending->asserted across rungs.
  def implemented do
    %{
      # -- 9.1 -- UsersService (4) + the SandboxService bootstrap trio (3) --
      {Proto.UsersService.Service, :GetAccounts} => {Investex.Users, :get_accounts, 1},
      {Proto.UsersService.Service, :GetMarginAttributes} =>
        {Investex.Users, :get_margin_attributes, 2},
      {Proto.UsersService.Service, :GetUserTariff} => {Investex.Users, :get_user_tariff, 1},
      {Proto.UsersService.Service, :GetInfo} => {Investex.Users, :get_info, 1},
      {Proto.SandboxService.Service, :OpenSandboxAccount} => {Investex.Sandbox, :open_account, 1},
      {Proto.SandboxService.Service, :GetSandboxAccounts} => {Investex.Sandbox, :get_accounts, 1},
      {Proto.SandboxService.Service, :CloseSandboxAccount} =>
        {Investex.Sandbox, :close_account, 2},
      # -- 9.2 -- InstrumentsService (27) --
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
      # -- 9.2 -- MarketDataService (7) --
      {Proto.MarketDataService.Service, :GetCandles} => {Investex.MarketData, :get_candles, 2},
      {Proto.MarketDataService.Service, :GetLastPrices} =>
        {Investex.MarketData, :get_last_prices, 2},
      {Proto.MarketDataService.Service, :GetOrderBook} =>
        {Investex.MarketData, :get_order_book, 2},
      {Proto.MarketDataService.Service, :GetTradingStatus} =>
        {Investex.MarketData, :get_trading_status, 2},
      {Proto.MarketDataService.Service, :GetTradingStatuses} =>
        {Investex.MarketData, :get_trading_statuses, 2},
      {Proto.MarketDataService.Service, :GetLastTrades} =>
        {Investex.MarketData, :get_last_trades, 2},
      {Proto.MarketDataService.Service, :GetClosePrices} =>
        {Investex.MarketData, :get_close_prices, 2},
      # -- 9.2 -- OperationsService (7) --
      {Proto.OperationsService.Service, :GetOperations} =>
        {Investex.Operations, :get_operations, 2},
      {Proto.OperationsService.Service, :GetPortfolio} =>
        {Investex.Operations, :get_portfolio, 2},
      {Proto.OperationsService.Service, :GetPositions} =>
        {Investex.Operations, :get_positions, 2},
      {Proto.OperationsService.Service, :GetWithdrawLimits} =>
        {Investex.Operations, :get_withdraw_limits, 2},
      {Proto.OperationsService.Service, :GetBrokerReport} =>
        {Investex.Operations, :get_broker_report, 2},
      {Proto.OperationsService.Service, :GetDividendsForeignIssuer} =>
        {Investex.Operations, :get_dividends_foreign_issuer, 2},
      {Proto.OperationsService.Service, :GetOperationsByCursor} =>
        {Investex.Operations, :get_operations_by_cursor, 2}
    }
  end

  # The 3 read modules and their generating Service (for the G-FID set-equality).
  def read_modules do
    [
      {Investex.Instruments, Proto.InstrumentsService.Service},
      {Investex.MarketData, Proto.MarketDataService.Service},
      {Investex.Operations, Proto.OperationsService.Service}
    ]
  end

  # Every {service, rpc_name} the proto declares, enumerated from the real modules.
  def all_rpcs do
    for service <- services(),
        {name, _req, _resp, _opts} <- service.__rpc_calls__(),
        do: {service, name}
  end

  # snake(RPC) for every RPC a service declares -- the expected public def-name set.
  def expected_fun_names(service) do
    for {rpc_name, _req, _resp, _opts} <- service.__rpc_calls__(),
        into: MapSet.new(),
        do: rpc_name |> to_string() |> Macro.underscore() |> String.to_atom()
  end

  # G-FID, runner edition: parse a read module's SOURCE to AST, pair each public
  # `def <name>` to its `&Stub.<fun>/3` capture (the shape probed in 9.2:
  # {:&, _, [{:/, _, [{{:., _, [{:__aliases__, _, [:Stub]}, fun]}, _, []}, arity]}]}),
  # and return [{def_name, capture}] where capture is {fun, arity} | :no_capture.
  # Mirrors test/fidelity_test.exs (the Tier-1 gate) so the .out records the same check.
  def def_capture_pairs(module) do
    source = module.module_info(:compile)[:source] |> to_string()
    ast = source |> File.read!() |> Code.string_to_quoted!()

    {_ast, defs} =
      Macro.prewalk(ast, [], fn
        {:def, _meta, [head, [do: body]]} = node, acc ->
          {node, [{def_name(head), stub_capture(body)} | acc]}

        node, acc ->
          {node, acc}
      end)

    Enum.reverse(defs)
  end

  defp def_name({:when, _meta, [call, _guard]}), do: def_name(call)
  defp def_name({name, _meta, _args}) when is_atom(name), do: name

  defp stub_capture(body) do
    {_body, found} =
      Macro.prewalk(body, :no_capture, fn
        {:&, _, [{:/, _, [{{:., _, [{:__aliases__, _, [:Stub]}, fun]}, _, []}, arity]}]} = node,
        :no_capture
        when is_atom(fun) and is_integer(arity) ->
          {node, {fun, arity}}

        node, acc ->
          {node, acc}
      end)

    found
  end
end

IO.puts(
  "header: Investex read services (lib-only, no dial) | Elixir #{System.version()} OTP #{:erlang.system_info(:otp_release)} | grpc #{Application.spec(:grpc, :vsn)} protobuf #{Application.spec(:protobuf, :vsn)}"
)

# == G1-scaffold@48 -- parity is measured and growing (INV-1, RQ-2/D-2) ==========
# The proto enumerates exactly 72 RPCs across 10 services; each of the 48 implemented
# (Users 4 + the sandbox trio 3 + Instruments 27 + MarketData 7 + Operations 7) maps to
# its named, exported Investex.<Service>.<fun>/n; the 24 unimplemented are carried as an
# explicit pending list; the touched services are exactly the 5 (a later un-mapped or
# renamed function fails it). The count-prints-72 full assertion is 9.5.
all_rpcs = G.all_rpcs()
implemented = G.implemented()
implemented_keys = implemented |> Map.keys() |> MapSet.new()
declared = MapSet.new(all_rpcs)

mapped_ok? =
  Enum.all?(implemented, fn {{_svc, _name} = key, {mod, fun, arity}} ->
    Code.ensure_loaded?(mod) and MapSet.member?(declared, key) and
      function_exported?(mod, fun, arity)
  end)

pending = Enum.reject(all_rpcs, &MapSet.member?(implemented_keys, &1))

touched_services =
  implemented |> Map.keys() |> Enum.map(fn {service, _name} -> service end) |> Enum.uniq()

expected_touched =
  [
    Proto.UsersService.Service,
    Proto.SandboxService.Service,
    Proto.InstrumentsService.Service,
    Proto.MarketDataService.Service,
    Proto.OperationsService.Service
  ]

g1 =
  G.line(
    "G1-scaffold@48 parity",
    length(G.services()) == 10 and length(all_rpcs) == 72 and map_size(implemented) == 48 and
      mapped_ok? and length(pending) == 24 and length(pending) + map_size(implemented) == 72 and
      Enum.sort(touched_services) == Enum.sort(expected_touched),
    "the proto enumerates 72 RPCs across 10 services; the 48 implemented (Users 4 + the sandbox trio 3 + Instruments 27 + MarketData 7 + Operations 7) each map to a real, exported Investex function; the 24 unimplemented are an explicit pending list; the touched services are exactly {Users, Sandbox, Instruments, MarketData, Operations} (the count-prints-72 full assertion is 9.5)"
  )

# == G2 -- money round-trips as integers over the read-response shapes (INV-3, D-4) ==
# A self-contained seeded sweep over the {units, nano} shapes a read response carries
# (LastPrice.price / Order.price / PortfolioPosition.quantity / expected_yield =
# Quotation; PortfolioResponse.total_amount_* = MoneyValue with an ISO currency):
# from_quotation . to_quotation is identity; from_money_value decodes the pair + the
# non-empty ISO currency; NO float anywhere. Money is EXERCISED, not extended.
:rand.seed(:exsss, {92, 91, 90})
pick = fn lo, hi -> lo + :rand.uniform(hi - lo + 1) - 1 end

g2_runs =
  Enum.reduce_while(1..2_000, 0, fn _, ok ->
    units = pick.(-1_000_000_000, 1_000_000_000)
    nano = pick.(-999_999_999, 999_999_999)
    currency = Enum.random(["rub", "usd", "eur", "gbp", "hkd"])

    rt = Money.from_quotation(Money.to_quotation({units, nano}))
    %Proto.Quotation{units: u, nano: n} = Money.to_quotation({units, nano})

    {{mu, mn}, mc} =
      Money.from_money_value(%Proto.MoneyValue{currency: currency, units: units, nano: nano})

    good =
      rt == {units, nano} and is_integer(u) and is_integer(n) and not is_float(u) and
        not is_float(n) and {mu, mn} == {units, nano} and mc == currency and mc != "" and
        is_integer(mu) and is_integer(mn)

    if good, do: {:cont, ok + 1}, else: {:halt, ok}
  end)

money_exports =
  Money.module_info(:exports)
  |> Enum.reject(fn {fun, _arity} -> fun in [:module_info, :__info__] end)
  |> Enum.sort()

g2 =
  G.line(
    "G2 money-read-shapes",
    g2_runs == 2_000 and
      money_exports == [from_money_value: 1, from_quotation: 1, to_quotation: 1],
    "across 2000 seeded {units, nano} pairs in the read-response field shapes from_quotation . to_quotation is identity, from_money_value decodes the integer pair + the non-empty ISO currency, and NO value is a float; Investex.Money is exercised-not-extended (its public surface is exactly the 3 codec functions)"
  )

# == G-FID -- the pass-through-fidelity check across all 41 (NEW, 9.2) ===========
# For each of the 3 read modules, the source AST pairs every public `def <name>` to its
# `&Stub.<fun>/3` capture; assert (1) name-match (def == captured stub fun, both
# snake(RPC)), (2) the seam (arity-3 capture via the Stub alias -- no def bypasses
# Caller.unary), (3) set-equality of the def-name set vs the service's __rpc_calls__()
# snake(RPC) set. A copy-paste `def shares` -> `&Stub.bonds/3` COMPILES but fails (1).
fid =
  Enum.reduce(G.read_modules(), %{count: 0, name_ok: true, seam_ok: true, set_ok: true}, fn
    {module, service}, acc ->
      pairs = G.def_capture_pairs(module)

      seam_ok =
        acc.seam_ok and Enum.all?(pairs, fn {_def, cap} -> match?({_f, 3}, cap) end)

      name_ok =
        acc.name_ok and
          Enum.all?(pairs, fn {def_name, cap} ->
            match?({_f, 3}, cap) and elem(cap, 0) == def_name
          end)

      def_names = pairs |> Enum.map(fn {name, _cap} -> name end) |> MapSet.new()
      set_ok = acc.set_ok and def_names == G.expected_fun_names(service)

      %{
        count: acc.count + length(pairs),
        name_ok: name_ok,
        seam_ok: seam_ok,
        set_ok: set_ok
      }
  end)

g_fid =
  G.line(
    "G-FID pass-through-fidelity",
    fid.count == 41 and fid.name_ok and fid.seam_ok and fid.set_ok,
    "all 41 read functions (Instruments 27 + MarketData 7 + Operations 7) delegate via &Stub.<fun>/3 to their identically-named stub fun (snake(RPC) == def-name == stub-fun-name), no def bypasses the Caller.unary seam, and each module's def-name set equals its service's declared RPC set; a mutated pairing (def shares -> &Stub.bonds/3) turns it red (the wrong-stub class the parity scaffold cannot catch)"
  )

# == G5 -- the pure suite is network-free; the sandbox suite is excluded by default ==
# Structural: test_helper.exs starts ExUnit excluding :sandbox, and the live test
# module is tagged :sandbox (so a default `mix test` never dials). This runner itself
# dials nothing -- proof by construction (no Client/Instruments/MarketData/Operations
# call above; only Money + AST + __rpc_calls__ reflection).
helper_src = File.read!(Path.expand("../../apps/investex/test/test_helper.exs", __DIR__))
live_src = File.read!(Path.expand("../../apps/investex/test/sandbox_live_test.exs", __DIR__))

g5 =
  G.line(
    "G5 network-free",
    String.contains?(helper_src, "exclude: [:sandbox]") and
      String.contains?(live_src, "@moduletag :sandbox"),
    "test_helper.exs starts ExUnit with exclude: [:sandbox] so the default suite (and this --no-start gate) is network-free; the live read subset module is @moduletag :sandbox (excluded by default, run only on --include sandbox with INVEST_TOKEN); this gate dials nothing by construction"
  )

# == G7 -- no token value anywhere (INV-9) ======================================
# A grep of the hand-written app + tests + the generated modules for a token-shaped
# string finds none (the token is read from the environment only). The non-secret test
# marker and the "Bearer #{token}" interpolation template are not token values.
investex_root = Path.expand("../../apps/investex", __DIR__)

source_files =
  Path.wildcard(Path.join(investex_root, "lib/**/*.ex")) ++
    Path.wildcard(Path.join(investex_root, "test/**/*.{ex,exs}"))

token_re = ~r/Bearer [A-Za-z0-9._-]{10,}|INVEST_TOKEN[[:space:]]*=[[:space:]]*[A-Za-z0-9]/

token_hits =
  Enum.flat_map(source_files, fn f ->
    f
    |> File.read!()
    |> String.split("\n")
    |> Enum.filter(&Regex.match?(token_re, &1))
    |> Enum.reject(&String.contains?(&1, "Bearer #{"#"}{token}"))
    |> Enum.reject(&String.contains?(&1, "marker-not-a-real-token"))
    |> Enum.map(&{f, &1})
  end)

g7 =
  G.line(
    "G7 no-token",
    token_hits == [],
    "no token-shaped literal in the app lib, tests, or generated modules (#{length(source_files)} files scanned); the token is read from INVEST_TOKEN at call time only -- never a struct default, a config literal, a log line, a fixture, or this transcript"
  )

gates = [g1, g2, g_fid, g5, g7]

if Enum.all?(gates) do
  IO.puts("PASS #{Enum.count(gates)}/#{Enum.count(gates)}")
else
  IO.puts("FAIL")
  System.halt(1)
end
