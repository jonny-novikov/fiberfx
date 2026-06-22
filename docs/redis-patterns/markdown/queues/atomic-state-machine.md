# The atomic state machine — one EVALSHA per transition

> Route: `/redis-patterns/queues/atomic-state-machine` · Module R3.04 · Chapter R3 Reliable Queues.
> · Pattern: `atomic-updates` (the lifecycle treatment). Grounding: EchoMQ's `EchoMQ.Scripts.move_to_finished/7`,
> which wraps `moveToFinished-14.lua` — fourteen keys, one `EVALSHA` — and finishes a job AND fetches the next
> (`fetch_next` defaults to 1) as one indivisible transition. The cached-script call falls back through
> `EchoMQ.Scripts.execute_raw/4` (`EVALSHA` → `NOSCRIPT` → `EVAL`). All real in `echo/apps/echomq`.

Ensure data integrity with atomic read-modify-write operations: a job's transition between states is a
read-modify-write, and it runs as one server-side Lua script so concurrent clients cannot interleave.

A queue's job has a lifecycle — wait, active, completed, failed, delayed. Each transition reads the job's current
place, decides where it goes next, and writes the move. Done as a sequence of separate commands, a stalled sweep or a
second worker slips between the read and the write and the job is handled twice or left in two places at once. Done as
one `EVALSHA`, the whole read-decide-write runs inside Redis's single command thread, indivisible. This module is that
discipline applied to the queue: the job's states are Redis locations, the transition is `moveToFinished-14.lua`, and
the script is the lock.

## The problem: interleaved read-modify-write

The atomic-updates pattern starts from a race. A read-modify-write — read a value, compute a new one, write it back —
is three steps, and any other client can act in the gaps. The source's worked example is a balance: read
`account:123:balance`, subtract `100`, write the result. Two clients that both read the old balance before either
writes both compute from the same number, and one update is lost.

Applied to the queue, the value being updated is not a balance but a **job's location**. A worker finishing a job
reads the lock on the job in `active`, branches to `completed`, and writes the move. A stalled sweep, running at the
same instant, reads the same job still in `active` and reclaims it to `wait`. Run as separate commands, the two
interleave: the job lands in `completed` and `wait` both, or its lock is cleared by one process while the other still
treats it as held. The concurrent writers are the **finishing worker** and the **recovery sweep** (or a second
worker), and the value they race on is the job's place in the queue.

## The solution: one Lua script, one EVALSHA

A Lua script executes atomically — no other command runs between the script's first line and its last. So the fix is
to fold the whole read-decide-write into one script and run it with a single call. The read (is the lock still held?
is this the right token?), the decision (completed or failed; past max attempts?), and every write (clear the lock,
record the result, move the id, bump metrics, fetch the next) happen as one indivisible step. No second client can
interleave, because Redis runs the script to completion before it serves the next command.

In EchoMQ this script is `moveToFinished-14.lua`, dispatched by `EchoMQ.Scripts.move_to_finished/7`. It touches
**fourteen keys** — the whole queue shape — and it does the finish AND the next fetch in one round trip: `fetch_next`
defaults to `1`, so the same call that finishes the current job pops the next one from `wait` into `active`. The
lifecycle transition and the next fetch are one atomic move.

## Redis commands used

- `EVALSHA sha numkeys key… arg…` — run a cached script by its SHA; cheap, because the script body is not on the wire.
- `SCRIPT LOAD script` — cache the body once, get back the SHA the client then calls by.
- `EVAL script numkeys key… arg…` — run the full body; the fallback when the SHA is not cached (`NOSCRIPT`).

The script body itself runs the queue moves — `LPUSH`/`RPOPLPUSH` over the `wait`/`active` lists, `ZADD` over the
`completed`/`failed`/`delayed`/`prioritized` sorted sets, `HSET` on the job hash — but the client issues exactly one
command: the `EVALSHA`. That is the point. A multi-key, multi-structure transition reaches Redis as one indivisible
call.

## When to use

Use the atomic-script transition whenever a job's move reads state, branches on it, and writes across more than one
key — and a second process can run the same move at the same time. A queue's finish is exactly that: it reads the lock
and the attempt count, branches to `completed` or `failed`, and writes across the lists, the sorted sets, the job
hash, and the metrics. A recovery sweep runs concurrently by design. The transition must be one step.

## When to avoid

A single-key, single-command update needs no script — `INCR`, `SET … GET`, `GETDEL` are already atomic on their own.
Reach for the script only when the move spans multiple keys or carries a branch. And keep the keys on one node: a Lua
script may only touch keys in the same slot, so a clustered queue co-locates its keys with a hash tag (the R2.05
treatment) before a fourteen-key script can run at all.

## The three dives

This module takes the transition in three parts, in order:

- **States as locations** — a job's state is a place in Redis, not a status field: `wait` and `active` are LISTs;
  `delayed`, `prioritized`, `completed` and `failed` are ZSETs. A transition moves the id from one structure to
  another and updates the job hash.
- **Read-decide-write in one EVALSHA** — the transition is a read-modify-write, and `moveToFinished-14.lua` runs the
  whole of it as one `EVALSHA` over fourteen keys, finishing the job and fetching the next as one step.
- **EVALSHA and NOSCRIPT** — how the script gets to the server: `SCRIPT LOAD` returns a SHA, the client calls
  `EVALSHA`, and a flushed cache returns `NOSCRIPT` so the client falls back to `EVAL` and re-caches.

### The pattern, applied

The atomic-updates pattern says a read-modify-write across multiple keys must be one server-side script, or concurrent
clients interleave. In EchoMQ that script is `moveToFinished-14.lua`, wrapped by `EchoMQ.Scripts.move_to_finished/7`
(arity-7: `conn`, `ctx`, `job_id`, `token`, `result`, `target`, `opts`, where `target` is `:completed` or `:failed`;
the wrappers `move_to_completed/6` and `move_to_failed/6` delegate to it). One `EVALSHA`, fourteen keys, the job
finished and the next fetched — one indivisible transition.

A door, not a depth: this module cites one excerpt — the fourteen-key `moveToFinished` and the `EVALSHA`/`NOSCRIPT`
fallback — as proof the transition ships. The worker fetch loop that calls it (E2 · the engine) and the full lifecycle
transitions with their fourteen-key include graph (E6 · the lifecycle) are the dedicated EchoMQ course.

## References

### Sources
- [Redis — EVALSHA](https://redis.io/commands/evalsha/) — run a cached script by its SHA; the cheap call that drives
  every lifecycle transition.
- [Redis — EVAL / scripting](https://redis.io/commands/eval/) — why a Lua script is one atomic step in the single
  command thread, so the read-decide-write cannot interleave.
- [Redis — SCRIPT LOAD](https://redis.io/commands/script-load/) — cache the script body once and get back the SHA the
  client calls by.
- [Redis — Scripting with Lua](https://redis.io/docs/latest/develop/interact/programmability/eval-intro/) — the model
  for why a script runs to completion before any other command.
- [BullMQ — the queue protocol](https://bullmq.io/) — the `moveToFinished` lifecycle EchoMQ ports, where "the Lua
  scripts are the protocol."

### Related in this course
- [R3 · Reliable Queues](/redis-patterns/queues) — the chapter: the whole reliable-queue family.
- [R3.04.1 · States as locations](/redis-patterns/queues/atomic-state-machine/states-as-locations) — a job's state is
  the Redis key its id lives in.
- [R3.04.2 · Read-decide-write in one EVALSHA](/redis-patterns/queues/atomic-state-machine/read-decide-write-in-one-evalsha) —
  the fourteen-key transition as one indivisible call.
- [R3.04.3 · EVALSHA and NOSCRIPT](/redis-patterns/queues/atomic-state-machine/evalsha-and-noscript) — load once, run
  by SHA, fall back on a flushed cache.
- [R3 · States as locations](/redis-patterns/queues/states-as-locations) — the standalone orientation dive: the family
  framing.
- [R3.03 · Stalled recovery](/redis-patterns/queues/stalled-recovery) — the sweep that must not interleave the finish.
- [R2.01 · Atomic updates](/redis-patterns/coordination/atomic-updates) — the one-script read-modify-write pattern this
  module applies to the lifecycle.
- [E2 · The engine](/echomq/core) — the dedicated EchoMQ course: the worker fetch loop that calls `moveToFinished`.
- [E6 · The job lifecycle](/echomq/lifecycle) — the lifecycle transitions and the fourteen-key include graph.
