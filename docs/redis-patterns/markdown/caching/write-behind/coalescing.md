# Coalescing writes

> Route: `/redis-patterns/caching/write-behind/coalescing` · Module R1.03 · dive 3 · Source:
> `content/fundamental/write-behind.md.txt` (*Advantages* — write coalescing) · Grounding:
> `EchoStore.Journal.record_many/2` (group commit) + `compact/1` (coverage). Engine: Valkey.

Twenty updates to one key between flushes should cost one database write, not twenty. The async buffer already cut the
database to a batch per flush; coalescing cuts it further, by keeping each changed key once.

## Keep each key once

The async buffer batches by flush. Coalescing batches by *key*. The trick is the buffer's structure. A List records
every change in order, so a key updated five times appears five times, and the flush writes the database five times for
that one key. A Set cannot hold a duplicate: `SADD` a key that is already present and the Set is unchanged. So a
dirty-set of changed keys holds each key exactly once, no matter how often it changed.

The value itself is not stored on the buffer — only the key is marked dirty. The flush reads the *current* value of each
dirty key with a normal `GET` or `HGETALL`, so it always carries the latest state, never an intermediate one. Twenty
updates to one key leave one entry in the set and write the database once with the final value.

```
# write path — mark the key dirty, store the value (the value, not the key, holds state)
SET  ecc:{limits}:LIM0NgWEfAEJfs  {…}    # store the latest value
SADD dirty  LIM0NgWEfAEJfs               # mark dirty — a Set keeps it once however often it changes
SADD dirty  LIM0NgWEfAEJfs               # the same key again -> Set unchanged, still one entry

# flush path — one write per distinct key, with the current value
SMEMBERS dirty                           # -> {"LIM0NgWEfAEJfs", "LIM0KHTOWnGLuC"} — each once
GET      ecc:{limits}:LIM0NgWEfAEJfs     # read the latest value, then write the database once
```

- **dirty-set** — a Valkey Set of changed keys. `SADD` is idempotent, so each key is held once however many times it
  changed.
- **coalescing** — collapsing many updates to one key into a single database write, carrying the latest value.
- **latest-wins** — the flush reads the current value, not a queued one, so intermediate states never reach the source.
- **write amplification** — the ratio of database writes to updates. A List keeps it at one; the dirty-set drops it
  toward the count of distinct keys.

Coalescing changes the durability story a little: the window holds only the latest value of each key, so a crash loses
the most recent change, not a sequence of them. The trade itself is the one R1.03.2 measured.

## Coalesce a stream of updates

Feed updates into the dirty-set one at a time and watch it hold each key once. The keys come from a fixed repeating
stream where one key is hot. Each *update* does an `SADD`; *flush* writes the database one round per distinct key and
clears the set. The readout reports updates seen, the distinct keys held, and the coalescing ratio — how many updates one
database write absorbed. A hot key updated again and again still costs one database write per flush.

## On EchoStore — group commit at the writer's edge

EchoStore coalesces in two places. At the cache, the dirty-set keeps each changed key once — the Valkey structure above.
At the journal, the equivalent is `record_many/2` (`journal.ex:57`): "group commit at the writer's edge — record a batch
of intents inside one transaction, one WAL append amortized across the batch." Newer-wins makes a re-applied version
harmless, so two intents on the same name collapse to one effect: applying the same version twice is a comparison that
answers stale the second time. `compact/1` (`journal.ex:106`) then retires the outbox by coverage — an intent is gone
when its name carries an applied version at least as new.

The coherence message is the smallest possible cargo for this: `id <> ":" <> version` (`coherence.ex:35`) — 14 bytes of
branded name, a colon, 14 bytes of branded version, **29 bytes total**. The deferred write it carries is buffered by
EchoStore; the [`/echomq/cache` course](/echomq/cache) teaches how the EchoStore Journal coalesces deferred writes in depth.

## References

### Sources
- [Valkey — SADD](https://valkey.io/commands/sadd/) — adds a member to a Set; idempotent, so a key is held once however often it changes.
- [Valkey — SMEMBERS](https://valkey.io/commands/smembers/) — reads every distinct dirty key on the flush, each once.
- [Redis — Documentation](https://redis.io/docs/) — Sets and Lists, and choosing the structure that fits the shape of the problem.
- [Sanfilippo, S. — antirez weblog](https://antirez.com/) — the Redis creator on choosing the data structure that fits the problem.

### Related in this course
- [R1.03.2 · The durability trade-off](/redis-patterns/caching/write-behind/durability) — the previous dive.
- [R1.03 · Write-behind](/redis-patterns/caching/write-behind) — the module hub.
- [R1 · Caching](/redis-patterns/caching) — the chapter.
- [/echomq/cache](/echomq/cache) — the EchoStore Journal coalesces deferred writes, in depth.
