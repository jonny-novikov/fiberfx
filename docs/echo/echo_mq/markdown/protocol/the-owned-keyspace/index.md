# The owned keyspace

> Module hub · The Protocol · EchoMQ, In Depth · route `/echomq/protocol/the-owned-keyspace`
> Grounding: all real code in `echo/apps/echo_mq/lib/echo_mq/keyspace.ex`. No `[RECONCILE]` markers — nothing here is
> ahead of the as-built code.

## The fact

The keyspace is the part of the protocol that answers **where**. Every key EchoMQ writes is built by one module,
`EchoMQ.Keyspace`, to one grammar: `emq:{q}:<type>`. The grammar is **total** — there is no key the system can write
that does not go through the builder — and it is **braced**: the queue name sits inside `{...}` so a Valkey cluster
routes every key of one queue to one slot. A reserved base, `{emq}:`, holds the cross-queue keys (the version fence),
first-byte-disjoint from a queue's `emq:` so the two spaces can never collide.

Three things make the keyspace a protocol, not a convention:

- **The grammar is one literal.** `emq:{q}:<type>` — change the `emq:` literal or move the braces and you are speaking
  a different wire. Every speaker agrees on this string shape.
- **The braces are the hashtag.** `{q}` pins one queue's keys to one slot, so a single atomic script can touch the
  pending set, the active set, and the job row in one round — they are guaranteed co-resident.
- **The reserve is disjoint.** `{emq}:` is the core's own space. It cannot be a queue (a queue's keys start `emq:`,
  the reserve starts `{emq}:` — different first bytes), so cross-queue state and per-queue state never overlap.

## The worked example — the real surface

`EchoMQ.Keyspace` is a pure module: every public function builds or reads a key, no process, no I/O.

- `queue_key(queue, type)` → `emq:{q}:<type>` — the per-queue grammar. Built as the iodata `["emq:{", queue, "}:", type]`.
- `job_key(queue, branded)` → `emq:{q}:job:<id>` — the job row, composed from `queue_key(queue, "job:")` and a
  **validated** branded id (it raises on an invalid id — the keyspace will not address an unbranded row).
- `version_key()` → `{emq}:version` — the cross-queue fence, built from the reserve.
- `slot(key)` → `0..16383` — the cluster slot, CRC16-XMODEM over the hashtag modulo 16384.
- `hashtag(key)` → the substring inside the first `{...}`, or the whole key if there is no tag.
- `reserve(suffix)` → `{emq}:<suffix>` — any cross-queue key.

The branded id is the long part of a job key by design: 14 bytes, 3-byte namespace + 11-byte Base62 payload, gated
before the keyspace will use it.

## The bridge — pattern → implementation

- **The pattern (Redis Patterns Applied):** hash-tag co-location — wrap the shared part of a key in `{...}` so every
  member of a logical group routes to one cluster slot, where one atomic operation can touch them together.
  (`/redis-patterns/coordination/hash-tag-colocation`.)
- **The implementation (echo_mq):** `EchoMQ.Keyspace.queue_key/2` makes the brace the protocol — `emq:{q}:<type>`
  pins every key of one queue to one slot, so the Lua layer's declared-key scripts are always single-slot.

## Recap

The keyspace answers **where**. One module builds every key to one braced grammar; the brace is the cluster hashtag;
the reserve is disjoint. Three dives read it in depth: the grammar, the hashtag and the slot it computes, and the
reserve.

## References

### Sources
- Valkey — Documentation — `https://valkey.io/docs/` — the store the keys are written to; the substrate of record.
- Redis — Keyspace & cluster hash tags — `https://redis.io/docs/` — cluster key routing by the hashtag inside `{...}`.
- Valkey — Cluster specification — `https://valkey.io/topics/cluster-spec/` — the `{hashtag}`→hash-slot routing the
  per-queue hashtag is built for: every key of a queue on one slot, where a multi-key script is legal.

### Related in this course
- `/echomq/protocol` — the chapter this module belongs to.
- `/echomq/protocol/the-owned-keyspace/the-braced-grammar` — dive 1.
- `/echomq/protocol/the-owned-keyspace/the-hashtag-and-the-slot` — dive 2.
- `/echomq/protocol/the-owned-keyspace/the-reserve` — dive 3.
- `/redis-patterns/coordination/hash-tag-colocation` — the near side of the door.
