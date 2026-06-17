defmodule EchoMQ.RepeatTest do
  @moduledoc """
  The repeatable-job registry (EMQ.1-D3): register/cancel verbs over the
  declared `emq:{q}:repeat` zset + `emq:{q}:repeat:<name>` record, the due
  read, and the advance. Each occurrence is a fresh branded mint host-side
  (the pump's job, driven directly here). Per-test sub-queues.
  """
  use ExUnit.Case, async: false

  @moduletag :valkey

  alias EchoData.BrandedId
  alias EchoMQ.{Connector, Jobs, Keyspace, Repeat}

  setup_all do
    :ok = EchoData.Snowflake.start(4)
    :ok
  end

  setup do
    {:ok, conn} = Connector.start_link(port: 6390)
    q = "emq1.repeat#{System.unique_integer([:positive])}"
    on_exit(fn -> purge(q) end)
    %{conn: conn, q: q}
  end

  defp purge(q) do
    {:ok, conn} = Connector.start_link(port: 6390)
    {:ok, keys} = Connector.command(conn, ["KEYS", "emq:{" <> q <> "}:*"])
    if keys != [], do: {:ok, _} = Connector.command(conn, ["DEL" | keys])
    GenServer.stop(conn)
  end

  # one occurrence: read due, mint fresh, enqueue, advance -- the pump's body
  defp fire(conn, q, name) do
    {:ok, [{^name, every, template}]} = Repeat.due(conn, q, 10)
    id = BrandedId.generate!("JOB")
    {:ok, _} = Jobs.enqueue(conn, q, id, template)
    {:ok, :advanced} = Repeat.advance(conn, q, name, String.to_integer(every))
    id
  end

  test "register writes the declared pair and is idempotent", %{conn: conn, q: q} do
    assert {:ok, :registered} = Repeat.register(conn, q, "daily", 60_000, "report", 0)
    assert {:ok, 1} = Repeat.count(conn, q)

    record = Keyspace.queue_key(q, "repeat:") <> "daily"
    assert {:ok, "60000"} = Connector.command(conn, ["HGET", record, "every_ms"])
    assert {:ok, "report"} = Connector.command(conn, ["HGET", record, "template"])

    # a second register of a live name changes nothing
    assert {:ok, :exists} = Repeat.register(conn, q, "daily", 999, "other", 0)
    assert {:ok, "60000"} = Connector.command(conn, ["HGET", record, "every_ms"])
  end

  test "two occurrences carry two distinct ids in mint order", %{conn: conn, q: q} do
    {:ok, :registered} = Repeat.register(conn, q, "sweep", 10, "recon", 0)

    first = fire(conn, q, "sweep")
    Process.sleep(20)
    second = fire(conn, q, "sweep")

    assert first != second
    # later occurrence mints a later (greater) branded id
    assert second > first

    # both are real, browsable, mint-ordered pending jobs
    assert {:ok, [^second, ^first]} = Jobs.browse(conn, q, 10)
  end

  test "cancel removes the registration from the declared keyspace", %{conn: conn, q: q} do
    {:ok, :registered} = Repeat.register(conn, q, "gone", 10, "x", 0)
    assert {:ok, 1} = Repeat.count(conn, q)

    assert {:ok, :cancelled} = Repeat.cancel(conn, q, "gone")
    assert {:ok, 0} = Repeat.count(conn, q)
    assert {:ok, 0} = Connector.command(conn, ["EXISTS", Keyspace.queue_key(q, "repeat:") <> "gone"])

    # no further occurrence is due
    assert {:ok, []} = Repeat.due(conn, q, 10)
    # cancelling an absent registration is honest
    assert {:ok, :absent} = Repeat.cancel(conn, q, "gone")
  end

  test "a registration with first_in delay is not due until the delay passes", %{conn: conn, q: q} do
    {:ok, :registered} = Repeat.register(conn, q, "delayed", 10_000, "later", 40)
    assert {:ok, []} = Repeat.due(conn, q, 10)

    Process.sleep(60)
    assert {:ok, [{"delayed", "10000", "later"}]} = Repeat.due(conn, q, 10)
  end

  test "advance pushes the next run beyond now so it is not immediately re-due", %{conn: conn, q: q} do
    {:ok, :registered} = Repeat.register(conn, q, "cad", 10_000, "p", 0)
    assert {:ok, [{"cad", _, _}]} = Repeat.due(conn, q, 10)

    {:ok, :advanced} = Repeat.advance(conn, q, "cad", 10_000)
    # advanced 10s out -> not due now
    assert {:ok, []} = Repeat.due(conn, q, 10)
  end

  test "advance on a cancelled record sweeps the dangling member", %{conn: conn, q: q} do
    {:ok, :registered} = Repeat.register(conn, q, "race", 10, "x", 0)
    # delete the record out of band, leaving the registry member dangling
    {:ok, _} = Connector.command(conn, ["DEL", Keyspace.queue_key(q, "repeat:") <> "race"])

    assert {:ok, :absent} = Repeat.advance(conn, q, "race", 10)
    assert {:ok, 0} = Repeat.count(conn, q)
  end

  test "every key of the repeat family lands on the queue's slot" do
    slots =
      for type <- ["repeat", "repeat:daily", "schedule", "pending"] do
        Keyspace.slot(Keyspace.queue_key("q9", type))
      end

    assert [_one] = Enum.uniq(slots)
  end
end
