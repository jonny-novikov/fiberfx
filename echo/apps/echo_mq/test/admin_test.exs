defmodule EchoMQ.AdminTest do
  @moduledoc """
  The wire column of the operator plane's queue-scope verbs (emq.2.2 D2–D4):
  queue-wide pause/resume, drain, and obliterate, on per-test sub-queues with
  the baseline purge idiom. Acceptance is read through the emq.2.1 read lens
  (`EchoMQ.Metrics`). AS-2 / AS-3 / AS-4.
  """
  use ExUnit.Case, async: false

  @moduletag :valkey

  alias EchoData.BrandedId
  alias EchoMQ.{Admin, Connector, Jobs, Keyspace, Lanes, Metrics, Repeat}

  setup_all do
    :ok = EchoData.Snowflake.start(4)
    :ok
  end

  setup do
    {:ok, conn} = Connector.start_link(port: 6390)
    q = "emq22.admin#{System.unique_integer([:positive])}"
    on_exit(fn -> purge(q) end)
    %{conn: conn, q: q}
  end

  defp purge(q) do
    {:ok, conn} = Connector.start_link(port: 6390)
    {:ok, keys} = Connector.command(conn, ["KEYS", "emq:{" <> q <> "}:*"])
    if keys != [], do: {:ok, _} = Connector.command(conn, ["DEL" | keys])
    GenServer.stop(conn)
  end

  # -- D2: queue-wide pause / resume ----------------------------------------

  test "pause/2 gates the whole queue and the backlog survives; resume/2 restores", %{conn: conn, q: q} do
    a = BrandedId.generate!("JOB")
    b = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Jobs.enqueue(conn, q, a, "p1")
    {:ok, :enqueued} = Jobs.enqueue(conn, q, b, "p2")

    assert :ok = Admin.pause(conn, q)
    assert Jobs.paused?(conn, q)
    assert :empty = Jobs.claim(conn, q, 60_000)
    # the backlog is untouched -- the count reads the same depth
    assert {:ok, %{"pending" => 2}} = Metrics.get_counts(conn, q, ["pending"])

    assert :ok = Admin.resume(conn, q)
    refute Jobs.paused?(conn, q)
    assert {:ok, {^a, "p1", 1}} = Jobs.claim(conn, q, 60_000)
  end

  test "the queue-wide pause is DISTINCT from Lanes.pause/3 and gates the grouped claim", %{conn: conn, q: q} do
    g = BrandedId.generate!("PRT")
    j = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Lanes.enqueue(conn, q, g, j, "g")

    assert :ok = Admin.pause(conn, q)
    # the queue-wide pause gates the grouped claim too
    assert :empty = Lanes.claim(conn, q, 60_000)
    # but it did NOT touch the per-group paused SET (Lanes' park)
    assert {:ok, 0} = Connector.command(conn, ["SISMEMBER", Keyspace.queue_key(q, "paused"), g])
    # the lane backlog is intact
    assert {:ok, 1} = Lanes.depth(conn, q, g)

    assert :ok = Admin.resume(conn, q)
    assert {:ok, {^j, "g", 1, ^g}} = Lanes.claim(conn, q, 60_000)
  end

  test "pause/2 and resume/2 are idempotent", %{conn: conn, q: q} do
    assert :ok = Admin.pause(conn, q)
    assert :ok = Admin.pause(conn, q)
    assert Jobs.paused?(conn, q)
    assert :ok = Admin.resume(conn, q)
    assert :ok = Admin.resume(conn, q)
    refute Jobs.paused?(conn, q)
  end

  # -- D3: drain ------------------------------------------------------------

  test "drain/3 empties pending and deletes the rows; active stays in flight", %{conn: conn, q: q} do
    live = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Jobs.enqueue(conn, q, live, "active")
    {:ok, {^live, _, 1}} = Jobs.claim(conn, q, 60_000)

    waiting = for _ <- 1..3, do: BrandedId.generate!("JOB")
    Enum.each(waiting, fn id -> {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "w") end)
    # give one of them a log subkey so the row-delete sweep is exercised
    {:ok, _} = Jobs.add_log(conn, q, hd(waiting), "diag")

    assert {:ok, 3} = Admin.drain(conn, q)
    assert {:ok, %{"pending" => 0, "active" => 1}} = Metrics.get_counts(conn, q, ["pending", "active"])
    assert {:ok, :active} = Metrics.get_job_state(conn, q, live)
    # each drained row + its logs subkey are gone
    assert {:ok, 0} = Connector.command(conn, ["EXISTS", Keyspace.job_key(q, hd(waiting))])
    assert {:ok, 0} = Connector.command(conn, ["EXISTS", Keyspace.job_key(q, hd(waiting)) <> ":logs"])
  end

  test "drain/3 with include_schedule empties schedule but leaves the repeat REGISTRY intact", %{conn: conn, q: q} do
    pend = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Jobs.enqueue(conn, q, pend, "w")
    sched = BrandedId.generate!("JOB")
    {:ok, :scheduled} = Jobs.enqueue_in(conn, q, sched, "s", 60_000)
    {:ok, :registered} = Repeat.register(conn, q, "nightly", 60_000, "tick", 60_000)

    assert {:ok, 2} = Admin.drain(conn, q, include_schedule: true)
    assert {:ok, %{"pending" => 0, "schedule" => 0}} = Metrics.get_counts(conn, q, ["pending", "schedule"])
    # the registered repeatable survives -- a drain does not cancel it (D-4)
    assert {:ok, 1} = Repeat.count(conn, q)
  end

  test "drain/3 without the schedule flag leaves schedule untouched", %{conn: conn, q: q} do
    sched = BrandedId.generate!("JOB")
    {:ok, :scheduled} = Jobs.enqueue_in(conn, q, sched, "s", 60_000)

    assert {:ok, 0} = Admin.drain(conn, q)
    assert {:ok, %{"schedule" => 1}} = Metrics.get_counts(conn, q, ["schedule"])
  end

  # -- D4: obliterate -------------------------------------------------------

  test "obliterate/3 destroys a paused queue: every set and the §6 keys gone", %{conn: conn, q: q} do
    # the to-be-dead job is enqueued + claimed FIRST (claim is ZPOPMIN, mint
    # order), so the later-minted pending/scheduled jobs stay put
    d = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Jobs.enqueue(conn, q, d, "w")
    {:ok, {^d, _, 1}} = Jobs.claim(conn, q, 60_000)
    {:ok, :dead} = Jobs.retry(conn, q, d, 1, 10, 1, "x")

    p = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Jobs.enqueue(conn, q, p, "w")
    s = BrandedId.generate!("JOB")
    {:ok, :scheduled} = Jobs.enqueue_in(conn, q, s, "s", 60_000)

    assert :ok = Admin.pause(conn, q)
    assert :ok = Admin.obliterate(conn, q)

    assert {:ok, %{"pending" => 0, "active" => 0, "schedule" => 0, "dead" => 0}} =
             Metrics.get_counts(conn, q, ["pending", "active", "schedule", "dead"])

    # the whole queue keyspace footprint is gone (meta with the paused flag too)
    assert {:ok, []} = Connector.command(conn, ["KEYS", "emq:{" <> q <> "}:*"])
  end

  test "obliterate/3 refuses a NON-paused queue with :not_paused, changing nothing", %{conn: conn, q: q} do
    id = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "w")

    assert {:error, :not_paused} = Admin.obliterate(conn, q)
    # nothing changed
    assert {:ok, %{"pending" => 1}} = Metrics.get_counts(conn, q, ["pending"])
    assert {:ok, :pending} = Metrics.get_job_state(conn, q, id)
  end

  test "obliterate/3 refuses a paused queue with live active jobs unless forced", %{conn: conn, q: q} do
    id = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "w")
    {:ok, {^id, _, 1}} = Jobs.claim(conn, q, 60_000)
    assert :ok = Admin.pause(conn, q)

    # without force, the live active job blocks obliterate
    assert {:error, :active} = Admin.obliterate(conn, q)
    assert {:ok, %{"active" => 1}} = Metrics.get_counts(conn, q, ["active"])

    # with force, it destroys the queue including the active job
    assert :ok = Admin.obliterate(conn, q, force: true)
    assert {:ok, []} = Connector.command(conn, ["KEYS", "emq:{" <> q <> "}:*"])
  end

  test "obliterate/3 is bounded per call: a small budget answers :more then :ok", %{conn: conn, q: q} do
    ids = for _ <- 1..5, do: BrandedId.generate!("JOB")
    Enum.each(ids, fn id -> {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "w") end)
    assert :ok = Admin.pause(conn, q)

    # budget 2 cannot finish in one call
    assert :more = Admin.obliterate(conn, q, budget: 2)
    # keep calling until done
    drain_obliterate(conn, q)
    assert {:ok, []} = Connector.command(conn, ["KEYS", "emq:{" <> q <> "}:*"])
  end

  defp drain_obliterate(conn, q) do
    case Admin.obliterate(conn, q, budget: 2) do
      :more -> drain_obliterate(conn, q)
      :ok -> :ok
    end
  end
end
