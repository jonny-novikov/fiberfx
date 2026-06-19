defmodule EchoMQ.MetronomeTest do
  @moduledoc """
  The metronome-as-system, proven on a live Valkey (emq.4.3, MECH-(ii)). A
  `:valkey` PROCESS suite: the metronome (`EchoMQ.Metronome`) is the SINGLE
  blocker on `emq:{q}:wake` per queue, fanning readiness out to a pool of
  registered-idle `EchoMQ.Consumer`s over BEAM messages -- one byte-frozen
  `EchoMQ.Lanes.claim/3` (`@gclaim`) per idle consumer per wake. The proof the
  conformance suite lacks: a BEAM process/lease property, not a wire trace
  (D-5).

  Four stories, each assertion DEFEATING a no-op:
  - US1 serve WELL BEFORE the beat (a long beat, the job handled in well under
    it -- defeats a poll-on-the-beat design).
  - US2 lost-wakeup at the registration boundary (the metronome holds the block
    continuously, not a transitioning consumer) + crash-mid-claim (the killed
    consumer's lease lapses, the metronome's per-beat `Jobs.reap/2` redelivers).
  - US3 multi-consumer fairness (N registered, a stream of admits, every
    consumer serves a share, none starves -- defeats a poke-one-to-exhaustive-
    drain). THE LOAD-BEARING PROOF.
  - US4 the registration/drain contract (kill a registered consumer → the
    metronome survives and serves on; `stop/2` → clean deregister, no leaked
    claim).

  Modeled on `EchoMQ.ConsumerTest`'s harness: `Connector.start_link(port: 6390)`,
  a per-test unique queue, an `on_exit` purge over `KEYS emq:{q}:*`, `wait_until/2`
  (5ms poll), `EchoData.Snowflake.start(4)` in `setup_all`, branded `JOB`/`PRT`
  ids. The handler attributes work to a consumer by sending `{:handled, self(),
  job_id}` to the test pid (the consumer is the process running the handler).
  """
  use ExUnit.Case, async: false

  @moduletag :valkey

  alias EchoData.BrandedId
  alias EchoMQ.{Connector, Consumer, Keyspace, Lanes, Metronome, Queue}

  setup_all do
    :ok = EchoData.Snowflake.start(4)
    :ok
  end

  setup do
    {:ok, conn} = Connector.start_link(port: 6390)
    q = "emq0.metronome#{System.unique_integer([:positive])}"

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

  # poll at 5ms, modeled on consumer_test.exs (tries default 1000 = 5s budget,
  # the suite's slowest beat is 2s so 5s comfortably covers a fallback round)
  defp wait_until(pred, tries \\ 1_000) do
    cond do
      pred.() -> :ok
      tries == 0 -> flunk("condition never held")
      true ->
        Process.sleep(5)
        wait_until(pred, tries - 1)
    end
  end

  # the job row is gone once @complete settled it
  defp completed?(conn, q, id) do
    {:ok, n} = Connector.command(conn, ["EXISTS", Keyspace.job_key(q, id)])
    n == 0
  end

  # ---- US1 -- served WELL BEFORE the beat ---------------------------------

  test "a job admitted to a registered-idle pool is served WELL BEFORE the beat",
       %{conn: conn, q: q} do
    parent = self()
    group = BrandedId.generate!("PRT")
    id = BrandedId.generate!("JOB")

    handler = fn job ->
      send(parent, {:handled, self(), job.id})
      :ok
    end

    # a deliberately LONG beat (2s): a poll-on-the-beat design could only serve
    # on a beat boundary, so it would take up to ~2s; the metronome unblocks on
    # the admit's LPUSH wake and pokes immediately.
    {:ok, pool} =
      Queue.start_link(
        queue: q,
        handler: handler,
        size: 2,
        connector: [port: 6390],
        beat_ms: 2_000,
        lease_ms: 5_000,
        name: pool_name()
      )

    # stop the pool at the test's end so its metronome/consumers (and their
    # connectors) do not linger and contend with later tests on the shared
    # Valkey instance -- the orphaned-blocker contention that turns a prompt
    # serve into a tight-budget timeout (deterministic teardown, not a wider
    # timeout).
    on_exit(fn -> stop_pool(pool) end)

    # WARM-UP: establish the US1 precondition deterministically -- "a consumer
    # REGISTERED-IDLE". The metronome processes a consumer's {:register_idle}
    # only at the top of its loop (drain_mailbox), so a fresh pool's FIRST block
    # may begin before the registrations are drained into the registry; the
    # first admit is then only guaranteed within a beat, not well-before it.
    # Driving one throwaway job to completion proves the registry is live and the
    # consumers have re-registered idle (the rest state US1 measures from) --
    # without reaching into the metronome's private state. (A poll-on-the-beat
    # design also serves this warm-up job, so the warm-up itself defeats no
    # no-op; the TIMED admit below is the no-op defeater.)
    warm = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Lanes.enqueue(conn, q, group, warm, "warmup")
    assert_receive {:handled, _c, ^warm}, 3_000
    wait_until(fn -> completed?(conn, q, warm) end)
    # let the serving consumer re-register idle after the warm-up settle
    Process.sleep(50)

    t0 = System.monotonic_time(:millisecond)
    {:ok, :enqueued} = Lanes.enqueue(conn, q, group, id, "cargo")

    assert_receive {:handled, _consumer, ^id}, 1_500
    elapsed = System.monotonic_time(:millisecond) - t0

    # THE NO-OP DEFEATER: with a consumer already registered-idle (the warm-up
    # established the rest state), the job is served in well under a full beat.
    # A poll-on-the-beat consumer (serve only when the 2_000ms block returns)
    # cannot meet this -- it would take up to ~2000ms.
    assert elapsed < 600,
           "served in #{elapsed}ms; a poll-on-the-beat design would take up to ~2000ms"

    # the row is settled and the consumer re-registers idle (rest state)
    wait_until(fn -> completed?(conn, q, id) end)
  end

  # ---- US2 -- lost-wakeup at the registration boundary + crash-mid-claim ---

  test "no wake is lost across the registration boundary, run repeatedly",
       %{conn: conn, q: q} do
    parent = self()
    group = BrandedId.generate!("PRT")

    handler = fn job ->
      send(parent, {:handled, self(), job.id})
      :ok
    end

    # ONE consumer so that after each claim it transitions back to register-idle
    # -- the exact lost-wakeup window. A short beat (100ms) means a lost wakeup
    # would still be caught by the fallback within the beat, so we assert WITHIN
    # the beat (the US2 contract: "still served within the beat"), and admit each
    # job timed to land around the consumer's re-registration boundary.
    {:ok, pool} =
      Queue.start_link(
        queue: q,
        handler: handler,
        size: 1,
        connector: [port: 6390],
        beat_ms: 100,
        lease_ms: 5_000,
        name: pool_name()
      )

    on_exit(fn -> stop_pool(pool) end)

    Process.sleep(150)

    # admit a stream, each job racing the prior job's completion → re-register
    # transition. Every job must be served (none hung): the metronome holds the
    # block continuously regardless of the single consumer's registration state.
    ids =
      for _ <- 1..30 do
        id = BrandedId.generate!("JOB")
        {:ok, :enqueued} = Lanes.enqueue(conn, q, group, id, "boundary")
        # land the next admit right around the re-registration boundary
        Process.sleep(3)
        id
      end

    # every admitted job is served (the window closes by construction). Generous
    # 5s budget; the property under test is "served at all, never hung".
    for id <- ids do
      assert_receive {:handled, _consumer, ^id}, 5_000
    end

    wait_until(fn -> Enum.all?(ids, &completed?(conn, q, &1)) end)
  end

  test "a consumer crashing mid-claim does not lose the job (reaped + redelivered)",
       %{conn: conn, q: q} do
    parent = self()
    group = BrandedId.generate!("PRT")
    id = BrandedId.generate!("JOB")

    # the metronome with a fast beat so its per-beat Jobs.reap runs often; a
    # SHORT lease (200ms) so a crashed consumer's claim lapses quickly and the
    # reap returns it to its lane (re-rung), where the metronome serves it next.
    {:ok, metro} =
      Metronome.start_link(
        queue: q,
        name: metro_name(),
        connector: [port: 6390],
        beat_ms: 50
      )

    # the ONLY consumer at first, so it is unambiguously the one poked for the
    # first job: it claims, signals the test, then CRASHES inside the handler (a
    # genuine process death mid-claim -- not a caught raise; an uncaught :kill
    # exit kills the spawn_link'd loop). It dies holding the server-clock lease.
    crasher_handler = fn job ->
      send(parent, {:claimed_then_crash, self(), job.id})
      Process.exit(self(), :kill)
      :ok
    end

    # unlinked: the crasher kills ITSELF mid-handler (Process.exit(self, :kill)),
    # which would propagate :killed across the spawn_link to the test process.
    {:ok, crasher} =
      unlinked_consumer(
        queue: q,
        handler: crasher_handler,
        metronome: metro,
        connector: [port: 6390],
        lease_ms: 200
      )

    Process.sleep(100)

    {:ok, :enqueued} = Lanes.enqueue(conn, q, group, id, "fragile")

    # the lone crasher claims it, then dies holding the lease
    assert_receive {:claimed_then_crash, ^crasher, ^id}, 3_000
    wait_until(fn -> not Process.alive?(crasher) end)

    # the metronome monitor-detected the dead consumer and removed its
    # registration -- but the CLAIM still sits in the active set under the
    # lapsing 200ms lease. NO-OP DEFEATER part 1: the job is NOT gone (a design
    # that dropped the claim with the dead consumer would have deleted the row).
    refute completed?(conn, q, id), "the job row must persist while the lapsed lease awaits reap"

    # now a healthy consumer joins; the crasher's lease lapses (200ms), the
    # metronome's per-beat Jobs.reap (beat 50ms) returns the member to its lane
    # (re-rung), and the healthy consumer is poked and serves it.
    healthy_handler = fn job ->
      send(parent, {:handled, self(), job.id})
      :ok
    end

    {:ok, healthy} =
      Consumer.start_link(
        queue: q,
        handler: healthy_handler,
        metronome: metro,
        connector: [port: 6390],
        lease_ms: 5_000
      )

    on_exit(fn -> stop_all([metro, crasher, healthy]) end)

    # NO-OP DEFEATER part 2: the reaped job is redelivered and completed by the
    # healthy consumer. A design that leaked the claim with the dead consumer
    # would never satisfy this -- the job would hang in the active set forever.
    assert_receive {:handled, ^healthy, ^id}, 5_000
    wait_until(fn -> completed?(conn, q, id) end)

    # and the active set is drained -- no leaked claim survives the reap+complete
    {:ok, active} = Connector.command(conn, ["ZCARD", Keyspace.queue_key(q, "active")])
    assert active == 0, "no claim must leak after reap+complete; active ZCARD=#{active}"

    assert :ok = Metronome.stop(metro)
  end

  # ---- US3 -- multi-consumer fairness (THE LOAD-BEARING PROOF) -------------

  test "N registered consumers each serve a fair share of a stream (none starves)",
       %{conn: conn, q: q} do
    parent = self()
    n = 4
    m = 40

    handler = fn job ->
      send(parent, {:handled, self(), job.id})
      :ok
    end

    {:ok, pool} =
      Queue.start_link(
        queue: q,
        handler: handler,
        size: n,
        connector: [port: 6390],
        beat_ms: 100,
        lease_ms: 5_000,
        name: pool_name()
      )

    on_exit(fn -> stop_pool(pool) end)

    Process.sleep(200)

    # a stream of M admits across n lanes (one lane per consumer's natural
    # rotation: the ring rotates LMOVE so successive lanes serve, and the
    # metronome hands one claim per idle consumer per wake). M >> n so every
    # consumer has ample opportunity to serve.
    groups = for _ <- 1..n, do: BrandedId.generate!("PRT")

    ids =
      for i <- 1..m do
        group = Enum.at(groups, rem(i, n))
        id = BrandedId.generate!("JOB")
        {:ok, :enqueued} = Lanes.enqueue(conn, q, group, id, "stream")
        id
      end

    # collect which consumer handled each job
    by_consumer = collect_handled(ids, %{})

    # all M served
    handled_ids = by_consumer |> Map.values() |> List.flatten()
    assert length(handled_ids) == m, "expected #{m} jobs served, got #{length(handled_ids)}"
    assert Enum.sort(handled_ids) == Enum.sort(ids), "served set must equal admitted set"

    counts = Enum.map(Map.values(by_consumer), &length/1)
    serving_consumers = map_size(by_consumer)

    # NO-OP DEFEATER (no-starvation): EVERY one of the N consumers serves at
    # least one job. A poke-one-to-exhaustive-drain would let a single consumer
    # handle all M while the other N-1 starve (serving_consumers would be 1).
    assert serving_consumers == n,
           "expected all #{n} consumers to serve; only #{serving_consumers} did " <>
             "(a poke-one-to-exhaustive-drain starves the rest). counts=#{inspect(counts)}"

    assert Enum.min(counts) >= 1, "every consumer must handle >= 1 job; counts=#{inspect(counts)}"

    # the spread is bounded: with one-claim-per-idle-consumer-per-wake fairness,
    # no consumer hogs the stream. max <= min + the whole stream would be the
    # trivial bound; assert a real band -- max is well under M (no single drainer)
    # and the spread is bounded by a generous multiple of the fair share (M/n=10).
    fair_share = div(m, n)

    assert Enum.max(counts) <= fair_share * 3,
           "max share #{Enum.max(counts)} exceeds 3x the fair share (#{fair_share}); " <>
             "fairness band breached. counts=#{inspect(counts)}"

    wait_until(fn -> Enum.all?(ids, &completed?(conn, q, &1)) end)
  end

  # ---- US4 -- the registration/drain contract -----------------------------

  test "killing a registered consumer leaves the metronome serving on the rest",
       %{conn: conn, q: q} do
    parent = self()
    group = BrandedId.generate!("PRT")

    handler = fn job ->
      send(parent, {:handled, self(), job.id})
      :ok
    end

    {:ok, metro} =
      Metronome.start_link(
        queue: q,
        name: metro_name(),
        connector: [port: 6390],
        beat_ms: 100
      )

    # unlinked: the test kills the victim with Process.exit(victim, :kill), which
    # would propagate :killed across the spawn_link to the test process.
    {:ok, victim} =
      unlinked_consumer(
        queue: q,
        handler: handler,
        metronome: metro,
        connector: [port: 6390],
        lease_ms: 5_000
      )

    {:ok, survivor} =
      Consumer.start_link(
        queue: q,
        handler: handler,
        metronome: metro,
        connector: [port: 6390],
        lease_ms: 5_000
      )

    on_exit(fn -> stop_all([metro, victim, survivor]) end)

    Process.sleep(150)

    # kill a registered-idle consumer; the metronome monitor-detects the :DOWN
    # and removes the registration -- it does NOT crash, and it must keep serving.
    Process.exit(victim, :kill)
    wait_until(fn -> not Process.alive?(victim) end)

    # NO-OP DEFEATER: the metronome survives the consumer death (a design where
    # the registry holds a stale pid and pokes it, or where the death takes the
    # metronome down, would hang here). The survivor serves new work.
    assert Process.alive?(metro), "the metronome must survive a registered consumer's death"
    assert Process.alive?(survivor)

    id = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Lanes.enqueue(conn, q, group, id, "after-death")

    assert_receive {:handled, served_by, ^id}, 3_000
    assert served_by == survivor, "the surviving consumer must serve the post-death job"

    wait_until(fn -> completed?(conn, q, id) end)
    assert :ok = Metronome.stop(metro)
  end

  test "stop/2 deregisters a registered consumer cleanly with no leaked claim",
       %{conn: conn, q: q} do
    parent = self()
    group = BrandedId.generate!("PRT")

    handler = fn job ->
      send(parent, {:handled, self(), job.id})
      :ok
    end

    {:ok, metro} =
      Metronome.start_link(
        queue: q,
        name: metro_name(),
        connector: [port: 6390],
        beat_ms: 100
      )

    {:ok, leaving} =
      Consumer.start_link(
        queue: q,
        handler: handler,
        metronome: metro,
        connector: [port: 6390],
        lease_ms: 5_000
      )

    {:ok, staying} =
      Consumer.start_link(
        queue: q,
        handler: handler,
        metronome: metro,
        connector: [port: 6390],
        lease_ms: 5_000
      )

    on_exit(fn -> stop_all([metro, leaving, staying]) end)

    Process.sleep(150)

    # stop a registered-idle consumer (the unsupervised owner's verb): it
    # deregisters at its settle point and exits :normal -- nothing is in hand,
    # so no claim leaks.
    ref = Process.monitor(leaving)
    assert :ok = Consumer.stop(leaving)
    assert_receive {:DOWN, ^ref, :process, ^leaving, :normal}, 2_000
    refute Process.alive?(leaving)

    # NO-OP DEFEATER: after the clean stop, the metronome continues to serve on
    # the staying consumer with no orphaned registration of the gone pid. New
    # work is served by the survivor (the stopped pid is never poked again --
    # if it were, the poke would target a dead pid and the job could hang).
    assert Process.alive?(metro)

    id = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Lanes.enqueue(conn, q, group, id, "after-stop")

    assert_receive {:handled, served_by, ^id}, 3_000
    assert served_by == staying, "the staying consumer must serve the post-stop job"

    wait_until(fn -> completed?(conn, q, id) end)

    # confirm no in-flight lease leaked: the active set is empty (the stopped
    # consumer was idle, nothing claimed; the served job completed). A leaked
    # claim would leave a member in the active ZSET.
    {:ok, active} =
      Connector.command(conn, ["ZCARD", Keyspace.queue_key(q, "active")])

    assert active == 0, "no claim must leak; active set ZCARD=#{active}"

    assert :ok = Metronome.stop(metro)
  end

  # ---- F-2 -- the metronome name registers SYNCHRONOUSLY ------------------

  test "the metronome name resolves to its pid the instant start_link returns",
       %{q: q} do
    # F-2 NO-OP DEFEATER: a `:name`d metronome must have its name registered
    # BEFORE start_link returns {:ok, pid}, so a `EchoMQ.Queue` (rest_for_one)
    # consumer started next -- whose first act is `send(name, {:register_idle,
    # _})` -- never sends to an unregistered atom (`send/2` to a dead name
    # RAISES). Registering INSIDE the spawn_link'd fn (the pre-fix form) left a
    # window where `Process.whereis(name)` was still nil on return; registering
    # from the PARENT on the returned pid closes it by construction. Asserted
    # WITHOUT a sleep -- a single delay would mask the race -- and over many
    # fresh starts so a flake cannot hide behind one lucky schedule.
    for _ <- 1..50 do
      name = metro_name()

      {:ok, pid} =
        Metronome.start_link(
          queue: q,
          name: name,
          connector: [port: 6390],
          beat_ms: 1_000
        )

      # synchronous: no Process.sleep between the return and the lookup
      assert Process.whereis(name) == pid,
             "the metronome name must be live the instant start_link returns (F-2)"

      assert :ok = Metronome.stop(pid)
      # let the name free before the next fresh start reuses the registry
      wait_until(fn -> Process.whereis(name) == nil end)
    end
  end

  # ---- helpers ------------------------------------------------------------

  # collect the {:handled, consumer_pid, id} messages for the given ids,
  # accumulating per-consumer id lists. Returns when every id is accounted for
  # (or fails the receive timeout, surfacing a hung/lost job).
  defp collect_handled([], acc), do: acc

  defp collect_handled(pending_ids, acc) do
    receive do
      {:handled, consumer, id} ->
        acc = Map.update(acc, consumer, [id], fn ids -> [id | ids] end)
        collect_handled(List.delete(pending_ids, id), acc)
    after
      10_000 ->
        flunk(
          "jobs hung/lost; #{length(pending_ids)} unhandled after 10s: #{inspect(pending_ids)}"
        )
    end
  end

  # Start a consumer UNLINKED from the test process. `EchoMQ.Consumer.start_link`
  # uses `spawn_link`, so the loop is linked to its caller -- in production a
  # supervisor (which traps exits), but here the ExUnit test process (which does
  # not). A `Process.exit(pid, :kill)` is untrappable and would propagate the
  # `:killed` EXIT across that link and abort the test. Unlinking severs ONLY the
  # test↔consumer harness link; the PRODUCTION safety net under test -- the
  # metronome's `Process.monitor/1` of the consumer -- is unaffected (a monitor
  # is not a link), so this proves the real `:DOWN`-detection path, not a harness
  # artifact.
  defp unlinked_consumer(opts) do
    {:ok, pid} = Consumer.start_link(opts)
    Process.unlink(pid)
    {:ok, pid}
  end

  # Stop a `Queue` pool supervisor (and with it the metronome + consumers + their
  # connectors) at a test's end -- deterministic teardown so orphaned blockers
  # never contend with later tests on the shared Valkey-6390 instance. Idempotent:
  # a pool already down (the test stopped it) is a no-op.
  defp stop_pool(pid) do
    if Process.alive?(pid), do: Supervisor.stop(pid, :normal, 2_000)
  catch
    :exit, _ -> :ok
  end

  # Stop a list of standalone processes (a metronome + its consumers) at a test's
  # end, same teardown discipline. A dead pid is skipped.
  defp stop_all(pids) do
    Enum.each(pids, fn pid ->
      if is_pid(pid) and Process.alive?(pid), do: Process.exit(pid, :shutdown)
    end)
  end

  # unique registered names per test (a Queue registers its supervisor + a
  # metronome by name; a standalone Metronome registers by name) so concurrent
  # leftovers from a prior test never collide. async: false, but unique anyway.
  defp pool_name, do: :"emq_pool_#{System.unique_integer([:positive])}"
  defp metro_name, do: :"emq_metro_#{System.unique_integer([:positive])}"
end
