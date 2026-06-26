# Capacity planning

> Route: `/redis-patterns/flow-control/worker-concurrency/capacity-planning` · R6.05.3 dive · Redis Patterns Applied
> Identity: BCS contract-sheet, redis-red. Grounded in the real as-built echo data layer (`echo/apps/echo_mq`).

**Plan worker capacity from the structural knobs, not a benchmark: pool width is the concurrent in-flight count,
`:beat_ms` and `:lease_ms` set the claim cadence and the reap window, `:pump_batch` is the release-side knob, and the
rate limiter is the ceiling where the pool is the floor.** Reason in round-trips — how many are outstanding, and how
many jobs each carries — not in measured milliseconds.

## The knobs are on the consumer

Capacity is configured, not discovered. `EchoMQ.Consumer` exposes the tuning surface as `start_link` options, and
each one names a structural property of the loop:

```
start_link(opts):
  :queue           — the queue this loop drains
  :handler         — fn %{id:, payload:, attempts:, group:} -> :ok | {:error, reason}
  :conn | :connector  — the dedicated connector (or options to start one)
  :lease_ms        — the lease window a claimed job holds before it is reapable (default 30_000)
  :beat_ms         — the cadence: how often the loop reaps, promotes, drains, and parks (default 1_000)
  :retry_delay_ms  — the back-off applied to a failed job before it is eligible again (default 1_000)
  :max_attempts    — how many tries before a job is dead-lettered (default 3)
  :pump_batch      — the promote LIMIT per beat (the release-side knob, default 100)
  :metronome       — opt-in: run the POOL path, fed by the queue's one blocker
```

These are levers on the *shape* of the work, not on the speed of the machine. Pool width — set when the pool is
started, not on the consumer — is the count of connectors, and so the count of round-trips that can be outstanding at
once. Together they describe the capacity of a deployment without measuring it.

## Reason in round-trips

The honest unit for planning is the round-trip, because it is the cost the design controls. A claim is one
round-trip and carries one job; a batch claim is one round-trip and carries up to `k` jobs. So the throughput a
deployment can offer is, in round-trips:

- **Pool width** sets how many claim round-trips are outstanding at once. A pool of four carries four; doubling the
  pool doubles the outstanding claims, until the server or the network is the limit.
- **Batch size** sets how many jobs each claim round-trip carries. A batch of eight divides the fetch cost over eight
  jobs; `bclaim/3` is the surface.
- **Claim cadence** (`:beat_ms`) sets how often a consumer reaches for work when the queue is quiet. A parked
  consumer spends no round-trips waiting, so the beat governs the housekeeping rhythm, not the busy-path throughput.

The product — outstanding claims times jobs per claim — is the structural throughput. Measured milliseconds are a
property of a particular machine, network, and load; they are what a benchmark reports, not what a capacity plan is
built from. The plan is in round-trips, and the round-trips come from the knobs.

## The lease window and the release knob

Two knobs are about correctness under failure, and they bound the plan. `:lease_ms` is the window a claimed job
holds before it is considered stalled and reaped. Set it shorter than the time a healthy handler takes and healthy
jobs are reaped mid-flight and run twice; set it far longer than the handler and a genuinely stalled worker holds its
jobs for too long before another worker recovers them. The lease is sized to the handler's real working time with
headroom, and a larger batch claim multiplies the leases a single stall can strand.

`:pump_batch` is the release side, not the claim side. The release cadence — `EchoMQ.Pump` — promotes due scheduled
work and fires repeatables on its own beat, and `:pump_batch` is the promote LIMIT per beat: how many due entries are
released into the pending set at once. It governs how fast delayed work becomes claimable, which is upstream of the
workers. `EchoMQ.Pump` is the release cadence, not the dequeue — it is cited here only as the release-batch knob, and
never as the worker claim loop.

## Ceiling and floor

The pool and the rate limiter pull in opposite directions, and a plan uses both. Pool width and batch size are the
**floor**: they set how much throughput the workers can offer. The rate limiter is the **ceiling**: a per-window
counter that caps how much work is admitted per unit time, regardless of how wide the pool is. A deployment sizes the
pool to keep up with demand and sets the limiter to protect a downstream that cannot absorb the full rate.

So capacity planning is two questions, not one. Can the workers keep up — a floor set by pool width, batch size, and
the lease window. And should they be allowed to — a ceiling set by the rate limiter. The floor is concurrency made
parallel; the ceiling is a budget per window. Neither is the count of BEAM processes.

## The pattern, applied

**Structural knobs ↔ planned throughput.** Pool width, batch size, the claim cadence, and the lease window are the
levers a capacity plan turns; throughput is reasoned in round-trips outstanding times jobs per round-trip, never in
measured milliseconds — and the rate limiter caps the result from above.

In codemojex the scoring consumers drain the `cm` queue. The plan is the pool width for the scoring fleet, the lease
window sized to the scoring handler, and `:pump_batch` for how fast timed game events release work — all reasoned in
round-trips, so the plan holds whatever the day's network latency happens to be. A benchmark would report a number
for one moment; the structural plan holds across moments.

> Sizing a pool against a real production load, recovering stalled leases at scale, and the metrics that confirm the
> plan are the queue's scaling layer, taught in the EchoMQ course.

**Notes on Valkey.** `BLPOP` lets the cadence cost nothing on a quiet queue: a parked consumer holds the connection
on the wake key and spends no round-trips until work arrives or the beat elapses, so `:beat_ms` governs housekeeping,
not busy-path throughput — https://valkey.io/commands/blpop/.

## References

### Sources

- Valkey — *BLPOP* (https://valkey.io/commands/blpop/) — the blocking park that makes the claim cadence free on a
  quiet queue.
- Valkey — *ZPOPMIN* (https://valkey.io/commands/zpopmin/) — the per-claim fetch whose count, outstanding, is the
  unit of a capacity plan.
- Valkey — *Pipelining* (https://valkey.io/topics/pipelining/) — the round-trip model that makes outstanding claims
  the honest planning unit rather than measured time.

### Related in this course

- R6.05 · Worker concurrency (`/redis-patterns/flow-control/worker-concurrency`) — the module hub.
- R6.05.1 · Parallel vs concurrent (`/redis-patterns/flow-control/worker-concurrency/parallel-vs-concurrent`) — pool
  width as the real parallelism the plan sizes.
- R6.05.2 · The per-claim fetch bottleneck
  (`/redis-patterns/flow-control/worker-concurrency/the-per-claim-fetch-bottleneck`) — batch size as the knob that
  divides the fetch cost.
- R6.01 · Rate limiting (`/redis-patterns/flow-control/rate-limiting`) — the ceiling the pool's floor runs beneath.
- /echomq/queue — sizing a pool against a real production load.
- /bcs/bus — Part B3, the Valkey-native bus the consumers drain.
