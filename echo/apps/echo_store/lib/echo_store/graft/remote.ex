defmodule EchoStore.Graft.Remote do
  @moduledoc """
  The durable remote for a Graft Volume — Graft's object-storage tier. The real
  Graft stores segments at `/segments/{SegmentId}` and commits at
  `/logs/{LogId}/commits/{LSN}`, committing with a conditional write. This
  behaviour is that contract; `EchoStore.Graft.Remote.Tigris` is the native-BEAM
  implementation over Tigris S3.

  A `put_commit/4` that returns `:conflict` is the object-store CAS firing: a
  commit object already exists at that LSN, so the write lost the race. With one
  writer per Volume that never happens; with several writers it is how they
  serialize without a coordinator.
  """
  @type cfg :: term()
  @type vol :: EchoData.BrandedId.t()

  @callback put_segment(cfg, vol, EchoData.BrandedId.t(), binary()) :: :ok | {:error, term()}
  @callback get_segment(cfg, vol, EchoData.BrandedId.t()) :: {:ok, binary()} | :absent | {:error, term()}
  @callback put_commit(cfg, vol, non_neg_integer(), binary()) :: :ok | :conflict | {:error, term()}
  @callback list_commits(cfg, vol, non_neg_integer()) :: {:ok, [non_neg_integer()]} | {:error, term()}
end
