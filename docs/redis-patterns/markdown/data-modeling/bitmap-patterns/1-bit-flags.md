# R7.04.1 · 1-bit flags

> Route: `/redis-patterns/data-modeling/bitmap-patterns/1-bit-flags` — dive 1 of the Bitmaps module.

**Lede.** A boolean per entity does not need a key per entity. A Redis bitmap is one String where bit number N
is the flag for entity N — set it with `SETBIT`, read it with `GETBIT`, and one megabyte holds eight million
of them.

The whole encoding rests on one identity: **the bit offset is the entity's integer id**. There is no map from
id to slot to maintain; the id *is* the slot. That makes a flag O(1) to set and read, and the storage a single
contiguous bit per entity.

## §1 · SETBIT and GETBIT — the offset is the id

```
SETBIT users:active 1000 1     # entity 1000 is active
GETBIT users:active 1000       # → 1
SETBIT users:active 1000 0     # clear it
GETBIT users:active 1000       # → 0
```

`SETBIT key offset value` sets the single bit at `offset` to 0 or 1 and returns its previous value; the
underlying String grows automatically so that the byte holding `offset` exists, zero-filled. `GETBIT key
offset` returns the bit (0 for any offset past the end). Both are O(1).

Because the offset is the id, setting "user 1000 is active" writes bit 1000 — byte 125, bit 0 within it — and
nothing else. No per-entity key, no key name to store a million times, no expiration metadata per flag. The
flag for the next entity is the next bit.

A bitmap is one boolean **across** many entities (`online:users`, bit per user) or many booleans **for** one
entity (`user:5000:features`, bit per feature). Same two commands, read either way.

## §2 · Feature flags per user — bits are features

When the bitmap belongs to one entity, the offsets are its features:

```
# bit 0 = dark_mode, bit 1 = notifications, bit 2 = beta_features, ...
SETBIT user:5000:features 0 1      # enable dark mode
SETBIT user:5000:features 2 1      # enable beta features
GETBIT user:5000:features 1        # notifications enabled?  → 0
GET    user:5000:features          # the raw byte(s) — decode all flags client-side
```

Each user's flag set is a handful of bits in one key. A single-feature check is `GETBIT`; reading every flag
at once is a `GET` of the String and a client-side decode, which is one round trip instead of one per flag.
For a few dozen features per user, the whole record is a byte or two.

The trade against a Hash of named booleans is legibility for density: a Hash field `notifications` reads
itself, a bit at offset 1 needs a legend. Use a bitmap when the flag set is large and dense and the memory
matters; use a Hash when there are a few flags and a reader needs the names.

## §3 · The density — why a bit beats a key

The reason to encode a flag as a bit rather than a key is the memory table from the source:

| Entities | Bitmap size | Equivalent Set of ids |
|---|---|---|
| 1 million | 125 KB | ~50 MB |
| 10 million | 1.25 MB | ~500 MB |
| 100 million | 12.5 MB | ~5 GB |

A bitmap is roughly **400× smaller** than a Set of the same ids. A Set stores each id as a member with its own
overhead; a bitmap stores each as one bit. For "is this entity flagged" at scale — active today, online now,
opted into a feature — the bitmap is the dense answer.

The caveat is the highest-offset rule, which the `daily-active-patterns` dive returns to: a bitmap allocates
up to its largest set offset, so the density holds only over a **dense** id space. A sparse id space (hashed
or random ids) wastes the bytes between the set bits.

### The bridge

| The pattern | Where it grounds |
|---|---|
| One bit per entity, `SETBIT`/`GETBIT` at O(1), 125 KB per million flags — a flag is a bit, not a key. | A **standalone** core-Valkey example. Bitmaps are not an EchoMQ surface — EchoMQ ships no `SETBIT`/`BITCOUNT`. The branded placement (`placement(id) → 234878118`) is the integer offset a branded-native bitmap would use. |

**Take.** The cheapest boolean-per-entity store is a bit, not a key: `SETBIT`/`GETBIT` put one flag in one bit
at the offset that *is* the id, and a million flags fit in 125 KB. It holds while the id space is dense — the
limitation the daily-active dive makes concrete.

**Notes on Valkey.** `SETBIT key offset value` and `GETBIT key offset` operate on the String type; the bit is
addressed from the most-significant bit of byte 0, and `SETBIT` grows the String (zero-filled) to reach the
offset. The offset must be a non-negative integer under 2³². See `valkey.io/commands/setbit/`.

## References

### Sources

- [Valkey — SETBIT](https://valkey.io/commands/setbit/) — set the bit at an offset; returns its old value; grows the String.
- [Valkey — GETBIT](https://valkey.io/commands/getbit/) — read the bit at an offset; 0 past the end.
- [Valkey — GET](https://valkey.io/commands/get/) — read the whole bitmap String to decode many flags client-side.
- [Redis — Bitmaps](https://redis.io/docs/latest/develop/data-types/bitmaps/) — the bitmap data-type overview.

### Related in this course

- [R7.04 · Bitmaps](/redis-patterns/data-modeling/bitmap-patterns) — the module hub.
- [R7.04.2 · bitcount aggregates](/redis-patterns/data-modeling/bitmap-patterns/bitcount-aggregates) — counting and combining bitmaps.
- [R7.04.3 · daily-active patterns](/redis-patterns/data-modeling/bitmap-patterns/daily-active-patterns) — a bitmap per day, and the sparse-offset caveat.
- [R7.02 · Memory optimization](/redis-patterns/data-modeling/memory-optimization) — the broader memory family.
