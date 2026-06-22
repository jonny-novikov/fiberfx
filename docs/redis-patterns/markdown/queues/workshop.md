# A reliable enrollment queue — lose no job, corrupt no state

> Route: `/redis-patterns/queues/workshop` · R3.06 · the capstone workshop (no dives) · Chapter R3 Reliable Queues.
> · An *applied synthesis*: Portal does NOT run on EchoMQ today — EchoMQ is the candidate for Portal's reserved
> F7–F9 multi-runtime layer. This page is the applied design — "if Portal's enrollment jobs ran through a reliable
> EchoMQ queue, here is how each guarantee maps." Grounding: the same verified EchoMQ symbols R3.01–R3.05 cite
> (`EchoMQ.Scripts.move_to_active/4`, `move_stalled_jobs_to_wait/4`, `move_to_finished/7`, `EchoMQ.Keys.marker/1`)
> plus Portal's real, already-idempotent enroll (`Portal.enroll/2` → `Portal.Enrollment.enroll/2`, the event
> `%Portal.Enrollment.Events.LearnerEnrolled{}`, the guard `Portal.Engine.Core.authorize/2` →
> `{:error, :already_enrolled}`). All real in `echo/apps/echomq` and `echo/apps/portal`.

The chapter taught five patterns: the processing list (R3.01), at-least-once delivery (R3.02), stalled recovery
(R3.03), the atomic state machine (R3.04), and blocking versus polling (R3.05). This capstone is the one worked design
that needs all five at once — a reliable queue for a single, concrete job: **enrolling a learner in a Portal course.**

## The scenario — enrollment as a job

Portal enrolls a learner in a course. Frame that enrollment as a *job*: an enrollment request is enqueued, a worker
processes it, and the job is completed once. "Reliable" means two things at the same time. A worker crash never drops
an enrollment — the learner is enrolled, eventually, even if the first worker dies mid-process. And a worker crash
never enrolls a learner into a corrupt half-state — no torn write where the seat is taken but the roster row is
missing, and no double-enrollment when the job runs twice.

Be plain about the boundary. Portal's enroll is **synchronous today** and does NOT run through EchoMQ. EchoMQ is the
candidate for Portal's reserved F7–F9 multi-runtime layer. This workshop is the *applied design*: the reliable-queue
path R3 built, laid over an enrollment job, so each pattern's guarantee maps to a real failure it prevents. The Redis
keys and Lua scripts are EchoMQ's real ones; the wiring of enroll-as-a-queue-job is the design this page assembles,
not Portal's current architecture.

## The assembled path — R3.01 through R3.05, in order

Five patterns assemble into one reliable loop. Each prevents a different failure of the naive form (pop a job, process
it, done), and they build in order.

**R3.01 — the processing list.** The enroll job moves from `wait` to `active` under a lock in one atomic step. EchoMQ's
`moveToActive-11.lua` runs `RPOPLPUSH wait active` (run by `EchoMQ.Scripts.move_to_active/4`): the job leaves
`emq:{queue}:wait` and lands in `emq:{queue}:active` as one command, never in neither list. A crash mid-process
leaves the job parked in `active`, recoverable — not lost.

**R3.02 — at-least-once.** The in-flight move makes redelivery *possible*, which is the point. A worker that enrolls
the learner, then crashes before it acknowledges the job, leaves the job in `active`; on recovery it is redelivered.
Exactly-once delivery is a lie — the acknowledgement itself can be lost — so the honest guarantee is **at-least-once**:
the enroll job runs one or more times, never zero. The responsibility shifts to the consumer.

**R3.03 — stalled recovery.** The dead worker's lock expires. A separate sweep, `moveStalledJobsToWait-8.lua` (run by
`EchoMQ.Scripts.move_stalled_jobs_to_wait/4`), finds each job in `active` whose lock has expired and returns it to
`wait` for another worker. The enroll job re-enters the normal pickup path; a second worker runs it. A job is only
truly lost if both the sweep and every worker fail at once.

**R3.04 — the atomic state machine.** The finish is one `moveToFinished-14.lua` (`EVALSHA`, run by
`EchoMQ.Scripts.move_to_finished/7`, `fetch_next` default 1): drop the lock, record the result, move the job from
`active` to `completed`, and fetch the next job — fourteen keys, one indivisible script. There is no window where the
lock is gone but the job is still in `active`, so a crash never leaves a half-finished enrollment.

**R3.05 — blocking versus polling.** Between jobs a worker blocks on the marker, `emq:{queue}:marker`
(`EchoMQ.Keys.marker/1`, a ZSET), via `BZPOPMIN` (`EchoMQ.Worker.wait_for_job/2` → `do_wait_for_job/3`). Enqueuing an
enroll job runs `ZADD marker 0 "0"` (`addBaseMarkerIfNeeded`), which wakes a blocked worker with no polling loop and
no idle CPU burn.

## The synthesis — at-least-once + idempotent enroll = exactly-once-in-effect

The assembled queue guarantees at-least-once delivery, so the enroll job CAN run twice. That is safe, because
**Portal's enroll is already idempotent.** `Portal.Engine.Core.authorize/2` checks the folded enrollment state before
any event is recorded:

```elixir
# Portal.Engine.Core.authorize/2 — the real guard (echo/apps/portal/lib/portal/engine/core.ex)
if MapSet.member?(enrolled, course_id), do: {:error, :already_enrolled}, else: :ok
```

A first enroll appends `%Portal.Enrollment.Events.LearnerEnrolled{user_id, course_id, at}` and the learner is
enrolled. A redelivered enroll of the same learner into the same course hits the guard, returns
`{:error, :already_enrolled}` (a real, closed `Portal.Error` code), and records nothing. Enrolling twice equals
enrolled once.

This is the chapter's thesis, fully assembled. A reliable queue (at-least-once, in-flight under a lock, stalled
recovery, atomic finish) plus an idempotent consumer loses no work and corrupts no state. In Portal the consumer is
`Portal.enroll/2` (delegating to `Portal.Enrollment.enroll/2`), already idempotent via the `:already_enrolled` guard.
At-least-once delivery over an idempotent effect is **exactly-once-in-effect** — the whole reliable design, in one
worked job.

## The assembled path, over a Portal enroll job

```text
Applied design — Portal does not run on EchoMQ today.
  enqueue        → ZADD emq:{queue}:marker 0 "0"        (wake a blocked worker)
  worker         → BZPOPMIN emq:{queue}:marker          (R3.05 — block, no polling)
  pick up        → moveToActive-11   RPOPLPUSH wait active, take the lock   (R3.01 — in-flight)
  process        → Portal.enroll/2  → %LearnerEnrolled{}                    (the effect)
                   on redelivery     → {:error, :already_enrolled}          (idempotent — a no-op)
  finish         → moveToFinished-14 (one EVALSHA: drop lock, record, active→completed, fetch next)  (R3.04)
  crash mid-job? → lock expires → moveStalledJobsToWait-8 returns it to wait → retry  (R3.02 + R3.03)
```

## Grounded in EchoMQ's iconic Elixir move and Portal's real enroll

Every Redis primitive in the assembled path is real EchoMQ code in the iconic Elixir app `echo/apps/echomq`, the same
symbols R3.01–R3.05 each cite. `EchoMQ.Scripts.move_to_active/4` runs `moveToActive-11.lua`;
`EchoMQ.Scripts.move_stalled_jobs_to_wait/4` runs `moveStalledJobsToWait-8.lua`;
`EchoMQ.Scripts.move_to_finished/7` runs `moveToFinished-14.lua`. The worker blocks on `EchoMQ.Keys.marker/1`
(`emq:{queue}:marker`) via `BZPOPMIN`, and a job add wakes it with `ZADD marker 0 "0"`. EchoMQ's governing rule is
*"the Lua scripts ARE the protocol"* — the same scripts are meant to run identically across the Elixir, Go, and
Node.js runtimes — and the honest status is that the three are not at parity; the iconic Elixir runtime is the most
complete.

The consumer is real Portal code in `echo/apps/portal`. The command is `Portal.enroll/2`, the `Portal` facade
function that delegates to `Portal.Enrollment.enroll/2`. The recorded fact is
`%Portal.Enrollment.Events.LearnerEnrolled{user_id, course_id, at}`, emitted by `Portal.Engine.Core.decide/2` and
folded by `evolve/2`. The idempotency guard is `Portal.Engine.Core.authorize/2`, which returns
`{:error, :already_enrolled}` against the folded state — the closed `Portal.Error` code that makes a redelivered
enroll a safe no-op.

The reliable-queue pattern says: a reliable queue plus an idempotent consumer loses no work and corrupts no state. In
Portal, the queue is the EchoMQ path R3 assembled and the consumer is `enroll/2`, already idempotent — so the assembled
design is exactly-once-in-effect.

The engine that runs these scripts — the full Lua inventory, the heartbeat manager, the stalled-check coordination
across a worker pool, and the three runtime implementations — is the dedicated **EchoMQ course**. This workshop closes
R3 with one reliable job; that course teaches the engine behind it.

## References

### Sources
- [Redis — RPOPLPUSH](https://redis.io/commands/rpoplpush/) — the atomic in-flight move (wait → active), the heart of
  `moveToActive-11.lua`.
- [Redis — EVALSHA](https://redis.io/commands/evalsha/) — the atomic finish: `moveToFinished-14.lua` runs as one cached
  script.
- [Redis — BZPOPMIN](https://redis.io/commands/bzpopmin/) — the worker blocks on the marker between jobs; no polling
  loop.
- [Redis — SET](https://redis.io/commands/set/) — `SET NX PX`, the job lock lease whose expiry signals a dead worker.
- [Redis — Redis queue (glossary)](https://redis.io/glossary/redis-queue/) — the reliable-queue model assembled here.
- [BullMQ — the queue protocol](https://bullmq.io/) — the reliable worker path EchoMQ ports, where "the Lua scripts are
  the protocol."

### Related in this course
- [R3 · Reliable Queues](/redis-patterns/queues) — the chapter this workshop closes.
- [R3.01 · The processing list](/redis-patterns/queues/processing-list) — the in-flight move (wait → active under a
  lock).
- [R3.02 · At-least-once](/redis-patterns/queues/at-least-once) — the delivery guarantee the idempotent consumer pays
  for.
- [R3.03 · Stalled recovery](/redis-patterns/queues/stalled-recovery) — the sweep that returns a dead worker's job to
  wait.
- [R3.04 · The atomic state machine](/redis-patterns/queues/atomic-state-machine) — the one-script finish.
- [R3.05 · Blocking vs polling](/redis-patterns/queues/blocking-vs-polling) — the blocking pickup on the marker.
- [EchoMQ · The core](/echomq/core) — the door: the engine that runs these scripts across three runtimes (the
  dedicated EchoMQ course).
