---
title: "Dive 13.2 — The commit log is the outbox"
id: ep-m13-d2
status: established
route: "/echo-persistence/platform/beats-classical-scheduling/the-commit-log-is-the-outbox"
kind: "module 13 · dive 13.2"
design: "html/redis-patterns sheet, re-themed amber/bronze."
pedagogy: "Taught through a unique interactive commit-log SVG (reserved @obx_base range, drain, replay); no machine numbers."
grounded-in: "docs/graft/graft.engine-split.design.md (Durability.Graft — outbox IS the commit log, @obx_base = 1 <<< 48, replay above a watermark, the Committer drain) · ADR-A"
renders-to: "platform/beats-classical-scheduling/the-commit-log-is-the-outbox.html"
---

# The commit log is the outbox { id="ep-m13-d2" }

> _Here is the move that makes the bus robust. Instead of a separate journal beside the engine, the durable record of an enqueue is the engine's own commit — `EchoStore.Durability.Graft` writes each intent as a page commit in a reserved high LSN range, `@obx_base = 1 <<< 48`, far above where ordinary page commits live. Because the intent is a commit, recording the work and making it durable are one act, and that one act inherits the Chapter III engine entire: the fence, replication to Tigris, log-head recovery._

**Interactive figure.** One commit log split into two regions by an `@obx_base` break — ordinary page commits at normal LSNs on the left, enqueue intents in the reserved high range on the right. The Committer drains intents to the work queue at-least-once; on crash, replay scans the reserved range above the watermark, and the intents survive because they are durable, replicated commits.

## §1 Recording and durability in one act { id="oneact" }

The dual-write problem of Module 12.2 came from two systems — a store and a queue — that could disagree across a crash. The commit-log-as-outbox removes one of them. In `EchoStore.Durability.Graft`, the outbox *is* the Graft commit log: an enqueue intent is written as a page commit, but in a reserved high LSN range, `@obx_base = 1 <<< 48`, so it cannot collide with the ordinary page commits that live at normal LSNs. The two share one log and one writer, separated only by where they sit on the LSN axis. Because the intent is itself a commit, recording the work and making it durable are a **single act** — there is no window between "saved" and "enqueued" for a crash to open, so the divergence simply cannot occur. And that one commit is not a lesser write than any other: it goes through the same OCC base-LSN check, the same conditional-write fence that makes the commit atomic against a racing writer, and the same page-rollup replication to Tigris. So an enqueue is, in one stroke, strict *and* replicated — the corner the classical queue could not reach — and it costs only what a Graft commit costs, riding the engine's batch for throughput. The engine earns this for free in the sense that matters: the Volume is already there for the page workloads of Chapter III, so the outbox adds a range, not an engine.

## §2 The drain and the replay { id="drain" }

A durable intent is not yet running work; something must turn the committed log into jobs on the bus, and that is the `Committer` — "the commit-log-as-outbox drain." It subscribes to the commit channel, and for each commit re-publishes that commit's names to the work queue **at-least-once**, tracking how far it has projected with a *persisted frontier*. At-least-once is the right guarantee precisely because the handlers downstream are already idempotent on the branded id (Module 11.1), so a name published twice after a restart is harmless. Recovery is the mirror image of the write: `EchoStore.Durability.Graft`'s replay scans the reserved range above a watermark and re-projects any intent the frontier had not yet reached, and the engine's own log-head recovery has already made those commits durably present after a crash. So the bus — volatile Valkey — can lose its in-flight projection without losing any work: the intents are durable, replicated commits, and the drain simply runs again from the frontier. This is exactly where EchoMQ 4+ is heading in the large: ADR-A makes the commit-log-as-outbox the journal itself, atomic and durable in one act, off SQL entirely. The robustness that the bus presents to its callers is, underneath, just the Chapter III engine doing what it already does — commit, fence, replicate, recover — with a reserved range and a drain on top.

## §3 References & sources { id="refs" }

Echo records:
- graft.engine-split.design.md — EchoStore.Durability.Graft, the outbox IS the commit log; @obx_base = 1 <<< 48; replay above a watermark; the Committer drain — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.engine-split.design.md
- eg-engine-split.progress.md — committer.ex: the commit-log-as-outbox drain, at-least-once, persisted frontier — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/eg-engine-split.progress.md
- echo_mq-v4-durability-adr.md — ADR-A: atomic and durable in one act, off SQL — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/echo_mq/kb/emq4-durability/echo_mq-v4-durability-adr.md

External:
- Transactional outbox — the intent in the same commit as the state — https://en.wikipedia.org/wiki/Transactional_outbox
- Idempotence — why at-least-once is safe here — https://en.wikipedia.org/wiki/Idempotence

---

_Pager: ← Dive 13.1 — The database on the hot path · Dive 13.3 — The balanced decision →_
