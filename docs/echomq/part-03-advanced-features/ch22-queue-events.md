# Chapter 22. Queue Events

EchoMQ provides two complementary event consumption models: **worker callbacks** for reacting to jobs a specific worker processes, and **QueueEvents** for monitoring all events across a queue regardless of which worker (or which runtime) handles them. QueueEvents uses Redis Streams under the hood, giving you persistent, replayable, ordered event delivery -- the same infrastructure that powers BullMQ's event system in Node.js.

For a game server like Fireheadz Arena, QueueEvents is how you build real-time combat dashboards, push player notifications through Phoenix PubSub, track matchmaking progress, and detect when a combat round has fully drained.

## 22.1. Worker Callbacks vs QueueEvents

Before diving into QueueEvents, it helps to understand the two models and when to use each.

**Worker callbacks** fire inside the worker process that handled the job. They are simple, low-latency, and require no additional infrastructure. Use them for logging, metrics, and worker-local reactions.

**QueueEvents** listens to the Redis Streams event log, which captures events from every worker connected to the queue -- Elixir, Go, and Node.js alike. Use QueueEvents when you need cross-worker visibility, when a separate process (like a dashboard or notification service) needs to react to events, or when you want event replay.

| Aspect | Worker Callbacks | QueueEvents |
|--------|-----------------|-------------|
| Scope | Jobs this worker processed | All jobs in the queue |
| Cross-runtime | No (local worker only) | Yes (Elixir, Go, Node.js) |
| Persistence | None (in-memory) | Redis Streams (replayable) |
| Multiple consumers | No | Yes (fan-out to subscribers) |
| Use case | Logging, local metrics | Dashboards, notifications, coordination |
| Overhead | Zero (inline) | One Redis connection per listener |

### Worker Callbacks

<tabs>
<tab title="Elixir">

```elixir
{:ok, worker} = EchoMQ.Worker.start_link(
  queue: "combat-actions",
  connection: :arena_redis,
  processor: &Arena.CombatProcessor.process/1,
  concurrency: 10,

  on_active: fn job ->
    Logger.info("Combat action started: #{job.name} for job #{job.id}")
  end,

  on_completed: fn job, result ->
    Logger.info("Combat resolved: job #{job.id}, damage=#{result[:damage]}")
    Arena.Dashboard.increment(:completed)
  end,

  on_failed: fn job, error ->
    Logger.error("Combat rejected: job #{job.id}, reason=#{error}")
    Arena.Alerts.notify(:combat_failure, job.id, error)
  end,

  on_progress: fn job, progress ->
    Logger.debug("Combat #{job.id} phase: #{inspect(progress)}")
  end,

  on_stalled: fn job_id ->
    Logger.warning("Combat action stalled: job=#{job_id}")
  end
)
```

> **Benefit**: Phoenix LiveView delivers real-time dashboards over WebSocket with zero client-side JavaScript.

</tab>
<tab title="Go">

```go
// Feature: Worker Event Callbacks (on_completed, on_failed, on_active)
//
// Not implemented in echomq-go. The Go worker does not expose
// callback-style hooks on the Worker struct. Events are emitted
// to the Redis event stream automatically on job completion/failure.
//
// Workaround:
//   Use the EventEmitter's output directly or subscribe to the
//   Redis event stream with XREAD:
//     stream := fmt.Sprintf("bull:%s:events", "combat-actions")
//     results, _ := rdb.XRead(ctx, &redis.XReadArgs{
//         Streams: []string{stream, "$"},
//         Block:   5 * time.Second,
//     }).Result()
//     for _, msg := range results[0].Messages {
//         event := msg.Values["event"].(string)
//         jobID := msg.Values["jobId"].(string)
//         log.Printf("[combat-actions] job=%s event=%s", jobID, event)
//     }
//
// Reference: Ch 17 Worker Patterns — Protocol Gap Summary Table
```

> **Tradeoff**: Lock extension requires periodic goroutine-based timers — manual lifecycle management.

</tab>
<tab title="Node.js">

```typescript
import { Worker } from "bullmq";

const worker = new Worker("combat-actions", combatProcessor, {
  connection: { host: "localhost", port: 6379 },
  concurrency: 10,
});

worker.on("active", (job) => {
  console.log(`Combat action started: ${job.name} for job ${job.id}`);
});

worker.on("completed", (job, result) => {
  console.log(`Combat resolved: job ${job.id}, damage=${result.damage}`);
});

worker.on("failed", (job, err) => {
  console.error(`Combat rejected: job ${job?.id}: ${err.message}`);
});

worker.on("progress", (job, progress) => {
  console.log(`Combat ${job.id} phase: ${JSON.stringify(progress)}`);
});

worker.on("stalled", (jobId) => {
  console.warn(`Combat action stalled: job=${jobId}`);
});
```

> **Tradeoff**: Event loop concurrency means I/O-bound jobs scale well but CPU-bound jobs need worker threads.

</tab>
</tabs>

> **⚠️ Go Gap**: QueueEvents (Redis Streams-based event listener) is not implemented. No real-time event subscription capability.
> **Proposed Solution**: Implement `QueueEvents` struct with `XREADGROUP` blocking loop in a goroutine. Parse stream entries into typed events (completed, failed, progress, stalled, waiting). Use consumer groups for reliable delivery.

### QueueEvents Listener

<tabs>
<tab title="Elixir">

`EchoMQ.QueueEvents` is a GenServer that opens a dedicated blocking Redis connection, reads from the `bull:{queue}:events` stream with `XREAD BLOCK`, and dispatches events to subscribers and handler modules.

```elixir
# Start the event listener
{:ok, events} = EchoMQ.QueueEvents.start_link(
  queue: "combat-actions",
  connection: :arena_redis
)

# Subscribe the current process
EchoMQ.QueueEvents.subscribe(events)

# Receive events from ANY worker (Elixir, Go, or Node.js)
receive do
  {:echomq_event, :completed, data} ->
    IO.puts("Job #{data["jobId"]} completed: #{data["returnvalue"]}")

  {:echomq_event, :failed, data} ->
    IO.puts("Job #{data["jobId"]} failed: #{data["failedReason"]}")

  {:echomq_event, :active, data} ->
    IO.puts("Job #{data["jobId"]} started processing")

  {:echomq_event, :stalled, data} ->
    IO.puts("Job #{data["jobId"]} stalled — worker crash?")

  {:echomq_event, :drained, _data} ->
    IO.puts("Queue drained — all combat actions processed")
end
```

Events arrive as `{:echomq_event, event_type, event_data}` tuples where `event_type` is an atom and `event_data` is a map with string keys.

> **Benefit**: LockManager batches all lock renewals into a single GenServer tick — O(1) timer overhead.

</tab>
<tab title="Go">

```go
// Feature: QueueEvents Listener (real-time event subscription)
//
// Partially implemented in echomq-go. The EventEmitter can publish
// events to Redis Streams (XADD), but there is no QueueEvents
// listener to consume them (no XREAD/XREADGROUP loop).
//
// Workaround:
//   Use Redis XREAD directly to consume the event stream:
//     streamKey := fmt.Sprintf("bull:%s:events", queueName)
//     results, _ := rdb.XRead(ctx, &redis.XReadArgs{
//         Streams: []string{streamKey, "$"},
//         Block:   5 * time.Second,
//     }).Result()
//
// Reference: Ch 17 Worker Patterns — Protocol Gap Summary Table

// Direct XREAD workaround for Go game servers:
func monitorCombatEvents(ctx context.Context, rdb *redis.Client, queueName string) {
    streamKey := fmt.Sprintf("bull:%s:events", queueName)
    lastID := "$"

    for {
        select {
        case <-ctx.Done():
            return
        default:
        }

        results, err := rdb.XRead(ctx, &redis.XReadArgs{
            Streams: []string{streamKey, lastID},
            Block:   5 * time.Second,
        }).Result()
        if err != nil {
            if err == redis.Nil {
                continue // timeout, no new events
            }
            log.Printf("Error reading events: %v", err)
            time.Sleep(time.Second)
            continue
        }

        for _, msg := range results[0].Messages {
            event := msg.Values["event"].(string)
            jobID := msg.Values["jobId"].(string)

            switch event {
            case "completed":
                log.Printf("Combat resolved: job=%s result=%v", jobID, msg.Values["returnvalue"])
            case "failed":
                log.Printf("Combat rejected: job=%s error=%v", jobID, msg.Values["error"])
            case "stalled":
                log.Printf("Combat stalled: job=%s", jobID)
            case "drained":
                log.Printf("Queue drained — combat round complete")
            }

            lastID = msg.ID
        }
    }
}
```

> **Benefit**: Group IDs as struct fields enable type-safe group assignment at compile time.

</tab>
<tab title="Node.js">

```typescript
import { QueueEvents } from "bullmq";

const queueEvents = new QueueEvents("combat-actions", {
  connection: { host: "localhost", port: 6379 },
});

queueEvents.on("completed", ({ jobId, returnvalue }) => {
  console.log(`Combat resolved: job ${jobId}, result: ${returnvalue}`);
});

queueEvents.on("failed", ({ jobId, failedReason }) => {
  console.error(`Combat rejected: job ${jobId}: ${failedReason}`);
});

queueEvents.on("active", ({ jobId, prev }) => {
  console.log(`Combat started: job ${jobId} (was ${prev})`);
});

queueEvents.on("stalled", ({ jobId }) => {
  console.warn(`Combat stalled: job ${jobId}`);
});

queueEvents.on("drained", () => {
  console.log("Queue drained — all combat actions processed");
});
```

> **Benefit**: Stalled job checker runs automatically within the Worker — configurable via `stalledInterval`.

</tab>
</tabs>

## 22.2. Event Types

Every job lifecycle transition emits an event to the `bull:{queue}:events` Redis Stream. The following table lists all standard events:

| Event | Description | Data Fields |
|-------|-------------|-------------|
| `added` | Job was added to the queue | `jobId`, `name` |
| `waiting` | Job is waiting to be processed | `jobId` |
| `active` | Job started processing | `jobId`, `prev` |
| `progress` | Job progress was updated | `jobId`, `data` |
| `completed` | Job completed successfully | `jobId`, `returnvalue`, `prev` |
| `failed` | Job failed | `jobId`, `failedReason`, `prev` |
| `delayed` | Job was delayed | `jobId`, `delay` |
| `stalled` | Job was detected as stalled | `jobId` |
| `removed` | Job was removed | `jobId`, `prev` |
| `drained` | Queue has no more waiting jobs | (none) |
| `paused` | Queue was paused | (none) |
| `resumed` | Queue was resumed | (none) |
| `waiting-children` | Parent waiting for child jobs | `jobId` |
| `duplicated` | Job was deduplicated | `jobId` |

In Elixir, event types are atoms (`:completed`, `:failed`, `:waiting_children`). Hyphenated event names are converted: `waiting-children` becomes `:waiting_children`. In Node.js, they are strings used as EventEmitter event names. In Go, they are string values in the Redis stream's `event` field.

## 22.3. Redis Streams Implementation

QueueEvents is built on Redis Streams, not Redis Pub/Sub. This is a deliberate design choice that gives events three properties Pub/Sub lacks: **persistence**, **ordering**, and **replay**.

```
Producer/Worker                   Redis Stream                    QueueEvents Listener
     |                                |                                |
     +-- XADD bull:queue:events -->   |                                |
     |   {event: "completed",         |                                |
     |    jobId: "PLR0K48QjihpC4",       +--- XREAD BLOCK 5000 ---------> |
     |    returnvalue: "..."}         |    STREAMS bull:queue:events $  |
     |                                |                                |
     +-- XADD bull:queue:events -->   |                                |
     |   {event: "active",            +--- delivers batch -----------> |
     |    jobId: "PLR1Md2fKjqD5n"}       |                                |
```

Key characteristics:

- **Stream key**: `bull:{queue}:events` (e.g., `bull:combat-actions:events`)
- **Auto-trimmed**: Approximately 10,000 entries by default (`MAXLEN ~ 10000`)
- **Blocking read**: Listener uses `XREAD BLOCK` for efficient polling (no busy-wait)
- **Delivery guarantee**: Unlike Pub/Sub, events are stored and survive listener restarts
- **Replay**: Pass `last_event_id` to start reading from a specific point in the stream
- **Approximate trimming**: Uses `~` flag for performance (may keep slightly more than `maxLen`)

<tabs>
<tab title="Elixir">

```elixir
# Inspect the event stream directly via Redis
{:ok, events} = Redix.command(:arena_redis, [
  "XRANGE", "bull:combat-actions:events", "-", "+", "COUNT", "5"
])

# Each entry: [stream_id, [field1, val1, field2, val2, ...]]
# Example: ["1707350400000-0", ["event", "completed", "jobId", "abc123", "returnvalue", "{...}"]]
for [id, fields] <- events do
  data = fields |> Enum.chunk_every(2) |> Map.new(fn [k, v] -> {k, v} end)
  IO.puts("[#{id}] #{data["event"]} job=#{data["jobId"]}")
end
```

> **Benefit**: Redix XREAD integration provides native stream consumption — no wrapper library needed.

</tab>
<tab title="Go">

```go
// Inspect event stream directly
results, err := rdb.XRange(ctx, "bull:combat-actions:events", "-", "+").Result()
if err != nil {
    log.Fatal(err)
}

for _, msg := range results {
    event := msg.Values["event"].(string)
    jobID := msg.Values["jobId"].(string)
    fmt.Printf("[%s] %s job=%s\n", msg.ID, event, jobID)
}

// Check stream length
length, _ := rdb.XLen(ctx, "bull:combat-actions:events").Result()
fmt.Printf("Event stream contains %d entries\n", length)
```

> **Benefit**: `redis.XRead` returns typed results — stream entries are immediately usable.

</tab>
<tab title="Node.js">

```typescript
import { createClient } from "redis";

const client = createClient({ url: "redis://localhost:6379" });
await client.connect();

// Inspect event stream directly
const events = await client.xRange("bull:combat-actions:events", "-", "+", { COUNT: 5 });

for (const entry of events) {
  const { event, jobId } = entry.message;
  console.log(`[${entry.id}] ${event} job=${jobId}`);
}

// Check stream length
const length = await client.xLen("bull:combat-actions:events");
console.log(`Event stream contains ${length} entries`);
```

> **Benefit**: QueueEvents wraps XREAD internally — consumers get typed events via EventEmitter.

</tab>
</tabs>

## 22.4. QueueEvents GenServer (Elixir)

The Elixir `EchoMQ.QueueEvents` module is a full GenServer that manages its own blocking Redis connection, consumer task, subscriber list, and optional handler module. Understanding its internals helps you integrate it correctly into your game server's supervision tree.

### Lifecycle

```
start_link(opts)
     |
     v
  init/1 — parse options, optionally send(:start)
     |
     v (if autorun: true)
  :start — open dedicated blocking Redis connection
     |
     v
  schedule_consume/1 — spawn Task.async for XREAD BLOCK
     |
     +---> Task completes with events
     |       |
     |       v
     |     process_events/2 — parse, notify subscribers, call handler
     |       |
     |       v
     |     schedule_consume/1 (loop)
     |
     +---> Task completes with nil (timeout)
     |       |
     |       v
     |     schedule_consume/1 (loop)
     |
     +---> close/1 — cancel task, close blocking connection
```

### Start Options

<tabs>
<tab title="Elixir">

```elixir
{:ok, events} = EchoMQ.QueueEvents.start_link(
  queue: "combat-actions",         # Queue name (required)
  connection: :arena_redis,        # Redis connection (required)
  prefix: "bull",                  # Key prefix (default: "bull")
  autorun: true,                   # Start listening immediately (default: true)
  last_event_id: "$",              # Start point: "$" = new events only (default)
  handler: Arena.CombatHandler,    # Handler module (optional)
  handler_state: %{kills: 0},     # Initial handler state (optional)
  name: :combat_events             # Register under a name (optional)
)
```

The `last_event_id` option controls where in the stream the listener starts reading. Use `"$"` (default) for new events only, `"0"` to replay all available events from the beginning, or a specific stream ID like `"1707350400000-0"` to resume from a known position.

> **Benefit**: Redix XREAD integration provides native stream consumption — no wrapper library needed.

</tab>
<tab title="Go">

```go
// Go does not have a built-in QueueEvents listener.
// Configure the XREAD parameters directly:
func NewCombatEventMonitor(rdb *redis.Client, queue string) *CombatEventMonitor {
    return &CombatEventMonitor{
        rdb:         rdb,
        streamKey:   fmt.Sprintf("bull:%s:events", queue),
        lastEventID: "$",           // "$" = new events only, "0" = replay all
        blockTimeout: 5 * time.Second,
    }
}

type CombatEventMonitor struct {
    rdb          *redis.Client
    streamKey    string
    lastEventID  string
    blockTimeout time.Duration
}

func (m *CombatEventMonitor) Listen(ctx context.Context, handler func(string, map[string]interface{})) {
    for {
        select {
        case <-ctx.Done():
            return
        default:
        }

        results, err := m.rdb.XRead(ctx, &redis.XReadArgs{
            Streams: []string{m.streamKey, m.lastEventID},
            Block:   m.blockTimeout,
        }).Result()
        if err != nil {
            if err == redis.Nil {
                continue
            }
            log.Printf("Event read error: %v", err)
            time.Sleep(time.Second)
            continue
        }

        for _, msg := range results[0].Messages {
            event := msg.Values["event"].(string)
            handler(event, msg.Values)
            m.lastEventID = msg.ID
        }
    }
}
```

> **Tradeoff**: Lock extension requires periodic goroutine-based timers — manual lifecycle management.

</tab>
<tab title="Node.js">

```typescript
import { QueueEvents } from "bullmq";

const queueEvents = new QueueEvents("combat-actions", {
  connection: { host: "localhost", port: 6379 },
  prefix: "bull",                    // Key prefix (default: "bull")
  autorun: true,                     // Start listening immediately (default: true)
  lastEventId: "$",                  // Start from new events (default)
  blockingTimeout: 10000,            // XREAD BLOCK timeout in ms (default: 10000)
});

// Close when done
await queueEvents.close();
```

> **Benefit**: Built-in lock extension runs automatically within the Worker class — transparent to processors.

</tab>
</tabs>

### Multiple Subscribers

Multiple processes can subscribe to the same QueueEvents instance. Each subscriber receives every event -- there is no partitioning or consumer groups at this level.

<tabs>
<tab title="Elixir">

```elixir
{:ok, events} = EchoMQ.QueueEvents.start_link(
  queue: "combat-actions",
  connection: :arena_redis,
  name: :combat_events
)

# Subscribe the dashboard GenServer
EchoMQ.QueueEvents.subscribe(:combat_events, dashboard_pid)

# Subscribe the notification service
EchoMQ.QueueEvents.subscribe(:combat_events, notifier_pid)

# Subscribe the analytics collector
EchoMQ.QueueEvents.subscribe(:combat_events, analytics_pid)

# Unsubscribe when a service stops
EchoMQ.QueueEvents.unsubscribe(:combat_events, analytics_pid)
```

Subscribers are monitored via `Process.monitor/1`. If a subscriber crashes, it is automatically removed from the subscriber list -- no manual cleanup needed.

> **Benefit**: Phoenix LiveView delivers real-time dashboards over WebSocket with zero client-side JavaScript.

</tab>
<tab title="Go">

```go
// In Go, implement fan-out manually with channels:
type EventFanOut struct {
    mu          sync.RWMutex
    subscribers []chan map[string]interface{}
}

func (f *EventFanOut) Subscribe() <-chan map[string]interface{} {
    ch := make(chan map[string]interface{}, 100)
    f.mu.Lock()
    f.subscribers = append(f.subscribers, ch)
    f.mu.Unlock()
    return ch
}

func (f *EventFanOut) Broadcast(event map[string]interface{}) {
    f.mu.RLock()
    defer f.mu.RUnlock()
    for _, ch := range f.subscribers {
        select {
        case ch <- event:
        default:
            // subscriber too slow, drop event
        }
    }
}
```

> **Tradeoff**: Lock extension requires periodic goroutine-based timers — manual lifecycle management.

</tab>
<tab title="Node.js">

```typescript
// Node.js QueueEvents supports multiple listeners per event natively
const queueEvents = new QueueEvents("combat-actions", { connection });

// Dashboard listener
queueEvents.on("completed", ({ jobId, returnvalue }) => {
  dashboard.update(jobId, JSON.parse(returnvalue));
});

// Notification listener
queueEvents.on("completed", ({ jobId }) => {
  notifier.sendPush(jobId, "Combat resolved");
});

// Analytics listener
queueEvents.on("completed", ({ jobId, returnvalue }) => {
  analytics.track("combat_completed", { jobId, result: returnvalue });
});

// Remove a specific listener
queueEvents.off("completed", analyticsHandler);
```

> **Benefit**: Bull Board provides a production-ready admin UI with job inspection, retry, and delete.

</tab>
</tabs>

## 22.5. Handler Module Pattern

For structured event handling, Elixir provides the `EchoMQ.QueueEvents.Handler` behaviour. This is the recommended approach for production game servers because it encapsulates state, enforces a consistent interface, and integrates cleanly with supervision trees.

<tabs>
<tab title="Elixir">

```elixir
defmodule Arena.CombatEventHandler do
  @moduledoc "Tracks combat statistics and broadcasts results to game rooms."
  use EchoMQ.QueueEvents.Handler

  require Logger

  @impl true
  def init(_opts) do
    {:ok, %{
      completed: 0,
      failed: 0,
      total_damage: 0,
      critical_hits: 0
    }}
  end

  @impl true
  def handle_event(:completed, %{"jobId" => id, "returnvalue" => value}, state) do
    result = Jason.decode!(value)
    damage = result["damage"] || 0
    critical = if result["critical"], do: 1, else: 0

    Logger.info("Combat #{id} resolved: #{damage} damage#{if critical == 1, do: " (CRITICAL)", else: ""}")

    # Broadcast to Phoenix PubSub for LiveView dashboards
    Phoenix.PubSub.broadcast(Arena.PubSub, "combat:results", {:combat_resolved, id, result})

    {:ok, %{state |
      completed: state.completed + 1,
      total_damage: state.total_damage + damage,
      critical_hits: state.critical_hits + critical
    }}
  end

  @impl true
  def handle_event(:failed, %{"jobId" => id, "failedReason" => reason}, state) do
    Logger.error("Combat #{id} rejected: #{reason}")
    Arena.Alerts.notify(:combat_failure, %{job_id: id, reason: reason})
    {:ok, %{state | failed: state.failed + 1}}
  end

  @impl true
  def handle_event(:stalled, %{"jobId" => id}, state) do
    Logger.warning("Combat #{id} stalled — possible worker crash")
    {:ok, state}
  end

  @impl true
  def handle_event(:drained, _data, state) do
    Logger.info("Combat round complete: #{state.completed} resolved, #{state.failed} rejected")
    {:ok, state}
  end

  @impl true
  def handle_event(_event, _data, state) do
    {:ok, state}
  end
end

# Start with the handler
{:ok, events} = EchoMQ.QueueEvents.start_link(
  queue: "combat-actions",
  connection: :arena_redis,
  handler: Arena.CombatEventHandler,
  handler_state: %{}
)
```

The handler behaviour requires two callbacks:

| Callback | Signature | Purpose |
|----------|-----------|---------|
| `init/1` | `(opts) -> {:ok, state}` | Initialize handler state |
| `handle_event/3` | `(event, data, state) -> {:ok, new_state}` | Process an event |

Using `use EchoMQ.QueueEvents.Handler` provides default implementations for both callbacks, so you only need to override the events you care about.

> **Benefit**: Phoenix LiveView delivers real-time dashboards over WebSocket with zero client-side JavaScript.

</tab>
<tab title="Go">

```go
// In Go, implement the handler pattern with an interface:
type EventHandler interface {
    HandleEvent(eventType string, data map[string]interface{}) error
}

type CombatEventHandler struct {
    mu           sync.Mutex
    completed    int
    failed       int
    totalDamage  float64
}

func (h *CombatEventHandler) HandleEvent(eventType string, data map[string]interface{}) error {
    h.mu.Lock()
    defer h.mu.Unlock()

    switch eventType {
    case "completed":
        h.completed++
        if rv, ok := data["returnvalue"].(string); ok {
            var result map[string]interface{}
            if err := json.Unmarshal([]byte(rv), &result); err == nil {
                if damage, ok := result["damage"].(float64); ok {
                    h.totalDamage += damage
                }
            }
        }
        log.Printf("Combat resolved: job=%s (total: %d)", data["jobId"], h.completed)

    case "failed":
        h.failed++
        log.Printf("Combat rejected: job=%s reason=%v", data["jobId"], data["error"])

    case "drained":
        log.Printf("Combat round complete: %d resolved, %d rejected", h.completed, h.failed)
    }

    return nil
}

// Use with the CombatEventMonitor from above
monitor := NewCombatEventMonitor(rdb, "combat-actions")
handler := &CombatEventHandler{}

go monitor.Listen(ctx, func(event string, data map[string]interface{}) {
    handler.HandleEvent(event, data)
})
```

> **Tradeoff**: Lock extension requires periodic goroutine-based timers — manual lifecycle management.

</tab>
<tab title="Node.js">

```typescript
import { QueueEvents } from "bullmq";

// Structured handler class
class CombatEventHandler {
  private completed = 0;
  private failed = 0;
  private totalDamage = 0;

  attach(queueEvents: QueueEvents) {
    queueEvents.on("completed", ({ jobId, returnvalue }) => {
      this.completed++;
      const result = JSON.parse(returnvalue || "{}");
      this.totalDamage += result.damage || 0;
      console.log(`Combat ${jobId} resolved (total: ${this.completed})`);
    });

    queueEvents.on("failed", ({ jobId, failedReason }) => {
      this.failed++;
      console.error(`Combat ${jobId} rejected: ${failedReason}`);
    });

    queueEvents.on("drained", () => {
      console.log(`Combat round complete: ${this.completed} resolved, ${this.failed} rejected`);
    });
  }

  getStats() {
    return { completed: this.completed, failed: this.failed, totalDamage: this.totalDamage };
  }
}

const queueEvents = new QueueEvents("combat-actions", { connection });
const handler = new CombatEventHandler();
handler.attach(queueEvents);
```

> **Benefit**: `queue.drain()` removes all waiting jobs — `queue.obliterate()` removes everything.

</tab>
</tabs>

## 22.6. Supervision Integration

In production, QueueEvents should live inside your OTP supervision tree so it restarts automatically on failure. The dedicated blocking Redis connection and the consumer task are both managed by the GenServer lifecycle.

<tabs>
<tab title="Elixir">

```elixir
defmodule Arena.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Redis connection pool
      {Redix, name: :arena_redis, host: "localhost", port: 6379},

      # Combat workers (process jobs)
      {EchoMQ.Worker,
        name: :combat_worker,
        queue: "combat-actions",
        connection: :arena_redis,
        processor: &Arena.CombatProcessor.process/1,
        concurrency: 10},

      # Combat event monitor (observe all events)
      {EchoMQ.QueueEvents,
        name: :combat_events,
        queue: "combat-actions",
        connection: :arena_redis,
        handler: Arena.CombatEventHandler,
        handler_state: %{}},

      # Matchmaking event monitor
      {EchoMQ.QueueEvents,
        name: :matchmaking_events,
        queue: "matchmaking",
        connection: :arena_redis,
        handler: Arena.MatchmakingEventHandler},

      # Phoenix PubSub for LiveView
      {Phoenix.PubSub, name: Arena.PubSub}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
```

Each `EchoMQ.QueueEvents` instance opens its own blocking Redis connection (separate from the shared connection pool) because `XREAD BLOCK` monopolizes the connection for the duration of the block timeout. The worker's main connection and the event listener's blocking connection never interfere.

> **Benefit**: Phoenix.PubSub distributes events across clustered BEAM nodes — built-in multi-server broadcasting.

</tab>
<tab title="Go">

```go
func main() {
    ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt)
    defer cancel()

    rdb := redis.NewClient(&redis.Options{Addr: "localhost:6379"})

    // Start combat worker
    worker := echomq.NewWorker("combat-actions", rdb, echomq.WorkerOptions{
        Concurrency: 10,
    })
    worker.Process(combatProcessor)

    // Start event monitor in background goroutine
    combatMonitor := NewCombatEventMonitor(rdb, "combat-actions")
    handler := &CombatEventHandler{}

    var wg sync.WaitGroup
    wg.Add(2)

    go func() {
        defer wg.Done()
        combatMonitor.Listen(ctx, func(event string, data map[string]interface{}) {
            handler.HandleEvent(event, data)
        })
    }()

    go func() {
        defer wg.Done()
        if err := worker.Start(ctx); err != nil {
            log.Printf("Worker stopped: %v", err)
        }
    }()

    wg.Wait()
}
```

> **Benefit**: Goroutine-per-job with semaphore-based limiting achieves OS-level parallelism.

</tab>
<tab title="Node.js">

```typescript
import { Worker, QueueEvents } from "bullmq";

const connection = { host: "localhost", port: 6379 };

// Combat worker
const worker = new Worker("combat-actions", combatProcessor, {
  connection,
  concurrency: 10,
});

// Event listener (separate Redis connection internally)
const queueEvents = new QueueEvents("combat-actions", { connection });

queueEvents.on("completed", ({ jobId, returnvalue }) => {
  console.log(`Combat ${jobId} resolved: ${returnvalue}`);
});

queueEvents.on("failed", ({ jobId, failedReason }) => {
  console.error(`Combat ${jobId} rejected: ${failedReason}`);
});

// Graceful shutdown
process.on("SIGINT", async () => {
  await worker.close();
  await queueEvents.close();
  process.exit(0);
});
```

> **Tradeoff**: Event loop concurrency means I/O-bound jobs scale well but CPU-bound jobs need worker threads.

</tab>
</tabs>

## 22.7. Event Filtering

Not every consumer needs every event. For a game dashboard, you might only care about `completed`, `failed`, and `drained`. Filtering happens at the application level -- Redis delivers all events, and your handler decides what to act on.

<tabs>
<tab title="Elixir">

```elixir
defmodule Arena.DashboardHandler do
  @moduledoc "Only tracks combat outcomes for the live dashboard."
  use EchoMQ.QueueEvents.Handler

  @dashboard_events [:completed, :failed, :drained, :stalled]

  @impl true
  def init(_opts) do
    {:ok, %{completed: 0, failed: 0, stalled: 0}}
  end

  @impl true
  def handle_event(event, data, state) when event in @dashboard_events do
    new_state = case event do
      :completed ->
        Phoenix.PubSub.broadcast(Arena.PubSub, "dashboard:combat",
          {:combat_completed, data["jobId"]})
        %{state | completed: state.completed + 1}

      :failed ->
        Phoenix.PubSub.broadcast(Arena.PubSub, "dashboard:combat",
          {:combat_failed, data["jobId"], data["failedReason"]})
        %{state | failed: state.failed + 1}

      :stalled ->
        Phoenix.PubSub.broadcast(Arena.PubSub, "dashboard:combat",
          {:combat_stalled, data["jobId"]})
        %{state | stalled: state.stalled + 1}

      :drained ->
        Phoenix.PubSub.broadcast(Arena.PubSub, "dashboard:combat", :round_complete)
        state
    end

    {:ok, new_state}
  end

  @impl true
  def handle_event(_event, _data, state) do
    {:ok, state}
  end
end
```

> **Benefit**: Phoenix LiveView delivers real-time dashboards over WebSocket with zero client-side JavaScript.

</tab>
<tab title="Go">

```go
// Filter events in the handler
var dashboardEvents = map[string]bool{
    "completed": true,
    "failed":    true,
    "drained":   true,
    "stalled":   true,
}

func (h *DashboardHandler) HandleEvent(event string, data map[string]interface{}) error {
    if !dashboardEvents[event] {
        return nil // skip non-dashboard events
    }

    switch event {
    case "completed":
        h.mu.Lock()
        h.completed++
        h.mu.Unlock()
        log.Printf("[dashboard] combat resolved: job=%s (total: %d)", data["jobId"], h.completed)
    case "failed":
        h.mu.Lock()
        h.failed++
        h.mu.Unlock()
        log.Printf("[dashboard] combat rejected: job=%s", data["jobId"])
    case "drained":
        log.Printf("[dashboard] combat round complete")
    case "stalled":
        log.Printf("[dashboard] combat stalled: job=%s", data["jobId"])
    }

    return nil
}
```

> **Tradeoff**: No built-in admin UI — JSON endpoints require a separate frontend or Grafana for visualization.

</tab>
<tab title="Node.js">

```typescript
const queueEvents = new QueueEvents("combat-actions", { connection });

// Only subscribe to events you need
const DASHBOARD_EVENTS = ["completed", "failed", "drained", "stalled"] as const;

for (const event of DASHBOARD_EVENTS) {
  queueEvents.on(event, (args) => {
    switch (event) {
      case "completed":
        dashboard.update({ type: "resolved", jobId: args.jobId });
        break;
      case "failed":
        dashboard.update({ type: "rejected", jobId: args.jobId, reason: args.failedReason });
        break;
      case "drained":
        dashboard.update({ type: "round_complete" });
        break;
      case "stalled":
        dashboard.update({ type: "stalled", jobId: args.jobId });
        break;
    }
  });
}
```

> **Benefit**: Bull Board provides a production-ready admin UI with job inspection, retry, and delete.

</tab>
</tabs>

## 22.8. Combat Action Monitor

A complete example: a real-time arena dashboard that monitors combat actions, tracks statistics, and pushes updates to connected players via Phoenix PubSub.

<tabs>
<tab title="Elixir">

```elixir
defmodule Arena.CombatMonitor do
  @moduledoc "Real-time combat dashboard backed by QueueEvents."
  use GenServer

  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def get_stats do
    GenServer.call(__MODULE__, :get_stats)
  end

  @impl true
  def init(_opts) do
    {:ok, events} = EchoMQ.QueueEvents.start_link(
      queue: "combat-actions",
      connection: :arena_redis
    )
    EchoMQ.QueueEvents.subscribe(events)

    {:ok, %{
      events_pid: events,
      completed: 0,
      failed: 0,
      active: 0,
      total_damage: 0,
      highest_hit: 0,
      last_event_at: nil
    }}
  end

  @impl true
  def handle_info({:echomq_event, :active, %{"jobId" => id}}, state) do
    Phoenix.PubSub.broadcast(Arena.PubSub, "arena:combat", {:combat_started, id})
    {:noreply, %{state | active: state.active + 1, last_event_at: DateTime.utc_now()}}
  end

  def handle_info({:echomq_event, :completed, %{"jobId" => id, "returnvalue" => rv}}, state) do
    result = Jason.decode!(rv)
    damage = result["damage"] || 0

    Phoenix.PubSub.broadcast(Arena.PubSub, "arena:combat", {:combat_resolved, id, result})

    {:noreply, %{state |
      completed: state.completed + 1,
      active: max(0, state.active - 1),
      total_damage: state.total_damage + damage,
      highest_hit: max(state.highest_hit, damage),
      last_event_at: DateTime.utc_now()
    }}
  end

  def handle_info({:echomq_event, :failed, %{"jobId" => id}}, state) do
    Phoenix.PubSub.broadcast(Arena.PubSub, "arena:combat", {:combat_failed, id})
    {:noreply, %{state |
      failed: state.failed + 1,
      active: max(0, state.active - 1),
      last_event_at: DateTime.utc_now()
    }}
  end

  def handle_info({:echomq_event, :drained, _data}, state) do
    Logger.info("Arena round complete: #{state.completed} actions resolved")
    Phoenix.PubSub.broadcast(Arena.PubSub, "arena:combat", :round_complete)
    {:noreply, %{state | last_event_at: DateTime.utc_now()}}
  end

  def handle_info({:echomq_event, _event, _data}, state) do
    {:noreply, state}
  end

  @impl true
  def handle_call(:get_stats, _from, state) do
    stats = %{
      completed: state.completed,
      failed: state.failed,
      active: state.active,
      total_damage: state.total_damage,
      highest_hit: state.highest_hit,
      last_event_at: state.last_event_at
    }
    {:reply, stats, state}
  end
end
```

> **Benefit**: Phoenix LiveView delivers real-time dashboards over WebSocket with zero client-side JavaScript.

</tab>
<tab title="Go">

```go
type ArenaCombatMonitor struct {
    mu          sync.RWMutex
    completed   int
    failed      int
    active      int
    totalDamage float64
    highestHit  float64
    lastEventAt time.Time
}

func (m *ArenaCombatMonitor) HandleEvent(event string, data map[string]interface{}) {
    m.mu.Lock()
    defer m.mu.Unlock()

    m.lastEventAt = time.Now()

    switch event {
    case "active":
        m.active++
        log.Printf("[arena] combat started: job=%s (active: %d)", data["jobId"], m.active)

    case "completed":
        m.completed++
        if m.active > 0 {
            m.active--
        }
        if rv, ok := data["returnvalue"].(string); ok {
            var result map[string]interface{}
            if err := json.Unmarshal([]byte(rv), &result); err == nil {
                if damage, ok := result["damage"].(float64); ok {
                    m.totalDamage += damage
                    if damage > m.highestHit {
                        m.highestHit = damage
                    }
                }
            }
        }
        log.Printf("[arena] combat resolved: job=%s (total: %d)", data["jobId"], m.completed)

    case "failed":
        m.failed++
        if m.active > 0 {
            m.active--
        }
        log.Printf("[arena] combat rejected: job=%s", data["jobId"])

    case "drained":
        log.Printf("[arena] round complete: %d resolved, %d rejected", m.completed, m.failed)
    }
}

func (m *ArenaCombatMonitor) Stats() map[string]interface{} {
    m.mu.RLock()
    defer m.mu.RUnlock()
    return map[string]interface{}{
        "completed":    m.completed,
        "failed":       m.failed,
        "active":       m.active,
        "total_damage": m.totalDamage,
        "highest_hit":  m.highestHit,
        "last_event":   m.lastEventAt,
    }
}
```

> **Tradeoff**: Lock extension requires periodic goroutine-based timers — manual lifecycle management.

</tab>
<tab title="Node.js">

```typescript
import { QueueEvents } from "bullmq";

class ArenaCombatMonitor {
  private completed = 0;
  private failed = 0;
  private active = 0;
  private totalDamage = 0;
  private highestHit = 0;
  private lastEventAt: Date | null = null;

  constructor(private queueEvents: QueueEvents) {
    queueEvents.on("active", ({ jobId }) => {
      this.active++;
      this.lastEventAt = new Date();
      console.log(`[arena] combat started: job=${jobId} (active: ${this.active})`);
    });

    queueEvents.on("completed", ({ jobId, returnvalue }) => {
      this.completed++;
      this.active = Math.max(0, this.active - 1);
      this.lastEventAt = new Date();

      const result = JSON.parse(returnvalue || "{}");
      const damage = result.damage || 0;
      this.totalDamage += damage;
      this.highestHit = Math.max(this.highestHit, damage);

      console.log(`[arena] combat resolved: job=${jobId} (total: ${this.completed})`);
    });

    queueEvents.on("failed", ({ jobId }) => {
      this.failed++;
      this.active = Math.max(0, this.active - 1);
      this.lastEventAt = new Date();
      console.error(`[arena] combat rejected: job=${jobId}`);
    });

    queueEvents.on("drained", () => {
      console.log(`[arena] round complete: ${this.completed} resolved, ${this.failed} rejected`);
    });
  }

  getStats() {
    return {
      completed: this.completed,
      failed: this.failed,
      active: this.active,
      totalDamage: this.totalDamage,
      highestHit: this.highestHit,
      lastEventAt: this.lastEventAt,
    };
  }
}

const queueEvents = new QueueEvents("combat-actions", { connection });
const monitor = new ArenaCombatMonitor(queueEvents);
```

> **Benefit**: `queue.drain()` removes all waiting jobs — `queue.obliterate()` removes everything.

</tab>
</tabs>

## 22.9. Matchmaking Progress Tracking

QueueEvents combined with progress updates creates a real-time matchmaking experience. The client sees each phase -- searching, expanding, evaluating, matched -- as it happens.

<tabs>
<tab title="Elixir">

```elixir
defmodule Arena.MatchmakingTracker do
  @moduledoc "Tracks matchmaking progress and notifies waiting players."
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    {:ok, events} = EchoMQ.QueueEvents.start_link(
      queue: "matchmaking",
      connection: :arena_redis
    )
    EchoMQ.QueueEvents.subscribe(events)

    {:ok, %{events_pid: events, active_searches: %{}}}
  end

  @impl true
  def handle_info({:echomq_event, :active, %{"jobId" => id}}, state) do
    # Player entered the matchmaking queue
    Phoenix.PubSub.broadcast(Arena.PubSub, "matchmaking:#{id}", {:status, :searching})
    searches = Map.put(state.active_searches, id, :searching)
    {:noreply, %{state | active_searches: searches}}
  end

  def handle_info({:echomq_event, :progress, %{"jobId" => id, "data" => progress}}, state) do
    phase = progress
    Phoenix.PubSub.broadcast(Arena.PubSub, "matchmaking:#{id}", {:progress, phase})
    searches = Map.put(state.active_searches, id, phase)
    {:noreply, %{state | active_searches: searches}}
  end

  def handle_info({:echomq_event, :completed, %{"jobId" => id, "returnvalue" => rv}}, state) do
    match = Jason.decode!(rv)
    Phoenix.PubSub.broadcast(Arena.PubSub, "matchmaking:#{id}",
      {:matched, match["match_id"], match["opponent_id"]})
    searches = Map.delete(state.active_searches, id)
    {:noreply, %{state | active_searches: searches}}
  end

  def handle_info({:echomq_event, :failed, %{"jobId" => id, "failedReason" => reason}}, state) do
    Phoenix.PubSub.broadcast(Arena.PubSub, "matchmaking:#{id}", {:failed, reason})
    searches = Map.delete(state.active_searches, id)
    {:noreply, %{state | active_searches: searches}}
  end

  def handle_info({:echomq_event, _event, _data}, state) do
    {:noreply, state}
  end
end
```

> **Benefit**: Phoenix.PubSub distributes events across clustered BEAM nodes — built-in multi-server broadcasting.

</tab>
<tab title="Go">

```go
type MatchmakingTracker struct {
    mu             sync.RWMutex
    activeSearches map[string]string // jobID -> phase
}

func NewMatchmakingTracker() *MatchmakingTracker {
    return &MatchmakingTracker{activeSearches: make(map[string]string)}
}

func (t *MatchmakingTracker) HandleEvent(event string, data map[string]interface{}) {
    jobID, _ := data["jobId"].(string)

    t.mu.Lock()
    defer t.mu.Unlock()

    switch event {
    case "active":
        t.activeSearches[jobID] = "searching"
        log.Printf("[matchmaking] search started: job=%s", jobID)

    case "progress":
        if progress, ok := data["data"].(string); ok {
            t.activeSearches[jobID] = progress
            log.Printf("[matchmaking] progress: job=%s phase=%s", jobID, progress)
        }

    case "completed":
        delete(t.activeSearches, jobID)
        if rv, ok := data["returnvalue"].(string); ok {
            var match map[string]interface{}
            json.Unmarshal([]byte(rv), &match)
            log.Printf("[matchmaking] matched: job=%s opponent=%v", jobID, match["opponent_id"])
        }

    case "failed":
        delete(t.activeSearches, jobID)
        log.Printf("[matchmaking] search failed: job=%s", jobID)
    }
}

func (t *MatchmakingTracker) ActiveSearches() int {
    t.mu.RLock()
    defer t.mu.RUnlock()
    return len(t.activeSearches)
}
```

> **Tradeoff**: Lock extension requires periodic goroutine-based timers — manual lifecycle management.

</tab>
<tab title="Node.js">

```typescript
import { QueueEvents } from "bullmq";

class MatchmakingTracker {
  private activeSearches = new Map<string, string>();

  constructor(queueEvents: QueueEvents) {
    queueEvents.on("active", ({ jobId }) => {
      this.activeSearches.set(jobId, "searching");
      console.log(`[matchmaking] search started: job=${jobId}`);
    });

    queueEvents.on("progress", ({ jobId, data }) => {
      this.activeSearches.set(jobId, data);
      console.log(`[matchmaking] progress: job=${jobId} phase=${data}`);
    });

    queueEvents.on("completed", ({ jobId, returnvalue }) => {
      this.activeSearches.delete(jobId);
      const match = JSON.parse(returnvalue || "{}");
      console.log(`[matchmaking] matched: job=${jobId} opponent=${match.opponent_id}`);
    });

    queueEvents.on("failed", ({ jobId, failedReason }) => {
      this.activeSearches.delete(jobId);
      console.log(`[matchmaking] search failed: job=${jobId}: ${failedReason}`);
    });
  }

  getActiveSearchCount(): number {
    return this.activeSearches.size;
  }
}

const matchEvents = new QueueEvents("matchmaking", { connection });
const tracker = new MatchmakingTracker(matchEvents);
```

> **Benefit**: `job.updateProgress()` triggers `progress` events on QueueEvents listeners.

</tab>
</tabs>

## 22.10. Queue Drain Detection

The `drained` event fires when a queue has no more waiting jobs. In a game server, this signals that all combat actions for a round have been dispatched to workers. Combined with tracking active job count, you can detect when a round is fully resolved.

<tabs>
<tab title="Elixir">

```elixir
defmodule Arena.RoundManager do
  @moduledoc "Detects when a combat round is fully resolved."
  use GenServer

  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    {:ok, events} = EchoMQ.QueueEvents.start_link(
      queue: "combat-actions",
      connection: :arena_redis
    )
    EchoMQ.QueueEvents.subscribe(events)

    {:ok, %{events_pid: events, active: 0, drained: false, round: 1}}
  end

  @impl true
  def handle_info({:echomq_event, :active, _data}, state) do
    {:noreply, %{state | active: state.active + 1, drained: false}}
  end

  def handle_info({:echomq_event, :completed, _data}, state) do
    new_active = max(0, state.active - 1)
    maybe_complete_round(%{state | active: new_active})
  end

  def handle_info({:echomq_event, :failed, _data}, state) do
    new_active = max(0, state.active - 1)
    maybe_complete_round(%{state | active: new_active})
  end

  def handle_info({:echomq_event, :drained, _data}, state) do
    maybe_complete_round(%{state | drained: true})
  end

  def handle_info({:echomq_event, _event, _data}, state) do
    {:noreply, state}
  end

  defp maybe_complete_round(%{drained: true, active: 0} = state) do
    Logger.info("Round #{state.round} fully resolved — starting next round")
    Phoenix.PubSub.broadcast(Arena.PubSub, "arena:rounds",
      {:round_complete, state.round})
    {:noreply, %{state | round: state.round + 1, drained: false}}
  end

  defp maybe_complete_round(state) do
    {:noreply, state}
  end
end
```

> **Benefit**: Phoenix.PubSub distributes events across clustered BEAM nodes — built-in multi-server broadcasting.

</tab>
<tab title="Go">

```go
type RoundManager struct {
    mu      sync.Mutex
    active  int
    drained bool
    round   int
}

func NewRoundManager() *RoundManager {
    return &RoundManager{round: 1}
}

func (rm *RoundManager) HandleEvent(event string, data map[string]interface{}) {
    rm.mu.Lock()
    defer rm.mu.Unlock()

    switch event {
    case "active":
        rm.active++
        rm.drained = false

    case "completed", "failed":
        if rm.active > 0 {
            rm.active--
        }
        rm.maybeCompleteRound()

    case "drained":
        rm.drained = true
        rm.maybeCompleteRound()
    }
}

func (rm *RoundManager) maybeCompleteRound() {
    if rm.drained && rm.active == 0 {
        log.Printf("[arena] Round %d fully resolved — starting next round", rm.round)
        rm.round++
        rm.drained = false
    }
}
```

> **Tradeoff**: Lock extension requires periodic goroutine-based timers — manual lifecycle management.

</tab>
<tab title="Node.js">

```typescript
class RoundManager {
  private active = 0;
  private drained = false;
  private round = 1;

  constructor(queueEvents: QueueEvents) {
    queueEvents.on("active", () => {
      this.active++;
      this.drained = false;
    });

    queueEvents.on("completed", () => {
      this.active = Math.max(0, this.active - 1);
      this.maybeCompleteRound();
    });

    queueEvents.on("failed", () => {
      this.active = Math.max(0, this.active - 1);
      this.maybeCompleteRound();
    });

    queueEvents.on("drained", () => {
      this.drained = true;
      this.maybeCompleteRound();
    });
  }

  private maybeCompleteRound() {
    if (this.drained && this.active === 0) {
      console.log(`[arena] Round ${this.round} fully resolved — starting next round`);
      this.round++;
      this.drained = false;
    }
  }
}

const roundEvents = new QueueEvents("combat-actions", { connection });
const roundMgr = new RoundManager(roundEvents);
```

> **Benefit**: `queue.drain()` removes all waiting jobs — `queue.obliterate()` removes everything.

</tab>
</tabs>

## 22.11. Cross-Language Event Compatibility

Events are wire-compatible across all three runtimes because they share the same Redis Streams format. A job added by a Node.js producer, processed by a Go worker, and monitored by an Elixir QueueEvents listener will work seamlessly -- the event format is identical.

<tabs>
<tab title="Elixir">

```elixir
# Elixir listener receives events from Go and Node.js workers
{:ok, events} = EchoMQ.QueueEvents.start_link(
  queue: "combat-actions",
  connection: :arena_redis
)
EchoMQ.QueueEvents.subscribe(events)

receive do
  # This fires whether the job was processed by Elixir, Go, or Node.js
  {:echomq_event, :completed, %{"jobId" => id, "returnvalue" => rv}} ->
    result = Jason.decode!(rv)
    IO.puts("Job #{id} completed (cross-runtime): damage=#{result["damage"]}")
end
```

> **Benefit**: `:telemetry` integration provides zero-cost event dispatch when no handlers are attached.

</tab>
<tab title="Go">

```go
// Go emits events that Elixir and Node.js listeners receive
// The EventEmitter uses XADD with the same field format:
//   event:        "completed"
//   jobId:        "abc123"
//   returnvalue:  "{\"damage\":150}"
//   timestamp:    1707350400000
//   attemptsMade: 1

// Events emitted by the Go worker are automatically consumed by:
// - Elixir: EchoMQ.QueueEvents GenServer (XREAD BLOCK)
// - Node.js: QueueEvents class (XREAD BLOCK)

// Go can also read events from other runtimes:
monitor := NewCombatEventMonitor(rdb, "combat-actions")
go monitor.Listen(ctx, func(event string, data map[string]interface{}) {
    // Receives events from Elixir workers, Go workers, and Node.js workers
    log.Printf("Cross-runtime event: %s job=%v", event, data["jobId"])
})
```

> **Tradeoff**: Lock extension requires periodic goroutine-based timers — manual lifecycle management.

</tab>
<tab title="Node.js">

```typescript
// Node.js listener receives events from Elixir and Go workers
const queueEvents = new QueueEvents("combat-actions", { connection });

queueEvents.on("completed", ({ jobId, returnvalue }) => {
  // This fires whether the job was processed by Elixir, Go, or Node.js
  const result = JSON.parse(returnvalue || "{}");
  console.log(`Job ${jobId} completed (cross-runtime): damage=${result.damage}`);
});

// Event field mapping across runtimes:
// Redis Stream field  | Elixir data key    | Go data key     | Node.js arg
// "returnvalue"       | data["returnvalue"] | Values["returnvalue"] | returnvalue
// "jobId"             | data["jobId"]       | Values["jobId"]       | jobId
// "failedReason"      | data["failedReason"]| Values["error"]       | failedReason
// "event"             | (parsed to atom)    | Values["event"]       | (event name)
```

> **Benefit**: QueueEvents wraps XREAD internally — consumers get typed events via EventEmitter.

</tab>
</tabs>

## 22.12. Performance Considerations

### Event Stream Trimming

The event stream grows with every job lifecycle event. Left untrimmed, a queue processing 1,000 jobs/second would generate 3,000-5,000 events/second (waiting, active, completed per job). The `maxLen` parameter on the EventEmitter controls approximate trimming.

<tabs>
<tab title="Elixir">

```elixir
# The event stream key follows the pattern: bull:{queue}:events
# Default approximate max length is ~10,000 entries

# Check current stream length
{:ok, len} = Redix.command(:arena_redis, ["XLEN", "bull:combat-actions:events"])
IO.puts("Event stream length: #{len}")

# Manual trimming (if needed for maintenance)
{:ok, trimmed} = Redix.command(:arena_redis, [
  "XTRIM", "bull:combat-actions:events", "MAXLEN", "~", "5000"
])
IO.puts("Trimmed #{trimmed} entries")

# For high-throughput queues, consider shorter max lengths:
# - 1,000 jobs/sec = ~5,000 events/sec
# - maxLen ~10,000 = ~2 seconds of history
# - maxLen ~100,000 = ~20 seconds of history
```

> **Benefit**: Redix XREAD integration provides native stream consumption — no wrapper library needed.

</tab>
<tab title="Go">

```go
// The Go EventEmitter trims on every XADD with approximate MAXLEN
emitter := echomq.NewEventEmitter("combat-actions", rdb, 10000)

// Each Emit call includes: XADD stream MAXLEN ~ 10000
// The ~ (approximate) flag lets Redis trim efficiently
// without counting exact entries on every write

// Check current stream length
length, _ := rdb.XLen(ctx, "bull:combat-actions:events").Result()
fmt.Printf("Event stream length: %d\n", length)

// For high-throughput game servers, tune maxLen based on:
// - How far back you need replay capability
// - Memory budget for event streams
// - Number of queues sharing the Redis instance
highThroughputEmitter := echomq.NewEventEmitter("combat-actions", rdb, 50000)
```

> **Benefit**: `redis.XRead` returns typed results — stream entries are immediately usable.

</tab>
<tab title="Node.js">

```typescript
// Node.js QueueEvents has a configurable blockingTimeout for polling efficiency
const queueEvents = new QueueEvents("combat-actions", {
  connection,
  blockingTimeout: 10000, // 10s XREAD BLOCK (default)
});

// Check stream length
const client = queueEvents.client;
const length = await client.xLen("bull:combat-actions:events");
console.log(`Event stream length: ${length}`);

// Performance tips for high-throughput queues:
// 1. Use longer blockingTimeout (10-30s) to reduce Redis round-trips
// 2. Process events in batches (XREAD returns multiple events per call)
// 3. Keep handler logic fast — slow handlers cause event processing lag
// 4. Consider separate QueueEvents instances per consumer for isolation
```

> **Benefit**: `limiter` option integrates with BullMQ's built-in token bucket implementation.

</tab>
</tabs>

## 22.13. Comparison: Event Features by Runtime

| Feature | Elixir | Go | Node.js |
|---------|--------|-----|---------|
| Worker callbacks | 7 callback options | Not implemented | EventEmitter pattern |
| QueueEvents listener | GenServer + XREAD BLOCK | Not implemented (use XREAD directly) | QueueEvents class |
| Event emission | Lua scripts (atomic) | EventEmitter (XADD) | Lua scripts (atomic) |
| Handler module | `EchoMQ.QueueEvents.Handler` | Manual interface | EventEmitter `.on()` |
| Multiple subscribers | `subscribe/2` fan-out | Manual channel fan-out | Multiple `.on()` handlers |
| Event replay | `last_event_id` option | Custom `lastID` tracking | `lastEventId` option |
| Supervision | OTP supervisor child | goroutine + context | Manual lifecycle |
| Auto-cleanup | Process monitor | Context cancellation | `.close()` method |

---

*Previous: [Repeatable Jobs](ch21-repeatable-jobs.md) | Next: [Custom Events](ch23-custom-events.md)*
