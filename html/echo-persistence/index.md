---
title: "Echo Persistence"
id: echo-persistence-landing
status: established
route: "/echo-persistence"
kind: "course landing — 13 modules, 4 chapters"
design: "Follows the html/redis-patterns course sheet (.chap / .mods / .chap-link), re-themed: persistence accent amber/bronze (--p-accent #b06f12). Chapter bands carry an Open chapter link on the right."
pedagogy: "Each module teaches a mechanism through a unique interactive SVG; single-machine figures are demoted to indicative single-core asides."
renders-to: "index.html"
---

# Durable state, taught as built { id="echo-persistence-landing" }

> _EchoMQ enqueues on Valkey — fast and volatile. Echo Persistence is the floor beneath it: an in-heap accept tier, a transactional page-store built twice (Elixir on CubDB, Rust on Fjall), and replication to Tigris. The course builds that ladder from the bottom up, and every module is an interactive dive into a mechanism, not a table of machine numbers._

**Interactive figure (landing).** A storage-ladder SVG — ETS, Valkey, CubDB/Fjall, Tigris stacked top to bottom. Tapping a tier reveals its job; the "read path" button animates a fault upward, the "commit path" button animates an append-local-then-replicate-down. It orients the learner to the shape the fourteen modules build.

## §1 The course map { id="map" }

Status legend: **built** (ready to open) · **planned** (specified, building) · **soon** (on the runway).

### Ch. I — Foundations · _Open chapter → /echo-persistence/foundations/durability-spectrum_
The mechanism and the model — why durability is one knob, and the two-tier shape that turns it.

- **Module 1 · The durability spectrum** — _built_ — the one knob (durable records per fsync) and the two axes a queue is placed on. → `/echo-persistence/foundations/durability-spectrum`
- **Module 2 · Champ, the accept tier** — _built_ — in-heap accept with a checkpoint per K; recovery and replay as mechanism. → `/echo-persistence/foundations/champ-accept-tier`
- **Module 3 · Persistence concepts** — _built_ — Volume, LSN, snapshot, the OCC commit, the conditional-write fence — engine-neutral. → `/echo-persistence/foundations/persistence-concepts`

### Ch. II — The local store · _Open chapter → /echo-persistence/local-store/cubdb_
CubDB in depth — the append-only immutable B-tree under the native engine, and what it makes possible.

- **Module 4 · CubDB architecture** — _built_ — append-only immutable B-tree; the page log on it; its place among the tiers. → `/echo-persistence/local-store/cubdb`
- **Module 5 · MVCC & time travel** — _built_ — zero-cost snapshots from immutability; reading a Volume at any past LSN. → `/echo-persistence/local-store/mvcc-time-travel`
- **Module 6 · Replay & recovery** — _built_ — the log as truth; green boot, replica catch-up, feed replay as one idea. → `/echo-persistence/local-store/replay-and-recovery`

### Ch. III — The engines · _Open chapter → /echo-persistence/engines/native-elixir_
Built twice and bridged — the native Elixir engine, the Rust twin, replication, and the cross-runtime contract.

- **Module 7 · The native Elixir engine** — _built_ — EchoStore.Graft.* on CubDB: the write-lock, OCC, the streamer, the lazy reader. → `/echo-persistence/engines/native-elixir`
- **Module 8 · The Rust engine** — _built_ — echo_graft on Fjall + OpenDAL: the fork, the runtime, the in-memory feed. → `/echo-persistence/engines/rust`
- **Module 9 · Tigris & the fence** — _built_ — push rollup, create-if-not-exists, log-head recovery — the shared remote. → `/echo-persistence/engines/tigris+fence`
- **Module 10 · The BEAM↔Rust contract** — _built_ — eg.4: the byte-frozen wire, the backend, the compositional cross-runtime proof. → `/echo-persistence/engines/beam-rust-contract`

### Ch. IV — The platform · _Open chapter → /echo-persistence/platform/echomq-bus_
The whole picture — the bus itself, persistence beneath it, why it beats classical scheduling, and the door it opens onto BCS.

- **Module 11 · EchoMQ Bus** — _built_ — ValKey Streams internals and the EchoMQ 3.0 Stream Tier built on them: the verbs, the PEL, retention. → `/echo-persistence/platform/echomq-bus`
- **Module 12 · EchoBus + Echo Persistence** — _built_ — the composition: EchoMQ 3.0 beside the durable floor of EP1–10; the loop across four tiers, the archive fold. → `/echo-persistence/platform/bus-and-persistence`
- **Module 13 · Why it beats classical scheduling** — _built_ — Postgres-backed Oban, honestly; what Echo separates where Oban couples, and where each one wins. → `/echo-persistence/platform/beats-classical-scheduling`
- **Module 14 · The door to BCS with Echo Persistence** — _built_ — the durable log plus Tables & Properties as a substrate for building systems; worked on Codemoji. → `/echo-persistence/platform/the-door-to-bcs`

## §2 References & sources { id="refs" }

Echo records:
- graft.engine-split.design.md — the storage tiers and the two engines — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.engine-split.design.md
- graft.design.md — the two-tier design — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.design.md
- emq.roadmap.md — the bus the change-feed rides — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/echo_mq/emq.roadmap.md

External:
- lucaong/cubdb — the native local page tier — https://github.com/lucaong/cubdb
- fjall-rs/fjall — the Rust engine's local store — https://github.com/fjall-rs/fjall
- Tigris object conditionals — the commit fence — https://www.tigrisdata.com/docs/objects/conditionals/

Design reference:
- Redis Patterns Applied — the course sheet this design follows, re-themed — https://jonnify.fly.dev/redis-patterns

---

_Pager: ← The overview · Module 1 · the durability spectrum →_
