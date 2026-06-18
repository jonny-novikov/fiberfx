defmodule Investex.Money do
  @moduledoc """
  The integer `{units, nano}` money codec (rung TRD.9.1,
  `docs/exchange/trd.9.1.specs.md` §Surface; INV-3, R-2/D-2).

  The venue speaks money as two integers — `units` (the whole part, int64) and
  `nano` (billionths, int32) — for both `Quotation` (no currency) and
  `MoneyValue` (with an ISO currency string) (common.proto:28-48). This codec
  carries that representation in and out of the generated structs as an integer
  pair, and **no float appears in any value, request, or response shape it
  exposes** (INV-3). The Go SDK's float bridge (`converters.go`'s
  `ToFloat`/`FloatToQuotation`) is deliberately **not** ported — that is the
  divergence INV-3 names: floating-point money is a class of rounding bug the
  whole Exchange platform refuses.

  `Investex.Money` lands in 9.1 though no 9.1-implemented RPC's response carries
  money (only the deferred `GetMarginAttributes` does, users.proto:89-108): the
  codec is pure and network-free, its input structs exist the instant the 9.1
  codegen runs, and it is the integer contract the money-dense read services
  (9.2) inherit (R-2/D-2).
  """

  alias Tinkoff.Public.Invest.Api.Contract.V1, as: Proto

  @typedoc "Venue money: `units` whole, `nano` billionths — both integers, never a float (common.proto:28-48)."
  @type money :: {units :: integer(), nano :: integer()}

  @doc """
  Decodes a `%Proto.Quotation{}` to the integer pair `{units, nano}`.

      iex> alias Tinkoff.Public.Invest.Api.Contract.V1, as: Proto
      iex> Investex.Money.from_quotation(%Proto.Quotation{units: 100, nano: 250_000_000})
      {100, 250_000_000}
  """
  @spec from_quotation(Proto.Quotation.t()) :: money()
  def from_quotation(%Proto.Quotation{units: units, nano: nano})
      when is_integer(units) and is_integer(nano) do
    {units, nano}
  end

  @doc """
  Encodes the integer pair `{units, nano}` back to a `%Proto.Quotation{}`.
  Round-trips `from_quotation/1` exactly (G2); no float enters the struct.

      iex> alias Tinkoff.Public.Invest.Api.Contract.V1, as: Proto
      iex> Investex.Money.to_quotation({100, 250_000_000})
      %Proto.Quotation{units: 100, nano: 250_000_000}
  """
  @spec to_quotation(money()) :: Proto.Quotation.t()
  def to_quotation({units, nano}) when is_integer(units) and is_integer(nano) do
    %Proto.Quotation{units: units, nano: nano}
  end

  @doc """
  Decodes a `%Proto.MoneyValue{}` to `{{units, nano}, currency}` — the integer
  pair plus the ISO currency string that rides alongside (common.proto:28-38).

      iex> alias Tinkoff.Public.Invest.Api.Contract.V1, as: Proto
      iex> Investex.Money.from_money_value(%Proto.MoneyValue{currency: "rub", units: 5, nano: 0})
      {{5, 0}, "rub"}
  """
  @spec from_money_value(Proto.MoneyValue.t()) :: {money(), currency :: String.t()}
  def from_money_value(%Proto.MoneyValue{units: units, nano: nano, currency: currency})
      when is_integer(units) and is_integer(nano) and is_binary(currency) do
    {{units, nano}, currency}
  end
end
