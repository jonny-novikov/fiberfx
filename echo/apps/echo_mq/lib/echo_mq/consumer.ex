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

        loop(%{
          conn: conn,
          queue: queue,
          handler: handler,
          lease_ms: Keyword.get(opts, :lease_ms, 30_000),
          beat_ms: Keyword.get(opts, :beat_ms, 1_000),
          retry_delay_ms: Keyword.get(opts, :retry_delay_ms, 1_000),
          max_attempts: Keyword.get(opts, :max_attempts, 3),
          pump_batch: Keyword.get(opts, :pump_batch, 100)
        })
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
end
