# R5.03.2 · The choosing rule

> Route: `/redis-patterns/streams-events/pubsub/the-choosing-rule` · dive
> Grounding: `echo/apps/echo_mq/lib/echo_mq/cancel.ex` (`EchoMQ.Cancel` — `new/0`, `cancel/3`, `check/1`, a
> host-side fire-and-forget control signal) · `events.ex` · `stream.ex`.

Once the two promises are clear — at-most-once delivery against a durable, replayable log — choosing between
them stops being a matter of taste. It follows from a single question: does a reader who was not present need
to read this later? If yes, the answer is the Stream, every time. If the value of the message is genuinely
*now-or-never*, Events is enough and cheaper. This dive turns that into a decision table, states the default,
and reads the worked fire-and-forget case in EchoMQ: a cooperative cancel signal that is a control nudge, not
a record — exactly the shape Events is for.

## One question

Every property that distinguishes the two channels reduces to the same fork: *must an absent reader see this
later?* Replay needs it — a reader rebuilding state was not there when the events happened. Resume-after-crash
needs it — the reader that comes back was absent while it was down. An audit trail needs it — the auditor
reads long after the fact. Time-travel needs it — a window of past entries is exactly the absent reader's
case. All four are the Stream.

The opposite branch is a message whose value expires the instant it is sent: a live progress percentage, a
presence heartbeat, a "stop what you are doing" nudge to a worker that is running right now. A reader who was
not present has nothing to gain from seeing it late — the next tick supersedes it, or the moment has passed.
That is the Events branch, and its reward is no storage and no retention decision.

## The decision table

| You need | Channel | Why |
|---|---|---|
| Replay from the start | Stream | the log is retained; `XRANGE` reads from `-` |
| A reader that resumes after a crash | Stream | the consumer-group cursor / PEL survives the reader |
| An audit trail or event sourcing | Stream | every entry is stored with an ordered id |
| Time-travel to a past window | Stream | a mint instant becomes a range bound |
| Fan-out to many independent readers | Stream | each group keeps its own cursor over one log |
| Live "react now, no replay" | Events | at-most-once is enough; no storage cost |
| An ephemeral signal a present worker reads | Events | a control nudge, not a record |
| A presence ping / live progress tick | Events | the next message supersedes a missed one |

Read top to bottom, the table has a shape: durability is the heavy side and the table leans onto it. Five of
the rows are the Stream because most events a system cares about are records — things that happened, which
someone will eventually need to read. Only the genuinely ephemeral rows are Events.

## The default is the Stream

When the requirement is unclear, choose the Stream. The reasoning is asymmetric. A Stream can always feed a
live reaction too — append the entry, and a reader tailing the log with a blocking read reacts within a round
trip, so picking the Stream does not cost you liveness. But Events cannot become durable after the fact: a
message published with no subscriber is gone, and no later decision can recover it. Choosing the Stream keeps
the durable option open and still serves the live case; choosing Events forecloses durability.

EchoMQ made that choice for its own lifecycle. The system of record is the durable Stream; `EchoMQ.Events`
exists for live reaction on top of it. A consumer that must not miss a transition reads the Stream; a
dashboard that wants to *feel* live subscribes to Events and accepts that a dropped frame is a dropped frame.
The default is durable, and the exception is named.

## The worked fire-and-forget case — the cancel token

Not every fire-and-forget signal goes over the wire. The clearest worked case in EchoMQ is `EchoMQ.Cancel`, a
cooperative cancellation token — and it is fire-and-forget in the same shape Events is, one level in. It is a
control nudge to a worker that is running *now*, with no durability and no record, which is exactly why it is
not a Stream entry.

```elixir
def new, do: make_ref()                      # ← a token, no wire identity

def cancel(pid, token, reason \\ nil) when is_pid(pid) do
  send(pid, {:emq_cancel, token, reason})    # ← fire-and-forget: a mailbox message
  :ok
end

def check(token) do
  receive do
    {:emq_cancel, ^token, reason} -> {:cancelled, reason}   # ← only THIS token's cancel
  after
    0 -> :ok                                 # ← non-blocking: nothing waiting
  end
end
```

The token is a plain `make_ref()` — no branded id, nothing on the wire. `cancel/3` sends
`{:emq_cancel, token, reason}` to the handler's mailbox and answers `:ok`; the handler picks it up at its next
`check/1`, a non-blocking `receive after 0`. It is **cooperative**: a handler that never checks completes
normally, and the `^token` match ensures a handler only catches its own cancellation. A cancel sent to a
handler that has already finished is never read — lost, harmlessly, exactly like a publish with no live
subscriber. There is no record that a cancel was requested because no record is wanted: the question is only
"is a stop waiting for me right now," and the answer expires the moment the work ends.

Read against the table, the cancel token is the bottom rows made concrete: an ephemeral signal a present
worker reads, where a missed message means the work had already finished. If cancellation needed to be
durable, audited, or replayed — issued from another node and coordinated across the cluster — it would stop
being this token and become a recorded, distributed surface (that distributed cancel is a separate EchoMQ
concern). The local token stays fire-and-forget because that is the promise the job needs.

## The pattern, applied

In codemojex (`echo/apps/codemojex`) the two branches of the table run side by side in one round. A
round-scored event is a record — the score has to be replayable and auditable — so it is appended to the
durable Stream, and a feed reader replays or resumes over it. A "round closing, stop accepting guesses" nudge
to the worker handling the round is the other branch: an ephemeral control signal a present worker reads, with
no value to a reader who arrives later, so it travels as a cooperative cancel-style message rather than a
Stream entry. The score is remembered; the stop-signal is consumed and gone. Each event takes the channel its
promise calls for.

## References

### Sources

- [Valkey — Introduction to Streams](https://valkey.io/topics/streams-intro/) — replay, consumer-group
  resume, and the retained log the durable rows of the table pick.
- [Valkey — Pub/Sub](https://valkey.io/topics/pubsub/) — the at-most-once channel the ephemeral rows pick.
- [Valkey — XRANGE](https://valkey.io/commands/xrange/) — reading the log from `-` to replay, the property
  the Stream rows turn on.
- [Kreps — The Log: What every software engineer should know](https://engineering.linkedin.com/distributed-systems/log-what-every-software-engineer-should-know-about-real-time-datas-unifying)
  — why a durable log is the safe default for an event a reader may need later.

### Related in this course

- [R5.03 · Pub/Sub vs Streams](/redis-patterns/streams-events/pubsub) — the module hub.
- [R5.03.1 · Fire-and-forget vs durable](/redis-patterns/streams-events/pubsub/fire-and-forget-vs-durable) —
  the two promises the rule chooses between.
- [R5.03.3 · The dedicated blocking connection](/redis-patterns/streams-events/pubsub/the-dedicated-blocking-connection)
  — the cost of the Events branch.
- [R5.02 · Stream consumer patterns](/redis-patterns/streams-events/streams-consumer-patterns) — reading the
  Stream branch reliably.
- [/echomq/bus](/echomq/bus) — the EchoMQ Bus pillar: where the durable channel is taught in depth.
