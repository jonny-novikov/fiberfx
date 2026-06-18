# EchoWire — program progress dashboard

The rollup for the wire client-core program. The single source of truth for *scope* is
[`ewr.roadmap.md`](ewr.roadmap.md); this file tracks *status*. Legend: ✅ SHIPPED · 🔨 IN FLIGHT ·
📐 SPECCED · 📋 PLANNED · 🔒 PROPOSED (seam).

## Where the program stands

The program is **opened**: the design fork is ruled (Arm A), the canon is authored, and the founding rung
(`ewr.1.1`) is specced and ready for a build run. No rung has shipped yet.

| Rung | Slice | Status |
| --- | --- | --- |
| `ewr.1.1` | `EchoWire.Pipe` — the threaded `\|>` pipeline + curated verbs + `command/2` escape hatch | 📐 SPECCED |
| `ewr.1.2` | the command vocabulary + the immutable command value (`cf`-flag model, advisory) | 📋 PLANNED |
| `ewr.1.3` | the two-tier error split (transport vs server) | 📋 PLANNED |
| `ewr.2.x` | CLIENT TRACKING / client-side caching | 🔒 PROPOSED (may be a wire MAJOR) |

## Movements

- **Movement I · The ergonomic core** — open. `ewr.1.1` specced; `1.2` / `1.3` planned. All additive over
  `Connector.pipeline/3`; the 52-scenario conformance and the 11-verb facade stay byte-stable.
- **Movement II · Server-assisted caching** — proposed seam. Gated on a real caching consumer (`echo_store`'s
  L1) and a surfaced MAJOR fork for the `CLIENT TRACKING` boot-step.

## Decisions on the record

- **D · Arm A ruled** — the API surface is `EchoWire.Pipe` (the threaded `|>` pipeline), carried with a curated
  verb set + a `Pipe.command/2` escape hatch. Arms B (`Cmd`) and C (`Query`) chosen-against, best case kept in
  [`specs/progress/ewr-1-1.progress.md`](specs/progress/ewr-1-1.progress.md).
- **D · Additive core; caching a seam** — Movement I ports only the construction ergonomics; client-side
  caching is a named Movement II seam.

## What's next

The founding rung [`ewr.1.1`](specs/ewr.1/ewr.1.1.md) is build-ready: a later `/echo-mq-ship`-style run takes
its triad through the Flat-L2 lead-team to one ratifying commit. `ewr.1.2` / `ewr.1.3` get triads once `1.1`
ships and its as-built shape is the floor they reconcile against.

---

Roadmap: [`ewr.roadmap.md`](ewr.roadmap.md) · Features: [`ewr.features.md`](ewr.features.md) · Testing:
[`ewr.testing.md`](ewr.testing.md) · Founding rung: [`specs/ewr.1/ewr.1.1.md`](specs/ewr.1/ewr.1.1.md)
