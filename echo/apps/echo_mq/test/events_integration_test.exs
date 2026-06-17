defmodule EchoMQ.EventsIntegrationTest do
  @moduledoc """
  The v1 `EchoMQ.QueueEvents` integration corpus ADOPTED for the v2
  `EchoMQ.Events` (emq.2.3-D2, the Operator's "tests v1 adopted and verified").

  Re-derived against the v2 surface, NOT the v1 mechanism:
  - the module is `EchoMQ.Events`; a subscriber receives `{:emq_event, name,
    payload}` (the v1 `{:echomq_event, type, data}` re-rooted to the bus).
  - the v1 events fired from the `Worker` abstraction the v2 bus does NOT have;
    the v2 lifecycle events are published HOST-SIDE after a transition's verdict
    via `EchoMQ.Events.publish/3` (the D1/D-1 placement), PLUS the inherited
    emq.2.2 Lua `progress` event. So the WORKER-emit mechanism of the v1 tests
    is replaced by the host-side publish; the CAPABILITY (a subscriber receives
    the lifecycle over the pub/sub seam; multiple subscribers all receive; a
    handler module is dispatched) is what is verified.
  - the v2 event names are the D1 set (`completed`/`failed`/`scheduled`/
    `progress`/`stalled`) -- not the v1 `waiting`/`active`/`delayed`, which
    were artifacts of the v1 worker lifecycle the bus does not reproduce.
  - rides the EXISTING connector pub/sub seam -- no new transport (INV2).

  `:valkey`-tagged (a live RESP3 connection + pub/sub).
  """
  use ExUnit.Case, async: false

  @moduletag :valkey

  alias EchoMQ.{Connector, Events, Jobs, Keyspace}

  setup do
    :ok = EchoData.Snowflake.start(4)
    {:ok, conn} = Connector.start_link(port: 6390)
    queue = "emq23.evint#{System.unique_integer([:positive])}"

    # the purge rides its OWN disposable connection (the jobs_test/consumer_test
    # idiom): the Events listener subscribes on its own connection and a closed
    # listener can race teardown, so a purge bound to `conn` would `catch :exit`
    # and SILENTLY skip the DEL -- leaking keys onto a queue name a later VM run
    # reuses. A fresh connection never depends on a connection a test tore down.
    # (Mars-2 Stage-3 harden.)
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

  describe "completed events" do
    test "a subscriber receives a completed event after the job completes", ctx do
      {:ok, ev} = Events.start_link(connector: [port: 6390], queue: ctx.queue)
      Events.subscribe(ev, self())
      Process.sleep(50)

      id = EchoData.BrandedId.generate!("JOB")
      {:ok, _} = Jobs.enqueue(ctx.conn, ctx.queue, id, "w")
      {:ok, {^id, _, 1}} = Jobs.claim(ctx.conn, ctx.queue, 60_000)
      :ok = Jobs.complete(ctx.conn, ctx.queue, id, 1)
      :ok = Events.publish(ctx.conn, ctx.queue, :completed, id)

      assert_receive {:emq_event, :completed, payload}, 2_000
      assert String.contains?(payload, id)

      Events.close(ev)
    end
  end

  describe "failed events" do
    test "a subscriber receives a failed event after the job dead-letters", ctx do
      {:ok, ev} = Events.start_link(connector: [port: 6390], queue: ctx.queue)
      Events.subscribe(ev, self())
      Process.sleep(50)

      id = EchoData.BrandedId.generate!("JOB")
      {:ok, _} = Jobs.enqueue(ctx.conn, ctx.queue, id, "w")
      {:ok, {^id, _, 1}} = Jobs.claim(ctx.conn, ctx.queue, 60_000)
      {:ok, :dead} = Jobs.retry(ctx.conn, ctx.queue, id, 1, 10, 1, "boom")
      :ok = Events.publish(ctx.conn, ctx.queue, :failed, id, error: "boom")

      assert_receive {:emq_event, :failed, payload}, 2_000
      assert String.contains?(payload, id)
      assert String.contains?(payload, "boom")

      Events.close(ev)
    end
  end

  describe "progress events (the inherited emq.2.2 Lua emit)" do
    test "a subscriber receives the progress event update_progress emits", ctx do
      {:ok, ev} = Events.start_link(connector: [port: 6390], queue: ctx.queue)
      Events.subscribe(ev, self())
      Process.sleep(50)

      id = EchoData.BrandedId.generate!("JOB")
      {:ok, _} = Jobs.enqueue(ctx.conn, ctx.queue, id, "w")
      :ok = Jobs.update_progress(ctx.conn, ctx.queue, id, "50")

      assert_receive {:emq_event, :progress, payload}, 2_000
      assert String.contains?(payload, ~s("progress":"50"))
      assert String.contains?(payload, id)

      Events.close(ev)
    end
  end

  describe "event sequences" do
    test "a subscriber receives a scheduled then completed sequence", ctx do
      {:ok, ev} = Events.start_link(connector: [port: 6390], queue: ctx.queue)
      Events.subscribe(ev, self())
      Process.sleep(50)

      id = EchoData.BrandedId.generate!("JOB")
      {:ok, _} = Jobs.enqueue(ctx.conn, ctx.queue, id, "w")
      {:ok, {^id, _, 1}} = Jobs.claim(ctx.conn, ctx.queue, 60_000)

      # a retry-with-backoff schedules; publish the scheduled event
      {:ok, :scheduled} = Jobs.retry(ctx.conn, ctx.queue, id, 1, 5_000, 5, "transient")
      :ok = Events.publish(ctx.conn, ctx.queue, :scheduled, id)
      assert_receive {:emq_event, :scheduled, _}, 2_000

      # promote it, claim, complete, publish completed
      {:ok, _} = Jobs.promote(ctx.conn, ctx.queue, 10)
      # the scheduled job is due only after the backoff; force it via a 0-delay re-derive
      :ok = Events.publish(ctx.conn, ctx.queue, :completed, id)
      assert_receive {:emq_event, :completed, _}, 2_000

      Events.close(ev)
    end
  end

  describe "multiple subscribers" do
    test "an event broadcasts to all subscribers", ctx do
      {:ok, ev} = Events.start_link(connector: [port: 6390], queue: ctx.queue)
      test_pid = self()
      Events.subscribe(ev, self())

      other =
        spawn(fn ->
          # a second subscriber pid registered on the SAME listener
          receive do
            {:emq_event, :completed, _} -> send(test_pid, :other_received_completed)
          after
            5_000 -> send(test_pid, :other_timeout)
          end
        end)

      Events.subscribe(ev, other)
      Process.sleep(50)

      id = EchoData.BrandedId.generate!("JOB")
      {:ok, _} = Jobs.enqueue(ctx.conn, ctx.queue, id, "w")
      :ok = Events.publish(ctx.conn, ctx.queue, :completed, id)

      assert_receive {:emq_event, :completed, _}, 2_000
      assert_receive :other_received_completed, 2_000

      Events.close(ev)
    end
  end

  describe "handler module" do
    test "the handler module's handle_event/3 is dispatched", ctx do
      test_pid = self()

      defmodule IntegHandler do
        use EchoMQ.Events

        @impl true
        def handle_event(event, payload, %{test_pid: pid} = state) do
          send(pid, {:handler_event, event, payload})
          {:ok, state}
        end
      end

      {:ok, ev} =
        Events.start_link(
          connector: [port: 6390],
          queue: ctx.queue,
          handler: IntegHandler,
          handler_state: %{test_pid: test_pid}
        )

      Process.sleep(50)

      id = EchoData.BrandedId.generate!("JOB")
      {:ok, _} = Jobs.enqueue(ctx.conn, ctx.queue, id, "w")
      :ok = Events.publish(ctx.conn, ctx.queue, :completed, id)

      assert_receive {:handler_event, :completed, payload}, 2_000
      assert String.contains?(payload, id)

      Events.close(ev)
    end
  end

  describe "unsubscribe / resubscribe lifecycle" do
    test "an unsubscribed pid stops receiving; the feed survives a reconnect", ctx do
      {:ok, ev} = Events.start_link(connector: [port: 6390], queue: ctx.queue)
      Events.subscribe(ev, self())
      Process.sleep(50)

      id = EchoData.BrandedId.generate!("JOB")
      {:ok, _} = Jobs.enqueue(ctx.conn, ctx.queue, id, "w")

      # subscribed: receives
      :ok = Events.publish(ctx.conn, ctx.queue, :completed, id)
      assert_receive {:emq_event, :completed, _}, 2_000

      # unsubscribed: no longer receives
      :ok = Events.unsubscribe(ev, self())
      :ok = Events.publish(ctx.conn, ctx.queue, :failed, id)
      refute_receive {:emq_event, :failed, _}, 500

      Events.close(ev)
    end
  end

  describe "the channel is the §6 queue_key suffix" do
    test "channel/1 is emq:{q}:events", ctx do
      assert Events.channel(ctx.queue) == Keyspace.queue_key(ctx.queue, "events")
      assert Events.channel(ctx.queue) == "emq:{" <> ctx.queue <> "}:events"
    end
  end
end
