# R3 · Reliable Queues

> Route: `/redis-patterns/queues` · Chapter landing (manifest) · BCS contract-sheet identity (redis-red).
> Grounding: the real **EchoMQ** worker path — the leased state machine in `echo/apps/echo_mq` (`EchoMQ.Jobs`,
> `EchoMQ.Consumer`, `EchoMQ.Stalled`, `EchoMQ.Lanes`, `EchoMQ.Keyspace`), worked through the **codemojex** consumer
> (`echo/apps/codemojex`). Engine: Valkey. Doors: `/echomq/queue` (the Queue pillar) + `/echo-persistence` (the
> durable floor) + `/bcs`.

A reliable queue loses no job. This is the pivot chapter of the course: with a queue that survives a crash, every
later chapter is a different surface over the same jobs.

## Overview

A naive queue pops a job off one end and hands it to a worker. The moment that worker crashes — mid-job, before the
work is acknowledged — the job is gone from Valkey and gone from memory, with nothing to reclaim it. The
reliable-queue family is the set of techniques that close that gap and the others around it: where a job sits while
in flight, how a duplicate delivery is made harmless, how a dead worker's job comes back, how the whole lifecycle
moves without tearing, and how a worker waits for work without burning CPU.

EchoMQ implements every one of these as a **leased state machine** over Valkey, and that worker path is the worked
example for the chapter. A job is a branded `JOB` id; its row is a Valkey hash at `emq:{q}:job:<id>`; the pending set
is a score-0 sorted set so byte order is mint order. `EchoMQ.Jobs.claim/3` pops the oldest pending id with
`ZPOPMIN`, mints a lease on the **server clock** (`TIME`), and increments the row's `attempts` field — the fencing
token. A crash leaves the job in the active set with an expired lease, and `EchoMQ.Jobs.reap/2` returns it to
pending. The state is never a place a crash can erase.

## Why & when

Reach for the reliable-queue family whenever losing a job is not acceptable and a worker can crash at any instant —
which is every real background-job system. Each failure mode below has one matching technique, and the chapter is the
set of those answers.

- **A worker crashes mid-job.** The job must not vanish when a worker dies — claim it under a server-clock lease, and
  reap it back to pending when the lease expires.
- **A job runs twice.** At-least-once delivery means a job can arrive more than once — make the consumer idempotent
  and key the effect on the branded `JOB` id.
- **A multi-step transition tears.** A lifecycle move touches the row, a set, and a counter and must be
  all-or-nothing — run the whole transition as one inline Lua script.
- **The worker busy-polls the queue.** A worker that loops on the queue burns CPU and adds latency — park on a wake
  key and let Valkey wake it.

## The patterns

Six teaching modules, then a workshop. Each module is a hub with three dives, grounded in the real EchoMQ worker
path.

- **R3.01 · Processing list** — move a job *into* a recoverable in-flight state; the real mechanism is the leased
  `EchoMQ.Jobs.claim/3`, not a list pop.
- **R3.02 · At-least-once** — delivery guarantees and idempotent consumers; the branded `JOB` id is the idempotency
  key. Why exactly-once is a lie.
- **R3.03 · Stalled recovery** — reclaim a dead worker's job by lease expiry on the server clock; `EchoMQ.Stalled`
  the count-thresholded sweep, and the durable floor a repeatedly-stalled job reaches.
- **R3.04 · Atomic state machine** — the lifecycle as one inline `EchoMQ.Script.new/2` Lua transition; states are
  `emq:{q}:` locations, read-decide-write in one EVALSHA, the gated branded `JOB` id.
- **R3.05 · Blocking vs polling** — stop busy-polling; the `EchoMQ.Consumer` parks on the wake key with `BLPOP`.
- **R3.06 · Workshop** — a reliable codemojex guess-command queue: `Codemojex.Guesses.submit/3` enqueues a `JOB` on
  the player's fair lane, `Codemojex.ScoreWorker.handle/1` drains it through `EchoMQ.Lanes.claim/3`.

## How to apply

The hard part is matching the reliable-queue technique to the failure you cannot allow. Name the failure, and the
technique — and the real EchoMQ artifact that implements it — follows.

| Failure | Technique | The EchoMQ artifact |
|---|---|---|
| A worker crashes mid-job | leased claim + reap | `EchoMQ.Jobs.claim/3` lease on server `TIME`; `EchoMQ.Jobs.reap/2` |
| A job runs twice | idempotent effect keyed by the `JOB` id | the branded `JOB` id; `EchoMQ.Jobs.complete/5` |
| A multi-step transition tears | one inline Lua transition | `EchoMQ.Script.new/2` run by `EchoMQ.Connector.eval/4` |
| The worker busy-polls | park on the wake key | `EchoMQ.Consumer` `BLPOP emq:{q}:wake` |

There is no single reliable-queue trick — only the technique that closes the failure you cannot accept, each one a
real move in EchoMQ's worker loop.

## The workshop — codemojex's guess-command queue

The chapter closes with R3.06: a reliable codemojex guess-command queue assembled from R3.01–R3.05.
`Codemojex.Guesses.submit/3` mints a branded `JOB` id and enqueues it on the player's fair lane with
`EchoMQ.Lanes.enqueue/5`; `Codemojex.ScoreWorker.handle/1` — wired as an `EchoMQ.Consumer` with `lease_ms: 10_000` —
drains the lane through `EchoMQ.Lanes.claim/3`, scores the guess, and completes the job with
`EchoMQ.Jobs.complete/5`. A worker that crashes mid-score leaves its `JOB` leased in the active set; the next reap
returns it to its lane. A guess is never lost, and one keyboard masher cannot starve the field because the lane is
named by the player.

## The road ahead — R4 to R8

R3 is the spine the rest of the course hangs from. Each later chapter is a different surface over the same jobs: R4
schedules and prioritizes them with the sorted set as a clock; R5 records the durable event log; R6 holds the tier
stable under load; R7 attends to how the job data lives in RAM; R8 operates the tier in production. A job that
exhausts its retries or is archived reaches the **durable floor** — the persistence tier behind `/echo-persistence`.

## References

### Sources

- [Valkey — ZPOPMIN](https://valkey.io/commands/zpopmin/) — the pop that claims the oldest pending job from the
  score-0 mint-ordered set, the engine the connector is gated against.
- [Valkey — HINCRBY](https://valkey.io/commands/hincrby/) — increments the row's `attempts` field, the lease fencing
  token that makes a stale completion a no-op.
- [Redis — Scripting with Lua](https://redis.io/docs/latest/develop/interact/programmability/eval-intro/) — the
  atomic lifecycle transition via EVAL / EVALSHA that every EchoMQ script runs.
- [Redis — Patterns](https://redis.io/docs/latest/develop/use/patterns/) — the canonical write-ups of the reliable
  work-queue access pattern.

### Related in this course

- [R2 · Coordination](/redis-patterns/coordination) — the atomic moves and lock lease R3 builds on.
- [R4 · Time, Delay & Priority](/redis-patterns/time-delay-priority) — the sorted set as a clock over R3's jobs.
- [/echomq/queue](/echomq/queue) — the EchoMQ Queue pillar: the state machine, lanes, and the schedule set in depth.
- [/echo-persistence](/echo-persistence) — the durable floor a dead-lettered or archived job reaches.
- [The Branded Component System](/bcs) — Part III builds the EchoMQ bus these patterns ground in.
