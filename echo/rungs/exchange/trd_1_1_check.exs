# trd_1_1_check.exs -- gates G1..G5 + cancel + totality + AS-5: the Exchange Gateway MVP.
#   cd /Users/jonny/dev/jonnify/echo && mix run --no-start rungs/exchange/trd_1_1_check.exs
#
# The Gateway is pure and touches no Valkey (INV-5), so this is a --no-start runner:
# it Code.require_file's the id canon raw (base62 -> native -> snowflake -> branded_id)
# then the Gateway module, calls EchoData.Snowflake.start(N) once (the INV-3 minting
# prerequisite), and runs one printed line per gate. Nonzero exit on any failure.
# Spec: docs/exchange/trd.1.1.specs.md ("Acceptance gates").

for f <- ~w(base62 native snowflake branded_id) do
  Code.require_file(Path.expand("../../apps/echo_data/lib/echo_data/#{f}.ex", __DIR__))
end

Code.require_file(Path.expand("../../apps/exchange/lib/exchange/gateway.ex", __DIR__))

:ok = EchoData.Snowflake.start(11)
alias EchoData.BrandedId
alias Exchange.Gateway

defmodule G do
  def line(tag, ok, detail) do
    IO.puts("#{tag} #{if ok, do: "ok", else: "FAIL"} -- #{detail}")
    ok
  end

  # Structural float-scan over a parsed command term (INV-2 / G3): no number
  # anywhere -- the tag, the map values, the {units, nano} pair -- may be a float.
  def no_float?(f) when is_float(f), do: false
  def no_float?({a, b}), do: no_float?(a) and no_float?(b)
  def no_float?(%{} = m), do: Enum.all?(m, fn {k, v} -> no_float?(k) and no_float?(v) end)
  def no_float?(list) when is_list(list), do: Enum.all?(list, &no_float?/1)
  def no_float?(_), do: true
end

IO.puts(
  "header: Exchange.Gateway (pure, no Valkey) | Elixir #{System.version()} OTP #{:erlang.system_info(:otp_release)} | schedulers #{System.schedulers_online()}"
)

# A canonical well-formed limit buy; the malformed cases overwrite one field each.
limit_buy = %{
  instrument: "BBG004730N88",
  account: "acct-2000",
  direction: :buy,
  type: :limit,
  quantity: 10,
  price: {145, 250_000_000}
}

over = fn m -> Map.merge(limit_buy, m) end

# G1 -- valid place parses and mints two distinct ids (INV-1, INV-2, INV-3)
{:ok, {:place, m1a}} = Gateway.parse_place(limit_buy)
{:ok, {:place, m1b}} = Gateway.parse_place(limit_buy)

g1 =
  G.line(
    "G1 place-mints",
    byte_size(m1a.id) == 14 and BrandedId.valid?(m1a.id) and BrandedId.namespace(m1a.id) == "ORD" and
      m1a.price == {145, 250_000_000} and is_integer(elem(m1a.price, 0)) and
      is_integer(elem(m1a.price, 1)) and m1a.id != m1b.id,
    "a well-formed limit buy mints a branded ORD id (14 bytes, valid?) with a {units, nano} integer price; the same input twice yields two distinct ids (mint order)"
  )

# G2 -- each error is reachable and exact (INV-1)
g2cases = [
  {over.(%{instrument: ""}), :unknown_instrument},
  {over.(%{direction: :hodl}), :bad_direction},
  {over.(%{type: :bestprice}), :bad_order_type},
  {over.(%{quantity: 0}), :nonpositive_quantity},
  {over.(%{price: 1.45}), :bad_price},
  {"not a map", :malformed}
]

g2results =
  Enum.map(g2cases, fn {input, want} -> Gateway.parse_place(input) == {:error, want} end)

g2atoms = Enum.map(g2cases, fn {_, want} -> want end) |> Enum.uniq() |> length()

g2 =
  G.line(
    "G2 errors-exact",
    Enum.all?(g2results) and g2atoms == 6,
    "six malformed inputs yield the six error atoms, one each (:unknown_instrument, :bad_direction, :bad_order_type, :nonpositive_quantity, :bad_price, :malformed); no crash, no unclassified result"
  )

# G3 -- no float survives (INV-2)
float_price = Gateway.parse_place(over.(%{price: 1.45}))
float_pair = Gateway.parse_place(over.(%{price: {145, 2.5}}))
extra_dot = Gateway.parse_money("1.4.5")
sci = Gateway.parse_money("1.5e3")
{:ok, c3limit} = Gateway.parse_place(limit_buy)
{:ok, c3market} = Gateway.parse_place(over.(%{type: :market}))

g3 =
  G.line(
    "G3 no-float",
    float_price == {:error, :bad_price} and float_pair == {:error, :bad_price} and
      extra_dot == {:error, :bad_price} and sci == {:error, :bad_price} and
      G.no_float?(c3limit) and G.no_float?(c3market),
    "a float-bearing price (1.45, {145, 2.5}), an extra-dot string (1.4.5) and scientific notation (1.5e3) are all :bad_price; no float appears anywhere in an accepted command term (structural scan, limit + market)"
  )

# G4 -- market order ignores price (INV-1)
{:ok, {:place, m4a}} = Gateway.parse_place(over.(%{type: :market}))
{:ok, {:place, m4b}} = Gateway.parse_place(over.(%{type: :market, price: 1.45}))
{:ok, {:place, m4c}} = Gateway.parse_place(Map.delete(over.(%{type: :market}), :price))

g4 =
  G.line(
    "G4 market-ignores-price",
    m4a.price == :market and m4b.price == :market and m4c.price == :market,
    "a market order parses with price: :market regardless of any price field -- a parseable price, a float price, and no price field all yield :market (per the venue contract)"
  )

# G5 -- opaque ids carried verbatim, unbranded (INV-4)
{:ok, {:place, m5}} =
  Gateway.parse_place(over.(%{instrument: "BBG-WEIRD-123", account: "acct-XYZ"}))

g5 =
  G.line(
    "G5 opaque-verbatim",
    m5.instrument == "BBG-WEIRD-123" and m5.account == "acct-XYZ" and
      BrandedId.parse(m5.instrument) == :error and BrandedId.parse(m5.account) == :error,
    "instrument and account appear in the command unchanged; they are opaque strings, not branded ids (BrandedId.parse refuses them) -- never branded, never rewritten"
  )

# cancel -- parse_cancel/1 parses (INV-1, INV-3, INV-4)
cancel_raw = %{instrument: "BBG004730N88", order_ref: "venue-ref-991"}
{:ok, {:cancel, mc1}} = Gateway.parse_cancel(cancel_raw)
{:ok, {:cancel, mc2}} = Gateway.parse_cancel(cancel_raw)
no_ref = Gateway.parse_cancel(Map.delete(cancel_raw, :order_ref))

gc =
  G.line(
    "cancel parses",
    byte_size(mc1.id) == 14 and BrandedId.valid?(mc1.id) and BrandedId.namespace(mc1.id) == "CMD" and
      mc1.instrument == "BBG004730N88" and mc1.order_ref == "venue-ref-991" and mc1.id != mc2.id and
      no_ref == {:error, :malformed},
    "a well-formed cancel mints a branded CMD id and carries order_ref + instrument verbatim; two cancels yield distinct ids; a missing order_ref is :malformed"
  )

# totality property -- over generated inputs (INV-1, INV-2, INV-5)
# A self-contained pseudo-random generator (no StreamData dep, so --no-start-safe
# and deterministic): each field draws from a pool mixing well-formed values, junk
# atoms, wrong types (floats, lists, nil), and -- via a random key-drop -- missing
# keys. Every output must be {:ok, command} (no float, 14-byte id) or {:error, atom}
# with the atom in the closed six-set; never a crash, never a partial command.
:rand.seed(:exsss, {101, 202, 303})

error_set = [
  :unknown_instrument,
  :bad_direction,
  :bad_order_type,
  :nonpositive_quantity,
  :bad_price,
  :malformed
]

pick = fn pool -> Enum.random(pool) end

junk = [nil, 42, -7, 3.14, :weird, "", "  ", [1, 2], true, {:replace, %{}}]

draw_place = fn ->
  base = %{
    instrument: pick.(["BBG004730N88", "BBG000B9XRY4" | junk]),
    account: pick.(["acct-1", "acct-2" | junk]),
    direction: pick.([:buy, :sell, "buy", "ORDER_DIRECTION_SELL" | junk]),
    type: pick.([:limit, :market, "limit", "ORDER_TYPE_MARKET", :bestprice | junk]),
    quantity: pick.([1, 10, 999, 0, -5 | junk]),
    price: pick.([{145, 0}, {145, 250_000_000}, "10", "10.5", {-2, 0}, 1.45, "1.4.5" | junk])
  }

  drop = Enum.take_random(Map.keys(base), :rand.uniform(4) - 1)
  Map.drop(base, drop)
end

draw_cancel = fn ->
  base = %{
    instrument: pick.(["BBG004730N88" | junk]),
    order_ref: pick.(["venue-ref-1", "venue-ref-2" | junk])
  }

  drop = Enum.take_random(Map.keys(base), :rand.uniform(3) - 1)
  Map.drop(base, drop)
end

total? = fn result, tag ->
  case result do
    {:ok, {^tag, m}} ->
      is_map(m) and is_binary(m.id) and byte_size(m.id) == 14 and G.no_float?({tag, m})

    {:error, atom} ->
      atom in error_set

    _ ->
      false
  end
end

n_prop = 2_000

prop_place =
  Enum.reduce_while(1..n_prop, {0, nil}, fn _, {ok, _} ->
    raw = draw_place.()

    case (try do
            {:total, total?.(Gateway.parse_place(raw), :place)}
          rescue
            e -> {:crash, {raw, e}}
          end) do
      {:total, true} -> {:cont, {ok + 1, nil}}
      {:total, false} -> {:halt, {ok, {:nontotal, raw, Gateway.parse_place(raw)}}}
      {:crash, info} -> {:halt, {ok, {:crash, info}}}
    end
  end)

prop_cancel =
  Enum.reduce_while(1..n_prop, {0, nil}, fn _, {ok, _} ->
    raw = draw_cancel.()

    case (try do
            {:total, total?.(Gateway.parse_cancel(raw), :cancel)}
          rescue
            e -> {:crash, {raw, e}}
          end) do
      {:total, true} -> {:cont, {ok + 1, nil}}
      {:total, false} -> {:halt, {ok, {:nontotal, raw, Gateway.parse_cancel(raw)}}}
      {:crash, info} -> {:halt, {ok, {:crash, info}}}
    end
  end)

# Non-map inputs are :malformed, never a crash.
nonmap_ok =
  Enum.all?([nil, 42, "str", [1, 2], true, 3.14], fn x ->
    Gateway.parse_place(x) == {:error, :malformed} and
      Gateway.parse_cancel(x) == {:error, :malformed}
  end)

gt =
  G.line(
    "totality",
    elem(prop_place, 0) == n_prop and elem(prop_cancel, 0) == n_prop and nonmap_ok,
    "#{n_prop} generated place inputs and #{n_prop} cancel inputs (well-formed, wrong-typed, missing-key) each resolve to {:ok, command} or one closed error atom -- never a crash, never a float, never a partial command; every non-map input is :malformed"
  )

# AS-5 -- statelessness grep + the dependency surface (INV-5)
# The grep is over CODE, not prose: strip line comments first so the moduledoc's
# prose ("no ETS", "no `mod:`") cannot trip a substring match -- the spec's
# "grep over lib/" means the source, not its documentation.
strip_comments = fn src ->
  src |> String.split("\n") |> Enum.map_join("\n", &Regex.replace(~r/#.*/, &1, ""))
end

lib_code =
  Path.expand("../../apps/exchange/lib", __DIR__)
  |> Path.join("**/*.ex")
  |> Path.wildcard()
  |> Enum.map_join("\n", fn f -> f |> File.read!() |> strip_comments.() end)

stateless? =
  not String.contains?(lib_code, "use GenServer") and not String.contains?(lib_code, ":ets") and
    not String.contains?(lib_code, "Application.get_env")

# The dependency surface, checked STRUCTURALLY (immune to comments): the loaded
# Mix project's application/0 declares no `:mod:` boot module (one stateless lib),
# and deps/0 is exactly the sanctioned in-umbrella canon edge + the test-only
# stream_data -- no new external runtime dependency (the AS-5 prohibition).
app_kw = Exchange.MixProject.application()
deps_kw = Exchange.MixProject.project() |> Keyword.fetch!(:deps)

deps_ok =
  not Keyword.has_key?(app_kw, :mod) and
    Enum.sort(deps_kw) ==
      Enum.sort([{:echo_data, in_umbrella: true}, {:stream_data, "~> 1.0", only: :test}])

gas5 =
  G.line(
    "AS-5 stateless",
    stateless? and deps_ok,
    "lib/ code has no `use GenServer`, no `:ets`, no `Application.get_env`; application/0 declares no `:mod` boot module and deps/0 is exactly {:echo_data, in_umbrella: true} + {:stream_data, only: :test} -- one stateless module, no new external dependency"
  )

gates = [g1, g2, g3, g4, g5, gc, gt, gas5]

if Enum.all?(gates) do
  IO.puts("PASS #{Enum.count(gates)}/#{Enum.count(gates)}")
else
  IO.puts("FAIL")
  System.halt(1)
end
