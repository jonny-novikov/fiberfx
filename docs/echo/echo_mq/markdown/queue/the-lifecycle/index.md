# The lifecycle — module hub

> Route: `/echomq/queue/the-lifecycle` · surface: module hub · pillar: The Queue.
> Grounded entirely in real code (`echo/apps/echo_mq/lib/echo_mq/{jobs,keyspace}.ex`). No reconcile shadow needed — every
> set, field, and verb is verified on disk (the md carries no ahead-of-code markers).

## The fact

A job has a life, and the whole of it is **four sorted sets and one row**. There is no separate state table, no lock
service, no second index. A job moves between four named sorted sets — `pending`, `active`, `schedule`, `dead` — and its
own hash row carries a `state` field that says where it is. The transitions are:

- `pending → active` — a worker claims the oldest pending job (`@claim`).
- `active → done` — the worker completes it; the row is deleted, the active entry removed (`@complete`).
- `active → scheduled → pending` — the work failed below max attempts; the job is parked on the schedule set with a
  delay, then promoted back to pending when due (`@retry` then `@promote`).
- `active → dead` — the work failed at max attempts; the job lands in the morgue with its `last_error` (`@retry`).
- `active → pending` — the lease lapsed (the worker crashed or stalled); a reaper returns it to pending (`@reap`).

The membership of each set IS the answer to "which jobs are here." The `active` set additionally encodes **when each
lease expires** in the member's score. That is the whole machine.

## The four sets and the one row

| Set | Key | Member | Score |
|---|---|---|---|
| pending | `emq:{q}:pending` | the branded job id | `0` (mint-ordered by member byte order) |
| active | `emq:{q}:active` | the branded job id | the lease deadline (server-clock ms) |
| schedule | `emq:{q}:schedule` | the branded job id | the run-at instant (server-clock ms) |
| dead | `emq:{q}:dead` | the branded job id | `0` |

The row is the hash at `emq:{q}:job:<id>` (built by `EchoMQ.Keyspace.job_key/2`, which gates the id via
`EchoData.BrandedId.valid?/1` before composing the key). It carries `state`, `attempts`, and `payload` from enqueue;
`last_error` is added on a failure.

## The three transitions that carry a job

Each transition is one atomic Lua script run inside Valkey. The hub names them; the dives read them in two beats.

- **claim** (`@claim`) — `ZPOPMIN` the oldest pending id, `HINCRBY attempts`, set `state = active`, `ZADD` to active at
  `now + lease`. The active-set score is the lease deadline; `attempts` is the fencing token.
- **complete** (`@complete`) — verify the attempts token (`EMQSTALE` on mismatch), `ZREM` from active, `DEL` the row,
  bump `metrics:completed`. Only the current token holder may retire the job.
- **retry / reap** (`@retry`, `@reap`) — a failure schedules a delayed retry or, at max attempts, dead-letters; a lapsed
  lease returns the job to pending on the server clock.

## The dives

1. **The four sets** (`/echomq/queue/the-lifecycle/the-four-sets`) — the sets are sorted sets whose members ARE the
   branded ids, so byte order is mint order and the queue needs no second index. `browse/3` (`ZRANGE … REV BYLEX`) and
   `pending_size/2` (`ZCARD`).
2. **Claim & the lease** (`/echomq/queue/the-lifecycle/claim-and-the-lease`) — the `@claim` two-beat: the active-set
   score IS the lease deadline; `attempts` IS the fencing token. `claim/3` honors `paused?/2` first.
3. **Completion & recovery** (`/echomq/queue/the-lifecycle/completion-and-recovery`) — the token-fenced terminal
   (`@complete`) and the recovery transitions (`@retry`, `@reap`, `reprocess_job/3`).

## The interactive (hub)

A **lifecycle map** over a fixed five-job dataset: pick a transition (`claim`, `complete`, `retry`, `dead`, `reap`) and
read which set each job sits in before and after, plus the row `state`. Pure function over the fixed dataset; the SVG and
controls are in static markup; JS only enhances.

## Pattern & implementation

- The pattern (Redis Patterns Applied): a reliable queue moves a job between named locations atomically, so a crash
  never loses or duplicates work. `/redis-patterns/queues` — *States as locations* and *The reliable queue*.
- The implementation (echo_mq): `EchoMQ.Jobs` runs `@claim` / `@complete` / `@retry` / `@reap` — four sorted sets and one
  row, every transition one atomic script.

## References

### Sources
- Valkey — ZADD — `https://valkey.io/commands/zadd/` — the score-carrying set insertion every transition uses.
- Valkey — ZPOPMIN — `https://valkey.io/commands/zpopmin/` — the atomic pop the claim transition begins with.
- Valkey — ZRANGEBYSCORE — `https://valkey.io/commands/zrangebyscore/` — the due-window read promote and reap run.
- Redis — EVALSHA — `https://redis.io/commands/evalsha/` — the load-once dispatch each transition runs by SHA.

### Related in this course
- `/echomq/queue` — the chapter this module belongs to.
- `/echomq/protocol/the-lua-layer` — the Lua layer the transitions are scripts in.
- `/echomq/protocol/the-owned-keyspace` — where the four set keys are built.
- `/redis-patterns/queues` — the reliable-queue pattern this state machine implements.
