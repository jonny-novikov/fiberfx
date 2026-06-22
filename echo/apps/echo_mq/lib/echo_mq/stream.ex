defmodule EchoMQ.Stream do
  @moduledoc """
  The writer LAW of EchoMQ 3.0's Stream Tier (emq3.2, S1 the writer part 2):
  per-key hash-tagged event streams, branded record ids appended in MINT
  ORDER, wrong-kind refused at the door. A thin host-side ROUTER over the pure
  `EchoMQ.Stream.Id` core (the order math) + the SHIPPED `EchoMQ.Connector`
  (the wire) -- no process, no GenServer, no supervision child, no lease, no
  `TIME`, no Lua. The append is `XADD` issued DIRECT (a no-new-script rung).

  ## The append (`append/4`, the writer's whole point)

  `append(conn, queue, name, fields)`:

    1. MINTS an `EVT`-branded record id host-side
       (`EchoData.Snowflake.next_branded("EVT")`) -- the writer OWNS the mint,
       so there is nothing to spoof (D-2);
    2. derives the EXPLICIT XADD id by field correspondence
       (`Stream.Id.xadd_id/1`, the A1 mapping `"<ms>-<tail22>"`);
    3. issues `XADD <key> <xadd_id> id <branded> <fields…>` through
       `EchoMQ.Connector.command/3` -- the 14-byte branded string stored as the
       stream `id` FIELD (the claims-only contract: a polyglot reader gets the
       canonical id without re-encoding);
    4. returns `{:ok, branded}` -- the branded id IS the receipt;
    5. maps Valkey's `id≤top` rejection to `{:error, :nonmonotonic}`, NEVER
       swallowed, NEVER retried with `*` (the F-A liveness check -- the wire
       telling the truth that an upstream mint-order violation happened).

  ## The order theorem (proven in `EchoMQ.Stream.Id`)

  Stream order == id sort == mint order. Single-writer-per-stream holds it
  EVERY time (the `:atomics` cell is strictly monotone, so successive mints
  are strictly increasing snowflakes → strictly increasing A1 ids → the next
  id always exceeds the stream top, no XADD rejection possible). Multi-writer
  (the parked log-tier-exit seam, or a misconfiguration) surfaces
  `{:error, :nonmonotonic}` honestly. The kind door (`Stream.Id.evt?/1`, one
  brand `EVT`) is what keeps the byte-order ≡ snowflake-order step sound
  (base62 byte order == int order only WITHIN one namespace) -- ADR-1 and
  ADR-2 are JOINED.

  ## The key (ADR-3)

  `emq:{q}:stream:<name>` via the shipped total `EchoMQ.Keyspace.queue_key(q,
  "stream:" <> name)` -- the §6 braced type emq3.1 founded, no grammar edit.
  The stream shares the `{q}` hashtag slot with that queue's keys.

  ## NOT this rung

  `read/3..6` is the MINIMAL un-grouped `XRANGE` read-back (the order-theorem
  proof surface), NOT the consumer group -- `XREADGROUP`/`XACK`/`XAUTOCLAIM`
  and the polyglot seam are emq3.3. Retention (`MAXLEN`/`MINID`) is emq3.4;
  `append/_` does not trim. Multi-writer-per-stream is the parked seam (the
  posture is single-writer; `:nonmonotonic` is surfaced, not BUILT for).
  """

  alias EchoMQ.{Connector, Keyspace}
  alias EchoMQ.Stream.Id

  # the verbatim valkey.io rejection of an explicit id <= the stream top
  # (valkey.io/topics/streams-intro) -- the ONLY error mapped to :nonmonotonic;
  # every other error_reply (e.g. WRONGTYPE) passes through verbatim.
  @id_too_small "ERR The ID specified in XADD is equal or smaller than the target stream top item"

  @typedoc "An XADD field pair list (claims-only -- flat string pairs)."
  @type fields :: [{binary(), binary()}] | [binary()]

  @doc """
  Appends one record to the stream `emq:{q}:stream:<name>`, minting an
  `EVT`-branded record id host-side and appending it under its A1 XADD id.

  Returns `{:ok, branded}` (the receipt), `{:error, :nonmonotonic}` (the
  `id≤top` rejection surfaced -- never swallowed), or `{:error, term}` (any
  other connector/server fault, verbatim). `fields` is a claims-only flat pair
  list (`[{k, v}, …]` or a pre-flattened `[k, v, …]`).
  """
  @spec append(GenServer.server(), binary(), binary(), fields()) ::
          {:ok, binary()} | {:error, :nonmonotonic | term()}
  def append(conn, queue, name, fields)
      when is_binary(queue) and is_binary(name) and is_list(fields) do
    branded = EchoData.Snowflake.next_branded(Id.kind())
    append_id(conn, queue, name, branded, fields)
  end

  @doc """
  The kind-checked append of a CALLER-SUPPLIED branded record id (the
  host-side kind door, INV2). RAISES `ArgumentError` before any wire if
  `branded` is malformed or not of the admitted stream namespace (`EVT`) --
  symmetric with `EchoMQ.Keyspace.job_key/2` (`keyspace.ex:22`), policy before
  existence before write. `append/4` routes through this with its own minted
  id (a wrong-kind is then a programming error that cannot occur); a caller
  supplying an id drives the door directly.
  """
  @spec append_id(GenServer.server(), binary(), binary(), binary(), fields()) ::
          {:ok, binary()} | {:error, :nonmonotonic | term()}
  def append_id(conn, queue, name, branded, fields)
      when is_binary(queue) and is_binary(name) and is_list(fields) do
    # the kind door FIRST -- a malformed/wrong-kind id raises before any wire.
    case Id.xadd_id(branded) do
      {:ok, xadd_id} ->
        key = stream_key(queue, name)
        parts = ["XADD", key, xadd_id, "id", branded | flatten(fields)]

        case Connector.command(conn, parts) do
          {:ok, id} when is_binary(id) -> {:ok, branded}
          {:ok, {:error_reply, @id_too_small}} -> {:error, :nonmonotonic}
          {:ok, {:error_reply, msg}} -> {:error, {:error_reply, msg}}
          {:error, _} = err -> err
        end

      {:error, :kind} ->
        raise ArgumentError,
              "EchoMQ.Stream admits one brand per stream (#{Id.kind()}); got: #{inspect(branded)}"

      {:error, :malformed} ->
        raise ArgumentError, "EchoMQ.Stream.append_id requires a valid branded id; got: #{inspect(branded)}"
    end
  end

  @doc """
  Appends a BATCH of records in one pipeline (riding the emq3.1-certified
  `EchoMQ.Connector.pipeline/3` -- the SOLE wire-owner, no second pipelining
  mechanism). Mints one `EVT` id per record host-side, in order, and issues N
  `XADD`s as one pipeline. Returns `{:ok, [branded]}` (the receipts in append
  order) or `{:error, term}` (the pipeline error; a per-record `:error_reply`
  surfaces in the reply list). The mints are over the shared monotone cell, so
  the batch is strictly mint-ordered.
  """
  @spec append_batch(GenServer.server(), binary(), binary(), [fields()]) ::
          {:ok, [binary()]} | {:error, term()}
  def append_batch(conn, queue, name, records)
      when is_binary(queue) and is_binary(name) and is_list(records) do
    key = stream_key(queue, name)

    {cmds, brandeds} =
      Enum.map_reduce(records, [], fn fields, acc ->
        branded = EchoData.Snowflake.next_branded(Id.kind())
        {:ok, xadd_id} = Id.xadd_id(branded)
        {["XADD", key, xadd_id, "id", branded | flatten(fields)], [branded | acc]}
      end)

    case Connector.pipeline(conn, cmds) do
      {:ok, _replies} -> {:ok, Enum.reverse(brandeds)}
      {:error, _} = err -> err
    end
  end

  @doc """
  The MINIMAL un-grouped read-back of `emq:{q}:stream:<name>` (the order-theorem
  proof surface, NOT a consumer group). Wraps `XRANGE <key> <from> <to> [COUNT
  n]` and parses the nested-array reply `[[xadd_id, [field, value, …]], …]`
  into `{branded, fields_map}` tuples IN MINT ORDER -- the branded id recovered
  from the stored `id` field, the remaining pairs as a map. `from`/`to` default
  to the full range `"-"`/`"+"`.
  """
  @spec read(GenServer.server(), binary(), binary(), binary(), binary(), pos_integer() | nil) ::
          {:ok, [{binary(), map()}]} | {:error, term()}
  def read(conn, queue, name, from \\ "-", to \\ "+", count \\ nil)
      when is_binary(queue) and is_binary(name) do
    key = stream_key(queue, name)
    parts = ["XRANGE", key, from, to] ++ if(count, do: ["COUNT", Integer.to_string(count)], else: [])

    case Connector.command(conn, parts) do
      {:ok, entries} when is_list(entries) -> {:ok, Enum.map(entries, &parse_entry/1)}
      {:error, _} = err -> err
    end
  end

  @doc """
  The braced stream key `emq:{q}:stream:<name>` via the shipped total
  `EchoMQ.Keyspace.queue_key/2` (ADR-3 -- no grammar edit; the stream shares
  the queue's `{q}` hashtag slot).
  """
  @spec stream_key(binary(), binary()) :: binary()
  def stream_key(queue, name) when is_binary(queue) and is_binary(name),
    do: Keyspace.queue_key(queue, "stream:" <> name)

  # Parse one XRANGE entry [xadd_id, [field, value, …]] into {branded, map}:
  # the branded record id is the stored "id" field (the claims-only contract),
  # the remaining pairs are the payload as a map. The xadd_id is the wire
  # position; the BRANDED id is the canonical receipt the reader sorts by.
  defp parse_entry([_xadd_id, kv]) when is_list(kv) do
    map = pairs(kv)
    {Map.get(map, "id"), Map.delete(map, "id")}
  end

  defp pairs([k, v | rest]), do: Map.put(pairs(rest), k, v)
  defp pairs([]), do: %{}

  # Flatten [{k, v}, …] -> [k, v, …]; a pre-flattened [k, v, …] passes through.
  defp flatten([{_, _} | _] = kv), do: Enum.flat_map(kv, fn {k, v} -> [k, v] end)
  defp flatten(flat) when is_list(flat), do: flat
end
