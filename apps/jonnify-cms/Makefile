# jonnify-cms — content toolchain for the /elixir Functional Programming course.
# GOWORK=off is required: the repo go.work references uninitialized submodules.

BIN        := bin/cms
ELIXIR_DIR ?= ../../elixir
export GOWORK := off

.PHONY: help build test vet install audit audit-fix readiness graph manifest clean

help:
	@echo "jonnify-cms targets:"
	@echo "  make build      Compile $(BIN)"
	@echo "  make test       go test ./..."
	@echo "  make vet        go vet ./..."
	@echo "  make audit      Find broken links under $(ELIXIR_DIR)"
	@echo "  make audit-fix  Rename slug-mismatch orphans to canonical filenames"
	@echo "  make readiness  Reconcile manifest vs filesystem vs gates"
	@echo "  make graph      Emit the navigation graph (mermaid)"
	@echo "  make manifest   Print the course manifest"

build:
	go build -o $(BIN) .
	@echo "built $(BIN)"

test:
	go test ./...

vet:
	go vet ./...

install:
	go install .

audit: build
	./$(BIN) audit --root $(ELIXIR_DIR)

audit-fix: build
	./$(BIN) audit --fix --root $(ELIXIR_DIR)

readiness: build
	./$(BIN) readiness --root $(ELIXIR_DIR)

graph: build
	./$(BIN) graph --format mermaid --root $(ELIXIR_DIR)

manifest: build
	./$(BIN) manifest

clean:
	rm -rf bin
