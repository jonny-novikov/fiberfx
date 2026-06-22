# echo_mq — the EchoMQ queue, lanes, jobs, and flows

`echo_mq` (EchoMQ) is the message queue and background-job engine of the platform:
a RESP3 connector to Valkey that the BEAM and the Go runtimes both speak, plus the
queue verbs built on it — fair lanes, reliable jobs with delays and retries, DAG
flows, pub/sub events, and lease management. It is the coordination half of the
`echo_mq → echo_data → echo_store` stack, and the bus Codemojex runs its
per-player guess lanes and settlement queue on.

## The connector

`EchoMQ.Connector` negotiates `HELLO 3` (RESP3) with Valkey and pipelines
commands. Every verb below takes a `conn` from a started connector; the project's
default Valkey port is `6390`.

## Fair lanes — `EchoMQ.Lanes`

Work is grouped, and service rotates **round-robin across groups** so one busy
group cannot starve the others — the property Codemojex relies on to keep one
key-masher from monopolising the score worker (the lane is keyed by the player's
`USR`).

| Function | Purpose |
|---|---|
| `enqueue/5` | enqueue `payload` as `job_id` on `{queue, group}` |
| `claim/3` | claim the next job across groups, leased for `lease_ms` |
| `pause/3`, `resume/3` | park / unpark a group's lane |
| `limit/4` | cap a group's in-flight work |
| `reassign/4` | move a job to another group |
| `drain/3`, `reap_group/4` | empty / reap a group |
| `depth/3` | a group's queued depth |

## Reliable jobs — `EchoMQ.Jobs`

A durable job queue with delayed delivery, retries with backoff, leases, logs, and
progress.

| Function | Purpose |
|---|---|
| `enqueue/4`, `enqueue_many/3` | enqueue now |
| `enqueue_at/5`, `enqueue_in/5` | delayed delivery |
| `claim/3`, `complete/5` | lease a job / finish it with a result |
| `retry/7`, `promote/3`, `reap/2` | retry with delay / promote due delayed jobs / reap stalled |
| `extend_lock/5`, `extend_locks/4` | extend a lease (heartbeat) |
| `update_data/4`, `update_progress/4`, `add_log/5`, `get_job_logs/3` | live job state |
| `browse/3`, `pending_size/2`, `remove_job/4`, `reprocess_job/2` | inspect / manage |

## DAG flows — `EchoMQ.Flows`

A parent job that runs only after its children complete, with the children's
results made available to it.

| Function | Purpose |
|---|---|
| `add/3`, `add_bulk/3` | add a parent + children (a flow / many flows) |
| `children_values/3` | the children's results, keyed by child id |
| `dependencies/3` | a parent's outstanding dependencies |
| `ignored_failures/3` | children whose failure the parent tolerates |

## Events — `EchoMQ.Events`

Pub/sub over a per-queue channel: `publish/5` an event for a job, `subscribe/2` a
process to the queue's event stream (`unsubscribe/2`, `close/2`, `channel/1`,
`event_name/1`). Codemojex publishes a `scored` event per guess this way.

## Lease management — `EchoMQ.Locks`

A heartbeat manager that tracks a consumer's held jobs (`track_job/3`,
`untrack_job/2`) and extends their leases on a beat so in-flight work isn't reaped
mid-flight (`get_active_job_count/1`, `get_tracked_job_ids/1`, `is_tracked?/2`).

## Consuming — `EchoMQ.Consumer`

A supervised GenServer (`child_spec/1`, `start_link/1`, `stop/2`) that drains a
lane via `Lanes.claim/3` and invokes a handler with `%{id:, payload:, group:}` —
the group arriving as the lane key (for Codemojex, the player id). This is what
turns the guess queue into a single scoring authority.

For **event streams** (the Stream Tier — at-least-once grouped delivery with
crash → re-delivery), the sibling is `EchoMQ.StreamConsumer`: a supervised consumer
group over `EchoMQ.Stream.append/4`'s per-key stream, reading `XREADGROUP … >` on
its own private lane, recovering its own un-acked backlog on restart and dead peers'
on the beat. See [`echo_mq/stream_consumer.md`](echo_mq/stream_consumer.md).

## Conformance and the stories catalogue

EchoMQ documents itself with **BDD story tests** (`test/stories/*_story_test.exs`,
written with `EchoMQ.Story`) that are simultaneously runnable acceptance tests
against Valkey and the source of a generated catalogue:

    mix echo_mq.stories     # -> docs/echo_mq/stories/<feature>.stories.md + README.md

`EchoMQ.Conformance` and the conformance test suite assert the queue verbs behave
to spec. The existing story catalogue covers, among others: flows (success and
failure), groups (fair lanes), and the `wire_pipe` family — cache-aside,
command/value, counter, dispatch, distributed lock, error split, hash object,
leaderboard, reliable queue, and set membership. A scenario reaches the catalogue
only because a test driving the real surface compiled, so the docs cannot lie.

## Why the versions are pinned

The connector's behaviour and the keyspace memory figures it produces are tied to
the RESP3 server it was exercised against; the bench builds Valkey from source and
pins the BEAM so a live run or a `.out` figure regenerates.
