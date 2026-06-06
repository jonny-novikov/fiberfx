# Chapter 11. Connections & Configuration

## 11.1. Redis Requirements

EchoMQ requires **Redis 6.0+** (for Lua scripting features used by the protocol). Redis 7.x is recommended for production deployments for improved memory efficiency and FUNCTION support.

**Critical setting** — all EchoMQ implementations require:

```
maxmemory-policy=noeviction
```

Without this, Redis may silently evict queue keys under memory pressure, causing jobs to disappear. This applies to all three runtimes equally.

**Standalone vs Cluster:**

| Deployment | When to Use | Key Format |
|-----------|-------------|------------|
| **Standalone** | Development, low-to-medium throughput | `bull:queueName:suffix` |
| **Redis Cluster** | High availability, horizontal scaling | `bull:{queueName}:suffix` |

Redis Cluster uses hash tags (`{queueName}`) to co-locate all keys for a queue in the same slot, which is required for multi-key Lua script execution. See [Redis Data Layer](ch02-redis-data-layer.md) for details on the hash tag strategy.

## 11.2. Basic Connection

<tabs>
<tab title="Elixir">

```elixir
# Add EchoMQ.RedisConnection to your supervision tree
children = [
  {EchoMQ.RedisConnection,
    name: :echomq_redis,
    url: "redis://localhost:6379",
    pool_size: 10}
]

Supervisor.start_link(children, strategy: :one_for_one)

# Use the named connection for queue operations
{:ok, job} = EchoMQ.Queue.add("combat-actions", "calculate-damage",
  %{player_id: "PLR0K48QjihpC4", target_id: "NPC5rK2mJ9pQ1L", damage: 150},
  connection: :echomq_redis)
```

> **Benefit**: Rate limiting uses Redis TTL keys — distributed limiting works across clustered BEAM nodes.

</tab>
<tab title="Go">

```go
import (
    "github.com/redis/go-redis/v9"
    "github.com/fiberfx/echomq-go/pkg/echomq"
)

// Create a Redis client
client := redis.NewClient(&redis.Options{
    Addr: "localhost:6379",
})

// Create a queue (accepts redis.Cmdable interface)
queue := echomq.NewQueue("combat-actions", client)

// Create a worker for processing combat calculations
worker := echomq.NewWorker("combat-actions", client, echomq.WorkerOptions{
    Concurrency: 10,
})
```

> **Benefit**: Goroutine-per-job with semaphore-based limiting achieves OS-level parallelism.

</tab>
<tab title="Node.js">

```typescript
import { Queue, Worker } from 'bullmq';

// Connection options passed to ioredis
const queue = new Queue('combat-actions', {
  connection: {
    host: 'localhost',
    port: 6379,
  },
});

// Workers auto-create a duplicate blocking connection
const worker = new Worker('combat-actions', async (job) => {
  // process combat action (damage calc, buff application, etc.)
}, {
  connection: {
    host: 'localhost',
    port: 6379,
  },
  concurrency: 10,
});
```

> **Tradeoff**: Event loop concurrency means I/O-bound jobs scale well but CPU-bound jobs need worker threads.

</tab>
</tabs>

## 11.3. Connection Pooling

Each language handles Redis connection pooling differently, reflecting the runtime's native concurrency model.

### Elixir: NimblePool

EchoMQ Elixir uses `NimblePool` for connection pooling. The `EchoMQ.RedisConnection` module wraps a pool of Redix connections with supervised lifecycle management:

```elixir
{EchoMQ.RedisConnection,
  name: :echomq_redis,
  host: "localhost",
  port: 6379,
  pool_size: 10,      # 10 Redix connections in the pool
  timeout: 5000}       # connection timeout in ms
```

The pool automatically checks out a connection for each Redis command and returns it when done. For Workers, the connection pool is shared across all concurrent job processors — a single pool can serve combat-actions, matchmaking, and inventory workers simultaneously. The NimblePool implementation also maintains a Registry for tracking blocking connections used by `QueueEvents`.

### Go: go-redis Internal Pool

The go-redis client has a built-in connection pool. Configure it through `redis.Options`:

```go
client := redis.NewClient(&redis.Options{
    Addr:         "localhost:6379",
    PoolSize:     10,              // max connections (default: 10 * NumCPU)
    MinIdleConns: 5,               // keep warm connections ready
    PoolTimeout:  30 * time.Second, // wait for available connection
    DialTimeout:  5 * time.Second,
    ReadTimeout:  3 * time.Second,
    WriteTimeout: 3 * time.Second,
})
```

Because go-redis pools internally, you pass a single `redis.Client` to `NewQueue` and `NewWorker`. The pool handles multiplexing across goroutines automatically.

### Node.js: ioredis Auto-Reconnect

ioredis manages a single connection per instance with built-in auto-reconnect. BullMQ Workers automatically create a second (duplicate) connection for blocking XREAD operations:

```typescript
import IORedis from 'ioredis';

// Shared connection for Queues (non-blocking operations)
const connection = new IORedis({
  host: 'localhost',
  port: 6379,
  maxRetriesPerRequest: null, // required for Workers
});

// Reuse across multiple game queues
const combatQueue = new Queue('combat-actions', { connection });
const matchmakingQueue = new Queue('matchmaking', { connection });

// Workers auto-duplicate the connection for blocking ops
const worker = new Worker('combat-actions', processor, { connection });
```

> **Important**: Set `maxRetriesPerRequest: null` on connections used by Workers. This tells ioredis to retry commands indefinitely during Redis outages, ensuring workers resume automatically after reconnection.

## 11.4. Redis Cluster

<tabs>
<tab title="Elixir">

```elixir
# Redis Cluster support via Redix.Cluster (if available)
# or individual node connections with hash-tag-aware key building.
# EchoMQ Elixir handles hash tags in key construction.
# For a game server cluster, connect via a Cluster-aware proxy:
{EchoMQ.RedisConnection,
  name: :echomq_redis,
  url: "redis://redis-cluster-proxy:6379",
  pool_size: 10}
```

> **Benefit**: Redix.Cluster provides transparent slot routing — application code doesn't change.

</tab>
<tab title="Go">

```go
// Redis Cluster — auto-detected by EchoMQ Go
client := redis.NewClusterClient(&redis.ClusterOptions{
    Addrs: []string{
        "redis-node-1:6379",
        "redis-node-2:6379",
        "redis-node-3:6379",
    },
    PoolSize: 10,
})

// EchoMQ auto-detects ClusterClient and enables hash-tagged keys
// bull:{queueName}:wait instead of bull:queueName:wait
queue := echomq.NewQueue("combat-actions", client)

// Slot validation happens at startup
// Output: Redis Cluster detected: Queue 'combat-actions' keys validated (slot XXXX)
```

> **Benefit**: `redis.ClusterClient` with automatic CRC16 hash tag detection handles sharded Redis.

</tab>
<tab title="Node.js">

```typescript
import IORedis from 'ioredis';
import { Queue, Worker } from 'bullmq';

const connection = new IORedis.Cluster([
  { host: 'redis-node-1', port: 6379 },
  { host: 'redis-node-2', port: 6379 },
  { host: 'redis-node-3', port: 6379 },
], {
  redisOptions: {
    maxRetriesPerRequest: null,
  },
});

const queue = new Queue('combat-actions', { connection });
const worker = new Worker('combat-actions', processor, { connection });
```

> **Benefit**: `ioredis` Cluster mode auto-discovers nodes and redirects commands transparently.

</tab>
</tabs>

> **⚠️ Elixir Gap**: Redis Cluster auto-detection and hash-tag validation are not implemented. Single-node and Sentinel modes only.
> **Proposed Solution**: Integrate `:eredis_cluster` or implement CRC16 slot calculation in `EchoMQ.RedisConnection` with hash-tag extraction matching the Go `cluster.go` approach.

All implementations use the `bull:{queueName}:suffix` key format with hash tags to ensure all keys for a queue land in the same Redis Cluster slot. This is mandatory — Lua scripts operate on multiple keys atomically and will fail with `CROSSSLOT` errors if keys span different slots.

## 11.5. Authentication & TLS

<tabs>
<tab title="Elixir">

```elixir
# Password authentication
{EchoMQ.RedisConnection,
  name: :echomq_redis,
  host: "redis.example.com",
  port: 6380,
  password: System.fetch_env!("REDIS_PASSWORD"),
  ssl: true}

# With full TLS options
{EchoMQ.RedisConnection,
  name: :echomq_redis,
  host: "redis.example.com",
  port: 6380,
  password: System.fetch_env!("REDIS_PASSWORD"),
  ssl: true,
  socket_opts: [
    verify: :verify_peer,
    cacertfile: CAStore.file_path(),
    server_name_indication: ~c"redis.example.com"
  ]}
```

> **Benefit**: Named connections via `Redix` integrate into supervision trees — automatic reconnect on network partitions.

</tab>
<tab title="Go">

```go
import "crypto/tls"

client := redis.NewClient(&redis.Options{
    Addr:     "redis.example.com:6380",
    Password: os.Getenv("REDIS_PASSWORD"),
    TLSConfig: &tls.Config{
        MinVersion: tls.VersionTLS12,
    },
})
```

> **Benefit**: Strongly-typed option structs catch misconfiguration at compile time.

</tab>
<tab title="Node.js">

```typescript
const connection = new IORedis({
  host: 'redis.example.com',
  port: 6380,
  password: process.env.REDIS_PASSWORD,
  tls: {
    rejectUnauthorized: true,
  },
});

const queue = new Queue('combat-actions', { connection });
```

> **Benefit**: `ioredis` connection with lazy initialization — Redis connects only when the first command is issued.

</tab>
</tabs>

## 11.6. Multi-Shard Game Server Connections

In a multiplayer game like Fireheadz Arena, game servers are typically organized into **shards** — logical partitions that isolate groups of players for performance and fault containment. EchoMQ supports shard isolation through **queue name prefixing**. All shards share the same Redis instance but use distinct queue names per shard. The Redis key prefix (`bull` by default) remains consistent across shards for protocol compatibility.

<tabs>
<tab title="Elixir">

```elixir
defmodule Arena.ShardQueue do
  @doc "Enqueue a job on a specific game shard's combat queue."
  def add_job(shard_id, job_name, data) do
    queue_name = "shard:#{shard_id}:combat-actions"
    EchoMQ.Queue.add(queue_name, job_name, data,
      connection: :echomq_redis)
  end

  def start_worker(shard_id, processor) do
    EchoMQ.Worker.start_link(
      queue: "shard:#{shard_id}:combat-actions",
      connection: :echomq_redis,
      processor: processor,
      concurrency: 50)
  end
end

# Example: Route a damage calculation to shard "dungeon-7"
Arena.ShardQueue.add_job("dungeon-7", "calculate-damage",
  %{player_id: "PLR0K48QjihpC4", target_id: "NPC5rK2mJ9pQ1L", damage: 150})
```

> **Benefit**: BEAM processes provide true preemptive concurrency — one slow job cannot starve others.

</tab>
<tab title="Go">

```go
func addShardJob(shardID string, client redis.Cmdable) {
    queueName := fmt.Sprintf("shard:%s:combat-actions", shardID)
    queue := echomq.NewQueue(queueName, client)
    // Keys: bull:{shard:dungeon-7:combat-actions}:wait, etc.
}

func startShardWorker(shardID string, client redis.Cmdable) {
    queueName := fmt.Sprintf("shard:%s:combat-actions", shardID)
    worker := echomq.NewWorker(queueName, client, echomq.WorkerOptions{
        Concurrency: 50,
    })
}
```

> **Benefit**: Goroutine-per-job with semaphore-based limiting achieves OS-level parallelism.

</tab>
<tab title="Node.js">

```typescript
function addShardJob(shardId: string) {
  const queueName = `shard:${shardId}:combat-actions`;
  const queue = new Queue(queueName, { connection });
  // Keys: bull:{shard:dungeon-7:combat-actions}:wait, etc.
}

function startShardWorker(shardId: string) {
  const queueName = `shard:${shardId}:combat-actions`;
  const worker = new Worker(queueName, processor, {
    connection,
    concurrency: 50,
  });
}
```

> **Tradeoff**: Event loop concurrency means I/O-bound jobs scale well but CPU-bound jobs need worker threads.

</tab>
</tabs>

For stronger isolation, use separate Redis databases per shard (0-15) or separate Redis instances entirely. Queue name prefixing is the lightest-weight approach and is sufficient for most game server topologies where shards share infrastructure but need logical separation.

## 11.7. Production Configuration

### Recommended Settings

| Setting | Elixir | Go | Node.js |
|---------|--------|-----|---------|
| **Pool size** | `pool_size: 10` (NimblePool) | `PoolSize: 10 * NumCPU` (go-redis default) | 1 per class (ioredis) |
| **Lock duration** | 30,000 ms | `LockDuration: 30s` | `lockDuration: 30000` |
| **Heartbeat interval** | lock_duration / 2 | `HeartbeatInterval: 15s` | Auto (lockDuration / 2) |
| **Stalled check** | 30,000 ms | `StalledCheckInterval: 30s` | `stalledInterval: 30000` |
| **Max attempts** | 3 | `MaxAttempts: 3` | `attempts: 3` |
| **Concurrency** | 50-500 (BEAM handles thousands; ideal for combat queues) | 10-100 (goroutine overhead; tunable per queue) | 5-50 (event loop bound; use worker threads for CPU-heavy) |
| **Shutdown timeout** | Supervisor timeout | `ShutdownTimeout: 30s` | `drainDelay: 30` |
| **Events max length** | ~10,000 | `EventsMaxLen: 10000` | `maxLenEvents: 10000` |

### Connection Timeouts

| Timeout | Purpose | Recommended |
|---------|---------|-------------|
| **Connect timeout** | Initial TCP handshake | 5s |
| **Read timeout** | Waiting for Redis response | 3s |
| **Write timeout** | Sending command to Redis | 3s |
| **Pool timeout** | Waiting for available connection | 30s |

### Memory Policy

Verify your Redis instance is configured correctly:

```bash
redis-cli CONFIG GET maxmemory-policy
# Must return: "noeviction"

redis-cli CONFIG GET maxmemory
# Set appropriately for your workload
```

## 11.8. Health Checks

For a game server, Redis health directly impacts player experience. A stalled Redis connection means combat actions pile up, matchmaking freezes, and players experience lag spikes. Monitor Redis connectivity as part of your game server's readiness probe.

<tabs>
<tab title="Elixir">

```elixir
defmodule Arena.RedisHealth do
  @doc "Basic liveness check for game server readiness probe."
  def check(conn \\ :echomq_redis) do
    case EchoMQ.RedisConnection.command(conn, ["PING"]) do
      {:ok, "PONG"} -> :healthy
      {:error, reason} -> {:unhealthy, reason}
    end
  end

  @doc "Latency-aware check — flag if Redis RTT exceeds game tick budget."
  def check_with_latency(conn \\ :echomq_redis) do
    start = System.monotonic_time(:millisecond)
    case EchoMQ.RedisConnection.command(conn, ["PING"]) do
      {:ok, "PONG"} ->
        latency = System.monotonic_time(:millisecond) - start
        {:healthy, latency_ms: latency}
      {:error, reason} ->
        {:unhealthy, reason}
    end
  end
end
```

> **Benefit**: `{:error, reason}` tuples enforce explicit error handling — no silent exception swallowing.

</tab>
<tab title="Go">

```go
import (
    "context"
    "time"
)

func healthCheck(client redis.Cmdable) error {
    ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
    defer cancel()
    return client.Ping(ctx).Err()
}

func healthCheckWithLatency(client redis.Cmdable) (time.Duration, error) {
    ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
    defer cancel()

    start := time.Now()
    err := client.Ping(ctx).Err()
    return time.Since(start), err
}
```

> **Benefit**: Returned `error` values make every failure path visible in the code flow.

</tab>
<tab title="Node.js">

```typescript
async function healthCheck(connection: IORedis): Promise<boolean> {
  try {
    const result = await connection.ping();
    return result === 'PONG';
  } catch {
    return false;
  }
}

async function healthCheckWithLatency(connection: IORedis) {
  const start = Date.now();
  try {
    await connection.ping();
    return { healthy: true, latencyMs: Date.now() - start };
  } catch (err) {
    return { healthy: false, error: err };
  }
}
```

> **Tradeoff**: Uncaught Promise rejections can crash the process — requires global `unhandledRejection` handler.

</tab>
</tabs>

For production game servers, run health checks on a periodic timer (every 10-30 seconds) and expose the results via your application's readiness endpoint. Redis latency above 10ms on a local network or above 50ms on cloud deployments typically indicates a problem worth investigating — for real-time game queues like `combat-actions`, sustained latency above 20ms can degrade player experience during peak combat encounters.

## 11.9. What's Next

- **[Architecture Overview](ch10-architecture-overview.md)** — How each language implements the shared protocol
- **[Elixir OTP Architecture](ch04-elixir-architecture.md)** — Supervision trees and BEAM advantages
- **[Go Implementation](ch05-go-architecture.md)** — Struct-based design and goroutine concurrency
- **[Cross-Language Interoperability](ch06-cross-language-interop.md)** — Feature matrix and testing strategy

---

*Previous: [Architecture Overview](ch10-architecture-overview.md) | Next: [Jobs Overview](ch12-jobs-overview.md)*
