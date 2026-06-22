---
title: "Dive 10.2 — Commit, ack, and the feed advance"
id: ep-m10-d2
status: established
route: "/echo-persistence/engines/beam-rust-contract/commit-ack-and-feed"
kind: "module 10 · dive 10.2"
design: "html/redis-patterns sheet, re-themed amber/bronze."
pedagogy: "Taught through a unique interactive sequence-diagram SVG; no machine numbers."
grounded-in: "docs/graft/specs/graft.4.md (the commit path, S-1, base-advisory + page-size reconciliations)"
renders-to: "engines/beam-rust-contract/commit-ack-and-feed.html"
---

# Commit, ack, and the feed advance { id="ep-m10-d2" }

> _One commit crosses the boundary and comes back twice: first as an `Ack` carrying the new LSN, then — if and only if the commit actually advanced the durable log — as a `FeedEvent` on a separate publish-only lane. That "if and only if" is the load-bearing invariant: a push that changes nothing publishes nothing, because the feed tracks the remote LSN, not the act of asking._

**Interactive figure.** A sequence diagram with three lifelines — client, backend, feed. `commit + push` draws the path downward in time: `Commit` (client→backend), a fence self-call producing an LSN, `Ack` (backend→client), a push self-call advancing the remote LSN, and a `FeedEvent` (backend→feed). `no-op push` draws `Push`, a self-call showing the LSN unchanged, and no feed event.

## §1 One request, two returns { id="path" }

A commit is a `Commit{corr, vid, base, pages}` on the Volume's command lane. The `corr` id is the request's name: the matching `Ack{corr, lsn}` echoes it on the per-client reply lane, so a client with many in-flight requests pairs each response without ambiguity. Two details of the commit are quietly load-bearing. First, **`base` is advisory**: the wire carries a base LSN, but the backend builds the writer from the Volume's own current snapshot — the engine's authoritative base — so a stale wire `base` does not silently widen the write; it surfaces as the real OCC conflict at `commit` (the same fence a concurrent writer hits). The wire's `base` is threaded only into the error detail; the engine's snapshot is the truth. Second, a `Page` is a fixed size (`PAGESIZE`, 4 KiB): the dispatch zero-pads a short page and refuses an oversize one with `unavailable` — never a panic. After the ack, `Push` drives `volume_push`, which takes the eg.2 conditional-write fence against object storage and, on success, advances the remote LSN.

## §2 The feed fires only on a real advance { id="liveness" }

The change-feed event is published by `publish_feed_advance`, and it is **gated on the remote LSN advancing** — not on the push being requested. This is the invariant the dive turns on, and the gate that proves it must be tested from both sides: a commit that advances the log must produce exactly one `FeedEvent` whose `lsn` matches the ack, and a no-op push — a push with nothing new to commit — must produce none. In the shipped backend this falls out of mechanism rather than a special case: the eg.3 feed is a concrete `InMemoryFeed` the backend cannot inject into, so after each push the session observes the engine's feed (`events_since` against a per-Volume bus cursor) and republishes any new events through a `BusFeed` sink onto `egraft:feed:{vol}`. If the LSN did not move, `events_since` returns nothing and the cursor does not advance, so the no-op publishes nothing — and the engine is never edited. The client therefore sees a strict order in the common case: the `Ack` confirms durability, and the subsequent `FeedEvent` confirms the advance is observable, which is what lets a reader react without polling. A lost fence is silent on the feed, exactly as it should be.

## §3 References & sources { id="refs" }

Echo records:
- graft specs / graft.4.md — the commit path, the base-advisory + page-size reconciliations, S-1 — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/specs/graft.4.md
- graft.roadmap.md — eg.2 fence + eg.3 feed, the rungs this path composes — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.roadmap.md
- store.design.md — commit, push, the remote LSN as cursor — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/echo_mq/store/design/store.design.md

External:
- Optimistic concurrency control — why a stale base is safe — https://en.wikipedia.org/wiki/Optimistic_concurrency_control
- Idempotence — a no-op that changes nothing — https://en.wikipedia.org/wiki/Idempotence

---

_Pager: ← Dive 10.1 — The byte-frozen wire & the handshake · Dive 10.3 — Crash, reconnect & the compositional proof →_
