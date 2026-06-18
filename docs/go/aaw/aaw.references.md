# aaw MCP server — references

> Every source the as-built reverse spec of the **aaw** server stands on: the AAW framework documents
> it operationalizes, the forward v2 canon it reconciles to, the as-built code it derives from, and
> the external protocol/runtime specs. One authority per fact — this file points; it does not re-own.

---

## I · The AAW framework (what the server operationalizes)

- **The framework definition** — [`../../aaw/aaw.framework.md`](../../aaw/aaw.framework.md): the
  Operator/Agent model, the four artifacts, the six-stage loop, the two directions. The aaw server is
  "the machine for the framework" — it records and enforces this process.
- **The rules of the game** — [`../../aaw/aaw.rules.md`](../../aaw/aaw.rules.md): the roles and
  fences, the LAWS (LAW-1…LAW-4 — the server enforces the LAW-4 `Z`-gate), the gates, the delta
  taxonomy, and the **Voice** rule this document obeys (plain specific prose, no first person, no
  perceptual/interior-state verbs for software).
- **The reverse playbook** — [`../../aaw/aaw.reverse.md`](../../aaw/aaw.reverse.md): the code→spec
  discipline this reverse spec follows — the code is canonical for surface facts, every cited surface
  verified at its source, every invariant mapped to a running check; the added gates (grounding,
  no-invent, exact-arity, file:line-resolves).
- **The architect's approach** — [`../../aaw/aaw.architect-approach.md`](../../aaw/aaw.architect-approach.md):
  the four-part arm (Rationale · 5W · Steelman · Steward) for a genuine fork. No fork is open in this
  as-built tree ([`./aaw.design.md`](./aaw.design.md) §S-11); the server's design forks were ruled
  forward and are recorded there.

## II · The forward v2 canon (the design of record — linked, never duplicated)

The **forward authority** for this server. This reverse spec reconciles the as-built `2.0.0-min`
(18 tools) to this canon (the 22-tool target) and links it for all rationale and the unbuilt
remainder.

- **The forward design of record** — [`../../aaw/mcp/aaw.mcp.design.md`](../../aaw/mcp/aaw.mcp.design.md):
  the 22-tool surface, the 14 architecture decisions (AD-1…AD-12), the master invariant, the closed
  error vocabulary, the §8 ledger grammar (EBNF), the four-tier conformance plan (§11), the decision
  record (§13).
- **The forward delivery roadmap** — [`../../aaw/mcp/aaw.mcp.roadmap.md`](../../aaw/mcp/aaw.mcp.roadmap.md):
  the `mcp1`–`mcp8` build ladder, the milestones, the seams & open decisions.
- **The chapter index** — [`../../aaw/mcp/specs/mcp.md`](../../aaw/mcp/specs/mcp.md): the map over the
  per-rung triads.
- **The per-rung triads** — [`../../aaw/mcp/specs/`](../../aaw/mcp/specs/): `mcp1`…`mcp6`
  (`mcpN.md` + `mcpN.stories.md` + `mcpN.llms.md`; `mcp1` adds `mcp1.prompt.md`); `mcp7`/`mcp8` are
  roadmap rows.
- **The forward dashboards** — the implementation dashboard
  [`../../aaw/mcp/specs/mcp.progress.md`](../../aaw/mcp/specs/mcp.progress.md) and the run ledger
  [`../../aaw/mcp/aaw.mcp.progress.md`](../../aaw/mcp/aaw.mcp.progress.md): per-rung stage, commit
  ids, the binding decisions (D-n, L-n).

## III · The as-built source (what this spec derives from)

Module `github.com/jonny-novikov/aaw` (`go 1.25.0`,
`replace github.com/fiberfx/mcp-go/v2 => ../mcp-go`), version `2.0.0-min`.

- **Entry + tool registration** — [`go/aaw/cmd/aaw/main.go`](../../../go/aaw/cmd/aaw/main.go): the
  five flags, the 18-tool registration, the `serve` / `selftest` modes, the all-or-nothing bind, the
  wire check.
- **The store** — [`go/aaw/internal/store/`](../../../go/aaw/internal/store/): `store.go` (scope
  index, per-scope serialization), `atomic.go` (temp+fsync+rename), `ledger.go` (the
  `<scope>.progress.md` channel ledger + the LAW-4 `Z`-gate + the §8 EBNF), `lock.go` (the instance
  flock).
- **The config plane** — [`go/aaw/internal/config/`](../../../go/aaw/internal/config/): the identity
  flags, the `.aaw/config.json` read-through, the wire-check verdict.
- **The gate plane** — [`go/aaw/internal/gates/`](../../../go/aaw/internal/gates/): the closed 16-code
  vocabulary, the `Contained(root, path)` PATH_ESCAPE predicate.
- **The signal plane** — [`go/aaw/internal/signals/`](../../../go/aaw/internal/signals/): the advisory
  signal set, the V-SOLO computations, the dedup audit-log emitter.
- **The vendored SDK fork** — [`go/mcp-go/`](../../../go/mcp-go/) (module
  `github.com/fiberfx/mcp-go/v2`): first-party, modifiable as a designed change (the forward D-5
  seam).
- **The build guide** — [`go/CLAUDE.md`](../../../go/CLAUDE.md): the `GOWORK=off` hermetic build/test
  rule, the flags-before-mode quirk.
- **The shared Go-server operating manual** — [`../program/go.program.md`](../program/go.program.md).

## IV · External protocol & runtime specifications

- **MCP — Streamable HTTP transport** — the wire the server serves over (`mcp.NewStreamableHTTPHandler`):
  <https://modelcontextprotocol.io/specification/2025-06-18/basic/transports>.
- **The Model Context Protocol** — the tool/JSON-RPC contract the SDK implements:
  <https://modelcontextprotocol.io/>.
- **Go `flag` package** — the `flag.Parse` stop-at-first-non-flag behavior behind the
  flags-before-mode rule: <https://pkg.go.dev/flag>.
- **`flock(2)`** — the advisory file lock behind the per-workspace instance guard:
  <https://man7.org/linux/man-pages/man2/flock.2.html>.

---

## Map

- The as-built design / roadmap / progress / features / testing: [`./aaw.design.md`](./aaw.design.md) ·
  [`./aaw.roadmap.md`](./aaw.roadmap.md) · [`./aaw.progress.md`](./aaw.progress.md) ·
  [`./aaw.features.md`](./aaw.features.md) · [`./aaw.testing.md`](./aaw.testing.md).
- The rung-triad index: [`./specs/README.md`](./specs/README.md).
