defmodule EchoWire.Cmd do
  @moduledoc """
  The fluent command builder — the rueidis type-state builder chain
  (`Builder.Set()` → `Set.Key(k)` → `SetKey.Value(v)` → `SetValue.Build()`,
  `gen_string.go:1487,1956,1998,2043`) reimagined as `|>`. It mints an
  immutable `EchoWire.Command` carrying parts + the **static per-verb** `cf`
  flags + the cluster key-slot:

      EchoWire.Cmd.set("user:1") |> EchoWire.Cmd.value("alice") |> EchoWire.Cmd.ex(60) |> EchoWire.Cmd.build()
      # => %EchoWire.Command{parts: ["SET","user:1","alice","EX","60"], flags: 0, slot: 14116}

      EchoWire.Cmd.get("user:1") |> EchoWire.Cmd.build()
      # => %EchoWire.Command{parts: ["GET","user:1"], flags: 8320, slot: 14116}

  ## The chain shape

  - A **verb-opener** (`set/1`, `get/1`, … one per principal verb across the
    six Valkey data families) returns an **un-built builder** — a distinct
    `%EchoWire.Cmd{}` intermediate (not a `%Command{}`).
  - **token-setters** (`value/2`, `ex/2`, `nx/1`, …) append tokens to the
    builder.
  - **`build/1`** freezes the builder into a `%EchoWire.Command{}`, stamping
    `parts` + the verb's **static** flags (looked up by the verb atom the
    opener carried — never parsed from `parts`) + the key-slot
    (`crc16(key | {hashtag}) & 16_383`).

  Dynamic Elixir cannot enforce the rueidis compile-time type-state, so
  `build/1` is a **runtime closing token**: passing an un-built builder to
  `run/2` or `EchoWire.Pipe.command/2` is a `FunctionClauseError` at the call
  boundary (the accepted cost of the `|>` reimagining).

  ## Running a built command

  `run/2` runs a built `%Command{}` (or a `[%Command{}]`) against a
  conn-or-pool through the **opaque `via` dispatch** — mirroring `Pipe`: the
  default is `EchoMQ.Connector`, `EchoMQ.Pool` via `opts[:via]`, and the
  reference is **never inspected**. It extracts `.parts` and flushes once
  through `via.pipeline/3`. `run/2` is on `EchoWire.Cmd`, **never** a 12th
  `EchoWire` facade verb.

  ## Flags are advisory; the curated set is never a ceiling

  The flags are **advisory** this rung (the roadmap's seam 4 — no consumer in
  the wire): they are carried on the value, dropped at `run/2` and at the
  `Pipe` seam, and read by nothing. Any un-curated verb is reachable via
  `EchoWire.Command.raw/1`.
  """

  alias EchoWire.Command
  alias EchoMQ.Connector

  @default_timeout 5_000

  @typedoc "An un-built builder — distinct from `EchoWire.Command`; close it with `build/1`."
  @type t :: %__MODULE__{
          verb: atom(),
          parts: [Command.part()],
          key: binary() | nil
        }

  defstruct verb: nil, parts: [], key: nil

  # -- the static per-verb flag table (cmds.go:5-23 per-verb stamp) --------
  #
  # The verb decides the flag, stamped at build time (INV3) — NEVER parsed
  # from `parts`. A verb absent from this map is a write (cf zero), the
  # rueidis default (`Set()` leaves cf zero). Grounded in the gen_*.go
  # per-verb `cf:` stamps:
  #   reads        → :readonly   (gen_string.go:232, gen_set.go, gen_sorted_set.go, gen_generic.go, gen_hash.go)
  #   MGET         → :mt_get     (gen_string.go:1077)
  #   BLPOP/BRPOP/BLMOVE → :block (gen_list.go:10/192, gen_sorted_set.go:105/157)
  @verb_flag %{
    # strings (gen_string.go)
    get: :readonly,
    mget: :mt_get,
    strlen: :readonly,
    getrange: :readonly,
    # generic / keys + expiry (gen_generic.go)
    exists: :readonly,
    ttl: :readonly,
    pttl: :readonly,
    type: :readonly,
    # hashes (gen_hash.go)
    hget: :readonly,
    hmget: :readonly,
    hgetall: :readonly,
    hexists: :readonly,
    hkeys: :readonly,
    hvals: :readonly,
    hlen: :readonly,
    # lists (gen_list.go)
    lrange: :readonly,
    llen: :readonly,
    lindex: :readonly,
    blpop: :block,
    brpop: :block,
    blmove: :block,
    # sets (gen_set.go)
    smembers: :readonly,
    sismember: :readonly,
    scard: :readonly,
    srandmember: :readonly,
    smismember: :readonly,
    sscan: :readonly,
    # sorted sets (gen_sorted_set.go)
    zrange: :readonly,
    zrevrange: :readonly,
    zscore: :readonly,
    zcard: :readonly,
    zrank: :readonly,
    zcount: :readonly,
    zscan: :readonly
  }

  # ========================================================================
  # strings (gen_string.go)
  # ========================================================================

  @doc "Open a GET builder (`readonly`)."
  @spec get(binary()) :: t()
  def get(key), do: open(:get, ["GET", key], key)

  @doc "Open a SET builder (a write); chain `value/2` + `ex/2`/`px/2`/`nx/1`/`xx/1`/`keepttl/1`/`get_opt/1`."
  @spec set(binary()) :: t()
  def set(key), do: open(:set, ["SET", key], key)

  @doc "Open a GETSET builder (a write)."
  @spec getset(binary(), binary()) :: t()
  def getset(key, value), do: open(:getset, ["GETSET", key, value], key)

  @doc "Open a GETDEL builder (a write)."
  @spec getdel(binary()) :: t()
  def getdel(key), do: open(:getdel, ["GETDEL", key], key)

  @doc "Open an MGET builder (`mt_get`, implies `readonly`). Slot from the first key."
  @spec mget([binary()]) :: t()
  def mget([first | _] = keys) when is_list(keys), do: open(:mget, ["MGET" | keys], first)

  @doc "Open an MSET builder (a write) from a `[{k, v}]` / flat `[k, v, ...]` list. Slot from the first key."
  @spec mset([{binary(), binary()}] | [binary()]) :: t()
  def mset(pairs) do
    flat = flatten_pairs(pairs)
    open(:mset, ["MSET" | flat], List.first(flat))
  end

  @doc "Open an INCR builder (a write)."
  @spec incr(binary()) :: t()
  def incr(key), do: open(:incr, ["INCR", key], key)

  @doc "Open an INCRBY builder (a write)."
  @spec incrby(binary(), integer()) :: t()
  def incrby(key, by), do: open(:incrby, ["INCRBY", key, by], key)

  @doc "Open a DECR builder (a write)."
  @spec decr(binary()) :: t()
  def decr(key), do: open(:decr, ["DECR", key], key)

  @doc "Open a DECRBY builder (a write)."
  @spec decrby(binary(), integer()) :: t()
  def decrby(key, by), do: open(:decrby, ["DECRBY", key, by], key)

  @doc "Open an APPEND builder (a write)."
  @spec append(binary(), binary()) :: t()
  def append(key, value), do: open(:append, ["APPEND", key, value], key)

  @doc "Open a STRLEN builder (`readonly`)."
  @spec strlen(binary()) :: t()
  def strlen(key), do: open(:strlen, ["STRLEN", key], key)

  @doc "Open a SETEX builder (a write)."
  @spec setex(binary(), integer(), binary()) :: t()
  def setex(key, seconds, value), do: open(:setex, ["SETEX", key, seconds, value], key)

  @doc "Open a SETNX builder (a write)."
  @spec setnx(binary(), binary()) :: t()
  def setnx(key, value), do: open(:setnx, ["SETNX", key, value], key)

  @doc "Open a GETRANGE builder (`readonly`)."
  @spec getrange(binary(), integer(), integer()) :: t()
  def getrange(key, start, stop), do: open(:getrange, ["GETRANGE", key, start, stop], key)

  # ========================================================================
  # keys / generic + expiry (gen_generic.go)
  # ========================================================================

  @doc "Open a DEL builder (a write). Slot from the first key."
  @spec del(binary() | [binary()]) :: t()
  def del(keys), do: open_multi(:del, "DEL", keys)

  @doc "Open an UNLINK builder (a write). Slot from the first key."
  @spec unlink(binary() | [binary()]) :: t()
  def unlink(keys), do: open_multi(:unlink, "UNLINK", keys)

  @doc "Open an EXISTS builder (`readonly`). Slot from the first key."
  @spec exists(binary() | [binary()]) :: t()
  def exists(keys), do: open_multi(:exists, "EXISTS", keys)

  @doc "Open an EXPIRE builder (a write)."
  @spec expire(binary(), integer()) :: t()
  def expire(key, seconds), do: open(:expire, ["EXPIRE", key, seconds], key)

  @doc "Open a PEXPIRE builder (a write)."
  @spec pexpire(binary(), integer()) :: t()
  def pexpire(key, ms), do: open(:pexpire, ["PEXPIRE", key, ms], key)

  @doc "Open a TTL builder (`readonly`)."
  @spec ttl(binary()) :: t()
  def ttl(key), do: open(:ttl, ["TTL", key], key)

  @doc "Open a PTTL builder (`readonly`)."
  @spec pttl(binary()) :: t()
  def pttl(key), do: open(:pttl, ["PTTL", key], key)

  @doc "Open a PERSIST builder (a write)."
  @spec persist(binary()) :: t()
  def persist(key), do: open(:persist, ["PERSIST", key], key)

  @doc "Open a TYPE builder (`readonly`)."
  @spec type(binary()) :: t()
  def type(key), do: open(:type, ["TYPE", key], key)

  @doc "Open a RENAME builder (a write). Slot from the source key."
  @spec rename(binary(), binary()) :: t()
  def rename(key, newkey), do: open(:rename, ["RENAME", key, newkey], key)

  @doc "Open a RENAMENX builder (a write). Slot from the source key."
  @spec renamenx(binary(), binary()) :: t()
  def renamenx(key, newkey), do: open(:renamenx, ["RENAMENX", key, newkey], key)

  @doc "Open a SCAN builder (a write — a cursor op). No single key → no slot."
  @spec scan(integer() | binary()) :: t()
  def scan(cursor), do: open(:scan, ["SCAN", cursor], nil)

  @doc "Open a TOUCH builder (a write). Slot from the first key."
  @spec touch(binary() | [binary()]) :: t()
  def touch(keys), do: open_multi(:touch, "TOUCH", keys)

  @doc "Open a COPY builder (a write). Slot from the source key."
  @spec copy(binary(), binary()) :: t()
  def copy(src, dst), do: open(:copy, ["COPY", src, dst], src)

  # ========================================================================
  # hashes (gen_hash.go)
  # ========================================================================

  @doc "Open an HSET builder (a write, single field)."
  @spec hset(binary(), binary(), binary()) :: t()
  def hset(key, field, value), do: open(:hset, ["HSET", key, field, value], key)

  @doc "Open a multi-field HSET builder (a write) from a `[{f, v}]` / flat list / map."
  @spec hset_all(binary(), [{binary(), binary()}] | [binary()] | map()) :: t()
  def hset_all(key, fields), do: open(:hset_all, ["HSET", key | flatten_pairs(fields)], key)

  @doc "Open an HGET builder (`readonly`)."
  @spec hget(binary(), binary()) :: t()
  def hget(key, field), do: open(:hget, ["HGET", key, field], key)

  @doc "Open an HMGET builder (`readonly`)."
  @spec hmget(binary(), [binary()]) :: t()
  def hmget(key, fields) when is_list(fields), do: open(:hmget, ["HMGET", key | fields], key)

  @doc "Open an HGETALL builder (`readonly`)."
  @spec hgetall(binary()) :: t()
  def hgetall(key), do: open(:hgetall, ["HGETALL", key], key)

  @doc "Open an HDEL builder (a write)."
  @spec hdel(binary(), binary() | [binary()]) :: t()
  def hdel(key, fields), do: open(:hdel, ["HDEL", key | List.wrap(fields)], key)

  @doc "Open an HEXISTS builder (`readonly`)."
  @spec hexists(binary(), binary()) :: t()
  def hexists(key, field), do: open(:hexists, ["HEXISTS", key, field], key)

  @doc "Open an HINCRBY builder (a write)."
  @spec hincrby(binary(), binary(), integer()) :: t()
  def hincrby(key, field, by), do: open(:hincrby, ["HINCRBY", key, field, by], key)

  @doc "Open an HKEYS builder (`readonly`)."
  @spec hkeys(binary()) :: t()
  def hkeys(key), do: open(:hkeys, ["HKEYS", key], key)

  @doc "Open an HVALS builder (`readonly`)."
  @spec hvals(binary()) :: t()
  def hvals(key), do: open(:hvals, ["HVALS", key], key)

  @doc "Open an HLEN builder (`readonly`)."
  @spec hlen(binary()) :: t()
  def hlen(key), do: open(:hlen, ["HLEN", key], key)

  @doc "Open an HSETNX builder (a write)."
  @spec hsetnx(binary(), binary(), binary()) :: t()
  def hsetnx(key, field, value), do: open(:hsetnx, ["HSETNX", key, field, value], key)

  # ========================================================================
  # lists (gen_list.go)
  # ========================================================================

  @doc "Open an LPUSH builder (a write)."
  @spec lpush(binary(), binary() | [binary()]) :: t()
  def lpush(key, values), do: open(:lpush, ["LPUSH", key | List.wrap(values)], key)

  @doc "Open an RPUSH builder (a write)."
  @spec rpush(binary(), binary() | [binary()]) :: t()
  def rpush(key, values), do: open(:rpush, ["RPUSH", key | List.wrap(values)], key)

  @doc "Open an LPOP builder (a write)."
  @spec lpop(binary()) :: t()
  def lpop(key), do: open(:lpop, ["LPOP", key], key)

  @doc "Open an RPOP builder (a write)."
  @spec rpop(binary()) :: t()
  def rpop(key), do: open(:rpop, ["RPOP", key], key)

  @doc "Open an LRANGE builder (`readonly`)."
  @spec lrange(binary(), integer(), integer()) :: t()
  def lrange(key, start, stop), do: open(:lrange, ["LRANGE", key, start, stop], key)

  @doc "Open an LLEN builder (`readonly`)."
  @spec llen(binary()) :: t()
  def llen(key), do: open(:llen, ["LLEN", key], key)

  @doc "Open an LINDEX builder (`readonly`)."
  @spec lindex(binary(), integer()) :: t()
  def lindex(key, index), do: open(:lindex, ["LINDEX", key, index], key)

  @doc "Open an LSET builder (a write)."
  @spec lset(binary(), integer(), binary()) :: t()
  def lset(key, index, value), do: open(:lset, ["LSET", key, index, value], key)

  @doc "Open an LREM builder (a write)."
  @spec lrem(binary(), integer(), binary()) :: t()
  def lrem(key, count, value), do: open(:lrem, ["LREM", key, count, value], key)

  @doc "Open an LTRIM builder (a write)."
  @spec ltrim(binary(), integer(), integer()) :: t()
  def ltrim(key, start, stop), do: open(:ltrim, ["LTRIM", key, start, stop], key)

  @doc "Open an RPOPLPUSH builder (a write). Slot from the source key."
  @spec rpoplpush(binary(), binary()) :: t()
  def rpoplpush(src, dst), do: open(:rpoplpush, ["RPOPLPUSH", src, dst], src)

  @doc "Open an LMOVE builder (a write). Slot from the source key."
  @spec lmove(binary(), binary(), :left | :right | binary(), :left | :right | binary()) :: t()
  def lmove(src, dst, from, to), do: open(:lmove, ["LMOVE", src, dst, side(from), side(to)], src)

  @doc "Open a BLPOP builder (`block` — a blocking command needing a dedicated connection)."
  @spec blpop(binary() | [binary()], integer()) :: t()
  def blpop(keys, timeout) do
    list = List.wrap(keys)
    open(:blpop, ["BLPOP" | list] ++ [timeout], List.first(list))
  end

  @doc "Open a BRPOP builder (`block`)."
  @spec brpop(binary() | [binary()], integer()) :: t()
  def brpop(keys, timeout) do
    list = List.wrap(keys)
    open(:brpop, ["BRPOP" | list] ++ [timeout], List.first(list))
  end

  @doc "Open a BLMOVE builder (`block`). Slot from the source key."
  @spec blmove(binary(), binary(), :left | :right | binary(), :left | :right | binary(), integer()) :: t()
  def blmove(src, dst, from, to, timeout),
    do: open(:blmove, ["BLMOVE", src, dst, side(from), side(to), timeout], src)

  # ========================================================================
  # sets (gen_set.go)
  # ========================================================================

  @doc "Open a SADD builder (a write)."
  @spec sadd(binary(), binary() | [binary()]) :: t()
  def sadd(key, members), do: open(:sadd, ["SADD", key | List.wrap(members)], key)

  @doc "Open a SREM builder (a write)."
  @spec srem(binary(), binary() | [binary()]) :: t()
  def srem(key, members), do: open(:srem, ["SREM", key | List.wrap(members)], key)

  @doc "Open a SMEMBERS builder (`readonly`)."
  @spec smembers(binary()) :: t()
  def smembers(key), do: open(:smembers, ["SMEMBERS", key], key)

  @doc "Open a SISMEMBER builder (`readonly`)."
  @spec sismember(binary(), binary()) :: t()
  def sismember(key, member), do: open(:sismember, ["SISMEMBER", key, member], key)

  @doc "Open a SCARD builder (`readonly`)."
  @spec scard(binary()) :: t()
  def scard(key), do: open(:scard, ["SCARD", key], key)

  @doc "Open a SPOP builder (a write)."
  @spec spop(binary()) :: t()
  def spop(key), do: open(:spop, ["SPOP", key], key)

  @doc "Open a SRANDMEMBER builder (`readonly`)."
  @spec srandmember(binary()) :: t()
  def srandmember(key), do: open(:srandmember, ["SRANDMEMBER", key], key)

  @doc "Open a SMISMEMBER builder (`readonly`)."
  @spec smismember(binary(), binary() | [binary()]) :: t()
  def smismember(key, members), do: open(:smismember, ["SMISMEMBER", key | List.wrap(members)], key)

  @doc "Open an SSCAN builder (`readonly`)."
  @spec sscan(binary(), integer() | binary()) :: t()
  def sscan(key, cursor), do: open(:sscan, ["SSCAN", key, cursor], key)

  # ========================================================================
  # sorted sets (gen_sorted_set.go)
  # ========================================================================

  @doc "Open a ZADD builder (a write); chain `score/3` setters or pass score+member via `member/3`."
  @spec zadd(binary()) :: t()
  def zadd(key), do: open(:zadd, ["ZADD", key], key)

  @doc "Open a ZREM builder (a write)."
  @spec zrem(binary(), binary() | [binary()]) :: t()
  def zrem(key, members), do: open(:zrem, ["ZREM", key | List.wrap(members)], key)

  @doc "Open a ZRANGE builder (`readonly`)."
  @spec zrange(binary(), integer() | binary(), integer() | binary()) :: t()
  def zrange(key, start, stop), do: open(:zrange, ["ZRANGE", key, start, stop], key)

  @doc "Open a ZREVRANGE builder (`readonly`)."
  @spec zrevrange(binary(), integer() | binary(), integer() | binary()) :: t()
  def zrevrange(key, start, stop), do: open(:zrevrange, ["ZREVRANGE", key, start, stop], key)

  @doc "Open a ZSCORE builder (`readonly`)."
  @spec zscore(binary(), binary()) :: t()
  def zscore(key, member), do: open(:zscore, ["ZSCORE", key, member], key)

  @doc "Open a ZCARD builder (`readonly`)."
  @spec zcard(binary()) :: t()
  def zcard(key), do: open(:zcard, ["ZCARD", key], key)

  @doc "Open a ZRANK builder (`readonly`)."
  @spec zrank(binary(), binary()) :: t()
  def zrank(key, member), do: open(:zrank, ["ZRANK", key, member], key)

  @doc "Open a ZINCRBY builder (a write)."
  @spec zincrby(binary(), number() | binary(), binary()) :: t()
  def zincrby(key, increment, member),
    do: open(:zincrby, ["ZINCRBY", key, to_token(increment), member], key)

  @doc "Open a ZPOPMIN builder (a write)."
  @spec zpopmin(binary()) :: t()
  def zpopmin(key), do: open(:zpopmin, ["ZPOPMIN", key], key)

  @doc "Open a ZPOPMAX builder (a write)."
  @spec zpopmax(binary()) :: t()
  def zpopmax(key), do: open(:zpopmax, ["ZPOPMAX", key], key)

  @doc "Open a ZCOUNT builder (`readonly`)."
  @spec zcount(binary(), number() | binary(), number() | binary()) :: t()
  def zcount(key, min, max), do: open(:zcount, ["ZCOUNT", key, to_token(min), to_token(max)], key)

  @doc "Open a ZSCAN builder (`readonly`)."
  @spec zscan(binary(), integer() | binary()) :: t()
  def zscan(key, cursor), do: open(:zscan, ["ZSCAN", key, cursor], key)

  # ========================================================================
  # token-setters (append to the builder) — the chainable `|>` middles
  # ========================================================================

  @doc "Append a VALUE token (the SET value position)."
  @spec value(t(), binary()) :: t()
  def value(%__MODULE__{} = b, v), do: push(b, [v])

  @doc "Append `EX seconds`."
  @spec ex(t(), integer()) :: t()
  def ex(%__MODULE__{} = b, seconds), do: push(b, ["EX", to_token(seconds)])

  @doc "Append `PX milliseconds`."
  @spec px(t(), integer()) :: t()
  def px(%__MODULE__{} = b, ms), do: push(b, ["PX", to_token(ms)])

  @doc "Append `EXAT unix-seconds`."
  @spec exat(t(), integer()) :: t()
  def exat(%__MODULE__{} = b, ts), do: push(b, ["EXAT", to_token(ts)])

  @doc "Append `PXAT unix-millis`."
  @spec pxat(t(), integer()) :: t()
  def pxat(%__MODULE__{} = b, ts), do: push(b, ["PXAT", to_token(ts)])

  @doc "Append the NX condition."
  @spec nx(t()) :: t()
  def nx(%__MODULE__{} = b), do: push(b, ["NX"])

  @doc "Append the XX condition."
  @spec xx(t()) :: t()
  def xx(%__MODULE__{} = b), do: push(b, ["XX"])

  @doc "Append the GT comparison (ZADD)."
  @spec gt(t()) :: t()
  def gt(%__MODULE__{} = b), do: push(b, ["GT"])

  @doc "Append the LT comparison (ZADD)."
  @spec lt(t()) :: t()
  def lt(%__MODULE__{} = b), do: push(b, ["LT"])

  @doc "Append the CH flag (ZADD — count changed)."
  @spec ch(t()) :: t()
  def ch(%__MODULE__{} = b), do: push(b, ["CH"])

  @doc "Append the INCR flag (ZADD — increment mode)."
  @spec incr_opt(t()) :: t()
  def incr_opt(%__MODULE__{} = b), do: push(b, ["INCR"])

  @doc "Append KEEPTTL (SET)."
  @spec keepttl(t()) :: t()
  def keepttl(%__MODULE__{} = b), do: push(b, ["KEEPTTL"])

  @doc "Append GET (SET — return the old value)."
  @spec get_opt(t()) :: t()
  def get_opt(%__MODULE__{} = b), do: push(b, ["GET"])

  @doc "Append a `score member` pair (ZADD)."
  @spec score(t(), number() | binary(), binary()) :: t()
  def score(%__MODULE__{} = b, score, member), do: push(b, [to_token(score), member])

  @doc "Append `MATCH pattern` (SCAN/HSCAN/SSCAN/ZSCAN)."
  @spec match(t(), binary()) :: t()
  def match(%__MODULE__{} = b, pattern), do: push(b, ["MATCH", pattern])

  @doc "Append `COUNT n` (SCAN/HSCAN/SSCAN/ZSCAN)."
  @spec count(t(), integer()) :: t()
  def count(%__MODULE__{} = b, n), do: push(b, ["COUNT", to_token(n)])

  @doc "Append WITHSCORES (ZRANGE/ZREVRANGE)."
  @spec withscores(t()) :: t()
  def withscores(%__MODULE__{} = b), do: push(b, ["WITHSCORES"])

  @doc """
  Append an arbitrary trailing token (or tokens) — the builder's own escape
  hatch for an option a typed setter does not model, without leaving the
  chain.
  """
  @spec arg(t(), Command.part() | [Command.part()]) :: t()
  def arg(%__MODULE__{} = b, tokens) when is_list(tokens), do: push(b, tokens)
  def arg(%__MODULE__{} = b, token), do: push(b, [token])

  # ========================================================================
  # build/1 — freeze the builder into an immutable %Command{}
  # ========================================================================

  @doc """
  Freeze the builder into an immutable `%EchoWire.Command{}`, stamping `parts`
  + the verb's **static** `cf` flags + the key-slot. A runtime closing token:
  it must be called before `run/2` / `EchoWire.Pipe.command/2`.
  """
  @spec build(t()) :: Command.t()
  def build(%__MODULE__{verb: verb, parts: parts, key: key}) do
    Command.new(parts, flags_for(verb), Command.slot_of(key))
  end

  # ========================================================================
  # run/2 — flush a built command (or list) over the opaque `via`
  # ========================================================================

  @doc """
  Run a built `%EchoWire.Command{}` (or a `[%EchoWire.Command{}]`) against a
  conn-or-pool. Extracts the command(s)' `.parts` and flushes **once** through
  the opaque `via.pipeline/3` (default `EchoMQ.Connector`, `EchoMQ.Pool` via
  the `:via` option) — the reference is **never inspected**. Answers
  `{:ok, [reply]}` / `{:error, term}`; an empty list answers
  `{:error, :empty_pipeline}` for parity with `EchoWire.Pipe`.

  `conn_or_opts` is the conn reference, or a keyword carrying `:conn` (+
  optional `:via` / `:timeout`).
  """
  @spec run(Command.t() | [Command.t()], keyword() | GenServer.server()) ::
          {:ok, [EchoMQ.RESP.reply()]} | :ok | {:error, term()}
  def run(cmd_or_list, conn_or_opts) do
    {conn, via, timeout} = dispatch(conn_or_opts)
    cmds = cmd_or_list |> List.wrap() |> Enum.map(&Command.parts/1)
    run_cmds(cmds, conn, via, timeout)
  end

  defp run_cmds([], _conn, _via, _timeout), do: {:error, :empty_pipeline}
  defp run_cmds(cmds, conn, via, timeout), do: via.pipeline(conn, cmds, timeout)

  # The conn-or-pool dispatch — carried, never detected (INV3, the ewr.1.1
  # `%Pipe{via}` opacity pattern). `via` defaults to EchoMQ.Connector; a pool
  # is reached via `via: EchoMQ.Pool`.
  defp dispatch(opts) when is_list(opts) do
    {Keyword.fetch!(opts, :conn), Keyword.get(opts, :via, Connector),
     Keyword.get(opts, :timeout, @default_timeout)}
  end

  defp dispatch(conn), do: {conn, Connector, @default_timeout}

  # -- internals -----------------------------------------------------------

  # Open an un-built builder with the verb (carried for the static flag
  # lookup), its initial parts, and the slot key.
  defp open(verb, parts, key), do: %__MODULE__{verb: verb, parts: parts, key: key}

  # The multi-key openers (DEL/EXISTS/...): slot from the first key.
  defp open_multi(verb, head, keys) do
    list = List.wrap(keys)
    open(verb, [head | list], List.first(list))
  end

  # Append tokens to a builder (chain middles keep call order).
  defp push(%__MODULE__{parts: parts} = b, tokens) when is_list(tokens) do
    %{b | parts: parts ++ tokens}
  end

  # The verb's static flags (INV3 — by the verb, never by the parts). A verb
  # absent from the table is a write (cf zero), the rueidis default.
  defp flags_for(verb) do
    case Map.get(@verb_flag, verb) do
      nil -> Command.flag(:write)
      flag_name -> Command.flag(flag_name)
    end
  end

  defp side(:left), do: "LEFT"
  defp side(:right), do: "RIGHT"
  defp side(s) when is_binary(s), do: s

  # `[{k, v}]` | `%{k => v}` | flat `[k, v, ...]` → flat `[k, v, ...]`.
  defp flatten_pairs(map) when is_map(map), do: Enum.flat_map(map, fn {k, v} -> [k, v] end)
  defp flatten_pairs([{_, _} | _] = pairs), do: Enum.flat_map(pairs, fn {k, v} -> [k, v] end)
  defp flatten_pairs(flat) when is_list(flat), do: flat

  # Render numbers as decimal-string tokens (the ewr.1.1 `to_token` idiom).
  defp to_token(v) when is_binary(v), do: v
  defp to_token(v) when is_integer(v), do: v
  defp to_token(v) when is_float(v), do: Float.to_string(v)
  defp to_token(v) when is_atom(v), do: v
end
