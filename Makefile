# Makefile — jonnify workspace
#

REPO_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
BIN_DIR  := $(REPO_DIR)/bin

.PHONY: help mcp mcpd mcp-stop mcp-status

help:
	@echo "jonnify — targets:"
	@echo ""
	@echo "MCP servers (aaw :8905 + msh :8899) via the mcpd controller:"
	@echo "  make mcp        Build + safe hot-swap restart aaw+msh, detached (the one-shot 'ensure up')"
	@echo "  make mcp-stop   Stop the aaw+msh MCP servers"
	@echo "  make mcp-status Show aaw+msh MCP server status (run bin/mcpd with no args for the TUI)"
	@echo ""

$(BIN_DIR):
	@mkdir -p $(BIN_DIR)

# ── MCP servers (aaw :8905 + msh :8899) via the mcpd controller ──────────────
# mcpd (apps/mcpd) is the single control plane for both MCP servers. It builds
# each server to a temp path and atomically swaps it into bin/ — a FAILED build
# never takes down a running server — then restarts, waiting for aaw's instance
# flock to release so the fresh aaw boots without INSTANCE_LOCKED. `make mcp` is
# the one-shot "ensure both are up on a fresh build, detached" entrypoint that
# satisfies the build-restart-safely-hot-swap contract. For an interactive
# control panel, run `bin/mcpd` with no arguments (a Bubble Tea TUI).
MCPD_BIN := $(BIN_DIR)/mcpd

mcpd: | $(BIN_DIR)
	@echo "→ Building $(MCPD_BIN)"
	@cd $(REPO_DIR)/apps/mcpd && GOWORK=off go build -o $(MCPD_BIN) .
	@echo "✓ Built $(MCPD_BIN)"

mcp: mcpd
	@echo "→ Ensuring aaw + msh MCP servers are up (build + safe hot-swap restart, detached)"
	@$(MCPD_BIN) restart -d

mcp-stop: mcpd
	@$(MCPD_BIN) stop

mcp-status: mcpd
	@$(MCPD_BIN) status
