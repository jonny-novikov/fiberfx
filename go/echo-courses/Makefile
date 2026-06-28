# echo-courses — the Echo v5 courses server (docs/echo_courses, rungs ec.1-ec.6).
#
# Standalone module: it consumes the vendored Echo at ../echo via a replace
# directive and builds hermetically with GOWORK=off (echo-courses is not a
# go.work member, matching the go/CLAUDE.md standalone-tool convention).

GO ?= go
BIN := bin/server

# background dev-server controls (make start | stop | restart | status)
ADDR ?= :1323
PID  := bin/server.pid
LOG  := bin/server.log

GOWORK := off
export GOWORK

.PHONY: build run start stop restart status test vet fmt tidy gate clean

# compile the server binary
build:
	$(GO) build -o $(BIN) ./cmd/server

# run the server in the FOREGROUND (ADDR, STATIC_DIR read from the environment)
run:
	$(GO) run ./cmd/server

# start the server in the BACKGROUND (detached, pidfile-managed); override the
# port with `make start ADDR=:8080`. Idempotent — a second start is a no-op.
start: build
	@if [ -f $(PID) ] && kill -0 `cat $(PID)` 2>/dev/null; then \
		echo "already running (pid `cat $(PID)`) on http://localhost$(ADDR)"; \
	else \
		ADDR=$(ADDR) nohup ./$(BIN) > $(LOG) 2>&1 & echo $$! > $(PID); \
		echo "started (pid `cat $(PID)`) -> http://localhost$(ADDR)  (logs: $(LOG))"; \
	fi

# stop the background server (graceful SIGTERM) and wait for it to exit
stop:
	@if [ -f $(PID) ] && kill -0 `cat $(PID)` 2>/dev/null; then \
		p=`cat $(PID)`; kill $$p; \
		for _ in 1 2 3 4 5 6 7 8 9 10; do kill -0 $$p 2>/dev/null || break; sleep 0.3; done; \
		echo "stopped (pid $$p)"; \
	else echo "not running"; fi; rm -f $(PID)

# restart = stop then start
restart: stop start

# report whether the background server is up
status:
	@if [ -f $(PID) ] && kill -0 `cat $(PID)` 2>/dev/null; then \
		echo "running (pid `cat $(PID)`) on http://localhost$(ADDR)"; \
	else echo "not running"; fi

# run the test suite
test:
	$(GO) test ./...

# go vet
vet:
	$(GO) vet ./...

# list mis-formatted files (empty output = clean)
fmt:
	gofmt -l .

# sync go.mod / go.sum against the vendored echo
tidy:
	$(GO) mod tidy

# the full gate: tidy + build + vet + test + gofmt-clean
gate:
	$(GO) mod tidy
	$(GO) build ./...
	$(GO) vet ./...
	$(GO) test ./...
	@test -z "$$(gofmt -l .)" || { echo "gofmt needed on:"; gofmt -l .; exit 1; }
	@echo "gate: OK"

clean:
	rm -rf bin
