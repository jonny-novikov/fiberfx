# Chapter 30. Telemetry & Tracing

EchoMQ provides two complementary observability systems. **Elixir Telemetry** emits structured events within a single BEAM node for local metrics, logging, and Prometheus integration. **OpenTelemetry** propagates distributed traces across service boundaries through W3C Trace Context, letting you follow a combat action from the Phoenix controller that enqueued it, through Redis, to the worker that processed it -- even when the producer and consumer run in different languages.

This chapter covers the full telemetry event reference, OpenTelemetry setup with W3C context propagation, Jaeger integration for trace visualization, custom telemetry backends, and cross-language tracing patterns for the Fireheadz Arena.

## 30.1. Observability Stack

```
+-----------------------------------------------------------------------+
|                      OBSERVABILITY STACK                              |
+-----------------------------------------------------------------------+
|                                                                       |
|   +----------------------------+    +----------------------------+    |
|   |     ELIXIR TELEMETRY       |    |      OPENTELEMETRY         |    |
|   |                            |    |                            |    |
|   |  - Local per-node events   |    |  - Distributed traces      |    |
|   |  - Counters / histograms   |    |  - Cross-service spans     |    |
|   |  - :telemetry library      |    |  - W3C Trace Context       |    |
|   |  - Zero network overhead   |    |  - Context via Redis       |    |
|   +-------------+--------------+    +-------------+--------------+    |
|                 |                                  |                   |
|                 v                                  v                   |
|   +----------------------------+    +----------------------------+    |
|   |  Prometheus / Grafana      |    |  Jaeger / Zipkin /         |    |
|   |  StatsD / Datadog          |    |  Honeycomb / Grafana Tempo |    |
|   +----------------------------+    +----------------------------+    |
|                                                                       |
+-----------------------------------------------------------------------+
```

Use both systems together: **Telemetry** for aggregated metrics (dashboards, alerting, capacity planning) and **OpenTelemetry** for request-level tracing (debugging slow jobs, understanding cross-service flows, identifying bottlenecks).

## 30.2. Telemetry Event Reference

All events are prefixed with `[:echomq, ...]`. These events fire within the BEAM VM on the node where the action occurs. They are zero-cost when no handler is attached.

### Job Events

| Event | Measurements | Metadata |
|-------|--------------|----------|
| `[:echomq, :job, :add]` | `%{queue_time: native}` | `queue`, `job_id`, `job_name` |
| `[:echomq, :job, :start]` | `%{system_time: native}` | `queue`, `job_id`, `job_name`, `worker` |
| `[:echomq, :job, :complete]` | `%{duration: native}` | `queue`, `job_id`, `job_name`, `worker` |
| `[:echomq, :job, :fail]` | `%{duration: native}` | `queue`, `job_id`, `job_name`, `worker`, `error` |
| `[:echomq, :job, :retry]` | `%{attempt: int, delay: ms}` | `queue`, `job_id`, `job_name` |
| `[:echomq, :job, :progress]` | `%{progress: 0..100}` | `queue`, `job_id` |

### Worker Events

| Event | Measurements | Metadata |
|-------|--------------|----------|
| `[:echomq, :worker, :start]` | `%{concurrency: int}` | `queue`, `worker` |
| `[:echomq, :worker, :stop]` | `%{uptime: native}` | `queue`, `worker` |
| `[:echomq, :worker, :stalled_check]` | `%{recovered: int, failed: int}` | `queue` |

### Queue Events

| Event | Measurements | Metadata |
|-------|--------------|----------|
| `[:echomq, :queue, :pause]` | - | `queue` |
| `[:echomq, :queue, :resume]` | - | `queue` |
| `[:echomq, :queue, :drain]` | - | `queue` |

### Rate Limiting Events

| Event | Measurements | Metadata |
|-------|--------------|----------|
| `[:echomq, :rate_limit, :hit]` | `%{delay: ms}` | `queue` |

## 30.3. Attaching Telemetry Handlers

<tabs>
<tab title="Elixir">

EchoMQ provides convenience wrappers (`EchoMQ.Telemetry.attach/4` and `attach_many/4`) that automatically prefix event names with `[:echomq]`, plus you can use the raw `:telemetry` library directly.

```elixir
defmodule Arena.TelemetrySetup do
  @moduledoc "Attaches telemetry handlers for Arena combat monitoring."

  require Logger

  def setup do
    # Using EchoMQ convenience functions (auto-prefixed)
    EchoMQ.Telemetry.attach_many("arena-combat-logger", [
      [:job, :complete],
      [:job, :fail],
      [:job, :retry],
      [:rate_limit, :hit]
    ], &__MODULE__.handle_event/4)

    # Using raw :telemetry for fine-grained control
    :telemetry.attach(
      "arena-stalled-monitor",
      [:echomq, :worker, :stalled_check],
      &__MODULE__.handle_stalled/4,
      nil
    )
  end

  def handle_event([:echomq, :job, :complete], measurements, metadata, _config) do
    duration_ms = System.convert_time_unit(measurements.duration, :native, :millisecond)
    Logger.info("[combat] Job #{metadata.job_id} completed in #{duration_ms}ms",
      queue: metadata.queue, job_name: metadata.job_name)
  end

  def handle_event([:echomq, :job, :fail], _measurements, metadata, _config) do
    Logger.error("[combat] Job #{metadata.job_id} failed: #{inspect(metadata.error)}",
      queue: metadata.queue, job_name: metadata.job_name)
  end

  def handle_event([:echomq, :job, :retry], measurements, metadata, _config) do
    Logger.warning("[combat] Job #{metadata.job_id} retry ##{measurements.attempt}, delay #{measurements.delay}ms")
  end

  def handle_event([:echomq, :rate_limit, :hit], measurements, metadata, _config) do
    Logger.warning("[combat] Rate limit hit on #{metadata.queue}: #{measurements.delay}ms delay")
  end

  def handle_stalled(_, %{recovered: recovered, failed: failed}, %{queue: queue}, _) do
    if recovered > 0, do: Logger.info("[combat] #{recovered} stalled jobs recovered in #{queue}")
    if failed > 0, do: Logger.error("[combat] #{failed} stalled jobs failed in #{queue}")
  end
end

# Call from your Application.start/2:
Arena.TelemetrySetup.setup()
```

> **Benefit**: `:telemetry.attach` adds zero-cost instrumentation — events are no-ops when unhandled.

</tab>
<tab title="Go">

```go
// Feature: Telemetry Event System
//
// Not implemented in echomq-go. The Go package does not have a
// telemetry event bus. Use manual instrumentation in your processor
// function and the OpenTelemetry Go SDK for distributed tracing.
//
// Workaround:
//   Instrument your processor directly with logging and metrics:

import "log/slog"

func instrumentedCombatProcessor(ctx context.Context, job *echomq.Job) error {
    start := time.Now()
    slog.Info("[combat] job started",
        "job_id", job.ID,
        "job_name", job.Name,
        "queue", "combat-actions",
    )

    err := processCombatAction(ctx, job)
    duration := time.Since(start)

    if err != nil {
        slog.Error("[combat] job failed",
            "job_id", job.ID,
            "job_name", job.Name,
            "error", err.Error(),
            "duration_ms", duration.Milliseconds(),
        )
        return err
    }

    slog.Info("[combat] job completed",
        "job_id", job.ID,
        "job_name", job.Name,
        "duration_ms", duration.Milliseconds(),
    )
    return nil
}

// For structured events similar to :telemetry, use a simple event bus:
type TelemetryEvent struct {
    Name         string
    Measurements map[string]interface{}
    Metadata     map[string]interface{}
}

type EventBus struct {
    handlers map[string][]func(TelemetryEvent)
    mu       sync.RWMutex
}

func (b *EventBus) Attach(name string, handler func(TelemetryEvent)) {
    b.mu.Lock()
    defer b.mu.Unlock()
    b.handlers[name] = append(b.handlers[name], handler)
}

func (b *EventBus) Emit(event TelemetryEvent) {
    b.mu.RLock()
    defer b.mu.RUnlock()
    for _, h := range b.handlers[event.Name] {
        h(event)
    }
}
```

> **Benefit**: EventEmitter publishes to Redis streams — external consumers can read events without Go dependency.

</tab>
<tab title="Node.js">

```typescript
import { Worker } from "bullmq";

const worker = new Worker("combat-actions", combatProcessor, {
  connection: { host: "localhost", port: 6379 },
  concurrency: 10,
});

// Node.js uses EventEmitter pattern instead of :telemetry
worker.on("completed", (job, result) => {
  const durationMs = job.finishedOn! - job.processedOn!;
  console.log(`[combat] Job ${job.id} completed in ${durationMs}ms`);
});

worker.on("failed", (job, err) => {
  console.error(`[combat] Job ${job?.id} failed: ${err.message}`);
});

worker.on("stalled", (jobId) => {
  console.warn(`[combat] Stalled job detected: ${jobId}`);
});

worker.on("progress", (job, progress) => {
  console.log(`[combat] Job ${job.id} progress: ${JSON.stringify(progress)}`);
});

// For Telemetry.Metrics-like structured events, use EventEmitter2 or custom:
import { EventEmitter } from "events";

const telemetry = new EventEmitter();

telemetry.on("echomq.job.complete", ({ duration, queue, jobId, jobName }) => {
  console.log(`[telemetry] ${queue}/${jobName} job=${jobId} duration=${duration}ms`);
});

// Emit from worker callbacks
worker.on("completed", (job) => {
  telemetry.emit("echomq.job.complete", {
    duration: job.finishedOn! - job.processedOn!,
    queue: "combat-actions",
    jobId: job.id,
    jobName: job.name,
  });
});
```

> **Benefit**: QueueEvents wraps Redis XREAD internally — event subscription is a one-liner.

</tab>
</tabs>

> **⚠️ Go Gap**: Distributed tracing with OpenTelemetry is not implemented. No span propagation through Redis job metadata.
> **Proposed Solution**: Inject `traceparent` header into job data on enqueue, extract on dequeue. Use `go.opentelemetry.io/otel` SDK to create spans wrapping `processJob()`. Link parent spans across queue boundaries via `SpanContext` propagation.

## 30.4. Telemetry Span Helper

EchoMQ provides a `span/3` function that wraps a function call with start/stop/exception telemetry events. This is useful for instrumenting multi-step job processors.

<tabs>
<tab title="Elixir">

```elixir
defmodule Arena.CombatProcessor do
  @moduledoc "Processes combat actions with telemetry instrumentation."

  def process(job) do
    # Wraps the entire operation with start/stop/exception events
    EchoMQ.Telemetry.span([:combat, :process], %{job_id: job.id}, fn ->
      # Validate combat action
      EchoMQ.Telemetry.span([:combat, :validate], %{job_id: job.id}, fn ->
        validate_combat_action(job.data)
      end)

      # Apply damage calculation
      result = EchoMQ.Telemetry.span([:combat, :calculate], %{job_id: job.id}, fn ->
        calculate_damage(job.data)
      end)

      # Update game state
      EchoMQ.Telemetry.span([:combat, :update_state], %{job_id: job.id}, fn ->
        update_game_state(result)
      end)

      {:ok, result}
    end)
  end
end

# Emitted events:
# [:echomq, :combat, :process, :start]
# [:echomq, :combat, :validate, :start]
# [:echomq, :combat, :validate, :stop]
# [:echomq, :combat, :calculate, :start]
# [:echomq, :combat, :calculate, :stop]
# [:echomq, :combat, :update_state, :start]
# [:echomq, :combat, :update_state, :stop]
# [:echomq, :combat, :process, :stop]
#
# If an exception occurs:
# [:echomq, :combat, :validate, :exception]
# [:echomq, :combat, :process, :exception]
```

> **Benefit**: `:telemetry.span` combines start/stop events with automatic duration measurement.

</tab>
<tab title="Go">

```go
// Replicate the span pattern with manual timing:
func processCombatAction(ctx context.Context, job *echomq.Job) error {
    start := time.Now()

    // Validate
    validateStart := time.Now()
    if err := validateCombatAction(job.Data); err != nil {
        slog.Error("combat.validate failed", "job_id", job.ID, "error", err,
            "duration_ms", time.Since(validateStart).Milliseconds())
        return err
    }
    slog.Debug("combat.validate complete", "job_id", job.ID,
        "duration_ms", time.Since(validateStart).Milliseconds())

    // Calculate damage
    calcStart := time.Now()
    result, err := calculateDamage(ctx, job.Data)
    if err != nil {
        return err
    }
    slog.Debug("combat.calculate complete", "job_id", job.ID,
        "duration_ms", time.Since(calcStart).Milliseconds())

    // Update game state
    stateStart := time.Now()
    if err := updateGameState(ctx, result); err != nil {
        return err
    }
    slog.Debug("combat.update_state complete", "job_id", job.ID,
        "duration_ms", time.Since(stateStart).Milliseconds())

    slog.Info("combat.process complete", "job_id", job.ID,
        "total_ms", time.Since(start).Milliseconds())
    return nil
}
```

> **Benefit**: `tracer.Start` returns a span and context pair — propagation is explicit and type-safe.

</tab>
<tab title="Node.js">

```typescript
// Span-like instrumentation using performance.now()
async function combatProcessor(job: Job) {
  const spans: { name: string; start: number; end?: number; error?: string }[] = [];

  async function span<T>(name: string, fn: () => Promise<T>): Promise<T> {
    const entry = { name, start: performance.now() };
    spans.push(entry);
    try {
      const result = await fn();
      entry.end = performance.now();
      return result;
    } catch (err) {
      entry.end = performance.now();
      entry.error = (err as Error).message;
      throw err;
    }
  }

  const result = await span("combat.process", async () => {
    await span("combat.validate", () => validateCombatAction(job.data));
    const damage = await span("combat.calculate", () => calculateDamage(job.data));
    await span("combat.update_state", () => updateGameState(damage));
    return damage;
  });

  // Log all spans
  for (const s of spans) {
    const duration = ((s.end ?? performance.now()) - s.start).toFixed(1);
    if (s.error) {
      console.error(`[span] ${s.name} FAILED in ${duration}ms: ${s.error}`);
    } else {
      console.log(`[span] ${s.name} completed in ${duration}ms`);
    }
  }

  return result;
}
```

> **Benefit**: `tracer.startActiveSpan` automatically sets the active context for downstream calls.

</tab>
</tabs>

## 30.5. OpenTelemetry Setup

OpenTelemetry provides distributed tracing across service boundaries. When a Phoenix controller enqueues a combat action and a separate worker process handles it, OpenTelemetry links both operations into a single trace.

### Installation

<tabs>
<tab title="Elixir">

```elixir
# mix.exs
defp deps do
  [
    {:echomq, "~> 1.0"},

    # OpenTelemetry API (required for tracing)
    {:opentelemetry_api, "~> 1.0"},

    # OpenTelemetry SDK (exports spans)
    {:opentelemetry, "~> 1.0"},

    # OTLP exporter (Jaeger, Grafana Tempo, Honeycomb)
    {:opentelemetry_exporter, "~> 1.0"}
  ]
end
```

```elixir
# config/runtime.exs
config :opentelemetry,
  resource: [service: [name: "arena-combat-service"]],
  span_processor: :batch,
  traces_exporter: :otlp

config :opentelemetry_exporter,
  otlp_protocol: :http_protobuf,
  otlp_endpoint: System.get_env("OTEL_EXPORTER_OTLP_ENDPOINT", "http://localhost:4318")
```

> **Benefit**: OpenTelemetry BEAM SDK propagates trace context across process boundaries automatically.

</tab>
<tab title="Go">

```go
// Feature: OpenTelemetry Integration
//
// Not implemented in echomq-go. The Go package does not have
// built-in OpenTelemetry support or trace context propagation.
//
// Workaround:
//   Use the OpenTelemetry Go SDK directly in your processor:

import (
    "go.opentelemetry.io/otel"
    "go.opentelemetry.io/otel/attribute"
    "go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracehttp"
    "go.opentelemetry.io/otel/sdk/resource"
    sdktrace "go.opentelemetry.io/otel/sdk/trace"
    semconv "go.opentelemetry.io/otel/semconv/v1.24.0"
)

func initTracer() (*sdktrace.TracerProvider, error) {
    exporter, err := otlptracehttp.New(context.Background(),
        otlptracehttp.WithEndpoint("localhost:4318"),
        otlptracehttp.WithInsecure(),
    )
    if err != nil {
        return nil, err
    }

    tp := sdktrace.NewTracerProvider(
        sdktrace.WithBatcher(exporter),
        sdktrace.WithResource(resource.NewWithAttributes(
            semconv.SchemaURL,
            semconv.ServiceNameKey.String("arena-combat-service"),
        )),
    )
    otel.SetTracerProvider(tp)
    return tp, nil
}
```

> **Benefit**: `go.opentelemetry.io/otel` provides native span creation with W3C trace context propagation.

</tab>
<tab title="Node.js">

```typescript
// package.json
// "dependencies": {
//   "bullmq": "^5.0.0",
//   "@opentelemetry/api": "^1.0.0",
//   "@opentelemetry/sdk-node": "^0.50.0",
//   "@opentelemetry/exporter-trace-otlp-http": "^0.50.0",
//   "bullmq-otel": "^0.7.0"
// }

import { NodeSDK } from "@opentelemetry/sdk-node";
import { OTLPTraceExporter } from "@opentelemetry/exporter-trace-otlp-http";

const sdk = new NodeSDK({
  serviceName: "arena-combat-service",
  traceExporter: new OTLPTraceExporter({
    url: process.env.OTEL_EXPORTER_OTLP_ENDPOINT || "http://localhost:4318/v1/traces",
  }),
});

sdk.start();
```

> **Benefit**: `@opentelemetry/sdk-node` auto-instruments HTTP and Redis calls — minimal manual span code.

</tab>
</tabs>

### Enabling in Workers

<tabs>
<tab title="Elixir">

```elixir
# Enable OpenTelemetry tracing on the worker
{:ok, worker} = EchoMQ.Worker.start_link(
  queue: "combat-actions",
  connection: :arena_redis,
  telemetry: EchoMQ.Telemetry.OpenTelemetry,  # Enable OTel
  processor: fn job ->
    # This job is automatically wrapped in a span:
    #   Name: "echomq.worker.process"
    #   Attributes: messaging.system, messaging.destination.name, etc.
    #   Parent: restored from job's telemetry_metadata (if present)
    process_combat_action(job)
    {:ok, :done}
  end
)

# When adding jobs, trace context is automatically propagated
{:ok, queue} = EchoMQ.Queue.start_link(
  name: :combat_queue,
  connection: :arena_redis,
  telemetry: EchoMQ.Telemetry.OpenTelemetry
)

# Add a job within a traced operation
require OpenTelemetry.Tracer, as: Tracer
Tracer.with_span "arena.combat.submit" do
  # The current span's trace context is serialized into the job's
  # telemetry_metadata option and stored in Redis with the job.
  {:ok, job} = EchoMQ.Queue.add(queue, "melee-attack", %{
    player_id: "PLR0K48QjihpC4",
    target_id: "NPC5rK2mJ9pQ1L",
    weapon: "flame_sword",
    damage_base: 150
  })
end
```

> **Benefit**: OpenTelemetry BEAM SDK propagates trace context across process boundaries automatically.

</tab>
<tab title="Go">

```go
// Manual OpenTelemetry instrumentation in Go processor
var tracer = otel.Tracer("arena-combat")

func tracedCombatProcessor(ctx context.Context, job *echomq.Job) error {
    // Start a consumer span
    ctx, span := tracer.Start(ctx, "echomq.worker.process",
        trace.WithSpanKind(trace.SpanKindConsumer),
        trace.WithAttributes(
            attribute.String("messaging.system", "echomq"),
            attribute.String("messaging.destination.name", "combat-actions"),
            attribute.String("messaging.message.id", job.ID),
            attribute.String("echomq.job.name", job.Name),
        ),
    )
    defer span.End()

    // Process with child spans
    if err := processCombatAction(ctx, job); err != nil {
        span.RecordError(err)
        span.SetStatus(codes.Error, err.Error())
        return err
    }

    span.SetStatus(codes.Ok, "")
    return nil
}

// When adding jobs, inject trace context manually:
func addTracedJob(ctx context.Context, queue *echomq.Queue, jobName string, data map[string]interface{}) error {
    ctx, span := tracer.Start(ctx, "echomq.queue.add",
        trace.WithSpanKind(trace.SpanKindProducer),
        trace.WithAttributes(
            attribute.String("messaging.system", "echomq"),
            attribute.String("messaging.destination.name", queue.Name()),
        ),
    )
    defer span.End()

    // Serialize trace context into job options
    carrier := propagation.MapCarrier{}
    otel.GetTextMapPropagator().Inject(ctx, carrier)
    telemetryMeta, _ := json.Marshal(carrier)

    return queue.Add(ctx, jobName, data, echomq.JobOptions{
        // Store trace context in job data for cross-language propagation
        TelemetryMetadata: string(telemetryMeta),
    })
}
```

> **Benefit**: `go.opentelemetry.io/otel` provides native span creation with W3C trace context propagation.

</tab>
<tab title="Node.js">

```typescript
import { Worker, Queue } from "bullmq";
import { trace, SpanKind, context } from "@opentelemetry/api";

// Using bullmq-otel for automatic instrumentation
import { BullMQOTel } from "bullmq-otel";

// Auto-instrument all BullMQ operations
BullMQOTel.instrument();

// Workers are automatically traced:
const worker = new Worker("combat-actions", async (job) => {
  // A consumer span is automatically created with:
  //   messaging.system: "bullmq"
  //   messaging.destination.name: "combat-actions"
  //   messaging.message.id: job.id
  return processCombatAction(job);
}, { connection });

// Queue.add is automatically traced:
const queue = new Queue("combat-actions", { connection });

// The current span's trace context is propagated to the job
const tracer = trace.getTracer("arena-combat");
await tracer.startActiveSpan("arena.combat.submit", async (span) => {
  await queue.add("melee-attack", {
    player_id: "PLR0K48QjihpC4",
    target_id: "NPC5rK2mJ9pQ1L",
    weapon: "flame_sword",
    damage_base: 150,
  });
  span.end();
});
```

> **Benefit**: `@opentelemetry/sdk-node` auto-instruments HTTP and Redis calls — minimal manual span code.

</tab>
</tabs>

## 30.6. W3C Trace Context Propagation

The key to distributed tracing across queues is **context propagation**. When a job is added, the current trace context is serialized into the job's metadata using W3C Trace Context format (`traceparent` and `tracestate` headers). When a worker picks up the job, it deserializes the context and creates a child span linked to the original trace.

```
W3C Trace Context Flow Through Redis

  [Phoenix Controller]           [Redis]              [EchoMQ Worker]
         |                          |                        |
    Start span                      |                        |
    "api.combat.submit"             |                        |
         |                          |                        |
    Serialize context               |                        |
    to traceparent header           |                        |
    "00-abc123...-def456...-01"     |                        |
         |                          |                        |
    Queue.add(job, opts:            |                        |
      telemetry_metadata:           |                        |
        '{"traceparent":   ------->  Store in job hash       |
         "00-abc123..."}'  )        |  HSET bull:q:id        |
         |                          |  telemetry_metadata    |
         |                          |  '{"traceparent":..}'  |
         |                          |                        |
         |                          |     BRPOPLPUSH ------> |
         |                          |                        |
         |                          |           Deserialize context
         |                          |           Extract traceparent
         |                          |           Create child span
         |                          |           "echomq.worker.process"
         |                          |           parent = abc123.def456
         |                          |                        |
    Same trace_id: abc123...        |           Same trace_id: abc123...
    Span: api.combat.submit         |           Span: echomq.worker.process
    (parent)                        |           (child of api.combat.submit)
```

The `traceparent` header follows the W3C format: `{version}-{trace-id}-{parent-id}-{trace-flags}`. This is the same format used by HTTP-based distributed tracing, making queue-based traces seamlessly join HTTP request traces.

## 30.7. Cross-Language Tracing

Because EchoMQ, BullMQ (Node.js), and the Go implementation all share the same Redis data format, trace context propagated by one runtime is readable by another. A Node.js service can enqueue a job with trace context, and an Elixir worker can pick it up and continue the same trace.

<tabs>
<tab title="Elixir">

```elixir
# Elixir worker processes a job added by Node.js with trace context.
# The trace context is stored in the job's telemetry_metadata field.
# EchoMQ.Telemetry.OpenTelemetry.deserialize_context/1 extracts it.

{:ok, worker} = EchoMQ.Worker.start_link(
  queue: "combat-actions",
  connection: :arena_redis,
  telemetry: EchoMQ.Telemetry.OpenTelemetry,
  processor: fn job ->
    # Automatically creates a child span of the Node.js producer span.
    # In Jaeger, you see:
    #   [Node.js] arena.combat.submit (parent)
    #     [Elixir] echomq.worker.process (child)
    #       [Elixir] combat.validate (grandchild)
    #       [Elixir] combat.calculate (grandchild)
    #       [Elixir] combat.update_state (grandchild)

    alias EchoMQ.Telemetry.OpenTelemetry, as: OTel

    OTel.trace("combat.validate", [kind: :internal], fn _span ->
      validate_combat_action(job.data)
    end)

    result = OTel.trace("combat.calculate", [kind: :internal], fn span ->
      OTel.set_attribute(span, "combat.weapon", job.data["weapon"])
      OTel.set_attribute(span, "combat.player_id", job.data["player_id"])
      calculate_damage(job.data)
    end)

    OTel.trace("combat.update_state", [kind: :client], fn span ->
      OTel.set_attribute(span, "db.system", "redis")
      update_game_state(result)
    end)

    {:ok, result}
  end
)
```

> **Benefit**: OpenTelemetry BEAM SDK propagates trace context across process boundaries automatically.

</tab>
<tab title="Go">

```go
// Go worker extracts trace context from a job added by Elixir or Node.js

func tracedCombatProcessor(ctx context.Context, job *echomq.Job) error {
    // Extract trace context from job metadata
    if meta := job.Opts.TelemetryMetadata; meta != "" {
        var carrier propagation.MapCarrier
        if err := json.Unmarshal([]byte(meta), &carrier); err == nil {
            ctx = otel.GetTextMapPropagator().Extract(ctx, carrier)
        }
    }

    // Create child span linked to the producer's trace
    ctx, span := tracer.Start(ctx, "echomq.worker.process",
        trace.WithSpanKind(trace.SpanKindConsumer),
        trace.WithAttributes(
            attribute.String("messaging.system", "echomq"),
            attribute.String("messaging.destination.name", "combat-actions"),
            attribute.String("messaging.message.id", job.ID),
            attribute.String("echomq.job.name", job.Name),
        ),
    )
    defer span.End()

    // Child spans for each processing phase
    func() {
        _, validateSpan := tracer.Start(ctx, "combat.validate")
        defer validateSpan.End()
        validateCombatAction(job.Data)
    }()

    var result *CombatResult
    func() {
        calcCtx, calcSpan := tracer.Start(ctx, "combat.calculate")
        defer calcSpan.End()
        calcSpan.SetAttributes(
            attribute.String("combat.weapon", job.Data["weapon"].(string)),
            attribute.String("combat.player_id", job.Data["player_id"].(string)),
        )
        result, _ = calculateDamage(calcCtx, job.Data)
    }()

    func() {
        _, stateSpan := tracer.Start(ctx, "combat.update_state",
            trace.WithSpanKind(trace.SpanKindClient))
        defer stateSpan.End()
        stateSpan.SetAttributes(attribute.String("db.system", "redis"))
        updateGameState(ctx, result)
    }()

    return nil
}

// In Jaeger:
//   [Elixir] arena.combat.submit (parent)
//     [Go] echomq.worker.process (child)
//       [Go] combat.validate (grandchild)
//       [Go] combat.calculate (grandchild)
//       [Go] combat.update_state (grandchild)
```

> **Benefit**: `go.opentelemetry.io/otel` provides native span creation with W3C trace context propagation.

</tab>
<tab title="Node.js">

```typescript
import { trace, SpanKind } from "@opentelemetry/api";
import { Queue, Worker } from "bullmq";

const tracer = trace.getTracer("arena-combat");

// Node.js producer adds a job with trace context
// (bullmq-otel does this automatically, or manually):
async function submitCombatAction(queue: Queue, action: CombatAction) {
  return tracer.startActiveSpan(
    "arena.combat.submit",
    { kind: SpanKind.PRODUCER },
    async (span) => {
      span.setAttribute("combat.player_id", action.playerId);
      span.setAttribute("combat.weapon", action.weapon);

      const job = await queue.add("melee-attack", action);
      span.setAttribute("messaging.message.id", job.id!);
      span.end();
      return job;
    }
  );
}

// Node.js worker with manual child spans
const worker = new Worker("combat-actions", async (job) => {
  // bullmq-otel automatically restores trace context

  await tracer.startActiveSpan("combat.validate", async (span) => {
    validateCombatAction(job.data);
    span.end();
  });

  const result = await tracer.startActiveSpan("combat.calculate", async (span) => {
    span.setAttribute("combat.weapon", job.data.weapon);
    const dmg = calculateDamage(job.data);
    span.end();
    return dmg;
  });

  await tracer.startActiveSpan("combat.update_state", { kind: SpanKind.CLIENT }, async (span) => {
    span.setAttribute("db.system", "redis");
    await updateGameState(result);
    span.end();
  });

  return result;
}, { connection });
```

> **Benefit**: `@opentelemetry/sdk-node` auto-instruments HTTP and Redis calls — minimal manual span code.

</tab>
</tabs>

## 30.8. Span Attributes Reference

Automatic spans created by `EchoMQ.Telemetry.OpenTelemetry` include these semantic attributes following the OpenTelemetry Messaging Semantic Conventions:

| Attribute | Value | Description |
|-----------|-------|-------------|
| `messaging.system` | `"echomq"` | Messaging system identifier |
| `messaging.destination.name` | Queue name | e.g., `"combat-actions"` |
| `messaging.message.id` | Job ID | Unique job identifier |
| `messaging.operation` | `"publish"` or `"receive"` | Producer or consumer operation |
| `echomq.job.name` | Job name | e.g., `"melee-attack"` |
| `echomq.job.priority` | Priority value | Job priority (0 = highest) |
| `echomq.job.delay` | Delay in ms | Scheduled delay |
| `echomq.job.attempts` | Current attempt | Number of attempts made |

## 30.9. Jaeger Setup

Jaeger provides a complete distributed tracing backend with a web UI for searching and visualizing traces. This docker-compose setup runs Jaeger with OTLP ingestion.

```yaml
# docker-compose.jaeger.yml
services:
  jaeger:
    image: jaegertracing/all-in-one:1.54
    ports:
      - "16686:16686"   # Jaeger UI
      - "4317:4317"     # OTLP gRPC
      - "4318:4318"     # OTLP HTTP
      - "14268:14268"   # Jaeger HTTP Thrift
    environment:
      COLLECTOR_OTLP_ENABLED: "true"
      SPAN_STORAGE_TYPE: "badger"
      BADGER_EPHEMERAL: "false"
      BADGER_DIRECTORY_VALUE: "/badger/data"
      BADGER_DIRECTORY_KEY: "/badger/key"
    volumes:
      - jaeger-data:/badger

volumes:
  jaeger-data:
```

```bash
# Start Jaeger
docker compose -f docker-compose.jaeger.yml up -d

# Open Jaeger UI
open http://localhost:16686
```

Configure each runtime to export to Jaeger's OTLP endpoint:

<tabs>
<tab title="Elixir">

```elixir
# config/runtime.exs
config :opentelemetry,
  resource: [service: [name: "arena-combat-elixir"]],
  span_processor: :batch,
  traces_exporter: :otlp

config :opentelemetry_exporter,
  otlp_protocol: :http_protobuf,
  otlp_endpoint: "http://localhost:4318"
```

> **Benefit**: OpenTelemetry BEAM SDK propagates trace context across process boundaries automatically.

</tab>
<tab title="Go">

```go
// Configure OTLP exporter pointing to Jaeger
exporter, err := otlptracehttp.New(ctx,
    otlptracehttp.WithEndpoint("localhost:4318"),
    otlptracehttp.WithInsecure(),
)
if err != nil {
    log.Fatalf("Failed to create exporter: %v", err)
}

tp := sdktrace.NewTracerProvider(
    sdktrace.WithBatcher(exporter),
    sdktrace.WithResource(resource.NewWithAttributes(
        semconv.SchemaURL,
        semconv.ServiceNameKey.String("arena-combat-go"),
    )),
)
otel.SetTracerProvider(tp)
defer tp.Shutdown(ctx)
```

> **Benefit**: `go.opentelemetry.io/otel` provides native span creation with W3C trace context propagation.

</tab>
<tab title="Node.js">

```typescript
import { NodeSDK } from "@opentelemetry/sdk-node";
import { OTLPTraceExporter } from "@opentelemetry/exporter-trace-otlp-http";

const sdk = new NodeSDK({
  serviceName: "arena-combat-nodejs",
  traceExporter: new OTLPTraceExporter({
    url: "http://localhost:4318/v1/traces",
  }),
});

sdk.start();

// Graceful shutdown
process.on("SIGTERM", async () => {
  await sdk.shutdown();
});
```

> **Benefit**: `@opentelemetry/sdk-node` auto-instruments HTTP and Redis calls — minimal manual span code.

</tab>
</tabs>

In the Jaeger UI, search for service `arena-combat-elixir` to see traces. A cross-language trace appears as a single trace with spans from multiple services, connected by the shared `trace_id`.

## 30.10. Custom Telemetry Backend

EchoMQ's telemetry system is pluggable through the `EchoMQ.Telemetry.Behaviour`. Implement the 9 callbacks to integrate with any tracing system -- Datadog APM, New Relic, AWS X-Ray, or a custom in-house solution.

<tabs>
<tab title="Elixir">

```elixir
defmodule Arena.DatadogTelemetry do
  @moduledoc "Custom telemetry backend that sends traces to Datadog APM."
  @behaviour EchoMQ.Telemetry.Behaviour

  @impl true
  def start_span(name, opts) do
    kind = Keyword.get(opts, :kind, :internal)
    attributes = Keyword.get(opts, :attributes, %{})
    parent = Keyword.get(opts, :parent)

    span = %{
      name: name,
      kind: kind,
      start_time: System.monotonic_time(),
      attributes: attributes,
      parent: parent,
      trace_id: if(parent, do: parent.trace_id, else: generate_trace_id()),
      span_id: generate_span_id(),
      events: []
    }

    {span, span}
  end

  @impl true
  def end_span(span, status) do
    case span do
      {state, _} when is_map(state) ->
        duration = System.monotonic_time() - state.start_time
        # Send to Datadog agent via StatsD or APM API
        send_to_datadog(%{
          name: state.name,
          duration: duration,
          status: status,
          trace_id: state.trace_id,
          span_id: state.span_id,
          attributes: state.attributes
        })
      _ -> :ok
    end
    :ok
  end

  @impl true
  def get_current_context do
    Process.get(:arena_trace_context)
  end

  @impl true
  def serialize_context(context) when is_map(context) do
    Jason.encode!(%{
      trace_id: context.trace_id,
      span_id: context.span_id
    })
  end
  def serialize_context(_), do: nil

  @impl true
  def deserialize_context(metadata) when is_binary(metadata) do
    case Jason.decode(metadata) do
      {:ok, %{"trace_id" => tid, "span_id" => sid}} ->
        %{trace_id: tid, span_id: sid}
      _ -> nil
    end
  end
  def deserialize_context(_), do: nil

  @impl true
  def with_context(context, fun) do
    previous = Process.get(:arena_trace_context)
    Process.put(:arena_trace_context, context)
    try do
      fun.()
    after
      if previous, do: Process.put(:arena_trace_context, previous),
        else: Process.delete(:arena_trace_context)
    end
  end

  @impl true
  def set_attribute({state, ref}, key, value) when is_map(state) do
    {Map.update!(state, :attributes, &Map.put(&1, key, value)), ref}
  end
  def set_attribute(span, _key, _value), do: span

  @impl true
  def add_event({state, ref}, name, attributes) when is_map(state) do
    event = %{name: name, attributes: attributes, timestamp: System.monotonic_time()}
    {Map.update!(state, :events, &[event | &1]), ref}
    :ok
  end
  def add_event(_, _, _), do: :ok

  @impl true
  def record_exception({state, _ref}, exception, stacktrace) when is_map(state) do
    Logger.error("Trace #{state.trace_id} exception: #{Exception.message(exception)}")
    :ok
  end
  def record_exception(_, _, _), do: :ok

  # Private helpers
  defp generate_trace_id, do: :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
  defp generate_span_id, do: :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)
  defp send_to_datadog(span_data), do: Arena.Datadog.Client.submit_span(span_data)
end

# Usage:
{:ok, worker} = EchoMQ.Worker.start_link(
  queue: "combat-actions",
  connection: :arena_redis,
  telemetry: Arena.DatadogTelemetry,
  processor: &Arena.CombatProcessor.process/1
)
```

> **Benefit**: OpenTelemetry BEAM SDK propagates trace context across process boundaries automatically.

</tab>
<tab title="Go">

```go
// In Go, implement tracing with any backend by wrapping your processor.
// This example uses Datadog's dd-trace-go:

import (
    "gopkg.in/DataDog/dd-trace-go.v1/ddtrace/tracer"
)

func init() {
    tracer.Start(
        tracer.WithService("arena-combat-go"),
        tracer.WithEnv("production"),
    )
}

func datadogTracedProcessor(ctx context.Context, job *echomq.Job) error {
    span, ctx := tracer.StartSpanFromContext(ctx, "echomq.worker.process",
        tracer.SpanType("queue"),
        tracer.ResourceName(job.Name),
        tracer.Tag("messaging.system", "echomq"),
        tracer.Tag("messaging.destination.name", "combat-actions"),
        tracer.Tag("messaging.message.id", job.ID),
    )
    defer span.Finish()

    if err := processCombatAction(ctx, job); err != nil {
        span.Finish(tracer.WithError(err))
        return err
    }
    return nil
}
```

> **Benefit**: `go.opentelemetry.io/otel` provides native span creation with W3C trace context propagation.

</tab>
<tab title="Node.js">

```typescript
// In Node.js, use dd-trace for Datadog or any custom backend:
import ddTrace from "dd-trace";

ddTrace.init({
  service: "arena-combat-nodejs",
  env: "production",
});

// Manual span creation around BullMQ operations
const worker = new Worker("combat-actions", async (job) => {
  const span = ddTrace.startSpan("echomq.worker.process", {
    type: "queue",
    resource: job.name,
    tags: {
      "messaging.system": "echomq",
      "messaging.destination.name": "combat-actions",
      "messaging.message.id": job.id,
    },
  });

  try {
    const result = await processCombatAction(job);
    span.finish();
    return result;
  } catch (err) {
    span.setTag("error", err);
    span.finish();
    throw err;
  }
}, { connection });
```

> **Benefit**: `@opentelemetry/sdk-node` auto-instruments HTTP and Redis calls — minimal manual span code.

</tab>
</tabs>

## 30.11. Combat Action Trace Example

A complete end-to-end trace of a combat action in Fireheadz Arena, showing how a player input flows through the system.

<tabs>
<tab title="Elixir">

```elixir
defmodule ArenaWeb.CombatController do
  @moduledoc "HTTP endpoint that receives combat actions and enqueues them."
  use ArenaWeb, :controller

  require OpenTelemetry.Tracer, as: Tracer

  def create(conn, %{"action" => action_params}) do
    Tracer.with_span "arena.api.combat.create" do
      Tracer.set_attribute("combat.player_id", action_params["player_id"])
      Tracer.set_attribute("combat.action_type", action_params["type"])

      # Enqueue combat action -- trace context propagates automatically
      {:ok, job} = EchoMQ.Queue.add(:combat_queue, action_params["type"], %{
        player_id: action_params["player_id"],
        target_id: action_params["target_id"],
        weapon: action_params["weapon"],
        position: action_params["position"],
        timestamp: System.system_time(:millisecond)
      })

      Tracer.set_attribute("messaging.message.id", job.id)

      conn
      |> put_status(:accepted)
      |> json(%{job_id: job.id, status: "queued"})
    end
  end
end

# The resulting trace in Jaeger:
#
# Trace: abc123...
# +-- arena.api.combat.create          [ArenaWeb]    12ms
#     |-- combat.player_id: PLR0K48QjihpC4
#     |-- combat.action_type: melee-attack
#     |-- messaging.message.id: xyz789
#     |
#     +-- echomq.worker.process        [CombatWorker] 8ms
#         |-- messaging.system: echomq
#         |-- messaging.destination.name: combat-actions
#         |-- echomq.job.name: melee-attack
#         |
#         +-- combat.validate           [internal]     1ms
#         +-- combat.calculate          [internal]     3ms
#         |   |-- combat.weapon: flame_sword
#         |   |-- combat.damage: 185
#         |   |-- combat.critical: true
#         +-- combat.update_state       [client]       2ms
#             |-- db.system: redis
```

> **Benefit**: OpenTelemetry BEAM SDK propagates trace context across process boundaries automatically.

</tab>
<tab title="Go">

```go
// Go HTTP handler that enqueues a combat action with trace context
func combatHandler(w http.ResponseWriter, r *http.Request) {
    ctx, span := tracer.Start(r.Context(), "arena.api.combat.create",
        trace.WithSpanKind(trace.SpanKindServer),
    )
    defer span.End()

    var action CombatAction
    json.NewDecoder(r.Body).Decode(&action)

    span.SetAttributes(
        attribute.String("combat.player_id", action.PlayerID),
        attribute.String("combat.action_type", action.Type),
    )

    // Inject trace context into job metadata
    carrier := propagation.MapCarrier{}
    otel.GetTextMapPropagator().Inject(ctx, carrier)
    telemetryMeta, _ := json.Marshal(carrier)

    jobID, err := combatQueue.Add(ctx, action.Type, action, echomq.JobOptions{
        TelemetryMetadata: string(telemetryMeta),
    })
    if err != nil {
        span.RecordError(err)
        http.Error(w, err.Error(), 500)
        return
    }

    span.SetAttributes(attribute.String("messaging.message.id", jobID))
    json.NewEncoder(w).Encode(map[string]string{
        "job_id": jobID,
        "status": "queued",
    })
}
```

> **Benefit**: `go.opentelemetry.io/otel` provides native span creation with W3C trace context propagation.

</tab>
<tab title="Node.js">

```typescript
import express from "express";
import { trace, SpanKind } from "@opentelemetry/api";
import { Queue } from "bullmq";

const app = express();
const tracer = trace.getTracer("arena-combat");
const combatQueue = new Queue("combat-actions", { connection });

app.post("/api/combat", async (req, res) => {
  await tracer.startActiveSpan(
    "arena.api.combat.create",
    { kind: SpanKind.SERVER },
    async (span) => {
      const { player_id, target_id, weapon, type } = req.body;

      span.setAttribute("combat.player_id", player_id);
      span.setAttribute("combat.action_type", type);

      // bullmq-otel automatically propagates trace context
      const job = await combatQueue.add(type, {
        player_id,
        target_id,
        weapon,
        position: req.body.position,
        timestamp: Date.now(),
      });

      span.setAttribute("messaging.message.id", job.id!);
      span.end();

      res.status(202).json({ job_id: job.id, status: "queued" });
    }
  );
});

// Resulting Jaeger trace:
// Trace: abc123...
// +-- arena.api.combat.create    [arena-combat-nodejs]  15ms
//     +-- echomq.queue.add       [arena-combat-nodejs]   3ms
//     +-- echomq.worker.process  [arena-combat-elixir]   8ms
//         +-- combat.validate    [internal]               1ms
//         +-- combat.calculate   [internal]               3ms
//         +-- combat.update_state [client]                2ms
```

> **Benefit**: `@opentelemetry/sdk-node` auto-instruments HTTP and Redis calls — minimal manual span code.

</tab>
</tabs>

## 30.12. Cross-Service Matchmaking Trace

A more complex trace that spans multiple queues and services: a matchmaking request that flows through the matchmaking queue, creates a match, then enqueues combat setup jobs for both players.

<tabs>
<tab title="Elixir">

```elixir
defmodule Arena.MatchmakingProcessor do
  @moduledoc "Processes matchmaking requests and spawns combat setup jobs."

  alias EchoMQ.Telemetry.OpenTelemetry, as: OTel

  def process(job) do
    player_id = job.data["player_id"]

    # Phase 1: Find opponent
    opponent = OTel.trace("matchmaking.find_opponent", [kind: :internal], fn span ->
      OTel.set_attribute(span, "matchmaking.player_id", player_id)
      OTel.set_attribute(span, "matchmaking.skill_rating", job.data["skill_rating"])
      find_opponent(player_id, job.data["skill_rating"])
    end)

    # Phase 2: Create match
    match = OTel.trace("matchmaking.create_match", [kind: :client], fn span ->
      match_id = Arena.ID.generate("MTH")  # e.g. "MTH0K5M2vuIULY"
      OTel.set_attribute(span, "matchmaking.match_id", match_id)
      OTel.set_attribute(span, "matchmaking.player_a", player_id)
      OTel.set_attribute(span, "matchmaking.player_b", opponent.id)
      create_match(match_id, player_id, opponent.id)
    end)

    # Phase 3: Enqueue combat setup for both players (child jobs)
    OTel.trace("matchmaking.enqueue_setup", [kind: :producer, propagate: true], fn _span, metadata ->
      EchoMQ.Queue.add(:combat_queue, "combat-setup", %{
        match_id: match.id,
        player_id: player_id,
        opponent_id: opponent.id,
        arena: match.arena
      }, telemetry_metadata: metadata)

      EchoMQ.Queue.add(:combat_queue, "combat-setup", %{
        match_id: match.id,
        player_id: opponent.id,
        opponent_id: player_id,
        arena: match.arena
      }, telemetry_metadata: metadata)
    end)

    {:ok, %{match_id: match.id, opponent_id: opponent.id}}
  end
end

# Jaeger trace:
# +-- arena.api.matchmaking.join          [Phoenix]     250ms
#     +-- echomq.worker.process           [Matchmaking]  200ms
#         +-- matchmaking.find_opponent   [internal]      150ms
#         +-- matchmaking.create_match    [client]         20ms
#         +-- matchmaking.enqueue_setup   [producer]       10ms
#             +-- echomq.worker.process   [Combat]          8ms  (player A)
#             +-- echomq.worker.process   [Combat]          8ms  (player B)
```

> **Benefit**: OpenTelemetry BEAM SDK propagates trace context across process boundaries automatically.

</tab>
<tab title="Go">

```go
func matchmakingProcessor(ctx context.Context, job *echomq.Job) error {
    playerID := job.Data["player_id"].(string)

    // Phase 1: Find opponent
    var opponent *Player
    func() {
        ctx, span := tracer.Start(ctx, "matchmaking.find_opponent")
        defer span.End()
        span.SetAttributes(
            attribute.String("matchmaking.player_id", playerID),
        )
        opponent = findOpponent(ctx, playerID)
    }()

    // Phase 2: Create match
    var match *Match
    func() {
        ctx, span := tracer.Start(ctx, "matchmaking.create_match",
            trace.WithSpanKind(trace.SpanKindClient))
        defer span.End()
        matchID := arena.GenerateID("MTH") // e.g. "MTH0K5M2vuIULY"
        span.SetAttributes(
            attribute.String("matchmaking.match_id", matchID),
            attribute.String("matchmaking.player_a", playerID),
            attribute.String("matchmaking.player_b", opponent.ID),
        )
        match = createMatch(ctx, matchID, playerID, opponent.ID)
    }()

    // Phase 3: Enqueue combat setup with trace context
    func() {
        _, span := tracer.Start(ctx, "matchmaking.enqueue_setup",
            trace.WithSpanKind(trace.SpanKindProducer))
        defer span.End()

        carrier := propagation.MapCarrier{}
        otel.GetTextMapPropagator().Inject(ctx, carrier)
        meta, _ := json.Marshal(carrier)

        combatQueue.Add(ctx, "combat-setup", map[string]interface{}{
            "match_id":    match.ID,
            "player_id":   playerID,
            "opponent_id": opponent.ID,
        }, echomq.JobOptions{TelemetryMetadata: string(meta)})

        combatQueue.Add(ctx, "combat-setup", map[string]interface{}{
            "match_id":    match.ID,
            "player_id":   opponent.ID,
            "opponent_id": playerID,
        }, echomq.JobOptions{TelemetryMetadata: string(meta)})
    }()

    return nil
}
```

> **Benefit**: `go.opentelemetry.io/otel` provides native span creation with W3C trace context propagation.

</tab>
<tab title="Node.js">

```typescript
import { trace, SpanKind } from "@opentelemetry/api";
import { Queue, Job } from "bullmq";

const tracer = trace.getTracer("arena-matchmaking");
const combatQueue = new Queue("combat-actions", { connection });

async function matchmakingProcessor(job: Job) {
  const playerId = job.data.player_id;

  // Phase 1: Find opponent
  const opponent = await tracer.startActiveSpan("matchmaking.find_opponent", async (span) => {
    span.setAttribute("matchmaking.player_id", playerId);
    span.setAttribute("matchmaking.skill_rating", job.data.skill_rating);
    const result = await findOpponent(playerId, job.data.skill_rating);
    span.end();
    return result;
  });

  // Phase 2: Create match
  const match = await tracer.startActiveSpan(
    "matchmaking.create_match",
    { kind: SpanKind.CLIENT },
    async (span) => {
      const matchId = generateBrandedId("MTH"); // e.g. "MTH0K5M2vuIULY"
      span.setAttribute("matchmaking.match_id", matchId);
      span.setAttribute("matchmaking.player_a", playerId);
      span.setAttribute("matchmaking.player_b", opponent.id);
      const result = await createMatch(matchId, playerId, opponent.id);
      span.end();
      return result;
    }
  );

  // Phase 3: Enqueue combat setup (bullmq-otel propagates context)
  await tracer.startActiveSpan(
    "matchmaking.enqueue_setup",
    { kind: SpanKind.PRODUCER },
    async (span) => {
      await Promise.all([
        combatQueue.add("combat-setup", {
          match_id: match.id,
          player_id: playerId,
          opponent_id: opponent.id,
          arena: match.arena,
        }),
        combatQueue.add("combat-setup", {
          match_id: match.id,
          player_id: opponent.id,
          opponent_id: playerId,
          arena: match.arena,
        }),
      ]);
      span.end();
    }
  );

  return { match_id: match.id, opponent_id: opponent.id };
}
```

> **Benefit**: `@opentelemetry/sdk-node` auto-instruments HTTP and Redis calls — minimal manual span code.

</tab>
</tabs>

## 30.13. Using Both Systems Together

The recommended production setup combines Elixir Telemetry for aggregated metrics with OpenTelemetry for distributed tracing. They complement each other without conflict.

<tabs>
<tab title="Elixir">

```elixir
defmodule Arena.Observability do
  @moduledoc """
  Complete observability setup: Telemetry metrics + OpenTelemetry tracing.
  Call setup/0 from your Application.start/2.
  """

  def setup do
    # 1. Prometheus metrics via Telemetry.Metrics
    {:ok, _} = TelemetryMetricsPrometheus.start_link(
      metrics: Arena.PrometheusMetrics.metrics(),
      port: 9568
    )

    # 2. Application-level alerting
    Arena.Alerts.setup()

    # 3. Structured logging of telemetry events
    Arena.TelemetrySetup.setup()

    # 4. OpenTelemetry is configured in config/runtime.exs
    #    and enabled per-worker via telemetry: EchoMQ.Telemetry.OpenTelemetry
    :ok
  end
end

# In your supervision tree:
defmodule Arena.Application do
  use Application

  def start(_type, _args) do
    Arena.Observability.setup()

    children = [
      {Redix, name: :arena_redis, host: "localhost", port: 6379},

      # Workers with both metrics and tracing enabled
      {EchoMQ.Worker,
        queue: "combat-actions",
        connection: :arena_redis,
        telemetry: EchoMQ.Telemetry.OpenTelemetry,
        processor: &Arena.CombatProcessor.process/1,
        concurrency: 10,
        metrics: %{max_data_points: 20_160}},

      {EchoMQ.Worker,
        queue: "matchmaking",
        connection: :arena_redis,
        telemetry: EchoMQ.Telemetry.OpenTelemetry,
        processor: &Arena.MatchmakingProcessor.process/1,
        concurrency: 5,
        metrics: %{max_data_points: 20_160}}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
```

> **Benefit**: `TelemetryMetricsPrometheus` auto-generates Prometheus endpoint from `:telemetry` event definitions.

</tab>
<tab title="Go">

```go
func main() {
    ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt)
    defer cancel()

    // 1. Initialize OpenTelemetry tracer
    tp, err := initTracer()
    if err != nil {
        log.Fatal(err)
    }
    defer tp.Shutdown(ctx)

    // 2. Start Prometheus metrics server
    http.Handle("/metrics", promhttp.Handler())
    go http.ListenAndServe(":9568", nil)

    // 3. Start workers with instrumented processors
    rdb := redis.NewClient(&redis.Options{Addr: "localhost:6379"})

    combatWorker := echomq.NewWorker("combat-actions", rdb, echomq.WorkerOptions{
        Concurrency: 10,
    })
    combatWorker.Process(tracedCombatProcessor) // Uses both OTel + Prometheus

    matchWorker := echomq.NewWorker("matchmaking", rdb, echomq.WorkerOptions{
        Concurrency: 5,
    })
    matchWorker.Process(matchmakingProcessor)

    // 4. Start event monitor for dashboard
    monitor := NewCombatEventMonitor(rdb, "combat-actions")
    go monitor.Listen(ctx, func(event string, data map[string]interface{}) {
        log.Printf("[events] %s job=%v", event, data["jobId"])
    })

    // Block until shutdown
    <-ctx.Done()
}
```

> **Benefit**: `promhttp.Handler()` serves metrics on any port — no framework dependency needed.

</tab>
<tab title="Node.js">

```typescript
import { NodeSDK } from "@opentelemetry/sdk-node";
import { OTLPTraceExporter } from "@opentelemetry/exporter-trace-otlp-http";
import { BullMQOTel } from "bullmq-otel";
import { Worker, Queue } from "bullmq";
import { register } from "prom-client";
import express from "express";

// 1. Initialize OpenTelemetry
const sdk = new NodeSDK({
  serviceName: "arena-combat-nodejs",
  traceExporter: new OTLPTraceExporter({
    url: "http://localhost:4318/v1/traces",
  }),
});
sdk.start();

// 2. Auto-instrument BullMQ
BullMQOTel.instrument();

// 3. Prometheus metrics endpoint
const app = express();
app.get("/metrics", async (req, res) => {
  res.set("Content-Type", register.contentType);
  res.end(await register.metrics());
});
app.listen(9568);

// 4. Workers with tracing + metrics
const connection = { host: "localhost", port: 6379 };

const combatWorker = new Worker("combat-actions", combatProcessor, {
  connection,
  concurrency: 10,
  metrics: { maxDataPoints: 20160 },
});

const matchWorker = new Worker("matchmaking", matchmakingProcessor, {
  connection,
  concurrency: 5,
  metrics: { maxDataPoints: 20160 },
});

// Prometheus counters driven by worker events
combatWorker.on("completed", (job) => {
  jobsCompletedTotal.labels("combat-actions", job.name).inc();
});
combatWorker.on("failed", (job) => {
  jobsFailedTotal.labels("combat-actions", job?.name ?? "unknown").inc();
});
```

> **Benefit**: `prom-client` `register.metrics()` returns Prometheus text format ready for scraping.

</tab>
</tabs>

## 30.14. Comparison: Telemetry & Tracing by Runtime

| Feature | Elixir | Go | Node.js |
|---------|--------|-----|---------|
| Local telemetry events | `:telemetry` (14 events) | Manual instrumentation | Worker EventEmitter |
| Telemetry helpers | `EchoMQ.Telemetry.attach/4` | Not available | Not available |
| Span helper | `EchoMQ.Telemetry.span/3` | Manual timing | Manual timing |
| OpenTelemetry adapter | `EchoMQ.Telemetry.OpenTelemetry` | Manual OTel Go SDK | `bullmq-otel` |
| Custom backend | `EchoMQ.Telemetry.Behaviour` (9 callbacks) | Any Go tracing lib | Any JS tracing lib |
| W3C context propagation | Built-in (`serialize_context/1`) | Manual injection/extraction | Via `bullmq-otel` |
| Jaeger integration | `opentelemetry_exporter` | `otlptrace/otlptracehttp` | `@opentelemetry/exporter-trace-otlp-http` |
| Cross-language tracing | Full (context via `telemetry_metadata`) | Full (manual carrier) | Full (`bullmq-otel`) |

---

*Previous: [Metrics & Prometheus](ch29-metrics-prometheus.md) | Next: [Production Guide](ch31-production-guide.md)*
