defmodule EchoMQ.Stories.WirePipeReliableQueueStoryTest do
  @moduledoc """
  Acceptance criteria for **Wire — Pipe — reliable-queue** (`EchoWire.Pipe`,
  EWR.1.1). `LPUSH` enqueues at the head and `RPOP` serves the tail, so the
  queue is FIFO (redis-patterns R3.01) — assembled with `%Pipe{}`.

  A `:valkey` ExUnit test driving `EchoWire.Pipe` end-to-end against Valkey on
  6390, AND the source of the generated story (EWR.1.1-INV7).
  """
  use EchoMQ.Story, feature: "Wire — Pipe — reliable-queue", async: false

  @moduletag :valkey

  alias EchoMQ.Connector
  alias EchoWire.Pipe

  setup do
    {:ok, conn} = Connector.start_link(port: 6390)
    q = "ewr.story.queue#{System.unique_integer([:positive])}"
    on_exit(fn -> purge(q) end)
    %{conn: conn, q: q}
  end

  scenario "two items pushed at the head are served FIFO from the tail", %{conn: conn, q: q} do
    given_ "an empty list" do
      assert {:ok, [0]} = conn |> Pipe.new() |> Pipe.llen(q) |> Pipe.exec()
    end

    when_ "two jobs are LPUSHed in one pipe, then the depth is read" do
      enqueue =
        conn
        |> Pipe.new()
        |> Pipe.lpush(q, "job-1")
        |> Pipe.lpush(q, "job-2")
        |> Pipe.llen(q)
        |> Pipe.exec()
    end

    and_ "the queue is drained from the tail with RPOP" do
      serve = conn |> Pipe.new() |> Pipe.rpop(q) |> Pipe.rpop(q) |> Pipe.exec()
    end

    then_ "the depth reads 2 after enqueue and the tail serves job-1 then job-2 (FIFO)" do
      assert {:ok, [1, 2, 2]} = enqueue
      assert {:ok, ["job-1", "job-2"]} = serve
    end
  end

  defp purge(q) do
    {:ok, conn} = Connector.start_link(port: 6390)
    {:ok, _} = Connector.command(conn, ["DEL", q])
    GenServer.stop(conn)
  end
end
