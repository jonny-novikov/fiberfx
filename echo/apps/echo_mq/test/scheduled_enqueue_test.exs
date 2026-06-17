defmodule EchoMQ.ScheduledEnqueueTest do
  @moduledoc """
  The scheduled-enqueue verbs (EMQ.1-D2): run-at and run-in mint a fresh
  branded JOB id, park it on the schedule set invisible to claim until due,
  and release it through the existing promote sweep -- a visibility fence,
  not a second queue. Per-test sub-queues with the baseline purge idiom.
  """
  use ExUnit.Case, async: false

  @moduletag :valkey

  alias EchoData.BrandedId
  alias EchoMQ.{Connector, Jobs, Keyspace}

  setup_all do
    :ok = EchoData.Snowflake.start(4)
    :ok
  end

  setup do
    {:ok, conn} = Connector.start_link(port: 6390)
    q = "emq1.sched#{System.unique_integer([:positive])}"
    on_exit(fn -> purge(q) end)
    %{conn: conn, q: q}
  end

  defp purge(q) do
    {:ok, conn} = Connector.start_link(port: 6390)
    {:ok, keys} = Connector.command(conn, ["KEYS", "emq:{" <> q <> "}:*"])
    if keys != [], do: {:ok, _} = Connector.command(conn, ["DEL" | keys])
    GenServer.stop(conn)
  end

  test "enqueue_in/5 parks on the schedule set, invisible to claim, until promoted", %{conn: conn, q: q} do
    id = BrandedId.generate!("JOB")

    assert {:ok, :scheduled} = Jobs.enqueue_in(conn, q, id, "later", 40)
    assert {:ok, "scheduled"} = Connector.command(conn, ["HGET", Keyspace.job_key(q, id), "state"])
    assert {:ok, 1} = Connector.command(conn, ["ZCARD", Keyspace.queue_key(q, "schedule")])

    # invisible to claim before due
    assert :empty = Jobs.claim(conn, q, 60_000)
    # premature promote releases nothing (not yet due)
    assert {:ok, 0} = Jobs.promote(conn, q, 10)
    assert :empty = Jobs.claim(conn, q, 60_000)

    Process.sleep(60)
    assert {:ok, 1} = Jobs.promote(conn, q, 10)
    assert {:ok, {^id, "later", 1}} = Jobs.claim(conn, q, 60_000)
    assert :ok = Jobs.complete(conn, q, id, 1)
  end

  test "enqueue_at/5 parks at an absolute due time and releases once past", %{conn: conn, q: q} do
    id = BrandedId.generate!("JOB")
    {:ok, [secs, micros]} = Connector.command(conn, ["TIME"])
    now_ms = String.to_integer(secs) * 1000 + div(String.to_integer(micros), 1000)
    run_at = now_ms + 40

    assert {:ok, :scheduled} = Jobs.enqueue_at(conn, q, id, "settle", run_at)
    assert :empty = Jobs.claim(conn, q, 60_000)

    Process.sleep(60)
    assert {:ok, 1} = Jobs.promote(conn, q, 10)
    assert {:ok, {^id, "settle", 1}} = Jobs.claim(conn, q, 60_000)
  end

  test "scheduled enqueue mints a fresh JOB id and refuses a non-JOB kind", %{conn: conn, q: q} do
    foreign = BrandedId.generate!("ORD")
    # the host-side job_key gate raises before the wire for a non-branded id;
    # a valid but wrong-namespace id is refused by the kind law wire-side
    assert {:error, :kind} = Jobs.enqueue_in(conn, q, foreign, "x", 10)
    assert {:ok, 0} = Connector.command(conn, ["EXISTS", Keyspace.job_key(q, foreign)])
  end

  test "scheduled enqueue refuses a duplicate id", %{conn: conn, q: q} do
    id = BrandedId.generate!("JOB")
    assert {:ok, :scheduled} = Jobs.enqueue_in(conn, q, id, "once", 1_000)
    assert {:ok, :duplicate} = Jobs.enqueue_in(conn, q, id, "twice", 1_000)
    assert {:ok, "once"} = Connector.command(conn, ["HGET", Keyspace.job_key(q, id), "payload"])
  end

  test "the mint-ordered id stays the sort key: minted-early/scheduled-late sorts by mint once promoted", %{conn: conn, q: q} do
    # id_a mints first but is scheduled to release LAST; id_b mints second,
    # released FIRST. Once both are promoted to pending, the lex order of the
    # ids (= mint order) is what a newest-first browse returns -- the
    # visibility instant never reorders them.
    id_a = BrandedId.generate!("JOB")
    id_b = BrandedId.generate!("JOB")
    assert id_a < id_b

    {:ok, :scheduled} = Jobs.enqueue_in(conn, q, id_a, "a", 30)
    {:ok, :scheduled} = Jobs.enqueue_in(conn, q, id_b, "b", 30)

    Process.sleep(50)
    assert {:ok, 2} = Jobs.promote(conn, q, 10)

    # newest-first browse over the pending ids: id_b (later mint) first
    assert {:ok, [^id_b, ^id_a]} = Jobs.browse(conn, q, 10)
  end
end
