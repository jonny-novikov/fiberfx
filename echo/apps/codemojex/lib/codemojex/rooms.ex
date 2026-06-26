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
      # `golden:true` is a TOURNAMENT marker, orthogonal to the type — a Golden Room
      # is type:"classic" (it fans out live); the blind mode is reached ONLY by an
      # explicit type:"golden" (cm.5 R12).
      type: Keyword.get(opts, :type, "classic"),
      duration_ms: Keyword.get(opts, :duration_ms, 35 * 3_600 * 1000),
      seed_pool: Keyword.get(opts, :seed_pool, 0),
      guess_fee: Keyword.get(opts, :guess_fee, 1),
      free: Keyword.get(opts, :free, false),
      clip_cost: Keyword.get(opts, :clip_cost, 1),
      golden: golden,
      # the sealed top-K split policy (rank weights) and the reduced-set size N
      # (null = the full keyboard). Snapshotted onto the game at start.
      payout_split: Keyword.get(opts, :payout_split, [40, 25, 15, 12, 8]),
      cell_count: Keyword.get(opts, :cell_count),
      # the Golden Room tournament levers (cm.5 D-7), snapshotted to the game at
      # start. nil for an ordinary room; create_golden_room defaults start_threshold.
      start_threshold: Keyword.get(opts, :start_threshold),
      entry_fee_keys: Keyword.get(opts, :entry_fee_keys),
      virtual_deposit: Keyword.get(opts, :virtual_deposit),
      first_movers: Keyword.get(opts, :first_movers),
      entry_fee_revenue_percentage: Keyword.get(opts, :entry_fee_revenue_percentage),
      room_deadline: Keyword.get(opts, :room_deadline),
      status: :waiting,
      game: nil
    }

    # the room changeset enforces buy_in ⇒ not free (cm.5 R11, INV-NOTFREE); an
    # invalid room surfaces the changeset error rather than minting an unwritable ROM.
    case Store.put_room(rom, room) do
      :ok -> {:ok, rom}
      {:error, _changeset} = err -> err
    end
  end

  @doc """
  Join a room: start its game if waiting, else enter the active one. For a Golden
  Room the join is the entry-fee buy-in (charged exactly-once); when the paid-member
  count reaches `start_threshold` the gather arms the timer (`:gathering → :open`).
  Returns the `GAM`.
  """
  def join_room(room_id, player) do
    case Store.room(room_id) do
      nil ->
        {:error, :no_room}

      %{status: :active, game: gid} = room when is_binary(gid) ->
        case enter_or_buy_in(gid, room, player, Map.get(room, :golden, false)) do
          {:error, reason} -> {:error, reason}
          _ -> {:ok, gid}
        end

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
        golden = Map.get(room, :golden, false)
        policy = policies_for(type, golden)

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
            guess_fee: room.guess_fee,
            free: room.free,
            clip_cost: room.clip_cost,
            # the sealed-split policy + breadth are snapshotted, so a game in
            # flight settles by the split it was created under
            payout_split: Map.get(room, :payout_split, [40, 25, 15, 12, 8]),
            top_k: 5,
            # Golden Rooms props are snapshotted, so a game in flight is unaffected
            # by a later edit to its room.
            golden: golden,
            # the D-7 tournament levers, snapshotted (cm.5 INV-SNAPSHOT)
            start_threshold: Map.get(room, :start_threshold),
            entry_fee_keys: Map.get(room, :entry_fee_keys),
            virtual_deposit: Map.get(room, :virtual_deposit),
            first_movers: Map.get(room, :first_movers),
            entry_fee_revenue_percentage: Map.get(room, :entry_fee_revenue_percentage),
            room_deadline: Map.get(room, :room_deadline)
          }
          |> Map.merge(formation(room, now, golden))
          |> seal_commitment(type, secret)

        :ok = Store.put_game(gid, game)
        :ok = Cache.put_game(gid, game)
        :ok = Store.put_room(room_id, %{room | status: :active, game: gid})
        # the joining player is the FIRST member: for a Golden Room this is the
        # buy-in (charged here, exactly-once); a non-golden game just enters.
        case enter_or_buy_in(gid, room, player, golden) do
          {:error, reason} -> {:error, reason}
          _ -> {:ok, gid}
        end

      _ ->
        {:error, :no_set}
    end
  end

  # The (type, golden)→policy lookup: the four policies are a pure function of the
  # type and the tournament marker, derived in code and snapshotted onto the game (a
  # game stays self-describing for settlement and replay).
  #
  #   * type "golden"            → blind/sealed top-K (the commit-reveal mode), any flag;
  #   * type "classic", golden   → the live top-K tournament (cm.5 R6: live_split /
  #                                proportional — "proportional" LABELS top_k_split,
  #                                a rank-weighted split, not Economy.proportional/2);
  #   * type "classic", ordinary → live winner-take-all.
  defp policies_for("golden", _golden),
    do: %{feedback: "none", scoring: "linear", settlement: "sealed", economy: "winner_take_all"}

  defp policies_for(_classic, true),
    do: %{feedback: "score", scoring: "linear", settlement: "live_split", economy: "proportional"}

  defp policies_for(_classic, _ordinary),
    do: %{feedback: "score", scoring: "linear", settlement: "live", economy: "winner_take_all"}

  # The formation fork (cm.5 R1): a Golden Room (classic+golden:true) forms in
  # :gathering — the timer is not yet armed (ends_ms nil), and the pool is seeded
  # with the platform's virtual_deposit (💎). A non-golden game opens immediately
  # with the live timer (now + duration_ms) and the ordinary seed_pool.
  defp formation(room, _now, true),
    do: %{
      status: :gathering,
      ends_ms: nil,
      prize_pool: Map.get(room, :virtual_deposit) || room.seed_pool
    }

  defp formation(room, now, _ordinary),
    do: %{status: :open, ends_ms: now + room.duration_ms, prize_pool: room.seed_pool}

  # Enter the game as a member. A Golden Room entry is the buy-in (charged
  # exactly-once via Wallet.buy_in); on success the player joins the players set, is
  # recorded in the paid-set hint, and the gather is re-checked (the Nth paid member
  # arms the timer). A non-golden game is a plain join. A buy-in error (insufficient
  # keys, etc.) is surfaced and NO membership is recorded.
  defp enter_or_buy_in(gid, room, player, true) do
    case Wallet.buy_in(player, gid) do
      {:ok, _} ->
        add_player(gid, player)
        # the fast-path paid-set hint + the gather counter (the buy_in TXN ledger is
        # the authority — this is a HINT, L-10). SADD is idempotent on a re-join.
        Cmd.sadd("cm:" <> gid <> ":paid", player) |> Wire.run(Bus.conn())
        arm_if_gathered(gid, room)
        {:ok, gid}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp enter_or_buy_in(gid, _room, player, _ordinary) do
    add_player(gid, player)
    {:ok, gid}
  end

  # The gather gate (cm.5 R5, INV-START-ONCE): when the ledger-authoritative paid
  # count reaches start_threshold and the game is still :gathering, arm the timer
  # under a single SET cm:<game>:started NX — the winner sets :open and
  # ends_ms = room_deadline (the fixed event end); every concurrent loser is a no-op.
  # The count is the buy_in TXN count (re-derivable across a Valkey flush); the
  # games-row FOR UPDATE in buy_in already serialized it, so NX is belt-and-suspenders.
  defp arm_if_gathered(gid, room) do
    threshold = Map.get(room, :start_threshold)

    with t when is_integer(t) <- threshold,
         %{status: :gathering, room_deadline: deadline} = g when not is_nil(deadline) <-
           Store.game(gid),
         true <- Store.paid_count(gid) >= t,
         {:ok, "OK"} <-
           Cmd.set("cm:" <> gid <> ":started") |> Cmd.value("1") |> Cmd.nx() |> Wire.run(Bus.conn()) do
      ends_ms = DateTime.to_unix(deadline, :millisecond)
      armed = %{g | status: :open, ends_ms: ends_ms}
      :ok = Store.put_game(gid, armed)
      :ok = Cache.put_game(gid, armed)
      {:ok, :armed}
    else
      _ -> {:ok, :gathering}
    end
  end

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
      "live_split" -> close_split(game, r)
      _ -> close_live(game, r)
    end
  end

  # Classic (live) settlement — winner-take-all over the pool, unchanged.
  defp close_live(game, r) do
    golden = Map.get(r, :golden, false)
    pool = Map.get(r, :prize_pool, 0)

    {:ok, board} = Board.top(game, 10)
    payouts = Economy.winner_take_all(pool, board)

    Enum.each(payouts, fn {winner, diamonds} ->
      if diamonds > 0 do
        Wallet.deposit_prize(winner, diamonds, game)
        notify_winner(winner, game, diamonds, golden)
      end
    end)

    total = payouts |> Enum.map(&elem(&1, 1)) |> Enum.sum()
    if total > 0, do: Cmd.incrby("cm:total_won", total) |> Wire.run(Bus.conn())
    if golden, do: announce_golden(game, payouts)
    :ok = Store.put_game(game, Map.put(r, :status, :settled))
    reset_room(r)
    {:ok, payouts}
  end

  # Live top-K settlement — the Golden Room tournament close (cm.5 R6). It MIRRORS
  # close_live's shape: a Store-only settle + the {:golden_win} fan-out — NOT
  # close_sealed (no Cache.put_game, no :revealing, no {:revealed} — INV-NO-REVEAL).
  # The whole prize_pool (the running holding record: virtual_deposit + first-mover
  # credits + guess credits) drains to the top-K proportionally; every other member
  # takes a consolation clip. The distribution is ONE Repo.transaction (R-HOLD).
  defp close_split(game, r) do
    pool = Map.get(r, :prize_pool, 0)
    split = Map.get(r, :payout_split, [40, 25, 15, 12, 8])
    members = Store.members(game)

    # read the board wide enough to cover every member (so consolation reaches all)
    {:ok, board} = Board.top(game, max(length(split), length(members)))
    payouts = Economy.top_k_split(pool, board, split)
    paid_ids = MapSet.new(payouts, fn {p, _} -> p end)

    # consolation: every member NOT in the top-K split gets max_score/10 clips; a
    # member who paid but never scored is 0 → 0 clips (INV-EVERY-MEMBER-PAID).
    scores = Map.new(board)

    consolation =
      members
      |> Enum.reject(&MapSet.member?(paid_ids, &1))
      |> Enum.map(fn p -> {p, div(Map.get(scores, p, 0), 10)} end)

    {:ok, _} = Wallet.distribute_pool(game, payouts, consolation)

    total = payouts |> Enum.map(&elem(&1, 1)) |> Enum.sum()
    if total > 0, do: Cmd.incrby("cm:total_won", total) |> Wire.run(Bus.conn())
    announce_golden(game, payouts)
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
    pool = Map.get(r, :prize_pool, 0)
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
        notify_winner(winner, game, diamonds, golden)
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
  # addressed by the chat the player registered; a golden win is announced as one.
  defp notify_winner(winner, game, diamonds, golden) do
    case Store.chat_of(winner) do
      nil -> :ok
      chat when golden -> Notifier.golden_win(chat, game, diamonds)
      chat -> Notifier.prize_won(chat, game, diamonds)
    end
  end

  # A golden close is also a live, room-wide moment on the game's channel.
  defp announce_golden(game, payouts) do
    won = payouts |> Enum.map(&elem(&1, 1)) |> Enum.sum()

    Phoenix.PubSub.broadcast(
      Codemojex.PubSub,
      "game:" <> game,
      {:golden_win, %{game: game, diamonds: won}}
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
      %{status: :open, ends_ms: e} when is_integer(e) and now >= e -> close_game(game)
      _ -> {:ok, :not_yet}
    end
  end

  @doc """
  Void the game only if it is still gathering past its `room_deadline` (a sweep
  calls this). A never-fills Golden Room is non-refundable (cm.5 R8 / D-7): the
  field simply voids, the platform keeps the collected fees and reclaims the unpaid
  virtual deposit. No player money moves.
  """
  def void_if_stale(game) do
    now = DateTime.utc_now()

    case Store.game(game) do
      %{status: :gathering, room_deadline: %DateTime{} = deadline} = r ->
        if DateTime.compare(now, deadline) != :lt, do: close_void(game, r), else: {:ok, :not_yet}

      _ ->
        {:ok, :not_yet}
    end
  end

  # The never-fills void (cm.5 R8, INV-NO-REFUND): under the SET cm:<game>:closed NX
  # close lock, transition :gathering → :voided and reset the room. NO refund, no
  # money moves — the close lock alone is the exactly-once guard (no per-player loop).
  defp close_void(game, r) do
    case Cmd.set("cm:" <> game <> ":closed") |> Cmd.value("1") |> Cmd.nx() |> Wire.run(Bus.conn()) do
      {:ok, "OK"} ->
        :ok = Store.put_game(game, Map.put(r, :status, :voided))
        reset_room(r)
        {:ok, :voided}

      _ ->
        {:ok, :already_closed}
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
