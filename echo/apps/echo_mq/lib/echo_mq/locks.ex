defmodule EchoMQ.Locks do
  @moduledoc """
  The worker-side lock plane: an OPT-IN, supervised process that tracks the
  jobs a consumer holds and extends their leases on a timer, so a long-but-
  alive handler is not reaped mid-work. A worker started without it is the v2
  core worker, unchanged -- the plane is the standing lease-keeper for a
  deployment that runs long jobs, so no consumer hand-rolls a lease-extender
  (the v1 `EchoMQ.LockManager` capability re-derived). emq.2.3-D5.

  (The module is `EchoMQ.Locks`, not `EchoMQ.LockManager`: the frozen v1
  reference `apps/echomq` already defines `EchoMQ.LockManager`, and both apps
  load on one code path -- a same-named module would shadow the new bus non-
  deterministically. The public capability is the v1 lock plane's; the name is
  collision-free. emq.2.3 realization-over-literal, ledger L-1.)

  Opt-in and owner-started (the library law: no `mod:` auto-start -- the
  `EchoMQ.Pump` precedent). The decision core -- the lease and the extend
  interval -- is pure (`EchoMQ.Locks.Core`), so the cadence arithmetic is a
  value tested without a clock; the GenServer is the thin shell that beats on
  it. A `:transient` child: a normal stop is final, a crash restarts the plane
  whole (the next beat re-extends the held set, and the tracked set is rebuilt
  by the consumer's next `track_job`).

  The lease IS the active-set score (the v2 invariant), so the plane extends by
  re-scoring the active member (`EchoMQ.Jobs.extend_locks/4`) -- never a
  separate `…:lock` string as the lease clock. It DOES write the per-job
  `emq:{q}:job:<id>:lock` presence marker on `track_job/3` (deleted on
  `untrack_job/2` -- the v1 `releaseLock` capability), so the operator
  `EchoMQ.Jobs.remove_job/4` sees a held job and refuses it `EMQLOCK` (the
  emq.2.2 contract the marker activates). The marker is the held-by-a-worker
  flag; the lease clock is the active score -- the v2 split of the v1
  two-mechanism lock.

  The marker carries a `PX` TTL (a small multiple of the lease,
  `EchoMQ.Locks.Core.marker_ttl_ms/1`, default 2×) that the beat REFRESHES
  alongside the lease extension -- so it inherits the lease's self-healing: a
  live worker keeps both fresh; a CRASHED worker (no `untrack_job/2`) lets BOTH
  the lease (the active score the reaper/stalled-sweep reclaim) AND the marker
  (the `:lock` key) expire shortly after, so the operator `remove_job/4` is not
  blocked on a stale `EMQLOCK` for an unbounded window (the v1 lock-string's
  `PX` self-healing, restored under the v2 split -- L-3).

  On completion the consumer calls `untrack_job/2`: the plane stops extending
  and removes the marker -- it does NOT double-retire the active score (the
  `complete`/`retry` transition already retires it).
  """

  use GenServer

  alias EchoMQ.{Connector, Jobs, Keyspace, Locks}

  @doc """
  A transient child: a normal stop is final, a crash restarts the plane whole.
  The held set is rebuilt by the consumer's next `track_job/3`, and the next
  beat re-extends whatever is tracked, so a restart loses no live lease that is
  still being tracked.
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
  Start the lock plane. Options: `:conn` (a connector this plane drives) or
  `:connector` (options to start one, linked); `:queue` (the queue whose jobs
  it tracks); `:lease_ms` (the lease each extend renews to, default 30_000);
  `:extend_ms` or `:extend_ratio` (the beat -- when to re-extend, default half
  the lease); `:name` (an optional registered name).
  """
  def start_link(opts) do
    {name, opts} = Keyword.pop(opts, :name)
    gen_opts = if name, do: [name: name], else: []
    GenServer.start_link(__MODULE__, opts, gen_opts)
  end

  @doc """
  Track a held job by its id and current attempts-token. The next beat extends
  its lease; the per-job presence marker (`emq:{q}:job:<id>:lock`) is written
  now, so `EchoMQ.Jobs.remove_job/4` refuses the job `EMQLOCK` while it is
  held. Idempotent: re-tracking the same id updates its token. Cast (fire-and-
  forget); the read surface answers the tracked set.
  """
  def track_job(manager, job_id, token) when is_integer(token) do
    GenServer.cast(manager, {:track_job, job_id, token})
  end

  @doc """
  Stop tracking a held job (on completion or release): the plane stops
  extending it and DELetes its presence marker (the v1 `releaseLock`
  capability). It does NOT retire the active score -- the `complete`/`retry`
  transition already did. Cast.
  """
  def untrack_job(manager, job_id) do
    GenServer.cast(manager, {:untrack_job, job_id})
  end

  @doc "How many jobs the plane currently tracks."
  def get_active_job_count(manager) do
    GenServer.call(manager, :get_active_job_count)
  end

  @doc "The ids the plane currently tracks (in no particular order)."
  def get_tracked_job_ids(manager) do
    GenServer.call(manager, :get_tracked_job_ids)
  end

  @doc "Whether the plane currently tracks `job_id`."
  def is_tracked?(manager, job_id) do
    GenServer.call(manager, {:is_tracked, job_id})
  end

  @doc "Stop the plane; the current beat settles, no further beat is scheduled."
  def stop(manager, timeout \\ 5_000), do: GenServer.stop(manager, :normal, timeout)

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
      lease_ms: Locks.Core.lease_ms(opts),
      extend_ms: Locks.Core.extend_ms(opts),
      marker_ttl_ms: Locks.Core.marker_ttl_ms(opts),
      # %{job_id => token}
      tracked: %{}
    }

    {:ok, arm(state)}
  end

  @impl true
  def handle_cast({:track_job, job_id, token}, s) do
    # Gate the id at the key builder (INV5): an ill-formed id raises before the
    # marker write. Write the presence marker (so remove_job refuses EMQLOCK)
    # with a PX TTL (a small multiple of the lease, refreshed on each beat), so
    # a crashed worker's marker SELF-EXPIRES shortly after its lease lapses --
    # the v1 lock-string's self-healing, restored under the v2 split (L-3).
    marker = Keyspace.job_key(s.queue, job_id) <> ":lock"

    _ =
      Connector.command(s.conn, [
        "SET",
        marker,
        Integer.to_string(token),
        "PX",
        Integer.to_string(s.marker_ttl_ms)
      ])

    {:noreply, %{s | tracked: Map.put(s.tracked, job_id, token)}}
  end

  def handle_cast({:untrack_job, job_id}, s) do
    if Map.has_key?(s.tracked, job_id) do
      marker = Keyspace.job_key(s.queue, job_id) <> ":lock"
      _ = Connector.command(s.conn, ["DEL", marker])
    end

    {:noreply, %{s | tracked: Map.delete(s.tracked, job_id)}}
  end

  @impl true
  def handle_call(:get_active_job_count, _from, s) do
    {:reply, map_size(s.tracked), s}
  end

  def handle_call(:get_tracked_job_ids, _from, s) do
    {:reply, Map.keys(s.tracked), s}
  end

  def handle_call({:is_tracked, job_id}, _from, s) do
    {:reply, Map.has_key?(s.tracked, job_id), s}
  end

  @impl true
  def handle_info(:beat, s) do
    _ = extend_all(s)
    {:noreply, arm(s)}
  end

  @doc """
  One extension pass, exposed for a direct-drive test (no cadence): extend
  every tracked job's lease in one batch and drop any whose lease could not be
  extended (a stale token or a gone row -- the consumer no longer holds it).
  Answers `{:ok, %{extended: n, dropped: ids}}`.
  """
  def extend(s), do: extend_all(s)

  defp extend_all(%{tracked: tracked} = _s) when map_size(tracked) == 0 do
    {:ok, %{extended: 0, dropped: []}}
  end

  defp extend_all(%{conn: conn, queue: queue, lease_ms: lease} = s) do
    tracked = s.tracked
    held = Map.to_list(tracked)

    case Jobs.extend_locks(conn, queue, held, lease) do
      {:ok, failed} ->
        # Refresh the :lock marker PX for the jobs whose lease WAS extended (the
        # still-held set: tracked minus failed), so the marker stays alive in
        # lockstep with the lease. A failed id (stale/gone) is no longer held by
        # this worker -- its marker is left to self-expire (L-3 self-healing).
        failed_set = MapSet.new(failed)

        for {id, _token} <- held, not MapSet.member?(failed_set, id) do
          marker = Keyspace.job_key(queue, id) <> ":lock"
          _ = Connector.command(conn, ["PEXPIRE", marker, Integer.to_string(s.marker_ttl_ms)])
        end

        {:ok, %{extended: map_size(tracked) - length(failed), dropped: failed}}

      _other ->
        {:ok, %{extended: 0, dropped: []}}
    end
  end

  # The beat re-extends what is tracked; failed ids stay tracked (the next
  # consumer untrack_job removes them) -- the plane never drops a job on its
  # own, so a transient wire hiccup does not silently un-track a live job.
  defp arm(s) do
    Process.send_after(self(), :beat, s.extend_ms)
    s
  end
end
