---
title: "Dive 13.3 — The balanced decision"
id: ep-m13-d3
status: established
route: "/echo-persistence/platform/beats-classical-scheduling/the-balanced-decision"
kind: "module 13 · dive 13.3"
design: "html/redis-patterns sheet, re-themed amber/bronze."
pedagogy: "Taught through a unique interactive 2×2 verdict SVG (durability × hot-path cost); qualitative axes, no machine numbers."
grounded-in: "docs/graft/graft.roadmap.md (the missing quadrant; Champ bounded-loss; Oban single-node) · docs/graft/graft.design.md (claim-batch alignment) · jonnify.todo.md (the balanced decision)"
renders-to: "platform/beats-classical-scheduling/the-balanced-decision.html"
---

# The balanced decision { id="ep-m13-d3" }

> _Put the options on two axes and the verdict draws itself. One axis is durability — from none, through bounded-loss, to strict-and-replicated. The other is hot-path cost — whether the durable store sits on the critical path of every operation, or stands aside while a fast bus carries the work. Each classical choice lands in a corner with something missing. Only one option reaches the corner that is strict, replicated, and off the hot path — and it is the commit-log-as-outbox._

**Interactive figure.** A 2×2 plot: durability (bounded/none → strict + replicated) against hot-path cost (DB on the hot path → bus on Valkey). Oban sits top-left, Champ mid-right, Memory bottom-right; the commit-log-as-outbox lands alone in the top-right target quadrant. Tap each point to see why.

## §1 The missing quadrant { id="quad" }

The roadmap names the corner directly: Champ is bounded-loss, Oban is strict but single-node unless Postgres replication is bolted on, and Graft already solves the quadrant the other two miss — transactional commits with an LSN log, conditional-write commit, and instant read replicas over object storage. Read the plot and each option fails the target corner for a different reason. **Memory** sits at the bottom: maximal throughput, off the hot path, but no durability at all — the wrong axis entirely for a durable queue. **Champ** sits mid-right: fast and off the hot path, but its replication is async and snapshot-grained, so it is bounded-loss, not strict — the right accept tier, not the durable floor. **Oban** sits top-left: genuinely strict, but with the database on the hot path of every dequeue, heartbeat, and ack, and single-node until you take on streaming replication. Each is missing exactly one property the platform wants together. The **commit-log-as-outbox** is the only point in the top-right: it is strict and replicated because the intent is a fenced, Tigris-replicated Graft commit (13.2), and it is off the hot path because the bus stays on Valkey and the durable write rides the engine's batch rather than gating the enqueue. It does not split the difference between the others; it occupies the corner none of them can.

## §2 The decision, stated plainly { id="balance" }

The engineering question this module answers was always narrow: what does a Graft-backed journal in EchoMQ buy over Oban fully backed by PostgreSQL? The balanced reading is the one the platform settled on — **mitigate the single-instance database, but keep a reliable Valkey bus**. The single-instance database is mitigated because durability is no longer a row in one Postgres; it is a replicated engine commit, recoverable by log-head replay, with the conditional-write fence guarding correctness. The fast bus is kept because none of that durability is on the enqueue hot path — Valkey carries the work, the commit-log-as-outbox carries the guarantee, and they meet only at the drain. Throughput is not sacrificed for this: the durable record rides the engine's batch, and aligning that commit batch to the consumer's claim batch — the seam from Module 12.1 — makes enqueue-through-record a single durable, replicated unit. So "it beats classical scheduling" is not a claim that Oban is bad; it is a claim that the platform reaches a corner Oban cannot, by being strict in a place that also replicates and never touches the hot path. That same engine-as-substrate idea is the threshold of the final module: once durable, replicated state is this cheap and this composable, it stops being plumbing for a queue and starts being the foundation for Tables, Properties, and the Branded Component System — the door this course opens last.

## §3 References & sources { id="refs" }

Echo records:
- graft.roadmap.md — the missing quadrant; Champ bounded-loss; Oban single-node; Graft solves transactional + replicated — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.roadmap.md
- graft.design.md — aligning the commit batch to the claim batch, one durable, replicated unit — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.design.md
- graft.engine-split.design.md — the outbox beside a volatile bus; Durability.Graft on the native engine — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.engine-split.design.md

External:
- CAP theorem — why single-node strictness and replication are different properties — https://en.wikipedia.org/wiki/CAP_theorem
- Oban — the strict, single-node reference point — https://hexdocs.pm/oban/Oban.html

---

_Pager: ← Dive 13.2 — The commit log is the outbox · Module 14 — The door to BCS →_
