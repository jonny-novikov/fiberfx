# The in-flight list — the recovery ledger

> Route: `/redis-patterns/queues/processing-list/the-in-flight-list` · Dive R3.01.3 · Module R3.01 Processing list.
> · Grounding: EchoMQ's `emq:{queue}:active` sorted set (`EchoMQ.Keyspace.queue_key(queue, "active")`) is the in-flight
> ledger a crashed worker leaves a job parked in; each member is **scored at its lease deadline** on the server clock,
> so the score is the recovery clock — no per-worker list needed. The ack is `EchoMQ.Jobs.complete/4`, token-fenced on
> the row's `attempts` value. `EchoMQ.Jobs.reap/2` returns any member whose lease score has passed `now` to `pending`;
> `EchoMQ.Stalled.check/3` counts repeated stalls and dead-letters a job past its threshold to the durable floor. Real
> in `echo/apps/echo_mq`.

The in-flight list is not a buffer to pass jobs through quickly. It is a ledger: at any instant it holds exactly the
jobs currently being processed. Because a job stays in the ledger until the work is acknowledged, a worker that dies
mid-job leaves its job sitting in the ledger — found, attributed, and returnable. That property is the whole reason the
move into the list is atomic. This dive reads the list as a record of in-flight work.

## The list is a record, not a buffer

A job moved into `active` does not pass through — it stays there for the entire duration of the work, and only an
explicit acknowledgement removes it. So `active` is a live record: every job in it is a job a worker has taken and not
yet finished. Reading the list answers a question that matters for reliability — what work is in flight right now —
without any extra bookkeeping. The record is the list itself.

```
emq:{queue}:active  →  [ job 7, job 6 ]   two jobs in flight
```

This is what makes a crash recoverable. When a worker dies between taking a job and acknowledging it, the job is still
in `active`. Nothing was lost, because nothing removed it. A recovery process can read the list and find the parked job,
exactly because the list is a record of in-flight work and not a transient buffer.

## Per-worker lists, or a lease score

One shared in-flight list works, but it cannot tell which worker holds which job. The classic LIST form gives each
worker its own in-flight list — `processing:worker1`, `processing:worker2`. A job in `processing:worker1` is held by
worker 1. When worker 1 dies, a recovery monitor reads worker 1's list, finds the parked jobs, and returns them to the
waiting list for another worker — `LMOVE processing:worker1 work_queue RIGHT RIGHT`. Per-worker lists make the
attribution direct: the list name is the worker.

```
processing:worker1   jobs held by worker 1
processing:worker2   jobs held by worker 2
```

A real engine refines the death signal beyond "how long has the job sat here." EchoMQ scores each member of
`emq:{queue}:active` at its lease deadline on the server clock; a member whose score has passed `now` is a worker that
stopped renewing, and `EchoMQ.Jobs.reap/2` returns it to `pending`. The lease score is the death signal, so EchoMQ needs
no per-worker list — the ledger's own score names the deadline. R3.03 is the count-thresholded sweep on top.

## The ack removes it only when done

A job leaves the in-flight list with one command: `LREM active 1 job` — remove one occurrence of this job from the
list. The discipline is *when* it runs: only after the work is truly complete. Run it too early — before the side effect
is durable — and a crash after the ack but before the effect loses the job for real, because the ledger no longer holds
it. Run it after the effect, and a crash before the ack leaves the job parked, recoverable, and redelivered.

```
job = RPOPLPUSH wait active   # take the job into the in-flight ledger
process(job)                  # do the work; durable side effect lands here
LREM active 1 job             # ack: remove from the ledger ONLY now
```

That ordering is what makes delivery at-least-once rather than at-most-once. A job is delivered again if the worker died
before the ack, and delivered once if the ack landed — never zero times. The cost is that a worker which finished the
work and died before the ack redelivers the job, which is why R3.02 makes the consumer idempotent. This dive's job is
the ledger and the ack; the redelivery cost is the next module's.

## The pattern, applied

EchoMQ's in-flight list is the `emq:{queue}:active` sorted set, built by `EchoMQ.Keyspace.queue_key(queue, "active")`,
real in `echo/apps/echo_mq`. The ack is `EchoMQ.Jobs.complete/4`: it is token-fenced on the row's `attempts` value, so
only the worker that holds the current lease can retire the job — a worker whose lease was reaped and re-claimed by
another worker is refused, and a redelivered completion is a no-op. A crash leaves the id in `active`, and `reap/2`
returns any member past its lease score to `pending`. A job that stalls repeatedly past `EchoMQ.Stalled`'s threshold is
dead-lettered to `emq:{queue}:dead` and folds onward to the durable floor (`EchoStore.StreamArchive` → the Graft page
engine), the persistence frontier the `/echo-persistence` course follows.

```
-- the ack and the recovery clock (echo/apps/echo_mq/lib/echo_mq/jobs.ex)
-- complete/4: token-fenced on attempts, only the lease holder may retire the row
local att = redis.call('HGET', KEYS[2], 'attempts')      -- KEYS[2] = the job row
if att ~= ARGV[2] then return redis.error_reply('EMQSTALE complete token mismatch') end
redis.call('ZREM', KEYS[1], ARGV[1])                     -- KEYS[1] = emq:{queue}:active, remove from the ledger
-- reap/2: any member whose lease score has passed now returns to pending
```

The branded `JOB` id is gated at the key builder; the lease score is the server clock (`TIME`). The reaper, the stalled
sweep, and the archive into the durable floor are the dedicated EchoMQ Queue pillar and the persistence course; this
dive teaches the ledger and the ack.

## References

### Sources
- [Redis — Lists](https://redis.io/docs/latest/develop/data-types/lists/) — the list as a record of ordered elements,
  the in-flight ledger.
- [Redis — LREM](https://redis.io/commands/lrem/) — the ack: remove one occurrence of a job from the in-flight list
  after the work is done.
- [Redis — RPOPLPUSH](https://redis.io/commands/rpoplpush/) — the move that parks a job in the in-flight ledger
  atomically.
- [Valkey — ZADD](https://valkey.io/commands/zadd/) — score a member of a sorted set, how EchoMQ records the lease
  deadline that doubles as the recovery clock.

### Related in this course
- [R3.01 · Processing list](/redis-patterns/queues/processing-list) — the module hub: the in-flight move.
- [R3.01.1 · List as wait + active](/redis-patterns/queues/processing-list/list-wait-active) — the two named places.
- [R3.01.2 · LMOVE / RPOPLPUSH](/redis-patterns/queues/processing-list/lmove-rpoplpush) — the atomic move that parks the
  job in this ledger.
- [R3 · The reliable queue](/redis-patterns/queues/the-reliable-queue) — at-least-once and stalled recovery, the
  guarantees this ledger enables.
- [/echomq/queue](/echomq/queue) — the dedicated EchoMQ Queue pillar: the leased state machine in depth.
- [/echo-persistence](/echo-persistence) — the durability floor a dead-lettered job folds onto.
