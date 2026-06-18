# The immutable line — dive

> Route: `/echomq/protocol/immutability-and-branded-ids/the-immutable-line` · surface: **dive**.
> Grounding: **real code** in `echo/apps/echo_mq`. **No `[RECONCILE]` markers.**

## The fact

Below the language line are two layers — **L1**, the keys and the field names, and **L2**, the atomic Lua. They are
fixed. Not by policy but by consequence: every speaker of the wire reads the same key at the same address and the same
named fields out of the same row. Rename one of them in one speaker and that speaker writes a row no other speaker can
find. The data is not lost — it is unfindable, or unreadable, across the wire.

This is the deepest reason the three pillars interoperate and any runtime can be a peer: the agreement is the keys and
the scripts, and an agreement only holds if both sides hold it byte-for-byte. The course's earlier dive drew this line
on a stack diagram; this dive deepens it on the **real record** — the exact key the keyspace builds and the exact three
fields the `@enqueue` script writes — and shows precisely who breaks for each thing you might change.

## The worked example (real grounding)

`EchoMQ.Keyspace.queue_key/2` builds the L1 address; `EchoMQ.Jobs`'s `@enqueue` writes the L1 fields. Both are extracts
on the page.

The address (L1):

```elixir
# echo_mq — EchoMQ.Keyspace
# The literal "emq:", the queue name wrapped in braces, then the type suffix.
# Every speaker composes the exact same bytes for the same {queue, type}.
def queue_key(queue, type) when is_binary(queue) and is_binary(type),
  do: IO.iodata_to_binary(["emq:{", queue, "}:", type])
```

The fields (L1), written by the `@enqueue` script (L2):

```lua
-- the three-field row, written atomically — state, attempts, payload
-- These three names ARE the contract. A reader looks up exactly these.
redis.call('HSET', KEYS[1], 'state', 'pending', 'attempts', '0', 'payload', ARGV[2])
```

Three fields, three fixed names: `state` (the lifecycle position), `attempts` (the retry fence), `payload` (the opaque
caller bytes). A reader anywhere on the wire reads exactly `state`, `attempts`, `payload`. Change `payload` to `data` in
one runtime's `@enqueue` and that runtime writes a field no other reader looks up; change the literal `emq:` and its
rows land in a keyspace no other reader scans.

What is NOT below the line: the L4 verb. `EchoMQ.Jobs.enqueue/4` is a name above the line — rename it and nothing on
the wire moves, because the keys it builds and the script it runs are unchanged.

## The interactives

1. **Hero — change one thing, who can still read the job?** Pick a change below the line (rename the key prefix, rename
   the `payload` field, drop a key from the `KEYS[]` contract) or above it (rename the L4 verb) and read the verdict
   over three fixed speakers: a below-the-line change desyncs the changer from the rest; an above-the-line change
   touches nothing on the wire. Pure function over a fixed model, live `.geo-readout`, an `<svg>` of three speakers
   reading one row.
2. **Main — the layer ledger.** Pick a layer (L1 keys, L1 fields, L2 Lua, L3 executor, L4 API) and read whether it is
   below or above the line and what "fixed" or "free" means for it concretely. Pure lookup over the same five-layer
   model, with a live readout.

## The bridge (pattern → implementation)

- **The pattern (Redis Patterns Applied):** a Redis convention becomes a protocol when the agreement — the keys plus
  the atomic scripts — is pushed below the language line and held fixed. `/redis-patterns/coordination` teaches the
  atomic, one-slot move that this fixity rests on.
- **The implementation (echo_mq):** `EchoMQ.Keyspace.queue_key/2` fixes the address `emq:{q}:<type>`; the `@enqueue`
  script fixes the row with the three named fields and every key declared in `KEYS[]`. L1 and L2, shared and fixed.

## Recap + take

The line is the keys and the Lua, and it is fixed because an agreement only holds when both sides hold it byte-for-byte.
A change below the line makes the row invisible or unreadable to every other speaker; a change above the line — the L4
verb — changes nothing on the wire. **Take:** below the line is the contract, above it is the code; fixity below the
line is what lets any runtime be a peer.

## References

### Sources
- Redis — Keyspace & hash tags (`https://redis.io/docs/`) — the L1 routing the address relies on.
- Valkey — HSET (`https://valkey.io/commands/hset/`) — the hash write that lays down the three fixed fields.
- Valkey — Documentation (`https://valkey.io/docs/`) — the substrate of record.

### Related in this course
- `/echomq/overview/the-protocol-below-the-line` — the line drawn on the layer stack.
- `/echomq/protocol/the-record-hash` — the record and its fields in depth.
- `/echomq/protocol/immutability-and-branded-ids/the-branded-id-gate` — the next dive: identity gated in Lua.
- `/redis-patterns/coordination` — atomicity and co-location, the near side of the door.
