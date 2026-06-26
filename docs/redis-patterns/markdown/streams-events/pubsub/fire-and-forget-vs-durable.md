# R5.03.1 · Fire-and-forget vs durable

> Route: `/redis-patterns/streams-events/pubsub/fire-and-forget-vs-durable` · dive
> Grounding: `echo/apps/echo_mq/lib/echo_mq/events.ex` (`EchoMQ.Events.publish/5` → `PUBLISH emq:{q}:events`,
> at-most-once) · `stream.ex` (`EchoMQ.Stream.append/4` → `XADD`, the `{:ok, branded}` receipt).

A `PUBLISH` and an `XADD` look alike from the caller — both take a payload and send it toward consumers — but
they make opposite promises about what happens to a consumer who is not there yet. A publish reaches the
subscribers present at that instant and nobody else; the log remembers an append for the reader who arrives a
minute later. This dive sits the two side by side: the at-most-once publish, the durable receipt, and the gap
between them — the no-live-subscriber case where one drops the message and the other keeps it.

## What a PUBLISH guarantees

`PUBLISH channel payload` is a delivery, not a store. Valkey sends the payload to every connection subscribed
to `channel` at the moment of the call and returns an integer — the number of subscribers it reached. That
integer is the whole receipt, and it is weak: a publish that reaches `0` returns `0`, which the sender cannot
tell apart from a healthy delivery without out-of-band knowledge of who should be listening. There is no
buffer behind the channel and no cursor in front of it. A subscriber that connects one millisecond after the
publish sees nothing of it; a subscriber that drops for a heartbeat and reconnects has missed whatever
published while it was gone.

This is **at-most-once**: a present subscriber receives a message zero or one times, and the message is never
held for an absent one. It is the right promise for a signal whose value is *now* — a live progress tick, a
presence ping, a cache-invalidation nudge — where a missed message means only that the next one supersedes it.
It is the wrong promise for anything that must be remembered: an order, an audit entry, a state transition a
reader must eventually see. The trap is that the API hides the difference — `PUBLISH` looks like it sent
something durable, and the returned count looks like a confirmation.

## What an XADD keeps

`XADD key * field value …` is a store with a delivery on top. Valkey appends the entry, assigns it a
monotonic id, and keeps it in the log until a retention policy removes it. The return value is that id — a
durable handle the caller keeps, not a count it has to interpret. A reader reads with `XRANGE` from any
position: the start of the log (`-`), a saved cursor, or only-new (`>` under a consumer group). So a reader
that was absent reads what it missed, a reader that crashed resumes from its cursor, and a reader rebuilding
state replays from `-`. The log is the source of truth, and the id is how every reader agrees on order.

The cost of that durability is memory and a retention decision — a log that only grows is a leak, so a Stream
needs a trim policy where a channel needs nothing. That cost is the subject of R5.02's trimming dive. Here the
point is narrower: where a publish answers a subscriber count and forgets, an append answers a receipt and
remembers.

## EchoMQ.Events.publish — at-most-once, stated

`EchoMQ.Events` is EchoMQ's pub/sub surface, and it does not pretend the channel is durable.
`publish(conn, queue, event, job_id, extra \\ [])` gates the id at the key builder, encodes the cjson
`{"event": …, "job": …}` payload, and issues `PUBLISH emq:{q}:events payload` — best-effort, a no-op when no
one is listening. The moduledoc states the promise in one sentence, verbatim: *"a PUBLISH with no live
subscriber, or one issued in the window between a socket drop and the resubscribe, is lost."* The cost is
named, not hidden behind the API.

```elixir
def publish(conn, queue, event, job_id, extra \\ []) do
  # gate the id (INV5) — raises on an ill-formed id before the wire
  _ = Keyspace.job_key(queue, job_id)
  payload = encode_event(event, job_id, extra)

  case Connector.command(conn, ["PUBLISH", channel(queue), payload]) do
    {:ok, _n} -> :ok          # ← the subscriber count, discarded — best-effort
    other -> other
  end
end
```

The returned `_n` — the subscriber count — is discarded on purpose. EchoMQ does not retry a publish that
reached zero subscribers, because retrying would not change the promise: there is still no store behind the
channel, and a late subscriber would still miss it. When a receipt is genuinely required, the design points at
the other channel rather than hardening this one.

## EchoMQ.Stream.append — the durable receipt

`EchoMQ.Stream.append(conn, queue, name, fields)` is the durable contrast on the same bus. It mints an
`EVT`-branded record id host-side, appends `XADD emq:{q}:stream:<name> <xadd_id> id <branded> <fields…>`, and
returns `{:ok, branded}`. **The branded id is the receipt** — a 14-byte durable handle, not a subscriber
count. The moduledoc puts it plainly: the append "returns `{:ok, branded}` — the branded id IS the receipt."

```elixir
case Connector.command(conn, parts) do
  {:ok, id} when is_binary(id) -> {:ok, branded}              # ← the receipt: the branded id
  {:ok, {:error_reply, @id_too_small}} -> {:error, :nonmonotonic}
  {:ok, {:error_reply, msg}} -> {:error, {:error_reply, msg}}
  {:error, _} = err -> err
end
```

The entry now exists in the log and stays there until retention removes it. A reader absent at append time
reads it later; a reader rebuilding state folds the whole log. The same event the publish forgot the instant
no one was listening, the append still holds.

## The gap — the no-live-subscriber case

Put one event through both channels with no subscriber present, and the difference is the whole module in
miniature. The publish reaches a subscriber count of zero and is gone — there is nowhere it could have been
stored. The append writes an entry that sits in the log, and the reader who connects a minute later reads it
in full. Neither is wrong; they are different promises. The publish is a doorbell that only the people home
hear; the append is a letter in the box that waits for whoever checks the mail.

So the common shape in a real system is *both*: append the event to the durable Stream so the record exists
and can be replayed, and publish a lighter notification on Events so a live view reacts at once. The Stream is
the system of record; the publish is the live nudge. If the nudge reaches no one, nothing of consequence is
lost — the record is in the log, readable on the reader's own schedule.

## The pattern, applied

In codemojex (`echo/apps/codemojex`) a round-settled event takes exactly that dual path. The settlement is
appended to the round's durable Stream with `EchoMQ.Stream.append/4`, so the `{:ok, branded}` receipt records
that it happened and a feed reader can replay the round or resume after a restart. A lighter "round settled"
notification is published on `EchoMQ.Events` so a live Telegram view updates the instant the round closes. A
player who is not watching at that instant misses the live nudge — and loses nothing, because the durable
Stream still holds the settlement for the feed that reads it later. Durable where the record matters, live
where the reaction does.

## References

### Sources

- [Valkey — PUBLISH](https://valkey.io/commands/publish/) — sends to present subscribers, returns the count
  reached; no subscriber means a no-op, nothing stored.
- [Valkey — Pub/Sub](https://valkey.io/topics/pubsub/) — the fire-and-forget channel and its at-most-once
  delivery.
- [Valkey — XADD](https://valkey.io/commands/xadd/) — appends a durable entry with a monotonic id and returns
  it; the receipt a publish has no equivalent of.
- [Valkey — Introduction to Streams](https://valkey.io/topics/streams-intro/) — the retained, replayable log
  the append writes to.

### Related in this course

- [R5.03 · Pub/Sub vs Streams](/redis-patterns/streams-events/pubsub) — the module hub.
- [R5.03.2 · The choosing rule](/redis-patterns/streams-events/pubsub/the-choosing-rule) — when each promise
  is the one you need.
- [R5.03.3 · The dedicated blocking connection](/redis-patterns/streams-events/pubsub/the-dedicated-blocking-connection)
  — the operational cost the publish side carries.
- [/echomq/bus](/echomq/bus) — the EchoMQ Bus pillar: the broadcast channel and the retained log in depth.
- [/bcs/bus](/bcs/bus) — Part B3, the Stream Tier the durable receipt is written to.
