# EchoWire — program progress dashboard

The rollup for the wire client-core program. The single source of truth for *scope* is
[`ewr.roadmap.md`](ewr.roadmap.md); this file tracks *status*; shipped deliverables are in the bus
[changelog](../emq.changelog.md). Legend: ✅ BUILT · 🔨 IN FLIGHT · 📐 SPECCED · 📋 PLANNED · 🔒 PROPOSED.

## Where the program stands

**Movement I is COMPLETE** — the ergonomic core shipped across four rungs (`ewr.1.1`–`ewr.1.4`, all
BUILT, Director-verified). The wire stays above the conformance boundary (the count is emq-owned and
byte-stable); `ewr.1.4` established the **version-reflection rule** — `echo_wire` ⟺ the connector
`@wire_version` ⟺ `echo_mq` are one number (`echomq:2.4.2` live). Movement II (server-assisted caching) is
**RESOLVED** — shipped as `echo_store`'s `:tracking` coherence mode (not a wire rung; the once-feared wire
MAJOR was demoted to a deferred optimization).

| Rung | Slice | Status |
| --- | --- | --- |
| `ewr.1.1` | `EchoWire.Pipe` — the threaded `\|>` pipeline + curated verbs + `command/2` escape hatch | ✅ BUILT |
| `ewr.1.2` | the command vocabulary + the immutable command value (`cf`-flag model, advisory) | ✅ BUILT |
| `ewr.1.3` | the two-tier error split (transport vs server) | ✅ BUILT |
| `ewr.1.4` | adopt `EchoWire.Pipe` into `echo_mq`'s internals — the Movement I closer | ✅ BUILT |
| `ewr.2.x` | CLIENT TRACKING / client-side caching | ✅ RESOLVED — shipped as `echo_store` `:tracking` (not a wire rung) |

## Movements

- **Movement I · The ergonomic core** — ✅ COMPLETE. `EchoWire.{Pipe, Cmd, Command, Result}` shipped,
  all additive over `Connector.pipeline/3`; the conformance count and the 11-verb facade stay byte-stable.
- **Movement II · Server-assisted caching** — ✅ RESOLVED (2026-06-18). Built as `echo_store`'s `:tracking`
  coherence mode, **not a wire rung**: the connector already delivers invalidation pushes, so no
  frozen-connector boot-step was needed; reconnect is flush-then-re-arm. See
  [`../store/store.tracking.md`](../store/store.tracking.md).

## Decisions on the record

- **D · Arm A ruled** — the API surface is `EchoWire.Pipe` (the threaded `|>` pipeline), carried with a
  curated verb set + a `Pipe.command/2` escape hatch. Arms B (`Cmd`) and C (`Query`) chosen-against.
- **D · Additive core; caching a seam** — Movement I ported only the construction ergonomics; client-side
  caching is a named Movement II seam.

## What's next

Movement I is closed and Movement II is resolved in `echo_store` — the wire client-core program is
**complete**. Per-rung deliverables: the bus [changelog](../emq.changelog.md).

---

Roadmap: [`ewr.roadmap.md`](ewr.roadmap.md) · Features: [`ewr.features.md`](ewr.features.md) · Testing:
[`ewr.testing.md`](ewr.testing.md) · Changelog: [`../emq.changelog.md`](../emq.changelog.md)
