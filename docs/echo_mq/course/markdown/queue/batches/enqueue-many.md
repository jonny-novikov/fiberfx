# Enqueue many — load once, pipeline the rest

**Route:** `/echomq/queue/batches/enqueue-many` · **section:** queue · **pillar:** The Queue · **surface:** dive

> Source-of-record. All grounding is real code in `echo/apps/echo_mq/lib/echo_mq/jobs.ex` — no `[RECONCILE]` markers.

## The fact

To admit one job is to run the `@enqueue` script. To admit many is to run **that same script, many times, in one wire
flush** — and read back **one verdict per item, in input order**. `EchoMQ.Jobs.enqueue_many/3` does exactly that in two
moves:

1. **Load the script once.** `SCRIPT LOAD` the `@enqueue` source (`@enqueue.source`) into the server's script cache.
   The server answers with the SHA the body hashes to; the connector already holds the same SHA at `@enqueue.sha`
   (precomputed by `EchoMQ.Script.new/2`).
2. **Pipeline the EVALSHA calls.** Build one `EVALSHA` command per `{id, payload}` pair — `["EVALSHA", @enqueue.sha,
   "2", job_key, pending_key, id, payload]` — and send the whole list with `Connector.pipeline/3` in one flush. The
   numkeys is the literal `"2"`: each call declares the job row and the pending set, exactly as `enqueue/4` does.

The replies come back **in the order the commands were sent**, so the result list is mapped position-for-position:
`1 -> :enqueued`, `0 -> :duplicate`, `{:error_reply, "EMQKIND" <> _} -> {:error, :kind}`. The verb returns
`{:ok, [verdict, …]}` — one verdict per input pair, in input order.

Every item runs **the same `@enqueue` body** the single `enqueue/4` runs: the `EMQKIND` branded-id gate, the `EXISTS`
idempotency check, the `HSET` three-field row, the `ZADD` pending entry. A batch changes the number of round trips, not
the contract each item obeys. A duplicate inside the batch returns `0` (it is a no-op, exactly as it is alone); a
non-`JOB` id returns its `EMQKIND` error and writes nothing; and the items beside it are unaffected — each EVALSHA is
its own atomic transition.

## The worked example — enqueue_many/3 on the real grounding

```elixir
# echo_mq — EchoMQ.Jobs
# enqueue_many/3 batches the @enqueue transition. Two moves:
#   1. SCRIPT LOAD the @enqueue source once (the server caches it by SHA).
#   2. build one EVALSHA command per {id, payload} and pipeline them in ONE flush.
# Each EVALSHA declares the same two keys enqueue/4 declares (numkeys "2"):
# the job row emq:{q}:job:<id> and the pending set emq:{q}:pending. The replies
# return IN INPUT ORDER, so the result list is mapped position-for-position.
def enqueue_many(conn, queue, pairs) when is_list(pairs) do
  {:ok, _} = Connector.command(conn, ["SCRIPT", "LOAD", @enqueue.source])

  cmds =
    for {id, payload} <- pairs do
      ["EVALSHA", @enqueue.sha, "2",
       Keyspace.job_key(queue, id), Keyspace.queue_key(queue, "pending"),
       id, payload]
    end

  with {:ok, results} <- Connector.pipeline(conn, cmds) do
    {:ok,
     Enum.map(results, fn
       1 -> :enqueued                                  # the row was new — written and pended
       0 -> :duplicate                                 # a row already existed — idempotent no-op
       {:error_reply, "EMQKIND" <> _} -> {:error, :kind}  # id not JOB-namespaced
     end)}
  end
end
```

The body of `@enqueue` is unchanged — it is the same script taught in two beats elsewhere. The batch adds no new Lua;
it loads the existing body once and runs it by SHA per item. (`Connector.pipeline/3` sends the command list in one
flush; `Connector.command/3` runs the one-off `SCRIPT LOAD`.)

## Interactive — the batch composer (hero) + the order contract (main)

- **Hero — compose a batch.** A fixed batch of four pairs over a fixed keyspace. Step the composer to read the
  per-item verdict each EVALSHA returns — a new id enqueues, a repeat is a duplicate no-op, a non-`JOB` id is an
  `EMQKIND` error, and the verdict list comes back in the order the pairs were sent. Pure over the fixed dataset.
- **Main — the order contract.** Pick a position in the result list to confirm verdict `k` answers pair `k`:
  pipelining preserves order, so position is identity. Pure lookup.

## Pattern & implementation

- **The pattern (Redis Patterns Applied):** pipelining sends N commands in one round trip and reads the N replies in
  order — the network cost falls from N turns to one. `/redis-patterns/queues` teaches reliable queues; the
  pipelined-admission angle is the near side of this door.
- **The implementation (echo_mq):** `enqueue_many/3` loads `@enqueue` once with `SCRIPT LOAD`, then pipelines one
  `EVALSHA` per pair in one flush, and maps the ordered replies to ordered verdicts — the same script, row, and
  idempotency as `enqueue/4`.

## Recap

Enqueue many is the single enqueue, pipelined: load `@enqueue` once, run it by SHA per item in one flush, and read one
verdict per item in input order. The batch is a wire optimization; each item still passes the same gate, the same
idempotency, the same row.

## References

### Sources
- Redis — SCRIPT LOAD (`https://redis.io/commands/script-load/`) — load the `@enqueue` body once; the server caches it by SHA.
- Redis — EVALSHA (`https://redis.io/commands/evalsha/`) — run the cached script by SHA, once per pipelined item.
- Valkey — ZADD (`https://valkey.io/commands/zadd/`) — the pending-set insertion every admitted item ends with.
- Valkey — Documentation (`https://valkey.io/docs/`) — the substrate of record EchoMQ is backed by.

### Related in this course
- `/echomq/queue/batches` — Batches, the module this dive belongs to.
- `/echomq/queue/batches/bulk-flows` — compose many flows in one call, fail-closed per flow.
- `/echomq/queue/jobs-lanes-consumer/enqueue-and-claim` — the single `enqueue/4` this batches.
- `/echomq/protocol/the-lua-layer/scripts-are-the-protocol` — the `@enqueue` two-beat in the Protocol chapter.
- `/redis-patterns/queues` — reliable queues, the near side of the door.
