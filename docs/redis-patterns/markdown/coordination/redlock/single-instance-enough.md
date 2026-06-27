# When single-instance is enough

> Route: `/redis-patterns/coordination/redlock/single-instance-enough` · Dive R2.03.3 · Source:
> `content/fundamental/redlock.md.txt`
> · Grounding (contrast): EchoMQ deliberately chose the single-Valkey lease over Redlock — `@claim`
> (`echo/apps/echo_mq/lib/echo_mq/jobs.ex:126`) stamps `ZADD active now + lease_ms <id>` against one server clock
> with the `attempts` fence (`HINCRBY`), refused stale at `@complete`/`@retry` (`EMQSTALE`). `Jobs.reap`
> (`consumer.ex:93`) returns a lapsed lease to pending; the `EchoMQ.Consumer` holds it for `:lease_ms` (default
> `30_000`). Idempotent work, one Valkey, no Redlock.

Redlock works. The question this dive resolves is whether a workload needs what it buys — because the five-instance
cost is real.

The whole module collapses to one decision, and it is about the consequence of a lost lock, not the lock itself.
When a lock is lost, does the system suffer **catastrophic corruption** or absorb a **recoverable retry**, and is
the budget **one Valkey** or **five independent masters**. The rule returns the right tool — a single-instance
lease, Redlock, or a consensus system. EchoMQ's answer lands on the recoverable side: the per-job lease guards one
active worker, the handler is idempotent, and a lapsed lease is reclaimed. That is why a queue keeps one Valkey.

## When to use Redlock

Redlock is the right tool for a specific shape of problem: coordination across machines where a lost lock is costly
enough to justify fault tolerance, but not so catastrophic that only a consensus system will do. The source names
four fits and four signals to reach elsewhere.

Redlock is appropriate for coordinating access to an **external resource** that has no concurrency control of its
own; for preventing **duplicate job execution** in a distributed task queue; for **distributed rate limiting** where
approximate correctness is acceptable; and for **leader election** among application instances. Each shares a trait:
the work is coordination, the consequence of a brief overlap is tolerable or recoverable, and the operational cost of
five masters is worth paying for fault tolerance a single instance cannot give.

Reach for an alternative when the shape is different. Use a **consensus system** — etcd or ZooKeeper — when absolute
correctness is required and a lock violation cannot be tolerated. Use **fencing at a linearizable resource** when the
storage layer can enforce a monotonic token, a stronger guarantee than any lock. Stay with **single-instance Redis**
when its reliability is sufficient for the workload. And avoid Redlock when the operational complexity of running
five independent masters is not justified by the failure it prevents.

That last line is the hinge. Redlock's price is not the algorithm — it is the infrastructure: five Redis masters,
fully independent, ideally in different availability zones, with no replication between them, each one a thing to
provision, monitor, patch, and reason about. A workload pays that price only when a lost lock would corrupt data and
no cheaper guarantee will hold the line.

## The decision

The whole module collapses to one decision, and it is about the **consequence of a lost lock**, not the lock itself.
A lock can always be lost — a failover, a clock jump, a process pause past the lease. What separates the right answer
is what happens next.

If a lost lock causes **catastrophic corruption** — two writers mutate a balance, a transfer is applied twice with
no record, an external system is driven into an inconsistent state it cannot recover from — then the lock is a
correctness boundary, and a lock that can fail under timing assumptions is the wrong boundary. The answer is a
consensus system that does not rest on bounded clocks, or a resource that enforces a fencing token, so a stale holder
is rejected where the data changes.

If a lost lock causes a **recoverable retry** — the same work runs twice, and running it twice is safe because the
operation is idempotent and a recovery path reclaims the orphaned unit — then the lock is an optimization, not a
correctness boundary. Here a single-instance lease is sufficient, and the five-master cost buys a guarantee the
workload does not need. A job queue lands squarely on the recoverable side, and that is the contrast EchoMQ makes
concrete.

## The summary table

The source closes on a four-row comparison. It is the trade in one frame: Redlock buys fault tolerance with
complexity, and a single instance keeps it simple at the cost of surviving a node failure.

| Aspect | Single instance | Redlock |
| --- | --- | --- |
| Fault tolerance | None — a node failure loses the lock | Tolerates a minority of node failures |
| Complexity | Low — one Redis, one `SET … NX PX` | Higher — five independent masters, the acquire-and-time-check protocol |
| Consistency | Lost on failover (the master-replica race) | Maintained while a majority survives |
| Use case | Non-critical coordination, or recoverable work | Important distributed coordination |

Redlock trades operational complexity for fault tolerance. It is not a consensus algorithm and does not give the
guarantees of Paxos or Raft; for many practical applications it provides sufficient distributed locking with
reasonable safety. The table does not crown a winner — it names the axis a workload chooses on. A queue reads the
recoverable-work cell and stops there.

## The contrast, resolved — EchoMQ keeps one Valkey

EchoMQ takes the single-instance side, and the choice is deliberate, not a compromise. A job queue does not need
absolute mutual exclusion; it needs one active worker per job in the common case and a safe recovery when that
breaks.

The lock is the claim lease on **one** Valkey. The `@claim` script (`echo/apps/echo_mq/lib/echo_mq/jobs.ex:126`,
run by `Jobs.claim/3` at jobs.ex:283) reads **one** server clock and stamps the lease — there is no majority of N
and no second master.

```lua
-- @claim (jobs.ex:126) — the single-Valkey lease, on one server clock, with the attempts fence
local att = redis.call('HINCRBY', jk, 'attempts', 1)   -- the monotone fence, returned to the worker
redis.call('HSET', jk, 'state', 'active')
local t = redis.call('TIME')                           -- one clock — no five masters, no vote
local now = t[1] * 1000 + math.floor(t[2] / 1000)
redis.call('ZADD', KEYS[2], now + tonumber(ARGV[2]), id)
```

The reason this is safe is the recovery path, not the lock. The `EchoMQ.Consumer` holds the lease for `:lease_ms`
(default `30_000`, `echo/apps/echo_mq/lib/echo_mq/consumer.ex:57`); on each beat it calls `Jobs.reap`
(`consumer.ex:93`), which returns every expired lease in `active` to `pending` on the same server clock. The next
worker re-claims the job and increments `attempts`; when the original worker resumes, `@complete`/`@retry` refuse its
stale token with `EMQSTALE … token mismatch`. Because the handler is idempotent, the re-run produces the same result
as the first run. A lost lease in EchoMQ becomes a double-run the queue recovers from, not two writers corrupting a
resource — exactly the move Redlock's critics prescribe, applied where the data changes instead of at the lock.

| The pattern | Its EchoMQ application |
| --- | --- |
| Redlock buys fault tolerance with five independent masters — the right call when a lost lock corrupts data and no cheaper guarantee holds the line. | `@claim` holds the lease on **one** Valkey against one server clock, with `attempts` (`HINCRBY`) the fence, refused stale with `EMQSTALE`; the `EchoMQ.Consumer` holds it for `:lease_ms` (`30_000`) and `Jobs.reap` reclaims a lapsed lease as a safe idempotent re-claim — so the queue keeps one Valkey instead of five. |

A door, not a depth: EchoMQ does **not** implement Redlock — this dive cites the single-Valkey lease as the road not
taken. The worker-side lock plane and the v2 script bundle are the dedicated [EchoMQ course](/echomq); where a cache
fact applies, see [The Branded Component System](/bcs).

## Recap — the contrast resolved

Redlock is a real tool with a real price: five independent masters, no replication, the acquire-and-time-check
protocol. The source names where it fits — external resources, duplicate-job prevention, approximate rate limiting,
leader election — and where to reach past it: a consensus system when correctness is absolute, a fenced resource when
the storage layer supports a token, a single instance when its reliability is sufficient. The whole module reduces to
one axis: a lost lock that causes catastrophic corruption needs more than a lock; a lost lock that causes a
recoverable retry needs less. EchoMQ reads the recoverable cell — `@claim` on one Valkey, the `attempts` fence, and
`Jobs.reap` reclaiming a lapsed lease, with an idempotent handler that makes a re-run safe — and keeps one Valkey.

## References

### Sources

- [Redis — Distributed Locks (and Redlock)](https://redis.io/docs/latest/develop/use/patterns/distributed-locks/) —
  the canonical algorithm and the when-to-use guidance: the four fits, the four signals to reach for a consensus
  system, and the operational cost of five independent masters.
- [Salvatore Sanfilippo — Is Redlock safe?](https://antirez.com/news/101) — the Redis creator's defence: for the
  coordination tasks Redlock targets, the timing checks are sufficient in practice.
- [Martin Kleppmann — How to do distributed locking](https://martin.kleppmann.com/2016/02/08/how-to-do-distributed-locking.html)
  — the critique that draws the line: when a lock violation corrupts data, fence at the resource or use consensus.
- [Valkey — SET](https://valkey.io/commands/set/) — `SET resource <token> NX PX <ttl>`, the single-instance lease
  that is the contrast Redlock weighs against.
- [Valkey — Programmability](https://valkey.io/topics/programmability/) — atomic Lua execution: why EchoMQ's `@claim`
  is one transition over the single-Valkey lease.

### Related in this course

- [R2.03 · The Redlock algorithm](/redis-patterns/coordination/redlock) — the module hub, where the majority-of-N
  mechanic and the validity math are taught in full.
- [R2.02 · Distributed locking](/redis-patterns/coordination/distributed-locking) — the single-Valkey lease that is
  the contrast: one `SET … NX PX`, one Valkey, reclaimed by lease recovery.
- [R2 · Coordination & Consistency](/redis-patterns/coordination) — the chapter: atomic moves, leases, and the
  Redlock contrast.
- [/echomq/protocol](/echomq/protocol) — the EchoMQ protocol the claim lease lives in.
- [/elixir · CQRS](/elixir/pragmatic/cqrs) — the functional-Elixir & OTP craft behind the echo umbrella.
