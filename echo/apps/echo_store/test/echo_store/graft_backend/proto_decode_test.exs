defmodule EchoStore.GraftBackend.ProtoDecodeTest do
  @moduledoc """
  eg.4 — `EchoStore.GraftBackend.Proto.decode/1` inverts `parts/1` for every message.

  The client parses a reply frame with `EchoMQ.RESP.parse/1` (yielding the flat bulk-string
  parts) and reconstructs the message tuple with `Proto.decode/1`. This pins that inverse over
  the SAME canonical vectors the conformance test froze, plus the malformed-input refusals
  (`decode/1` never raises — it returns `{:error, _}`).
  """
  use ExUnit.Case, async: true

  alias EchoMQ.RESP
  alias EchoStore.GraftBackend.Proto

  @vid "3QJmnh7Yx2Kp9Wd5Lr8Tz4B"
  @branded "VOL0O5fmcxbds8"
  @log "74ggc11XPe-3tpZminfUtzHG"
  @page <<0xDE, 0xAD, 0xBE, 0xEF>>
  @feed_blob <<0x05, 0x0E, 0x56, 0x4F, 0x4C, 0x30, 0x4F, 0x35, 0x66, 0x6D, 0x63, 0x78, 0x62, 0x64,
               0x73, 0x38, 0x05, 0x18, 0x37, 0x34, 0x67, 0x67, 0x63, 0x31, 0x31, 0x58, 0x50, 0x65,
               0x2D, 0x33, 0x74, 0x70, 0x5A, 0x6D, 0x69, 0x6E, 0x66, 0x55, 0x74, 0x7A, 0x48, 0x47,
               0x04, 0x07, 0x04, 0x80, 0xCF, 0x94, 0xFE, 0xBB, 0x30>>

  defp canonical do
    # v2 (D-5): hello/welcome carry version 2; commit carries a fixed-position mode (both pinned).
    [
      {:hello, 2, 2, "echo_store"},
      {:welcome, 2},
      {:incompatible, 2, 3, "no overlapping protocol version"},
      {:open_volume, 7, @branded, nil, @log},
      {:resolve_branded, 8, @branded},
      {:commit, 9, @vid, 3, :sync, [{1, @page}]},
      {:commit, 9, @vid, 3, :async, [{1, @page}]},
      {:push, 10, @vid},
      {:pull, 11, @vid},
      {:read, 12, @vid, 1},
      {:snapshot, 13, @vid},
      {:get_commit, 14, @log, 42},
      {:ack, 9, 4},
      {:pages, 12, @page},
      {:snapshot_resp, 13, 4, 2},
      {:err, 9, :conflict, "concurrent write to Volume"},
      {:feed, @feed_blob}
    ]
  end

  test "encode → RESP.parse → decode reproduces every message tuple" do
    for msg <- canonical() do
      bytes = IO.iodata_to_binary(Proto.encode(msg))
      assert {:ok, parts, ""} = RESP.parse(bytes)
      assert {:ok, ^msg} = Proto.decode(parts), "decode drift for #{inspect(msg)}"
    end
  end

  test "a multi-page commit round-trips (with mode)" do
    msg = {:commit, 5, @vid, 0, :async, [{1, <<1, 2>>}, {9, <<3>>}, {2, <<>>}]}
    bytes = IO.iodata_to_binary(Proto.encode(msg))
    {:ok, parts, ""} = RESP.parse(bytes)
    assert {:ok, ^msg} = Proto.decode(parts)
  end

  test "decode refuses malformed input without raising" do
    assert {:error, :empty} = Proto.decode([])
    assert {:error, {:unknown_tag, "ZZZ"}} = Proto.decode(["ZZZ"])
    # ACK with a non-numeric corr
    assert {:error, {:bad_field, _}} = Proto.decode(["ACK", "x", "1"])
    # ERR with an out-of-taxonomy kind
    assert {:error, {:bad_field, "err_kind"}} = Proto.decode(["ERR", "1", "teapot", "d"])
    # wrong arity
    assert {:error, {:bad_arity, "PUSH"}} = Proto.decode(["PUSH", "1"])
    # COMMIT with a page-count that disagrees with the tail (v2 shape: corr,vid,base,mode,npages,…)
    assert {:error, {:bad_field, "pages_count"}} =
             Proto.decode(["COMMIT", "1", @vid, "0", "sync", "2", "1", "x"])
    # COMMIT with an out-of-set mode token
    assert {:error, {:bad_field, "commit_mode"}} =
             Proto.decode(["COMMIT", "1", @vid, "0", "eventually", "0"])
  end
end
