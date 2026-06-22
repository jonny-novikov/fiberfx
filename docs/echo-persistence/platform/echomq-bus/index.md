---
title: "Module 11 — EchoMQ Bus"
id: ep-m11-hub
status: established
route: "/echo-persistence/platform/echomq-bus"
kind: "module 11 hub — Chapter IV (opens Chapter IV), 3 dives"
design: "html/redis-patterns sheet, re-themed amber/bronze."
pedagogy: "Taught through a unique interactive stream + consumer-group PEL SVG; no machine numbers."
reference: "Danni Popova — Replacing Kafka with Redis Streams (Arcjet), converted + annotated; mapped onto emq.streams.md"
renders-to: "platform/echomq-bus/index.html"
---

# The EchoMQ bus { id="ep-m11-hub" }

> _Ten modules built the durable floor; this one teaches the thing that sits on it. EchoMQ's newest tier is a stream tier — append-only event streams with consumer groups — built on the same ValKey/Redis Streams verbs a field team would reach for. The lesson is the consumer-group lifecycle: an entry is read into a group's pending list, acknowledged per group, re-claimed on crash — and exactly where ordering survives that and where it doesn't._

**Interactive figure (hub).** A producer appends entries to a stream shown as a row of cells in mint order, each tagged with a branded id. `XREADGROUP >` moves an entry to a per-group PEL panel, assigned to a consumer with a delivery count; `XACK` clears it from the PEL while it stays dimmed in the stream (acked ≠ deleted). Crashing c1 and running `XAUTOCLAIM` re-hands its pending entry to c2 with an incremented delivery count — returning it out of real-time order, the named exception to the order theorem.

## §1 The verbs, and the edge that appears with groups { id="stream" }

For a single reader a stream is three verbs — `XADD` to append, `XREAD` to consume, `XDEL` to remove. The edge appears the moment two independent consumers need the same entries: you can no longer delete on completion, since a fast group would pull entries out from under a slow one. The coordination primitive is the consumer group: an entry read through a group (`XREADGROUP GROUP g c >`) lands on that group's Pending Entries List, a consumer drains its own PEL first on rejoin, and `XACK` guarantees no re-delivery within that group. The trap the field account names precisely: an acknowledged entry is not deleted — it stays in the stream until something trims it, and left alone it fills the box. EchoMQ keeps these verbs exactly — `XADD`, `XRANGE`, `XREADGROUP`, `XACK`, `XAUTOCLAIM` — as additive registrations on the existing `EchoMQ.Connector`, a protocol minor on the same RESP3 wire and house port as the jobs, the bus, and the cache. No second system to run — which was the whole objection to Kafka.

## §2 What EchoMQ adds: invariants, not verbs { id="tier" }

EchoMQ 3.0 claims the small end explicitly — event streams, bounded retention, a handful of groups per stream — and keeps its databases (Tables, the journal, Postgres) beside the log, which makes keyed compaction someone else's problem. Its contribution is to turn each edge the field account discovered into something named. An order theorem: stream order equals branded-id sort order equals mint order, because every record's id is minted so its byte order is its time order; but a consumer group adds a second axis — a re-claimed PEL entry returns out of real-time order, the honest cost of at-least-once — and the spec names exactly where the theorem holds (the stream) and where it cannot (a re-claim), so a spec asserting "order preserved" can never be a false green. Retention is policy, not a bespoke process: a declared per-stream window (`MAXLEN ~` approx, `MINID` by mint instant) rather than a Janitor trimming by estimate. And the archive: a fold consumer commits each trimmed slice into the native `EchoStore.Graft` engine before it trims (fold-before-trim), and the engine streams those pages to Tigris — so the field account's "acked entries are never deleted" fear is answered by folding them to durable object storage, not by hoarding RAM.

## §3 The three dives { id="dives" }

- **Dive 11.1 — ValKey Streams internals** _(built)_ — the raw verbs and the PEL up close: the two recovery paths (drain-own-PEL vs `XAUTOCLAIM` beat), delivery counts, at-least-once with idempotent handlers. → `/echo-persistence/platform/echomq-bus/valkey-streams-internals`
- **Dive 11.2 — Retention & the never-deleted problem** _(built)_ — the unbounded stream, `XTRIM` `MAXLEN`/`MINID` by mint instant, and emq3.4 retention-as-policy with the open F3.4-A trim-cadence fork (fold-before-trim vs a timer that loses data). → `/echo-persistence/platform/echomq-bus/retention-and-the-never-deleted-problem`
- **Dive 11.3 — The Stream Tier ladder** _(built)_ — emq3.1–3.6 end to end: the writer law, the readers, the archive fold into `EchoStore.Graft` (CubDB→Tigris), and the merge-read that stitches segments to the live tail across the watermark. → `/echo-persistence/platform/echomq-bus/the-stream-tier-ladder`

## §4 Build & check { id="build" }

**What you build.** Take the field account's three pains — the multi-group deletion problem, the never-deleted accumulation, the trim-by-estimate Janitor — and name the EchoMQ answer to each: the PEL plus per-group `XACK`; the archive fold (emq3.5); declared retention policy (emq3.4). If each pain maps to an invariant, a policy, or a fold, you have the module.

**Check.** State exactly where the order theorem holds and where it breaks, and why "acked" does not mean "deleted." "Order holds on the stream, not on a re-claimed PEL entry; acked entries fold to Tigris rather than vanish" means you have it.

## §5 References & sources { id="refs" }

External:
- Redis Streams — the verbs, groups, the PEL — https://redis.io/docs/latest/develop/data-types/streams/
- Valkey — the RESP3 server EchoMQ targets — https://valkey.io/
- Danni Popova, *Replacing Kafka with Redis Streams* — this module's field reference — https://blog.arcjet.com/replacing-kafka-with-redis-streams/

Echo records:
- emq.streams.md — EchoMQ 3.0 the Stream Tier (the ladder, the small-end claim, retention, the archive) — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/echo_mq/emq.streams.md
- streams.synthesis.md — the PEL re-claim exception, F3.4-A, the fold — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/echo_mq/kb/streams-tier/streams.synthesis.md
- graft.roadmap.md — echo_graft, where the archive folds — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.roadmap.md

---

_Pager: ← Chapter III · The engines · Module 12 — EchoBus + Echo Persistence →_
