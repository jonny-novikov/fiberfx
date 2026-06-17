defmodule EchoMQ.PoolTest do
  @moduledoc """
  The wire column of the Pool row (echo2-migration.md §5): `size/1`, and
  round-robin `command/3` distribution asserted via the per-member
  `stats/1` commands counters.
  """
  use ExUnit.Case, async: false

  @moduletag :valkey

  alias EchoMQ.Pool

  setup do
    name = :"emq0_pool_#{System.unique_integer([:positive])}"
    {:ok, sup} = Pool.start_link(name: name, size: 2, port: 6390)

    on_exit(fn ->
      try do
        Supervisor.stop(sup)
      catch
        :exit, _ -> :ok
      end
    end)

    %{pool: name}
  end

  test "size/1 answers the declared size", %{pool: pool} do
    assert Pool.size(pool) == 2
  end

  test "command/3 distributes round-robin across the members", %{pool: pool} do
    for _ <- 1..4 do
      assert {:ok, "PONG"} = Pool.command(pool, ["PING"])
    end

    stats = Pool.stats(pool)
    members = Map.keys(stats) |> Enum.sort()

    assert members == [:"#{pool}_1", :"#{pool}_2"]
    assert Enum.map(members, &stats[&1].commands) == [2, 2]
  end

  test "pipeline/3 rides the same rotation", %{pool: pool} do
    assert {:ok, ["PONG", "PONG"]} = Pool.pipeline(pool, [["PING"], ["PING"]])

    total =
      Pool.stats(pool)
      |> Map.values()
      |> Enum.map(& &1.pipelines)
      |> Enum.sum()

    assert total == 1
  end
end
