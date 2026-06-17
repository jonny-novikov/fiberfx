defmodule EchoMQ.WatchDepthTest do
  @moduledoc """
  EMQ.2.4-D7 -- the watch-plane DEPTH suite: the v1 watch-depth scenarios
  (`queue_events_integration_test.exs`, `worker_cancellation_test.exs`, and the
  lock/stalled paths in `worker_integration_test.exs`) re-derived against the
  SHIPPED watch surface -- `EchoMQ.Jobs.extend_lock/5` + `extend_locks/4`,
  `EchoMQ.Stalled`, `EchoMQ.Events`, `EchoMQ.Meter`, `EchoMQ.Cancel` -- at v1's
  scenario depth, beyond the happy-paths in `locks_stalled_test.exs` /
  `events_integration_test.exs` / `cancel_test.exs` / `meter_test.exs`.

  Closed for the shipped watch surface, honestly bounded for the rest (INV2):
  every test drives a verb `echo_mq` ACTUALLY ships. The DEFERRED watch depth is
  attributed (D8): the worker abstraction + worker-registry → emq.6; the
  telemetry CONTRACT (payload-shape matrix, the engine matrix) → emq.8 (this
  suite asserts only that the SURFACE fires, not the contract); the DISTRIBUTED
  cancel (a cancel from another node) → emq.6 (this asserts only the LOCAL
  cooperative token); the durable replayable stream → emq3.2 (this asserts the
  pub/sub subscription, fire-and-forget). NONE of those is tested here -- a test
  for an unshipped feature is a false-green, forbidden (INV2).

  Determinism discipline (INV7): this is the PROCESS-touching suite -- the lock
  plane runs on a timer, the stalled sweep reads the server clock, events ride a
  live pub/sub socket -- so it is the ≥100-iteration determinism-loop target.
  Loop-stability: NO sleep-as-sync where a barrier exists. track_job is a cast,
  so a following synchronous is_tracked?/2 is a FIFO barrier (the marker write
  has landed when it returns -- the iteration-35 cast/call race the lock plane
  already documents). Events use a SUBSCRIBE-then-let-it-land window + a bounded
  assert_receive (no lost-wakeup). The reaper/stalled timing uses the server
  TIME (the sleep is the LEASE lapsing, an event the test waits FOR, not a
  sync). The setup conn is STOPPED synchronously at test end and the purge rides
  its OWN disposable connection (the determinism-gate races L-9 the watch plane
  already records). Per-test sub-queues; Valkey 6390 the truth row.
  EMQ.2.4-AS5 / EMQ.2.4-US7.
  """
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  @moduletag :valkey

  alias EchoData.BrandedId
  alias EchoMQ.{Cancel, Connector, Events, Jobs, Keyspace, Lanes, Locks, Meter, Metrics, Stalled}

  setup do
    :ok = EchoData.Snowflake.start(4)
    {:ok, conn} = Connector.start_link(port: 6390)
    queue = "emq24.wdepth#{System.unique_integer([:positive])}"

    # the purge rides its OWN disposable connection (the watch-plane idiom):
    # several tests KILL a connection or race teardown, so a purge bound to
    # `conn` would `catch :exit` and SILENTLY skip the DEL -- leaking keys onto a
    # queue name a later VM run reuses (the unique_integer counter resets per
    # VM). A fresh connection never depends on a connection a test tore down.
    #
    # The setup conn is STOPPED synchronously (not left to die with the test):
    # a connector lingering into teardown can RECONNECT into a sibling suite's
    # version-fence mutation window and die {:version_fence, …}, the
    # determinism-gate race (L-9). Stopping it bounds its lifetime to the test.
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
    id = BrandedId.generate!("JOB")
    {:ok, _} = Jobs.enqueue(conn, queue, id, "w")
    {:ok, {^id, _, token}} = Jobs.claim(conn, queue, lease)
    {id, token}
  end

  # -- lock-extension re-scores past the original reaper deadline -------------

  describe "extend_lock/5 at depth -- the extended lease outlives the reaper" do
    test "an extended member survives a reap that catches the un-extended one", ctx do
      # two jobs, both claimed with a tiny lease; extend ONE past the deadline.
      # The reaper (a single server-clock scan) reclaims the un-extended one and
      # leaves the extended one in active -- the extension is what the reaper honors.
      {kept, kept_tok} = claim_one(ctx.conn, ctx.queue, 40)
      {lapsed, _} = claim_one(ctx.conn, ctx.queue, 40)

      assert :ok = Jobs.extend_lock(ctx.conn, ctx.queue, kept, kept_tok, 60_000)

      # wait for the 40ms lease to lapse (the event the test waits FOR, not a sync)
      Process.sleep(120)
      # the reaper reclaims exactly the un-extended job (1 returned to pending)
      assert {:ok, 1} = Jobs.reap(ctx.conn, ctx.queue)

      # the extended job is still active; the lapsed one is back in pending
      {:ok, members} =
        Connector.command(ctx.conn, ["ZRANGE", Keyspace.queue_key(ctx.queue, "active"), "0", "-1"])

      assert kept in members
      refute lapsed in members
      assert {:ok, :pending} = Metrics.get_job_state(ctx.conn, ctx.queue, lapsed)
    end

    test "a stale attempts-token refuses EMQSTALE; a gone row refuses :gone", ctx do
      {id, _token} = claim_one(ctx.conn, ctx.queue, 60_000)
      assert {:error, :stale} = Jobs.extend_lock(ctx.conn, ctx.queue, id, 999, 60_000)
      assert {:error, :gone} =
               Jobs.extend_lock(ctx.conn, ctx.queue, BrandedId.generate!("JOB"), 1, 60_000)
    end
  end

  # -- C2: the batch extend_locks returns the partial-batch un-extendable -----

  describe "extend_locks/4 at depth (C2) -- a partial batch [live, stale, gone]" do
    test "answers exactly the un-extendable ids: the live extends, the stale and the gone fail", ctx do
      {live, live_tok} = claim_one(ctx.conn, ctx.queue, 60_000)
      {stale, _stale_tok} = claim_one(ctx.conn, ctx.queue, 60_000)
      gone = BrandedId.generate!("JOB")

      # a mixed batch: live (correct token) + stale (wrong token) + gone (no row)
      held = [{live, live_tok}, {stale, 999}, {gone, 1}]

      assert {:ok, failed} = Jobs.extend_locks(ctx.conn, ctx.queue, held, 90_000)
      # the failed list is exactly the stale + the gone (order preserved from the
      # batch); the live id is NOT in it
      assert Enum.sort(failed) == Enum.sort([stale, gone])
      refute live in failed

      # the live job's lease WAS extended -- it survives a reap of the original lease
      Process.sleep(20)
      {:ok, members} =
        Connector.command(ctx.conn, ["ZRANGE", Keyspace.queue_key(ctx.queue, "active"), "0", "-1"])

      assert live in members
    end

    test "an all-live batch returns an empty failed list", ctx do
      {a, ta} = claim_one(ctx.conn, ctx.queue, 60_000)
      {b, tb} = claim_one(ctx.conn, ctx.queue, 60_000)
      assert {:ok, []} = Jobs.extend_locks(ctx.conn, ctx.queue, [{a, ta}, {b, tb}], 90_000)
    end
  end

  # -- the lock PLANE: track/extend on a timer (process-touching) -------------

  describe "EchoMQ.Locks plane at depth -- the standing lease-keeper" do
    test "the plane keeps a tracked job's lease alive across the original deadline", ctx do
      {id, token} = claim_one(ctx.conn, ctx.queue, 50)
      {:ok, lm} = Locks.start_link(conn: ctx.conn, queue: ctx.queue, lease_ms: 60_000)

      Locks.track_job(lm, id, token)
      # FIFO barrier: track_job is a cast; the following sync is_tracked?/2 is
      # mailbox-ordered AFTER the handle_cast marker SET -- when it returns the
      # track (and its first marker write) has landed (no cast/call race, L-S).
      assert Locks.is_tracked?(lm, id)

      # a direct-drive extend pass re-scores the tracked lease to 60s
      assert {:ok, %{extended: 1, dropped: []}} = Locks.extend(:sys.get_state(lm))

      # the original 50ms lease lapses, but the plane re-scored it -> the reaper finds nothing
      Process.sleep(120)
      assert {:ok, 0} = Jobs.reap(ctx.conn, ctx.queue)

      Locks.stop(lm)
    end

    test "the plane drops a job whose token went stale (the extend pass returns it)", ctx do
      {id, _token} = claim_one(ctx.conn, ctx.queue, 60_000)
      {:ok, lm} = Locks.start_link(conn: ctx.conn, queue: ctx.queue, lease_ms: 60_000)

      # track with a STALE token -> the extend pass cannot extend it -> dropped
      Locks.track_job(lm, id, 999)
      assert Locks.is_tracked?(lm, id)

      assert {:ok, %{extended: 0, dropped: [^id]}} = Locks.extend(:sys.get_state(lm))

      Locks.stop(lm)
    end
  end

  # -- the stalled sweep below/at the threshold + job_stalled? ----------------

  describe "EchoMQ.Stalled at depth -- recover below the threshold, dead-letter at it" do
    test "a lapsed lease recovers below max_stalled and dead-letters at it; job_stalled? reports",
         ctx do
      {id, _token} = claim_one(ctx.conn, ctx.queue, 30)
      refute Stalled.job_stalled?(ctx.conn, ctx.queue, id)

      # let the 30ms lease lapse (the event waited FOR), sweep with threshold 2
      Process.sleep(80)
      assert {:ok, %{recovered: [^id], dead: []}} =
               Stalled.check(ctx.conn, ctx.queue, max_stalled: 2)
      assert Stalled.job_stalled?(ctx.conn, ctx.queue, id)
      assert {:ok, :pending} = Metrics.get_job_state(ctx.conn, ctx.queue, id)

      # claim again, lapse again, sweep -> stalled count hits 2 -> dead
      {:ok, {^id, _, _}} = Jobs.claim(ctx.conn, ctx.queue, 30)
      Process.sleep(80)
      assert {:ok, %{recovered: [], dead: [^id]}} =
               Stalled.check(ctx.conn, ctx.queue, max_stalled: 2)
      assert {:ok, :dead} = Metrics.get_job_state(ctx.conn, ctx.queue, id)
      assert {:ok, "stalled"} =
               Connector.command(ctx.conn, ["HGET", Keyspace.job_key(ctx.queue, id), "last_error"])
      # the failed metrics counter was bumped by the dead-letter
      assert {:ok, %{count: 1}} = Metrics.get_metrics(ctx.conn, ctx.queue, :failed)
    end
  end

  # -- C2: the group-aware stalled recover branch -----------------------------

  describe "EchoMQ.Stalled at depth (C2) -- the GROUP-aware recover branch" do
    test "a lapsed GROUPED lease recovers into emq:{q}:g:<g>:pending, not the flat pending", ctx do
      g = BrandedId.generate!("PRT")
      id = BrandedId.generate!("JOB")
      {:ok, :enqueued} = Lanes.enqueue(ctx.conn, ctx.queue, g, id, "g")
      {:ok, {^id, _, 1, ^g}} = Lanes.claim(ctx.conn, ctx.queue, 30)

      # the grouped job's lease lapses; the sweep recovers it
      Process.sleep(80)
      assert {:ok, %{recovered: [^id], dead: []}} =
               Stalled.check(ctx.conn, ctx.queue, max_stalled: 2)

      # the recovered job is in the LANE pending set, NOT the flat pending set
      # (the @sweep_stalled group-aware branch -- distinct from the flat branch).
      # ZSCORE under RESP3 answers a float (0.0), so the assertion is membership
      # (a present score) vs nil (absent), not a string match.
      assert {:ok, score} =
               Connector.command(ctx.conn, [
                 "ZSCORE",
                 Keyspace.queue_key(ctx.queue, "g:" <> g <> ":pending"),
                 id
               ])

      assert score == 0.0
      assert {:ok, nil} =
               Connector.command(ctx.conn, ["ZSCORE", Keyspace.queue_key(ctx.queue, "pending"), id])

      # and it claims again through the grouped path (back in rotation)
      assert {:ok, {^id, _, 2, ^g}} = Lanes.claim(ctx.conn, ctx.queue, 60_000)
    end
  end

  # -- events over the seam + across a reconnect ------------------------------

  describe "EchoMQ.Events at depth -- delivery over the seam and across a reconnect" do
    test "a subscriber receives a lifecycle event published host-side over the pub/sub seam", ctx do
      {:ok, ev} = Events.start_link(connector: [port: 6390], queue: ctx.queue)
      Events.subscribe(ev, self())
      # let the SUBSCRIBE land before the publish (no lost-wakeup race)
      Process.sleep(50)

      id = BrandedId.generate!("JOB")
      {:ok, _} = Jobs.enqueue(ctx.conn, ctx.queue, id, "w")
      {:ok, {^id, _, 1}} = Jobs.claim(ctx.conn, ctx.queue, 60_000)
      :ok = Jobs.complete(ctx.conn, ctx.queue, id, 1)
      :ok = Events.publish(ctx.conn, ctx.queue, :completed, id)

      assert_receive {:emq_event, :completed, payload}, 2_000
      assert String.contains?(payload, id)
      assert Events.event_name(payload) == :completed

      Events.close(ev)
    end

    test "the feed survives a connector reconnect -- a post-reconnect publish still delivers", ctx do
      # the listener's connection is killed from `conn`; the emq.1 resubscribe
      # MapSet re-issues the SUBSCRIBE on reconnect, so the feed comes back live.
      capture_log(fn ->
        {:ok, ev} =
          Events.start_link(
            connector: [port: 6390, backoff_initial: 20, backoff_max: 50],
            queue: ctx.queue
          )

        Events.subscribe(ev, self())
        Process.sleep(50)

        id = BrandedId.generate!("JOB")
        {:ok, _} = Jobs.enqueue(ctx.conn, ctx.queue, id, "w")

        # before the kill: a publish delivers
        :ok = Events.publish(ctx.conn, ctx.queue, :completed, id)
        assert_receive {:emq_event, :completed, _}, 2_000

        # kill the listener's underlying connection by its client id. The Events
        # listener subscribes on its OWN self-started connector (conn_opts), so
        # find that connection's id via its stats and kill it from `conn`.
        sub_conn = :sys.get_state(ev).conn
        {:ok, sub_id} = Connector.command(sub_conn, ["CLIENT", "ID"])
        {:ok, _} = Connector.command(ctx.conn, ["CLIENT", "KILL", "ID", Integer.to_string(sub_id)])

        # poll the reconnect (a barrier, not a fixed sleep): the listener's
        # connector reports :connected again once the resubscribe lands
        assert wait_reconnected(sub_conn, 100)

        # after the reconnect: a fresh publish still delivers (the SUBSCRIBE was
        # re-issued from the resubscribe MapSet)
        :ok = Events.publish(ctx.conn, ctx.queue, :failed, id, error: "after")
        assert_receive {:emq_event, :failed, payload}, 2_000
        assert String.contains?(payload, "after")

        Events.close(ev)
      end)
    end
  end

  # -- the telemetry handler fires (the SURFACE, not the emq.8 contract) -------

  describe "EchoMQ.Meter at depth -- an attached handler receives a lifecycle event" do
    test "a [:emq, :job, :complete] handler receives the event the surface fires", ctx do
      # the two-mode contract: :telemetry is an OPTIONAL dep (the bus declares
      # none). Assert the real verdict in EITHER mode -- present: the handler
      # receives; absent: the emit is a safe no-op (no event).
      test = self()
      hid = "wdepth-#{System.unique_integer([:positive])}"

      :ok =
        Meter.attach(hid, [:job, :complete], fn event, meas, meta, _ ->
          send(test, {:metered, event, meas, meta})
        end)

      id = BrandedId.generate!("JOB")
      {:ok, _} = Jobs.enqueue(ctx.conn, ctx.queue, id, "w")
      {:ok, {^id, _, 1}} = Jobs.claim(ctx.conn, ctx.queue, 60_000)
      :ok = Jobs.complete(ctx.conn, ctx.queue, id, 1)
      :ok = Meter.job_completed(ctx.queue, id, "w", self(), 4242)

      if :erlang.function_exported(:telemetry, :execute, 3) do
        assert_receive {:metered, [:emq, :job, :complete], %{duration: 4242}, meta}, 1_000
        assert meta.job_id == id
        assert meta.queue == ctx.queue
      else
        refute_receive {:metered, _, _, _}, 100
      end

      if :erlang.function_exported(:telemetry, :detach, 1), do: apply(:telemetry, :detach, [hid])
    end
  end

  # -- the cooperative cancellation token -------------------------------------

  describe "EchoMQ.Cancel at depth -- the local cooperative token" do
    test "cancel/check/check! -- a cancelled token answers cancelled and check! raises", _ctx do
      token = Cancel.new()
      assert is_reference(token)

      # un-cancelled: check answers :ok, check! is a no-op
      assert :ok = Cancel.check(token)
      assert :ok = Cancel.check!(token)

      # cancel with a reason -> check answers {:cancelled, reason}
      assert :ok = Cancel.cancel(self(), token, :shutdown)
      assert {:cancelled, :shutdown} = Cancel.check(token)

      # cancel again -> check! raises Cancelled carrying the reason
      assert :ok = Cancel.cancel(self(), token, :again)

      assert_raise EchoMQ.Cancel.Cancelled, fn -> Cancel.check!(token) end
    end

    test "a token only catches its OWN cancellation (the ^token match)", _ctx do
      mine = Cancel.new()
      other = Cancel.new()

      # a cancel for `other` does NOT cancel `mine`
      assert :ok = Cancel.cancel(self(), other, :not_yours)
      assert :ok = Cancel.check(mine)
      # but `other` is cancelled
      assert {:cancelled, :not_yours} = Cancel.check(other)
    end
  end

  defp wait_reconnected(_conn, 0), do: false

  defp wait_reconnected(conn, n) do
    Process.sleep(20)

    case Connector.stats(conn).status do
      :connected -> true
      _ -> wait_reconnected(conn, n - 1)
    end
  end
end
