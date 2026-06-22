---
title: "Module 5 — MVCC & time travel"
id: ep-m5-hub
status: established
route: "/echo-persistence/local-store/mvcc-time-travel"
kind: "module 5 hub — Chapter II, 3 dives"
design: "html/redis-patterns sheet, re-themed amber/bronze."
pedagogy: "Taught through a unique interactive MVCC facet-selector SVG; no machine numbers."
renders-to: "local-store/mvcc-time-travel/index.html"
---

# MVCC & time travel { id="ep-m5-hub" }

> _Module 4 left us with one fact: old roots stay valid. Multiversion concurrency control is what you get for free from it. A snapshot is a retained root, so readers never lock and never block the writer, and "the state at any past LSN" is just the root that was current then._

**Interactive figure (hub).** Four version roots v1–v4 in a chain over a shared, immutable node pool, with a reader pinned at v2 and a writer at the head v4. Tapping "coexisting versions" highlights all roots and the pool; "lock-free" highlights the reader and writer proceeding together; "time travel" highlights the version axis as selectable by LSN.

## §1 One fact, three payoffs { id="facets" }

Because an update keeps the old root, many versions exist at once over a single shared node pool — **coexisting versions**. A reader grabs the current root and reads it to completion no matter what the writer does next, and the writer appends new roots without waiting on any reader — **lock-free** concurrency, no mutual blocking. And since each LSN named a root, you can open the root current at any LSN — **time travel**, the checkout-at-LSN the change feed and replicas depend on. Each is a dive.

## §2 The three dives { id="dives" }

- **Dive 5.1 — Coexisting versions** — many roots, one node pool; click a version and watch which nodes it reaches, mostly shared, a few its own. → `/echo-persistence/local-store/mvcc-time-travel/coexisting-versions`
- **Dive 5.2 — Lock-free readers** — start a reader, let the writer commit, and watch the reader keep reading its pinned version while the head races ahead. → `/echo-persistence/local-store/mvcc-time-travel/lock-free-readers`
- **Dive 5.3 — Checkout & GC** — open the Volume at any past LSN with a scrubber, then run GC and watch old roots reclaimed except the one a reader pins. → `/echo-persistence/local-store/mvcc-time-travel/checkout-and-gc`

## §3 Build & check { id="build" }

**What you build.** One sentence each linking the three facets back to "old roots stay valid": why coexistence is automatic, why reads need no lock, why checkout-at-LSN is well-defined. The chain of reasoning is the deliverable.

**Check.** What is a snapshot, in one phrase; and what is the single thing GC must never reclaim? "A retained root" and "a root a reader still pins" mean you have the module.

## §4 References & sources { id="refs" }

External:
- Multiversion concurrency control — readers and writers, no locks — https://en.wikipedia.org/wiki/Multiversion_concurrency_control
- CubDB.Snapshot — a snapshot as a retained version — https://hexdocs.pm/cubdb/CubDB.Snapshot.html
- orbitinghail/graft — checkout-at-LSN, the change feed — https://github.com/orbitinghail/graft

Echo records:
- graft.design.md — MVCC, checkout-at-LSN, delta snapshots — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.design.md
- store.design.md — snapshots and retention on CubDB — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/echo_mq/store/design/store.design.md

---

_Pager: ← CubDB architecture · Dive 5.1 — Coexisting versions →_
