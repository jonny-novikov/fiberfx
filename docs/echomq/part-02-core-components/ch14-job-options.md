# Chapter 14. Job Options

Job options control how a job is scheduled, prioritized, retried, and cleaned up. In **Fireheadz Arena**, these options govern everything from damage calculation priority to NPC respawn cooldowns and matchmaking retry logic. All three runtimes support the same core options because they are interpreted by the shared Lua scripts at the Redis layer. API syntax varies by language.

## 14.1. Options Reference

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `job_id` | string | auto | Custom job identifier for idempotency |
| `priority` | integer | 0 | 0 (highest) to 2^21. Lower = processed first |
| `delay` | integer | 0 | Milliseconds before processing |
| `attempts` | integer | 1 | Total attempts (including first try) |
| `backoff` | map | none | Retry delay strategy (fixed or exponential) |
| `lifo` | boolean | false | Last-in-first-out ordering |
| `timeout` | integer | none | Job processing timeout (ms) |
| `remove_on_complete` | bool/int/map | false | Auto-delete after completion |
| `remove_on_fail` | bool/int/map | false | Auto-delete after failure |
| `timestamp` | integer | now | Custom creation timestamp (Unix ms) |
| `repeat` | map | none | Repeatable/cron job configuration |
| `deduplication` | map | none | Deduplication (throttle/debounce) |
| `parent` | map | none | Parent job reference (for flows) |
| `fail_parent_on_failure` | boolean | false | Fail parent if this child fails |
| `ignore_dependency_on_failure` | boolean | false | Let parent proceed despite child failure |
| `remove_dependency_on_failure` | boolean | false | Remove dep link on child failure |
| `telemetry_metadata` | string | none | Metadata for distributed tracing |
| `omit_context` | boolean | false | Omit context data from job |

---

## 14.2. Priority

Priority determines processing order within a queue. Lower values equal higher priority (0 is highest, like Unix nice values). In a game server, damage calculations must resolve before chat messages or analytics events.

<tabs>
<tab title="Elixir">

```elixir
# Critical: damage calculation resolves before anything else
{:ok, _} = EchoMQ.Queue.add("combat-actions", "calculate-damage",
  %{player_id: "PLR0K48QjihpC4", action: "attack", target_id: "NPC5rK2mJ9pQ1L", damage: 150},
  connection: :redis, priority: 1)

# High: matchmaking affects player experience directly
{:ok, _} = EchoMQ.Queue.add("matchmaking", "find-match",
  %{player_id: "PLR0K48QjihpC4", mode: "ranked", map: "arena-3"},
  connection: :redis, priority: 10)

# Low: leaderboard can update in the background
{:ok, _} = EchoMQ.Queue.add("leaderboard", "update-score",
  %{player_id: "PLR0K48QjihpC4", score: 2450},
  connection: :redis, priority: 20)
```

> **Benefit**: Priority maps to Redis sorted set scores — atomic ordering without application-level sorting.

</tab>
<tab title="Go">

```go
// Critical: damage calculation resolves first
_, err := queue.Add(ctx, "calculate-damage",
    map[string]interface{}{
        "player_id": "PLR0K48QjihpC4", "action": "attack",
        "target_id": "NPC5rK2mJ9pQ1L", "damage": 150,
    },
    echomq.JobOptions{Priority: 1})
if err != nil {
    log.Fatalf("failed to enqueue damage calculation: %v", err)
}

// High: matchmaking
_, err = queue.Add(ctx, "find-match",
    map[string]interface{}{
        "player_id": "PLR0K48QjihpC4", "mode": "ranked", "map": "arena-3",
    },
    echomq.JobOptions{Priority: 10})
if err != nil {
    log.Fatalf("failed to enqueue matchmaking: %v", err)
}

// Low: leaderboard update
_, err = queue.Add(ctx, "update-score",
    map[string]interface{}{"player_id": "PLR0K48QjihpC4", "score": 2450},
    echomq.JobOptions{Priority: 20})
if err != nil {
    log.Fatalf("failed to enqueue leaderboard update: %v", err)
}
```

> **Benefit**: Priority encoding uses composite score combining priority level and insertion order.

</tab>
<tab title="Node.js">

```typescript
// Critical: damage calculation
await queue.add("calculate-damage", {
  player_id: "PLR0K48QjihpC4", action: "attack",
  target_id: "NPC5rK2mJ9pQ1L", damage: 150,
}, { priority: 1 });

// High: matchmaking
await queue.add("find-match", {
  player_id: "PLR0K48QjihpC4", mode: "ranked", map: "arena-3",
}, { priority: 10 });

// Low: leaderboard
await queue.add("update-score", {
  player_id: "PLR0K48QjihpC4", score: 2450,
}, { priority: 20 });
```

> **Benefit**: Priority values mirror BullMQ's proven sorted set implementation.

</tab>
</tabs>

### Priority Ranges

| Range | Use Case | Example |
|-------|----------|---------|
| 0-10 | Critical | Damage calculations, buff resolution, skill execution |
| 11-100 | High | Matchmaking, trade processing, zone transitions |
| 101-500 | Normal | Inventory updates, crafting, loot drops |
| 501-1000 | Low | Leaderboard recalculation, achievement checks |
| 1001+ | Bulk | Analytics batches, replay archival |

### Priority vs FIFO

Jobs without priority go to the WAITING list (FIFO). Jobs with priority go to the PRIORITIZED sorted set. Workers always check the prioritized queue before the wait queue:

```
Processing order:
1. All PRIORITIZED jobs (by priority score, lowest first)
2. Then WAITING jobs (FIFO order)
```

---

## 14.3. Delay

Schedule jobs for future execution. Delayed jobs enter the DELAYED state and move to WAITING when their time arrives. In a game server, delays handle NPC respawn cooldowns, match start countdowns, and seasonal event scheduling.

<tabs>
<tab title="Elixir">

```elixir
# NPC respawn cooldown (5 minutes after death)
{:ok, job} = EchoMQ.Queue.add("world-sync", "spawn-npc",
  %{npc_id: "NPC5rK2mJ9pQ1L", zone: "dungeon-7", hp: 50_000},
  connection: :redis, delay: 300_000)

# Match start countdown (60 seconds for players to ready up)
{:ok, job} = EchoMQ.Queue.add("matchmaking", "create-lobby",
  %{match_id: "MTH0K5M2vuIULY", players: ["PLR0K48QjihpC4", "PLR3QR5T7V9W2X"], map: "arena-3"},
  connection: :redis, delay: 60_000)

# Seasonal event: start at a specific time
target = ~U[2026-06-01 09:00:00Z]
delay_ms = DateTime.diff(target, DateTime.utc_now(), :millisecond)
{:ok, job} = EchoMQ.Queue.add("player-events", "unlock-achievement",
  %{event: "summer-festival", reward: "ITM1yO4wQ6sS2L"},
  connection: :redis, delay: max(0, delay_ms))

# Using Erlang timer helpers for daily ranking reset
{:ok, job} = EchoMQ.Queue.add("leaderboard", "recalculate-rankings", %{},
  connection: :redis, delay: :timer.hours(24))
```

> **Benefit**: LockManager batches all lock renewals into a single GenServer tick — O(1) timer overhead.

</tab>
<tab title="Go">

```go
// NPC respawn cooldown (5 minutes after death)
_, err := queue.Add(ctx, "spawn-npc",
    map[string]interface{}{
        "npc_id": "NPC5rK2mJ9pQ1L", "zone": "dungeon-7", "hp": 50000,
    },
    echomq.JobOptions{Delay: 5 * time.Minute})
if err != nil {
    log.Fatalf("failed to enqueue NPC respawn: %v", err)
}

// Match start countdown (60 seconds)
_, err = queue.Add(ctx, "create-lobby",
    map[string]interface{}{
        "match_id": "MTH0K5M2vuIULY",
        "players": []string{"PLR0K48QjihpC4", "PLR3QR5T7V9W2X"},
        "map":     "arena-3",
    },
    echomq.JobOptions{Delay: 60 * time.Second})
if err != nil {
    log.Fatalf("failed to enqueue lobby creation: %v", err)
}

// Seasonal event at a specific time
target := time.Date(2026, 6, 1, 9, 0, 0, 0, time.UTC)
delay := time.Until(target)
if delay < 0 {
    delay = 0
}
_, err = queue.Add(ctx, "unlock-achievement",
    map[string]interface{}{"event": "summer-festival", "reward": "ITM1yO4wQ6sS2L"},
    echomq.JobOptions{Delay: delay})
if err != nil {
    log.Fatalf("failed to enqueue achievement unlock: %v", err)
}
```

Go uses native `time.Duration` values. The `Queue.Add()` method converts to milliseconds internally when writing to the Redis sorted set.

> **Tradeoff**: Lock extension requires periodic goroutine-based timers — manual lifecycle management.

</tab>
<tab title="Node.js">

```typescript
// NPC respawn cooldown (5 minutes after death)
await queue.add("spawn-npc", {
  npc_id: "NPC5rK2mJ9pQ1L", zone: "dungeon-7", hp: 50000,
}, { delay: 300_000 });

// Match start countdown (60 seconds)
await queue.add("create-lobby", {
  match_id: "MTH0K5M2vuIULY", players: ["PLR0K48QjihpC4", "PLR3QR5T7V9W2X"], map: "arena-3",
}, { delay: 60_000 });

// Seasonal event at a specific time
const target = new Date("2026-06-01T09:00:00Z");
const delay = Math.max(0, target.getTime() - Date.now());
await queue.add("unlock-achievement", {
  event: "summer-festival", reward: "ITM1yO4wQ6sS2L",
}, { delay });
```

> **Benefit**: Built-in lock extension runs automatically within the Worker class — transparent to processors.

</tab>
</tabs>

---

## 14.4. Retry Configuration

### Attempts

The `attempts` option specifies the total number of processing attempts (1 = no retries, 3 = 1 initial + 2 retries).

<tabs>
<tab title="Elixir">

```elixir
# 3 attempts for matchmaking (server might be overloaded)
{:ok, job} = EchoMQ.Queue.add("matchmaking", "find-match",
  %{player_id: "PLR0K48QjihpC4", mode: "ranked"},
  connection: :redis, attempts: 3)

# 5 attempts for critical combat resolution
{:ok, job} = EchoMQ.Queue.add("combat-actions", "resolve-skill",
  %{player_id: "PLR0K48QjihpC4", skill_id: "fireball", target_id: "NPC5rK2mJ9pQ1L"},
  connection: :redis, attempts: 5)
```

> **Benefit**: Named connections via `Redix` integrate into supervision trees — automatic reconnect on network partitions.

</tab>
<tab title="Go">

```go
// Per-job attempts for matchmaking
queue.Add(ctx, "find-match",
    map[string]interface{}{"player_id": "PLR0K48QjihpC4", "mode": "ranked"},
    echomq.JobOptions{Attempts: 3})

// Worker-level default (applies when job opts don't specify)
worker := echomq.NewWorker("combat-actions", rdb, echomq.WorkerOptions{
    MaxAttempts: 5,
})
```

> **Benefit**: Strongly-typed option structs catch misconfiguration at compile time.

</tab>
<tab title="Node.js">

```typescript
// 3 attempts for matchmaking
await queue.add("find-match", {
  player_id: "PLR0K48QjihpC4", mode: "ranked",
}, { attempts: 3 });

// 5 attempts for critical combat resolution
await queue.add("resolve-skill", {
  player_id: "PLR0K48QjihpC4", skill_id: "fireball", target_id: "NPC5rK2mJ9pQ1L",
}, { attempts: 5 });
```

> **Benefit**: Inline options object matches BullMQ's well-documented API — no translation needed.

</tab>
</tabs>

### Backoff Strategies

Backoff controls the delay between retry attempts.

#### Fixed Backoff

Same delay between each retry. Useful for zone transitions where the target zone may be temporarily locked.

<tabs>
<tab title="Elixir">

```elixir
{:ok, job} = EchoMQ.Queue.add("world-sync", "zone-transition",
  %{player_id: "PLR0K48QjihpC4", from_zone: "town-1", to_zone: "dungeon-7"},
  connection: :redis,
  attempts: 4,
  backoff: %{type: :fixed, delay: 5000})
# Retry delays: 5s, 5s, 5s
```

Both atom keys (`:fixed`) and string keys (`"fixed"`) are accepted. Atom keys are idiomatic for Elixir-created jobs; string keys are used when deserializing from Redis/JSON.

> **Benefit**: Custom backoff functions receive attempt count and error — full context for delay calculation.

</tab>
<tab title="Go">

```go
queue.Add(ctx, "zone-transition",
    map[string]interface{}{
        "player_id": "PLR0K48QjihpC4",
        "from_zone": "town-1",
        "to_zone":   "dungeon-7",
    },
    echomq.JobOptions{
        Attempts: 4,
        Backoff:  echomq.BackoffConfig{Type: "fixed", Delay: 5000},
    })
// Retry delays: 5s, 5s, 5s
```

> **Benefit**: Backoff configuration is declarative — `Type` and `Delay` fields are validated at compile time.

</tab>
<tab title="Node.js">

```typescript
await queue.add("zone-transition", {
  player_id: "PLR0K48QjihpC4", from_zone: "town-1", to_zone: "dungeon-7",
}, {
  attempts: 4,
  backoff: { type: "fixed", delay: 5000 },
});
// Retry delays: 5s, 5s, 5s
```

> **Benefit**: Custom backoff functions return millisecond delay — simple numeric interface.

</tab>
</tabs>

#### Exponential Backoff

Delay doubles each retry. The formula is `2^(attempt-1) * delay`. Ideal for matchmaking retries when the game server is under heavy load -- back off progressively to avoid overwhelming the matchmaker.

<tabs>
<tab title="Elixir">

```elixir
{:ok, job} = EchoMQ.Queue.add("matchmaking", "find-match",
  %{player_id: "PLR0K48QjihpC4", mode: "ranked", map: "arena-3"},
  connection: :redis,
  attempts: 5,
  backoff: %{type: :exponential, delay: 1000})
# Retry delays: 1s, 2s, 4s, 8s

# With jitter to prevent thundering herd when many players retry at once
{:ok, job} = EchoMQ.Queue.add("matchmaking", "find-match",
  %{player_id: "PLR0K48QjihpC4", mode: "ranked", map: "arena-3"},
  connection: :redis,
  attempts: 5,
  backoff: %{type: :exponential, delay: 1000, jitter: 0.2})
# Retry delays: ~1s, ~2s, ~4s, ~8s (each +/- 20%)
```

The `jitter` parameter (float 0.0-1.0) adds randomization. With `jitter: 0.2` and a base delay of 4000ms, the actual delay falls in the range 3200ms-4800ms. This is implemented in `EchoMQ.Job.calculate_exponential_backoff/3`.

> **Benefit**: Custom backoff functions receive attempt count and error — full context for delay calculation.

</tab>
<tab title="Go">

```go
queue.Add(ctx, "find-match",
    map[string]interface{}{
        "player_id": "PLR0K48QjihpC4", "mode": "ranked", "map": "arena-3",
    },
    echomq.JobOptions{
        Attempts: 5,
        Backoff:  echomq.BackoffConfig{Type: "exponential", Delay: 1000},
    })
// Retry delays: 1s, 2s, 4s, 8s
```

Go's `CalculateBackoff()` function adds jitter automatically to prevent synchronized retries.

> **Benefit**: Backoff configuration is declarative — `Type` and `Delay` fields are validated at compile time.

</tab>
<tab title="Node.js">

```typescript
await queue.add("find-match", {
  player_id: "PLR0K48QjihpC4", mode: "ranked", map: "arena-3",
}, {
  attempts: 5,
  backoff: { type: "exponential", delay: 1000 },
});
// Retry delays: 1s, 2s, 4s, 8s
```

> **Benefit**: Custom backoff functions return millisecond delay — simple numeric interface.

</tab>
</tabs>

---

## 14.5. Auto-Cleanup

Control how long completed and failed jobs remain in Redis. Without cleanup, finished combat actions, matchmaking results, and leaderboard updates accumulate indefinitely. In a high-throughput game server, this is essential for keeping Redis memory bounded.

### Remove on Complete

<tabs>
<tab title="Elixir">

```elixir
# Remove combat log immediately after resolution (ephemeral)
{:ok, _} = EchoMQ.Queue.add("combat-actions", "apply-buff",
  %{player_id: "PLR0K48QjihpC4", buff: "shield", duration_ms: 10_000},
  connection: :redis, remove_on_complete: true)

# Keep last 1000 completed combat actions for replay
{:ok, _} = EchoMQ.Queue.add("combat-actions", "calculate-damage",
  %{player_id: "PLR0K48QjihpC4", target_id: "NPC5rK2mJ9pQ1L", damage: 150},
  connection: :redis, remove_on_complete: %{count: 1000})

# Keep completed matches for the last hour (age in seconds)
{:ok, _} = EchoMQ.Queue.add("matchmaking", "find-match",
  %{player_id: "PLR0K48QjihpC4", mode: "ranked"},
  connection: :redis, remove_on_complete: %{age: 3600})
```

> **Benefit**: Job removal is atomic via Lua script — no partial state left in Redis.

</tab>
<tab title="Go">

```go
// Remove buff application immediately after completion
queue.Add(ctx, "apply-buff",
    map[string]interface{}{
        "player_id": "PLR0K48QjihpC4", "buff": "shield", "duration_ms": 10000,
    },
    echomq.JobOptions{
        RemoveOnComplete: echomq.RemoveOnSetting{Remove: true},
    })

// Keep last 1000 completed combat actions for replay
queue.Add(ctx, "calculate-damage",
    map[string]interface{}{
        "player_id": "PLR0K48QjihpC4", "target_id": "NPC5rK2mJ9pQ1L", "damage": 150,
    },
    echomq.JobOptions{
        RemoveOnComplete: echomq.RemoveOnSetting{Count: 1000},
    })

// Keep completed matches for the last hour
queue.Add(ctx, "find-match",
    map[string]interface{}{"player_id": "PLR0K48QjihpC4", "mode": "ranked"},
    echomq.JobOptions{
        RemoveOnComplete: echomq.RemoveOnSetting{Age: 3600},
    })
```

Go's `RemoveOnSetting` struct handles all three variants (boolean, count, age/count object) and provides `ShouldRemove()` for conditional cleanup in the completer.

> **Benefit**: `queue.Remove(id)` issues a single Lua script call — O(1) regardless of queue size.

</tab>
<tab title="Node.js">

```typescript
// Remove buff application immediately
await queue.add("apply-buff", {
  player_id: "PLR0K48QjihpC4", buff: "shield", duration_ms: 10000,
}, { removeOnComplete: true });

// Keep last 1000 combat actions for replay
await queue.add("calculate-damage", {
  player_id: "PLR0K48QjihpC4", target_id: "NPC5rK2mJ9pQ1L", damage: 150,
}, { removeOnComplete: { count: 1000 } });

// Keep completed matches for the last hour
await queue.add("find-match", {
  player_id: "PLR0K48QjihpC4", mode: "ranked",
}, { removeOnComplete: { age: 3600 } });
```

> **Benefit**: `job.remove()` cleans up all associated Redis keys in one atomic operation.

</tab>
</tabs>

### Remove on Fail

<tabs>
<tab title="Elixir">

```elixir
# Remove failed NPC pathfind attempts immediately (transient failures)
{:ok, _} = EchoMQ.Queue.add("world-sync", "pathfind",
  %{npc_id: "NPC4pL8nQ3uV7X", destination: "waypoint-12"},
  connection: :redis, attempts: 3, remove_on_fail: true)

# Keep last 50 failed matchmaking attempts for debugging
{:ok, _} = EchoMQ.Queue.add("matchmaking", "find-match",
  %{player_id: "PLR0K48QjihpC4", mode: "ranked"},
  connection: :redis, attempts: 3, remove_on_fail: %{count: 50})

# Keep failed trade jobs for 24 hours (audit trail)
{:ok, _} = EchoMQ.Queue.add("inventory", "process-trade",
  %{item_id: "ITM8xN3vP7qR4K", from_player: "PLR0K48QjihpC4", to_player: "PLR3QR5T7V9W2X"},
  connection: :redis, attempts: 3, remove_on_fail: %{age: 86400})
```

> **Benefit**: Job removal is atomic via Lua script — no partial state left in Redis.

</tab>
<tab title="Go">

```go
// Remove failed pathfind attempts immediately
queue.Add(ctx, "pathfind",
    map[string]interface{}{
        "npc_id": "NPC4pL8nQ3uV7X", "destination": "waypoint-12",
    },
    echomq.JobOptions{
        Attempts:     3,
        RemoveOnFail: echomq.RemoveOnSetting{Remove: true},
    })

// Keep last 50 failed matchmaking attempts
queue.Add(ctx, "find-match",
    map[string]interface{}{"player_id": "PLR0K48QjihpC4", "mode": "ranked"},
    echomq.JobOptions{
        Attempts:     3,
        RemoveOnFail: echomq.RemoveOnSetting{Count: 50},
    })
```

> **Benefit**: `queue.Remove(id)` issues a single Lua script call — O(1) regardless of queue size.

</tab>
<tab title="Node.js">

```typescript
// Remove failed pathfind attempts immediately
await queue.add("pathfind", {
  npc_id: "NPC4pL8nQ3uV7X", destination: "waypoint-12",
}, {
  attempts: 3,
  removeOnFail: true,
});

// Keep last 50 failed matchmaking attempts
await queue.add("find-match", {
  player_id: "PLR0K48QjihpC4", mode: "ranked",
}, {
  attempts: 3,
  removeOnFail: { count: 50 },
});
```

> **Benefit**: `job.remove()` cleans up all associated Redis keys in one atomic operation.

</tab>
</tabs>

### Removal Type Reference

| Value | Behavior |
|-------|----------|
| `true` | Remove immediately |
| `false` | Never remove (default) |
| `%{count: N}` | Keep only the last N jobs |
| `%{age: S}` | Remove jobs older than S seconds |

---

## 14.6. LIFO Mode

Process jobs in stack order (newest first). In a game server, LIFO is ideal for player position updates in world-sync -- when multiple position updates queue up, the most recent position is always the one that matters.

<tabs>
<tab title="Elixir">

```elixir
# Player position updates -- newest position supersedes older ones
{:ok, _} = EchoMQ.Queue.add("world-sync", "pathfind",
  %{npc_id: "NPC4pL8nQ3uV7X", position: {10, 20}}, connection: :redis, lifo: true)
{:ok, _} = EchoMQ.Queue.add("world-sync", "pathfind",
  %{npc_id: "NPC4pL8nQ3uV7X", position: {15, 25}}, connection: :redis, lifo: true)
{:ok, _} = EchoMQ.Queue.add("world-sync", "pathfind",
  %{npc_id: "NPC4pL8nQ3uV7X", position: {20, 30}}, connection: :redis, lifo: true)

# Processing order: {20,30} -> {15,25} -> {10,20}
# The most recent position is resolved first
```

The `lifo` option is also respected during retry -- when a retried job with `lifo: true` re-enters the wait list, it is pushed to the front.

> **Benefit**: Backoff strategies compose with supervision tree restart logic — double fault tolerance.

</tab>
<tab title="Go">

```go
// ---------------------------------------------------------------
// LIFO is not yet supported in the Go API.
//
// The underlying addJob Lua script supports LIFO ordering via
// RPUSH (instead of LPUSH) on the wait list, but the Go
// Queue.Add() method always passes the FIFO flag.
//
// Workaround: Use priority with a timestamp-based score to
// approximate newest-first ordering.
//
// Tracking: See PROTOCOL-GAPS.md for the implementation roadmap.
// ---------------------------------------------------------------
```

> **Benefit**: Priority encoding uses composite score combining priority level and insertion order.

</tab>
<tab title="Node.js">

```typescript
// NPC pathfind updates -- newest position wins
await queue.add("pathfind", { npc_id: "NPC4pL8nQ3uV7X", position: [10, 20] }, { lifo: true });
await queue.add("pathfind", { npc_id: "NPC4pL8nQ3uV7X", position: [15, 25] }, { lifo: true });
await queue.add("pathfind", { npc_id: "NPC4pL8nQ3uV7X", position: [20, 30] }, { lifo: true });

// Processing order: [20,30] -> [15,25] -> [10,20]
```

> **Benefit**: Inline options object matches BullMQ's well-documented API — no translation needed.

</tab>
</tabs>

| Use Case | Why LIFO |
|----------|----------|
| NPC position sync | Latest coordinates are most relevant |
| Player input buffer | Newest action supersedes stale inputs |
| Cache invalidation | Most recent zone state wins |

---

## 14.7. Custom Job ID

Prevent duplicate processing with custom IDs. Adding a job with the same ID as an existing job returns the existing one. This is critical for idempotent trade processing -- a player selling an item must never create duplicate trade jobs if the request is retried.

<tabs>
<tab title="Elixir">

```elixir
# Use trade ID as job ID to guarantee idempotent processing
trade_id = "TRD9f8x2kABC1D"
{:ok, job} = EchoMQ.Queue.add("inventory", "process-trade",
  %{item_id: "ITM8xN3vP7qR4K", from_player: "PLR0K48QjihpC4", to_player: "PLR3QR5T7V9W2X", quantity: 1},
  connection: :redis, job_id: "trade-#{trade_id}")

# Second add with same ID returns existing job (no duplicate trade)
{:ok, same_job} = EchoMQ.Queue.add("inventory", "process-trade",
  %{item_id: "ITM8xN3vP7qR4K", from_player: "PLR0K48QjihpC4", to_player: "PLR3QR5T7V9W2X", quantity: 1},
  connection: :redis, job_id: "trade-#{trade_id}")

# job.id == same_job.id -- the trade is processed exactly once
```

> **Benefit**: Named connections via `Redix` integrate into supervision trees — automatic reconnect on network partitions.

</tab>
<tab title="Go">

```go
// ---------------------------------------------------------------
// Custom job IDs are not yet exposed in the Go public API.
//
// Go generates UUIDs automatically via uuid.New(). The addJob
// Lua script supports custom IDs (it checks for existing keys),
// but the Go JobOptions struct does not include a JobID field.
//
// Workaround: For idempotent trade processing, use deduplication
// at the application layer (e.g., a Redis SET check before Add).
//
// Tracking: See PROTOCOL-GAPS.md for the implementation roadmap.
// ---------------------------------------------------------------
```

> **Benefit**: Rate limit config is declarative — the Lua script enforces limits atomically in Redis.

</tab>
<tab title="Node.js">

```typescript
const tradeId = "TRD9f8x2kABC1D";
const job = await queue.add("process-trade", {
  item_id: "ITM8xN3vP7qR4K", from_player: "PLR0K48QjihpC4",
  to_player: "PLR3QR5T7V9W2X", quantity: 1,
}, {
  jobId: `trade-${tradeId}`,
});

// Second add returns existing job -- no duplicate trade
const same = await queue.add("process-trade", {
  item_id: "ITM8xN3vP7qR4K", from_player: "PLR0K48QjihpC4",
  to_player: "PLR3QR5T7V9W2X", quantity: 1,
}, {
  jobId: `trade-${tradeId}`,
});
// job.id === same.id
```

> **Benefit**: Inline options object matches BullMQ's well-documented API — no translation needed.

</tab>
</tabs>

> **⚠️ Go Gap**: Custom job IDs are not supported. All jobs receive auto-generated UUIDs.
> **Proposed Solution**: Accept optional `JobID` in `JobOpts`, pass to `addStandardJob` Lua script's ARGV[2] position instead of generating UUID.

---

## 14.8. Deduplication

Deduplication provides fine-grained control over duplicate job prevention beyond simple `job_id` matching. In a game server, this prevents duplicate level-up rewards, throttles leaderboard recalculations, and debounces NPC pathfind recalculations when the world state changes rapidly. Three modes are supported:

| Mode | Configuration | Behavior |
|------|--------------|----------|
| **Simple** | `id` only | Deduplicate until job completes or fails |
| **Throttle** | `id` + `ttl` | Deduplicate for TTL duration |
| **Debounce** | `id` + `ttl` + `extend` + `replace` | Extend TTL and replace data on each duplicate |

<tabs>
<tab title="Elixir">

```elixir
# Simple: deduplicate level-up until the current one finishes processing
{:ok, job} = EchoMQ.Queue.add("player-events", "level-up",
  %{player_id: "PLR0K48QjihpC4", new_level: 25},
  connection: :redis,
  deduplication: %{id: "levelup-PLR0K48QjihpC4"})

# Throttle: one leaderboard recalculation per minute per bracket
{:ok, job} = EchoMQ.Queue.add("leaderboard", "recalculate-rankings",
  %{bracket: "gold", season: 7},
  connection: :redis,
  deduplication: %{id: "rankings-gold-s7", ttl: 60_000})

# Debounce: NPC pathfind recalculation -- only keep the latest target
{:ok, job} = EchoMQ.Queue.add("world-sync", "pathfind",
  %{npc_id: "NPC4pL8nQ3uV7X", destination: "waypoint-12"},
  connection: :redis,
  deduplication: %{
    id: "pathfind-NPC4pL8nQ3uV7X",
    ttl: 5_000,
    extend: true,
    replace: true
  })
```

The deduplication ID is stored as `deid` in the Redis hash and tracked via the `deduplication_id` field on the `EchoMQ.Job` struct. The ID is extracted from `opts.deduplication.id` during `Job.new/4`.

> **Benefit**: `removeOnComplete` with TTL uses Redis native expiry — no application-level cleanup needed.

</tab>
<tab title="Go">

```go
// ---------------------------------------------------------------
// Deduplication is not yet supported in the Go API.
//
// The underlying Lua scripts fully support deduplication (simple,
// throttle, and debounce modes) via the "deid" field in the job
// hash, but the Go JobOptions struct does not expose a
// Deduplication field to pass these options through.
//
// Workaround: Implement application-level deduplication using a
// Redis SET or SETNX guard before calling Queue.Add().
//
// Tracking: See PROTOCOL-GAPS.md for the implementation roadmap.
// ---------------------------------------------------------------
```

> **Benefit**: TTL-based job cleanup runs via Redis EXPIRE — no background goroutine required.

</tab>
<tab title="Node.js">

```typescript
// Simple: deduplicate level-up until completion
await queue.add("level-up", { player_id: "PLR0K48QjihpC4", new_level: 25 }, {
  deduplication: { id: "levelup-PLR0K48QjihpC4" },
});

// Throttle: one leaderboard recalculation per minute
await queue.add("recalculate-rankings", { bracket: "gold", season: 7 }, {
  deduplication: { id: "rankings-gold-s7", ttl: 60_000 },
});

// Debounce: NPC pathfind -- only keep the latest destination
await queue.add("pathfind", { npc_id: "NPC4pL8nQ3uV7X", destination: "waypoint-12" }, {
  deduplication: { id: "pathfind-NPC4pL8nQ3uV7X", ttl: 5000, extend: true, replace: true },
});
```

> **Benefit**: `removeOnComplete` accepts boolean or count — automatic cleanup with configurable history.

</tab>
</tabs>

> **Go Gap**: Job deduplication (simple, throttle, and debounce modes) is not implemented.
> **Proposed Solution**: Add `DeduplicationOpts` to `JobOpts` and wire through `addStandardJob` Lua script which already supports dedup parameters (ARGV dedup_id, dedup_ttl).

### Managing Deduplication

Query and remove deduplication state programmatically:

<tabs>
<tab title="Elixir">

```elixir
# Find which job started the deduplication
{:ok, job_id} = EchoMQ.Queue.get_deduplication_job_id("combat-actions", "pathfind-NPC4pL8nQ3uV7X",
  connection: :redis)
# => {:ok, "12345"} or {:ok, nil}

# Remove deduplication early — allows a new job to be queued immediately
{:ok, 1} = EchoMQ.Queue.remove_deduplication_key("combat-actions", "pathfind-NPC4pL8nQ3uV7X",
  connection: :redis)
```

</tab>
<tab title="Go">

```go
// Go does not yet expose deduplication management APIs.
// Workaround: query the Redis dedup key directly.
// Key format: bull:{queueName}:de:{dedupId}
key := fmt.Sprintf("bull:%s:de:%s", queueName, dedupID)
jobID, err := redisClient.Get(ctx, key).Result()
// To remove: redisClient.Del(ctx, key)
```

</tab>
<tab title="Node.js">

```typescript
// Query which job started the deduplication
const jobId = await queue.getDeduplicationJobId("pathfind-NPC4pL8nQ3uV7X");

// Remove deduplication early
await queue.removeDeduplicationKey("pathfind-NPC4pL8nQ3uV7X");
```

</tab>
</tabs>

**Common pattern — remove dedup when job starts processing**, allowing a new job to queue while the current one runs:

<tabs>
<tab title="Elixir">

```elixir
processor = fn job ->
  if dedup = job.opts[:deduplication] do
    EchoMQ.Queue.remove_deduplication_key("world-sync", dedup[:id],
      connection: :redis)
  end
  process_job(job.data)
end
```

</tab>
<tab title="Go">

```go
func processor(ctx context.Context, job *echomq.Job) (interface{}, error) {
    // Remove dedup key on start to allow next job to queue
    if dedupID, ok := job.Opts["deduplication_id"].(string); ok {
        key := fmt.Sprintf("bull:%s:de:%s", job.QueueName, dedupID)
        redisClient.Del(ctx, key)
    }
    return processJob(ctx, job)
}
```

</tab>
<tab title="Node.js">

```typescript
const worker = new Worker('world-sync', async (job) => {
  if (job.opts.deduplication?.id) {
    const queue = new Queue('world-sync', { connection });
    await queue.removeDeduplicationKey(job.opts.deduplication.id);
  }
  return processJob(job.data);
});
```

</tab>
</tabs>

### Deduplication Options Reference

| Option | Type | Required | Description |
|--------|------|----------|-------------|
| `id` | string | Yes | Unique identifier for deduplication |
| `ttl` | integer | No | Time-to-live in milliseconds |
| `extend` | boolean | No | Extend TTL on each duplicate |
| `replace` | boolean | No | Replace job data while delayed |

### Deduplication Best Practices

1. **Use meaningful IDs** that represent the logical operation: `"sync-user-#{user_id}"` rather than generic values.
2. **Simple mode for critical operations** that must not run twice simultaneously (level-up rewards, payment processing).
3. **Throttle mode for rate limiting** — limit how often a job can be triggered (leaderboard recalculations).
4. **Debounce mode for frequent updates** — collapse rapid updates into one (NPC pathfinding, search index updates).
5. **Remove dedup on active** when you want to allow queuing the next job while the current one runs.

---

## 14.9. Repeatable Jobs

Schedule recurring jobs with interval or cron patterns. In a game server, repeatables drive world heartbeats, daily ranking resets, and time-limited seasonal events.

<tabs>
<tab title="Elixir">

```elixir
# World heartbeat every 5 minutes (stalled job detection, NPC respawns)
{:ok, _} = EchoMQ.Queue.add("world-sync", "spawn-npc", %{zone: "dungeon-7"},
  connection: :redis,
  repeat: %{every: 300_000})

# Daily ranking reset at 9 AM UTC
{:ok, _} = EchoMQ.Queue.add("leaderboard", "recalculate-rankings", %{season: 7},
  connection: :redis,
  repeat: %{pattern: "0 9 * * *"})

# 7-day seasonal event reminder (limited repetitions)
{:ok, _} = EchoMQ.Queue.add("player-events", "unlock-achievement",
  %{event: "summer-festival"},
  connection: :redis,
  repeat: %{every: 86_400_000, limit: 7})

# Prime-time bonus XP (weekdays 6-10 PM Eastern)
{:ok, _} = EchoMQ.Queue.add("player-events", "player-login",
  %{bonus: "double-xp"},
  connection: :redis,
  repeat: %{pattern: "0 18 * * 1-5", tz: "America/New_York"})
```

> **Benefit**: Repeatable jobs persist in Redis — BEAM node restarts resume the schedule automatically.

</tab>
<tab title="Go">

```go
// ---------------------------------------------------------------
// Repeatable jobs are not yet supported in the Go API.
//
// Repeatables require the addRepeatableJob Lua script and a
// dedicated JobScheduler process (available in Elixir and
// Node.js). The Go runtime does not include a scheduler.
//
// Workaround: Use a goroutine with time.Ticker to call
// Queue.Add() on a fixed interval, or use an external cron
// scheduler (e.g., systemd timer) to trigger job creation.
//
// Tracking: See PROTOCOL-GAPS.md for the implementation roadmap.
// ---------------------------------------------------------------
```

> **Tradeoff**: Go has no built-in cron — scheduler must use `time.Ticker` or external cron library.

</tab>
<tab title="Node.js">

```typescript
// World heartbeat every 5 minutes
await queue.add("spawn-npc", { zone: "dungeon-7" }, {
  repeat: { every: 300_000 },
});

// Daily ranking reset at 9 AM UTC
await queue.add("recalculate-rankings", { season: 7 }, {
  repeat: { pattern: "0 9 * * *" },
});

// 7-day seasonal event reminder
await queue.add("unlock-achievement", { event: "summer-festival" }, {
  repeat: { every: 86_400_000, limit: 7 },
});
```

> **Benefit**: Repeatable job API matches BullMQ — `every` and `pattern` (cron) options available.

</tab>
</tabs>

### Cron Patterns

| Pattern | Schedule | Game Example |
|---------|----------|-------------|
| `* * * * *` | Every minute | Stalled job health check |
| `0 * * * *` | Every hour | Zone NPC respawn sweep |
| `0 9 * * *` | Daily at 9 AM | Leaderboard ranking reset |
| `0 9 * * 1` | Every Monday at 9 AM | Weekly tournament start |
| `0 0 1 * *` | First of each month | Season rollover |
| `0 18 * * 1-5` | Weekdays at 6 PM | Prime-time bonus XP activation |

### Repeat Options Reference

| Option | Type | Description |
|--------|------|-------------|
| `pattern` | string | Cron expression |
| `every` | integer | Interval in milliseconds |
| `limit` | integer | Max number of repetitions |
| `start_date` | DateTime/integer | When to start repeating |
| `end_date` | DateTime/integer | When to stop repeating |
| `tz` | string | Timezone for cron (e.g., `"America/New_York"`) |
| `immediately` | boolean | Run first occurrence immediately |
| `offset` | integer | Offset for `every` in ms |
| `count` | integer | Current repetition count |

---

## 14.10. Elixir-Specific: Keyword List Syntax and NimbleOptions

In Elixir, job options are passed as a keyword list to `EchoMQ.Queue.add/4`. The function accepts both keyword lists and maps:

```elixir
# Keyword list (idiomatic Elixir)
EchoMQ.Queue.add("combat-actions", "calculate-damage",
  %{player_id: "PLR0K48QjihpC4", action: "attack", target_id: "NPC5rK2mJ9pQ1L", damage: 150},
  connection: :my_redis,
  priority: 1,
  attempts: 3,
  backoff: %{type: :exponential, delay: 1000},
  remove_on_complete: %{age: 3600},
  remove_on_fail: %{count: 500})
```

`EchoMQ.Job.new/4` converts keyword lists to maps internally. The Queue GenServer mode uses `NimbleOptions` for compile-time validation of queue-level configuration options (`:name`, `:queue`, `:connection`, `:prefix`, `:default_job_opts`, `:telemetry`, `:skip_meta_update`, `:streams`).

### Option Encoding for Redis

Elixir uses snake_case option names internally, but encodes them to short keys for Redis storage to maintain Node.js interoperability. The `@opts_encode_map` in `EchoMQ.Job` handles this transparently:

| Elixir Option | Redis Short Key |
|---------------|----------------|
| `deduplication` | `de` |
| `fail_parent_on_failure` | `fpof` |
| `continue_parent_on_failure` | `cpof` |
| `ignore_dependency_on_failure` | `idof` |
| `keep_logs` | `kl` |
| `remove_dependency_on_failure` | `rdof` |
| `telemetry_metadata` | `tm` |
| `omit_context` | `omc` |

When reading jobs back from Redis, the `@opts_decode_map` reverses this mapping.

---

## 14.11. Combined Options (Production Example)

A production-ready configuration for a critical combat action that combines priority, retry, idempotency, and cleanup:

<tabs>
<tab title="Elixir">

```elixir
{:ok, job} = EchoMQ.Queue.add("combat-actions", "resolve-skill", %{
  player_id: "PLR0K48QjihpC4",
  skill_id: "dragon_breath",
  target_id: "NPC5rK2mJ9pQ1L",
  damage: 450,
  room_id: "dungeon-7"
},
  connection: :my_redis,

  # Idempotency: one resolution per combat action
  job_id: "combat-PLR0K48QjihpC4-dragon_breath-#{System.unique_integer([:positive])}",

  # Critical priority: damage resolution before anything else
  priority: 1,

  # Robust retry with exponential backoff + jitter
  attempts: 5,
  backoff: %{type: :exponential, delay: 2000, jitter: 0.15},

  # Cleanup: keep resolved actions for 1 hour, failed for 24 hours
  remove_on_complete: %{age: 3600},
  remove_on_fail: %{age: 86400}
)
```

> **Benefit**: Custom backoff functions receive attempt count and error — full context for delay calculation.

</tab>
<tab title="Go">

```go
job, err := queue.Add(ctx, "resolve-skill",
    map[string]interface{}{
        "player_id": "PLR0K48QjihpC4",
        "skill_id":  "dragon_breath",
        "target_id": "NPC5rK2mJ9pQ1L",
        "damage":    450,
        "room_id":   "dungeon-7",
    },
    echomq.JobOptions{
        // Critical priority
        Priority: 1,

        // Robust retry
        Attempts: 5,
        Backoff:  echomq.BackoffConfig{Type: "exponential", Delay: 2000},

        // Cleanup
        RemoveOnComplete: echomq.RemoveOnSetting{Age: 3600},
        RemoveOnFail:     echomq.RemoveOnSetting{Age: 86400},
    })
```

> **Benefit**: Backoff configuration is declarative — `Type` and `Delay` fields are validated at compile time.

</tab>
<tab title="Node.js">

```typescript
const job = await queue.add("resolve-skill", {
  player_id: "PLR0K48QjihpC4",
  skill_id: "dragon_breath",
  target_id: "NPC5rK2mJ9pQ1L",
  damage: 450,
  room_id: "dungeon-7",
}, {
  jobId: `combat-PLR0K48QjihpC4-dragon_breath-${Date.now()}`,
  priority: 1,
  attempts: 5,
  backoff: { type: "exponential", delay: 2000 },
  removeOnComplete: { age: 3600 },
  removeOnFail: { age: 86400 },
});
```

> **Benefit**: Custom backoff functions return millisecond delay — simple numeric interface.

</tab>
</tabs>

---

## 14.12. Feature Support Matrix

| Option | Elixir | Go | Node.js |
|--------|--------|----|---------|
| Priority | Yes | Yes | Yes |
| Delay | Yes | Yes | Yes |
| Attempts/Backoff | Yes | Yes | Yes |
| LIFO | Yes | Planned | Yes |
| Custom Job ID | Yes | Planned | Yes |
| RemoveOnComplete | Yes | Yes | Yes |
| RemoveOnFail | Yes | Yes | Yes |
| Repeatable/Cron | Yes | Planned | Yes |
| Deduplication | Yes | Planned | Yes |
| FlowProducer | Yes | Planned | Yes |

See [Go Architecture](ch05-go-architecture.md) for the full Go implementation roadmap and [Cross-Language Interop](ch06-cross-language-interop.md) for known divergences.

---

## 14.13. What's Next

- [Queues](ch15-queues.md) -- Queue creation, bulk operations, pausing, draining, and rate limiting
- [Workers](ch16-workers.md) -- Job processing, concurrency, and event handling
- [Job Lifecycle](ch13-job-lifecycle.md) -- State transitions from creation to completion

---

*Previous: [Job Lifecycle](ch13-job-lifecycle.md) | Next: [Queues](ch15-queues.md)*
