---
title: "Dive 12.2 — The outbox beside the bus"
id: ep-m12-d2
status: established
route: "/echo-persistence/platform/bus-and-persistence/the-outbox-beside-the-bus"
kind: "module 12 · dive 12.2"
design: "html/redis-patterns sheet, re-themed amber/bronze."
pedagogy: "Taught through a unique interactive bus-vs-outbox SVG (hot path + replay); no machine numbers."
grounded-in: "docs/graft/graft.engine-split.design.md (EchoStore.Durability — the low-volume outbox beside the bus; SQLite/Memory adapters; Durability.Graft)"
renders-to: "platform/bus-and-persistence/the-outbox-beside-the-bus.html"
---

# The outbox beside the bus { id="ep-m12-d2" }

> _Make a durable record and enqueue a job, and you have written to two systems that cannot commit together — the classic dual-write trap, where a crash between the two leaves them disagreeing. The usual fix folds the enqueue into the database transaction via an outbox, but that risks putting a durable write on the hot path. EchoMQ's move is sharper: keep the bus on Valkey for speed, and stand the outbox beside it as a small, mostly-idle dependency that only the crash window ever reads._

**Interactive figure.** An enqueue goes to the bus (Valkey) on the fast path and records a low-volume intent in the outbox journal beside it. The bus is volatile; if it loses its crash window, the outbox replay re-enqueues exactly those intents.

## §1 The dual-write trap { id="dual" }

A great many bugs hide in a single innocent line: "save the record, then enqueue the job." Those are two systems — a store and a queue — and nothing makes the pair atomic. Crash after the save but before the enqueue and the work is durable but never scheduled; crash the other way and a job runs for a record that was rolled back. No ordering of the two writes closes the gap, because the gap is *between* them. The standard answer is the transactional outbox: write the intent to enqueue into the *same* transaction as the state, then a separate relay projects committed intents onto the queue — one commit, no divergence. It is the same idea the engines already use internally, where the commit log *is* the outbox and a drainer projects it. The open question the outbox always raises is cost: if every enqueue must now pass through a durable transaction, you have moved the database onto the hot path, which is exactly what a fast queue exists to avoid.

## §2 Beside the hot path, not on it { id="beside" }

EchoMQ resolves that tension by being explicit about what is hot and what is not. **The bus stays on Valkey** — fast and reliable, and treated as volatile — so the enqueue hot path never touches durable storage. Durability is a *separate, smaller* concern: `EchoStore.Durability` is a transactional-enqueue outbox whose own moduledoc is blunt about its size — the intents it carries are **low-volume**, "a small, mostly-idle dependency, not the hot path Oban puts every dequeue, heartbeat, and ack through." The durable write stands *beside* the bus; it records the intent so a crash window can be replayed, but it never enters the enqueue path. The contract is a small pluggable `Adapter` — append, replay, stats — and the shipped, dependency-free backends are `SQLite` (via `exqlite`) and `Memory` (ETS). A heavier journal is bring-your-own: a host can drop in Postgres, or the Graft commit-log-as-outbox, where an intent is simply a page commit in a reserved high LSN range — the same engine from Chapter III serving the outbox because the Volume is already there. So EchoMQ keeps the outbox's guarantee (no dual-write divergence; replay the crash window) without paying the outbox's usual tax (a durable write per enqueue). The lesson is the converse of the previous dive's: some seams should be tight (the cursor), and some should be deliberately loose (the journal beside the bus) — the skill is knowing which is which.

## §3 References & sources { id="refs" }

Echo records:
- graft.engine-split.design.md — EchoStore.Durability, the low-volume outbox beside the bus; the Adapter; SQLite / Memory; Durability.Graft — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.engine-split.design.md
- graft.design.md — the commit-log-as-outbox; replay the crash window — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.design.md
- store.design.md — EchoStore module architecture; the journal — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/echo_mq/store/design/store.design.md

External:
- Transactional outbox — intent in the same transaction as state — https://microservices.io/patterns/data/transactional-outbox.html
- Two-phase commit — the coordination the outbox avoids — https://en.wikipedia.org/wiki/Two-phase_commit_protocol

---

_Pager: ← Dive 12.1 — The commit LSN is the cursor · Dive 12.3 — The loop closes →_
