defmodule EchoMQ.Stories.WirePipeCounterStoryTest do
  @moduledoc """
  Acceptance criteria for **Wire — Pipe — counter** (`EchoWire.Pipe`,
  EWR.1.1). Three `INCR`s in one pipe return the running total `[1, 2, 3]` —
  atomic per-command counting (redis-patterns R2.01) assembled with `%Pipe{}`.

  A `:valkey` ExUnit test driving `EchoWire.Pipe` end-to-end against Valkey on
  6390, AND the source of the generated story (EWR.1.1-INV7).
  """
  use EchoMQ.Story, feature: "Wire — Pipe — counter", async: false

  @moduletag :valkey

  alias EchoMQ.Connector
  alias EchoWire.Pipe

  setup do
    {:ok, conn} = Connector.start_link(port: 6390)
    c = "ewr.story.counter#{System.unique_integer([:positive])}"
    on_exit(fn -> purge(c) end)
    %{conn: conn, c: c}
  end

  scenario "three increments in one pipe read the running total, then INCRBY steps it", %{conn: conn, c: c} do
    given_ "an unset counter" do
      assert {:ok, [nil]} = conn |> Pipe.new() |> Pipe.get(c) |> Pipe.exec()
    end

    when_ "the counter is incremented three times in one pipe" do
      run = conn |> Pipe.new() |> Pipe.incr(c) |> Pipe.incr(c) |> Pipe.incr(c) |> Pipe.exec()
    end

    and_ "then stepped by ten and read back" do
      step = conn |> Pipe.new() |> Pipe.incrby(c, 10) |> Pipe.get(c) |> Pipe.exec()
    end

    then_ "the three increments return 1, 2, 3 in order and INCRBY lands on 13" do
      assert {:ok, [1, 2, 3]} = run
      assert {:ok, [13, "13"]} = step
    end
  end

  defp purge(c) do
    {:ok, conn} = Connector.start_link(port: 6390)
    {:ok, _} = Connector.command(conn, ["DEL", c])
    GenServer.stop(conn)
  end
end
