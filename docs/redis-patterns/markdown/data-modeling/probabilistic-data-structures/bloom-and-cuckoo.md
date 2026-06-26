# R7.03.2 · Bloom & Cuckoo filters

> Route: `/redis-patterns/data-modeling/probabilistic-data-structures/bloom-and-cuckoo` · dive 2.
> Probabilistic membership with no false negatives. A contrast with EchoMQ's exact `de:` membership, never a
> thing EchoMQ implements.

A Bloom filter answers "is this item in the set?" with **possible false positives but zero false negatives**. A
"no" is certain; a "yes" is "probably". That one-sided error is the property worth understanding — it is what makes
a Bloom filter safe in front of an expensive lookup, and it is exactly the property EchoMQ's idempotency cannot
accept.

## How a Bloom filter works

A Bloom filter is a bit array plus k hash functions. To add an item, hash it k ways and set the k bits. To test an
item, hash it the same k ways and read those bits: if **any** bit is zero the item is definitely absent; if **all**
are set the item is probably present. A false positive happens when other items happened to set all of one
absent item's bits. A false negative cannot happen — adding an item only sets bits, never clears them, so a present
item always reads back all-set.

The false-positive rate is a **dial**. More bits per item and more hash functions lower it; a 1% rate for a million
items is a typical reservation. You pay memory and a little CPU for a smaller error.

Bloom commands are **module commands** — Valkey-Bloom or Redis-Stack, not the core engine:

```
BF.RESERVE usernames 0.01 1000000   # 1% false-positive rate, capacity 1,000,000 — a module command
BF.ADD usernames "john_doe"
BF.EXISTS usernames "john_doe"
```

## The signature use — cache penetration

Without a membership pre-check, a flood of requests for keys that do not exist each misses the cache and falls
through to the database — an attacker can turn "look up a user that isn't there" into database load. A Bloom filter
holding the set of real keys rejects the absent ones immediately: if the filter says "absent", skip the cache and
the database entirely. The zero-false-negative guarantee is what makes this safe — the filter never wrongly says
"absent" for a key that exists, so a real key is never rejected. A false **positive** only costs one needless
lookup, which the cache absorbs.

## Cuckoo — Bloom with deletion

A Bloom filter cannot delete: clearing a bit might unset a bit another item relies on, breaking the
no-false-negative guarantee. A Cuckoo filter stores small **fingerprints** in a cuckoo hash table, so it supports
deletion. Cuckoo commands are **module commands**, `CF.*`:

```
CF.RESERVE sessions 1000000
CF.ADD sessions "session:abc123"
CF.EXISTS sessions "session:abc123"
CF.DEL sessions "session:abc123"   # delete — what Bloom cannot do
```

| Feature | Bloom | Cuckoo |
|---|---|---|
| Deletion | Not supported | Supported |
| Space (low FP rates) | Good | Better |
| Insert | Faster | Slightly slower |
| Lookup | Slightly slower | Faster |

Choose Bloom when the set only grows and inserts dominate; choose Cuckoo when items must leave the filter — tracking
active sessions that expire, for instance, where a logged-out session should drop out of the set.

## The EchoMQ contrast — exact membership, by choice

EchoMQ also answers a membership question — "have I already seen this idempotency key?" — but it answers it
**exactly**, with a real key, not a filter:

```elixir
# echo/apps/echo_mq/lib/echo_mq/metrics.ex (verbatim) — exact membership, every id stored
def get_deduplication_job_id(conn, queue, dedup_id) when is_binary(dedup_id) do
  key = Keyspace.queue_key(queue, "de:" <> dedup_id)
  ...
end
```

```lua
-- echo/apps/echo_mq/lib/echo_mq/jobs.ex — @enqueue, the exact dup-refusal by job key (verbatim)
if redis.call('EXISTS', KEYS[1]) == 1 then
  return 0
end
```

A Bloom filter's error is one-sided in the **wrong** direction for idempotency. It never wrongly says "absent" — but
it can wrongly say "present", a false positive. For a cache pre-check a false "present" is harmless (one extra real
lookup). For dedup a false "present" means "already seen, drop it" — and the job is lost, silently. So EchoMQ stores
every id exactly, pays O(n) memory, and accepts zero false positives. The Bloom filter is the right tool when a
false positive costs a wasted lookup; the exact `de:` key is the right tool when a false positive costs a dropped
job.

## The bridge

- **Pattern** — a Bloom (or Cuckoo) filter: membership at a fraction of the exact memory, **no false negatives**,
  a tunable false-positive rate. Safe in front of an expensive lookup.
- **Application (counter-example)** — EchoMQ's `emq:{q}:de:<dedupId>` (plus the `@enqueue` `EXISTS` refusal) is
  **exact** membership: O(n) memory, zero false positives. A false "already seen" would drop a job, so the filter's
  one-sided error is unacceptable here.

**Take.** A Bloom filter's value is its one-sided error — a "no" is certain, so it is safe to skip work on it; a
"yes" may be wrong, so confirm it. Use it where a false positive is cheap (a wasted cache lookup). Where a false
positive is catastrophic — dropping a job — use the exact key EchoMQ uses.

## References

### Sources

- [Redis — Bloom filter](https://redis.io/docs/latest/develop/data-types/probabilistic/bloom-filter/) — the bit
  array, the k hashes, and the no-false-negative guarantee.
- [Redis — BF.RESERVE](https://redis.io/commands/bf.reserve/) — create a Bloom filter with a target
  false-positive rate; a module command.
- [Redis — Cuckoo filter](https://redis.io/docs/latest/develop/data-types/probabilistic/cuckoo-filter/) — a
  fingerprint filter that supports deletion.
- [Redis — CF.RESERVE](https://redis.io/commands/cf.reserve/) — create a Cuckoo filter; a module command.

### Related in this course

- [R7.03 · Probabilistic data structures](/redis-patterns/data-modeling/probabilistic-data-structures) — the module
  hub and the exact-vs-probabilistic frame.
- [R7.03.1 · HyperLogLog](/redis-patterns/data-modeling/probabilistic-data-structures/hyperloglog) — cardinality,
  the count question filters do not answer.
- [R7.01.1 · System of record](/redis-patterns/data-modeling/primary-database/system-of-record) — the exact `de:`
  dedup key in context.
- [/bcs — The Branded Component System](/bcs) — the architecture EchoMQ is built to.
