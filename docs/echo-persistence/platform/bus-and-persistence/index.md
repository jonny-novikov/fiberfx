---
title: "Module 12 — EchoBus + Echo Persistence"
id: ep-m12-hub
status: established
route: "/echo-persistence/platform/bus-and-persistence"
kind: "module 12 hub — Chapter IV, 3 dives"
design: "html/redis-patterns sheet, re-themed amber/bronze."
pedagogy: "Taught through a unique interactive two-halves / three-seams composition SVG; no machine numbers."
grounded-in: "docs/graft/graft.design.md (two-tier join, LSN published over EchoMQ) · docs/graft/graft.engine-split.design.md (EchoStore.Durability outbox) · docs/echo_mq/emq.streams.md (emq3.5 fold)"
renders-to: "platform/bus-and-persistence/index.html"
---

# EchoBus + Echo Persistence { id="ep-m12-hub" }

> _Eleven modules built two things that look separate: a message bus (EchoMQ 3.0) and a durable floor (the engines and store of EP1–10). This module is the claim that they are one system. They meet at exactly three seams — a shared cursor, an outbox, and a fold — and through those seams a write becomes a loop across four tiers: accepted, committed, published, and folded back._

**Interactive figure (hub).** A left panel (the bus: Champ accept tier, emq3.0 stream tier) and a right panel (the durable floor: Graft engine, CubDB→Tigris store), coupled in both directions. Tapping each of three connectors highlights it: ① the commit LSN published from the engine is the cursor the bus binds to; ② the outbox stands beside the bus, journaling intents while the bus stays on Valkey; ③ the archive fold commits stream slices back into the engine.

## §1 Why it is one system, not two { id="one" }

It is tempting to read the course as two stacks bolted together: a queue on one side, a database on the other. The platform's design refuses that split, and the reason is the **commit LSN**. When the accept tier (Champ, in-memory with an fsync every K records) folds a batch into a Graft transaction, that batch becomes **one LSN** replicated to Tigris — and that same LSN is published over EchoMQ. A number that means "this much is durable" on the store side is the identical number that means "subscribe from here" on the bus side. So the two halves do not exchange data through an adapter that could drift; they share a cursor. That single fact is what makes a replica's position, a consumer's offset, and a commit's durability the same coordinate, and it is why the rest of the module can talk about a loop rather than a pipeline: the engine's commit drives the bus, and — through the archive fold — the bus drives the engine's commit. Everything else in this module is a consequence of choosing one cursor for both worlds.

## §2 The three seams { id="seams" }

The coupling is not diffuse; it is exactly three seams, and each is a dive. **The cursor** (①) is the accept–commit join: the caller picks the guarantee per call — `:async` returns once the batch is fsync'd locally, `:sync` only after the Tigris-replicated commit acknowledges — and the published LSN binds every replica to the same point. **The outbox** (②) is the deliberate non-coupling of the hot path: the bus stays on Valkey because it must be fast, and durability stands beside it as a low-volume transactional-enqueue outbox (`EchoStore.Durability`), so a durable write never enters the enqueue path — its adapters are `SQLite` and `Memory`, with the Graft commit-log as a bring-your-own option. **The fold** (③) is the return leg: the Stream Tier's retention does not delete history, it archives it — a dedicated fold consumer commits trimmed stream slices into the engine with `EchoStore.Graft.commit/3`, fold-before-trim, so the bus's old tail becomes the store's durable segments. Read the seams in order and the loop is complete: a write is accepted, committed (①), recorded beside the bus (②), carried as events, and folded back into the store (③).

## §3 The three dives { id="dives" }

- **Dive 12.1 — The commit LSN is the cursor** — the accept tier and the commit tier join at the batch; one batch is one LSN; `:async` vs `:sync` per call; and the published LSN binds every replica and consumer to the same point. → `/echo-persistence/platform/bus-and-persistence/the-commit-lsn-is-the-cursor`
- **Dive 12.2 — The outbox beside the bus** — the dual-write trap, and why EchoMQ sidesteps it: the bus stays on Valkey while a low-volume outbox journals intents beside the hot path. The Adapter contract; `SQLite`/`Memory`. → `/echo-persistence/platform/bus-and-persistence/the-outbox-beside-the-bus`
- **Dive 12.3 — The loop closes** — the archive fold commits stream slices into the engine (`EchoStore.Graft.commit/3`, fold-before-trim) — the four tiers become a cycle joined by the cursor and the feed. → `/echo-persistence/platform/bus-and-persistence/the-loop-closes`

## §4 Up next { id="next" }

- **Module 13 · Why it beats classical scheduling** — beats over polling, claim batches, and at-least-once with idempotent handlers; why the EchoMQ model out-performs an Oban/cron shape on the platform's workloads. → `/echo-persistence/platform/beats-classical-scheduling`
- **Module 14 · The door to BCS** — where durable state stops being plumbing and becomes substrate: Tables and Properties over the engines, the Branded Component System, and the codemojex apps that ride it.
- **The course map** — jump back to the full map (Foundations, the local store, the engines, the platform) and revisit any module or dive. → `/echo-persistence#map`

## §5 References & sources { id="refs" }

Echo records:
- graft.design.md — the two-tier join; the commit LSN published over EchoMQ binds replicas; :async / :sync — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.design.md
- graft.engine-split.design.md — EchoStore.Durability, the outbox beside the bus; SQLite / Memory adapters — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.engine-split.design.md
- emq.streams.md — emq3.5, the archive fold into EchoStore.Graft — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/echo_mq/emq.streams.md
- store.design.md — EchoStore module architecture; dev↔prod durability knob — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/echo_mq/store/design/store.design.md

External:
- Transactional outbox — the dual-write problem the seam avoids — https://microservices.io/patterns/data/transactional-outbox.html
- Change data capture — the commit log as an event source — https://en.wikipedia.org/wiki/Change_data_capture

---

_Pager: ← Module 11 — EchoMQ Bus · Dive 12.1 — The commit LSN is the cursor →_
