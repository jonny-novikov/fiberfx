---
title: "The in-memory feed"
id: ep-m8-d3
status: established
route: "/echo-persistence/engines/rust/the-in-memory-feed"
kind: "module 8 · dive 8.3"
design: "html/redis-patterns sheet, re-themed amber/bronze."
pedagogy: "Taught through a unique interactive ring-buffer + fallback SVG; no machine numbers."
renders-to: "engines/rust/the-in-memory-feed.html"
---

# The in-memory feed { id="ep-m8-d3" }

> _The Rust engine serves its change feed from memory: recent commits live in a fixed-size ring, broadcast to every subscriber at its own cursor — a hit is an O(1) read, no disk, no network. A subscriber that falls behind the ring's window is not dropped: it falls back to the durable segments in object storage, catches up to the window edge, and rejoins._

**Interactive figure.** A writer feeds a five-slot in-memory ring holding the most recent commit LSNs, with the head slot marked. Subscriber cursors A and B sit under the ring slot matching their position when in-window. Committing advances the ring and can push a cursor off the left edge; reading while behind the window drops that cursor to a segments band in object storage below, where it catches up to the window edge before rejoining the ring.

## §1 Broadcast, window, fallback { id="ring" }

A and B start at the head. Commit a few times without letting B read — the ring slides and B's next LSN ages out. Reading A after each commit keeps it in memory (O(1), no I/O). Then read B: its next LSN has left the window, so it falls back to segments, catches up to the window edge, and rejoins — no commit lost.

## §2 Memory speed, durable floor { id="why" }

Serving the feed from memory is what makes the Rust engine's notifications cheap: a subscriber that stays close to the head reads each new commit straight from the ring, with no I/O at all, and the broadcast fans one append out to every listener. The ring is bounded on purpose — it holds only the most recent commits, so memory use is fixed no matter how long the engine runs. The cost of that bound is that a slow or briefly-disconnected subscriber can fall behind the oldest entry still in memory. The feed handles this without dropping anyone: because every commit is also a durable segment in object storage (Module 6, Module 9), a lagging subscriber reads the missing range from segments, catches up to the window edge, and resumes from the ring. So the feed is fast in the common case and complete in the worst case — the in-memory path and the durable path are the same ordered stream, two ways to reach it. In the Rust engine this ring is the `InMemoryFeed`, and `publish_feed_advance` fires **only when the remote LSN advances** — a no-op push notifies no one — while eg.4 republishes those advances onto the EchoMQ lane `egraft:feed:{vol}` through a `BusFeed` sink, so a BEAM consumer observes them over the bus without the engine being touched. That durable floor — the shared remote both engines lean on — is the whole of Module 9.

## §3 References & sources { id="refs" }

External:
- Circular buffer — the bounded ring — https://en.wikipedia.org/wiki/Circular_buffer
- tokio broadcast — fan-out with a lag/fallback boundary — https://docs.rs/tokio/latest/tokio/sync/broadcast/index.html
- Change data capture — the ordered change stream — https://en.wikipedia.org/wiki/Change_data_capture

Echo records:
- graft specs / graft.3.md — eg.3 — branded-id identity + the EchoMQ change-feed — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/specs/graft.3.md
- graft.roadmap.md — eg.3 — the EchoMQ change-feed off the commit LSN — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.roadmap.md
- graft.engine-split.design.md — echo_graft in-memory feed, segment fallback — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.engine-split.design.md
- emq.roadmap.md — change feed, subscriber catch-up — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/echo_mq/emq.roadmap.md

---

_Pager: ← OpenDAL & the portable remote · Module 9 — Tigris & the fence →_
