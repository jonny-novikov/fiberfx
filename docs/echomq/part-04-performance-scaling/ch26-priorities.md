# Chapter 26. Priorities

Priority queues allow jobs to be processed based on importance rather than arrival order. In a Fireheadz Arena game server, a critical hit dealing lethal damage must resolve before a background leaderboard update, even if the leaderboard job was enqueued first. EchoMQ supports priorities ranging from 0 (highest explicit) to 2,097,152 (lowest), with a composite score encoding scheme that preserves FIFO ordering within the same priority level across all three runtimes. Priority is enforced at the Redis level through sorted sets, making it global across all workers regardless of language.

## 26.1. How Priorities Work

By default, jobs without an explicit priority are stored in the wait list (a Redis LIST) and processed in FIFO order. When you assign a priority value greater than zero, the job is stored in a separate sorted set (`bull:{queue}:prioritized`) with a composite score that encodes both priority level and insertion order.

```
Processing Order:

Queue State:
+-- [No Priority]: Job A, Job B, Job C    <-- Processed FIRST (FIFO)
+-- [Priority 1]:  Job D, Job E           <-- Then these (FIFO within P1)
+-- [Priority 5]:  Job F                  <-- Then this
+-- [Priority 100]: Job G, Job H          <-- Finally these (FIFO within P100)

Order: A -> B -> C -> D -> E -> F -> G -> H
```

The ordering rules are:

1. **No priority (default)** -- processed first, FIFO within this group
2. **Priority 1** -- highest explicit priority
3. **Priority N** -- lower number = higher priority
4. **Same priority** -- FIFO ordering (first added, first processed)

Jobs without a priority being processed before explicitly prioritized jobs may seem counterintuitive, but it preserves backward compatibility: existing queues that never used priorities continue to work identically.

## 26.2. Composite Score Encoding

When a priority job is added, EchoMQ computes a composite score that packs both the priority level and a monotonically increasing counter into a single floating-point value. This is the mechanism that enables FIFO ordering within the same priority tier inside a Redis sorted set (ZSET).

```
score = priority * 0x100000000 + counter % 0x100000000

Example (priority=1, counter=42):
  score = 1 * 4294967296 + 42 = 4294967338

Example (priority=1, counter=43):
  score = 1 * 4294967296 + 43 = 4294967339

Example (priority=5, counter=44):
  score = 5 * 4294967296 + 44 = 21474836524

Redis ZRANGEBYSCORE returns: 4294967338 < 4294967339 < 21474836524
                             (P1, #42)    (P1, #43)    (P5, #44)
```

The counter is stored in a Redis key (`bull:{queue}:pc`) and atomically incremented with each priority job addition. The `0x100000000` multiplier (2^32) reserves the lower 32 bits for the counter, allowing up to ~4 billion jobs per priority level before wrapping. This encoding matches the BullMQ Lua `getPriorityScore()` function exactly, so priority jobs added from any runtime -- Elixir, Go, or Node.js -- interleave correctly in the same sorted set.

## 26.3. Adding Priority Jobs

Assign a priority when enqueuing a job. Lower numbers mean higher priority.

<tabs>
<tab title="Elixir">

```elixir
# Critical hit resolution -- highest explicit priority
{:ok, critical} = EchoMQ.Queue.add(
  "combat-actions", "resolve-damage",
  %{
    "attacker" => "PLR0K48QjihpC4",
    "target" => "NPC5rK2mJ9pQ1L",
    "damage" => 2450,
    "type" => "critical_hit"
  },
  connection: :arena_redis,
  priority: 1
)

# Normal attack -- medium priority
{:ok, normal} = EchoMQ.Queue.add(
  "combat-actions", "resolve-damage",
  %{
    "attacker" => "PLR3QR5T7V9W2X",
    "target" => "NPC4pL8nQ3uV7X",
    "damage" => 180,
    "type" => "normal_attack"
  },
  connection: :arena_redis,
  priority: 100
)

# Buff application -- low priority
{:ok, buff} = EchoMQ.Queue.add(
  "combat-actions", "apply-buff",
  %{
    "caster" => "PLR5M2vuIULYab",
    "target" => "PLR0K48QjihpC4",
    "buff" => "strength_boost",
    "duration_ms" => 30_000
  },
  connection: :arena_redis,
  priority: 500
)

# Leaderboard update -- background priority
{:ok, leaderboard} = EchoMQ.Queue.add(
  "combat-actions", "update-leaderboard",
  %{
    "player_id" => "PLR0K48QjihpC4",
    "xp_gained" => 350,
    "kills" => 1
  },
  connection: :arena_redis,
  priority: 1000
)

# Processing order: critical (1) -> normal (100) -> buff (500) -> leaderboard (1000)
```

The `priority` option accepts any non-negative integer. When set to a value greater than zero, the job is routed to the `bull:{queue}:prioritized` sorted set via the `addPrioritizedJob` Lua script, which atomically increments the per-queue priority counter and computes the composite score.

> **Benefit**: Priority maps to Redis sorted set scores — atomic ordering without application-level sorting.

</tab>
<tab title="Go">

```go
ctx := context.Background()
q := echomq.NewQueue("combat-actions", rdb)

// Critical hit resolution -- highest explicit priority
_, err := q.Add(ctx, "resolve-damage", map[string]interface{}{
    "attacker": "PLR0K48QjihpC4",
    "target":   "NPC5rK2mJ9pQ1L",
    "damage":   2450,
    "type":     "critical_hit",
}, echomq.JobOptions{Priority: 1})

// Normal attack -- medium priority
_, err = q.Add(ctx, "resolve-damage", map[string]interface{}{
    "attacker": "PLR3QR5T7V9W2X",
    "target":   "NPC4pL8nQ3uV7X",
    "damage":   180,
    "type":     "normal_attack",
}, echomq.JobOptions{Priority: 100})

// Buff application -- low priority
_, err = q.Add(ctx, "apply-buff", map[string]interface{}{
    "caster":      "PLR5M2vuIULYab",
    "target":      "PLR0K48QjihpC4",
    "buff":        "strength_boost",
    "duration_ms": 30000,
}, echomq.JobOptions{Priority: 500})

// Leaderboard update -- background priority
_, err = q.Add(ctx, "update-leaderboard", map[string]interface{}{
    "player_id": "PLR0K48QjihpC4",
    "xp_gained": 350,
    "kills":     1,
}, echomq.JobOptions{Priority: 1000})
```

The Go implementation in `queue_impl.go` detects `Priority > 0`, atomically increments the priority counter key (`bull:{queue}:pc`) via `INCR`, and computes the composite score directly:

```go
priorityScore := float64(job.Opts.Priority) * 0x100000000 +
                 float64(counter % 0x100000000)
```

The job is then added to the prioritized sorted set via `ZADD`. Validation in `validation.go` rejects negative priority values.

> **Benefit**: Priority encoding uses composite score combining priority level and insertion order.

</tab>
<tab title="Node.js">

```typescript
import { Queue } from "bullmq";

const queue = new Queue("combat-actions", {
  connection: { host: "localhost", port: 6379 },
});

// Critical hit resolution -- highest explicit priority
await queue.add("resolve-damage", {
  attacker: "PLR0K48QjihpC4",
  target: "NPC5rK2mJ9pQ1L",
  damage: 2450,
  type: "critical_hit",
}, { priority: 1 });

// Normal attack -- medium priority
await queue.add("resolve-damage", {
  attacker: "PLR3QR5T7V9W2X",
  target: "NPC4pL8nQ3uV7X",
  damage: 180,
  type: "normal_attack",
}, { priority: 100 });

// Buff application -- low priority
await queue.add("apply-buff", {
  caster: "PLR5M2vuIULYab",
  target: "PLR0K48QjihpC4",
  buff: "strength_boost",
  duration_ms: 30000,
}, { priority: 500 });

// Leaderboard update -- background priority
await queue.add("update-leaderboard", {
  player_id: "PLR0K48QjihpC4",
  xp_gained: 350,
  kills: 1,
}, { priority: 1000 });
```

> **Benefit**: Priority values mirror BullMQ's proven sorted set implementation.

</tab>
</tabs>

## 26.4. Tiered Priority System

Define named priority tiers as constants rather than scattering magic numbers across your codebase. A combat-focused game server typically needs 4-6 tiers that map to game action urgency.

<tabs>
<tab title="Elixir">

```elixir
defmodule Arena.Priority do
  @moduledoc "Named priority tiers for Fireheadz Arena combat actions"

  # Lethal damage, interrupt effects, instant kills
  @critical 1
  # Standard melee/ranged attacks, spell damage
  @high 10
  # Buff/debuff applications, healing, shields
  @normal 100
  # Cooldown resets, mana regeneration, passive effects
  @low 500
  # Leaderboard updates, XP grants, achievement checks
  @background 1000

  def critical, do: @critical
  def high, do: @high
  def normal, do: @normal
  def low, do: @low
  def background, do: @background
end

# Usage in combat system
defmodule Arena.CombatQueue do
  alias Arena.Priority

  def enqueue_damage(attacker, target, damage, opts \\ []) do
    is_lethal = Keyword.get(opts, :lethal, false)
    priority = if is_lethal, do: Priority.critical(), else: Priority.high()

    EchoMQ.Queue.add("combat-actions", "resolve-damage", %{
      "attacker" => attacker,
      "target" => target,
      "damage" => damage,
      "lethal" => is_lethal
    }, connection: :arena_redis, priority: priority)
  end

  def enqueue_buff(caster, target, buff_type, duration_ms) do
    EchoMQ.Queue.add("combat-actions", "apply-buff", %{
      "caster" => caster,
      "target" => target,
      "buff" => buff_type,
      "duration_ms" => duration_ms
    }, connection: :arena_redis, priority: Priority.normal())
  end

  def enqueue_leaderboard_update(player_id, stats) do
    EchoMQ.Queue.add("combat-actions", "update-leaderboard",
      Map.put(stats, "player_id", player_id),
      connection: :arena_redis, priority: Priority.background()
    )
  end
end
```

> **Benefit**: Priority maps to Redis sorted set scores — atomic ordering without application-level sorting.

</tab>
<tab title="Go">

```go
package arena

import "github.com/fiberfx/echomq-go/pkg/echomq"

// Priority tiers for Fireheadz Arena combat actions
const (
    PriorityCritical   = 1    // Lethal damage, interrupt effects
    PriorityHigh       = 10   // Standard attacks, spell damage
    PriorityNormal     = 100  // Buff/debuff, healing, shields
    PriorityLow        = 500  // Cooldown resets, passive effects
    PriorityBackground = 1000 // Leaderboard, XP, achievements
)

func EnqueueDamage(ctx context.Context, q *echomq.Queue, attacker, target string, damage int, lethal bool) error {
    priority := PriorityHigh
    if lethal {
        priority = PriorityCritical
    }

    _, err := q.Add(ctx, "resolve-damage", map[string]interface{}{
        "attacker": attacker,
        "target":   target,
        "damage":   damage,
        "lethal":   lethal,
    }, echomq.JobOptions{Priority: priority})
    return err
}

func EnqueueBuff(ctx context.Context, q *echomq.Queue, caster, target, buffType string, durationMs int) error {
    _, err := q.Add(ctx, "apply-buff", map[string]interface{}{
        "caster":      caster,
        "target":      target,
        "buff":        buffType,
        "duration_ms": durationMs,
    }, echomq.JobOptions{Priority: PriorityNormal})
    return err
}

func EnqueueLeaderboardUpdate(ctx context.Context, q *echomq.Queue, playerID string, xp, kills int) error {
    _, err := q.Add(ctx, "update-leaderboard", map[string]interface{}{
        "player_id": playerID,
        "xp_gained": xp,
        "kills":     kills,
    }, echomq.JobOptions{Priority: PriorityBackground})
    return err
}
```

> **Benefit**: Priority encoding uses composite score combining priority level and insertion order.

</tab>
<tab title="Node.js">

```typescript
import { Queue } from "bullmq";

// Priority tiers for Fireheadz Arena combat actions
const Priority = {
  CRITICAL: 1,     // Lethal damage, interrupt effects
  HIGH: 10,        // Standard attacks, spell damage
  NORMAL: 100,     // Buff/debuff, healing, shields
  LOW: 500,        // Cooldown resets, passive effects
  BACKGROUND: 1000 // Leaderboard, XP, achievements
} as const;

const combatQueue = new Queue("combat-actions", {
  connection: { host: "localhost", port: 6379 },
});

async function enqueueDamage(
  attacker: string, target: string, damage: number, lethal = false
) {
  return combatQueue.add("resolve-damage", {
    attacker, target, damage, lethal,
  }, {
    priority: lethal ? Priority.CRITICAL : Priority.HIGH,
  });
}

async function enqueueBuff(
  caster: string, target: string, buffType: string, durationMs: number
) {
  return combatQueue.add("apply-buff", {
    caster, target, buff: buffType, duration_ms: durationMs,
  }, {
    priority: Priority.NORMAL,
  });
}

async function enqueueLeaderboardUpdate(
  playerId: string, xp: number, kills: number
) {
  return combatQueue.add("update-leaderboard", {
    player_id: playerId, xp_gained: xp, kills,
  }, {
    priority: Priority.BACKGROUND,
  });
}
```

> **Benefit**: Priority values mirror BullMQ's proven sorted set implementation.

</tab>
</tabs>

### Priority Tier Reference

| Tier | Value | Game Actions | Latency Target |
|------|-------|-------------|----------------|
| Critical | 1 | Lethal damage, interrupts, instant kills | < 5ms |
| High | 10 | Normal attacks, spell damage, ranged hits | < 10ms |
| Normal | 100 | Buff/debuff applications, healing, shields | < 50ms |
| Low | 500 | Cooldown resets, mana regen, passive effects | < 200ms |
| Background | 1000 | Leaderboard updates, XP grants, achievements | < 1s |

## 26.5. Dynamic Priority

Assign priority based on runtime game state. A matchmaking job's urgency increases as a player waits longer, and an NPC respawn becomes critical when the arena has too few active enemies.

<tabs>
<tab title="Elixir">

```elixir
defmodule Arena.DynamicPriority do
  @moduledoc "Computes job priority from live game state"

  alias Arena.Priority

  @doc "Higher priority for longer wait times"
  def matchmaking_priority(wait_time_ms) do
    cond do
      wait_time_ms > 60_000 -> Priority.critical()   # Waiting > 1 min
      wait_time_ms > 30_000 -> Priority.high()        # Waiting > 30s
      wait_time_ms > 10_000 -> Priority.normal()      # Waiting > 10s
      true                  -> Priority.low()          # Just joined
    end
  end

  @doc "NPC respawn urgency based on active enemy count"
  def npc_respawn_priority(active_npcs, min_threshold) do
    ratio = active_npcs / max(min_threshold, 1)
    cond do
      ratio < 0.25 -> Priority.critical()   # Arena nearly empty
      ratio < 0.50 -> Priority.high()        # Below half capacity
      ratio < 0.75 -> Priority.normal()      # Getting low
      true         -> Priority.background()  # Plenty of enemies
    end
  end
end

# Matchmaking with escalating priority
defmodule Arena.MatchmakingQueue do
  def enqueue_search(player_id, rank, wait_start) do
    wait_time = System.system_time(:millisecond) - wait_start
    priority = Arena.DynamicPriority.matchmaking_priority(wait_time)

    EchoMQ.Queue.add("matchmaking", "find-match", %{
      "player_id" => player_id,
      "rank" => rank,
      "wait_start" => wait_start,
      "search_attempt" => div(wait_time, 10_000) + 1
    }, connection: :arena_redis, priority: priority)
  end
end

# NPC respawn with arena state awareness
defmodule Arena.NPCSpawnQueue do
  def enqueue_respawn(npc_template, zone_id) do
    active = Arena.ZoneRegistry.active_npc_count(zone_id)
    threshold = Arena.ZoneRegistry.min_npc_count(zone_id)
    priority = Arena.DynamicPriority.npc_respawn_priority(active, threshold)

    EchoMQ.Queue.add("world-sync", "respawn-npc", %{
      "template" => npc_template,
      "zone_id" => zone_id,
      "active_npcs" => active,
      "threshold" => threshold
    }, connection: :arena_redis, priority: priority)
  end
end
```

> **Benefit**: Priority maps to Redis sorted set scores — atomic ordering without application-level sorting.

</tab>
<tab title="Go">

```go
// Matchmaking priority escalates with wait time
func matchmakingPriority(waitTimeMs int64) int {
    switch {
    case waitTimeMs > 60000:
        return PriorityCritical  // Waiting > 1 min
    case waitTimeMs > 30000:
        return PriorityHigh      // Waiting > 30s
    case waitTimeMs > 10000:
        return PriorityNormal    // Waiting > 10s
    default:
        return PriorityLow       // Just joined
    }
}

// NPC respawn urgency based on active enemy count
func npcRespawnPriority(activeNPCs, minThreshold int) int {
    if minThreshold == 0 {
        minThreshold = 1
    }
    ratio := float64(activeNPCs) / float64(minThreshold)
    switch {
    case ratio < 0.25:
        return PriorityCritical   // Arena nearly empty
    case ratio < 0.50:
        return PriorityHigh       // Below half capacity
    case ratio < 0.75:
        return PriorityNormal     // Getting low
    default:
        return PriorityBackground // Plenty of enemies
    }
}

func enqueueMatchSearch(ctx context.Context, q *echomq.Queue, playerID string, rank int, waitStart int64) error {
    waitTime := time.Now().UnixMilli() - waitStart
    priority := matchmakingPriority(waitTime)

    _, err := q.Add(ctx, "find-match", map[string]interface{}{
        "player_id":      playerID,
        "rank":           rank,
        "wait_start":     waitStart,
        "search_attempt": waitTime/10000 + 1,
    }, echomq.JobOptions{Priority: priority})
    return err
}

func enqueueNPCRespawn(ctx context.Context, q *echomq.Queue, template, zoneID string, activeNPCs, threshold int) error {
    priority := npcRespawnPriority(activeNPCs, threshold)

    _, err := q.Add(ctx, "respawn-npc", map[string]interface{}{
        "template":    template,
        "zone_id":     zoneID,
        "active_npcs": activeNPCs,
        "threshold":   threshold,
    }, echomq.JobOptions{Priority: priority})
    return err
}
```

> **Benefit**: Priority encoding uses composite score combining priority level and insertion order.

</tab>
<tab title="Node.js">

```typescript
import { Queue } from "bullmq";

const Priority = { CRITICAL: 1, HIGH: 10, NORMAL: 100, LOW: 500, BACKGROUND: 1000 } as const;

function matchmakingPriority(waitTimeMs: number): number {
  if (waitTimeMs > 60_000) return Priority.CRITICAL;
  if (waitTimeMs > 30_000) return Priority.HIGH;
  if (waitTimeMs > 10_000) return Priority.NORMAL;
  return Priority.LOW;
}

function npcRespawnPriority(activeNPCs: number, minThreshold: number): number {
  const ratio = activeNPCs / Math.max(minThreshold, 1);
  if (ratio < 0.25) return Priority.CRITICAL;
  if (ratio < 0.50) return Priority.HIGH;
  if (ratio < 0.75) return Priority.NORMAL;
  return Priority.BACKGROUND;
}

const matchQueue = new Queue("matchmaking", {
  connection: { host: "localhost", port: 6379 },
});

async function enqueueMatchSearch(playerId: string, rank: number, waitStart: number) {
  const waitTime = Date.now() - waitStart;
  return matchQueue.add("find-match", {
    player_id: playerId,
    rank,
    wait_start: waitStart,
    search_attempt: Math.floor(waitTime / 10_000) + 1,
  }, {
    priority: matchmakingPriority(waitTime),
  });
}

const worldQueue = new Queue("world-sync", {
  connection: { host: "localhost", port: 6379 },
});

async function enqueueNPCRespawn(
  template: string, zoneId: string, activeNPCs: number, threshold: number
) {
  return worldQueue.add("respawn-npc", {
    template, zone_id: zoneId, active_npcs: activeNPCs, threshold,
  }, {
    priority: npcRespawnPriority(activeNPCs, threshold),
  });
}
```

> **Benefit**: Priority values mirror BullMQ's proven sorted set implementation.

</tab>
</tabs>

## 26.6. Changing Priority at Runtime

Update a job's priority after it has been enqueued. This is useful when game conditions change -- for example, promoting a matchmaking search to critical when a tournament round is about to start, or demoting a leaderboard job during a server-wide combat event.

<tabs>
<tab title="Elixir">

```elixir
# Fetch the job by ID
{:ok, job} = EchoMQ.Job.from_id(:arena_redis, "combat-actions", job_id)

# Promote to critical priority (tournament round starting)
:ok = EchoMQ.Job.change_priority(job, priority: 1)

# Demote to background (combat event in progress, defer non-combat work)
:ok = EchoMQ.Job.change_priority(job, priority: 1000)

# Use LIFO ordering within the same priority tier
# (newest jobs in this tier processed first)
:ok = EchoMQ.Job.change_priority(job, priority: 100, lifo: true)
```

The `change_priority/2` function executes the `changePriority` Lua script, which atomically removes the job from its current position in the sorted set and re-inserts it with a new composite score. The priority counter is incremented to maintain insertion order.

> **Benefit**: Priority maps to Redis sorted set scores — atomic ordering without application-level sorting.

</tab>
<tab title="Go">

```go
// Feature: Change Priority (Job.changePriority)
//
// Not yet implemented as a first-class method in echomq-go.
// The changePriority Lua script atomically moves a job within
// the prioritized sorted set by recalculating its composite score.
//
// Workaround:
//   Remove and re-add the job to the prioritized ZSET directly:
//
//   func changePriority(ctx context.Context, rdb *redis.Client, queue, jobID string, newPriority int) error {
//       key := fmt.Sprintf("bull:%s:prioritized", queue)
//       counterKey := fmt.Sprintf("bull:%s:pc", queue)
//
//       // Atomically: remove old score, increment counter, add with new score
//       pipe := rdb.TxPipeline()
//       pipe.ZRem(ctx, key, jobID)
//       counterCmd := pipe.Incr(ctx, counterKey)
//       if _, err := pipe.Exec(ctx); err != nil {
//           return err
//       }
//       counter := counterCmd.Val()
//       score := float64(newPriority)*0x100000000 + float64(counter%0x100000000)
//       return rdb.ZAdd(ctx, key, redis.Z{Score: score, Member: jobID}).Err()
//   }
//
// Reference: Ch 17 Worker Patterns -- Protocol Gap Summary Table

// Use the workaround for now:
err := changePriority(ctx, rdb, "combat-actions", jobID, 1) // promote to critical
```

> **Benefit**: Priority encoding uses composite score combining priority level and insertion order.

</tab>
<tab title="Node.js">

```typescript
import { Job } from "bullmq";

// Fetch the job by ID
const job = await Job.fromId(queue, jobId);

// Promote to critical priority (tournament round starting)
await job.changePriority({ priority: 1 });

// Demote to background
await job.changePriority({ priority: 1000 });

// Use LIFO within the same priority tier
await job.changePriority({ priority: 100, lifo: true });
```

> **Benefit**: Priority values mirror BullMQ's proven sorted set implementation.

</tab>
</tabs>

## 26.7. Querying Prioritized Jobs

Inspect the prioritized job set to monitor queue depth per tier, build admin dashboards, or detect priority starvation.

<tabs>
<tab title="Elixir">

```elixir
# Get all jobs currently in the prioritized state
{:ok, jobs} = EchoMQ.Queue.get_prioritized("combat-actions",
  connection: :arena_redis
)

# Count prioritized jobs
{:ok, count} = EchoMQ.Queue.get_prioritized_count("combat-actions",
  connection: :arena_redis
)
IO.puts("#{count} jobs awaiting priority processing")

# Get counts per priority tier
{:ok, counts} = EchoMQ.Queue.get_counts_per_priority(
  "combat-actions",
  [1, 10, 100, 500, 1000],
  connection: :arena_redis
)
# counts => %{"1" => 3, "10" => 12, "100" => 45, "500" => 8, "1000" => 120}

# Use get_jobs with state filter
{:ok, jobs} = EchoMQ.Queue.get_jobs("combat-actions",
  [:prioritized],
  connection: :arena_redis
)

# Full queue status including prioritized
{:ok, counts} = EchoMQ.Queue.get_job_counts("combat-actions",
  connection: :arena_redis
)
IO.inspect(counts)
# %{waiting: 50, active: 10, delayed: 5, prioritized: 188, completed: 1200, failed: 3}
```

> **Benefit**: Priority maps to Redis sorted set scores — atomic ordering without application-level sorting.

</tab>
<tab title="Go">

```go
ctx := context.Background()
q := echomq.NewQueue("combat-actions", rdb)

// Get full job counts (includes prioritized)
counts, err := q.GetJobCounts(ctx)
if err != nil {
    log.Fatal(err)
}
fmt.Printf("Prioritized: %d, Waiting: %d, Active: %d\n",
    counts.Prioritized, counts.Waiting, counts.Active)

// Query prioritized jobs directly via Redis sorted set
kb := echomq.NewKeyBuilder("combat-actions", rdb)
jobIDs, err := rdb.ZRange(ctx, kb.Prioritized(), 0, -1).Result()
if err != nil {
    log.Fatal(err)
}
fmt.Printf("%d prioritized jobs: %v\n", len(jobIDs), jobIDs)

// Get counts per priority tier using ZCOUNT with score ranges
tiers := []struct {
    Name     string
    MinScore float64
    MaxScore float64
}{
    {"critical", 1 * 0x100000000, 2 * 0x100000000 - 1},
    {"high", 10 * 0x100000000, 11 * 0x100000000 - 1},
    {"normal", 100 * 0x100000000, 101 * 0x100000000 - 1},
    {"low", 500 * 0x100000000, 501 * 0x100000000 - 1},
    {"background", 1000 * 0x100000000, 1001 * 0x100000000 - 1},
}
for _, tier := range tiers {
    count, _ := rdb.ZCount(ctx, kb.Prioritized(),
        fmt.Sprintf("%f", tier.MinScore),
        fmt.Sprintf("%f", tier.MaxScore),
    ).Result()
    fmt.Printf("  %s: %d jobs\n", tier.Name, count)
}
```

The Go implementation provides `GetJobCounts` which returns a struct including the `Prioritized` field. For per-tier breakdowns, use Redis `ZCOUNT` with score ranges derived from the composite encoding: jobs at priority P have scores in the range `[P * 0x100000000, (P+1) * 0x100000000)`.

> **Benefit**: Priority encoding uses composite score combining priority level and insertion order.

</tab>
<tab title="Node.js">

```typescript
import { Queue } from "bullmq";

const queue = new Queue("combat-actions", {
  connection: { host: "localhost", port: 6379 },
});

// Get all prioritized jobs
const jobs = await queue.getJobs(["prioritized"]);
console.log(`${jobs.length} prioritized jobs`);

// Get counts per priority tier
const counts = await queue.getCountsPerPriority([1, 10, 100, 500, 1000]);
console.log(counts);
// { "1": 3, "10": 12, "100": 45, "500": 8, "1000": 120 }

// Full queue status
const allCounts = await queue.getJobCounts(
  "waiting", "active", "delayed", "prioritized", "completed", "failed"
);
console.log(allCounts);
```

> **Benefit**: Priority values mirror BullMQ's proven sorted set implementation.

</tab>
</tabs>

## 26.8. Bulk Priority Jobs

Add multiple priority jobs efficiently using bulk operations. In a combat round, dozens of damage events fire simultaneously.

<tabs>
<tab title="Elixir">

```elixir
# End-of-round combat resolution: many damage events at different priorities
round_events = [
  {"resolve-damage", %{"attacker" => "PLR0K48QjihpC4", "target" => "NPC5rK2mJ9pQ1L",
    "damage" => 2450, "type" => "critical_hit"}, [priority: 1]},
  {"resolve-damage", %{"attacker" => "PLR3QR5T7V9W2X", "target" => "NPC4pL8nQ3uV7X",
    "damage" => 180, "type" => "normal_attack"}, [priority: 10]},
  {"apply-buff", %{"caster" => "PLR5M2vuIULYab", "target" => "PLR0K48QjihpC4",
    "buff" => "strength_boost", "duration_ms" => 30_000}, [priority: 100]},
  {"apply-buff", %{"caster" => "PLR6dF8jL2uA4W", "target" => "PLR3QR5T7V9W2X",
    "buff" => "haste", "duration_ms" => 15_000}, [priority: 100]},
  {"update-leaderboard", %{"player_id" => "PLR0K48QjihpC4",
    "xp_gained" => 350, "kills" => 1}, [priority: 1000]},
  {"update-leaderboard", %{"player_id" => "PLR3QR5T7V9W2X",
    "xp_gained" => 120, "kills" => 0}, [priority: 1000]}
]

{:ok, results} = EchoMQ.Queue.add_bulk("combat-actions", round_events,
  connection: :arena_redis
)
IO.puts("Enqueued #{length(results)} combat events")
```

Priority jobs in `add_bulk` are processed sequentially rather than pipelined, because each one requires an atomic `INCR` on the priority counter followed by a `ZADD` with the computed composite score. Standard (non-priority) jobs in the same batch still use pipelining.

> **Benefit**: `Enum.chunk_every` pipelines provide natural batch decomposition with backpressure.

</tab>
<tab title="Go">

```go
// Bulk add combat round events with mixed priorities
type CombatEvent struct {
    Name     string
    Data     map[string]interface{}
    Priority int
}

events := []CombatEvent{
    {"resolve-damage", map[string]interface{}{
        "attacker": "PLR0K48QjihpC4", "target": "NPC5rK2mJ9pQ1L",
        "damage": 2450, "type": "critical_hit",
    }, PriorityCritical},
    {"resolve-damage", map[string]interface{}{
        "attacker": "PLR3QR5T7V9W2X", "target": "NPC4pL8nQ3uV7X",
        "damage": 180, "type": "normal_attack",
    }, PriorityHigh},
    {"apply-buff", map[string]interface{}{
        "caster": "PLR5M2vuIULYab", "target": "PLR0K48QjihpC4",
        "buff": "strength_boost", "duration_ms": 30000,
    }, PriorityNormal},
    {"update-leaderboard", map[string]interface{}{
        "player_id": "PLR0K48QjihpC4", "xp_gained": 350, "kills": 1,
    }, PriorityBackground},
}

q := echomq.NewQueue("combat-actions", rdb)
for _, e := range events {
    _, err := q.Add(ctx, e.Name, e.Data, echomq.JobOptions{Priority: e.Priority})
    if err != nil {
        log.Printf("Failed to enqueue %s: %v", e.Name, err)
    }
}
```

The Go queue does not yet have a native `AddBulk` method, so priority jobs are added in a loop. Each `Add` call performs an atomic `INCR` + `ZADD` pair to maintain correct composite scores.

> **Benefit**: Priority encoding uses composite score combining priority level and insertion order.

</tab>
<tab title="Node.js">

```typescript
import { Queue } from "bullmq";

const queue = new Queue("combat-actions", {
  connection: { host: "localhost", port: 6379 },
});

// Bulk add combat round events with mixed priorities
const roundEvents = [
  { name: "resolve-damage", data: {
    attacker: "PLR0K48QjihpC4", target: "NPC5rK2mJ9pQ1L", damage: 2450, type: "critical_hit",
  }, opts: { priority: 1 } },
  { name: "resolve-damage", data: {
    attacker: "PLR3QR5T7V9W2X", target: "NPC4pL8nQ3uV7X", damage: 180, type: "normal_attack",
  }, opts: { priority: 10 } },
  { name: "apply-buff", data: {
    caster: "PLR5M2vuIULYab", target: "PLR0K48QjihpC4", buff: "strength_boost", duration_ms: 30000,
  }, opts: { priority: 100 } },
  { name: "update-leaderboard", data: {
    player_id: "PLR0K48QjihpC4", xp_gained: 350, kills: 1,
  }, opts: { priority: 1000 } },
];

const results = await queue.addBulk(roundEvents);
console.log(`Enqueued ${results.length} combat events`);
```

> **Benefit**: Priority values mirror BullMQ's proven sorted set implementation.

</tab>
</tabs>

## 26.9. Performance Considerations

Adding prioritized jobs has `O(log n)` complexity relative to the number of jobs in the prioritized sorted set, because Redis uses a skip list internally. Standard FIFO jobs use `O(1)` `RPUSH` / `LPUSH` operations.

| Job Type | Add Complexity | Fetch Complexity | Notes |
|----------|---------------|-----------------|-------|
| Standard (FIFO) | O(1) | O(1) `RPOP` | Fastest for uniform workloads |
| LIFO | O(1) | O(1) `LPOP` | Same cost as FIFO, reversed order |
| Prioritized | O(log n) | O(log n) `ZPOPMIN` | Cost grows with prioritized set size |
| Delayed | O(log n) | O(log n) `ZPOPMIN` | Same sorted set mechanics |

For a queue with 10,000 prioritized jobs, `log2(10000) ~ 13` comparisons per insert. At 100,000 jobs, this grows to ~17. The practical impact is minimal for most game workloads, but becomes measurable at very high throughput.

### When Priorities Slow You Down

```
Throughput vs Queue Depth (priority jobs):

Queue Size    |  Add Latency   |  Relative to FIFO
------------- | -------------- | ------------------
100           |  ~0.05ms       |  1.2x
1,000         |  ~0.07ms       |  1.5x
10,000        |  ~0.10ms       |  2.0x
100,000       |  ~0.15ms       |  3.0x
1,000,000     |  ~0.20ms       |  4.0x

Note: Absolute latencies depend on Redis deployment.
Network round-trip typically dominates for remote Redis.
```

## 26.10. Priorities vs Separate Queues

Two architectural approaches solve the "process important jobs first" problem. Each has different tradeoffs.

| Factor | Priority Queue | Separate Queues |
|--------|---------------|-----------------|
| **Setup complexity** | One queue, one worker config | Multiple queues, multiple workers |
| **Processing logic** | Same processor for all tiers | Can differ per queue |
| **Dynamic promotion** | `change_priority` at runtime | Must move job between queues |
| **Throughput scaling** | Shared worker pool | Independent scaling per tier |
| **Starvation risk** | Low-priority jobs can starve | Each queue drains independently |
| **Monitoring** | Single queue dashboard | Per-queue dashboards |
| **Best for** | 3-5 tiers, same processing logic | Many tiers, different processors |

### Priority Queue Approach

Use a single queue with priority tiers when all jobs share the same processing logic and you need dynamic priority changes.

<tabs>
<tab title="Elixir">

```elixir
# Single queue: all combat actions processed by one worker pool
{:ok, _} = EchoMQ.Worker.start_link(
  queue: "combat-actions",
  connection: :arena_redis,
  processor: &Arena.CombatProcessor.process/1,
  concurrency: 60
)

# Jobs self-organize by priority within the queue
EchoMQ.Queue.add("combat-actions", "resolve-damage", damage_data,
  connection: :arena_redis, priority: Arena.Priority.critical())
EchoMQ.Queue.add("combat-actions", "apply-buff", buff_data,
  connection: :arena_redis, priority: Arena.Priority.normal())
EchoMQ.Queue.add("combat-actions", "update-leaderboard", lb_data,
  connection: :arena_redis, priority: Arena.Priority.background())
```

> **Benefit**: BEAM processes provide true preemptive concurrency — one slow job cannot starve others.

</tab>
<tab title="Go">

```go
// Single queue: all combat actions processed by one worker
worker := echomq.NewWorker("combat-actions", rdb, echomq.WorkerOptions{
    Concurrency: 60,
})
worker.Process(combatProcessor)
worker.Start(ctx)

// Jobs self-organize by priority within the queue
q.Add(ctx, "resolve-damage", damageData, echomq.JobOptions{Priority: PriorityCritical})
q.Add(ctx, "apply-buff", buffData, echomq.JobOptions{Priority: PriorityNormal})
q.Add(ctx, "update-leaderboard", lbData, echomq.JobOptions{Priority: PriorityBackground})
```

> **Benefit**: Goroutine-per-job with semaphore-based limiting achieves OS-level parallelism.

</tab>
<tab title="Node.js">

```typescript
// Single queue: all combat actions processed by one worker pool
const worker = new Worker("combat-actions", combatProcessor, {
  connection: { host: "localhost", port: 6379 },
  concurrency: 60,
});

// Jobs self-organize by priority within the queue
await queue.add("resolve-damage", damageData, { priority: 1 });
await queue.add("apply-buff", buffData, { priority: 100 });
await queue.add("update-leaderboard", lbData, { priority: 1000 });
```

> **Tradeoff**: Event loop concurrency means I/O-bound jobs scale well but CPU-bound jobs need worker threads.

</tab>
</tabs>

### Separate Queues Approach

Use separate queues when different tiers need different concurrency settings, rate limits, or processing logic.

<tabs>
<tab title="Elixir">

```elixir
# Separate queues: independent scaling and processing per tier
# Critical combat: high concurrency, fast resolution
{:ok, _} = EchoMQ.Worker.start_link(
  queue: "combat-critical",
  connection: :arena_redis,
  processor: &Arena.CombatProcessor.process_critical/1,
  concurrency: 100
)

# Normal combat: moderate concurrency
{:ok, _} = EchoMQ.Worker.start_link(
  queue: "combat-normal",
  connection: :arena_redis,
  processor: &Arena.CombatProcessor.process_normal/1,
  concurrency: 30
)

# Background tasks: low concurrency, no rush
{:ok, _} = EchoMQ.Worker.start_link(
  queue: "combat-background",
  connection: :arena_redis,
  processor: &Arena.BackgroundProcessor.process/1,
  concurrency: 5
)
```

> **Benefit**: BEAM processes provide true preemptive concurrency — one slow job cannot starve others.

</tab>
<tab title="Go">

```go
// Separate queues: independent scaling per tier
criticalWorker := echomq.NewWorker("combat-critical", rdb, echomq.WorkerOptions{
    Concurrency: 100,
})
criticalWorker.Process(processCritical)
go criticalWorker.Start(ctx)

normalWorker := echomq.NewWorker("combat-normal", rdb, echomq.WorkerOptions{
    Concurrency: 30,
})
normalWorker.Process(processNormal)
go normalWorker.Start(ctx)

backgroundWorker := echomq.NewWorker("combat-background", rdb, echomq.WorkerOptions{
    Concurrency: 5,
})
backgroundWorker.Process(processBackground)
go backgroundWorker.Start(ctx)
```

> **Benefit**: Goroutine-per-job with semaphore-based limiting achieves OS-level parallelism.

</tab>
<tab title="Node.js">

```typescript
// Separate queues: independent scaling per tier
new Worker("combat-critical", processCritical, {
  connection, concurrency: 100,
});
new Worker("combat-normal", processNormal, {
  connection, concurrency: 30,
});
new Worker("combat-background", processBackground, {
  connection, concurrency: 5,
});
```

> **Tradeoff**: Event loop concurrency means I/O-bound jobs scale well but CPU-bound jobs need worker threads.

</tab>
</tabs>

## 26.11. Priority Starvation

When high-priority jobs arrive faster than they drain, low-priority jobs may wait indefinitely. This is known as priority starvation. Detect and mitigate it by monitoring per-tier queue depth and age.

<tabs>
<tab title="Elixir">

```elixir
defmodule Arena.StarvationDetector do
  @moduledoc "Detects priority starvation in combat queues"

  use GenServer

  @check_interval 15_000
  @starvation_threshold_ms 60_000  # 1 minute without processing

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(_opts) do
    :timer.send_interval(@check_interval, :check)
    {:ok, %{}}
  end

  @impl true
  def handle_info(:check, state) do
    {:ok, counts} = EchoMQ.Queue.get_counts_per_priority(
      "combat-actions",
      [1, 10, 100, 500, 1000],
      connection: :arena_redis
    )

    # Check if low-priority tiers are growing while high-priority drains
    background_count = Map.get(counts, "1000", 0)
    low_count = Map.get(counts, "500", 0)

    if background_count > 500 or low_count > 200 do
      Logger.warning(
        "[starvation] combat-actions backlog: background=#{background_count} low=#{low_count}"
      )
      :telemetry.execute(
        [:arena, :priority, :starvation],
        %{background: background_count, low: low_count},
        %{queue: "combat-actions"}
      )
    end

    {:noreply, state}
  end
end
```

> **Benefit**: `:telemetry.attach` adds zero-cost instrumentation — events are no-ops when unhandled.

</tab>
<tab title="Go">

```go
func detectStarvation(ctx context.Context, rdb *redis.Client, queue string, interval time.Duration) {
    ticker := time.NewTicker(interval)
    defer ticker.Stop()

    kb := echomq.NewKeyBuilder(queue, rdb)
    for {
        select {
        case <-ctx.Done():
            return
        case <-ticker.C:
            // Count jobs in low-priority tiers using ZCOUNT with score ranges
            bgMin := fmt.Sprintf("%f", float64(1000)*0x100000000)
            bgMax := fmt.Sprintf("%f", float64(1001)*0x100000000-1)
            bgCount, _ := rdb.ZCount(ctx, kb.Prioritized(), bgMin, bgMax).Result()

            lowMin := fmt.Sprintf("%f", float64(500)*0x100000000)
            lowMax := fmt.Sprintf("%f", float64(501)*0x100000000-1)
            lowCount, _ := rdb.ZCount(ctx, kb.Prioritized(), lowMin, lowMax).Result()

            if bgCount > 500 || lowCount > 200 {
                log.Printf("[starvation] %s backlog: background=%d low=%d",
                    queue, bgCount, lowCount)
            }
        }
    }
}

go detectStarvation(ctx, rdb, "combat-actions", 15*time.Second)
```

> **Benefit**: Priority encoding uses composite score combining priority level and insertion order.

</tab>
<tab title="Node.js">

```typescript
import { Queue } from "bullmq";

const STARVATION_CHECK_INTERVAL = 15_000;

async function detectStarvation(queueName: string) {
  const queue = new Queue(queueName, {
    connection: { host: "localhost", port: 6379 },
  });

  setInterval(async () => {
    const counts = await queue.getCountsPerPriority([1, 10, 100, 500, 1000]);
    const bgCount = counts[1000] || 0;
    const lowCount = counts[500] || 0;

    if (bgCount > 500 || lowCount > 200) {
      console.warn(
        `[starvation] ${queueName} backlog: background=${bgCount} low=${lowCount}`
      );
    }
  }, STARVATION_CHECK_INTERVAL);
}

detectStarvation("combat-actions");
```

> **Benefit**: Priority values mirror BullMQ's proven sorted set implementation.

</tab>
</tabs>

### Mitigation Strategies

| Strategy | How | When |
|----------|-----|------|
| **Aging** | Periodically promote long-waiting low-priority jobs | Consistent starvation across tiers |
| **Reserved capacity** | Dedicate a worker with `concurrency: 5` to process only background jobs from a separate queue | Critical path cannot share workers |
| **Overflow queue** | When prioritized set exceeds threshold, spill to a separate background queue | Burst traffic with priority imbalance |
| **Dynamic demotion** | Demote high-priority jobs that exceed SLA to free capacity | High-priority jobs backing up |

## 26.12. Cross-Language Comparison

| Feature | Elixir | Go | Node.js |
|---------|--------|-----|---------|
| Add with priority | `Queue.add(..., priority: n)` | `q.Add(..., JobOptions{Priority: n})` | `queue.add(..., { priority: n })` |
| Priority range | 0 - 2,097,152 | 0+ (validated >= 0) | 0 - 2,097,152 |
| Composite score | Lua `getPriorityScore()` | Go: `priority * 0x100000000 + counter` | Lua `getPriorityScore()` |
| Change priority | `Job.change_priority/2` | Redis workaround (ZREM + ZADD) | `job.changePriority()` |
| Get prioritized | `Queue.get_prioritized/2` | `rdb.ZRange(kb.Prioritized())` | `queue.getJobs(["prioritized"])` |
| Counts per tier | `Queue.get_counts_per_priority/3` | `rdb.ZCount` with score ranges | `queue.getCountsPerPriority()` |
| Bulk priority | `Queue.add_bulk/3` (sequential) | Loop with `q.Add` | `queue.addBulk()` |
| Redis key | `bull:{queue}:prioritized` | `bull:{queue}:prioritized` | `bull:{queue}:prioritized` |
| Counter key | `bull:{queue}:pc` | `bull:{queue}:pc` | `bull:{queue}:pc` |

All three runtimes share the same Redis data structures. A priority job added from Go with `Priority: 10` is correctly ordered relative to jobs added from Elixir with `priority: 1` and Node.js with `{ priority: 100 }`. The composite score encoding ensures cross-runtime FIFO ordering within each tier.

---

*Previous: [Rate Limiting](ch25-rate-limiting.md) | Next: [Batches](ch27-batches.md)*
