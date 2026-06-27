# Stalled recovery — reclaim a dead worker's job

> **Route:** `/redis-patterns/queues/stalled-recovery` · **Module:** R3.03 · **Pattern:** reliable-queue (the recovery treatment)
> **Grounding:** `echo/apps/echo_mq` — `EchoMQ.Stalled` (the count-thresholded sweep), `EchoMQ.Jobs.reap/2` (the crash-recovery reaper), the `active` lease ZSET, the server clock (`TIME`). Consumer: `Codemojex.CommandWorker`.

Guarantee at-least-once message delivery using `LMOVE` to atomically transfer messages to a processing list, enabling recovery if consumers crash before completing work.

A worker can die mid-job: the process is killed, the box loses power, the network partitions. The job it claimed is in flight, no live worker is finishing it, and at-least-once delivery means that job must reach another worker — never be lost. Stalled recovery is the separate sweep that finds a job whose worker stopped and returns it to be claimed again. The hard part is doing it without redelivering a job whose worker is merely slow, and without two sweeps reclaiming the same job twice.

## Recovery from Failures

A separate monitor process — sometimes called a "reaper" — periodically scans the in-flight set for stalled jobs. The source describes the list-based form: check each processing queue, and if a message has been there longer than a timeout (say ten minutes), assume the worker died and move it back to the main queue with `LMOVE processing work_queue RIGHT RIGHT`. This guarantees at-least-once delivery — a message may be processed more than once, but it is never lost.

EchoMQ answers the same question — *which in-flight job has no live worker?* — with a sharper signal than a wall-clock age. When a worker claims a job, `EchoMQ.Jobs.claim/3` puts its id on the `active` set scored by its **lease deadline** (`now + lease_ms`, read from the server clock with `TIME`). A worker that finishes calls `complete`; a worker that is still working extends its lease. A worker that dies does neither: its lease deadline passes, and the job sits in `active` with a score in the past. The recovery sweep does not measure how long a message has waited — it reads `ZRANGEBYSCORE active -inf now`, every member whose lease deadline is at or before the server clock. Lease expired ⇒ no live worker ⇒ recover.

Two layers ride that one signal:

- **The reaper — crash recovery.** `EchoMQ.Jobs.reap/2` runs `@reap`: one server-side scan that returns every expired-lease id from `active` to `pending` once, with no count. `EchoMQ.Consumer` runs it on every beat, so a crashed worker's job is back in line within one cadence. This is at-least-once delivery in one verb.
- **The sweep — stall-count recovery.** `EchoMQ.Stalled.check/3` runs `@sweep_stalled` on top: each pass increments a per-job `stalled` field (`HINCRBY`), recovers a job whose count is below `max_stalled`, and dead-letters one at or above it — `HSET state dead`, `ZADD emq:{q}:dead`. A job that repeatedly stalls is not recovered forever; it reaches the morgue and stops poisoning the queue.

Both run inside one Lua script, one `EVALSHA`. The read (which leases expired), the decide (recover or dead-letter), and the write (move the id, bump the field) happen on the server's single thread with no interleaving — so each expired lease is reclaimed exactly once per sweep, and the attempt and stall counters are incremented in-script, never by a client that could lose the update. That indivisibility is the whole pattern: an app-side loop that lists the in-flight set, probes each id, then moves it in separate round trips opens a window where two sweeps reclaim the same job. The atomic move closes it.

## The three dives

The arc is *detect → recover safely → why one step*.

1. **Lock-expiry detection** — the lease deadline as a liveness signal. A claim scores the job on `active` at `now + lease_ms`; a live worker pushes that score forward; a dead worker lets it pass. `ZRANGEBYSCORE active -inf now` is the whole detector — no per-job probe.
2. **Two-phase mark/recover** — the `stalled` count as a grace pass and the dead-letter threshold. A job recovered below `max_stalled` returns to `pending`; a job at or above it goes to `dead`, so a repeatedly-stalling job is bounded.
3. **Atomic vs non-atomic** — the centrepiece. One `EVALSHA` detect-and-move (`@sweep_stalled`) versus an app-side multi-round-trip loop. The double-recovery window, made precise.

## The pattern, applied

The pattern says *a separate sweep reclaims a job whose worker died, and the detect-and-move must be one indivisible step or two overlapping sweeps redeliver it.* In EchoMQ that one step is `@sweep_stalled` (the `EchoMQ.Stalled` script) over the `active` lease ZSET, on the server clock. A `CMD` command job that `Codemojex.CommandWorker` claimed and never completed — its handler crashed mid-dispatch — has a lease deadline in the past; the next sweep returns it to `cm.bot.commands`'s `pending`, and another worker drains it.

A job that exhausts its stall budget does not vanish. At `max_stalled` it lands in `emq:{q}:dead`, and when the bus trims its stream history, `EchoStore.StreamArchive` folds the trimmed segments into the durable Graft floor and on to Tigris — deep history without resident memory, readable beside the live tail. The recovery decision lives on the volatile bus; the record of what died lives on the persistence floor.

## References

### Sources

- [Redis — *EVALSHA*](https://redis.io/commands/evalsha/) — the cached atomic script: detect-and-move runs as one indivisible step on the server's single thread.
- [Redis — *EVAL / scripting*](https://redis.io/commands/eval/) — why a Lua sweep cannot interleave with another sweep.
- [Valkey — *Sorted Sets*](https://valkey.io/topics/sorted-sets/) — the scored structure the `active` lease set is built on; `ZRANGEBYSCORE` reads every expired lease.
- [Valkey — *SET*](https://valkey.io/commands/set/) — a value with a `PX` expiry in one command, the lease-renewal primitive a heartbeat would use.

### Related in this course

- [R3 · Reliable Queues](/redis-patterns/queues) — the chapter.
- [R3.03.1 · Lock-expiry detection](/redis-patterns/queues/stalled-recovery/lock-expiry-detection) — the lease as a liveness signal.
- [R3.03.2 · Two-phase mark/recover](/redis-patterns/queues/stalled-recovery/two-phase-mark-recover) — the stall count and the dead-letter threshold.
- [R3.03.3 · Atomic vs non-atomic](/redis-patterns/queues/stalled-recovery/atomic-vs-non-atomic) — the double-recovery window.
- [The reliable queue](/redis-patterns/queues/the-reliable-queue) — the family in one place.
- [R2.01 · Atomic updates](/redis-patterns/coordination/atomic-updates) — the one-step atomic move the sweep needs.
- [/echomq/queue](/echomq/queue) — the EchoMQ Queue pillar: the lease, the reaper, the state machine in depth.
- [/echo-persistence](/echo-persistence) — the durability dial a dead-lettered job reaches.
