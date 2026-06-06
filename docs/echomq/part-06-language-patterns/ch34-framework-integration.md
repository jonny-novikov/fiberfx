# Chapter 34. Framework Integration

> Integrating EchoMQ with web frameworks across Elixir, Go, and Node.js — from application bootstrap to real-time dashboards.

## 34.1. Overview

Every web application eventually needs background processing: sending emails after signup, generating thumbnails after upload, refreshing leaderboards on a schedule. The challenge is wiring your queue system into the framework's lifecycle so that jobs are enqueued reliably, processed concurrently, and monitored in real time.

Each ecosystem has a dominant web framework with distinct integration patterns:

- **Phoenix** (Elixir): Supervision trees, PubSub broadcasting, LiveView real-time UI
- **Chi / net/http** (Go): Middleware chains, context propagation, goroutine-based workers
- **Fastify** (Node.js): Plugin system, async hooks, decorator patterns

Despite these differences, the integration goals are the same: bootstrap queues at startup, enqueue from HTTP handlers, broadcast events for real-time monitoring, and test queue interactions cleanly.

---

## 34.2. Application Bootstrap

Wiring EchoMQ into application startup ensures workers are running before any HTTP request arrives. Each framework provides a different lifecycle hook for this.

### Game Room Queue Setup

In the Codemoji game, game room creation (ROM entity) triggers multiple background jobs — map generation, bot spawning, and notification delivery. The queue must be ready before the first API call.

<tabs>
<tab title="Elixir">

```elixir
# lib/codemoji/application.ex
defmodule Codemoji.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Database
      Codemoji.Repo,

      # PubSub for real-time events
      {Phoenix.PubSub, name: Codemoji.PubSub},

      # Phoenix Endpoint
      CodemojixWeb.Endpoint,

      # Redis connection for EchoMQ
      {EchoMQ.RedisConnection,
        name: :echomq_redis,
        url: System.get_env("REDIS_URL", "redis://localhost:6379")},

      # Game room setup worker (ROM entity)
      {EchoMQ.Worker,
        name: :room_worker,
        queue: "game_rooms",
        connection: :echomq_redis,
        processor: &Codemoji.Workers.RoomSetup.process/1,
        concurrency: 5},

      # Guess evaluation worker (GUS entity)
      {EchoMQ.Worker,
        name: :guess_worker,
        queue: "guesses",
        connection: :echomq_redis,
        processor: &Codemoji.Workers.GuessEvaluator.process/1,
        concurrency: 20},

      # Event broadcaster: EchoMQ events -> Phoenix.PubSub
      {Codemoji.JobEventBroadcaster, pubsub: Codemoji.PubSub}
    ]

    opts = [strategy: :one_for_one, name: Codemoji.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

> **Benefit**: OTP supervision tree guarantees workers restart on crash — zero manual lifecycle management.

</tab>
<tab title="Go">

```go
// cmd/server/main.go
package main

import (
    "context"
    "log"
    "net/http"
    "os"
    "os/signal"
    "syscall"

    "github.com/go-chi/chi/v5"
    "github.com/go-chi/chi/v5/middleware"
    "github.com/redis/go-redis/v9"

    "codemoji/internal/handlers"
    "codemoji/internal/workers"
    "codemoji/pkg/echomq"
)

func main() {
    ctx, cancel := context.WithCancel(context.Background())
    defer cancel()

    // Redis connection
    rdb := redis.NewClient(&redis.Options{
        Addr: os.Getenv("REDIS_URL"),
    })

    // Create queues
    roomQueue := echomq.NewQueue("game_rooms", rdb)
    guessQueue := echomq.NewQueue("guesses", rdb)

    // Start workers in background goroutines
    roomWorker := echomq.NewWorker("game_rooms", rdb, echomq.WorkerOptions{
        Concurrency: 5,
    })
    roomWorker.Process(workers.RoomSetupProcessor)
    go roomWorker.Start(ctx)

    guessWorker := echomq.NewWorker("guesses", rdb, echomq.WorkerOptions{
        Concurrency: 20,
    })
    guessWorker.Process(workers.GuessEvaluatorProcessor)
    go guessWorker.Start(ctx)

    // HTTP router
    r := chi.NewRouter()
    r.Use(middleware.Logger)
    r.Use(middleware.Recoverer)

    h := handlers.New(roomQueue, guessQueue)
    r.Post("/api/rooms", h.CreateRoom)
    r.Post("/api/rooms/{roomID}/guess", h.SubmitGuess)

    // Graceful shutdown
    srv := &http.Server{Addr: ":8080", Handler: r}

    go func() {
        sig := make(chan os.Signal, 1)
        signal.Notify(sig, syscall.SIGINT, syscall.SIGTERM)
        <-sig
        cancel()
        roomWorker.Stop()
        guessWorker.Stop()
        srv.Shutdown(context.Background())
    }()

    log.Println("Server starting on :8080")
    srv.ListenAndServe()
}
```

> **Tradeoff**: Workers must be started as explicit goroutines with manual signal handling for graceful shutdown.

</tab>
<tab title="Node.js">

```typescript
// src/app.ts
import Fastify from "fastify";
import { Queue, Worker, QueueEvents } from "echomq";
import Redis from "ioredis";

const app = Fastify({ logger: true });

// Redis connection shared across queues
const connection = new Redis(process.env.REDIS_URL ?? "redis://localhost:6379");

// Create queues
const roomQueue = new Queue("game_rooms", { connection });
const guessQueue = new Queue("guesses", { connection });

// Decorate Fastify instance with queues for handler access
app.decorate("roomQueue", roomQueue);
app.decorate("guessQueue", guessQueue);

// Queue events for real-time monitoring
const roomEvents = new QueueEvents("game_rooms", { connection });
const guessEvents = new QueueEvents("guesses", { connection });

// Start workers
const roomWorker = new Worker(
  "game_rooms",
  async (job) => {
    const { roomId, config } = job.data;
    await job.updateProgress(10);
    const room = await generateRoomMap(roomId, config);
    await job.updateProgress(80);
    await spawnBots(roomId, config.botCount);
    await job.updateProgress(100);
    return { roomId, status: "ready", playerSlots: room.maxPlayers };
  },
  { connection, concurrency: 5 }
);

const guessWorker = new Worker(
  "guesses",
  async (job) => {
    return evaluateGuess(job.data);
  },
  { connection, concurrency: 20 }
);

// Graceful shutdown
const shutdown = async () => {
  await roomWorker.close();
  await guessWorker.close();
  await roomEvents.close();
  await guessEvents.close();
  await connection.quit();
  process.exit(0);
};

process.on("SIGINT", shutdown);
process.on("SIGTERM", shutdown);

// Register routes
app.register(import("./routes/rooms"));
app.register(import("./routes/guesses"));

app.listen({ port: 8080 });
```

> **Benefit**: Fastify decorators make queues accessible in every route handler without dependency injection boilerplate.

</tab>
</tabs>

---

## 34.3. Enqueueing from HTTP Handlers

The most common integration point: an HTTP request arrives, business logic runs, and a background job is enqueued. The response returns immediately while the job processes asynchronously.

### Game Room Creation API

When a player creates a new game room, the API validates the request, persists the room record, and enqueues a setup job that generates the map and spawns bots.

<tabs>
<tab title="Elixir">

```elixir
# lib/codemojix_web/controllers/room_controller.ex
defmodule CodemojixWeb.RoomController do
  use CodemojixWeb, :controller

  alias Codemoji.Rooms

  def create(conn, %{"room" => room_params}) do
    case Rooms.create_room(room_params) do
      {:ok, room} ->
        # Enqueue background setup job
        {:ok, job} = EchoMQ.Queue.add(
          "game_rooms",
          "setup_room",
          %{
            room_id: room.id,
            config: %{
              max_players: room.max_players,
              bot_count: room.bot_count,
              difficulty: room.difficulty
            }
          },
          connection: :echomq_redis,
          priority: 1
        )

        conn
        |> put_status(:created)
        |> json(%{
          id: room.id,
          status: "initializing",
          setup_job_id: job.id
        })

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: format_errors(changeset)})
    end
  end

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
```

> **Benefit**: Pattern matching in controller actions provides compile-time safety for request shape validation.

</tab>
<tab title="Go">

```go
// internal/handlers/rooms.go
package handlers

import (
    "encoding/json"
    "net/http"

    "codemoji/internal/models"
    "codemoji/pkg/echomq"
)

type Handlers struct {
    roomQueue  *echomq.Queue
    guessQueue *echomq.Queue
}

func New(roomQueue, guessQueue *echomq.Queue) *Handlers {
    return &Handlers{roomQueue: roomQueue, guessQueue: guessQueue}
}

func (h *Handlers) CreateRoom(w http.ResponseWriter, r *http.Request) {
    var req models.CreateRoomRequest
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        http.Error(w, "invalid request body", http.StatusBadRequest)
        return
    }

    // Persist room record
    room, err := models.CreateRoom(r.Context(), req)
    if err != nil {
        http.Error(w, "failed to create room", http.StatusInternalServerError)
        return
    }

    // Enqueue background setup job
    job, err := h.roomQueue.Add(r.Context(), "setup_room", map[string]interface{}{
        "room_id": room.ID,
        "config": map[string]interface{}{
            "max_players": req.MaxPlayers,
            "bot_count":   req.BotCount,
            "difficulty":  req.Difficulty,
        },
    }, echomq.JobOptions{
        Priority: 1,
    })
    if err != nil {
        http.Error(w, "failed to enqueue setup job", http.StatusInternalServerError)
        return
    }

    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(http.StatusCreated)
    json.NewEncoder(w).Encode(map[string]interface{}{
        "id":           room.ID,
        "status":       "initializing",
        "setup_job_id": job.ID,
    })
}
```

> **Benefit**: `r.Context()` propagates cancellation from the HTTP request through to the queue operation.

</tab>
<tab title="Node.js">

```typescript
// src/routes/rooms.ts
import { FastifyInstance } from "fastify";

interface CreateRoomBody {
  maxPlayers: number;
  botCount: number;
  difficulty: string;
}

export default async function roomRoutes(app: FastifyInstance) {
  app.post<{ Body: CreateRoomBody }>("/api/rooms", async (request, reply) => {
    const { maxPlayers, botCount, difficulty } = request.body;

    // Persist room record
    const room = await app.db.rooms.create({
      maxPlayers,
      botCount,
      difficulty,
    });

    // Enqueue background setup job
    const job = await app.roomQueue.add(
      "setup_room",
      {
        roomId: room.id,
        config: { maxPlayers, botCount, difficulty },
      },
      { priority: 1 }
    );

    return reply.code(201).send({
      id: room.id,
      status: "initializing",
      setupJobId: job.id,
    });
  });
}
```

> **Benefit**: Fastify's schema-based validation and TypeScript generics catch malformed requests before the handler runs.

</tab>
</tabs>

### Guess Submission with Delayed Evaluation

When a player submits a guess (GUS entity), the evaluation might be delayed to batch-process guesses or to create suspense in the game flow.

<tabs>
<tab title="Elixir">

```elixir
# lib/codemojix_web/controllers/guess_controller.ex
defmodule CodemojixWeb.GuessController do
  use CodemojixWeb, :controller

  def create(conn, %{"room_id" => room_id, "guess" => guess_params}) do
    player_id = conn.assigns.current_player.id

    {:ok, guess} = Codemoji.Guesses.record_guess(room_id, player_id, guess_params)

    # Delayed evaluation — 2 second suspense window
    {:ok, job} = EchoMQ.Queue.add(
      "guesses",
      "evaluate_guess",
      %{
        guess_id: guess.id,
        room_id: room_id,
        player_id: player_id,
        emoji_sequence: guess_params["emoji_sequence"]
      },
      connection: :echomq_redis,
      delay: 2_000,
      attempts: 3,
      backoff: %{type: :exponential, delay: 1_000}
    )

    json(conn, %{
      guess_id: guess.id,
      status: "pending",
      job_id: job.id,
      evaluates_at: DateTime.add(DateTime.utc_now(), 2, :second)
    })
  end
end
```

> **Benefit**: `delay` and `backoff` options are passed declaratively — no timer management required.

</tab>
<tab title="Go">

```go
// internal/handlers/guesses.go
func (h *Handlers) SubmitGuess(w http.ResponseWriter, r *http.Request) {
    roomID := chi.URLParam(r, "roomID")
    playerID := r.Context().Value("playerID").(string)

    var req models.SubmitGuessRequest
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        http.Error(w, "invalid request body", http.StatusBadRequest)
        return
    }

    guess, err := models.RecordGuess(r.Context(), roomID, playerID, req)
    if err != nil {
        http.Error(w, "failed to record guess", http.StatusInternalServerError)
        return
    }

    // Delayed evaluation — 2 second suspense window
    job, err := h.guessQueue.Add(r.Context(), "evaluate_guess", map[string]interface{}{
        "guess_id":       guess.ID,
        "room_id":        roomID,
        "player_id":      playerID,
        "emoji_sequence": req.EmojiSequence,
    }, echomq.JobOptions{
        Delay:    2 * time.Second,
        Attempts: 3,
        Backoff: echomq.BackoffConfig{
            Type:  "exponential",
            Delay: 1000,
        },
    })
    if err != nil {
        http.Error(w, "failed to enqueue evaluation", http.StatusInternalServerError)
        return
    }

    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(map[string]interface{}{
        "guess_id":     guess.ID,
        "status":       "pending",
        "job_id":       job.ID,
        "evaluates_at": time.Now().Add(2 * time.Second).Format(time.RFC3339),
    })
}
```

> **Benefit**: `time.Duration` types prevent unit mismatch bugs that plague raw millisecond integers.

</tab>
<tab title="Node.js">

```typescript
// src/routes/guesses.ts
import { FastifyInstance } from "fastify";

interface SubmitGuessBody {
  emojiSequence: string[];
}

export default async function guessRoutes(app: FastifyInstance) {
  app.post<{ Params: { roomId: string }; Body: SubmitGuessBody }>(
    "/api/rooms/:roomId/guess",
    async (request, reply) => {
      const { roomId } = request.params;
      const playerId = request.user.id;
      const { emojiSequence } = request.body;

      const guess = await app.db.guesses.create({
        roomId,
        playerId,
        emojiSequence,
      });

      // Delayed evaluation — 2 second suspense window
      const job = await app.guessQueue.add(
        "evaluate_guess",
        {
          guessId: guess.id,
          roomId,
          playerId,
          emojiSequence,
        },
        {
          delay: 2000,
          attempts: 3,
          backoff: { type: "exponential", delay: 1000 },
        }
      );

      return reply.send({
        guessId: guess.id,
        status: "pending",
        jobId: job.id,
        evaluatesAt: new Date(Date.now() + 2000).toISOString(),
      });
    }
  );
}
```

> **Benefit**: `job.waitUntilFinished()` lets callers await completion when the sync variant is needed.

</tab>
</tabs>

---

## 34.4. Real-Time Job Status

Players waiting for their game room to finish loading or their guess to be evaluated need live updates. Each framework provides a different mechanism for server-to-client push.

### Live Game Dashboard

The game dashboard shows active games, processing status, and real-time event feeds (GAM entity). Phoenix uses LiveView, Go uses Server-Sent Events, and Node.js uses WebSocket via Socket.IO.

<tabs>
<tab title="Elixir">

```elixir
# lib/codemojix_web/live/game_dashboard_live.ex
defmodule CodemojixWeb.GameDashboardLive do
  use CodemojixWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Codemoji.PubSub, "echomq:events")
    end

    {:ok, counts} = EchoMQ.Queue.get_counts("game_rooms", connection: :echomq_redis)

    {:ok,
      socket
      |> assign(:room_counts, counts)
      |> assign(:recent_events, [])
      |> assign(:active_games, 0)}
  end

  @impl true
  def handle_info({:job_event, :completed, %{"jobId" => job_id} = data}, socket) do
    event = %{
      type: :room_ready,
      job_id: job_id,
      room_id: data["room_id"],
      time: DateTime.utc_now()
    }

    {:noreply,
      socket
      |> update(:recent_events, fn events -> Enum.take([event | events], 25) end)
      |> update(:active_games, &(&1 + 1))}
  end

  def handle_info({:job_event, :failed, %{"jobId" => job_id} = data}, socket) do
    event = %{
      type: :room_failed,
      job_id: job_id,
      error: data["failedReason"],
      time: DateTime.utc_now()
    }

    {:noreply,
      socket
      |> update(:recent_events, fn events -> Enum.take([event | events], 25) end)}
  end

  def handle_info({:job_event, :active, _data}, socket) do
    {:noreply, socket}
  end

  def handle_info({:job_event, _, _}, socket), do: {:noreply, socket}

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h1 class="text-2xl font-bold mb-4">Game Dashboard</h1>

      <div class="grid grid-cols-4 gap-4 mb-6">
        <.stat_card label="Active Games" value={@active_games} color="blue" />
        <.stat_card label="Rooms Waiting" value={@room_counts[:waiting] || 0} color="yellow" />
        <.stat_card label="Setting Up" value={@room_counts[:active] || 0} color="green" />
        <.stat_card label="Failed" value={@room_counts[:failed] || 0} color="red" />
      </div>

      <h2 class="text-xl font-semibold mb-2">Recent Events</h2>
      <div class="space-y-2">
        <%= for event <- @recent_events do %>
          <div class={"p-3 rounded border-l-4 #{event_class(event.type)}"}>
            <span class="font-mono text-sm"><%= event.job_id %></span>
            <span class="text-xs text-gray-500 ml-2">
              <%= Calendar.strftime(event.time, "%H:%M:%S") %>
            </span>
            <%= if event[:error] do %>
              <div class="text-sm text-red-600 mt-1"><%= event.error %></div>
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp event_class(:room_ready), do: "bg-green-50 border-green-500"
  defp event_class(:room_failed), do: "bg-red-50 border-red-500"
  defp event_class(_), do: "bg-gray-50 border-gray-500"

  defp stat_card(assigns) do
    ~H"""
    <div class={"bg-#{@color}-50 p-4 rounded-lg"}>
      <div class={"text-3xl font-bold text-#{@color}-800"}><%= @value %></div>
      <div class={"text-#{@color}-600 text-sm"}><%= @label %></div>
    </div>
    """
  end
end
```

> **Benefit**: Phoenix LiveView delivers real-time updates over WebSocket with zero client-side JavaScript.

</tab>
<tab title="Go">

```go
// internal/handlers/dashboard.go
package handlers

import (
    "context"
    "encoding/json"
    "fmt"
    "net/http"
    "time"

    "codemoji/pkg/echomq"
    "github.com/redis/go-redis/v9"
)

// DashboardSSE streams real-time job events via Server-Sent Events
func (h *Handlers) DashboardSSE(w http.ResponseWriter, r *http.Request) {
    flusher, ok := w.(http.Flusher)
    if !ok {
        http.Error(w, "streaming not supported", http.StatusInternalServerError)
        return
    }

    w.Header().Set("Content-Type", "text/event-stream")
    w.Header().Set("Cache-Control", "no-cache")
    w.Header().Set("Connection", "keep-alive")

    ctx := r.Context()
    rdb := h.roomQueue.RedisClient()

    // Stream key for game_rooms queue events
    streamKey := "bull:game_rooms:events"
    lastID := "$" // Start from latest

    for {
        select {
        case <-ctx.Done():
            return
        default:
            // XREAD with 5-second block timeout
            results, err := rdb.XRead(ctx, &redis.XReadArgs{
                Streams: []string{streamKey, lastID},
                Count:   10,
                Block:   5 * time.Second,
            }).Result()
            if err != nil {
                continue
            }

            for _, stream := range results {
                for _, msg := range stream.Messages {
                    lastID = msg.ID

                    eventData, _ := json.Marshal(msg.Values)
                    fmt.Fprintf(w, "data: %s\n\n", eventData)
                    flusher.Flush()
                }
            }
        }
    }
}

// DashboardStats returns current queue statistics as JSON
func (h *Handlers) DashboardStats(w http.ResponseWriter, r *http.Request) {
    counts, err := h.roomQueue.GetJobCounts(r.Context())
    if err != nil {
        http.Error(w, "failed to get counts", http.StatusInternalServerError)
        return
    }

    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(counts)
}
```

> **Tradeoff**: SSE requires manual stream management and `http.Flusher` type assertion — no built-in abstraction.

</tab>
<tab title="Node.js">

```typescript
// src/routes/dashboard.ts
import { FastifyInstance } from "fastify";
import { Server } from "socket.io";

export default async function dashboardRoutes(app: FastifyInstance) {
  // REST endpoint for initial stats load
  app.get("/api/dashboard/stats", async (request, reply) => {
    const roomCounts = await app.roomQueue.getJobCounts(
      "waiting",
      "active",
      "completed",
      "failed"
    );
    const guessCounts = await app.guessQueue.getJobCounts(
      "waiting",
      "active",
      "completed",
      "failed"
    );

    return { rooms: roomCounts, guesses: guessCounts };
  });
}

// src/plugins/websocket.ts — Socket.IO plugin for real-time events
export function setupRealtimeDashboard(
  io: Server,
  roomEvents: QueueEvents,
  guessEvents: QueueEvents
) {
  io.on("connection", (socket) => {
    socket.join("dashboard");
  });

  // Bridge EchoMQ events to WebSocket clients
  roomEvents.on("completed", ({ jobId, returnvalue }) => {
    const result = JSON.parse(returnvalue);
    io.to("dashboard").emit("room:ready", {
      jobId,
      roomId: result.roomId,
      status: result.status,
      timestamp: Date.now(),
    });
  });

  roomEvents.on("failed", ({ jobId, failedReason }) => {
    io.to("dashboard").emit("room:failed", {
      jobId,
      error: failedReason,
      timestamp: Date.now(),
    });
  });

  roomEvents.on("active", ({ jobId }) => {
    io.to("dashboard").emit("room:processing", {
      jobId,
      timestamp: Date.now(),
    });
  });

  guessEvents.on("completed", ({ jobId, returnvalue }) => {
    const result = JSON.parse(returnvalue);
    io.to("dashboard").emit("guess:evaluated", {
      jobId,
      playerId: result.playerId,
      correct: result.correct,
      timestamp: Date.now(),
    });
  });
}
```

> **Benefit**: Socket.IO handles reconnection, room-based broadcasting, and binary fallback automatically.

</tab>
</tabs>

---

## 34.5. Event Broadcasting

Bridging queue events into the framework's native event system allows any part of the application to react to job lifecycle changes without coupling directly to Redis streams.

### PubSub Bridge for Game Events

<tabs>
<tab title="Elixir">

```elixir
# lib/codemoji/job_event_broadcaster.ex
defmodule Codemoji.JobEventBroadcaster do
  use GenServer

  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    pubsub = Keyword.fetch!(opts, :pubsub)

    # Subscribe to EchoMQ events for each queue
    {:ok, room_events} = EchoMQ.QueueEvents.start_link(
      queue: "game_rooms",
      connection: :echomq_redis
    )
    EchoMQ.QueueEvents.subscribe(room_events)

    {:ok, guess_events} = EchoMQ.QueueEvents.start_link(
      queue: "guesses",
      connection: :echomq_redis
    )
    EchoMQ.QueueEvents.subscribe(guess_events)

    {:ok, %{pubsub: pubsub}}
  end

  @impl true
  def handle_info({:echomq_event, event_type, data}, state) do
    # Broadcast on the general topic
    Phoenix.PubSub.broadcast(
      state.pubsub,
      "echomq:events",
      {:job_event, event_type, data}
    )

    # Broadcast on queue-specific topic for targeted subscriptions
    queue = data["queue"] || "unknown"
    Phoenix.PubSub.broadcast(
      state.pubsub,
      "echomq:events:#{queue}",
      {:job_event, event_type, data}
    )

    {:noreply, state}
  end
end
```

> **Benefit**: Phoenix.PubSub distributes events across clustered BEAM nodes — multi-server broadcasting built in.

</tab>
<tab title="Go">

```go
// internal/events/broadcaster.go
package events

import (
    "context"
    "encoding/json"
    "log"
    "sync"
    "time"

    "github.com/redis/go-redis/v9"
)

// Subscriber receives job events
type Subscriber func(eventType string, data map[string]interface{})

// Broadcaster bridges EchoMQ Redis stream events to in-process subscribers
type Broadcaster struct {
    rdb         redis.Cmdable
    queues      []string
    subscribers []Subscriber
    mu          sync.RWMutex
}

func NewBroadcaster(rdb redis.Cmdable, queues []string) *Broadcaster {
    return &Broadcaster{rdb: rdb, queues: queues}
}

func (b *Broadcaster) Subscribe(fn Subscriber) {
    b.mu.Lock()
    defer b.mu.Unlock()
    b.subscribers = append(b.subscribers, fn)
}

// Start begins polling Redis streams for job events
func (b *Broadcaster) Start(ctx context.Context) {
    for _, queue := range b.queues {
        go b.pollStream(ctx, queue)
    }
}

func (b *Broadcaster) pollStream(ctx context.Context, queue string) {
    streamKey := "bull:" + queue + ":events"
    lastID := "$"

    for {
        select {
        case <-ctx.Done():
            return
        default:
            results, err := b.rdb.XRead(ctx, &redis.XReadArgs{
                Streams: []string{streamKey, lastID},
                Count:   50,
                Block:   5 * time.Second,
            }).Result()
            if err != nil {
                continue
            }

            for _, stream := range results {
                for _, msg := range stream.Messages {
                    lastID = msg.ID
                    b.dispatch(msg.Values)
                }
            }
        }
    }
}

func (b *Broadcaster) dispatch(data map[string]interface{}) {
    b.mu.RLock()
    defer b.mu.RUnlock()

    eventType, _ := data["event"].(string)
    for _, sub := range b.subscribers {
        go sub(eventType, data)
    }
}
```

> **Tradeoff**: The broadcaster must poll Redis streams in a goroutine — no push-based notification from Redis to Go.

</tab>
<tab title="Node.js">

```typescript
// src/events/broadcaster.ts
import { QueueEvents } from "echomq";
import { EventEmitter } from "events";
import Redis from "ioredis";

type JobEvent = {
  eventType: string;
  jobId: string;
  queue: string;
  data: Record<string, unknown>;
  timestamp: number;
};

/**
 * Bridges EchoMQ queue events into a local EventEmitter
 * for framework-agnostic consumption.
 */
export class JobEventBroadcaster extends EventEmitter {
  private queueEvents: Map<string, QueueEvents> = new Map();

  constructor(
    private connection: Redis,
    private queueNames: string[]
  ) {
    super();
  }

  async start(): Promise<void> {
    for (const queue of this.queueNames) {
      const events = new QueueEvents(queue, {
        connection: this.connection,
      });

      events.on("completed", ({ jobId, returnvalue }) => {
        this.emit("job:completed", {
          eventType: "completed",
          jobId,
          queue,
          data: { returnvalue },
          timestamp: Date.now(),
        } satisfies JobEvent);
      });

      events.on("failed", ({ jobId, failedReason }) => {
        this.emit("job:failed", {
          eventType: "failed",
          jobId,
          queue,
          data: { failedReason },
          timestamp: Date.now(),
        } satisfies JobEvent);
      });

      events.on("active", ({ jobId }) => {
        this.emit("job:active", {
          eventType: "active",
          jobId,
          queue,
          data: {},
          timestamp: Date.now(),
        } satisfies JobEvent);
      });

      this.queueEvents.set(queue, events);
    }
  }

  async stop(): Promise<void> {
    for (const [, events] of this.queueEvents) {
      await events.close();
    }
  }
}
```

> **Benefit**: QueueEvents wraps Redis XREAD internally, so the broadcaster only wires EventEmitter to EventEmitter.

</tab>
</tabs>

---

## 34.6. Dashboard Integration

Production applications need an admin dashboard for queue health monitoring. Phoenix has LiveDashboard, Node.js has Bull Board, and Go can expose metrics via a custom admin panel or Prometheus endpoint.

### Queue Admin Panel

<tabs>
<tab title="Elixir">

```elixir
# lib/codemojix_web/live/echomq_dashboard_page.ex
defmodule CodemojixWeb.EchoMQDashboardPage do
  use Phoenix.LiveDashboard.PageBuilder

  @queues ["game_rooms", "guesses", "leaderboards", "notifications"]

  @impl true
  def menu_link(_, _) do
    {:ok, "EchoMQ Queues"}
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      :timer.send_interval(5_000, :refresh)
    end

    {:ok, fetch_data(socket)}
  end

  @impl true
  def handle_info(:refresh, socket) do
    {:noreply, fetch_data(socket)}
  end

  defp fetch_data(socket) do
    queue_data = Enum.map(@queues, fn queue ->
      {:ok, counts} = EchoMQ.Queue.get_counts(queue, connection: :echomq_redis)
      %{name: queue, counts: counts}
    end)

    assign(socket, :queues, queue_data)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-4">
      <h2 class="text-xl font-bold mb-4">EchoMQ Queue Status</h2>
      <table class="w-full border-collapse">
        <thead>
          <tr class="bg-gray-100">
            <th class="text-left p-2">Queue</th>
            <th class="text-right p-2">Waiting</th>
            <th class="text-right p-2">Active</th>
            <th class="text-right p-2">Completed</th>
            <th class="text-right p-2">Failed</th>
            <th class="text-right p-2">Delayed</th>
          </tr>
        </thead>
        <tbody>
          <%= for queue <- @queues do %>
            <tr class="border-b hover:bg-gray-50">
              <td class="p-2 font-medium"><%= queue.name %></td>
              <td class="p-2 text-right"><%= queue.counts[:waiting] || 0 %></td>
              <td class="p-2 text-right"><%= queue.counts[:active] || 0 %></td>
              <td class="p-2 text-right"><%= queue.counts[:completed] || 0 %></td>
              <td class="p-2 text-right"><%= queue.counts[:failed] || 0 %></td>
              <td class="p-2 text-right"><%= queue.counts[:delayed] || 0 %></td>
            </tr>
          <% end %>
        </tbody>
      </table>
    </div>
    """
  end
end

# lib/codemojix_web/router.ex — register the dashboard page
import Phoenix.LiveDashboard.Router

scope "/" do
  pipe_through :browser

  live_dashboard "/dashboard",
    metrics: CodemojixWeb.Telemetry,
    additional_pages: [
      echomq: CodemojixWeb.EchoMQDashboardPage
    ]
end
```

> **Benefit**: LiveDashboard custom pages inherit authentication, layout, and auto-refresh from the framework.

</tab>
<tab title="Go">

```go
// internal/handlers/admin.go
package handlers

import (
    "context"
    "encoding/json"
    "net/http"

    "codemoji/pkg/echomq"
)

type QueueStatus struct {
    Name   string           `json:"name"`
    Counts *echomq.JobCounts `json:"counts"`
    Paused bool             `json:"paused"`
}

// AdminDashboard returns the status of all queues as JSON
func (h *Handlers) AdminDashboard(w http.ResponseWriter, r *http.Request) {
    ctx := r.Context()
    queueNames := []string{"game_rooms", "guesses", "leaderboards", "notifications"}

    statuses := make([]QueueStatus, 0, len(queueNames))
    for _, name := range queueNames {
        q := echomq.NewQueue(name, h.roomQueue.RedisClient())
        counts, err := q.GetJobCounts(ctx)
        if err != nil {
            counts = &echomq.JobCounts{}
        }
        paused, _ := q.IsPaused(ctx)
        statuses = append(statuses, QueueStatus{
            Name:   name,
            Counts: counts,
            Paused: paused,
        })
    }

    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(map[string]interface{}{
        "queues": statuses,
    })
}

// AdminPrometheus exports queue metrics in Prometheus format
func (h *Handlers) AdminPrometheus(w http.ResponseWriter, r *http.Request) {
    ctx := r.Context()
    queueNames := []string{"game_rooms", "guesses", "leaderboards", "notifications"}

    w.Header().Set("Content-Type", "text/plain; charset=utf-8")
    for _, name := range queueNames {
        q := echomq.NewQueue(name, h.roomQueue.RedisClient())
        counts, err := q.GetJobCounts(ctx)
        if err != nil {
            continue
        }
        fmt.Fprintf(w, "echomq_waiting{queue=%q} %d\n", name, counts.Waiting)
        fmt.Fprintf(w, "echomq_active{queue=%q} %d\n", name, counts.Active)
        fmt.Fprintf(w, "echomq_completed{queue=%q} %d\n", name, counts.Completed)
        fmt.Fprintf(w, "echomq_failed{queue=%q} %d\n", name, counts.Failed)
        fmt.Fprintf(w, "echomq_delayed{queue=%q} %d\n", name, counts.Delayed)
    }
}
```

> **Tradeoff**: No built-in admin UI — you must build JSON endpoints and connect a separate frontend or Grafana.

</tab>
<tab title="Node.js">

```typescript
// src/plugins/bull-board.ts
import { createBullBoard } from "@bull-board/api";
import { BullMQAdapter } from "@bull-board/api/bullMQAdapter";
import { FastifyAdapter } from "@bull-board/fastify";
import { FastifyInstance } from "fastify";
import { Queue } from "echomq";

/**
 * Registers Bull Board UI at /admin/queues for visual queue management.
 * Bull Board provides: job inspection, retry, delete, and live stats.
 */
export function setupBullBoard(app: FastifyInstance, queues: Queue[]) {
  const serverAdapter = new FastifyAdapter();
  serverAdapter.setBasePath("/admin/queues");

  createBullBoard({
    queues: queues.map((q) => new BullMQAdapter(q)),
    serverAdapter,
  });

  app.register(serverAdapter.registerPlugin(), {
    prefix: "/admin/queues",
    basePath: "/admin/queues",
  });
}

// Usage in app.ts:
// setupBullBoard(app, [roomQueue, guessQueue, leaderboardQueue]);

// Custom Prometheus metrics endpoint alongside Bull Board
export default async function metricsRoutes(app: FastifyInstance) {
  app.get("/metrics/queues", async () => {
    const queues = [app.roomQueue, app.guessQueue];
    const lines: string[] = [];

    for (const queue of queues) {
      const counts = await queue.getJobCounts(
        "waiting", "active", "completed", "failed", "delayed"
      );
      const name = queue.name;
      lines.push(`echomq_waiting{queue="${name}"} ${counts.waiting}`);
      lines.push(`echomq_active{queue="${name}"} ${counts.active}`);
      lines.push(`echomq_completed{queue="${name}"} ${counts.completed}`);
      lines.push(`echomq_failed{queue="${name}"} ${counts.failed}`);
      lines.push(`echomq_delayed{queue="${name}"} ${counts.delayed}`);
    }

    return lines.join("\n");
  });
}
```

> **Benefit**: Bull Board provides a production-ready admin UI with job inspection, retry, and delete out of the box.

</tab>
</tabs>

---

## 34.7. Database Transaction Integration

A critical pattern: enqueue a job only if the database transaction succeeds. If the transaction rolls back, the job must not be enqueued. Each ecosystem handles this differently.

### Prize Claim with Transactional Enqueue

When a player claims a prize (ORD + BNK entities) after winning, the order record and balance deduction must be atomic with the prize distribution job.

<tabs>
<tab title="Elixir">

```elixir
# lib/codemoji/prizes.ex
defmodule Codemoji.Prizes do
  alias Codemoji.Repo
  alias Codemoji.Prizes.{Order, BankTransaction}

  def claim_prize(player_id, prize_id) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:order, Order.changeset(%Order{}, %{
      player_id: player_id,
      prize_id: prize_id,
      status: "pending"
    }))
    |> Ecto.Multi.insert(:bank_txn, fn %{order: order} ->
      BankTransaction.changeset(%BankTransaction{}, %{
        order_id: order.id,
        player_id: player_id,
        amount: -prize_cost(prize_id),
        type: "prize_claim"
      })
    end)
    |> Ecto.Multi.run(:enqueue_distribution, fn _repo, %{order: order} ->
      EchoMQ.Queue.add(
        "prizes",
        "distribute_prize",
        %{
          order_id: order.id,
          player_id: player_id,
          prize_id: prize_id
        },
        connection: :echomq_redis,
        attempts: 5,
        backoff: %{type: :exponential, delay: 2_000}
      )
    end)
    |> Repo.transaction()
  end

  defp prize_cost(prize_id) do
    Repo.get!(Codemoji.Prizes.Prize, prize_id).cost
  end
end
```

> **Benefit**: `Ecto.Multi` composes the enqueue step into the transaction — if Redis fails, the DB rolls back.

</tab>
<tab title="Go">

```go
// internal/services/prizes.go
package services

import (
    "context"
    "database/sql"
    "fmt"

    "codemoji/internal/models"
    "codemoji/pkg/echomq"
)

type PrizeService struct {
    db         *sql.DB
    prizeQueue *echomq.Queue
}

func (s *PrizeService) ClaimPrize(ctx context.Context, playerID, prizeID string) error {
    tx, err := s.db.BeginTx(ctx, nil)
    if err != nil {
        return fmt.Errorf("begin tx: %w", err)
    }
    defer tx.Rollback()

    // Create order
    order, err := models.CreateOrderTx(tx, playerID, prizeID, "pending")
    if err != nil {
        return fmt.Errorf("create order: %w", err)
    }

    // Deduct balance
    prizeCost, err := models.GetPrizeCost(tx, prizeID)
    if err != nil {
        return fmt.Errorf("get prize cost: %w", err)
    }

    err = models.CreateBankTransactionTx(tx, playerID, order.ID, -prizeCost, "prize_claim")
    if err != nil {
        return fmt.Errorf("create bank txn: %w", err)
    }

    // Commit database transaction first
    if err := tx.Commit(); err != nil {
        return fmt.Errorf("commit: %w", err)
    }

    // Enqueue AFTER commit — if this fails, a recovery job will retry
    _, err = s.prizeQueue.Add(ctx, "distribute_prize", map[string]interface{}{
        "order_id":  order.ID,
        "player_id": playerID,
        "prize_id":  prizeID,
    }, echomq.JobOptions{
        Attempts: 5,
        Backoff: echomq.BackoffConfig{
            Type:  "exponential",
            Delay: 2000,
        },
    })
    if err != nil {
        // Order committed but job failed — log for recovery
        log.Printf("WARN: order %s committed but enqueue failed: %v", order.ID, err)
    }

    return nil
}
```

> **Tradeoff**: Go enqueues after `tx.Commit()` — a crash between commit and enqueue requires a recovery mechanism.

</tab>
<tab title="Node.js">

```typescript
// src/services/prizes.ts
import { Queue } from "echomq";
import { PrismaClient } from "@prisma/client";

export class PrizeService {
  constructor(
    private db: PrismaClient,
    private prizeQueue: Queue
  ) {}

  async claimPrize(playerId: string, prizeId: string): Promise<string> {
    // Prisma interactive transaction — all-or-nothing
    const result = await this.db.$transaction(async (tx) => {
      const prize = await tx.prize.findUniqueOrThrow({
        where: { id: prizeId },
      });

      const order = await tx.order.create({
        data: {
          playerId,
          prizeId,
          status: "pending",
        },
      });

      await tx.bankTransaction.create({
        data: {
          orderId: order.id,
          playerId,
          amount: -prize.cost,
          type: "prize_claim",
        },
      });

      return order;
    });

    // Enqueue AFTER transaction commits
    await this.prizeQueue.add(
      "distribute_prize",
      {
        orderId: result.id,
        playerId,
        prizeId,
      },
      {
        attempts: 5,
        backoff: { type: "exponential", delay: 2000 },
      }
    );

    return result.id;
  }
}
```

> **Tradeoff**: Like Go, enqueue happens after `$transaction` — Prisma has no way to include Redis in its TX boundary.

</tab>
</tabs>

---

## 34.8. API Endpoints for Job Management

REST endpoints for inspecting, retrying, and cancelling jobs from the admin panel or CLI tooling.

### Job Status and Retry Endpoints

<tabs>
<tab title="Elixir">

```elixir
# lib/codemojix_web/controllers/job_controller.ex
defmodule CodemojixWeb.JobController do
  use CodemojixWeb, :controller

  @queues ~w(game_rooms guesses leaderboards prizes notifications)

  def show(conn, %{"queue" => queue, "id" => job_id}) when queue in @queues do
    case EchoMQ.Queue.get_job(queue, job_id, connection: :echomq_redis) do
      {:ok, nil} ->
        conn |> put_status(:not_found) |> json(%{error: "Job not found"})

      {:ok, job} ->
        json(conn, %{
          id: job.id,
          name: job.name,
          data: job.data,
          status: job_status(job),
          progress: job.progress,
          attempts_made: job.attempts_made,
          result: job.return_value,
          failed_reason: job.failed_reason,
          timestamp: job.timestamp
        })
    end
  end

  def retry(conn, %{"queue" => queue, "id" => job_id}) when queue in @queues do
    case EchoMQ.Queue.retry_job(queue, job_id, connection: :echomq_redis) do
      :ok -> json(conn, %{status: "retried", job_id: job_id})
      {:error, reason} ->
        conn |> put_status(:unprocessable_entity) |> json(%{error: inspect(reason)})
    end
  end

  def cancel(conn, %{"queue" => queue, "id" => job_id}) when queue in @queues do
    case EchoMQ.Queue.remove_job(queue, job_id, connection: :echomq_redis) do
      {:ok, 1} -> json(conn, %{status: "cancelled", job_id: job_id})
      {:ok, 0} ->
        conn |> put_status(:not_found) |> json(%{error: "Job not found or already processed"})
      {:error, reason} ->
        conn |> put_status(:unprocessable_entity) |> json(%{error: inspect(reason)})
    end
  end

  def counts(conn, %{"queue" => queue}) when queue in @queues do
    {:ok, counts} = EchoMQ.Queue.get_counts(queue, connection: :echomq_redis)
    json(conn, counts)
  end

  defp job_status(%{finished_on: nil, processed_on: nil}), do: "waiting"
  defp job_status(%{finished_on: nil, processed_on: _}), do: "active"
  defp job_status(%{failed_reason: nil}), do: "completed"
  defp job_status(_), do: "failed"
end
```

> **Benefit**: Guard clauses (`when queue in @queues`) reject invalid queue names at the pattern-match level.

</tab>
<tab title="Go">

```go
// internal/handlers/jobs.go
package handlers

import (
    "encoding/json"
    "net/http"

    "github.com/go-chi/chi/v5"
    "codemoji/pkg/echomq"
)

var allowedQueues = map[string]bool{
    "game_rooms": true, "guesses": true,
    "leaderboards": true, "prizes": true, "notifications": true,
}

func (h *Handlers) GetJob(w http.ResponseWriter, r *http.Request) {
    queue := chi.URLParam(r, "queue")
    jobID := chi.URLParam(r, "jobID")

    if !allowedQueues[queue] {
        http.Error(w, "invalid queue", http.StatusBadRequest)
        return
    }

    q := echomq.NewQueue(queue, h.roomQueue.RedisClient())
    job, err := q.GetJob(r.Context(), jobID)
    if err != nil {
        http.Error(w, "job not found", http.StatusNotFound)
        return
    }

    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(map[string]interface{}{
        "id":            job.ID,
        "name":          job.Name,
        "data":          job.Data,
        "attemptsMade":  job.AttemptsMade,
        "timestamp":     job.Timestamp,
    })
}

func (h *Handlers) RetryJob(w http.ResponseWriter, r *http.Request) {
    queue := chi.URLParam(r, "queue")
    jobID := chi.URLParam(r, "jobID")

    if !allowedQueues[queue] {
        http.Error(w, "invalid queue", http.StatusBadRequest)
        return
    }

    q := echomq.NewQueue(queue, h.roomQueue.RedisClient())
    if err := q.RetryJob(r.Context(), jobID); err != nil {
        http.Error(w, err.Error(), http.StatusUnprocessableEntity)
        return
    }

    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(map[string]interface{}{
        "status": "retried",
        "jobId":  jobID,
    })
}

func (h *Handlers) CancelJob(w http.ResponseWriter, r *http.Request) {
    queue := chi.URLParam(r, "queue")
    jobID := chi.URLParam(r, "jobID")

    if !allowedQueues[queue] {
        http.Error(w, "invalid queue", http.StatusBadRequest)
        return
    }

    q := echomq.NewQueue(queue, h.roomQueue.RedisClient())
    if err := q.RemoveJob(r.Context(), jobID); err != nil {
        http.Error(w, err.Error(), http.StatusUnprocessableEntity)
        return
    }

    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(map[string]interface{}{
        "status": "cancelled",
        "jobId":  jobID,
    })
}
```

> **Benefit**: Explicit allowlist map gives O(1) validation with clear security boundary.

</tab>
<tab title="Node.js">

```typescript
// src/routes/jobs.ts
import { FastifyInstance } from "fastify";
import { Queue } from "echomq";

const ALLOWED_QUEUES = new Set([
  "game_rooms", "guesses", "leaderboards", "prizes", "notifications",
]);

export default async function jobRoutes(app: FastifyInstance) {
  app.get<{ Params: { queue: string; jobId: string } }>(
    "/api/queues/:queue/jobs/:jobId",
    async (request, reply) => {
      const { queue: queueName, jobId } = request.params;
      if (!ALLOWED_QUEUES.has(queueName)) {
        return reply.code(400).send({ error: "invalid queue" });
      }

      const queue = new Queue(queueName, { connection: app.redis });
      const job = await queue.getJob(jobId);
      if (!job) {
        return reply.code(404).send({ error: "job not found" });
      }

      const state = await job.getState();
      return {
        id: job.id,
        name: job.name,
        data: job.data,
        status: state,
        progress: job.progress,
        attemptsMade: job.attemptsMade,
        result: job.returnvalue,
        failedReason: job.failedReason,
        timestamp: job.timestamp,
      };
    }
  );

  app.post<{ Params: { queue: string; jobId: string } }>(
    "/api/queues/:queue/jobs/:jobId/retry",
    async (request, reply) => {
      const { queue: queueName, jobId } = request.params;
      if (!ALLOWED_QUEUES.has(queueName)) {
        return reply.code(400).send({ error: "invalid queue" });
      }

      const queue = new Queue(queueName, { connection: app.redis });
      const job = await queue.getJob(jobId);
      if (!job) {
        return reply.code(404).send({ error: "job not found" });
      }

      await job.retry();
      return { status: "retried", jobId };
    }
  );

  app.delete<{ Params: { queue: string; jobId: string } }>(
    "/api/queues/:queue/jobs/:jobId",
    async (request, reply) => {
      const { queue: queueName, jobId } = request.params;
      if (!ALLOWED_QUEUES.has(queueName)) {
        return reply.code(400).send({ error: "invalid queue" });
      }

      const queue = new Queue(queueName, { connection: app.redis });
      const job = await queue.getJob(jobId);
      if (!job) {
        return reply.code(404).send({ error: "job not found" });
      }

      await job.remove();
      return { status: "cancelled", jobId };
    }
  );
}
```

> **Tradeoff**: Creating a new Queue instance per request works but is less efficient than a shared queue registry.

</tab>
</tabs>

---

## 34.9. Webhook Integration

External payment systems like Telegram Stars send webhook callbacks that must be handled reliably. The webhook handler validates the payload, persists it, and enqueues a processing job.

### Prize Claim Webhook Handler

<tabs>
<tab title="Elixir">

```elixir
# lib/codemojix_web/controllers/webhook_controller.ex
defmodule CodemojixWeb.WebhookController do
  use CodemojixWeb, :controller

  plug :verify_telegram_signature when action in [:telegram_payment]

  def telegram_payment(conn, %{"pre_checkout_query" => query}) do
    # Acknowledge the pre-checkout immediately (Telegram requires < 10s)
    json(conn, %{ok: true})
  end

  def telegram_payment(conn, %{"message" => %{"successful_payment" => payment}}) do
    order_id = payment["invoice_payload"]
    amount = payment["total_amount"]
    currency = payment["currency"]

    # Enqueue prize distribution — webhook must respond fast
    {:ok, _job} = EchoMQ.Queue.add(
      "prizes",
      "process_payment",
      %{
        order_id: order_id,
        telegram_payment_id: payment["telegram_payment_charge_id"],
        amount: amount,
        currency: currency
      },
      connection: :echomq_redis,
      priority: 1,
      attempts: 10,
      backoff: %{type: :exponential, delay: 5_000}
    )

    json(conn, %{ok: true})
  end

  defp verify_telegram_signature(conn, _opts) do
    # Validate X-Telegram-Bot-Api-Secret-Token header
    token = get_req_header(conn, "x-telegram-bot-api-secret-token") |> List.first()
    expected = Application.get_env(:codemoji, :telegram_webhook_secret)

    if Plug.Crypto.secure_compare(token || "", expected || "") do
      conn
    else
      conn |> put_status(:unauthorized) |> json(%{error: "invalid signature"}) |> halt()
    end
  end
end
```

> **Benefit**: `Plug.Crypto.secure_compare` prevents timing attacks on webhook signature verification.

</tab>
<tab title="Go">

```go
// internal/handlers/webhooks.go
package handlers

import (
    "crypto/hmac"
    "crypto/sha256"
    "encoding/hex"
    "encoding/json"
    "io"
    "net/http"
    "os"

    "codemoji/pkg/echomq"
)

func (h *Handlers) TelegramPaymentWebhook(w http.ResponseWriter, r *http.Request) {
    // Verify webhook signature
    secretToken := r.Header.Get("X-Telegram-Bot-Api-Secret-Token")
    expected := os.Getenv("TELEGRAM_WEBHOOK_SECRET")
    if !hmac.Equal([]byte(secretToken), []byte(expected)) {
        http.Error(w, "unauthorized", http.StatusUnauthorized)
        return
    }

    body, _ := io.ReadAll(r.Body)
    var payload struct {
        Message struct {
            SuccessfulPayment *struct {
                InvoicePayload           string `json:"invoice_payload"`
                TelegramPaymentChargeID  string `json:"telegram_payment_charge_id"`
                TotalAmount              int    `json:"total_amount"`
                Currency                 string `json:"currency"`
            } `json:"successful_payment"`
        } `json:"message"`
    }

    if err := json.Unmarshal(body, &payload); err != nil {
        http.Error(w, "invalid payload", http.StatusBadRequest)
        return
    }

    payment := payload.Message.SuccessfulPayment
    if payment == nil {
        w.WriteHeader(http.StatusOK)
        json.NewEncoder(w).Encode(map[string]bool{"ok": true})
        return
    }

    // Enqueue prize distribution — webhook must respond fast
    h.prizeQueue.Add(r.Context(), "process_payment", map[string]interface{}{
        "order_id":             payment.InvoicePayload,
        "telegram_payment_id": payment.TelegramPaymentChargeID,
        "amount":              payment.TotalAmount,
        "currency":            payment.Currency,
    }, echomq.JobOptions{
        Priority: 1,
        Attempts: 10,
        Backoff: echomq.BackoffConfig{
            Type:  "exponential",
            Delay: 5000,
        },
    })

    w.WriteHeader(http.StatusOK)
    json.NewEncoder(w).Encode(map[string]bool{"ok": true})
}
```

> **Benefit**: `crypto/hmac.Equal` provides constant-time comparison — Go's stdlib covers this without dependencies.

</tab>
<tab title="Node.js">

```typescript
// src/routes/webhooks.ts
import { FastifyInstance } from "fastify";
import crypto from "crypto";

export default async function webhookRoutes(app: FastifyInstance) {
  // Telegram payment webhook
  app.post("/webhooks/telegram/payment", {
    preHandler: async (request, reply) => {
      const token = request.headers["x-telegram-bot-api-secret-token"];
      const expected = process.env.TELEGRAM_WEBHOOK_SECRET;

      if (!token || !expected) {
        return reply.code(401).send({ error: "unauthorized" });
      }

      const isValid = crypto.timingSafeEqual(
        Buffer.from(String(token)),
        Buffer.from(expected)
      );
      if (!isValid) {
        return reply.code(401).send({ error: "invalid signature" });
      }
    },
    handler: async (request, reply) => {
      const { message } = request.body as any;
      const payment = message?.successful_payment;

      if (!payment) {
        return { ok: true };
      }

      // Enqueue prize distribution — webhook must respond fast
      await app.prizeQueue.add(
        "process_payment",
        {
          orderId: payment.invoice_payload,
          telegramPaymentId: payment.telegram_payment_charge_id,
          amount: payment.total_amount,
          currency: payment.currency,
        },
        {
          priority: 1,
          attempts: 10,
          backoff: { type: "exponential", delay: 5000 },
        }
      );

      return { ok: true };
    },
  });
}
```

> **Benefit**: `crypto.timingSafeEqual` is built into Node.js — no third-party package needed for safe comparison.

</tab>
</tabs>

---

## 34.10. Scheduled Background Jobs

Periodic tasks like leaderboard refresh (SNP entity) run on a schedule. Each ecosystem wires this differently: Phoenix uses GenServer timers, Go uses goroutine tickers, and Node.js uses EchoMQ's built-in job scheduler.

### Leaderboard Refresh Schedule

<tabs>
<tab title="Elixir">

```elixir
# lib/codemoji/schedulers/leaderboard_scheduler.ex
defmodule Codemoji.Schedulers.LeaderboardScheduler do
  use GenServer

  @refresh_interval :timer.minutes(5)

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    schedule_refresh()
    {:ok, %{}}
  end

  @impl true
  def handle_info(:refresh, state) do
    # Enqueue a leaderboard snapshot job
    {:ok, _job} = EchoMQ.Queue.add(
      "leaderboards",
      "refresh_snapshot",
      %{
        timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
        boards: ["daily", "weekly", "all_time"]
      },
      connection: :echomq_redis,
      attempts: 3
    )

    schedule_refresh()
    {:noreply, state}
  end

  defp schedule_refresh do
    Process.send_after(self(), :refresh, @refresh_interval)
  end
end

# Add to application.ex children list:
# {Codemoji.Schedulers.LeaderboardScheduler, []}
```

> **Tradeoff**: GenServer timers are per-node — running multiple nodes requires deduplication or leader election.

</tab>
<tab title="Go">

```go
// internal/schedulers/leaderboard.go
package schedulers

import (
    "context"
    "log"
    "time"

    "codemoji/pkg/echomq"
)

// LeaderboardScheduler enqueues periodic leaderboard refresh jobs
type LeaderboardScheduler struct {
    queue    *echomq.Queue
    interval time.Duration
}

func NewLeaderboardScheduler(queue *echomq.Queue, interval time.Duration) *LeaderboardScheduler {
    return &LeaderboardScheduler{queue: queue, interval: interval}
}

func (s *LeaderboardScheduler) Start(ctx context.Context) {
    ticker := time.NewTicker(s.interval)
    defer ticker.Stop()

    // Run immediately on start
    s.enqueueRefresh(ctx)

    for {
        select {
        case <-ctx.Done():
            return
        case <-ticker.C:
            s.enqueueRefresh(ctx)
        }
    }
}

func (s *LeaderboardScheduler) enqueueRefresh(ctx context.Context) {
    _, err := s.queue.Add(ctx, "refresh_snapshot", map[string]interface{}{
        "timestamp": time.Now().Format(time.RFC3339),
        "boards":    []string{"daily", "weekly", "all_time"},
    }, echomq.JobOptions{
        Attempts: 3,
    })
    if err != nil {
        log.Printf("failed to enqueue leaderboard refresh: %v", err)
    }
}

// Usage in main.go:
// scheduler := schedulers.NewLeaderboardScheduler(leaderboardQueue, 5*time.Minute)
// go scheduler.Start(ctx)
```

> **Tradeoff**: `time.Ticker` is per-process — same multi-instance deduplication concern as Elixir.

</tab>
<tab title="Node.js">

```typescript
// src/schedulers/leaderboard.ts
import { Queue } from "echomq";
import Redis from "ioredis";

/**
 * Uses EchoMQ's built-in job scheduler (upsertJobScheduler)
 * for durable, Redis-persisted schedules that survive restarts.
 */
export async function setupLeaderboardScheduler(connection: Redis) {
  const queue = new Queue("leaderboards", { connection });

  // Upsert a repeatable job — runs every 5 minutes.
  // The scheduler ID is idempotent: calling this on every
  // server start will not create duplicates.
  await queue.upsertJobScheduler(
    "leaderboard-refresh",
    { every: 5 * 60 * 1000 }, // 5 minutes in milliseconds
    {
      name: "refresh_snapshot",
      data: {
        boards: ["daily", "weekly", "all_time"],
      },
      opts: {
        attempts: 3,
        backoff: { type: "exponential", delay: 1000 },
      },
    }
  );

  return queue;
}

// Usage in app.ts:
// await setupLeaderboardScheduler(connection);
```

> **Benefit**: `upsertJobScheduler` is Redis-persisted and idempotent — safe to call on every server restart.

</tab>
</tabs>

---

## 34.11. Testing Queue Integration

Testing queue interactions requires isolating the queue from actual Redis during unit tests while still validating the enqueue/process contract.

### Testing Room Creation with Mock Queue

<tabs>
<tab title="Elixir">

```elixir
# test/codemojix_web/controllers/room_controller_test.exs
defmodule CodemojixWeb.RoomControllerTest do
  use CodemojixWeb.ConnCase

  import Mox

  setup :verify_on_exit!

  describe "POST /api/rooms" do
    test "creates room and enqueues setup job", %{conn: conn} do
      # Mock the queue add call
      expect(Codemoji.QueueMock, :add, fn
        "game_rooms", "setup_room", %{room_id: _, config: _}, _opts ->
          {:ok, %EchoMQ.Job{id: "mock-job-123", name: "setup_room"}}
      end)

      conn = post(conn, ~p"/api/rooms", room: %{
        max_players: 4,
        bot_count: 2,
        difficulty: "medium"
      })

      assert %{
        "id" => _room_id,
        "status" => "initializing",
        "setup_job_id" => "mock-job-123"
      } = json_response(conn, 201)
    end

    test "returns errors for invalid params", %{conn: conn} do
      conn = post(conn, ~p"/api/rooms", room: %{max_players: -1})

      assert json_response(conn, 422)["errors"] != %{}
    end
  end
end

# test/codemoji/workers/room_setup_test.exs
defmodule Codemoji.Workers.RoomSetupTest do
  use Codemoji.DataCase

  alias Codemoji.Workers.RoomSetup

  test "processes room setup job successfully" do
    room = insert(:room, status: "initializing")

    job = %EchoMQ.Job{
      id: "test-job-1",
      name: "setup_room",
      data: %{
        "room_id" => room.id,
        "config" => %{
          "max_players" => 4,
          "bot_count" => 2,
          "difficulty" => "medium"
        }
      },
      queue_name: "game_rooms"
    }

    assert {:ok, result} = RoomSetup.process(job)
    assert result.status == "ready"

    updated_room = Repo.get!(Codemoji.Rooms.Room, room.id)
    assert updated_room.status == "ready"
  end
end
```

> **Benefit**: Mox generates compile-time verified mocks from behaviours — mock drift is impossible.

</tab>
<tab title="Go">

```go
// internal/handlers/rooms_test.go
package handlers_test

import (
    "bytes"
    "encoding/json"
    "net/http"
    "net/http/httptest"
    "testing"

    "codemoji/internal/handlers"
    "codemoji/internal/mocks"
    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/require"
)

func TestCreateRoom(t *testing.T) {
    mockQueue := mocks.NewMockQueue(t)
    mockQueue.On("Add", mock.Anything, "setup_room", mock.Anything, mock.Anything).
        Return(&echomq.Job{ID: "mock-job-123"}, nil)

    h := handlers.New(mockQueue, nil)

    body, _ := json.Marshal(map[string]interface{}{
        "maxPlayers": 4,
        "botCount":   2,
        "difficulty": "medium",
    })

    req := httptest.NewRequest(http.MethodPost, "/api/rooms", bytes.NewReader(body))
    req.Header.Set("Content-Type", "application/json")
    w := httptest.NewRecorder()

    h.CreateRoom(w, req)

    assert.Equal(t, http.StatusCreated, w.Code)

    var resp map[string]interface{}
    require.NoError(t, json.Unmarshal(w.Body.Bytes(), &resp))
    assert.Equal(t, "initializing", resp["status"])
    assert.Equal(t, "mock-job-123", resp["setup_job_id"])

    mockQueue.AssertExpectations(t)
}

// internal/workers/room_setup_test.go
func TestRoomSetupProcessor(t *testing.T) {
    job := &echomq.Job{
        ID:   "test-job-1",
        Name: "setup_room",
        Data: map[string]interface{}{
            "room_id": "room-abc",
            "config": map[string]interface{}{
                "max_players": float64(4),
                "bot_count":   float64(2),
                "difficulty":  "medium",
            },
        },
    }

    result, err := workers.RoomSetupProcessor(job)
    require.NoError(t, err)

    resultMap := result.(map[string]interface{})
    assert.Equal(t, "ready", resultMap["status"])
}
```

> **Benefit**: `httptest.NewRecorder` + testify mocks give full request/response testing without a running server.

</tab>
<tab title="Node.js">

```typescript
// src/__tests__/routes/rooms.test.ts
import { describe, it, expect, vi, beforeEach } from "vitest";
import Fastify from "fastify";

describe("POST /api/rooms", () => {
  let app: ReturnType<typeof Fastify>;
  const mockAdd = vi.fn();

  beforeEach(async () => {
    app = Fastify();

    // Mock the queue
    app.decorate("roomQueue", { add: mockAdd });
    app.decorate("db", {
      rooms: {
        create: vi.fn().mockResolvedValue({ id: "room-abc" }),
      },
    });

    await app.register(import("../../routes/rooms"));
    await app.ready();
  });

  it("creates room and enqueues setup job", async () => {
    mockAdd.mockResolvedValue({ id: "mock-job-123" });

    const response = await app.inject({
      method: "POST",
      url: "/api/rooms",
      payload: { maxPlayers: 4, botCount: 2, difficulty: "medium" },
    });

    expect(response.statusCode).toBe(201);
    const body = response.json();
    expect(body.status).toBe("initializing");
    expect(body.setupJobId).toBe("mock-job-123");

    expect(mockAdd).toHaveBeenCalledWith(
      "setup_room",
      expect.objectContaining({ roomId: "room-abc" }),
      expect.objectContaining({ priority: 1 })
    );
  });
});

// src/__tests__/workers/room-setup.test.ts
describe("RoomSetupProcessor", () => {
  it("generates room map and returns ready status", async () => {
    const mockJob = {
      id: "test-job-1",
      data: {
        roomId: "room-abc",
        config: { maxPlayers: 4, botCount: 2, difficulty: "medium" },
      },
      updateProgress: vi.fn(),
    };

    const result = await roomSetupProcessor(mockJob as any);

    expect(result.status).toBe("ready");
    expect(result.roomId).toBe("room-abc");
    expect(mockJob.updateProgress).toHaveBeenCalledWith(100);
  });
});
```

> **Benefit**: Fastify's `app.inject()` sends in-memory requests — no port binding needed for route tests.

</tab>
</tabs>

---

## 34.12. Request-Response with Background Jobs

Sometimes an API client needs to wait for a background job to complete before returning a response. This pattern combines immediate enqueue with event-driven completion notification.

### Synchronous Room Setup (Wait for Ready)

A variant where the API blocks until the room is fully set up, using long polling with a timeout.

<tabs>
<tab title="Elixir">

```elixir
# lib/codemojix_web/controllers/room_controller.ex
def create_and_wait(conn, %{"room" => room_params}) do
  case Codemoji.Rooms.create_room(room_params) do
    {:ok, room} ->
      {:ok, job} = EchoMQ.Queue.add(
        "game_rooms", "setup_room",
        %{room_id: room.id, config: room_params},
        connection: :echomq_redis, priority: 1
      )

      # Subscribe and wait for completion (max 30 seconds)
      Phoenix.PubSub.subscribe(Codemoji.PubSub, "echomq:events:game_rooms")

      result = receive do
        {:job_event, :completed, %{"jobId" => ^(job.id)} = data} ->
          {:ok, data}
        {:job_event, :failed, %{"jobId" => ^(job.id)} = data} ->
          {:error, data["failedReason"]}
      after
        30_000 -> {:error, "timeout"}
      end

      Phoenix.PubSub.unsubscribe(Codemoji.PubSub, "echomq:events:game_rooms")

      case result do
        {:ok, _data} ->
          conn |> put_status(:created) |> json(%{id: room.id, status: "ready"})
        {:error, reason} ->
          conn |> put_status(:gateway_timeout) |> json(%{error: reason})
      end

    {:error, changeset} ->
      conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(changeset)})
  end
end
```

> **Benefit**: `receive` with timeout is a native BEAM primitive — no polling, no external dependencies.

</tab>
<tab title="Go">

```go
// internal/handlers/rooms_sync.go
func (h *Handlers) CreateRoomAndWait(w http.ResponseWriter, r *http.Request) {
    var req models.CreateRoomRequest
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        http.Error(w, "invalid request body", http.StatusBadRequest)
        return
    }

    room, err := models.CreateRoom(r.Context(), req)
    if err != nil {
        http.Error(w, "failed to create room", http.StatusInternalServerError)
        return
    }

    job, err := h.roomQueue.Add(r.Context(), "setup_room", map[string]interface{}{
        "room_id": room.ID,
        "config":  req,
    }, echomq.JobOptions{Priority: 1})
    if err != nil {
        http.Error(w, "failed to enqueue", http.StatusInternalServerError)
        return
    }

    // Poll for job completion (max 30 seconds)
    ctx, cancel := context.WithTimeout(r.Context(), 30*time.Second)
    defer cancel()

    ticker := time.NewTicker(500 * time.Millisecond)
    defer ticker.Stop()

    for {
        select {
        case <-ctx.Done():
            w.WriteHeader(http.StatusGatewayTimeout)
            json.NewEncoder(w).Encode(map[string]string{"error": "timeout"})
            return
        case <-ticker.C:
            updatedJob, err := h.roomQueue.GetJob(ctx, job.ID)
            if err != nil {
                continue
            }
            // Check if job has a return value (completed)
            if updatedJob.ReturnValue != nil {
                w.Header().Set("Content-Type", "application/json")
                w.WriteHeader(http.StatusCreated)
                json.NewEncoder(w).Encode(map[string]interface{}{
                    "id": room.ID, "status": "ready",
                })
                return
            }
        }
    }
}
```

> **Tradeoff**: Polling with `time.Ticker` adds latency (up to 500ms) between job completion and response.

</tab>
<tab title="Node.js">

```typescript
// src/routes/rooms-sync.ts
import { FastifyInstance } from "fastify";
import { Job, QueueEvents } from "echomq";

export default async function syncRoomRoutes(app: FastifyInstance) {
  app.post("/api/rooms/sync", async (request, reply) => {
    const { maxPlayers, botCount, difficulty } = request.body as any;

    const room = await app.db.rooms.create({ maxPlayers, botCount, difficulty });

    const job = await app.roomQueue.add(
      "setup_room",
      { roomId: room.id, config: { maxPlayers, botCount, difficulty } },
      { priority: 1 }
    );

    // Wait for job completion using QueueEvents (max 30 seconds)
    const events = new QueueEvents("game_rooms", {
      connection: app.redis,
    });

    try {
      const result = await job.waitUntilFinished(events, 30000);

      return reply.code(201).send({
        id: room.id,
        status: "ready",
        result,
      });
    } catch (err) {
      const message = err instanceof Error ? err.message : "timeout";
      return reply.code(504).send({ error: message });
    } finally {
      await events.close();
    }
  });
}
```

> **Benefit**: `job.waitUntilFinished(events, timeout)` provides a clean one-liner for synchronous job waiting.

</tab>
</tabs>

---

## 34.13. Summary

Framework integration follows a consistent pattern across all three ecosystems:

| Concern | Elixir / Phoenix | Go / Chi | Node.js / Fastify |
|---------|-----------------|----------|-------------------|
| **Bootstrap** | Supervision tree children | `main()` goroutines | Fastify decorators + plugins |
| **Enqueue** | Controller → `Queue.add/4` | Handler → `queue.Add()` | Route → `queue.add()` |
| **Real-time** | LiveView + PubSub | SSE via `http.Flusher` | Socket.IO + QueueEvents |
| **Events** | GenServer + PubSub bridge | Goroutine stream poller | QueueEvents EventEmitter |
| **Dashboard** | LiveDashboard custom page | JSON + Prometheus endpoints | Bull Board + metrics route |
| **Transactions** | `Ecto.Multi` + enqueue step | `sql.Tx` + enqueue after commit | Prisma `$transaction` + enqueue |
| **Scheduling** | GenServer timer | `time.Ticker` goroutine | `upsertJobScheduler` |
| **Testing** | Mox mock + DataCase | testify mock + httptest | vitest mock + `app.inject` |

The key principle: **enqueue fast, process async**. HTTP handlers should never block on job processing. Return a job ID immediately and let clients poll or subscribe for the result.

---

*Previous: [Chapter 33: Telemetry Integration](ch33-telemetry-integration.md) | Next: [Chapter 35: Concurrent Data Structures](ch35-concurrent-data-structures.md)*
