# R5 · Streams & Events — the durable log

> Observability and event-driven coordination, with Redis Streams as the durable, replayable log. Four patterns —
> event sourcing on Streams, stream consumer patterns, Pub/Sub versus Streams, and custom events and projections —
> grounded in EchoMQ's `:events` stream. Depends on R3's job lifecycle, which emits the events.

## Where this chapter starts and ends

- **Start** — R3's reliable queue, whose every transition emits a lifecycle event. The reader can run a queue but
  cannot yet observe it, replay its history, or broadcast domain events.
- **End** — the reader can treat a Redis Stream as the append-only source of truth and rebuild state from it,
  consume it with blocking long-poll and consumer groups, choose Streams over Pub/Sub for persistence and replay,
  and publish arbitrary domain events with windowed projections. The workshop builds a live Portal activity feed.

## The grounding (Redis Pattern Applied)

Grounded in **EchoMQ's `:events` stream**: every lifecycle transition is `XADD bull:{queue}:events MAXLEN ~ 10000`
(`apps/echomq-go/pkg/echomq/events.go`); consumers read it with `XREAD BLOCK` (the documented naive form, with the
`XREADGROUP` consumer-group upgrade as the "make it reliable" arc); the stream is trimmed approximately with
`MAXLEN ~`; and `last_event_id` resumes a consumer from a known position. Pub/Sub is the **contrast** — EchoMQ
deliberately chose durable Streams over fire-and-forget Pub/Sub (ch22), using a true `echomq:cancel` Pub/Sub channel
only for cross-worker cancellation.

## The module ladder

| Module | Pattern | What it adds | Grounding | Dives |
| --- | --- | --- | --- | --- |
| R5.01 event-sourcing | `streams-event-sourcing` | the append-only log is the source of truth; state is its replay | `:events` `XADD` | the append-only log · replay/rebuild · `last_event_id` cursor |
| R5.02 consumer-patterns | `streams-consumer-patterns` | block, batch, trim, resume | EchoMQ QueueEvents (`XREAD BLOCK`; → `XREADGROUP`) | XREAD BLOCK · consumer groups · `MAXLEN ~` trimming |
| R5.03 pubsub-vs-streams | `pubsub` | fire-and-forget vs durable, and how to choose | `echomq:cancel`; the ch22 decision | fire-and-forget vs durable · the choosing rule · the dedicated blocking connection |
| R5.04 custom-events | `streams-event-sourcing` (applied) | arbitrary domain events and windowed projections on the same stream | EchoMQ custom events on `:events` | domain events on the stream · windowed aggregation · reserved-name discipline |
| R5.05 Workshop | — | a live Portal activity feed | the `:events` stream over Portal lifecycle | — |

## The door to the EchoMQ course

→ EchoMQ. The cross-runtime event system — the full 14-event schema, the per-runtime consumers (Node `QueueEvents`,
the Elixir GenServer mailbox, the Go listener gap), and the cross-language field mapping — belongs to the dedicated
EchoMQ course. This chapter teaches the Streams patterns; that course teaches EchoMQ's observability layer.

## Conventions

Pages follow the two mandatory layout rules, pass the ten gates including `refs`, and honour voice and no-invent:
cite the real EchoMQ stream key, command, or decision from the grounding map. Pub/Sub is taught as the contrast to
Streams (the choice EchoMQ made), not as EchoMQ's event transport. R5.04 reapplies R5.01's event-sourcing pattern to
user-defined events rather than introducing a new catalog pattern. See [`../redis-patterns.md`](../redis-patterns.md).

Index: [`../redis-patterns.md`](../redis-patterns.md) · TOC: [`../../redis-patterns.toc.md`](../../redis-patterns.toc.md) · Roadmap: [`../../redis-patterns.roadmap.md`](../../redis-patterns.roadmap.md)
