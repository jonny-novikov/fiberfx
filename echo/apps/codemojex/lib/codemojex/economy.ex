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

  @doc """
  Sealed top-K payout — the golden-close rule (V-15): the top `K` players by score
  each take a weight share of the `pool` (diamonds). `board` is `[{player, score}]`
  highest first; `split` is an ordered integer weight array (rank `i` takes
  `split[i] / Σ split_used`). When fewer than `length(split)` players are present,
  only the assigned ranks are paid and the share normalizes over the weights
  actually used. The integer-division remainder (the rounding dust) is added to
  rank 1 (the top scorer), so the **whole** pool is distributed — none is stranded.
  Pure: the same inputs always yield the same `[{player, diamonds}]`, so a re-run
  settlement pays identically.
  """
  def top_k_split(_pool, [], _split), do: []

  def top_k_split(pool, board, split) when is_list(split) do
    ranked = Enum.zip(board, split)
    sum = ranked |> Enum.map(fn {_row, w} -> w end) |> Enum.sum()

    if sum <= 0 do
      Enum.map(ranked, fn {{p, _s}, _w} -> {p, 0} end)
    else
      payouts = Enum.map(ranked, fn {{p, _s}, w} -> {p, div(pool * w, sum)} end)
      # the floor strands up to (paid_ranks - 1) diamonds; give the dust to rank 1
      # so the boosted golden pool drains entirely (purity preserved — deterministic).
      paid = payouts |> Enum.map(&elem(&1, 1)) |> Enum.sum()
      add_dust(payouts, pool - paid)
    end
  end

  # Add the integer-division remainder to the first (highest-ranked) payout.
  defp add_dust([], _dust), do: []
  defp add_dust(payouts, 0), do: payouts
  defp add_dust([{p, d} | rest], dust), do: [{p, d + dust} | rest]

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
