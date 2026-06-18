defmodule EchoMQ.Stories.WirePipeHashObjectStoryTest do
  @moduledoc """
  Acceptance criteria for **Wire — Pipe — hash object** (`EchoWire.Pipe`,
  EWR.1.1). A hash models an object: `HSET` writes fields, `HINCRBY` steps a
  counter field, `HGETALL` round-trips the whole record (the hash-object
  pattern) — assembled with `%Pipe{}`, including the multi-field `hset_all/3`.

  A `:valkey` ExUnit test driving `EchoWire.Pipe` end-to-end against Valkey on
  6390, AND the source of the generated story (EWR.1.1-INV7).
  """
  use EchoMQ.Story, feature: "Wire — Pipe — hash object", async: false

  @moduletag :valkey

  alias EchoMQ.Connector
  alias EchoWire.Pipe

  setup do
    {:ok, conn} = Connector.start_link(port: 6390)
    h = "ewr.story.hash#{System.unique_integer([:positive])}"
    on_exit(fn -> purge(h) end)
    %{conn: conn, h: h}
  end

  scenario "an object's fields are written, a counter field steps, and the record round-trips", %{conn: conn, h: h} do
    given_ "an empty hash" do
      assert {:ok, [0]} = conn |> Pipe.new() |> Pipe.hlen(h) |> Pipe.exec()
    end

    when_ "name + visits are written multi-field, visits is incremented, and one field is read" do
      run =
        conn
        |> Pipe.new()
        |> Pipe.hset_all(h, [{"name", "alice"}, {"visits", "0"}])
        |> Pipe.hincrby(h, "visits", 3)
        |> Pipe.hget(h, "name")
        |> Pipe.exec()
    end

    and_ "the whole record is read back with HGETALL" do
      record = conn |> Pipe.new() |> Pipe.hgetall(h) |> Pipe.exec()
    end

    then_ "two fields are created, visits steps to 3, the name reads back, and HGETALL is the full map" do
      assert {:ok, [2, 3, "alice"]} = run
      assert {:ok, [%{"name" => "alice", "visits" => "3"}]} = record
    end
  end

  defp purge(h) do
    {:ok, conn} = Connector.start_link(port: 6390)
    {:ok, _} = Connector.command(conn, ["DEL", h])
    GenServer.stop(conn)
  end
end
