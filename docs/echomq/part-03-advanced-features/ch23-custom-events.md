# Chapter 23. Custom Events

EchoMQ's event system is not limited to job lifecycle events. You can publish and subscribe to **custom events** -- arbitrary, user-defined events that flow through the same Redis Streams infrastructure. Custom events enable building distributed event-driven architectures where different parts of your game server communicate through the queue's event stream without needing a separate messaging layer.

For Fireheadz Arena, custom events power achievement notifications ("Dragon Slayer unlocked!"), game room status broadcasts (lobby to in-progress to completed), match-ready coordination signals, and live combat metrics feeds for spectator dashboards.

## 23.1. How Custom Events Work

Custom events use the same `bull:{queue}:events` Redis Stream as standard job lifecycle events. The flow is identical:

```
Publisher                          Redis Stream                     Subscriber
   |                                    |                               |
   +-- XADD bull:queue:events --------> |                               |
   |   {event: "achievement-unlocked",  |                               |
   |    playerId: "PLR0K48QjihpC4",            +--- XREAD BLOCK -------------> |
   |    achievement: "dragon-slayer"}   |    STREAMS bull:queue:events  |
   |                                    |                               |
```

Key characteristics:

- Custom events are **persistent** (stored in the stream, not fire-and-forget)
- They are **ordered** (Redis Streams guarantee ordering within a stream)
- They are **cross-runtime** (published from any language, received by any language)
- They share the same **trimming policy** as standard events (`MAXLEN ~`)
- Subscribers receive both standard and custom events on the same stream

## 23.2. Publishing Custom Events

<tabs>
<tab title="Elixir">

```elixir
# Elixir publishes custom events directly to the Redis event stream
defmodule Arena.CustomEvents do
  @moduledoc "Publish custom game events to the EchoMQ event stream."

  @doc "Publish an achievement unlock event."
  def achievement_unlocked(redis, queue, player_id, achievement) do
    stream_key = "bull:#{queue}:events"

    Redix.command(redis, [
      "XADD", stream_key, "MAXLEN", "~", "10000", "*",
      "event", "achievement-unlocked",
      "playerId", player_id,
      "achievement", achievement,
      "timestamp", to_string(System.system_time(:millisecond))
    ])
  end

  @doc "Publish a game room status change."
  def room_status_changed(redis, queue, room_id, status) do
    stream_key = "bull:#{queue}:events"

    Redix.command(redis, [
      "XADD", stream_key, "MAXLEN", "~", "10000", "*",
      "event", "room-status",
      "roomId", room_id,
      "status", status,
      "timestamp", to_string(System.system_time(:millisecond))
    ])
  end
end

# Usage
Arena.CustomEvents.achievement_unlocked(:arena_redis, "combat-actions",
  "PLR0K48QjihpC4", "dragon-slayer")

Arena.CustomEvents.room_status_changed(:arena_redis, "combat-actions",
  "MTH0K5M2vuIULY", "in-progress")
```

> **Benefit**: LockManager batches all lock renewals into a single GenServer tick — O(1) timer overhead.

</tab>
<tab title="Go">

```go
// Go can publish custom events using the EventEmitter.Emit method directly
func publishAchievement(ctx context.Context, emitter *echomq.EventEmitter, playerID, achievement string) error {
    return emitter.Emit(ctx, echomq.Event{
        EventType: "achievement-unlocked",
        JobID:     "",  // No associated job
        Timestamp: time.Now().UnixMilli(),
        Data: map[string]interface{}{
            "playerId":    playerID,
            "achievement": achievement,
        },
    })
}

func publishRoomStatus(ctx context.Context, emitter *echomq.EventEmitter, roomID, status string) error {
    return emitter.Emit(ctx, echomq.Event{
        EventType: "room-status",
        JobID:     "",
        Timestamp: time.Now().UnixMilli(),
        Data: map[string]interface{}{
            "roomId": roomID,
            "status": status,
        },
    })
}

// Usage
emitter := echomq.NewEventEmitter("combat-actions", rdb, 10000)
publishAchievement(ctx, emitter, "PLR0K48QjihpC4", "dragon-slayer")
publishRoomStatus(ctx, emitter, "MTH0K5M2vuIULY", "in-progress")
```

> **Tradeoff**: Lock extension requires periodic goroutine-based timers — manual lifecycle management.

</tab>
<tab title="Node.js">

```typescript
import { QueueEventsProducer } from "bullmq";

const producer = new QueueEventsProducer("combat-actions", {
  connection: { host: "localhost", port: 6379 },
});

// Publish achievement unlock
await producer.publishEvent({
  eventName: "achievement-unlocked",
  playerId: "PLR0K48QjihpC4",
  achievement: "dragon-slayer",
  timestamp: Date.now(),
});

// Publish room status change
await producer.publishEvent({
  eventName: "room-status",
  roomId: "MTH0K5M2vuIULY",
  status: "in-progress",
  timestamp: Date.now(),
});
```

> **Benefit**: Built-in lock extension runs automatically within the Worker class — transparent to processors.

</tab>
</tabs>

> **⚠️ Go Gap**: Custom event publishing and subscription are not implemented. The Go SDK cannot publish or listen for user-defined events on the queue event stream.
> **Proposed Solution**: Add `Queue.EmitCustomEvent()` using `XADD` to the `bull:{queue}:events` stream, and extend `QueueEvents` (once implemented) to dispatch custom event types alongside standard lifecycle events.

## 23.3. Receiving Custom Events

Custom events arrive through the same QueueEvents listener as standard events. The event type becomes an atom in Elixir (with hyphens preserved as `:"hyphenated-name"`), a string in Go, and an EventEmitter event name in Node.js.

<tabs>
<tab title="Elixir">

```elixir
defmodule Arena.GameEventHandler do
  @moduledoc "Handles both standard job events and custom game events."
  use EchoMQ.QueueEvents.Handler

  require Logger

  @impl true
  def init(_opts) do
    {:ok, %{achievements: [], room_transitions: 0}}
  end

  # Standard job event
  @impl true
  def handle_event(:completed, %{"jobId" => id, "returnvalue" => rv}, state) do
    Logger.info("Job #{id} completed: #{rv}")
    {:ok, state}
  end

  # Custom event: achievement unlocked
  @impl true
  def handle_event(:"achievement-unlocked", data, state) do
    player_id = data["playerId"]
    achievement = data["achievement"]
    Logger.info("Achievement unlocked: #{player_id} earned '#{achievement}'")

    # Push to LiveView dashboard
    Phoenix.PubSub.broadcast(Arena.PubSub, "achievements:#{player_id}",
      {:achievement, achievement})

    {:ok, %{state | achievements: [{player_id, achievement} | state.achievements]}}
  end

  # Custom event: room status
  @impl true
  def handle_event(:"room-status", data, state) do
    room_id = data["roomId"]
    status = data["status"]
    Logger.info("Room #{room_id} -> #{status}")

    Phoenix.PubSub.broadcast(Arena.PubSub, "rooms:#{room_id}", {:status, status})

    {:ok, %{state | room_transitions: state.room_transitions + 1}}
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
  handler: Arena.GameEventHandler
)
```

> **Benefit**: Phoenix LiveView delivers real-time dashboards over WebSocket with zero client-side JavaScript.

</tab>
<tab title="Go">

```go
// Go receives custom events through the same XREAD loop
func handleGameEvent(event string, data map[string]interface{}) {
    switch event {
    // Standard job events
    case "completed":
        log.Printf("Job %s completed: %v", data["jobId"], data["returnvalue"])

    // Custom event: achievement unlocked
    case "achievement-unlocked":
        playerID := data["playerId"].(string)
        achievement := data["achievement"].(string)
        log.Printf("Achievement unlocked: %s earned '%s'", playerID, achievement)

    // Custom event: room status
    case "room-status":
        roomID := data["roomId"].(string)
        status := data["status"].(string)
        log.Printf("Room %s -> %s", roomID, status)

    default:
        log.Printf("Unknown event: %s data=%v", event, data)
    }
}

// Wire it up
monitor := NewCombatEventMonitor(rdb, "combat-actions")
go monitor.Listen(ctx, handleGameEvent)
```

> **Tradeoff**: Lock extension requires periodic goroutine-based timers — manual lifecycle management.

</tab>
<tab title="Node.js">

```typescript
import { QueueEvents } from "bullmq";

const queueEvents = new QueueEvents("combat-actions", { connection });

// Standard job event
queueEvents.on("completed", ({ jobId, returnvalue }) => {
  console.log(`Job ${jobId} completed: ${returnvalue}`);
});

// Custom event: achievement unlocked
queueEvents.on("achievement-unlocked", ({ playerId, achievement }: any) => {
  console.log(`Achievement unlocked: ${playerId} earned '${achievement}'`);
  notifyPlayer(playerId, `You earned: ${achievement}!`);
});

// Custom event: room status
queueEvents.on("room-status", ({ roomId, status }: any) => {
  console.log(`Room ${roomId} -> ${status}`);
  broadcastRoomUpdate(roomId, status);
});
```

> **Benefit**: Built-in lock extension runs automatically within the Worker class — transparent to processors.

</tab>
</tabs>

## 23.4. Reserved Event Names

The following event names are reserved for EchoMQ's internal job lifecycle. Do not use these names for custom events -- they will collide with standard events and produce unexpected behavior.

| Reserved Name | Purpose |
|---------------|---------|
| `added` | Job added to queue |
| `waiting` | Job waiting for processing |
| `active` | Job started processing |
| `progress` | Job progress updated |
| `completed` | Job completed successfully |
| `failed` | Job failed |
| `delayed` | Job delayed |
| `stalled` | Job stalled (worker crash) |
| `removed` | Job removed from queue |
| `drained` | Queue has no waiting jobs |
| `paused` | Queue paused |
| `resumed` | Queue resumed |
| `waiting-children` | Parent waiting for children |
| `duplicated` | Job deduplicated |

A safe naming convention for custom events: use a domain prefix like `game-`, `arena-`, or `match-` to avoid future collisions if EchoMQ adds new standard events.

```
game-achievement-unlocked    (not: achievement-unlocked)
arena-round-complete         (not: completed)
match-ready                  (not: active)
```

## 23.5. Event Data Serialization

Custom event data is stored as Redis Stream fields (flat string key-value pairs). Complex data structures must be serialized to strings before publishing and deserialized on receipt.

<tabs>
<tab title="Elixir">

```elixir
defmodule Arena.CustomEvents do
  @doc "Publish combat stats as a custom event with JSON-encoded data."
  def combat_stats(redis, queue, match_id, stats) do
    # Encode complex data as JSON string
    stats_json = Jason.encode!(stats)
    stream_key = "bull:#{queue}:events"

    Redix.command(redis, [
      "XADD", stream_key, "MAXLEN", "~", "10000", "*",
      "event", "combat-stats",
      "matchId", match_id,
      "data", stats_json,
      "timestamp", to_string(System.system_time(:millisecond))
    ])
  end
end

# Publish
Arena.CustomEvents.combat_stats(:arena_redis, "combat-actions", "MTH0K5M2vuIULY", %{
  "top_damage" => %{"player" => "PLR0K48QjihpC4", "total" => 15_420},
  "top_healing" => %{"player" => "PLR2Nc03LjrE6p", "total" => 8_750},
  "duration_ms" => 180_000,
  "kills" => 12,
  "deaths" => 8
})

# Receive and decode
def handle_event(:"combat-stats", data, state) do
  stats = Jason.decode!(data["data"])
  top_dmg = stats["top_damage"]["player"]
  Logger.info("Match #{data["matchId"]} stats: top damage by #{top_dmg}")
  {:ok, state}
end
```

> **Benefit**: Redix XREAD integration provides native stream consumption — no wrapper library needed.

</tab>
<tab title="Go">

```go
// Publish complex data as JSON-encoded string
func publishCombatStats(ctx context.Context, emitter *echomq.EventEmitter, matchID string, stats interface{}) error {
    statsJSON, err := json.Marshal(stats)
    if err != nil {
        return fmt.Errorf("failed to marshal stats: %w", err)
    }

    return emitter.Emit(ctx, echomq.Event{
        EventType: "combat-stats",
        Timestamp: time.Now().UnixMilli(),
        Data: map[string]interface{}{
            "matchId": matchID,
            "data":    string(statsJSON),
        },
    })
}

// Publish
publishCombatStats(ctx, emitter, "MTH0K5M2vuIULY", map[string]interface{}{
    "top_damage":  map[string]interface{}{"player": "PLR0K48QjihpC4", "total": 15420},
    "top_healing": map[string]interface{}{"player": "PLR2Nc03LjrE6p", "total": 8750},
    "duration_ms": 180000,
    "kills":       12,
    "deaths":      8,
})

// Receive and decode
func handleCombatStats(data map[string]interface{}) {
    matchID := data["matchId"].(string)
    statsJSON := data["data"].(string)

    var stats map[string]interface{}
    json.Unmarshal([]byte(statsJSON), &stats)

    topDmg := stats["top_damage"].(map[string]interface{})
    log.Printf("Match %s stats: top damage by %s", matchID, topDmg["player"])
}
```

> **Benefit**: Channel-based event delivery integrates naturally with Go's select statement for multiplexing.

</tab>
<tab title="Node.js">

```typescript
// Publish complex data as JSON-encoded string
await producer.publishEvent({
  eventName: "combat-stats",
  matchId: "MTH0K5M2vuIULY",
  data: JSON.stringify({
    top_damage: { player: "PLR0K48QjihpC4", total: 15420 },
    top_healing: { player: "PLR2Nc03LjrE6p", total: 8750 },
    duration_ms: 180000,
    kills: 12,
    deaths: 8,
  }),
});

// Receive and decode
queueEvents.on("combat-stats", ({ matchId, data }: any) => {
  const stats = JSON.parse(data);
  console.log(`Match ${matchId} stats: top damage by ${stats.top_damage.player}`);
});
```

> **Benefit**: EventEmitter pattern is native to Node.js — existing event-handling code works directly.

</tab>
</tabs>

## 23.6. Match-Ready Coordination

Custom events can coordinate multi-player state transitions. When all players in a match have loaded, publish a `match-ready` event that triggers the game loop to start.

<tabs>
<tab title="Elixir">

```elixir
defmodule Arena.MatchCoordinator do
  @moduledoc "Coordinates match-ready signals using custom events."
  use GenServer

  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def player_loaded(match_id, player_id) do
    GenServer.cast(__MODULE__, {:player_loaded, match_id, player_id})
  end

  @impl true
  def init(_opts) do
    {:ok, events} = EchoMQ.QueueEvents.start_link(
      queue: "matchmaking",
      connection: :arena_redis
    )
    EchoMQ.QueueEvents.subscribe(events)

    {:ok, %{events_pid: events, pending: %{}}}
  end

  @impl true
  def handle_cast({:player_loaded, match_id, player_id}, state) do
    players = Map.get(state.pending, match_id, MapSet.new())
    players = MapSet.put(players, player_id)
    pending = Map.put(state.pending, match_id, players)

    # Check if all players are loaded (assume 2-player matches)
    if MapSet.size(players) >= 2 do
      Logger.info("Match #{match_id}: all players loaded — publishing match-ready")
      stream_key = "bull:matchmaking:events"
      Redix.command(:arena_redis, [
        "XADD", stream_key, "MAXLEN", "~", "10000", "*",
        "event", "match-ready",
        "matchId", match_id,
        "players", Jason.encode!(MapSet.to_list(players)),
        "timestamp", to_string(System.system_time(:millisecond))
      ])

      {:noreply, %{state | pending: Map.delete(pending, match_id)}}
    else
      {:noreply, %{state | pending: pending}}
    end
  end

  @impl true
  def handle_info({:echomq_event, :"match-ready", data}, state) do
    match_id = data["matchId"]
    players = Jason.decode!(data["players"])
    Logger.info("Match #{match_id} ready with players: #{inspect(players)}")

    # Start the game loop
    Arena.GameLoop.start(match_id, players)
    {:noreply, state}
  end

  def handle_info({:echomq_event, _event, _data}, state) do
    {:noreply, state}
  end
end
```

> **Benefit**: Redix XREAD integration provides native stream consumption — no wrapper library needed.

</tab>
<tab title="Go">

```go
type MatchCoordinator struct {
    mu      sync.Mutex
    rdb     *redis.Client
    emitter *echomq.EventEmitter
    pending map[string]map[string]bool // matchID -> set of playerIDs
}

func NewMatchCoordinator(rdb *redis.Client) *MatchCoordinator {
    return &MatchCoordinator{
        rdb:     rdb,
        emitter: echomq.NewEventEmitter("matchmaking", rdb, 10000),
        pending: make(map[string]map[string]bool),
    }
}

func (mc *MatchCoordinator) PlayerLoaded(ctx context.Context, matchID, playerID string) error {
    mc.mu.Lock()
    defer mc.mu.Unlock()

    if mc.pending[matchID] == nil {
        mc.pending[matchID] = make(map[string]bool)
    }
    mc.pending[matchID][playerID] = true

    // Check if all players are loaded (2-player matches)
    if len(mc.pending[matchID]) >= 2 {
        players := make([]string, 0, len(mc.pending[matchID]))
        for p := range mc.pending[matchID] {
            players = append(players, p)
        }
        playersJSON, _ := json.Marshal(players)

        log.Printf("Match %s: all players loaded — publishing match-ready", matchID)
        err := mc.emitter.Emit(ctx, echomq.Event{
            EventType: "match-ready",
            Timestamp: time.Now().UnixMilli(),
            Data: map[string]interface{}{
                "matchId": matchID,
                "players": string(playersJSON),
            },
        })

        delete(mc.pending, matchID)
        return err
    }

    return nil
}

func (mc *MatchCoordinator) HandleEvent(event string, data map[string]interface{}) {
    if event == "match-ready" {
        matchID := data["matchId"].(string)
        log.Printf("Match %s ready — starting game loop", matchID)
        // startGameLoop(matchID)
    }
}
```

> **Tradeoff**: Lock extension requires periodic goroutine-based timers — manual lifecycle management.

</tab>
<tab title="Node.js">

```typescript
import { QueueEvents, QueueEventsProducer } from "bullmq";

class MatchCoordinator {
  private pending = new Map<string, Set<string>>();
  private producer: QueueEventsProducer;

  constructor(
    private queueEvents: QueueEvents,
    producer: QueueEventsProducer,
  ) {
    this.producer = producer;

    queueEvents.on("match-ready", ({ matchId, players }: any) => {
      const playerList = JSON.parse(players);
      console.log(`Match ${matchId} ready with players: ${playerList.join(", ")}`);
      startGameLoop(matchId, playerList);
    });
  }

  async playerLoaded(matchId: string, playerId: string) {
    if (!this.pending.has(matchId)) {
      this.pending.set(matchId, new Set());
    }
    this.pending.get(matchId)!.add(playerId);

    // Check if all players loaded (2-player matches)
    if (this.pending.get(matchId)!.size >= 2) {
      const players = Array.from(this.pending.get(matchId)!);
      console.log(`Match ${matchId}: all players loaded — publishing match-ready`);

      await this.producer.publishEvent({
        eventName: "match-ready",
        matchId,
        players: JSON.stringify(players),
      });

      this.pending.delete(matchId);
    }
  }
}

const queueEvents = new QueueEvents("matchmaking", { connection });
const producer = new QueueEventsProducer("matchmaking", { connection });
const coordinator = new MatchCoordinator(queueEvents, producer);
```

> **Benefit**: EventEmitter pattern is native to Node.js — existing event-handling code works directly.

</tab>
</tabs>

## 23.7. Live Metrics Feed

Custom events power real-time spectator dashboards by streaming DPS, healing, and other combat statistics during a match.

<tabs>
<tab title="Elixir">

```elixir
defmodule Arena.MetricsFeed do
  @moduledoc "Publishes live combat metrics for spectator dashboards."

  @doc "Publish a DPS snapshot from the combat worker."
  def publish_dps_snapshot(redis, match_id, player_stats) do
    stream_key = "bull:combat-actions:events"

    Redix.command(redis, [
      "XADD", stream_key, "MAXLEN", "~", "10000", "*",
      "event", "live-metrics",
      "matchId", match_id,
      "metricType", "dps-snapshot",
      "data", Jason.encode!(player_stats),
      "timestamp", to_string(System.system_time(:millisecond))
    ])
  end
end

# Worker publishes metrics during combat processing
def process(%EchoMQ.Job{name: "calculate-damage", data: data} = job) do
  result = Arena.Combat.resolve_damage(data["attacker_id"], data["target_id"], data["skill_id"])

  # Publish live metrics for spectators
  Arena.MetricsFeed.publish_dps_snapshot(:arena_redis, data["match_id"], %{
    "player_id" => data["attacker_id"],
    "damage_dealt" => result.damage,
    "skill_used" => data["skill_id"],
    "critical" => result.critical?
  })

  {:ok, result}
end

# Spectator dashboard subscribes
defmodule Arena.SpectatorDashboard do
  use EchoMQ.QueueEvents.Handler

  @impl true
  def handle_event(:"live-metrics", %{"metricType" => "dps-snapshot", "data" => data_json, "matchId" => match_id}, state) do
    stats = Jason.decode!(data_json)
    Phoenix.PubSub.broadcast(Arena.PubSub, "spectator:#{match_id}", {:dps_update, stats})
    {:ok, state}
  end

  @impl true
  def handle_event(_event, _data, state), do: {:ok, state}
end
```

> **Benefit**: Phoenix LiveView delivers real-time dashboards over WebSocket with zero client-side JavaScript.

</tab>
<tab title="Go">

```go
// Publish DPS snapshots from Go combat worker
func publishDPSSnapshot(ctx context.Context, emitter *echomq.EventEmitter, matchID string, stats map[string]interface{}) error {
    statsJSON, _ := json.Marshal(stats)
    return emitter.Emit(ctx, echomq.Event{
        EventType: "live-metrics",
        Timestamp: time.Now().UnixMilli(),
        Data: map[string]interface{}{
            "matchId":    matchID,
            "metricType": "dps-snapshot",
            "data":       string(statsJSON),
        },
    })
}

// Inside the combat processor
worker.Process(func(job *echomq.Job) (interface{}, error) {
    attackerID := job.Data["attacker_id"].(string)
    targetID := job.Data["target_id"].(string)
    matchID := job.Data["match_id"].(string)

    result := resolveDamage(attackerID, targetID, job.Data["skill_id"].(string))

    // Publish live metrics for spectators
    emitter := echomq.NewEventEmitter("combat-actions", rdb, 10000)
    publishDPSSnapshot(ctx, emitter, matchID, map[string]interface{}{
        "player_id":    attackerID,
        "damage_dealt": result.Damage,
        "skill_used":   job.Data["skill_id"],
        "critical":     result.Critical,
    })

    return result, nil
})

// Spectator dashboard consuming metrics
func (s *SpectatorDashboard) HandleEvent(event string, data map[string]interface{}) {
    if event == "live-metrics" && data["metricType"] == "dps-snapshot" {
        matchID := data["matchId"].(string)
        var stats map[string]interface{}
        json.Unmarshal([]byte(data["data"].(string)), &stats)
        log.Printf("[spectator:%s] DPS update: %v", matchID, stats)
    }
}
```

> **Tradeoff**: No built-in admin UI — JSON endpoints require a separate frontend or Grafana for visualization.

</tab>
<tab title="Node.js">

```typescript
import { QueueEventsProducer, QueueEvents } from "bullmq";

// Publish DPS snapshots from Node.js combat worker
const metricsProducer = new QueueEventsProducer("combat-actions", { connection });

async function publishDPSSnapshot(matchId: string, stats: object) {
  await metricsProducer.publishEvent({
    eventName: "live-metrics",
    matchId,
    metricType: "dps-snapshot",
    data: JSON.stringify(stats),
  });
}

// Inside the combat worker
const worker = new Worker("combat-actions", async (job) => {
  const { attacker_id, target_id, skill_id, match_id } = job.data;
  const result = resolveDamage(attacker_id, target_id, skill_id);

  // Publish live metrics for spectators
  await publishDPSSnapshot(match_id, {
    player_id: attacker_id,
    damage_dealt: result.damage,
    skill_used: skill_id,
    critical: result.critical,
  });

  return result;
}, { connection });

// Spectator dashboard subscribing
const spectatorEvents = new QueueEvents("combat-actions", { connection });

spectatorEvents.on("live-metrics", ({ matchId, metricType, data }: any) => {
  if (metricType === "dps-snapshot") {
    const stats = JSON.parse(data);
    broadcastToSpectators(matchId, { type: "dps_update", stats });
  }
});
```

> **Benefit**: Bull Board provides a production-ready admin UI with job inspection, retry, and delete.

</tab>
</tabs>

## 23.8. Event Aggregation

For high-frequency events like combat metrics, aggregating over time windows reduces downstream processing load. Buffer events and flush summaries at regular intervals.

<tabs>
<tab title="Elixir">

```elixir
defmodule Arena.MetricsAggregator do
  @moduledoc "Aggregates combat metrics over time windows."
  use GenServer

  @flush_interval 10_000  # 10 seconds

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

    :timer.send_interval(@flush_interval, :flush)

    {:ok, %{
      events_pid: events,
      buffer: [],
      window_start: System.system_time(:millisecond)
    }}
  end

  @impl true
  def handle_info({:echomq_event, :"live-metrics", data}, state) do
    {:noreply, %{state | buffer: [data | state.buffer]}}
  end

  def handle_info({:echomq_event, _event, _data}, state) do
    {:noreply, state}
  end

  def handle_info(:flush, %{buffer: []} = state) do
    {:noreply, %{state | window_start: System.system_time(:millisecond)}}
  end

  def handle_info(:flush, state) do
    window_end = System.system_time(:millisecond)
    summary = aggregate(state.buffer, state.window_start, window_end)

    Phoenix.PubSub.broadcast(Arena.PubSub, "metrics:summary", {:metrics_window, summary})

    {:noreply, %{state |
      buffer: [],
      window_start: window_end
    }}
  end

  defp aggregate(events, window_start, window_end) do
    %{
      window_start: window_start,
      window_end: window_end,
      event_count: length(events),
      total_damage: events |> Enum.map(&decode_damage/1) |> Enum.sum(),
      unique_players: events |> Enum.map(&(&1["playerId"])) |> Enum.uniq() |> length()
    }
  end

  defp decode_damage(event) do
    case Jason.decode(event["data"] || "{}") do
      {:ok, %{"damage_dealt" => d}} when is_number(d) -> d
      _ -> 0
    end
  end
end
```

> **Benefit**: Phoenix.PubSub distributes events across clustered BEAM nodes — built-in multi-server broadcasting.

</tab>
<tab title="Go">

```go
type MetricsAggregator struct {
    mu          sync.Mutex
    buffer      []map[string]interface{}
    windowStart time.Time
}

func NewMetricsAggregator() *MetricsAggregator {
    return &MetricsAggregator{
        windowStart: time.Now(),
    }
}

func (a *MetricsAggregator) HandleEvent(event string, data map[string]interface{}) {
    if event != "live-metrics" {
        return
    }
    a.mu.Lock()
    a.buffer = append(a.buffer, data)
    a.mu.Unlock()
}

func (a *MetricsAggregator) StartFlushing(ctx context.Context, interval time.Duration) {
    ticker := time.NewTicker(interval)
    defer ticker.Stop()

    for {
        select {
        case <-ctx.Done():
            return
        case <-ticker.C:
            a.flush()
        }
    }
}

func (a *MetricsAggregator) flush() {
    a.mu.Lock()
    events := a.buffer
    a.buffer = nil
    windowStart := a.windowStart
    a.windowStart = time.Now()
    a.mu.Unlock()

    if len(events) == 0 {
        return
    }

    totalDamage := 0.0
    players := make(map[string]bool)
    for _, e := range events {
        if dataStr, ok := e["data"].(string); ok {
            var data map[string]interface{}
            json.Unmarshal([]byte(dataStr), &data)
            if d, ok := data["damage_dealt"].(float64); ok {
                totalDamage += d
            }
            if p, ok := data["player_id"].(string); ok {
                players[p] = true
            }
        }
    }

    log.Printf("[metrics] Window %v-%v: %d events, %.0f damage, %d players",
        windowStart.Format("15:04:05"), time.Now().Format("15:04:05"),
        len(events), totalDamage, len(players))
}
```

> **Benefit**: `prometheus/client_golang` is the canonical Prometheus client — direct histogram/counter support.

</tab>
<tab title="Node.js">

```typescript
class MetricsAggregator {
  private buffer: Record<string, any>[] = [];
  private windowStart = Date.now();
  private timer: NodeJS.Timer;

  constructor(queueEvents: QueueEvents, flushIntervalMs = 10000) {
    queueEvents.on("live-metrics", (data: any) => {
      this.buffer.push(data);
    });

    this.timer = setInterval(() => this.flush(), flushIntervalMs);
  }

  private flush() {
    if (this.buffer.length === 0) {
      this.windowStart = Date.now();
      return;
    }

    const events = this.buffer;
    this.buffer = [];
    const windowEnd = Date.now();

    let totalDamage = 0;
    const players = new Set<string>();

    for (const event of events) {
      try {
        const data = JSON.parse(event.data || "{}");
        totalDamage += data.damage_dealt || 0;
        if (data.player_id) players.add(data.player_id);
      } catch { /* skip malformed */ }
    }

    console.log(`[metrics] Window: ${events.length} events, ${totalDamage} damage, ${players.size} players`);
    this.windowStart = windowEnd;
  }

  stop() {
    clearInterval(this.timer);
    this.flush(); // flush remaining
  }
}

const queueEvents = new QueueEvents("combat-actions", { connection });
const aggregator = new MetricsAggregator(queueEvents, 10000);
```

> **Benefit**: `prom-client` registers metrics globally — all queue instances contribute to the same counters.

</tab>
</tabs>

## 23.9. Cross-Language Custom Events

Custom events are fully cross-runtime. A Go worker can publish an achievement event, an Elixir QueueEvents listener can forward it to Phoenix PubSub, and a Node.js dashboard can subscribe to the same stream independently. The Redis Stream format is the common denominator.

The key requirement: all runtimes must use the same queue name and Redis prefix (default: `"bull"`). Event field names are strings in Redis, so ensure consistency -- if Go publishes `"playerId"`, Elixir must read `data["playerId"]` (not `data["player_id"]`).

| Aspect | Elixir | Go | Node.js |
|--------|--------|-----|---------|
| Publish custom events | `Redix.command` (XADD) | `EventEmitter.Emit` | `QueueEventsProducer.publishEvent` |
| Receive custom events | `QueueEvents` handler | XREAD loop | `QueueEvents.on(eventName)` |
| Event name format | Atom (`:""achievement-unlocked""`) | String (`"achievement-unlocked"`) | String (`"achievement-unlocked"`) |
| Data serialization | Manual JSON encode | Manual JSON encode | Automatic in `publishEvent` |

## 23.10. Comparison: Standard vs Custom Events

| Aspect | Standard Events | Custom Events |
|--------|----------------|---------------|
| Triggered by | Job lifecycle transitions | Application code |
| Event names | Fixed set (14 built-in) | User-defined (avoid reserved) |
| Data fields | Protocol-defined (`jobId`, `returnvalue`) | User-defined (any fields) |
| Emission | Automatic (Lua scripts / EventEmitter) | Manual (XADD / publishEvent) |
| Reception | Same QueueEvents listener | Same QueueEvents listener |
| Persistence | Same Redis Stream | Same Redis Stream |
| Trimming | Shared `MAXLEN` policy | Shared `MAXLEN` policy |

---

*Previous: [Queue Events](ch22-queue-events.md) | Next: [Worker Concurrency](ch24-worker-concurrency.md)*
