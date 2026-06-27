# The Redlock algorithm

> Route: `/redis-patterns/coordination/redlock` · Module R2.03 *(taught as a CONTRAST)* · Source:
> `content/fundamental/redlock.md.txt`
> · Grounding (contrast): EchoMQ does **not** implement Redlock. The positive contrast is its single-Valkey lease —
> the `@claim` script (`echo/apps/echo_mq/lib/echo_mq/jobs.ex:126`) reads **one** server clock with
> `redis.call('TIME')` inside one atomic Lua transition and writes the lease with `ZADD active now + lease_ms <id>`;
> there is no majority of N and no cross-node clock comparison. The fencing token is `attempts` (`HINCRBY` in
> `@claim`); a stale worker is refused at `@complete`/`@retry` with `EMQSTALE … token mismatch`. A lapsed lease is
> returned to pending by `Jobs.reap` (`echo/apps/echo_mq/lib/echo_mq/consumer.ex:93`) on the same server clock, so a
> lost lease is a recovered re-claim, not corruption. Door forward to the dedicated EchoMQ course for the worker-side
> lock plane.

Achieve fault-tolerant distributed locking by acquiring locks on a majority (N/2+1) of N independent Redis instances,
tolerating node failures without losing lock consistency.

Redlock is the contrast to the single-instance lock of R2.02. A single-instance lock is lost when its one Redis node
fails; Redlock spreads the lock across several independent masters and counts votes, so a minority of failures does
not drop the lock. That fault tolerance has a price — five independent instances, a timing assumption, and a known
debate — and this module weighs it against the single-Valkey lease EchoMQ actually ships.

## The problem with single-instance locks

A single Redis lock with `SET resource <token> NX PX 30000` holds until the one Redis server fails. With
master-replica replication, a race opens at failover:

1. Client A acquires the lock on the master.
2. The master crashes before the write replicates to the replica.
3. The replica is promoted to master.
4. Client B acquires the same lock — the new master carries no record of A's lock.

Two clients are now both granted the same lock. The mutual-exclusion guarantee is violated: two holders at once,
which is exactly what a lock must prevent. The acquire is safe on one node; the gap opens only across a
master-replica handoff. This is the weakness Redlock is built to remove.

## The Redlock solution

Redlock uses N independent Redis masters (typically 5) with **no replication between them**. A lock counts as
acquired only when a client holds it on a majority of instances — N/2+1, so at least 3 of 5. The acquire is
time-checked end to end:

1. Read the current time in milliseconds (`T1`).
2. On each of N instances, with a 5–50 ms per-instance timeout, run `SET resource_name <random_value> NX PX 30000`.
3. Read the clock again (`T2`) and compute `elapsed = T2 − T1`.
4. The lock is **acquired** only if the OK count is a majority (`≥ N/2+1`) **and** `elapsed < TTL`.
5. The usable validity is `TTL − elapsed − clock_drift_allowance`.
6. Otherwise, release on **all** instances at once, wait a random delay, and retry.

Release runs the same token-checked Lua script on every instance — `GET == token then DEL` — so a delete only lands
on a lock this client still owns. The release is attempted on all instances, even those where the acquire appeared
to fail, because a network blip can produce a false negative. The random retry delay desynchronizes competing
clients and reduces contention.

## Safety and liveness

Redlock targets three properties.

- **Safety — mutual exclusion.** At most one client holds the lock at a time, as long as the client finishes its work
  within the validity time. If the lease expires mid-work, a second client may acquire it.
- **Liveness — deadlock freedom.** A lock eventually frees even when the holder crashes, because the TTL releases it
  automatically — the same mortality the single-instance `PX` gives, now across N nodes.
- **Liveness — fault tolerance.** While a majority of instances are reachable, clients can acquire and release locks.
  This is the property a single-instance lock cannot offer, and the whole reason to run more than one.

## Clock drift and timing

Redlock assumes clocks on different machines advance at approximately the same rate. It does **not** require
synchronized clocks — only that a local clock does not drift significantly relative to the TTL. The algorithm is
immune to network delay during the acquire because it re-checks the time at `T2`: if too much time elapsed, the lock
is treated as invalid even when a majority responded OK. The vulnerability is a **clock jump** — a manual time
change or an aggressive NTP correction — which can move a clock past the lease and break the safety argument. The
drift allowance, typically 1–2% of the TTL, is the safety margin subtracted from the usable validity:
`validity = TTL − elapsed − clock_drift_allowance`.

## The fencing problem

Automatic expiry creates a hazard shared by every distributed lock: client A acquires the lock; A pauses (GC, a
context switch, a scheduler stall); the lock expires; client B acquires it; A resumes and proceeds as a holder; two
clients now operate on the shared resource at once.

The stronger fix is a **fencing token**: on acquire, also obtain a monotonically increasing token; every operation
on the resource carries the token; the resource rejects any operation whose token is older than the highest it has
seen. A paused, stale writer is fenced out *at the resource*, not merely warned at the lock. Redlock's random value
can serve as a check-and-set token, but it carries no ordering, so it does not fence on its own.

## When to use Redlock

Redlock fits work where approximate mutual exclusion is enough and fault tolerance matters: coordinating access to an
external resource with no built-in concurrency control, preventing duplicate job execution in a distributed queue,
approximate distributed rate limiting, and leader election among application instances.

Reach for an alternative when the requirements harden — absolute correctness, a linearizable resource, a case where
one Redis node is enough, or a setting where five independent instances cost more than the guarantee is worth.

| The requirement | Reach for |
| --- | --- |
| Approximate mutual exclusion, fault tolerance matters | Redlock — majority of N |
| Absolute correctness, a lost lock corrupts data | A consensus system — etcd, ZooKeeper (Paxos/Raft) |
| A linearizable storage system is available | Fencing at the storage layer |
| One Redis node's reliability is sufficient | A single-instance lease (R2.02) |
| Five independent instances are not justified | A single-instance lease + idempotent work |

## Implementation guidelines

The algorithm's safety rests on a handful of concrete settings.

| Knob | Value | Why |
| --- | --- | --- |
| Instances | 5 masters | Tolerates up to 2 failures while keeping a majority. |
| Independence | no replication | Fully independent, ideally in different AZs — a replica failover is the single-instance race Redlock removes. |
| TTL | 10–30 s | Longer than the operation, short enough that a failed client does not block the resource for long. |
| Per-instance timeout | 5–50 ms | Long enough for a healthy instance to respond, short enough to skip a failed one. |
| Random value | ≥ 20 bytes | From a cryptographically secure source (`/dev/urandom`), unique per client per attempt. |
| Drift allowance | 1–2% | Subtracted from the validity for clock drift between machines. |

## The debate

Martin Kleppmann published a critique arguing Redlock is unsafe for correctness-critical work, primarily because of
its timing assumptions, and that a fencing token from the protected resource is the real fix. Salvatore Sanfilippo
(antirez, the Redis creator) replied defending the algorithm's practical safety, arguing the timing checks are
sufficient under real conditions. The disagreement centres on whether those timing checks are enough to prevent a
safety violation in practice. Both agree on one point: a fencing token is the stronger guarantee where the resource
supports it.

## Summary — single instance vs Redlock

| Aspect | Single instance | Redlock |
| --- | --- | --- |
| Fault tolerance | None — lost when the one node fails | Tolerates a minority of node failures |
| Complexity | Low — one Redis | Higher — 5 independent instances |
| Consistency | Lost on failover | Maintained while a majority survives |
| Use case | Non-critical coordination | Important distributed coordination |

Redlock trades operational complexity for fault tolerance — not a consensus algorithm, but sufficient locking with
reasonable safety for many applications.

## The contrast — EchoMQ keeps one Valkey

EchoMQ does **not** implement Redlock. Its "lock" is the claim lease, and it lives on **one** Valkey, reached
through **one** `EchoMQ.Connector`. The `@claim` script (`echo/apps/echo_mq/lib/echo_mq/jobs.ex:126`) is one atomic
Lua transition: it pops the next id from `pending` with `ZPOPMIN`, increments the fencing token with `HINCRBY <job>
attempts 1`, marks the row `active`, reads **one** server clock with `redis.call('TIME')`, and stamps the lease with
`ZADD active now + lease_ms <id>`. No cross-node clock is compared, because there is only one clock; no votes are
counted, because there is only one master.

```lua
-- @claim (jobs.ex:126) — the lease on one server clock, attempts as the fencing token
local popped = redis.call('ZPOPMIN', KEYS[1])
if #popped == 0 then return {} end
local id = popped[1]
local jk = ARGV[1] .. id
local att = redis.call('HINCRBY', jk, 'attempts', 1)   -- the monotone fence
redis.call('HSET', jk, 'state', 'active')
local t = redis.call('TIME')                            -- one server clock
local now = t[1] * 1000 + math.floor(t[2] / 1000)
redis.call('ZADD', KEYS[2], now + tonumber(ARGV[2]), id)
return {id, redis.call('HGET', jk, 'payload'), att}
```

The pause that breaks Redlock is handled without a fencing token at the resource and without five masters. The
`attempts` counter, returned to the worker by `@claim`, is the fence: `@complete` and `@retry` refuse a stale token
with `EMQSTALE … token mismatch`, so a worker whose lease was reaped and re-claimed by another worker carries the
old `attempts` and is rejected at the write. The reclaim itself is `Jobs.reap` (consumer.ex:93), which on the same
server clock returns every expired lease in `active` to `pending` — crash recovery, not a vote. A lost lease is a
re-claim by the next worker; because the work is idempotent, that re-run is safe.

| The pattern | Its EchoMQ application |
| --- | --- |
| Redlock answers "keep a lock when a node fails" by acquiring on a majority of N independent masters and counting votes — fault tolerance bought with five instances, a clock assumption, and the `validity = TTL − elapsed − drift` margin. | EchoMQ keeps **one** Valkey: `@claim` reads one server clock with `redis.call('TIME')` and writes the lease with `ZADD active now + lease_ms <id>`; `attempts` (`HINCRBY`) is the fence, refused stale with `EMQSTALE`, and `Jobs.reap` returns a lapsed lease to pending. No majority, no Redlock. |

A door, not a depth: this module teaches Redlock as the contrast and cites EchoMQ's single-Valkey lease as the road
not taken. The worker-side lock plane and the full v2 script bundle are the subject of the dedicated
[EchoMQ course](/echomq); where a cache fact applies, see [The Branded Component System](/bcs).

## The three dives

Each dive takes one part of the contrast, following the source in order: the majority mechanic that gives the fault
tolerance, the timing argument the whole debate turns on, and the contrast resolved — when a single-Valkey lease is
enough.

- **R2.03.1 — The majority of N.** Why N/2+1 of N independent masters gives fault tolerance one node cannot. The full
  acquire protocol, the elapsed-time guard, and why independence matters.
- **R2.03.2 — Clock assumptions.** The validity math, immunity to network delay, the hazard of a clock jump and a
  process pause, and the Kleppmann/Sanfilippo debate in full.
- **R2.03.3 — When single-instance is enough.** The decision — recoverable retry or catastrophic corruption — and why
  EchoMQ keeps one Valkey and makes the work idempotent. The contrast resolved.

## References

### Sources

- [Redis — Distributed Locks (and Redlock)](https://redis.io/docs/latest/develop/use/patterns/distributed-locks/) —
  the canonical specification: majority of N, the time-check, release on all instances.
- [Salvatore Sanfilippo — Is Redlock safe?](https://antirez.com/news/101) — the Redis creator's reply defending the
  algorithm's practical safety against the timing critique.
- [Martin Kleppmann — How to do distributed locking](https://martin.kleppmann.com/2016/02/08/how-to-do-distributed-locking.html)
  — the critique: Redlock's timing assumptions, and why a fencing token from the resource is stronger.
- [Valkey — SET](https://valkey.io/commands/set/) — the `NX`/`PX` options behind the per-instance acquire and the
  single-instance lease.
- [Valkey — Programmability](https://valkey.io/topics/programmability/) — atomic Lua execution: why the token-checked
  release, and EchoMQ's `@claim`, run as one transition.

### Related in this course

- [R2 · Coordination & Consistency](/redis-patterns/coordination) — the chapter.
- [R2.02 · Distributed locking](/redis-patterns/coordination/distributed-locking) — the single-Valkey lease this
  contrast weighs against.
- [R2.01 · Atomic updates](/redis-patterns/coordination/atomic-updates) — the atomic move a lock protects.
- [/echomq/protocol](/echomq/protocol) — the EchoMQ protocol the claim lease lives in.
- [/elixir · CQRS](/elixir/pragmatic/cqrs) — the functional-Elixir & OTP craft behind the echo umbrella.
