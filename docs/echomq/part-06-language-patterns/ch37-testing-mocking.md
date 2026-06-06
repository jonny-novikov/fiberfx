# Chapter 37. Testing & Mocking EchoMQ

> Testing strategies for reliable job processing across all three runtimes.

## 37.1. Overview

Testing queue-based systems presents unique challenges that differ from testing synchronous
request-response code. Jobs execute asynchronously, depend on Redis state, emit events over
time, and transition through lifecycle states that span multiple processes. Each language
ecosystem provides distinct testing primitives that align with its concurrency model and
package ecosystem.

```
                      TESTING PYRAMID FOR QUEUE SYSTEMS
  ┌──────────────────────────────────────────────────────────────────┐
  │                     End-to-End (E2E)                             │
  │         Full Redis + Worker + Queue + Event listeners            │
  │                    Slowest, highest fidelity                     │
  ├──────────────────────────────────────────────────────────────────┤
  │                   Integration Tests                              │
  │        Real Redis (or testcontainers), real Lua scripts          │
  │                 Validates protocol compliance                    │
  ├──────────────────────────────────────────────────────────────────┤
  │                     Unit Tests                                   │
  │      Mock Redis, isolated processors, pure functions             │
  │                   Fastest, most focused                          │
  └──────────────────────────────────────────────────────────────────┘
```

| Concern | Elixir | Go | Node.js |
|---------|--------|----|---------|
| Test framework | ExUnit | `testing` stdlib | Jest / Vitest |
| Mocking | Mox (behaviour-based) | Interfaces + test doubles | `jest.mock` / `ioredis-mock` |
| Process isolation | BEAM per-test sandbox | Goroutine + unique prefixes | Separate worker instances |
| Async assertions | `assert_receive/2` | Channel + `select` timeout | `waitFor` / polling |
| Redis test instance | `start_supervised!/1` | `miniredis` / testcontainers | `ioredis-mock` / testcontainers |
| Cleanup | Automatic (sandbox) | `t.Cleanup` | `afterEach` / `afterAll` |

---

## 37.2. Unit Testing Processors

Processors are pure functions (or close to it) that take a job and return a result.
Testing them in isolation -- without Redis, without workers -- provides the fastest
feedback loop and catches logic errors early.

<tabs>
<tab title="Elixir">

> **Benefit**: BEAM process isolation means each test gets a clean worker -- no shared mutable state leaks between tests.

```elixir
defmodule Codemoji.GuessProcessorTest do
  use ExUnit.Case, async: true

  alias Codemoji.GuessProcessor

  describe "process/1 with valid guesses" do
    test "correct guess returns exact match counts" do
      job = build_job("validate_guess", %{
        "game_id" => "GAM5rK2mJ9pQ1L",
        "player_id" => "PLR0K48QjihpC4",
        "guess" => "ABCD",
        "room_id" => "ROM8xN3vP7qR4K"
      })

      # Mock the game validation service
      Mox.expect(Codemoji.GamesMock, :validate_guess, fn
        "GAM5rK2mJ9pQ1L", "ABCD" ->
          {:ok, %{correct: true, exact: 4, found: 0}}
      end)

      assert {:ok, result} = GuessProcessor.process(job)
      assert result.correct == true
      assert result.exact == 4
    end

    test "incorrect guess returns partial match counts" do
      job = build_job("validate_guess", %{
        "game_id" => "GAM5rK2mJ9pQ1L",
        "player_id" => "PLR0K48QjihpC4",
        "guess" => "ABXX",
        "room_id" => "ROM8xN3vP7qR4K"
      })

      Mox.expect(Codemoji.GamesMock, :validate_guess, fn
        "GAM5rK2mJ9pQ1L", "ABXX" ->
          {:ok, %{correct: false, exact: 2, found: 0}}
      end)

      assert {:ok, result} = GuessProcessor.process(job)
      assert result.correct == false
      assert result.exact == 2
    end

    test "finished game returns unrecoverable error" do
      job = build_job("validate_guess", %{
        "game_id" => "GAM5rK2mJ9pQ1L",
        "guess" => "ABCD"
      })

      Mox.expect(Codemoji.GamesMock, :validate_guess, fn _, _ ->
        {:error, :game_finished}
      end)

      assert {:error, %EchoMQ.UnrecoverableError{}} =
               GuessProcessor.process(job)
    end
  end

  # Helper: builds a minimal EchoMQ.Job struct for testing
  defp build_job(name, data) do
    %EchoMQ.Job{
      id: "GUS3QR5T7V9W2X",
      name: name,
      data: data,
      queue_name: "guess-processing",
      attempts_made: 0,
      opts: %EchoMQ.JobOptions{attempts: 3}
    }
  end
end
```

</tab>
<tab title="Go">

> **Tradeoff**: No built-in process isolation -- tests sharing Redis must use unique key prefixes or separate databases.

```go
package codemoji_test

import (
    "testing"

    "github.com/fiberfx/echomq-go/pkg/echomq"
)

func TestGuessProcessor_ValidGuess(t *testing.T) {
    tests := []struct {
        name     string
        guess    string
        wantExact int
        wantFound int
        wantErr  bool
    }{
        {
            name:      "correct guess returns full match",
            guess:     "ABCD",
            wantExact: 4,
            wantFound: 0,
        },
        {
            name:      "partial match returns found count",
            guess:     "ABXX",
            wantExact: 2,
            wantFound: 0,
        },
        {
            name:      "all wrong returns zero counts",
            guess:     "XXXX",
            wantExact: 0,
            wantFound: 0,
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            job := &echomq.Job{
                ID:        "GUS3QR5T7V9W2X",
                Name:      "validate_guess",
                QueueName: "guess-processing",
                Data: map[string]interface{}{
                    "game_id":   "GAM5rK2mJ9pQ1L",
                    "player_id": "PLR0K48QjihpC4",
                    "guess":     tt.guess,
                    "room_id":   "ROM8xN3vP7qR4K",
                },
                AttemptsMade: 0,
            }

            // Inject mock game validator
            validator := &MockGameValidator{
                Result: GuessResult{
                    Exact: tt.wantExact,
                    Found: tt.wantFound,
                },
            }

            processor := NewGuessProcessor(validator)
            result, err := processor.Process(job)

            if tt.wantErr {
                if err == nil {
                    t.Fatal("expected error, got nil")
                }
                return
            }
            if err != nil {
                t.Fatalf("unexpected error: %v", err)
            }

            res := result.(map[string]interface{})
            if got := res["exact"].(int); got != tt.wantExact {
                t.Errorf("exact = %d, want %d", got, tt.wantExact)
            }
        })
    }
}

func TestGuessProcessor_FinishedGame(t *testing.T) {
    job := &echomq.Job{
        ID:   "GUS3QR5T7V9W2X",
        Name: "validate_guess",
        Data: map[string]interface{}{
            "game_id": "GAM5rK2mJ9pQ1L",
            "guess":   "ABCD",
        },
    }

    validator := &MockGameValidator{
        Err: ErrGameFinished,
    }

    processor := NewGuessProcessor(validator)
    _, err := processor.Process(job)

    var permErr *echomq.PermanentError
    if !errors.As(err, &permErr) {
        t.Fatalf("expected PermanentError, got %T: %v", err, err)
    }
}
```

</tab>
<tab title="Node.js">

> **Benefit**: Jest's mock system allows swapping ioredis with ioredis-mock without changing worker code.

```typescript
import { Job } from 'echomq';
import { processGuess } from './guess-processor';

// Mock the game validation service
jest.mock('./game-service', () => ({
  validateGuess: jest.fn(),
}));

import { validateGuess } from './game-service';
const mockValidate = validateGuess as jest.MockedFunction<
  typeof validateGuess
>;

describe('GuessProcessor', () => {
  const buildJob = (data: Record<string, unknown>): Job =>
    ({
      id: 'GUS3QR5T7V9W2X',
      name: 'validate_guess',
      queueName: 'guess-processing',
      data,
      attemptsMade: 0,
    }) as unknown as Job;

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('returns exact match counts for correct guess', async () => {
    mockValidate.mockResolvedValue({
      correct: true,
      exact: 4,
      found: 0,
    });

    const job = buildJob({
      game_id: 'GAM5rK2mJ9pQ1L',
      player_id: 'PLR0K48QjihpC4',
      guess: 'ABCD',
      room_id: 'ROM8xN3vP7qR4K',
    });

    const result = await processGuess(job);
    expect(result.correct).toBe(true);
    expect(result.exact).toBe(4);
  });

  it('returns partial match counts for wrong guess', async () => {
    mockValidate.mockResolvedValue({
      correct: false,
      exact: 2,
      found: 0,
    });

    const job = buildJob({
      game_id: 'GAM5rK2mJ9pQ1L',
      guess: 'ABXX',
    });

    const result = await processGuess(job);
    expect(result.correct).toBe(false);
    expect(result.exact).toBe(2);
  });

  it('throws UnrecoverableError for finished game', async () => {
    mockValidate.mockRejectedValue(
      new Error('Game already finished')
    );

    const job = buildJob({
      game_id: 'GAM5rK2mJ9pQ1L',
      guess: 'ABCD',
    });

    await expect(processGuess(job)).rejects.toThrow(
      'Game already finished'
    );
  });
});
```

</tab>
</tabs>

---

## 37.3. Mocking Redis Connections

Queue systems depend heavily on Redis. Mocking that dependency lets you test processor
logic, job creation, and queue operations without a running Redis instance. Each language
has a preferred approach that fits its type system and mocking conventions.

<tabs>
<tab title="Elixir">

> **Benefit**: Mox enforces that mocks implement the same behaviour (interface) as the real module -- compile-time safety.

```elixir
# Step 1: Define a behaviour for the Redis connection
defmodule Codemoji.Redis.Behaviour do
  @callback get(key :: String.t()) :: {:ok, term()} | {:error, term()}
  @callback set(key :: String.t(), value :: term(), opts :: keyword()) ::
              :ok | {:error, term()}
  @callback del(key :: String.t()) :: :ok
  @callback eval(script :: String.t(), keys :: [String.t()], args :: [term()]) ::
              {:ok, term()} | {:error, term()}
end

# Step 2: Define the mock in test_helper.exs
Mox.defmock(Codemoji.RedisMock, for: Codemoji.Redis.Behaviour)

# Step 3: Use the mock in tests
defmodule Codemoji.QueueOperationsTest do
  use ExUnit.Case, async: true

  import Mox

  setup :verify_on_exit!

  test "adding a job calls Redis with correct key prefix" do
    Mox.expect(Codemoji.RedisMock, :eval, fn script, keys, args ->
      # Verify the bull: prefix is used (wire compatibility)
      assert hd(keys) =~ "bull:guess-processing:"
      assert is_binary(script)
      {:ok, "GUS3QR5T7V9W2X"}
    end)

    assert {:ok, job_id} =
             Codemoji.Queue.add(
               "guess-processing",
               "validate_guess",
               %{game_id: "GAM5rK2mJ9pQ1L", guess: "ABCD"},
               connection: Codemoji.RedisMock
             )

    assert job_id == "GUS3QR5T7V9W2X"
  end

  test "fetching job state reads from correct hash key" do
    Mox.expect(Codemoji.RedisMock, :get, fn key ->
      assert key == "bull:guess-processing:GUS3QR5T7V9W2X"
      {:ok, Jason.encode!(%{state: "completed", result: %{exact: 4}})}
    end)

    assert {:ok, state} =
             Codemoji.Queue.get_job_state(
               "guess-processing",
               "GUS3QR5T7V9W2X",
               connection: Codemoji.RedisMock
             )

    assert state.state == "completed"
  end
end
```

</tab>
<tab title="Go">

> **Benefit**: `miniredis` provides a real Redis protocol implementation in-process -- no Docker, no ports, sub-millisecond tests.

```go
package codemoji_test

import (
    "context"
    "testing"

    "github.com/alicebob/miniredis/v2"
    "github.com/redis/go-redis/v9"
    "github.com/fiberfx/echomq-go/pkg/echomq"
)

func TestQueueAdd_WritesCorrectKeys(t *testing.T) {
    // miniredis: in-process Redis server (no Docker needed)
    mr := miniredis.RunT(t)

    rdb := redis.NewClient(&redis.Options{
        Addr: mr.Addr(),
    })
    t.Cleanup(func() { rdb.Close() })

    queue := echomq.NewQueue("guess-processing", rdb)
    ctx := context.Background()

    jobID, err := queue.Add(ctx, "validate_guess",
        map[string]interface{}{
            "game_id":   "GAM5rK2mJ9pQ1L",
            "player_id": "PLR0K48QjihpC4",
            "guess":     "ABCD",
        },
        echomq.JobOptions{Attempts: 3},
    )
    if err != nil {
        t.Fatalf("Add failed: %v", err)
    }

    // Verify key prefix uses "bull:" (wire compatibility)
    hashKey := "bull:guess-processing:" + jobID
    if !mr.Exists(hashKey) {
        t.Errorf("expected key %s to exist", hashKey)
    }

    // Verify job data stored correctly
    data, err := mr.HGet(hashKey, "data")
    if err != nil {
        t.Fatalf("HGet failed: %v", err)
    }
    if data == "" {
        t.Error("job data is empty")
    }
}

func TestQueueAdd_SetsCorrectState(t *testing.T) {
    mr := miniredis.RunT(t)
    rdb := redis.NewClient(&redis.Options{Addr: mr.Addr()})
    t.Cleanup(func() { rdb.Close() })

    queue := echomq.NewQueue("prizes", rdb)

    _, err := queue.Add(context.Background(), "distribute_prize",
        map[string]interface{}{
            "player_id": "PLR0K48QjihpC4",
            "rank":      1,
            "diamonds":  100,
        },
        echomq.JobOptions{},
    )
    if err != nil {
        t.Fatalf("Add failed: %v", err)
    }

    // Verify job appears in the waiting list
    members, err := mr.ZMembers("bull:prizes:wait")
    if err != nil {
        t.Fatalf("ZMembers failed: %v", err)
    }
    if len(members) != 1 {
        t.Errorf("expected 1 waiting job, got %d", len(members))
    }
}
```

</tab>
<tab title="Node.js">

> **Tradeoff**: `ioredis-mock` does not support Lua scripts -- integration tests with real Redis are needed for Lua-dependent operations.

```typescript
import Redis from 'ioredis-mock';
import { Queue, Job } from 'echomq';

describe('Queue Operations with Mocked Redis', () => {
  let redis: Redis;
  let queue: Queue;

  beforeEach(() => {
    redis = new Redis();
    queue = new Queue('guess-processing', {
      connection: redis as any,
    });
  });

  afterEach(async () => {
    await queue.close();
  });

  it('adds a job with correct data', async () => {
    const job = await queue.add('validate_guess', {
      game_id: 'GAM5rK2mJ9pQ1L',
      player_id: 'PLR0K48QjihpC4',
      guess: 'ABCD',
      room_id: 'ROM8xN3vP7qR4K',
    });

    expect(job.id).toBeDefined();
    expect(job.name).toBe('validate_guess');
    expect(job.data.game_id).toBe('GAM5rK2mJ9pQ1L');
  });

  it('stores job with bull: key prefix', async () => {
    const job = await queue.add('validate_guess', {
      game_id: 'GAM5rK2mJ9pQ1L',
      guess: 'ABCD',
    });

    // Verify wire-compatible key prefix
    const keys = await redis.keys('bull:guess-processing:*');
    expect(keys.length).toBeGreaterThan(0);
    expect(keys.some((k) => k.includes(job.id!))).toBe(true);
  });

  it('sets correct default attempts', async () => {
    const job = await queue.add(
      'distribute_prize',
      {
        player_id: 'PLR0K48QjihpC4',
        rank: 1,
        diamonds: 100,
      },
      { attempts: 5 },
    );

    expect(job.opts.attempts).toBe(5);
  });
});
```

</tab>
</tabs>

---

## 37.4. Integration Testing with Real Redis

Integration tests exercise the full queue path: enqueue, Lua script execution, worker
pickup, processor invocation, and state transition. These tests require a running Redis
instance but validate that your code works with the actual EchoMQ protocol.

<tabs>
<tab title="Elixir">

> **Benefit**: `start_supervised!/1` ties worker lifecycle to the test process -- automatic cleanup on test exit.

```elixir
defmodule Codemoji.GuessIntegrationTest do
  use ExUnit.Case

  # Not async: true -- integration tests share a Redis instance
  @moduletag :integration

  setup do
    # Clean up test keys before each test
    {:ok, conn} = Redix.start_link("redis://localhost:6379/15")
    Redix.command!(conn, ["FLUSHDB"])

    on_exit(fn ->
      Redix.command!(conn, ["FLUSHDB"])
      GenServer.stop(conn)
    end)

    {:ok, conn: conn}
  end

  test "guess job completes full lifecycle", %{conn: conn} do
    # Start a worker that processes guesses
    {:ok, worker} = start_supervised!(
      {EchoMQ.Worker,
        queue: "guess-processing",
        connection: conn,
        processor: &Codemoji.GuessProcessor.process/1,
        concurrency: 1}
    )

    # Enqueue a guess validation job
    {:ok, job_id} = EchoMQ.Queue.add(
      "guess-processing",
      "validate_guess",
      %{
        "game_id" => "GAM5rK2mJ9pQ1L",
        "player_id" => "PLR0K48QjihpC4",
        "guess" => "ABCD"
      },
      connection: conn,
      attempts: 3
    )

    # Wait for job completion (up to 5 seconds)
    assert_receive {:job_completed, ^job_id, result}, 5_000

    assert result.exact >= 0
    assert result.found >= 0

    # Verify job state in Redis
    {:ok, state} = EchoMQ.Queue.get_job_state(
      "guess-processing", job_id,
      connection: conn
    )
    assert state == "completed"
  end

  test "failed guess retries up to max attempts", %{conn: conn} do
    # Processor that always fails
    failing_processor = fn _job ->
      {:error, "Redis timeout simulation"}
    end

    {:ok, _worker} = start_supervised!(
      {EchoMQ.Worker,
        queue: "guess-retry-test",
        connection: conn,
        processor: failing_processor,
        concurrency: 1}
    )

    {:ok, job_id} = EchoMQ.Queue.add(
      "guess-retry-test",
      "validate_guess",
      %{"game_id" => "GAM5rK2mJ9pQ1L", "guess" => "XXXX"},
      connection: conn,
      attempts: 3,
      backoff: %{type: :fixed, delay: 100}
    )

    # Wait for final failure after all attempts
    assert_receive {:job_failed, ^job_id, _reason}, 10_000

    # Verify all 3 attempts were made
    {:ok, attempts} = EchoMQ.Queue.get_job_attempts(
      "guess-retry-test", job_id,
      connection: conn
    )
    assert attempts == 3
  end
end
```

</tab>
<tab title="Go">

> **Benefit**: `testcontainers-go` spins up real Redis in Docker -- production-identical protocol, fully isolated per test suite.

```go
package codemoji_test

import (
    "context"
    "testing"
    "time"

    "github.com/redis/go-redis/v9"
    "github.com/testcontainers/testcontainers-go"
    tcredis "github.com/testcontainers/testcontainers-go/modules/redis"
    "github.com/fiberfx/echomq-go/pkg/echomq"
)

func setupRedis(t *testing.T) *redis.Client {
    t.Helper()
    ctx := context.Background()

    container, err := tcredis.Run(ctx, "redis:7-alpine")
    if err != nil {
        t.Fatalf("failed to start Redis container: %v", err)
    }

    t.Cleanup(func() {
        testcontainers.CleanupContainer(t, container)
    })

    connStr, err := container.ConnectionString(ctx)
    if err != nil {
        t.Fatalf("failed to get connection string: %v", err)
    }

    opts, _ := redis.ParseURL(connStr)
    rdb := redis.NewClient(opts)

    t.Cleanup(func() { rdb.Close() })

    return rdb
}

func TestGuessJob_FullLifecycle(t *testing.T) {
    if testing.Short() {
        t.Skip("skipping integration test in short mode")
    }

    rdb := setupRedis(t)
    ctx := context.Background()

    // Create queue and add a job
    queue := echomq.NewQueue("guess-processing", rdb)
    jobID, err := queue.Add(ctx, "validate_guess",
        map[string]interface{}{
            "game_id":   "GAM5rK2mJ9pQ1L",
            "player_id": "PLR0K48QjihpC4",
            "guess":     "ABCD",
            "room_id":   "ROM8xN3vP7qR4K",
        },
        echomq.JobOptions{Attempts: 3},
    )
    if err != nil {
        t.Fatalf("Add failed: %v", err)
    }

    // Start worker with test processor
    completed := make(chan string, 1)
    worker := echomq.NewWorker("guess-processing", rdb,
        func(job *echomq.Job) (interface{}, error) {
            result := map[string]interface{}{
                "exact": 4,
                "found": 0,
            }
            completed <- job.ID
            return result, nil
        },
        echomq.WorkerOptions{Concurrency: 1},
    )

    go worker.Run(ctx)
    t.Cleanup(func() { worker.Close() })

    // Wait for completion
    select {
    case id := <-completed:
        if id != jobID {
            t.Errorf("completed job %s, want %s", id, jobID)
        }
    case <-time.After(10 * time.Second):
        t.Fatal("timeout waiting for job completion")
    }

    // Verify final state
    state, err := queue.GetJobState(ctx, jobID)
    if err != nil {
        t.Fatalf("GetJobState failed: %v", err)
    }
    if state != "completed" {
        t.Errorf("state = %q, want completed", state)
    }
}
```

</tab>
<tab title="Node.js">

> **Tradeoff**: Real Redis tests require cleanup discipline -- forgotten keys from crashed tests pollute subsequent runs.

```typescript
import { Queue, Worker, Job, QueueEvents } from 'echomq';
import Redis from 'ioredis';

describe('Guess Processing Integration', () => {
  let redis: Redis;
  let queue: Queue;
  let worker: Worker;
  let queueEvents: QueueEvents;

  beforeAll(() => {
    redis = new Redis({ db: 15 }); // Dedicated test database
  });

  beforeEach(async () => {
    await redis.flushdb();
    queue = new Queue('guess-processing', {
      connection: { host: 'localhost', port: 6379, db: 15 },
    });
    queueEvents = new QueueEvents('guess-processing', {
      connection: { host: 'localhost', port: 6379, db: 15 },
    });
  });

  afterEach(async () => {
    if (worker) await worker.close();
    await queueEvents.close();
    await queue.close();
  });

  afterAll(async () => {
    await redis.flushdb();
    await redis.quit();
  });

  it('processes a guess job end-to-end', async () => {
    // Start worker
    worker = new Worker(
      'guess-processing',
      async (job: Job) => {
        const { game_id, guess } = job.data;
        return { exact: 4, found: 0, correct: true };
      },
      {
        connection: { host: 'localhost', port: 6379, db: 15 },
        concurrency: 1,
      },
    );

    // Add job
    const job = await queue.add('validate_guess', {
      game_id: 'GAM5rK2mJ9pQ1L',
      player_id: 'PLR0K48QjihpC4',
      guess: 'ABCD',
      room_id: 'ROM8xN3vP7qR4K',
    });

    // Wait for completion
    const completedJob = await job.waitUntilFinished(queueEvents, 10000);
    expect(completedJob.exact).toBe(4);
    expect(completedJob.correct).toBe(true);

    // Verify state
    const state = await job.getState();
    expect(state).toBe('completed');
  });

  it('retries failed jobs up to max attempts', async () => {
    let attemptCount = 0;

    worker = new Worker(
      'guess-processing',
      async (job: Job) => {
        attemptCount++;
        throw new Error('Simulated Redis timeout');
      },
      {
        connection: { host: 'localhost', port: 6379, db: 15 },
        concurrency: 1,
      },
    );

    await queue.add(
      'validate_guess',
      { game_id: 'GAM5rK2mJ9pQ1L', guess: 'XXXX' },
      { attempts: 3, backoff: { type: 'fixed', delay: 100 } },
    );

    // Wait for all retries to exhaust
    await new Promise((resolve) => setTimeout(resolve, 5000));
    expect(attemptCount).toBe(3);
  });
});
```

</tab>
</tabs>

---

## 37.5. Testing Job Lifecycle States

Jobs transition through a well-defined state machine: `waiting` -> `active` -> `completed`
(or `failed`), with possible detours through `delayed` and `waiting-children`. Testing these
transitions verifies that your queue configuration and processor logic produce the expected
state flow.

<tabs>
<tab title="Elixir">

> **Benefit**: Pattern-matching on state atoms makes state transition assertions read like a specification.

```elixir
defmodule Codemoji.JobLifecycleTest do
  use ExUnit.Case

  @moduletag :integration

  setup do
    {:ok, conn} = Redix.start_link("redis://localhost:6379/15")
    Redix.command!(conn, ["FLUSHDB"])
    on_exit(fn -> Redix.command!(conn, ["FLUSHDB"]); GenServer.stop(conn) end)
    {:ok, conn: conn}
  end

  test "game room job transitions through full lifecycle", %{conn: conn} do
    # Add job -- should be in :waiting state
    {:ok, job_id} = EchoMQ.Queue.add(
      "game-rooms",
      "create_room",
      %{"room_id" => "ROM8xN3vP7qR4K", "host" => "PLR0K48QjihpC4"},
      connection: conn
    )

    assert {:ok, :waiting} =
             EchoMQ.Queue.get_job_state("game-rooms", job_id, connection: conn)

    # Start worker -- job moves to :active, then :completed
    {:ok, worker} = start_supervised!(
      {EchoMQ.Worker,
        queue: "game-rooms",
        connection: conn,
        processor: fn _job -> {:ok, %{status: "created"}} end,
        concurrency: 1}
    )

    # Wait for completion
    assert_receive {:job_completed, ^job_id, _result}, 5_000

    assert {:ok, :completed} =
             EchoMQ.Queue.get_job_state("game-rooms", job_id, connection: conn)
  end

  test "delayed job stays in :delayed until delay expires", %{conn: conn} do
    {:ok, job_id} = EchoMQ.Queue.add(
      "notifications",
      "send_telegram",
      %{"player_id" => "PLR0K48QjihpC4", "message" => "You won!"},
      connection: conn,
      delay: 2_000
    )

    # Immediately after add: should be delayed
    assert {:ok, :delayed} =
             EchoMQ.Queue.get_job_state("notifications", job_id, connection: conn)

    # After delay: should transition to waiting
    Process.sleep(2_500)

    assert {:ok, :waiting} =
             EchoMQ.Queue.get_job_state("notifications", job_id, connection: conn)
  end

  test "failed job shows :failed state with error details", %{conn: conn} do
    {:ok, _worker} = start_supervised!(
      {EchoMQ.Worker,
        queue: "failing-queue",
        connection: conn,
        processor: fn _job ->
          {:error, EchoMQ.UnrecoverableError.new("Permanent failure")}
        end,
        concurrency: 1}
    )

    {:ok, job_id} = EchoMQ.Queue.add(
      "failing-queue",
      "doomed_task",
      %{},
      connection: conn,
      attempts: 1
    )

    assert_receive {:job_failed, ^job_id, _reason}, 5_000

    assert {:ok, :failed} =
             EchoMQ.Queue.get_job_state("failing-queue", job_id, connection: conn)
  end
end
```

</tab>
<tab title="Go">

> **Tradeoff**: State assertions require polling with timeouts -- Go has no built-in `assert_receive` equivalent.

```go
package codemoji_test

import (
    "context"
    "fmt"
    "testing"
    "time"

    "github.com/alicebob/miniredis/v2"
    "github.com/redis/go-redis/v9"
    "github.com/fiberfx/echomq-go/pkg/echomq"
)

func TestJobLifecycle_WaitingToCompleted(t *testing.T) {
    mr := miniredis.RunT(t)
    rdb := redis.NewClient(&redis.Options{Addr: mr.Addr()})
    t.Cleanup(func() { rdb.Close() })

    ctx := context.Background()
    queue := echomq.NewQueue("game-rooms", rdb)

    // Add job -- should be waiting
    jobID, err := queue.Add(ctx, "create_room",
        map[string]interface{}{
            "room_id": "ROM8xN3vP7qR4K",
            "host":    "PLR0K48QjihpC4",
        },
        echomq.JobOptions{},
    )
    if err != nil {
        t.Fatalf("Add failed: %v", err)
    }

    state, _ := queue.GetJobState(ctx, jobID)
    if state != "waiting" {
        t.Errorf("initial state = %q, want waiting", state)
    }

    // Start worker
    completed := make(chan struct{}, 1)
    worker := echomq.NewWorker("game-rooms", rdb,
        func(job *echomq.Job) (interface{}, error) {
            completed <- struct{}{}
            return map[string]interface{}{"status": "created"}, nil
        },
        echomq.WorkerOptions{Concurrency: 1},
    )
    go worker.Run(ctx)
    t.Cleanup(func() { worker.Close() })

    select {
    case <-completed:
    case <-time.After(5 * time.Second):
        t.Fatal("timeout waiting for job completion")
    }

    // Verify completed state
    state, _ = queue.GetJobState(ctx, jobID)
    if state != "completed" {
        t.Errorf("final state = %q, want completed", state)
    }
}

func TestJobLifecycle_FailedState(t *testing.T) {
    mr := miniredis.RunT(t)
    rdb := redis.NewClient(&redis.Options{Addr: mr.Addr()})
    t.Cleanup(func() { rdb.Close() })

    ctx := context.Background()
    queue := echomq.NewQueue("failing-queue", rdb)

    failed := make(chan struct{}, 1)
    worker := echomq.NewWorker("failing-queue", rdb,
        func(job *echomq.Job) (interface{}, error) {
            failed <- struct{}{}
            return nil, &echomq.PermanentError{
                Err: fmt.Errorf("permanent failure"),
                Msg: "doomed",
            }
        },
        echomq.WorkerOptions{Concurrency: 1},
    )
    go worker.Run(ctx)
    t.Cleanup(func() { worker.Close() })

    jobID, _ := queue.Add(ctx, "doomed_task",
        map[string]interface{}{},
        echomq.JobOptions{Attempts: 1},
    )

    select {
    case <-failed:
    case <-time.After(5 * time.Second):
        t.Fatal("timeout waiting for failure")
    }

    // Allow worker to update state
    time.Sleep(200 * time.Millisecond)

    state, _ := queue.GetJobState(ctx, jobID)
    if state != "failed" {
        t.Errorf("state = %q, want failed", state)
    }
}
```

</tab>
<tab title="Node.js">

> **Benefit**: `QueueEvents` provides promise-based `waitUntilFinished` -- no manual polling needed.

```typescript
import { Queue, Worker, QueueEvents, Job } from 'echomq';

describe('Job Lifecycle States', () => {
  let queue: Queue;
  let worker: Worker;
  let queueEvents: QueueEvents;
  const connOpts = { host: 'localhost', port: 6379, db: 15 };

  beforeEach(async () => {
    const Redis = (await import('ioredis')).default;
    const redis = new Redis({ ...connOpts });
    await redis.flushdb();
    await redis.quit();

    queue = new Queue('game-rooms', { connection: connOpts });
    queueEvents = new QueueEvents('game-rooms', {
      connection: connOpts,
    });
  });

  afterEach(async () => {
    if (worker) await worker.close();
    await queueEvents.close();
    await queue.close();
  });

  it('transitions waiting -> active -> completed', async () => {
    // Add job -- starts as waiting
    const job = await queue.add('create_room', {
      room_id: 'ROM8xN3vP7qR4K',
      host: 'PLR0K48QjihpC4',
    });

    expect(await job.getState()).toBe('waiting');

    // Start worker
    worker = new Worker(
      'game-rooms',
      async () => ({ status: 'created' }),
      { connection: connOpts, concurrency: 1 },
    );

    await job.waitUntilFinished(queueEvents, 5000);
    expect(await job.getState()).toBe('completed');
  });

  it('delayed job stays delayed until timeout', async () => {
    const job = await queue.add(
      'send_telegram',
      {
        player_id: 'PLR0K48QjihpC4',
        message: 'You won!',
      },
      { delay: 2000 },
    );

    expect(await job.getState()).toBe('delayed');

    // Wait for delay to expire
    await new Promise((r) => setTimeout(r, 2500));
    expect(await job.getState()).toBe('waiting');
  });

  it('permanently failed job shows failed state', async () => {
    worker = new Worker(
      'game-rooms',
      async () => {
        throw new Error('Permanent failure');
      },
      { connection: connOpts, concurrency: 1 },
    );

    const job = await queue.add(
      'doomed_task',
      {},
      { attempts: 1 },
    );

    // Wait for failure
    await new Promise((resolve) => {
      worker.on('failed', () => resolve(undefined));
    });

    expect(await job.getState()).toBe('failed');
  });
});
```

</tab>
</tabs>

---

## 37.6. Flow Testing Strategies

EchoMQ flows compose multiple jobs into directed acyclic graphs. Testing flows requires
verifying that parent-child relationships form correctly, that child jobs spawn at the
right time, and that the parent completes only after all children finish.

<tabs>
<tab title="Elixir">

> **Benefit**: `assert_receive` with pattern matching captures the exact child job sequence without polling.

```elixir
defmodule Codemoji.PrizeFlowTest do
  use ExUnit.Case

  @moduletag :integration

  setup do
    {:ok, conn} = Redix.start_link("redis://localhost:6379/15")
    Redix.command!(conn, ["FLUSHDB"])
    on_exit(fn -> Redix.command!(conn, ["FLUSHDB"]); GenServer.stop(conn) end)
    {:ok, conn: conn}
  end

  test "prize flow spawns child jobs for each winner", %{conn: conn} do
    # Parent processor: creates child jobs for each winner
    parent_processor = fn job ->
      winners = job.data["winners"]

      children =
        Enum.map(winners, fn winner ->
          %{
            name: "distribute_prize",
            data: %{
              "player_id" => winner["player_id"],
              "diamonds" => winner["diamonds"],
              "rank" => winner["rank"]
            },
            opts: %{attempts: 3}
          }
        end)

      {:ok, %{children: children}}
    end

    child_processor = fn job ->
      {:ok, %{
        player_id: job.data["player_id"],
        awarded: job.data["diamonds"]
      }}
    end

    # Start workers for both queues
    {:ok, _parent_worker} = start_supervised!(
      {EchoMQ.Worker,
        queue: "prize-flow",
        connection: conn,
        processor: parent_processor,
        concurrency: 1},
      id: :parent_worker
    )

    {:ok, _child_worker} = start_supervised!(
      {EchoMQ.Worker,
        queue: "prize-distribution",
        connection: conn,
        processor: child_processor,
        concurrency: 3},
      id: :child_worker
    )

    # Add parent job with 3 winners
    {:ok, parent_id} = EchoMQ.Queue.add(
      "prize-flow",
      "award_prizes",
      %{
        "game_id" => "GAM5rK2mJ9pQ1L",
        "winners" => [
          %{"player_id" => "PLR0K48QjihpC4", "rank" => 1, "diamonds" => 100},
          %{"player_id" => "PLR7FXC4K8M9N2P", "rank" => 2, "diamonds" => 50},
          %{"player_id" => "PLR9AB3D5F7G8HJ", "rank" => 3, "diamonds" => 25}
        ]
      },
      connection: conn
    )

    # Wait for all children to complete
    assert_receive {:job_completed, ^parent_id, _result}, 10_000

    # Verify parent state
    assert {:ok, :completed} =
             EchoMQ.Queue.get_job_state("prize-flow", parent_id, connection: conn)
  end
end
```

</tab>
<tab title="Go">

> **Tradeoff**: Flow testing requires coordinating multiple workers and channels -- more boilerplate than single-job tests.

```go
package codemoji_test

import (
    "context"
    "sync"
    "testing"
    "time"

    "github.com/alicebob/miniredis/v2"
    "github.com/redis/go-redis/v9"
    "github.com/fiberfx/echomq-go/pkg/echomq"
)

func TestPrizeFlow_SpawnsChildJobs(t *testing.T) {
    mr := miniredis.RunT(t)
    rdb := redis.NewClient(&redis.Options{Addr: mr.Addr()})
    t.Cleanup(func() { rdb.Close() })

    ctx := context.Background()

    // Track child job completions
    var mu sync.Mutex
    childResults := make([]string, 0, 3)
    childDone := make(chan struct{})

    // Parent worker: creates child jobs
    parentWorker := echomq.NewWorker("prize-flow", rdb,
        func(job *echomq.Job) (interface{}, error) {
            winners, _ := job.Data["winners"].([]interface{})
            childQueue := echomq.NewQueue("prize-distribution", rdb)

            for _, w := range winners {
                winner := w.(map[string]interface{})
                childQueue.Add(ctx, "distribute_prize",
                    winner,
                    echomq.JobOptions{
                        Attempts: 3,
                        Parent: &echomq.ParentOpts{
                            ID:    job.ID,
                            Queue: "prize-flow",
                        },
                    },
                )
            }
            return map[string]interface{}{"children": len(winners)}, nil
        },
        echomq.WorkerOptions{Concurrency: 1},
    )

    // Child worker: processes individual prizes
    childWorker := echomq.NewWorker("prize-distribution", rdb,
        func(job *echomq.Job) (interface{}, error) {
            playerID, _ := job.Data["player_id"].(string)

            mu.Lock()
            childResults = append(childResults, playerID)
            if len(childResults) == 3 {
                close(childDone)
            }
            mu.Unlock()

            return map[string]interface{}{"awarded": true}, nil
        },
        echomq.WorkerOptions{Concurrency: 3},
    )

    go parentWorker.Run(ctx)
    go childWorker.Run(ctx)
    t.Cleanup(func() {
        parentWorker.Close()
        childWorker.Close()
    })

    // Add parent job
    queue := echomq.NewQueue("prize-flow", rdb)
    queue.Add(ctx, "award_prizes",
        map[string]interface{}{
            "game_id": "GAM5rK2mJ9pQ1L",
            "winners": []interface{}{
                map[string]interface{}{
                    "player_id": "PLR0K48QjihpC4",
                    "rank":      1, "diamonds": 100,
                },
                map[string]interface{}{
                    "player_id": "PLR7FXC4K8M9N2P",
                    "rank":      2, "diamonds": 50,
                },
                map[string]interface{}{
                    "player_id": "PLR9AB3D5F7G8HJ",
                    "rank":      3, "diamonds": 25,
                },
            },
        },
        echomq.JobOptions{},
    )

    select {
    case <-childDone:
        mu.Lock()
        if len(childResults) != 3 {
            t.Errorf("expected 3 children, got %d", len(childResults))
        }
        mu.Unlock()
    case <-time.After(10 * time.Second):
        t.Fatal("timeout waiting for child jobs")
    }
}
```

</tab>
<tab title="Node.js">

> **Benefit**: `FlowProducer` API creates the entire DAG atomically -- parent and all children in a single Redis transaction.

```typescript
import {
  Queue,
  Worker,
  FlowProducer,
  QueueEvents,
} from 'echomq';

describe('Prize Distribution Flow', () => {
  const connOpts = { host: 'localhost', port: 6379, db: 15 };
  let parentWorker: Worker;
  let childWorker: Worker;
  let flowProducer: FlowProducer;
  let queueEvents: QueueEvents;

  beforeEach(async () => {
    const Redis = (await import('ioredis')).default;
    await new Redis(connOpts).flushdb();

    flowProducer = new FlowProducer({ connection: connOpts });
    queueEvents = new QueueEvents('prize-flow', {
      connection: connOpts,
    });
  });

  afterEach(async () => {
    if (parentWorker) await parentWorker.close();
    if (childWorker) await childWorker.close();
    await flowProducer.close();
    await queueEvents.close();
  });

  it('parent completes after all children finish', async () => {
    const childCompletions: string[] = [];

    childWorker = new Worker(
      'prize-distribution',
      async (job) => {
        childCompletions.push(job.data.player_id);
        return { awarded: job.data.diamonds };
      },
      { connection: connOpts, concurrency: 3 },
    );

    parentWorker = new Worker(
      'prize-flow',
      async (job) => ({
        game_id: job.data.game_id,
        total_awarded: true,
      }),
      { connection: connOpts, concurrency: 1 },
    );

    // Create entire flow atomically
    const flow = await flowProducer.add({
      name: 'award_prizes',
      queueName: 'prize-flow',
      data: { game_id: 'GAM5rK2mJ9pQ1L' },
      children: [
        {
          name: 'distribute_prize',
          queueName: 'prize-distribution',
          data: { player_id: 'PLR0K48QjihpC4', rank: 1, diamonds: 100 },
        },
        {
          name: 'distribute_prize',
          queueName: 'prize-distribution',
          data: { player_id: 'PLR7FXC4K8M9N2P', rank: 2, diamonds: 50 },
        },
        {
          name: 'distribute_prize',
          queueName: 'prize-distribution',
          data: { player_id: 'PLR9AB3D5F7G8HJ', rank: 3, diamonds: 25 },
        },
      ],
    });

    // Wait for parent to complete (after all children)
    const result = await flow.job.waitUntilFinished(
      queueEvents,
      15000,
    );

    expect(result.total_awarded).toBe(true);
    expect(childCompletions).toHaveLength(3);
    expect(childCompletions).toContain('PLR0K48QjihpC4');
  });
});
```

</tab>
</tabs>

---

## 37.7. Event Testing Patterns

EchoMQ emits events at every lifecycle transition: `completed`, `failed`, `progress`,
`stalled`, `waiting`, and more. Testing event handlers ensures your monitoring,
alerting, and side-effect logic fires correctly.

<tabs>
<tab title="Elixir">

> **Benefit**: `:telemetry` events are synchronous within the emitting process -- no race conditions in test assertions.

```elixir
defmodule Codemoji.EventHandlerTest do
  use ExUnit.Case, async: true

  test "telemetry event fires on job completion" do
    test_pid = self()

    # Attach a test handler that sends a message
    :telemetry.attach(
      "test-completion-handler",
      [:echomq, :job, :complete],
      fn _event, measurements, metadata, _config ->
        send(test_pid, {:telemetry_event, measurements, metadata})
      end,
      nil
    )

    on_exit(fn ->
      :telemetry.detach("test-completion-handler")
    end)

    # Simulate the event that EchoMQ would emit
    :telemetry.execute(
      [:echomq, :job, :complete],
      %{duration: 150_000_000},
      %{
        job_id: "GUS3QR5T7V9W2X",
        queue: "guess-processing",
        job_name: "validate_guess"
      }
    )

    assert_receive {:telemetry_event, measurements, metadata}
    assert measurements.duration == 150_000_000
    assert metadata.queue == "guess-processing"
    assert metadata.job_id == "GUS3QR5T7V9W2X"
  end

  test "stalled event fires when job lock expires" do
    test_pid = self()

    :telemetry.attach(
      "test-stalled-handler",
      [:echomq, :job, :stalled],
      fn _event, _measurements, metadata, _config ->
        send(test_pid, {:stalled, metadata.job_id})
      end,
      nil
    )

    on_exit(fn ->
      :telemetry.detach("test-stalled-handler")
    end)

    :telemetry.execute(
      [:echomq, :job, :stalled],
      %{},
      %{job_id: "GUS3QR5T7V9W2X", queue: "guess-processing"}
    )

    assert_receive {:stalled, "GUS3QR5T7V9W2X"}
  end
end
```

</tab>
<tab title="Go">

> **Benefit**: Channel-based event listeners integrate naturally with Go's `select` + timeout pattern for test assertions.

```go
package codemoji_test

import (
    "testing"
    "time"

    "github.com/fiberfx/echomq-go/pkg/echomq"
)

func TestEventHandler_CompletionFires(t *testing.T) {
    events := make(chan echomq.JobEvent, 10)

    // Register event listener
    listener := &echomq.EventListener{
        OnCompleted: func(event echomq.JobEvent) {
            events <- event
        },
    }

    // Simulate worker emitting a completion event
    listener.OnCompleted(echomq.JobEvent{
        JobID:     "GUS3QR5T7V9W2X",
        QueueName: "guess-processing",
        JobName:   "validate_guess",
        Duration:  150 * time.Millisecond,
    })

    select {
    case event := <-events:
        if event.JobID != "GUS3QR5T7V9W2X" {
            t.Errorf("job ID = %q, want GUS3QR5T7V9W2X", event.JobID)
        }
        if event.QueueName != "guess-processing" {
            t.Errorf("queue = %q, want guess-processing", event.QueueName)
        }
    case <-time.After(time.Second):
        t.Fatal("timeout waiting for completion event")
    }
}

func TestEventHandler_StalledDetection(t *testing.T) {
    stalledJobs := make(chan string, 10)

    listener := &echomq.EventListener{
        OnStalled: func(event echomq.JobEvent) {
            stalledJobs <- event.JobID
        },
    }

    listener.OnStalled(echomq.JobEvent{
        JobID:     "GUS3QR5T7V9W2X",
        QueueName: "guess-processing",
    })

    select {
    case jobID := <-stalledJobs:
        if jobID != "GUS3QR5T7V9W2X" {
            t.Errorf("stalled job = %q, want GUS3QR5T7V9W2X", jobID)
        }
    case <-time.After(time.Second):
        t.Fatal("timeout waiting for stalled event")
    }
}

func TestEventHandler_ProgressUpdates(t *testing.T) {
    progressUpdates := make(chan int, 10)

    listener := &echomq.EventListener{
        OnProgress: func(event echomq.JobEvent) {
            progressUpdates <- event.Progress
        },
    }

    // Simulate progress events from a leaderboard calculation
    for _, pct := range []int{25, 50, 75, 100} {
        listener.OnProgress(echomq.JobEvent{
            JobID:    "GUS3QR5T7V9W2X",
            Progress: pct,
        })
    }

    for _, expected := range []int{25, 50, 75, 100} {
        select {
        case got := <-progressUpdates:
            if got != expected {
                t.Errorf("progress = %d, want %d", got, expected)
            }
        case <-time.After(time.Second):
            t.Fatalf("timeout waiting for progress %d", expected)
        }
    }
}
```

</tab>
<tab title="Node.js">

> **Benefit**: EventEmitter `once` combined with `Promise` wrapping makes one-shot event assertions clean and readable.

```typescript
import { Worker, Queue, QueueEvents, Job } from 'echomq';

describe('Event Testing', () => {
  const connOpts = { host: 'localhost', port: 6379, db: 15 };
  let queue: Queue;
  let worker: Worker;
  let queueEvents: QueueEvents;

  beforeEach(async () => {
    const Redis = (await import('ioredis')).default;
    await new Redis(connOpts).flushdb();

    queue = new Queue('guess-processing', { connection: connOpts });
    queueEvents = new QueueEvents('guess-processing', {
      connection: connOpts,
    });
  });

  afterEach(async () => {
    if (worker) await worker.close();
    await queueEvents.close();
    await queue.close();
  });

  it('emits completed event with result', async () => {
    worker = new Worker(
      'guess-processing',
      async (job: Job) => ({ exact: 4, found: 0 }),
      { connection: connOpts, concurrency: 1 },
    );

    // Promise-wrapped event listener
    const completedPromise = new Promise<{
      jobId: string;
      returnvalue: string;
    }>((resolve) => {
      queueEvents.on('completed', (event) => {
        resolve(event);
      });
    });

    await queue.add('validate_guess', {
      game_id: 'GAM5rK2mJ9pQ1L',
      guess: 'ABCD',
    });

    const event = await completedPromise;
    expect(event.jobId).toBeDefined();
    expect(JSON.parse(event.returnvalue).exact).toBe(4);
  });

  it('emits failed event with error details', async () => {
    worker = new Worker(
      'guess-processing',
      async () => {
        throw new Error('Game server unreachable');
      },
      { connection: connOpts, concurrency: 1 },
    );

    const failedPromise = new Promise<{
      jobId: string;
      failedReason: string;
    }>((resolve) => {
      queueEvents.on('failed', (event) => {
        resolve(event);
      });
    });

    await queue.add(
      'validate_guess',
      { game_id: 'GAM5rK2mJ9pQ1L' },
      { attempts: 1 },
    );

    const event = await failedPromise;
    expect(event.failedReason).toContain('Game server unreachable');
  });

  it('emits progress events during processing', async () => {
    const progressValues: number[] = [];

    worker = new Worker(
      'guess-processing',
      async (job: Job) => {
        for (const pct of [25, 50, 75, 100]) {
          await job.updateProgress(pct);
        }
        return { done: true };
      },
      { connection: connOpts, concurrency: 1 },
    );

    queueEvents.on('progress', (event) => {
      progressValues.push(event.data as number);
    });

    const job = await queue.add('calculate_leaderboard', {
      game_id: 'GAM5rK2mJ9pQ1L',
    });

    await job.waitUntilFinished(queueEvents, 5000);

    // Allow events to propagate
    await new Promise((r) => setTimeout(r, 500));
    expect(progressValues).toEqual(
      expect.arrayContaining([25, 50, 75, 100]),
    );
  });
});
```

</tab>
</tabs>

---

## 37.8. Test Helpers and Utilities

Repeated setup/teardown patterns benefit from shared helpers. Each language ecosystem
has idiomatic approaches to building reusable test infrastructure for queue systems.

<tabs>
<tab title="Elixir">

> **Benefit**: ExUnit `setup` callbacks and module attributes compose cleanly -- helpers are just functions on imported modules.

```elixir
defmodule Codemoji.QueueTestHelpers do
  @moduledoc """
  Shared test helpers for EchoMQ queue testing.
  Import in test modules: `import Codemoji.QueueTestHelpers`
  """

  alias EchoMQ.{Job, JobOptions}

  @doc "Builds a minimal Job struct for unit testing."
  def build_job(name, data, opts \\ []) do
    %Job{
      id: Keyword.get(opts, :id, generate_test_id()),
      name: name,
      data: data,
      queue_name: Keyword.get(opts, :queue, "test-queue"),
      attempts_made: Keyword.get(opts, :attempts_made, 0),
      opts: %JobOptions{
        attempts: Keyword.get(opts, :attempts, 3),
        delay: Keyword.get(opts, :delay, 0)
      }
    }
  end

  @doc "Builds a guess validation job with codemoji domain data."
  def build_guess_job(game_id \\ "GAM5rK2mJ9pQ1L", guess \\ "ABCD") do
    build_job("validate_guess", %{
      "game_id" => game_id,
      "player_id" => "PLR0K48QjihpC4",
      "guess" => guess,
      "room_id" => "ROM8xN3vP7qR4K"
    }, queue: "guess-processing")
  end

  @doc "Builds a prize distribution job."
  def build_prize_job(player_id, rank, diamonds) do
    build_job("distribute_prize", %{
      "player_id" => player_id,
      "rank" => rank,
      "diamonds" => diamonds,
      "game_id" => "GAM5rK2mJ9pQ1L"
    }, queue: "prize-distribution")
  end

  @doc "Sets up a clean Redis connection on DB 15."
  def setup_redis(_context \\ %{}) do
    {:ok, conn} = Redix.start_link("redis://localhost:6379/15")
    Redix.command!(conn, ["FLUSHDB"])
    {:ok, conn: conn}
  end

  @doc "Waits for a specific job state with timeout."
  def wait_for_state(queue, job_id, expected_state, opts \\ []) do
    conn = Keyword.get(opts, :connection)
    timeout = Keyword.get(opts, :timeout, 5_000)
    interval = Keyword.get(opts, :interval, 100)

    deadline = System.monotonic_time(:millisecond) + timeout

    Stream.repeatedly(fn ->
      Process.sleep(interval)
      EchoMQ.Queue.get_job_state(queue, job_id, connection: conn)
    end)
    |> Enum.find(fn
      {:ok, ^expected_state} -> true
      _ -> System.monotonic_time(:millisecond) > deadline
    end)
  end

  defp generate_test_id do
    "TST" <> (:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower))
  end
end
```

</tab>
<tab title="Go">

> **Benefit**: `testing.TB` interface lets helpers accept both `*testing.T` and `*testing.B` -- reusable across tests and benchmarks.

```go
package testutil

import (
    "context"
    "testing"
    "time"

    "github.com/alicebob/miniredis/v2"
    "github.com/redis/go-redis/v9"
    "github.com/fiberfx/echomq-go/pkg/echomq"
)

// SetupMiniredis creates an in-process Redis for testing.
func SetupMiniredis(tb testing.TB) (*miniredis.Miniredis, *redis.Client) {
    tb.Helper()
    mr := miniredis.RunT(tb)
    rdb := redis.NewClient(&redis.Options{Addr: mr.Addr()})
    tb.Cleanup(func() { rdb.Close() })
    return mr, rdb
}

// BuildJob creates a test Job with sensible defaults.
func BuildJob(name string, data map[string]interface{}) *echomq.Job {
    return &echomq.Job{
        ID:           "TST" + randomID(),
        Name:         name,
        QueueName:    "test-queue",
        Data:         data,
        AttemptsMade: 0,
        Opts:         echomq.JobOptions{Attempts: 3},
    }
}

// BuildGuessJob creates a guess validation job for codemoji tests.
func BuildGuessJob(gameID, guess string) *echomq.Job {
    return BuildJob("validate_guess", map[string]interface{}{
        "game_id":   gameID,
        "player_id": "PLR0K48QjihpC4",
        "guess":     guess,
        "room_id":   "ROM8xN3vP7qR4K",
    })
}

// BuildPrizeJob creates a prize distribution job.
func BuildPrizeJob(playerID string, rank int, diamonds int) *echomq.Job {
    return BuildJob("distribute_prize", map[string]interface{}{
        "player_id": playerID,
        "rank":      rank,
        "diamonds":  diamonds,
        "game_id":   "GAM5rK2mJ9pQ1L",
    })
}

// WaitForState polls job state until it matches or times out.
func WaitForState(
    t *testing.T,
    queue *echomq.Queue,
    jobID, expectedState string,
    timeout time.Duration,
) {
    t.Helper()
    ctx := context.Background()
    deadline := time.Now().Add(timeout)

    for time.Now().Before(deadline) {
        state, err := queue.GetJobState(ctx, jobID)
        if err == nil && state == expectedState {
            return
        }
        time.Sleep(100 * time.Millisecond)
    }
    t.Fatalf("job %s did not reach state %q within %v", jobID, expectedState, timeout)
}
```

</tab>
<tab title="Node.js">

> **Benefit**: Factory functions with spread defaults make creating test jobs a one-liner with targeted overrides.

```typescript
import { Queue, Worker, QueueEvents, Job } from 'echomq';
import Redis from 'ioredis';

/**
 * Shared test helpers for EchoMQ tests.
 * Import: import { setupRedis, buildJob, waitForState } from './helpers';
 */

const TEST_CONN = { host: 'localhost', port: 6379, db: 15 };

export async function setupRedis(): Promise<Redis> {
  const redis = new Redis(TEST_CONN);
  await redis.flushdb();
  return redis;
}

export function buildJob(
  name: string,
  data: Record<string, unknown>,
  overrides: Partial<Job> = {},
): Partial<Job> {
  return {
    id: `TST${Date.now().toString(36)}`,
    name,
    data,
    queueName: 'test-queue',
    attemptsMade: 0,
    ...overrides,
  };
}

export function buildGuessJob(
  gameId = 'GAM5rK2mJ9pQ1L',
  guess = 'ABCD',
): Partial<Job> {
  return buildJob('validate_guess', {
    game_id: gameId,
    player_id: 'PLR0K48QjihpC4',
    guess,
    room_id: 'ROM8xN3vP7qR4K',
  });
}

export function buildPrizeJob(
  playerId: string,
  rank: number,
  diamonds: number,
): Partial<Job> {
  return buildJob('distribute_prize', {
    player_id: playerId,
    rank,
    diamonds,
    game_id: 'GAM5rK2mJ9pQ1L',
  });
}

/**
 * Waits for a job to reach a specific state.
 * Polls every 100ms until timeout.
 */
export async function waitForState(
  job: Job,
  expectedState: string,
  timeoutMs = 5000,
): Promise<void> {
  const start = Date.now();

  while (Date.now() - start < timeoutMs) {
    const state = await job.getState();
    if (state === expectedState) return;
    await new Promise((r) => setTimeout(r, 100));
  }

  throw new Error(
    `Job ${job.id} did not reach state "${expectedState}" within ${timeoutMs}ms`,
  );
}

/**
 * Creates a queue + worker + events triplet for integration tests.
 * Returns a cleanup function.
 */
export async function createTestWorker(
  queueName: string,
  processor: (job: Job) => Promise<unknown>,
  opts: { concurrency?: number } = {},
): Promise<{
  queue: Queue;
  worker: Worker;
  events: QueueEvents;
  cleanup: () => Promise<void>;
}> {
  const queue = new Queue(queueName, { connection: TEST_CONN });
  const worker = new Worker(queueName, processor, {
    connection: TEST_CONN,
    concurrency: opts.concurrency ?? 1,
  });
  const events = new QueueEvents(queueName, {
    connection: TEST_CONN,
  });

  const cleanup = async () => {
    await worker.close();
    await events.close();
    await queue.close();
  };

  return { queue, worker, events, cleanup };
}
```

</tab>
</tabs>

---

## 37.9. CI/CD Integration

Queue tests have unique CI/CD requirements: Redis availability, test database isolation,
timeout configuration for async operations, and parallel test safety. Each ecosystem
has established patterns for running queue tests in automated pipelines.

<tabs>
<tab title="Elixir">

> **Benefit**: Mix tags (`@moduletag :integration`) let you split fast unit tests from slow integration tests in CI stages.

```elixir
# config/test.exs -- Redis configuration for test environment
import Config

config :codemoji,
  redis_url: System.get_env("REDIS_URL", "redis://localhost:6379/15"),
  redis_pool_size: 2

# mix.exs -- test configuration
defp project do
  [
    # ...
    preferred_cli_env: [
      "test.unit": :test,
      "test.integration": :test
    ]
  ]
end

# .github/workflows/test.yml (relevant job section)
# jobs:
#   test:
#     services:
#       redis:
#         image: redis:7-alpine
#         ports:
#           - 6379:6379
#         options: --health-cmd "redis-cli ping"
#     steps:
#       - run: mix test --exclude integration
#         name: Unit Tests
#       - run: mix test --only integration
#         name: Integration Tests
#         env:
#           REDIS_URL: redis://localhost:6379/15

# test/test_helper.exs
ExUnit.start(exclude: [:integration])

# Run unit tests only (fast, no Redis needed):
#   mix test --exclude integration
#
# Run integration tests only (requires Redis):
#   mix test --only integration
#
# Run all tests:
#   mix test --include integration
```

</tab>
<tab title="Go">

> **Tradeoff**: `testing.Short()` is opt-in -- CI must explicitly pass `-short` to skip slow tests, which is easy to forget.

```go
// integration_test.go -- build tag separation
//go:build integration

package codemoji_test

import (
    "os"
    "testing"
)

func TestMain(m *testing.M) {
    // Verify Redis is available before running integration tests
    redisURL := os.Getenv("REDIS_URL")
    if redisURL == "" {
        redisURL = "localhost:6379"
    }

    // Run tests
    os.Exit(m.Run())
}

// Makefile targets:
//   test-unit:
//     go test ./... -short -count=1
//
//   test-integration:
//     go test ./... -tags=integration -count=1 -timeout=120s
//
//   test-all:
//     go test ./... -tags=integration -count=1 -timeout=120s

// .github/workflows/test.yml (relevant section)
// jobs:
//   test:
//     services:
//       redis:
//         image: redis:7-alpine
//         ports:
//           - 6379:6379
//     steps:
//       - name: Unit Tests
//         run: go test ./... -short -count=1 -race
//       - name: Integration Tests
//         run: go test ./... -tags=integration -count=1 -timeout=120s
//         env:
//           REDIS_URL: localhost:6379

// For miniredis-based tests (no real Redis needed):
func TestWithMiniredis(t *testing.T) {
    // These run in ALL modes -- no build tag needed
    mr := miniredis.RunT(t)
    _ = mr
}

// For real Redis tests:
func TestWithRealRedis(t *testing.T) {
    if testing.Short() {
        t.Skip("skipping integration test in short mode")
    }
    // Requires running Redis
}
```

</tab>
<tab title="Node.js">

> **Benefit**: Jest `projects` config runs unit and integration tests as separate test suites with different settings.

```typescript
// jest.config.ts -- multi-project configuration
export default {
  projects: [
    {
      displayName: 'unit',
      testMatch: ['<rootDir>/src/**/*.test.ts'],
      testPathIgnorePatterns: ['.integration.'],
      // Unit tests: fast, no Redis needed
      testTimeout: 5000,
    },
    {
      displayName: 'integration',
      testMatch: ['<rootDir>/src/**/*.integration.test.ts'],
      // Integration tests: slower, needs Redis
      testTimeout: 30000,
      globalSetup: '<rootDir>/test/global-setup.ts',
      globalTeardown: '<rootDir>/test/global-teardown.ts',
    },
  ],
};

// test/global-setup.ts
import Redis from 'ioredis';

export default async function globalSetup() {
  // Verify Redis is available
  const redis = new Redis({
    host: process.env.REDIS_HOST || 'localhost',
    port: parseInt(process.env.REDIS_PORT || '6379'),
    db: 15,
    lazyConnect: true,
    connectTimeout: 5000,
  });

  try {
    await redis.connect();
    await redis.ping();
    console.log('Redis connection verified for integration tests');
  } catch (err) {
    console.error('Redis not available -- skipping integration tests');
    process.env.SKIP_INTEGRATION = 'true';
  } finally {
    await redis.quit();
  }
}

// test/global-teardown.ts
import Redis from 'ioredis';

export default async function globalTeardown() {
  const redis = new Redis({ db: 15 });
  await redis.flushdb();
  await redis.quit();
}

// package.json scripts:
// "test:unit": "jest --selectProjects unit",
// "test:integration": "jest --selectProjects integration",
// "test": "jest"

// .github/workflows/test.yml (relevant section)
// jobs:
//   test:
//     services:
//       redis:
//         image: redis:7-alpine
//         ports:
//           - 6379:6379
//     steps:
//       - run: npm run test:unit
//         name: Unit Tests
//       - run: npm run test:integration
//         name: Integration Tests
//         env:
//           REDIS_HOST: localhost
//           REDIS_PORT: 6379
```

</tab>
</tabs>

---

## 37.10. Summary

| Pattern | Elixir | Go | Node.js |
|---------|--------|----|---------|
| **Unit test isolation** | BEAM process sandbox | Unique key prefixes | Fresh mock instances |
| **Redis mock** | Mox (behaviour-based) | `miniredis` (in-process) | `ioredis-mock` |
| **Integration Redis** | `start_supervised!/1` + Redix | `testcontainers-go` | testcontainers / real Redis |
| **Async assertions** | `assert_receive/2` | Channel + `select` timeout | `waitUntilFinished` / Promise |
| **Event testing** | `:telemetry.attach/4` | Channel-based listeners | EventEmitter `on`/`once` |
| **Test helpers** | Module with `build_*` functions | `testutil` package | Factory functions + cleanup |
| **CI separation** | `@moduletag :integration` | Build tags + `-short` | Jest projects config |
| **Cleanup** | Automatic (process exit) | `t.Cleanup` callbacks | `afterEach` / `afterAll` |
| **State polling** | `assert_receive` (no polling) | `WaitForState` helper | `job.getState()` loop |
| **Flow testing** | Child job events via mailbox | Parent/child workers + channels | `FlowProducer` atomic DAG |

---

*Previous: [Error Handling](ch36-error-handling.md) | Next: [Migration Guide](ch38-migration-guide.md)*
