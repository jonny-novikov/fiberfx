# EchoMQ Go — Makefile
#
# Common targets for local development and CI. CI ordering expectations:
#   - `make check-lua-drift` must pass before `make test`.

SHELL := /usr/bin/env bash

.PHONY: help test check-lua-drift build-consumer

help:
	@echo "EchoMQ Go — available targets:"
	@echo "  make check-lua-drift   Verify embedded Lua scripts match the BullMQ pin (R-2)"
	@echo "  make test              Run the Go test suite (race-detector on)"
	@echo "  make build-consumer    Build the standalone echomq-consumer binary (linux/amd64) -> ../bin/echomq-consumer"
	@echo "  make help              This message"

# FTR0N1TUwoc4DQ R-2: standalone wire-only consumer for nano-extreme container.
# Output path follows the apps/bin/ canonical convention (CLAUDE.md "Binary Convention").
build-consumer:
	GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -trimpath -o ../bin/echomq-consumer ./cmd/echomq-consumer

# R-2: Lua upstream drift check. Exits 0 on clean state, 2 on drift.
check-lua-drift:
	@scripts/check-lua-drift.sh

# Standard Go test run with race detector. Drift check is a pre-req so
# that CI fails fast on protocol pin violations rather than after a long
# test run.
test: check-lua-drift
	go test -race ./...
