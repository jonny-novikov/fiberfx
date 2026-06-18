# The hash and its fields — dive

**Route:** `/echomq/protocol/the-record-hash/the-hash-and-its-fields` · **surface:** dive

> Source-of-record. All grounding is real code in `echo/apps/echo_mq` — no `[RECONCILE]` except the unbuilt R7 door.

## The fact

The job record is one Valkey **HASH**, addressed by `EchoMQ.Keyspace.job_key/2` at `emq:{q}:job:<id>`, and built by
exactly one write inside the enqueue script:

```
redis.call('HSET', KEYS[1], 'state', 'pending', 'attempts', '0', 'payload', ARGV[2])
```

The field list — `state`, `attempts`, `payload` — is the record's shape. It is fixed and named, so any speaker that
reads the row knows what each field means without a schema lookup. There is no `created_at`, no `id` field (the id is
the key), no second copy of anything: the record is the smallest row that carries the job.

## The worked example (the real grounding)

**Beat one — the named handle.** `EchoMQ.Jobs.enqueue/4` builds the keys and runs `@enqueue`. The key for the row is
`job_key/2`, which composes `queue_key(queue, "job:") <> id` — a gated builder that raises on an ill-formed id, so a
bad id never reaches the wire.

**Beat two — the script body.** `@enqueue` admits by kind, refuses a duplicate, then writes the three-field row with a
single `HSET` and inserts the id into the pending set. The `HSET` is the field set, literally.

The hero interactive lets a reader pick a field and read its name, its initial value at enqueue, and its role. The main
interactive reads a fixed sample row back field by field, the way `claim` returns it.

## The bridge — R7 data modeling → the EchoMQ record

- **The pattern:** **Data Modeling & Memory (R7)** — one entity, one hash, a small fixed field set. The key is the
  address; the fields are the contract. [RECONCILE: R7 unbuilt on disk; `<strong>`-name it, link the built
  `/redis-patterns` + `patterns-become-protocol`.]
- **The implementation:** `job_key/2` addresses the row; `@enqueue`'s `HSET` fixes its three named fields.

## Recap

A job is a Valkey HASH at `emq:{q}:job:<id>` with three named fields written by one atomic `HSET` — `state`,
`attempts`, `payload`. The names are the protocol; the shape is the contract.

## References

### Sources
- Valkey — HSET (`https://valkey.io/commands/hset/`) — the one write that builds the three-field row.
- Valkey — Documentation (`https://valkey.io/docs/`) — the substrate of record.
- Redis — Hashes (`https://redis.io/docs/data-types/hashes/`) — the data type the record is modeled on.

### Related in this course
- `/echomq/protocol/the-record-hash` — the module hub.
- `/echomq/protocol/the-record-hash/the-state-and-attempts` — the next dive.
- `/echomq/protocol` — the chapter landing.
- `/echomq/overview/the-protocol-below-the-line` — where the field set first appears.
