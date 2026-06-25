defmodule Codemojex.Guesses do
  @moduledoc """
  The play API. A guess is validated against the game's keyboard, has the
  player's locked positions overlaid, is charged through the wallet on the room's
  currency path (keys for paid rooms, clips for free), then enqueued as a branded
  `JOB` on the player's lane — the lane is named by the player's `PLR`, so the bus
  rotates service across players and one keyboard masher cannot starve the field.
  The host never scores; the consumer does. Games are opened by `Codemojex.Rooms`.
  """
  alias EchoMQ.Lanes
  alias Codemojex.{Bus, Store, Cache, Locks, EmojiSet, Wallet}

  @queue "cm"
  def queue, do: @queue

  @doc """
  Submit a guess: validate, overlay locks, charge the right currency, enqueue. The
  game's mutable state is read from the system of record; the cache is trusted
  only for the immutable secret on the scoring path.
  """
  def submit(game, player, emojis) when length(emojis) == 6 do
    r = Store.game(game)
    now = System.system_time(:millisecond)

    cond do
      r == nil -> {:error, :no_game}
      Map.get(r, :status, :open) != :open -> {:error, :closed}
      expired?(r, now) -> {:error, :expired}
      not valid_guess?(r, emojis) -> {:error, :bad_guess}
      true ->
        guess = Locks.merge(game, player, emojis)

        case Wallet.charge_guess(player, r, game) do
          {:ok, _balance} ->
            job = EchoData.BrandedId.generate!("JOB")
            payload = :erlang.term_to_binary({:guess, game, player, guess})
            Lanes.enqueue(Bus.conn(), @queue, player, job, payload)

          {:error, reason} ->
            {:error, reason}
        end
    end
  end

  # Anything that is not a valid 6-element guess is simply a bad guess.
  def submit(_game, _player, _emojis), do: {:error, :bad_guess}

  defp expired?(r, now) do
    case Map.get(r, :ends_ms) do
      e when is_integer(e) -> now >= e
      _ -> false
    end
  end

  # A guess into a set-backed game must use that game's keyboard codes.
  defp valid_guess?(r, emojis) do
    case Map.get(r, :cell_codes) do
      codes when is_list(codes) and codes != [] ->
        length(emojis) == 6 and Enum.all?(emojis, &(&1 in codes))

      _ ->
        case Map.get(r, :emojiset) do
          nil ->
            true

          set_id ->
            case Cache.fetch_set(set_id) do
              %EmojiSet{} = set -> EmojiSet.valid_guess?(set, emojis)
              _ -> true
            end
        end
    end
  end

  @doc "Lock a code at a position (0..5); it persists across the player's guesses."
  def lock(game, player, pos, code), do: Locks.lock(game, player, pos, code)
  def unlock(game, player, pos), do: Locks.unlock(game, player, pos)
  def locked(game, player), do: Locks.locked(game, player)

  def pause(player), do: Lanes.pause(Bus.conn(), @queue, player)
  def resume(player), do: Lanes.resume(Bus.conn(), @queue, player)
  def depth(player), do: Lanes.depth(Bus.conn(), @queue, player)
end

defmodule Codemojex.ScoreWorker do
  @moduledoc """
  The scoring consumer — the authority. `EchoMQ.Consumer` drains the guess queue
  through `Lanes.claim`, the player id arriving as the lane group. It reads the
  game's secret through the cache, scores with the pure linear engine, writes a
  `GES` guess, counts the attempt, records the result on the leaderboard (the raw
  linear best), and — for a classic game — publishes a `scored` event. A golden
  game stores the guess but emits NO per-guess feedback (the blind contract): the
  score is sealed until reveal. A perfect crack (600) ends a classic game. A guess
  for an unknown game answers `:ok` (a drop), never a retry loop.
  """
  alias EchoMQ.Events
  alias EchoWire.Cmd
  alias Codemojex.{Bus, Store, Cache, Scoring, Board, Rooms, Wire}

  @queue "cm"
  def queue, do: @queue

  def handle(%{id: job_id, payload: payload, group: player}) do
    {:guess, game, ^player, emojis} = :erlang.binary_to_term(payload)

    case Cache.fetch_game(game) do
      %{secret: secret} = g ->
        s = Scoring.score(secret, emojis)
        gid = EchoData.BrandedId.generate!("GES")
        conn = Bus.conn()

        Store.put_guess(gid, %{
          game: game,
          player: player,
          emojis: emojis,
          points: s.total,
          at_ms: System.system_time(:millisecond)
        })

        Cmd.incr("cm:" <> game <> ":attempts") |> Wire.run(conn)

        eff = Board.record(game, player, s.total)

        # Blind mode (B-1): a golden game suppresses the per-guess feedback — the
        # score exists server-side at close but nothing about it leaks in-flight.
        if Map.get(g, :feedback, "score") == "score" do
          name = (Store.player(player) || %{name: "?"}).name

          Events.publish(conn, @queue, "scored", job_id,
            game: game,
            player: name,
            pct: to_string(s.percentage),
            eff: to_string(eff)
          )

          # live update for the room channel — no secret, no guess content
          Phoenix.PubSub.broadcast(
            Codemojex.PubSub,
            "game:" <> game,
            {:scored, %{game: game, player: name, pct: s.percentage, eff: eff}}
          )

          # a perfect crack ends a classic game immediately (winner-take-all)
          if s.total == 600, do: Rooms.close_game(game)
        end

        :ok

      _ ->
        :ok
    end
  end
end

defmodule Codemojex.Settle do
  @moduledoc """
  Game settlement as a second-queue job. Closing a game enqueues a `JOB` on the
  settle lane (lane = the game id); the consumer runs the payout
  (`Codemojex.Rooms.close_game/1`) — winner-take-all for a classic game, the
  sealed top-K split for a golden game — and returns the room to waiting. The
  move-then-settle split is the Exchange pattern: the guess queue competes, the
  settle queue pays.
  """
  alias EchoMQ.Lanes
  alias Codemojex.{Bus, Rooms}

  @queue "cm-settle"
  def queue, do: @queue

  def close(game) do
    job = EchoData.BrandedId.generate!("JOB")
    payload = :erlang.term_to_binary({:settle, game})
    Lanes.enqueue(Bus.conn(), @queue, game, job, payload)
  end

  def handle(%{payload: payload}) do
    {:settle, game} = :erlang.binary_to_term(payload)
    _ = Rooms.close_game(game)
    :ok
  end
end

defmodule Codemojex do
  @moduledoc """
  Codemojex on the bus: a six-emoji code-breaking competition whose entities are
  branded components persisted in Postgres, whose guesses are jobs on per-player
  lanes scored by a single authority, whose three currencies mutate atomically in
  the database through a wallet with a transaction ledger, whose rooms template
  their games, and whose diamond prize pools settle through a second queue
  (winner-take-all for a classic game, a sealed top-K split for a golden game).
  Startup is `Codemojex.Application`'s job — the Repo, PubSub, the EchoMQ bus and
  consumers, and the Phoenix endpoint come up there.
  """
  alias Codemojex.{Rooms, Guesses, Settle, View, Wallet}

  # players & wallet
  def create_player(name, opts \\ []), do: Wallet.create(name, opts)
  # cm.4: resolve a verified Telegram user id to its single PLR (resolve-or-create,
  # idempotent under concurrency). The auth handshake calls this once per verified
  # request before minting a SES.
  def resolve_player_by_tg(tg_user_id, opts \\ []), do: Wallet.resolve_by_tg(tg_user_id, opts)
  defdelegate balance(player), to: Wallet
  defdelegate purchase_keys(player, keys, ref), to: Wallet
  defdelegate convert_to_keys(player, diamonds), to: Wallet

  # rooms & games
  def create_room(name, set, opts \\ []), do: Rooms.create_room(name, set, opts)
  def create_golden_room(name, set, opts \\ []), do: Rooms.create_room(name, set, Keyword.put(opts, :golden, true))
  defdelegate join_room(room, player), to: Rooms
  def close(game), do: Settle.close(game)
  defdelegate close_now(game), to: Rooms, as: :close_game

  # play
  defdelegate submit(game, player, emojis), to: Guesses
  defdelegate lock(game, player, pos, code), to: Guesses
  defdelegate unlock(game, player, pos), to: Guesses
  defdelegate locked(game, player), to: Guesses
  defdelegate pause(player), to: Guesses
  defdelegate resume(player), to: Guesses
  defdelegate depth(player), to: Guesses

  # views (privacy-preserving: no secret, no others' guesses)
  defdelegate lobby, to: View
  defdelegate game_view(game), to: View
  def my_history(game, player, n \\ 50), do: View.my_history(game, player, n)
  def leaderboard(game, n \\ 10), do: View.leaderboard(game, n)
end
