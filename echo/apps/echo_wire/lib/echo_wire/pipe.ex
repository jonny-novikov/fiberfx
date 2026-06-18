defmodule EchoWire.Pipe do
  @moduledoc """
  The threaded pipeline: idiomatic `|>` command-batch construction over the
  owned wire. A `%Pipe{}` accumulator threads through a chain of verbs, each
  appending one command-list, and `exec/1` flushes the batch once through the
  connector it was opened on.

      conn
      |> EchoWire.Pipe.new()
      |> EchoWire.Pipe.set("user:1", "alice", ex: 60)
      |> EchoWire.Pipe.get("user:1")
      |> EchoWire.Pipe.incr("hits")
      |> EchoWire.Pipe.exec()
      # => {:ok, ["OK", "alice", 1]}

  ## What this adds — and what it does not

  The connector already pipelines: `EchoMQ.Connector.pipeline/3` takes a list
  of command-lists off an in-flight FIFO and returns `{:ok, [reply]}`. This
  module adds **no second pipelining mechanism** — it adds the *noun* the
  connector consumes. `exec/1` is literally one `pipeline/3` call over the
  commands the chain gathered; the connector stays the sole owner of the wire.

  ## Conn-or-pool, opaque

  `new/2` carries the server reference (`conn`) and a `via` dispatch module,
  never inspecting the reference. The same `%Pipe{}` flushes against an
  `EchoMQ.Connector` (the default `via`) or an `EchoMQ.Pool` (`via:
  EchoMQ.Pool`) — both expose a signature-identical `pipeline/3`. The
  transaction/no-reply flush verbs (`exec_txn/1`, `exec_noreply/1`) are
  connection-stateful (`MULTI`/`EXEC`; `CLIENT REPLY OFF`/`ON`) and so are
  `EchoMQ.Connector`-only: a pool round-robins per command and pins no
  connection across a transaction.

  ## The curated set is never a ceiling

  The verbs below span the six core Valkey data families (strings ·
  keys/expiry · hashes · lists · sets · sorted sets), curated from the
  valkey-go fluent builders (`go/valkey-go/internal/cmds/gen_*.go`). Any
  command not curated — a different family, a rare option — is reachable
  through `command/2`, which appends a raw command-list verbatim. Replies map
  one-to-one to the appended commands, in call order.
  """

  alias EchoMQ.Connector

  @default_timeout 5_000

  @typedoc "One command as a flat list of wire tokens."
  @type command :: [binary() | integer() | atom()]

  @type t :: %__MODULE__{
          conn: GenServer.server(),
          via: module(),
          timeout: timeout(),
          cmds: [command()]
        }

  defstruct [:conn, :via, :timeout, cmds: []]

  # -- construction --------------------------------------------------------

  @doc """
  Open an empty pipe over `conn`.

  Options:

    * `:via` — the dispatch module whose `pipeline/3` flushes the batch.
      Defaults to `EchoMQ.Connector`; pass `EchoMQ.Pool` to flush against a
      pool. The reference itself is **never inspected** — the dispatch is
      carried, not detected.
    * `:timeout` — the per-flush call timeout. Defaults to `#{@default_timeout}`.
  """
  @spec new(GenServer.server(), keyword()) :: t()
  def new(conn, opts \\ []) do
    %__MODULE__{
      conn: conn,
      via: Keyword.get(opts, :via, Connector),
      timeout: Keyword.get(opts, :timeout, @default_timeout),
      cmds: []
    }
  end

  # -- strings (gen_string.go) ---------------------------------------------

  @doc "SET key value, with `:ex`/`:px`/`:exat`/`:pxat`/`:nx`/`:xx`/`:keepttl`/`:get` options as trailing tokens."
  @spec set(t(), binary(), binary(), keyword()) :: t()
  def set(pipe, key, value, opts \\ []) do
    add(pipe, ["SET", key, value] ++ set_opts(opts))
  end

  @doc "GET key."
  @spec get(t(), binary()) :: t()
  def get(pipe, key), do: add(pipe, ["GET", key])

  @doc "GETSET key value (set new, return old)."
  @spec getset(t(), binary(), binary()) :: t()
  def getset(pipe, key, value), do: add(pipe, ["GETSET", key, value])

  @doc "GETDEL key (get then delete)."
  @spec getdel(t(), binary()) :: t()
  def getdel(pipe, key), do: add(pipe, ["GETDEL", key])

  @doc "MSET from a `[{key, value}]` or flat `[key, value, ...]` list."
  @spec mset(t(), [{binary(), binary()}] | [binary()]) :: t()
  def mset(pipe, pairs), do: add(pipe, ["MSET" | flatten_pairs(pairs)])

  @doc "MGET keys."
  @spec mget(t(), [binary()]) :: t()
  def mget(pipe, keys) when is_list(keys), do: add(pipe, ["MGET" | keys])

  @doc "APPEND key value."
  @spec append(t(), binary(), binary()) :: t()
  def append(pipe, key, value), do: add(pipe, ["APPEND", key, value])

  @doc "STRLEN key."
  @spec strlen(t(), binary()) :: t()
  def strlen(pipe, key), do: add(pipe, ["STRLEN", key])

  @doc "INCR key."
  @spec incr(t(), binary()) :: t()
  def incr(pipe, key), do: add(pipe, ["INCR", key])

  @doc "INCRBY key increment."
  @spec incrby(t(), binary(), integer()) :: t()
  def incrby(pipe, key, by), do: add(pipe, ["INCRBY", key, by])

  @doc "DECR key."
  @spec decr(t(), binary()) :: t()
  def decr(pipe, key), do: add(pipe, ["DECR", key])

  @doc "DECRBY key decrement."
  @spec decrby(t(), binary(), integer()) :: t()
  def decrby(pipe, key, by), do: add(pipe, ["DECRBY", key, by])

  @doc "INCRBYFLOAT key increment."
  @spec incrbyfloat(t(), binary(), number() | binary()) :: t()
  def incrbyfloat(pipe, key, by), do: add(pipe, ["INCRBYFLOAT", key, to_token(by)])

  @doc "SETEX key seconds value."
  @spec setex(t(), binary(), integer(), binary()) :: t()
  def setex(pipe, key, seconds, value), do: add(pipe, ["SETEX", key, seconds, value])

  @doc "SETNX key value."
  @spec setnx(t(), binary(), binary()) :: t()
  def setnx(pipe, key, value), do: add(pipe, ["SETNX", key, value])

  @doc "GETRANGE key start stop."
  @spec getrange(t(), binary(), integer(), integer()) :: t()
  def getrange(pipe, key, start, stop), do: add(pipe, ["GETRANGE", key, start, stop])

  @doc "SETRANGE key offset value."
  @spec setrange(t(), binary(), integer(), binary()) :: t()
  def setrange(pipe, key, offset, value), do: add(pipe, ["SETRANGE", key, offset, value])

  # -- keys / generic + expiry (gen_generic.go) ----------------------------

  @doc "DEL key(s)."
  @spec del(t(), binary() | [binary()]) :: t()
  def del(pipe, keys), do: add(pipe, ["DEL" | List.wrap(keys)])

  @doc "UNLINK key(s)."
  @spec unlink(t(), binary() | [binary()]) :: t()
  def unlink(pipe, keys), do: add(pipe, ["UNLINK" | List.wrap(keys)])

  @doc "EXISTS key(s)."
  @spec exists(t(), binary() | [binary()]) :: t()
  def exists(pipe, keys), do: add(pipe, ["EXISTS" | List.wrap(keys)])

  @doc "EXPIRE key seconds."
  @spec expire(t(), binary(), integer()) :: t()
  def expire(pipe, key, seconds), do: add(pipe, ["EXPIRE", key, seconds])

  @doc "PEXPIRE key milliseconds."
  @spec pexpire(t(), binary(), integer()) :: t()
  def pexpire(pipe, key, ms), do: add(pipe, ["PEXPIRE", key, ms])

  @doc "EXPIREAT key unix-seconds."
  @spec expireat(t(), binary(), integer()) :: t()
  def expireat(pipe, key, ts), do: add(pipe, ["EXPIREAT", key, ts])

  @doc "PEXPIREAT key unix-millis."
  @spec pexpireat(t(), binary(), integer()) :: t()
  def pexpireat(pipe, key, ts), do: add(pipe, ["PEXPIREAT", key, ts])

  @doc "TTL key."
  @spec ttl(t(), binary()) :: t()
  def ttl(pipe, key), do: add(pipe, ["TTL", key])

  @doc "PTTL key."
  @spec pttl(t(), binary()) :: t()
  def pttl(pipe, key), do: add(pipe, ["PTTL", key])

  @doc "PERSIST key."
  @spec persist(t(), binary()) :: t()
  def persist(pipe, key), do: add(pipe, ["PERSIST", key])

  @doc "TYPE key."
  @spec type(t(), binary()) :: t()
  def type(pipe, key), do: add(pipe, ["TYPE", key])

  @doc "RENAME key newkey."
  @spec rename(t(), binary(), binary()) :: t()
  def rename(pipe, key, newkey), do: add(pipe, ["RENAME", key, newkey])

  @doc "RENAMENX key newkey."
  @spec renamenx(t(), binary(), binary()) :: t()
  def renamenx(pipe, key, newkey), do: add(pipe, ["RENAMENX", key, newkey])

  @doc "SCAN cursor, with `:match`/`:count`/`:type` options as trailing tokens (the KEYS-avoid path)."
  @spec scan(t(), integer() | binary(), keyword()) :: t()
  def scan(pipe, cursor, opts \\ []), do: add(pipe, ["SCAN", cursor] ++ scan_opts(opts))

  @doc "TOUCH key(s)."
  @spec touch(t(), binary() | [binary()]) :: t()
  def touch(pipe, keys), do: add(pipe, ["TOUCH" | List.wrap(keys)])

  @doc "COPY source destination."
  @spec copy(t(), binary(), binary()) :: t()
  def copy(pipe, src, dst), do: add(pipe, ["COPY", src, dst])

  # -- hashes (gen_hash.go) ------------------------------------------------

  @doc "HSET key field value (single field)."
  @spec hset(t(), binary(), binary(), binary()) :: t()
  def hset(pipe, key, field, value), do: add(pipe, ["HSET", key, field, value])

  @doc "HSET key field value ... from a `[{field, value}]` or flat list / map (multi-field)."
  @spec hset_all(t(), binary(), [{binary(), binary()}] | [binary()] | map()) :: t()
  def hset_all(pipe, key, fields), do: add(pipe, ["HSET", key | flatten_pairs(fields)])

  @doc "HMSET key field value ... (deprecated alias of multi-field HSET)."
  @spec hmset(t(), binary(), [{binary(), binary()}] | [binary()] | map()) :: t()
  def hmset(pipe, key, fields), do: add(pipe, ["HMSET", key | flatten_pairs(fields)])

  @doc "HGET key field."
  @spec hget(t(), binary(), binary()) :: t()
  def hget(pipe, key, field), do: add(pipe, ["HGET", key, field])

  @doc "HMGET key field(s)."
  @spec hmget(t(), binary(), [binary()]) :: t()
  def hmget(pipe, key, fields) when is_list(fields), do: add(pipe, ["HMGET", key | fields])

  @doc "HGETALL key."
  @spec hgetall(t(), binary()) :: t()
  def hgetall(pipe, key), do: add(pipe, ["HGETALL", key])

  @doc "HDEL key field(s)."
  @spec hdel(t(), binary(), binary() | [binary()]) :: t()
  def hdel(pipe, key, fields), do: add(pipe, ["HDEL", key | List.wrap(fields)])

  @doc "HEXISTS key field."
  @spec hexists(t(), binary(), binary()) :: t()
  def hexists(pipe, key, field), do: add(pipe, ["HEXISTS", key, field])

  @doc "HINCRBY key field increment."
  @spec hincrby(t(), binary(), binary(), integer()) :: t()
  def hincrby(pipe, key, field, by), do: add(pipe, ["HINCRBY", key, field, by])

  @doc "HINCRBYFLOAT key field increment."
  @spec hincrbyfloat(t(), binary(), binary(), number() | binary()) :: t()
  def hincrbyfloat(pipe, key, field, by),
    do: add(pipe, ["HINCRBYFLOAT", key, field, to_token(by)])

  @doc "HKEYS key."
  @spec hkeys(t(), binary()) :: t()
  def hkeys(pipe, key), do: add(pipe, ["HKEYS", key])

  @doc "HVALS key."
  @spec hvals(t(), binary()) :: t()
  def hvals(pipe, key), do: add(pipe, ["HVALS", key])

  @doc "HLEN key."
  @spec hlen(t(), binary()) :: t()
  def hlen(pipe, key), do: add(pipe, ["HLEN", key])

  @doc "HSETNX key field value."
  @spec hsetnx(t(), binary(), binary(), binary()) :: t()
  def hsetnx(pipe, key, field, value), do: add(pipe, ["HSETNX", key, field, value])

  @doc "HSCAN key cursor, with `:match`/`:count`/`:novalues` options as trailing tokens."
  @spec hscan(t(), binary(), integer() | binary(), keyword()) :: t()
  def hscan(pipe, key, cursor, opts \\ []),
    do: add(pipe, ["HSCAN", key, cursor] ++ hscan_opts(opts))

  # -- lists (gen_list.go) -------------------------------------------------

  @doc "LPUSH key value(s)."
  @spec lpush(t(), binary(), binary() | [binary()]) :: t()
  def lpush(pipe, key, values), do: add(pipe, ["LPUSH", key | List.wrap(values)])

  @doc "RPUSH key value(s)."
  @spec rpush(t(), binary(), binary() | [binary()]) :: t()
  def rpush(pipe, key, values), do: add(pipe, ["RPUSH", key | List.wrap(values)])

  @doc "LPOP key, optional count."
  @spec lpop(t(), binary(), integer() | nil) :: t()
  def lpop(pipe, key, count \\ nil)
  def lpop(pipe, key, nil), do: add(pipe, ["LPOP", key])
  def lpop(pipe, key, count), do: add(pipe, ["LPOP", key, count])

  @doc "RPOP key, optional count."
  @spec rpop(t(), binary(), integer() | nil) :: t()
  def rpop(pipe, key, count \\ nil)
  def rpop(pipe, key, nil), do: add(pipe, ["RPOP", key])
  def rpop(pipe, key, count), do: add(pipe, ["RPOP", key, count])

  @doc "LRANGE key start stop."
  @spec lrange(t(), binary(), integer(), integer()) :: t()
  def lrange(pipe, key, start, stop), do: add(pipe, ["LRANGE", key, start, stop])

  @doc "LLEN key."
  @spec llen(t(), binary()) :: t()
  def llen(pipe, key), do: add(pipe, ["LLEN", key])

  @doc "LINDEX key index."
  @spec lindex(t(), binary(), integer()) :: t()
  def lindex(pipe, key, index), do: add(pipe, ["LINDEX", key, index])

  @doc "LSET key index value."
  @spec lset(t(), binary(), integer(), binary()) :: t()
  def lset(pipe, key, index, value), do: add(pipe, ["LSET", key, index, value])

  @doc "LREM key count value."
  @spec lrem(t(), binary(), integer(), binary()) :: t()
  def lrem(pipe, key, count, value), do: add(pipe, ["LREM", key, count, value])

  @doc "LINSERT key BEFORE|AFTER pivot value."
  @spec linsert(t(), binary(), :before | :after | binary(), binary(), binary()) :: t()
  def linsert(pipe, key, where, pivot, value),
    do: add(pipe, ["LINSERT", key, insert_where(where), pivot, value])

  @doc "LTRIM key start stop."
  @spec ltrim(t(), binary(), integer(), integer()) :: t()
  def ltrim(pipe, key, start, stop), do: add(pipe, ["LTRIM", key, start, stop])

  @doc "RPOPLPUSH source destination."
  @spec rpoplpush(t(), binary(), binary()) :: t()
  def rpoplpush(pipe, src, dst), do: add(pipe, ["RPOPLPUSH", src, dst])

  @doc "LMOVE source destination LEFT|RIGHT LEFT|RIGHT."
  @spec lmove(t(), binary(), binary(), :left | :right | binary(), :left | :right | binary()) :: t()
  def lmove(pipe, src, dst, from, to),
    do: add(pipe, ["LMOVE", src, dst, side(from), side(to)])

  # -- sets (gen_set.go) ---------------------------------------------------

  @doc "SADD key member(s)."
  @spec sadd(t(), binary(), binary() | [binary()]) :: t()
  def sadd(pipe, key, members), do: add(pipe, ["SADD", key | List.wrap(members)])

  @doc "SREM key member(s)."
  @spec srem(t(), binary(), binary() | [binary()]) :: t()
  def srem(pipe, key, members), do: add(pipe, ["SREM", key | List.wrap(members)])

  @doc "SMEMBERS key."
  @spec smembers(t(), binary()) :: t()
  def smembers(pipe, key), do: add(pipe, ["SMEMBERS", key])

  @doc "SISMEMBER key member."
  @spec sismember(t(), binary(), binary()) :: t()
  def sismember(pipe, key, member), do: add(pipe, ["SISMEMBER", key, member])

  @doc "SCARD key."
  @spec scard(t(), binary()) :: t()
  def scard(pipe, key), do: add(pipe, ["SCARD", key])

  @doc "SPOP key, optional count."
  @spec spop(t(), binary(), integer() | nil) :: t()
  def spop(pipe, key, count \\ nil)
  def spop(pipe, key, nil), do: add(pipe, ["SPOP", key])
  def spop(pipe, key, count), do: add(pipe, ["SPOP", key, count])

  @doc "SRANDMEMBER key, optional count."
  @spec srandmember(t(), binary(), integer() | nil) :: t()
  def srandmember(pipe, key, count \\ nil)
  def srandmember(pipe, key, nil), do: add(pipe, ["SRANDMEMBER", key])
  def srandmember(pipe, key, count), do: add(pipe, ["SRANDMEMBER", key, count])

  @doc "SUNION key(s)."
  @spec sunion(t(), binary() | [binary()]) :: t()
  def sunion(pipe, keys), do: add(pipe, ["SUNION" | List.wrap(keys)])

  @doc "SINTER key(s)."
  @spec sinter(t(), binary() | [binary()]) :: t()
  def sinter(pipe, keys), do: add(pipe, ["SINTER" | List.wrap(keys)])

  @doc "SDIFF key(s)."
  @spec sdiff(t(), binary() | [binary()]) :: t()
  def sdiff(pipe, keys), do: add(pipe, ["SDIFF" | List.wrap(keys)])

  @doc "SMISMEMBER key member(s)."
  @spec smismember(t(), binary(), binary() | [binary()]) :: t()
  def smismember(pipe, key, members), do: add(pipe, ["SMISMEMBER", key | List.wrap(members)])

  @doc "SSCAN key cursor, with `:match`/`:count` options as trailing tokens."
  @spec sscan(t(), binary(), integer() | binary(), keyword()) :: t()
  def sscan(pipe, key, cursor, opts \\ []),
    do: add(pipe, ["SSCAN", key, cursor] ++ scan_opts(opts))

  # -- sorted sets (gen_sorted_set.go) -------------------------------------

  @doc """
  ZADD key score member, with `:nx`/`:xx`/`:gt`/`:lt`/`:ch`/`:incr` options as
  trailing tokens. `score`+`member` may be a single pair or a `[{score, member}]`
  list for the multi-member form.
  """
  @spec zadd(t(), binary(), number() | binary() | [{number() | binary(), binary()}], binary() | keyword(), keyword()) ::
          t()
  def zadd(pipe, key, score, member, opts \\ [])

  def zadd(pipe, key, pairs, opts, []) when is_list(pairs) and is_list(opts) do
    add(pipe, ["ZADD", key] ++ zadd_opts(opts) ++ flatten_score_members(pairs))
  end

  def zadd(pipe, key, score, member, opts) when is_binary(member) do
    add(pipe, ["ZADD", key] ++ zadd_opts(opts) ++ [to_token(score), member])
  end

  @doc "ZREM key member(s)."
  @spec zrem(t(), binary(), binary() | [binary()]) :: t()
  def zrem(pipe, key, members), do: add(pipe, ["ZREM", key | List.wrap(members)])

  @doc "ZRANGE key start stop, with `:withscores`/`:rev` options as trailing tokens."
  @spec zrange(t(), binary(), integer() | binary(), integer() | binary(), keyword()) :: t()
  def zrange(pipe, key, start, stop, opts \\ []),
    do: add(pipe, ["ZRANGE", key, start, stop] ++ zrange_opts(opts))

  @doc "ZRANGEBYSCORE key min max, with `:withscores` and `:limit {offset, count}` options."
  @spec zrangebyscore(t(), binary(), number() | binary(), number() | binary(), keyword()) :: t()
  def zrangebyscore(pipe, key, min, max, opts \\ []),
    do: add(pipe, ["ZRANGEBYSCORE", key, to_token(min), to_token(max)] ++ zrangebyscore_opts(opts))

  @doc "ZREVRANGE key start stop, with `:withscores` option."
  @spec zrevrange(t(), binary(), integer() | binary(), integer() | binary(), keyword()) :: t()
  def zrevrange(pipe, key, start, stop, opts \\ []),
    do: add(pipe, ["ZREVRANGE", key, start, stop] ++ withscores_opt(opts))

  @doc "ZSCORE key member."
  @spec zscore(t(), binary(), binary()) :: t()
  def zscore(pipe, key, member), do: add(pipe, ["ZSCORE", key, member])

  @doc "ZCARD key."
  @spec zcard(t(), binary()) :: t()
  def zcard(pipe, key), do: add(pipe, ["ZCARD", key])

  @doc "ZRANK key member."
  @spec zrank(t(), binary(), binary()) :: t()
  def zrank(pipe, key, member), do: add(pipe, ["ZRANK", key, member])

  @doc "ZREVRANK key member."
  @spec zrevrank(t(), binary(), binary()) :: t()
  def zrevrank(pipe, key, member), do: add(pipe, ["ZREVRANK", key, member])

  @doc "ZINCRBY key increment member."
  @spec zincrby(t(), binary(), number() | binary(), binary()) :: t()
  def zincrby(pipe, key, increment, member),
    do: add(pipe, ["ZINCRBY", key, to_token(increment), member])

  @doc "ZPOPMIN key, optional count."
  @spec zpopmin(t(), binary(), integer() | nil) :: t()
  def zpopmin(pipe, key, count \\ nil)
  def zpopmin(pipe, key, nil), do: add(pipe, ["ZPOPMIN", key])
  def zpopmin(pipe, key, count), do: add(pipe, ["ZPOPMIN", key, count])

  @doc "ZPOPMAX key, optional count."
  @spec zpopmax(t(), binary(), integer() | nil) :: t()
  def zpopmax(pipe, key, count \\ nil)
  def zpopmax(pipe, key, nil), do: add(pipe, ["ZPOPMAX", key])
  def zpopmax(pipe, key, count), do: add(pipe, ["ZPOPMAX", key, count])

  @doc "ZCOUNT key min max."
  @spec zcount(t(), binary(), number() | binary(), number() | binary()) :: t()
  def zcount(pipe, key, min, max),
    do: add(pipe, ["ZCOUNT", key, to_token(min), to_token(max)])

  @doc "ZSCAN key cursor, with `:match`/`:count` options as trailing tokens."
  @spec zscan(t(), binary(), integer() | binary(), keyword()) :: t()
  def zscan(pipe, key, cursor, opts \\ []),
    do: add(pipe, ["ZSCAN", key, cursor] ++ scan_opts(opts))

  # -- the escape hatch ----------------------------------------------------

  @doc """
  Append a raw command-list verbatim — the curated set is never a ceiling.
  Any un-modeled verb (a different family, an admin call like
  `["CLIENT", "INFO"]`) is reachable without a curated wrapper.
  """
  @spec command(t(), command()) :: t()
  def command(pipe, parts) when is_list(parts), do: add(pipe, parts)

  # -- flush ---------------------------------------------------------------

  @doc """
  Flush the batch once through the opaque `via.pipeline/3` (an `EchoMQ.Connector`
  or an `EchoMQ.Pool`); answers `{:ok, [reply]}` with one reply per appended
  command, in call order. An empty pipe answers `{:error, :empty_pipeline}`
  without calling the wire.
  """
  @spec exec(t()) :: {:ok, [EchoMQ.RESP.reply()]} | {:error, term()}
  def exec(%__MODULE__{cmds: []}), do: {:error, :empty_pipeline}

  def exec(%__MODULE__{conn: conn, via: via, timeout: timeout, cmds: cmds}) do
    via.pipeline(conn, Enum.reverse(cmds), timeout)
  end

  @doc """
  Flush the batch inside `MULTI`/`EXEC` via `EchoMQ.Connector.transaction_pipeline/3`;
  answers `{:ok, exec_replies}`. Requires a single `EchoMQ.Connector` (a pool
  pins no connection across a transaction — out of contract). An empty pipe
  answers `{:error, :empty_pipeline}`.
  """
  @spec exec_txn(t()) :: {:ok, [EchoMQ.RESP.reply()]} | {:error, term()}
  def exec_txn(%__MODULE__{cmds: []}), do: {:error, :empty_pipeline}

  def exec_txn(%__MODULE__{conn: conn, timeout: timeout, cmds: cmds}) do
    Connector.transaction_pipeline(conn, Enum.reverse(cmds), timeout)
  end

  @doc """
  Flush the batch with replies suppressed wire-side (`CLIENT REPLY OFF`/`ON`)
  via `EchoMQ.Connector.noreply_pipeline/3`; answers `:ok`. Requires a single
  `EchoMQ.Connector` (out of contract for a pool). An empty pipe answers
  `{:error, :empty_pipeline}`.
  """
  @spec exec_noreply(t()) :: :ok | {:error, term()}
  def exec_noreply(%__MODULE__{cmds: []}), do: {:error, :empty_pipeline}

  def exec_noreply(%__MODULE__{conn: conn, timeout: timeout, cmds: cmds}) do
    Connector.noreply_pipeline(conn, Enum.reverse(cmds), timeout)
  end

  # -- internals -----------------------------------------------------------

  # Prepend one command-list (newest-first); the flush verbs reverse once so
  # the flushed order equals the call order (D6).
  @spec add(t(), command()) :: t()
  defp add(%__MODULE__{cmds: cmds} = pipe, parts), do: %{pipe | cmds: [parts | cmds]}

  # SET option chain → trailing tokens (rueidis SetCondition*/ExSeconds/PxMilliseconds/Get/KeepTtl).
  defp set_opts(opts) do
    Enum.flat_map(opts, fn
      {:ex, s} -> ["EX", to_token(s)]
      {:px, ms} -> ["PX", to_token(ms)]
      {:exat, ts} -> ["EXAT", to_token(ts)]
      {:pxat, ts} -> ["PXAT", to_token(ts)]
      {:nx, true} -> ["NX"]
      {:xx, true} -> ["XX"]
      {:keepttl, true} -> ["KEEPTTL"]
      {:get, true} -> ["GET"]
      {_k, false} -> []
    end)
  end

  # SCAN/SSCAN/ZSCAN option chain → trailing tokens.
  defp scan_opts(opts) do
    Enum.flat_map(opts, fn
      {:match, pat} -> ["MATCH", pat]
      {:count, n} -> ["COUNT", to_token(n)]
      {:type, t} -> ["TYPE", t]
    end)
  end

  # HSCAN adds NOVALUES.
  defp hscan_opts(opts) do
    Enum.flat_map(opts, fn
      {:match, pat} -> ["MATCH", pat]
      {:count, n} -> ["COUNT", to_token(n)]
      {:novalues, true} -> ["NOVALUES"]
      {:novalues, false} -> []
    end)
  end

  # ZADD condition/comparison chain → trailing tokens (rueidis ZaddCondition*/ZaddComparison*/Ch/Incr).
  defp zadd_opts(opts) do
    Enum.flat_map(opts, fn
      {:nx, true} -> ["NX"]
      {:xx, true} -> ["XX"]
      {:gt, true} -> ["GT"]
      {:lt, true} -> ["LT"]
      {:ch, true} -> ["CH"]
      {:incr, true} -> ["INCR"]
      {_k, false} -> []
    end)
  end

  defp zrange_opts(opts) do
    Enum.flat_map(opts, fn
      {:withscores, true} -> ["WITHSCORES"]
      {:rev, true} -> ["REV"]
      {_k, false} -> []
    end)
  end

  defp zrangebyscore_opts(opts) do
    Enum.flat_map(opts, fn
      {:withscores, true} -> ["WITHSCORES"]
      {:limit, {offset, count}} -> ["LIMIT", to_token(offset), to_token(count)]
      {_k, false} -> []
    end)
  end

  defp withscores_opt(opts) do
    if Keyword.get(opts, :withscores, false), do: ["WITHSCORES"], else: []
  end

  defp insert_where(:before), do: "BEFORE"
  defp insert_where(:after), do: "AFTER"
  defp insert_where(w) when is_binary(w), do: w

  defp side(:left), do: "LEFT"
  defp side(:right), do: "RIGHT"
  defp side(s) when is_binary(s), do: s

  # `[{k, v}]` | `%{k => v}` | flat `[k, v, ...]` → flat `[k, v, ...]`.
  defp flatten_pairs(map) when is_map(map), do: Enum.flat_map(map, fn {k, v} -> [k, v] end)

  defp flatten_pairs([{_, _} | _] = pairs),
    do: Enum.flat_map(pairs, fn {k, v} -> [k, v] end)

  defp flatten_pairs(flat) when is_list(flat), do: flat

  # `[{score, member}]` → flat `[score, member, ...]` with scores tokenized.
  defp flatten_score_members(pairs),
    do: Enum.flat_map(pairs, fn {score, member} -> [to_token(score), member] end)

  # Keep binaries/atoms as-is; render numbers as decimal strings so a float
  # score/increment is an explicit token rather than relying on RESP coercion.
  defp to_token(v) when is_binary(v), do: v
  defp to_token(v) when is_integer(v), do: v
  defp to_token(v) when is_float(v), do: Float.to_string(v)
  defp to_token(v) when is_atom(v), do: v
end
