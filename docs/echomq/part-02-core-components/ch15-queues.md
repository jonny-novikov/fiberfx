# Chapter 15. Queues

Queues are the entry point for submitting jobs into EchoMQ. A queue is a named container backed by Redis data structures that organizes jobs by state: waiting, active, delayed, prioritized, completed, and failed. All three EchoMQ runtimes share the same Redis keys and Lua scripts, so a job enqueued by Go is immediately visible to an Elixir worker and a Node.js dashboard.

In **Fireheadz Arena**, each game subsystem maps to a dedicated queue: `combat-actions` for damage calculations, `matchmaking` for lobby and rank pairing, `inventory` for trades and crafting, `leaderboard` for scores and rankings, `player-events` for login and achievements, and `world-sync` for NPC state and zone transitions.

## 15.1. Queue Concepts

A queue provides:

- **Job submission** -- add single or bulk jobs with options like delay, priority, and retry
- **State inspection** -- get counts, fetch jobs by state, check metadata
- **Lifecycle management** -- pause, resume, drain, clean, obliterate
- **Rate limiting** -- global rate limits and concurrency caps across all workers

Queues are **stateless by default** in Elixir and Go. You pass a queue name and connection to each operation. Optionally, you can run a queue as a supervised process (Elixir GenServer or Go struct) for connection reuse and default options.

## 15.2. Creating a Queue

<tabs>
<tab title="Elixir">

Queues in Elixir are **stateless function calls** -- no process needed for basic operations:

```elixir
# Stateless API -- pass queue name and connection each time
{:ok, job} = EchoMQ.Queue.add("combat-actions", "calculate-damage",
  %{player_id: "PLR0K48QjihpC4", action: "attack", target_id: "NPC5rK2mJ9pQ1L", damage: 150},
  connection: :my_redis)

# Or start a Queue GenServer for connection reuse
children = [
  {EchoMQ.Queue,
    name: :combat_queue,
    queue: "combat-actions",
    connection: :my_redis,
    default_job_opts: %{attempts: 3}}
]

# Then use by name (no connection: needed)
{:ok, job} = EchoMQ.Queue.add(:combat_queue, "calculate-damage",
  %{player_id: "PLR0K48QjihpC4", action: "attack", target_id: "NPC5rK2mJ9pQ1L", damage: 150})
```

The GenServer mode also sets queue metadata (version, maxLenEvents) in Redis on init, which is useful for dashboard tools like Bull Board.

> **Benefit**: Phoenix LiveView delivers real-time dashboards over WebSocket with zero client-side JavaScript.

</tab>
<tab title="Go">

Queues in Go are struct-based -- create once, reuse:

```go
import (
    "context"
    "github.com/fiberfx/echomq-go/pkg/echomq"
    "github.com/redis/go-redis/v9"
)

rdb := redis.NewClient(&redis.Options{Addr: "localhost:6379"})
combatQueue := echomq.NewQueue("combat-actions", rdb)

job, err := combatQueue.Add(ctx, "calculate-damage",
    map[string]interface{}{
        "player_id": "PLR0K48QjihpC4", "action": "attack",
        "target_id": "NPC5rK2mJ9pQ1L", "damage": 150,
    },
    echomq.JobOptions{})
```

`NewQueue` accepts both `*redis.Client` and `*redis.ClusterClient` via the `redis.Cmdable` interface. The constructor loads all embedded Lua scripts and creates an event emitter.

> **Benefit**: `redis.ClusterClient` with automatic CRC16 hash tag detection handles sharded Redis.

</tab>
<tab title="Node.js">

Queues in Node.js are class-based -- standard BullMQ API:

```typescript
import { Queue } from "bullmq";

const combatQueue = new Queue("combat-actions", {
  connection: { host: "localhost", port: 6379 },
});

const job = await combatQueue.add("calculate-damage", {
  player_id: "PLR0K48QjihpC4", action: "attack",
  target_id: "NPC5rK2mJ9pQ1L", damage: 150,
});
```

> **Benefit**: `ioredis` connection with lazy initialization — Redis connects only when the first command is issued.

</tab>
</tabs>

## 15.3. Adding Jobs

### Single Job

<tabs>
<tab title="Elixir">

```elixir
# Immediate combat action
{:ok, job} = EchoMQ.Queue.add("combat-actions", "calculate-damage",
  %{player_id: "PLR0K48QjihpC4", action: "attack", target_id: "NPC5rK2mJ9pQ1L", damage: 150},
  connection: :redis)

# Delayed NPC respawn (60 seconds cooldown)
{:ok, job} = EchoMQ.Queue.add("world-sync", "spawn-npc",
  %{npc_id: "NPC5rK2mJ9pQ1L", zone: "dungeon-7"},
  connection: :redis,
  delay: 60_000)

# Prioritized damage resolution (lower number = higher priority)
{:ok, job} = EchoMQ.Queue.add("combat-actions", "resolve-skill",
  %{player_id: "PLR0K48QjihpC4", skill_id: "fireball", target_id: "NPC5rK2mJ9pQ1L"},
  connection: :redis,
  priority: 1)

# Matchmaking with retries and exponential backoff
{:ok, job} = EchoMQ.Queue.add("matchmaking", "find-match",
  %{player_id: "PLR0K48QjihpC4", mode: "ranked"},
  connection: :redis,
  attempts: 5,
  backoff: %{type: :exponential, delay: 1000})
```

Internally, `add/4` routes to one of three Lua scripts based on options:
- `add_standard_job` for normal FIFO jobs (LPUSH to wait list)
- `add_delayed_job` for delayed jobs (ZADD to delayed sorted set)
- `add_prioritized_job` for priority jobs (ZADD to prioritized sorted set with priority counter)

> **Benefit**: Custom backoff functions receive attempt count and error — full context for delay calculation.

</tab>
<tab title="Go">

```go
// Immediate combat action
job, err := queue.Add(ctx, "calculate-damage",
    map[string]interface{}{
        "player_id": "PLR0K48QjihpC4", "action": "attack",
        "target_id": "NPC5rK2mJ9pQ1L", "damage": 150,
    },
    echomq.JobOptions{})

// Delayed NPC respawn (60 seconds cooldown)
job, err := queue.Add(ctx, "spawn-npc",
    map[string]interface{}{"npc_id": "NPC5rK2mJ9pQ1L", "zone": "dungeon-7"},
    echomq.JobOptions{Delay: 60 * time.Second})

// Prioritized damage resolution
job, err := queue.Add(ctx, "resolve-skill",
    map[string]interface{}{
        "player_id": "PLR0K48QjihpC4", "skill_id": "fireball",
        "target_id": "NPC5rK2mJ9pQ1L",
    },
    echomq.JobOptions{Priority: 1})

// Matchmaking with retries
job, err := queue.Add(ctx, "find-match",
    map[string]interface{}{"player_id": "PLR0K48QjihpC4", "mode": "ranked"},
    echomq.JobOptions{
        Attempts: 5,
        Backoff: echomq.BackoffConfig{
            Type:  "exponential",
            Delay: 1000,
        },
    })
```

> **Benefit**: Backoff configuration is declarative — `Type` and `Delay` fields are validated at compile time.

</tab>
<tab title="Node.js">

```typescript
// Immediate combat action
const job = await queue.add("calculate-damage", {
  player_id: "PLR0K48QjihpC4", action: "attack",
  target_id: "NPC5rK2mJ9pQ1L", damage: 150,
});

// Delayed NPC respawn (60 seconds cooldown)
const job = await queue.add("spawn-npc", {
  npc_id: "NPC5rK2mJ9pQ1L", zone: "dungeon-7",
}, { delay: 60000 });

// Prioritized damage resolution
const job = await queue.add("resolve-skill", {
  player_id: "PLR0K48QjihpC4", skill_id: "fireball", target_id: "NPC5rK2mJ9pQ1L",
}, { priority: 1 });

// Matchmaking with retries
const job = await queue.add("find-match", {
  player_id: "PLR0K48QjihpC4", mode: "ranked",
}, {
  attempts: 5,
  backoff: { type: "exponential", delay: 1000 },
});
```

> **Benefit**: Custom backoff functions return millisecond delay — simple numeric interface.

</tab>
</tabs>

### Bulk Add

Bulk add submits multiple jobs atomically -- useful for spawning a batch of NPCs when a dungeon zone loads.

<tabs>
<tab title="Elixir">

Bulk add is **atomic** and uses transactional pipelining for high throughput (~60,000 jobs/sec with connection pooling):

```elixir
# Spawn a batch of NPCs for dungeon zone 7
jobs = [
  {"spawn-npc", %{npc_id: "NPC8xN3vP7qR4K", zone: "dungeon-7", hp: 500}, []},
  {"spawn-npc", %{npc_id: "NPC2wM6kR9sT1J", zone: "dungeon-7", hp: 500}, []},
  {"spawn-npc", %{npc_id: "NPC5rK2mJ9pQ1L", zone: "dungeon-7", hp: 50_000}, [priority: 1]}
]

{:ok, added_jobs} = EchoMQ.Queue.add_bulk("world-sync", jobs, connection: :redis)

# With connection pool for massive zone loading (hundreds of NPCs)
pool = for i <- 1..8 do
  name = :"redis_pool_#{i}"
  {:ok, _} = Redix.start_link(host: "localhost", name: name)
  name
end

{:ok, jobs} = EchoMQ.Queue.add_bulk("world-sync", npc_spawn_list,
  connection: :redis,
  connection_pool: pool,
  chunk_size: 100)
```

Standard jobs (no delay or priority) use optimized pipelining. Delayed and prioritized jobs fall back to sequential Lua script calls.

> **Benefit**: `Ecto.Multi` composes the enqueue step into the database transaction — atomic commit or rollback.

</tab>
<tab title="Go">

Go does not yet have a dedicated bulk add API. Use a loop with goroutines for concurrent submission:

```go
var wg sync.WaitGroup
npcs := []struct{ name string; data map[string]interface{} }{
    {"spawn-npc", map[string]interface{}{"npc_id": "NPC8xN3vP7qR4K", "zone": "dungeon-7", "hp": 500}},
    {"spawn-npc", map[string]interface{}{"npc_id": "NPC2wM6kR9sT1J", "zone": "dungeon-7", "hp": 500}},
    {"spawn-npc", map[string]interface{}{"npc_id": "NPC5rK2mJ9pQ1L", "zone": "dungeon-7", "hp": 50000}},
}

for _, npc := range npcs {
    wg.Add(1)
    go func(name string, data map[string]interface{}) {
        defer wg.Done()
        queue.Add(ctx, name, data, echomq.JobOptions{})
    }(npc.name, npc.data)
}
wg.Wait()
```

> **Benefit**: Group IDs as struct fields enable type-safe group assignment at compile time.

</tab>
<tab title="Node.js">

```typescript
// Spawn NPCs for dungeon zone 7
const npcs = [
  { name: "spawn-npc", data: { npc_id: "NPC8xN3vP7qR4K", zone: "dungeon-7", hp: 500 } },
  { name: "spawn-npc", data: { npc_id: "NPC2wM6kR9sT1J", zone: "dungeon-7", hp: 500 } },
  { name: "spawn-npc", data: { npc_id: "NPC5rK2mJ9pQ1L", zone: "dungeon-7", hp: 50000 },
    opts: { priority: 1 } },
];

const addedJobs = await queue.addBulk(npcs);
```

> **Benefit**: Priority values mirror BullMQ's proven sorted set implementation.

</tab>
</tabs>

## 15.4. Getting Queue Counts

Monitor queue health by inspecting job state distribution. In a game server, this powers dashboards that show how many combat actions are pending, how many matchmaking attempts have failed, and whether the world-sync queue is falling behind.

<tabs>
<tab title="Elixir">

```elixir
{:ok, counts} = EchoMQ.Queue.get_counts("combat-actions", connection: :redis)
# %{
#   waiting: 10,
#   active: 2,
#   delayed: 5,
#   prioritized: 3,
#   completed: 150,
#   failed: 3,
#   paused: 0,
#   waiting_children: 1
# }

# Total pending count (waiting + paused + delayed + prioritized + waiting_children)
{:ok, total} = EchoMQ.Queue.count("combat-actions", connection: :redis)

# Counts for specific states
{:ok, counts} = EchoMQ.Queue.get_job_counts("matchmaking", [:waiting, :failed],
  connection: :redis)
```

Uses a Redis pipeline to execute LLEN/ZCARD commands in parallel for all states.

> **Benefit**: Queue pause uses Redis flags — paused state persists across BEAM node restarts.

</tab>
<tab title="Go">

```go
counts, err := queue.GetJobCounts(ctx)
// counts.Waiting, counts.Active, counts.Completed,
// counts.Failed, counts.Delayed, counts.Prioritized

fmt.Printf("Combat queue -- Waiting: %d, Active: %d, Failed: %d\n",
    counts.Waiting, counts.Active, counts.Failed)
```

Uses a Redis pipeline for parallel count retrieval.

> **Benefit**: `time.Duration` types prevent unit mismatch bugs that plague raw millisecond integers.

</tab>
<tab title="Node.js">

```typescript
const counts = await queue.getJobCounts(
  "waiting", "active", "completed", "failed", "delayed"
);
console.log(`Combat queue -- Waiting: ${counts.waiting}, Failed: ${counts.failed}`);
```

> **Benefit**: Millisecond delays align with JavaScript's native timing model — intuitive for Node.js developers.

</tab>
</tabs>

## 15.5. Pausing and Resuming

When paused, workers stop picking up new jobs. Active jobs continue to completion. Pause the matchmaking queue during server maintenance windows, and resume when the game servers are back online.

<tabs>
<tab title="Elixir">

```elixir
# Pause matchmaking during maintenance -- active matches continue to completion
:ok = EchoMQ.Queue.pause("matchmaking", connection: :redis)

# Resume matchmaking after maintenance
:ok = EchoMQ.Queue.resume("matchmaking", connection: :redis)

# Check pause state before allowing new match requests
true = EchoMQ.Queue.paused?("matchmaking", connection: :redis)
```

Pause/resume use a Lua script that atomically moves waiting jobs between the `wait` and `paused` lists and sets/removes the `paused` field in the queue metadata hash.

> **Benefit**: Queue pause uses Redis flags — paused state persists across BEAM node restarts.

</tab>
<tab title="Go">

```go
// Pause matchmaking during maintenance
err := queue.Pause(ctx)

// Resume after maintenance
err := queue.Resume(ctx)

// Check before accepting new match requests
paused, err := queue.IsPaused(ctx)
```

Go uses direct HSET/HDEL on the meta key. Note: this does not use the Lua script, which is a protocol gap (see Comparison Table below).

> **Benefit**: Pause/resume operates at the Redis level — consistent behavior across all runtimes.

</tab>
<tab title="Node.js">

```typescript
// Pause matchmaking during maintenance
await queue.pause();

// Resume after maintenance
await queue.resume();

const isPaused = await queue.isPaused();
```

> **Benefit**: `queue.pause()` and `queue.resume()` toggle processing without disconnecting.

</tab>
</tabs>

## 15.6. Cleaning and Draining

Clean completed combat logs older than 24 hours to keep Redis memory bounded, or drain the matchmaking queue before a server restart.

<tabs>
<tab title="Elixir">

```elixir
# Clean completed combat actions older than 24 hours
{:ok, removed_ids} = EchoMQ.Queue.clean("combat-actions", :completed, 86_400_000,
  connection: :redis, limit: 1000)

# Drain matchmaking queue before server restart (without processing)
:ok = EchoMQ.Queue.drain("matchmaking", connection: :redis, delayed: true)

# Obliterate a test queue (irreversible!)
:ok = EchoMQ.Queue.obliterate("combat-actions-test", connection: :redis)

# Force obliterate even with active jobs
:ok = EchoMQ.Queue.obliterate("combat-actions-test", connection: :redis, force: true)
```

> **Benefit**: Rate limiting uses Redis TTL keys — distributed limiting works across clustered BEAM nodes.

</tab>
<tab title="Go">

```go
// Clean completed combat actions older than 24 hours
removed, err := queue.Clean(ctx, 24*time.Hour, 1000, "completed")

// Drain matchmaking queue before server restart
totalRemoved, err := queue.Drain(ctx)

// Remove a specific stale job
err := queue.RemoveJob(ctx, "job-id-123")
```

> **Benefit**: Drain operates via Lua scripts — atomic removal regardless of queue size.

</tab>
<tab title="Node.js">

```typescript
// Clean completed combat actions older than 24 hours
const removed = await queue.clean(86400000, 1000, "completed");

// Drain matchmaking queue before server restart
await queue.drain();

// Obliterate a test queue
await queue.obliterate();
```

> **Benefit**: `limiter` option integrates with BullMQ's built-in token bucket implementation.

</tab>
</tabs>

## 15.7. Queue Metadata

Queue metadata stores operational state such as the pause flag, EchoMQ version, global concurrency, and rate limit configuration. This metadata is stored in the Redis `meta` hash key for each queue.

<tabs>
<tab title="Elixir">

```elixir
# Get metadata (paused state, version, concurrency, rate limit)
{:ok, meta} = EchoMQ.Queue.get_meta("combat-actions", connection: :redis)
# %{paused: false, version: "bullmq:5.65.1", concurrency: nil, ...}

# Get the EchoMQ version stored in Redis
{:ok, version} = EchoMQ.Queue.get_version("combat-actions", connection: :redis)
# "bullmq:5.65.1"

# Explicitly set metadata (version + maxLenEvents)
:ok = EchoMQ.Queue.update_meta("combat-actions", connection: :redis)
```

> **Benefit**: BEAM processes provide true preemptive concurrency — one slow job cannot starve others.

</tab>
<tab title="Go">

Go queue metadata is managed through the KeyBuilder's Meta key. Currently, the Go API exposes only the pause state from metadata. A full `GetMeta()` method that returns version, concurrency, and rate limit fields is not yet available -- the underlying Redis hash contains the data, but Go does not have a dedicated struct or method to parse it.

```go
// Check pause state via metadata
paused, err := queue.IsPaused(ctx)

// For other metadata fields, read the Redis hash directly:
// rdb.HGetAll(ctx, "bull:combat-actions:meta")
```

> **Benefit**: Goroutine-per-job with semaphore-based limiting achieves OS-level parallelism.

</tab>
<tab title="Node.js">

```typescript
const { concurrency, max, duration, maxLenEvents, paused, version } =
  await queue.getMeta();
console.log(`Queue version: ${version}, Paused: ${paused}`);
```

> **Tradeoff**: Event loop concurrency means I/O-bound jobs scale well but CPU-bound jobs need worker threads.

</tab>
</tabs>

## 15.8. Rate Limiting and Global Concurrency

Rate limiting prevents game server overload. For example, limit the `combat-actions` queue to 500 concurrent damage calculations across all worker nodes, or cap `matchmaking` to 100 match searches per minute to avoid overwhelming the ranking service.

<tabs>
<tab title="Elixir">

Rate limiting is configured on the **worker**, not the queue, but the queue stores the configuration:

```elixir
# Set global concurrency (max 500 combat actions active across all workers)
:ok = EchoMQ.Queue.set_global_concurrency("combat-actions", 500, connection: :redis)

# Read global concurrency
{:ok, 500} = EchoMQ.Queue.get_global_concurrency("combat-actions", connection: :redis)

# Rate limit TTL (how long until the rate window refreshes)
{:ok, ttl_ms} = EchoMQ.Queue.get_rate_limit_ttl("matchmaking", connection: :redis)
```

Rate limiting uses the Lua `moveToActive` script. When the rate limit is exceeded, the worker receives a rate-limited delay and waits before fetching the next job.

> **Benefit**: BEAM processes provide true preemptive concurrency — one slow job cannot starve others.

</tab>
<tab title="Go">

Rate limiting is not yet implemented in the Go runtime. The `moveToActive` Lua script is embedded and supports rate limit arguments, but the Go Worker does not yet pass rate limiter options. See [PROTOCOL-GAPS.md](https://github.com/fiberfx/echomq-go) for the tracking issue.

> **Benefit**: Goroutine-per-job with semaphore-based limiting achieves OS-level parallelism.

</tab>
<tab title="Node.js">

```typescript
// Cap matchmaking to 100 searches per minute
const worker = new Worker("matchmaking", processor, {
  connection,
  limiter: { max: 100, duration: 60000 },
});
```

> **Tradeoff**: Event loop concurrency means I/O-bound jobs scale well but CPU-bound jobs need worker threads.

</tab>
</tabs>

## 15.9. Comparison: Queue API by Runtime

| Operation | Elixir | Go | Node.js |
|-----------|--------|-----|---------|
| Add single job | `Queue.add/4` | `Queue.Add()` | `queue.add()` |
| Bulk add | `Queue.add_bulk/3` (atomic, pipelined) | Loop + goroutines | `queue.addBulk()` |
| Get counts | `Queue.get_counts/2` | `Queue.GetJobCounts()` | `queue.getJobCounts()` |
| Get jobs by state | `Queue.get_jobs/3` | `Queue.GetWaitingJobs()` etc. | `queue.getJobs()` |
| Pause/Resume | Lua script (atomic) | HSET/HDEL (non-atomic) | Lua script (atomic) |
| Clean old jobs | `Queue.clean/4` | `Queue.Clean()` | `queue.clean()` |
| Drain | Lua script | Pipeline delete | `queue.drain()` |
| Obliterate | Lua script (iterative) | Not implemented | `queue.obliterate()` |
| Rate limiting | Worker-level, Lua enforced | Not wired | Worker-level, Lua enforced |
| Global concurrency | `Queue.set_global_concurrency/3` | Not implemented | Worker options |
| Bulk add throughput | ~60K/s (pooled pipeline) | ~6K/s (goroutine loop) | ~30K/s (pipelined) |
| Prometheus export | `Queue.export_prometheus_metrics/2` | Not implemented | Via Bull Board |

## 15.10. Cross-Runtime Interoperability

All three runtimes write to the same Redis keys. Here is the key layout for the `combat-actions` queue:

```
bull:combat-actions:wait        -- LIST: waiting job IDs (FIFO)
bull:combat-actions:active      -- LIST: active job IDs
bull:combat-actions:delayed     -- ZSET: delayed job IDs (score = timestamp)
bull:combat-actions:prioritized -- ZSET: prioritized job IDs (score = priority)
bull:combat-actions:completed   -- ZSET: completed job IDs (score = timestamp)
bull:combat-actions:failed      -- ZSET: failed job IDs (score = timestamp)
bull:combat-actions:meta        -- HASH: queue metadata (paused, version, etc.)
bull:combat-actions:{id}        -- HASH: job data, opts, state
```

A job added by Go is visible to an Elixir worker immediately. The key difference is atomicity: Elixir and Node.js use Lua scripts for critical-path operations (add, pause, drain), while Go uses separate Redis commands for some operations, creating brief windows of inconsistency in cluster scenarios. In practice, this means a Go-enqueued damage calculation can be picked up by an Elixir combat worker within the same tick.

---

*Previous: [Job Options](ch14-job-options.md) | Next: [Workers](ch16-workers.md)*
