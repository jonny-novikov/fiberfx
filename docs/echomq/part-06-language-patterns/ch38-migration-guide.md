# Chapter 38. Migration from BullMQ

> Zero-downtime migration strategies for moving from Node.js BullMQ to polyglot EchoMQ.

## 38.1. Overview

EchoMQ implements the BullMQ v5.62.0 Redis protocol exactly -- same Lua scripts, same key
structures, same job lifecycle state machine. This wire-level compatibility means you can
migrate from Node.js BullMQ to EchoMQ (Elixir, Go, or Node.js) without stopping your
existing workers. The key insight: **all three implementations read and write the same
Redis keys**, so workers in different languages can process the same queue simultaneously.

```
            ZERO-DOWNTIME MIGRATION TIMELINE
  ┌──────────────────────────────────────────────────────────────┐
  │  Phase 1: Add EchoMQ workers alongside BullMQ workers       │
  │           Both process the same Redis queue                  │
  │                                                              │
  │  Phase 2: Shift traffic -- route new jobs to EchoMQ API     │
  │           Existing BullMQ jobs drain naturally               │
  │                                                              │
  │  Phase 3: Remove BullMQ workers                              │
  │           EchoMQ handles all processing                      │
  │                                                              │
  │  Phase 4: Clean up BullMQ dependencies from package.json    │
  └──────────────────────────────────────────────────────────────┘
```

| Concern | BullMQ (Node.js) | EchoMQ (Elixir) | EchoMQ (Go) |
|---------|-------------------|------------------|-------------|
| Redis key prefix | `bull:` | `bull:` (preserved) | `bull:` (preserved) |
| Lua script version | v5.62.0 | v5.62.0 (ported) | v5.62.0 (ported) |
| Job data format | JSON | JSON | JSON |
| Lock mechanism | `bull:{queue}:{id}:lock` | Same | Same |
| State sets | `wait`, `active`, `completed`, `failed`, `delayed` | Same | Same |

---

## 38.2. Redis Key Compatibility

The foundation of zero-downtime migration is key prefix compatibility. EchoMQ preserves
the `bull:` prefix exactly as BullMQ defines it, so both systems read and write identical
Redis keys.

<tabs>
<tab title="BullMQ (Node.js)">

> **Benefit**: BullMQ's key structure is the shared protocol -- every other EchoMQ implementation targets this layout.

```typescript
import { Queue } from 'bullmq';

// BullMQ creates these Redis keys for queue "guess-processing":
//
//   bull:guess-processing:meta          -- queue metadata (HASH)
//   bull:guess-processing:id            -- job ID counter (STRING)
//   bull:guess-processing:wait          -- waiting jobs (LIST)
//   bull:guess-processing:active        -- active jobs (LIST)
//   bull:guess-processing:delayed       -- delayed jobs (ZSET)
//   bull:guess-processing:completed     -- completed jobs (ZSET)
//   bull:guess-processing:failed        -- failed jobs (ZSET)
//   bull:guess-processing:stalled-check -- stalled detection (STRING)
//   bull:guess-processing:{jobId}       -- job data (HASH)
//   bull:guess-processing:{jobId}:lock  -- job lock (STRING)

const queue = new Queue('guess-processing', {
  connection: { host: 'redis.codemoji.io', port: 6379 },
});

// Add a job -- creates bull:guess-processing:{id} hash
const job = await queue.add('validate_guess', {
  game_id: 'GAM5rK2mJ9pQ1L',
  player_id: 'PLR0K48QjihpC4',
  guess: 'ABCD',
  room_id: 'ROM8xN3vP7qR4K',
});

console.log(`Job ${job.id} added to bull:guess-processing`);
```

</tab>
<tab title="EchoMQ (Elixir)">

> **Benefit**: Elixir workers read the exact same `bull:` keys -- no data migration needed, just start the worker.

```elixir
# EchoMQ (Elixir) uses identical key prefix: "bull:"
#
# This means an Elixir worker can pick up jobs enqueued by BullMQ (Node.js)
# and vice versa -- zero-downtime migration.

# The Elixir worker connects to the same Redis and processes
# the same "bull:guess-processing" keys
{:ok, worker} = EchoMQ.Worker.start_link(
  queue: "guess-processing",
  connection: [host: "redis.codemoji.io", port: 6379],
  processor: &Codemoji.GuessProcessor.process/1,
  concurrency: 5
)

# Verify key compatibility: read a job created by BullMQ
{:ok, job_data} = EchoMQ.Queue.get_job(
  "guess-processing",
  "42",  # Job ID created by BullMQ
  connection: [host: "redis.codemoji.io", port: 6379]
)

# Job data is identical -- same JSON, same fields
IO.inspect(job_data.data)
# => %{"game_id" => "GAM5rK2mJ9pQ1L", "player_id" => "PLR0K48QjihpC4", ...}
```

</tab>
<tab title="EchoMQ (Go)">

> **Tradeoff**: Go's typed struct mapping requires explicit JSON tags matching BullMQ's camelCase field names.

```go
package main

import (
    "context"
    "fmt"

    "github.com/redis/go-redis/v9"
    "github.com/fiberfx/echomq-go/pkg/echomq"
)

func main() {
    rdb := redis.NewClient(&redis.Options{
        Addr: "redis.codemoji.io:6379",
    })
    ctx := context.Background()

    // Go EchoMQ reads the same "bull:" prefix keys
    // No configuration needed -- it's the default

    // Read a job created by BullMQ (Node.js)
    queue := echomq.NewQueue("guess-processing", rdb)
    job, err := queue.GetJob(ctx, "42") // Job ID from BullMQ
    if err != nil {
        panic(err)
    }

    // Job data is identical JSON -- same fields, same format
    fmt.Printf("Game: %s\n", job.Data["game_id"])
    // => Game: GAM5rK2mJ9pQ1L

    // Start a Go worker alongside the BullMQ worker
    worker := echomq.NewWorker("guess-processing", rdb,
        func(job *echomq.Job) (interface{}, error) {
            gameID, _ := job.Data["game_id"].(string)
            guess, _ := job.Data["guess"].(string)
            return validateGuess(gameID, guess)
        },
        echomq.WorkerOptions{Concurrency: 5},
    )

    worker.Run(ctx)
}
```

</tab>
</tabs>

---

## 38.3. Configuration Mapping

BullMQ configuration options map directly to EchoMQ equivalents. This section shows the
correspondence for the most common settings so you can translate your existing BullMQ
configuration without behavioral changes.

<tabs>
<tab title="BullMQ (Node.js)">

> **Benefit**: BullMQ configuration is the reference standard -- EchoMQ implementations mirror every option name and default value.

```typescript
import { Worker, Queue, QueueScheduler } from 'bullmq';

// --- EXISTING BullMQ configuration ---

const queue = new Queue('guess-processing', {
  connection: {
    host: 'redis.codemoji.io',
    port: 6379,
    maxRetriesPerRequest: null,
  },
  defaultJobOptions: {
    attempts: 3,
    backoff: {
      type: 'exponential',
      delay: 1000,
    },
    removeOnComplete: { count: 1000 },
    removeOnFail: { count: 5000 },
  },
});

const worker = new Worker('guess-processing', processGuess, {
  connection: {
    host: 'redis.codemoji.io',
    port: 6379,
    maxRetriesPerRequest: null,
  },
  concurrency: 10,
  limiter: {
    max: 100,
    duration: 60000, // 100 jobs per minute
  },
  lockDuration: 30000,      // 30s lock
  lockRenewTime: 15000,     // Renew every 15s
  stalledInterval: 30000,   // Check for stalled every 30s
  maxStalledCount: 1,       // Max stalls before fail
});
```

</tab>
<tab title="EchoMQ (Elixir)">

> **Benefit**: Keyword list syntax maps 1:1 with BullMQ options -- minimal cognitive overhead when porting configuration.

```elixir
# --- EQUIVALENT EchoMQ (Elixir) configuration ---

# Queue configuration
{:ok, queue} = EchoMQ.Queue.start_link(
  queue: "guess-processing",
  connection: [host: "redis.codemoji.io", port: 6379],
  default_job_options: [
    attempts: 3,
    backoff: %{type: :exponential, delay: 1_000},
    remove_on_complete: %{count: 1_000},
    remove_on_fail: %{count: 5_000}
  ]
)

# Worker configuration (mirrors BullMQ exactly)
{:ok, worker} = EchoMQ.Worker.start_link(
  queue: "guess-processing",
  connection: [host: "redis.codemoji.io", port: 6379],
  processor: &Codemoji.GuessProcessor.process/1,
  concurrency: 10,
  limiter: %{max: 100, duration: 60_000},    # 100 jobs per minute
  lock_duration: 30_000,                      # 30s lock
  lock_renew_time: 15_000,                    # Renew every 15s
  stalled_interval: 30_000,                   # Check every 30s
  max_stalled_count: 1                        # Max stalls before fail
)

# Configuration mapping reference:
#   BullMQ                    EchoMQ (Elixir)
#   ──────                    ───────────────
#   concurrency               concurrency
#   lockDuration              lock_duration
#   lockRenewTime             lock_renew_time
#   stalledInterval           stalled_interval
#   maxStalledCount           max_stalled_count
#   limiter.max               limiter.max
#   limiter.duration          limiter.duration
#   backoff.type              backoff.type (atom: :exponential, :fixed)
#   removeOnComplete          remove_on_complete
#   removeOnFail              remove_on_fail
```

</tab>
<tab title="EchoMQ (Go)">

> **Tradeoff**: Go uses struct fields instead of string keys -- type safety gained at the cost of manual option translation.

```go
package main

import (
    "time"

    "github.com/redis/go-redis/v9"
    "github.com/fiberfx/echomq-go/pkg/echomq"
)

func main() {
    rdb := redis.NewClient(&redis.Options{
        Addr: "redis.codemoji.io:6379",
    })

    // --- EQUIVALENT EchoMQ (Go) configuration ---

    // Queue with default job options
    queue := echomq.NewQueue("guess-processing", rdb,
        echomq.QueueOptions{
            DefaultJobOptions: echomq.JobOptions{
                Attempts: 3,
                Backoff: &echomq.BackoffOptions{
                    Type:  "exponential",
                    Delay: 1000,
                },
                RemoveOnComplete: &echomq.RemoveOption{Count: 1000},
                RemoveOnFail:     &echomq.RemoveOption{Count: 5000},
            },
        },
    )

    // Worker configuration (mirrors BullMQ exactly)
    worker := echomq.NewWorker("guess-processing", rdb,
        guessProcessor,
        echomq.WorkerOptions{
            Concurrency:     10,
            Limiter: &echomq.RateLimiter{
                Max:      100,
                Duration: 60 * time.Second,    // 100 jobs per minute
            },
            LockDuration:    30 * time.Second,  // 30s lock
            LockRenewTime:   15 * time.Second,  // Renew every 15s
            StalledInterval: 30 * time.Second,  // Check every 30s
            MaxStalledCount: 1,                 // Max stalls before fail
        },
    )

    // Configuration mapping reference:
    //   BullMQ                   EchoMQ (Go)
    //   ──────                   ──────────────
    //   concurrency              Concurrency
    //   lockDuration             LockDuration (time.Duration)
    //   lockRenewTime            LockRenewTime (time.Duration)
    //   stalledInterval          StalledInterval (time.Duration)
    //   maxStalledCount          MaxStalledCount
    //   limiter.max              Limiter.Max
    //   limiter.duration         Limiter.Duration (time.Duration)
    //   backoff.type             Backoff.Type (string)
    //   removeOnComplete         RemoveOnComplete
    //   removeOnFail             RemoveOnFail

    _ = queue
    _ = worker
}
```

</tab>
</tabs>

---

## 38.4. Mixed-Language Worker Fleets

During migration, you run BullMQ and EchoMQ workers simultaneously on the same queues.
This is the core mechanism that enables zero-downtime migration -- Redis's atomic Lua
scripts ensure only one worker picks up each job, regardless of which language runtime
processes it.

<tabs>
<tab title="BullMQ (Node.js)">

> **Benefit**: Existing BullMQ workers continue unchanged -- no code modifications needed during migration.

```typescript
import { Worker } from 'bullmq';

// --- EXISTING BullMQ worker (no changes needed) ---
// This worker continues to run during migration.
// It shares the Redis queue with EchoMQ workers.

const worker = new Worker(
  'guess-processing',
  async (job) => {
    const { game_id, player_id, guess } = job.data;

    // Existing processing logic -- unchanged
    const result = await validateGuess(game_id, guess);

    return {
      correct: result.correct,
      exact: result.exact,
      found: result.found,
      player_id,
    };
  },
  {
    connection: {
      host: 'redis.codemoji.io',
      port: 6379,
    },
    concurrency: 5,
  },
);

// BullMQ and EchoMQ workers compete for jobs using the same
// atomic BRPOPLPUSH / Lua scripts. Redis guarantees each job
// is delivered to exactly one worker, regardless of language.

console.log('BullMQ worker running alongside EchoMQ workers');
```

</tab>
<tab title="EchoMQ (Elixir)">

> **Benefit**: OTP supervision gives Elixir workers automatic restart and backpressure -- an upgrade over raw Node.js workers.

```elixir
# --- NEW EchoMQ worker (runs alongside BullMQ) ---
# Processes the SAME queue as the existing BullMQ worker.
# Redis atomic Lua scripts ensure no double-processing.

defmodule Codemoji.GuessWorker do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      {EchoMQ.Worker, [
        queue: "guess-processing",
        connection: [host: "redis.codemoji.io", port: 6379],
        processor: &Codemoji.GuessProcessor.process/1,
        concurrency: 5,
        # Stalled detection: compatible with BullMQ's defaults
        stalled_interval: 30_000,
        lock_duration: 30_000
      ]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end

# During migration, BOTH workers process the same queue:
#
#   BullMQ (Node.js):  5 concurrent processors
#   EchoMQ (Elixir):   5 concurrent processors
#   Total capacity:    10 concurrent processors
#
# This doubles throughput during migration -- a bonus.
# Gradually reduce BullMQ concurrency as Elixir proves stable.
```

</tab>
<tab title="EchoMQ (Go)">

> **Tradeoff**: Go workers must handle JSON field names matching BullMQ's JavaScript conventions (camelCase data, snake_case options).

```go
package main

import (
    "context"
    "fmt"
    "log"

    "github.com/redis/go-redis/v9"
    "github.com/fiberfx/echomq-go/pkg/echomq"
)

func main() {
    rdb := redis.NewClient(&redis.Options{
        Addr: "redis.codemoji.io:6379",
    })
    ctx := context.Background()

    // --- NEW EchoMQ (Go) worker alongside BullMQ ---
    // Processes the SAME "guess-processing" queue.
    // Redis Lua scripts prevent double-processing.

    worker := echomq.NewWorker("guess-processing", rdb,
        func(job *echomq.Job) (interface{}, error) {
            // Job data is the same JSON that BullMQ wrote
            gameID, _ := job.Data["game_id"].(string)
            playerID, _ := job.Data["player_id"].(string)
            guess, _ := job.Data["guess"].(string)

            result, err := validateGuess(gameID, guess)
            if err != nil {
                return nil, fmt.Errorf("validation: %w", err)
            }

            return map[string]interface{}{
                "correct":   result.Correct,
                "exact":     result.Exact,
                "found":     result.Found,
                "player_id": playerID,
            }, nil
        },
        echomq.WorkerOptions{
            Concurrency:     5,
            StalledInterval: 30_000, // Must match BullMQ setting
            LockDuration:    30_000, // Must match BullMQ setting
        },
    )

    log.Println("Go EchoMQ worker running alongside BullMQ workers")
    worker.Run(ctx)
}
```

</tab>
</tabs>

---

## 38.5. Step-by-Step Migration Path

A concrete migration plan for the codemoji game backend, moving from Node.js BullMQ
to Elixir EchoMQ. The same approach applies to any BullMQ-to-EchoMQ migration.

<tabs>
<tab title="Phase 1: Parallel Workers">

> **Benefit**: Zero risk -- if EchoMQ workers fail, BullMQ workers continue processing. No job is lost.

```
Phase 1: Add EchoMQ Workers Alongside BullMQ
─────────────────────────────────────────────
Duration: 1-2 weeks (observation period)

Step 1: Deploy Elixir EchoMQ workers for "guess-processing" queue
  - Connect to the SAME Redis instance
  - Start with concurrency: 2 (low, for observation)
  - BullMQ workers continue at full concurrency: 10

Step 2: Monitor shared metrics
  - Job completion rate (should increase -- more workers)
  - Error rate (should stay flat -- same processing logic)
  - Latency p50/p99 (should decrease -- more capacity)
  - Redis memory usage (unchanged -- same key structure)

Step 3: Gradually increase EchoMQ concurrency
  Week 1: EchoMQ concurrency 2, BullMQ concurrency 10
  Week 2: EchoMQ concurrency 5, BullMQ concurrency 5

Queue: guess-processing
├── BullMQ Worker (Node.js)   concurrency: 5  [existing]
└── EchoMQ Worker (Elixir)    concurrency: 5  [new]
```

</tab>
<tab title="Phase 2: Shift Prize Distribution">

> **Tradeoff**: OTP supervision is a clear upgrade for prize processing, but requires rewriting business logic in Elixir.

```
Phase 2: Migrate Prize Distribution to Elixir
──────────────────────────────────────────────
Duration: 1-2 weeks

Why prizes first (after guess validation):
  - Financial operations benefit from OTP's "let it crash" + supervision
  - Idempotency patterns are more natural in Elixir (tagged tuples)
  - Lower throughput than guesses -- safer for first full migration

Step 1: Deploy Elixir EchoMQ worker for "prize-distribution" queue
  - Implement PrizeDistributionProcessor in Elixir
  - Use branded IDs for idempotency (PLR0K48QjihpC4)
  - Wire OTP supervision for automatic restart

Step 2: Run parallel for 1 week
  - Both BullMQ and EchoMQ process prize-distribution
  - Compare completion rates and error rates

Step 3: Drain BullMQ prize workers
  - Set BullMQ prize worker concurrency to 0
  - Wait for in-flight jobs to complete (lockDuration window)
  - Remove BullMQ prize worker from deployment

Queue: prize-distribution
├── BullMQ Worker (Node.js)   concurrency: 0  [draining]
└── EchoMQ Worker (Elixir)    concurrency: 10 [primary]

Queue: guess-processing
├── BullMQ Worker (Node.js)   concurrency: 5  [shared]
└── EchoMQ Worker (Elixir)    concurrency: 5  [shared]
```

</tab>
<tab title="Phase 3: Keep Telegram in Node.js">

> **Benefit**: Node.js Telegram Bot API libraries are mature and well-maintained -- no reason to port.

```
Phase 3: Evaluate Telegram Notifications
─────────────────────────────────────────
Duration: Ongoing

Decision: KEEP telegram-notifications in Node.js (EchoMQ Node.js)

Rationale:
  - Telegram Bot API Node.js libraries (telegraf, grammy) are excellent
  - No business logic to port -- just API calls
  - Upgrade from BullMQ to EchoMQ (Node.js) is a package swap

Migration steps:
  1. Replace 'bullmq' import with 'echomq'
  2. No code changes needed -- API is compatible
  3. Test with existing integration tests

Queue: telegram-notifications
└── EchoMQ Worker (Node.js)   concurrency: 5  [upgraded from BullMQ]

Queue: prize-distribution
└── EchoMQ Worker (Elixir)    concurrency: 10 [migrated]

Queue: guess-processing
└── EchoMQ Worker (Elixir)    concurrency: 10 [migrated]

Final architecture:
┌──────────────────────────────────────────────────────────────┐
│                     Redis (shared)                           │
│                   bull: prefix keys                          │
├────────────────┬─────────────────┬───────────────────────────┤
│ guess-processing│ prize-distribution│ telegram-notifications  │
│ Elixir EchoMQ  │ Elixir EchoMQ    │ Node.js EchoMQ          │
│ OTP supervised │ OTP supervised   │ PM2 managed             │
└────────────────┴─────────────────┴───────────────────────────┘
```

</tab>
</tabs>

---

## 38.6. Lua Script Version Considerations

EchoMQ's polyglot protocol compatibility rests on Lua script parity. All three
implementations use the same Lua scripts (ported from BullMQ v5.62.0) to ensure
identical atomic state transitions in Redis. Understanding the script version is
critical for migration safety.

<tabs>
<tab title="BullMQ (Node.js)">

> **Benefit**: BullMQ v5.62.0 Lua scripts are the canonical reference -- all EchoMQ implementations are tested against this version.

```typescript
// BullMQ Lua scripts are bundled in the npm package.
// Key scripts that affect migration compatibility:

// 1. addJob.lua -- adds job to queue (HASH + ZSET/LIST)
//    EchoMQ ports: EXACT replica
//    Compatibility: Job IDs, timestamps, state sets all match

// 2. moveToActive.lua -- moves job from wait to active
//    EchoMQ ports: EXACT replica + rate limiting (GAP-005 fixed)
//    Compatibility: Lock acquisition, stalled detection identical

// 3. moveToFinished.lua -- completes or fails a job
//    EchoMQ ports: EXACT replica + metrics (GAP-006 fixed)
//    Compatibility: Return values, cleanup, DLQ routing match

// 4. extendLock.lua -- renews job lock (GAP-007 fixed)
//    EchoMQ ports: Atomic lock ownership verification
//    Compatibility: Lock token validation identical

// Check your BullMQ version:
import { version } from 'bullmq/package.json';
console.log(`BullMQ version: ${version}`);
// Ensure >= 5.0.0 for full EchoMQ compatibility

// IMPORTANT: If running BullMQ < 5.0.0, some key structures
// differ (e.g., waiting list vs waiting ZSET). Upgrade BullMQ
// first, then add EchoMQ workers.
```

</tab>
<tab title="EchoMQ (Elixir)">

> **Benefit**: Elixir Lua scripts are byte-for-byte ports of BullMQ v5.62.0 -- tested against the Node.js reference implementation.

```elixir
# EchoMQ (Elixir) bundles Lua scripts as embedded files.
# They are loaded at compile time via @external_resource.

# Verify Lua script compatibility:
EchoMQ.Scripts.version()
# => "5.62.0"

# The Elixir implementation ports these critical scripts:
#
#   addJob.lua          -- Job creation (HASH + sorted set)
#   moveToActive.lua    -- BRPOPLPUSH equivalent via Lua
#   moveToFinished.lua  -- State transition + cleanup
#   extendLock.lua      -- Atomic lock renewal
#   obliterate.lua      -- Queue deletion
#   pause.lua           -- Queue pause/resume
#
# Each script:
#   1. Takes the same KEY and ARGV arguments as BullMQ
#   2. Returns the same values in the same format
#   3. Handles the same edge cases (stalled jobs, lock expiry)

# During migration, both BullMQ and EchoMQ call the same
# Lua scripts. Redis guarantees atomicity per script execution,
# so there are zero race conditions between implementations.

# If you have CUSTOM Lua scripts in BullMQ:
# These need manual porting. Use EchoMQ.Scripts.eval/4:
EchoMQ.Scripts.eval(
  conn,
  "return redis.call('GET', KEYS[1])",
  ["bull:guess-processing:custom-key"],
  []
)
```

</tab>
<tab title="EchoMQ (Go)">

> **Tradeoff**: Go embeds Lua scripts via `//go:embed` -- updating scripts requires recompilation, not a config change.

```go
package main

import (
    "fmt"

    "github.com/fiberfx/echomq-go/pkg/echomq"
)

func main() {
    // EchoMQ (Go) bundles Lua scripts via go:embed.
    // Verify version compatibility:
    fmt.Println("Lua script version:", echomq.ScriptVersion)
    // => "5.62.0"

    // The Go implementation ports the same scripts:
    //
    //   addJob.lua         -- Job creation
    //   moveToActive.lua   -- Job activation + lock
    //   moveToFinished.lua -- Completion/failure state transition
    //   extendLock.lua     -- Lock renewal
    //   obliterate.lua     -- Queue obliteration
    //   pause.lua          -- Queue pause/resume
    //
    // Scripts are embedded at compile time:
    //
    //   //go:embed scripts/addJob.lua
    //   var addJobScript string
    //
    // This means script updates require recompilation.
    // In practice, scripts only change on EchoMQ version bumps.

    // MIGRATION SAFETY CHECK:
    // Before deploying Go workers alongside BullMQ, verify:
    //   1. BullMQ version >= 5.0.0
    //   2. No custom Lua scripts in BullMQ worker
    //   3. Job data is JSON-serializable (no Date objects,
    //      no Buffer, no class instances)
    //   4. Redis version >= 6.2 (required for both)
}
```

</tab>
</tabs>

---

## 38.7. Monitoring During Migration

During the transition period, monitoring both BullMQ and EchoMQ workers is essential.
You need visibility into which runtime is processing which jobs, error rates per runtime,
and any protocol compatibility issues.

<tabs>
<tab title="BullMQ (Node.js)">

> **Benefit**: BullMQ's built-in `QueueEvents` provides real-time visibility into job processing without external tools.

```typescript
import { QueueEvents, Queue } from 'bullmq';

// Monitor the shared queue during migration
const queueEvents = new QueueEvents('guess-processing', {
  connection: { host: 'redis.codemoji.io', port: 6379 },
});

// Track which runtime processed each job
// EchoMQ workers set a "runtime" field in return value
queueEvents.on('completed', ({ jobId, returnvalue }) => {
  const result = JSON.parse(returnvalue);
  const runtime = result._runtime || 'bullmq'; // BullMQ won't set this

  metrics.increment('job.completed', {
    queue: 'guess-processing',
    runtime,
  });

  console.log(`Job ${jobId} completed by ${runtime}`);
});

queueEvents.on('failed', ({ jobId, failedReason }) => {
  metrics.increment('job.failed', {
    queue: 'guess-processing',
  });

  console.error(`Job ${jobId} failed: ${failedReason}`);
});

// Health check: compare processing rates
const queue = new Queue('guess-processing', {
  connection: { host: 'redis.codemoji.io', port: 6379 },
});

setInterval(async () => {
  const counts = await queue.getJobCounts(
    'waiting', 'active', 'completed', 'failed', 'delayed'
  );

  console.log('Queue health:', counts);

  // Alert if waiting count grows (workers can't keep up)
  if (counts.waiting > 1000) {
    alerting.warn('guess-processing queue backlog growing');
  }
}, 30000);
```

</tab>
<tab title="EchoMQ (Elixir)">

> **Benefit**: `:telemetry` events integrate directly with Prometheus/Grafana for unified dashboards alongside BullMQ metrics.

```elixir
defmodule Codemoji.MigrationMonitor do
  @moduledoc """
  Telemetry handler for monitoring EchoMQ during BullMQ migration.
  Tracks per-runtime completion rates and error rates.
  """

  require Logger

  def setup do
    events = [
      [:echomq, :job, :complete],
      [:echomq, :job, :fail],
      [:echomq, :job, :stalled]
    ]

    :telemetry.attach_many(
      "migration-monitor",
      events,
      &handle_event/4,
      %{}
    )
  end

  def handle_event([:echomq, :job, :complete], measurements, metadata, _config) do
    # Tag with runtime for per-runtime dashboards
    :telemetry.execute(
      [:codemoji, :migration, :completed],
      %{count: 1, duration_ms: div(measurements.duration, 1_000_000)},
      %{
        queue: metadata.queue,
        runtime: "elixir",
        job_name: metadata.job_name
      }
    )

    Logger.debug("Job #{metadata.job_id} completed by Elixir worker",
      queue: metadata.queue,
      duration_ms: div(measurements.duration, 1_000_000)
    )
  end

  def handle_event([:echomq, :job, :fail], _measurements, metadata, _config) do
    :telemetry.execute(
      [:codemoji, :migration, :failed],
      %{count: 1},
      %{
        queue: metadata.queue,
        runtime: "elixir",
        error: inspect(metadata.error)
      }
    )

    Logger.error("Job #{metadata.job_id} failed in Elixir worker",
      queue: metadata.queue,
      error: inspect(metadata.error)
    )
  end

  def handle_event([:echomq, :job, :stalled], _measurements, metadata, _config) do
    Logger.warning("Stalled job detected: #{metadata.job_id}",
      queue: metadata.queue
    )
  end
end

# Prometheus metrics exporter (add to your Prometheus config)
#
# codemoji_migration_completed_total{queue="guess-processing",runtime="elixir"}
# codemoji_migration_completed_total{queue="guess-processing",runtime="bullmq"}
# codemoji_migration_failed_total{queue="guess-processing",runtime="elixir"}
```

</tab>
<tab title="EchoMQ (Go)">

> **Tradeoff**: Go monitoring requires explicit Prometheus registration -- no automatic telemetry dispatch like Elixir's `:telemetry`.

```go
package main

import (
    "log"
    "time"

    "github.com/fiberfx/echomq-go/pkg/echomq"
    "github.com/prometheus/client_golang/prometheus"
    "github.com/prometheus/client_golang/prometheus/promauto"
)

var (
    migrationCompleted = promauto.NewCounterVec(
        prometheus.CounterOpts{
            Name: "codemoji_migration_completed_total",
            Help: "Jobs completed during migration by runtime",
        },
        []string{"queue", "runtime", "job_name"},
    )

    migrationFailed = promauto.NewCounterVec(
        prometheus.CounterOpts{
            Name: "codemoji_migration_failed_total",
            Help: "Jobs failed during migration by runtime",
        },
        []string{"queue", "runtime"},
    )

    migrationLatency = promauto.NewHistogramVec(
        prometheus.HistogramOpts{
            Name:    "codemoji_migration_duration_seconds",
            Help:    "Job processing duration during migration",
            Buckets: prometheus.DefBuckets,
        },
        []string{"queue", "runtime"},
    )
)

// MonitoredProcessor wraps a processor with migration metrics.
func MonitoredProcessor(
    queueName string,
    inner func(*echomq.Job) (interface{}, error),
) func(*echomq.Job) (interface{}, error) {
    return func(job *echomq.Job) (interface{}, error) {
        start := time.Now()

        result, err := inner(job)
        duration := time.Since(start).Seconds()

        if err != nil {
            migrationFailed.WithLabelValues(
                queueName, "go",
            ).Inc()
            log.Printf("[migration] Job %s failed (go): %v", job.ID, err)
        } else {
            migrationCompleted.WithLabelValues(
                queueName, "go", job.Name,
            ).Inc()
            migrationLatency.WithLabelValues(
                queueName, "go",
            ).Observe(duration)
        }

        return result, err
    }
}

// Usage:
// worker := echomq.NewWorker("guess-processing", rdb,
//     MonitoredProcessor("guess-processing", guessProcessor),
//     echomq.WorkerOptions{Concurrency: 5},
// )
```

</tab>
</tabs>

---

## 38.8. Rollback Strategies

If EchoMQ workers exhibit unexpected behavior during migration, you need a fast
rollback path. Because both systems share the same Redis keys, rollback is simply
a matter of stopping EchoMQ workers and restoring BullMQ concurrency.

<tabs>
<tab title="BullMQ (Node.js)">

> **Benefit**: Rollback to BullMQ is instant -- just stop EchoMQ workers and increase BullMQ concurrency.

```typescript
// --- ROLLBACK PROCEDURE ---
// If EchoMQ workers cause issues during migration:

// Step 1: Stop EchoMQ workers (Elixir/Go side)
// This is a deployment action -- scale EchoMQ to 0 instances

// Step 2: Increase BullMQ concurrency to original level
const worker = new Worker('guess-processing', processGuess, {
  connection: { host: 'redis.codemoji.io', port: 6379 },
  concurrency: 10,  // Restored from 5 during migration
});

// Step 3: Verify no orphaned jobs in active state
const queue = new Queue('guess-processing', {
  connection: { host: 'redis.codemoji.io', port: 6379 },
});

async function verifyNoOrphans() {
  const active = await queue.getActive();

  for (const job of active) {
    // Check if lock is still held
    const lockKey = `bull:guess-processing:${job.id}:lock`;
    const lock = await queue.client.get(lockKey);

    if (!lock) {
      // Orphaned job -- EchoMQ worker died without releasing lock
      console.warn(`Orphaned job ${job.id} -- moving back to waiting`);
      await job.moveToFailed(
        new Error('Worker died during migration rollback'),
        'migration-rollback',
      );
    }
  }
}

// Step 4: Run stalled job check to recover any stuck jobs
// BullMQ's built-in stalled detection handles this automatically
// within one stalledInterval (default 30s)

await verifyNoOrphans();
console.log('Rollback complete -- BullMQ workers restored');
```

</tab>
<tab title="EchoMQ (Elixir)">

> **Tradeoff**: Graceful Elixir shutdown waits for in-flight jobs to complete -- `lock_duration` determines maximum wait time.

```elixir
# --- GRACEFUL SHUTDOWN for rollback ---
# EchoMQ (Elixir) supports graceful shutdown that:
#   1. Stops accepting new jobs
#   2. Waits for in-flight jobs to complete
#   3. Releases all locks

defmodule Codemoji.MigrationRollback do
  require Logger

  @doc """
  Graceful shutdown procedure for rolling back to BullMQ.
  Call this before stopping the Elixir application.
  """
  def rollback do
    Logger.warning("Migration rollback initiated -- draining EchoMQ workers")

    # Stop all EchoMQ workers gracefully
    workers = [
      Codemoji.GuessWorker,
      Codemoji.PrizeWorker
    ]

    for worker_sup <- workers do
      Logger.info("Draining #{inspect(worker_sup)}")
      # Supervisor.stop waits for children to finish
      Supervisor.stop(worker_sup, :normal, 30_000)
    end

    # Verify no locks are held by this node
    {:ok, conn} = Redix.start_link("redis://redis.codemoji.io:6379")

    queues = ["guess-processing", "prize-distribution"]

    for queue <- queues do
      active_jobs = Redix.command!(conn, [
        "LRANGE", "bull:#{queue}:active", "0", "-1"
      ])

      for job_id <- active_jobs do
        lock = Redix.command!(conn, [
          "GET", "bull:#{queue}:#{job_id}:lock"
        ])

        if lock do
          Logger.warning(
            "Lock still held for #{queue}:#{job_id} -- " <>
            "will expire in #{30}s (lock_duration)"
          )
        end
      end
    end

    GenServer.stop(conn)
    Logger.info("Rollback complete -- EchoMQ workers stopped")
  end
end
```

</tab>
<tab title="EchoMQ (Go)">

> **Benefit**: Go's `context.Context` cancellation propagates to all in-flight jobs -- clean shutdown with bounded wait time.

```go
package main

import (
    "context"
    "log"
    "time"

    "github.com/redis/go-redis/v9"
    "github.com/fiberfx/echomq-go/pkg/echomq"
)

// RollbackShutdown performs graceful shutdown for migration rollback.
func RollbackShutdown(worker *echomq.Worker, rdb *redis.Client) error {
    log.Println("Migration rollback: draining Go EchoMQ worker")

    // Step 1: Stop accepting new jobs
    // Close cancels the worker's context, which:
    //   - Stops fetching new jobs from Redis
    //   - Cancels context for in-flight processors
    //   - Waits up to LockDuration for graceful completion

    ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
    defer cancel()

    if err := worker.Close(); err != nil {
        log.Printf("Worker close error: %v", err)
    }

    // Step 2: Verify no orphaned locks
    queues := []string{"guess-processing", "prize-distribution"}

    for _, queueName := range queues {
        activeKey := "bull:" + queueName + ":active"
        active, err := rdb.LRange(ctx, activeKey, 0, -1).Result()
        if err != nil {
            log.Printf("Failed to check active jobs for %s: %v",
                queueName, err)
            continue
        }

        for _, jobID := range active {
            lockKey := "bull:" + queueName + ":" + jobID + ":lock"
            lock, err := rdb.Get(ctx, lockKey).Result()
            if err == nil && lock != "" {
                log.Printf("Lock still held for %s:%s -- "+
                    "expires with lock_duration", queueName, jobID)
            }
        }
    }

    log.Println("Rollback complete -- Go EchoMQ worker stopped")
    return nil
}
```

</tab>
</tabs>

---

## 38.9. Post-Migration Verification

After fully migrating from BullMQ to EchoMQ, run these verification checks to confirm
that all queues operate correctly and no data was lost during the transition.

<tabs>
<tab title="BullMQ (Node.js)">

> **Benefit**: BullMQ's queue inspection APIs serve as the reference standard for verifying EchoMQ's state consistency.

```typescript
import { Queue } from 'bullmq';

/**
 * Post-migration verification script.
 * Run after all BullMQ workers are stopped and EchoMQ is primary.
 */
async function verifyMigration() {
  const connection = { host: 'redis.codemoji.io', port: 6379 };

  const queues = [
    'guess-processing',
    'prize-distribution',
    'telegram-notifications',
  ];

  for (const queueName of queues) {
    const queue = new Queue(queueName, { connection });
    const counts = await queue.getJobCounts(
      'waiting', 'active', 'completed', 'failed', 'delayed'
    );

    console.log(`\n=== ${queueName} ===`);
    console.log('  Waiting:', counts.waiting);
    console.log('  Active:', counts.active);
    console.log('  Completed:', counts.completed);
    console.log('  Failed:', counts.failed);
    console.log('  Delayed:', counts.delayed);

    // Verification checks
    if (counts.active > 0) {
      console.warn(`  WARNING: ${counts.active} active jobs -- ` +
        'check for orphaned locks');
    }

    if (counts.waiting > 100) {
      console.warn(`  WARNING: ${counts.waiting} waiting jobs -- ` +
        'verify EchoMQ workers are processing');
    }

    // Check for stalled jobs
    const stalled = await queue.getJobs(['active'], 0, -1);
    const now = Date.now();
    const stalledJobs = stalled.filter(
      (j) => now - (j.processedOn ?? 0) > 60000
    );

    if (stalledJobs.length > 0) {
      console.warn(
        `  WARNING: ${stalledJobs.length} potentially stalled jobs`
      );
    }

    await queue.close();
  }

  console.log('\nPost-migration verification complete');
}

verifyMigration().catch(console.error);
```

</tab>
<tab title="EchoMQ (Elixir)">

> **Benefit**: Elixir verification can run as a Mix task -- integrated into your deployment pipeline.

```elixir
defmodule Mix.Tasks.Verify.Migration do
  @moduledoc """
  Post-migration verification task.
  Run: mix verify.migration
  """

  use Mix.Task

  require Logger

  @queues ["guess-processing", "prize-distribution", "telegram-notifications"]

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("app.start")

    {:ok, conn} = Redix.start_link("redis://redis.codemoji.io:6379")

    for queue <- @queues do
      Logger.info("=== #{queue} ===")

      # Get job counts from Redis directly
      waiting = Redix.command!(conn, ["LLEN", "bull:#{queue}:wait"])
      active = Redix.command!(conn, ["LLEN", "bull:#{queue}:active"])
      completed = Redix.command!(conn, ["ZCARD", "bull:#{queue}:completed"])
      failed = Redix.command!(conn, ["ZCARD", "bull:#{queue}:failed"])
      delayed = Redix.command!(conn, ["ZCARD", "bull:#{queue}:delayed"])

      Logger.info("  Waiting: #{waiting}")
      Logger.info("  Active: #{active}")
      Logger.info("  Completed: #{completed}")
      Logger.info("  Failed: #{failed}")
      Logger.info("  Delayed: #{delayed}")

      # Check for orphaned active jobs
      if active > 0 do
        active_ids = Redix.command!(conn, ["LRANGE", "bull:#{queue}:active", "0", "-1"])

        orphaned =
          Enum.filter(active_ids, fn job_id ->
            lock = Redix.command!(conn, ["GET", "bull:#{queue}:#{job_id}:lock"])
            is_nil(lock)
          end)

        if length(orphaned) > 0 do
          Logger.warning("  #{length(orphaned)} orphaned jobs (no lock): #{inspect(orphaned)}")
        end
      end

      # Verify EchoMQ worker is processing
      if waiting > 100 do
        Logger.warning("  Queue backlog: #{waiting} waiting jobs")
      end
    end

    GenServer.stop(conn)
    Logger.info("\nPost-migration verification complete")
  end
end
```

</tab>
<tab title="EchoMQ (Go)">

> **Tradeoff**: Go verification scripts need explicit Redis commands -- no queue abstraction layer for inspection.

```go
package main

import (
    "context"
    "fmt"
    "log"

    "github.com/redis/go-redis/v9"
)

// VerifyMigration checks queue health after BullMQ removal.
func VerifyMigration(rdb *redis.Client) error {
    ctx := context.Background()

    queues := []string{
        "guess-processing",
        "prize-distribution",
        "telegram-notifications",
    }

    for _, queueName := range queues {
        fmt.Printf("\n=== %s ===\n", queueName)

        prefix := "bull:" + queueName

        // Get job counts
        waiting, _ := rdb.LLen(ctx, prefix+":wait").Result()
        active, _ := rdb.LLen(ctx, prefix+":active").Result()
        completed, _ := rdb.ZCard(ctx, prefix+":completed").Result()
        failed, _ := rdb.ZCard(ctx, prefix+":failed").Result()
        delayed, _ := rdb.ZCard(ctx, prefix+":delayed").Result()

        fmt.Printf("  Waiting:   %d\n", waiting)
        fmt.Printf("  Active:    %d\n", active)
        fmt.Printf("  Completed: %d\n", completed)
        fmt.Printf("  Failed:    %d\n", failed)
        fmt.Printf("  Delayed:   %d\n", delayed)

        // Check for orphaned active jobs
        if active > 0 {
            activeIDs, _ := rdb.LRange(ctx, prefix+":active", 0, -1).Result()

            orphaned := 0
            for _, jobID := range activeIDs {
                lockKey := prefix + ":" + jobID + ":lock"
                lock, err := rdb.Get(ctx, lockKey).Result()
                if err != nil || lock == "" {
                    orphaned++
                    log.Printf("  Orphaned job (no lock): %s", jobID)
                }
            }

            if orphaned > 0 {
                log.Printf("  WARNING: %d orphaned jobs", orphaned)
            }
        }

        // Queue backlog check
        if waiting > 100 {
            log.Printf("  WARNING: %d waiting jobs -- "+
                "verify workers are processing", waiting)
        }
    }

    fmt.Println("\nPost-migration verification complete")
    return nil
}
```

</tab>
</tabs>

---

## 38.10. Summary

| Phase | Action | Risk | Duration |
|-------|--------|------|----------|
| **Preparation** | Verify BullMQ >= v5.0.0, Redis >= 6.2, JSON-serializable job data | None | 1 day |
| **Phase 1** | Add EchoMQ workers alongside BullMQ (low concurrency) | Zero -- BullMQ continues as primary | 1-2 weeks |
| **Phase 2** | Increase EchoMQ concurrency, decrease BullMQ | Low -- shared processing, can rollback instantly | 1-2 weeks |
| **Phase 3** | Drain BullMQ workers, EchoMQ becomes primary | Medium -- rollback still possible (restart BullMQ) | 1 week |
| **Phase 4** | Remove BullMQ dependencies | Low -- cleanup only, no processing change | 1 day |
| **Verification** | Run post-migration checks (orphans, backlogs, stalled) | None -- read-only inspection | 1 hour |

### Key Migration Principles

1. **Wire compatibility** -- Redis key prefix `bull:` is preserved across all implementations.
2. **Atomic Lua scripts** -- Same v5.62.0 scripts prevent race conditions between runtimes.
3. **Gradual rollout** -- Run both systems in parallel before committing to EchoMQ.
4. **Instant rollback** -- Stop EchoMQ workers, restore BullMQ concurrency. No data migration needed.
5. **JSON serialization** -- Job data must be plain JSON. No Date objects, Buffers, or class instances.
6. **Lock settings must match** -- `lockDuration` and `stalledInterval` must be identical across all workers on the same queue.

---

*Previous: [Testing & Mocking](ch37-testing-mocking.md) | Next: [EchoMQ Index](../echomq_index.md)*
