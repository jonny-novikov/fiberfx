# The Bus — EchoMQ, In Depth (route mirror: `/echomq/bus`)

> Route-mirror md for the Bus chapter **landing**. The HTML at `html/echomq/bus/index.html` reflects this.
> All grounding is **real code** in `echo/apps/echo_mq` + `echo/apps/echo_store` — the Stream Tier (emq3.1–emq3.6)
> shipped 2026-06-23 and is on disk. This chapter carries **no `[RECONCILE]` markers**: every surface is real.
> Manuscript figure home: `docs/echo/bcs/bcs.3.md` §B3.3 (the Stream Tier).

## Thesis

The Bus is the second pillar: **broadcast signals over the wire**. Where the Queue distributes work — one job, one
worker, claimed and completed once — the Bus does the opposite: it **fans a message out to everyone**, and it **keeps
an ordered, replayable log** that many readers consume at their own pace. Two surfaces, one wire:

- **Events** (`EchoMQ.Events`) — fire-and-forget pub/sub. A consumer reacts to work as it happens (`completed`,
  `failed`, `progress`, `stalled`) without polling the sets. At-most-once: a publish with no live subscriber is gone.
- **The stream log** (`EchoMQ.Stream`) — an append-only log, **ordered by append the way the store is ordered by
  mint**. It is durable in Valkey, replayable from the head, consumed by groups with at-least-once delivery, readable
  by a mint instant (time-travel), bounded by a retention policy, and — what it trims — folded into the durable Graft
  floor so deep history survives without resident memory.

The thread through both is the **branded id**. An event names a `JOB`; a stream record IS an `EVT` — minted host-side,
appended in mint order, stored as the entry's `id` field so a polyglot reader recovers the canonical receipt without
re-encoding. The protocol lives below the language line, so the read side is reachable from any runtime that speaks the
wire — the course teaches the canonical Elixir.

## The two surfaces (the framing interactive)

Pick a surface to read what it is, the verb it runs, the Valkey command beneath, and its delivery guarantee.

- **Events** — `EchoMQ.Events.publish/5` → `PUBLISH emq:{q}:events`. Delivery: **at-most-once** (fire-and-forget; no
  live subscriber means the signal is lost). The mitigation for a dropped feed is the connector's reconnect
  resubscribe; the durable replayable receipt is the stream, not this.
- **Append** — `EchoMQ.Stream.append/4` → `XADD emq:{q}:stream:<name>`. Mints an `EVT` id host-side, appends it under
  its explicit id derived by field correspondence; returns `{:ok, branded}` — the branded id IS the receipt. A
  mint-order violation surfaces as `{:error, :nonmonotonic}`, never swallowed.
- **Consume** — `EchoMQ.StreamConsumer` → `XREADGROUP … >` on its own lane. Delivery: **at-least-once** with
  idempotent handlers; a crash re-delivers. A consumer that restarts resumes its own PEL, then reads new entries.
- **Time-travel** — `EchoMQ.Stream.read_window/6` / `read_since/5` → `XRANGE` over a `%DateTime{}` bound. A datetime
  becomes an id range bound (`minid_floor/1`/`maxid_ceil/1`); read the log as it stood at an instant, for backtest /
  audit / debug.
- **Retain** — `EchoMQ.Stream.trim/4` → `XTRIM MAXLEN|MINID`. Bound the log by length or age; the named, opt-in
  `EchoMQ.StreamRetention` driver re-applies a declared policy on a beat.
- **Archive** — `EchoStore.StreamArchive.fold/3` → the Graft floor → Tigris. Trimmed segments fold into CubDB's
  append-only B-tree at a reserved high page range, readable beside the live tail through a watermark merge-read.

## The modules

1. **The events channel** (`/echomq/bus/events`) — `EchoMQ.Events`: the one-time subscribe to `emq:{q}:events`, the
   host-side `publish/5` after a transition's verdict, the substring-scan `event_name/1` read, the subscriber-pid and
   `handle_event/3` handler delivery shapes, the at-most-once posture and the reconnect resubscribe mitigation.
2. **The stream log** (`/echomq/bus/the-stream-log`) — `EchoMQ.Stream.append/4`: the host-side `EVT` mint, the explicit
   `XADD` id by field correspondence, the order theorem (stream order == id sort == mint order, held by the
   single-writer monotone cell), the claims-only `id`-field contract, the `{:error, :nonmonotonic}` liveness signal.
3. **Consumer groups** (`/echomq/bus/consumer-groups`) — `EchoMQ.StreamConsumer`: the lazy `XGROUP CREATE … MKSTREAM`
   door (declared `:group_start`, swallow only `BUSYGROUP`), the drain-PEL-first → `>` → `XAUTOCLAIM` loop (recover
   self, then reclaim dead peers), the exact-mirror handler `%{id, payload, attempts, group}`, at-least-once and the
   PEL re-claim ordering exception that makes idempotence mandatory, the private-lane blocking read.
4. **Time-travel** (`/echomq/bus/time-travel`) — `EchoMQ.Stream.read_window/6` / `read_since/5`: the mint-instant read,
   `minid_floor/1` (`"<ms>-0"`, the half-open lower floor) and `maxid_ceil/1` (`"<ms>-<0x3FFFFF>"`, the inclusive upper
   inverse), the exact window edges, zero new Lua (host-issued `XRANGE`).
5. **Retention & the archive** (`/echomq/bus/retention-and-archive`) — `EchoMQ.Stream.trim/4` (`MAXLEN`/`MINID`, the
   safe `~` approximate default vs the `=` exact opt-in, the bounded blast radius INV), `EchoMQ.StreamRetention` (the
   opt-in BEAM-side policy driver), and `EchoStore.StreamArchive.fold/3` — the reserved `2^49` page range, the branded
   `EVT` watermark `W`, the fold-before-trim no-loss ordering, the merge-read split on `W` → the door to Echo
   Persistence.
6. **Workshop** (`/echomq/bus/workshop`) — publish an event and watch a subscriber react; append to a stream and read
   it back by a mint instant; declare a retention window and watch the trim fold a segment into the durable floor.

## Cooperative cancellation (a worker-side primitive)

`EchoMQ.Cancel` is the cooperative cancellation token a long-running handler checks at a safe point: `new/0` mints a
`make_ref()`, `cancel/3` sends `{:emq_cancel, token, reason}` to the handler's mailbox, `check/1` is a non-blocking
`receive after 0`. It is host-side with **no wire identity** — a handler that never checks completes normally; the
`^token` match ensures a handler only catches its own cancellation. This is the **worker-side** primitive; the
**distributed** cancel — issued from another node, coordinated across the cluster — is a separate surface beyond this
pillar.

## Redis Patterns Applied (the reverse door)

This is the depth behind the `/redis-patterns` chapter that doors here: **R5 · Streams & Events** — distributed events
and cancel over the bus land in this pillar; the stream patterns (the log, consumer groups, event sourcing) are exactly
what this pillar's log makes concrete. (R5 not yet built — `<strong>`-named, not linked.) There the pattern is the
door; here is the wire.

## The durable floor (the door to Echo Persistence)

A log that only grows is a leak, so retention is a policy, not a default — and what a stream trims is not lost.
`EchoStore.StreamArchive` folds the trimmed segments into the durable `EchoStore.Graft` floor — CubDB's append-only
B-tree, on to Tigris object storage behind a create-only commit fence — at a reserved high page range disjoint from
business pages, ordered by the branded `EVT` id so a forward scan reads oldest-first with no second index. The
merge-read splits on the watermark `W`: records at or below `W` come from the archive, records above it from the live
tail. Deep history without resident memory, readable beside the live tail. That floor is taught in full in Echo
Persistence (`/echo-persistence`), narrated in the manuscript at `docs/echo/bcs/bcs.3.md` §B3.3.

## References

### Sources
- Valkey — Introduction to Streams (`https://valkey.io/topics/streams-intro/`) — the append-only log and consumer
  groups the stream tier is built on.
- Valkey — Cluster specification (`https://valkey.io/topics/cluster-spec/`) — the `{q}` hashtag forces a queue's keys,
  the stream included, onto one of 16384 slots.
- Kreps — The Log (`https://engineering.linkedin.com/distributed-systems/log-what-every-software-engineer-should-know-about-real-time-datas-unifying`)
  — the log as the unifying abstraction beneath a stream.
- Lamport — Time, Clocks, and the Ordering of Events (`https://dl.acm.org/doi/10.1145/359545.359563`) — the
  happens-before the mint order and the time-travel read order by.

### Related in this course
- The Queue (`/echomq/queue`) — distribute work; the first pillar over the same wire.
- The Protocol (`/echomq/protocol`) — the braced keyspace and the branded-id gate the stream keys are born to.
- Overview (`/echomq/overview`) — the chapter that frames the three pillars.
- Echo Persistence (`/echo-persistence`) — the durable floor a trimmed stream history folds into.
- The Branded Component System — the bus (`/bcs/bus`) — the manuscript chapter (B3) this pillar realizes.
