# R4.04.1 · Exponential backoff

> Route: `/redis-patterns/time-delay-priority/backoff-retry/exponential-backoff` · dive 1 of R4.04

The formula: `delay = base × 2^(attempts-1)`. Attempt 1 waits `base`, attempt 2 waits `2 × base`, attempt 3 waits `4 × base`. The owner of this curve is a host-side pure function, `EchoMQ.Backoff.delay_ms/2` — not the wire.

## §1 — The doubling curve

Exponential backoff multiplies the wait by two on each failed attempt. With a `base` of 100 ms the schedule is 100, 200, 400, 800, 1600 — the gap between retries grows as fast as the failures persist. A dependency that recovers quickly costs one short delay; a dependency that stays down is hit less and less often, which is exactly what a struggling service needs.

The exponent is the attempt that just failed, minus one. `attempts = 1` (the first failure) gives `2⁰ = 1`, so the first retry waits exactly `base`. This anchors the curve: the first retry is fast, and each subsequent one doubles.

## §2 — The clamp

An unbounded curve is a hazard. After 20 attempts `2¹⁹ × base` is enormous — a job that would not re-fire for years. Exponential backoff in practice carries a `cap`: the delay is `min(base × 2^(attempts-1), cap)`. The curve climbs, then holds flat at the ceiling. A clamp turns an exponential into a bounded ramp that protects the dependency without parking the job forever.

## §3 — The formula owner is host-side

In the real bus the curve lives **above the wire**, in `EchoMQ.Backoff.delay_ms/2` — a pure function from a policy and an attempt count to a literal `delay_ms`. No process, no clock, no I/O; a consumer can compute, table, and test its retry cadence without a server. The wire takes a literal delay and never computes a curve. The exponential clause is one `min`:

```elixir
# EchoMQ.Backoff.delay_ms/2 — the :exponential clause (verbatim)
def delay_ms({:exponential, base, cap}, attempts) do
  raw = base * Bitwise.bsl(1, attempts - 1)   # base × 2^(attempts-1)
  min(raw, cap)                                # clamped at the ceiling
end
```

Its own doctests pin the curve: `delay_ms({:exponential, 100, 10_000}, 1)` is `100`; `delay_ms({:exponential, 100, 10_000}, 3)` is `400`; `delay_ms({:exponential, 100, 10_000}, 20)` is `10000` — the cap. The shift is exact-integer; the cap holds the curve from overflowing past the ceiling.

## §4 — The literal delay crosses to the wire

`EchoMQ.Jobs.retry/7` takes that literal `delay_ms` as its fifth argument and ZADDs the job onto the schedule set at `now + delay_ms` on the server clock. The wire receives one number — the delay — and never the formula that produced it. That separation is the design: the backoff math is a value a consumer owns and tests; the reschedule is the wire's only job.

## The bridge — pattern to application

- **The pattern:** exponential backoff waits `base × 2^(attempts-1)`, clamped at a cap, so each retry waits twice as long and a stubborn job ramps to a ceiling rather than re-firing forever.
- **Its EchoMQ application:** `EchoMQ.Backoff.delay_ms({:exponential, base, cap}, attempts)` computes the literal delay host-side; `EchoMQ.Jobs.retry/7` carries it to the wire and schedules the job at `now + delay_ms`.

## References

### Sources

- Redis — *ZADD* — https://redis.io/commands/zadd/ — re-add the job to the schedule set at the backoff fire-time.
- Redis — *Documentation* — https://redis.io/docs/ — sorted sets and scoring in context.
- Valkey — *Sorted sets* — https://valkey.io/topics/data-types/ — the structure the schedule set is.

### Related in this course

- R4.04 · Backoff & retry — `/redis-patterns/time-delay-priority/backoff-retry` — the module hub.
- R4.04.2 · Jitter & the thundering herd — `/redis-patterns/time-delay-priority/backoff-retry/jitter-thundering-herd` — the next dive.
- R4.01 · Delayed queue — `/redis-patterns/time-delay-priority/delayed-queue` — the schedule-set machinery the delay rides.
- The EchoMQ queue protocol — `/echomq/queue` — the retry path on the wire.
- Functional Programming in Elixir — `/elixir` — the pure-function craft behind the backoff vocabulary.
