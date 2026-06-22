---
title: "One log, three replays"
id: ep-m6-d1
status: established
route: "/echo-persistence/local-store/replay-and-recovery/one-log-three-replays"
kind: "module 6 · dive 6.1"
design: "html/redis-patterns sheet, re-themed amber/bronze."
pedagogy: "Taught through a unique interactive three-cursor log SVG; no machine numbers."
renders-to: "local-store/replay-and-recovery/one-log-three-replays.html"
---

# One log, three replays { id="ep-m6-d1" }

> _Put three cursors on the same commit log: a booting process at the last snapshot, a replica at its own LSN, a feed subscriber at its cursor. Advancing any of them runs the identical step — `apply(commit)` — one LSN at a time toward the head. Different starts, one operation._

**Interactive figure.** A commit log of ten LSNs across the top. Below it, three lanes — boot, replica, feed — each a progress bar with a token at its current LSN, starting at LSN 3, 6, and 8 respectively. Advancing a lane extends its bar by one LSN toward the head at LSN 10 and flashes a shared "apply(commit) → state" box, showing the step is the same for all three. "Advance all" moves every cursor; a reset returns them to their starting LSNs.

## §1 Same step, different starts { id="cursors" }

Advance any lane and it applies one commit, moving one LSN closer to the head — the same fold step lights up regardless of which cursor moved. Boot starts furthest back (from the snapshot), the feed nearest the head. Catch all three up and the point lands: one operation, three starting points.

## §2 Why one mechanism is enough { id="why" }

Collapsing three features into one fold is not a tidy diagram — it is the reason the engine is small. There is a single, well-tested replay path; boot, catch-up, and the feed are call sites that hand it a starting LSN. Determinism does the rest: the same commits applied in the same order reach the same state, so a replica that replays the primary's log is the primary, and a feed subscriber sees exactly what a recovering process would. The next two dives are this fold with the starting LSN and byte source pinned down — green boot from the local snapshot, replica catch-up from remote segments.

## §3 References & sources { id="refs" }

External:
- State machine replication — deterministic replay equals agreement — https://en.wikipedia.org/wiki/State_machine_replication
- Fold (higher-order function) — apply, repeated, over a sequence — https://en.wikipedia.org/wiki/Fold_(higher-order_function)
- Designing Data-Intensive Applications, Kleppmann 2017 — logs and replication (Ch. 5) — https://dataintensive.net

Echo records:
- graft.design.md — the unified replay path — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.design.md
- store.design.md — apply(commit) from a starting LSN — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/echo_mq/store/design/store.design.md

---

_Pager: ← Replay & recovery · Dive 6.2 — Green boot →_
