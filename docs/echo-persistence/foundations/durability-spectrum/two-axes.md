---
title: "Two axes, one decision"
id: ep-m1-d3
status: established
route: "/echo-persistence/foundations/durability-spectrum/two-axes"
kind: "module 1 · dive 1.3"
design: "html/redis-patterns sheet, re-themed amber/bronze."
pedagogy: "Taught through a unique interactive durability×replication plane; no machine numbers."
renders-to: "foundations/durability-spectrum/two-axes.html"
---

# Two axes, one decision { id="ep-m1-d3" }

> _The shootout measured one thing — the loss window. A second axis is independent of it: does the durable state ever leave the machine? A tier can be strict but single-node, or bounded but replicated. Placing a queue means choosing both._

**Interactive figure.** A two-axis plane: horizontal is durability (weak → strict), vertical is replication (single-node → off-box). The engines sit where they fall — Memory bottom-left, Oban bottom-right, BullMQ bottom-centre, Champ (async snapshot) upper-left — and the top-right quadrant (strict and off-box) is highlighted as the goal, holding **Champ + Graft**. Three workload buttons (telemetry, ordinary work, payments) drop a pulsing marker into the corner that workload *needs*, with a readout explaining why. The lesson is that the two corners are chosen by two separate questions.

## §1 The durability–replication plane { id="plane" }

The plane separates what the shootout conflated. Loss window runs left-to-right; replication runs bottom-to-top. They are independent: Oban is strict but single-node unless Postgres streaming replication is bolted on; Champ's snapshot is bounded-loss yet ships off-box asynchronously. A queue is placed by answering both — how much loss is tolerable, and must the state survive losing the box.

- **telemetry** → lossy · single-node — cheapest corner; Memory does fine.
- **ordinary work** → bounded loss · off-box — a small window is acceptable, but the work should outlive the machine; Champ's async ship sits here.
- **payments** → strict · off-box — no acknowledged loss, must survive losing the box; only the top-right corner will do.

## §2 The corner the course reaches { id="corner" }

The plane makes the design's target precise. Oban owns the bottom-right — strict, but single-node; Champ's async snapshot reaches off-box only at a bounded loss, upper-left. The corner no single engine holds is **top-right**: strict *and* off-box. Echo Persistence reaches it by composition — Champ accepts (left axis handled by K), Graft commits transactionally and replicates to Tigris (the move up the right edge) — which is why "Champ + Graft" sits where it does. The next chapters build each half; this is the corner they aim at.

## §3 References & sources { id="refs" }

Echo records:
- graft.design.md — the two axes and the target corner — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.design.md
- graft.engine-split.design.md — replication as a distinct concern — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.engine-split.design.md

External:
- Tigris object conditionals — the off-box, fenced commit — https://www.tigrisdata.com/docs/objects/conditionals/
- Designing Data-Intensive Applications, Kleppmann 2017 — replication and durability as separate guarantees (Ch. 5) — https://dataintensive.net

---

_Pager: ← The shootout and the one knob · Chapter II — The local store →_
