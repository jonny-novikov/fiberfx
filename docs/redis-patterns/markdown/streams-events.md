# R5 · Streams & Events

> Route: `/redis-patterns/streams-events` · Chapter landing (manifest) · BCS contract-sheet identity (redis-red).
> Grounding: EchoMQ's real shipped **Stream Tier** in `echo/apps/echo_mq` — `EchoMQ.Stream` (the writer),
> `EchoMQ.StreamConsumer` (the reader law), `EchoMQ.StreamRetention` (retention as policy), keyspace
> `emq:{q}:stream:<name>` — and the manuscript bus chapter `docs/echo/bcs/bcs.3.md §B3.3`, worked through the
> **codemojex** consumer (`echo/apps/codemojex`). Engine: Valkey 9. Doors: `/echomq/bus` (the Bus pillar) +
> `/bcs/bus` (the manuscript) + `/echo-persistence` (the durable archive floor).

A Redis Stream is the append-only source of truth. Append every event, replay to rebuild state, consume with
blocking reads and consumer groups, trim under a retention policy — and fold what is trimmed to the durable floor.

## Overview

A row says what is true now; a log says everything that ever happened, in order. A Redis Stream is that log: an
append-only sequence of entries, each carrying a time-ordered id that sorts it against every other. Append every
change as an immutable entry, and the present is no longer a value you overwrite but a fold you recompute — replay
the log from the start and the state falls out, the same every time.

EchoMQ ships this as a real **Stream Tier** beside the job queue, and that tier is the worked example for the
chapter. `EchoMQ.Stream.append/4` issues `XADD emq:{q}:stream:<name>` and returns the branded `EVT` id;
`EchoMQ.Stream.read/6` issues `XRANGE` and hands the entries back in mint order to fold. `EchoMQ.StreamConsumer`
carries the reader law — a consumer group reads new entries, acknowledges them, and resumes where it left off, so a
reader that restarts does not replay what it has already handled. A log that only grows is a leak, so
`EchoMQ.Stream.trim/4` bounds it by length or age under a named, opt-in retention driver, and what is trimmed is not
lost: `EchoStore.StreamArchive` folds trimmed segments into the durable Graft floor. The append order is the truth
order, and the stream keys are born braced and branded like every other key on the bus.

## Why & when

Reach for streams whenever the history matters as much as the present, and many independent readers each need to
consume the same record of what happened at their own pace. Each capability below answers one demand the chapter
makes good on.

- **The history is the truth, not the latest value.** An audit trail, an activity feed, or a state machine whose
  transitions other readers also consume — keep the immutable log and derive the present by folding it, instead of
  overwriting a row and losing what came before.
- **Many readers, one log, different speeds.** A stream is read non-destructively: a read moves a cursor instead of
  removing the entry, so the entry stays until each reader acknowledges it. One reader can be at the tail while
  another replays from the start.
- **A reader must wait without busy-polling.** A blocking read parks until the next entry arrives, so a consumer
  that is caught up costs the engine nothing and wakes the instant there is work.
- **A reader that crashes must resume, not replay.** A consumer group remembers each consumer's un-acknowledged
  backlog, so a restarted reader drains what it owns before reading anything new.
- **The log must stay bounded, and deep history must survive.** Retention is a policy, not a default: trim the live
  log by length or age, and fold what is trimmed to a durable floor so deep history is readable without resident
  memory.

## The patterns

All four teaching modules and the closing workshop are built. Each module is a hub with its dives, grounded in the
real EchoMQ Stream Tier.

- **R5.01 · Event sourcing on Streams** — the append-only log is the source of truth; store every change as an
  immutable entry and reconstruct current state by folding the log from the start. Grounded in
  `EchoMQ.Stream.append/4` (`XADD`) and `EchoMQ.Stream.read/6` (`XRANGE`).
- **R5.02 · Stream consumer patterns** — block, batch, trim, resume; read the log reliably with consumer groups,
  handle failure recovery and poison pills, and manage memory. Grounded in `EchoMQ.StreamConsumer` (the reader law),
  `EchoMQ.Stream.trim/4`, and `EchoMQ.StreamRetention`.
- **R5.03 · Pub/Sub vs Streams** — fire-and-forget delivery against a durable, replayable log; the rule for
  choosing between a channel a subscriber must be present for and a log a reader can resume.
- **R5.04 · Custom events & projections** — arbitrary domain events appended to the same stream, and windowed
  projections folded from them; many independent views over one log.
- **R5.05 · Workshop** — a live codemojex activity feed off the `:events` stream lifecycle: every guess, round, and
  settlement appended as an event, and the feed a fold of the log.

## How to apply

The hard part is matching the stream technique to the demand you have. Name the demand, and the technique — and the
real EchoMQ surface that implements it — follows.

| Demand | Technique | The EchoMQ surface |
|---|---|---|
| The history is the truth | append-only log + fold | `EchoMQ.Stream.append/4` (`XADD`); `EchoMQ.Stream.read/6` (`XRANGE`) |
| A reader waits without busy-polling | blocking read | `EchoMQ.StreamConsumer` parks on the next entry |
| A crashed reader resumes, not replays | consumer group + un-acked backlog | `EchoMQ.StreamConsumer` the reader law |
| The log must stay bounded | retention as policy | `EchoMQ.Stream.trim/4`; `EchoMQ.StreamRetention` the named driver |
| Deep history must survive a trim | fold to the durable floor | `EchoStore.StreamArchive` into the Graft floor |

There is no single streams trick — only the technique that answers the demand you have, each one a real move in
EchoMQ's Stream Tier.

## The workshop — a codemojex activity feed

The chapter closes with R5.05: a live codemojex activity feed built off the `:events` stream lifecycle. Each event
the game produces — a guess submitted, a round opened, a settlement posted — is appended to
`emq:{q}:stream:events` with `EchoMQ.Stream.append/4`, minting a branded `EVT` id as the receipt. The feed is a fold
of that log: a reader replays the stream in mint order to render what has happened, and a consumer group lets the
notification side resume after a restart without re-sending what it already delivered. Retention trims the live log
under `EchoMQ.StreamRetention`, and `EchoStore.StreamArchive` folds older segments to the durable floor so the deep
feed survives without holding memory. The activity feed is the log seen sideways — identity orders the entries, the
boundary owns them, and what survives is a choice the system makes.

## The road ahead — R6 to R8

R5 records the durable event log the rest of the tier can lean on. R6 holds the tier stable under load; R7 attends
to how the record lives in RAM; R8 operates the tier in production. A trimmed stream segment, or a stream archived
for deep history, reaches the **durable floor** — the persistence tier behind `/echo-persistence`, where
`EchoStore.StreamArchive` folds into the Graft engine and out to Tigris, the durability dial taught end to end.

## References

### Sources

- [Valkey — Introduction to Streams](https://valkey.io/topics/streams-intro/) — the append-only log, entry ids,
  consumer groups, and the range read this chapter is built on.
- [Valkey — Cluster specification](https://valkey.io/topics/cluster-spec/) — the `{q}` hash tag forces a queue's
  stream keys onto one of the 16384 slots so a multi-key script stays legal.
- [Kreps, J. — The Log](https://engineering.linkedin.com/distributed-systems/log-what-every-software-engineer-should-know-about-real-time-datas-unifying) — the log as the shared abstraction beneath a stream.
- [Oban](https://hexdocs.pm/oban/Oban.html) — the comparison: jobs and data in one Postgres transaction; the bus
  separates the log from the store and buys an in-memory hot path with the durability dial.

### Related in this course

- [R4 · Time, Delay & Priority](/redis-patterns/time-delay-priority) — the sorted set as a clock; the chapter R5
  follows.
- [R5.01 · Event sourcing on Streams](/redis-patterns/streams-events/streams-event-sourcing) — the append-only log
  as the source of truth, replay to rebuild.
- [R5.02 · Stream consumer patterns](/redis-patterns/streams-events/streams-consumer-patterns) — block, resume,
  trim, archive; read the log reliably.
- [/echomq/bus](/echomq/bus) — the EchoMQ Bus pillar: the broadcast and the retained, replayable log in depth.
- [/bcs/bus](/bcs/bus) — the manuscript bus chapter (B3) the figures are drawn from.
- [/echo-persistence](/echo-persistence) — the durable floor a trimmed or archived stream segment reaches.
