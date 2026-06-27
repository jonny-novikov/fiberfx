# States as locations

> Route: `/redis-patterns/queues/atomic-state-machine/states-as-locations` · Dive R3.04.1.
> Grounding: `EchoMQ.Keyspace.queue_key/2` and `job_key/2` (`echo/apps/echo_mq/lib/echo_mq/keyspace.ex`) — the
> braced `emq:{q}:` keyspace; `EchoMQ.Jobs` writes the row's `state` field as it moves the id between sorted
> sets. Consumer: codemojex (`Codemojex.Guesses` mints the `JOB`). Engine: Valkey.

A job's state is not a status field — it is the `emq:{q}:` key its id lives in. Moving between states moves
the id from one structure to another, and updates the row's `state` field to match.

## A place, not a flag

A naive queue stores the lifecycle as a column: `state = "pending"`, then `state = "active"`. The job sits in
one row and a flag says where it is. Two facts can then disagree — where the job actually sits, and what its
flag claims — and a crash between writing the flag and moving the job leaves the pair out of sync with nothing
to reconcile them.

EchoMQ stores the lifecycle as **membership**. Each state is its own `emq:{q}:` sorted set, and a job's id is a
member of exactly one of them. The job's row — a hash at `emq:{q}:job:<id>` — still carries a `state` field,
but the field follows the membership; the membership is the truth. Asking "what is pending" is a read of one
sorted set, in mint order, with no second index.

## The four locations and the row

The keys are built by `EchoMQ.Keyspace.queue_key(queue, type)`, which returns `emq:{queue}:<type>`, and the
row key by `job_key(queue, branded)`, which returns `emq:{queue}:job:<branded>` after gating the branded id:

- **`emq:{q}:pending`** — a sorted set, every member scored `0`, so byte order is mint order (the branded id
  sorts by creation). The waiting line; `claim/3` pops the lowest with `ZPOPMIN`.
- **`emq:{q}:active`** — a sorted set scored by the **lease deadline** on the server clock. A claimed job sits
  here until it is completed or its lease expires.
- **`emq:{q}:schedule`** — a sorted set scored by **run-at**. A delayed or a retried job parks here; the
  promote pump returns it to `pending` once its server-clock score is due.
- **`emq:{q}:dead`** — a sorted set, the morgue. A job past its `max` attempts lands here.
- **`emq:{q}:job:<id>`** — a hash, the job's row: `state`, `attempts`, `payload`. The `state` field tracks the
  set the id currently lives in.

## A transition moves the id

A transition is a move between these structures, plus a write to the row's `state`. `enqueue/4` adds the id to
`pending` and writes the row `state = pending`. `claim/3` pops the id from `pending`, `HINCRBY`s the row's
`attempts`, and adds it to `active` (`state = active`). `complete/5` removes it from `active` and retires the
row. `retry/7` moves it `active → schedule` below `max` (`state = scheduled`) or `active → dead` at `max`
(`state = dead`). The id is in exactly one set at every instant, because each move is one atomic script: a move
that removed the id from one set and added it to another in two separate commands would have a window where the
id is in neither, or both.

## The branded JOB id is the member

The member that moves is the branded `JOB` id — a 14-character name, a 3-character namespace plus 11 Base62
over a snowflake (epoch `1704067200000`). Because the score in `pending` is constant, the id's own byte order
is the queue order, so a job minted earlier sorts ahead with no second index. The id is gated before any key is
built: `EchoMQ.Keyspace.job_key/2` raises on an ill-formed id, so a malformed member can never reach a key.

In codemojex, `Codemojex.Guesses.submit/3` mints the member — `EchoData.BrandedId.generate!("JOB")` — and
enqueues it on the `cm` queue's player lane; `Codemojex.ScoreWorker` claims it, moving the id `pending →
active` for the duration of the scoring, then completing it.

## The pattern, applied

The pattern: model the lifecycle as membership, so a transition is a move between structures and "what is in
state X" is a read of one structure. The EchoMQ application: each state is an `emq:{q}:` sorted set, the row's
`state` follows the membership, and the branded `JOB` id is the member that moves — gated at the key builder,
mint-ordered in `pending`.

A door, not a depth: the full keyspace grammar and the rest of the sets are the dedicated EchoMQ course's Queue
pillar; the manuscript builds the `emq:{q}:` keyspace in Part III (`/bcs/bus`).

## References

### Sources
- [Redis — Sorted sets](https://redis.io/docs/latest/develop/data-types/sorted-sets/) — the data type each
  lifecycle location is, scored to order its members.
- [Redis — ZADD](https://redis.io/commands/zadd/) — add a member to a state set with a score: the lease
  deadline, the run-at, or zero for mint order.
- [Valkey — ZADD](https://valkey.io/commands/zadd/) — the same move on the engine the connector is gated
  against.
- [Redis — keyspace](https://redis.io/docs/latest/develop/use/keyspace/) — keys, hash tags, and slots; the
  basis for the braced `emq:{q}:` grammar.

### Related in this course
- [R3.04 · Atomic state machine](/redis-patterns/queues/atomic-state-machine) — the module hub.
- [R3.04.2 · Read-decide-write in one EVALSHA](/redis-patterns/queues/atomic-state-machine/read-decide-write-in-one-evalsha) —
  the next dive: the move as one atomic call.
- [R3 · States as locations](/redis-patterns/queues/states-as-locations) — the standalone orientation dive.
- [R3 · Reliable Queues](/redis-patterns/queues) — the chapter.
- [EchoMQ · the Queue pillar](/echomq/queue) — the full keyspace and the leased state machine in depth.
- [The Branded Component System · the bus](/bcs/bus) — the manuscript's `emq:{q}:` keyspace.
