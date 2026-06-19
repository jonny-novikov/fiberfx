defmodule EchoMQ.Consumer do
  @moduledoc """
  The loop that owns the rhythm. A supervised process holding a dedicated
  connector -- blocking verbs get their own lane (Appendix B) -- that
  beats on a cadence: reap expired leases, promote due schedules, drain
  the ring with rotating claims, then park on the wake key with BLPOP
  until readiness arrives as a wake or the beat elapses. Park, don't
  poll: a parked consumer costs the wire nothing, and the beat doubles
  as the pump cadence Chapter 3.3 shipped beats for. Hardened by Chapter
  3.5: a raising handler converts to a typed retry and the loop survives;
  `stop/2` drains and stops -- the job in hand settles, nothing more is
  claimed. Chapters 3.4 and 3.5.

  emq.4.3 adds an OPT-IN `:metronome` mode for a POOL. With a `:metronome`
  the consumer does not hold its own block or run its own reap/promote: it
  registers idle with the queue's `EchoMQ.Metronome`, awaits a `:claim_once`
  poke, runs the byte-frozen `EchoMQ.Lanes.claim/3` exactly once, settles, and
  re-registers -- one blocker per queue (the metronome), the herd gone,
  readiness fanned out fairly. WITHOUT a `:metronome` the consumer is the
  shipped standalone loop, byte-for-byte: it self-parks on the wake token and
  runs its own cadence (a lone consumer is no herd). The metronome is a
  coordinator for a pool; a standalone consumer needs none.
  """

  alias EchoMQ.{Connector, Jobs, Keyspace, Lanes}

  @doc "A permanent child: the loop restarts whole, and its self-started connector lane dies and returns with it."
  def child_spec(opts) do
    %{
      id: Keyword.get(opts, :id, __MODULE__),
      start: {__MODULE__, :start_link, [opts]},
      restart: :permanent,
      shutdown: 5_000
    }
  end

  @doc """
  Start the loop. Options: `:queue`, `:handler` (a fun taking
  `%{id:, payload:, attempts:, group:}` and answering `:ok` or
  `{:error, reason}`), and either `:conn` (a connector this consumer will
  treat as its own exclusive lane) or `:connector` (options to start one,
  linked to the loop). `:lease_ms`, `:beat_ms`, `:retry_delay_ms`,
  `:max_attempts`, `:pump_batch` tune the rhythm.

  `:metronome` (opt-in, emq.4.3) is the pid or registered name of the queue's
  `EchoMQ.Metronome`. With it the consumer runs the POOL path -- register idle,
  await a `:claim_once`, claim once, settle, re-register -- and does NOT
  self-park or run its own reap/promote (the metronome owns the one block + the
  one beat per queue). Without it the consumer is the shipped standalone loop,
  byte-for-byte.
  """
  def start_link(opts) do
    queue = Keyword.fetch!(opts, :queue)
    handler = Keyword.fetch!(opts, :handler)

    pid =
      spawn_link(fn ->
        Process.flag(:trap_exit, true)

        conn =
          case Keyword.fetch(opts, :conn) do
            {:ok, c} ->
              c

            :error ->
              {:ok, c} = Connector.start_link(Keyword.fetch!(opts, :connector))
              c
          end

        state = %{
          conn: conn,
          queue: queue,
          handler: handler,
          lease_ms: Keyword.get(opts, :lease_ms, 30_000),
          beat_ms: Keyword.get(opts, :beat_ms, 1_000),
          retry_delay_ms: Keyword.get(opts, :retry_delay_ms, 1_000),
          max_attempts: Keyword.get(opts, :max_attempts, 3),
          pump_batch: Keyword.get(opts, :pump_batch, 100),
          metronome: Keyword.get(opts, :metronome)
        }

        case state.metronome do
          nil -> loop(Map.delete(state, :metronome))
          _ -> metronome_loop(state)
        end
      end)

    {:ok, pid}
  end

  @doc """
  Drain and stop: the loop settles the job in hand, claims nothing more,
  and exits `:normal` -- a self-started connector lane closes quietly with
  it. Synchronous; the reply arrives when the loop is down. A parked
  consumer notices the request when its park returns, so stop latency is
  bounded by the beat plus the job in hand. This is the unsupervised
  owner's verb; under a supervisor, `Supervisor.terminate_child/2` drains
  the same way because the loop traps exits and honors `:shutdown` at the
  same settle points.
  """
  def stop(pid, timeout \\ 5_000) when is_pid(pid) do
    ref = Process.monitor(pid)
    send(pid, {:emq_stop, self(), ref})

    receive do
      {:DOWN, ^ref, :process, ^pid, _reason} -> :ok
    after
      timeout ->
        Process.demonitor(ref, [:flush])
        {:error, :timeout}
    end
  end

  defp loop(s) do
    check_control()
    {:ok, _} = Jobs.reap(s.conn, s.queue)
    {:ok, _} = Jobs.promote(s.conn, s.queue, s.pump_batch)
    drain(s)
    park(s)
    loop(s)
  end

  # The loop traps exits, so control arrives as messages and is honored at
  # the settle points -- between jobs, never inside one. A stop request
  # drains to :normal; the supervisor's :shutdown drains to :shutdown; the
  # dedicated lane dying takes the loop with it, for the tree to restart.
  defp check_control do
    receive do
      {:emq_stop, _from, _ref} -> exit(:normal)
      {:EXIT, _from, :shutdown} -> exit(:shutdown)
      {:EXIT, _from, reason} -> exit(reason)
    after
      0 -> :ok
    end
  end

  defp drain(s) do
    check_control()

    case Lanes.claim(s.conn, s.queue, s.lease_ms) do
      :empty ->
        :ok

      {:ok, {id, payload, att, group}} ->
        verdict =
          try do
            s.handler.(%{id: id, payload: payload, attempts: att, group: group})
          rescue
            e -> {:error, Exception.message(e)}
          catch
            :exit, reason -> {:error, "exit: " <> inspect(reason)}
            :throw, value -> {:error, "throw: " <> inspect(value)}
          end

        case verdict do
          :ok ->
            Jobs.complete(s.conn, s.queue, id, att)

          {:error, reason} ->
            Jobs.retry(s.conn, s.queue, id, att, s.retry_delay_ms, s.max_attempts, to_string(reason))
        end

        drain(s)
    end
  end

  defp park(s) do
    secs = :erlang.float_to_binary(s.beat_ms / 1000, decimals: 3)
    wake = Keyspace.queue_key(s.queue, "wake")
    _ = Connector.command(s.conn, ["BLPOP", wake, secs], s.beat_ms + 2_000)
    :ok
  end

  # The POOL path (emq.4.3, opt-in `:metronome`). The consumer holds NO block
  # and runs NO reap/promote (the metronome owns the single block + the one
  # beat per queue -- SEAM-1); it registers idle, then settles into a receive,
  # acting on the metronome's poke. Readiness is fanned out by the metronome,
  # one `@gclaim` per idle consumer per wake, so the herd is gone and no
  # consumer starves. The settle points are the same discipline as the
  # standalone loop's `check_control`: a stop/shutdown is honored between claims,
  # never inside one, and deregisters from the metronome first (no orphaned
  # registration). The metronome `Process.monitor/1`s this pid, so a crash is a
  # monitor-detected registry removal -- a deregister is the clean-exit courtesy,
  # the monitor is the safety net.
  defp metronome_loop(s) do
    register_idle(s)
    await_poke(s)
  end

  defp register_idle(s), do: send_metronome(s, {:register_idle, self()})

  # Idle: await the metronome's `:claim_once` poke, or a stop/shutdown control.
  # A poke runs exactly one claim+settle, then re-registers and awaits again --
  # the metronome decides when there is more, re-poking promptly (the
  # one-claim-per-idle-consumer-per-wake contract). A stop/shutdown deregisters
  # and exits at this settle point (nothing is in hand -- the consumer is idle).
  defp await_poke(s) do
    receive do
      {:claim_once, _from} ->
        claim_once(s)
        metronome_loop(s)

      {:emq_stop, _from, _ref} ->
        deregister(s)
        exit(:normal)

      {:EXIT, _from, :shutdown} ->
        deregister(s)
        exit(:shutdown)

      {:EXIT, _from, reason} ->
        deregister(s)
        exit(reason)
    end
  end

  # Run the byte-frozen atomic claim ONCE (via `Lanes.claim/3` -- the consumer
  # NEVER pops the lane/ring itself; the lane head is popped inside `@gclaim`
  # only, §12.2), handle the job, and settle it -- the same settle the
  # standalone `drain/1` makes (`:ok` -> `Jobs.complete`, an error or a raise ->
  # `Jobs.retry`), but exactly once per poke, not exhaustively (the metronome's
  # dispatch, not the consumer's drain, decides how many). An empty lane on a
  # poke is a no-op (the metronome poked optimistically; the consumer simply
  # re-registers).
  defp claim_once(s) do
    case Lanes.claim(s.conn, s.queue, s.lease_ms) do
      :empty ->
        :ok

      {:ok, {id, payload, att, group}} ->
        verdict =
          try do
            s.handler.(%{id: id, payload: payload, attempts: att, group: group})
          rescue
            e -> {:error, Exception.message(e)}
          catch
            :exit, reason -> {:error, "exit: " <> inspect(reason)}
            :throw, value -> {:error, "throw: " <> inspect(value)}
          end

        case verdict do
          :ok ->
            Jobs.complete(s.conn, s.queue, id, att)

          {:error, reason} ->
            Jobs.retry(s.conn, s.queue, id, att, s.retry_delay_ms, s.max_attempts, to_string(reason))
        end
    end
  end

  defp deregister(s), do: send_metronome(s, {:deregister, self()})

  defp send_metronome(s, msg) do
    send(s.metronome, msg)
    :ok
  end
end
