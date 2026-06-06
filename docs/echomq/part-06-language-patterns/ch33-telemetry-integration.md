# Chapter 33. Telemetry Integration

> Observability patterns for EchoMQ across Elixir, Go, and Node.js ecosystems -- from local event systems through Prometheus metrics to distributed tracing with OpenTelemetry.

## 33.1. Overview

Telemetry serves different roles in each EchoMQ runtime. Elixir provides `:telemetry`, a zero-cost PubSub event library baked into the BEAM ecosystem -- handlers attach by event name and fire synchronously in the caller's process. Go has no equivalent event bus; instead you instrument directly at call sites using `prometheus/client_golang` or `log/slog`, threading context explicitly through `context.Context`. Node.js sits between the two: BullMQ's Worker and QueueEvents classes extend EventEmitter, giving you a reactive subscription model where you listen for `completed`, `failed`, `stalled`, and other events after the fact.

Despite these philosophical differences, the observability **outcome** is the same: counters for throughput, histograms for latency, gauges for queue depth, and distributed traces that follow a job from enqueue to completion -- even when the producer and consumer run in different languages.

This chapter walks through the full telemetry stack for a Codemoji deployment: event systems, metric collection, Prometheus integration, OpenTelemetry distributed tracing, Grafana dashboards, custom backends, and cross-language trace continuity.

```
+-----------------------------------------------------------------------+
|                      TELEMETRY ARCHITECTURE                           |
+-----------------------------------------------------------------------+
|                                                                       |
|   Elixir (:telemetry)     Go (Prometheus)      Node.js (EventEmitter)|
|   +-------------------+   +------------------+  +------------------+ |
|   | Declarative PubSub|   | Imperative Calls |  | Reactive Events  | |
|   | attach_many/3     |   | .Inc() .Observe()|  | worker.on(...)   | |
|   | Zero-cost if idle |   | Direct at site   |  | QueueEvents      | |
|   +--------+----------+   +--------+---------+  +--------+---------+ |
|            |                        |                     |           |
|            v                        v                     v           |
|   +-----------------------------------------------------------+      |
|   |            Prometheus / Grafana / AlertManager             |      |
|   +-----------------------------------------------------------+      |
|   +-----------------------------------------------------------+      |
|   |     OpenTelemetry (W3C Trace Context via Redis jobs)       |      |
|   +-----------------------------------------------------------+      |
|            |                        |                     |           |
|            v                        v                     v           |
|   +-----------------------------------------------------------+      |
|   |          Jaeger / Zipkin / Grafana Tempo / Honeycomb       |      |
|   +-----------------------------------------------------------+      |
|                                                                       |
+-----------------------------------------------------------------------+
```

## 33.2. Event Systems

Each language has a native mechanism for emitting and consuming job lifecycle events. Understanding these differences is critical for building cross-runtime dashboards.

### Event Reference

All EchoMQ runtimes emit equivalent lifecycle events, though the delivery mechanism differs.

| Lifecycle Event | Elixir | Go | Node.js |
|-----------------|--------|----|---------|
| Job added | `[:echomq, :job, :add]` | `EmitWaiting()` | `"waiting"` |
| Job active | `[:echomq, :job, :start]` | `EmitActive()` | `"active"` |
| Job completed | `[:echomq, :job, :complete]` | `EmitCompleted()` | `"completed"` |
| Job failed | `[:echomq, :job, :fail]` | `EmitFailed()` | `"failed"` |
| Job retried | `[:echomq, :job, :retry]` | `EmitRetry()` | `"waiting"` (re-enqueue) |
| Job progress | `[:echomq, :job, :progress]` | `EmitProgress()` | `"progress"` |
| Job stalled | `[:echomq, :worker, :stalled_check]` | `EmitStalled()` | `"stalled"` |

### Attaching Event Handlers

<tabs>
<tab title="Elixir">

> **Benefit**: Zero-cost declarative PubSub -- events compile to no-ops when no handler is attached.

Elixir's `:telemetry` library provides a declarative, zero-cost event system. When no handler is attached, the event emission compiles down to a no-op. EchoMQ wraps this with convenience functions that auto-prefix event names with `[:echomq]`.

```elixir
defmodule Codemoji.GuessMetrics do
  @moduledoc "Telemetry handlers for guess processing observability."

  require Logger

  def setup do
    # Using EchoMQ convenience wrapper (auto-prefixed with [:echomq])
    EchoMQ.Telemetry.attach_many("codemoji-guess-metrics", [
      [:job, :complete],
      [:job, :fail],
      [:job, :retry],
      [:rate_limit, :hit]
    ], &__MODULE__.handle_event/4)

    # Raw :telemetry for worker-level events
    :telemetry.attach(
      "codemoji-worker-monitor",
      [:echomq, :worker, :stalled_check],
      &__MODULE__.handle_stalled/4,
      nil
    )
  end

  def handle_event([:echomq, :job, :complete], measurements, metadata, _config) do
    duration_ms = System.convert_time_unit(measurements.duration, :native, :millisecond)
    Logger.info("[guess] Job #{metadata.job_id} completed in #{duration_ms}ms",
      queue: metadata.queue, job_name: metadata.job_name)
  end

  def handle_event([:echomq, :job, :fail], _measurements, metadata, _config) do
    Logger.error("[guess] Job #{metadata.job_id} failed: #{inspect(metadata.error)}",
      queue: metadata.queue)
  end

  def handle_event([:echomq, :job, :retry], measurements, metadata, _config) do
    Logger.warning("[guess] Retry ##{measurements.attempt} for #{metadata.job_id}, " <>
      "delay #{measurements.delay}ms")
  end

  def handle_event([:echomq, :rate_limit, :hit], measurements, metadata, _config) do
    Logger.warning("[guess] Rate limit on #{metadata.queue}: pausing #{measurements.delay}ms")
  end

  def handle_stalled(_, %{recovered: recovered, failed: failed}, %{queue: queue}, _) do
    if recovered > 0, do: Logger.info("[stalled] #{recovered} recovered in #{queue}")
    if failed > 0, do: Logger.error("[stalled] #{failed} permanently failed in #{queue}")
  end
end

# Call from Application.start/2
Codemoji.GuessMetrics.setup()
```

</tab>
<tab title="Go">

> **Tradeoff**: No in-process event bus -- instrument directly at call sites using `log/slog` or a metrics library.

Go's echomq-go package publishes events to Redis Streams via `EventEmitter`, but does not provide an in-process event bus. Instrument your processor function directly using `log/slog` or a metrics library.

```go
package main

import (
    "log/slog"
    "sync"
    "time"

    "github.com/fiberfx/echomq-go/pkg/echomq"
)

// instrumentedGuessProcessor wraps guess evaluation with telemetry.
// Since echomq-go has no :telemetry equivalent, we instrument at the call site.
func instrumentedGuessProcessor(job *echomq.Job) (interface{}, error) {
    start := time.Now()
    slog.Info("[guess] job started",
        "job_id", job.ID,
        "job_name", job.Name,
        "queue", "guess-evaluation",
    )

    result, err := evaluateGuess(job)
    duration := time.Since(start)

    if err != nil {
        slog.Error("[guess] job failed",
            "job_id", job.ID,
            "error", err.Error(),
            "duration_ms", duration.Milliseconds(),
        )
        return nil, err
    }

    slog.Info("[guess] job completed",
        "job_id", job.ID,
        "duration_ms", duration.Milliseconds(),
    )
    return result, nil
}

// For structured events similar to :telemetry, build a simple event bus:
type TelemetryEvent struct {
    Name         string
    Measurements map[string]interface{}
    Metadata     map[string]interface{}
}

type EventBus struct {
    handlers map[string][]func(TelemetryEvent)
    mu       sync.RWMutex
}

func NewEventBus() *EventBus {
    return &EventBus{handlers: make(map[string][]func(TelemetryEvent))}
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

</tab>
<tab title="Node.js">

> **Benefit**: Reactive EventEmitter pattern -- subscribe to lifecycle events without modifying processor code.

Node.js BullMQ uses the native EventEmitter pattern. Workers and QueueEvents instances emit lifecycle events that you subscribe to reactively.

```typescript
import { Worker, QueueEvents } from "bullmq";

const connection = { host: "localhost", port: 6379 };

// Worker events fire for jobs processed by THIS worker
const worker = new Worker("guess-evaluation", guessProcessor, {
  connection,
  concurrency: 10,
});

worker.on("completed", (job, result) => {
  const durationMs = job.finishedOn! - job.processedOn!;
  console.log(`[guess] Job ${job.id} completed in ${durationMs}ms`);
});

worker.on("failed", (job, err) => {
  console.error(`[guess] Job ${job?.id} failed: ${err.message}`);
});

worker.on("stalled", (jobId) => {
  console.warn(`[guess] Stalled job detected: ${jobId}`);
});

worker.on("progress", (job, progress) => {
  console.log(`[guess] Job ${job.id} progress: ${JSON.stringify(progress)}`);
});

// QueueEvents listens to the Redis event stream — sees ALL jobs, not just this worker's
const queueEvents = new QueueEvents("guess-evaluation", { connection });

queueEvents.on("completed", ({ jobId, returnvalue }) => {
  console.log(`[queue] Job ${jobId} completed: ${returnvalue}`);
});

queueEvents.on("failed", ({ jobId, failedReason }) => {
  console.error(`[queue] Job ${jobId} failed: ${failedReason}`);
});

queueEvents.on("waiting", ({ jobId }) => {
  console.log(`[queue] Job ${jobId} waiting`);
});
```

</tab>
</tabs>

### Telemetry Span Helper

EchoMQ's Elixir library includes a `span/3` function that wraps a function call with start/stop/exception telemetry events. The Go and Node.js equivalents require manual instrumentation or OpenTelemetry SDK calls.

<tabs>
<tab title="Elixir">

> **Benefit**: `span/3` wraps functions with start/stop/exception events automatically -- zero manual timing code.

```elixir
defmodule Codemoji.GuessProcessor do
  @moduledoc "Processes guess evaluation with telemetry span instrumentation."

  def process(job) do
    EchoMQ.Telemetry.span([:guess, :process], %{job_id: job.id}, fn ->
      # Validate the guess format (emits :start/:stop events)
      EchoMQ.Telemetry.span([:guess, :validate], %{job_id: job.id}, fn ->
        validate_guess(job.data)
      end)

      # Evaluate against the code (emits :start/:stop events)
      result = EchoMQ.Telemetry.span([:guess, :evaluate], %{job_id: job.id}, fn ->
        evaluate_against_code(job.data)
      end)

      # Update player score
      EchoMQ.Telemetry.span([:guess, :score], %{job_id: job.id}, fn ->
        update_player_score(result)
      end)

      {:ok, result}
    end)
  end
end

# Emitted events:
# [:echomq, :guess, :process, :start]
# [:echomq, :guess, :validate, :start]
# [:echomq, :guess, :validate, :stop]
# [:echomq, :guess, :evaluate, :start]
# [:echomq, :guess, :evaluate, :stop]
# [:echomq, :guess, :score, :start]
# [:echomq, :guess, :score, :stop]
# [:echomq, :guess, :process, :stop]
```

</tab>
<tab title="Go">

> **Benefit**: Generic `spanFunc` provides type-safe span wrapping via Go generics with structured logging.

```go
package main

import (
    "context"
    "log/slog"
    "time"
)

// spanFunc wraps a function call with start/stop logging, returning its result.
// This mirrors EchoMQ.Telemetry.span/3 for Go processors.
func spanFunc[T any](ctx context.Context, name string, meta map[string]string, fn func() (T, error)) (T, error) {
    start := time.Now()
    slog.Info(name+".start", "job_id", meta["job_id"])

    result, err := fn()
    duration := time.Since(start)

    if err != nil {
        slog.Error(name+".exception",
            "job_id", meta["job_id"],
            "error", err.Error(),
            "duration_ms", duration.Milliseconds(),
        )
        return result, err
    }

    slog.Info(name+".stop",
        "job_id", meta["job_id"],
        "duration_ms", duration.Milliseconds(),
    )
    return result, nil
}

func processGuess(ctx context.Context, job *echomq.Job) (interface{}, error) {
    meta := map[string]string{"job_id": job.ID}

    _, err := spanFunc(ctx, "guess.validate", meta, func() (bool, error) {
        return validateGuess(job.Data)
    })
    if err != nil {
        return nil, err
    }

    result, err := spanFunc(ctx, "guess.evaluate", meta, func() (*GuessResult, error) {
        return evaluateAgainstCode(job.Data)
    })
    if err != nil {
        return nil, err
    }

    _, err = spanFunc(ctx, "guess.score", meta, func() (bool, error) {
        return updatePlayerScore(result)
    })
    return result, err
}
```

</tab>
<tab title="Node.js">

> **Benefit**: `spanAsync` mirrors Elixir's `span/3` with `performance.now()` for sub-millisecond precision.

```typescript
// spanAsync wraps an async function with timing and error logging,
// mirroring EchoMQ.Telemetry.span/3 for Node.js processors.
async function spanAsync<T>(
  name: string,
  meta: Record<string, string>,
  fn: () => Promise<T>
): Promise<T> {
  const start = performance.now();
  console.log(`${name}.start`, meta);

  try {
    const result = await fn();
    const durationMs = (performance.now() - start).toFixed(1);
    console.log(`${name}.stop`, { ...meta, duration_ms: durationMs });
    return result;
  } catch (err) {
    const durationMs = (performance.now() - start).toFixed(1);
    console.error(`${name}.exception`, {
      ...meta,
      error: (err as Error).message,
      duration_ms: durationMs,
    });
    throw err;
  }
}

async function processGuess(job: Job): Promise<GuessResult> {
  const meta = { job_id: job.id! };

  await spanAsync("guess.validate", meta, () => validateGuess(job.data));

  const result = await spanAsync("guess.evaluate", meta, () =>
    evaluateAgainstCode(job.data)
  );

  await spanAsync("guess.score", meta, () => updatePlayerScore(result));

  return result;
}
```

</tab>
</tabs>

## 33.3. Metric Collection

Prometheus-compatible metrics follow the same naming convention across all three runtimes, ensuring that Grafana dashboards work regardless of which language processed the job.

### Metric Types

| Metric Type | Purpose | Codemoji Example |
|-------------|---------|------------------|
| **Counter** | Monotonically increasing count | Total guesses processed |
| **Histogram** | Distribution of observed values | Guess evaluation latency |
| **Gauge** | Current value that can go up or down | Pending jobs per game room |

### Registering Metrics

<tabs>
<tab title="Elixir">

> **Benefit**: Declarative metric definitions -- `TelemetryMetricsPrometheus` auto-translates events to Prometheus counters/histograms.

Using `Telemetry.Metrics` with `TelemetryMetricsPrometheus`, metric definitions are declarative. The reporter translates `:telemetry` events into Prometheus metrics automatically.

```elixir
defmodule Codemoji.Metrics do
  @moduledoc "Prometheus metric definitions for Codemoji EchoMQ queues."

  import Telemetry.Metrics

  def metrics do
    [
      # GUS: Guess processing throughput
      counter(
        "echomq.job.count",
        event_name: [:echomq, :job, :complete],
        tags: [:queue, :job_name],
        description: "Total jobs completed"
      ),

      # GUS: Guess evaluation latency histogram
      distribution(
        "echomq.job.duration",
        event_name: [:echomq, :job, :complete],
        measurement: :duration,
        unit: {:native, :millisecond},
        tags: [:queue, :job_name],
        reporter_options: [
          buckets: [10, 50, 100, 250, 500, 1000, 2500, 5000]
        ],
        description: "Job processing duration in milliseconds"
      ),

      # Failure counter for alerting
      counter(
        "echomq.job.failures",
        event_name: [:echomq, :job, :fail],
        tags: [:queue, :job_name],
        description: "Total jobs failed"
      ),

      # Rate limit hits for capacity planning
      counter(
        "echomq.rate_limit.hits",
        event_name: [:echomq, :rate_limit, :hit],
        tags: [:queue],
        description: "Rate limit events"
      ),

      # Worker concurrency gauge
      last_value(
        "echomq.worker.concurrency",
        event_name: [:echomq, :worker, :start],
        measurement: :concurrency,
        tags: [:queue],
        description: "Worker concurrency level"
      )
    ]
  end
end

# In your supervision tree (application.ex)
children = [
  {TelemetryMetricsPrometheus, metrics: Codemoji.Metrics.metrics()}
]
```

</tab>
<tab title="Go">

> **Benefit**: `promauto` registers metrics at init time -- type-safe labels via `CounterVec` and `HistogramVec`.

Go uses `prometheus/client_golang` directly. Metrics are registered at init time and updated imperatively in the processor function.

```go
package metrics

import (
    "github.com/prometheus/client_golang/prometheus"
    "github.com/prometheus/client_golang/prometheus/promauto"
)

var (
    // GUS: Guess processing throughput
    JobsCompleted = promauto.NewCounterVec(
        prometheus.CounterOpts{
            Name: "echomq_job_count_total",
            Help: "Total jobs completed",
        },
        []string{"queue", "job_name"},
    )

    // GUS: Guess evaluation latency histogram
    JobDuration = promauto.NewHistogramVec(
        prometheus.HistogramOpts{
            Name:    "echomq_job_duration_milliseconds",
            Help:    "Job processing duration in milliseconds",
            Buckets: []float64{10, 50, 100, 250, 500, 1000, 2500, 5000},
        },
        []string{"queue", "job_name"},
    )

    // Failure counter
    JobsFailed = promauto.NewCounterVec(
        prometheus.CounterOpts{
            Name: "echomq_job_failures_total",
            Help: "Total jobs failed",
        },
        []string{"queue", "job_name"},
    )

    // ROM: Queue depth gauge
    QueueDepth = promauto.NewGaugeVec(
        prometheus.GaugeOpts{
            Name: "echomq_queue_depth",
            Help: "Number of pending jobs per queue",
        },
        []string{"queue"},
    )

    // TXN: Transaction processing rate
    TransactionsProcessed = promauto.NewCounterVec(
        prometheus.CounterOpts{
            Name: "echomq_transactions_total",
            Help: "Total payment transactions processed",
        },
        []string{"queue", "status"},
    )
)
```

</tab>
<tab title="Node.js">

> **Benefit**: `prom-client` singletons with `as const` labels provide type-safe Prometheus-compatible metrics.

Node.js uses `prom-client` for Prometheus-compatible metrics. Metrics are registered as module-level singletons and updated in event handlers.

```typescript
import { Counter, Histogram, Gauge, Registry } from "prom-client";

const register = new Registry();

// GUS: Guess processing throughput
const jobsCompleted = new Counter({
  name: "echomq_job_count_total",
  help: "Total jobs completed",
  labelNames: ["queue", "job_name"] as const,
  registers: [register],
});

// GUS: Guess evaluation latency histogram
const jobDuration = new Histogram({
  name: "echomq_job_duration_milliseconds",
  help: "Job processing duration in milliseconds",
  labelNames: ["queue", "job_name"] as const,
  buckets: [10, 50, 100, 250, 500, 1000, 2500, 5000],
  registers: [register],
});

// Failure counter
const jobsFailed = new Counter({
  name: "echomq_job_failures_total",
  help: "Total jobs failed",
  labelNames: ["queue", "job_name"] as const,
  registers: [register],
});

// ROM: Queue depth gauge
const queueDepth = new Gauge({
  name: "echomq_queue_depth",
  help: "Number of pending jobs per queue",
  labelNames: ["queue"] as const,
  registers: [register],
});

// TXN: Transaction processing rate
const transactionsProcessed = new Counter({
  name: "echomq_transactions_total",
  help: "Total payment transactions processed",
  labelNames: ["queue", "status"] as const,
  registers: [register],
});

export { register, jobsCompleted, jobDuration, jobsFailed, queueDepth };
```

</tab>
</tabs>

### Recording Metrics in Processors

<tabs>
<tab title="Elixir">

> **Benefit**: Metrics recorded automatically via `:telemetry` events -- no manual `.inc()` calls inside processors.

In Elixir, metrics are recorded automatically when `:telemetry` events fire. The `TelemetryMetricsPrometheus` reporter listens for the events defined in `metrics/0` and updates Prometheus counters/histograms. No manual `.inc()` calls are needed inside the processor -- you only need to ensure EchoMQ's built-in telemetry emissions are active.

```elixir
defmodule Codemoji.GuessWorker do
  @moduledoc """
  Worker for the guess-evaluation queue.
  Telemetry events fire automatically via EchoMQ internals -- the Prometheus
  reporter picks them up from the metric definitions in Codemoji.Metrics.
  """

  def start_link(opts) do
    EchoMQ.Worker.start_link(
      queue: "guess-evaluation",
      connection: opts[:redis],
      concurrency: 20,
      processor: &process/1
    )
  end

  defp process(job) do
    # EchoMQ automatically emits [:echomq, :job, :start] here
    result = evaluate_guess(job.data)
    # EchoMQ automatically emits [:echomq, :job, :complete] with duration
    {:ok, result}
  end
end

# For custom business metrics beyond EchoMQ events:
defmodule Codemoji.BusinessMetrics do
  def record_guess_outcome(room_id, outcome) do
    :telemetry.execute(
      [:codemoji, :guess, :outcome],
      %{count: 1},
      %{room_id: room_id, outcome: outcome}
    )
  end
end
```

</tab>
<tab title="Go">

> **Tradeoff**: Imperative metric updates at call sites -- processor must call `.Inc()` and `.Observe()` directly.

In Go, metric updates happen imperatively at the call site. The processor function calls `.Inc()`, `.Observe()`, and `.Set()` directly on the registered Prometheus metrics.

```go
package main

import (
    "context"
    "time"

    "github.com/fiberfx/echomq-go/pkg/echomq"
    "codemoji/internal/metrics"
)

func guessProcessor(job *echomq.Job) (interface{}, error) {
    start := time.Now()
    queueName := "guess-evaluation"
    jobName := job.Name

    result, err := evaluateGuess(context.Background(), job.Data)
    duration := time.Since(start)

    if err != nil {
        metrics.JobsFailed.WithLabelValues(queueName, jobName).Inc()
        return nil, err
    }

    // Record completion counter and duration histogram
    metrics.JobsCompleted.WithLabelValues(queueName, jobName).Inc()
    metrics.JobDuration.WithLabelValues(queueName, jobName).Observe(
        float64(duration.Milliseconds()),
    )

    // TXN: Track payment transactions if this is a prize distribution job
    if job.Name == "distribute-prize" {
        metrics.TransactionsProcessed.WithLabelValues(queueName, "success").Inc()
    }

    return result, nil
}
```

</tab>
<tab title="Node.js">

> **Benefit**: Event handler separation keeps processor clean -- metrics wired through `worker.on()` listeners.

In Node.js, wire metric updates to Worker event handlers. This keeps the processor function clean and separates business logic from observability.

```typescript
import { Worker } from "bullmq";
import { jobsCompleted, jobDuration, jobsFailed, queueDepth } from "./metrics";

const worker = new Worker("guess-evaluation", guessProcessor, {
  connection: { host: "localhost", port: 6379 },
  concurrency: 20,
});

// Record metrics from event handlers (not inside the processor)
worker.on("completed", (job) => {
  const queue = "guess-evaluation";
  const jobName = job.name;
  const durationMs = job.finishedOn! - job.processedOn!;

  jobsCompleted.inc({ queue, job_name: jobName });
  jobDuration.observe({ queue, job_name: jobName }, durationMs);
});

worker.on("failed", (job, err) => {
  jobsFailed.inc({ queue: "guess-evaluation", job_name: job?.name ?? "unknown" });
});

// Periodically update queue depth gauge
setInterval(async () => {
  const counts = await queue.getJobCounts("waiting", "active", "delayed");
  queueDepth.set({ queue: "guess-evaluation" }, counts.waiting + counts.delayed);
}, 5000);
```

</tab>
</tabs>

## 33.4. Prometheus Integration

All three runtimes expose a `/metrics` HTTP endpoint that Prometheus scrapes. The metric names use the same `echomq_` prefix, so a single Grafana dashboard works across runtimes.

### Exposing the Metrics Endpoint

<tabs>
<tab title="Elixir">

> **Benefit**: Standalone Cowboy server auto-started, or serve via Phoenix Plug for single-port deployments.

`TelemetryMetricsPrometheus` starts its own Cowboy HTTP server on port 9568 by default. For Phoenix applications, you can serve metrics from a dedicated plug instead.

```elixir
# Option 1: Standalone (auto-started by TelemetryMetricsPrometheus)
# Scrape at http://localhost:9568/metrics

# Option 2: Phoenix Plug (serve from the app's own port)
defmodule CodemojiFrontendWeb.MetricsPlug do
  @behaviour Plug

  def init(opts), do: opts

  def call(conn, _opts) do
    metrics = TelemetryMetricsPrometheus.Core.scrape()

    conn
    |> Plug.Conn.put_resp_content_type("text/plain")
    |> Plug.Conn.send_resp(200, metrics)
  end
end

# In router.ex
scope "/internal" do
  get "/metrics", CodemojiFrontendWeb.MetricsPlug, :call
end
```

</tab>
<tab title="Go">

> **Benefit**: `promhttp.Handler()` serves the default registry -- single line to add a metrics endpoint.

Go's `promhttp` handler serves the default registry. Add it to your HTTP server alongside the application routes.

```go
package main

import (
    "net/http"

    "github.com/prometheus/client_golang/prometheus/promhttp"
)

func main() {
    // Serve metrics on a dedicated port
    go func() {
        mux := http.NewServeMux()
        mux.Handle("/metrics", promhttp.Handler())
        http.ListenAndServe(":9090", mux)
    }()

    // Start EchoMQ worker
    worker := echomq.NewWorker("guess-evaluation", redisClient, echomq.WorkerOptions{
        Concurrency: 20,
    })
    worker.Process(guessProcessor)
    worker.Start(context.Background())
}
```

</tab>
<tab title="Node.js">

> **Benefit**: `register.metrics()` serializes all registered metrics in Prometheus exposition format.

Node.js uses `prom-client` with an Express or Fastify endpoint. The `register.metrics()` call serializes all registered metrics in Prometheus exposition format.

```typescript
import express from "express";
import { register } from "./metrics";

const app = express();

// Serve Prometheus metrics
app.get("/metrics", async (_req, res) => {
  res.set("Content-Type", register.contentType);
  res.end(await register.metrics());
});

app.listen(9090, () => {
  console.log("Metrics server running on :9090/metrics");
});
```

</tab>
</tabs>

### Prometheus Scrape Configuration

A single `prometheus.yml` can scrape all three runtimes. The `runtime` label distinguishes the source while keeping metric names identical.

```yaml
# prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: "codemoji-elixir"
    static_configs:
      - targets: ["elixir-worker:9568"]
        labels:
          runtime: "elixir"

  - job_name: "codemoji-go"
    static_configs:
      - targets: ["go-worker:9090"]
        labels:
          runtime: "go"

  - job_name: "codemoji-nodejs"
    static_configs:
      - targets: ["node-worker:9090"]
        labels:
          runtime: "nodejs"
```

## 33.5. Grafana Dashboard Queries

These PromQL queries work across all three runtimes because the metric names follow the same `echomq_` convention. Use the `runtime` label to filter or aggregate by language.

### Guess Processing Throughput (GUS)

```promql
# Total guesses per second across all runtimes
sum(rate(echomq_job_count_total{queue="guess-evaluation"}[5m]))

# Throughput broken down by runtime
sum by (runtime) (rate(echomq_job_count_total{queue="guess-evaluation"}[5m]))
```

### Prize Distribution Latency (BNK)

```promql
# P50 latency for prize distribution
histogram_quantile(0.50,
  rate(echomq_job_duration_milliseconds_bucket{queue="prize-distribution"}[5m])
)

# P95 latency
histogram_quantile(0.95,
  rate(echomq_job_duration_milliseconds_bucket{queue="prize-distribution"}[5m])
)

# P99 latency
histogram_quantile(0.99,
  rate(echomq_job_duration_milliseconds_bucket{queue="prize-distribution"}[5m])
)
```

### Game Room Queue Depth (ROM)

```promql
# Pending jobs per game room queue
echomq_queue_depth{queue=~"room-.*"}

# Average queue depth across all rooms
avg(echomq_queue_depth{queue=~"room-.*"})
```

### Transaction Processing Rate (TXN)

```promql
# Payment transactions per second
sum(rate(echomq_transactions_total{queue="prize-distribution", status="success"}[5m]))

# Failure ratio
sum(rate(echomq_transactions_total{status="failed"}[5m]))
  /
sum(rate(echomq_transactions_total[5m]))
```

### Failure Rate Alerting

```promql
# Alert: Failure rate exceeds 5% over 10 minutes
sum(rate(echomq_job_failures_total{queue="guess-evaluation"}[10m]))
  /
sum(rate(echomq_job_count_total{queue="guess-evaluation"}[10m]))
  > 0.05
```

### Player Activity (PLR)

```promql
# Active players submitting guesses (proxy: unique job names per minute)
count(
  count by (job_name) (
    rate(echomq_job_count_total{queue="guess-evaluation"}[1m]) > 0
  )
)
```

## 33.6. OpenTelemetry & Distributed Tracing

OpenTelemetry enables distributed tracing across service boundaries. When a job is enqueued, the current trace context is serialized into the job's metadata. When a worker picks up the job, the context is deserialized and a child span is created, maintaining trace continuity through Redis.

### Installation & Configuration

<tabs>
<tab title="Elixir">

> **Benefit**: Declarative config via `config/runtime.exs` -- exporter protocol and endpoint separated from code.

```elixir
# mix.exs
defp deps do
  [
    {:echomq, "~> 1.0"},
    {:opentelemetry_api, "~> 1.0"},
    {:opentelemetry, "~> 1.0"},
    {:opentelemetry_exporter, "~> 1.0"}
  ]
end

# config/runtime.exs
config :opentelemetry,
  resource: [service: [name: "codemoji-elixir"]],
  span_processor: :batch,
  traces_exporter: :otlp

config :opentelemetry_exporter,
  otlp_protocol: :http_protobuf,
  otlp_endpoint: "http://localhost:4318"
```

</tab>
<tab title="Go">

> **Tradeoff**: Programmatic setup required -- `TracerProvider` must be initialized explicitly in `main()`.

```go
// go.mod dependencies:
//   go.opentelemetry.io/otel v1.24.0
//   go.opentelemetry.io/otel/sdk v1.24.0
//   go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracehttp v1.24.0

package main

import (
    "context"

    "go.opentelemetry.io/otel"
    "go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracehttp"
    "go.opentelemetry.io/otel/sdk/resource"
    sdktrace "go.opentelemetry.io/otel/sdk/trace"
    semconv "go.opentelemetry.io/otel/semconv/v1.24.0"
)

func initTracer(ctx context.Context) (*sdktrace.TracerProvider, error) {
    exporter, err := otlptracehttp.New(ctx,
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
            semconv.ServiceNameKey.String("codemoji-go"),
        )),
    )
    otel.SetTracerProvider(tp)
    return tp, nil
}
```

</tab>
<tab title="Node.js">

> **Benefit**: `NodeSDK` provides one-liner initialization with automatic async context propagation.

```typescript
// package.json dependencies:
//   "@opentelemetry/api": "^1.8.0"
//   "@opentelemetry/sdk-node": "^0.50.0"
//   "@opentelemetry/exporter-trace-otlp-http": "^0.50.0"
//   "@opentelemetry/resources": "^1.22.0"
//   "@opentelemetry/semantic-conventions": "^1.22.0"

import { NodeSDK } from "@opentelemetry/sdk-node";
import { OTLPTraceExporter } from "@opentelemetry/exporter-trace-otlp-http";
import { Resource } from "@opentelemetry/resources";
import {
  ATTR_SERVICE_NAME,
} from "@opentelemetry/semantic-conventions";

const sdk = new NodeSDK({
  resource: new Resource({
    [ATTR_SERVICE_NAME]: "codemoji-nodejs",
  }),
  traceExporter: new OTLPTraceExporter({
    url: "http://localhost:4318/v1/traces",
  }),
});

sdk.start();
```

</tab>
</tabs>

### Creating Spans in Job Processors

<tabs>
<tab title="Elixir">

> **Benefit**: Auto-created outer span when `telemetry: OpenTelemetry` is set -- only child spans need manual creation.

EchoMQ's OpenTelemetry adapter wraps the entire processor invocation in a span automatically when the `telemetry: EchoMQ.Telemetry.OpenTelemetry` option is set. Create child spans for sub-operations using the `trace/3` helper.

```elixir
alias EchoMQ.Telemetry.OpenTelemetry, as: Tracer

{:ok, worker} = EchoMQ.Worker.start_link(
  queue: "guess-evaluation",
  connection: :redis,
  telemetry: EchoMQ.Telemetry.OpenTelemetry,
  processor: fn job ->
    # Outer span "echomq.worker.process" is auto-created by the adapter.
    # Create child spans for sub-operations:
    Tracer.trace("guess.validate", [kind: :internal], fn _span ->
      validate_guess(job.data)
    end)

    result = Tracer.trace("guess.evaluate", [kind: :internal], fn span ->
      Tracer.set_attribute(span, "game.room_id", job.data["room_id"])
      Tracer.set_attribute(span, "game.player_id", job.data["player_id"])
      evaluate_against_code(job.data)
    end)

    Tracer.trace("guess.update_score", [kind: :client], fn span ->
      Tracer.set_attribute(span, "db.system", "postgresql")
      update_player_score(result)
    end)

    {:ok, result}
  end
)
```

</tab>
<tab title="Go">

> **Tradeoff**: Fully manual span lifecycle -- must pass `context.Context` through every call and end each span explicitly.

Go's OpenTelemetry SDK uses `otel.Tracer` and `context.Context` for explicit span creation. Pass the context through the call chain to maintain parent-child relationships.

```go
package main

import (
    "context"

    "go.opentelemetry.io/otel"
    "go.opentelemetry.io/otel/attribute"
    "go.opentelemetry.io/otel/codes"
    "go.opentelemetry.io/otel/trace"

    "github.com/fiberfx/echomq-go/pkg/echomq"
)

var tracer = otel.Tracer("codemoji-guess")

func tracedGuessProcessor(job *echomq.Job) (interface{}, error) {
    ctx := context.Background()

    ctx, span := tracer.Start(ctx, "echomq.worker.process",
        trace.WithAttributes(
            attribute.String("messaging.system", "echomq"),
            attribute.String("messaging.destination.name", "guess-evaluation"),
            attribute.String("messaging.message.id", job.ID),
            attribute.String("echomq.job.name", job.Name),
        ),
    )
    defer span.End()

    // Validate
    ctx, validateSpan := tracer.Start(ctx, "guess.validate")
    if err := validateGuess(job.Data); err != nil {
        validateSpan.RecordError(err)
        validateSpan.SetStatus(codes.Error, err.Error())
        validateSpan.End()
        span.SetStatus(codes.Error, "validation failed")
        return nil, err
    }
    validateSpan.End()

    // Evaluate
    ctx, evalSpan := tracer.Start(ctx, "guess.evaluate",
        trace.WithAttributes(
            attribute.String("game.room_id", job.Data["room_id"].(string)),
            attribute.String("game.player_id", job.Data["player_id"].(string)),
        ),
    )
    result, err := evaluateAgainstCode(ctx, job.Data)
    if err != nil {
        evalSpan.RecordError(err)
        evalSpan.SetStatus(codes.Error, err.Error())
        evalSpan.End()
        return nil, err
    }
    evalSpan.End()

    // Update score
    _, scoreSpan := tracer.Start(ctx, "guess.update_score",
        trace.WithAttributes(attribute.String("db.system", "postgresql")),
    )
    if err := updatePlayerScore(result); err != nil {
        scoreSpan.RecordError(err)
        scoreSpan.End()
        return nil, err
    }
    scoreSpan.End()

    span.SetStatus(codes.Ok, "")
    return result, nil
}
```

</tab>
<tab title="Node.js">

> **Benefit**: `startActiveSpan` auto-propagates context through async boundaries -- no manual context passing.

Node.js uses the `@opentelemetry/api` `tracer.startActiveSpan()` pattern. The SDK automatically propagates context through async boundaries.

```typescript
import { trace, SpanStatusCode, context } from "@opentelemetry/api";

const tracer = trace.getTracer("codemoji-guess");

async function tracedGuessProcessor(job: Job): Promise<GuessResult> {
  return tracer.startActiveSpan(
    "echomq.worker.process",
    {
      attributes: {
        "messaging.system": "echomq",
        "messaging.destination.name": "guess-evaluation",
        "messaging.message.id": job.id!,
        "echomq.job.name": job.name,
      },
    },
    async (span) => {
      try {
        // Validate
        await tracer.startActiveSpan("guess.validate", async (valSpan) => {
          await validateGuess(job.data);
          valSpan.end();
        });

        // Evaluate
        const result = await tracer.startActiveSpan(
          "guess.evaluate",
          {
            attributes: {
              "game.room_id": job.data.roomId,
              "game.player_id": job.data.playerId,
            },
          },
          async (evalSpan) => {
            const res = await evaluateAgainstCode(job.data);
            evalSpan.end();
            return res;
          }
        );

        // Update score
        await tracer.startActiveSpan("guess.update_score", async (scoreSpan) => {
          scoreSpan.setAttribute("db.system", "postgresql");
          await updatePlayerScore(result);
          scoreSpan.end();
        });

        span.setStatus({ code: SpanStatusCode.OK });
        span.end();
        return result;
      } catch (err) {
        span.recordException(err as Error);
        span.setStatus({
          code: SpanStatusCode.ERROR,
          message: (err as Error).message,
        });
        span.end();
        throw err;
      }
    }
  );
}
```

</tab>
</tabs>

### Context Propagation Across Redis

The key to cross-language tracing is W3C Trace Context propagation. When a job is enqueued, the `traceparent` header is serialized into the job's metadata field. When a worker in any language picks up the job, it deserializes the context and creates a child span.

```
+-----------------------------------------------------------------------+
|                    TRACE PROPAGATION VIA REDIS                        |
+-----------------------------------------------------------------------+
|                                                                       |
|   [Service A]              [Redis]              [Service B]           |
|   (any language)                                (any language)        |
|        |                      |                      |                |
|   Add Job with                |                      |                |
|   traceparent  --------->  Store in              Process Job          |
|   in metadata             job hash  ---------->  Extract traceparent  |
|        |                      |                  Create child span    |
|   +----------+          +----------+          +----------+            |
|   | Span A   |--------->|telemetry |--------->| Span B   |           |
|   |(producer)|          |_metadata |          |(consumer)|           |
|   +----------+          +----------+          +----------+            |
|                                                                       |
|   traceparent: "00-<trace_id>-<span_id>-01"                          |
|   Same trace_id across all services                                   |
+-----------------------------------------------------------------------+
```

<tabs>
<tab title="Elixir">

> **Benefit**: Automatic W3C Trace Context propagation when `telemetry: OpenTelemetry` is set on both Queue and Worker.

EchoMQ's OpenTelemetry adapter handles propagation automatically when `telemetry: EchoMQ.Telemetry.OpenTelemetry` is set on both the Queue and Worker.

```elixir
# Producer: trace context serialized automatically
{:ok, queue} = EchoMQ.Queue.start_link(
  name: :guess_queue,
  connection: :redis,
  telemetry: EchoMQ.Telemetry.OpenTelemetry
)

# Inside a traced context, the traceparent is injected into job metadata
require OpenTelemetry.Tracer, as: Tracer
Tracer.with_span "api.submit_guess" do
  # Context propagated: traceparent stored in telemetry_metadata
  {:ok, job} = EchoMQ.Queue.add(queue, "evaluate-guess", %{
    room_id: "ROM0K48QjihpC4",
    player_id: "PLR3QR5T7V9W2X",
    guess: [1, 2, 3, 4]
  })
end

# Consumer: trace context deserialized, child span created
{:ok, worker} = EchoMQ.Worker.start_link(
  queue: "guess-evaluation",
  connection: :redis,
  telemetry: EchoMQ.Telemetry.OpenTelemetry,
  processor: fn job ->
    # This processor runs inside a child span linked to the producer's span
    evaluate_guess(job.data)
  end
)
```

</tab>
<tab title="Go">

> **Tradeoff**: Manual `traceparent` injection/extraction -- serialize trace context into job data field explicitly.

Go requires manual trace context injection and extraction. Serialize the `traceparent` into the job data when producing, and extract it when consuming.

```go
package main

import (
    "context"
    "encoding/json"

    "go.opentelemetry.io/otel"
    "go.opentelemetry.io/otel/propagation"
)

// injectTraceContext serializes the current trace context into a map
// that can be stored as part of the job data.
func injectTraceContext(ctx context.Context) map[string]string {
    carrier := propagation.MapCarrier{}
    otel.GetTextMapPropagator().Inject(ctx, carrier)
    return carrier
}

// extractTraceContext deserializes trace context from job data.
func extractTraceContext(ctx context.Context, headers map[string]string) context.Context {
    carrier := propagation.MapCarrier(headers)
    return otel.GetTextMapPropagator().Extract(ctx, carrier)
}

// Producer: inject traceparent before adding job
func enqueueGuess(ctx context.Context, producer *echomq.Producer, guess GuessData) error {
    ctx, span := tracer.Start(ctx, "api.submit_guess")
    defer span.End()

    traceHeaders := injectTraceContext(ctx)
    jobData := map[string]interface{}{
        "room_id":       guess.RoomID,
        "player_id":     guess.PlayerID,
        "guess":         guess.Values,
        "trace_context": traceHeaders, // W3C headers stored in job
    }

    return producer.Add(ctx, "evaluate-guess", jobData, echomq.JobOptions{})
}

// Consumer: extract traceparent and create child span
func tracedProcessor(job *echomq.Job) (interface{}, error) {
    ctx := context.Background()

    // Extract trace context from job data
    if tc, ok := job.Data["trace_context"].(map[string]interface{}); ok {
        headers := make(map[string]string)
        for k, v := range tc {
            headers[k] = v.(string)
        }
        ctx = extractTraceContext(ctx, headers)
    }

    ctx, span := tracer.Start(ctx, "echomq.worker.process")
    defer span.End()

    return evaluateGuess(ctx, job.Data)
}
```

</tab>
<tab title="Node.js">

> **Tradeoff**: Manual inject/extract via `propagation` API -- or use `bullmq-otel` community package for automation.

Node.js can use the `bullmq-otel` community package for automatic propagation, or inject/extract manually using the OpenTelemetry SDK.

```typescript
import { trace, context, propagation } from "@opentelemetry/api";
import { Queue, Worker } from "bullmq";

const tracer = trace.getTracer("codemoji-nodejs");

// Producer: inject traceparent into job data
async function enqueueGuess(queue: Queue, guess: GuessData): Promise<void> {
  await tracer.startActiveSpan("api.submit_guess", async (span) => {
    // Extract current trace context into a carrier object
    const traceContext: Record<string, string> = {};
    propagation.inject(context.active(), traceContext);

    await queue.add("evaluate-guess", {
      room_id: guess.roomId,
      player_id: guess.playerId,
      guess: guess.values,
      trace_context: traceContext, // W3C headers stored in job
    });

    span.end();
  });
}

// Consumer: extract traceparent and create child span
const worker = new Worker(
  "guess-evaluation",
  async (job) => {
    const traceHeaders = job.data.trace_context ?? {};
    const parentCtx = propagation.extract(context.active(), traceHeaders);

    return context.with(parentCtx, () =>
      tracer.startActiveSpan("echomq.worker.process", async (span) => {
        try {
          const result = await evaluateGuess(job.data);
          span.end();
          return result;
        } catch (err) {
          span.recordException(err as Error);
          span.end();
          throw err;
        }
      })
    );
  },
  { connection: { host: "localhost", port: 6379 } }
);
```

</tab>
</tabs>

## 33.7. Custom Telemetry Backends

Each language provides an extension point for plugging in custom telemetry implementations beyond the built-in options.

<tabs>
<tab title="Elixir">

> **Benefit**: `Behaviour` callbacks provide a formal contract for custom backends -- plug in Datadog, Honeycomb, etc.

Implement the `EchoMQ.Telemetry.Behaviour` callbacks to create a custom tracing backend. The behaviour defines contracts for span lifecycle, context propagation, and attribute management.

```elixir
defmodule Codemoji.DatadogTelemetry do
  @moduledoc "Custom telemetry backend that sends traces to Datadog."
  @behaviour EchoMQ.Telemetry.Behaviour

  @impl true
  def start_span(name, opts) do
    %{
      name: name,
      start_time: System.monotonic_time(),
      attributes: Keyword.get(opts, :attributes, %{}),
      kind: Keyword.get(opts, :kind, :internal)
    }
  end

  @impl true
  def end_span(span, status) do
    duration = System.monotonic_time() - span.start_time
    duration_ms = System.convert_time_unit(duration, :native, :millisecond)

    Datadog.send_span(%{
      name: span.name,
      duration_ms: duration_ms,
      status: status,
      attributes: span.attributes
    })
    :ok
  end

  @impl true
  def serialize_context(_span), do: nil

  @impl true
  def deserialize_context(_metadata), do: nil

  @impl true
  def record_exception(span, exception, _stacktrace) do
    Datadog.send_error(span.name, Exception.message(exception))
    :ok
  end

  @impl true
  def set_attribute(span, key, value) do
    %{span | attributes: Map.put(span.attributes, key, value)}
  end

  @impl true
  def get_current_context, do: nil
  @impl true
  def with_context(_ctx, fun), do: fun.()
  @impl true
  def add_event(_span, _name, _attrs), do: :ok
end

# Use it:
{:ok, worker} = EchoMQ.Worker.start_link(
  queue: "guess-evaluation",
  connection: :redis,
  telemetry: Codemoji.DatadogTelemetry,
  processor: &process/1
)
```

</tab>
<tab title="Go">

> **Benefit**: Middleware pattern wraps processor transparently -- `Backend` interface requires only 2 methods.

Go uses middleware functions around the processor. Create a wrapper that intercepts job processing and sends telemetry to your preferred backend.

```go
package telemetry

import (
    "time"

    "github.com/fiberfx/echomq-go/pkg/echomq"
)

// Backend defines the interface for custom telemetry backends.
type Backend interface {
    RecordJob(queue, jobName, jobID string, duration time.Duration, err error)
    RecordQueueDepth(queue string, depth int)
}

// Middleware wraps a processor with telemetry instrumentation.
func Middleware(backend Backend, queue string) func(echomq.ProcessorFunc) echomq.ProcessorFunc {
    return func(next echomq.ProcessorFunc) echomq.ProcessorFunc {
        return func(job *echomq.Job) (interface{}, error) {
            start := time.Now()
            result, err := next(job)
            duration := time.Since(start)

            backend.RecordJob(queue, job.Name, job.ID, duration, err)
            return result, err
        }
    }
}

// DatadogBackend sends metrics to Datadog via DogStatsD.
type DatadogBackend struct {
    client *statsd.Client
}

func (d *DatadogBackend) RecordJob(queue, jobName, jobID string, duration time.Duration, err error) {
    tags := []string{"queue:" + queue, "job_name:" + jobName}
    status := "success"
    if err != nil {
        status = "failure"
    }
    tags = append(tags, "status:"+status)

    d.client.Incr("echomq.job.count", tags, 1)
    d.client.Timing("echomq.job.duration", duration, tags, 1)
}
```

</tab>
<tab title="Node.js">

> **Benefit**: Event hook subscription separates telemetry from processor -- attach or detach backends at runtime.

Node.js uses event hooks and wrapper functions. Create a telemetry plugin that subscribes to Worker events and forwards them to your backend.

```typescript
interface TelemetryBackend {
  recordJob(
    queue: string,
    jobName: string,
    jobId: string,
    durationMs: number,
    error?: Error
  ): void;
  recordQueueDepth(queue: string, depth: number): void;
}

// Datadog backend using hot-shots (DogStatsD client)
class DatadogBackend implements TelemetryBackend {
  constructor(private client: StatsD) {}

  recordJob(
    queue: string,
    jobName: string,
    jobId: string,
    durationMs: number,
    error?: Error
  ): void {
    const tags = [`queue:${queue}`, `job_name:${jobName}`];
    const status = error ? "failure" : "success";
    tags.push(`status:${status}`);

    this.client.increment("echomq.job.count", tags);
    this.client.histogram("echomq.job.duration", durationMs, tags);
  }

  recordQueueDepth(queue: string, depth: number): void {
    this.client.gauge("echomq.queue.depth", depth, [`queue:${queue}`]);
  }
}

// Attach the backend to a Worker
function attachTelemetry(worker: Worker, queue: string, backend: TelemetryBackend) {
  worker.on("completed", (job) => {
    const durationMs = job.finishedOn! - job.processedOn!;
    backend.recordJob(queue, job.name, job.id!, durationMs);
  });

  worker.on("failed", (job, err) => {
    const durationMs = Date.now() - (job?.processedOn ?? Date.now());
    backend.recordJob(queue, job?.name ?? "unknown", job?.id ?? "?", durationMs, err);
  });
}
```

</tab>
</tabs>

## 33.8. Cross-Language Tracing

The most powerful feature of EchoMQ's polyglot design is that a job can be enqueued by a Go service, processed by an Elixir worker, trigger a child job consumed by a Node.js service, and the entire chain shows up as a single distributed trace in Jaeger.

### Trace Flow Diagram

```
[Go API Server]         [Elixir Worker]          [Node.js Worker]
      |                       |                         |
  POST /guess                 |                         |
  (creates span)              |                         |
      |                       |                         |
  enqueue job with            |                         |
  traceparent -------> Redis: guess-evaluation          |
      |                       |                         |
      |                 pick up job                     |
      |                 extract traceparent             |
      |                 (child span) ----+              |
      |                       |          |              |
      |                 evaluate guess   |              |
      |                       |          |              |
      |                 enqueue prize    |              |
      |                 with traceparent |              |
      |                       | -------> Redis: prize-distribution
      |                       |                         |
      |                       |                  pick up job
      |                       |                  extract traceparent
      |                       |                  (grandchild span)
      |                       |                         |
      |                       |                  distribute prize
      |                       |                         |
  <-- response                |                         |
      |                       |                         |
  All three spans share the same trace_id
```

### End-to-End Example

<tabs>
<tab title="Elixir">

> **Benefit**: Middle of the trace chain -- context automatically restored from Go producer and propagated to Node.js consumer.

The Elixir worker sits in the middle of the trace chain. It extracts the trace context from the incoming job (set by the Go producer), creates a child span for its own processing, then propagates context forward when enqueuing a child job for the Node.js worker.

```elixir
defmodule Codemoji.GuessWorker do
  @moduledoc """
  Processes guess evaluations. Extracts trace context from Go API server,
  propagates it to the prize distribution queue consumed by Node.js.
  """

  alias EchoMQ.Telemetry.OpenTelemetry, as: Tracer

  def start_link(opts) do
    EchoMQ.Worker.start_link(
      queue: "guess-evaluation",
      connection: opts[:redis],
      telemetry: EchoMQ.Telemetry.OpenTelemetry,
      processor: &process/1
    )
  end

  defp process(job) do
    # Trace context is automatically restored by the OpenTelemetry adapter.
    # This span is a child of the Go API's "api.submit_guess" span.

    result = Tracer.trace("guess.evaluate", [kind: :internal], fn span ->
      Tracer.set_attribute(span, "game.room_id", job.data["room_id"])
      evaluate_against_code(job.data)
    end)

    # If the guess was correct, enqueue prize distribution.
    # The trace context propagates forward to the Node.js worker.
    if result.correct? do
      Tracer.trace("prize.enqueue", [kind: :producer, propagate: true], fn _span, _metadata ->
        {:ok, _} = EchoMQ.Queue.add(:prize_queue, "distribute-prize", %{
          player_id: job.data["player_id"],
          room_id: job.data["room_id"],
          prize_amount: result.prize_amount
        })
      end)
    end

    {:ok, result}
  end
end
```

</tab>
<tab title="Go">

> **Benefit**: Root span creation with full W3C propagation -- `MapCarrier` serializes trace context into job data.

The Go API server starts the trace. It creates the root span when receiving the HTTP request, then propagates the trace context into the EchoMQ job for the Elixir worker to continue.

```go
package api

import (
    "context"
    "encoding/json"
    "net/http"

    "go.opentelemetry.io/otel"
    "go.opentelemetry.io/otel/propagation"

    "github.com/fiberfx/echomq-go/pkg/echomq"
)

var tracer = otel.Tracer("codemoji-api")

func submitGuessHandler(producer *echomq.Producer) http.HandlerFunc {
    return func(w http.ResponseWriter, r *http.Request) {
        // Extract incoming trace context (from upstream load balancer / gateway)
        ctx := otel.GetTextMapPropagator().Extract(r.Context(), propagation.HeaderCarrier(r.Header))

        ctx, span := tracer.Start(ctx, "api.submit_guess")
        defer span.End()

        var guess GuessRequest
        json.NewDecoder(r.Body).Decode(&guess)

        // Inject trace context into job data for cross-language propagation
        traceHeaders := make(map[string]string)
        otel.GetTextMapPropagator().Inject(ctx, propagation.MapCarrier(traceHeaders))

        jobData := map[string]interface{}{
            "room_id":       guess.RoomID,
            "player_id":     guess.PlayerID,
            "guess":         guess.Values,
            "trace_context": traceHeaders,
        }

        err := producer.Add(ctx, "evaluate-guess", jobData, echomq.JobOptions{})
        if err != nil {
            span.RecordError(err)
            http.Error(w, "Failed to enqueue guess", 500)
            return
        }

        w.WriteHeader(http.StatusAccepted)
        json.NewEncoder(w).Encode(map[string]string{"status": "queued"})
    }
}
```

</tab>
<tab title="Node.js">

> **Benefit**: Final consumer extracts trace context from any upstream language via `propagation.extract()`.

The Node.js worker is the final consumer in the trace chain. It extracts the trace context that originated in Go, passed through Elixir, and creates the final child span for prize distribution.

```typescript
import { trace, context, propagation, SpanStatusCode } from "@opentelemetry/api";
import { Worker } from "bullmq";

const tracer = trace.getTracer("codemoji-prize");

const prizeWorker = new Worker(
  "prize-distribution",
  async (job) => {
    // Extract trace context propagated from the Elixir worker
    const traceHeaders = job.data.trace_context ?? {};
    const parentCtx = propagation.extract(context.active(), traceHeaders);

    return context.with(parentCtx, () =>
      tracer.startActiveSpan("prize.distribute", async (span) => {
        try {
          span.setAttribute("game.player_id", job.data.player_id);
          span.setAttribute("game.room_id", job.data.room_id);
          span.setAttribute("prize.amount", job.data.prize_amount);

          // Process the prize distribution (BNK entity)
          const txnResult = await distributePrize({
            playerId: job.data.player_id,
            amount: job.data.prize_amount,
          });

          span.setAttribute("txn.id", txnResult.transactionId);
          span.setStatus({ code: SpanStatusCode.OK });
          span.end();
          return txnResult;
        } catch (err) {
          span.recordException(err as Error);
          span.setStatus({
            code: SpanStatusCode.ERROR,
            message: (err as Error).message,
          });
          span.end();
          throw err;
        }
      })
    );
  },
  { connection: { host: "localhost", port: 6379 }, concurrency: 5 }
);
```

</tab>
</tabs>

### Jaeger Setup

Run Jaeger locally with Docker to visualize cross-language traces.

```yaml
# docker-compose.yml
services:
  jaeger:
    image: jaegertracing/all-in-one:latest
    ports:
      - "16686:16686"  # Jaeger UI
      - "4318:4318"    # OTLP HTTP receiver
    environment:
      - COLLECTOR_OTLP_ENABLED=true
```

Open `http://localhost:16686` to view traces. Search for service `codemoji-go` to find the root span, then drill into its children to see the Elixir and Node.js spans in a unified timeline.

## 33.9. Summary

| Aspect | Elixir | Go | Node.js |
|--------|--------|----|---------|
| **Event System** | `:telemetry` (declarative PubSub) | Manual at call site | EventEmitter (reactive) |
| **Metric Library** | `telemetry_metrics` + `prometheus` reporter | `prometheus/client_golang` | `prom-client` |
| **Span Creation** | `EchoMQ.Telemetry.OpenTelemetry.trace/3` | `otel.Tracer.Start()` | `tracer.startActiveSpan()` |
| **Context Propagation** | Automatic via adapter | Manual inject/extract | Manual inject/extract |
| **Custom Backend** | Implement `Behaviour` callbacks | Middleware function wrapper | Event hook subscription |
| **Zero-Cost Idle** | Yes (`:telemetry` no-ops) | No (explicit calls) | Partial (no listeners = no-op) |

---

*Previous: [Chapter 32: Supervision Patterns](ch32-otp-supervision.md) | Next: [Chapter 34: Framework Integration](ch34-framework-integration.md)*
