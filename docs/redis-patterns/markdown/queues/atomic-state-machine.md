# The atomic state machine — one EVALSHA per transition

> Route: `/redis-patterns/queues/atomic-state-machine` · Module R3.04 · Chapter R3 Reliable Queues.
> · Pattern: `atomic-updates` (the lifecycle treatment). Grounding: the real Elixir `EchoMQ.Jobs`
> (`echo/apps/echo_mq/lib/echo_mq/jobs.ex`) — the leased state machine: `enqueue/4` → `claim/3` →
> `complete/5` / `retry/7`. Each transition is one inline `EchoMQ.Script.new/2` script the connector runs
> EVALSHA-first (`EchoMQ.Connector.eval/5`, `echo/apps/echo_wire/lib/echo_mq/connector.ex`), falling back to
> `SCRIPT LOAD` + `EVALSHA` on a `NOSCRIPT` reply. The states are `emq:{q}:` keyspace locations
> (`EchoMQ.Keyspace.queue_key/2`); the branded `JOB` id is gated at the key builder. Consumer: codemojex
> (`Codemojex.Guesses` mints the `JOB`, `Codemojex.ScoreWorker` drains it). Engine: Valkey.

Ensure data integrity with atomic read-modify-write operations: a job's transition between states is a
read-modify-write, and it runs as one server-side Lua script so concurrent clients cannot interleave.

A queue's job has a lifecycle — pending, active, scheduled, dead. Each transition reads where the job sits,
decides where it goes next, and writes the move. Done as a sequence of separate commands, a lease-expiry sweep
or a second worker slips between the read and the write, and the job is handled twice or left in two places at
once. Done as one `EVALSHA`, the whole read-decide-write runs inside Valkey's single command thread,
indivisible. This module is that discipline applied to the queue: the job's states are `emq:{q}:` locations,
each transition is one inline `EchoMQ.Script.new/2`, and the script is the lock.

## The problem: interleaved read-modify-write

The atomic-updates pattern starts from a race. A read-modify-write — read a value, compute a new one, write it
back — is three steps, and any other client can act in the gaps. The source's worked example is a balance:
read `account:123:balance`, subtract `100`, write the result. Two clients that both read the old balance
before either writes both compute from the same number, and one update is lost.

Applied to the queue, the value being updated is not a balance but a **job's location**. A worker completing a
job reads the job's fencing token, checks it still holds the lease, and writes the move out of `active`. A
lease-expiry sweep, running at the same instant, reads the same job still in `active` past its deadline and
returns it to `pending` for redelivery. Run as separate commands, the two interleave: the job is retired by
one process and re-queued by the other, or its lease is released by one while the other still treats it as
held. The concurrent writers are the **completing worker** and the **reaper** (`EchoMQ.Stalled`, on the
server clock), and the value they race on is the job's place in the queue.

## The solution: one Lua script, one EVALSHA

A Lua script executes atomically — no other command runs between the script's first line and its last. So the
fix is to fold the whole read-decide-write into one script and run it with a single call. The read (read the
row's `attempts` fencing token), the decision (does the token still match? is this attempt past `max`?), and
every write (release the lease from `active`, record the result or the error, move the row's `state`, bump the
metric) happen as one indivisible step. No second client can interleave, because Valkey runs the script to
completion before it serves the next command.

In EchoMQ each transition is one inline script declared with `EchoMQ.Script.new(name, lua)` and dispatched by
`EchoMQ.Connector.eval/5`. `EchoMQ.Jobs` is the leased state machine: `enqueue/4` writes the row and the
`pending` entry under the `@enqueue` script; `claim/3` pops the oldest `pending` member, `HINCRBY`s the row's
`attempts` to mint the lease token, and scores it into `active` on the server clock under `@claim`;
`complete/5` checks the token and retires the row under `@complete`; `retry/7` checks the token and either
reschedules or moves the row to `dead` under `@retry`. Every script declares every key it touches in `KEYS`,
and the branded `JOB` id is gated before the key is built (`EchoMQ.Keyspace.job_key/2`).

## Redis commands used

- `EVALSHA sha numkeys key… arg…` — run a cached script by its SHA; cheap, because the script body is not on
  the wire. `EchoMQ.Connector.eval/5` tries this first.
- `SCRIPT LOAD script` — cache the body once and get back the SHA the client then calls by; the connector runs
  it once per script when an `EVALSHA` returns `NOSCRIPT`.
- `EVALSHA sha …` again — after the load, the same call is re-run by the SHA.

The script body itself runs the queue moves — `ZPOPMIN` over `pending`, `ZADD` into `active`/`schedule`/`dead`,
`ZREM` from `active`, `HINCRBY` on the row's `attempts`, `HSET` on the row's `state` — but the client issues
exactly one command per transition: the `EVALSHA`. That is the point. A multi-key, multi-structure transition
reaches Valkey as one indivisible call.

## When to use

Use the atomic-script transition whenever a job's move reads state, branches on it, and writes across more than
one key — and a second process can run the same move at the same time. A queue's completion is exactly that: it
reads the fencing token, branches on whether the token still matches and whether the attempt is past `max`,
and writes across the `active` set, the row hash, and the metric. A lease-expiry sweep runs concurrently by
design. The transition must be one step.

## When to avoid

A single-key, single-command update needs no script — `INCR`, `SET … GET`, `GETDEL` are already atomic on
their own. Reach for the script only when the move spans multiple keys or carries a branch. And keep the keys
on one node: a Lua script may only touch keys in the same slot, so EchoMQ braces the queue name —
`emq:{q}:pending`, `emq:{q}:active`, `emq:{q}:job:<id>` — so every key of one queue hash-tags into one slot
and a multi-key script can run at all (the R2.05 hash-tag treatment, built into the keyspace).

## The three dives

This module takes the transition in three parts, in order:

- **States as locations** — a job's state is a place in `emq:{q}:`, not a status field. `pending`, `active`,
  `schedule` and `dead` are sorted sets; the row is a hash at `emq:{q}:job:<id>`. A transition moves the id
  from one structure to another and updates the row's `state` field.
- **Read-decide-write in one EVALSHA** — the transition is a read-modify-write, and each `EchoMQ.Script.new/2`
  script runs the whole of it as one `EVALSHA` over its declared keys. The fencing token — the row's
  `attempts`, `HINCRBY`'d at claim — is what a stale holder fails on, so a reaped-and-reclaimed job cannot be
  finished twice.
- **EVALSHA and NOSCRIPT** — how the script reaches the server: `EchoMQ.Script.new/2` precomputes the SHA, the
  connector calls `EVALSHA` by it, and a flushed cache returns `NOSCRIPT` so the connector runs `SCRIPT LOAD`
  once and re-runs the `EVALSHA`.

### The pattern, applied

The atomic-updates pattern says a read-modify-write across multiple keys must be one server-side script, or
concurrent clients interleave. In EchoMQ each lifecycle transition is one inline `EchoMQ.Script.new/2`,
dispatched by `EchoMQ.Connector.eval/5` (EVALSHA-first, `SCRIPT LOAD` + re-`EVALSHA` on `NOSCRIPT`). The
fencing token — the row's `attempts`, minted by `claim/3`'s `HINCRBY` — makes the script idempotent under
redelivery: a stale token is refused (`EMQSTALE token mismatch`), so the completing worker and the reaper
cannot both move the same job.

Where a job exhausts its retries — `retry/7` moves the row to `state = dead` and into the `dead` set — it has
reached the durable frontier the persistence floor covers: the page tier (`EchoStore.Graft.*` over CubDB,
then Tigris) is where a dead-lettered completion is archived. A door, not a depth: this module cites the
leased state machine and the EVALSHA/NOSCRIPT fallback as proof the transition ships. The worker fetch loop
and the full set of scripts are the dedicated **EchoMQ course** (the Queue pillar); the durability dial is
**/echo-persistence**.

## References

### Sources
- [Redis — EVALSHA](https://redis.io/commands/evalsha/) — run a cached script by its SHA; the cheap call that
  drives every lifecycle transition.
- [Redis — EVAL / scripting](https://redis.io/commands/eval/) — why a Lua script is one atomic step in the
  single command thread, so the read-decide-write cannot interleave.
- [Redis — SCRIPT LOAD](https://redis.io/commands/script-load/) — cache the script body once and get back the
  SHA the client calls by.
- [Redis — Scripting with Lua](https://redis.io/docs/latest/develop/interact/programmability/eval-intro/) —
  the model for why a script runs to completion before any other command.
- [Valkey — EVALSHA](https://valkey.io/commands/evalsha/) — the cached-script call on the engine the connector
  is gated against; `NOSCRIPT` is the engine's own reply when the SHA is uncached.

### Related in this course
- [R3 · Reliable Queues](/redis-patterns/queues) — the chapter: the whole reliable-queue family.
- [R3.04.1 · States as locations](/redis-patterns/queues/atomic-state-machine/states-as-locations) — a job's
  state is the `emq:{q}:` key its id lives in.
- [R3.04.2 · Read-decide-write in one EVALSHA](/redis-patterns/queues/atomic-state-machine/read-decide-write-in-one-evalsha) —
  the transition as one indivisible call, token-fenced.
- [R3.04.3 · EVALSHA and NOSCRIPT](/redis-patterns/queues/atomic-state-machine/evalsha-and-noscript) — load
  once, run by SHA, fall back on a flushed cache.
- [R3 · States as locations](/redis-patterns/queues/states-as-locations) — the standalone orientation dive:
  the family framing.
- [R3.03 · Stalled recovery](/redis-patterns/queues/stalled-recovery) — the sweep that must not interleave the
  completion.
- [R2.01 · Atomic updates](/redis-patterns/coordination/atomic-updates) — the one-script read-modify-write
  pattern this module applies to the lifecycle.
- [EchoMQ · the Queue pillar](/echomq/queue) — the dedicated EchoMQ course: the worker fetch loop that runs the
  leased state machine.
- [The durability floor](/echo-persistence) — where a dead-lettered job reaches the page tier and Tigris.
