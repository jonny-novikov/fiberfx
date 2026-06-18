defmodule EchoWire.PipeTest do
  @moduledoc """
  The offline construction suite for `EchoWire.Pipe` (EWR.1.1, D2–D6).

  No Valkey: a `%Pipe{}` is an immutable accumulator, so every assertion here
  reads the gathered `cmds` (reversed to call order, exactly as `exec/1`
  flushes it) and proves the `add/2` token rendering, the positional order,
  the `command/2` escape hatch, the empty-pipe guard, and the opaque dispatch
  (`exec` flushes through `via` without inspecting `conn`). The `:valkey`
  round-trip proof lives in the `echo_mq` BDD story suite (the dep direction
  forces it there).
  """
  use ExUnit.Case, async: true

  alias EchoWire.Pipe

  # The exact list-of-commands a pipe would flush, in call order.
  defp built(%Pipe{cmds: cmds}), do: Enum.reverse(cmds)

  describe "new/2 — the accumulator (D2, INV3)" do
    test "seeds an empty pipe carrying conn, the default via, and the default timeout" do
      pipe = Pipe.new(:some_conn)
      assert %Pipe{conn: :some_conn, via: EchoMQ.Connector, timeout: 5_000, cmds: []} = pipe
    end

    test ":via and :timeout come from opts" do
      pipe = Pipe.new(:pool_name, via: EchoMQ.Pool, timeout: 1_000)
      assert %Pipe{conn: :pool_name, via: EchoMQ.Pool, timeout: 1_000} = pipe
    end

    test "the conn reference is stored opaquely — never inspected (any term is accepted)" do
      for ref <- [:atom_conn, self(), {:via, Registry, {R, :k}}, make_ref(), "named"] do
        assert %Pipe{conn: ^ref} = Pipe.new(ref)
      end
    end
  end

  describe "ordering + the empty pipe (D6, INV6)" do
    test "commands accumulate in |> order; the flushed list equals the call order" do
      pipe =
        :c
        |> Pipe.new()
        |> Pipe.set("a", "1")
        |> Pipe.get("a")
        |> Pipe.incr("hits")

      assert built(pipe) == [["SET", "a", "1"], ["GET", "a"], ["INCR", "hits"]]
    end

    test "exec on an empty pipe answers {:error, :empty_pipeline} without touching the wire" do
      assert Pipe.exec(Pipe.new(:c)) == {:error, :empty_pipeline}
      assert Pipe.exec_txn(Pipe.new(:c)) == {:error, :empty_pipeline}
      assert Pipe.exec_noreply(Pipe.new(:c)) == {:error, :empty_pipeline}
    end
  end

  describe "command/2 — the escape hatch (D4, INV6)" do
    test "appends a raw command-list verbatim" do
      pipe =
        :c
        |> Pipe.new()
        |> Pipe.command(["CLIENT", "INFO"])
        |> Pipe.command(["PING"])

      assert built(pipe) == [["CLIENT", "INFO"], ["PING"]]
    end

    test "a pipe built entirely through command/2 equals the curated equivalents" do
      # The curated verb keeps an integer option as an integer token (RESP
      # encodes it identically to its string form), so the raw equivalent
      # carries the same integer — the equivalence is term-for-term here and
      # wire-identical regardless.
      curated = :c |> Pipe.new() |> Pipe.set("k", "v", ex: 60) |> Pipe.get("k")
      raw = :c |> Pipe.new() |> Pipe.command(["SET", "k", "v", "EX", 60]) |> Pipe.command(["GET", "k"])
      assert built(curated) == built(raw)
    end
  end

  describe "strings (gen_string.go)" do
    test "set/3 with no options" do
      assert built(Pipe.set(Pipe.new(:c), "k", "v")) == [["SET", "k", "v"]]
    end

    test "set/4 renders options as trailing tokens, integers verbatim" do
      assert built(Pipe.set(Pipe.new(:c), "k", "v", ex: 60)) == [["SET", "k", "v", "EX", 60]]
      assert built(Pipe.set(Pipe.new(:c), "k", "v", px: 500)) == [["SET", "k", "v", "PX", 500]]
      assert built(Pipe.set(Pipe.new(:c), "k", "v", nx: true)) == [["SET", "k", "v", "NX"]]
      assert built(Pipe.set(Pipe.new(:c), "k", "v", xx: true)) == [["SET", "k", "v", "XX"]]
      assert built(Pipe.set(Pipe.new(:c), "k", "v", get: true)) == [["SET", "k", "v", "GET"]]
      assert built(Pipe.set(Pipe.new(:c), "k", "v", keepttl: true)) == [["SET", "k", "v", "KEEPTTL"]]
      assert built(Pipe.set(Pipe.new(:c), "k", "v", exat: 100)) == [["SET", "k", "v", "EXAT", 100]]
      assert built(Pipe.set(Pipe.new(:c), "k", "v", pxat: 100)) == [["SET", "k", "v", "PXAT", 100]]
    end

    test "a false-valued option contributes no token" do
      assert built(Pipe.set(Pipe.new(:c), "k", "v", nx: false)) == [["SET", "k", "v"]]
    end

    test "options render in keyword order" do
      assert built(Pipe.set(Pipe.new(:c), "k", "v", nx: true, ex: 60)) ==
               [["SET", "k", "v", "NX", "EX", 60]]
    end

    test "the rest of the string family" do
      assert built(Pipe.get(Pipe.new(:c), "k")) == [["GET", "k"]]
      assert built(Pipe.getset(Pipe.new(:c), "k", "v")) == [["GETSET", "k", "v"]]
      assert built(Pipe.getdel(Pipe.new(:c), "k")) == [["GETDEL", "k"]]
      assert built(Pipe.mset(Pipe.new(:c), [{"a", "1"}, {"b", "2"}])) == [["MSET", "a", "1", "b", "2"]]
      assert built(Pipe.mset(Pipe.new(:c), ["a", "1", "b", "2"])) == [["MSET", "a", "1", "b", "2"]]
      assert built(Pipe.mget(Pipe.new(:c), ["a", "b"])) == [["MGET", "a", "b"]]
      assert built(Pipe.append(Pipe.new(:c), "k", "x")) == [["APPEND", "k", "x"]]
      assert built(Pipe.strlen(Pipe.new(:c), "k")) == [["STRLEN", "k"]]
      assert built(Pipe.incr(Pipe.new(:c), "k")) == [["INCR", "k"]]
      assert built(Pipe.incrby(Pipe.new(:c), "k", 5)) == [["INCRBY", "k", 5]]
      assert built(Pipe.decr(Pipe.new(:c), "k")) == [["DECR", "k"]]
      assert built(Pipe.decrby(Pipe.new(:c), "k", 5)) == [["DECRBY", "k", 5]]
      assert built(Pipe.incrbyfloat(Pipe.new(:c), "k", 1.5)) == [["INCRBYFLOAT", "k", "1.5"]]
      assert built(Pipe.setex(Pipe.new(:c), "k", 60, "v")) == [["SETEX", "k", 60, "v"]]
      assert built(Pipe.setnx(Pipe.new(:c), "k", "v")) == [["SETNX", "k", "v"]]
      assert built(Pipe.getrange(Pipe.new(:c), "k", 0, -1)) == [["GETRANGE", "k", 0, -1]]
      assert built(Pipe.setrange(Pipe.new(:c), "k", 2, "x")) == [["SETRANGE", "k", 2, "x"]]
    end
  end

  describe "keys / generic + expiry (gen_generic.go)" do
    test "variadic key verbs wrap a single key or a list" do
      assert built(Pipe.del(Pipe.new(:c), "k")) == [["DEL", "k"]]
      assert built(Pipe.del(Pipe.new(:c), ["a", "b"])) == [["DEL", "a", "b"]]
      assert built(Pipe.unlink(Pipe.new(:c), ["a", "b"])) == [["UNLINK", "a", "b"]]
      assert built(Pipe.exists(Pipe.new(:c), ["a", "b"])) == [["EXISTS", "a", "b"]]
      assert built(Pipe.touch(Pipe.new(:c), "k")) == [["TOUCH", "k"]]
    end

    test "expiry + metadata verbs" do
      assert built(Pipe.expire(Pipe.new(:c), "k", 60)) == [["EXPIRE", "k", 60]]
      assert built(Pipe.pexpire(Pipe.new(:c), "k", 60_000)) == [["PEXPIRE", "k", 60_000]]
      assert built(Pipe.expireat(Pipe.new(:c), "k", 100)) == [["EXPIREAT", "k", 100]]
      assert built(Pipe.pexpireat(Pipe.new(:c), "k", 100)) == [["PEXPIREAT", "k", 100]]
      assert built(Pipe.ttl(Pipe.new(:c), "k")) == [["TTL", "k"]]
      assert built(Pipe.pttl(Pipe.new(:c), "k")) == [["PTTL", "k"]]
      assert built(Pipe.persist(Pipe.new(:c), "k")) == [["PERSIST", "k"]]
      assert built(Pipe.type(Pipe.new(:c), "k")) == [["TYPE", "k"]]
      assert built(Pipe.rename(Pipe.new(:c), "k", "k2")) == [["RENAME", "k", "k2"]]
      assert built(Pipe.renamenx(Pipe.new(:c), "k", "k2")) == [["RENAMENX", "k", "k2"]]
      assert built(Pipe.copy(Pipe.new(:c), "k", "k2")) == [["COPY", "k", "k2"]]
    end

    test "scan/3 renders match/count/type as trailing tokens (the KEYS-avoid path)" do
      assert built(Pipe.scan(Pipe.new(:c), 0)) == [["SCAN", 0]]

      assert built(Pipe.scan(Pipe.new(:c), 0, match: "u:*", count: 100)) ==
               [["SCAN", 0, "MATCH", "u:*", "COUNT", 100]]

      assert built(Pipe.scan(Pipe.new(:c), 0, type: "string")) == [["SCAN", 0, "TYPE", "string"]]
    end
  end

  describe "hashes (gen_hash.go)" do
    test "single-field and multi-field set forms" do
      assert built(Pipe.hset(Pipe.new(:c), "h", "f", "v")) == [["HSET", "h", "f", "v"]]
      assert built(Pipe.hset_all(Pipe.new(:c), "h", [{"f1", "v1"}, {"f2", "v2"}])) ==
               [["HSET", "h", "f1", "v1", "f2", "v2"]]
      assert built(Pipe.hset_all(Pipe.new(:c), "h", ["f1", "v1"])) == [["HSET", "h", "f1", "v1"]]
      assert built(Pipe.hmset(Pipe.new(:c), "h", [{"f", "v"}])) == [["HMSET", "h", "f", "v"]]
    end

    test "the rest of the hash family" do
      assert built(Pipe.hget(Pipe.new(:c), "h", "f")) == [["HGET", "h", "f"]]
      assert built(Pipe.hmget(Pipe.new(:c), "h", ["a", "b"])) == [["HMGET", "h", "a", "b"]]
      assert built(Pipe.hgetall(Pipe.new(:c), "h")) == [["HGETALL", "h"]]
      assert built(Pipe.hdel(Pipe.new(:c), "h", "f")) == [["HDEL", "h", "f"]]
      assert built(Pipe.hdel(Pipe.new(:c), "h", ["a", "b"])) == [["HDEL", "h", "a", "b"]]
      assert built(Pipe.hexists(Pipe.new(:c), "h", "f")) == [["HEXISTS", "h", "f"]]
      assert built(Pipe.hincrby(Pipe.new(:c), "h", "f", 3)) == [["HINCRBY", "h", "f", 3]]
      assert built(Pipe.hincrbyfloat(Pipe.new(:c), "h", "f", 1.5)) == [["HINCRBYFLOAT", "h", "f", "1.5"]]
      assert built(Pipe.hkeys(Pipe.new(:c), "h")) == [["HKEYS", "h"]]
      assert built(Pipe.hvals(Pipe.new(:c), "h")) == [["HVALS", "h"]]
      assert built(Pipe.hlen(Pipe.new(:c), "h")) == [["HLEN", "h"]]
      assert built(Pipe.hsetnx(Pipe.new(:c), "h", "f", "v")) == [["HSETNX", "h", "f", "v"]]
      assert built(Pipe.hscan(Pipe.new(:c), "h", 0, count: 10, novalues: true)) ==
               [["HSCAN", "h", 0, "COUNT", 10, "NOVALUES"]]
    end
  end

  describe "lists (gen_list.go)" do
    test "push variadics, pop with optional count" do
      assert built(Pipe.lpush(Pipe.new(:c), "l", "a")) == [["LPUSH", "l", "a"]]
      assert built(Pipe.lpush(Pipe.new(:c), "l", ["a", "b"])) == [["LPUSH", "l", "a", "b"]]
      assert built(Pipe.rpush(Pipe.new(:c), "l", ["a", "b"])) == [["RPUSH", "l", "a", "b"]]
      assert built(Pipe.lpop(Pipe.new(:c), "l")) == [["LPOP", "l"]]
      assert built(Pipe.lpop(Pipe.new(:c), "l", 2)) == [["LPOP", "l", 2]]
      assert built(Pipe.rpop(Pipe.new(:c), "l")) == [["RPOP", "l"]]
      assert built(Pipe.rpop(Pipe.new(:c), "l", 2)) == [["RPOP", "l", 2]]
    end

    test "the rest of the list family" do
      assert built(Pipe.lrange(Pipe.new(:c), "l", 0, -1)) == [["LRANGE", "l", 0, -1]]
      assert built(Pipe.llen(Pipe.new(:c), "l")) == [["LLEN", "l"]]
      assert built(Pipe.lindex(Pipe.new(:c), "l", 0)) == [["LINDEX", "l", 0]]
      assert built(Pipe.lset(Pipe.new(:c), "l", 0, "v")) == [["LSET", "l", 0, "v"]]
      assert built(Pipe.lrem(Pipe.new(:c), "l", 1, "v")) == [["LREM", "l", 1, "v"]]
      assert built(Pipe.linsert(Pipe.new(:c), "l", :before, "p", "v")) ==
               [["LINSERT", "l", "BEFORE", "p", "v"]]
      assert built(Pipe.linsert(Pipe.new(:c), "l", :after, "p", "v")) ==
               [["LINSERT", "l", "AFTER", "p", "v"]]
      assert built(Pipe.ltrim(Pipe.new(:c), "l", 0, 10)) == [["LTRIM", "l", 0, 10]]
      assert built(Pipe.rpoplpush(Pipe.new(:c), "a", "b")) == [["RPOPLPUSH", "a", "b"]]
      assert built(Pipe.lmove(Pipe.new(:c), "a", "b", :left, :right)) ==
               [["LMOVE", "a", "b", "LEFT", "RIGHT"]]
    end
  end

  describe "sets (gen_set.go)" do
    test "the set family" do
      assert built(Pipe.sadd(Pipe.new(:c), "s", "m")) == [["SADD", "s", "m"]]
      assert built(Pipe.sadd(Pipe.new(:c), "s", ["a", "b"])) == [["SADD", "s", "a", "b"]]
      assert built(Pipe.srem(Pipe.new(:c), "s", ["a", "b"])) == [["SREM", "s", "a", "b"]]
      assert built(Pipe.smembers(Pipe.new(:c), "s")) == [["SMEMBERS", "s"]]
      assert built(Pipe.sismember(Pipe.new(:c), "s", "m")) == [["SISMEMBER", "s", "m"]]
      assert built(Pipe.scard(Pipe.new(:c), "s")) == [["SCARD", "s"]]
      assert built(Pipe.spop(Pipe.new(:c), "s")) == [["SPOP", "s"]]
      assert built(Pipe.spop(Pipe.new(:c), "s", 2)) == [["SPOP", "s", 2]]
      assert built(Pipe.srandmember(Pipe.new(:c), "s")) == [["SRANDMEMBER", "s"]]
      assert built(Pipe.srandmember(Pipe.new(:c), "s", -3)) == [["SRANDMEMBER", "s", -3]]
      assert built(Pipe.sunion(Pipe.new(:c), ["a", "b"])) == [["SUNION", "a", "b"]]
      assert built(Pipe.sinter(Pipe.new(:c), ["a", "b"])) == [["SINTER", "a", "b"]]
      assert built(Pipe.sdiff(Pipe.new(:c), ["a", "b"])) == [["SDIFF", "a", "b"]]
      assert built(Pipe.smismember(Pipe.new(:c), "s", ["a", "b"])) == [["SMISMEMBER", "s", "a", "b"]]
      assert built(Pipe.sscan(Pipe.new(:c), "s", 0, match: "x*")) == [["SSCAN", "s", 0, "MATCH", "x*"]]
    end
  end

  describe "sorted sets (gen_sorted_set.go)" do
    test "zadd single pair, with options as trailing tokens before the score" do
      assert built(Pipe.zadd(Pipe.new(:c), "z", 1.0, "m")) == [["ZADD", "z", "1.0", "m"]]
      assert built(Pipe.zadd(Pipe.new(:c), "z", 5, "m")) == [["ZADD", "z", 5, "m"]]
      assert built(Pipe.zadd(Pipe.new(:c), "z", 1.0, "m", nx: true, ch: true)) ==
               [["ZADD", "z", "NX", "CH", "1.0", "m"]]
      assert built(Pipe.zadd(Pipe.new(:c), "z", 2.0, "m", gt: true)) ==
               [["ZADD", "z", "GT", "2.0", "m"]]
    end

    test "zadd multi-member from a [{score, member}] list" do
      assert built(Pipe.zadd(Pipe.new(:c), "z", [{1.0, "a"}, {2.0, "b"}], [])) ==
               [["ZADD", "z", "1.0", "a", "2.0", "b"]]

      assert built(Pipe.zadd(Pipe.new(:c), "z", [{1, "a"}], nx: true)) ==
               [["ZADD", "z", "NX", 1, "a"]]
    end

    test "ranges with options" do
      assert built(Pipe.zrange(Pipe.new(:c), "z", 0, -1)) == [["ZRANGE", "z", 0, -1]]
      assert built(Pipe.zrange(Pipe.new(:c), "z", 0, -1, withscores: true)) ==
               [["ZRANGE", "z", 0, -1, "WITHSCORES"]]
      assert built(Pipe.zrange(Pipe.new(:c), "z", 0, -1, rev: true)) == [["ZRANGE", "z", 0, -1, "REV"]]
      assert built(Pipe.zrevrange(Pipe.new(:c), "z", 0, -1, withscores: true)) ==
               [["ZREVRANGE", "z", 0, -1, "WITHSCORES"]]
      assert built(Pipe.zrangebyscore(Pipe.new(:c), "z", "-inf", "+inf", limit: {0, 10})) ==
               [["ZRANGEBYSCORE", "z", "-inf", "+inf", "LIMIT", 0, 10]]
      assert built(Pipe.zrangebyscore(Pipe.new(:c), "z", 1, 5)) == [["ZRANGEBYSCORE", "z", 1, 5]]
    end

    test "the rest of the sorted-set family" do
      assert built(Pipe.zrem(Pipe.new(:c), "z", ["a", "b"])) == [["ZREM", "z", "a", "b"]]
      assert built(Pipe.zscore(Pipe.new(:c), "z", "m")) == [["ZSCORE", "z", "m"]]
      assert built(Pipe.zcard(Pipe.new(:c), "z")) == [["ZCARD", "z"]]
      assert built(Pipe.zrank(Pipe.new(:c), "z", "m")) == [["ZRANK", "z", "m"]]
      assert built(Pipe.zrevrank(Pipe.new(:c), "z", "m")) == [["ZREVRANK", "z", "m"]]
      assert built(Pipe.zincrby(Pipe.new(:c), "z", 1.5, "m")) == [["ZINCRBY", "z", "1.5", "m"]]
      assert built(Pipe.zpopmin(Pipe.new(:c), "z")) == [["ZPOPMIN", "z"]]
      assert built(Pipe.zpopmin(Pipe.new(:c), "z", 2)) == [["ZPOPMIN", "z", 2]]
      assert built(Pipe.zpopmax(Pipe.new(:c), "z")) == [["ZPOPMAX", "z"]]
      assert built(Pipe.zpopmax(Pipe.new(:c), "z", 2)) == [["ZPOPMAX", "z", 2]]
      assert built(Pipe.zcount(Pipe.new(:c), "z", "-inf", "+inf")) == [["ZCOUNT", "z", "-inf", "+inf"]]
      assert built(Pipe.zscan(Pipe.new(:c), "z", 0, count: 10)) == [["ZSCAN", "z", 0, "COUNT", 10]]
    end
  end

  describe "exec dispatch is opaque (INV3, INV4) — proven with a stub via" do
    # A stand-in `via` capturing the exact (conn, cmds, timeout) the flush passes,
    # so the offline suite proves: (a) exec calls via.pipeline/3 once,
    # (b) the cmds are reversed to call order, (c) conn + timeout pass through
    # untouched, (d) exec never inspects conn (any term flows through).
    defmodule StubVia do
      def pipeline(conn, cmds, timeout), do: send(self(), {:flushed, conn, cmds, timeout})
    end

    test "exec flushes the reversed cmds through via.pipeline/3 with conn + timeout intact" do
      :the_conn
      |> Pipe.new(via: StubVia, timeout: 1234)
      |> Pipe.set("a", "1")
      |> Pipe.get("a")
      |> Pipe.exec()

      assert_received {:flushed, :the_conn, [["SET", "a", "1"], ["GET", "a"]], 1234}
    end

    test "exec passes an arbitrary opaque conn through without inspection" do
      ref = make_ref()
      Pipe.new(ref, via: StubVia) |> Pipe.incr("n") |> Pipe.exec()
      assert_received {:flushed, ^ref, [["INCR", "n"]], 5_000}
    end
  end
end
