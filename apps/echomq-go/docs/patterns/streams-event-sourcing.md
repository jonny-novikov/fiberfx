# Streams Event Sourcing

Append-only event logs on Redis Streams where services append immutable facts and projections derive state. Retention is bounded by `MAXLEN ~ N` approximate trimming. Dedup lives in a sidecar LRU keyed by a caller-supplied event id. This is the canonical substrate for workflow-relevant audit trails — FTR-009's iteration events, BullMQ's job-lifecycle events, and any future Rose Tree replay-capable consumer.

**Primary use-case axis:** A — supervisor/worker messaging (event audit trail).
**Secondary axes:** B (important/actionable events mirror to operator inbox), C (TUI Iterations tab projects from event stream).

## Primitive

Redis Streams (5.0+) as an append-only log with bounded retention. Core commands:

- `XADD <stream> [MAXLEN ~ N] * field1 val1 field2 val2 ...` — append an entry; the `*` yields an auto-generated millisecond-precision time-ordered id. `MAXLEN ~` enables approximate trim-on-write, which Redis implements by deleting whole macro-nodes at insertion time rather than exact-count enforcement. Per [`mercury streams-event-sourcing.md`](/Users/jonny/dev/mercury-design/redis-patterns/fundamental/streams-event-sourcing.md.txt), approximate trimming is dramatically cheaper than exact.
- `XRANGE <stream> <start> <end> [COUNT <n>]` — read a range. `XRANGE <key> - +` is the full-stream replay. `XRANGE <key> (<id> +` starts after a known id.
- `XREAD [BLOCK <ms>] STREAMS <stream> <id>` — non-consumer-group read; `$` means "only future entries", `0` means from the start.
- `XTRIM <stream> MAXLEN ~ N` — out-of-band retention enforcement. Prefer the inline `MAXLEN ~` on `XADD` so trimming costs are amortized per-write instead of per-cron-tick.
- `XTRIM <stream> MINID ~ <ms-id>` — time-based retention (Redis 6.2+); trim entries older than a timestamp id.
- `XINFO STREAM <key>` / `XINFO GROUPS <key>` — introspection: length, last-generated-id, radix-tree node count, group lag.

The projection model: services write events with `XADD`; consumers (groups for work-distribution, plain `XREAD` for catch-up) fold events into derived state. The stream itself is the source of truth; state is derived.

Retention math: `MAXLEN ~ 5000` at 0.1 msg/s sustained holds approximately 14 hours of replay depth — the canonical FTR-009 iteration-events window per [FTR-009 `iteration-events.md` §6](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/iteration-events.md).

## Rose Tree + FTR-009 Application

FTR-009 iteration-events are the most direct implementation of this pattern inside CCLIN:

- **Canonical envelope** — 13 required fields (`team, kind, agent, archetype, iteration_id, phase, grade, grade_rubric, artifacts, trace_id, ts, notify_class, notify_text`) plus a `extensions` additive map. See [FTR-009 `iteration-events.md` §2](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/iteration-events.md).
- **Phase sub-taxonomy** — 21 phase enum values (`feature_bootstrap`, `wave_started`, `grade`, `remediation_started`, `teammate_retired`, ...) drive projections. See [FTR-009 `iteration-events.md` §3](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/iteration-events.md).
- **Append-only** — events are published via the `SendMessageBridge` producer with outer `Kind="iteration_event"` and inner JSON-serialized `IterationEvent`. Publishers MUST NOT mutate or delete prior events; every correction is a new append. See [FTR-009 `iteration-events.md` §4](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/iteration-events.md).
- **Projections** — the TUI Iterations tab folds events into a wave × agent grid; the Pluto supervise cron folds `stale_detected` events into `cclin:stale:level{1,2}` ZSETs; the lifecycle router folds `grade` events into the 6-state teammate state machine.
- **Dedup** — `extensions.event_id` carries a UUID v4 that consumers use to drop duplicates on replay. See [FTR-009 `iteration-events.md` §8](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/iteration-events.md).
- **Retention** — `MAXLEN ~ 5000` on iteration-event streams, approximate trim-on-write, consumed at TUI boot as `XRANGE <stream> - + COUNT 100` to backfill the most-recent view without replaying the full window.
- **Replay under churn** — Mars teammate restart reads the consumer-group PEL first (via the sibling [`streams-consumer-groups.md`](streams-consumer-groups.md) pattern) to recover events that were in flight at crash time, then tails `>` for new entries.

Iteration events and mailbox messages share the underlying substrate (XADD + MAXLEN + consumer groups) but differ in semantics: mailbox streams carry addressed messages (durable P2P delivery), while iteration-event streams carry broadcast audit facts (event sourcing projection surface).

## echomq-go code anchor

EchoMQ emits BullMQ-protocol job-lifecycle events using this pattern:

- Event emitter using `XAdd` + `MaxLen` + `Approx: true` approximate trim-on-write: [`../../pkg/echomq/events.go:64-91`](../../pkg/echomq/events.go) — the `Emit` method serializes an `Event` struct into direct stream fields (`event`, `jobId`, `timestamp`, `attemptsMade`, plus type-specific extras) and writes with `XAdd` to the `bull:<queue>:events` stream.
- Per-event-type emitters (`EmitWaiting`, `EmitActive`, `EmitCompleted`, `EmitFailed`, `EmitProgress`, `EmitStalled`, `EmitRetry`): [`../../pkg/echomq/events.go:94-185`](../../pkg/echomq/events.go) — each lifecycle transition emits a canonical-shape event.
- Events stream key builder (cluster-safe slot placement via hash tags): [`../../pkg/echomq/keys.go:89-95`](../../pkg/echomq/keys.go) — `Events()` returns `bull:<queue>:events` or `bull:{<queue>}:events` depending on `useHashTags`.
- `XTRIM MAXLEN ~` usage inside Lua scripts for retention enforcement: [`../../pkg/echomq/scripts/scripts.go:906`](../../pkg/echomq/scripts/scripts.go) (MoveToFinished path) and [`../../pkg/echomq/scripts/scripts.go:1410`](../../pkg/echomq/scripts/scripts.go) (RetryJob path). Both use approximate trimming with a default `10000` event cap when `opts.maxLenEvents` is absent.
- Inline `XADD` inside the `MoveToActive` Lua script (atomicity with job pickup): [`../../pkg/echomq/scripts/scripts.go:146`](../../pkg/echomq/scripts/scripts.go) — writes `event active jobId <id> prev waiting` as a single atomic unit with the list move.

BullMQ reads the event stream at observers only; internal state lives in the job hash + wait/active lists. FTR-009 reverses that relationship for iteration events — the stream IS the state.

## Antipatterns avoided

**1. XDEL after XACK (Swiss-cheese fragmentation).** Streams store entries in Radix-tree macro-nodes (listpacks). `XDEL` marks entries deleted but cannot reclaim memory until the entire macro-node is empty. Per [`mercury streams-consumer-patterns.md §Memory Management`](/Users/jonny/dev/mercury-design/redis-patterns/fundamental/streams-consumer-patterns.md.txt), prefer `XACK` for consumer-group state + `MAXLEN ~` trim-on-write for memory bounds. Heavy `XDEL` usage at steady state is a memory-bloat bug.

**2. Mutating events after append.** Event sourcing requires immutability — the log is the history, and consumers rebuild state by replaying. A "correction" that edits a prior event invalidates every downstream projection built from the replay. Per [`mercury streams-event-sourcing.md §Benefits`](/Users/jonny/dev/mercury-design/redis-patterns/fundamental/streams-event-sourcing.md.txt), the discipline is append-a-compensating-event, never edit in place.

**3. No dedup identifier.** Without an idempotency key, replays after reader crashes double-project (e.g., an L2-escalation B-NNN filed twice). Per [FTR-009 `iteration-events.md` §8](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/iteration-events.md), every event carries `extensions.event_id` (UUID v4) and consumers maintain an LRU dedup cache keyed on it.

**4. Unbounded MAXLEN.** A stream with no `MAXLEN` grows without bound and eventually exhausts Redis memory. Even for "audit forever" requirements, the correct shape is tight in-Redis retention + periodic archive to cold storage (out-of-scope for H1; see [FTR-009 `iteration-events.md` §6](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/iteration-events.md) for the FTR-018 forward-pointer).

## Cross-references

FTR consumers:

- [FTR-009 `iteration-events.md`](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/iteration-events.md) — canonical 13-field envelope + phase taxonomy + publish path
- [FTR-009 `mailbox-keyspace.md`](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/mailbox-keyspace.md) — bridgeEnvelope dual-write + MAXLEN pin
- [FTR-009 `tui-panels.md`](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/tui-panels.md) — Iterations tab projection
- FTR-008 `dev/mcp/features/FTR-008-cclin-echomq-pubsub/` — `SendMessageBridge` producer
- FTR-010 (future) HITL draft-approval events
- FTR-018 (future) long-term archive sink for beyond-14h audit

Sibling patterns:

- [`streams-consumer-groups.md`](streams-consumer-groups.md) — per-consumer durable delivery on the same substrate
- [`reliable-queue.md`](reliable-queue.md) — alternative when consumer-group machinery is overkill
- [`pubsub-fanout.md`](pubsub-fanout.md) — anti-pattern contrast; pubsub is fire-and-forget, Streams are durable
- [`hash-tag-colocation.md`](hash-tag-colocation.md) — cluster-mode slot placement for stream + meta keys
- [`atomic-updates.md`](atomic-updates.md) — Lua-script atomicity for combined XADD + HSET transitions

Mercury-design source:

- [`fundamental/streams-event-sourcing.md`](/Users/jonny/dev/mercury-design/redis-patterns/fundamental/streams-event-sourcing.md.txt) — primitive reference (append-only log + projections)
- [`fundamental/streams-consumer-patterns.md`](/Users/jonny/dev/mercury-design/redis-patterns/fundamental/streams-consumer-patterns.md.txt) — PEL + memory-management discipline

## Worked example

FTR-009 iteration-event envelope written to a team-scoped events stream, then replayed for TUI boot:

```bash
# Publisher — emit a grade event with 13-field canonical envelope
XADD cclin:mbox:flyer-a1:apollo-2:stream MAXLEN \~ 5000 * \
     message_id evt-uuid-abc \
     from apollo-2 to mars-3 body '{"team":"flyer-a1","kind":"iteration_event","agent":"mars-3","archetype":"mars","iteration_id":"W1-Iter-1","phase":"grade","grade":"A-","grade_rubric":"code=28/30 arch=36/40 fidelity=18/20","artifacts":["apps/echomq-go/docs/patterns/streams-consumer-groups.md"],"trace_id":"tr-abc","ts":1714000000000,"notify_class":"important","notify_text":"Iter-1 grade: A- (92/100)","extensions":{"event_id":"uuid-v4-xyz","emitter":"apollo-2","status":"pass","score":92}}' \
     trace_id tr-abc ts_ms 1714000000000 \
     kind iteration_event

# Consumer — TUI Iterations tab backfill (most-recent 100 events)
XRANGE cclin:mbox:flyer-a1:apollo-2:stream - + COUNT 100

# Consumer — continuous tail (consumer-group pattern; see streams-consumer-groups.md)
XREADGROUP GROUP cclin:mbox:flyer-a1:apollo-2:stream:grp tui-12345 \
           BLOCK 5000 COUNT 32 \
           STREAMS cclin:mbox:flyer-a1:apollo-2:stream >

# Inspect retention window
XLEN cclin:mbox:flyer-a1:apollo-2:stream              # current entry count
XINFO STREAM cclin:mbox:flyer-a1:apollo-2:stream       # length + first/last ids + groups
```

Go-side sketch of the FTR-009 publisher (mirrors [FTR-009 `iteration-events.md` §4](../../../dev/mcp/features/FTR-009-cclin-human-bridge/architecture/iteration-events.md)):

```go
func (p *Publisher) Emit(ctx context.Context, evt IterationEvent) error {
    if evt.Kind == "" { evt.Kind = "iteration_event" }
    if evt.Ts == 0 { evt.Ts = time.Now().UnixMilli() }
    if evt.Extensions == nil { evt.Extensions = map[string]any{} }
    if _, ok := evt.Extensions["event_id"]; !ok {
        evt.Extensions["event_id"] = uuid.NewString()
    }
    body, _ := json.Marshal(evt)
    outer := pubsub.BridgeEnvelope{
        MessageID: evt.Extensions["event_id"].(string),
        From:      evt.Extensions["emitter"].(string),
        To:        evt.Agent,
        Body:      string(body),
        Kind:      "iteration_event",
        Team:      evt.Team,
    }
    return p.bridge.Publish(ctx, outer)
}
```
