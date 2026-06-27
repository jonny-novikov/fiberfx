# The road ahead — the arc R3 to R8, and the doors beyond

> Route: `/redis-patterns/queues/the-road-ahead` · Dive R3·3 · Chapter R3 Reliable Queues · BCS contract-sheet.
> Grounding: the course arc over the real **EchoMQ** worker path (`echo/apps/echo_mq`), the **codemojex** consumer
> (`echo/apps/codemojex`), and the durable floor (`EchoStore.StreamArchive` → the Graft floor). Doors: `/echomq/queue`
> (the Queue pillar), `/echo-persistence` (the durability dial), `/bcs`.

The reliable queue is the spine. Each later chapter adds one capability on top of it — and on the far side wait the
two systems that put the patterns to work: the EchoMQ protocol in depth, and the durable floor beneath it.

## The arc — one queue, one sense at a time

R3 builds a queue that is correct under a crash. A `JOB` moves from `emq:{q}:pending` into `emq:{q}:active` under a
server-clock lease and on to completion; a worker that dies leaves its job leased and recoverable, not lost. That
correct queue is the floor. Every chapter after it adds exactly one capability, and each is one more Valkey structure
put to one more use.

- **R4 · Time, Delay & Priority** turns the sorted set into a clock. EchoMQ already schedules: `EchoMQ.Jobs.enqueue_at`
  and `enqueue_in` park a job on `emq:{q}:schedule` at a server-clock run-at, and `EchoMQ.Jobs.promote/3` releases it
  to pending once due. The queue learns *when*.
- **R5 · Streams & Events** adds the durable log. `EchoMQ.Events` records lifecycle transitions on an ordered,
  replayable stream so the queue learns to *remember and replay*.
- **R6 · Flow Control & Scale** keeps the tier stable under load — fair lanes (`EchoMQ.Lanes`), per-group limits, and
  bulk batches. The queue learns *restraint*.
- **R7 · Data Modeling & Memory** attends to how the job data lives in RAM — compact encodings and capped structures.
  The queue learns to *spend memory well*.
- **R8 · Production & Operations** runs the tier at scale: pooling, failover, and operating everything above. The
  queue learns to *survive production*.

## The durable floor — where a job lands for keeps

A job that exhausts its retries, or whose completion is archived, reaches the **persistence floor** beneath the
volatile tiers. `EchoMQ.Stalled.check/3` dead-letters a repeatedly-stalled job; `EchoStore.StreamArchive` folds a
completed stream into the durable page engine `EchoStore.Graft` (CubDB → Tigris remote behind a create-only commit
fence). Durability is a **dial** a system turns — hold nothing, a bounded in-heap window with a checkpoint, or
commit-per-record replicated off-box — and the enqueue hot path touches only a small, mostly-idle outbox, never a
database on the path of every claim. The comparison is **Oban**, which keeps jobs in the same PostgreSQL as the data
so a job and a row commit in one transaction; Echo separates the bus from the store and buys an in-memory hot path
plus the dial, giving up that one-transaction coupling. The durable floor is taught end to end in `/echo-persistence`.

## The doors beyond

R3 hands off twice. The patterns have shown the techniques — the leased state machine, the inline Lua, the fencing
token, the reliable queue — and grounded each in how EchoMQ really uses it. What this course deliberately does not do
is teach the protocol in full: the complete script bundle, the version-fence governance, the worker-pool metronome.
That depth is the **EchoMQ Queue pillar** at `/echomq/queue`. And the durable substrate beneath a reaped or archived
job — the durability dial, the page engine, the remote — is `/echo-persistence`. The patterns are the vocabulary;
EchoMQ and the persistence floor are the systems that speak it.

## References

### Sources

- [Redis — Sorted sets](https://redis.io/docs/latest/develop/data-types/sorted-sets/) — the ZSET as a clock and a
  priority ladder, the structure R4 turns into delay and run-at.
- [Redis — Streams](https://redis.io/docs/latest/develop/data-types/streams/) — the durable, replayable log R5 teaches
  on top of the reliable queue.
- [Valkey — TIME](https://valkey.io/commands/time/) — the server clock the schedule run-at and the lease both read.
- [llms.txt — the convention](https://llmstxt.org/) — the machine-readable map format both courses publish for agents.

### Related in this course

- [R3 · Reliable Queues](/redis-patterns/queues) — the chapter this dive closes.
- [R3 · States as locations](/redis-patterns/queues/states-as-locations) — dive 2: the lifecycle as one atomic Lua
  move, the foundation the later chapters build on.
- [/echomq/queue](/echomq/queue) — the EchoMQ Queue pillar: the protocol in depth.
- [/echo-persistence](/echo-persistence) — the durable floor a dead-lettered or archived job reaches.
- [The Branded Component System](/bcs) — the architecture law the whole arc stands on.
