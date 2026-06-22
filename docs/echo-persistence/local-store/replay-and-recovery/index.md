---
title: "Module 6 — Replay & recovery"
id: ep-m6-hub
status: established
route: "/echo-persistence/local-store/replay-and-recovery"
kind: "module 6 hub — Chapter II, 3 dives (closes Chapter II)"
design: "html/redis-patterns sheet, re-themed amber/bronze."
pedagogy: "Taught through a unique interactive log-with-operation-spans SVG; no machine numbers."
renders-to: "local-store/replay-and-recovery/index.html"
---

# Replay & recovery { id="ep-m6-hub" }

> _Three operations that look unrelated — booting a fresh process, catching up a replica, feeding a subscriber changes — are the same operation: replay the immutable log from some LSN forward to the head. Only the starting LSN and the source of the bytes differ._

**Interactive figure (hub).** One commit log of ten LSNs, a snapshot flag at LSN 3, the head at LSN 10. Three operation spans are drawn below it: green boot replays from the snapshot to the head, replica catch-up from the replica's LSN 6 to the head, and the change feed from a subscriber's LSN 8 to the head and onward (a dashed arrow). Tapping an operation highlights its span and the log cells it replays — making visible that the three differ only in where they start.

## §1 Recovery is not a special case { id="one" }

Chapter II established that the log is append-only and immutable, so the state at any LSN is the log folded to that point, and old roots stay valid. The payoff this module collects is that recovery stops being special. Rebuilding a crashed process, bringing a lagging replica current, and streaming changes to a consumer are not three subsystems — they are one fold, `apply(commit)` repeated from a starting LSN to the head, parameterized only by where you begin and whether the bytes are local or pulled from object storage. The Stream Tier's archive fold (emq3.5) joins the same family rather than adding a fourth subsystem: its recovery is `replay(from_lsn, apply_fn)` from the archive watermark, one more cursor on the one log.

## §2 The three dives { id="dives" }

- **Dive 6.1 — One log, three replays** — three cursors on one log; advance each to the head and watch the apply step be identical. → `/echo-persistence/local-store/replay-and-recovery/one-log-three-replays`
- **Dive 6.2 — Green boot** — blue serves while green seeds from the snapshot, replays the tail, and traffic cuts over with zero downtime. → `/echo-persistence/local-store/replay-and-recovery/green-boot`
- **Dive 6.3 — Replica catch-up & the feed** — a replica pulls segments after its LSN until lag is zero, and the change feed is that same ordered stream. → `/echo-persistence/local-store/replay-and-recovery/replica-catch-up-and-the-feed`

## §3 Build & check { id="build" }

**What you build.** Write the one signature the module reduces to — `replay(from_lsn, apply_fn)` — and, in a sentence each, say what `from_lsn` is for green boot, replica catch-up, and the feed. The unification is the deliverable.

**Check.** What makes replay deterministic, and why does that let a replica and the primary agree byte-for-byte? "Same start, same ordered commits, same state" means you have the module.

## §4 References & sources { id="refs" }

External:
- State machine replication — deterministic replay equals agreement — https://en.wikipedia.org/wiki/State_machine_replication
- orbitinghail/graft — checkout-at-LSN, the change feed model — https://github.com/orbitinghail/graft
- Designing Data-Intensive Applications, Kleppmann 2017 — logs, replication, recovery (Ch. 3, 5) — https://dataintensive.net

Echo records:
- graft.design.md — replay, green boot, replica catch-up, change feed — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.design.md
- store.design.md — recovery as restore + replay — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/echo_mq/store/design/store.design.md

---

_Pager: ← MVCC & time travel · Dive 6.1 — One log, three replays →_
