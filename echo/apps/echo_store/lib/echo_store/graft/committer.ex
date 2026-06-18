defmodule EchoStore.Graft.Committer do
  @moduledoc """
  Puts the Graft pieces together: the commit-log-as-outbox drain (ADR-C).

  The volume already gives a fenced, OCC single-writer commit (`VolumeServer` + `Epoch`),
  durable local pages (CubDB), rollup to object storage (`Streamer`), and lock-free reads
  (`Reader`). What was missing is the steady-state *drain*: a process that learns of each
  new commit and re-publishes its names to the work bus at-least-once, so a downstream
  consumer (Codemoji's notifier, a projection rebuild, a Go replica) reacts to durable state
  without polling.

  It subscribes to the volume's commit channel (`EchoStore.Graft.Sync.subscribe_commits/2`),
  and on each notice enqueues a job carrying the commit's branded ids onto a target queue via
  `EchoMQ.Jobs`. Delivery is at-least-once: the commit is already durable (its LSN survives a
  crash), the SyncPoint records how far the bus has been told, and a re-announced commit is
  absorbed by bus admission dedup plus newer-wins downstream — the same contract as the
  journal outbox. The committer never merges; reconciliation uses `Divergence`.
  """
  use GenServer
  require Logger

  alias EchoStore.Graft.{Sync, Store, Divergence, Epoch}
  alias EchoData.Graft.SyncPoint
  alias EchoMQ.Jobs

  @registry EchoStore.Graft.Registry

  @type opts :: [
          volume_id: EchoData.BrandedId.t(),
          conn: GenServer.server(),
          db: GenServer.server(),
          queue: binary()
        ]

  @spec start_link(opts()) :: GenServer.on_start()
  def start_link(opts) do
    vol = Keyword.fetch!(opts, :volume_id)
    GenServer.start_link(__MODULE__, opts, name: via(vol))
  end

  def via(vol), do: {:via, Registry, {@registry, {:committer, vol}}}

  @doc "Force a drain pass now (e.g. after recovery), in addition to the live subscription."
  @spec drain(EchoData.BrandedId.t()) :: :ok
  def drain(vol), do: GenServer.cast(via(vol), :drain)

  @impl true
  def init(opts) do
    state = %{
      vol: Keyword.fetch!(opts, :volume_id),
      conn: Keyword.fetch!(opts, :conn),
      db: Keyword.fetch!(opts, :db),
      queue: Keyword.get(opts, :queue, "graft.commits")
    }

    :ok = Sync.subscribe_commits(state.conn, state.vol)
    # catch up anything committed-but-unannounced before this process existed
    send(self(), :drain)
    {:ok, state}
  end

  @impl true
  def handle_cast(:drain, state), do: handle_info(:drain, state)

  @impl true
  # Live notice from the bus: announce exactly this commit's names onto the work queue.
  def handle_info({:emq_push, ["message", _channel, payload]}, state) do
    {lsn, cid, sid, _pages} = Sync.decode_notice(payload)
    announce(state, lsn, cid, sid)
    {:noreply, advance(state, lsn)}
  end

  # Catch-up drain: every commit above the announced frontier, oldest first.
  def handle_info(:drain, state) do
    sp = Store.get_syncpoint(state.db)
    from = sp.local_watermark + 1
    head = Store.head_lsn(state.db)

    state =
      if from > head do
        state
      else
        state.db
        |> Store.commits(from, head)
        |> Enum.reduce(state, fn {{:commit, lsn}, commit}, acc ->
          announce(acc, lsn, commit.id, commit.segment_id)
          advance(acc, lsn)
        end)
      end

    {:noreply, state}
  end

  def handle_info(_other, state), do: {:noreply, state}

  # --- announce + frontier ---------------------------------------------------

  # The bus carries the names; the bytes are already on the remote (cargo law).
  defp announce(state, lsn, commit_id, segment_id) do
    job_id = EchoData.BrandedId.generate!("JOB")
    payload = "#{state.vol}:#{lsn}:#{commit_id}:#{segment_id}"

    case Jobs.enqueue(state.conn, state.queue, job_id, payload) do
      {:ok, _} -> :ok
      other -> Logger.warning("committer #{state.vol} enqueue lsn=#{lsn} failed: #{inspect(other)}")
    end
  end

  # Move the announced frontier forward; persisted so a restart resumes, never re-floods.
  defp advance(state, lsn) do
    sp = Store.get_syncpoint(state.db)
    :ok = Store.put_syncpoint(state.db, SyncPoint.advance_local(sp, lsn))
    state
  end

  # --- the safety the committer leans on, exposed for callers ---------------

  @doc """
  Fenced commit: stamp the writer's epoch and reject a stale writer rather than double-append.
  Wraps `VolumeServer.commit/3` with the `Epoch` check so the outbox drain can trust that an
  announced commit came from the one authoritative writer.
  """
  @spec fenced_commit(EchoData.BrandedId.t(), non_neg_integer(), map(), Epoch.t(), Epoch.t()) ::
          {:ok, non_neg_integer()} | {:error, {:fenced, Epoch.t()}} | {:error, {:conflict, non_neg_integer()}}
  def fenced_commit(volume_id, base_lsn, staged, writer_epoch, current_epoch) do
    case Epoch.fence(writer_epoch, current_epoch) do
      :ok -> EchoStore.Graft.VolumeServer.commit(volume_id, base_lsn, staged)
      {:error, _} = fenced -> fenced
    end
  end

  @doc """
  Reconcile a replica against the remote without ever merging: fast-forward when only the
  remote moved, no-op when in sync, and surface `{:error, {:diverged, l, r}}` for a human when
  both moved. The decision rule of B5/B7, callable from a pull/reconcile path.
  """
  @spec reconcile(GenServer.server(), non_neg_integer(), non_neg_integer()) ::
          :ok | {:fast_forward, :remote, non_neg_integer()} | {:error, {:diverged, non_neg_integer(), non_neg_integer()}}
  def reconcile(db, local_head, remote_head) do
    sp = Store.get_syncpoint(db)

    case Divergence.check(sp, local_head, remote_head) do
      {:fast_forward, :remote, rh} = ff ->
        :ok = Store.put_syncpoint(db, SyncPoint.advance_remote(sp, rh))
        ff

      other ->
        other
    end
  end
end
