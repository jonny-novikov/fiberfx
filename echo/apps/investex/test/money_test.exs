defmodule Investex.MoneyTest do
  @moduledoc """
  Tier 1 (pure): the integer `{units, nano}` codec round-trips with NO float in
  any value (trd.9.1.specs.md G2; INV-3, R-2/D-2). The G2 property holds over
  StreamData-generated integer money.

  9.2 (trd.9.2.specs.md §"The Money exercise", RQ-4/D-4) **exercises** the codec
  against the field shapes the read responses carry — `LastPrice.price` /
  `Order.price` / `PortfolioPosition.quantity` / `expected_yield` are `Quotation`;
  `PortfolioResponse.total_amount_*` is a `MoneyValue` with a non-empty ISO
  currency — adding NO new `Investex.Money` function (exercised, not extended).
  The live decode of REAL such fields is the sandbox tier's money half
  (sandbox_live_test.exs).
  """
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Investex.Money
  alias Tinkoff.Public.Invest.Api.Contract.V1, as: Proto

  doctest Investex.Money

  # int64 units, int32 nano — the proto field widths (common.proto:28-48).
  defp units_gen, do: integer(-9_223_372_036_854_775_808..9_223_372_036_854_775_807)
  defp nano_gen, do: integer(-2_147_483_648..2_147_483_647)

  property "G2: from_quotation ∘ to_quotation is identity over integer {units, nano}" do
    check all units <- units_gen(), nano <- nano_gen() do
      pair = {units, nano}
      assert Money.from_quotation(Money.to_quotation(pair)) == pair
    end
  end

  property "G2: to_quotation ∘ from_quotation is identity over a Quotation struct" do
    check all units <- units_gen(), nano <- nano_gen() do
      q = %Proto.Quotation{units: units, nano: nano}
      assert Money.to_quotation(Money.from_quotation(q)) == q
    end
  end

  property "G2: no float appears in any round-tripped value" do
    check all units <- units_gen(), nano <- nano_gen() do
      {u, n} = Money.from_quotation(%Proto.Quotation{units: units, nano: nano})
      assert is_integer(u) and is_integer(n)
      refute is_float(u) or is_float(n)

      %Proto.Quotation{units: u2, nano: n2} = Money.to_quotation({units, nano})
      assert is_integer(u2) and is_integer(n2)
    end
  end

  property "G2: from_money_value decodes the integer pair plus the ISO currency" do
    check all units <- units_gen(),
              nano <- nano_gen(),
              currency <- member_of(["rub", "usd", "eur", ""]) do
      mv = %Proto.MoneyValue{currency: currency, units: units, nano: nano}
      assert {{^units, ^nano}, ^currency} = Money.from_money_value(mv)
    end
  end

  # The 9.2 read-response field shapes (RQ-4/D-4). The spec pins the boundary
  # generators a real read response carries: units ∈ {0, large ±}, nano ∈ {0,
  # negative, ±}, and (for MoneyValue) a non-empty ISO currency. These subsume
  # nothing the broad-range properties above miss numerically, but they make the
  # read-services' money contract legible and pin the boundary values.
  defp read_units_gen do
    one_of([
      constant(0),
      integer(1..9_223_372_036_854_775_807),
      integer(-9_223_372_036_854_775_808..-1)
    ])
  end

  defp read_nano_gen do
    one_of([constant(0), integer(-999_999_999..-1), integer(1..999_999_999)])
  end

  property "G2 (9.2): the Quotation read-response shape (LastPrice.price / Order.price / quantity / yield) round-trips integers" do
    check all units <- read_units_gen(), nano <- read_nano_gen() do
      # The shape get_last_prices / get_order_book / get_portfolio responses carry.
      q = %Proto.Quotation{units: units, nano: nano}
      {u, n} = Money.from_quotation(q)

      assert {u, n} == {units, nano}
      assert is_integer(u) and is_integer(n)
      refute is_float(u) or is_float(n)
      assert Money.to_quotation({u, n}) == q
    end
  end

  property "G2 (9.2): the MoneyValue read-response shape (PortfolioResponse.total_amount_*) decodes to {{units, nano}, currency} with a non-empty ISO currency" do
    check all units <- read_units_gen(),
              nano <- read_nano_gen(),
              currency <- member_of(["rub", "usd", "eur", "gbp", "hkd"]) do
      mv = %Proto.MoneyValue{currency: currency, units: units, nano: nano}
      {{u, n}, c} = Money.from_money_value(mv)

      assert {{u, n}, c} == {{units, nano}, currency}
      assert is_integer(u) and is_integer(n)
      refute is_float(u) or is_float(n)
      assert c != "" and is_binary(c)
    end
  end

  test "fractional prices carry exactly (no rounding at the codec)" do
    assert Money.from_quotation(%Proto.Quotation{units: 100, nano: 250_000_000}) ==
             {100, 250_000_000}

    assert Money.to_quotation({-1, -500_000_000}) ==
             %Proto.Quotation{units: -1, nano: -500_000_000}
  end

  test "Investex.Money is exercised, not extended — no new public function at 9.2 (RQ-4/D-4)" do
    # The 9.2 Money exercise adds tests, not functions. The public surface stays
    # exactly the three 9.1 codec functions (money.ex:35/49/62); a new public
    # Money/_ would fail this guard. (`module_info(:exports)` adds the
    # compiler-injected reflection callbacks `module_info/0,1` and `__info__/1`;
    # filter both to the real public arities.)
    exports =
      Investex.Money.module_info(:exports)
      |> Enum.reject(fn {fun, _arity} -> fun in [:module_info, :__info__] end)
      |> Enum.sort()

    assert exports == [from_money_value: 1, from_quotation: 1, to_quotation: 1]
  end
end
