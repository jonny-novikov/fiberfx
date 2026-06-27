# The majority of N

> Route: `/redis-patterns/coordination/redlock/majority-of-n` · Dive R2.03.1 · Source:
> `content/fundamental/redlock.md.txt`
> · Grounding (contrast): EchoMQ holds **one** lease per job on **one** Valkey — the `@claim` script
> (`echo/apps/echo_mq/lib/echo_mq/jobs.ex:126`, run by `claim/3` at jobs.ex:283) stamps `ZADD active now + lease_ms
> <id>` against a single server clock, no majority of N. A lapsed lease is reclaimed by `Jobs.reap`
> (`consumer.ex:93`) and the work is idempotent, so a lost lease is a recovered re-claim, not corruption.

One Redis node down is no lock at all. Acquire on a majority of N independent masters, and a lock survives the
failure of a minority.

Redlock runs N independent Redis masters — typically five, no replication between them — and counts the lock as held
only on a majority: N/2+1, three of five. Two masters can be down and a client still reaches three. The acquire is
time-checked end to end: read clock `T1`, `SET` on each, read `T2`, and a lock is held only when the votes clear the
majority line **and** the elapsed acquire fits inside the lease. The contrast — EchoMQ's **one** lease per job on a
single Valkey — is below.

## Why a majority of N

Redlock runs N independent Redis masters — typically five — with **no replication between them**. A lock counts as
held only when a client got `OK` on a majority of instances: `N/2+1`, so at least three of five. The number is what
buys the fault tolerance.

With five masters, the majority line is three. Two masters can be down or unreachable and a client can still reach
three of the remaining — the lock is still acquirable. That is the property a single-instance lock cannot offer: one
node down is no lock at all. The majority also keeps two clients from both holding the lock. Two disjoint majorities
of five cannot exist — any two sets of three share at least one master — so the first client to claim three has
claimed a master the second cannot also claim, and the second falls short of its own majority.

**Independence is the whole point.** Each master must be fully independent: no replication, no clustering, ideally in
different availability zones. A replicated pair is not two votes — it is the single-instance failover race wearing a
second hat. The exact gap Redlock removes (a master crashing before its write reaches a replica, a promoted replica
that carries no record of the lock) reopens the moment two of the N masters are a master and its replica.

## The acquire protocol, in full

The acquire is time-checked end to end, because a slow acquire can eat the lease before the work begins. The source
spells out six steps:

```text
# 1. read clock T1
T1 = now_ms()
# 2. on each of N instances, with a 5–50 ms per-instance timeout:
SET resource_name <random_value> NX PX 30000
# 3. read clock T2 → elapsed = T2 − T1
# 4. ACQUIRED only if (OK count ≥ N/2+1) AND (elapsed < TTL)
# 5. validity = TTL − elapsed − clock_drift_allowance
# 6. else → release on ALL instances at once, wait a random delay, retry
```

The random value is unique across every client and every attempt — at least 20 bytes from a cryptographically
secure source. The short per-instance timeout (5–50 ms) is what keeps an unavailable node from stalling the whole
acquire: a master that does not answer within the window is counted as a miss, not waited on. The release runs the
same token-checked Lua script on every instance — `GET == token then DEL` — so a delete lands only on a lock this
client still owns, and it is attempted on **all** N instances, even those where the acquire appeared to fail.

## The two gates behind "held"

The vote and the time-check are two independent gates, and a held lock has to clear both. The **vote** gate is the
majority: count the `OK` responses across the N masters. Below `N/2+1`, the acquire failed — the lock is released on
all instances and retried after a random delay.

The **time** gate is `elapsed < TTL`. This is the gate that makes Redlock immune to a slow network during the
acquire. Suppose all five masters returned `OK`, but the round-trips took 31 seconds against a 30-second TTL. By the
time the last `OK` arrived, the first lock had already expired — so the algorithm treats the whole acquire as invalid
even though five of five responded, and releases everywhere.

## The contrast — EchoMQ holds one lease on one Valkey

Redlock spends five independent masters to keep a lock through the failure of a minority. EchoMQ does not take that
road. Its per-job lock is the **claim lease**, and it lives on **one** Valkey, reached through **one**
`EchoMQ.Connector`. The `@claim` script (`echo/apps/echo_mq/lib/echo_mq/jobs.ex:126`, run by `Jobs.claim/3` at
jobs.ex:283) is one atomic Lua transition: pop the next id, increment the fence, mark the row active, read **one**
server clock, and stamp the lease.

```lua
-- @claim (jobs.ex:126) — one lease per job, on one Valkey, against one server clock
local popped = redis.call('ZPOPMIN', KEYS[1])    -- the next pending id
if #popped == 0 then return {} end
local id = popped[1]
local jk = ARGV[1] .. id
local att = redis.call('HINCRBY', jk, 'attempts', 1)   -- the monotone fence
redis.call('HSET', jk, 'state', 'active')
local t = redis.call('TIME')                           -- one server clock, not a majority
local now = t[1] * 1000 + math.floor(t[2] / 1000)
redis.call('ZADD', KEYS[2], now + tonumber(ARGV[2]), id)   -- the lease in the active set
return {id, redis.call('HGET', jk, 'payload'), att}
```

There is no majority of N and no vote. The trade is sound for a job queue because the protected work is made
**idempotent** and a lost lease is a recoverable re-claim, not corruption. When a lease lapses, `Jobs.reap`
(`echo/apps/echo_mq/lib/echo_mq/consumer.ex:93`) returns the expired entry from `active` to `pending` on the same
server clock, and the next worker re-claims it; because the handler is idempotent, the re-run is safe. So the rare
failure that drops a lock becomes a rare double-run the queue recovers from — the exact outcome Redlock spends five
masters to avoid, made harmless instead.

| The pattern | Its EchoMQ application |
| --- | --- |
| Redlock counts votes across N independent masters: a lock is held only on a majority, so a minority of node failures does not drop it — fault tolerance bought with five instances and the time-check. | `@claim` holds **one** lease per job on a single Valkey against **one** server clock (`redis.call('TIME')`), with `attempts` (`HINCRBY`) the fence; a lapsed lease is reclaimed by `Jobs.reap` as a safe re-claim, not corruption. |

A door, not a depth: EchoMQ does **not** implement Redlock — this dive cites the single-Valkey lease as the road not
taken. The worker-side lock plane and the v2 script bundle are the dedicated [EchoMQ course](/echomq).

## Recap — the vote and the clock

Redlock removes the single point of failure by acquiring on a majority of N independent masters: with five and no
replication between them, two can be down and a client still reaches three, and two disjoint majorities cannot exist.
The acquire is two clock reads around a set of `SET`s, and a lock is held only when the votes clear `N/2+1` and the
elapsed acquire fits inside the lease — else it is released on all N. EchoMQ weighs that cost and keeps one Valkey
instead, making the protected work idempotent so a lost lease is a recovered re-claim. The next dive takes the timing
argument the whole Redlock debate turns on.

## References

### Sources

- [Redis — Distributed Locks (and Redlock)](https://redis.io/docs/latest/develop/use/patterns/distributed-locks/) —
  the canonical acquire protocol: the majority of N, the `T1`/acquire/`T2` time-check, release on all instances.
- [Salvatore Sanfilippo — Is Redlock safe?](https://antirez.com/news/101) — the Redis creator's account of why the
  majority vote and the time-check are sufficient in practice.
- [Martin Kleppmann — How to do distributed locking](https://martin.kleppmann.com/2016/02/08/how-to-do-distributed-locking.html)
  — the critique of the majority argument, and the case for a fencing token from the resource.
- [Valkey — SET](https://valkey.io/commands/set/) — the `NX`/`PX` options behind the per-instance acquire.
- [Valkey — Programmability](https://valkey.io/topics/programmability/) — atomic Lua execution: why the
  token-checked release, and EchoMQ's `@claim`, run as one transition.

### Related in this course

- [R2.03 · The Redlock algorithm](/redis-patterns/coordination/redlock) — the module hub.
- [R2.02 · Distributed locking](/redis-patterns/coordination/distributed-locking) — the single-Valkey lease this
  majority is weighed against.
- [R2 · Coordination & Consistency](/redis-patterns/coordination) — the chapter.
- [/echomq/protocol](/echomq/protocol) — the EchoMQ protocol the claim lease lives in.
- [/elixir · CQRS](/elixir/pragmatic/cqrs) — the functional-Elixir & OTP craft behind the echo umbrella.
