# BCS · Chapter 1.5 — The time inside the name

<show-structure depth="2"/>

Every chapter so far has leaned on chronology without taking it as a subject. The order theorem turned keys into timelines, the storage chapter ranged stream windows by id arithmetic, the substrate paged newest-first with no clock in the process — time has been load-bearing on every page and examined on none. This chapter examines it: what the 41 bits in the layout promise, what they refuse to promise, the discipline the minter owes its clock, and the law that keeps the trading system from confusing the two kinds of time it will live with. The contract owns the bits; this chapter states the policy.

## Why

A trading platform runs on two times that look alike and are not. There is the moment an exchange says a fill happened — event time, owned by someone else's clock, carried as data, disputed in arbitration. And there is the moment this architecture first *named* the fill — identity time, owned by the minter, carried inside the id, readable forever through `unix_ms`. Conflating them is the subtle cousin of the second clock from Chapter 1.2: not a duplicate timestamp beside the id, but the id's timestamp doing a job it never promised to do. Part VIII cannot be written until the line is drawn, and the line is an idea, which makes it Part I's job.

## What

**The arithmetic, stated plainly.** The layout grants 41 bits of milliseconds above a 2024-01-01 epoch (`1704067200000`); 2⁴¹ milliseconds is about 69.7 years, so the timestamp field exhausts in September 2093. The horizon is recorded here rather than discovered later: a successor epoch is a contract amendment with a wire-version bump and a drain-and-switch lane — the same shape the EchoMQ migration already uses — and seventy years is enough runway to make that a planned chapter, never an incident.

**What identity time is.** Per node it is a strict total order — the minting law's counter never repeats and never reverses — and fleet-wide it is a coarse global order at millisecond grain with node concurrency inside each tick. It is also a free creation instant: the canonical pair in [`vectors.json`](../../contract/vectors.json) decodes `USR0NgWEfAEJfs` to `320636799581945856` and reads `unix_ms` as `1780512970164`, no column required. The measured record has exercised both faces: the substrate's gate paged a byte-sort desc over 2000 minted ids with no timestamp consulted, and the streams experiment addressed a ten-millisecond window purely by id arithmetic — 40960 entries (expected 40960), the first of them `1781000000010-28672`, an id readable by eye as time, node, and sequence [2].

**What identity time is not.** It is not event time, and the distinction has a fifty-year-old foundation. Lamport's 1978 result examined one event happening before another in a distributed system and showed the relation to "define a partial ordering of the events" [1] — order in a distributed system is a causal construction, not a reading of simultaneous wall clocks, and a timestamp minted *here* cannot testify about what happened *there*. The id's milliseconds answer exactly one question: when did this architecture first know this entity by name. When the fill occurred at the exchange, when the order was placed by the client, when the risk breach opened — those are claims under someone else's clock, and they travel as properties in a system's table, never as readings of the id. **The law of two clocks: identity time is the id's; event time is data.**

**The discipline the minter owes.** Within one millisecond the minting law already legislates: the counter excludes node bits, and a burst that drains the sequence borrows the next millisecond rather than a neighbor's space. This chapter makes the wall-clock corollary explicit as policy of record: the mint floor is monotonic — when the wall clock steps backwards (an NTP correction, a VM migration), the minter holds at or borrows above its last-issued millisecond and never re-issues a past one. Strict per-node monotonicity is not a property the layout grants; it is a property the clock discipline preserves, and the fleet operates accordingly (slewed corrections, monotonic sources, the floor rule).

**The store's clock is a third thing.** A TTL is the *store's* time — priced in Chapter 1.3 as embedded object growth (`brd14+ttl 14 128 99 29` on the measured table) and enforced by the engine's clock at expiry. The name's time is forever; the row's tenure is rented. Retention sweeps choose by id arithmetic, expiry executes by the store — two mechanisms, deliberately unmerged.

## Who

The trading desk's entities draw the line constantly: an `ORD` is named at acceptance (identity time) and executed at the exchange's stamp (event time, a property of the fill); a `RSK` breach is named when the engine first sees it and dated by the market data that triggered it. Audit answers "when did we first know" from the id alone; compliance answers "when did it happen" from the recorded event fields; replay teams address windows by `min_for` arithmetic at both ends; and operations owns the clock fleet the mint floor depends on.

## When

Reach for identity time when the question is about this architecture's own history: pagination, replay windows, retention cutoffs, first-seen audit, dedupe-by-recency. Reach for event time when the question belongs to another clock's jurisdiction: matching semantics, regulatory timestamps, PnL bucketing, anything an exchange or a client could dispute. The litmus is one question — *whose clock is authoritative for this claim?* — and the moment the answer is "not ours," the value is data beside the id, never arithmetic on it.

## Where

The contract owns the layout, the epoch, and the minting law; `vectors.json` owns the accessor truths; the streams record under `bench/valkey-id/` owns the window proof; Chapter 1.3's table owns the TTL price; this chapter owns the policy line the rest of the series cites.

## How — both sides of the law, in Elixir and in Go

**Identity time, as arithmetic.** A window over `ORD` names is two synthetic cursors, no clock consulted at read time:

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

**Event time, as data.** The other side of the law is a refusal: the exchange's stamp rides beside the name, typed as time, never encoded into one.

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

Same grammar both sides of the bus, and the same prohibition: nothing parses an id to answer an event-time question.

## Decisions

**The law of two clocks stands:** identity time is the id's, event time is data; every chapter after this one may cite the line instead of re-arguing it.

**The mint floor is monotonic, as policy of record:** a backwards wall clock holds or borrows, never re-issues — the minting law's burst rule generalized to the clock itself, with the fleet discipline (slew, monotonic sources) named as its operational half.

**The horizon is 2093 and recorded:** the successor epoch is a planned amendment riding the existing wire-version lane, not an emergency.

**No created-at beside an id for "first named":** `unix_ms` is the accessor, and a duplicate column is the second clock returning in disguise — event timestamps exempt by the first decision, because they were never duplicates.

## References

1. Lamport, L. — Time, Clocks, and the Ordering of Events in a Distributed System. Communications of the ACM, vol. 21 no. 7, July 1978 (happened-before as a partial order; order as construction, not simultaneous wall-clock reading): [dl.acm.org/doi/10.1145/359545.359563](https://dl.acm.org/doi/10.1145/359545.359563)
2. Valkey documentation — Streams introduction (entry ids carry the millisecond; ranges address time through the id): [valkey.io/topics/streams-intro](https://valkey.io/topics/streams-intro/)
