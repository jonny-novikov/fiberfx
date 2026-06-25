# Cancellation & checkpoints

> Route: `/echomq/queue/lifecycle-controls/cancellation-and-checkpoints` · surface: dive · grounding: all **real code**
> in `echo/apps/echo_mq` — `EchoMQ.Cancel.{new/0, cancel/3, check/1, check!/1}` + `EchoMQ.Cancel.Cancelled`,
> `EchoMQ.Jobs.extend_lock/5` + the `@extend_lock` Lua, `EchoMQ.Stalled.{check/3, job_stalled?/4}` + the `@sweep_stalled`
> Lua. No `[RECONCILE]` markers.

## The fact — control over the worker in hand

A claimed job is held by a worker for the length of its lease. Three controls act on that worker while it runs:

- **Cancel it cooperatively** — ask a long handler to stop its own work at a safe point, without a forced kill
  mid-transaction.
- **Checkpoint its lease** — re-score the active member to a fresh deadline so a long-but-alive handler is not reaped
  mid-work.
- **Recover the ones that stalled** — sweep the active set for leases that lapsed without a checkpoint, recover them, and
  dead-letter the ones that keep stalling.

## Cancellation is cooperative and worker-side

`EchoMQ.Cancel` is a host-side primitive with **no wire identity**. The token is a plain `make_ref/0`; cancellation is a
process message. `new/0` mints a token. `cancel/3` sends `{:emq_cancel, token, reason}` to a pid's mailbox. `check/1` is
a non-blocking `receive after 0` that answers `{:cancelled, reason}` if a cancellation for **this** token is waiting,
else `:ok`. `check!/1` raises `EchoMQ.Cancel.Cancelled` for a checkpoint-style handler.

Cooperative means a handler that never checks completes normally — cancellation does not interrupt it. The `^token` pin
ensures a handler only catches its own cancellation. This is a local primitive: a long handler calls `check!/1` at safe
points and aborts where it is asked to, leaving no half-finished transaction.

## extend_lock checkpoints the lease

The lease is the active-set score. `extend_lock/5` runs `@extend_lock`: `HGET attempts`, fence the token (a stale token
answers `EMQSTALE`), read the server `TIME`, and `ZADD KEYS[1]` (the active set) at `now + lease` for this id. It
re-scores the member to a fresh deadline.

Beat one — the handle. `extend_lock/5` builds the active set and the row, passes the id, token, and lease, and maps the
return: `1` → `:ok`, a missing row → `{:error, :gone}`, a stale token → `{:error, :stale}`.

Beat two — `@extend_lock`. The token fence first, then the server-clock re-score. A long-but-alive handler calls
`extend_lock/5` periodically so its deadline always sits ahead of now — so the reaper never sees it as expired. Because
the lease **is** the active score, there is no separate lock string to refresh; the checkpoint re-scores the one member
that already represents the lease, and it is token-fenced so only the current holder may extend.

## Stalled recovery is count-thresholded, on top of reap

The reaper (`Jobs.reap/2`) returns any expired-lease job from active to pending once, with no count — crash recovery.
`EchoMQ.Stalled` is the count-thresholded layer above it. `@sweep_stalled` reads the expired members on the server clock,
and for each one increments a per-job `stalled` field. A job below the `max_stalled` threshold (default 1) is recovered —
back to pending, or to its lane if it is grouped. A job at or above the threshold is dead-lettered: `HSET state dead`,
`HSET last_error stalled`, `ZADD dead`, and the failed metric increments.

`check/3` runs one sweep and answers `{:ok, %{recovered: [id], dead: [id]}}` — the ids returned to pending and the ids
dead-lettered this pass. `job_stalled?/4` answers whether a job's `stalled` field is present and positive. The sweep may
run on its own opt-in periodic process, or be direct-driven by `check/3` for an operator's one-shot recovery.

So a worker that stalls once is recovered; a worker that keeps stalling on the same job — a poison job that hangs every
worker that picks it up — is not recovered forever. The count is the difference between a transient slow handler and a
job that should die.

## Worked example

A worker claims a job with a 30-second lease, runs for 90 seconds, and checkpoints with `extend_lock/5` every 20
seconds. Its active deadline always sits ahead of now, so neither the reaper nor the stalled sweep touches it. A second
worker claims a different job and crashes silently. Its lease lapses; the sweep increments its `stalled` field to 1,
which is at the default threshold, so it is dead-lettered with `last_error = "stalled"`.

## Interactive 1 (hero) — the lease timeline

A claimed job's lease deadline against a "now" the reader advances, with a checkpoint button that re-scores the deadline.
The readout shows whether the reaper would reclaim the job (now past the deadline) — and how a checkpoint moves the
deadline ahead. Pure: reclaim is `now > deadline`.

## Interactive 2 (main) — the stalled-sweep ladder

Step a job through repeated stalls at a chosen `max_stalled`. The readout shows each pass: the `stalled` count after the
increment, and whether the job is recovered (below threshold) or dead-lettered (at/above). Pure over the real sweep
logic.

## Bridge

- The pattern (Redis Patterns Applied): a reliable queue checkpoints a worker's lease and reclaims abandoned work on a
  recovery pass. `/redis-patterns/time-delay-priority` and `/redis-patterns/queues` teach the lease-and-recover machinery.
- The implementation (echo_mq): the lease is the active score, `extend_lock/5` re-scores it, and `EchoMQ.Stalled` is the
  count-thresholded sweep on top of the reaper.

## Take

The lease is a score; a checkpoint moves it; a cancel is a message a handler chooses to honour; recovery counts how many
times a job has stalled before it gives up on it. Control over the worker in hand is three small, fenced moves.

## The durable floor (the door to Echo Persistence)

When the sweep gives up on a poison job it dead-letters it, kept for inspection. A checkpoint and a dead-letter are both
moments worth keeping past memory: when a queue trims its history, `EchoStore.StreamArchive` folds the trimmed segments
into the durable `EchoStore.Graft` floor (CubDB's append-only B-tree, on to Tigris) — deep history without resident
memory, readable beside the live tail. The fold is real code
(`echo/apps/echo_store/lib/echo_store/{stream_archive,graft}.ex`); the durable floor is taught in full in Echo
Persistence (`/echo-persistence`), per `docs/echo/bcs/bcs.3.md` B3.3 / `bcs.5.md`.

## References

### Sources
- valkey.io/commands/zadd/ — the active-set re-score that is the lease checkpoint.
- valkey.io/commands/hincrby/ — the per-job `stalled` count the sweep increments.
- redis.io/commands/evalsha/ — the load-once dispatch the checkpoint and sweep run by SHA.
- valkey.io/docs/ — the substrate of record.

### Related in this course
- /echomq/queue — The Queue.
- /echomq/queue/lifecycle-controls — the module hub.
- /echomq/protocol — the keyspace and the Lua layer these controls run on.
- /redis-patterns/time-delay-priority — the lease/recover family.
- /echo-persistence — the durable floor a dead-lettered, trimmed job folds into.
