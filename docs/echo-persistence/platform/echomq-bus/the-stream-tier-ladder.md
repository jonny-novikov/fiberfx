---
title: "Dive 11.3 — The Stream Tier ladder"
id: ep-m11-d3
status: established
route: "/echo-persistence/platform/echomq-bus/the-stream-tier-ladder"
kind: "module 11 · dive 11.3 (closes the bus arc)"
design: "html/redis-patterns sheet, re-themed amber/bronze."
pedagogy: "Taught through a unique interactive archive merge-read SVG; no machine numbers."
grounded-in: "docs/echo_mq/emq.streams.md (emq3.1–3.6) + docs/echo_mq/kb/streams-tier/streams.synthesis.md"
renders-to: "platform/echomq-bus/the-stream-tier-ladder.html"
---

# The Stream Tier ladder { id="ep-m11-d3" }

> _EchoMQ 3.0 is not a rewrite; it is six small rungs that add a log tier beside the job tier, each shipping under the same wire. The reason it is cheap to build is that the two hardest pieces already exist from Chapter IV: the sequence is already minted (a branded id's byte order is its mint order) and latest-per-key is already law (the staleness fence plus newer-wins). What is left is mostly naming where order holds._

**Interactive figure.** Two horizontal bands aligned by mint id: the top is the live stream tail, the bottom is durable segments in object storage. Each id column has a cell in exactly one band — ids below the watermark `W` are segments, ids at or above `W` are the live tail. `XADD` appends a cell to the tail; `fold + trim` advances `W`, moving one column down to segments; a `deep read` across `W` highlights the segment portion and the tail portion, which concatenate with no gap or overlap.

## §1 Six rungs, one wire { id="ladder" }

The verbs register as an **additive minor** on `EchoMQ.Connector` — the same connector that carries jobs — so a deployment can mix an old job-only node and a new stream-aware node on the same bus (`echomq:2.6.x`); only the eventual `echomq:3.0.0` is a major, and that cutover is deliberately deferred because a shared fence-climb would brick co-tenants. The order theorem underwrites everything: a stream's order is the branded-id sort, which is the mint order, with one named exception — a re-claimed pending entry returns out of real-time order, so the spec says exactly where order holds (the stream) and where it does not (re-claim).

- **emq3.1** — The verbs: `XADD` / `XRANGE` / `XREADGROUP` / `XACK` / `XAUTOCLAIM` registered as a no-break minor. Shipped.
- **emq3.2** — The writer law: hash-tagged streams, branded ids, `append == mint` so byte order is time order. Shipped.
- **emq3.3** — Readers: consumer groups + a polyglot handler; at-least-once, idempotent. Shipped.
- **emq3.4** — Retention as policy: `MAXLEN ~` / `MINID` by mint instant; the cadence fork F3.4-A ruled (Dive 11.2). Shipped.
- **emq3.5** — The archive (next): a fold consumer commits trimmed slices to native `EchoStore.Graft`, fold-before-trim; the merge-read below.
- **emq3.6** — Time travel: a mint-instant becomes a half-open `XRANGE [dt1,dt2)` via `Snowflake.min_for/1`; a Table hydrates from the tail as a changelog read, no compactor.

Two committed mechanics make the climb cheap rather than novel. The **sequence is already minted**: because every record carries a branded Snowflake whose bytes sort in creation order, the stream needs no separate sequence and "keep the last hour" is a key comparison, not a scan. And **latest-per-key is already law**: the staleness fence and newer-wins from Chapter IV mean a changelog-style read already resolves to the current value without a background compactor. The three delivery milestones — S1 the writer, S2 the readers, S3 the memory tier — are just the order in which these land.

## §2 One log, two homes { id="merge" }

The archive rung is where the bus and the engine you built finally meet. A dedicated fold `StreamConsumer` commits trimmed slices to the native `EchoStore.Graft` store via `commit/3`, and the engine streams those pages from CubDB out to Tigris — the same durable floor Chapter III's engines lean on, which is why this supersedes the older external-replication idea (Litestream / the retired `Shadow` store) entirely. The merge-read is the payoff. Define the watermark **`W`** as the branded id of Graft's folded frontier: everything below `W` has been folded to segments, everything at or above `W` is still in the live stream. A deep read of a range is then segments below `W` concatenated with the live tail at or above `W` — and there is provably no gap and no overlap at the seam, because fold-before-trim guarantees nothing is trimmed until it is folded (so nothing falls between the two homes) and the order theorem guarantees both halves sort by the same mint order (so the seam is exactly `W`). emq3.6 builds straight on this: a time window is a pair of mint instants, so a historical read is a half-open `XRANGE` over the merged log, and a Table rebuilt from the tail is just a changelog read resolved by the latest-per-key law — no compaction step anywhere. The course closes where it began: durability is one ordered log, and the only question is whether a given entry currently lives in memory or in object storage.

## §3 References & sources { id="refs" }

Echo records:
- emq.streams.md — the emq3.1–3.6 ladder, the writer law, the merge-read, time travel — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/echo_mq/emq.streams.md
- streams.synthesis.md — the order theorem, the two committed mechanics, the milestones — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/echo_mq/kb/streams-tier/streams.synthesis.md
- graft specs / graft.4.md — EchoStore.Graft, the archive the fold commits into — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/specs/graft.4.md

External:
- Redis Streams — XRANGE, the log model — https://redis.io/docs/latest/develop/data-types/streams/
- Snowflake ID — time-ordered ids, the mint-instant bound — https://en.wikipedia.org/wiki/Snowflake_ID

---

_Pager: ← Dive 11.2 — Retention & the never-deleted problem · Module 12 — EchoBus + Echo Persistence →_
