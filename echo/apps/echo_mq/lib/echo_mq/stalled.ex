defmodule EchoMQ.Stalled do
  @moduledoc """
  The explicit stalled-recovery sweep: a periodic recovery that distinguishes a
  job whose lease expired WITHOUT extension (a worker that stalled or died
  mid-job) from a transient slow handler, counting how many times a job has
  stalled and -- past a `max_stalled` threshold -- dead-lettering it rather than
  recovering it again (the v1 `EchoMQ.StalledChecker` / `moveStalledJobsToWait`
  capability re-derived). emq.2.3-D6.

  (The module is `EchoMQ.Stalled`, not `EchoMQ.StalledChecker`: the frozen v1
  reference `apps/echomq` already defines `EchoMQ.StalledChecker`, and both
  apps load on one code path -- a same-named module would shadow the new bus
  non-deterministically. The capability is the v1 checker's; the name is
  collision-free. emq.2.3 realization-over-literal, ledger L-1.)

  BEYOND the as-built dead-lease reaper, not a replacement. `EchoMQ.Jobs.reap/2`
  is the server-side single scan that returns ANY expired-lease job from
  `active` to `pending` ONCE, with no count -- crash recovery. This sweep is the
  count-thresholded layer ON TOP: each pass increments a per-job `stalled`
  field (a field on the as-built three-field row -- no new key type), recovers a
  job below the threshold, and dead-letters one at or above it, so a job that
  repeatedly stalls is not recovered forever. A deployment runs the reaper (via
  the consumer loop) for crash recovery and, optionally, this sweep for
  stall-count recovery.

  The clock is the server's (`TIME` inside the script -- never the v1 caller
  clock). The sweep declares ONLY the sets it touches (`active`/`pending`/
  `dead`) plus the queue base root for the per-job key derivation -- never the
  v1 9-key `moveStalledJobsToWait` LIST shape. A grouped job (the lanes family)
  recovers into its lane (`emq:{q}:g:<group>:pending`), mirroring the reaper's
  group branch.

  The sweep may run on its own opt-in `:transient` timer process (the
  `EchoMQ.Pump` shape) like the v1 periodic checker, or be direct-driven by
  `check/2` for an operator's one-shot recovery.
  """

  use GenServer

  alias EchoMQ.{Connector, Keyspace, Script}

  @default_max_stalled 1
  @default_interval_ms 30_000
  @default_limit 100

  # KEYS[1] active  KEYS[2] pending  KEYS[3] dead
  # ARGV[1] base ('emq:{q}:')  ARGV[2] max_stalled  ARGV[3] limit
  # Returns {recovered_ids, dead_ids}: the ids returned to pending (or a lane)
  # and the ids dead-lettered this pass.
  @sweep_stalled Script.new(:sweep_stalled, """
                 local p = ARGV[1]
                 local maxst = tonumber(ARGV[2])
                 local lim = tonumber(ARGV[3])
                 local t = redis.call('TIME')
                 local now = t[1] * 1000 + math.floor(t[2] / 1000)
                 local exp = redis.call('ZRANGEBYSCORE', KEYS[1], '-inf', now, 'LIMIT', 0, lim)
                 local recovered = {}
                 local dead = {}
                 for _, id in ipairs(exp) do
                   redis.call('ZREM', KEYS[1], id)
                   local jk = p .. 'job:' .. id
                   local g = redis.call('HGET', jk, 'group')
                   local st = redis.call('HINCRBY', jk, 'stalled', 1)
                   if g then
                     local act = redis.call('HINCRBY', p .. 'gactive', g, -1)
                     if act <= 0 then redis.call('HDEL', p .. 'gactive', g) end
                   end
                   if st >= maxst then
                     redis.call('HSET', jk, 'state', 'dead')
                     redis.call('HSET', jk, 'last_error', 'stalled')
                     redis.call('ZADD', KEYS[3], 0, id)
                     redis.call('HINCRBY', p .. 'metrics:failed', 'count', 1)
                     table.insert(dead, id)
                   else
                     if g then
                       local lane = p .. 'g:' .. g .. ':pending'
                       redis.call('ZADD', lane, 0, id)
                       if redis.call('SISMEMBER', p .. 'paused', g) == 0 then
                         local lim2 = redis.call('HGET', p .. 'glimit', g)
                         local act2 = tonumber(redis.call('HGET', p .. 'gactive', g) or '0')
                         if (not lim2 or act2 < tonumber(lim2)) and not redis.call('LPOS', p .. 'ring', g) then
                           redis.call('RPUSH', p .. 'ring', g)
                           redis.call('LPUSH', p .. 'wake', '1')
                           redis.call('LTRIM', p .. 'wake', 0, 63)
                         end
                       end
                     else
                       redis.call('ZADD', KEYS[2], 0, id)
                     end
                     redis.call('HSET', jk, 'state', 'pending')
                     table.insert(recovered, id)
                   end
                 end
                 return {recovered, dead}
                 """)

  @doc """
  Run ONE stalled-recovery sweep over `queue`. Options: `:max_stalled` (the
  threshold past which a repeatedly-stalled job is dead-lettered instead of
  recovered, default #{@default_max_stalled}); `:limit` (the max jobs examined
  this pass, default #{@default_limit}). Answers
  `{:ok, %{recovered: [id], dead: [id]}}` -- the ids returned to pending (or a
  lane) and the ids dead-lettered this pass. Reads the server `TIME`; declares
  only the sets it touches. emq.2.3-D6.
  """
  def check(conn, queue, opts \\ []) do
    max_stalled = Keyword.get(opts, :max_stalled, @default_max_stalled)
    limit = Keyword.get(opts, :limit, @default_limit)

    keys = [
      Keyspace.queue_key(queue, "active"),
      Keyspace.queue_key(queue, "pending"),
      Keyspace.queue_key(queue, "dead")
    ]

    argv = [
      Keyspace.queue_key(queue, ""),
      Integer.to_string(max_stalled),
      Integer.to_string(limit)
    ]

    case Connector.eval(conn, @sweep_stalled, keys, argv) do
      {:ok, [recovered, dead]} when is_list(recovered) and is_list(dead) ->
        {:ok, %{recovered: recovered, dead: dead}}

      other ->
        other
    end
  end

  @doc """
  Whether `job_id` is currently marked stalled: its `stalled` field on the row
  is present and positive (a job whose lease lapsed without extension and was
  swept at least once). A missing job, or one that has never stalled, answers
  `false`. The id is gated at the key builder (`Keyspace.job_key/2` -- INV5).
  The fourth `opts` argument matches the v1 `job_stalled?/4` arity (reserved for
  a future stall-age option); it is ignored today. emq.2.3-D6.
  """
  def job_stalled?(conn, queue, job_id, _opts \\ []) do
    case Connector.command(conn, ["HGET", Keyspace.job_key(queue, job_id), "stalled"]) do
      {:ok, nil} -> false
      {:ok, val} -> String.to_integer(val) > 0
      _ -> false
    end
  end

  # -- the optional periodic process (the v1 checker's timer) ----------------

  @doc """
  A transient child: a normal stop is final, a crash restarts the sweep cadence
  whole (the sweep is idempotent over the active set -- a restart re-sweeps
  without loss or double-recovery).
  """
  def child_spec(opts) do
    %{
      id: Keyword.get(opts, :id, __MODULE__),
      start: {__MODULE__, :start_link, [opts]},
      restart: :transient,
      shutdown: 5_000
    }
  end

  @doc """
  Start the periodic stalled sweep. Options: `:conn` (a connector this sweep
  drives) or `:connector` (options to start one, linked); `:queue`;
  `:interval_ms` (the beat, default #{@default_interval_ms}); `:max_stalled`,
  `:limit` (per-sweep, as `check/3`); `:name` (optional registered name). A
  deployment without this process is the unchanged v2 worker -- the sweep is
  opt-in (the `EchoMQ.Pump` law). emq.2.3-D6.
  """
  def start_link(opts) do
    {name, opts} = Keyword.pop(opts, :name)
    gen_opts = if name, do: [name: name], else: []
    GenServer.start_link(__MODULE__, opts, gen_opts)
  end

  @doc "Stop the periodic sweep; the current sweep settles, no further beat is scheduled."
  def stop(checker, timeout \\ 5_000), do: GenServer.stop(checker, :normal, timeout)

  @impl true
  def init(opts) do
    queue = Keyword.fetch!(opts, :queue)

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
      interval_ms: Keyword.get(opts, :interval_ms, @default_interval_ms),
      opts: Keyword.take(opts, [:max_stalled, :limit])
    }

    {:ok, arm(state)}
  end

  @impl true
  def handle_info(:sweep, s) do
    _ = check(s.conn, s.queue, s.opts)
    {:noreply, arm(s)}
  end

  defp arm(s) do
    Process.send_after(self(), :sweep, s.interval_ms)
    s
  end
end
