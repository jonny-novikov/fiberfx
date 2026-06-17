# B1.5.2 · The Law of Two Clocks — dive

Route: `/bcs/ideas/time-inside-the-name/the-law-of-two-clocks` · teaches manuscript chapter `content/bcs1.5.md`
(what identity time is, what it is not, and the How).

## Hero

Kicker: B1.5 · dive — the law of two clocks

H1: Identity time is the id's; event time is **data**.

Lede: A trading platform runs on two times that look alike and are not. The id's milliseconds answer exactly
one question: **when did this architecture first know this entity by name.** When the fill occurred at the
exchange, when the order was placed by the client, when the risk breach opened — those are claims under
someone else's clock, and they travel as properties in a system's table, never as readings of the id.

Heronote: Source: content/bcs1.5.md · What and How; the streams record under bench/valkey-id/ owns the window
proof; the rung 1.1 transcript owns the byte-sort proof.

Hero interactive: **two clocks, one litmus** — a selector over identity time, event time, and the litmus
question (*whose clock is authoritative for this claim?*), each reading out which questions that clock
answers and where its value lives. Pure lookup; static text readable without JS.

## §1 — What identity time is (content/bcs1.5.md · What)

Per node it is a strict total order — the minting law's counter never repeats and never reverses — and
fleet-wide it is a coarse global order at millisecond grain with node concurrency inside each tick. It is also
a free creation instant: the canonical pair in `vectors.json` decodes `USR0NgWEfAEJfs` to
`320636799581945856` and reads `unix_ms` as `1780512970164`, no column required.

The measured record has exercised both faces.

Frozen evidence 1 (content/echo_data/runtimes/elixir/bcs_rung_1_1_check.out · G4):

```
G4 ordered ok -- page_desc(2000) == byte-sort desc over 2000 minted ids; store holds no clock
```

Frozen evidence 2 (content/echo_data/bench/valkey-id/streams_bench.out):

```
window [+10ms, +20ms) via branded-derived ids: 40960 entries (expected 40960)
first id in window: "1781000000010-28672"  (low 22 bits = node 7 << 12 | seq 0 = 28672)
```

The substrate's gate paged a byte-sort desc over 2000 minted ids with no timestamp consulted; the streams
experiment addressed a ten-millisecond window purely by id arithmetic — 40960 entries (expected 40960), the
first of them `1781000000010-28672`, an id readable by eye as time, node, and sequence.

## §2 — What identity time is not (content/bcs1.5.md · What; Lamport 1978)

It is not event time, and the distinction has a fifty-year-old foundation. Lamport's 1978 result examined one
event happening before another in a distributed system and showed the relation to "define a partial ordering
of the events" — order in a distributed system is a causal construction, not a reading of simultaneous wall
clocks, and a timestamp minted *here* cannot testify about what happened *there*.

**The law of two clocks: identity time is the id's; event time is data.**

## §3 — Identity time, as arithmetic (content/bcs1.5.md · How)

A window over `ORD` names is two synthetic cursors, no clock consulted at read time:

```elixir
# Elixir — min_for: the smallest snowflake a millisecond can carry
min_for = fn ms -> Bitwise.bsl(ms - 1_704_067_200_000, 22) end
from = EchoData.BrandedId.encode!("ORD", min_for.(t0))
til  = EchoData.BrandedId.encode!("ORD", min_for.(t1))
```

```go
// Go — the same cursor, the same bytes
minFor := func(ms int64) uint64 { return uint64(ms-1704067200000) << 22 }
from := brandedid.MustEncode("ORD", minFor(t0))
til := brandedid.MustEncode("ORD", minFor(t1))
```

Interactive: **the cursor computer** — three fixed milliseconds, all committed: the streams window's two edges
(`1781000000010`, `1781000000020` — the same ten-millisecond window the bench addressed) and the decode
vector's millisecond (`1780512970164`). For each, the readout computes `(ms − 1704067200000) << 22` in BigInt —
the smallest snowflake that millisecond can carry. Static reading: `min_for(1780512970164)` is
`320636799581945856` — exactly the canonical vector's snowflake, because that vector carries node 0 and
sequence 0.

## §4 — Event time, as data (content/bcs1.5.md · How)

The other side of the law is a refusal: the exchange's stamp rides beside the name, typed as time, never
encoded into one.

```elixir
defmodule Fill do
  defstruct [:id, :order_id, :at_exchange]   # at_exchange: DateTime — their clock
end
```

```go
type Fill struct {
    ID         string    // FIL… — named when we first knew it
    OrderID    string    // ORD…
    AtExchange time.Time // their clock, our data
}
```

Same grammar both sides of the bus, and the same prohibition: nothing parses an id to answer an event-time
question. And the decision of record closes the loop: **no `created_at` beside an id for "first named"** —
`unix_ms` is the accessor, and a duplicate column is the second clock returning in disguise; event timestamps
are exempt, because they were never duplicates.

## References

Sources:
- Lamport — Time, Clocks, and the Ordering of Events in a Distributed System (1978):
  https://dl.acm.org/doi/10.1145/359545.359563 — happened-before "define[s] a partial ordering of the events".
- Valkey documentation — Streams introduction: https://valkey.io/topics/streams-intro/ — entry ids carry the
  millisecond; ranges address time through the id.

Related:
- `/bcs/ideas/time-inside-the-name` — the module hub.
- `/bcs/ideas/identity-contract` — B1.2, the order theorem and the second clock this law generalizes.
- `/bcs/ideas/id-system` — B1.3, the storage record the window proof extends.
- `/echomq` — the bus whose stream entry ids carry the millisecond.

## Pager

prev: `/bcs/ideas/time-inside-the-name/the-41-bit-horizon` (B1.5.1 · The 41-Bit Horizon) · next:
`/bcs/ideas/time-inside-the-name/the-floor-and-the-third-clock` (B1.5.3 · The Floor and the Third Clock)

Stamp: `BCS0NtfEw7hltQ` (decoded ts 2026-06-11 17:01:02 UTC)
