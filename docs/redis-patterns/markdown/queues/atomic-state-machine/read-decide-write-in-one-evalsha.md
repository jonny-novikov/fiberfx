# Read-decide-write in one EVALSHA

> Route: `/redis-patterns/queues/atomic-state-machine/read-decide-write-in-one-evalsha` · Dive R3.04.2.
> Grounding: the inline `@complete` / `@retry` / `@claim` scripts in `EchoMQ.Jobs`
> (`echo/apps/echo_mq/lib/echo_mq/jobs.ex`), each declared with `EchoMQ.Script.new/2` and dispatched by
> `EchoMQ.Connector.eval/5` as one `EVALSHA`. The row's `attempts` — `HINCRBY`'d at `claim/3` — is the
> fencing token that makes the script idempotent. Engine: Valkey.

The completion is a read-modify-write: read the fencing token, decide where the job goes, write the move.
Split into round trips, a second process slips between the read and the write. Run as one `EVALSHA`, it is
indivisible.

## The transition is a read-modify-write

Completing a job is not one write. It is a read, a decision, and several writes:

- **Read** — the row's `attempts` token. A worker whose lease was reaped and re-claimed by another holds a
  stale token, and must not complete a job the new holder now owns.
- **Decide** — does the token still match? On a retry, is the attempt past `max` — schedule again, or
  dead-letter?
- **Write** — remove the id from `active`, record the result or the error on the row, move the row's `state`,
  and bump the metric.

That is a read-modify-write across more than one key. Done as separate commands, the gaps between them are
open. A lease-expiry sweep reads the same job still in `active` past its deadline and returns it to `pending`
for redelivery — between the completing worker's read and its write. The job is retired by one process and
re-queued by the other, or its lease is released by one while the other still treats it as held. At-least-once
becomes a mess by accident.

## One EVALSHA closes every gap

A Lua script runs to completion before Valkey serves the next command. So folding the whole read-decide-write
into one script and dispatching it with a single `EVALSHA` removes every gap. The read, the decision, and the
writes are one indivisible step; no sweep and no second completion can interleave.

In EchoMQ each transition is one inline script, declared with `EchoMQ.Script.new(name, lua)` and dispatched by
`EchoMQ.Connector.eval/5`. The `@complete` body is the read-decide-write in one call: read the token, refuse a
mismatch, release the lease, retire the row, bump the metric.

```
-- @complete (jobs.ex), trimmed — read the token, decide, write, all in one EVALSHA
local att = redis.call('HGET', KEYS[2], 'attempts')   -- read the fencing token
if not att then return 0 end                          -- the row is gone
if att ~= ARGV[2] then                                -- decide: a stale holder is refused
  return redis.error_reply('EMQSTALE complete token mismatch')
end
local was_active = redis.call('ZREM', KEYS[1], ARGV[1])  -- write: release the lease
redis.call('DEL', KEYS[2])                               -- retire the row
redis.call('HINCRBY', p .. 'metrics:completed', 'count', 1)
```

Every key the script touches is declared in `KEYS` (the v2 law) — `KEYS[1]` the `active` set, `KEYS[2]` the
row — both braced `emq:{q}:` keys built host-side by `EchoMQ.Keyspace`, so they share one slot. `ARGV` carries
values only.

## The fencing token

The decision that makes the transition safe under redelivery is the token check. `claim/3` mints the token by
`HINCRBY`-ing the row's `attempts` when it leases the job; the worker carries that value, and every later
transition passes it as `ARGV[2]`. A worker whose lease was reaped and re-claimed holds the old value, so its
`@complete` or `@retry` reads a mismatched token and is refused with `EMQSTALE token mismatch` — it changes
nothing. The completing worker and the reaper cannot both move the same job, because the script reads the token
inside the same atomic step that does the writes.

`@retry` carries the same fence and adds the branch: below `max` it sets `state = scheduled` and `ZADD`s the
row into `schedule` on the server clock; at `max` it sets `state = dead` and `ZADD`s the row into `dead`,
bumping `metrics:failed`. One read, one decision, the writes — one `EVALSHA`.

## The pattern, applied

The atomic-updates pattern says a multi-key read-modify-write must be one server-side script. In EchoMQ each
lifecycle transition is one inline `EchoMQ.Script.new/2`, dispatched by `EchoMQ.Connector.eval/5` as a single
`EVALSHA`; the row's `attempts` fencing token, minted by `claim/3`, makes the script idempotent so a stale
holder cannot move the job.

A door, not a depth: the full script bundle and the worker fetch loop that runs the leased state machine are
the dedicated EchoMQ course's Queue pillar. A dead-lettered job reaches the durability floor at
`/echo-persistence`.

## References

### Sources
- [Redis — EVALSHA](https://redis.io/commands/evalsha/) — the cached-script call that runs the read-decide-write
  as one step.
- [Redis — EVAL / scripting](https://redis.io/commands/eval/) — why a Lua script is one atomic step, so no
  second process interleaves the read-decide-write.
- [Redis — Scripting with Lua](https://redis.io/docs/latest/develop/interact/programmability/eval-intro/) — the
  model for a script running to completion in the single command thread.
- [Valkey — EVAL](https://valkey.io/commands/eval/) — the scripting surface on the engine the connector is
  gated against.

### Related in this course
- [R3.04 · Atomic state machine](/redis-patterns/queues/atomic-state-machine) — the module hub.
- [R3.04.1 · States as locations](/redis-patterns/queues/atomic-state-machine/states-as-locations) — the prior
  dive: the locations the move travels between.
- [R3.04.3 · EVALSHA and NOSCRIPT](/redis-patterns/queues/atomic-state-machine/evalsha-and-noscript) — the
  next dive: how the cached script reaches the server.
- [R3.03 · Stalled recovery](/redis-patterns/queues/stalled-recovery) — the reaper that must not interleave
  this completion.
- [R2.01 · Atomic updates](/redis-patterns/coordination/atomic-updates) — the one-script read-modify-write
  pattern this applies.
- [EchoMQ · the Queue pillar](/echomq/queue) — the dedicated EchoMQ course: the leased state machine in depth.
