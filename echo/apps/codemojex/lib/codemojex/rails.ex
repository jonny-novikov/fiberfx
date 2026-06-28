defmodule Codemojex.Rails do
  @moduledoc """
  The closed set of four pay-in rails, as FROZEN module data (cm.7, cm-7 D-6 F1/F5).

  A bare `rail` STRING is the discriminator (the brand-is-the-type discipline applied
  to currency); the per-rail scaling facts — the minor unit, the major->minor factor,
  the decimals — live HERE, never in a mutable `decimals` column (a money-scaling
  constant an admin could fat-finger silently mis-scales every nanoTON). Each rail
  stores its amount in its NATIVE smallest unit, integer-exact (F5): a Star is its own
  minor unit (XTR has no sub-unit), a TON is 1e9 nanoTON, a USDT is 1e6 micro-USDT, a
  rouble is 100 kopeck. `order.price_minor`, `OTX.amount_minor`, and the
  `revenue_ledger.delta` all carry the SAME unit per currency.

  `self_check!/0` is the boot vector (the `EchoData.BrandedId.self_check!` pattern):
  it asserts each rail's `factor == 10 ** decimals`, so a typo in a factor fails fast
  at boot, not at the first mis-booked order. Wired into `Codemojex.Application`.
  """

  # The minor-unit convention (cm-7 D-6 F5 — every rail's amount stored in its NATIVE
  # smallest unit, integer-exact). A wrong factor is caught by self_check!/0 at boot.
  @rails %{
    "stars" => %{minor: :star, factor: 1, decimals: 0},
    "ton" => %{minor: :nano_ton, factor: 1_000_000_000, decimals: 9},
    "usdt" => %{minor: :micro_usdt, factor: 1_000_000, decimals: 6},
    "rub" => %{minor: :kopeck, factor: 100, decimals: 2}
  }
  @rail_names ~w(stars ton usdt rub)

  @doc "The closed rail set — the CHECK + the changeset-inclusion source (cm-7 D-6 F1)."
  @spec rails() :: [binary()]
  def rails, do: @rail_names

  @doc "True when `rail` is one of the four known rails."
  @spec known?(binary()) :: boolean()
  def known?(rail), do: rail in @rail_names

  @doc "The major->minor factor for a rail (e.g. 1_000_000_000 for ton)."
  @spec factor(binary()) :: pos_integer()
  def factor(rail), do: fetch!(rail).factor

  @doc "The number of decimal places the rail's minor unit represents."
  @spec decimals(binary()) :: non_neg_integer()
  def decimals(rail), do: fetch!(rail).decimals

  @doc "The minor-unit name for a rail (e.g. `:nano_ton`)."
  @spec minor(binary()) :: atom()
  def minor(rail), do: fetch!(rail).minor

  @doc """
  The boot vector: assert each rail's `factor == 10 ** decimals`. Raises on a typo so a
  mis-scaling money constant cannot ship silently. Returns `:ok`.
  """
  @spec self_check!() :: :ok
  def self_check! do
    for {rail, %{factor: factor, decimals: decimals}} <- @rails do
      expected = Integer.pow(10, decimals)

      if factor != expected do
        raise "Codemojex.Rails self-check failed: rail #{inspect(rail)} factor #{factor} != 10**#{decimals} (#{expected})"
      end
    end

    :ok
  end

  defp fetch!(rail) do
    case Map.fetch(@rails, rail) do
      {:ok, facts} -> facts
      :error -> raise ArgumentError, "unknown rail #{inspect(rail)} (known: #{inspect(@rail_names)})"
    end
  end
end
