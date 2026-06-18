defmodule Codemojex.Scoring do
  @moduledoc """
  The Linear scoring engine, pure. A secret is six unique emojis in positions
  0..5; a guess is six emojis. Each guessed emoji that exists in the secret earns
  points by how far it sits from its secret position — `points = 100 - 20*d` for
  distance `d` in 0..5, zero for a miss — and the total over six positions, out of
  600, is the round's percentage. The tier is the total in 20-point steps (0..30).
  No process, no bus: the score worker calls this once a guess arrives, and the
  same secret and guess always yield the same score, so a re-delivered guess
  re-scores identically.
  """

  @max 600

  @doc "Points for a position at distance `d` (0..5); a miss is `:miss`."
  def points(:miss), do: 0
  def points(d) when is_integer(d) and d >= 0 and d <= 5, do: 100 - 20 * d
  def points(_), do: 0

  @doc "Distance between a guess position and a secret position."
  def distance(guess_pos, secret_pos), do: abs(guess_pos - secret_pos)

  @doc "The status word the rules table uses for a distance (or a miss)."
  def status(:miss), do: "MISS"
  def status(0), do: "EXACT"
  def status(1), do: "ADJACENT"
  def status(d) when d in [2, 3], do: "NEAR"
  def status(4), do: "FAR"
  def status(5), do: "MAX"

  @doc "The tier a total lands in: the total in 20-point steps, 0..30."
  def tier(total) when is_integer(total), do: div(total, 20)

  @doc """
  Score one guess against a secret. Returns the total, the percentage out of 600,
  the tier, and a per-position breakdown `{pos, guess_emoji, distance|:miss, points,
  status}`.
  """
  def score(secret, guess) when length(secret) == 6 and length(guess) == 6 do
    breakdown =
      for {emoji, i} <- Enum.with_index(guess) do
        case Enum.find_index(secret, &(&1 == emoji)) do
          nil -> {i, emoji, :miss, 0, status(:miss)}
          j ->
            d = distance(i, j)
            {i, emoji, d, points(d), status(d)}
        end
      end

    total = breakdown |> Enum.map(&elem(&1, 3)) |> Enum.sum()

    %{
      total: total,
      max: @max,
      percentage: round(total / @max * 100),
      tier: tier(total),
      breakdown: breakdown
    }
  end

  @doc "The full distance→points scale as `{distance, points, status}` rows."
  def scale, do: for(d <- 0..5, do: {d, points(d), status(d)})
end
