# aaw MCP server — the as-built roadmap (reverse)

> The delivery view of the **aaw** Go MCP server as it stands today (`2.0.0-min`, 18 tools) and the
> ladder that carries it to the v2 target (22 tools). This file **plans by linking**: the binding
> build ladder is the forward [`mcp1`–`mcp8`](../../aaw/mcp/aaw.mcp.roadmap.md) ladder under
> [`docs/aaw/mcp/`](../../aaw/mcp/), and the per-rung triads live at
> [`docs/aaw/mcp/specs/`](../../aaw/mcp/specs/). This document never restates those rungs — it gives
> one row each pointing at the real file, marks what `2.0.0-min` already realizes, and names the
> remainder forward-tense. **One authority per fact:** the forward roadmap is the authority for the
> ladder; this is the as-built reconcile.

Canon: the forward roadmap [`../../aaw/mcp/aaw.mcp.roadmap.md`](../../aaw/mcp/aaw.mcp.roadmap.md) ·
the forward design [`../../aaw/mcp/aaw.mcp.design.md`](../../aaw/mcp/aaw.mcp.design.md) ·
the chapter index [`../../aaw/mcp/specs/mcp.md`](../../aaw/mcp/specs/mcp.md) ·
the implementation dashboard [`../../aaw/mcp/specs/mcp.progress.md`](../../aaw/mcp/specs/mcp.progress.md).
The as-built design: [`./aaw.design.md`](./aaw.design.md). Source: [`go/aaw/`](../../../go/aaw/).

---

## The epic

**One server, two views: the as-built `2.0.0-min` and the forward v2 ladder that completes it.**

- **Why.** The aaw server is the machine for the AAW framework — it records and enforces process,
  runs no agents, makes no commits ([`../../aaw/aaw.framework.md`](../../aaw/aaw.framework.md)). It
  ships today as `2.0.0-min` and is being driven to the approved v2 design through a thin-rung
  ladder. This reverse roadmap exists so the as-built surface has a spec home that **links** the
  forward plan rather than forking it.
- **What.** [`go/aaw/`](../../../go/aaw/) (module `github.com/jonny-novikov/aaw`, `go 1.25.0`,
  `replace github.com/fiberfx/mcp-go/v2 => ../mcp-go`) — the file-backed process engine serving 18
  MCP tools over streamable HTTP at `localhost:8905`. The forward target is a 22-tool surface with
  the four-tier conformance suite green.
- **Who.** The Operator owns the goal and every fork; the aaw lead team ships the rungs (the forward
  ladder runs the tiered formation — settled / standard / full). The server's own consumers are the
  AAW formations that dial its tools.
- **When.** As built, the tree realizes the forward `mcp1`–`mcp4` band — mcp1–mcp3 **shipped**, mcp4
  **build-grade** ([`../../aaw/mcp/specs/mcp.progress.md`](../../aaw/mcp/specs/mcp.progress.md)). The
  remainder (`mcp5`–`mcp8`) is specced/planned and carries the 18 → 22 jump.
- **Where.** Code: [`go/aaw/`](../../../go/aaw/) (`cmd/aaw/`, `internal/{config,gates,signals,store}`).
  Forward specs: [`docs/aaw/mcp/`](../../aaw/mcp/). This reverse view: [`docs/go/aaw/`](.).

## The as-built surface (where this tree stands)

`2.0.0-min` serves **18 tools** — the count `selftest` pins over the live wire
(`cmd/aaw/main.go:778`):

- **Lifecycle & registry (7):** `aaw_init` · `aaw_spawn` · `agent_register` · `agent_send` ·
  `agent_heartbeat` · `aaw_status` · `probe`.
- **The `tool_x_*` ledger family (11):** `tool_x_trace` · `tool_x_analyze` · `tool_x_alternative` ·
  `tool_x_decision` · `tool_x_learning` · `tool_x_nxm_synthesize` · `tool_x_consensus` ·
  `tool_x_escalation` · `tool_x_progress` · `tool_x_complete` · `tool_x_report`.

The full per-tool `file:line` map is [`./aaw.design.md`](./aaw.design.md) §S-4; the by-feature view
is [`./aaw.features.md`](./aaw.features.md).

## The rung ladder (links the forward triads — one row each, never restated)

The binding ladder is the forward `mcp1`–`mcp8` ([`../../aaw/mcp/aaw.mcp.roadmap.md`](../../aaw/mcp/aaw.mcp.roadmap.md)).
Each row below points at the real triad under [`docs/aaw/mcp/specs/`](../../aaw/mcp/specs/) and marks
how the as-built `2.0.0-min` relates to it. Status legend below.

| Rung | Ships (the slice) | Tool count after | As-built relation | Triad |
| --- | --- | --- | --- | --- |
| **mcp1** | the single-writer store discipline (per-scope serialization, persisted `next_ccl`, atomic temp+fsync+rename, the read-through index, the boot flock) | 17 | ✅ **realized** in this tree (`internal/store`) | [`mcp1.md`](../../aaw/mcp/specs/mcp1.md) · [`.stories`](../../aaw/mcp/specs/mcp1.stories.md) · [`.llms`](../../aaw/mcp/specs/mcp1.llms.md) · [`.prompt`](../../aaw/mcp/specs/mcp1.prompt.md) |
| **mcp2** | attribution, liveness & the `aaw_status` gate console (+`agent_heartbeat`) | 18 | ✅ **realized** (`agent_heartbeat` present; `internal/signals`) | [`mcp2.md`](../../aaw/mcp/specs/mcp2.md) · [`.stories`](../../aaw/mcp/specs/mcp2.stories.md) · [`.llms`](../../aaw/mcp/specs/mcp2.llms.md) |
| **mcp3** | the closed error vocabulary + the §8 ledger-grammar formalization | 18 | ✅ **realized** (`internal/gates`, the 16-code set; `internal/store/ledger.go` EBNF) | [`mcp3.md`](../../aaw/mcp/specs/mcp3.md) · [`.stories`](../../aaw/mcp/specs/mcp3.stories.md) · [`.llms`](../../aaw/mcp/specs/mcp3.llms.md) |
| **mcp4** | config, ports & the wire contract (identity flags, `.aaw/config.json` read-through, all-or-nothing bind, `-wire-check`) | 18 | ✅ **realized — build-grade** (`internal/config`; `bindLocalhost`; `WireCheck`) | [`mcp4.md`](../../aaw/mcp/specs/mcp4.md) · [`.stories`](../../aaw/mcp/specs/mcp4.stories.md) · [`.llms`](../../aaw/mcp/specs/mcp4.llms.md) |
| **mcp5** | the `aaw reconcile` CLI subcommand (deterministic spec↔tree drift; no new MCP tool) | 18 | 📐 specced (forward) — not in this tree | [`mcp5.md`](../../aaw/mcp/specs/mcp5.md) · [`.stories`](../../aaw/mcp/specs/mcp5.stories.md) · [`.llms`](../../aaw/mcp/specs/mcp5.llms.md) |
| **mcp6** | interactive `aaw tui` — the read-only Bubble Tea console (no new MCP tool); the measurement rung | 18 | 📐 specced (forward) — not in this tree | [`mcp6.md`](../../aaw/mcp/specs/mcp6.md) · [`.stories`](../../aaw/mcp/specs/mcp6.stories.md) · [`.llms`](../../aaw/mcp/specs/mcp6.llms.md) |
| **mcp7** | message channels + `tool_x_resonance` + lazy TTL archival + the `aaw audit` CLI — **the 18 → 22 jump** | 22 | 📋 planned (forward) | row only — [`../../aaw/mcp/aaw.mcp.roadmap.md`](../../aaw/mcp/aaw.mcp.roadmap.md) §mcp7 |
| **mcp8** | the transport posture (C-1 probe), four-tier conformance closure + the live cutover | 22 | 📋 planned (forward) | row only — [`../../aaw/mcp/aaw.mcp.roadmap.md`](../../aaw/mcp/aaw.mcp.roadmap.md) §mcp8 |

Status legend: ✅ **realized in `2.0.0-min`** (the as-built tree holds this rung's surface) ·
🔨 **in flight** · 📐 **specced** (forward triad authored, not in this tree) ·
📋 **planned** (forward row only) · 🔒 **proposed**.

> The as-built tree carries the `mcp1`–`mcp4` band; the 18 → 22 tool jump and the conformance
> closure are `mcp7`/`mcp8`, owned by the forward roadmap. This reverse roadmap adds no rungs — it
> reconciles the as-built surface against the forward ladder.

## The master invariant

> **Files are truth; no loss by construction** — every durable fact in a plain file, every
> whole-file write atomic (temp + fsync + rename), history append-only, the server rebuildable from
> the tree at any instant. Held at every rung; verified in this tree at
> [`./aaw.design.md`](./aaw.design.md) §S-3. **Additive-only evolution:** no rung breaks a tool name
> or shape (the forward design's compatibility contract); a breaking change costs a new name.

## Seams & open decisions

No design fork is open in this as-built tree (the architecture decisions were ruled in the forward
Design Phase — [`./aaw.design.md`](./aaw.design.md) §S-11). The open seams are the forward roadmap's,
linked here, not re-owned:

- **C-1 — the transport probe** (forward mcp8): stateless is the intent; one live harness-dial probe
  is the decider; a flip to stateful is a configuration change, not a redesign. The as-built tree
  serves over `mcp.NewStreamableHTTPHandler` (`cmd/aaw/main.go:710`); the posture is settled forward.
  → [`../../aaw/mcp/aaw.mcp.roadmap.md`](../../aaw/mcp/aaw.mcp.roadmap.md) §Seams.
- **D-5 — the SDK seam:** `go/mcp-go` (module `github.com/fiberfx/mcp-go/v2`) is a first-party fork,
  modifiable as a designed + ADR-recorded change. → forward §Seams.
- **The auth seam:** tokenless v2 is ratified; `auth.RequireBearerToken` in `go/mcp-go` is the named
  upgrade path for any future non-loopback posture — a new design, not a knob. → forward §Seams.
- **Package layout:** the forward design's end-state layout materializes seam-by-seam; the as-built
  tree carries `internal/{config,gates,signals,store}` and `cmd/aaw/`. → forward §Seams.

## Map

- The forward ladder (binding for rung composition):
  [`../../aaw/mcp/aaw.mcp.roadmap.md`](../../aaw/mcp/aaw.mcp.roadmap.md).
- The forward design (the rungs derive from it):
  [`../../aaw/mcp/aaw.mcp.design.md`](../../aaw/mcp/aaw.mcp.design.md).
- The chapter index over the triads: [`../../aaw/mcp/specs/mcp.md`](../../aaw/mcp/specs/mcp.md).
- The as-built design / dashboard / features / testing: [`./aaw.design.md`](./aaw.design.md) ·
  [`./aaw.progress.md`](./aaw.progress.md) · [`./aaw.features.md`](./aaw.features.md) ·
  [`./aaw.testing.md`](./aaw.testing.md).
- The rung-triad index (links forward, no duplication): [`./specs/README.md`](./specs/README.md).
- Source: [`go/aaw/`](../../../go/aaw/) · the build guide [`go/CLAUDE.md`](../../../go/CLAUDE.md) ·
  the shared Go-server manual [`../program/go.program.md`](../program/go.program.md).
