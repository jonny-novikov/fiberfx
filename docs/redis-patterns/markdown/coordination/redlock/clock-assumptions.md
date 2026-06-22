# Clock assumptions

> Route: `/redis-patterns/coordination/redlock/clock-assumptions` · Dive R2.03.2 · Source:
> `content/fundamental/redlock.md.txt`
> · Grounding (contrast): EchoMQ sidesteps the cross-node clock argument entirely — the `@claim` script
> (`echo/apps/echo_mq/lib/echo_mq/jobs.ex:126`) reads **one** server clock with `redis.call('TIME')` inside one
> atomic transition; there are no clocks to compare. A worker that pauses past its lease is fenced by `attempts`
> (`HINCRBY`) — refused at `@complete`/`@retry` with `EMQSTALE … token mismatch` — and the lease is reclaimed by
> `Jobs.reap` (`consumer.ex:93`), so a timing violation is a recovered re-claim, not corruption.

Redlock is safe while clocks behave. A lease is a real-time budget — and a pause that outlives it lets a second
holder in.

Redlock does not need synchronized clocks — only that local clocks advance at the same rate and do not jump. The
validity math carries the assumption: `validity = TTL − elapsed − drift`, less one to two percent for drift. A slow
acquire is harmless because the `T2` re-check catches it; a **clock jump** or a **process pause** is not. That is the
fencing problem the whole Kleppmann/Sanfilippo debate turns on. The contrast — why a queue prefers idempotent work
to a perfect lock, and reads one server clock instead of comparing many — is below.

## Clock drift and timing

Redlock assumes the clocks on different machines advance at approximately the same rate. It does **not** require
synchronized clocks — only that local clocks do not drift significantly relative to the lock TTL. That is a far
cheaper assumption than wall-clock agreement, and it is what lets five independent masters cooperate without a time
authority between them.

The algorithm is immune to network delays during the acquire, and the reason is the time-check from the previous
dive. After acquiring on a majority, a client reads the clock again and computes `elapsed = T2 − T1`. If too much
time passed, the acquire is treated as invalid even when a majority responded — the slow network is caught by the
second gate, not by trusting the round-trips were fast. The drift allowance then trims the usable validity: subtract
a small percentage, typically **1–2%**, to leave headroom for the clocks running at slightly different rates.

What the time-check cannot catch is a clock that **jumps**. A manual time change or an aggressive NTP correction can
move a machine's clock forward past the lease boundary in an instant — and a lease whose expiry is computed against
that clock expires early, while a client elsewhere acts on a lock the holder still counts as live. The mitigation is
operational: configure NTP to slew rather than step, and prevent manual clock adjustments on the Redis servers.

## The fencing problem

A subtle issue affects every distributed lock with automatic expiration, Redlock included — and it has nothing to do
with the clocks on the Redis servers. It is the pause on the **client**:

1. Client A acquires the lock.
2. Client A pauses — a stop-the-world GC, a context switch, a hypervisor freeze.
3. The lease expires while A is paused.
4. Client B acquires the lock; from B's side it is free.
5. Client A resumes and acts as the holder — but its lease has already expired.
6. Both clients operate on the shared resource at once. Mutual exclusion is violated — two writers.

No amount of majority counting prevents this. The lock was held correctly; the holder stalled past the lease, and
the lease is a real-time budget the algorithm has no way to extend after the fact. The fix is to move the guarantee
**off the lock and onto the resource**: a fencing token. On acquire, also obtain a monotonically increasing token;
carry it on every write; the resource rejects any operation whose token is older than the highest it has accepted.

```text
# the fence runs at the resource, not at the lock:
write(resource, payload, token):
  if token > resource.highest_token_seen:
      resource.highest_token_seen = token
      apply(payload)            # accepted
  else:
      reject()                  # stale token — the paused holder is fenced out
```

## The debate

Martin Kleppmann published a critique arguing that Redlock is unsafe for correctness-critical applications, primarily
because of these timing assumptions: a GC pause or a clock jump can produce two holders, and a lock that can fail
this way is the wrong tool when a violation corrupts data. His prescription is the fencing token — let the protected
resource enforce ordering, and the lock becomes an optimization rather than a correctness boundary.

Salvatore Sanfilippo (antirez, the Redis creator) replied defending the algorithm's practical safety: the time-check
already rejects a slow acquire, well-run NTP keeps drift bounded, and for the coordination tasks Redlock targets the
timing checks are sufficient in practice. Both sides agree on one point: **fencing tokens provide stronger
guarantees where the protected resource supports them.** For a resource where a lock violation would corrupt data
and the resource cannot enforce a token, the answer is a consensus system or a different design — not a more careful
lock.

## The contrast — EchoMQ reads one server clock and makes the work idempotent

A job queue steps out of this debate, because it does not need absolute mutual exclusion and it never compares clocks
across nodes. EchoMQ holds one lease per job on **one** Valkey, and the lease is computed against **one** server
clock. The `@claim` script (`echo/apps/echo_mq/lib/echo_mq/jobs.ex:126`) reads `redis.call('TIME')` once, inside the
same atomic transition that stamps the lease — so the clock-drift argument has nothing to act on: there is no second
clock to drift against the first.

```lua
-- @claim (jobs.ex:126) — the lease against ONE server clock; no cross-node comparison
local t = redis.call('TIME')                           -- the only clock in the transition
local now = t[1] * 1000 + math.floor(t[2] / 1000)
redis.call('ZADD', KEYS[2], now + tonumber(ARGV[2]), id)   -- expiry on the server's own clock
```

The client pause that Redlock cannot fence is handled by the **fencing token** EchoMQ already carries: `attempts`,
incremented with `HINCRBY` in `@claim` and returned to the worker. If a worker pauses past its lease, `Jobs.reap`
(`echo/apps/echo_mq/lib/echo_mq/consumer.ex:93`) returns the expired entry to `pending`, the next worker re-claims it
and increments `attempts` again, and when the paused worker resumes and tries to finish, `@complete` and `@retry`
refuse its stale token with `EMQSTALE … token mismatch`. The resource — the job row — enforces ordering exactly as
Kleppmann prescribes, and because the handler is idempotent, the recovered re-claim produces the same result. A
timing violation in EchoMQ is a recovered re-run, not corruption — so the queue never has to win the
Kleppmann/Sanfilippo argument.

| The pattern | Its EchoMQ application |
| --- | --- |
| Redlock's safety rests on bounded clocks: a clock jump or a process pause past the lease admits two holders, and the stronger fix is a fencing token the resource enforces — not the lock. | `@claim` reads **one** server clock (`redis.call('TIME')`), so there is no clock to drift; a worker that pauses past its lease carries a stale `attempts` and is refused at `@complete`/`@retry` (`EMQSTALE`), while `Jobs.reap` reclaims the lease — a timing violation becomes a recovered job. |

A door, not a depth: EchoMQ does **not** implement Redlock — this dive cites the single-Valkey lease as the road not
taken. The worker-side lock plane and the v2 script bundle are the dedicated [EchoMQ course](/echomq).

## Recap — the lease is a real-time budget

Redlock's safety rests on bounded clock drift, not synchronized clocks: `validity = TTL − elapsed − drift`, with the
`T2` re-check absorbing a slow acquire and a 1–2% allowance absorbing drift. A clock jump and a process pause defeat
that — a holder that stalls past the lease can find a second holder already in, the fencing problem every expiring
lock shares. Kleppmann calls for a fencing token; Sanfilippo calls the checks sufficient; both agree a token at the
resource is stronger. EchoMQ sidesteps the argument: one server clock inside one atomic script, the `attempts` fence
at the job row, and `Jobs.reap` to reclaim a lapsed lease. The next dive resolves the contrast — when the
single-Valkey lease is enough, and when Redlock's five-instance cost is justified.

## References

### Sources

- [Martin Kleppmann — How to do distributed locking](https://martin.kleppmann.com/2016/02/08/how-to-do-distributed-locking.html)
  — the timing critique: a GC pause or a clock jump produces two holders, and the case for a fencing token the
  resource enforces.
- [Salvatore Sanfilippo — Is Redlock safe?](https://antirez.com/news/101) — the Redis creator's reply: the `T2`
  time-check rejects a slow acquire and the timing checks are sufficient in practice.
- [Redis — Distributed Locks (and Redlock)](https://redis.io/docs/latest/develop/use/patterns/distributed-locks/) —
  where the validity math and the clock-drift allowance are specified.
- [Valkey — SET](https://valkey.io/commands/set/) — the `PX` lease whose expiry the clock assumptions are measured
  against.
- [Valkey — Programmability](https://valkey.io/topics/programmability/) — atomic Lua execution: why EchoMQ's `@claim`
  reads one server clock inside one transition.

### Related in this course

- [R2.03 · The Redlock algorithm](/redis-patterns/coordination/redlock) — the module hub.
- [R2.02 · Distributed locking](/redis-patterns/coordination/distributed-locking) — the single-Valkey lease that
  sidesteps the debate.
- [R2 · Coordination & Consistency](/redis-patterns/coordination) — the chapter.
- [/echomq](/echomq) — the EchoMQ protocol the claim lease lives in.
- [/elixir · CQRS](/elixir/pragmatic/cqrs) — the functional-Elixir & OTP craft behind the echo umbrella.
