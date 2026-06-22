---
title: "The commit-log outbox"
id: ep-m7-d3
status: established
route: "/echo-persistence/engines/native-elixir/the-commit-log-outbox"
kind: "module 7 · dive 7.3"
design: "html/redis-patterns sheet, re-themed amber/bronze."
pedagogy: "Taught through a unique interactive outbox-drain-with-fence SVG; no machine numbers."
renders-to: "engines/native-elixir/the-commit-log-outbox.html"
---

# The commit-log outbox { id="ep-m7-d3" }

> _The commit log earns its keep twice. Each entry is durable locally the instant it's written — that's recovery — and it is also a pending item in an outbox: the Committer drains the log to Tigris, uploading each segment with a conditional PUT so two committers can never double-write, then marks it shipped. One structure is both the durability log and the replication source._

**Interactive figure.** On the left, a commit log where each entry carries two badges — durable (always, once written) and its upload state (pending → shipped). A Committer in the center reads the oldest pending entry and issues a conditional PUT to Tigris on the right, which holds shipped segments; a high-water mark shows the highest contiguous shipped LSN. "Append" adds a durable, pending entry; "ship next" drains the oldest pending one (the PUT returns 201 and it becomes shipped). Toggling "simulate contention" makes the PUT return 412 — the fence rejecting a duplicate write — and the entry is marked shipped idempotently anyway.

## §1 Durable now, shipped soon { id="outbox" }

Append an entry and it is durable in CubDB at once — recovery is covered — and pending upload. Ship it and the Committer issues `PUT seg/<lsn>` with `If-None-Match: *`: 201 Created means the fence held and the segment is uploaded; the entry flips to shipped and the high-water mark advances. Turn on contention and the same PUT returns 412 — another committer already wrote that segment — so no second copy is created, and the entry is marked shipped regardless.

## §2 One log, two jobs { id="why" }

Most systems keep a write-ahead log for crashes and a separate queue for replication, then fight to keep them consistent. The native engine refuses the duplication: the commit log is the outbox. A commit is durable the moment CubDB has it, so recovery (Module 6) needs nothing else; and the very same entries are the work list the Committer drains to object storage. Shipping is decoupled and idempotent — the Committer uploads a segment with a conditional PUT (create-if-not-exists, the fence from Module 3), so if another committer already wrote that segment the PUT fails the precondition and no second copy is created; the entry is marked shipped either way. A high-water mark tracks the highest contiguous shipped LSN, which is exactly what a replica needs to know where to start. Durability, replication, and the change feed all fall out of one append-only log — which is why this engine is the platform's default. Chapter III continues with the Rust engine, which makes different bets under the same contracts.

## §3 References & sources { id="refs" }

External:
- Transactional outbox — log doubles as outbox — https://microservices.io/patterns/data/transactional-outbox.html
- If-None-Match — conditional PUT as the fence — https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/If-None-Match

Echo records:
- graft.engine-split.design.md — commit-log-as-outbox, Committer, fence — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.engine-split.design.md
- store.design.md — Committer drain, shipped high-water mark — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/echo_mq/store/design/store.design.md
- emq.roadmap.md — upload + change-notify integration — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/echo_mq/emq.roadmap.md

---

_Pager: ← The lazy Reader · Module 8 — The Rust engine →_
