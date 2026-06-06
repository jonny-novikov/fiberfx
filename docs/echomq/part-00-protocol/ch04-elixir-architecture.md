# Chapter 04. Elixir OTP Architecture

## 4.1. Design Philosophy

EchoMQ (the Elixir implementation) makes a deliberate architectural choice: **let Redis own all queue state and let OTP own all process lifecycle.** This separation produces a system where the Elixir layer is a thin, highly-concurrent execution engine over the Redis protocol — no local state to synchronize, no single points of failure.

## 4.2. BullMQ-to-OTP Concept Mapping

### Queue: Stateless Functions (Not GenServer)

Unlike Node.js where `new Queue(...)` creates a class instance holding configuration, EchoMQ's `EchoMQ.Queue` module provides **pure function calls** that take a connection reference:

<tabs>
<tab title="Elixir">

```elixir
# No GenServer, no state — just a function call
{:ok, job} = EchoMQ.Queue.add("emails", "send-welcome", %{to: "user@example.com"},
  connection: :my_redis)
```

</tab>
<tab title="Go">

```go
// Struct-based — Queue holds redis.Cmdable, KeyBuilder, ScriptLoader
queue := echomq.NewQueue("emails", redisClient)
job, err := queue.Add(ctx, "send-welcome", map[string]interface{}{
    "to": "user@example.com",
}, echomq.JobOptions{})
```

</tab>
<tab title="Node.js">

```typescript
// Class instance — holds ioredis connection and configuration
const queue = new Queue('emails', { connection: { host: 'localhost' } });
const job = await queue.add('send-welcome', { to: 'user@example.com' });
```

</tab>
</tabs>

Because Redis holds all queue state, the Elixir layer does not need a stateful process. The connection is a named Redix process in the supervision tree. Queue operations are atomic Lua script invocations. This eliminates an entire class of bugs around stale local state and makes the Queue API naturally concurrent-safe.

| Node.js BullMQ | EchoMQ Elixir | OTP Pattern |
|----------------|-----------------|-------------|
| `new Queue(name, opts)` | `BullMQ.Queue.add/4` (stateless) | Module functions + Redix connection |
| `queue.add(name, data, opts)` | `BullMQ.Queue.add(queue, name, data, opts)` | Direct Lua script invocation |
| `queue.getJobCounts()` | `BullMQ.Queue.get_counts(queue, connection:)` | Stateless query |
| `queue.pause()` / `resume()` | `BullMQ.Queue.pause/2` / `resume/2` | Redis state mutation |

### Worker: GenServer with BEAM Process Pool

The Worker is where OTP shines most visibly. Each `BullMQ.Worker` is a **GenServer** that:

1. **Owns its Redis connection** for parallel job fetching
2. **Spawns BEAM processes** for concurrent job execution (one per active job)
3. **Manages a LockManager** (linked GenServer) for lock renewal
4. **Integrates into the supervision tree** for automatic restart on failure

```
Worker GenServer (coordinator)
├── LockManager (linked GenServer, single timer for ALL active jobs)
├── Job Task Process 1 → Running processor function
├── Job Task Process 2 → Running processor function
├── Job Task Process 3 → Running processor function
└── ... up to concurrency limit
```

The concurrency model is fundamentally different from Node.js:

| Aspect | Node.js | Elixir |
|--------|---------|--------|
| Concurrency model | async/await on single thread | N independent BEAM processes |
| CPU-bound jobs | Blocks event loop → stalls | Preemptively scheduled → never stalls |
| Per-worker overhead | ~30-50MB (OS process) | ~2KB (BEAM process) |
| Max concurrent jobs | ~CPU cores | Thousands |
| Lock renewal during CPU work | Blocked | Runs on separate scheduler |

### The LockManager Optimization

Instead of N timers for N concurrent jobs (timer explosion at high concurrency), a **single timer per worker** renews all active job locks in one batch:

- At 500 concurrency: 1 timer vs 500 timers
- Uses the `extendLocks` Lua script for atomic bulk renewal
- Dramatically reduces timer overhead

### FlowProducer: Stateless Atomic Operations

Like Queue, the FlowProducer is stateless. Flow definitions are trees of job descriptors added atomically:

<tabs>
<tab title="Elixir">

```elixir
{:ok, flow} = EchoMQ.FlowProducer.add(%{
  name: "deploy",
  queue_name: "deploy",
  children: [
    %{name: "build", queue_name: "build", children: [
      %{name: "compile", queue_name: "build"},
      %{name: "test", queue_name: "test"}
    ]},
    %{name: "infra", queue_name: "infra"}
  ]
}, connection: :my_redis)
```

</tab>
<tab title="Go">

```go
// Go does not yet implement FlowProducer (see roadmap).
// Flows are a future milestone — currently use Node.js or Elixir
// for flow creation in mixed-language deployments.
```

</tab>
<tab title="Node.js">

```typescript
const flowProducer = new FlowProducer({ connection: { host: 'localhost' } });
const flow = await flowProducer.add({
  name: 'deploy',
  queueName: 'deploy',
  children: [
    { name: 'build', queueName: 'build', children: [
      { name: 'compile', queueName: 'build' },
      { name: 'test', queueName: 'test' },
    ]},
    { name: 'infra', queueName: 'infra' },
  ],
});
```

</tab>
</tabs>

### QueueEvents: GenServer with Redis Streams

`BullMQ.QueueEvents` is a GenServer that subscribes to Redis Streams. Two consumption patterns:

1. **Process subscription**: `{:bullmq_event, type, data}` messages to subscribed PIDs
2. **Handler module**: Implement `BullMQ.QueueEvents.Handler` behaviour

This maps natively to OTP message passing — where Node.js uses EventEmitter, Elixir uses process mailboxes.

## 4.3. Supervision Tree

```
Application Supervisor
├── Redix (named :my_redis)
├── BullMQ.Worker (:email_worker)
│   └── LockManager (linked)
│       └── Job Task processes...
├── BullMQ.Worker (:heavy_worker)
│   └── LockManager (linked)
│       └── Job Task processes...
├── BullMQ.QueueEvents (:task_events)
└── DynamicSupervisor (optional, for dynamic scaling)
    └── Dynamically spawned workers
```

### Fault Tolerance Semantics

| Failure | Recovery | Data Safety |
|---------|----------|-------------|
| **Worker crash** | Supervisor restarts it | Active jobs become stalled → recovered by stall detection |
| **LockManager crash** | Worker terminates (linked) → supervisor restarts both | Lock-lost cancellation fires for in-flight jobs |
| **Job Task crash** | Job moves to failed/delayed | Worker continues processing other jobs |
| **Redix crash** | All dependents receive error | Automatic reconnection via Redix |
| **Node failure** | Other nodes continue | Jobs redistributed to surviving workers |

## 4.4. BEAM Advantages

### Preemptive Scheduling

The BEAM scheduler preemptively interrupts processes after ~4000 reductions (~4000 function calls):

- **No stalled jobs from CPU-bound work.** Node.js BullMQ docs explicitly warn about CPU-intensive processors blocking the event loop and preventing lock renewal. In Elixir, the lock renewal timer runs on a separate scheduler — it cannot be blocked.
- **Fair scheduling across workers.** With 10 workers processing jobs, each gets fair CPU time without manual yield points.

### Lightweight Processes

| Metric | Node.js | Go | Elixir |
|--------|---------|-----|--------|
| Memory per concurrent job | ~30-50MB (OS thread/process) | ~8KB (goroutine) | ~2KB (BEAM process) |
| Max concurrent jobs | ~CPU cores | ~100K goroutines | ~1M processes |
| Creation time | ~100ms (fork) | ~1μs | ~3μs |
| Inter-worker communication | IPC/Redis | channels/mutex | Direct message passing |

### Concurrency at Scale: 10,000 Concurrent Jobs

The lightweight process model transforms large-scale job processing:

**Node.js** — scaling requires OS process clusters:

```
┌─────────────────────────────────────────────────────┐
│                   OS Process 1                       │
│  ┌─────────────────────────────────────────────┐   │
│  │           Single Event Loop                   │   │
│  │  Job 1 → Job 2 → Job 3 → ... → Job 100       │   │
│  │  (sequential within process)                  │   │
│  └─────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘
                         × 100 processes

Memory: ~100MB per process = 10GB total
Process manager: PM2/Kubernetes required
Failure isolation: None within process
```

**Elixir/BEAM** — all jobs in a single VM with per-job isolation:

```
┌─────────────────────────────────────────────────────┐
│                   BEAM VM (1 OS process)             │
│  ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐          │
│  │Job 1│ │Job 2│ │Job 3│ │Job 4│ │Job 5│   ...    │
│  └─────┘ └─────┘ └─────┘ └─────┘ └─────┘          │
│     ↓       ↓       ↓       ↓       ↓               │
│  ┌─────────────────────────────────────────────┐   │
│  │         Preemptive Scheduler                  │   │
│  │    (fair scheduling across all 10,000)       │   │
│  └─────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘

Memory: ~2KB per process = 20MB total
Process manager: Built-in supervisor
Failure isolation: Per-job
```

The 500x memory reduction and built-in per-job isolation make BEAM the natural runtime for high-concurrency job processing.

### Fault Isolation

BEAM process isolation means:
- A crashing job processor never takes down other jobs or the worker
- Exception handling is structural (`try/rescue/catch` for `raise`, `exit`, `throw`)
- "Let it crash" philosophy aligns with BullMQ's retry semantics
- OTP supervisors provide declarative restart policies

### Hot Code Reload

BEAM supports hot code swapping at the module level:
- Update processor logic without stopping workers
- No job loss during deployment (no graceful shutdown/restart cycle)
- Zero-downtime updates to job processing logic

This is impossible in Node.js (requires process restart) and impractical in Go (requires binary replacement).

### Distribution

BEAM natively supports distributed computing across nodes:

<tabs>
<tab title="Elixir">

```elixir
# Using :pg (process groups) for distributed cancellation
:pg.join(@group, {__MODULE__, queue_name}, worker_pid)

# Cancel across all nodes — no Redis pubsub needed
workers = :pg.get_members(@group, {__MODULE__, queue_name})
for worker <- workers, do: Worker.cancel_job(worker, job_id, reason)
```

</tab>
<tab title="Go">

```go
// Go requires external coordination for cross-node cancellation.
// Typical pattern: Redis pubsub channel per queue.
pubsub := redisClient.Subscribe(ctx, "cancel:"+queueName)
ch := pubsub.Channel()
for msg := range ch {
    // msg.Payload contains the job ID to cancel
    worker.CancelJob(msg.Payload)
}
```

</tab>
<tab title="Node.js">

```typescript
// Node.js also requires external coordination.
// BullMQ uses Redis pubsub internally for some operations,
// but cross-node cancellation needs explicit setup.
const subscriber = new Redis();
subscriber.subscribe(`cancel:${queueName}`);
subscriber.on('message', (channel, jobId) => {
  // Cancel the job via the Worker API
  worker.close(); // or implement per-job cancellation
});
```

</tab>
</tabs>

For Go or Node.js, this requires external coordination (Redis pubsub, gRPC). BEAM provides it as a runtime primitive.

### Pattern Matching for Job Routing

<tabs>
<tab title="Elixir">

```elixir
# Multi-clause function heads — compiled to dispatch tables
def process(%Job{name: "email", data: data}), do: send_email(data)
def process(%Job{name: "sms", data: data}), do: send_sms(data)
def process(%Job{name: "push", data: data}), do: send_push(data)
def process(%Job{name: name}), do: {:error, "Unknown: #{name}"}
```

</tab>
<tab title="Go">

```go
// Go uses a switch statement or handler map for job routing
func processor(ctx context.Context, job *echomq.Job) (interface{}, error) {
    switch job.Name {
    case "email":
        return sendEmail(job.Data)
    case "sms":
        return sendSMS(job.Data)
    case "push":
        return sendPush(job.Data)
    default:
        return nil, fmt.Errorf("unknown job: %s", job.Name)
    }
}
```

</tab>
<tab title="Node.js">

```typescript
// Node.js uses if/else or a handler map
const worker = new Worker('notifications', async (job) => {
  switch (job.name) {
    case 'email': return sendEmail(job.data);
    case 'sms':   return sendSMS(job.data);
    case 'push':  return sendPush(job.data);
    default:      throw new Error(`Unknown: ${job.name}`);
  }
});
```

</tab>
</tabs>

Compiled to efficient dispatch tables — no if/else chains or switch statements.

## 4.5. Performance Benchmarks

| Configuration | Throughput |
|--------------|-----------|
| 1 worker, 500 concurrency (no-op) | ~4,100 j/s |
| 5 workers, 500 concurrency each | ~12,400 j/s |
| 10 workers, 500 concurrency each | ~16,500 j/s |
| Bulk add, sequential (1 conn) | ~5,700 j/s |
| Bulk add, parallel (8 conn pool) | ~58,000 j/s |

These are infrastructure overhead numbers with no-op processors. Real I/O-bound workloads show even better scaling due to BEAM's efficient context switching during I/O waits.

## 4.6. Rename Status: BullMQex → EchoMQ (COMPLETED)

The rename from BullMQex to EchoMQ has been completed. The package directory has been moved from `phoenix/apps/bullmqex/` to `phoenix/apps/echomq/`, all Elixir source modules updated from `BullMQex.*` to `EchoMQ.*`, and Go package renamed from `pkg/bullmq/` to `pkg/echomq/`.

### What Changed

1. **Elixir source**: 53 files renamed — all `BullMQex.*` modules → `EchoMQ.*`
2. **Go package**: 51 files renamed — `pkg/bullmq/` → `pkg/echomq/`
3. **Directory renames**: `phoenix/apps/bullmqex/` → `phoenix/apps/echomq/`, `pkg/bullmq/` → `pkg/echomq/`
4. **Compressed field names**: 6 `atm` field references fixed across Go source

### What Did NOT Change (By Design)

- Redis key prefix remains `"bull"` — wire compatibility with Node.js BullMQ workers
- `@bullmq_version` variable name preserved — refers to upstream BullMQ version
- Lua scripts unchanged — shared protocol layer (L2) is immutable

### Backward Compatibility Matrix

| Concern | Strategy |
|---------|----------|
| Existing `BullMQ.*` module references | Deprecated aliases for 2 major versions |
| Redis key prefix (`bull:*`) | Keep `"bull"` default, `"echo"` opt-in |
| Node.js BullMQ interop | Preserved when using `"bull"` prefix |
| hex.pm package name | New `echomq`, `bullmq` deprecated |
| Lua scripts | Identical (shared with Node.js) |
| Job data format | Identical (JSON, same compressed schema) |

## 4.7. Elixir-Unique Features

| Feature | Description |
|---------|-------------|
| True parallelism | BEAM processes vs async/await — CPU-bound jobs do not stall |
| Supervision trees | `child_spec` for declarative lifecycle management |
| Pattern matching processors | Multi-clause function heads for job routing |
| Dynamic worker scaling | `DynamicSupervisor` for runtime worker spawn/kill |
| Distributed cancellation | `:pg` process groups for cluster-wide cancel |
| BrandedChamp integration | CHAMP trie data structure for typed job state |
| Cooperative cancellation | O(1) `receive after 0` pattern vs AbortSignal |
| Lock-loss auto-cancellation | Automatic cancel on lock renewal failure |
| Telemetry dual stack | Both Elixir `:telemetry` and OpenTelemetry |

## 4.8. Existing Phoenix Integration

The Phoenix application at `phoenix/apps/echo/` already contains:

| Component | Description |
|-----------|-------------|
| `Echo.QueueManager` | GenStage producer with priority queues (critical/high/normal/low) |
| `Echo.Workers.*` | Health checker, ready poller, rolling restart, supervisor |
| `EchoWeb.QueueLive` | LiveView queue monitoring page |
| `EchoWeb.MetricsLive` | LiveView metrics dashboard |
| `EchoWeb.CircuitBreakersLive` | Circuit breaker monitoring |
| `EchoWeb.WorkerSocket` | WebSocket channel for worker communication |

The existing `Echo.QueueManager` GenStage producer can be backed by EchoMQ, giving the system Redis persistence, cross-node distribution, and BullMQ ecosystem compatibility.

## 4.9. Known Gaps

| Gap | Status | Impact |
|-----|--------|--------|
| 6-field cron expressions | Not supported (5-field only) | Use `every: ms` for sub-minute |
| Sunday=0 in cron | Only Sunday=7 accepted | Minor scheduler drift risk |
| Redis Cluster support | Unverified | Production deployment constraint |
| Groups (BullMQ Pro feature) | Status unknown | May be docs-only |
| Dynamic concurrency update | Not documented | Cannot change concurrency at runtime |
| Source-level verification | Documentation-based analysis | Actual `.ex` source audit pending |

## 4.10. BEAM-Exclusive Capabilities

These capabilities require runtime features that only the BEAM provides — they are architecturally impossible in Node.js and impractical in Go:

| # | Capability | BEAM Feature | Node.js Equivalent |
|---|-----------|--------------|-------------------|
| 1 | Supervision-aware job routing | Supervisor health checks | External service mesh |
| 2 | Telemetry-driven autoscaling | `:telemetry` + DynamicSupervisor | Prometheus + K8s HPA |
| 3 | LiveView job observatory | Phoenix LiveView | Separate React app + WebSocket |
| 4 | Cross-runtime trace stitching | W3C Trace Context propagation | Manual OpenTelemetry |
| 5 | Process-per-job isolation | Lightweight BEAM processes | Shared event loop (see 4.4) |
| 6 | GenServer state machines | GenServer + supervision | External state machine libs |
| 7 | Hot config reload | Hot code swapping | Process restart required (see 4.4) |

Features 5 and 7 are covered in section 4.4 above. Feature 3 (LiveView) integrates with the Phoenix components listed in section 4.8. The remaining features are detailed below.

### Telemetry-Driven Autoscaling

EchoMQ uses Elixir's native `:telemetry` events to drive `DynamicSupervisor` scaling — the feedback loop runs in-process with sub-millisecond latency:

<tabs>
<tab title="Elixir">

```elixir
defmodule Echo.GameScaler do
  use GenServer

  @scale_up_threshold 100
  @scale_down_threshold 10

  def init(opts) do
    :telemetry.attach("scaler", [:echomq, :queue, :size], &handle_telemetry/4, nil)
    {:ok, %{supervisor: opts[:supervisor]}}
  end

  def handle_cast({:queue_size, count}, state) do
    workers = DynamicSupervisor.which_children(state.supervisor)
    cond do
      count > @scale_up_threshold ->
        DynamicSupervisor.start_child(state.supervisor, {EchoMQ.Worker, worker_opts()})
      count < @scale_down_threshold and length(workers) > 2 ->
        [{_, pid, _, _} | _] = workers
        GenServer.call(pid, :drain)
        DynamicSupervisor.terminate_child(state.supervisor, pid)
      true -> :ok
    end
    {:noreply, state}
  end
end
```

</tab>
<tab title="Go">

```go
// Go requires external metrics + external scaler.
// Typical pattern: Prometheus metrics + Kubernetes HPA.
//
// 1. Worker exposes /metrics endpoint with queue depth gauge
// 2. Prometheus scrapes every 15-30s (vs Elixir's sub-ms feedback)
// 3. K8s HPA scales pods based on custom metric
//
// The feedback loop spans 3 external systems with 30s+ latency.
```

</tab>
<tab title="Node.js">

```typescript
// Node.js requires external infrastructure for autoscaling:
// 1. StatsD/Prometheus client emits metrics
// 2. Prometheus stores and evaluates rules
// 3. Kubernetes HPA scales worker deployments
//
// No in-process DynamicSupervisor equivalent exists.
// Scaling means spawning/killing OS processes, not lightweight tasks.
```

</tab>
</tabs>

EchoMQ emits telemetry events that the scaler consumes in the same VM — no network hops, no external systems, sub-millisecond reaction time.

### Cross-Runtime Trace Stitching

In hybrid deployments (Elixir + Node.js + Go workers), EchoMQ propagates W3C Trace Context through Redis job metadata, producing unified distributed traces:

<tabs>
<tab title="Elixir">

```elixir
defmodule EchoMQ.Telemetry.OpenTelemetry do
  def on_job_start(job, _opts) do
    parent_ctx = extract_trace_context(job.opts[:trace_context])
    span = OpenTelemetry.start_span("job.process",
      parent: parent_ctx,
      attributes: [{"job.id", job.id}, {"job.name", job.name}]
    )
    {:ok, %{span: span}}
  end

  def on_job_complete(_job, result, %{span: span}) do
    OpenTelemetry.set_attribute(span, "job.result", inspect(result))
    OpenTelemetry.end_span(span)
  end
end
```

</tab>
<tab title="Go">

```go
// Go worker extracts trace context from job opts
func processWithTracing(ctx context.Context, job *echomq.Job) (interface{}, error) {
    if tc, ok := job.Opts["trace_context"].(map[string]interface{}); ok {
        if tp, ok := tc["traceparent"].(string); ok {
            ctx = otel.GetTextMapPropagator().Extract(ctx,
                propagation.MapCarrier{"traceparent": tp})
        }
    }
    ctx, span := otel.Tracer("echomq").Start(ctx, "job.process")
    defer span.End()
    return processJob(ctx, job)
}
```

</tab>
<tab title="Node.js">

```typescript
import { context, trace, propagation } from '@opentelemetry/api';

// Inject trace context when enqueuing
async function enqueueWithTrace(queue: Queue, data: any) {
  const span = trace.getTracer('app').startSpan('enqueue.task');
  const traceContext: Record<string, string> = {};
  propagation.inject(context.active(), traceContext);
  await queue.add('process', data, {
    trace_context: traceContext  // Propagated to Elixir/Go workers
  });
  span.end();
}
```

</tab>
</tabs>

The result is a single distributed trace spanning all three runtimes — visible in Jaeger or Zipkin without manual correlation:

```
Node.js Service
└─ enqueue.task (12ms)
    └─ redis.xadd (3ms)

Elixir Worker (trace context propagated)
└─ job.process (156ms)
    ├─ db.query (45ms)
    └─ http.request (98ms)
```

### GenServer State Machines for Complex Flows

OTP's GenServer provides native state machines with supervision — no external libraries needed:

<tabs>
<tab title="Elixir">

```elixir
defmodule Echo.MatchSaga do
  @moduledoc "State machine: lobby -> countdown -> active -> completed | abandoned"
  use GenServer

  defstruct [:match_id, :state, :players, :checkpoints]

  def init(match_id) do
    saga = load_checkpoint(match_id) || %__MODULE__{match_id: match_id, state: :lobby}
    {:ok, saga, {:continue, :advance}}
  end

  def handle_continue(:advance, saga) do
    case advance_state(saga) do
      {:ok, new_saga}            -> save_checkpoint(new_saga); {:noreply, new_saga, {:continue, :advance}}
      {:wait, new_saga, timeout} -> {:noreply, new_saga, timeout}
      {:done, final_saga}        -> {:stop, :normal, final_saga}
      {:error, reason, saga}     -> compensate(saga); {:stop, {:error, reason}, saga}
    end
  end

  defp advance_state(%{state: :lobby, players: p} = s) when length(p) >= 2, do: {:ok, %{s | state: :countdown}}
  defp advance_state(%{state: :lobby} = s), do: {:wait, s, 30_000}
  defp advance_state(%{state: :countdown} = s), do: {:ok, %{s | state: :active}}
  defp advance_state(%{state: :active} = s), do: {:wait, s, :infinity}

  defp compensate(%{state: :active} = s), do: abort_match(s); compensate(%{s | state: :lobby})
  defp compensate(%{state: :countdown} = s), do: notify_players(s, :cancelled); compensate(%{s | state: :lobby})
  defp compensate(%{state: :lobby}), do: :ok
end
```

</tab>
<tab title="Go">

```go
// Go uses explicit state + switch. No built-in supervision or checkpoint/restore.
type MatchSaga struct {
    MatchID string
    State   string // "lobby", "countdown", "active", "completed"
    Players []string
}

func (s *MatchSaga) Advance() error {
    switch s.State {
    case "lobby":
        if len(s.Players) >= 2 {
            s.State = "countdown"
            return s.Advance()
        }
        return nil // wait
    case "countdown":
        s.State = "active"
        return nil
    case "active":
        return nil // wait for completion
    default:
        return fmt.Errorf("unknown state: %s", s.State)
    }
}
// Compensation, checkpointing, and restart must be manually implemented.
```

</tab>
<tab title="Node.js">

```typescript
// Node.js requires external state machine libraries (XState).
// No native supervision, checkpointing, or crash recovery.
import { createMachine, interpret } from 'xstate';

const matchMachine = createMachine({
  id: 'match',
  initial: 'lobby',
  states: {
    lobby:     { on: { READY: 'countdown' } },
    countdown: { on: { START: 'active' } },
    active:    { on: { END: 'completed', FAIL: 'abandoned' } },
    completed: { type: 'final' },
    abandoned: { type: 'final' },
  },
});
// No crash recovery, no compensation, no supervisor restart.
const service = interpret(matchMachine).start();
```

</tab>
</tabs>

The Elixir version runs under supervision — if the process crashes, the supervisor restarts it and the checkpoint restores state. Compensation logic unwinds cleanly via pattern-matched state transitions.

## 4.11. When to Choose EchoMQ (Elixir)

| Requirement | EchoMQ Elixir | EchoMQ Go | Node.js BullMQ |
|------------|---------------|-----------|----------------|
| Fault-tolerant processing | Native (OTP supervisors) | Manual recovery | External (PM2/K8s) |
| Massive concurrency (1000+ jobs) | ~2KB per job process | ~8KB per goroutine | ~30MB per OS process |
| Zero-downtime deploys | Hot code reload | Binary replacement | Process restart |
| Real-time dashboards | LiveView (same codebase) | Separate frontend | Separate frontend |
| Polyglot interop | Wire-compatible via Redis | Wire-compatible | Reference implementation |
| CPU-bound workloads | Preemptive scheduling | Goroutine scheduling | Event loop blocking |

**Choose Elixir** when you need supervision trees, hot code reload, or massive concurrency.
**Choose Go** when you need minimal memory footprint and compiled binary deployment.
**Choose Node.js** when your team already uses JavaScript and needs ecosystem compatibility.

---

*Previous: [Job Lifecycle](ch03-job-lifecycle.md) | Next: [Go Architecture](ch05-go-architecture.md)*
