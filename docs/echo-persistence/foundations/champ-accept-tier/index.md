---
title: "Module 2 — Champ, the accept tier"
id: ep-m2-hub
status: established
route: "/echo-persistence/foundations/champ-accept-tier"
kind: "module 2 hub — Chapter I, 3 dives"
design: "html/redis-patterns sheet, re-themed amber/bronze."
pedagogy: "Taught through a unique interactive lifecycle SVG; no machine throughput numbers on the hub."
renders-to: "foundations/champ-accept-tier/index.html"
---

# Champ, the accept tier { id="ep-m2-hub" }

> _The first tier says yes fast. Champ holds the outbox in a persistent in-heap structure and writes a snapshot to disk every K records, so the accept path runs at heap speed while a single fsync covers a whole interval. Three dives — the structure, the checkpoint dial, recovery — each by working the figure, not reading a benchmark._

**Interactive figure (hub).** A Champ lifecycle flow — accept (in-heap CHAMP) → checkpoint (snapshot every K, fsync) → crash → recover (restore + replay). Tapping a stage reveals it and points to the matching dive; a run button pulses the loop. It orients the three dives.

## §1 Why an accept tier { id="lifecycle" }

A strict, replicated commit is expensive, and you do not want every `enqueue` to wait for it. Champ absorbs the write at heap speed and bounds the exposure, leaving the durable, replicated commit to the second tier on its own schedule. The bound is K: the records accepted since the last snapshot are the only ones a crash can take, so K is the loss window in records and the throughput dial at once.

Three properties make that work, and each is a dive. The structure is **persistent**, so a snapshot is a cheap reference, not a copy. The checkpoint is **periodic**, so one fsync serves K records. Recovery is **restore-plus-replay**, so a lost heap is rebuilt from the last snapshot and the intent log after it.

## §2 The three dives { id="dives" }

- **Dive 2.1 — The in-heap structure** — insert a key and watch the new version share every untouched node with the old; structural sharing is what makes a snapshot nearly free. → `/echo-persistence/foundations/champ-accept-tier/the-in-heap-structure`
- **Dive 2.2 — The checkpoint dial** — K is the loss window; feed the gauge, watch the at-risk window fill and a snapshot fire, set K and see the rhythm move. → `/echo-persistence/foundations/champ-accept-tier/the-checkpoint-dial`
- **Dive 2.3 — Recovery & replay** — a crash, then restore from the last snapshot and replay the intents after it; step the sequence. → `/echo-persistence/foundations/champ-accept-tier/recovery-and-replay`

## §3 Build & check { id="build" }

**What you build.** A back-of-envelope sizing note for one queue: pick an acceptable loss window in records, set K to it, and state what that costs (snapshot frequency) and buys (accept latency) — direction, not absolute throughput.

**Check.** Explain, without numbers, why a snapshot of a persistent structure does not copy the whole map; and describe what recovery reads, in order, after a crash.

## §4 References & sources { id="refs" }

Echo records:
- graft.design.md — the accept tier and the checkpoint — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.design.md
- store.design.md — Champ recovery and replay — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/echo_mq/store/design/store.design.md

External:
- Persistent data structures — structural sharing — https://en.wikipedia.org/wiki/Persistent_data_structure
- Elixir Map — the BEAM's immutable maps — https://hexdocs.pm/elixir/Map.html
- Designing Data-Intensive Applications, Kleppmann 2017 — snapshots + logs (Ch. 3) — https://dataintensive.net

---

_Pager: ← The durability spectrum · Dive 2.1 — The in-heap structure →_
