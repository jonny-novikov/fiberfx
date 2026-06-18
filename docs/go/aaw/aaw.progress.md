# aaw MCP server — as-built progress dashboard (reverse)

> The single status view of the **aaw** Go MCP server *as it ships today* — `2.0.0-min`, **18
> tools**, file-backed, streamable HTTP at `localhost:8905`. This file **reports**; the binding
> artifacts **define** — the as-built design [`./aaw.design.md`](./aaw.design.md), the as-built
> roadmap [`./aaw.roadmap.md`](./aaw.roadmap.md), and (for the forward ladder + per-rung ship
> detail) the forward dashboard
> [`../../aaw/mcp/specs/mcp.progress.md`](../../aaw/mcp/specs/mcp.progress.md) and run ledger
> [`../../aaw/mcp/aaw.mcp.progress.md`](../../aaw/mcp/aaw.mcp.progress.md). Per-rung commit ids and
> stage detail live in the forward dashboard — **linked, not restated** (one authority per fact).
> Re-probe [`go/aaw/`](../../../go/aaw/) before trusting any figure here.

**One-line state.** The as-built server is `2.0.0-min`, serving **18 MCP tools** (7 lifecycle/registry
+ 11 `tool_x_*` ledger writers), with the per-scope single-writer store, the closed 16-code error
vocabulary, the boot/config plane, the all-or-nothing dual-stack bind, and the LAW-4 `Z`-gate all in
the tree. Against the forward `mcp1`–`mcp8` ladder it realizes the `mcp1`–`mcp4` band (mcp1–mcp3
**shipped**, mcp4 **build-grade** per the forward dashboard). The 18 → 22 tool jump and the
four-tier conformance closure are forward `mcp7`/`mcp8`.

---

## Legend

| Symbol | State | Meaning |
|---|---|---|
| ✅ | **SHIPPED** | present in the as-built tree, exercised by the gate (`selftest` / `go test`) |
| 🔨 | **IN FLIGHT** | partial in the tree, not yet gate-green |
| 📐 | **SPECCED** | forward triad authored, not in this tree |
| 📋 | **PLANNED** | forward roadmap row, triad not yet authored |
| 🔒 | **PROPOSED** | awaiting Operator ratification |

---

## As-built surface (`2.0.0-min`)

```text
aaw MCP server — module github.com/jonny-novikov/aaw · go 1.25.0 · streamable HTTP localhost:8905

Lifecycle & registry (7 tools — explicit mcp.AddTool)
  aaw_init         ✅  create / idempotently re-open a scope               cmd/aaw/main.go:369
  aaw_spawn        ✅  record a spawned agent, mint CCL-id                  cmd/aaw/main.go:385
  agent_register   ✅  register an identity (LAW-1) + FAKE-N tally          cmd/aaw/main.go:410
  agent_send       ✅  record a point-to-point message (durable log)       cmd/aaw/main.go:438
  agent_heartbeat  ✅  zero-ledger liveness touch + quiet window           cmd/aaw/main.go:452
  aaw_status       ✅  the gate console (tallies · gates · liveness)       cmd/aaw/main.go:478
  probe            ✅  health / boot surface / instance-lock holder        cmd/aaw/main.go:520

The tool_x_* ledger family (11 tools — the streams loop, cmd/aaw/main.go:539-582)
  tool_x_trace ✅ · tool_x_analyze ✅ · tool_x_alternative ✅ · tool_x_decision ✅
  tool_x_learning ✅ · tool_x_nxm_synthesize ✅ · tool_x_consensus ✅ · tool_x_escalation ✅
  tool_x_progress ✅ · tool_x_complete ✅ (LAW-4 Z-gate) · tool_x_report ✅

The planes
  store    ✅  per-scope single-writer · read-through index · atomic write   internal/store
  config   ✅  five identity flags · .aaw/config.json read-through · -wire-check  internal/config
  gates    ✅  closed 16-code vocabulary · PATH_ESCAPE containment          internal/gates
  signals  ✅  advisory FAKE-N / V-SOLO-1 / V-SOLO-2(computed) / …           internal/signals
  boot     ✅  all-or-nothing dual-stack bind · instance flock · wire check  cmd/aaw/main.go

── roll-up ──
  shipped   18 tools · the four planes · the LAW-4 Z-gate · selftest pins 18
  forward   18 → 22 at mcp7 (channels + resonance + audit); conformance closure at mcp8
```

The full `file:line` map is [`./aaw.design.md`](./aaw.design.md) §S-4; the by-feature view is
[`./aaw.features.md`](./aaw.features.md); the testing view is [`./aaw.testing.md`](./aaw.testing.md).

## Forward ladder status (linked, not restated)

The forward `mcp1`–`mcp8` rung statuses are owned by the forward dashboard
([`../../aaw/mcp/specs/mcp.progress.md`](../../aaw/mcp/specs/mcp.progress.md)) and roadmap
([`../../aaw/mcp/aaw.mcp.roadmap.md`](../../aaw/mcp/aaw.mcp.roadmap.md)). As recorded there:

| Rung | Forward status | As-built relation |
|---|---|---|
| mcp1 — single-writer store | ✅ shipped (`7972859f`) | realized in this tree |
| mcp2 — attribution + liveness + console | ✅ shipped (`f44f0539` · `514d4768`) | realized (`agent_heartbeat`, 18) |
| mcp3 — error vocabulary + grammar | ✅ shipped (`750bda97`) | realized (16-code set, EBNF) |
| mcp4 — config + ports + wire | 🔨 build-grade (D-18) | realized in this tree |
| mcp5 — `aaw reconcile` CLI | 📐 specced | not in this tree |
| mcp6 — `aaw tui` console | 📐 specced | not in this tree |
| mcp7 — channels + resonance + audit (→22) | 📋 planned | not in this tree |
| mcp8 — transport + conformance + cutover | 📋 planned | not in this tree |

> Commit ids and per-rung stage detail are the forward dashboard's — this row table is a pointer, not
> a second copy. Where this table and the forward dashboard disagree, the forward dashboard wins.

## Master invariant (held in this tree)

> **Files are truth; no loss by construction** — every durable fact in a plain file, every
> whole-file write atomic (temp + fsync + rename — `internal/store/atomic.go`), history append-only
> (`internal/store/ledger.go`), the server rebuildable from the tree at any instant. Additive-only
> tool evolution: no rung breaks a name or shape.

## Sources

- **As-built design:** [`./aaw.design.md`](./aaw.design.md) · **As-built roadmap:** [`./aaw.roadmap.md`](./aaw.roadmap.md)
- **Features / testing / references:** [`./aaw.features.md`](./aaw.features.md) ·
  [`./aaw.testing.md`](./aaw.testing.md) · [`./aaw.references.md`](./aaw.references.md)
- **Forward authority (design + ladder + ship detail):**
  [`../../aaw/mcp/aaw.mcp.design.md`](../../aaw/mcp/aaw.mcp.design.md) ·
  [`../../aaw/mcp/aaw.mcp.roadmap.md`](../../aaw/mcp/aaw.mcp.roadmap.md) ·
  [`../../aaw/mcp/specs/mcp.progress.md`](../../aaw/mcp/specs/mcp.progress.md) ·
  [`../../aaw/mcp/aaw.mcp.progress.md`](../../aaw/mcp/aaw.mcp.progress.md)
- **The framework the server enforces:** [`../../aaw/aaw.framework.md`](../../aaw/aaw.framework.md)
- **As-built source:** [`go/aaw/`](../../../go/aaw/) · the build guide [`go/CLAUDE.md`](../../../go/CLAUDE.md)
