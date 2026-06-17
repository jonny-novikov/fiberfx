defmodule EchoStore.Graft.VolumeServer do
  @moduledoc """
  The single writer for one Volume. Graft serializes commits with "a global write
  lock ensuring commits execute one at a time" (graft.rs); on the BEAM that lock
  is this process's mailbox — commits are `handle_call`s, so they run one at a
  time by construction, with no lock primitive. Reads never touch this process:
  they go straight to the L1 (`EchoStore.Table`, a lock-free `read_concurrency`
  ETS table) or to CubDB's zero-cost snapshots (see `EchoStore.Graft.Reader`).

  When a remote is configured, the writer starts an `EchoStore.Graft.Streamer`
  and, on each commit, signals it (`commit_ready/2`). The Streamer ships the data
  to Tigris in real time and announces the commit on the bus — off the write
  path, so commit latency stays local.

  State:

    * `volume_id`  — the `VOL` GID
    * `head_lsn`   — the current head (monotonic, this process owns it)
    * `db`         — the CubDB store (`EchoStore.Graft.Store`)
    * `table`      — the L1 table name (`EchoStore.Table`) used as the head cache
    * `conn`       — the EchoMQ connector for notices (may be `nil`)
    * `remote`     — `{module, cfg}` durable remote, or `nil` (standalone)
  """
  use GenServer

  alias EchoData.Graft.{Id, Commit, PageSet, Snapshot}
  alias EchoStore.Graft.{Store, Streamer}

  @registry EchoStore.Graft.Registry

  # --- public API ---------------------------------------------------------

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) do
    volume_id = Keyword.fetch!(opts, :volume_id)
    GenServer.start_link(__MODULE__, opts, name: via(volume_id))
  end

  @doc "Opens a write transaction on the current head — the base for a commit."
  @spec begin(EchoData.BrandedId.t()) :: {:ok, base_lsn :: non_neg_integer()}
  def begin(volume_id), do: {:ok, GenServer.call(via(volume_id), :head_lsn)}

  @doc """
  Commits a staged page map against `base_lsn` (read-your-write happens in the
  caller's `Writer`). Returns `{:ok, lsn}`, or `{:error, {:conflict, head}}` when
  the base is stale — the OCC validation Graft performs before serializing.
  """
  @spec commit(EchoData.BrandedId.t(), non_neg_integer(), %{non_neg_integer() => binary()}) ::
          {:ok, non_neg_integer()} | {:error, {:conflict, non_neg_integer()}} | {:error, term()}
  def commit(volume_id, base_lsn, staged),
    do: GenServer.call(via(volume_id), {:commit, base_lsn, staged})

  @doc "An immutable Snapshot at the current head."
  @spec snapshot(EchoData.BrandedId.t()) :: Snapshot.t()
  def snapshot(volume_id), do: GenServer.call(via(volume_id), :snapshot)

  @spec head_lsn(EchoData.BrandedId.t()) :: non_neg_integer()
  def head_lsn(volume_id), do: GenServer.call(via(volume_id), :head_lsn)

  @doc "Nudges the Streamer to flush everything above the watermark to the remote now."
  @spec push(EchoData.BrandedId.t()) :: :ok | {:error, :no_remote}
  def push(volume_id), do: GenServer.call(via(volume_id), :push)

  def via(volume_id), do: {:via, Registry, {@registry, volume_id}}

  # --- callbacks ----------------------------------------------------------

  @impl true
  def init(opts) do
    volume_id = Keyword.fetch!(opts, :volume_id)
    dir = Keyword.fetch!(opts, :data_dir)
    {:ok, db} = Store.open(dir)

    remote =
      case Keyword.get(opts, :remote_cfg) do
        nil -> nil
        cfg -> {Keyword.get(opts, :remote_mod, EchoStore.Graft.Remote.Tigris), cfg}
      end

    state = %{
      volume_id: volume_id,
      head_lsn: Store.head_lsn(db),
      db: db,
      table: Keyword.get(opts, :table, volume_id),
      conn: Keyword.get(opts, :conn),
      remote: remote
    }

    # Start the real-time uploader when a remote is configured.
    if remote do
      {mod, cfg} = remote

      {:ok, _} =
        Streamer.start_link(
          volume_id: volume_id,
          db: db,
          remote_mod: mod,
          remote_cfg: cfg,
          conn: state.conn
        )
    end

    # Publish a read context (incl. the remote) under a second Registry key so
    # readers resolve the L1 table, CubDB handle, and remote without a call into
    # this process — reads stay lock-free.
    {:ok, _} =
      Registry.register(
        @registry,
        {:ctx, volume_id},
        Map.take(state, [:volume_id, :db, :table, :conn, :remote])
      )

    {:ok, state}
  end

  @impl true
  def handle_call(:head_lsn, _from, s), do: {:reply, s.head_lsn, s}

  def handle_call(:snapshot, _from, s),
    do: {:reply, %Snapshot{volume_id: s.volume_id, lsn: s.head_lsn}, s}

  def handle_call(:push, _from, %{remote: nil} = s), do: {:reply, {:error, :no_remote}, s}

  def handle_call(:push, _from, s) do
    Streamer.commit_ready(s.volume_id, s.head_lsn)
    {:reply, :ok, s}
  end

  def handle_call({:commit, base_lsn, staged}, _from, %{head_lsn: head} = s) do
    cond do
      base_lsn != head ->
        # OCC validation failed: the base snapshot is no longer the latest.
        {:reply, {:error, {:conflict, head}}, s}

      staged == %{} ->
        {:reply, {:ok, head}, s}

      true ->
        lsn = head + 1

        commit = %Commit{
          lsn: lsn,
          id: Id.commit(),
          segment_id: Id.segment(),
          pages: staged |> Map.keys() |> PageSet.from_list(),
          ts: System.os_time(:millisecond)
        }

        case Store.append(s.db, commit, staged) do
          :ok ->
            write_through_l1(s.table, staged, commit.id)
            if s.remote, do: Streamer.commit_ready(s.volume_id, lsn)
            {:reply, {:ok, lsn}, %{s | head_lsn: lsn}}

          {:error, _} = err ->
            {:reply, err, s}
        end
    end
  end

  # --- internals ----------------------------------------------------------

  # Write-through the L1: each head page, versioned by the commit id. The id's
  # snowflake suffix is monotonic in commit order (single writer), so newer-wins
  # coherence on the L1 orders correctly.
  defp write_through_l1(table, staged, <<_::binary-14>> = version) do
    Enum.each(staged, fn {idx, bin} ->
      EchoStore.Table.put(table, {:page, idx}, bin, version)
    end)
  end
end
