# aaw (reverse) — rung-triad index

> The rung ladder for the **aaw** server lives in [`../aaw.roadmap.md`](../aaw.roadmap.md). The
> per-rung triads are **not duplicated here** — they are the forward `mcp1`–`mcp8` triads at
> [`../../../aaw/mcp/specs/`](../../../aaw/mcp/specs/), the authority for every rung's spec, stories,
> and brief. This directory is the reverse spec's triad slot; it links the forward triads rather than
> re-owning them (one authority per fact).

## Where the triads are

The binding per-rung triads (each `mcpN.md` + `mcpN.stories.md` + `mcpN.llms.md`, with
`mcp1.prompt.md` an as-run runbook):

- The chapter index over them: [`../../../aaw/mcp/specs/mcp.md`](../../../aaw/mcp/specs/mcp.md).
- The triads themselves: [`../../../aaw/mcp/specs/`](../../../aaw/mcp/specs/) — `mcp1`…`mcp6`
  authored; `mcp7`/`mcp8` are roadmap rows in
  [`../../../aaw/mcp/aaw.mcp.roadmap.md`](../../../aaw/mcp/aaw.mcp.roadmap.md).

## How the as-built tree maps to the ladder

`2.0.0-min` (18 tools) realizes the forward `mcp1`–`mcp4` band — see the rung table in
[`../aaw.roadmap.md`](../aaw.roadmap.md) for the per-rung as-built relation, and
[`../aaw.design.md`](../aaw.design.md) for the as-built surface each rung's code holds. The
18 → 22 tool jump and the conformance closure are forward `mcp7`/`mcp8`.

## Why no triads live here

This is a **reverse (code→spec)** documentation tree. The forward triads already define every rung;
restating them here would create a drift surface the framework's one-authority law forbids
([`../../../aaw/aaw.framework.md`](../../../aaw/aaw.framework.md), Values). The reverse spec's job is
to record the as-built surface ([`../aaw.design.md`](../aaw.design.md)) and **link** the forward plan,
not to fork it.
