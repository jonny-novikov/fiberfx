# The stream log — module hub

> Route: `/echomq/bus/the-stream-log` · Pillar II, The Bus · module 02.
> Surface: `EchoMQ.Stream` + `EchoMQ.Stream.Id` (`echo/apps/echo_mq`). Dark-editorial. No version labels.
> No Lua on this pillar — `XADD` / `XRANGE` are issued direct through `EchoMQ.Connector`.

## Framing

Where module 01's events say a thing once and are gone, the stream **remembers**. The stream log is an
append-only record of what happened, ordered the way the store is ordered — by the branded id — and a reader can
replay it from any point at its own pace. The events channel is the present tense; the log is the past, kept.

One verb carries the whole idea. `EchoMQ.Stream.append(conn, queue, name, fields)`:

1. mints an `EVT`-branded record id **host-side** — `EchoData.Snowflake.next_branded("EVT")`. The writer owns the
   mint, so there is nothing to spoof.
2. derives the explicit `XADD` entry id from that branded id by field correspondence (`Stream.Id.xadd_id/1` →
   `"<ms>-<tail22>"`).
3. issues `XADD emq:{q}:stream:<name> <xadd_id> id <branded> <fields…>` **direct** — no Lua, no new script. The
   14-byte branded string is stored as the stream's `id` field (the claims-only contract).
4. returns `{:ok, branded}`. The branded id is the **receipt**.
5. maps Valkey's `id≤top` rejection to `{:error, :nonmonotonic}` — never swallowed, never retried with `*`.

The key is `emq:{q}:stream:<name>`, built by the shipped total `EchoMQ.Keyspace.queue_key(queue, "stream:" <>
name)` — the stream shares the queue's `{q}` hashtag slot, so a queue and its stream co-locate on one of Valkey
Cluster's 16384 slots.

## What holds it: the order theorem

Stream order == id sort == mint order. That equality is what makes the log replayable in the order things
happened without a second index — and it is proven **by construction** in `EchoMQ.Stream.Id`, not by example:

- branded byte order == snowflake integer order (the order-preserving Base62 codec, **within one namespace** —
  which is why the kind door admits exactly one brand, `EVT`, per stream);
- the `XADD` id is an order-preserving image of the snowflake (timestamp packed high, the `node|seq` tail low,
  no overlap).

A single writer's strictly-monotone mint cell means the next id always exceeds the stream top, so no `XADD`
rejection is possible. A multi-writer violation surfaces honestly as `{:error, :nonmonotonic}`.

## The three dives

1. **The host-side mint** (`the-host-side-mint`) — `append/4`: the host-side `EVT` mint, the A1 id derivation,
   the direct `XADD`, the receipt, and the kind door that raises before the wire.
2. **The order theorem** (`the-order-theorem`) — why stream order, id sort, and mint order are the same fact,
   proven by construction, and why a violation surfaces as `:nonmonotonic` rather than a silent retry.
3. **The claims-only id** (`the-claims-only-id`) — the branded id stored as the stream `id` field, the minimal
   `read/6` (`XRANGE`) read-back recovering `{branded, fields_map}` in mint order, and the forward doors:
   time-travel and the archive.

## Redis Patterns Applied

This module is the depth behind **Redis Patterns Applied · R5 · Streams & Events** (`/redis-patterns/streams-events`)
— the append-only-log pattern, event sourcing, and replay. There the pattern is the door; here is the writer.

## The contrast with module 01

The events channel (module 01) is fire-and-forget: a publish with no live subscriber is lost. The stream is the
durable receipt of the same idea — what an event forgets, the log keeps. An event tells you a thing is happening
now; the stream lets you ask, later, what happened and in what order.

## References

### Sources
- [Valkey — Introduction to Streams](https://valkey.io/topics/streams-intro/) — the append-only log `XADD` and `XRANGE` operate on.
- [Valkey — XADD](https://valkey.io/commands/xadd/) — the append, issued direct with an explicit entry id.
- [Valkey — Cluster specification](https://valkey.io/topics/cluster-spec/) — the `{q}` hashtag co-locates a queue and its stream on one of 16384 slots.
- [Kreps — The Log](https://engineering.linkedin.com/distributed-systems/log-what-every-software-engineer-should-know-about-real-time-datas-unifying) — the log as the unifying abstraction.

### Related in this course
- `/echomq/bus` — the pillar landing: the two surfaces of the Bus.
- `/echomq/bus/the-stream-log/the-host-side-mint` — the append, dive one.
- `/echomq/bus/the-stream-log/the-order-theorem` — why order is a theorem, dive two.
- `/echomq/bus/the-stream-log/the-claims-only-id` — the id field and the read-back, dive three.
- `/echomq/queue` — the Queue: distribute work over the same wire.
- `/echomq/protocol` — the keyspace and branded-id gate the stream keys are born to.
- `/bcs/bus` — the manuscript chapter (B3.3) this module realizes.
- `/redis-patterns/streams-events` — the pattern side of the log.
