defmodule EchoStore.Graft.Epoch do
  @moduledoc """
  A monotonic **fencing token** for a volume. Graft serializes commits with a global
  write lock and detects remote conflicts with a conditional write to
  `/logs/{LogId}/commits/{LSN}`. `EchoStore.Graft.VolumeServer` serializes locally via
  its single-writer mailbox — but a *restarted or partitioned* writer could resurrect as
  a second owner and double-append. The epoch closes that gap: each time a VolumeServer
  claims a volume it bumps the epoch, the remote records the highest epoch seen, and a
  commit carrying a **stale** epoch is rejected (`{:error, {:fenced, current}}`).

  This is the safety the commit-log-as-outbox (EchoMQ 4+, ADR-A) depends on: an intent
  must be admitted by exactly one writer, so a stale writer cannot re-emit a covered
  intent under a fork.
  """
  @type t :: non_neg_integer()

  @doc "The epoch a freshly claimed volume takes, given the highest epoch the remote has seen."
  @spec claim(remote_epoch :: t()) :: t()
  def claim(remote_epoch) when is_integer(remote_epoch) and remote_epoch >= 0,
    do: remote_epoch + 1

  @doc """
  Fence a commit: accept only when the writer's epoch is the current (highest) one.
  A lower epoch means another writer has since claimed the volume — reject, do not merge.
  """
  @spec fence(writer_epoch :: t(), current_epoch :: t()) ::
          :ok | {:error, {:fenced, t()}}
  def fence(writer, current) when writer == current, do: :ok
  def fence(_writer, current), do: {:error, {:fenced, current}}
end
