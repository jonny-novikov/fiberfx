# Lease renewal — keep the lease fresh

> Route: `/redis-patterns/coordination/distributed-locking/lease-renewal` · Dive R2.02.3 · Parent: R2.02
> distributed-locking · Source: `content/fundamental/distributed-locking.md.txt` (*Extending Lock Duration* + *Lock
> Lifecycle*) · Grounding: the generic one-timer-per-worker renewal taught first; the honest applied form — the
> consumer holds the lease for `:lease_ms` (default `30_000`, `consumer.ex:57`) and `EchoMQ.Consumer` runs
> `Jobs.reap/2` (`jobs.ex:357`) on its `:beat_ms` to return an expired lease to pending. The worker-side lock-subkey
> renewal plane is the door to /echomq.

A 30-second lease and a long job will lapse mid-work. The generic fix is to extend the lock before it expires — but
only while the token is still yours. The extend is the token-checked release with one verb swapped:
`if GET == token then PEXPIRE` instead of `DEL`. Renew on a cadence shorter than the lease and a long job holds its
lock for as long as it owns it.

## Extend before the lease expires

The lease is a deadline, and a long job can outrun it. A 30-second `PX` set at acquire is a guess at how long the
work will take; for work that may take longer, the holder extends the lease while it is still held. The extension
resets the TTL — but it must be conditional. Extend the key only if the value under it is still the token the holder
acquired with.

```
-- extend: reset the TTL only if the stored token is still ours
if redis.call("get", KEYS[1]) == ARGV[1] then
  return redis.call("pexpire", KEYS[1], ARGV[2])
else
  return 0
end
```

The shape is the token-checked release with `pexpire` in place of `del`: the same `GET == token` admission, a
different verb. If the token still matches, the TTL is pushed out; if it does not — the lease lapsed and another
client took the key — the script returns `0` and the holder has lost the lock. A holder that renews on a fixed
cadence shorter than the lease keeps the lock for as long as it still owns it, and stops the instant the lock is
gone.

## The lock lifecycle — renewal sits inside the work

The lifecycle the source spells out is: generate a token, acquire (`SET … NX PX`), check the result, do the work,
release with the token-checked script. Renewal sits inside step four. For work that may outrun the lease, the holder
renews on a cadence for the whole duration of the work, then releases.

Renewal is what makes a short lease safe for a long job. A short lease bounds the damage when a holder crashes — a
crashed holder's lock expires in seconds, not minutes. Renewal lets a live holder keep that short, safe lease as long
as it needs it. The two together give a lock that is both **mortal** (it cannot deadlock the key) and **durable** (it
does not expire under a holder still doing the work).

## One timer per job does not scale

The straightforward implementation is one renewal timer per held lock: a job acquires, schedules a timer at half its
lease, the timer fires a single-key extend, reschedules, and cancels on release. For one job that is fine. For a
worker running many jobs at once it is not. K jobs means K timers, K wake-ups per renewal cycle, and K separate
round-trips each cycle. The work each call does is small — a `GET`, a compare, a `PEXPIRE` — but the count grows with
the number of held jobs, and the renewal layer becomes load that scales with concurrency rather than with the work.

## The applied form — the consumer's lease and the reaper

EchoMQ does not renew a worker-held lock on a holder-side timer at all in the shipped claim path. The honest applied
form is simpler and lives on the server clock: the **consumer holds the lease for `:lease_ms`**, and a single loop —
the **reaper** — returns any expired lease to pending. Crash recovery is the server clock, not a holder heartbeat.

`EchoMQ.Consumer` (`echo/apps/echo_mq/lib/echo_mq/consumer.ex`) is one supervised loop that beats on a cadence. Its
loop (`consumer.ex:91`) runs the reaper first on every beat:

```
defp loop(s) do
  check_control()
  {:ok, _} = Jobs.reap(s.conn, s.queue)              # return expired leases to pending
  {:ok, _} = Jobs.promote(s.conn, s.queue, s.pump_batch)
  drain(s)                                            # claim and run ready jobs
  park(s)                                             # BLPOP on the wake key until a wake or the beat elapses
  loop(s)
end
```

`Jobs.reap/2` (`jobs.ex:357`) runs the `@reap` script (`jobs.ex:245`), which reads the server clock and returns every
job in `emq:{q}:active` whose lease score is past `now` back to `emq:{q}:pending`:

```
local t = redis.call('TIME')
local now = t[1] * 1000 + math.floor(t[2] / 1000)
local exp = redis.call('ZRANGEBYSCORE', KEYS[1], '-inf', now, 'LIMIT', 0, 100)   -- KEYS[1] = emq:{q}:active
for _, id in ipairs(exp) do
  redis.call('ZREM', KEYS[1], id)
  -- ... ZADD the id back into emq:{q}:pending at score 0, HSET state = pending ...
end
return #exp
```

The default `:lease_ms` is `30_000` (`consumer.ex:57`). A crashed worker's lease is never renewed, so its deadline
passes; the next reaper beat returns its job to pending; another worker re-leases it by re-claiming. The
`PEXPIRE`-extend of the generic pattern becomes a server-side reaper sweep — no holder-side timer, no per-job
round-trip, one bounded `ZRANGEBYSCORE` per beat. And the re-claim runs `HINCRBY attempts 1` again, so the crashed
worker's stale attempt count fences it out if it ever resumes (the previous dive).

The worker-side lock-subkey renewal plane — the `emq:{q}:job:<id>:lock` subkey a long-running worker holds and
renews, the §6 lock `remove_job` already refuses to clear with the `EMQLOCK` class (`jobs.ex:492`) — is forward work
in the dedicated EchoMQ course. This dive cites the consumer loop and the reaper script as proof the lease recovery
is real, and doors forward to the renewal plane.

## Recap — the reaper renews, the lease is the server clock

A lock with a short lease will lapse under a long job. The generic fix is conditional renewal:
`if GET == token then PEXPIRE`. One timer per job does not scale. EchoMQ's answer is the reaper: the consumer holds
the lease for `:lease_ms`, and on every beat `Jobs.reap` returns any active job whose server-clock deadline has
passed back to pending, where another worker re-leases it by re-claiming. That closes R2.02: lease one holder via the
claim, fence a stale worker on `attempts`, and recover an expired lease with the reaper on the server clock.

## References

### Sources
- [Redis — Distributed Locks](https://redis.io/docs/latest/develop/use/patterns/distributed-locks/) —
  single-instance lock acquisition, owner-token release, and lock extension.
- [Valkey — PEXPIRE](https://valkey.io/commands/pexpire/) — reset a key's time to live in milliseconds; the verb the
  generic extend swaps in for `DEL`.
- [Valkey — ZRANGEBYSCORE](https://valkey.io/commands/zrangebyscore/) — the range read the reaper uses to find every
  lease whose deadline is past the server clock.
- [Valkey — Programmability](https://valkey.io/topics/programmability/) — why the reaper's read-and-move runs as one
  atomic script.

### Related in this course
- [R2.02 · Distributed locking](/redis-patterns/coordination/distributed-locking) — the module hub.
- [R2.02.1 · SET NX PX](/redis-patterns/coordination/distributed-locking/set-nx-px) — the claim lease the reaper
  recovers.
- [R2.02.2 · Fencing tokens](/redis-patterns/coordination/distributed-locking/fencing-tokens) — why a re-claimed job
  fences the lapsed worker.
- [/echomq/protocol](/echomq/protocol) — the EchoMQ protocol, where the worker-side lock-subkey renewal plane is taught.
