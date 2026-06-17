# E2.02.1 · The job model

> Movement I · dive 1 · grounded in `EchoMQ.Job` (`lib/echomq/job.ex`)

A Job in EchoMQ is a **thin Elixir struct over a Redis hash**. The struct is a runtime
materialization; the job's canonical state lives in Redis — the hash plus the state-key membership
(E2.01). `EchoMQ.Job.new(queue_name, name, data, opts \\ [])` (arity 4) builds a `%EchoMQ.Job{}`.

## The struct

`new/4` sets the loud fields and folds the rest of `opts` into the `opts` map:

- `id` = `Map.get(opts, :job_id) || generate_id()` — a custom id via `:job_id`, else auto-generated.
- `name`, `data`, `queue_name` — the call's three positional values.
- `prefix` (default `"bull"`), `timestamp`, `delay` (0), `priority` (0).
- `parent` and `parent_key` (built from a `:parent` ref, for flows), `deduplication_id` (from
  `:deduplication.id`).

The full verified `defstruct` carries: `id, name, data, queue_name, token, connection, worker,
parent_key, parent, processed_by, repeat_job_key, deduplication_id, deferred_failure, processed_on,
finished_on, failed_reason, return_value, opts (%{}), prefix ("bull"), timestamp (0), delay (0),
priority (0), progress (0), stacktrace ([])`, plus `attempts_made`, `attempts_started`, and
`stalled_counter`.

The hash field names (`atm` = attemptsMade, `ats`, `stc`, `deid`, `defa`) and the full hash schema
belong to **E1 · the protocol** — the model names them, the protocol decodes them field by field.
See `/echomq/protocol/job-hash`.

## The options decide where a job lands

The `opts` map is the router. The interactive picks an option set and reports the **target state**
and the **add script**:

- `:delay > 0` → the job lands in `delayed`, written by `addDelayedJob-6`.
- `:priority > 0` → the job lands in `prioritized`, written by `addPrioritizedJob-9`. **Priority 0 is
  the highest priority** (the default), verified in `types.ex`.
- neither → the job lands in `wait`, written by `addStandardJob-9`.

Other options: `:job_id` (custom id), `:prefix` (default `"bull"`), `:timestamp`, `:parent` (a
parent ref → `parent_key`, for flows), `:deduplication` (→ `deduplication_id`), `:lifo`, and the
retry pair `:attempts` + `:backoff` (`%{type: :fixed | :exponential, delay: ms}`), plus
`removeOnComplete` / `removeOnFail`.

## State predicates — pure functions on the struct

The Job carries pure predicates over its own fields: `completed?/1`, `failed?/1`, `active?/1`,
`delayed?/1`, `has_parent?/1`, and `estimated_state/1`. Helpers `should_retry?/1` and
`calculate_backoff/1` read the retry options; `from_redis(job_id, queue_name, data, opts \\ [])`
reconstructs a Job from a Redis HGETALL (the job is a hash), and `to_redis/1` serializes it back.

## The bridge — the hash, then its three runtimes

- **The protocol (immutable L1):** the job hash schema in Redis and its field names — the same
  location and the same field set in every runtime.
- **Its three runtimes (variable L3/L4):** Elixir materializes the hash into `%EchoMQ.Job{}` via
  `Job.from_redis/4`; Go materializes it into its own struct; Node.js into its own class. Each
  runtime builds a different object from the **same** hash; the wire hash does not move.

The takeaway: a Job is a thin view, not the source of truth. Restart the materializer and the hash
is still in Redis — re-read it and you have the same Job again.

## References

### Sources

- BullMQ — *Documentation* (`https://docs.bullmq.io/`) — the job model and its options.
- BullMQ — *Home* (`https://bullmq.io/`) — the project EchoMQ implements.
- Redis — *Hashes* (`https://redis.io/docs/latest/develop/data-types/hashes/`) — the HGETALL the
  Job is reconstructed from.
- Redis — *HSET* (`https://redis.io/commands/hset/`) — the write that creates a job hash.

### Related in this course

- `/echomq/core/jobs-queues-workers` — E2.02 · the module hub.
- `/echomq/core/jobs-queues-workers/the-stateless-queue` — E2.02.2 · the queue that admits the job.
- `/echomq/protocol/job-hash` — E1 · the job hash, field by field.
- `/echomq/core/lifecycle/the-eight-states` — E2.01.1 · the states a job's options target.
- `/redis-patterns/queues` — redis-patterns R3 · Reliable queues.
