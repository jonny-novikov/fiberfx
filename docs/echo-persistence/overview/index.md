---
title: "Echo Persistence — Overview"
id: echo-persistence-overview
status: established
route: "/echo-persistence/overview"
kind: "course overview — module hub (3 dives)"
design: "Follows the html/redis-patterns course sheet, re-themed: persistence accent amber/bronze (--p-accent #b06f12, tint #f4e7cd); the one deviation from the B0 base identity."
ratified-against: "github.com/jonny-novikov/fiberfx@echo_mq · docs/graft + docs/echo_mq"
renders-to: "overview/index.html"
---

# Keeping the state that matters { id="echo-persistence-overview" }

> _EchoMQ enqueues on Valkey — a job on disk within a 1s window, on one box. Echo Persistence is everything beyond that for the state that must not be lost or must live off the machine: Champ accepts at in-heap speed with a fsync per K records, a transactional page-store commits each batch as one LSN replicated to Tigris, and the same model is built twice — native Elixir on CubDB and Rust on Fjall._

This is the course hub. The landing page lists the thirteen modules; this overview establishes the one idea behind all of them in three dives, then sends you into Module 1.

**Grounding.** docs/graft (`graft.design.md`, `graft.engine-split.design.md`), docs/echo_mq (`emq.roadmap.md`), `echo/apps/echo_store`, `echo/apps/echo_graft` — every figure verbatim from a committed record. Numbers are single-core sandbox measurements against MinIO; the spread between tiers is the lesson, not the absolutes.

## §1 The one knob { id="knob" }

Every engine accepts a job and decides two things at once: how much of it survives a crash, and how fast it says yes. Those are the same knob — the fsync is fixed cost, and throughput is how many durable records you amortize it across. An in-memory map rides infinitely many records per fsync and loses everything on a crash; Oban's single-insert rides one durable record per fsync and loses nothing.

So the design question for Echo Persistence is not *whether* to fsync, but how to reach a **per-commit, replicated** guarantee without collapsing to the per-commit floor. The answer pairs **Champ** — an in-memory structure with a checkpoint every K records — as the accept tier, and **Graft** — a transactional page-store replicated to Tigris — as the commit tier, with the commit LSN published over EchoMQ as the change-feed.

The four-way shootout, measured at N = 20,000 on one vCPU (Postgres `synchronous_commit=on`, Redis AOF `everysec`):

| engine | store | durability | single jobs/s | batch jobs/s |
|---|---|---|---|---|
| Memory | in-memory map | none | 336,961 | — |
| Champ K=10,000 | local fsync snapshot | bounded ≤ 10,000 rec | 103,970 | — |
| Champ K=1,000 | local fsync snapshot | bounded ≤ 1,000 rec | 33,989 | — |
| BullMQ | Redis AOF everysec | bounded 1s | 6,388 | 16,180 |
| Oban | Postgres sync commit | strict per-commit | 718 | 13,235 |

A factor of 469 separates strict per-commit from no durability; Oban single → batch is a factor of 18 from spreading one fsync across 1,000 jobs. Champ's K and Graft's batch are how the strict-and-replicated tier stays off that floor.

## §2 The three dives { id="dives" }

- **Dive 1 — The durability spectrum** (`/echo-persistence/overview/the-durability-spectrum`) — the four-way shootout read mechanically, and the two independent axes: the loss window, and whether state leaves the box.
- **Dive 2 — The two-tier shape** (`/echo-persistence/overview/the-two-tier-shape`) — Champ accepts at in-heap speed; Graft commits one LSN, replicated to Tigris behind a conditional-write fence. The seam, and the per-call durability mode.
- **Dive 3 — Persistence in the platform** (`/echo-persistence/overview/persistence-in-the-platform`) — the four storage tiers, Echo Bus beside Echo Persistence, the durability dial per queue, and the two engines that coexist.

## §3 References & sources { id="refs" }

Echo records:
- graft.design.md — the two-tier design and the shootout — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.design.md
- graft.engine-split.design.md — the two coexisting engines — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.engine-split.design.md
- emq.roadmap.md — EchoMQ, the bus the change-feed rides — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/echo_mq/emq.roadmap.md

External:
- Valkey persistence (AOF) — the inherited 1s window — https://valkey.io/topics/persistence/
- orbitinghail/graft — the transactional model (read-only idea source, MIT/Apache-2.0) — https://github.com/orbitinghail/graft
- Tigris object conditionals — create-if-not-exists, the commit fence — https://www.tigrisdata.com/docs/objects/conditionals/
- Designing Data-Intensive Applications, Kleppmann 2017 — WAL, group commit, replication — https://dataintensive.net

Design reference:
- Redis Patterns Applied — the course sheet this design follows, re-themed — https://jonnify.fly.dev/redis-patterns

---

_Pager: ← Echo Persistence (landing) · Dive 1 — The durability spectrum →_
