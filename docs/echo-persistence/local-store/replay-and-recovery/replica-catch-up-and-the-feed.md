---
title: "Replica catch-up & the feed"
id: ep-m6-d3
status: established
route: "/echo-persistence/local-store/replay-and-recovery/replica-catch-up-and-the-feed"
kind: "module 6 · dive 6.3 (closes Chapter II)"
design: "html/redis-patterns sheet, re-themed amber/bronze."
pedagogy: "Taught through a unique interactive primary/segment-store/replica topology SVG; no machine numbers."
renders-to: "local-store/replay-and-recovery/replica-catch-up-and-the-feed.html"
---

# Replica catch-up & the feed { id="ep-m6-d3" }

> _A replica behind at some LSN pulls the segments committed after it from object storage and applies them — the same fold as Dive 6.1, with bytes from the wire — until its lag is zero. And the change feed is not a separate thing: it is this ordered stream of commits, handed to any subscriber that asks for "everything after LSN k."_

**Interactive figure.** A primary at the head LSN pushes committed segments into a central segment store (Tigris); a replica behind pulls pending segments and applies them, with a red lag meter shrinking as it catches up. The same stream is delivered to a feed subscriber shown below, which receives each committed LSN as a chip. "Primary commits" grows the log and the lag; "replica pulls" closes the lag by one; "auto catch-up" drains to lag zero.

## §1 Push segments, pull to catch up { id="topo" }

A primary commit adds a segment to the store (pending for the replica) and pushes it to the feed. The replica fetches and applies pending segments — the same fold, bytes from the store — each pull closing the lag by one until it reaches the head. The feed subscriber sees the very same ordered commits the replica does.

## §2 The feed is catch-up, productized { id="why" }

A replica and a feed subscriber are the same client wearing different hats. Both say "I'm at LSN k, give me what's after"; both receive the ordered segments and apply — or react to — each one. The only differences are intent and lifetime: a replica wants a full copy and runs forever; a subscriber may want just the deltas and may stop. That is why the engine ships one stream and exposes it as both replication and the change feed. The bytes are the Zstd-framed page segments uploaded behind the conditional-write fence from Module 3, so a replica reads exactly what the primary committed, in order — deterministic catch-up, no divergence. With this, Chapter II is complete: a durable, versioned, replicated local store. Chapter III opens the two engines that implement it.

## §3 References & sources { id="refs" }

External:
- orbitinghail/graft — pull-based catch-up, the change feed — https://github.com/orbitinghail/graft
- Change data capture — the log as a stream of changes — https://en.wikipedia.org/wiki/Change_data_capture
- Designing Data-Intensive Applications, Kleppmann 2017 — replication logs, CDC (Ch. 5, 11) — https://dataintensive.net

Echo records:
- graft.design.md — replica catch-up, segments, change feed — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.design.md
- graft.engine-split.design.md — segment format, the feed in both engines — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.engine-split.design.md

---

_Pager: ← Green boot · Module 7 — The native Elixir engine →_
