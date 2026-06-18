# EchoMQ commands — v1→v3 (new format)

> 52 legacy Lua v1 commands reformatted into the per-command v1→v3 shape (see [FORMAT.md](FORMAT.md)). One `.md` per command, grouped by the 12-feature taxonomy. `addStandardJob-9` was delivered last turn at the deeper two-Lua-source + diff tier.

**NO-INVENT:** v1 sources are embedded verbatim; v3 schematics are never fabricated — proposed/unbuilt rungs carry the repo's own withholding.

**Status tally:** BUILDING 1 · NOT YET 7 · PARTIAL 12 · PROPOSED 1 · RETIRED 2 · SHIPPED 29 · **52 total**

## admission

| Command | Status | v3 home |
|---|---|---|
| [`addStandardJob-9`](admission/addStandardJob-9.md) *(deep-dive tier, prior turn)* | SHIPPED (ported) | EchoMQ.Jobs.enqueue/4 (@enqueue, jobs.ex) |

## batches

| Command | Status | v3 home |
|---|---|---|
| [`add_bulk`](batches/add_bulk.md) | SHIPPED (ported) | EchoMQ.Flows.add_bulk/3 (flows.ex) + EchoMQ.Jobs.enqueue_many/3 |
| [`moveJobsToWait-8`](batches/moveJobsToWait-8.md) | PARTIAL | single-job EchoMQ.Jobs.reprocess_job/3 (jobs.ex) + EchoMQ.Jobs.promote/3 (jobs.ex) exist; a bulk requeue_set(state, count) is PROPOSED |

## claim

| Command | Status | v3 home |
|---|---|---|
| [`moveToActive-11`](claim/moveToActive-11.md) | SHIPPED (ported) | EchoMQ.Jobs.claim/4 (@claim, jobs.ex) + grouped EchoMQ.Lanes.claim/3 (@gclaim, lanes.ex) |
| [`moveJobFromActiveToWait-9`](claim/moveJobFromActiveToWait-9.md) | PARTIAL (partial) | recovery EchoMQ.Jobs.reap/2 (@reap, jobs.ex) + Stalled.check/3; a token-fenced voluntary requeue is PROPOSED |
| [`moveStalledJobsToWait-8`](claim/moveStalledJobsToWait-8.md) | SHIPPED (ported) | EchoMQ.Stalled.check/3 (@sweep_stalled) |

## data

| Command | Status | v3 home |
|---|---|---|
| [`updateData-1`](data/updateData-1.md) | SHIPPED (ported) | EchoMQ.Jobs.update_data/4 (@update_data, jobs.ex) |
| [`updateProgress-3`](data/updateProgress-3.md) | SHIPPED (ported) | EchoMQ.Jobs.update_progress/4 (@update_progress, jobs.ex; the v2 form is a PUBLISH emq:{q}:events, NOT an XADD — D-5/D-6) |
| [`addLog-2`](data/addLog-2.md) | SHIPPED (ported) | EchoMQ.Jobs.add_log/5 + get_job_logs/3 (@add_log, jobs.ex) |
| [`saveStacktrace-1`](data/saveStacktrace-1.md) | NOT YET (folded) | today the failure record is a single last_error field set by @retry's dead-letter arm (jobs.ex); a dedicated @save_stacktrace is PROPOSED |

## flows

| Command | Status | v3 home |
|---|---|---|
| [`addParentJob-6`](flows/addParentJob-6.md) | SHIPPED (ported) | EchoMQ.Flows.add/3 + add_bulk/3 (@enqueue_flow/@hold_parent/@enqueue_flow_child, flows.ex) |
| [`moveToFinished-14`](flows/moveToFinished-14.md) | SHIPPED (ported) | EchoMQ.Jobs.complete/5 (@complete, jobs.ex) |
| [`moveToWaitingChildren-7`](flows/moveToWaitingChildren-7.md) | PARTIAL | fan-in in Flows/@complete; explicit await_children/… PROPOSED |
| [`getDependencyCounts-4`](flows/getDependencyCounts-4.md) | PARTIAL (split, not aggregated) | EchoMQ.Flows.dependencies/3 (flows.ex) + children_values/3/ignored_failures/3; aggregate child_counts/3 PROPOSED |
| [`grandchildren-recursive-flow-tree`](flows/grandchildren-recursive-flow-tree.md) | BUILDING (`[RECONCILE]`) | recursive add/3 over the byte-frozen @enqueue_flow/@hold_parent/@enqueue_flow_child/@complete |

## groups

| Command | Status | v3 home |
|---|---|---|
| [`addPrioritizedJob-9`](groups/addPrioritizedJob-9.md) | SHIPPED (ported, re-aimed) | EchoMQ.Lanes.enqueue/5 (@genqueue, lanes.ex), no prioritized set (D-9) |
| [`changePriority-7`](groups/changePriority-7.md) | RETIRED (capability retired by design, §6) | no priority re-score; Lanes group re-assignment / weighted rotation (emq.4) |
| [`getCountsPerPriority-4`](groups/getCountsPerPriority-4.md) | RETIRED (retired by design) | re-derived as per-lane depth EchoMQ.Metrics.lane_depths/3 (also metrics: per-lane / per-player backlog the consuming app reads) |

## lifecycle

| Command | Status | v3 home |
|---|---|---|
| [`removeJob-2`](lifecycle/removeJob-2.md) | SHIPPED (ported) | EchoMQ.Jobs.remove_job/4 (@remove_job, jobs.ex; refuses locked EMQLOCK, -1→:gone) |
| [`removeChildDependency-1`](lifecycle/removeChildDependency-1.md) | NOT YET (as a named verb) | — |
| [`removeDeduplicationKey-1`](lifecycle/removeDeduplicationKey-1.md) | PARTIAL (folded) | folded into @remove_job's de: branch (jobs.ex); standalone release_dedup/3 PROPOSED |
| [`removeUnprocessedChildren-2`](lifecycle/removeUnprocessedChildren-2.md) | NOT YET | — |
| [`cleanJobsInSet-3`](lifecycle/cleanJobsInSet-3.md) | PARTIAL | Admin.drain/3 is predicate-free today; Admin.clean/4 (server-clock age grace + limit) PROPOSED. (also batches) |
| [`drain-5`](lifecycle/drain-5.md) | SHIPPED (ported) | EchoMQ.Admin.drain/3 (@drain, admin.ex) |
| [`obliterate-2`](lifecycle/obliterate-2.md) | SHIPPED (ported) | EchoMQ.Admin.obliterate/3 (@obliterate, admin.ex) |
| [`pause-7`](lifecycle/pause-7.md) | SHIPPED (ported) | EchoMQ.Admin.pause/2 + resume/2 (@pause/@resume, admin.ex; a paused FIELD on emq:{q}:meta, no wait↔paused RENAME) |

## locks

| Command | Status | v3 home |
|---|---|---|
| [`extendLock-2`](locks/extendLock-2.md) | SHIPPED (ported) | EchoMQ.Jobs.extend_lock/5 (@extend_lock, jobs.ex) |
| [`extendLocks-1`](locks/extendLocks-1.md) | SHIPPED (ported) | EchoMQ.Jobs.extend_locks/4 (@extend_locks, jobs.ex) |
| [`releaseLock-1`](locks/releaseLock-1.md) | SHIPPED (ported, re-split) | EchoMQ.Locks.untrack_job/2 (the lease releases by natural active-score expiry / complete) |

## metrics

| Command | Status | v3 home |
|---|---|---|
| [`getCounts-1`](metrics/getCounts-1.md) | SHIPPED (ported) | EchoMQ.Metrics.get_counts/3 (@counts, metrics.ex) |
| [`getState-8`](metrics/getState-8.md) | SHIPPED (ported) | EchoMQ.Metrics.get_job_state/3 (@state_lookup, metrics.ex) |
| [`getStateV2-8`](metrics/getStateV2-8.md) | SHIPPED (subsumed) | folded into EchoMQ.Metrics.get_job_state/3 (@state_lookup, metrics.ex) |
| [`getMetrics-2`](metrics/getMetrics-2.md) | PARTIAL | EchoMQ.Metrics.get_metrics/3 (metrics.ex) |
| [`getRanges-1`](metrics/getRanges-1.md) | NOT YET | no def get_ranges; closest as-built EchoMQ.Jobs.browse/3 + Metrics.get_counts/3 |
| [`getRateLimitTtl-2`](metrics/getRateLimitTtl-2.md) | SHIPPED (ported) | EchoMQ.Metrics.get_rate_limit_ttl/3 (@rate_ttl, metrics.ex) |
| [`isMaxed-2`](metrics/isMaxed-2.md) | SHIPPED (ported) | EchoMQ.Metrics.is_maxed/2 (@is_maxed, metrics.ex) |
| [`isFinished-3`](metrics/isFinished-3.md) | PARTIAL | no def is_finished; a thin finished?/3 over EchoMQ.Metrics.get_job_state/3 (@state_lookup, metrics.ex) |
| [`isJobInList-1`](metrics/isJobInList-1.md) | NOT YET | no def in_list; re-derives as a declared-key ZSCORE (the @state_lookup mechanism) |
| [`paginate-1`](metrics/paginate-1.md) | NOT YET | no def paginate; the shipped listing is EchoMQ.Jobs.browse/3 + pending_size/3 |

## repeat

| Command | Status | v3 home |
|---|---|---|
| [`addRepeatableJob-2`](repeat/addRepeatableJob-2.md) | SHIPPED (ported) | EchoMQ.Repeat.register/6 (@repeat_register, repeat.ex) |
| [`addJobScheduler-11`](repeat/addJobScheduler-11.md) | PARTIAL | EchoMQ.Repeat.register/6 + EchoMQ.Pump (@repeat_register, repeat.ex) |
| [`getJobScheduler-1`](repeat/getJobScheduler-1.md) | PROPOSED (partial) | EchoMQ.Repeat.get/3 (proposed) beside count/2/due/3 (repeat.ex) |
| [`removeJobScheduler-3`](repeat/removeJobScheduler-3.md) | SHIPPED (ported) | EchoMQ.Repeat.cancel/3 (@repeat_cancel, repeat.ex) |
| [`updateJobScheduler-12`](repeat/updateJobScheduler-12.md) | SHIPPED (ported) | EchoMQ.Repeat.advance/4 + EchoMQ.Pump (@repeat_advance, repeat.ex) |
| [`updateRepeatableJobMillis-1`](repeat/updateRepeatableJobMillis-1.md) | PARTIAL | EchoMQ.Repeat.advance/4 (@repeat_advance, repeat.ex) |
| [`removeRepeatable-3`](repeat/removeRepeatable-3.md) | SHIPPED (ported, new form) | EchoMQ.Repeat.cancel/3 (@repeat_cancel, repeat.ex) |

## retry

| Command | Status | v3 home |
|---|---|---|
| [`retryJob-11`](retry/retryJob-11.md) | PARTIAL | split across EchoMQ.Jobs.retry/7 (@retry, jobs.ex) + reprocess_job/3 (jobs.ex); a single active→pending-now lock-released requeue_active/4 is PROPOSED |
| [`reprocessJob-8`](retry/reprocessJob-8.md) | SHIPPED (ported) | EchoMQ.Jobs.reprocess_job/3 (@reprocess, jobs.ex) |
| [`moveToDelayed-8`](retry/moveToDelayed-8.md) | SHIPPED (ported as retry-reschedule) | EchoMQ.Jobs.retry/7 non-terminal arm (@retry, jobs.ex) |

## scheduling

| Command | Status | v3 home |
|---|---|---|
| [`addDelayedJob-6`](scheduling/addDelayedJob-6.md) | SHIPPED (ported) | EchoMQ.Jobs.enqueue_at/5 + enqueue_in/5 (@schedule, jobs.ex) |
| [`changeDelay-4`](scheduling/changeDelay-4.md) | NOT YET (proposed) | reschedule/4 (proposed) beside @schedule/@promote |
| [`promote-9`](scheduling/promote-9.md) | PARTIAL | EchoMQ.Jobs.promote/3 (@promote due-sweep, jobs.ex); targeted promote_now/3 (proposed) |
