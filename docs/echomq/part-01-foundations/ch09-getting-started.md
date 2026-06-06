# Chapter 09. Getting Started

This chapter takes you from zero to first job processed in your language of choice. You will create a combat action queue, enqueue a damage calculation job, and process it with a worker — all using the Fireheadz Arena game engine as the running example. All three runtimes are shown side by side — pick the tab that matches your stack.

## 9.1. Prerequisites

**Redis 6.0+** is required for all runtimes. EchoMQ uses Lua scripts and Redis Streams features introduced in Redis 6.

```bash
# Verify Redis version
redis-cli INFO server | grep redis_version

# Or start Redis via Docker
docker run -d -p 6379:6379 redis:7-alpine
```

Language-specific requirements:

<tabs>
<tab title="Elixir">

- Elixir 1.14+ / OTP 25+
- Mix build tool (ships with Elixir)

> **Benefit**: Pattern matching and keyword options provide self-documenting APIs with compile-time safety.

</tab>
<tab title="Go">

- Go 1.21+
- Go modules enabled (default since Go 1.16)

> **Tradeoff**: Explicit error handling adds verbosity but makes every failure path visible and auditable.

</tab>
<tab title="Node.js">

- Node.js 18+ (LTS recommended)
- npm or yarn

> **Benefit**: async/await makes asynchronous queue operations read like synchronous code.

</tab>
</tabs>

---

## 9.2. Installation

<tabs>
<tab title="Elixir">

Add to your `mix.exs` dependencies:

```elixir
defp deps do
  [
    {:echomq, "~> 1.3"},
    {:redix, "~> 1.2"}
  ]
end
```

Then fetch:

```bash
mix deps.get
```

> **Benefit**: Hex resolves EchoMQ's Lua scripts and Redix pool dependencies automatically -- no manual Redis configuration required.

</tab>
<tab title="Go">

```bash
go get github.com/fiberfx/echomq-go
```

> **Benefit**: Go modules pin the exact version, ensuring Lua script protocol compatibility with EchoMQ v5.62.0+.

</tab>
<tab title="Node.js">

```bash
npm install bullmq
```

The Node.js implementation IS BullMQ. The `bullmq` npm package is the EchoMQ reference implementation.

> **Benefit**: The bullmq npm package bundles all Lua scripts -- no separate binary or compilation step needed.

</tab>
</tabs>

---

## 9.3. Your First Queue

A queue is the entry point for submitting jobs. In a game backend, the `combat-actions` queue handles all damage calculations, buff applications, and skill resolutions.

<tabs>
<tab title="Elixir">

Queues are **stateless function calls** — no GenServer needed:

```elixir
# Enqueue a damage calculation for a player attacking a dragon
{:ok, job} = EchoMQ.Queue.add("combat-actions", "calculate-damage",
  %{
    player_id: "PLR0K48QjihpC4",
    action: "attack",
    target_id: "NPC5rK2mJ9pQ1L",
    damage: 150,
    room_id: "dungeon-7"
  },
  connection: :game_redis)

IO.puts("Combat job created: #{job.id}")
```

Options like `delay: 60_000` (delayed buff expiry) and `priority: 1` (critical hits first) are passed in the keyword list.

> **Benefit**: Priority maps to Redis sorted set scores — atomic ordering without application-level sorting.

</tab>
<tab title="Go">

Queues are struct-based — create once, reuse:

```go
rdb := redis.NewClient(&redis.Options{Addr: "localhost:6379"})
queue := echomq.NewQueue("combat-actions", rdb)

// Enqueue a damage calculation for a player attacking a dragon
job, err := queue.Add(ctx, "calculate-damage",
    map[string]interface{}{
        "player_id": "PLR0K48QjihpC4",
        "action":    "attack",
        "target_id": "NPC5rK2mJ9pQ1L",
        "damage":    150,
        "room_id":   "dungeon-7",
    },
    echomq.JobOptions{})
```

> **Benefit**: Strongly-typed option structs catch misconfiguration at compile time.

</tab>
<tab title="Node.js">

Queues are class-based — standard BullMQ API:

```typescript
const queue = new Queue("combat-actions", {
  connection: { host: "localhost", port: 6379 },
});

// Enqueue a damage calculation for a player attacking a dragon
const job = await queue.add("calculate-damage", {
  player_id: "PLR0K48QjihpC4",
  action: "attack",
  target_id: "NPC5rK2mJ9pQ1L",
  damage: 150,
  room_id: "dungeon-7",
});
```

Options like `{ delay: 60000 }` and `{ priority: 1 }` go in a third argument.

> **Benefit**: Priority values mirror BullMQ's proven sorted set implementation.

</tab>
</tabs>

All three runtimes write to the same Redis data structures. A job added by Go is visible to Elixir and Node.js workers immediately — the combat action lands in `bull:combat-actions:wait` regardless of which language enqueued it.

---

## 9.4. Your First Worker

A worker consumes jobs from a queue and processes them. The processor function receives a job and returns a result or error. In Fireheadz Arena, the combat worker dispatches to different handlers based on the action type — damage calculations, buff applications, and skill resolutions.

<tabs>
<tab title="Elixir">

Workers in Elixir are GenServers that integrate into your supervision tree. Pattern matching on job names provides clean dispatch:

```elixir
defmodule Arena.CombatProcessor do
  def process(%EchoMQ.Job{name: "calculate-damage", data: data}) do
    player = Arena.Players.get(data["player_id"])
    target = Arena.Entities.get(data["target_id"])

    # Apply armor, resistances, and critical hit modifiers
    final_damage = Arena.Combat.resolve_damage(player, target, data["damage"])
    Arena.Entities.apply_damage(target, final_damage)

    {:ok, %{
      damage_dealt: final_damage,
      target_hp: target.hp - final_damage,
      critical: final_damage > data["damage"]
    }}
  end

  def process(%EchoMQ.Job{name: "apply-buff", data: data}) do
    Arena.Buffs.apply(data["player_id"], data["buff_id"], data["duration_ms"])
    {:ok, %{applied: true}}
  end

  def process(%EchoMQ.Job{name: "resolve-skill", data: data}) do
    Arena.Skills.execute(data["player_id"], data["skill_id"], data["targets"])
    {:ok, %{resolved: true}}
  end

  def process(%EchoMQ.Job{name: name}) do
    {:error, "Unknown combat action: #{name}"}
  end
end
```

Start the worker in your application supervisor:

```elixir
defmodule Arena.Application do
  use Application

  def start(_type, _args) do
    children = [
      # Redis connection
      {Redix, name: :game_redis, host: "localhost", port: 6379},

      # Combat worker — 10 concurrent actions
      {EchoMQ.Worker,
        name: :combat_worker,
        queue: "combat-actions",
        connection: :game_redis,
        processor: &Arena.CombatProcessor.process/1,
        concurrency: 10}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
```

Each of those 10 concurrent jobs runs in its own BEAM process. If a damage calculation crashes due to corrupt player data, the other 9 combat actions continue unaffected — the supervisor simply restarts the failed process.

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
    ctx, cancel := signal.NotifyContext(context.Background(),
        os.Interrupt)
    defer cancel()

    rdb := redis.NewClient(&redis.Options{Addr: "localhost:6379"})

    // Create combat worker with 10 concurrent jobs
    worker := echomq.NewWorker("combat-actions", rdb, echomq.WorkerOptions{
        Concurrency:       10,
        LockDuration:      30 * time.Second,
        HeartbeatInterval: 15 * time.Second,
    })

    // Register the combat processor
    worker.Process(func(job *echomq.Job) (interface{}, error) {
        switch job.Name {
        case "calculate-damage":
            playerID := job.Data["player_id"].(string)
            targetID := job.Data["target_id"].(string)
            damage := int(job.Data["damage"].(float64))

            fmt.Printf("Resolving %d damage: %s -> %s\n",
                damage, playerID, targetID)

            // Apply combat resolution logic
            return map[string]interface{}{
                "damage_dealt": damage,
                "target_id":    targetID,
            }, nil

        case "apply-buff":
            fmt.Printf("Applying buff %s to %s\n",
                job.Data["buff_id"], job.Data["player_id"])
            return map[string]interface{}{"applied": true}, nil

        default:
            return nil, fmt.Errorf("unknown combat action: %s", job.Name)
        }
    })

    // Start processing (blocks until context cancelled)
    if err := worker.Start(ctx); err != nil {
        log.Fatal(err)
    }
}
```

> **Benefit**: Goroutine-per-job with semaphore-based limiting achieves OS-level parallelism.

</tab>
<tab title="Node.js">

Workers in BullMQ take a queue name and an async processor function:

```typescript
import { Worker, Job } from "bullmq";

const worker = new Worker(
  "combat-actions",
  async (job: Job) => {
    switch (job.name) {
      case "calculate-damage": {
        const { player_id, target_id, damage, room_id } = job.data;
        console.log(
          `Resolving ${damage} damage: ${player_id} -> ${target_id} in ${room_id}`
        );

        // Apply combat resolution logic
        const finalDamage = await resolveDamage(player_id, target_id, damage);
        return {
          damage_dealt: finalDamage,
          target_id,
          critical: finalDamage > damage,
        };
      }

      case "apply-buff": {
        const { player_id, buff_id, duration_ms } = job.data;
        await applyBuff(player_id, buff_id, duration_ms);
        return { applied: true };
      }

      case "resolve-skill": {
        const { player_id, skill_id, targets } = job.data;
        await executeSkill(player_id, skill_id, targets);
        return { resolved: true };
      }

      default:
        throw new Error(`Unknown combat action: ${job.name}`);
    }
  },
  {
    connection: { host: "localhost", port: 6379 },
    concurrency: 10,
  }
);

worker.on("completed", (job) => {
  console.log(`Combat action ${job.id} resolved`);
});

worker.on("failed", (job, err) => {
  console.log(`Combat action ${job?.id} failed: ${err.message}`);
});
```

> **Tradeoff**: Event loop concurrency means I/O-bound jobs scale well but CPU-bound jobs need worker threads.

</tab>
</tabs>

---

## 9.5. Adding More Queue Types

A real game backend uses multiple queues for different workloads. Here is how to enqueue jobs across the Fireheadz Arena domain:

<tabs>
<tab title="Elixir">

```elixir
# Matchmaking — find a ranked match for two players
{:ok, _} = EchoMQ.Queue.add("matchmaking", "find-match",
  %{players: ["PLR0K48QjihpC4", "PLR3QR5T7V9W2X"], mode: "ranked", map: "arena-3"},
  connection: :game_redis, priority: 1)

# Inventory — process a trade between players
{:ok, _} = EchoMQ.Queue.add("inventory", "process-trade",
  %{item_id: "ITM8xN3vP7qR4K", from_player: "PLR0K48QjihpC4", to_player: "PLR3QR5T7V9W2X", quantity: 1},
  connection: :game_redis)

# Leaderboard — update scores after a match ends
{:ok, _} = EchoMQ.Queue.add("leaderboard", "update-score",
  %{player_id: "PLR0K48QjihpC4", match_id: "MTH0K5M2vuIULY", score_delta: 25},
  connection: :game_redis)

# Player events — delayed achievement unlock (shows after 5 seconds)
{:ok, _} = EchoMQ.Queue.add("player-events", "unlock-achievement",
  %{player_id: "PLR0K48QjihpC4", achievement: "dragon_slayer"},
  connection: :game_redis, delay: 5_000)
```

> **Benefit**: Priority maps to Redis sorted set scores — atomic ordering without application-level sorting.

</tab>
<tab title="Go">

```go
matchmaking := echomq.NewQueue("matchmaking", rdb)
inventory := echomq.NewQueue("inventory", rdb)
leaderboard := echomq.NewQueue("leaderboard", rdb)
playerEvents := echomq.NewQueue("player-events", rdb)

// Matchmaking — find a ranked match for two players
matchmaking.Add(ctx, "find-match",
    map[string]interface{}{
        "players": []string{"PLR0K48QjihpC4", "PLR3QR5T7V9W2X"},
        "mode":    "ranked",
        "map":     "arena-3",
    },
    echomq.JobOptions{Priority: 1})

// Inventory — process a trade between players
inventory.Add(ctx, "process-trade",
    map[string]interface{}{
        "item_id":     "ITM8xN3vP7qR4K",
        "from_player": "PLR0K48QjihpC4",
        "to_player":   "PLR3QR5T7V9W2X",
        "quantity":    1,
    },
    echomq.JobOptions{})

// Leaderboard — update scores after a match ends
leaderboard.Add(ctx, "update-score",
    map[string]interface{}{
        "player_id":   "PLR0K48QjihpC4",
        "match_id":    "MTH0K5M2vuIULY",
        "score_delta": 25,
    },
    echomq.JobOptions{})

// Player events — delayed achievement unlock (shows after 5 seconds)
playerEvents.Add(ctx, "unlock-achievement",
    map[string]interface{}{
        "player_id":   "PLR0K48QjihpC4",
        "achievement": "dragon_slayer",
    },
    echomq.JobOptions{Delay: 5 * time.Second})
```

> **Benefit**: Priority encoding uses composite score combining priority level and insertion order.

</tab>
<tab title="Node.js">

```typescript
const matchmaking = new Queue("matchmaking", { connection: redisOpts });
const inventory = new Queue("inventory", { connection: redisOpts });
const leaderboard = new Queue("leaderboard", { connection: redisOpts });
const playerEvents = new Queue("player-events", { connection: redisOpts });

// Matchmaking — find a ranked match for two players
await matchmaking.add(
  "find-match",
  { players: ["PLR0K48QjihpC4", "PLR3QR5T7V9W2X"], mode: "ranked", map: "arena-3" },
  { priority: 1 }
);

// Inventory — process a trade between players
await inventory.add("process-trade", {
  item_id: "ITM8xN3vP7qR4K",
  from_player: "PLR0K48QjihpC4",
  to_player: "PLR3QR5T7V9W2X",
  quantity: 1,
});

// Leaderboard — update scores after a match ends
await leaderboard.add("update-score", {
  player_id: "PLR0K48QjihpC4",
  match_id: "MTH0K5M2vuIULY",
  score_delta: 25,
});

// Player events — delayed achievement unlock (shows after 5 seconds)
await playerEvents.add(
  "unlock-achievement",
  { player_id: "PLR0K48QjihpC4", achievement: "dragon_slayer" },
  { delay: 5000 }
);
```

> **Benefit**: Priority values mirror BullMQ's proven sorted set implementation.

</tab>
</tabs>

---

## 9.6. Cross-Runtime Verification

The power of EchoMQ is cross-runtime compatibility. Enqueue a combat job from one language and process it from another. For example, start the Elixir combat worker above, then enqueue from Go:

```go
queue := echomq.NewQueue("combat-actions", rdb)
queue.Add(ctx, "calculate-damage",
    map[string]interface{}{
        "player_id": "PLR0K48QjihpC4",
        "action":    "attack",
        "target_id": "NPC5rK2mJ9pQ1L",
        "damage":    150,
        "room_id":   "dungeon-7",
    },
    echomq.JobOptions{})
```

The Elixir worker picks up the Go-enqueued combat job automatically. This works because all implementations write to the same Redis keys (`bull:combat-actions:wait`, `bull:combat-actions:*`) using the same data format and Lua scripts.

You can verify this in Redis directly:

```bash
# Check that the job landed in the wait queue
redis-cli LLEN bull:combat-actions:wait

# Inspect the job data — same format regardless of which language enqueued it
redis-cli HGETALL bull:combat-actions:<job-id>
```

The `data` field in the job hash will contain the JSON payload exactly as submitted — `player_id`, `target_id`, `damage` — regardless of whether Go, Elixir, or Node.js wrote it.

---

## 9.7. What's Next

Now that you have a working combat queue and worker, explore the architecture in depth:

- [EchoMQ Overview](ch00-echomq-overview.md) — Protocol layers, version strategy, implementation status
- [Unified Protocol](ch01-unified-protocol.md) — The immutable Lua script and Redis data layers
- [Redis Data Layer](ch02-redis-data-layer.md) — Key taxonomy, data structures, field schemas
- [Elixir Architecture](ch04-elixir-architecture.md) — OTP patterns, supervision trees, BEAM advantages
- [Go Architecture](ch05-go-architecture.md) — Current status, gap analysis, v1.0 roadmap
- [Cross-Language Interop](ch06-cross-language-interop.md) — Feature matrix, known divergences, testing strategy

---

*Previous: [Why EchoMQ?](ch08-why-echomq.md) | Next: [Architecture Overview](ch10-architecture-overview.md)*
