defmodule EchoMQ.LocksStalledTest do
  @moduledoc """
  The v1 lock-manager + stalled-checker coverage ADOPTED for the v2
  `EchoMQ.Locks` + `EchoMQ.Stalled` (emq.2.3-D4/D5/D6, the Operator's "tests v1
  adopted and verified"). Re-derived against the v2 surface, NOT the v1
  mechanism:

  - the v1 `extend_lock` test (worker_integration_test.exs:2015,2039) sets a
    `:lock` STRING (`SET lock token PX`) + a `stalled` SET and asserts the
    script answers 1 (extended) / 0 (wrong token). The v2 re-derivation: the
    LEASE is the active-set score, the TOKEN is the row's attempts; so an
    adopted test enqueues+claims (creating the lease + token), calls
    `EchoMQ.Jobs.extend_lock/5`, and asserts `:ok` (the active member re-scored,
    surviving the reaper) on the live token / `{:error, :stale}` on the wrong
    one. The capability ("extend a held lease; refuse on a stale token") is
    identical; the mechanism is the v2 active-score + server `TIME`, never a
    `:lock` string + a caller clock.
  - the worker-side lock plane (`EchoMQ.Locks`) is the v1 `LockManager`
    capability re-derived as an opt-in `:transient` process (track/untrack +
    the read trio + extend-on-a-timer + the `:lock` presence marker with a
    self-healing PX TTL -- L-3/L-4).
  - the stalled recovery (`EchoMQ.Stalled`) is the v1 `StalledChecker` /
    `moveStalledJobsToWait` capability re-derived over the four as-built sets
    under the server `TIME`, recovering below `max_stalled` and dead-lettering
    at it -- never the v1 9-key LIST shape.

  `:valkey`-tagged; the process-touching half (the lock plane + the sweep) is
  the determinism-loop target.
  """
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  @moduletag :valkey

  alias EchoMQ.{Connector, Jobs, Keyspace, Locks, Metrics, Stalled}

  setup do
    :ok = EchoData.Snowflake.start(4)
    {:ok, conn} = Connector.start_link(port: 6390)
    queue = "emq23.lst#{System.unique_integer([:positive])}"

    # the purge rides its OWN disposable connection (the jobs_test/consumer_test
    # idiom): several tests deliberately KILL a plane's connection or race
    # teardown, so a purge bound to `conn` would `catch :exit` and SILENTLY skip
    # the DEL -- leaking keys onto a queue name a later VM run reuses (the
    # unique_integer counter resets per VM), which surfaced as a cross-run flake
    # (a leftover active/dead job claimed by a later test). A fresh connection
    # never depends on a connection a test tore down. (Mars-2 Stage-3 harden.)
    #
    # The setup conn is STOPPED at test end (not just left to die with the test
    # process): a connector that lingers into teardown can RECONNECT into a
    # sibling suite's global-state window -- e.g. connector_test's version-fence
    # mutation -- and die {:version_fence, …}, the determinism-gate race (L-9).
    # Stopping it synchronously bounds its lifetime to the test. (Mars-1 Stage-3.)
    on_exit(fn ->
      stop_conn(conn)
      purge(queue)
    end)

    %{conn: conn, queue: queue}
  end

  defp stop_conn(conn) do
    try do
      GenServer.stop(conn)
    catch
      :exit, _ -> :ok
    end
  end

  defp purge(queue) do
    {:ok, conn} = Connector.start_link(port: 6390)
    {:ok, keys} = Connector.command(conn, ["KEYS", "emq:{" <> queue <> "}:*"])
    if keys != [], do: {:ok, _} = Connector.command(conn, ["DEL" | keys])
    GenServer.stop(conn)
  end

  defp claim_one(conn, queue, lease) do
    id = EchoData.BrandedId.generate!("JOB")
    {:ok, _} = Jobs.enqueue(conn, queue, id, "w")
    {:ok, {^id, _, token}} = Jobs.claim(conn, queue, lease)
    {id, token}
  end

  # -- the lock-extension verb (the v1 extend_lock capability, re-derived) ----

  describe "extend_lock/5 (the v1 extend_lock script, re-derived to the active-score lease)" do
    test "extends a held lease with the live token (re-scores the active member)", ctx do
      {id, token} = claim_one(ctx.conn, ctx.queue, 50)

      assert :ok = Jobs.extend_lock(ctx.conn, ctx.queue, id, token, 60_000)

      # the v1 test asserted result == 1; the v2 verdict is the active member
      # re-scored past the original deadline so the reaper does not reclaim it
      Process.sleep(120)
      assert {:ok, 0} = Jobs.reap(ctx.conn, ctx.queue)

      {:ok, members} =
        Connector.command(ctx.conn, ["ZRANGE", Keyspace.queue_key(ctx.queue, "active"), "0", "-1"])

      assert id in members
    end

    test "fails with the wrong token (the v1 result == 0, re-derived to EMQSTALE)", ctx do
      {id, _token} = claim_one(ctx.conn, ctx.queue, 60_000)

      # the v1 test used a wrong lock-string token -> 0; the v2 verdict is the
      # attempts-token fence -> EMQSTALE -> {:error, :stale}
      assert {:error, :stale} = Jobs.extend_lock(ctx.conn, ctx.queue, id, 999, 60_000)
    end

    test "a gone job answers {:error, :gone}", ctx do
      gone = EchoData.BrandedId.generate!("JOB")
      assert {:error, :gone} = Jobs.extend_lock(ctx.conn, ctx.queue, gone, 1, 60_000)
    end
  end

  describe "extend_locks/4 (the v1 extendLocks capability, re-derived)" do
    test "answers the ids whose lease could not be extended", ctx do
      {id1, t1} = claim_one(ctx.conn, ctx.queue, 60_000)
      {id2, _t2} = claim_one(ctx.conn, ctx.queue, 60_000)

      # id1 has the live token; id2 is given a stale token -> only id2 fails
      assert {:ok, failed} = Jobs.extend_locks(ctx.conn, ctx.queue, [{id1, t1}, {id2, 999}], 90_000)
      assert failed == [id2]
    end
  end

  # -- the worker-side lock plane (the v1 LockManager capability, re-derived) --

  describe "EchoMQ.Locks (the v1 LockManager surface, re-derived)" do
    test "track/untrack + the read trio answer the tracked set", ctx do
      {id, token} = claim_one(ctx.conn, ctx.queue, 60_000)
      {:ok, lm} = Locks.start_link(conn: ctx.conn, queue: ctx.queue)

      assert Locks.get_active_job_count(lm) == 0
      refute Locks.is_tracked?(lm, id)

      Locks.track_job(lm, id, token)
      Process.sleep(20)

      assert Locks.get_active_job_count(lm) == 1
      assert Locks.is_tracked?(lm, id)
      assert Locks.get_tracked_job_ids(lm) == [id]

      Locks.untrack_job(lm, id)
      Process.sleep(20)
      assert Locks.get_active_job_count(lm) == 0
      refute Locks.is_tracked?(lm, id)

      Locks.stop(lm)
    end

    test "the plane extends a tracked job's lease (a direct-drive beat)", ctx do
      {id, token} = claim_one(ctx.conn, ctx.queue, 50)
      {:ok, lm} = Locks.start_link(conn: ctx.conn, queue: ctx.queue, lease_ms: 60_000)
      Locks.track_job(lm, id, token)
      Process.sleep(20)

      assert {:ok, %{extended: 1, dropped: []}} = Locks.extend(:sys.get_state(lm))

      Process.sleep(120)
      assert {:ok, 0} = Jobs.reap(ctx.conn, ctx.queue)

      Locks.stop(lm)
    end

    test "track_job writes the :lock marker so remove_job refuses EMQLOCK; untrack releases it", ctx do
      {id, token} = claim_one(ctx.conn, ctx.queue, 60_000)
      {:ok, lm} = Locks.start_link(conn: ctx.conn, queue: ctx.queue)
      Locks.track_job(lm, id, token)
      Process.sleep(20)

      assert {:error, :locked} = Jobs.remove_job(ctx.conn, ctx.queue, id)

      Locks.untrack_job(lm, id)
      Process.sleep(20)
      assert :ok = Jobs.remove_job(ctx.conn, ctx.queue, id)

      Locks.stop(lm)
    end

    test "a consumer without the plane is the unchanged v2 worker (no :lock marker)", ctx do
      {id, _token} = claim_one(ctx.conn, ctx.queue, 60_000)
      # no Locks process started -> no marker -> remove_job is not blocked
      marker = Keyspace.job_key(ctx.queue, id) <> ":lock"
      assert {:ok, nil} = Connector.command(ctx.conn, ["GET", marker])
      assert :ok = Jobs.remove_job(ctx.conn, ctx.queue, id)
    end
  end

  # -- L-3/L-4: the :lock marker self-healing (the crash-recovery drill) ------

  describe "the :lock marker self-heals on a worker crash (L-3/L-4)" do
    test "a crashed worker's marker self-expires; remove_job no longer wrongly refuses EMQLOCK", ctx do
      Process.flag(:trap_exit, true)
      {id, token} = claim_one(ctx.conn, ctx.queue, 40)
      marker = Keyspace.job_key(ctx.queue, id) <> ":lock"

      # the deliberate owner-kill tears down a LINKED self-started connector,
      # which logs a GenServer-terminating line -- captured so the suite output
      # stays clean (the kill is the test's own simulated crash, not a fault).
      capture_log(fn ->
        # the plane runs in an isolated owner; killing the owner kills the LINKED
        # plane (the beat stops) -- a real worker crash. lease 100, marker 200.
        parent = self()

        {owner, _ref} =
          spawn_monitor(fn ->
            {:ok, lm} =
              Locks.start_link(
                conn: ctx.conn,
                queue: ctx.queue,
                lease_ms: 100,
                marker_multiple: 2
              )

            Locks.track_job(lm, id, token)
            # a FIFO barrier: track_job is a GenServer.cast, so a following
            # synchronous call (is_tracked?/2) is mailbox-ordered AFTER the
            # handle_cast({:track_job,…}) marker SET -- when it returns the
            # marker write has completed, so the parent's PTTL read below cannot
            # race the async track (the iteration-35 cast/call race -- Mars-1 S4).
            _ = Locks.is_tracked?(lm, id)
            send(parent, :tracked)
            Process.sleep(:infinity)
          end)

        assert_receive :tracked, 2_000
        Process.sleep(30)

        assert {:ok, ttl} = Connector.command(ctx.conn, ["PTTL", marker])
        assert ttl > 0 and ttl <= 200
        assert {:error, :locked} = Jobs.remove_job(ctx.conn, ctx.queue, id)

        # crash: kill the owner -> the linked plane dies -> the beat stops
        Process.exit(owner, :kill)
        assert_receive {:DOWN, _, :process, ^owner, _}, 1_000

        # the marker's last PX lapses with no refresh; the lease (40ms) lapsed too
        Process.sleep(260)
        assert {:ok, nil} = Connector.command(ctx.conn, ["GET", marker])
        assert {:ok, -2} = Connector.command(ctx.conn, ["PTTL", marker])
      end)

      {:ok, _} = Jobs.reap(ctx.conn, ctx.queue)
      assert :ok = Jobs.remove_job(ctx.conn, ctx.queue, id)
    end
  end

  # -- the stalled recovery (the v1 StalledChecker capability, re-derived) ----

  describe "EchoMQ.Stalled (the v1 StalledChecker / moveStalledJobsToWait, re-derived)" do
    test "a lapsed lease is recovered below the threshold and dead-lettered at it", ctx do
      {id, _token} = claim_one(ctx.conn, ctx.queue, 30)

      refute Stalled.job_stalled?(ctx.conn, ctx.queue, id)

      Process.sleep(80)
      assert {:ok, %{recovered: [^id], dead: []}} = Stalled.check(ctx.conn, ctx.queue, max_stalled: 2)
      assert Stalled.job_stalled?(ctx.conn, ctx.queue, id)
      assert {:ok, :pending} = Metrics.get_job_state(ctx.conn, ctx.queue, id)

      # claim again, let it lapse, sweep -> stalled count hits the threshold -> dead
      {:ok, {^id, _, _}} = Jobs.claim(ctx.conn, ctx.queue, 30)
      Process.sleep(80)
      assert {:ok, %{recovered: [], dead: [^id]}} = Stalled.check(ctx.conn, ctx.queue, max_stalled: 2)
      assert {:ok, :dead} = Metrics.get_job_state(ctx.conn, ctx.queue, id)

      assert {:ok, "stalled"} =
               Connector.command(ctx.conn, ["HGET", Keyspace.job_key(ctx.queue, id), "last_error"])
    end

    test "the sweep reads the server TIME (a job whose lease has NOT lapsed is not swept)", ctx do
      {id, _token} = claim_one(ctx.conn, ctx.queue, 60_000)

      # the lease is far in the future -> the sweep finds nothing
      assert {:ok, %{recovered: [], dead: []}} = Stalled.check(ctx.conn, ctx.queue)
      refute Stalled.job_stalled?(ctx.conn, ctx.queue, id)
    end

    test "job_stalled?/4 answers absent for a missing job", ctx do
      missing = EchoData.BrandedId.generate!("JOB")
      refute Stalled.job_stalled?(ctx.conn, ctx.queue, missing)
    end

    test "beyond the dead-lease reaper, not a replacement: reap recovers once, the sweep counts", ctx do
      {id, _token} = claim_one(ctx.conn, ctx.queue, 30)
      Process.sleep(80)

      # reap (the as-built single scan) recovers the lapsed lease with NO count
      assert {:ok, 1} = Jobs.reap(ctx.conn, ctx.queue)
      refute Stalled.job_stalled?(ctx.conn, ctx.queue, id)
      assert {:ok, :pending} = Metrics.get_job_state(ctx.conn, ctx.queue, id)
    end
  end
end
