defmodule EchoMQ.MetricsDepthTest do
  @moduledoc """
  EMQ.2.4-D5 -- the read-plane DEPTH suite: the v1 read-depth scenarios
  (`queue_getters_test.exs` / `queue_integration_test.exs` /
  `rate_limiter_integration_test.exs`) re-derived against the SHIPPED
  `EchoMQ.Metrics` verbs, at v1's scenario depth -- multi-job, concurrent, and
  at the edges, beyond the single happy-path each verb shipped with in
  `metrics_test.exs`.

  Closed for the shipped read surface, honestly bounded for the rest (INV2):
  every test drives a verb `echo_mq` ACTUALLY ships -- `get_counts/3`,
  `get_job/3`, `get_job_state/3`, `get_metrics/3`, `get_deduplication_job_id/3`,
  `is_maxed/2`, `lane_depth/3`, `lane_depths/3`. No transition is rewritten;
  the plane is read-only (INV2). The minting depth is the order theorem (INV5)
  -- the multi-job scenarios mint DISTINCT branded ids in mint order.

  Determinism posture (INV7): the read plane is synchronous deterministic
  round-trips with no minting timer, so the multi-seed sweep is the honest
  posture -- running the ≥100 process-loop on a non-process suite would forge
  load the rung did not introduce (the emq.2.1 precedent). The concurrent
  scenario uses a barrier (Task.await on each mint) so the count read happens
  AFTER the structures settle -- no read races a half-applied transition.

  Un-ported v1 read depth attributed (D8): the v1 worker-roster getters
  (`get_workers`/`get_workers_count`) are emq.6 (the worker registry), NOT
  read here. Per-test sub-queues; Valkey 6390 the truth row. EMQ.2.4-AS3 /
  EMQ.2.4-US5.
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
    q = "emq24.mdepth#{System.unique_integer([:positive])}"
    on_exit(fn -> purge(q) end)
    %{conn: conn, q: q}
  end

  # -- counts equal the structure cardinalities, multi-job + concurrent -------

  describe "get_counts/3 at depth -- the count equals the live cardinality" do
    test "across all four sets at once, with a populated each", %{conn: conn, q: q} do
      # claim the OLDEST (mint order: enqueue the to-be-active first), so the
      # later-minted pending stay put; build a populated pending/active/schedule/
      # dead in one queue and read every cardinality in one call.
      active = BrandedId.generate!("JOB")
      {:ok, :enqueued} = Jobs.enqueue(conn, q, active, "c")
      {:ok, {^active, _, 1}} = Jobs.claim(conn, q, 60_000)

      dead = BrandedId.generate!("JOB")
      {:ok, :enqueued} = Jobs.enqueue(conn, q, dead, "c")
      {:ok, {^dead, _, 1}} = Jobs.claim(conn, q, 60_000)
      {:ok, :dead} = Jobs.retry(conn, q, dead, 1, 10, 1, "x")

      pending = for _ <- 1..4, do: BrandedId.generate!("JOB")
      Enum.each(pending, fn id -> {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "c") end)
      sched = for _ <- 1..2, do: BrandedId.generate!("JOB")
      Enum.each(sched, fn id -> {:ok, :scheduled} = Jobs.enqueue_in(conn, q, id, "c", 60_000) end)

      assert {:ok, %{"pending" => 4, "active" => 1, "schedule" => 2, "dead" => 1}} =
               Metrics.get_counts(conn, q, ["pending", "active", "schedule", "dead"])
    end

    test "concurrent enqueues -- the count equals the number of jobs minted (no drift)",
         %{conn: conn, q: q} do
      # N concurrent enqueuers, each on its OWN connection (mints serialize at
      # the host Snowflake, but the enqueues hit the wire concurrently). Barrier:
      # await every task before the read, so no count races a half-applied write.
      n = 12

      tasks =
        for _ <- 1..n do
          Task.async(fn ->
            {:ok, c} = Connector.start_link(port: 6390)
            id = BrandedId.generate!("JOB")
            {:ok, :enqueued} = Jobs.enqueue(c, q, id, "x")
            GenServer.stop(c)
            id
          end)
        end

      ids = Enum.map(tasks, &Task.await(&1, 5_000))
      # distinct ids (the order theorem -- no same-ms collision survives)
      assert length(Enum.uniq(ids)) == n
      assert {:ok, %{"pending" => ^n}} = Metrics.get_counts(conn, q, ["pending"])
    end

    test "the count tracks a claim/complete cycle exactly", %{conn: conn, q: q} do
      ids = for _ <- 1..5, do: BrandedId.generate!("JOB")
      Enum.each(ids, fn id -> {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "c") end)
      assert {:ok, %{"pending" => 5, "active" => 0}} = Metrics.get_counts(conn, q, ["pending", "active"])

      # claim three -> pending 2, active 3
      claimed =
        for _ <- 1..3 do
          {:ok, {id, _, 1}} = Jobs.claim(conn, q, 60_000)
          id
        end

      assert {:ok, %{"pending" => 2, "active" => 3}} =
               Metrics.get_counts(conn, q, ["pending", "active"])

      # complete two -> active 1 (completed retires the row, no set holds it)
      [a, b | _] = claimed
      :ok = Jobs.complete(conn, q, a, 1)
      :ok = Jobs.complete(conn, q, b, 1)
      assert {:ok, %{"active" => 1}} = Metrics.get_counts(conn, q, ["active"])
      assert {:ok, %{"completed" => 2}} = Metrics.get_counts(conn, q, ["completed"])
    end

    test "an unregistered state name in a populated request is a typed error", %{conn: conn, q: q} do
      {:ok, :enqueued} = Jobs.enqueue(conn, q, BrandedId.generate!("JOB"), "c")
      assert {:error, {:unknown_state, "waiting"}} =
               Metrics.get_counts(conn, q, ["pending", "waiting"])
    end
  end

  # -- state across every set + the in-flight + the absent --------------------

  describe "get_job_state/3 at depth -- one job in each set, plus in-flight and absent" do
    test "reads pending/active/scheduled/dead/absent each correctly", %{conn: conn, q: q} do
      # claim is ZPOPMIN (mint order, oldest-first), so the to-be-active and
      # to-be-dead jobs must be MINTED FIRST -- they are the oldest in pending,
      # so they are the two the claims pop. The to-stay-pending job is minted
      # last, so a claim never reaches it.
      active = BrandedId.generate!("JOB")
      {:ok, :enqueued} = Jobs.enqueue(conn, q, active, "w")
      {:ok, {^active, _, 1}} = Jobs.claim(conn, q, 60_000)

      dead = BrandedId.generate!("JOB")
      {:ok, :enqueued} = Jobs.enqueue(conn, q, dead, "w")
      {:ok, {^dead, _, 1}} = Jobs.claim(conn, q, 60_000)
      {:ok, :dead} = Jobs.retry(conn, q, dead, 1, 10, 1, "x")

      pending = BrandedId.generate!("JOB")
      {:ok, :enqueued} = Jobs.enqueue(conn, q, pending, "w")

      sched = BrandedId.generate!("JOB")
      {:ok, :scheduled} = Jobs.enqueue_in(conn, q, sched, "w", 60_000)

      missing = BrandedId.generate!("JOB")

      assert {:ok, :pending} = Metrics.get_job_state(conn, q, pending)
      assert {:ok, :active} = Metrics.get_job_state(conn, q, active)
      assert {:ok, :scheduled} = Metrics.get_job_state(conn, q, sched)
      assert {:ok, :dead} = Metrics.get_job_state(conn, q, dead)
      assert {:ok, :absent} = Metrics.get_job_state(conn, q, missing)
    end

    test "the in-flight :unknown -- a row that exists but is in no set reads :unknown", %{
      conn: conn,
      q: q
    } do
      # A job whose row HASH exists but whose id is in none of the four sorted
      # sets: the transient window a transition lands in. get_job_state's
      # @state_lookup script returns 'unknown' when no set holds the id but the
      # row EXISTS (metrics.ex @state_lookup, the in-flight read the spec names
      # in D5). Construct it by claiming (active holds it) then ZREM-ing from
      # active WITHOUT a transition -- a synthetic in-flight gap, the row intact.
      id = BrandedId.generate!("JOB")
      {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "w")
      {:ok, {^id, _, 1}} = Jobs.claim(conn, q, 60_000)
      # remove it from the active set but leave the row -> set-less but present
      {:ok, 1} = Connector.command(conn, ["ZREM", Keyspace.queue_key(q, "active"), id])

      # get_job still reads the row (the row HASH is intact)...
      assert {:ok, %{"state" => "active"}} = Metrics.get_job(conn, q, id)
      # ...and the state lookup answers :unknown -- the set-less-but-present read,
      # distinct from :absent (no row) and from the four set states (INV2).
      assert {:ok, :unknown} = Metrics.get_job_state(conn, q, id)
    end
  end

  # -- metrics monotone under repeated completion / dead ----------------------

  describe "get_metrics/3 at depth -- the terminal counters are monotone" do
    test "the completed counter rises by one per completion and never falls", %{conn: conn, q: q} do
      assert {:ok, %{count: 0, data_points: 0}} = Metrics.get_metrics(conn, q, :completed)

      for n <- 1..5 do
        id = BrandedId.generate!("JOB")
        {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "m")
        {:ok, {^id, _, 1}} = Jobs.claim(conn, q, 60_000)
        :ok = Jobs.complete(conn, q, id, 1)
        assert {:ok, %{count: ^n}} = Metrics.get_metrics(conn, q, :completed)
      end

      # data_points stays honest-0 across all of it (the :data series is held to
      # emq.8 -- D3; no phantom series is read)
      assert {:ok, %{count: 5, data_points: 0}} = Metrics.get_metrics(conn, q, :completed)
    end

    test "the failed counter rises only on dead-letter, not on a reschedule", %{conn: conn, q: q} do
      assert {:ok, %{count: 0}} = Metrics.get_metrics(conn, q, :failed)

      # a retry that RESCHEDULES does not bump failed
      r = BrandedId.generate!("JOB")
      {:ok, :enqueued} = Jobs.enqueue(conn, q, r, "m")
      {:ok, {^r, _, 1}} = Jobs.claim(conn, q, 60_000)
      {:ok, :scheduled} = Jobs.retry(conn, q, r, 1, 10, 3, "transient")
      assert {:ok, %{count: 0}} = Metrics.get_metrics(conn, q, :failed)

      # three dead-letters -> failed rises to 3
      for n <- 1..3 do
        id = BrandedId.generate!("JOB")
        {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "m")
        {:ok, {^id, _, 1}} = Jobs.claim(conn, q, 60_000)
        {:ok, :dead} = Jobs.retry(conn, q, id, 1, 10, 1, "boom")
        assert {:ok, %{count: ^n}} = Metrics.get_metrics(conn, q, :failed)
      end
    end
  end

  # -- dedup read / absent ----------------------------------------------------

  describe "get_deduplication_job_id/3 at depth" do
    test "several parked keys each read back their own id; an absent one reads absent",
         %{conn: conn, q: q} do
      parks =
        for n <- 1..3 do
          did = "batch-#{n}"
          id = BrandedId.generate!("JOB")
          {:ok, _} = Connector.command(conn, ["SET", Keyspace.queue_key(q, "de:" <> did), id])
          {did, id}
        end

      for {did, id} <- parks do
        assert {:ok, ^id} = Metrics.get_deduplication_job_id(conn, q, did)
      end

      assert :absent = Metrics.get_deduplication_job_id(conn, q, "never-parked")
    end
  end

  # -- rate read at / below / above the ceiling -------------------------------

  describe "is_maxed/2 at depth -- the rate read at every edge of the ceiling" do
    test "below, at, and re-opened above->below the ceiling", %{conn: conn, q: q} do
      {:ok, _} = Connector.command(conn, ["HSET", Keyspace.queue_key(q, "meta"), "concurrency", "2"])

      # 0 active, ceiling 2 -> below -> :ok
      assert :ok = Metrics.is_maxed(conn, q)

      one = BrandedId.generate!("JOB")
      {:ok, :enqueued} = Jobs.enqueue(conn, q, one, "r")
      {:ok, {^one, _, 1}} = Jobs.claim(conn, q, 60_000)
      # 1 active, ceiling 2 -> still below -> :ok
      assert :ok = Metrics.is_maxed(conn, q)

      two = BrandedId.generate!("JOB")
      {:ok, :enqueued} = Jobs.enqueue(conn, q, two, "r")
      {:ok, {^two, _, 1}} = Jobs.claim(conn, q, 60_000)
      # 2 active, ceiling 2 -> at the ceiling -> {:error, :rate}
      assert {:error, :rate} = Metrics.is_maxed(conn, q)

      # complete one -> back below -> :ok
      :ok = Jobs.complete(conn, q, one, 1)
      assert :ok = Metrics.is_maxed(conn, q)
    end
  end

  # -- lane reads over multiple populated groups ------------------------------

  describe "lane_depth/3 and lane_depths/3 at depth -- many groups, separate backlogs" do
    test "each group reads its own backlog; a batch read answers the whole map", %{conn: conn, q: q} do
      groups = for _ <- 1..4, do: BrandedId.generate!("PRT")
      # group i carries i jobs
      groups
      |> Enum.with_index(1)
      |> Enum.each(fn {g, count} ->
        for _ <- 1..count, do: {:ok, :enqueued} = Lanes.enqueue(conn, q, g, BrandedId.generate!("JOB"), "l")
      end)

      [g1, g2, g3, g4] = groups
      assert {:ok, 1} = Metrics.lane_depth(conn, q, g1)
      assert {:ok, 2} = Metrics.lane_depth(conn, q, g2)
      assert {:ok, 3} = Metrics.lane_depth(conn, q, g3)
      assert {:ok, 4} = Metrics.lane_depth(conn, q, g4)

      assert {:ok, depths} = Metrics.lane_depths(conn, q, groups)
      assert depths == %{g1 => 1, g2 => 2, g3 => 3, g4 => 4}
    end

    test "claiming from one lane drops only its backlog; the others are unmoved", %{conn: conn, q: q} do
      [a, b] = for _ <- 1..2, do: BrandedId.generate!("PRT")
      for _ <- 1..3, do: {:ok, :enqueued} = Lanes.enqueue(conn, q, a, BrandedId.generate!("JOB"), "l")
      for _ <- 1..2, do: {:ok, :enqueued} = Lanes.enqueue(conn, q, b, BrandedId.generate!("JOB"), "l")

      # one rotation claim takes from `a` (the ring head); read both lanes
      {:ok, {_, _, 1, claimed_group}} = Lanes.claim(conn, q, 60_000)
      assert {:ok, depths} = Metrics.lane_depths(conn, q, [a, b])

      # the claimed group dropped by one; the total backlog is 5 - 1 = 4
      assert depths[claimed_group] == if(claimed_group == a, do: 2, else: 1)
      assert depths[a] + depths[b] == 4
    end
  end

  defp purge(q) do
    {:ok, conn} = Connector.start_link(port: 6390)
    {:ok, keys} = Connector.command(conn, ["KEYS", "emq:{" <> q <> "}:*"])
    if keys != [], do: {:ok, _} = Connector.command(conn, ["DEL" | keys])
    GenServer.stop(conn)
  end
end
