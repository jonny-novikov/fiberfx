# SET NX PX — the atomic acquire

> Route: `/redis-patterns/coordination/distributed-locking/set-nx-px` · Dive R2.02.1 · Parent: R2.02
> distributed-locking · Source: `content/fundamental/distributed-locking.md.txt` (*The Basic Lock* · *Why These
> Options Matter* · *Common Mistakes*) · Grounding: the generic mutex `SET key token NX PX ms` taught as the
> contrast; the applied form is the lease-scored `active` set — `EchoMQ.Jobs.claim/3`'s `@claim` script `ZADD`s the
> job into `emq:{q}:active` scored `now + lease_ms`, never a `SET NX PX` mutex.

A lock is acquired with a single `SET`: one holder, a mortal lease, and a token to release it safely.
`SET resource:lock <token> NX PX 30000` reads-and-writes in one atomic step on the server. `NX` admits exactly one
holder; `PX` attaches a TTL so a crashed holder cannot deadlock the resource; the random token names this
acquisition, so a later release deletes only this lock.

## The basic lock

A lock is the `SET` command with three options at once. One command carries the whole acquire.

```
SET resource:lock <token> NX PX 30000
```

The command sets the key only if it does not exist (`NX`), attaches a 30-second expiration (`PX 30000`), and stores
a unique token that identifies this acquisition. If `SET` returns OK, the lock was acquired. If it returns nil,
another client holds the lock and this caller did not get it.

That single reply is the whole admission test. There is no separate "is the lock free" read to race against the
write: `SET … NX` reads-and-writes in one atomic step on the server, so of many callers issuing it in the same
instant, exactly one finds the absent key and writes, and the rest find the now-present key and get nil.

## Why NX, PX, and a token

Each option closes a distinct failure, and all three are needed. Drop any one and a specific hazard returns.

- **NX (only if not exists)** is the mutual exclusion. Without it, a plain `SET` would overwrite a held lock, and two
  clients would both proceed as the owner.
- **PX (expiration)** is the deadlock guard. The expiry makes the lock a *lease*: it lapses on its own, so a crashed
  holder is eventually evicted and the resource frees.
- **The token** is a random value naming *this* acquisition. It is needed for safe release: a release must delete the
  lock only when this token still matches, so a caller never deletes a lock that has since expired and been
  re-acquired.

`NX` without `PX` deadlocks on a crash. `PX` without `NX` lets two holders in. A lock without a token is a delete
waiting to hit the wrong client. The one command carries all three.

## The non-atomic acquire is a race

The common mistake is to acquire the lock and set its expiry as two separate commands.

```
SETNX lock <token>    # if the process crashes here...
EXPIRE lock 30        # ...this never runs — the lock has no expiry
```

`SETNX` sets the key if absent; `EXPIRE` attaches the TTL afterward. Between the two there is a window. If the
process crashes after `SETNX` succeeds but before `EXPIRE` runs, the lock exists with no expiration. Nothing will
ever evict it. The next caller's `SETNX` fails forever, and the resource is deadlocked — the exact outcome `PX` was
meant to prevent, reintroduced by splitting the acquire in two. The fix is to make the acquire one command:
`SET lock <token> NX PX 30000` sets the key and its TTL together.

## The applied form — EchoMQ leases, it does not mutex

EchoMQ has no `SET NX PX` mutex and no lock-manager. Its mutual exclusion is the **claim lease**: the same "one
holder, mortal hold" idea, expressed as a sorted-set entry instead of a string key. `EchoMQ.Jobs.claim/3`
(`echo/apps/echo_mq/lib/echo_mq/jobs.ex:283`) runs the `@claim` script (`jobs.ex:126`), which in one atomic step
pops the oldest pending id and leases it:

```
local popped = redis.call('ZPOPMIN', KEYS[1])   -- KEYS[1] = emq:{q}:pending
if #popped == 0 then return {} end
local id = popped[1]
local jk = ARGV[1] .. id
local att = redis.call('HINCRBY', jk, 'attempts', 1)        -- the fence
redis.call('HSET', jk, 'state', 'active')
local t = redis.call('TIME')
local now = t[1] * 1000 + math.floor(t[2] / 1000)
redis.call('ZADD', KEYS[2], now + tonumber(ARGV[2]), id)    -- KEYS[2] = emq:{q}:active, scored now + lease_ms
return {id, redis.call('HGET', jk, 'payload'), att}
```

The lease is not a `PX` on a string key — it is the job's score in `emq:{q}:active`, computed `now + lease_ms` from
the server's own clock (`redis.call('TIME')` inside the script). One worker holds the job because `ZPOPMIN` removes
it from pending atomically; the lease bounds the hold because a later `Jobs.reap` returns any expired score to
pending. The `SET … NX` admission becomes the atomic `ZPOPMIN`; the `PX` expiry becomes the server-clock score.

The lease deadline is read inside the script, so there is no two-command gap to race — the `SETNX`+`EXPIRE` hazard
cannot exist here because the whole transition is one EVAL. The door at the bottom links to the EchoMQ course, where
the worker-side lock-subkey plane is taught in full.

## Recap — one command, or a race

A lock acquires in one command: `SET resource:lock <token> NX PX 30000`. `NX` admits one holder; `PX` makes the lock
mortal; the random token names this acquisition for a safe release. Split the acquire into `SETNX` then `EXPIRE` and
a crash in the gap leaves a lock with no expiry — a deadlock. EchoMQ does not run a mutex at all: its `@claim` script
leases the job into `emq:{q}:active` scored on the server clock, the atomic equivalent of one holder under a mortal
TTL. The next dive makes the fence explicit with `attempts`.

## References

### Sources
- [Redis — Distributed Locks](https://redis.io/docs/latest/develop/use/patterns/distributed-locks/) — the
  single-instance lock, the one-command acquire, and where Redlock begins.
- [Valkey — SET](https://valkey.io/commands/set/) — the `NX` and `PX` options behind the atomic acquire, and why
  they are one command.
- [Valkey — ZADD](https://valkey.io/commands/zadd/) — the sorted-set write the claim lease uses to score a job by
  its lease deadline.

### Related in this course
- [R2.02 · Distributed locking](/redis-patterns/coordination/distributed-locking) — the module hub.
- [R2.02.2 · Fencing tokens](/redis-patterns/coordination/distributed-locking/fencing-tokens) — `attempts` is the
  fence; the next dive.
- [R2.01 · Atomic updates](/redis-patterns/coordination/atomic-updates) — why the whole claim is one Lua EVAL.
- [/echomq](/echomq) — the EchoMQ protocol, where the worker-side lock-subkey plane is taught.
