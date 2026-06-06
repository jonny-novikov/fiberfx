# Chapter 24. Worker Concurrency

Concurrency determines how many jobs a single worker processes simultaneously. Each EchoMQ runtime implements concurrency using language-native primitives: Elixir spawns BEAM processes with true preemptive parallelism, Go launches goroutines controlled by a semaphore channel, and Node.js interleaves async promises on a single thread. Understanding these differences is essential for tuning a Fireheadz Arena game server where combat-actions, matchmaking, inventory, and leaderboard queues each demand different concurrency profiles.

## 24.1. Parallelism vs Concurrency

Before tuning workers, distinguish two concepts that are often conflated:

```
Parallelism                              Concurrency
(simultaneous execution)                 (interleaved progress)

  Core 1   Core 2   Core 3              Single Thread
  +------+ +------+ +------+            +---+---+---+---+---+
  | Job A| | Job B| | Job C|            | A | B | A | C | B |
  +------+ +------+ +------+            +---+---+---+---+---+
  Running at the SAME instant            Taking turns on ONE core
```

| Property | Parallelism | Concurrency |
|----------|------------|-------------|
| Execution | Simultaneous on multiple cores | Interleaved on one or more cores |
| Requires | Multiple CPU cores | Just one core (time-slicing) |
| Best for | CPU-bound work (damage calc) | I/O-bound work (Redis, HTTP) |
| BEAM | True parallel (schedulers per core) | Also concurrent (preemptive) |
| Go | True parallel (GOMAXPROCS goroutines) | Also concurrent (M:N scheduler) |
| Node.js | Not parallel (single thread) | Concurrent only (event loop) |

## 24.2. Concurrency Models by Runtime

Each runtime uses a fundamentally different mechanism to achieve concurrent job processing. This has real consequences for how you tune worker counts and concurrency settings.

```
+-----------------------------------------------------------------------+
|                         ELIXIR / BEAM                                  |
+-----------------------------------------------------------------------+
|                                                                        |
|  Single OS Process (BEAM VM)                                           |
|  +--------------------------------------------------------------+     |
|  | Scheduler 1   Scheduler 2   Scheduler 3   Scheduler 4        |     |
|  | (Core 1)      (Core 2)      (Core 3)      (Core 4)           |     |
|  |  [P1][P2]      [P3][P4]      [P5][P6]      [P7][P8]          |     |
|  |  [P9][P10]     [P11][P12]    [P13]...       ...               |     |
|  +--------------------------------------------------------------+     |
|  1 OS process, N schedulers, thousands of lightweight processes        |
|  Preemptive: a stuck process cannot block others                       |
|  Per-process GC: no stop-the-world pauses                              |
|                                                                        |
+-----------------------------------------------------------------------+
|                            GO                                          |
+-----------------------------------------------------------------------+
|                                                                        |
|  Single OS Process (Go runtime)                                        |
|  +--------------------------------------------------------------+     |
|  | OS Thread 1   OS Thread 2   OS Thread 3   OS Thread 4        |     |
|  | (Core 1)      (Core 2)      (Core 3)      (Core 4)           |     |
|  |  [G1][G2]      [G3][G4]      [G5][G6]      [G7][G8]          |     |
|  |  [G9]...       ...           ...            ...               |     |
|  +--------------------------------------------------------------+     |
|  1 OS process, M:N scheduling (goroutines onto OS threads)             |
|  Cooperative + preemptive (Go 1.14+): tight loops preempted            |
|  Stop-the-world GC: brief pauses (~1ms typical)                        |
|                                                                        |
+-----------------------------------------------------------------------+
|                          NODE.JS                                       |
+-----------------------------------------------------------------------+
|                                                                        |
|  Single OS Process                                                     |
|  +--------------------------------------------------------------+     |
|  | Event Loop (1 thread)                                         |     |
|  |                                                               |     |
|  |  await Job1 --> yield --> await Job2 --> yield --> await Job3  |     |
|  |  (only ONE piece of JS executes at any instant)               |     |
|  +--------------------------------------------------------------+     |
|  1 thread, async/await interleaving                                    |
|  CPU-bound work blocks ALL other jobs                                  |
|  Multi-core requires PM2 cluster or worker_threads                     |
|                                                                        |
+-----------------------------------------------------------------------+
```

## 24.3. Setting Concurrency

The `concurrency` option controls the maximum number of jobs a single worker instance processes at the same time.

<tabs>
<tab title="Elixir">

```elixir
# Each concurrent job runs in its own BEAM process
{:ok, worker} = EchoMQ.Worker.start_link(
  queue: "combat-actions",
  connection: :arena_redis,
  processor: &Arena.CombatProcessor.process/1,
  concurrency: 60
)
```

Internally, the worker GenServer spawns up to 60 `Task.async` processes. Each runs in true parallel across all available CPU schedulers. A CPU-bound damage calculation in slot 1 cannot block a buff application in slot 2.

> **Benefit**: GenServer-based schedulers integrate with supervision — restarts guarantee schedule continuity.

</tab>
<tab title="Go">

```go
worker := echomq.NewWorker("combat-actions", rdb, echomq.WorkerOptions{
    Concurrency:          60,
    LockDuration:         30 * time.Second,
    HeartbeatInterval:    15 * time.Second,
    StalledCheckInterval: 30 * time.Second,
})

worker.Process(func(job *echomq.Job) (interface{}, error) {
    damage := resolveDamage(job.Data)
    return map[string]interface{}{"damage": damage}, nil
})

worker.Start(ctx)
```

The Go worker uses a **buffered channel semaphore** (`activeSemaphore`) sized to the concurrency value. The main loop acquires a slot by sending to the channel, then launches a goroutine for the job. The goroutine releases the slot via `defer` when done:

```
Main loop: activeSemaphore <- struct{}{}   (acquire)
           go processJob(ctx, jobID, token)
               defer <-activeSemaphore     (release)
```

A `sync.WaitGroup` tracks all active goroutines for graceful shutdown.

> **Benefit**: Goroutine-per-job with semaphore-based limiting achieves OS-level parallelism.

</tab>
<tab title="Node.js">

```typescript
import { Worker } from "bullmq";

const worker = new Worker(
  "combat-actions",
  async (job) => {
    const damage = resolveDamage(job.data);
    return { damage, resolved: true };
  },
  {
    connection: { host: "localhost", port: 6379 },
    concurrency: 60,
  }
);
```

Node.js runs 60 async promises concurrently on a single thread. For I/O-bound jobs (Redis lookups, HTTP calls), this works well. For CPU-bound damage calculations, each promise blocks the entire event loop while executing synchronous code.

> **Tradeoff**: Event loop concurrency means I/O-bound jobs scale well but CPU-bound jobs need worker threads.

</tab>
</tabs>

> **⚠️ Go Gap**: Cooperative job cancellation is not implemented. Running jobs cannot be cancelled mid-execution.
> **Proposed Solution**: Pass `context.Context` to processor functions (already partially done). Add `CancelJob()` method that sets a Redis key, with the worker checking via `ctx.Done()` channel or polling the cancel key.

## 24.4. Per-Queue Tuning for Game Servers

Different game systems have different concurrency requirements. A combat-actions queue processing real-time damage needs high throughput, while a leaderboard queue writing aggregate rankings needs strict serialization to prevent race conditions.

<tabs>
<tab title="Elixir">

```elixir
defmodule Arena.WorkerSupervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      # Combat: high concurrency for real-time damage resolution
      {EchoMQ.Worker,
        name: :combat_worker,
        queue: "combat-actions",
        connection: :arena_redis,
        processor: &Arena.CombatProcessor.process/1,
        concurrency: 60},

      # Matchmaking: moderate — each search holds DB connections
      {EchoMQ.Worker,
        name: :matchmaking_worker,
        queue: "matchmaking",
        connection: :arena_redis,
        processor: &Arena.MatchmakingProcessor.process/1,
        concurrency: 20},

      # Inventory: low — serialized writes to prevent item duplication
      {EchoMQ.Worker,
        name: :inventory_worker,
        queue: "inventory",
        connection: :arena_redis,
        processor: &Arena.InventoryProcessor.process/1,
        concurrency: 5},

      # Leaderboard: single — aggregate ranking must be sequential
      {EchoMQ.Worker,
        name: :leaderboard_worker,
        queue: "leaderboard",
        connection: :arena_redis,
        processor: &Arena.LeaderboardProcessor.process/1,
        concurrency: 1}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
```

> **Benefit**: BEAM processes provide true preemptive concurrency — one slow job cannot starve others.

</tab>
<tab title="Go">

```go
type QueueConfig struct {
    Name        string
    Concurrency int
    Processor   echomq.JobProcessor
}

queues := []QueueConfig{
    // Combat: high concurrency for real-time damage resolution
    {"combat-actions", 60, combatProcessor},
    // Matchmaking: moderate — each search holds DB connections
    {"matchmaking", 20, matchmakingProcessor},
    // Inventory: low — serialized writes prevent item duplication
    {"inventory", 5, inventoryProcessor},
    // Leaderboard: single — aggregate ranking must be sequential
    {"leaderboard", 1, leaderboardProcessor},
}

var wg sync.WaitGroup
for _, q := range queues {
    wg.Add(1)
    go func(cfg QueueConfig) {
        defer wg.Done()
        w := echomq.NewWorker(cfg.Name, rdb, echomq.WorkerOptions{
            Concurrency:          cfg.Concurrency,
            LockDuration:         30 * time.Second,
            HeartbeatInterval:    15 * time.Second,
            StalledCheckInterval: 30 * time.Second,
        })
        w.Process(cfg.Processor)
        if err := w.Start(ctx); err != nil {
            log.Printf("Worker %s stopped: %v", cfg.Name, err)
        }
    }(q)
}
wg.Wait()
```

> **Benefit**: Goroutine-per-job with semaphore-based limiting achieves OS-level parallelism.

</tab>
<tab title="Node.js">

```typescript
import { Worker } from "bullmq";

const connection = { host: "localhost", port: 6379 };

// Combat: high concurrency for real-time damage resolution
const combatWorker = new Worker("combat-actions", combatProcessor, {
  connection,
  concurrency: 60,
});

// Matchmaking: moderate — each search holds DB connections
const matchmakingWorker = new Worker("matchmaking", matchmakingProcessor, {
  connection,
  concurrency: 20,
});

// Inventory: low — serialized writes prevent item duplication
const inventoryWorker = new Worker("inventory", inventoryProcessor, {
  connection,
  concurrency: 5,
});

// Leaderboard: single — aggregate ranking must be sequential
const leaderboardWorker = new Worker("leaderboard", leaderboardProcessor, {
  connection,
  concurrency: 1,
});
```

> **Tradeoff**: Event loop concurrency means I/O-bound jobs scale well but CPU-bound jobs need worker threads.

</tab>
</tabs>

### Tuning Rationale

| Queue | Concurrency | Reasoning |
|-------|-------------|-----------|
| `combat-actions` | 60 | I/O-bound (Redis reads for player stats) + fast resolution. High throughput keeps combat responsive. |
| `matchmaking` | 20 | Each search queries the database. Match connection pool size to prevent exhaustion. |
| `inventory` | 5 | Database writes with consistency requirements. Too many concurrent trades risk item duplication. |
| `leaderboard` | 1 | Sequential aggregation prevents ranking inconsistencies. Throughput is not the bottleneck. |

## 24.5. Vertical Scaling: Multiple Workers per Machine

Increase throughput on a single machine by running multiple worker instances against the same queue. Redis Lua scripts handle atomic job distribution -- workers never steal each other's jobs.

<tabs>
<tab title="Elixir">

```elixir
defmodule Arena.CombatWorkerPool do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    # Scale based on CPU cores: 2 workers per core
    num_workers = System.schedulers_online() * 2

    children = for i <- 1..num_workers do
      Supervisor.child_spec(
        {EchoMQ.Worker,
          queue: "combat-actions",
          connection: :arena_redis,
          processor: &Arena.CombatProcessor.process/1,
          concurrency: 60},
        id: :"combat_worker_#{i}"
      )
    end

    Supervisor.init(children, strategy: :one_for_one)
  end
end

# On an 8-core machine: 16 workers x 60 concurrency = 960 parallel slots
```

BEAM workers rarely need multiple instances per machine because a single worker with high concurrency already uses all cores. Multiple workers are useful when you want independent failure domains or different processor functions on the same queue.

> **Benefit**: GenServer-based schedulers integrate with supervision — restarts guarantee schedule continuity.

</tab>
<tab title="Go">

```go
func startWorkerPool(ctx context.Context, rdb redis.Cmdable, count int) {
    var wg sync.WaitGroup

    for i := 0; i < count; i++ {
        wg.Add(1)
        go func(id int) {
            defer wg.Done()

            w := echomq.NewWorker("combat-actions", rdb, echomq.WorkerOptions{
                Concurrency:          60,
                LockDuration:         30 * time.Second,
                HeartbeatInterval:    15 * time.Second,
                StalledCheckInterval: 30 * time.Second,
            })
            w.Process(combatProcessor)

            if err := w.Start(ctx); err != nil {
                log.Printf("Worker %d stopped: %v", id, err)
            }
        }(i)
    }

    wg.Wait()
}

// On an 8-core machine:
// startWorkerPool(ctx, rdb, runtime.NumCPU() * 2)
// 16 workers x 60 concurrency = 960 parallel goroutine slots
```

Go's M:N scheduler distributes goroutines across OS threads automatically. Multiple worker instances add independent semaphore pools and stalled checkers, which improves fault isolation.

> **Tradeoff**: Go has no built-in cron — scheduler must use `time.Ticker` or external cron library.

</tab>
<tab title="Node.js">

```typescript
import { Worker } from "bullmq";
import cluster from "node:cluster";
import os from "node:os";

if (cluster.isPrimary) {
  const numWorkers = os.cpus().length;
  console.log(`Starting ${numWorkers} worker processes`);

  for (let i = 0; i < numWorkers; i++) {
    cluster.fork();
  }

  cluster.on("exit", (worker) => {
    console.log(`Worker ${worker.process.pid} exited, restarting`);
    cluster.fork();
  });
} else {
  // Each process runs its own event loop
  const worker = new Worker("combat-actions", combatProcessor, {
    connection: { host: "localhost", port: 6379 },
    concurrency: 60,
  });

  console.log(`Worker process ${process.pid} started`);
}

// 8 OS processes x 60 async concurrency = 480 concurrent slots
// Alternative: use PM2 for production process management
// pm2 start worker.js -i max
```

Node.js requires separate OS processes (via `cluster` module or PM2) to use multiple cores. Each process has its own V8 isolate, event loop, and memory space (~30-50MB per process).

> **Benefit**: `ioredis` Cluster mode auto-discovers nodes and redirects commands transparently.

</tab>
</tabs>

## 24.6. Horizontal Scaling: Multiple Machines

Deploy the same worker application to multiple machines. All workers connect to the same Redis instance and compete for jobs atomically.

```
+-------------------+     +-------------------+     +-------------------+
|   Game Server 1   |     |   Game Server 2   |     |   Game Server 3   |
|   Region: US-E    |     |   Region: US-W    |     |   Region: EU      |
|                   |     |                   |     |                   |
|  Elixir BEAM      |     |  Go binary        |     |  Node.js cluster  |
|  8 workers x 60   |     |  16 workers x 60  |     |  8 procs x 60     |
|  = 480 slots      |     |  = 960 slots      |     |  = 480 slots      |
+--------+----------+     +--------+----------+     +--------+----------+
         |                         |                         |
         +-------------------------+-------------------------+
                                   |
                            +------+------+
                            |    Redis    |
                            |  (shared)   |
                            +-------------+

Total capacity: 1,920 concurrent combat actions
Mixed runtimes: fully interoperable via EchoMQ protocol
```

Horizontal scaling requires zero coordination between machines. Redis Lua scripts (`moveToActive`, `moveToCompleted`) guarantee atomic job state transitions regardless of how many workers compete.

## 24.7. Dynamic Worker Scaling

Scale workers up or down at runtime based on game load. When a new arena room opens, spin up additional combat workers. When rooms close during off-peak hours, scale down.

<tabs>
<tab title="Elixir">

```elixir
defmodule Arena.DynamicWorkerManager do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def scale_up(queue, count \\ 1) do
    GenServer.call(__MODULE__, {:scale_up, queue, count})
  end

  def scale_down(queue, count \\ 1) do
    GenServer.call(__MODULE__, {:scale_down, queue, count})
  end

  def worker_count(queue) do
    GenServer.call(__MODULE__, {:count, queue})
  end

  @impl true
  def init(_opts) do
    {:ok, %{workers: %{}}}
  end

  @impl true
  def handle_call({:scale_up, queue, count}, _from, state) do
    new_pids = for _ <- 1..count do
      {:ok, pid} = DynamicSupervisor.start_child(
        Arena.WorkerSupervisor,
        {EchoMQ.Worker,
          queue: queue,
          connection: :arena_redis,
          processor: &Arena.CombatProcessor.process/1,
          concurrency: 60}
      )
      Process.monitor(pid)
      pid
    end

    existing = Map.get(state.workers, queue, [])
    {:reply, {:ok, length(new_pids)},
     %{state | workers: Map.put(state.workers, queue, existing ++ new_pids)}}
  end

  @impl true
  def handle_call({:scale_down, queue, count}, _from, state) do
    pids = Map.get(state.workers, queue, [])
    {to_stop, to_keep} = Enum.split(pids, count)

    Enum.each(to_stop, fn pid ->
      EchoMQ.Worker.close(pid)
      DynamicSupervisor.terminate_child(Arena.WorkerSupervisor, pid)
    end)

    {:reply, {:ok, length(to_stop)},
     %{state | workers: Map.put(state.workers, queue, to_keep)}}
  end

  @impl true
  def handle_call({:count, queue}, _from, state) do
    {:reply, length(Map.get(state.workers, queue, [])), state}
  end
end

# Arena room opened -- scale up combat workers
Arena.DynamicWorkerManager.scale_up("combat-actions", 4)

# Off-peak hours -- scale down
Arena.DynamicWorkerManager.scale_down("combat-actions", 2)
```

> **Benefit**: BEAM processes provide true preemptive concurrency — one slow job cannot starve others.

</tab>
<tab title="Go">

```go
type DynamicWorkerPool struct {
    mu       sync.Mutex
    workers  map[string][]*ManagedWorker
    rdb      redis.Cmdable
}

type ManagedWorker struct {
    worker *echomq.Worker
    cancel context.CancelFunc
}

func NewDynamicWorkerPool(rdb redis.Cmdable) *DynamicWorkerPool {
    return &DynamicWorkerPool{
        workers: make(map[string][]*ManagedWorker),
        rdb:     rdb,
    }
}

func (p *DynamicWorkerPool) ScaleUp(queue string, count int, processor echomq.JobProcessor) {
    p.mu.Lock()
    defer p.mu.Unlock()

    for i := 0; i < count; i++ {
        ctx, cancel := context.WithCancel(context.Background())
        w := echomq.NewWorker(queue, p.rdb, echomq.WorkerOptions{
            Concurrency:          60,
            LockDuration:         30 * time.Second,
            HeartbeatInterval:    15 * time.Second,
            StalledCheckInterval: 30 * time.Second,
        })
        w.Process(processor)

        managed := &ManagedWorker{worker: w, cancel: cancel}
        p.workers[queue] = append(p.workers[queue], managed)

        go w.Start(ctx)
    }
}

func (p *DynamicWorkerPool) ScaleDown(queue string, count int) int {
    p.mu.Lock()
    defer p.mu.Unlock()

    workers := p.workers[queue]
    if count > len(workers) {
        count = len(workers)
    }

    for i := 0; i < count; i++ {
        workers[i].cancel() // Triggers graceful shutdown
    }

    p.workers[queue] = workers[count:]
    return count
}

// Arena room opened -- scale up
pool := NewDynamicWorkerPool(rdb)
pool.ScaleUp("combat-actions", 4, combatProcessor)

// Off-peak -- scale down
pool.ScaleDown("combat-actions", 2)
```

> **Benefit**: Goroutine-per-job with semaphore-based limiting achieves OS-level parallelism.

</tab>
<tab title="Node.js">

```typescript
import { Worker } from "bullmq";

class DynamicWorkerPool {
  private workers: Map<string, Worker[]> = new Map();
  private connection = { host: "localhost", port: 6379 };

  async scaleUp(
    queue: string,
    count: number,
    processor: (job: any) => Promise<any>
  ): Promise<number> {
    const existing = this.workers.get(queue) || [];

    for (let i = 0; i < count; i++) {
      const worker = new Worker(queue, processor, {
        connection: this.connection,
        concurrency: 60,
      });
      existing.push(worker);
    }

    this.workers.set(queue, existing);
    return count;
  }

  async scaleDown(queue: string, count: number): Promise<number> {
    const workers = this.workers.get(queue) || [];
    const toRemove = Math.min(count, workers.length);

    for (let i = 0; i < toRemove; i++) {
      await workers[i].close(); // Graceful shutdown
    }

    this.workers.set(queue, workers.slice(toRemove));
    return toRemove;
  }

  workerCount(queue: string): number {
    return (this.workers.get(queue) || []).length;
  }
}

// Arena room opened -- scale up
const pool = new DynamicWorkerPool();
await pool.scaleUp("combat-actions", 4, combatProcessor);

// Off-peak -- scale down
await pool.scaleDown("combat-actions", 2);
```

> **Tradeoff**: Event loop concurrency means I/O-bound jobs scale well but CPU-bound jobs need worker threads.

</tab>
</tabs>

## 24.8. Graceful Shutdown

When a game server shuts down for maintenance or deployment, workers must finish active combat rounds before exiting. All three runtimes support graceful shutdown, but the mechanism differs.

<tabs>
<tab title="Elixir">

```elixir
# Graceful close -- waits for active jobs to complete
EchoMQ.Worker.close(worker)

# Force close -- abandons in-flight jobs (they become stalled)
EchoMQ.Worker.close(worker, force: true)

# In a supervised application, SIGTERM triggers orderly shutdown:
# 1. Application.stop/0 called
# 2. Supervisor sends :shutdown to each child
# 3. Each Worker GenServer calls close() in terminate/2
# 4. Active BEAM processes finish (up to shutdown timeout)
# 5. Jobs that don't finish within timeout become stalled

# Custom shutdown timeout in supervisor
Supervisor.init(children,
  strategy: :one_for_one,
  shutdown: 30_000  # 30 seconds to finish active jobs
)
```

> **Benefit**: Rate limiting uses Redis TTL keys — distributed limiting works across clustered BEAM nodes.

</tab>
<tab title="Go">

```go
// Signal-based graceful shutdown
ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
defer cancel()

worker := echomq.NewWorker("combat-actions", rdb, echomq.WorkerOptions{
    Concurrency:     60,
    ShutdownTimeout: 30 * time.Second, // Wait up to 30s for active jobs
})
worker.Process(combatProcessor)

// Start blocks until context cancelled
if err := worker.Start(ctx); err != nil {
    log.Printf("Worker shutdown: %v", err)
}

// Shutdown flow:
// 1. SIGTERM/SIGINT received -> context cancelled
// 2. Main loop stops picking new jobs
// 3. wg.Wait() blocks for active goroutines
// 4. If timeout exceeded: returns "shutdown timeout exceeded"
// 5. Active semaphore slots freed as goroutines exit
```

> **Benefit**: Goroutine-per-job with semaphore-based limiting achieves OS-level parallelism.

</tab>
<tab title="Node.js">

```typescript
const worker = new Worker("combat-actions", combatProcessor, {
  connection: { host: "localhost", port: 6379 },
  concurrency: 60,
});

// Graceful shutdown on SIGTERM
process.on("SIGTERM", async () => {
  console.log("Shutting down: finishing active combat rounds...");
  await worker.close(); // Waits for in-flight jobs
  console.log("All combat rounds resolved. Exiting.");
  process.exit(0);
});

// Force close if graceful shutdown takes too long
process.on("SIGTERM", async () => {
  const timeout = setTimeout(() => {
    console.error("Shutdown timeout -- forcing exit");
    process.exit(1);
  }, 30_000);

  await worker.close();
  clearTimeout(timeout);
  process.exit(0);
});
```

> **Tradeoff**: Event loop concurrency means I/O-bound jobs scale well but CPU-bound jobs need worker threads.

</tab>
</tabs>

## 24.9. Monitoring Active Concurrency

Track how many concurrent slots are in use to detect saturation. When active count consistently equals the concurrency limit, the worker is saturated and needs scaling.

<tabs>
<tab title="Elixir">

```elixir
# Query worker state directly
active = EchoMQ.Worker.active_count(worker)  # => 47
running = EchoMQ.Worker.running?(worker)      # => true
paused = EchoMQ.Worker.paused?(worker)        # => false

# Periodic monitoring with Telemetry
defmodule Arena.WorkerMonitor do
  use GenServer

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(opts) do
    workers = Keyword.fetch!(opts, :workers)
    :timer.send_interval(5_000, :report)
    {:ok, %{workers: workers}}
  end

  @impl true
  def handle_info(:report, state) do
    Enum.each(state.workers, fn {name, pid} ->
      active = EchoMQ.Worker.active_count(pid)
      :telemetry.execute(
        [:arena, :worker, :concurrency],
        %{active: active},
        %{queue: name}
      )
    end)
    {:noreply, state}
  end
end
```

> **Benefit**: `:telemetry.attach` adds zero-cost instrumentation — events are no-ops when unhandled.

</tab>
<tab title="Go">

```go
// Monitor active slot usage via Redis queue length
func monitorConcurrency(ctx context.Context, rdb redis.Cmdable, queue string) {
    ticker := time.NewTicker(5 * time.Second)
    defer ticker.Stop()

    kb := echomq.NewKeyBuilder(queue, rdb)
    for {
        select {
        case <-ctx.Done():
            return
        case <-ticker.C:
            // Active list length = currently processing jobs
            active, _ := rdb.LLen(ctx, kb.Active()).Result()
            // Waiting jobs = backlog depth
            waiting, _ := rdb.LLen(ctx, kb.Wait()).Result()
            // Prioritized jobs waiting
            prioritized, _ := rdb.ZCard(ctx, kb.Prioritized()).Result()

            log.Printf("[%s] active=%d waiting=%d prioritized=%d",
                queue, active, waiting, prioritized)

            if active >= 60 { // Saturated at concurrency limit
                log.Printf("[%s] WARNING: worker saturated, consider scaling", queue)
            }
        }
    }
}

go monitorConcurrency(ctx, rdb, "combat-actions")
```

> **Benefit**: Goroutine-per-job with semaphore-based limiting achieves OS-level parallelism.

</tab>
<tab title="Node.js">

```typescript
import { Queue } from "bullmq";

const queue = new Queue("combat-actions", {
  connection: { host: "localhost", port: 6379 },
});

// Periodic monitoring
setInterval(async () => {
  const counts = await queue.getJobCounts("active", "waiting", "delayed");
  console.log(
    `[combat-actions] active=${counts.active} waiting=${counts.waiting} delayed=${counts.delayed}`
  );

  if (counts.active >= 60) {
    console.warn("[combat-actions] WARNING: worker saturated, consider scaling");
  }
}, 5_000);
```

> **Tradeoff**: Event loop concurrency means I/O-bound jobs scale well but CPU-bound jobs need worker threads.

</tab>
</tabs>

## 24.10. Room-Based Auto-Scaling

In Fireheadz Arena, each active game room generates combat-action jobs. Auto-scale workers proportionally to the number of open rooms.

<tabs>
<tab title="Elixir">

```elixir
defmodule Arena.RoomScaler do
  use GenServer

  @check_interval 10_000  # Check every 10 seconds
  @jobs_per_room 3        # Expected concurrent jobs per room
  @concurrency 60         # Per-worker concurrency

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(_opts) do
    :timer.send_interval(@check_interval, :check_rooms)
    {:ok, %{current_workers: 1}}
  end

  @impl true
  def handle_info(:check_rooms, state) do
    active_rooms = Arena.RoomRegistry.active_count()
    # Workers needed = ceil(rooms * jobs_per_room / concurrency)
    needed = max(1, ceil(active_rooms * @jobs_per_room / @concurrency))

    cond do
      needed > state.current_workers ->
        diff = needed - state.current_workers
        Arena.DynamicWorkerManager.scale_up("combat-actions", diff)

      needed < state.current_workers ->
        diff = state.current_workers - needed
        Arena.DynamicWorkerManager.scale_down("combat-actions", diff)

      true -> :ok
    end

    {:noreply, %{state | current_workers: needed}}
  end
end
```

> **Benefit**: BEAM processes provide true preemptive concurrency — one slow job cannot starve others.

</tab>
<tab title="Go">

```go
type RoomScaler struct {
    pool          *DynamicWorkerPool
    processor     echomq.JobProcessor
    queue         string
    concurrency   int
    jobsPerRoom   int
    currentCount  int
    mu            sync.Mutex
}

func (s *RoomScaler) Reconcile(activeRooms int) {
    s.mu.Lock()
    defer s.mu.Unlock()

    // Workers needed = ceil(rooms * jobsPerRoom / concurrency)
    needed := (activeRooms*s.jobsPerRoom + s.concurrency - 1) / s.concurrency
    if needed < 1 {
        needed = 1
    }

    if needed > s.currentCount {
        diff := needed - s.currentCount
        s.pool.ScaleUp(s.queue, diff, s.processor)
        log.Printf("Scaled UP %s: %d -> %d workers (%d rooms)",
            s.queue, s.currentCount, needed, activeRooms)
    } else if needed < s.currentCount {
        diff := s.currentCount - needed
        s.pool.ScaleDown(s.queue, diff)
        log.Printf("Scaled DOWN %s: %d -> %d workers (%d rooms)",
            s.queue, s.currentCount, needed, activeRooms)
    }
    s.currentCount = needed
}

// Run reconciliation loop
func (s *RoomScaler) Start(ctx context.Context) {
    ticker := time.NewTicker(10 * time.Second)
    defer ticker.Stop()
    for {
        select {
        case <-ctx.Done():
            return
        case <-ticker.C:
            rooms := getActiveRoomCount() // Your game server API
            s.Reconcile(rooms)
        }
    }
}
```

> **Benefit**: Goroutine-per-job with semaphore-based limiting achieves OS-level parallelism.

</tab>
<tab title="Node.js">

```typescript
class RoomScaler {
  private pool: DynamicWorkerPool;
  private currentWorkers = 1;
  private readonly concurrency = 60;
  private readonly jobsPerRoom = 3;

  constructor(pool: DynamicWorkerPool) {
    this.pool = pool;
  }

  async reconcile(activeRooms: number): Promise<void> {
    const needed = Math.max(1, Math.ceil(
      (activeRooms * this.jobsPerRoom) / this.concurrency
    ));

    if (needed > this.currentWorkers) {
      const diff = needed - this.currentWorkers;
      await this.pool.scaleUp("combat-actions", diff, combatProcessor);
      console.log(`Scaled UP: ${this.currentWorkers} -> ${needed} (${activeRooms} rooms)`);
    } else if (needed < this.currentWorkers) {
      const diff = this.currentWorkers - needed;
      await this.pool.scaleDown("combat-actions", diff);
      console.log(`Scaled DOWN: ${this.currentWorkers} -> ${needed} (${activeRooms} rooms)`);
    }

    this.currentWorkers = needed;
  }

  start(): void {
    setInterval(async () => {
      const rooms = await getActiveRoomCount();
      await this.reconcile(rooms);
    }, 10_000);
  }
}

const scaler = new RoomScaler(pool);
scaler.start();
```

> **Tradeoff**: Event loop concurrency means I/O-bound jobs scale well but CPU-bound jobs need worker threads.

</tab>
</tabs>

## 24.11. Capacity Planning

### Throughput Formula

```
throughput = num_workers x concurrency / avg_job_time
```

For a Fireheadz Arena server on an 8-core machine:

| Queue | Workers | Concurrency | Avg Job Time | Theoretical Throughput |
|-------|---------|-------------|-------------|----------------------|
| `combat-actions` | 2 | 60 | 1ms (no-op) | 120,000 j/s |
| `combat-actions` | 2 | 60 | 5ms (real) | 24,000 j/s |
| `matchmaking` | 1 | 20 | 50ms | 400 j/s |
| `inventory` | 1 | 5 | 10ms | 500 j/s |
| `leaderboard` | 1 | 1 | 5ms | 200 j/s |

Actual throughput is lower due to Redis round-trip overhead (~0.1-0.5ms per operation), lock acquisition, and event emission. Expect 60-80% of theoretical maximum in production.

### Benchmarks

Measured on a single machine (8 cores, Redis local):

| Configuration | No-Op Throughput | Real Workload |
|---------------|-----------------|---------------|
| 1 worker, concurrency 1 | ~800 j/s | ~200 j/s |
| 1 worker, concurrency 60 | ~4,100 j/s | ~2,400 j/s |
| 1 worker, concurrency 500 | ~4,100 j/s | ~3,800 j/s |
| 5 workers, concurrency 500 | ~12,400 j/s | ~10,000 j/s |
| 10 workers, concurrency 500 | ~16,500 j/s | ~14,000 j/s |
| Bulk add (10K jobs) | ~30,000 j/s | N/A |

Diminishing returns above ~500 concurrency per worker because job fetching from Redis becomes the bottleneck (sequential `ZPOPMIN` / `RPOP` per job).

### Running a Throughput Benchmark

Measure your own throughput by enqueuing a batch of no-op jobs and timing how fast workers drain them.

<tabs>
<tab title="Elixir">

```elixir
defmodule Arena.Benchmark do
  def run(queue, job_count \\ 10_000) do
    # Enqueue jobs
    jobs = for i <- 1..job_count do
      {"benchmark-#{i}", %{seq: i}, []}
    end
    {:ok, _} = EchoMQ.Queue.add_bulk(queue, jobs, connection: :arena_redis)

    # Time the drain
    start = System.monotonic_time(:millisecond)
    wait_until_drained(queue, start)
  end

  defp wait_until_drained(queue, start) do
    case EchoMQ.Queue.get_job_counts(queue, connection: :arena_redis) do
      %{active: 0, waiting: 0} ->
        elapsed = System.monotonic_time(:millisecond) - start
        IO.puts("Drained in #{elapsed}ms (#{div(10_000 * 1000, elapsed)} j/s)")
      _ ->
        Process.sleep(100)
        wait_until_drained(queue, start)
    end
  end
end

# Run: Arena.Benchmark.run("combat-actions")
```

> **Benefit**: Queue draining removes waiting jobs atomically — active jobs continue to completion.

</tab>
<tab title="Go">

```go
func runBenchmark(ctx context.Context, rdb redis.Cmdable, queue string, count int) {
    q := echomq.NewQueue(queue, rdb)

    // Enqueue jobs
    for i := 0; i < count; i++ {
        q.Add(ctx, fmt.Sprintf("benchmark-%d", i),
            map[string]interface{}{"seq": i}, echomq.JobOptions{})
    }

    // Time the drain
    start := time.Now()
    for {
        active, _ := rdb.LLen(ctx, fmt.Sprintf("bull:%s:active", queue)).Result()
        waiting, _ := rdb.LLen(ctx, fmt.Sprintf("bull:%s:wait", queue)).Result()
        if active == 0 && waiting == 0 {
            elapsed := time.Since(start)
            throughput := float64(count) / elapsed.Seconds()
            log.Printf("Drained %d jobs in %v (%.0f j/s)", count, elapsed, throughput)
            return
        }
        time.Sleep(100 * time.Millisecond)
    }
}

// Run: runBenchmark(ctx, rdb, "combat-actions", 10000)
```

> **Benefit**: Drain operates via Lua scripts — atomic removal regardless of queue size.

</tab>
<tab title="Node.js">

```typescript
import { Queue } from "bullmq";

async function runBenchmark(queueName: string, count: number = 10_000) {
  const queue = new Queue(queueName, {
    connection: { host: "localhost", port: 6379 },
  });

  // Enqueue jobs
  const jobs = Array.from({ length: count }, (_, i) => ({
    name: `benchmark-${i}`,
    data: { seq: i },
  }));
  await queue.addBulk(jobs);

  // Time the drain
  const start = Date.now();
  while (true) {
    const counts = await queue.getJobCounts("active", "waiting");
    if (counts.active === 0 && counts.waiting === 0) {
      const elapsed = Date.now() - start;
      const throughput = Math.round((count / elapsed) * 1000);
      console.log(`Drained ${count} jobs in ${elapsed}ms (${throughput} j/s)`);
      break;
    }
    await new Promise((r) => setTimeout(r, 100));
  }
}

// Run: runBenchmark("combat-actions")
```

> **Benefit**: `queue.drain()` removes all waiting jobs — `queue.obliterate()` removes everything.

</tab>
</tabs>

## 24.12. Fault Tolerance and Crash Isolation

How a single job crash affects the rest of the system differs fundamentally across runtimes.

<tabs>
<tab title="Elixir">

```elixir
# Each job runs in an isolated BEAM process
# A crash in one job CANNOT affect others

# Supervision tree:
#
# Application Supervisor (one_for_one)
# +-- Arena.WorkerSupervisor (DynamicSupervisor)
# |   +-- Worker 1 (GenServer)
# |   |   +-- LockManager (linked GenServer)
# |   |   +-- Job Process A (Task.async -- isolated heap)
# |   |   +-- Job Process B (Task.async -- isolated heap)
# |   |   +-- Job Process C (Task.async -- isolated heap)
# |   +-- Worker 2 (GenServer)
# |       +-- LockManager (linked GenServer)
# |       +-- Job Process D
# |       +-- Job Process E
# +-- Arena.QueueEventsSupervisor (DynamicSupervisor)
#     +-- QueueEvents listener

# What happens when Job Process B crashes:
# 1. Job B is moved to failed (or delayed for retry)
# 2. Worker 1 receives DOWN message, cleans up slot
# 3. Worker 1 immediately fetches next job
# 4. Jobs A, C, D, E continue UNAFFECTED
# 5. No GC pause (each process has its own heap)

# What happens when Worker 1 crashes:
# 1. LockManager is terminated (linked process)
# 2. Supervisor restarts Worker 1
# 3. Active jobs A, B, C become stalled
# 4. Stalled checker recovers them within 30-60s
# 5. Worker 2 continues UNAFFECTED
```

> **Benefit**: LockManager batches all lock renewals into a single GenServer tick — O(1) timer overhead.

</tab>
<tab title="Go">

```go
// Each job runs in an isolated goroutine
// A panic in one goroutine does NOT crash others (with recover)

// Architecture:
//
// main goroutine
// +-- Worker.Start() loop
// |   +-- goroutine: processJob(jobA)  (own stack, shared heap)
// |   +-- goroutine: processJob(jobB)  (own stack, shared heap)
// |   +-- goroutine: processJob(jobC)  (own stack, shared heap)
// +-- goroutine: HeartbeatManager
// +-- goroutine: StalledChecker

// What happens when processJob(B) panics:
// 1. Without recover: entire process crashes (all goroutines die)
// 2. With recover in processJob: job B fails, others continue
// 3. Semaphore slot released via defer
// 4. WaitGroup decremented via defer
// 5. Worker continues fetching new jobs

// Graceful shutdown:
// 1. Context cancelled or shutdownChan closed
// 2. Main loop stops picking new jobs
// 3. wg.Wait() blocks until active goroutines finish
// 4. ShutdownTimeout (default 30s) prevents indefinite hang
func (w *Worker) gracefulShutdown() error {
    done := make(chan struct{})
    go func() {
        w.wg.Wait()
        close(done)
    }()
    select {
    case <-done:
        return nil
    case <-time.After(w.opts.ShutdownTimeout):
        return fmt.Errorf("shutdown timeout exceeded")
    }
}
```

> **Benefit**: Group IDs as struct fields enable type-safe group assignment at compile time.

</tab>
<tab title="Node.js">

```typescript
// All jobs share a single thread
// An unhandled exception or CPU-bound hang affects ALL jobs

// Architecture:
//
// Event Loop (single thread)
// +-- Promise: processJob(A)   -- yields on await
// +-- Promise: processJob(B)   -- yields on await
// +-- Promise: processJob(C)   -- yields on await
// +-- Timer: heartbeat renewal
// +-- Timer: stalled check

// What happens when processJob(B) throws:
// 1. Promise rejects, job B moves to failed/retry
// 2. Other promises continue (async error isolation)
// 3. Worker fetches next job

// What happens when processJob(B) enters infinite loop:
// 1. Event loop BLOCKED -- no other JS can execute
// 2. ALL other promises frozen (C, D, E...)
// 3. Heartbeat timers cannot fire
// 4. Locks expire, jobs become stalled
// 5. Only fix: kill the process (PM2 restarts it)

// Mitigation for CPU-bound work:
// Use sandboxed processor (separate child process per job)
const worker = new Worker("combat-actions", "processor.js", {
  connection: { host: "localhost", port: 6379 },
  concurrency: 60,
  useWorkerThreads: true, // Node.js worker_threads
});
```

> **Benefit**: Sandboxed processors fork a child process — complete isolation from the main event loop.

</tab>
</tabs>

### Crash Isolation Comparison

| Scenario | Elixir | Go | Node.js |
|----------|--------|-----|---------|
| One job throws exception | Job fails, others unaffected | Job fails, others unaffected | Job fails, others unaffected |
| One job infinite loop | Preempted after reduction count | Preempted (Go 1.14+) | ALL jobs blocked |
| One job OOM | Process killed, others unaffected | Entire process crashes | Entire process crashes |
| Worker process crashes | Supervisor restarts, jobs stall | Must restart manually | PM2/systemd restarts |
| GC pause | Per-process, microseconds | Stop-the-world, ~1ms | Stop-the-world, variable |

## 24.13. Environment-Based Configuration

<tabs>
<tab title="Elixir">

```elixir
# config/runtime.exs
config :arena, Arena.WorkerSupervisor,
  combat_concurrency: String.to_integer(System.get_env("COMBAT_CONCURRENCY", "60")),
  combat_workers: String.to_integer(System.get_env("COMBAT_WORKERS", "2")),
  matchmaking_concurrency: String.to_integer(System.get_env("MATCH_CONCURRENCY", "20")),
  inventory_concurrency: String.to_integer(System.get_env("INVENTORY_CONCURRENCY", "5"))

# In the supervisor
@impl true
def init(_opts) do
  config = Application.get_env(:arena, __MODULE__)
  num_combat = config[:combat_workers]
  combat_concurrency = config[:combat_concurrency]

  children = for i <- 1..num_combat do
    Supervisor.child_spec(
      {EchoMQ.Worker,
        queue: "combat-actions",
        connection: :arena_redis,
        processor: &Arena.CombatProcessor.process/1,
        concurrency: combat_concurrency},
      id: :"combat_#{i}"
    )
  end

  Supervisor.init(children, strategy: :one_for_one)
end
```

> **Benefit**: BEAM processes provide true preemptive concurrency — one slow job cannot starve others.

</tab>
<tab title="Go">

```go
func configFromEnv() map[string]int {
    return map[string]int{
        "COMBAT_CONCURRENCY":    envInt("COMBAT_CONCURRENCY", 60),
        "COMBAT_WORKERS":        envInt("COMBAT_WORKERS", 2),
        "MATCH_CONCURRENCY":     envInt("MATCH_CONCURRENCY", 20),
        "INVENTORY_CONCURRENCY": envInt("INVENTORY_CONCURRENCY", 5),
    }
}

func envInt(key string, fallback int) int {
    if v := os.Getenv(key); v != "" {
        if n, err := strconv.Atoi(v); err == nil {
            return n
        }
    }
    return fallback
}

func main() {
    cfg := configFromEnv()

    for i := 0; i < cfg["COMBAT_WORKERS"]; i++ {
        w := echomq.NewWorker("combat-actions", rdb, echomq.WorkerOptions{
            Concurrency: cfg["COMBAT_CONCURRENCY"],
        })
        w.Process(combatProcessor)
        go w.Start(ctx)
    }
}
```

> **Benefit**: Goroutine-per-job with semaphore-based limiting achieves OS-level parallelism.

</tab>
<tab title="Node.js">

```typescript
const config = {
  combatConcurrency: parseInt(process.env.COMBAT_CONCURRENCY || "60"),
  combatWorkers: parseInt(process.env.COMBAT_WORKERS || "2"),
  matchConcurrency: parseInt(process.env.MATCH_CONCURRENCY || "20"),
  inventoryConcurrency: parseInt(process.env.INVENTORY_CONCURRENCY || "5"),
};

for (let i = 0; i < config.combatWorkers; i++) {
  new Worker("combat-actions", combatProcessor, {
    connection: { host: "localhost", port: 6379 },
    concurrency: config.combatConcurrency,
  });
}

new Worker("matchmaking", matchmakingProcessor, {
  connection: { host: "localhost", port: 6379 },
  concurrency: config.matchConcurrency,
});
```

> **Tradeoff**: Event loop concurrency means I/O-bound jobs scale well but CPU-bound jobs need worker threads.

</tab>
</tabs>

## 24.14. Optimization Guidelines

### Workers per Machine

| Job Type | Workers per Machine | Why |
|----------|-------------------|-----|
| I/O-bound (Redis, HTTP, DB) | `CPU cores x 2` | Overlap network wait time |
| CPU-bound (damage calc, physics) | `CPU cores x 1` | Avoid context switch overhead |
| Mixed workload | `CPU cores x 1.5` | Balance between I/O wait and CPU |
| Memory-heavy (world sync, navmesh) | `available_RAM / per_job_RAM` | Prevent OOM |

### Concurrency per Worker

| Range | Use Case |
|-------|----------|
| 1 | Strict ordering (leaderboard aggregation) |
| 5-10 | Database-write-heavy (inventory trades, match connection pool) |
| 20-50 | Standard I/O-bound (matchmaking, analytics) |
| 60-200 | High-throughput I/O (combat actions, player events) |
| 200-500 | Maximum throughput (fire-and-forget analytics, logging) |
| 500+ | Diminishing returns -- Redis fetch becomes bottleneck |

### Memory Estimation

```
total_memory = base_process + (num_workers x worker_overhead) + (total_concurrency x avg_job_memory)
```

| Runtime | Base Process | Worker Overhead | Per-Job Overhead |
|---------|-------------|----------------|-----------------|
| Elixir | ~40MB (BEAM VM) | ~100KB | ~2KB (BEAM process) |
| Go | ~10MB (runtime) | ~100KB | ~8KB (goroutine stack) |
| Node.js | ~30-50MB (V8) | N/A (single process) | ~1KB (promise state) |

For a combat worker with concurrency 60:
- **Elixir**: 40MB + 100KB + (60 x 2KB) = ~40.2MB
- **Go**: 10MB + 100KB + (60 x 8KB) = ~10.6MB
- **Node.js**: 40MB + (60 x 1KB) = ~40.1MB

## 24.15. Runtime Comparison Summary

| Aspect | Elixir (BEAM) | Go | Node.js |
|--------|--------------|-----|---------|
| **Concurrency mechanism** | BEAM processes (lightweight) | Goroutines (M:N scheduled) | Async promises (single thread) |
| **True parallelism** | Yes (1 scheduler per core) | Yes (GOMAXPROCS threads) | No (requires cluster/PM2) |
| **Process per core needed** | No | No | Yes |
| **Memory per concurrent job** | ~2KB | ~8KB | ~1KB |
| **Max concurrent jobs/machine** | Thousands | Thousands | Hundreds (per process) |
| **Crash isolation** | Per job (process boundary) | Per job (with recover) | Per job (promise reject only) |
| **CPU-bound job impact** | None (preemptive) | Minimal (preempted) | Blocks all jobs |
| **GC model** | Per-process (no global pauses) | Stop-the-world (~1ms) | Stop-the-world (variable) |
| **Multi-core usage** | Automatic | Automatic | Manual (cluster/PM2) |
| **Scaling complexity** | Low (just add workers) | Low (just add goroutines) | Higher (process management) |
| **Inter-worker communication** | Direct message passing | Channels / shared memory | IPC / Redis |
| **Dynamic scaling** | DynamicSupervisor | Context cancellation | Worker.close() |
| **Best for game servers** | Massive I/O + fault tolerance | High throughput + low memory | Rapid prototyping + ecosystem |

---

*Previous: [Custom Events](ch23-custom-events.md) | Next: [Rate Limiting](ch25-rate-limiting.md)*
