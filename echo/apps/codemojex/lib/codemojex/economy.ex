defmodule Codemojex.Economy do
  @moduledoc """
  The money math, pure — three currencies. Keys pay for guesses in paid rooms and
  are bought with Telegram Stars; Clips pay for guesses in free rooms only and
  carry no value; Diamonds are the prize currency, won from rooms and convertible
  to keys at a fixed 10:1. Every function here is a pure calculation; balances and
  the ledger live elsewhere, so the same inputs always yield the same result and a
  re-run settlement pays identically.
  """
  @diamonds_per_key 10
  @cents_per_diamond 1.2

  def diamonds_per_key, do: @diamonds_per_key

  @doc "Keys obtained by converting `diamonds` (floored to whole keys)."
  def keys_from_diamonds(d) when d >= 0, do: div(d, @diamonds_per_key)

  @doc "Diamonds needed to mint `keys` by conversion."
  def diamonds_for_keys(k) when k >= 0, do: k * @diamonds_per_key

  @doc "USD cents for a diamond amount (1 diamond = 1.2 cents)."
  def to_cents(d), do: round(d * @cents_per_diamond)

  @doc ~S|Formatted USD for a diamond amount, e.g. `"$3.40"` for 283.|
  def to_usd(d) do
    "$" <> :erlang.float_to_binary(to_cents(d) / 100, decimals: 2)
  end

  @doc """
  The pool actually paid out at settlement. A Golden Room multiplies its diamond
  `pool` by `mult` — the platform funds the boost — while a normal room pays its
  pool as-is. The multiplier is applied once, at close, over the seeded pool.
  """
  def effective_pool(pool, golden, mult)
  def effective_pool(pool, true, mult) when is_integer(mult) and mult > 0, do: pool * mult
  def effective_pool(pool, _golden, _mult), do: pool

  @doc """
  Winner-take-all payout — the room-close rule: the whole `pool` (diamonds) goes
  to the max-score player(s), split evenly on a tie. `board` is `[{player, score}]`
  highest first. Returns `[{player, diamonds}]`.
  """
  def winner_take_all(_pool, []), do: []

  def winner_take_all(pool, [{_, top} | _] = board) do
    winners = board |> Enum.filter(fn {_, s} -> s == top end) |> Enum.map(&elem(&1, 0))
    share = div(pool, length(winners))
    Enum.map(winners, &{&1, share})
  end

  @doc "Proportional payout (an alternative split): `net` shared by score."
  def proportional(net, board) do
    sum = board |> Enum.map(&elem(&1, 1)) |> Enum.sum()

    if sum <= 0,
      do: Enum.map(board, fn {p, _} -> {p, 0} end),
      else: Enum.map(board, fn {p, s} -> {p, div(net * s, sum)} end)
  end

  @doc "A best score as a percent of the 600 maximum — the lobby's progress bar."
  def progress_pct(best), do: Float.round(best / 600 * 100, 2)
end
