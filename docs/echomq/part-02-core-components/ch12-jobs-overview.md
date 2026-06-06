# Chapter 12. Jobs Overview

A job is the fundamental unit of work in EchoMQ. Every job carries a **name** (routing key), a **data** payload, and **options** that control how it is processed. All three runtimes share the same Redis-backed job representation, so a job created by one language is fully readable and processable by another.

## 12.1. Job Structure

Every job contains these core fields, persisted as a Redis hash:

| Field | Redis Key | Description |
|-------|-----------|-------------|
| `id` | (hash key) | Unique identifier (auto-generated or custom) |
| `name` | `name` | Job type for routing to the correct processor |
| `data` | `data` | JSON-encoded payload |
| `opts` | `opts` | JSON-encoded configuration (priority, delay, retries, backoff) |
| `timestamp` | `timestamp` | Creation time (Unix ms) |
| `delay` | `delay` | Delay before processing (ms) |
| `priority` | `priority` | Priority level (0 = highest) |
| `progress` | `progress` | Processing progress (0-100 or custom JSON) |
| `returnvalue` | `returnvalue` | Result after successful completion |
| `failedReason` | `failedReason` | Error message if failed |
| `attemptsMade` / `atm` | `attemptsMade` | Number of processing attempts completed |
| `ats` | `ats` | Number of attempts started |
| `stc` | `stc` | Stall detection counter |
| `processedOn` | `processedOn` | Timestamp when processing started (Unix ms) |
| `finishedOn` | `finishedOn` | Timestamp when completed or failed (Unix ms) |
| `parentKey` | `parentKey` | Parent job Redis key (for flows) |
| `processedBy` | `processedBy` | Worker that processed this job |
| `rjk` | `rjk` | Repeatable job key |
| `deid` | `deid` | Deduplication identifier |

<tabs>
<tab title="Elixir">

```elixir
%EchoMQ.Job{
  id: "a1b2c3d4e5f6a7b8c9d0e1f2",
  name: "calculate-damage",
  data: %{
    player_id: "PLR0K48QjihpC4",
    action: "attack",
    target_id: "NPC5rK2mJ9pQ1L",
    damage: 150,
    room_id: "dungeon-7"
  },
  opts: %{
    priority: 1,
    attempts: 3,
    delay: 0
  },
  queue_name: "combat-actions",
  prefix: "bull",
  timestamp: 1706832000000,
  delay: 0,
  priority: 1,
  progress: 0,
  return_value: nil,
  failed_reason: nil,
  stacktrace: [],
  attempts_made: 0,
  attempts_started: 0,
  stalled_counter: 0,
  processed_on: nil,
  finished_on: nil,
  parent_key: nil,
  parent: nil,
  processed_by: nil,
  repeat_job_key: nil,
  deduplication_id: nil,
  deferred_failure: nil
}
```

The Elixir struct uses snake_case field names. When reading from Redis, `EchoMQ.Job.from_redis/4` translates camelCase Redis fields (e.g., `processedOn`) to snake_case (`processed_on`) and expands compressed short keys (e.g., `atm` to `attempts_made`, `deid` to `deduplication_id`).

The opts map also uses short keys for Redis storage -- the `@opts_encode_map` in `EchoMQ.Job` maps full names like `fail_parent_on_failure` to `fpof` for Node.js interoperability.

> **Benefit**: OpenTelemetry BEAM SDK propagates trace context across process boundaries automatically.

</tab>
<tab title="Go">

```go
&echomq.Job{
    ID:           "MTH0K5M2vuIULY",
    Name:         "calculate-damage",
    Data:         map[string]interface{}{
        "player_id": "PLR0K48QjihpC4",
        "action":    "attack",
        "target_id": "NPC5rK2mJ9pQ1L",
        "damage":    150,
        "room_id":   "dungeon-7",
    },
    Opts:         echomq.JobOptions{
        Priority: 1,
        Attempts: 3,
        Delay:    0,
    },
    Timestamp:    1706832000000,
    Progress:     0,
    ReturnValue:  nil,
    FailedReason: "",
    AttemptsMade: 0,
    ProcessedOn:  0,
    FinishedOn:   0,
}
```

Go uses a typed `JobOptions` struct with dedicated fields for `RemoveOnComplete`, `RemoveOnFail`, and `BackoffConfig`.

> **Benefit**: Backoff configuration is declarative — `Type` and `Delay` fields are validated at compile time.

</tab>
<tab title="Node.js">

```typescript
{
  id: "1",
  name: "calculate-damage",
  data: {
    player_id: "PLR0K48QjihpC4",
    action: "attack",
    target_id: "NPC5rK2mJ9pQ1L",
    damage: 150,
    room_id: "dungeon-7",
  },
  opts: {
    priority: 1,
    attempts: 3,
    delay: 0,
  },
  timestamp: 1706832000000,
  progress: 0,
  returnvalue: undefined,
  failedReason: "",
  attemptsMade: 0,
  processedOn: undefined,
  finishedOn: undefined,
}
```

Node.js BullMQ auto-increments integer IDs by default. The `opts` object supports the full range of BullMQ options.

> **Benefit**: Priority values mirror BullMQ's proven sorted set implementation.

</tab>
</tabs>

### Auto-generated IDs

Each runtime generates unique IDs in its own format:

| Runtime | ID Format | Example |
|---------|-----------|---------|
| Elixir | 24-char hex (`crypto.strong_rand_bytes/1`) | `"a1b2c3d4e5f6a7b8c9d0e1f2"` |
| Go | UUID v4 | `"f47ac10b-58cc-4372-a567-0e02b2c3d479"` |
| Node.js | Auto-incrementing integer | `"1"`, `"2"`, `"3"` |

---

## 12.2. Job Types

EchoMQ supports multiple job ordering modes that can be mixed in the same queue:

| Type | Description | Use Case |
|------|-------------|----------|
| **FIFO** | First-in-first-out | Default, ordered processing |
| **LIFO** | Last-in-first-out | Stack-like, newest first |
| **Delayed** | Future execution | Scheduled tasks |
| **Prioritized** | Priority ordering | Urgent jobs first |
| **Repeatable** | Recurring schedule | Cron-like patterns |

### FIFO Jobs (Default)

Jobs added without special options process in the order they were submitted. In a combat system, this ensures damage calculations resolve in the order attacks were issued.

<tabs>
<tab title="Elixir">

```elixir
{:ok, job1} = EchoMQ.Queue.add("combat-actions", "calculate-damage",
  %{player_id: "PLR0K48QjihpC4", target_id: "NPC5rK2mJ9pQ1L", damage: 120}, connection: :redis)
{:ok, job2} = EchoMQ.Queue.add("combat-actions", "calculate-damage",
  %{player_id: "PLR3QR5T7V9W2X", target_id: "NPC5rK2mJ9pQ1L", damage: 85}, connection: :redis)
{:ok, job3} = EchoMQ.Queue.add("combat-actions", "apply-buff",
  %{player_id: "PLR0K48QjihpC4", buff: "shield", duration: 30_000}, connection: :redis)

# Processing order: PLR0K48QjihpC4 attack -> PLR3QR5T7V9W2X attack -> PLR0K48QjihpC4 buff
```

> **Benefit**: Named connections via `Redix` integrate into supervision trees — automatic reconnect on network partitions.

</tab>
<tab title="Go">

```go
queue := echomq.NewQueue("combat-actions", rdb)

job1, _ := queue.Add(ctx, "calculate-damage",
    map[string]interface{}{"player_id": "PLR0K48QjihpC4", "target_id": "NPC5rK2mJ9pQ1L", "damage": 120},
    echomq.JobOptions{})
job2, _ := queue.Add(ctx, "calculate-damage",
    map[string]interface{}{"player_id": "PLR3QR5T7V9W2X", "target_id": "NPC5rK2mJ9pQ1L", "damage": 85},
    echomq.JobOptions{})
job3, _ := queue.Add(ctx, "apply-buff",
    map[string]interface{}{"player_id": "PLR0K48QjihpC4", "buff": "shield", "duration": 30000},
    echomq.JobOptions{})

// Processing order: PLR0K48QjihpC4 attack -> PLR3QR5T7V9W2X attack -> PLR0K48QjihpC4 buff
```

> **Benefit**: Strongly-typed option structs catch misconfiguration at compile time.

</tab>
<tab title="Node.js">

```typescript
const queue = new Queue("combat-actions", { connection });

await queue.add("calculate-damage", { player_id: "PLR0K48QjihpC4", target_id: "NPC5rK2mJ9pQ1L", damage: 120 });
await queue.add("calculate-damage", { player_id: "PLR3QR5T7V9W2X", target_id: "NPC5rK2mJ9pQ1L", damage: 85 });
await queue.add("apply-buff", { player_id: "PLR0K48QjihpC4", buff: "shield", duration: 30000 });

// Processing order: PLR0K48QjihpC4 attack -> PLR3QR5T7V9W2X attack -> PLR0K48QjihpC4 buff
```

> **Benefit**: `ioredis` connection with lazy initialization — Redis connects only when the first command is issued.

</tab>
</tabs>

### LIFO Jobs

With LIFO enabled, the most recently added job processes first. This is useful in game scenarios where you want to process the latest world state snapshot before older ones.

<tabs>
<tab title="Elixir">

```elixir
# Sync the most recent world state first (newest snapshot wins)
{:ok, _} = EchoMQ.Queue.add("world-sync", "zone-transition",
  %{player_id: "PLR0K48QjihpC4", zone: "forest", snapshot: 1}, connection: :redis, lifo: true)
{:ok, _} = EchoMQ.Queue.add("world-sync", "zone-transition",
  %{player_id: "PLR0K48QjihpC4", zone: "dungeon-7", snapshot: 2}, connection: :redis, lifo: true)
{:ok, _} = EchoMQ.Queue.add("world-sync", "zone-transition",
  %{player_id: "PLR0K48QjihpC4", zone: "crystal-caves", snapshot: 3}, connection: :redis, lifo: true)

# Processing order: crystal-caves -> dungeon-7 -> forest
```

> **Benefit**: Named connections via `Redix` integrate into supervision trees — automatic reconnect on network partitions.

</tab>
<tab title="Go">

```go
// Go does not support a LIFO option on Add().
//
// How FIFO works in Go:
//   queue_impl.go uses LPush to add job IDs to the wait list
//   (bull:{queue}:wait). Workers consume from the right via RPop,
//   producing FIFO order (left-push, right-pop).
//
// What LIFO would require:
//   LIFO reverses the push direction — using RPush instead of LPush
//   so the newest job is consumed first (right-push, right-pop).
//   The BullMQ addJob Lua script accepts a "LIFO" argument that
//   switches the push command. Go's enqueueJob() hardcodes LPush
//   and does not accept this parameter.
//
// Workaround:
//   For game scenarios where newest-first matters (e.g., processing
//   the latest world state snapshot), use a priority queue with a
//   timestamp-based priority (lower = newer = higher priority).
```

> **Benefit**: Priority encoding uses composite score combining priority level and insertion order.

</tab>
<tab title="Node.js">

```typescript
const queue = new Queue("world-sync", { connection });

await queue.add("zone-transition", { player_id: "PLR0K48QjihpC4", zone: "forest", snapshot: 1 }, { lifo: true });
await queue.add("zone-transition", { player_id: "PLR0K48QjihpC4", zone: "dungeon-7", snapshot: 2 }, { lifo: true });
await queue.add("zone-transition", { player_id: "PLR0K48QjihpC4", zone: "crystal-caves", snapshot: 3 }, { lifo: true });

// Processing order: crystal-caves -> dungeon-7 -> forest
```

> **Benefit**: `ioredis` connection with lazy initialization — Redis connects only when the first command is issued.

</tab>
</tabs>

### Delayed Jobs

Jobs scheduled for future execution enter the DELAYED state and move to WAITING when their time arrives. Perfect for NPC respawn timers, buff expirations, and scheduled game events.

<tabs>
<tab title="Elixir">

```elixir
# Respawn NPC after 30-second cooldown
{:ok, job} = EchoMQ.Queue.add("world-sync", "spawn-npc",
  %{npc_id: "NPC5rK2mJ9pQ1L", zone: "dungeon-7", hp: 5000},
  connection: :redis, delay: 30_000)

# Schedule a tournament start at a specific time
target = ~U[2026-06-01 20:00:00Z]
delay_ms = DateTime.diff(target, DateTime.utc_now(), :millisecond)
{:ok, job} = EchoMQ.Queue.add("matchmaking", "create-lobby",
  %{tournament_id: "TRN5cT7uW9yA1H", mode: "ranked"},
  connection: :redis, delay: max(0, delay_ms))

# Expire a buff after 2 hours using Erlang timer helpers
{:ok, job} = EchoMQ.Queue.add("combat-actions", "remove-buff",
  %{player_id: "PLR0K48QjihpC4", buff: "shield"},
  connection: :redis, delay: :timer.hours(2))
```

> **Benefit**: GenServer-based schedulers integrate with supervision — restarts guarantee schedule continuity.

</tab>
<tab title="Go">

```go
queue := echomq.NewQueue("world-sync", rdb)

// Respawn NPC after 30-second cooldown
job, err := queue.Add(ctx, "spawn-npc",
    map[string]interface{}{
        "npc_id": "NPC5rK2mJ9pQ1L",
        "zone":   "dungeon-7",
        "hp":     5000,
    },
    echomq.JobOptions{Delay: 30 * time.Second})

// Schedule a season reset in 1 hour
job, err = queue.Add(ctx, "recalculate-rankings",
    map[string]interface{}{"season": "S12"},
    echomq.JobOptions{Delay: time.Hour})
```

Go uses `time.Duration` for the delay, which is converted to milliseconds internally for Redis storage.

> **Tradeoff**: Go has no built-in cron — scheduler must use `time.Ticker` or external cron library.

</tab>
<tab title="Node.js">

```typescript
const queue = new Queue("world-sync", { connection });

// Respawn NPC after 30-second cooldown
await queue.add("spawn-npc", {
  npc_id: "NPC5rK2mJ9pQ1L", zone: "dungeon-7", hp: 5000,
}, { delay: 30_000 });

// Schedule a tournament start at a specific time
const target = new Date("2026-06-01T20:00:00Z");
const delay = Math.max(0, target.getTime() - Date.now());
await queue.add("create-lobby", {
  tournament_id: "TRN5cT7uW9yA1H", mode: "ranked",
}, { delay });
```

> **Benefit**: `upsertJobScheduler` is Redis-persisted and idempotent — safe across process restarts.

</tab>
</tabs>

### Prioritized Jobs

Priority determines processing order. Lower values equal higher priority (0 is highest, like Unix nice). In a game combat system, damage calculations should resolve before buff applications.

<tabs>
<tab title="Elixir">

```elixir
# Damage calculations are urgent (priority 1)
{:ok, _} = EchoMQ.Queue.add("combat-actions", "calculate-damage",
  %{player_id: "PLR0K48QjihpC4", target_id: "NPC5rK2mJ9pQ1L", damage: 250},
  connection: :redis, priority: 1)

# Buff applications are normal priority (priority 5)
{:ok, _} = EchoMQ.Queue.add("combat-actions", "apply-buff",
  %{player_id: "PLR3QR5T7V9W2X", buff: "heal", amount: 100},
  connection: :redis, priority: 5)

# Leaderboard updates are background (priority 100)
{:ok, _} = EchoMQ.Queue.add("combat-actions", "update-score",
  %{player_id: "PLR0K48QjihpC4", xp_gained: 500},
  connection: :redis, priority: 100)

# Processing order: damage calc -> buff -> leaderboard
```

> **Benefit**: Priority maps to Redis sorted set scores — atomic ordering without application-level sorting.

</tab>
<tab title="Go">

```go
queue := echomq.NewQueue("combat-actions", rdb)

// Damage calculations are urgent (priority 1)
queue.Add(ctx, "calculate-damage",
    map[string]interface{}{"player_id": "PLR0K48QjihpC4", "target_id": "NPC5rK2mJ9pQ1L", "damage": 250},
    echomq.JobOptions{Priority: 1})

// Buff applications are normal priority (priority 5)
queue.Add(ctx, "apply-buff",
    map[string]interface{}{"player_id": "PLR3QR5T7V9W2X", "buff": "heal", "amount": 100},
    echomq.JobOptions{Priority: 5})

// Leaderboard updates are background (priority 100)
queue.Add(ctx, "update-score",
    map[string]interface{}{"player_id": "PLR0K48QjihpC4", "xp_gained": 500},
    echomq.JobOptions{Priority: 100})

// Processing order: damage calc -> buff -> leaderboard
```

Go stores prioritized jobs in a Redis sorted set using a composite score (`priority * 0x100000000 + counter`), dequeued by `ZPopMin` in the worker loop. This preserves FIFO ordering within the same priority level.

> **Benefit**: Priority encoding uses composite score combining priority level and insertion order.

</tab>
<tab title="Node.js">

```typescript
const queue = new Queue("combat-actions", { connection });

// Damage calculations are urgent (priority 1)
await queue.add("calculate-damage", {
  player_id: "PLR0K48QjihpC4", target_id: "NPC5rK2mJ9pQ1L", damage: 250,
}, { priority: 1 });

// Buff applications are normal priority (priority 5)
await queue.add("apply-buff", {
  player_id: "PLR3QR5T7V9W2X", buff: "heal", amount: 100,
}, { priority: 5 });

// Leaderboard updates are background (priority 100)
await queue.add("update-score", {
  player_id: "PLR0K48QjihpC4", xp_gained: 500,
}, { priority: 100 });

// Processing order: damage calc -> buff -> leaderboard
```

> **Benefit**: Priority values mirror BullMQ's proven sorted set implementation.

</tab>
</tabs>

---

## 12.3. Job Data

### Data Serialization

Job data is serialized to JSON for Redis storage. This means only JSON-compatible types are supported.

<tabs>
<tab title="Elixir">

```elixir
# Supported types — a combat action payload
{:ok, job} = EchoMQ.Queue.add("combat-actions", "resolve-skill", %{
  player_id: "PLR0K48QjihpC4",
  skill_name: "fireball",
  damage: 150,
  crit_multiplier: 1.5,
  aoe: true,
  targets: ["NPC8xN3vP7qR4K", "NPC2wM6kR9sT1J", "NPC4pL8nQ3uV7X"],
  modifiers: %{element: "fire", level_bonus: 12},
  cooldown_override: nil
}, connection: :redis)

# NOT supported (will fail or lose data)
# - Atoms (converted to strings by Jason)
# - Tuples (use lists instead)
# - PIDs, refs, functions
# - Structs (convert to maps with type marker)
```

For structs, convert to maps with a type marker before enqueuing:

```elixir
defmodule Fireheadz.TradeOffer do
  defstruct [:from_player, :to_player, :items, :gold]

  def to_job_data(%__MODULE__{} = trade) do
    %{"_type" => "TradeOffer", "from_player" => trade.from_player,
      "to_player" => trade.to_player, "items" => trade.items,
      "gold" => trade.gold}
  end

  def from_job_data(%{"_type" => "TradeOffer"} = data) do
    %__MODULE__{from_player: data["from_player"], to_player: data["to_player"],
      items: data["items"], gold: data["gold"]}
  end
end
```

The `EchoMQ.Job` module uses `Jason.encode!/1` for serialization and `Jason.decode/1` for deserialization, so any data that Jason can encode is valid.

> **Benefit**: Named connections via `Redix` integrate into supervision trees — automatic reconnect on network partitions.

</tab>
<tab title="Go">

```go
job, err := queue.Add(ctx, "resolve-skill",
    map[string]interface{}{
        "player_id":       "PLR0K48QjihpC4",
        "skill_name":      "fireball",
        "damage":          150,
        "crit_multiplier": 1.5,
        "aoe":             true,
        "targets":         []interface{}{"NPC8xN3vP7qR4K", "NPC2wM6kR9sT1J", "NPC4pL8nQ3uV7X"},
        "modifiers":       map[string]interface{}{"element": "fire", "level_bonus": 12},
    }, echomq.JobOptions{})
```

Go uses `map[string]interface{}` for job data, which means JSON numbers deserialize as `float64`. If integer precision matters (e.g., exact gold amounts in trades), use string-encoded numbers or verify at the consumer. See PROTOCOL-GAPS.md (GAP-001) for details.

> **Benefit**: Strongly-typed option structs catch misconfiguration at compile time.

</tab>
<tab title="Node.js">

```typescript
await queue.add("resolve-skill", {
  player_id: "PLR0K48QjihpC4",
  skill_name: "fireball",
  damage: 150,
  crit_multiplier: 1.5,
  aoe: true,
  targets: ["NPC8xN3vP7qR4K", "NPC2wM6kR9sT1J", "NPC4pL8nQ3uV7X"],
  modifiers: { element: "fire", level_bonus: 12 },
  cooldown_override: null,
});
```

> **Benefit**: JSON job data requires no serialization step — JavaScript objects are the wire format.

</tab>
</tabs>

### Large Data Patterns

For large payloads, store data externally and reference it in the job. Redis is optimized for small keys; large payloads slow down the entire queue. Game replays, world state snapshots, and match telemetry are common examples.

<tabs>
<tab title="Elixir">

```elixir
# Store match replay reference, not the full replay data
{:ok, replay_url} = Fireheadz.Storage.store_replay(match_data)
{:ok, job} = EchoMQ.Queue.add("matchmaking", "process-replay", %{
  match_id: "MTH0K5M2vuIULY",
  replay_ref: replay_url
}, connection: :redis)

# In worker — fetch replay data on demand
def process(%EchoMQ.Job{data: %{"replay_ref" => ref, "match_id" => match_id}}) do
  replay = Fireheadz.Storage.fetch_replay(ref)
  stats = analyze_match(replay)
  {:ok, %{match_id: match_id, stats_url: stats.url}}
end
```

> **Benefit**: Named connections via `Redix` integrate into supervision trees — automatic reconnect on network partitions.

</tab>
<tab title="Go">

```go
// Store match replay reference, not the full data
replayRef, _ := storage.StoreReplay(ctx, matchData)
queue.Add(ctx, "process-replay",
    map[string]interface{}{
        "match_id":   "MTH0K5M2vuIULY",
        "replay_ref": replayRef,
    }, echomq.JobOptions{})

// In worker processor — fetch on demand
worker.Process(func(job *echomq.Job) (interface{}, error) {
    ref := job.Data["replay_ref"].(string)
    replay, _ := storage.FetchReplay(ctx, ref)
    stats := analyzeMatch(replay)
    return map[string]interface{}{"stats_url": stats.URL}, nil
})
```

> **Benefit**: Returned `error` values make every failure path visible in the code flow.

</tab>
<tab title="Node.js">

```typescript
// Store match replay reference, not the full data
const replayRef = await storage.storeReplay(matchData);
await queue.add("process-replay", {
  match_id: "MTH0K5M2vuIULY",
  replay_ref: replayRef,
});

// In worker — fetch replay data on demand
const worker = new Worker("matchmaking", async (job) => {
  const replay = await storage.fetchReplay(job.data.replay_ref);
  const stats = analyzeMatch(replay);
  return { match_id: job.data.match_id, stats_url: stats.url };
});
```

> **Benefit**: JSON job data requires no serialization step — JavaScript objects are the wire format.

</tab>
</tabs>

---

## 12.4. Adding Jobs

### Basic Add

<tabs>
<tab title="Elixir">

```elixir
# Stateless function call (no GenServer needed)
{:ok, job} = EchoMQ.Queue.add("player-events", "player-login",
  %{player_id: "PLR0K48QjihpC4", zone: "crystal-caves", level: 42},
  connection: :my_redis)

IO.puts("Job created: #{job.id}")

# With options — process a trade with retries and cleanup
{:ok, job} = EchoMQ.Queue.add("inventory", "process-trade",
  %{item_id: "ITM8xN3vP7qR4K", from_player: "PLR0K48QjihpC4", to_player: "PLR3QR5T7V9W2X", quantity: 1},
  connection: :my_redis,
  attempts: 5,
  backoff: %{type: :exponential, delay: 1000},
  remove_on_complete: %{age: 3600})
```

`EchoMQ.Queue.add/4` accepts the queue name as a string (stateless, requires `:connection` option) or as an atom/pid (GenServer mode, connection stored in state). Options are passed as a keyword list, which `EchoMQ.Job.new/4` converts to a map internally.

> **Benefit**: Custom backoff functions receive attempt count and error — full context for delay calculation.

</tab>
<tab title="Go">

```go
queue := echomq.NewQueue("player-events", rdb)

job, err := queue.Add(ctx, "player-login",
    map[string]interface{}{
        "player_id": "PLR0K48QjihpC4",
        "zone":      "crystal-caves",
        "level":     42,
    }, echomq.JobOptions{})

fmt.Printf("Job created: %s\n", job.ID)
```

> **Benefit**: Channel-based event delivery integrates naturally with Go's select statement for multiplexing.

</tab>
<tab title="Node.js">

```typescript
const queue = new Queue("player-events", { connection });

const job = await queue.add("player-login", {
  player_id: "PLR0K48QjihpC4",
  zone: "crystal-caves",
  level: 42,
});

console.log(`Job created: ${job.id}`);
```

> **Benefit**: EventEmitter pattern is native to Node.js — existing event-handling code works directly.

</tab>
</tabs>

### Bulk Add

Adding multiple jobs atomically reduces round-trips to Redis. Useful for batch game operations like registering all players in a tournament lobby or processing end-of-match rewards.

<tabs>
<tab title="Elixir">

```elixir
# Tuple format: {name, data, opts}
# Register all players joining a tournament lobby
jobs = [
  {"find-match", %{player_id: "PLR0K48QjihpC4", rank: 1200, mode: "ranked"}, []},
  {"find-match", %{player_id: "PLR3QR5T7V9W2X", rank: 1150, mode: "ranked"}, []},
  {"find-match", %{player_id: "PLR5M2vuIULYab", rank: 1300, mode: "ranked"}, [priority: 1]}
]

{:ok, added_jobs} = EchoMQ.Queue.add_bulk("matchmaking", jobs,
  connection: :my_redis)
```

Bulk add uses Redis `MULTI/EXEC` transactions for atomicity and achieves up to 10x throughput compared to sequential adds (~60,000 jobs/sec vs ~6,000 jobs/sec). Configure `chunk_size:` (default 100) and `connection_pool:` for parallel chunk processing.

> **Benefit**: `Ecto.Multi` composes the enqueue step into the database transaction — atomic commit or rollback.

</tab>
<tab title="Go">

```go
// Go does not provide a bulk add API. Each queue.Add() call issues
// its own Redis commands (HSET + LPUSH/ZADD). For high-throughput
// scenarios, use a goroutine pool with error collection:
type addResult struct {
    Job *echomq.Job
    Err error
}

players := []string{"PLR0K48QjihpC4", "PLR3QR5T7V9W2X", "PLR5M2vuIULYab"}
results := make([]addResult, len(players))

var wg sync.WaitGroup
for i, playerID := range players {
    wg.Add(1)
    go func(idx int, pid string) {
        defer wg.Done()
        job, err := queue.Add(ctx, "player-login",
            map[string]interface{}{"player_id": pid},
            echomq.JobOptions{})
        results[idx] = addResult{Job: job, Err: err}
    }(i, playerID)
}
wg.Wait()

// Check for errors
for _, r := range results {
    if r.Err != nil {
        log.Printf("Failed to enqueue: %v", r.Err)
    }
}
```

> **Note:** This is NOT atomic like Elixir's `add_bulk` (which uses MULTI/EXEC). Some jobs may succeed while others fail. For game batch operations where atomicity matters (e.g., tournament registration), consider adding jobs sequentially with rollback logic.



> **Benefit**: Slice-based batching with goroutine fan-out provides predictable memory usage.

</tab>
<tab title="Node.js">

```typescript
const queue = new Queue("matchmaking", { connection });

await queue.addBulk([
  { name: "find-match", data: { player_id: "PLR0K48QjihpC4", rank: 1200, mode: "ranked" } },
  { name: "find-match", data: { player_id: "PLR3QR5T7V9W2X", rank: 1150, mode: "ranked" } },
  { name: "find-match", data: { player_id: "PLR5M2vuIULYab", rank: 1300, mode: "ranked" }, opts: { priority: 1 } },
]);
```

> **Benefit**: Priority values mirror BullMQ's proven sorted set implementation.

</tab>
</tabs>

> **⚠️ Go Gap**: Bulk job addition is not implemented. Jobs can only be added one at a time.
> **Proposed Solution**: Implement `Queue.AddBulk()` using pipelined `addStandardJob` Lua script calls within a single Redis transaction, matching Elixir's `Queue.add_bulk/2` chunked approach.

---

## 12.5. Custom Job IDs

Specify your own IDs for idempotency. Adding a job with the same ID as an existing job returns the existing job without creating a duplicate. This prevents double-processing of game events like trades and achievement unlocks.

<tabs>
<tab title="Elixir">

```elixir
# Use trade ID as job ID to prevent duplicate trade processing
{:ok, job} = EchoMQ.Queue.add("inventory", "process-trade",
  %{item_id: "ITM8xN3vP7qR4K", from_player: "PLR0K48QjihpC4", to_player: "PLR3QR5T7V9W2X"},
  connection: :redis, job_id: "trade-PLR0K48QjihpC4-ITM8xN3vP7qR4K")

# Adding same job_id again returns existing job (no duplicate trade)
{:ok, same_job} = EchoMQ.Queue.add("inventory", "process-trade",
  %{item_id: "ITM8xN3vP7qR4K", from_player: "PLR0K48QjihpC4", to_player: "PLR3QR5T7V9W2X"},
  connection: :redis, job_id: "trade-PLR0K48QjihpC4-ITM8xN3vP7qR4K")

# job.id == same_job.id
```

> **Benefit**: `:telemetry` integration provides zero-cost event dispatch when no handlers are attached.

</tab>
<tab title="Go">

```go
// Go does not support custom job IDs.
//
// How IDs work in Go:
//   queue_impl.go generates a UUID v4 via uuid.New().String() for
//   every job (line 34). This ID becomes the Redis hash key
//   (bull:{queue}:{uuid}) and the job's identity throughout its
//   lifecycle. There is no JobID field on JobOptions.
//
// What custom IDs would require:
//   Add a JobID field to the JobOptions struct. In queue_impl.Add(),
//   check if opts.JobID is set and use it instead of uuid.New().
//   The addJob Lua script handles deduplication by checking if the
//   job hash already exists — Go would need similar logic.
//
// Workaround for idempotency:
//   Use the deduplication_id pattern instead. Store a mapping of
//   your business ID to the generated UUID in a separate Redis key:
//     SET echomq:dedup:trade-PLR0K48QjihpC4-ITM8xN3vP7qR4K <job-uuid> NX EX 3600
//   Check this key before adding to avoid duplicate jobs.
```

> **Benefit**: Rate limit config is declarative — the Lua script enforces limits atomically in Redis.

</tab>
<tab title="Node.js">

```typescript
const queue = new Queue("inventory", { connection });

const job = await queue.add("process-trade", {
  item_id: "ITM8xN3vP7qR4K", from_player: "PLR0K48QjihpC4", to_player: "PLR3QR5T7V9W2X",
}, { jobId: "trade-PLR0K48QjihpC4-ITM8xN3vP7qR4K" });

// Adding same jobId returns existing job (no duplicate trade)
const same = await queue.add("process-trade", {
  item_id: "ITM8xN3vP7qR4K", from_player: "PLR0K48QjihpC4", to_player: "PLR3QR5T7V9W2X",
}, { jobId: "trade-PLR0K48QjihpC4-ITM8xN3vP7qR4K" });

// job.id === same.id
```

> **Benefit**: `ioredis` connection with lazy initialization — Redis connects only when the first command is issued.

</tab>
</tabs>

### Idempotency Patterns

| Pattern | Example ID | Use Case |
|---------|-----------|----------|
| Entity ID | `"trade-#{from_player}-#{item_id}"` | Prevent duplicate trades |
| Idempotency key | `"#{player_id}-level-up-#{date}"` | Daily level-up limits |
| Match reference | `"match-#{match_id}-rewards"` | Prevent double reward grants |

---

## 12.6. Retrieving Jobs

### Get by State

<tabs>
<tab title="Elixir">

```elixir
{:ok, waiting} = EchoMQ.Queue.get_jobs("combat-actions", "waiting", connection: :redis)
{:ok, active} = EchoMQ.Queue.get_jobs("combat-actions", "active", connection: :redis)
{:ok, completed} = EchoMQ.Queue.get_jobs("combat-actions", "completed", connection: :redis)
{:ok, failed} = EchoMQ.Queue.get_jobs("combat-actions", "failed", connection: :redis)

# Get queue counts (all states at once)
{:ok, counts} = EchoMQ.Queue.get_counts("combat-actions", connection: :redis)
# %{waiting: 10, active: 2, delayed: 5, completed: 100, failed: 3}
```

> **Benefit**: `delay` option uses Redis-native delayed scoring — no application-level timer management.

</tab>
<tab title="Go">

```go
queue := echomq.NewQueue("combat-actions", rdb)

waitingIDs, _ := queue.GetWaitingJobs(ctx, 0, -1)
activeIDs, _ := queue.GetActiveJobs(ctx, 0, -1)
completedIDs, _ := queue.GetCompletedJobs(ctx, 0, 10)
failedIDs, _ := queue.GetFailedJobs(ctx, 0, 10)
```

Go returns job ID strings. Use `queue.GetJobs(ctx, ids)` to fetch full job data.

> **Benefit**: `map[string]interface{}` job data can be marshaled to/from typed structs for safety.

</tab>
<tab title="Node.js">

```typescript
const queue = new Queue("combat-actions", { connection });

const waiting = await queue.getJobs(["waiting"]);
const active = await queue.getJobs(["active"]);
const completed = await queue.getJobs(["completed"], 0, 10);
const failed = await queue.getJobs(["failed"], 0, 10);
```

> **Benefit**: `ioredis` connection with lazy initialization — Redis connects only when the first command is issued.

</tab>
</tabs>

### Estimated State (Elixir)

The `EchoMQ.Job` module provides helper functions to check job state from the struct without a Redis round-trip:

```elixir
# Boolean state checks
EchoMQ.Job.completed?(job)  #=> true/false (finished_on set, no failed_reason)
EchoMQ.Job.failed?(job)     #=> true/false (failed_reason present)
EchoMQ.Job.active?(job)     #=> true/false (processed_on set, not finished)
EchoMQ.Job.delayed?(job)    #=> true/false (delay > 0)
EchoMQ.Job.has_parent?(job) #=> true/false (parent or parent_key present)

# Composite state inference
EchoMQ.Job.estimated_state(job)
#=> :waiting | :active | :delayed | :prioritized | :completed | :failed
```

For the authoritative state (which checks Redis directly), use `EchoMQ.Queue.get_job_state/2`.

---

## 12.7. Cross-Language Compatibility

All three runtimes write to the same Redis data structures. A job added by one language is immediately visible to workers in another language.

```
Go producer  ---\
                 +--> Redis (bull:combat-actions:*) --> Elixir worker
Node.js API --/
```

The key compatibility requirement is that all implementations use the same Redis hash field names. See [Cross-Language Interop](ch06-cross-language-interop.md) for the full field mapping and known divergences.

---

## 12.8. What's Next

- [Job Lifecycle](ch13-job-lifecycle.md) -- State transitions from creation to completion
- [Job Options](ch14-job-options.md) -- Priority, delay, retries, backoff, and cleanup
- [Getting Started](ch09-getting-started.md) -- First queue and worker in all three languages

---

*Previous: [Connections](ch11-connections.md) | Next: [Job Lifecycle](ch13-job-lifecycle.md)*
