# Time-travel

> Route: `/echomq/bus/time-travel` · Pillar II — the Bus · Module 04 (hub).
> Grounds entirely in `EchoMQ.Stream` (`echo/apps/echo_mq`) — `read_window/6`, `read_since/5`, `minid_floor/1`,
> `maxid_ceil/1`. As-shipped, dark-editorial, no version labels, no `file:line`, **no Lua** (the reads delegate to
> the byte-frozen `read/6` → `XRANGE`).

Module 03's consumer group reads the log **forward** — `XREADGROUP … >` hands you new entries as they arrive.
Module 04 reads the log **backward in time**: a **historical window** selected by a wall-clock instant. *What did the
log look like between 14:30 and 14:32?* is a single bounded read.

This is the **order theorem** (module 02) cashed out. Because the stream is ordered by mint — and because one brand
(`EVT`) makes byte-order equal snowflake-order equal mint-order — a `%DateTime{}` is not a thing to *scan for*; it is
an **exact id position**. So a time window is a **range read, not a scan**: compute the lower and upper id bounds
host-side, hand them to the already-shipped `read/6` (`XRANGE`), and the entries come back already filtered, in mint
order. The whole feature is **id-math over a read that already exists** — zero new Lua, zero new wire surface.

Two shapes, one mechanism:

- **A closed window** `[t0, t1]` — `read_window/6`. "Between 14:30 and 14:32," both edges inclusive.
- **An open window** `[t0, ∞)` — `read_since/5`. "Everything since 14:30," up to the stream top.

The use cases are three, and the dive `backtest-audit-debug` works each: **backtest** a strategy over a past slice,
**audit** "what happened between X and Y," **debug** a past state without holding the window in memory.

## The framing interactive — a draggable window over a mint-ordered log

A row of mint-ordered `EVT` entries laid out on a time axis. The reader drags a window `[t0, t1]` across it and reads
back exactly the entries whose mint instant falls inside — and the two id bounds the window compiles to
(`minid_floor(t0)` … `maxid_ceil(t1)`). Toggling between the closed window and the open `[t0, ∞)` form shows the upper
bound switch from `maxid_ceil(t1)` to `+` (the stream top). The point the figure makes visible: **the window is the
bounds; the bounds are exact; the read is `XRANGE`.**

## The three dives

1. **Time is the address** (`time-is-the-address`) — the mechanism. `minid_floor(dt)` → `"<ms>-0"` is the exact
   half-open lower edge (a `dt − 1ms` entry is out, a `dt` entry is in); `maxid_ceil(dt)` → `"<ms>-<0x3FFFFF>"` is the
   exact inclusive upper edge (a `dt` entry reads back, a `dt + 1ms` entry does not). Exact **only because** the stream
   is mint-ordered and one brand makes byte-order == snowflake-order. Never a raw snowflake integer to the wire — the
   wire wants `ms-seq`.
2. **The two reads** (`the-two-reads`) — the surface. `read_since(conn, q, name, t0)` → `[t0, ∞)` (`from =
   minid_floor(t0)`, `to = "+"`); `read_window(conn, q, name, t0, t1)` → `[t0, t1]` (`from = minid_floor(t0)`, `to =
   maxid_ceil(t1)`). Both **delegate to the byte-frozen `read/6`** and return `{:ok, [{branded, fields_map}]}` in mint
   order. `read_window` **raises** `ArgumentError` before any wire on an inverted window (`t1` strictly before `t0`).
3. **Backtest, audit, debug** (`backtest-audit-debug`) — the application. Each use case is a `read_window/6` over a
   mint-instant interval, no resident memory of the window required. The codemojex angle (a page-own example, real
   brands): replay a round's `GES` guess events over its open→settle interval, folding them into the round's history.

## Redis Patterns Applied

This module is the depth behind **Redis Patterns Applied** — **R5 · Streams & Events**
(`/redis-patterns/streams-events`): the time-range read over an event log the pattern names, made concrete on the
wire as id-math over `XRANGE`. There the pattern is the door; here is the address arithmetic.

## The rest of the pillar

Module 03 (the consumer group) reads the live tail forward; module 04 reads a historical window by instant; module 05
(retention & the archive) bounds the live log and folds what it trims to the durable floor → **Echo Persistence**
(`/echo-persistence`). The mint-instant read here covers the **live log**; deep history beyond it is the archive's
merge-read, named here and built in module 05.

## References

### Sources
- [Valkey — XRANGE](https://valkey.io/commands/xrange/) — the range read both time-travel functions delegate to.
- [Valkey — Introduction to Streams](https://valkey.io/topics/streams-intro/) — the `ms-seq` entry id the bounds are expressed in.
- [Valkey — Cluster specification](https://valkey.io/topics/cluster-spec/) — the `{q}` hashtag co-locates a queue and its stream on one of 16384 slots.
- [Lamport — Time, Clocks, and the Ordering of Events](https://dl.acm.org/doi/10.1145/359545.359563) — the order a mint-instant read reads by.

### Related in this course
- `/echomq/bus/the-stream-log` — the order theorem that makes the address exact.
- `/echomq/bus/time-travel/time-is-the-address` — the floor/ceil id math.
- `/echomq/bus/time-travel/the-two-reads` — `read_since/5` and `read_window/6`.
- `/echomq/bus/time-travel/backtest-audit-debug` — the three use cases, worked on codemojex.
- `/echomq/bus` — the pillar landing.
- `/bcs/bus` — the manuscript chapter (B3) this module realizes.
