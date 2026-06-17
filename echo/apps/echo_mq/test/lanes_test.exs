defmodule EchoMQ.LanesTest do
  @moduledoc """
  The wire column of the Lanes row (echo2-migration.md §5): grouped
  admission, strict ring rotation, pause/resume, the `limit/4` ceiling
  parking and reopening on complete, and `depth/3` — on per-test
  sub-queues with the baseline purge idiom.
  """
  use ExUnit.Case, async: false

  @moduletag :valkey

  alias EchoData.BrandedId
  alias EchoMQ.{Connector, Jobs, Lanes}

  setup_all do
    :ok = EchoData.Snowflake.start(4)
    :ok
  end

  setup do
    {:ok, conn} = Connector.start_link(port: 6390)
    q = "emq0.lanes#{System.unique_integer([:positive])}"

    # the conn dies with the test process (the OTP parent-exit protocol),
    # so the purge rides its own disposable connection
    on_exit(fn -> purge(q) end)

    %{conn: conn, q: q}
  end

  defp purge(q) do
    {:ok, conn} = Connector.start_link(port: 6390)
    {:ok, keys} = Connector.command(conn, ["KEYS", "emq:{" <> q <> "}:*"])
    if keys != [], do: {:ok, _} = Connector.command(conn, ["DEL" | keys])
    GenServer.stop(conn)
  end

  test "grouped enqueue admits, dedups, and claim returns the group", %{conn: conn, q: q} do
    group = BrandedId.generate!("PRT")
    id = BrandedId.generate!("JOB")

    assert {:ok, :enqueued} = Lanes.enqueue(conn, q, group, id, "cargo")
    assert {:ok, :duplicate} = Lanes.enqueue(conn, q, group, id, "again")
    assert {:error, :kind} = Lanes.enqueue(conn, q, group, BrandedId.generate!("ORD"), "x")

    assert {:ok, {^id, "cargo", 1, ^group}} = Lanes.claim(conn, q, 60_000)
    assert :ok = Jobs.complete(conn, q, id, 1)
  end

  test "two lanes claim in strict rotation — the ring is the rota", %{conn: conn, q: q} do
    [a, b] = for _ <- 1..2, do: BrandedId.generate!("PRT")

    for grp <- [a, b], _ <- 1..2 do
      {:ok, :enqueued} = Lanes.enqueue(conn, q, grp, BrandedId.generate!("JOB"), "r")
    end

    served =
      for _ <- 1..4 do
        {:ok, {_id, _p, 1, grp}} = Lanes.claim(conn, q, 60_000)
        grp
      end

    assert served == [a, b, a, b]
  end

  test "pause/3 parks the lane with its backlog intact; resume/3 returns it", %{conn: conn, q: q} do
    [a, b] = for _ <- 1..2, do: BrandedId.generate!("PRT")

    for grp <- [a, b], _ <- 1..2 do
      {:ok, :enqueued} = Lanes.enqueue(conn, q, grp, BrandedId.generate!("JOB"), "p")
    end

    assert :ok = Lanes.pause(conn, q, a)

    assert {:ok, {_, _, 1, ^b}} = Lanes.claim(conn, q, 60_000)
    assert {:ok, {_, _, 1, ^b}} = Lanes.claim(conn, q, 60_000)
    assert :empty = Lanes.claim(conn, q, 60_000)

    assert {:ok, 2} = Lanes.depth(conn, q, a)

    assert :ok = Lanes.resume(conn, q, a)
    assert {:ok, {_, _, 1, ^a}} = Lanes.claim(conn, q, 60_000)
  end

  test "limit/4 parks the lane at its ceiling and complete reopens it", %{conn: conn, q: q} do
    a = BrandedId.generate!("PRT")
    assert :ok = Lanes.limit(conn, q, a, 1)

    j1 = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Lanes.enqueue(conn, q, a, j1, "l")
    {:ok, :enqueued} = Lanes.enqueue(conn, q, a, BrandedId.generate!("JOB"), "l")

    assert {:ok, {^j1, _, 1, ^a}} = Lanes.claim(conn, q, 60_000)
    assert :empty = Lanes.claim(conn, q, 60_000)

    assert :ok = Jobs.complete(conn, q, j1, 1)
    assert {:ok, {_, _, 1, ^a}} = Lanes.claim(conn, q, 60_000)
  end

  test "depth/3 counts the lane's parked backlog", %{conn: conn, q: q} do
    group = BrandedId.generate!("PRT")

    assert {:ok, 0} = Lanes.depth(conn, q, group)

    for _ <- 1..3 do
      {:ok, :enqueued} = Lanes.enqueue(conn, q, group, BrandedId.generate!("JOB"), "d")
    end

    assert {:ok, 3} = Lanes.depth(conn, q, group)
  end
end
