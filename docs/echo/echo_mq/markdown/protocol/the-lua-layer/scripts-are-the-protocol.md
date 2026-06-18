# Scripts are the protocol

**Route:** `/echomq/protocol/the-lua-layer/scripts-are-the-protocol` · **Surface:** dive · **Pillar:** The Protocol

> Source-of-record. As-shipped voice, no version labels. All grounding is real code in `echo/apps/echo_mq` —
> **no `[RECONCILE]` markers**. Lua is shown in **two beats** (the named handle, then the decoded body), never a
> `file:line`.

## The fact

A state transition in EchoMQ is not a sequence of client commands — it is **one server-side Lua script that runs
atomically**. The enqueue transition is the `@enqueue` script: it admits the job by kind, refuses a duplicate, writes
the row, and inserts the pending entry, in one indivisible step. No other client can observe the row half-written, and
no concurrent enqueue of the same id can write it twice. The script *is* the enqueue protocol.

## The worked example — the enqueue transition in two beats

### Beat one — the named handle

`EchoMQ.Jobs.enqueue/4` builds the two keys the transition touches — the job row and the pending set — and runs the
`@enqueue` script through the connector. The keys are built host-side by `EchoMQ.Keyspace`; the values (the branded id
and the payload) ride `ARGV`. The Elixir verb is the handle; the Lua is the transition.

```elixir
# echo_mq — EchoMQ.Jobs
# enqueue/4 is the handle. It builds the two keys @enqueue will touch — the
# job row and the pending set — and hands them in declared. The connector
# runs @enqueue EVALSHA-first. KEYS = [row, pending]; the values (id, payload)
# ride ARGV. The script's integer return is mapped to a verdict.
def enqueue(conn, queue, job_id, payload) when is_binary(job_id) and is_binary(payload) do
  keys = [Keyspace.job_key(queue, job_id), Keyspace.queue_key(queue, "pending")]

  case Connector.eval(conn, @enqueue, keys, [job_id, payload]) do
    {:ok, 1} -> {:ok, :enqueued}      # the row was new — written and made pending
    {:ok, 0} -> {:ok, :duplicate}     # a row already existed — idempotent no-op
    {:error, {:server, "EMQKIND" <> _}} -> {:error, :kind}  # the id was not JOB-namespaced
    other -> other
  end
end
```

### Beat two — the script body

`@enqueue` is the protocol. Four moves, one atomic step: the branded-id gate, the idempotency check, the row write, the
pending insertion.

```lua
-- the @enqueue script — one atomic transition, every key declared
-- The branded-id gate: the id must be JOB-namespaced (first three bytes 'JOB'),
-- refused at the wire. The gate runs in Lua, so no malformed id can be admitted
-- by any speaker — the rule lives below the language line.
if string.sub(ARGV[1], 1, 3) ~= 'JOB' then
  return redis.error_reply('EMQKIND job id must be JOB-namespaced')
end
-- Idempotency: a row that already exists is a no-op. Two enqueues of the same
-- id leave exactly one row and one pending entry — the second returns 0.
if redis.call('EXISTS', KEYS[1]) == 1 then
  return 0
end
-- The three-field row: state, attempts, payload — the shape every speaker reads.
-- attempts starts at '0' (the fencing token); state starts at 'pending'.
redis.call('HSET', KEYS[1], 'state', 'pending', 'attempts', '0', 'payload', ARGV[2])
-- The pending set: the id itself is the member at score 0, so byte order is mint
-- order and the queue carries no second index.
redis.call('ZADD', KEYS[2], 0, ARGV[1])
return 1
```

`KEYS[1]` is the job row, `KEYS[2]` the pending set; `ARGV[1]` is the branded id, `ARGV[2]` the payload. Every key the
script touches arrives declared; every value rides `ARGV`. The four moves are one transition — the row and the pending
entry appear together or not at all.

## The pairing — the pattern → the implementation

- **The pattern (Redis Patterns Applied):** an atomic multi-step update, expressed as one server-side script, becomes a
  protocol when the agreement is pushed below the language line — `/redis-patterns` teaches the move in
  "patterns become protocol" and atomic updates.
- **The implementation (echo_mq):** `EchoMQ.Jobs` `@enqueue` runs the four-move transition atomically; `enqueue/4` is
  the handle that builds the keys and maps the verdict.

## Recap

The enqueue transition is one atomic Lua script: gate the branded id, refuse a duplicate, write the three-field row,
insert the pending entry. Read it in two beats — `enqueue/4` the handle, `@enqueue` the transition. The next dive reads
the declared-keys law the script obeys.

## References

### Sources
- Redis — *EVAL* — `https://redis.io/commands/eval/` — atomic server-side scripting; a script runs to completion with
  no interleaving.
- Valkey — *EVALSHA* — `https://valkey.io/commands/evalsha/` — the load-once dispatch the handle runs the script with.
- Valkey — *HSET* — `https://valkey.io/commands/hset/` — the hash write the row is built from.
- Valkey — *ZADD* — `https://valkey.io/commands/zadd/` — the pending-set insertion the script ends with.

### Related in this course
- `/echomq/protocol/the-lua-layer` — the module this dive belongs to.
- `/echomq/protocol/the-lua-layer/declared-keys` — the law the script obeys.
- `/echomq/protocol/the-record-hash` — the three-field row the script writes.
- `/redis-patterns/coordination/atomic-updates` — the atomic-update pattern, the near side of the door.
- `/redis-patterns/overview/patterns-become-protocol` — convention becoming protocol.
