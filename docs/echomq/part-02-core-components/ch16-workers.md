# Chapter 16. Workers

Workers are the job consumers in EchoMQ. A worker connects to a queue, fetches jobs, executes your processor function, and handles completion, failure, retries, and lock management. Each runtime implements the same protocol but uses language-native concurrency: Elixir uses BEAM processes with true preemptive parallelism, Go uses goroutines, and Node.js uses async/await on a single thread.

## 16.1. Worker Architecture

```
Worker
  |
  +-- Fetches jobs from Redis (moveToActive Lua script)
  |     |
  |     +-- wait list (FIFO) or prioritized set (priority order)
  |
  +-- Acquires lock (SET with TTL)
  |
  +-- Runs processor function (per-job concurrency)
  |     |
  |     +-- {:ok, result}  --> moveToCompleted
  |     +-- {:error, reason} --> retry or moveToFailed
  |     +-- crash/stall    --> lock expires, stalled checker recovers
  |
  +-- Lock renewal (heartbeat)
  |
  +-- Stalled job detection (periodic check)
```

## 16.2. Creating a Worker

<tabs>
<tab title="Elixir">

Workers in Elixir are **GenServer processes** that integrate into your supervision tree:

```elixir
defmodule Arena.CombatProcessor do
  def process(%EchoMQ.Job{name: "calculate-damage", data: data}) do
    attacker = Arena.Players.get!(data["attacker_id"])
    target = Arena.Players.get!(data["target_id"])

    result = Arena.Combat.resolve_damage(attacker, target, data["skill_id"])
    {:ok, %{damage: result.damage, critical: result.critical?, timestamp: DateTime.utc_now()}}
  end

  def process(%EchoMQ.Job{name: "apply-buff", data: data}) do
    player = Arena.Players.get!(data["player_id"])
    Arena.Combat.apply_buff(player, data["buff_id"], data["duration_ms"])
    {:ok, %{applied: true}}
  end
end

# Start in your application supervisor
children = [
  {Redix, name: :arena_redis, host: "localhost", port: 6379},

  {EchoMQ.Worker,
    name: :combat_worker,
    queue: "combat-actions",
    connection: :arena_redis,
    processor: &Arena.CombatProcessor.process/1,
    concurrency: 10}
]

Supervisor.start_link(children, strategy: :one_for_one)
```

The processor function receives an `EchoMQ.Job` struct. Three arities are supported:

| Arity | Signature | Use Case |
|-------|-----------|----------|
| 1 | `fn job -> result` | Standard processing (most common) |
| 2 | `fn job, token -> result` | Manual lock extension for long jobs |
| 3 | `fn job, token, cancel_token -> result` | Cooperative cancellation support |

The worker detects arity at init and skips cancellation token overhead for arity-1 processors.

Return values:

| Return Value | Behavior |
|---|---|
| `{:ok, result}` | Job completed. Result stored in `returnvalue` field. |
| `:ok` | Job completed with no return value. |
| `{:error, reason}` | Job failed. Retried if attempts remain. |
| `{:delay, ms}` | Move job back to delayed (does not count as an attempt). |
| `{:rate_limit, ms}` | Move to delayed due to rate limiting. |
| `:waiting` | Move job back to waiting queue. |
| `:waiting_children` | Move to waiting-children state (job flows). |

> **Benefit**: BEAM processes provide true preemptive concurrency — one slow job cannot starve others.

</tab>
<tab title="Go">

Workers in Go use a processor function and explicit start/stop lifecycle:

```go
package main

import (
    "context"
    "fmt"
    "log"
    "os"
    "os/signal"
    "time"

    "github.com/fiberfx/echomq-go/pkg/echomq"
    "github.com/redis/go-redis/v9"
)

func main() {
    ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt)
    defer cancel()

    rdb := redis.NewClient(&redis.Options{Addr: "localhost:6379"})

    worker := echomq.NewWorker("combat-actions", rdb, echomq.WorkerOptions{
        Concurrency:          10,
        LockDuration:         30 * time.Second,
        HeartbeatInterval:    15 * time.Second,
        StalledCheckInterval: 30 * time.Second,
        MaxAttempts:          3,
        BackoffDelay:         1 * time.Second,
    })

    worker.Process(func(job *echomq.Job) (interface{}, error) {
        fmt.Printf("Resolving combat action %s: %v\n", job.Name, job.Data)
        damage := resolveDamage(job.Data)
        return map[string]interface{}{"damage": damage, "resolved": true}, nil
    })

    if err := worker.Start(ctx); err != nil {
        log.Fatal(err)
    }
}
```

The processor returns `(interface{}, error)`. A nil error means success; a non-nil error triggers retry or failure based on error categorization (transient vs permanent).

> **Benefit**: Backoff configuration is declarative — `Type` and `Delay` fields are validated at compile time.

</tab>
<tab title="Node.js">

Workers in Node.js take a queue name and an async processor function:

```typescript
import { Worker, Job } from "bullmq";

const worker = new Worker(
  "combat-actions",
  async (job: Job) => {
    console.log(`Resolving ${job.name}: ${JSON.stringify(job.data)}`);
    switch (job.name) {
      case "calculate-damage":
        const damage = resolveDamage(job.data);
        return { damage, critical: damage.isCritical, timestamp: new Date().toISOString() };
      case "apply-buff":
        applyBuff(job.data.playerId, job.data.buffId);
        return { applied: true };
      default:
        throw new Error(`Unknown combat action: ${job.name}`);
    }
  },
  {
    connection: { host: "localhost", port: 6379 },
    concurrency: 10,
  }
);
```

> **Tradeoff**: Event loop concurrency means I/O-bound jobs scale well but CPU-bound jobs need worker threads.

</tab>
</tabs>

## 16.3. Worker Options

| Option | Elixir | Go | Node.js | Default |
|--------|--------|-----|---------|---------|
| Queue name | `:queue` | 1st arg | 1st arg | required |
| Processor | `:processor` | `.Process()` | 2nd arg | required |
| Concurrency | `:concurrency` | `Concurrency` | `concurrency` | 1 |
| Lock duration | `:lock_duration` | `LockDuration` | `lockDuration` | 30s |
| Stalled interval | `:stalled_interval` | `StalledCheckInterval` | `stalledInterval` | 30s |
| Max stalled count | `:max_stalled_count` | `MaxAttempts` | `maxStalledCount` | 1 |
| Auto start | `:autorun` | `.Start(ctx)` | `autorun` | true |
| Rate limiter | `:limiter` | Not implemented | `limiter` | nil |
| Redis prefix | `:prefix` | Automatic | `prefix` | "bull" |

## 16.4. Concurrency

### How Concurrency Works

Each runtime implements concurrency differently, but the protocol-level behavior is the same: N jobs can be active simultaneously per worker instance. For a game server processing combat actions, this determines how many damage calculations, buff applications, and skill resolutions can execute in parallel.

<tabs>
<tab title="Elixir">

Each concurrent job runs in its own **BEAM process** under the worker's supervision. This provides true preemptive parallelism -- a CPU-bound damage calculation cannot block other combat resolutions.

```
Worker GenServer (coordinator)
  |
  +-- Task.async: Combat A — calculate-damage (own BEAM process, own stack)
  +-- Task.async: Combat B — apply-buff      (own BEAM process, own stack)
  +-- Task.async: Combat C — resolve-skill    (own BEAM process, own stack)
  +-- Task.async: Combat D — calculate-damage (own BEAM process, own stack)
  +-- Task.async: Combat E — apply-buff      (own BEAM process, own stack)
  ...
  +-- Task.async: Combat J — resolve-skill    (own BEAM process, own stack)

  10 combat actions processing in TRUE PARALLEL (not async/await)
```

The worker tracks active jobs as a map of `job_id => {job, task_ref}`. When a task completes, the worker receives a message, handles completion/failure, and fetches the next job.

**Lock management** uses a centralized `LockManager` GenServer: one timer per worker renews locks for all active jobs in batch. This is more efficient than N timers (one per job) and is unique to the Elixir implementation.

> **Benefit**: BEAM processes provide true preemptive concurrency — one slow job cannot starve others.

</tab>
<tab title="Go">

Each concurrent job runs in its own **goroutine**. A buffered channel (`activeSemaphore`) controls concurrency:

```
Worker main loop
  |
  +-- activeSemaphore <- struct{}{} (acquire slot)
  |     |
  |     +-- go processJob(ctx, jobID, lockToken)
  |           |
  |           +-- defer <-activeSemaphore (release slot)
  |
  +-- (repeat until concurrency slots exhausted)
```

The `HeartbeatManager` handles lock renewal for all active jobs. The `StalledChecker` runs on its own goroutine with atomic guards to prevent overlapping checks.

> **Benefit**: Cron expressions are parsed at setup time — invalid patterns fail fast before runtime.

</tab>
<tab title="Node.js">

Node.js uses a single event loop with async/await. "Concurrency" means N promises executing concurrently -- true parallelism requires worker_threads or multiple processes. For I/O-bound combat actions (Redis lookups, database reads), this is efficient. For CPU-bound damage calculations, consider sandboxed processors.

```
Event Loop
  |
  +-- Promise 1: await resolveDamage(A)     (yields on I/O)
  +-- Promise 2: await applyBuff(B)          (yields on I/O)
  +-- Promise 3: await resolveSkill(C)       (yields on I/O)
  ...
  +-- Promise 10: await resolveDamage(J)     (yields on I/O)

  10 combat actions "concurrent" (interleaved, not parallel)
```

> **Benefit**: Sandboxed processors fork a child process — complete isolation from the main event loop.

</tab>
</tabs>

### Choosing Concurrency for Game Servers

| Queue Type | Recommended | Why |
|----------|-------------|-----|
| `combat-actions` (CPU-bound damage calc) | CPU cores (Elixir/Go), 1-2 (Node.js) | Maximize CPU; Node.js blocks on CPU |
| `matchmaking` (I/O-bound Redis/DB lookups) | 10-50 | Overlap network latency while searching |
| `inventory` (database writes for trades) | 5-10 | Match connection pool size |
| `world-sync` (NPC pathfinding, memory-heavy) | 2-5 | Prevent OOM from large navmesh data |
| `analytics` (HTTP calls to data warehouse) | 20-100 | Overlap external API latency |

## 16.5. Event Callbacks

<tabs>
<tab title="Elixir">

Callbacks are functions passed as worker options:

```elixir
{:ok, worker} = EchoMQ.Worker.start_link(
  queue: "combat-actions",
  connection: :arena_redis,
  processor: &Arena.CombatProcessor.process/1,
  concurrency: 10,

  on_active: fn job ->
    Logger.info("Combat action started: #{job.name} for job #{job.id}")
  end,

  on_completed: fn job, result ->
    Logger.info("Combat resolved: job #{job.id}, damage=#{result[:damage]}")
  end,

  on_failed: fn job, error ->
    Logger.error("Combat action rejected: job #{job.id}, reason=#{error}")
  end,

  on_progress: fn job, progress ->
    Logger.info("Combat #{job.id} phase: #{inspect(progress)}")
  end,

  on_stalled: fn job_id ->
    Logger.warning("Combat action stalled — worker crash? job=#{job_id}")
  end,

  on_error: fn error ->
    Logger.error("Combat worker error: #{inspect(error)}")
  end,

  on_lock_renewal_failed: fn job_ids ->
    Logger.warning("Lock renewal failed for combat actions: #{inspect(job_ids)}")
  end
)
```

The `on_lock_renewal_failed` callback is unique to Elixir. When a lock renewal fails, the affected job's processor is automatically cancelled via `CancellationToken` to prevent duplicate processing.

For structured event handling across multiple consumers (including cross-runtime events), use `QueueEvents`:

```elixir
# QueueEvents subscribes to the Redis Streams event stream
{:ok, events} = EchoMQ.QueueEvents.start_link(
  queue: "combat-actions",
  connection: :arena_redis
)

# Subscribe this process to receive events
EchoMQ.QueueEvents.subscribe(events, self())

# In your GenServer handle_info:
def handle_info({:echomq_event, :completed, %{job_id: id}}, state) do
  # Reacts to completions from ANY worker (Elixir, Go, or Node.js)
  {:noreply, state}
end
```

Or implement a handler module for a more structured approach:

```elixir
defmodule Arena.CombatEventHandler do
  use EchoMQ.QueueEvents.Handler

  @impl true
  def handle_event(:completed, %{job_id: id, returnvalue: value}, state) do
    Logger.info("Combat action #{id} resolved — broadcasting to game room")
    {:ok, state}
  end

  @impl true
  def handle_event(:failed, %{job_id: id, failed_reason: reason}, state) do
    Logger.error("Combat action #{id} rejected: #{reason}")
    {:ok, state}
  end

  @impl true
  def handle_event(_event, _data, state), do: {:ok, state}
end
```

> **Benefit**: BEAM processes provide true preemptive concurrency — one slow job cannot starve others.

</tab>
<tab title="Go">

Go emits events to the `bull:{queue}:events` Redis stream automatically. While the Worker struct does not expose callback-style hooks directly, you can consume events using `QueueEvents` or subscribe to the Redis stream:

```go
// QueueEvents provides typed event consumption
qe := echomq.NewQueueEvents("combat-actions", rdb)

qe.On("completed", func(event echomq.QueueEvent) {
    fmt.Printf("Combat resolved: job %s, result=%v\n", event.JobID, event.ReturnValue)
})

qe.On("failed", func(event echomq.QueueEvent) {
    fmt.Printf("Combat rejected: job %s, reason=%s\n", event.JobID, event.FailedReason)
})

qe.On("stalled", func(event echomq.QueueEvent) {
    fmt.Printf("Combat action stalled: job %s\n", event.JobID)
})

// Start listening (blocks until context cancelled)
go qe.Listen(ctx)
```

Alternatively, subscribe directly to the Redis event stream for custom monitoring:

```go
// Direct Redis stream subscription for game server dashboards
stream := fmt.Sprintf("bull:%s:events", "combat-actions")
for {
    results, err := rdb.XRead(ctx, &redis.XReadArgs{
        Streams: []string{stream, "$"},
        Block:   0,
    }).Result()
    if err != nil {
        break
    }
    for _, msg := range results[0].Messages {
        event := msg.Values["event"].(string)
        jobID := msg.Values["jobId"].(string)
        log.Printf("[%s] job=%s event=%s", "combat-actions", jobID, event)
    }
}
```

> **Tradeoff**: No built-in admin UI — JSON endpoints require a separate frontend or Grafana for visualization.

</tab>
<tab title="Node.js">

```typescript
worker.on("completed", (job, result) => {
  console.log(`Combat resolved: job ${job.id}, damage=${result.damage}`);
});

worker.on("failed", (job, err) => {
  console.log(`Combat rejected: job ${job?.id}: ${err.message}`);
});

worker.on("progress", (job, progress) => {
  console.log(`Combat ${job.id} phase: ${JSON.stringify(progress)}`);
});

worker.on("stalled", (jobId) => {
  console.log(`Combat action stalled — worker crash? job=${jobId}`);
});
```

> **Benefit**: Stalled job checker runs automatically within the Worker — configurable via `stalledInterval`.

</tab>
</tabs>

> **⚠️ Go Gap**: Worker event callbacks (OnCompleted, OnFailed, OnProgress, OnStalled, OnError, OnDrained) are not implemented.
> **Proposed Solution**: Add callback function fields to `WorkerOpts` and invoke them from the job completion/failure paths in `processJob()`.

> **⚠️ Go Gap**: Two-phase stalled job detection is not wired. The `moveStalledJobsToWait` Lua script is embedded but unused -- stalled checking uses a naive single-phase lock scan.
> **Proposed Solution**: Wire `moveStalledJobsToWait-8.lua` in the stalled checker goroutine, replacing the current pipeline-based approach. Pass the 8 required keys matching the Elixir `StalledChecker` implementation.

## 16.6. Progress Reporting

Progress reporting is valuable for long-running game operations like matchmaking searches, where the client needs feedback on search phases.

<tabs>
<tab title="Elixir">

```elixir
def process(%EchoMQ.Job{name: "find-match", data: data} = job) do
  player = Arena.Players.get!(data["player_id"])
  rank = player.rating

  # Phase 1: Searching nearby ranks
  EchoMQ.Worker.update_progress(job, %{phase: "searching", detail: "Scanning rank #{rank} +/- 100"})
  candidates = Arena.Matchmaking.find_candidates(rank, tolerance: 100)

  if candidates == [] do
    # Phase 2: Expanding search
    EchoMQ.Worker.update_progress(job, %{phase: "expanding", detail: "Widening to +/- 300"})
    candidates = Arena.Matchmaking.find_candidates(rank, tolerance: 300)
  end

  # Phase 3: Evaluating match quality
  EchoMQ.Worker.update_progress(job, %{phase: "evaluating", detail: "#{length(candidates)} candidates"})
  match = Arena.Matchmaking.best_match(player, candidates)

  # Phase 4: Matched
  EchoMQ.Worker.update_progress(job, %{phase: "matched", detail: "Opponent: #{match.opponent_id}"})

  {:ok, %{match_id: match.id, opponent_id: match.opponent_id, estimated_quality: match.quality}}
end
```

Progress is stored in Redis via a Lua script and emitted to the event stream. The worker's `on_progress` callback is also triggered, enabling real-time UI updates for the matchmaking screen.

> **Benefit**: `EchoMQ.Job.update_progress/2` publishes to Redis streams — real-time progress tracking.

</tab>
<tab title="Go">

```go
worker.Process(func(job *echomq.Job) (interface{}, error) {
    playerID := job.Data["player_id"].(string)
    rank := int(job.Data["rank"].(float64))

    // Phase 1: Searching nearby ranks
    job.UpdateProgress(ctx, map[string]interface{}{
        "phase": "searching", "detail": fmt.Sprintf("Scanning rank %d +/- 100", rank),
    })
    candidates := findCandidates(rank, 100)

    if len(candidates) == 0 {
        // Phase 2: Expanding search
        job.UpdateProgress(ctx, map[string]interface{}{
            "phase": "expanding", "detail": "Widening to +/- 300",
        })
        candidates = findCandidates(rank, 300)
    }

    // Phase 3: Evaluating
    job.UpdateProgress(ctx, map[string]interface{}{
        "phase": "evaluating", "detail": fmt.Sprintf("%d candidates", len(candidates)),
    })
    match := bestMatch(playerID, candidates)

    // Phase 4: Matched
    job.UpdateProgress(ctx, map[string]interface{}{
        "phase": "matched", "detail": fmt.Sprintf("Opponent: %s", match.OpponentID),
    })

    return map[string]interface{}{
        "match_id": match.ID, "opponent_id": match.OpponentID,
    }, nil
})
```

> **Benefit**: Progress updates are published atomically via Lua script — no race conditions.

</tab>
<tab title="Node.js">

```typescript
const worker = new Worker("matchmaking", async (job) => {
  const { player_id, rank } = job.data;

  // Phase 1: Searching nearby ranks
  await job.updateProgress({ phase: "searching", detail: `Scanning rank ${rank} +/- 100` });
  let candidates = await findCandidates(rank, 100);

  if (candidates.length === 0) {
    // Phase 2: Expanding search
    await job.updateProgress({ phase: "expanding", detail: "Widening to +/- 300" });
    candidates = await findCandidates(rank, 300);
  }

  // Phase 3: Evaluating match quality
  await job.updateProgress({ phase: "evaluating", detail: `${candidates.length} candidates` });
  const match = bestMatch(player_id, candidates);

  // Phase 4: Matched
  await job.updateProgress({ phase: "matched", detail: `Opponent: ${match.opponentId}` });

  return { matchId: match.id, opponentId: match.opponentId, quality: match.quality };
});
```

> **Benefit**: `job.updateProgress()` triggers `progress` events on QueueEvents listeners.

</tab>
</tabs>

## 16.7. Manual Worker Control

<tabs>
<tab title="Elixir">

```elixir
# Pause -- finish current combat actions, stop fetching new ones
EchoMQ.Worker.pause(worker)

# Resume
EchoMQ.Worker.resume(worker)

# Graceful close -- waits for active combat rounds to finish
EchoMQ.Worker.close(worker)

# Force close -- abandons current jobs (combat results lost)
EchoMQ.Worker.close(worker, force: true)

# Check state
EchoMQ.Worker.paused?(worker)    # => true/false
EchoMQ.Worker.running?(worker)   # => true/false
EchoMQ.Worker.active_count(worker) # => 7
```

### Manual Job Fetching

For advanced use cases like custom game server scheduling, you can fetch and process jobs manually:

```elixir
{:ok, worker} = EchoMQ.Worker.start_link(
  queue: "combat-actions",
  connection: :arena_redis,
  processor: nil,
  autorun: false
)

:ok = EchoMQ.Worker.start_stalled_check_timer(worker)

token = UUID.uuid4()
case EchoMQ.Worker.get_next_job(worker, token, timeout: 10) do
  {:ok, nil} -> :no_job
  {:ok, job} ->
    case Arena.Combat.resolve(job.data) do
      {:ok, result} -> EchoMQ.Job.move_to_completed(job, result, token)
      {:error, reason} -> EchoMQ.Job.move_to_failed(job, reason, token)
    end
end
```

Manual fetching uses `BZPOPMIN` on the marker key for efficient blocking waits.

> **Benefit**: GenServer-based schedulers integrate with supervision — restarts guarantee schedule continuity.

</tab>
<tab title="Go">

```go
// Graceful shutdown via context cancellation
ctx, cancel := context.WithCancel(context.Background())

// Cancel triggers graceful shutdown -- finishes active combat rounds
cancel()

// Or use the explicit Stop method
worker.Stop()
```

Go uses context cancellation as the primary control mechanism. The `gracefulShutdown()` method waits for active jobs with a configurable timeout, ensuring in-flight damage calculations complete before the worker exits.

> **Tradeoff**: Graceful shutdown requires `os/signal.Notify` and manual drain loop — more boilerplate.

</tab>
<tab title="Node.js">

```typescript
await worker.pause();
await worker.resume();
await worker.close();

// Manual job fetching for custom scheduling
const job = await worker.getNextJob("my-token");
```

> **Benefit**: `upsertJobScheduler` is Redis-persisted and idempotent — safe across process restarts.

</tab>
</tabs>

## 16.8. Cancellation Support

Cancellation is critical in game servers. When a player disconnects during matchmaking, the search should stop immediately to free resources. When a game room closes, pending combat actions for that room should be cancelled.

<tabs>
<tab title="Elixir">

Elixir supports cooperative job cancellation through `CancellationToken`. Use an arity-3 processor to receive it:

```elixir
# Arity-3 processor receives job, lock token, and cancellation token
def process(%EchoMQ.Job{name: "find-match"} = job, _token, cancel_token) do
  player_id = job.data["player_id"]
  rank = job.data["rank"]

  # Search in expanding rings until match found or cancelled
  Enum.reduce_while([100, 200, 300, 500, 1000], nil, fn tolerance, _acc ->
    if EchoMQ.CancellationToken.cancelled?(cancel_token) do
      Logger.info("Matchmaking cancelled for player #{player_id} — disconnected")
      {:halt, {:error, :cancelled}}
    else
      case Arena.Matchmaking.find_candidates(rank, tolerance: tolerance) do
        [] ->
          EchoMQ.Worker.update_progress(job, %{phase: "expanding", tolerance: tolerance})
          Process.sleep(2_000)  # Wait between search rounds
          {:cont, nil}
        candidates ->
          match = Arena.Matchmaking.best_match(player_id, candidates)
          {:halt, {:ok, %{match_id: match.id, opponent_id: match.opponent_id}}}
      end
    end
  end)
end

# Cancel when player disconnects
EchoMQ.Worker.cancel_job(worker, "job-123", "Player disconnected")

# Cancel all matchmaking when server is shutting down
EchoMQ.Worker.cancel_all_jobs(worker, "Server shutdown")
```

The worker detects processor arity at init. Arity-1 processors skip cancellation token overhead entirely.

> **Benefit**: LockManager batches all lock renewals into a single GenServer tick — O(1) timer overhead.

</tab>
<tab title="Go">

Go uses context cancellation natively. The worker passes a derived context to each processor invocation, which is cancelled on shutdown or explicit job cancellation:

```go
worker.Process(func(job *echomq.Job) (interface{}, error) {
    playerID := job.Data["player_id"].(string)
    rank := int(job.Data["rank"].(float64))

    tolerances := []int{100, 200, 300, 500, 1000}
    for _, tolerance := range tolerances {
        // Check if player disconnected (context cancelled)
        select {
        case <-ctx.Done():
            log.Printf("Matchmaking cancelled for player %s", playerID)
            return nil, ctx.Err()
        default:
        }

        candidates := findCandidates(rank, tolerance)
        if len(candidates) > 0 {
            match := bestMatch(playerID, candidates)
            return map[string]interface{}{
                "match_id": match.ID, "opponent_id": match.OpponentID,
            }, nil
        }

        // Wait between search rounds
        select {
        case <-ctx.Done():
            return nil, ctx.Err()
        case <-time.After(2 * time.Second):
        }
    }

    return nil, fmt.Errorf("no match found for player %s", playerID)
})
```

> **Tradeoff**: Graceful shutdown requires `os/signal.Notify` and manual drain loop — more boilerplate.

</tab>
<tab title="Node.js">

```typescript
const worker = new Worker("matchmaking", async (job, token, signal) => {
  const { player_id, rank } = job.data;
  const tolerances = [100, 200, 300, 500, 1000];

  for (const tolerance of tolerances) {
    // Check if player disconnected
    if (signal?.aborted) {
      throw new Error(`Matchmaking cancelled for player ${player_id}`);
    }

    const candidates = await findCandidates(rank, tolerance);
    if (candidates.length > 0) {
      return bestMatch(player_id, candidates);
    }

    await job.updateProgress({ phase: "expanding", tolerance });
    await new Promise(resolve => setTimeout(resolve, 2000));
  }

  throw new Error(`No match found for player ${player_id}`);
});

// Cancel when player disconnects
worker.cancelJob("job-123", "Player disconnected");
```

> **Benefit**: `job.updateProgress()` triggers `progress` events on QueueEvents listeners.

</tab>
</tabs>

## 16.9. Comparison: Worker Features by Runtime

| Feature | Elixir | Go | Node.js |
|---------|--------|-----|---------|
| Concurrency model | BEAM processes (true parallel) | Goroutines (true parallel) | Async/await (cooperative) |
| Job fetching | Lua `moveToActive` script | RPop/ZPopMin (non-atomic) | Lua `moveToActive` script |
| Lock management | LockManager GenServer (1 timer) | HeartbeatManager (per-job goroutine) | Per-job timer |
| Stalled detection | Lua script (atomic) | Separate Redis commands | Lua script (atomic) |
| Event callbacks | 7 callback options | QueueEvents + Redis stream | EventEmitter pattern |
| Cancellation | CancellationToken (cooperative) | Context cancellation | AbortSignal |
| Manual job fetch | `get_next_job/3` with BZPOPMIN | Not implemented | `getNextJob()` |
| Progress updates | Lua script + callback | Redis HSET | Lua script |
| Rate limiting | Lua script enforced | Not implemented | Lua script enforced |

---

*Previous: [Queues](ch15-queues.md) | Next: [Worker Patterns](ch17-worker-patterns.md)*
