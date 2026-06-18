defmodule EchoMQ.Stories.WirePipeSetMembershipStoryTest do
  @moduledoc """
  Acceptance criteria for **Wire — Pipe — set-membership** (`EchoWire.Pipe`,
  EWR.1.1). `SADD` builds a set and `SISMEMBER`/`SCARD` answer membership and
  size (the set-membership pattern) — assembled with `%Pipe{}`.

  A `:valkey` ExUnit test driving `EchoWire.Pipe` end-to-end against Valkey on
  6390, AND the source of the generated story (EWR.1.1-INV7).
  """
  use EchoMQ.Story, feature: "Wire — Pipe — set-membership", async: false

  @moduletag :valkey

  alias EchoMQ.Connector
  alias EchoWire.Pipe

  setup do
    {:ok, conn} = Connector.start_link(port: 6390)
    s = "ewr.story.set#{System.unique_integer([:positive])}"
    on_exit(fn -> purge(s) end)
    %{conn: conn, s: s}
  end

  scenario "members added to a set report present/absent and a correct cardinality", %{conn: conn, s: s} do
    given_ "an empty set" do
      assert {:ok, [0]} = conn |> Pipe.new() |> Pipe.scard(s) |> Pipe.exec()
    end

    when_ "three tags are added in one pipe, then membership is queried" do
      run =
        conn
        |> Pipe.new()
        |> Pipe.sadd(s, ["red", "green", "blue"])
        |> Pipe.sismember(s, "green")
        |> Pipe.sismember(s, "violet")
        |> Pipe.scard(s)
        |> Pipe.exec()
    end

    then_ "three members are added, green is present (1), violet is absent (0), and the cardinality is 3" do
      assert {:ok, [3, 1, 0, 3]} = run
    end
  end

  defp purge(s) do
    {:ok, conn} = Connector.start_link(port: 6390)
    {:ok, _} = Connector.command(conn, ["DEL", s])
    GenServer.stop(conn)
  end
end
