# R5.03 · Pub/Sub vs Streams

> Route: `/redis-patterns/streams-events/pubsub` · module hub
> Grounding: `echo/apps/echo_mq/lib/echo_mq/events.ex` (`EchoMQ.Events`) · `stream.ex`
> (`EchoMQ.Stream.append/4`) · `cancel.ex` (`EchoMQ.Cancel`), with codemojex the consumer.

Two channels carry an event in Valkey, and they make opposite promises. Pub/Sub is fire-and-forget:
`PUBLISH` reaches whoever is subscribed at that instant and reaches nobody else, so a message issued with
no live subscriber is gone. A Stream is a durable, replayable log: `XADD` writes the entry and hands back a
receipt, and a reader that was not there can read it later, resume after a crash, and replay from the start.
The pattern is choosing between them — a channel a subscriber must be present for, against a log a reader can
resume — and refusing the temptation to make one do the other's job.

EchoMQ made that decision in the open, and the two channels are separate surfaces, not a mode on one.
`EchoMQ.Events` is the fire-and-forget side: it subscribes once to the per-queue channel `emq:{q}:events` and
delivers each lifecycle event to whoever is listening *now* — at-most-once, stated and not papered over.
`EchoMQ.Stream` is the durable side: `append/4` writes an entry to `emq:{q}:stream:<name>` and returns the
`{:ok, branded}` receipt, replayable beside the live tail. The system of record is the durable Stream; Pub/Sub
is for live reaction. This module reads the difference, gives the rule for choosing, and ends on the one
operational cost the fire-and-forget side carries — a subscriber monopolizes its connection.

## Two promises

A Redis channel is a delivery, not a store. `PUBLISH channel payload` sends the payload to every connection
currently subscribed to `channel` and returns the number of subscribers it reached. There is no buffer, no
backlog, no cursor: a subscriber that connects one millisecond later sees nothing of what came before, and a
publish that reaches a subscriber count of zero is a no-op the sender cannot distinguish from success at the
protocol level. This is the **at-most-once** promise: a message is delivered to a present subscriber zero or
one times, never stored for a late one.

A Stream inverts every one of those defaults. `XADD key * field value` appends an entry, assigns it a
monotonic id, and keeps it in the log until a retention policy removes it. A reader reads with `XRANGE` or
`XREADGROUP` from any position — the start, a saved cursor, or only-new — so a reader that was absent reads
what it missed, and a reader that crashed resumes where it stopped. The log *remembers*; the channel does not.
The two are not competitors with one better than the other: a live metrics tick wants the channel's
no-storage simplicity, and an audit trail wants the log's durability. The error is using the channel where
the promise needed was the log's.

## EchoMQ.Events — the fire-and-forget side

`EchoMQ.Events` is EchoMQ's pub/sub surface, and it is honest about the promise. It subscribes once to the
per-queue channel `emq:{q}:events` and dispatches each lifecycle event — a job completed, failed, scheduled,
stalled — to the pids that registered with `subscribe/2` and to an optional handler module. A consumer reacts
to work as it happens without polling the sets. The moduledoc states the cost in one sentence: *"a PUBLISH
with no live subscriber, or one issued in the window between a socket drop and the resubscribe, is lost."*
That is at-most-once, named.

The mitigation is not a buffer — adding one would make it a different channel. It is the emq.1 resubscribe: a
connector that reconnects re-issues its `SUBSCRIBE`, so the feed comes back live across a drop, narrowing the
loss window to the reconnect itself. And where a receipt is actually required — replay, audit, a reader that
must not miss an entry — the answer is the durable channel, not a harder push: `EchoMQ.Stream`, not
`EchoMQ.Events`. The design says so directly, and that honesty is the lesson.

## EchoMQ.Stream — the durable contrast

`EchoMQ.Stream.append(conn, queue, name, fields)` is the other promise. It mints an `EVT`-branded record id
host-side, appends `XADD emq:{q}:stream:<name> <id> id <branded> <fields…>`, and returns `{:ok, branded}` —
**the branded id is the receipt**. Where a publish answers a subscriber count it cannot interpret, an append
answers a durable handle the caller keeps. The entry stays in the log until retention removes it, readable by
any reader at its own pace, replayable from the start.

The same event can travel both channels, and often should: append it to the Stream so the record exists and
can be replayed, and publish a lighter notification on Events so a live dashboard reacts without reading the
log. The Stream is the source of truth; the publish is the doorbell. What a publish forgets the instant no
one is listening, the log still holds for the reader who arrives a minute later.

## The choosing rule

The decision is not taste; it follows from the promise each channel makes. The rule:

| You need | Channel | Why |
|---|---|---|
| Replay from the start | Stream | the log is retained; `XRANGE` reads from `-` |
| A reader that resumes after a crash | Stream | the consumer-group cursor / PEL survives the reader |
| An audit trail or event sourcing | Stream | every entry is stored with an ordered id |
| Time-travel to a past window | Stream | a mint instant becomes a range bound |
| Live "react now, no replay" | Events | at-most-once is enough; no storage cost |
| An ephemeral signal a present worker reads | Events | a control nudge, not a record |

The default is the Stream — durability is the safe choice, and a Stream can always feed a live reaction too.
Reach for Events only when the promise you need is genuinely *react-now-or-never*: a metrics tick, a presence
ping, a live progress bar. The worked fire-and-forget case is a cooperative control signal — see the dives.

## The dedicated blocking connection

The fire-and-forget side carries one operational cost the publish side hides: a subscriber monopolizes its
connection. The moment a connection issues `SUBSCRIBE`, it enters subscriber mode and can no longer run
ordinary commands — a `GET` on that connection is refused until it unsubscribes. A subscriber is therefore not
a connection borrowed from the shared pool; it is a connection given over to listening.

`EchoMQ.Events` takes that as a requirement, not an accident. Its `:conn` **must** be a RESP3 connector
(`protocol: 3`) with `push_to` set to the listener process, so pushed messages arrive as `{:emq_push, …}`
mailbox frames on a connection dedicated to the subscription. The same dedicated-lane discipline the blocking
stream read follows: a verb that holds a connection gets its own connection, so the single-owner socket the
rest of the system shares is never stalled. The third dive reads this seam in full.

## The pattern, applied — the codemojex activity feed

codemojex (`echo/apps/codemojex`) is the worked consumer — a Telegram emoji-guessing game on the same stack.
Its round lifecycle uses both channels for what each is good at. A round event — a round opened, a guess
scored, a round settled — is appended to the durable activity Stream so the full history exists and a feed
reader can replay it or resume after a restart. A lighter notification rides `EchoMQ.Events` so a live
Telegram view reacts the instant something happens, without reading the log. If that publish reaches no live
view, nothing is lost that matters: the Stream still holds the record. Durable where a record is needed, live
where reaction is needed — one event, two channels, each making the promise it should.

## The three dives

- **R5.03.1 · Fire-and-forget vs durable** — the at-most-once `PUBLISH` against the `XADD` receipt; the
  no-live-subscriber gap, and how the log remembers what a publish forgets.
- **R5.03.2 · The choosing rule** — the decision table in full: replay / resume / audit / time-travel pick the
  Stream, live ephemeral picks Events; the `EchoMQ.Cancel` token as the worked fire-and-forget case.
- **R5.03.3 · The dedicated blocking connection** — `SUBSCRIBE` monopolizes a connection; the RESP3 push seam,
  the `protocol: 3` + `push_to` lane, and the resubscribe that keeps the feed live across a reconnect.

## References

### Sources

- [Valkey — Pub/Sub](https://valkey.io/topics/pubsub/) — the fire-and-forget channel: `PUBLISH` /
  `SUBSCRIBE`, no storage, at-most-once delivery.
- [Valkey — PUBLISH](https://valkey.io/commands/publish/) — sends to present subscribers and returns the
  count reached; no subscriber means a no-op.
- [Valkey — Introduction to Streams](https://valkey.io/topics/streams-intro/) — the durable, replayable log
  the `XADD` receipt is written to.
- [Valkey — XADD](https://valkey.io/commands/xadd/) — appends an entry with an ordered id and retains it; the
  durable contrast to a publish.
- [Valkey — Cluster specification](https://valkey.io/topics/cluster-spec/) — the `{q}` hash tag forces a
  queue's channel and stream onto one of 16384 hash slots.
- [Kreps — The Log: What every software engineer should know](https://engineering.linkedin.com/distributed-systems/log-what-every-software-engineer-should-know-about-real-time-datas-unifying)
  — the log as the shared abstraction beneath a stream.

### Related in this course

- [R5 · Streams & Events](/redis-patterns/streams-events) — the chapter.
- [R5.03.1 · Fire-and-forget vs durable](/redis-patterns/streams-events/pubsub/fire-and-forget-vs-durable) —
  the at-most-once publish against the durable receipt.
- [R5.03.2 · The choosing rule](/redis-patterns/streams-events/pubsub/the-choosing-rule) — the decision table
  and the cancel signal.
- [R5.03.3 · The dedicated blocking connection](/redis-patterns/streams-events/pubsub/the-dedicated-blocking-connection)
  — why a subscriber gets its own lane.
- [R5.02 · Stream consumer patterns](/redis-patterns/streams-events/streams-consumer-patterns) — reading the
  durable log reliably.
- [/echomq/bus](/echomq/bus) — the EchoMQ Bus pillar: the broadcast channel and the retained replayable log in
  depth.
- [/bcs/bus](/bcs/bus) — Part B3, the Stream Tier the durable channel is built on.
