---
title: "Module 3 — Persistence concepts"
id: ep-m3-hub
status: established
route: "/echo-persistence/foundations/persistence-concepts"
kind: "module 3 hub — Chapter I, 3 dives"
design: "html/redis-patterns sheet, re-themed amber/bronze."
pedagogy: "Engine-neutral vocabulary taught through a unique interactive Volume-anatomy SVG; no machine numbers."
renders-to: "foundations/persistence-concepts/index.html"
---

# Persistence concepts { id="ep-m3-hub" }

> _Before either engine, the words. Both the native Elixir engine and the Rust one speak the same five — Volume, LSN, snapshot, the OCC commit, the conditional-write fence. Learn them engine-neutral here and the two engines later are the same idea twice._

**Interactive figure (hub).** An anatomy of a Volume: a container holding a strip of LSN cells, a read pointer marking a snapshot at an LSN, and a commit appended at the head through a fence gate. Tapping a term (Volume / LSN / snapshot / commit / fence) lights up its element and gives an engine-neutral definition pointing to the relevant dive.

## §1 Five words, one model { id="anatomy" }

A **Volume** is the unit of durable state — a branded id and an append-only log. Each entry is a commit named by a monotonic **LSN**, so "the state" is always "the log up to some LSN." A **snapshot** is therefore just a read at an LSN, and because the log is append-only that read is consistent and lock-free. A **commit** appends the next LSN; the **fence** is what guarantees only one writer claims that next slot. The last two are the subtle ones, so they each get a dive.

## §2 The three dives { id="dives" }

- **Dive 3.1 — Volume, LSN, snapshot** — the log as an immutable ribbon; scrub to any past LSN and read the snapshot you would see. → `/echo-persistence/foundations/persistence-concepts/volume-lsn-snapshot`
- **Dive 3.2 — The OCC commit** — two writers, one head LSN; one appends, the other is told `{:conflict, head}` and retries. The local serialization. → `/echo-persistence/foundations/persistence-concepts/the-occ-commit`
- **Dive 3.3 — The conditional-write fence** — two nodes write the same commit object; create-if-not-exists lets one through and rejects the other. The remote fence. → `/echo-persistence/foundations/persistence-concepts/the-conditional-write-fence`

## §3 Build & check { id="build" }

**What you build.** A five-line glossary in your own words: Volume, LSN, snapshot, commit, fence — each defined by what it *is*, not how it's coded.

**Check.** Answer two questions without code: why is a snapshot free if the log is append-only, and what is the difference between the OCC commit (3.2) and the fence (3.3)? Both are "one writer wins," at two different layers — local process versus remote object store.

## §4 References & sources { id="refs" }

Echo records:
- graft.design.md — Volume, LSN, snapshot, commit, fence — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.design.md
- graft.engine-split.design.md — the vocabulary shared by both engines — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.engine-split.design.md

External:
- orbitinghail/graft — the LSN-log model — https://github.com/orbitinghail/graft
- Optimistic concurrency control — the commit discipline — https://en.wikipedia.org/wiki/Optimistic_concurrency_control
- Designing Data-Intensive Applications, Kleppmann 2017 — logs, snapshots, isolation (Ch. 3, 7) — https://dataintensive.net

---

_Pager: ← Champ, the accept tier · Dive 3.1 — Volume, LSN, snapshot →_
