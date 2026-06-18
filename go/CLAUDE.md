# CLAUDE.md — the `go/` workspace · the local agent operating system

This file guides a fresh session building in `/Users/jonny/dev/jonnify/go`. It is the **per-workspace build
guide** for the repo's **local agent operating system** — the Go MCP servers that run the Operator's
**memory** and **task-management** workflow: `msh` (memory) and `aaw` (the Agile Agent Workflow), the
controller `mcpd` that runs them, and the `mcp-go` SDK they stand on. It records the layout, the toolchain,
the build/gate commands, and the invariants that keep the live servers healthy.

The **specs are the source of truth**, not this file: the as-built spec program for these servers lives at
`docs/go/` (the `aaw` + `msh` reverse-mode backbone); the **framework `aaw` operationalizes** is
`docs/aaw/aaw.framework.md`; the fullest **worked example** of the workflow is `docs/echo_mq/`. The repo-root
`CLAUDE.md` redirects Go work here — but only Go work; for the echo_mq / BCS Elixir stack it and
`echo/CLAUDE.md` stay authoritative.

## Scope of this file

**In scope:** the four agent-OS modules and their build/test mechanics — `aaw` · `msh` · `mcpd` · `mcp-go`.
The goal of the work here is to bring `aaw` (task management) and `msh` (local memory) to **fully-fledged**,
with `aaw` aligned to the AAW framework definition.

**Out of scope for this file** (they live under `go/` but are standalone tools, not the agent OS): `jonnify-cms`
(the Go CMS toolchain for the `/elixir` static course) and `echomq-go` (the Go client for the Valkey-backed
EchoMQ bus). Build them independently — they are **not** `go.work` members (see §2). Also out of scope: the
`echo/` Elixir umbrella (its own `echo/CLAUDE.md`).

## 1. The workspace — the local agent OS (base → top)

| Module | Role | Port / form |
|---|---|---|
| `mcp-go` | **The SDK** — the **Research Preview of the _official_ MCP Go SDK** (`github.com/fiberfx/mcp-go/v2`), an MCP server toolkit with advanced features. It is **NOT `github.com/mark3labs/mcp-go`** (the community library most "mcp-go" references mean). Vendored as a first-party fork and **free to modify** to fit `aaw`/`msh` needs (Operator decision D-5); `aaw` + `msh` consume it via `replace … => ../mcp-go`, so an edit here flows straight through with no re-vendor. | library |
| `msh` | **Local memory** — the `memory/` corpus toolchain (`memory_scan` / `memory_graph` / `memory_stale` / `memory_audit` / `memory_project`) + a `specs` spec-lint tool + `mint` (brd14 branded ids) — **7 tools**. Resolves the corpus via `.msh-memory.json` (the project anchor). Goal: **fully-fledged local memory**. | MCP `:8899` |
| `aaw` | **Task management** — the Agile Agent Workflow MCP server: the team/scope registry (`aaw_init`, `aaw_spawn`, `agent_register`/`send`/`heartbeat`, `aaw_status`, `probe`) and the per-scope ledger (`tool_x_*`). **Aligned to `docs/aaw/aaw.framework.md`** (the Operator-Agent model, the four artifacts, the sharpen→build→ship→demo→review→feedback loop), exemplified by `docs/echo_mq/emq.*` (AAW4 — the framework's own validation run). Goal: **fully-fledged task management**. | MCP `:8905` (dual-stack) |
| `mcpd` | **The controller** — a cobra + Bubble Tea control plane that builds, atomically hot-swaps, and runs both servers (`make mcp`). | CLI / TUI |

> `aaw` + `msh` are the two halves of the local agent OS — task management and memory — and both are in
> **active development** toward fully-fledged. `mcp-go` is the shared substrate; `mcpd` is the operator's
> control plane.

## 2. The `go.work` — the agent-infra workspace

`go/go.work` spans exactly the four agent-OS modules:

```
go 1.26.3
use (./aaw ./mcp-go ./mcpd ./msh)
```

It exists for **interactive dev ergonomics**: because `aaw` and `msh` both `replace … => ../mcp-go`, a workspace
over that cluster means an edit to the `mcp-go` SDK is picked up by both servers immediately — no re-vendor.

**The `GOWORK=off` rule** (load-bearing):

- `mcpd` and any CI build force **`GOWORK=off`** so each server compiles **hermetically** from its own `go.mod`,
  reproducibly and independent of workspace state. The workspace never interferes with the build that ships.
- The **standalone tools** (`jonnify-cms`, `echomq-go`) are **not** workspace members — always build them with
  `GOWORK=off` from their own dir.

Toolchain: the installed Go is **`go1.26.3`**; the modules declare `go 1.25.0` (their **minimum** language
version) — both are true, do not "correct" the `go.work` `go` line down to 1.25.0.

## 3. Build / run / verify

```bash
# interactive dev build (go.work auto-discovered from a parent dir)
cd /Users/jonny/dev/jonnify/go/<module>     # aaw | msh | mcpd | mcp-go
go build ./...

# hermetic build / the gate (what mcpd + CI run)
GOWORK=off go build ./...
GOWORK=off go vet ./...
GOWORK=off go test ./...
gofmt -l .                                   # must print nothing
```

The controller (from the repo root): `make mcp` builds both servers and safe-hot-swap-restarts them detached;
`make mcp-status` / `make mcp-stop`; bare `bin/mcpd` opens the TUI. `mcpd` builds each server to a temp path and
**atomically renames it into `bin/` only on success — a failed build never takes down a live server.**

Ports + wire: `aaw` `localhost:8905` (dual-stack `127.0.0.1` + `[::1]`), `msh` `localhost:8899`; both registered
in the repo-root `.mcp.json` (streamable HTTP). **Adding a tool or restarting a server needs an `/mcp`
reconnect** to be seen by the client.

## 4. Invariants & gotchas (violating these breaks a live server or the build)

- **The live servers serve _this_ session.** Don't `pkill`; let `mcpd` hot-swap (a failed build leaves the
  running server untouched). If you must stop one, kill its exact pid (`bin/<name>.pid`).
- **`aaw` holds an instance flock for its whole life.** On restart `mcpd` waits for the flock to release before
  booting the fresh `aaw`, else `INSTANCE_LOCKED`.
- **`aaw -addr` must be the literal `localhost:8905`** — its strict wire-check compares the host string against
  `.mcp.json` with no `127.0.0.1` normalization. `aaw`'s flags (stdlib `flag`) **must precede the mode word**
  (`serve` | `selftest`); `flag.Parse` stops at the first non-flag.
- **`aaw` enforces LAW-4:** `tool_x_complete` refuses a completion entry while no decision (`D-n`) is locked in
  the scope ledger.
- **`GOWORK=off`** for `mcpd`/CI builds and for the standalone tools — never assume the workspace.
- **`mcp-go` is modifiable** (Operator D-5): a build rung's diff boundary may legitimately extend into it.

## The workflow (how work ships here)

Work ships **spec-driven, rung by rung** (the Agile Agent Workflow) — thin provable increments under
executable gates. The `aaw` server itself is built this way (its forward ladder `docs/aaw/mcp/specs/mcp1–8`).
Read the framework definition `docs/aaw/aaw.framework.md`, the worked example `docs/echo_mq/`, and the as-built
reverse-mode specs for these servers under `docs/go/`.

## Map

Framework `docs/aaw/` (`aaw.framework.md` · `aaw.rules.md` · `aaw.reverse.md` · `aaw.architect-approach.md`) ·
the Go-server specs `docs/go/` (`aaw/` + `msh/`, forward v2 for `aaw` at `docs/aaw/mcp/`) · the worked example
`docs/echo_mq/` · the memory corpus `memory/` + the `.msh-memory.json` anchor · the controller via the root
`Makefile`.
