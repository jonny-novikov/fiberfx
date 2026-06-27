# Distributed locking

> Route: `/redis-patterns/coordination/distributed-locking` · Module R2.02 · Source:
> `content/fundamental/distributed-locking.md.txt`
> · Grounding: the honest applied form — EchoMQ has no `SET NX PX` mutex. Its "lock" is the **claim lease**:
> `EchoMQ.Jobs.claim/3` (`echo/apps/echo_mq/lib/echo_mq/jobs.ex:283`) runs the `@claim` script
> (`jobs.ex:126`), which `ZADD`s the job into the `active` set scored `now + lease_ms` on the server clock, and
> `HINCRBY <jobkey> attempts 1` — `attempts` is the **fencing token**. `@complete` / `@retry` refuse a stale token
> with `EMQSTALE … token mismatch`; `EchoMQ.Consumer` runs `Jobs.reap` on its beat to return an expired lease to
> pending. One verified excerpt, then a door forward to the dedicated EchoMQ course.

Implement mutual exclusion across distributed processes using `SET key value NX PX timeout` for atomic lock
acquisition with automatic expiration. Distributed systems often need mutual exclusion to prevent a race when many
processes reach for one shared resource at the same time. This module covers the single-instance lock, release with
owner verification, and lock extension.

## The basic lock

A Valkey lock is the `SET` command with two options and a token:

```
SET resource:lock <token> NX PX 30000
```

The command sets the key only if it does not exist (`NX`), attaches a 30-second expiry (`PX 30000`), and stores a
unique token that names this lock acquisition. If the command returns OK, the lock was acquired; if it returns nil,
another client holds the lock. The whole acquire is one command, so nothing interleaves between the existence check
and the write.

## Why NX, PX, and a token

Each part of the command carries one guarantee:

- **`NX` (not exists)** admits exactly one holder. If two clients run the command at the same instant, only one
  receives OK.
- **`PX` (expiry)** makes the lock mortal. If the holder crashes without releasing, the lease expires on its own; a
  lock with no expiry is held until a process clears it by hand, so a crash becomes a deadlock.
- **The token** — a random value, typically a UUID — names this acquisition. It is what makes release safe: a holder
  deletes the lock only when the stored token still matches its own.

## Releasing the lock safely

Never release a lock with a bare `DEL`. A blind delete risks removing a different client's lock. The hazard:

1. Client A acquires the lock with token `abc`.
2. Client A runs long; the lease expires.
3. Client B acquires the lock with token `xyz`.
4. Client A finishes and runs `DEL`.
5. Client A has now deleted client B's lock.

The safe release is a Lua script that checks the token before deleting, so the delete and the check are one atomic
unit:

```
if redis.call("get", KEYS[1]) == ARGV[1] then
  return redis.call("del", KEYS[1])
else
  return 0
end
```

Run it with `EVAL <script> 1 resource:lock abc-token-123`. The lock is deleted only when the token matches, so a
late delete from a stale holder becomes a no-op.

## Lock lifecycle

The full sequence is five steps: generate a unique token; acquire with `SET resource:lock <token> NX PX 30000`;
check the result (OK → proceed, nil → another client holds it); do the protected work; release with the token-checked
Lua script. When acquisition fails, a client has three options — retry with backoff (increasing delays), fail
immediately (return an error to the caller), or block and poll until the lock frees.

## Extending the lease

For work that may run longer than the TTL, the holder extends the lock before it expires — and only if it still owns
the lock:

```
if redis.call("get", KEYS[1]) == ARGV[1] then
  return redis.call("pexpire", KEYS[1], ARGV[2])
else
  return 0
end
```

This resets the TTL only when the token still matches. A modern single-command alternative (Redis 6.2+) is
`SET resource:lock <new_token> XX GET`: `XX` requires the key to exist and `GET` returns the old value, which the
application checks before treating the lock as extended. For a conditional TTL update the Lua script stays the
clearer tool.

## Limitations

Single-instance Valkey locking has one structural limitation: if the master fails after a client acquires a lock but
before the lock replicates, the lock can be lost during failover, and two clients can then both hold it at once.
Applications that need a stronger guarantee reach for the **Redlock algorithm** (locks from several independent
instances), a consensus system such as etcd or ZooKeeper, or a design that tolerates the rare violation by making the
protected operation idempotent. Redlock is the contrast taught in the next module; this one stays on the
single-instance lock.

## Common mistakes

Three mistakes recur, and each turns the lock into a deadlock or a wrong delete:

- **No expiry.** `SET lock token NX` with no `PX` leaves the lock held forever if the holder crashes.
- **A bare `DEL` for release.** May delete another client's lock (the scenario above).
- **A non-atomic acquire.** Separate `SETNX` then `EXPIRE` is a race: a crash between the two leaves a lock with no
  expiry, and that is a deadlock.

```
SETNX lock token    # if the process crashes here...
EXPIRE lock 30      # ...the lock never gets an expiry
```

Always use the combined `SET` with `NX` and `PX`.

## When to use, when to avoid

Use a lock to coordinate access to an external resource, to prevent duplicate job execution, for leader election, or
to serialize updates to shared state. Avoid it for high-frequency operations where contention would be severe, for
scenarios that demand absolute correctness (reach for a consensus system), and when the protected resource already
handles concurrent access safely.

## The pattern, applied — the claim lease, not a mutex

A Valkey lock makes one holder own a resource at a time, with `PX` guaranteeing the lock is mortal and the token
making release safe. EchoMQ does not implement a `SET NX PX` mutex at all. Its mutual exclusion is the **claim
lease**: a job leased to exactly one worker for `lease_ms`, on the server clock, with the attempt count as the
fence.

`EchoMQ.Jobs.claim/3` (`echo/apps/echo_mq/lib/echo_mq/jobs.ex:283`) runs the `@claim` script (`jobs.ex:126`). The
script `ZPOPMIN`s the oldest pending id, then in the same atomic step does two locking moves:

```
local att = redis.call('HINCRBY', jk, 'attempts', 1)   -- the fencing token, monotone per claim
redis.call('HSET', jk, 'state', 'active')
local t = redis.call('TIME')
local now = t[1] * 1000 + math.floor(t[2] / 1000)
redis.call('ZADD', KEYS[2], now + tonumber(ARGV[2]), id)  -- the lease: active set, scored now + lease_ms
```

`KEYS[2]` is `emq:{q}:active`; the score is the lease deadline read from the server's own clock (`redis.call('TIME')`
inside the script), so the lease never depends on the worker's clock. The claim returns `{id, payload, att}` — the
job, its payload, and the attempt count the worker must present back. That attempt count is the fence: `@complete`
(`jobs.ex:139`) and `@retry` (`jobs.ex:173`) compare the presented token against the stored `attempts` and refuse a
mismatch with `EMQSTALE complete token mismatch` / `EMQSTALE retry token mismatch`. A worker whose lease was reaped
and re-claimed carries a stale `attempts` and is rejected.

The mortal-lease half of the pattern is the reaper, not a holder-side timer. `EchoMQ.Consumer`
(`echo/apps/echo_mq/lib/echo_mq/consumer.ex:93`) beats on a cadence (`:beat_ms`) and on each beat runs
`Jobs.reap/2` (`jobs.ex:357`), whose script returns every expired lease — the ids in `active` whose deadline is past
the server clock — back to `pending`. The default `:lease_ms` is `30_000` (`consumer.ex:57`). A crashed worker's
lease lapses; the reaper returns its job to pending; another worker re-leases it by re-claiming, and the crashed
worker's stale `attempts` fences it out if it ever returns. The `SET NX PX` lock becomes the lease-scored `active`
set; the owner token becomes the monotone `attempts`.

The worker-side lock-renewal plane — the `emq:{q}:job:<id>:lock` subkey that a long-running worker holds and renews,
which `remove_job` already refuses to clear (`jobs.ex:492`, the `EMQLOCK` class) — is forward work in the dedicated
EchoMQ course. This module cites the claim lease as proof the pattern is real and doors forward.

## The three dives

- **R2.02.1 · SET NX PX** — the generic atomic acquire: `NX` for one holder, `PX` for no deadlock, the random token
  for safe release; the `SETNX`+`EXPIRE` race contrasted. The applied form is the lease-scored `active` set, no
  mutex.
- **R2.02.2 · Fencing tokens** — the real one: `attempts` (monotone via `HINCRBY` in `@claim`) is EchoMQ's fence; a
  worker whose lease was reaped and re-claimed carries a stale token and is refused at `@complete` / `@retry` with
  `EMQSTALE`.
- **R2.02.3 · Lease renewal** — the generic one-timer-per-worker renewal, then the honest applied form: the
  consumer holds the lease for `:lease_ms` and the reaper returns an expired lease to pending on `:beat_ms`. The full
  worker-side lock-subkey plane is the door to the EchoMQ course.

## References

### Sources
- [Redis — Distributed Locks](https://redis.io/docs/latest/develop/use/patterns/distributed-locks/) — the
  single-instance lock, the token-checked release, and where Redlock begins.
- [Valkey — SET](https://valkey.io/commands/set/) — the `NX`/`PX`/`GET`/`XX` options behind the one-command acquire
  and extend.
- [Valkey — Programmability](https://valkey.io/topics/programmability/) — atomic script execution: why the
  claim's `HINCRBY` + `ZADD` and the token-checked release run as one indivisible step.
- [Salvatore Sanfilippo — antirez weblog](https://antirez.com/) — the Redis creator on locks, leases, and treating
  expiry as a safety bound rather than a correctness guarantee.

### Related in this course
- [R2 · Coordination & Consistency](/redis-patterns/coordination) — the chapter.
- [R2.01 · Atomic updates](/redis-patterns/coordination/atomic-updates) — the atomic move the claim script performs
  in one step.
- [R2.03 · Redlock](/redis-patterns/coordination/redlock) — the multi-instance contrast EchoMQ deliberately did not
  build.
- [/echomq/protocol](/echomq/protocol) — the EchoMQ protocol, where the worker-side lock-subkey plane is taught in full.
- [/elixir · State](/elixir/pragmatic/state) — the functional-Elixir craft behind the consumer loop.
