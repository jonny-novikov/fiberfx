# R5.03.3 · The dedicated blocking connection

> Route: `/redis-patterns/streams-events/pubsub/the-dedicated-blocking-connection` · dive
> Grounding: `echo/apps/echo_mq/lib/echo_mq/events.ex` (the `:conn` is RESP3 `protocol: 3` + `push_to`; the
> `{:emq_push, …}` frame; the emq.1 resubscribe `MapSet`) · `echo/apps/echo_wire/lib/echo_mq/connector.ex`
> (`subscribe/2`, `push_to`).

The fire-and-forget side carries one operational cost the publish side hides entirely: a subscriber
monopolizes its connection. The instant a connection issues `SUBSCRIBE`, it enters subscriber mode and can no
longer run ordinary commands — a `GET` on that connection is refused until it unsubscribes. So a subscriber is
not a connection borrowed from the shared pool and returned; it is a connection given over to listening for as
long as it listens. This dive reads why that is, how `EchoMQ.Events` handles it with a dedicated RESP3 lane,
and the resubscribe that keeps the feed live across a reconnect.

## SUBSCRIBE changes the connection

A Redis connection in subscriber mode is a different beast. After `SUBSCRIBE channel`, the connection's only
job is to carry pushed messages from that channel; the protocol refuses most ordinary commands on it until it
unsubscribes. There is good reason — a subscriber must be able to receive a message at any instant, with no
request outstanding, so the connection cannot also be mid-`GET`. But the consequence for connection accounting
is exact: a subscription is not a quick borrow-and-return like a `GET`; it holds its connection for the entire
lifetime of the subscription.

This is the same hazard shape as the blocking stream read in R5.02 — a verb that holds a connection — but it
is worse in degree. A `BLOCK 1000` parks for a second and re-arms; a `SUBSCRIBE` parks until its
owner stops listening, which may be the life of the application. Run a subscriber on a connection drawn
from the shared pool and that connection never comes back. Run several and the pool drains: an unrelated
`GET` elsewhere in the app waits for a connection that is gone for good. The subscriber did not deadlock the
channel; it removed connections from circulation.

## The fix is a dedicated lane

The mitigation is the same law the blocking read follows: a verb that holds a connection gets its own
connection. Give each subscriber a connection that is not part of the shared pool, dedicated to the
subscription, and the shared pool stays whole — every ordinary `GET` and `SET` runs on a free connection while
the subscriber holds its own. It is not a tuning knob; it is a structural requirement, because a subscriber's
connection is consumed by definition, not occasionally.

In RESP3 the dedicated-lane requirement has a second half: the connection must be in protocol 3 so pushed
messages arrive as out-of-band *push* frames the client routes to the listener, rather than tangling with
ordinary replies on the wire. So a subscriber lane is specifically a RESP3 connection given over to one
listening process.

## EchoMQ.Events takes it as a requirement

`EchoMQ.Events` does not let a caller subscribe on a borrowed connection. Its `:conn` **must** be a RESP3
connector — `protocol: 3` — with `push_to` set to the listener process, so pushed messages land as
`{:emq_push, …}` mailbox frames on a connection dedicated to the subscription. The moduledoc spells it: the
`:conn` "MUST be `protocol: 3` and `push_to` this process." If a caller hands it connector options instead,
`init/1` starts a fresh connector and sets both itself:

```elixir
conn_opts =
  opts
  |> Keyword.fetch!(:connector)
  |> Keyword.put_new(:protocol, 3)        # ← RESP3: pushes arrive as push frames
  |> Keyword.put(:push_to, self())        # ← routed to THIS listener process

{:ok, c} = Connector.start_link(conn_opts)
```

It then subscribes **once** to `emq:{q}:events` on that lane, and a pushed message arrives as
`{:emq_push, ["message", channel, payload]}` — dispatched to the registered subscriber pids and the handler.
The subscription rides its own connection, so the single-owner socket the rest of the system shares is never
stalled — the same outcome the blocking stream read reaches by holding its own lane. A listening verb on a
listening connection.

## The resubscribe — surviving a reconnect

A dedicated lane fixes the connection-accounting problem. A second problem remains: a connection can drop, and
a subscription does not survive a TCP reconnect on its own — the server forgets a dropped connection's
subscriptions, so a naive reconnect comes back subscribed to nothing and the feed goes silent. The fix is the
emq.1 resubscribe. The connector tracks its subscribed channels in a `MapSet`, and on reconnect it re-issues
the `SUBSCRIBE` for each, so the feed comes back live without the listener doing anything.

That mechanism is also exactly the boundary of the at-most-once promise. Between the socket drop and the
resubscribe completing, the connection is subscribed to nothing, so a message published in that window reaches
no subscriber and is lost. The resubscribe narrows the window to the reconnect interval; it does not erase it,
because nothing short of a durable log could. The moduledoc states both halves: the resubscribe is "the
mitigation (a reconnect re-issues the `SUBSCRIBE`)," and "the durable replayable receipt is" the Stream, "not
this." A subscriber that cannot tolerate even that window does not want a subscriber — it wants the durable
channel.

## The pattern, applied

A codemojex (`echo/apps/codemojex`) live-feed listener subscribes to its game's `emq:{q}:events` channel on a
dedicated RESP3 connector, separate from the pool the game's ordinary reads and writes use. While it sits
parked on the subscription for the life of the room, a `GET`-the-board call and a `SET`-the-score call
elsewhere in the app never wait on its connection — the listener holds its own lane. If the connection drops
for a heartbeat, the connector's resubscribe re-issues the `SUBSCRIBE` and the live feed resumes on its own;
the one or two events that published during the gap are missed by the live view and lose nothing, because the
durable round Stream still holds them for the feed reader that replays the log. A dedicated lane for the live
nudge, the durable Stream for the record.

## References

### Sources

- [Valkey — SUBSCRIBE](https://valkey.io/commands/subscribe/) — entering subscriber mode and the commands the
  connection then refuses.
- [Valkey — Pub/Sub](https://valkey.io/topics/pubsub/) — the subscriber connection model and the RESP3 push
  delivery.
- [Valkey — RESP3 protocol](https://valkey.io/topics/protocol/) — the push frames a `protocol: 3` connection
  delivers out of band.
- [Valkey — Cluster specification](https://valkey.io/topics/cluster-spec/) — the `{q}` hash tag that places a
  queue's events channel on one of 16384 hash slots.

### Related in this course

- [R5.03 · Pub/Sub vs Streams](/redis-patterns/streams-events/pubsub) — the module hub.
- [R5.03.1 · Fire-and-forget vs durable](/redis-patterns/streams-events/pubsub/fire-and-forget-vs-durable) —
  the at-most-once promise this connection serves.
- [R5.03.2 · The choosing rule](/redis-patterns/streams-events/pubsub/the-choosing-rule) — when the
  fire-and-forget connection is the right choice.
- [R5.02.1 · The blocking read](/redis-patterns/streams-events/streams-consumer-patterns/the-blocking-read) —
  the same dedicated-lane law for the blocking stream read.
- [/echomq/bus](/echomq/bus) — the EchoMQ Bus pillar: the broadcast channel and its connection seam in depth.
