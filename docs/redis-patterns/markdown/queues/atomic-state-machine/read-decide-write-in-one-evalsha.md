# Read-decide-write in one EVALSHA — fourteen keys, one step

> Route: `/redis-patterns/queues/atomic-state-machine/read-decide-write-in-one-evalsha` · Dive R3.04.2 · Module R3.04
> Atomic state machine. Grounding: `EchoMQ.Scripts.move_to_finished/7` wraps `moveToFinished-14.lua` — fourteen keys
> in one `EVALSHA`. The same call finishes the job and, with `fetch_next` defaulting to 1, fetches the next from
> `wait` into `active`. The dispatch is `EchoMQ.Scripts.execute(conn, :move_to_finished, keys, args)`. All real in
> `echo/apps/echomq`.

The finish is a read-modify-write: read the lock, decide where the job goes, write the move. Split into round trips, a
second process slips between read and write. Run as one `EVALSHA`, it is indivisible.

## The transition is a read-modify-write

Finishing a job is not one write. It is a read, a decision, and several writes:

- **Read** — is the lock still held, and is this the right token? A worker that lost its lease must not finish a job a
  recovery sweep has already reclaimed.
- **Decide** — completed or failed; and past the attempt ceiling, failed instead of retried.
- **Write** — clear the lock, record the result on the job hash, move the id from `active` to `completed` or `failed`,
  bump the metrics, and fetch the next job.

That is a read-modify-write across many keys. Done as separate commands, the gaps between them are open. A recovery
sweep reads the same job still in `active`, reclaims it, and writes it back to `wait` — between the finishing worker's
read and its write. The job lands in both `completed` and `wait`, or its lock is cleared by one process while the
other still treats it as held. At-least-once becomes a mess by accident.

## One EVALSHA closes every gap

A Lua script runs to completion before Redis serves the next command. So folding the whole read-decide-write into one
script and dispatching it with a single `EVALSHA` removes every gap. The read, the decision, and the writes are one
indivisible step; no recovery sweep and no second finish can interleave.

`moveToFinished-14.lua` is that script, and it touches **fourteen keys** — the whole queue shape, named in this order:

1. `emq:{queue}:wait` (LIST) · 2. `emq:{queue}:active` (LIST) · 3. `emq:{queue}:prioritized` (ZSET) ·
4. `emq:{queue}:events` (STREAM) · 5. `emq:{queue}:stalled` (SET) · 6. `emq:{queue}:limiter` ·
7. `emq:{queue}:delayed` (ZSET) · 8. `emq:{queue}:paused` (LIST) · 9. `emq:{queue}:meta` ·
10. `emq:{queue}:pc` (priority counter) · 11. `emq:{queue}:completed` **or** `emq:{queue}:failed` (the target
ZSET) · 12. `emq:{queue}:<id>` (the job hash) · 13. `emq:{queue}:metrics:<target>` · 14. `emq:{queue}:marker`.

`EchoMQ.Scripts.move_to_finished/7` builds this list in exactly this order and dispatches it with
`execute(conn, :move_to_finished, keys, args)`, a named-script call that runs `EVALSHA`. The fourteen keys reach Redis
as one command.

## The fetch_next payoff

The centrepiece is one ARGV flag. `fetch_next` defaults to `1`, so the same `moveToFinished` call that finishes the
current job also pops the next id from `wait` into `active` — under the same atomic step. Finish-then-fetch, the two
moves a worker makes back to back, is one round trip rather than two. The lifecycle transition and the next fetch are
indivisible: there is no instant between the finish and the next pickup at which the queue sits half-moved.

A worker loop that finished a job and then made a second call to fetch the next would pay two round trips and open a
window between them. EchoMQ's loop pays one. The `fetch_next=1` flag is what makes "finish this, start the next" a
single atomic move.

### The pattern, applied

The atomic-updates pattern says a multi-key read-modify-write must be one server-side script. In EchoMQ that script is
`moveToFinished-14.lua`, dispatched by `EchoMQ.Scripts.move_to_finished/7` as one `EVALSHA` over fourteen keys, with
`fetch_next` defaulting to 1 so the finish and the next fetch are one indivisible step.

A door, not a depth: the script body's full include graph over all fourteen keys, and the worker fetch loop that calls
it, are E2 · the engine and E6 · the lifecycle in the dedicated EchoMQ course.

## References

### Sources
- [Redis — EVALSHA](https://redis.io/commands/evalsha/) — the cached-script call that runs the fourteen-key transition
  as one step.
- [Redis — EVAL / scripting](https://redis.io/commands/eval/) — why a Lua script is one atomic step, so no second
  process interleaves the read-decide-write.
- [Redis — Scripting with Lua](https://redis.io/docs/latest/develop/interact/programmability/eval-intro/) — the model
  for a script running to completion in the single command thread.
- [Redis — Sorted sets](https://redis.io/docs/latest/develop/data-types/sorted-sets/) — the `completed`/`failed`/
  `delayed`/`prioritized` target locations the move writes into.
- [BullMQ — the queue protocol](https://bullmq.io/) — the `moveToFinished` lifecycle and its fetch-next payoff that
  EchoMQ ports.

### Related in this course
- [R3.04 · Atomic state machine](/redis-patterns/queues/atomic-state-machine) — the module: the transition as one
  EVALSHA.
- [R3.04.1 · States as locations](/redis-patterns/queues/atomic-state-machine/states-as-locations) — the prior dive:
  the locations the move travels between.
- [R3.04.3 · EVALSHA and NOSCRIPT](/redis-patterns/queues/atomic-state-machine/evalsha-and-noscript) — the next dive:
  how the cached script gets to the server.
- [R3.03 · Stalled recovery](/redis-patterns/queues/stalled-recovery) — the sweep that must not interleave this finish.
- [R2.01 · Atomic updates](/redis-patterns/coordination/atomic-updates) — the one-script read-modify-write pattern this
  applies.
- [E2 · The engine](/echomq/core) — the dedicated EchoMQ course: the worker fetch loop that calls `moveToFinished`.
