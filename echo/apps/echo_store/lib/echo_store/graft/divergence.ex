defmodule EchoStore.Graft.Divergence do
  @moduledoc """
  Graft's pull step refuses to merge when both local and remote advanced independently —
  "divergence requires manual intervention" (graft.rs/docs/internals#pull). This guard
  makes that explicit for `EchoStore.Graft.Sync`: given a `SyncPoint` and the observed
  local/remote heads, it returns `:ok` only when at most one side moved past the synced
  frontier. Divergence is reported, never resolved by guessing — consistent with the BCS
  newer-wins/no-silent-merge stance and EchoMQ's at-least-once-with-idempotency contract.
  """
  alias EchoData.Graft.SyncPoint

  @spec check(SyncPoint.t(), local_head :: non_neg_integer(), remote_head :: non_neg_integer()) ::
          :ok
          | {:fast_forward, :remote, non_neg_integer()}
          | {:error, {:diverged, local :: non_neg_integer(), remote :: non_neg_integer()}}
  def check(%SyncPoint{local_watermark: lw, remote: r}, local_head, remote_head) do
    local_ahead = local_head > lw
    remote_ahead = remote_head > r

    cond do
      local_ahead and remote_ahead -> {:error, {:diverged, local_head, remote_head}}
      remote_ahead -> {:fast_forward, :remote, remote_head}
      true -> :ok
    end
  end
end
