---
title: "Dive 11.1 — ValKey Streams internals"
id: ep-m11-d1
status: established
route: "/echo-persistence/platform/echomq-bus/valkey-streams-internals"
kind: "module 11 · dive 11.1"
design: "html/redis-patterns sheet, re-themed amber/bronze."
pedagogy: "Taught through a unique interactive two-recovery-paths SVG; no machine numbers."
grounded-in: "docs/echo_mq/kb/streams-tier/streams.synthesis.md · docs/echo_mq/emq.streams.md (emq3.3)"
renders-to: "platform/echomq-bus/valkey-streams-internals.html"
---

# ValKey Streams internals { id="ep-m11-d1" }

> _The hub showed the lifecycle; this dive goes under it, to the part most ad-hoc implementations get subtly wrong. A consumer group's pending list is not one recovery mechanism but two, and they recover different things: a consumer that restarts drains its own pending entries first, and a consumer that never comes back is recovered by a peer's claim on a beat. EchoMQ keeps both and names which is which._

**Interactive figure.** Two entries sit in the `process` group's pending list, owned by `c1` and idle. If c1 restarts, it re-reads its own PEL (`XREADGROUP … 0`) and recovers itself — ownership stays c1. If c1 is gone, `c2`'s `XAUTOCLAIM` beat takes the idle entries over and bumps their delivery count, recovering the peer.

## §1 Drain your own, then claim a peer's { id="paths" }

When an entry is read through a group it joins that group's pending list, owned by the consumer that read it, until that consumer `XACK`s it. Two distinct failures can leave an entry stuck there, and they want opposite recoveries. The first is a consumer that **crashes and restarts** under the same name: on its way back it must re-read its own pending entries before taking anything new, which it does with `XREADGROUP GROUP g c STREAMS s 0` — the `0` reads the PEL rather than `>` for new entries — so it resumes exactly where it left off. This recovers **self**. The second is a consumer that **never comes back**: its entries would sit idle forever, because nothing it owns will ever be re-read by it. Here a surviving consumer runs `XAUTOCLAIM` on a beat, claiming entries whose idle time exceeds a threshold and taking ownership of them. This recovers **peers**. EchoMQ's consumer makes both first-class and complementary: drain-own-PEL on start, the autoclaim beat for the rest. Conflating them is the classic bug — rely only on restart-drain and a permanently dead consumer's backlog is never recovered; rely only on the beat and a fast-restarting consumer races its own reclaim. The synthesis names this split explicitly so a spec can't quietly assume one covers both.

## §2 The handler, the count, the lazy group { id="handler" }

The posture is at-least-once with idempotent handlers; exactly-once is not claimed. The handler is one exact shape — `%{id, payload, attempts, group} → :ok | {:error, reason}` — the same contract the job `Consumer` already uses, so a stream consumer is not a new mental model. The `attempts` field is the load-bearing one, and EchoMQ writes it down as a **named invariant**: it maps to the entry's `XPENDING` delivery count, the same number `XAUTOCLAIM` increments on a reclaim, so a handler can see how many times an entry has been tried and decide to dead-letter rather than loop forever. Because delivery is at-least-once, a handler must be safe to run twice on the same `id` — the branded id is the natural idempotency key. Group creation is lazy and defensive: a consumer ensures its group on start with `XGROUP CREATE … MKSTREAM` and swallows only `BUSYGROUP` (a `WRONGTYPE` stays loud); the start position — `$` for new-only or `0` to replay — is a declared `start_link` option, never a silent default; and there is no destructive group verb in this tier. None of these are new commands; they are the discipline that turns the raw verbs into a consumer you can reason about.

## §3 References & sources { id="refs" }

Echo records:
- streams.synthesis.md — the recovery split, the handler mirror, the attempts ↔ XPENDING invariant (F3.3-B) — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/echo_mq/kb/streams-tier/streams.synthesis.md
- emq.streams.md — emq3.3 groups, at-least-once, idempotent handlers — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/echo_mq/emq.streams.md
- streams.design.A-consumer-lens.md — the consumer / operability lens — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/echo_mq/kb/streams-tier/streams.design.A-consumer-lens.md

External:
- XAUTOCLAIM — claiming idle pending entries — https://redis.io/docs/latest/commands/xautoclaim/
- XPENDING — the delivery count — https://redis.io/docs/latest/commands/xpending/

---

_Pager: ← Module 11 — EchoMQ Bus · Dive 11.2 — Retention & the never-deleted problem →_
