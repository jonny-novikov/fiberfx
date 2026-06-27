# The reliable queue — lose no job

> Route: `/redis-patterns/queues/the-reliable-queue` · Dive R3·1 · Chapter R3 Reliable Queues · BCS contract-sheet.
> Grounding: the real **EchoMQ** leased state machine in `echo/apps/echo_mq`. `EchoMQ.Jobs.claim/3` pops the oldest
> pending `JOB` with `ZPOPMIN`, mints a lease from the server `TIME`, and `HINCRBY`s the row's `attempts` fencing
> token — a crash leaves the job leased in `emq:{q}:active`, recoverable. The branded `JOB` id is the idempotency
> key. `EchoMQ.Stalled.check/3` (a count-thresholded sweep) and `EchoMQ.Jobs.reap/2` return a job whose lease
> expired by the server clock. Doors: `/echomq/queue`.

A reliable queue loses no job. The naive loop — claim a job, process it, done — drops a job the instant a worker
dies between the claim and the finish. Three guarantees build a queue that survives a crash, and they build in
order: claim a job into a recoverable in-flight state so a worker that dies leaves it reclaimable, not lost; accept
that redelivery means at-least-once, so the consumer must be idempotent; and reclaim a job whose worker died — its
lease expired — back to pending. Each guarantee is EchoMQ's real worker path.

## The recoverable claim

A pop-and-process loop is the leak. If a job leaves the queue the moment it is taken — before any work has happened —
and the worker then crashes (a deploy, an OOM kill, a power loss), the job is neither in Valkey nor finished. It is
lost, with nothing to recover it from.

The fix is to never let a job leave a recoverable place until it is done. EchoMQ does not pop a job out: it **claims**
it from the pending sorted set into the active set under a **lease**. `EchoMQ.Jobs.claim/3` runs one inline Lua
script: `ZPOPMIN emq:{q}:pending` takes the oldest id; `HINCRBY` bumps the row's `attempts`; `HSET` marks the row
`active`; and `ZADD emq:{q}:active <now + lease_ms> <id>` parks the id in the active set scored by its lease
deadline, where `now` is read from the server's `TIME`. The job is in exactly one set at every instant. A worker that
dies leaves its job in the active set with a lease that will expire — it can be found and returned.

```lua
-- @claim (inline EchoMQ.Script.new/2) — the leased, recoverable claim
local popped = redis.call('ZPOPMIN', KEYS[1])   -- KEYS[1] = emq:{q}:pending
if #popped == 0 then return {} end
local id = popped[1]
local jk = ARGV[1] .. id                          -- the row key
local att = redis.call('HINCRBY', jk, 'attempts', 1)   -- the fencing token
redis.call('HSET', jk, 'state', 'active')
local t = redis.call('TIME')
local now = t[1] * 1000 + math.floor(t[2] / 1000)
redis.call('ZADD', KEYS[2], now + tonumber(ARGV[2]), id)  -- KEYS[2] = emq:{q}:active, lease deadline
return {id, redis.call('HGET', jk, 'payload'), att}
```

The lease is the recovery contract: hold a claim too long and it expires, and another worker can take the job. There
is no instant at which the job exists nowhere.

## At-least-once and idempotency

The recoverable claim makes redelivery possible — that is the whole point. It also makes redelivery inevitable in one
case: a worker that finishes the work, then crashes before it completes the job. On recovery the lease has expired, so
the job is reclaimed and the work runs again.

This is the honest cost of never losing a job. **Exactly-once delivery is a lie** — you cannot both guarantee a job
is never lost and guarantee it is never delivered twice, because the completion itself can be lost. What a reliable
queue offers is **at-least-once**: a job is delivered one or more times, never zero. The responsibility moves to the
consumer, which must be **idempotent** — running the same job twice must produce the same effect as running it once.

The discipline is to make the *effect* exactly-once even though the *delivery* is at-least-once. The stable key for
that is the job's identity: every EchoMQ job is a branded `JOB` id, gated at the key builder
(`EchoMQ.Keyspace.job_key/2`). Key the effect on that id — a row keyed by the `JOB` id, an upsert, a charge recorded
against it — and a redelivery is a no-op. EchoMQ also fences completion itself: `EchoMQ.Jobs.complete/5` carries the
`attempts` token the claim minted, and a completion whose token no longer matches (because the lease was reaped and
re-claimed) is refused. A stale worker cannot complete a job another worker now holds.

## Stalled recovery

A job in the active set whose worker has died must come back. The death signal is a **lease that expired**: the
active set is scored by each job's lease deadline, so any member whose score is in the past is held by no live
worker. `EchoMQ.Jobs.reap/2` is the recovery: one inline Lua sweep over `emq:{q}:active` for members scored
`<= now` (server `TIME`), each `ZADD`ed back to `emq:{q}:pending` and re-marked `pending`. The job re-enters the
normal pickup path and is delivered again — at-least-once in action.

The sweep must itself be careful. Done as two steps — read the expired set, then move each member — two recovery
processes can both see the same stalled job and both move it. EchoMQ runs detect-and-move as **one Lua script** over
the active and pending sets, so each stalled member is reclaimed once per sweep. A non-atomic check-then-move is the
cautionary contrast, correct only until two sweeps overlap.

Above the bare reaper sits `EchoMQ.Stalled.check/3`, a count-thresholded sweep: each pass increments a per-job
`stalled` field, recovers a job below the `:max_stalled` threshold, and dead-letters one at or above it — so a job
that repeatedly stalls is not recovered forever.

## In EchoMQ — the worker path that loses no job

EchoMQ's worker loop is all three guarantees in real code, in `echo/apps/echo_mq`. The recoverable claim is
`EchoMQ.Jobs.claim/3` — `ZPOPMIN` from `emq:{q}:pending` into `emq:{q}:active` under a server-clock lease. The
idempotency key is the branded `JOB` id, fenced by the `attempts` token on `EchoMQ.Jobs.complete/5`. Stalled
recovery is `EchoMQ.Jobs.reap/2` and the count-thresholded `EchoMQ.Stalled.check/3`. The naive pop-and-process loses
a job on a crash; the leased claim, the id-keyed idempotent effect, and the reap sweep are the three guarantees that
make the queue lose none.

## References

### Sources

- [Valkey — ZPOPMIN](https://valkey.io/commands/zpopmin/) — the pop that claims the oldest pending job from the
  score-0 mint-ordered set, the heart of the claim script.
- [Valkey — HINCRBY](https://valkey.io/commands/hincrby/) — increments the row's `attempts`, the lease fencing token
  that makes a stale completion a no-op.
- [Valkey — TIME](https://valkey.io/commands/time/) — the server clock the lease deadline and reap both read, never
  the caller's.
- [Redis — Scripting with Lua](https://redis.io/docs/latest/develop/interact/programmability/eval-intro/) — how the
  multi-key claim and the reap sweep each run as one atomic script.

### Related in this course

- [R3 · Reliable Queues](/redis-patterns/queues) — the chapter: the whole reliable-queue family.
- [R3 · States as locations](/redis-patterns/queues/states-as-locations) — the next dive: each state is an
  `emq:{q}:` location, and the move between them is one atomic Lua transition.
- [R2.01 · Atomic updates](/redis-patterns/coordination/atomic-updates) — the atomic move the reliable queue is built
  on: read-decide-write in one indivisible step.
- [/echomq/queue](/echomq/queue) — the EchoMQ Queue pillar: the leased state machine in depth.
