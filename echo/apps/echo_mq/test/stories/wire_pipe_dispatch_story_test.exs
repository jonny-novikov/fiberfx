defmodule EchoMQ.Stories.WirePipeDispatchStoryTest do
  @moduledoc """
  Acceptance criteria for **Wire — Pipe — conn-or-pool dispatch** (`EchoWire.Pipe`,
  EWR.1.1, INV3 + INV5). The conn-or-pool opacity is first-class this rung: the
  SAME built `%Pipe{}` flushes identically against an `EchoMQ.Connector` and an
  `EchoMQ.Pool` (only the carried `conn`/`via` differ — the reference is never
  inspected). The transaction flush (`exec_txn`) is proven against a single
  `Connector` (a pool pins no connection across MULTI/EXEC — out of contract).

  A `:valkey` ExUnit test driving `EchoWire.Pipe` end-to-end against Valkey on
  6390, AND the source of the generated story (EWR.1.1-INV7).
  """
  use EchoMQ.Story, feature: "Wire — Pipe — conn-or-pool dispatch", async: false

  @moduletag :valkey

  alias EchoMQ.{Connector, Pool}
  alias EchoWire.Pipe

  setup do
    {:ok, conn} = Connector.start_link(port: 6390)

    pool_name = :"ewr_story_pool_#{System.unique_integer([:positive])}"
    {:ok, _pool} = Pool.start_link(name: pool_name, size: 2, port: 6390)

    k = "ewr.story.dispatch#{System.unique_integer([:positive])}"
    on_exit(fn -> purge(k) end)
    %{conn: conn, pool: pool_name, k: k}
  end

  scenario "the same %Pipe{} flushes identically against a Connector and a Pool", %{conn: conn, pool: pool, k: k} do
    given_ "a pipe built once over the connector (set, get, incr a sibling counter)" do
      pipe =
        conn
        |> Pipe.new()
        |> Pipe.set(k, "v", ex: 60)
        |> Pipe.get(k)
    end

    when_ "it is flushed against the connector, then the same built batch is re-targeted to the pool" do
      via_conn = Pipe.exec(pipe)
      # Re-target the identical accumulator to the pool — only conn + via change;
      # the gathered cmds are untouched (opacity: the reference is carried, never detected).
      via_pool = Pipe.exec(%{pipe | conn: pool, via: Pool})
    end

    then_ "both round-trips return the identical reply list" do
      assert {:ok, ["OK", "v"]} = via_conn
      assert via_pool == via_conn
    end
  end

  scenario "exec_txn wraps the batch in MULTI/EXEC against a single Connector", %{conn: conn, k: k} do
    given_ "a counter key" do
      assert {:ok, [nil]} = conn |> Pipe.new() |> Pipe.get(k) |> Pipe.exec()
    end

    when_ "two increments are flushed as one transaction" do
      txn = conn |> Pipe.new() |> Pipe.incr(k) |> Pipe.incr(k) |> Pipe.exec_txn()
    end

    then_ "EXEC returns both step replies in order" do
      assert {:ok, [1, 2]} = txn
    end

    and_ "exec_noreply suppresses replies wire-side and answers :ok" do
      assert :ok = conn |> Pipe.new() |> Pipe.incr(k) |> Pipe.exec_noreply()
      assert {:ok, ["3"]} = conn |> Pipe.new() |> Pipe.get(k) |> Pipe.exec()
    end
  end

  defp purge(k) do
    {:ok, conn} = Connector.start_link(port: 6390)
    {:ok, _} = Connector.command(conn, ["DEL", k])
    GenServer.stop(conn)
  end
end
