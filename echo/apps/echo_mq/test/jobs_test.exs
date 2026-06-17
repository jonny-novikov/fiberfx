defmodule EchoMQ.JobsTest do
  @moduledoc """
  The wire column of the Jobs row (echo2-migration.md §5), on per-test
  sub-queues with the baseline purge idiom (the Conformance purge
  pattern, conformance.ex:271-275).
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
    q = "emq0.jobs#{System.unique_integer([:positive])}"

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

  test "enqueue/4 admits, refuses the duplicate, and refuses the wrong kind", %{conn: conn, q: q} do
    id = BrandedId.generate!("JOB")
    foreign = BrandedId.generate!("ORD")

    assert {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "cargo")
    assert {:ok, :duplicate} = Jobs.enqueue(conn, q, id, "again")
    assert {:error, :kind} = Jobs.enqueue(conn, q, foreign, "x")

    assert {:ok, "cargo"} = Connector.command(conn, ["HGET", Keyspace.job_key(q, id), "payload"])
    assert {:ok, 0} = Connector.command(conn, ["EXISTS", Keyspace.job_key(q, foreign)])
  end

  test "claim/3 mints the token and complete/4 retires only for its holder", %{conn: conn, q: q} do
    id = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "work")

    assert {:ok, {^id, "work", 1}} = Jobs.claim(conn, q, 60_000)
    assert :empty = Jobs.claim(conn, q, 60_000)

    assert {:error, :stale} = Jobs.complete(conn, q, id, 99)
    assert :ok = Jobs.complete(conn, q, id, 1)
    assert {:error, :gone} = Jobs.complete(conn, q, id, 1)

    assert {:ok, 0} = Connector.command(conn, ["EXISTS", Keyspace.job_key(q, id)])
  end

  test "retry/7 schedules with last_error kept and promote/3 returns it", %{conn: conn, q: q} do
    id = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "w")
    {:ok, {^id, _, 1}} = Jobs.claim(conn, q, 60_000)

    assert {:ok, :scheduled} = Jobs.retry(conn, q, id, 1, 10, 3, "boom")
    assert {:ok, "scheduled"} = Connector.command(conn, ["HGET", Keyspace.job_key(q, id), "state"])
    assert {:ok, "boom"} = Connector.command(conn, ["HGET", Keyspace.job_key(q, id), "last_error"])

    Process.sleep(30)
    assert {:ok, 1} = Jobs.promote(conn, q, 10)
    assert {:ok, {^id, _, 2}} = Jobs.claim(conn, q, 60_000)
    assert :ok = Jobs.complete(conn, q, id, 2)
  end

  test "retry/7 past the attempts cap dead-letters with last_error kept", %{conn: conn, q: q} do
    id = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "w")
    {:ok, {^id, _, 1}} = Jobs.claim(conn, q, 60_000)

    assert {:ok, :dead} = Jobs.retry(conn, q, id, 1, 10, 1, "gave up")
    assert {:ok, "dead"} = Connector.command(conn, ["HGET", Keyspace.job_key(q, id), "state"])
    assert {:ok, "gave up"} = Connector.command(conn, ["HGET", Keyspace.job_key(q, id), "last_error"])

    assert {:ok, [^id]} =
             Connector.command(conn, [
               "ZRANGE",
               Keyspace.queue_key(q, "dead"),
               "+",
               "-",
               "BYLEX",
               "REV"
             ])
  end

  test "a stale retry token is refused", %{conn: conn, q: q} do
    id = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "w")
    {:ok, {^id, _, 1}} = Jobs.claim(conn, q, 60_000)

    assert {:error, :stale} = Jobs.retry(conn, q, id, 99, 10, 3, "nope")
  end

  test "reap/2 returns an expired lease to pending on the server clock", %{conn: conn, q: q} do
    id = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "w")
    {:ok, {^id, _, 1}} = Jobs.claim(conn, q, 30)

    Process.sleep(60)

    assert {:ok, 1} = Jobs.reap(conn, q)
    assert {:ok, "pending"} = Connector.command(conn, ["HGET", Keyspace.job_key(q, id), "state"])
    assert {:ok, {^id, _, 2}} = Jobs.claim(conn, q, 60_000)
  end

  test "browse/3 walks newest-first and pending_size/2 counts", %{conn: conn, q: q} do
    ids =
      for _ <- 1..3 do
        id = BrandedId.generate!("JOB")
        {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "o")
        id
      end

    [a, b, c] = ids

    assert {:ok, [^c, ^b]} = Jobs.browse(conn, q, 2)
    assert {:ok, [^c, ^b, ^a]} = Jobs.browse(conn, q, 10)
    assert {:ok, 3} = Jobs.pending_size(conn, q)
  end

  test "enqueue_many/3 answers per-item verdicts in input order", %{conn: conn, q: q} do
    a = BrandedId.generate!("JOB")
    b = BrandedId.generate!("JOB")
    foreign = BrandedId.generate!("ORD")

    assert {:ok, [:enqueued, :duplicate, {:error, :kind}, :enqueued]} =
             Jobs.enqueue_many(conn, q, [{a, "p1"}, {a, "p2"}, {foreign, "p3"}, {b, "p4"}])

    assert {:ok, 2} = Jobs.pending_size(conn, q)
  end
end
