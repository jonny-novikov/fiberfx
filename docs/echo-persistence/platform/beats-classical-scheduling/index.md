---
title: "Module 13 — Why it beats classical scheduling"
id: ep-m13-hub
status: established
route: "/echo-persistence/platform/beats-classical-scheduling"
kind: "module 13 hub — Chapter IV, 3 dives"
design: "html/redis-patterns sheet, re-themed amber/bronze."
pedagogy: "Taught through a unique interactive durability-spectrum SVG (records per fsync); single-machine job/s flagged indicative, not the teaching point."
grounded-in: "docs/graft/graft.design.md (the measured spectrum, records-per-fsync) · docs/graft/graft.engine-split.design.md (Durability.Graft, @obx_base, the Committer drain) · docs/echo_mq/kb/emq4-durability (ADR-A)"
renders-to: "platform/beats-classical-scheduling/index.html"
---

# Why it beats classical scheduling { id="ep-m13-hub" }

> _The classical durable queue — Oban on PostgreSQL, cron on a table — is strict and well-understood, and it pays for that in two coins: it puts the database on the hot path of every dequeue, heartbeat, and ack, and it is single-node until you bolt on streaming replication. This module shows the one mechanism that explains the whole durability spectrum, and how EchoMQ's commit-log-as-outbox reaches batch-class throughput while being the only tier that is both strict and replicated._

**Interactive figure (hub).** A horizontal axis — durable records per fsync — with markers for Oban-single (one), Oban-batch (a transaction), Champ (K), Memory (∞, no durability), and the commit-log-as-outbox (the engine's batch, strict *and* replicated, in the dashed target quadrant). Tap a queue to place it and read its trade-off.

> Absolute job/s figures are indicative and single-machine; the teaching is the mechanism — records amortized per fsync — not any one number.

## §1 What classical scheduling costs { id="cost" }

Oban is the reference point because it is genuinely good: strict per-commit durability, mature tooling, a queue you can trust. Its bill comes in two parts. First, the database is on the **hot path** — every enqueue, every dequeue, every heartbeat, every ack is a PostgreSQL round-trip, so the store's latency and availability gate the queue's. Second, that durability is **single-node**: a committed job survives a crash of the worker, but not the loss of the database, unless you bolt on Postgres streaming replication and accept its operational weight. Underneath both sits the one mechanism this whole module turns on: durable throughput is set by *how many records ride a single fsync*. Oban's single-insert path commits once per job — one record per fsync — and its `insert_all` path writes a transaction's worth at once, closing most of the gap by spreading one fsync across the batch. Memory rides infinitely many records per fsync because it never fsyncs at all; Champ rides `K` because its checkpoint amortizes the fsync over `K` records. The spectrum is not four philosophies; it is one dial set to four positions. The platform's job is to choose where each queue sits — and to make the strict-*and*-replicated end affordable, which is exactly the corner Oban cannot reach without leaving the single-node world.

## §2 The answer: the commit-log-as-outbox { id="answer" }

The platform's answer keeps the bus on Valkey — fast, reliable, volatile, off the durable path — and makes the durable record the *engine's own commit*. This is the **commit-log-as-outbox**: built today as `EchoStore.Durability.Graft`, where an enqueue intent is simply a page commit in a reserved high LSN range (`@obx_base = 1 <<< 48`), and recovery replays that range above a watermark. Because the intent *is* a commit, it is atomic and durable in one act — there is no second system to disagree with, so the dual-write problem of the last module never arises. And because the engine is the Chapter III Graft engine, that single commit inherits everything that engine already proves: the OCC base-LSN check, the conditional-write fence, page-rollup replication to Tigris, and log-head recovery. So the enqueue is strict *and* replicated — the corner Oban misses — while riding the engine's batch for throughput, and the bus stays fast because none of this is on the enqueue hot path. The same idea is where EchoMQ 4+ is headed in the large (ADR-A: the commit-log-as-outbox as the journal, off SQL entirely). The balanced reading is the one the platform settled on: mitigate the single-instance database by making durability a replicated engine commit, and keep a reliable Valkey bus for speed. That is why it beats classical scheduling — not by being less strict, but by being strict in a place that also replicates and never touches the hot path.

## §3 The three dives { id="dives" }

- **Dive 13.1 — The database on the hot path** — the classical model traced: every dequeue, heartbeat, and ack a round-trip to PostgreSQL, strict but single-node, throughput pinned to one record per fsync on the single-insert path. → `/echo-persistence/platform/beats-classical-scheduling/the-database-on-the-hot-path`
- **Dive 13.2 — The commit log is the outbox** — the robust solution: an enqueue intent is a page commit at `@obx_base = 1 <<< 48`, atomic and durable in one act, drained by the Committer, replayed above a watermark — the engine becomes the bus's outbox. → `/echo-persistence/platform/beats-classical-scheduling/the-commit-log-is-the-outbox`
- **Dive 13.3 — The balanced decision** — the verdict on two axes, durability and hot-path cost; why the commit-log-as-outbox lands alone in the strict-and-replicated-and-off-the-hot-path quadrant. → `/echo-persistence/platform/beats-classical-scheduling/the-balanced-decision`

## §4 Up next { id="next" }

- **Module 14 · The door to BCS** — where durable state stops being plumbing and becomes substrate: Tables and Properties over the engines, the Branded Component System, and the codemojex apps that ride it. → `/echo-persistence/platform/the-door-to-bcs`
- **Revisit · Module 12 · EchoBus + Echo Persistence** — the composition this module sharpens: the three seams, the commit LSN as the cursor, the outbox beside the bus. → `/echo-persistence/platform/bus-and-persistence`
- **The course map** — jump back to the full map and revisit any module or dive. → `/echo-persistence#map`

## §5 References & sources { id="refs" }

Echo records:
- graft.design.md — the measured durability spectrum (Memory / Champ / Oban / BullMQ); records-per-fsync as the single mechanism — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.design.md
- graft.engine-split.design.md — EchoStore.Durability.Graft, the outbox IS the commit log; @obx_base; the Committer drain — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.engine-split.design.md
- echo_mq-v4-durability-adr.md — ADR-A: commit-log-as-outbox, atomic and durable in one act, off SQL — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/echo_mq/kb/emq4-durability/echo_mq-v4-durability-adr.md
- graft.roadmap.md — the missing quadrant; Oban single-node unless replication is bolted on; the shootout — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.roadmap.md

External:
- Oban — the classical Postgres-backed job queue — https://hexdocs.pm/oban/Oban.html
- Transaction log — the commit log the outbox reuses — https://en.wikipedia.org/wiki/Transaction_log

---

_Pager: ← Module 12 — EchoBus + Echo Persistence · Dive 13.1 — The database on the hot path →_
