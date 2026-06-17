# Overview — EchoMQ, In Depth

**Route:** `/echomq/overview` · the orientation chapter (the chapter landing).

EchoMQ is **one Valkey-native job system you own, canonical in Elixir**. Its keys and its Lua scripts are the protocol;
draw the line there and three surfaces fall out of one wire — the **Queue** (distribute work), the **Bus** (broadcast
signals + a retained, replayable event log), and the **Cache** (serve reads). This chapter sets the frame: the three
pillars, the protocol below the line that makes them polyglot and coherent, the door from
[Redis Patterns Applied](/redis-patterns), and what EchoMQ means for the [Branded Component System](/bcs) it is the bus
of.

## The protocol below the line

The layer stack: **L0** Valkey · **L1** the data layer (which key holds which structure, the field names) · **L2** the
atomic Lua scripts · **L3** the script executor (load-once, run-by-SHA) · **L4** the language API
(`EchoMQ.Jobs.enqueue`, `EchoMQ.Consumer`). The shared line falls **between L2 and L3**: below it the protocol is fixed
and shared; above it, every runtime writes its own code. That single placement is what lets one wire serve three
pillars and lets any runtime speak it.

## The three orienting dives

A **what → why → where** arc before the depth chapters:

- **[The three pillars](/echomq/overview/the-three-pillars)** (*what*) — the Queue, the Bus, and the Cache: three
  surfaces over one wire, and the job each one does.
- **[The protocol below the line](/echomq/overview/the-protocol-below-the-line)** (*why*) — the keys and the Lua are
  shared and fixed; the language is yours. The line that makes the system polyglot and coherent, on a real key.
- **[The door & the BCS family](/echomq/overview/the-door)** (*where*) — the bidirectional Redis-Patterns door, and
  what owning the queue, the bus, and the cache means for the systems built on them.

## Up next — the depth chapters

Read **[The Protocol](/echomq/protocol)** next — the substrate the three pillars share. Then take the pillar you need:
**The Queue**, **The Bus**, **The Cache**. The **Proof** chapter shows the system holds. Each closes with a workshop.
The Protocol is ready to read; the three pillars and the Proof chapter are on the build front, each added as its pages
land.

## References

### Sources
- [Valkey — Documentation](https://valkey.io/docs/) — the BSD-licensed, foundation-governed store EchoMQ is backed by; the substrate of record.
- [Redis — EVALSHA](https://redis.io/commands/evalsha/) — the load-once, run-by-SHA dispatch the L3 executor uses.
- [DragonflyDB — Server flags](https://www.dragonflydb.io/docs/managing-dragonfly/flags) — the thread-per-shard engine the declared-key keyspace is built for.
- [llmstxt.org — The llms.txt convention](https://llmstxt.org/) — the machine-readable map format the course follows.

### Related in this course
- [Course home](/echomq) — the full six-chapter map.
- [The three pillars](/echomq/overview/the-three-pillars) — the first dive, what EchoMQ is.
- [redis-patterns · Patterns become protocol](/redis-patterns/overview/patterns-become-protocol) — the near side of the door.
- [The Branded Component System](/bcs) — the architecture EchoMQ is the bus and near-cache of.
