defmodule EchoStore.Coherence do
  @moduledoc """
  The coherence vocabulary of Part IV: a message about a name.

  An invalidation carries exactly two identities — the cached name and the
  writer's mint-time version — and nothing else. Newer wins by comparing
  the snowflake payloads of two branded ids: the order theorem makes the
  eleven payload bytes lexicographically equal to mint order, regardless
  of namespace, so coherence needs no coordinator, no lock, and no clock
  but the one already inside every id.

  Two lanes carry the same payload. The broadcast lane is a PUBLISH on the
  table's channel — fire-and-forget, one wire hop, for surfaces where a
  lost message costs one TTL of staleness. The job lane is an enqueue on
  the table's coherence queue over EchoMQ — at-least-once, crash-surviving,
  for surfaces where a stale read costs money. Application is idempotent
  by construction: applying the same version twice is a comparison that
  answers stale the second time.
  """

  alias EchoStore.Keyspace
  alias EchoData.BrandedId
  alias EchoMQ.{Connector, Lanes, Script}

  @doc "The broadcast channel of one table's coherence lane."
  @spec channel(binary()) :: binary()
  def channel(table) when is_binary(table), do: "ecc:{" <> table <> "}:coh"

  @doc "The job queue of one table's coherence lane."
  @spec queue(binary()) :: binary()
  def queue(table) when is_binary(table), do: "ecc.coh." <> table

  @doc "The message: two names, twenty-nine bytes, nothing else."
  @spec payload(binary(), binary()) :: binary()
  def payload(<<_::binary-14>> = id, <<_::binary-14>> = version), do: id <> ":" <> version

  @spec parse(binary()) :: {:ok, binary(), binary()} | :error
  def parse(<<id::binary-14, ":", version::binary-14>>) do
    if BrandedId.valid?(id) and BrandedId.valid?(version),
      do: {:ok, id, version},
      else: :error
  end

  def parse(_), do: :error

  @doc """
  Mint-order comparison across kinds: true when `a` was minted after `b`.
  Compares the eleven-byte snowflake payloads — the order theorem's
  lexicographic-equals-chronological property — ignoring the namespaces.
  """
  @spec newer?(binary(), binary()) :: boolean()
  def newer?(<<_::binary-3, pa::binary-11>>, <<_::binary-3, pb::binary-11>>), do: pa > pb

  @drop Script.new(:coherence_drop, """
        local cur = redis.call('GET', KEYS[1])
        if not cur then return 0 end
        if #cur < 14 then
          redis.call('DEL', KEYS[1])
          return 1
        end
        if string.sub(ARGV[1], 4, 14) > string.sub(cur, 4, 14) then
          redis.call('DEL', KEYS[1])
          return 1
        end
        return 0
        """)

  @doc """
  Conditionally drop the L2 row: deleted only when `version` is newer than
  the version framed into the stored value — one transition, one script,
  so a late stale invalidation can never erase a newer row.
  """
  @spec drop_l2(GenServer.server(), binary(), binary(), binary()) ::
          {:ok, 0 | 1} | {:error, term()}
  def drop_l2(conn, table, id, version) do
    Connector.eval(conn, @drop, [Keyspace.key(table, id)], [version])
  end

  @doc "The broadcast lane: fire-and-forget, returns the receiver count."
  @spec broadcast(GenServer.server(), binary(), binary(), binary()) ::
          {:ok, integer()} | {:error, term()}
  def broadcast(conn, table, id, version) do
    Connector.command(conn, ["PUBLISH", channel(table), payload(id, version)])
  end

  @doc "The job lane: at-least-once over EchoMQ's fair lanes."
  @spec enqueue(GenServer.server(), binary(), binary(), binary(), binary()) ::
          {:ok, :enqueued | :duplicate} | {:error, term()}
  def enqueue(conn, table, group, id, version) do
    Lanes.enqueue(conn, queue(table), group, BrandedId.generate!("JOB"), payload(id, version))
  end
end
