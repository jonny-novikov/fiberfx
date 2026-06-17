# E2.01.2 · Every transition & its script

> Route: `/echomq/core/lifecycle/every-transition-and-its-script` · Movement I · The Core (as-built, present tense) · dive 2
> Back-link: ← redis-patterns R3 (`/redis-patterns/queues`)

## The fact

Every move between states is **one atomic Lua script**, and the number in the script's filename is its `KEYS` arity —
the count of Redis keys it touches in a single server-side step. Four scripts perform the moves the running library
makes:

| Transition | Script | KEYS | What it does atomically |
|---|---|---|---|
| pickup | `moveToActive-11` | 11 | promote due `delayed → wait`, check the rate limiter + global concurrency, dequeue (`RPOP` wait or `ZPOPMIN` prioritized), **acquire the lock** (`SET …:lock <uuid> PX`), `LPUSH active`, `XADD` the `active` event, return the job's hash fields |
| completion | `moveToFinished-14` | 14 | **verify the lock token first**, `LREM active`, `HSET returnvalue` or `failedReason`+`stacktrace`, `ZADD completed`/`failed` (score = timestamp), `DEL` the lock, increment metrics, apply `removeOnComplete`/`removeOnFail`, update a parent's deps, clean the dedup key, `XTRIM` events, optionally return the next job |
| retry | `moveToDelayed-8` | 8 | `DEL` the lock, compute the backoff `delay = base * 2^(attempt-1)` (optional jitter), move `active → delayed` with the new run-at score, increment `atm` (attempts made), `XADD` the `delayed` event |
| stalled recovery | `moveStalledJobsToWait-8` | 8 | for each job in `active`, check whether the lock exists; **no lock ⇒ stalled**; if `stc >= maxStalledCount` move to `failed`, else move back to `wait` and increment `stc` |

The Elixir executor reaches three of these as `EchoMQ.Scripts.move_to_active/4`, `move_to_finished/7`, and
`move_to_delayed/6`; the stalled sweep is driven by the supporting stalled-checker process. `moveToFinished-14` is the
most complex script in the protocol — roughly 1100 lines with the BullMQ includes resolved.

## The worked example — the atomic step list, and the return codes

Pick a transition and read its atomic step list (the bullets above are the real steps, in order). The point is
**atomicity**: every step of a transition runs in one server-side execution, so a worker never observes a job that is
half-moved — never in `active` without a lock, never in two state sets at once.

When a script cannot complete, it returns a negative integer from a **closed set of eleven**, named and never expanded:

```
-1  JobNotExist                 -7   ParentJobCannotBeReplaced
-2  JobLockNotExist             -8   JobBelongsToJobScheduler
-3  JobNotInState               -9   JobHasFailedChildren
-4  JobPendingChildren          -10  SchedulerJobIdCollision
-5  ParentJobNotExist           -11  SchedulerJobSlotsBusy
-6  JobLockMismatch
```

Two of these are the lock codes `moveToFinished-14` emits on its verify step: `-2` (`JobLockNotExist`, the lock is
missing) and `-6` (`JobLockMismatch`, the token does not match the holder). The set is fixed at eleven — the same
codes mean the same thing in every runtime.

## The protocol ↔ runtime pairing (the Golden Rule)

A transition's script and its closed return codes are **L2 — immutable and shared**. `moveToActive-11` is eleven keys
in a fixed order, performing the same atomic steps, in every runtime; the `-1`…`-11` codes mean the same thing
everywhere.

- **The protocol (immutable L2)** — the transition scripts `moveToActive-11`, `moveToFinished-14`, `moveToDelayed-8`,
  `moveStalledJobsToWait-8`, and the closed `-1`…`-11` codes.
- **Its three runtimes (variable L3)** — Elixir dispatches them by SHA via `EchoMQ.Scripts` over a Redix pool; Go and
  Node.js load and run the same script files their own way. The script does not move between runtimes; the executor
  that dispatches it does.

## Recap

Every move is one atomic Lua script whose filename number is its `KEYS` arity: `moveToActive-11` (pickup),
`moveToFinished-14` (completion), `moveToDelayed-8` (retry), `moveStalledJobsToWait-8` (recovery). Each runs its steps
in one server-side execution, so a job is never half-moved. The `-1`…`-11` codes are the scripts' fixed return
vocabulary — `-2`/`-6` are the lock codes — named and never expanded. The scripts and the codes are L2, the same in
every runtime.

## References

### Sources

- BullMQ — *Documentation* (`https://docs.bullmq.io/`) — the transition scripts and the lifecycle moves they perform.
- Redis — *EVALSHA* (`https://redis.io/commands/evalsha/`) — the load-once, run-by-SHA dispatch every transition
  script runs under.
- Redis — *LREM* (`https://redis.io/commands/lrem/`) — the remove-from-active step in `moveToFinished`.
- Redis — *ZADD* (`https://redis.io/commands/zadd/`) — the add-to-terminal-set step (completed/failed, scored by
  timestamp).

### Related in this course

- `/echomq/core/lifecycle` — E2.01 · The lifecycle & state machine (the module hub).
- `/echomq/core/lifecycle/the-eight-states` — E2.01.1 · The eight states (the locations these scripts move between).
- `/echomq/protocol/lua-scripts` — E1.03 · The Lua script layer (how a script is loaded and dispatched by SHA).
- `/redis-patterns/queues` — redis-patterns R3 · Reliable queues (the atomic-move pattern, applied).
