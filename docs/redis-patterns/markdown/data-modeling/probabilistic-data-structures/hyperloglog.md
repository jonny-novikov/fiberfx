# R7.03.1 · HyperLogLog

> Route: `/redis-patterns/data-modeling/probabilistic-data-structures/hyperloglog` · dive 1.
> Cardinality at a fixed 12KB. A contrast with EchoMQ's exact dedup, never a thing EchoMQ implements.

HyperLogLog estimates how many **distinct** items a set holds, at a fixed 12KB of memory regardless of how many you
add, with about 0.81% standard error. It is the cleanest example of the probabilistic trade: a known, small error
bought for a flat, tiny footprint.

## The memory cliff

A plain Set is exact: to count one billion unique ids it stores all one billion, roughly **12GB** of RAM. A
HyperLogLog is fixed: **12KB** for the same billion, and 12KB for a thousand, and 12KB for a trillion. The cost
does not grow with the cardinality — it is paid once.

The structure works by hashing each element and watching the maximum run of leading zeros. The chance of an N-zero
run is 1/2^N, so a long run is evidence of many distinct elements. A single estimator would be noisy, so HLL keeps
many registers and combines them with a harmonic mean. The result is an estimate with about 0.81% standard error —
for one million actual uniques, typically between 991,900 and 1,008,100.

The trade is exactness for memory. You cannot ask an HLL "is `user:123` in here?" — it does not store members, only
the evidence of how many there were. What you get back is a count, close but not exact.

## The commands — core Valkey

HyperLogLog is **core Valkey**: `PFADD`, `PFCOUNT`, `PFMERGE` ship in the engine, no module needed. The `PF` prefix
is a nod to Philippe Flajolet, who co-invented the algorithm.

```
PFADD visitors:2024-01-30 "user:123" "user:456" "user:789"   # add elements (creates the key)
PFCOUNT visitors:2024-01-30                                  # the estimated cardinality
PFMERGE visitors:week visitors:2024-01-28 visitors:2024-01-29 visitors:2024-01-30  # union of HLLs
```

`PFADD` returns 1 if the internal registers changed (a likely-new element) and 0 if not. `PFMERGE` computes the
union — the count of distinct elements across several HLLs — which is how a daily uniques HLL rolls up into a weekly
one without double-counting a visitor who returned.

A Valkey note on the structure: an HLL is stored in a string; small cardinalities use a compact **sparse**
encoding and convert to the fixed-size **dense** encoding as the cardinality grows, which is why a brand-new HLL is
smaller than 12KB and a large one settles at 12KB.

## The EchoMQ contrast — exact, by choice

EchoMQ counts and dedups **exactly**, and does not use HyperLogLog anywhere. Its dedup parks each producer
idempotency key at a real string key holding the actual branded job id:

```elixir
# echo/apps/echo_mq/lib/echo_mq/metrics.ex (verbatim)
def get_deduplication_job_id(conn, queue, dedup_id) when is_binary(dedup_id) do
  key = Keyspace.queue_key(queue, "de:" <> dedup_id)
  case Connector.command(conn, ["GET", key]) do
    {:ok, nil} -> :absent
    {:ok, id} when is_binary(id) -> {:ok, id}
    other -> other
  end
end
```

The difference is the question each answers. An HLL answers "**how many** distinct ids" approximately. EchoMQ's
`de:` key answers "**which** id, exactly" — it must, because the dedup decides whether to admit or drop a job, and a
wrong "already seen" silently loses work. HyperLogLog cannot answer the membership question at all (it stores no
members), and even if it could, its error rate is the wrong property for idempotency. So the road EchoMQ took is the
exact key; HyperLogLog is the road for the other problem — counting a huge population cheaply.

## The bridge

- **Pattern** — HyperLogLog: cardinality of a huge set at a fixed 12KB, ~0.81% error. Exactness traded for a flat,
  tiny footprint; no members stored.
- **Application (counter-example)** — EchoMQ's `emq:{q}:de:<dedupId>` is exact membership, O(n) memory, zero false
  positives. The dedup must be exact, so EchoMQ pays the memory rather than estimate.

**A codemojex note (forward-tense / standalone).** Counting distinct players per day is the natural HLL fit:
`PFADD cm:uniques:2024-01-30 <player>` on each guess, `PFCOUNT` for the dashboard — 12KB whether ten or ten million
played. codemojex ships no HLL surface today (no `PF*` key in its keyspace), so this is a possibility for the
workshop's "uniques" view, not a claim about the live code.

**Take.** HyperLogLog is the trade in its clearest form: a 12GB exact count becomes a 12KB estimate with a 0.81%
error. Use it when you need *how many* across a huge population and a sub-percent error is fine — and notice it
cannot answer *which*, which is exactly why EchoMQ's idempotency keeps an exact key.

## References

### Sources

- [Valkey — PFADD](https://valkey.io/commands/pfadd/) — add elements to a HyperLogLog; core Valkey, no module.
- [Valkey — PFCOUNT](https://valkey.io/commands/pfcount/) — the estimated cardinality of one or more HyperLogLogs.
- [Valkey — PFMERGE](https://valkey.io/commands/pfmerge/) — the union of several HyperLogLogs into one.
- [Redis — HyperLogLog](https://redis.io/docs/latest/develop/data-types/probabilistic/hyperloglogs/) — how the
  registers and the harmonic mean produce a 0.81%-error cardinality.

### Related in this course

- [R7.03 · Probabilistic data structures](/redis-patterns/data-modeling/probabilistic-data-structures) — the module
  hub and the exact-vs-probabilistic frame.
- [R7.03.2 · Bloom & Cuckoo](/redis-patterns/data-modeling/probabilistic-data-structures/bloom-and-cuckoo) —
  membership, where HLL cannot help.
- [R7.01.1 · System of record](/redis-patterns/data-modeling/primary-database/system-of-record) — the exact `de:`
  dedup key in context.
- [/bcs — The Branded Component System](/bcs) — the architecture EchoMQ is built to.
