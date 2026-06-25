defmodule Codemojex.Board do
  @moduledoc """
  The competitive state, in Valkey. The leaderboard is one sorted set per game;
  a player's score on it is their best linear total. A guess updates the player's
  best base and writes it straight to the board — no tier ladder, no first-mover
  bonus: the raw linear score is the sole rank. Server-side, with no read-modify-
  write beyond the best-of fold.
  """
  alias EchoWire.Cmd
  alias Codemojex.{Bus, Wire}

  defp k(game, suffix), do: "cm:" <> game <> ":" <> suffix

  @doc "Record a scored guess. Returns the player's best linear total (the board rank)."
  def record(game, player, base) do
    conn = Bus.conn()

    old = hget_int(conn, k(game, "base"), player)
    new_base = max(old, base)
    Cmd.hset(k(game, "base"), player, to_string(new_base)) |> Wire.run(conn)
    Cmd.zadd(k(game, "board")) |> Cmd.score(new_base, player) |> Wire.run(conn)
    new_base
  end

  @doc "Top `n`, highest first: {player_id, score}."
  def top(game, n \\ 10) do
    case Cmd.zrevrange(k(game, "board"), 0, n - 1) |> Cmd.withscores() |> Wire.run(Bus.conn()) do
      {:ok, flat} -> {:ok, parse(flat)}
      other -> other
    end
  end

  defp hget_int(conn, key, field, default \\ 0) do
    case Cmd.hget(key, field) |> Wire.run(conn) do
      {:ok, nil} -> default
      {:ok, v} -> to_int(v)
      _ -> default
    end
  end

  defp to_int(v) when is_integer(v), do: v
  defp to_int(v) when is_float(v), do: trunc(v)
  defp to_int(v) when is_binary(v) do
    case Integer.parse(v) do
      {i, _} -> i
      _ -> 0
    end
  end

  defp to_int(_), do: 0

  defp parse([]), do: []
  defp parse([h | _] = l) when is_list(h), do: Enum.map(l, fn [m, s] -> {m, to_int(s)} end)
  defp parse(l), do: l |> Enum.chunk_every(2) |> Enum.map(fn [m, s] -> {m, to_int(s)} end)
end
