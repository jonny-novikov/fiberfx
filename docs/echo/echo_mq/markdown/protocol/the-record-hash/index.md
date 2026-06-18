# The record hash — module hub

**Route:** `/echomq/protocol/the-record-hash` · **chapter:** The Protocol · **surface:** module hub (hub + 3 dives)

> Source-of-record for the hub page. All grounding is real code in `echo/apps/echo_mq` — no `[RECONCILE]` markers.

## The fact

A job is an **entity**, and its identity is a branded id under the `JOB` namespace. Its state lives in one
Valkey **HASH** at the job key the keyspace builds: `EchoMQ.Keyspace.job_key/2` → `emq:{q}:job:<id>`. The hash is
written once, atomically, by the enqueue script:

```
redis.call('HSET', KEYS[1], 'state', 'pending', 'attempts', '0', 'payload', ARGV[2])
```

Three fields, and they are part of the **protocol**, not an implementation detail. Every runtime that speaks the wire
reads `state`, `attempts`, `payload` by those names. Rename one and the row goes invisible to every other speaker.

- **`state`** — the lifecycle position (`pending` at creation; `active`, `scheduled`, `dead` as the transitions move it).
- **`attempts`** — the retry count, and the **fencing token**: claim increments it, completion checks it.
- **`payload`** — the caller's opaque cargo; the wire never reads inside it.

Lifecycle transitions add a small, fixed set of further fields when they apply — `last_error` (set when a retry
dead-letters), `progress` (set by the progress verb), `group` (a lane member's name) — but the record a job is born
with is the three-field row above. That row is the unit of the protocol.

## The worked example (the real grounding)

`EchoMQ.Jobs.enqueue/4` is the named handle; the `@enqueue` script is the body. The host builds the two keys — the job
row (`job_key/2`) and the pending set (`queue_key/2`) — and hands them in declared; the script writes the three-field
row and the pending entry in one atomic step. The hub's framing interactive lets a reader pick each field and read what
holds it and which transition writes it.

The three-field discipline is what makes the record portable: a fixed, named shape any speaker can read, small enough
that the queue carries no second index (the id is the pending-set member, so byte order is mint order).

## The triangle — the pattern → the EchoMQ record

- **The pattern (Redis Patterns Applied):** **Data Modeling & Memory (R7)** — model an entity as one Valkey hash with
  a small, fixed field set; let the key be the address and the fields be the contract. R7 teaches the move; this is the
  system that applies it. [RECONCILE: R7 (data-modeling) is not yet built on disk — link the built `/redis-patterns`
  home + `patterns-become-protocol`, `<strong>`-name R7. Re-point to `/redis-patterns/<R7-route>` when it ships.]
- **The implementation (`echo_mq`):** `EchoMQ.Keyspace.job_key/2` addresses the row at `emq:{q}:job:<id>`; the
  `@enqueue` script fixes the field set — `state`, `attempts`, `payload` — written atomically with `HSET`.

## Recap

The job record is a three-field Valkey HASH at `emq:{q}:job:<id>` — `state` the lifecycle position, `attempts` the
retry fence and fencing token, `payload` the opaque cargo. The field names are protocol. The three dives read each:
the field set, the state-and-attempts pair, and the payload.

## References

### Sources
- Valkey — Documentation (`https://valkey.io/docs/`) — the store the record hash lives in; the substrate of record.
- Valkey — HSET (`https://valkey.io/commands/hset/`) — the single write that builds the three-field row.
- Valkey — HGET (`https://valkey.io/commands/hget/`) — how claim reads the payload back to the worker.
- Redis — Hashes (`https://redis.io/docs/data-types/hashes/`) — the hash data type the record is modeled on.

### Related in this course
- `/echomq/protocol` — the chapter this module belongs to.
- `/echomq/protocol/the-record-hash/the-hash-and-its-fields` — dive 1: the field set.
- `/echomq/protocol/the-record-hash/the-state-and-attempts` — dive 2: the lifecycle field + the fence.
- `/echomq/protocol/the-record-hash/the-payload` — dive 3: the opaque cargo.
- `/echomq/overview/the-protocol-below-the-line` — where the three-field row first appears.
