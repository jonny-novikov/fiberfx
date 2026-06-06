# Chapter 06. Cross-Language Interoperability

## 6.1. Feature Parity Matrix

This matrix reflects the **verified** implementation status after cross-validation by the Apollo evaluator. Go statuses are corrected per Director Decisions D-1 and D-2.

### Core Features

| Feature | Node.js | Go | Elixir | Notes |
|---------|:-------:|:--:|:------:|-------|
| **Job Addition** | Full | Implemented (non-atomic) | Full | Go uses separate commands |
| **Priority (0-2^21)** | Full | Implemented (wrong encoding) | Full | Go uses inverted scores |
| **Delay** | Full | Implemented (non-atomic) | Full | |
| **LIFO mode** | Full | No | Full | |
| **Bulk add** | Full | No | Full | |
| **Deduplication** | Full | No | Full | v5 feature |
| **Custom job ID** | Full | No | Full | Go uses UUID |
| **Worker processing** | Full | Implemented (non-atomic) | Full | |
| **Concurrency** | Full | Implemented | Full | Go: goroutine semaphore |
| **Global concurrency** | Full | No | Full | Via meta hash |
| **Lock management** | Full | Implemented | Full | Go: per-job goroutines |
| **Lock renewal** | Full | Implemented | Full | Elixir: bulk (1 timer), Go: per-job |
| **Stalled detection** | Full | Implemented (non-atomic) | Full | |
| **Rate limiting** | Full | No (out of scope) | Full | Lua script supports it |
| **Backoff (fixed/exp)** | Full | Implemented | Full | |
| **Backoff (custom)** | Full | No | Full | |

### Advanced Features

| Feature | Node.js | Go | Elixir | Notes |
|---------|:-------:|:--:|:------:|-------|
| **Flows (parent-child)** | Full | No | Full | FlowProducer |
| **Waiting-children** | Full | No | Full | |
| **failParentOnFailure** | Full | No | Full | |
| **Job Schedulers** | Full | No | Full | Cron/every patterns |
| **Pause/Resume** | Full | No | Full | |
| **Drain** | Full | No | Full | |
| **Progress update** | Full | Implemented (Lua) | Full | Go correctly uses Lua |
| **Job logs** | Full | Implemented (Lua) | Full | Go correctly uses Lua |
| **Events stream** | Full | Implemented | Full | XADD/XREAD |
| **removeOnComplete/Fail** | Full | Implemented | Full | |
| **Results queue pattern** | No | Extension | No | echomq-go unique |

### Infrastructure

| Feature | Node.js | Go | Elixir | Notes |
|---------|:-------:|:--:|:------:|-------|
| **Redis Cluster** | Full | Implemented | Unverified | |
| **Telemetry/OTel** | Full | Not yet | Full | Go has indirect deps |
| **Metrics collection** | Full | No | Partial | |
| **Sandboxed processors** | Full | N/A | N/A | Node.js specific |
| **Connection pooling** | ioredis | go-redis | Redix | |

## 6.2. Divergence Analysis

### Architecture Divergences

| Aspect | Node.js | Go | Elixir |
|--------|---------|-----|--------|
| Runtime | V8, single-threaded | Goroutines | BEAM processes |
| Redis client | ioredis | go-redis/v9 | Redix |
| Blocking wait | BZPOPMIN on marker | Ticker polling | GenServer loop |
| Lua script loading | `redis.defineCommand()` | EVALSHA with SHA cache | Redix command |
| msgpack library | Packr | vmihailenco/msgpack/v5 | Erlang term format |
| Concurrency limit | async/await interleaving | Semaphore (chan) | Process spawning |
| Lock renewal | Per-job timer | Per-job goroutine | **Single timer per worker** |
| Error handling | throw/catch | `(result, error)` tuple | `{:ok, result}` / `{:error, reason}` |

### API Naming Divergences

| Concept | Node.js | Go | Elixir |
|---------|---------|-----|--------|
| Add job | `queue.add(name, data, opts)` | `producer.Add(name, data, opts)` | `Queue.add(queue, name, data, opts)` |
| Process | `new Worker(name, processor)` | `worker.Process(handler)` | `Worker.start_link(processor: fn)` |
| Get state | `job.getState()` | `job.GetState()` | `Job.get_state(job)` |
| Options | `{ delay, priority }` | `JobOptions{ Delay, Priority }` | `[delay: _, priority: _]` |
| Success | `return value` | `return result, nil` | `{:ok, result}` |
| Failure | `throw new Error()` | `return nil, err` | `{:error, reason}` |

## 6.3. Critical Interop Issues

### Issue 1: Compressed Field Names (CRITICAL)

**Problem**: Go writes `attemptsMade`, Node.js/Elixir read `atm`.

**Impact**: Jobs created by Go appear to have 0 attempts when consumed by Node.js/Elixir workers → **infinite retry loop**.

**Fields affected**:

| Go (current) | Protocol (required) |
|--------------|-------------------|
| `attemptsMade` | `atm` |
| (not set) | `ats` |
| (not set) | `stc` |
| (not set) | `pb` |

**Resolution**: Change Go JSON struct tags to compressed names. The Lua scripts already use compressed names, so this fix is needed regardless of Lua integration.

### Issue 2: msgpack Encoding (CRITICAL)

**Problem**: BullMQ Lua scripts call `cmsgpack.unpack(ARGV[n])` to decode complex arguments. Go must produce msgpack output binary-compatible with Redis's built-in cmsgpack.

**Status**: Go has `vmihailenco/msgpack/v5` (v5.4.1) and uses it for progress/logs. The library exists — the gap is in extending usage to critical-path ARGV encoding.

**Risk**: Subtle binary format differences between Go's msgpack and Redis's cmsgpack could cause silent data corruption. Example risks:
- Integer encoding (fixint vs int32)
- Map key ordering
- Float precision
- Nil encoding

**Mitigation**: Round-trip test suite — Go encode → Redis → Lua cmsgpack.unpack → verify.

### Issue 3: Non-Atomic Operations (HIGH)

**Problem**: Go uses separate Redis commands where the protocol requires atomic Lua scripts.

**Impact in mixed deployments**: When Go and Node.js workers share a queue:
- Go's non-atomic pickup can race with Node.js's atomic pickup
- Go's non-atomic completion can leave jobs in inconsistent states
- Stalled recovery can interfere with active processing

**Resolution**: Wire Go to use embedded Lua scripts (Milestone 1).

### Issue 4: Priority Encoding (MEDIUM)

**Problem**: Go uses negative ZADD scores (higher priority = more negative). BullMQ Lua scripts use the `pc` priority counter for ordering.

**Impact**: Jobs enqueued by Go sort differently in the prioritized ZSET compared to Node.js-enqueued jobs.

**Resolution**: Automatically fixed when `addPrioritizedJob` Lua script is integrated (D-6).

### Issue 5: Job.Data Type (LOW)

**Problem**: Go uses `map[string]interface{}` which deserializes JSON. Node.js preserves raw JSON.

**Impact**:
- Go re-serializes with potentially different key ordering
- `float64` conversion for large integers (> 2^53) causes precision loss
- Nested structures lose original representation

**Resolution**: Consider migration to `json.RawMessage` for round-trip fidelity.

## 6.4. Multi-Language Coordination Patterns

### Pattern 1: Language-Specialized Workers

<tabs>
<tab title="Elixir">

```elixir
# Elixir worker handles fan-out and real-time streaming
{EchoMQ.Worker,
  name: :media_worker,
  queue: "media-processing",
  connection: :redis,
  processor: fn
    %EchoMQ.Job{name: "stream-fanout", data: data} ->
      EchoMQ.FlowProducer.add(%{
        name: "distribute",
        queue_name: "media-processing",
        children: Enum.map(data["targets"], &stream_child/1)
      }, connection: :redis)
    %EchoMQ.Job{name: "notify", data: data} ->
      Phoenix.PubSub.broadcast(Echo.PubSub, "media:#{data["id"]}", {:done, data})
  end,
  concurrency: 500}
```

</tab>
<tab title="Go">

```go
// Go worker handles CPU-intensive image processing
worker := echomq.NewWorker("media-processing", redisClient, echomq.WorkerOptions{
    Concurrency: runtime.NumCPU(),
})
worker.Process(func(ctx context.Context, job *echomq.Job) (interface{}, error) {
    switch job.Name {
    case "resize-image":
        return resizeImage(job.Data["path"].(string), job.Data["width"].(float64))
    case "generate-thumbnail":
        return generateThumbnail(job.Data["path"].(string))
    default:
        return nil, nil // Not our job type — skip
    }
})
worker.Start(ctx)
```

</tab>
<tab title="Node.js">

```typescript
// Node.js worker handles FFmpeg-based video transcoding
const worker = new Worker('media-processing', async (job) => {
  switch (job.name) {
    case 'transcode-video':
      return await ffmpeg.transcode(job.data.path, job.data.format);
    case 'extract-audio':
      return await ffmpeg.extractAudio(job.data.path);
    default:
      return null; // Not our job type
  }
}, { connection: { host: 'localhost' }, concurrency: 4 });
```

</tab>
</tabs>

All three workers share the same queue, same Redis, same Lua scripts. The job `name` field routes to the appropriate handler in each language.

### Pattern 2: Cross-Language Flows

<tabs>
<tab title="Elixir">

```elixir
# Elixir creates the flow — children processed by any language's workers
{:ok, flow} = EchoMQ.FlowProducer.add(%{
  name: "generate-report",
  queue_name: "reports",
  data: %{report_id: "RPT-42"},
  children: [
    %{name: "crunch-numbers", queue_name: "compute", data: %{report_id: "RPT-42"}},
    %{name: "send-notifications", queue_name: "notify", data: %{report_id: "RPT-42"}},
    %{name: "render-pdf", queue_name: "render", data: %{report_id: "RPT-42"}}
  ]
}, connection: :redis)
# Go worker picks up "crunch-numbers", Elixir picks up "send-notifications",
# Node.js picks up "render-pdf". Parent completes when all children done.
```

</tab>
<tab title="Go">

```go
// Go does not yet support FlowProducer — use Elixir or Node.js
// to create the flow. Go workers consume child jobs from their queue:
worker := echomq.NewWorker("compute", redisClient, echomq.WorkerOptions{
    Concurrency: runtime.NumCPU(),
})
worker.Process(func(ctx context.Context, job *echomq.Job) (interface{}, error) {
    // "crunch-numbers" child job arrives here
    return crunchNumbers(job.Data)
})
```

</tab>
<tab title="Node.js">

```typescript
// Node.js creates the flow via FlowProducer
const flowProducer = new FlowProducer({ connection: { host: 'localhost' } });
const flow = await flowProducer.add({
  name: 'generate-report',
  queueName: 'reports',
  data: { reportId: 'RPT-42' },
  children: [
    { name: 'crunch-numbers', queueName: 'compute', data: { reportId: 'RPT-42' } },
    { name: 'send-notifications', queueName: 'notify', data: { reportId: 'RPT-42' } },
    { name: 'render-pdf', queueName: 'render', data: { reportId: 'RPT-42' } },
  ],
});
```

</tab>
</tabs>

### Pattern 3: Polyglot Migration

<tabs>
<tab title="Elixir">

```elixir
# Phase 2: Shadow Elixir worker alongside existing Node.js worker
# Both consume from the same queue — Elixir validates results
{EchoMQ.Worker,
  name: :shadow_worker,
  queue: "orders",
  connection: :redis,
  processor: fn job ->
    result = MyApp.Orders.process(job)
    # Log for comparison — don't affect production flow
    Logger.info("Shadow result for #{job.id}: #{inspect(result)}")
    {:ok, result}
  end,
  concurrency: 10}
```

</tab>
<tab title="Go">

```go
// Phase 3: Go worker becomes primary, Node.js still running as fallback
worker := echomq.NewWorker("orders", redisClient, echomq.WorkerOptions{
    Concurrency: 50,
})
worker.Process(func(ctx context.Context, job *echomq.Job) (interface{}, error) {
    return processOrder(ctx, job.Data)
})
worker.Start(ctx)
// Node.js worker still running — processes any jobs Go doesn't pick up first
```

</tab>
<tab title="Node.js">

```typescript
// Phase 1: Pure Node.js — the starting point
const queue = new Queue('orders', { connection: { host: 'localhost' } });
const worker = new Worker('orders', async (job) => {
  return processOrder(job.data);
}, { connection: { host: 'localhost' }, concurrency: 10 });

// Phase 4: Node.js retired — Go/Elixir handle everything
// Just stop the Node.js worker. No protocol changes needed.
```

</tab>
</tabs>

This pattern allows incremental language migration with zero downtime. Because EchoMQ is protocol-compatible, you can run workers in both languages simultaneously against the same queue.

## 6.5. Testing Strategy

### Level 1: Unit Tests (Per Implementation)

- Verify key format generation matches specification
- Verify job hash serialization with compressed field names
- Verify error code handling matches enum
- Verify msgpack encoding matches expected binary format

### Level 2: Integration Tests (Per Implementation)

- Execute each Lua script against real Redis
- Verify Redis state after each operation
- Verify event stream entries match expected format

### Level 3: Cross-Language Tests (Across Implementations)

| Producer | Consumer | Verify |
|----------|----------|--------|
| Node.js | Go | Job data integrity, state transitions |
| Go | Elixir | Field name compatibility, result format |
| Elixir | Node.js | Flow parent-child, event propagation |
| Mixed | Mixed | Concurrent workers on same queue |

### Level 4: Chaos Tests

| Scenario | Verify |
|----------|--------|
| Kill worker mid-processing | Stalled recovery → no job loss |
| Redis disconnect/reconnect | No duplicate processing |
| Mixed-version deployment | Cross-version compatibility |
| Network partition | Lock expiry and recovery |

## 6.6. Risk Register

| Risk | Severity | Owner | Mitigation |
|------|----------|-------|------------|
| msgpack binary incompatibility (Go vs cmsgpack) | CRITICAL | Go team | Round-trip test suite before Lua integration |
| EchoMQ may lack working source code | HIGH | Director | Commission source-level audit |
| No cross-language test coverage | HIGH | All teams | Implement Level 3 test plan |
| Go Job.Data type causes precision loss | MEDIUM | Go team | Evaluate json.RawMessage migration |
| Feature matrix misleads planning | MEDIUM | Director | This document corrects it (D-1, D-2) |
| go.mod vs import path inconsistency | LOW | Go team | Fix during next PR |

---

*Previous: [Go Architecture](ch05-go-architecture.md) | Next: [Vision and Roadmap](ch07-vision-and-roadmap.md)*
