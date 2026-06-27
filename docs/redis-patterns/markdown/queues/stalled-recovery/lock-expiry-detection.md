# Lock-expiry detection — the lease as the death signal

> **Route:** `/redis-patterns/queues/stalled-recovery/lock-expiry-detection` · **Dive:** R3.03.1
> **Grounding:** `echo/apps/echo_mq/lib/echo_mq/jobs.ex` — `EchoMQ.Jobs.claim/3` (the `@claim` lease mint), the `active` ZSET scored by `now + lease_ms`, the server clock (`TIME`); `EchoMQ.Jobs.reap/2` (`@reap`, the expired-lease scan).

The reaper has to answer one question before it can recover anything: which in-flight job has no live worker? The source's monitor answers it with age — a message older than a timeout is assumed dead. EchoMQ answers it with a **lease**: a deadline a live worker keeps in the future and a dead worker lets pass. Lease in the future ⇒ a live worker holds it. Lease in the past ⇒ recover.

## The lease, minted at claim

When `EchoMQ.Jobs.claim/3` pops the oldest pending job, it does more than hand the worker a payload — it stamps a deadline. The `@claim` script reads the server clock once (`local t = redis.call('TIME')`), computes `now`, and scores the id on the `active` set at `now + lease_ms` (the consumer's default `:lease_ms` is `30_000`). The same `HINCRBY attempts 1` that fences the job is the worker's proof it holds the lease.

    local popped = redis.call('ZPOPMIN', KEYS[1])     -- pending: oldest first
    if #popped == 0 then return {} end
    local id = popped[1]
    local jk = ARGV[1] .. id
    local att = redis.call('HINCRBY', jk, 'attempts', 1)   -- the fencing token
    redis.call('HSET', jk, 'state', 'active')
    local t = redis.call('TIME')                            -- the server clock
    local now = t[1] * 1000 + math.floor(t[2] / 1000)
    redis.call('ZADD', KEYS[2], now + tonumber(ARGV[2]), id)  -- active, scored by lease deadline
    return {id, redis.call('HGET', jk, 'payload'), att}

The score is the death signal. A worker that finishes calls `complete` and the id leaves `active`. A worker still working extends its lease (it re-claims or re-scores the deadline forward). A worker that dies does neither — and its score stays a fixed instant that the clock walks past.

## Detect by reading the clock, not the lock

Because the deadline lives in the score, detection is one range read: `ZRANGEBYSCORE active -inf now`, every member at or below the current server clock. There is no per-job key to probe, no `EXISTS` round trip per id — the in-flight set is already a min-heap on the deadline, so the expired members are the cheap prefix. `EchoMQ.Jobs.reap/2` does exactly this and returns each expired id to `pending` once:

    local t = redis.call('TIME')
    local now = t[1] * 1000 + math.floor(t[2] / 1000)
    local exp = redis.call('ZRANGEBYSCORE', KEYS[1], '-inf', now, 'LIMIT', 0, 100)
    for _, id in ipairs(exp) do
      redis.call('ZREM', KEYS[1], id)
      redis.call('ZADD', KEYS[2], 0, id)        -- back to pending
      redis.call('HSET', ARGV[1] .. 'job:' .. id, 'state', 'pending')
    end

The clock is the server's, read inside the script. A caller's clock could be skewed, and a lease that expired on a fast client but not on the server would redeliver a job whose worker is still alive. Reading `TIME` inside the eval means the deadline that was written and the clock that reads it are the same clock — the master invariant for every leased transition on the bus.

## Live, slow, dead — three scores

The lease distinguishes the three states a worker can be in without a separate health channel:

- **Live and fast** — completes before the deadline; the id leaves `active`, never seen by a sweep.
- **Live but slow** — extends the lease before it lapses; the deadline moves forward, so the slow worker is never reclaimed out from under itself.
- **Dead** — neither completes nor extends; the deadline passes, and the next sweep returns the job to `pending`.

The lease length is the only tuning knob: too short and a slow-but-alive worker is reclaimed mid-job (a needless redelivery); too long and a dead worker's job waits the full lease before recovery. The default `30_000` ms is the consumer's; a workload with long handlers raises it, and a workload that needs fast recovery lowers it and extends the lease on a heartbeat.

## The bridge

- **The pattern:** a separate reaper finds a stalled job by asking whether its worker is still alive — the source measures that as "older than a timeout."
- **Its EchoMQ application:** the answer is a lease deadline on the `active` ZSET, scored by `now + lease_ms` from the server clock; `ZRANGEBYSCORE active -inf now` reads every member whose lease lapsed — no per-job probe, one range read.

The take: detection is not a health check on each worker; it is one range read over a set already sorted by death time.

## References

### Sources

- [Valkey — *Sorted Sets*](https://valkey.io/topics/sorted-sets/) — the `active` set is a ZSET scored by lease deadline; `ZRANGEBYSCORE -inf now` is the expired prefix.
- [Valkey — *ZRANGEBYSCORE*](https://valkey.io/commands/zrangebyscore/) — read every member whose score is at or below the server clock.
- [Valkey — *SET*](https://valkey.io/commands/set/) — `SET key value PX <ms>`, the expiry primitive a per-job lock would use; the lease puts the same idea in a score.
- [Redis — *EVAL / scripting*](https://redis.io/commands/eval/) — reading `TIME` inside the script binds the deadline and the clock that reads it.

### Related in this course

- [R3.03 · Stalled recovery](/redis-patterns/queues/stalled-recovery) — the module hub.
- [R3.03.2 · Two-phase mark/recover](/redis-patterns/queues/stalled-recovery/two-phase-mark-recover) — the stall count, once a job is detected.
- [R3.03.3 · Atomic vs non-atomic](/redis-patterns/queues/stalled-recovery/atomic-vs-non-atomic) — why the detect-and-move is one step.
- [R4 · Time, Delay & Priority](/redis-patterns/time-delay-priority) — the sorted set as a clock, the same structure the lease uses.
- [/echomq/queue](/echomq/queue) — the EchoMQ Queue pillar: the lease and the worker fetch loop in depth.
