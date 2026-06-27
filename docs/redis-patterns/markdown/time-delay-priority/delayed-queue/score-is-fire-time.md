# The score is the fire-time

> R4.01.1 · dive 1. The score of a delayed job is the time it should run. The textbook puts a raw Unix timestamp in
> the score; EchoMQ scores the `schedule` set by the run-at millisecond — the caller's for `enqueue_at`, `now + delay`
> from the server clock for `enqueue_in` — while the mint-ordered branded `JOB` id stays the sort key once promoted.

**Route:** `/redis-patterns/time-delay-priority/delayed-queue/score-is-fire-time`

A delayed queue is a sorted set whose score carries the meaning. For a delayed job that meaning is its fire-time —
the moment it becomes eligible to run. Score a job by its fire-time and the set orders its members by when they are
due, head first. The whole pattern rests on one decision: what number goes in the score. The textbook answer is the
fire-time itself. EchoMQ's answer is the run-at millisecond, computed on the server clock for a relative delay, with
a second ordering carried not by the score but by the branded id the job already has.

## The textbook score: the fire-time itself

The classic delayed-queue pattern puts the Unix timestamp at which the task should run directly into the score:

```
ZADD delayed_queue 1706649000 "task:abc123"
```

The score is the fire-time, second-for-second. The set sorts by it, so the earliest-due task is at the head, and a
range query bounded by the current clock returns the due tasks. The fire-time of a deferred task is `now + delay` — to
defer five minutes, score by `now + 300`. One number, one meaning: when this task should run.

This is enough for most schedulers. Its one weak spot is resolution. A coarse score gives every task scheduled in the
same tick the identical score, and a sorted set keeps members with equal scores in lexicographic order of the member,
not arrival order. The question every real scheduler answers is: when two jobs share a tick, what breaks the tie — and
that answer is what EchoMQ moves on.

## EchoMQ's score: the run-at millisecond, on the server clock

EchoMQ keeps the structure and prices the score precisely. The schedule set is `emq:{<queue>}:schedule`
(`EchoMQ.Keyspace.queue_key(queue, "schedule")`), and the score is the run-at **millisecond**. There are two ways to
say when:

```
EchoMQ.Jobs.enqueue_at(conn, queue, job_id, payload, run_at_ms)
EchoMQ.Jobs.enqueue_in(conn, queue, job_id, payload, delay_ms)
```

`enqueue_at/5` takes an absolute run-at millisecond — the caller names the wall-clock instant, and that integer is the
score. `enqueue_in/5` takes a relative delay, and the run-at score is computed wire-side, inside the script, from the
server's own clock:

```
local t = redis.call('TIME')
local now = t[1] * 1000 + math.floor(t[2] / 1000)   -- the server clock, in milliseconds
score = now + tonumber(ARGV[4])                      -- run-at = now + delay
```

The delay is measured on the same clock the promote and reap paths read, never the caller's. A caller whose clock
runs fast cannot schedule a job into the wrong window — for a relative delay the server is the only clock that prices
it.

**The hero interactive — the run-at score.** A slider sets a job's `delay` in milliseconds against a fixed server
`now`. On every move it computes the run-at score for `enqueue_in` — `now + delay` — and contrasts it with the
absolute `enqueue_at` score. The readout names both and confirms the relative score is read off the server `TIME`,
not the caller's.

> The score of a delayed job is its run-at time. `enqueue_at` scores by the caller's absolute millisecond;
> `enqueue_in` scores by `now + delay`, where `now` is the server clock read inside the script.

## One atomic write: the row and the schedule entry

The score is half the story; the other half is that the schedule entry and the job row are written together. A
half-written scheduled job — a row with no schedule entry, or a schedule entry pointing at no row — is a job that
either never runs or runs against nothing. EchoMQ's `@schedule` script writes both in one `EVAL`:

```
-- @schedule (jobs.ex) — admit a scheduled job atomically (real)
if string.sub(ARGV[1], 1, 3) ~= 'JOB' then          -- the id must be JOB-namespaced
  return redis.error_reply('EMQKIND job id must be JOB-namespaced')
end
if redis.call('EXISTS', KEYS[1]) == 1 then return 0 end   -- idempotent: a duplicate no-ops
redis.call('HSET', KEYS[1], 'state', 'scheduled', 'attempts', '0', 'payload', ARGV[2])
redis.call('ZADD', KEYS[2], score, ARGV[1])          -- park the JOB id on the schedule set
return 1
```

`KEYS[1]` is the job row, `KEYS[2]` the schedule set — both declared, both braced `emq:{<queue>}:` keys that pin one
cluster slot. The kind guard refuses any id that is not `JOB`-namespaced, and the existence guard makes a repeated
schedule a no-op rather than a second copy. The row carries `state = scheduled`; the id sits on the schedule set at
its run-at score. Nothing is observable half-written.

**The main interactive — schedule, then promote.** A control admits two jobs with run-at scores, shows them parked on
the `schedule` set in score order, then steps the clock so the due one is promoted onto the `pending` set. The readout
names each job's state — `scheduled` while it waits, `pending` once promoted — and the score that ordered it.

> The schedule entry and the row are one atomic write: `HSET … state scheduled` then `ZADD schedule <run-at> <JOB id>`
> in one script, so a scheduled job is never observable half-written.

## The sort key once promoted: the mint-ordered id

There is a second ordering the score never carries. When a due job is promoted it moves onto the `pending` set, and
that set is scored `0` for every member — its members are the branded `JOB` ids themselves, so byte order is mint
order. The schedule set orders by *when* a job runs; the pending set orders by *when the job was minted*. A branded
`JOB` id is a 14-character name whose text sorts as its mint instant (a snowflake under the `JOB` namespace), so a
job minted earlier but scheduled later sorts, once promoted, by its mint — the queue carries no second index for it.

```
-- @promote (jobs.ex) — a due job lands on the pending set at score 0 (real)
redis.call('ZADD', KEYS[2], 0, id)                  -- pending: same score, members are JOB ids
redis.call('HSET', jk, 'state', 'pending')
```

So two orderings cooperate: the schedule set decides *which* jobs are released, by run-at score; the pending set
decides the order they are then served, by the id's mint order. The score prices the wait; the id prices the queue.

## In EchoMQ — the schedule score, in real code

The whole score is real code in `echo/apps/echo_mq/lib/echo_mq/jobs.ex`. The schedule set is
`EchoMQ.Keyspace.queue_key(queue, "schedule")` → `emq:{<queue>}:schedule`. `enqueue_at/5` parks the id at the
caller's absolute millisecond; `enqueue_in/5` computes `now + delay` from the server `TIME` inside the `@schedule`
script. Both write the row `state = scheduled` and `ZADD` the id onto the schedule set in one atomic `EVAL`. The id
itself, mint-ordered under the `JOB` namespace, becomes the sort key the moment promotion moves it onto the
score-`0` pending set.

> **The pattern:** a delayed job is scored by its fire-time, so the sorted set orders its members by when they are
> due.
>
> **→ In EchoMQ:** `enqueue_at/5` scores the schedule set by the caller's run-at millisecond, `enqueue_in/5` by
> `now + delay` on the server clock; both write `state = scheduled` and `ZADD emq:{<queue>}:schedule` in one atomic
> script, and the promoted job inherits the mint order of its branded `JOB` id on the pending set.

The take: the score prices the wait — the run-at millisecond, read off the server clock for a relative delay — and the
branded id prices the queue, so a delayed job is ordered first by when it runs and then by when it was minted.

## References

### Sources

- [Valkey — *ZADD*](https://valkey.io/commands/zadd/) — add a member with its score; the single write that parks a
  scheduled job on the schedule set by its run-at millisecond.
- [Redis — *Sorted sets*](https://redis.io/docs/latest/develop/data-types/sorted-sets/) — the data type behind the
  schedule set: members ordered by a numeric score.
- [Valkey — *TIME*](https://valkey.io/commands/time/) — the server clock `enqueue_in` reads inside the script, so a
  relative delay is priced by the server, not the caller.
- [Redis — *ZRANGEBYSCORE*](https://redis.io/commands/zrangebyscore/) — the range query the same score is later read
  by, the next dive's sweep.

### Related in this course

- [R4.01 · The delayed queue](/redis-patterns/time-delay-priority/delayed-queue) — the module hub.
- [R4.01.2 · ZRANGEBYSCORE promotion](/redis-patterns/time-delay-priority/delayed-queue/zrangebyscore-promotion) — the
  next dive: reading the due head this score creates.
- [R4.01.3 · The next wake](/redis-patterns/time-delay-priority/delayed-queue/the-next-wake) — the metronome beat that
  drives promotion on demand.
- [R4 · The sorted set as a clock](/redis-patterns/time-delay-priority/the-sorted-set-as-a-clock) — the orientation
  dive: the score is the semantics, fire-time first.
- [R4 · Time, Delay & Priority](/redis-patterns/time-delay-priority) — the chapter.
- [/echomq · Queue](/echomq/queue) — the dedicated EchoMQ course: the schedule set and promote pump in depth.
