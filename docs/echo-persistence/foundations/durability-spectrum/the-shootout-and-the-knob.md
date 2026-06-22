---
title: "The shootout and the one knob"
id: ep-m1-d2
status: established
route: "/echo-persistence/foundations/durability-spectrum/the-shootout-and-the-knob"
kind: "module 1 · dive 1.2"
design: "html/redis-patterns sheet, re-themed amber/bronze."
pedagogy: "Taught through a unique interactive fsync-amortization SVG; the four-way table is a labelled reference, not the lesson."
renders-to: "foundations/durability-spectrum/the-shootout-and-the-knob.html"
---

# The shootout and the one knob { id="ep-m1-d2" }

> _A four-way measurement once spanned three orders of magnitude, and people remember the digits. The digits are a distraction. The whole spread comes from one lever: how many durable records ride each fsync. Turn it and watch throughput follow — the four engines are just stops on this dial._

**Interactive figure.** An fsync-amortization model: N record squares regroup as you raise records-per-fsync (a slider). Each batch shares one fsync stamp, so raising the knob drops the number of flushes and grows a throughput bar — fast at first (the flush is the dominant cost, divided across more records), then flattening as per-record work dominates. The readout reports the factor over commit-per-record and the percentage of the no-flush ceiling. This is the module's core mechanism; you *discover* the curve by moving the slider rather than reading it off a table.

## §1 The one knob { id="knob" }

The flattening is the whole story of the spectrum. Early on, throughput climbs almost linearly with records-per-fsync, because the flush is the dominant cost and you are dividing it across more records. Past a point, per-record work (serialize, append) dominates and more batching buys little. Every engine lives somewhere on this curve; the only question is what sets its records-per-fsync.

## §2 The engines as stops on the dial { id="engines" }

Read the four-way result as positions, not numbers. Memory has no flush, so it sits at the far ceiling. Oban's single insert is one record per flush — the strict, slow end; its `insert_all` puts a transaction's worth of records behind one flush and jumps up the curve. BullMQ's bulk add does the same on Redis. Champ never makes the caller hold a batch: its checkpoint-every-K keeps records-per-fsync high *continuously*, so its single-record path already sits where the others only reach with a bulk API.

| engine | store | durability | enqueue (single) | enqueue (bulk) |
|---|---|---|---|---|
| Memory | in-memory map | none | 336,961 | n/a — no fsync to amortize |
| Champ K=1,000 | local fsync snapshot | bounded ≤ 1,000 rec | 33,989 | n/a — K amortizes continuously |
| Champ K=10,000 | local fsync snapshot | bounded ≤ 10,000 rec | 103,970 | n/a — K amortizes continuously |
| BullMQ | Redis AOF everysec | bounded 1s | 6,388 | 16,180 |
| Oban | Postgres sync commit | strict per-commit | 718 | 13,235 |
| **Champ + Graft** | accept tier + commit → Tigris | **strict, replicated** | **pending eg.6 · per-workload** | **pending eg.6** |

**Reading the table.** Figures are indicative single-core measurements against MinIO — positions on the dial above, not a portable benchmark. "Bulk" is durable-*enqueue* via a bulk write API (`insert_all`/`addBulk`), amortizing the fsync on the write side; `n/a` means the row needs no such API (Memory has no fsync; Champ already amortizes via K). EchoMQ's shipped batches (emq.5 `claim_batch`/`BatchConsumer`) are *claim/consume* batches — a delivery axis, durability-neutral — not this column. Champ + Graft is the two-tier design; its number is measured per-workload at `eg.6` — a rung deferred behind a fly.io deploy floor — so it stays pending, not asserted here.

## §3 References & sources { id="refs" }

Echo records:
- graft.design.md — the shootout and the fsync reading — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.design.md
- emq.roadmap.md — emq.5 claim/consume batches, the other axis — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/echo_mq/emq.roadmap.md

External:
- oban-bg/oban — single insert vs insert_all — https://github.com/oban-bg/oban
- taskforcesh/bullmq — add vs addBulk on Redis — https://github.com/taskforcesh/bullmq
- Designing Data-Intensive Applications, Kleppmann 2017 — group commit, the amortization idea — https://dataintensive.net

---

_Pager: ← Inherited Valkey durability · Dive 1.3 — Two axes, one decision →_
