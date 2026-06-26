# From one box to a fleet: 1 → 1000+ scaling

> R8.03.3 · Pinterest: task queues & partitioning — dive 3 · route `/redis-patterns/production-operations/pinterest-task-queue/scaling-1-to-1000`

Pinterest scaled from eight servers to a fleet carrying fifty billion Pins, and the move that made it
possible was not a bigger machine — it was making "add a shard" a configuration change rather than a data
migration. PinLater put the shard id inside every job's descriptor, so a new shard is chosen at enqueue and
no row ever has to move. The BCS bus answers the same scaling question the same way: a queue's placement is a
pure function of its name, decided up front, so the cluster can grow without re-homing a single key.

Grounding: the Pinterest engineering history — *Sharding Pinterest: How we scaled our MySQL fleet* and
*Open-sourcing PinLater* — for the scale figures and the free-sharding scheme; the real
`echo/apps/echo_mq/lib/echo_mq/keyspace.ex` (the `{q}` hashtag and the CRC16 slot) and
`echo/apps/echo_mq/lib/echo_mq/jobs.ex` (the job HASH that is the record of truth) for the applied half.

This dive owns the **scaling-out** story: how a system grows without moving data, and where in-RAM speed
hands off to durable storage. Functional partitioning (the polyglot split, the shard-in-the-id) is dive 1;
the list-based reliable queue and the lease that replaces it is dive 2. This page references them, it does
not repeat them.

## §1 · Eight servers, then over capacity

Pinterest's growth through 2011 was explosive. The fleet started small — *"eight EC2 servers running one
MySQL instance each"* — and the engineering account is blunt about where that ended: by **September 2011**
*"every piece of our infrastructure was over capacity."*

The answer they shipped was a sharded fleet. They finished launching the sharding approach *"in early 2012,
and it's still the system we use today,"* and it carried **50 billion Pins** across **one billion boards**.
The title of this dive is that arc — one box to a fleet — and the lesson is not the size of the fleet but
what made it reachable: a scheme where adding capacity does not mean moving the data already stored.

Pinterest stated the principle that governed every capacity move: *"We hated moving data around, especially
item by item… If we had to move data, it was better to move an entire virtual node to a different physical
node."* Capacity is added by upgrading a machine, opening a new shard range, or migrating a whole virtual
node — never by re-distributing rows one at a time. A migration that touches every item does not scale; a
migration that relocates a whole bucket does.

## §2 · PinLater's free sharding — the shard is in the descriptor

PinLater, Pinterest's asynchronous job system, made "add a shard" trivial by putting the shard id where it
could never need a lookup: **inside the job's own descriptor.** The descriptor format, verbatim from the
project's documentation, is

```text
[queue_name][shard_id][priority][local_id]
```

Shards live *within* a queue. PinLater uses a **free sharding scheme — a shard is chosen when a job is
enqueued** — and the chosen shard is then carried in the descriptor for the life of the job. Two consequences
follow directly:

- **Adding a shard is configuration, not migration.** Because the shard is selected at enqueue time and
  recorded in the descriptor, a new shard begins receiving jobs as soon as it is listed in the configuration.
  No existing job moves; load simply starts spreading across the wider set.
- **The descriptor locates the job.** A worker reading a descriptor knows the queue, the shard, the priority,
  and the local id without consulting a registry. The id tells you where the job lives — the same property
  the shard-in-the-id scheme gives Pinterest's Pins in dive 1.

This is the same scaling posture at the queue layer that the sharded fleet gives at the database layer: the
placement decision is made once, written into the identity, and never revisited. PinLater ran this across
real scale — *"more than 500 job queues processing north of six million jobs per minute"* on *"more than 10
different clusters all on Amazon EC2."*

## §3 · The BCS echo — placement is a function of the name

The echo bus reaches the same "add a shard without moving data" property by a different mechanism, and the
mechanism is the one the cluster specification defines. Every key of one queue is built with a hashtag, and
the slot it lands on is computed client-side from that hashtag:

```text
emq:{orders}:pending      # the queue name "orders" sits inside the braces
```

`EchoMQ.Keyspace.slot/1` computes a key's cluster slot as `rem(crc16(hashtag(key), 0), 16384)` — CRC16-XMODEM
over the substring inside the first `{...}`, modulo **16384**, exactly the cluster specification's algorithm.
The module's own words: *"every key of one queue lands on one slot."* A known vector pins the behaviour:
`slot("123456789") == 12739`.

The scaling payoff is the same as PinLater's free sharding. A queue's slot is a **pure function of the queue
name** — it is computed, never looked up, and it never changes. When the cluster grows from a few nodes to
many, slots are reassigned to nodes, but a queue's keys stay together on whatever node now owns their slot.
No key is re-homed by name; the slot was decided up front, the moment the queue was named. Pinterest decides
placement at enqueue and writes it into the descriptor; the bus decides placement from the name and computes
it on every call. Both make growth a matter of widening the set, not relocating the contents.

**Bridge — the pattern → its EchoMQ application.** The pattern: scale out by making placement a property
fixed up front, so adding capacity widens the set without moving what is already stored — Pinterest chooses a
shard at enqueue and records it in the `[queue_name][shard_id][priority][local_id]` descriptor. Its
application: `EchoMQ.Keyspace.slot/1` derives a queue's slot from the `{q}` hashtag via CRC16 mod 16384, so a
queue's keys are co-located by name and the cluster can grow without re-homing them.

## §4 · The durability turn — fast in RAM, durable on the dial

The scale figures hide a second lesson, and PinLater states it as a turn. PinLater shipped with **two storage
backends, MySQL and Redis**, and the guidance was throughput-driven: services should *"default to use the
MySQL backend as long as the QPS is in the lower to mid range (no more than 1000 QPS per shard). If the QPS is
expected to be higher than this, then the Redis implementation should be used."* Redis was the
high-throughput backend.

Then the trade reversed. Pinterest reported *"5X more throughput on the MySQL backend, which allows us to do
over 2,000 enqueues per second with a single i2.2xl MySQL EC2 instance"* and so chose to *"move all our
workloads to MySQL and deprecate the use of the Redis backend"* — for MySQL's durability and replication. A
list-in-RAM queue is fast, but a job store that must not lose work eventually wants a durable record of every
job. This is the tension the R7.01 pattern (Redis as a primary database) names directly, and it is the reason
the persistence floor exists.

The BCS stack answers the same tension not by replacing the engine but with a **durability dial.** The job is
a HASH held in Valkey, and that HASH is the record of truth: the `@enqueue` script writes
`HSET KEYS[1] 'state' 'pending' 'attempts' '0' 'payload' …`, and `state`, `attempts`, and `payload` carry the
job's whole life. That record lives in RAM for speed, the way PinLater's Redis backend did. Where it is made
durable is the dial — ETS, then Valkey, then a committed engine behind it — and that dial is the subject of
`/echo-persistence`. PinLater moved a layer (Redis → MySQL) to gain durability; the BCS stack keeps one
record of truth and turns the durability up underneath it.

**Take.** Scaling out is making placement a decision you make once. Pinterest writes the shard into the
descriptor; the bus computes the slot from the queue name. And scaling up against the durability ceiling is a
dial, not a rewrite — the job HASH is the record of truth in RAM, and `/echo-persistence` is where it is made
durable.

## §Recap

One box to a fleet is one idea repeated at two layers. Pinterest went from eight servers to a sharded fleet
of fifty billion Pins by deciding placement up front — the shard in the Pin's id, the shard in PinLater's
job descriptor — so a new shard is configuration, never a migration. The echo bus does the same with the
`{q}` hashtag: a queue's slot is a function of its name, computed client-side, fixed for the life of the
queue, so the cluster grows without re-homing a key. And PinLater's Redis → MySQL durability turn is the same
ceiling the persistence floor answers with a dial. The next page is the chapter landing — R8 continues to the
Twitter/X case study (R8.04, specified) and the production capstone.

## References

### Sources

- [Pinterest Engineering — Sharding Pinterest: How we scaled our MySQL fleet](https://medium.com/pinterest-engineering/sharding-pinterest-how-we-scaled-our-mysql-fleet-3f341e96ca6f) — eight servers, over capacity by Sept 2011, the early-2012 sharded fleet of 50B Pins / 1B boards, and the move-cost principle.
- [Pinterest Engineering — Open-sourcing PinLater: An asynchronous job execution system](https://medium.com/pinterest-engineering/open-sourcing-pinlater-an-asynchronous-job-execution-system-d8ec4e39859a) — the free sharding scheme, the 500+ queues / 6M+ jobs-per-minute scale, and the Redis → MySQL durability turn.
- [GitHub — pinterest/pinlater](https://github.com/pinterest/pinlater) — the Thrift async-job service; the `[queue_name][shard_id][priority][local_id]` descriptor and the per-shard QPS backend guidance.
- [Valkey — Cluster specification](https://valkey.io/topics/cluster-spec/) — CRC16 modulo 16384 hash slots and the `{…}` hashtag the bus uses to co-locate a queue's keys.

### Related in this course

- [R8.03 · Pinterest: task queues & partitioning](/redis-patterns/production-operations/pinterest-task-queue) — the module hub.
- [R8.03.2 · List-based reliable queues](/redis-patterns/production-operations/pinterest-task-queue/list-based-reliable-queues) — the previous dive: the processing list, the lease, no lost job.
- [R8 · Production & Operations](/redis-patterns/production-operations) — the chapter.
- [/echo-persistence](/echo-persistence) — the durability dial the Redis → MySQL turn points to.
- [/echomq/queue](/echomq/queue) — the Queue pillar: jobs, lanes, leases, and the keyspace behind the slot.
