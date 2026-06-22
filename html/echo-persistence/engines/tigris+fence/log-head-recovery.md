---
title: "Log-head recovery"
id: ep-m9-d3
status: established
route: "/echo-persistence/engines/tigris+fence/log-head-recovery"
kind: "module 9 · dive 9.3 (closes Chapter III)"
design: "html/redis-patterns sheet, re-themed amber/bronze."
pedagogy: "Taught through a unique interactive cold-node recovery + lazy fault SVG; no machine numbers."
renders-to: "engines/tigris+fence/log-head-recovery.html"
---

# Log-head recovery { id="ep-m9-d3" }

> _A fresh node with nothing on disk doesn't download a database to come up. It reads the head object from the bucket to learn where the log ends, reads the commit chain and snapshot pointer to fix its position, and is then ready to serve — with zero pages loaded. Pages arrive lazily, faulted from segments only when something asks for them._

**Interactive figure.** A cold node on the left, initially knowing nothing, with a grid of eight page slots all empty and a status line. A Tigris bucket on the right holds a head object, a commit chain, a snapshot pointer, and page segments. Stepping reads the head into the node, then the chain, making the node ready with zero pages resident. Faulting a page draws an arrow from a segment to the node and fills one slot — showing pages load lazily rather than all at once.

## §1 Read the head, fault the rest { id="recover" }

Step forward: the node reads the `head` object (LSN 8) in one GET, then the commit chain and snapshot pointer (LSN 5), and becomes ready — still 0 pages resident. Then fault pages one at a time: each is fetched from a segment and cached, the resident count climbs, and the rest stay in object storage until asked. Ready happens before any page is loaded.

## §2 Why a cold node is ready in two reads { id="why" }

The expensive thing in recovery is data; the cheap thing is knowing where you are. Log-head recovery separates them. To be correct, a node only needs the head — the latest commit object — and the snapshot pointer it descends from; both are tiny objects, so two reads make the node authoritative about the log's end. It can then accept reads immediately, because a page it doesn't hold is just a fault: find the segment that carries that page's latest version (the rollup from Dive 9.1), fetch it, serve it, and keep it cached (the lazy Reader from Module 7). Nothing forces a full download — a node that only ever touches a hot working set only ever fetches that working set. This is what makes the remote a true floor rather than a backup: a brand-new replica, a restarted process, or a promoted standby all come up the same way, in two reads, and warm themselves on demand. It is the same fold the whole of Module 6 described, with its starting point — the head — read from the shared bucket. Chapter III is complete: one contract, two engines, one remote. Chapter IV turns to the platform around them.

## §3 References & sources { id="refs" }

External:
- orbitinghail/graft — checkout-at-LSN, lazy fetch — https://github.com/orbitinghail/graft
- Demand paging — load pages only when referenced — https://en.wikipedia.org/wiki/Demand_paging
- Object storage — the durable head and segments — https://en.wikipedia.org/wiki/Object_storage

Echo records:
- graft specs / graft.2.md — eg.2 — recovery from the remote log head — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/specs/graft.2.md
- graft.roadmap.md — eg.2 — recovery from the remote log head — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.roadmap.md
- graft.design.md — log-head recovery, lazy page faults — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.design.md
- store.design.md — head + snapshot pointer, fault-on-read — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/echo_mq/store/design/store.design.md

---

_Pager: ← The create-if-not-exists fence · Module 10 — The BEAM↔Rust contract →_
