---
title: "Dive 14.1 — Tables & Properties"
id: ep-m15-d1
status: established
route: "/echo-persistence/platform/the-door-to-bcs/tables-and-properties"
kind: "module 15 · dive 14.1"
design: "html/redis-patterns sheet, re-themed amber/bronze."
pedagogy: "Taught through a unique interactive property-table + newer-wins-coherence SVG; no machine numbers."
grounded-in: "echo_data/bcs/property_store.ex (ordered_set keyed by branded id; page_desc) · coherence.ex + graft/id.ex (newer-wins, the id is the version) · graft.engine-split.design.md (EchoStore.Table L1)"
renders-to: "platform/the-door-to-bcs/tables-and-properties.html"
---

# Tables & Properties { id="ep-m15-d1" }

> _The first thing BCS needs from the floor is a place to keep a component, and the floor already has the perfect shape for it: a table keyed by the branded id. A property store is an `ordered_set` on the 14-byte name, so it is sorted by birth for free; `EchoStore.Table` is the L1 ETS cache that serves reads without a lock; and `EchoStore.Coherence` keeps that cache correct with one rule — newer wins — where the version is the id itself._

**Interactive figure.** A durable engine feeds coherence messages to an `EchoStore.Table` L1 cache holding rows keyed by branded id (name, version id, value). Writing sends a message whose id is greater, so newer wins and the row updates; a stale message carries a lesser id and is ignored; a read is served lock-free.

## §1 State keyed by identity { id="keyed" }

A component has to live somewhere, and BCS puts it in the simplest structure that respects the branded id: a property store is a process owning one private `ordered_set` table keyed by the 14-byte branded string — `put(id, value)`, `get(id)`, and a `page_desc(n)` that reads the most recent `n` entries. Because the key is the id, and a branded id sorts lexicographically in mint order, the table is sorted by birth with no extra index — the newest rows are simply the largest keys, so "recent first" is a backward walk of the set. This is the same property the whole course has leaned on, now doing ordinary database work: the snowflake's time-ordering, which gave free-order compaction on the stream tier and a version for coherence, here gives a sorted table and recent-first paging for free. Nothing about this is queue-specific. It is a generic place to keep any entity's properties, and it inherits the floor: the authoritative copy is a Graft commit, durable and replicated, while the property store and the L1 are the fast, local view of it.

## §2 Coherence by identity { id="coh" }

A local cache is only useful if it stays correct, and the elegant part is how cheaply it does. `EchoStore.Table` is the L1 ETS cache over the engine, read lock-free — a native BEAM strength — and `EchoStore.Coherence` keeps it consistent with a single rule: **newer wins**, where the version *is the branded id*. There is no separate version counter to maintain, no vector clock to merge; a coherence message is "a message about a name," and the receiver applies it only if the incoming id is greater than the one it holds. Because lexicographic order equals chronological order for branded ids, "greater id" means "more recent write," so a stale message — one carrying a lesser id, perhaps a late-arriving duplicate or a slow replica's echo — is simply ignored, and the cache never moves backwards. This is the coherence model the bus already spoke in Chapter 12, surfaced as a table primitive: the same "message about a name" that bound replicas to a cursor now binds an L1 row to its newest writer. With a sorted, durable, identity-keyed table that stays coherent by id alone, the floor has handed BCS everything a component needs — and the next dive can stop talking about storage and start talking about *shape*.

## §3 References & sources { id="refs" }

Echo records:
- graft.engine-split.design.md — EchoStore.Table (L1 ETS, lock-free) + EchoStore.Coherence (newer-wins, a message about a name) — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.engine-split.design.md
- notifications.design.md — the property store keyed by the 14-byte branded id; ordered_set, page_desc — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/codemojex/notifications/notifications.design.md
- graft.design.md — the branded id is the version; lexicographic = chronological — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.design.md

External:
- ETS — ordered_set; lock-free reads on the BEAM — https://www.erlang.org/doc/man/ets.html
- Last-write-wins — newer-wins resolution — https://en.wikipedia.org/wiki/Last_write_wins

---

_Pager: ← Module 15 — The door to BCS · Dive 14.2 — Entities, components & the law →_
