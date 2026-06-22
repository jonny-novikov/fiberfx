---
title: "Dive 12.3 — The loop closes"
id: ep-m12-d3
status: established
route: "/echo-persistence/platform/bus-and-persistence/the-loop-closes"
kind: "module 12 · dive 12.3"
design: "html/redis-patterns sheet, re-themed amber/bronze."
pedagogy: "Taught through a unique interactive four-tier flow + archive-fold return-arc SVG; no machine numbers."
grounded-in: "docs/echo_mq/emq.streams.md (emq3.5 fold into EchoStore.Graft) · docs/echo_mq/kb/streams-tier/streams.synthesis.md (merge-read across W, F3.4-A) · docs/graft/graft.design.md (the LSN cursor)"
renders-to: "platform/bus-and-persistence/the-loop-closes.html"
---

# The loop closes { id="ep-m12-d3" }

> _Follow a write forward and it crosses the four tiers this course was built around: accepted by Champ, stored in CubDB, committed by Graft as one replicated LSN, published onto an EchoMQ stream. That is a pipeline. What makes it a system is the return leg — the archive fold — which does not delete the stream's old tail but commits it back into the engine as durable segments._

**Interactive figure.** Forward: a write moves Accept → Local → Engine → Bus. Fold: below the watermark `W`, the Stream Tier's tail is committed back into the engine with `EchoStore.Graft.commit/3` — fold-before-trim — closing the loop.

## §1 The fold closes the loop { id="fold" }

Module 11 left a deliberate tension: a stream is an append-only log, `XACK` does not delete, so retention must trim — but trimming must never outrun what has been saved (the fold-before-trim rule of fork F3.4-A). This dive is where "saved" gets its meaning. The emq3.5 archive is a dedicated fold consumer that reads the stream's old tail — everything below the watermark `W` — and commits those slices into the engine with `EchoStore.Graft.commit/3`. The engine streams those pages from CubDB to Tigris exactly as any other commit would, so a slice of the bus's history becomes a set of the store's durable segments. Only *then* may the trim advance, which is why the fold watermark always sits at or ahead of the trim watermark. The payoff is the merge-read of Module 11.3: a deep read concatenates the segments below `W` (now in the store) with the live tail at or above `W` (still on the bus), with no gap and no overlap, because the same watermark divides them. `W` is *derived* from the engine's committed frontier — the engine owns its extent, so the cut cannot drift from what is actually durable. The fold is not a backup job bolted on; it is the return leg that turns the bus's retention into the store's durability, using the one commit primitive the whole course has been building.

## §2 The four-tier cycle { id="cycle" }

Stand back and the four chapters are four tiers of one cycle. A write is **accepted** by Champ (Chapter I) with a bounded loss window; it is held in the **local** CubDB store (Chapter II) with copy-on-write versioning; it is **committed** by Graft (Chapter III) as a single replicated LSN behind the fence; and it is **published** onto an EchoMQ stream (Chapter IV) for consumers and replicas. Then the archive fold carries the stream's aged tail back into the engine, and the cycle is closed. Two things bind the ends, and both are earlier dives in this very module: the **commit LSN** is the cursor every tier names its position with (12.1), and the **change feed** off that LSN is how a commit becomes a bus event in the first place. The outbox (12.2) sits to one side of this cycle, keeping the enqueue hot path off durable storage while still surviving a crash. So "the bus and the store are one system" is not a slogan: it is a literal loop, joined at a shared integer and a shared feed, where the engine's commit drives the bus and the bus's retention drives the engine's commit. That is where Echo Persistence has been heading all along — and the door past it, in the chapters to come, is where this durable substrate stops being plumbing and starts being the Branded Component System.

## §3 References & sources { id="refs" }

Echo records:
- emq.streams.md — emq3.5, the fold consumer commits trimmed slices to EchoStore.Graft; fold-before-trim — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/echo_mq/emq.streams.md
- streams.synthesis.md — the merge-read across the watermark W; fork F3.4-A — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/echo_mq/kb/streams-tier/streams.synthesis.md
- graft.design.md — commit, the LSN as the cursor binding both ends of the loop — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.design.md

External:
- Log-structured merge-tree — the tail-to-segments fold — https://en.wikipedia.org/wiki/Log-structured_merge-tree
- Event sourcing — the log as the system of record — https://en.wikipedia.org/wiki/Event_sourcing

---

_Pager: ← Dive 12.2 — The outbox beside the bus · Module 13 — Why it beats classical scheduling →_
