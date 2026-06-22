---
title: "Compaction"
id: ep-m4-d3
status: established
route: "/echo-persistence/local-store/cubdb/compaction"
kind: "module 4 · dive 4.3"
design: "html/redis-patterns sheet, re-themed amber/bronze."
pedagogy: "Taught through a unique interactive live/dead reclaim SVG; the live-fraction bar is structural, not a benchmark."
renders-to: "local-store/cubdb/compaction.html"
---

# Compaction { id="ep-m4-d3" }

> _Never overwriting has a price: the file only grows. Every update supersedes nodes that are now dead — still on disk, no longer reachable from the current root. Compaction is the sweep: copy the live data to a fresh file and reclaim the rest._

**Interactive figure.** A file as a row of blocks, some live and some dead. Each write supersedes older blocks (turning them dead) and appends new live blocks, so the file grows while the live set stays small; a bar tracks the live fraction. Compact copies only the live blocks to a fresh, shorter file and reclaims the dead space. Write, compact, reset.

## §1 Live versus dead { id="grow" }

Writing appends live blocks and turns superseded ones dead; the file grows, the live set stays small, the waste climbs. Compact copies the live blocks to a fresh file and reclaims the dead — done in the background, no read or write blocked.

## §2 A background sweep, not a stall { id="why" }

Compaction reads everything reachable from the current root and writes it to a new file, then switches over and drops the old one. It runs in the background while normal reads and writes continue against the live tree, because immutability means the data being copied never changes underfoot. The trigger is a ratio, not a clock: when dead data passes a threshold of the file, sweep. For the durable tier this keeps the page log's footprint bounded without ever blocking an enqueue, reusing the same "copy the live set forward" move that recovery and replication lean on elsewhere.

## §3 References & sources { id="refs" }

External:
- CubDB · compact/1 — how compaction works — https://hexdocs.pm/cubdb/CubDB.html#compact/1
- lucaong/cubdb — auto-compaction thresholds — https://github.com/lucaong/cubdb
- Log-structured storage — dead space and compaction, generally — https://en.wikipedia.org/wiki/Log-structured_merge-tree

Echo records:
- store.design.md — keeping the page log bounded — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/echo_mq/store/design/store.design.md
- graft.design.md — the durable tier's footprint — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.design.md

---

_Pager: ← The immutable B-tree · Module 5 — MVCC & time travel →_
