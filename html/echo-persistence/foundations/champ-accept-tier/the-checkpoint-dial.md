---
title: "The checkpoint dial"
id: ep-m2-d2
status: established
route: "/echo-persistence/foundations/champ-accept-tier/the-checkpoint-dial"
kind: "module 2 · dive 2.2"
design: "html/redis-patterns sheet, re-themed amber/bronze."
pedagogy: "Taught through a unique interactive checkpoint gauge; K is shown as the loss window, not a throughput number."
renders-to: "foundations/champ-accept-tier/the-checkpoint-dial.html"
---

# The checkpoint dial { id="ep-m2-d2" }

> _Champ snapshots every K records. That single number is two things at once: the loss window — exactly the records accepted since the last snapshot — and the throughput dial, because one fsync covers all K._

**Interactive figure.** A semicircular checkpoint gauge. The filled arc is the records accepted since the last snapshot, out of K. Add records (+50, +250); when the arc reaches K a snapshot is fsync'd and the arc resets to empty. A K selector (100 / 1,000 / 10,000) changes how fast the arc fills — bigger K, slower fill, fewer fsyncs, wider window. The arc's current value is the loss window.

## §1 K is the loss window { id="dial" }

The arc is exactly what a crash would lose right now. Raise K and it fills more slowly — fewer fsyncs, a larger window; lower K and it snapshots often — a smaller window, more fsyncs.

## §2 The same lever, named for Champ { id="tradeoff" }

This is the spectrum's one knob wearing Champ's clothes. Records-per-fsync from Module 1 is here called K, and because the structure is persistent (Dive 2.1) the snapshot it fsyncs is a reference, not a copy — so raising K is nearly free on the accept side and simply widens the window. There is no "right" K; there is the K your queue's tolerable loss allows. The next dive answers the question this raises: when the window does take records, how does Champ get them back?

## §3 References & sources { id="refs" }

Echo records:
- graft.design.md — checkpoint_every K, the loss window — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.design.md
- store.design.md — the snapshot cadence — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/echo_mq/store/design/store.design.md

External:
- Valkey persistence — the time-based cousin (every-second) — https://valkey.io/topics/persistence/
- Designing Data-Intensive Applications, Kleppmann 2017 — snapshotting and bounded loss (Ch. 3) — https://dataintensive.net

---

_Pager: ← The in-heap structure · Dive 2.3 — Recovery & replay →_
