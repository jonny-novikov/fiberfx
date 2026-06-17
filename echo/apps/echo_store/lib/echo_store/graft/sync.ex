defmodule EchoStore.Graft.Sync do
  @moduledoc """
  The low-latency notification layer over the EchoMQ bus. Durable data now lives
  on the remote object store (`EchoStore.Graft.Remote` → Tigris); the bus carries
  only commit *notices*, so a replica learns of a new LSN immediately and can
  pull it and invalidate stale head pages, while the bytes travel via Tigris.

  Only the verified connector surface is used: `command/3` for `PUBLISH`, and
  `subscribe/2`, whose out-of-band pushes arrive as
  `{:emq_push, ["message", channel, payload]}` — the same envelope
  `EchoStore.Table` already consumes for coherence.
  """
  alias EchoData.Graft.{Commit, PageSet}
  alias EchoData.BrandedId

  @type conn :: GenServer.server()

  @doc "Announce a commit on the Volume's channel (a notice, not the data)."
  @spec publish_notice(conn, BrandedId.t(), Commit.t()) :: :ok | {:error, term()}
  def publish_notice(conn, volume_id, %Commit{} = commit) do
    case EchoMQ.Connector.command(conn, ["PUBLISH", commits_channel(volume_id), encode_notice(commit)]) do
      {:ok, _} -> :ok
      {:error, _} = e -> e
      other -> {:error, other}
    end
  end

  @doc "Subscribe to a Volume's commit channel; notices arrive as `{:emq_push, ...}`."
  @spec subscribe_commits(conn, BrandedId.t()) :: :ok | {:error, term()}
  def subscribe_commits(conn, volume_id),
    do: EchoMQ.Connector.subscribe(conn, commits_channel(volume_id))

  @doc "Decodes a notice into `{lsn, commit_id, segment_id, page_set}`."
  @spec decode_notice(binary()) :: {non_neg_integer(), BrandedId.t(), BrandedId.t(), PageSet.t()}
  def decode_notice(<<lsn::64, cid::binary-14, sid::binary-14, pages::binary>>),
    do: {lsn, cid, sid, PageSet.decode(pages)}

  defp encode_notice(%Commit{lsn: lsn, id: cid, segment_id: sid, pages: pages}),
    do: <<lsn::64, cid::binary-14, sid::binary-14, PageSet.encode(pages)::binary>>

  defp commits_channel(volume_id), do: "graft:" <> volume_id <> ":commits"
end
