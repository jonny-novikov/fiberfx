# Chapter 03. Job Lifecycle & State Machine

## 3.1. State Machine

Jobs in EchoMQ follow a well-defined state machine. All state transitions are performed atomically by Lua scripts — this is the fundamental protocol guarantee.

```
                    add()
                      │
           ┌──────────┼──────────┐
           │          │          │
           ▼          ▼          ▼
        [wait]   [delayed]  [prioritized]
           │          │          │
           │    (timer/promote)  │
           │          │          │
           └──────────┼──────────┘
                      │
              moveToActive (Lua)
                      │
                      ▼
                  [active]  ◄── lock acquired (STRING + TTL)
                      │
           ┌──────────┼──────────┬───────────┐
           │          │          │           │
           ▼          ▼          ▼           ▼
      [completed]  [failed]  [delayed]  [waiting-children]
                      │      (retry)     (flow parent)
                      │          │           │
                      ▼          │    (children done)
                   [wait]  ◄─────┘           │
                   (retry)                   ▼
                                         [wait/delayed/prioritized]
```

### State Definitions

| State | Redis Location | Description |
|-------|---------------|-------------|
| **wait** | LIST `bull:{q}:wait` | Ready for processing (FIFO order) |
| **paused** | LIST `bull:{q}:paused` | Ready but queue is paused |
| **delayed** | ZSET `bull:{q}:delayed` | Waiting for scheduled time (score = timestamp) |
| **prioritized** | ZSET `bull:{q}:prioritized` | Ready, ordered by priority (score = priority) |
| **active** | LIST `bull:{q}:active` | Currently being processed by a worker |
| **completed** | ZSET `bull:{q}:completed` | Successfully processed (terminal) |
| **failed** | ZSET `bull:{q}:failed` | Processing failed (terminal unless retry) |
| **waiting-children** | ZSET `bull:{q}:waiting-children` | Parent job awaiting child completion |

### Terminal vs Non-Terminal States

- **Terminal**: `completed`, `failed` (after max retries)
- **Non-terminal**: all others — the job can still transition
- **Recyclable terminal**: `failed` and `completed` jobs can be reprocessed via `reprocessJob`

## 3.2. Core State Transitions

### Job Addition

When a job is added, its target state depends on options:

| Condition | Target State | Lua Script |
|-----------|-------------|------------|
| No delay, no priority | `wait` | `addStandardJob-9` |
| `delay > 0` | `delayed` | `addDelayedJob-6` |
| `priority > 0` | `prioritized` | `addPrioritizedJob-9` |
| Has parent job | `waiting-children` (parent) | `addParentJob-6` |

The add scripts atomically:
1. Store the job hash (HMSET)
2. Add to the target queue/set
3. Publish the `added` + `waiting`/`delayed` events
4. Check deduplication (if `deid` provided)
5. Add marker entry (for worker notification)

### Job Pickup (moveToActive)

The `moveToActive-11` Lua script is the heart of the worker loop. It atomically:

1. **Promotes delayed jobs** — moves jobs whose delay has expired from `delayed` to `wait`/`prioritized`
2. **Checks rate limit** — if the rate limiter is active, returns without activating
3. **Checks global concurrency** — respects `meta.concurrency` limit
4. **Dequeues** — RPOP from `wait` or ZPOPMIN from `prioritized`
5. **Acquires lock** — SET `bull:{q}:{jobId}:lock` with token and PX TTL
6. **Activates** — LPUSH to `active` list
7. **Publishes event** — XADD `active` event
8. **Returns job data** — includes all hash fields for immediate processing

**Key count**: 11 Redis keys accessed atomically.

### Job Completion (moveToFinished)

The `moveToFinished-14` Lua script handles both success and failure. It atomically:

1. **Verifies lock** — confirms the caller holds the correct lock token
2. **Removes from active** — LREM from `active` list
3. **Stores result** — HSET `returnvalue` or `failedReason` + `stacktrace`
4. **Adds to terminal set** — ZADD to `completed` or `failed` with timestamp score
5. **Removes lock** — DEL the lock key
6. **Collects metrics** — increments `meta:metrics:completed` or `meta:metrics:failed`
7. **Handles removeOn** — applies `removeOnComplete`/`removeOnFail` policies (by count or age)
8. **Updates parent** — if this job has a parent, checks if all children are done
9. **Removes dedup key** — cleans up deduplication key if present
10. **Trims events** — XTRIM to maintain stream size
11. **Fetches next job** — optionally returns the next job to process (optimization: avoids separate pickup call)

**Key count**: 14 Redis keys accessed atomically.

This is the most complex script in the protocol (~1100 lines with includes resolved).

### Retry (moveToDelayed / retryJob)

When a job fails but has remaining attempts:

1. **Lock removed** — DEL the lock key
2. **Backoff calculated** — delay = base * 2^(attempt-1) with optional jitter
3. **Job moved** — from `active` to `delayed` with new timestamp score
4. **Counter incremented** — `atm` (attempts made) incremented
5. **Event published** — `delayed` event with retry info

### Stalled Job Recovery (moveStalledJobsToWait)

Runs periodically (default every 30 seconds). For each job in the `active` list:

1. **Check lock** — does `bull:{q}:{jobId}:lock` exist?
2. **If no lock** — job is stalled (worker crashed or lost connection)
3. **Check stalled counter** — if `stc >= maxStalledCount`, move to `failed`
4. **Otherwise** — move back to `wait` for reprocessing, increment `stc`

## 3.3. Flow (Parent-Child) Lifecycle

### Flow Creation

A flow is a tree of jobs where parent jobs wait for all children to complete:

```
Parent Job (queue: "deploy")
├── Child 1 (queue: "build")
│   ├── Grandchild A (queue: "compile")
│   └── Grandchild B (queue: "test")
└── Child 2 (queue: "infra")
```

The `FlowProducer` adds all jobs atomically:
1. Leaf jobs added to their target queues
2. Parent jobs added in `waiting-children` state
3. Each child's key added to parent's `:dependencies` set
4. `parentKey` field set on each child job

### Flow Resolution

When a child completes, `moveToFinished` calls `updateParentDepsIfNeeded`:

1. Remove child key from parent's `:dependencies` set
2. Store child's return value in parent's `:processed` hash
3. If `:dependencies` set is empty — all children done:
   - Move parent from `waiting-children` to `wait`
   - Parent will be picked up and processed normally

### Flow Failure Modes

| Option | Behavior |
|--------|----------|
| `failParentOnFailure` | Parent moves to `failed` when any child fails |
| `ignoreDependencyOnFailure` | Parent continues even if child fails |
| `removeDependencyOnFailure` | Remove failed child from parent's deps |
| `continueParentOnFailure` | Parent completes even with failed children |

## 3.4. Locking Protocol

### Lock Acquisition

When a worker picks up a job, the `moveToActive` script atomically sets:

```
SET bull:{queue}:{jobId}:lock <uuid-token> PX <lockDuration>
```

The lock token is a UUID v4 string unique to the worker. The PX TTL ensures the lock expires automatically if the worker crashes.

### Lock Renewal (Heartbeat)

Workers must periodically extend the lock to prevent stall detection:

```
-- Every lockDuration/2 milliseconds:
EVALSHA extendLock KEYS[1]=lock_key KEYS[2]=stalled_set ARGV[1]=token ARGV[2]=duration
```

The `extendLock` script:
1. Verifies the token matches (no one else took the lock)
2. Extends the TTL (PEXPIRE)
3. Removes the job from the stalled set (SREM)

### Lock Verification

All state transitions verify the lock:
- `moveToFinished` checks the lock token before completing
- If the lock is gone or owned by another worker, returns error code -2 (`JobLockNotExist`) or -6 (`JobLockMismatch`)

### Timing

| Parameter | Default | Purpose |
|-----------|---------|---------|
| `lockDuration` | 30000ms | Lock TTL |
| `lockRenewTime` | 15000ms (lockDuration/2) | Heartbeat interval |
| `stalledInterval` | 30000ms | Stalled check period |
| `maxStalledCount` | 1 | Max stalls before permanent failure |

## 3.5. Observability

### Standard Metrics

All implementations should export:

| Metric | Type | Labels | Description |
|--------|------|--------|-------------|
| `echomq_jobs_added_total` | Counter | queue, name | Jobs added |
| `echomq_jobs_completed_total` | Counter | queue, name | Jobs completed |
| `echomq_jobs_failed_total` | Counter | queue, name | Jobs failed |
| `echomq_jobs_stalled_total` | Counter | queue | Stalled detections |
| `echomq_job_duration_seconds` | Histogram | queue, name | Processing time |
| `echomq_job_wait_duration_seconds` | Histogram | queue | Time in wait state |
| `echomq_queue_depth` | Gauge | queue, state | Jobs per state |
| `echomq_worker_active_jobs` | Gauge | queue, worker | Active jobs per worker |

### Distributed Tracing (OpenTelemetry)

Trace context is propagated through job options using W3C TraceContext format:

- Stored in the `tm` (telemetry metadata) compressed options field
- Node.js already supports via `telemetry.metadata`
- Go and Elixir implementations should propagate the same format
- Traces can flow across language boundaries: Node.js producer → Go worker → Elixir callback

---

*Previous: [Redis Data Layer](ch02-redis-data-layer.md) | Next: [Elixir Architecture](ch04-elixir-architecture.md)*
