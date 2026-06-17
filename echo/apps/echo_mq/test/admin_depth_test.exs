defmodule EchoMQ.AdminDepthTest do
  @moduledoc """
  EMQ.2.4-D6 -- the operator-plane DEPTH suite: the v1 operator-depth scenarios
  (`obliterate_test.exs` + the lifecycle paths in `queue_integration_test.exs`)
  re-derived against the SHIPPED `EchoMQ.Admin` + the `EchoMQ.Jobs` mutation
  verbs, at v1's scenario depth -- populated multi-set queues with active jobs
  and the precondition refusals fired, beyond the single happy-path each verb
  shipped with in `admin_test.exs` / `jobs_ops_test.exs`.

  Closed for the shipped operator surface, honestly bounded for the rest
  (INV2): every test drives a verb `echo_mq` ACTUALLY ships -- `pause/2`,
  `resume/2`, `drain/3`, `obliterate/3`, `update_data/4`, `update_progress/4`,
  `add_log/5`, `get_job_logs/3`, `remove_job/4`, `reprocess_job/3`. The read
  plane (`EchoMQ.Metrics`) is the acceptance lens. No transition is rewritten
  (INV3) -- the v2 state machine is emq.1/emq.2.2's, tested at depth here, not
  changed.

  The typed refusals are each exercised: `EMQSTATE not paused` (obliterate on a
  live queue) / `EMQSTATE active` (obliterate with live active jobs) /
  `EMQSTATE not dead` (reprocess a non-dead job) / `EMQLOCK` (remove a locked
  job) / typed `:gone` (a mutation on a missing job). Per-test sub-queues;
  Valkey 6390 the truth row. EMQ.2.4-AS4 / EMQ.2.4-US6.
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
    q = "emq24.adepth#{System.unique_integer([:positive])}"
    on_exit(fn -> purge(q) end)
    %{conn: conn, q: q}
  end

  # -- pause gates BOTH the flat and the grouped claim ------------------------

  describe "pause/2 at depth -- it gates both claim paths and the backlogs survive" do
    test "a non-empty pending AND live groups: pause gates flat Jobs.claim AND grouped Lanes.claim",
         %{conn: conn, q: q} do
      flat = BrandedId.generate!("JOB")
      {:ok, :enqueued} = Jobs.enqueue(conn, q, flat, "f")
      g = BrandedId.generate!("PRT")
      grouped = BrandedId.generate!("JOB")
      {:ok, :enqueued} = Lanes.enqueue(conn, q, g, grouped, "g")

      assert :ok = Admin.pause(conn, q)

      # BOTH paths answer empty under the queue-wide pause
      assert :empty = Jobs.claim(conn, q, 60_000)
      assert :empty = Lanes.claim(conn, q, 60_000)

      # both backlogs are intact -- the per-group paused SET was NOT touched
      assert {:ok, %{"pending" => 1}} = Metrics.get_counts(conn, q, ["pending"])
      assert {:ok, 1} = Lanes.depth(conn, q, g)
      assert {:ok, 0} = Connector.command(conn, ["SISMEMBER", Keyspace.queue_key(q, "paused"), g])

      # resume restores BOTH
      assert :ok = Admin.resume(conn, q)
      assert {:ok, {^flat, "f", 1}} = Jobs.claim(conn, q, 60_000)
      assert {:ok, {^grouped, "g", 1, ^g}} = Lanes.claim(conn, q, 60_000)
    end
  end

  # -- drain spares active + the repeat registry ------------------------------

  describe "drain/3 at depth -- a populated pending(+schedule), active survives, repeat survives" do
    test "drain empties pending, leaves active in flight, and the repeat registry keeps minting",
         %{conn: conn, q: q} do
      # mint the to-be-active FIRST (claim is ZPOPMIN), then the to-stay pending
      live = BrandedId.generate!("JOB")
      {:ok, :enqueued} = Jobs.enqueue(conn, q, live, "active")
      {:ok, {^live, _, 1}} = Jobs.claim(conn, q, 60_000)

      waiting = for _ <- 1..4, do: BrandedId.generate!("JOB")
      Enum.each(waiting, fn id -> {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "w") end)
      sched = BrandedId.generate!("JOB")
      {:ok, :scheduled} = Jobs.enqueue_in(conn, q, sched, "s", 60_000)
      {:ok, :registered} = Repeat.register(conn, q, "nightly", 60_000, "tick", 60_000)

      # drain with the schedule included
      assert {:ok, 5} = Admin.drain(conn, q, include_schedule: true)

      assert {:ok, %{"pending" => 0, "schedule" => 0, "active" => 1}} =
               Metrics.get_counts(conn, q, ["pending", "schedule", "active"])
      # the in-flight job survives
      assert {:ok, :active} = Metrics.get_job_state(conn, q, live)
      # the repeat registry survives the drain (D-4) -- the registration is still
      # counted, so a future occurrence still mints (registered next_ms 60s out,
      # so it is not yet DUE -- the registry's survival is the assertion, not a
      # premature occurrence).
      assert {:ok, 1} = Repeat.count(conn, q)
      assert {:ok, []} = Repeat.due(conn, q, 10)
    end
  end

  # -- obliterate at depth: every set + auxiliary keys + the refusals ---------

  describe "obliterate/3 at depth -- a fully-populated paused queue, the refusals fired" do
    test "clears every FLAT set + every §6 auxiliary key on a paused queue (no lane jobs)",
         %{conn: conn, q: q} do
      # build pending + dead + schedule + a repeat record + the metrics counters
      # (NO lane job -- see the [FINDING] test below for the grouped-row case),
      # then pause and obliterate the lot.
      d = BrandedId.generate!("JOB")
      {:ok, :enqueued} = Jobs.enqueue(conn, q, d, "w")
      {:ok, {^d, _, 1}} = Jobs.claim(conn, q, 60_000)
      {:ok, :dead} = Jobs.retry(conn, q, d, 1, 10, 1, "x")

      done = BrandedId.generate!("JOB")
      {:ok, :enqueued} = Jobs.enqueue(conn, q, done, "w")
      {:ok, {^done, _, 1}} = Jobs.claim(conn, q, 60_000)
      :ok = Jobs.complete(conn, q, done, 1)

      for _ <- 1..2, do: {:ok, :enqueued} = Jobs.enqueue(conn, q, BrandedId.generate!("JOB"), "w")
      {:ok, :scheduled} = Jobs.enqueue_in(conn, q, BrandedId.generate!("JOB"), "s", 60_000)
      {:ok, :registered} = Repeat.register(conn, q, "rep", 60_000, "tick", 60_000)

      # the metrics counter is populated (1 completed)
      assert {:ok, %{count: 1}} = Metrics.get_metrics(conn, q, :completed)

      assert :ok = Admin.pause(conn, q)
      assert :ok = Admin.obliterate(conn, q)

      # every flat set is empty AND the whole keyspace footprint is gone (meta,
      # the metrics hashes, the repeat records -- the §6 keys)
      assert {:ok, %{"pending" => 0, "active" => 0, "schedule" => 0, "dead" => 0}} =
               Metrics.get_counts(conn, q, ["pending", "active", "schedule", "dead"])
      assert {:ok, []} = Connector.command(conn, ["KEYS", "emq:{" <> q <> "}:*"])
    end

    test "obliterate clears the lane g:<g>:pending SET AND del_job's the grouped JOB ROWS (emq.2.2 fix)",
         %{conn: conn, q: q} do
      # The emq.2.2-D4 spec says obliterate destroys "the lane structures ... +
      # each g:<g>:pending ... and every reachable job row + its :logs/:lock
      # subkeys" (docs/echo_mq/specs/emq.2.2.md:178-180). The original as-built
      # @obliterate del_job'd only the FOUR FLAT sets (active/pending/schedule/
      # dead); for the OPEN lane family it DELed each `g:<g>:pending` SET but did
      # NOT iterate its members to del their rows, so a grouped-but-unclaimed job
      # (enqueued via Lanes.enqueue/5, never claimed) leaked its row
      # `emq:{q}:job:<id>`. The emq.2.2 fix (admin.ex) del_job's each lane
      # member before DELing the lane ZSET, under the same budget bound (the row
      # key derives from the declared base root -- slot-sound, A-1-clean).
      #
      # This was the @tag :finding test asserting the as-built LEAK; D-5 ruled
      # the fix in this ship, so it now asserts the FIXED behavior: the lane SET
      # clears AND the grouped row is gone. Two lanes so the per-lane drain runs
      # more than once; a logs subkey to prove the whole row footprint clears.
      g1 = BrandedId.generate!("PRT")
      g2 = BrandedId.generate!("PRT")
      grouped1 = BrandedId.generate!("JOB")
      grouped2 = BrandedId.generate!("JOB")
      {:ok, :enqueued} = Lanes.enqueue(conn, q, g1, grouped1, "l1")
      {:ok, :enqueued} = Lanes.enqueue(conn, q, g2, grouped2, "l2")
      {:ok, _} = Connector.command(conn, ["RPUSH", Keyspace.job_key(q, grouped1) <> ":logs", "x"])

      assert :ok = Admin.pause(conn, q)
      assert :ok = Admin.obliterate(conn, q)

      # both lane pending SETs are cleared...
      assert {:ok, 0} = Lanes.depth(conn, q, g1)
      assert {:ok, 0} = Lanes.depth(conn, q, g2)
      # ...AND the grouped job ROWS are gone (no leak), logs subkey too, and the
      # whole keyspace footprint is clear.
      assert {:ok, 0} = Connector.command(conn, ["EXISTS", Keyspace.job_key(q, grouped1)])
      assert {:ok, 0} = Connector.command(conn, ["EXISTS", Keyspace.job_key(q, grouped2)])
      assert {:ok, 0} = Connector.command(conn, ["EXISTS", Keyspace.job_key(q, grouped1) <> ":logs"])
      assert {:ok, []} = Connector.command(conn, ["KEYS", "emq:{" <> q <> "}:*"])
    end

    test "the grouped-row obliterate is bounded: a small budget answers :more then :ok", %{
      conn: conn,
      q: q
    } do
      # several grouped jobs across lanes with a budget smaller than the total,
      # so the per-lane drain must span multiple bounded calls (the :more path
      # through the lane loop, not just the flat-set loops).
      g = BrandedId.generate!("PRT")
      ids = for _ <- 1..5, do: BrandedId.generate!("JOB")
      Enum.each(ids, fn id -> {:ok, :enqueued} = Lanes.enqueue(conn, q, g, id, "l") end)
      assert :ok = Admin.pause(conn, q)

      assert :more = Admin.obliterate(conn, q, budget: 2)
      assert :ok = drain_obliterate(conn, q, 2)

      assert {:ok, 0} = Lanes.depth(conn, q, g)
      for id <- ids, do: assert({:ok, 0} = Connector.command(conn, ["EXISTS", Keyspace.job_key(q, id)]))
      assert {:ok, []} = Connector.command(conn, ["KEYS", "emq:{" <> q <> "}:*"])
    end

    test "refuses a NON-paused queue (:not_paused) changing nothing", %{conn: conn, q: q} do
      id = BrandedId.generate!("JOB")
      {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "w")

      assert {:error, :not_paused} = Admin.obliterate(conn, q)
      # nothing changed
      assert {:ok, %{"pending" => 1}} = Metrics.get_counts(conn, q, ["pending"])
      assert {:ok, :pending} = Metrics.get_job_state(conn, q, id)
    end

    test "refuses a paused queue with live active jobs (:active) unless forced", %{conn: conn, q: q} do
      id = BrandedId.generate!("JOB")
      {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "w")
      {:ok, {^id, _, 1}} = Jobs.claim(conn, q, 60_000)
      assert :ok = Admin.pause(conn, q)

      # unforced: the live active job blocks it, nothing changes
      assert {:error, :active} = Admin.obliterate(conn, q)
      assert {:ok, %{"active" => 1}} = Metrics.get_counts(conn, q, ["active"])

      # forced: destroys the queue including the active job
      assert :ok = Admin.obliterate(conn, q, force: true)
      assert {:ok, []} = Connector.command(conn, ["KEYS", "emq:{" <> q <> "}:*"])
    end

    test "is bounded per call: a small budget answers :more then :ok across many jobs", %{
      conn: conn,
      q: q
    } do
      ids = for _ <- 1..7, do: BrandedId.generate!("JOB")
      Enum.each(ids, fn id -> {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "w") end)
      assert :ok = Admin.pause(conn, q)

      # budget 3 cannot finish in one call
      assert :more = Admin.obliterate(conn, q, budget: 3)
      assert :ok = drain_obliterate(conn, q, 3)
      assert {:ok, []} = Connector.command(conn, ["KEYS", "emq:{" <> q <> "}:*"])
    end
  end

  # -- the job mutations on in-flight jobs + the typed-absent -----------------

  describe "update_data/4, update_progress/4, add_log/5 at depth" do
    test "update_data rewrites an in-flight (claimed) job's payload; a missing job is typed :gone",
         %{conn: conn, q: q} do
      id = BrandedId.generate!("JOB")
      {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "old")
      {:ok, {^id, _, 1}} = Jobs.claim(conn, q, 60_000)

      assert :ok = Jobs.update_data(conn, q, id, "new")
      assert {:ok, %{"payload" => "new", "state" => "active"}} = Metrics.get_job(conn, q, id)
      assert {:error, :gone} = Jobs.update_data(conn, q, BrandedId.generate!("JOB"), "x")
    end

    test "update_progress writes the row field and a missing job is typed :gone", %{conn: conn, q: q} do
      id = BrandedId.generate!("JOB")
      {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "w")
      {:ok, {^id, _, 1}} = Jobs.claim(conn, q, 60_000)

      assert :ok = Jobs.update_progress(conn, q, id, "75")
      assert {:ok, "75"} = Connector.command(conn, ["HGET", Keyspace.job_key(q, id), "progress"])
      assert {:error, :gone} = Jobs.update_progress(conn, q, BrandedId.generate!("JOB"), "1")
    end

    test "add_log appends with keep-N trim and get_job_logs reads in order; missing is :gone", %{
      conn: conn,
      q: q
    } do
      id = BrandedId.generate!("JOB")
      {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "w")

      assert {:ok, 1} = Jobs.add_log(conn, q, id, "line-1")
      assert {:ok, 2} = Jobs.add_log(conn, q, id, "line-2")
      assert {:ok, 3} = Jobs.add_log(conn, q, id, "line-3")
      assert {:ok, ["line-1", "line-2", "line-3"]} = Jobs.get_job_logs(conn, q, id)

      # keep-2 trims to the last two
      assert {:ok, 2} = Jobs.add_log(conn, q, id, "line-4", 2)
      assert {:ok, ["line-3", "line-4"]} = Jobs.get_job_logs(conn, q, id)

      missing = BrandedId.generate!("JOB")
      assert {:error, :gone} = Jobs.add_log(conn, q, missing, "x")
      assert {:error, :gone} = Jobs.get_job_logs(conn, q, missing)
    end
  end

  # -- remove_job across the four sets + EMQLOCK + the dedup release -----------

  describe "remove_job/4 at depth -- clears from each set, refuses a locked job, releases dedup" do
    test "removes a pending, an active, a scheduled, and a dead job (each set)", %{conn: conn, q: q} do
      # one job in each of the four sets (mint the to-be-active/dead FIRST)
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

      for id <- [pending, active, sched, dead] do
        assert :ok = Jobs.remove_job(conn, q, id)
        assert {:ok, :absent} = Metrics.get_job_state(conn, q, id)
      end

      assert {:ok, %{"pending" => 0, "active" => 0, "schedule" => 0, "dead" => 0}} =
               Metrics.get_counts(conn, q, ["pending", "active", "schedule", "dead"])
    end

    test "refuses a locked job EMQLOCK untouched, then removes it once the marker clears", %{
      conn: conn,
      q: q
    } do
      id = BrandedId.generate!("JOB")
      {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "w")
      # a :lock marker present (the worker-side lock plane writes this on track_job)
      {:ok, _} = Connector.command(conn, ["SET", Keyspace.job_key(q, id) <> ":lock", "worker-1"])

      assert {:error, :locked} = Jobs.remove_job(conn, q, id)
      # the job is untouched
      assert {:ok, :pending} = Metrics.get_job_state(conn, q, id)

      # clear the marker -> remove succeeds
      {:ok, _} = Connector.command(conn, ["DEL", Keyspace.job_key(q, id) <> ":lock"])
      assert :ok = Jobs.remove_job(conn, q, id)
      assert {:ok, :absent} = Metrics.get_job_state(conn, q, id)
    end

    test "releases the caller-supplied dedup key and answers :gone for a missing job", %{
      conn: conn,
      q: q
    } do
      did = "dedup-depth"
      id = BrandedId.generate!("JOB")
      {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "w")
      {:ok, _} = Connector.command(conn, ["SET", Keyspace.queue_key(q, "de:" <> did), id])

      assert :ok = Jobs.remove_job(conn, q, id, did)
      assert :absent = Metrics.get_deduplication_job_id(conn, q, did)
      assert {:error, :gone} = Jobs.remove_job(conn, q, BrandedId.generate!("JOB"))
    end
  end

  # -- reprocess_job dead->pending + EMQSTATE ---------------------------------

  describe "reprocess_job/3 at depth" do
    test "moves a dead job to pending (clearing last_error) and refuses a non-dead job EMQSTATE",
         %{conn: conn, q: q} do
      dead = BrandedId.generate!("JOB")
      {:ok, :enqueued} = Jobs.enqueue(conn, q, dead, "w")
      {:ok, {^dead, _, 1}} = Jobs.claim(conn, q, 60_000)
      {:ok, :dead} = Jobs.retry(conn, q, dead, 1, 10, 1, "gave up")

      live = BrandedId.generate!("JOB")
      {:ok, :enqueued} = Jobs.enqueue(conn, q, live, "w")

      assert :ok = Jobs.reprocess_job(conn, q, dead)
      assert {:ok, :pending} = Metrics.get_job_state(conn, q, dead)
      assert {:ok, %{"state" => "pending"}} = Metrics.get_job(conn, q, dead)
      assert {:ok, nil} = Connector.command(conn, ["HGET", Keyspace.job_key(q, dead), "last_error"])

      # a live (pending) job is not reprocessable
      assert {:error, :not_dead} = Jobs.reprocess_job(conn, q, live)
      assert {:ok, :pending} = Metrics.get_job_state(conn, q, live)

      # a reprocessed dead job is claimable again (re-entered the pending set)
      assert {:ok, {^dead, "w", 2}} = Jobs.claim(conn, q, 60_000)
    end
  end

  defp drain_obliterate(conn, q, budget) do
    case Admin.obliterate(conn, q, budget: budget) do
      :more -> drain_obliterate(conn, q, budget)
      :ok -> :ok
    end
  end

  defp purge(q) do
    {:ok, conn} = Connector.start_link(port: 6390)
    {:ok, keys} = Connector.command(conn, ["KEYS", "emq:{" <> q <> "}:*"])
    if keys != [], do: {:ok, _} = Connector.command(conn, ["DEL" | keys])
    GenServer.stop(conn)
  end
end
