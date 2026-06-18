defmodule EchoWire.CommandTest do
  @moduledoc """
  EWR.1.2 — the immutable command value: the `%Command{parts, flags, slot}`
  struct, the **full `cf` predicate truth table** (with the rueidis
  bit-inclusion), the pure key-slot, and `raw/1`. Fully offline — building a
  command performs no I/O and starts no process.
  """
  use ExUnit.Case, async: true

  alias EchoWire.Command
  alias EchoWire.Cmd

  describe "the struct + accessors" do
    test "a built command exposes parts/1 and slot/1" do
      cmd = Cmd.get("user:1") |> Cmd.build()
      assert Command.parts(cmd) == ["GET", "user:1"]
      assert Command.slot(cmd) == Command.slot_of("user:1")
      assert %Command{} = cmd
    end

    test "building is pure data — deterministic, no linked process" do
      # building twice yields equal values (referential transparency), and the
      # builder links no process to the caller (a pure function over data).
      {:links, links_before} = Process.info(self(), :links)
      cmd1 = Cmd.set("k") |> Cmd.value("v") |> Cmd.build()
      cmd2 = Cmd.set("k") |> Cmd.value("v") |> Cmd.build()
      {:links, links_after} = Process.info(self(), :links)
      assert cmd1 == cmd2
      assert links_before == links_after
    end
  end

  describe "the slot is a pure function of the key (slot.go)" do
    test "the known CRC16-XMODEM vector: slot(\"123456789\") == 12_739" do
      assert Command.slot_of("123456789") == 12_739
    end

    test "a {hashtag} hashes only the inner substring — co-located keys share a slot" do
      assert Command.slot_of("{user}:1") == Command.slot_of("{user}:2")
      assert Command.slot_of("{user}:1") == Command.slot_of("{user}")
    end

    test "an empty or unterminated {hashtag} falls back to hashing the whole key" do
      # "{}x": empty tag → whole-key hash, distinct from the bare "x" slot path
      assert Command.slot_of("{}x") == Command.slot_of("{}x")
      refute Command.slot_of("{}foo") == Command.slot_of("foo")
      # "{foo" (no close) → whole key
      assert Command.slot_of("{foo") != Command.slot_of("foo")
    end

    test "nil key → nil slot" do
      assert Command.slot_of(nil) == nil
    end

    test "the slot is in range 0..16_383" do
      for key <- ["a", "user:1", "{tag}:x", "123456789", "a-very-long-key-name-here"] do
        slot = Command.slot_of(key)
        assert slot >= 0 and slot <= 16_383
      end
    end
  end

  describe "the full cf predicate truth table (cmds.go:147-212) — STATIC per verb" do
    test "GET is readonly (and therefore retryable), not a write" do
      cmd = Cmd.get("k") |> Cmd.build()
      assert Command.readonly?(cmd)
      assert Command.retryable?(cmd)
      refute Command.write?(cmd)
      refute Command.block?(cmd)
      refute Command.noreply?(cmd)
    end

    test "SET is a write (cf zero) — not readonly, not retryable" do
      cmd = Cmd.set("k") |> Cmd.value("v") |> Cmd.build()
      assert Command.write?(cmd)
      refute Command.readonly?(cmd)
      refute Command.retryable?(cmd)
      refute Command.block?(cmd)
    end

    test "MGET carries mt_get — which INCLUDES readonly (and so retryable)" do
      cmd = Cmd.mget(["a", "b"]) |> Cmd.build()
      assert Command.mt_get?(cmd)
      assert Command.readonly?(cmd)
      assert Command.retryable?(cmd)
      refute Command.write?(cmd)
    end

    test "BLPOP carries block — needs a dedicated connection; not readonly" do
      cmd = Cmd.blpop("q", 5) |> Cmd.build()
      assert Command.block?(cmd)
      refute Command.readonly?(cmd)
      refute Command.retryable?(cmd)
    end

    test "the flag-by-verb is STATIC, not parsed from parts — a key literally named \"GET\" does not make a SET readonly" do
      # SET with a value that contains the bytes "GET" stays a write: the verb
      # decides the flag, not a scan of the assembled parts (INV3).
      cmd = Cmd.set("GET") |> Cmd.value("GET") |> Cmd.get_opt() |> Cmd.build()
      assert "GET" in cmd.parts
      assert Command.write?(cmd)
      refute Command.readonly?(cmd)
    end
  end

  describe "the rueidis bit-inclusion (cmds.go:5-23)" do
    test "noreply INCLUDES readonly and pipe (noRetTag ⊇ readonly|pipeTag)" do
      cmd = %Command{parts: ["SUBSCRIBE", "c"], flags: Command.flag(:noreply), slot: nil}
      assert Command.noreply?(cmd)
      assert Command.readonly?(cmd)
      assert Command.pipe?(cmd)
      assert Command.retryable?(cmd)
    end

    test "unsub INCLUDES noreply (unsubTag ⊇ noRetTag)" do
      cmd = %Command{parts: ["UNSUBSCRIBE", "c"], flags: Command.flag(:unsub), slot: nil}
      assert Command.unsub?(cmd)
      assert Command.noreply?(cmd)
      assert Command.readonly?(cmd)
    end

    test "scr_ro INCLUDES readonly (scrRoTag ⊇ readonly)" do
      cmd = %Command{parts: ["EVAL_RO"], flags: Command.flag(:scr_ro), slot: nil}
      assert Command.scr_ro?(cmd)
      assert Command.readonly?(cmd)
      assert Command.retryable?(cmd)
    end

    test "a bare write (cf zero) answers false to every advisory predicate" do
      cmd = %Command{parts: ["SET", "k", "v"], flags: 0, slot: nil}
      refute Command.readonly?(cmd)
      refute Command.retryable?(cmd)
      refute Command.block?(cmd)
      refute Command.noreply?(cmd)
      refute Command.unsub?(cmd)
      refute Command.mt_get?(cmd)
      refute Command.scr_ro?(cmd)
      refute Command.opt_in?(cmd)
      refute Command.static_ttl?(cmd)
      refute Command.pipe?(cmd)
      assert Command.write?(cmd)
    end

    test "opt_in and static_ttl read independently of the readonly chain" do
      opt = %Command{parts: ["GET", "k"], flags: Command.flag(:opt_in), slot: nil}
      assert Command.opt_in?(opt)

      ttl = %Command{parts: ["GET", "k"], flags: Command.flag(:static_ttl), slot: nil}
      assert Command.static_ttl?(ttl)
    end
  end

  describe "raw/1 + raw/2 — the escape hatch (INV6)" do
    test "raw/1 takes parts verbatim, defaults to write/unknown, slots the 2nd token when binary" do
      cmd = Command.raw(["GET", "user:1"])
      assert cmd.parts == ["GET", "user:1"]
      assert Command.write?(cmd)
      refute Command.readonly?(cmd)
      assert Command.slot(cmd) == Command.slot_of("user:1")
    end

    test "raw/1 of a keyless admin verb has nil slot" do
      cmd = Command.raw(["CLIENT"])
      assert cmd.parts == ["CLIENT"]
      assert Command.slot(cmd) == nil
      assert Command.write?(cmd)
    end

    test "raw/2 identifies the slot key explicitly" do
      cmd = Command.raw(["GEORADIUS", "geo", "x"], "geo")
      assert Command.slot(cmd) == Command.slot_of("geo")
    end

    test "a raw GET and a curated GET are parts-equivalent (wire-equivalent)" do
      raw = Command.raw(["GET", "k"])
      curated = Cmd.get("k") |> Cmd.build()
      assert raw.parts == curated.parts
    end
  end
end
