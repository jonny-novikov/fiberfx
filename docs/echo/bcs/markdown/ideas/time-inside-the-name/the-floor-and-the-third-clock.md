# B1.5.3 · The Floor and the Third Clock — dive

Route: `/bcs/ideas/time-inside-the-name/the-floor-and-the-third-clock` · teaches manuscript chapter
`content/bcs1.5.md` (the discipline the minter owes + the store's clock).

## Hero

Kicker: B1.5 · dive — the floor and the third clock

H1: Hold, borrow, never **re-issue**.

Lede: Strict per-node monotonicity is not a property the layout grants; it is a property the clock discipline
preserves. **The mint floor is monotonic, as policy of record:** when the wall clock steps backwards — an NTP
correction, a VM migration — the minter holds at or borrows above its last-issued millisecond and never
re-issues a past one. And a TTL is a third clock entirely: the store's time, priced on the measured table and
deliberately unmerged from the name's.

Heronote: Source: content/bcs1.5.md · the discipline and the third thing; the TTL price is Chapter 1.3's
measured row (bench/valkey-id/valkey_id_bench.out).

Hero interactive: **the floor, exercised** — three fixed scenarios (an NTP step backwards, a VM migration, a
drained sequence), each computing the minter's next-issue floor as `max(wall, last-issued)` — hold at, borrow
above, or borrow the next millisecond. Pure arithmetic over fixed pairs; static text readable without JS.

## §1 — The discipline the minter owes (content/bcs1.5.md · What)

Within one millisecond the minting law already legislates: the counter excludes node bits, and a burst that
drains the sequence borrows the next millisecond rather than a neighbor's space. The wall-clock corollary,
explicit as policy of record: the mint floor is monotonic — when the wall clock steps backwards (an NTP
correction, a VM migration), the minter holds at or borrows above its last-issued millisecond and never
re-issues a past one. The fleet operates accordingly: slewed corrections, monotonic sources, the floor rule.

## §2 — The third clock: the store's (content/bcs1.5.md · What; Chapter 1.3's table)

A TTL is the *store's* time — priced in Chapter 1.3 as embedded object growth and enforced by the engine's
clock at expiry. The name's time is forever; the row's tenure is rented.

Frozen evidence (content/echo_data/bench/valkey-id/valkey_id_bench.out · the brd14 rows):

```
fmt keylen redis7 valkey81 saved
brd14 14 88 65 23
brd14+ttl 14 128 99 29
```

`brd14+ttl 14 128 99 29` — branded with EX 86400. On Valkey 8.1 the expire is 99 against 65 bytes per key: an
expire is +34 bytes of object growth, not a second table.

Interactive: **the price of the third clock** — a two-row selector over the measured table (`brd14` ·
`brd14+ttl`); the readout computes the per-key delta (99 − 65 = 34 bytes on Valkey 8.1) and names whose clock
the row now carries. Pure lookup + subtraction over the committed rows.

## §3 — Deliberately unmerged (content/bcs1.5.md · What + Decisions)

Retention sweeps choose by id arithmetic; expiry executes by the store — two mechanisms, deliberately
unmerged. The decisions of record this dive carries forward: **the mint floor is monotonic, as policy of
record** — the minting law's burst rule generalized to the clock itself, with the fleet discipline (slew,
monotonic sources) named as its operational half; and the litmus from the law of two clocks governs here too —
the store's clock answers tenure questions, the id's clock answers first-named questions, and neither
substitutes for the other.

## References

Sources:
- Lamport — Time, Clocks, and the Ordering of Events in a Distributed System (1978):
  https://dl.acm.org/doi/10.1145/359545.359563 — order as a construction the clock discipline must preserve.
- Valkey documentation — Streams introduction: https://valkey.io/topics/streams-intro/ — the store-side
  arithmetic the retention sweeps ride.

Related:
- `/bcs/ideas/time-inside-the-name` — the module hub.
- `/bcs/ideas/id-system` — B1.3, the measured table the TTL row sits on.
- `/bcs/ideas/identity-contract` — B1.2, the minting law whose burst rule the floor generalizes.
- `/redis-patterns` — the store-side patterns, taught applied.

## Pager

prev: `/bcs/ideas/time-inside-the-name/the-law-of-two-clocks` (B1.5.2 · The Law of Two Clocks) · next:
`/bcs/ideas/time-inside-the-name` (B1.5 · The Time Inside the Name)

Stamp: `BCS0NtfEwDNkUi` (decoded ts 2026-06-11 17:01:02 UTC)
