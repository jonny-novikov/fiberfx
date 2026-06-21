defmodule EchoMQ.ConformanceScenariosTest do
  @moduledoc """
  The pure half of the Conformance row (echo2-migration.md §5): the
  scenario registry pinned — seventy-four names in run order (the eighteen
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
  (batch_claim, batch_claim_short, batch_partial_failure), and the emq.5.2
  batch-shaping cadence's three (batch_shaping_floor, batch_shaping_timeout,
  batch_shaping_partial_failure), the emq.5.3 grouped batch's three (the
  affinity batch grouped_batch_affinity, the glimit-headroom ceiling
  grouped_batch_ceiling, and the fairness interleaving witness
  grouped_batch_fairness), and the emq.5.4 resolve half's three (the
  exhaustive/disjoint partition batch_partition, the dynamic-delay re-score
  batch_delay, and the delay token-fence batch_delay_stale), and -- since EchoMQ
  3.0's Stream Tier opened (emq3.1) -- the stream-verb floor's one (the five
  stream verbs round-trip on the certified connector + a pipelined XADD batch +
  push-safe under RESP3, stream_verbs)). The wire half (`run/2 → {:ok, 74}`)
  lives in `conformance_run_test.exs` behind the `:valkey` tag.
  """
  use ExUnit.Case, async: true

  alias EchoMQ.Conformance

  @run_order [
    :fence,
    :mint,
    :duplicate,
    :kind,
    :order,
    :claim,
    :stale,
    :complete,
    :retry,
    :dead,
    :reap,
    :rotate,
    :pause,
    :limit,
    :schedule,
    :repeat,
    :backoff,
    :resubscribe,
    :counts,
    :state,
    :metrics,
    :dedup,
    :rate,
    :lane_depth,
    :queue_pause,
    :drain,
    :obliterate,
    :update_data,
    :update_progress,
    :job_logs,
    :remove_job,
    :reprocess_job,
    :lock_extend,
    :stalled,
    :events,
    :telemetry,
    :cancel,
    :unknown_state,
    :rate_consult,
    :dedup_release,
    :extend_locks_batch,
    :stalled_group,
    :obliterate_grouped,
    :reassign,
    :lane_drain,
    :reap_group,
    :flow_add,
    :flow_fanin,
    :flow_children_values,
    :flow_cross_queue,
    :flow_fail_parent,
    :flow_ignore_dep,
    :flow_add_bulk,
    :flow_grandchild,
    :flow_grandchild_fail,
    :pool_enqueue,
    :pool_order,
    :native_lock_field,
    :native_lock_refuses,
    :weighted_proportion,
    :starvation_drill,
    :batch_claim,
    :batch_claim_short,
    :batch_partial_failure,
    :batch_shaping_floor,
    :batch_shaping_timeout,
    :batch_shaping_partial_failure,
    :grouped_batch_affinity,
    :grouped_batch_ceiling,
    :grouped_batch_fairness,
    :batch_partition,
    :batch_delay,
    :batch_delay_stale,
    :stream_verbs
  ]

  test "scenarios/0 answers exactly the seventy-four names in run order" do
    assert Keyword.keys(Conformance.scenarios()) == @run_order
  end

  test "every scenario carries a one-line contract" do
    assert Enum.all?(Conformance.scenarios(), fn {_name, contract} ->
             is_binary(contract) and contract != ""
           end)
  end
end
