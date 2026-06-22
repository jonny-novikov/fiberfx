# Write-behind (write-back)

> Route: `/redis-patterns/caching/write-behind` · Module R1.03 · Source: `content/fundamental/write-behind.md.txt`
> · Grounding: `EchoCache.Journal` — the transactional outbox, the async job lane over EchoMQ, the SQLite WAL.
> Engine: Valkey.

Maximize write throughput by writing only to Valkey and asynchronously syncing to the database later—trades immediate
durability for performance. The application writes only to Valkey, which acknowledges instantly. A separate background
process periodically synchronizes changes to the backing store, batching writes for efficiency.

## How It Works

The pattern is three steps, and the database is reached on none of them:

1. **The application writes data to Valkey.**
2. **Valkey acknowledges immediately** — the client receives success.
3. **A background process periodically reads changed data from Valkey and writes it to the database.**

The store update happens "behind" the cache write, hence the name. The application stores the new value and records that
the key changed — a write buffer, built as a List with `LPUSH` or a dirty-set with `SADD`. The caller is acknowledged
the moment both succeed. A separate background worker drains the buffer on a timer, reads the current value for each
changed key, and writes the batch to the database in one round trip. Nothing about the acknowledgement waits for the
database, and the source is reached far less often than the application writes.

## Redis Commands Used

The application writes to Valkey and nothing else:

```
SET counter:page_views "15847293"
INCRBY counter:page_views 1
```

No database interaction occurs during these operations. The background sync process later reads these values and
persists them. The write path adds one move to mark the key changed — `LPUSH writebuf <key>` onto a List buffer, or
`SADD dirty <key>` onto a dirty-set — and the flush path drains it (`RPOP`, or `SMEMBERS`) and reads the current value
before writing the source.

**On EchoCache.** The deferral is real code in `EchoCache.Journal` — the transactional outbox. The writer's verb,
`intend_and_enqueue/4` (`journal.ex:66`), mints a `JOB` id, records the intent in a local SQLite file, hands the apply to
the async job lane over EchoMQ with `Lanes.enqueue`, and marks the intent enqueued. The write returns after the **local
record**; the bus carries the apply off the write path. The job lane itself is `EchoCache.Coherence.enqueue/5`
(`coherence.ex:89`) — "the job lane: at-least-once over EchoMQ's fair lanes." That lane is the EchoMQ protocol; the
[`/echomq` course](/echomq) teaches it in depth.

## Advantages

- **Extremely low write latency** — operations complete as soon as Valkey acknowledges (and, on EchoCache, after one
  local SQLite append), because no database round trip is on the request path.
- **High throughput** — the database is protected from write storms. Many rapid updates collapse into a single database
  write during sync.
- **Write coalescing** — if a counter is incremented 1000 times per second, only the final value needs to be written to
  the database, not 1000 individual increments.

## The Durability Trade-off

This pattern trades durability for speed, and the cost is exact:

- **Data loss risk** — if the cache fails before synchronization, any writes since the last sync are lost. The cache
  becomes the system of record during the sync window.
- **Eventual consistency** — the database lags behind the cache. Queries directly to the database may return stale data.

Several strategies reduce the risk. EchoCache closes the window not with a cache-side AOF but with the outbox: the intent
is recorded in a **SQLite WAL** before the bus hears it (`journal.ex:125-126` — `PRAGMA journal_mode=WAL`, `synchronous=NORMAL`),
so a bus restart loses the queued obligation but `replay/2` (`journal.ex:103`) re-enqueues every intent not yet covered
by the applied memory. The bus already deduplicates a re-enqueued job id and newer-wins makes a re-applied version
harmless. The plain-Redis dials still apply where the buffer is a raw List:

- **Persistence** — append every write to a log (AOF) to bound loss back to the last fsync, or snapshot (RDB) to bound it
  to the last snapshot.
- **Shorter sync intervals** — narrow the window of potential loss.
- **Replication** — survive a single-node failure.

The flush interval sizes the window; durable storage sets whether a crash in it loses anything. Both are dials, not
defaults — the second dive measures them.

## Ideal Use Cases

Write-behind excels where a small, bounded loss is acceptable in exchange for write throughput:

- **Counters and metrics** — page views, likes, impressions, where losing a few counts is acceptable.
- **High-velocity session updates** — frequent session touches where database latency would be prohibitive.
- **Analytics ingestion** — collecting telemetry at high speed.
- **Coherence obligations on EchoCache** — a changed risk limit must reach every cache copy; the job lane carries it
  at-least-once, and the journal makes the obligation survive a bus restart.

Never use write-behind for data where loss is unacceptable:

- Financial transactions.
- Order processing.
- User credentials or authentication data.
- Any data with regulatory compliance requirements.

## The Sync Process

The background synchronization typically works in four steps, and must handle failure so nothing is silently dropped:

1. **Scan for keys that have changed** — using a "dirty" flag, a buffer List, or a timestamp.
2. **Read current values from the cache** — so the source always receives the latest state, never an intermediate one.
3. **Write to the database** — batched, one round trip for many keys.
4. **Mark keys as synchronized** — clear them from the buffer or dirty-set.

If a database write fails, the key must remain marked for retry — the buffer is the only copy until the source confirms.
On EchoCache the equivalent is `compact/1` (`journal.ex:106`): an intent is retired only when its name carries an applied
version at least as new — coverage, not acknowledgment, so the hot path pays no per-intent completion write. A burst of
writes to one key collapses to a single source write: the dirty-set holds the key once however often it changed, and the
flush reads its current value. The third dive walks that coalescing step.

## On EchoCache — the lane that remembers

`EchoCache.Journal` is the write-behind path made durable. The bus stays volatile by decision; durability for the job
lane's obligations lives in a per-group SQLite file standing beside the bus — the `intents` outbox (record → enqueue →
mark) and the `applied` memory (the last version applied per name). The committed measure: `143 us per record-and-mark
pair` at the writer's edge, a remembered-lane median of `524 us` against the bare lane's 148 — "3.5 times the latency
buys an outbox, a last word per name, and a replay that survives the bus" (`content/bcs4.4.md`). The 29-byte coherence
message — `id <> ":" <> version` (`coherence.ex:35`) — is the cargo the lane carries.

## References

### Sources
- [Valkey — SET](https://valkey.io/commands/set/) — sets value (and TTL with `PX`) in one command; the write the cache acknowledges.
- [Valkey — LPUSH](https://valkey.io/commands/lpush/) — pushes a changed key onto the head of the write-buffer List.
- [Valkey — RPOP](https://valkey.io/commands/rpop/) — the flush worker drains the buffer from the tail in arrival order.
- [Redis — Documentation](https://redis.io/docs/) — Lists, Sets, and persistence (RDB, AOF), the structures a write buffer is built from.
- [Sanfilippo, S. — antirez weblog](https://antirez.com/) — the Redis creator on durability, persistence, and what a fast store can honestly promise.

### Related in this course
- [R1.03.1 · The async buffer](/redis-patterns/caching/write-behind/async-buffer) — write the cache now, queue the DB sync.
- [R1.03.2 · The durability trade-off](/redis-patterns/caching/write-behind/durability) — the unflushed window and how to bound it.
- [R1.03.3 · Coalescing writes](/redis-patterns/caching/write-behind/coalescing) — many updates to one key, one flush.
- [R1.02 · Write-through](/redis-patterns/caching/write-through) — the synchronous, always-fresh contrast.
- [R1 · Caching](/redis-patterns/caching) — the chapter.
- [/echomq](/echomq) — the fair-lanes job queue the coherence lane rides.
