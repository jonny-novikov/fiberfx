# Chapter 32. Supervision Patterns

> How different languages handle worker supervision and fault tolerance in EchoMQ.

## 32.1. Overview

Every EchoMQ worker must answer two fundamental questions: **what happens when a worker crashes?** and **who is responsible for restarting it?** Each language ecosystem answers these differently based on its concurrency model and runtime capabilities.

Elixir leans on OTP's battle-tested supervision trees. Go uses structured concurrency via `context` and `errgroup`. Node.js relies on the event loop's single-threaded model with process-level supervision through cluster mode or external managers.

Despite these differences, the **goals are universal**: detect failures, recover gracefully, prevent cascading crashes, and maintain job processing availability. This chapter walks through supervision patterns for each language, grounded in the actual EchoMQ implementations.

## 32.2. Worker Lifecycle

Every EchoMQ worker follows the same high-level lifecycle, regardless of language:

```
                          WORKER LIFECYCLE
 ┌──────────────────────────────────────────────────────────┐
 │                                                          │
 │   Initialize                                             │
 │       │                                                  │
 │       ▼                                                  │
 │   Connect to Redis ──────────────────────────┐           │
 │       │                                      │ failure   │
 │       ▼                                      ▼           │
 │   Start Background Services            Retry / Crash     │
 │   ├── Lock Manager (heartbeat)               │           │
 │   ├── Stalled Checker                        │           │
 │   └── Event Emitter                     ┌────┘           │
 │       │                                 │                │
 │       ▼                                 │                │
 │   ┌──────────────┐                      │                │
 │   │  Fetch Jobs   │◀───────── Retry ────┘                │
 │   │  (main loop)  │                                      │
 │   └──────┬────────┘                                      │
 │          │                                               │
 │          ▼                                               │
 │   Process Job(s) ─── concurrent slots ──┐                │
 │          │                               │               │
 │          ▼                               ▼               │
 │   Complete / Fail / Retry          Lock Renewal          │
 │          │                          (periodic)           │
 │          ▼                                               │
 │   SIGTERM / close() ──▶ Graceful Shutdown                │
 │                         ├── Stop fetching                │
 │                         ├── Wait for active jobs         │
 │                         └── Clean up connections         │
 └──────────────────────────────────────────────────────────┘
```

The key difference is **who watches the watcher**. Here is how each language implements the initialization and background service startup:

<tabs>
<tab title="Elixir">

> **Benefit**: OTP manages GenServer lifecycle -- non-blocking `init` via self-send pattern ensures the supervisor never blocks.

```elixir
# EchoMQ.Worker is a GenServer — OTP manages lifecycle automatically
defmodule Codemoji.GameRoom.Worker do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: opts[:name])
  end

  @impl true
  def init(opts) do
    # Trap exits so supervisor can shut us down gracefully
    Process.flag(:trap_exit, true)

    state = %{
      queue_name: opts[:queue],
      connection: opts[:connection],
      running: false,
      active_jobs: %{},
      lock_manager: nil
    }

    # Send ourselves a :start message (non-blocking init)
    send(self(), :start)
    {:ok, state}
  end

  @impl true
  def handle_info(:start, state) do
    # Start lock manager — linked process, crashes propagate
    {:ok, lock_manager} = EchoMQ.LockManager.start_link(
      connection: state.connection,
      keys: EchoMQ.Keys.new(state.queue_name)
    )
    Process.link(lock_manager)

    send(self(), :fetch_jobs)
    {:noreply, %{state | running: true, lock_manager: lock_manager}}
  end
end
```

</tab>
<tab title="Go">

> **Benefit**: Context-based cancellation -- caller controls worker lifetime explicitly via `ctx`.

```go
// Worker.Start uses context.Context for cancellation — caller manages lifecycle
func startGameRoomWorker(ctx context.Context, rdb redis.Cmdable) error {
    worker := echomq.NewWorker("guess-processing", rdb, echomq.WorkerOptions{
        Concurrency:          10,
        LockDuration:         30 * time.Second,
        HeartbeatInterval:    15 * time.Second,
        StalledCheckInterval: 30 * time.Second,
        ShutdownTimeout:      30 * time.Second,
    })

    worker.Process(func(job *echomq.Job) (interface{}, error) {
        return processGuess(job)
    })

    // Start blocks until ctx is cancelled — spawns heartbeat + stalled checker
    // internally via goroutines. Caller is responsible for context lifecycle.
    return worker.Start(ctx)
}
```

</tab>
<tab title="Node.js">

> **Tradeoff**: Auto-start simplifies setup but error handling is purely event-driven -- no crash propagation.

```typescript
// Worker auto-starts on construction (autorun: true by default)
// The event loop IS the supervisor — no external watcher needed
import { Worker } from 'echomq';

const worker = new Worker(
  'guess-processing',
  async (job) => {
    return processGuess(job.data);
  },
  {
    connection: { host: 'localhost', port: 6379 },
    concurrency: 10,
    lockDuration: 30000,
    stalledInterval: 30000,
    autorun: true, // starts processing immediately
  }
);

// Event-driven error handling (no crash — just emit)
worker.on('error', (err) => {
  console.error('[GameRoom] Worker error:', err.message);
});

worker.on('failed', (job, err) => {
  console.error(`[GameRoom] Job ${job?.id} failed:`, err.message);
});
```

</tab>
</tabs>

## 32.3. Basic Supervision

The fundamental pattern: **something watches the worker and restarts it on failure**. Each language has a radically different approach to this.

<tabs>
<tab title="Elixir">

> **Benefit**: Declarative child specs -- supervisor handles all restart logic automatically with zero boilerplate.

```elixir
# OTP Supervisor: declarative child specs, automatic restarts
defmodule Codemoji.GameRoom.Supervisor do
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      # Redis connection (shared by workers)
      {EchoMQ.RedisConnection,
        name: :game_redis,
        url: System.get_env("REDIS_URL", "redis://localhost:6379")},

      # Guess processing worker
      {EchoMQ.Worker,
        name: :guess_worker,
        queue: "guess-processing",
        connection: :game_redis,
        processor: &Codemoji.Guess.Processor.process/1,
        concurrency: 10},

      # Prize distribution worker
      {EchoMQ.Worker,
        name: :prize_worker,
        queue: "prize-distribution",
        connection: :game_redis,
        processor: &Codemoji.Prize.Processor.process/1,
        concurrency: 5}
    ]

    # :one_for_one — each child restarts independently
    Supervisor.init(children, strategy: :one_for_one)
  end
end
```

</tab>
<tab title="Go">

> **Benefit**: `errgroup` provides structured concurrency -- any error cancels the group via shared context.

```go
// errgroup provides structured concurrency with error propagation
func runGameRoomWorkers(ctx context.Context, rdb redis.Cmdable) error {
    g, ctx := errgroup.WithContext(ctx)

    // Guess processing worker
    g.Go(func() error {
        worker := echomq.NewWorker("guess-processing", rdb, echomq.WorkerOptions{
            Concurrency: 10,
        })
        worker.Process(processGuess)
        return worker.Start(ctx) // blocks until context cancelled
    })

    // Prize distribution worker
    g.Go(func() error {
        worker := echomq.NewWorker("prize-distribution", rdb, echomq.WorkerOptions{
            Concurrency: 5,
        })
        worker.Process(distributePrizes)
        return worker.Start(ctx)
    })

    // If ANY worker returns an error, ctx is cancelled for all
    return g.Wait()
}
```

</tab>
<tab title="Node.js">

> **Tradeoff**: No built-in supervisor -- restart logic must be implemented manually via event handlers.

```typescript
// Node.js: process-level supervision via cluster or PM2
// Within a single process, workers are event emitters — they don't "crash"
import { Worker } from 'echomq';

class GameRoomSupervisor {
  private workers: Map<string, Worker> = new Map();

  start() {
    this.startWorker('guess-processing', processGuess, 10);
    this.startWorker('prize-distribution', distributePrizes, 5);
  }

  private startWorker(
    queue: string,
    processor: (job: any) => Promise<any>,
    concurrency: number
  ) {
    const worker = new Worker(queue, processor, {
      connection: { host: 'localhost', port: 6379 },
      concurrency,
    });

    worker.on('error', (err) => {
      console.error(`[${queue}] error:`, err.message);
    });

    // Node.js workers don't crash the process — errors are events
    // For process-level restarts, use PM2 or cluster module
    worker.on('closed', () => {
      console.log(`[${queue}] worker closed, restarting...`);
      setTimeout(() => this.startWorker(queue, processor, concurrency), 1000);
    });

    this.workers.set(queue, worker);
  }

  async stop() {
    await Promise.all(
      Array.from(this.workers.values()).map((w) => w.close())
    );
  }
}
```

</tab>
</tabs>

## 32.4. Restart Strategies

When a failure occurs, the **scope of the restart** matters. Should only the failed component restart, or should related components restart together?

<tabs>
<tab title="Elixir">

> **Benefit**: Three built-in strategies (`:one_for_one`, `:rest_for_one`, `:one_for_all`) with `max_restarts` rate limiting.

```elixir
# Strategy 1: :one_for_one — independent workers
# If guess_worker crashes, prize_worker keeps running
Supervisor.init(children, strategy: :one_for_one)

# Strategy 2: :rest_for_one — ordered dependencies
# If Redis dies, ALL workers after it restart
children = [
  {EchoMQ.RedisConnection, name: :game_redis, url: url},  # 1st
  {EchoMQ.Worker, name: :guess_worker, connection: :game_redis, ...},  # 2nd
  {EchoMQ.Worker, name: :prize_worker, connection: :game_redis, ...},  # 3rd
  {EchoMQ.QueueEvents, name: :game_events, connection: :game_redis, ...}  # 4th
]
# Redis crash → workers + events restart. Worker crash → only later children restart.
Supervisor.init(children, strategy: :rest_for_one)

# Strategy 3: :one_for_all — tightly coupled group
# If ANY process dies, ALL restart (e.g., coordinator + processor pair)
children = [
  {EchoMQ.Worker, name: :coordinator, queue: "game-main", ...},
  {EchoMQ.Worker, name: :processor, queue: "game-work", ...}
]
Supervisor.init(children, strategy: :one_for_all)

# Rate limit restarts to prevent crash loops
Supervisor.init(children,
  strategy: :one_for_one,
  max_restarts: 5,      # max 5 restarts...
  max_seconds: 60       # ...within 60 seconds, then supervisor crashes up
)
```

</tab>
<tab title="Go">

> **Tradeoff**: No built-in restart strategies -- must implement restart loops and dependency chains manually.

```go
// Go errgroup: "one_for_all" semantics — any error cancels the group
func runWithRestartStrategy(ctx context.Context, rdb redis.Cmdable) error {
    // Strategy 1: Independent workers (manual restart loop)
    // Each worker runs in its own goroutine with independent restart logic
    go func() {
        for {
            select {
            case <-ctx.Done():
                return
            default:
                err := runGuessWorker(ctx, rdb)
                if err != nil {
                    log.Printf("guess worker failed: %v, restarting...", err)
                    time.Sleep(time.Second) // backoff before restart
                }
            }
        }
    }()

    // Strategy 2: Coordinated group (errgroup = one_for_all)
    // If any worker fails, context is cancelled for all
    g, gCtx := errgroup.WithContext(ctx)
    g.Go(func() error { return runPrizeWorker(gCtx, rdb) })
    g.Go(func() error { return runSessionWorker(gCtx, rdb) })
    return g.Wait() // blocks until all finish or one errors

    // Strategy 3: rest_for_one via dependency chain
    // Start Redis watcher first, workers depend on it
    // redisCtx, cancelRedis := context.WithCancel(ctx)
    // workerCtx, cancelWorkers := context.WithCancel(redisCtx)
    // If Redis watcher errors → cancelRedis() → cancels workerCtx too
}
```

</tab>
<tab title="Node.js">

> **Tradeoff**: Process-level supervision via `cluster` module -- no per-worker restart strategy within a process.

```typescript
// Node.js cluster module: OS-level process supervision
import cluster from 'node:cluster';
import { availableParallelism } from 'node:os';

if (cluster.isPrimary) {
  const numWorkers = availableParallelism();

  // Fork worker processes
  for (let i = 0; i < numWorkers; i++) {
    cluster.fork();
  }

  // Restart strategy: restart crashed workers (one_for_one equivalent)
  let restartCount = 0;
  const MAX_RESTARTS = 5;
  const RESTART_WINDOW = 60_000;
  let windowStart = Date.now();

  cluster.on('exit', (worker, code, signal) => {
    console.log(`Worker ${worker.process.pid} died (${signal || code})`);

    // Rate-limit restarts
    const now = Date.now();
    if (now - windowStart > RESTART_WINDOW) {
      restartCount = 0;
      windowStart = now;
    }

    if (restartCount < MAX_RESTARTS) {
      restartCount++;
      console.log('Restarting worker...');
      cluster.fork();
    } else {
      console.error('Too many restarts, stopping.');
    }
  });
} else {
  // Each forked process runs its own EchoMQ worker
  const worker = new Worker('guess-processing', processGuess, {
    connection: { host: 'localhost', port: 6379 },
    concurrency: 10,
  });
}
```

</tab>
</tabs>

## 32.5. Linked Process Failures

EchoMQ workers depend on auxiliary processes: the **LockManager** renews job locks, and the **StalledChecker** recovers abandoned jobs. When these fail, the worker must respond appropriately.

```
     ┌──────────────────────────────────────────────────┐
     │                LINKED FAILURES                    │
     │                                                   │
     │  Worker ◀──────── link ────────▶ LockManager     │
     │    │                                  │           │
     │    │ LockManager crash                │           │
     │    │ ─────────────────────────▶ EXIT signal       │
     │    │                                              │
     │    ▼                                              │
     │  Worker crashes (intentional!)                    │
     │    │                                              │
     │    ▼                                              │
     │  Supervisor restarts Worker                       │
     │    │                                              │
     │    ▼                                              │
     │  Worker spawns NEW LockManager                    │
     │                                                   │
     │  WHY: Silent lock renewal failure = data loss.    │
     │  Jobs would stall without the worker knowing.     │
     └──────────────────────────────────────────────────┘
```

<tabs>
<tab title="Elixir">

> **Benefit**: Process linking propagates failures explicitly -- silent lock renewal loss is impossible.

```elixir
# Worker traps exits and handles LockManager crashes explicitly
# From EchoMQ.Worker — linked process crash handling

@impl true
def handle_info(:start, state) do
  # Start lock manager and LINK it to this process
  {:ok, lock_manager} = EchoMQ.LockManager.start_link(
    connection: state.connection,
    keys: state.keys,
    lock_duration: state.lock_duration
  )
  # Explicit link: if LockManager crashes, Worker gets EXIT signal
  Process.link(lock_manager)

  {:noreply, %{state | lock_manager: lock_manager}}
end

# Normal exit — LockManager stopped gracefully (e.g., during shutdown)
def handle_info({:EXIT, pid, :normal}, state) when pid == state.lock_manager do
  {:noreply, %{state | lock_manager: nil}}
end

# Abnormal exit — LockManager crashed! Crash the worker too.
# The supervisor will restart both.
def handle_info({:EXIT, pid, reason}, state) when pid == state.lock_manager do
  Logger.error("[Worker] LockManager crashed: #{inspect(reason)}")
  {:stop, {:lock_manager_crashed, reason}, state}
end
```

</tab>
<tab title="Go">

> **Tradeoff**: No process linking -- heartbeat failures are logged but do not crash the worker.

```go
// Go: HeartbeatManager is a struct, not a goroutine — lifecycle is explicit
// Worker owns HeartbeatManager and StalledChecker directly
type Worker struct {
    heartbeatManager *HeartbeatManager
    stalledChecker   *StalledChecker
    shutdownChan     chan struct{}
    wg               sync.WaitGroup
}

func (w *Worker) Start(ctx context.Context) error {
    // Start background services — goroutines, not separate processes
    w.heartbeatManager = NewHeartbeatManager(w)
    w.stalledChecker = NewStalledChecker(w)
    go w.stalledChecker.Start(ctx) // runs in background goroutine

    // Main job loop
    for {
        select {
        case <-ctx.Done():
            return w.gracefulShutdown()
        default:
            if err := w.pickupJob(ctx); err != nil {
                // Heartbeat failures are logged but don't crash the worker.
                // If lock renewal fails, the stalled checker will recover the job.
                time.Sleep(time.Second)
            }
        }
    }
}

// Per-job heartbeat — linked to job lifecycle via context cancellation
func (hm *HeartbeatManager) StartHeartbeat(ctx context.Context, jobID string, token LockToken) {
    heartbeatCtx, cancel := context.WithCancel(ctx)
    hm.activeLocks[jobID] = cancel

    go hm.heartbeatLoop(heartbeatCtx, jobID, token)
}

// If lock is stolen, heartbeat stops — no process crash needed
func (hm *HeartbeatManager) heartbeatLoop(ctx context.Context, jobID string, token LockToken) {
    ticker := time.NewTicker(hm.worker.opts.HeartbeatInterval)
    defer ticker.Stop()

    for {
        select {
        case <-ctx.Done():
            return
        case <-ticker.C:
            result, err := extendLockScript.Run(ctx, /* ... */).Int64()
            if result == 0 {
                // Lock stolen — stop heartbeat, stalled checker handles recovery
                return
            }
        }
    }
}
```

</tab>
<tab title="Node.js">

> **Tradeoff**: Event-based error reporting -- lock failures emit events instead of crashing the worker.

```typescript
// Node.js: LockManager is an object, not a separate process
// Failures are emitted as events, not process crashes
class LockManager {
  private lockRenewalTimer?: NodeJS.Timeout;
  private trackedJobs = new Map<string, { token: string; ts: number }>();

  private startLockExtenderTimer(): void {
    this.lockRenewalTimer = setTimeout(async () => {
      const now = Date.now();
      const jobsToExtend: string[] = [];

      for (const [jobId, tracked] of this.trackedJobs) {
        if (tracked.ts + this.opts.lockRenewTime / 2 < now) {
          this.trackedJobs.set(jobId, { ...tracked, ts: now });
          jobsToExtend.push(jobId);
        }
      }

      if (jobsToExtend.length) {
        await this.extendLocks(jobsToExtend);
      }

      this.startLockExtenderTimer(); // reschedule
    }, this.opts.lockRenewTime / 2);
  }

  private async extendLocks(jobIds: string[]): Promise<void> {
    try {
      const tokens = jobIds.map(id => this.trackedJobs.get(id)?.token);
      const erroredJobIds = await this.worker.extendJobLocks(
        jobIds, tokens, this.opts.lockDuration
      );

      if (erroredJobIds.length > 0) {
        // Emit event — does NOT crash the worker
        this.worker.emit('lockRenewalFailed', erroredJobIds);
        for (const jobId of erroredJobIds) {
          this.worker.emit('error',
            new Error(`could not renew lock for job ${jobId}`)
          );
        }
      }
    } catch (err) {
      // Errors are events, not crashes
      this.worker.emit('error', err as Error);
    }
  }
}
```

</tab>
</tabs>

## 32.6. Dynamic Worker Creation

Static supervision works for fixed queue configurations, but games need to spin up workers on demand -- for example, one worker per active game room.

<tabs>
<tab title="Elixir">

> **Benefit**: DynamicSupervisor provides supervised runtime worker creation with automatic restart and cleanup.

```elixir
# DynamicSupervisor: spawn workers at runtime, supervised automatically
defmodule Codemoji.Room.WorkerSupervisor do
  use DynamicSupervisor

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @doc "Start a worker for a specific game room"
  def start_room_worker(room_id) do
    spec = {EchoMQ.Worker,
      name: :"room_worker_#{room_id}",
      queue: "room-#{room_id}-guesses",
      connection: :game_redis,
      processor: &Codemoji.Room.Processor.process/1,
      concurrency: 5
    }

    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  @doc "Stop a room worker when the game ends"
  def stop_room_worker(room_id) do
    case Process.whereis(:"room_worker_#{room_id}") do
      nil -> {:error, :not_found}
      pid -> DynamicSupervisor.terminate_child(__MODULE__, pid)
    end
  end

  @doc "List all active room workers"
  def active_rooms do
    DynamicSupervisor.which_children(__MODULE__)
    |> Enum.map(fn {_, pid, _, _} -> pid end)
    |> Enum.filter(&is_pid/1)
  end
end
```

</tab>
<tab title="Go">

> **Tradeoff**: Manual goroutine pool with `sync.RWMutex` -- no automatic restart on individual worker failure.

```go
// WorkerPool: dynamic goroutine-based worker management
type RoomWorkerPool struct {
    mu       sync.RWMutex
    workers  map[string]context.CancelFunc
    rdb      redis.Cmdable
    wg       sync.WaitGroup
}

func NewRoomWorkerPool(rdb redis.Cmdable) *RoomWorkerPool {
    return &RoomWorkerPool{
        workers: make(map[string]context.CancelFunc),
        rdb:     rdb,
    }
}

// StartRoomWorker spawns a worker for a specific game room
func (p *RoomWorkerPool) StartRoomWorker(parentCtx context.Context, roomID string) error {
    p.mu.Lock()
    defer p.mu.Unlock()

    if _, exists := p.workers[roomID]; exists {
        return fmt.Errorf("worker for room %s already running", roomID)
    }

    ctx, cancel := context.WithCancel(parentCtx)
    p.workers[roomID] = cancel

    worker := echomq.NewWorker(
        fmt.Sprintf("room-%s-guesses", roomID),
        p.rdb,
        echomq.WorkerOptions{Concurrency: 5},
    )
    worker.Process(func(job *echomq.Job) (interface{}, error) {
        return processRoomGuess(roomID, job)
    })

    p.wg.Add(1)
    go func() {
        defer p.wg.Done()
        defer p.StopRoomWorker(roomID)
        if err := worker.Start(ctx); err != nil {
            log.Printf("room %s worker error: %v", roomID, err)
        }
    }()

    return nil
}

// StopRoomWorker cancels a specific room worker
func (p *RoomWorkerPool) StopRoomWorker(roomID string) {
    p.mu.Lock()
    defer p.mu.Unlock()

    if cancel, ok := p.workers[roomID]; ok {
        cancel()
        delete(p.workers, roomID)
    }
}

// StopAll waits for all workers to finish
func (p *RoomWorkerPool) StopAll() {
    p.mu.RLock()
    for _, cancel := range p.workers {
        cancel()
    }
    p.mu.RUnlock()
    p.wg.Wait()
}
```

</tab>
<tab title="Node.js">

> **Tradeoff**: Map-based tracking with manual cleanup -- no supervisor integration for automatic restarts.

```typescript
// Dynamic worker pool with Map-based tracking
class RoomWorkerPool {
  private workers = new Map<string, Worker>();
  private connection: ConnectionOptions;

  constructor(connection: ConnectionOptions) {
    this.connection = connection;
  }

  startRoomWorker(roomId: string): void {
    if (this.workers.has(roomId)) {
      throw new Error(`Worker for room ${roomId} already running`);
    }

    const worker = new Worker(
      `room-${roomId}-guesses`,
      async (job) => processRoomGuess(roomId, job),
      { connection: this.connection, concurrency: 5 }
    );

    worker.on('error', (err) => {
      console.error(`[Room ${roomId}] worker error:`, err.message);
    });

    // Auto-cleanup when worker closes
    worker.on('closed', () => {
      this.workers.delete(roomId);
    });

    this.workers.set(roomId, worker);
  }

  async stopRoomWorker(roomId: string): Promise<void> {
    const worker = this.workers.get(roomId);
    if (worker) {
      await worker.close();
      this.workers.delete(roomId);
    }
  }

  activeRooms(): string[] {
    return Array.from(this.workers.keys());
  }

  async stopAll(): Promise<void> {
    await Promise.all(
      Array.from(this.workers.values()).map((w) => w.close())
    );
    this.workers.clear();
  }
}
```

</tab>
</tabs>

## 32.7. Multi-Queue Architecture

Production applications typically process multiple queues with different priorities and concurrency settings. The supervision structure must reflect these relationships.

```
         ┌──────────────────────────────────────────────────┐
         │            CODEMOJI QUEUE ARCHITECTURE            │
         │                                                   │
         │  Application Supervisor                           │
         │  ├── Redis Connection (shared)                    │
         │  ├── Game Queue Supervisor                        │
         │  │   ├── guess-processing (concurrency: 20)       │
         │  │   ├── prize-distribution (concurrency: 10)     │
         │  │   └── room-events (concurrency: 5)             │
         │  ├── Player Queue Supervisor                      │
         │  │   ├── session-monitoring (concurrency: 5)      │
         │  │   └── leaderboard-updates (concurrency: 3)     │
         │  └── Admin Queue Supervisor                       │
         │      ├── analytics (concurrency: 2, rate-limited) │
         │      └── notifications (concurrency: 10)          │
         └──────────────────────────────────────────────────┘
```

<tabs>
<tab title="Elixir">

> **Benefit**: Nested supervision trees mirror the architecture -- each queue group fails independently.

```elixir
# Nested supervision tree mirrors the architecture diagram
defmodule Codemoji.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Shared Redis (if this dies, everything restarts)
      {EchoMQ.RedisConnection,
        name: :game_redis,
        url: System.get_env("REDIS_URL")},

      # Game queues — independent supervisor
      {Codemoji.Game.QueueSupervisor, []},

      # Player queues — independent supervisor
      {Codemoji.Player.QueueSupervisor, []},

      # Admin queues — independent supervisor
      {Codemoji.Admin.QueueSupervisor, []}
    ]

    # rest_for_one: Redis crash restarts all queue supervisors
    Supervisor.start_link(children,
      strategy: :rest_for_one,
      name: Codemoji.Supervisor
    )
  end
end

defmodule Codemoji.Game.QueueSupervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      {EchoMQ.Worker,
        name: :guess_worker,
        queue: "guess-processing",
        connection: :game_redis,
        processor: &Codemoji.Guess.Processor.process/1,
        concurrency: 20},

      {EchoMQ.Worker,
        name: :prize_worker,
        queue: "prize-distribution",
        connection: :game_redis,
        processor: &Codemoji.Prize.Processor.process/1,
        concurrency: 10},

      {EchoMQ.Worker,
        name: :room_events_worker,
        queue: "room-events",
        connection: :game_redis,
        processor: &Codemoji.Room.Events.process/1,
        concurrency: 5}
    ]

    # Workers are independent within this group
    Supervisor.init(children, strategy: :one_for_one)
  end
end
```

</tab>
<tab title="Go">

> **Benefit**: Nested errgroups compose naturally -- one group per queue category with shared context propagation.

```go
// Multi-queue via goroutine groups with shared context
func runCodemoji(ctx context.Context, rdb redis.Cmdable) error {
    g, ctx := errgroup.WithContext(ctx)

    // Game queue group
    g.Go(func() error { return runGameQueues(ctx, rdb) })

    // Player queue group
    g.Go(func() error { return runPlayerQueues(ctx, rdb) })

    // Admin queue group
    g.Go(func() error { return runAdminQueues(ctx, rdb) })

    return g.Wait()
}

func runGameQueues(ctx context.Context, rdb redis.Cmdable) error {
    g, ctx := errgroup.WithContext(ctx)

    g.Go(func() error {
        w := echomq.NewWorker("guess-processing", rdb,
            echomq.WorkerOptions{Concurrency: 20})
        w.Process(processGuess)
        return w.Start(ctx)
    })

    g.Go(func() error {
        w := echomq.NewWorker("prize-distribution", rdb,
            echomq.WorkerOptions{Concurrency: 10})
        w.Process(distributePrizes)
        return w.Start(ctx)
    })

    g.Go(func() error {
        w := echomq.NewWorker("room-events", rdb,
            echomq.WorkerOptions{Concurrency: 5})
        w.Process(processRoomEvents)
        return w.Start(ctx)
    })

    return g.Wait()
}

func runAdminQueues(ctx context.Context, rdb redis.Cmdable) error {
    g, ctx := errgroup.WithContext(ctx)

    g.Go(func() error {
        w := echomq.NewWorker("analytics", rdb, echomq.WorkerOptions{
            Concurrency: 2,
            Limiter: &echomq.LimiterConfig{Max: 100, Duration: time.Minute},
        })
        w.Process(processAnalytics)
        return w.Start(ctx)
    })

    g.Go(func() error {
        w := echomq.NewWorker("notifications", rdb,
            echomq.WorkerOptions{Concurrency: 10})
        w.Process(sendNotifications)
        return w.Start(ctx)
    })

    return g.Wait()
}
```

</tab>
<tab title="Node.js">

> **Tradeoff**: Flat class-based organization -- no hierarchical failure isolation between queue groups.

```typescript
// Multi-queue with class-based organization
class CodemojiBroker {
  private workers: Worker[] = [];
  private connection: ConnectionOptions;

  constructor(connection: ConnectionOptions) {
    this.connection = connection;
  }

  start() {
    // Game queues
    this.addWorker('guess-processing', processGuess, { concurrency: 20 });
    this.addWorker('prize-distribution', distributePrizes, { concurrency: 10 });
    this.addWorker('room-events', processRoomEvents, { concurrency: 5 });

    // Player queues
    this.addWorker('session-monitoring', monitorSession, { concurrency: 5 });
    this.addWorker('leaderboard-updates', updateLeaderboard, { concurrency: 3 });

    // Admin queues (rate-limited analytics)
    this.addWorker('analytics', processAnalytics, {
      concurrency: 2,
      limiter: { max: 100, duration: 60_000 },
    });
    this.addWorker('notifications', sendNotifications, { concurrency: 10 });
  }

  private addWorker(
    queue: string,
    processor: (job: any) => Promise<any>,
    opts: Partial<WorkerOptions> = {}
  ) {
    const worker = new Worker(queue, processor, {
      connection: this.connection,
      ...opts,
    });

    worker.on('error', (err) =>
      console.error(`[${queue}] error:`, err.message)
    );
    worker.on('failed', (job, err) =>
      console.error(`[${queue}] job ${job?.id} failed:`, err.message)
    );

    this.workers.push(worker);
  }

  async stop() {
    await Promise.all(this.workers.map((w) => w.close()));
    this.workers = [];
  }
}

// Usage
const broker = new CodemojiBroker({ host: 'localhost', port: 6379 });
broker.start();

// Graceful shutdown
process.on('SIGTERM', async () => {
  await broker.stop();
  process.exit(0);
});
```

</tab>
</tabs>

## 32.8. Graceful Shutdown

When a shutdown signal arrives, workers must finish active jobs before exiting. Abandoned active jobs become stalled and must be recovered by other workers.

<tabs>
<tab title="Elixir">

> **Benefit**: OTP handles shutdown ordering automatically via supervision tree teardown and `terminate/2` callbacks.

```elixir
# OTP handles shutdown ordering automatically via supervision tree
# Workers that trap exits get terminate/2 called

defmodule Codemoji.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {EchoMQ.RedisConnection, name: :game_redis, url: redis_url()},
      {EchoMQ.Worker, name: :guess_worker, queue: "guess-processing",
        connection: :game_redis, processor: &process_guess/1}
    ]

    Supervisor.start_link(children, strategy: :rest_for_one)
  end

  @impl true
  def prep_stop(_state) do
    # Called BEFORE supervisor shuts down children
    # Close workers gracefully with timeout
    EchoMQ.Worker.close(:guess_worker, timeout: 25_000)
    :ok
  end
end

# Inside the worker — terminate/2 is called by OTP
defmodule EchoMQ.Worker do
  @impl true
  def terminate(_reason, state) do
    # Stop lock manager
    if state.lock_manager, do: EchoMQ.LockManager.stop(state.lock_manager)

    # Cancel stalled checker timer
    if state.stalled_timer, do: Process.cancel_timer(state.stalled_timer)

    # Close blocking Redis connection
    if state.blocking_conn do
      EchoMQ.RedisConnection.close_blocking(state.connection, state.blocking_conn)
    end

    :ok
  end
end
```

</tab>
<tab title="Go">

> **Benefit**: Context cancellation propagates shutdown signal to all goroutines; `sync.WaitGroup` ensures completion.

```go
// context.Context propagates cancellation; sync.WaitGroup waits for completion
func main() {
    ctx, cancel := context.WithCancel(context.Background())

    // Trap SIGTERM/SIGINT
    sigChan := make(chan os.Signal, 1)
    signal.Notify(sigChan, syscall.SIGTERM, syscall.SIGINT)

    go func() {
        <-sigChan
        log.Println("Shutdown signal received, stopping workers...")
        cancel() // triggers ctx.Done() in all workers
    }()

    rdb := redis.NewClient(&redis.Options{Addr: "localhost:6379"})
    if err := runCodemoji(ctx, rdb); err != nil {
        log.Fatalf("workers exited with error: %v", err)
    }
}

// Inside Worker.gracefulShutdown:
func (w *Worker) gracefulShutdown() error {
    // Wait for all active job goroutines to finish
    done := make(chan struct{})
    go func() {
        w.wg.Wait() // sync.WaitGroup tracks active jobs
        close(done)
    }()

    select {
    case <-done:
        return nil // all jobs finished
    case <-time.After(w.opts.ShutdownTimeout):
        return fmt.Errorf("shutdown timeout exceeded after %v", w.opts.ShutdownTimeout)
    }
}
```

</tab>
<tab title="Node.js">

> **Tradeoff**: Manual signal handling with timeout -- must coordinate `Worker.close()` sequence explicitly.

```typescript
// Process signal handlers + Worker.close() with timeout

const workers: Worker[] = [];

// Create workers
workers.push(
  new Worker('guess-processing', processGuess, {
    connection: { host: 'localhost', port: 6379 },
    concurrency: 10,
  })
);

// Graceful shutdown handler
async function shutdown(signal: string) {
  console.log(`${signal} received, shutting down gracefully...`);

  // Close all workers with timeout
  const shutdownTimeout = setTimeout(() => {
    console.error('Shutdown timeout exceeded, forcing exit');
    process.exit(1);
  }, 30_000);

  try {
    await Promise.all(workers.map((w) => w.close()));
    clearTimeout(shutdownTimeout);
    console.log('All workers closed cleanly');
    process.exit(0);
  } catch (err) {
    console.error('Error during shutdown:', err);
    clearTimeout(shutdownTimeout);
    process.exit(1);
  }
}

// Worker.close() internals:
// 1. Sets closing = true (stops fetching new jobs)
// 2. Waits for active jobs to complete
// 3. Clears lock renewal timer
// 4. Closes blocking Redis connection
// 5. Emits 'closed' event

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));
```

</tab>
</tabs>

## 32.9. Health Checks

Supervision is not just about crash recovery -- it also requires **proactive monitoring** to detect degraded states before they become failures.

<tabs>
<tab title="Elixir">

> **Benefit**: `Process.whereis` and `Process.alive?` provide zero-cost runtime health inspection with no polling overhead.

```elixir
# Process-based health: check if workers are alive and running
defmodule Codemoji.HealthCheck do
  @workers [
    {:guess_worker, "guess-processing"},
    {:prize_worker, "prize-distribution"},
    {:session_worker, "session-monitoring"}
  ]

  def check do
    results = Enum.map(@workers, fn {name, queue} ->
      case Process.whereis(name) do
        nil ->
          {queue, :down, "Process not found"}

        pid when is_pid(pid) ->
          cond do
            not Process.alive?(pid) ->
              {queue, :down, "Process dead"}

            EchoMQ.Worker.paused?(name) ->
              {queue, :paused, "Worker paused"}

            not EchoMQ.Worker.running?(name) ->
              {queue, :starting, "Worker not yet running"}

            true ->
              active = EchoMQ.Worker.active_count(name)
              {queue, :healthy, "#{active} active jobs"}
          end
      end
    end)

    status = if Enum.all?(results, fn {_, s, _} -> s == :healthy end),
      do: :ok, else: :degraded

    {status, results}
  end

  @doc "Phoenix health endpoint integration"
  def json_health do
    {status, results} = check()

    %{
      status: status,
      workers: Enum.map(results, fn {queue, status, detail} ->
        %{queue: queue, status: status, detail: detail}
      end)
    }
  end
end
```

</tab>
<tab title="Go">

> **Benefit**: Struct-based health with atomic counters -- no locking overhead for read-heavy monitoring.

```go
// Struct-based health: check worker state and background services
type WorkerHealth struct {
    Queue       string `json:"queue"`
    Status      string `json:"status"`
    ActiveJobs  int    `json:"active_jobs"`
    Heartbeats  uint64 `json:"heartbeat_failures"`
    StalledRec  uint64 `json:"stalled_recovered"`
    Detail      string `json:"detail"`
}

type HealthChecker struct {
    workers map[string]*echomq.Worker
}

func (h *HealthChecker) Check() (string, []WorkerHealth) {
    results := make([]WorkerHealth, 0, len(h.workers))
    allHealthy := true

    for queue, worker := range h.workers {
        health := WorkerHealth{Queue: queue}

        // Check heartbeat manager
        hbFailures := uint64(0)
        if worker.HeartbeatManager() != nil {
            hbFailures = worker.HeartbeatManager().GetFailureCount()
        }
        health.Heartbeats = hbFailures

        // Check stalled checker stats
        if worker.StalledChecker() != nil {
            _, recovered := worker.StalledChecker().GetStats()
            health.StalledRec = recovered
        }

        // Determine status
        switch {
        case hbFailures > 10:
            health.Status = "degraded"
            health.Detail = "excessive heartbeat failures"
            allHealthy = false
        default:
            health.Status = "healthy"
            health.Detail = "operating normally"
        }

        results = append(results, health)
    }

    status := "ok"
    if !allHealthy {
        status = "degraded"
    }
    return status, results
}
```

</tab>
<tab title="Node.js">

> **Tradeoff**: Event-driven tracking requires explicit listener setup per worker -- no built-in health API.

```typescript
// Event-driven health: track worker state via event listeners
interface WorkerHealth {
  queue: string;
  status: 'healthy' | 'degraded' | 'down';
  activeJobs: number;
  failedLocks: number;
  detail: string;
}

class HealthMonitor {
  private lockFailures = new Map<string, number>();
  private workers = new Map<string, Worker>();

  register(queue: string, worker: Worker) {
    this.workers.set(queue, worker);
    this.lockFailures.set(queue, 0);

    // Track lock renewal failures
    worker.on('lockRenewalFailed', (jobIds: string[]) => {
      const current = this.lockFailures.get(queue) || 0;
      this.lockFailures.set(queue, current + jobIds.length);
    });
  }

  async check(): Promise<{ status: string; workers: WorkerHealth[] }> {
    const results: WorkerHealth[] = [];
    let allHealthy = true;

    for (const [queue, worker] of this.workers) {
      const failures = this.lockFailures.get(queue) || 0;
      const isRunning = !worker.isPaused();

      let status: WorkerHealth['status'] = 'healthy';
      let detail = 'operating normally';

      if (!isRunning) {
        status = 'down';
        detail = 'worker is paused or closed';
        allHealthy = false;
      } else if (failures > 10) {
        status = 'degraded';
        detail = `${failures} lock renewal failures`;
        allHealthy = false;
      }

      results.push({ queue, status, activeJobs: 0, failedLocks: failures, detail });
    }

    return { status: allHealthy ? 'ok' : 'degraded', workers: results };
  }
}

// Express health endpoint
app.get('/health', async (req, res) => {
  const health = await monitor.check();
  const statusCode = health.status === 'ok' ? 200 : 503;
  res.status(statusCode).json(health);
});
```

</tab>
</tabs>

## 32.10. Stalled Job Recovery

When a worker crashes mid-processing, the job's lock eventually expires. The **stalled checker** detects these orphaned jobs and either requeues them or marks them as failed.

<tabs>
<tab title="Elixir">

> **Benefit**: GenServer-based periodic check with two-phase detection prevents false positives from timing jitter.

```elixir
# StalledChecker: periodic GenServer that scans for lockless active jobs
defmodule EchoMQ.StalledChecker do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl true
  def init(opts) do
    state = %{
      connection: opts[:connection],
      queue: opts[:queue],
      prefix: opts[:prefix] || "bull",
      stalled_interval: opts[:stalled_interval] || 30_000,
      max_stalled_count: opts[:max_stalled_count] || 1,
      timer_ref: nil
    }

    # Start checking after initial delay
    timer = Process.send_after(self(), :check_stalled, state.stalled_interval)
    {:ok, %{state | timer_ref: timer}}
  end

  @impl true
  def handle_info(:check_stalled, state) do
    ctx = EchoMQ.Keys.context(state.prefix, state.queue)

    case check_and_recover(state.connection, ctx, state.max_stalled_count) do
      {:ok, %{recovered: r, failed: f}} when r > 0 or f > 0 ->
        Logger.info("[StalledChecker] #{state.queue}: recovered=#{r}, failed=#{f}")
      _ -> :ok
    end

    # Schedule next check
    timer = Process.send_after(self(), :check_stalled, state.stalled_interval)
    {:noreply, %{state | timer_ref: timer}}
  end
end

# Two-phase detection prevents false positives:
# Phase 1: Mark jobs without locks as "stalled"
# Phase 2: On next check, requeue or fail jobs still in "stalled" set
```

</tab>
<tab title="Go">

> **Benefit**: Atomic `CompareAndSwap` guard prevents overlapping stalled checks without mutex contention.

```go
// StalledChecker: goroutine-based periodic check with atomic guard
type StalledChecker struct {
    worker         *Worker
    stopChan       chan struct{}
    isRunning      atomic.Bool   // prevents overlapping checks
    checkCount     uint64
    recoveredCount uint64
}

func (sc *StalledChecker) Start(ctx context.Context) {
    ticker := time.NewTicker(sc.worker.opts.StalledCheckInterval)
    defer ticker.Stop()

    for {
        select {
        case <-ctx.Done():
            return
        case <-sc.stopChan:
            return
        case <-ticker.C:
            // CompareAndSwap prevents concurrent checks
            if !sc.isRunning.CompareAndSwap(false, true) {
                continue // previous check still running
            }
            go func() {
                defer sc.isRunning.Store(false)
                sc.checkStalledJobs(ctx)
            }()
        }
    }
}

func (sc *StalledChecker) checkStalledJobs(ctx context.Context) {
    kb := NewKeyBuilder(sc.worker.queueName, sc.worker.redisClient)

    // Get all active job IDs
    activeJobs, err := sc.worker.redisClient.LRange(ctx, kb.Active(), 0, -1).Result()
    if err != nil {
        return
    }

    // Check each job's lock — no lock means stalled
    for _, jobID := range activeJobs {
        lockKey := kb.Lock(jobID)
        exists, _ := sc.worker.redisClient.Exists(ctx, lockKey).Result()
        if exists == 0 {
            sc.recoverStalledJob(ctx, jobID)
        }
    }
}
```

</tab>
<tab title="Node.js">

> **Benefit**: Lua script handles atomic two-phase detection server-side -- `setInterval` just triggers the check.

```typescript
// Node.js: stalled check runs via setInterval in the worker
// Uses the moveStalledJobsToWait Lua script for atomic recovery

class Worker {
  private startStalledCheckTimer(): void {
    // Two-phase detection: mark → recover
    const stalledCheck = async () => {
      try {
        const [failed, stalled] = await this.scripts.moveStalledJobsToWait(
          this.opts.maxStalledCount
        );

        // Emit events for monitoring
        for (const jobId of stalled) {
          this.emit('stalled', jobId, 'active');
        }

        for (const [jobId, reason] of failed) {
          const job = await Job.fromId(this, jobId);
          this.emit('failed', job,
            new Error(`job stalled more than maxStalledCount (${reason})`),
            'active'
          );
        }
      } catch (err) {
        this.emit('error', err as Error);
      }
    };

    // Start interval — runs every stalledInterval ms
    this.stalledCheckStopper = (() => {
      const timer = setInterval(stalledCheck, this.opts.stalledInterval);
      return () => clearInterval(timer);
    })();
  }
}

// Lua script handles atomic two-phase detection:
// 1. For each active job, check if lock exists
// 2. If no lock: add to stalled set (phase 1)
// 3. If already in stalled set: move to wait or failed (phase 2)
// This prevents false positives from timing jitter
```

</tab>
</tabs>

## 32.11. Sandboxed Processors

Node.js offers a unique feature: **sandboxed processors** that run in separate OS processes or worker threads. This provides crash isolation within a single-threaded runtime. The other languages achieve this naturally through their concurrency models.

<tabs>
<tab title="Elixir">

> **Benefit**: BEAM processes provide automatic memory and crash isolation -- no additional sandboxing layer needed.

```elixir
# Elixir: BEAM processes ARE sandboxed by default
# Each job runs in its own process (Task.async), isolated from others.
# No additional sandboxing layer needed.

defmodule Codemoji.Guess.Processor do
  def process(%EchoMQ.Job{data: data} = job) do
    # This runs in its own BEAM process (via Task.async in the worker)
    # A crash here does NOT crash other jobs or the worker itself
    # The worker receives {:DOWN, ref, :process, pid, reason} and handles it

    room_id = data["room_id"]
    guess = data["guess"]

    case validate_and_score(room_id, guess) do
      {:ok, score} -> {:ok, %{score: score, room_id: room_id}}
      {:error, reason} -> {:error, reason}
    end
  end
end

# Worker spawns each job in a Task:
# task = Task.async(fn ->
#   processor.(job)   # runs in isolated process
# end)
# If processor crashes, worker gets :DOWN message — not an EXIT
```

</tab>
<tab title="Go">

> **Tradeoff**: Goroutines share memory -- true isolation requires subprocess execution via `os/exec`.

```go
// Go: goroutines share memory — isolation via convention, not enforcement
// Each job runs in its own goroutine with a deferred panic recovery

func (w *Worker) processJobDirect(ctx context.Context, job *Job, token LockToken) {
    defer w.wg.Done()
    defer func() { <-w.activeSemaphore }() // release concurrency slot

    // Start per-job heartbeat
    if w.heartbeatManager != nil {
        w.heartbeatManager.StartHeartbeat(ctx, job.ID, token)
        defer w.heartbeatManager.StopHeartbeat(job.ID)
    }

    // Execute processor — panics are caught by the deferred recover
    result, err := w.processor(job)

    if err != nil {
        w.handleJobFailure(ctx, job, token, err)
    } else {
        w.handleJobSuccess(ctx, job, token, result)
    }
}

// For true isolation, run processors as separate OS processes:
func processSandboxed(job *echomq.Job) (interface{}, error) {
    // Encode job data and pass to subprocess
    data, _ := json.Marshal(job.Data)
    cmd := exec.CommandContext(context.Background(),
        "./processor", "--job-data", string(data))

    output, err := cmd.Output()
    if err != nil {
        return nil, fmt.Errorf("subprocess failed: %w", err)
    }

    var result interface{}
    json.Unmarshal(output, &result)
    return result, nil
}
```

</tab>
<tab title="Node.js">

> **Benefit**: Built-in sandbox via `ChildPool` -- worker threads or child processes provide V8 isolate separation.

```typescript
// Node.js: sandboxed processors run in child processes or worker threads
// This is a BUILT-IN feature of BullMQ/EchoMQ

// Option 1: Separate file processor (sandboxed in child process)
const worker = new Worker(
  'guess-processing',
  './processors/guess-processor.js', // path to processor file
  {
    connection: { host: 'localhost', port: 6379 },
    concurrency: 10,
    useWorkerThreads: true, // use worker threads instead of child processes
  }
);

// processors/guess-processor.js
export default async function (job) {
  // Runs in a SEPARATE V8 isolate (worker thread or child process)
  // A crash here does NOT crash the main process
  // Memory is NOT shared with the main process
  const { room_id, guess } = job.data;
  const score = await validateAndScore(room_id, guess);
  return { score, room_id };
}

// Under the hood: ChildPool manages the process pool
// class ChildPool {
//   retained: { [pid]: Child }  — currently processing
//   free: { [file]: Child[] }   — idle, reusable
//
//   retain(file): retains a free child or spawns new one
//   release(child): returns child to free pool
//   kill(child): terminates child process
//   clean(): terminates ALL children
// }

// Option 2: Inline processor (runs in main thread — no sandbox)
const unsandboxedWorker = new Worker(
  'quick-tasks',
  async (job) => {
    // Runs in the MAIN event loop
    // A thrown error does NOT crash the process (caught by Worker)
    // But an unhandled promise rejection CAN crash the process
    return processQuickTask(job.data);
  },
  { connection: { host: 'localhost', port: 6379 } }
);
```

</tab>
</tabs>

## 32.12. Common Pitfalls

<tabs>
<tab title="Elixir">

> **Tradeoff**: OTP defaults (3 restarts/5s) are too aggressive for Redis outage scenarios -- tune `max_restarts`.

```elixir
# PITFALL 1: Not using rest_for_one when workers depend on Redis
# If Redis crashes, workers fail silently on every operation

# BAD: one_for_one means Redis restart doesn't restart workers
children = [
  {EchoMQ.RedisConnection, name: :redis, url: url},
  {EchoMQ.Worker, connection: :redis, ...}
]
Supervisor.init(children, strategy: :one_for_one)

# GOOD: rest_for_one restarts workers when Redis restarts
Supervisor.init(children, strategy: :rest_for_one)

# PITFALL 2: Blocking the GenServer main loop
# The processor runs in Task.async, but if you call GenServer
# synchronously from inside the processor, you deadlock

# BAD: calling worker from inside its own processor
def process(job) do
  # This deadlocks! Worker is waiting for Task, Task calls Worker
  EchoMQ.Worker.active_count(:my_worker)
end

# GOOD: processor is self-contained
def process(job) do
  result = do_work(job.data)
  {:ok, result}
end

# PITFALL 3: Not configuring max_restarts
# Default is 3 restarts in 5 seconds — too aggressive for Redis outages

# BAD: worker crashes 4 times in 5s → supervisor crashes → app down
Supervisor.init(children, strategy: :one_for_one)

# GOOD: allow more restarts during transient failures
Supervisor.init(children,
  strategy: :one_for_one,
  max_restarts: 10,
  max_seconds: 60
)
```

</tab>
<tab title="Go">

> **Tradeoff**: `errgroup`'s one-for-all semantics may unexpectedly cancel independent workers on a single failure.

```go
// PITFALL 1: Not handling context cancellation in processor
// Long-running processors ignore shutdown signals

// BAD: processor ignores context
worker.Process(func(job *echomq.Job) (interface{}, error) {
    time.Sleep(5 * time.Minute) // blocks shutdown for 5 minutes
    return process(job.Data), nil
})

// GOOD: check context in long operations
worker.Process(func(job *echomq.Job) (interface{}, error) {
    for i := 0; i < 100; i++ {
        select {
        case <-job.Ctx.Done():
            return nil, job.Ctx.Err() // shutdown requested
        default:
            processChunk(job.Data, i)
        }
    }
    return "done", nil
})

// PITFALL 2: Goroutine leak — forgetting to cancel contexts
// BAD: cancel is never called on error path
func startWorker(ctx context.Context) {
    workerCtx, cancel := context.WithCancel(ctx)
    // cancel is never called! goroutines leak
    go runWorker(workerCtx)
}

// GOOD: always defer cancel
func startWorker(ctx context.Context) {
    workerCtx, cancel := context.WithCancel(ctx)
    defer cancel() // ensures cleanup even on error
    runWorker(workerCtx) // blocks, cancel runs when it returns
}

// PITFALL 3: errgroup cancels ALL workers on first error
// BAD: one worker's transient error kills all workers
g, ctx := errgroup.WithContext(ctx)
g.Go(func() error { return worker1.Start(ctx) }) // if this errors...
g.Go(func() error { return worker2.Start(ctx) }) // ...this gets cancelled

// GOOD: wrap with restart loop for independent workers
g.Go(func() error {
    for {
        if err := worker1.Start(ctx); err != nil {
            if ctx.Err() != nil { return ctx.Err() } // real shutdown
            log.Printf("worker1 error: %v, restarting...", err)
            time.Sleep(time.Second) // backoff
        }
    }
})
```

</tab>
<tab title="Node.js">

> **Tradeoff**: Unhandled promise rejections crash the process (Node.js 15+) -- error handlers are mandatory.

```typescript
// PITFALL 1: Unhandled promise rejections crash the process
// Node.js 15+ terminates on unhandled rejections by default

// BAD: no error handler — process crashes on first error
const worker = new Worker('guess-processing', processGuess, opts);
// if processGuess throws, 'error' event fires
// if no 'error' listener → unhandledRejection → process crash!

// GOOD: always attach error handlers
worker.on('error', (err) => {
  console.error('Worker error:', err.message);
  // log, report to Sentry, etc. — but don't crash
});

// PITFALL 2: Using process.exit() in shutdown handler
// This kills active jobs immediately

// BAD: jobs are abandoned
process.on('SIGTERM', () => process.exit(0));

// GOOD: wait for workers to finish
process.on('SIGTERM', async () => {
  await worker.close(); // waits for active jobs
  process.exit(0);
});

// PITFALL 3: Memory leaks from event listeners
// Creating workers in loops without cleanup

// BAD: each iteration adds listeners that never get removed
setInterval(() => {
  const w = new Worker('queue', processor, opts);
  // w is never closed, listeners accumulate
}, 1000);

// GOOD: track and clean up workers
const pool = new Map();
function ensureWorker(queue: string) {
  if (!pool.has(queue)) {
    const w = new Worker(queue, processor, opts);
    w.on('closed', () => pool.delete(queue));
    pool.set(queue, w);
  }
}
```

</tab>
</tabs>

## 32.13. Supervision Model Comparison

The following table summarizes how each language approaches the key supervision concerns:

| Concern | Elixir | Go | Node.js |
|---------|--------|-----|---------|
| **Supervisor** | OTP Supervisor (built-in) | `errgroup` / manual goroutine management | `cluster` module / PM2 / manual |
| **Failure isolation** | BEAM processes (complete isolation) | Goroutines (shared memory) | Worker threads / child processes |
| **Restart strategy** | `:one_for_one`, `:rest_for_one`, `:one_for_all` | Manual (restart loops, errgroup) | Manual (event handlers, process managers) |
| **Dynamic scaling** | `DynamicSupervisor` | Goroutine pool with `sync.Map` | Worker pool with `Map` |
| **Crash propagation** | `Process.link/1` (bidirectional) | `context.WithCancel` (parent→child) | Event emitter (no propagation) |
| **Lock renewal** | `LockManager` GenServer (linked) | `HeartbeatManager` goroutine (context-scoped) | `LockManager` class (timer-based) |
| **Stalled detection** | `StalledChecker` GenServer + Lua script | `StalledChecker` goroutine + Redis scan | Lua script via `setInterval` |
| **Graceful shutdown** | `prep_stop/1` + `terminate/2` | `context.Done()` + `sync.WaitGroup` | `Worker.close()` + SIGTERM handler |
| **Sandbox** | Not needed (BEAM isolation) | Not built-in (subprocess optional) | Built-in (`ChildPool` + worker threads) |

---

*Previous: [Part VI: Language Patterns](_index.md) | Next: [Chapter 33: Telemetry Integration](ch33-telemetry-integration.md)*
