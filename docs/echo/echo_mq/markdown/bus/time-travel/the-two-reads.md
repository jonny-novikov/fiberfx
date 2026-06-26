# The two reads

> Route: `/echomq/bus/time-travel/the-two-reads` · Pillar II — the Bus · Module 04, dive 02.
> Grounds in `EchoMQ.Stream.read_since/5` + `read_window/6` (`echo/apps/echo_mq`). As-shipped, no version labels,
> no `file:line`, **no Lua**.

## Two windows, one read beneath

The previous dive built the address arithmetic: a `%DateTime{}` compiles to an exact id bound. This dive composes
those bounds into the two public reads. They differ only in the **upper** edge — one open, one closed — and both
**delegate to the byte-frozen `read/6`** (`XRANGE`). There is no new wire surface and no new Lua: time-travel is two
thin functions that pick bounds and hand off to a read that already shipped.

- `read_since(conn, queue, name, t0, count \\ nil)` → the **open** window `[t0, ∞)`. The lower bound is
  `minid_floor(t0)`; the upper bound is `"+"`, the stream top. "Everything at or after `t0`." The half-open lower edge
  is the exact one the floor already proves: a `t0` entry is in, a `t0 − 1ms` entry is out.
- `read_window(conn, queue, name, t0, t1, count \\ nil)` → the **closed** window `[t0, t1]`. The lower bound is
  `minid_floor(t0)`; the upper bound is `maxid_ceil(t1)`, the inclusive ceiling. "Between `t0` and `t1`, both ends in."

Both return `{:ok, [{branded, fields_map}]}` — the entries in **mint order**, each a `{branded EVT id, payload map}`
tuple, the branded id recovered from the stored `id` field. A connector or server fault surfaces as `{:error, term}`
verbatim, the same shape `read/6` already has.

## The two reads, extracted

The real `read_since/5` and `read_window/6`. Notice how little there is to either: each is a bound choice and a
delegation. `read_window/6` carries one extra guard — the inverted-window check — which it pays before computing any
bound.

```elixir
# echo_mq — EchoMQ.Stream
# OPEN window [t0, ∞): from = minid_floor(t0) (the half-open lower floor), to = "+"
# (the stream top). The common audit case — "everything at or after t0." Delegates
# to the byte-frozen read/6; ZERO new Lua.
def read_since(conn, queue, name, %DateTime{} = t0, count \\ nil)
    when is_binary(queue) and is_binary(name) do
  read(conn, queue, name, minid_floor(t0), "+", count)
end

# CLOSED window [t0, t1], both edges inclusive: from = minid_floor(t0), to =
# maxid_ceil(t1) (the inclusive upper inverse). Delegates to read/6; ZERO new Lua.
# RAISES ArgumentError before any wire on an INVERTED window (t1 strictly before
# t0) — a host-side guard, never a malformed bound to the wire.
def read_window(conn, queue, name, %DateTime{} = t0, %DateTime{} = t1, count \\ nil)
    when is_binary(queue) and is_binary(name) do
  if DateTime.compare(t1, t0) == :lt do
    raise ArgumentError,
          "EchoMQ.Stream.read_window requires t0 <= t1; got t0=#{DateTime.to_iso8601(t0)}, t1=#{DateTime.to_iso8601(t1)}"
  end

  read(conn, queue, name, minid_floor(t0), maxid_ceil(t1), count)
end
```

The `count` is an optional cap passed straight through to `read/6` (it becomes `XRANGE … COUNT n`) — useful for paging
a wide window without materializing all of it at once. When `nil`, the whole window comes back.

## The guard: an inverted window raises before the wire

`read_window/6` checks `t1 ≥ t0` *first*, and **raises `ArgumentError`** if not — before it computes a single bound,
before it touches the connector. An inverted window is a programming error, not a runtime condition to be handled, and
a malformed bound should never reach the wire. This is the same policy-before-existence discipline the append path
takes with its kind door and the trim path takes with its name guard: refuse the bad input at the host, loudly, rather
than ship a malformed command and let the store's behavior define the meaning. A valid `t0 == t1` window is allowed —
it is the degenerate closed window of a single millisecond.

## The window is a filter expressed as bounds

Conceptually, `read_window/6` over `[t0, t1]` returns exactly the entries you would get by reading the **whole** stream
and keeping each one whose branded `EVT` mint instant falls in `[t0, t1]`. But it does not read the whole stream and
filter in the host — it pushes the filter down to the store as the `XRANGE` bounds, so the store returns only the slice
and the host materializes only the slice. The bounds *are* the filter; the floor/ceil arithmetic is what makes that
push-down exact rather than approximate.

## The interactive

Pick a window form (closed `[t0, t1]` vs open `[t0, ∞)`) and an inverted-or-valid pair of instants. The readout shows
the `XRANGE` bounds each compiles to (`minid_floor(t0)` … `maxid_ceil(t1)` for closed; `minid_floor(t0)` … `+` for
open), whether the inverted case raises `ArgumentError` before the wire, and the mint-ordered entries returned over a
fixed dataset — the real branching of `read_window/6` and `read_since/5`, no wire.

## Pattern & implementation

- **The pattern (Redis Patterns Applied):** read a slice of an event log by a time range — open-ended ("since X") or
  closed ("between X and Y") — with `XRANGE` over the entry ids. [Streams & Events](/redis-patterns/streams-events)
  teaches the range read.
- **The implementation (echo_mq):** `read_since/5` (`[t0, ∞)`, `to = "+"`) and `read_window/6` (`[t0, t1]`, `to =
  maxid_ceil(t1)`) pick the bounds from `%DateTime{}`s and delegate to the byte-frozen `read/6`; `read_window/6` raises
  on an inverted window before any wire. No new Lua, no new wire surface.

## Recap

Two reads, one `XRANGE` beneath. `read_since/5` is the open window `[t0, ∞)`; `read_window/6` is the closed window
`[t0, t1]`, raising `ArgumentError` on an inverted pair before it touches the wire. Both return mint-ordered
`{branded, fields_map}` tuples and both delegate to the byte-frozen `read/6`. The next dive puts them to work:
backtest, audit, debug.

## References

### Sources
- [Valkey — XRANGE](https://valkey.io/commands/xrange/) — the range read both functions delegate to.
- [Valkey — Introduction to Streams](https://valkey.io/topics/streams-intro/) — the entry-id range semantics the window rests on.
- [Lamport — Time, Clocks, and the Ordering of Events](https://dl.acm.org/doi/10.1145/359545.359563) — the mint order the reads return in.

### Related in this course
- `/echomq/bus/time-travel/time-is-the-address` — the floor/ceil bounds these reads compose.
- `/echomq/bus/the-stream-log/the-claims-only-id` — the un-grouped `read/6` these delegate to.
- `/echomq/bus/time-travel/backtest-audit-debug` — the two reads applied.
- `/echomq/bus/time-travel` — the module hub.
- `/bcs/bus` — the manuscript chapter (B3) this module realizes.
