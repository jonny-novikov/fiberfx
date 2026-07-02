---
name: mcpd-controller
description: "go/mcpd = the Go cobra+bubbletea controller for the aaw+msh MCP servers (bin/, start/stop/restart, make mcp, safe hot-swap)"
project: mcpd
metadata: 
  node_type: memory
  type: project
  originSessionId: 7412b4ee-b3af-4f35-af24-757aa8513637
---

`go/mcpd` (module `github.com/jonny-novikov/mcpd`, built to `bin/mcpd`) is the single control plane for the two local MCP servers — **aaw** (`bin/aaw`, :8905) and **msh** (`bin/msh`, :8899). Bare `mcpd` = a Bubble Tea TUI (status board + s/x/r/S/X/R keys, manages servers detached); `mcpd start|restart|stop [-d]` = CLI (default = foreground-supervise with Ctrl-C teardown; `-d` = detach, servers outlive mcpd); `mcpd status` = one-shot table. `make mcp` = build mcpd + `mcpd restart -d` (the one-shot "ensure both up on a fresh build"); also `make mcp-stop` / `make mcp-status`. Built + proven end-to-end 2026-06-17; the whole Go tree then moved `apps/`→`go/` (2026-06-18) — the Makefile + `servers.go` (`isRepoRoot` markers + per-server `AppDir`s) repointed to `go/` so `make mcp` builds AND resolves the repo root at runtime (a Makefile-only fix builds but aborts "could not locate the jonnify repo root"); commit `9e35a8d6`.

**Non-obvious, load-bearing facts** (all also in code comments):
- **Safe hot-swap ordering = build → atomic rename → stop → start.** Each server builds to `bin/.<name>.new`, then `os.Rename`s into place; a FAILED build leaves the running server untouched (the old `Makefile restart: stop build start` had the opposite, unsafe order). Rename-over-a-running-binary is safe on Unix.
- **aaw flock-release wait is the central restart correctness fix.** aaw holds `LOCK_EX` on `<root>/.aaw/aaw.lock` for its whole life (acquired BEFORE bind); on restart mcpd probe-acquires-and-releases that flock non-blocking before starting the new aaw, else the new boot dies `INSTANCE_LOCKED`. This is the authoritative, PID-reuse-immune "old instance is gone" signal.
- **aaw must launch as `-workspace <root> -addr localhost:8905 serve`** — flags BEFORE the `serve` word (flag.Parse stops at the first non-flag arg), and the LITERAL `localhost:8905` (its strict wire-check compares the host string to `.mcp.json` with NO 127.0.0.1 normalization, so `127.0.0.1:8905` refuses to boot). Healthy boot logs `wire_contract agree` + dual-stack 127.0.0.1 & [::1].
- mcpd manages BOTH uniformly by launching each server's FOREGROUND `serve` as a child — NOT msh's own `msh mcp start` (that writes a `$TMPDIR` pidfile and would escape supervision). msh launched as `mcp serve --port 8899 --root <root>/memory` (the `.msh-memory.json` anchor). PID/log live in `bin/<name>.{pid,log}` (bin/ is fully gitignored).
- All server builds force **GOWORK=off** so each module compiles hermetically from its own go.mod, independent of any `go/go.work` state. Foreground children get `Setpgid` (terminal Ctrl-C reaches them exactly once via the supervisor's explicit forward, no double-signal); detached get `Setsid`. An orchestrator flock `bin/.mcpd.lock` serialises concurrent mutations (e.g. `make mcp` while the TUI is open).
- Deps: cobra v1.10.2 + bubbletea v1.3.10 + lipgloss v1.1.0 (all already in the module cache). After (re)starting, Claude Code needs a `/mcp` reconnect to re-attach.

Links: [[msh-mcp-server]].
