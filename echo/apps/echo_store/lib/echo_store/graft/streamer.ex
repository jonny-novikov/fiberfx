defmodule EchoStore.Graft.Streamer do
  @moduledoc """
  The native, real-time replacement for the Litestream sidecar. One Streamer per
  Volume continuously ships everything above the SyncPoint's local watermark to
  the remote (Tigris), as rolled-up Segments plus conditional commit objects,
  then advances the watermark and announces the commit on the EchoMQ bus.

  Where Litestream spawned an external binary and restarted it with a linear
  backoff, this is a supervised BEAM process: a commit triggers an immediate
  drain (`commit_ready/2`), failures retry with capped exponential backoff, and
  because the commits already live durably in CubDB, a crash simply resumes from
  the watermark on restart — no replay coordination, no lost writes.

  State: `%{vol, db, remote_mod, remote_cfg, conn, backoff}`.
  """
  use GenServer
  require Logger

  alias EchoData.Graft.{Id, Commit, Segment, PageSet}
  alias EchoStore.Graft.{Store, Sync}

  @registry EchoStore.Graft.Registry
  @backoff_floor 200
  @backoff_ceil 30_000

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) do
    vol = Keyword.fetch!(opts, :volume_id)
    GenServer.start_link(__MODULE__, opts, name: via(vol))
  end

  @doc "Signal that a new commit is durable locally; triggers an immediate drain."
  @spec commit_ready(EchoData.BrandedId.t(), non_neg_integer()) :: :ok
  def commit_ready(vol, lsn), do: GenServer.cast(via(vol), {:commit_ready, lsn})

  def via(vol), do: {:via, Registry, {@registry, {:streamer, vol}}}

  @impl true
  def init(opts) do
    state = %{
      vol: Keyword.fetch!(opts, :volume_id),
      db: Keyword.fetch!(opts, :db),
      remote_mod: Keyword.get(opts, :remote_mod, EchoStore.Graft.Remote.Tigris),
      remote_cfg: Keyword.fetch!(opts, :remote_cfg),
      conn: Keyword.get(opts, :conn),
      backoff: 0
    }

    # Catch up anything not yet streamed (crash-safe resume from the watermark).
    send(self(), :drain)
    {:ok, state}
  end

  @impl true
  def handle_cast({:commit_ready, _lsn}, s) do
    send(self(), :drain)
    {:noreply, s}
  end

  @impl true
  def handle_info(:drain, s) do
    sp = Store.get_syncpoint(s.db)
    from = sp.local_watermark + 1
    head = Store.head_lsn(s.db)

    if from > head do
      {:noreply, %{s | backoff: 0}}
    else
      case stream_range(s, sp, from, head) do
        :ok ->
          # advanced; keep draining in case more arrived during the upload
          send(self(), :drain)
          {:noreply, %{s | backoff: 0}}

        {:error, reason} ->
          b = next_backoff(s.backoff)
          Logger.warning("graft streamer #{inspect(s.vol)} → tigris failed (#{inspect(reason)}); retry in #{b}ms")
          Process.send_after(self(), :drain, b)
          {:noreply, %{s | backoff: b}}
      end
    end
  end

  def handle_info(_msg, s), do: {:noreply, s}

  # Roll the LSN range up into one Segment, ship it, write the conditional commit
  # object, advance the watermark, and announce on the bus.
  defp stream_range(s, sp, from, head) do
    staged = rollup(s.db, from, head)
    seg = Segment.build(Id.segment(), head, staged)

    commit = %Commit{
      lsn: head,
      id: Id.commit(),
      segment_id: seg.id,
      pages: seg.pages,
      ts: System.os_time(:millisecond)
    }

    with :ok <- s.remote_mod.put_segment(s.remote_cfg, s.vol, seg.id, Segment.encode(seg)),
         commit_result when commit_result in [:ok, :conflict] <-
           s.remote_mod.put_commit(s.remote_cfg, s.vol, head, encode_commit(commit)) do
      # :conflict means another writer already holds this LSN remotely — the
      # range is covered either way, so the watermark advances.
      :ok = Store.put_syncpoint(s.db, %{sp | local_watermark: head})
      if s.conn, do: Sync.publish_notice(s.conn, s.vol, commit)
      :ok
    else
      {:error, _} = err -> err
      other -> {:error, other}
    end
  end

  defp rollup(db, from, to) do
    db
    |> Store.commits(from, to)
    |> Enum.reduce(%{}, fn {{:commit, clsn}, %Commit{pages: pages}}, acc ->
      Enum.reduce(PageSet.to_list(pages), acc, fn idx, acc ->
        case Store.page_at(db, idx, clsn) do
          {:ok, bin} -> Map.put(acc, idx, bin)
          :absent -> acc
        end
      end)
    end)
  end

  defp encode_commit(%Commit{lsn: lsn, id: id, segment_id: sid, pages: pages}),
    do: <<lsn::64, id::binary-14, sid::binary-14, PageSet.encode(pages)::binary>>

  defp next_backoff(0), do: @backoff_floor
  defp next_backoff(b), do: min(b * 2, @backoff_ceil)
end
