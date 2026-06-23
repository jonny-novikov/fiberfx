defmodule EchoStore.StreamHydrator do
  @moduledoc """
  THE HYDRATION (emq3.6, S3 the memory part 2): a ONE-SHOT fold of a recorded
  `EchoMQ.Stream` tail into an `EchoStore.Table`, holding per key the value
  carried by the NEWEST mint id -- *changelog semantics without a compactor*.
  A store loader warming config / positions / a hydration table from a recorded
  event stream reads the tail once and folds it; the `:tracking` staleness fence
  the Table already arms keeps it current thereafter (*hydrate-then-fence equals
  loader truth*).

  This is a CALLER-SIDE orchestration over two PUBLIC surfaces -- the bus read
  `EchoMQ.Stream.read/3..6` (`stream.ex:270`) and the store write
  `EchoStore.Table.put/4` (`table.ex:97`) -- with NO new state and NO background
  process: a bounded tail read, a per-key versioned write, done. It deliberately
  lives BESIDE `EchoStore.Table` (not inside the cache owner) so the Table's
  cache-aside core stays uncluttered and the L1/L2 write path stays the single
  `put/4` authority (the engine + the Table internals are UNTOUCHED -- the
  hydration touches only the public API, INV8). The supervised continuous
  hydrator (a standing tailer + a durable cursor) is a FUTURE additive surface;
  emq3.6 ships the one-shot, the fence maintains freshness (Arm 3).

  ## The fold (newer-wins, no compactor)

  Each tail record carries (claims-only flat string fields):

    * a KEY field (default `"key"`) -- the entity id the Table row is written to
      (gated to the Table's namespace by `Table.put/4`'s door, `table.ex:547`);
    * a VALUE field (default `"value"`) -- the row value;
    * the branded `EVT` record id (the stream `id` field `EchoMQ.Stream.read/6`
      recovers) -- used AS the `Table.put/4` version.

  The fold writes each record in mint order (`read/6` returns mint order) via
  `Table.put(table, key, value, evt_id)`. Because the tail is mint-ordered and
  `EchoStore.Coherence.newer?/2` (`coherence.ex:52`) compares the branded id's
  11-byte snowflake payload, the LAST write per key (the record with the MAX
  branded `EVT` mint id) wins -- the changelog snapshot, no compactor, no log
  rewrite. The source stream is READ-ONLY to the hydrator (no `XADD`/`XTRIM`);
  the payloads stay claims-only flat pairs.

  ## Idempotence

  Re-running the hydrate (a replay over the same tail) is HARMLESS: `Table.put/4`
  is a versioned write and the re-applied records carry the SAME `EVT` ids, so
  every key re-resolves to the SAME newest value -- newer-wins makes the replay a
  no-op-by-value. There is no cursor to leave ahead (the one-shot folds a bounded
  tail each call), so the emq3.5 R-1 two-phase-write hazard does not arise.
  """

  alias EchoStore.Table
  alias EchoMQ.Stream, as: MqStream

  @default_key_field "key"
  @default_value_field "value"

  @typedoc """
  A hydrate summary: the number of DISTINCT keys folded and the total number of
  tail records read (records >= keys when any key received more than one record).
  """
  @type summary :: %{keys: non_neg_integer(), records: non_neg_integer()}

  @doc """
  Hydrates `table` from the live tail of `emq:{queue}:stream:<name>` -- a
  ONE-SHOT fold, newer-wins by mint order, no compactor (emq3.6, INV-HYDRATE /
  INV-NOCOMPACTOR).

  Reads the tail via the byte-frozen `EchoMQ.Stream.read/3..6` (the LIVE tail,
  Arm 4 -- the merge-read deep source is a future arity), then folds each record
  in mint order into `table` via `EchoStore.Table.put/4`, keyed on the record's
  KEY field and versioned by the record's branded `EVT` id. The Table holds, per
  key, the value of the record with the MAXIMUM branded `EVT` mint id.

  ## Options

    * `:key_field` -- the claims-only field carrying the entity id (default
      `"#{@default_key_field}"`);
    * `:value_field` -- the field carrying the row value (default
      `"#{@default_value_field}"`);
    * `:from` / `:to` -- the `XRANGE` bounds passed through to `read/6` (default
      the full range `"-"`/`"+"`); a caller may pass `EchoMQ.Stream.minid_floor/1`
      / `maxid_ceil/1` to hydrate from a mint-time window;
    * `:count` -- an optional `XRANGE COUNT` cap.

  Returns `{:ok, %{keys: D, records: K}}` (the fold summary) or `{:error, term}`
  -- a read fault verbatim (`read/6`'s shape), or a `Table.put/4` write fault
  (fail-closed: the fold STOPS at the first write error, never a silent partial
  hydrate). RAISES `ArgumentError` before any write on a record missing its KEY
  or VALUE field (a contract violation -- policy before write, the bus-side
  `append_id/5` precedent) and propagates the `Table.put/4` kind-door
  `{:error, :kind}` for a key outside the Table's namespace.
  """
  @spec hydrate_from_stream(atom(), GenServer.server(), binary(), binary(), keyword()) ::
          {:ok, summary()} | {:error, term()}
  def hydrate_from_stream(table, conn, queue, name, opts \\ [])
      when is_atom(table) and is_binary(queue) and is_binary(name) and is_list(opts) do
    key_field = Keyword.get(opts, :key_field, @default_key_field)
    value_field = Keyword.get(opts, :value_field, @default_value_field)
    from = Keyword.get(opts, :from, "-")
    to = Keyword.get(opts, :to, "+")
    count = Keyword.get(opts, :count)

    case MqStream.read(conn, queue, name, from, to, count) do
      {:ok, entries} -> fold(table, entries, key_field, value_field)
      {:error, _} = err -> err
    end
  end

  # Fold the mint-ordered tail into the Table per key, versioned by each record's
  # branded EVT id. Stops at the first write error (fail-closed -- never a silent
  # partial hydrate). Tracks the distinct keys touched for the summary. The fold
  # is mint-ordered, so the last write per key (the newest mint id) wins by the
  # newer-wins comparison Table.put/4 frames into the row version.
  defp fold(table, entries, key_field, value_field) do
    Enum.reduce_while(entries, {:ok, MapSet.new(), 0}, fn {evt_id, fields}, {:ok, keys, n} ->
      key = field!(fields, key_field, "key")
      value = field!(fields, value_field, "value")

      case Table.put(table, key, value, evt_id) do
        :ok -> {:cont, {:ok, MapSet.put(keys, key), n + 1}}
        {:error, _} = err -> {:halt, err}
      end
    end)
    |> case do
      {:ok, keys, n} -> {:ok, %{keys: MapSet.size(keys), records: n}}
      {:error, _} = err -> err
    end
  end

  # Read a required claims-only field; RAISE before any write on a missing field
  # (the record is structurally malformed for hydration -- policy before write,
  # the bus-side append_id/5 policy-before-existence precedent), never a silent
  # skip that drops a key.
  defp field!(fields, name, role) do
    case Map.fetch(fields, name) do
      {:ok, v} when is_binary(v) ->
        v

      _ ->
        raise ArgumentError,
              "EchoStore.StreamHydrator: a tail record is missing its #{role} field #{inspect(name)}; got fields: #{inspect(fields)}"
    end
  end
end
