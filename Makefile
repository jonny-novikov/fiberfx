# Makefile — jonnify static server (local dev)
#
# Serves (all clean URLs, no .html extension):
#   /          → index.html
#   /ege/*     → ege/*.html
#   /edu/*     → edu/*.html
#   /school/*  → school/*.html
#   /future/*  → future/*.html
#
# GOWORK=off is required because go.work references uninitialized submodules
# (atlas, imgkit, pgroll, tbls) that would otherwise break `go build`.

REPO_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
BIN_DIR  := $(REPO_DIR)/bin
BINARY   := $(BIN_DIR)/jonnify
PID_FILE := $(BIN_DIR)/jonnify.pid
LOG_FILE := $(BIN_DIR)/jonnify.log

PORT       ?= 8765
DISTR_DIR  ?= $(REPO_DIR)/data
INDEX_HTML ?= $(REPO_DIR)/html/index.html
EGE_DIR    ?= $(REPO_DIR)/html/ege
EDU_DIR    ?= $(REPO_DIR)/html/edu
SCHOOL_DIR ?= $(REPO_DIR)/html/school
FUTURE_DIR ?= $(REPO_DIR)/html/future
MAP_DIR    ?= $(REPO_DIR)/html/map
GAME_HTML  ?= $(REPO_DIR)/html/game.html
HEALTH_DIR ?= $(REPO_DIR)/html/health
VENDOR_DIR ?= $(REPO_DIR)/html/assets
ERROR_DIR  ?= $(REPO_DIR)/html/error
ELIXIR_DIR ?= $(REPO_DIR)/elixir
LOGIC_DIR  ?= $(REPO_DIR)/html/logic
LAW_DIR    ?= $(REPO_DIR)/html/law
PHYSICS_DIR ?= $(REPO_DIR)/html/physics
AI_RABOTA_DIR ?= $(REPO_DIR)/html/ai-rabota
AGILE_AGENT_WORKFLOW_DIR ?= $(REPO_DIR)/html/agile-agent-workflow
SITEMAP_XML ?= $(REPO_DIR)/html/sitemap.xml
ROBOTS_TXT  ?= $(REPO_DIR)/html/robots.txt
LLMS_TXT    ?= $(REPO_DIR)/html/llms.txt
SITE_BASE   ?= https://jonnify.fly.dev

export GOWORK := off

.PHONY: help build sitemap elixir-llms start stop restart run status watch clean

help:
	@echo "jonnify static server — targets:"
	@echo "  make build      Compile bin/jonnify"
	@echo "  make start      Build (if needed) and start server in background"
	@echo "  make stop       Stop background server via PID file"
	@echo "  make restart    Stop, rebuild, and start (fresh binary every time)"
	@echo "  make watch      Auto-reload: .go changes rebuild+restart; html/ served live"
	@echo "  make run        Run in foreground (logs to terminal)"
	@echo "  make status     Show whether server is running"
	@echo "  make clean      Remove binary, PID file, and log file"
	@echo "  make sitemap    Regenerate sitemap.xml + robots.txt (cmd/sitemap)"
	@echo "  make elixir-llms Regenerate per-chapter elixir/**/llms.txt (cmd/elixir-llms)"
	@echo ""
	@echo "Server listens on http://localhost:$(PORT)"
	@echo "  /                    → $(INDEX_HTML)"
	@echo "  /ege, /ege/*         → $(EGE_DIR)/*.html"
	@echo "  /edu, /edu/*         → $(EDU_DIR)/*.html"
	@echo "  /school, /school/*   → $(SCHOOL_DIR)/*.html"
	@echo "  /future, /future/*   → $(FUTURE_DIR)/*.html"
	@echo "  /map, /map/*         → $(MAP_DIR)/*.html (3D orbital map)"
	@echo "  /elixir, /elixir/**  → $(ELIXIR_DIR)/ (folder tree → index.html / <name>.html)"
	@echo "  /game                → $(GAME_HTML)"
	@echo "  /healthz             → JSON liveness probe (Fly health check)"
	@echo "  /health, /health/**  → $(HEALTH_DIR)/ (folder tree → index.html / <module>.html)"
	@echo "  /logic, /logic/**    → $(LOGIC_DIR)/ (folder tree → index.html / <module>.html)"
	@echo "  /law, /law/**        → $(LAW_DIR)/ (folder tree → index.html / <module>.html)"
	@echo "  /physics, /physics/**→ $(PHYSICS_DIR)/ (folder tree → index.html / <module>.html)"
	@echo "  /ai-rabota, /ai-rabota/** → $(AI_RABOTA_DIR)/ (folder tree → index.html / <module>.html)"
	@echo "  /agile-agent-workflow, /agile-agent-workflow/** → $(AGILE_AGENT_WORKFLOW_DIR)/ (folder tree → index.html / <module>.html)"
	@echo "  /sitemap.xml         → $(SITEMAP_XML)"
	@echo "  /robots.txt          → $(ROBOTS_TXT)"
	@echo "  /llms.txt            → $(LLMS_TXT)"
	@echo "  (errors)             → $(ERROR_DIR)/<status>.html (404, 500, …)"

$(BIN_DIR):
	@mkdir -p $(BIN_DIR)

build: | $(BIN_DIR)
	@echo "→ Building $(BINARY)"
	@cd $(REPO_DIR) && go build -o $(BINARY) .
	@echo "✓ Built $(BINARY)"

sitemap:
	@echo "→ Generating sitemap.xml + robots.txt (base $(SITE_BASE))"
	@cd $(REPO_DIR) && go run ./cmd/sitemap -base $(SITE_BASE) -root $(REPO_DIR) -out $(SITEMAP_XML) -robots $(ROBOTS_TXT)
	@echo "✓ Wrote $(SITEMAP_XML) and $(ROBOTS_TXT)"

# Regenerate the per-chapter elixir/<chapter>/llms.txt agent maps (+ course-root
# elixir/llms.txt) from page metadata. Served as text/plain by serveDirTree; re-run
# after adding/renaming elixir lessons so the maps stay accurate.
elixir-llms:
	@echo "→ Generating per-chapter elixir/**/llms.txt"
	@cd $(REPO_DIR) && go run ./cmd/elixir-llms -root $(REPO_DIR)
	@echo "✓ Wrote elixir/llms.txt + per-chapter maps"

start: build
	@if [ -f $(PID_FILE) ] && kill -0 $$(cat $(PID_FILE)) 2>/dev/null; then \
		echo "✗ Server already running (PID $$(cat $(PID_FILE))). Use 'make restart' or 'make stop' first."; \
		exit 1; \
	fi
	@echo "→ Starting jonnify on port $(PORT) (logs: $(LOG_FILE))"
	@PORT=$(PORT) \
	 DISTR_DIR=$(DISTR_DIR) \
	 INDEX_HTML=$(INDEX_HTML) \
	 EGE_DIR=$(EGE_DIR) \
	 EDU_DIR=$(EDU_DIR) \
	 SCHOOL_DIR=$(SCHOOL_DIR) \
	 FUTURE_DIR=$(FUTURE_DIR) \
	 MAP_DIR=$(MAP_DIR) \
	 ELIXIR_DIR=$(ELIXIR_DIR) \
	 SITEMAP_XML=$(SITEMAP_XML) \
	 ROBOTS_TXT=$(ROBOTS_TXT) \
	 LLMS_TXT=$(LLMS_TXT) \
	 GAME_HTML=$(GAME_HTML) \
	 HEALTH_DIR=$(HEALTH_DIR) \
	 LOGIC_DIR=$(LOGIC_DIR) \
	 LAW_DIR=$(LAW_DIR) \
	 PHYSICS_DIR=$(PHYSICS_DIR) \
	 AI_RABOTA_DIR=$(AI_RABOTA_DIR) \
	 AGILE_AGENT_WORKFLOW_DIR=$(AGILE_AGENT_WORKFLOW_DIR) \
	 VENDOR_DIR=$(VENDOR_DIR) \
	 ERROR_DIR=$(ERROR_DIR) \
	 nohup $(BINARY) > $(LOG_FILE) 2>&1 & echo $$! > $(PID_FILE)
	@sleep 1
	@if kill -0 $$(cat $(PID_FILE)) 2>/dev/null; then \
		echo "✓ Started (PID $$(cat $(PID_FILE))). http://localhost:$(PORT)/"; \
	else \
		echo "✗ Server failed to start — check $(LOG_FILE)"; \
		rm -f $(PID_FILE); \
		exit 1; \
	fi

stop:
	@if [ -f $(PID_FILE) ]; then \
		PID=$$(cat $(PID_FILE)); \
		if kill -0 $$PID 2>/dev/null; then \
			echo "→ Stopping jonnify (PID $$PID)"; \
			kill $$PID; \
			for i in 1 2 3 4 5; do \
				kill -0 $$PID 2>/dev/null || break; \
				sleep 1; \
			done; \
			kill -0 $$PID 2>/dev/null && kill -9 $$PID 2>/dev/null; \
			echo "✓ Stopped"; \
		else \
			echo "  (PID file present but process $$PID not running — cleaning up)"; \
		fi; \
		rm -f $(PID_FILE); \
	else \
		echo "  (no PID file — server is not running)"; \
	fi

restart: stop build start

# Auto-reload for local dev — no extra tools required (no fswatch/entr). Polls
# once a second with find(1). A root-package .go change (what 'make build'
# compiles into the server binary) rebuilds + restarts; content under html/ and
# elixir/ is served live by the running server (serveDirTree reads disk per
# request, so an HTML edit shows up on the next request with no restart), so a
# content edit is reported as already-live.
# Starts from a fresh server via 'restart', then watches until Ctrl-C.
watch: restart
	@echo "▶ watching $(REPO_DIR) — .go → rebuild+restart, html/elixir → served live (Ctrl-C to stop)"
	@touch $(BIN_DIR)/.watch-go $(BIN_DIR)/.watch-html
	@while sleep 1; do \
		if [ -n "$$(find $(REPO_DIR) -maxdepth 1 -name '*.go' -newer $(BIN_DIR)/.watch-go -print -quit 2>/dev/null)" ]; then \
			echo "↻ .go changed → rebuild + restart"; \
			$(MAKE) --no-print-directory restart; \
			touch $(BIN_DIR)/.watch-go $(BIN_DIR)/.watch-html; \
		elif [ -n "$$(find $(REPO_DIR)/html $(REPO_DIR)/elixir -type f -newer $(BIN_DIR)/.watch-html -print -quit 2>/dev/null)" ]; then \
			echo "✓ content changed → served live (no restart needed)"; \
			touch $(BIN_DIR)/.watch-html; \
		fi; \
	done

run: build
	@echo "→ Running jonnify in foreground on port $(PORT) (Ctrl-C to stop)"
	@PORT=$(PORT) \
	 DISTR_DIR=$(DISTR_DIR) \
	 INDEX_HTML=$(INDEX_HTML) \
	 EGE_DIR=$(EGE_DIR) \
	 EDU_DIR=$(EDU_DIR) \
	 SCHOOL_DIR=$(SCHOOL_DIR) \
	 FUTURE_DIR=$(FUTURE_DIR) \
	 MAP_DIR=$(MAP_DIR) \
	 ELIXIR_DIR=$(ELIXIR_DIR) \
	 SITEMAP_XML=$(SITEMAP_XML) \
	 ROBOTS_TXT=$(ROBOTS_TXT) \
	 LLMS_TXT=$(LLMS_TXT) \
	 GAME_HTML=$(GAME_HTML) \
	 HEALTH_DIR=$(HEALTH_DIR) \
	 LOGIC_DIR=$(LOGIC_DIR) \
	 LAW_DIR=$(LAW_DIR) \
	 PHYSICS_DIR=$(PHYSICS_DIR) \
	 AI_RABOTA_DIR=$(AI_RABOTA_DIR) \
	 AGILE_AGENT_WORKFLOW_DIR=$(AGILE_AGENT_WORKFLOW_DIR) \
	 VENDOR_DIR=$(VENDOR_DIR) \
	 ERROR_DIR=$(ERROR_DIR) \
	 $(BINARY)

status:
	@if [ -f $(PID_FILE) ] && kill -0 $$(cat $(PID_FILE)) 2>/dev/null; then \
		echo "✓ Running (PID $$(cat $(PID_FILE))) on port $(PORT)"; \
	else \
		echo "✗ Not running"; \
	fi

clean: stop
	@rm -f $(BINARY) $(PID_FILE) $(LOG_FILE)
	@echo "✓ Cleaned bin/"
