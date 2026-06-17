defmodule EchoMQ.RESPExtendTest do
  @moduledoc """
  The rest of the RESP row's pure column (echo2-migration.md §5),
  extending the migrated floor `resp_test.exs` (encode array, simple,
  integer, blob, array, push, one incomplete, bad lead), which stays
  byte-unmodified: the error reply as a value, every RESP3 type — map,
  set, double (`inf`/`-inf`/`nan` and finite), boolean, null, big
  number, verbatim — the `$-1`/`*-1` nils, the encode part kinds, and
  `:incomplete` continuations across split frames.
  """
  use ExUnit.Case, async: true

  alias EchoMQ.RESP

  test "a server error reply parses as a value, not a failure" do
    assert {:ok, {:error_reply, "ERR boom"}, ""} = RESP.parse("-ERR boom\r\n")
    assert {:ok, {:error_reply, "EMQKIND job id must be JOB-namespaced"}, "rest"} =
             RESP.parse("-EMQKIND job id must be JOB-namespaced\r\nrest")
  end

  test "a RESP3 map parses to a map" do
    assert {:ok, %{"a" => 1, "b" => 2}, "tail"} =
             RESP.parse("%2\r\n$1\r\na\r\n:1\r\n$1\r\nb\r\n:2\r\ntail")
  end

  test "a RESP3 set parses to a MapSet" do
    assert {:ok, set, ""} = RESP.parse("~3\r\n:1\r\n:2\r\n$1\r\nx\r\n")
    assert set == MapSet.new([1, 2, "x"])
  end

  test "doubles parse to floats with the three special forms" do
    assert {:ok, 3.25, ""} = RESP.parse(",3.25\r\n")
    assert {:ok, +0.0, ""} = RESP.parse(",0\r\n")
    assert {:ok, :infinity, ""} = RESP.parse(",inf\r\n")
    assert {:ok, :neg_infinity, ""} = RESP.parse(",-inf\r\n")
    assert {:ok, :nan, ""} = RESP.parse(",nan\r\n")
  end

  test "booleans and the RESP3 null parse natively" do
    assert {:ok, true, ""} = RESP.parse("#t\r\n")
    assert {:ok, false, "x"} = RESP.parse("#f\r\nx")
    assert {:ok, nil, "y"} = RESP.parse("_\r\ny")
  end

  test "a big number parses to an integer" do
    big = "3492890328409238509324850943850943825024385"
    assert {:ok, n, ""} = RESP.parse("(" <> big <> "\r\n")
    assert n == String.to_integer(big)
  end

  test "a verbatim string parses with its format prefix stripped" do
    assert {:ok, "Some string", ""} = RESP.parse("=15\r\ntxt:Some string\r\n")
    # a verbatim too short to carry the fmt prefix passes through whole
    assert {:ok, "ab", ""} = RESP.parse("=2\r\nab\r\n")
  end

  test "the RESP2 null blob and null array parse to nil" do
    assert {:ok, nil, ""} = RESP.parse("$-1\r\n")
    assert {:ok, nil, "tail"} = RESP.parse("*-1\r\ntail")
  end

  test "encode accepts binary, integer, atom, and iodata parts" do
    assert IO.iodata_to_binary(RESP.encode(["GET", :k])) == "*2\r\n$3\r\nGET\r\n$1\r\nk\r\n"

    assert IO.iodata_to_binary(RESP.encode([["S", ["E", "T"]], "k", 10])) ==
             "*3\r\n$3\r\nSET\r\n$1\r\nk\r\n$2\r\n10\r\n"
  end

  test ":incomplete continues split frames of every shape" do
    assert :incomplete = RESP.parse("")
    assert :incomplete = RESP.parse("+OK")
    assert :incomplete = RESP.parse(",3.2")
    assert :incomplete = RESP.parse("#")
    assert :incomplete = RESP.parse("_")
    assert :incomplete = RESP.parse("*2\r\n:1\r\n")
    assert :incomplete = RESP.parse("%1\r\n$1\r\na")
    assert :incomplete = RESP.parse("~2\r\n:1")
    assert :incomplete = RESP.parse("=15\r\ntxt:Some str")
  end
end
