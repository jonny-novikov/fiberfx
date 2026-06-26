# R7.03.3 · Count-Min Sketch & T-Digest

> Route: `/redis-patterns/data-modeling/probabilistic-data-structures/count-min-and-t-digest` · dive 3.
> Frequency, heavy-hitter, and percentile estimation over a stream. A contrast with EchoMQ's exact counters,
> never a thing EchoMQ implements.

Two more questions a stream raises — "how often did each item appear?" and "what is the p99?" — have exact answers
that are too expensive at scale, and probabilistic answers that are cheap and bounded. Count-Min Sketch estimates
frequency, Top-K finds heavy hitters, and T-Digest estimates percentiles. All three are **module commands**
(Valkey-Bloom / Redis-Stack), not the core engine.

## Count-Min Sketch — frequency, over-counting only

Count-Min Sketch estimates how many times each item has been seen. Its error is one-sided: it may **over-count**,
never under-count. It is a small grid of counters with several hash rows; an increment bumps one counter per row,
and a query takes the **minimum** across the rows for that item. The minimum is the tightest estimate, because
collisions only ever add to a counter, so the smallest of the rows has the fewest stray additions.

```
CMS.INITBYDIM page_views 2000 5     # width 2000, depth 5 — a module command
CMS.INCRBY page_views "/home" 1 "/about" 1
CMS.QUERY page_views "/home"        # an estimate ≥ the true count, never below it
```

The trade is a fixed-size grid against exact per-key counters. For a few hot keys an exact `HINCRBY` is fine; for
millions of distinct keys in a stream the grid bounds the memory while keeping the error one-sided and small.

## Top-K — the heavy hitters

Top-K tracks the K most frequent items in a stream without storing all of them. It may temporarily misrank but
converges to the true ranking over time:

```
TOPK.RESERVE trending 10 50 3 0.9   # top 10 — a module command
TOPK.ADD trending "topic:redis" "topic:python" "topic:redis" "topic:go"
TOPK.LIST trending                  # the current top items
```

It fits trending topics, popular products, or the most frequent errors — the few items that matter, found without
counting every item exactly.

## T-Digest — percentiles at the tails

An exact percentile means sorting every observation — impractical for a continuous stream of latencies. T-Digest
keeps a compressed sketch that estimates percentiles accurately, especially at the tails (p99, p99.9) where an
average tells you nothing:

```
TDIGEST.CREATE latencies            # a module command
TDIGEST.ADD latencies 45.2 89.1 12.5 156.7 23.4
TDIGEST.QUANTILE latencies 0.5 0.95 0.99   # estimated p50, p95, p99
```

It fits SLA monitoring ("p99 latency under 100ms") and any analysis where the average hides the tail. The estimate
is close, not exact — bought for a fixed footprint over an unbounded stream.

## The EchoMQ contrast — exact counters, by choice

EchoMQ's counters are **exact integers**, not sketches. The `attempts` field of the job HASH is an exact retry
fence — `@enqueue` writes it `'0'`, and each delivery increments it with `HINCRBY` — and the dedup membership is the
exact `emq:{q}:de:<dedupId>` key from the hub. A grep of the `echo_mq` library finds no `CMS.`, `TDIGEST.`, or
`TOPK.` anywhere.

The reason is the same as for dedup: these counters drive **decisions**, not dashboards. The `attempts` fence
decides whether a job has exhausted its retries and must move to the dead set; an over-count would dead-letter a
job too early, an under-count would loop a poison job forever. A Count-Min Sketch's "over-count only, bounded
error" is exactly the wrong property for a counter that gates a control-flow decision. Sketches are for
**observability over a huge stream** where a small bounded error is fine — page-view frequency, trending topics,
p99 latency — not for a counter the system acts on.

## The bridge

- **Pattern** — Count-Min Sketch (frequency, over-count only), Top-K (heavy hitters), T-Digest (percentiles):
  bounded-error estimates over an unbounded stream, at a fixed footprint. For observability, not control flow.
- **Application (counter-example)** — EchoMQ's `attempts` fence (`HINCRBY` on the job HASH) and `de:` dedup are
  **exact integers and exact keys**: they gate decisions, so a bounded error is unacceptable.

**Take.** Count-Min, Top-K, and T-Digest answer "how often" and "what percentile" cheaply, with a bounded error,
over streams too large to count exactly. Use them for observability. Where the count gates a decision — EchoMQ's
retry fence — keep the exact integer, as EchoMQ does.

## References

### Sources

- [Redis — Count-Min Sketch](https://redis.io/docs/latest/develop/data-types/probabilistic/count-min-sketch/) — the
  counter grid and the minimum-across-rows query.
- [Redis — CMS.INITBYDIM](https://redis.io/commands/cms.initbydim/) — initialise a Count-Min Sketch by width and
  depth; a module command.
- [Redis — T-Digest](https://redis.io/docs/latest/develop/data-types/probabilistic/t-digest/) — percentile
  estimation, accurate at the tails.
- [Redis — Top-K](https://redis.io/docs/latest/develop/data-types/probabilistic/top-k/) — heavy-hitter tracking
  without storing every item.

### Related in this course

- [R7.03 · Probabilistic data structures](/redis-patterns/data-modeling/probabilistic-data-structures) — the module
  hub and the exact-vs-probabilistic frame.
- [R7.03.2 · Bloom & Cuckoo](/redis-patterns/data-modeling/probabilistic-data-structures/bloom-and-cuckoo) —
  membership estimation; the same one-sided-error idea.
- [R7.01.1 · System of record](/redis-patterns/data-modeling/primary-database/system-of-record) — the exact job
  HASH (`attempts`, `de:`) the sketches are contrasted against.
- [/bcs — The Branded Component System](/bcs) — the architecture EchoMQ is built to.
