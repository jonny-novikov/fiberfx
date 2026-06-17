defmodule Codemoji.Guesses do
  @moduledoc """
  The host API. Opening a round mints a `RND` and writes the round component (its
  secret, category, timer, prize pool, key cost). A guess is gated for keys, then
  enqueued as a branded `JOB` on the player's lane — the lane is named by the
  player's `USR` id, so the bus rotates service across players and one keyboard
  masher cannot starve the field. The host never scores; the consumer does.
  """
  alias EchoMQ.Lanes
  alias Codemoji.{Bus, Store, Cache}

  @queue "cm"
  def queue, do: @queue

  def start_round(category, secret, opts \\ []) when length(secret) == 6 do
    rid = EchoData.BrandedId.generate!("RND")
    now = System.system_time(:millisecond)

    round = %{
      category: category,
      secret: secret,
      started_ms: now,
      ends_ms: now + Keyword.get(opts, :duration_ms, 35 * 3_600 * 1000),
      prize_pool: Keyword.get(opts, :prize_pool, 0),
      keys_cost: Keyword.get(opts, :keys_cost, 1),
      status: :open
    }

    :ok = Store.put_round(rid, round)
    :ok = Cache.put_round(rid, round)
    {:ok, rid}
  end

  def join(name, keys) do
    uid = EchoData.BrandedId.generate!("USR")
    :ok = Store.put_player(uid, %{name: name, stars: 0, keys: keys})
    {:ok, uid}
  end

  @doc "Spend a key and enqueue the guess on the player's lane, or refuse."
  def submit(round, player, emojis) when length(emojis) == 6 do
    p = Store.player(player)
    cost = (Cache.fetch_round(round) || %{keys_cost: 1}).keys_cost

    cond do
      p == nil ->
        {:error, :no_player}

      p.keys < cost ->
        {:error, :no_keys}

      true ->
        :ok = Store.put_player(player, %{p | keys: p.keys - cost})
        job = EchoData.BrandedId.generate!("JOB")
        payload = :erlang.term_to_binary({:guess, round, player, emojis})
        Lanes.enqueue(Bus.conn(), @queue, player, job, payload)
    end
  end

  def pause(player), do: Lanes.pause(Bus.conn(), @queue, player)
  def resume(player), do: Lanes.resume(Bus.conn(), @queue, player)
  def depth(player), do: Lanes.depth(Bus.conn(), @queue, player)
end

defmodule Codemoji.ScoreWorker do
  @moduledoc """
  The scoring consumer — the authority. `EchoMQ.Consumer` drains the guess queue
  through `Lanes.claim`, the player id arriving as the lane group. It reads the
  round's secret through the cache, scores the guess with the pure engine, writes
  a `GES` guess component, records the result on the leaderboard (awarding any
  first-mover tier bonuses), and publishes a `scored` event. A guess for an
  unknown round answers `:ok` (a drop), never a retry loop.
  """
  alias Codemoji.{Bus, Store, Cache, Scoring, Board}
  alias EchoMQ.Events

  @queue "cm"
  def queue, do: @queue

  def handle(%{id: job_id, payload: payload, group: player}) do
    {:guess, round, ^player, emojis} = :erlang.binary_to_term(payload)

    case Cache.fetch_round(round) do
      %{secret: secret} ->
        s = Scoring.score(secret, emojis)
        gid = EchoData.BrandedId.generate!("GES")

        Store.put_guess(gid, %{
          round: round,
          player: player,
          emojis: emojis,
          points: s.total,
          percentage: s.percentage,
          tier: s.tier,
          at_ms: System.system_time(:millisecond)
        })

        {eff, claimed, _bonus} = Board.record(round, player, s.total, s.tier)
        name = (Store.player(player) || %{name: "?"}).name

        Events.publish(Bus.conn(), @queue, "scored", job_id,
          round: round,
          player: name,
          pct: to_string(s.percentage),
          tier: to_string(s.tier),
          eff: to_string(eff),
          first: to_string(claimed)
        )

        :ok

      _ ->
        :ok
    end
  end
end

defmodule Codemoji.Settle do
  @moduledoc """
  Round settlement, as a cross-queue job. Closing a round enqueues a `JOB` on the
  settle queue (lane = the round id); the settle consumer takes the 30% platform
  fee, splits the remaining 70% across the top of the leaderboard in proportion to
  score, and writes the payouts. The move-then-settle split is the Exchange
  pattern: the guess queue competes, the settle queue pays.
  """
  alias EchoMQ.{Lanes, Connector}
  alias Codemoji.{Bus, Board}

  @queue "cm-settle"
  @fee 0.30
  def queue, do: @queue

  def close(round, prize_pool) do
    job = EchoData.BrandedId.generate!("JOB")
    payload = :erlang.term_to_binary({:settle, round, prize_pool})
    Lanes.enqueue(Bus.conn(), @queue, round, job, payload)
  end

  def handle(%{payload: payload}) do
    {:settle, round, prize_pool} = :erlang.binary_to_term(payload)
    net = trunc(prize_pool * (1.0 - @fee))
    {:ok, board} = Board.top(round, 3)
    sum = board |> Enum.map(&elem(&1, 1)) |> Enum.sum()
    conn = Bus.conn()

    Enum.each(board, fn {player, score} ->
      pay = if sum > 0, do: trunc(net * score / sum), else: 0
      Connector.command(conn, ["HSET", "cm:" <> round <> ":payout", player, to_string(pay)])
    end)

    :ok
  end

  def payouts(round) do
    case Connector.command(Bus.conn(), ["HGETALL", "cm:" <> round <> ":payout"]) do
      {:ok, m} when is_map(m) -> {:ok, Enum.map(m, fn {k, v} -> {k, v} end)}
      {:ok, flat} when is_list(flat) -> {:ok, flat |> Enum.chunk_every(2) |> Enum.map(fn [k, v] -> {k, v} end)}
      other -> other
    end
  end
end

defmodule Codemoji do
  @moduledoc """
  Codemoji on the bus: a six-emoji code-breaking competition whose entities are
  branded components, whose guesses are jobs on per-player lanes scored by a single
  authority, whose leaderboard and first-mover bonuses live in Valkey, and whose
  prizes settle through a second queue. `start/1` brings up the component stores,
  the connector, and the two consumers.
  """
  alias Codemoji.{Store, Bus, Guesses, ScoreWorker, Settle, Board}
  alias EchoMQ.Consumer

  def start(opts \\ []) do
    port = Keyword.get(opts, :port, 6390)
    {:ok, _} = Store.start_link()
    {:ok, _} = Bus.start(port: port)

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

  defdelegate start_round(category, secret, opts), to: Guesses
  defdelegate join(name, keys), to: Guesses
  defdelegate submit(round, player, emojis), to: Guesses
  defdelegate pause(player), to: Guesses
  defdelegate resume(player), to: Guesses
  defdelegate depth(player), to: Guesses
  defdelegate top(round, n), to: Board
  defdelegate firsts(round, player), to: Board
  def close(round, pool), do: Settle.close(round, pool)
  defdelegate payouts(round), to: Settle
end
