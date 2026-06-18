defmodule EchoWire.CmdTest do
  @moduledoc """
  EWR.1.2 — the fluent builder: the `set |> value |> ex |> build` chains
  produce the right parts across the six families; an un-built builder is a
  distinct intermediate; `build/1` stamps the static per-verb flag + slot; the
  `Pipe.command/2`-accepts-`%Command{}` equivalence and the `run/2`-vs-bare-verb
  `parts` equality. Fully offline (no `run/2` flush — that is the `:valkey`
  story layer).
  """
  use ExUnit.Case, async: true

  alias EchoWire.{Cmd, Command, Pipe}

  describe "the builder chain shape" do
    test "set |> value |> ex |> build yields the expected %Command{}" do
      # `ex/2` tokenizes the seconds with the ewr.1.1 `to_token` idiom: an
      # integer stays an integer token (RESP encodes it identically to its
      # decimal string), matching `Pipe.set(.., ex: 60)` exactly.
      cmd = Cmd.set("user:1") |> Cmd.value("alice") |> Cmd.ex(60) |> Cmd.build()
      assert cmd.parts == ["SET", "user:1", "alice", "EX", 60]
      assert %Command{} = cmd
    end

    test "an un-built builder is a DISTINCT intermediate, not a %Command{}" do
      builder = Cmd.set("k") |> Cmd.value("v")
      assert %Cmd{} = builder
      # the un-built builder's struct module is EchoWire.Cmd, not EchoWire.Command
      assert builder.__struct__ == EchoWire.Cmd
      refute builder.__struct__ == EchoWire.Command
      # closing it produces the value
      assert %Command{} = Cmd.build(builder)
    end

    test "the SET option setters render as trailing tokens" do
      cmd = Cmd.set("k") |> Cmd.value("v") |> Cmd.nx() |> Cmd.keepttl() |> Cmd.build()
      assert cmd.parts == ["SET", "k", "v", "NX", "KEEPTTL"]
    end

    test "arg/2 is the builder's own escape hatch for an un-modeled trailing option" do
      cmd = Cmd.set("k") |> Cmd.value("v") |> Cmd.arg(["IDLE", 5]) |> Cmd.build()
      assert cmd.parts == ["SET", "k", "v", "IDLE", 5]
    end
  end

  describe "the six families render the right parts" do
    test "strings" do
      assert (Cmd.get("k") |> Cmd.build()).parts == ["GET", "k"]
      assert (Cmd.mget(["a", "b"]) |> Cmd.build()).parts == ["MGET", "a", "b"]
      assert (Cmd.incrby("k", 3) |> Cmd.build()).parts == ["INCRBY", "k", 3]
      assert (Cmd.append("k", "x") |> Cmd.build()).parts == ["APPEND", "k", "x"]
    end

    test "keys / generic" do
      assert (Cmd.del(["a", "b"]) |> Cmd.build()).parts == ["DEL", "a", "b"]
      assert (Cmd.ttl("k") |> Cmd.build()).parts == ["TTL", "k"]
      assert (Cmd.expire("k", 60) |> Cmd.build()).parts == ["EXPIRE", "k", 60]
      assert (Cmd.copy("a", "b") |> Cmd.build()).parts == ["COPY", "a", "b"]
    end

    test "hashes" do
      assert (Cmd.hset("h", "f", "v") |> Cmd.build()).parts == ["HSET", "h", "f", "v"]
      assert (Cmd.hgetall("h") |> Cmd.build()).parts == ["HGETALL", "h"]
      assert (Cmd.hset_all("h", [{"a", "1"}, {"b", "2"}]) |> Cmd.build()).parts ==
               ["HSET", "h", "a", "1", "b", "2"]
    end

    test "lists" do
      assert (Cmd.lpush("l", ["a", "b"]) |> Cmd.build()).parts == ["LPUSH", "l", "a", "b"]
      assert (Cmd.lrange("l", 0, -1) |> Cmd.build()).parts == ["LRANGE", "l", 0, -1]
      assert (Cmd.lmove("a", "b", :left, :right) |> Cmd.build()).parts ==
               ["LMOVE", "a", "b", "LEFT", "RIGHT"]
    end

    test "sets" do
      assert (Cmd.sadd("s", ["a", "b"]) |> Cmd.build()).parts == ["SADD", "s", "a", "b"]
      assert (Cmd.sismember("s", "a") |> Cmd.build()).parts == ["SISMEMBER", "s", "a"]
    end

    test "sorted sets" do
      assert (Cmd.zadd("z") |> Cmd.score(1.5, "a") |> Cmd.build()).parts ==
               ["ZADD", "z", "1.5", "a"]

      assert (Cmd.zadd("z") |> Cmd.nx() |> Cmd.ch() |> Cmd.score(2, "b") |> Cmd.build()).parts ==
               ["ZADD", "z", "NX", "CH", 2, "b"]

      assert (Cmd.zrange("z", 0, -1) |> Cmd.withscores() |> Cmd.build()).parts ==
               ["ZRANGE", "z", 0, -1, "WITHSCORES"]
    end
  end

  describe "build/1 stamps the static flag + slot per family" do
    test "reads are readonly, writes are writes, blocks are block" do
      assert Command.readonly?(Cmd.hget("h", "f") |> Cmd.build())
      assert Command.readonly?(Cmd.zscore("z", "m") |> Cmd.build())
      assert Command.readonly?(Cmd.smembers("s") |> Cmd.build())
      assert Command.write?(Cmd.hset("h", "f", "v") |> Cmd.build())
      assert Command.write?(Cmd.sadd("s", "m") |> Cmd.build())
      assert Command.block?(Cmd.brpop("q", 1) |> Cmd.build())
    end

    test "the slot is computed from the command's key" do
      cmd = Cmd.get("user:1") |> Cmd.build()
      assert cmd.slot == Command.slot_of("user:1")

      # multi-key: slot from the first key
      mget = Cmd.mget(["{u}:1", "{u}:2"]) |> Cmd.build()
      assert mget.slot == Command.slot_of("{u}:1")
    end
  end

  describe "EWR.1.2-INV1 — the facade stays 11; run/2 is on EchoWire.Cmd" do
    test "EchoWire.run/2 does NOT exist" do
      refute function_exported?(EchoWire, :run, 2)
    end

    test "EchoWire.Cmd.run/2 DOES exist" do
      assert function_exported?(EchoWire.Cmd, :run, 2)
    end
  end

  describe "EWR.1.2-INV4 — a %Command{} flushes only its .parts (the wire never sees a flag)" do
    test "Pipe.command/2 accepts a %Command{} and appends exactly its parts" do
      cmd = Cmd.get("k") |> Cmd.build()
      # a pipe built with the %Command{} and one built with the raw list carry
      # the identical accumulated cmds.
      via_command = :sentinel_conn |> Pipe.new() |> Pipe.command(cmd)
      via_raw = :sentinel_conn |> Pipe.new() |> Pipe.command(["GET", "k"])
      assert via_command.cmds == via_raw.cmds
      assert via_command.cmds == [["GET", "k"]]
    end

    test "a flagged %Command{} and the bare Pipe verb accumulate the SAME cmds (byte-equivalence, offline)" do
      cmd = Cmd.set("user:1") |> Cmd.value("alice") |> Cmd.ex(60) |> Cmd.build()
      via_command = :c |> Pipe.new() |> Pipe.command(cmd)
      via_verb = :c |> Pipe.new() |> Pipe.set("user:1", "alice", ex: 60)
      assert via_command.cmds == via_verb.cmds
    end

    test "a raw/1 %Command{}, a curated %Command{}, and the Pipe verb are all wire-equivalent (INV6)" do
      raw = Command.raw(["GET", "k"])
      curated = Cmd.get("k") |> Cmd.build()
      p_raw = :c |> Pipe.new() |> Pipe.command(raw)
      p_curated = :c |> Pipe.new() |> Pipe.command(curated)
      p_verb = :c |> Pipe.new() |> Pipe.get("k")
      assert p_raw.cmds == p_curated.cmds
      assert p_curated.cmds == p_verb.cmds
    end
  end

  describe "EWR.1.2-D6 — run/2 extracts .parts (the parts a flush would carry)" do
    test "run/2 over a list maps each command to its .parts (the pipeline payload), in order" do
      # Prove the payload run/2 would flush equals the bare command-lists, by
      # routing through a stub `via` that captures its cmds argument.
      cmds = [
        Cmd.set("a") |> Cmd.value("1") |> Cmd.build(),
        Cmd.get("a") |> Cmd.build(),
        Cmd.incr("hits") |> Cmd.build()
      ]

      assert Cmd.run(cmds, conn: :stub, via: EchoWire.CmdTest.CaptureVia) ==
               {:captured, :stub,
                [["SET", "a", "1"], ["GET", "a"], ["INCR", "hits"]], 5_000}
    end

    test "run/2 of a single %Command{} wraps it into a one-command payload" do
      cmd = Cmd.get("k") |> Cmd.build()

      assert Cmd.run(cmd, conn: :stub, via: EchoWire.CmdTest.CaptureVia) ==
               {:captured, :stub, [["GET", "k"]], 5_000}
    end

    test "run/2 of an empty list answers {:error, :empty_pipeline} (parity with Pipe)" do
      assert Cmd.run([], conn: :stub, via: EchoWire.CmdTest.CaptureVia) ==
               {:error, :empty_pipeline}
    end

    test "run/2 carries the dispatch opaquely — it never inspects the reference" do
      # A bare reference (not a keyword) routes to the default Connector dispatch;
      # the body has no is_struct/is_atom/module guard. We assert it does not
      # crash on an atom reference by routing through a capturing via passed as
      # a keyword (the conn stays opaque).
      cmd = Cmd.get("k") |> Cmd.build()

      assert {:captured, {:whatever, :ref}, [["GET", "k"]], 1_234} =
               Cmd.run(cmd,
                 conn: {:whatever, :ref},
                 via: EchoWire.CmdTest.CaptureVia,
                 timeout: 1_234
               )
    end
  end

  # A stub `via` capturing the (conn, cmds, timeout) run/2 flushes — proves the
  # extracted payload without a live Valkey (that is the story layer's job).
  defmodule CaptureVia do
    def pipeline(conn, cmds, timeout), do: {:captured, conn, cmds, timeout}
  end
end
