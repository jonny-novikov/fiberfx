# Chapter 31. Production Guide

Running EchoMQ in production means configuring Redis for durability, supervising workers for fault tolerance, monitoring queue health, and scaling capacity to match Fireheadz Arena's real-time game load. This chapter consolidates deployment, benchmarking, error recovery, and operational best practices into a single production-readiness guide. Each section addresses all three runtimes so you can deploy a polyglot worker fleet across regions with confidence.

## 31.1. Deployment

### Release Builds

Build optimized artifacts for each runtime before deploying to Fly.io or any container platform.

<tabs>
<tab title="Elixir">

```elixir
# mix.exs — configure release
def project do
  [
    app: :arena,
    version: "1.0.0",
    elixir: "~> 1.18",
    start_permanent: Mix.env() == :prod,
    releases: [
      arena: [
        include_executables_for: [:unix],
        applications: [runtime_tools: :permanent]
      ]
    ]
  ]
end

# Build release
# MIX_ENV=prod mix release arena
# _build/prod/rel/arena/bin/arena start
```

The BEAM release bundles the Erlang runtime, all compiled `.beam` files, and a boot script. The `runtime_tools` application enables production debugging via `:observer` and `:dbg` without recompilation.

> **Benefit**: Pattern matching and keyword options provide self-documenting APIs with compile-time safety.

</tab>
<tab title="Go">

```go
// Build a statically linked binary for Linux containers
// CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o arena-worker ./cmd/worker

// cmd/worker/main.go
package main

import (
    "context"
    "log"
    "os"
    "os/signal"
    "syscall"

    "github.com/fiberfx/echomq-go/pkg/echomq"
    "github.com/redis/go-redis/v9"
)

func main() {
    rdb := redis.NewClient(&redis.Options{
        Addr:     os.Getenv("REDIS_URL"),
        Password: os.Getenv("REDIS_PASSWORD"),
    })

    ctx, cancel := signal.NotifyContext(context.Background(),
        os.Interrupt, syscall.SIGTERM)
    defer cancel()

    w := echomq.NewWorker("combat-actions", rdb, echomq.WorkerOptions{
        Concurrency:     60,
        ShutdownTimeout: 25 * time.Second,
    })
    w.Process(combatProcessor)

    if err := w.Start(ctx); err != nil {
        log.Fatalf("Worker exited: %v", err)
    }
}
```

The `-ldflags="-s -w"` flags strip debug symbols and DWARF info, reducing binary size by ~30%. `CGO_ENABLED=0` produces a fully static binary that runs in `scratch` or `distroless` Docker images.

> **Benefit**: Goroutine-per-job with semaphore-based limiting achieves OS-level parallelism.

</tab>
<tab title="Node.js">

```typescript
// package.json — production scripts
{
  "scripts": {
    "build": "tsc --project tsconfig.build.json",
    "start:worker": "node --max-old-space-size=512 dist/worker.js",
    "start:cluster": "node dist/cluster.js"
  },
  "engines": {
    "node": ">=20.0.0"
  }
}

// tsconfig.build.json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "Node16",
    "outDir": "dist",
    "sourceMap": false,
    "declaration": false,
    "removeComments": true,
    "strict": true
  },
  "include": ["src/**/*.ts"],
  "exclude": ["src/**/*.test.ts"]
}

// Build: npm run build
// Start: NODE_ENV=production npm run start:worker
```

Set `--max-old-space-size` to cap V8 heap memory. In production, disable source maps to reduce startup time and memory. Pin the Node.js version in `engines` to prevent accidental deployment on incompatible runtimes.

> **Benefit**: `ioredis` Cluster mode auto-discovers nodes and redirects commands transparently.

</tab>
</tabs>

### Docker Images

<tabs>
<tab title="Elixir">

```dockerfile
# Dockerfile — multi-stage Elixir release
FROM elixir:1.18-otp-27-alpine AS build
WORKDIR /app
ENV MIX_ENV=prod

COPY mix.exs mix.lock ./
RUN mix deps.get --only prod && mix deps.compile

COPY config config
COPY lib lib
RUN mix release arena

# Runtime image — minimal Alpine
FROM alpine:3.20
RUN apk add --no-cache libstdc++ ncurses-libs
WORKDIR /app
COPY --from=build /app/_build/prod/rel/arena ./
ENV RELEASE_DISTRIBUTION=none

EXPOSE 4000
HEALTHCHECK --interval=30s --timeout=5s \
  CMD wget -q --spider http://localhost:4000/health/live || exit 1

CMD ["bin/arena", "start"]
```

> **Benefit**: LockManager batches all lock renewals into a single GenServer tick — O(1) timer overhead.

</tab>
<tab title="Go">

```dockerfile
# Dockerfile — multi-stage Go build
FROM golang:1.23-alpine AS build
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o arena-worker ./cmd/worker

# Runtime image — distroless for minimal attack surface
FROM gcr.io/distroless/static-debian12
COPY --from=build /app/arena-worker /arena-worker

EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=5s \
  CMD ["/arena-worker", "--health-check"]

ENTRYPOINT ["/arena-worker"]
```

> **Tradeoff**: Workers must be started as explicit goroutines with manual signal handling for graceful shutdown.

</tab>
<tab title="Node.js">

```dockerfile
# Dockerfile — multi-stage Node.js build
FROM node:20-alpine AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --production=false
COPY tsconfig.build.json ./
COPY src src
RUN npm run build && npm prune --production

# Runtime image
FROM node:20-alpine
WORKDIR /app
COPY --from=build /app/dist ./dist
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/package.json ./

ENV NODE_ENV=production
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=5s \
  CMD wget -q --spider http://localhost:8080/health || exit 1

CMD ["node", "--max-old-space-size=512", "dist/worker.js"]
```

> **Benefit**: Built-in lock extension runs automatically within the Worker class — transparent to processors.

</tab>
</tabs>

### Fly.io Deployment

Fireheadz Arena runs across three Fly.io regions for low-latency combat processing. Each region deploys EchoMQ workers close to game servers and connects to a regional Redis instance.

```
+-----------------------+     +-----------------------+     +-----------------------+
|   Region: iad (US-E)  |     |   Region: lax (US-W)  |     |   Region: ams (EU)    |
|                       |     |                       |     |                       |
|  Elixir BEAM          |     |  Go binary            |     |  Node.js cluster      |
|  combat:  2w x 60c    |     |  combat:  4w x 60c    |     |  combat:  8p x 60c    |
|  match:   1w x 20c    |     |  match:   1w x 20c    |     |  match:   1w x 20c    |
|  leader:  1w x 1c     |     |  leader:  1w x 1c     |     |  leader:  1w x 1c     |
|                       |     |                       |     |                       |
|  Redis (regional)     |     |  Redis (regional)     |     |  Redis (regional)     |
+-----------------------+     +-----------------------+     +-----------------------+
```

```toml
# fly.toml — Elixir worker deployment
app = "arena-workers-iad"
primary_region = "iad"

[build]
  dockerfile = "Dockerfile"

[env]
  REDIS_URL = "redis://arena-redis-iad.internal:6379"
  COMBAT_CONCURRENCY = "60"
  COMBAT_WORKERS = "2"
  MATCH_CONCURRENCY = "20"
  PHX_HOST = "arena-workers-iad.fly.dev"

[[services]]
  internal_port = 4000
  protocol = "tcp"
  [[services.ports]]
    port = 443
    handlers = ["tls", "http"]
  [[services.http_checks]]
    interval = 15000
    timeout = 5000
    path = "/health/ready"

[processes]
  worker = "bin/arena start"

[[vm]]
  size = "performance-2x"
  memory = "4096"
  processes = ["worker"]
```

## 31.2. Redis Configuration

Redis is the backbone of EchoMQ's distributed state. Misconfigured Redis is the most common cause of production incidents.

### Persistence

Enable both RDB snapshots and AOF (Append Only File) for durability:

```
# redis.conf — production settings

# RDB: periodic snapshots (crash recovery baseline)
save 900 1      # Snapshot after 900s if 1+ keys changed
save 300 10     # Snapshot after 300s if 10+ keys changed
save 60 10000   # Snapshot after 60s if 10000+ keys changed

# AOF: append-only log (point-in-time recovery)
appendonly yes
appendfsync everysec   # Flush AOF buffer every second (1s max data loss)

# CRITICAL: Prevent key eviction (EchoMQ requires ALL keys to persist)
maxmemory-policy noeviction

# Memory limit — set based on your queue depth and job data size
maxmemory 2gb
```

**Why `noeviction` is mandatory**: EchoMQ stores job state, queue metadata, and lock tokens in Redis. If Redis evicts keys under memory pressure, jobs silently disappear, locks break, and workers process phantom state. The `noeviction` policy returns errors on writes when memory is full, which EchoMQ handles as a transient failure with retry.

### Connection Pooling

<tabs>
<tab title="Elixir">

```elixir
# EchoMQ.RedisConnection manages a supervised connection.
# For high-throughput queues, use separate connections per worker
# to avoid head-of-line blocking on the Redis socket.

children = [
  # Shared connection for queue operations
  {EchoMQ.RedisConnection,
    name: :arena_redis,
    url: System.get_env("REDIS_URL"),
    socket_opts: [
      keepalive: true,
      nodelay: true
    ]},

  # Dedicated connection for high-throughput combat queue
  {EchoMQ.RedisConnection,
    name: :combat_redis,
    url: System.get_env("REDIS_URL"),
    socket_opts: [keepalive: true]}
]
```

Elixir's `Redix` driver uses a single TCP connection per process. For BEAM, this is sufficient because the runtime multiplexes thousands of lightweight processes over that connection. Separate connections help only when a single queue saturates the socket.

> **Benefit**: Rate limiting uses Redis TTL keys — distributed limiting works across clustered BEAM nodes.

</tab>
<tab title="Go">

```go
// go-redis maintains an internal connection pool
rdb := redis.NewClient(&redis.Options{
    Addr:         os.Getenv("REDIS_URL"),
    Password:     os.Getenv("REDIS_PASSWORD"),
    DB:           0,
    PoolSize:     runtime.NumCPU() * 10, // 10 conns per core
    MinIdleConns: runtime.NumCPU(),       // Keep cores idle conns warm
    DialTimeout:  5 * time.Second,
    ReadTimeout:  3 * time.Second,
    WriteTimeout: 3 * time.Second,
    PoolTimeout:  4 * time.Second,
})
```

The Go Redis client pools connections automatically. `PoolSize` should be at least `sum(worker_concurrency)` across all workers in the process, since each active goroutine may hold a connection during a Redis round-trip.

> **Benefit**: Goroutine-per-job with semaphore-based limiting achieves OS-level parallelism.

</tab>
<tab title="Node.js">

```typescript
import { Worker, Queue } from "bullmq";
import IORedis from "ioredis";

// Shared connection with production settings
const connection = new IORedis(process.env.REDIS_URL, {
  maxRetriesPerRequest: null,  // Workers must retry indefinitely
  enableReadyCheck: true,
  retryStrategy(times: number) {
    return Math.max(Math.min(Math.exp(times), 20000), 1000);
  },
  reconnectOnError(err: Error) {
    // Reconnect on READONLY errors (Redis failover)
    return err.message.includes("READONLY");
  },
});

// Queue instances should fail fast (different config)
const queueConnection = new IORedis(process.env.REDIS_URL, {
  maxRetriesPerRequest: 3,      // Fail fast for enqueue operations
  enableOfflineQueue: false,    // Don't buffer commands during disconnect
});
```

IORedis maintains a single TCP connection per instance. For Node.js, create separate IORedis instances for workers (infinite retry) and queues (fail fast) to prevent enqueue operations from blocking during Redis reconnection.

> **Benefit**: `limiter` option integrates with BullMQ's built-in token bucket implementation.

</tab>
</tabs>

## 31.3. Supervision and Restart

Production workers must survive crashes, Redis disconnections, and deployment restarts without losing jobs.

### OTP Supervision Trees (Elixir)

<tabs>
<tab title="Elixir">

```elixir
defmodule Arena.Application do
  use Application

  @impl true
  def start(_type, _args) do
    Arena.Telemetry.setup()

    children = [
      # Redis connections (shared infrastructure)
      {EchoMQ.RedisConnection,
        name: :arena_redis,
        url: System.get_env("REDIS_URL", "redis://localhost:6379")},

      # Worker supervisor — isolates worker failures from the app
      Arena.WorkerSupervisor,

      # Health check endpoint
      {Bandit, plug: Arena.HealthPlug, port: 4000}
    ]

    opts = [strategy: :rest_for_one, name: Arena.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def prep_stop(_state) do
    # Gracefully close all workers before BEAM shutdown.
    # The supervisor sends :shutdown to each child, which triggers
    # Worker.terminate/2 -> close() -> waits for active jobs.
    :ok
  end
end

defmodule Arena.WorkerSupervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      # Combat: high throughput, real-time damage resolution
      Supervisor.child_spec(
        {EchoMQ.Worker,
          name: :combat_worker_1,
          queue: "combat-actions",
          connection: :arena_redis,
          processor: &Arena.CombatProcessor.process/1,
          concurrency: 60},
        id: :combat_1),
      Supervisor.child_spec(
        {EchoMQ.Worker,
          name: :combat_worker_2,
          queue: "combat-actions",
          connection: :arena_redis,
          processor: &Arena.CombatProcessor.process/1,
          concurrency: 60},
        id: :combat_2),

      # Matchmaking: moderate concurrency, DB-bound
      {EchoMQ.Worker,
        name: :matchmaking_worker,
        queue: "matchmaking",
        connection: :arena_redis,
        processor: &Arena.MatchmakingProcessor.process/1,
        concurrency: 20},

      # Leaderboard: serialized to prevent ranking races
      {EchoMQ.Worker,
        name: :leaderboard_worker,
        queue: "leaderboard",
        connection: :arena_redis,
        processor: &Arena.LeaderboardProcessor.process/1,
        concurrency: 1}
    ]

    Supervisor.init(children,
      strategy: :one_for_one,
      max_restarts: 10,
      max_seconds: 60
    )
  end
end
```

The `:rest_for_one` strategy at the application level ensures that if the Redis connection dies, all workers restart (since they depend on Redis). Within the worker supervisor, `:one_for_one` lets each worker restart independently.

> **Benefit**: `:telemetry.attach` adds zero-cost instrumentation — events are no-ops when unhandled.

</tab>
<tab title="Go">

```go
// Go workers use context.Context for lifecycle management.
// A supervisor pattern is built with goroutines + restart logic.

func superviseWorker(ctx context.Context, rdb redis.Cmdable, cfg QueueConfig) {
    for {
        select {
        case <-ctx.Done():
            return
        default:
        }

        w := echomq.NewWorker(cfg.Name, rdb, echomq.WorkerOptions{
            Concurrency:     cfg.Concurrency,
            ShutdownTimeout: 25 * time.Second,
        })
        w.Process(cfg.Processor)

        err := w.Start(ctx)
        if err != nil && ctx.Err() == nil {
            log.Printf("[%s] Worker crashed: %v. Restarting in 5s...",
                cfg.Name, err)
            time.Sleep(5 * time.Second)
            continue // Restart the worker
        }
        return // Context cancelled, exit cleanly
    }
}

func main() {
    ctx, cancel := signal.NotifyContext(context.Background(),
        os.Interrupt, syscall.SIGTERM)
    defer cancel()

    rdb := redis.NewClient(&redis.Options{Addr: os.Getenv("REDIS_URL")})

    queues := []QueueConfig{
        {"combat-actions", 60, combatProcessor},
        {"matchmaking", 20, matchmakingProcessor},
        {"leaderboard", 1, leaderboardProcessor},
    }

    var wg sync.WaitGroup
    for _, q := range queues {
        wg.Add(1)
        go func(cfg QueueConfig) {
            defer wg.Done()
            superviseWorker(ctx, rdb, cfg)
        }(q)
    }
    wg.Wait()
}
```

Go lacks built-in supervision trees, so the restart loop with backoff replicates the essential behavior: detect crash, wait, restart. The `context.Context` propagation ensures all goroutines shut down when SIGTERM is received.

> **Benefit**: Backoff configuration is declarative — `Type` and `Delay` fields are validated at compile time.

</tab>
<tab title="Node.js">

```typescript
import { Worker } from "bullmq";
import cluster from "node:cluster";
import os from "node:os";

if (cluster.isPrimary) {
  const numWorkers = parseInt(process.env.WORKER_PROCESSES || "4");
  console.log(`Starting ${numWorkers} worker processes`);

  for (let i = 0; i < numWorkers; i++) {
    cluster.fork();
  }

  // Restart crashed workers (supervisor behavior)
  cluster.on("exit", (worker, code) => {
    if (code !== 0) {
      console.error(`Worker PID ${worker.process.pid} crashed (code ${code}). Restarting...`);
      setTimeout(() => cluster.fork(), 5000);
    }
  });

  // Graceful shutdown: forward SIGTERM to all children
  process.on("SIGTERM", () => {
    for (const id in cluster.workers) {
      cluster.workers[id]?.process.kill("SIGTERM");
    }
  });
} else {
  const connection = { host: "localhost", port: 6379 };

  const combatWorker = new Worker("combat-actions", combatProcessor, {
    connection,
    concurrency: 60,
  });

  const matchWorker = new Worker("matchmaking", matchmakingProcessor, {
    connection,
    concurrency: 20,
  });

  // Graceful shutdown per process
  const shutdown = async () => {
    console.log(`[PID ${process.pid}] Shutting down...`);
    await Promise.all([combatWorker.close(), matchWorker.close()]);
    process.exit(0);
  };

  process.on("SIGTERM", shutdown);
  process.on("SIGINT", shutdown);

  // Catch unhandled errors to prevent silent crashes
  process.on("uncaughtException", (err) => {
    console.error("Uncaught exception:", err);
    process.exit(1); // Let cluster primary restart this worker
  });

  process.on("unhandledRejection", (reason) => {
    console.error("Unhandled rejection:", reason);
    process.exit(1);
  });
}
```

Node.js uses the `cluster` module (or PM2 in production) to supervise worker processes. Each child process runs its own event loop with independent V8 heaps, providing crash isolation between processes.

> **Benefit**: `ioredis` Cluster mode auto-discovers nodes and redirects commands transparently.

</tab>
</tabs>

### Graceful Shutdown and SIGTERM

When a container platform (Fly.io, Kubernetes) deploys a new version, it sends SIGTERM to the running process and waits for a grace period before sending SIGKILL. Workers must stop fetching new jobs and finish active ones within that window.

<tabs>
<tab title="Elixir">

```elixir
# BEAM handles SIGTERM automatically through the Application behavior.
# When the BEAM VM receives SIGTERM:
# 1. Application.prep_stop/1 is called
# 2. Supervisor sends :shutdown to each child (in reverse order)
# 3. Each Worker.terminate/2 calls close(timeout: 25_000)
# 4. Active BEAM processes finish or are killed at timeout
# 5. BEAM VM exits

# fly.toml
# [processes]
#   kill_signal = "SIGTERM"
#   kill_timeout = 30  # Must exceed worker shutdown timeout (25s)
```

> **Benefit**: OTP shutdown signals propagate through the supervision tree — coordinated multi-worker drain.

</tab>
<tab title="Go">

```go
// signal.NotifyContext handles SIGTERM/SIGINT in main()
ctx, cancel := signal.NotifyContext(context.Background(),
    os.Interrupt, syscall.SIGTERM)
defer cancel()

// Worker.Start(ctx) blocks until context is cancelled,
// then calls gracefulShutdown() internally:
// 1. Stop picking new jobs (main loop exits)
// 2. wg.Wait() for active goroutines
// 3. ShutdownTimeout (25s) prevents indefinite hang
// 4. Returns error if timeout exceeded
```

> **Tradeoff**: Lock extension requires periodic goroutine-based timers — manual lifecycle management.

</tab>
<tab title="Node.js">

```typescript
const SHUTDOWN_TIMEOUT = 25_000;

const gracefulShutdown = async (signal: string) => {
  console.log(`Received ${signal}, closing workers...`);

  const timeout = setTimeout(() => {
    console.error("Shutdown timeout exceeded, forcing exit");
    process.exit(1);
  }, SHUTDOWN_TIMEOUT);

  try {
    await Promise.all(workers.map((w) => w.close()));
    clearTimeout(timeout);
    console.log("All workers closed gracefully");
    process.exit(0);
  } catch (err) {
    console.error("Error during shutdown:", err);
    process.exit(1);
  }
};

process.on("SIGINT", () => gracefulShutdown("SIGINT"));
process.on("SIGTERM", () => gracefulShutdown("SIGTERM"));
```

> **Benefit**: `worker.close()` returns a Promise that resolves when all active jobs complete.

</tab>
</tabs>

Set the container kill timeout (Fly.io `kill_timeout`, Kubernetes `terminationGracePeriodSeconds`) to at least 5 seconds more than your worker shutdown timeout. This gives the process time to drain active jobs before receiving SIGKILL.

## 31.4. Health Checks

Health checks let load balancers, container orchestrators, and monitoring systems verify that workers are alive and processing jobs.

<tabs>
<tab title="Elixir">

```elixir
defmodule Arena.HealthPlug do
  use Plug.Router

  plug :match
  plug :dispatch

  # Liveness: is the BEAM process running?
  get "/health/live" do
    send_resp(conn, 200, "ok")
  end

  # Readiness: are all workers processing jobs?
  get "/health/ready" do
    workers = [
      {:combat_worker_1, "combat-actions"},
      {:combat_worker_2, "combat-actions"},
      {:matchmaking_worker, "matchmaking"},
      {:leaderboard_worker, "leaderboard"}
    ]

    results = Enum.map(workers, fn {name, queue} ->
      case Process.whereis(name) do
        nil -> %{queue: queue, worker: name, status: "down"}
        pid when is_pid(pid) ->
          if EchoMQ.Worker.running?(name) do
            %{queue: queue, worker: name, status: "healthy"}
          else
            %{queue: queue, worker: name, status: "paused"}
          end
      end
    end)

    all_healthy = Enum.all?(results, &(&1.status == "healthy"))
    status = if all_healthy, do: 200, else: 503
    send_resp(conn, status, Jason.encode!(%{workers: results}))
  end

  # Queue depth: how many jobs are waiting?
  get "/health/queues" do
    queues = ["combat-actions", "matchmaking", "leaderboard"]

    depths = Enum.map(queues, fn queue ->
      counts = EchoMQ.Queue.get_job_counts(queue, connection: :arena_redis)
      %{queue: queue, waiting: counts.waiting, active: counts.active,
        delayed: counts.delayed, failed: counts.failed}
    end)

    send_resp(conn, 200, Jason.encode!(%{queues: depths}))
  end

  match _ do
    send_resp(conn, 404, "not found")
  end
end
```

> **Benefit**: Queue pause uses Redis flags — paused state persists across BEAM node restarts.

</tab>
<tab title="Go">

```go
func startHealthServer(ctx context.Context, rdb redis.Cmdable, workers []*echomq.Worker) {
    mux := http.NewServeMux()

    // Liveness: is the process running?
    mux.HandleFunc("/health/live", func(w http.ResponseWriter, r *http.Request) {
        w.WriteHeader(http.StatusOK)
        w.Write([]byte("ok"))
    })

    // Readiness: can the process reach Redis?
    mux.HandleFunc("/health/ready", func(w http.ResponseWriter, r *http.Request) {
        if err := rdb.Ping(ctx).Err(); err != nil {
            w.WriteHeader(http.StatusServiceUnavailable)
            fmt.Fprintf(w, `{"status":"unhealthy","error":"%s"}`, err.Error())
            return
        }
        w.WriteHeader(http.StatusOK)
        w.Write([]byte(`{"status":"healthy"}`))
    })

    // Queue depth: waiting + active counts
    mux.HandleFunc("/health/queues", func(w http.ResponseWriter, r *http.Request) {
        queues := []string{"combat-actions", "matchmaking", "leaderboard"}
        type QueueHealth struct {
            Queue   string `json:"queue"`
            Waiting int64  `json:"waiting"`
            Active  int64  `json:"active"`
        }

        var results []QueueHealth
        for _, q := range queues {
            kb := echomq.NewKeyBuilder(q, rdb)
            waiting, _ := rdb.LLen(ctx, kb.Wait()).Result()
            active, _ := rdb.LLen(ctx, kb.Active()).Result()
            results = append(results, QueueHealth{
                Queue: q, Waiting: waiting, Active: active,
            })
        }

        w.Header().Set("Content-Type", "application/json")
        json.NewEncoder(w).Encode(map[string]interface{}{"queues": results})
    })

    srv := &http.Server{Addr: ":8080", Handler: mux}
    go func() {
        <-ctx.Done()
        srv.Shutdown(context.Background())
    }()
    srv.ListenAndServe()
}
```

> **Tradeoff**: Graceful shutdown requires `os/signal.Notify` and manual drain loop — more boilerplate.

</tab>
<tab title="Node.js">

```typescript
import express from "express";
import { Queue } from "bullmq";

const app = express();
const connection = { host: "localhost", port: 6379 };

// Liveness
app.get("/health/live", (_req, res) => {
  res.status(200).json({ status: "ok" });
});

// Readiness: check Redis connection
app.get("/health/ready", async (_req, res) => {
  try {
    const queue = new Queue("combat-actions", { connection });
    await queue.client.then((c) => c.ping());
    res.status(200).json({ status: "healthy" });
  } catch (err) {
    res.status(503).json({ status: "unhealthy", error: String(err) });
  }
});

// Queue depth
app.get("/health/queues", async (_req, res) => {
  const queueNames = ["combat-actions", "matchmaking", "leaderboard"];
  const results = await Promise.all(
    queueNames.map(async (name) => {
      const queue = new Queue(name, { connection });
      const counts = await queue.getJobCounts(
        "waiting", "active", "delayed", "failed"
      );
      return { queue: name, ...counts };
    })
  );
  res.json({ queues: results });
});

app.listen(8080, () => console.log("Health server on :8080"));
```

> **Benefit**: Millisecond delays align with JavaScript's native timing model — intuitive for Node.js developers.

</tab>
</tabs>

### Alert Thresholds

| Metric | Warning | Critical | Action |
|--------|---------|----------|--------|
| Queue depth (waiting) | > 1,000 | > 10,000 | Scale up workers |
| Active job count | = concurrency limit | Sustained 5 min | Increase concurrency or add workers |
| Failed job rate | > 1% of processed | > 5% | Investigate processor errors |
| Stalled job count | > 0 | > 10 | Check worker health, lock duration |
| Redis memory usage | > 70% maxmemory | > 90% | Increase memory or enable job removal |

## 31.5. Benchmarks

Benchmark data establishes baseline throughput so you can size your worker fleet for Fireheadz Arena's peak load.

### Single Worker (Elixir)

| Concurrency | Jobs | Time | Throughput |
|-------------|------|------|------------|
| 100 | 500 | 206ms | 2,427 j/s |
| 200 | 1,000 | 357ms | 2,801 j/s |
| 500 | 2,500 | 510ms | 4,901 j/s |

A single Elixir worker saturates at ~500 concurrency because job fetching from Redis is sequential (`RPOP` / `ZPOPMIN` per job).

### Multi-Worker Scaling (Elixir)

| Workers | Concurrency/Worker | Total Concurrency | Jobs | Time | Throughput |
|---------|-------------------|-------------------|------|------|------------|
| 1 | 500 | 500 | 2,500 | 608ms | 4,111 j/s |
| 5 | 500 | 2,500 | 12,500 | 1,011ms | 12,363 j/s |
| 10 | 500 | 5,000 | 25,000 | 1,515ms | **16,501 j/s** |

Multiple workers scale nearly linearly up to ~10 workers, each with its own Redis connection and LockManager. Beyond 10 workers, Redis itself becomes the bottleneck.

### Bulk Add Performance (Elixir)

| Method | Connections | Throughput | Speedup |
|--------|-------------|------------|---------|
| Sequential | 1 | 5,700 j/s | 1.0x |
| Transactional | 1 | 24,000 j/s | 4.2x |
| Transactional | 4 | 54,000 j/s | 9.5x |
| **Transactional** | **8** | **58,000 j/s** | **10.2x** |

`add_bulk` uses MULTI/EXEC transactions with parallel connections. Each chunk of 100 jobs is added atomically.

### Go Throughput

| Configuration | No-Op Throughput | Notes |
|---------------|-----------------|-------|
| 1 worker, concurrency 1 | ~800 j/s | Sequential baseline |
| 1 worker, concurrency 60 | ~2,800 j/s | Goroutine parallelism |
| Bulk add (10K jobs) | ~30,000 j/s | Pipeline batching |

Go throughput is lower than Elixir for no-op jobs because the current Go implementation uses non-Lua `RPOP` + separate lock acquisition (two round-trips per job), whereas Elixir uses a single atomic Lua script. For real-world jobs with I/O (HTTP, database), this difference narrows significantly.

> **Go Production Gaps**: Rate limiting (GAP-005) and built-in metrics emission (GAP-006) are not yet implemented in the Go runtime. Use application-level rate limiting and Prometheus instrumentation as documented in [Ch 25: Rate Limiting](ch25-rate-limiting.md) and [Ch 29: Metrics & Prometheus](ch29-metrics-prometheus.md).

### Capacity Planning Formula

```
required_workers = peak_jobs_per_second * avg_job_duration_ms / (concurrency * 1000)
```

For Fireheadz Arena peak load (Saturday evening, all regions):

| Queue | Peak Rate | Avg Duration | Concurrency | Workers Needed |
|-------|-----------|-------------|-------------|---------------|
| `combat-actions` | 5,000 j/s | 2ms | 60 | 2 (per region) |
| `matchmaking` | 200 j/s | 50ms | 20 | 1 |
| `inventory` | 100 j/s | 10ms | 5 | 1 |
| `leaderboard` | 50 j/s | 5ms | 1 | 1 |

### Reproducing Benchmarks

Run benchmarks locally to validate throughput on your hardware. Redis 7+ must be running on localhost:

<tabs>
<tab title="Elixir">

```bash
mix run -e '
alias EchoMQ.{Queue, Worker, RedisConnection}

configs = [{1, 500, 2500}, {5, 500, 12500}, {10, 500, 25000}]

for {n_workers, concurrency, job_count} <- configs do
  conn = :"bench_#{:erlang.unique_integer([:positive])}"
  {:ok, _} = RedisConnection.start_link(host: "localhost", port: 6379, name: conn)
  queue = "bench_#{:erlang.unique_integer([:positive])}"
  completed = :counters.new(1, [])
  processor = fn _job -> :counters.add(completed, 1, 1); :ok end
  jobs = for i <- 1..job_count, do: {"job-#{i}", %{}, []}
  {:ok, _} = Queue.add_bulk(queue, jobs, connection: conn)

  start = System.monotonic_time(:millisecond)
  workers = for _ <- 1..n_workers do
    {:ok, w} = Worker.start_link(queue: queue, connection: conn,
      concurrency: concurrency, processor: processor)
    w
  end

  wait = fn f -> Process.sleep(100); if :counters.get(completed, 1) < job_count, do: f.(f) end
  wait.(wait)
  elapsed = System.monotonic_time(:millisecond) - start
  IO.puts("#{n_workers} workers: #{trunc(job_count / elapsed * 1000)} j/s")
  Enum.each(workers, &GenServer.stop/1)
end
'
```

</tab>
<tab title="Go">

```bash
# Go benchmark: build and run the echomq bench command
cd pkg/echomq
go test -bench=BenchmarkWorkerThroughput -benchtime=5s ./...
```

</tab>
<tab title="Node.js">

```bash
# Node.js benchmark using BullMQ's built-in benchmarks
npx tsx scripts/benchmark.ts --workers=10 --concurrency=500 --jobs=25000
```

</tab>
</tabs>

The sweet spot for Elixir is 200-500 concurrency per worker. Above 500, diminishing returns occur due to sequential Redis fetching. Multiple workers (5-10) provide near-linear scaling up to the Redis throughput ceiling.

## 31.6. Error Recovery

### Dead Letter Queues

Move permanently failed jobs to a dead letter queue for manual investigation instead of discarding them.

<tabs>
<tab title="Elixir">

```elixir
defmodule Arena.DeadLetterHandler do
  require Logger

  def handle_failed(%EchoMQ.Job{} = job, reason) do
    Logger.error("Job #{job.id} permanently failed: #{inspect(reason)}",
      queue: job.queue_name, job_name: job.name, attempts: job.attempts_made)

    EchoMQ.Queue.add("dead-letter", "failed_#{job.name}", %{
      original_queue: job.queue_name,
      original_job_id: job.id,
      job_data: job.data,
      failed_reason: inspect(reason),
      failed_at: DateTime.utc_now() |> DateTime.to_iso8601()
    }, connection: :arena_redis)
  end
end

# Attach to worker
{EchoMQ.Worker,
  queue: "combat-actions",
  connection: :arena_redis,
  processor: &Arena.CombatProcessor.process/1,
  on_failed: &Arena.DeadLetterHandler.handle_failed/2,
  concurrency: 60}
```

> **Benefit**: BEAM processes provide true preemptive concurrency — one slow job cannot starve others.

</tab>
<tab title="Go">

```go
func deadLetterHandler(rdb redis.Cmdable) func(*echomq.Job, error) {
    dlq := echomq.NewQueue("dead-letter", rdb)
    return func(job *echomq.Job, jobErr error) {
        log.Printf("[DLQ] Job %s from %s failed: %v",
            job.ID, job.QueueName(), jobErr)

        dlq.Add(context.Background(),
            fmt.Sprintf("failed_%s", job.Name),
            map[string]interface{}{
                "original_queue":  job.QueueName(),
                "original_job_id": job.ID,
                "job_data":        job.Data,
                "failed_reason":   jobErr.Error(),
                "failed_at":       time.Now().UTC().Format(time.RFC3339),
            },
            echomq.JobOptions{},
        )
    }
}
```

> **Benefit**: Returned `error` values make every failure path visible in the code flow.

</tab>
<tab title="Node.js">

```typescript
import { Queue, Worker, Job } from "bullmq";

const dlq = new Queue("dead-letter", { connection });

const combatWorker = new Worker("combat-actions", combatProcessor, {
  connection,
  concurrency: 60,
});

combatWorker.on("failed", async (job: Job | undefined, err: Error) => {
  if (!job) return;

  // Only move to DLQ if all retries exhausted
  if (job.attemptsMade >= (job.opts.attempts ?? 3)) {
    await dlq.add(`failed_${job.name}`, {
      originalQueue: job.queueName,
      originalJobId: job.id,
      jobData: job.data,
      failedReason: err.message,
      failedAt: new Date().toISOString(),
    });
    console.error(`[DLQ] Job ${job.id} moved to dead-letter queue`);
  }
});
```

> **Tradeoff**: Event loop concurrency means I/O-bound jobs scale well but CPU-bound jobs need worker threads.

</tab>
</tabs>

### Idempotent Processors

Jobs may execute more than once due to stalled recovery, lock expiration during network partitions, or deployment-triggered restarts. Every processor must be idempotent.

<tabs>
<tab title="Elixir">

```elixir
defmodule Arena.MatchmakingProcessor do
  def process(%EchoMQ.Job{id: job_id, data: %{"match_id" => match_id}} = _job) do
    # Use job_id as idempotency key to prevent duplicate match creation
    case Arena.Matches.create_if_not_exists(match_id, idempotency_key: job_id) do
      {:ok, :already_exists} ->
        {:ok, %{status: "already_created", match_id: match_id}}
      {:ok, match} ->
        {:ok, %{status: "created", match_id: match.id}}
      {:error, reason} ->
        {:error, reason}
    end
  end
end
```

> **Benefit**: `:telemetry` integration provides zero-cost event dispatch when no handlers are attached.

</tab>
<tab title="Go">

```go
func matchmakingProcessor(job *echomq.Job) (interface{}, error) {
    matchID := job.Data["match_id"].(string)

    // Idempotency check: has this job already created a match?
    exists, _ := db.Exec(
        "SELECT 1 FROM matches WHERE idempotency_key = $1", job.ID)
    if exists {
        return map[string]interface{}{
            "status": "already_created", "match_id": matchID,
        }, nil
    }

    match, err := createMatch(matchID, job.ID)
    if err != nil {
        return nil, err
    }
    return map[string]interface{}{
        "status": "created", "match_id": match.ID,
    }, nil
}
```

> **Benefit**: Returned `error` values make every failure path visible in the code flow.

</tab>
<tab title="Node.js">

```typescript
async function matchmakingProcessor(job: Job) {
  const matchId = job.data.match_id;

  // Idempotency: use job ID as unique constraint
  const [match, created] = await Match.findOrCreate({
    where: { idempotencyKey: job.id },
    defaults: { matchId, status: "pending" },
  });

  return {
    status: created ? "created" : "already_created",
    matchId: match.matchId,
  };
}
```

> **Benefit**: JSON job data requires no serialization step — JavaScript objects are the wire format.

</tab>
</tabs>

### Checkpoint Pattern

For long-running jobs (world sync, batch analytics), save intermediate progress so retries resume from the last checkpoint instead of starting over.

<tabs>
<tab title="Elixir">

```elixir
defmodule Arena.WorldSyncProcessor do
  def process(%EchoMQ.Job{id: job_id, data: %{"regions" => regions}} = job) do
    checkpoint = load_checkpoint(job_id) || %{synced: 0, results: []}
    remaining = Enum.drop(regions, checkpoint.synced)

    case sync_regions(remaining, checkpoint, job) do
      {:ok, results} ->
        clear_checkpoint(job_id)
        {:ok, %{synced: length(regions), results: results}}
      {:error, updated_checkpoint, reason} ->
        save_checkpoint(job_id, updated_checkpoint)
        {:error, reason}
    end
  end

  defp sync_regions([], checkpoint, _job), do: {:ok, checkpoint.results}

  defp sync_regions([region | rest], checkpoint, job) do
    case Arena.RegionSync.sync(region) do
      {:ok, result} ->
        new_cp = %{synced: checkpoint.synced + 1,
                    results: [result | checkpoint.results]}
        EchoMQ.Worker.update_progress(job, new_cp.synced)
        sync_regions(rest, new_cp, job)
      {:error, reason} ->
        {:error, checkpoint, reason}
    end
  end

  defp load_checkpoint(job_id), do: Arena.Cache.get("checkpoint:#{job_id}")
  defp save_checkpoint(job_id, cp), do: Arena.Cache.put("checkpoint:#{job_id}", cp)
  defp clear_checkpoint(job_id), do: Arena.Cache.delete("checkpoint:#{job_id}")
end
```

> **Benefit**: `EchoMQ.Job.update_progress/2` publishes to Redis streams — real-time progress tracking.

</tab>
<tab title="Go">

```go
func worldSyncProcessor(job *echomq.Job) (interface{}, error) {
    regions := job.Data["regions"].([]interface{})

    // Load checkpoint (resume from last successful region)
    checkpoint := loadCheckpoint(job.ID)
    remaining := regions[checkpoint.Synced:]

    for i, region := range remaining {
        result, err := syncRegion(region.(string))
        if err != nil {
            checkpoint.Synced += i
            saveCheckpoint(job.ID, checkpoint)
            return nil, fmt.Errorf("sync failed at region %s: %w",
                region, err)
        }
        checkpoint.Results = append(checkpoint.Results, result)
    }

    clearCheckpoint(job.ID)
    return map[string]interface{}{
        "synced":  len(regions),
        "results": checkpoint.Results,
    }, nil
}
```

> **Benefit**: Returned `error` values make every failure path visible in the code flow.

</tab>
<tab title="Node.js">

```typescript
async function worldSyncProcessor(job: Job) {
  const regions: string[] = job.data.regions;

  // Load checkpoint
  const checkpoint = (await loadCheckpoint(job.id)) || {
    synced: 0,
    results: [] as string[],
  };
  const remaining = regions.slice(checkpoint.synced);

  for (const region of remaining) {
    try {
      const result = await syncRegion(region);
      checkpoint.synced++;
      checkpoint.results.push(result);
      await job.updateProgress(checkpoint.synced);
    } catch (err) {
      await saveCheckpoint(job.id, checkpoint);
      throw err; // Triggers retry from checkpoint
    }
  }

  await clearCheckpoint(job.id);
  return { synced: regions.length, results: checkpoint.results };
}
```

> **Benefit**: `job.updateProgress()` triggers `progress` events on QueueEvents listeners.

</tab>
</tabs>

## 31.7. Monitoring Pipeline

A production monitoring stack connects EchoMQ telemetry to Prometheus metrics and Grafana dashboards.

### Telemetry to Prometheus

<tabs>
<tab title="Elixir">

```elixir
defmodule Arena.Telemetry do
  import Telemetry.Metrics

  def setup do
    :telemetry.attach_many("arena-echomq", [
      [:echomq, :job, :complete],
      [:echomq, :job, :fail],
      [:echomq, :job, :stalled],
      [:echomq, :worker, :active]
    ], &handle_event/4, nil)
  end

  def metrics do
    [
      counter("echomq.job.complete.count",
        tags: [:queue, :job_name],
        description: "Total completed jobs"),
      counter("echomq.job.fail.count",
        tags: [:queue, :job_name],
        description: "Total failed jobs"),
      distribution("echomq.job.complete.duration",
        tags: [:queue],
        unit: {:native, :millisecond},
        description: "Job processing duration"),
      last_value("echomq.worker.active.count",
        tags: [:queue],
        description: "Currently active jobs per queue"),
      counter("echomq.job.stalled.count",
        tags: [:queue],
        description: "Jobs recovered from stalled state")
    ]
  end

  defp handle_event([:echomq, :job, :complete], measurements, metadata, _config) do
    :prometheus_counter.inc(:echomq_jobs_completed_total,
      [metadata.queue, metadata.job_name])
    :prometheus_histogram.observe(:echomq_job_duration_ms,
      [metadata.queue], measurements.duration)
  end

  defp handle_event([:echomq, :job, :fail], _measurements, metadata, _config) do
    :prometheus_counter.inc(:echomq_jobs_failed_total,
      [metadata.queue, metadata.job_name])
  end

  defp handle_event([:echomq, :job, :stalled], _measurements, metadata, _config) do
    :prometheus_counter.inc(:echomq_jobs_stalled_total, [metadata.queue])
  end

  defp handle_event([:echomq, :worker, :active], measurements, metadata, _config) do
    :prometheus_gauge.set(:echomq_worker_active_jobs,
      [metadata.queue], measurements.count)
  end
end
```

> **Benefit**: `TelemetryMetricsPrometheus` auto-generates Prometheus endpoint from `:telemetry` event definitions.

</tab>
<tab title="Go">

```go
import (
    "github.com/prometheus/client_golang/prometheus"
    "github.com/prometheus/client_golang/prometheus/promhttp"
)

var (
    jobsCompleted = prometheus.NewCounterVec(
        prometheus.CounterOpts{
            Name: "echomq_jobs_completed_total",
            Help: "Total completed jobs",
        },
        []string{"queue", "job_name"},
    )
    jobsFailed = prometheus.NewCounterVec(
        prometheus.CounterOpts{
            Name: "echomq_jobs_failed_total",
            Help: "Total failed jobs",
        },
        []string{"queue", "job_name"},
    )
    jobDuration = prometheus.NewHistogramVec(
        prometheus.HistogramOpts{
            Name:    "echomq_job_duration_seconds",
            Help:    "Job processing duration",
            Buckets: []float64{0.001, 0.005, 0.01, 0.05, 0.1, 0.5, 1, 5},
        },
        []string{"queue"},
    )
    queueDepth = prometheus.NewGaugeVec(
        prometheus.GaugeOpts{
            Name: "echomq_queue_waiting_jobs",
            Help: "Jobs waiting in queue",
        },
        []string{"queue"},
    )
)

func init() {
    prometheus.MustRegister(jobsCompleted, jobsFailed, jobDuration, queueDepth)
}

// Wrap processor with metrics instrumentation
func instrumentedProcessor(queue string, processor echomq.JobProcessor) echomq.JobProcessor {
    return func(job *echomq.Job) (interface{}, error) {
        start := time.Now()
        result, err := processor(job)
        duration := time.Since(start).Seconds()

        jobDuration.WithLabelValues(queue).Observe(duration)
        if err != nil {
            jobsFailed.WithLabelValues(queue, job.Name).Inc()
        } else {
            jobsCompleted.WithLabelValues(queue, job.Name).Inc()
        }
        return result, err
    }
}

// Expose /metrics endpoint
func main() {
    http.Handle("/metrics", promhttp.Handler())
    go http.ListenAndServe(":9090", nil)
}
```

> **Benefit**: `promhttp.Handler()` serves metrics on any port — no framework dependency needed.

</tab>
<tab title="Node.js">

```typescript
import client from "prom-client";
import express from "express";
import { Worker, Job } from "bullmq";

// Register metrics
const jobsCompleted = new client.Counter({
  name: "echomq_jobs_completed_total",
  help: "Total completed jobs",
  labelNames: ["queue", "job_name"],
});

const jobsFailed = new client.Counter({
  name: "echomq_jobs_failed_total",
  help: "Total failed jobs",
  labelNames: ["queue", "job_name"],
});

const jobDuration = new client.Histogram({
  name: "echomq_job_duration_seconds",
  help: "Job processing duration",
  labelNames: ["queue"],
  buckets: [0.001, 0.005, 0.01, 0.05, 0.1, 0.5, 1, 5],
});

// Attach to worker events
function instrumentWorker(worker: Worker, queue: string) {
  worker.on("completed", (job: Job) => {
    jobsCompleted.inc({ queue, job_name: job.name });
  });

  worker.on("failed", (job: Job | undefined, err: Error) => {
    if (job) jobsFailed.inc({ queue, job_name: job.name });
  });
}

// Prometheus endpoint
const metricsApp = express();
metricsApp.get("/metrics", async (_req, res) => {
  res.set("Content-Type", client.register.contentType);
  res.end(await client.register.metrics());
});
metricsApp.listen(9090, () => console.log("Metrics on :9090"));
```

> **Benefit**: `prom-client` `register.metrics()` returns Prometheus text format ready for scraping.

</tab>
</tabs>

### Grafana Dashboard Queries

Key PromQL queries for an EchoMQ dashboard:

```promql
# Throughput (jobs/second) by queue
rate(echomq_jobs_completed_total[5m])

# Error rate (percentage of failed jobs)
rate(echomq_jobs_failed_total[5m]) / (rate(echomq_jobs_completed_total[5m]) + rate(echomq_jobs_failed_total[5m])) * 100

# P95 job duration by queue
histogram_quantile(0.95, rate(echomq_job_duration_seconds_bucket[5m]))

# Queue depth (waiting jobs)
echomq_queue_waiting_jobs

# Stalled jobs per hour
increase(echomq_jobs_stalled_total[1h])
```

## 31.8. Scaling Guide

### Vertical vs Horizontal

| Strategy | When to Use | How |
|----------|------------|-----|
| **Vertical (concurrency)** | Queue underutilized, CPU/RAM available | Increase `concurrency` per worker |
| **Vertical (workers)** | Single worker saturated at ~500 concurrency | Add more worker instances per machine |
| **Horizontal (machines)** | Single machine at capacity | Deploy same worker app to additional machines |

### Per-Queue Tuning Reference

| Queue | Concurrency | Workers/Region | Rationale |
|-------|-------------|---------------|-----------|
| `combat-actions` | 60 | 2 | I/O-bound (Redis reads), fast resolution. High throughput keeps combat responsive. |
| `matchmaking` | 20 | 1 | Each search queries the database. Match connection pool size to prevent exhaustion. |
| `inventory` | 5 | 1 | Database writes with consistency requirements. Too many concurrent trades risk item duplication. |
| `leaderboard` | 1 | 1 | Sequential aggregation prevents ranking inconsistencies. Throughput is not the bottleneck. |
| `player-events` | 200 | 1 | Fire-and-forget analytics. No ordering or consistency requirements. |
| `world-sync` | 10 | 1 | Long-running region syncs. Limited by external API rate limits. |

### Scaling Decision Tree

```
Is queue depth growing faster than drain rate?
  |
  +-- YES: Workers are saturated
  |     |
  |     +-- Is concurrency at recommended max for this queue type?
  |     |     |
  |     |     +-- NO:  Increase concurrency (cheapest change)
  |     |     +-- YES: Are workers at CPU/memory limit?
  |     |              |
  |     |              +-- NO:  Add more worker instances (same machine)
  |     |              +-- YES: Add more machines (horizontal scale)
  |     |
  |     +-- Is avg job duration unexpectedly high?
  |           |
  |           +-- YES: Optimize processor (DB queries, external calls)
  |           +-- NO:  Scale workers (above)
  |
  +-- NO: Current capacity is sufficient
```

## 31.9. Production Checklist

> Use this checklist before every production deployment.

### Redis

- [ ] `maxmemory-policy` set to `noeviction`
- [ ] AOF persistence enabled with `appendfsync everysec`
- [ ] RDB snapshots configured for baseline recovery
- [ ] `maxmemory` set with 30% headroom above expected usage
- [ ] Connection timeouts configured (read: 3s, write: 3s, dial: 5s)
- [ ] Redis version 6.0+ (required for Lua script compatibility)

### Workers

- [ ] All workers registered in a supervision tree (Elixir), restart loop (Go), or cluster/PM2 (Node.js)
- [ ] Graceful shutdown handles SIGTERM with a timeout matching container kill timeout
- [ ] Shutdown timeout is 5s less than container `kill_timeout` to allow cleanup
- [ ] `concurrency` tuned per queue based on workload profile
- [ ] Stalled check interval configured (default 30s is suitable for most queues)

### Processors

- [ ] All processors are idempotent (safe to execute multiple times)
- [ ] Unrecoverable errors use `UnrecoverableError` (Elixir) or `PermanentError` (Go) to skip retry
- [ ] Long-running jobs implement checkpoint pattern for resume-on-retry
- [ ] Dead letter queue configured for permanently failed jobs
- [ ] Auto-removal configured for completed jobs (`removeOnComplete: { count: 1000 }`)

### Monitoring

- [ ] Health check endpoints exposed (liveness + readiness)
- [ ] Prometheus metrics registered (completed, failed, duration, queue depth, stalled)
- [ ] Grafana dashboard with throughput, error rate, P95 duration, queue depth panels
- [ ] Alerts configured: queue depth > 10K, error rate > 5%, stalled > 10
- [ ] Log aggregation configured with structured logging (queue, job_id, duration)

### Security

- [ ] Redis password set via environment variable (not in config files)
- [ ] Sensitive data excluded from job payloads (or encrypted before enqueue)
- [ ] Redis bound to internal network only (no public access)
- [ ] TLS enabled for Redis connections in production

### Deployment

- [ ] Docker image uses multi-stage build (small runtime image)
- [ ] Container resource limits set (CPU, memory)
- [ ] Fly.io / Kubernetes health checks configured for readiness endpoint
- [ ] Rolling deployment strategy (new workers start before old ones drain)
- [ ] Environment-specific config via environment variables (not hardcoded)

## 31.10. Troubleshooting

### Missing Locks

The error "Missing lock for job 1234. moveToFinished." means a worker tried to complete or fail a job whose lock was deleted. The worker "owns" the job via a Redis lock key; if this key disappears, the completion Lua script rejects the operation.

Common causes:

| Cause | Diagnosis | Fix |
|-------|-----------|-----|
| CPU starvation | Worker consuming too much CPU, unable to renew lock within 30s | Increase `lock_duration`, reduce job processing time, or increase worker count |
| Redis disconnect | Worker lost connection during lock renewal window | Check Redis connectivity, enable `keepalive` on connections |
| Forced removal | Job removed via API while still processing | Avoid `Queue.obliterate` / `Queue.clean` on active queues |
| Wrong eviction policy | Redis evicted the lock key under memory pressure | Set `maxmemory-policy noeviction` (see 31.2) |

### Invalid Arguments in Lua Scripts

The error "ERR Error running script ... Lua redis() command arguments must be strings or integers" typically means an undefined or non-string value was passed as a job parameter. This happens when:

- Environment variables are undefined or empty strings
- Job data contains unexpected types (objects or arrays where strings are expected)

<tabs>
<tab title="Elixir">

```elixir
# Validate config at startup — fail fast, not in Lua scripts
queue_name = System.get_env("QUEUE_NAME") || raise "QUEUE_NAME not set"
redis_url = System.get_env("REDIS_URL") || raise "REDIS_URL not set"

# Guard against nil data in job payloads
data = %{user_id: user_id, action: action}
unless is_binary(user_id), do: raise "user_id must be a string, got: #{inspect(user_id)}"
```

</tab>
<tab title="Go">

```go
// Validate at startup
queueName := os.Getenv("QUEUE_NAME")
if queueName == "" {
    log.Fatal("QUEUE_NAME environment variable is required")
}

// Go's type system prevents most nil-in-Redis issues at compile time.
// Watch for interface{} values that may be nil:
if data["user_id"] == nil {
    return fmt.Errorf("user_id is required")
}
```

</tab>
<tab title="Node.js">

```typescript
// Validate early — don't let undefined reach Redis
const queueName = process.env.QUEUE_NAME;
if (!queueName) {
  throw new Error("QUEUE_NAME is not defined or is empty");
}

// TypeScript strictNullChecks + explicit typing prevents most issues
const queue = new Queue(queueName, { connection });
```

</tab>
</tabs>

---

*Previous: [Telemetry & Tracing](ch30-telemetry-tracing.md) | Next: [OTP Supervision](ch32-otp-supervision.md)*
