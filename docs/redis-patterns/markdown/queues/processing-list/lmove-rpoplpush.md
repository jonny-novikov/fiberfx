# LMOVE / RPOPLPUSH — the atomic transfer

> Route: `/redis-patterns/queues/processing-list/lmove-rpoplpush` · Dive R3.01.2 · Module R3.01 Processing list.
> · Grounding: EchoMQ's in-flight move is one command — `moveToActive-11.lua` runs
> `rcall("RPOPLPUSH", waitKey, activeKey)`, not a separate `RPOP` then `LPUSH`. `EchoMQ.Scripts.move_to_active/4`
> dispatches it. Real in `echo/apps/echomq`.

Moving a job from the waiting list to the in-flight list is one logical step, and it must be one Redis command. Done as
two — pop, then push — it has a gap in the middle where the job is in neither list, and a crash in that gap drops the
job. `RPOPLPUSH` and its modern successor `LMOVE` do the pop and the push as a single atomic command, so there is no
gap. This dive is the difference between two steps and one.

## Two steps leave a gap

The obvious way to take a job is to pop it from the waiting list and push it to the in-flight list:

```
job = RPOP  wait        # job leaves wait — it is now in neither list
# ---- if the worker dies HERE, the job is gone ----
LPUSH active job        # job lands in active
```

Between the `RPOP` and the `LPUSH`, the job exists nowhere. It has left `wait` and not yet reached `active`. A crash in
that window — a deploy, an OOM kill, a dropped connection — drops the job with nothing to recover it from. The window is
small, but a busy queue runs the move millions of times, and small windows fire. Two commands cannot be made atomic by
running them quickly.

## One command closes it

`RPOPLPUSH source destination` pops from the tail of `source` and pushes to the head of `destination` as a single
atomic command. The job leaves `wait` and lands in `active` with no instant in between in which it is in neither list:

```
job = RPOPLPUSH wait active   # atomic: pop tail of wait, push head of active
process(job)                  # a crash here leaves the job parked in active
LREM active 1 job             # remove only after the work is truly done
```

`LMOVE source destination RIGHT LEFT` (Redis 6.2+) is the same move with explicit directions. `RPOPLPUSH src dst` is
exactly `LMOVE src dst RIGHT LEFT` — pop the right (tail), push the left (head). `LMOVE` generalises it to any pair of
ends and is the recommended form for new code; `RPOPLPUSH` remains for compatibility and is what older protocols, EchoMQ
included, run. Either way the guarantee is identical: the job is in exactly one list at every instant.

```
RPOPLPUSH src dst            ==  LMOVE src dst RIGHT LEFT
LMOVE  src dst LEFT  RIGHT   →  pop the head of src, push the tail of dst
```

## The blocking variant — block, do not poll

A worker with nothing to do can poll: run `RPOPLPUSH` in a loop, get nil on an empty queue, sleep, try again. Polling
wastes round trips when the queue is idle and adds latency between a job arriving and a worker taking it. The blocking
variants remove the loop. `BLMOVE source destination RIGHT LEFT timeout` (and the older `BRPOPLPUSH source destination
timeout`) do the same atomic move, but on an empty source they block the connection for up to `timeout` seconds, waking
the instant a job is pushed:

```
BRPOPLPUSH wait active 30     # block up to 30s; wake the moment a job arrives
BLMOVE     wait active RIGHT LEFT 30   # the modern form, same blocking move
```

A timeout of 0 blocks indefinitely. The block is server-side: no round trips while waiting, and the worker takes the job
with no polling delay. The move is still atomic — blocking changes only when the command returns, not what it does.

## The pattern, applied

EchoMQ's in-flight move is one command, not two. `EchoMQ.Scripts.move_to_active/4` dispatches `moveToActive-11.lua`,
whose move is `rcall("RPOPLPUSH", waitKey, activeKey)` — the `RPOPLPUSH` form, inside a larger Lua script that also sets
the lock and writes an event, the whole thing atomic. The job leaves `emq:{queue}:wait` and lands in
`emq:{queue}:active` with no gap, real in `echo/apps/echomq`.

```lua
-- moveToActive-11.lua — the move is RPOPLPUSH, not RPOP + LPUSH (real)
local waitKey = KEYS[1]      -- emq:{queue}:wait
local activeKey = KEYS[2]    -- emq:{queue}:active
local jobId = rcall("RPOPLPUSH", waitKey, activeKey)  -- one command, atomic
```

EchoMQ runs the move inside a Lua script rather than as a bare `BLMOVE`, because the move also has to set the job's lock
and write to the event stream — work that has to be atomic with the pop-and-push, so it goes in one script. The bare
`RPOPLPUSH` and `BLMOVE` are the same closing-the-gap move at the command level; the script is that move plus the lock
and the event, all-or-nothing.

## References

### Sources
- [Redis — RPOPLPUSH](https://redis.io/commands/rpoplpush/) — the original atomic move, pop tail of source, push head
  of destination, in one command.
- [Redis — LMOVE](https://redis.io/commands/lmove/) — the modern successor (Redis 6.2+), explicit `RIGHT`/`LEFT`,
  recommended for new code.
- [Redis — BLMOVE](https://redis.io/commands/blmove/) — the blocking variant: the same move, block instead of poll.
- [Salvatore Sanfilippo — RPOPLPUSH, the reliable queue pattern](https://antirez.com/news/77) — the Redis creator's
  design note on the atomic move.

### Related in this course
- [R3.01 · Processing list](/redis-patterns/queues/processing-list) — the module hub: the in-flight move.
- [R3.01.1 · List as wait + active](/redis-patterns/queues/processing-list/list-wait-active) — the two named lists the
  command moves a job between.
- [R3.01.3 · The in-flight list](/redis-patterns/queues/processing-list/the-in-flight-list) — what the atomic move
  enables: a recoverable parked job.
- [R2.01 · Atomic updates](/redis-patterns/coordination/atomic-updates) — the broader atomic read-modify-write family
  this move belongs to.
- [E2 · the engine](/echomq/core) — the dedicated EchoMQ course: the worker fetch loop in depth.
