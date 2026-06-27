# Score as meaning

> **Route:** `/redis-patterns/time-delay-priority/score-as-meaning` · R4 · orientation dive

The sorted set is one mechanism; the score is the whole semantic axis. Score a job by a future millisecond and the
set is a delayed queue; flatten the score to a constant and let the member's mint order serve as the queue; score
it by a next-run time and the set is a scheduler registry. Same member, same commands — three meanings, all carried
by one number.

A sorted set stores members ordered by a numeric score. The textbook delayed queue uses the simplest possible
score: a timestamp. The member is the task id; the score is when it should run; `ZRANGEBYSCORE` reads back
everything due. That one idea — the score is a number that sorts the set — is the whole pattern. This dive shows how
EchoMQ reads one number three ways across three real sets.

## The score is a number that sorts

The delayed-queue pattern schedules tasks with a sorted set whose score is a run-at millisecond:

```
ZADD schedule 1706649000000 "JOB0Nb1VTbfnu4"
ZRANGEBYSCORE schedule -inf 1706648500000 LIMIT 0 10
ZREM schedule "JOB0Nb1VTbfnu4"
```

The member is the job id, the score is the fire-time, and the set stays ordered by fire-time with no extra
bookkeeping. A pump reads the due head with `ZRANGEBYSCORE`, removes each member with `ZREM`, and promotes it.
Nothing in Valkey is told what the score "means" — it is a number, and the set sorts by it. The meaning lives in how
the writer chooses the number and how the reader interprets the order.

That freedom is the lever. Because the score is an arbitrary number, the *member* can carry meaning too. EchoMQ uses
this on its `pending` set: it flattens every score to `0` and lets the branded job id — which sorts as its mint
instant — carry the order.

### The hero interactive — the score decoder

A control reads one fixed example job three ways. Each reading computes the actual stored score and names the write
and read commands: **fire-time** (`score = run_at_ms`), **order** (`score = 0`, the mint-ordered id is the sort
key), and **next-run** (`score = next_run_ms`, upserted). The readout shows the score and where the job sorts.

## One number, three real sets

EchoMQ never packs two facts into one score. It keeps each reading on its own set and lets each set carry exactly
one number per member.

**Fire-time — `emq:{q}:schedule`.** `EchoMQ.Jobs.enqueue_at/6` writes the caller's absolute run-at millisecond as
the score; `enqueue_in/6` computes `now + delay_ms` from the server clock inside the `@schedule` Lua
(`local t = redis.call('TIME')`). The score *is* the millisecond — no left-shift, no lossy recovery. The job's row
is written `state = scheduled` and parked on the set; the score is a visibility fence, not a second queue.

**Order — `emq:{q}:pending`.** Once a scheduled job is due, `EchoMQ.Jobs.promote/3` `ZADD`s it onto the pending set
with score `0`. Every pending member shares score `0`, so the set sorts entirely by the *member* — the branded
`JOB` id, which sorts as its mint instant. The `claim` script's `ZPOPMIN` therefore serves the oldest job first.
The order is carried by the id, not by a packed counter.

**Next-run — `emq:{q}:repeat`.** `EchoMQ.Repeat.register/6` `ZADD`s a registration name scored by its next-run
millisecond, and the `@register` Lua **upserts** — it guards on `EXISTS KEYS[2]` (the per-name record hash) and
returns `0` without re-adding when the name is already live, so a reboot that re-registers the same recurring job
adds no duplicate. The pump reads the due names with `ZRANGEBYSCORE repeat -inf now` and `EchoMQ.Repeat.advance/4`
re-scores each to `now + every_ms`.

### The main interactive — the three-readings panel

One fixed example job, read three ways. Each reading computes the actual stored score and names the write command
and the read command:

- **fire-time** → `score = run_at_ms`; write `ZADD emq:{q}:schedule score id`; read
  `ZRANGEBYSCORE emq:{q}:schedule -inf now`.
- **order** → `score = 0`; write `ZADD emq:{q}:pending 0 id`; read `ZPOPMIN emq:{q}:pending`.
- **next-run** → `score = next_run_ms`; write `ZADD emq:{q}:repeat next_run_ms name` (upsert); read
  `ZRANGEBYSCORE emq:{q}:repeat -inf now`.

The same job is stored three different ways because the score carries three different meanings.

## The bridge — the writer encodes the meaning

The textbook reaches the same "next job to serve" order by *packing* two fields into one score — a priority tier in
the high 32 bits, an arrival counter in the low 32 bits (`score = priority × 2³² + arrival`), read by `ZPOPMIN`.
That is a valid encoding, and it is the contrast worth knowing: it puts the order *in the score*. EchoMQ chose the
opposite — it puts the order *in the member*. A score-0 pending set ordered by a mint-ordered branded id needs no
arrival counter to break ties, because the id already is one.

| reading | set | score | meaning |
| --- | --- | --- | --- |
| fire-time | `emq:{q}:schedule` | run-at ms | *when* a job runs |
| order | `emq:{q}:pending` | `0` (id carries order) | *in what order* |
| next-run | `emq:{q}:repeat` | next-run ms (upsert) | *how often* |

> **The pattern:** the sorted set does not store time, priority, or schedule — it stores one number per member and
> keeps the set ordered by it.
>
> **→ In EchoMQ:** three real sets — `emq:{q}:schedule` scored by run-at ms, `emq:{q}:pending` scored `0` and
> ordered by the mint-ordered `JOB` id, `emq:{q}:repeat` scored by next-run ms and upserted — each carrying exactly
> one number per member.

**Take:** the number is the meaning, and the writer encodes it. EchoMQ's choice is to keep each number simple and
let the branded id do the ordering work a packed counter would otherwise carry.

## References

### Sources

- [Valkey — *Sorted sets*](https://valkey.io/topics/) — the data type: members ordered by a numeric score, the
  substrate every reading shares.
- [Redis — *ZADD*](https://redis.io/commands/zadd/) — add or update a member's score; the one write command behind
  all three readings (and the `emq:{q}:repeat` upsert).
- [Redis — *ZRANGEBYSCORE*](https://redis.io/commands/zrangebyscore/) — read members by score range; the due-head
  read the promote and repeat sweeps both use.
- [Redis — *ZPOPMIN*](https://redis.io/commands/zpopmin/) — pop the lowest-scored member; the read that serves the
  oldest job from the score-0 pending set.

### Related in this course

- [R4 · Time, Delay & Priority](/redis-patterns/time-delay-priority) — the chapter: the sorted-set-as-clock family
  in one place.
- [R4 · The sorted set as a clock](/redis-patterns/time-delay-priority/the-sorted-set-as-a-clock) — the prior dive:
  one set, two readings (timer wheel and mint-ordered queue).
- [R4 · The road ahead](/redis-patterns/time-delay-priority/the-road-ahead) — the arc R4.01→R4.06 and the door to
  the EchoMQ Queue.
- [The Queue — EchoMQ, In Depth](/echomq/queue) — the EchoMQ state machine, the schedule set, and the promote pump,
  in depth.
