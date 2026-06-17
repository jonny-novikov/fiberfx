defmodule EchoStore.Graft.Reader do
  @moduledoc """
  Lock-free reads. Nothing here calls the `VolumeServer`; reads run against
  immutable state, so any number of processes read in parallel — Graft's
  lock-free-reads property, native to the BEAM.

  Three paths, cheapest first:

    1. **Head read** — a straight `EchoStore.Table.fetch/3`, i.e. an `:ets.lookup`
       on the L1's `read_concurrency` table. This is the common path on the
       writer node and on any replica that has touched the page.
    2. **Snapshot read** — `EchoStore.Graft.Store.page_at/3` against CubDB's
       zero-cost MVCC snapshot, for reads at a historical LSN (the L1 holds only
       the head version, so older snapshots resolve here).
    3. **Lazy fetch** — when neither has the page (a partial replica that has not
       pulled it), demand-fetch the owning Segment's frame over the bus, cache it
       in the L1, and serve. A page never read is never fetched.
  """
  alias EchoData.Graft.{Snapshot, Segment}
  alias EchoStore.Graft.Store

  @doc "Head read: L1 first, then CubDB head, then lazy fetch."
  @spec get(map(), non_neg_integer()) :: {:ok, binary()} | :absent
  def get(%{table: table, db: db} = ctx, page_idx) do
    case l1_get(table, page_idx) do
      {:ok, bin} ->
        {:ok, bin}

      :miss ->
        head = Store.head_lsn(db)

        case Store.page_at(db, page_idx, head) do
          {:ok, bin} ->
            cache(ctx, page_idx, bin)
            {:ok, bin}

          :absent ->
            lazy_fetch(ctx, %Snapshot{volume_id: ctx.volume_id, lsn: head}, page_idx)
        end
    end
  end

  # The L1 table is `:public` and `read_concurrency: true` by design, so the head
  # read is a direct lock-free `:ets.lookup` — not `EchoStore.Table.fetch/3`,
  # whose miss path fills from L2 (Valkey), which is the wrong miss path for
  # Graft (a Graft miss resolves against CubDB or a remote Segment, below).
  # Row shape is `{id, value, expires_at, version}`.
  defp l1_get(table, page_idx) do
    case :ets.lookup(table, {:page, page_idx}) do
      [{_id, bin, _expires_at, _version}] when is_binary(bin) -> {:ok, bin}
      _ -> :miss
    end
  end

  @doc "Read at a specific Snapshot. CubDB is the multi-version source; lazy fetch backs a miss."
  @spec get_at(map(), Snapshot.t(), non_neg_integer()) :: {:ok, binary()} | :absent
  def get_at(%{db: db} = ctx, %Snapshot{lsn: lsn} = snap, page_idx) do
    case Store.page_at(db, page_idx, lsn) do
      {:ok, bin} -> {:ok, bin}
      :absent -> lazy_fetch(ctx, snap, page_idx)
    end
  end

  # --- lazy partial-replication fetch ------------------------------------
  defp lazy_fetch(%{remote: nil}, _snap, _page_idx), do: :absent

  defp lazy_fetch(%{remote: {mod, cfg}, volume_id: volume_id} = ctx, %Snapshot{} = snap, page_idx) do
    with {:ok, segment_id} <- Snapshot.segment_for(snap, page_idx),
         {:ok, blob} <- mod.get_segment(cfg, volume_id, segment_id),
         %Segment{} = seg <- Segment.decode(blob, segment_id, snap.lsn),
         {:ok, bin} <- Segment.page(seg, page_idx) do
      cache(ctx, page_idx, bin)
      {:ok, bin}
    else
      _ -> :absent
    end
  end

  defp cache(%{table: table}, page_idx, bin) do
    # Versionless cache fill on the read path; the writer supplies versions.
    _ = EchoStore.Table.put(table, {:page, page_idx}, bin)
    :ok
  end
end
