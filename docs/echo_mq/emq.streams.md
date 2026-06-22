# EchoMQ 3.0 — The Stream Tier

**Status: 📨 ACTIVE / NEXT** — the active next-major delivery, **re-sequenced ahead of the 2.x-runway
remainder (Operator-ruled 2026-06-22)**. Gated on `emq.0` ONLY (met); `emq3.1`–`emq3.4` SHIPPED, `emq3.5` is next. This is the
high-level spec; each rung is still spec-triad-first under the program loop, and no number is claimed
here before its rung commits it.

## Version plane

The tier ships **additive-minor**: the stream verbs (`XADD` / `XRANGE` / `XREADGROUP` / `XACK` /
`XAUTOCLAIM`) are additive registrations → a protocol **MINOR** by the additive-registration law (no
wire break), each landing WITH its conformance probe. The `mix.exs` rung label continues additively
(`echomq:2.5.2` live → `2.6.x` → …). The **`echomq:3.0.0` MAJOR is a DEFERRED cutover ratification** —
declared when the tier is whole, not forced at `emq3.1` — per the established defer-the-fence-cutover
pattern (the shared `:6390` fence-climb bricks co-tenants and the version number is contested, so an
additive rung defaults to NO climb).

## The needs, derived

The BCS architecture leaves exactly one row contested — *replay for many groups* — and claims its
small end explicitly: **event streams, bounded retention, a handful of groups per stream.** Walking
the real consumers confirms that small end is the whole demand — game development wants recorded
event streams, a consumer group, and a polyglot seam: streams replayed, bounded by run windows, plus
an archive for walk-forward depth. Nothing demands partition fleets, years-deep multi-team retention,
or keyed compaction of a log standing in for a database — this architecture keeps its databases
(Tables, the journal, Postgres) *beside* the log, which is exactly what makes compaction someone
else's problem.

What the tier must answer:

- **Append-only event streams** on one wire, one ops posture (RESP on the house port).
- **Consumer groups** — at-least-once, a handful per stream (`XREADGROUP` / `XACK` / `XAUTOCLAIM`;
  group state lives with the stream).
- **Bounded retention as policy** — the compliance window and memory truth, via `XTRIM` `MAXLEN`
  (approx) and `MINID` (mint time).
- **Deep history without resident memory** — stream segments folded to local CubDB and streamed to
  Tigris by the `EchoStore.Graft` engine (emq3.5).
- **Latest-value-per-key reads** (config, positions, hydration) — *already built*: versioned claims +
  Tables, newer-wins by mint order — changelog semantics without a compactor.
- **Time-travel** (backtests, audit, debugging) — entry ids are millisecond-prefixed, so branded mint
  instants map straight to `XRANGE` bounds.
- **Polyglot readers** — every runtime has a Redis client; claims-only payloads keep the codec trivial.

**Two committed mechanics make this tier cheaper here than anywhere else.** *The sequence is already
minted* — every record carries a branded id whose byte order is mint order, so stream position, sort
key, claim, and cache key stay one value (Appendix F's property extended to the log). *Latest-per-key
is already law* — the staleness fence + newer-wins admission (Chapters 4.1–4.2) give changelog reads
at the read path.

## The durable-archive answer

The archive tier (emq3.5) folds trimmed stream segments into the `EchoStore.Graft` engine's local
CubDB and lets the engine stream those pages natively to Tigris S3 — **one durable path, one knob
(`remote_cfg`)**, not a sidecar. This supersedes the earlier Litestream/`Shadow` plan: the
`EchoStore.Shadow` behaviour is retired (`store.design.md` §2), the Litestream sidecar is gone, and
the SQLite journal is demoted to a rebuildable local working set (on recovery the bus's own admission
dedup absorbs the ids the journal would have replayed). Box-loss recovery is the engine's lazy fetch
of `segments/{SEG}` frames from Tigris — and the fold being a property of the engine already in place
is what makes the archive nearly free.

## The ladder

Six rungs, three milestones. The v2 laws bind every 3.x rung **unchanged** — grammar-total keys,
branded ids at the builder, declared Lua keys, additive registration as a protocol minor.

| Rung | Ships (PROPOSED) | Stands on (as-built) | Gate sketch |
|---|---|---|---|
| **emq3.1** | stream verbs on the connector: `XADD`, `XRANGE`, `XREADGROUP`, `XACK`, `XAUTOCLAIM` | the refereed `EchoMQ.Connector` / `EchoWire` (post-emq.0) | verb round-trips; pipelined `XADD` batch; push-safe under RESP3 |
| **emq3.2** | `EchoMQ.Stream` (the writer law): per-key hash-tagged streams, branded record ids, append == mint order | Keyspace tags, the canon | append-order property: stream order == id sort, every time; wrong-kind refused at the door |
| **emq3.3** | groups + the polyglot seam: a BEAM consumer and one non-BEAM reader on the same group | emq3.1–3.2 | at-least-once with idempotent handlers; crash → `XAUTOCLAIM` re-delivery; replay parity with the journal fold |
| **emq3.4** | retention as policy: per-stream `MAXLEN` (approx) and mint-time `MINID` windows, declared not defaulted | emq3.2 | trim honors the window; a read inside the window never misses; outside, it answers truthfully |
| **emq3.5** | the archive: a group consumer folding trimmed segments into the `Graft` engine (CubDB → Tigris); deep reads = segment + live-tail merge | journal mechanics (BCS 4.4), the `Graft` engine (`store.design.md`) | segment fold == stream slice; box-loss restore; the merge-read property |
| **emq3.6** | time-travel + hydration: mint-instant → `XRANGE` bounds; Table hydration from a stream tail (the changelog read, no compactor) | the staleness fence (BCS 4.2), Tables (4.1) | a mint-time window read equals the id-filtered truth; hydrate-then-fence equals loader truth |

**Milestones:** **S1 · the writer** (emq3.1–3.2) — append to a hash-tagged stream through the
certified connector and read it back in mint order, the append-order property gated. **S2 · the
readers** (emq3.3–3.4) — a BEAM consumer group beside a non-BEAM reader with crash re-delivery, and a
declared retention window the trim provably honors. **S3 · the memory** (emq3.5–3.6) — fold trimmed
segments into the `Graft` engine, survive box loss, merge-read segment plus tail, and answer a
mint-time window query from either.

## Seams

- **The log-tier exit** — if a real consumer ever presents large-end demand (sustained fan-out, deep
  retention, keyed compaction), the log tier *and only* the log tier moves; the examined-and-rejected
  record is BCS Appendix I, and reopening it edits this file first.
- **Object payloads on streams** — claims-only is the law; an object topic's codec is a decision at
  its rung, not a default.
- **Exactly-once** — not claimed; at-least-once with idempotent handlers is the gated posture.
- **The external-pipeline cache seam** — a cache resource speaking the versioned-claims contract for
  pipeline frameworks; relevant only past the exit, named and parked.

## Map

The forward plan: [`emq.roadmap.md` §EchoMQ 3.0](./emq.roadmap.md) · the progress dashboard:
[`emq.progress.md`](./emq.progress.md). The line beneath: the design canon
[`emq.design.md`](./emq.design.md) (the 2.x line) · the store engine
[`store/design/store.design.md`](./store/design/store.design.md).
