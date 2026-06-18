defmodule Codemojex.View do
  @moduledoc """
  The player-facing reads, with the privacy invariant built in: nothing here
  returns the secret, and nothing returns another player's guesses. The lobby
  lists the rooms; a round view carries the keyboard, timer, pool, and totals; a
  player sees only their own attempt history (from Postgres); the leaderboard is
  max scores, never guesses.
  """
  alias EchoWire.Cmd
  alias Codemojex.{Bus, Store, Cache, EmojiSet, Economy, Board, Wire}

  @doc "The lobby: every room as a card — prize (in USD), emoji count, cells, and the leader's progress."
  def lobby do
    for room <- Store.rooms() do
      set = Cache.fetch_set(room.emojiset)

      {prize, best} =
        case room.round do
          rid when is_binary(rid) ->
            r = Store.round(rid)
            {(r && r.prize_pool) || room.seed_pool, best_score(rid)}

          _ ->
            {room.seed_pool, 0}
        end

      %{
        room: room.id,
        name: room.name,
        free: room.free,
        guess_fee: room.guess_fee,
        status: room.status,
        emoji_count: (set && length(set.codes)) || 0,
        cells: EmojiSet.code_length(),
        prize_pool: prize,
        prize_usd: Economy.to_usd(prize),
        progress_pct: Economy.progress_pct(best)
      }
    end
  end

  @doc "Everything a player may see about a round — never the secret."
  def round_view(round) do
    case Store.round(round) do
      nil ->
        nil

      r ->
        set = Cache.fetch_set(r.emojiset)
        best = best_score(round)

        %{
          round: round,
          room: Map.get(r, :room),
          emojiset: set && EmojiSet.snapshot(set),
          ends_ms: r.ends_ms,
          prize_pool: r.prize_pool,
          prize_usd: Economy.to_usd(r.prize_pool),
          guess_fee: r.guess_fee,
          free: r.free,
          status: r.status,
          totals: %{
            players: total_players(round),
            attempts: total_attempts(round),
            best: best,
            best_pct: Economy.progress_pct(best)
          }
        }
    end
  end

  @doc "The player's own attempts (their guesses + scores), newest first — from Postgres."
  def my_history(round, player, n \\ 50) do
    round
    |> Store.guesses_for(player, n)
    |> Enum.map(&Map.take(&1, [:emojis, :points, :percentage, :tier, :at_ms]))
  end

  @doc "The leaderboard: `{player, max_score}` highest first — no guesses."
  def leaderboard(round, n \\ 10) do
    case Board.top(round, n) do
      {:ok, rows} -> rows
      _ -> []
    end
  end

  def total_players(round), do: scard("cm:" <> round <> ":players")
  def total_attempts(round), do: get_int("cm:" <> round <> ":attempts")

  defp best_score(round) do
    case Board.top(round, 1) do
      {:ok, [{_p, s} | _]} -> s
      _ -> 0
    end
  end

  defp scard(key) do
    case Cmd.scard(key) |> Wire.run(Bus.conn()) do
      {:ok, n} when is_integer(n) -> n
      {:ok, n} when is_binary(n) -> String.to_integer(n)
      _ -> 0
    end
  end

  defp get_int(key) do
    case Cmd.get(key) |> Wire.run(Bus.conn()) do
      {:ok, nil} -> 0
      {:ok, v} -> String.to_integer(to_string(v))
      _ -> 0
    end
  end
end
