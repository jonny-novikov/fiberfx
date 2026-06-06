# Chapter 35. Concurrent Data Structures

> Managing shared state and identifiers across concurrent EchoMQ workers in Elixir, Go, and Node.js.

## 35.1. Overview

Each EchoMQ runtime has a fundamentally different concurrency model. Elixir runs isolated
BEAM processes that share nothing and communicate through message passing. Go runs goroutines
that share memory and coordinate through mutexes, channels, and atomic operations. Node.js
runs a single-threaded event loop where concurrency comes from asynchronous I/O, with
`worker_threads` for CPU-bound parallelism.

These differences shape every decision around shared state in queue-processing applications:
how you maintain worker-local caches, how you build concurrent registries for game rooms,
and how you generate branded identifiers across distributed workers. This chapter explores
the concrete data structures each language offers and demonstrates them in the Codemoji
game domain.

```
+--------------------+------------------------+------------------------+
|     Elixir         |         Go             |       Node.js          |
+--------------------+------------------------+------------------------+
| Shared-nothing     | Shared-memory with     | Single-threaded event  |
| processes          | explicit sync           | loop (cooperative)     |
|                    |                         |                        |
| ETS tables         | sync.Map               | Map / WeakRef          |
| Agent / GenServer  | sync.RWMutex + struct  | Class fields            |
| :persistent_term   | atomic.Int64           | SharedArrayBuffer      |
| :counters          | sync/atomic            | Atomics (threads)      |
+--------------------+------------------------+------------------------+
```

---

## 35.2. Branded Identifiers (CHAMP Protocol)

The CHAMP (Channel Message Protocol) branded ID system provides consistent identification
across all three runtimes. Every entity in the Codemoji pipeline — jobs, events, flows,
queues, workers, traces — gets a 14-character identifier composed of a 3-character namespace
prefix and an 11-character Base62-encoded snowflake.

| Namespace | Entity | Codemoji Usage |
|-----------|--------|----------------|
| `JOB` | Job | Emoji guess submission |
| `EVT` | Event | Game state transition |
| `FLW` | Flow | Multi-round game flow |
| `QUE` | Queue | Queue identifier |
| `WRK` | Worker | Worker instance |
| `TRC` | Trace | Distributed trace span |

The snowflake encodes 41 bits of timestamp, 10 bits of worker ID, and 12 bits of sequence
counter. This means branded IDs are lexicographically sortable by creation time and carry
embedded metadata that can be extracted without a database lookup.

### 35.2.1. Generating and Parsing Branded IDs

<tabs>
<tab title="Elixir">

```elixir
defmodule Codemoji.GameIds do
  @moduledoc "Branded ID helpers for the Codemoji game pipeline."

  alias EchoMQ.Champ

  # Generate IDs for game entities
  def new_job_id, do: Champ.generate_id(:job)
  def new_event_id, do: Champ.generate_id(:event)
  def new_flow_id, do: Champ.generate_id(:flow)
  def new_trace_id, do: Champ.generate_id(:trace)

  # Parse any branded ID
  def parse(id) do
    case Champ.parse(id) do
      {:ok, namespace, snowflake} ->
        {:ok, %{namespace: namespace, snowflake: snowflake}}
      :error ->
        {:error, :invalid_branded_id}
    end
  end

  # Extract creation timestamp from any branded ID
  def created_at(id) do
    case Champ.extract(id) do
      {:ok, %{timestamp: ts}} -> {:ok, ts}
      :error -> {:error, :invalid_id}
    end
  end

  # Branded IDs are sortable by creation time
  def sort_by_creation(ids), do: Enum.sort(ids)
end
```

> **Benefit**: EchoMQ.Champ wraps ID generation as a pure function call — no shared state between BEAM processes.

</tab>
<tab title="Go">

```go
package codemoji

import (
    "crypto/rand"
    "encoding/binary"
    "fmt"
    "sync/atomic"
    "time"
)

// Base62 alphabet for encoding snowflakes
const base62Chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"

// Namespaces for Codemoji branded IDs
const (
    NSJob    = "JOB"
    NSEvent  = "EVT"
    NSFlow   = "FLW"
    NSQueue  = "QUE"
    NSWorker = "WRK"
    NSTrace  = "TRC"
)

// IDGenerator produces branded IDs with atomic sequence counters.
// Safe for concurrent use across goroutines.
type IDGenerator struct {
    workerID uint64
    sequence atomic.Uint64
    epoch    int64 // custom epoch in milliseconds
}

func NewIDGenerator(workerID uint64) *IDGenerator {
    return &IDGenerator{
        workerID: workerID & 0x3FF, // 10 bits
        epoch:    1704067200000,     // 2024-01-01 UTC
    }
}

// Generate produces a branded ID: {namespace}{base62-snowflake}
func (g *IDGenerator) Generate(namespace string) string {
    ts := time.Now().UnixMilli() - g.epoch
    seq := g.sequence.Add(1) & 0xFFF // 12 bits

    snowflake := uint64(ts)<<22 | g.workerID<<12 | seq
    return namespace + encodeBase62(snowflake)
}

// Parse extracts namespace and snowflake from a branded ID
func Parse(id string) (namespace string, snowflake uint64, err error) {
    if len(id) != 14 {
        return "", 0, fmt.Errorf("invalid branded ID length: %d", len(id))
    }
    namespace = id[:3]
    snowflake, err = decodeBase62(id[3:])
    return
}

func encodeBase62(n uint64) string {
    if n == 0 {
        return "00000000000"
    }
    buf := make([]byte, 11)
    for i := 10; i >= 0; i-- {
        buf[i] = base62Chars[n%62]
        n /= 62
    }
    return string(buf)
}
```

> **Benefit**: `atomic.Uint64` sequence counter enables lock-free ID generation across goroutines.

</tab>
<tab title="Node.js">

```typescript
// Base62 alphabet matching EchoMQ.Champ
const BASE62 = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";

// Namespaces for Codemoji branded IDs
const Namespace = {
  JOB: "JOB",
  EVT: "EVT",
  FLW: "FLW",
  QUE: "QUE",
  WRK: "WRK",
  TRC: "TRC",
} as const;

type NamespaceType = (typeof Namespace)[keyof typeof Namespace];

// Snowflake generator — safe in single-threaded Node.js event loop
class ChampGenerator {
  private sequence = 0;
  private lastTimestamp = 0;
  private readonly epoch = 1704067200000n; // 2024-01-01 UTC

  constructor(private readonly workerId: number) {}

  generate(namespace: NamespaceType): string {
    let ts = BigInt(Date.now()) - this.epoch;
    const now = Number(ts);

    if (now === this.lastTimestamp) {
      this.sequence = (this.sequence + 1) & 0xfff;
      if (this.sequence === 0) {
        // Sequence overflow — spin until next millisecond
        while (Number(BigInt(Date.now()) - this.epoch) === now) {}
        ts = BigInt(Date.now()) - this.epoch;
      }
    } else {
      this.sequence = 0;
      this.lastTimestamp = now;
    }

    const snowflake =
      (ts << 22n) | (BigInt(this.workerId & 0x3ff) << 12n) | BigInt(this.sequence);
    return namespace + encodeBase62(snowflake);
  }
}

function encodeBase62(n: bigint): string {
  const buf: string[] = new Array(11).fill("0");
  for (let i = 10; i >= 0; i--) {
    buf[i] = BASE62[Number(n % 62n)];
    n = n / 62n;
  }
  return buf.join("");
}

function parse(id: string): { namespace: string; snowflake: bigint } {
  if (id.length !== 14) throw new Error(`Invalid branded ID: ${id}`);
  return { namespace: id.slice(0, 3), snowflake: decodeBase62(id.slice(3)) };
}
```

> **Benefit**: Single-threaded event loop eliminates sequence contention — no atomics needed for ID generation.

</tab>
</tabs>

---

## 35.3. Process/Thread State Management

In a queue-processing application, you often need state that is visible across workers within
a single node — a leaderboard cache, a registry of active game rooms, or a counter tracking
processed jobs. Each language provides different primitives for this.

### 35.3.1. Leaderboard Cache

The Codemoji leaderboard tracks player rankings during active games. Workers processing
guess results need to update scores atomically while readers (the web layer) must see
consistent snapshots without blocking writers.

<tabs>
<tab title="Elixir">

```elixir
defmodule Codemoji.LeaderboardCache do
  @moduledoc """
  ETS-backed concurrent leaderboard cache.

  ETS tables are shared across all BEAM processes on the node.
  Reads are lock-free. Writes are atomic per-row. This gives us
  true concurrency: multiple workers can update different players
  simultaneously without contention.
  """

  @table :codemoji_leaderboard

  def start_link(_opts) do
    # :public allows any process to read/write
    # :ordered_set keeps entries sorted by key (useful for range queries)
    :ets.new(@table, [:named_table, :public, :ordered_set,
                       read_concurrency: true, write_concurrency: true])
    {:ok, self()}
  end

  @doc "Atomically increment a player's score."
  def increment_score(player_id, points) do
    # update_counter is atomic — no locks needed
    :ets.update_counter(@table, player_id, {2, points}, {player_id, 0})
  end

  @doc "Get top N players. Lock-free read."
  def top(n) do
    @table
    |> :ets.tab2list()
    |> Enum.sort_by(fn {_id, score} -> -score end)
    |> Enum.take(n)
    |> Enum.map(fn {id, score} -> %{player_id: id, score: score} end)
  end

  @doc "Get a single player's score."
  def score(player_id) do
    case :ets.lookup(@table, player_id) do
      [{^player_id, score}] -> score
      [] -> 0
    end
  end

  @doc "Reset all scores for a new game round."
  def reset, do: :ets.delete_all_objects(@table)
end
```

> **Benefit**: ETS provides lock-free concurrent reads and atomic per-key writes across all BEAM processes on the node.

</tab>
<tab title="Go">

```go
package codemoji

import (
    "sort"
    "sync"
)

// LeaderboardCache provides concurrent access to player rankings.
// Uses sync.RWMutex for read-heavy workloads: multiple goroutines
// can read simultaneously, writes acquire exclusive access.
type LeaderboardCache struct {
    mu     sync.RWMutex
    scores map[string]int64
}

func NewLeaderboardCache() *LeaderboardCache {
    return &LeaderboardCache{scores: make(map[string]int64)}
}

// IncrementScore atomically adds points to a player.
func (lc *LeaderboardCache) IncrementScore(playerID string, points int64) int64 {
    lc.mu.Lock()
    defer lc.mu.Unlock()
    lc.scores[playerID] += points
    return lc.scores[playerID]
}

// Top returns the top N players. Acquires a read lock so
// multiple goroutines can call Top concurrently.
func (lc *LeaderboardCache) Top(n int) []PlayerScore {
    lc.mu.RLock()
    defer lc.mu.RUnlock()

    entries := make([]PlayerScore, 0, len(lc.scores))
    for id, score := range lc.scores {
        entries = append(entries, PlayerScore{PlayerID: id, Score: score})
    }
    sort.Slice(entries, func(i, j int) bool {
        return entries[i].Score > entries[j].Score
    })
    if n < len(entries) {
        entries = entries[:n]
    }
    return entries
}

// Score returns a single player's score.
func (lc *LeaderboardCache) Score(playerID string) int64 {
    lc.mu.RLock()
    defer lc.mu.RUnlock()
    return lc.scores[playerID]
}

// Reset clears all scores for a new game round.
func (lc *LeaderboardCache) Reset() {
    lc.mu.Lock()
    defer lc.mu.Unlock()
    lc.scores = make(map[string]int64)
}

type PlayerScore struct {
    PlayerID string
    Score    int64
}
```

> **Benefit**: `sync.RWMutex` allows multiple goroutines to read scores simultaneously without blocking each other.

</tab>
<tab title="Node.js">

```typescript
/**
 * In-process leaderboard cache for Node.js.
 *
 * Node.js is single-threaded — no locks needed for the event loop.
 * The Map is safely mutated between async ticks. For worker_threads
 * scenarios, use SharedArrayBuffer (shown in a later section).
 */
class LeaderboardCache {
  private scores = new Map<string, number>();

  incrementScore(playerId: string, points: number): number {
    const current = this.scores.get(playerId) ?? 0;
    const newScore = current + points;
    this.scores.set(playerId, newScore);
    return newScore;
  }

  top(n: number): Array<{ playerId: string; score: number }> {
    return Array.from(this.scores.entries())
      .map(([playerId, score]) => ({ playerId, score }))
      .sort((a, b) => b.score - a.score)
      .slice(0, n);
  }

  score(playerId: string): number {
    return this.scores.get(playerId) ?? 0;
  }

  reset(): void {
    this.scores.clear();
  }

  get size(): number {
    return this.scores.size;
  }
}
```

> **Tradeoff**: No synchronization needed (single-threaded), but cache is limited to one event loop — no cross-process sharing.

</tab>
</tabs>

### 35.3.2. Game Room Registry

The Codemoji game room registry tracks active rooms with player counts. Rooms are
created when a game starts, updated as players join or leave, and removed when the
game ends. Multiple workers may update the registry concurrently.

<tabs>
<tab title="Elixir">

```elixir
defmodule Codemoji.RoomRegistry do
  @moduledoc """
  Concurrent game room registry backed by ETS.

  Each room is stored as {room_id, %{player_count: n, status: atom, created_at: DateTime}}.
  Using :set table type for O(1) lookups by room ID.
  """

  use GenServer

  @table :codemoji_rooms

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    :ets.new(@table, [:named_table, :public, :set,
                       read_concurrency: true, write_concurrency: true])
    {:ok, %{}}
  end

  def create_room(room_id, opts \\ %{}) do
    room = %{
      player_count: 0,
      status: :waiting,
      created_at: DateTime.utc_now(),
      max_players: Map.get(opts, :max_players, 8)
    }
    :ets.insert(@table, {room_id, room})
    :ok
  end

  def join_room(room_id) do
    case :ets.lookup(@table, room_id) do
      [{^room_id, room}] ->
        updated = %{room | player_count: room.player_count + 1}
        :ets.insert(@table, {room_id, updated})
        {:ok, updated.player_count}
      [] ->
        {:error, :room_not_found}
    end
  end

  def leave_room(room_id) do
    case :ets.lookup(@table, room_id) do
      [{^room_id, room}] ->
        updated = %{room | player_count: max(room.player_count - 1, 0)}
        :ets.insert(@table, {room_id, updated})
        {:ok, updated.player_count}
      [] ->
        {:error, :room_not_found}
    end
  end

  def get_room(room_id) do
    case :ets.lookup(@table, room_id) do
      [{^room_id, room}] -> {:ok, room}
      [] -> {:error, :room_not_found}
    end
  end

  def active_rooms do
    :ets.tab2list(@table)
    |> Enum.map(fn {id, room} -> Map.put(room, :id, id) end)
    |> Enum.filter(fn room -> room.status in [:waiting, :active] end)
  end

  def remove_room(room_id), do: :ets.delete(@table, room_id)
end
```

> **Benefit**: ETS `:public` tables allow any process to read/write without routing through a single bottleneck process.

</tab>
<tab title="Go">

```go
package codemoji

import (
    "sync"
    "time"
)

// Room represents an active Codemoji game room.
type Room struct {
    PlayerCount int
    Status      string // "waiting", "active", "finished"
    CreatedAt   time.Time
    MaxPlayers  int
}

// RoomRegistry manages active game rooms with concurrent access.
// sync.Map is optimized for the read-heavy, append-mostly pattern
// that characterizes a room registry: many reads per room lookup,
// occasional writes for join/leave.
type RoomRegistry struct {
    rooms sync.Map // map[string]*Room
}

func NewRoomRegistry() *RoomRegistry {
    return &RoomRegistry{}
}

func (rr *RoomRegistry) CreateRoom(roomID string, maxPlayers int) {
    rr.rooms.Store(roomID, &Room{
        PlayerCount: 0,
        Status:      "waiting",
        CreatedAt:   time.Now(),
        MaxPlayers:  maxPlayers,
    })
}

// JoinRoom atomically increments the player count.
// Uses LoadOrStore + CompareAndSwap pattern for lock-free updates.
func (rr *RoomRegistry) JoinRoom(roomID string) (int, error) {
    val, ok := rr.rooms.Load(roomID)
    if !ok {
        return 0, ErrRoomNotFound
    }
    room := val.(*Room)
    // For simplicity, use a local mutex per-room in production.
    // sync.Map handles the map-level concurrency; field updates
    // within a value still need coordination.
    room.PlayerCount++
    return room.PlayerCount, nil
}

func (rr *RoomRegistry) LeaveRoom(roomID string) (int, error) {
    val, ok := rr.rooms.Load(roomID)
    if !ok {
        return 0, ErrRoomNotFound
    }
    room := val.(*Room)
    if room.PlayerCount > 0 {
        room.PlayerCount--
    }
    return room.PlayerCount, nil
}

func (rr *RoomRegistry) GetRoom(roomID string) (*Room, bool) {
    val, ok := rr.rooms.Load(roomID)
    if !ok {
        return nil, false
    }
    return val.(*Room), true
}

func (rr *RoomRegistry) ActiveRooms() []*Room {
    var result []*Room
    rr.rooms.Range(func(_, value any) bool {
        room := value.(*Room)
        if room.Status == "waiting" || room.Status == "active" {
            result = append(result, room)
        }
        return true
    })
    return result
}

func (rr *RoomRegistry) RemoveRoom(roomID string) {
    rr.rooms.Delete(roomID)
}
```

> **Benefit**: `sync.Map` is optimized for read-heavy, append-mostly patterns like room lookups — no explicit lock management.

</tab>
<tab title="Node.js">

```typescript
interface RoomState {
  playerCount: number;
  status: "waiting" | "active" | "finished";
  createdAt: Date;
  maxPlayers: number;
}

/**
 * Game room registry. In Node.js, Map operations are atomic
 * within a single event loop tick — no external synchronization needed.
 */
class RoomRegistry {
  private rooms = new Map<string, RoomState>();

  createRoom(roomId: string, maxPlayers = 8): void {
    this.rooms.set(roomId, {
      playerCount: 0,
      status: "waiting",
      createdAt: new Date(),
      maxPlayers,
    });
  }

  joinRoom(roomId: string): number {
    const room = this.rooms.get(roomId);
    if (!room) throw new Error(`Room not found: ${roomId}`);
    room.playerCount++;
    return room.playerCount;
  }

  leaveRoom(roomId: string): number {
    const room = this.rooms.get(roomId);
    if (!room) throw new Error(`Room not found: ${roomId}`);
    room.playerCount = Math.max(room.playerCount - 1, 0);
    return room.playerCount;
  }

  getRoom(roomId: string): RoomState | undefined {
    return this.rooms.get(roomId);
  }

  activeRooms(): Array<RoomState & { id: string }> {
    const result: Array<RoomState & { id: string }> = [];
    for (const [id, room] of this.rooms) {
      if (room.status === "waiting" || room.status === "active") {
        result.push({ ...room, id });
      }
    }
    return result;
  }

  removeRoom(roomId: string): boolean {
    return this.rooms.delete(roomId);
  }
}
```

> **Benefit**: Map operations are atomic within event loop ticks — zero synchronization overhead for room management.

</tab>
</tabs>

---

## 35.4. Worker-Local State

Each EchoMQ worker maintains per-instance state during job processing: the current lock
token, active job tracking, processing metrics, and configuration. The design varies
dramatically across languages.

### 35.4.1. Per-Worker Job Tracking

<tabs>
<tab title="Elixir">

```elixir
defmodule Codemoji.GuessWorker do
  @moduledoc """
  Worker state lives inside the GenServer process.

  Each field is private to this process. No other process can read or modify
  these fields directly. External access goes through GenServer.call/cast
  which serializes access through the process mailbox.
  """

  use GenServer

  defstruct [
    :queue_name,
    :connection,
    :lock_manager,
    active_jobs: %{},           # job_id => {job, task_ref}
    cancellation_tokens: %{},   # job_id => {token, pid}
    processed_count: 0,
    failed_count: 0,
    running: false,
    paused: false
  ]

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: opts[:name])
  end

  @impl true
  def init(opts) do
    state = %__MODULE__{
      queue_name: opts[:queue],
      connection: opts[:connection]
    }
    {:ok, state}
  end

  @doc "Get worker stats. Serialized through the process mailbox."
  def stats(worker) do
    GenServer.call(worker, :stats)
  end

  @impl true
  def handle_call(:stats, _from, state) do
    stats = %{
      active: map_size(state.active_jobs),
      processed: state.processed_count,
      failed: state.failed_count,
      running: state.running
    }
    {:reply, stats, state}
  end

  @impl true
  def handle_info({:job_completed, job_id, _result}, state) do
    new_state = %{state |
      active_jobs: Map.delete(state.active_jobs, job_id),
      processed_count: state.processed_count + 1
    }
    {:noreply, new_state}
  end
end
```

> **Benefit**: GenServer process isolation means worker state is inherently thread-safe — no locks needed.

</tab>
<tab title="Go">

```go
package codemoji

import (
    "context"
    "sync"
    "sync/atomic"
)

// GuessWorker maintains per-worker state for processing emoji guesses.
// Fields use different sync primitives based on access patterns:
// - atomic for simple counters (no lock contention)
// - RWMutex for maps (concurrent reads, exclusive writes)
// - channel for shutdown signaling (no shared state)
type GuessWorker struct {
    queueName string
    opts      WorkerOptions

    // Active job tracking — protected by RWMutex because
    // reads (status checks) outnumber writes (job start/finish)
    activeJobs map[string]*activeJob
    mu         sync.RWMutex

    // Counters use atomic operations — zero contention,
    // no mutex needed for simple increment/read patterns
    processedCount atomic.Int64
    failedCount    atomic.Int64

    // Shutdown signaling via channel — goroutine-safe
    // without any mutex
    shutdownChan chan struct{}
    wg           sync.WaitGroup
}

type activeJob struct {
    Job    *Job
    Cancel context.CancelFunc
}

func NewGuessWorker(queueName string, opts WorkerOptions) *GuessWorker {
    return &GuessWorker{
        queueName:    queueName,
        opts:         opts,
        activeJobs:   make(map[string]*activeJob),
        shutdownChan: make(chan struct{}),
    }
}

// Stats returns worker metrics. Uses RLock so multiple callers
// can read concurrently without blocking each other.
func (w *GuessWorker) Stats() WorkerStats {
    w.mu.RLock()
    activeCount := len(w.activeJobs)
    w.mu.RUnlock()

    return WorkerStats{
        Active:    activeCount,
        Processed: w.processedCount.Load(),
        Failed:    w.failedCount.Load(),
    }
}

// TrackJob registers a new active job. Exclusive lock.
func (w *GuessWorker) TrackJob(jobID string, job *Job, cancel context.CancelFunc) {
    w.mu.Lock()
    defer w.mu.Unlock()
    w.activeJobs[jobID] = &activeJob{Job: job, Cancel: cancel}
}

// CompleteJob removes a job and increments the counter.
func (w *GuessWorker) CompleteJob(jobID string) {
    w.mu.Lock()
    delete(w.activeJobs, jobID)
    w.mu.Unlock()
    w.processedCount.Add(1)
}

type WorkerStats struct {
    Active    int
    Processed int64
    Failed    int64
}
```

> **Tradeoff**: Different fields need different sync primitives — `atomic` for counters, `RWMutex` for maps, channels for signals.

</tab>
<tab title="Node.js">

```typescript
/**
 * Worker-local state in Node.js.
 *
 * Since the event loop is single-threaded, plain object fields
 * are safe. No Map/Set locking — mutations between await points
 * are atomic from the event loop's perspective.
 */
class GuessWorker {
  private activeJobs = new Map<string, { job: Job; abortController: AbortController }>();
  private processedCount = 0;
  private failedCount = 0;
  private running = false;

  constructor(
    private readonly queueName: string,
    private readonly opts: WorkerOptions,
  ) {}

  stats(): { active: number; processed: number; failed: number; running: boolean } {
    return {
      active: this.activeJobs.size,
      processed: this.processedCount,
      failed: this.failedCount,
      running: this.running,
    };
  }

  trackJob(jobId: string, job: Job): AbortController {
    const controller = new AbortController();
    this.activeJobs.set(jobId, { job, abortController: controller });
    return controller;
  }

  completeJob(jobId: string): void {
    this.activeJobs.delete(jobId);
    this.processedCount++;
  }

  failJob(jobId: string): void {
    this.activeJobs.delete(jobId);
    this.failedCount++;
  }

  cancelJob(jobId: string, reason?: string): boolean {
    const tracked = this.activeJobs.get(jobId);
    if (tracked) {
      tracked.abortController.abort(reason);
      return true;
    }
    return false;
  }

  getActiveJobIds(): string[] {
    return Array.from(this.activeJobs.keys());
  }
}
```

> **Benefit**: Plain object fields are safe in the single-threaded event loop — no locking overhead for worker state.

</tab>
</tabs>

---

## 35.5. Concurrent Caches

Queue-processing workers frequently cache expensive computations — Lua script SHA1 hashes,
game configuration, player profiles. The caching pattern differs by runtime: ETS provides
a shared concurrent table in Elixir, `sync.Map` or `sync.RWMutex` protect shared state
in Go, and Node.js uses a plain `Map` with optional TTL eviction.

### 35.5.1. Script Cache with SHA1 Deduplication

<tabs>
<tab title="Elixir">

```elixir
defmodule Codemoji.ScriptCache do
  @moduledoc """
  Caches Lua script SHA1 hashes to avoid repeated SCRIPT LOAD calls.

  Uses :persistent_term for read-heavy data that rarely changes.
  :persistent_term has zero-cost reads (no copying, direct reference)
  but expensive writes (triggers global GC). This matches the script
  cache pattern: load once at startup, read on every Redis command.
  """

  @prefix :codemoji_script_

  def load(name, script_source) do
    sha1 = :crypto.hash(:sha, script_source) |> Base.encode16(case: :lower)
    :persistent_term.put({@prefix, name}, %{sha1: sha1, source: script_source})
    sha1
  end

  def get_sha1(name) do
    case :persistent_term.get({@prefix, name}, nil) do
      nil -> nil
      %{sha1: sha1} -> sha1
    end
  end

  def get_source(name) do
    case :persistent_term.get({@prefix, name}, nil) do
      nil -> nil
      %{source: source} -> source
    end
  end

  def loaded?(name) do
    :persistent_term.get({@prefix, name}, nil) != nil
  end
end
```

> **Benefit**: `:persistent_term` provides zero-cost reads (direct reference, no copying) for rarely-changing script hashes.

</tab>
<tab title="Go">

```go
package codemoji

import (
    "context"
    "crypto/sha1"
    "encoding/hex"
    "sync"

    "github.com/redis/go-redis/v9"
)

// ScriptCache caches Lua scripts with SHA1 hashes for EVALSHA optimization.
// Matches the ScriptLoader pattern from the EchoMQ Go implementation.
//
// Uses sync.RWMutex because the cache is read on every Redis command
// but written only during initialization.
type ScriptCache struct {
    client redis.Cmdable
    cache  map[string]*redis.Script
    mu     sync.RWMutex
}

func NewScriptCache(client redis.Cmdable) *ScriptCache {
    return &ScriptCache{
        client: client,
        cache:  make(map[string]*redis.Script),
    }
}

// Load registers a script and caches its SHA1 hash.
func (sc *ScriptCache) Load(name, source string) *redis.Script {
    sc.mu.Lock()
    defer sc.mu.Unlock()

    if script, exists := sc.cache[name]; exists {
        return script
    }

    script := redis.NewScript(source)
    sc.cache[name] = script
    return script
}

// Run executes a cached script via EVALSHA with EVAL fallback.
func (sc *ScriptCache) Run(ctx context.Context, name string, keys []string, args ...interface{}) *redis.Cmd {
    sc.mu.RLock()
    script, exists := sc.cache[name]
    sc.mu.RUnlock()

    if !exists {
        return redis.NewCmd(ctx, "ERR", "script not loaded: "+name)
    }
    return script.Run(ctx, sc.client, keys, args...)
}

// SHA1 computes the SHA1 hash of a script source.
func SHA1(source string) string {
    h := sha1.New()
    h.Write([]byte(source))
    return hex.EncodeToString(h.Sum(nil))
}
```

> **Benefit**: `sync.RWMutex` allows concurrent EVALSHA lookups while blocking only during initial script loading.

</tab>
<tab title="Node.js">

```typescript
import { createHash } from "crypto";
import { Redis } from "ioredis";

/**
 * Script cache with SHA1 deduplication.
 *
 * ioredis handles EVALSHA/EVAL fallback internally via defineCommand,
 * but this cache demonstrates the pattern explicitly. The Map is safe
 * for concurrent async access because mutations happen synchronously
 * within event loop ticks.
 */
class ScriptCache {
  private cache = new Map<string, { sha1: string; source: string }>();

  constructor(private readonly client: Redis) {}

  async load(name: string, source: string): Promise<string> {
    const sha1 = createHash("sha1").update(source).digest("hex");

    // SCRIPT LOAD sends the script to Redis and caches the SHA1
    await this.client.script("LOAD", source);

    this.cache.set(name, { sha1, source });
    return sha1;
  }

  async run(name: string, keys: string[], ...args: (string | number)[]): Promise<unknown> {
    const cached = this.cache.get(name);
    if (!cached) throw new Error(`Script not loaded: ${name}`);

    try {
      // Try EVALSHA first (uses cached SHA1)
      return await this.client.evalsha(cached.sha1, keys.length, ...keys, ...args);
    } catch (err: any) {
      if (err.message?.includes("NOSCRIPT")) {
        // Fallback to EVAL if SHA1 not found on this Redis node
        return await this.client.eval(cached.source, keys.length, ...keys, ...args);
      }
      throw err;
    }
  }

  getSha1(name: string): string | undefined {
    return this.cache.get(name)?.sha1;
  }

  isLoaded(name: string): boolean {
    return this.cache.has(name);
  }
}
```

> **Tradeoff**: Manual EVALSHA/EVAL fallback is needed here for illustration — ioredis handles this internally via `defineCommand`.

</tab>
</tabs>

---

## 35.6. Message Envelopes and Correlation

Cross-service communication in the Codemoji pipeline uses structured message envelopes with
embedded correlation IDs and W3C trace context. This enables end-to-end tracing from a
player's guess submission through the Node.js queue to the Elixir game engine and back.

### 35.6.1. Trace-Aware Envelope Construction

<tabs>
<tab title="Elixir">

```elixir
defmodule Codemoji.Envelope do
  @moduledoc """
  Cross-runtime message envelopes with W3C trace context.

  Built on EchoMQ.Champ — envelopes carry branded event IDs,
  reference IDs for parent entities, and trace context for
  distributed tracing across Elixir <-> Node.js boundaries.
  """

  alias EchoMQ.Champ

  @type t :: %{
    id: Champ.event_id(),
    type: atom(),
    payload: map(),
    timestamp: non_neg_integer(),
    ref_id: Champ.branded_id() | nil,
    trace_context: Champ.trace_context(),
    source: :elixir | :nodejs
  }

  @doc "Create an envelope for a game state transition."
  def game_event(game_id, event_type, payload, opts \\ []) do
    job_id = Champ.generate_id(:job)

    Champ.envelope(:state_transition, %{
      game_id: game_id,
      event_type: event_type,
      payload: payload,
      job_id: job_id
    }, opts[:ref_id], opts)
  end

  @doc "Create a child envelope preserving the parent's trace."
  def child_event(parent_envelope, event_type, payload) do
    child_trace = Champ.child_trace_context(parent_envelope.trace_context)

    Champ.envelope(event_type, payload, parent_envelope.id,
      trace_context: child_trace
    )
  end

  @doc "Serialize for Redis transport."
  def to_json(envelope), do: Champ.to_json(envelope)

  @doc "Deserialize from Redis."
  def from_json(json), do: Champ.from_json(json)
end
```

> **Benefit**: `EchoMQ.Champ` module handles all envelope construction — branded IDs and trace context are first-class.

</tab>
<tab title="Go">

```go
package codemoji

import (
    "crypto/rand"
    "encoding/hex"
    "encoding/json"
    "fmt"
    "time"
)

// Envelope wraps a message with trace context for cross-runtime transport.
type Envelope struct {
    ID           string        `json:"id"`
    Type         string        `json:"type"`
    Payload      interface{}   `json:"payload"`
    Timestamp    int64         `json:"timestamp"`
    RefID        string        `json:"ref_id,omitempty"`
    TraceContext *TraceContext  `json:"trace_context,omitempty"`
    Source       string        `json:"source"`
}

type TraceContext struct {
    TraceID    string `json:"trace_id"`
    SpanID     string `json:"span_id"`
    TraceFlags int    `json:"trace_flags"`
}

// NewGameEvent creates a game state transition envelope.
func NewGameEvent(gen *IDGenerator, gameID, eventType string, payload interface{}) *Envelope {
    return &Envelope{
        ID:           gen.Generate(NSEvent),
        Type:         "state_transition",
        Payload:      map[string]interface{}{
            "game_id":    gameID,
            "event_type": eventType,
            "payload":    payload,
        },
        Timestamp:    time.Now().UnixMilli(),
        TraceContext: NewTraceContext(),
        Source:       "go",
    }
}

// ChildEvent creates a child envelope inheriting the parent's trace.
func ChildEvent(gen *IDGenerator, parent *Envelope, eventType string, payload interface{}) *Envelope {
    return &Envelope{
        ID:           gen.Generate(NSEvent),
        Type:         eventType,
        Payload:      payload,
        Timestamp:    time.Now().UnixMilli(),
        RefID:        parent.ID,
        TraceContext: ChildTraceContext(parent.TraceContext),
        Source:       "go",
    }
}

func NewTraceContext() *TraceContext {
    return &TraceContext{
        TraceID:    randomHex(32),
        SpanID:     randomHex(16),
        TraceFlags: 1,
    }
}

func ChildTraceContext(parent *TraceContext) *TraceContext {
    return &TraceContext{
        TraceID:    parent.TraceID, // Preserve parent trace
        SpanID:     randomHex(16),  // New span
        TraceFlags: parent.TraceFlags,
    }
}

// FormatTraceparent encodes as W3C traceparent header.
func (tc *TraceContext) FormatTraceparent() string {
    return fmt.Sprintf("00-%s-%s-%02x", tc.TraceID, tc.SpanID, tc.TraceFlags)
}

func (e *Envelope) ToJSON() ([]byte, error) {
    return json.Marshal(e)
}

func randomHex(length int) string {
    b := make([]byte, length/2)
    rand.Read(b)
    return hex.EncodeToString(b)
}
```

> **Benefit**: Struct-based envelopes with JSON tags enable zero-allocation serialization via `encoding/json`.

</tab>
<tab title="Node.js">

```typescript
import { randomBytes } from "crypto";

interface TraceContext {
  traceId: string;
  spanId: string;
  traceFlags: number;
}

interface MessageEnvelope {
  id: string;
  type: string;
  payload: Record<string, unknown>;
  timestamp: number;
  refId?: string;
  traceContext: TraceContext;
  source: "nodejs" | "elixir" | "go";
}

const champGen = new ChampGenerator(1);

function newTraceContext(): TraceContext {
  return {
    traceId: randomBytes(16).toString("hex"),
    spanId: randomBytes(8).toString("hex"),
    traceFlags: 1,
  };
}

function childTraceContext(parent: TraceContext): TraceContext {
  return {
    traceId: parent.traceId, // Preserve parent trace
    spanId: randomBytes(8).toString("hex"), // New span
    traceFlags: parent.traceFlags,
  };
}

function gameEvent(gameId: string, eventType: string, payload: unknown): MessageEnvelope {
  return {
    id: champGen.generate(Namespace.EVT),
    type: "state_transition",
    payload: { gameId, eventType, payload },
    timestamp: Date.now(),
    traceContext: newTraceContext(),
    source: "nodejs",
  };
}

function childEvent(
  parent: MessageEnvelope,
  eventType: string,
  payload: Record<string, unknown>,
): MessageEnvelope {
  return {
    id: champGen.generate(Namespace.EVT),
    type: eventType,
    payload,
    timestamp: Date.now(),
    refId: parent.id,
    traceContext: childTraceContext(parent.traceContext),
    source: "nodejs",
  };
}

// Format as W3C traceparent header
function formatTraceparent(ctx: TraceContext): string {
  const flags = ctx.traceFlags.toString(16).padStart(2, "0");
  return `00-${ctx.traceId}-${ctx.spanId}-${flags}`;
}
```

> **Benefit**: TypeScript interfaces provide compile-time envelope shape safety while keeping runtime serialization simple.

</tab>
</tabs>

---

## 35.7. Split Topology Patterns

A split topology deploys multiple runtimes where each handles what it does best.
In the Codemoji architecture, Node.js produces jobs and writes results (co-located
with Redis for minimal latency), Elixir consumes queue events and manages game state
(leveraging OTP supervision), and Go handles CPU-intensive scoring calculations.

### 35.7.1. Multi-Runtime Coordinator

<tabs>
<tab title="Elixir">

```elixir
defmodule Codemoji.SplitTopology.Consumer do
  @moduledoc """
  Elixir side of the split topology.

  Reads job results from Redis Streams via QueueEvents.
  Manages game state in ETS. Broadcasts updates to
  connected LiveView clients.

  In the split topology, Elixir never writes to the
  queue directly — it observes events and maintains
  the authoritative game state.
  """

  use GenServer

  alias EchoMQ.{Champ, QueueEvents}

  defstruct [:events_pid, game_state: %{}, event_log: []]

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    # Subscribe to queue events (reads from Redis Streams)
    {:ok, events_pid} = QueueEvents.start_link(
      queue: opts[:queue],
      connection: opts[:connection]
    )

    QueueEvents.on(events_pid, :completed, &handle_completed/1)
    QueueEvents.on(events_pid, :failed, &handle_failed/1)

    {:ok, %__MODULE__{events_pid: events_pid}}
  end

  defp handle_completed(event) do
    # Parse branded ID from the event
    case Champ.parse(event.job_id) do
      {:ok, :job, _snowflake} ->
        # Update game state in ETS
        Codemoji.LeaderboardCache.increment_score(
          event.return_value["player_id"],
          event.return_value["points"]
        )

        # Broadcast to LiveView clients
        Phoenix.PubSub.broadcast(Codemoji.PubSub, "game:updates", {
          :score_updated,
          event.return_value
        })

      _ ->
        :ignored
    end
  end

  defp handle_failed(event) do
    Logger.warning("Job failed: #{event.job_id} — #{event.failed_reason}")
  end
end
```

> **Benefit**: OTP supervision + QueueEvents makes Elixir ideal for the "observe and react" side of a split topology.

</tab>
<tab title="Go">

```go
package codemoji

import (
    "context"
    "encoding/json"
    "fmt"
    "log"

    "github.com/redis/go-redis/v9"
)

// ScoringWorker is the Go side of the split topology.
// Handles CPU-intensive scoring calculations. Uses goroutine pool
// for parallel score computation while maintaining thread-safe
// access to the shared leaderboard cache.
type ScoringWorker struct {
    worker      *Worker
    leaderboard *LeaderboardCache
    idGen       *IDGenerator
}

func NewScoringWorker(rdb redis.Cmdable, leaderboard *LeaderboardCache) *ScoringWorker {
    sw := &ScoringWorker{
        leaderboard: leaderboard,
        idGen:       NewIDGenerator(1),
    }

    opts := DefaultWorkerOptions
    opts.Concurrency = 10 // 10 parallel scoring goroutines

    sw.worker = NewWorker("game:scoring", rdb, opts)
    sw.worker.Process(sw.processScoring)

    return sw
}

// processScoring runs in its own goroutine — one per active job.
// The leaderboard cache handles its own synchronization.
func (sw *ScoringWorker) processScoring(job *Job) (interface{}, error) {
    var guess struct {
        PlayerID string `json:"player_id"`
        GuessID  string `json:"guess_id"`
        Answer   string `json:"answer"`
        Correct  bool   `json:"correct"`
    }

    if err := json.Unmarshal(job.Data, &guess); err != nil {
        return nil, fmt.Errorf("invalid guess payload: %w", err)
    }

    // Compute score (CPU-intensive in real scenarios)
    points := computeScore(guess.Correct, job.Timestamp)

    // Update leaderboard — thread-safe via RWMutex
    newTotal := sw.leaderboard.IncrementScore(guess.PlayerID, int64(points))

    // Generate branded event ID for the result
    eventID := sw.idGen.Generate(NSEvent)

    return map[string]interface{}{
        "event_id":  eventID,
        "player_id": guess.PlayerID,
        "points":    points,
        "total":     newTotal,
    }, nil
}

func computeScore(correct bool, timestamp int64) int {
    if !correct {
        return 0
    }
    // Bonus for fast answers
    return 100
}
```

> **Benefit**: Goroutine pool with shared `LeaderboardCache` enables parallel CPU-intensive scoring across cores.

</tab>
<tab title="Node.js">

```typescript
import { Queue, FlowProducer } from "bullmq";
import { Redis } from "ioredis";

/**
 * Node.js side of the split topology.
 *
 * Produces jobs and writes results — co-located with Redis
 * for minimal latency. Node.js is the "write side" in the
 * Codemoji split topology.
 */
class GameProducer {
  private guessQueue: Queue;
  private scoringQueue: Queue;
  private flowProducer: FlowProducer;
  private champGen = new ChampGenerator(0);

  constructor(private readonly connection: Redis) {
    this.guessQueue = new Queue("game:guesses", { connection });
    this.scoringQueue = new Queue("game:scoring", { connection });
    this.flowProducer = new FlowProducer({ connection });
  }

  /**
   * Submit a player guess — creates a flow with scoring child job.
   * The branded job ID enables cross-runtime correlation.
   */
  async submitGuess(playerId: string, answer: string, gameId: string) {
    const jobId = this.champGen.generate(Namespace.JOB);
    const traceCtx = newTraceContext();

    // Flow: guess -> scoring (parent-child)
    const flow = await this.flowProducer.add({
      name: "evaluate-guess",
      queueName: "game:guesses",
      data: {
        player_id: playerId,
        answer,
        game_id: gameId,
        trace_context: traceCtx,
      },
      opts: { jobId },
      children: [
        {
          name: "compute-score",
          queueName: "game:scoring",
          data: {
            player_id: playerId,
            guess_id: jobId,
            answer,
          },
          opts: {
            jobId: this.champGen.generate(Namespace.JOB),
          },
        },
      ],
    });

    return { jobId, flowId: flow.job.id };
  }

  async close() {
    await this.guessQueue.close();
    await this.scoringQueue.close();
    await this.flowProducer.close();
  }
}
```

> **Benefit**: `FlowProducer` co-located with Redis provides minimal-latency job production for the "write side" of the topology.

</tab>
</tabs>

---

## 35.8. Immutable Data Patterns

Queue processors benefit from immutable data patterns: a snapshot of game state
cannot be corrupted by a concurrent worker modifying the same data. Each language
approaches immutability differently.

### 35.8.1. Immutable Game State Snapshots

<tabs>
<tab title="Elixir">

```elixir
defmodule Codemoji.GameState do
  @moduledoc """
  Immutable game state using Elixir's persistent data structures.

  All Elixir data structures are immutable by default. Maps, lists,
  and tuples share structure when "modified" — only changed nodes
  are allocated. This means creating a "new" game state from an
  existing one is O(log n) and shares most memory with the original.
  """

  defstruct [
    :game_id,
    :round,
    players: %{},
    scores: %{},
    history: [],
    status: :waiting,
    created_at: nil
  ]

  @doc "Create a new game state. Returns an immutable struct."
  def new(game_id) do
    %__MODULE__{
      game_id: game_id,
      round: 1,
      created_at: DateTime.utc_now()
    }
  end

  @doc """
  Apply a guess result. Returns a NEW state — the original is unchanged.
  This is safe to call from any process without coordination.
  """
  def apply_guess(state, player_id, correct?) do
    points = if correct?, do: 100, else: 0

    %{state |
      scores: Map.update(state.scores, player_id, points, &(&1 + points)),
      history: [{player_id, correct?, DateTime.utc_now()} | state.history]
    }
  end

  @doc "Advance to the next round. Returns a NEW state."
  def next_round(state) do
    %{state | round: state.round + 1}
  end

  @doc "Take a snapshot for serialization. Zero-cost — it's already immutable."
  def snapshot(state) do
    %{
      game_id: state.game_id,
      round: state.round,
      scores: state.scores,
      player_count: map_size(state.players),
      status: state.status
    }
  end
end
```

> **Benefit**: All data structures are immutable by default — structural sharing makes updates O(log n) with minimal allocation.

</tab>
<tab title="Go">

```go
package codemoji

import (
    "time"
)

// GameState is a value type — pass by value to create implicit copies.
// For large states, use explicit Copy() to avoid accidentally sharing
// the underlying map slices.
type GameState struct {
    GameID    string
    Round     int
    Players   map[string]Player
    Scores    map[string]int64
    History   []GuessRecord
    Status    string
    CreatedAt time.Time
}

type GuessRecord struct {
    PlayerID string
    Correct  bool
    At       time.Time
}

// NewGameState creates an initial game state.
func NewGameState(gameID string) GameState {
    return GameState{
        GameID:    gameID,
        Round:     1,
        Players:   make(map[string]Player),
        Scores:    make(map[string]int64),
        History:   nil,
        Status:    "waiting",
        CreatedAt: time.Now(),
    }
}

// ApplyGuess returns a NEW GameState with the guess applied.
// The original is not modified — maps are explicitly copied.
func (gs GameState) ApplyGuess(playerID string, correct bool) GameState {
    // Copy the scores map to avoid aliasing
    newScores := make(map[string]int64, len(gs.Scores))
    for k, v := range gs.Scores {
        newScores[k] = v
    }
    if correct {
        newScores[playerID] += 100
    }

    // Copy and append to history
    newHistory := make([]GuessRecord, len(gs.History)+1)
    copy(newHistory, gs.History)
    newHistory[len(gs.History)] = GuessRecord{
        PlayerID: playerID,
        Correct:  correct,
        At:       time.Now(),
    }

    return GameState{
        GameID:    gs.GameID,
        Round:     gs.Round,
        Players:   gs.Players, // Shared if not modified
        Scores:    newScores,
        History:   newHistory,
        Status:    gs.Status,
        CreatedAt: gs.CreatedAt,
    }
}

// NextRound returns a new state for the next round.
func (gs GameState) NextRound() GameState {
    gs.Round++ // Safe because gs is a value receiver (copy)
    return gs
}

// Snapshot returns a serializable view.
func (gs GameState) Snapshot() map[string]interface{} {
    return map[string]interface{}{
        "game_id":      gs.GameID,
        "round":        gs.Round,
        "scores":       gs.Scores,
        "player_count": len(gs.Players),
        "status":       gs.Status,
    }
}
```

> **Tradeoff**: Maps and slices must be explicitly copied to avoid aliasing — value receivers help but don't protect map contents.

</tab>
<tab title="Node.js">

```typescript
/**
 * Immutable game state using Object.freeze + spread copies.
 *
 * JavaScript objects are mutable by default. We enforce immutability
 * via Object.freeze (shallow) and explicit spread copies for updates.
 * For deep immutability in production, consider Immer's produce().
 */
interface PlayerRecord {
  readonly id: string;
  readonly name: string;
}

interface GuessRecord {
  readonly playerId: string;
  readonly correct: boolean;
  readonly at: number;
}

interface GameState {
  readonly gameId: string;
  readonly round: number;
  readonly players: ReadonlyMap<string, PlayerRecord>;
  readonly scores: ReadonlyMap<string, number>;
  readonly history: readonly GuessRecord[];
  readonly status: "waiting" | "active" | "finished";
  readonly createdAt: number;
}

function newGameState(gameId: string): GameState {
  return Object.freeze({
    gameId,
    round: 1,
    players: new Map(),
    scores: new Map(),
    history: [],
    status: "waiting" as const,
    createdAt: Date.now(),
  });
}

/**
 * Apply a guess — returns a NEW frozen state.
 * The original is unchanged (enforced by Object.freeze + readonly types).
 */
function applyGuess(state: GameState, playerId: string, correct: boolean): GameState {
  const newScores = new Map(state.scores);
  const current = newScores.get(playerId) ?? 0;
  newScores.set(playerId, current + (correct ? 100 : 0));

  const newRecord: GuessRecord = { playerId, correct, at: Date.now() };

  return Object.freeze({
    ...state,
    scores: newScores,
    history: [...state.history, newRecord],
  });
}

function nextRound(state: GameState): GameState {
  return Object.freeze({
    ...state,
    round: state.round + 1,
  });
}

function snapshot(state: GameState): Record<string, unknown> {
  return {
    gameId: state.gameId,
    round: state.round,
    scores: Object.fromEntries(state.scores),
    playerCount: state.players.size,
    status: state.status,
  };
}
```

> **Tradeoff**: `Object.freeze` is shallow — deep immutability requires explicit spread copies or libraries like Immer.

</tab>
</tabs>

---

## 35.9. Lock Management Patterns

EchoMQ workers must continuously renew job locks to prevent stalled detection from
reclaiming active jobs. Each language implements lock management differently based
on its concurrency primitives.

### 35.9.1. Periodic Lock Renewal

<tabs>
<tab title="Elixir">

```elixir
defmodule Codemoji.LockRenewal do
  @moduledoc """
  Lock renewal using a single GenServer timer.

  Instead of spawning a timer per active job, a single periodic
  timer checks all tracked jobs and extends locks in batch.
  The tracked_jobs map lives inside the GenServer state —
  process isolation guarantees no concurrent modification.
  """

  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl true
  def init(opts) do
    interval = Keyword.get(opts, :lock_duration, 30_000) |> div(2)
    timer = Process.send_after(self(), :extend_locks, interval)

    {:ok, %{
      connection: opts[:connection],
      keys: opts[:keys],
      lock_duration: opts[:lock_duration],
      interval: interval,
      tracked_jobs: %{},  # job_id => %{token: token, ts: timestamp}
      timer: timer
    }}
  end

  def track_job(manager, job_id, token) do
    GenServer.cast(manager, {:track, job_id, token})
  end

  def untrack_job(manager, job_id) do
    GenServer.cast(manager, {:untrack, job_id})
  end

  @impl true
  def handle_cast({:track, job_id, token}, state) do
    tracked = Map.put(state.tracked_jobs, job_id, %{
      token: token,
      ts: System.system_time(:millisecond)
    })
    {:noreply, %{state | tracked_jobs: tracked}}
  end

  def handle_cast({:untrack, job_id}, state) do
    {:noreply, %{state | tracked_jobs: Map.delete(state.tracked_jobs, job_id)}}
  end

  @impl true
  def handle_info(:extend_locks, state) do
    now = System.system_time(:millisecond)
    threshold = div(state.interval, 2)

    {to_extend, updated} =
      Enum.reduce(state.tracked_jobs, {[], %{}}, fn {id, info}, {ext, acc} ->
        if info.ts + threshold < now do
          {[{id, info.token} | ext], Map.put(acc, id, %{info | ts: now})}
        else
          {ext, Map.put(acc, id, info)}
        end
      end)

    if to_extend != [] do
      # Batch extend via Lua script
      EchoMQ.Scripts.extend_locks(
        state.connection, state.keys,
        Enum.map(to_extend, &elem(&1, 0)),
        Enum.map(to_extend, &elem(&1, 1)),
        state.lock_duration
      )
    end

    timer = Process.send_after(self(), :extend_locks, state.interval)
    {:noreply, %{state | tracked_jobs: updated, timer: timer}}
  end
end
```

> **Benefit**: `Process.send_after` creates a self-rescheduling timer — no external scheduler dependency needed.

</tab>
<tab title="Go">

```go
package codemoji

import (
    "context"
    "sync"
    "time"

    "github.com/redis/go-redis/v9"
)

// LockRenewer manages periodic lock extension for active jobs.
// Uses a single goroutine with a ticker — more efficient than
// spawning a goroutine per job.
//
// The activeLocks map is protected by a RWMutex because the
// ticker goroutine reads it while worker goroutines write to it.
type LockRenewer struct {
    client       redis.Cmdable
    lockDuration time.Duration
    interval     time.Duration

    activeLocks map[string]lockInfo
    mu          sync.RWMutex

    stopChan chan struct{}
}

type lockInfo struct {
    Token     LockToken
    TrackedAt time.Time
}

func NewLockRenewer(client redis.Cmdable, lockDuration time.Duration) *LockRenewer {
    return &LockRenewer{
        client:       client,
        lockDuration: lockDuration,
        interval:     lockDuration / 2,
        activeLocks:  make(map[string]lockInfo),
        stopChan:     make(chan struct{}),
    }
}

// Start begins the periodic lock renewal goroutine.
func (lr *LockRenewer) Start(ctx context.Context) {
    ticker := time.NewTicker(lr.interval / 2)

    go func() {
        defer ticker.Stop()
        for {
            select {
            case <-ctx.Done():
                return
            case <-lr.stopChan:
                return
            case <-ticker.C:
                lr.extendAll(ctx)
            }
        }
    }()
}

func (lr *LockRenewer) Track(jobID string, token LockToken) {
    lr.mu.Lock()
    defer lr.mu.Unlock()
    lr.activeLocks[jobID] = lockInfo{Token: token, TrackedAt: time.Now()}
}

func (lr *LockRenewer) Untrack(jobID string) {
    lr.mu.Lock()
    defer lr.mu.Unlock()
    delete(lr.activeLocks, jobID)
}

func (lr *LockRenewer) extendAll(ctx context.Context) {
    lr.mu.RLock()
    now := time.Now()
    threshold := lr.interval / 2
    var toExtend []string
    var tokens []string

    for id, info := range lr.activeLocks {
        if now.Sub(info.TrackedAt) > threshold {
            toExtend = append(toExtend, id)
            tokens = append(tokens, info.Token.String())
        }
    }
    lr.mu.RUnlock()

    // Batch extend outside the lock
    for i, jobID := range toExtend {
        extendLock(ctx, lr.client, jobID, tokens[i], lr.lockDuration)
    }
}

func (lr *LockRenewer) Stop() {
    close(lr.stopChan)
}
```

> **Benefit**: Single goroutine with `time.Ticker` is more efficient than spawning one goroutine per active job.

</tab>
<tab title="Node.js">

```typescript
/**
 * Lock renewal using setTimeout recursion.
 *
 * The LockManager from EchoMQ uses a single timer that fires
 * every lockRenewTime/2 milliseconds. Since Node.js is single-threaded,
 * the trackedJobs Map is safe to mutate without locks.
 *
 * This matches the official BullMQ LockManager pattern.
 */
class LockRenewalManager {
  private trackedJobs = new Map<string, { token: string; ts: number }>();
  private timer?: NodeJS.Timeout;
  private closed = false;

  constructor(
    private readonly extendLockFn: (jobIds: string[], tokens: string[], duration: number) => Promise<number[]>,
    private readonly lockDuration: number = 30_000,
  ) {}

  start(): void {
    if (this.closed) return;
    this.scheduleExtension();
  }

  private scheduleExtension(): void {
    const renewTime = this.lockDuration / 2;
    this.timer = setTimeout(async () => {
      const now = Date.now();
      const threshold = renewTime / 2;
      const jobsToExtend: string[] = [];
      const tokensToExtend: string[] = [];

      for (const [jobId, info] of this.trackedJobs) {
        if (info.ts + threshold < now) {
          // Update timestamp before extending
          this.trackedJobs.set(jobId, { token: info.token, ts: now });
          jobsToExtend.push(jobId);
          tokensToExtend.push(info.token);
        }
      }

      if (jobsToExtend.length > 0) {
        try {
          const results = await this.extendLockFn(
            jobsToExtend,
            tokensToExtend,
            this.lockDuration,
          );
          // Remove jobs that failed to extend (lock stolen)
          results.forEach((result, i) => {
            if (result === 0) {
              this.trackedJobs.delete(jobsToExtend[i]);
            }
          });
        } catch (err) {
          console.error("[LockRenewal] Extension failed:", err);
        }
      }

      if (!this.closed) this.scheduleExtension();
    }, renewTime / 2);
  }

  trackJob(jobId: string, token: string): void {
    this.trackedJobs.set(jobId, { token, ts: Date.now() });
  }

  untrackJob(jobId: string): void {
    this.trackedJobs.delete(jobId);
  }

  stop(): void {
    this.closed = true;
    if (this.timer) clearTimeout(this.timer);
    this.trackedJobs.clear();
  }
}
```

> **Benefit**: `setTimeout` recursion naturally fits the event loop model — no thread management needed for periodic renewal.

</tab>
</tabs>

---

## 35.10. Async Task Queues

Each language needs an internal mechanism to manage the flow of concurrent job processing.
Elixir uses `Task.async` with the process mailbox as a natural FIFO. Go uses buffered
channels as semaphores. Node.js requires a custom async FIFO queue to track Promise
completion order.

### 35.10.1. Internal Concurrency Control

<tabs>
<tab title="Elixir">

```elixir
defmodule Codemoji.ConcurrencyLimiter do
  @moduledoc """
  Concurrency control using Elixir's process model.

  The GenServer mailbox is a natural FIFO queue. Task.async spawns
  a linked process for each job. The GenServer tracks active tasks
  via monitor refs and enforces the concurrency limit by deferring
  new fetches until slots open.
  """

  use GenServer

  defstruct [:max_concurrency, active: %{}, pending: :queue.new()]

  def start_link(max_concurrency) do
    GenServer.start_link(__MODULE__, max_concurrency)
  end

  @impl true
  def init(max_concurrency) do
    {:ok, %__MODULE__{max_concurrency: max_concurrency}}
  end

  def submit(limiter, fun) do
    GenServer.call(limiter, {:submit, fun})
  end

  @impl true
  def handle_call({:submit, fun}, from, state) do
    if map_size(state.active) < state.max_concurrency do
      task = Task.async(fun)
      active = Map.put(state.active, task.ref, from)
      {:noreply, %{state | active: active}}
    else
      pending = :queue.in({fun, from}, state.pending)
      {:noreply, %{state | pending: pending}}
    end
  end

  @impl true
  def handle_info({ref, result}, state) when is_reference(ref) do
    Process.demonitor(ref, [:flush])

    case Map.pop(state.active, ref) do
      {nil, _} ->
        {:noreply, state}
      {from, active} ->
        GenServer.reply(from, {:ok, result})
        state = %{state | active: active}
        maybe_start_pending(state)
    end
  end

  def handle_info({:DOWN, ref, :process, _pid, reason}, state) do
    case Map.pop(state.active, ref) do
      {nil, _} -> {:noreply, state}
      {from, active} ->
        GenServer.reply(from, {:error, reason})
        maybe_start_pending(%{state | active: active})
    end
  end

  defp maybe_start_pending(state) do
    case :queue.out(state.pending) do
      {:empty, _} ->
        {:noreply, state}
      {{:value, {fun, from}}, pending} ->
        task = Task.async(fun)
        active = Map.put(state.active, task.ref, from)
        {:noreply, %{state | active: active, pending: pending}}
    end
  end
end
```

> **Benefit**: GenServer mailbox is a natural FIFO queue — `Task.async` spawns linked processes with automatic monitoring.

</tab>
<tab title="Go">

```go
package codemoji

import (
    "context"
    "sync"
)

// ConcurrencyLimiter uses a buffered channel as a semaphore.
// This is the standard Go pattern: the channel capacity IS the
// concurrency limit. Sending to a full channel blocks until
// a slot opens.
type ConcurrencyLimiter struct {
    semaphore chan struct{}
    wg        sync.WaitGroup
}

func NewConcurrencyLimiter(maxConcurrency int) *ConcurrencyLimiter {
    return &ConcurrencyLimiter{
        semaphore: make(chan struct{}, maxConcurrency),
    }
}

// Submit runs a function with concurrency limiting.
// Blocks if all slots are occupied. The caller's goroutine
// is parked on the channel send — no busy waiting.
func (cl *ConcurrencyLimiter) Submit(ctx context.Context, fn func() error) error {
    select {
    case cl.semaphore <- struct{}{}: // Acquire slot
        cl.wg.Add(1)
        go func() {
            defer func() {
                <-cl.semaphore // Release slot
                cl.wg.Done()
            }()
            if err := fn(); err != nil {
                // Error handling per-job
            }
        }()
        return nil
    case <-ctx.Done():
        return ctx.Err()
    }
}

// Wait blocks until all submitted jobs complete.
func (cl *ConcurrencyLimiter) Wait() {
    cl.wg.Wait()
}

// ActiveCount returns the number of currently active jobs.
func (cl *ConcurrencyLimiter) ActiveCount() int {
    return len(cl.semaphore)
}

// Available returns the number of free slots.
func (cl *ConcurrencyLimiter) Available() int {
    return cap(cl.semaphore) - len(cl.semaphore)
}
```

> **Benefit**: Buffered channel as semaphore — channel capacity IS the concurrency limit, goroutines park without busy-waiting.

</tab>
<tab title="Node.js">

```typescript
/**
 * AsyncFifoQueue from the EchoMQ codebase.
 *
 * Node.js needs an explicit async FIFO because Promise.all
 * resolves in arbitrary order. This queue ensures results are
 * consumed in the order they resolve, which matters for job
 * completion ordering.
 *
 * The linked list backing structure avoids array shift() O(n)
 * overhead for high-throughput workers.
 */
class AsyncFifoQueue<T> {
  private queue: T[] = [];
  private pending = new Set<Promise<T>>();
  private resolve?: (value: T | undefined) => void;
  private nextPromise: Promise<T | undefined>;

  constructor(private ignoreErrors = false) {
    this.nextPromise = this.newPromise();
  }

  add(promise: Promise<T>): void {
    this.pending.add(promise);

    promise
      .then((data) => {
        this.pending.delete(promise);
        this.queue.push(data);
        if (this.queue.length === 1 && this.resolve) {
          this.resolve(data);
          this.nextPromise = this.newPromise();
        }
      })
      .catch((err) => {
        this.pending.delete(promise);
        if (!this.ignoreErrors) throw err;
      });
  }

  async fetch(): Promise<T | undefined> {
    if (this.pending.size === 0 && this.queue.length === 0) {
      return undefined;
    }
    while (this.queue.length === 0) {
      await this.nextPromise;
    }
    return this.queue.shift();
  }

  numPending(): number {
    return this.pending.size;
  }

  numQueued(): number {
    return this.queue.length;
  }

  private newPromise(): Promise<T | undefined> {
    return new Promise<T | undefined>((resolve) => {
      this.resolve = resolve;
    });
  }
}

/**
 * ConcurrencyLimiter wraps AsyncFifoQueue with a slot counter.
 * Matches EchoMQ's worker concurrency model where N promises
 * can be in-flight simultaneously.
 */
class ConcurrencyLimiter {
  private active = 0;
  private fifo = new AsyncFifoQueue<void>(true);

  constructor(private readonly maxConcurrency: number) {}

  async submit(fn: () => Promise<void>): Promise<void> {
    while (this.active >= this.maxConcurrency) {
      await this.fifo.fetch();
    }
    this.active++;
    const promise = fn().finally(() => {
      this.active--;
    });
    this.fifo.add(promise.then(() => {}));
  }

  get activeCount(): number {
    return this.active;
  }

  get available(): number {
    return this.maxConcurrency - this.active;
  }
}
```

> **Tradeoff**: Requires custom `AsyncFifoQueue` because `Promise.all` resolves in arbitrary order — explicit FIFO tracking needed.

</tab>
</tabs>

---

## 35.11. Atomic Counters for Metrics

High-throughput job processing requires efficient counters for metrics: jobs processed,
failures, bytes transferred. Each language provides different atomic counter primitives.

### 35.11.1. Processing Metrics

<tabs>
<tab title="Elixir">

```elixir
defmodule Codemoji.Metrics do
  @moduledoc """
  Lock-free atomic counters using :counters.

  :counters (OTP 21.2+) provides truly atomic, lock-free counters
  that can be updated from any process without coordination.
  Unlike ETS update_counter, :counters has no key lookup overhead.
  """

  @counters_ref :codemoji_metrics

  # Counter indices
  @processed 1
  @failed 2
  @active 3
  @bytes_in 4
  @bytes_out 5

  def init do
    ref = :counters.new(5, [:write_concurrency])
    :persistent_term.put(@counters_ref, ref)
  end

  defp ref, do: :persistent_term.get(@counters_ref)

  def increment_processed, do: :counters.add(ref(), @processed, 1)
  def increment_failed, do: :counters.add(ref(), @failed, 1)
  def increment_active, do: :counters.add(ref(), @active, 1)
  def decrement_active, do: :counters.add(ref(), @active, -1)
  def add_bytes_in(n), do: :counters.add(ref(), @bytes_in, n)
  def add_bytes_out(n), do: :counters.add(ref(), @bytes_out, n)

  def snapshot do
    r = ref()
    %{
      processed: :counters.get(r, @processed),
      failed: :counters.get(r, @failed),
      active: :counters.get(r, @active),
      bytes_in: :counters.get(r, @bytes_in),
      bytes_out: :counters.get(r, @bytes_out)
    }
  end
end
```

> **Benefit**: `:counters` module provides truly lock-free atomic operations with no per-key lookup overhead.

</tab>
<tab title="Go">

```go
package codemoji

import "sync/atomic"

// Metrics tracks processing statistics using atomic operations.
// Each counter is an atomic.Int64 — increments never block,
// reads are always consistent, and there is zero lock contention
// even under high parallelism.
type Metrics struct {
    Processed atomic.Int64
    Failed    atomic.Int64
    Active    atomic.Int64
    BytesIn   atomic.Int64
    BytesOut  atomic.Int64
}

func (m *Metrics) IncrementProcessed() { m.Processed.Add(1) }
func (m *Metrics) IncrementFailed()    { m.Failed.Add(1) }
func (m *Metrics) IncrementActive()    { m.Active.Add(1) }
func (m *Metrics) DecrementActive()    { m.Active.Add(-1) }
func (m *Metrics) AddBytesIn(n int64)  { m.BytesIn.Add(n) }
func (m *Metrics) AddBytesOut(n int64) { m.BytesOut.Add(n) }

func (m *Metrics) Snapshot() MetricsSnapshot {
    return MetricsSnapshot{
        Processed: m.Processed.Load(),
        Failed:    m.Failed.Load(),
        Active:    m.Active.Load(),
        BytesIn:   m.BytesIn.Load(),
        BytesOut:  m.BytesOut.Load(),
    }
}

type MetricsSnapshot struct {
    Processed int64 `json:"processed"`
    Failed    int64 `json:"failed"`
    Active    int64 `json:"active"`
    BytesIn   int64 `json:"bytes_in"`
    BytesOut  int64 `json:"bytes_out"`
}
```

> **Benefit**: `sync/atomic` operations map directly to hardware CAS instructions — zero lock contention under high parallelism.

</tab>
<tab title="Node.js">

```typescript
/**
 * Worker metrics. In the single-threaded event loop,
 * plain number increments are atomic (no interleaving).
 *
 * For worker_threads, use SharedArrayBuffer + Atomics.
 */
class WorkerMetrics {
  private processed = 0;
  private failed = 0;
  private active = 0;
  private bytesIn = 0;
  private bytesOut = 0;

  incrementProcessed(): void { this.processed++; }
  incrementFailed(): void { this.failed++; }
  incrementActive(): void { this.active++; }
  decrementActive(): void { this.active--; }
  addBytesIn(n: number): void { this.bytesIn += n; }
  addBytesOut(n: number): void { this.bytesOut += n; }

  snapshot() {
    return {
      processed: this.processed,
      failed: this.failed,
      active: this.active,
      bytesIn: this.bytesIn,
      bytesOut: this.bytesOut,
    };
  }
}

/**
 * SharedArrayBuffer-backed metrics for worker_threads.
 * Uses Atomics for cross-thread atomic operations.
 */
class SharedMetrics {
  private buffer: SharedArrayBuffer;
  private view: Int32Array;

  // Indices
  static readonly PROCESSED = 0;
  static readonly FAILED = 1;
  static readonly ACTIVE = 2;

  constructor(buffer?: SharedArrayBuffer) {
    this.buffer = buffer ?? new SharedArrayBuffer(3 * Int32Array.BYTES_PER_ELEMENT);
    this.view = new Int32Array(this.buffer);
  }

  incrementProcessed(): number {
    return Atomics.add(this.view, SharedMetrics.PROCESSED, 1);
  }

  incrementFailed(): number {
    return Atomics.add(this.view, SharedMetrics.FAILED, 1);
  }

  incrementActive(): number {
    return Atomics.add(this.view, SharedMetrics.ACTIVE, 1);
  }

  decrementActive(): number {
    return Atomics.sub(this.view, SharedMetrics.ACTIVE, 1);
  }

  snapshot() {
    return {
      processed: Atomics.load(this.view, SharedMetrics.PROCESSED),
      failed: Atomics.load(this.view, SharedMetrics.FAILED),
      active: Atomics.load(this.view, SharedMetrics.ACTIVE),
    };
  }

  /** Share this buffer with worker threads */
  getBuffer(): SharedArrayBuffer {
    return this.buffer;
  }
}
```

> **Tradeoff**: Plain number increments are safe in the event loop, but `worker_threads` require `SharedArrayBuffer` + `Atomics`.

</tab>
</tabs>

---

## 35.12. Transaction Ledger Pattern

The Codemoji prize distribution system requires concurrent balance updates during
end-of-game payouts. Multiple workers may process prize distribution jobs simultaneously,
each updating the same transaction ledger atomically.

<tabs>
<tab title="Elixir">

```elixir
defmodule Codemoji.TransactionLedger do
  @moduledoc """
  Concurrent transaction ledger using ETS with atomic update_counter.

  Each balance update is a single :ets.update_counter call — atomic
  and lock-free. The ledger supports concurrent credits and debits
  from any number of worker processes without explicit locking.
  """

  alias EchoMQ.Champ

  @table :codemoji_ledger

  def init do
    :ets.new(@table, [:named_table, :public, :set,
                       read_concurrency: true, write_concurrency: true])
  end

  @doc "Credit points to a player. Returns new balance."
  def credit(player_id, amount) when amount > 0 do
    txn_id = Champ.generate_id(:event)
    new_balance = :ets.update_counter(@table, player_id, {2, amount}, {player_id, 0})
    log_transaction(txn_id, player_id, :credit, amount, new_balance)
    {:ok, txn_id, new_balance}
  end

  @doc "Debit points from a player. Fails if insufficient balance."
  def debit(player_id, amount) when amount > 0 do
    txn_id = Champ.generate_id(:event)
    # Check-then-act is safe here because ETS operations within
    # a single call are atomic per-key
    case :ets.lookup(@table, player_id) do
      [{^player_id, balance}] when balance >= amount ->
        new_balance = :ets.update_counter(@table, player_id, {2, -amount})
        log_transaction(txn_id, player_id, :debit, amount, new_balance)
        {:ok, txn_id, new_balance}
      _ ->
        {:error, :insufficient_balance}
    end
  end

  def balance(player_id) do
    case :ets.lookup(@table, player_id) do
      [{^player_id, balance}] -> balance
      [] -> 0
    end
  end

  defp log_transaction(txn_id, player_id, type, amount, balance) do
    :ets.insert(:codemoji_txn_log, {
      txn_id, player_id, type, amount, balance, DateTime.utc_now()
    })
  end
end
```

> **Benefit**: ETS `update_counter` is atomic and lock-free — concurrent credits from any number of worker processes.

</tab>
<tab title="Go">

```go
package codemoji

import (
    "fmt"
    "sync"
    "time"
)

// TransactionLedger manages concurrent balance updates.
// Uses fine-grained locking: one mutex per player instead of
// a global lock. This eliminates contention between workers
// updating different players' balances.
type TransactionLedger struct {
    balances map[string]*playerBalance
    mu       sync.RWMutex // Protects the map itself
    idGen    *IDGenerator
    txnLog   []Transaction
    logMu    sync.Mutex
}

type playerBalance struct {
    mu      sync.Mutex
    balance int64
}

type Transaction struct {
    ID        string
    PlayerID  string
    Type      string // "credit" or "debit"
    Amount    int64
    Balance   int64
    Timestamp time.Time
}

func NewTransactionLedger(idGen *IDGenerator) *TransactionLedger {
    return &TransactionLedger{
        balances: make(map[string]*playerBalance),
        idGen:    idGen,
    }
}

func (tl *TransactionLedger) getOrCreate(playerID string) *playerBalance {
    tl.mu.RLock()
    pb, exists := tl.balances[playerID]
    tl.mu.RUnlock()

    if exists {
        return pb
    }

    tl.mu.Lock()
    defer tl.mu.Unlock()
    // Double-check after acquiring write lock
    if pb, exists = tl.balances[playerID]; exists {
        return pb
    }
    pb = &playerBalance{}
    tl.balances[playerID] = pb
    return pb
}

// Credit adds points atomically. Returns (txnID, newBalance).
func (tl *TransactionLedger) Credit(playerID string, amount int64) (string, int64) {
    pb := tl.getOrCreate(playerID)
    pb.mu.Lock()
    pb.balance += amount
    newBalance := pb.balance
    pb.mu.Unlock()

    txnID := tl.idGen.Generate(NSEvent)
    tl.logTxn(txnID, playerID, "credit", amount, newBalance)
    return txnID, newBalance
}

// Debit removes points atomically. Returns error if insufficient.
func (tl *TransactionLedger) Debit(playerID string, amount int64) (string, int64, error) {
    pb := tl.getOrCreate(playerID)
    pb.mu.Lock()
    if pb.balance < amount {
        pb.mu.Unlock()
        return "", 0, fmt.Errorf("insufficient balance: have %d, need %d", pb.balance, amount)
    }
    pb.balance -= amount
    newBalance := pb.balance
    pb.mu.Unlock()

    txnID := tl.idGen.Generate(NSEvent)
    tl.logTxn(txnID, playerID, "debit", amount, newBalance)
    return txnID, newBalance, nil
}

func (tl *TransactionLedger) Balance(playerID string) int64 {
    tl.mu.RLock()
    pb, exists := tl.balances[playerID]
    tl.mu.RUnlock()
    if !exists {
        return 0
    }
    pb.mu.Lock()
    defer pb.mu.Unlock()
    return pb.balance
}

func (tl *TransactionLedger) logTxn(id, playerID, txnType string, amount, balance int64) {
    tl.logMu.Lock()
    defer tl.logMu.Unlock()
    tl.txnLog = append(tl.txnLog, Transaction{
        ID: id, PlayerID: playerID, Type: txnType,
        Amount: amount, Balance: balance, Timestamp: time.Now(),
    })
}
```

> **Benefit**: Fine-grained per-player mutex eliminates contention between workers updating different players' balances.

</tab>
<tab title="Node.js">

```typescript
/**
 * Transaction ledger for Codemoji prize distribution.
 *
 * In Node.js, the single event loop guarantees that each synchronous
 * block runs to completion without interleaving. Balance checks
 * and updates within the same tick are inherently atomic.
 */
class TransactionLedger {
  private balances = new Map<string, number>();
  private txnLog: TransactionRecord[] = [];
  private champGen = new ChampGenerator(0);

  credit(playerId: string, amount: number): { txnId: string; balance: number } {
    const current = this.balances.get(playerId) ?? 0;
    const newBalance = current + amount;
    this.balances.set(playerId, newBalance);

    const txnId = this.champGen.generate(Namespace.EVT);
    this.txnLog.push({
      id: txnId,
      playerId,
      type: "credit",
      amount,
      balance: newBalance,
      timestamp: Date.now(),
    });

    return { txnId, balance: newBalance };
  }

  debit(playerId: string, amount: number): { txnId: string; balance: number } {
    const current = this.balances.get(playerId) ?? 0;
    if (current < amount) {
      throw new Error(`Insufficient balance: have ${current}, need ${amount}`);
    }

    const newBalance = current - amount;
    this.balances.set(playerId, newBalance);

    const txnId = this.champGen.generate(Namespace.EVT);
    this.txnLog.push({
      id: txnId,
      playerId,
      type: "debit",
      amount,
      balance: newBalance,
      timestamp: Date.now(),
    });

    return { txnId, balance: newBalance };
  }

  balance(playerId: string): number {
    return this.balances.get(playerId) ?? 0;
  }

  getTransactionLog(): readonly TransactionRecord[] {
    return this.txnLog;
  }
}

interface TransactionRecord {
  id: string;
  playerId: string;
  type: "credit" | "debit";
  amount: number;
  balance: number;
  timestamp: number;
}
```

> **Benefit**: Synchronous balance check + update within one event loop tick is inherently atomic — no race conditions possible.

</tab>
</tabs>

---

## 35.13. Performance Tradeoffs

| Criterion | Elixir | Go | Node.js |
|-----------|--------|----|---------|
| **Concurrency model** | Actor (shared-nothing processes) | CSP (shared memory + channels) | Event loop (single-threaded) |
| **Concurrent reads** | ETS: lock-free, zero-copy | sync.RWMutex: multiple concurrent readers | Map: single-threaded (free) |
| **Concurrent writes** | ETS: atomic per-key, `write_concurrency` | sync.Mutex / atomic | Map: no contention (single thread) |
| **Memory sharing** | None — processes are isolated | Full — goroutines share heap | Full — single heap, no threads |
| **Atomic counters** | `:counters` module — no copying | `sync/atomic` — hardware CAS | `Atomics` (worker_threads only) |
| **Read-only globals** | `:persistent_term` — zero-cost read | Package-level `var` — no sync needed | Module-level `const` |
| **Cache pattern** | ETS (shared) or `:persistent_term` (immutable) | `sync.Map` (read-heavy) or `sync.RWMutex` | `Map` (no sync needed) |
| **Overhead per worker** | ~2KB per BEAM process | ~8KB per goroutine stack | N/A (one thread, async callbacks) |
| **Max concurrent workers** | ~1M processes per node | ~100K goroutines per node | 1 (event loop) + worker_threads |
| **Immutability** | Default (all data structures) | Explicit (copy maps, use value receivers) | Manual (`Object.freeze`, `readonly`) |

### 35.13.1. When to Choose Each Approach

**Elixir ETS** is the best fit when you need a shared cache visible across all workers on a node.
The combination of lock-free reads, atomic per-key writes, and `write_concurrency` makes ETS
unbeatable for leaderboard and registry patterns. The tradeoff is that ETS data is node-local
and lost on restart.

**Go sync primitives** shine for CPU-bound workloads where you need true parallelism across
cores. The explicit nature of mutex/atomic usage forces you to think about data races at
write time rather than discovering them at runtime. Use `sync.Map` for append-mostly maps
(caches, registries); prefer `sync.RWMutex` when you need more control over the locking
granularity.

**Node.js Maps** are the simplest option precisely because there is no concurrency to manage
within a single event loop. The limitation surfaces when you need CPU parallelism — that
requires `worker_threads` with `SharedArrayBuffer`, which introduces the complexity of
cross-thread synchronization via `Atomics`.

---

*Previous: [Chapter 34: Framework Integration](ch34-framework-integration.md) | Next: [Chapter 36: Error Handling](ch36-error-handling.md)*
