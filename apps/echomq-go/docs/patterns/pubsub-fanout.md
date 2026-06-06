# Pub/Sub Fanout

Redis PUBLISH/SUBSCRIBE delivers messages to all currently-connected subscribers at the moment of publish. Delivery is best-effort, stateless, and fire-and-forget: subscribers that are disconnected during publish receive nothing, there is no acknowledgement, and there is no replay. This pattern documents the Redis primitive alongside its in-process cousin — the Go-channel dispatcher bridge — and makes the distinction explicit so authors reach for Streams when durability matters.

**Primary use-case axis:** C — TUI live-update broadcasting (in-process variant via Go-channel bridge).
**Secondary axes:** none; explicitly N/A on axes A, B, D per [`adr-001-pattern-taxonomy.md` §3](../architecture/adr-001-pattern-taxonomy.md).

## Primitive

Two variants; the pattern names both and marks each for its correct domain.

**Redis cross-process pubsub:**

- `PUBLISH <channel> <payload>` — broadcast a payload to every currently-subscribed client; returns the subscriber count that received it. Per [`mercury community/pubsub.md §Basic Operations`](/Users/jonny/dev/mercury-design/redis-patterns/community/pubsub.md.txt).
- `SUBSCRIBE <channel> [channel ...]` — register for direct-channel messages. Per [`mercury community/pubsub.md §Basic Operations`](/Users/jonny/dev/mercury-design/redis-patterns/community/pubsub.md.txt), subscribed clients enter a special mode that only accepts pubsub management + `PING`/`QUIT`.
- `PSUBSCRIBE <pattern>` — register for glob-pattern matches (e.g., `user:*:notifications`). Per [`mercury community/pubsub.md §Pattern Subscriptions`](/Users/jonny/dev/mercury-design/redis-patterns/community/pubsub.md.txt).
- `UNSUBSCRIBE` / `PUNSUBSCRIBE` — deregister.

Semantics per [`mercury community/pubsub.md §Fire-and-Forget Nature`](/Users/jonny/dev/mercury-design/redis-patterns/community/pubsub.md.txt):

1. No persistence — messages exist only during the `PUBLISH` call.
2. No delivery guarantee — if no subscribers are connected, the message is lost.
3. No acknowledgement — the publisher only learns the live subscriber count, not confirmation of handling.
4. No replay — disconnected subscribers cannot backfill.

**In-process Go-channel dispatcher bridge:**

The Rose Tree TUI uses a Go goroutine to translate `chan<- MailboxEvent` into `tea.Program.Send` commands inside the same process. This is NOT Redis pubsub — it is a zero-copy in-memory fanout across Elm-architecture reducers. It is durable within the process lifetime (the upstream `streams-consumer-groups` pattern handles cross-process durability); it loses data only on process exit, at which point the consumer group's PEL preserves unacked entries for recovery. See [FTR-009 `tui-panels.md` §1](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/tui-panels.md) for the dispatcher architecture.

## Rose Tree + FTR-009 Application

FTR-009 uses the **Go-channel variant** for TUI live updates, not Redis pubsub:

- **Source:** `internal/mailbox.Reader.Run(ctx, out chan<- MailboxEvent)` emits decoded mailbox entries on a Go channel — see [FTR-009 `reader-loop.md` §3](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/reader-loop.md).
- **Bridge:** a dispatcher goroutine reads the channel and calls `tea.Program.Send` with a `MailboxEventMsg` — see [FTR-009 `tui-panels.md` §1](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/tui-panels.md).
- **Sinks:** four Bubble Tea panels (`Inbox`, `Progress`, `Supervise`, `Iterations`) each apply the message in their `Update` function and re-render their slice of state — [FTR-009 `tui-panels.md` §3-§6](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/tui-panels.md).

Reason for Go-channel over Redis pubsub in FTR-009:

1. Durability requirement — the TUI needs every mailbox entry, not a subset of entries delivered while connected. Redis pubsub loses data during reader reconnect.
2. Same-process fanout — publisher (reader loop) and subscribers (TUI panels) run in the same cclin-server process. The Go-channel + Bubble Tea message bus is the idiomatic shape for intra-process fanout.
3. Backpressure — `chan<- MailboxEvent` with a bounded buffer gives natural backpressure; Redis pubsub drops unbuffered messages at the publisher side when subscribers are slow.

**Where Redis pubsub IS the right choice (future FTRs, out of scope for H1):**

- **Cross-process cache invalidation** — the canonical pubsub use case. A database update publishes to `cache:invalidate`; every application server subscribes and drops its local cache entry. Loss tolerance: if a server was disconnected, a stale cache entry persists until TTL expiry — acceptable for ephemeral caches.
- **Session invalidation / logout broadcast** — per [`mercury community/session-management.md §Real-Time Session Invalidation`](/Users/jonny/dev/mercury-design/redis-patterns/community/session-management.md.txt) and [`session-management.md`](session-management.md).
- **FTR-018 web dashboard — multi-process TUI broadcast** — pushing iteration-event state updates to browser WebSockets via a server-side fanout. See [FTR-019 `architecture/overview.md` §6](../../../dev/mcp/features/FTR-019-echomq-pattern-library/architecture/overview.md) for the forward-pointer.
- **Keyspace notifications** — a structured pubsub use case; see [`keyspace-notifications.md`](keyspace-notifications.md) for the specialized variant.

## echomq-go code anchor

FORWARD-REF: FTR-009

Current echomq-go (BullMQ v5.62.0 pinned) does not use Redis pubsub for job-lifecycle fanout — BullMQ uses Streams (`events` stream per queue) for observability, not pubsub. The Go-channel dispatcher bridge variant of this pattern lands with FTR-009 W1-Iter-2 (TUI 4-tab implementation).

The closest echomq-go primitive is the event-emission path at [`../../pkg/echomq/events.go:64-91`](../../pkg/echomq/events.go), which uses Streams (not pubsub) — that is the correct choice for BullMQ's "observer subscribed during downtime must catch up" requirement.

## Antipatterns avoided

**1. Redis pubsub for durable mailbox delivery.** A mailbox stream for an agent needs every message, not just those arriving while the consumer happens to be connected. Redis pubsub silently drops messages during consumer disconnects. Per [`mercury community/pubsub.md §Fire-and-Forget Nature`](/Users/jonny/dev/mercury-design/redis-patterns/community/pubsub.md.txt), the correct choice for durable delivery is Streams + consumer groups — see [`streams-consumer-groups.md`](streams-consumer-groups.md). FTR-009 explicitly rejects this antipattern per [FTR-009 `tui-panels.md` §1](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/tui-panels.md).

**2. Subscribing on a shared connection in a connection pool.** Per [`mercury community/pubsub.md §Connection Considerations`](/Users/jonny/dev/mercury-design/redis-patterns/community/pubsub.md.txt), a subscribed Redis client can only execute `SUBSCRIBE`/`UNSUBSCRIBE`/`PING`/`QUIT` — regular commands on the same connection return errors. Sharing a pool connection between pubsub and regular work deadlocks both. Dedicate a connection (or connection pool) to pubsub traffic.

**3. Assuming `PUBLISH` return value means "delivered".** `PUBLISH` returns the number of subscribers that received the publish call, not the count that successfully processed it. A subscriber can disconnect mid-handler; the publisher never learns. If acknowledgement matters, the pattern is wrong — use Streams.

**4. Pattern subscriptions with overlapping globs.** `PSUBSCRIBE user:*:notifications` and `PSUBSCRIBE user:123:*` both match `user:123:notifications` and a single publish will dispatch twice through both subscriptions, doubling handler cost. Curate globs to be disjoint or dedupe in the subscriber.

## Cross-references

FTR consumers:

- [FTR-009 `tui-panels.md`](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/tui-panels.md) — Go-channel dispatcher, NOT Redis pubsub
- [FTR-009 `reader-loop.md`](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/reader-loop.md) — upstream source of mailbox events
- FTR-018 (future) — web dashboard cross-process broadcast (legitimate Redis pubsub use)
- FTR-016 (future) — keyspace-notifications cluster-mode variant (see [`keyspace-notifications.md`](keyspace-notifications.md))

Sibling patterns:

- [`streams-consumer-groups.md`](streams-consumer-groups.md) — durable delivery alternative when pubsub's fire-and-forget is unacceptable
- [`streams-event-sourcing.md`](streams-event-sourcing.md) — durable broadcast fanout via consumer groups + replay
- [`keyspace-notifications.md`](keyspace-notifications.md) — specialized pubsub variant with Redis-generated events
- [`session-management.md`](session-management.md) — legitimate pubsub use case for session invalidation

Mercury-design source:

- [`community/pubsub.md`](/Users/jonny/dev/mercury-design/redis-patterns/community/pubsub.md.txt) — primitive reference + fire-and-forget discipline

## Worked example

Go-channel dispatcher bridge (the FTR-009 variant):

```go
// Reader side — publishes decoded mailbox entries on a Go channel
out := make(chan MailboxEvent, 32)
go reader.Run(ctx, out)

// Bridge goroutine — fans channel values into Bubble Tea messages
go func() {
    for evt := range out {
        if evt.Kind == "" { continue }
        teaProgram.Send(MailboxEventMsg{Event: evt})
    }
}()

// Panel Update functions — each applies the same message to its slice of state
func (m inboxModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
    switch t := msg.(type) {
    case MailboxEventMsg:
        m.entries = append(m.entries, t.Event)
        if t.Event.Kind == "direct" || t.Event.Kind == "broadcast" {
            m.unread++
        }
    }
    return m, nil
}
```

Redis cross-process pubsub (future FTR-018 use case; NOT used in FTR-009):

```bash
# Publisher — broadcast cache-invalidation to all application servers
PUBLISH cache:invalidate "user:123"

# Subscriber — receives messages until disconnect
SUBSCRIBE cache:invalidate
# 1) "subscribe"
# 2) "cache:invalidate"
# 3) (integer) 1
# 1) "message"
# 2) "cache:invalidate"
# 3) "user:123"

# Pattern subscription for a family of channels
PSUBSCRIBE user:*:notifications
# Receives messages published to user:123:notifications, user:456:notifications, etc.
```

Go-side cross-process pubsub (reference for FTR-018 future work):

```go
pubsub := client.Subscribe(ctx, "cache:invalidate")
defer pubsub.Close()

ch := pubsub.Channel()
for msg := range ch {
    localCache.Evict(msg.Payload)
}
```
