defmodule Codemoji.Locks do
  @moduledoc """
  Position locking, in Valkey. A player sure of a position locks it; the lock is
  one field in a per-player hash for the round (`cm:{round}:lock:{player}`, field =
  position, value = code), so it persists across guesses with no client state to
  lose. `merge/3` overlays a player's locks onto a submitted guess — a locked
  position is guaranteed regardless of what the keyboard sent — which is the rules'
  "locked positions persist across guesses", made server-side and durable.
  """
  alias EchoMQ.Connector
  alias Codemoji.Bus

  defp k(round, player), do: "cm:" <> round <> ":lock:" <> player

  @doc "Lock `code` at `pos` (0..5) for this player in this round."
  def lock(round, player, pos, code) when pos in 0..5,
    do: Connector.command(Bus.conn(), ["HSET", k(round, player), to_string(pos), to_string(code)])

  @doc "Release a locked position."
  def unlock(round, player, pos) when pos in 0..5,
    do: Connector.command(Bus.conn(), ["HDEL", k(round, player), to_string(pos)])

  @doc "The player's locked positions as `%{pos => code}`."
  def locked(round, player) do
    case Connector.command(Bus.conn(), ["HGETALL", k(round, player)]) do
      {:ok, m} when is_map(m) -> to_pos_map(Enum.to_list(m))
      {:ok, flat} when is_list(flat) -> flat |> Enum.chunk_every(2) |> to_pos_map()
      _ -> %{}
    end
  end

  @doc "Overlay the player's locks onto a guess; locks win at their positions."
  def merge(round, player, guess) do
    locks = locked(round, player)
    guess |> Enum.with_index() |> Enum.map(fn {code, i} -> Map.get(locks, i, code) end)
  end

  defp to_pos_map(pairs) do
    Map.new(pairs, fn [p, c] -> {String.to_integer(to_string(p)), String.to_integer(to_string(c))} end)
  end
end
