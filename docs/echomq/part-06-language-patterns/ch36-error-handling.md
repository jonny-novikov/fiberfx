# Chapter 36. Error Handling

> Error handling philosophies and patterns across EchoMQ's three language ecosystems.

## 36.1. Overview

Each language ecosystem brings a distinct error handling philosophy to job processing. Elixir embraces
"let it crash" with pattern-matched tuples, Go demands explicit error returns with typed wrapping,
and Node.js leans on exceptions with Promise rejection. These philosophies shape every aspect of how
your queue processors report failure, decide what to retry, and recover from partial progress.

```
                     ERROR PHILOSOPHY COMPARISON
  ┌─────────────────┬──────────────────────┬──────────────────────┐
  │     Elixir      │        Go            │      Node.js         │
  ├─────────────────┼──────────────────────┼──────────────────────┤
  │ {:ok, result}   │ (result, nil)        │ return result        │
  │ {:error, reason}│ (nil, err)           │ throw new Error()    │
  │ Pattern match   │ errors.As / errors.Is│ instanceof / catch   │
  │ "Let it crash"  │ "Handle every error" │ "Catch or reject"    │
  │ Supervisor tree │ Goroutine lifecycle  │ Process manager      │
  └─────────────────┴──────────────────────┴──────────────────────┘
```

| Feature | Elixir | Go | Node.js |
|---------|--------|----|---------|
| Success signal | `{:ok, result}` | `return result, nil` | `return result` |
| Failure signal | `{:error, reason}` | `return nil, err` | `throw new Error(msg)` |
| Permanent fail | `UnrecoverableError` | `*PermanentError` | `UnrecoverableError` |
| Retry delay | `{:delay, ms}` | `*TransientError` | `DelayedError` |
| Error inspection | Pattern matching | `errors.As` / `errors.Is` | `instanceof` |
| Cancellation | `CancellationToken` (mailbox) | `context.Context` | `AbortController` |
| Custom backoff | `Backoff.register/2` | `CalculateBackoff()` | `Backoffs.calculate()` |

---

## 36.2. Processor Return Conventions

How each language signals success, failure, retry, and delay from job processors. This is the
foundation of EchoMQ's error handling -- the processor return value determines the job's fate.

<tabs>
<tab title="Elixir">

> **Benefit**: Tagged tuples make return-value-driven flow control explicit and exhaustive at the call site.

```elixir
defmodule Codemoji.GuessProcessor do
  @moduledoc """
  Processor for guess validation jobs (GUS entity).

  Return values control job outcome:
    {:ok, result}         -> Completed successfully
    :ok                   -> Completed (no return value)
    {:error, reason}      -> Failed, may retry based on attempts
    {:delay, ms}          -> Retry later WITHOUT incrementing attempts
    {:rate_limit, ms}     -> Delay due to rate limiting
    :waiting              -> Move back to waiting queue
    :waiting_children     -> Wait for child jobs to complete
  """

  def process(%EchoMQ.Job{name: "validate_guess", data: data}) do
    case Codemoji.Games.validate_guess(data["game_id"], data["guess"]) do
      {:ok, %{correct: true} = result} ->
        {:ok, result}

      {:ok, %{correct: false} = result} ->
        {:ok, result}

      {:error, :game_finished} ->
        # Game already ended -- permanent, skip retry
        {:error, EchoMQ.UnrecoverableError.new("Game already finished")}

      {:error, :redis_timeout} ->
        # Transient -- retry after 2 seconds without burning an attempt
        {:delay, 2_000}

      {:error, :rate_limited} ->
        # Telegram API rate limit -- back off
        {:rate_limit, 30_000}

      {:error, reason} ->
        # Other errors retry with standard backoff
        {:error, reason}
    end
  end
end
```

</tab>
<tab title="Go">

> **Tradeoff**: Explicit `(result, error)` returns require checking at every call site, but make all failure paths visible.

```go
package codemoji

import (
    "fmt"
    "github.com/fiberfx/echomq-go/pkg/echomq"
)

// GuessProcessor handles guess validation jobs (GUS entity).
//
// Go uses (result, error) returns. The error type determines retry behavior:
//   nil           -> Completed successfully
//   *TransientError  -> Retry with backoff
//   *PermanentError  -> Fail immediately, no retry
//   *ValidationError -> Fail immediately (invalid input)
//   other error      -> Categorized by CategorizeError()
func GuessProcessor(job *echomq.Job) (interface{}, error) {
    gameID, _ := job.Data["game_id"].(string)
    guess, _ := job.Data["guess"].(string)

    result, err := validateGuess(gameID, guess)
    if err != nil {
        switch {
        case isGameFinished(err):
            // Permanent -- game already ended
            return nil, &echomq.PermanentError{
                Err: err,
                Msg: "game already finished",
            }

        case isRedisTimeout(err):
            // Transient -- retry with exponential backoff
            return nil, &echomq.TransientError{
                Err: err,
                Msg: "redis timeout during guess validation",
            }

        default:
            // CategorizeError() inspects error type:
            // net.Error -> transient, context.DeadlineExceeded -> transient,
            // ValidationError -> permanent, default -> permanent
            return nil, err
        }
    }

    return result, nil
}
```

</tab>
<tab title="Node.js">

> **Benefit**: `async/await` with `throw` maps naturally to existing JavaScript error handling patterns.

```typescript
import { Job, UnrecoverableError, DelayedError } from 'echomq';

/**
 * Guess processor for validation jobs (GUS entity).
 *
 * Node.js uses return/throw conventions:
 *   return value          -> Completed successfully
 *   throw Error           -> Failed, retries based on attempts config
 *   throw UnrecoverableError -> Fail immediately, no retry
 *   throw DelayedError    -> Move to delayed state
 *   throw RateLimitError  -> Rate limit the queue
 *   throw WaitingChildrenError -> Wait for child jobs
 */
async function processGuess(job: Job): Promise<{ correct: boolean }> {
  const { game_id, guess } = job.data;

  try {
    const result = await validateGuess(game_id, guess);
    return result;
  } catch (err) {
    if (err.code === 'GAME_FINISHED') {
      // Permanent -- bypass retry entirely
      throw new UnrecoverableError('Game already finished');
    }

    if (err.code === 'REDIS_TIMEOUT') {
      // Move to delayed -- retry without incrementing attempts
      throw new DelayedError('Redis timeout, retrying later');
    }

    // All other errors: standard retry with configured backoff
    throw err;
  }
}
```

</tab>
</tabs>

---

## 36.3. Error Type Hierarchies

Each language provides a structured way to classify errors so the worker can make retry decisions
automatically. The key distinction everywhere is **transient** (retry) vs **permanent** (fail fast).

<tabs>
<tab title="Elixir">

> **Benefit**: No class hierarchy needed — pattern matching on tuples and structs handles all classification.

```elixir
# Elixir uses tagged tuples and structs -- no class hierarchies needed.
# The worker pattern-matches on the return value to decide behavior.

# --- Built-in error signals ---

# Permanent failure: bypasses retry, moves directly to failed
{:error, EchoMQ.UnrecoverableError.new("Player PLR0K48 not found")}

# Transient failure: retries with configured backoff
{:error, "Telegram API returned 500"}

# Manual delay: retries WITHOUT incrementing attempt counter
{:delay, 5_000}

# Rate limit signal: delays the entire queue
{:rate_limit, 30_000}

# --- Pattern matching for classification ---

defmodule Codemoji.ErrorClassifier do
  @doc "Classify errors for monitoring and alerting."
  def classify({:error, %EchoMQ.UnrecoverableError{}}), do: :permanent
  def classify({:error, %{__exception__: true}}), do: :exception
  def classify({:error, reason}) when is_binary(reason), do: :transient
  def classify({:error, reason}) when is_atom(reason), do: :transient
  def classify({:delay, _ms}), do: :rate_limited
  def classify({:ok, _}), do: :success
  def classify(:ok), do: :success
end
```

</tab>
<tab title="Go">

> **Benefit**: `errors.As`/`errors.Is` provide type-safe unwrapping through the entire error chain.

```go
package echomq

import (
    "context"
    "errors"
    "net"
)

// TransientError indicates a temporary failure (should retry).
// Wraps the original error for unwrapping via errors.As/errors.Is.
type TransientError struct {
    Err error
    Msg string
}

func (e *TransientError) Error() string { return "transient error: " + e.Msg + ": " + e.Err.Error() }
func (e *TransientError) Unwrap() error { return e.Err }

// PermanentError indicates a permanent failure (should not retry).
type PermanentError struct {
    Err error
    Msg string
}

func (e *PermanentError) Error() string { return "permanent error: " + e.Msg + ": " + e.Err.Error() }
func (e *PermanentError) Unwrap() error { return e.Err }

// ValidationError indicates invalid input (always permanent).
type ValidationError struct {
    Field   string
    Message string
}

func (e *ValidationError) Error() string {
    return "validation error: " + e.Field + ": " + e.Message
}

// CategorizeError uses errors.As to walk the error chain and
// classify by type. This is Go's idiomatic alternative to catch blocks.
func CategorizeError(err error) ErrorCategory {
    // Explicit wrappers take priority
    var transient *TransientError
    if errors.As(err, &transient) { return ErrorCategoryTransient }

    var permanent *PermanentError
    if errors.As(err, &permanent) { return ErrorCategoryPermanent }

    // Network errors are always transient
    var netErr net.Error
    if errors.As(err, &netErr) { return ErrorCategoryTransient }

    // Context cancellation/timeout is transient
    if errors.Is(err, context.DeadlineExceeded) { return ErrorCategoryTransient }
    if errors.Is(err, context.Canceled)         { return ErrorCategoryTransient }

    // Default: permanent (fail fast, don't waste retries)
    return ErrorCategoryPermanent
}
```

</tab>
<tab title="Node.js">

> **Tradeoff**: `instanceof` checks require proper prototype chain setup (`Object.setPrototypeOf`) when targeting ES5.

```typescript
// Node.js uses Error subclasses with instanceof checks.
// EchoMQ provides five built-in error classes:

// 1. UnrecoverableError -- permanent failure, bypass retry
export class UnrecoverableError extends Error {
  constructor(message: string = 'bullmq:unrecoverable') {
    super(message);
    this.name = this.constructor.name;
    Object.setPrototypeOf(this, new.target.prototype);
  }
}

// 2. DelayedError -- move job to delayed state
export class DelayedError extends Error {
  constructor(message: string = 'bullmq:movedToDelayed') {
    super(message);
    this.name = this.constructor.name;
    Object.setPrototypeOf(this, new.target.prototype);
  }
}

// 3. RateLimitError -- rate limit the entire queue
export class RateLimitError extends Error {
  constructor(message: string = 'bullmq:rateLimitExceeded') {
    super(message);
    this.name = this.constructor.name;
    Object.setPrototypeOf(this, new.target.prototype);
  }
}

// 4. WaitingChildrenError -- wait for child jobs
export class WaitingChildrenError extends Error {
  constructor(message: string = 'bullmq:movedToWaitingChildren') {
    super(message);
    this.name = this.constructor.name;
    Object.setPrototypeOf(this, new.target.prototype);
  }
}

// 5. WaitingError -- move back to wait/prioritized
export class WaitingError extends Error {
  constructor(message: string = 'bullmq:movedToWait') {
    super(message);
    this.name = this.constructor.name;
    Object.setPrototypeOf(this, new.target.prototype);
  }
}

// The worker's handleFailed() checks instanceof to route errors:
//   RateLimitError    -> moveLimitedBackToWait()
//   DelayedError      -> moveToActive() (re-pick next job)
//   WaitingError      -> moveToActive()
//   WaitingChildrenError -> moveToActive()
//   UnrecoverableError -> moveToFailed() immediately
//   other Error       -> moveToFailed() with retry logic
```

</tab>
</tabs>

---

## 36.4. Retry Configuration

Per-job retry options and backoff strategies. All three runtimes support the same two built-in
strategies (fixed and exponential) because they share the same underlying Redis Lua scripts.

<tabs>
<tab title="Elixir">

> **Benefit**: Backoff config is plain data (maps), composable and serializable without special types.

```elixir
# --- Per-job retry options ---

# Prize claim job (BNK entity) with exponential backoff
EchoMQ.Queue.add("prizes", "claim_prize", %{
    player_id: "PLR0K48QjihpC4",
    prize_id: "PRZ0K5M2vuIULY",
    amount: 500
  },
  connection: :redis,
  attempts: 5,
  backoff: %{type: :exponential, delay: 2_000}
)
# Retry delays: 2s, 4s, 8s, 16s, 32s

# Telegram notification with fixed backoff
EchoMQ.Queue.add("notifications", "send_telegram", %{
    chat_id: "123456789",
    text: "You won 500 coins!"
  },
  connection: :redis,
  attempts: 3,
  backoff: %{type: :fixed, delay: 5_000}
)
# Retry delays: 5s, 5s, 5s

# Exponential backoff WITH jitter (prevents thundering herd)
EchoMQ.Queue.add("leaderboard", "recalculate", %{
    snapshot_id: "SNP0K5M3abc123"
  },
  connection: :redis,
  attempts: 4,
  backoff: %{type: :exponential, delay: 1_000, jitter: 0.2}
)
# Retry delays: ~1s, ~2s, ~4s, ~8s (each +/- 20%)
```

</tab>
<tab title="Go">

> **Benefit**: Typed `BackoffConfig` struct catches invalid configuration at compile time.

```go
package codemoji

import (
    "time"
    "github.com/fiberfx/echomq-go/pkg/echomq"
)

func setupRetryConfig() {
    // Prize claim job (BNK entity) with exponential backoff
    producer.Add("prizes", "claim_prize", map[string]interface{}{
        "player_id": "PLR0K48QjihpC4",
        "prize_id":  "PRZ0K5M2vuIULY",
        "amount":    500,
    }, echomq.JobOptions{
        Attempts: 5,
        Backoff: echomq.BackoffConfig{
            Type:  "exponential",
            Delay: 2000, // milliseconds
        },
    })
    // Retry delays: 2s, 4s, 8s, 16s, 32s

    // Notification with fixed backoff
    producer.Add("notifications", "send_telegram", map[string]interface{}{
        "chat_id": "123456789",
        "text":    "You won 500 coins!",
    }, echomq.JobOptions{
        Attempts: 3,
        Backoff: echomq.BackoffConfig{
            Type:  "fixed",
            Delay: 5000,
        },
    })
    // Retry delays: 5s, 5s, 5s
}

// Go's CalculateBackoff includes built-in jitter (+/- 20%)
// Formula: min(initialDelay * 2^(attempt-1) * jitter, maxDelay)
func example() {
    delay := echomq.CalculateBackoff(
        3,                    // attemptsMade
        1*time.Second,        // initialDelay
        30*time.Second,       // maxDelay
    )
    // Returns ~4s with 0.8-1.2 jitter factor
}
```

</tab>
<tab title="Node.js">

> **Benefit**: Shorthand syntax (passing a number normalizes to fixed backoff) reduces boilerplate for common cases.

```typescript
import { Queue } from 'echomq';

const prizeQueue = new Queue('prizes');
const notifyQueue = new Queue('notifications');

// Prize claim job (BNK entity) with exponential backoff
await prizeQueue.add('claim_prize', {
  player_id: 'PLR0K48QjihpC4',
  prize_id: 'PRZ0K5M2vuIULY',
  amount: 500,
}, {
  attempts: 5,
  backoff: {
    type: 'exponential',
    delay: 2000,
  },
});
// Retry delays: 2s, 4s, 8s, 16s, 32s

// Notification with fixed backoff
await notifyQueue.add('send_telegram', {
  chat_id: '123456789',
  text: 'You won 500 coins!',
}, {
  attempts: 3,
  backoff: {
    type: 'fixed',
    delay: 5000,
  },
});
// Retry delays: 5s, 5s, 5s

// Exponential backoff WITH jitter
await prizeQueue.add('claim_prize', data, {
  attempts: 4,
  backoff: {
    type: 'exponential',
    delay: 1000,
    jitter: 0.2,  // +/- 20% randomness
  },
});
// Retry delays: ~1s, ~2s, ~4s, ~8s

// Shorthand: pass a number for fixed backoff
await prizeQueue.add('simple_task', data, {
  attempts: 3,
  backoff: 5000,  // Normalized to { type: 'fixed', delay: 5000 }
});
```

</tab>
</tabs>

### Backoff Strategy Comparison

| Strategy | Formula | Attempt 1 | Attempt 2 | Attempt 3 | Attempt 4 |
|----------|---------|-----------|-----------|-----------|-----------|
| `fixed` | `delay` | 2s | 2s | 2s | 2s |
| `exponential` | `delay * 2^(n-1)` | 2s | 4s | 8s | 16s |
| `exponential` + jitter 0.2 | `delay * 2^(n-1) * [0.8, 1.2]` | ~2s | ~4s | ~8s | ~16s |

---

## 36.5. Selective Retry Logic

Not all errors deserve retries. The key skill is distinguishing transient failures (network glitch,
rate limit) from permanent ones (invalid data, deleted resource). Each language has a natural
idiom for this classification.

<tabs>
<tab title="Elixir">

> **Benefit**: Pattern matching makes error classification declarative — each clause is a distinct retry policy.

```elixir
defmodule Codemoji.TelegramProcessor do
  @moduledoc """
  Selective retry for Telegram API calls.
  Pattern matching makes error classification declarative.
  """

  def process(%EchoMQ.Job{data: %{"chat_id" => chat_id, "text" => text}}) do
    case Codemoji.Telegram.send_message(chat_id, text) do
      {:ok, _message} ->
        {:ok, :sent}

      # 429 Too Many Requests -- transient, respect retry_after
      {:error, %{error_code: 429, parameters: %{retry_after: seconds}}} ->
        {:delay, seconds * 1_000}

      # 403 Forbidden -- user blocked bot, permanent
      {:error, %{error_code: 403}} ->
        # Return :ok to complete without polluting the failed queue
        {:ok, :skipped_blocked_user}

      # 400 Bad Request -- chat not found (PLR entity deleted)
      {:error, %{error_code: 400, description: desc}} when desc =~ "chat not found" ->
        {:ok, :skipped_invalid_chat}

      # 500-599 Server errors -- transient, standard retry
      {:error, %{error_code: code}} when code >= 500 ->
        {:error, "Telegram server error: #{code}"}

      # Network/timeout errors -- transient
      {:error, %Mint.TransportError{} = err} ->
        {:error, Exception.message(err)}

      # Unknown errors -- let the default retry logic decide
      {:error, reason} ->
        {:error, reason}
    end
  end
end
```

</tab>
<tab title="Go">

> **Tradeoff**: Explicit `errors.As` unwrapping is verbose but ensures no error category goes unhandled.

```go
package codemoji

import (
    "errors"
    "fmt"
    "net/http"

    "github.com/fiberfx/echomq-go/pkg/echomq"
)

// TelegramError represents a Telegram API error response.
type TelegramError struct {
    Code        int
    Description string
    RetryAfter  int
}

func (e *TelegramError) Error() string {
    return fmt.Sprintf("telegram %d: %s", e.Code, e.Description)
}

// TelegramProcessor classifies Telegram errors explicitly.
// Go forces you to handle every error path -- no silent swallowing.
func TelegramProcessor(job *echomq.Job) (interface{}, error) {
    chatID, _ := job.Data["chat_id"].(string)
    text, _ := job.Data["text"].(string)

    err := sendTelegramMessage(chatID, text)
    if err == nil {
        return map[string]interface{}{"sent": true}, nil
    }

    // Unwrap to check for TelegramError
    var tgErr *TelegramError
    if errors.As(err, &tgErr) {
        switch {
        case tgErr.Code == http.StatusTooManyRequests:
            // 429: transient, retry after specified delay
            return nil, &echomq.TransientError{
                Err: tgErr,
                Msg: fmt.Sprintf("rate limited, retry after %ds", tgErr.RetryAfter),
            }

        case tgErr.Code == http.StatusForbidden:
            // 403: user blocked bot -- complete as success (skip)
            return map[string]interface{}{"skipped": "blocked_user"}, nil

        case tgErr.Code == http.StatusBadRequest:
            // 400: permanent failure (chat not found)
            return nil, &echomq.PermanentError{
                Err: tgErr,
                Msg: "invalid chat ID",
            }

        case tgErr.Code >= 500:
            // 5xx: transient server error
            return nil, &echomq.TransientError{
                Err: tgErr,
                Msg: "telegram server error",
            }
        }
    }

    // For unknown errors, CategorizeError() handles net.Error,
    // context.DeadlineExceeded, etc. automatically
    return nil, err
}
```

</tab>
<tab title="Node.js">

> **Tradeoff**: Property-based checks (`err.response?.status`) are concise but fragile if the API response shape changes.

```typescript
import { Job, UnrecoverableError, DelayedError, RateLimitError } from 'echomq';

/**
 * Selective retry for Telegram API calls.
 * Node.js uses try/catch with instanceof and error property checks.
 */
async function processTelegram(job: Job): Promise<{ sent: boolean }> {
  const { chat_id, text } = job.data;

  try {
    await sendTelegramMessage(chat_id, text);
    return { sent: true };
  } catch (err: any) {
    // 429 Too Many Requests -- rate limit the queue
    if (err.response?.status === 429) {
      const retryAfter = err.response?.data?.parameters?.retry_after ?? 30;
      // RateLimitError pauses the entire queue, not just this job
      throw new RateLimitError(
        `Rate limited for ${retryAfter}s`
      );
    }

    // 403 Forbidden -- user blocked bot, complete without retry
    if (err.response?.status === 403) {
      // Return instead of throw: marks job as completed
      return { sent: false, skipped: 'blocked_user' } as any;
    }

    // 400 Bad Request -- permanent failure
    if (err.response?.status === 400) {
      throw new UnrecoverableError(
        `Invalid chat: ${err.response?.data?.description}`
      );
    }

    // 5xx Server errors -- standard retry with backoff
    if (err.response?.status >= 500) {
      throw new Error(`Telegram server error: ${err.response.status}`);
    }

    // Network errors (ECONNREFUSED, ETIMEDOUT) -- standard retry
    throw err;
  }
}
```

</tab>
</tabs>

---

## 36.6. Unrecoverable Errors

When a job can never succeed regardless of retries, mark it as permanently failed.
All three runtimes provide a mechanism to bypass retry logic and move directly to the failed state.

<tabs>
<tab title="Elixir">

> **Benefit**: `with/else` chains handle multi-step failures in one declarative block with tagged error origins.

```elixir
defmodule Codemoji.PrizeClaimProcessor do
  @moduledoc """
  Prize claim processing (BNK/TXN entities).

  UnrecoverableError is a struct that the worker recognizes.
  When returned as {:error, %UnrecoverableError{}}, the job
  moves to failed immediately regardless of remaining attempts.
  """

  def process(%EchoMQ.Job{data: data} = job) do
    player_id = data["player_id"]
    prize_id = data["prize_id"]

    with {:ok, player} <- Codemoji.Players.get(player_id),
         {:ok, prize} <- Codemoji.Prizes.get(prize_id),
         :ok <- validate_claim_window(prize),
         {:ok, txn} <- Codemoji.Bank.transfer(player, prize) do
      {:ok, %{transaction_id: txn.id, amount: txn.amount}}
    else
      {:error, :player_not_found} ->
        # Player deleted -- will never succeed
        {:error, EchoMQ.UnrecoverableError.new(
          "Player #{player_id} not found"
        )}

      {:error, :prize_expired} ->
        # Claim window closed -- permanent
        {:error, EchoMQ.UnrecoverableError.new(
          "Prize #{prize_id} claim window expired"
        )}

      {:error, :insufficient_balance} ->
        # Balance could be replenished -- allow retry
        {:error, "Insufficient balance for prize claim"}

      {:error, :payment_gateway_timeout} ->
        # Gateway might recover -- transient
        {:delay, 10_000}

      {:error, reason} ->
        {:error, inspect(reason)}
    end
  end

  defp validate_claim_window(prize) do
    if DateTime.compare(DateTime.utc_now(), prize.expires_at) == :gt do
      {:error, :prize_expired}
    else
      :ok
    end
  end
end
```

</tab>
<tab title="Go">

> **Benefit**: Each failure point returns explicitly, making the exact location of failure always traceable.

```go
package codemoji

import (
    "fmt"
    "time"

    "github.com/fiberfx/echomq-go/pkg/echomq"
)

// PrizeClaimProcessor handles prize claims (BNK/TXN entities).
//
// In Go, PermanentError wraps the original error and signals
// the worker to skip retry logic entirely. The worker checks:
//   category := CategorizeError(err)
//   if category == ErrorCategoryPermanent { moveToFailed() }
func PrizeClaimProcessor(job *echomq.Job) (interface{}, error) {
    playerID, _ := job.Data["player_id"].(string)
    prizeID, _ := job.Data["prize_id"].(string)

    player, err := getPlayer(playerID)
    if err != nil {
        // Player not found -- permanent
        return nil, &echomq.PermanentError{
            Err: err,
            Msg: fmt.Sprintf("player %s not found", playerID),
        }
    }

    prize, err := getPrize(prizeID)
    if err != nil {
        return nil, &echomq.PermanentError{
            Err: err,
            Msg: fmt.Sprintf("prize %s not found", prizeID),
        }
    }

    // Check claim window
    if time.Now().After(prize.ExpiresAt) {
        return nil, &echomq.PermanentError{
            Err: fmt.Errorf("claim window closed at %v", prize.ExpiresAt),
            Msg: "prize claim expired",
        }
    }

    // Attempt transfer
    txn, err := transferFunds(player, prize)
    if err != nil {
        if isInsufficientBalance(err) {
            // Could be replenished -- transient
            return nil, &echomq.TransientError{
                Err: err,
                Msg: "insufficient balance",
            }
        }
        // Default categorization handles net.Error, timeouts, etc.
        return nil, err
    }

    return map[string]interface{}{
        "transaction_id": txn.ID,
        "amount":         txn.Amount,
    }, nil
}
```

</tab>
<tab title="Node.js">

> **Benefit**: `throw new UnrecoverableError()` immediately short-circuits the entire async function.

```typescript
import { Job, UnrecoverableError, DelayedError } from 'echomq';

/**
 * Prize claim processor (BNK/TXN entities).
 *
 * UnrecoverableError extends Error with a sentinel name.
 * The worker's handleFailed() checks: if the error is
 * instanceof UnrecoverableError, it calls moveToFailed()
 * with zero remaining attempts.
 */
async function processClaimPrize(job: Job): Promise<{
  transaction_id: string;
  amount: number;
}> {
  const { player_id, prize_id } = job.data;

  const player = await getPlayer(player_id);
  if (!player) {
    // Player deleted -- will never succeed
    throw new UnrecoverableError(
      `Player ${player_id} not found`
    );
  }

  const prize = await getPrize(prize_id);
  if (!prize) {
    throw new UnrecoverableError(
      `Prize ${prize_id} not found`
    );
  }

  // Check claim window
  if (new Date() > prize.expiresAt) {
    throw new UnrecoverableError(
      `Prize ${prize_id} claim window expired`
    );
  }

  try {
    const txn = await transferFunds(player, prize);
    return { transaction_id: txn.id, amount: txn.amount };
  } catch (err: any) {
    if (err.code === 'INSUFFICIENT_BALANCE') {
      // Could be replenished -- standard retry
      throw new Error('Insufficient balance for prize claim');
    }

    if (err.code === 'GATEWAY_TIMEOUT') {
      // Gateway might recover -- delay without attempt increment
      throw new DelayedError('Payment gateway timeout');
    }

    throw err;
  }
}
```

</tab>
</tabs>

---

## 36.7. Dead Letter Queues

When a job exhausts all retries, move it to a dead letter queue (DLQ) for inspection, debugging,
or manual replay. This pattern prevents failed jobs from being lost while keeping the main
queue clean.

<tabs>
<tab title="Elixir">

> **Benefit**: `on_failed` callback keeps DLQ routing fully decoupled from processor logic.

```elixir
defmodule Codemoji.DeadLetterHandler do
  @moduledoc """
  Routes permanently failed jobs to a dead letter queue.
  Hooks into the worker's on_failed callback.
  """

  require Logger

  def handle_failed(%EchoMQ.Job{} = job, reason) do
    Logger.warning("Job #{job.id} failed permanently: #{inspect(reason)}",
      queue: job.queue_name,
      job_name: job.name,
      attempts: job.attempts_made
    )

    # Enqueue to DLQ with full context for debugging
    EchoMQ.Queue.add("dead_letter", "failed_job", %{
        original_queue: job.queue_name,
        original_job_id: job.id,
        job_name: job.name,
        job_data: job.data,
        failed_reason: inspect(reason),
        failed_at: DateTime.utc_now() |> DateTime.to_iso8601(),
        attempts_made: job.attempts_made
      },
      connection: :redis,
      # DLQ jobs should NOT retry -- they are for inspection only
      attempts: 1
    )
  end
end

# Wire the handler into the worker via on_failed callback
{:ok, _worker} = EchoMQ.Worker.start_link(
  queue: "prizes",
  connection: :redis,
  processor: &Codemoji.PrizeClaimProcessor.process/1,
  on_failed: &Codemoji.DeadLetterHandler.handle_failed/2,
  concurrency: 5
)
```

</tab>
<tab title="Go">

> **Benefit**: Wrapper processor pattern is composable — stack DLQ, metrics, and retry wrappers independently.

```go
package codemoji

import (
    "context"
    "encoding/json"
    "fmt"
    "log"
    "time"

    "github.com/fiberfx/echomq-go/pkg/echomq"
)

// DeadLetterRouter moves permanently failed jobs to a DLQ.
// In Go, this is wired via a wrapper processor pattern.
type DeadLetterRouter struct {
    dlqProducer *echomq.Producer
    inner       func(*echomq.Job) (interface{}, error)
}

func (d *DeadLetterRouter) Process(job *echomq.Job) (interface{}, error) {
    result, err := d.inner(job)
    if err != nil {
        category := echomq.CategorizeError(err)

        // Only route to DLQ on permanent errors or max attempts
        if category == echomq.ErrorCategoryPermanent ||
            job.AttemptsMade >= job.Opts.Attempts {

            d.routeToDLQ(job, err)
        }
    }
    return result, err
}

func (d *DeadLetterRouter) routeToDLQ(job *echomq.Job, jobErr error) {
    ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
    defer cancel()

    dataJSON, _ := json.Marshal(job.Data)

    err := d.dlqProducer.Add(ctx, "dead_letter", "failed_job",
        map[string]interface{}{
            "original_queue":  job.QueueName,
            "original_job_id": job.ID,
            "job_name":        job.Name,
            "job_data":        string(dataJSON),
            "failed_reason":   jobErr.Error(),
            "failed_at":       time.Now().UTC().Format(time.RFC3339),
            "attempts_made":   job.AttemptsMade,
        },
        echomq.JobOptions{Attempts: 1}, // No retry for DLQ entries
    )
    if err != nil {
        log.Printf("[dlq] failed to enqueue job %s: %v", job.ID, err)
    }
}

// Usage:
// router := &DeadLetterRouter{
//     dlqProducer: dlqProducer,
//     inner:       PrizeClaimProcessor,
// }
// worker.Process(router.Process)
```

</tab>
<tab title="Node.js">

> **Benefit**: EventEmitter `'failed'` event supports multiple independent listeners for the same event.

```typescript
import { Worker, Queue, Job } from 'echomq';

const dlqQueue = new Queue('dead_letter');

/**
 * Wire DLQ routing via the worker's 'failed' event.
 * This fires after all retries are exhausted.
 */
const worker = new Worker('prizes', processClaimPrize, {
  concurrency: 5,
  connection: { host: 'localhost', port: 6379 },
});

worker.on('failed', async (job: Job | undefined, err: Error) => {
  if (!job) return;

  console.warn(`Job ${job.id} failed permanently: ${err.message}`);

  await dlqQueue.add('failed_job', {
    original_queue: job.queueName,
    original_job_id: job.id,
    job_name: job.name,
    job_data: job.data,
    failed_reason: err.message,
    failed_at: new Date().toISOString(),
    attempts_made: job.attemptsMade,
  }, {
    attempts: 1, // No retry for DLQ entries
  });
});

// Optional: process DLQ entries for replay
const dlqWorker = new Worker('dead_letter', async (job: Job) => {
  // Log, alert, store in database, or replay to original queue
  console.log(`[DLQ] ${job.data.original_queue}/${job.data.job_name}:`,
    job.data.failed_reason);
  return { acknowledged: true };
});
```

</tab>
</tabs>

---

## 36.8. Cancellation and Interruption

Long-running jobs need cooperative cancellation. Each language has a native cancellation
primitive that EchoMQ integrates into its worker lifecycle.

<tabs>
<tab title="Elixir">

> **Benefit**: Mailbox-based cancellation is O(1) and requires zero shared mutable state.

```elixir
defmodule Codemoji.LeaderboardCalculator do
  @moduledoc """
  Leaderboard recalculation with cancellation support (SNP entity).

  Elixir's CancellationToken uses the process mailbox:
  - Token is a reference (make_ref())
  - Worker sends {:cancel, token, reason} to the processor process
  - Processor checks mailbox with `receive after 0` (O(1), non-blocking)
  """

  def process(%EchoMQ.Job{data: data} = job, cancel_token) do
    snapshot_id = data["snapshot_id"]
    players = Codemoji.Players.list_active()

    # Process players in chunks, checking cancellation between each
    players
    |> Enum.chunk_every(100)
    |> Enum.reduce_while({:ok, []}, fn chunk, {:ok, acc} ->
      # Non-blocking cancellation check via mailbox
      case EchoMQ.CancellationToken.check(cancel_token) do
        {:cancelled, reason} ->
          {:halt, {:error, {:cancelled, reason}}}

        :ok ->
          results = Enum.map(chunk, &calculate_score/1)
          progress = length(acc ++ results) / length(players) * 100
          EchoMQ.Worker.update_progress(job, progress)
          {:cont, {:ok, acc ++ results}}
      end
    end)
    |> case do
      {:ok, scores} ->
        Codemoji.Snapshots.save(snapshot_id, scores)
        {:ok, %{snapshot: snapshot_id, players: length(scores)}}

      {:error, {:cancelled, _reason}} = err ->
        err
    end
  end
end

# Cancel a running job from outside:
EchoMQ.Worker.cancel_job(worker, job_id, "Admin cancelled recalculation")
```

</tab>
<tab title="Go">

> **Benefit**: `context.Context` is the ecosystem standard — all Go libraries and frameworks accept it natively.

```go
package codemoji

import (
    "context"
    "fmt"

    "github.com/fiberfx/echomq-go/pkg/echomq"
)

// LeaderboardCalculator processes leaderboard recalculations (SNP entity).
//
// Go uses context.Context for cancellation -- the standard pattern
// throughout the Go ecosystem. The worker passes a context that gets
// cancelled on shutdown or when the job lock is lost.
func LeaderboardCalculator(job *echomq.Job) (interface{}, error) {
    ctx := job.Context() // Worker-provided context with cancellation

    snapshotID, _ := job.Data["snapshot_id"].(string)
    players, err := listActivePlayers(ctx)
    if err != nil {
        return nil, err
    }

    var scores []Score
    chunkSize := 100

    for i := 0; i < len(players); i += chunkSize {
        // Check cancellation between chunks
        select {
        case <-ctx.Done():
            return nil, &echomq.TransientError{
                Err: ctx.Err(),
                Msg: fmt.Sprintf(
                    "cancelled after %d/%d players",
                    len(scores), len(players),
                ),
            }
        default:
        }

        end := i + chunkSize
        if end > len(players) {
            end = len(players)
        }

        chunk := players[i:end]
        for _, player := range chunk {
            score := calculateScore(ctx, player)
            scores = append(scores, score)
        }

        // Update progress
        progress := float64(len(scores)) / float64(len(players)) * 100
        job.UpdateProgress(ctx, int(progress))
    }

    if err := saveSnapshot(ctx, snapshotID, scores); err != nil {
        return nil, err
    }

    return map[string]interface{}{
        "snapshot": snapshotID,
        "players":  len(scores),
    }, nil
}
```

</tab>
<tab title="Node.js">

> **Tradeoff**: `AbortSignal` requires explicit opt-in and manual polling between async operations.

```typescript
import { Job, WaitingChildrenError } from 'echomq';

/**
 * Leaderboard calculator with AbortController cancellation (SNP entity).
 *
 * Node.js uses AbortController/AbortSignal -- the Web API standard.
 * The worker creates an AbortController and passes its signal to the
 * processor. The signal is aborted when the job lock is lost or
 * the worker shuts down.
 *
 * To receive the signal, set `useWorkerThreads: true` or return
 * true from the processor's signal acceptance check.
 */
async function calculateLeaderboard(
  job: Job,
  signal?: AbortSignal,
): Promise<{ snapshot: string; players: number }> {
  const { snapshot_id } = job.data;
  const players = await listActivePlayers();

  const scores: Score[] = [];
  const chunkSize = 100;

  for (let i = 0; i < players.length; i += chunkSize) {
    // Check AbortSignal between chunks
    if (signal?.aborted) {
      throw new Error(
        `Cancelled after ${scores.length}/${players.length} players`
      );
    }

    const chunk = players.slice(i, i + chunkSize);
    for (const player of chunk) {
      scores.push(await calculateScore(player));
    }

    // Update progress
    const progress = (scores.length / players.length) * 100;
    await job.updateProgress(Math.round(progress));
  }

  await saveSnapshot(snapshot_id, scores);
  return { snapshot: snapshot_id, players: scores.length };
}

// Configure worker to pass AbortSignal to processor
const worker = new Worker('leaderboard', calculateLeaderboard, {
  concurrency: 2,
  // When true, processor receives AbortSignal as second argument
  useWorkerThreads: false,
});
```

</tab>
</tabs>

### Cancellation Mechanism Comparison

| Feature | Elixir | Go | Node.js |
|---------|--------|----|---------|
| Primitive | `CancellationToken` (ref) | `context.Context` | `AbortController` |
| Check cost | O(1) mailbox peek | `select` on channel | property check |
| Propagation | Process message | Context tree | Signal listeners |
| Blocking check | `receive` with timeout | `<-ctx.Done()` | `signal.addEventListener` |
| Non-blocking check | `receive after 0` | `select default` | `signal.aborted` |
| Cleanup | Automatic (GC) | `defer cancel()` | `signal.removeEventListener` |

---

## 36.9. Error Recovery Patterns

When jobs fail partway through, you need strategies to avoid duplicate work and resume
from where you left off. These patterns are critical for jobs that make external side effects.

### Idempotent Operations

<tabs>
<tab title="Elixir">

> **Benefit**: Pattern matching on `:already_processed` makes the idempotent path self-documenting.

```elixir
defmodule Codemoji.BankTransferProcessor do
  @moduledoc """
  Idempotent prize claim transfer (TXN entity).
  Uses job ID as idempotency key to prevent double-spending.
  """

  def process(%EchoMQ.Job{id: job_id, data: data}) do
    player_id = data["player_id"]
    amount = data["amount"]

    # Use job_id as idempotency key -- safe to retry
    case Codemoji.Bank.transfer_idempotent(player_id, amount, job_id) do
      {:ok, :already_processed} ->
        # Previous attempt completed this job -- return cached result
        {:ok, %{status: "already_processed", idempotency_key: job_id}}

      {:ok, %{transaction_id: txn_id} = txn} ->
        {:ok, %{transaction_id: txn_id, amount: txn.amount}}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
```

</tab>
<tab title="Go">

> **Benefit**: Explicit check-then-act pattern makes the idempotency logic visible at every step.

```go
package codemoji

import (
    "github.com/fiberfx/echomq-go/pkg/echomq"
)

// BankTransferProcessor is idempotent via job ID (TXN entity).
// The job ID serves as idempotency key for the payment system.
func BankTransferProcessor(job *echomq.Job) (interface{}, error) {
    playerID, _ := job.Data["player_id"].(string)
    amount, _ := job.Data["amount"].(float64)

    // Use job.ID as idempotency key -- safe to retry
    txn, err := transferIdempotent(playerID, int(amount), job.ID)
    if err != nil {
        if isAlreadyProcessed(err) {
            return map[string]interface{}{
                "status":          "already_processed",
                "idempotency_key": job.ID,
            }, nil
        }
        return nil, err
    }

    return map[string]interface{}{
        "transaction_id": txn.ID,
        "amount":         txn.Amount,
    }, nil
}
```

</tab>
<tab title="Node.js">

> **Benefit**: Database-level dedup via unique constraint offloads idempotency to the storage layer.

```typescript
import { Job } from 'echomq';

/**
 * Idempotent bank transfer (TXN entity).
 * Job ID used as idempotency key for payment gateway.
 */
async function processBankTransfer(job: Job) {
  const { player_id, amount } = job.data;

  // Use job.id as idempotency key -- safe to retry
  const existing = await db.query(
    'SELECT * FROM transactions WHERE idempotency_key = $1',
    [job.id]
  );

  if (existing.rows.length > 0) {
    return {
      status: 'already_processed',
      idempotency_key: job.id,
    };
  }

  const txn = await transferFunds(player_id, amount, {
    idempotencyKey: job.id,
  });

  return { transaction_id: txn.id, amount: txn.amount };
}
```

</tab>
</tabs>

### Checkpoint and Resume

<tabs>
<tab title="Elixir">

> **Benefit**: Recursive `reduce_while` naturally checkpoints between chunks with tail-call optimization.

```elixir
defmodule Codemoji.BatchSnapshotProcessor do
  @moduledoc """
  Leaderboard batch processing with checkpoint/resume (SNP entity).

  If the job fails partway through, the checkpoint records
  progress so the next attempt resumes from where it left off.
  """

  def process(%EchoMQ.Job{id: job_id, data: data} = job) do
    snapshot_id = data["snapshot_id"]
    all_players = Codemoji.Players.list_ids()

    # Load checkpoint from previous attempt (if any)
    checkpoint = load_checkpoint(job_id) || %{processed: 0, scores: []}
    remaining = Enum.drop(all_players, checkpoint.processed)

    case process_remaining(remaining, checkpoint, job) do
      {:ok, final_scores} ->
        Codemoji.Snapshots.save(snapshot_id, final_scores)
        clear_checkpoint(job_id)
        {:ok, %{snapshot: snapshot_id, total: length(final_scores)}}

      {:error, partial_checkpoint, reason} ->
        save_checkpoint(job_id, partial_checkpoint)
        {:error, reason}
    end
  end

  defp process_remaining([], checkpoint, _job), do: {:ok, checkpoint.scores}

  defp process_remaining([player_id | rest], checkpoint, job) do
    case Codemoji.Scoring.calculate(player_id) do
      {:ok, score} ->
        new_checkpoint = %{
          processed: checkpoint.processed + 1,
          scores: [score | checkpoint.scores]
        }

        progress = new_checkpoint.processed / (new_checkpoint.processed + length(rest)) * 100
        EchoMQ.Worker.update_progress(job, progress)

        process_remaining(rest, new_checkpoint, job)

      {:error, reason} ->
        {:error, checkpoint, "Failed on player #{player_id}: #{reason}"}
    end
  end

  defp load_checkpoint(job_id) do
    case Codemoji.Cache.get("checkpoint:#{job_id}") do
      nil -> nil
      data -> Jason.decode!(data, keys: :atoms)
    end
  end

  defp save_checkpoint(job_id, checkpoint) do
    Codemoji.Cache.put("checkpoint:#{job_id}", Jason.encode!(checkpoint),
      ttl: :timer.hours(24)
    )
  end

  defp clear_checkpoint(job_id) do
    Codemoji.Cache.delete("checkpoint:#{job_id}")
  end
end
```

</tab>
<tab title="Go">

> **Benefit**: Periodic checkpoint save (every 50 items) balances durability against throughput overhead.

```go
package codemoji

import (
    "context"
    "encoding/json"
    "fmt"
    "time"

    "github.com/fiberfx/echomq-go/pkg/echomq"
    "github.com/redis/go-redis/v9"
)

// Checkpoint tracks progress for resumable batch processing.
type Checkpoint struct {
    Processed int      `json:"processed"`
    Scores    []Score  `json:"scores"`
    UpdatedAt string   `json:"updated_at"`
}

// BatchSnapshotProcessor resumes from checkpoint on retry (SNP entity).
func BatchSnapshotProcessor(rdb *redis.Client) echomq.ProcessorFunc {
    return func(job *echomq.Job) (interface{}, error) {
        ctx := job.Context()
        snapshotID, _ := job.Data["snapshot_id"].(string)
        allPlayers, err := listPlayerIDs(ctx)
        if err != nil {
            return nil, err
        }

        // Load checkpoint from previous attempt
        cp, err := loadCheckpoint(ctx, rdb, job.ID)
        if err != nil {
            cp = &Checkpoint{Processed: 0, Scores: nil}
        }

        // Resume from where we left off
        remaining := allPlayers[cp.Processed:]

        for i, playerID := range remaining {
            select {
            case <-ctx.Done():
                saveCheckpoint(ctx, rdb, job.ID, cp)
                return nil, &echomq.TransientError{
                    Err: ctx.Err(),
                    Msg: "cancelled, checkpoint saved",
                }
            default:
            }

            score, err := calculateScore(ctx, playerID)
            if err != nil {
                // Save checkpoint before failing
                saveCheckpoint(ctx, rdb, job.ID, cp)
                return nil, fmt.Errorf("player %s: %w", playerID, err)
            }

            cp.Scores = append(cp.Scores, score)
            cp.Processed++

            // Update progress
            progress := float64(cp.Processed) / float64(len(allPlayers)) * 100
            job.UpdateProgress(ctx, int(progress))

            // Periodic checkpoint save (every 50 items)
            if (i+1)%50 == 0 {
                saveCheckpoint(ctx, rdb, job.ID, cp)
            }
        }

        // All done -- save snapshot, clear checkpoint
        if err := saveSnapshot(ctx, snapshotID, cp.Scores); err != nil {
            return nil, err
        }
        clearCheckpoint(ctx, rdb, job.ID)

        return map[string]interface{}{
            "snapshot": snapshotID,
            "total":    len(cp.Scores),
        }, nil
    }
}

func loadCheckpoint(ctx context.Context, rdb *redis.Client, jobID string) (*Checkpoint, error) {
    data, err := rdb.Get(ctx, "checkpoint:"+jobID).Bytes()
    if err != nil {
        return nil, err
    }
    var cp Checkpoint
    return &cp, json.Unmarshal(data, &cp)
}

func saveCheckpoint(ctx context.Context, rdb *redis.Client, jobID string, cp *Checkpoint) {
    cp.UpdatedAt = time.Now().UTC().Format(time.RFC3339)
    data, _ := json.Marshal(cp)
    rdb.Set(ctx, "checkpoint:"+jobID, data, 24*time.Hour)
}

func clearCheckpoint(ctx context.Context, rdb *redis.Client, jobID string) {
    rdb.Del(ctx, "checkpoint:"+jobID)
}
```

</tab>
<tab title="Node.js">

> **Benefit**: Redis `EX` flag on checkpoint keys auto-cleans stale checkpoints after 24 hours.

```typescript
import { Job } from 'echomq';
import Redis from 'ioredis';

interface Checkpoint {
  processed: number;
  scores: Score[];
  updatedAt: string;
}

const redis = new Redis();

/**
 * Batch snapshot processor with checkpoint/resume (SNP entity).
 * Saves progress to Redis so retries resume from last checkpoint.
 */
async function processBatchSnapshot(job: Job) {
  const { snapshot_id } = job.data;
  const allPlayers = await listPlayerIDs();

  // Load checkpoint from previous attempt
  let cp: Checkpoint = await loadCheckpoint(job.id) ?? {
    processed: 0,
    scores: [],
    updatedAt: new Date().toISOString(),
  };

  // Resume from where we left off
  const remaining = allPlayers.slice(cp.processed);

  for (let i = 0; i < remaining.length; i++) {
    try {
      const score = await calculateScore(remaining[i]);
      cp.scores.push(score);
      cp.processed++;

      // Update progress
      const progress = Math.round(
        (cp.processed / allPlayers.length) * 100
      );
      await job.updateProgress(progress);

      // Periodic checkpoint save (every 50 items)
      if ((i + 1) % 50 === 0) {
        await saveCheckpoint(job.id, cp);
      }
    } catch (err) {
      // Save checkpoint before re-throwing for retry
      await saveCheckpoint(job.id, cp);
      throw err;
    }
  }

  // All done -- save snapshot, clear checkpoint
  await saveSnapshot(snapshot_id, cp.scores);
  await clearCheckpoint(job.id);

  return { snapshot: snapshot_id, total: cp.scores.length };
}

async function loadCheckpoint(jobId: string): Promise<Checkpoint | null> {
  const data = await redis.get(`checkpoint:${jobId}`);
  return data ? JSON.parse(data) : null;
}

async function saveCheckpoint(jobId: string, cp: Checkpoint) {
  cp.updatedAt = new Date().toISOString();
  await redis.set(`checkpoint:${jobId}`, JSON.stringify(cp), 'EX', 86400);
}

async function clearCheckpoint(jobId: string) {
  await redis.del(`checkpoint:${jobId}`);
}
```

</tab>
</tabs>

---

## 36.10. Monitoring and Alerting on Failures

Each ecosystem provides hooks for tracking job failures through telemetry events,
callback hooks, and integration with observability platforms.

<tabs>
<tab title="Elixir">

> **Benefit**: `:telemetry.attach_many` subscribes to multiple event types in a single registration call.

```elixir
defmodule Codemoji.ErrorTelemetry do
  @moduledoc """
  Telemetry-based error monitoring for EchoMQ workers.

  Elixir's :telemetry library provides structured event emission
  that integrates with Prometheus, StatsD, and LiveDashboard.
  """

  require Logger

  def setup do
    events = [
      [:echomq, :job, :fail],
      [:echomq, :job, :complete],
      [:echomq, :job, :stalled]
    ]

    :telemetry.attach_many(
      "codemoji-error-monitor",
      events,
      &handle_event/4,
      %{alert_queues: ["prizes", "bank_transfers"]}
    )
  end

  def handle_event([:echomq, :job, :fail], measurements, metadata, config) do
    Logger.error("Job failed",
      job_id: metadata.job_id,
      queue: metadata.queue,
      job_name: metadata.job_name,
      duration_ms: div(measurements.duration, 1_000_000),
      error: inspect(metadata.error),
      attempts: metadata.attempts_made
    )

    # Increment Prometheus counter
    :telemetry.execute(
      [:codemoji, :job, :failure],
      %{count: 1},
      %{queue: metadata.queue, job_name: metadata.job_name}
    )

    # Alert on critical queues
    if metadata.queue in config.alert_queues do
      Codemoji.Alerts.send(
        :critical,
        "Job #{metadata.job_id} failed in #{metadata.queue}: " <>
          "#{inspect(metadata.error)}"
      )
    end
  end

  def handle_event([:echomq, :job, :stalled], _measurements, metadata, _config) do
    Logger.warning("Job stalled: #{metadata.job_id}",
      queue: metadata.queue
    )

    :telemetry.execute(
      [:codemoji, :job, :stalled],
      %{count: 1},
      %{queue: metadata.queue}
    )
  end

  def handle_event(_, _, _, _), do: :ok
end
```

</tab>
<tab title="Go">

> **Benefit**: Prometheus middleware wrapper pattern is reusable across all processor functions.

```go
package codemoji

import (
    "log"
    "sync/atomic"
    "time"

    "github.com/fiberfx/echomq-go/pkg/echomq"
    "github.com/prometheus/client_golang/prometheus"
    "github.com/prometheus/client_golang/prometheus/promauto"
)

var (
    jobFailures = promauto.NewCounterVec(
        prometheus.CounterOpts{
            Name: "codemoji_job_failures_total",
            Help: "Total job failures by queue and name",
        },
        []string{"queue", "job_name", "error_category"},
    )

    jobDuration = promauto.NewHistogramVec(
        prometheus.HistogramOpts{
            Name:    "codemoji_job_duration_seconds",
            Help:    "Job processing duration",
            Buckets: prometheus.DefBuckets,
        },
        []string{"queue", "job_name", "status"},
    )

    stalledJobs = promauto.NewCounter(prometheus.CounterOpts{
        Name: "codemoji_jobs_stalled_total",
        Help: "Total stalled jobs detected",
    })
)

// MonitoredProcessor wraps a processor with Prometheus metrics.
func MonitoredProcessor(
    queueName string,
    inner func(*echomq.Job) (interface{}, error),
) func(*echomq.Job) (interface{}, error) {
    return func(job *echomq.Job) (interface{}, error) {
        start := time.Now()

        result, err := inner(job)
        duration := time.Since(start).Seconds()

        if err != nil {
            category := echomq.CategorizeError(err)
            categoryStr := "permanent"
            if category == echomq.ErrorCategoryTransient {
                categoryStr = "transient"
            }

            jobFailures.WithLabelValues(
                queueName, job.Name, categoryStr,
            ).Inc()

            jobDuration.WithLabelValues(
                queueName, job.Name, "failed",
            ).Observe(duration)

            log.Printf("[monitor] job %s failed (%s): %v",
                job.ID, categoryStr, err)
        } else {
            jobDuration.WithLabelValues(
                queueName, job.Name, "completed",
            ).Observe(duration)
        }

        return result, err
    }
}

// Usage:
// worker.Process(MonitoredProcessor("prizes", PrizeClaimProcessor))
```

</tab>
<tab title="Node.js">

> **Benefit**: EventEmitter events (`'failed'`, `'completed'`, `'stalled'`) cover the full job lifecycle.

```typescript
import { Worker, Job } from 'echomq';
import { Counter, Histogram, Registry } from 'prom-client';

// Prometheus metrics
const register = new Registry();

const jobFailures = new Counter({
  name: 'codemoji_job_failures_total',
  help: 'Total job failures by queue and name',
  labelNames: ['queue', 'job_name', 'error_type'],
  registers: [register],
});

const jobDuration = new Histogram({
  name: 'codemoji_job_duration_seconds',
  help: 'Job processing duration',
  labelNames: ['queue', 'job_name', 'status'],
  registers: [register],
});

/**
 * Node.js uses EventEmitter events for monitoring.
 * The Worker emits 'failed', 'completed', 'error', and 'stalled'.
 */
function setupMonitoring(worker: Worker, queueName: string) {
  worker.on('failed', (job: Job | undefined, err: Error) => {
    if (!job) return;

    const errorType = err.name === 'UnrecoverableError'
      ? 'permanent' : 'transient';

    jobFailures.inc({
      queue: queueName,
      job_name: job.name,
      error_type: errorType,
    });

    console.error(`[monitor] Job ${job.id} failed (${errorType}):`,
      err.message, `attempts: ${job.attemptsMade}`);

    // Alert on critical queues
    if (['prizes', 'bank_transfers'].includes(queueName)) {
      sendAlert('critical',
        `Job ${job.id} failed in ${queueName}: ${err.message}`);
    }
  });

  worker.on('completed', (job: Job, result: any) => {
    jobDuration.observe(
      { queue: queueName, job_name: job.name, status: 'completed' },
      (Date.now() - job.processedOn!) / 1000,
    );
  });

  worker.on('stalled', (jobId: string) => {
    console.warn(`[monitor] Job ${jobId} stalled in ${queueName}`);
  });

  worker.on('error', (err: Error) => {
    console.error(`[monitor] Worker error in ${queueName}:`, err);
  });
}
```

</tab>
</tabs>

---

## 36.11. Custom Backoff Strategies

Beyond fixed and exponential, each language lets you define custom backoff logic
that can inspect the error, the job, and the attempt count.

<tabs>
<tab title="Elixir">

> **Benefit**: `Backoff.register/2` makes custom strategies available by name across all queues.

```elixir
# Register a custom linear backoff strategy
EchoMQ.Backoff.register(:linear, fn attempt, delay, _error, _job ->
  attempt * delay
end)

# Register a strategy that adapts based on error type
EchoMQ.Backoff.register(:adaptive, fn attempt, delay, error, _job ->
  case error do
    %{error_code: 429, parameters: %{retry_after: seconds}} ->
      # Use server-provided retry-after value
      seconds * 1_000

    %{error_code: code} when code >= 500 ->
      # Server errors: aggressive exponential
      trunc(:math.pow(2, attempt) * delay)

    _ ->
      # Default: gentle linear increase
      attempt * delay
  end
end)

# Use custom strategy when adding jobs
EchoMQ.Queue.add("notifications", "send_telegram", data,
  connection: :redis,
  attempts: 5,
  backoff: %{type: :adaptive, delay: 1_000}
)
```

</tab>
<tab title="Go">

> **Tradeoff**: No built-in strategy registry — custom backoff requires wrapping `CalculateBackoff` manually.

```go
package codemoji

import (
    "math"
    "math/rand"
    "time"

    "github.com/fiberfx/echomq-go/pkg/echomq"
)

// AdaptiveBackoff calculates retry delays based on error type.
// Go's CalculateBackoff is a pure function -- customize by wrapping.
func AdaptiveBackoff(
    job *echomq.Job,
    err error,
    attempt int,
) time.Duration {
    // Check for explicit retry-after from API response
    var tgErr *TelegramError
    if errors.As(err, &tgErr) && tgErr.RetryAfter > 0 {
        return time.Duration(tgErr.RetryAfter) * time.Second
    }

    // Server errors: aggressive exponential
    if isServerError(err) {
        base := 2 * time.Second
        return time.Duration(
            float64(base) * math.Pow(2, float64(attempt)),
        )
    }

    // Default: standard exponential with jitter
    return echomq.CalculateBackoff(
        attempt,
        1*time.Second,   // initialDelay
        30*time.Second,   // maxDelay
    )
}

// LinearBackoff implements simple linear backoff.
func LinearBackoff(attempt int, baseDelay time.Duration) time.Duration {
    delay := time.Duration(attempt) * baseDelay
    // Add 10% jitter
    jitter := time.Duration(rand.Float64() * 0.1 * float64(delay))
    return delay + jitter
}
```

</tab>
<tab title="Node.js">

> **Benefit**: `backoffStrategy` setting on Worker applies globally; job-level `type` selects which strategy.

```typescript
import { Queue, Worker, Job, BackoffOptions } from 'echomq';
import { BackoffStrategy } from 'echomq/types';

/**
 * Custom backoff strategy.
 * Register at Worker creation -- receives attempt count, type, error, and job.
 */
const adaptiveBackoff: BackoffStrategy = (
  attemptsMade: number,
  type: string,
  err: Error,
  job: Job,
): number => {
  // Check for server-provided retry-after
  const retryAfter = (err as any).retryAfter;
  if (retryAfter) {
    return retryAfter * 1000;
  }

  // Server errors: aggressive exponential
  if ((err as any).statusCode >= 500) {
    return Math.pow(2, attemptsMade) * 2000;
  }

  // Default: gentle linear increase
  return attemptsMade * 1000;
};

// Register custom strategy with the Worker
const worker = new Worker('notifications', processNotification, {
  settings: {
    backoffStrategy: adaptiveBackoff,
  },
});

// Use custom strategy name when adding jobs
const queue = new Queue('notifications');
await queue.add('send_telegram', data, {
  attempts: 5,
  backoff: {
    type: 'adaptive',  // Matches the registered strategy
    delay: 1000,
  },
});
```

</tab>
</tabs>

---

## 36.12. Error Propagation Chains

Complex jobs call multiple services. Understanding how errors propagate through
the call chain -- and where to catch them -- is essential for reliable processing.

<tabs>
<tab title="Elixir">

> **Benefit**: `with` macro with tagged steps (`{:validate, ...}`) identifies exactly where the chain broke.

```elixir
defmodule Codemoji.PrizeFlowProcessor do
  @moduledoc """
  Multi-step prize flow with error propagation.

  Elixir's `with` macro creates clean error propagation chains.
  Each step returns {:ok, _} or {:error, _}, and the `else` block
  handles all failure paths in one place.
  """

  def process(%EchoMQ.Job{data: data} = job) do
    with {:validate, {:ok, claim}} <- {:validate, validate_claim(data)},
         {:balance, {:ok, balance}} <- {:balance, check_balance(claim)},
         {:transfer, {:ok, txn}} <- {:transfer, execute_transfer(claim, balance)},
         {:notify, {:ok, _}} <- {:notify, send_notification(claim, txn)} do
      {:ok, %{
        claim_id: claim.id,
        transaction_id: txn.id,
        amount: txn.amount
      }}
    else
      # Tag each step so errors identify WHERE the failure occurred
      {:validate, {:error, reason}} ->
        {:error, EchoMQ.UnrecoverableError.new("Validation: #{reason}")}

      {:balance, {:error, :insufficient}} ->
        {:delay, 60_000}  # Balance might be replenished

      {:balance, {:error, reason}} ->
        {:error, "Balance check: #{reason}"}

      {:transfer, {:error, :gateway_timeout}} ->
        {:delay, 10_000}

      {:transfer, {:error, reason}} ->
        {:error, EchoMQ.UnrecoverableError.new("Transfer: #{reason}")}

      {:notify, {:error, _reason}} ->
        # Notification failure should not fail the job
        # Transfer already succeeded -- log and complete
        Logger.warning("Notification failed for job #{job.id}, transfer OK")
        {:ok, %{notification: :skipped}}
    end
  end
end
```

</tab>
<tab title="Go">

> **Benefit**: `fmt.Errorf` with `%w` wrapping preserves the full error chain for `errors.As` inspection.

```go
package codemoji

import (
    "fmt"

    "github.com/fiberfx/echomq-go/pkg/echomq"
)

// PrizeFlowProcessor chains multiple operations with explicit error handling.
// Go's explicit error returns make the propagation path visible at every step.
func PrizeFlowProcessor(job *echomq.Job) (interface{}, error) {
    // Step 1: Validate
    claim, err := validateClaim(job.Data)
    if err != nil {
        return nil, &echomq.PermanentError{
            Err: err,
            Msg: "validation failed",
        }
    }

    // Step 2: Check balance
    balance, err := checkBalance(claim)
    if err != nil {
        if isInsufficientBalance(err) {
            // Balance might be replenished -- transient
            return nil, &echomq.TransientError{
                Err: err,
                Msg: "insufficient balance, will retry",
            }
        }
        return nil, fmt.Errorf("balance check: %w", err)
    }

    // Step 3: Execute transfer
    txn, err := executeTransfer(claim, balance)
    if err != nil {
        if isGatewayTimeout(err) {
            return nil, &echomq.TransientError{
                Err: err,
                Msg: "gateway timeout",
            }
        }
        return nil, &echomq.PermanentError{
            Err: err,
            Msg: "transfer failed permanently",
        }
    }

    // Step 4: Send notification (non-critical)
    if err := sendNotification(claim, txn); err != nil {
        // Log but don't fail -- transfer already succeeded
        log.Printf("[prize-flow] notification failed for job %s: %v",
            job.ID, err)
    }

    return map[string]interface{}{
        "claim_id":       claim.ID,
        "transaction_id": txn.ID,
        "amount":         txn.Amount,
    }, nil
}
```

</tab>
<tab title="Node.js">

> **Tradeoff**: Sequential `try/catch` blocks can become deeply nested for multi-step flows.

```typescript
import { Job, UnrecoverableError, DelayedError } from 'echomq';

/**
 * Multi-step prize flow with error propagation.
 * Node.js uses try/catch nesting or sequential await with
 * error wrapping for clear propagation chains.
 */
async function processPrizeFlow(job: Job) {
  // Step 1: Validate (permanent on failure)
  let claim: Claim;
  try {
    claim = await validateClaim(job.data);
  } catch (err: any) {
    throw new UnrecoverableError(`Validation: ${err.message}`);
  }

  // Step 2: Check balance (may be transient)
  let balance: Balance;
  try {
    balance = await checkBalance(claim);
  } catch (err: any) {
    if (err.code === 'INSUFFICIENT_BALANCE') {
      throw new DelayedError('Insufficient balance, retrying in 60s');
    }
    throw new Error(`Balance check: ${err.message}`);
  }

  // Step 3: Execute transfer
  let txn: Transaction;
  try {
    txn = await executeTransfer(claim, balance);
  } catch (err: any) {
    if (err.code === 'GATEWAY_TIMEOUT') {
      throw new DelayedError('Gateway timeout, retrying');
    }
    throw new UnrecoverableError(`Transfer: ${err.message}`);
  }

  // Step 4: Send notification (non-critical)
  try {
    await sendNotification(claim, txn);
  } catch (err) {
    // Log but don't fail -- transfer already succeeded
    console.warn(`Notification failed for job ${job.id}:`, err);
  }

  return {
    claim_id: claim.id,
    transaction_id: txn.id,
    amount: txn.amount,
  };
}
```

</tab>
</tabs>

---

## 36.13. Common Pitfalls

Language-specific error handling mistakes that trip up developers working with queue processing.

<tabs>
<tab title="Elixir">

> **Tradeoff**: Pattern match assertions (`{:ok, _} = ...`) crash on mismatch, which surprises developers from other languages.

```elixir
# --- PITFALL 1: Asserting on {:ok, _} (crashes the processor) ---

# BAD: MatchError crash on {:error, _}
def process(job) do
  {:ok, result} = do_work(job.data)
  {:ok, result}
end

# GOOD: Handle all cases
def process(job) do
  case do_work(job.data) do
    {:ok, result} -> {:ok, result}
    {:error, reason} -> {:error, reason}
  end
end

# --- PITFALL 2: Infinite retries via {:delay, _} ---

# BAD: Never gives up
def process(job) do
  case api_call(job.data) do
    {:error, _} -> {:delay, 5_000}
    {:ok, result} -> {:ok, result}
  end
end

# GOOD: Track attempts, fail eventually
def process(%{attempts_made: attempts} = job) when attempts >= 10 do
  {:error, EchoMQ.UnrecoverableError.new("Max manual retries exceeded")}
end

def process(job) do
  case api_call(job.data) do
    {:error, :rate_limited} -> {:delay, 5_000}
    {:error, reason} -> {:error, reason}
    {:ok, result} -> {:ok, result}
  end
end

# --- PITFALL 3: Non-idempotent side effects ---

# BAD: Double-credits on retry
def process(job) do
  Codemoji.Bank.add_coins(job.data["player_id"], job.data["amount"])
  {:ok, :done}
end

# GOOD: Idempotent with job ID
def process(job) do
  Codemoji.Bank.add_coins_once(
    job.data["player_id"],
    job.data["amount"],
    idempotency_key: job.id
  )
  {:ok, :done}
end
```

</tab>
<tab title="Go">

> **Tradeoff**: Silent error swallowing (log then `return nil, nil`) is the most common Go error handling bug.

```go
package codemoji

import "github.com/fiberfx/echomq-go/pkg/echomq"

// --- PITFALL 1: Ignoring error categorization ---

// BAD: All errors treated the same (default = permanent)
func badProcessor(job *echomq.Job) (interface{}, error) {
    result, err := callExternalAPI(job.Data)
    if err != nil {
        return nil, err // Network errors fail permanently!
    }
    return result, nil
}

// GOOD: Wrap errors with intent
func goodProcessor(job *echomq.Job) (interface{}, error) {
    result, err := callExternalAPI(job.Data)
    if err != nil {
        if isNetworkError(err) {
            return nil, &echomq.TransientError{Err: err, Msg: "api call"}
        }
        return nil, &echomq.PermanentError{Err: err, Msg: "api call"}
    }
    return result, nil
}

// --- PITFALL 2: Swallowing errors silently ---

// BAD: Error is logged but not returned (job shows as success)
func silentProcessor(job *echomq.Job) (interface{}, error) {
    result, err := processData(job.Data)
    if err != nil {
        log.Printf("error: %v", err) // Logged but job completes!
        return nil, nil
    }
    return result, nil
}

// GOOD: Return the error so the worker can decide
func loudProcessor(job *echomq.Job) (interface{}, error) {
    result, err := processData(job.Data)
    if err != nil {
        return nil, fmt.Errorf("processing job %s: %w", job.ID, err)
    }
    return result, nil
}

// --- PITFALL 3: Not wrapping errors for context ---

// BAD: No context about where the error occurred
func noContextProcessor(job *echomq.Job) (interface{}, error) {
    _, err := step1(job.Data)
    if err != nil { return nil, err }    // Which step failed?
    _, err = step2(job.Data)
    if err != nil { return nil, err }    // No way to tell
    return nil, nil
}

// GOOD: Wrap errors with fmt.Errorf %w
func contextProcessor(job *echomq.Job) (interface{}, error) {
    _, err := step1(job.Data)
    if err != nil { return nil, fmt.Errorf("step1: %w", err) }
    _, err = step2(job.Data)
    if err != nil { return nil, fmt.Errorf("step2: %w", err) }
    return nil, nil
}
```

</tab>
<tab title="Node.js">

> **Tradeoff**: Returning `undefined` instead of throwing creates ambiguous completion signals.

```typescript
import { Job, UnrecoverableError } from 'echomq';

// --- PITFALL 1: Unhandled Promise rejection ---

// BAD: Async error not caught (crashes the worker process)
async function badProcessor(job: Job) {
  const result = await riskyApiCall(job.data);
  // If riskyApiCall rejects, the entire worker may crash
  return result;
}

// GOOD: Wrap in try/catch with proper error types
async function goodProcessor(job: Job) {
  try {
    const result = await riskyApiCall(job.data);
    return result;
  } catch (err: any) {
    if (err.response?.status === 404) {
      throw new UnrecoverableError('Resource not found');
    }
    throw err; // Let worker handle retry
  }
}

// --- PITFALL 2: Swallowing errors in callbacks ---

// BAD: Error in event handler silently fails
worker.on('completed', async (job) => {
  await updateAnalytics(job); // If this throws, nobody knows
});

// GOOD: Catch errors in event handlers
worker.on('completed', async (job) => {
  try {
    await updateAnalytics(job);
  } catch (err) {
    console.error(`Analytics update failed for ${job.id}:`, err);
  }
});

// --- PITFALL 3: Returning undefined instead of throwing ---

// BAD: Returns undefined on error (job shows as "completed")
async function ambiguousProcessor(job: Job) {
  const data = await fetchData(job.data.id);
  if (!data) return; // Completed with undefined result!
}

// GOOD: Throw on failure so worker handles it correctly
async function clearProcessor(job: Job) {
  const data = await fetchData(job.data.id);
  if (!data) {
    throw new UnrecoverableError(
      `Data not found for ${job.data.id}`
    );
  }
  return data;
}
```

</tab>
</tabs>

---

## 36.14. Summary

| Pattern | Elixir | Go | Node.js |
|---------|--------|----|---------|
| **Error philosophy** | Let it crash + pattern match | Explicit returns + wrapping | Exceptions + Promise rejection |
| **Permanent failure** | `{:error, UnrecoverableError.new(msg)}` | `return nil, &PermanentError{}` | `throw new UnrecoverableError(msg)` |
| **Transient failure** | `{:error, reason}` | `return nil, &TransientError{}` | `throw new Error(msg)` |
| **Manual delay** | `{:delay, ms}` | Not built-in (use TransientError) | `throw new DelayedError(msg)` |
| **Rate limiting** | `{:rate_limit, ms}` | `*RateLimitedError` | `throw new RateLimitError(msg)` |
| **Error inspection** | Pattern matching (compile-time) | `errors.As` / `errors.Is` (runtime) | `instanceof` / `.name` check |
| **Custom backoff** | `Backoff.register/2` agent | `CalculateBackoff()` function | `settings.backoffStrategy` |
| **Cancellation** | `CancellationToken` (mailbox) | `context.Context` (channel) | `AbortController` (signal) |
| **Error propagation** | `with` macro chains | `if err != nil` chains | `try/catch` nesting |
| **Monitoring** | `:telemetry.attach/4` | Prometheus middleware wrapper | `worker.on('failed', ...)` |
| **DLQ routing** | `on_failed` callback | Wrapper processor pattern | `'failed'` event listener |

---

*Previous: [Chapter 35: Concurrent Data Structures](ch35-concurrent-data-structures.md) | Next: [Testing & Mocking](ch37-testing-mocking.md)*
