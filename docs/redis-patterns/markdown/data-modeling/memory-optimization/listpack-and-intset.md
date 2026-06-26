# R7.02.1 · listpack and intset

> Route: `/redis-patterns/data-modeling/memory-optimization/listpack-and-intset` · dive 1.

Small collections do not cost what they look like they cost. Redis stores a small Hash as a **listpack** — a single sequential byte array — and a small all-integer Set as an **intset** — a sorted array of fixed-width integers. Both avoid the pointers and buckets a general hash table needs, and both are chosen automatically. EchoMQ's three-field job HASH is the worked case: it is a listpack because the row is small, and a listpack is most of the memory win this chapter is about.

## §1 · Two layouts for the same data

A Hash can be stored two ways. The **hashtable** encoding is the general structure: a bucket array, a chain of entries per bucket, and a pointer for every key and value — fast at any size, but each entry carries pointer and allocation overhead that, for a small object, can be 80% of the bytes. The **listpack** encoding packs all the fields end to end into one contiguous byte array: length-prefixed entries, no per-entry pointer, no bucket array. A read walks the array; for a few fields that is cheaper than chasing pointers, and the memory is a fraction.

An all-integer Set has a third, tighter layout: the **intset** — a sorted array of fixed-width integers (16-, 32-, or 64-bit, widened only when a member needs it). No hashing, no pointers, only a packed sorted array a membership test binary-searches.

The engine picks the layout by size and switches when a structure crosses a configured threshold.

## §2 · The thresholds

These are Valkey engine defaults — read from the documentation, **not** set in EchoMQ's config:

```
hash-max-listpack-entries 512
hash-max-listpack-value 64
set-max-intset-entries 512
zset-max-listpack-entries 128
```

A Hash stays a listpack while it has fewer than 512 fields **and** every value is under 64 bytes; cross either bound and it converts to a hashtable. A Set stays an intset while it has fewer than 512 members **and** every member is an integer; add a 513th member or one non-integer and it converts (to a listpack, then a hashtable). The conversion is **one-way** — adding the element that crosses the line flips the encoding, and removing it does not flip it back.

## §3 · The job HASH is a listpack

EchoMQ's job row is a Hash with exactly three fields, written by the `@enqueue` script in one atomic step:

```lua
-- @enqueue (EchoMQ.Script.new(:enqueue, …)) — the row write, verbatim
if string.sub(ARGV[1], 1, 3) ~= 'JOB' then
  return redis.error_reply('EMQKIND job id must be JOB-namespaced')
end
if redis.call('EXISTS', KEYS[1]) == 1 then
  return 0
end
redis.call('HSET', KEYS[1], 'state', 'pending', 'attempts', '0', 'payload', ARGV[2])
redis.call('ZADD', KEYS[2], 0, ARGV[1])
return 1
```

Three fields is far under 512; `state` is a short word, `attempts` is a bare integer, `payload` is a body that is small for the operational jobs EchoMQ runs — all under 64 bytes in the common case. So Valkey stores the row as a listpack. The committed `infra/valkey/conf/valkey.conf` sets **no** encoding thresholds, so this is the engine default at work on a deliberately minimal row — the win is the design, not a tuned knob.

The figure home in the Branded Component System manuscript states the production posture of the same store; this dive grounds the *encoding* in the real row.

## The bridge — pattern → application

**Pattern.** A small Hash is a listpack and a small all-integer Set is an intset — a sequential byte array with no pointer or bucket overhead, chosen automatically below the thresholds.

**EchoMQ application.** The 3-field job HASH (`state`/`attempts`/`payload`) sits far under `hash-max-listpack-entries 512` with values under `hash-max-listpack-value 64`, so Valkey keeps it a listpack — the compact encoding by construction, not configuration.

**Take.** The cheapest memory optimization is to keep a structure small enough to stay in its compact encoding. EchoMQ never has to tune the thresholds because its row is three short fields — a listpack the engine stores it as by default.

## References

### Sources

- [Valkey — Memory optimization](https://valkey.io/topics/memory-optimization/) — listpack and intset, the thresholds, and the pointer overhead a compact encoding removes.
- [Valkey — OBJECT ENCODING](https://valkey.io/commands/object-encoding/) — read a key's internal encoding to confirm `listpack` vs `hashtable` vs `intset`.
- [Valkey — HSET](https://valkey.io/commands/hset/) — set fields on a Hash; the job row is written as one Hash.
- [Valkey — SADD](https://valkey.io/commands/sadd/) — add members to a Set; an all-integer Set is an intset until it crosses the threshold.

### Related in this course

- [R7.02 · Memory optimization](/redis-patterns/data-modeling/memory-optimization) — the module hub.
- [R7.02.2 · short-field-names](/redis-patterns/data-modeling/memory-optimization/short-field-names) — keeping the value under `hash-max-listpack-value`.
- [R7.02.3 · capped-structures](/redis-patterns/data-modeling/memory-optimization/capped-structures) — bounding the structures that grow.
- [/bcs · The store](/bcs/store) — EchoStore, the compact near-cache.
