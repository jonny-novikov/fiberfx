# Batches — the same per-item contract, pipelined

**Route:** `/echomq/queue/batches` · **section:** queue · **pillar:** The Queue · **surface:** module hub

> Source-of-record for the hub. All grounding is real code in `echo/apps/echo_mq` — no `[RECONCILE]` markers.

## The fact

A batch is not a new kind of work. It is the **same per-item transition, issued many at once in one wire flush** —
and answered with **one verdict per item, in input order**. The Queue's bulk verbs change the round-trip count, never
the rule each item obeys.

Three bulk verbs sit on the real Queue surface, each the bulk twin of a single verb taught elsewhere:

- **Admit many** — `EchoMQ.Jobs.enqueue_many/3` runs the `@enqueue` transition for many `{id, payload}` pairs in one
  flush: `SCRIPT LOAD` the `@enqueue` source once, then an `EVALSHA` pipeline. Each item gets the same verdict the
  single `enqueue/4` returns (`:enqueued` | `:duplicate` | `{:error, :kind}`), in input order.
- **Compose many** — `EchoMQ.Flows.add_bulk/3` lands many flows, each through the single `add/3`, **fail-closed per
  flow**: a flow that fails to land leaves its own parent held and the batch continues. Returns
  `{:ok, [{parent_id, [child_id]}]}` in input order.
- **Extend many** — `EchoMQ.Jobs.extend_locks/4` re-scores every `active` member whose token matches under one
  server-clock read, and returns the `failed` list (the ids whose token was stale or whose row was gone).

The shared idea: **batching is a wire optimization, not a semantic one.** Each item still passes the same script, the
same row shape, the same idempotency, the same token fence. The batch saves round trips; it does not relax a rule.

## The dives

1. **Enqueue many** (`enqueue-many`) — `enqueue_many/3`: load the script once, run an EVALSHA pipeline, read per-item
   verdicts in input order.
2. **Bulk flows** (`bulk-flows`) — `Flows.add_bulk/3`: many flows, each via `add/3`, fail-closed per flow.
3. **Batch lease extension** (`batch-lease-extension`) — `extend_locks/4`: gate every id, re-score the matching
   members under one clock read, return the `failed` list; contrast the single `extend_lock/5`.

## Framing interactive — the batch verbs

A pure lookup over the three real bulk verbs: pick a verb to read its handle, the single verb it batches, its wire
shape (one flush vs N flushes), and the shape it returns. Pure over a fixed dataset, no network. The readout is a
pure function of the verb chosen.

## Pattern & implementation

- **The pattern (Redis Patterns Applied):** pipelining sends many commands in one round trip and reads the replies in
  order, so N operations cost one network turn instead of N. `/redis-patterns/queues` teaches reliable queues, the
  near side of the bulk-admission door.
- **The implementation (echo_mq):** `enqueue_many/3` loads `@enqueue` once and pipelines the EVALSHA calls;
  `add_bulk/3` issues `add/3` per flow; `extend_locks/4` re-scores every matching member in one script — each a bulk
  twin that keeps the single verb's contract.

## Recap

A batch is the same per-item contract, pipelined: one flush, one verdict per item, in input order. The verb saves
round trips; the rule each item obeys is unchanged.

## References

### Sources
- Redis — EVALSHA (`https://redis.io/commands/evalsha/`) — load-once, run-by-SHA dispatch the bulk verbs pipeline.
- Redis — SCRIPT LOAD (`https://redis.io/commands/script-load/`) — load the script body once, before the pipeline of EVALSHA calls.
- Valkey — ZADD (`https://valkey.io/commands/zadd/`) — the sorted-set re-score the batch lease extension performs per matching member.
- Valkey — Documentation (`https://valkey.io/docs/`) — the substrate of record EchoMQ is backed by.

### Related in this course
- `/echomq/queue/batches/enqueue-many` — admit many in one flush.
- `/echomq/queue/batches/bulk-flows` — compose many flows, fail-closed per flow.
- `/echomq/queue/batches/batch-lease-extension` — extend many leases under one clock read.
- `/echomq/queue` — The Queue, the pillar this module belongs to.
- `/redis-patterns/queues` — reliable queues, the near side of the door.
