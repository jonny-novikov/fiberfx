# The Queue · Workshop — trace one job, then compose a flow

> Route: `/echomq/queue/workshop` · surface: dive (single page, no sub-dives) · pillar: The Queue.
> Grounding: **all real code** in `echo/apps/echo_mq` (`jobs.ex`, `flows.ex`, `keyspace.ex`). No `[RECONCILE]`
> markers — every transition, key, field, and verdict below is verified on disk.

## The thesis

The Queue is a state machine over **four sorted sets** and **one row hash**. This workshop closes the chapter
hands-on: take one job and walk it across the whole machine, then take a parent and N children and watch the
fan-in release the parent. Nothing here is new — it is the lifecycle and the flow, run end to end.

The four sets, per queue, are `emq:{q}:pending`, `emq:{q}:active`, `emq:{q}:schedule`, `emq:{q}:dead` — all
sorted sets whose members are the branded job ids themselves. The row is the hash at
`emq:{q}:job:<id>` (the grammar is `job:<id>`, built by `EchoMQ.Keyspace.job_key/2`, gated by
`EchoData.BrandedId.valid?/1`). The row carries `state`, `attempts`, `payload` at the floor.

## Part 1 — trace one job through its lifecycle

A job moves through the machine by one atomic script per transition. The happy path is three moves; the failure
fork adds two; recovery is one.

### The happy path — enqueue → claim → complete

1. **enqueue.** `EchoMQ.Jobs.enqueue/4` runs the `@enqueue` script: gate the id (`string.sub(ARGV[1],1,3) == 'JOB'`),
   refuse a duplicate (`EXISTS KEYS[1]`), `HSET` the three-field row (`state pending`, `attempts 0`, `payload`),
   `ZADD KEYS[2] 0 ARGV[1]` (pending at score 0). Set membership after: **pending = {id}**, row `state = pending`,
   `attempts = 0`.
2. **claim.** `EchoMQ.Jobs.claim/3` honors `paused?/2` first, then runs `@claim`: `ZPOPMIN` pending (the oldest id),
   `HINCRBY attempts 1` (→ 1 — **this is the fencing token**), `HSET state active`, then read the server clock
   (`TIME`) and `ZADD active (now + lease) id` (**the active-set score IS the lease deadline**). Returns
   `{:ok, {id, payload, att}}`. Set membership after: **active = {id}** at score `now + lease`, pending empty,
   row `state = active`, `attempts = 1`.
3. **complete.** `EchoMQ.Jobs.complete/4` runs `@complete`: read `attempts` and token-fence it
   (`att ~= ARGV[2]` → `EMQSTALE`); `ZREM active`; for a non-flow job, `DEL KEYS[2]` (the row) and
   `HINCRBY metrics:completed count 1`; `return 1`. Set membership after: **all sets empty**, the row is gone,
   `metrics:completed` incremented. The handle maps `1 → :ok`.

The fencing token is the point: only the worker holding the matching `attempts` value may complete. A stale token
(a reaped, then re-claimed, then late-completing worker) is refused `EMQSTALE` — the second claim incremented
`attempts`, so the first worker's token no longer matches.

### The failure fork — claim → retry (scheduled) → promote → claim → dead

When a handler returns `{:error, reason}`, the worker calls `EchoMQ.Jobs.retry/7`. `@retry` token-fences, `ZREM`s
active, `HSET last_error`, then branches on attempts:

- **below max** (`att < max_attempts`): `HSET state scheduled`, `ZADD schedule (now + delay) id`, `return 'scheduled'`.
  The schedule set is a **visibility fence, not a second queue** — the row sits at a future score until due. The
  delay is a **literal** the wire takes; the curve (`{:fixed,…}` / `{:exponential,…}` / `{:jitter,…}`) is computed
  host-side by `EchoMQ.Backoff.delay_ms/2`.
- **`EchoMQ.Jobs.promote/3`** runs `@promote`: `ZRANGEBYSCORE schedule -inf now` for the due ids, `ZREM schedule`,
  `ZADD pending 0 id`, `HSET state pending`. The job is claimable again — the next `claim/3` pops it, `HINCRBY`ing
  `attempts` to 2.
- **at max** (`att >= max_attempts`, where `att` is the row's current `attempts`, already incremented by the claim):
  `HSET state dead`, `ZADD dead 0 id`, `HINCRBY metrics:failed count 1`, `return 'dead'`. The job lands in the morgue
  with its `last_error`; the handle maps `'dead' → {:ok, :dead}`. (The dead test reads the row's `attempts` value, not
  a separate retry count — so with `max = 2` the job dies on the retry following its second claim, when `attempts = 2`.)

A `dead` job can be sent back with `EchoMQ.Jobs.reprocess_job/3` (`@reprocess`): refuse a job not in `dead`
(`EMQSTATE` → `{:error, :not_dead}`), else `HDEL last_error`, `HSET state pending`, `ZADD pending 0 id`.

### Recovery — reap

If the worker crashes mid-work, nobody completes or retries; the active-set entry simply expires. `EchoMQ.Jobs.reap/2`
runs `@reap` on the **server clock**: `ZRANGEBYSCORE active -inf now` for entries whose lease deadline has passed,
`ZREM active`, `ZADD pending 0 id`, `HSET state pending`. The job returns to pending — no separate lock, no
heartbeat table. The next claim increments `attempts` (the token moves), so the crashed worker's late completion,
if it ever arrives, is fenced out.

### Interactive 1 — the lifecycle stepper

A pure function `stepState(scenario, step)` over a fixed job (`JOB-7a3`, `lease = 30000`, `max = 2`) returns, for
each step on a chosen path, the set membership across the four sets + the row state + `attempts`. Two scenarios:
the **happy path** (enqueue · claim · complete) and the **failure path** (enqueue · claim · retry→scheduled ·
promote · claim · retry→dead). The attempts sequence on the failure path is `0 → 1 → 1 → 1 → 2 → 2` — each `@claim`
`HINCRBY`s `attempts`, and the second retry sees `attempts = 2 >= max 2` and dead-letters. The readout shows, for
the selected step: which set holds the id, the row's `state`, and `attempts` — read off the real transitions in
`jobs.ex`.

## Part 2 — compose a small flow

A flow is a **parent job + a flat list of children**. `EchoMQ.Flows.add/3` lands a same-queue flow in one atomic
`@enqueue_flow` on one slot: gate the parent and every child id; for each child, `HSET` its row
(`state pending`, `attempts 0`, `payload`, `parent <parent-id>`) and `ZADD pending 0 cid`; then hold the parent —
`HSET parent state awaiting_children` and `SET :dependencies n` (the outstanding-child counter as a STRING at
`emq:{q}:job:<parent>:dependencies`). Returns `{:ok, {parent_id, [child_id]}}`. All-or-none: either the whole
flow lands or none of it.

The children are claimable immediately (they sit in pending); the parent is held out of pending until its
children finish. The **fan-in lives inside `@complete`**: when a flow child completes (its row carries a `parent`
field, read host-side by `complete/4`), the script declares the parent's `:dependencies` / `:processed` keys and
its row, then — inside the `was_active == 1` branch — `DECR KEYS[3]` (the counter), `HSET KEYS[4] ARGV[1] ARGV[5]`
(record the child's result in `:processed`), and **at zero** `ZADD pending 0 ARGV[4]` + `HSET KEYS[5] state pending`
(release the parent). The DECR sits inside the once-only active→done branch, so a redelivered or stale-token
completion never double-decrements.

The parent handler runs **on** its children's results, through three pure reads (no state change, all id-gated):

- `EchoMQ.Flows.children_values/3` — `HGETALL` the `:processed` hash → `%{child_id => result}`.
- `EchoMQ.Flows.dependencies/3` — `GET` the `:dependencies` counter → a non-negative integer; `{:ok, 0}` when the
  key is absent.
- `EchoMQ.Flows.ignored_failures/3` — `HGETALL` the `:unsuccessful` hash → `%{child_id => error}`.

### Interactive 2 — the flow composer

A pure function `flowState(n, completed)` over a parent and `n` children (1–5) returns the `:dependencies` count
(`n - completed`), each child's bucket (claimable / done), the parent's row state (`awaiting_children` while
count > 0, `pending` at 0), and the `:processed` map size. Step `completed` from 0 to n and watch the counter
tick to zero and the parent release — the real `SET` n / `DECR` per child / release-at-zero of `@enqueue_flow`
and `@complete`.

## The bridge — pattern ↔ implementation

**The pattern (Redis Patterns Applied):** a reliable queue confirms work atomically and recovers a crashed
worker's job from a visibility timeout; orchestrating dependent work is the flow-control angle, **R6 · Flow
control** (named in prose — `/redis-patterns/flow-control` is not built). The near, resolvable door is
[R3 · Reliable Queues](/redis-patterns/queues).

**The implementation (echo_mq):** the lifecycle is `EchoMQ.Jobs`'s four scripts over four sorted sets — the
active score is the lease, `attempts` is the token, `@reap` recovers on the server clock; the flow is
`EchoMQ.Flows.add/3`'s atomic `@enqueue_flow` plus the fan-in hook inside `@complete`.

## Recap

One job, three moves on the happy path; two more on the failure fork; one for recovery. One flow, an atomic land
and a counter that ticks to zero. The whole machine is four sorted sets and one row hash, and every transition is
one atomic script.

## The durable floor (the door to Echo Persistence)

The job traced above lives in memory: a completed row is deleted, a dead one is retained, a trimmed segment is gone.
None of it has to vanish. When a queue trims its history, `EchoStore.StreamArchive` folds the trimmed segments into the
durable `EchoStore.Graft` floor (CubDB's append-only B-tree, on to Tigris) — deep history without resident memory,
readable beside the live tail. The fold is real code (`echo/apps/echo_store/lib/echo_store/{stream_archive,graft}.ex`);
the durable floor is taught in full in Echo Persistence (`/echo-persistence`), per `docs/echo/bcs/bcs.3.md` B3.3 /
`bcs.5.md`.

## References

### Sources

- Valkey — *ZPOPMIN* (`https://valkey.io/commands/zpopmin/`) — the claim's pop of the oldest pending id.
- Valkey — *ZADD* (`https://valkey.io/commands/zadd/`) — the set insertion every transition ends with (pending,
  active at the lease deadline, schedule at the run-at score).
- Valkey — *DECR* (`https://valkey.io/commands/decr/`) — the fan-in decrement of the `:dependencies` counter.
- Valkey — *ZRANGEBYSCORE* (`https://valkey.io/commands/zrangebyscore/`) — promote and reap select the due / expired
  members by score.
- Redis — *EVALSHA* (`https://redis.io/commands/evalsha/`) — the load-once dispatch each transition script runs with.

### Related in this course

- /echomq/queue — The Queue (the chapter landing).
- /echomq/queue/the-lifecycle — The lifecycle (the state machine in full).
- /echomq/queue/the-lifecycle/claim-and-the-lease — claim, the lease, and the fencing token.
- /echomq/queue/the-lifecycle/completion-and-recovery — complete, retry, reap.
- /echomq/queue/flows — Flows (orchestration over the queue).
- /echomq/queue/flows/parent-and-children — the flow shape and the atomic land.
- /redis-patterns/queues — redis-patterns · Reliable Queues (the near side of the door).
- /echo-persistence — the durable floor a trimmed, retained job folds into.
