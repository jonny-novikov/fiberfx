---
title: "Lock-free readers"
id: ep-m5-d2
status: established
route: "/echo-persistence/local-store/mvcc-time-travel/lock-free-readers"
kind: "module 5 · dive 5.2"
design: "html/redis-patterns sheet, re-themed amber/bronze."
pedagogy: "Taught through a unique interactive swimlane-timeline SVG; no machine numbers."
renders-to: "local-store/mvcc-time-travel/lock-free-readers.html"
---

# Lock-free readers { id="ep-m5-d2" }

> _A reader takes hold of the current root and reads it to the end. Whatever the writer does next — commit a new root, ten new roots — the reader's view is fixed, because its root is immutable. And the writer never waits for a reader, because it only ever appends._

**Interactive figure.** A writer lane with version commit ticks advancing rightward over time, the newest being the head. A reader lane below: starting a reader draws a bar pinned to the head of that moment; further writer commits move the head right while a dashed line keeps the reader bar attached to its pinned, older version. Commit, start-reader, and reset buttons.

## §1 The head moves; the reader doesn't { id="lanes" }

Commit a couple of versions, then start a reader. Commit again: the head advances while the reader stays pinned to the version it opened on — no lock taken, nothing blocked either way.

## §2 Where the locks went { id="why" }

In a mutable store, a reader and a writer touching the same data must take turns, so one waits — that is what a lock *is*. Immutability removes the shared mutable thing entirely: the reader's root and the writer's new root are different objects, so there is nothing to contend over. Readers scale out freely, a long analytical read can't stall the write path, and the writer's only serialization is the tiny head swap from Module 3's OCC, not a lock over the data. For a durable queue this is the difference between draining the backlog and inspecting the backlog never fighting each other. The one cost is that a reader pins its version alive — exactly what GC must respect, in the last dive.

## §3 References & sources { id="refs" }

External:
- Multiversion concurrency control — readers don't block writers — https://en.wikipedia.org/wiki/Multiversion_concurrency_control
- CubDB.with_snapshot — a consistent read while writes continue — https://hexdocs.pm/cubdb/CubDB.html#with_snapshot/2
- Snapshot isolation — the guarantee a pinned reader gets — https://en.wikipedia.org/wiki/Snapshot_isolation

Echo records:
- store.design.md — lock-free reads beside the write lock — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/echo_mq/store/design/store.design.md
- graft.design.md — readers, the head, and OCC — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.design.md

---

_Pager: ← Coexisting versions · Dive 5.3 — Checkout & GC →_
