APP       := flyer
MODULE    := github.com/fiberfx/flyer
ENTRY     := ./cmd/flyer
BIN_DIR   := ../bin

VERSION   ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")
COMMIT    ?= $(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")
BUILD_AT  ?= $(shell date -u +%Y-%m-%dT%H:%M:%SZ)

LDFLAGS   := -s -w \
  -X main.version=$(VERSION) \
  -X main.commit=$(COMMIT) \
  -X main.buildDate=$(BUILD_AT)

GOOS      ?= $(shell go env GOOS)
GOARCH    ?= $(shell go env GOARCH)

.PHONY: all build build-linux clean tidy

all: build

build: $(BIN_DIR)
	CGO_ENABLED=0 GOOS=$(GOOS) GOARCH=$(GOARCH) \
	  go build -ldflags "$(LDFLAGS)" -o $(BIN_DIR)/$(APP) $(ENTRY)

build-linux: $(BIN_DIR)
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
	  go build -ldflags "$(LDFLAGS)" -o $(BIN_DIR)/$(APP)-linux-amd64 $(ENTRY)

$(BIN_DIR):
	mkdir -p $(BIN_DIR)

clean:
	rm -f $(BIN_DIR)/$(APP) $(BIN_DIR)/$(APP)-linux-amd64

tidy:
	go mod tidy
