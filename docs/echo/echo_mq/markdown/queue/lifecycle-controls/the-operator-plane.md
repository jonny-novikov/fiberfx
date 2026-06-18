# The operator plane

> Route: `/echomq/queue/lifecycle-controls/the-operator-plane` · surface: dive · grounding: all **real code** in
> `echo/apps/echo_mq` — `EchoMQ.Admin.{pause/2, resume/2, drain/3, obliterate/3}` + the `@pause`/`@resume`/`@drain`/
> `@obliterate` Lua, and the per-job verbs on `EchoMQ.Jobs` — `update_data/4`, `update_progress/4` (with the `PUBLISH`
> on `emq:{q}:events`), `add_log/5`, `get_job_logs/3`, `remove_job/4`, `reprocess_job/3`. No `[RECONCILE]` markers.

## The fact — control over the whole queue, and one job's row

An operator's runbook drives a live queue. Two scopes:

- **Queue scope** (`EchoMQ.Admin`) — pause and resume claiming on the entire queue; drain the pending backlog;
  obliterate a paused queue down to its keyspace footprint.
- **Job scope** (`EchoMQ.Jobs`) — reach into one job's row to replace its payload, write progress, append logs, remove
  it, or reprocess a dead one.

## Pause is a separate gate, so the claim script never changes

`pause/2` runs `@pause`: `HSET KEYS[1] paused 1` on `emq:{q}:meta`. `resume/2` runs `@resume`: `HDEL` that field. The
pause is a field on the queue's meta hash — not a move on any set.

The claim path reads that field **first** and answers `:empty` when it is set, even with a non-empty pending set; the
pending backlog is untouched. This is the separate-gate form: the claim script stays byte-unchanged, and the gate lives
above it in `Jobs.claim/3` (and `Lanes.claim/3`, so a queue-wide pause gates both the flat and the grouped claim). A
paused queue stops serving work without losing a single member.

## Drain empties the backlog; active and the cadence survive

`drain/3` runs `@drain`: for the pending set (and the schedule set when asked), read the members, delete each job's row
and its `:logs` subkey, then delete the set. It answers `{:ok, n}`, the count drained.

Two things it does **not** touch: the **active** set (those jobs are in flight) and the **repeat** registry (a
registered repeatable keeps producing after a drain). A drain clears the backlog of already-enqueued work; it does not
cancel work in hand or stop the cadence that produces more.

## Obliterate destroys a paused queue, bounded

`obliterate/3` runs `@obliterate`: it refuses a non-paused queue (`EMQSTATE not paused` → `{:error, :not_paused}`) and,
unless forced, a queue with live active jobs (`EMQSTATE active jobs present` → `{:error, :active}`). Otherwise it deletes
every state set (`pending`/`active`/`schedule`/`dead`), every reachable job row, and the auxiliary keys — the metrics
hashes, the lane structures, the repeat records, the meta hash with the paused flag. It is bounded per invocation by a
budget: it answers `:more` while work remains (call again) and `:ok` when the queue is gone. There is no
`completed`/`failed` set to destroy — the metrics hashes are the throughput record, deleted as keys.

The order matters: a queue must be paused before it can be obliterated, and (unforced) it must have no jobs in flight.
The destructive verb refuses to run on a live queue.

## The per-job verbs reach into one row

The per-job plane lives on `EchoMQ.Jobs`, beside the state machine it extends. Each is one inline script that declares
its keys; the branded id is gated at the key builder; a missing job answers a typed `{:error, :gone}` and changes
nothing.

- `update_data/4` — replace the row's `payload` field.
- `update_progress/4` — write the row's `progress` field, then `PUBLISH` a progress event on the per-queue events
  channel `emq:{q}:events`: a `cjson`-encoded `{"event":"progress","job":"<id>","progress":"<value>"}`. The event name
  rides the payload's `event` field, so one channel per queue carries every lifecycle event. A subscriber-less PUBLISH is
  a no-op.
- `add_log/5` — append a line to the job's logs list (`emq:{q}:job:<id>:logs`) and answer the count; with a `keep`
  argument, the list is trimmed to the last `keep` lines. `get_job_logs/3` reads the list in append order.
- `remove_job/4` — remove the job from whichever of the four sets holds it, delete the row and its `:logs` subkey, and
  release a held dedup key when the caller supplies its id. It **refuses a locked job** (`emq:{q}:job:<id>:lock` present)
  with `{:error, :locked}`, leaving it untouched.
- `reprocess_job/3` — move a dead job back to pending: clear `last_error`, set `state = pending`, add it to the pending
  set. It **refuses a job not in dead** with `{:error, :not_dead}`.

## Worked example

A queue is misbehaving. The operator pauses it (`pause/2`) — claiming stops, the backlog stays. They inspect a stuck
job's logs (`get_job_logs/3`), fix its payload (`update_data/4`), and move a job that died on a transient error back to
pending (`reprocess_job/3`). When the bad release is fully cleared, they drain the backlog (`drain/3`) — active jobs
finish, the daily-report cadence survives. To retire the queue entirely, they obliterate it (`obliterate/3`), calling
again on `:more` until `:ok`.

## Interactive 1 (hero) — the separate gate

A queue with a pending set and a paused flag. Toggle pause and run a claim; the readout shows the claim answers `:empty`
while the flag is set, and the pending depth is unchanged before and after. Pure: the claim verdict is a function of the
flag and the pending depth.

## Interactive 2 (main) — the operator console

Pick a verb (pause · resume · drain · obliterate · update-data · update-progress · add-log · remove-job · reprocess) and
a queue state; the readout names the real fn, the precondition it checks, and the verdict — including the typed refusals
(`{:error, :not_paused}`, `{:error, :active}`, `{:error, :locked}`, `{:error, :not_dead}`, `{:error, :gone}`). Pure over
a fixed dataset.

## Bridge

- The pattern (Redis Patterns Applied): operating a queue at scale — pausing intake, clearing a backlog, retrying a
  failure — is the operational side of the delay/schedule/priority family.
  `/redis-patterns/time-delay-priority` teaches it.
- The implementation (echo_mq): `EchoMQ.Admin` is the queue-scope plane (pause as a separate gate, drain that spares
  active, bounded obliterate); the per-job verbs on `EchoMQ.Jobs` reach into one row.

## Take

Pause is a field the claim reads, not a move on a set; drain spares what is in flight and the cadence that produces more;
obliterate refuses a live queue; and every per-job verb is a fenced transition that refuses cleanly. The operator plane
is the runbook, in real transitions.

## References

### Sources
- valkey.io/commands/hset/ — the meta field pause sets and the row fields the per-job verbs write.
- valkey.io/commands/hdel/ — the field resume clears.
- valkey.io/commands/publish/ — the progress event update_progress emits on the events channel.
- redis.io/commands/evalsha/ — the load-once dispatch every operator verb runs by SHA.
- valkey.io/docs/ — the substrate of record.

### Related in this course
- /echomq/queue — The Queue.
- /echomq/queue/lifecycle-controls — the module hub.
- /echomq/protocol — the keyspace and the Lua layer the operator plane runs on.
- /redis-patterns/time-delay-priority — the operational delay/schedule family.
