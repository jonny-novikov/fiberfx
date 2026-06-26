# R7.04.3 · daily-active patterns

> Route: `/redis-patterns/data-modeling/bitmap-patterns/daily-active-patterns` — dive 3 of the Bitmaps module.

**Lede.** The most common bitmap pattern is one bitmap per day. Set a player's bit when they act, and the
day's activity is a `BITCOUNT`; roll several days up with `BITOP` and you have weekly and monthly actives, and
retention cohorts, from the same bits.

This is also where the encoding's one limitation bites hardest, because real ids are rarely a dense `0..N`
sequence. The dive ends on it — the sparse-offset rule — and on the **forward-tense** codemojex spike that
solves it with a roaring bitmap.

## §1 · A bitmap per day — DAU

Name the bitmap by date; set a player's bit on activity:

```
SETBIT dau:2024-01-30 12345 1      # player 12345 was active on this day
BITCOUNT dau:2024-01-30            # daily active users (DAU)
GETBIT  dau:2024-01-30 12345       # was this player active that day?
```

One bitmap per day, one bit per player. The day's DAU is `BITCOUNT` over its key. **Memory: 1 million players
= 125 KB per day** — a year of daily-active bitmaps for a million players is about 46 MB, far less than a Set
of ids per day.

## §2 · BITOP over days — WAU, MAU, and retention

Windows are `BITOP` over the daily bitmaps:

```
# weekly active — set in ANY day this week
BITOP OR  wau:2024-W05 dau:2024-01-28 dau:2024-01-29 dau:2024-01-30 dau:2024-01-31 ...
BITCOUNT  wau:2024-W05

# active EVERY day this week — the most-engaged
BITOP AND wau:2024-W05:every dau:2024-01-28 dau:2024-01-29 ...
BITCOUNT  wau:2024-W05:every
```

`BITOP OR` over a week's daily bitmaps is weekly-active; over a month's, monthly-active. `BITOP AND` over them
is "active every day in the window". The result is itself a bitmap, so it composes — a quarter is the `OR` of
its months.

**Retention** is the intersection of two days:

```
# of those active on day 0, who returned on day 7
BITOP AND retain:d0_d7 dau:2024-01-01 dau:2024-01-08
BITCOUNT retain:d0_d7
# day-7 retention rate = BITCOUNT(retain:d0_d7) / BITCOUNT(dau:2024-01-01)
```

A funnel is a chain of `BITOP AND`: registered-and-played-and-paid is the intersection of three attribute
bitmaps. Every cohort question reduces to a union or an intersection followed by a count.

## §3 · The sparse-offset limitation — the whole caveat

The density holds only over a **dense** id space, because a bitmap allocates memory up to its highest set
offset:

```
SETBIT users:active 999999999 1    # allocates ~125 MB to hold ONE bit
```

One bit at offset ~10⁹ forces the String to ~125 MB of mostly zeros. The source's fixes are: use dense,
sequential ids; **hash ids to a bounded range and accept collisions**; or use a Set for sparse data. A plain
bitmap is the right structure only when the ids are packed near `0`.

## §4 · The codemojex cohort note — forward-tense, and roaring

codemojex ships **no** bitmap code today: there is zero `SETBIT`/`BITCOUNT`/`bitmapist` in
`echo/apps/codemojex/lib/` (verified). What follows is **planned**, not shipped.

A planned analytics spike, `cm-bitmapist` (`infra/cm-bitmapist/` — a Go port of Doist's `bitmapist4`,
branded-id-native, on its own Fly machine), *would* model daily-active **players** as bitmaps. The offset
would be each player's branded-id placement — the `hash32`, the first half of MurmurHash3's fmix64 truncated
to 32 bits, asserted at boot in `branded_id.ex`:

```
placement("USR0KHTOWnGLuC")  →  234878118     # the boot-asserted vector (the bit offset)
```

A page-own codemojex example uses the live brand **`PLR`** (player):

```
# planned — codemojex-bitmapist, not in echo/apps/codemojex
Mark("active", "PLR0KHTOWnGLuC", today)   # offset = placement("PLR0KHTOWnGLuC")
Count("active", month)                      # BITCOUNT — monthly active players
AndCount(registered, played, paid)          # a registered → played → paid funnel
```

Here is where the sparse-offset rule decides the design. The branded placement is a **hash**, so the offset
lands anywhere in the 32-bit space — sparse, exactly the §3 limitation. A flat bitmap over a sparse branded
keyspace is enormous; the spike uses **roaring** bitmaps instead (compressed bitmaps that store dense runs and
sparse positions differently, not a flat allocation to the highest offset). The published result for a sparse
branded keyspace is on the order of ~129 GB on a plain bitmap versus ~300 MB roaring — figure 11's limitation,
solved by the structure. The `hash32` is also collision-bearing in 32 bits (on the order of N²/2³³ colliding
pairs at N players — negligible into the millions), so distinct counts undercount slightly; a property to
state, not assume.

(Door: `/bcs/overview` — where the branded-id placement vectors live and are asserted.)

### The bridge

| The pattern | Its application (forward-tense) |
|---|---|
| A bitmap per day; `BITCOUNT` = DAU; `BITOP OR/AND` over days = WAU/MAU and retention — exact cohort analytics over the bits. | codemojex's **planned** `cm-bitmapist` would mark daily-active **players** at the offset = their branded-id placement (`placement(…) → 234878118`). The placement is sparse, so the spike uses a **roaring** bitmap, not a flat one. |

**Take.** A bitmap per day makes DAU/WAU/MAU and retention a matter of `BITCOUNT` and `BITOP` — exact, cheap,
composable. But only over a dense id space: a hashed (branded) id space is sparse, so a branded-native cohort
store wants a roaring bitmap, the structure that does not allocate to the highest offset.

**Notes on Valkey.** `BITOP OR|AND|XOR|NOT destkey key [key ...]` writes a result bitmap the size of the
longest input and is O(N) in that length; a flat String bitmap grows to its highest set offset, which is why a
sparse id space wants a different structure. See `valkey.io/commands/bitop/`.

## References

### Sources

- [Valkey — BITOP](https://valkey.io/commands/bitop/) — union and intersection of daily bitmaps for windows and retention.
- [Valkey — BITCOUNT](https://valkey.io/commands/bitcount/) — DAU/WAU/MAU as a population count.
- [Valkey — SETBIT](https://valkey.io/commands/setbit/) — set a player's daily bit; the offset is the id, and a flat bitmap allocates to the highest offset.
- [Redis — Bitmaps](https://redis.io/docs/latest/develop/data-types/bitmaps/) — the bitmap data-type overview.

### Related in this course

- [R7.04 · Bitmaps](/redis-patterns/data-modeling/bitmap-patterns) — the module hub.
- [R7.04.1 · 1-bit flags](/redis-patterns/data-modeling/bitmap-patterns/1-bit-flags) — `SETBIT`/`GETBIT`, the offset is the id.
- [R7.04.2 · bitcount aggregates](/redis-patterns/data-modeling/bitmap-patterns/bitcount-aggregates) — `BITCOUNT` and `BITOP` analytics.
- [/bcs · Overview](/bcs/overview) — the branded-id placement vector, the bit-offset tie-in.
