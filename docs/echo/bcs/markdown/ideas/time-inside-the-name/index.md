# B1.5 · The Time Inside the Name — module hub

Route: `/bcs/ideas/time-inside-the-name` · teaches manuscript chapter `content/bcs1.5.md`.

## Hero

Kicker: B1.5 · The Time Inside the Name — manuscript chapter 1.5

H1: Whose clock is **authoritative**?

Lede: Every chapter so far has leaned on chronology without taking it as a subject. The order theorem turned
keys into timelines, the storage chapter ranged stream windows by id arithmetic, the substrate paged
newest-first with no clock in the process — **time has been load-bearing on every page and examined on none.**
This module examines it: what the 41 bits promise, what they refuse to promise, the discipline the minter owes
its clock, and the law that keeps the trading system from confusing the kinds of time it lives with.

Heronote: The chapter is content/bcs1.5.md. The contract owns the bits; this module states the policy.

Hero interactive: **the three clocks** — a selector over identity time (the id's — when this architecture
first named the entity, readable through `unix_ms`), event time (someone else's clock, carried as data), and
the store's clock (a TTL — the row's rented tenure). Pure lookup over the chapter's own definitions; live
readout; static text readable without JS.

## §1 — Two times that look alike (content/bcs1.5.md · Why)

A trading platform runs on two times that look alike and are not. There is the moment an exchange says a fill
happened — event time, owned by someone else's clock, carried as data, disputed in arbitration. And there is
the moment this architecture first *named* the fill — identity time, owned by the minter, carried inside the
id, readable forever through `unix_ms`. Conflating them is the subtle cousin of the second clock from Chapter
1.2: not a duplicate timestamp beside the id, but the id's timestamp doing a job it never promised to do.

## §2 — The free creation instant (content/vectors.json)

Identity time is a free creation instant. The canonical pair in `vectors.json` decodes `USR0NgWEfAEJfs` to
`320636799581945856` and reads `unix_ms` as `1780512970164`, no column required.

Frozen evidence (content/vectors.json · decode + unix_ms):

```
id         USR0NgWEfAEJfs
snowflake  320636799581945856
unix_ms    1780512970164
```

The litmus for everything in this module is one question — *whose clock is authoritative for this claim?* —
and the moment the answer is "not ours," the value is data beside the id, never arithmetic on it.

## §3 — The dives (fixed by the chapter spec)

- **B1.5.1 · The 41-Bit Horizon** (`the-41-bit-horizon`) — 41 bits of milliseconds above the 2024-01-01 epoch
  (`1704067200000`) is about 69.7 years; the field exhausts in September 2093; the successor epoch is a
  planned amendment, never an incident.
- **B1.5.2 · The Law of Two Clocks** (`the-law-of-two-clocks`) — identity time vs event time; Lamport's
  fifty-year-old foundation; `min_for` cursors as identity-time arithmetic; event time as data.
- **B1.5.3 · The Floor and the Third Clock** (`the-floor-and-the-third-clock`) — the monotonic mint floor as
  policy of record; a TTL as the store's clock, priced on the measured table; two mechanisms, deliberately
  unmerged.

Booknote: Reach for identity time when the question is about this architecture's own history — pagination,
replay windows, retention cutoffs, first-seen audit, dedupe-by-recency. Reach for event time when the question
belongs to another clock's jurisdiction — matching semantics, regulatory timestamps, PnL bucketing, anything an
exchange or a client could dispute.

## References

Sources:
- Lamport — Time, Clocks, and the Ordering of Events in a Distributed System (1978):
  https://dl.acm.org/doi/10.1145/359545.359563 — happened-before as a partial order; order as construction.
- Valkey documentation — Streams introduction: https://valkey.io/topics/streams-intro/ — entry ids carry the
  millisecond; ranges address time through the id.

Related:
- `/bcs/ideas` — B1 · Ideas Behind, the chapter landing.
- `/bcs/ideas/identity-contract` — B1.2, the order theorem and the second clock.
- `/bcs/ideas/id-system` — B1.3, the measured table the TTL row sits on.
- `/echomq` — the bus whose stream entry ids carry the millisecond.

## Pager

prev: `/bcs/ideas` (B1 · Ideas Behind) · next: `/bcs/ideas/time-inside-the-name/the-41-bit-horizon`
(B1.5.1 · The 41-Bit Horizon)

Stamp: `BCS0NtfEvw4DYm` (decoded ts 2026-06-11 17:01:02 UTC)
