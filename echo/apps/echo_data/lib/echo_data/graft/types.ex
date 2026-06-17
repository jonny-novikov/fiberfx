defmodule EchoData.Graft.Commit do
  @moduledoc """
  One entry in a Volume's log. `lsn` is the Volume-local monotonic version the
  single writer assigns; `id` is the global `CMT` GID; `segment_id` names the
  Segment carrying this commit's pages; `pages` is the set of page indices the
  commit touched.
  """
  @enforce_keys [:lsn, :id, :segment_id, :pages]
  defstruct [:lsn, :id, :segment_id, :pages, :ts]

  @type t :: %__MODULE__{
          lsn: non_neg_integer(),
          id: EchoData.BrandedId.t(),
          segment_id: EchoData.BrandedId.t(),
          pages: EchoData.Graft.PageSet.t(),
          ts: integer() | nil
        }
end

defmodule EchoData.Graft.Snapshot do
  @moduledoc """
  An immutable view of a Volume at an LSN. `index` resolves a page index to the
  `{lsn, segment_id}` that last wrote it at or below this snapshot — the lookup
  the reader uses to find which Segment to fetch. The struct holds no process
  state and no locks, so any number of readers share it concurrently.
  """
  @enforce_keys [:volume_id, :lsn]
  defstruct [:volume_id, :lsn, index: %{}]

  @type t :: %__MODULE__{
          volume_id: EchoData.BrandedId.t(),
          lsn: non_neg_integer(),
          index: %{optional(non_neg_integer()) => {non_neg_integer(), EchoData.BrandedId.t()}}
        }

  @doc "Resolves which Segment holds `page_idx` at or below this snapshot."
  @spec segment_for(t, non_neg_integer()) :: {:ok, EchoData.BrandedId.t()} | :absent
  def segment_for(%__MODULE__{index: index}, page_idx) do
    case Map.get(index, page_idx) do
      {_lsn, segment_id} -> {:ok, segment_id}
      nil -> :absent
    end
  end
end

defmodule EchoData.Graft.SyncPoint do
  @moduledoc """
  The local↔remote replication cursor. `local_watermark` is the highest local
  LSN pushed to remote; `remote` is the highest remote LSN pulled locally. New
  snapshots are built from the current SyncPoint, so reads stay consistent
  across the replication boundary.
  """
  defstruct local_watermark: 0, remote: 0

  @type t :: %__MODULE__{local_watermark: non_neg_integer(), remote: non_neg_integer()}
end
