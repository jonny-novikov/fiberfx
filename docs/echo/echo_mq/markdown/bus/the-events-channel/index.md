# The events channel — EchoMQ, In Depth (route mirror: `/echomq/bus/the-events-channel`)

> Route-mirror md for **module 01** of the Bus pillar — the hub. The HTML at
> `html/echomq/bus/the-events-channel/index.html` reflects this. All grounding is **real code** in
> `echo/apps/echo_mq` (`lib/echo_mq/events.ex` + `lib/echo_mq/cancel.ex`). This module carries **no
> `[RECONCILE]` markers**: every surface is real. Manuscript figure home: `docs/echo/bcs/bcs.3.md` §B3.3.

## Thesis

The Queue hands one job to **one** worker. The events channel does the opposite: a publisher fans a single
signal out to **everyone listening**, now and gone. It is the bus's lightest surface — fire-and-forget pub/sub
on one channel per queue, `emq:{q}:events` — and its job is to let a consumer **react to work as it happens**
(`completed`, `failed`, `progress`, `stalled`) without polling the sets on a timer.

Three moves carry the whole surface, and the module is one dive each:

- **Subscribe once.** A listener (`EchoMQ.Events`) subscribes a single time to `emq:{q}:events`, riding the
  connector's existing pub/sub seam. Every published message is delivered two ways: to each subscriber pid as
  `{:emq_event, name, payload}`, and to an optional `:handler` module's `handle_event/3`.
- **Publish after the verdict.** A lifecycle event is published **host-side**, after a transition's verdict —
  not from inside the transition's script. That placement is deliberate: it keeps the byte-frozen transition
  scripts byte-unchanged. The payload is a small cjson object; the name is read back by a substring scan, and
  an unknown name answers `:unknown` rather than minting an atom from the wire.
- **Fire-and-forget.** The channel is **at-most-once**: a publish with no live subscriber is lost, and so is
  one issued in the window between a socket drop and the reconnect resubscribe. The reconnect resubscribe is
  the mitigation; the **durable receipt is the stream** (module 02). Its control-plane sibling is
  `EchoMQ.Cancel` — a second fire-and-forget signal, sent to a worker's mailbox, checked cooperatively.

The contrast that frames the whole pillar: **the events say it once; the stream remembers.** The events
channel is the reflex; the stream log is the memory.

## The fan-out (the framing interactive)

A publisher issues one `PUBLISH emq:{q}:events`; the channel fans the message out to every live subscriber pid
and the handler module. Pick a lifecycle event to read the cjson payload it carries and where it is published
from. The point the figure makes: **one publish, N deliveries — and zero if no one is listening.**

The events the bus carries are the lifecycle transitions: `completed`, `failed`, `progress`, `stalled`,
`scheduled`. Each is published host-side after its transition's verdict, except `progress`, which the
`@update_progress` seam already publishes inline (the channel + payload shape it established). The payload is
flat string fields — `{"event":"<name>","job":"<id>",…}` — and the consumer reads the `event` field by scan.

## The two deliveries

A subscriber chooses how it wants the events, and both run off the same one subscription:

- **Subscriber pids** — `subscribe(server, pid)` registers a pid; it then receives `{:emq_event, event_name,
  raw_payload}` for **every** event. Idempotent, defaults to the caller. This is the loose-coupling shape: a
  LiveView, a metrics collector, a test process — each subscribes and pattern-matches the messages it cares
  about in its own `handle_info`.
- **A handler module** — an optional `:handler` implementing the `handle_event/3` behaviour, invoked per event
  with the handler's state and answering `{:ok, new_state}`. `use EchoMQ.Events` derives a no-op default, so a
  handler overrides only the events of interest. This is the stateful-reducer shape: fold the event stream into
  a running state.

Both deliveries happen on the listener's single `emq:{q}:events` subscription — there is no second connection,
no second `SUBSCRIBE`, and no extra cost per subscriber beyond a `send/2`.

## The modules (the three dives)

1. **Subscribe and handle** (`subscribe-and-handle`) — `subscribe/2` registers a pid; the listener subscribes
   **once** to `channel(queue)` = `emq:{q}:events`, riding the connector's `{:emq_push, …}` push and the
   resubscribe `MapSet` that keeps the feed live across a reconnect. Delivery as `{:emq_event, event, payload}`
   to every subscriber pid, plus the `:handler` behaviour (`use EchoMQ.Events` derives a no-op `handle_event/3`;
   override the events of interest).
2. **Publish after the verdict** (`publish-after-the-verdict`) — `publish/5` issues `PUBLISH emq:{q}:events`
   **host-side**, after a transition's verdict (why host-side: the byte-frozen transition scripts stay
   byte-unchanged). The cjson `{"event":"<name>","job":"<id>",…}` payload; the id is **gated at the key builder**
   (`job_key/2`) before the wire; `event_name/1` reads the name by **substring scan** (the bus carries no JSON
   parser) and answers `:unknown` for an unknown name — never minting an atom from the wire.
3. **Fire-and-forget** (`fire-and-forget`) — at-most-once: a publish with no live subscriber, or one in the
   window between a socket drop and the resubscribe, is **lost**; the reconnect resubscribe is the mitigation,
   and the **durable receipt is the stream** (module 02). Paired with `EchoMQ.Cancel` as a second fire-and-forget
   *control* signal: a `make_ref()` token, `cancel/3` sends `{:emq_cancel, token, reason}` to the handler's
   mailbox, `check/1` is a non-blocking `receive after 0` — a worker-side **cooperative** cancel (a handler that
   never checks completes normally), with **no wire identity**.

## Redis Patterns Applied (the reverse door)

This is the depth behind the `/redis-patterns` chapter that doors here: **R5 · Streams & Events** — the
publish/subscribe events that let a consumer react without polling are exactly what this module makes concrete
on the real wire. There the pattern is the door; here is the implementation.

## The durable receipt (the door to the stream log)

The events channel is fast and lossy by design: it broadcasts the present and keeps nothing. When you need the
event to **survive** — to be replayed, audited, or consumed by a reader that was not yet running when it
happened — you do not harden the channel; you write to the **stream log** (`EchoMQ.Stream`, module 02). The
event channel is the reflex; the stream is the memory. The same branded id threads both: an event names a
`JOB`; a stream record IS an `EVT`.

## References

### Sources
- Valkey — Introduction to Streams (`https://valkey.io/topics/streams-intro/`) — the bus surfaces this pillar
  builds on; the events channel is the pub/sub half.
- Valkey — PUBLISH (`https://valkey.io/commands/publish/`) — the single command the events channel issues to
  fan a message out to every subscriber.
- Valkey — SUBSCRIBE (`https://valkey.io/commands/subscribe/`) — the one-time subscription the listener holds on
  `emq:{q}:events`.
- Valkey — Cluster specification (`https://valkey.io/topics/cluster-spec/`) — the `{q}` hashtag forces the
  events channel and the stream onto one of 16384 slots, co-located with the queue.

### Related in this course
- Subscribe and handle (`/echomq/bus/the-events-channel/subscribe-and-handle`) — the one-time subscribe and the
  two deliveries.
- Publish after the verdict (`/echomq/bus/the-events-channel/publish-after-the-verdict`) — the host-side publish
  and the substring-scan read.
- Fire-and-forget (`/echomq/bus/the-events-channel/fire-and-forget`) — at-most-once, and the cancel control
  signal.
- The Bus (`/echomq/bus`) — the pillar this module opens.
- The Queue (`/echomq/queue`) — distribute work; the mirror of the bus over the same wire.
