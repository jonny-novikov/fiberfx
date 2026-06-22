---
title: "The durability spectrum"
id: echo-persistence-dive-spectrum
status: established
route: "/echo-persistence/overview/the-durability-spectrum"
kind: "overview dive 1 of 3"
design: "html/redis-patterns sheet, re-themed amber/bronze persistence accent."
renders-to: "overview/the-durability-spectrum.html"
---

# The durability spectrum { id="echo-persistence-dive-spectrum" }

> _Durability is not a checkbox; it is a position on a spectrum, set deliberately per queue. Read from one measurement, the spectrum has a single mechanism behind it — and one more axis the throughput number hides: whether the durable state ever leaves the box._

## §1 The measurement { id="measure" }

Four engines recorded the same 20,000 jobs on one shared vCPU, with Postgres durable (`synchronous_commit=on`) and Redis durable (AOF `everysec`). The result spans three orders of magnitude, and the spread has exactly one explanation: **throughput tracks how many durable records ride each fsync**. The fsync is fixed cost; everything else is how many jobs you amortize it across.

| engine | store | durability | single | batch |
|---|---|---|---|---|
| Memory | in-memory map | none | 336,961 | — |
| Champ K=10,000 | local fsync snapshot | bounded ≤ 10,000 rec | 103,970 | — |
| Champ K=1,000 | local fsync snapshot | bounded ≤ 1,000 rec | 33,989 | — |
| BullMQ | Redis AOF everysec | bounded 1s | 6,388 | 16,180 |
| Oban | Postgres sync commit | strict per-commit | 718 | 13,235 |

Memory rides infinitely many records per fsync; Champ rides K; Oban-batch rides a transaction; Oban-single rides one. A factor of 469 separates strict per-commit (Oban, 718 jobs/s) from no durability (Memory, 336,961 jobs/s). Within Oban, `insert_all` writes 1,000 jobs per transaction and reaches 13,235 — a factor of 18, purely from spreading one fsync across the batch. Champ reaches that class continuously, because its checkpoint amortizes the fsync over K records without the caller ever holding a batch.

The lesson is mechanical, not magical: to make a strong guarantee affordable, raise the durable-records-per-fsync — with K (Champ), a transaction (Oban-batch), or a group-commit. That single lever is what the whole two-tier design pulls.

## §2 Two axes, one decision { id="axes" }

The shootout measures one axis: the loss window, from "none" to "strict per-commit." A second axis is independent of it — **does the durable state leave the machine?** Oban is strict but single-node unless Postgres streaming replication is bolted on; Champ's snapshot is bounded-loss and ships asynchronously. A tier can be strict-but-single-node, or bounded-but-replicated; the two choices do not move together.

Placing a queue therefore means choosing both — a loss window and a replication posture:

- telemetry → none acceptable / not needed → **Memory**, 336,961 jobs/s
- ordinary work → a bounded few thousand records / nice to have → **Champ-K**, tens of thousands/s
- payments → none / required, off-box → **Champ + Graft**, per-commit and replicated to Tigris

The rest of Echo Persistence is about reaching that far corner — per-commit and replicated — without paying the per-commit floor, which Dive 2 builds.

## §3 References & sources { id="refs" }

- graft.design.md — the shootout and the spectrum — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.design.md
- Valkey persistence (AOF) — the 1s loss window — https://valkey.io/topics/persistence/
- oban-bg/oban — strict per-commit; insert_all batch — https://github.com/oban-bg/oban
- taskforcesh/bullmq — the Redis-backed tier — https://github.com/taskforcesh/bullmq
- Designing Data-Intensive Applications, Kleppmann 2017 — group commit (Ch. 3, 5) — https://dataintensive.net

---

_Pager: ← Course hub (overview) · Dive 2 — The two-tier shape →_
