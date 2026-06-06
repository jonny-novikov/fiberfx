# Chapter 05. Go Implementation Architecture

## 5.1. Current State (v0.1.1)

EchoMQ Go is a well-structured Go library implementing the BullMQ wire protocol for Redis-based job queuing. It provides:

- **~20 source files** (~4,850 lines) with clean separation of concerns
- **Correct wire format** — JSON serialization, Redis key naming, event streams
- **Embedded Lua scripts** from BullMQ v5.62.0 (~1,583 lines in `scripts.go`)
- **77 tests** (47 unit + 30 integration) with testcontainers for real Redis
- **Redis Cluster support** — hash tag auto-detection, CRC16 slot calculation

### The Core Insight

> The Lua scripts are present in `scripts.go` and the ScriptLoader is functional (proven by `progress.go` and `logs.go` which use it correctly). The gap is purely in the integration layer — critical-path operations need to call the scripts instead of issuing separate Redis commands.

This is not an architecture or design problem. It is a **wiring** problem.

## 5.2. Package Structure

<tabs>
<tab title="Go">

```
apps/echomq-go/
  pkg/echomq/            # All implementation code (flat package)
    scripts/             # Embedded Lua scripts + loader
  examples/              # 5 usage examples
  tests/
    unit/                # 12 test files
    integration/         # 13 test files
    compatibility/       # Node.js interop test harness
  specs/001-bullmq-.../  # Specification documents
    contracts/           # Redis protocol contracts
```

</tab>
<tab title="Elixir">

```
phoenix/apps/echomq/
  lib/echomq/
    queue.ex             # Stateless queue operations (GenServer optional)
    worker.ex            # GenServer worker with BEAM process pool
    job.ex               # Job struct + Redis serialization
    flow_producer.ex     # Atomic flow tree creation
    lock_manager.ex      # Batch lock renewal (1 timer per worker)
    queue_events.ex      # Redis Streams subscription (GenServer)
    redis_connection.ex  # NimblePool connection management
    scripts.ex           # Lua script execution via Redix
    keys.ex              # Redis key builder
    telemetry.ex         # :telemetry event emission
  test/                  # ExUnit tests
```

</tab>
<tab title="Node.js">

```
repos/bullmq-node/
  classes/
    queue.ts             # Queue class (extends QueueBase)
    worker.ts            # Worker class with event loop concurrency
    job.ts               # Job class with rich API
    flow-producer.ts     # FlowProducer for parent-child trees
    lock-manager.ts      # Per-job lock renewal timers
    queue-events.ts      # Redis Streams EventEmitter
    redis-connection.ts  # ioredis wrapper
    scripts.ts           # Lua script loading + defineCommand
  commands/              # Lua scripts (source of truth)
  interfaces/            # TypeScript type definitions
```

</tab>
</tabs>

The flat single-package design is appropriate for the current scope. Restructuring will be needed when flows, repeatable jobs, and other features are added.

## 5.3. Architecture Diagram

<tabs>
<tab title="Go">

```
Queue
  ├── redis.Cmdable (interface — works with Client or ClusterClient)
  ├── KeyBuilder (constructs Redis keys with hash tags)
  ├── ScriptLoader (EVALSHA caching)
  └── EventEmitter (XADD publishing)

Worker
  ├── Queue (embedded)
  ├── JobProcessor func(context.Context, *Job) (interface{}, error)
  ├── HeartbeatManager (per-job lock extension goroutines)
  ├── StalledChecker (periodic stall detection)
  ├── Completer (state transitions)
  └── sync.WaitGroup (graceful shutdown)

Job
  ├── JSON tags matching BullMQ wire format
  ├── RemoveOnSetting (flexible bool/int/object)
  └── Methods: UpdateProgress(), Log()
```

</tab>
<tab title="Elixir">

```
EchoMQ.Queue (module — stateless function calls)
  ├── Redix connection (named :my_redis)
  ├── EchoMQ.Keys (constructs Redis keys)
  ├── EchoMQ.Scripts (EVALSHA via Redix)
  └── No EventEmitter (events emitted inline)

EchoMQ.Worker (GenServer)
  ├── Redix connection (owned per worker)
  ├── Processor function (&MyApp.process/1)
  ├── LockManager (linked GenServer — 1 timer for ALL jobs)
  ├── StalledChecker (periodic, via Process.send_after)
  └── DynamicSupervisor (optional, for scaling)

EchoMQ.Job (struct)
  ├── Snake_case fields mapped from Redis camelCase
  ├── from_redis/4 for deserialization
  └── Methods: update_progress/2, add_log/2
```

</tab>
<tab title="Node.js">

```
Queue (class instance)
  ├── ioredis connection (main)
  ├── QueueKeys (Redis key builder)
  ├── Scripts (redis.defineCommand)
  └── EventEmitter (Node.js native)

Worker (class instance)
  ├── ioredis connection (main + blocking duplicate)
  ├── Processor (async function or sandboxed child)
  ├── LockManager (per-job setInterval timers)
  ├── Stalled checker (setInterval, periodic)
  └── AbortController (graceful shutdown)

Job (class instance)
  ├── camelCase fields matching Redis schema
  ├── fromJSON() for deserialization
  └── Methods: updateProgress(), log()
```

</tab>
</tabs>

## 5.4. Concurrency Model

The worker uses a **goroutine-per-job** pattern with a counting semaphore:

<tabs>
<tab title="Go">

```
Worker.Start()
  └── polling loop (ticker-based)
       └── pickupJob()
            └── go processJob()  // new goroutine per job
                 ├── heartbeat.Start(jobID, lockToken)
                 │    └── goroutine: ticker-based lock extension
                 ├── processor(ctx, job)  // user function
                 └── heartbeat.Stop(jobID)
```

</tab>
<tab title="Elixir">

```
Worker GenServer (coordinator)
  └── handle_info(:poll)
       └── move_to_active() via Lua script
            └── Task.async(fn -> processor.(job) end)  // BEAM process per job
                 ├── LockManager handles ALL job locks (1 timer)
                 ├── processor.(job)  // user function
                 └── move_to_finished() on completion
```

</tab>
<tab title="Node.js">

```
Worker (event loop)
  └── getNextJob() (BZPOPMIN-based blocking wait)
       └── moveToActive Lua script
            └── async processor(job)  // runs on event loop
                 ├── setInterval: lock renewal timer (per-job)
                 ├── await processor(job)  // user function
                 └── moveToFinished Lua script
```

</tab>
</tabs>

The semaphore limits concurrent processing to `WorkerOptions.Concurrency` (default: 1). Each active job has its own heartbeat goroutine.

**Graceful Shutdown**: `Worker.Stop()` sets running=false, stops polling ticker, waits for all in-flight jobs via `sync.WaitGroup`, then stops stalled checker and heartbeat manager.

## 5.5. Functional Requirements Coverage

| FR | Description | Status | Root Cause |
|----|-------------|--------|------------|
| **FR-1** | Job submission | IMPLEMENTED | `queue_impl.go:Add()` with UUID job IDs |
| **FR-2** | Job pickup | PARTIAL | **Separate commands, not `moveToActive` script** |
| **FR-3** | Lock-based heartbeat | IMPLEMENTED | `heartbeat.go` — per-job goroutines, 15s/30s |
| **FR-4** | Completion/failure | PARTIAL | **Separate commands, not `moveToFinished` script** |
| **FR-5** | Stalled recovery | PARTIAL | **Separate commands, not `moveStalledJobsToWait` script** |
| **FR-6** | Exponential backoff | IMPLEMENTED | `retry.go` — correct formula with ±20% jitter |
| **FR-7** | Error categorization | IMPLEMENTED | `errors.go` — Transient/Permanent/Validation |
| **FR-8** | Redis Cluster hash tags | IMPLEMENTED | `cluster.go` — CRC16, auto-detection |
| **FR-9** | Event stream publishing | IMPLEMENTED | `events.go` — XADD with ~MAXLEN trimming |
| **FR-10** | Progress and logs | IMPLEMENTED | `progress.go`, `logs.go` — **correctly use Lua scripts** |

**Summary**: 7/10 fully implemented. 3/10 partial — all share the same root cause: critical-path operations bypass embedded Lua scripts.

## 5.6. The Atomicity Gap

### Gap 1: Non-Atomic Job Pickup (CRITICAL)

**Current** (`worker_impl.go:pickupJob()`):
```
1. ZPopMin(prioritized) OR RPop(wait)   // Remove from queue
2. SetEx(lock:{jobId}, token, 30s)      // Acquire lock
3. LPush(active, jobId)                 // Add to active list
```

**Required** (`moveToActive` Lua script):
```
1. EVALSHA moveToActive [keys...] [args...]  // Atomic: dequeue + lock + activate
```

**Risk**: Worker crash between step 1 and step 3 → job dequeued but never activated = **lost job** until manual intervention.

**Missed functionality**: Rate limiting enforcement, delayed job promotion, marker management, group support.

### Gap 2: Non-Atomic Job Completion (CRITICAL)

**Current** (`completer.go:Complete()`):
```
1. LRem(active, jobId)                  // Remove from active
2. HSet(job:{jobId}, returnvalue, ...)  // Store result
3. ZAdd(completed, timestamp, jobId)    // Add to completed set
4. Del(lock:{jobId})                    // Remove lock
5. XADD(events, completed, ...)         // Publish event
```

**Required** (`moveToFinished` Lua script):
```
1. EVALSHA moveToFinished [keys...] [args...]  // Atomic: all above + parent deps + metrics + next job
```

**Risk**: Crash between step 1 and step 3 → job in limbo (neither active nor completed). Also misses: parent dependency resolution, metrics collection, next-job optimization, dedup key cleanup, removeOn policy.

### Gap 3: Non-Atomic Stalled Recovery (HIGH)

**Current** (`stalled.go`): Iterates stalled jobs with separate commands.

**Risk**: Race with active workers → can move processing jobs back to wait → **duplicate processing**.

**Additional bug**: `attemptsMade` is hardcoded to 1 (TODO comment in source).

## 5.7. Network Performance Impact

| Phase | Current RTTs | With Lua Scripts | Savings |
|-------|-------------|-----------------|---------|
| Add (enqueue) | 3-4 | 1 (addJob script) | 2-3 |
| Pickup | 3-4 | 1 (moveToActive) | 2-3 |
| Heartbeat (each) | 1 | 1 | 0 |
| Complete/Fail | 4-5 | 1 (moveToFinished) | 3-4 |
| **Total per job** | **~11-14** | **~4** | **7-10 RTTs** |

At 1,000 jobs/sec: **7,000-10,000 unnecessary network round trips per second**.

## 5.8. Cross-Language Compatibility

### Verified Compatible

- Redis key naming: `bull:{queueName}:{entity}` with hash tags
- Event stream format: Same XADD structure and event types
- Lock token format: UUID v4 strings
- Heartbeat timing: 15s interval, 30s TTL (matches Node.js defaults)
- `returnvalue` lowercase (correct)

### Known Incompatibilities

| Area | Go Behavior | Node.js Behavior | Impact |
|------|-------------|-----------------|--------|
| Job ID generation | UUID v4 | Sequential INCR | Functionally compatible (both strings) |
| Job pickup | Separate commands | `moveToActive` | Race conditions in mixed deployments |
| Completion | Separate commands | `moveToFinished` | State corruption under concurrent access |
| Field names | `attemptsMade` (full) | `atm` (compressed) | **CRITICAL**: infinite retry interop bug |
| Priority scoring | Negative ZADD scores | Lua script encoding | Priority mismatch across languages |
| `Job.Data` type | `map[string]interface{}` | JSON string | Float precision loss for large integers |
| Module path | `fiberfx/echomq-go` (go.mod) | N/A | Internal imports use `lokeyflow/bullmq-go` |

### Director Decisions (from Apollo Review)

| Decision | Finding | Resolution |
|----------|---------|------------|
| **D-1** | Go HAS msgpack (`vmihailenco/msgpack/v5`) | Extend usage to critical-path ARGV, don't add new dependency |
| **D-2** | Go features ARE implemented but non-atomic | Reframe work as "rewire" not "build from scratch" |
| **D-3** | `Job.Data` is `map[string]interface{}`, not `json.RawMessage` | Consider migration for round-trip fidelity |
| **D-5** | Tests at `tests/unit/` + `tests/integration/` (non-standard Go layout) | Document for contributor onboarding |
| **D-6** | Priority scoring auto-fixes when Lua scripts integrated | No separate fix needed |

## 5.9. Script Infrastructure

The infrastructure for Lua script execution already works:

### ScriptLoader (`scripts/loader.go`)

- SHA1 caching: first call = EVAL (sends full script), subsequent = EVALSHA (sends hash)
- NOSCRIPT recovery: auto-fallback to EVAL on Redis restart
- **Proven**: `progress.go` and `logs.go` use it correctly in production paths

### Embedded Scripts (`scripts/scripts.go`)

~1,583 lines containing 8 BullMQ v5.62.0 Lua scripts:

| Script | Lines | Status |
|--------|-------|--------|
| `MoveToActive` | ~245 | Embedded, **not wired** |
| `MoveToFinished` | ~1100 | Embedded, **not wired** |
| `MoveToCompleted` | alias | Points to MoveToFinished |
| `MoveToFailed` | alias | Points to MoveToFinished |
| `RetryJob` | ~300 | Embedded, **not wired** |
| `MoveStalledJobsToWait` | ~175 | Embedded, **not wired** |
| `ExtendLock` | ~20 | Embedded, **wired and working** |
| `UpdateProgress` | ~35 | Embedded, **wired and working** |
| `AddLog` | ~23 | Embedded, **wired and working** |

### Missing Script

`addJob` (addStandardJob/addDelayedJob/addPrioritizedJob) — not extracted yet. Needed for atomic job submission.

## 5.10. Dependencies

| Dependency | Version | Purpose | Risk |
|------------|---------|---------|------|
| `go-redis/v9` | v9.16.0 | Redis client | Low — mature |
| `google/uuid` | v1.6.0 | Job ID + lock token | Low |
| `vmihailenco/msgpack/v5` | v5.4.1 | Lua ARGV encoding | **Medium** — must be cmsgpack-compatible |
| `testcontainers-go` | v0.39.0 | Integration tests | Low — test-only |
| `testify` | v1.11.1 | Test assertions | Low — test-only |

## 5.11. Roadmap to v1.0

### Milestone 1: Atomicity (v0.2.0) — 2-3 weeks

1. Wire `pickupJob()` → `MoveToActive` via ScriptLoader
2. Wire `Complete()`/`Fail()` → `MoveToFinished` via ScriptLoader
3. Wire `checkAndRecover()` → `MoveStalledJobsToWait` via ScriptLoader
4. Wire `retryJob()` → `RetryJob` via ScriptLoader
5. Extract + embed `addJob` Lua script
6. Wire `Add()` → `addJob` via ScriptLoader
7. Fix compressed field names (`atm`, `ats`, `stc`, `pb`)
8. Fix priority scoring to match BullMQ encoding

### Milestone 2: Validation (v0.3.0) — 2 weeks

1. Cross-language compatibility tests under concurrent load
2. Benchmark suite (throughput, latency, memory, goroutine count)
3. Fix `attemptsMade` parsing in stalled checker
4. Fix module path inconsistency (fiberfx vs lokeyflow)
5. Connection pool configuration exposure
6. Metrics collection (processed/failed counters)

### Milestone 3: Hardening (v1.0.0) — 3-4 weeks

1. Chaos testing (network partitions, Redis restarts, worker crashes)
2. Documentation (GoDoc, usage guides, migration guide)
3. CI/CD pipeline with cross-language test matrix
4. Performance optimization (batch operations)
5. OpenTelemetry integration (traces/metrics)

## 5.12. Architectural Strengths

1. **Script Infrastructure Ready** — ScriptLoader + embedded scripts work; gap is purely wiring
2. **Clean Abstractions** — `redis.Cmdable`, `KeyBuilder`, `EventEmitter` need no changes for Lua integration
3. **Correct Wire Format** — JSON tags, flexible RemoveOnSetting deserialization, proper key formatting
4. **Good Test Infrastructure** — testcontainers-go + Node.js compatibility harness
5. **Cluster-First Design** — CRC16, cluster detection, hash tag validation (v0.1.1 fix)

## 5.13. Architectural Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| Lua script argument encoding mismatch | HIGH | Build argument builder with tests against Node.js outputs |
| msgpack binary incompatibility (Go vs cmsgpack) | CRITICAL | Round-trip test suite: Go encode → Redis → Lua decode |
| Script key ordering errors | HIGH | Dedicated `ScriptCall` struct validating argument counts |
| Breaking existing users on atomicity change | LOW | Release as v0.2.0 — non-atomic behavior is a bug |
| BullMQ version drift | MEDIUM | Version pinning + script extraction tool |

---

*Previous: [Elixir Architecture](ch04-elixir-architecture.md) | Next: [Cross-Language Interop](ch06-cross-language-interop.md)*
