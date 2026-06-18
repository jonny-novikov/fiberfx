defmodule EchoMQ.Stories.WirePipeLeaderboardStoryTest do
  @moduledoc """
  Acceptance criteria for **Wire — Pipe — leaderboard** (`EchoWire.Pipe`,
  EWR.1.1). A sorted set ranks members by score: `ZADD` seeds, `ZREVRANGE`
  reads top-first, `ZRANK`/`ZSCORE` query a member (redis-patterns R4.05) —
  assembled with `%Pipe{}`.

  A `:valkey` ExUnit test driving `EchoWire.Pipe` end-to-end against Valkey on
  6390, AND the source of the generated story (EWR.1.1-INV7).
  """
  use EchoMQ.Story, feature: "Wire — Pipe — leaderboard", async: false

  @moduletag :valkey

  alias EchoMQ.Connector
  alias EchoWire.Pipe

  setup do
    {:ok, conn} = Connector.start_link(port: 6390)
    z = "ewr.story.board#{System.unique_integer([:positive])}"
    on_exit(fn -> purge(z) end)
    %{conn: conn, z: z}
  end

  scenario "three scored members rank top-first, and a member's rank and score read back", %{conn: conn, z: z} do
    given_ "an empty board" do
      assert {:ok, [0]} = conn |> Pipe.new() |> Pipe.zcard(z) |> Pipe.exec()
    end

    when_ "three players are added with scores in one pipe" do
      seed =
        conn
        |> Pipe.new()
        |> Pipe.zadd(z, 100, "alice")
        |> Pipe.zadd(z, 250, "bob")
        |> Pipe.zadd(z, 175, "carol")
        |> Pipe.exec()
    end

    and_ "the board is read top-first and bob is queried" do
      board =
        conn
        |> Pipe.new()
        |> Pipe.zrevrange(z, 0, -1)
        |> Pipe.zrevrank(z, "bob")
        |> Pipe.zscore(z, "bob")
        |> Pipe.exec()
    end

    then_ "each add reports one new member, the order is bob, carol, alice, and bob is rank 0 with score 250 (a RESP3 double)" do
      assert {:ok, [1, 1, 1]} = seed
      assert {:ok, [["bob", "carol", "alice"], 0, 250.0]} = board
    end
  end

  defp purge(z) do
    {:ok, conn} = Connector.start_link(port: 6390)
    {:ok, _} = Connector.command(conn, ["DEL", z])
    GenServer.stop(conn)
  end
end
