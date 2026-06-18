# go — the agent-OS spec home (index)

> The spec program for the **Go MCP servers** that are the repo's local agent operating system: **`msh`**
> (memory) and **`aaw`** (task management). These are **reverse-mode** programs (code→spec): the code is
> canonical for surface facts, and the spec is derived from it and reconciled to it each rung. The build guide
> is [`go/CLAUDE.md`](../../go/CLAUDE.md); the framework the servers operationalize is [`docs/aaw/`](../aaw/);
> the fullest worked example of the workflow is [`docs/echo_mq/`](../echo_mq/).

## The two sub-programs

| Program | Server | As-built | Spec home |
|---|---|---|---|
| **`msh`** | local memory (MCP `:8899`) | `0.1.0`, 7 tools | [`msh/`](msh/) — design · roadmap · progress · features · testing · references |
| **`aaw`** | task management (MCP `:8905`) | `2.0.0-min`, 18 tools | [`aaw/`](aaw/) — as-built reverse spec; the **forward v2** design + `mcp1–8` ladder stay at [`docs/aaw/mcp/`](../aaw/mcp/) (linked, never duplicated) |

## The shared operating manual

- [`program/go.program.md`](program/go.program.md) — the Go-server gate ladder, the boundary, the reverse-mode
  discipline, the live-server caution. The build discipline lives **once** here (it is identical for both
  servers); each sub-program keeps its own design/roadmap/progress/features/testing/references.
- [`program/go.venus.md`](program/go.venus.md) · [`program/go.mars.md`](program/go.mars.md) ·
  [`program/go.apollo.md`](program/go.apollo.md) — the role calibrations for Go-server work.

## Method

- **Reverse-mode** (code canonical, spec reconciled): [`docs/aaw/aaw.reverse.md`](../aaw/aaw.reverse.md).
- **Design forks** framed in four-part arms — Rationale · 5W · Steelman · Steward — surfaced for the Operator,
  never decided by an agent: [`docs/aaw/aaw.architect-approach.md`](../aaw/aaw.architect-approach.md).
- **Voice & grounding** (plain prose, NO-INVENT, one authority): [`docs/aaw/aaw.rules.md`](../aaw/aaw.rules.md).
- **Status:** the program backbone is authored; the rung ladder is defined in each `*.roadmap.md`; per-rung
  triads are deferred to follow-on rungs (for `aaw`, the forward triads already exist at `docs/aaw/mcp/specs/`).

## Map

[`go/CLAUDE.md`](../../go/CLAUDE.md) (the build guide) · [`docs/aaw/`](../aaw/) (the framework) ·
[`docs/echo_mq/`](../echo_mq/) (the exemplar program) · the memory corpus `memory/` + the `.msh-memory.json`
anchor.
