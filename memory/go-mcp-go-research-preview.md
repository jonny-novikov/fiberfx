---
name: go-mcp-go-research-preview
description: "go/mcp-go = the Research Preview of the OFFICIAL MCP Go SDK (NOT mark3labs/mcp-go); first-party fork, FREE TO MODIFY (Operator D-5); aaw+msh consume it via replace ../mcp-go."
metadata:
  node_type: memory
  type: reference
  originSessionId: 28505ba0-cad7-48a6-8927-5e2e3eff1cf4
---

`go/mcp-go` (module `github.com/fiberfx/mcp-go/v2`, `go 1.25.0`) is the **Research Preview of the _official_ MCP
Go SDK** — an MCP-server toolkit with advanced features. It is **NOT `github.com/mark3labs/mcp-go`** (the popular
community library most "mcp-go" references mean); do not conflate them.

It is a **first-party vendored fork and FREE TO MODIFY** to fit `aaw`/`msh` needs (Operator decision **D-5**,
recorded in the `aaw-mcp` ledger): a build rung's diff boundary may legitimately extend into it. `go/aaw` and
`go/msh` consume it via `replace github.com/fiberfx/mcp-go/v2 => ../mcp-go`, so an edit here flows straight into
both servers with no re-vendor — the dev-ergonomics reason `go/go.work` spans the cluster.

**Why:** "mcp-go" usually means mark3labs; mistaking this fork for that read-only community lib would block
legitimate edits and misread its API surface.
**How to apply:** treat `go/mcp-go` as a modifiable first-party surface (cite it as the official-SDK research
preview); when extending `aaw`/`msh`, editing the SDK is on the table.

Related: [[go-workspace-active-dev]], [[mcpd-controller]], [[msh-mcp-server]]
