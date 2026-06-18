defmodule Codemoji.Guesses do
  @moduledoc """
  The play API. A guess is validated against the round's keyboard, has the
  player's locked positions overlaid, is charged through the wallet on the room's
  currency path (keys for paid rooms, clips for free), then enqueued as a branded
  `JOB` on the player's lane — the lane is named by the player's `USR`, so the bus
  rotates service across players and one keyboard masher cannot starve the field.
  The host never scores; the consumer does. Rounds are opened by `Codemoji.Rooms`.
  """
  alias EchoMQ.Lanes
  alias Codemoji.{Bus, Store, Cache, Locks, EmojiSet, Wallet}

  @queue "cm"
  def queue, do: @queue

  @doc """
  Submit a guess: validate, overlay locks, charge the right currency, enqueue. The
  round's mutable state is read from the system of record; the cache is trusted
  only for the immutable secret on the scoring path.
  """
  def submit(round, player, emojis) when length(emojis) == 6 do
    r = Store.round(round)
    now = System.system_time(:millisecond)

    cond do
      r == nil -> {:error, :no_round}
      Map.get(r, :status, :open) != :open -> {:error, :closed}
      expired?(r, now) -> {:error, :expired}
      not valid_guess?(r, emojis) -> {:error, :bad_guess}
      true ->
        guess = Locks.merge(round, player, emojis)

        case Wallet.charge_guess(player, r, round) do
          {:ok, _balance} ->
            job = EchoData.BrandedId.generate!("JOB")
            payload = :erlang.term_to_binary({:guess, round, player, guess})
            Lanes.enqueue(Bus.conn(), @queue, player, job, payload)

          {:error, reason} ->
            {:error, reason}
        end
    end
  end

  defp expired?(r, now) do
    case Map.get(r, :ends_ms) do
      e when is_integer(e) -> now >= e
      _ -> false
    end
  end

  # A guess into a set-backed round must use that set's codes.
  defp valid_guess?(r, emojis) do
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

  @doc "Lock a code at a position (0..5); it persists across the player's guesses."
  def lock(round, player, pos, code), do: Locks.lock(round, player, pos, code)
  def unlock(round, player, pos), do: Locks.unlock(round, player, pos)
  def locked(round, player), do: Locks.locked(round, player)

  def pause(player), do: Lanes.pause(Bus.conn(), @queue, player)
  def resume(player), do: Lanes.resume(Bus.conn(), @queue, player)
  def depth(player), do: Lanes.depth(Bus.conn(), @queue, player)
end

defmodule Codemoji.ScoreWorker do
  @moduledoc """
  The scoring consumer — the authority. `EchoMQ.Consumer` drains the guess queue
  through `Lanes.claim`, the player id arriving as the lane group. It reads the
  round's secret through the cache, scores with the pure engine, writes a `GES`
  guess, counts the attempt and pushes it onto the player's own history, records
  the result on the leaderboard (awarding first-mover tier bonuses), and publishes
  a `scored` event. A perfect crack (600) ends the round. A guess for an unknown
  round answers `:ok` (a drop), never a retry loop.
  """
  alias EchoMQ.{Connector, Events}
  alias Codemoji.{Bus, Store, Cache, Scoring, Board, Rooms}

  @queue "cm"
  def queue, do: @queue

  def handle(%{id: job_id, payload: payload, group: player}) do
    {:guess, round, ^player, emojis} = :erlang.binary_to_term(payload)

    case Cache.fetch_round(round) do
      %{secret: secret} ->
        s = Scoring.score(secret, emojis)
        gid = EchoData.BrandedId.generate!("GES")
        conn = Bus.conn()

        Store.put_guess(gid, %{
          round: round,
          player: player,
          emojis: emojis,
          points: s.total,
          percentage: s.percentage,
          tier: s.tier,
          at_ms: System.system_time(:millisecond)
        })

        Connector.command(conn, ["INCR", "cm:" <> round <> ":attempts"])
        Connector.command(conn, ["LPUSH", "cm:" <> round <> ":hist:" <> player, gid])

        {eff, claimed, _bonus} = Board.record(round, player, s.total, s.tier)
        name = (Store.player(player) || %{name: "?"}).name

        Events.publish(conn, @queue, "scored", job_id,
          round: round,
          player: name,
          pct: to_string(s.percentage),
          tier: to_string(s.tier),
          eff: to_string(eff),
          first: to_string(claimed)
        )

        # a perfect crack ends the round immediately (winner-take-all)
        if s.total == 600, do: Rooms.close_round(round)

        :ok

      _ ->
        :ok
    end
  end
end

defmodule Codemoji.Settle do
  @moduledoc """
  Round settlement as a second-queue job. Closing a round enqueues a `JOB` on the
  settle lane (lane = the round id); the consumer runs the winner-take-all payout
  (`Codemoji.Rooms.close_round/1`), depositing the diamond pool to the max-score
  player and returning the room to waiting. The move-then-settle split is the
  Exchange pattern: the guess queue competes, the settle queue pays.
  """
  alias EchoMQ.Lanes
  alias Codemoji.{Bus, Rooms}

  @queue "cm-settle"
  def queue, do: @queue

  def close(round) do
    job = EchoData.BrandedId.generate!("JOB")
    payload = :erlang.term_to_binary({:settle, round})
    Lanes.enqueue(Bus.conn(), @queue, round, job, payload)
  end

  def handle(%{payload: payload}) do
    {:settle, round} = :erlang.binary_to_term(payload)
    _ = Rooms.close_round(round)
    :ok
  end
end

defmodule Codemoji do
  @moduledoc """
  Codemoji on the bus: a six-emoji code-breaking competition whose entities are
  branded components, whose guesses are jobs on per-player lanes scored by a single
  authority, whose three currencies mutate atomically through a wallet with a
  transaction ledger, whose rooms template their rounds, and whose diamond prize
  pools settle winner-take-all through a second queue. `start/1` brings up the
  component stores, the connector, the wallet, and the two consumers.
  """
  alias Codemoji.{Store, Bus, Wallet, Rooms, Guesses, ScoreWorker, Settle, View, Board}
  alias EchoMQ.Consumer

  def start(opts \\ []) do
    port = Keyword.get(opts, :port, 6390)
    {:ok, _} = Store.start_link()
    {:ok, _} = Bus.start(port: port)
    {:ok, _} = Wallet.start_link()

    {:ok, score} =
      Consumer.start_link(
        queue: ScoreWorker.queue(),
        handler: &ScoreWorker.handle/1,
        connector: [port: port, protocol: 3],
        beat_ms: 100,
        lease_ms: 10_000
      )

    {:ok, settle} =
      Consumer.start_link(
        queue: Settle.queue(),
        handler: &Settle.handle/1,
        connector: [port: port, protocol: 3],
        beat_ms: 100,
        lease_ms: 10_000
      )

    {:ok, %{score: score, settle: settle}}
  end

  # players & wallet
  def create_player(name, opts \\ []), do: Wallet.create(name, opts)
  defdelegate balance(player), to: Wallet
  defdelegate purchase_keys(player, keys, ref), to: Wallet
  defdelegate convert_to_keys(player, diamonds), to: Wallet

  # rooms & rounds
  def create_room(name, set, opts \\ []), do: Rooms.create_room(name, set, opts)
  defdelegate join_room(room, player), to: Rooms
  def close(round), do: Settle.close(round)
  defdelegate close_now(round), to: Rooms, as: :close_round

  # play
  defdelegate submit(round, player, emojis), to: Guesses
  defdelegate lock(round, player, pos, code), to: Guesses
  defdelegate unlock(round, player, pos), to: Guesses
  defdelegate locked(round, player), to: Guesses
  defdelegate pause(player), to: Guesses
  defdelegate resume(player), to: Guesses
  defdelegate depth(player), to: Guesses

  # views (privacy-preserving: no secret, no others' guesses)
  defdelegate round_view(round), to: View
  def my_history(round, player, n \\ 50), do: View.my_history(round, player, n)
  def leaderboard(round, n \\ 10), do: View.leaderboard(round, n)
  defdelegate firsts(round, player), to: Board
end
