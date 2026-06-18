defmodule EchoStore.Graft.SyncPoint do
  @moduledoc """
  The replication coordination point for a volume, modeled on Graft's `SyncPoint`
  (graft.rs/docs/internals): it tracks how far the local log has been **pushed** to
  the remote (`local_watermark`) and how far the remote has been **pulled** into the
  local view (`remote`). Snapshots are built from the current SyncPoint, so a reader's
  view is consistent across the replication boundary.

  This hardens `EchoStore.Graft` for EchoMQ 4+: the commit-log-as-outbox (ADR-A) needs
  the committer to drain a log whose pushed/pulled frontier is explicit, not implied by
  "the streamer fired on commit". `head_lsn` (owned by `VolumeServer`) is the local head;
  the SyncPoint is the durable frontier beneath it.
  """
  alias EchoData.BrandedId

  @enforce_keys [:volume_id]
  defstruct volume_id: nil, local_watermark: 0, remote: 0

  @type t :: %__MODULE__{
          volume_id: BrandedId.t(),
          local_watermark: non_neg_integer(),
          remote: non_neg_integer()
        }

  @spec new(BrandedId.t()) :: t()
  def new(volume_id) when is_binary(volume_id), do: %__MODULE__{volume_id: volume_id}

  @doc "Mark the local log pushed up to `lsn` (monotonic; never moves backward)."
  @spec advance_local(t(), non_neg_integer()) :: t()
  def advance_local(%__MODULE__{} = sp, lsn) when is_integer(lsn) and lsn >= 0,
    do: %{sp | local_watermark: max(sp.local_watermark, lsn)}

  @doc "Mark the remote log pulled up to `lsn` (monotonic)."
  @spec advance_remote(t(), non_neg_integer()) :: t()
  def advance_remote(%__MODULE__{} = sp, lsn) when is_integer(lsn) and lsn >= 0,
    do: %{sp | remote: max(sp.remote, lsn)}

  @doc "True when everything the local head holds has reached the remote."
  @spec synced?(t(), head_lsn :: non_neg_integer()) :: boolean()
  def synced?(%__MODULE__{local_watermark: w}, head_lsn), do: w >= head_lsn

  @doc "How many local commits are not yet pushed (the committer/streamer backlog)."
  @spec unsynced(t(), head_lsn :: non_neg_integer()) :: non_neg_integer()
  def unsynced(%__MODULE__{local_watermark: w}, head_lsn), do: max(head_lsn - w, 0)
end
