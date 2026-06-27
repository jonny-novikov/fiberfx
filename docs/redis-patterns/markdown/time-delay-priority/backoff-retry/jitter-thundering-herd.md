# R4.04.2 · Jitter & the thundering herd

> Route: `/redis-patterns/time-delay-priority/backoff-retry/jitter-thundering-herd` · dive 2 of R4.04

A fixed backoff schedules every job that failed together for the same future instant — so they re-fire in one spike, the thundering herd. Jitter spreads them across a window. In the real bus jitter is a policy wrapper: `{:jitter, inner}`, a uniform random delay in `0..inner_delay`.

## §1 — The herd

A dependency blinks. A hundred jobs fail in the same moment, each at attempt 3. A fixed exponential backoff prices the same delay for all of them — `4 × base` — so all hundred are scheduled for the **same** future instant. When that instant arrives the promotion sweep moves all hundred back to pending at once, and they hit the dependency together: a second spike on a service that was already struggling. The retry meant to relieve the dependency instead re-creates the original pressure.

## §2 — Spreading the cohort

Jitter breaks the synchrony. Instead of scheduling each job at exactly `delay`, schedule it at a random point bounded by `delay`. A hundred jobs that failed together now carry a hundred different fire-times scattered across the window, and the promotion sweep releases them gradually. The dependency sees a spread, not a spike. The full-jitter form makes the bound the whole delay: each job's wait is a uniform random value in `0..delay`.

The cost is variance: a given job's exact wait is no longer predictable, only its bound. That is the trade — predictability for the absence of a herd — and for retry work it is almost always worth taking.

## §3 — Jitter as a policy wrapper

In the real bus jitter is not a flag on the formula; it is a policy that wraps any inner policy. `{:jitter, inner}` computes the inner policy's delay, then draws a uniform random value bounded by it:

```elixir
# EchoMQ.Backoff.delay_ms/2 — the :jitter clause (verbatim)
def delay_ms({:jitter, inner}, attempts) do
  bound = delay_ms(inner, attempts)          # the inner curve's delay
  if bound <= 0, do: 0, else: :rand.uniform(bound + 1) - 1   # uniform in 0..bound
end
```

Wrapping the exponential policy — `{:jitter, {:exponential, 100, 10_000}}` — gives a curve that climbs **and** spreads: attempt 3's bound is 400, so the jittered delay is a uniform draw in `0..400`. The inner delay is its bound, and the randomness is the point. This is the only non-deterministic policy in the vocabulary; `:fixed` and `:exponential` are pure functions of `(policy, attempts)`.

## §4 — Where the spread lands

The jittered delay crosses to the wire the same way every backoff delay does: as the literal `delay_ms` argument to `EchoMQ.Jobs.retry/7`, which ZADDs the job onto the schedule set at `now + delay_ms`. A cohort that failed together is written to the schedule set at scattered scores, so `EchoMQ.Jobs.promote/3` sweeps them back across a window rather than in one ZRANGEBYSCORE pull. The spread is a property of the scores; nothing on the wire knows it was jittered.

## The bridge — pattern to application

- **The pattern:** a fixed backoff synchronizes a failed cohort into one re-fire spike; full jitter draws each retry's wait uniformly in `0..delay`, so the cohort re-fires across a window.
- **Its EchoMQ application:** `EchoMQ.Backoff.delay_ms({:jitter, inner}, attempts)` returns a uniform random delay bounded by the inner curve; `EchoMQ.Jobs.retry/7` schedules each job at `now + delay_ms`, scattering the cohort across the schedule set.

## References

### Sources

- Redis — *ZADD* — https://redis.io/commands/zadd/ — write each jittered retry at its own schedule-set score.
- Redis — *ZRANGEBYSCORE* — https://redis.io/commands/zrangebyscore/ — the sweep that releases the spread cohort gradually.
- Valkey — *Sorted sets* — https://valkey.io/topics/data-types/ — the structure the scattered scores live on.

### Related in this course

- R4.04 · Backoff & retry — `/redis-patterns/time-delay-priority/backoff-retry` — the module hub.
- R4.04.1 · Exponential backoff — `/redis-patterns/time-delay-priority/backoff-retry/exponential-backoff` — the curve jitter wraps.
- R4.04.3 · Reusing the schedule set — `/redis-patterns/time-delay-priority/backoff-retry/reuse-the-delayed-zset` — the next dive.
- R1.05 · Cache stampede prevention — `/redis-patterns/caching/cache-stampede-prevention` — jitter applied to TTLs, the same anti-herd move.
- The EchoMQ queue protocol — `/echomq/queue` — the retry path on the wire.
