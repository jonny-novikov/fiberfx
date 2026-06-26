# R7.03 · Probabilistic data structures

> Route: `/redis-patterns/data-modeling/probabilistic-data-structures` · module hub.
> Taught as a **contrast** — never something EchoMQ implements. EchoMQ chose exact dedup; probabilistic
> structures are the road it did not take.

Count unique items with HyperLogLog (12KB fixed), test set membership with Bloom filters, or estimate
frequencies with Count-Min Sketch — trading small accuracy loss for massive memory savings.

When a dataset grows to billions of items, exact counting and exact membership testing become prohibitively
expensive. A probabilistic structure gives up exactness and buys a fixed, tiny footprint with a known error rate.
That is the opposite of the choice EchoMQ made for deduplication. EchoMQ pays O(n) memory to be exact, because a
false "already seen" would silently drop a job. This module teaches the probabilistic family and states the trade
both ways: when the bounded error is acceptable, and when — as for idempotency — it is not.

## The contrast that frames the module — EchoMQ chose exact dedup

EchoMQ deduplicates **exactly**. Every producer-chosen idempotency key is parked at a real string key
`emq:{q}:de:<dedupId>` holding the actual branded job id; `EchoMQ.Metrics.get_deduplication_job_id/3` reads it
back. The admission script adds a second exact check — `EXISTS KEYS[1]` on the job key refuses a duplicate by id:

```elixir
# echo/apps/echo_mq/lib/echo_mq/metrics.ex — the branded job id parked at emq:{q}:de:<dedupId> (verbatim)
def get_deduplication_job_id(conn, queue, dedup_id) when is_binary(dedup_id) do
  key = Keyspace.queue_key(queue, "de:" <> dedup_id)
  case Connector.command(conn, ["GET", key]) do
    {:ok, nil} -> :absent
    {:ok, id} when is_binary(id) -> {:ok, id}
    other -> other
  end
end
```

```lua
-- echo/apps/echo_mq/lib/echo_mq/jobs.ex — @enqueue, the exact dup-refusal by job key (verbatim)
if redis.call('EXISTS', KEYS[1]) == 1 then
  return 0
end
```

A grep of the whole `echo_mq` library finds **zero** probabilistic structures — no `PFADD`, no `BF.`/`CF.`/`CMS.`,
no bloom or cuckoo. That is deliberate: a probabilistic dedup would, at its configured error rate, occasionally
report "already seen" for a job it had never seen, and the queue would drop real work silently. For idempotency the
right answer is the exact key. Probabilistic structures are what you reach for in the **other** direction: when the
cardinality is so large that storing every key exactly is too expensive, and a small, bounded error rate is
acceptable.

## HyperLogLog: counting unique items

HyperLogLog (HLL) estimates the **cardinality** — the count of unique items — of a set. A plain Set storing one
billion unique user ids needs roughly 12GB of RAM. An HLL needs exactly **12KB regardless of how many elements you
add**, with about **0.81% standard error**.

HLL hashes each element and observes the maximum number of leading zeros in the resulting bits. The probability of
seeing N leading zeros is 1/2^N, so the maximum leading-zero run estimates how many distinct elements were added.
Multiple registers and a harmonic mean reduce the variance.

The commands are **core Valkey** — no module required:

```
PFADD visitors:2024-01-30 "user:123" "user:456" "user:789"
PFCOUNT visitors:2024-01-30
PFMERGE visitors:week visitors:2024-01-28 visitors:2024-01-29 visitors:2024-01-30
```

Use it for unique visitors, distinct search queries, distinct IP addresses — any place an approximate count of a
huge set is acceptable. For one million actual unique items the estimate typically falls between 991,900 and
1,008,100.

The `hyperloglog` dive carves this slice, with the exact-Set-vs-HLL memory cliff and the EchoMQ exact-dedup
contrast.

## Bloom Filter: membership testing

A Bloom filter answers "is this item in the set?" with **possible false positives but zero false negatives**. A
"no" is definite; a "yes" is "probably". Items are hashed by several functions, each setting a bit in a shared bit
array; a lookup checks the same bits — any zero proves absence.

Bloom commands are **module commands** (Valkey-Bloom / Redis-Stack — not core), `BF.*`:

```
BF.RESERVE usernames 0.01 1000000
BF.ADD usernames "john_doe"
BF.EXISTS usernames "john_doe"
```

The signature use is **cache penetration**: a flood of requests for non-existent keys each misses the cache and
hits the database. A Bloom filter rejects them immediately — if the filter says the key is absent, no cache or
database lookup happens.

## Cuckoo Filter

A Cuckoo filter is a Bloom filter that **supports deletion**. It stores fingerprints via cuckoo hashing. Cuckoo
commands are **module commands**, `CF.*`:

```
CF.RESERVE sessions 1000000
CF.ADD sessions "session:abc123"
CF.EXISTS sessions "session:abc123"
CF.DEL sessions "session:abc123"
```

| Feature | Bloom | Cuckoo |
|---|---|---|
| Deletion | Not supported | Supported |
| Space (low FP rates) | Good | Better |
| Insert | Faster | Slightly slower |
| Lookup | Slightly slower | Faster |

Reach for Cuckoo when items must leave the filter — tracking active sessions that expire, for example. The
`bloom-and-cuckoo` dive carves both, with the false-positive dial and the contrast against EchoMQ's exact `de:`
membership.

## T-Digest: percentile estimation

Computing exact percentiles means sorting every data point — impractical for a stream. T-Digest keeps a compressed
representation that estimates percentiles accurately, especially at the tails (p99, p99.9). T-Digest commands are
**module commands**, `TDIGEST.*`:

```
TDIGEST.CREATE latencies
TDIGEST.ADD latencies 45.2 89.1 12.5 156.7 23.4
TDIGEST.QUANTILE latencies 0.5 0.95 0.99
```

Use it for SLA monitoring (p99 latency under 100ms), and for performance analysis where an average misleads.

## Count-Min Sketch: frequency estimation

Count-Min Sketch estimates how many times each item has been seen, with **possible over-counting but never
under-counting**. Commands are **module commands**, `CMS.*`:

```
CMS.INITBYDIM page_views 2000 5
CMS.INCRBY page_views "/home" 1 "/about" 1
CMS.QUERY page_views "/home"
```

It fits streaming-frequency questions where exact counts are impractical.

## Top-K: heavy hitters

Top-K tracks the K most frequent items in a stream without storing all of them. Commands are **module commands**,
`TOPK.*`:

```
TOPK.RESERVE trending 10 50 3 0.9
TOPK.ADD trending "topic:redis" "topic:python" "topic:redis" "topic:go"
TOPK.LIST trending
```

It may temporarily misrank but converges — ideal for trending topics, popular products, or frequent errors. The
`count-min-and-t-digest` dive carves frequency, percentile, and heavy-hitter estimation together.

## Choosing the right structure

| Need | Structure | Engine | Error type |
|---|---|---|---|
| Count unique items | HyperLogLog | **core** (`PF*`) | Cardinality ±0.81% |
| Check set membership | Bloom / Cuckoo | **module** (`BF.*`/`CF.*`) | False positives possible |
| Calculate percentiles | T-Digest | **module** (`TDIGEST.*`) | Percentile estimates |
| Count item frequency | Count-Min Sketch | **module** (`CMS.*`) | Over-counting possible |

Every one of these structures answers a question approximately to save memory. The discipline is the same in each
case: name the error you can tolerate, then pick the structure whose error is that. For idempotency the answer is
**none** — so EchoMQ keeps the exact `emq:{q}:de:<dedupId>` key.

## The pattern, applied (the bridge)

- **Pattern** — a probabilistic structure trades a small, known error for a fixed, tiny memory footprint. It
  answers cardinality, membership, frequency, or percentile approximately, at a fraction of the exact cost.
- **Application (counter-example)** — EchoMQ's `emq:{q}:de:<dedupId>` membership is **exact**: O(n) memory, zero
  false positives. For producer idempotency a false positive would drop a job, so the exact key is the right call,
  and the `echo_mq` library carries no probabilistic structure at all.

**A codemojex note (forward-tense / standalone).** Unique-player counts per round or per day are the natural
HyperLogLog fit — the workshop's "uniques" view. codemojex ships no HLL surface today (its keyspace carries no
`PF*` key), so the example here is standalone: an `PFADD`/`PFCOUNT` pair over a per-day key would count distinct
players at 12KB regardless of how many played. It is shown as a possibility, not a claim about the live code.

**Take.** A probabilistic structure is a deliberate trade of exactness for memory, with a known error rate. The
discipline is to name the error you can tolerate and pick the structure whose error matches it — and to notice when
the tolerable error is zero, as it is for idempotency, where EchoMQ keeps the exact `de:` key.

## References

### Sources

- [Redis — Probabilistic data types](https://redis.io/docs/latest/develop/data-types/probabilistic/) — the
  HyperLogLog, Bloom, Cuckoo, Count-Min, T-Digest, and Top-K family in one place.
- [Valkey — PFADD](https://valkey.io/commands/pfadd/) — add elements to a HyperLogLog; cardinality estimation in
  core Valkey, no module required.
- [Valkey — PFCOUNT](https://valkey.io/commands/pfcount/) — the estimated cardinality of one or more HyperLogLogs.
- [Redis — BF.RESERVE](https://redis.io/commands/bf.reserve/) — create a Bloom filter with a target false-positive
  rate; a module command.
- [Redis — CMS.INITBYDIM](https://redis.io/commands/cms.initbydim/) — initialise a Count-Min Sketch; a module
  command for frequency estimation.

### Related in this course

- [R7.03.1 · HyperLogLog](/redis-patterns/data-modeling/probabilistic-data-structures/hyperloglog) — cardinality at
  12KB fixed; the exact-Set-vs-HLL memory cliff.
- [R7.03.2 · Bloom & Cuckoo](/redis-patterns/data-modeling/probabilistic-data-structures/bloom-and-cuckoo) —
  membership with no false negatives; the false-positive dial.
- [R7.03.3 · Count-Min & T-Digest](/redis-patterns/data-modeling/probabilistic-data-structures/count-min-and-t-digest)
  — frequency, percentile, and heavy-hitter estimation.
- [R7.01.1 · System of record](/redis-patterns/data-modeling/primary-database/system-of-record) — the exact-dedup
  home: the job HASH and the `de:` key.
- [/bcs — The Branded Component System](/bcs) — the architecture EchoMQ and codemojex are built to.
