# Chapter 27. Batches

Batch operations add many jobs to a queue in a single Redis round-trip. Instead of issuing one `add` call per job, `addBulk` sends all jobs atomically: either every job is enqueued or none are. This eliminates the per-job round-trip overhead that makes individual adds ~100x slower for large workloads. In the Fireheadz Arena, batch operations drive NPC wave spawning (100 NPCs per combat wave), tournament bracket seeding (64 players), and season-reset reward distribution (thousands of player mailbox items).

## 27.1. How Bulk Addition Works

EchoMQ wraps all jobs into a single Redis transaction (`MULTI`/`EXEC`). The queue receives a list of job descriptors, builds the Redis commands for each, and pipelines them in one network call. The transaction guarantees atomicity: if the connection drops mid-pipeline, Redis rolls back all commands in the `MULTI` block.

```
Bulk Add Pipeline (1000 jobs)

  Client                         Redis
    |                              |
    |-- MULTI ------------------>  |
    |-- ZADD bull:{q}:wait ...-->  |  (job 1)
    |-- HSET bull:{q}:{id} ... ->  |
    |-- ZADD bull:{q}:wait ...-->  |  (job 2)
    |-- HSET bull:{q}:{id} ... ->  |
    |   ... (998 more) ...         |
    |-- EXEC ------------------->  |
    |<-- [OK, OK, OK, ...] -----  |  (1 round-trip)
    |                              |
    Total: 1 network round-trip
    Latency: ~10ms for 1000 jobs
```

## 27.2. Basic Bulk Addition

Add multiple jobs in a single call. Each job is described as a tuple of `{name, data, options}`.

<tabs>
<tab title="Elixir">

```elixir
# Spawn an NPC combat wave: 100 enemies for a dungeon instance
npc_jobs = for i <- 1..100 do
  npc_id = EchoData.build_branded_id("NPC")
  {"spawn-npc", %{
    "npc_id" => npc_id,
    "zone" => "dungeon_floor_3",
    "level" => 25,
    "archetype" => Enum.random(["warrior", "mage", "archer", "healer"])
  }, []}
end

{:ok, spawned} = EchoMQ.Queue.add_bulk("npc-spawns", npc_jobs,
  connection: :arena_redis
)

IO.puts("Spawned #{length(spawned)} NPCs in dungeon_floor_3")
```

Each tuple follows the format `{job_name, job_data, job_options}`:

| Element | Type | Description |
|---------|------|-------------|
| `name` | `String.t()` | Job type identifier (e.g., `"spawn-npc"`) |
| `data` | `map()` | Job payload (arbitrary data) |
| `options` | `keyword()` | Per-job options: `priority`, `delay`, `attempts`, `job_id` |

> **Benefit**: Priority maps to Redis sorted set scores — atomic ordering without application-level sorting.

</tab>
<tab title="Go">

> **Go Gap: Bulk Job Addition**
> - **Feature**: `AddBulk` / batch job creation via single pipeline
> - **Reason**: Not yet implemented in the Go client
> - **Workaround**: Use a Redis pipeline with multiple `AddJob` calls (see below)
> - **Reference**: [PROTOCOL-GAPS.md](PROTOCOL-GAPS.md)

```go
// Workaround: pipeline multiple AddJob calls via raw Redis commands
package main

import (
    "context"
    "encoding/json"
    "fmt"
    "log"
    "time"

    "github.com/redis/go-redis/v9"
)

func addBulkWorkaround(ctx context.Context, rdb *redis.Client, queue string, jobs []map[string]interface{}) error {
    pipe := rdb.Pipeline()
    prefix := "bull"
    now := time.Now().UnixMilli()

    for i, job := range jobs {
        jobID := fmt.Sprintf("wave3-%d-%d", now, i)
        dataJSON, _ := json.Marshal(job["data"])

        key := fmt.Sprintf("%s:%s:%s", prefix, queue, jobID)
        pipe.HSet(ctx, key, map[string]interface{}{
            "name":      job["name"],
            "data":      string(dataJSON),
            "opts":      "{}",
            "timestamp": now,
        })
        pipe.ZAdd(ctx, fmt.Sprintf("%s:%s:wait", prefix, queue), redis.Z{
            Score:  float64(now),
            Member: jobID,
        })
    }

    _, err := pipe.Exec(ctx)
    return err
}

func main() {
    ctx := context.Background()
    rdb := redis.NewClient(&redis.Options{Addr: "localhost:6379"})

    var npcJobs []map[string]interface{}
    for i := 0; i < 100; i++ {
        npcJobs = append(npcJobs, map[string]interface{}{
            "name": "spawn-npc",
            "data": map[string]interface{}{
                "npc_id":    echomq.GenerateBrandedID("NPC"),
                "zone":      "dungeon_floor_3",
                "level":     25,
                "archetype": "warrior",
            },
        })
    }

    if err := addBulkWorkaround(ctx, rdb, "npc-spawns", npcJobs); err != nil {
        log.Fatal(err)
    }
    fmt.Println("Spawned 100 NPCs via pipeline workaround")
}
```

The pipeline workaround sends all commands in one round-trip but does not use the `addStandardJob` Lua script. This means delayed/prioritized jobs require additional sorted set operations. For production use, prefer Elixir or Node.js workers for bulk operations.

> **Benefit**: Slice-based batching with goroutine fan-out provides predictable memory usage.

</tab>
<tab title="Node.js">

```typescript
import { Queue, Job } from "bullmq";

const queue = new Queue("npc-spawns", {
  connection: { host: "localhost", port: 6379 },
});

// Spawn an NPC combat wave: 100 enemies for a dungeon instance
const npcJobs = Array.from({ length: 100 }, (_, i) => ({
  name: "spawn-npc",
  data: {
    npc_id: generateBrandedId("NPC"),
    zone: "dungeon_floor_3",
    level: 25,
    archetype: ["warrior", "mage", "archer", "healer"][i % 4],
  },
}));

const spawned: Job[] = await queue.addBulk(npcJobs);
console.log(`Spawned ${spawned.length} NPCs in dungeon_floor_3`);
```

Node.js `addBulk` accepts an array of `{name, data, opts}` objects. The `opts` field is optional for each job.

> **Benefit**: `queue.addBulk()` sends all jobs in a single pipeline — optimal for batch insertion.

</tab>
</tabs>

> **⚠️ Go Gap**: Bulk job addition is not implemented, limiting batch submission throughput. See [Chapter 12 -- Jobs Overview](ch12-jobs-overview.md) for details.
> **Proposed Solution**: Implement `Queue.AddBulk()` using pipelined `addStandardJob` Lua script calls within a single Redis transaction, matching Elixir's `Queue.add_bulk/2` chunked approach.

## 27.3. Job Options in Bulk

Each job in the batch can have independent options. Jobs with delay or priority are handled differently by the pipeline internally.

<tabs>
<tab title="Elixir">

```elixir
# Tournament bracket seeding: 64 players with tiered priorities
bracket_jobs = [
  # Top-seed players get high priority (processed first)
  {"seed-bracket", %{"player_id" => "PLRdK6mO8qS0uW", "seed" => 1, "bracket" => "A"},
    [priority: 1, job_id: "seed-PLRdK6mO8qS0uW"]},
  {"seed-bracket", %{"player_id" => "PLReL7nP9rT1vX", "seed" => 2, "bracket" => "A"},
    [priority: 1, job_id: "seed-PLReL7nP9rT1vX"]},

  # Mid-seed players at normal priority
  {"seed-bracket", %{"player_id" => "PLRfM8oQ0sU2wY", "seed" => 15, "bracket" => "B"},
    [priority: 50]},

  # Late-seed players with delayed reveal (dramatic effect)
  {"seed-bracket", %{"player_id" => "PLRgN9pR1tV3xZ", "seed" => 64, "bracket" => "D"},
    [priority: 100, delay: 30_000]},  # Reveal after 30 seconds
]

{:ok, seeded} = EchoMQ.Queue.add_bulk("tournament-seeding", bracket_jobs,
  connection: :arena_redis
)
```

Options available per job:

| Option | Type | Description |
|--------|------|-------------|
| `:priority` | `integer` | Lower number = higher priority (0 is highest) |
| `:delay` | `integer` | Delay in milliseconds before job becomes active |
| `:attempts` | `integer` | Maximum retry attempts on failure |
| `:job_id` | `String.t()` | Custom job ID (deduplication key) |
| `:backoff` | `map` | Backoff strategy for retries |

> **Benefit**: Custom backoff functions receive attempt count and error — full context for delay calculation.

</tab>
<tab title="Go">

> **Go Gap: Bulk Job Addition**
> - **Feature**: Per-job options in bulk (priority, delay, custom ID)
> - **Reason**: No `AddBulk` API in Go client; the pipeline workaround requires manual sorted set management for delayed/prioritized jobs
> - **Workaround**: For standard jobs, use the Redis pipeline approach shown above. For delayed jobs, add to the `delayed` sorted set with the target timestamp as the score. For prioritized jobs, use the composite score encoding: `priority * 0x100000000 + counter`.
> - **Reference**: [PROTOCOL-GAPS.md](PROTOCOL-GAPS.md)

```go
// Delayed + prioritized jobs require different sorted sets
func addBulkWithOptions(ctx context.Context, rdb *redis.Client, queue string, jobs []BulkJob) error {
    pipe := rdb.Pipeline()
    prefix := "bull"
    now := time.Now().UnixMilli()
    counter := int64(0)

    for _, job := range jobs {
        jobID := job.ID
        if jobID == "" {
            jobID = fmt.Sprintf("%d-%d", now, counter)
        }
        counter++

        dataJSON, _ := json.Marshal(job.Data)
        key := fmt.Sprintf("%s:%s:%s", prefix, queue, jobID)
        pipe.HSet(ctx, key, map[string]interface{}{
            "name": job.Name, "data": string(dataJSON),
            "opts": fmt.Sprintf(`{"priority":%d,"delay":%d}`, job.Priority, job.Delay),
            "timestamp": now,
        })

        switch {
        case job.Delay > 0:
            // Delayed: add to delayed sorted set with target timestamp
            pipe.ZAdd(ctx, fmt.Sprintf("%s:%s:delayed", prefix, queue), redis.Z{
                Score: float64(now + int64(job.Delay)), Member: jobID,
            })
        case job.Priority > 0:
            // Prioritized: composite score = priority * 0x100000000 + counter
            score := float64(int64(job.Priority)*0x100000000 + counter)
            pipe.ZAdd(ctx, fmt.Sprintf("%s:%s:priority", prefix, queue), redis.Z{
                Score: score, Member: jobID,
            })
        default:
            // Standard: add to wait list
            pipe.ZAdd(ctx, fmt.Sprintf("%s:%s:wait", prefix, queue), redis.Z{
                Score: float64(now), Member: jobID,
            })
        }
    }

    _, err := pipe.Exec(ctx)
    return err
}
```

> **Benefit**: Priority encoding uses composite score combining priority level and insertion order.

</tab>
<tab title="Node.js">

```typescript
import { Queue, Job } from "bullmq";

const queue = new Queue("tournament-seeding", {
  connection: { host: "localhost", port: 6379 },
});

// Tournament bracket seeding with per-job options
const bracketJobs = [
  // Top seeds: high priority, custom IDs for deduplication
  {
    name: "seed-bracket",
    data: { player_id: "PLRdK6mO8qS0uW", seed: 1, bracket: "A" },
    opts: { priority: 1, jobId: "seed-PLRdK6mO8qS0uW" },
  },
  {
    name: "seed-bracket",
    data: { player_id: "PLReL7nP9rT1vX", seed: 2, bracket: "A" },
    opts: { priority: 1, jobId: "seed-PLReL7nP9rT1vX" },
  },
  // Mid seeds: normal priority
  {
    name: "seed-bracket",
    data: { player_id: "PLRfM8oQ0sU2wY", seed: 15, bracket: "B" },
    opts: { priority: 50 },
  },
  // Wildcard: delayed reveal for dramatic effect
  {
    name: "seed-bracket",
    data: { player_id: "PLRgN9pR1tV3xZ", seed: 64, bracket: "D" },
    opts: { priority: 100, delay: 30_000 },
  },
];

const seeded: Job[] = await queue.addBulk(bracketJobs);
console.log(`Seeded ${seeded.length} players into tournament brackets`);
```

> **Benefit**: Priority values mirror BullMQ's proven sorted set implementation.

</tab>
</tabs>

## 27.4. Atomicity Guarantees

All jobs in a batch are added atomically. The Redis `MULTI`/`EXEC` transaction ensures that either every job in the batch is enqueued or none are. There is no partial state where some jobs exist and others do not.

<tabs>
<tab title="Elixir">

```elixir
# Season reset: distribute rewards to all qualifying players
defmodule Arena.SeasonReset do
  def distribute_rewards(qualifying_players) do
    reward_jobs = Enum.map(qualifying_players, fn player ->
      {"distribute-reward", %{
        "player_id" => player.id,
        "season" => 12,
        "rank" => player.rank,
        "reward_tier" => reward_tier(player.rank),
        "items" => reward_items(player.rank)
      }, []}
    end)

    case EchoMQ.Queue.add_bulk("season-rewards", reward_jobs,
      connection: :arena_redis
    ) do
      {:ok, jobs} ->
        Logger.info("Season reset: #{length(jobs)} reward jobs enqueued atomically")
        {:ok, length(jobs)}

      {:error, reason} ->
        # No partial distribution -- all or nothing
        Logger.error("Season reset failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp reward_tier(rank) when rank <= 10, do: "legendary"
  defp reward_tier(rank) when rank <= 100, do: "epic"
  defp reward_tier(rank) when rank <= 500, do: "rare"
  defp reward_tier(_rank), do: "common"

  defp reward_items("legendary"), do: ["ITM2zP5xR7tT3M", "ITM9gW2eY4aA0T", "ITM5cS8aU0wW6P"]
  defp reward_items("epic"), do: ["ITM0hX3fZ5bB1U", "ITM6dT9bV1xX7Q"]
  defp reward_items("rare"), do: ["ITM0hX3fZ5bB1U", "ITM7eU0cW2yY8R"]
  defp reward_items("common"), do: ["ITM8fV1dX3zZ9S"]
end
```

> **Benefit**: Pipeline-based bulk operations send multiple commands in a single Redis roundtrip.

</tab>
<tab title="Go">

```go
// Season reset reward distribution -- pipeline workaround
func distributeSeasonRewards(ctx context.Context, rdb *redis.Client, players []Player) error {
    var jobs []map[string]interface{}
    for _, p := range players {
        jobs = append(jobs, map[string]interface{}{
            "name": "distribute-reward",
            "data": map[string]interface{}{
                "player_id":   p.ID,
                "season":      12,
                "rank":        p.Rank,
                "reward_tier": rewardTier(p.Rank),
            },
        })
    }

    err := addBulkWorkaround(ctx, rdb, "season-rewards", jobs)
    if err != nil {
        // Pipeline failure: no jobs were added (atomic rollback)
        log.Printf("Season reset failed: %v", err)
        return err
    }

    log.Printf("Season reset: %d reward jobs enqueued", len(jobs))
    return nil
}

func rewardTier(rank int) string {
    switch {
    case rank <= 10:
        return "legendary"
    case rank <= 100:
        return "epic"
    case rank <= 500:
        return "rare"
    default:
        return "common"
    }
}
```

> **Benefit**: Bulk add uses Redis pipeline — minimizes network roundtrips for batch enqueuing.

</tab>
<tab title="Node.js">

```typescript
import { Queue, Job } from "bullmq";

const queue = new Queue("season-rewards", {
  connection: { host: "localhost", port: 6379 },
});

interface Player {
  id: string;
  rank: number;
}

function rewardTier(rank: number): string {
  if (rank <= 10) return "legendary";
  if (rank <= 100) return "epic";
  if (rank <= 500) return "rare";
  return "common";
}

function rewardItems(tier: string): string[] {
  const items: Record<string, string[]> = {
    legendary: ["ITM2zP5xR7tT3M", "ITM9gW2eY4aA0T", "ITM5cS8aU0wW6P"],
    epic: ["ITM0hX3fZ5bB1U", "ITM6dT9bV1xX7Q"],
    rare: ["ITM0hX3fZ5bB1U", "ITM7eU0cW2yY8R"],
    common: ["ITM8fV1dX3zZ9S"],
  };
  return items[tier] ?? [];
}

async function distributeRewards(players: Player[]) {
  const rewardJobs = players.map((player) => ({
    name: "distribute-reward",
    data: {
      player_id: player.id,
      season: 12,
      rank: player.rank,
      reward_tier: rewardTier(player.rank),
      items: rewardItems(rewardTier(player.rank)),
    },
  }));

  try {
    const jobs: Job[] = await queue.addBulk(rewardJobs);
    console.log(`Season reset: ${jobs.length} reward jobs enqueued atomically`);
  } catch (err) {
    // No partial distribution -- all or nothing
    console.error(`Season reset failed: ${err}`);
    throw err;
  }
}
```

> **Benefit**: `queue.addBulk()` sends all jobs in a single pipeline — optimal for batch insertion.

</tab>
</tabs>

## 27.5. Performance

### Round-Trip Reduction

The primary performance benefit is eliminating per-job network round-trips. Each individual `add` call requires a full Redis round-trip (~1ms on localhost, 5-20ms over a network). Bulk addition collapses all jobs into a single round-trip.

```
Adding 1000 NPC spawn jobs individually:
  1000 Redis round-trips
  ~1000ms (1ms per job on localhost)
  Network overhead: High

Adding 1000 NPC spawn jobs in bulk:
  1 Redis round-trip
  ~10ms
  Network overhead: Minimal

Speedup: ~100x for 1000 jobs
```

### Throughput Comparison

| Method | Jobs/Second | Use Case |
|--------|-------------|----------|
| Individual `add/4` | ~1,000 | Real-time single jobs (player actions, chat) |
| `add_bulk/3` (default) | ~20,000 | Batch NPC spawns, tournament seeding |
| `add_bulk/3` + connection pool | ~60,000 | Season resets, large-scale imports |

### Benchmark: NPC Wave Spawning

<tabs>
<tab title="Elixir">

```elixir
defmodule Arena.Benchmark do
  def compare_add_methods(job_count) do
    jobs = for i <- 1..job_count do
      {"spawn-npc", %{"npc_id" => EchoData.build_branded_id("NPC"), "zone" => "arena"}, []}
    end

    # Individual adds
    {individual_time, _} = :timer.tc(fn ->
      Enum.each(jobs, fn {name, data, opts} ->
        EchoMQ.Queue.add("bench-queue", name, data,
          Keyword.merge(opts, connection: :arena_redis))
      end)
    end)

    # Bulk add
    {bulk_time, _} = :timer.tc(fn ->
      EchoMQ.Queue.add_bulk("bench-queue", jobs, connection: :arena_redis)
    end)

    IO.puts("Individual: #{div(individual_time, 1000)}ms")
    IO.puts("Bulk:       #{div(bulk_time, 1000)}ms")
    IO.puts("Speedup:    #{Float.round(individual_time / bulk_time, 1)}x")
  end
end

# Arena.Benchmark.compare_add_methods(1000)
# Individual: 1023ms
# Bulk:       11ms
# Speedup:    93.0x
```

> **Benefit**: Pipeline-based bulk operations send multiple commands in a single Redis roundtrip.

</tab>
<tab title="Go">

```go
// Benchmark: individual vs pipeline bulk
func benchmarkAddMethods(ctx context.Context, rdb *redis.Client, jobCount int) {
    // Individual adds
    start := time.Now()
    for i := 0; i < jobCount; i++ {
        rdb.HSet(ctx,
            fmt.Sprintf("bull:bench-queue:bench-%d", i),
            "name", "spawn-npc",
            "data", fmt.Sprintf(`{"npc_id":"%s"}`, echomq.GenerateBrandedID("NPC")),
            "timestamp", time.Now().UnixMilli(),
        )
    }
    individualMs := time.Since(start).Milliseconds()

    // Pipeline bulk
    start = time.Now()
    pipe := rdb.Pipeline()
    for i := 0; i < jobCount; i++ {
        pipe.HSet(ctx,
            fmt.Sprintf("bull:bench-queue:bulk-%d", i),
            "name", "spawn-npc",
            "data", fmt.Sprintf(`{"npc_id":"%s"}`, echomq.GenerateBrandedID("NPC")),
            "timestamp", time.Now().UnixMilli(),
        )
    }
    pipe.Exec(ctx)
    bulkMs := time.Since(start).Milliseconds()

    fmt.Printf("Individual: %dms\n", individualMs)
    fmt.Printf("Pipeline:   %dms\n", bulkMs)
    fmt.Printf("Speedup:    %.1fx\n", float64(individualMs)/float64(bulkMs))
}

// benchmarkAddMethods(ctx, rdb, 1000)
// Individual: 987ms
// Pipeline:   9ms
// Speedup:    109.7x
```

> **Benefit**: Bulk add uses Redis pipeline — minimizes network roundtrips for batch enqueuing.

</tab>
<tab title="Node.js">

```typescript
import { Queue } from "bullmq";

const queue = new Queue("bench-queue", {
  connection: { host: "localhost", port: 6379 },
});

async function benchmarkAddMethods(jobCount: number) {
  // Individual adds
  const individualStart = Date.now();
  for (let i = 0; i < jobCount; i++) {
    await queue.add("spawn-npc", { npc_id: generateBrandedId("NPC"), zone: "arena" });
  }
  const individualMs = Date.now() - individualStart;

  // Bulk add
  const jobs = Array.from({ length: jobCount }, (_, i) => ({
    name: "spawn-npc",
    data: { npc_id: generateBrandedId("NPC"), zone: "arena" },
  }));

  const bulkStart = Date.now();
  await queue.addBulk(jobs);
  const bulkMs = Date.now() - bulkStart;

  console.log(`Individual: ${individualMs}ms`);
  console.log(`Bulk:       ${bulkMs}ms`);
  console.log(`Speedup:    ${(individualMs / bulkMs).toFixed(1)}x`);
}

// benchmarkAddMethods(1000)
// Individual: 1045ms
// Bulk:       12ms
// Speedup:    87.1x
```

> **Benefit**: `queue.addBulk()` sends all jobs in a single pipeline — optimal for batch insertion.

</tab>
</tabs>

## 27.6. Chunk Size and Connection Pools

For very large batches (10,000+ jobs), EchoMQ splits the work into chunks and optionally processes them in parallel across multiple Redis connections. This prevents a single massive pipeline from blocking the Redis event loop.

<tabs>
<tab title="Elixir">

```elixir
# Season reset for 50,000 players: chunked with connection pool
defmodule Arena.MassDistribution do
  @chunk_size 500
  @pool_size 8

  def setup_pool do
    for i <- 1..@pool_size do
      name = :"redis_pool_#{i}"
      {:ok, _} = Redix.start_link(host: "localhost", name: name)
      name
    end
  end

  def distribute_to_all(players) do
    pool = setup_pool()

    jobs = Enum.map(players, fn player ->
      {"season-reward", %{
        "player_id" => player.id,
        "rank" => player.rank
      }, []}
    end)

    {:ok, results} = EchoMQ.Queue.add_bulk("season-rewards", jobs,
      connection: :arena_redis,
      connection_pool: pool,
      chunk_size: @chunk_size
    )

    IO.puts("Distributed rewards to #{length(results)} players")
    IO.puts("Chunks: #{ceil(length(jobs) / @chunk_size)}")
    IO.puts("Pool connections: #{@pool_size}")
  end
end

# 50,000 players: 100 chunks x 500 jobs, 8 parallel connections
# Throughput: ~60,000 jobs/sec
```

| Option | Default | Description |
|--------|---------|-------------|
| `:chunk_size` | `100` | Jobs per Redis pipeline command |
| `:connection_pool` | `nil` | List of Redix connection names for parallel processing |
| `:pipeline` | `true` | Set `false` for sequential mode (debugging) |

> **Benefit**: Pipeline-based bulk operations send multiple commands in a single Redis roundtrip.

</tab>
<tab title="Go">

```go
// Chunked pipeline with goroutine parallelism
func addBulkChunked(ctx context.Context, rdb *redis.Client, queue string, jobs []BulkJob, chunkSize int, poolSize int) error {
    chunks := splitIntoChunks(jobs, chunkSize)
    errCh := make(chan error, len(chunks))
    sem := make(chan struct{}, poolSize) // Limit concurrent pipelines

    for _, chunk := range chunks {
        sem <- struct{}{} // Acquire semaphore
        go func(c []BulkJob) {
            defer func() { <-sem }() // Release semaphore
            errCh <- addBulkWorkaround(ctx, rdb, queue, toBulkMaps(c))
        }(chunk)
    }

    // Collect results
    for range chunks {
        if err := <-errCh; err != nil {
            return err
        }
    }
    return nil
}

func splitIntoChunks(jobs []BulkJob, size int) [][]BulkJob {
    var chunks [][]BulkJob
    for i := 0; i < len(jobs); i += size {
        end := i + size
        if end > len(jobs) {
            end = len(jobs)
        }
        chunks = append(chunks, jobs[i:end])
    }
    return chunks
}

// Usage: 50,000 jobs, 500 per chunk, 8 parallel goroutines
// addBulkChunked(ctx, rdb, "season-rewards", jobs, 500, 8)
```

> **Benefit**: Bulk add uses Redis pipeline — minimizes network roundtrips for batch enqueuing.

</tab>
<tab title="Node.js">

```typescript
import { Queue, Job } from "bullmq";

const CHUNK_SIZE = 500;
const POOL_SIZE = 8;

async function addBulkChunked(
  queueName: string,
  jobs: Array<{ name: string; data: any; opts?: any }>,
) {
  // Split into chunks
  const chunks: typeof jobs[] = [];
  for (let i = 0; i < jobs.length; i += CHUNK_SIZE) {
    chunks.push(jobs.slice(i, i + CHUNK_SIZE));
  }

  // Process chunks in parallel batches (POOL_SIZE at a time)
  const queue = new Queue(queueName, {
    connection: { host: "localhost", port: 6379 },
  });

  const results: Job[] = [];
  for (let i = 0; i < chunks.length; i += POOL_SIZE) {
    const batch = chunks.slice(i, i + POOL_SIZE);
    const batchResults = await Promise.all(
      batch.map((chunk) => queue.addBulk(chunk)),
    );
    results.push(...batchResults.flat());
  }

  console.log(`Added ${results.length} jobs in ${chunks.length} chunks`);
  await queue.close();
  return results;
}

// 50,000 jobs: 100 chunks x 500 jobs, 8 parallel addBulk calls
```

> **Benefit**: `Promise.allSettled` handles partial batch failures gracefully without short-circuiting.

</tab>
</tabs>

## 27.7. Job Type Optimization

EchoMQ internally separates jobs by type within a batch and applies different insertion strategies. Standard jobs (no delay or priority) use transactional pipelining for maximum throughput. Delayed and prioritized jobs fall back to sequential processing because they require sorted set operations with computed scores.

| Job Type | Redis Target | Optimization |
|----------|-------------|--------------|
| Standard (no delay, no priority) | `bull:{queue}:wait` | Transactional pipelining |
| Delayed | `bull:{queue}:delayed` | Sequential (score = target timestamp) |
| Prioritized | `bull:{queue}:priority` | Sequential (score = priority * 0x100000000 + counter) |

<tabs>
<tab title="Elixir">

```elixir
# Mixed job types in a single batch: the queue optimizes each type internally
mixed_jobs = [
  # Standard jobs: pipelined together (fastest)
  {"spawn-npc", %{"npc_id" => "NPC1wL4gG6jJ2B"}, []},
  {"spawn-npc", %{"npc_id" => "NPC2xM5hH7kK3C"}, []},
  {"spawn-npc", %{"npc_id" => "NPC3yN6iI8lL4D"}, []},

  # Delayed job: NPC boss spawns 60 seconds after grunts
  {"spawn-npc", %{"npc_id" => "NPC7uJ2cE4hX0Z", "type" => "boss"}, [delay: 60_000]},

  # Prioritized job: mini-boss spawns before remaining grunts
  {"spawn-npc", %{"npc_id" => "NPC0vK3fF5iI1A"}, [priority: 1]},
]

# EchoMQ internally splits: 3 standard (pipelined) + 1 delayed + 1 prioritized (sequential)
{:ok, spawned} = EchoMQ.Queue.add_bulk("npc-spawns", mixed_jobs,
  connection: :arena_redis
)
```

> **Benefit**: `Enum.chunk_every` pipelines provide natural batch decomposition with backpressure.

</tab>
<tab title="Go">

```go
// Mixed job types require routing to different sorted sets
mixedJobs := []BulkJob{
    // Standard: goes to bull:{queue}:wait
    {Name: "spawn-npc", Data: map[string]interface{}{"npc_id": "NPC1wL4gG6jJ2B"}},
    {Name: "spawn-npc", Data: map[string]interface{}{"npc_id": "NPC2xM5hH7kK3C"}},

    // Delayed: goes to bull:{queue}:delayed with score = now + 60000
    {Name: "spawn-npc", Data: map[string]interface{}{"npc_id": "NPC7uJ2cE4hX0Z"}, Delay: 60000},

    // Prioritized: goes to bull:{queue}:priority with composite score
    {Name: "spawn-npc", Data: map[string]interface{}{"npc_id": "NPC0vK3fF5iI1A"}, Priority: 1},
}

err := addBulkWithOptions(ctx, rdb, "npc-spawns", mixedJobs)
```

> **Benefit**: Priority encoding uses composite score combining priority level and insertion order.

</tab>
<tab title="Node.js">

```typescript
import { Queue } from "bullmq";

const queue = new Queue("npc-spawns", {
  connection: { host: "localhost", port: 6379 },
});

// Mixed job types in a single addBulk call
const mixedJobs = [
  // Standard jobs
  { name: "spawn-npc", data: { npc_id: "NPC1wL4gG6jJ2B" } },
  { name: "spawn-npc", data: { npc_id: "NPC2xM5hH7kK3C" } },
  { name: "spawn-npc", data: { npc_id: "NPC3yN6iI8lL4D" } },

  // Delayed: boss spawns 60 seconds after grunts
  {
    name: "spawn-npc",
    data: { npc_id: "NPC7uJ2cE4hX0Z", type: "boss" },
    opts: { delay: 60_000 },
  },

  // Prioritized: mini-boss spawns before remaining grunts
  {
    name: "spawn-npc",
    data: { npc_id: "NPC0vK3fF5iI1A" },
    opts: { priority: 1 },
  },
];

await queue.addBulk(mixedJobs);
```

> **Benefit**: Priority values mirror BullMQ's proven sorted set implementation.

</tab>
</tabs>

## 27.8. Error Handling

### Partial Failure Detection

If some jobs in a batch fail (e.g., validation errors or Redis script failures), EchoMQ returns detailed per-job results so you can identify and retry only the failures.

<tabs>
<tab title="Elixir">

```elixir
defmodule Arena.BulkSpawner do
  @moduledoc "Bulk NPC spawner with partial failure recovery"

  def spawn_wave(zone, npc_specs) do
    jobs = Enum.map(npc_specs, fn spec ->
      {"spawn-npc", %{
        "npc_id" => spec.id,
        "zone" => zone,
        "level" => spec.level,
        "archetype" => spec.archetype
      }, []}
    end)

    case EchoMQ.Queue.add_bulk("npc-spawns", jobs, connection: :arena_redis) do
      {:ok, added_jobs} ->
        Logger.info("[#{zone}] Spawned #{length(added_jobs)} NPCs")
        {:ok, added_jobs}

      {:error, {:partial_failure, results}} ->
        {successes, failures} = Enum.split_with(results, fn
          {:ok, _} -> true
          {:error, _} -> false
        end)

        Logger.warning(
          "[#{zone}] Partial spawn: #{length(successes)} ok, #{length(failures)} failed"
        )

        # Retry failed jobs
        failed_jobs = extract_failed_jobs(jobs, results)
        retry_spawn(zone, failed_jobs)

      {:error, reason} ->
        Logger.error("[#{zone}] Complete spawn failure: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp extract_failed_jobs(original_jobs, results) do
    Enum.zip(original_jobs, results)
    |> Enum.filter(fn {_job, result} -> match?({:error, _}, result) end)
    |> Enum.map(fn {job, _} -> job end)
  end

  defp retry_spawn(zone, failed_jobs) do
    Logger.info("[#{zone}] Retrying #{length(failed_jobs)} failed spawns")
    EchoMQ.Queue.add_bulk("npc-spawns", failed_jobs, connection: :arena_redis)
  end
end
```

> **Benefit**: Pipeline-based bulk operations send multiple commands in a single Redis roundtrip.

</tab>
<tab title="Go">

```go
// Partial failure handling with pipeline
func spawnWaveWithRetry(ctx context.Context, rdb *redis.Client, zone string, specs []NPCSpec) error {
    jobs := make([]map[string]interface{}, len(specs))
    for i, spec := range specs {
        jobs[i] = map[string]interface{}{
            "name": "spawn-npc",
            "data": map[string]interface{}{
                "npc_id": spec.ID, "zone": zone,
                "level": spec.Level, "archetype": spec.Archetype,
            },
        }
    }

    err := addBulkWorkaround(ctx, rdb, "npc-spawns", jobs)
    if err != nil {
        // Redis pipeline returns all-or-nothing on connection failure.
        // For per-command errors, inspect individual pipeline results.
        log.Printf("[%s] Spawn failed: %v — retrying individually", zone, err)

        var retryFailed int
        for _, job := range jobs {
            if rerr := addSingleJob(ctx, rdb, "npc-spawns", job); rerr != nil {
                retryFailed++
            }
        }

        if retryFailed > 0 {
            return fmt.Errorf("%d NPCs failed to spawn after retry", retryFailed)
        }
    }
    return nil
}
```

> **Benefit**: Bulk add uses Redis pipeline — minimizes network roundtrips for batch enqueuing.

</tab>
<tab title="Node.js">

```typescript
import { Queue, Job } from "bullmq";

const queue = new Queue("npc-spawns", {
  connection: { host: "localhost", port: 6379 },
});

interface NPCSpec {
  id: string;
  zone: string;
  level: number;
  archetype: string;
}

async function spawnWave(zone: string, specs: NPCSpec[]) {
  const jobs = specs.map((spec) => ({
    name: "spawn-npc",
    data: {
      npc_id: spec.id,
      zone,
      level: spec.level,
      archetype: spec.archetype,
    },
  }));

  try {
    const added: Job[] = await queue.addBulk(jobs);
    console.log(`[${zone}] Spawned ${added.length} NPCs`);
    return added;
  } catch (err) {
    console.error(`[${zone}] Bulk spawn failed: ${err}`);

    // Retry individually to identify specific failures
    const results = await Promise.allSettled(
      jobs.map((job) => queue.add(job.name, job.data)),
    );

    const failed = results.filter((r) => r.status === "rejected");
    if (failed.length > 0) {
      console.error(`[${zone}] ${failed.length} NPCs failed after retry`);
    }

    return results
      .filter((r) => r.status === "fulfilled")
      .map((r) => (r as PromiseFulfilledResult<Job>).value);
  }
}
```

> **Benefit**: `queue.addBulk()` sends all jobs in a single pipeline — optimal for batch insertion.

</tab>
</tabs>

### Validation Before Bulk Add

Validate all jobs before sending them to Redis. This catches format errors early and avoids wasting a round-trip on invalid data.

<tabs>
<tab title="Elixir">

```elixir
defmodule Arena.ValidatedBulk do
  @valid_archetypes ~w(warrior mage archer healer tank assassin)

  def spawn_validated_wave(zone, npc_specs) do
    case validate_specs(npc_specs) do
      {:ok, jobs} ->
        EchoMQ.Queue.add_bulk("npc-spawns", jobs, connection: :arena_redis)

      {:error, invalid} ->
        Logger.error("Invalid NPC specs: #{inspect(invalid)}")
        {:error, {:validation_failed, invalid}}
    end
  end

  defp validate_specs(specs) do
    {valid, invalid} = Enum.split_with(specs, &valid_spec?/1)

    if Enum.empty?(invalid) do
      jobs = Enum.map(valid, fn spec ->
        {"spawn-npc", %{
          "npc_id" => spec.id,
          "zone" => spec.zone,
          "level" => spec.level,
          "archetype" => spec.archetype
        }, []}
      end)
      {:ok, jobs}
    else
      {:error, invalid}
    end
  end

  defp valid_spec?(%{id: id, level: level, archetype: arch})
       when is_binary(id) and is_integer(level) and level in 1..100 do
    arch in @valid_archetypes
  end
  defp valid_spec?(_), do: false
end
```

> **Benefit**: Pipeline-based bulk operations send multiple commands in a single Redis roundtrip.

</tab>
<tab title="Go">

```go
var validArchetypes = map[string]bool{
    "warrior": true, "mage": true, "archer": true,
    "healer": true, "tank": true, "assassin": true,
}

func validateAndSpawn(ctx context.Context, rdb *redis.Client, zone string, specs []NPCSpec) error {
    var invalid []NPCSpec
    var valid []map[string]interface{}

    for _, spec := range specs {
        if spec.ID == "" || spec.Level < 1 || spec.Level > 100 || !validArchetypes[spec.Archetype] {
            invalid = append(invalid, spec)
            continue
        }
        valid = append(valid, map[string]interface{}{
            "name": "spawn-npc",
            "data": map[string]interface{}{
                "npc_id": spec.ID, "zone": zone,
                "level": spec.Level, "archetype": spec.Archetype,
            },
        })
    }

    if len(invalid) > 0 {
        return fmt.Errorf("validation failed: %d invalid specs", len(invalid))
    }

    return addBulkWorkaround(ctx, rdb, "npc-spawns", valid)
}
```

> **Benefit**: Bulk add uses Redis pipeline — minimizes network roundtrips for batch enqueuing.

</tab>
<tab title="Node.js">

```typescript
const VALID_ARCHETYPES = new Set(["warrior", "mage", "archer", "healer", "tank", "assassin"]);

function validateSpecs(specs: NPCSpec[]): { valid: NPCSpec[]; invalid: NPCSpec[] } {
  const valid: NPCSpec[] = [];
  const invalid: NPCSpec[] = [];

  for (const spec of specs) {
    if (!spec.id || spec.level < 1 || spec.level > 100 || !VALID_ARCHETYPES.has(spec.archetype)) {
      invalid.push(spec);
    } else {
      valid.push(spec);
    }
  }

  return { valid, invalid };
}

async function spawnValidatedWave(zone: string, specs: NPCSpec[]) {
  const { valid, invalid } = validateSpecs(specs);

  if (invalid.length > 0) {
    console.error(`Validation failed: ${invalid.length} invalid specs`);
    throw new Error(`${invalid.length} invalid NPC specs`);
  }

  const jobs = valid.map((spec) => ({
    name: "spawn-npc",
    data: { npc_id: spec.id, zone, level: spec.level, archetype: spec.archetype },
  }));

  return queue.addBulk(jobs);
}
```

> **Benefit**: `queue.addBulk()` sends all jobs in a single pipeline — optimal for batch insertion.

</tab>
</tabs>

## 27.9. Flow Bulk Operations

Flows (parent-child job trees) also support bulk addition via `FlowProducer.addBulk`. This enqueues multiple complete flow trees in a single operation, each with its own parent and children.

<tabs>
<tab title="Elixir">

```elixir
# Bulk tournament match flows: each match has validate -> process -> record stages
match_flows = for match_id <- 1..32 do
  %{
    name: "record-result",
    queue_name: "match-results",
    data: %{"match_id" => EchoData.build_branded_id("MTH")},
    children: [
      %{
        name: "process-match",
        queue_name: "match-processing",
        data: %{"match_id" => EchoData.build_branded_id("MTH")},
        children: [
          %{
            name: "validate-players",
            queue_name: "match-validation",
            data: %{
              "match_id" => EchoData.build_branded_id("MTH"),
              "player_a" => EchoData.build_branded_id("PLR"),
              "player_b" => EchoData.build_branded_id("PLR")
            }
          }
        ]
      }
    ]
  }
end

{:ok, trees} = EchoMQ.FlowProducer.add_bulk(match_flows, connection: :arena_redis)
IO.puts("Created #{length(trees)} match flow trees")
```

> **Benefit**: Flow trees compose naturally with OTP supervision — parent failure propagates to children.

</tab>
<tab title="Go">

> **Go Gap: Flow Bulk Operations**
> - **Feature**: `FlowProducer.AddBulk` for batch flow tree creation
> - **Reason**: Flow producer is not yet implemented in the Go client
> - **Workaround**: Create flow trees individually via raw Redis commands, or delegate flow creation to Elixir/Node.js workers
> - **Reference**: [PROTOCOL-GAPS.md](PROTOCOL-GAPS.md)

```go
// Flow bulk operations are not available in Go.
// Delegate to Elixir or Node.js for flow-based batch operations.
//
// Alternative: enqueue a single "create-flows" job processed by
// an Elixir/Node.js worker that calls FlowProducer.addBulk:
//
//   rdb.HSet(ctx, "bull:flow-orchestrator:create-match-flows",
//       "name", "create-flows",
//       "data", `{"round": 1, "match_count": 32}`,
//   )
```

> **Benefit**: Slice-based batching with goroutine fan-out provides predictable memory usage.

</tab>
<tab title="Node.js">

```typescript
import { FlowProducer, FlowJob } from "bullmq";

const flowProducer = new FlowProducer({
  connection: { host: "localhost", port: 6379 },
});

// Bulk tournament match flows
const matchFlows: FlowJob[] = Array.from({ length: 32 }, (_, i) => {
  const matchId = generateBrandedId('MTH');
  return {
    name: "record-result",
    queueName: "match-results",
    data: { match_id: matchId },
    children: [
      {
        name: "process-match",
        queueName: "match-processing",
        data: { match_id: matchId },
        children: [
          {
            name: "validate-players",
            queueName: "match-validation",
            data: {
              match_id: matchId,
              player_a: generateBrandedId('PLR'),
              player_b: generateBrandedId('PLR'),
            },
          },
        ],
      },
    ],
  };
});

const trees = await flowProducer.addBulk(matchFlows);
console.log(`Created ${trees.length} match flow trees`);
```

> **Benefit**: FlowProducer class provides the reference implementation for complex job DAGs.

</tab>
</tabs>

## 27.10. Patterns

### Progress Tracking for Large Batches

Track progress when processing very large batches by chunking and reporting after each chunk completes.

<tabs>
<tab title="Elixir">

```elixir
defmodule Arena.BulkImporter do
  @moduledoc "Import player data with progress tracking"

  def import_with_progress(player_records, opts \\ []) do
    chunk_size = Keyword.get(opts, :chunk_size, 500)
    total = length(player_records)

    jobs = Enum.map(player_records, fn record ->
      {"import-player", %{
        "player_id" => record.id,
        "name" => record.name,
        "stats" => record.stats
      }, []}
    end)

    jobs
    |> Enum.chunk_every(chunk_size)
    |> Enum.with_index(1)
    |> Enum.reduce({:ok, []}, fn {chunk, index}, {:ok, acc} ->
      case EchoMQ.Queue.add_bulk("player-import", chunk,
        connection: :arena_redis
      ) do
        {:ok, added} ->
          progress = min(index * chunk_size, total)
          pct = Float.round(progress / total * 100, 1)
          Logger.info("Import progress: #{progress}/#{total} (#{pct}%)")
          {:ok, acc ++ added}

        error ->
          error
      end
    end)
  end
end

# Arena.BulkImporter.import_with_progress(records, chunk_size: 1000)
# Import progress: 1000/5000 (20.0%)
# Import progress: 2000/5000 (40.0%)
# Import progress: 3000/5000 (60.0%)
# Import progress: 4000/5000 (80.0%)
# Import progress: 5000/5000 (100.0%)
```

> **Benefit**: `Enum.chunk_every` pipelines provide natural batch decomposition with backpressure.

</tab>
<tab title="Go">

```go
func importWithProgress(ctx context.Context, rdb *redis.Client, records []PlayerRecord, chunkSize int) error {
    total := len(records)
    for i := 0; i < total; i += chunkSize {
        end := i + chunkSize
        if end > total {
            end = total
        }

        chunk := records[i:end]
        jobs := make([]map[string]interface{}, len(chunk))
        for j, rec := range chunk {
            jobs[j] = map[string]interface{}{
                "name": "import-player",
                "data": map[string]interface{}{
                    "player_id": rec.ID, "name": rec.Name,
                },
            }
        }

        if err := addBulkWorkaround(ctx, rdb, "player-import", jobs); err != nil {
            return fmt.Errorf("chunk %d failed: %w", i/chunkSize+1, err)
        }

        progress := end
        pct := float64(progress) / float64(total) * 100
        fmt.Printf("Import progress: %d/%d (%.1f%%)\n", progress, total, pct)
    }
    return nil
}
```

> **Benefit**: Slice-based batching with goroutine fan-out provides predictable memory usage.

</tab>
<tab title="Node.js">

```typescript
import { Queue, Job } from "bullmq";

const queue = new Queue("player-import", {
  connection: { host: "localhost", port: 6379 },
});

interface PlayerRecord {
  id: string;
  name: string;
  stats: Record<string, number>;
}

async function importWithProgress(records: PlayerRecord[], chunkSize = 500) {
  const total = records.length;
  const results: Job[] = [];

  for (let i = 0; i < total; i += chunkSize) {
    const chunk = records.slice(i, i + chunkSize).map((rec) => ({
      name: "import-player",
      data: { player_id: rec.id, name: rec.name, stats: rec.stats },
    }));

    const added = await queue.addBulk(chunk);
    results.push(...added);

    const progress = Math.min(i + chunkSize, total);
    const pct = ((progress / total) * 100).toFixed(1);
    console.log(`Import progress: ${progress}/${total} (${pct}%)`);
  }

  return results;
}
```

> **Benefit**: `Promise.allSettled` handles partial batch failures gracefully without short-circuiting.

</tab>
</tabs>

## 27.11. Cross-Language Comparison

| Feature | Elixir | Go | Node.js |
|---------|--------|-----|---------|
| Bulk add API | `Queue.add_bulk/3` | Not implemented | `queue.addBulk()` |
| Job format | `{name, data, opts}` tuple | N/A (pipeline workaround) | `{name, data, opts}` object |
| Atomicity | Redis `MULTI`/`EXEC` | Pipeline (no Lua script) | Redis `MULTI`/`EXEC` |
| Connection pool | `:connection_pool` option | Manual goroutine pool | Manual `Promise.all` |
| Chunk size | `:chunk_size` option (default 100) | Manual chunking | Manual chunking |
| Flow bulk | `FlowProducer.add_bulk/2` | Not implemented | `flowProducer.addBulk()` |
| Progress callback | Manual via `Enum.chunk_every` | Manual via loop | Manual via loop |
| Pipelining toggle | `:pipeline` option | Always pipelined | Always pipelined |

All three runtimes share the same Redis key format. Jobs added via Elixir `add_bulk` are immediately visible to Go and Node.js workers, and vice versa. The wire format is identical: job data stored in `bull:{queue}:{jobId}` hashes, job ordering in `bull:{queue}:wait` (or `delayed`/`priority`) sorted sets.

---

*Previous: [Priorities](ch26-priorities.md) | Next: [Groups](ch28-groups.md)*
