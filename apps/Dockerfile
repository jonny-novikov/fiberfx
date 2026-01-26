# syntax = docker/dockerfile:1

# =============================================================================
# FiberFx Gateway - Docker Image
# =============================================================================
# Go server with Svelte frontend + FiberFx Studio
#
# Architecture:
#   - Go binary → serves login page, handles JWT auth, proxies to studio
#   - FiberFx Studio → database management UI on internal port 3008
#
# Build approach:
#   - Uses pnpm for studio (matches pnpm-lock.yaml)
#   - Uses npm for gateway web (simpler, no lock file)
#   - Multi-stage build for minimal final image
#
# =============================================================================

# -----------------------------------------------------------------------------
# Stage 1: Build Go binary (Alpine - pure Go, no CGO)
# -----------------------------------------------------------------------------
FROM golang:1.23-alpine AS go-builder

WORKDIR /build

# Install build dependencies
RUN apk add --no-cache git ca-certificates

# Copy go.mod first for layer caching
COPY gateway/go.mod gateway/go.sum ./
RUN go mod download

# Copy source
COPY gateway/cmd/ ./cmd/
COPY gateway/internal/ ./internal/

# Build static binary
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags="-w -s" \
    -trimpath \
    -o gateway ./cmd/gateway

# -----------------------------------------------------------------------------
# Stage 2: Build Svelte frontend (login page)
# -----------------------------------------------------------------------------
FROM node:22-slim AS web-builder

WORKDIR /build

# Copy package files
COPY gateway/web/package.json ./
COPY gateway/web/package-lock.json* ./

# Install dependencies with npm
RUN npm install

# Copy source
COPY gateway/web/ ./

# Build production assets
RUN npm run build && \
    echo "=== Web build output ===" && \
    ls -la /build/dist/

# -----------------------------------------------------------------------------
# Stage 3: Build s3explorer Go server
# -----------------------------------------------------------------------------
FROM node:22-slim AS studio-builder

# Install pnpm
RUN corepack enable && corepack prepare pnpm@latest --activate

WORKDIR /app

# Copy package files and lock file
COPY studio/package.json studio/pnpm-lock.yaml ./

# Install dependencies with pnpm (matches local development)
RUN pnpm install --frozen-lockfile

# Copy source
COPY studio/ ./


# -----------------------------------------------------------------------------
# Stage 4: Final runtime image
# -----------------------------------------------------------------------------
FROM node:22-slim

LABEL fly_launch_runtime="FiberFxGateway"
LABEL maintainer="fireheadz"

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    tini \
    && rm -rf /var/lib/apt/lists/*

# Create app user
RUN groupadd -g 1001 gateway && \
    useradd -u 1001 -g gateway -s /bin/false gateway

WORKDIR /app

# Create directories
RUN mkdir -p /app/web /app/studio && \
    chown -R gateway:gateway /app

# Copy Go binary
COPY --from=go-builder /build/gateway /app/gateway

# Copy web assets (Svelte login page)
COPY --from=web-builder /build/dist /app/web

# Copy Next.js standalone server
COPY --from=studio-builder /app/.next/standalone /app/studio

# Copy Next.js static assets and public folder
COPY --from=studio-builder /app/.next/static /app/studio/.next/static
COPY --from=studio-builder /app/public /app/studio/public

# Verify setup
RUN echo "=== Gateway binary ===" && \
    ls -la /app/gateway && \
    echo "=== Web assets ===" && \
    ls -la /app/web/ && \
    echo "=== s3explorer files ===" && \
    ls -la /app/s3explorer

# Set permissions
RUN chmod +x /app/gateway && \
    chown -R gateway:gateway /app

# Switch to non-root user
USER gateway

# Environment
ENV PORT=8080
ENV S3_EXPLORER_PORT=3008
ENV S3_EXPLORER_CMD="node server.js"
ENV S3_EXPLORER_WORK_DIR=/app/s3explorer
ENV WEB_DIR=/app/web

# Expose main port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Use tini as init for proper signal handling
ENTRYPOINT ["/usr/bin/tini", "--"]

# Start gateway (which starts studio as child process)
CMD ["/app/gateway"]
