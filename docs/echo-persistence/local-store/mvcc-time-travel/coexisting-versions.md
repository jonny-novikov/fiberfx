---
title: "Coexisting versions"
id: ep-m5-d1
status: established
route: "/echo-persistence/local-store/mvcc-time-travel/coexisting-versions"
kind: "module 5 · dive 5.1"
design: "html/redis-patterns sheet, re-themed amber/bronze."
pedagogy: "Taught through a unique interactive shared-node-pool SVG; no machine numbers."
renders-to: "local-store/mvcc-time-travel/coexisting-versions.html"
---

# Coexisting versions { id="ep-m5-d1" }

> _Copy-on-write keeps every old root, so many versions are alive at once — all rooted in one shared pool of immutable nodes. A newer version reuses almost all of the older one's nodes and adds a few of its own. A snapshot, then, is nothing but a root into that pool._

**Interactive figure.** Three version roots v1, v2, v3 over a pool of five immutable nodes. Each root links to the three nodes it reaches; clicking a version highlights its reachable nodes — teal for the ones shared with the prior version, amber for its own new node — and dims the others. All three versions coexist in the same pool; no version is a copy.

## §1 Many roots, one pool { id="pool" }

Click a version: it reaches three nodes, sharing two with the others (teal) and owning one new node (amber). The versions coexist over the same shared, never-mutated pool.

## §2 Why keeping versions is free { id="why" }

Retaining an old version costs nothing extra because its nodes already exist in the pool — never overwritten, and newer versions simply don't reference the few they replaced. So "take a snapshot" is "remember this root," an O(1) act, and a Volume can hold many readable points at once for the price of the diffs between them. That is the engine behind delta snapshots and checkout-at-LSN: the deltas are exactly the per-version new nodes shown in amber. The only growth is those diffs — which compaction (Dive 4.3) and GC (Dive 5.3) keep in check.

## §3 References & sources { id="refs" }

External:
- Persistent data structures — many versions, shared nodes — https://en.wikipedia.org/wiki/Persistent_data_structure
- CubDB.Snapshot — a snapshot is a retained root — https://hexdocs.pm/cubdb/CubDB.Snapshot.html
- Multiversion concurrency control — coexisting versions — https://en.wikipedia.org/wiki/Multiversion_concurrency_control

Echo records:
- graft.design.md — delta snapshots, the per-version diff — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.design.md
- store.design.md — retained roots on CubDB — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/echo_mq/store/design/store.design.md

---

_Pager: ← MVCC & time travel · Dive 5.2 — Lock-free readers →_
