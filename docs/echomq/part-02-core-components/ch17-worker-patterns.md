# Chapter 17. Worker Patterns

This chapter covers production patterns for EchoMQ workers: concurrency scaling, stalled job handling, graceful shutdown, lock management, and deployment strategies. These patterns apply across all three runtimes, with language-specific implementations. All examples use the Fireheadz Arena game engine domain.

## 17.1. Scaling with Multiple Workers

### Static Worker Pools

A game server typically runs fixed pools of workers for different queue priorities. Combat actions need high throughput and low latency. Matchmaking needs moderate concurrency for I/O-bound searches. Analytics runs in the background with minimal resources.

<tabs>
<tab title="Elixir">

Use an OTP Supervisor to manage fixed pools of workers across different game queues:

```elixir
defmodule Arena.WorkerSupervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    children = [
      # Combat actions: 3 workers x 20 concurrency = 60 parallel damage resolutions
      worker_spec("combat-actions", 1, concurrency: 20),
      worker_spec("combat-actions", 2, concurrency: 20),
      worker_spec("combat-actions", 3, concurrency: 20),

      # Matchmaking: 2 workers x 10 concurrency = 20 parallel searches
      worker_spec("matchmaking", 1, concurrency: 10),
      worker_spec("matchmaking", 2, concurrency: 10),

      # Inventory: 1 worker x 5 concurrency (DB writes, match pool size)
      worker_spec("inventory", 1, concurrency: 5),

      # Leaderboard: single worker, serialized for consistency
      worker_spec("leaderboard", 1, concurrency: 1),

      # World sync: low concurrency, memory-heavy NPC pathfinding
      worker_spec("world-sync", 1, concurrency: 3)
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp worker_spec(queue, instance, opts) do
    %{
      id: {EchoMQ.Worker, "#{queue}-#{instance}"},
      start: {EchoMQ.Worker, :start_link, [[
        queue: queue,
        connection: :arena_redis,
        processor: &Arena.Processor.process/1
      ] ++ opts]}
    }
  end
end
```

OTP's `:one_for_one` strategy means if one worker crashes, only that worker restarts. Other workers continue processing. This is structural fault tolerance -- no explicit error handling needed.

> **Benefit**: BEAM processes provide true preemptive concurrency — one slow job cannot starve others.

</tab>
<tab title="Go">

Use goroutines and a WaitGroup to manage multiple workers:

```go
func startWorkerPool(ctx context.Context, rdb *redis.Client) {
    var wg sync.WaitGroup

    configs := []struct {
        queue       string
        concurrency int
        count       int
    }{
        {"combat-actions", 20, 3},  // 60 parallel damage resolutions
        {"matchmaking", 10, 2},     // 20 parallel searches
        {"inventory", 5, 1},        // DB writes, match pool size
        {"leaderboard", 1, 1},      // Serialized for consistency
        {"world-sync", 3, 1},       // Memory-heavy pathfinding
    }

    for _, cfg := range configs {
        for i := 0; i < cfg.count; i++ {
            wg.Add(1)
            go func(queue string, concurrency int) {
                defer wg.Done()
                worker := echomq.NewWorker(queue, rdb, echomq.WorkerOptions{
                    Concurrency: concurrency,
                })
                worker.Process(arenaProcessor)
                worker.Start(ctx)
            }(cfg.queue, cfg.concurrency)
        }
    }

    wg.Wait()
}
```

> **Benefit**: Goroutine-per-job with semaphore-based limiting achieves OS-level parallelism.

</tab>
<tab title="Node.js">

```typescript
// Fixed worker pools for different game queues
const workers = [
  // Combat: 3 workers x 20 concurrency = 60 parallel
  new Worker("combat-actions", combatProcessor, { concurrency: 20 }),
  new Worker("combat-actions", combatProcessor, { concurrency: 20 }),
  new Worker("combat-actions", combatProcessor, { concurrency: 20 }),

  // Matchmaking: 2 workers x 10 concurrency
  new Worker("matchmaking", matchmakingProcessor, { concurrency: 10 }),
  new Worker("matchmaking", matchmakingProcessor, { concurrency: 10 }),

  // Inventory, leaderboard, world sync
  new Worker("inventory", inventoryProcessor, { concurrency: 5 }),
  new Worker("leaderboard", leaderboardProcessor, { concurrency: 1 }),
  new Worker("world-sync", worldSyncProcessor, { concurrency: 3 }),
];
```

> **Tradeoff**: Event loop concurrency means I/O-bound jobs scale well but CPU-bound jobs need worker threads.

</tab>
</tabs>

### Dynamic Worker Scaling

Game servers need dynamic worker scaling tied to game room lifecycle. When a new game room is created, dedicated workers spin up for that room's queues. When the game ends, those workers gracefully shut down.

<tabs>
<tab title="Elixir">

Use `DynamicSupervisor` to spawn workers on demand -- a dedicated worker pool per active game room:

```elixir
defmodule Arena.GameRoomWorkers do
  use DynamicSupervisor
  require Logger

  @queue_types ~w(rounds actions sync)

  def start_link(opts) do
    DynamicSupervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    DynamicSupervisor.init(strategy: :one_for_one, max_restarts: 100)
  end

  @doc """
  Start all workers for a new game room.
  Called from Arena.Games.create/1 when a match starts.
  """
  def start_game_workers(game_id) do
    Logger.info("Spawning workers for game room #{game_id}")

    results = Enum.map(@queue_types, fn queue_type ->
      start_worker_for_game(game_id, queue_type)
    end)

    if Enum.all?(results, &match?({:ok, _}, &1)) do
      Logger.info("All workers active for game #{game_id}")
      {:ok, game_id}
    else
      # Rollback on partial failure
      stop_game_workers(game_id)
      {:error, :worker_start_failed}
    end
  end

  @doc """
  Gracefully stop all workers for a game that has ended.
  Workers finish their current combat round before stopping.
  """
  def stop_game_workers(game_id) do
    Logger.info("Draining workers for game room #{game_id}")

    Enum.each(@queue_types, fn queue_type ->
      queue = "game:#{game_id}:#{queue_type}"

      case Registry.lookup(Arena.WorkerRegistry, queue) do
        [{pid, _}] ->
          EchoMQ.Worker.close(pid)
          Logger.debug("Stopped worker for #{queue}")
        [] ->
          Logger.debug("Worker already stopped for #{queue}")
      end
    end)

    :ok
  end

  @doc """
  Scale shared combat workers based on active game count.
  Called periodically by Arena.Scaler GenServer.
  """
  def scale_for_load(active_game_count) do
    # 1 combat worker per 10 active games, min 3, max 20
    target = active_game_count |> div(10) |> max(3) |> min(20)
    current = count_workers("combat-actions")

    cond do
      target > current ->
        Logger.info("Scaling up combat workers: #{current} -> #{target} (#{active_game_count} games)")
        for _ <- 1..(target - current), do: add_combat_worker()

      target < current ->
        Logger.info("Scaling down combat workers: #{current} -> #{target} (#{active_game_count} games)")
        remove_workers("combat-actions", current - target)

      true -> :ok
    end
  end

  # Private

  defp start_worker_for_game(game_id, queue_type) do
    queue = "game:#{game_id}:#{queue_type}"

    spec = %{
      id: make_ref(),
      start: {EchoMQ.Worker, :start_link, [[
        queue: queue,
        connection: :arena_redis,
        processor: &Arena.Processor.process/1,
        concurrency: concurrency_for(queue_type)
      ]]},
      restart: :temporary
    }

    case DynamicSupervisor.start_child(__MODULE__, spec) do
      {:ok, pid} ->
        Registry.register(Arena.WorkerRegistry, queue, pid)
        {:ok, pid}
      error ->
        Logger.error("Failed to start worker for #{queue}: #{inspect(error)}")
        error
    end
  end

  defp add_combat_worker do
    spec = %{
      id: make_ref(),
      start: {EchoMQ.Worker, :start_link, [[
        queue: "combat-actions",
        connection: :arena_redis,
        processor: &Arena.Processor.process/1,
        concurrency: 20
      ]]},
      restart: :temporary
    }
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  defp remove_workers(queue, count) do
    DynamicSupervisor.which_children(__MODULE__)
    |> Enum.filter(fn {_, pid, _, _} ->
      match?({:ok, ^queue}, GenServer.call(pid, :get_queue))
    end)
    |> Enum.take(count)
    |> Enum.each(fn {_, pid, _, _} -> EchoMQ.Worker.close(pid) end)
  end

  defp count_workers(queue) do
    DynamicSupervisor.which_children(__MODULE__)
    |> Enum.count(fn {_, pid, _, _} ->
      match?({:ok, ^queue}, GenServer.call(pid, :get_queue))
    end)
  end

  # Per-game queue concurrency
  defp concurrency_for("rounds"), do: 1   # Rounds must be sequential per game
  defp concurrency_for("actions"), do: 5  # Player actions can parallelize
  defp concurrency_for("sync"), do: 1     # State sync is serialized
end
```

Workers started with `restart: :temporary` are not restarted on crash. This is appropriate for ephemeral workers tied to a game room's lifetime -- when the game ends, its workers should not respawn.

> **Benefit**: BEAM processes provide true preemptive concurrency — one slow job cannot starve others.

</tab>
<tab title="Go">

```go
type GameRoomWorkerPool struct {
    workers map[string][]*echomq.Worker  // game_id -> workers
    mu      sync.Mutex
    rdb     redis.Cmdable
}

func (p *GameRoomWorkerPool) StartGameWorkers(ctx context.Context, gameID string) {
    p.mu.Lock()
    defer p.mu.Unlock()

    queueTypes := []struct {
        suffix      string
        concurrency int
    }{
        {"rounds", 1},   // Sequential round processing
        {"actions", 5},  // Parallel player actions
        {"sync", 1},     // Serialized state sync
    }

    var gameWorkers []*echomq.Worker
    for _, qt := range queueTypes {
        queue := fmt.Sprintf("game:%s:%s", gameID, qt.suffix)
        worker := echomq.NewWorker(queue, p.rdb, echomq.WorkerOptions{
            Concurrency: qt.concurrency,
        })
        worker.Process(arenaProcessor)
        go worker.Start(ctx)
        gameWorkers = append(gameWorkers, worker)
    }

    p.workers[gameID] = gameWorkers
}

func (p *GameRoomWorkerPool) StopGameWorkers(gameID string) {
    p.mu.Lock()
    defer p.mu.Unlock()

    if workers, ok := p.workers[gameID]; ok {
        for _, worker := range workers {
            worker.Stop()  // Graceful: finishes active combat round
        }
        delete(p.workers, gameID)
    }
}

// ScaleForLoad adjusts shared combat workers based on active game count
func (p *GameRoomWorkerPool) ScaleForLoad(ctx context.Context, activeGames int) {
    p.mu.Lock()
    defer p.mu.Unlock()

    target := max(3, min(20, activeGames/10))
    current := len(p.workers["__combat__"])

    if target > current {
        for i := 0; i < target-current; i++ {
            worker := echomq.NewWorker("combat-actions", p.rdb, echomq.WorkerOptions{
                Concurrency: 20,
            })
            worker.Process(arenaProcessor)
            go worker.Start(ctx)
            p.workers["__combat__"] = append(p.workers["__combat__"], worker)
        }
    }
}
```

> **Benefit**: Goroutine-per-job with semaphore-based limiting achieves OS-level parallelism.

</tab>
<tab title="Node.js">

```typescript
const gameWorkers = new Map<string, Worker[]>();

function startGameWorkers(gameId: string) {
  const queueTypes = [
    { suffix: "rounds", concurrency: 1 },
    { suffix: "actions", concurrency: 5 },
    { suffix: "sync", concurrency: 1 },
  ];

  const workers = queueTypes.map(({ suffix, concurrency }) => {
    const queue = `game:${gameId}:${suffix}`;
    return new Worker(queue, arenaProcessor, { connection, concurrency });
  });

  gameWorkers.set(gameId, workers);
}

async function stopGameWorkers(gameId: string) {
  const workers = gameWorkers.get(gameId);
  if (workers) {
    await Promise.all(workers.map((w) => w.close()));
    gameWorkers.delete(gameId);
  }
}
```

> **Tradeoff**: Event loop concurrency means I/O-bound jobs scale well but CPU-bound jobs need worker threads.

</tab>
</tabs>

## 17.2. Stalled Job Handling

A job is "stalled" when a worker takes it but fails to renew its lock before expiration. This happens when the worker crashes, the machine loses power, or a network partition prevents heartbeats. In a game server context, a stalled combat action means a player's damage calculation is stuck -- the stalled checker recovers it so another worker can retry.

### Detection Algorithm

EchoMQ uses a two-phase stalled detection to prevent false positives:

```
Phase 1 (Mark): Check active jobs for expired locks
  |
  +-- Job in ACTIVE list but no lock key? --> Mark as stalled
  |
Phase 2 (Recover): On next check, handle stalled jobs
  |
  +-- Stall count < max_stalled_count? --> Move back to WAITING (retry)
  +-- Stall count >= max_stalled_count? --> Move to FAILED
```

### Configuration

<tabs>
<tab title="Elixir">

```elixir
# Combat actions: short lock duration, fast recovery
{:ok, combat_worker} = EchoMQ.Worker.start_link(
  queue: "combat-actions",
  connection: :arena_redis,
  processor: &Arena.CombatProcessor.process/1,
  lock_duration: 30_000,      # Lock TTL (default: 30s)
  stalled_interval: 30_000,   # Check frequency (default: 30s)
  max_stalled_count: 1         # Max stalls before failure (default: 1)
)

# World sync / pathfinding: extended lock for long-running AI computations
{:ok, world_worker} = EchoMQ.Worker.start_link(
  queue: "world-sync",
  connection: :arena_redis,
  processor: &Arena.WorldSyncProcessor.process/1,
  lock_duration: 120_000,     # 2 minutes for pathfinding operations
  stalled_interval: 60_000,   # Check every minute
  max_stalled_count: 2         # Allow 2 stalls (pathfinding can be slow)
)
```

The Elixir stalled checker uses the `moveStalledJobsToWait` Lua script, which atomically checks locks and moves jobs. The `StalledChecker` module runs as a GenServer with periodic checks.

The `LockManager` is a key Elixir-specific optimization: instead of one timer per job (N timers for N concurrent jobs), a single timer renews all locks in batch. This reduces timer overhead from O(N) to O(1):

```
Node.js approach: N jobs = N timers = N lock extension calls
Elixir approach:  N jobs = 1 timer  = 1 batched renewal call
```

When a lock renewal fails, the `LockManager` notifies the worker, which cancels the affected job's processor via `CancellationToken` to prevent duplicate processing.

You can also trigger stalled checks manually (useful for diagnosing stuck combat actions):

```elixir
# Manual one-shot stalled check
EchoMQ.StalledChecker.check(:arena_redis, "combat-actions")

# Check if a specific job is stalled
EchoMQ.StalledChecker.job_stalled?(:arena_redis, "combat-actions", "job-123")
```

> **Benefit**: `Enum.chunk_every` pipelines provide natural batch decomposition with backpressure.

</tab>
<tab title="Go">

```go
// Combat actions: standard timing
combatWorker := echomq.NewWorker("combat-actions", rdb, echomq.WorkerOptions{
    LockDuration:         30 * time.Second,
    HeartbeatInterval:    15 * time.Second,
    StalledCheckInterval: 30 * time.Second,
    MaxAttempts:          3,
})

// World sync / pathfinding: extended timing for AI computations
worldWorker := echomq.NewWorker("world-sync", rdb, echomq.WorkerOptions{
    LockDuration:         120 * time.Second,  // 2 minutes for pathfinding
    HeartbeatInterval:    30 * time.Second,
    StalledCheckInterval: 60 * time.Second,
    MaxAttempts:          2,
})
```

The Go `StalledChecker` uses separate Redis commands (LRANGE, EXISTS, LREM, ZADD/LPUSH, HSET) rather than a Lua script. This is a **protocol gap**: the non-atomic approach can race with other workers in concurrent scenarios.

The `HeartbeatManager` handles per-job lock renewal. Since GAP-007 was fixed, lock extension now uses the `extendLock` Lua script for atomic ownership verification, preventing one worker from extending a lock stolen by another.

> **Benefit**: Rate limit config is declarative — the Lua script enforces limits atomically in Redis.

</tab>
<tab title="Node.js">

```typescript
// Combat actions: standard timing
const combatWorker = new Worker("combat-actions", combatProcessor, {
  lockDuration: 30000,
  stalledInterval: 30000,
  maxStalledCount: 1,
});

// World sync / pathfinding: extended timing
const worldWorker = new Worker("world-sync", worldSyncProcessor, {
  lockDuration: 120000,    // 2 minutes for pathfinding
  stalledInterval: 60000,
  maxStalledCount: 2,
});
```

> **Benefit**: Built-in lock extension runs automatically within the Worker class — transparent to processors.

</tab>
</tabs>

### Timing Relationships

```
lock_duration (30s)
|<----------------------------->|
|                               |
|  heartbeat/renewal (15s)      |  lock expires here
|<------------>|<------------>| |
|              |              | |
|  stalled_interval (30s)     | |
|<----------------------------->|
```

Rules:
- `heartbeat_interval` should be less than `lock_duration / 2` to ensure at least one renewal before expiration
- `stalled_interval` should be roughly equal to `lock_duration` for timely detection
- Jobs stalled for longer than `lock_duration + stalled_interval` are detected and recovered

For long-running operations like NPC pathfinding or AI behavior trees, increase `lock_duration` proportionally. A pathfinding job that takes 90 seconds needs at least a 120-second lock with 30-second heartbeat intervals.

## 17.3. Graceful Shutdown

### Sequence

A game server shutdown must finish active combat rounds before stopping workers. Abandoning mid-combat jobs results in stalled actions and a degraded player experience. A proper graceful shutdown follows this sequence:

1. **Stop accepting new work** -- pause the worker
2. **Wait for active jobs** -- allow current combat rounds to complete
3. **Timeout** -- force stop if deadline exceeded
4. **Clean up** -- close connections, cancel timers

<tabs>
<tab title="Elixir">

```elixir
defmodule Arena.ShutdownManager do
  require Logger

  @shutdown_timeout 25_000  # Fly.io gives 30s before SIGKILL

  def graceful_shutdown(timeout \\ @shutdown_timeout) do
    Logger.info("Arena shutting down — finishing active combat rounds...")

    # Get all worker PIDs (static + per-game-room)
    workers = get_all_workers()

    # Phase 1: Pause all workers (stop picking up new jobs)
    Enum.each(workers, &EchoMQ.Worker.pause/1)
    Logger.info("Workers paused: #{length(workers)}")

    # Phase 2: Save active game states for session recovery
    save_active_game_states()

    # Phase 3: Wait for active combat actions to complete
    deadline = System.monotonic_time(:millisecond) + timeout

    Enum.each(workers, fn worker ->
      remaining = deadline - System.monotonic_time(:millisecond)
      if remaining > 0 do
        EchoMQ.Worker.close(worker, timeout: remaining)
      end
    end)

    Logger.info("All workers shut down — active combat rounds completed")

    # Phase 4: Notify connected game clients
    Phoenix.PubSub.broadcast(
      Arena.PubSub,
      "system:status",
      {:server_shutdown, %{message: "Server restarting, reconnecting..."}}
    )
  end

  defp save_active_game_states do
    active_games = Arena.Games.list_active()
    Enum.each(active_games, fn game ->
      Arena.Games.save_state(game)
    end)
    Logger.info("Saved #{length(active_games)} active game states")
  end

  defp get_all_workers do
    static = Supervisor.which_children(Arena.WorkerSupervisor)
             |> Enum.map(fn {_, pid, _, _} -> pid end)
             |> Enum.filter(&is_pid/1)

    dynamic = DynamicSupervisor.which_children(Arena.GameRoomWorkers)
              |> Enum.map(fn {_, pid, _, _} -> pid end)
              |> Enum.filter(&is_pid/1)

    static ++ dynamic
  end
end
```

In a Phoenix application, this integrates with the Application `stop/1` callback. OTP handles SIGTERM automatically when `trap_exit` is set (which `EchoMQ.Worker` does in `init/1`).

For Fly.io deployments:
- SIGTERM gives 30 seconds before SIGKILL
- Use 25-second timeout to leave buffer for cleanup
- Save game state before workers drain so players can reconnect after restart

> **Benefit**: Phoenix.PubSub distributes events across clustered BEAM nodes — built-in multi-server broadcasting.

</tab>
<tab title="Go">

```go
func main() {
    ctx, cancel := signal.NotifyContext(context.Background(),
        os.Interrupt, syscall.SIGTERM)
    defer cancel()

    // Start worker pool
    combatWorker := echomq.NewWorker("combat-actions", rdb, echomq.WorkerOptions{
        Concurrency:     20,
        ShutdownTimeout: 25 * time.Second,  // Fly.io gives 30s
    })
    combatWorker.Process(combatProcessor)

    matchWorker := echomq.NewWorker("matchmaking", rdb, echomq.WorkerOptions{
        Concurrency:     10,
        ShutdownTimeout: 25 * time.Second,
    })
    matchWorker.Process(matchmakingProcessor)

    // Start blocks until context cancelled by SIGTERM
    var wg sync.WaitGroup
    for _, w := range []*echomq.Worker{combatWorker, matchWorker} {
        wg.Add(1)
        go func(worker *echomq.Worker) {
            defer wg.Done()
            if err := worker.Start(ctx); err != nil {
                log.Printf("Worker stopped: %v", err)
            }
        }(w)
    }

    wg.Wait()
    log.Println("All workers shut down — active combat rounds completed")
}
```

Go's `signal.NotifyContext` catches SIGTERM/SIGINT and cancels the context. The worker's `gracefulShutdown()` method waits for active jobs with `ShutdownTimeout`, ensuring in-flight damage calculations complete before exit.

> **Benefit**: Goroutine-per-job with semaphore-based limiting achieves OS-level parallelism.

</tab>
<tab title="Node.js">

```typescript
const gracefulShutdown = async (signal: string) => {
  console.log(`${signal} received — finishing active combat rounds...`);

  // Close all workers (waits for active jobs to complete)
  await Promise.all(workers.map((w) => w.close()));

  console.log("All workers shut down — active combat rounds completed");
  process.exit(0);
};

process.on("SIGTERM", () => gracefulShutdown("SIGTERM"));
process.on("SIGINT", () => gracefulShutdown("SIGINT"));
```

> **Benefit**: `worker.close()` returns a Promise that resolves when all active jobs complete.

</tab>
</tabs>

## 17.4. Lock Management Deep Dive

Lock management is the mechanism that prevents two workers from processing the same combat action simultaneously. Each runtime approaches this differently.

### Elixir: Centralized LockManager

The Elixir `LockManager` is a GenServer that tracks all active jobs and renews their locks in batch:

```
LockManager GenServer
  |
  +-- tracked_jobs: %{
  |     "combat-42" => %{token: "abc", ts: 1707350400000},
  |     "combat-43" => %{token: "def", ts: 1707350400100},
  |     "combat-44" => %{token: "ghi", ts: 1707350400200}
  |   }
  |
  +-- Single timer fires every lock_renew_time / 2
  |     |
  |     +-- For each tracked job: extend_lock(job_id, token, lock_duration)
  |     +-- If extend fails: notify worker -> cancel job processor
```

Benefits:
- O(1) timer overhead regardless of concurrency
- Batch lock renewal reduces Redis round-trips
- Failed renewals trigger cancellation to prevent duplicates
- Linked to worker -- if LockManager crashes, worker restarts too

### Go: Per-Job HeartbeatManager

The Go `HeartbeatManager` starts a goroutine per tracked job:

```
HeartbeatManager
  |
  +-- combat-42: goroutine with ticker -> extendLock Lua script
  +-- combat-43: goroutine with ticker -> extendLock Lua script
  +-- combat-44: goroutine with ticker -> extendLock Lua script
```

Since GAP-007 was fixed, each heartbeat goroutine now uses the `extendLock` Lua script for atomic token verification. If the lock was stolen (another worker acquired it), the script returns 0 and the job's processing context is cancelled.

### Node.js: Per-Job Timer

Node.js creates a `setInterval` timer per active job. Each timer calls the `extendLock` Lua script.

## 17.5. Error Handling Patterns

### Categorized Retries

<tabs>
<tab title="Elixir">

```elixir
def process(%EchoMQ.Job{name: "process-trade", attempts_made: attempts} = job) do
  case Arena.Inventory.execute_trade(job.data) do
    {:ok, trade_result} ->
      {:ok, trade_result}

    {:error, :insufficient_gold} ->
      # Don't retry -- player doesn't have enough gold
      {:ok, %{skipped: true, reason: "insufficient_gold"}}

    {:error, :item_locked} when attempts < 5 ->
      # Item is in another trade -- retry with backoff
      {:error, "Item locked in another trade, will retry"}

    {:error, :item_locked} ->
      # Final attempt -- fail and notify player
      {:error, "Item locked after #{attempts} attempts"}

    {:error, :redis_timeout} ->
      # Transient -- always retry
      {:error, "Redis timeout, will retry"}

    {:error, reason} ->
      {:error, reason}
  end
end
```

> **Benefit**: Custom backoff functions receive attempt count and error — full context for delay calculation.

</tab>
<tab title="Go">

Go has built-in error categorization for automatic retry decisions:

```go
worker.Process(func(job *echomq.Job) (interface{}, error) {
    result, err := executeTrade(job.Data)
    if err != nil {
        // Transient errors (network, timeout) are retried automatically
        // Permanent errors (validation, not found) fail immediately
        return nil, err
    }
    return result, nil
})

// Custom error categorization for game-specific errors
func init() {
    echomq.RegisterTransientError(ErrItemLocked)       // Retry
    echomq.RegisterTransientError(ErrRedisTimeout)      // Retry
    echomq.RegisterPermanentError(ErrInsufficientGold)  // Fail immediately
    echomq.RegisterPermanentError(ErrInvalidTradeData)  // Fail immediately
}
```

The `CategorizeError` function determines if an error is transient (network timeout, connection refused, item locked) or permanent (validation error, insufficient resources). Transient errors trigger retry with backoff; permanent errors move the job to failed immediately.

> **Benefit**: Backoff configuration is declarative — `Type` and `Delay` fields are validated at compile time.

</tab>
<tab title="Node.js">

```typescript
const worker = new Worker("inventory", async (job) => {
  try {
    return await executeTrade(job.data);
  } catch (err) {
    if (err.code === "INSUFFICIENT_GOLD") {
      return { skipped: true, reason: "insufficient_gold" }; // Don't retry
    }
    throw err; // Retry for transient errors
  }
}, {
  attempts: 5,
  backoff: { type: "exponential", delay: 1000 },
});
```

> **Benefit**: Custom backoff functions return millisecond delay — simple numeric interface.

</tab>
</tabs>

### Results Queue Pattern

<tabs>
<tab title="Elixir">

In Elixir, job results are stored in the `returnvalue` field of the job hash. For reliable downstream processing (updating leaderboards after combat, notifying players of trade results), enqueue results into a separate queue:

```elixir
def process(%EchoMQ.Job{name: "calculate-damage"} = job) do
  result = Arena.Combat.resolve_damage(job.data)

  # Forward combat result for leaderboard and analytics processing
  EchoMQ.Queue.add("leaderboard", "update-score", %{
    source_job_id: job.id,
    game_id: job.data["game_id"],
    player_id: job.data["attacker_id"],
    damage_dealt: result.damage,
    processed_at: DateTime.utc_now()
  }, connection: :arena_redis)

  {:ok, result}
end
```

> **Benefit**: Rate limiting uses Redis TTL keys — distributed limiting works across clustered BEAM nodes.

</tab>
<tab title="Go">

Go has a built-in `ProcessWithResults` helper:

```go
worker.ProcessWithResults("leaderboard", func(job *echomq.Job) (interface{}, error) {
    result := resolveDamage(job.Data)
    return result, nil // Automatically forwarded to "leaderboard" queue
}, echomq.ResultsQueueConfig{
    OnError: func(jobID string, err error) {
        log.Printf("Failed to forward combat result for %s: %v", jobID, err)
    },
})
```

This is an application-level convenience, not a protocol feature. Results are added to the target queue via standard `Queue.Add()`.

> **Benefit**: Returned `error` values make every failure path visible in the code flow.

</tab>
<tab title="Node.js">

```typescript
const worker = new Worker("combat-actions", async (job) => {
  const result = await resolveDamage(job.data);

  // Forward to leaderboard queue for score updates
  await leaderboardQueue.add("update-score", {
    sourceJobId: job.id,
    gameId: job.data.game_id,
    playerId: job.data.attacker_id,
    damageDealt: result.damage,
  });

  return result;
});
```

> **Benefit**: JSON job data requires no serialization step — JavaScript objects are the wire format.

</tab>
</tabs>

> **⚠️ Elixir Gap**: Built-in results queue forwarding pattern is not implemented.
> **Proposed Solution**: Add `EchoMQ.ResultsQueue` GenServer that subscribes to QueueEvents `:completed` and forwards `{job_id, return_value}` to a configurable results queue, matching Go's `ResultsQueue` wrapper.

## 17.6. Health Monitoring

Game servers need real-time health dashboards that track worker throughput per queue, active job counts, and Redis connectivity. This data feeds into Fly.io health checks and admin dashboards.

<tabs>
<tab title="Elixir">

```elixir
defmodule Arena.WorkerHealth do
  @game_queues [
    "combat-actions",
    "matchmaking",
    "inventory",
    "leaderboard",
    "world-sync"
  ]

  def check do
    static_health = check_static_workers()
    dynamic_health = check_game_room_workers()
    redis_health = check_redis()

    all_healthy = Enum.all?(static_health, fn w -> w.status == :healthy end)
    redis_ok = redis_health == :healthy

    overall = cond do
      not redis_ok -> :critical
      not all_healthy -> :degraded
      true -> :healthy
    end

    %{
      status: overall,
      timestamp: DateTime.utc_now(),
      static_workers: static_health,
      game_room_workers: length(dynamic_health),
      redis: redis_health,
      queues: Enum.map(@game_queues, fn queue ->
        {:ok, counts} = EchoMQ.Queue.get_counts(queue, connection: :arena_redis)
        %{queue: queue, active: counts.active, waiting: counts.waiting, failed: counts.failed}
      end)
    }
  end

  defp check_static_workers do
    Supervisor.which_children(Arena.WorkerSupervisor)
    |> Enum.map(fn {id, pid, _, _} ->
      if is_pid(pid) and Process.alive?(pid) do
        %{id: id, status: :healthy, active: EchoMQ.Worker.active_count(pid)}
      else
        %{id: id, status: :dead, active: 0}
      end
    end)
  end

  defp check_game_room_workers do
    DynamicSupervisor.which_children(Arena.GameRoomWorkers)
    |> Enum.filter(fn {_, pid, _, _} -> is_pid(pid) and Process.alive?(pid) end)
  end

  defp check_redis do
    case Redix.command(:arena_redis, ["PING"]) do
      {:ok, "PONG"} -> :healthy
      _ -> :unhealthy
    end
  end
end
```

> **Benefit**: Named connections via `Redix` integrate into supervision trees — automatic reconnect on network partitions.

</tab>
<tab title="Go">

```go
type ArenaWorkerHealth struct {
    Status    string        `json:"status"`
    Queues    []QueueHealth `json:"queues"`
    Workers   int           `json:"active_workers"`
    Connected bool          `json:"redis_connected"`
}

type QueueHealth struct {
    Queue   string `json:"queue"`
    Active  int    `json:"active"`
    Waiting int    `json:"waiting"`
    Failed  int    `json:"failed"`
}

func CheckHealth(workers []*echomq.Worker, rdb redis.Cmdable) ArenaWorkerHealth {
    queues := []string{"combat-actions", "matchmaking", "inventory", "leaderboard", "world-sync"}
    var queueHealth []QueueHealth

    for _, queue := range queues {
        active, _ := rdb.LLen(ctx, fmt.Sprintf("bull:%s:active", queue)).Result()
        waiting, _ := rdb.LLen(ctx, fmt.Sprintf("bull:%s:wait", queue)).Result()
        failed, _ := rdb.ZCard(ctx, fmt.Sprintf("bull:%s:failed", queue)).Result()
        queueHealth = append(queueHealth, QueueHealth{
            Queue: queue, Active: int(active), Waiting: int(waiting), Failed: int(failed),
        })
    }

    _, err := rdb.Ping(ctx).Result()

    return ArenaWorkerHealth{
        Status:    "healthy",
        Queues:    queueHealth,
        Workers:   len(workers),
        Connected: err == nil,
    }
}
```

> **Tradeoff**: Workers must be started as explicit goroutines with manual signal handling for graceful shutdown.

</tab>
<tab title="Node.js">

```typescript
app.get("/health", async (req, res) => {
  const queues = ["combat-actions", "matchmaking", "inventory", "leaderboard", "world-sync"];
  const queueHealth = await Promise.all(
    queues.map(async (name) => {
      const q = new Queue(name, { connection });
      const counts = await q.getJobCounts("active", "waiting", "failed");
      return { queue: name, ...counts };
    })
  );

  res.json({
    status: "healthy",
    queues: queueHealth,
    workers: workers.length,
  });
});
```

> **Benefit**: `ioredis` connection with lazy initialization — Redis connects only when the first command is issued.

</tab>
</tabs>

## 17.7. Telemetry and Tracing

<tabs>
<tab title="Elixir">

The worker supports pluggable telemetry via the `:telemetry` option. Pass a module implementing `EchoMQ.Telemetry.Behaviour` for distributed tracing of combat actions through your game server pipeline:

```elixir
{EchoMQ.Worker,
  queue: "combat-actions",
  connection: :arena_redis,
  processor: &Arena.CombatProcessor.process/1,
  telemetry: EchoMQ.Telemetry.OpenTelemetry}
```

This enables automatic span creation for job processing, including attributes like job name, queue, duration, and result. Traces propagate through your existing OpenTelemetry pipeline (Jaeger, Honeycomb, Datadog, etc.).

For custom game metrics, attach telemetry handlers:

```elixir
:telemetry.attach_many(
  "arena-worker-metrics",
  [
    [:echomq, :job, :completed],
    [:echomq, :job, :failed],
    [:echomq, :worker, :stalled]
  ],
  fn event, measurements, metadata, _config ->
    StatsD.increment("arena.#{Enum.join(event, ".")}", tags: [
      "queue:#{metadata.queue}",
      "job:#{metadata.job_name}"
    ])
    if measurements[:duration_ms] do
      StatsD.histogram("arena.job.duration", measurements.duration_ms, tags: [
        "queue:#{metadata.queue}"
      ])
    end
  end,
  nil
)
```

> **Benefit**: OpenTelemetry BEAM SDK propagates trace context across process boundaries automatically.

</tab>
<tab title="Go">

Go does not yet have built-in telemetry integration. Use the event emitter's Redis Streams output for external monitoring, or wrap the processor function with Prometheus metrics:

```go
worker.Process(func(job *echomq.Job) (interface{}, error) {
    start := time.Now()
    result, err := combatProcessor(job)
    duration := time.Since(start)

    // Prometheus metrics for game server dashboard
    jobDuration.WithLabelValues(job.Name, "combat-actions").Observe(duration.Seconds())
    if err != nil {
        jobFailures.WithLabelValues(job.Name, "combat-actions").Inc()
    } else {
        jobCompletions.WithLabelValues(job.Name, "combat-actions").Inc()
    }
    return result, err
})
```

> **Benefit**: `promhttp.Handler()` serves metrics on any port — no framework dependency needed.

</tab>
<tab title="Node.js">

```typescript
// Prometheus metrics for game server monitoring
worker.on("completed", (job) => {
  metrics.increment("arena.jobs.completed", { queue: "combat-actions", name: job.name });
});

worker.on("failed", (job, err) => {
  metrics.increment("arena.jobs.failed", { queue: "combat-actions", name: job?.name });
});
```

> **Benefit**: `prom-client` `register.metrics()` returns Prometheus text format ready for scraping.

</tab>
</tabs>

## 17.8. Protocol Gap Summary: Go Workers

The Go worker implementation has several areas where it diverges from the Elixir and Node.js implementations (which both use Lua scripts for atomicity). Two gaps have been closed since initial documentation:

| Operation | Elixir/Node.js | Go | Status |
|-----------|---------------|-----|--------|
| Job pickup | `moveToActive` Lua (atomic) | RPop/ZPopMin + separate LPUSH (non-atomic) | **GAP-005**: Open |
| Retry | `moveToDelayed` Lua (atomic) | LREM + ZADD + HSET (3 commands) | **GAP-002**: Open |
| Stalled recovery | `moveStalledJobsToWait` Lua (atomic) | LREM + ZADD/LPUSH + HSET (separate) | **GAP-003**: Open |
| Priority encoding | `addPrioritizedJob` Lua with `pc` counter | Composite score `priority * 0x100000000 + counter` | **GAP-004**: Fixed |
| Lock extension | `extendLock` Lua (token verified) | `extendLock` Lua script (token verified) | **GAP-007**: Fixed |

**Fixed gaps:**
- **GAP-004** (priority encoding): Now uses the composite score `priority * 0x100000000 + counter % 0x100000000` with an atomically incremented per-queue priority counter (`pc` key), matching the BullMQ protocol. Same-priority jobs maintain FIFO ordering across all runtimes.
- **GAP-007** (lock extension): Now uses the `extendLock` Lua script for atomic token ownership verification and stalled SET cleanup. If the lock was stolen by another worker, the script returns 0 and the job's processing is cancelled.

**Open gaps** do not cause data loss in single-worker scenarios. They become relevant in multi-worker, high-throughput, or crash-recovery scenarios. The embedded Lua scripts exist in Go's `scripts/scripts.go` but are not yet wired into all critical-path operations. See `PROTOCOL-GAPS.md` in the echomq-go repository for detailed wiring plans.

## 17.9. Manual Job Processing

Manual processing gives full control over the job lifecycle — fetching jobs, managing locks, and deciding completion or failure explicitly rather than relying on the automatic processing loop. This is useful for custom routing, application-level rate limiting, batch processing, or integration with external workflow engines.

<tabs>
<tab title="Elixir">

```elixir
# Create a worker in manual mode (no automatic processing loop)
{:ok, worker} = EchoMQ.Worker.start_link(
  queue: "game:events",
  connection: :redis,
  processor: nil,
  autorun: false,
  lock_duration: 30_000)

EchoMQ.Worker.start_stalled_check_timer(worker)

# Fetch and process a single job
token = Base.encode16(:crypto.strong_rand_bytes(16), case: :lower)

case EchoMQ.Worker.get_next_job(worker, token) do
  {:ok, nil} -> :no_jobs
  {:ok, job} ->
    case process_player_action(job.data) do
      {:ok, result} -> EchoMQ.Job.move_to_completed(job, result, token)
      {:error, reason} -> EchoMQ.Job.move_to_failed(job, reason, token)
    end
end
```

</tab>
<tab title="Go">

```go
// Go does not yet support manual processing mode.
// The Worker struct always runs an automatic processing loop.
//
// Workaround: use a custom Redis consumer that calls moveToActive
// and moveToCompleted Lua scripts directly.
//
// See PROTOCOL-GAPS.md for the manual processing implementation roadmap.
```

</tab>
<tab title="Node.js">

```typescript
const worker = new Worker('game:events', undefined, {
  connection,
  autorun: false,   // Manual mode
  lockDuration: 30000,
});

const token = crypto.randomUUID();
const job = await worker.getNextJob(token);
if (job) {
  try {
    const result = await processPlayerAction(job.data);
    await job.moveToCompleted(result, token, true); // fetchNext=true
  } catch (err) {
    await job.moveToFailed(err as Error, token);
  }
}
```

</tab>
</tabs>

### Manual Processing API

| Operation | Elixir | Node.js |
|-----------|--------|---------|
| Fetch job | `Worker.get_next_job(worker, token)` | `worker.getNextJob(token)` |
| Complete | `Job.move_to_completed(job, value, token)` | `job.moveToCompleted(value, token)` |
| Fail | `Job.move_to_failed(job, error, token)` | `job.moveToFailed(error, token)` |
| Return to queue | `Job.move_to_wait(job, token)` | `job.moveToWait(token)` |
| Extend lock | `Job.extend_lock(job, token, duration)` | `job.extendLock(token, duration)` |
| Start stalled check | `Worker.start_stalled_check_timer(worker)` | `worker.startStalledCheckTimer()` |

### Long-Running Jobs with Lock Extension

For jobs that take longer than the lock duration, extend the lock periodically to prevent stalled-job recovery from reclaiming the job:

<tabs>
<tab title="Elixir">

```elixir
defp process_long_job(job, token) do
  lock_task = Task.async(fn -> extend_lock_loop(job, token) end)
  try do
    result = do_long_work(job.data)
    EchoMQ.Job.move_to_completed(job, result, token)
  rescue
    e -> EchoMQ.Job.move_to_failed(job, Exception.message(e), token)
  after
    Task.shutdown(lock_task, :brutal_kill)
  end
end

defp extend_lock_loop(job, token) do
  Process.sleep(10_000)  # Extend every 10s (assuming 30s lock)
  case EchoMQ.Job.extend_lock(job, token, 30_000) do
    {:ok, _} -> extend_lock_loop(job, token)
    {:error, _} -> :ok  # Lock lost, stop extending
  end
end
```

</tab>
<tab title="Go">

```go
// Go's automatic worker handles lock extension via the LockManager.
// For manual scenarios, call extendLock directly:
func extendLockLoop(ctx context.Context, job *echomq.Job, token string) {
    ticker := time.NewTicker(10 * time.Second)
    defer ticker.Stop()
    for {
        select {
        case <-ctx.Done():
            return
        case <-ticker.C:
            if err := job.ExtendLock(ctx, token, 30000); err != nil {
                return // lock lost
            }
        }
    }
}
```

</tab>
<tab title="Node.js">

```typescript
async function processLongJob(job: Job, token: string) {
  const interval = setInterval(async () => {
    try { await job.extendLock(token, 30000); }
    catch { clearInterval(interval); } // lock lost
  }, 10000);

  try {
    const result = await doLongWork(job.data);
    await job.moveToCompleted(result, token);
  } catch (err) {
    await job.moveToFailed(err as Error, token);
  } finally {
    clearInterval(interval);
  }
}
```

</tab>
</tabs>

**Token management rules**: generate a unique token per fetch, use the same token for all operations on that job (complete/fail/extend), and never reuse tokens across different jobs.

## 17.10. Cooperative Job Cancellation

EchoMQ provides cooperative job cancellation, where processors voluntarily check for cancellation signals. This enables graceful stop for long-running jobs, user-initiated cancellations, and clean shutdown.

### How Cancellation Works

Each runtime uses its native cancellation mechanism:

| Runtime | Mechanism | Overhead |
|---------|-----------|----------|
| Elixir | `cancel_token` reference + `receive after 0` | O(1), zero for arity-1 processors |
| Go | `context.Context` cancellation | O(1), standard Go pattern |
| Node.js | `AbortSignal` (via `AbortController`) | O(1), standard Web API |

<tabs>
<tab title="Elixir">

```elixir
# Arity-2 processor receives a cancel_token
processor = fn job, cancel_token ->
  Enum.reduce_while(job.data["items"], {:ok, []}, fn item, {:ok, acc} ->
    receive do
      {:cancel, ^cancel_token, reason} ->
        {:halt, {:error, {:cancelled, reason}}}
    after
      0 ->  # Non-blocking check — O(1)
        result = process_item(item)
        {:cont, {:ok, [result | acc]}}
    end
  end)
end

# Cancel a specific job
:ok = EchoMQ.Worker.cancel_job(worker, job_id, "User requested cancellation")

# Cancel all active jobs (graceful shutdown)
:ok = EchoMQ.Worker.cancel_all_jobs(worker, "Worker shutting down")
```

</tab>
<tab title="Go">

```go
// Go uses context.Context — cancel propagates via ctx.Done()
func processor(ctx context.Context, job *echomq.Job) (interface{}, error) {
    for _, item := range job.Data["items"].([]interface{}) {
        select {
        case <-ctx.Done():
            return nil, fmt.Errorf("cancelled: %w", ctx.Err())
        default:
            processItem(item)
        }
    }
    return map[string]interface{}{"processed": true}, nil
}

// Cancel via context: the worker cancels the context when
// Worker.CancelJob(jobID) is called or the job lock is lost.
```

</tab>
<tab title="Node.js">

```typescript
// Node.js processors can receive an AbortSignal via job.token
const worker = new Worker('queue', async (job) => {
  for (const item of job.data.items) {
    if (job.isAborted) {
      throw new Error('Job cancelled');
    }
    await processItem(item);
  }
  return { processed: true };
});

// Cancel from outside
await worker.cancelJob(jobId, 'User requested cancellation');
```

</tab>
</tabs>

### Automatic Cancellation on Lock Loss

When a job's lock renewal fails (Redis disconnect, TTL expiry), EchoMQ automatically sends a cancellation signal. This prevents duplicate processing when another worker picks up the same job:

- **Elixir**: `{:cancel, cancel_token, {:lock_lost, job_id}}` message
- **Go**: Context is cancelled with `context.DeadlineExceeded`
- **Node.js**: `job.isAborted` becomes `true`

### Distributed Cancellation

In multi-node Elixir deployments, use `:pg` (process groups) for cluster-wide cancellation without Redis:

<tabs>
<tab title="Elixir">

```elixir
defmodule Echo.WorkerRegistry do
  @group :echomq_workers

  def register(worker_pid, queue_name) do
    :pg.join(@group, {__MODULE__, queue_name}, worker_pid)
  end

  def cancel_job(queue_name, job_id, reason) do
    for worker <- :pg.get_members(@group, {__MODULE__, queue_name}) do
      EchoMQ.Worker.cancel_job(worker, job_id, reason)
    end
    :ok
  end
end
```

</tab>
<tab title="Go">

```go
// Go requires external coordination for cross-node cancellation.
// Typical pattern: Redis pubsub channel per queue.
func cancelJobDistributed(ctx context.Context, rc *redis.Client, queue, jobID, reason string) error {
    msg, _ := json.Marshal(map[string]string{
        "queue": queue, "jobId": jobID, "reason": reason,
    })
    return rc.Publish(ctx, "echomq:cancel", msg).Err()
}
```

</tab>
<tab title="Node.js">

```typescript
// Node.js uses Redis pubsub for cross-node cancellation
const CANCEL_CHANNEL = 'echomq:cancel';

async function cancelJobDistributed(queue: string, jobId: string, reason: string) {
  const message = JSON.stringify({ queue, jobId, reason });
  await redisClient.publish(CANCEL_CHANNEL, message);
}
```

</tab>
</tabs>

For polyglot deployments (Elixir + Node.js + Go workers), a Redis Pub/Sub bridge on the Elixir side forwards cancellation requests between runtimes. Elixir-to-Elixir communication uses `:pg` directly (no Redis overhead), while cross-runtime uses the Redis channel.

---

*Previous: [Workers](ch16-workers.md) | Next: [Flows Overview](ch18-flows-overview.md)*
