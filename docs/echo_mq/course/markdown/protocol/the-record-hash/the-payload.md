# The payload — dive

**Route:** `/echomq/protocol/the-record-hash/the-payload` · **surface:** dive

> Source-of-record. All grounding is real code in `echo/apps/echo_mq` — no `[RECONCILE]` except the unbuilt R7 door.

## The fact

The third field, `payload`, is the caller's data, and the wire never reads inside it. Enqueue takes it as `ARGV[2]`
and stores it verbatim:

```
redis.call('HSET', KEYS[1], 'state', 'pending', 'attempts', '0', 'payload', ARGV[2])
```

Claim hands it back unchanged:

```
return {id, redis.call('HGET', jk, 'payload'), att}
```

Between those two points the protocol does nothing with it. The payload is **opaque cargo** — the system addresses it,
moves it, and delivers it, but never parses, validates, or branches on its contents. That is deliberate. Because the
wire holds no opinion about the bytes, the same protocol carries any job for any consumer, in any encoding the caller
and the worker agree on. The cargo law: the bus carries; the caller decides what.

`enqueue/4` guards that the payload is a binary (`when … and is_binary(payload)`), so the field always holds a string —
but the contents are the caller's. The wire's only contract is the three field names and the value of `state` and
`attempts`; `payload` is a passthrough.

## The worked example (the real grounding)

**Beat one — the named handle.** `EchoMQ.Jobs.enqueue/4` requires `is_binary(payload)` and passes it as `ARGV[2]`.
**Beat two — the body** stores it with the `HSET`, untouched. On the read side, `@claim` returns `HGET payload`
verbatim to the worker. The round trip is store-then-return; the wire reads neither end.

The hero interactive enqueues a few sample payloads (JSON, a plain string, a number) and shows each stored and returned
byte-for-byte — same in, same out. The main interactive contrasts an opaque field (the wire passes it through) with a
protocol field (the wire reads `state`/`attempts`), showing which the system interprets.

## The bridge — R7 data modeling → the EchoMQ record

- **The pattern:** **Data Modeling & Memory (R7)** — keep the payload opaque to the store; let the value be the
  caller's and the key/the control fields be the system's. [RECONCILE: R7 unbuilt on disk; `<strong>`-name it.]
- **The implementation:** `payload` is `ARGV[2]` stored verbatim by `@enqueue` and returned verbatim by `@claim`; the
  wire reads only `state` and `attempts`.

## Recap

`payload` is the caller's opaque cargo — stored verbatim by `@enqueue`, returned verbatim by `@claim`, never read by
the wire. The protocol interprets the key and the control fields; the value is the caller's. That is what lets one wire
carry any job.

## References

### Sources
- Valkey — HGET (`https://valkey.io/commands/hget/`) — how claim returns the payload verbatim.
- Valkey — HSET (`https://valkey.io/commands/hset/`) — the write that stores the payload as the third field.
- Valkey — Documentation (`https://valkey.io/docs/`) — the substrate of record.

### Related in this course
- `/echomq/protocol/the-record-hash` — the module hub.
- `/echomq/protocol/the-record-hash/the-state-and-attempts` — the previous dive.
- `/echomq/protocol` — the chapter landing.
- `/echomq/overview/the-protocol-below-the-line` — the line below which the field set is fixed.
