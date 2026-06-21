defmodule EchoStore.GraftBackend.FeedBlobTest do
  @moduledoc """
  eg.4 — the client's minimal read into the OPAQUE eg.3 `FeedEvent` bilrost blob.

  The blob is opaque by contract; the client peeks only at field 1 (branded id) and field 3
  (LSN) to keep its replay cursor. These pin that peek against the SAME byte-frozen eg.3
  fixture the Rust `echo_graft::feed` and the cross-runtime conformance use.
  """
  use ExUnit.Case, async: true

  alias EchoStore.GraftBackend.FeedBlob

  # The eg.3 FeedEvent fixture (51 bytes): branded id "VOL0O5fmcxbds8" (field 1),
  # log "74ggc11XPe-3tpZminfUtzHG" (field 2), lsn 7 (field 3), ts 1_700_000_000_000 (field 4).
  @feed_blob <<0x05, 0x0E, 0x56, 0x4F, 0x4C, 0x30, 0x4F, 0x35, 0x66, 0x6D, 0x63, 0x78, 0x62, 0x64,
               0x73, 0x38, 0x05, 0x18, 0x37, 0x34, 0x67, 0x67, 0x63, 0x31, 0x31, 0x58, 0x50, 0x65,
               0x2D, 0x33, 0x74, 0x70, 0x5A, 0x6D, 0x69, 0x6E, 0x66, 0x55, 0x74, 0x7A, 0x48, 0x47,
               0x04, 0x07, 0x04, 0x80, 0xCF, 0x94, 0xFE, 0xBB, 0x30>>

  test "reads the branded id (field 1) and LSN (field 3) from the frozen fixture" do
    assert {:ok, "VOL0O5fmcxbds8", 7} = FeedBlob.branded_and_lsn(@feed_blob)
  end

  test "reads a larger multi-byte LSN varint" do
    # field 1 = "AAABBBCCCDDD11" (14 bytes, key 0x05 len 0x0e), field 3 = lsn (key 0x04, varint)
    # lsn 1_000_000 = 0xC0, 0x84, 0x3D in unsigned LEB128
    branded = "AAABBBCCCDDD11"
    blob =
      <<0x05, 0x0E>> <>
        branded <>
        <<0x05, 0x01, ?L>> <>
        <<0x04>> <> leb(1_000_000)

    assert {:ok, ^branded, 1_000_000} = FeedBlob.branded_and_lsn(blob)
  end

  test "an empty or truncated blob is :error, not a crash" do
    assert :error = FeedBlob.branded_and_lsn(<<>>)
    # a length-delimited field claiming 14 bytes but truncated
    assert :error = FeedBlob.branded_and_lsn(<<0x05, 0x0E, 0x56, 0x4F>>)
  end

  test "a blob missing field 3 (no LSN) is :error" do
    # only field 1 present
    blob = <<0x05, 0x03, ?A, ?B, ?C>>
    assert :error = FeedBlob.branded_and_lsn(blob)
  end

  # encode an unsigned LEB128 varint (test helper)
  defp leb(n) when n < 0x80, do: <<n>>
  defp leb(n), do: <<Bitwise.bor(Bitwise.band(n, 0x7F), 0x80)>> <> leb(Bitwise.bsr(n, 7))
end
