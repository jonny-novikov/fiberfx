# The durability window

> Route: `/redis-patterns/caching/write-behind/durability` · Module R1.03 · dive 2 · Source:
> `content/fundamental/write-behind.md.txt` (*The Durability Trade-off* + *Mitigating Data Loss*) · Grounding:
> `EchoStore.Journal` — the SQLite WAL, `replay/2`, `compact/1`; the measured price from `bcs.4.md`.
> Engine: Valkey.

Between a write and its flush, the cache holds the only copy. That window is the price of the throughput. The flush
interval sets its width, and durable storage sets whether a crash in it loses anything.

## The unflushed window

The trade is the inverse of write-through. Write-through writes the database on the request, so the source is always
current and a cache loss costs nothing. Write-behind defers that write, so between a write and the next flush the
database is behind and the cache holds the only copy of those changes. If the cache is lost in that window — a crash, a
failover, an eviction — the unflushed writes are gone.

The window's width is the flush interval. With a one-second interval and a steady stream, roughly one second of writes
is at risk at any moment; with a five-second interval, five seconds is. Narrowing the interval narrows the window but
shrinks the batches, which is exactly the throughput the pattern was bought for. The choice is a dial, not a default.

- **durability window** — the span from a write landing in the cache to its flush. In it, the cache holds the only copy
  of that write.
- **at-risk writes** — everything written but not yet flushed. A crash in the window loses exactly these.
- **flush interval** — the dial. Shorter narrows the window and the loss; longer batches more and risks more.
- **RPO** — recovery point objective: how much recent data a system may lose on a crash. Write-behind's RPO is bounded
  by the window.

A second lever shrinks the window without touching the interval: flush on shutdown. A clean stop drains the buffer
first, so a planned restart loses nothing — only an unclean crash hits the window.

## Persistence bounds the loss

The flush interval bounds *how many* writes the window holds. Durable storage bounds *whether a crash actually loses
them*. The cache can run purely in memory, snapshot to disk on a schedule (RDB), or append every write to a log (AOF).
Each mode changes what survives a process restart, and so changes the real risk of the unflushed window.

- **in-memory only** — fastest; on a crash the whole keyspace is gone, buffer included. The buffer must be treated as
  expendable.
- **RDB snapshot** — a restart restores the keyspace as of the last periodic snapshot, so loss is bounded back to the
  snapshot interval rather than the flush interval.
- **AOF (append-only)** with `appendfsync everysec` — a restart replays the log up to the last fsync, so the buffer
  survives and the worker flushes it. Loss is bounded to roughly one second.

Two dials bound the risk: the flush interval sizes the window, and durable storage sets whether a crash in it actually
loses anything.

## On EchoStore — the lane that remembers

EchoStore does not put an append log on the cache. The bus stays volatile by decision; durability for the job lane's
obligations lives in a per-group **SQLite WAL** standing beside the bus (`journal.ex:125-126` — `PRAGMA
journal_mode=WAL`, `synchronous=NORMAL`). The outbox closes the window by construction: the intent is recorded *before*
the bus hears it, and `replay/2` (`journal.ex:103`) re-enqueues every intent not yet covered by the applied memory after
a bus restart. The bus already deduplicates a re-enqueued job id and newer-wins makes a re-applied version harmless, so
replay is at-least-once and harmless by comparison. `compact/1` (`journal.ex:106`) retires an intent only when its name
carries an applied version at least as new — coverage, not acknowledgment.

The committed record prices the memory exactly. The writer's edge costs `143 us per record-and-mark pair`; the
remembered-lane median is `524 us` against the bare lane's 148 — and after a staged bus loss, replay re-enqueued
`exactly 30 uncovered intents re-enqueued in seq order`. The chapter's own closing words: "3.5 times the latency buys an
outbox, a last word per name, and a replay that survives the bus" (`bcs.4.md`).

`synchronous=NORMAL` is the stated trade: every process crash, consumer kill, and bus restart this part stages is fully
covered, and only a machine power loss may trim the unsynced tail of the WAL — the layer that closes that gap is a
separate off-box process, referenced and deliberately not built in.

## References

### Sources
- [Valkey — SET](https://valkey.io/commands/set/) — `SET … PX` sets value and TTL atomically; the cache write whose loss the window measures.
- [Redis — Documentation](https://redis.io/docs/) — persistence: RDB snapshots, AOF, and what each survives a restart.
- [Sanfilippo, S. — antirez weblog](https://antirez.com/) — the Redis creator on durability and the honest limits of a fast store.
- [Valkey — RPOP](https://valkey.io/commands/rpop/) — the flush drain whose interval sets the width of the window.

### Related in this course
- [R1.03.1 · The async buffer](/redis-patterns/caching/write-behind/async-buffer) — the previous dive.
- [R1.03.3 · Coalescing writes](/redis-patterns/caching/write-behind/coalescing) — the next dive.
- [R1.03 · Write-behind](/redis-patterns/caching/write-behind) — the module hub.
- [/echomq/cache](/echomq/cache) — the EchoStore Journal replays the outbox, in depth.
