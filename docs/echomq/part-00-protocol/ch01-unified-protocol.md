# Chapter 01. Unified Protocol Specification

## 1.1. Protocol Definition

The EchoMQ protocol is **not** a network wire protocol. It is a **Redis data structure convention** combined with **atomic Lua scripts** that together define a distributed job queue system. The protocol specifies:

1. **Key naming conventions** — how Redis keys are structured
2. **Data structure assignments** — which Redis type (LIST, ZSET, HASH, STREAM, STRING) is used for each purpose
3. **Lua scripts** — atomic operations that transition jobs between states
4. **Job hash schema** — the field names and value formats stored in job HASH keys
5. **Event stream format** — the fields emitted to the Redis STREAM for observability
6. **Locking convention** — how distributed locks are implemented via STRING keys with TTL
7. **Error codes** — numeric return values from Lua scripts indicating failure conditions

## 1.2. Immutable Protocol Contract

These elements MUST NOT be modified by any EchoMQ implementation. They define the wire-level compatibility guarantee:

### 1. Redis Key Naming

Base format: `{prefix}:{queueName}:{suffix}`

Default prefix: `bull` (configurable, but all implementations sharing a Redis must use the same prefix)

All keys use hash tags `bull:{queueName}:*` where `{queueName}` ensures same Redis Cluster slot via CRC16.

### 2. Lua Scripts

All implementations MUST use unmodified BullMQ Lua scripts pinned to the protocol version. Scripts are extracted verbatim from the reference implementation and embedded as string constants.

Requirements:
- Embed the full include chain — scripts reference includes via `--- @include` directives
- Use script versioning: commands registered as `{scriptName}:{version}`
- Use EVALSHA: load script once, execute by SHA (performance)
- Handle NOSCRIPT: reload script if SHA not found (Redis restart recovery)

### 3. Job Hash Field Names

v5.x uses **compressed field names** to reduce Redis memory:

| Full Name | Compressed | Used Since |
|-----------|-----------|------------|
| `attemptsMade` | `atm` | v5.x |
| `attemptsStarted` | `ats` | v5.x |
| `stalledCounter` | `stc` | v5.x |
| `processedBy` | `pb` | v5.x |
| `repeatJobKey` | `rjk` | v5.x |
| `deduplicationId` | `deid` | v5.x |
| `deferredFailure` | `defa` | v5.x |
| `nextRepeatableJobId` | `nrjid` | v5.x |

> **Critical**: If an implementation writes `attemptsMade` while another reads `atm`, jobs appear to have 0 attempts and retry infinitely. This is the single most important interop requirement.

### 4. Job Options Encoding

Job options MUST be **msgpack-encoded** for Lua ARGV transmission. The Lua scripts call `cmsgpack.unpack(ARGV[n])` to decode arguments. Implementations must use a msgpack library that is binary-compatible with Redis's built-in `cmsgpack`.

Compressed options field map:

```
attempts        → att
backoff         → bo
delay           → del
lifo            → lifo
priority        → pri
removeOnComplete → roc
removeOnFail    → rof
sizeLimit       → sl
stackTraceLimit → stl
failParentOnFailure → fpof
removeDependencyOnFailure → rdof
ignoreDependencyOnFailure → idof
continueParentOnFailure → cpof
telemetry.metadata → tm
telemetry.omitContext → omc
deduplication.id → de.id
```

### 5. Event Stream Fields

Events use exact field names. Notably: `returnvalue` (lowercase, not camelCase).

### 6. Error Codes

Lua scripts return negative integers for error conditions:

| Code | Name | Meaning |
|------|------|---------|
| -1 | `JobNotExist` | Job key missing |
| -2 | `JobLockNotExist` | Lock key missing |
| -3 | `JobNotInState` | Job not in expected state |
| -4 | `JobPendingChildren` | Cannot complete, has pending deps |
| -5 | `ParentJobNotExist` | Parent key missing |
| -6 | `JobLockMismatch` | Lock token does not match |
| -7 | `ParentJobCannotBeReplaced` | Parent replacement blocked |
| -8 | `JobBelongsToJobScheduler` | Cannot remove scheduler job directly |
| -9 | `JobHasFailedChildren` | Cannot complete with failed children |
| -10 | `SchedulerJobIdCollision` | Scheduler job ID already exists |
| -11 | `SchedulerJobSlotsBusy` | Scheduler time slots occupied |

### 7. Lock Format

Distributed locks use STRING keys with token value and PX TTL:
- Key: `bull:{queue}:{jobId}:lock`
- Value: UUID v4 token string
- TTL: `lockDuration` (default 30000ms)
- Extension: every `lockDuration/2` via heartbeat

### 8. Priority Range

Priority values: 0 (highest) to 2^21 (lowest). The `pc` (priority counter) key provides ordering within the same priority level.

## 1.3. Language-Specific Elements

These elements CAN vary between implementations:

| Element | Description | Examples |
|---------|-------------|----------|
| API surface | Method names, parameter order, return types | `queue.add()` vs `Queue.add/4` |
| Error handling | Language-native error patterns | Exceptions, `(result, error)`, `{:ok, result}` |
| Concurrency model | How parallel work is managed | Threads, goroutines, BEAM processes |
| Connection management | Pool configuration, reconnection, failover | ioredis, go-redis, Redix |
| Type system | How job data types are expressed | Generics, interfaces, behaviours |
| Telemetry | Observability integration | OpenTelemetry, StatsD, :telemetry |
| Configuration | How options are passed | Constructor opts, config files, env vars |
| Helper patterns | Application-level conveniences | Results queue, test helpers |

## 1.4. Complete Lua Script Inventory

The BullMQ v5.x protocol includes **53 main Lua scripts** and **60 include helpers**.

### Main Scripts: Job Lifecycle

| Script | Keys | Purpose |
|--------|------|---------|
| `addStandardJob-9` | 9 | Add standard (non-priority, non-delayed) job |
| `addDelayedJob-6` | 6 | Add job to delayed ZSET |
| `addPrioritizedJob-9` | 9 | Add job to prioritized ZSET |
| `addParentJob-6` | 6 | Add parent job (waiting-children state) |
| `moveToActive-11` | 11 | Atomic: wait/prioritized → active + lock acquisition |
| `moveToFinished-14` | 14 | Atomic: active → completed/failed + next job fetch |
| `moveToDelayed-8` | 8 | Move active job to delayed (retry with backoff) |
| `moveToWaitingChildren-7` | 7 | Move active to waiting-children |
| `moveJobFromActiveToWait-9` | 9 | Rate-limited: active → wait |
| `moveStalledJobsToWait-8` | 8 | Detect and requeue stalled jobs |
| `moveJobsToWait-8` | 8 | Bulk retry failed/completed jobs |
| `retryJob-11` | 11 | Retry single active job |
| `reprocessJob-8` | 8 | Re-queue completed/failed job |

### Main Scripts: Job Management

| Script | Keys | Purpose |
|--------|------|---------|
| `removeJob-2` | 2 | Remove job and its children |
| `cleanJobsInSet-3` | 3 | Clean old jobs from completed/failed |
| `obliterate-2` | 2 | Completely destroy queue |
| `drain-5` | 5 | Remove all waiting/delayed jobs |
| `promote-9` | 9 | Promote delayed job to wait |

### Main Scripts: Data Operations

| Script | Keys | Purpose |
|--------|------|---------|
| `updateData-1` | 1 | Update job data payload |
| `updateProgress-3` | 3 | Update job progress + emit event |
| `addLog-2` | 2 | Append job log entry |
| `extendLock-2` | 2 | Extend job lock TTL (heartbeat) |
| `extendLocks-1` | 1 | Bulk extend multiple locks |
| `saveStacktrace-1` | 1 | Save error stacktrace |
| `pause-7` | 7 | Pause/resume queue |

### Main Scripts: Query Operations

| Script | Keys | Purpose |
|--------|------|---------|
| `getCounts-1` | 1 | Get job counts by state |
| `getState-8` / `getStateV2-8` | 8 | Get job state |
| `getRanges-1` | 1 | Get job IDs by state range |
| `isFinished-3` | 3 | Check if job completed/failed |

### Main Scripts: Scheduler/Repeatable

| Script | Keys | Purpose |
|--------|------|---------|
| `addJobScheduler-11` | 11 | Upsert job scheduler |
| `updateJobScheduler-12` | 12 | Update existing scheduler |
| `removeJobScheduler-3` | 3 | Remove job scheduler |

### Key Include Helpers (60 files)

The most important shared includes:

| Include | Purpose |
|---------|---------|
| `storeJob` | HMSET job hash with all fields |
| `prepareJobForProcessing` | Lock acquisition, rate limit check, event emit |
| `promoteDelayedJobs` | Move due delayed jobs to wait |
| `getTargetQueueList` | Determine target list (wait vs paused, check maxed) |
| `moveJobFromPrioritizedToActive` | ZPOPMIN from prioritized set |
| `removeLock` | Verify and delete lock |
| `updateParentDepsIfNeeded` | Flow: check parent completion |
| `moveParentToWaitIfNeeded` | Flow: move parent when children done |
| `collectMetrics` | Record completion/failure metrics |
| `deduplicateJob` | Check deduplication key |
| `trimEvents` | XTRIM events stream |

### Critical Script Dependency Graphs

**moveToActive** (the job pickup script):
```
moveToActive-11.lua
  ├── includes/getNextDelayedTimestamp
  ├── includes/getRateLimitTTL
  ├── includes/getTargetQueueList
  │     ├── includes/isQueuePaused
  │     └── includes/isQueueMaxed
  ├── includes/moveJobFromPrioritizedToActive
  ├── includes/prepareJobForProcessing
  │     └── includes/addBaseMarkerIfNeeded
  └── includes/promoteDelayedJobs
        ├── includes/addDelayedJob
        └── includes/addJobWithPriority
```

**moveToFinished** (the completion/failure script — ~1100 lines resolved):
```
moveToFinished-14.lua
  ├── includes/collectMetrics
  ├── includes/getNextDelayedTimestamp
  ├── includes/getRateLimitTTL
  ├── includes/getTargetQueueList
  ├── includes/moveJobFromPrioritizedToActive
  ├── includes/moveChildFromDependenciesIfNeeded
  ├── includes/prepareJobForProcessing
  ├── includes/promoteDelayedJobs
  ├── includes/removeDeduplicationKeyIfNeededOnFinalization
  ├── includes/removeJobKeys
  ├── includes/removeJobsByMaxAge / removeJobsByMaxCount
  ├── includes/removeLock
  ├── includes/removeParentDependencyKey
  ├── includes/trimEvents
  ├── includes/updateParentDepsIfNeeded
  │     └── includes/moveParentToWaitIfNeeded
  │           └── includes/moveParentToWait
  └── includes/updateJobFields
```

## 1.5. Protocol Governance

### Version Pinning

Each EchoMQ release pins to a specific BullMQ commit SHA. The Lua scripts are extracted verbatim from that commit. CI validates script checksums against upstream.

### Version Declaration

Implementations write a version identifier to the queue metadata hash:

```
bull:{queue}:meta field "version" = "{library}:{version}"

Examples:
  "bullmq:5.62.0"     (Node.js)
  "echomq-go:5.62.0"   (Go)
  "echomq-ex:5.62.0"   (Elixir)
```

### Compatibility Rule

All EchoMQ implementations sharing a Redis instance MUST use the same Lua script version. Version mismatch detection is available via the `meta.version` field.

---

*Previous: [EchoMQ Overview](ch00-echomq-overview.md) | Next: [Redis Data Layer](ch02-redis-data-layer.md)*
