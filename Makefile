# Makefile — jonnify static server (local dev)
#
# Serves:
#   /        → index.html
#   /ege/*   → ege/*.html  (clean URLs, no .html extension)
#   /edu/*   → edu/*.html  (clean URLs, no .html extension)
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

export GOWORK := off

.PHONY: help build start stop restart run status clean

help:
	@echo "jonnify static server — targets:"
	@echo "  make build      Compile bin/jonnify"
	@echo "  make start      Build (if needed) and start server in background"
	@echo "  make stop       Stop background server via PID file"
	@echo "  make restart    Stop, rebuild, and start (fresh binary every time)"
	@echo "  make run        Run in foreground (logs to terminal)"
	@echo "  make status     Show whether server is running"
	@echo "  make clean      Remove binary, PID file, and log file"
	@echo ""
	@echo "Server listens on http://localhost:$(PORT)"
	@echo "  /              → $(INDEX_HTML)"
	@echo "  /ege, /ege/*   → $(EGE_DIR)/*.html"
	@echo "  /edu, /edu/*   → $(EDU_DIR)/*.html"

$(BIN_DIR):
	@mkdir -p $(BIN_DIR)

build: | $(BIN_DIR)
	@echo "→ Building $(BINARY)"
	@cd $(REPO_DIR) && go build -o $(BINARY) .
	@echo "✓ Built $(BINARY)"

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
