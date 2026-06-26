# R5.02 · Stream consumer patterns

> Route: `/redis-patterns/streams-events/streams-consumer-patterns` · module hub
> Grounding: `echo/apps/echo_mq/lib/echo_mq/stream_consumer.ex` · `stream.ex` · `stream_retention.ex`,
> with `EchoStore.StreamArchive` the durable floor and codemojex the consumer.

Implement reliable message processing with Valkey Streams consumer groups, handling failure recovery,
poison pills, and memory management — the operational patterns that production systems require beyond basic
`XREADGROUP` usage.

A stream is an **immutable log**, not a work queue. Where a list read is destructive — `RPOP` removes the
item, and a crash before the work finishes loses it — a stream read is non-destructive: the entry stays until
a reader acknowledges it. The queue state (pending versus handled) lives in consumer-group metadata, not in
the data. That single shift is what makes the four moves of this module possible: **block** for new entries
without busy-polling, **resume** an un-acked backlog after a crash, **trim** a log that would otherwise grow
without bound, and **archive** what is trimmed so history is bounded in memory but not lost.

EchoMQ's Stream Tier is the worked form of these moves. `EchoMQ.StreamConsumer` is the reader law — a
consumer group reads new entries, acknowledges them, and resumes where it left off, so a reader that restarts
does not replay what it has already handled. `EchoMQ.Stream.trim/4` bounds the log by length or age, the
opt-in `EchoMQ.StreamRetention` driver re-applies a declared policy on its own beat, and what is trimmed folds
into the durable Graft floor through `EchoStore.StreamArchive`.

## The mental model problem

Most stream adoption failures stem from treating a stream like a list. The differences are not cosmetic:

| Behaviour | List (`LPUSH` / `RPOP`) | Stream (`XADD` / `XREADGROUP`) |
|---|---|---|
| Read effect | destructive — removes the item | non-destructive — moves a cursor |
| Failure handling | data lost if the consumer crashes | data stays until `XACK`ed |
| Cleanup | automatic on read | explicit (`XTRIM`) |

In EchoMQ the two shapes are deliberately separate code paths, not a mode on one. The job `EchoMQ.Consumer`
**claims** a job and **completes** it once — the work leaves the queue. The `EchoMQ.StreamConsumer` reads a
log many readers consume at their own pace: a different claim path (`XREADGROUP` group read, not a lease pop)
and a different settle (`XACK` / leave-un-acked, not complete / retry). A queue is for work claimed and
completed once; a stream is the append-only log beside it.

## The pending entries list

When a consumer reads via `XREADGROUP`, each delivered entry enters that consumer's pending entries list
(the PEL). It stays there until the consumer acknowledges it with `XACK`. The PEL is the per-consumer record
of "delivered to me, not yet settled" — it is what survives a crash, and it is what `XAUTOCLAIM` reads to
recover a dead peer.

EchoMQ rides the PEL directly. On `:ok` the entry is `XACK`ed and retires from the PEL; on `{:error, reason}`
(or a raising handler, which the loop converts to `{:error, reason}` and survives) it is **left un-acked** —
it survives in the PEL and is re-delivered. That is the at-least-once posture stated as one rule: the only way
an entry leaves the PEL is a handler that returns `:ok`.

## The startup recovery pattern

A critical anti-pattern is a consumer that only ever requests `>` (new entries). If it crashes after a
delivery but before the `XACK`, those entries become zombies — stuck in the PEL, never re-read, because `>`
only ever hands back entries newer than the group's last-delivered id.

The correct pattern is two-phase: on (re)start, first drain the consumer's own PEL by reading from cursor `0`
to exhaustion, settling each; only then switch to `>` for new entries. Reading id `0` queries the PEL for
entries already assigned to **this** consumer name.

EchoMQ builds this into the loop. `EchoMQ.StreamConsumer` drains its own PEL first
(`XREADGROUP GROUP g <self> ... 0`, the un-acked backlog keyed to its own consumer name) to exhaustion, then
switches to `>`. A crashed consumer that restarts with the same name recovers its own held work the instant it
restarts; a clean cold start has an empty PEL — the `0` read returns nothing — so one code path covers both.

## Automated recovery with XAUTOCLAIM

The startup drain recovers a consumer that **comes back**. A consumer that dies permanently never restarts, so
its PEL is never self-drained — its entries are orphaned. Recovering them is a second, complementary
mechanism: other consumers must claim what a dead peer left.

`XAUTOCLAIM <key> <group> <self> <min-idle-ms> <cursor>` atomically scans and re-assigns to the caller every
entry idle past the threshold. Run it on a beat in every consumer and the result is decentralised
work-stealing: each consumer picks up the slack from failed peers, with no coordinator.

EchoMQ's loop reclaims dead peers on every beat via `XAUTOCLAIM <key> <group> <self> <min_idle_ms> 0`, where
`:min_idle_ms` (default `30_000`) is the single tunable for "how long before a dead peer's work is
re-delivered." The idle threshold is evaluated server-side against `XPENDING` idle time, never against a host
clock — the clock that wrote the idle time and the clock that reads it are one clock.

## The order theorem under a group

New entries arrive in mint order — the writer mints monotone `EVT` ids, so `XREADGROUP ... >` hands them back
in append order, and the writer's order theorem is untouched. But a **re-claimed** entry — recovered by
`XAUTOCLAIM` or a PEL drain after newer entries were already handled — returns to a consumer **out of**
real-time delivery order: its branded id is older (lower) than entries already handled.

This is the irreducible cost of at-least-once; exactly-once is not claimed. The consequence is a hard rule:
the handler must be **idempotent**. Handling the same entry twice, or an older entry after a newer one, must
be safe — and the branded id is the dedup key, the BCS newer-wins discipline.

## Poison pill handling

A poison pill is an entry that consistently crashes whatever reads it — malformed fields, a missing key. Left
unguarded it is an infinite loop: consumer A reads it and dies, the entry goes idle, consumer B auto-claims it
and dies, and so on until every consumer is dead. Decentralised work-stealing turns a single bad entry into a
fleet-wide outage.

The guard is a delivery count and a threshold. `XPENDING` carries each entry's `times-delivered`; past a
maximum, route the entry to a dead-letter destination and acknowledge it rather than handle it again. A stream
has no built-in dead-letter queue — this is application logic.

EchoMQ **specifies** the count so the guard can be written correctly: the handler map carries
`attempts` — the `XPENDING` per-entry delivery count (how many times **this** entry has been delivered), not a
handler-failure count. That distinction is load-bearing: a poison-threshold of `attempts >= N` calibrates
against deliveries, the quantity that actually grows each time a pill is re-claimed.

## Memory management — XTRIM, not XDEL

The tempting cleanup is to `XDEL` an entry after `XACK`ing it. It is harmful. A stream stores entries in a
radix tree of macro-nodes (listpacks); `XDEL` marks an entry deleted but does not free memory until the entire
macro-node is empty, so heavy `XDEL` use leaves "Swiss cheese" fragmentation.

The correct pattern keeps the two concerns apart: `XACK` marks an entry handled (consumer-group state only),
and `XTRIM` enforces a retention policy (frees memory by whole macro-nodes). `XADD ... MAXLEN ~ N` trims on
write; `XTRIM ... MAXLEN ~ N` trims periodically. The `~` selects approximate trimming — Valkey trims whole
macro-nodes rather than to an exact count, cutting CPU sharply. `MINID ~ <ms>-0` trims by time instead of
count, removing entries older than an id.

EchoMQ exposes exactly this as `EchoMQ.Stream.trim/4`. `{:maxlen, count, approx?}` issues
`XTRIM <key> MAXLEN [~|=] <count>` — keep the `count` newest, remove the older; `{:minid, dt, approx?}` issues
`XTRIM <key> MINID [~|=] "<ms>-0"`, the floor derived from the branded mint instant, never a raw snowflake to
the wire. `approx?` true selects `~` — the safe default: it may under-trim but can **never** over-trim, so a
trim can never delete inside the declared window. The opt-in `EchoMQ.StreamRetention` driver re-applies a
declared policy on its own beat, decoupled from consumer liveness: a stream nobody drains still trims, because
bounded memory is a safety property and "a consumer is up" is a liveness fact — coupling the two is a
silent-no-op the design refuses.

What is trimmed is not lost. `EchoStore.StreamArchive.fold/3` folds trimmed segments into the durable Graft
floor — deep history without resident memory, readable beside the live tail through a merge-read split on a
watermark. The archive frontier doors out to `/echo-persistence`, where the durability dial is taught in full.

## Blocking read pitfalls

A blocking `XREADGROUP` can exhaust a connection pool. If ten worker threads each issue
`XREADGROUP ... BLOCK 5000` over a pool of ten connections, all ten connections are parked — any other code
needing the store, even a simple `GET`, waits forever. The fixes are a dedicated connection for each blocking
consumer, shorter block times rather than an infinite `BLOCK 0`, and a server-side `BLOCK` timeout shorter than
the client socket timeout.

EchoMQ takes the dedicated-connection fix as a law. The blocking `XREADGROUP ... BLOCK <beat_ms>` parks on the
consumer's **own** private connector lane — the same "blocking verbs get their own lane" rule the job consumer
follows for `BLPOP` — so the single-owner socket the rest of the system shares is never stalled. The block time
is the `:beat_ms` cadence (default `1_000`), and the command timeout is `beat_ms` plus a buffer so the `BLOCK`
returns first.

## Lag monitoring

Lag in a stream has two faces. **Ingestion lag** is the distance between the newest stream id and the group's
last-delivered id — how far behind the readers are. **Processing lag** is the PEL size — entries delivered but
not yet acknowledged. Low ingestion lag with a high PEL points at a processing bottleneck or `XACK` failures,
not a delivery problem; `XINFO GROUPS` reads both. EchoMQ's PEL-drain-first loop keeps the steady-state PEL
small: an entry leaves it only on a `:ok` ack, and a restart drains the backlog before reading anything new.

## The pattern, applied — the codemojex activity feed

codemojex (`echo/apps/codemojex`) is the worked consumer: a Telegram emoji-guessing game on the same stack. A
game round appends an entry to its activity stream on the `{q}` queue — a guess scored, a round opened — and a
feed reader joins the consumer group to render the live timeline. When the reader restarts, it drains its own
PEL first, so the feed never double-renders an event it already showed. When the stream grows past the declared
window, `EchoMQ.StreamRetention` trims it on its beat, and `EchoStore.StreamArchive` folds the trimmed segments
into the Graft floor — the full round history stays readable for an audit without holding it all in memory.

## The three dives

- **R5.02.1 · The blocking read** — `XREAD BLOCK` long-poll versus a busy-poll, and why the blocking verb rides
  a dedicated connection so it never stalls the shared socket.
- **R5.02.2 · Consumer groups** — `XREADGROUP` / `XACK`, at-least-once with resume, and `EchoMQ.StreamConsumer`
  as the reader law: drain own PEL, read `>`, reclaim dead peers.
- **R5.02.3 · MAXLEN trimming** — `MAXLEN ~` / `MINID` retention as a policy, and how the archive catches what
  is trimmed and folds it to the durable floor.

## References

### Sources

- [Valkey — Introduction to Streams](https://valkey.io/topics/streams-intro/) — the append-only log and the
  consumer groups the tier is built on.
- [Valkey — XREADGROUP](https://valkey.io/commands/xreadgroup/) — the group read that delivers new entries and
  drains a consumer's PEL from cursor `0`.
- [Valkey — XACK](https://valkey.io/commands/xack/) — the acknowledgement that retires an entry from the PEL;
  no ack means re-delivery.
- [Valkey — XTRIM](https://valkey.io/commands/xtrim/) — `MAXLEN ~` and `MINID` retention; the `~` trims whole
  macro-nodes.
- [Valkey — Cluster specification](https://valkey.io/topics/cluster-spec/) — the `{q}` hash tag forces a
  queue's stream keys onto one of 16384 hash slots.
- [Kreps — The Log: What every software engineer should know](https://engineering.linkedin.com/distributed-systems/log-what-every-software-engineer-should-know-about-real-time-datas-unifying)
  — the log as the shared abstraction beneath a stream.

### Related in this course

- [R5 · Streams & Events](/redis-patterns/streams-events) — the chapter.
- [R5.02.1 · The blocking read](/redis-patterns/streams-events/streams-consumer-patterns/the-blocking-read) —
  the long-poll on a dedicated lane.
- [R5.02.2 · Consumer groups](/redis-patterns/streams-events/streams-consumer-patterns/consumer-groups) —
  at-least-once with resume.
- [R5.02.3 · MAXLEN trimming](/redis-patterns/streams-events/streams-consumer-patterns/maxlen-trimming) —
  retention as policy, and the archive.
- [/echomq/bus](/echomq/bus) — the EchoMQ Bus pillar: the retained replayable log in depth.
- [/echo-persistence](/echo-persistence) — the durability dial a trimmed segment folds onto.
