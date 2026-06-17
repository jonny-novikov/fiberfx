# B4.2.2 · The Broadcast Lane

> Dive 2 of B4.2 · route `/bcs/cache/coherence-by-mint-time/the-broadcast-lane` · teaches `content/bcs4.2.md`
> (What: the broadcast lane, the loss gated) · reads gates F3–F4 of `bcs_rung_4_2_check.out`.

One PUBLISH hop, and the loss stated as a gate.

A coherence write publishes on the table's channel; every node's table holds a RESP3 subscription and applies
pushes in its owner. The substrate's contract is stated by its own documentation — Valkey pub/sub is
at-most-once, "a message will be delivered once if at all" — so the lane is fast and lossy by construction. The
rung derives the band first, measures inside it, and then states the loss as a gate of its own: a table that
declared the job lane holds no subscription, and the broadcast passes it by.

## §1 The transcript

The derive line and gates F3–F4, verbatim (source:
`content/echo_data/runtimes/elixir/bcs_rung_4_2_check.out`; the record opens with F1–F2 and continues through
F6 — the hub holds it whole):

```
…
derive (broadcast): the lane is one PUBLISH hop on the wire whose committed sequential floor is 29,456 round trips per second, near 34 us each -- expect a median push latency between 30 and 500 us, and the receiver's apply is one ETS comparison on top
F3 broadcast ok -- median push latency 72 us over 100 messages, inside the derived band; the cross-node round trip holds -- the writer put px=106.00, 3 subscribers heard the name, and the other node's next read fell through its dropped L1 to the shared L2 and answered fresh
F4 loss ok -- the price of fire-and-forget, stated as a gate: :qc declared the job lane and holds no subscription, so the broadcast passed it by and it still serves px=100.00 -- bounded staleness until its own lane delivers, which is the next gate's business
…
PASS 6/6
```

## §2 The cross-node round trip

The derive line is the chapter's evidence ethic in one move: the lane is one PUBLISH hop on a wire whose
committed sequential floor is 29,456 round trips per second, near 34 us each, so the band is 30 to 500 us — and
the measurement landed at `median push latency 72 us over 100 messages, inside the derived band`. The round
trip the gate closes runs writer to reader across nodes: the writer put px=106.00, the push crossed the wire,
and the other node's next read fell through its dropped L1 to the shared L2 and answered fresh.

The receiver never refetches on the push itself: an invalidation drops the L1 row, and the next read pays the
normal cache-aside path against an L2 the writer already updated. Coherence drops; it never writes — a message
means *the writer already placed the newer value in L2*, and the receiver's only move is to discard its older
L1 copy. A receiver that wrote values carried by rumor would make every subscriber a writer, and the lane
carries names, not rows.

## §3 The loss, gated

Fire-and-forget is a price, and the record pays it in the open: a table that declared the job lane holds no
subscription, so `the broadcast passed it by and it still serves px=100.00 -- bounded staleness until its own
lane delivers`. A missed broadcast costs one TTL of staleness — exactly the 4.1 bound — which is why the
broadcast lane is declared per surface rather than assumed. The boundary is inherited whole: at-most-once,
unpersisted, lost on disconnect — a node that reconnects has missed what it missed, the TTL bounds the damage,
and resubscription rides supervision (the table restarts, the subscription returns; auto-resubscribe inside the
connector is a carried knob, not a shipped feature).

Declare `:broadcast` when staleness is tolerable but a tighter bound is cheap value — the lane costs one
subscription per table per node and 72 microseconds per message. Declare `:none` when the TTL already says
everything true. When at-least-once is a requirement, the next dive's lane carries the same twenty-nine bytes
with a guarantee — the priced pair on the record's last row: `broadcast median 72 us fire-and-forget, job lane
median 148 us at-least-once -- the guarantee costs 2.1 times the latency`.

## References

Sources:

- Valkey — Pub/Sub — https://valkey.io/topics/pubsub/ (the lane's contract taken whole: at-most-once,
  unpersisted, "a message will be delivered once if at all")
- Valkey — Client-side caching — https://valkey.io/topics/client-side-caching/ (the comparison set's
  invalidation messages: deletion-shaped, no version, no order)
- Lamport, L. — Time, Clocks, and the Ordering of Events in a Distributed System —
  https://dl.acm.org/doi/10.1145/359545.359563 (the order that makes a dropped-row protocol safe)

Related:

- /bcs/cache/coherence-by-mint-time — B4.2 · the module hub; the full rung in context
- /bcs/cache — B4 · EchoCache, the chapter landing
- /bcs/bus — B3 · The Bus, the wire the push frames share
- /bcs/elixir-core/property-stores — B2.2 · Property Stores on ETS, the owner the applies run in
- /echomq — EchoMQ, the protocol in rung-level depth
- /redis-patterns — Redis Patterns Applied, the pub/sub substrate
- /elixir — Functional Programming in Elixir, the umbrella

Pager: previous `/bcs/cache/coherence-by-mint-time/the-twenty-nine-bytes` · next
`/bcs/cache/coherence-by-mint-time/the-job-lane`.
