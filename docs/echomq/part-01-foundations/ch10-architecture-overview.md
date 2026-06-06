# Chapter 10. Architecture Overview

## 10.1. From Protocol to Implementation

The [EchoMQ Overview](ch00-echomq-overview.md) introduced the 4-layer architecture model where L0-L2 are immutable (shared across all implementations) and L3-L4 are language-specific. The [Unified Protocol](ch01-unified-protocol.md) and [Redis Data Layer](ch02-redis-data-layer.md) covered the shared foundation in detail. This chapter focuses on **how each language implements L3 (Script Executor) and L4 (Language API)** — the layers where Elixir, Go, and Node.js diverge from a common protocol into language-native patterns.

```
┌──────────────────────────────────────────────────────────────┐
│                    EchoMQ 4-Layer Model                       │
├────────┬──────────────────┬──────────────────────────────────┤
│ Layer  │ Name             │ Scope                            │
├────────┼──────────────────┼──────────────────────────────────┤
│  L4    │ Language API     │ Queue.add(), Worker.process()    │
│  L3    │ Script Executor  │ EVALSHA, msgpack, SHA cache      │
├────────┼──────────────────┼──────────────────────────────────┤
│  L2    │ Lua Scripts      │ 53 scripts + 60 includes         │  IMMUTABLE
│  L1    │ Redis Data Layer │ Keys, structures, field names    │  IMMUTABLE
│  L0    │ Redis Engine     │ Redis 6.0+ / Cluster             │  EXTERNAL
└────────┴──────────────────┴──────────────────────────────────┘
```

Every EchoMQ implementation executes the same Lua scripts against the same Redis data structures. The differences lie entirely in how each runtime manages connections, concurrency, and failure recovery around those shared scripts.

## 10.2. Shared Foundation (L0-L2)

All three implementations share these elements identically:

- **Redis key naming**: `bull:{queueName}:{suffix}` with hash tags for Cluster slot co-location
- **53 Lua scripts** extracted verbatim from BullMQ v5.62.0 (pinned commit SHA)
- **Job hash schema**: compressed field names (`atm`, `ats`, `stc`, `pb`) for v5.x interop
- **Event stream format**: XADD to `bull:{queueName}:events` with `~MAXLEN 10000`
- **Lock convention**: STRING keys with UUID v4 tokens and PX TTL
- **Error codes**: -1 through -11 returned from Lua scripts
- **msgpack encoding**: Job options transmitted as msgpack-encoded ARGV to Lua scripts

See [Unified Protocol](ch01-unified-protocol.md) for the complete protocol contract and [Redis Data Layer](ch02-redis-data-layer.md) for key taxonomy and schema details.

## 10.3. Language-Specific Layers (L3-L4)

### Runtime Architecture Comparison

Each runtime implements the same protocol (L0-L2) but with fundamentally different process models. Use the tabs below to compare architecture diagrams side by side.

<tabs>
<tab title="Elixir">

**Design philosophy:** Redis owns all queue state, OTP owns all process lifecycle.

**Key design choices:**

- **Queue is stateless.** No GenServer, no local state. `EchoMQ.Queue.add/4` is a pure function call that invokes a Lua script via a named Redix connection. Because Redis holds all queue state, the Elixir Queue module is naturally concurrent-safe without coordination.
- **Worker is a GenServer.** Each `EchoMQ.Worker` is a supervised GenServer that owns its Redis connection, spawns isolated BEAM processes per job, and manages a linked LockManager for batch lock renewal.
- **NimblePool for connections.** The `EchoMQ.RedisConnection` module provides a supervised connection pool with configurable `pool_size`, health checking, and automatic reconnection.
- **Telemetry is native.** `:telemetry` events fire for job lifecycle transitions without external dependencies.

```
Application Supervisor
├── EchoMQ.RedisConnection (:echomq_redis)
│   ├── NimblePool (pool_size connections)
│   └── Registry (blocking connection tracking)
├── EchoMQ.Worker (:combat_worker)
│   ├── LockManager (linked GenServer, 1 timer for ALL active jobs)
│   ├── Job Process 1 → processor function (calculate-damage)
│   ├── Job Process 2 → processor function (apply-buff)
│   └── ... up to concurrency limit
├── EchoMQ.Worker (:matchmaking_worker)
│   └── LockManager + Job Processes...
├── EchoMQ.QueueEvents (:player_events)
│   └── Redis XREAD loop → process mailbox delivery
└── DynamicSupervisor (optional, runtime worker scaling)
```

The LockManager optimization is significant: instead of N timers for N concurrent jobs, a single timer per worker renews all active locks in one batch via the `extendLocks` Lua script. At 500 concurrency, this means 1 timer instead of 500.

> **Benefit**: `:telemetry.attach` adds zero-cost instrumentation — events are no-ops when unhandled.

</tab>
<tab title="Go">

**Design philosophy:** High-throughput, low-latency workloads with struct-based APIs and goroutine-per-job concurrency.

**Key design choices:**

- **Struct-based Queue and Worker.** `NewQueue` and `NewWorker` return structs that hold a `redis.Cmdable` interface (accepts both `*redis.Client` and `*redis.ClusterClient`), a `KeyBuilder`, a `ScriptLoader`, and an `EventEmitter`.
- **Goroutine-per-job with semaphore.** A counting semaphore (buffered channel) limits concurrent processing to `WorkerOptions.Concurrency`. Each active job gets its own heartbeat goroutine for lock extension.
- **Embedded Lua scripts via ScriptLoader.** Scripts from BullMQ v5.62.0 are Go string constants. The `ScriptLoader` uses EVALSHA with automatic NOSCRIPT fallback to EVAL.
- **Redis Cluster auto-detection.** Type assertion on `redis.Cmdable` determines whether to use hash-tagged keys. CRC16-CCITT slot calculation and `ValidateHashTags` verify Cluster correctness at startup.

```
Worker.Start()
└── polling loop (ticker-based)
     └── pickupJob()
          └── go processJob()            // goroutine per job
               ├── heartbeat.Start()     // goroutine: ticker-based lock extension
               ├── processor(ctx, job)   // user function
               └── heartbeat.Stop()
                    └── completer.Complete() or .Fail()

Shutdown: stop ticker → wait WaitGroup → stop heartbeat manager + stalled checker
```

The `KeyBuilder` automatically switches between `bull:queueName:suffix` (standalone) and `bull:{queueName}:suffix` (Cluster) based on the detected client type.

> **Benefit**: `redis.ClusterClient` with automatic CRC16 hash tag detection handles sharded Redis.

</tab>
<tab title="Node.js">

**Design philosophy:** BullMQ is THE reference implementation. EchoMQ Node.js IS BullMQ — the npm package `bullmq` v5.x unchanged.

**Key design choices:**

- **Class-based API.** `Queue`, `Worker`, `QueueEvents`, and `FlowProducer` are ES6 classes with constructor-based configuration.
- **Event loop + async/await.** Concurrency is cooperative: jobs run as async functions on the single event loop. CPU-bound work blocks the loop and prevents lock renewal.
- **ioredis client.** Connection management, reconnection, Cluster support, and pipelining are handled by ioredis. `maxRetriesPerRequest: null` is required for Workers (unlimited retry).
- **QueueEvents for observability.** A dedicated class subscribes to Redis Streams via blocking XREAD, emitting Node.js EventEmitter events.

```
Node.js Process
├── Event Loop
│   ├── Worker (polling Redis for jobs)
│   │   ├── async processor(job)    // runs on event loop
│   │   ├── Lock renewal timer      // setInterval, per-job
│   │   └── Stalled check timer     // setInterval, periodic
│   ├── QueueEvents (blocking XREAD)
│   │   └── EventEmitter → listener callbacks
│   └── Queue (stateless operations)
└── ioredis
    ├── Main connection (commands)
    └── Blocking connection (XREAD, auto-created)
```

BullMQ Workers automatically create a second (duplicate) ioredis connection for blocking operations. This is why `QueueEvents` and `Worker` cannot fully share a single connection with non-blocking classes like `Queue`.

> **Benefit**: `ioredis` Cluster mode auto-discovers nodes and redirects commands transparently.

</tab>
</tabs>

## 10.4. Concurrency Models Compared

The three runtimes handle concurrent job processing with fundamentally different primitives:

| Aspect | Elixir (BEAM) | Go (goroutines) | Node.js (event loop) |
|--------|---------------|-----------------|---------------------|
| **Unit of concurrency** | BEAM process (~2KB) | Goroutine (~8KB) | Async function (shared heap) |
| **Scheduling** | Preemptive (per-reduction) | Cooperative (goroutine yield) | Cooperative (await points) |
| **Max concurrent jobs** | Millions of processes | ~100K goroutines | ~CPU cores (practical) |
| **CPU-bound safety** | Lock renewal unaffected | Lock renewal unaffected | Lock renewal BLOCKED |
| **Memory isolation** | Full (per-process heap) | Partial (shared memory, goroutine stack) | None (shared V8 heap) |
| **Creation overhead** | ~3 microseconds | ~1 microsecond | N/A (same thread) |

**The CPU-bound problem** is the most significant practical difference. In a game engine, CPU-intensive operations like damage calculation, pathfinding, or anti-cheat analysis are common. In Node.js, these processor functions block the event loop, preventing lock renewal timers from firing — the job appears stalled even though it is still running. BullMQ's documentation explicitly warns about this. In Elixir and Go, lock renewal runs on separate scheduling units (BEAM schedulers or goroutines) and cannot be starved by application code, making them safer choices for compute-heavy game logic.

**Lock renewal strategy** also differs:

| Strategy | Elixir | Go | Node.js |
|----------|--------|-----|---------|
| Timer count | 1 per worker (batch) | 1 per active job | 1 per active job |
| Script used | `extendLocks` (bulk) | `extendLock` (single) | `extendLock` (single) |
| At 500 concurrency | 1 timer | 500 goroutines | 500 setInterval timers |

## 10.5. Failure Handling Compared

Each runtime recovers from failures through different mechanisms, but all rely on the same underlying Redis protocol: lock expiry triggers stall detection, which requeues the job.

| Failure Scenario | Elixir Recovery | Go Recovery | Node.js Recovery |
|-----------------|-----------------|-------------|------------------|
| **Job processor crash** | BEAM process exits; worker GenServer continues; job lock expires; stalled checker requeues | Goroutine panics (recovered); worker continues polling; stalled checker requeues | Uncaught exception caught by Worker; job moved to failed; retried if attempts remain |
| **Worker process death** | OTP supervisor restarts worker; in-flight jobs become stalled; recovered within stalledInterval | `sync.WaitGroup` for graceful shutdown; ungraceful death → stalled recovery | PM2/K8s restarts process; stalled jobs recovered by other workers |
| **Redis connection loss** | Redix auto-reconnects with configurable backoff; operations fail with `{:error, reason}` | go-redis retries with exponential backoff (100ms-30s); worker pauses pickup | ioredis auto-reconnects; `maxRetriesPerRequest: null` retries indefinitely |
| **Lock renewal failure** | LockManager crash → linked worker terminates → supervisor restarts both | Heartbeat goroutine logs failure; job continues; may be requeued as stalled | Timer failure logged; job continues; may be requeued as stalled |
| **Node/machine failure** | Surviving BEAM nodes continue (distributed Erlang); no single point of failure | Other worker processes continue; stalled jobs redistributed | Other worker processes continue; stalled jobs redistributed |

**Elixir's structural advantage**: OTP supervision trees make crash recovery declarative rather than imperative. A crashing job processor never takes down other jobs or the worker — fault isolation is enforced by the VM, not by application error handling.

**Go's pragmatic approach**: `sync.WaitGroup` ensures graceful shutdown waits for in-flight jobs. The `ShutdownTimeout` option (default 30s) caps how long the worker waits before force-stopping.

**Node.js's trade-off**: Single-threaded design means a truly catastrophic failure (segfault, OOM kill) loses all in-flight jobs simultaneously. Recovery depends entirely on external process managers and the stalled checker running on other worker instances.

## 10.6. Performance Characteristics

For a game engine like Fireheadz Arena, performance characteristics directly impact player experience. Combat action queues demand low latency (players feel delays above ~100ms), matchmaking needs sustained throughput during peak hours, and analytics pipelines require bulk processing without starving real-time queues.

### When to Choose Each Runtime

**Choose Elixir when:**
- Fault tolerance is a primary requirement (game state must never be lost mid-match)
- You need thousands of concurrent jobs with sub-millisecond scheduling overhead (e.g., per-player combat actions at scale)
- Hot code reload for zero-downtime deployment of game logic updates
- Distributed coordination across nodes is needed (`:pg` process groups for cross-region matchmaking, Erlang distribution)
- CPU-bound job processors are common and must not block lock renewal (damage calculations, pathfinding, anti-cheat analysis)

**Choose Go when:**
- Raw throughput and low latency are priorities (leaderboard recalculation, analytics pipelines)
- You want minimal runtime overhead and small binary size (sidecar workers in a containerized game infrastructure)
- The system is a microservice in a larger Go ecosystem (game backend services)
- Redis Cluster is required (auto-detection and CRC16 validation built in)
- Goroutine-per-job model fits your concurrency needs (batch world-sync operations)

**Choose Node.js (BullMQ) when:**
- You need the battle-tested reference implementation with the most mature ecosystem
- The BullMQ ecosystem (BullBoard, Taskforce.sh) is important for monitoring game queues
- Jobs are primarily I/O-bound (HTTP calls to external APIs, database queries, webhook delivery)
- Your team has deep TypeScript/JavaScript expertise
- You want the most complete feature set (flows, schedulers, rate limiting all production-ready)

### Benchmark Reference

| Configuration | Elixir | Go | Node.js |
|--------------|--------|-----|---------|
| No-op job throughput (1 worker) | ~4,100 j/s | ~2,800 j/s | ~3,000 j/s |
| Bulk enqueue (parallel) | ~58,000 j/s (8 conns) | ~30,000 j/s (goroutines) | ~20,000 j/s |
| Memory per concurrent job | ~2KB | ~8KB | Shared heap |
| RTTs per job lifecycle | 4 (Lua scripts) | 11-14 (partial Lua) | 4 (Lua scripts) |

> **Note on Go RTTs**: EchoMQ Go v0.1.1 uses separate Redis commands for critical-path operations instead of Lua scripts, resulting in 7-10 extra round trips per job. The Go benchmark figures above reflect this overhead — throughput will improve significantly once v0.2.0 achieves full Lua script integration and the same 4 RTTs as Elixir and Node.js. For latency-sensitive game queues like `combat-actions`, this RTT gap matters most at high concurrency. See [Go Implementation](ch05-go-architecture.md) for the atomicity gap details.

## 10.7. What's Next

- **[Connections & Configuration](ch11-connections.md)** — Production-ready Redis connection setup for all three languages
- **[Unified Protocol](ch01-unified-protocol.md)** — The immutable protocol layers (L1 + L2)
- **[Redis Data Layer](ch02-redis-data-layer.md)** — Complete key taxonomy and data structures
- **[Elixir OTP Architecture](ch04-elixir-architecture.md)** — Deep dive into BEAM advantages and supervision trees
- **[Go Implementation](ch05-go-architecture.md)** — Current status, gap analysis, and v1.0 roadmap

---

*Previous: [Getting Started](ch09-getting-started.md) | Next: [Connections](ch11-connections.md)*
