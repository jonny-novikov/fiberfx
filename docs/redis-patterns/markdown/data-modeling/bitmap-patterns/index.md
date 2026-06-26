# R7.04 · Bitmaps

> Route: `/redis-patterns/data-modeling/bitmap-patterns` — the R7.04 module hub.
> Identity: BCS contract-sheet, redis-red. Pattern slug: `bitmap-patterns`.

**Lede (verbatim from the author source `community/bitmap-patterns.md.txt`):**

> Store millions of boolean flags in minimal memory using Redis bitmaps — 1 bit per flag with O(1) access,
> plus fast aggregate operations across entire datasets.

A Redis (Valkey) bitmap is a String where each bit is a boolean. `SETBIT` and `GETBIT` address a single bit
by offset; one megabyte stores eight million flags. With `BITCOUNT` and `BITOP`, those flags become analytics:
how many are set, and which entities are in the union or intersection of several flag sets. The whole pattern
turns on one identity — **the bit offset is the entity's integer id** — and the whole limitation turns on the
same one: a bitmap allocates memory up to its highest offset, so the id space must be dense.

This module grounds in a **standalone** bitmap example (bitmaps are not an EchoMQ surface — EchoMQ ships zero
`SETBIT`/`BITCOUNT`/`BITOP`), with a **forward-tense** codemojex cohort note layered on top: a **planned**
analytics spike, `cm-bitmapist`, would model daily-active **players** as bitmaps, the offset being each
player's branded-id placement hash.

---

## §1 · Basic operations — one bit per entity

The three primitives address and count bits:

```
SETBIT users:active 1000 1     # user 1000 is active   (the offset IS the id)
GETBIT users:active 1000       # → 1                    (was this user active?)
BITCOUNT users:active          # → number of active users (a popcount over the string)
```

`SETBIT key offset value` sets the bit at `offset` to 0 or 1, growing the underlying String as needed.
`GETBIT key offset` reads it. `BITCOUNT key` counts the set bits — a population count over the whole string,
or over a byte/bit range. The cost model is the headline: a flag is one bit, and a count is a scan the engine
does in hardware popcount steps.

The `1-bit-flags` dive takes `SETBIT`/`GETBIT` and the per-entity flag grid apart.

## §2 · Daily active users (and weekly / monthly)

Name a bitmap per day; set a player's bit when they act:

```
SETBIT dau:2024-01-30 12345 1      # user 12345 visited today
BITCOUNT dau:2024-01-30            # daily active users
GETBIT  dau:2024-01-30 12345       # was this user active today?
```

Memory: **1 million users = 125 KB per day**. Combine daily bitmaps with `BITOP` to roll up windows:

```
BITOP OR  wau:2024-W05 dau:2024-01-28 dau:2024-01-29 dau:2024-01-30 ...   # active ANY day (union)
BITOP AND wau:2024-W05:daily dau:2024-01-28 dau:2024-01-29 ...            # active EVERY day (intersection)
```

`BITOP OR` over a week's daily bitmaps is weekly-active; `BITOP AND` over them is "active every day".
Retention cohorts fall out of the same two operators: who was active on day 0 **AND** day 7. The
`daily-active-patterns` dive carves this slice and ties it to the codemojex forward-tense note.

## §3 · Feature flags and online status

A bitmap can hold one entity's many booleans, or one boolean across many entities.

**Feature flags per user** — bit positions are features:

```
# 0 = dark_mode, 1 = notifications, 2 = beta_features, ...
SETBIT user:5000:features 0 1      # enable dark mode
SETBIT user:5000:features 2 1      # enable beta features
GETBIT user:5000:features 1        # notifications enabled?
GET    user:5000:features          # all flags at once — decode client-side
```

**Online status** — one bitmap, one bit per user:

```
SETBIT online:users 12345 1        # user comes online
SETBIT online:users 12345 0        # user goes offline
BITCOUNT online:users              # how many online
```

For millions of users this costs a fraction of a key-per-user, and time-bucketed keys (`online:minute:<ts>`
with an `EXPIRE`) give "active in the last five minutes" as a `BITOP OR` over the recent buckets.

## §4 · Bloom-filter alternative and cohort analysis

Bitmaps approximate two structures you might otherwise reach a module for.

**A hand-rolled Bloom filter** maps an item to k bit positions with k hashes and sets them; membership is "all
k bits set". If any is 0 the item is definitely absent; if all are 1 it is probably present (false positives
possible). This is the contrast R7.03 teaches in depth: probabilistic membership trades a bounded error rate
for fixed memory. For a real Bloom filter, the module commands `BF.*` size and hash automatically.

**Cohort analysis** intersects attribute bitmaps:

```
SETBIT users:premium 12345 1
SETBIT users:mobile  12345 1
BITOP AND cohort:premium_mobile users:premium users:mobile
BITCOUNT cohort:premium_mobile     # premium mobile users
BITOP NOT users:not_mobile users:mobile          # complement, then
BITOP AND cohort:premium_desktop users:premium users:not_mobile
```

Every segment question — premium-and-mobile, premium-and-not-mobile — is one `BITOP` plus a `BITCOUNT`. The
`bitcount-aggregates` dive takes `BITCOUNT` and `BITOP AND/OR/XOR/NOT` apart.

## §5 · BITFIELD, BITPOS, and rate limiting

Two commands address bit ranges beyond a single bit.

`BITFIELD` does atomic read-modify on arbitrary-width fields packed into one key — small counters with
overflow control:

```
BITFIELD counters SET u8 0 100                 # an 8-bit counter at offset 0
BITFIELD counters INCRBY u8 0 1 OVERFLOW SAT   # increment, saturating not wrapping
BITFIELD user:123:stats SET u8 0 50 SET u8 8 100 GET u8 0   # several counters in one key
```

`BITPOS` finds the first set or unset bit — the first active id, or the first free slot:

```
BITPOS users:active 1        # first set bit  (first active user)
BITPOS users:active 0        # first unset bit (first inactive id)
BITPOS users:active 1 100 200  # within a byte range
```

**Rate limiting** with bit-level granularity uses one bit per millisecond within a second; `BITCOUNT` over the
second's key is the request count, and a short `EXPIRE` reclaims it — 1000 bits (125 bytes) per user per
second.

## §6 · Memory efficiency, and the sparse-offset limitation

The reason to reach for a bitmap is the memory table:

| Users | Bitmap size | Equivalent Set |
|---|---|---|
| 1 million | 125 KB | ~50 MB |
| 10 million | 1.25 MB | ~500 MB |
| 100 million | 12.5 MB | ~5 GB |

Bitmaps are roughly **400× more memory-efficient** than storing ids in a Set — but only over a **dense
integer id space**. The limitation is the same fact read the other way: a bitmap allocates to its highest
offset.

```
SETBIT users:active 999999999 1    # allocates ~125 MB to hold ONE bit
```

A sparse id space wastes memory. The source's stated fixes are: use dense sequential ids; **hash ids to a
bounded range and accept collisions**; or use a Set. `BITOP` is also O(N) in the longest input, so very large
bitmaps are sharded by id range. This sparse-offset caveat is the whole story of the codemojex note below.

## §7 · The grounding — the branded offset, and the forward-tense codemojex spike

A bitmap's offset must be a non-negative integer. The Branded Component System already mints one for every
entity: a 14-character branded id carries a **placement** — `hash32`, the first half of MurmurHash3's fmix64
truncated to 32 bits. The runtime asserts the vector at boot (`branded_id.ex`, `self_check!`):

```
placement("USR0KHTOWnGLuC")  →  234878118
```

That 32-bit placement is exactly a bitmap bit offset. (Door: `/bcs/overview` — where the branded-id vectors
live.)

**The forward-tense codemojex note (planned, not shipped).** codemojex ships **no** bitmap code today — zero
`SETBIT`/`BITCOUNT`/`bitmapist` in `echo/apps/codemojex/lib/` (verified). A **planned** analytics spike,
`cm-bitmapist` (`infra/cm-bitmapist/` — a Go port of Doist's `bitmapist4`, branded-id-native, on its own Fly
machine), *would* mark each **player**'s daily-active bit at `Offset(id) = Hash32(Decode(id))`; DAU/WAU/MAU
would be `BITCOUNT`, and retention/funnel cohorts would be `BITOP AND`/`OR`. A page-own codemojex example uses
the live brand **`PLR`** (player):

```
# planned — codemojex-bitmapist, not in echo/apps/codemojex today
Mark("active", "PLR0KHTOWnGLuC", today)   # offset = placement("PLR0KHTOWnGLuC")
Count("active", month)                      # BITCOUNT — monthly actives
AndCount(reg, played, paid)                 # a registered → played → paid funnel
```

Because the branded placement is a **hash**, the offset lands anywhere in the 32-bit space — sparse, exactly
figure 11's limitation. So the spike uses **roaring** bitmaps (compressed bitmaps that store runs, not a flat
allocation to the highest offset): the published result for a sparse branded keyspace is on the order of
~129 GB on a plain bitmap versus ~300 MB roaring. The `hash32` is also collision-bearing in 32 bits
(on the order of N²/2³³ colliding pairs), so distinct counts undercount slightly — a property to state, not
assume.

### The bridge

| The pattern | Its application (forward-tense) |
|---|---|
| 1 bit per flag; `BITCOUNT`/`BITOP` analytics over millions of entities at O(1) memory per flag. | codemojex's **planned** `cm-bitmapist` would model daily-active **players** as bitmaps — the bit offset is the player's branded-id placement hash (`placement(…) → 234878118`), sparse → roaring. |

**Take.** Bitmaps buy O(1)-memory-per-flag answers to "how many" and "which set" — but only over a **dense
integer id space**. The sparse-offset caveat is the whole limitation: a flat bitmap allocates to its highest
offset, so a hashed (branded) id space wants a roaring bitmap, not a plain one.

**Notes on Valkey.** `BITCOUNT key [start end [BYTE | BIT]]` counts set bits over the whole string or a range,
and `SETBIT`/`GETBIT`/`BITOP`/`BITPOS`/`BITFIELD` are all **core** commands on the String type — no module
required (the `BF.*`/`CF.*` probabilistic structures are the module exception R7.03 covers). See
`valkey.io/commands/bitcount/`.

## The three dives

- **R7.04.1 · `1-bit-flags`** — Basic Operations + Feature Flags: `SETBIT`/`GETBIT`, one bit per entity, the
  offset is the id; the 125 KB-per-1M-flags density; a feature-flag-per-user grid.
- **R7.04.2 · `bitcount-aggregates`** — `BITCOUNT` (popcount) + `BITOP AND/OR/XOR/NOT` (combine bitmaps) +
  `BITPOS`; the Bloom-filter-alternative framing (a contrast pointer to R7.03).
- **R7.04.3 · `daily-active-patterns`** — a bitmap per day (`SETBIT dau:<date> <id>`), `BITCOUNT` = DAU,
  `BITOP OR/AND` over days = WAU/MAU and retention cohorts; the codemojex forward-tense cohort note + the
  sparse-offset → roaring caveat.

## References

### Sources

- [Valkey — SETBIT](https://valkey.io/commands/setbit/) — set the bit at an offset; the offset is the entity id.
- [Valkey — BITCOUNT](https://valkey.io/commands/bitcount/) — population count over a String, whole or by range.
- [Valkey — BITOP](https://valkey.io/commands/bitop/) — AND / OR / XOR / NOT across bitmaps for cohorts and windows.
- [Valkey — BITPOS](https://valkey.io/commands/bitpos/) — first set or unset bit; the first active id or free slot.
- [Valkey — BITFIELD](https://valkey.io/commands/bitfield/) — atomic read-modify on packed bit-width counters.
- [Redis — Bitmaps](https://redis.io/docs/latest/develop/data-types/bitmaps/) — the data-type overview the patterns build on.

### Related in this course

- [R7.04.1 · 1-bit flags](/redis-patterns/data-modeling/bitmap-patterns/1-bit-flags) — `SETBIT`/`GETBIT`, the offset is the id.
- [R7.04.2 · bitcount aggregates](/redis-patterns/data-modeling/bitmap-patterns/bitcount-aggregates) — `BITCOUNT` and `BITOP` analytics.
- [R7.04.3 · daily-active patterns](/redis-patterns/data-modeling/bitmap-patterns/daily-active-patterns) — DAU/WAU/MAU and the codemojex note.
- [R7.03 · Probabilistic data structures](/redis-patterns/data-modeling/probabilistic-data-structures) — bitmaps as an exact alternative to a probabilistic estimate.
- [R7.02 · Memory optimization](/redis-patterns/data-modeling/memory-optimization) — the same memory family: compact encodings and bounded structures.
- [/bcs · Overview](/bcs/overview) — the branded-id placement vector, the bit-offset tie-in.
