# EMQ · EchoMQ 3.0 — The Stream Tier, Specified From Its Needs

Status: **PROPOSED

## The needs, derived

BCS leaves exactly one row contested — replay for many groups — and claims its small end explicitly:
Event streams, bounded retention, a handful of groups. Walking the consumers confirms the small end is the
whole demand: Game development requires event streams, consumer group, and a
polyglot seam; recorded streams replayed, bounded by run windows, plus an archive for walk-forward depth. 
Nothing demands partition fleets, years-deep multi-team retention, or keyed compaction of a log standing in for a database —
this architecture keeps its databases (Tables, the journal, Postgres) beside the log, which is what makes compaction
a solution to someone else's problem.


- Append-only event streams.
- Consumer groups, at-least-once, a handful per stream. `XREADGROUP` / `XACK` / `XAUTOCLAIM` — group state lives with the stream.
- Bounded retention as policy | the compliance window; memory truth | `XTRIM` `MAXLEN` (approx) and `MINID` — and `MINID` is mint time, see below |
- Deep history without resident memory | the strategies' walk-forward; audit | the archive tier: stream segments folded to local CubDB and streamed to Tigris by the `EchoStore.Graft` engine — emq3.5 |
- Latest-value-per-key reads | config, positions, hydration | already built: versioned claims + Tables, newer-wins by mint order — changelog semantics without a compactor |
- Time-travel: backtests, audit, debugging - stream entry ids are millisecond-prefixed; branded mint instants map straight to `XRANGE` bounds.
- One wire, one ops posture: the whole series | RESP on the house port; Dragonfly native primary, Valkey portable secondary — both speak Streams |



- Polyglot readers - every runtime has a Redis client; claims-only payloads keep the codec trivial.

Two committed mechanics make the tier cheaper here than anywhere else. **The sequence is already minted** — every
record carries a branded id whose byte order is mint order, so stream position, sort key, claim, and cache key stay
one value (Appendix F's property extended to the log). **Latest-per-key is already law** — the staleness fence and
newer-wins admission (Chapters 4.1–4.2) give changelog reads at the read path.

## The durable-archive answer

The archive tier (emq3.5) folds trimmed stream segments into the `EchoStore.Graft` engine's local CubDB and lets the
engine stream those pages natively to Tigris S3 — one durable path, gated by one knob (`remote_cfg`), not a sidecar
bolted alongside. This supersedes the earlier Litestream/`Shadow` plan: the `EchoStore.Shadow` behaviour and its
`Copy` implementation are retired (`store.design.md` §2), the Litestream sidecar is gone, and the SQLite journal is
demoted to a rebuildable local working set — on recovery the bus's own admission dedup absorbs the ids the journal
would have replayed. Box-loss recovery is now the engine's lazy fetch of `segments/{SEG}` frames from Tigris, and the
fold being a property of the engine already in place is what makes the archive tier nearly free.

## Alignment with the active program

The 3.x ladder stands on the program's Movement 0 and is sequenced by the Operator against its ladder
([`emq.roadmap.md`](../emq.roadmap.md)): The v2 laws bind every 3.x rung unchanged — grammar-total keys,
branded ids at the builder, declared Lua keys, additive registration as a protocol minor.

## The ladder

| Rung | Ships (PROPOSED) | Stands on (as-built) | Gate sketch |
|---|---|---|---|
| emq3.1 | stream verbs gated on the connector: `XADD`, `XRANGE`, `XREADGROUP`, `XACK`, `XAUTOCLAIM` | the refereed `EchoMQ.Connector` / `EchoWire` (post-emq.0) | verb round-trips; pipelined `XADD` batch; push-safe under RESP3 |
| emq3.2 | `EchoMQ.Stream` (the writer law): per-key hash-tagged streams, branded record ids, append is mint order | Keyspace tags, the canon | append-order property: stream order == id sort, every time |
| emq3.3 | groups and the polyglot seam: a BEAM consumer and one non-BEAM reader on the same group | emq3.1–3.2 | at-least-once with idempotent handlers; crash → `XAUTOCLAIM` re-delivery; replay parity with the journal fold |
| emq3.4 | retention as policy: per-stream `MAXLEN` (approx) and mint-time `MINID` windows, declared not defaulted | emq3.2 | trim honors the window; a read inside the window never misses; outside, it answers truthfully |
| emq3.5 | the archive: a group consumer folding trimmed segments into the `EchoStore.Graft` engine (local CubDB → Tigris); deep reads = segment + live tail merge | Journal mechanics (4.4), the Graft engine (`store.design.md`) | segment fold == stream slice; box-loss restore of an archive; the merge-read property |
| emq3.6 | time-travel and hydration: mint-instant → `XRANGE` bounds; Table hydration from a stream tail (the changelog read, no compactor) | the staleness fence (4.2), Tables (4.1) | a mint-time window read equals the id-filtered truth; hydrate-then-fence equals loader truth |

Each rung is spec-triad-first under the program's loop; the numbers any rung claims will be its committed record's
numbers, and none is claimed here.

## Seams

The log-tier exit (if a real consumer someday presents large-end demand — sustained fan-out, deep retention, keyed
compaction — the log tier and only the log tier moves; the examined-and-rejected record is Appendix I, and reopening
it edits this file first); object payloads on streams (claims-only is the law; an object topic's codec is a decision
at its rung, not a default); exactly-once (not claimed — at-least-once with idempotent handlers is the posture,
gated); and the external-pipeline cache seam (a cache resource speaking the versioned-claims contract for pipeline
frameworks — relevant only past the exit, named and parked).

## Map

Delivery: the single consolidated [`emq.roadmap.md` §EchoMQ 3.x](../emq.roadmap.md). The line beneath:
[`emq2.specs.md`](emq2.specs.md) · [`emq.roadmap.md`](../emq.roadmap.md).
