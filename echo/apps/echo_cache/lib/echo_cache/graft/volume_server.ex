defmodule EchoCache.Graft.VolumeServer do
  @moduledoc """
  The single writer for one Volume. Graft serializes commits with "a global write
  lock ensuring commits execute one at a time" (graft.rs); on the BEAM that lock
  is this process's mailbox — commits are `handle_call`s, so they run one at a
  time by construction, with no lock primitive. Reads never touch this process:
  they go straight to the L1 (`EchoCache.Table`, a lock-free `read_concurrency`
  ETS table) or to CubDB's zero-cost snapshots (see `EchoCache.Graft.Reader`).

  State:

    * `volume_id`  — the `VOL` GID
    * `head_lsn`   — the current head (monotonic, this process owns it)
    * `db`         — the CubDB store (`EchoCache.Graft.Store`)
    * `table`      — the L1 table name (`EchoCache.Table`) used as the head cache
    * `conn`       — the EchoMQ connector for replication (may be `nil` on a
                     standalone Volume)
  """
  use GenServer

  alias EchoData.Graft.{Id, Commit, Segment, PageSet, Snapshot}
  alias EchoCache.Graft.{Store, Sync}

  @registry EchoCache.Graft.Registry

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

  @doc "Pushes everything above the SyncPoint's local watermark to the remote, as one rolled-up Segment."
  @spec push(EchoData.BrandedId.t()) :: :ok | {:error, term()}
  def push(volume_id), do: GenServer.call(via(volume_id), :push)

  def via(volume_id), do: {:via, Registry, {@registry, volume_id}}

  # --- callbacks ----------------------------------------------------------

  @impl true
  def init(opts) do
    volume_id = Keyword.fetch!(opts, :volume_id)
    dir = Keyword.fetch!(opts, :data_dir)
    {:ok, db} = Store.open(dir)

    state = %{
      volume_id: volume_id,
      head_lsn: Store.head_lsn(db),
      db: db,
      table: Keyword.get(opts, :table, volume_id),
      conn: Keyword.get(opts, :conn)
    }

    # Publish a read context under a second Registry key so readers resolve the
    # L1 table + CubDB handle without a call into this process (lock-free reads).
    {:ok, _} =
      Registry.register(
        EchoCache.Graft.Registry,
        {:ctx, volume_id},
        Map.take(state, [:volume_id, :db, :table, :conn])
      )

    {:ok, state}
  end

  @impl true
  def handle_call(:head_lsn, _from, s), do: {:reply, s.head_lsn, s}

  def handle_call(:snapshot, _from, s),
    do: {:reply, %Snapshot{volume_id: s.volume_id, lsn: s.head_lsn}, s}

  def handle_call({:commit, base_lsn, staged}, _from, %{head_lsn: head} = s) do
    cond do
      base_lsn != head ->
        # OCC validation failed: the base snapshot is no longer the latest.
        {:reply, {:error, {:conflict, head}}, s}

      staged == %{} ->
        {:reply, {:ok, head}, s}

      true ->
        lsn = head + 1
        seg_id = Id.segment()

        commit = %Commit{
          lsn: lsn,
          id: Id.commit(),
          segment_id: seg_id,
          pages: staged |> Map.keys() |> PageSet.from_list(),
          ts: System.os_time(:millisecond)
        }

        case Store.append(s.db, commit, staged) do
          :ok ->
            write_through_l1(s.table, staged, commit.id)
            announce(s, commit)
            {:reply, {:ok, lsn}, %{s | head_lsn: lsn}}

          {:error, _} = err ->
            {:reply, err, s}
        end
    end
  end

  def handle_call(:push, _from, %{conn: nil} = s), do: {:reply, {:error, :no_conn}, s}

  def handle_call(:push, _from, s) do
    sp = Store.get_syncpoint(s.db)
    from_lsn = sp.local_watermark + 1

    if from_lsn > s.head_lsn do
      {:reply, :ok, s}
    else
      # Rollup: fold the LSN range into one Segment carrying the latest version
      # of each touched page, then ship it and advance the watermark.
      staged = rollup_pages(s.db, from_lsn, s.head_lsn)
      seg = Segment.build(Id.segment(), s.head_lsn, staged)

      notice = %Commit{
        lsn: s.head_lsn,
        id: Id.commit(),
        segment_id: seg.id,
        pages: seg.pages,
        ts: System.os_time(:millisecond)
      }

      case Sync.push(s.conn, s.volume_id, seg, notice) do
        :ok ->
          Store.put_syncpoint(s.db, %{sp | local_watermark: s.head_lsn})
          {:reply, :ok, s}

        err ->
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
      EchoCache.Table.put(table, {:page, idx}, bin, version)
    end)
  end

  # Announce the commit on the bus so replicas can invalidate stale head pages
  # and learn the new LSN. Data is shipped by `push/1` (rollup). No-op when the
  # Volume has no connector (standalone).
  defp announce(%{conn: nil}, _commit), do: :ok

  defp announce(%{conn: conn, volume_id: volume_id}, commit),
    do: Sync.announce(conn, volume_id, commit)

  defp rollup_pages(db, from_lsn, to_lsn) do
    db
    |> Store.commits(from_lsn, to_lsn)
    |> Enum.reduce(%{}, fn {{:commit, clsn}, %Commit{pages: pages}}, acc ->
      Enum.reduce(PageSet.to_list(pages), acc, fn idx, acc ->
        case Store.page_at(db, idx, clsn) do
          {:ok, bin} -> Map.put(acc, idx, bin)
          :absent -> acc
        end
      end)
    end)
  end
end
