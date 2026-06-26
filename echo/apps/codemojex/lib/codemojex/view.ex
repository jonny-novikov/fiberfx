defmodule Codemojex.View do
  @moduledoc """
  The player-facing reads, with the privacy invariant built in: nothing here
  returns the secret, and nothing returns another player's guesses. The lobby
  lists the rooms; a game view carries the keyboard, timer, pool, and totals; a
  player sees only their own attempt history (from Postgres); the leaderboard is
  max scores, never guesses.

  For a golden game (`feedback="none"`) the privacy gate widens: before the game's
  `revealed_ms` is set, no score crosses the wire — the view withholds the totals,
  `my_history` withholds points, and the leaderboard withholds scores; only the
  published commitment, the state, and the timer are exposed. After reveal, the
  golden reads return the score like classic (the contest is over).
  """
  alias EchoWire.Cmd
  alias Codemojex.{Bus, Store, Cache, EmojiSet, Economy, Board, Wire}

  @doc "The lobby: every room as a card — prize (in USD), emoji count, cells, and the leader's progress."
  def lobby do
    for room <- Store.rooms() do
      set = Cache.fetch_set(room.emojiset)

      {prize, best} =
        case room.game do
          gid when is_binary(gid) ->
            r = Store.game(gid)
            {(r && r.prize_pool) || room.seed_pool, lobby_best(r, gid)}

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

  @doc "Everything a player may see about a game — never the secret; for a golden game, no score until reveal."
  def game_view(game) do
    case Store.game(game) do
      nil ->
        nil

      r ->
        set = Cache.fetch_set(r.emojiset)
        base =
          %{
            game: game,
            room: Map.get(r, :room),
            emojiset: set && EmojiSet.snapshot(set),
            ends_ms: r.ends_ms,
            prize_pool: r.prize_pool,
            prize_usd: Economy.to_usd(r.prize_pool),
            guess_fee: r.guess_fee,
            free: r.free,
            status: r.status
          }
          |> put_gather(game, r)

        if revealed?(r) do
          best = best_score(game)

          Map.put(base, :totals, %{
            players: total_players(game),
            attempts: total_attempts(game),
            best: best,
            best_pct: Economy.progress_pct(best)
          })
          |> put_commitment(r)
        else
          # blind, pre-reveal: state + timer + the commitment, no score
          Map.put(base, :totals, %{
            players: total_players(game),
            attempts: total_attempts(game)
          })
          |> put_commitment(r)
        end
    end
  end

  @doc "The player's own attempts (their guesses + scores), newest first — from Postgres. A golden game withholds points until reveal."
  def my_history(game, player, n \\ 50) do
    fields =
      case Store.game(game) do
        r when is_map(r) -> if revealed?(r), do: [:emojis, :points, :at_ms], else: [:emojis, :at_ms]
        _ -> [:emojis, :points, :at_ms]
      end

    game
    |> Store.guesses_for(player, n)
    |> Enum.map(&Map.take(&1, fields))
  end

  @doc "The leaderboard: `{player, max_score}` highest first — no guesses. A golden game returns nothing until reveal."
  def leaderboard(game, n \\ 10) do
    case Store.game(game) do
      r when is_map(r) ->
        if revealed?(r) do
          board_rows(game, n)
        else
          []
        end

      _ ->
        board_rows(game, n)
    end
  end

  def total_players(game), do: scard("cm:" <> game <> ":players")
  def total_attempts(game), do: get_int("cm:" <> game <> ":attempts")

  # A game's score is visible when it is not blind, or once it has revealed.
  defp revealed?(r) do
    Map.get(r, :feedback, "score") != "none" or not is_nil(Map.get(r, :revealed_ms))
  end

  # The live gather counter for a :gathering Golden Room (cm.5 R14): paid/threshold,
  # the paid count from the cheap Valkey :paid set hint. Absent for a started game.
  defp put_gather(view, game, %{status: :gathering} = r) do
    Map.put(view, :gather, %{
      paid: scard("cm:" <> game <> ":paid"),
      threshold: Map.get(r, :start_threshold)
    })
  end

  defp put_gather(view, _game, _r), do: view

  # The commitment is published from open for a golden game (so the player records
  # it for later verification); a classic game has none.
  defp put_commitment(view, r) do
    case Map.get(r, :commitment) do
      c when is_binary(c) -> Map.put(view, :commitment, c)
      _ -> view
    end
  end

  defp board_rows(game, n) do
    case Board.top(game, n) do
      {:ok, rows} -> rows
      _ -> []
    end
  end

  # The lobby leader's progress: hidden for a blind game in flight, else the best.
  defp lobby_best(r, gid) do
    if is_map(r) and not revealed?(r), do: 0, else: best_score(gid)
  end

  defp best_score(game) do
    case Board.top(game, 1) do
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
