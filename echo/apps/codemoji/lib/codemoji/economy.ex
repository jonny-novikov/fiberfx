defmodule Codemoji.Economy do
  @moduledoc """
  The money math, pure. Stars buy Keys, Keys buy guesses, entry fees in Stars feed
  the prize pool, and the pool settles after the platform fee. Every function here
  is a pure calculation — the ledgers (player balances, the pool) live in the
  component stores and Valkey; this module only decides amounts, so the same
  inputs always yield the same split and a re-run settlement pays identically.
  """
  @fee 0.30
  @stars_per_key 10

  @doc "Platform fee fraction (0.30)."
  def fee, do: @fee

  @doc "Keys bought for `stars` at `rate` stars per key (floored)."
  def keys_for_stars(stars, rate \\ @stars_per_key) when stars >= 0 and rate > 0, do: div(stars, rate)

  @doc "Stars cost of `keys` at `rate` stars per key."
  def stars_for_keys(keys, rate \\ @stars_per_key) when keys >= 0, do: keys * rate

  @doc "From a pool, the platform's `{cut, net}` after the fee."
  def split_pool(pool, fee \\ @fee) when pool >= 0 do
    cut = trunc(pool * fee)
    {cut, pool - cut}
  end

  @doc """
  Proportional payouts: `net` split across `ranked` (`{player, score}`) in
  proportion to score. Returns `[{player, payout}]`, integer-floored; an
  all-zero board pays nothing.
  """
  def payouts(net, ranked) when net >= 0 do
    sum = ranked |> Enum.map(&elem(&1, 1)) |> Enum.sum()

    if sum <= 0 do
      Enum.map(ranked, fn {p, _} -> {p, 0} end)
    else
      Enum.map(ranked, fn {p, s} -> {p, trunc(net * s / sum)} end)
    end
  end
end
