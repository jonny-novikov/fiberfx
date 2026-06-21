defmodule EchoMQ.ConformanceRunTest do
  @moduledoc """
  The standing gate (EMQ.0-US4, the ratified Q1 stand-in for rung 3_6):
  the sixty-seven-scenario harness drives the public surface against Valkey
  on 6390 and every scenario passes — `run/2 → {:ok, 67}` (the eighteen
  state-machine scenarios, the emq.2.1 read plane's six (counts, state,
  metrics, dedup, rate, lane_depth), the emq.2.2 operator plane's eight
  (queue_pause, drain, obliterate, update_data, update_progress, job_logs,
  remove_job, reprocess_job), the emq.2.3 watch plane's five (lock_extend,
  stalled, events, telemetry, cancel), the emq.2.4 parity-closer's five
  depth scenarios (unknown_state, rate_consult, dedup_release,
  extend_locks_batch, stalled_group), the emq.2.2 obliterate fix's
  grouped-row scenario (obliterate_grouped), the emq.3 flow family's three
  single-queue scenarios (flow_add, flow_fanin, flow_children_values),
  the emq.3.3 cross-queue flow scenario (flow_cross_queue), the emq.3.4
  failure-half's three scenarios (flow_fail_parent, flow_ignore_dep,
  flow_add_bulk), the emq.3.5 closer's two recursion scenarios
  (flow_grandchild, flow_grandchild_fail), the emq.4.1 control plane's
  two (the lane re-assignment reassign and the lane-scoped destructive drain
  lane_drain), the emq.4.2 group-aware recovery's one (the group-scoped
  stalled-sweep reap_group), the emq.5.1 batch-claim spine's three
  (the batch claim batch_claim, the under-fill short batch batch_claim_short,
  and partial-failure isolation batch_partial_failure), and the emq.5.2
  batch-shaping cadence's three (the size-floor flush batch_shaping_floor, the
  latency-ceiling flush batch_shaping_timeout, and the partial-failure
  isolation through the cadence batch_shaping_partial_failure)). Scenarios run
  on per-scenario sub-queues and purge what they mint.
  """
  use ExUnit.Case, async: false

  @moduletag :valkey

  alias EchoMQ.{Conformance, Connector}

  setup_all do
    :ok = EchoData.Snowflake.start(4)
    :ok
  end

  test "the sixty-seven-scenario harness passes whole against the truth row" do
    {:ok, conn} = Connector.start_link(port: 6390)

    on_exit(fn ->
      try do
        GenServer.stop(conn)
      catch
        :exit, _ -> :ok
      end
    end)

    q = "emq0.conf#{System.unique_integer([:positive])}"

    assert Conformance.run(conn, q) == {:ok, 67}
  end
end
