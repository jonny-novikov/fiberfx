defmodule EchoCache.Graft.Sync do
  @moduledoc """
  Replication over the EchoMQ bus. Graft's object-storage remote becomes, on the
  mesh, a durable shared store reached through the RESP3 connector
  (`EchoMQ.Connector`): segments are SET as blobs, commit notices are PUBLISHed
  on a per-Volume channel, and replicas SUBSCRIBE to learn of new commits and
  GET segment frames on demand.

  Only the verified connector surface is used: `command/3` for `SET`/`GET`/
  `PUBLISH`, and `subscribe/2`, whose out-of-band pushes arrive at the subscribed
  process as `{:emq_push, ["message", channel, payload]}` — the same envelope
  `EchoCache.Table` already consumes for coherence.
  """
  alias EchoData.Graft.{Segment, Commit, PageSet}
  alias EchoData.BrandedId

  @type conn :: GenServer.server()

  @doc "PUSH: store the Segment blob, then announce the commit to replicas."
  @spec push(conn, BrandedId.t(), Segment.t(), Commit.t()) :: :ok | {:error, term()}
  def push(conn, volume_id, %Segment{} = seg, %Commit{} = commit) do
    with {:ok, _} <- EchoMQ.Connector.command(conn, ["SET", segment_key(volume_id, seg.id), Segment.encode(seg)]),
         {:ok, _} <- EchoMQ.Connector.command(conn, ["PUBLISH", commits_channel(volume_id), encode_notice(commit)]) do
      :ok
    end
  end

  @doc """
  ANNOUNCE: publish a commit notice only, without uploading a Segment. Replicas
  use it to invalidate stale head pages in their L1 immediately and to learn
  which LSNs exist; the Segment data becomes fetchable once `push/4` has run.
  """
  @spec announce(conn, BrandedId.t(), Commit.t()) :: :ok | {:error, term()}
  def announce(conn, volume_id, %Commit{} = commit) do
    case EchoMQ.Connector.command(conn, ["PUBLISH", commits_channel(volume_id), encode_notice(commit)]) do
      {:ok, _} -> :ok
      other -> normalize_error(other)
    end
  end

  @doc "FETCH: GET a remote Segment frame on demand — the partial-replication read path."
  @spec fetch_segment(conn, BrandedId.t(), BrandedId.t(), non_neg_integer()) ::
          {:ok, Segment.t()} | :absent | {:error, term()}
  def fetch_segment(conn, volume_id, segment_id, lsn) do
    case EchoMQ.Connector.command(conn, ["GET", segment_key(volume_id, segment_id)]) do
      {:ok, blob} when is_binary(blob) -> {:ok, Segment.decode(blob, segment_id, lsn)}
      {:ok, nil} -> :absent
      other -> normalize_error(other)
    end
  end

  @doc "Subscribe to a Volume's commit channel; notices arrive as `{:emq_push, ...}`."
  @spec subscribe_commits(conn, BrandedId.t()) :: :ok | {:error, term()}
  def subscribe_commits(conn, volume_id),
    do: EchoMQ.Connector.subscribe(conn, commits_channel(volume_id))

  @doc """
  Decodes a commit notice delivered on the bus into `{lsn, commit_id, segment_id,
  page_set}`. A replica uses it to invalidate touched pages in its L1 and to know
  which LSNs to pull.
  """
  @spec decode_notice(binary()) :: {non_neg_integer(), BrandedId.t(), BrandedId.t(), PageSet.t()}
  def decode_notice(<<lsn::64, cid::binary-14, sid::binary-14, pages::binary>>),
    do: {lsn, cid, sid, PageSet.decode(pages)}

  # --- wire helpers -------------------------------------------------------
  defp encode_notice(%Commit{lsn: lsn, id: cid, segment_id: sid, pages: pages}),
    do: <<lsn::64, cid::binary-14, sid::binary-14, PageSet.encode(pages)::binary>>

  defp segment_key(volume_id, segment_id), do: "graft:" <> volume_id <> ":seg:" <> segment_id
  defp commits_channel(volume_id), do: "graft:" <> volume_id <> ":commits"

  defp normalize_error({:error, _} = e), do: e
  defp normalize_error(other), do: {:error, other}
end
