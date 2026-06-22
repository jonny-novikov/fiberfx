# Echo Bus v3 — the platform consolidation KB (local-store · engines · platform)

A **two-architect, vision-forward consolidation** that reconciles the **Echo Platform vision**
([`docs/echo-persistence/`](../../../echo-persistence/index.md)) against the **EchoMQ bus specs**
([`emq.streams.md`](../../emq.streams.md), [`emq.design.md`](../../emq.design.md)) and the **Graft engine
as-built** ([`docs/graft/`](../../../graft/graft.roadmap.md)) — authored for **independent Operator review
before the emq3.5 (archive) build**. Its purpose is to **reframe the platform's forward development path** and
to name the `docs/echo-persistence/` manuscript edits that keep the published vision coherent with shipped
reality. Method of record: [`aaw.architect-approach.md`](../../../aaw/aaw.architect-approach.md) (the
multi-architect debate).

Two architects argued the **same forks** from divergent **vision-forward** lenses, INDEPENDENTLY (neither read
the other): **Lens A — bus-led** ("the log reaches down to the floor") and **Lens B — persistence-led** ("the
floor rises to carry the log"). The Director **stages** their disagreement (does not average it).

## The KB, chapter by chapter

The three chapters map 1:1 onto the manuscript's Chapters II / III / IV. Each chapter folder holds the two
lens perspectives + the Director's synthesis (its cross-lens diff + report).

| Chapter | Lens A (bus-led) | Lens B (persistence-led) | Director synthesis |
|---|---|---|---|
| **local-store** (CubDB · MVCC · replay) | [`A-lens.md`](./local-store/A-lens.md) | [`B-lens.md`](./local-store/B-lens.md) | [`synthesis.md`](./local-store/synthesis.md) |
| **engines** (native Graft · Rust · Tigris+fence · BEAM↔Rust) | [`A-lens.md`](./engines/A-lens.md) | [`B-lens.md`](./engines/B-lens.md) | [`synthesis.md`](./engines/synthesis.md) |
| **platform** (Stream Tier · bus+persistence · the door to BCS) | [`A-lens.md`](./platform/A-lens.md) | [`B-lens.md`](./platform/B-lens.md) | [`synthesis.md`](./platform/synthesis.md) |

**The cross-chapter rollup:** [`echo-bus-v3.consolidated.md`](./echo-bus-v3.consolidated.md) — the convergence
map across all ten forks, the **ADR matrix** (anchored on the existing `emq.design.md` S-n / DQ-n decisions),
the **reframed development path** (the one meta-axis the Operator rules), and the unified
`docs/echo-persistence/` reconciliation changeset.

## Read order for review

The [`consolidated.md`](./echo-bus-v3.consolidated.md) first (the result + the reframed path + the ADR matrix),
then any chapter `synthesis.md` for the cross-lens diff, then either lens doc for the full four-part argument
behind a fork.

## The result in one line

**Ten forks → six CONVERGED, four DIVERGED.** The six convergences are the **complete emq3.5 build surface**
(the archive lands as a reserved-range page index, into the native `EchoStore.Graft` via `commit/3`, by a
store-side fold consumer, merge-read on an engine-derived watermark `W`). The four divergences collapse onto
**one meta-axis** — *bus-as-spine (keep boundaries, finish the frontier) vs engine-as-substrate (unify onto the
floor, deepen toward ADR-A)* — which **is the reframed development path** the Operator is asked to rule. It does
not block emq3.5.

## Settled this session (GIVEN to both architects)

The dependency direction `echo_store → echo_mq` (so the fold-consumer lives store-side); the native
`EchoStore.Graft` is COEXIST-canonical and UNTOUCHED; eg.6 is DEFERRED (behind a fly.io deploy floor), the live
frontier is the bus rung emq3.5; the streams-tier KB's emq3.3/3.4 forks are RULED (both rungs shipped).

## Inputs reconciled

`docs/echo-persistence/**` (the vision, `status: established`) · the bus canon
([`emq.streams.md`](../../emq.streams.md) · [`emq.design.md`](../../emq.design.md) ·
[`emq.roadmap.md`](../../emq.roadmap.md)) · the Graft as-built ([`docs/graft/`](../../../graft/graft.roadmap.md)
+ `echo/apps/echo_store/lib/echo_store/graft/**`) · the prior design-ahead
[`kb/streams-tier/`](../streams-tier/README.md) (the template + RULED F3.5-A/B).

## Status

**Consolidation, uncommitted, for review.** No `echo/apps/**` code, no bus-canon body edited — the KB
**extends** the `emq.design.md` S-1..S-7 / DQ-1..DQ-4 set, it does not duplicate it. The
`docs/echo-persistence/` manuscript edits this KB proposes are named in
[`consolidated.md`](./echo-bus-v3.consolidated.md) §6 and applied surgically by the Director; the bus-canon
syncs there are recommended for the Operator, not applied by this phase. Each rung named here remains
spec-triad-first at its own build.
