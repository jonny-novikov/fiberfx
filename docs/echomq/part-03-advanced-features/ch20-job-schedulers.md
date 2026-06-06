# Chapter 20. Job Schedulers

A Job Scheduler is a factory that produces jobs on a recurring basis. Rather than manually creating delayed jobs in a loop, you declare a schedule once and the system handles the rest: calculating the next execution time, creating the delayed job, preventing duplicates through upsert semantics, and tracking iteration counts. Each runtime implements the same Redis-backed scheduling protocol, but Go does not yet have a native `JobScheduler` abstraction.

## 20.1. Scheduler Architecture

```
JobScheduler (Redis sorted set: bull:{queue}:repeat)
  |
  +-- Scheduler "season-reset" (score = next execution timestamp)
  |     |
  |     +-- template: {name: "reset-season", data: {season_id: "S7"}}
  |     +-- repeat: {pattern: "0 0 1 * *", tz: "UTC"}
  |     +-- iteration_count: 3
  |     |
  |     +-- Produces --> Job in delayed set (bull:{queue}:delayed)
  |                       |
  |                       +-- When picked up by worker, next job is created
  |
  +-- Scheduler "npc-respawn-forest" (score = next execution timestamp)
  |     |
  |     +-- template: {name: "respawn-npc", data: {zone: "enchanted-forest"}}
  |     +-- repeat: {every: 300_000}
  |     +-- iteration_count: 1847
  |     |
  |     +-- Produces --> Job in delayed set
  |
  +-- Scheduler "daily-rewards" (score = next execution timestamp)
        |
        +-- template: {name: "grant-rewards", data: {type: "login"}}
        +-- repeat: {pattern: "0 9 * * *", tz: "America/New_York"}
        +-- iteration_count: 42
```

Each scheduler entry is stored as a member of a Redis sorted set keyed by `bull:{queue}:repeat`. The score is the next execution timestamp in milliseconds. When the scheduler produces a job, it increments `iteration_count` and recalculates the score for the next firing.

## 20.2. Creating a Scheduler

### Interval-Based Scheduling

Interval-based schedulers fire every N milliseconds. This is the simplest and most cross-platform-compatible mode.

<tabs>
<tab title="Elixir">

```elixir
# NPC respawn: every 5 minutes per zone
{:ok, job} = EchoMQ.JobScheduler.upsert(
  :arena_redis,
  "world-sync",
  "npc-respawn-forest",
  %{every: 300_000},
  "respawn-npc",
  %{zone: "enchanted-forest", npc_types: ["goblin", "treant", "fairy"]},
  priority: 3
)

IO.puts("Next NPC respawn job: #{job.id}, delay: #{job.delay}ms")
```

The `upsert/7` function takes the Redis connection, queue name, a unique scheduler ID, repeat options, job name, job data, and optional job options as a keyword list. If a scheduler with ID `"npc-respawn-forest"` already exists, it is updated rather than duplicated.

> **Benefit**: GenServer-based schedulers integrate with supervision — restarts guarantee schedule continuity.

</tab>
<tab title="Go">

```go
// Feature: JobScheduler (recurring job creation)
//
// Not yet implemented in echomq-go. BullMQ's JobScheduler creates
// jobs on a recurring schedule using cron expressions or fixed intervals,
// with upsert semantics to prevent duplicate schedulers.
//
// Workaround:
//   Use an external cron library (github.com/robfig/cron/v3) to
//   trigger queue.Add() calls on a schedule. Store scheduler state
//   in a Redis hash for persistence across restarts.
//
// Reference: Ch 17 Worker Patterns — Protocol Gap Summary Table

// Example workaround using robfig/cron:
c := cron.New(cron.WithSeconds())
c.AddFunc("0 */5 * * * *", func() {
    queue.Add(ctx, "respawn-npc", map[string]interface{}{
        "zone":      "enchanted-forest",
        "npc_types": []string{"goblin", "treant", "fairy"},
    }, echomq.JobOptions{Priority: 3})
})
c.Start()
defer c.Stop()
```

> **Tradeoff**: Go has no built-in cron — scheduler must use `time.Ticker` or external cron library.

</tab>
<tab title="Node.js">

```typescript
import { Queue } from "bullmq";

const queue = new Queue("world-sync", {
  connection: { host: "localhost", port: 6379 },
});

// NPC respawn: every 5 minutes per zone
const job = await queue.upsertJobScheduler(
  "npc-respawn-forest",
  { every: 300_000 },
  {
    name: "respawn-npc",
    data: { zone: "enchanted-forest", npc_types: ["goblin", "treant", "fairy"] },
    opts: { priority: 3 },
  }
);

console.log(`Next NPC respawn job: ${job.id}, delay: ${job.delay}ms`);
```

> **Benefit**: `upsertJobScheduler` is Redis-persisted and idempotent — safe across process restarts.

</tab>
</tabs>

> **⚠️ Go Gap**: JobScheduler (cron and interval-based repeatable jobs) is not implemented.
> **Proposed Solution**: Implement `JobScheduler.Upsert()` using `addJobScheduler` Lua script with 5-field cron parsing (use `robfig/cron/v3` library). Add scheduler goroutine to check and enqueue jobs at tick intervals.

### Cron-Based Scheduling

Cron-based schedulers use standard 5-field cron expressions for time-of-day or calendar-based patterns.

<tabs>
<tab title="Elixir">

```elixir
# Season reset: first day of every month at midnight UTC
{:ok, job} = EchoMQ.JobScheduler.upsert(
  :arena_redis,
  "game-admin",
  "season-reset",
  %{pattern: "0 0 1 * *"},
  "reset-season",
  %{season_id: "S7", rewards: true, leaderboard_snapshot: true},
  priority: 1, attempts: 3
)

# Daily login rewards: 9 AM Eastern (handles DST)
{:ok, job} = EchoMQ.JobScheduler.upsert(
  :arena_redis,
  "player-events",
  "daily-rewards",
  %{pattern: "0 9 * * *", tz: "America/New_York"},
  "grant-rewards",
  %{type: "login", currency: "gold", base_amount: 100},
  []
)
```

The `:tz` option ensures cron evaluation respects the target timezone, including DST transitions. When DST springs forward (2 AM becomes 3 AM), a `"0 2 * * *"` job skips that night. When DST falls back, it fires once (not twice).

> **Benefit**: GenServer-based schedulers integrate with supervision — restarts guarantee schedule continuity.

</tab>
<tab title="Go">

```go
// Feature: JobScheduler (cron-based recurring job creation)
//
// Not yet implemented in echomq-go. BullMQ's JobScheduler creates
// jobs on a recurring schedule using cron expressions or fixed intervals,
// with upsert semantics to prevent duplicate schedulers.
//
// Workaround:
//   Use an external cron library (github.com/robfig/cron/v3) to
//   trigger queue.Add() calls on a schedule. Store scheduler state
//   in a Redis hash for persistence across restarts.
//
// Reference: Ch 17 Worker Patterns — Protocol Gap Summary Table

// Example workaround:
loc, _ := time.LoadLocation("America/New_York")
c := cron.New(cron.WithLocation(loc))

// Season reset: first day of every month at midnight
c.AddFunc("0 0 1 * *", func() {
    queue.Add(ctx, "reset-season", map[string]interface{}{
        "season_id": "S7", "rewards": true, "leaderboard_snapshot": true,
    }, echomq.JobOptions{Priority: 1, Attempts: 3})
})

// Daily login rewards at 9 AM Eastern
c.AddFunc("0 9 * * *", func() {
    queue.Add(ctx, "grant-rewards", map[string]interface{}{
        "type": "login", "currency": "gold", "base_amount": 100,
    }, echomq.JobOptions{})
})

c.Start()
```

> **Tradeoff**: Go has no built-in cron — scheduler must use `time.Ticker` or external cron library.

</tab>
<tab title="Node.js">

```typescript
// Season reset: first day of every month at midnight UTC
await queue.upsertJobScheduler(
  "season-reset",
  { pattern: "0 0 1 * *" },
  {
    name: "reset-season",
    data: { season_id: "S7", rewards: true, leaderboard_snapshot: true },
    opts: { priority: 1, attempts: 3 },
  }
);

// Daily login rewards: 9 AM Eastern (handles DST)
await queue.upsertJobScheduler(
  "daily-rewards",
  { pattern: "0 9 * * *", tz: "America/New_York" },
  {
    name: "grant-rewards",
    data: { type: "login", currency: "gold", base_amount: 100 },
  }
);
```

> **Benefit**: `upsertJobScheduler` is Redis-persisted and idempotent — safe across process restarts.

</tab>
</tabs>

## 20.3. Upsert Semantics

The core design principle of JobScheduler is **upsert** (create-or-update). Calling `upsert` with the same scheduler ID either creates a new scheduler or updates the existing one. This prevents duplicate schedulers across deployments and makes configuration changes safe.

<tabs>
<tab title="Elixir">

```elixir
# First deploy: NPC respawn every 5 minutes
{:ok, _job} = EchoMQ.JobScheduler.upsert(
  :arena_redis, "world-sync", "npc-respawn-forest",
  %{every: 300_000},
  "respawn-npc",
  %{zone: "enchanted-forest", npc_types: ["goblin", "treant"]},
  []
)

# Second deploy: changed to 3 minutes, added "fairy" NPC type
# Same scheduler ID = update, not duplicate
{:ok, _job} = EchoMQ.JobScheduler.upsert(
  :arena_redis, "world-sync", "npc-respawn-forest",
  %{every: 180_000},
  "respawn-npc",
  %{zone: "enchanted-forest", npc_types: ["goblin", "treant", "fairy"]},
  []
)

# Result: ONE scheduler with the updated config, not two
{:ok, count} = EchoMQ.JobScheduler.count(:arena_redis, "world-sync")
# => {:ok, 1}
```

> **Benefit**: GenServer-based schedulers integrate with supervision — restarts guarantee schedule continuity.

</tab>
<tab title="Go">

```go
// Feature: JobScheduler upsert semantics
//
// Not yet implemented in echomq-go. Upsert ensures that calling
// the same scheduler ID twice updates rather than duplicates.
//
// Workaround:
//   Maintain a Redis hash mapping scheduler IDs to their current
//   config. Before adding a new cron entry, check if one exists
//   and remove the old entry first.
//
// Reference: Ch 17 Worker Patterns — Protocol Gap Summary Table

// Manual upsert pattern:
func upsertScheduler(rdb *redis.Client, id, cronExpr string) error {
    key := "scheduler:config:" + id
    existing, _ := rdb.HGet(ctx, key, "cron").Result()
    if existing != "" {
        // Remove old cron entry, add new one
    }
    return rdb.HSet(ctx, key, "cron", cronExpr).Err()
}
```

> **Tradeoff**: Go has no built-in cron — scheduler must use `time.Ticker` or external cron library.

</tab>
<tab title="Node.js">

```typescript
// First deploy: NPC respawn every 5 minutes
await queue.upsertJobScheduler(
  "npc-respawn-forest",
  { every: 300_000 },
  {
    name: "respawn-npc",
    data: { zone: "enchanted-forest", npc_types: ["goblin", "treant"] },
  }
);

// Second deploy: changed to 3 minutes, added "fairy" NPC type
// Same scheduler ID = update, not duplicate
await queue.upsertJobScheduler(
  "npc-respawn-forest",
  { every: 180_000 },
  {
    name: "respawn-npc",
    data: { zone: "enchanted-forest", npc_types: ["goblin", "treant", "fairy"] },
  }
);

// Result: ONE scheduler with the updated config
const count = await queue.getJobSchedulersCount();
console.log(count); // 1
```

> **Benefit**: `upsertJobScheduler` is Redis-persisted and idempotent — safe across process restarts.

</tab>
</tabs>

This is essential for game servers where multiple application instances boot simultaneously. Without upsert, each instance would create its own scheduler, producing N copies of every recurring job.

## 20.4. Repeat Options Reference

| Option | Type | Description | Default |
|--------|------|-------------|---------|
| `every` | integer | Interval in milliseconds (mutually exclusive with `pattern`) | -- |
| `pattern` | string | 5-field cron expression (mutually exclusive with `every`) | -- |
| `limit` | integer | Maximum number of job productions before the scheduler stops | unlimited |
| `start_date` | DateTime/integer | Earliest time the scheduler will produce jobs | now |
| `end_date` | DateTime/integer | Latest time the scheduler will produce jobs | unlimited |
| `tz` | string | IANA timezone for cron evaluation (e.g., `"America/New_York"`) | `"UTC"` |
| `immediately` | boolean | Produce the first job immediately instead of waiting for the first interval/cron tick | false |
| `offset` | integer | Millisecond offset applied to interval-based scheduling | 0 |

Validation rules:
- You must specify exactly one of `every` or `pattern` (not both, not neither).
- `immediately` and `start_date` are mutually exclusive.
- If `limit` is reached, subsequent `upsert` calls return `{:error, :limit_reached}`.
- If `end_date` is in the past, `upsert` returns `{:error, :end_date_reached}`.

## 20.5. Managing Schedulers

### Get a Scheduler

<tabs>
<tab title="Elixir">

```elixir
{:ok, scheduler} = EchoMQ.JobScheduler.get(:arena_redis, "world-sync", "npc-respawn-forest")

# Returns:
# %{
#   key: "npc-respawn-forest",
#   name: "respawn-npc",
#   every: 300_000,
#   next: 1738972800000,
#   iteration_count: 1847,
#   template: %{
#     data: %{"zone" => "enchanted-forest", "npc_types" => [...]},
#     opts: %{"priority" => 3}
#   }
# }

IO.puts("Next respawn at: #{DateTime.from_unix!(scheduler.next, :millisecond)}")
IO.puts("Total respawns so far: #{scheduler.iteration_count}")
```

> **Benefit**: GenServer-based schedulers integrate with supervision — restarts guarantee schedule continuity.

</tab>
<tab title="Go">

```go
// Feature: JobScheduler.get (retrieve scheduler by ID)
//
// Not yet implemented in echomq-go. Retrieves scheduler metadata
// including next execution time, iteration count, and template.
//
// Workaround:
//   Read the scheduler's sorted set entry and hash directly:
//   ZSCORE bull:{queue}:repeat {scheduler_id}  -- next timestamp
//   HGETALL bull:{queue}:repeat:{scheduler_id} -- scheduler data
//
// Reference: Ch 17 Worker Patterns — Protocol Gap Summary Table

score, _ := rdb.ZScore(ctx, "bull:world-sync:repeat", "npc-respawn-forest").Result()
fmt.Printf("Next respawn at: %v\n", time.UnixMilli(int64(score)))
```

> **Tradeoff**: Go has no built-in cron — scheduler must use `time.Ticker` or external cron library.

</tab>
<tab title="Node.js">

```typescript
const scheduler = await queue.getJobScheduler("npc-respawn-forest");

console.log(`Next respawn at: ${new Date(scheduler.next)}`);
console.log(`Total respawns: ${scheduler.iterationCount}`);
console.log(`Template data: ${JSON.stringify(scheduler.template.data)}`);
```

> **Benefit**: `upsertJobScheduler` is Redis-persisted and idempotent — safe across process restarts.

</tab>
</tabs>

### List All Schedulers

<tabs>
<tab title="Elixir">

```elixir
# List all schedulers for the world-sync queue
{:ok, schedulers} = EchoMQ.JobScheduler.list(:arena_redis, "world-sync")

Enum.each(schedulers, fn s ->
  next_dt = DateTime.from_unix!(s.next, :millisecond)
  IO.puts("  #{s.key}: next=#{next_dt}, iterations=#{s[:iteration_count] || 0}")
end)

# With pagination (ascending order, first 10)
{:ok, page} = EchoMQ.JobScheduler.list(:arena_redis, "world-sync",
  start: 0,
  end: 9,
  asc: true
)
```

> **Benefit**: GenServer-based schedulers integrate with supervision — restarts guarantee schedule continuity.

</tab>
<tab title="Go">

```go
// Feature: JobScheduler.list (enumerate schedulers with pagination)
//
// Not yet implemented in echomq-go.
//
// Workaround:
//   Use ZRANGE/ZREVRANGE on the sorted set directly:
//   ZRANGE bull:{queue}:repeat 0 -1 WITHSCORES
//
// Reference: Ch 17 Worker Patterns — Protocol Gap Summary Table

results, _ := rdb.ZRangeWithScores(ctx, "bull:world-sync:repeat", 0, -1).Result()
for _, z := range results {
    fmt.Printf("Scheduler: %s, next: %v\n", z.Member, time.UnixMilli(int64(z.Score)))
}
```

> **Tradeoff**: Go has no built-in cron — scheduler must use `time.Ticker` or external cron library.

</tab>
<tab title="Node.js">

```typescript
// List all schedulers
const schedulers = await queue.getJobSchedulers();
for (const s of schedulers) {
  console.log(`${s.id}: next=${new Date(s.next)}, iterations=${s.iterationCount}`);
}

// With pagination (ascending, first 10)
const page = await queue.getJobSchedulers(0, 9, true);
```

> **Benefit**: `upsertJobScheduler` is Redis-persisted and idempotent — safe across process restarts.

</tab>
</tabs>

### Count Schedulers

<tabs>
<tab title="Elixir">

```elixir
{:ok, count} = EchoMQ.JobScheduler.count(:arena_redis, "world-sync")
IO.puts("Active schedulers: #{count}")
```

> **Benefit**: GenServer-based schedulers integrate with supervision — restarts guarantee schedule continuity.

</tab>
<tab title="Go">

```go
// Workaround: ZCARD on the sorted set
count, _ := rdb.ZCard(ctx, "bull:world-sync:repeat").Result()
fmt.Printf("Active schedulers: %d\n", count)
```

> **Tradeoff**: Go has no built-in cron — scheduler must use `time.Ticker` or external cron library.

</tab>
<tab title="Node.js">

```typescript
const count = await queue.getJobSchedulersCount();
console.log(`Active schedulers: ${count}`);
```

> **Benefit**: `upsertJobScheduler` is Redis-persisted and idempotent — safe across process restarts.

</tab>
</tabs>

### Remove a Scheduler

<tabs>
<tab title="Elixir">

```elixir
# Remove the NPC respawn scheduler for a zone being retired
{:ok, true} = EchoMQ.JobScheduler.remove(:arena_redis, "world-sync", "npc-respawn-forest")

# Returns {:ok, false} if the scheduler didn't exist
{:ok, false} = EchoMQ.JobScheduler.remove(:arena_redis, "world-sync", "nonexistent")
```

Removing a scheduler also removes its next pending delayed job from the queue, preventing orphaned jobs from firing after the scheduler is gone.

> **Benefit**: GenServer-based schedulers integrate with supervision — restarts guarantee schedule continuity.

</tab>
<tab title="Go">

```go
// Feature: JobScheduler.remove (delete scheduler and pending job)
//
// Not yet implemented in echomq-go.
//
// Workaround:
//   Remove from sorted set and clean up the pending delayed job:
//   ZREM bull:{queue}:repeat {scheduler_id}
//   Then find and remove the associated delayed job by its repeatJobKey.
//
// Reference: Ch 17 Worker Patterns — Protocol Gap Summary Table

rdb.ZRem(ctx, "bull:world-sync:repeat", "npc-respawn-forest")
```

> **Tradeoff**: Go has no built-in cron — scheduler must use `time.Ticker` or external cron library.

</tab>
<tab title="Node.js">

```typescript
// Remove the NPC respawn scheduler for a retired zone
const removed = await queue.removeJobScheduler("npc-respawn-forest");
console.log(`Removed: ${removed}`); // true or false
```

> **Benefit**: `upsertJobScheduler` is Redis-persisted and idempotent — safe across process restarts.

</tab>
</tabs>

## 20.6. Job Production Timing

Understanding how and when schedulers produce jobs is critical for game servers where timing precision matters.

### Production Flow

1. When you call `upsert`, the **first job** is created immediately in the `delayed` set with a calculated delay
2. The delayed job waits until its scheduled time, then moves to `wait` (or `prioritized`)
3. A worker picks up the job and starts processing
4. When the job **starts processing** (not when it completes), the **next job** is scheduled
5. This chain continues until `limit` or `end_date` is reached

### Timing Implications

<tabs>
<tab title="Elixir">

```elixir
# Gold sink event: hourly during a special event window
# If every: 3_600_000 (1 hour) and processing takes 10 seconds:
#
# T+0:00:00  Job 1 moves to active, Job 2 created (scheduled for T+1:00:00)
# T+0:00:10  Job 1 completes
# T+1:00:00  Job 2 moves to active, Job 3 created (scheduled for T+2:00:00)
# T+1:00:10  Job 2 completes
#
# The interval measures start-to-start, not end-to-start.
# If the queue is backed up, jobs may start late but the next
# job is still scheduled relative to the original timeline.

{:ok, _job} = EchoMQ.JobScheduler.upsert(
  :arena_redis,
  "game-events",
  "gold-sink-hourly",
  %{
    every: 3_600_000,
    start_date: ~U[2026-02-14 18:00:00Z],
    end_date: ~U[2026-02-14 23:00:00Z]
  },
  "gold-sink-tick",
  %{event: "valentines-sale", discount_pct: 50},
  []
)
```

> **Benefit**: GenServer-based schedulers integrate with supervision — restarts guarantee schedule continuity.

</tab>
<tab title="Go">

```go
// Gold sink event: hourly during a special event window
//
// Job production timing works the same at the Redis protocol level:
// each job is created when the previous one starts processing.
//
// With the cron workaround, timing is driven by the cron library
// rather than Redis, so jobs are created independently of processing.

c.AddFunc("0 * * * *", func() {
    now := time.Now().UTC()
    start := time.Date(2026, 2, 14, 18, 0, 0, 0, time.UTC)
    end := time.Date(2026, 2, 14, 23, 0, 0, 0, time.UTC)

    if now.After(start) && now.Before(end) {
        queue.Add(ctx, "gold-sink-tick", map[string]interface{}{
            "event": "valentines-sale", "discount_pct": 50,
        }, echomq.JobOptions{})
    }
})
```

> **Benefit**: Channel-based event delivery integrates naturally with Go's select statement for multiplexing.

</tab>
<tab title="Node.js">

```typescript
// Gold sink event: hourly during a special event window
await queue.upsertJobScheduler(
  "gold-sink-hourly",
  {
    every: 3_600_000,
    startDate: new Date("2026-02-14T18:00:00Z"),
    endDate: new Date("2026-02-14T23:00:00Z"),
  },
  {
    name: "gold-sink-tick",
    data: { event: "valentines-sale", discount_pct: 50 },
  }
);
```

> **Benefit**: `upsertJobScheduler` is Redis-persisted and idempotent — safe across process restarts.

</tab>
</tabs>

> **Important:** If no workers are running, scheduled jobs accumulate in the `delayed` set but new jobs are **not** produced (since production is triggered by job processing). When workers come back online, only the most recent pending job fires -- the scheduler does not "catch up" on missed intervals.

## 20.7. Bounded Scheduling

Schedulers support date bounds and iteration limits to constrain job production. This is essential for time-limited game events.

<tabs>
<tab title="Elixir">

```elixir
# Tournament schedule: every Saturday at 8 PM UTC for 6 weeks
{:ok, job} = EchoMQ.JobScheduler.upsert(
  :arena_redis,
  "game-events",
  "weekend-tournament",
  %{
    pattern: "0 20 * * 6",
    start_date: ~U[2026-03-01 00:00:00Z],
    end_date: ~U[2026-04-12 23:59:59Z],
    limit: 6
  },
  "start-tournament",
  %{format: "battle-royale", entry_fee: 500, prize_pool: 50_000},
  priority: 1, attempts: 3
)

# Check how many tournaments have fired
{:ok, scheduler} = EchoMQ.JobScheduler.get(:arena_redis, "game-events", "weekend-tournament")
IO.puts("Tournaments held: #{scheduler.iteration_count}/#{scheduler.limit}")
```

> **Benefit**: GenServer-based schedulers integrate with supervision — restarts guarantee schedule continuity.

</tab>
<tab title="Go">

```go
// Feature: Bounded scheduling (start_date, end_date, limit)
//
// Not yet implemented in echomq-go. BullMQ's JobScheduler supports
// date bounds and iteration limits to constrain job production.
//
// Workaround:
//   Track iteration count in Redis and check bounds manually:
//   HINCRBY scheduler:weekend-tournament iterations 1
//   Compare against limit before adding the next job.
//
// Reference: Ch 17 Worker Patterns — Protocol Gap Summary Table

loc, _ := time.LoadLocation("UTC")
c := cron.New(cron.WithLocation(loc))

c.AddFunc("0 20 * * 6", func() {
    now := time.Now().UTC()
    start := time.Date(2026, 3, 1, 0, 0, 0, 0, time.UTC)
    end := time.Date(2026, 4, 12, 23, 59, 59, 0, time.UTC)

    if now.Before(start) || now.After(end) {
        return
    }

    count, _ := rdb.HIncrBy(ctx, "scheduler:weekend-tournament", "iterations", 1).Result()
    if count > 6 {
        return
    }

    queue.Add(ctx, "start-tournament", map[string]interface{}{
        "format": "battle-royale", "entry_fee": 500, "prize_pool": 50000,
    }, echomq.JobOptions{Priority: 1, Attempts: 3})
})
```

> **Tradeoff**: Go has no built-in cron — scheduler must use `time.Ticker` or external cron library.

</tab>
<tab title="Node.js">

```typescript
// Tournament schedule: every Saturday at 8 PM UTC for 6 weeks
await queue.upsertJobScheduler(
  "weekend-tournament",
  {
    pattern: "0 20 * * 6",
    startDate: new Date("2026-03-01T00:00:00Z"),
    endDate: new Date("2026-04-12T23:59:59Z"),
    limit: 6,
  },
  {
    name: "start-tournament",
    data: { format: "battle-royale", entry_fee: 500, prize_pool: 50000 },
    opts: { priority: 1, attempts: 3 },
  }
);

// Check iteration count
const scheduler = await queue.getJobScheduler("weekend-tournament");
console.log(`Tournaments held: ${scheduler.iterationCount}/${scheduler.limit}`);
```

> **Benefit**: `upsertJobScheduler` is Redis-persisted and idempotent — safe across process restarts.

</tab>
</tabs>

## 20.8. Job Options for Produced Jobs

Each job created by a scheduler inherits the options you pass to `upsert`. This lets you control priority, retry behavior, and cleanup for every produced job.

<tabs>
<tab title="Elixir">

```elixir
# NPC respawn with retry and auto-cleanup
{:ok, job} = EchoMQ.JobScheduler.upsert(
  :arena_redis,
  "world-sync",
  "npc-respawn-dungeon",
  %{every: 300_000},
  "respawn-npc",
  %{zone: "shadow-dungeon", npc_types: ["skeleton", "lich", "wraith"]},
  priority: 2,
  attempts: 5,
  backoff: %{type: "exponential", delay: 2_000},
  remove_on_complete: %{age: 3_600},
  remove_on_fail: %{age: 86_400}
)
```

Every job produced by this scheduler will have priority 2, up to 5 attempts with exponential backoff starting at 2 seconds, auto-removal of completed jobs after 1 hour, and auto-removal of failed jobs after 24 hours.

> **Benefit**: Custom backoff functions receive attempt count and error — full context for delay calculation.

</tab>
<tab title="Go">

```go
// Feature: Template job options for scheduled jobs
//
// Not yet implemented in echomq-go. With the cron workaround,
// pass options directly to each queue.Add() call.
//
// Reference: Ch 17 Worker Patterns — Protocol Gap Summary Table

c.AddFunc("0 */5 * * * *", func() {
    queue.Add(ctx, "respawn-npc", map[string]interface{}{
        "zone": "shadow-dungeon", "npc_types": []string{"skeleton", "lich", "wraith"},
    }, echomq.JobOptions{
        Priority:  2,
        Attempts:  5,
        BackoffDelay: 2 * time.Second,
    })
})
```

> **Benefit**: Backoff configuration is declarative — `Type` and `Delay` fields are validated at compile time.

</tab>
<tab title="Node.js">

```typescript
// NPC respawn with retry and auto-cleanup
await queue.upsertJobScheduler(
  "npc-respawn-dungeon",
  { every: 300_000 },
  {
    name: "respawn-npc",
    data: { zone: "shadow-dungeon", npc_types: ["skeleton", "lich", "wraith"] },
    opts: {
      priority: 2,
      attempts: 5,
      backoff: { type: "exponential", delay: 2000 },
      removeOnComplete: { age: 3600 },
      removeOnFail: { age: 86400 },
    },
  }
);
```

> **Benefit**: Custom backoff functions return millisecond delay — simple numeric interface.

</tab>
</tabs>

## 20.9. Error Handling

<tabs>
<tab title="Elixir">

```elixir
case EchoMQ.JobScheduler.upsert(
  :arena_redis, "world-sync", scheduler_id, repeat_opts, name, data, opts
) do
  {:ok, job} ->
    Logger.info("Scheduler active — next job #{job.id} fires in #{job.delay}ms")

  {:error, :both_pattern_and_every} ->
    Logger.error("Specify either :pattern or :every, not both")

  {:error, :no_pattern_or_every} ->
    Logger.error("Must specify :pattern (cron) or :every (interval)")

  {:error, :immediately_with_start_date} ->
    Logger.error("Cannot use :immediately with :start_date")

  {:error, :limit_reached} ->
    Logger.info("Scheduler has reached its iteration limit — no more jobs will be produced")

  {:error, :end_date_reached} ->
    Logger.info("Scheduler end date has passed — no more jobs will be produced")

  {:error, :job_id_collision} ->
    Logger.error("Job ID collision — another job with the computed ID already exists")

  {:error, :job_slots_busy} ->
    Logger.warning("Both current and next time slots have pending jobs — skipping this tick")

  {:error, {:invalid_scheduler_id, message}} ->
    Logger.error("Invalid scheduler ID: #{message}")

  {:error, reason} ->
    Logger.error("Scheduler error: #{inspect(reason)}")
end
```

The `:job_slots_busy` error is a safety mechanism. Each scheduler maintains at most two jobs in flight (the current and the next). If both slots are occupied (e.g., workers are slow), the scheduler skips rather than accumulating unbounded jobs.

> **Benefit**: GenServer-based schedulers integrate with supervision — restarts guarantee schedule continuity.

</tab>
<tab title="Go">

```go
// Error handling with the cron workaround is simpler since the
// scheduler logic is external. Handle queue.Add errors directly:

err := queue.Add(ctx, "respawn-npc", data, opts)
if err != nil {
    log.Printf("Failed to add scheduled job: %v", err)
    // Retry logic or alerting here
}
```

> **Tradeoff**: Go has no built-in cron — scheduler must use `time.Ticker` or external cron library.

</tab>
<tab title="Node.js">

```typescript
try {
  const job = await queue.upsertJobScheduler(schedulerId, repeatOpts, {
    name: jobName,
    data: jobData,
    opts: jobOpts,
  });
  console.log(`Scheduler active — next job ${job.id} fires in ${job.delay}ms`);
} catch (err) {
  if (err.message.includes("limit reached")) {
    console.log("Scheduler reached its iteration limit");
  } else if (err.message.includes("end date")) {
    console.log("Scheduler end date has passed");
  } else {
    console.error(`Scheduler error: ${err.message}`);
  }
}
```

> **Benefit**: `upsertJobScheduler` is Redis-persisted and idempotent — safe across process restarts.

</tab>
</tabs>

## 20.10. Scheduler ID Validation

Scheduler IDs must have fewer than 5 colon-separated parts. This prevents confusion with the legacy repeatable jobs format, which used colon-separated composite keys like `"name:pattern:tz:endDate:every"`.

<tabs>
<tab title="Elixir">

```elixir
# Valid scheduler IDs
"npc-respawn-forest"           # simple slug
"zone:enchanted-forest"        # 2 parts (OK)
"region:us-east:zone:forest"   # 4 parts (OK, max)

# Invalid scheduler ID (5+ colon-separated parts)
"name:*/5 * * * *:UTC:0:300000"  # Legacy format — rejected
# => {:error, {:invalid_scheduler_id, "Scheduler ID '...' contains 5 colon-separated parts..."}}
```

> **Benefit**: GenServer-based schedulers integrate with supervision — restarts guarantee schedule continuity.

</tab>
<tab title="Go">

```go
// Scheduler ID validation is handled at the protocol level.
// When using the cron workaround, choose descriptive IDs:
//
//   "npc-respawn-forest"      -- good
//   "zone:enchanted-forest"   -- good (2 parts)
//   "name:pattern:tz:end:every" -- bad (legacy format, 5 parts)
```

> **Tradeoff**: Go has no built-in cron — scheduler must use `time.Ticker` or external cron library.

</tab>
<tab title="Node.js">

```typescript
// Valid scheduler IDs
await queue.upsertJobScheduler("npc-respawn-forest", { every: 300_000 }, template);
await queue.upsertJobScheduler("zone:enchanted-forest", { every: 300_000 }, template);

// Invalid: 5+ colon-separated parts (legacy format)
// await queue.upsertJobScheduler("name:*/5:UTC:0:300000", ...); // throws
```

> **Benefit**: `upsertJobScheduler` is Redis-persisted and idempotent — safe across process restarts.

</tab>
</tabs>

## 20.11. Practical Patterns for Game Servers

### Multi-Zone NPC Respawn

<tabs>
<tab title="Elixir">

```elixir
# Register one scheduler per zone during game server boot
zones = [
  %{id: "enchanted-forest", interval: 300_000, npcs: ["goblin", "treant", "fairy"]},
  %{id: "shadow-dungeon", interval: 180_000, npcs: ["skeleton", "lich", "wraith"]},
  %{id: "crystal-caves", interval: 600_000, npcs: ["golem", "bat", "slime"]},
  %{id: "fire-peaks", interval: 240_000, npcs: ["dragon", "phoenix", "salamander"]}
]

for zone <- zones do
  {:ok, _job} = EchoMQ.JobScheduler.upsert(
    :arena_redis,
    "world-sync",
    "npc-respawn-#{zone.id}",
    %{every: zone.interval},
    "respawn-npc",
    %{zone: zone.id, npc_types: zone.npcs},
    priority: 3
  )
end

# List all active respawn schedulers
{:ok, schedulers} = EchoMQ.JobScheduler.list(:arena_redis, "world-sync")
IO.puts("Active zone respawners: #{length(schedulers)}")
```

> **Benefit**: GenServer-based schedulers integrate with supervision — restarts guarantee schedule continuity.

</tab>
<tab title="Go">

```go
// Multi-zone NPC respawn using cron workaround
type Zone struct {
    ID       string
    Interval time.Duration
    NPCs     []string
}

zones := []Zone{
    {"enchanted-forest", 5 * time.Minute, []string{"goblin", "treant", "fairy"}},
    {"shadow-dungeon", 3 * time.Minute, []string{"skeleton", "lich", "wraith"}},
    {"crystal-caves", 10 * time.Minute, []string{"golem", "bat", "slime"}},
    {"fire-peaks", 4 * time.Minute, []string{"dragon", "phoenix", "salamander"}},
}

for _, zone := range zones {
    z := zone // capture
    c.AddFunc(fmt.Sprintf("@every %s", z.Interval), func() {
        queue.Add(ctx, "respawn-npc", map[string]interface{}{
            "zone": z.ID, "npc_types": z.NPCs,
        }, echomq.JobOptions{Priority: 3})
    })
}
```

> **Benefit**: Priority encoding uses composite score combining priority level and insertion order.

</tab>
<tab title="Node.js">

```typescript
// Multi-zone NPC respawn
const zones = [
  { id: "enchanted-forest", interval: 300_000, npcs: ["goblin", "treant", "fairy"] },
  { id: "shadow-dungeon", interval: 180_000, npcs: ["skeleton", "lich", "wraith"] },
  { id: "crystal-caves", interval: 600_000, npcs: ["golem", "bat", "slime"] },
  { id: "fire-peaks", interval: 240_000, npcs: ["dragon", "phoenix", "salamander"] },
];

for (const zone of zones) {
  await queue.upsertJobScheduler(
    `npc-respawn-${zone.id}`,
    { every: zone.interval },
    {
      name: "respawn-npc",
      data: { zone: zone.id, npc_types: zone.npcs },
      opts: { priority: 3 },
    }
  );
}

// List all active respawn schedulers
const schedulers = await queue.getJobSchedulers();
console.log(`Active zone respawners: ${schedulers.length}`);
```

> **Benefit**: `upsertJobScheduler` is Redis-persisted and idempotent — safe across process restarts.

</tab>
</tabs>

## 20.12. Cross-Platform Compatibility

| Feature | Elixir | Go | Node.js | Compatible? |
|---------|--------|-----|---------|-------------|
| Interval-based (`every`) | Native | Workaround (cron lib) | Native | Protocol-level |
| Cron-based (`pattern`) | Native (5-field) | Workaround (cron lib) | Native (5 or 6-field) | Use 5-field only |
| Upsert semantics | Native | Manual | Native | Protocol-level |
| Iteration limits | Native | Manual tracking | Native | Protocol-level |
| Date bounds | Native | Manual checks | Native | Protocol-level |
| Timezone support | Via `tz` option | Via cron lib location | Via `tz` option | Use IANA names |
| Immediate execution | Via `immediately` | Run job manually first | Via `immediately` | Elixir + Node.js |
| Sunday numbering | `7` only | `0` or `7` (cron lib) | `0` or `7` | Use `7` |

**For cross-platform schedulers**, use interval-based (`every`) scheduling when possible. If you need cron, stick to 5-field expressions and use `7` for Sunday.

## 20.13. Comparison: Elixir vs Node.js API

| Operation | Elixir | Node.js |
|-----------|--------|---------|
| Create/update | `JobScheduler.upsert(conn, queue, id, repeat, name, data, opts)` | `queue.upsertJobScheduler(id, repeat, {name, data, opts})` |
| Get | `JobScheduler.get(conn, queue, id)` | `queue.getJobScheduler(id)` |
| List | `JobScheduler.list(conn, queue, opts)` | `queue.getJobSchedulers(start, end, asc)` |
| Count | `JobScheduler.count(conn, queue)` | `queue.getJobSchedulersCount()` |
| Remove | `JobScheduler.remove(conn, queue, id)` | `queue.removeJobScheduler(id)` |
| Next time | `JobScheduler.calculate_next_millis(repeat, ref)` | Internal (not exposed) |

Key differences:
- Elixir passes the connection and queue name explicitly to each function (stateless module)
- Node.js methods are on the `Queue` instance (stateful object)
- Elixir exposes `calculate_next_millis/2` publicly for programmatic next-time calculation
- Elixir job options are a keyword list; Node.js nests them in `opts` inside the template object

---

*Previous: [Parent-Child Jobs](ch19-parent-child-jobs.md) | Next: [Repeatable Jobs](ch21-repeatable-jobs.md)*
