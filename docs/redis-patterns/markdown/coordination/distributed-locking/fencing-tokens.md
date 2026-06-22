# Fencing tokens — the token that makes release safe

> Route: `/redis-patterns/coordination/distributed-locking/fencing-tokens` · Dive R2.02.2 · Parent: R2.02
> distributed-locking · Source: `content/fundamental/distributed-locking.md.txt` (*Releasing the Lock* + *Safe Lock
> Release*) · Grounding: the **real** fence — `attempts`, incremented `HINCRBY <jobkey> attempts 1` in
> `EchoMQ.Jobs.claim/3`'s `@claim` script (`echo/apps/echo_mq/lib/echo_mq/jobs.ex:131`); `@complete` (`jobs.ex:139`)
> and `@retry` (`jobs.ex:173`) refuse a stale token with `EMQSTALE … token mismatch`.

A blind `DEL` deletes whatever lock is there now — which is not always the lock you took. A lease expires on its own,
and once it does another client can take the same key. A late `DEL` from the original holder then deletes the
successor's lock, and the mutual exclusion is gone. The fix conditions the act on a token: delete only if the value
under the key is still yours. The deeper argument, fencing, pushes the same check into the protected resource so a
holder paused past its lease cannot write through it.

## Never DEL a lock blindly

The release looks harmless: the work is done, so the holder calls `DEL resource:lock`. The hazard is that the key
under `resource:lock` may no longer hold the lock the caller took. A lease expires on its own — that expiry is what
keeps a crashed holder from deadlocking the key. Once the lease lapses, another client can take the same key. A late
`DEL` then deletes that client's lock.

```
-- DANGEROUS: deletes whatever lock is under the key right now
DEL resource:lock
```

The scenario, step by step:

1. Client A takes the lock with token `abc`.
2. Client A takes too long; the lease expires on its own.
3. Client B takes the same key with token `xyz`.
4. Client A finishes and calls `DEL`.
5. The `DEL` removes client B's lock, not A's.

Now two clients hold the lock at once. The fault is not the expiry; the fault is releasing without checking
whose lock is under the key.

## The token-checked release

The fix conditions the delete on the token: read the key, and delete it only if the stored value is still the token
the caller acquired with. The read and the delete must be one atomic step — between a bare `GET` and a separate
`DEL`, the lease could expire and another client could take the key. A Lua script runs to completion with no command
interleaved.

```
-- safe release: DEL only if the stored token is still ours
if redis.call("GET", KEYS[1]) == ARGV[1] then
  return redis.call("DEL", KEYS[1])
else
  return 0
end
```

In the A/B scenario, A's release reads `xyz` under the key, finds it is not `abc`, and returns `0` — a no-op. B's
lock stands. The token is the whole defence: without it, release has no way to tell its own lock from a successor's.

## Fencing a stale writer

The token-checked release closes the in-the-store hazard, but a longer argument remains. Suppose a holder is paused —
a long garbage-collection pause, a scheduler stall, a network partition — past the end of its lease. While it is
paused, the lease expires, another worker takes the lock, and that worker starts writing to the protected resource.
Then the first holder resumes. It still carries its lock value. It writes.

A lock alone cannot stop that write, because from the resource's side the late write arrives like any other. Martin
Kleppmann's argument is that the resource itself must reject the stale writer, and the mechanism is a **fencing
token**: a number that increases every time the lock is granted. Each writer presents its token with every write; the
resource keeps the highest token it has accepted and rejects any write carrying a lower one.

```
# grant 1 -> token 33; grant 2 -> token 34; ...
# the resource accepts a write only if its token >= the highest seen
write(payload, fencing_token)   # rejected when fencing_token < max_seen
```

The paused holder acquired with token N. While it was paused, the next holder acquired with token N+1 and wrote. The
resource has now seen N+1. When the paused holder resumes and writes with token N, the resource compares N against
the N+1 it has already accepted and rejects the write. The lease being a wall-clock guess no longer decides
correctness.

Salvatore Sanfilippo, Redis's author, replied to that critique in *Is Redlock safe?*. The honest summary is that a
monotonic fencing counter and an owner token solve overlapping but not identical problems — the owner token stops the
wrong client's lock being deleted; the fencing token stops a holder whose lease has already lapsed.

## The applied form — `attempts` is EchoMQ's fence

EchoMQ does not run a separate string lock with an owner token. Its fence is the monotone **attempt count** built
into every claim, and it is precisely the fencing-token idea Kleppmann describes — a number that increases each time
the job is granted, presented back on every transition. `EchoMQ.Jobs.claim/3`'s `@claim` script
(`echo/apps/echo_mq/lib/echo_mq/jobs.ex:131`) increments it as it leases the job:

```
local att = redis.call('HINCRBY', jk, 'attempts', 1)   -- the fence: +1 per grant
redis.call('HSET', jk, 'state', 'active')
-- ... ZADD the job into emq:{q}:active scored now + lease_ms ...
return {id, redis.call('HGET', jk, 'payload'), att}     -- the worker carries `att` and must present it back
```

The worker now holds `att` and must present it on `complete` or `retry`. Those scripts fence on it. `@complete`
(`jobs.ex:139`) reads the stored `attempts` and refuses a mismatch:

```
local att = redis.call('HGET', KEYS[2], 'attempts')
if not att then return 0 end
if att ~= ARGV[2] then
  return redis.error_reply('EMQSTALE complete token mismatch')
end
```

`@retry` (`jobs.ex:173`) carries the same `EMQSTALE retry token mismatch` fence. The chain is the whole fence: a
worker whose lease was reaped and re-claimed by another worker carries a stale `att`, because the re-claim ran
`HINCRBY attempts 1` again and bumped the stored value past the paused worker's copy. When the paused worker resumes
and calls `complete` with its old `att`, the stored `attempts` is higher, the comparison fails, and the transition is
refused — exactly Kleppmann's "reject the lower token." `EchoMQ.Jobs.complete/4` (`jobs.ex:313`) surfaces this as
`{:error, :stale}`.

The worker-side lock-subkey plane — `emq:{q}:job:<id>:lock`, the §6 subkey a long-running worker holds and which
`remove_job` already refuses to clear with the `EMQLOCK` class (`jobs.ex:492`) — is forward work in the dedicated
EchoMQ course. This dive cites the `attempts` fence as proof the pattern is real and doors forward.

## Recap — the fence is a number, not a string lock

A blind `DEL` deletes whatever lock is under the key, which after a lapsed lease is a successor's lock. The
token-checked release deletes only your own. The fencing-token argument pushes the same idea into the resource so a
holder paused past its lease cannot write through it. EchoMQ's fence is `attempts`: `HINCRBY`'d once per claim,
carried by the worker, and checked at `@complete` / `@retry`, which refuse a stale token with `EMQSTALE`. A reaped
and re-claimed job bumps the stored count, so the paused worker's old count fences it out. The next dive keeps the
lease fresh so a long job does not get reaped mid-work.

## References

### Sources
- [Redis — Distributed Locks](https://redis.io/docs/latest/develop/use/patterns/distributed-locks/) —
  single-instance acquisition, owner-token release, and the failover caveat.
- [Valkey — Programmability](https://valkey.io/topics/programmability/) — why a `GET`-then-`DEL`, or an
  `HINCRBY`-then-`HSET`-then-`ZADD`, must be one script: atomic execution, nothing interleaved.
- [Martin Kleppmann — How to do distributed locking](https://martin.kleppmann.com/2016/02/08/how-to-do-distributed-locking.html)
  — the fencing-token argument: the resource must reject a stale writer.
- [Salvatore Sanfilippo — Is Redlock safe?](https://antirez.com/news/101) — the reply to that critique, weighing the
  lock service against the resource.

### Related in this course
- [R2.02 · Distributed locking](/redis-patterns/coordination/distributed-locking) — the module hub.
- [R2.02.1 · SET NX PX](/redis-patterns/coordination/distributed-locking/set-nx-px) — where the lease is taken, the
  claim that runs the `HINCRBY`.
- [R2.02.3 · Lease renewal](/redis-patterns/coordination/distributed-locking/lease-renewal) — the next dive: keep the
  lease fresh.
- [/echomq](/echomq) — the EchoMQ protocol, where the worker-side lock-subkey plane is taught.
