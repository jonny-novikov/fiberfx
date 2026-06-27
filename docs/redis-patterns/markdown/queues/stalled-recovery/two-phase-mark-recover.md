# Two-phase mark/recover — count the stalls, bound the recovery

> **Route:** `/redis-patterns/queues/stalled-recovery/two-phase-mark-recover` · **Dive:** R3.03.2
> **Grounding:** `echo/apps/echo_mq/lib/echo_mq/stalled.ex` — `EchoMQ.Stalled.check/3` (`@sweep_stalled`), the per-job `stalled` field (`HINCRBY`), `:max_stalled` the dead-letter threshold, the `emq:{q}:dead` morgue.

Detection finds a job whose lease lapsed. Recovery has a harder decision: should this job go back in line, or has it stalled so many times that returning it again only re-poisons the queue? A job that crashes its worker every time it is claimed would, under a plain reaper, be recovered forever. The mark/recover layer counts the stalls and bounds them.

## The reaper recovers; the sweep counts

`EchoMQ.Jobs.reap/2` is the unconditional layer — it returns any expired-lease job to `pending` once, no count, the at-least-once floor. `EchoMQ.Stalled.check/3` is the count-thresholded layer that rides on top. Each pass it examines the same expired prefix, but for each job it increments a per-job `stalled` field on the row (`HINCRBY ... 'stalled' 1`) and branches on the result against `max_stalled` (default `1`):

    local st = redis.call('HINCRBY', jk, 'stalled', 1)   -- this job's stall count, this pass
    if st >= maxst then
      redis.call('HSET', jk, 'state', 'dead')
      redis.call('HSET', jk, 'last_error', 'stalled')
      redis.call('ZADD', KEYS[3], 0, id)                 -- emq:{q}:dead
      redis.call('HINCRBY', p .. 'metrics:failed', 'count', 1)
      -- dead-lettered: not recovered
    else
      redis.call('ZADD', KEYS[2], 0, id)                 -- emq:{q}:pending
      redis.call('HSET', jk, 'state', 'pending')
      -- recovered: back in line
    end

The `stalled` field is the mark. It is not a separate set or a separate key — it is a field on the job's three-field row, so marking a job costs nothing the row did not already hold. A job's stall history travels with the job, and a recovered job carries its count into the next claim.

## Recover below the threshold, dead-letter at it

The branch is the two phases in one decision:

- **Below `max_stalled` — recover.** `ZADD emq:{q}:pending`, `HSET state pending`. The job goes back to be claimed again. A grouped job (a fair lane) recovers into its lane, `emq:{q}:g:<group>:pending`, mirroring the reaper's group branch, so lane fairness is preserved across a recovery.
- **At or above `max_stalled` — dead-letter.** `HSET state dead`, `ZADD emq:{q}:dead`, and the `metrics:failed` counter ticks. The job stops cycling; it is now a record in the morgue rather than a member of the working set.

`max_stalled` is the budget. Set to `1`, a job is recovered once and dead-lettered on its second stall — the strict default. Raise it for a workload where a transient stall (a slow downstream, a brief pause) is expected and a job deserves several recoveries before it is given up. The threshold separates *the worker died* (recover, it was not the job's fault) from *this job kills workers* (dead-letter, the job is poison).

## Idempotent across a restart

The sweep is idempotent over the active set. If the sweep process crashes and its `:transient` child restarts, the next pass re-reads `ZRANGEBYSCORE active -inf now` and re-applies the branch — a job already recovered has left `active`, so it is not examined again; a job not yet recovered is recovered on the re-sweep. No double-recovery, no loss across a restart, because the move reads the live set, not a journal of what the last pass intended to do.

## The bridge

- **detect** — a job's lease lapsed, the reaper finds it on `active`.
- **then bound the recovery** — `EchoMQ.Stalled` increments the job's `stalled` field, recovers it below `max_stalled` into `pending` (or its lane), and dead-letters it at or above the threshold into `emq:{q}:dead`.

The take: a plain reaper recovers a poison job forever; the stall count turns "recover" into "recover a bounded number of times, then retire."

## Where a dead-lettered job lands

A job in `emq:{q}:dead` is a durable record of a failure, not a working-set member. When the bus trims the stream that carries the queue's history, `EchoStore.StreamArchive` folds the trimmed segments into the durable Graft floor on CubDB at a reserved high page range and on to Tigris — deep history without resident memory, queryable beside the live tail. The morgue is the dial's first detent — held in Valkey — and the archive is the next: the floor `/echo-persistence` builds.

## References

### Sources

- [Valkey — *HINCRBY*](https://valkey.io/commands/hincrby/) — the in-script increment of the per-job `stalled` count; the field travels with the row.
- [Valkey — *Sorted Sets*](https://valkey.io/topics/sorted-sets/) — `pending`, `active`, and `dead` are scored sets the sweep moves a job between.
- [Redis — *EVALSHA*](https://redis.io/commands/evalsha/) — the whole mark-and-branch runs as one cached script per sweep.
- [Oban — *Robust job processing in Elixir*](https://hexdocs.pm/oban/Oban.html) — the Postgres-backed prior art for retries, attempts, and a dead-letter outcome.

### Related in this course

- [R3.03 · Stalled recovery](/redis-patterns/queues/stalled-recovery) — the module hub.
- [R3.03.1 · Lock-expiry detection](/redis-patterns/queues/stalled-recovery/lock-expiry-detection) — how a stalled job is found.
- [R3.03.3 · Atomic vs non-atomic](/redis-patterns/queues/stalled-recovery/atomic-vs-non-atomic) — why the mark-and-move is one step.
- [R3.02 · At-least-once](/redis-patterns/queues/at-least-once) — the attempts counter the recovery rides beside.
- [/echo-persistence](/echo-persistence) — the durability floor a dead-lettered job's history folds into.
