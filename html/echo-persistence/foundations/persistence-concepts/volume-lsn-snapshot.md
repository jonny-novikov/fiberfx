---
title: "Volume, LSN, snapshot"
id: ep-m3-d1
status: established
route: "/echo-persistence/foundations/persistence-concepts/volume-lsn-snapshot"
kind: "module 3 · dive 3.1"
design: "html/redis-patterns sheet, re-themed amber/bronze."
pedagogy: "Taught through a unique interactive LSN-ribbon scrubber; no machine numbers."
renders-to: "foundations/persistence-concepts/volume-lsn-snapshot.html"
---

# Volume, LSN, snapshot { id="ep-m3-d1" }

> _A Volume is an append-only log; each commit gets the next LSN. So "the state at LSN k" is just the log folded up to k — and a snapshot is a read at an LSN, nothing more. Because nothing is ever overwritten in place, every past point is still readable._

**Interactive figure.** An LSN ribbon: eight commit cells in order, each setting a key. A read-point slider selects an LSN; commits up to it are visible, later ones dimmed and invisible to that reader; below, the folded state — the latest value of each key through the selected LSN — is shown as chips. Scrub it to read any past snapshot.

## §1 A read at an LSN { id="scrub" }

The snapshot at LSN k is the log folded to k; commits after k are simply not in this reader's view. No copy, no lock — the past is still there.

## §2 Why time travel is free { id="free" }

Append-only is the whole trick. A reader holding LSN k sees a fixed prefix of the log no matter how many commits land after, so reads need no lock and snapshots need no copy — the same property the persistent structure gave Champ in Module 2, now at the log level. It is also what makes a replica's "catch up to LSN k" and the change feed's "everything after LSN k" well-defined. The one hard part is appending the *next* LSN when two writers want it at once — the next two dives.

## §3 References & sources { id="refs" }

Echo records:
- graft.design.md — Volume, LSN, snapshot, checkout-at-LSN — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.design.md
- store.design.md — the append-only page log — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/echo_mq/store/design/store.design.md

External:
- orbitinghail/graft — the LSN-log model — https://github.com/orbitinghail/graft
- Multiversion concurrency control — read-at-version, snapshots — https://en.wikipedia.org/wiki/Multiversion_concurrency_control
- Designing Data-Intensive Applications, Kleppmann 2017 — snapshot isolation, logs (Ch. 3, 7) — https://dataintensive.net

---

_Pager: ← Persistence concepts · Dive 3.2 — The OCC commit →_
