---
name: go-workspace-active-dev
description: "go/ = the local agent OS in active dev: aaw (task-mgmt :8905, aligned to docs/aaw/aaw.framework.md) + msh (memory :8899, 7 tools) toward fully-fledged; go/go.work over the agent-infra 4; specs at docs/go/."
metadata:
  node_type: memory
  type: project
  originSessionId: 28505ba0-cad7-48a6-8927-5e2e3eff1cf4
---

`go/` is the repo's **local agent operating system**, in active development toward fully-fledged:
- **`aaw`** (task management, MCP `:8905`, `2.0.0-min`, **18 tools**) — the Agile Agent Workflow server,
  **aligned to `docs/aaw/aaw.framework.md`**, exemplified by `docs/echo_mq/emq.*` (AAW4). LAW-4 Z-gate at
  `go/aaw/internal/store/ledger.go:250`.
- **`msh`** (memory, MCP `:8899`, `0.1.0`, **7 tools** = 5 `memory_*` + `mint` + `specs`) — the `memory/` corpus
  toolchain ([[msh-mcp-server]]).
- **`mcpd`** the controller ([[mcpd-controller]]); **`mcp-go`** the modifiable official-SDK research preview
  ([[go-mcp-go-research-preview]]).

**As of 2026-06-17/18:** the modules live at **`go/<module>`** (the old `apps/` layout is gone); `mcpd` +
`Makefile` build from `go/…` (paths reconciled — `isRepoRoot` markers + `mcpd_test.go` use `go/aaw`/`go/msh`).
**`go/go.work`** spans the agent-infra 4 (`use ./aaw ./mcp-go ./mcpd ./msh`; `go 1.26.3` installed, modules pin
`1.25.0`) and **all four build clean** in workspace + `GOWORK=off` modes — `mcpd`/CI stay `GOWORK=off`
(hermetic); the standalone tools (`jonnify-cms`, `echomq-go`) are non-members, always `GOWORK=off`.

**Guides:** `go/CLAUDE.md` (build); the root `CLAUDE.md` **redirects Go work there**. **Specs:** the reverse-mode
as-built backbone is at **`docs/go/`** (`aaw/` + `msh/` + shared `program/`; the `aaw` forward v2 stays at
`docs/aaw/mcp/`, linked not duplicated). The `msh` `metadata.type` parser fork (parser reads top-level `type:`
at `frontmatter/parse.go:13` while the corpus nests `metadata.type` → notes classify `unknown`) is a real open
decision recorded in `docs/go/msh/msh.design.md`.

**Why:** `go/` is no longer scattered utility code — it is the agent OS (memory + task management) being built;
agents must know the `go/` layout, the working `go.work`, and the spec home.
**How to apply:** Go-server work → `go/CLAUDE.md` + `docs/go/`; build `GOWORK=off` for hermetic/CI; the workspace
is for interactive dev only.

Related: [[go-mcp-go-research-preview]], [[mcpd-controller]], [[msh-mcp-server]], [[echo-mq-three-movements]]
