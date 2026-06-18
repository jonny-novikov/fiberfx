# EchoMQ command catalogue — v1→v3 by feature, with reference-retirement

> One table per feature family (the 12-feature taxonomy). Each row: the v1 legacy
> command, a one-line description, its port status, and **the rung after which its
> v1 reference can be safely dropped**. Reconciled against the as-built
> `features/<family>/<cmd>.md` slices at the **emq.3.5 boundary** (Movement I
> closed; Movement II, emq.4–8, open). Companion to [`README.md`](README.md) and
> the agent index [`llms.txt`](llms.txt).

**NO-INVENT.** Every description compresses the slice's own `Covers → v3` line;
every status + rung is lifted from the slice's `--@` header. Commit hashes are
deliberately omitted — a rung is a durable coordinate, a short-hash is not.

---

## What "safe to drop ref" means

A command's **v1 reference** is two artifacts: the vendored raw source
`registry/<cmd>.lua` (the cold-store corpus) and its migration slice
`features/<family>/<cmd>.md` (the v1→v3 side-by-side). A reference is
**load-bearing only while it is the *spec* for behaviour that has not yet
shipped.** Once that stops being true, the slice can be folded and the hot index
(`llms.txt`, the matrix) can stop citing it — parity is then captured in shipped
code plus the conformance suite, not in a Lua fossil.

| Verdict | Meaning |
|---|---|
| **now (`emq.N`)** | The v3 port **shipped** at rung `emq.N`. The reference is historical — safe to retire today. |
| **now (folded)** | The capability **ships**, folded/subsumed into a broader verb by deliberate design (the divergence is intentional, not pending work). Safe to retire; keep the slice only as a design-note if useful. |
| **`emq.N`** | A concrete future rung pins the remaining/proposed work. The reference is the spec for it — **hold until `emq.N` ships**, then drop. |
| **hold** | Proposed work with **no scheduled rung** (a Movement-II backlog verb). The reference stays load-bearing; rung TBD. |
| **`emq.4 †`** | **Retired by design.** The reference documents *why* the capability was dropped; it becomes a design-note once the replacement lands at `emq.4`. |

### Roll-up (52 commands)

- **33 references are safe to retire now** — 30 SHIPPED ports + 3 deliberately-folded capabilities (`updateRepeatableJobMillis-1`, `isFinished-3`, `removeDeduplicationKey-1`).
- **9 are pinned to a future rung** — `emq.5` ×1, `emq.6` ×3, `emq.8` ×5.
- **8 are held** pending an unscheduled Movement-II verb.
- **2 are retired** (drop once the `emq.4` Lanes replacement ships).

Status vocabulary: `SHIPPED` (ported) · `PARTIAL` (shipped in part) · `NOT YET`
(proposed) · `PROPOSED` (forward-only) · `RETIRED` (dropped by design). All 52
ported or proposed — none remain `BUILDING` (emq.3.5 shipped, closing Movement I).

---

## admission

| Command | What it does | Status | Safe to drop ref |
|---|---|---|---|
| [`addStandardJob-9`](features/admission/addStandardJob-9.md) | Enqueue a job for immediate processing (→ the pending set). | SHIPPED | now (emq.0/1) |

## scheduling

| Command | What it does | Status | Safe to drop ref |
|---|---|---|---|
| [`addDelayedJob-6`](features/scheduling/addDelayedJob-6.md) | Enqueue a job to run after a delay (→ the `schedule` set). *also admission* | SHIPPED | now (emq.1) |
| [`changeDelay-4`](features/scheduling/changeDelay-4.md) | Re-score an already-delayed job to a new delay. | NOT YET | hold |
| [`promote-9`](features/scheduling/promote-9.md) | Promote one specific delayed job to run now. | PARTIAL | hold (core emq.1) |

## repeat

| Command | What it does | Status | Safe to drop ref |
|---|---|---|---|
| [`addRepeatableJob-2`](features/repeat/addRepeatableJob-2.md) | Register/override a repeatable (cron/every) schedule. | SHIPPED | now (emq.1) |
| [`addJobScheduler-11`](features/repeat/addJobScheduler-11.md) | Upsert a scheduler and materialize its next occurrence. | PARTIAL | hold (core emq.1) |
| [`getJobScheduler-1`](features/repeat/getJobScheduler-1.md) | Read one scheduler record (next-run + template). | PROPOSED | hold |
| [`removeJobScheduler-3`](features/repeat/removeJobScheduler-3.md) | Remove a scheduler and its next-programmed job. | SHIPPED | now (emq.1) |
| [`removeRepeatable-3`](features/repeat/removeRepeatable-3.md) | Remove a repeatable (legacy + new key forms collapse to one). | SHIPPED | now (emq.1) |
| [`updateJobScheduler-12`](features/repeat/updateJobScheduler-12.md) | Advance a scheduler to its next occurrence. | SHIPPED | now (emq.1) |
| [`updateRepeatableJobMillis-1`](features/repeat/updateRepeatableJobMillis-1.md) | Re-score a repeatable by custom/legacy key. | PARTIAL | now (folded → `advance/4`) |

## claim

| Command | What it does | Status | Safe to drop ref |
|---|---|---|---|
| [`moveToActive-11`](features/claim/moveToActive-11.md) | Fetch the next eligible job into `active` under a lease (worker pull). | SHIPPED | now (emq.0/1) |
| [`moveJobFromActiveToWait-9`](features/claim/moveJobFromActiveToWait-9.md) | Worker voluntarily returns a still-held active job to wait. | PARTIAL | hold (recovery emq.0) |
| [`moveStalledJobsToWait-8`](features/claim/moveStalledJobsToWait-8.md) | Periodic sweep reclaiming jobs whose worker died holding them. *also locks* | SHIPPED | now (emq.2.3) |

## retry

| Command | What it does | Status | Safe to drop ref |
|---|---|---|---|
| [`retryJob-11`](features/retry/retryJob-11.md) | Move a failed active job back to wait now, releasing its lock. | PARTIAL | hold (core emq.1/2.2) |
| [`reprocessJob-8`](features/retry/reprocessJob-8.md) | Reprocess a finished/failed job (re-enqueue, clear finish fields). | SHIPPED | now (emq.2.2) |
| [`moveToDelayed-8`](features/retry/moveToDelayed-8.md) | Move a locked active job back to delayed (the retry/backoff arm). | SHIPPED | now (emq.1) |

## flows

| Command | What it does | Status | Safe to drop ref |
|---|---|---|---|
| [`addParentJob-6`](features/flows/addParentJob-6.md) | Add a parent job for a parent/child flow. | SHIPPED | now (emq.3.1) |
| [`moveToFinished-14`](features/flows/moveToFinished-14.md) | Complete a locked active job and run the parent fan-in. | SHIPPED | now (emq.0/1) |
| [`moveToWaitingChildren-7`](features/flows/moveToWaitingChildren-7.md) | Worker parks its active job pending its children. | PARTIAL | hold (core emq.3.1) |
| [`getDependencyCounts-4`](features/flows/getDependencyCounts-4.md) | Count a flow parent's children per state. *also metrics* | PARTIAL | hold (pieces emq.3.2/3.4) |
| [`grandchildren-recursive-flow-tree`](features/flows/grandchildren-recursive-flow-tree.md) | Arbitrary-depth flow trees (recursive parent/child nesting). | SHIPPED | now (emq.3.5) |

## groups

| Command | What it does | Status | Safe to drop ref |
|---|---|---|---|
| [`addPrioritizedJob-9`](features/groups/addPrioritizedJob-9.md) | Priority enqueue → re-aimed to per-group fair lanes. *also admission* | SHIPPED | now (emq.1) |
| [`changePriority-7`](features/groups/changePriority-7.md) | Re-position a job at a new priority score. | RETIRED | emq.4 † |
| [`getCountsPerPriority-4`](features/groups/getCountsPerPriority-4.md) | Counts per priority band → re-derived as per-lane depth. *also metrics* | RETIRED | emq.4 † |

## batches

| Command | What it does | Status | Safe to drop ref |
|---|---|---|---|
| [`add_bulk`](features/batches/add_bulk.md) | Submit many flows in one call (the batch producer verb). | SHIPPED | now (emq.3.4) |
| [`moveJobsToWait-8`](features/batches/moveJobsToWait-8.md) | Bulk-move a window of completed/failed/delayed jobs to wait. *also claim* | PARTIAL | emq.5 |

## locks

| Command | What it does | Status | Safe to drop ref |
|---|---|---|---|
| [`extendLock-2`](features/locks/extendLock-2.md) | Renew one job's lease. | SHIPPED | now (emq.2.3) |
| [`extendLocks-1`](features/locks/extendLocks-1.md) | Batch-renew many leases. | SHIPPED | now (emq.2.3) |
| [`releaseLock-1`](features/locks/releaseLock-1.md) | Release a lease. | SHIPPED | now (emq.2.3) |

## metrics

| Command | What it does | Status | Safe to drop ref |
|---|---|---|---|
| [`getCounts-1`](features/metrics/getCounts-1.md) | Count jobs per requested state. | SHIPPED | now (emq.2.1) |
| [`getState-8`](features/metrics/getState-8.md) | Look up one job's state (four-ZSET probe + row branch). | SHIPPED | now (emq.2.1) |
| [`getStateV2-8`](features/metrics/getStateV2-8.md) | Newer-Valkey `getState` variant (LPOS) — the split collapses. | SHIPPED | now (subsumed) |
| [`getMetrics-2`](features/metrics/getMetrics-2.md) | Read the throughput block (completed/failed counters). | PARTIAL | emq.8 (`:data` ring) |
| [`getRanges-1`](features/metrics/getRanges-1.md) | List job-ids per state over a `[start,end]` window. | NOT YET | emq.8 |
| [`getRateLimitTtl-2`](features/metrics/getRateLimitTtl-2.md) | Remaining rate-limiter TTL in ms. | SHIPPED | now (emq.2.1) |
| [`isMaxed-2`](features/metrics/isMaxed-2.md) | Is the queue at its concurrency ceiling? (read-and-refuse) | SHIPPED | now (emq.2.1) |
| [`isFinished-3`](features/metrics/isFinished-3.md) | Is a job finished? (only `:dead` retained by design) | PARTIAL | now (subsumed) |
| [`isJobInList-1`](features/metrics/isJobInList-1.md) | Is an id a member of a given list? (→ O(log n) ZSCORE) | NOT YET | emq.8 |
| [`paginate-1`](features/metrics/paginate-1.md) | A stable-cursor page of a set or hash. | NOT YET | emq.8 |

## data

| Command | What it does | Status | Safe to drop ref |
|---|---|---|---|
| [`updateData-1`](features/data/updateData-1.md) | Replace a job's `data` (→ `payload`) blob. | SHIPPED | now (emq.2.2) |
| [`updateProgress-3`](features/data/updateProgress-3.md) | Write a job's progress and emit a `progress` event. | SHIPPED | now (emq.2.2) |
| [`addLog-2`](features/data/addLog-2.md) | Append a line to a job's logs (keep-N trim). | SHIPPED | now (emq.2.2) |
| [`saveStacktrace-1`](features/data/saveStacktrace-1.md) | Persist a richer failure record (stacktrace + reason). | NOT YET | emq.8 |

## lifecycle

| Command | What it does | Status | Safe to drop ref |
|---|---|---|---|
| [`removeJob-2`](features/lifecycle/removeJob-2.md) | Remove one job from every state + all its data; refuse if locked. | SHIPPED | now (emq.2.2) |
| [`removeChildDependency-1`](features/lifecycle/removeChildDependency-1.md) | Break one parent↔child flow link. *also flows* | NOT YET | emq.6 |
| [`removeDeduplicationKey-1`](features/lifecycle/removeDeduplicationKey-1.md) | Release a dedup key iff it still points at this job. | PARTIAL | now (folded → `@remove_job`) |
| [`removeUnprocessedChildren-2`](features/lifecycle/removeUnprocessedChildren-2.md) | Recursively remove a job's unprocessed children. *also flows* | NOT YET | emq.6 |
| [`cleanJobsInSet-3`](features/lifecycle/cleanJobsInSet-3.md) | Bulk-remove aged jobs from one set (skip locked/scheduler). *also batches* | PARTIAL | emq.6 |
| [`drain-5`](features/lifecycle/drain-5.md) | Empty pending (+ optional delayed), leaving active. | SHIPPED | now (emq.2.2) |
| [`obliterate-2`](features/lifecycle/obliterate-2.md) | Destroy a *paused* queue entirely (every set + key). | SHIPPED | now (emq.2.2) |
| [`pause-7`](features/lifecycle/pause-7.md) | Pause/resume the queue globally. | SHIPPED | now (emq.2.2) |

---

† **Retired by design.** The v1 `prioritized` ZSET is gone (mint order *is* the
order theorem; per-group `Lanes` replace numeric priority). These references are
kept only as the record of *what was dropped and why*; once the `Lanes`
re-assignment / weighted-rotation replacement ships at **emq.4**, that rationale
lives in the emq.4 design notes and the slice becomes redundant.

**Provenance.** Descriptions ← each slice's `Covers → v3` line. Status + rung ←
each slice's `--@status` / `--@rung` header (hashes stripped). Target rungs for
unshipped work ← [`llms.txt`](llms.txt). Cross-feature tags (*also …*) ← the
registry matrix. Nothing here is fabricated; v3 schematics for unbuilt rungs stay
withheld at their slice (the NO-INVENT rule of [`features/FORMAT.md`](features/FORMAT.md)).
