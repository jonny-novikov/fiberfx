# Time is the address

> Route: `/echomq/bus/time-travel/time-is-the-address` · Pillar II — the Bus · Module 04, dive 01.
> Grounds in `EchoMQ.Stream.minid_floor/1` + `maxid_ceil/1` (`echo/apps/echo_mq`). As-shipped, no version labels,
> no `file:line`, **no Lua**.

## A wall-clock instant is an exact id position

The order theorem (the stream-log module) proved that, within one brand, **byte-order == snowflake-order == mint
order**. A consequence falls straight out of it: a `%DateTime{}` is not something you search the log for; it maps to
an **exact position** in the id space. Every entry id is `"<ms>-<seq>"` — a millisecond and a 22-bit `node|seq` tail.
So a time `dt` becomes a pair of bounds, and the half-open and inclusive edges are each *exact*, not approximate.

The two edges are inverses of one another, and they are the entire mechanism:

- `minid_floor(dt)` → `"<ms>-0"` — the **smallest** id at or after `dt`. The `ms` is the true Unix-millisecond of
  `dt` (`DateTime.to_unix(dt, :millisecond)`), and the tail `-0` is the lowest sequence at that millisecond. This is
  the **half-open lower edge**: `XRANGE` with this `from` excludes every entry minted in an *earlier* millisecond and
  includes everything at `dt` onward — a `dt − 1ms` entry is **out**, a `dt` entry is **in**.
- `maxid_ceil(dt)` → `"<ms>-<0x3FFFFF>"` — the **largest** id mintable at or before `dt`. The same true `ms`, and the
  tail `0x3FFFFF` is the maximal 22-bit `node|seq` (the ceiling of the snowflake's `node|seq` slice). This is the
  **inclusive upper edge**: `XRANGE` with this `to` admits every entry whose mint millisecond is `≤ dt` (any sequence
  at that ms is `≤ 0x3FFFFF` by construction) and excludes the first entry of `dt + 1ms` — a `dt` entry reads back, a
  `dt + 1ms` entry does **not**.

## The floor and the ceil, extracted

The real `minid_floor/1` and `maxid_ceil/1` — the two halves of the address arithmetic. Note what they share: the
*same* `ms` derivation; they differ only in the tail (`0` vs the maximal `0x3FFFFF`), which is exactly what makes one
the half-open lower edge and the other the inclusive upper edge.

```elixir
# echo_mq — EchoMQ.Stream
# The maximal 22-bit `node|seq` tail (0x3FFFFF) — the largest seq an xadd id can
# carry at one millisecond. It is the ceiling maxid_ceil/1 uses; minid_floor/1
# uses 0, the floor. The two edges differ ONLY in this tail.
@max_seq 0x3FFFFF

# The MINID floor id "<ms>-0" for a horizon dt: the smallest entry id at or after
# the instant. ms is the true Unix-ms of dt; the tail -0 is the lowest sequence
# at that ms. The half-open [dt, …) lower edge is EXACT: a dt-1ms entry is OUT,
# a dt entry is IN. NEVER a raw snowflake integer to the wire — the wire wants ms-seq.
def minid_floor(%DateTime{} = dt) do
  ms = EchoData.Snowflake.unix_ms(EchoData.Snowflake.min_for(dt))
  "#{ms}-0"
end

# The INCLUSIVE upper-bound id "<ms>-#{@max_seq}" for a window end dt — the inverse
# of minid_floor/1, the LARGEST id mintable at or before dt. The SAME true ms; the
# seq is the maximal tail (0x3FFFFF). So XRANGE … "<ms>-#{@max_seq}" admits every
# entry whose mint ms is <= dt and excludes the first entry of dt+1ms: the inclusive
# [.., dt] edge is EXACT — a dt entry reads back, a dt+1ms entry does not.
def maxid_ceil(%DateTime{} = dt) do
  ms = EchoData.Snowflake.unix_ms(EchoData.Snowflake.min_for(dt))
  "#{ms}-#{@max_seq}"
end
```

The `ms` is computed the same way in both: `Snowflake.unix_ms(Snowflake.min_for(dt))`, which equals
`DateTime.to_unix(dt, :millisecond)` — the instant's true millisecond, carried straight into the bound. Nothing about
the id space is reverse-engineered at read time; the bound is **derived** from the instant and the known layout of the
snowflake.

## Why exact, and not "close enough"

The edges are exact for one structural reason: **the stream is mint-ordered, and one brand makes byte-order ==
snowflake-order**. Were two brands interleaved on a stream, byte-order would no longer equal mint-order across them,
and a millisecond bound would no longer cleanly separate "before `dt`" from "at `dt`." The kind door that admits a
single brand (`EVT`) per stream is what keeps the time address sound. The address arithmetic and the kind door are the
same theorem read from two sides.

## The discipline: ms-seq to the wire, never the raw integer

A snowflake is a 63-bit integer; the wire wants `"<ms>-<seq>"`. Handing a raw snowflake integer to `XRANGE` would be a
silent malformation — the bound would be wrong in a way the single-node store would not loudly reject. `minid_floor/1`
and `maxid_ceil/1` exist precisely to hold that discipline: they translate an instant into the wire's `ms-seq` shape,
and nothing else touches a bound. This is the same class of care the trim path takes for `MINID` — the floor id is
always the formatted `ms-seq`, never the integer behind it.

## The interactive

A slider sweeps a `%DateTime{}` across a fixed row of mint-ordered `EVT` entries. As it moves, the readout shows the
two bounds it compiles to — `minid_floor(dt)` = `"<ms>-0"` and `maxid_ceil(dt)` = `"<ms>-<0x3FFFFF>"` — and which
entries fall in versus out, demonstrating the exact half-open/inclusive edges over a fixed dataset (no wire).

## Pattern & implementation

- **The pattern (Redis Patterns Applied):** a time-range query over a stream uses the entry's `ms-seq` id as the
  range bound; `XRANGE start end` is half-open/inclusive on the ids you give it.
  [Streams & Events](/redis-patterns/streams-events) teaches the time-range read.
- **The implementation (echo_mq):** `minid_floor/1` and `maxid_ceil/1` *derive* those bounds from a `%DateTime{}` —
  the floor the half-open lower edge, the ceil the inclusive upper inverse — so a wall-clock instant is an exact id
  position, sound because the stream is mint-ordered under one brand.

## Recap

A `%DateTime{}` is an exact address into a mint-ordered log. `minid_floor/1` gives the half-open lower edge `"<ms>-0"`;
`maxid_ceil/1` gives the inclusive upper edge `"<ms>-<0x3FFFFF>"` from the same true millisecond. Both are exact
because one brand makes byte-order equal mint-order, and both speak the wire's `ms-seq` shape rather than a raw
integer. The next dive uses the two edges to build the two reads.

## References

### Sources
- [Valkey — XRANGE](https://valkey.io/commands/xrange/) — the `start`/`end` id bounds the floor and ceil become.
- [Valkey — Introduction to Streams](https://valkey.io/topics/streams-intro/) — the `ms-seq` entry id layout the bounds are expressed in.
- [Lamport — Time, Clocks, and the Ordering of Events](https://dl.acm.org/doi/10.1145/359545.359563) — the order the id encodes.

### Related in this course
- `/echomq/bus/the-stream-log/the-order-theorem` — the theorem that makes the address exact.
- `/echomq/bus/time-travel/the-two-reads` — the floor and ceil composed into `read_since/5` and `read_window/6`.
- `/echomq/bus/time-travel` — the module hub.
- `/bcs/bus` — the manuscript chapter (B3) this module realizes.
