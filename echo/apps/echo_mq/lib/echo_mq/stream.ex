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
  and the polyglot seam are emq3.3. Retention (`MAXLEN`/`MINID`) lands here as
  `trim/4` (emq3.4); `append/_` itself does not trim -- retention is a SEPARATE
  destructive verb, never coupled to the append (D-2). Multi-writer-per-stream
  is the parked seam (the posture is single-writer; `:nonmonotonic` is surfaced,
  not BUILT for).

  ## Retention (`trim/4`, emq3.4 -- the destructive verb)

  `trim(conn, queue, name, window)` removes entries OUTSIDE a declared window
  over `XTRIM` issued DIRECT (no new script -- the emq3.3 no-new-Lua pattern).
  Two window forms:

    * `{:maxlen, count, approx?}` -> `XTRIM <key> MAXLEN [~|=] <count>` -- keep
      the `count` newest entries, remove the older;
    * `{:minid, dt, approx?}` -> `XTRIM <key> MINID [~|=] "<ms>-0"` -- remove
      every entry minted strictly BEFORE the `DateTime` `dt`, the floor DERIVED
      from `EchoData.Snowflake.min_for/1` (`ms = unix_ms(min_for(dt))`, the
      rung's one piece of real id-math -- NEVER a raw snowflake integer to the
      wire).

  `approx?` (the third element) selects `~` (approximate -- trims in whole
  macro-nodes, cheaper; it may UNDER-trim but can NEVER OVER-trim, so it can
  never delete inside the window: the safe-by-construction default) vs `=`
  (exact -- removes precisely to the window edge, the opt-in). Either way the
  blast radius is bounded by the window: a trim can NEVER delete an entry inside
  it (INV4). Answers `{:ok, removed_count}` (the integer `XTRIM` returns) or
  `{:error, term}` (any connector/server fault verbatim -- a `WRONGTYPE` is
  surfaced, not swallowed). RAISES before any wire on a malformed queue/stream
  name (the `append_id/5` policy-before-existence precedent). The named, opt-in
  trim driver `EchoMQ.StreamRetention` re-applies a declared policy via this
  verb; a manual call is the equally-supported cadence (the driver is sugar).
  """

  alias EchoMQ.{Connector, Keyspace}
  alias EchoMQ.Stream.Id

  # the verbatim valkey.io rejection of an explicit id <= the stream top
  # (valkey.io/topics/streams-intro) -- the ONLY error mapped to :nonmonotonic;
  # every other error_reply (e.g. WRONGTYPE) passes through verbatim.
  @id_too_small "ERR The ID specified in XADD is equal or smaller than the target stream top item"

  # The maximal 22-bit `node|seq` tail (`0x3FFFFF`) -- the largest seq an A1
  # xadd id can carry at one ms (`Stream.Id.xadd_id/1`'s `snow &&& 0x3FFFFF`,
  # stream/id.ex:89). `maxid_ceil/1` (emq3.6) uses it as the INCLUSIVE upper
  # bound `"<ms>-#{0x3FFFFF}"`, the inverse of `minid_floor/1`'s `"<ms>-0"`.
  @max_seq 0x3FFFFF

  @typedoc "An XADD field pair list (claims-only -- flat string pairs)."
  @type fields :: [{binary(), binary()}] | [binary()]

  @typedoc """
  A retention window for `trim/4` (emq3.4). `{:maxlen, count, approx?}` keeps
  the `count` newest entries; `{:minid, dt, approx?}` keeps entries minted at or
  after the `DateTime` `dt` (the floor derived from `Snowflake.min_for/1`).
  `approx?` true selects the SAFE approximate `~` form (the default the driver
  uses), false the exact `=` opt-in.
  """
  @type window ::
          {:maxlen, non_neg_integer(), boolean()} | {:minid, DateTime.t(), boolean()}

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
  Trims the stream `emq:{q}:stream:<name>` to a declared retention `window`,
  removing entries OUTSIDE it over `XTRIM` issued DIRECT through
  `EchoMQ.Connector.command/3` (no new script -- emq3.4, the no-new-Lua rung).

  The `window`:

    * `{:maxlen, count, approx?}` -> `XTRIM <key> MAXLEN [~|=] <count>` -- keep
      the `count` newest entries, remove the older;
    * `{:minid, %DateTime{}, approx?}` -> `XTRIM <key> MINID [~|=] "<ms>-0"` --
      remove every entry minted strictly before the instant; the floor is
      DERIVED from `EchoData.Snowflake.min_for/1` (`ms = unix_ms(min_for(dt))`
      == `DateTime.to_unix(dt, :millisecond)`, the rung's one piece of real
      id-math, INV6) -- never a raw snowflake integer to the wire.

  `approx?` (the third element) selects the trim mode: `true` -> `~`
  (approximate, the SAFE default -- trims in whole macro-nodes, may UNDER-trim
  but NEVER OVER-trim, so it can never delete inside the window); `false` -> `=`
  (exact, the opt-in -- removes precisely to the window edge). EITHER way the
  blast radius is bounded by the window -- a trim can NEVER delete an entry
  inside it (INV4).

  Returns `{:ok, removed_count}` (the integer `XTRIM` answers -- entries
  removed; under `~` it may be 0 even when entries are old, as approx trims in
  whole macro-nodes) or `{:error, term}` (any connector/server fault verbatim --
  a `WRONGTYPE` against a non-stream key is SURFACED, not swallowed). RAISES
  `ArgumentError` before any wire on a malformed queue/stream name (the
  `append_id/5` policy-before-existence precedent).
  """
  @spec trim(GenServer.server(), binary(), binary(), window()) ::
          {:ok, non_neg_integer()} | {:error, term()}
  def trim(conn, queue, name, {:maxlen, count, approx?})
      when is_binary(queue) and is_binary(name) and is_integer(count) and count >= 0 and
             is_boolean(approx?) do
    key = stream_key(queue, name)
    xtrim(conn, ["XTRIM", key, "MAXLEN", approx_flag(approx?), Integer.to_string(count)])
  end

  def trim(conn, queue, name, {:minid, %DateTime{} = dt, approx?})
      when is_binary(queue) and is_binary(name) and is_boolean(approx?) do
    key = stream_key(queue, name)
    xtrim(conn, ["XTRIM", key, "MINID", approx_flag(approx?), minid_floor(dt)])
  end

  @doc """
  The `MINID` floor id `"<ms>-0"` for a retention horizon `dt`, DERIVED from
  `EchoData.Snowflake.min_for/1` (INV6): `ms = Snowflake.unix_ms(min_for(dt))`
  == `DateTime.to_unix(dt, :millisecond)` -- the smallest entry id at or after
  the instant (tail `-0` the lowest sequence at that ms). `XTRIM MINID
  "<ms>-0"` removes every entry whose `ms-seq` id is strictly below it -- every
  entry minted in an EARLIER millisecond -- so the half-open `[dt, ∞)` edge is
  exact: a `dt - 1ms` entry trims, a `dt` entry survives. NEVER a raw
  `min_for/1` integer handed to the wire (the wire wants `ms-seq`).
  """
  @spec minid_floor(DateTime.t()) :: binary()
  def minid_floor(%DateTime{} = dt) do
    ms = EchoData.Snowflake.unix_ms(EchoData.Snowflake.min_for(dt))
    "#{ms}-0"
  end

  @doc """
  The INCLUSIVE upper-bound id `"<ms>-#{@max_seq}"` for a window end `dt` (the
  inverse of `minid_floor/1`, emq3.6) -- the LARGEST entry id mintable at or
  before `dt`. The `ms` is the SAME true-Unix-ms `minid_floor/1` uses
  (`Snowflake.unix_ms(min_for(dt))` == `DateTime.to_unix(dt, :millisecond)`);
  the seq is the maximal 22-bit `node|seq` tail (`0x3FFFFF` == #{@max_seq}), the
  ceiling of `Stream.Id.xadd_id/1`'s `snow &&& 0x3FFFFF` (`stream/id.ex:89`). So
  `XRANGE <from> "<ms>-#{@max_seq}"` ADMITS every entry whose mint ms is `<= dt`
  (any seq at `ms` is `<= 0x3FFFFF` by construction) and EXCLUDES the first entry
  of `ms + 1ms` -- the inclusive `[…, dt]` edge is exact: a `dt` entry reads
  back, a `dt + 1ms` entry does not. NEVER a raw `min_for/1` integer handed to
  the wire (the wire wants `ms-seq`, the F-1-class discipline `minid_floor/1`
  holds).
  """
  @spec maxid_ceil(DateTime.t()) :: binary()
  def maxid_ceil(%DateTime{} = dt) do
    ms = EchoData.Snowflake.unix_ms(EchoData.Snowflake.min_for(dt))
    "#{ms}-#{@max_seq}"
  end

  @doc """
  A CLOSED mint-time window read of `emq:{q}:stream:<name>` over `[t0, t1]`
  (INCLUSIVE both edges, emq3.6 -- the time-travel read for backtest / audit /
  debug). Computes the `XRANGE` bounds host-side -- `from` = `minid_floor(t0)`
  (the SHIPPED lower floor, byte-frozen), `to` = `maxid_ceil(t1)` (the new
  inclusive upper inverse) -- and DELEGATES to the byte-frozen `read/6`. ZERO
  new Lua (`XRANGE` is host-issued through the SHIPPED `read/6` path).

  Returns `{:ok, [{branded, fields_map}]}` -- the entries whose branded `EVT`
  mint-instant (`Snowflake.to_datetime/1` of the id's snowflake) falls in
  `[t0, t1]`, in mint order -- which EQUALS reading the full stream and
  filtering each entry by its id's mint instant (INV-TT, the window is a
  server-side filter via the bounds). `{:error, term}` is any connector/server
  fault verbatim (`read/6`'s shape).

  RAISES `ArgumentError` before any wire on a malformed queue/stream name (the
  `append_id/5` / `trim/4` policy-before-existence precedent) or an inverted
  window (`t1` strictly before `t0`) -- a host-side guard, never a malformed
  bound to the wire.
  """
  @spec read_window(GenServer.server(), binary(), binary(), DateTime.t(), DateTime.t(), pos_integer() | nil) ::
          {:ok, [{binary(), map()}]} | {:error, term()}
  def read_window(conn, queue, name, %DateTime{} = t0, %DateTime{} = t1, count \\ nil)
      when is_binary(queue) and is_binary(name) do
    if DateTime.compare(t1, t0) == :lt do
      raise ArgumentError,
            "EchoMQ.Stream.read_window requires t0 <= t1; got t0=#{DateTime.to_iso8601(t0)}, t1=#{DateTime.to_iso8601(t1)}"
    end

    read(conn, queue, name, minid_floor(t0), maxid_ceil(t1), count)
  end

  @doc """
  An OPEN-ended mint-time window read of `emq:{q}:stream:<name>` over `[t0, ∞)`
  (emq3.6 -- the common audit case: everything at or after `t0`). The `from` is
  the SHIPPED `minid_floor(t0)` (the half-open lower floor, byte-frozen); the
  `to` is `"+"` (the stream top, the open upper). DELEGATES to the byte-frozen
  `read/6`; ZERO new Lua.

  Returns `{:ok, [{branded, fields_map}]}` in mint order -- the entries minted
  at or after `t0` -- or `{:error, term}` verbatim. The half-open `[t0, …)` edge
  is the exact one `minid_floor/1` already proves on the trim path: a `t0` entry
  is IN, a `t0 - 1ms` entry is OUT. RAISES `ArgumentError` before any wire on a
  malformed queue/stream name (the `append_id/5` precedent).
  """
  @spec read_since(GenServer.server(), binary(), binary(), DateTime.t(), pos_integer() | nil) ::
          {:ok, [{binary(), map()}]} | {:error, term()}
  def read_since(conn, queue, name, %DateTime{} = t0, count \\ nil)
      when is_binary(queue) and is_binary(name) do
    read(conn, queue, name, minid_floor(t0), "+", count)
  end

  # `~` approximate (the SAFE default -- whole macro-nodes, never over-trims) vs
  # `=` exact (the opt-in -- removes precisely to the window edge).
  defp approx_flag(true), do: "~"
  defp approx_flag(false), do: "="

  # Issue the XTRIM parts and surface the integer removed-count verbatim; any
  # connector/server fault (e.g. WRONGTYPE on a non-stream key) passes through,
  # never swallowed (the gate-liveness discipline).
  defp xtrim(conn, parts) do
    case Connector.command(conn, parts) do
      {:ok, removed} when is_integer(removed) -> {:ok, removed}
      {:ok, {:error_reply, msg}} -> {:error, {:error_reply, msg}}
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

  @doc """
  Caches the archive watermark `W` (the branded `EVT` id of the highest-folded
  record, emq3.5) under `emq:{q}:stream:<name>:archived` -- a stock `SET` over
  `EchoMQ.Connector.command/3`, NO new script and NO grammar edit (the key rides
  the existing `emq:{q}:stream:<name>:<sub>` form, the `:archived` sub on the
  shared `{q}` slot).

  This is a polyglot CACHE of the archive seam, NEVER the source of truth (the
  store-side engine's frontier is -- `EchoStore.StreamArchive.archive_frontier/1`):
  a non-BEAM reader discovers where the archive ends and the live tail begins
  without a store call. The store-side fold consumer writes it AFTER advancing
  the engine frontier; it is overwritten on each fold and DELETEd when the stream
  is obliterated (`clear_archived/3`). Answers `{:ok, "OK"}` or `{:error, term}`
  verbatim. RAISES `ArgumentError` before any wire on a malformed queue/stream
  name (the `append_id/5` policy-before-existence precedent).
  """
  @spec put_archived(GenServer.server(), binary(), binary(), binary()) ::
          {:ok, binary()} | {:error, term()}
  def put_archived(conn, queue, name, w)
      when is_binary(queue) and is_binary(name) and is_binary(w) do
    key = archived_key(queue, name)

    case Connector.command(conn, ["SET", key, w]) do
      {:ok, "OK"} -> {:ok, "OK"}
      {:ok, {:error_reply, msg}} -> {:error, {:error_reply, msg}}
      {:error, _} = err -> err
    end
  end

  @doc """
  Reads the cached archive watermark `W` from `emq:{q}:stream:<name>:archived` --
  a stock `GET` over `EchoMQ.Connector.command/3`. Answers `{:ok, w}` (the
  branded `EVT` id a fold last cached), `:empty` (no fold has cached a seam
  yet -- the whole stream is live tail), or `{:error, term}` verbatim. The CACHE
  face of the seam; the store-side engine frontier is the source of truth.
  """
  @spec get_archived(GenServer.server(), binary(), binary()) ::
          {:ok, binary()} | :empty | {:error, term()}
  def get_archived(conn, queue, name)
      when is_binary(queue) and is_binary(name) do
    key = archived_key(queue, name)

    case Connector.command(conn, ["GET", key]) do
      {:ok, w} when is_binary(w) -> {:ok, w}
      {:ok, nil} -> :empty
      {:ok, {:error_reply, msg}} -> {:error, {:error_reply, msg}}
      {:error, _} = err -> err
    end
  end

  @doc """
  Deletes the cached archive watermark at `emq:{q}:stream:<name>:archived` -- the
  NAMED cleanup the seam cache carries (called when the stream is obliterated, so
  no stale seam outlives the stream). A stock `DEL` over
  `EchoMQ.Connector.command/3`; answers `{:ok, n}` (1 if the key existed, 0
  otherwise) or `{:error, term}` verbatim.
  """
  @spec clear_archived(GenServer.server(), binary(), binary()) ::
          {:ok, non_neg_integer()} | {:error, term()}
  def clear_archived(conn, queue, name)
      when is_binary(queue) and is_binary(name) do
    key = archived_key(queue, name)

    case Connector.command(conn, ["DEL", key]) do
      {:ok, n} when is_integer(n) -> {:ok, n}
      {:ok, {:error_reply, msg}} -> {:error, {:error_reply, msg}}
      {:error, _} = err -> err
    end
  end

  # The archive-seam cache key `emq:{q}:stream:<name>:archived` via the shipped
  # total queue_key/2 -- the `:archived` sub on the stream's `{q}` slot, the
  # existing emq:{q}:stream:<name>:<sub> form, no grammar edit.
  defp archived_key(queue, name),
    do: Keyspace.queue_key(queue, "stream:" <> name <> ":archived")

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
