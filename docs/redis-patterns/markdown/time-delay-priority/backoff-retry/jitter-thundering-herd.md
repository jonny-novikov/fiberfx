# R4.04.2 · Jitter & the thundering herd

> Route: `/redis-patterns/time-delay-priority/backoff-retry/jitter-thundering-herd` · dive 2 of R4.04

Exponential backoff alone has a failure mode. When many jobs fail at the same instant, they all compute the same delay and all re-fire at the same future millisecond — a synchronized spike that hits the recovering dependency at once. Jitter spreads the retries across a window so the herd disperses.

## The thundering herd

A dependency goes down. Every job that needed it fails in the same window — say a thousand jobs failing within the same second. Each runs the same exponential formula with the same base and the same attempt number, so each computes the *same* delay. They all re-schedule for the same future millisecond. When that millisecond arrives, all thousand re-fire together.

The dependency, perhaps newly back on its feet, takes the full thousand-job spike in one instant and may fall over again — which schedules a thousand more retries for the next backoff window, and the spike repeats. Backoff was supposed to space the load out; without jitter it re-synchronizes it. The herd is the cost of every member computing an identical delay from identical inputs.

## Jitter spreads the window

The fix is to add controlled randomness to each delay so the retries land across a window instead of on a point. `EchoMQ.Backoff` applies it in `apply_jitter/2`. For a jitter fraction in (0, 1] it widens the delay into a band:

```elixir
defp apply_jitter(delay, jitter) when jitter > 0 and jitter <= 1 do
  min_delay = trunc(delay * (1 - jitter))
  jitter_range = trunc(delay * jitter * 2)
  min_delay + :rand.uniform(jitter_range + 1) - 1
end
```

`min_delay` is the floor — the computed delay reduced by the jitter fraction. `jitter_range` spans twice the fraction, so the band runs from `delay × (1 - jitter)` up to `delay × (1 + jitter)`. `:rand.uniform` picks a point inside it, independently for each job. With `jitter: 0.2` on a 4000 ms delay, `min_delay` is 3200, `jitter_range` is 1600, and each retry lands somewhere in `[3200, 4800]` — the computed delay plus or minus twenty percent. A thousand jobs that would have re-fired on one millisecond now scatter across a 1600 ms window, a few per millisecond instead of all at once.

The doc example carries it: `calculate(:exponential, 3, 1000, jitter: 0.2)` returns *about* 4000 — about, not exactly, because each call draws a different point in the band. The default config sets `jitter: 0.2`, so the spread is on by default. A jitter of `0` (the `apply_jitter(delay, 0)` clause) returns the delay unchanged — that is the synchronized case, the herd.

## Jitter applies to fixed backoff too

The herd is not exclusive to exponential schedules. A fixed backoff — the same base every attempt — has the same flaw: a batch that fails together re-fires together. `EchoMQ.Backoff`'s `:fixed` clause routes through the same jitter: `apply_jitter(base_delay, jitter)`. So a `%{type: :fixed, delay: 5_000, jitter: 0.2}` config spaces a batch's retries across `[4000, 6000]` exactly the way the exponential one does. Jitter is the herd-breaker; the strategy (fixed or exponential) only decides the center of the band, not whether it is spread.

## Where this is heading — EchoMQ 2.0

Jitter is computed in `EchoMQ.Backoff` before the delay is written, so the spread is decided in Elixir, not in the key. EchoMQ 2.0 renames the delayed key from `emq:{queue}:delayed` to `emq:{queue}:delayed` and records `meta.version` as `echomq:2.0.0`, but `apply_jitter/2` is unchanged by the break — the band math runs over the delay value, not the keyspace. The herd-breaking this dive teaches works the same on either prefix.

## The bridge — pattern to application

- **The pattern.** A synchronized batch of retries re-fires as one spike; jitter scatters each delay across a window so the load spreads.
- **In EchoMQ.** `apply_jitter(delay, jitter)` returns `min_delay + :rand.uniform(jitter_range + 1) - 1`, where `min_delay = trunc(delay × (1 - jitter))` and `jitter_range = trunc(delay × jitter × 2)` — so `jitter: 0.2` spreads a 4000 ms delay across `[3200, 4800]`. Each job draws its own point.

The takeaway: fixed-and-exact delays re-synchronize a failed batch into a spike; jitter widens each delay into a band and draws an independent point per job, so the herd disperses across a window instead of hitting on one millisecond.

## References

### Sources

- [Redis — *ZADD*](https://redis.io/commands/zadd/) — the write that places each jittered retry at its own fire-time score.
- [Redis — *Sorted sets*](https://redis.io/docs/latest/develop/data-types/sorted-sets/) — the timer-wheel the spread retries scatter across.
- [BullMQ — *the queue protocol*](https://bullmq.io/) — the backoff-with-jitter protocol EchoMQ ports.

### Related in this course

- R4.04 · Backoff & retry — `/redis-patterns/time-delay-priority/backoff-retry`
- R4.04.1 · Exponential backoff — `/redis-patterns/time-delay-priority/backoff-retry/exponential-backoff`
- R4.04.3 · Reusing the delayed ZSET — `/redis-patterns/time-delay-priority/backoff-retry/reuse-the-delayed-zset`
- R4.01 · The delayed queue — `/redis-patterns/time-delay-priority/delayed-queue`
- E6 · Lifecycle controls — `/echomq/lifecycle`
