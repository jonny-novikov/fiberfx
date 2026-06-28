---
title: "Dive 13.1 — The database on the hot path"
id: ep-m14-d1
status: established
route: "/echo-persistence/platform/beats-classical-scheduling/the-database-on-the-hot-path"
kind: "module 14 · dive 13.1"
design: "html/redis-patterns sheet, re-themed amber/bronze."
pedagogy: "Taught through a unique interactive job-lifecycle round-trip SVG; single-machine job/s flagged indicative."
grounded-in: "docs/graft/graft.design.md (records-per-fsync; single-insert vs insert_all) · docs/graft/graft.engine-split.design.md (the hot path Oban puts every dequeue/heartbeat/ack through)"
renders-to: "platform/beats-classical-scheduling/the-database-on-the-hot-path.html"
---

# The database on the hot path { id="ep-m14-d1" }

> _A classical durable queue earns its reliability by routing the whole job lifecycle through the database. Enqueue is an insert; claiming a job is an update; the heartbeat that keeps a long job's lease alive is an update; the ack that finishes it is an update or delete. Every one is a round-trip to PostgreSQL, and every commit is an fsync._

**Interactive figure.** A worker and a PostgreSQL box, joined by four arrows — enqueue, dequeue, heartbeat, ack. Running the lifecycle lights each in turn and counts the round-trips; every durable step is an fsync. Toggle the fsync mode to see the one dial that sets throughput.

> Absolute job/s figures are indicative and single-machine; the teaching is the mechanism — the database on the hot path, and records per fsync.

## §1 Everything is a round-trip { id="hot" }

The defining property of the classical durable queue is not that it stores jobs — every queue does — but *where* it stores the queue's control state. In Oban, the jobs table holds the work and its lifecycle: a job is enqueued by an insert, claimed by an update under a lock, kept alive by periodic lease heartbeats, and completed by an update or delete. Each of those is a transaction against PostgreSQL, so the database sits on the hot path of every step, not just the durable write. That has two consequences worth stating plainly. The queue's **latency** is the database's latency — a slow commit slows claiming and acking, not only enqueue — and the queue's **availability** is the database's availability, because a worker that cannot reach Postgres cannot even mark progress on a job it already holds. And the durability, real as it is, is **single-node**: the committed jobs table survives a worker crash, but the loss of that one database is the loss of the queue, unless you run Postgres streaming replication and take on its failover complexity. None of this is a flaw in Oban; it is the direct cost of putting the control plane in the durable store. The platform's move is to ask whether the durable write has to be on that path at all.

## §2 The throughput dial: records per fsync { id="fsync" }

Strip the schema away and a durable queue's throughput reduces to one number: how many durable records ride a single fsync. The classical single-insert path commits once per job, so it rides **one record per fsync** — the strictest and the slowest end. The `insert_all` path writes a transaction's worth of jobs in one commit, riding a whole batch per fsync, and that single change closes most of the throughput gap — the same durability, far more jobs per second, paid for by holding a batch. This is the dial the hub's spectrum turns: Memory rides infinitely many records per fsync because it never syncs, Champ rides `K` because its checkpoint amortizes the fsync over `K` records, and Oban rides one or a transaction depending on the path. The insight that matters for the next dive is that batching is not unique to any one system — anything that amortizes the fsync over more records moves right on this axis. What batching alone never adds is *replication*: an `insert_all` is still single-node. So the open corner, the one the classical queue cannot reach by tuning its batch size, is strict durability that is *also* replicated and *also* off the hot path. That corner is the subject of the next dive.

## §3 References & sources { id="refs" }

Echo records:
- graft.design.md — the measured spectrum; single-insert vs insert_all; records-per-fsync as the one dial — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.design.md
- graft.engine-split.design.md — durability.ex: the bus stays on Valkey, the hot path Oban puts every dequeue/heartbeat/ack through — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.engine-split.design.md
- graft.roadmap.md — Oban strict but single-node unless streaming replication is bolted on — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.roadmap.md

External:
- Oban — the jobs table; the lifecycle — https://hexdocs.pm/oban/Oban.html
- PostgreSQL WAL reliability — fsync on commit — https://www.postgresql.org/docs/current/wal-reliability.html

---

_Pager: ← Module 14 — Why it beats classical scheduling · Dive 13.2 — The commit log is the outbox →_
