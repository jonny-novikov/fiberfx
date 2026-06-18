defmodule EchoMQ.LanesDrainTest do
  @moduledoc """
  The lane-scoped destructive drain (emq.4.1-D5): `Lanes.drain/3` empties one
  lane's `g:<group>:pending` backlog -- deleting each member's row and its §6
  logs subkey, the lane set, and the group's ring entry -- and returns the count.
  It is the `EchoMQ.Admin.drain/3` wipe scoped to one lane. The proof set is the
  BLAST RADIUS of a destructive op: the target lane's pending rows + logs + set +
  ring entry go; an in-flight member of the same lane (claimed -> active, counted
  in `gactive`), every sibling lane, the lane's own `paused`/`glimit` config, and
  the repeat registry all survive. Plus the edges: an empty/absent lane drains to
  0, and an ill-formed group raises before the wire. On per-test sub-queues with
  the baseline purge idiom.
  """
  use ExUnit.Case, async: false

  @moduletag :valkey

  alias EchoData.BrandedId
  alias EchoMQ.{Connector, Jobs, Keyspace, Lanes, Metrics, Repeat}

  setup_all do
    :ok = EchoData.Snowflake.start(4)
    :ok
  end

  setup do
    {:ok, conn} = Connector.start_link(port: 6390)
    q = "emq0.drain#{System.unique_integer([:positive])}"

    on_exit(fn -> purge(q) end)

    %{conn: conn, q: q}
  end

  defp purge(q) do
    {:ok, conn} = Connector.start_link(port: 6390)
    {:ok, keys} = Connector.command(conn, ["KEYS", "emq:{" <> q <> "}:*"])
    if keys != [], do: {:ok, _} = Connector.command(conn, ["DEL" | keys])
    GenServer.stop(conn)
  end

  defp exists(conn, key), do: Connector.command(conn, ["EXISTS", key])

  test "drains one lane: deletes its pending rows, their logs, the lane set, the ring entry; returns the count",
       %{conn: conn, q: q} do
    g = BrandedId.generate!("PRT")
    [j1, j2] = for _ <- 1..2, do: BrandedId.generate!("JOB")
    {:ok, :enqueued} = Lanes.enqueue(conn, q, g, j1, "one")
    {:ok, :enqueued} = Lanes.enqueue(conn, q, g, j2, "two")
    # j1 carries a log line, to prove the §6 logs subkey is deleted
    {:ok, 1} = Jobs.add_log(conn, q, j1, "trace")

    assert {:ok, 2} = Lanes.drain(conn, q, g)

    # the rows + their logs + the lane set are gone
    assert {:ok, 0} = exists(conn, Keyspace.job_key(q, j1))
    assert {:ok, 0} = exists(conn, Keyspace.job_key(q, j1) <> ":logs")
    assert {:ok, 0} = exists(conn, Keyspace.job_key(q, j2))
    assert {:ok, 0} = exists(conn, Keyspace.queue_key(q, "g:" <> g <> ":pending"))
    # the ring no longer carries the group
    assert {:ok, nil} = Connector.command(conn, ["LPOS", Keyspace.queue_key(q, "ring"), g])
  end

  test "an in-flight member of the same lane is untouched: still active, gactive intact",
       %{conn: conn, q: q} do
    g = BrandedId.generate!("PRT")
    [live, pend] = for _ <- 1..2, do: BrandedId.generate!("JOB")
    {:ok, :enqueued} = Lanes.enqueue(conn, q, g, live, "live")
    {:ok, :enqueued} = Lanes.enqueue(conn, q, g, pend, "pend")
    # claim `live` -> it leaves the lane for active; gactive[g] = 1
    {:ok, {^live, _, 1, ^g}} = Lanes.claim(conn, q, 60_000)

    # only the one remaining pending member drains
    assert {:ok, 1} = Lanes.drain(conn, q, g)

    # the in-flight member survives: row present, state active, gactive still 1
    assert {:ok, 1} = exists(conn, Keyspace.job_key(q, live))
    assert {:ok, :active} = Metrics.get_job_state(conn, q, live)
    assert {:ok, "1"} = Connector.command(conn, ["HGET", Keyspace.queue_key(q, "gactive"), g])
    # its lease can still settle on its token
    assert :ok = Jobs.complete(conn, q, live, 1)
  end

  test "a sibling lane is untouched by the drain", %{conn: conn, q: q} do
    target = BrandedId.generate!("PRT")
    sibling = BrandedId.generate!("PRT")
    {:ok, :enqueued} = Lanes.enqueue(conn, q, target, BrandedId.generate!("JOB"), "t")
    s1 = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Lanes.enqueue(conn, q, sibling, s1, "s")

    assert {:ok, 1} = Lanes.drain(conn, q, target)

    # the sibling lane's row + set are intact and it is still serviceable
    assert {:ok, 1} = exists(conn, Keyspace.job_key(q, s1))
    assert {:ok, 1} = Lanes.depth(conn, q, sibling)
    assert {:ok, pos} = Connector.command(conn, ["LPOS", Keyspace.queue_key(q, "ring"), sibling])
    assert is_integer(pos)
    # the sibling still claims
    assert {:ok, {^s1, "s", 1, ^sibling}} = Lanes.claim(conn, q, 60_000)
  end

  test "the lane's paused/limit config and the repeat registry survive a drain", %{conn: conn, q: q} do
    g = BrandedId.generate!("PRT")
    # configure a ceiling and pause the lane, then enqueue a member behind it
    :ok = Lanes.limit(conn, q, g, 5)
    :ok = Lanes.pause(conn, q, g)
    {:ok, :enqueued} = Lanes.enqueue(conn, q, g, BrandedId.generate!("JOB"), "w")
    # a repeat registration must survive a lane drain (the registry is not a lane)
    {:ok, :registered} = Repeat.register(conn, q, "rep", 60_000, "tick", 0)

    assert {:ok, 1} = Lanes.drain(conn, q, g)

    # the lane's config keys survive: glimit field present, still paused
    assert {:ok, "5"} = Connector.command(conn, ["HGET", Keyspace.queue_key(q, "glimit"), g])
    assert {:ok, 1} = Connector.command(conn, ["SISMEMBER", Keyspace.queue_key(q, "paused"), g])
    # the repeat registry survives
    assert {:ok, 1} = exists(conn, Keyspace.queue_key(q, "repeat"))
    assert {:ok, 1} = exists(conn, Keyspace.queue_key(q, "repeat:rep"))
  end

  test "an empty or absent lane drains to 0, changing nothing", %{conn: conn, q: q} do
    # a never-populated lane
    absent = BrandedId.generate!("PRT")
    assert {:ok, 0} = Lanes.drain(conn, q, absent)

    # a lane emptied by a prior drain
    g = BrandedId.generate!("PRT")
    {:ok, :enqueued} = Lanes.enqueue(conn, q, g, BrandedId.generate!("JOB"), "w")
    assert {:ok, 1} = Lanes.drain(conn, q, g)
    assert {:ok, 0} = Lanes.drain(conn, q, g)
  end

  test "an ill-formed group raises before any wire", %{conn: conn, q: q} do
    g = BrandedId.generate!("PRT")
    keep = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Lanes.enqueue(conn, q, g, keep, "w")

    assert_raise ArgumentError, fn -> Lanes.drain(conn, q, "not-a-branded-id") end
    # the real lane is untouched -- the raise happened host-side, no drain
    assert {:ok, 1} = Lanes.depth(conn, q, g)
  end
end
