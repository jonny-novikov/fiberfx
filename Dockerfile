# Build stage - builds both jonnify server and flyer CLI
FROM golang:1.25-alpine AS builder

# Install tar for creating distribution archives
RUN apk --no-cache add tar

WORKDIR /build

# ===== Build jonnify server =====
COPY go.mod go.sum* ./
RUN go mod download

COPY main.go .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o jonnify .

# ===== Build flyer CLI =====
WORKDIR /build/flyer
COPY flyer/go.mod flyer/go.sum ./
RUN go mod download

COPY flyer/ .

# Extract version from source
RUN FLYER_VERSION=$(grep 'version = ' cmd/flyer/main.go | cut -d'"' -f2) && \
    echo "${FLYER_VERSION}" > /build/flyer-version.txt && \
    echo "Building flyer v${FLYER_VERSION} for linux, windows, darwin (amd64)"

# Build flyer for Linux amd64
RUN FLYER_VERSION=$(cat /build/flyer-version.txt) && \
    CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
        -ldflags="-s -w -X main.version=${FLYER_VERSION}" \
        -o /build/flyer-linux-amd64 ./cmd/flyer

# Build flyer for Windows amd64
RUN FLYER_VERSION=$(cat /build/flyer-version.txt) && \
    CGO_ENABLED=0 GOOS=windows GOARCH=amd64 go build \
        -ldflags="-s -w -X main.version=${FLYER_VERSION}" \
        -o /build/flyer-windows-amd64.exe ./cmd/flyer

# Build flyer for Darwin (macOS) amd64
RUN FLYER_VERSION=$(cat /build/flyer-version.txt) && \
    CGO_ENABLED=0 GOOS=darwin GOARCH=amd64 go build \
        -ldflags="-s -w -X main.version=${FLYER_VERSION}" \
        -o /build/flyer-darwin-amd64 ./cmd/flyer

# Create distribution tarballs for all platforms
RUN FLYER_VERSION=$(cat /build/flyer-version.txt) && \
    mkdir -p /build/distr/flyer && \
    # Linux
    tar -czvf /build/distr/flyer/flyer-${FLYER_VERSION}-linux-amd64.tar.gz \
        -C /build flyer-linux-amd64 && \
    # Windows
    tar -czvf /build/distr/flyer/flyer-${FLYER_VERSION}-windows-amd64.tar.gz \
        -C /build flyer-windows-amd64.exe && \
    # Darwin
    tar -czvf /build/distr/flyer/flyer-${FLYER_VERSION}-darwin-amd64.tar.gz \
        -C /build flyer-darwin-amd64 && \
    # Create latest symlinks
    ln -sf flyer-${FLYER_VERSION}-linux-amd64.tar.gz /build/distr/flyer/flyer-latest-linux-amd64.tar.gz && \
    ln -sf flyer-${FLYER_VERSION}-windows-amd64.tar.gz /build/distr/flyer/flyer-latest-windows-amd64.tar.gz && \
    ln -sf flyer-${FLYER_VERSION}-darwin-amd64.tar.gz /build/distr/flyer/flyer-latest-darwin-amd64.tar.gz

# ===== Runtime stage =====
FROM alpine:3.19

RUN apk --no-cache add ca-certificates

WORKDIR /app

# Copy jonnify server binary
COPY --from=builder /build/jonnify /app/jonnify

# Copy static index.html served at "/"
COPY index.html /app/index.html

# Copy EGE course materials served under /ege/*
COPY ege/ /app/ege/

# Copy EDU course materials served under /edu/*
COPY edu/ /app/edu/

# Copy SCHOOL course materials served under /school/*
COPY school/ /app/school/

# Copy FUTURE course materials served under /future/*
COPY future/ /app/future/

# Create distribution directory structure
RUN mkdir -p /app/distr/litestream /app/distr/flyer

# Copy litestream distribution (static, never changes)
COPY data/litestream-0.5.5.tar.gz /app/distr/litestream/

# Copy flyer distribution (built at Docker build time)
COPY --from=builder /build/distr/flyer/ /app/distr/flyer/

EXPOSE 8080

CMD ["/app/jonnify"]
