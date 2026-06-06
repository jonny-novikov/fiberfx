# Chapter 28. Groups

Groups provide fair job distribution across tenants, guilds, or player categories within a single queue. Instead of creating separate queues per tenant, you assign a group ID to each job. The queue processes groups in round-robin order, preventing any single group from monopolizing worker capacity. In the Fireheadz Arena, groups enable per-guild job fairness (so a guild spamming matchmaking requests cannot starve other guilds), arena instance isolation (each instance processes independently), and multi-region shard groups for world synchronization.

> **Pro Feature Notice:** Groups is a BullMQ Pro feature (`@taskforcesh/bullmq-pro`). The Elixir client has a `group_key` type spec for wire compatibility but no runtime group enforcement. The Go client has no group support. Node.js Pro (`QueuePro`/`WorkerPro`) is the primary implementation. This chapter documents the full feature set with Elixir workaround patterns and Go gap documentation.

## 28.1. The Problem Groups Solve

Without groups, a single tenant can flood the queue and starve everyone else. Consider a game server where guilds submit matchmaking requests:

```
Standard Queue (no groups):
+------------------------------------------------------------+
| guild_A | guild_A | guild_A | guild_A | ... | guild_B | guild_C |
+------------------------------------------------------------+
              ^
              Guild A submitted 5000 matchmaking jobs.
              Guilds B and C wait behind all of them.
```

With groups, the queue distributes processing time fairly via round-robin:

```
Grouped Queue (round-robin):
+-----------------------------------------------------------+
| guild_A | guild_B | guild_C | guild_A | guild_B | guild_A |
+---------+---------+---------+---------+---------+---------+
|  Job 1  |  Job 1  |  Job 1  |  Job 2  |  Job 2  |  Job 3 |
|  Job 2  |  Job 2  |         |  Job 3  |         |  ...   |
|  ...    |         |         |  ...    |         |        |
+---------+---------+---------+---------+---------+---------+

Each guild gets equal processing time regardless of queue depth.
```

## 28.2. Adding Jobs to Groups

Assign a group by setting the `group` option when adding a job. The group ID is an arbitrary string that identifies the tenant, guild, or category.

<tabs>
<tab title="Elixir">

```elixir
# Per-guild matchmaking: fair processing across all guilds
defmodule Arena.GuildMatchmaking do
  @moduledoc "Submit matchmaking requests with guild-based grouping"

  def queue_match(player_id, guild_id, rank) do
    EchoMQ.Queue.add("matchmaking", "find-match", %{
      "player_id" => player_id,
      "guild_id" => guild_id,
      "rank" => rank,
      "queued_at" => System.system_time(:millisecond)
    },
      connection: :arena_redis,
      group: %{id: "guild_#{guild_id}"}
    )
  end
end

# Guild "dragons" submits 500 matchmaking requests
for i <- 1..500 do
  Arena.GuildMatchmaking.queue_match(EchoData.build_branded_id("PLR", EchoData.Snowflake.generate()), "dragons", 1500 + i)
end

# Guild "phoenix" submits 10 matchmaking requests
for i <- 1..10 do
  Arena.GuildMatchmaking.queue_match(EchoData.build_branded_id("PLR", EchoData.Snowflake.generate()), "phoenix", 1800 + i)
end

# With groups: "dragons" and "phoenix" are processed in round-robin.
# Without groups: all 500 dragon requests would process before any phoenix request.
```

The `group: %{id: string}` option writes the group ID into the job's options hash in Redis. When a Node.js Pro worker processes this queue, it reads the group ID and applies round-robin scheduling across all active groups.

> **Elixir Limitation:** The Elixir worker does not enforce group-level scheduling natively. The `group` option is written to Redis for compatibility with Node.js Pro workers. For Elixir-only deployments, see the "Elixir Workaround Patterns" section below.

> **Benefit**: GenServer-based schedulers integrate with supervision — restarts guarantee schedule continuity.

</tab>
<tab title="Go">

> **Go Gap: Job Groups**
> - **Feature**: Group-based fair scheduling (`group.id` option)
> - **Reason**: Not yet implemented in the Go client. Groups require Pro worker scheduling logic.
> - **Workaround**: Write the group option into the job hash manually (for Node.js Pro worker consumption), or use separate queues per group with dedicated Go workers.
> - **Reference**: [PROTOCOL-GAPS.md](PROTOCOL-GAPS.md)

```go
// Workaround: write group ID into job options for Node.js Pro consumption
func addJobWithGroup(ctx context.Context, rdb *redis.Client, queue, name, groupID string, data map[string]interface{}) error {
    prefix := "bull"
    now := time.Now().UnixMilli()
    jobID := fmt.Sprintf("%d-%s", now, name)

    dataJSON, _ := json.Marshal(data)
    optsJSON := fmt.Sprintf(`{"group":{"id":"%s"}}`, groupID)

    key := fmt.Sprintf("%s:%s:%s", prefix, queue, jobID)
    pipe := rdb.Pipeline()
    pipe.HSet(ctx, key, map[string]interface{}{
        "name":      name,
        "data":      string(dataJSON),
        "opts":      optsJSON,
        "timestamp": now,
    })
    pipe.ZAdd(ctx, fmt.Sprintf("%s:%s:wait", prefix, queue), redis.Z{
        Score:  float64(now),
        Member: jobID,
    })
    _, err := pipe.Exec(ctx)
    return err
}

// Usage: enqueue grouped jobs for Node.js Pro worker processing
addJobWithGroup(ctx, rdb, "matchmaking", "find-match", "guild_dragons",
    map[string]interface{}{"player_id": "PLRdrgn01J2vQ1", "rank": 1500})
addJobWithGroup(ctx, rdb, "matchmaking", "find-match", "guild_phoenix",
    map[string]interface{}{"player_id": "PLRphnx01L4qP8", "rank": 1800})
```

This writes the group ID into the job hash. A Node.js Pro worker reading this queue will apply group-level round-robin. Go workers on the same queue will ignore the group and process jobs in standard FIFO order.

> **Tradeoff**: Go has no built-in cron — scheduler must use `time.Ticker` or external cron library.

</tab>
<tab title="Node.js">

```typescript
import { QueuePro, WorkerPro } from "@taskforcesh/bullmq-pro";

const queue = new QueuePro("matchmaking", {
  connection: { host: "localhost", port: 6379 },
});

// Per-guild matchmaking with group-based fair scheduling
async function queueMatch(playerId: string, guildId: string, rank: number) {
  await queue.add("find-match", {
    player_id: playerId,
    guild_id: guildId,
    rank,
    queued_at: Date.now(),
  }, {
    group: { id: `guild_${guildId}` },
  });
}

// Guild "dragons" submits 500 requests, "phoenix" submits 10
for (let i = 0; i < 500; i++) {
  await queueMatch(generateBrandedId('PLR'), "dragons", 1500 + i);
}
for (let i = 0; i < 10; i++) {
  await queueMatch(generateBrandedId('PLR'), "phoenix", 1800 + i);
}

// WorkerPro processes groups in round-robin: dragons, phoenix, dragons, phoenix, ...
const worker = new WorkerPro("matchmaking",
  async (job) => {
    const { player_id, guild_id, rank } = job.data;
    return await findMatch(player_id, rank);
  },
  { connection: { host: "localhost", port: 6379 } }
);
```

> **Benefit**: `upsertJobScheduler` is Redis-persisted and idempotent — safe across process restarts.

</tab>
</tabs>

## 28.3. Group Concurrency

Limit how many jobs run simultaneously per group. This prevents a single group from consuming all worker threads even when the queue has capacity.

<tabs>
<tab title="Elixir">

```elixir
# Elixir does not enforce group concurrency natively.
# Write grouped jobs for Node.js Pro worker consumption.

# For Elixir-only deployments, simulate group concurrency with
# a Redis-based semaphore per group:
defmodule Arena.GroupConcurrency do
  @max_per_group 3

  def acquire_slot(group_id) do
    key = "arena:group_concurrency:#{group_id}"

    case Redix.command(:arena_redis, ["INCR", key]) do
      {:ok, count} when count <= @max_per_group ->
        # Set expiry as safety net (in case worker crashes)
        if count == 1, do: Redix.command(:arena_redis, ["EXPIRE", key, 300])
        :ok

      {:ok, _count} ->
        Redix.command(:arena_redis, ["DECR", key])
        {:error, :group_limit_reached}
    end
  end

  def release_slot(group_id) do
    key = "arena:group_concurrency:#{group_id}"
    Redix.command(:arena_redis, ["DECR", key])
  end
end

# In worker processor:
def process(%EchoMQ.Job{data: %{"guild_id" => guild_id}} = job) do
  case Arena.GroupConcurrency.acquire_slot(guild_id) do
    :ok ->
      try do
        do_matchmaking(job)
      after
        Arena.GroupConcurrency.release_slot(guild_id)
      end

    {:error, :group_limit_reached} ->
      # Re-delay the job and try again later
      {:delay, 1_000}
  end
end
```

> **Benefit**: BEAM processes provide true preemptive concurrency — one slow job cannot starve others.

</tab>
<tab title="Go">

> **Go Gap: Group Concurrency**
> - **Feature**: Per-group concurrency limiting (`group.concurrency` option)
> - **Reason**: Group scheduling requires Pro worker logic not present in Go
> - **Workaround**: Use a Redis-based semaphore per group in the processor (same pattern as Elixir workaround above)
> - **Reference**: [PROTOCOL-GAPS.md](PROTOCOL-GAPS.md)

```go
// Redis-based group concurrency semaphore
const maxPerGroup = 3

func acquireGroupSlot(ctx context.Context, rdb *redis.Client, groupID string) (bool, error) {
    key := fmt.Sprintf("arena:group_concurrency:%s", groupID)
    count, err := rdb.Incr(ctx, key).Result()
    if err != nil {
        return false, err
    }
    if count == 1 {
        rdb.Expire(ctx, key, 5*time.Minute) // Safety net
    }
    if count > int64(maxPerGroup) {
        rdb.Decr(ctx, key)
        return false, nil
    }
    return true, nil
}

func releaseGroupSlot(ctx context.Context, rdb *redis.Client, groupID string) {
    key := fmt.Sprintf("arena:group_concurrency:%s", groupID)
    rdb.Decr(ctx, key)
}
```

> **Tradeoff**: Go has no built-in cron — scheduler must use `time.Ticker` or external cron library.

</tab>
<tab title="Node.js">

```typescript
import { WorkerPro } from "@taskforcesh/bullmq-pro";

// Group concurrency: max 3 parallel jobs per guild
const worker = new WorkerPro("matchmaking",
  async (job) => {
    const { player_id, rank } = job.data;
    return await findMatch(player_id, rank);
  },
  {
    connection: { host: "localhost", port: 6379 },
    concurrency: 100,   // Total worker concurrency
    group: {
      concurrency: 3,   // Max 3 parallel jobs per group
    },
  }
);
```

The `group.concurrency` setting is global across all workers. With 5 workers at `concurrency: 100` and `group.concurrency: 3`, each group processes at most 3 jobs simultaneously total (not 15).

```
Group concurrency = 3, Total concurrency = 100:

Guild "dragons":
  Job 1 --- Active (Worker A)
  Job 2 --- Active (Worker B)
  Job 3 --- Active (Worker C)
  Job 4 --- Waiting (group limit)
  Job 5 --- Waiting

Guild "phoenix":
  Job 1 --- Active (Worker A)
  Job 2 --- Active (Worker D)
  Job 3 --- Active (Worker E)

Total active: 6 (3 per group, 100 capacity available)
```

> **Tradeoff**: Event loop concurrency means I/O-bound jobs scale well but CPU-bound jobs need worker threads.

</tab>
</tabs>

## 28.4. Group Rate Limiting

Limit the processing rate per group independently. When a group hits its rate limit, only that group pauses while other groups continue processing normally.

<tabs>
<tab title="Elixir">

```elixir
# Elixir workaround: per-group rate limiting with Redis counters
defmodule Arena.GroupRateLimiter do
  @moduledoc "Per-guild rate limiting for API-bound operations"

  def check_group_rate(group_id, max_per_window, window_ms) do
    key = "arena:group_rate:#{group_id}"

    case Redix.pipeline(:arena_redis, [
      ["INCR", key],
      ["PTTL", key]
    ]) do
      {:ok, [count, ttl]} ->
        if count == 1 do
          Redix.command(:arena_redis, ["PEXPIRE", key, window_ms])
        end

        if count > max_per_window do
          {:rate_limited, max(ttl, 0)}
        else
          :ok
        end
    end
  end
end

# In processor: limit each guild to 50 API calls per second
def process(%EchoMQ.Job{data: data} = _job) do
  guild_id = data["guild_id"]

  case Arena.GroupRateLimiter.check_group_rate(guild_id, 50, 1_000) do
    :ok ->
      call_external_api(data)

    {:rate_limited, ttl} ->
      Logger.debug("Guild #{guild_id} rate limited for #{ttl}ms")
      {:delay, ttl}
  end
end
```

> **Benefit**: Rate limiting uses Redis TTL keys — distributed limiting works across clustered BEAM nodes.

</tab>
<tab title="Go">

> **Go Gap: Group Rate Limiting**
> - **Feature**: Per-group rate limiting (`group.limit` option)
> - **Reason**: Not implemented in Go client
> - **Workaround**: Use the same Redis counter pattern as the Elixir workaround above
> - **Reference**: [PROTOCOL-GAPS.md](PROTOCOL-GAPS.md)

```go
// Per-group rate check using Redis counter
func checkGroupRate(ctx context.Context, rdb *redis.Client, groupID string, maxPerWindow int, windowMs int) (bool, int64) {
    key := fmt.Sprintf("arena:group_rate:%s", groupID)

    count, _ := rdb.Incr(ctx, key).Result()
    if count == 1 {
        rdb.PExpire(ctx, key, time.Duration(windowMs)*time.Millisecond)
    }

    if count > int64(maxPerWindow) {
        ttl, _ := rdb.PTTL(ctx, key).Result()
        return false, ttl.Milliseconds()
    }
    return true, 0
}

// Usage in processor: 50 per second per guild
worker.Process(func(job *echomq.Job) (interface{}, error) {
    guildID := job.Data["guild_id"].(string)

    allowed, ttlMs := checkGroupRate(ctx, rdb, guildID, 50, 1000)
    if !allowed {
        // Return error with delay hint for retry
        return nil, fmt.Errorf("guild %s rate limited for %dms", guildID, ttlMs)
    }

    return callExternalAPI(job.Data)
})
```

> **Benefit**: Rate limit config is declarative — the Lua script enforces limits atomically in Redis.

</tab>
<tab title="Node.js">

```typescript
import { WorkerPro, QueuePro } from "@taskforcesh/bullmq-pro";

// Group rate limiting: 50 jobs per second per guild
const worker = new WorkerPro("guild-api-calls",
  async (job) => {
    return await callExternalAPI(job.data);
  },
  {
    connection: { host: "localhost", port: 6379 },
    group: {
      limit: {
        max: 50,        // 50 jobs per second per group
        duration: 1000,
      },
    },
  }
);
```

Rate limit behavior per group:

```
Rate Limit Timeline (max: 50/sec per group):

Guild "dragons": ████████░░░░████████░░░░  (rate limited, resumes)
Guild "phoenix": ████████████████████████  (unaffected by dragons)
Guild "titans":  ██████░░░░░░████████████  (briefly limited)

Each group's rate limit is independent.
When "dragons" hits 50/sec, only "dragons" pauses.
```

> **Benefit**: `limiter` option integrates with BullMQ's built-in token bucket implementation.

</tab>
</tabs>

## 28.5. Manual Group Rate Limiting

Rate limit a specific group based on external signals, such as a 429 response from a per-tenant API endpoint.

<tabs>
<tab title="Elixir">

```elixir
# Manual group rate limiting based on external API 429 response
defmodule Arena.GuildAPIProcessor do
  def process(%EchoMQ.Job{data: data} = _job) do
    guild_id = data["guild_id"]

    case Arena.ExternalAPI.call(guild_id, data["endpoint"], data["params"]) do
      {:ok, result} ->
        {:ok, result}

      {:error, %{status: 429, headers: headers}} ->
        retry_after = parse_retry_after(headers)
        # Rate limit just this guild's group
        Arena.GroupRateLimiter.set_group_limit(guild_id, retry_after)
        {:delay, retry_after}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp parse_retry_after(headers) do
    case List.keyfind(headers, "retry-after", 0) do
      {_, seconds} -> String.to_integer(seconds) * 1_000
      nil -> 5_000
    end
  end
end

defmodule Arena.GroupRateLimiter do
  def set_group_limit(group_id, duration_ms) do
    key = "arena:group_rate_limit:#{group_id}"
    Redix.command(:arena_redis, ["SET", key, "1", "PX", duration_ms])
  end

  def is_group_limited?(group_id) do
    key = "arena:group_rate_limit:#{group_id}"
    case Redix.command(:arena_redis, ["PTTL", key]) do
      {:ok, ttl} when ttl > 0 -> {:limited, ttl}
      _ -> :ok
    end
  end
end
```

> **Benefit**: Rate limiting uses Redis TTL keys — distributed limiting works across clustered BEAM nodes.

</tab>
<tab title="Go">

```go
// Manual group rate limiting: set a per-group cooldown in Redis
func setGroupRateLimit(ctx context.Context, rdb *redis.Client, groupID string, durationMs int) error {
    key := fmt.Sprintf("arena:group_rate_limit:%s", groupID)
    return rdb.Set(ctx, key, "1", time.Duration(durationMs)*time.Millisecond).Err()
}

func isGroupLimited(ctx context.Context, rdb *redis.Client, groupID string) (bool, int64) {
    key := fmt.Sprintf("arena:group_rate_limit:%s", groupID)
    ttl, err := rdb.PTTL(ctx, key).Result()
    if err != nil || ttl <= 0 {
        return false, 0
    }
    return true, ttl.Milliseconds()
}

// In processor: check before calling per-guild API
worker.Process(func(job *echomq.Job) (interface{}, error) {
    guildID := job.Data["guild_id"].(string)

    if limited, ttlMs := isGroupLimited(ctx, rdb, guildID); limited {
        return nil, fmt.Errorf("guild %s rate limited for %dms", guildID, ttlMs)
    }

    result, err := callGuildAPI(guildID, job.Data)
    if apiErr, ok := err.(*APIError); ok && apiErr.StatusCode == 429 {
        setGroupRateLimit(ctx, rdb, guildID, apiErr.RetryAfterMs())
        return nil, err
    }
    return result, err
})
```

> **Benefit**: Rate limit config is declarative — the Lua script enforces limits atomically in Redis.

</tab>
<tab title="Node.js">

```typescript
import { WorkerPro, Job } from "@taskforcesh/bullmq-pro";

const worker = new WorkerPro("guild-api-calls",
  async (job: Job) => {
    const guildId = job.opts.group?.id;
    if (!guildId) throw new Error("Missing group ID");

    try {
      return await callGuildAPI(guildId, job.data);
    } catch (err: any) {
      if (err.status === 429) {
        const retryAfter = (parseInt(err.headers["retry-after"]) || 5) * 1000;

        // Rate limit just this group
        await worker.rateLimitGroup(job, retryAfter);
        throw WorkerPro.RateLimitError();
      }
      throw err;
    }
  },
  {
    connection: { host: "localhost", port: 6379 },
  }
);
```

Node.js Pro provides `worker.rateLimitGroup(job, duration)` as a built-in method. It writes a per-group rate limit key in Redis, causing the Pro worker to skip that group for the specified duration. The `RateLimitError` signals the framework to move the job back to waiting.

> **Benefit**: `limiter` option integrates with BullMQ's built-in token bucket implementation.

</tab>
</tabs>

## 28.6. Pausing and Resuming Groups

Pause processing for specific groups without affecting others. Active jobs in the paused group finish, but no new jobs from that group are picked up until resumed.

<tabs>
<tab title="Elixir">

```elixir
# Pause a guild during maintenance or investigation
defmodule Arena.GroupAdmin do
  def pause_guild(guild_id) do
    # For Node.js Pro worker consumption: write pause flag to Redis
    key = "arena:group_paused:#{guild_id}"
    Redix.command(:arena_redis, ["SET", key, "1"])
    Logger.info("Paused group: guild_#{guild_id}")
  end

  def resume_guild(guild_id) do
    key = "arena:group_paused:#{guild_id}"
    Redix.command(:arena_redis, ["DEL", key])
    Logger.info("Resumed group: guild_#{guild_id}")
  end

  def guild_paused?(guild_id) do
    key = "arena:group_paused:#{guild_id}"
    case Redix.command(:arena_redis, ["EXISTS", key]) do
      {:ok, 1} -> true
      _ -> false
    end
  end
end

# Pause the "exploiters" guild during investigation
Arena.GroupAdmin.pause_guild("exploiters")

# Resume after investigation
Arena.GroupAdmin.resume_guild("exploiters")
```

> **Benefit**: Process groups via `:pg` distribute group membership across the BEAM cluster.

</tab>
<tab title="Go">

```go
// Pause/resume groups via Redis flags
func pauseGroup(ctx context.Context, rdb *redis.Client, groupID string) error {
    key := fmt.Sprintf("arena:group_paused:%s", groupID)
    return rdb.Set(ctx, key, "1", 0).Err()
}

func resumeGroup(ctx context.Context, rdb *redis.Client, groupID string) error {
    key := fmt.Sprintf("arena:group_paused:%s", groupID)
    return rdb.Del(ctx, key).Err()
}

func isGroupPaused(ctx context.Context, rdb *redis.Client, groupID string) bool {
    key := fmt.Sprintf("arena:group_paused:%s", groupID)
    exists, _ := rdb.Exists(ctx, key).Result()
    return exists > 0
}

// In processor: skip paused groups
worker.Process(func(job *echomq.Job) (interface{}, error) {
    guildID := job.Data["guild_id"].(string)
    if isGroupPaused(ctx, rdb, guildID) {
        // Re-delay the job; it will be picked up after resume
        return nil, fmt.Errorf("guild %s is paused", guildID)
    }
    return processJob(job)
})
```

> **Benefit**: Group IDs as struct fields enable type-safe group assignment at compile time.

</tab>
<tab title="Node.js">

```typescript
import { QueuePro } from "@taskforcesh/bullmq-pro";

const queue = new QueuePro("matchmaking", {
  connection: { host: "localhost", port: 6379 },
});

// Pause a guild during investigation
const paused = await queue.pauseGroup("guild_exploiters");
// Returns true if newly paused, false if already paused

// Resume after investigation
const resumed = await queue.resumeGroup("guild_exploiters");
// Returns true if newly resumed, false if not paused or group doesn't exist

// Pause is immediate: workers finish current jobs but pick up no new ones
// from this group. Other groups continue processing normally.
```

Group pausing is useful for:
- **Investigating abuse**: Pause a guild's jobs while reviewing suspicious activity
- **Maintenance windows**: Pause a region's shard group during infrastructure updates
- **Gradual rollout**: Pause all groups, then resume one at a time to control load

> **Benefit**: Group support matches BullMQ Pro's API — familiar for commercial BullMQ users.

</tab>
</tabs>

## 28.7. Max Group Size

Limit the number of waiting jobs per group. When a group reaches its max size, new jobs for that group are rejected. This prevents a single tenant from consuming unbounded Redis memory.

<tabs>
<tab title="Elixir">

```elixir
# Elixir workaround: check group size before adding
defmodule Arena.GroupSizeGuard do
  @max_group_size 1000

  def add_with_limit(queue, name, data, group_id, opts) do
    size_key = "arena:group_size:#{group_id}"

    case Redix.command(:arena_redis, ["INCR", size_key]) do
      {:ok, count} when count <= @max_group_size ->
        result = EchoMQ.Queue.add(queue, name, data,
          Keyword.merge(opts, group: %{id: group_id}, connection: :arena_redis)
        )

        case result do
          {:ok, _} -> result
          error ->
            Redix.command(:arena_redis, ["DECR", size_key])
            error
        end

      {:ok, _count} ->
        Redix.command(:arena_redis, ["DECR", size_key])
        {:error, :group_max_size_exceeded}
    end
  end

  # Call this when a job completes to decrement the counter
  def on_job_complete(group_id) do
    size_key = "arena:group_size:#{group_id}"
    Redix.command(:arena_redis, ["DECR", size_key])
  end
end

# Usage: limit guild "dragons" to 1000 pending matchmaking jobs
case Arena.GroupSizeGuard.add_with_limit(
  "matchmaking", "find-match",
  %{"player_id" => "PLRdrgn51K3pN7"}, "guild_dragons", []
) do
  {:ok, job} ->
    Logger.info("Queued matchmaking for PLRdrgn51K3pN7")

  {:error, :group_max_size_exceeded} ->
    Logger.warning("Guild dragons at capacity (1000 jobs)")
end
```

> **Benefit**: Process groups via `:pg` distribute group membership across the BEAM cluster.

</tab>
<tab title="Go">

```go
// Group size guard: Redis counter-based
const maxGroupSize = 1000

func addWithGroupLimit(ctx context.Context, rdb *redis.Client, queue, name, groupID string, data map[string]interface{}) error {
    sizeKey := fmt.Sprintf("arena:group_size:%s", groupID)

    count, err := rdb.Incr(ctx, sizeKey).Result()
    if err != nil {
        return err
    }

    if count > int64(maxGroupSize) {
        rdb.Decr(ctx, sizeKey)
        return fmt.Errorf("group %s max size exceeded (%d)", groupID, maxGroupSize)
    }

    err = addJobWithGroup(ctx, rdb, queue, name, groupID, data)
    if err != nil {
        rdb.Decr(ctx, sizeKey) // Rollback on failure
        return err
    }
    return nil
}

// Decrement when job completes
func onJobComplete(ctx context.Context, rdb *redis.Client, groupID string) {
    sizeKey := fmt.Sprintf("arena:group_size:%s", groupID)
    rdb.Decr(ctx, sizeKey)
}
```

> **Benefit**: Group IDs as struct fields enable type-safe group assignment at compile time.

</tab>
<tab title="Node.js">

```typescript
import { QueuePro, GroupMaxSizeExceededError } from "@taskforcesh/bullmq-pro";

const queue = new QueuePro("matchmaking", {
  connection: { host: "localhost", port: 6379 },
});

// Add job with max group size enforced by Pro
try {
  await queue.add("find-match", {
    player_id: "PLRdrgn51K3pN7",
    guild_id: "dragons",
  }, {
    group: {
      id: "guild_dragons",
      maxSize: 1000,  // Max 1000 pending jobs for this guild
    },
  });
} catch (err) {
  if (err instanceof GroupMaxSizeExceededError) {
    console.log("Guild dragons at capacity (1000 jobs)");
    // Return 429 to the player or show "queue full" message
  } else {
    throw err;
  }
}
```

In Node.js Pro, `maxSize` is specified per-add call in the group options. The check is atomic (Lua script) so there is no race condition between the size check and the add.

> **Benefit**: Group support matches BullMQ Pro's API — familiar for commercial BullMQ users.

</tab>
</tabs>

## 28.8. Group Getters

Query group status: list all groups, count jobs per group, and retrieve specific group's jobs.

<tabs>
<tab title="Elixir">

```elixir
# Elixir workaround: query group data via Redis keys
defmodule Arena.GroupInspector do
  def list_groups(queue) do
    # Scan for group keys (Pro stores groups in bull:{queue}:groups)
    # Workaround: track groups manually in a Redis set
    {:ok, groups} = Redix.command(:arena_redis, [
      "SMEMBERS", "arena:groups:#{queue}"
    ])
    groups
  end

  def group_job_count(queue, group_id) do
    # Query the group's waiting list size
    key = "arena:group_size:#{group_id}"
    case Redix.command(:arena_redis, ["GET", key]) do
      {:ok, nil} -> 0
      {:ok, count} -> String.to_integer(count)
    end
  end

  def inspect_all(queue) do
    groups = list_groups(queue)

    Enum.map(groups, fn group_id ->
      count = group_job_count(queue, group_id)
      %{group_id: group_id, pending_jobs: count}
    end)
  end
end

# Arena.GroupInspector.inspect_all("matchmaking")
# [
#   %{group_id: "guild_dragons", pending_jobs: 487},
#   %{group_id: "guild_phoenix", pending_jobs: 8},
#   %{group_id: "guild_titans", pending_jobs: 142}
# ]
```

> **Benefit**: Process groups via `:pg` distribute group membership across the BEAM cluster.

</tab>
<tab title="Go">

```go
// Group inspection via Redis
func listGroups(ctx context.Context, rdb *redis.Client, queue string) ([]string, error) {
    key := fmt.Sprintf("arena:groups:%s", queue)
    return rdb.SMembers(ctx, key).Result()
}

func groupJobCount(ctx context.Context, rdb *redis.Client, groupID string) (int64, error) {
    key := fmt.Sprintf("arena:group_size:%s", groupID)
    val, err := rdb.Get(ctx, key).Int64()
    if err == redis.Nil {
        return 0, nil
    }
    return val, err
}

func inspectAllGroups(ctx context.Context, rdb *redis.Client, queue string) {
    groups, _ := listGroups(ctx, rdb, queue)
    for _, gid := range groups {
        count, _ := groupJobCount(ctx, rdb, gid)
        fmt.Printf("  %s: %d pending jobs\n", gid, count)
    }
}
```

> **Benefit**: Group IDs as struct fields enable type-safe group assignment at compile time.

</tab>
<tab title="Node.js">

```typescript
import { QueuePro } from "@taskforcesh/bullmq-pro";

const queue = new QueuePro("matchmaking", {
  connection: { host: "localhost", port: 6379 },
});

// Get total job count across all groups (iterates in batches of 1000)
const totalGroupJobs = await queue.getGroupsJobsCount(1000);
console.log(`Total jobs across all groups: ${totalGroupJobs}`);

// Get active job count for a specific guild
const dragonsActive = await queue.getGroupActiveCount("guild_dragons");
console.log(`Guild dragons active jobs: ${dragonsActive}`);

// Get jobs for a specific guild with pagination
const jobs = await queue.getGroupJobs("guild_dragons", 0, 100);
console.log(`First 100 jobs for guild dragons:`);
for (const job of jobs) {
  console.log(`  ${job.id}: ${job.data.player_id} (rank ${job.data.rank})`);
}

// Get priority distribution within a group
const counts = await queue.getCountsPerPriorityForGroup("guild_dragons", [0, 1, 50, 100]);
// { "0": 300, "1": 50, "50": 100, "100": 37 }
```

> **Benefit**: `limiter` option integrates with BullMQ's built-in token bucket implementation.

</tab>
</tabs>

## 28.9. Priority Within Groups

Combine groups with intra-group priorities. Each group maintains its own priority queue, so high-priority jobs within a guild are processed before low-priority jobs in the same guild, while the round-robin across guilds remains fair.

<tabs>
<tab title="Elixir">

```elixir
# Prioritized guild actions: combat > buffs > leaderboard updates
defmodule Arena.GuildActions do
  # Priority tiers (lower = higher priority)
  @priority_combat 1
  @priority_buffs 10
  @priority_leaderboard 50

  def queue_combat_action(guild_id, player_id, action) do
    EchoMQ.Queue.add("guild-actions", "combat", %{
      "player_id" => player_id,
      "guild_id" => guild_id,
      "action" => action
    },
      connection: :arena_redis,
      group: %{id: "guild_#{guild_id}", priority: @priority_combat}
    )
  end

  def queue_buff_application(guild_id, player_id, buff) do
    EchoMQ.Queue.add("guild-actions", "buff", %{
      "player_id" => player_id,
      "guild_id" => guild_id,
      "buff" => buff
    },
      connection: :arena_redis,
      group: %{id: "guild_#{guild_id}", priority: @priority_buffs}
    )
  end

  def queue_leaderboard_update(guild_id, player_id, score) do
    EchoMQ.Queue.add("guild-actions", "leaderboard", %{
      "player_id" => player_id,
      "guild_id" => guild_id,
      "score" => score
    },
      connection: :arena_redis,
      group: %{id: "guild_#{guild_id}", priority: @priority_leaderboard}
    )
  end
end

# Within guild "dragons", combat actions process before buffs,
# which process before leaderboard updates.
# Across guilds, round-robin fairness is preserved.
```

> **Benefit**: Process groups via `:pg` distribute group membership across the BEAM cluster.

</tab>
<tab title="Go">

```go
// Prioritized group jobs: write priority into group options
func queueGuildAction(ctx context.Context, rdb *redis.Client, guildID, actionType string, priority int, data map[string]interface{}) error {
    prefix := "bull"
    queue := "guild-actions"
    now := time.Now().UnixMilli()
    jobID := fmt.Sprintf("%d-%s-%s", now, guildID, actionType)

    dataJSON, _ := json.Marshal(data)
    optsJSON := fmt.Sprintf(`{"group":{"id":"guild_%s","priority":%d}}`, guildID, priority)

    key := fmt.Sprintf("%s:%s:%s", prefix, queue, jobID)
    pipe := rdb.Pipeline()
    pipe.HSet(ctx, key, map[string]interface{}{
        "name": actionType, "data": string(dataJSON),
        "opts": optsJSON, "timestamp": now,
    })
    pipe.ZAdd(ctx, fmt.Sprintf("%s:%s:wait", prefix, queue), redis.Z{
        Score: float64(now), Member: jobID,
    })
    _, err := pipe.Exec(ctx)
    return err
}

// Priority tiers
const (
    PriorityCombat      = 1
    PriorityBuffs       = 10
    PriorityLeaderboard = 50
)

// queueGuildAction(ctx, rdb, "dragons", "combat", PriorityCombat, data)
```

> **Benefit**: Group IDs as struct fields enable type-safe group assignment at compile time.

</tab>
<tab title="Node.js">

```typescript
import { QueuePro } from "@taskforcesh/bullmq-pro";

const queue = new QueuePro("guild-actions", {
  connection: { host: "localhost", port: 6379 },
});

// Priority tiers (lower = higher priority)
const PRIORITY = {
  COMBAT: 1,
  BUFFS: 10,
  LEADERBOARD: 50,
} as const;

// Combat action: highest priority within the guild's group
await queue.add("combat", {
  player_id: "PLRdrgn01J2vQ1",
  guild_id: "dragons",
  action: "fireball",
}, {
  group: { id: "guild_dragons", priority: PRIORITY.COMBAT },
});

// Buff application: medium priority
await queue.add("buff", {
  player_id: "PLRdrgn01J2vQ1",
  guild_id: "dragons",
  buff: "strength_potion",
}, {
  group: { id: "guild_dragons", priority: PRIORITY.BUFFS },
});

// Leaderboard update: lowest priority
await queue.add("leaderboard", {
  player_id: "PLRdrgn01J2vQ1",
  guild_id: "dragons",
  score: 4500,
}, {
  group: { id: "guild_dragons", priority: PRIORITY.LEADERBOARD },
});

// Processing order within "guild_dragons": combat -> buffs -> leaderboard
// Processing order across guilds: round-robin (dragons -> phoenix -> ...)
```

Priorities within groups range from 0 to 2,097,151. Priority 0 (default) is the highest; larger numbers mean lower priority.

> **Benefit**: Group support matches BullMQ Pro's API — familiar for commercial BullMQ users.

</tab>
</tabs>

## 28.10. Local Group Settings

Override the global group concurrency or rate limit for specific groups. This is useful when different tenants have different SLA tiers.

<tabs>
<tab title="Elixir">

```elixir
# Elixir workaround: per-group config stored in Redis
defmodule Arena.GroupConfig do
  def set_group_concurrency(group_id, concurrency) do
    key = "arena:group_config:#{group_id}:concurrency"
    Redix.command(:arena_redis, ["SET", key, concurrency])
  end

  def get_group_concurrency(group_id, default \\ 3) do
    key = "arena:group_config:#{group_id}:concurrency"
    case Redix.command(:arena_redis, ["GET", key]) do
      {:ok, nil} -> default
      {:ok, val} -> String.to_integer(val)
    end
  end

  def set_group_rate_limit(group_id, max_per_duration, duration_ms) do
    key = "arena:group_config:#{group_id}:rate_limit"
    Redix.command(:arena_redis, [
      "HSET", key, "max", max_per_duration, "duration", duration_ms
    ])
  end
end

# Premium guild: higher concurrency and rate limit
Arena.GroupConfig.set_group_concurrency("guild_whales", 10)
Arena.GroupConfig.set_group_rate_limit("guild_whales", 200, 1_000)

# Free-tier guild: default limits
# (uses the global defaults: concurrency 3, rate limit 50/sec)
```

> **Benefit**: BEAM processes provide true preemptive concurrency — one slow job cannot starve others.

</tab>
<tab title="Go">

```go
// Per-group config: Redis hash storage
func setGroupConcurrency(ctx context.Context, rdb *redis.Client, groupID string, concurrency int) error {
    key := fmt.Sprintf("arena:group_config:%s:concurrency", groupID)
    return rdb.Set(ctx, key, concurrency, 0).Err()
}

func getGroupConcurrency(ctx context.Context, rdb *redis.Client, groupID string, defaultVal int) int {
    key := fmt.Sprintf("arena:group_config:%s:concurrency", groupID)
    val, err := rdb.Get(ctx, key).Int()
    if err != nil {
        return defaultVal
    }
    return val
}

func setGroupRateLimit(ctx context.Context, rdb *redis.Client, groupID string, max, durationMs int) error {
    key := fmt.Sprintf("arena:group_config:%s:rate_limit", groupID)
    return rdb.HSet(ctx, key, "max", max, "duration", durationMs).Err()
}
```

> **Benefit**: Goroutine-per-job with semaphore-based limiting achieves OS-level parallelism.

</tab>
<tab title="Node.js">

```typescript
import { QueuePro, WorkerPro } from "@taskforcesh/bullmq-pro";

const queue = new QueuePro("guild-actions", {
  connection: { host: "localhost", port: 6379 },
});

// Set per-group concurrency: premium guilds get 10 parallel jobs
await queue.setGroupConcurrency("guild_whales", 10);

// Read current group concurrency
const concurrency = await queue.getGroupConcurrency("guild_whales");
// 10

// Set per-group rate limit: premium guilds get 200/sec (vs default 50/sec)
await queue.setGroupRateLimit("guild_whales", 200, 1000);

// Worker must still declare a default group limit for this to work
const worker = new WorkerPro("guild-actions",
  async (job) => processGuildAction(job),
  {
    connection: { host: "localhost", port: 6379 },
    group: {
      concurrency: 3,  // Default for groups without a local override
      limit: {
        max: 50,        // Default rate limit
        duration: 1000,
      },
    },
  }
);
```

Local group settings override the global defaults. Groups without a local setting use the worker's default `group.concurrency` and `group.limit`.

> **Tradeoff**: Event loop concurrency means I/O-bound jobs scale well but CPU-bound jobs need worker threads.

</tab>
</tabs>

## 28.11. Groups vs Separate Queues

| Aspect | Groups | Separate Queues |
|--------|--------|-----------------|
| Configuration | Single queue, single worker pool | Multiple queues, dedicated workers per queue |
| Fair scheduling | Built-in round-robin (Pro) | Manual: allocate worker count per queue |
| Dynamic tenants | Groups created on-the-fly | New queue + worker per tenant |
| Resource isolation | Shared worker pool | Dedicated workers per queue |
| Monitoring | Group-aware metrics (Pro) | Standard per-queue metrics |
| Per-tenant config | `setGroupConcurrency` / `setGroupRateLimit` | Different worker config per queue |
| Memory overhead | O(1) per group (Redis sorted set entries) | O(N) per queue (separate data structures) |
| Elixir support | Wire-compatible only (group option stored) | Full native support |
| Go support | Not implemented | Full native support |

### When to Use Groups

- Unknown or dynamic number of tenants (guilds created at runtime)
- Need fair resource sharing without manual worker allocation
- All groups have similar processing requirements
- Single worker pool is simpler to operate and monitor

### When to Use Separate Queues

- Small, fixed number of tenants (3 game servers, not 10,000 guilds)
- Different processing requirements per tenant (different worker code)
- Need strict resource isolation (one tenant's load cannot affect another)
- Different SLAs require dedicated infrastructure per tenant
- Running Elixir-only or Go-only without Node.js Pro workers

## 28.12. Elixir Workaround Patterns

For Elixir-only deployments without Node.js Pro workers, simulate group behavior using separate queues with a routing layer.

<tabs>
<tab title="Elixir">

```elixir
defmodule Arena.GroupRouter do
  @moduledoc """
  Routes jobs to per-group queues with round-robin worker allocation.
  Simulates BullMQ Pro groups for Elixir-only deployments.
  """

  def add_grouped(base_queue, name, data, group_id, opts \\ []) do
    queue_name = "#{base_queue}:#{group_id}"

    # Track the group in a set for discovery
    Redix.command(:arena_redis, ["SADD", "arena:groups:#{base_queue}", group_id])

    # Add to the group-specific queue
    EchoMQ.Queue.add(queue_name, name, data,
      Keyword.merge(opts, connection: :arena_redis)
    )
  end

  def start_grouped_workers(base_queue, processor, opts \\ []) do
    concurrency_per_group = Keyword.get(opts, :concurrency, 5)

    # Discover active groups
    {:ok, groups} = Redix.command(:arena_redis, [
      "SMEMBERS", "arena:groups:#{base_queue}"
    ])

    # Start a worker per group (round-robin via BEAM scheduler)
    Enum.map(groups, fn group_id ->
      queue_name = "#{base_queue}:#{group_id}"
      EchoMQ.Worker.start_link(
        name: String.to_atom("worker_#{queue_name}"),
        queue: queue_name,
        connection: :arena_redis,
        processor: processor,
        concurrency: concurrency_per_group
      )
    end)
  end
end

# Route matchmaking to per-guild queues
Arena.GroupRouter.add_grouped("matchmaking", "find-match",
  %{"player_id" => "PLRdrgn01J2vQ1"}, "guild_dragons")

# Start workers for all active guilds
Arena.GroupRouter.start_grouped_workers("matchmaking",
  &Arena.Matchmaking.process/1, concurrency: 3)
```

> **Benefit**: GenServer-based schedulers integrate with supervision — restarts guarantee schedule continuity.

</tab>
<tab title="Go">

```go
// Group routing: separate queues per group
func addGrouped(ctx context.Context, rdb *redis.Client, baseQueue, name, groupID string, data map[string]interface{}) error {
    queueName := fmt.Sprintf("%s:%s", baseQueue, groupID)

    // Track the group
    rdb.SAdd(ctx, fmt.Sprintf("arena:groups:%s", baseQueue), groupID)

    // Add to the group-specific queue
    return addSingleJob(ctx, rdb, queueName, map[string]interface{}{
        "name": name, "data": data,
    })
}

// Start workers per group
func startGroupedWorkers(ctx context.Context, rdb *redis.Client, baseQueue string, concurrency int) {
    groups, _ := rdb.SMembers(ctx, fmt.Sprintf("arena:groups:%s", baseQueue)).Result()

    for _, groupID := range groups {
        queueName := fmt.Sprintf("%s:%s", baseQueue, groupID)
        worker := echomq.NewWorker(queueName, rdb, echomq.WorkerOptions{
            Concurrency: concurrency,
        })
        worker.Process(func(job *echomq.Job) (interface{}, error) {
            return processJob(job)
        })
        go worker.Start(ctx)
    }
}
```

> **Benefit**: Goroutine-per-job with semaphore-based limiting achieves OS-level parallelism.

</tab>
<tab title="Node.js">

```typescript
// For Node.js, use QueuePro/WorkerPro directly (native group support).
// This routing pattern is only needed if you cannot use Pro.

import { Queue, Worker, Job } from "bullmq";

const connection = { host: "localhost", port: 6379 };

async function addGrouped(baseQueue: string, name: string, data: any, groupId: string) {
  const queueName = `${baseQueue}:${groupId}`;
  const queue = new Queue(queueName, { connection });
  await queue.add(name, data);
  await queue.close();
}

function startGroupedWorkers(baseQueue: string, groups: string[], concurrency: number) {
  return groups.map((groupId) => {
    const queueName = `${baseQueue}:${groupId}`;
    return new Worker(queueName,
      async (job: Job) => processJob(job),
      { connection, concurrency }
    );
  });
}

// Non-Pro fallback: separate queues per guild with round-robin via OS scheduler
```

> **Benefit**: `upsertJobScheduler` is Redis-persisted and idempotent — safe across process restarts.

</tab>
</tabs>

## 28.13. Cross-Language Comparison

| Feature | Elixir | Go | Node.js Pro |
|---------|--------|-----|-------------|
| Group option | `group: %{id: "..."}` (wire only) | Not implemented | `group: { id: "..." }` |
| Group scheduling | Not enforced natively | Not implemented | Built-in round-robin |
| Group concurrency | Workaround (Redis semaphore) | Workaround (Redis semaphore) | `group.concurrency` option |
| Group rate limiting | Workaround (Redis counter) | Workaround (Redis counter) | `group.limit` option |
| Manual rate limit | Workaround (Redis key) | Workaround (Redis key) | `worker.rateLimitGroup()` |
| Pause/resume | Workaround (Redis flag) | Workaround (Redis flag) | `queue.pauseGroup()` |
| Max group size | Workaround (Redis counter) | Workaround (Redis counter) | `group.maxSize` option |
| Group getters | Workaround (manual tracking) | Workaround (manual tracking) | `queue.getGroupJobs()` etc. |
| Local overrides | Workaround (Redis hash) | Workaround (Redis hash) | `queue.setGroupConcurrency()` |
| Priority in groups | `group: %{..., priority: n}` (wire) | Not implemented | `group: { ..., priority: n }` |
| Sandboxed processors | N/A | N/A | Supported (access `job.gid`) |

Groups is the only EchoMQ feature where Node.js Pro is the primary implementation and Elixir/Go provide workaround patterns. For deployments that need native group scheduling, run a Node.js Pro worker alongside your Elixir/Go workers on the same queue. The shared Redis key format ensures all runtimes see the same jobs.

---

*Previous: [Batches](ch27-batches.md) | Next: [Metrics & Prometheus](ch29-metrics-prometheus.md)*
