# Round-trip elimination

> Route: `/redis-patterns/flow-control/batches/round-trip-elimination` · R6.04.1 dive · Redis Patterns Applied
> Identity: BCS contract-sheet, redis-red. Grounded in the real as-built echo data layer (`echo/apps/echo_mq`).

**N separate enqueues cost N network round-trips; one pipelined flush costs one. The win is wall-clock round-trip
time — the server still runs every script, but the bytes cross the wire once.** This is the whole reason a batch is
faster than a loop, and it is worth seeing exactly where the saving lives so it is not confused with doing less
work.

## The cost of a round-trip

A single enqueue is a request and a reply. The client sends the command, then waits for the server to answer before
it can send the next one. That wait is a round-trip: the time for the bytes to reach the server, plus the server's
work, plus the time for the reply to come back. On a fast local link the network part is small; across a network
boundary it dominates, and it is paid once per command.

Enqueue a thousand jobs in a loop and you pay that round-trip a thousand times, back to back — send, wait, send,
wait. The server is idle for most of each cycle, waiting for the next request to arrive; the client is idle for the
rest, waiting for the reply. The throughput ceiling is not the server's speed. It is the latency of the link times
the number of items.

## The flush

Pipelining removes the wait. The client writes every command to the socket without pausing for the replies, then
reads all the replies together. The commands still execute on the server, in order, one after another — but the
client no longer pays a round-trip between each. It pays one: the time to push the whole batch out and read the
whole batch back.

`enqueue_many/4` is exactly this. It assembles one `EVALSHA` command per `{id, payload}` pair into an
`EchoWire.Pipe`, then flushes the pipe once. The accumulation is a fold over the pairs; the flush is a single
`exec`:

```
pipe =
  Enum.reduce(pairs, Pipe.new(conn, via: via), fn {id, payload}, pipe ->
    Pipe.command(pipe, ["EVALSHA", sha, "2", job_key, pending_key, id, payload])
  end)

Pipe.exec(pipe)
# → one round-trip carries every EVALSHA; the replies return in one frame, in order
```

The reduce builds the command list; `exec` sends it and reads the replies. A thousand pairs become a thousand
`EVALSHA` commands in one write and a thousand replies in one read — one round-trip, not a thousand.

## What does not change

The saving is on the wire, and only on the wire. Each pair still runs the full enqueue script on the server:
kind-gate the id, `EXISTS` for a duplicate, `HSET` the row, `ZADD` the pending entry. The server does the same
total work for a batch of N as for N separate enqueues — N script executions. Pipelining changes *when the bytes
travel*, never *how much the server computes*.

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

That is the right way to reason about it. If the server is the bottleneck — the scripts are heavy, the CPU is
saturated — a batch will not help, because the batch runs the same scripts. If the *round-trip* is the bottleneck —
many cheap writes across a network — a batch turns N round-trips into one and the throughput rises by close to the
factor of N, until something else becomes the limit.

## The reply still maps per item

Reading the replies together does not collapse them. The flush returns a list of N results in input order, and
`enqueue_many/4` maps each to a verdict: `1` becomes `:enqueued`, `0` becomes `:duplicate`, an `EMQKIND` error
becomes `{:error, :kind}`. So the batch buys the round-trip saving without giving up per-item visibility — every
item's outcome is still there, at its own position in the list. The third dive examines that verdict model against a
transaction's single result.

> **The pattern** — collapse N round-trips into one flush.
> **↔** Its EchoMQ application — `EchoWire.Pipe` accumulates one `EVALSHA` per pair and `exec` sends them in a single
> round-trip; the server runs all N scripts, the wire carries one request and one reply.

## Applied

In codemojex — a Telegram emoji-guessing game on the same stack — a single guess is admitted by
`Codemojex.Guesses.submit/3`, one enqueue per guess. When a burst of player commands arrives together, sending each
as its own round-trip is the slow path; the flat-queue batch shape admits the burst in one flush over
`emq:{cm}:pending`, so the wire cost is paid once for the whole burst rather than once per guess.

Driving that batch into the consumer at scale — the pool that flushes it, the claim that drains it — is the queue's
scaling layer, taught in the EchoMQ course.

## References

### Sources

- Valkey — *Pipelining* (https://valkey.io/topics/pipelining/) — the canonical description of why pipelining cuts
  round-trip time without reducing server work.
- Valkey — *EVALSHA* (https://valkey.io/commands/evalsha/) — the per-pair command the pipe accumulates; one cached
  script run per item.
- Valkey — *ZADD* (https://valkey.io/commands/zadd/) — the score-0 pending insert each enqueue script runs on the
  server, batch or not.

### Related in this course

- R6.04 · Batches & pipelining (`/redis-patterns/flow-control/batches`) — the module hub.
- R6.04.2 · Chunking across a pool (`/redis-patterns/flow-control/batches/chunking-across-a-pool`) — flushing the
  batch across N pooled connectors.
- R6.04.3 · Partial-failure handling (`/redis-patterns/flow-control/batches/partial-failure-handling`) — reading the
  per-item verdicts the flush returns.
- /echomq/queue — EchoMQ's Queue pillar, where the batch is driven into the consumer.
- /bcs/bus — Part B3, the Valkey-native bus the figures draw from.
