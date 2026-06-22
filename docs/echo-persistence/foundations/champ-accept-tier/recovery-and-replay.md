---
title: "Recovery & replay"
id: ep-m2-d3
status: established
route: "/echo-persistence/foundations/champ-accept-tier/recovery-and-replay"
kind: "module 2 · dive 2.3"
design: "html/redis-patterns sheet, re-themed amber/bronze."
pedagogy: "Taught through a unique interactive restore-then-replay stepper; the one figure pair is flagged indicative single-core."
renders-to: "foundations/champ-accept-tier/recovery-and-replay.html"
---

# Recovery & replay { id="ep-m2-d3" }

> _A crash takes the heap, not the disk. Recovery is two moves: load the last snapshot, then replay the intents recorded after it. The snapshot is a fast starting point; the intent log carries the rest._

**Interactive figure.** A recovery stepper. On disk: a snapshot box followed by six intent boxes, with a crash marker. Below, the in-heap state as ten cells. Stepping forward crashes the heap to empty, restores the snapshot as four cells, then replays the six intents one cell at a time until all ten are filled — recovered, identical to before the crash. Prev/next or run.

## §1 Restore, then replay { id="seq" }

The sequence is the lesson: crash empties the heap, restore loads the snapshot instantly, and each replay applies one logged intent until the state is whole again.

## §2 The log is the truth { id="truth" }

The snapshot is an optimization, not the source of truth — it spares you replaying from the beginning. Truth is the snapshot plus the ordered intents after it, so recovery is deterministic: same snapshot, same intents, same state. Measured on the bench, seed-and-restore lands in single-digit milliseconds and replay runs at over a million intents a second — _indicative single-core figures_, included only to say the operation is cheap, not slow. The same restore-plus-replay shape returns later for replicas catching up and for the change feed.

## §3 References & sources { id="refs" }

Echo records:
- store.design.md — seed + restore, intent replay — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/echo_mq/store/design/store.design.md
- graft.design.md — the snapshot-plus-log recovery model — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.design.md

External:
- Write-ahead logging — log-then-apply, the replay idea — https://en.wikipedia.org/wiki/Write-ahead_logging
- Designing Data-Intensive Applications, Kleppmann 2017 — snapshots + logs, deterministic replay (Ch. 3) — https://dataintensive.net

---

_Pager: ← The checkpoint dial · Module 3 — Persistence concepts →_
