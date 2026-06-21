# echo-courses — the Echo v5 courses server (docs/echo_courses, rungs ec.1-ec.6).
#
# Standalone module: it consumes the vendored Echo at ../echo via a replace
# directive and builds hermetically with GOWORK=off (echo-courses is not a
# go.work member, matching the go/CLAUDE.md standalone-tool convention).

GO ?= go
BIN := bin/server

GOWORK := off
export GOWORK

.PHONY: build run test vet fmt tidy gate clean

# compile the server binary
build:
	$(GO) build -o $(BIN) ./cmd/server

# run the server (ADDR, STATIC_DIR read from the environment)
run:
	$(GO) run ./cmd/server

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
