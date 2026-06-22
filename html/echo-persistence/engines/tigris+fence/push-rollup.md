---
title: "Push rollup"
id: ep-m9-d1
status: established
route: "/echo-persistence/engines/tigris+fence/push-rollup"
kind: "module 9 · dive 9.1"
design: "html/redis-patterns sheet, re-themed amber/bronze."
pedagogy: "Taught through a unique interactive dedup-to-segment SVG; no machine numbers."
renders-to: "engines/tigris+fence/push-rollup.html"
---

# Push rollup { id="ep-m9-d1" }

> _Between uploads, a Volume may write the same page many times. Pushing every write would mean a storm of tiny objects, most immediately stale. So before upload the engine rolls up: it keeps only the latest version of each changed page, frames the result with Zstd, and writes one segment._

**Interactive figure.** On the left, a write log of page writes accumulates, with superseded writes dimmed. In the center, a rollup map shows one row per distinct page holding its latest version, updating as writes arrive. Rolling up produces a single Zstd segment on the right listing the latest version of each page, and clears the write log — so a burst of writes collapses to one object.

## §1 Many writes, one segment { id="rollup" }

Press write a few times — some pages repeat at higher versions, dimming the older writes — and the rollup map keeps only the latest of each. Roll up and the changed pages become one Zstd segment, uploaded with a single PUT; the write log clears. The segment's size is the count of distinct changed pages, not the number of writes.

## §2 Why coalesce before the wire { id="why" }

Object stores reward few large writes and punish many small ones — each PUT has fixed overhead and the fence costs a round trip. Rolling up turns a burst of page writes into a single segment whose size is the count of distinct changed pages, because a page written five times only needs its final version on the wire. Zstd then frames that segment so the bytes are compact. The effect compounds with the engines you have seen: the native engine's commit-log outbox (Module 7) and the Rust engine's flushes both push rollups, so a hot page that changes constantly still costs one page slot per upload, not one per change. The deduped, framed segment is exactly what a replica pulls (Module 6) and what recovery faults (Dive 9.3) — one object, latest versions only. Next, how that upload is made safe when more than one writer is involved.

## §3 References & sources { id="refs" }

External:
- orbitinghail/graft — page-set rollup, segment upload — https://github.com/orbitinghail/graft
- Zstandard — framing and compression — https://facebook.github.io/zstd/
- Write amplification — why fewer, larger writes win — https://en.wikipedia.org/wiki/Write_amplification

Echo records:
- graft specs / graft.2.md — eg.2 — segments on the remote — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/specs/graft.2.md
- graft.roadmap.md — eg.2 — segments, the remote write path — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.roadmap.md
- graft.design.md — push rollup, dedupe, Zstd segments — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.design.md
- store.design.md — changed-page set, segment framing — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/echo_mq/store/design/store.design.md

---

_Pager: ← Tigris & the fence · Dive 9.2 — The create-if-not-exists fence →_
