defmodule EchoWireLiveTest do
  @moduledoc """
  The EchoWire extension row's wire column (the agent brief, Stage-1c):
  one happy-path command and one pipeline THROUGH the facade against
  6390 — the delegation proven live.

  PLACEMENT: lives in `apps/echo_mq/test/` beside the connector wire
  suite — the connector's fence reads `EchoMQ.Keyspace.version_key/0` at
  runtime, so no echo_wire-local test can connect (the dependency-free
  wire app does not carry echo_mq in its closure; echo_mq carries both).
  """
  use ExUnit.Case, async: false

  @moduletag :valkey

  test "command/3 and pipeline/3 reach the wire through the facade" do
    {:ok, conn} = EchoWire.start_link(port: 6390)

    key = "emq:{emq0.facade#{System.unique_integer([:positive])}}:probe"

    # the conn dies with the test process — the DEL rides a disposable one
    on_exit(fn ->
      {:ok, sweeper} = EchoWire.start_link(port: 6390)
      {:ok, _} = EchoWire.command(sweeper, ["DEL", key])
      GenServer.stop(sweeper)
    end)

    assert {:ok, "PONG"} = EchoWire.command(conn, ["PING"])
    assert {:ok, ["OK", "front-door"]} = EchoWire.pipeline(conn, [["SET", key, "front-door"], ["GET", key]])
    assert EchoWire.stats(conn).status == :connected
  end
end
