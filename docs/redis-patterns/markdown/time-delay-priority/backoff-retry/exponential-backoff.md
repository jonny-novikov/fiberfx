# R4.04.1 · Exponential backoff

> Route: `/redis-patterns/time-delay-priority/backoff-retry/exponential-backoff` · dive 1 of R4.04

A retry needs a delay. A fixed delay treats every failure the same; an exponential delay doubles each attempt, so the first retry is quick and a repeatedly-failing dependency gets progressively more room. The formula is `delay = base × 2^(attempt - 1)` — and its owner is `EchoMQ.Backoff.calculate/4` in Elixir, not the Lua.

## The formula

Exponential backoff scales the wait with the attempt number:

```
delay = base × 2^(attempt - 1)
```

The exponent is `attempt - 1`, so the first attempt waits exactly the base:

- attempt 1 → `base × 2^0` = `base`
- attempt 2 → `base × 2^1` = `2 × base`
- attempt 3 → `base × 2^2` = `4 × base`
- attempt 4 → `base × 2^3` = `8 × base`

With a one-second base the retries land at 1s, 2s, 4s, 8s, 16s out from each failure. The delay doubles each step — a geometric series, not a linear one. Where a fixed 1s delay would re-fire five times in five seconds, the exponential schedule spreads the same five attempts across thirty-one seconds of cumulative wall-clock, giving a struggling dependency exponentially more time to recover between hits.

## Where the math lives — `EchoMQ.Backoff`, not the Lua

The exponential formula is Elixir. `EchoMQ.Backoff.calculate/4` is the owner; its `:exponential` clause computes the delay and applies jitter:

```elixir
def calculate(:exponential, attempt, base_delay, opts) do
  jitter = Keyword.get(opts, :jitter, 0)
  delay = trunc(:math.pow(2, attempt - 1) * base_delay)
  apply_jitter(delay, jitter)
end
```

`:math.pow(2, attempt - 1)` is the doubling; `base_delay` scales it; `trunc` makes it an integer millisecond. The doc example is exact: `calculate(:exponential, 3, 1000)` returns `4000`, and `calculate(:exponential, 3, 1000, jitter: 0.2)` returns about `4000` with the spread. The `:fixed` strategy is the contrast — it returns `apply_jitter(base_delay, jitter)`, the same base every attempt, no doubling.

This is the binding distinction. The retry reschedule script (`retryJob-11.lua`) does not compute `2^(n-1)`. It re-adds the job to the delayed set at a fire-time it is *given*. The delay value is computed first, in `EchoMQ.Backoff`; the Lua only reschedules at that delay. The formula is the strategy module's; the reschedule is the script's.

## The base is the whole tuning knob

The base delay sets the floor and, with it, the whole curve. A 100 ms base gives 100ms, 200ms, 400ms — tight retries for a flaky-but-fast dependency. A 5000 ms base gives 5s, 10s, 20s — patient retries for a service that takes minutes to recover. The shape is fixed (doubling); the base slides the whole series up or down. EchoMQ's default base is `1_000` ms (`%{type: :exponential, delay: 1_000, jitter: 0.2}`), so the default schedule is 1s, 2s, 4s, 8s out, jittered.

The exponent has a hard edge worth knowing: it grows the delay without bound, so the attempts cap (the *maximum retry limits* the source names) is what keeps the curve from running away — attempt 20 of a 1s-base exponential would wait over a hundred hours. The base sizes the delays; the cap sizes how many there are.

## Where this is heading — EchoMQ 2.0

The formula is computed in Elixir and the delay is written to `emq:{queue}:delayed` today. EchoMQ 2.0 renames that key to `emq:{queue}:delayed` and bumps `meta.version` to `echomq:2.0.0`, but `EchoMQ.Backoff.calculate/4` is untouched by the break — the doubling is arithmetic over the attempt number, independent of the keyspace it eventually writes to. The exponential curve this dive teaches is the same before and after the rename.

## The bridge — pattern to application

- **The pattern.** A retry delay grows with the attempt: `delay = base × 2^(attempt - 1)`, doubling each step.
- **In EchoMQ.** `EchoMQ.Backoff.calculate(:exponential, attempt, base_delay, opts)` computes `trunc(:math.pow(2, attempt - 1) × base_delay)` then jitters it; `retryJob-11.lua` reschedules at that value. The formula is Elixir; the reschedule is Lua.

The takeaway: exponential backoff doubles the delay each attempt, and the doubling lives in `EchoMQ.Backoff` — the Lua reschedules at the delay it is handed, it never computes the power.

## References

### Sources

- [Redis — *ZADD*](https://redis.io/commands/zadd/) — the write that re-schedules the failed job at the computed backoff fire-time.
- [Redis — *Sorted sets*](https://redis.io/docs/latest/develop/data-types/sorted-sets/) — the timer-wheel the exponential delay writes into.
- [BullMQ — *the queue protocol*](https://bullmq.io/) — the backoff strategy EchoMQ ports.

### Related in this course

- R4.04 · Backoff & retry — `/redis-patterns/time-delay-priority/backoff-retry`
- R4.04.2 · Jitter & the thundering herd — `/redis-patterns/time-delay-priority/backoff-retry/jitter-thundering-herd`
- R4.04.3 · Reusing the delayed ZSET — `/redis-patterns/time-delay-priority/backoff-retry/reuse-the-delayed-zset`
- R4.01 · The delayed queue — `/redis-patterns/time-delay-priority/delayed-queue`
- E6 · Lifecycle controls — `/echomq/lifecycle`
