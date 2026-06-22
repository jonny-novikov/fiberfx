---
title: "Persistence in the platform"
id: echo-persistence-dive-platform
status: established
route: "/echo-persistence/overview/persistence-in-the-platform"
kind: "overview dive 3 of 3"
design: "html/redis-patterns sheet, re-themed amber/bronze persistence accent."
renders-to: "overview/persistence-in-the-platform.html"
---

# Where persistence sits { id="echo-persistence-dive-platform" }

> _The platform is two halves that compose: Echo Bus (EchoMQ on Valkey) carries the work, and Echo Persistence keeps the state. Persistence spans four storage tiers, and a queue is placed on a durability dial across them — the only durability the enqueue hot path touches is a small, low-volume outbox beside the bus._

## §1 The four storage tiers { id="tiers" }

State moves down a ladder of tiers, each with a different job. A read faults up the ladder; a commit appends locally and replicates down to Tigris.

| tier | role | note |
|---|---|---|
| ETS | in-process L1 head cache | derived, safe to drop |
| Valkey | the bus (RESP3) + the L2 | EchoMQ, fast, volatile |
| CubDB / Fjall | durable local page tier | append-only, MVCC, the LSN log |
| Tigris | remote object storage | `/segments` + `/logs/.../commits/{LSN}` |

The page tier itself is built twice and the two engines coexist by ruling: the native Elixir `EchoStore.Graft.*` on CubDB is the canonical default; the Rust `echo_graft` on Fjall + OpenDAL serves raw-page and replica-recovery workloads, driven over the bus under a non-colliding name. Both replicate to Tigris behind the same conditional-write fence.

## §2 The durability dial { id="dial" }

Each queue is placed on a dial: Memory (holding nothing), Champ-K (a bounded window), or Champ + a page engine + Tigris (per-commit and replicated). Crucially, the only durability the enqueue **hot path** touches is the outbox — a low-volume intent journal standing beside the bus, a small mostly-idle dependency, not the path every dequeue, heartbeat, and ack runs through. The bus stays on Valkey; the page tier serves the page/replica need separately.

- telemetry → engages **ETS + Valkey** only (Memory tier, nothing durable; the bus carries it)
- ordinary work → engages **ETS + Valkey + CubDB** (Champ-K bounded window; outbox intent, async ship)
- payments → engages **all four: ETS + Valkey + CubDB/Fjall + Tigris** (per-commit, replicated off-box)

EchoMQ itself dogfoods the page engine as its durable spine, and the planned Stream Tier archives there — so Echo Persistence is not a bolt-on beneath the bus, it is the floor the bus stands on. The thirteen course modules build this ladder from the bottom up.

## §3 References & sources { id="refs" }

- graft.engine-split.design.md — the tiers, the two engines, the outbox-vs-page split — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.engine-split.design.md
- emq.roadmap.md — the bus, dogfooding the page engine, the Stream Tier — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/echo_mq/emq.roadmap.md
- durability.ex — the low-volume outbox beside the bus — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/apps/echo_store/lib/echo_store/durability.ex
- lucaong/cubdb — the native local page tier — https://github.com/lucaong/cubdb
- fjall-rs/fjall — the Rust engine's local store — https://github.com/fjall-rs/fjall
- ETS — the L1 head cache — https://www.erlang.org/doc/man/ets
- Valkey — the bus and the L2 — https://valkey.io

---

_Pager: ← Dive 2 — The two-tier shape · Into the course — the thirteen modules →_
