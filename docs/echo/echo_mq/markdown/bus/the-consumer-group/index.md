# The consumer group

> Route: `/echomq/bus/the-consumer-group` · Pillar II — the Bus · Module 03 (hub).
> Grounds entirely in `EchoMQ.StreamConsumer` (`echo/apps/echo_mq`). As-shipped, dark-editorial, no version
> labels, no `file:line`, no Lua (the group verbs issue direct through `EchoMQ.Connector.command/3`).

Module 02's `read/6` (`XRANGE`) is a **stateless replay**: every reader sees the whole log from `-`, and the
order theorem is the proof surface. A **consumer group** is the opposite kind of read — the **reliable,
distributed** one. Many cooperating readers share one stream; **each entry is delivered to exactly one** of
them, acknowledged, and resumable. The group remembers each consumer's un-acked backlog — the **PEL**
(Pending Entries List) — so a reader that crashes resumes where it left off **without replaying what it
already handled**.

The promise in one line: **read `>`, ack, resume.** And the cost named up front: **at-least-once, not
exactly-once.** A re-claimed entry can come back; the handler must be idempotent. The dive
`at-least-once-and-the-handler` pays that off.

This is the manuscript's reader law, B3.3 (quoted verbatim): *`EchoMQ.StreamConsumer` is the reader law: a
consumer group reads new entries, acknowledges them, and resumes where it left off, so a reader that restarts
does not replay what it has already handled.*

## The framing interactive — a group fan-out

A group over one stream key: N entries arrive; the group hands each to one consumer; each `XACK`s its own.
When a consumer crashes mid-work, its un-acked entries stay in **its** PEL — and a peer reclaims them after
they go idle. The interactive lets the reader pick a state (steady · a crash leaves a PEL · the reclaim) and
read what the group does, the Valkey verb beneath it, and the guarantee.

- **steady** — `XREADGROUP … >` hands each new entry to one consumer; on `:ok` the consumer `XACK`s it.
- **crash** — a consumer dies mid-entry; the entry is **left un-acked**, surviving in that consumer's PEL.
- **reclaim** — `XAUTOCLAIM` re-assigns the dead peer's idle entries to a live consumer; it handles them and
  `XACK`s — at-least-once, so the branded id is the dedup key.

## The three dives

1. **The group door** (`the-group-door`) — `XGROUP CREATE … MKSTREAM` on start; swallow only `BUSYGROUP`;
   the declared `:group_start` with no default; no destructive tear-down verb.
2. **Recover self, then peers** (`recover-self-then-peers`) — PEL-drain-on-(re)start recovers SELF;
   the `XAUTOCLAIM` beat recovers dead PEERS; the blocking `>` read parks on the consumer's own private lane.
3. **At-least-once and the handler** (`at-least-once-and-the-handler`) — the exact-mirror handler;
   `:ok` → `XACK`, `{:error, _}`/raise → leave un-acked; `attempts` is the `XPENDING` delivery-count; the
   order-theorem PEL exception; idempotency as the price of at-least-once.

## Redis Patterns Applied

This module is the depth behind **Redis Patterns Applied** — **R5 · Streams & Events**
(`/redis-patterns/streams-events`): the consumer-group, the PEL, and the at-least-once delivery the pattern
names, made concrete on the wire. There the pattern is the door; here is the law.

## The rest of the pillar

Module 02 (the stream log) is the writer this group reads; module 04 (time-travel) reads the log by a mint
instant; module 05 (retention & the archive) bounds it and folds what it trims to the durable floor →
**Echo Persistence** (`/echo-persistence`). Forward doors named here, built there.

## References

### Sources
- [Valkey — Introduction to Streams](https://valkey.io/topics/streams-intro/) — consumer groups, the PEL, and at-least-once delivery.
- [Valkey — XREADGROUP](https://valkey.io/commands/xreadgroup/) — the group read; `>` for new entries, `0` for the PEL.
- [Valkey — XACK](https://valkey.io/commands/xack/) — the acknowledgement that retires an entry from the PEL.
- [Valkey — Cluster specification](https://valkey.io/topics/cluster-spec/) — the `{q}` hashtag co-locates a queue and its stream on one of 16384 slots.

### Related in this course
- `/echomq/bus/the-stream-log` — the writer this group reads.
- `/echomq/bus/the-consumer-group/the-group-door` — the lazy group door.
- `/echomq/bus/the-consumer-group/recover-self-then-peers` — the two recovery mechanisms.
- `/echomq/bus/the-consumer-group/at-least-once-and-the-handler` — the handler and the idempotency cost.
- `/echomq/bus` — the pillar landing.
- `/bcs/bus` — the manuscript chapter (B3) this module realizes.
