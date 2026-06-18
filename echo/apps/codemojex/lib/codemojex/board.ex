defmodule Codemojex.Board do
  @moduledoc """
  The competitive state, in Valkey. The leaderboard is one sorted set per round;
  a player's score on it is their best base total plus their accumulated
  first-mover tier bonuses. First-mover is an `HSETNX` race: the first id to claim
  a tier wins it atomically, server-side, with no read-modify-write. A guess that
  reaches tier T claims every still-unclaimed tier above the player's previous
  best — at most +1 per tier, up to +30 over a round.
  """
  alias EchoWire.Cmd
  alias Codemojex.{Bus, Wire}

  defp k(round, suffix), do: "cm:" <> round <> ":" <> suffix

  @doc "Record a scored guess. Returns {effective_score, tiers_claimed_now, total_bonus}."
  def record(round, player, base, tier) do
    conn = Bus.conn()

    old = hget_int(conn, k(round, "base"), player)
    new_base = max(old, base)
    Cmd.hset(k(round, "base"), player, to_string(new_base)) |> Wire.run(conn)

    prev = hget_int(conn, k(round, "ptier"), player, -1)

    claimed =
      Enum.count((prev + 1)..tier//1, fn t -> t > 0 and claim_tier(conn, round, t, player) end)

    if tier > prev, do: Cmd.hset(k(round, "ptier"), player, to_string(tier)) |> Wire.run(conn)

    bonus =
      if claimed > 0 do
        {:ok, b} = Cmd.hincrby(k(round, "bonus"), player, claimed) |> Wire.run(conn)
        to_int(b)
      else
        hget_int(conn, k(round, "bonus"), player)
      end

    eff = new_base + bonus
    Cmd.zadd(k(round, "board")) |> Cmd.score(eff, player) |> Wire.run(conn)
    {eff, claimed, bonus}
  end

  defp claim_tier(conn, round, t, player) do
    case Cmd.hsetnx(k(round, "tierfirst"), to_string(t), player) |> Wire.run(conn) do
      {:ok, 1} -> true
      {:ok, "1"} -> true
      _ -> false
    end
  end

  @doc "Top `n`, highest first: {player_id, effective_score}."
  def top(round, n \\ 10) do
    case Cmd.zrevrange(k(round, "board"), 0, n - 1) |> Cmd.withscores() |> Wire.run(Bus.conn()) do
      {:ok, flat} -> {:ok, parse(flat)}
      other -> other
    end
  end

  @doc "How many tiers this player was first to reach."
  def firsts(round, player) do
    case Cmd.hvals(k(round, "tierfirst")) |> Wire.run(Bus.conn()) do
      {:ok, vals} -> Enum.count(vals, &(&1 == player))
      _ -> 0
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
