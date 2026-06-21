defmodule EchoMQ.BatchConsumer do
  @moduledoc """
  The self-pacing batch consumer: a supervised process that watches the flat
  `emq:{q}:pending` depth and flushes ONE batch when a SIZE FLOOR
  (`min_size`) or a LATENCY CEILING (`timeout`) is reached, draining via the
  byte-frozen `EchoMQ.Jobs.claim_batch/4` (`@bclaim`, the emq.5.1 spine). The
  spine is a manual single-shot pull; this gives it a rhythm with both a size
  floor and a latency ceiling. emq.5.2.

  The home of the batches family (5.2 the flat batch, 5.3 the grouped batch,
  5.4 the partitioned finish), kept a SIBLING of `EchoMQ.Consumer` rather than
  a mode on it: the Consumer is the single-job RING consumer (its standalone
  and metronome modes are the SAME `EchoMQ.Lanes.claim/3` + single-job-handler
  shape); the batch consumer is a DIFFERENT claim path (watch-depth -> flush
  the flat set) AND a different handler contract (a batch handler returning a
  per-member verdict map). emq.5.2-D1.

  The cadence is WATCH-DEPTH (emq.5.2-D1): the window reads
  `EchoMQ.Jobs.pending_size/2` (a `ZCARD` -- a pure read, NO claim, NO lease
  tick) to decide whether the floor is met, and claims a batch ONLY at the
  flush moment (one `claim_batch/4` for the decided size). So nothing is leased
  during accumulation -- `timeout` (when to claim) and `lease_ms` (the claimed
  batch's deadline) are INDEPENDENT, dodging the early-lease/timeout coupling
  an accumulate-and-hold model would carry. The flush decision is the pure
  `EchoMQ.BatchShaper.Core` (`batch_shaper/core.ex`), driven by an INJECTED
  clock (`:now_fn`), so the timer leg is deterministic.

  The batch handler is invoked ONCE over the served members
  (`[%{id:, payload:, attempts:}]`) and answers a PER-MEMBER verdict map
  (`%{id => :ok | {:error, reason}}`); the `:ok` members retire through the
  byte-frozen `EchoMQ.Jobs.complete/5`, the `{:error, reason}` members retry
  through the byte-frozen `EchoMQ.Jobs.retry/7` (each member's reason -> that
  member's `last_error`), so emq.5.1's partial-failure isolation is observable
  through the cadence -- one poison member retries alone, the rest complete. A
  served member ABSENT from the returned map is a contract violation treated as
  a RETRY (`{:error, "missing verdict"}`), never a silent complete --
  unprocessed work must not retire. A raising batch handler converts to a
  whole-batch retry and the loop survives (the `EchoMQ.Consumer` `drain/1`
  rescue/catch discipline, Chapter 3.5, generalized to the batch).
  emq.5.2-D2.

  Each settled member emits its own lifecycle event through the byte-frozen
  `EchoMQ.Events.publish/5` (`completed`/`failed`, on the member's own branded
  `job_id`, the id gated at the key builder) -- the batch is invisible to the
  events plane, which sees N per-member transitions, exactly the standalone
  Consumer's per-job settle. emq.5.2-D3.

  Control (a `stop/2` request, a supervisor `:shutdown`) is honored at the
  settle points -- between batches and at the poll wait, NEVER inside a batch's
  settle -- the `EchoMQ.Consumer` `check_control` discipline. The process traps
  exits; a self-started connector lane dies and returns with the loop.
  """

  alias EchoMQ.{Connector, Events, Jobs}
  alias EchoMQ.BatchShaper.Core

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
  Start the batch consumer. Options:

    * `:queue` (required) -- the queue whose flat `pending` set this drains.
    * `:batch_handler` (required) -- a fun taking the served members
      `[%{id:, payload:, attempts:}]` and answering a per-member verdict map
      `%{id => :ok | {:error, reason}}` (emq.5.2-D2). An absent member id is a
      retry (`"missing verdict"`); a raise is a whole-batch retry.
    * either `:conn` (a connector this consumer treats as its own exclusive
      lane) or `:connector` (options to start one, linked to the loop).
    * `:min_size` (the SIZE FLOOR, default 1) and `:timeout` (the LATENCY
      CEILING in ms, default 1_000) -- each a positive integer or
      `EchoMQ.BatchShaper.Core.validate!/2` RAISES at start.
    * `:lease_ms` (the claimed batch's lease, default 30_000),
      `:poll_ms` (the watch cadence, default 50), `:retry_delay_ms`
      (default 1_000), `:max_attempts` (default 3) tune the rhythm.
    * `:now_fn` (the injected clock, default
      `fn -> System.monotonic_time(:millisecond) end`) -- the test seam that
      makes the timer leg deterministic.
  """
  def start_link(opts) do
    queue = Keyword.fetch!(opts, :queue)
    batch_handler = Keyword.fetch!(opts, :batch_handler)
    {min_size, timeout} = Core.validate!(Keyword.get(opts, :min_size, 1), Keyword.get(opts, :timeout, 1_000))

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
          batch_handler: batch_handler,
          min_size: min_size,
          timeout: timeout,
          lease_ms: Keyword.get(opts, :lease_ms, 30_000),
          poll_ms: Keyword.get(opts, :poll_ms, 50),
          retry_delay_ms: Keyword.get(opts, :retry_delay_ms, 1_000),
          max_attempts: Keyword.get(opts, :max_attempts, 3),
          now_fn: Keyword.get(opts, :now_fn, fn -> System.monotonic_time(:millisecond) end)
        }

        loop(state)
      end)

    {:ok, pid}
  end

  @doc """
  Drain and stop: the loop settles the batch in hand (if any), claims nothing
  more, and exits `:normal` -- a self-started connector lane closes quietly
  with it. Synchronous; the reply arrives when the loop is down. A waiting
  consumer notices the request at its poll wait, so stop latency is bounded by
  the poll cadence plus the batch in hand. The same drain runs under a
  supervisor (`Supervisor.terminate_child/2`) because the loop traps exits and
  honors `:shutdown` at the same settle points.
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

  # The window: open at t0 (the injected clock), then watch the flat pending
  # depth on the poll cadence, feeding (depth, elapsed) to the pure shaper.
  # On :wait the window stays open (no claim -- no lease tick); on a flush the
  # batch is claimed ONCE, settled per-member, and the window re-opens.
  defp loop(s) do
    check_control()
    window(s, s.now_fn.())
    loop(s)
  end

  defp window(s, t0) do
    check_control()
    {:ok, depth} = Jobs.pending_size(s.conn, s.queue)
    elapsed = s.now_fn.() - t0

    case Core.decide(depth, elapsed, s.min_size, s.timeout) do
      {:flush, size} ->
        flush(s, size)

      :wait ->
        # park the poll cadence, honoring control -- a parked consumer is
        # interrupted by a stop/shutdown rather than busy-spinning the wire.
        if poll_wait(s.poll_ms), do: window(s, t0), else: :stopped
    end
  end

  # The loop traps exits, so control arrives as messages and is honored at the
  # settle points -- between batches and at the poll wait, never inside a
  # batch's settle. A stop request drains to :normal; the supervisor's
  # :shutdown drains to :shutdown; the dedicated lane dying takes the loop with
  # it, for the tree to restart.
  defp check_control do
    receive do
      {:emq_stop, _from, _ref} -> exit(:normal)
      {:EXIT, _from, :shutdown} -> exit(:shutdown)
      {:EXIT, _from, reason} -> exit(reason)
    after
      0 -> :ok
    end
  end

  # Wait up to poll_ms for the next watch, honoring control at the wait. true
  # to keep watching, exit on a stop/shutdown (the wait is the settle point).
  defp poll_wait(poll_ms) do
    receive do
      {:emq_stop, _from, _ref} -> exit(:normal)
      {:EXIT, _from, :shutdown} -> exit(:shutdown)
      {:EXIT, _from, reason} -> exit(reason)
    after
      poll_ms -> true
    end
  end

  # Flush: claim the decided size ONCE over the flat pending set (the
  # byte-frozen claim_batch/4 -- NOT Lanes.claim/3, the grouped ring; the
  # grouped batch is emq.5.3). claim_batch/4 consults paused?/2 FIRST, so a
  # paused queue answers :empty and the window re-opens with no batch. A benign
  # race (the set emptied between the depth read and the flush) is the same
  # :empty -- no batch this window.
  defp flush(s, size) do
    case Jobs.claim_batch(s.conn, s.queue, size, s.lease_ms) do
      :empty ->
        :ok

      {:ok, members} ->
        verdicts = invoke(s, members)
        settle(s, members, verdicts)
    end
  end

  # Invoke the batch handler ONCE over the served members. A raise converts to
  # a whole-batch retry verdict (the Consumer drain/1 rescue/catch discipline
  # generalized): every member gets {:error, reason} so the batch retries
  # rather than crashing the loop. A handler that answers a non-map is the same
  # whole-batch retry (a contract violation at the batch level).
  defp invoke(s, members) do
    view = Enum.map(members, fn {id, payload, att} -> %{id: id, payload: payload, attempts: att} end)

    try do
      s.batch_handler.(view)
    rescue
      e -> {:batch_error, Exception.message(e)}
    catch
      :exit, reason -> {:batch_error, "exit: " <> inspect(reason)}
      :throw, value -> {:batch_error, "throw: " <> inspect(value)}
    end
    |> normalize(members)
  end

  # Normalize the handler's answer into a per-member verdict map. A
  # {:batch_error, reason} (a raise/throw/exit, or below a non-map answer) maps
  # EVERY member to that error (the whole-batch retry). A proper map is taken
  # as-is; an absent member is filled fail-safe at the settle (D2 sub-decision).
  defp normalize({:batch_error, reason}, members) do
    Map.new(members, fn {id, _p, _a} -> {id, {:error, reason}} end)
  end

  defp normalize(map, _members) when is_map(map), do: map

  defp normalize(other, members) do
    # a non-map, non-error answer is a batch-level contract violation -> retry all
    Map.new(members, fn {id, _p, _a} -> {id, {:error, "bad verdict: " <> inspect(other)}} end)
  end

  # Settle each member individually through the byte-frozen complete/5 / retry/7
  # (emq.5.1's partial-failure isolation -- the batch is a CLAIM unit, not a
  # RESOLUTION unit), and emit its own lifecycle event through the byte-frozen
  # Events.publish/5 (D3 -- per-member, on the member's own gated id). A served
  # member ABSENT from the verdict map is a retry ("missing verdict"), never a
  # silent complete (D2 sub-decision -- unprocessed work must not retire).
  defp settle(s, members, verdicts) do
    Enum.each(members, fn {id, _payload, att} ->
      case Map.get(verdicts, id, {:error, "missing verdict"}) do
        :ok ->
          Jobs.complete(s.conn, s.queue, id, att)
          publish(s, "completed", id)

        {:error, reason} ->
          Jobs.retry(s.conn, s.queue, id, att, s.retry_delay_ms, s.max_attempts, to_string(reason))
          publish(s, "failed", id)
      end
    end)
  end

  # Best-effort per-member lifecycle event (fire-and-forget, the id gated at the
  # key builder -- INV5/INV-Events). A publish error is swallowed so the events
  # plane never sinks the settle loop.
  defp publish(s, event, id) do
    _ = Events.publish(s.conn, s.queue, event, id)
    :ok
  end
end
