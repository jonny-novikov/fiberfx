defmodule EchoStore.GraftBackend.Proto do
  @moduledoc """
  The byte-frozen `echo_graft_proto` wire, BEAM side (eg.4).

  `EchoStore.GraftBackend` drives the Rust page-engine (`echo_graft_backend`) over EchoMQ. This
  module is the Elixir half of the cross-runtime contract: it builds each protocol message as a
  flat RESP3 array of bulk strings via the real `EchoMQ.RESP` codec, byte-identical to the Rust
  `echo_graft_proto` crate. A shared fixture set
  (`test/fixtures/graft_backend/wire.fixtures`, mirrored byte-identical from the proto crate) is
  asserted by both sides' conformance tests — neither side owns its own truth.

  This is a coexisting **peer** to the native `EchoStore.Graft.*` engine; it neither touches nor
  wraps it. The eg.3 `FeedEvent` rides as an opaque bilrost blob — this module never inspects it.

  Messages are tagged tuples mirroring the Rust `Msg` enum; see `parts/1` for the full set.
  """

  alias EchoMQ.RESP

  @proto_min 1
  @proto_max 1

  @doc "The lowest protocol version this build speaks."
  @spec proto_min() :: pos_integer()
  def proto_min, do: @proto_min

  @doc "The highest protocol version this build speaks."
  @spec proto_max() :: pos_integer()
  def proto_max, do: @proto_max

  @typedoc "The closed error taxonomy carried by an `:err` message (a new kind is a version bump)."
  @type err_kind :: :conflict | :not_found | :version_mismatch | :unavailable

  @err_tokens %{
    conflict: "conflict",
    not_found: "not_found",
    version_mismatch: "version_mismatch",
    unavailable: "unavailable"
  }

  @doc "The wire token for an error kind."
  @spec err_token(err_kind()) :: binary()
  def err_token(kind) when is_atom(kind), do: Map.fetch!(@err_tokens, kind)

  @doc """
  Encode a message tuple to its frozen RESP3 wire bytes (iodata).

  Pass the result through `IO.iodata_to_binary/1` to compare against a fixture.
  """
  @spec encode(tuple()) :: iodata()
  def encode(msg), do: RESP.encode(parts(msg))

  @doc """
  The flat list of bulk-string parts for a message (tag first) — the input to `EchoMQ.RESP.encode/1`.

  Integers bulk-encode as their decimal ASCII (matching `resp.ex`); an absent optional id is the
  empty string; the feed event's bilrost blob is one opaque bulk string.
  """
  @spec parts(tuple()) :: [binary() | integer()]
  # handshake
  def parts({:hello, proto_min, proto_max, client}), do: ["HELLO", proto_min, proto_max, client]
  def parts({:welcome, proto}), do: ["WELCOME", proto]
  def parts({:incompatible, proto_min, proto_max, reason}), do: ["INCOMPAT", proto_min, proto_max, reason]
  # requests
  def parts({:open_volume, corr, branded, local, remote}), do: ["OPEN", corr, branded, local || "", remote || ""]
  def parts({:resolve_branded, corr, branded}), do: ["RESOLVE", corr, branded]

  def parts({:commit, corr, vid, base, pages}) do
    ["COMMIT", corr, vid, base, length(pages) | Enum.flat_map(pages, fn {idx, data} -> [idx, data] end)]
  end

  def parts({:push, corr, vid}), do: ["PUSH", corr, vid]
  def parts({:pull, corr, vid}), do: ["PULL", corr, vid]
  def parts({:read, corr, vid, pageidx}), do: ["READ", corr, vid, pageidx]
  def parts({:snapshot, corr, vid}), do: ["SNAP", corr, vid]
  def parts({:get_commit, corr, log, lsn}), do: ["GETCOMMIT", corr, log, lsn]
  # responses
  def parts({:ack, corr, lsn}), do: ["ACK", corr, lsn]
  def parts({:pages, corr, data}), do: ["PAGES", corr, data]
  def parts({:snapshot_resp, corr, lsn, pages}), do: ["SNAPRESP", corr, lsn, pages]
  def parts({:err, corr, kind, detail}), do: ["ERR", corr, err_token(kind), detail]
  # feed (publish-only)
  def parts({:feed, blob}), do: ["FEED", blob]

  @doc """
  Decode wire `parts` (the flat list `EchoMQ.RESP.parse/1` yields for a frame — tag first,
  every field a binary) back into a message tuple, the inverse of `parts/1`.

  Integers arrive as their decimal-ASCII bulk strings and are parsed back; an absent optional
  id is the empty string (`nil` in the tuple); the feed blob stays an opaque binary. Mirrors
  the Rust `Msg::from_parts` exactly — the same closed tag set, the same arities.

  Returns `{:ok, msg}` or `{:error, reason}` (`:empty`, `{:unknown_tag, tag}`,
  `{:bad_field, name}`, `{:bad_arity, tag}`) — never raises on malformed input.
  """
  @spec decode([binary()]) :: {:ok, tuple()} | {:error, term()}
  def decode([]), do: {:error, :empty}
  def decode([tag | rest]), do: from_parts(tag, rest)

  # handshake
  defp from_parts("HELLO", [pmin, pmax, client]),
    do: with_ints([pmin, pmax], fn [a, b] -> {:hello, a, b, client} end)

  defp from_parts("WELCOME", [proto]),
    do: with_ints([proto], fn [p] -> {:welcome, p} end)

  defp from_parts("INCOMPAT", [pmin, pmax, reason]),
    do: with_ints([pmin, pmax], fn [a, b] -> {:incompatible, a, b, reason} end)

  # requests
  defp from_parts("OPEN", [corr, branded, local, remote]),
    do: with_ints([corr], fn [c] -> {:open_volume, c, branded, blank_to_nil(local), blank_to_nil(remote)} end)

  defp from_parts("RESOLVE", [corr, branded]),
    do: with_ints([corr], fn [c] -> {:resolve_branded, c, branded} end)

  defp from_parts("COMMIT", [corr, vid, base, npages | tail]) do
    with_ints([corr, base, npages], fn [c, b, n] ->
      pages = decode_pages(tail, n)
      if pages == :error, do: {:error, {:bad_field, "pages_count"}}, else: {:commit, c, vid, b, pages}
    end)
    |> unwrap_nested()
  end

  defp from_parts("PUSH", [corr, vid]), do: with_ints([corr], fn [c] -> {:push, c, vid} end)
  defp from_parts("PULL", [corr, vid]), do: with_ints([corr], fn [c] -> {:pull, c, vid} end)

  defp from_parts("READ", [corr, vid, pageidx]),
    do: with_ints([corr, pageidx], fn [c, p] -> {:read, c, vid, p} end)

  defp from_parts("SNAP", [corr, vid]), do: with_ints([corr], fn [c] -> {:snapshot, c, vid} end)

  defp from_parts("GETCOMMIT", [corr, log, lsn]),
    do: with_ints([corr, lsn], fn [c, l] -> {:get_commit, c, log, l} end)

  # responses
  defp from_parts("ACK", [corr, lsn]), do: with_ints([corr, lsn], fn [c, l] -> {:ack, c, l} end)
  defp from_parts("PAGES", [corr, data]), do: with_ints([corr], fn [c] -> {:pages, c, data} end)

  defp from_parts("SNAPRESP", [corr, lsn, pages]),
    do: with_ints([corr, lsn, pages], fn [c, l, p] -> {:snapshot_resp, c, l, p} end)

  defp from_parts("ERR", [corr, kind, detail]) do
    case err_kind(kind) do
      {:ok, k} -> with_ints([corr], fn [c] -> {:err, c, k, detail} end)
      :error -> {:error, {:bad_field, "err_kind"}}
    end
  end

  # feed (publish-only)
  defp from_parts("FEED", [blob]), do: {:ok, {:feed, blob}}

  defp from_parts(tag, _) when tag in ~w(HELLO WELCOME INCOMPAT OPEN RESOLVE COMMIT PUSH PULL READ SNAP GETCOMMIT ACK PAGES SNAPRESP ERR FEED),
    do: {:error, {:bad_arity, tag}}

  defp from_parts(tag, _), do: {:error, {:unknown_tag, tag}}

  # Parse each named field as an integer; on success apply `build`, else surface :bad_field.
  defp with_ints(fields, build) do
    parsed = Enum.map(fields, &parse_int/1)

    if Enum.any?(parsed, &(&1 == :error)) do
      {:error, {:bad_field, "integer"}}
    else
      {:ok, build.(parsed)}
    end
  end

  defp parse_int(bin) when is_binary(bin) do
    case Integer.parse(bin) do
      {n, ""} when n >= 0 -> n
      _ -> :error
    end
  end

  defp parse_int(_), do: :error

  defp blank_to_nil(""), do: nil
  defp blank_to_nil(s), do: s

  defp decode_pages(tail, n) when length(tail) == n * 2 do
    tail
    |> Enum.chunk_every(2)
    |> Enum.map(fn [idx, data] -> {parse_int(idx), data} end)
    |> then(fn pairs -> if Enum.any?(pairs, fn {i, _} -> i == :error end), do: :error, else: pairs end)
  end

  defp decode_pages(_, _), do: :error

  # COMMIT's builder can itself return an {:error, _}; lift that out of the {:ok, _} wrapper.
  defp unwrap_nested({:ok, {:error, _} = e}), do: e
  defp unwrap_nested(other), do: other

  defp err_kind("conflict"), do: {:ok, :conflict}
  defp err_kind("not_found"), do: {:ok, :not_found}
  defp err_kind("version_mismatch"), do: {:ok, :version_mismatch}
  defp err_kind("unavailable"), do: {:ok, :unavailable}
  defp err_kind(_), do: :error
end
