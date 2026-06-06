# Chapter 08. Why EchoMQ?

## 8.1. The Polyglot Problem

Most job queue systems are single-language. Sidekiq serves Ruby, Celery serves Python, Oban serves Elixir, and BullMQ serves Node.js. When your architecture spans multiple runtimes — a common reality in game backends where real-time services, matchmaking, and analytics each demand different strengths — you face an unpleasant choice: pick one queue system and build adapters for every other language, or run multiple queue systems with synchronization overhead between them.

EchoMQ eliminates this problem. A Go microservice can enqueue a damage calculation that an Elixir worker processes at 60 ticks per second, while a Node.js dashboard streams combat events in real-time. All three runtimes share the same Redis instance, the same data structures, the same atomic Lua scripts, and the same event stream.

```
                    ┌──────────────────────────────┐
                    │      Shared Redis Instance    │
                    │                               │
                    │  Lua Scripts   Redis Data     │
                    │  (atomic)      Layer          │
                    │                               │
                    │  Event Streams (observability) │
                    └──────┬──────────┬──────┬──────┘
                           │          │      │
                    ┌──────┴───┐ ┌────┴───┐ ┌┴──────────┐
                    │  EchoMQ  │ │ EchoMQ │ │  EchoMQ   │
                    │  Elixir  │ │ Go     │ │  Node.js  │
                    │  (OTP)   │ │ (grtn) │ │  (=BullMQ)│
                    └──────────┘ └────────┘ └───────────┘
```

This is not a theoretical design. EchoMQ formalizes an insight that already exists in the wild: the BullMQ Lua scripts define a wire protocol. Any implementation that executes those scripts against the same Redis data structures is protocol-compatible, regardless of the host language.

---

## 8.2. Three Runtimes, Three Strengths

Each EchoMQ runtime brings distinct advantages to the table. In a game backend, choosing which runtime processes which queues is an architectural decision driven by workload characteristics, not a language-war argument.

| Dimension | Elixir (BEAM) | Go | Node.js |
|-----------|--------------|-----|---------|
| **Concurrency model** | Millions of lightweight processes | Goroutine-per-job with semaphore | Event loop + async/await |
| **Memory per job** | ~2 KB (BEAM process) | ~8 KB (goroutine) | Shared event loop (~30-50 MB per OS process) |
| **CPU-bound work** | Preemptive scheduling — never stalls | Goroutines yield at I/O — can block | Blocks the event loop |
| **Fault isolation** | Per-process — crash one, others continue | Per-goroutine with recovery | Shared — one crash affects all |
| **Supervision** | Built-in OTP supervision trees | Manual goroutine lifecycle | External (PM2, Kubernetes) |
| **Hot code reload** | Native — update logic without restart | Binary replacement required | Process restart required |
| **Ecosystem** | Phoenix LiveView dashboards, Telemetry | Static binaries, low ops overhead | BullMQ origin, Bull Board UI |
| **Best for** | High-concurrency fault-tolerant processing | Raw throughput, static typing | Dashboard tooling, rapid prototyping |

### Elixir: Fault Isolation for Combat Processing

The BEAM virtual machine was designed for telecom switches requiring 99.9999999% uptime. Each job runs in its own lightweight process (~2 KB overhead, ~1 us spawn time). When processing thousands of combat actions per second, a crash in one player's damage calculation never takes down other players' actions. OTP supervision trees provide automatic restart, backoff, and escalation without external tooling.

The LockManager optimization in EchoMQ Elixir is a direct consequence of this architecture: instead of N timers for N concurrent combat jobs, a single GenServer renews all active locks in one batch — eliminating timer explosion during peak battle events when hundreds of players attack simultaneously.

The BEAM scheduler also guarantees fairness through preemptive scheduling. A computationally expensive pathfinding job for one NPC cannot starve the lock renewal timers that keep other players' combat actions alive. After ~4,000 reductions (operations), the scheduler forcibly rotates to the next process.

### Go: Throughput for Bulk Operations

Go's goroutine-per-job model delivers high throughput with minimal operational complexity. For queue workloads like leaderboard recalculation, analytics aggregation, or batch inventory processing, a single statically-linked binary deploys anywhere without runtime dependencies. Static typing catches protocol mismatches at compile time.

Redis Cluster support with automatic CRC16 hash tag detection makes it production-ready for sharded environments — critical when your player base grows beyond what a single Redis instance can serve.

The embedded Lua scripts from BullMQ v5.62.0 ensure atomic operations — the ScriptLoader caches SHA1 hashes and falls back to full EVAL on Redis restart.

### Node.js: Origin and Ecosystem

Node.js BullMQ IS the reference implementation. EchoMQ does not fork or modify it — it pins to a specific version and extracts the Lua scripts and Redis conventions as the shared protocol definition. The npm ecosystem provides mature tooling: Bull Board for visual dashboards showing combat queue throughput, BullMQ Pro for commercial features like rate-limited matchmaking, and thousands of community integrations.

For game backends, Node.js excels as the dashboard and tooling layer — game masters can monitor queue health, inspect failed jobs, and retry stuck player actions through Bull Board without touching production code.

---

## 8.3. The Protocol Insight

> **The Golden Rule**: If two implementations execute the same Lua scripts against the same Redis data structures with the same field names, they are protocol-compatible. Everything above the script layer can vary freely.

EchoMQ's architecture follows a 4-layer model where the bottom two layers are immutable across all implementations:

| Layer | Name | Scope | Mutability |
|-------|------|-------|------------|
| **L0** | Redis Engine | Redis 6.0+ / Redis Cluster | External |
| **L1** | Redis Data Layer | Key naming, data structures, field names | **Immutable** |
| **L2** | Lua Script Layer | 53 main scripts + 60 includes | **Immutable** |
| **L3** | Script Executor | EVALSHA dispatch, msgpack encoding, SHA caching | Language-specific |
| **L4** | Language API | `Queue.add()`, `Worker.process()`, `Job.getState()` | Language-specific |

Layers L1 and L2 are extracted verbatim from BullMQ v5.62.0 (commit `6a31e0ae`). CI validates script checksums against upstream. This means protocol compatibility is not aspirational — it is mechanically enforced.

The consequence is powerful for game backends: your Go matchmaking service can enqueue a `create-lobby` job, your Elixir combat engine can process it alongside `calculate-damage` jobs, and your Node.js admin dashboard can query job status — all without adapters, bridges, or serialization translation.

---

## 8.4. Killer Features by Runtime

Different runtimes excel at different capabilities. This table shows where each implementation leads:

| Feature | Elixir | Go | Node.js |
|---------|--------|-----|---------|
| **True parallel processing** | Native (BEAM processes) | Native (goroutines) | Worker threads (limited) |
| **Supervision trees** | Built-in OTP | Manual goroutine lifecycle | External (PM2, K8s) |
| **Hot code reload** | Native (zero-downtime updates) | — | — |
| **Static binary deployment** | — | Native (single binary) | — |
| **Redis Cluster auto-detection** | — | Built-in (CRC16 + hash tags) | Via ioredis |
| **LiveView dashboards** | Zero-JS real-time UI | — | Bull Board |
| **Pattern matching dispatch** | Multi-clause function heads | switch/type assertions | if/else chains |
| **Telemetry integration** | Native `:telemetry` | Prometheus metrics | OpenTelemetry |
| **Distributed cancellation** | `:pg` process groups | — | Redis pubsub |
| **Dynamic worker scaling** | DynamicSupervisor | — | Process spawn |
| **Ecosystem maturity** | Growing | Growing | Production battle-tested |

### Features unique to Elixir

- **Process-per-job isolation**: Each combat action runs in a separate BEAM process. A memory leak in one player's damage calculation, an infinite loop in pathfinding, or a crash in buff application cannot affect any other job or the worker itself.
- **Preemptive scheduling**: The BEAM scheduler interrupts processes after ~4000 reductions. No job can monopolize the CPU — lock renewal timers run on separate schedulers and cannot be blocked, even during expensive world-sync operations.
- **Dynamic autoscaling**: Telemetry events drive DynamicSupervisor scaling. Workers spin up and down based on queue depth without external orchestration — when a tournament starts and combat actions spike, new workers spawn automatically.

### Features unique to Go

- **Cluster-first design**: Automatic Redis Cluster detection with CRC16 slot validation. Hash tags are applied transparently when a ClusterClient is detected.
- **Single-binary deployment**: No runtime dependencies. Copy one binary to the server and run it — ideal for deploying leaderboard workers or analytics processors alongside your game servers.
- **Results queue pattern**: `ProcessWithResults()` helper automatically forwards successful job results to a dedicated queue for downstream processing.

### Features unique to Node.js

- **Reference implementation**: The protocol definition itself. Every Lua script, every Redis key format, every field name originates from Node.js BullMQ.
- **Bull Board**: Production-ready visual dashboard for monitoring combat queues, inspecting failed matchmaking jobs, and retrying stuck player events.
- **BullMQ Pro**: Commercial features including groups, batches, and rate limiting extensions.

---

## 8.5. Architecture Comparison

How each runtime handles the core job processing patterns:

### Worker Concurrency

```
Elixir                    Go                        Node.js
─────────────────────     ─────────────────────     ─────────────────────
Worker GenServer          Worker struct              Worker instance
├── LockManager           ├── HeartbeatManager       ├── Event loop
├── Job Process 1         ├── goroutine 1            │   ├── Job 1 (async)
├── Job Process 2         ├── goroutine 2            │   ├── Job 2 (async)
├── Job Process 3         ├── goroutine 3            │   └── Job 3 (async)
└── ... (thousands)       └── ... (via semaphore)    └── (single thread)

Isolation: per-process    Isolation: per-goroutine   Isolation: none
Scheduling: preemptive    Scheduling: cooperative    Scheduling: run-to-yield
```

### Failure Recovery

| Failure Mode | Elixir | Go | Node.js |
|--------------|--------|-----|---------|
| **Job crashes** | Process dies, worker continues | Goroutine panics, recovered via defer | Uncaught exception crashes worker |
| **Worker crashes** | Supervisor restarts it automatically | Manual restart required | PM2/K8s restarts |
| **Lock expiration** | LockManager detects, cancels job | StalledChecker requeues | Stalled job recovery |
| **Redis disconnect** | Redix auto-reconnects | Exponential backoff reconnect | ioredis auto-reconnects |
| **Node failure** | Other BEAM nodes continue via `:pg` | Other instances continue | Other instances continue |

### Queue API Surface

<tabs>
<tab title="Elixir">

```elixir
# Stateless function calls — no GenServer needed for basic operations
{:ok, job} = EchoMQ.Queue.add("combat-actions", "calculate-damage",
  %{player_id: "PLR0K48QjihpC4", target_id: "NPC5rK2mJ9pQ1L", action: "attack", damage: 150},
  connection: :game_redis)

# Or use as supervised GenServer for queue management
{:ok, counts} = EchoMQ.Queue.get_counts("combat-actions", connection: :game_redis)
```

> **Benefit**: Named connections via `Redix` integrate into supervision trees — automatic reconnect on network partitions.

</tab>
<tab title="Go">

```go
// Struct-based — create once, reuse
queue := echomq.NewQueue("combat-actions", redisClient)

job, err := queue.Add(ctx, "calculate-damage",
    map[string]interface{}{
        "player_id": "PLR0K48QjihpC4",
        "target_id": "NPC5rK2mJ9pQ1L",
        "action":    "attack",
        "damage":    150,
    },
    echomq.JobOptions{})
```

> **Benefit**: Strongly-typed option structs catch misconfiguration at compile time.

</tab>
<tab title="Node.js">

```typescript
// Class-based — BullMQ standard API
const queue = new Queue("combat-actions", { connection: redisOpts });

const job = await queue.add("calculate-damage", {
  player_id: "PLR0K48QjihpC4",
  target_id: "NPC5rK2mJ9pQ1L",
  action: "attack",
  damage: 150,
});
```

> **Benefit**: `ioredis` connection with lazy initialization — Redis connects only when the first command is issued.

</tab>
</tabs>

---

## 8.6. Learning Paths

### For Node.js Developers

You already know BullMQ. Your path is about understanding what changes — and what stays identical — when adding Elixir or Go workers to your game backend.

| Step | Topic | Why |
|------|-------|-----|
| 1 | [Getting Started](ch09-getting-started.md) | Run your first polyglot combat queue |
| 2 | [Cross-Language Interop](ch06-cross-language-interop.md) | Understand wire compatibility |
| 3 | [Elixir Architecture](ch04-elixir-architecture.md) or [Go Architecture](ch05-go-architecture.md) | Pick your second language |

### For Elixir Developers

You know OTP and supervision trees. Your path is about applying those patterns to game job processing and understanding the shared protocol layer that lets you interop with Go and Node.js services.

| Step | Topic | Why |
|------|-------|-----|
| 1 | [Getting Started](ch09-getting-started.md) | Set up EchoMQ in your Phoenix game server |
| 2 | [Elixir Architecture](ch04-elixir-architecture.md) | Deep dive into OTP patterns for combat processing |
| 3 | [Unified Protocol](ch01-unified-protocol.md) | Understand the Lua script layer |

### For Go Developers

You want high-throughput job processing with minimal ceremony. Your path focuses on the Go API for leaderboard, analytics, and batch processing workloads, and understanding the protocol guarantees.

| Step | Topic | Why |
|------|-------|-----|
| 1 | [Getting Started](ch09-getting-started.md) | First queue and worker in Go |
| 2 | [Go Architecture](ch05-go-architecture.md) | Concurrency model and current status |
| 3 | [Redis Data Layer](ch02-redis-data-layer.md) | Understand what your jobs look like in Redis |

### For Game Architects

You are evaluating EchoMQ for a polyglot game backend. Your path covers protocol guarantees, operational characteristics, and the roadmap — the information you need to decide which runtime handles combat, matchmaking, inventory, and analytics.

| Step | Topic | Why |
|------|-------|-----|
| 1 | [Unified Protocol](ch01-unified-protocol.md) | Protocol compatibility guarantees |
| 2 | [Cross-Language Interop](ch06-cross-language-interop.md) | Feature matrix and known divergences |
| 3 | [Vision & Roadmap](ch07-vision-and-roadmap.md) | Where EchoMQ is heading |

---

## 8.7. Next Steps

Ready to write code? Continue to [Getting Started](ch09-getting-started.md) for a hands-on walkthrough where you create a combat action queue, enqueue a damage calculation, and process it with a worker — in all three languages.

---

*Previous: [Vision and Roadmap](ch07-vision-and-roadmap.md) | Next: [Getting Started](ch09-getting-started.md)*
