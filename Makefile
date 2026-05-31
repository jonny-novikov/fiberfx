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
INDEX_HTML ?= $(REPO_DIR)/index.html
EGE_DIR    ?= $(REPO_DIR)/ege
EDU_DIR    ?= $(REPO_DIR)/edu
SCHOOL_DIR ?= $(REPO_DIR)/school
FUTURE_DIR ?= $(REPO_DIR)/future
MAP_DIR    ?= $(REPO_DIR)/map
GAME_HTML  ?= $(REPO_DIR)/game.html
HEALTH_DIR ?= $(REPO_DIR)/health
VENDOR_DIR ?= $(REPO_DIR)/assets
ERROR_DIR  ?= $(REPO_DIR)/error
ELIXIR_DIR ?= $(REPO_DIR)/elixir
LOGIC_DIR  ?= $(REPO_DIR)/logic
LAW_DIR    ?= $(REPO_DIR)/law
SITEMAP_XML ?= $(REPO_DIR)/sitemap.xml
ROBOTS_TXT  ?= $(REPO_DIR)/robots.txt
SITE_BASE   ?= https://jonnify.fly.dev

export GOWORK := off

.PHONY: help build sitemap start stop restart run status clean

help:
	@echo "jonnify static server — targets:"
	@echo "  make build      Compile bin/jonnify"
	@echo "  make start      Build (if needed) and start server in background"
	@echo "  make stop       Stop background server via PID file"
	@echo "  make restart    Stop, rebuild, and start (fresh binary every time)"
	@echo "  make run        Run in foreground (logs to terminal)"
	@echo "  make status     Show whether server is running"
	@echo "  make clean      Remove binary, PID file, and log file"
	@echo "  make sitemap    Regenerate sitemap.xml + robots.txt (cmd/sitemap)"
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
	@echo "  /sitemap.xml         → $(SITEMAP_XML)"
	@echo "  /robots.txt          → $(ROBOTS_TXT)"
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
	 GAME_HTML=$(GAME_HTML) \
	 HEALTH_DIR=$(HEALTH_DIR) \
	 LOGIC_DIR=$(LOGIC_DIR) \
	 LAW_DIR=$(LAW_DIR) \
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
	 GAME_HTML=$(GAME_HTML) \
	 HEALTH_DIR=$(HEALTH_DIR) \
	 LOGIC_DIR=$(LOGIC_DIR) \
	 LAW_DIR=$(LAW_DIR) \
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
