# Chapter 25. Rate Limiting

Rate limiting controls how many jobs a queue processes within a given time window. In game servers, unchecked throughput can overwhelm external APIs (Telegram bot notifications, payment gateways, analytics endpoints), trigger upstream rate limits, or degrade service for other tenants. EchoMQ provides rate limiting at two levels: **worker-level** (configured at worker startup) and **queue-level** (set dynamically at runtime). Both are enforced globally across all workers for a queue through Redis-backed counters, not per-worker in-memory state.

## 25.1. How Rate Limiting Works

EchoMQ's rate limiter uses a Redis key (`bull:{queue}:limiter`) to track job activations within a sliding time window. When a worker calls the `moveToActive` Lua script to fetch the next job, the script checks this counter:

1. If the counter is below `max`, the job is activated and the counter increments
2. If the counter has reached `max`, the script returns a rate limit delay instead of a job
3. The worker pauses fetching for the delay duration, then retries

Because this check happens inside a Lua script (atomic Redis execution), the limit is enforced globally regardless of how many worker instances connect to the queue.

```
Rate Limit Flow (max: 25, duration: 1000ms)

  Worker A               Redis                Worker B
     |                     |                     |
     |-- moveToActive ---->|                     |
     |   counter: 24/25    |                     |
     |<-- job #24 ---------|                     |
     |                     |<-- moveToActive ----|
     |                     |   counter: 25/25    |
     |                     |--- job #25 -------->|
     |                     |                     |
     |-- moveToActive ---->|                     |
     |   counter: 25/25    |                     |
     |<-- delay: 450ms ----|  (limit reached)    |
     |                     |                     |
     |   (waits 450ms)     |                     |
     |                     |  (window resets)     |
     |-- moveToActive ---->|                     |
     |   counter: 1/25     |                     |
     |<-- job #26 ---------|                     |
```

## 25.2. Worker-Level Rate Limiting

Configure a rate limiter when creating a worker. The `max` and `duration` parameters define the ceiling: at most `max` jobs activated within any `duration` millisecond window.

<tabs>
<tab title="Elixir">

```elixir
# Telegram bot notifications: 25 messages per second (Telegram API limit)
{:ok, worker} = EchoMQ.Worker.start_link(
  queue: "telegram-notifications",
  connection: :arena_redis,
  processor: &Arena.Notifications.send_telegram/1,
  concurrency: 10,
  limiter: %{max: 25, duration: 1_000}
)
```

The `limiter` option accepts a map with two keys:

| Key | Type | Description |
|-----|------|-------------|
| `:max` | integer | Maximum jobs activated per window |
| `:duration` | integer | Window size in milliseconds |

When the limit is reached, the worker receives a `rate_limit_delay` from the `moveToActive` Lua script and schedules a retry after the delay. The worker emits a `[:echomq, :rate_limit, :hit]` telemetry event with the delay duration.

> **Benefit**: `:telemetry.attach` adds zero-cost instrumentation — events are no-ops when unhandled.

</tab>
<tab title="Go">

```go
// Feature: Worker Rate Limiter (max jobs per duration)
//
// Not yet implemented in echomq-go. BullMQ's rate limiter is enforced
// in the moveToActive Lua script — it checks a Redis key
// (bull:{queue}:limiter) and delays job activation when the limit
// is exceeded. Go's worker_impl.go does not pass limiter options.
//
// Workaround:
//   Use golang.org/x/time/rate for local rate limiting:
//     limiter := rate.NewLimiter(rate.Every(time.Second/25), 25)
//     // In processor:
//     limiter.Wait(ctx)  // blocks until token available
//
//   For global (cross-worker) limiting, use a Redis-based token bucket:
//     EVALSHA <token_bucket_script> 1 "bull:{queue}:limiter" <max> <duration>
//
// Reference: Ch 17 Worker Patterns — Protocol Gap Summary Table (GAP-005)

// Local rate limiting with golang.org/x/time/rate
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
    "golang.org/x/time/rate"
)

func main() {
    ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt)
    defer cancel()

    rdb := redis.NewClient(&redis.Options{Addr: "localhost:6379"})

    // 25 notifications per second — local to this worker instance
    limiter := rate.NewLimiter(rate.Every(time.Second/25), 25)

    worker := echomq.NewWorker("telegram-notifications", rdb, echomq.WorkerOptions{
        Concurrency: 10,
    })

    worker.Process(func(job *echomq.Job) (interface{}, error) {
        // Block until rate limiter allows
        if err := limiter.Wait(ctx); err != nil {
            return nil, err
        }
        return sendTelegramNotification(job.Data)
    })

    if err := worker.Start(ctx); err != nil {
        log.Fatal(err)
    }
}
```

The local workaround limits per-worker, not globally. With 3 workers each at 25/sec, total throughput is 75/sec. For true global limiting, use Elixir or Node.js workers on this queue, or implement a Redis-based token bucket in your processor.

> **Benefit**: Goroutine-per-job with semaphore-based limiting achieves OS-level parallelism.

</tab>
<tab title="Node.js">

```typescript
import { Worker, Job } from "bullmq";

// Telegram bot notifications: 25 messages per second
const worker = new Worker(
  "telegram-notifications",
  async (job: Job) => {
    const { player_id, message, chat_id } = job.data;
    const response = await sendTelegramMessage(chat_id, message);
    return { delivered: true, messageId: response.message_id };
  },
  {
    connection: { host: "localhost", port: 6379 },
    concurrency: 10,
    limiter: {
      max: 25,
      duration: 1000,  // 25 per second
    },
  }
);
```

> **Tradeoff**: Event loop concurrency means I/O-bound jobs scale well but CPU-bound jobs need worker threads.

</tab>
</tabs>

## 25.3. Global Semantics

The rate limiter is **global across all workers** for a queue. This is a critical distinction from per-worker concurrency limits. If you run 5 workers with `limiter: %{max: 25, duration: 1000}`, the queue processes at most 25 jobs per second total, not 125.

<tabs>
<tab title="Elixir">

```elixir
# All three workers share the SAME Redis-backed rate limit counter.
# Total throughput: 25 msg/sec, NOT 75.
for i <- 1..3 do
  EchoMQ.Worker.start_link(
    name: :"telegram_worker_#{i}",
    queue: "telegram-notifications",
    connection: :arena_redis,
    processor: &Arena.Notifications.send_telegram/1,
    concurrency: 10,
    limiter: %{max: 25, duration: 1_000}
  )
end
```

This is because the limiter counter lives in Redis at `bull:telegram-notifications:limiter`, not in the worker process. The `moveToActive` Lua script atomically increments and checks this shared counter on every job fetch. When worker A activates the 25th job, workers B and C both receive a delay response on their next fetch attempt.

> **Benefit**: BEAM processes provide true preemptive concurrency — one slow job cannot starve others.

</tab>
<tab title="Go">

```go
// Feature: Global Rate Limiter
//
// Not yet implemented in echomq-go. The rate limiter is enforced in the
// moveToActive Lua script via a shared Redis key (bull:{queue}:limiter).
// All workers — regardless of runtime — share this counter.
//
// Workaround:
//   For global cross-worker limiting, use a Redis-based counter directly:
//
//     func checkGlobalLimit(ctx context.Context, rdb *redis.Client, queue string, max int, duration time.Duration) bool {
//         key := fmt.Sprintf("bull:%s:limiter", queue)
//         count, _ := rdb.Incr(ctx, key).Result()
//         if count == 1 {
//             rdb.PExpire(ctx, key, duration)
//         }
//         return count <= int64(max)
//     }
//
// Reference: Ch 17 Worker Patterns — Protocol Gap Summary Table (GAP-005)
```

> **Benefit**: Rate limit config is declarative — the Lua script enforces limits atomically in Redis.

</tab>
<tab title="Node.js">

```typescript
import { Worker, Job } from "bullmq";

// All three workers share the same rate limit counter in Redis.
// Total throughput: 25 msg/sec across all workers combined.
for (let i = 0; i < 3; i++) {
  new Worker(
    "telegram-notifications",
    async (job: Job) => {
      return await sendTelegramMessage(job.data.chat_id, job.data.message);
    },
    {
      connection: { host: "localhost", port: 6379 },
      concurrency: 10,
      limiter: {
        max: 25,
        duration: 1000,
      },
    }
  );
}
```

> **Tradeoff**: Event loop concurrency means I/O-bound jobs scale well but CPU-bound jobs need worker threads.

</tab>
</tabs>

## 25.4. Queue-Level Rate Limiting

Set a rate limit on the queue itself at runtime, independent of worker configuration. This is useful for dynamically adjusting throughput without restarting workers.

<tabs>
<tab title="Elixir">

```elixir
# Set a global rate limit: max 5 payment API calls per second
:ok = EchoMQ.Queue.set_global_rate_limit("payment-transactions", 5, 1_000,
  connection: :arena_redis
)

# Read current rate limit configuration
{:ok, config} = EchoMQ.Queue.get_global_rate_limit("payment-transactions",
  connection: :arena_redis
)
# config => %{max: 5, duration: 1000}

# Check if the queue is currently rate-limited (TTL remaining)
{:ok, ttl} = EchoMQ.Queue.get_rate_limit_ttl("payment-transactions",
  connection: :arena_redis
)
case ttl do
  0 -> IO.puts("Queue is accepting jobs")
  ms -> IO.puts("Queue paused for #{ms}ms — payment API cooling down")
end
```

Queue-level rate limits are stored in the queue's metadata hash in Redis. They are enforced alongside worker-level limits: both must allow activation for a job to proceed.

> **Benefit**: `Ecto.Multi` composes the enqueue step into the database transaction — atomic commit or rollback.

</tab>
<tab title="Go">

```go
// Feature: Queue-Level Rate Limiting
//
// Not yet implemented in echomq-go. BullMQ stores queue-level rate
// limits in the meta hash (bull:{queue}:meta) with "max" and "duration"
// fields. The moveToActive Lua script checks both worker-level and
// queue-level limits before activating a job.
//
// Workaround:
//   Set the rate limit directly in Redis (compatible with Elixir/Node.js workers):
//     rdb.HSet(ctx, "bull:payment-transactions:meta", "max", 5, "duration", 1000)
//
//   Read current config:
//     vals, _ := rdb.HMGet(ctx, "bull:payment-transactions:meta", "max", "duration").Result()
//
// Reference: Ch 17 Worker Patterns — Protocol Gap Summary Table (GAP-005)
```

> **Tradeoff**: Enqueue happens after `tx.Commit()` — a crash between commit and enqueue requires recovery.

</tab>
<tab title="Node.js">

```typescript
import { Queue } from "bullmq";

const paymentQueue = new Queue("payment-transactions", {
  connection: { host: "localhost", port: 6379 },
});

// Set a global rate limit: max 5 payment API calls per second
await paymentQueue.setGlobalRateLimit(5, 1000);

// Read current rate limit configuration
const config = await paymentQueue.getGlobalRateLimit();
// config => { max: 5, duration: 1000 }

// Check if the queue is currently rate-limited
const ttl = await paymentQueue.getRateLimitTtl();
if (ttl > 0) {
  console.log(`Queue paused for ${ttl}ms — payment API cooling down`);
}
```

> **Tradeoff**: Redis enqueue is outside the database transaction boundary — requires saga or outbox pattern.

</tab>
</tabs>

## 25.5. Manual Rate Limiting (429 Handling)

External APIs enforce their own rate limits and respond with HTTP 429 (Too Many Requests). When your processor receives a 429, you can signal EchoMQ to pause the entire queue for a cooldown period. The job moves back to the delayed set and the queue stops activating new jobs for the specified duration.

<tabs>
<tab title="Elixir">

```elixir
defmodule Arena.PaymentProcessor do
  @moduledoc "Processes microtransaction payments with 429 retry-after handling"

  def process(%EchoMQ.Job{name: "purchase-item", data: data} = job) do
    player_id = data["player_id"]
    item_id = data["item_id"]
    amount = data["amount_cents"]

    case Arena.PaymentGateway.charge(player_id, item_id, amount) do
      {:ok, receipt} ->
        {:ok, %{receipt_id: receipt.id, item_id: item_id, charged: amount}}

      {:error, %{status: 429, headers: headers}} ->
        # Parse Retry-After header (seconds) and convert to milliseconds
        retry_after_ms = parse_retry_after(headers)

        # Rate limit the queue — all workers pause for this duration
        EchoMQ.Worker.rate_limit(job, retry_after_ms)

        # Return :rate_limit to move this job back to delayed
        {:rate_limit, retry_after_ms}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp parse_retry_after(headers) do
    case List.keyfind(headers, "retry-after", 0) do
      {_, seconds} -> String.to_integer(seconds) * 1_000
      nil -> 5_000  # Default 5 second cooldown
    end
  end
end
```

The `{:rate_limit, ms}` return value is a special processor result (alongside `{:ok, _}`, `{:error, _}`, and `{:delay, _}`). It moves the job to the delayed set and writes the rate limit delay to the `bull:{queue}:limiter` key. All workers on the queue will see this delay on their next `moveToActive` call.

> **Benefit**: `Ecto.Multi` composes the enqueue step into the database transaction — atomic commit or rollback.

</tab>
<tab title="Go">

```go
// Feature: Manual Rate Limiting (Worker.rateLimit)
//
// Not yet implemented in echomq-go. BullMQ's manual rate limiting
// sets the bull:{queue}:limiter key with a TTL, causing all workers
// to pause job activation until the TTL expires.
//
// Workaround:
//   Set the limiter key directly in your processor when you receive a 429:
//
//     func rateLimitQueue(ctx context.Context, rdb *redis.Client, queue string, delayMs int) error {
//         key := fmt.Sprintf("bull:%s:limiter", queue)
//         pipe := rdb.Pipeline()
//         pipe.Set(ctx, key, "1", time.Duration(delayMs)*time.Millisecond)
//         _, err := pipe.Exec(ctx)
//         return err
//     }
//
// Reference: Ch 17 Worker Patterns — Protocol Gap Summary Table (GAP-005)

worker.Process(func(job *echomq.Job) (interface{}, error) {
    playerID := job.Data["player_id"].(string)
    itemID := job.Data["item_id"].(string)
    amount := int(job.Data["amount_cents"].(float64))

    receipt, err := chargePayment(playerID, itemID, amount)
    if err != nil {
        // Check for 429 rate limit response
        if apiErr, ok := err.(*APIError); ok && apiErr.StatusCode == 429 {
            retryAfter := apiErr.RetryAfterMs()
            // Set the limiter key directly in Redis
            rateLimitQueue(ctx, rdb, "payment-transactions", retryAfter)
            // Return a transient error so the job retries
            return nil, fmt.Errorf("rate limited for %dms: %w", retryAfter, err)
        }
        return nil, err
    }

    return map[string]interface{}{
        "receipt_id": receipt.ID, "item_id": itemID, "charged": amount,
    }, nil
})
```

> **Tradeoff**: Enqueue happens after `tx.Commit()` — a crash between commit and enqueue requires recovery.

</tab>
<tab title="Node.js">

```typescript
import { Worker, Job } from "bullmq";

const worker = new Worker(
  "payment-transactions",
  async (job: Job) => {
    const { player_id, item_id, amount_cents } = job.data;

    try {
      const receipt = await chargePayment(player_id, item_id, amount_cents);
      return { receipt_id: receipt.id, item_id, charged: amount_cents };
    } catch (err) {
      if (err.status === 429) {
        // Parse Retry-After header (seconds -> milliseconds)
        const retryAfter = (parseInt(err.headers["retry-after"]) || 5) * 1000;

        // Rate limit the queue — all workers pause
        await worker.rateLimit(retryAfter);

        // Throw RateLimitError to move this job back to delayed
        throw Worker.RateLimitError();
      }
      throw err;
    }
  },
  {
    connection: { host: "localhost", port: 6379 },
    concurrency: 5,
    limiter: {
      max: 5,
      duration: 1000,  // Pre-emptive: max 5 req/sec
    },
  }
);
```

Node.js uses a throw-based pattern: call `worker.rateLimit(ms)` to set the delay, then throw `Worker.RateLimitError()` to signal the framework. Elixir uses a return-based pattern: return `{:rate_limit, ms}` from the processor.

> **Tradeoff**: Redis enqueue is outside the database transaction boundary — requires saga or outbox pattern.

</tab>
</tabs>

### Rate Limit Flow Diagram

```
Player buys item --> Job enqueued
     |
     v
+--------------------+
| Worker fetches job  |
| (moveToActive Lua)  |
+--------------------+
     |
     v
+--------------------+
| Processor calls     |
| Payment Gateway API |
+--------------------+
     |
     +--- 200 OK ---------> {:ok, receipt}  --> Job completed
     |
     +--- 429 Too Many ---> Parse Retry-After header
                             |
                             v
                    +------------------------+
                    | rate_limit(job, 5000)   |
                    | {:rate_limit, 5000}     |
                    +------------------------+
                             |
                             v
                    +------------------------+
                    | Job -> delayed set      |
                    | Limiter key TTL = 5s    |
                    | ALL workers pause       |
                    +------------------------+
                             |
                             v  (5 seconds later)
                    +------------------------+
                    | Limiter key expires     |
                    | Workers resume fetching |
                    | Job re-activated        |
                    +------------------------+
```

## 25.6. Checking Rate Limit Status

Query whether a queue is currently paused due to rate limiting. This is useful for dashboards and health checks.

<tabs>
<tab title="Elixir">

```elixir
defmodule Arena.RateLimitMonitor do
  @moduledoc "Monitors rate limit status for game server queues"

  @queues ["telegram-notifications", "payment-transactions", "analytics-events"]

  def check_all do
    Enum.map(@queues, fn queue ->
      {:ok, ttl} = EchoMQ.Queue.get_rate_limit_ttl(queue, connection: :arena_redis)

      status = if ttl > 0, do: "limited (#{ttl}ms remaining)", else: "active"
      {queue, status}
    end)
  end

  def wait_for_clearance(queue) do
    case EchoMQ.Queue.get_rate_limit_ttl(queue, connection: :arena_redis) do
      {:ok, 0} ->
        :ok

      {:ok, ttl} ->
        Process.sleep(ttl)
        wait_for_clearance(queue)
    end
  end
end
```

> **Benefit**: `Ecto.Multi` composes the enqueue step into the database transaction — atomic commit or rollback.

</tab>
<tab title="Go">

```go
// Check rate limit TTL directly via Redis
func getRateLimitTTL(ctx context.Context, rdb *redis.Client, queue string) (time.Duration, error) {
    key := fmt.Sprintf("bull:%s:limiter", queue)
    ttl, err := rdb.PTTL(ctx, key).Result()
    if err != nil {
        return 0, err
    }
    // PTTL returns -2 if key doesn't exist, -1 if no TTL
    if ttl < 0 {
        return 0, nil
    }
    return ttl, nil
}

// Usage in health check
queues := []string{"telegram-notifications", "payment-transactions", "analytics-events"}
for _, queue := range queues {
    ttl, err := getRateLimitTTL(ctx, rdb, queue)
    if err != nil {
        log.Printf("[%s] error checking rate limit: %v", queue, err)
        continue
    }
    if ttl > 0 {
        fmt.Printf("[%s] rate limited for %v\n", queue, ttl)
    } else {
        fmt.Printf("[%s] active\n", queue)
    }
}
```

> **Tradeoff**: Enqueue happens after `tx.Commit()` — a crash between commit and enqueue requires recovery.

</tab>
<tab title="Node.js">

```typescript
import { Queue } from "bullmq";

const queues = ["telegram-notifications", "payment-transactions", "analytics-events"];

async function checkAllRateLimits() {
  for (const name of queues) {
    const queue = new Queue(name, {
      connection: { host: "localhost", port: 6379 },
    });

    const ttl = await queue.getRateLimitTtl();
    const status = ttl > 0 ? `limited (${ttl}ms remaining)` : "active";
    console.log(`[${name}] ${status}`);

    await queue.close();
  }
}
```

> **Tradeoff**: Redis enqueue is outside the database transaction boundary — requires saga or outbox pattern.

</tab>
</tabs>

## 25.7. Removing Rate Limits

Clear an active rate limit to immediately resume job processing. This is useful when an external API recovers earlier than expected or during manual intervention.

<tabs>
<tab title="Elixir">

```elixir
# Remove rate limit — workers resume immediately
:ok = EchoMQ.Queue.remove_rate_limit_key("payment-transactions",
  connection: :arena_redis
)

# Also remove the queue-level rate limit configuration
:ok = EchoMQ.Queue.remove_global_rate_limit("payment-transactions",
  connection: :arena_redis
)
```

`remove_rate_limit_key/2` deletes the `bull:{queue}:limiter` key, allowing workers to fetch jobs on their next poll. `remove_global_rate_limit/2` clears the rate limit configuration from the queue metadata, preventing the limit from being re-applied on subsequent activations.

> **Benefit**: `Ecto.Multi` composes the enqueue step into the database transaction — atomic commit or rollback.

</tab>
<tab title="Go">

```go
// Remove rate limit directly via Redis
func removeRateLimit(ctx context.Context, rdb *redis.Client, queue string) error {
    key := fmt.Sprintf("bull:%s:limiter", queue)
    return rdb.Del(ctx, key).Err()
}

// Remove queue-level rate limit configuration from metadata
func removeGlobalRateLimit(ctx context.Context, rdb *redis.Client, queue string) error {
    metaKey := fmt.Sprintf("bull:%s:meta", queue)
    return rdb.HDel(ctx, metaKey, "max", "duration").Err()
}

// Usage
removeRateLimit(ctx, rdb, "payment-transactions")
removeGlobalRateLimit(ctx, rdb, "payment-transactions")
```

> **Tradeoff**: Enqueue happens after `tx.Commit()` — a crash between commit and enqueue requires recovery.

</tab>
<tab title="Node.js">

```typescript
import { Queue } from "bullmq";

const queue = new Queue("payment-transactions", {
  connection: { host: "localhost", port: 6379 },
});

// Remove active rate limit — workers resume immediately
await queue.removeRateLimitKey();

// Remove queue-level rate limit configuration
await queue.removeGlobalRateLimit();
```

> **Tradeoff**: Redis enqueue is outside the database transaction boundary — requires saga or outbox pattern.

</tab>
</tabs>

## 25.8. Patterns

### API Rate Limit Compliance

Combine a pre-emptive worker limiter with reactive 429 handling for robust API compliance. The worker limiter prevents most 429s; the manual rate limit handles the ones that slip through under burst conditions.

<tabs>
<tab title="Elixir">

```elixir
defmodule Arena.AnalyticsProcessor do
  @moduledoc "Sends game events to external analytics (50 events/sec limit)"

  def start_worker do
    EchoMQ.Worker.start_link(
      queue: "analytics-events",
      connection: :arena_redis,
      processor: &process/1,
      concurrency: 20,
      # Pre-emptive: stay under the 50/sec API limit
      limiter: %{max: 50, duration: 1_000}
    )
  end

  def process(%EchoMQ.Job{data: data} = job) do
    event = %{
      event: data["event_type"],
      player_id: data["player_id"],
      properties: data["properties"],
      timestamp: data["timestamp"]
    }

    case Arena.Analytics.Client.track(event) do
      {:ok, _} ->
        {:ok, :tracked}

      {:error, %{status: 429, headers: headers}} ->
        retry_after = parse_retry_after(headers)
        EchoMQ.Worker.rate_limit(job, retry_after)
        {:rate_limit, retry_after}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp parse_retry_after(headers) do
    case List.keyfind(headers, "retry-after", 0) do
      {_, seconds} -> String.to_integer(seconds) * 1_000
      nil -> 2_000
    end
  end
end
```

> **Benefit**: BEAM processes provide true preemptive concurrency — one slow job cannot starve others.

</tab>
<tab title="Go">

```go
// Analytics events: 50/sec to external analytics endpoint
//
// Pre-emptive local limiter + reactive 429 handling
limiter := rate.NewLimiter(rate.Every(time.Second/50), 50)

worker := echomq.NewWorker("analytics-events", rdb, echomq.WorkerOptions{
    Concurrency: 20,
})

worker.Process(func(job *echomq.Job) (interface{}, error) {
    // Pre-emptive: local token bucket
    if err := limiter.Wait(ctx); err != nil {
        return nil, err
    }

    event := map[string]interface{}{
        "event":      job.Data["event_type"],
        "player_id":  job.Data["player_id"],
        "properties": job.Data["properties"],
        "timestamp":  job.Data["timestamp"],
    }

    err := trackAnalyticsEvent(event)
    if err != nil {
        if apiErr, ok := err.(*APIError); ok && apiErr.StatusCode == 429 {
            retryAfter := apiErr.RetryAfterMs()
            rateLimitQueue(ctx, rdb, "analytics-events", retryAfter)
            return nil, fmt.Errorf("analytics rate limited: %w", err)
        }
        return nil, err
    }

    return map[string]interface{}{"tracked": true}, nil
})
```

> **Benefit**: Goroutine-per-job with semaphore-based limiting achieves OS-level parallelism.

</tab>
<tab title="Node.js">

```typescript
import { Worker, Job } from "bullmq";

const worker = new Worker(
  "analytics-events",
  async (job: Job) => {
    const event = {
      event: job.data.event_type,
      player_id: job.data.player_id,
      properties: job.data.properties,
      timestamp: job.data.timestamp,
    };

    try {
      await trackAnalyticsEvent(event);
      return { tracked: true };
    } catch (err) {
      if (err.status === 429) {
        const retryAfter = (parseInt(err.headers["retry-after"]) || 2) * 1000;
        await worker.rateLimit(retryAfter);
        throw Worker.RateLimitError();
      }
      throw err;
    }
  },
  {
    connection: { host: "localhost", port: 6379 },
    concurrency: 20,
    // Pre-emptive: stay under the 50/sec API limit
    limiter: {
      max: 50,
      duration: 1000,
    },
  }
);
```

> **Tradeoff**: Event loop concurrency means I/O-bound jobs scale well but CPU-bound jobs need worker threads.

</tab>
</tabs>

### Tiered Rate Limiting

Use separate queues with different rate limits for premium and standard players. Premium players get higher throughput for matchmaking, notifications, and API calls.

<tabs>
<tab title="Elixir">

```elixir
# Premium matchmaking: 1000 matches/min — fast queue times
{:ok, _} = EchoMQ.Worker.start_link(
  queue: "matchmaking-premium",
  connection: :arena_redis,
  processor: &Arena.Matchmaking.process/1,
  concurrency: 50,
  limiter: %{max: 1_000, duration: 60_000}
)

# Standard matchmaking: 100 matches/min — fair-use tier
{:ok, _} = EchoMQ.Worker.start_link(
  queue: "matchmaking-standard",
  connection: :arena_redis,
  processor: &Arena.Matchmaking.process/1,
  concurrency: 10,
  limiter: %{max: 100, duration: 60_000}
)

# Route jobs to the correct queue based on player tier
def enqueue_matchmaking(player_id, rank) do
  player = Arena.Players.get!(player_id)
  queue = if player.tier == :premium, do: "matchmaking-premium", else: "matchmaking-standard"

  EchoMQ.Queue.add(queue, "find-match", %{
    "player_id" => player_id,
    "rank" => rank,
    "tier" => to_string(player.tier)
  }, connection: :arena_redis)
end
```

> **Benefit**: BEAM processes provide true preemptive concurrency — one slow job cannot starve others.

</tab>
<tab title="Go">

```go
// Tiered matchmaking with local rate limiters
//
// Premium: 1000/min, Standard: 100/min
premiumLimiter := rate.NewLimiter(rate.Every(time.Minute/1000), 50)
standardLimiter := rate.NewLimiter(rate.Every(time.Minute/100), 10)

premiumWorker := echomq.NewWorker("matchmaking-premium", rdb, echomq.WorkerOptions{
    Concurrency: 50,
})
premiumWorker.Process(func(job *echomq.Job) (interface{}, error) {
    if err := premiumLimiter.Wait(ctx); err != nil {
        return nil, err
    }
    return findMatch(job.Data)
})

standardWorker := echomq.NewWorker("matchmaking-standard", rdb, echomq.WorkerOptions{
    Concurrency: 10,
})
standardWorker.Process(func(job *echomq.Job) (interface{}, error) {
    if err := standardLimiter.Wait(ctx); err != nil {
        return nil, err
    }
    return findMatch(job.Data)
})
```

> **Benefit**: Goroutine-per-job with semaphore-based limiting achieves OS-level parallelism.

</tab>
<tab title="Node.js">

```typescript
import { Worker, Queue, Job } from "bullmq";

const connection = { host: "localhost", port: 6379 };

// Premium matchmaking: 1000 matches/min
const premiumWorker = new Worker(
  "matchmaking-premium",
  async (job: Job) => findMatch(job.data),
  {
    connection,
    concurrency: 50,
    limiter: { max: 1000, duration: 60000 },
  }
);

// Standard matchmaking: 100 matches/min
const standardWorker = new Worker(
  "matchmaking-standard",
  async (job: Job) => findMatch(job.data),
  {
    connection,
    concurrency: 10,
    limiter: { max: 100, duration: 60000 },
  }
);

// Route based on player tier
async function enqueueMatchmaking(playerId: string, rank: number, tier: string) {
  const queueName = tier === "premium" ? "matchmaking-premium" : "matchmaking-standard";
  const queue = new Queue(queueName, { connection });
  await queue.add("find-match", { player_id: playerId, rank, tier });
}
```

> **Tradeoff**: Event loop concurrency means I/O-bound jobs scale well but CPU-bound jobs need worker threads.

</tab>
</tabs>

### Chat Spam Protection

Rate limit chat messages per player using a processor-level Redis counter. This prevents a single player from flooding the chat channel while allowing normal conversation flow.

<tabs>
<tab title="Elixir">

```elixir
defmodule Arena.ChatProcessor do
  @moduledoc "Processes chat messages with per-player spam protection (10 msg/10s)"

  @max_per_player 10
  @window_ms 10_000

  def process(%EchoMQ.Job{data: data} = job) do
    player_id = data["player_id"]
    message = data["message"]
    channel = data["channel"]

    # Per-player rate check using a Redis counter
    case check_player_rate(player_id) do
      :ok ->
        Arena.Chat.broadcast(channel, player_id, message)
        {:ok, %{delivered: true, channel: channel}}

      {:rate_limited, ttl} ->
        # Don't retry — just drop and notify
        Arena.Chat.notify_player(player_id, "Slow down! Wait #{div(ttl, 1000)}s.")
        {:ok, %{delivered: false, reason: "spam_protection", cooldown_ms: ttl}}
    end
  end

  defp check_player_rate(player_id) do
    # player_id is already a branded ID, e.g. "PLR0K48QjihpC4"
    # Key: "arena:chat:rate:PLR0K48QjihpC4"
    key = "arena:chat:rate:#{player_id}"

    case Redix.pipeline(:arena_redis, [
      ["INCR", key],
      ["PTTL", key]
    ]) do
      {:ok, [count, ttl]} ->
        if count == 1, do: Redix.command(:arena_redis, ["PEXPIRE", key, @window_ms])
        if count > @max_per_player, do: {:rate_limited, max(ttl, 0)}, else: :ok
    end
  end
end
```

> **Benefit**: Rate limiting uses Redis TTL keys — distributed limiting works across clustered BEAM nodes.

</tab>
<tab title="Go">

```go
// Chat spam protection: 10 messages per 10 seconds per player
const maxPerPlayer = 10
const windowMs = 10_000

worker := echomq.NewWorker("chat-messages", rdb, echomq.WorkerOptions{
    Concurrency: 20,
})

worker.Process(func(job *echomq.Job) (interface{}, error) {
    playerID := job.Data["player_id"].(string)
    message := job.Data["message"].(string)
    channel := job.Data["channel"].(string)

    // Per-player rate check
    // playerID is already a branded ID, e.g. "PLR0K48QjihpC4"
    // Key: "arena:chat:rate:PLR0K48QjihpC4"
    key := "arena:chat:rate:" + playerID
    count, err := rdb.Incr(ctx, key).Result()
    if err != nil {
        return nil, err
    }
    if count == 1 {
        rdb.PExpire(ctx, key, time.Duration(windowMs)*time.Millisecond)
    }

    if count > int64(maxPerPlayer) {
        ttl, _ := rdb.PTTL(ctx, key).Result()
        notifyPlayer(playerID, fmt.Sprintf("Slow down! Wait %ds.", int(ttl.Seconds())))
        return map[string]interface{}{
            "delivered": false, "reason": "spam_protection",
        }, nil
    }

    broadcastChat(channel, playerID, message)
    return map[string]interface{}{"delivered": true, "channel": channel}, nil
})
```

> **Benefit**: Goroutine-per-job with semaphore-based limiting achieves OS-level parallelism.

</tab>
<tab title="Node.js">

```typescript
import { Worker, Job } from "bullmq";
import Redis from "ioredis";

const MAX_PER_PLAYER = 10;
const WINDOW_MS = 10_000;

const redis = new Redis();

const worker = new Worker(
  "chat-messages",
  async (job: Job) => {
    const { player_id, message, channel } = job.data;

    // Per-player rate check
    // player_id is already a branded ID, e.g. "PLR0K48QjihpC4"
    // Key: "arena:chat:rate:PLR0K48QjihpC4"
    const key = `arena:chat:rate:${player_id}`;
    const count = await redis.incr(key);
    if (count === 1) {
      await redis.pexpire(key, WINDOW_MS);
    }

    if (count > MAX_PER_PLAYER) {
      const ttl = await redis.pttl(key);
      await notifyPlayer(player_id, `Slow down! Wait ${Math.ceil(ttl / 1000)}s.`);
      return { delivered: false, reason: "spam_protection", cooldown_ms: ttl };
    }

    await broadcastChat(channel, player_id, message);
    return { delivered: true, channel };
  },
  {
    connection: { host: "localhost", port: 6379 },
    concurrency: 20,
  }
);
```

> **Tradeoff**: Event loop concurrency means I/O-bound jobs scale well but CPU-bound jobs need worker threads.

</tab>
</tabs>

## 25.9. Telemetry Events

EchoMQ emits telemetry events when a rate limit is triggered, allowing you to monitor and alert on rate limiting activity.

<tabs>
<tab title="Elixir">

```elixir
# Attach a handler for rate limit events
:telemetry.attach(
  "arena-rate-limit-monitor",
  [:echomq, :rate_limit, :hit],
  fn _event, %{delay: delay}, %{queue: queue}, _config ->
    Logger.warning("[#{queue}] Rate limit hit — pausing for #{delay}ms")
    Arena.Metrics.increment("echomq.rate_limit.hit", tags: [queue: queue])
  end,
  nil
)

# Full telemetry setup with Prometheus
defmodule Arena.EchoMQTelemetry do
  use Supervisor

  def start_link(opts), do: Supervisor.start_link(__MODULE__, opts, name: __MODULE__)

  def init(_opts) do
    :telemetry.attach_many(
      "arena-echomq-metrics",
      [
        [:echomq, :job, :complete],
        [:echomq, :job, :fail],
        [:echomq, :rate_limit, :hit]
      ],
      &handle_event/4,
      nil
    )

    Supervisor.init([], strategy: :one_for_one)
  end

  def handle_event([:echomq, :rate_limit, :hit], %{delay: delay}, %{queue: queue}, _) do
    :telemetry.execute(
      [:arena, :rate_limit, :activated],
      %{delay_ms: delay},
      %{queue: queue}
    )
  end

  def handle_event(_, _, _, _), do: :ok
end
```

> **Benefit**: `TelemetryMetricsPrometheus` auto-generates Prometheus endpoint from `:telemetry` event definitions.

</tab>
<tab title="Go">

```go
// Go does not emit rate limit telemetry events natively.
// Monitor the limiter key TTL directly for observability.

func monitorRateLimits(ctx context.Context, rdb *redis.Client, queues []string, interval time.Duration) {
    ticker := time.NewTicker(interval)
    defer ticker.Stop()

    for {
        select {
        case <-ctx.Done():
            return
        case <-ticker.C:
            for _, queue := range queues {
                key := fmt.Sprintf("bull:%s:limiter", queue)
                ttl, err := rdb.PTTL(ctx, key).Result()
                if err != nil {
                    continue
                }
                if ttl > 0 {
                    log.Printf("[%s] rate limited for %v", queue, ttl)
                    // Emit to your metrics system
                    recordMetric("echomq_rate_limit_active", float64(ttl.Milliseconds()),
                        map[string]string{"queue": queue})
                }
            }
        }
    }
}
```

> **Benefit**: EventEmitter publishes to Redis streams — external consumers can read events without Go dependency.

</tab>
<tab title="Node.js">

```typescript
import { QueueEvents, Queue } from "bullmq";

// QueueEvents listens to the Redis event stream for rate limit events
const queueEvents = new QueueEvents("telegram-notifications", {
  connection: { host: "localhost", port: 6379 },
});

// Monitor when workers hit rate limits
queueEvents.on("waiting", ({ jobId }) => {
  // Jobs moved back to waiting due to rate limiting appear here
  console.log(`Job ${jobId} waiting (possibly rate limited)`);
});

// For explicit rate limit monitoring, poll the TTL
async function monitorRateLimits(queue: Queue, intervalMs: number) {
  setInterval(async () => {
    const ttl = await queue.getRateLimitTtl();
    if (ttl > 0) {
      console.log(`[${queue.name}] rate limited for ${ttl}ms`);
      metrics.gauge("echomq.rate_limit.ttl_ms", ttl, { queue: queue.name });
    }
  }, intervalMs);
}
```

> **Benefit**: QueueEvents wraps Redis XREAD internally — event subscription is a one-liner.

</tab>
</tabs>

## 25.10. Cross-Language Comparison

| Feature | Elixir | Go | Node.js |
|---------|--------|-----|---------|
| Worker limiter option | `limiter: %{max: n, duration: ms}` | Not implemented (use `x/time/rate`) | `limiter: { max, duration }` |
| Limiter scope | Global (Redis Lua) | Local (per-worker) | Global (Redis Lua) |
| Manual rate limit | Return `{:rate_limit, ms}` | Set Redis key directly | `worker.rateLimit(ms)` + throw |
| Queue-level config | `Queue.set_global_rate_limit/4` | Set Redis meta directly | `queue.setGlobalRateLimit()` |
| Check TTL | `Queue.get_rate_limit_ttl/2` | `PTTL` on limiter key | `queue.getRateLimitTtl()` |
| Remove limit | `Queue.remove_rate_limit_key/2` | `DEL` on limiter key | `queue.removeRateLimitKey()` |
| Telemetry | `[:echomq, :rate_limit, :hit]` | Poll limiter key | QueueEvents stream |
| Redis key | `bull:{queue}:limiter` | `bull:{queue}:limiter` | `bull:{queue}:limiter` |

All three runtimes share the same Redis key format. A rate limit set by an Elixir worker is immediately visible to Go and Node.js workers on the same queue, and vice versa. This cross-runtime compatibility is guaranteed by the shared `moveToActive` Lua script (Elixir, Node.js) and the `bull:{queue}:limiter` key convention.

---

*Previous: [Worker Concurrency](ch24-worker-concurrency.md) | Next: [Priorities](ch26-priorities.md)*
