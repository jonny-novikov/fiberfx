---
title: "Checkout & GC"
id: ep-m5-d3
status: established
route: "/echo-persistence/local-store/mvcc-time-travel/checkout-and-gc"
kind: "module 5 · dive 5.3"
design: "html/redis-patterns sheet, re-themed amber/bronze."
pedagogy: "Taught through a unique interactive version-timeline + pin + GC SVG; no machine numbers."
renders-to: "local-store/mvcc-time-travel/checkout-and-gc.html"
---

# Checkout & GC { id="ep-m5-d3" }

> _Each LSN named a root, so opening the Volume at any LSN is just picking that root — checkout-at-LSN, the move behind the change feed and replica catch-up. But kept versions accumulate, so a retention policy reclaims old roots. The one rule GC must obey: never reclaim a version a reader still pins._

**Interactive figure.** Six version roots tagged LSN 10–15 in a row. A checkout slider highlights one as opened (the root current at that LSN). A pin can be placed on the checked-out version. A retention watermark marks the last three as kept; running GC reclaims versions older than the watermark unless a pin holds them. Slider, pin, run-GC, reset.

## §1 Open any LSN; keep what's pinned { id="travel" }

Scrub to open a version — you read the root current at that LSN, lock-free. Pin one to stand in for a live reader, then run GC: old, unpinned roots are reclaimed; the pinned one is kept no matter its age.

## §2 Why GC follows the pins { id="why" }

Checkout is free for the reason Dive 5.1 gave: the root and its nodes are still in the pool. Retention is the counterweight — without it the diffs pile up forever — so GC reclaims nodes no retained or pinned version can reach, the on-disk job compaction (Dive 4.3) performs. The safety rule is the point: a reader pinned at an old LSN keeps that root *and everything it reaches* alive, so GC computes liveness from active pins plus the retention window, never from age alone. Reclaim a pinned version and a reader would fault on a missing page; respect the pins and time travel stays sound. This is the machinery the change feed and replica catch-up sit on — and where Chapter III picks up, with the engines that turn these roots into replicated pages.

One scoping note for later chapters: this is one of *two* retention watermarks the platform carries. This one is the engine's version-history GC — which old roots are reclaimable. The other is the Stream Tier's trim window (Module 12.2 / emq3.4) — how far the live stream has been cut. They are different axes over different data, coupled only by fold-then-trim (a slice is folded durably before the stream may trim past it); whether they should also share a value is an open design question, not asserted here.

## §3 References & sources { id="refs" }

External:
- orbitinghail/graft — checkout-at-LSN, the change feed — https://github.com/orbitinghail/graft
- CubDB.Snapshot — pinned snapshots and release — https://hexdocs.pm/cubdb/CubDB.Snapshot.html
- Reachability & GC — liveness from roots, not age — https://en.wikipedia.org/wiki/Tracing_garbage_collection

Echo records:
- graft.design.md — checkout-at-LSN, retention, the change feed — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.design.md
- store.design.md — snapshot retention and GC on CubDB — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/echo_mq/store/design/store.design.md

---

_Pager: ← Lock-free readers · Module 6 — Replay & recovery →_
