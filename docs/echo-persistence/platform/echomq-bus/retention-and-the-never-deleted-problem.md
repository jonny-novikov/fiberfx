---
title: "Dive 11.2 — Retention & the never-deleted problem"
id: ep-m11-d2
status: established
route: "/echo-persistence/platform/echomq-bus/retention-and-the-never-deleted-problem"
kind: "module 11 · dive 11.2"
design: "html/redis-patterns sheet, re-themed amber/bronze."
pedagogy: "Taught through a unique interactive retention-window / trim-cadence SVG; no machine numbers."
grounded-in: "docs/echo_mq/emq.streams.md (emq3.4) + docs/echo_mq/kb/streams-tier/streams.synthesis.md (fork F3.4-A)"
renders-to: "platform/echomq-bus/retention-and-the-never-deleted-problem.html"
---

# Retention & the never-deleted problem { id="ep-m11-d2" }

> _A stream is a log, and `XACK` does not delete — it only clears an entry from a group's pending list. So a busy stream grows forever unless something trims it, and trimming a log is exactly where you can lose data you meant to keep. EchoMQ makes retention a declared policy, not a side effect, and it has one open design question worth seeing in motion: when do you trim?_

**Interactive figure.** A row of stream entry cells with ascending mint ids. A green fold watermark (how far the archive consumer has copied entries to durable segments) and an amber trim watermark (how far the stream has been cut) sit between cells. `XADD` appends a live cell; `fold` advances the fold watermark, archiving the next live cell; `trim` advances the trim watermark — in fold-before-trim mode it is blocked from passing the fold watermark, in trim-by-timer mode it advances regardless and any un-folded cell it cuts is marked lost.

## §1 Ack is not delete { id="never" }

The single fact behind this whole rung is that acknowledging an entry does not remove it. `XACK` clears the entry from one group's pending list; the entry itself stays in the stream, visible to `XRANGE` and to any other group, forever. That is the right default — a log you can replay is the entire point of the tier — but it means a stream that is only ever appended to is a stream that only ever grows. The control is `XTRIM`, and EchoMQ treats it as **retention-as-policy** rather than an ad-hoc call: a stream declares its window once, and the two levers are `MAXLEN ~ N` (keep approximately the last N entries; the `~` lets the server trim on macro-node boundaries, which is far cheaper than exact) and `MINID m` (drop everything below a minimum id). Because a branded id's sort order is mint order, `MINID` is also a time bound: `Snowflake.min_for/1` turns an instant into the smallest id at-or-after it, so "keep the last hour" is a `MINID` trim, no scan required. Approximate `MAXLEN` is the default and exact trimming is opt-in, because for retention "roughly the last N" is what you actually want and exactness costs you the cheap boundary. None of this changes a reader inside the window: a deep read of entries that still exist is exact; the window only governs what no longer does.

## §2 The open question: when do you trim? { id="fork" }

Trimming is safe only relative to what has been preserved elsewhere. The next rung (emq3.5) archives the trimmed tail into durable segments via the native `EchoStore.Graft` engine — the same engine Chapter III built — and the rule there is **fold-before-trim**: a dedicated fold consumer commits a slice to the archive, and only then may the stream cut up to the folded frontier. Couple the two and a trim can never remove an un-archived entry, because the trim watermark is bounded by the fold watermark by construction; that is the safe path the figure shows. The cadence of the general-purpose trim that is not the archive fold — recorded as fork **F3.4-A** — is now ruled. One option drives trimming on the consumer beat and ties the trim watermark to the fold watermark, so safety is automatic but liveness and safety are now one knob. The other gives trimming a separate, named cadence and keeps safety as an explicit precondition, on the principle that you should not couple a liveness concern (how often we trim) to a safety concern (what we are allowed to trim). The reconciliation lands on the second: emq3.4 ships the `trim` verb with its policy converged plus a named, opt-in driver (`EchoMQ.StreamRetention`) that re-applies a declared per-stream policy on its own beat — so a stream nobody drains still trims, and a stream the operator wants unbounded is simply not declared and never silently cut. The emq3.5 fold consumer is the one place that does fold-before-trim. The naive failure the figure dramatizes — a timer that advances the cut past the fold — is precisely what naming the cadence prevents.

What a trimmed slice *becomes* on disk is a separate question. The archive fold's mechanism is settled (a dedicated consumer commits each slice into the native engine before the trim is allowed to pass it), but the slice's **landing representation** — how a run of stream entries maps onto durable pages — is the open emq3.5 design question, staged for the Operator in the [`echo-bus-v3` KB](../../../echo_mq/kb/echo-bus-v3/).

## §3 References & sources { id="refs" }

Echo records:
- emq.streams.md — emq3.4 retention as policy; MAXLEN ~, MINID by mint instant — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/echo_mq/emq.streams.md
- streams.synthesis.md — fork F3.4-A, trim cadence; the Director reconciliation — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/echo_mq/kb/streams-tier/streams.synthesis.md
- graft specs / graft.4.md — the EchoStore.Graft archive the fold commits into — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/specs/graft.4.md

External:
- XTRIM — MAXLEN and MINID trimming — https://redis.io/docs/latest/commands/xtrim/
- Redis Streams — why ack does not delete — https://redis.io/docs/latest/develop/data-types/streams/

---

_Pager: ← Dive 11.1 — ValKey Streams internals · Dive 11.3 — The Stream Tier ladder →_
