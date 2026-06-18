defmodule Codemoji.Rooms do
  @moduledoc """
  Rooms are templates; a round is a game in a room. A room holds the props a round
  inherits — its emoji set, duration, seed prize pool (in diamonds), guess fee, and
  whether it is free — and at most one active round. The first player to join a
  waiting room starts a round: the room's emoji set and props are snapshotted, an
  `RND` is minted with a fresh secret, and the timer begins. Later joiners enter
  the same round. On close the pool goes winner-take-all to the max-score player
  and the room returns to waiting for the next round.
  """
  alias EchoMQ.Connector
  alias Codemoji.{Bus, Store, Cache, EmojiSet, Wallet, Economy, Board}

  @doc "Create a room (`RMM`) over an emoji set, in the waiting state."
  def create_room(name, %EmojiSet{} = set, opts \\ []) do
    :ok = Store.put_set(set)
    :ok = Cache.put_set(set)
    rmm = EchoData.BrandedId.generate!("RMM")

    room = %{
      name: name,
      emojiset: set.id,
      duration_ms: Keyword.get(opts, :duration_ms, 35 * 3_600 * 1000),
      seed_pool: Keyword.get(opts, :seed_pool, 0),
      guess_fee: Keyword.get(opts, :guess_fee, 1),
      free: Keyword.get(opts, :free, false),
      clip_cost: Keyword.get(opts, :clip_cost, 1),
      status: :waiting,
      round: nil
    }

    :ok = Store.put_room(rmm, room)
    {:ok, rmm}
  end

  @doc "Join a room: start its round if waiting, else enter the active one. Returns the `RND`."
  def join_room(room_id, player) do
    case Store.room(room_id) do
      nil ->
        {:error, :no_room}

      %{status: :active, round: rid} = _room when is_binary(rid) ->
        add_player(rid, player)
        {:ok, rid}

      room ->
        start_round(room_id, room, player)
    end
  end

  defp start_round(room_id, room, player) do
    case Cache.fetch_set(room.emojiset) do
      %EmojiSet{} = set ->
        rid = EchoData.BrandedId.generate!("RND")
        now = System.system_time(:millisecond)

        round = %{
          room: room_id,
          emojiset: set.id,
          secret: EmojiSet.secret(set),
          started_ms: now,
          ends_ms: now + room.duration_ms,
          # the prize pool is diamonds, seeded by the platform to promote play
          prize_pool: room.seed_pool,
          guess_fee: room.guess_fee,
          free: room.free,
          clip_cost: room.clip_cost,
          status: :open
        }

        :ok = Store.put_round(rid, round)
        :ok = Cache.put_round(rid, round)
        :ok = Store.put_room(room_id, %{room | status: :active, round: rid})
        add_player(rid, player)
        {:ok, rid}

      _ ->
        {:error, :no_set}
    end
  end

  defp add_player(round, player),
    do: Connector.command(Bus.conn(), ["SADD", "cm:" <> round <> ":players", player])

  @doc """
  Close a round: pay the pool winner-take-all (diamonds) to the max-score player,
  mark the round closed, bump the global total-won counter, and return the room to
  waiting. Triggered by a perfect score or an expired timer.
  """
  def close_round(round) do
    case Store.round(round) do
      nil ->
        {:error, :no_round}

      %{status: :closed} ->
        {:ok, :already_closed}

      r ->
        # Exactly-once payout: only the closer that wins this atomic SET NX pays.
        # A perfect-crack close and a timer close can race; the loser is a no-op.
        case Connector.command(Bus.conn(), ["SET", "cm:" <> round <> ":closed", "1", "NX"]) do
          {:ok, "OK"} -> do_close(round, r)
          _ -> {:ok, :already_closed}
        end
    end
  end

  defp do_close(round, r) do
    {:ok, board} = Board.top(round, 10)
    payouts = Economy.winner_take_all(Map.get(r, :prize_pool, 0), board)

    Enum.each(payouts, fn {winner, diamonds} ->
      if diamonds > 0, do: Wallet.deposit_prize(winner, diamonds, round)
    end)

    total = payouts |> Enum.map(&elem(&1, 1)) |> Enum.sum()
    if total > 0, do: Connector.command(Bus.conn(), ["INCRBY", "cm:total_won", to_string(total)])
    :ok = Store.put_round(round, Map.put(r, :status, :closed))
    reset_room(r)
    {:ok, payouts}
  end

  @doc "Close the round only if its timer has expired (a sweep calls this)."
  def close_if_expired(round) do
    now = System.system_time(:millisecond)

    case Store.round(round) do
      %{status: :open, ends_ms: e} when now >= e -> close_round(round)
      _ -> {:ok, :not_yet}
    end
  end

  defp reset_room(r) do
    with room_id when is_binary(room_id) <- Map.get(r, :room),
         room when is_map(room) <- Store.room(room_id) do
      Store.put_room(room_id, %{room | status: :waiting, round: nil})
    else
      _ -> :ok
    end
  end
end
