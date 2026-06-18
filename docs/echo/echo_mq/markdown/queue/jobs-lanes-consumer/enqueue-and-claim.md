# Enqueue & claim — the producer and the flat worker

**Route:** `/echomq/queue/jobs-lanes-consumer/enqueue-and-claim` · **Pillar:** The Queue · **Surface:** dive

> All real code in `echo/apps/echo_mq/lib/echo_mq/jobs.ex` + `keyspace.ex`. No `[RECONCILE]` markers.

## The fact

To enqueue a job is to run **one idempotent script**. `EchoMQ.Jobs.@enqueue` admits the job by kind, refuses a
duplicate, writes the three-field row, and inserts the pending entry — atomically. To claim one is to run the flat
`@claim`: pop the oldest pending id, lease it on the server clock, and hand it to a worker.

## Beat one — the `@enqueue` handle (real, `jobs.ex`)

```elixir
def enqueue(conn, queue, job_id, payload) when is_binary(job_id) and is_binary(payload) do
  keys = [Keyspace.job_key(queue, job_id), Keyspace.queue_key(queue, "pending")]

  case Connector.eval(conn, @enqueue, keys, [job_id, payload]) do
    {:ok, 1} -> {:ok, :enqueued}      # the row was new
    {:ok, 0} -> {:ok, :duplicate}     # a row already existed — idempotent no-op
    {:error, {:server, "EMQKIND" <> _}} -> {:error, :kind}  # id not JOB-namespaced
    other -> other
  end
end
```

KEYS = `[job_key, pending]` (`job_key/2` → `emq:{q}:job:<id>`, gated; `queue_key/2` → `emq:{q}:pending`). ARGV =
`[job_id, payload]`. Three verdicts: `1`→`:enqueued`, `0`→`:duplicate`, `EMQKIND`→`:kind`.

## Beat two — the `@enqueue` Lua body (real, decoded, `jobs.ex`)

```lua
if string.sub(ARGV[1], 1, 3) ~= 'JOB' then
  return redis.error_reply('EMQKIND job id must be JOB-namespaced')
end
if redis.call('EXISTS', KEYS[1]) == 1 then
  return 0
end
redis.call('HSET', KEYS[1], 'state', 'pending', 'attempts', '0', 'payload', ARGV[2])
redis.call('ZADD', KEYS[2], 0, ARGV[1])
return 1
```

- the **kind-gate** — first three bytes of `ARGV[1]` must be `'JOB'`, else `EMQKIND`. A non-JOB id is refused at the
  wire before any write. The gate lives below the language line.
- **idempotency** — `EXISTS KEYS[1] == 1` → `0`. Two enqueues of the same id leave exactly one row + one pending entry.
- the **three-field row** — `state`/`attempts`/`payload`, in one `HSET`. `attempts` starts at `'0'` (the fencing token).
- the **pending entry** — `ZADD KEYS[2] 0 ARGV[1]`: the id itself is the member at score 0, so byte order is mint order.

## Hero interactive — run @enqueue (three verdicts)

Buttons replay the real `@enqueue` logic over a fixed keyspace: enqueue a new JOB id, enqueue it again (duplicate),
enqueue another new id, enqueue a non-JOB id (kind error). Pure functions; live `.geo-readout`.

## The flat claim (real, `jobs.ex`)

```elixir
def claim(conn, queue, lease_ms) when is_integer(lease_ms) and lease_ms > 0 do
  if paused?(conn, queue) do
    :empty
  else
    keys = [Keyspace.queue_key(queue, "pending"), Keyspace.queue_key(queue, "active")]
    argv = [Keyspace.queue_key(queue, "job:"), Integer.to_string(lease_ms)]

    case Connector.eval(conn, @claim, keys, argv) do
      {:ok, []} -> :empty
      {:ok, [id, payload, att]} -> {:ok, {id, payload, att}}
      other -> other
    end
  end
end
```

`claim/3` honors `paused?/2` first (a paused queue answers `:empty`, pending untouched). The `@claim` body:
`ZPOPMIN` the oldest pending id, `HINCRBY attempts 1`, `HSET state active`, `ZADD active` at `now + lease`, return
`{id, payload, att}`. (The active-set score IS the lease deadline, `attempts` IS the fencing token — the lifecycle's
`claim-and-the-lease` dive reads that in full.)

## Main interactive — the round trip (enqueue → claim)

A two-step trace over a fixed pending set: step "enqueue JOB-7a3" (row written, pending grows) then "claim" (oldest
id popped, leased, returned). Shows pending membership + the claim result. Pure; live `.geo-readout`.

## Bridge

- the pattern (Redis Patterns Applied): a reliable queue admits work once and hands it to exactly one worker — R3
  `/redis-patterns/queues` (built).
- the implementation (echo_mq): `@enqueue` admits idempotently; the flat `@claim` pops, leases, and returns the job.

## Take

Enqueue is one idempotent script; claim is its mirror — pop, lease, return. The producer and the flat worker are two
verbs over one wire.

## References

### Sources
- Redis — `EVALSHA` — https://redis.io/commands/evalsha/
- Valkey — `ZPOPMIN` — https://valkey.io/commands/zpopmin/
- Valkey — `HSET` — https://valkey.io/commands/hset/
- Valkey — `ZADD` — https://valkey.io/commands/zadd/

### Related in this course
- `/echomq/queue/jobs-lanes-consumer` — the module hub
- `/echomq/protocol/the-lua-layer/scripts-are-the-protocol` — the @enqueue two-beat in the Protocol
- `/redis-patterns/queues` — R3, the reliable-queue pattern
