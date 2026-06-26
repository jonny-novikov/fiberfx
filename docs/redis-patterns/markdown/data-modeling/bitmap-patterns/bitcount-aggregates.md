# R7.04.2 · bitcount aggregates

> Route: `/redis-patterns/data-modeling/bitmap-patterns/bitcount-aggregates` — dive 2 of the Bitmaps module.

**Lede.** Once flags are bits, the analytics are bit arithmetic. `BITCOUNT` answers "how many are set" as a
population count over the whole string; `BITOP` combines several bitmaps with AND / OR / XOR / NOT into a new
one; `BITPOS` finds the first set or unset bit. None of them need to enumerate the entities.

This is what makes bitmaps an analytics encoding rather than only a flag store: a segment question becomes one
`BITOP` followed by one `BITCOUNT`, over the bits, in the engine.

## §1 · BITCOUNT — the population count

```
BITCOUNT users:active              # count every set bit
BITCOUNT users:active 0 0          # set bits in byte 0
BITCOUNT users:active 0 0 BIT      # set bits in bit 0 (the BIT range form)
```

`BITCOUNT key` counts the set bits in the string — the number of flagged entities. The optional `start`/`end`
restrict it to a byte range, or a bit range with the `BIT` modifier. The work is a popcount, which the engine
does in hardware-sized steps over the string, so counting a million-flag bitmap is one fast scan, not a
million reads.

`BITCOUNT` is the size of any cohort, window, or flag set: daily active users, online users, holders of a
feature — each is the count of one bitmap.

## §2 · BITOP — combine bitmaps into a cohort

`BITOP` writes a new bitmap from a bitwise operation over one or more inputs:

```
BITOP OR  any  a b c        # bit set if set in ANY input   (union)
BITOP AND all  a b c        # bit set if set in EVERY input (intersection)
BITOP XOR diff a b          # bit set if set in exactly one (symmetric difference)
BITOP NOT inv  a            # every bit flipped              (complement)
```

A cohort is one `BITOP` plus a `BITCOUNT`:

```
SETBIT users:premium 12345 1
SETBIT users:mobile  12345 1
BITOP AND cohort:premium_mobile users:premium users:mobile
BITCOUNT cohort:premium_mobile                       # premium AND mobile

BITOP NOT users:not_mobile users:mobile              # complement, then
BITOP AND cohort:premium_desktop users:premium users:not_mobile
BITCOUNT cohort:premium_desktop                      # premium AND NOT mobile
```

Every attribute is a bitmap; every segment is a boolean expression over them. The result bitmap is the same
size as its inputs and can itself feed another `BITOP` — cohorts compose. `BITOP` is **O(N)** in the length of
the longest input string, so the cost is the size of the largest bitmap, and very large ones are sharded by id
range.

## §3 · BITPOS — the first set or unset bit

```
BITPOS users:active 1          # offset of the first set bit  → first active id
BITPOS users:active 0          # offset of the first unset bit → first free slot
BITPOS users:active 1 100 200  # within a byte range
```

`BITPOS key bit` returns the offset of the first bit equal to `bit` (0 or 1), optionally within a range. It
answers "the first active entity" or "the first free slot" without scanning client-side — useful for
allocating the next id in a dense space, or finding where a run of activity begins.

## §4 · The Bloom-filter alternative — and the contrast it points to

A bitmap can stand in for a Bloom filter: hash an item to k positions and set them; membership is "all k bits
set". If any is 0 the item is definitely absent; if all are 1 it is probably present, with false positives
whose rate depends on the bitmap size and k. That is the same accuracy-for-memory trade R7.03 teaches as a
first-class structure — and where a real Bloom filter belongs, the module commands `BF.*` size it and choose
the hashes for you.

The contrast is the point. Bitmaps as taught here are **exact**: `BITCOUNT` over a flag set is the true count
(no estimate), and `GETBIT` is a definite yes/no for a known offset. You reach for the probabilistic
structures of R7.03 only when the cardinality is so large that even one bit per entity is too much, and a
bounded error rate is acceptable.

### The bridge

| The pattern | Where it grounds |
|---|---|
| `BITCOUNT` is an exact popcount; `BITOP AND/OR/XOR/NOT` composes cohorts; `BITPOS` finds the first set/unset bit — all over the bits, in the engine. | A **standalone** core-Valkey example. These are exact answers; R7.03's HyperLogLog and Bloom filters are the approximate counterparts you reach for when exact storage is too expensive. |

**Take.** Bitmaps turn a flag store into an analytics one: `BITCOUNT` for the size of a set, `BITOP` to compose
cohorts, `BITPOS` to find an edge — exactly, and without enumerating entities. The approximate versions are a
deliberate trade (R7.03), not the default.

**Notes on Valkey.** `BITOP destkey op key [key ...]` is O(N) in the length of the longest input string and
writes a result the size of that input; `BITCOUNT` is a population count with an optional `BYTE`/`BIT` range
modifier. See `valkey.io/commands/bitop/`.

## References

### Sources

- [Valkey — BITCOUNT](https://valkey.io/commands/bitcount/) — population count over the whole String or a byte/bit range.
- [Valkey — BITOP](https://valkey.io/commands/bitop/) — AND / OR / XOR / NOT across bitmaps into a result bitmap; O(N) in the longest input.
- [Valkey — BITPOS](https://valkey.io/commands/bitpos/) — the offset of the first set or unset bit.
- [Redis — Bitmaps](https://redis.io/docs/latest/develop/data-types/bitmaps/) — the bitmap data-type overview.

### Related in this course

- [R7.04 · Bitmaps](/redis-patterns/data-modeling/bitmap-patterns) — the module hub.
- [R7.04.1 · 1-bit flags](/redis-patterns/data-modeling/bitmap-patterns/1-bit-flags) — `SETBIT`/`GETBIT`, the offset is the id.
- [R7.04.3 · daily-active patterns](/redis-patterns/data-modeling/bitmap-patterns/daily-active-patterns) — `BITOP` over daily bitmaps for windows and cohorts.
- [R7.03 · Probabilistic data structures](/redis-patterns/data-modeling/probabilistic-data-structures) — the approximate counterpart to exact bitmap analytics.
