# R4.04.3 · Reusing the schedule set

> Route: `/redis-patterns/time-delay-priority/backoff-retry/reuse-the-delayed-zset` · dive 3 of R4.04

A retry adds no new structure. It re-enters the same schedule set R4.01's delayed queue uses, scored by `now + delay_ms`, and the same promotion sweep brings it back when due. One sorted set, two uses: a first-time delayed job and every retry.

## §1 — One sorted set, two callers

The delayed queue (R4.01) schedules a job for a future time by ZADDing it onto a sorted set scored by its fire-time, then sweeping the due range back to pending. A retry is the same three moves with one difference: the score comes from a backoff formula instead of a caller-supplied time. Both write to the same key, `emq:{<queue>}:schedule`; both are swept by the same promotion. The schedule set does not know — and does not need to know — which of its members is a first-time delayed job and which is a retry. The score is the only thing that matters.

## §2 — The reschedule (`retry/7`)

`EchoMQ.Jobs.retry/7` is token-fenced and reads the row's `attempts` before it does anything. Under the max-attempts ceiling, it reads the server clock, sets the row's state to `scheduled`, and ZADDs the job onto the schedule set at `now + delay_ms` — the literal delay the host computed with `EchoMQ.Backoff`:

```lua
-- @retry (jobs.ex) — the non-terminal arm, verbatim
local t = redis.call('TIME')
local now = t[1] * 1000 + math.floor(t[2] / 1000)
redis.call('HSET', KEYS[4], 'state', 'scheduled')
redis.call('ZADD', KEYS[2], now + tonumber(ARGV[3]), ARGV[1])
return 'scheduled'
```

`KEYS[2]` is the schedule set, `ARGV[3]` is the literal `delay_ms`, `ARGV[1]` is the job id. The script reschedules at a delay it is given; it never computes a curve. At the max-attempts ceiling the other arm of the same script sets the row `dead` and ZADDs the job onto the morgue set instead — the retry gives up.

## §3 — The sweep (`promote/3`)

The promotion that brings a retry back is the same one R4.01 teaches for delayed jobs. `EchoMQ.Jobs.promote/3` reads the server clock and ZRANGEBYSCOREs the schedule set from `-inf` to `now`, then moves each due member back to pending:

```lua
-- @promote (jobs.ex) — the due-range sweep, the non-group path
local due = redis.call('ZRANGEBYSCORE', KEYS[1], '-inf', now, 'LIMIT', 0, tonumber(ARGV[2]))
for _, id in ipairs(due) do
  redis.call('ZREM', KEYS[1], id)
  redis.call('ZADD', KEYS[2], 0, id)         -- a non-group job → the pending set
  redis.call('HSET', p .. 'job:' .. id, 'state', 'pending')
end
return #due
```

`KEYS[1]` is the schedule set, `KEYS[2]` is pending. A retry that was ZADDed at `now + delay_ms` falls into this range once the clock passes its score, and the sweep moves it back to pending exactly as it moves a first-time delayed job. No retry-specific path runs; the retry becomes due like any other member.

## §4 — Why one structure is enough

Reuse is the point, not a coincidence. The schedule set is a timer wheel keyed by score; anything with a future fire-time belongs on it. A delayed job's fire-time is a caller's clock; a retry's fire-time is a backoff curve; a scheduler's next run is an interval — all three are scores on the same sorted set, swept by the same promotion. Adding a separate "retry set" would duplicate the sweep, the promotion, and the morgue handling for no gain. One sorted set, scored by fire-time, is the whole delay machinery — and the retry is one more caller of it.

## The bridge — pattern to application

- **The pattern:** a retry is a delayed job whose score is a backoff delay; it rides the same sorted set, the same ZADD, and the same due-range sweep the delayed queue uses — no new structure.
- **Its EchoMQ application:** `EchoMQ.Jobs.retry/7` ZADDs the job onto `emq:{<queue>}:schedule` at `now + delay_ms`; `EchoMQ.Jobs.promote/3` ZRANGEBYSCOREs the due range and moves it back to pending — the same machinery R4.01 teaches for first-time delayed jobs.

## References

### Sources

- Redis — *ZADD* — https://redis.io/commands/zadd/ — re-add the failed job to the schedule set at its backoff fire-time.
- Redis — *ZRANGEBYSCORE* — https://redis.io/commands/zrangebyscore/ — the due-range sweep that brings a retry back to pending.
- Valkey — *Sorted sets* — https://valkey.io/topics/data-types/ — the timer-wheel both the delayed job and the retry ride.
- Redis — *Documentation* — https://redis.io/docs/ — scoring and range queries in context.

### Related in this course

- R4.04 · Backoff & retry — `/redis-patterns/time-delay-priority/backoff-retry` — the module hub.
- R4.04.2 · Jitter & the thundering herd — `/redis-patterns/time-delay-priority/backoff-retry/jitter-thundering-herd` — the previous dive.
- R4.01 · Delayed queue — `/redis-patterns/time-delay-priority/delayed-queue` — the schedule-set machinery this reuses.
- R4.02 · Schedulers — `/redis-patterns/time-delay-priority/schedulers` — recurring jobs on the same clock.
- The EchoMQ queue protocol — `/echomq/queue` — the schedule set, the retry, and the promotion in depth.
