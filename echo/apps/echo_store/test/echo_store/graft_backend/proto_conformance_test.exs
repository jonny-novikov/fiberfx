defmodule EchoStore.GraftBackend.ProtoConformanceTest do
  @moduledoc """
  eg.4 — the Elixir side of the cross-runtime conformance suite (criteria 5 + 6).

  The canonical vectors below mirror `crates/echo_graft_proto/tests/conformance.rs` EXACTLY. Both
  runtimes encode the same messages and must produce the same bytes; the shared fixture file
  (`test/fixtures/graft_backend/wire.fixtures`, a byte-identical mirror of the proto crate's) is
  authoritative for both. A mismatch here means the BEAM and Rust wires have skewed — the precise
  HIGH-risk failure eg.4 exists to prevent.
  """
  use ExUnit.Case, async: true

  alias EchoMQ.RESP
  alias EchoStore.GraftBackend.Proto

  @mirror Path.expand("../../fixtures/graft_backend/wire.fixtures", __DIR__)
  @canonical Path.expand(
               "../../../../echo_graft/crates/echo_graft_proto/tests/fixtures/wire.fixtures",
               __DIR__
             )

  # the canonical test vectors — mirrored EXACTLY from the Rust conformance.rs
  @vid "3QJmnh7Yx2Kp9Wd5Lr8Tz4B"
  @branded "VOL0O5fmcxbds8"
  @log "74ggc11XPe-3tpZminfUtzHG"
  @page <<0xDE, 0xAD, 0xBE, 0xEF>>
  # the eg.3 FeedEvent bilrost fixture (51 bytes), carried opaque by the eg.4 wire
  @feed_blob <<0x05, 0x0E, 0x56, 0x4F, 0x4C, 0x30, 0x4F, 0x35, 0x66, 0x6D, 0x63, 0x78, 0x62, 0x64,
               0x73, 0x38, 0x05, 0x18, 0x37, 0x34, 0x67, 0x67, 0x63, 0x31, 0x31, 0x58, 0x50, 0x65,
               0x2D, 0x33, 0x74, 0x70, 0x5A, 0x6D, 0x69, 0x6E, 0x66, 0x55, 0x74, 0x7A, 0x48, 0x47,
               0x04, 0x07, 0x04, 0x80, 0xCF, 0x94, 0xFE, 0xBB, 0x30>>

  defp canonical do
    [
      {"hello", {:hello, 1, 1, "echo_store"}},
      {"welcome", {:welcome, 1}},
      {"incompatible", {:incompatible, 2, 3, "no overlapping protocol version"}},
      {"open_volume", {:open_volume, 7, @branded, nil, @log}},
      {"resolve_branded", {:resolve_branded, 8, @branded}},
      {"commit", {:commit, 9, @vid, 3, [{1, @page}]}},
      {"push", {:push, 10, @vid}},
      {"pull", {:pull, 11, @vid}},
      {"read", {:read, 12, @vid, 1}},
      {"snapshot", {:snapshot, 13, @vid}},
      {"get_commit", {:get_commit, 14, @log, 42}},
      {"ack", {:ack, 9, 4}},
      {"pages", {:pages, 12, @page}},
      {"snapshot_resp", {:snapshot_resp, 13, 4, 2}},
      {"err", {:err, 9, :conflict, "concurrent write to Volume"}},
      {"feed_event", {:feed, @feed_blob}}
    ]
  end

  defp load_fixtures(path) do
    path
    |> File.read!()
    |> String.split("\n", trim: true)
    |> Enum.reject(&String.starts_with?(&1, "#"))
    |> Map.new(fn line ->
      [name, hex] = String.split(line, "\t")
      {name, Base.decode16!(hex, case: :lower)}
    end)
  end

  test "the echo_store mirror is byte-identical to the canonical proto fixtures" do
    assert File.read!(@mirror) == File.read!(@canonical),
           "wire.fixtures drift: regenerate (REGEN_FIXTURES=1) in echo_graft_proto and re-copy the mirror"
  end

  test "every message encodes to its frozen bytes; the codec round-trips them (criteria 5+6)" do
    fixtures = load_fixtures(@mirror)
    names = canonical() |> Enum.map(&elem(&1, 0)) |> MapSet.new()
    assert MapSet.new(Map.keys(fixtures)) == names, "fixture set and canonical message set diverge"

    for {name, msg} <- canonical() do
      expected = Map.fetch!(fixtures, name)

      # #6 — the Elixir EchoMQ.RESP codec produces the IDENTICAL bytes the Rust side froze
      assert IO.iodata_to_binary(Proto.encode(msg)) == expected,
             "encode mismatch for #{name}: BEAM and Rust wires have skewed"

      # the codec round-trips the frozen bytes (parse → re-encode reproduces them)
      assert {:ok, parts, ""} = RESP.parse(expected)
      assert IO.iodata_to_binary(RESP.encode(parts)) == expected, "round-trip mismatch for #{name}"
    end
  end
end
