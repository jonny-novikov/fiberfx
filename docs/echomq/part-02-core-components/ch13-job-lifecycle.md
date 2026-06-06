# Chapter 13. Job Lifecycle

Every job follows a predictable path through the EchoMQ system, transitioning between well-defined states. Because all three runtimes share the same Redis data structures and Lua scripts, the lifecycle is identical regardless of which language enqueued or processes the job.

## 13.1. Lifecycle Overview

```
                      Queue.add()
                          |
            +-------------+-------------+
            |             |             |
            v             v             v
        WAITING       DELAYED     PRIORITIZED
            |             |             |
            |    (timer)  |             |
            |      +------+             |
            |      |                    |
            v      v                    |
        WAITING <--+                    |
            |                           |
            +---------------------------+
            |
            v
         ACTIVE  (worker picks up, lock acquired)
            |
     +------+------+
     |      |      |
     v      v      v
 COMPLETED FAILED STALLED
               |      |
               |      +---> WAITING (if retries left)
               |      +---> FAILED  (if no retries)
               |
               +---> WAITING (if retries left, with backoff)
               +---> FAILED  (final failure)
```

### Parent-Child Extension

When using flows (parent-child job relationships), an additional state exists:

```
Queue.add(parent + children)
              |
              v
      WAITING-CHILDREN  ----> (all children complete) ----> WAITING
              |
              v
    (child fails, no ignore) ----> FAILED
```

---

## 13.2. Job States

### WAITING

Jobs ready for immediate processing. This is the default state for jobs added without delay or priority. A combat action enters WAITING as soon as the player submits an attack.

**Redis storage**: List (`bull:{queue}:wait`)

<tabs>
<tab title="Elixir">

```elixir
{:ok, job} = EchoMQ.Queue.add("combat-actions", "calculate-damage",
  %{player_id: "PLR0K48QjihpC4", target_id: "NPC5rK2mJ9pQ1L", damage: 150},
  connection: :redis)
# job enters WAITING state immediately

{:ok, counts} = EchoMQ.Queue.get_counts("combat-actions", connection: :redis)
IO.puts("Waiting: #{counts.waiting}")
```

> **Benefit**: Named connections via `Redix` integrate into supervision trees — automatic reconnect on network partitions.

</tab>
<tab title="Go">

```go
queue := echomq.NewQueue("combat-actions", rdb)

job, _ := queue.Add(ctx, "calculate-damage",
    map[string]interface{}{"player_id": "PLR0K48QjihpC4", "target_id": "NPC5rK2mJ9pQ1L", "damage": 150},
    echomq.JobOptions{})
// job enters WAITING state immediately

counts, _ := queue.GetJobCounts(ctx)
fmt.Printf("Waiting: %d\n", counts.Waiting)
```

> **Benefit**: Strongly-typed option structs catch misconfiguration at compile time.

</tab>
<tab title="Node.js">

```typescript
const queue = new Queue("combat-actions", { connection });

const job = await queue.add("calculate-damage", {
  player_id: "PLR0K48QjihpC4", target_id: "NPC5rK2mJ9pQ1L", damage: 150,
});
// job enters WAITING state immediately

const counts = await queue.getJobCounts("waiting");
console.log(`Waiting: ${counts.waiting}`);
```

> **Benefit**: `ioredis` connection with lazy initialization — Redis connects only when the first command is issued.

</tab>
</tabs>

### PRIORITIZED

Jobs with a priority value greater than 0 enter the priority queue instead of the wait list. They are dequeued in priority order (lower score = higher priority). Damage calculations (priority 1) process before buff applications (priority 5).

**Redis storage**: Sorted Set (`bull:{queue}:prioritized`)
**Score**: Priority value (composite: `priority * 0x100000000 + counter`)

<tabs>
<tab title="Elixir">

```elixir
{:ok, job} = EchoMQ.Queue.add("combat-actions", "calculate-damage",
  %{player_id: "PLR0K48QjihpC4", target_id: "NPC5rK2mJ9pQ1L", damage: 250},
  connection: :redis, priority: 1)
# job enters PRIORITIZED state
# Prioritized jobs are processed before WAITING jobs

# The estimated_state/1 function detects this:
EchoMQ.Job.estimated_state(job)  #=> :prioritized (when priority > 0)
```

> **Benefit**: Priority maps to Redis sorted set scores — atomic ordering without application-level sorting.

</tab>
<tab title="Go">

```go
job, _ := queue.Add(ctx, "calculate-damage",
    map[string]interface{}{"player_id": "PLR0K48QjihpC4", "target_id": "NPC5rK2mJ9pQ1L", "damage": 250},
    echomq.JobOptions{Priority: 1})
// job enters PRIORITIZED state
// Worker checks prioritized queue before wait queue
```

> **Benefit**: Priority encoding uses composite score combining priority level and insertion order.

</tab>
<tab title="Node.js">

```typescript
const queue = new Queue("combat-actions", { connection });

const job = await queue.add("calculate-damage", {
  player_id: "PLR0K48QjihpC4", target_id: "NPC5rK2mJ9pQ1L", damage: 250,
}, { priority: 1 });
// job enters PRIORITIZED state
```

> **Benefit**: Priority values mirror BullMQ's proven sorted set implementation.

</tab>
</tabs>

### DELAYED

Jobs scheduled for future execution. A scheduler process (or Lua script) moves them to WAITING when their timestamp arrives. NPC respawn timers and buff expirations are classic delayed jobs.

**Redis storage**: Sorted Set (`bull:{queue}:delayed`)
**Score**: Target execution timestamp (Unix ms)

<tabs>
<tab title="Elixir">

```elixir
# Respawn NPC after 30-second cooldown
{:ok, job} = EchoMQ.Queue.add("world-sync", "spawn-npc",
  %{npc_id: "NPC5rK2mJ9pQ1L", zone: "dungeon-7", hp: 5000},
  connection: :redis, delay: 30_000)
# job enters DELAYED state
# After 30 seconds, moves to WAITING (or PRIORITIZED if priority set)

EchoMQ.Job.delayed?(job)  #=> true (when delay > 0)

# The exact activation time:
EchoMQ.Job.delay_until(job)  #=> timestamp + delay (ms)
```

> **Benefit**: Priority maps to Redis sorted set scores — atomic ordering without application-level sorting.

</tab>
<tab title="Go">

```go
// Respawn NPC after 30-second cooldown
job, _ := queue.Add(ctx, "spawn-npc",
    map[string]interface{}{"npc_id": "NPC5rK2mJ9pQ1L", "zone": "dungeon-7", "hp": 5000},
    echomq.JobOptions{Delay: 30 * time.Second})
// job enters DELAYED state
// Go stores delay as timestamp offset in the sorted set score
```

> **Benefit**: `time.Duration` types prevent unit mismatch bugs that plague raw millisecond integers.

</tab>
<tab title="Node.js">

```typescript
// Respawn NPC after 30-second cooldown
const job = await queue.add("spawn-npc", {
  npc_id: "NPC5rK2mJ9pQ1L", zone: "dungeon-7", hp: 5000,
}, { delay: 30_000 });
// job enters DELAYED state
```

> **Benefit**: Millisecond delays align with JavaScript's native timing model — intuitive for Node.js developers.

</tab>
</tabs>

### ACTIVE

Jobs currently being processed by a worker. The worker acquires a lock with a TTL to claim the job. A heartbeat mechanism extends the lock while processing continues. A damage calculation enters ACTIVE when a worker picks it up for resolution.

**Redis storage**: List (`bull:{queue}:active`)
**Lock**: `bull:{queue}:{job_id}:lock` with configurable TTL (default 30s)

<tabs>
<tab title="Elixir">

```elixir
# Workers move jobs to ACTIVE automatically.
# The EchoMQ.Worker GenServer handles this internally.

# Check from struct:
EchoMQ.Job.active?(job)  #=> true (processed_on set, finished_on nil)

# Check active combat actions
{:ok, counts} = EchoMQ.Queue.get_counts("combat-actions", connection: :redis)
IO.puts("Active: #{counts.active}")
```

> **Benefit**: Job promotion from delayed to waiting uses atomic Lua script — no race window.

</tab>
<tab title="Go">

```go
// Workers move jobs to ACTIVE automatically.
// The worker.pickupJob() -> acquireLockAndActivate() handles this.

counts, _ := queue.GetJobCounts(ctx)
fmt.Printf("Active combat actions: %d\n", counts.Active)
```

> **Tradeoff**: Lock extension requires periodic goroutine-based timers — manual lifecycle management.

</tab>
<tab title="Node.js">

```typescript
// Workers move jobs to ACTIVE automatically
const counts = await queue.getJobCounts("active");
console.log(`Active combat actions: ${counts.active}`);
```

> **Benefit**: `job.promote()` moves delayed jobs to waiting immediately — useful for urgent tasks.

</tab>
</tabs>

### COMPLETED

Jobs that finished successfully. The processor returned a success result, and the return value is stored in the job hash. A resolved combat action stores its outcome (damage dealt, buffs applied).

**Redis storage**: Sorted Set (`bull:{queue}:completed`)
**Score**: Completion timestamp (Unix ms)

<tabs>
<tab title="Elixir">

```elixir
# Worker returns {:ok, result} -> job moves to COMPLETED
def process(%EchoMQ.Job{name: "calculate-damage", data: data}) do
  result = resolve_damage(data["player_id"], data["target_id"], data["damage"])
  {:ok, %{damage_dealt: result.final_damage, target_hp: result.remaining_hp}}
end

# Check from struct:
EchoMQ.Job.completed?(job)  #=> true (finished_on set, no failed_reason)
```

Other valid success returns from the processor:
- `:ok` -- completed with no return value
- `{:delay, milliseconds}` -- move to delayed (does not increment attempts)
- `:waiting` -- move back to waiting queue
- `:waiting_children` -- move to waiting-children state

> **Benefit**: Job promotion from delayed to waiting uses atomic Lua script — no race window.

</tab>
<tab title="Go">

```go
// Processor returns (result, nil) -> job moves to COMPLETED
worker.Process(func(job *echomq.Job) (interface{}, error) {
    result := resolveDamage(job.Data["player_id"].(string),
        job.Data["target_id"].(string), job.Data["damage"])
    return map[string]interface{}{
        "damage_dealt": result.FinalDamage,
        "target_hp":    result.RemainingHP,
    }, nil
})
```

> **Benefit**: Move operations are Lua-script atomic — consistent across all queue states.

</tab>
<tab title="Node.js">

```typescript
// Processor returns value -> job moves to COMPLETED
const worker = new Worker("combat-actions", async (job) => {
  const result = await resolveDamage(job.data.player_id, job.data.target_id, job.data.damage);
  return { damage_dealt: result.finalDamage, target_hp: result.remainingHP };
}, { connection });
```

> **Benefit**: `job.promote()` moves delayed jobs to waiting immediately — useful for urgent tasks.

</tab>
</tabs>

### FAILED

Jobs that errored during processing. If retries are configured and not exhausted, the job moves back to WAITING with a backoff delay. Otherwise it remains in FAILED as a terminal state. A matchmaking job might fail if the ranking service is temporarily unavailable.

**Redis storage**: Sorted Set (`bull:{queue}:failed`)
**Score**: Failure timestamp (Unix ms)

<tabs>
<tab title="Elixir">

```elixir
# Worker returns {:error, reason} -> job moves to FAILED
def process(%EchoMQ.Job{name: "find-match", data: data} = job) do
  case Fireheadz.Matchmaking.find_opponent(data["player_id"], data["rank"]) do
    {:ok, match} -> {:ok, match}
    {:error, :ranking_service_down} -> {:error, :ranking_service_down}
  end
end

# Raising an exception also fails the job
def process(%EchoMQ.Job{name: "process-trade"}) do
  raise "Insufficient inventory"
end

# Check from struct:
EchoMQ.Job.failed?(job)  #=> true (failed_reason is not nil)
```

> **Benefit**: Job promotion from delayed to waiting uses atomic Lua script — no race window.

</tab>
<tab title="Go">

```go
// Processor returns (nil, err) -> job moves to FAILED
worker.Process(func(job *echomq.Job) (interface{}, error) {
    match, err := findOpponent(job.Data["player_id"].(string), job.Data["rank"])
    if err != nil {
        return nil, err  // Job fails
    }
    return match, nil
})
```

Go categorizes errors as transient (retry) or permanent (fail immediately) via the `CategorizeError()` function.

> **Benefit**: Move operations are Lua-script atomic — consistent across all queue states.

</tab>
<tab title="Node.js">

```typescript
const worker = new Worker("matchmaking", async (job) => {
  const match = await findOpponent(job.data.player_id, job.data.rank);
  if (!match.ok) {
    throw new Error(match.error); // Job fails
  }
  return match;
}, { connection });
```

> **Tradeoff**: Uncaught Promise rejections can crash the process — requires global `unhandledRejection` handler.

</tab>
</tabs>

### STALLED

Jobs where the worker died or lost connection during processing. The stalled checker detects expired locks and either retries the job or moves it to FAILED. A long-running pathfinding calculation is a classic stall candidate -- if the worker crashes mid-computation, the job is recovered automatically.

<tabs>
<tab title="Elixir">

```elixir
# Stalled detection is automatic. Configure via worker options:
{EchoMQ.Worker,
  queue: "world-sync",
  connection: :redis,
  processor: &Fireheadz.PathfindingProcessor.process/1,
  stalled_interval: 30_000,   # Check every 30 seconds (default)
  max_stalled_count: 1}       # Max stalls before failing (default)
```

The Elixir implementation has a structural advantage here: the `LockManager` uses **1 timer per worker** instead of N timers per job. Combined with BEAM's preemptive scheduling, this eliminates the risk of a CPU-intensive pathfinding job blocking the stall-check timer -- a common failure mode in single-threaded runtimes where the event loop can be starved.

> **Benefit**: GenServer-based schedulers integrate with supervision — restarts guarantee schedule continuity.

</tab>
<tab title="Go">

```go
// Go's StalledChecker runs automatically when the worker starts.
// It checks for expired locks at StalledCheckInterval.
worker := echomq.NewWorker("world-sync", rdb, echomq.WorkerOptions{
    StalledCheckInterval: 30 * time.Second,
    MaxAttempts:          3,
})
```

> **Tradeoff**: Lock extension requires periodic goroutine-based timers — manual lifecycle management.

</tab>
<tab title="Node.js">

```typescript
const worker = new Worker("world-sync", pathfindProcessor, {
  connection,
  stalledInterval: 30000,
  maxStalledCount: 2,
});

worker.on("stalled", (jobId) => {
  console.log(`Pathfinding job ${jobId} stalled — requeuing`);
});
```

> **Benefit**: Stalled job checker runs automatically within the Worker — configurable via `stalledInterval`.

</tab>
</tabs>

### WAITING-CHILDREN

Parent jobs in a flow that are waiting for their child jobs to complete. Once all children finish, the parent moves to WAITING for processing. In a game context, a "match-complete" parent job might wait for child jobs that update each player's stats, grant rewards, and record the replay.

**Redis storage**: Sorted Set (`bull:{queue}:waiting-children`)

<tabs>
<tab title="Elixir">

```elixir
# When processing a parent "match-complete" job, access child results:
def process(%EchoMQ.Job{name: "match-complete"} = job) do
  {:ok, children_values} = EchoMQ.Job.get_children_values(job)
  # %{"bull:leaderboard:123" => %{new_rank: 5}, "bull:inventory:456" => %{rewards: [...]}}

  {:ok, ignored_failures} = EchoMQ.Job.get_ignored_children_failures(job)
  # %{"bull:player-events:789" => "Achievement service timeout"}

  {:ok, deps} = EchoMQ.Job.get_dependencies(job)
  # ["bull:leaderboard:123", "bull:inventory:456"]

  {:ok, count} = EchoMQ.Job.get_dependencies_count(job)
  # 2

  {:ok, aggregate_match_results(children_values)}
end
```

> **Benefit**: `:telemetry` integration provides zero-cost event dispatch when no handlers are attached.

</tab>
<tab title="Go">

```go
// Go does not yet support FlowProducer or parent-child job relationships.
//
// What's missing:
//   - FlowProducer requires the addFlow Lua script, which orchestrates
//     creating parent + child jobs atomically with dependency tracking.
//   - The WAITING-CHILDREN state needs the parent to monitor a Redis
//     dependencies set (bull:{queue}:{jobId}:dependencies) that child
//     jobs remove themselves from upon completion.
//   - Go's queue_impl.go has no concept of parentKey or child dependencies.
//
// Workaround:
//   Use application-level coordination — enqueue children independently,
//   track completion via a shared counter or Redis key, and enqueue the
//   parent aggregation job when all children finish.
//
// See: PROTOCOL-GAPS.md for the full list of Go implementation gaps.
```

> **Benefit**: Rate limit config is declarative — the Lua script enforces limits atomically in Redis.

</tab>
<tab title="Node.js">

```typescript
const flow = new FlowProducer({ connection });

// After a match ends, update stats + grant rewards, then finalize
await flow.add({
  name: "match-complete",
  queueName: "matchmaking",
  data: { match_id: "MTH0K5M2vuIULY" },
  children: [
    { name: "update-score", data: { player_id: "PLR0K48QjihpC4", xp: 500 }, queueName: "leaderboard" },
    { name: "update-score", data: { player_id: "PLR3QR5T7V9W2X", xp: 300 }, queueName: "leaderboard" },
    { name: "drop-loot", data: { match_id: "MTH0K5M2vuIULY", tier: "epic" }, queueName: "inventory" },
  ],
});
```

> **Benefit**: FlowProducer class provides the reference implementation for complex job DAGs.

</tab>
</tabs>

---

## 13.3. State Transitions

### Normal Flow

```
add() --> WAITING --> ACTIVE --> COMPLETED
```

### With Delay

```
add(delay: X) --> DELAYED --> (timer expires) --> WAITING --> ACTIVE --> COMPLETED
```

### With Priority

```
add(priority: N) --> PRIORITIZED --> ACTIVE --> COMPLETED
```

### With Retry

```
add(attempts: 3)
  --> WAITING --> ACTIVE --> FAILED
                               |
                               +--> WAITING (retry 1, backoff delay)
                                       |
                                       +--> ACTIVE --> FAILED
                                                          |
                                                          +--> WAITING (retry 2)
                                                                  |
                                                                  +--> ACTIVE --> COMPLETED (or final FAILED)
```

### With Stall Recovery

```
WAITING --> ACTIVE --> (worker crashes, lock expires)
                           |
                           +--> STALLED --> WAITING (if retries left)
                                       +--> FAILED  (if no retries)
```

---

## 13.4. Retry Behavior

When a job fails, EchoMQ checks whether retries are available. The `attempts` option specifies the **total** number of processing attempts (1 initial + N-1 retries).

### Configuring Retries

<tabs>
<tab title="Elixir">

```elixir
# 3 total attempts (1 initial + 2 retries) for a flaky matchmaking service
{:ok, job} = EchoMQ.Queue.add("matchmaking", "find-match",
  %{player_id: "PLR0K48QjihpC4", rank: 1200, mode: "ranked"},
  connection: :redis,
  attempts: 3,
  backoff: %{type: :exponential, delay: 1000})

# Check retry eligibility from job struct
EchoMQ.Job.should_retry?(job)  #=> true (attempts_made + 1 < max_attempts)

# Calculate next backoff delay
delay_ms = EchoMQ.Job.calculate_backoff(job)  #=> milliseconds
```

The `should_retry?/1` function compares `attempts_made` against the `attempts` option stored in `job.opts`. The `calculate_backoff/1` function supports both atom (`:exponential`) and string (`"exponential"`) keys, handling both fresh Elixir jobs and jobs deserialized from Redis.

> **Benefit**: Custom backoff functions receive attempt count and error — full context for delay calculation.

</tab>
<tab title="Go">

```go
// Go configures retries at the worker level, not per-job.
worker := echomq.NewWorker("matchmaking", rdb, echomq.WorkerOptions{
    MaxAttempts:  3,
    BackoffDelay: time.Second,
})
```

Per-job attempt configuration is stored in `JobOptions.Attempts` and respected during failure handling.

> **Benefit**: Backoff configuration is declarative — `Type` and `Delay` fields are validated at compile time.

</tab>
<tab title="Node.js">

```typescript
await queue.add("find-match", {
  player_id: "PLR0K48QjihpC4", rank: 1200, mode: "ranked",
}, {
  attempts: 3,
  backoff: { type: "exponential", delay: 1000 },
});
```

> **Benefit**: Custom backoff functions return millisecond delay — simple numeric interface.

</tab>
</tabs>

### Backoff Strategies

| Strategy | Pattern | Example Delays |
|----------|---------|----------------|
| **fixed** | Same delay each retry | 1s, 1s, 1s, 1s |
| **exponential** | `2^(attempt-1) * delay` | 1s, 2s, 4s, 8s |

Exponential backoff in Elixir supports a `jitter` parameter (float 0.0-1.0) that adds randomization to prevent thundering-herd problems:

```elixir
backoff: %{type: :exponential, delay: 1000, jitter: 0.2}
# Base delays: 1s, 2s, 4s, 8s (each +/- 20% random)
# With jitter 0.2, a 4000ms base -> range 3200ms-4800ms
```

### Checking Retry Status in Workers

<tabs>
<tab title="Elixir">

```elixir
def process(%EchoMQ.Job{name: "find-match", attempts_made: attempts, data: data} = job) do
  Logger.info("Matchmaking attempt #{attempts + 1} for #{data["player_id"]}")

  case Fireheadz.Matchmaking.find_opponent(data["player_id"], data["rank"]) do
    {:ok, match} ->
      {:ok, match}

    {:error, :service_overloaded} when attempts < 4 ->
      # Transient error -- matchmaking service busy, will retry with backoff
      Logger.warning("Matchmaking overloaded, retrying for #{data["player_id"]}")
      {:error, :service_overloaded}

    {:error, :player_banned} ->
      # Permanent error -- don't waste retries
      {:ok, %{skipped: true, reason: :player_banned}}

    {:error, reason} ->
      {:error, reason}
  end
end
```

> **Benefit**: Custom backoff functions receive attempt count and error — full context for delay calculation.

</tab>
<tab title="Go">

```go
worker.Process(func(job *echomq.Job) (interface{}, error) {
    fmt.Printf("Matchmaking attempt %d for %s\n",
        job.AttemptsMade+1, job.Data["player_id"])

    match, err := findOpponent(job.Data["player_id"].(string), job.Data["rank"])
    if err != nil {
        // Go's error categorization determines retry behavior:
        // - Transient errors (service overloaded, timeout) -> retry
        // - Permanent errors (player banned, invalid rank) -> fail immediately
        return nil, err
    }
    return match, nil
})
```

> **Tradeoff**: Backoff must be implemented manually or via struct config — no built-in strategy pattern.

</tab>
<tab title="Node.js">

```typescript
const worker = new Worker("matchmaking", async (job) => {
  console.log(`Matchmaking attempt ${job.attemptsMade + 1} for ${job.data.player_id}`);

  try {
    return await findOpponent(job.data.player_id, job.data.rank);
  } catch (err) {
    if (err.code === "SERVICE_OVERLOADED" && job.attemptsMade < 4) {
      throw err; // Will retry with exponential backoff
    }
    // For permanent errors, throw UnrecoverableError
    throw new UnrecoverableError(err.message);
  }
}, { connection });
```

> **Benefit**: Custom backoff functions return millisecond delay — simple numeric interface.

</tab>
</tabs>

---

## 13.5. Manual Job Operations

### Retrying Failed Jobs

<tabs>
<tab title="Elixir">

```elixir
# Retry a failed matchmaking job (moves back to waiting)
{:ok, updated_job} = EchoMQ.Job.retry(job)

# Retry a completed trade job (re-process the trade)
{:ok, updated_job} = EchoMQ.Job.retry(job, :completed)

# Retry and reset attempt counters (fresh start)
{:ok, updated_job} = EchoMQ.Job.retry(job, :failed,
  reset_attempts_made: true,
  reset_attempts_started: true)
```

The `retry/3` function uses the `reprocessJob` Lua script to atomically move the job from its current state set back to the wait list. Error code `-1` means the job does not exist; `-3` means it was not found in the expected state.

> **Benefit**: Job promotion from delayed to waiting uses atomic Lua script — no race window.

</tab>
<tab title="Go">

```go
// Retry a failed matchmaking job (moves from failed queue back to wait)
err := queue.RetryJob(ctx, jobID)
if err != nil {
    log.Printf("Retry failed: %v", err)
}
```

`RetryJob` removes the job from the failed sorted set, resets `atm` (attemptsMade) to 0, clears `failedReason`, and pushes the job ID back onto the wait list. The operation uses a pipeline for atomicity with rollback on failure.

> **Benefit**: `queue.Remove(id)` issues a single Lua script call — O(1) regardless of queue size.

</tab>
<tab title="Node.js">

```typescript
// Retry a failed matchmaking job
await job.retry("failed");

// Retry a completed trade (re-process)
await job.retry("completed");
```

> **Benefit**: Built-in backoff strategies (`fixed`, `exponential`) with custom function support.

</tab>
</tabs>

### Moving Jobs Back to Wait

<tabs>
<tab title="Elixir">

```elixir
# Move an active matchmaking job back to wait (e.g., server full)
{:ok, _pttl} = EchoMQ.Job.move_to_wait(job, token)
```

This is useful when implementing rate limiting -- the processor can return `{:rate_limit, milliseconds}` to trigger this automatically. In a game context, you might requeue matchmaking jobs when a game server reaches capacity.

> **Benefit**: Rate limiting uses Redis TTL keys — distributed limiting works across clustered BEAM nodes.

</tab>
<tab title="Go">

```go
// Go does not expose a direct move-to-wait API for active jobs.
//
// What's missing:
//   - The BullMQ moveToWaitChildren Lua script can atomically move an
//     active job back to the wait list while preserving lock state.
//   - Go's worker handles retry-to-wait internally via retryJob(),
//     but this always applies backoff delay (moves to delayed set).
//
// Workaround:
//   For manual requeue without backoff, use RemoveJob + Add:
//     queue.RemoveJob(ctx, jobID)
//     queue.Add(ctx, jobName, jobData, echomq.JobOptions{})
//   This is NOT atomic — there is a brief window where the job exists
//   in neither queue. For rate-limiting patterns, consider using the
//   delayed queue with a short delay instead.
//
// See: PROTOCOL-GAPS.md (GAP-002 covers the non-atomic retry path).
```

> **Benefit**: Backoff configuration is declarative — `Type` and `Delay` fields are validated at compile time.

</tab>
<tab title="Node.js">

```typescript
// Rate limiting moves job back to wait automatically
// via the worker's limiter option — useful for capping
// matchmaking throughput when game servers are at capacity
```

> **Benefit**: `limiter` option integrates with BullMQ's built-in token bucket implementation.

</tab>
</tabs>

### Extending Lock Duration

<tabs>
<tab title="Elixir">

```elixir
# When manually processing a long pathfinding job, extend the lock
{:ok, _} = EchoMQ.Job.extend_lock(job, token, 30_000)
```

In normal operation, the `EchoMQ.Worker` handles lock renewal automatically via its heartbeat timer. Manual lock extension is only needed when processing jobs outside the worker framework.

> **Benefit**: LockManager batches all lock renewals into a single GenServer tick — O(1) timer overhead.

</tab>
<tab title="Go">

```go
// Go's HeartbeatManager handles lock renewal automatically.
// It extends the lock TTL at HeartbeatInterval (default: 15s)
// using the extendLock Lua script, which atomically verifies
// lock ownership before renewal (GAP-007 fixed).
//
// If renewal fails (lock was stolen), the worker cancels the
// job's processing context to prevent duplicate work.
```

The Go worker starts a `HeartbeatManager` that tracks all active job locks and renews them on a timer. If renewal fails, the job may be detected as stalled and requeued by the `StalledChecker`.

> **Tradeoff**: Lock extension requires periodic goroutine-based timers — manual lifecycle management.

</tab>
<tab title="Node.js">

```typescript
// BullMQ workers auto-renew locks via the lockRenewTime option
// Manual extension: await job.extendLock(token, duration)
```

> **Benefit**: Built-in lock extension runs automatically within the Worker class — transparent to processors.

</tab>
</tabs>

---

## 13.6. Job Events

Workers and queues emit events at each state transition, enabling monitoring and observability. In a game server, these events feed dashboards that track combat throughput, matchmaking latency, and trade volumes in real time.

<tabs>
<tab title="Elixir">

```elixir
# Worker-level callbacks for combat action monitoring
{EchoMQ.Worker,
  queue: "combat-actions",
  connection: :redis,
  processor: &Fireheadz.CombatProcessor.process/1,

  on_active: fn job ->
    Logger.info("Combat job #{job.id} started: #{job.name}")
  end,

  on_progress: fn job, progress ->
    Logger.info("Combat job #{job.id} progress: #{inspect(progress)}")
  end,

  on_completed: fn job, result ->
    Logger.info("Combat job #{job.id} resolved: #{inspect(result)}")
  end,

  on_failed: fn job, error ->
    Logger.error("Combat job #{job.id} failed: #{inspect(error)}")
  end,

  on_stalled: fn job_id ->
    Logger.warning("Combat job #{job_id} stalled — worker may have crashed")
  end,

  on_lock_renewal_failed: fn job_ids ->
    Logger.error("Lock renewal failed for: #{inspect(job_ids)}")
  end}
```

> **Benefit**: LockManager batches all lock renewals into a single GenServer tick — O(1) timer overhead.

</tab>
<tab title="Go">

```go
// Go emits events to the Redis event stream (bull:{queue}:events).
// The EventEmitter writes waiting, active, completed, and failed events.
// Application code can subscribe to the stream for real-time monitoring:
rdb.XRead(ctx, &redis.XReadArgs{
    Streams: []string{"bull:combat-actions:events", "$"},
    Block:   0,
})
```

> **Tradeoff**: Lock extension requires periodic goroutine-based timers — manual lifecycle management.

</tab>
<tab title="Node.js">

```typescript
// Worker events
worker.on("active", (job) => {
  console.log(`Combat job ${job.id} started: ${job.name}`);
});

worker.on("completed", (job, result) => {
  console.log(`Combat job ${job.id} resolved`);
});

worker.on("failed", (job, err) => {
  console.log(`Combat job ${job?.id} failed: ${err.message}`);
});

// Queue-level events (global, across all workers)
const events = new QueueEvents("combat-actions", { connection });
events.on("completed", ({ jobId, returnvalue }) => {
  console.log(`Combat action ${jobId} completed globally`);
});
```

> **Benefit**: EventEmitter pattern is native to Node.js — existing event-handling code works directly.

</tab>
</tabs>

---

## 13.7. Progress Tracking

Jobs can report progress during processing, which is persisted to Redis and observable by other processes. This is useful for long-running game operations like leaderboard recalculations or batch reward distributions.

<tabs>
<tab title="Elixir">

```elixir
def process(%EchoMQ.Job{name: "recalculate-rankings", data: data} = job) do
  players = Fireheadz.Leaderboard.get_all_players(data["season"])
  total = length(players)

  Enum.each(Enum.with_index(players, 1), fn {player, index} ->
    recalculate_rank(player, data["season"])

    # Numeric progress (0-100)
    EchoMQ.Job.update_progress(job, round(index / total * 100))

    # Or structured progress (any JSON-serializable map)
    # EchoMQ.Job.update_progress(job, %{current: index, total: total, season: data["season"]})
  end)

  {:ok, %{players_ranked: total}}
end
```

The `progress` field on the job struct supports both integer (0-100) and map values.

> **Benefit**: `EchoMQ.Job.update_progress/2` publishes to Redis streams — real-time progress tracking.

</tab>
<tab title="Go">

```go
worker.Process(func(job *echomq.Job) (interface{}, error) {
    players := job.Data["players"].([]interface{})
    total := len(players)

    for i, player := range players {
        recalculateRank(player, job.Data["season"].(string))
        progress := int(float64(i+1) / float64(total) * 100)
        job.UpdateProgress(progress)
    }

    return map[string]interface{}{"players_ranked": total}, nil
})
```

Go's `UpdateProgress` uses a Lua script for atomicity and automatically emits a progress event to the Redis stream.

> **Benefit**: Progress updates are published atomically via Lua script — no race conditions.

</tab>
<tab title="Node.js">

```typescript
const worker = new Worker("leaderboard", async (job) => {
  const players = job.data.players;
  for (let i = 0; i < players.length; i++) {
    await recalculateRank(players[i], job.data.season);
    await job.updateProgress(Math.round(((i + 1) / players.length) * 100));
  }
  return { players_ranked: players.length };
}, { connection });
```

> **Benefit**: `job.updateProgress()` triggers `progress` events on QueueEvents listeners.

</tab>
</tabs>

---

## 13.8. Job Logging

Jobs support structured log entries that are persisted in Redis, separate from application logs. This is invaluable for auditing game events -- tracking combat resolutions, trade history, and match outcomes at the individual job level.

<tabs>
<tab title="Elixir">

```elixir
def process(%EchoMQ.Job{data: data} = job) do
  EchoMQ.Job.log(job, "Starting combat resolution for room #{data["room_id"]}")

  case resolve_combat(data) do
    {:ok, result} ->
      EchoMQ.Job.log(job, "Damage dealt: #{result.damage} to #{data["target_id"]}")
      EchoMQ.Job.log(job, "Combat resolved — attacker=#{data["player_id"]}, outcome=#{result.outcome}")
      {:ok, result}

    {:error, reason} ->
      EchoMQ.Job.log(job, "Combat resolution failed: #{inspect(reason)}")
      {:error, reason}
  end
end

# Limit stored logs to prevent unbounded growth
EchoMQ.Job.log(job, "Turn complete", keep_logs: 100)
```

> **Benefit**: `:telemetry` integration provides zero-cost event dispatch when no handlers are attached.

</tab>
<tab title="Go">

```go
// Go does not expose a dedicated job.Log() API method.
// Job logs are stored as a Redis list at bull:{queue}:{job_id}:logs.
// You can write log entries directly via Redis RPUSH:
func logJobEvent(ctx context.Context, rdb redis.Cmdable, queueName, jobID, message string) error {
    key := fmt.Sprintf("bull:%s:%s:logs", queueName, jobID)
    return rdb.RPush(ctx, key, message).Err()
}

// Usage in a worker processor:
worker.Process(func(job *echomq.Job) (interface{}, error) {
    logJobEvent(ctx, rdb, "combat-actions", job.ID,
        fmt.Sprintf("Starting combat resolution for room %s", job.Data["room_id"]))

    result, err := resolveCombat(job.Data)
    if err != nil {
        logJobEvent(ctx, rdb, "combat-actions", job.ID,
            fmt.Sprintf("Combat failed: %v", err))
        return nil, err
    }

    logJobEvent(ctx, rdb, "combat-actions", job.ID,
        fmt.Sprintf("Damage dealt: %d to %s", result.Damage, job.Data["target_id"]))
    return result, nil
})
```

The Go implementation stores logs in the same Redis list format (`bull:{queue}:{job_id}:logs`) as Node.js and Elixir, so logs written by Go are readable by all runtimes. The `addLog` Lua script is available in `scripts/scripts.go` but not yet wired to a Go API method.

> **Benefit**: Channel-based event delivery integrates naturally with Go's select statement for multiplexing.

</tab>
<tab title="Node.js">

```typescript
const worker = new Worker("combat-actions", async (job) => {
  await job.log(`Starting combat resolution for room ${job.data.room_id}`);

  try {
    const result = await resolveCombat(job.data);
    await job.log(`Damage dealt: ${result.damage} to ${job.data.target_id}`);
    await job.log(`Combat resolved — attacker=${job.data.player_id}, outcome=${result.outcome}`);
    return result;
  } catch (err) {
    await job.log(`Combat resolution failed: ${err.message}`);
    throw err;
  }
}, { connection });

// Retrieve logs for audit
const logs = await queue.getJobLogs(job.id);
console.log(logs.logs); // ["Starting combat...", "Damage dealt...", ...]
```

> **Benefit**: `ioredis` connection with lazy initialization — Redis connects only when the first command is issued.

</tab>
</tabs>

Job logs are stored in a Redis list at `bull:{queue}:{job_id}:logs` and can be retrieved for debugging or audit purposes. Unlike application logs that scatter across services, job logs travel with the job itself -- making them ideal for game audit trails where you need to reconstruct exactly what happened during a specific combat encounter or trade.

---

## 13.9. What's Next

- [Job Options](ch14-job-options.md) -- Priority, delay, retries, backoff, and cleanup configuration
- [Jobs Overview](ch12-jobs-overview.md) -- Job structure, types, and data handling
- [Cross-Language Interop](ch06-cross-language-interop.md) -- Feature matrix and known divergences

---

*Previous: [Jobs Overview](ch12-jobs-overview.md) | Next: [Job Options](ch14-job-options.md)*
