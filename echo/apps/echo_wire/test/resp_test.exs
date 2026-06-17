defmodule EchoMQ.RESPTest do
  use ExUnit.Case, async: true
  alias EchoMQ.RESP

  test "encodes a command as a RESP array of bulk strings, as iodata" do
    assert IO.iodata_to_binary(RESP.encode(["PING"])) == "*1\r\n$4\r\nPING\r\n"
    assert IO.iodata_to_binary(RESP.encode(["SET", "k", 1])) ==
             "*3\r\n$3\r\nSET\r\n$1\r\nk\r\n$1\r\n1\r\n"
  end

  test "parses simple strings, integers, blobs, arrays, and pushes" do
    assert {:ok, "OK", ""} = RESP.parse("+OK\r\n")
    assert {:ok, 42, ""} = RESP.parse(":42\r\n")
    assert {:ok, "hi", "tail"} = RESP.parse("$2\r\nhi\r\ntail")
    assert {:ok, ["a", 1], ""} = RESP.parse("*2\r\n$1\r\na\r\n:1\r\n")
    assert {:ok, {:push, ["invalidate", ["k"]]}, ""} =
             RESP.parse(">2\r\n$10\r\ninvalidate\r\n*1\r\n$1\r\nk\r\n")
  end

  test "reports incomplete frames and refuses bad leads" do
    assert :incomplete = RESP.parse("$5\r\nhe")
    assert {:error, :bad_resp} = RESP.parse("?nope\r\n")
  end
end
