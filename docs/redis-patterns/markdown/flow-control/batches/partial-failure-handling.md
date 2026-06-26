# Partial-failure handling

> Route: `/redis-patterns/flow-control/batches/partial-failure-handling` · R6.04.3 dive · Redis Patterns Applied
> Identity: BCS contract-sheet, redis-red. Grounded in the real as-built echo data layer (`echo/apps/echo_mq`).

**A pipelined batch is not all-or-nothing. `enqueue_many/4` returns a verdict for every item in input order — some
enqueued, some duplicate, some refused — and an empty batch refuses outright. That is a deliberate choice over
`MULTI`/`EXEC` rollback, and for an at-least-once queue it is the better one.** This dive corrects the catalog
framing of "bulk enqueue" as a transaction and shows why the per-item model is the honest design.

## The picture to unlearn

"Bulk enqueue" sounds like a transaction: send a batch, and either the whole batch lands or none of it does. That is
the `MULTI`/`EXEC` model, and it is not what `enqueue_many/4` does. There is no rollback. If the third item in a
batch is a duplicate and the fifth has a malformed id, the first, second, and fourth are still enqueued — the batch
does not unwind. What the caller gets back is not a single success-or-failure; it is a **list of verdicts, one per
item, in input order**.

## The verdict list

Each `{id, payload}` pair runs the same idempotent enqueue script, and the script's return maps to a verdict:

- `:enqueued` — the script returned `1`: the row and the pending entry were written.
- `:duplicate` — the script returned `0`: a row already existed at that id, so the script made no change.
- `{:error, :kind}` — the id was not `JOB`-namespaced; the script refused it with `EMQKIND`.

`enqueue_many/4` maps the flushed replies straight onto these:

```
{:ok,
 Enum.map(results, fn
   1 -> :enqueued
   0 -> :duplicate
   {:error_reply, "EMQKIND" <> _} -> {:error, :kind}
 end)}
```

The list has the same length and order as the input, so position `n` in the verdict list is the outcome of pair `n`.
A caller reads it to learn exactly which items landed and which were refused — and the refusals do not contaminate
the rest. One duplicate among a thousand new jobs enqueues nine hundred ninety-nine and reports the one.

The empty batch is the boundary case: `enqueue_many(conn, queue, [])` answers `{:error, :empty_pipeline}`. There is
nothing to flush, and the empty pipe refuses rather than send a frame with no commands.

## Atomic per item, not per batch

The subtlety worth being precise about: every item *is* atomic, but not the batch. Each member runs the enqueue
script, and that script is one indivisible server-side step — the kind-gate, the `EXISTS` check, the `HSET`, and the
`ZADD` either all happen for that item or none do. An item never lands half-written. What the batch gives up is
atomicity *across* items: there is no point at which all items are applied together or none are.

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

So the unit of atomicity is the item; the unit of the round-trip saving is the batch. They are different scopes on
purpose.

## Why per-item beats rollback here

For an at-least-once queue, the per-item model is the stronger one, not a compromise.

The enqueue script is idempotent: a second enqueue of the same id is a `:duplicate`, a no-op. So if a batch is sent
again — a retry after a timeout, a redelivery, a producer that is not sure the first send landed — the items that
already enqueued report `:duplicate` and the items that did not enqueue land. The batch *converges* to the intended
state. A transaction would instead fail the whole retried batch because some members now conflict, and the producer
would have to reason about which items to strip before resending.

Per-item idempotent dedup beats whole-batch rollback because the failure mode of a queue producer is a re-sent
batch, and the per-item model handles a re-send by settling rather than by aborting. The price is that the caller
reads a verdict list instead of a single boolean — which is information it wanted anyway.

> **The pattern** — a batch that reports per-item rather than rolling back.
> **↔** Its EchoMQ application — `enqueue_many/4` maps the flushed replies to `:enqueued` / `:duplicate` /
> `{:error, :kind}` in input order; an empty batch is `{:error, :empty_pipeline}`. Each item is atomic via the
> enqueue script; the batch is not transactional, by design.

## Pipeline against transaction, side by side

| | pipelined batch (`enqueue_many/4`) | a transaction (`MULTI`/`EXEC`) |
|---|---|---|
| atomicity | per item (the enqueue script) | across the whole batch |
| on a bad item | that item's verdict; the rest land | the conditions that roll back undo the batch |
| reply | a list of verdicts, in input order | one result for the batch |
| a re-sent batch | converges — duplicates are no-ops | conflicts; the batch must be reshaped |
| the win | one round-trip, per-item visibility | all-or-nothing semantics |

The two are different tools. A pipeline is right when items are independent and the producer may re-send; a
transaction is right when the items are only meaningful together and must not partially apply. `enqueue_many/4`
chose the pipeline because a queue's producers re-send, and convergence is worth more than rollback.

## Applied

In codemojex — a Telegram emoji-guessing game on the same stack — a single guess is admitted by
`Codemojex.Guesses.submit/3`, which mints a `JOB` and enqueues it. When a burst is admitted in one flush, a stray
duplicate or a malformed id in the burst fails only itself: the rest of the guesses enqueue, and the verdict list
says which. If the bot re-sends a burst it is unsure landed, the already-enqueued guesses report `:duplicate` and
the missing ones land — the burst converges. Driving these bursts through the consumer at scale is the queue's
scaling layer, taught in the EchoMQ course.

## References

### Sources

- Valkey — *Transactions* (https://valkey.io/topics/transactions/) — `MULTI`/`EXEC` and the all-or-nothing model a
  pipeline deliberately does not provide.
- Valkey — *Pipelining* (https://valkey.io/topics/pipelining/) — the transport model that returns a reply per
  command, the basis of the per-item verdict list.
- Valkey — *EVALSHA* (https://valkey.io/commands/evalsha/) — the per-item command; an error reply on one item is one
  item's verdict, not a batch abort.

### Related in this course

- R6.04 · Batches & pipelining (`/redis-patterns/flow-control/batches`) — the module hub.
- R6.04.1 · Round-trip elimination (`/redis-patterns/flow-control/batches/round-trip-elimination`) — the round-trip
  saving the verdict list preserves.
- R6.04.2 · Chunking across a pool (`/redis-patterns/flow-control/batches/chunking-across-a-pool`) — the pooled flush
  whose replies still map per item.
- R2 · Distributed coordination (`/redis-patterns/coordination`) — `atomic-updates`, the per-item idempotent script.
- /echomq/queue — EchoMQ's Queue pillar, where bursts are driven through the consumer.
- /bcs/bus — Part B3, the Valkey-native bus the figures draw from.
