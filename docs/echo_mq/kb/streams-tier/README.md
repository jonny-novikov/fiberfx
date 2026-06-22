# Stream Tier (emq3.3 → emq3.6) — design-ahead KB

A two-architect design-ahead of the **complete** EchoMQ 3.0 Stream Tier (the reader → retention → memory arc),
authored for **independent Operator review** before emq3.3's public surface freezes. Method of record:
[`aaw.architect-approach.md`](../../../aaw/aaw.architect-approach.md) (four-part arms; the multi-architect debate).

| Doc | Author | What it is |
|---|---|---|
| [`streams.design.A-consumer-lens.md`](./streams.design.A-consumer-lens.md) | Architect A | Every fork argued from the **consumer / operability** lens (the runtime that operates and consumes the tier). |
| [`streams.design.B-steward-lens.md`](./streams.design.B-steward-lens.md) | Architect B | Every fork argued from the **spec-steward / invariants** lens (the maintainer who freezes and tests the surface for years). |
| [`streams.synthesis.md`](./streams.synthesis.md) | Director | The cross-lens diff: **9/10 forks converged**, 1 diverged (F3.4-A, the trim cadence); the build-ready decision set + the consolidated recommended next actions. |

**Read order for review:** the synthesis first (the result + the one open divergence), then either lens doc for
the full four-part argument behind any fork.

**Settled this session (Operator-ruled, carried as GIVEN by both architects):** the BEAM consumer is a new
sibling `EchoMQ.StreamConsumer`; crash re-delivery is folded into its beat (`XAUTOCLAIM`); the polyglot seam is
proven by a raw-connector parity test.

**Status:** design-ahead, uncommitted, for review. No code, no canon edit — the tier's canonical ladder remains
[`emq.streams.md`](../../emq.streams.md); each rung is still spec-triad-first at its own build.
