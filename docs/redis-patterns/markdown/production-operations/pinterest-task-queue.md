# Pinterest: task queues & partitioning

> R8.03 · Production & Operations — module hub · route `/redis-patterns/production-operations/pinterest-task-queue`

PinLater is a Thrift service Pinterest built to manage the scheduling and execution of asynchronous jobs:
**enqueue, dequeue, ACK** over two storage backends — MySQL and Redis — running more than **500 job queues
processing north of six million jobs per minute** across more than ten EC2 clusters. It proves two patterns
worth taking apart: **functional partitioning** (different data on the store that fits its access pattern, the
shard carried in the id) and the **list-based reliable queue** (never lose a job to a crash between claim and
ack).

This module reads PinLater and the sharded Pinterest fleet as the case study, then ties each idea back to one
verified surface in the BCS bus. Pinterest's own stack legitimately names Redis, MySQL, and memcache — that is
their history, quoted as theirs. The BCS bus is Valkey-only; the worked consumer is codemojex.

Grounding: the Pinterest source pack — *Open-sourcing PinLater* and *Sharding Pinterest: How we scaled our MySQL
fleet* (Pinterest Engineering), the `pinterest/pinlater` README, and the Redis `RPOPLPUSH`/`LMOVE` docs — for the
case study; the as-built `echo/apps/echo_mq` (`Lanes`, `Jobs`, `Keyspace`) and `echo/apps/echo_data`
(`BrandedId`) for the applied half. Every external claim cites a real source; no Pinterest number, Redis command,
or echo surface is invented.

## §1 · The system: PinLater

*"PinLater is a Thrift service to manage scheduling and execution of asynchronous jobs."* Written in Java,
Apache-2.0, open-sourced in 2014 and archived in February 2018 (succeeded by Pacer). Its surface is three core
actions — **`enqueue`, `dequeue`, `ACK`** — over three components:

1. *"A stateless Thrift service to manage job submission and scheduling."*
2. *"A storage backend to store the jobs and state."*
3. *"Worker pools to execute the jobs."*

Reliability is **explicit acks with automatic retry at a configurable delay**: a worker replies a positive or
negative ACK depending on whether execution succeeded or failed, and a failed job is retried later. Per-job knobs
are set at enqueue time — *"Priorities, delayed execution and flexible retry policies that can be specified per
job at enqueue time"* — plus checkpointing for long-running jobs.

Two storage backends sit behind it. The README guidance: services should *"default to use the MySQL backend as
long as the QPS is in the lower to mid range (no more than 1000 QPS per shard). If the QPS is expected to be
higher than this, then the Redis implementation should be used."* Redis was the high-throughput backend; MySQL
was the durable default.

## §2 · The two ideas it proves

PinLater and the fleet behind it carry two patterns this course teaches applied.

**Functional partitioning — polyglot by access pattern.** Pinterest keeps different data on different stores,
chosen by how it is read: *"We keep `pin_id → pin object` cache in a memcache cluster, but we keep
`board_id → pin_ids` in a redis cluster."* Different data, different store — not forced into one engine. And the
id itself carries placement: the sharded fleet packs the shard into the high bits of a 64-bit id,
`ID = (shard ID << 46) | (type ID << 36) | (local ID<<0)` (shard id 16 bits, type id 10 bits, local id 36 bits),
so *the id tells you where the row lives — no lookup table*. A new Pin is assigned to the same shard as the board
it is inserted into.

**The list-based reliable queue.** A consumer **atomically moves** a job off the work list onto a **processing
list** as it claims it (`RPOPLPUSH source processing`, blocking `BRPOPLPUSH`), then **`LREM`** removes it from the
processing list once the job is acknowledged. If the worker crashes mid-job, the job is still on the processing
list — a recovery worker scans for items stuck too long and re-queues them. No job is lost to a crash between
receive and ack. `RPOPLPUSH`/`BRPOPLPUSH` were deprecated in Redis 6.2.0 in favour of **`LMOVE`/`BLMOVE`** (which
take an explicit `LEFT`/`RIGHT` direction); `LMOVE` is today's primitive, `RPOPLPUSH` the original.

## §3 · Scale, and the durability turn

The fleet behind PinLater grew through a wall. Pinterest started from *"eight EC2 servers running one MySQL
instance each"*; by September 2011 *"every piece of our infrastructure was over capacity."* They finished
launching the sharding approach *"in early 2012, and it's still the system we use today,"* carrying **50 billion
Pins** across **one billion boards**. PinLater's own sharding is a **free sharding scheme — a shard is chosen
when a job is enqueued** — so adding a shard is a configuration change, not a data migration, and load spreads
evenly. The shard id rides in the job descriptor itself, `[queue_name][shard_id][priority][local_id]`.

The case study's punch line is the durability turn. Pinterest later got *"5X more throughput on the MySQL
backend, which allows us to do over 2,000 enqueues per second with a single i2.2xl MySQL EC2 instance"* and so
chose to *"move all our workloads to MySQL and deprecate the use of the Redis backend"* — for MySQL's durability
and replication. A list-in-RAM queue is fast, but a job store that must not lose work eventually wants a durable
record. That is the same tension R7.01 (Redis as a primary database) and the persistence floor
(`/echo-persistence`) name.

## §4 · The applied half — the BCS bus

The Pinterest case is the lens; the bus the reader is building is EchoMQ, backed by Valkey. Each idea ties back to
one verified surface.

The bridge:

- **The pattern** — functional partitioning puts a queue's data on a known shard and lets the identity decide
  placement; the list-based reliable queue moves a claimed job somewhere safe so a crash never loses it.
- **Its EchoMQ application** — partitioning is the braced `emq:{q}:<type>` keyspace
  (`echo/apps/echo_mq/lib/echo_mq/keyspace.ex`): every key of one queue lands on one slot, computed client-side
  as `slot/1 = rem(crc16(hashtag(key), 0), 16384)` (CRC16-XMODEM over the `{…}` substring, mod 16384 — the
  cluster-spec algorithm), with the on-disk vector `slot("123456789") == 12739`. Crash-safety is a **server-clock
  lease plus an `attempts` counter**, not a processing list: the claim stamps `redis.call('TIME')` and the job
  HASH carries `state` / `attempts` / `payload` (`echo/apps/echo_mq/lib/echo_mq/jobs.ex`:
  `HSET KEYS[1] 'state' 'pending' 'attempts' '0' 'payload' …`). A crash lets the lease expire; the job is
  re-claimed and `attempts` increments.

Two honest framings hold the parallel straight:

- **The lane ring is not a processing list.** `EchoMQ.Lanes` does run
  `redis.call('LMOVE', KEYS[1], KEYS[1], 'LEFT', 'RIGHT')`, but that is a **single-key ring rotation** — it
  rotates the list of lane names round-robin so service spreads across lanes; it is not a `source → processing`
  move. The owned wire still knows the family — `EchoWire.Cmd.rpoplpush/2` ("Open an RPOPLPUSH builder") and
  `blmove` exist in `echo/apps/echo_wire/lib/echo_wire/cmd.ex`. PinLater and classic-Redis recover via a
  processing list and a recovery worker; EchoMQ reaches the same goal — no lost job, bounded retries — through
  the modern lease-based equivalent.
- **Placement is computed from identity, not looked up.** Pinterest *embeds* the shard in the id's high bits
  (`shard ID << 46`, a bit-extract). The branded id is *hashed* to a placement — the contract vector
  `EchoData.BrandedId.hash32(274557032793636864) == 234878118` (the id `USR0KHTOWnGLuC`) — and a queue's
  co-location comes from the `{q}` hashtag, not from the snowflake's minting-node field. The shared principle is
  the one to keep: placement is a property of the identity, computed rather than stored in a registry — Pinterest
  by bit-extraction, echo by hash plus the `{q}` hashtag.

The worked consumer is **codemojex**. `Codemojex.Guesses.submit/3` mints a branded `JOB`
(`EchoData.BrandedId.generate!("JOB")`) and runs `Lanes.enqueue(Bus.conn(), "cm", player, job, payload)` — a
guess is a job on the player's lane, *"so the bus rotates service across players and one keyboard masher cannot
starve the field."*

### Notes on Valkey

A queue's keys co-locate because the `{q}` hashtag forces the slot: a key is hashed only over the substring
between the first `{` and `}`, and the slot is `CRC16(hashtag) mod 16384`. Every `emq:{orders}:*` key lands on one
slot, so a multi-key Lua script over one queue is always a single-slot operation —
[valkey.io/topics/cluster-spec](https://valkey.io/topics/cluster-spec/).

## The three dives

The module takes the two ideas apart and then follows the scale arc:

- **R8.03.1 · Functional partitioning**
  (`/redis-patterns/production-operations/pinterest-task-queue/functional-partitioning`) — the polyglot split, the
  shard-in-the-id scheme, and the BCS echo: the `{q}` hashtag pins a queue's keys to one slot, the branded id is
  hashed to a placement. Placement is computed from identity, not looked up.
- **R8.03.2 · List-based reliable queues**
  (`/redis-patterns/production-operations/pinterest-task-queue/list-based-reliable-queues`) — `LMOVE`/`BLMOVE`
  onto a processing list, `LREM` on ack, the recovery worker; PinLater's explicit acks and automatic retry; and
  the BCS echo: a server-clock lease plus `attempts` reaches the same goal.
- **R8.03.3 · 1 → 1000+ scaling**
  (`/redis-patterns/production-operations/pinterest-task-queue/scaling-1-to-1000`) — eight EC2 servers to the
  early-2012 sharded fleet, PinLater's free sharding so adding a shard is config not migration, and the durability
  turn that moved Pinterest from Redis to MySQL.

Read them in order: partition first, then make the queue reliable, then scale it out.

## References

### Sources

- [Pinterest Engineering — Open-sourcing PinLater](https://medium.com/pinterest-engineering/open-sourcing-pinlater-an-asynchronous-job-execution-system-d8ec4e39859a)
  — the Thrift async-job service: enqueue/dequeue/ACK, the two backends, explicit acks with retry, and the 500+
  queues / 6M+ jobs per minute scale.
- [GitHub — pinterest/pinlater](https://github.com/pinterest/pinlater) — the README: the job descriptor format,
  the free sharding scheme, the MySQL-vs-Redis backend guidance, and the admin API.
- [Pinterest Engineering — Sharding Pinterest: How we scaled our MySQL fleet](https://medium.com/pinterest-engineering/sharding-pinterest-how-we-scaled-our-mysql-fleet-3f341e96ca6f)
  — the growth wall, the shard-in-the-id scheme, functional partitioning, and the move-cost principle.
- [Redis — LMOVE](https://redis.io/docs/latest/commands/lmove/) — the modern reliable-queue primitive (with
  `RPOPLPUSH` deprecated in 6.2.0).
- [Redis — RPOPLPUSH](https://redis.io/docs/latest/commands/rpoplpush/) — the original reliable-queue pattern and
  the processing-list recovery note.
- [Valkey — Cluster specification](https://valkey.io/topics/cluster-spec/) — CRC16 mod 16384 hash slots and the
  `{…}` hashtag that forces a queue's keys onto one slot.

### Related in this course

- [R8.03.1 · Functional partitioning](/redis-patterns/production-operations/pinterest-task-queue/functional-partitioning) — the id carries placement.
- [R8.03.2 · List-based reliable queues](/redis-patterns/production-operations/pinterest-task-queue/list-based-reliable-queues) — never lose a job to a crash.
- [R8.03.3 · 1 → 1000+ scaling](/redis-patterns/production-operations/pinterest-task-queue/scaling-1-to-1000) — add a shard trivially, then the durability turn.
- [R8 · Production & Operations](/redis-patterns/production-operations) — the chapter.
- [/echomq](/echomq) — the EchoMQ protocol behind the reliable-queue and partitioning tie-backs.
- [/echomq/queue](/echomq/queue) — the Queue pillar: jobs, lanes, leases.
