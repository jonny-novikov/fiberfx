defmodule EchoMQ.MetricsTest do
  @moduledoc """
  The read plane (EMQ.2.1-D2..D7): pure-read verbs over the as-built four
  sorted sets, the three-field row, the lane sets, the §6 metrics/limiter/de
  keys, and the EMQRATE concurrency gate. Each verb observes; none mutates --
  the one write the plane earns is the terminal-outcome counter the completion
  and dead-letter transitions keep, proven here to be no phantom. Per-test
  sub-queues with the baseline purge idiom; Valkey on 6390 the truth row.
  """
  use ExUnit.Case, async: false

  @moduletag :valkey

  alias EchoData.BrandedId
  alias EchoMQ.{Connector, Jobs, Keyspace, Lanes, Metrics}

  setup_all do
    :ok = EchoData.Snowflake.start(4)
    :ok
  end

  setup do
    {:ok, conn} = Connector.start_link(port: 6390)
    q = "emq21.metrics#{System.unique_integer([:positive])}"
    on_exit(fn -> purge(q) end)
    %{conn: conn, q: q}
  end

  # -- D2 counts ------------------------------------------------------------

  describe "get_counts/3 (D2)" do
    test "answers the cardinality of each as-built set", %{conn: conn, q: q} do
      # the oldest pending is claimed into active (ZPOPMIN is mint order), so
      # enqueue the to-be-active job first, then three that stay pending
      a = BrandedId.generate!("JOB")
      {:ok, :enqueued} = Jobs.enqueue(conn, q, a, "c")
      {:ok, {^a, _, 1}} = Jobs.claim(conn, q, 60_000)
      for _ <- 1..3, do: {:ok, :enqueued} = Jobs.enqueue(conn, q, BrandedId.generate!("JOB"), "c")
      {:ok, :scheduled} = Jobs.enqueue_in(conn, q, BrandedId.generate!("JOB"), "c", 60_000)

      assert {:ok, %{"pending" => 3, "active" => 1, "schedule" => 1, "dead" => 0}} =
               Metrics.get_counts(conn, q, ["pending", "active", "schedule", "dead"])
    end

    test "an unregistered state name is a typed error, never an open concatenation", %{
      conn: conn,
      q: q
    } do
      assert {:error, {:unknown_state, "wait"}} = Metrics.get_counts(conn, q, ["pending", "wait"])
      assert {:error, {:unknown_state, "prioritized"}} =
               Metrics.get_counts(conn, q, ["prioritized"])
    end

    test "\"completed\" answers from the metrics counter, not a set", %{conn: conn, q: q} do
      id = BrandedId.generate!("JOB")
      {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "c")
      {:ok, {^id, _, 1}} = Jobs.claim(conn, q, 60_000)
      :ok = Jobs.complete(conn, q, id, 1)
      # no `completed` SET exists; the count comes from emq:{q}:metrics:completed
      assert {:ok, %{"completed" => 1}} = Metrics.get_counts(conn, q, ["completed"])
      assert {:ok, 0} = Connector.command(conn, ["EXISTS", Keyspace.queue_key(q, "completed")])
    end

    test "a metric-only request (no set states) still answers — the KEYS[1] slot root is declared", %{
      conn: conn,
      q: q
    } do
      # the formerly-KEYS-empty path: requesting only completed/failed declares
      # no set key, so the queue base must be KEYS[1] to pin the {q} slot
      c = BrandedId.generate!("JOB")
      {:ok, :enqueued} = Jobs.enqueue(conn, q, c, "c")
      {:ok, {^c, _, 1}} = Jobs.claim(conn, q, 60_000)
      :ok = Jobs.complete(conn, q, c, 1)
      f = BrandedId.generate!("JOB")
      {:ok, :enqueued} = Jobs.enqueue(conn, q, f, "c")
      {:ok, {^f, _, 1}} = Jobs.claim(conn, q, 60_000)
      {:ok, :dead} = Jobs.retry(conn, q, f, 1, 10, 1, "boom")

      assert {:ok, %{"completed" => 1, "failed" => 1}} =
               Metrics.get_counts(conn, q, ["completed", "failed"])
    end

    test "the read mutates nothing (counts equal before and after)", %{conn: conn, q: q} do
      for _ <- 1..2, do: {:ok, :enqueued} = Jobs.enqueue(conn, q, BrandedId.generate!("JOB"), "c")
      before = Metrics.get_counts(conn, q, ["pending"])
      _ = Metrics.get_counts(conn, q, ["pending"])
      assert before == Metrics.get_counts(conn, q, ["pending"])
      assert {:ok, %{"pending" => 2}} = before
    end
  end

  # -- D3 job & state lookup ------------------------------------------------

  describe "get_job/3 and get_job_state/3 (D3)" do
    test "get_job reads the three-field row", %{conn: conn, q: q} do
      id = BrandedId.generate!("JOB")
      {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "cargo")

      assert {:ok, %{"state" => "pending", "attempts" => "0", "payload" => "cargo"}} =
               Metrics.get_job(conn, q, id)
    end

    test "a missing job reads the typed absent shape", %{conn: conn, q: q} do
      assert :absent = Metrics.get_job(conn, q, BrandedId.generate!("JOB"))
    end

    test "a claimed job reads active; a scheduled job reads scheduled", %{conn: conn, q: q} do
      claimed = BrandedId.generate!("JOB")
      {:ok, :enqueued} = Jobs.enqueue(conn, q, claimed, "w")
      {:ok, {^claimed, _, 1}} = Jobs.claim(conn, q, 60_000)
      sched = BrandedId.generate!("JOB")
      {:ok, :scheduled} = Jobs.enqueue_in(conn, q, sched, "w", 60_000)
      pend = BrandedId.generate!("JOB")
      {:ok, :enqueued} = Jobs.enqueue(conn, q, pend, "w")

      assert {:ok, :active} = Metrics.get_job_state(conn, q, claimed)
      assert {:ok, :scheduled} = Metrics.get_job_state(conn, q, sched)
      assert {:ok, :pending} = Metrics.get_job_state(conn, q, pend)
    end

    test "a dead job reads dead; a missing job reads absent", %{conn: conn, q: q} do
      id = BrandedId.generate!("JOB")
      {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "w")
      {:ok, {^id, _, 1}} = Jobs.claim(conn, q, 60_000)
      {:ok, :dead} = Jobs.retry(conn, q, id, 1, 10, 1, "gave up")

      assert {:ok, :dead} = Metrics.get_job_state(conn, q, id)
      assert {:ok, :absent} = Metrics.get_job_state(conn, q, BrandedId.generate!("JOB"))
    end

    test "an ill-formed id raises at the key builder (INV5)", %{conn: conn, q: q} do
      assert_raise ArgumentError, fn -> Metrics.get_job(conn, q, "not-branded") end
      assert_raise ArgumentError, fn -> Metrics.get_job_state(conn, q, "USR1") end
    end
  end

  # -- D4 metrics -----------------------------------------------------------

  describe "get_metrics/3 (D4)" do
    test "a completed job increments the completed counter; no phantom", %{conn: conn, q: q} do
      assert {:ok, %{count: 0, data_points: 0}} = Metrics.get_metrics(conn, q, :completed)
      id = BrandedId.generate!("JOB")
      {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "m")
      {:ok, {^id, _, 1}} = Jobs.claim(conn, q, 60_000)
      :ok = Jobs.complete(conn, q, id, 1)
      assert {:ok, %{count: 1, data_points: 0}} = Metrics.get_metrics(conn, q, :completed)
    end

    test "a dead-lettered job increments the failed counter", %{conn: conn, q: q} do
      assert {:ok, %{count: 0}} = Metrics.get_metrics(conn, q, :failed)
      id = BrandedId.generate!("JOB")
      {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "m")
      {:ok, {^id, _, 1}} = Jobs.claim(conn, q, 60_000)
      {:ok, :dead} = Jobs.retry(conn, q, id, 1, 10, 1, "boom")
      assert {:ok, %{count: 1}} = Metrics.get_metrics(conn, q, :failed)
    end

    test "the completed counter is not bumped by a retry that reschedules", %{conn: conn, q: q} do
      id = BrandedId.generate!("JOB")
      {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "m")
      {:ok, {^id, _, 1}} = Jobs.claim(conn, q, 60_000)
      {:ok, :scheduled} = Jobs.retry(conn, q, id, 1, 10, 3, "transient")
      assert {:ok, %{count: 0}} = Metrics.get_metrics(conn, q, :completed)
      assert {:ok, %{count: 0}} = Metrics.get_metrics(conn, q, :failed)
    end
  end

  # -- D5 dedup read --------------------------------------------------------

  describe "get_deduplication_job_id/3 (D5)" do
    test "a parked dedup id reads back; an absent one reads absent", %{conn: conn, q: q} do
      did = "order-99"
      id = BrandedId.generate!("JOB")
      {:ok, _} = Connector.command(conn, ["SET", Keyspace.queue_key(q, "de:" <> did), id])
      assert {:ok, ^id} = Metrics.get_deduplication_job_id(conn, q, did)
      assert :absent = Metrics.get_deduplication_job_id(conn, q, "never")
    end
  end

  # -- D6 rate plane --------------------------------------------------------

  describe "get_rate_limit_ttl/3, get_global_rate_limit/2, is_maxed/2 (D6)" do
    test "an unconfigured queue answers ttl 0 and limit 0", %{conn: conn, q: q} do
      assert {:ok, 0} = Metrics.get_rate_limit_ttl(conn, q)
      assert {:ok, 0} = Metrics.get_global_rate_limit(conn, q)
    end

    test "a rate-limited queue answers a positive TTL", %{conn: conn, q: q} do
      {:ok, _} = Connector.command(conn, ["SET", Keyspace.queue_key(q, "limiter"), "5", "PX", "500"])
      {:ok, _} = Connector.command(conn, ["HSET", Keyspace.queue_key(q, "meta"), "max", "5"])
      assert {:ok, 5} = Metrics.get_global_rate_limit(conn, q)
      assert {:ok, ttl} = Metrics.get_rate_limit_ttl(conn, q)
      assert ttl > 0
    end

    test "the concurrency gate refuses EMQRATE at the ceiling and answers ok below it", %{
      conn: conn,
      q: q
    } do
      {:ok, _} =
        Connector.command(conn, ["HSET", Keyspace.queue_key(q, "meta"), "concurrency", "1"])

      assert :ok = Metrics.is_maxed(conn, q)
      id = BrandedId.generate!("JOB")
      {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "r")
      {:ok, {^id, _, 1}} = Jobs.claim(conn, q, 60_000)
      assert {:error, :rate} = Metrics.is_maxed(conn, q)
    end

    test "an unconfigured concurrency answers ok (no ceiling)", %{conn: conn, q: q} do
      id = BrandedId.generate!("JOB")
      {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "r")
      {:ok, {^id, _, 1}} = Jobs.claim(conn, q, 60_000)
      assert :ok = Metrics.is_maxed(conn, q)
    end
  end

  # -- D7 per-lane introspection --------------------------------------------

  describe "lane_depth/3 and lane_depths/3 (D7)" do
    test "two lanes answer their separate backlogs", %{conn: conn, q: q} do
      [a, b] = for _ <- 1..2, do: BrandedId.generate!("PRT")
      for _ <- 1..2, do: {:ok, :enqueued} = Lanes.enqueue(conn, q, a, BrandedId.generate!("JOB"), "l")
      {:ok, :enqueued} = Lanes.enqueue(conn, q, b, BrandedId.generate!("JOB"), "l")

      assert {:ok, 2} = Metrics.lane_depth(conn, q, a)
      assert {:ok, 1} = Metrics.lane_depth(conn, q, b)
      assert {:ok, %{^a => 2, ^b => 1}} = Metrics.lane_depths(conn, q, [a, b])
    end

    test "an ill-formed group raises (INV5)", %{conn: conn, q: q} do
      assert_raise ArgumentError, fn -> Metrics.lane_depths(conn, q, ["not-branded"]) end
    end
  end

  defp purge(q) do
    {:ok, conn} = Connector.start_link(port: 6390)
    {:ok, keys} = Connector.command(conn, ["KEYS", "emq:{" <> q <> "}:*"])
    if keys != [], do: {:ok, _} = Connector.command(conn, ["DEL" | keys])
    :ok
  end
end
