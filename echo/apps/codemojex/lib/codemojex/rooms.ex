defmodule Codemojex.Rooms do
  @moduledoc """
  Rooms are templates; a game is one play in a room. A room holds the props a game
  inherits — its emoji set, duration, seed prize pool (in diamonds), guess fee, and
  whether it is free — and at most one active game. The first player to join a
  waiting room starts a game: the room's emoji set and props are snapshotted, a
  `GAM` is minted with a fresh secret, and the timer begins. Later joiners enter
  the same game. On close a classic game pays winner-take-all to the max-score
  player; a golden game runs blind and pays the top scorers a sealed top-K split.
  The room then returns to waiting for the next game.
  """
  alias EchoWire.Cmd
  alias Codemojex.{Bus, Store, Cache, EmojiSet, Wallet, Economy, Board, Notifier, Wire}

  # The record separator joining the six secret codes before the nonce, in the
  # commit-reveal hash (V-14). Pinned so a client recomputes the commitment
  # identically: SHA-256 over `code₀ ‖ … ‖ code₅ ‖ nonce`, joined by US (0x1e).
  @rs <<0x1E>>

  @doc "Create a room (`ROM`) over an emoji set, in the waiting state."
  def create_room(name, %EmojiSet{} = set, opts \\ []) do
    :ok = Store.put_set(set)
    :ok = Cache.put_set(set)
    rom = EchoData.BrandedId.generate!("ROM")

    golden = Keyword.get(opts, :golden, false)

    room = %{
      name: name,
      emojiset: set.id,
      type: Keyword.get(opts, :type, if(golden, do: "golden", else: "classic")),
      duration_ms: Keyword.get(opts, :duration_ms, 35 * 3_600 * 1000),
      seed_pool: Keyword.get(opts, :seed_pool, 0),
      guess_fee: Keyword.get(opts, :guess_fee, 1),
      free: Keyword.get(opts, :free, false),
      clip_cost: Keyword.get(opts, :clip_cost, 1),
      # Golden Rooms: a platform-boosted class. A golden room defaults to a 3x
      # pool multiplier unless one is given; a normal room is 1x.
      golden: golden,
      gold_multiplier: Keyword.get(opts, :gold_multiplier, if(golden, do: 3, else: 1)),
      # the sealed top-K split policy (rank weights) and the reduced-set size N
      # (null = the full keyboard). Snapshotted onto the game at start.
      payout_split: Keyword.get(opts, :payout_split, [40, 25, 15, 12, 8]),
      cell_count: Keyword.get(opts, :cell_count),
      status: :waiting,
      game: nil
    }

    :ok = Store.put_room(rom, room)
    {:ok, rom}
  end

  @doc "Join a room: start its game if waiting, else enter the active one. Returns the `GAM`."
  def join_room(room_id, player) do
    case Store.room(room_id) do
      nil ->
        {:error, :no_room}

      %{status: :active, game: gid} = _room when is_binary(gid) ->
        add_player(gid, player)
        {:ok, gid}

      room ->
        start_game(room_id, room, player)
    end
  end

  defp start_game(room_id, room, player) do
    case Cache.fetch_set(room.emojiset) do
      %EmojiSet{} = set ->
        gid = EchoData.BrandedId.generate!("GAM")
        now = System.system_time(:millisecond)
        type = Map.get(room, :type, "classic")
        policy = policies_for(type)

        # The game snapshots a keyboard: the full set for a classic room, a fresh
        # randomized N-cell subset when the room sets `cell_count` (a reduced
        # golden contest). The secret is drawn from THIS snapshot, so the keyboard
        # the player taps and the secret they chase index the same cells.
        cell_codes = snapshot_cells(set, Map.get(room, :cell_count))
        secret = EmojiSet.secret_from(cell_codes)

        game =
          %{
            room: room_id,
            emojiset: set.id,
            type: type,
            feedback: policy.feedback,
            scoring: policy.scoring,
            settlement: policy.settlement,
            economy: policy.economy,
            secret: secret,
            cell_codes: cell_codes,
            started_ms: now,
            ends_ms: now + room.duration_ms,
            # the prize pool is diamonds, seeded by the platform to promote play
            prize_pool: room.seed_pool,
            guess_fee: room.guess_fee,
            free: room.free,
            clip_cost: room.clip_cost,
            # the sealed-split policy + breadth are snapshotted, so a game in
            # flight settles by the split it was created under
            payout_split: Map.get(room, :payout_split, [40, 25, 15, 12, 8]),
            top_k: 5,
            # Golden Rooms props are snapshotted, so a game in flight is unaffected
            # by a later edit to its room.
            golden: Map.get(room, :golden, false),
            gold_multiplier: Map.get(room, :gold_multiplier, 1),
            status: :open
          }
          |> seal_commitment(type, secret)

        :ok = Store.put_game(gid, game)
        :ok = Cache.put_game(gid, game)
        :ok = Store.put_room(room_id, %{room | status: :active, game: gid})
        add_player(gid, player)
        {:ok, gid}

      _ ->
        {:error, :no_set}
    end
  end

  # The type→policy lookup: for the two launch types the four policies are a pure
  # function of the type, so they are derived in code and snapshotted onto the
  # game (a game stays self-describing for settlement and replay).
  defp policies_for("golden"),
    do: %{feedback: "none", scoring: "linear", settlement: "sealed", economy: "winner_take_all"}

  defp policies_for(_classic),
    do: %{feedback: "score", scoring: "linear", settlement: "live", economy: "winner_take_all"}

  # The reduced-set snapshot: the full keyboard when no `cell_count`, else a fresh
  # random N-cell subset of the room's keyboard (V-16a).
  defp snapshot_cells(%EmojiSet{codes: codes}, nil), do: codes
  defp snapshot_cells(%EmojiSet{codes: codes}, n) when is_integer(n) and n > 0,
    do: Enum.take_random(codes, min(n, length(codes)))

  defp snapshot_cells(%EmojiSet{codes: codes}, _), do: codes

  # Commit-reveal (V-14): a golden game draws a nonce and binds the secret with a
  # SHA-256 commitment over `code₀ ‖ … ‖ code₅ ‖ nonce` (lowercase hex). The
  # `secret` and `nonce` stay server-side until reveal; the commitment may be
  # published at open. A classic game writes neither (the columns stay NULL).
  defp seal_commitment(game, "golden", secret) do
    nonce = mint_nonce()
    Map.merge(game, %{nonce: nonce, commitment: commit(secret, nonce)})
  end

  defp seal_commitment(game, _type, _secret), do: game

  @doc false
  def commit(secret, nonce) when is_list(secret) and is_binary(nonce) do
    payload = Enum.join(secret, @rs) <> @rs <> nonce
    :crypto.hash(:sha256, payload) |> Base.encode16(case: :lower)
  end

  defp mint_nonce, do: :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)

  defp add_player(game, player),
    do: Cmd.sadd("cm:" <> game <> ":players", player) |> Wire.run(Bus.conn())

  @doc """
  Close a game. A classic game pays the pool winner-take-all (diamonds) to the
  max-score player; a golden game reveals the secret, ranks every guess linearly,
  and pays the top-K a sealed split — both inside one exactly-once close. Marks the
  game settled, bumps the global total-won counter, and returns the room to
  waiting. Triggered by a perfect score (classic) or an expired timer.
  """
  def close_game(game) do
    case Store.game(game) do
      nil ->
        {:error, :no_game}

      %{status: :settled} ->
        {:ok, :already_closed}

      r ->
        # Exactly-once payout: only the closer that wins this atomic SET NX pays.
        # A perfect-crack close and a timer close can race; the loser is a no-op.
        case Cmd.set("cm:" <> game <> ":closed") |> Cmd.value("1") |> Cmd.nx() |> Wire.run(Bus.conn()) do
          {:ok, "OK"} -> do_close(game, r)
          _ -> {:ok, :already_closed}
        end
    end
  end

  defp do_close(game, r) do
    case Map.get(r, :settlement, "live") do
      "sealed" -> close_sealed(game, r)
      _ -> close_live(game, r)
    end
  end

  # Classic (live) settlement — winner-take-all over the (boosted) pool, unchanged.
  defp close_live(game, r) do
    golden = Map.get(r, :golden, false)
    mult = Map.get(r, :gold_multiplier, 1)
    pool = Economy.effective_pool(Map.get(r, :prize_pool, 0), golden, mult)

    {:ok, board} = Board.top(game, 10)
    payouts = Economy.winner_take_all(pool, board)

    Enum.each(payouts, fn {winner, diamonds} ->
      if diamonds > 0 do
        Wallet.deposit_prize(winner, diamonds, game)
        notify_winner(winner, game, diamonds, golden, mult)
      end
    end)

    total = payouts |> Enum.map(&elem(&1, 1)) |> Enum.sum()
    if total > 0, do: Cmd.incrby("cm:total_won", total) |> Wire.run(Bus.conn())
    if golden, do: announce_golden(game, payouts, mult)
    :ok = Store.put_game(game, Map.put(r, :status, :settled))
    reset_room(r)
    {:ok, payouts}
  end

  # Blind (sealed) settlement — the golden path. Reveal the secret+nonce, rank
  # every guess linearly, pay the top-K each its `payout_split` weight share of the
  # boosted pool, emit ONE fat `revealed` event, then settle. The same `SET NX`
  # one-shot guards it, so a re-run pays identically.
  defp close_sealed(game, r) do
    golden = Map.get(r, :golden, false)
    mult = Map.get(r, :gold_multiplier, 1)
    pool = Economy.effective_pool(Map.get(r, :prize_pool, 0), golden, mult)
    revealed_ms = System.system_time(:millisecond)

    # revealing: expose secret+nonce, set revealed_ms (the privacy gate opens)
    r = Map.merge(r, %{status: :revealing, revealed_ms: revealed_ms})
    :ok = Store.put_game(game, r)
    :ok = Cache.put_game(game, r)

    # settling: rank by best linear points, pay the top-K split
    {:ok, board} = Board.top(game, Map.get(r, :top_k, 5))
    payouts = Economy.top_k_split(pool, board, Map.get(r, :payout_split, [40, 25, 15, 12, 8]))

    Enum.each(payouts, fn {winner, diamonds} ->
      if diamonds > 0 do
        Wallet.deposit_prize(winner, diamonds, game)
        notify_winner(winner, game, diamonds, golden, mult)
      end
    end)

    total = payouts |> Enum.map(&elem(&1, 1)) |> Enum.sum()
    if total > 0, do: Cmd.incrby("cm:total_won", total) |> Wire.run(Bus.conn())

    settled = Map.put(r, :status, :settled)
    :ok = Store.put_game(game, settled)
    :ok = Cache.put_game(game, settled)
    broadcast_revealed(game, settled, board, payouts)
    reset_room(r)
    {:ok, payouts}
  end

  # A prize win reaches the player through the notification system (echo_bot),
  # addressed by the chat the player registered; a golden win carries the boost.
  defp notify_winner(winner, game, diamonds, golden, mult) do
    case Store.chat_of(winner) do
      nil -> :ok
      chat when golden -> Notifier.golden_win(chat, game, diamonds, mult)
      chat -> Notifier.prize_won(chat, game, diamonds)
    end
  end

  # A golden close is also a live, room-wide moment on the game's channel.
  defp announce_golden(game, payouts, mult) do
    won = payouts |> Enum.map(&elem(&1, 1)) |> Enum.sum()

    Phoenix.PubSub.broadcast(
      Codemojex.PubSub,
      "game:" <> game,
      {:golden_win, %{game: game, diamonds: won, multiplier: mult}}
    )
  end

  # The ONE fat `revealed` event (V-13): the first and only results a blind client
  # receives — the now-exposed secret + nonce + commitment, the final board, the
  # top-K payouts, and the terminal state. The preimage was sealed until this point.
  defp broadcast_revealed(game, settled, board, payouts) do
    Phoenix.PubSub.broadcast(
      Codemojex.PubSub,
      "game:" <> game,
      {:revealed,
       %{
         game: game,
         secret: Map.get(settled, :secret),
         nonce: Map.get(settled, :nonce),
         commitment: Map.get(settled, :commitment),
         board: Enum.map(board, fn {p, s} -> %{player: p, score: s} end),
         payouts: Enum.map(payouts, fn {p, d} -> %{player: p, diamonds: d} end),
         state: Map.get(settled, :status)
       }}
    )
  end

  @doc "Close the game only if its timer has expired (a sweep calls this)."
  def close_if_expired(game) do
    now = System.system_time(:millisecond)

    case Store.game(game) do
      %{status: :open, ends_ms: e} when now >= e -> close_game(game)
      _ -> {:ok, :not_yet}
    end
  end

  defp reset_room(r) do
    with room_id when is_binary(room_id) <- Map.get(r, :room),
         room when is_map(room) <- Store.room(room_id) do
      Store.put_room(room_id, %{room | status: :waiting, game: nil})
    else
      _ -> :ok
    end
  end
end
