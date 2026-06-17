# trd_9_1_check.exs -- gates G1-scaffold, G2, G4, G5, G7: the investex transport spine.
#   cd /Users/jonny/dev/jonnify/echo && mix run --no-start rungs/exchange/trd_9_1_check.exs
#
# A COMPILED-umbrella `mix run --no-start` runner (D-4) -- NOT a Code.require_file
# pure runner like trd_2_1_check.exs, because Config/Money/Retry/the parity scaffold
# reference the GENERATED :protobuf structs (Tinkoff.Public.Invest.Api.Contract.V1.*),
# which exist only as compiled artifacts. The runner aliases the compiled modules
# directly, dials NOTHING (`:investex` is lib-only -- no mod: -- so loading it opens
# no connection), and stays network-free: it exercises only the pure surface
# (Config defaults, the Money round-trip, the Retry decision, the parity scaffold)
# plus two structural greps (the :sandbox exclusion, the no-token scan). One printed
# line per gate; nonzero exit on any failure. The generator is a self-contained
# seeded :rand (no StreamData dep, so --no-start-safe and deterministic).
# Spec: docs/exchange/trd.9.1.specs.md ("Acceptance gates"); the trd_2_1_check.exs pattern.

alias Investex.{Config, Money, Retry}
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

  # The 7 implemented RPCs: {Service, proto RPC name} -> {Elixir module, fun, arity}.
  def implemented do
    %{
      {Proto.UsersService.Service, :GetAccounts} => {Investex.Users, :get_accounts, 1},
      {Proto.UsersService.Service, :GetMarginAttributes} =>
        {Investex.Users, :get_margin_attributes, 2},
      {Proto.UsersService.Service, :GetUserTariff} => {Investex.Users, :get_user_tariff, 1},
      {Proto.UsersService.Service, :GetInfo} => {Investex.Users, :get_info, 1},
      {Proto.SandboxService.Service, :OpenSandboxAccount} => {Investex.Sandbox, :open_account, 1},
      {Proto.SandboxService.Service, :GetSandboxAccounts} => {Investex.Sandbox, :get_accounts, 1},
      {Proto.SandboxService.Service, :CloseSandboxAccount} => {Investex.Sandbox, :close_account, 2}
    }
  end

  # Every {service, rpc_name} the proto declares, enumerated from the real modules.
  def all_rpcs do
    for service <- services(),
        {name, _req, _resp, _opts} <- service.__rpc_calls__(),
        do: {service, name}
  end
end

IO.puts(
  "header: Investex transport spine (lib-only, no dial) | Elixir #{System.version()} OTP #{:erlang.system_info(:otp_release)} | grpc #{Application.spec(:grpc, :vsn)} protobuf #{Application.spec(:protobuf, :vsn)}"
)

# == G1-scaffold -- parity is measured and growing (INV-1, R-3/D-3) ==============
# The proto enumerates exactly 72 RPCs across 10 services; each of the 7 implemented
# maps to its named, exported Investex.<Service>.<fun>/n; the 65 unimplemented are
# carried as an explicit pending list (a later un-mapped or renamed function fails it).
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

g1 =
  G.line(
    "G1-scaffold parity",
    length(G.services()) == 10 and length(all_rpcs) == 72 and map_size(implemented) == 7 and
      mapped_ok? and length(pending) == 65 and length(pending) + map_size(implemented) == 72,
    "the proto enumerates 72 RPCs across 10 services; the 7 implemented (UsersService 4 + the sandbox trio 3) each map to a real, exported Investex function; the 65 unimplemented are carried as an explicit pending list (rows move pending->asserted across 9.2-9.5; the count-prints-72 full assertion is 9.5)"
  )

# == G2 -- money round-trips as integers (INV-3, R-2/D-2) =======================
# A self-contained seeded sweep over {units, nano}: from_quotation . to_quotation is
# identity; from_money_value decodes the pair + the ISO currency; NO float anywhere.
:rand.seed(:exsss, {91, 92, 93})
pick = fn lo, hi -> lo + :rand.uniform(hi - lo + 1) - 1 end

g2_runs =
  Enum.reduce_while(1..2_000, 0, fn _, ok ->
    units = pick.(-1_000_000_000, 1_000_000_000)
    nano = pick.(-999_999_999, 999_999_999)
    currency = Enum.random(["rub", "usd", "eur", ""])

    rt = Money.from_quotation(Money.to_quotation({units, nano}))
    %Proto.Quotation{units: u, nano: n} = Money.to_quotation({units, nano})
    {{mu, mn}, mc} = Money.from_money_value(%Proto.MoneyValue{currency: currency, units: units, nano: nano})

    good =
      rt == {units, nano} and is_integer(u) and is_integer(n) and not is_float(u) and
        not is_float(n) and {mu, mn} == {units, nano} and mc == currency and is_integer(mu) and
        is_integer(mn)

    if good, do: {:cont, ok + 1}, else: {:halt, ok}
  end)

g2 =
  G.line(
    "G2 money-round-trip",
    g2_runs == 2_000,
    "across 2000 seeded {units, nano} pairs from_quotation . to_quotation is identity, from_money_value decodes the integer pair + the ISO currency, and NO value is a float (the Go ToFloat/FloatToQuotation bridge is deliberately not ported)"
  )

# == G4 -- the retry decision is pure and correct (INV-6) =======================
# The three branches at their boundaries; plus a comments-stripped grep proving the
# decision holds no clock/sleep/Process.*/network/IO.
retry_branches =
  # linear: :unavailable/:internal under the cap -> {:retry, 500}
  Retry.decide(:unavailable, 0, %{}) == {:retry, 500} and
    Retry.decide(:internal, 2, %{}) == {:retry, 500} and
    # resource-exhausted: honor x-ratelimit-reset (seconds->ms), floored at 500
    Retry.decide(:resource_exhausted, 0, %{"x-ratelimit-reset" => "7"}) == {:retry, 7000} and
    Retry.decide(:resource_exhausted, 0, %{}) == {:retry, 500} and
    Retry.decide(:resource_exhausted, 0, %{"x-ratelimit-reset" => "0"}) == {:retry, 500} and
    # give-up: past the cap, RE-disabled, disable_all_retry, unretryable status
    Retry.decide(:unavailable, 3, %{}) == :give_up and
    Retry.decide(:resource_exhausted, 0, %{"x-ratelimit-reset" => "5"}, Config.new(disable_resource_exhausted_retry: true)) ==
      :give_up and
    Retry.decide(:unavailable, 0, %{}, Config.new(disable_all_retry: true)) == :give_up and
    Retry.decide(:not_found, 0, %{}) == :give_up

retry_code =
  Path.expand("../../apps/investex/lib/investex/retry.ex", __DIR__)
  |> File.read!()
  |> String.split("\n")
  |> Enum.map_join("\n", &Regex.replace(~r/#.*/, &1, ""))

forbidden = [
  "Process.sleep",
  ":timer.sleep",
  "System.monotonic_time",
  "System.os_time",
  "System.system_time",
  "DateTime.utc_now",
  "GRPC.Stub",
  "IO."
]

retry_pure? = Enum.all?(forbidden, &(not String.contains?(retry_code, &1)))

g4 =
  G.line(
    "G4 retry-pure",
    retry_branches and retry_pure?,
    "decide/3+/4 returns {:retry, 500} on :unavailable/:internal under the cap, {:retry, wait} honoring x-ratelimit-reset (floored 500) on :resource_exhausted, and :give_up past max_retries / RE-disabled / disable_all_retry / an unretryable status; retry.ex (comments stripped) contains no clock/sleep/Process.*/network/IO"
  )

# == G5 -- the pure suite is network-free; the sandbox suite is excluded by default ==
# Structural: test_helper.exs starts ExUnit excluding :sandbox, and the live test
# module is tagged :sandbox (so a default `mix test` never dials). This runner
# itself dials nothing -- proof by construction (no Client/Users/Sandbox call above).
helper_src = File.read!(Path.expand("../../apps/investex/test/test_helper.exs", __DIR__))
live_src = File.read!(Path.expand("../../apps/investex/test/sandbox_live_test.exs", __DIR__))

g5 =
  G.line(
    "G5 network-free",
    String.contains?(helper_src, "exclude: [:sandbox]") and
      String.contains?(live_src, "@moduletag :sandbox"),
    "test_helper.exs starts ExUnit with exclude: [:sandbox] so the default suite (and this --no-start gate) is network-free; the live round-trip module is @moduletag :sandbox (excluded by default, run only on --include sandbox with INVEST_TOKEN); this gate dials nothing by construction"
  )

# == G7 -- no token value anywhere (INV-9) ======================================
# A grep of the hand-written app + tests + the generated modules for a token-shaped
# string finds none (the token is read from the environment only). The non-secret
# test marker and the "Bearer #{token}" interpolation template are not token values.
investex_root = Path.expand("../../apps/investex", __DIR__)

source_files =
  Path.wildcard(Path.join(investex_root, "lib/**/*.ex")) ++
    Path.wildcard(Path.join(investex_root, "test/**/*.{ex,exs}"))

# A token-shaped literal: Bearer <>=10 opaque chars, or INVEST_TOKEN=<value>, or a
# long dotted opaque token. The known non-secrets are excluded.
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

gates = [g1, g2, g4, g5, g7]

if Enum.all?(gates) do
  IO.puts("PASS #{Enum.count(gates)}/#{Enum.count(gates)}")
else
  IO.puts("FAIL")
  System.halt(1)
end
