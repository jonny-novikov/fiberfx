---
title: "Module 8 — The Rust engine"
id: ep-m8-hub
status: established
route: "/echo-persistence/engines/rust"
kind: "module 8 hub — Chapter III, 3 dives"
design: "html/redis-patterns sheet, re-themed amber/bronze."
pedagogy: "Taught through a unique interactive contract-spine two-engines SVG; no machine numbers."
grounded-in: "docs/graft/graft.roadmap.md · docs/graft/graft.engine-split.design.md · docs/graft/specs/"
renders-to: "engines/rust/index.html"
---

# The Rust engine { id="ep-m8-hub" }

> _The platform's second engine is `echo_graft`: a from-scratch fork **seeded from** upstream Graft (its SQLite layer stripped), written in Rust on Fjall and Apache OpenDAL, run as a supervised **sidecar** the BEAM drives over EchoMQ. By the Operator's COEXIST ruling it does not replace the native engine — it is a peer, implementing the same contract Module 3 defined (Volume, LSN, OCC commit, snapshot, the fence, the change feed) on a different substrate, reached over the bus rather than linked in-process._

**Interactive figure (hub).** A central spine of five contract concerns — Volume & LSN, OCC commit, snapshot, the fence, the change feed — with the native Elixir engine box on the left (CubDB, BEAM) and the Rust engine box on the right (Fjall, OpenDAL). Tapping a concern highlights it, lights connectors to both engine boxes, and fills each box with that engine's implementation of the concern, so the identical guarantee and the divergent internals are visible side by side.

## §1 Why a second engine — and why a sidecar { id="fork" }

Two engines exist because the contract from Module 3 is substrate-neutral: nothing in "Volume addressed by LSN, commit under OCC, fence with create-if-not-exists, feed the ordered changes" demands the BEAM. So the platform implements it twice. The native engine optimizes for tight Elixir integration — in-process ETS caches, GenServer serialization, no boundary crossing. The Rust engine, `echo_graft`, is **seeded from** the upstream Graft Volume runtime (MIT/Apache-2.0, a read-only idea source — no upstream compatibility is kept) with the SQLite extension (`libgraft_ext`) removed and three seams re-cut for this platform: a Tigris remote, branded-Snowflake identity at the external edge, and an EchoMQ change-feed off the commit LSN. Crucially it is **not linked into the BEAM during the spine**: it runs as a supervised Rust sidecar (`echo_graft_backend`) the BEAM orchestrates over EchoMQ (RESP3) through a versioned wire (`echo_graft_proto`), with `EchoStore.GraftBackend` as the Elixir client. The bus is the contract; the commit LSN is the synchronization cursor every advance publishes on the change-feed lane. Why fork rather than rebuild? Champ is bounded-loss (a window of K records, snapshot-grained replication) and Oban is single-node unless Postgres streaming replication is bolted on — Graft already solves the missing transactional-and-replicated quadrant, so reusing its core buys the consistency model without a multi-month build or the rejected SQLite/C-binding path. The work is sequenced **eg.1 → eg.6**: eg.1 the core fork (Fjall retained, SQLite cut), eg.2 the Tigris remote + the conditional-write fence, eg.3 branded-id identity + the EchoMQ feed, eg.4 the BEAM↔Rust backend + protocol (Module 10), eg.5 a low-latency group-commit tier, eg.6 ship + the durability shootout beside Champ and Oban. The three dives take this substrate apart — the LSM-tree, OpenDAL, the in-memory feed — always against the same contract.

## §2 The three dives { id="dives" }

- **Dive 8.1 — Fjall & the LSM-tree** — writes fill a memtable, flush to immutable SSTables, and compact by merging; a different shape from CubDB's B-tree, same append-only promise. → `/echo-persistence/engines/rust/fjall-and-the-lsm-tree`
- **Dive 8.2 — OpenDAL & the portable remote** — one operator over many backends; Tigris, S3, or fs are a config change, and the fence is one `if_not_exists` call. → `/echo-persistence/engines/rust/opendal-and-the-portable-remote`
- **Dive 8.3 — The in-memory feed** — the change feed served from a ring broadcast to subscribers on lane `egraft:feed:{vol}`, with a fallback to segments for any consumer that falls off the window. → `/echo-persistence/engines/rust/the-in-memory-feed`

## §3 Build & check { id="build" }

**What you build.** Take the five contract rows and write, for each, the native approach and the Rust approach in one line apiece. If the two columns differ but the row's guarantee is identical, you have understood the split.

**Check.** Name one thing identical across both engines and one thing that differs — and where the Rust engine actually lives. "Same fence protocol; different local store (B-tree vs LSM); and the Rust engine is a sidecar over the bus, not linked in-process" means you have the module.

## §4 References & sources { id="refs" }

External:
- orbitinghail/graft — the upstream Volume engine echo_graft is seeded from (MIT/Apache-2.0, read-only idea source) — https://github.com/orbitinghail/graft
- fjall-rs/fjall — the LSM-tree local store — https://github.com/fjall-rs/fjall
- Apache OpenDAL — one data-access layer, many backends — https://opendal.apache.org/
- Rust — the runtime for echo_graft — https://www.rust-lang.org/

Echo records:
- graft.roadmap.md — echo_graft: the eg.1–eg.6 ladder, the sidecar architecture, the fork brief — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.roadmap.md
- graft.engine-split.design.md — the COEXIST ruling (native EchoStore.Graft.* canonical, echo_graft_backend a peer) — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.engine-split.design.md
- graft specs (graft.1–graft.6) — the per-rung specs — https://github.com/jonny-novikov/fiberfx/tree/echo_mq/docs/graft/specs
- graft.design.md — Volume, OCC, fence, feed, substrate-neutral — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.design.md

---

_Pager: ← The native Elixir engine · Dive 8.1 — Fjall & the LSM-tree →_
