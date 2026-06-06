# Chapter 21. Repeatable Jobs & Cron Patterns

This chapter dives deep into repeat options, cron expression syntax, timezone handling, and scheduling strategies. While [Job Schedulers](ch20-job-schedulers.md) covered the `JobScheduler` API and management operations, this chapter focuses on the repeat configuration itself -- the options that control **when** and **how often** jobs are produced.

## 21.1. Repeat Options Deep Dive

Every scheduler is configured with a repeat options map that controls timing. The two fundamental modes are interval-based (`every`) and cron-based (`pattern`), which are mutually exclusive.

### Interval-Based Repetition

Interval scheduling fires every N milliseconds, measured from the previous job's production time. This is the simplest mode and works identically across all runtimes at the protocol level.

<tabs>
<tab title="Elixir">

```elixir
# Heartbeat ping: every 30 seconds
{:ok, job} = EchoMQ.JobScheduler.upsert(
  :arena_redis,
  "monitoring",
  "heartbeat-ping",
  %{every: 30_000},
  "server-heartbeat",
  %{server_id: "arena-us-east-1", version: "2.4.1"},
  []
)
```

> **Benefit**: GenServer-based schedulers integrate with supervision — restarts guarantee schedule continuity.

</tab>
<tab title="Go">

```go
// Heartbeat ping: every 30 seconds
c := cron.New(cron.WithSeconds())
c.AddFunc("*/30 * * * * *", func() {
    queue.Add(ctx, "server-heartbeat", map[string]interface{}{
        "server_id": "arena-us-east-1", "version": "2.4.1",
    }, echomq.JobOptions{})
})
c.Start()
```

> **Benefit**: Strongly-typed option structs catch misconfiguration at compile time.

</tab>
<tab title="Node.js">

```typescript
// Heartbeat ping: every 30 seconds
await queue.upsertJobScheduler(
  "heartbeat-ping",
  { every: 30_000 },
  {
    name: "server-heartbeat",
    data: { server_id: "arena-us-east-1", version: "2.4.1" },
  }
);
```

> **Benefit**: `upsertJobScheduler` is Redis-persisted and idempotent — safe across process restarts.

</tab>
</tabs>

> **⚠️ Go Gap**: Repeatable job management is not implemented.
> **Proposed Solution**: Embed `addRepeatableJob` and `removeRepeatable` Lua scripts. Implement `Queue.AddRepeatable()` with cron/every/limit/startDate/endDate options. Store repeat metadata in Redis hash keyed by repeat key hash.

### Interval with Offset

The `offset` option shifts when within the interval the job fires. This is useful when multiple schedulers share the same interval but you want to stagger them to avoid thundering herd.

<tabs>
<tab title="Elixir">

```elixir
# Three zone respawners on the same 5-minute interval, staggered by 1 minute each
zones = [
  {"enchanted-forest", 0},
  {"shadow-dungeon", 60_000},
  {"crystal-caves", 120_000}
]

for {zone, offset} <- zones do
  {:ok, _job} = EchoMQ.JobScheduler.upsert(
    :arena_redis,
    "world-sync",
    "npc-respawn-#{zone}",
    %{every: 300_000, offset: offset},
    "respawn-npc",
    %{zone: zone},
    []
  )
end

# Result: forest fires at T+0, dungeon at T+1m, caves at T+2m,
#         then forest at T+5m, dungeon at T+6m, caves at T+7m, etc.
```

> **Benefit**: GenServer-based schedulers integrate with supervision — restarts guarantee schedule continuity.

</tab>
<tab title="Go">

```go
// Staggered zone respawners using cron workaround
// Forest at :00, dungeon at :01, caves at :02 (every 5 min cycle)
type StaggeredZone struct {
    ID     string
    Offset time.Duration
}

zones := []StaggeredZone{
    {"enchanted-forest", 0},
    {"shadow-dungeon", 1 * time.Minute},
    {"crystal-caves", 2 * time.Minute},
}

for _, z := range zones {
    zone := z
    go func() {
        time.Sleep(zone.Offset) // Initial stagger
        ticker := time.NewTicker(5 * time.Minute)
        defer ticker.Stop()
        for {
            select {
            case <-ctx.Done():
                return
            case <-ticker.C:
                queue.Add(ctx, "respawn-npc", map[string]interface{}{
                    "zone": zone.ID,
                }, echomq.JobOptions{})
            }
        }
    }()
}
```

> **Benefit**: Strongly-typed option structs catch misconfiguration at compile time.

</tab>
<tab title="Node.js">

```typescript
// Three zone respawners staggered by 1 minute each
const zones = [
  { id: "enchanted-forest", offset: 0 },
  { id: "shadow-dungeon", offset: 60_000 },
  { id: "crystal-caves", offset: 120_000 },
];

for (const zone of zones) {
  await queue.upsertJobScheduler(
    `npc-respawn-${zone.id}`,
    { every: 300_000, offset: zone.offset },
    {
      name: "respawn-npc",
      data: { zone: zone.id },
    }
  );
}
```

> **Benefit**: `upsertJobScheduler` is Redis-persisted and idempotent — safe across process restarts.

</tab>
</tabs>

## 21.2. Cron Expression Reference

EchoMQ uses standard 5-field cron format. Each field specifies when the job should fire.

```
┌───────────── minute (0 - 59)
│ ┌───────────── hour (0 - 23)
│ │ ┌───────────── day of month (1 - 31)
│ │ │ ┌───────────── month (1 - 12)
│ │ │ │ ┌───────────── day of week (1 - 7, Monday = 1, Sunday = 7)
│ │ │ │ │
* * * * *
```

### Special Characters

| Character | Meaning | Example | Fires |
|-----------|---------|---------|-------|
| `*` | Any value | `* * * * *` | Every minute |
| `,` | Value list | `0,30 * * * *` | At minute 0 and 30 |
| `-` | Range | `0-5 * * * *` | At minutes 0 through 5 |
| `/` | Step | `*/15 * * * *` | Every 15 minutes |

### Common Cron Patterns for Game Servers

| Pattern | Description | Game Use Case |
|---------|-------------|---------------|
| `* * * * *` | Every minute | Debug/monitoring probes |
| `*/5 * * * *` | Every 5 minutes | NPC respawn tick |
| `0 * * * *` | Every hour | Leaderboard snapshot |
| `0 6 * * *` | Daily at 6 AM | Daily quest rotation |
| `0 9 * * *` | Daily at 9 AM | Login rewards window open |
| `0 12 * * *` | Daily at noon | Season pass tier unlock |
| `0 18 * * 5` | Friday at 6 PM | Weekend double-XP start |
| `0 23 * * 7` | Sunday at 11 PM | Weekend event end |
| `0 0 1 * *` | First of month | Season reset |
| `0 6 1 1,4,7,10 *` | Quarterly at 6 AM | Major content patch |
| `0 0 * * 1-5` | Weekday midnight | Ranked queue maintenance |

### Node.js 6-Field Warning

Node.js supports an optional 6th field for **seconds** at the beginning of the expression. Elixir uses standard 5-field format only.

| Feature | Elixir | Node.js | Cross-Platform? |
|---------|--------|---------|-----------------|
| 5-field (no seconds) | Supported | Supported | Yes |
| 6-field (with seconds) | Not supported | Supported | No -- avoid |
| Sunday = `7` | Supported | Supported | Yes |
| Sunday = `0` | Not supported | Supported | No -- use `7` |

For cross-platform compatibility, always use 5-field expressions and `7` for Sunday.

## 21.3. Timezone Support

Cron expressions are evaluated in UTC by default. Use the `tz` option with an IANA timezone name to evaluate in a specific timezone. The scheduler handles DST transitions automatically.

<tabs>
<tab title="Elixir">

```elixir
# Daily quest rotation at 6 AM UTC
{:ok, _job} = EchoMQ.JobScheduler.upsert(
  :arena_redis,
  "game-events",
  "daily-quests-utc",
  %{pattern: "0 6 * * *"},
  "rotate-daily-quests",
  %{quest_pool: "standard"},
  []
)

# Daily quest rotation at 6 AM in each major region
regions = [
  {"daily-quests-us", "America/New_York"},
  {"daily-quests-eu", "Europe/London"},
  {"daily-quests-asia", "Asia/Tokyo"}
]

for {scheduler_id, tz} <- regions do
  {:ok, _job} = EchoMQ.JobScheduler.upsert(
    :arena_redis,
    "game-events",
    scheduler_id,
    %{pattern: "0 6 * * *", tz: tz},
    "rotate-daily-quests",
    %{quest_pool: "standard", region_tz: tz},
    []
  )
end
```

> **Benefit**: GenServer-based schedulers integrate with supervision — restarts guarantee schedule continuity.

</tab>
<tab title="Go">

```go
// Daily quest rotation at 6 AM per region
regions := map[string]string{
    "daily-quests-us":   "America/New_York",
    "daily-quests-eu":   "Europe/London",
    "daily-quests-asia": "Asia/Tokyo",
}

for id, tz := range regions {
    loc, err := time.LoadLocation(tz)
    if err != nil {
        log.Printf("Invalid timezone %s: %v", tz, err)
        continue
    }

    regionCron := cron.New(cron.WithLocation(loc))
    regionCron.AddFunc("0 6 * * *", func() {
        queue.Add(ctx, "rotate-daily-quests", map[string]interface{}{
            "quest_pool": "standard", "region_tz": tz,
        }, echomq.JobOptions{})
    })
    regionCron.Start()
}
```

> **Benefit**: Strongly-typed option structs catch misconfiguration at compile time.

</tab>
<tab title="Node.js">

```typescript
// Daily quest rotation at 6 AM per region
const regions = [
  { id: "daily-quests-us", tz: "America/New_York" },
  { id: "daily-quests-eu", tz: "Europe/London" },
  { id: "daily-quests-asia", tz: "Asia/Tokyo" },
];

for (const region of regions) {
  await queue.upsertJobScheduler(
    region.id,
    { pattern: "0 6 * * *", tz: region.tz },
    {
      name: "rotate-daily-quests",
      data: { quest_pool: "standard", region_tz: region.tz },
    }
  );
}
```

> **Benefit**: `upsertJobScheduler` is Redis-persisted and idempotent — safe across process restarts.

</tab>
</tabs>

### DST Behavior

When a timezone observes DST transitions, the scheduler follows these rules:

| Transition | Behavior | Example |
|------------|----------|---------|
| Spring forward (2 AM becomes 3 AM) | Jobs scheduled during the skipped hour **do not fire** | `"0 2 * * *"` in `America/New_York` skips the spring forward night |
| Fall back (2 AM repeats) | Jobs fire **once** during the repeated hour | `"0 2 * * *"` in `America/New_York` fires once during fall back |

For game events that must fire regardless of DST, use UTC or interval-based scheduling.

## 21.4. Immediate Execution

The `immediately` option produces the first job right now, then follows the regular schedule. This is useful when deploying a new scheduler and you want the first job to run without waiting for the next cron tick.

<tabs>
<tab title="Elixir">

```elixir
# Season pass tier unlock: runs at noon daily, but start now on first deploy
{:ok, job} = EchoMQ.JobScheduler.upsert(
  :arena_redis,
  "player-events",
  "season-pass-unlock",
  %{
    pattern: "0 12 * * *",
    immediately: true
  },
  "unlock-season-tier",
  %{season: "S7", check_all_players: true},
  []
)

# job.delay will be 0 (or very small) for the immediate first execution
IO.puts("First job fires immediately: delay=#{job.delay}ms")
```

The `immediately` option is mutually exclusive with `start_date` -- you cannot say "start at a future date" and "start now" at the same time. Attempting both returns `{:error, :immediately_with_start_date}`.

> **Benefit**: GenServer-based schedulers integrate with supervision — restarts guarantee schedule continuity.

</tab>
<tab title="Go">

```go
// Immediate execution with cron workaround:
// Run the job once immediately, then start the cron schedule

// Immediate first run
queue.Add(ctx, "unlock-season-tier", map[string]interface{}{
    "season": "S7", "check_all_players": true,
}, echomq.JobOptions{})

// Then schedule recurring runs at noon daily
c.AddFunc("0 12 * * *", func() {
    queue.Add(ctx, "unlock-season-tier", map[string]interface{}{
        "season": "S7", "check_all_players": true,
    }, echomq.JobOptions{})
})
```

> **Tradeoff**: Go has no built-in cron — scheduler must use `time.Ticker` or external cron library.

</tab>
<tab title="Node.js">

```typescript
// Season pass tier unlock: runs at noon daily, but start now on first deploy
const job = await queue.upsertJobScheduler(
  "season-pass-unlock",
  {
    pattern: "0 12 * * *",
    immediately: true,
  },
  {
    name: "unlock-season-tier",
    data: { season: "S7", check_all_players: true },
  }
);

console.log(`First job fires immediately: delay=${job.delay}ms`);
```

> **Benefit**: `upsertJobScheduler` is Redis-persisted and idempotent — safe across process restarts.

</tab>
</tabs>

## 21.5. Iteration Tracking and Limits

Each scheduler tracks how many jobs it has produced via `iteration_count`. You can set a `limit` to stop production after a fixed number of iterations.

<tabs>
<tab title="Elixir">

```elixir
# Limited-time Halloween event: 14 daily activations
{:ok, job} = EchoMQ.JobScheduler.upsert(
  :arena_redis,
  "game-events",
  "halloween-daily",
  %{
    pattern: "0 18 * * *",
    tz: "UTC",
    limit: 14
  },
  "activate-halloween-event",
  %{event: "spooky-arena", bonus_candy_drops: true, special_npcs: ["pumpkin-king"]},
  []
)

# After a few days, check progress
{:ok, scheduler} = EchoMQ.JobScheduler.get(:arena_redis, "game-events", "halloween-daily")
remaining = scheduler.limit - scheduler.iteration_count
IO.puts("Halloween activations remaining: #{remaining}/#{scheduler.limit}")

# After 14 iterations, upsert returns an error
# {:error, :limit_reached}
```

> **Benefit**: GenServer-based schedulers integrate with supervision — restarts guarantee schedule continuity.

</tab>
<tab title="Go">

```go
// Limited-time Halloween event: 14 daily activations
// Track iterations manually with Redis
const limitKey = "scheduler:halloween-daily:iterations"
const limit = 14

c.AddFunc("0 18 * * *", func() {
    count, _ := rdb.Incr(ctx, limitKey).Result()
    if count > int64(limit) {
        log.Println("Halloween event limit reached, skipping")
        return
    }

    queue.Add(ctx, "activate-halloween-event", map[string]interface{}{
        "event": "spooky-arena", "bonus_candy_drops": true,
        "special_npcs": []string{"pumpkin-king"},
        "iteration": count,
    }, echomq.JobOptions{})

    log.Printf("Halloween activation %d/%d", count, limit)
})
```

> **Tradeoff**: Go has no built-in cron — scheduler must use `time.Ticker` or external cron library.

</tab>
<tab title="Node.js">

```typescript
// Limited-time Halloween event: 14 daily activations
await queue.upsertJobScheduler(
  "halloween-daily",
  {
    pattern: "0 18 * * *",
    tz: "UTC",
    limit: 14,
  },
  {
    name: "activate-halloween-event",
    data: { event: "spooky-arena", bonus_candy_drops: true, special_npcs: ["pumpkin-king"] },
  }
);

// Check progress
const scheduler = await queue.getJobScheduler("halloween-daily");
const remaining = scheduler.limit - scheduler.iterationCount;
console.log(`Halloween activations remaining: ${remaining}/${scheduler.limit}`);
```

> **Benefit**: `upsertJobScheduler` is Redis-persisted and idempotent — safe across process restarts.

</tab>
</tabs>

## 21.6. Start and End Date Bounds

Date bounds constrain the scheduling window. Jobs are only produced between `start_date` and `end_date`. Both accept either a DateTime/Date object or a Unix timestamp in milliseconds.

### Start Date

<tabs>
<tab title="Elixir">

```elixir
# Weekend double-XP event: starts Friday at 6 PM UTC
{:ok, job} = EchoMQ.JobScheduler.upsert(
  :arena_redis,
  "game-events",
  "double-xp-weekend",
  %{
    every: 3_600_000,
    start_date: ~U[2026-02-13 18:00:00Z]
  },
  "apply-xp-multiplier",
  %{multiplier: 2.0, scope: "all-queues"},
  []
)

# Using milliseconds timestamp
start_ms = DateTime.to_unix(~U[2026-02-13 18:00:00Z], :millisecond)
{:ok, _job} = EchoMQ.JobScheduler.upsert(
  :arena_redis, "game-events", "double-xp-alt",
  %{every: 3_600_000, start_date: start_ms},
  "apply-xp-multiplier", %{multiplier: 2.0}, []
)
```

> **Benefit**: GenServer-based schedulers integrate with supervision — restarts guarantee schedule continuity.

</tab>
<tab title="Go">

```go
// Weekend double-XP: starts Friday 6 PM UTC
start := time.Date(2026, 2, 13, 18, 0, 0, 0, time.UTC)

go func() {
    // Wait until start time
    delay := time.Until(start)
    if delay > 0 {
        time.Sleep(delay)
    }

    ticker := time.NewTicker(1 * time.Hour)
    defer ticker.Stop()
    for {
        select {
        case <-ctx.Done():
            return
        case <-ticker.C:
            queue.Add(ctx, "apply-xp-multiplier", map[string]interface{}{
                "multiplier": 2.0, "scope": "all-queues",
            }, echomq.JobOptions{})
        }
    }
}()
```

> **Benefit**: `time.Duration` types prevent unit mismatch bugs that plague raw millisecond integers.

</tab>
<tab title="Node.js">

```typescript
// Weekend double-XP event: starts Friday at 6 PM UTC
await queue.upsertJobScheduler(
  "double-xp-weekend",
  {
    every: 3_600_000,
    startDate: new Date("2026-02-13T18:00:00Z"),
  },
  {
    name: "apply-xp-multiplier",
    data: { multiplier: 2.0, scope: "all-queues" },
  }
);
```

> **Benefit**: `upsertJobScheduler` is Redis-persisted and idempotent — safe across process restarts.

</tab>
</tabs>

### End Date

<tabs>
<tab title="Elixir">

```elixir
# Weekend double-XP event ends Sunday at 11 PM UTC
{:ok, job} = EchoMQ.JobScheduler.upsert(
  :arena_redis,
  "game-events",
  "double-xp-weekend",
  %{
    every: 3_600_000,
    start_date: ~U[2026-02-13 18:00:00Z],
    end_date: ~U[2026-02-15 23:00:00Z]
  },
  "apply-xp-multiplier",
  %{multiplier: 2.0, scope: "all-queues"},
  []
)

# After end_date passes, the scheduler stops producing jobs.
# Calling upsert again returns {:error, :end_date_reached}
```

> **Benefit**: GenServer-based schedulers integrate with supervision — restarts guarantee schedule continuity.

</tab>
<tab title="Go">

```go
// Weekend double-XP with end date
start := time.Date(2026, 2, 13, 18, 0, 0, 0, time.UTC)
end := time.Date(2026, 2, 15, 23, 0, 0, 0, time.UTC)

go func() {
    delay := time.Until(start)
    if delay > 0 {
        time.Sleep(delay)
    }

    ticker := time.NewTicker(1 * time.Hour)
    defer ticker.Stop()
    for {
        select {
        case <-ctx.Done():
            return
        case t := <-ticker.C:
            if t.After(end) {
                log.Println("Double-XP event ended")
                return
            }
            queue.Add(ctx, "apply-xp-multiplier", map[string]interface{}{
                "multiplier": 2.0, "scope": "all-queues",
            }, echomq.JobOptions{})
        }
    }
}()
```

> **Benefit**: Channel-based event delivery integrates naturally with Go's select statement for multiplexing.

</tab>
<tab title="Node.js">

```typescript
// Weekend double-XP: Friday 6 PM to Sunday 11 PM
await queue.upsertJobScheduler(
  "double-xp-weekend",
  {
    every: 3_600_000,
    startDate: new Date("2026-02-13T18:00:00Z"),
    endDate: new Date("2026-02-15T23:00:00Z"),
  },
  {
    name: "apply-xp-multiplier",
    data: { multiplier: 2.0, scope: "all-queues" },
  }
);
```

> **Benefit**: `upsertJobScheduler` is Redis-persisted and idempotent — safe across process restarts.

</tab>
</tabs>

## 21.7. Calculating Next Execution Time

Elixir exposes `calculate_next_millis/2` to programmatically determine when the next job will fire. This is useful for displaying countdown timers or scheduling UI elements.

<tabs>
<tab title="Elixir">

```elixir
now = System.system_time(:millisecond)

# For interval-based schedulers
next_interval = EchoMQ.JobScheduler.calculate_next_millis(%{every: 300_000}, now)
IO.puts("Next NPC respawn in: #{next_interval - now}ms")

# For cron-based schedulers
next_cron = EchoMQ.JobScheduler.calculate_next_millis(
  %{pattern: "0 6 * * *", tz: "UTC"},
  now
)

next_dt = DateTime.from_unix!(next_cron, :millisecond)
IO.puts("Next daily quest rotation: #{next_dt}")

# With start_date in the future
future_start = EchoMQ.JobScheduler.calculate_next_millis(
  %{pattern: "0 18 * * *", start_date: ~U[2026-03-01 00:00:00Z]},
  now
)
# Returns the first cron tick on or after March 1st

# Returns nil if end_date has passed
expired = EchoMQ.JobScheduler.calculate_next_millis(
  %{every: 60_000, end_date: ~U[2025-01-01 00:00:00Z]},
  now
)
# => nil
```

> **Benefit**: GenServer-based schedulers integrate with supervision — restarts guarantee schedule continuity.

</tab>
<tab title="Go">

```go
// calculate_next_millis is not exposed in echomq-go.
// Use the cron library's Schedule.Next() method instead:

schedule, _ := cron.ParseStandard("0 6 * * *")
next := schedule.Next(time.Now())
fmt.Printf("Next daily quest rotation: %v\n", next)

// For interval-based, calculate manually:
interval := 5 * time.Minute
now := time.Now()
nextInterval := now.Add(interval)
fmt.Printf("Next NPC respawn: %v (in %v)\n", nextInterval, interval)
```

> **Tradeoff**: Go has no built-in cron — scheduler must use `time.Ticker` or external cron library.

</tab>
<tab title="Node.js">

```typescript
// Node.js does not expose a public calculate_next_millis method.
// Use the scheduler's `next` field after creation:

const scheduler = await queue.getJobScheduler("npc-respawn-forest");
const nextDate = new Date(scheduler.next);
const delayMs = scheduler.next - Date.now();

console.log(`Next NPC respawn: ${nextDate} (in ${Math.round(delayMs / 1000)}s)`);

// For programmatic cron calculation, use the cron-parser library:
import parser from "cron-parser";

const interval = parser.parseExpression("0 6 * * *", { tz: "UTC" });
console.log(`Next daily quest rotation: ${interval.next().toDate()}`);
```

> **Benefit**: `upsertJobScheduler` is Redis-persisted and idempotent — safe across process restarts.

</tab>
</tabs>

## 21.8. Migration from Legacy Repeatable Jobs

BullMQ v5 introduced `JobScheduler` to replace the older "repeatable jobs" API. If your codebase uses the legacy `repeat` option on `Queue.add()`, migrate to `JobScheduler.upsert()` for better control and explicit scheduler IDs.

<tabs>
<tab title="Elixir">

```elixir
# Legacy approach (deprecated in BullMQ v5+)
# EchoMQ.Queue.add("game-events", "daily-quest", %{},
#   repeat: %{pattern: "0 6 * * *"}
# )
# Problem: scheduler ID was auto-generated from repeat config,
# making it hard to manage, update, or remove.

# New approach with JobScheduler
{:ok, _job} = EchoMQ.JobScheduler.upsert(
  :arena_redis,
  "game-events",
  "daily-quest-rotation",
  %{pattern: "0 6 * * *"},
  "rotate-daily-quests",
  %{quest_pool: "standard"},
  []
)

# Benefits:
# - Explicit ID ("daily-quest-rotation") for easy management
# - Upsert semantics prevent duplicates across deploys
# - get/list/count/remove operations by ID
# - Iteration tracking built in
```

> **Benefit**: GenServer-based schedulers integrate with supervision — restarts guarantee schedule continuity.

</tab>
<tab title="Go">

```go
// Go does not have a legacy repeatable jobs API to migrate from.
// The cron workaround approach described throughout this chapter
// is the recommended pattern until echomq-go implements JobScheduler.
//
// When JobScheduler is implemented, the migration path will be:
//   1. Stop external cron entries
//   2. Call JobScheduler.Upsert() with the same schedule
//   3. Remove external cron state from Redis
```

> **Tradeoff**: Go has no built-in cron — scheduler must use `time.Ticker` or external cron library.

</tab>
<tab title="Node.js">

```typescript
// Legacy approach (deprecated)
// await queue.add("rotate-daily-quests", { quest_pool: "standard" }, {
//   repeat: { pattern: "0 6 * * *" },
// });
// Problem: scheduler ID auto-generated, hard to manage

// New approach with JobScheduler
await queue.upsertJobScheduler(
  "daily-quest-rotation",
  { pattern: "0 6 * * *" },
  {
    name: "rotate-daily-quests",
    data: { quest_pool: "standard" },
  }
);

// To migrate existing repeatable jobs:
// 1. List old repeatable jobs
const oldRepeatables = await queue.getRepeatableJobs();
// 2. Create corresponding JobSchedulers
for (const old of oldRepeatables) {
  await queue.upsertJobScheduler(
    old.id || `migrated-${old.name}`,
    { pattern: old.cron, every: old.every, tz: old.tz },
    { name: old.name, data: {} }
  );
}
// 3. Remove old repeatable jobs
for (const old of oldRepeatables) {
  await queue.removeRepeatableByKey(old.key);
}
```

> **Benefit**: `upsertJobScheduler` is Redis-persisted and idempotent — safe across process restarts.

</tab>
</tabs>

## 21.9. Advanced: Combining Options

Repeat options compose to express complex scheduling requirements. Here is a comprehensive example that combines multiple options.

<tabs>
<tab title="Elixir">

```elixir
# Ranked season event: weekday evenings (6 PM) in US Eastern,
# starting March 1st, ending April 30th, max 40 activations.
# First activation fires immediately on deploy.
{:ok, job} = EchoMQ.JobScheduler.upsert(
  :arena_redis,
  "game-events",
  "ranked-season-evening",
  %{
    pattern: "0 18 * * 1-5",
    tz: "America/New_York",
    start_date: ~U[2026-03-01 00:00:00Z],
    end_date: ~U[2026-04-30 23:59:59Z],
    limit: 40
  },
  "start-ranked-session",
  %{
    season: "S7",
    mode: "competitive",
    rank_floor: "gold",
    rewards_multiplier: 1.5
  },
  priority: 1,
  attempts: 3,
  backoff: %{type: "exponential", delay: 5_000}
)

# Monitor the scheduler
{:ok, s} = EchoMQ.JobScheduler.get(:arena_redis, "game-events", "ranked-season-evening")

IO.puts("""
Ranked Season Scheduler:
  Pattern:    #{s.pattern}
  Timezone:   #{s.tz}
  Next fire:  #{DateTime.from_unix!(s.next, :millisecond)}
  Iterations: #{s.iteration_count}/#{s.limit}
  Start:      #{DateTime.from_unix!(s.start_date, :millisecond)}
  End:        #{DateTime.from_unix!(s.end_date, :millisecond)}
""")
```

> **Benefit**: Custom backoff functions receive attempt count and error — full context for delay calculation.

</tab>
<tab title="Go">

```go
// Ranked season event: weekday evenings in US Eastern,
// bounded by date range and iteration limit
loc, _ := time.LoadLocation("America/New_York")
c := cron.New(cron.WithLocation(loc))

start := time.Date(2026, 3, 1, 0, 0, 0, 0, time.UTC)
end := time.Date(2026, 4, 30, 23, 59, 59, 0, time.UTC)
limitKey := "scheduler:ranked-season:iterations"
limit := int64(40)

c.AddFunc("0 18 * * 1-5", func() {
    now := time.Now().UTC()
    if now.Before(start) || now.After(end) {
        return
    }

    count, _ := rdb.Incr(ctx, limitKey).Result()
    if count > limit {
        return
    }

    queue.Add(ctx, "start-ranked-session", map[string]interface{}{
        "season": "S7", "mode": "competitive",
        "rank_floor": "gold", "rewards_multiplier": 1.5,
        "iteration": count,
    }, echomq.JobOptions{
        Priority: 1, Attempts: 3, BackoffDelay: 5 * time.Second,
    })

    log.Printf("Ranked session %d/%d started", count, limit)
})
c.Start()
```

> **Benefit**: Backoff configuration is declarative — `Type` and `Delay` fields are validated at compile time.

</tab>
<tab title="Node.js">

```typescript
// Ranked season event: weekday evenings (6 PM) in US Eastern,
// bounded March-April, max 40 activations
await queue.upsertJobScheduler(
  "ranked-season-evening",
  {
    pattern: "0 18 * * 1-5",
    tz: "America/New_York",
    startDate: new Date("2026-03-01T00:00:00Z"),
    endDate: new Date("2026-04-30T23:59:59Z"),
    limit: 40,
  },
  {
    name: "start-ranked-session",
    data: {
      season: "S7",
      mode: "competitive",
      rank_floor: "gold",
      rewards_multiplier: 1.5,
    },
    opts: {
      priority: 1,
      attempts: 3,
      backoff: { type: "exponential", delay: 5000 },
    },
  }
);

// Monitor the scheduler
const s = await queue.getJobScheduler("ranked-season-evening");
console.log(`Ranked Season Scheduler:`);
console.log(`  Pattern:    ${s.pattern}`);
console.log(`  Next fire:  ${new Date(s.next)}`);
console.log(`  Iterations: ${s.iterationCount}/${s.limit}`);
```

> **Benefit**: Custom backoff functions return millisecond delay — simple numeric interface.

</tab>
</tabs>

## 21.10. Repeat Options Quick Reference

| Option | Type | Interval | Cron | Description |
|--------|------|----------|------|-------------|
| `every` | integer (ms) | Required | N/A | Interval between job productions |
| `pattern` | string | N/A | Required | 5-field cron expression |
| `offset` | integer (ms) | Optional | N/A | Shifts interval firing time |
| `tz` | string (IANA) | Ignored | Optional | Timezone for cron evaluation |
| `limit` | integer | Optional | Optional | Max iterations before stopping |
| `start_date` | DateTime/ms | Optional | Optional | Earliest production time |
| `end_date` | DateTime/ms | Optional | Optional | Latest production time |
| `immediately` | boolean | N/A | Optional | Fire first job immediately |

Mutual exclusions:
- `every` and `pattern` cannot be used together
- `immediately` and `start_date` cannot be used together

## 21.11. Comparison: Scheduler Features by Runtime

| Feature | Elixir | Go | Node.js |
|---------|--------|-----|---------|
| JobScheduler API | Native (`EchoMQ.JobScheduler`) | Not implemented (use cron lib) | Native (`Queue.upsertJobScheduler`) |
| Interval scheduling | `%{every: ms}` | `time.Ticker` or cron `@every` | `{ every: ms }` |
| Cron scheduling | 5-field only | 5 or 6-field (via cron lib) | 5 or 6-field |
| Upsert semantics | Built-in | Manual (Redis check) | Built-in |
| Iteration tracking | Built-in (`iteration_count`) | Manual (Redis counter) | Built-in (`iterationCount`) |
| Date bounds | Built-in (`start_date`/`end_date`) | Manual time checks | Built-in (`startDate`/`endDate`) |
| Timezone | Via `tz` option | Via `cron.WithLocation` | Via `tz` option |
| Next-time calculation | `calculate_next_millis/2` (public) | `Schedule.Next()` (cron lib) | Internal (read from scheduler) |
| Scheduler removal | Removes pending delayed job | Manual cleanup | Removes pending delayed job |

---

*Previous: [Job Schedulers](ch20-job-schedulers.md) | Next: [Queue Events](ch22-queue-events.md)*
