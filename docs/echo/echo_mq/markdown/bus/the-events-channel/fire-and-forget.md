# Fire-and-forget — EchoMQ, In Depth (route mirror: `/echomq/bus/the-events-channel/fire-and-forget`)

> Route-mirror md for dive 03 of module 01. The HTML at
> `html/echomq/bus/the-events-channel/fire-and-forget.html` reflects this. All grounding is **real code** in
> `echo/apps/echo_mq/lib/echo_mq/events.ex` + `echo/apps/echo_mq/lib/echo_mq/cancel.ex`. No `[RECONCILE]`
> markers — every surface is real.

## Lede

The events channel makes no delivery promise. A publish with no live subscriber is gone, and so is one issued
in the gap between a socket drop and the reconnect. That is not a bug to fix — it is the contract, and the
durable receipt lives somewhere else.

## At-most-once, stated plainly

`PUBLISH` delivers to whoever is subscribed **at that instant**. There is no buffer, no replay, no
acknowledgement. So an event is delivered **at most once** to each subscriber, and possibly **zero** times:

- **No live subscriber.** If nothing is subscribed to `emq:{q}:events` when the publish lands, the message is
  dropped. `publish/5` reads `{:ok, 0}` from the wire and reports `:ok` — zero receivers is success, because
  the channel never promised one.
- **The reconnect window.** A listener's connection can drop and reconnect. In the gap between the drop and the
  connector re-issuing its `SUBSCRIBE`, the channel is momentarily unsubscribed, and any publish in that window
  is lost to that listener.

The moduledoc states this directly rather than papering over it: the push channel is fire-and-forget
(at-most-once); a publish with no live subscriber, or one issued in the window between a socket drop and the
resubscribe, is lost.

## The two mitigations — one for each loss

The loss has two causes, and each has its own answer:

1. **For the reconnect window — the resubscribe `MapSet`.** The connector remembers every channel it is
   subscribed to in a `MapSet` and re-issues `SUBSCRIBE` for all of them on reconnect. That shrinks the
   unsubscribed window to the reconnect latency: the feed comes back automatically, and a long-lived listener
   never has to re-subscribe by hand. It narrows the window; it does not replay what was missed inside it.
2. **For "I need the event to survive" — the stream log.** When an event must not be lost — replayed by a
   reader that was not running yet, audited, consumed at-least-once — you do not harden the channel. You write
   to the **stream log** (`EchoMQ.Stream`, module 02): an append-only, durable, replayable log. The events
   channel is the reflex; the stream is the memory. The same branded id threads both — an event names a `JOB`;
   a stream record IS an `EVT`.

So the design splits one concern in two: a fast, lossy broadcast for "react now," and a durable log for
"remember." Trying to make the broadcast durable would rebuild the log badly; the channel stays simple on
purpose.

## The control-plane sibling — `EchoMQ.Cancel`

The events channel is a fire-and-forget *signal* about work that happened. Its mirror on the control plane is
`EchoMQ.Cancel`: a fire-and-forget signal asking work to **stop**. Same posture — best-effort, no
acknowledgement, cooperative — but it carries **no wire identity** at all. The token is a plain `make_ref()`,
and cancellation is a process message to the worker's mailbox.

```elixir
# echo_mq — EchoMQ.Cancel (the worker-side cooperative cancel; NO wire identity)
# A token is a local make_ref(); cancellation is a process MESSAGE, not a wire op.
# Cooperative: a handler that never checks check/1 just completes normally.
@type t :: reference()

# mint a token — a unique reference identifying this cancellation
def new, do: make_ref()

# flag it cancelled: send {:emq_cancel, token, reason} to the worker's mailbox.
# best-effort, fire-and-forget — answers :ok regardless of what the worker does.
def cancel(pid, token, reason \\ nil) when is_pid(pid) do
  send(pid, {:emq_cancel, token, reason})
  :ok
end

# non-blocking check (O(1), `receive after 0`): is a cancel for THIS token waiting?
# the ^token match ensures a handler only catches its OWN cancellation.
def check(token) do
  receive do
    {:emq_cancel, ^token, reason} -> {:cancelled, reason}
  after
    0 -> :ok
  end
end
```

The mechanics make the "cooperative" word precise:

- **`new/0`** mints a `make_ref()` — globally unique within the node, never minted from the wire.
- **`cancel/3`** sends `{:emq_cancel, token, reason}` to a pid's mailbox and answers `:ok`. It does not stop
  anything; it asks. Best-effort, like a publish.
- **`check/1`** is a non-blocking `receive after 0`: it returns `{:cancelled, reason}` if a cancel for **this**
  token is already in the mailbox, else `:ok`. The `^token` pin means a handler only ever catches its own
  cancellation — a cancel for a different job sits untouched. `check!/1` is the same check that raises
  `EchoMQ.Cancel.Cancelled` instead, for a checkpoint-style handler that wants to abort by exception.

The token carries no wire identity because both ends are processes on the same node — the token is no more than a
shared reference. The defining property: a handler that **never calls `check/1` completes normally**. Cancellation is something
the worker chooses to honor at a safe point, between units of work — never a forced kill mid-transaction. That
is why it is "cooperative," and why it needs no wire identity: both ends are processes on the same node, and
the token is just a shared reference.

(This is the **worker-side** primitive only. A cancel issued from another node and coordinated across the
cluster is a different, larger surface, beyond this module.)

## The interactives — the loss and the cooperative stop

The first figure is the at-most-once delivery model: a slider for the number of live subscribers (0…N) and a
toggle for "publish during the reconnect window." Publish and read the receiver count and which subscribers
got the message — with the count at 0, or during the window, the message is shown lost, and the readout names
the right mitigation for that case (resubscribe for the window, the stream for durability).

The second figure is the cancel handshake over a fixed token: `new/0` mints it, a worker loops over units of
work calling `check/1` at each checkpoint, and a `cancel/3` drops `{:emq_cancel, token, reason}` into the
mailbox. Step it to see the worker run to its next checkpoint, then catch the cancel and stop — and a "never
checks" variant that runs to completion despite the pending cancel, making "cooperative" literal.

## Bridge — pattern and implementation

- **The pattern (Redis Patterns Applied).** Fire-and-forget messaging trades delivery guarantees for
  simplicity and speed; durability, when needed, is a separate, deliberate mechanism (an append-only log).
- **The implementation (echo_mq).** `EchoMQ.Events` is at-most-once on `emq:{q}:events` (the resubscribe
  `MapSet` narrows the reconnect window; the stream is the durable receipt), and `EchoMQ.Cancel` is its
  control-plane twin — a cooperative, no-wire-identity `make_ref()` signal a handler honors at a checkpoint.

Takeaway: fire-and-forget is a choice, not a defect. Keep the broadcast and the cancel simple; put durability
in the log that is built for it.

## Recap

The events channel is **at-most-once**: a publish with no live subscriber, or one in the reconnect window, is
lost. The resubscribe `MapSet` narrows the window; the **stream log** (module 02) is the durable receipt.
`EchoMQ.Cancel` is the control-plane sibling — a worker-side cooperative cancel with no wire identity: `new/0`
mints a `make_ref()`, `cancel/3` sends `{:emq_cancel, token, reason}` to the worker's mailbox, `check/1` is a
non-blocking check a handler honors at a safe point, and a handler that never checks completes normally. Next,
the pillar moves from the reflex to the memory: the stream log.

## References

### Sources
- Valkey — PUBLISH (`https://valkey.io/commands/publish/`) — delivers to current subscribers only; its reply is
  the receiver count, which can be zero.
- Valkey — Introduction to Streams (`https://valkey.io/topics/streams-intro/`) — the durable, replayable log the
  stream module builds on, the answer to at-most-once loss.
- Valkey — Cluster specification (`https://valkey.io/topics/cluster-spec/`) — the `{q}` hashtag keeps the events
  channel and the durable stream co-located.

### Related in this course
- The events channel (`/echomq/bus/the-events-channel`) — the module hub.
- Subscribe and handle (`/echomq/bus/the-events-channel/subscribe-and-handle`) — the listener whose feed the
  resubscribe keeps live.
- Publish after the verdict (`/echomq/bus/the-events-channel/publish-after-the-verdict`) — the best-effort
  publish whose loss this dive characterizes.
- The Bus (`/echomq/bus`) — the pillar; the stream log (module 02) is the durable receipt.
- Cancellation & checkpoints (`/echomq/queue/lifecycle-controls/cancellation-and-checkpoints`) — `EchoMQ.Cancel`
  applied to a long-running job in the Queue.
- Echo Persistence (`/echo-persistence`) — where the durable log ultimately folds to disk.
