defmodule EchoMQ.ConformanceRunTest do
  @moduledoc """
  The standing gate (EMQ.0-US4, the ratified Q1 stand-in for rung 3_6):
  the seventy-eight-scenario harness drives the public surface against Valkey
  on 6390 and every scenario passes — `run/2 → {:ok, 78}` (the eighteen
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
  isolation through the cadence batch_shaping_partial_failure), and the emq.5.3
  grouped batch's three (the affinity batch grouped_batch_affinity, the
  glimit-headroom ceiling grouped_batch_ceiling, and the fairness interleaving
  witness grouped_batch_fairness), and the emq.5.4 resolve half's three (the
  exhaustive/disjoint partition batch_partition, the dynamic-delay re-score
  batch_delay, and the delay token-fence batch_delay_stale), and -- since EchoMQ
  3.0's Stream Tier opened (emq3.1) -- the stream-verb floor's one (the five
  stream verbs round-trip on the certified connector + a pipelined XADD batch +
  push-safe under RESP3, stream_verbs), and -- the writer law (emq3.2) -- the
  append-order theorem's one (stream_append: EchoMQ.Stream.append mints an
  EVT-branded record id and appends it under its A1 xadd id, N>=2 reads back in
  mint order == id-sort order, a wrong-kind id raises before any wire, and a
  contrived out-of-order append surfaces :nonmonotonic), and -- the reader law
  (emq3.3) -- the consumer group's at-least-once grouped delivery's one
  (stream_group: two branded records group-read with XREADGROUP >, one XACKed
  and one left un-acked, a forced XAUTOCLAIM re-delivers the SAME un-acked
  branded receipt -- a POSITIVE re-delivery proof), and -- retention as policy
  (emq3.4) -- the destructive trim's bounded blast radius's one (stream_retention:
  EchoMQ.Stream.trim/4 bounds a stream to a DECLARED window over XTRIM issued
  direct, proven POSITIVELY over BOTH forms -- in-window entries SURVIVE,
  below-window entries are GONE, the removed-count exact, the MINID floor the
  exact half-open [dt, ∞) edge from Snowflake.min_for/1; a no-op is a LOUD
  failure), and -- the archive (emq3.5) -- the archive seam cache's one
  (stream_archived: the store-side fold consumer caches the archive watermark W
  to emq:{q}:stream:<name>:archived for a polyglot reader, a CACHE never the
  source of truth, proven BUS-PURE -- put/get the EXACT W, a second put
  overwrites, clear_archived DELetes and the seam is :empty again)). Scenarios
  run on per-scenario sub-queues and purge what they mint.
  """
  use ExUnit.Case, async: false

  @moduletag :valkey

  alias EchoMQ.{Conformance, Connector}

  setup_all do
    :ok = EchoData.Snowflake.start(4)
    :ok
  end

  test "the seventy-eight-scenario harness passes whole against the truth row" do
    {:ok, conn} = Connector.start_link(port: 6390)

    on_exit(fn ->
      try do
        GenServer.stop(conn)
      catch
        :exit, _ -> :ok
      end
    end)

    q = "emq0.conf#{System.unique_integer([:positive])}"

    assert Conformance.run(conn, q) == {:ok, 78}
  end
end
