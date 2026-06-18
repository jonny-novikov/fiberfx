defmodule EchoMQ.Stories.WirePipeDistributedLockStoryTest do
  @moduledoc """
  Acceptance criteria for **Wire — Pipe — distributed-lock** (`EchoWire.Pipe`,
  EWR.1.1). `SET key token NX` mints a lock once and is refused while held; a
  `DEL` releases it (redis-patterns R2.02) — all assembled with `%Pipe{}`.

  A `:valkey` ExUnit test driving `EchoWire.Pipe` end-to-end against Valkey on
  6390, AND the source of the generated story (EWR.1.1-INV7).
  """
  use EchoMQ.Story, feature: "Wire — Pipe — distributed-lock", async: false

  @moduletag :valkey

  alias EchoMQ.Connector
  alias EchoWire.Pipe

  setup do
    {:ok, conn} = Connector.start_link(port: 6390)
    lock = "ewr.story.lock#{System.unique_integer([:positive])}"
    on_exit(fn -> purge(lock) end)
    %{conn: conn, lock: lock}
  end

  scenario "the first SET NX takes the lock, the second is refused, and releasing reopens it",
           %{conn: conn, lock: lock} do
    given_ "a free lock key" do
      assert {:ok, [0]} = conn |> Pipe.new() |> Pipe.exists(lock) |> Pipe.exec()
    end

    when_ "two contenders each attempt SET NX with a 30s TTL in one pipe, then the holder releases" do
      contention =
        conn
        |> Pipe.new()
        |> Pipe.set(lock, "owner-a", nx: true, ex: 30)
        |> Pipe.set(lock, "owner-b", nx: true, ex: 30)
        |> Pipe.exec()

      release = conn |> Pipe.new() |> Pipe.del(lock) |> Pipe.exec()

      reacquire = conn |> Pipe.new() |> Pipe.set(lock, "owner-b", nx: true, ex: 30) |> Pipe.exec()
    end

    then_ "the first acquires (OK), the second is refused (nil), release deletes one key, and reacquire succeeds" do
      assert {:ok, ["OK", nil]} = contention
      assert {:ok, [1]} = release
      assert {:ok, ["OK"]} = reacquire
    end
  end

  defp purge(lock) do
    {:ok, conn} = Connector.start_link(port: 6390)
    {:ok, _} = Connector.command(conn, ["DEL", lock])
    GenServer.stop(conn)
  end
end
