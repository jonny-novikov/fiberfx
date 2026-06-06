# Streams Consumer Groups

Canonical Redis Streams pattern for per-logical-consumer durable delivery with ACK tracking and crash recovery. One stream key per mailbox, one consumer group per stream, consumer names bound to process identity. `XREADGROUP BLOCK … COUNT …` drives delivery; `XACK` closes the Pending Entries List; `XAUTOCLAIM` rescues entries whose owner died. This pattern is the backbone substrate for Rose Tree mailbox messaging and BullMQ job pickup.

**Primary use-case axis:** A — supervisor/worker messaging (durable fanout + ACK + recovery).
**Secondary axes:** B (human-in-loop when mailbox consumer is an operator UI), C (TUI subscribes via Go-channel bridge — see [`pubsub-fanout.md`](pubsub-fanout.md)).

## Primitive

Redis Streams with Consumer Groups (Redis 5.0+, `XAUTOCLAIM` requires 6.2+).

Core commands:

- `XADD <stream> [MAXLEN ~ N] * field1 val1 ...` — append an entry to the stream; `MAXLEN ~` performs approximate trim-on-write to bound memory. See [`mercury-design streams-event-sourcing.md`](/Users/jonny/dev/mercury-design/redis-patterns/fundamental/streams-event-sourcing.md.txt) and [`mercury-design streams-consumer-patterns.md`](/Users/jonny/dev/mercury-design/redis-patterns/fundamental/streams-consumer-patterns.md.txt).
- `XGROUP CREATE <stream> <group> $ MKSTREAM` — create a consumer group; `$` starts at end-of-stream, `0` replays history. `MKSTREAM` lazily creates the stream if absent.
- `XREADGROUP GROUP <group> <consumer> BLOCK <ms> COUNT <n> STREAMS <stream> <ID>` — read entries assigned to a consumer. `<ID>=>` returns never-delivered entries; `<ID>=0` returns this consumer's Pending Entries List history. Per [`mercury streams-consumer-patterns.md §Startup Recovery`](/Users/jonny/dev/mercury-design/redis-patterns/fundamental/streams-consumer-patterns.md.txt), the correct startup pattern is two-phase: drain `0` first, then switch to `>`.
- `XACK <stream> <group> <entry-id>` — acknowledge an entry, removing it from the Pending Entries List.
- `XAUTOCLAIM <stream> <group> <consumer> <min-idle-ms> <start> [COUNT <n>]` — atomically scan and claim entries whose owner has been idle longer than the threshold. Per [`mercury streams-consumer-patterns.md §Automated Recovery`](/Users/jonny/dev/mercury-design/redis-patterns/fundamental/streams-consumer-patterns.md.txt), run this in a background "janitor" goroutine inside every consumer.
- `XPENDING <stream> <group> - + <count> <consumer>` — introspect the Pending Entries List; returns `times-delivered` per entry for poison-pill detection.
- `XTRIM <stream> MAXLEN ~ N` — out-of-band trim; prefer `MAXLEN ~` over exact trim for O(1) macro-node-boundary cost per [`mercury streams-consumer-patterns.md §Memory Management`](/Users/jonny/dev/mercury-design/redis-patterns/fundamental/streams-consumer-patterns.md.txt).

The Pending Entries List (PEL) is a separate Radix tree per group. Unacknowledged entries remain in the PEL until explicitly `XACK`ed; this is what makes Streams durable under crash versus Pub/Sub's fire-and-forget.

## Rose Tree + FTR-009 Application

Rose Tree mailbox substrate instantiates one Stream per `<team>:<agent>` pair, with one adjacent Consumer Group per mailbox, and one consumer per reader process:

- **Stream key:** `cclin:mbox:<team>:<agent>:stream` — per [FTR-009 `mailbox-keyspace.md` §2](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/mailbox-keyspace.md).
- **Group name:** `<stream-key>:grp` — one group per mailbox enforced by [FTR-009 `mailbox-keyspace.md` §1 I-kspc-B](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/mailbox-keyspace.md).
- **Consumer name:** `<pid>-<boot_ns>` — per [FTR-009 `mailbox-keyspace.md` §1 I-kspc-C](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/mailbox-keyspace.md). Bound to process identity so that process restart creates a fresh consumer and abandoned entries become XAUTOCLAIM candidates.
- **Reader cadence:** `XREADGROUP BLOCK 5000 COUNT 32` — balances responsiveness and Redis load per [FTR-009 `reader-loop.md` §1](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/reader-loop.md).
- **XAUTOCLAIM idle threshold:** 5 minutes (`300000` ms) with a 2-minute reclaim cron per [FTR-009 `reader-loop.md` §1](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/reader-loop.md).
- **MAXLEN:** `~ 1024` per mailbox stream (FTR-009) and `~ 5000` per iteration-events stream per [FTR-009 `iteration-events.md` §6](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/iteration-events.md).
- **Poison-pill escalation:** entries with `times-delivered > 10` route to a deadletter stream per [FTR-009 `reader-loop.md` §4](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/reader-loop.md).

Dual-write atomicity: [FTR-009 `mailbox-keyspace.md` §5 bridgeEnvelope additive extension](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/mailbox-keyspace.md) uses `MULTI / XADD topic-key / XADD mailbox-key / EXEC` so the FTR-008 team topic and the per-agent mailbox stream stay in lockstep.

## echomq-go code anchor

EchoMQ ships this pattern for BullMQ job-queue semantics. The mapping is:

- Producer-side `XADD` with `MAXLEN ~`: [`../../pkg/echomq/events.go:64-91`](../../pkg/echomq/events.go) — the `EventEmitter.Emit` method issues `XAdd` with `MaxLen` and `Approx: true`.
- Consumer-side atomic pickup (BullMQ equivalent of `XREADGROUP`): [`../../pkg/echomq/worker_impl.go:76-128`](../../pkg/echomq/worker_impl.go) — `pickupJob` runs the `MoveToActive` Lua script to claim a job and set a lock token.
- Lua script driving the atomic pickup: [`../../pkg/echomq/scripts/scripts.go:10-246`](../../pkg/echomq/scripts/scripts.go) — `MoveToActive` encodes BullMQ's consumer-group equivalent: it emits `XADD event-stream * event active jobId <id> prev waiting` at [`scripts.go:146`](../../pkg/echomq/scripts/scripts.go) and also writes to the active list.
- Per-state key builder (cluster-safe via hash tags): [`../../pkg/echomq/keys.go:42-95`](../../pkg/echomq/keys.go) — `Wait/Active/Events` share slot placement when cluster mode is detected.

Note: BullMQ uses a hybrid topology (List-based `wait`/`active` + Stream-based `events`). Rose Tree mailboxes use pure Streams + Consumer Groups, matching the mercury-design canonical shape more directly.

## Antipatterns avoided

**1. Skipping two-phase startup.** A consumer that only requests `>` (new entries) leaves crashed-before-XACK entries as zombies stuck in its PEL forever. Per [`mercury streams-consumer-patterns.md §Startup Recovery`](/Users/jonny/dev/mercury-design/redis-patterns/fundamental/streams-consumer-patterns.md.txt), the correct shape is drain-PEL-with-`0` first, switch to `>` once backlog is empty.

**2. XDEL after XACK (Swiss-cheese fragmentation).** `XDEL` marks an entry deleted but does not free memory until the entire macro-node is empty. Heavy `XDEL` usage after every `XACK` creates sparse listpacks that inflate memory. Per [`mercury streams-consumer-patterns.md §Memory Management`](/Users/jonny/dev/mercury-design/redis-patterns/fundamental/streams-consumer-patterns.md.txt), the correct pattern is `XACK` for consumer-group state + `MAXLEN ~` trim-on-write for memory bounds.

**3. Poison-pill infinite loop.** Without a delivery-attempt counter + deadletter escalation, a malformed entry that consistently crashes its consumer gets reclaimed by `XAUTOCLAIM` forever, cascading across every consumer in the group. Per [`mercury streams-consumer-patterns.md §Poison Pill Handling`](/Users/jonny/dev/mercury-design/redis-patterns/fundamental/streams-consumer-patterns.md.txt), the fix is an `XPENDING` check for `times-delivered > MAX_RETRIES` followed by rerouting to a DLQ stream and ACKing the original.

**4. Blocking XREADGROUP exhausting the connection pool.** `BLOCK 0` (infinite) on all connections in a pool deadlocks any unrelated Redis work. Use `BLOCK 5000` (5s) — matches FTR-009 — or dedicate a connection per blocking consumer.

## Cross-references

FTR consumers:

- [FTR-009 `reader-loop.md`](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/reader-loop.md) — XREADGROUP state machine, XAUTOCLAIM cron
- [FTR-009 `mailbox-keyspace.md`](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/mailbox-keyspace.md) — keyspace registry, bridgeEnvelope dual-write
- [FTR-009 `iteration-events.md`](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/iteration-events.md) — consumer-group projections for iteration events
- [FTR-009 `teammate-lifecycle.md`](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/teammate-lifecycle.md) — reader shutdown on `state==retired`
- FTR-007 `dev/mcp/features/FTR-007-mcp-shim/` — mcp-shim consumes mailbox streams via this pattern
- FTR-008 `dev/mcp/features/FTR-008-cclin-echomq-pubsub/` — SendMessageBridge producer side

Sibling patterns:

- [`streams-event-sourcing.md`](streams-event-sourcing.md) — same primitive, event-sourcing projection semantics
- [`reliable-queue.md`](reliable-queue.md) — Streams successor to LMOVE-based legacy reliable queues
- [`hash-tag-colocation.md`](hash-tag-colocation.md) — required for cluster-mode multi-key Lua scripts over stream + group keys
- [`atomic-updates.md`](atomic-updates.md) — Lua-script atomicity for pickup side (see `MoveToActive` example)
- [`pubsub-fanout.md`](pubsub-fanout.md) — anti-pattern contrast; explains when Streams (not pubsub) is the right choice

Mercury-design source:

- [`fundamental/streams-consumer-patterns.md`](/Users/jonny/dev/mercury-design/redis-patterns/fundamental/streams-consumer-patterns.md.txt) — production pattern reference
- [`fundamental/streams-event-sourcing.md`](/Users/jonny/dev/mercury-design/redis-patterns/fundamental/streams-event-sourcing.md.txt) — primitive reference

## Worked example

Per-mailbox reader loop against a team `flyer-a1`, agent `mars-3`:

```bash
# Publisher side — append an entry with bounded retention
XADD cclin:mbox:flyer-a1:mars-3:stream MAXLEN \~ 1024 * \
     from director to mars-3 body '{"assignment":"W1-Iter-1"}' \
     kind direct trace_id tr-abc ts_ms 1714000000000

# Consumer side — ensure group exists (idempotent)
XGROUP CREATE cclin:mbox:flyer-a1:mars-3:stream \
              cclin:mbox:flyer-a1:mars-3:stream:grp \$ MKSTREAM

# Two-phase startup — drain PEL first, then read new
# Phase 1: replay this consumer's pending history
XREADGROUP GROUP cclin:mbox:flyer-a1:mars-3:stream:grp 12345-boot_ns_0001 \
           COUNT 32 STREAMS cclin:mbox:flyer-a1:mars-3:stream 0

# Phase 2: consume new entries
XREADGROUP GROUP cclin:mbox:flyer-a1:mars-3:stream:grp 12345-boot_ns_0001 \
           BLOCK 5000 COUNT 32 \
           STREAMS cclin:mbox:flyer-a1:mars-3:stream >

# Acknowledge on successful handler completion
XACK cclin:mbox:flyer-a1:mars-3:stream \
     cclin:mbox:flyer-a1:mars-3:stream:grp 1714000000000-0

# Janitor — rescue entries whose owner died > 5 min ago
XAUTOCLAIM cclin:mbox:flyer-a1:mars-3:stream \
           cclin:mbox:flyer-a1:mars-3:stream:grp \
           12345-boot_ns_0001 300000 0-0 COUNT 32
```

Go-side sketch (mirrors [FTR-009 `reader-loop.md` §3](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/reader-loop.md)):

```go
entries, err := r.redis.XReadGroup(ctx, &redis.XReadGroupArgs{
    Group:    r.consumerGroup(),     // "cclin:mbox:<team>:<agent>:stream:grp"
    Consumer: r.consumerName(),      // "<pid>-<boot_ns>"
    Streams:  []string{r.streamKey(), ">"},
    Count:    32,
    Block:    5 * time.Second,
}).Result()

for _, entry := range entries[0].Messages {
    if err := handle(entry); err != nil {
        continue // no XACK — entry re-delivered after XAUTOCLAIM idle threshold
    }
    r.redis.XAck(ctx, r.streamKey(), r.consumerGroup(), entry.ID)
}
```
