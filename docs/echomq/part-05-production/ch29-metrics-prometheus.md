# Chapter 29. Metrics & Prometheus

EchoMQ provides two complementary metrics systems for monitoring queue health and performance. **Built-in metrics** aggregate per-minute job counts in Redis, giving you historical throughput and failure data with zero external dependencies. **Telemetry-based metrics** emit real-time events that feed into Prometheus, StatsD, or any metrics backend. Together, they give an Arena game server complete visibility into combat queue throughput, matchmaking latency, and worker utilization.

This chapter covers both systems, shows how to bridge them into Prometheus for Grafana dashboards, and builds a complete Arena performance monitoring setup.

## 29.1. How Built-in Metrics Work

Built-in metrics track two counters per queue: **completed** and **failed** jobs. The counting happens inside the `moveToFinished` Lua script -- the same atomic script that transitions a job from `active` to `completed` or `failed`. After updating the job state, the script calls `collectMetrics`, which:

1. Increments a per-minute counter in a Redis list (`bull:{queue}:metrics:completed:data`)
2. Stores a metadata hash with total count and timestamp (`bull:{queue}:metrics:completed`)
3. Trims old data points beyond `maxDataPoints` to cap memory usage

```
moveToFinished Lua Script (atomic)
     |
     +-- Move job to completed/failed set
     |
     +-- Emit event to Redis Stream
     |
     +-- collectMetrics(metaKey, dataPointsList, maxDataPoints, timestamp)
              |
              +-- HINCRBY metaKey "count" 1       (total count)
              +-- Check if minute boundary crossed
              +-- If yes: RPUSH dataPointsList count  (new minute bucket)
              +-- LTRIM dataPointsList to maxDataPoints
```

The result is a time series of per-minute job counts stored entirely in Redis, queryable without any external metrics infrastructure. Each queue's metrics data uses approximately 120KB of Redis RAM for two weeks of history at 1-minute resolution.

## 29.2. Enabling Metrics

Metrics collection is opt-in. Enable it by passing a `metrics` configuration to the worker with a `max_data_points` value. The value controls how many 1-minute data points to retain.

<tabs>
<tab title="Elixir">

```elixir
# Enable metrics with 2 weeks of 1-minute history
{:ok, worker} = EchoMQ.Worker.start_link(
  queue: "combat-actions",
  connection: :arena_redis,
  processor: &Arena.CombatProcessor.process/1,
  concurrency: 10,
  metrics: %{
    max_data_points: 20_160  # 14 days * 24 hours * 60 minutes
  }
)

# For shorter retention (saves Redis memory on high-throughput queues):
{:ok, matchmaking_worker} = EchoMQ.Worker.start_link(
  queue: "matchmaking",
  connection: :arena_redis,
  processor: &Arena.MatchmakingProcessor.process/1,
  metrics: %{
    max_data_points: 1_440  # 24 hours of 1-minute intervals
  }
)
```

> **Benefit**: `:telemetry` library provides structured metrics with zero overhead when no reporters are attached.

</tab>
<tab title="Go">

```go
// Feature: Built-in Metrics Collection
//
// Partially implemented in echomq-go. The collectMetrics Lua function
// exists in the moveToFinished script, but the Go Worker struct does
// not expose a metrics configuration option to pass maxDataPoints.
//
// The Lua script checks: if maxMetricsSize ~= "" then collectMetrics(...)
// Since Go does not pass maxMetricsSize, the collectMetrics branch
// is never entered (GAP-006).
//
// Workaround:
//   Query Redis directly for metrics stored by Elixir/Node.js workers
//   on the same queue, or use XLEN on the event stream as a throughput
//   proxy:
//
//   length, _ := rdb.XLen(ctx, "bull:combat-actions:events").Result()
//   fmt.Printf("Event stream entries: %d\n", length)
//
//   For custom counters, increment Redis keys in your processor:
//   rdb.Incr(ctx, "arena:metrics:combat:completed")
//
// Reference: PROTOCOL-GAPS.md GAP-006

worker := echomq.NewWorker("combat-actions", rdb, echomq.WorkerOptions{
    Concurrency: 10,
    // No metrics option available in Go yet
})
```

> **Benefit**: `prometheus/client_golang` is the canonical Prometheus client — direct histogram/counter support.

</tab>
<tab title="Node.js">

```typescript
import { Worker, MetricsTime } from "bullmq";

// Enable metrics with 2 weeks of 1-minute history
const worker = new Worker("combat-actions", combatProcessor, {
  connection: { host: "localhost", port: 6379 },
  concurrency: 10,
  metrics: {
    maxDataPoints: MetricsTime.ONE_WEEK * 2, // 20,160
  },
});

// MetricsTime convenience constants:
// MetricsTime.ONE_MINUTE  = 1
// MetricsTime.FIVE_MINUTES = 5
// MetricsTime.FIFTEEN_MINUTES = 15
// MetricsTime.ONE_HOUR = 60
// MetricsTime.ONE_DAY = 1440
// MetricsTime.ONE_WEEK = 10080

// Shorter retention for high-throughput queues
const matchmakingWorker = new Worker("matchmaking", matchmakingProcessor, {
  connection: { host: "localhost", port: 6379 },
  metrics: {
    maxDataPoints: MetricsTime.ONE_DAY, // 1,440
  },
});
```

> **Benefit**: `prom-client` registers metrics globally — all queue instances contribute to the same counters.

</tab>
</tabs>

> **⚠️ Go Gap**: Built-in Prometheus metrics export is not implemented. The `getMetrics` Lua script key is passed but metrics are never read back.
> **Proposed Solution**: Implement `Queue.ExportPrometheusMetrics()` using `getMetrics` Lua script. Expose via `promhttp.Handler()` with gauges for queue depth, job duration histograms, and counters for completed/failed jobs.

## 29.3. Querying Metrics

Once metrics are enabled, query them through the Queue API. You can fetch completed or failed counts, optionally specifying a time range.

<tabs>
<tab title="Elixir">

```elixir
# Get completed job metrics (all available data points)
{:ok, metrics} = EchoMQ.Queue.get_metrics("combat-actions", :completed,
  connection: :arena_redis
)

# metrics structure:
# %{
#   data: [15, 22, 18, 30, 25, ...],  # Jobs per minute (newest first)
#   count: 1250,                        # Total jobs in the queried range
#   meta: %{
#     count: 45_000,                    # Total jobs since queue started
#     prev_ts: 1707350400000,           # Previous minute timestamp
#     prev_count: 22                    # Previous minute's count
#   }
# }

# Get failed job metrics
{:ok, failed_metrics} = EchoMQ.Queue.get_metrics("combat-actions", :failed,
  connection: :arena_redis
)

# Query a specific range (start/end are list indexes, not timestamps)
{:ok, recent} = EchoMQ.Queue.get_metrics("combat-actions", :completed,
  connection: :arena_redis,
  start: 0,    # Newest
  end: 59      # Last 60 minutes
)
```

> **Benefit**: `:telemetry` library provides structured metrics with zero overhead when no reporters are attached.

</tab>
<tab title="Go">

```go
// Feature: Built-in Metrics Query (get_metrics)
//
// Not implemented in echomq-go. The Go package does not expose a
// Queue.GetMetrics() function. Metrics stored by Elixir/Node.js
// workers are accessible via direct Redis commands.
//
// Workaround:
//   Read the metrics Redis keys directly:
//
//     metaKey := fmt.Sprintf("bull:%s:metrics:completed", queueName)
//     dataKey := metaKey + ":data"
//
//     // Get total count
//     count, _ := rdb.HGet(ctx, metaKey, "count").Int64()
//
//     // Get per-minute data points
//     data, _ := rdb.LRange(ctx, dataKey, 0, 59).Result() // Last 60 minutes
//
//     fmt.Printf("Total completed: %d\n", count)
//     fmt.Printf("Last 60 minutes: %v\n", data)
//
// Reference: PROTOCOL-GAPS.md GAP-006

func getQueueMetrics(ctx context.Context, rdb *redis.Client, queue string, metricType string) (map[string]interface{}, error) {
    metaKey := fmt.Sprintf("bull:%s:metrics:%s", queue, metricType)
    dataKey := metaKey + ":data"

    // Get metadata
    totalCount, err := rdb.HGet(ctx, metaKey, "count").Int64()
    if err != nil && err != redis.Nil {
        return nil, fmt.Errorf("get metrics meta: %w", err)
    }

    // Get per-minute data points (last 60 minutes)
    dataStrings, err := rdb.LRange(ctx, dataKey, 0, 59).Result()
    if err != nil {
        return nil, fmt.Errorf("get metrics data: %w", err)
    }

    data := make([]int64, len(dataStrings))
    for i, s := range dataStrings {
        val, _ := strconv.ParseInt(s, 10, 64)
        data[i] = val
    }

    return map[string]interface{}{
        "count": totalCount,
        "data":  data,
    }, nil
}

// Usage:
// metrics, _ := getQueueMetrics(ctx, rdb, "combat-actions", "completed")
// fmt.Printf("Combat throughput: %v\n", metrics)
```

> **Benefit**: `prometheus/client_golang` is the canonical Prometheus client — direct histogram/counter support.

</tab>
<tab title="Node.js">

```typescript
import { Queue, MetricsTime } from "bullmq";

const queue = new Queue("combat-actions", {
  connection: { host: "localhost", port: 6379 },
});

// Get completed job metrics
const metrics = await queue.getMetrics("completed");
// {
//   data: [15, 22, 18, 30, 25, ...],  // Jobs per minute
//   count: 1250,                        // Total in range
//   meta: {
//     count: 45000,                     // Total since start
//     prevTS: 1707350400000,
//     prevCount: 22
//   }
// }

// Get failed job metrics
const failedMetrics = await queue.getMetrics("failed");

// Query specific range
const recent = await queue.getMetrics("completed", 0, 59); // Last 60 minutes
```

> **Benefit**: `prom-client` registers metrics globally — all queue instances contribute to the same counters.

</tab>
</tabs>

## 29.4. Understanding Metrics Data

The `data` array contains per-minute job counts, ordered newest-first. Combined with the `meta` object, you can calculate throughput, failure rates, and trends.

<tabs>
<tab title="Elixir">

```elixir
defmodule Arena.MetricsAnalyzer do
  @moduledoc "Analyzes EchoMQ metrics for the Arena performance dashboard."

  def analyze_queue(queue, conn) do
    {:ok, completed} = EchoMQ.Queue.get_metrics(queue, :completed,
      connection: conn, start: 0, end: 59)
    {:ok, failed} = EchoMQ.Queue.get_metrics(queue, :failed,
      connection: conn, start: 0, end: 59)

    completed_data = completed.data
    failed_data = failed.data

    total_completed = Enum.sum(completed_data)
    total_failed = Enum.sum(failed_data)
    total_processed = total_completed + total_failed

    %{
      # Throughput: average jobs per second over last hour
      avg_throughput: Float.round(total_completed / max(length(completed_data), 1) / 60, 2),

      # Peak minute: highest per-minute throughput
      peak_per_minute: Enum.max(completed_data, fn -> 0 end),

      # Failure rate as percentage
      failure_rate: if(total_processed > 0,
        do: Float.round(total_failed / total_processed * 100, 2),
        else: 0.0),

      # Trend: is throughput increasing or decreasing?
      # Compare first half vs second half of the window
      trend: compute_trend(completed_data),

      # Total counts
      completed_last_hour: total_completed,
      failed_last_hour: total_failed,
      all_time_completed: completed.meta.count,
      all_time_failed: failed.meta.count
    }
  end

  defp compute_trend(data) when length(data) < 4, do: :stable

  defp compute_trend(data) do
    mid = div(length(data), 2)
    {recent, older} = Enum.split(data, mid)
    recent_avg = Enum.sum(recent) / length(recent)
    older_avg = Enum.sum(older) / length(older)

    cond do
      recent_avg > older_avg * 1.1 -> :increasing
      recent_avg < older_avg * 0.9 -> :decreasing
      true -> :stable
    end
  end
end

# Usage in a Phoenix LiveView dashboard:
analysis = Arena.MetricsAnalyzer.analyze_queue("combat-actions", :arena_redis)
# %{avg_throughput: 12.5, peak_per_minute: 850, failure_rate: 0.3, trend: :stable, ...}
```

> **Benefit**: Phoenix LiveView delivers real-time dashboards over WebSocket with zero client-side JavaScript.

</tab>
<tab title="Go">

```go
type QueueAnalysis struct {
    AvgThroughput     float64 `json:"avg_throughput"`
    PeakPerMinute     int64   `json:"peak_per_minute"`
    FailureRate       float64 `json:"failure_rate"`
    Trend             string  `json:"trend"`
    CompletedLastHour int64   `json:"completed_last_hour"`
    FailedLastHour    int64   `json:"failed_last_hour"`
}

func analyzeQueue(ctx context.Context, rdb *redis.Client, queue string) (*QueueAnalysis, error) {
    completed, err := getQueueMetrics(ctx, rdb, queue, "completed")
    if err != nil {
        return nil, err
    }
    failed, err := getQueueMetrics(ctx, rdb, queue, "failed")
    if err != nil {
        return nil, err
    }

    cData := completed["data"].([]int64)
    fData := failed["data"].([]int64)

    var totalCompleted, totalFailed, peak int64
    for _, v := range cData {
        totalCompleted += v
        if v > peak {
            peak = v
        }
    }
    for _, v := range fData {
        totalFailed += v
    }

    total := totalCompleted + totalFailed
    var failureRate float64
    if total > 0 {
        failureRate = float64(totalFailed) / float64(total) * 100
    }

    minutes := int64(len(cData))
    if minutes == 0 {
        minutes = 1
    }
    avgThroughput := float64(totalCompleted) / float64(minutes) / 60.0

    return &QueueAnalysis{
        AvgThroughput:     avgThroughput,
        PeakPerMinute:     peak,
        FailureRate:       failureRate,
        Trend:             computeTrend(cData),
        CompletedLastHour: totalCompleted,
        FailedLastHour:    totalFailed,
    }, nil
}

func computeTrend(data []int64) string {
    if len(data) < 4 {
        return "stable"
    }
    mid := len(data) / 2
    var recentSum, olderSum int64
    for _, v := range data[:mid] {
        recentSum += v
    }
    for _, v := range data[mid:] {
        olderSum += v
    }
    recentAvg := float64(recentSum) / float64(mid)
    olderAvg := float64(olderSum) / float64(len(data)-mid)

    switch {
    case recentAvg > olderAvg*1.1:
        return "increasing"
    case recentAvg < olderAvg*0.9:
        return "decreasing"
    default:
        return "stable"
    }
}
```

> **Benefit**: `prometheus/client_golang` is the canonical Prometheus client — direct histogram/counter support.

</tab>
<tab title="Node.js">

```typescript
interface QueueAnalysis {
  avgThroughput: number;
  peakPerMinute: number;
  failureRate: number;
  trend: "increasing" | "decreasing" | "stable";
  completedLastHour: number;
  failedLastHour: number;
  allTimeCompleted: number;
  allTimeFailed: number;
}

async function analyzeQueue(queue: Queue): Promise<QueueAnalysis> {
  const completed = await queue.getMetrics("completed", 0, 59);
  const failed = await queue.getMetrics("failed", 0, 59);

  const totalCompleted = completed.data.reduce((a, b) => a + b, 0);
  const totalFailed = failed.data.reduce((a, b) => a + b, 0);
  const totalProcessed = totalCompleted + totalFailed;

  const peakPerMinute = Math.max(...completed.data, 0);
  const minutes = Math.max(completed.data.length, 1);

  return {
    avgThroughput: parseFloat((totalCompleted / minutes / 60).toFixed(2)),
    peakPerMinute,
    failureRate: totalProcessed > 0
      ? parseFloat(((totalFailed / totalProcessed) * 100).toFixed(2))
      : 0,
    trend: computeTrend(completed.data),
    completedLastHour: totalCompleted,
    failedLastHour: totalFailed,
    allTimeCompleted: completed.meta.count,
    allTimeFailed: failed.meta.count,
  };
}

function computeTrend(data: number[]): "increasing" | "decreasing" | "stable" {
  if (data.length < 4) return "stable";
  const mid = Math.floor(data.length / 2);
  const recentAvg = data.slice(0, mid).reduce((a, b) => a + b, 0) / mid;
  const olderAvg = data.slice(mid).reduce((a, b) => a + b, 0) / (data.length - mid);

  if (recentAvg > olderAvg * 1.1) return "increasing";
  if (recentAvg < olderAvg * 0.9) return "decreasing";
  return "stable";
}

// Usage:
// const analysis = await analyzeQueue(combatQueue);
// console.log(`Throughput: ${analysis.avgThroughput} jobs/sec, failure rate: ${analysis.failureRate}%`);
```

> **Benefit**: `prom-client` registers metrics globally — all queue instances contribute to the same counters.

</tab>
</tabs>

## 29.5. Prometheus Integration

Prometheus scrapes metrics from HTTP endpoints at regular intervals. The bridge between EchoMQ and Prometheus has two paths: **telemetry-to-Prometheus** (real-time events converted to counters/histograms) and **direct Prometheus export** (queue state snapshots as gauge metrics).

### Telemetry-to-Prometheus Bridge

The recommended approach uses EchoMQ's telemetry events (`:telemetry` in Elixir, EventEmitter in Node.js) to drive Prometheus counters and histograms. This gives you sub-second granularity compared to the 1-minute built-in metrics.

<tabs>
<tab title="Elixir">

```elixir
defmodule Arena.PrometheusMetrics do
  @moduledoc "Bridges EchoMQ telemetry events to Prometheus metrics."

  import Telemetry.Metrics

  def metrics do
    [
      # Job duration histogram (P50/P95/P99 latency)
      distribution(
        "echomq.job.duration",
        event_name: [:echomq, :job, :complete],
        measurement: :duration,
        unit: {:native, :millisecond},
        tags: [:queue, :job_name],
        reporter_options: [
          buckets: [5, 10, 25, 50, 100, 250, 500, 1000, 2500, 5000]
        ]
      ),

      # Completed job counter
      counter(
        "echomq.job.completed.total",
        event_name: [:echomq, :job, :complete],
        tags: [:queue, :job_name]
      ),

      # Failed job counter
      counter(
        "echomq.job.failed.total",
        event_name: [:echomq, :job, :fail],
        tags: [:queue, :job_name]
      ),

      # Retry counter
      counter(
        "echomq.job.retries.total",
        event_name: [:echomq, :job, :retry],
        tags: [:queue, :job_name]
      ),

      # Rate limit hit counter
      counter(
        "echomq.rate_limit.hits.total",
        event_name: [:echomq, :rate_limit, :hit],
        tags: [:queue]
      ),

      # Worker concurrency gauge
      last_value(
        "echomq.worker.concurrency",
        event_name: [:echomq, :worker, :start],
        measurement: :concurrency,
        tags: [:queue]
      ),

      # Stalled job recovery counter
      sum(
        "echomq.worker.stalled.recovered",
        event_name: [:echomq, :worker, :stalled_check],
        measurement: :recovered,
        tags: [:queue]
      )
    ]
  end
end

# In your application supervision tree (application.ex):
children = [
  # Start the Prometheus reporter
  {TelemetryMetricsPrometheus, [
    metrics: Arena.PrometheusMetrics.metrics(),
    port: 9568  # Dedicated metrics port (optional)
  ]}
]
```

> **Benefit**: `TelemetryMetricsPrometheus` auto-generates Prometheus endpoint from `:telemetry` event definitions.

</tab>
<tab title="Go">

```go
// Feature: Telemetry-to-Prometheus Bridge
//
// Not implemented in echomq-go. The Go package does not have a
// telemetry event system. Use the Prometheus Go client directly
// with custom instrumentation in your processor function.
//
// Workaround:
//   Use github.com/prometheus/client_golang to define and update
//   metrics manually in your job processor.

import (
    "github.com/prometheus/client_golang/prometheus"
    "github.com/prometheus/client_golang/prometheus/promhttp"
)

var (
    jobsCompletedTotal = prometheus.NewCounterVec(
        prometheus.CounterOpts{
            Name: "echomq_jobs_completed_total",
            Help: "Total completed jobs",
        },
        []string{"queue", "job_name"},
    )

    jobsFailedTotal = prometheus.NewCounterVec(
        prometheus.CounterOpts{
            Name: "echomq_jobs_failed_total",
            Help: "Total failed jobs",
        },
        []string{"queue", "job_name"},
    )

    jobDurationSeconds = prometheus.NewHistogramVec(
        prometheus.HistogramOpts{
            Name:    "echomq_job_duration_seconds",
            Help:    "Job processing duration in seconds",
            Buckets: []float64{0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5},
        },
        []string{"queue", "job_name"},
    )

    activeJobs = prometheus.NewGaugeVec(
        prometheus.GaugeOpts{
            Name: "echomq_active_jobs",
            Help: "Currently active jobs",
        },
        []string{"queue"},
    )
)

func init() {
    prometheus.MustRegister(jobsCompletedTotal, jobsFailedTotal, jobDurationSeconds, activeJobs)
}

// Instrumented processor for combat actions
func combatProcessor(ctx context.Context, job *echomq.Job) error {
    activeJobs.WithLabelValues("combat-actions").Inc()
    start := time.Now()
    defer func() {
        duration := time.Since(start).Seconds()
        jobDurationSeconds.WithLabelValues("combat-actions", job.Name).Observe(duration)
        activeJobs.WithLabelValues("combat-actions").Dec()
    }()

    err := processCombatAction(ctx, job)
    if err != nil {
        jobsFailedTotal.WithLabelValues("combat-actions", job.Name).Inc()
        return err
    }
    jobsCompletedTotal.WithLabelValues("combat-actions", job.Name).Inc()
    return nil
}

// Expose /metrics endpoint
func main() {
    http.Handle("/metrics", promhttp.Handler())
    go http.ListenAndServe(":9568", nil)

    // Start worker with instrumented processor...
}
```

> **Benefit**: `promhttp.Handler()` serves metrics on any port — no framework dependency needed.

</tab>
<tab title="Node.js">

```typescript
import { Worker } from "bullmq";
import { register, Counter, Histogram, Gauge } from "prom-client";
import express from "express";

// Define Prometheus metrics
const jobsCompletedTotal = new Counter({
  name: "echomq_jobs_completed_total",
  help: "Total completed jobs",
  labelNames: ["queue", "job_name"],
});

const jobsFailedTotal = new Counter({
  name: "echomq_jobs_failed_total",
  help: "Total failed jobs",
  labelNames: ["queue", "job_name"],
});

const jobDurationSeconds = new Histogram({
  name: "echomq_job_duration_seconds",
  help: "Job processing duration in seconds",
  labelNames: ["queue", "job_name"],
  buckets: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5],
});

const activeJobs = new Gauge({
  name: "echomq_active_jobs",
  help: "Currently active jobs",
  labelNames: ["queue"],
});

// Attach metrics via worker events
const worker = new Worker("combat-actions", combatProcessor, {
  connection: { host: "localhost", port: 6379 },
  concurrency: 10,
});

worker.on("active", (job) => {
  activeJobs.labels("combat-actions").inc();
});

worker.on("completed", (job) => {
  jobsCompletedTotal.labels("combat-actions", job.name).inc();
  activeJobs.labels("combat-actions").dec();
  // Duration tracked via job.processedOn and job.finishedOn
  if (job.processedOn && job.finishedOn) {
    const durationSec = (job.finishedOn - job.processedOn) / 1000;
    jobDurationSeconds.labels("combat-actions", job.name).observe(durationSec);
  }
});

worker.on("failed", (job, err) => {
  jobsFailedTotal.labels("combat-actions", job?.name ?? "unknown").inc();
  activeJobs.labels("combat-actions").dec();
});

// Expose /metrics endpoint
const app = express();
app.get("/metrics", async (req, res) => {
  res.set("Content-Type", register.contentType);
  res.end(await register.metrics());
});
app.listen(9568);
```

> **Benefit**: `prom-client` `register.metrics()` returns Prometheus text format ready for scraping.

</tab>
</tabs>

### Phoenix Endpoint for Prometheus Scraping

Expose the metrics endpoint in your Phoenix router so Prometheus can scrape it.

<tabs>
<tab title="Elixir">

```elixir
# lib/arena_web/router.ex
scope "/metrics" do
  pipe_through :api

  get "/", ArenaWeb.MetricsController, :index
end

# lib/arena_web/controllers/metrics_controller.ex
defmodule ArenaWeb.MetricsController do
  use ArenaWeb, :controller

  def index(conn, _params) do
    # TelemetryMetricsPrometheus handles formatting
    metrics = TelemetryMetricsPrometheus.Core.scrape()

    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, metrics)
  end
end
```

> **Benefit**: `TelemetryMetricsPrometheus` auto-generates Prometheus endpoint from `:telemetry` event definitions.

</tab>
<tab title="Go">

```go
// The promhttp.Handler() registered in init serves this automatically.
// Configure your HTTP mux to expose /metrics:

mux := http.NewServeMux()
mux.Handle("/metrics", promhttp.Handler())
mux.HandleFunc("/health", healthHandler)

server := &http.Server{
    Addr:    ":9568",
    Handler: mux,
}
go server.ListenAndServe()
```

> **Benefit**: `promhttp.Handler()` serves metrics on any port — no framework dependency needed.

</tab>
<tab title="Node.js">

```typescript
// Using express (shown above) or any HTTP framework:
import Fastify from "fastify";
import { register } from "prom-client";

const app = Fastify();

app.get("/metrics", async (request, reply) => {
  reply.header("Content-Type", register.contentType);
  return register.metrics();
});

await app.listen({ port: 9568 });
```

> **Benefit**: `prom-client` `register.metrics()` returns Prometheus text format ready for scraping.

</tab>
</tabs>

### Prometheus Scrape Configuration

Configure Prometheus to scrape the metrics endpoint from your game servers.

```yaml
# prometheus.yml
scrape_configs:
  - job_name: "arena-echomq"
    static_configs:
      - targets:
          - "arena-web-1:9568"
          - "arena-web-2:9568"
          - "arena-worker-1:9568"
    metrics_path: "/metrics"
    scrape_interval: 15s
    labels:
      game: "fireheadz-arena"
      environment: "production"

  # If using TelemetryMetricsPrometheus on default port
  - job_name: "arena-telemetry"
    static_configs:
      - targets: ["arena-web-1:4000"]
    metrics_path: "/metrics"
    scrape_interval: 10s
```

## 29.6. Queue-Level Prometheus Export

EchoMQ can export queue state counts directly in Prometheus text format. This provides point-in-time gauge metrics for queue depth without requiring telemetry event handlers.

<tabs>
<tab title="Elixir">

```elixir
# Export queue state as Prometheus metrics
{:ok, metrics} = EchoMQ.Queue.export_prometheus_metrics("combat-actions",
  connection: :arena_redis
)

# Output:
# echomq_job_count{queue="combat-actions", state="waiting"} 42
# echomq_job_count{queue="combat-actions", state="active"} 8
# echomq_job_count{queue="combat-actions", state="completed"} 15230
# echomq_job_count{queue="combat-actions", state="failed"} 12
# echomq_job_count{queue="combat-actions", state="delayed"} 5
# echomq_job_count{queue="combat-actions", state="paused"} 0

# With global labels for multi-environment setups
{:ok, metrics} = EchoMQ.Queue.export_prometheus_metrics("combat-actions",
  connection: :arena_redis,
  global_variables: %{
    "env" => "production",
    "server" => "arena-worker-1",
    "region" => "us-east-1"
  }
)

# Output:
# echomq_job_count{queue="combat-actions", state="waiting", env="production", server="arena-worker-1", region="us-east-1"} 42

# Multi-queue export for the Arena dashboard
defmodule Arena.PrometheusExporter do
  @arena_queues ["combat-actions", "matchmaking", "inventory", "leaderboard", "chat"]

  def export_all_queues(conn) do
    metrics =
      @arena_queues
      |> Enum.map(fn queue ->
        case EchoMQ.Queue.export_prometheus_metrics(queue,
          connection: conn,
          global_variables: %{"game" => "fireheadz_arena"}) do
          {:ok, text} -> text
          {:error, _} -> ""
        end
      end)
      |> Enum.join("\n")

    metrics
  end
end
```

> **Benefit**: `TelemetryMetricsPrometheus` auto-generates Prometheus endpoint from `:telemetry` event definitions.

</tab>
<tab title="Go">

```go
// Feature: Queue-Level Prometheus Export
//
// Not implemented in echomq-go. The Queue does not have an
// ExportPrometheusMetrics method.
//
// Workaround:
//   Read queue counts from Redis and format as Prometheus text:

func exportQueuePrometheus(ctx context.Context, rdb *redis.Client, queue string, labels map[string]string) string {
    prefix := "bull"
    states := []string{"wait", "active", "completed", "failed", "delayed", "paused"}
    stateLabels := []string{"waiting", "active", "completed", "failed", "delayed", "paused"}

    var buf strings.Builder
    buf.WriteString("# HELP echomq_job_count Number of jobs in the queue by state\n")
    buf.WriteString("# TYPE echomq_job_count gauge\n")

    globalLabels := ""
    for k, v := range labels {
        globalLabels += fmt.Sprintf(", %s=\"%s\"", k, v)
    }

    for i, state := range states {
        key := fmt.Sprintf("%s:%s:%s", prefix, queue, state)
        var count int64

        switch state {
        case "wait", "paused":
            count, _ = rdb.LLen(ctx, key).Result()
        case "active", "completed", "failed", "delayed":
            count, _ = rdb.ZCard(ctx, key).Result()
        }

        buf.WriteString(fmt.Sprintf(
            "echomq_job_count{queue=\"%s\", state=\"%s\"%s} %d\n",
            queue, stateLabels[i], globalLabels, count,
        ))
    }

    return buf.String()
}

// Usage:
// metrics := exportQueuePrometheus(ctx, rdb, "combat-actions", map[string]string{
//     "env": "production",
//     "server": "arena-worker-1",
// })
```

> **Benefit**: `promhttp.Handler()` serves metrics on any port — no framework dependency needed.

</tab>
<tab title="Node.js">

```typescript
import { Queue } from "bullmq";

const queue = new Queue("combat-actions", {
  connection: { host: "localhost", port: 6379 },
});

// Export queue state as Prometheus text
const metrics = await queue.exportPrometheusMetrics();
// echomq_job_count{queue="combat-actions", state="waiting"} 42
// echomq_job_count{queue="combat-actions", state="active"} 8
// ...

// Multi-queue export
const ARENA_QUEUES = ["combat-actions", "matchmaking", "inventory", "leaderboard", "chat"];

async function exportAllQueues(): Promise<string> {
  const results = await Promise.all(
    ARENA_QUEUES.map(async (name) => {
      const q = new Queue(name, { connection: { host: "localhost", port: 6379 } });
      try {
        return await q.exportPrometheusMetrics();
      } finally {
        await q.close();
      }
    })
  );
  return results.join("\n");
}
```

> **Benefit**: `prom-client` `register.metrics()` returns Prometheus text format ready for scraping.

</tab>
</tabs>

## 29.7. Grafana Dashboard Queries

These PromQL queries power a game server operations dashboard. Each query is designed for a specific Grafana panel type.

### Throughput Panel (Graph)

```promql
# Jobs completed per second by queue (time series)
rate(echomq_jobs_completed_total[5m])

# Total throughput across all combat queues
sum(rate(echomq_jobs_completed_total{queue=~"combat.*"}[5m]))

# Throughput by job type (e.g., melee vs ranged attacks)
sum by (job_name) (rate(echomq_jobs_completed_total{queue="combat-actions"}[5m]))
```

### Failure Rate Panel (Graph)

```promql
# Failure rate as percentage
rate(echomq_jobs_failed_total[5m]) / (rate(echomq_jobs_completed_total[5m]) + rate(echomq_jobs_failed_total[5m])) * 100

# Failure rate by queue
sum by (queue) (rate(echomq_jobs_failed_total[5m]))
/ sum by (queue) (rate(echomq_jobs_completed_total[5m]) + rate(echomq_jobs_failed_total[5m])) * 100
```

### Latency Panel (Heatmap or Graph)

```promql
# P50 job processing duration
histogram_quantile(0.50, rate(echomq_job_duration_seconds_bucket[5m]))

# P95 job processing duration (critical for matchmaking SLA)
histogram_quantile(0.95, rate(echomq_job_duration_seconds_bucket[5m]))

# P99 job processing duration
histogram_quantile(0.99, rate(echomq_job_duration_seconds_bucket[5m]))

# Average duration by queue
rate(echomq_job_duration_seconds_sum[5m]) / rate(echomq_job_duration_seconds_count[5m])
```

### Queue Depth Panel (Gauge or Graph)

```promql
# Current waiting jobs (queue depth)
echomq_job_count{state="waiting"}

# Active jobs (being processed right now)
echomq_job_count{state="active"}

# Delayed jobs (scheduled for future processing)
echomq_job_count{state="delayed"}

# Queue saturation (active / concurrency)
echomq_active_jobs / echomq_worker_concurrency
```

### Rate Limiting Panel (Counter)

```promql
# Rate limit hits per second
rate(echomq_rate_limit_hits_total[5m])

# Rate limit hits by queue
sum by (queue) (increase(echomq_rate_limit_hits_total[1h]))
```

## 29.8. Alerting Patterns

Prometheus alerting rules catch problems before they affect players. These rules trigger PagerDuty, Slack, or other notification channels through Alertmanager.

### Prometheus Alerting Rules

```yaml
# prometheus/rules/echomq.yml
groups:
  - name: echomq_alerts
    interval: 30s
    rules:
      # Critical: Queue depth growing faster than processing
      - alert: EchoMQQueueBacklog
        expr: echomq_job_count{state="waiting"} > 1000
        for: 5m
        labels:
          severity: warning
          game: fireheadz-arena
        annotations:
          summary: "Queue {{ $labels.queue }} has {{ $value }} waiting jobs"
          description: "Queue backlog exceeds 1000 for 5 minutes. Check worker health."

      # Critical: High failure rate on combat queue
      - alert: EchoMQHighFailureRate
        expr: >
          rate(echomq_jobs_failed_total{queue="combat-actions"}[5m])
          / (rate(echomq_jobs_completed_total{queue="combat-actions"}[5m]) + rate(echomq_jobs_failed_total{queue="combat-actions"}[5m]))
          > 0.05
        for: 3m
        labels:
          severity: critical
          game: fireheadz-arena
        annotations:
          summary: "Combat queue failure rate is {{ $value | humanizePercentage }}"
          description: "More than 5% of combat actions are failing. Players may be losing inputs."

      # Warning: Matchmaking P95 latency too high
      - alert: EchoMQMatchmakingLatency
        expr: >
          histogram_quantile(0.95, rate(echomq_job_duration_seconds_bucket{queue="matchmaking"}[5m]))
          > 5
        for: 2m
        labels:
          severity: warning
          game: fireheadz-arena
        annotations:
          summary: "Matchmaking P95 latency is {{ $value }}s"
          description: "Players are waiting too long for matches. Consider scaling workers."

      # Critical: No jobs being processed (workers down?)
      - alert: EchoMQWorkersDown
        expr: >
          rate(echomq_jobs_completed_total[5m]) == 0
          and echomq_job_count{state="waiting"} > 0
        for: 2m
        labels:
          severity: critical
          game: fireheadz-arena
        annotations:
          summary: "No jobs being processed on {{ $labels.queue }}"
          description: "Queue has waiting jobs but no completions. Workers may be crashed."
```

### Application-Level Alerting

<tabs>
<tab title="Elixir">

```elixir
defmodule Arena.Alerts do
  @moduledoc "Real-time alerting based on EchoMQ telemetry events."

  require Logger

  @critical_queues ["combat-actions", "matchmaking", "inventory"]

  def setup do
    :telemetry.attach_many(
      "arena-alerts",
      [
        [:echomq, :job, :fail],
        [:echomq, :rate_limit, :hit],
        [:echomq, :worker, :stalled_check]
      ],
      &handle_event/4,
      nil
    )
  end

  def handle_event([:echomq, :job, :fail], _measurements, %{queue: queue, error: error}, _) do
    if queue in @critical_queues do
      Logger.error("[ALERT] Critical queue failure: #{queue} — #{inspect(error)}")
      Arena.Notifications.send_slack(
        channel: "#arena-alerts",
        text: "Combat queue `#{queue}` job failed: #{inspect(error)}"
      )
    end
  end

  def handle_event([:echomq, :rate_limit, :hit], %{delay: delay}, %{queue: queue}, _) do
    if delay > 5_000 do
      Logger.warning("[ALERT] Extended rate limit on #{queue}: #{delay}ms delay")
    end
  end

  def handle_event([:echomq, :worker, :stalled_check], %{recovered: recovered, failed: failed}, %{queue: queue}, _) do
    if failed > 0 do
      Logger.error("[ALERT] #{failed} stalled jobs failed in #{queue}")
      Arena.Notifications.send_pagerduty(
        summary: "#{failed} stalled jobs failed in #{queue}",
        severity: :critical
      )
    end

    if recovered > 0 do
      Logger.info("[INFO] #{recovered} stalled jobs recovered in #{queue}")
    end
  end
end
```

> **Benefit**: `:telemetry.attach` adds zero-cost instrumentation — events are no-ops when unhandled.

</tab>
<tab title="Go">

```go
type AlertHandler struct {
    criticalQueues map[string]bool
    slackWebhook   string
}

func NewAlertHandler(slackWebhook string) *AlertHandler {
    return &AlertHandler{
        criticalQueues: map[string]bool{
            "combat-actions": true,
            "matchmaking":    true,
            "inventory":      true,
        },
        slackWebhook: slackWebhook,
    }
}

// Call this from your instrumented processor on failure
func (a *AlertHandler) OnJobFailed(queue, jobName string, err error) {
    if !a.criticalQueues[queue] {
        return
    }
    log.Printf("[ALERT] Critical queue failure: %s — %v", queue, err)

    // Send Slack notification
    payload := fmt.Sprintf(`{"text":"Combat queue %s job %s failed: %v"}`, queue, jobName, err)
    http.Post(a.slackWebhook, "application/json", strings.NewReader(payload))
}

// Periodic health check — call from a goroutine
func (a *AlertHandler) CheckQueueHealth(ctx context.Context, rdb *redis.Client, queues []string) {
    for _, queue := range queues {
        waitKey := fmt.Sprintf("bull:%s:wait", queue)
        waiting, _ := rdb.LLen(ctx, waitKey).Result()

        if waiting > 1000 {
            log.Printf("[ALERT] Queue %s has %d waiting jobs", queue, waiting)
        }
    }
}
```

> **Benefit**: `crypto/hmac.Equal` provides constant-time comparison — Go's stdlib covers this natively.

</tab>
<tab title="Node.js">

```typescript
import { Worker, QueueEvents } from "bullmq";

const CRITICAL_QUEUES = new Set(["combat-actions", "matchmaking", "inventory"]);

// Alert on failures in critical queues
function setupAlerts(worker: Worker, queueName: string) {
  worker.on("failed", (job, err) => {
    if (CRITICAL_QUEUES.has(queueName)) {
      console.error(`[ALERT] Critical queue failure: ${queueName} — ${err.message}`);
      sendSlackAlert(`Combat queue \`${queueName}\` job \`${job?.name}\` failed: ${err.message}`);
    }
  });

  worker.on("stalled", (jobId) => {
    console.error(`[ALERT] Stalled job in ${queueName}: ${jobId}`);
    sendPagerDutyAlert({
      summary: `Stalled job in ${queueName}: ${jobId}`,
      severity: "critical",
    });
  });
}

async function sendSlackAlert(text: string) {
  await fetch(process.env.SLACK_WEBHOOK_URL!, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ text }),
  });
}

async function sendPagerDutyAlert(alert: { summary: string; severity: string }) {
  // PagerDuty Events API v2
  await fetch("https://events.pagerduty.com/v2/enqueue", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      routing_key: process.env.PAGERDUTY_ROUTING_KEY,
      event_action: "trigger",
      payload: {
        summary: alert.summary,
        severity: alert.severity,
        source: "arena-echomq",
      },
    }),
  });
}
```

> **Benefit**: `crypto.timingSafeEqual` is built into Node.js — no third-party dependency for safe comparison.

</tab>
</tabs>

## 29.9. Arena Performance Dashboard

A complete example: a multi-queue Arena dashboard that combines built-in metrics, telemetry-driven Prometheus metrics, and direct queue state export into a single monitoring surface.

<tabs>
<tab title="Elixir">

```elixir
defmodule Arena.PerformanceDashboard do
  @moduledoc """
  Combines all metrics sources for the Arena game ops dashboard.
  Exposes a /metrics endpoint with Prometheus text format and
  a /api/dashboard endpoint with JSON for the LiveView frontend.
  """

  @arena_queues [
    {"combat-actions", :critical},
    {"matchmaking", :critical},
    {"inventory", :standard},
    {"leaderboard", :standard},
    {"chat", :low},
    {"analytics", :low}
  ]

  def setup do
    # Start Prometheus reporter for telemetry events
    {:ok, _} = TelemetryMetricsPrometheus.start_link(
      metrics: Arena.PrometheusMetrics.metrics(),
      port: 9568
    )

    # Start alerting handlers
    Arena.Alerts.setup()

    :ok
  end

  @doc "Returns a snapshot of all Arena queue health for the LiveView dashboard."
  def snapshot(conn) do
    queues =
      @arena_queues
      |> Enum.map(fn {queue, priority} ->
        analysis = Arena.MetricsAnalyzer.analyze_queue(queue, conn)
        counts = get_queue_counts(queue, conn)

        %{
          name: queue,
          priority: priority,
          throughput: analysis.avg_throughput,
          peak_per_minute: analysis.peak_per_minute,
          failure_rate: analysis.failure_rate,
          trend: analysis.trend,
          waiting: counts.waiting,
          active: counts.active,
          delayed: counts.delayed,
          completed_1h: analysis.completed_last_hour,
          failed_1h: analysis.failed_last_hour
        }
      end)

    %{
      queues: queues,
      timestamp: DateTime.utc_now(),
      total_throughput: Enum.reduce(queues, 0, & &1.throughput + &2),
      critical_alerts: Enum.count(queues, fn q ->
        q.priority == :critical and q.failure_rate > 5.0
      end)
    }
  end

  defp get_queue_counts(queue, conn) do
    {:ok, counts} = EchoMQ.Queue.get_counts(queue, connection: conn)
    counts
  end
end
```

> **Benefit**: `TelemetryMetricsPrometheus` auto-generates Prometheus endpoint from `:telemetry` event definitions.

</tab>
<tab title="Go">

```go
type PerformanceDashboard struct {
    rdb    *redis.Client
    queues []QueueConfig
}

type QueueConfig struct {
    Name     string
    Priority string // "critical", "standard", "low"
}

type DashboardSnapshot struct {
    Queues          []QueueSnapshot `json:"queues"`
    Timestamp       time.Time       `json:"timestamp"`
    TotalThroughput float64         `json:"total_throughput"`
    CriticalAlerts  int             `json:"critical_alerts"`
}

type QueueSnapshot struct {
    Name           string  `json:"name"`
    Priority       string  `json:"priority"`
    Throughput     float64 `json:"throughput"`
    FailureRate    float64 `json:"failure_rate"`
    Trend          string  `json:"trend"`
    Waiting        int64   `json:"waiting"`
    Active         int64   `json:"active"`
    Delayed        int64   `json:"delayed"`
    Completed1h    int64   `json:"completed_1h"`
    Failed1h       int64   `json:"failed_1h"`
}

func NewDashboard(rdb *redis.Client) *PerformanceDashboard {
    return &PerformanceDashboard{
        rdb: rdb,
        queues: []QueueConfig{
            {"combat-actions", "critical"},
            {"matchmaking", "critical"},
            {"inventory", "standard"},
            {"leaderboard", "standard"},
            {"chat", "low"},
            {"analytics", "low"},
        },
    }
}

func (d *PerformanceDashboard) Snapshot(ctx context.Context) (*DashboardSnapshot, error) {
    snap := &DashboardSnapshot{Timestamp: time.Now()}

    for _, qc := range d.queues {
        analysis, err := analyzeQueue(ctx, d.rdb, qc.Name)
        if err != nil {
            log.Printf("Failed to analyze %s: %v", qc.Name, err)
            continue
        }

        waiting, _ := d.rdb.LLen(ctx, fmt.Sprintf("bull:%s:wait", qc.Name)).Result()
        active, _ := d.rdb.ZCard(ctx, fmt.Sprintf("bull:%s:active", qc.Name)).Result()
        delayed, _ := d.rdb.ZCard(ctx, fmt.Sprintf("bull:%s:delayed", qc.Name)).Result()

        qs := QueueSnapshot{
            Name:        qc.Name,
            Priority:    qc.Priority,
            Throughput:  analysis.AvgThroughput,
            FailureRate: analysis.FailureRate,
            Trend:       analysis.Trend,
            Waiting:     waiting,
            Active:      active,
            Delayed:     delayed,
            Completed1h: analysis.CompletedLastHour,
            Failed1h:    analysis.FailedLastHour,
        }
        snap.Queues = append(snap.Queues, qs)
        snap.TotalThroughput += qs.Throughput

        if qc.Priority == "critical" && qs.FailureRate > 5.0 {
            snap.CriticalAlerts++
        }
    }

    return snap, nil
}

// Expose as HTTP handler
func (d *PerformanceDashboard) ServeHTTP(w http.ResponseWriter, r *http.Request) {
    snap, err := d.Snapshot(r.Context())
    if err != nil {
        http.Error(w, err.Error(), 500)
        return
    }
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(snap)
}
```

> **Tradeoff**: No built-in admin UI — JSON endpoints require a separate frontend or Grafana for visualization.

</tab>
<tab title="Node.js">

```typescript
import { Queue } from "bullmq";

interface QueueConfig {
  name: string;
  priority: "critical" | "standard" | "low";
}

interface DashboardSnapshot {
  queues: QueueSnapshot[];
  timestamp: string;
  totalThroughput: number;
  criticalAlerts: number;
}

interface QueueSnapshot {
  name: string;
  priority: string;
  throughput: number;
  failureRate: number;
  trend: string;
  waiting: number;
  active: number;
  delayed: number;
  completed1h: number;
  failed1h: number;
}

const ARENA_QUEUES: QueueConfig[] = [
  { name: "combat-actions", priority: "critical" },
  { name: "matchmaking", priority: "critical" },
  { name: "inventory", priority: "standard" },
  { name: "leaderboard", priority: "standard" },
  { name: "chat", priority: "low" },
  { name: "analytics", priority: "low" },
];

async function getSnapshot(connection: { host: string; port: number }): Promise<DashboardSnapshot> {
  const queues: QueueSnapshot[] = [];

  for (const qc of ARENA_QUEUES) {
    const queue = new Queue(qc.name, { connection });
    try {
      const analysis = await analyzeQueue(queue);
      const counts = await queue.getJobCounts("waiting", "active", "delayed");

      queues.push({
        name: qc.name,
        priority: qc.priority,
        throughput: analysis.avgThroughput,
        failureRate: analysis.failureRate,
        trend: analysis.trend,
        waiting: counts.waiting,
        active: counts.active,
        delayed: counts.delayed,
        completed1h: analysis.completedLastHour,
        failed1h: analysis.failedLastHour,
      });
    } finally {
      await queue.close();
    }
  }

  const totalThroughput = queues.reduce((sum, q) => sum + q.throughput, 0);
  const criticalAlerts = queues.filter(
    (q) => q.priority === "critical" && q.failureRate > 5.0
  ).length;

  return {
    queues,
    timestamp: new Date().toISOString(),
    totalThroughput,
    criticalAlerts,
  };
}

// Express endpoint
app.get("/api/dashboard", async (req, res) => {
  const snapshot = await getSnapshot({ host: "localhost", port: 6379 });
  res.json(snapshot);
});
```

> **Benefit**: Bull Board provides a production-ready admin UI with job inspection, retry, and delete.

</tab>
</tabs>

## 29.10. Metrics Storage Details

Understanding the Redis data structures behind metrics helps with debugging and capacity planning.

| Redis Key | Type | Purpose | Size Estimate |
|-----------|------|---------|--------------|
| `bull:{queue}:metrics:completed` | Hash | Total count + timestamp metadata | ~64 bytes |
| `bull:{queue}:metrics:completed:data` | List | Per-minute completed counts | ~8 bytes/entry |
| `bull:{queue}:metrics:failed` | Hash | Total failed count + metadata | ~64 bytes |
| `bull:{queue}:metrics:failed:data` | List | Per-minute failed counts | ~8 bytes/entry |

For a queue with `max_data_points: 20_160` (2 weeks):

- Completed data: 20,160 entries x ~8 bytes = ~157 KB
- Failed data: 20,160 entries x ~8 bytes = ~157 KB
- Total per queue: ~315 KB
- 6 Arena queues: ~1.9 MB

For high-throughput queues processing 10,000+ jobs/second, consider shorter retention (1-3 days) and relying on Prometheus for long-term storage.

## 29.11. Comparison: Metrics Features by Runtime

| Feature | Elixir | Go | Node.js |
|---------|--------|-----|---------|
| Built-in Redis metrics | Full (`get_metrics/3`) | Not wired (GAP-006) | Full (`getMetrics`) |
| Prometheus export | `export_prometheus_metrics/2` | Manual (see workaround) | `exportPrometheusMetrics()` |
| Telemetry events | `:telemetry` (10+ event types) | Manual Prometheus client | Worker EventEmitter |
| Prometheus bridge | `TelemetryMetricsPrometheus` | `prometheus/client_golang` | `prom-client` |
| Grafana integration | Via Prometheus scrape | Via Prometheus scrape | Via Prometheus scrape |
| Alerting | Telemetry handlers + Prometheus rules | Prometheus rules | Worker events + Prometheus rules |
| Max data points config | `metrics: %{max_data_points: N}` | Not available | `metrics: {maxDataPoints: N}` |

---

*Previous: [Groups](ch28-groups.md) | Next: [Telemetry & Tracing](ch30-telemetry-tracing.md)*
