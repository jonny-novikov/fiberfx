# jonnify-cms — content toolchain for the /elixir Functional Programming course.
# GOWORK=off is required: the repo go.work references uninitialized submodules.

BIN        := bin/cms
ELIXIR_DIR ?= ../../elixir
export GOWORK := off

.PHONY: help build test vet install audit audit-fix readiness graph manifest promote integrate clean

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

# Auto-declare any built-but-planned modules + newly-arrived subpages in both
# manifests, rebuild cms, and re-sync the contents-page cards. The deterministic
# half of "process new pages as they arrive" (no AI).
promote:
	cd ../../docs/elixir/kb && python3 promote.py --rebuild

# Full integration sweep: promote drift, then audit links + report readiness.
integrate: promote audit readiness

clean:
	rm -rf bin
