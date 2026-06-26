# Retention & the archive — the Bus, module 05

> Route: `/echomq/bus/retention-and-archive` · hub. Dark-editorial. Surface:
> `EchoMQ.Stream.trim/4` + `EchoMQ.StreamRetention` + `EchoStore.StreamArchive`. The Bus pillar's door to
> `/echo-persistence` in full. All real code (`echo/apps/echo_mq` + `echo/apps/echo_store`); no Lua on this
> pillar; no `[RECONCILE]` (the Stream Tier is shipped).

## The frame

A log that only grows is a leak. The Bus keeps an append-only log many readers replay — but an append-only
log appends forever, and memory is finite, so the live log has to be **bounded**. Retention is how: it caps
the live log by **length** (`MAXLEN`) or by **age** (`MINID`). The trap it refuses is the one that makes
retention dangerous in most systems — coupling a **safety** property (bounded memory) to a **liveness** fact
(a consumer happens to be up). Couple them and a stream nobody drains grows without bound; couple them the
other way and a slow consumer's lag silently deletes data it has not read. So the trim cadence lives on its
**own** beat, decoupled from any consumer.

And the second half is the whole point of this module: **what is trimmed is not lost.** Before a record
leaves the live stream it is **folded** into the durable Graft floor — committed to disk, kept, and readable
beside the live tail through a watermark merge-read. The result is a stream that is **bounded in memory but
deep in history**: the hot tail stays small, and the past stays queryable, with no resident memory of it.
That floor is the **persistence floor** — the door this module opens, in full, to `/echo-persistence`.

## The framing interactive — a log, a trim, a fold

A growing log on the wire; a trim sweep that bounds it; the trimmed segment sliding into the durable floor,
ordered by the branded id, where it is still readable. Step the three phases:

1. **The live log grows** — `EchoMQ.Stream.append/4` appends `EVT` records in mint order. Resident, fast,
   unbounded if nothing bounds it.
2. **A trim bounds it** — `EchoMQ.Stream.trim/4` issues `XTRIM MAXLEN | MINID`, removing the records outside
   the window. The `~` approximate default never over-trims (INV4).
3. **The fold keeps it** — before the trim, `EchoStore.StreamArchive.fold/3` folds the about-to-trim slice
   into the durable Graft floor (CubDB → Tigris) at a reserved page range; the merge-read serves the archive
   below the watermark `W` and the live tail above it, as one mint-ordered stream.

The take: retention is a policy, not a default — and the trimmed past folds to the floor, queryable beside
the present.

## The dives

Three dives:

1. **Retention is a policy** — `EchoMQ.Stream.trim/4`: the two windows (`MAXLEN` length, `MINID` age), the
   safe `~` default vs the exact `=` opt-in, INV4 (a trim can never delete inside the window), and the named
   opt-in `EchoMQ.StreamRetention` driver that re-applies a declared BEAM-side policy on its own beat,
   decoupled from consumer liveness.
2. **Nothing is lost** — `EchoStore.StreamArchive.fold/3`: the reserved `2^49` page range disjoint from
   business pages by construction, the branded-id-monotone fold (the order theorem reaching disk), the
   watermark `W` (a branded `EVT` id, never `head_lsn`), the merge-read split on `W`, and fold-before-trim as
   the no-loss ordering.
3. **The door to persistence** — the durability dial in depth: hold nothing · a bounded window + a
   checkpoint per K · commit-per-record + replicate off-box (Graft → Tigris); deep history without resident
   memory; the Oban comparison (the trade, not the coupling). The door to `/echo-persistence` + `/bcs/persistence`.

## Redis Patterns Applied (the reverse door)

This module is the depth behind the Redis Patterns Applied chapter that doors here:
[R5 · Streams & Events](/redis-patterns/streams-events) — the retention and the durable, replayable log that
land in this pillar, made concrete on the wire as `XTRIM` on the live log and a fold into the page engine.
There the pattern is the door; here is the floor.

## The durable floor (the door)

What a stream trims is not lost. `EchoStore.StreamArchive` folds the trimmed segments into the durable
`EchoStore.Graft` floor — CubDB's append-only B-tree, on to Tigris object storage — at a reserved page range
ordered by the branded `EVT` id, readable beside the live tail through a watermark merge-read. Deep history
without resident memory. That floor is taught in full at [Echo Persistence](/echo-persistence), and narrated
in the manuscript at [The Branded Component System · the persistence floor](/bcs/persistence).

## References

### Sources
- [Valkey — XTRIM](https://valkey.io/commands/xtrim/) — the trim that bounds the live log by `MAXLEN` or `MINID`.
- [Valkey — Introduction to Streams](https://valkey.io/topics/streams-intro/) — the append-only log retention bounds.
- [Valkey — Cluster specification](https://valkey.io/topics/cluster-spec/) — the `{q}` hashtag co-locates a queue and its stream on one of 16384 slots.
- [Kreps — The Log](https://engineering.linkedin.com/distributed-systems/log-what-every-software-engineer-should-know-about-real-time-datas-unifying) — the commit log whose retained, replayable form the archive extends to disk.

### Related in this course
- [Retention is a policy](/echomq/bus/retention-and-archive/retention-is-a-policy) — `trim/4`, the windows, the safe default.
- [Nothing is lost](/echomq/bus/retention-and-archive/nothing-is-lost) — the fold into the Graft floor and the merge-read.
- [The door to persistence](/echomq/bus/retention-and-archive/the-door-to-persistence) — the durability dial in depth.
- [Time-travel](/echomq/bus/time-travel) — reading the live log by a mint instant; deep history past it is the archive.
- [The Bus](/echomq/bus) — the pillar landing.
- [Echo Persistence](/echo-persistence) — the durable floor a trimmed stream history folds into.
- [The Branded Component System · the persistence floor](/bcs/persistence) — the manuscript chapter this module's floor realizes.
