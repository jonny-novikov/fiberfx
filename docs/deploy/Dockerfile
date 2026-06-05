# syntax = docker/dockerfile:1

# =============================================================================
# Phoenix Machine Dockerfile
# Echo (Elixir/Phoenix) + Fastify Workers
# =============================================================================
#
# FWHD (Fastify Worker Hot Deployment):
#   - Fastify backend downloaded from Tigris S3 at startup (via flyer sync)
#   - packages.db tracks versions, replicated via Litestream
#   - No volume mounting needed - workers pre-downloaded before Echo starts
#
# Architecture:
#   - Echo (Phoenix 1.7 / Elixir 1.18.4 / OTP 27) runs as supervisor on port 4000
#   - Fastify workers (Node.js 22) spawned by Echo via OTP supervision
#   - LiveSvelte for Phoenix LiveView + Svelte 5 SSR integration
#   - Both share the same codemoji-postgres Postgres instance
#
# Port Allocation:
#   4000  - Echo Phoenix (HTTP + Channels + LiveView)
#   6003  - Fastify API (from /app/workers/backend or /app/packages/current)
#
# Build Stages:
#   1. node-base     - Node.js base with npm
#   2. elixir-deps   - Fetch Elixir deps (provides Phoenix JS packages)
#   3. node-build    - Build Echo frontend assets (esbuild + Svelte 5)
#   4. elixir-base   - Elixir/OTP setup
#   5. elixir-build  - Build Phoenix release
#   6. runtime       - Final image (Node.js runtime + Elixir release)
#
# =============================================================================

# -----------------------------------------------------------------------------
# Stage 1: Node.js Base
# -----------------------------------------------------------------------------
ARG NODE_VERSION=22
ARG ELIXIR_VERSION=1.18.4
ARG OTP_VERSION=27.3.4.1
ARG DEBIAN_DATE=20251117

FROM node:${NODE_VERSION}-alpine AS node-base

WORKDIR /app
ENV NODE_ENV=production

# -----------------------------------------------------------------------------
# Stage 2: Elixir Deps (fetch Phoenix JS deps for node-build)
# -----------------------------------------------------------------------------
# Fetches Elixir dependencies which include the Phoenix JavaScript packages.
# These are then copied to the node-build stage for npm resolution.
# Uses umbrella structure for in_umbrella deps (live_svelte).
# -----------------------------------------------------------------------------
FROM hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-bookworm-${DEBIAN_DATE} AS elixir-deps

WORKDIR /app
ENV MIX_ENV=prod

# Install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Copy umbrella root and apps (mix.lock is at umbrella root)
COPY mix.exs mix.lock ./
COPY apps/echo/mix.exs apps/echo/
COPY apps/live_svelte/mix.exs apps/live_svelte/

# Fetch dependencies from umbrella root (resolves in_umbrella deps)
RUN mix deps.get --only prod

# -----------------------------------------------------------------------------
# Stage 3: Node.js Build (Echo Assets - LiveSvelte + esbuild)
# -----------------------------------------------------------------------------
# Builds Echo frontend assets for LiveView + Svelte 5 SSR:
#   - Client bundle: priv/static/assets/app.js
#   - Server bundle: priv/svelte/server.js (Node 22 SSR)
#
# NOTE: Fastify backend is NOT built here - deployed via FWHD from Tigris S3.
# -----------------------------------------------------------------------------
FROM node-base AS node-build

WORKDIR /app/assets

# Copy live_svelte package (local dependency)
# Path must match package.json "file:../../live_svelte" from /app/assets
COPY apps/live_svelte /live_svelte

# Copy Echo assets for npm resolution
COPY apps/echo/assets/package.json apps/echo/assets/package-lock.json ./

# Copy Phoenix JS deps from elixir-deps stage (umbrella deps at /app/deps/)
COPY --from=elixir-deps /app/deps/phoenix ../deps/phoenix
COPY --from=elixir-deps /app/deps/phoenix_html ../deps/phoenix_html
COPY --from=elixir-deps /app/deps/phoenix_live_view ../deps/phoenix_live_view

# Install dependencies (include devDependencies for build tools like esbuild)
RUN npm ci --include=dev

# Copy asset source files
COPY apps/echo/assets/js ./js
COPY apps/echo/assets/css ./css
COPY apps/echo/assets/svelte ./svelte
COPY apps/echo/assets/build.mjs ./build.mjs
COPY apps/echo/assets/tsconfig.json ./tsconfig.json

# Build production bundles (client + server SSR)
RUN node build.mjs --deploy

# -----------------------------------------------------------------------------
# Stage 4: Elixir Base (using Debian for glibc compatibility with runtime)
# Tag format: hexpm/elixir:1.18.4-erlang-27.3.4.1-debian-bookworm-20251117
# -----------------------------------------------------------------------------
FROM hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-bookworm-${DEBIAN_DATE} AS elixir-base

WORKDIR /app
ENV MIX_ENV=prod

# Install build dependencies
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# -----------------------------------------------------------------------------
# Stage 5: Elixir Build
# -----------------------------------------------------------------------------
# Uses umbrella structure for in_umbrella deps (live_svelte).
# -----------------------------------------------------------------------------
FROM elixir-base AS elixir-build

# Download litestream from jonnify distribution server
ARG JONNIFY_URL=https://jonnify.fly.dev
RUN curl -fsSL "${JONNIFY_URL}/distr/litestream/litestream-0.5.5.tar.gz" | tar -xzf - -C /usr/local/bin/

# Copy umbrella root and apps (mix.lock is at umbrella root)
COPY mix.exs mix.lock ./
COPY config config
COPY apps/echo/mix.exs apps/echo/
COPY apps/echo/config apps/echo/config
COPY apps/live_svelte/mix.exs apps/live_svelte/
COPY apps/live_svelte/lib apps/live_svelte/lib
COPY apps/live_svelte/README.md apps/live_svelte/

# Install and compile dependencies from umbrella root
RUN mix deps.get --only prod
RUN mix deps.compile

# Copy echo application code
COPY apps/echo/lib apps/echo/lib
COPY apps/echo/priv apps/echo/priv

# Compile echo application
WORKDIR /app/apps/echo
RUN mix compile

# Copy built assets from Node.js build stage
# Client bundle (browser)
COPY --from=node-build /app/priv/static/assets priv/static/assets
# Server bundle (Node 22 SSR for LiveSvelte)
COPY --from=node-build /app/priv/svelte priv/svelte

# Create digested assets with cache_manifest.json for production
RUN mix phx.digest

# Build release
RUN mix release

# -----------------------------------------------------------------------------
# Stage 6: Runtime (using Debian slim for better DNS/network compatibility)
# Note: Alpine's musl libc has known issues with IPv6-only networks like Fly.io
# -----------------------------------------------------------------------------
FROM node:${NODE_VERSION}-bookworm-slim AS runtime

LABEL fly_launch_runtime="Echo/Phoenix + Fastify Workers"

# Install runtime dependencies for Elixir
# Note: Node.js is already in the base image
# psmisc provides 'fuser' for killing processes by port (worker restart cleanup)
# sqlite3 needed for packages.db bootstrap seeding
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    libstdc++6 \
    openssl \
    libncurses6 \
    curl \
    ca-certificates \
    bash \
    procps \
    psmisc \
    sqlite3 \
    && rm -rf /var/lib/apt/lists/*

# Set locale
ENV LANG=C.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=C.UTF-8

# Create app user (Debian style)
RUN groupadd -g 1001 app && \
    useradd -u 1001 -g app -m app

WORKDIR /app

# FWHD v3: Create packages directory for DistrWatcher mode
# When DISTR_WATCH_ENABLED=true, flyer sync downloads packages here
RUN mkdir -p ./packages && chown app:app ./packages

# FWHD v3: Create data directory for packages.db (SQLitestream)
# Must be created before USER switch for permission
RUN mkdir -p ./data && chown app:app ./data

# FWHD v3: Download flyer CLI from jonnify distribution server
ARG JONNIFY_URL=https://jonnify.fly.dev
RUN curl -fsSL "${JONNIFY_URL}/distr/flyer/flyer-latest-linux-amd64.tar.gz" | tar -xzf - -C /usr/local/bin/ && \
    mv /usr/local/bin/flyer-linux-amd64 /usr/local/bin/flyer && \
    chmod +x /usr/local/bin/flyer

# Copy seed data for packages.db bootstrap
COPY data/seed.sql /tmp/seed.sql

USER app

# -----------------------------------------------------------------------------
# FWHD v3: Bootstrap packages.db with seed data
# -----------------------------------------------------------------------------
# Initialize packages.db schema and seed with initial release data
# This enables first-boot workers without needing Litestream restore
RUN flyer db init --db ./data/packages.db && \
    sqlite3 ./data/packages.db < /tmp/seed.sql && \
    echo "packages.db bootstrapped:"  && \
    sqlite3 ./data/packages.db "SELECT component, release_id FROM active_versions;"

# -----------------------------------------------------------------------------
# Copy Elixir Release
# -----------------------------------------------------------------------------
COPY --from=elixir-build --chown=app:app /app/_build/prod/rel/echo ./echo

# -----------------------------------------------------------------------------
# FWHD v3: Backend loaded from Tigris S3 at startup
# -----------------------------------------------------------------------------
# NOTE: Backend is NOT copied from build stage!
# The Fastify backend is downloaded at startup via flyer sync:
#   1. Litestream restores packages.db from Tigris S3
#   2. flyer sync reads active_versions and downloads tarballs
#   3. Workers extracted to /app/packages/{version}/
#   4. Symlink created: /app/packages/current -> /app/packages/{version}/
#   5. Echo starts with workers already ready
#
# DistrWatcher GenServer monitors packages.db for version changes
# and triggers rolling restart via PackageManager.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Copy Startup Script and Config Files
# -----------------------------------------------------------------------------
COPY --chown=app:app scripts/start.sh ./start.sh
COPY --chown=app:app scripts/inetrc ./inetrc
RUN chmod +x ./start.sh

# -----------------------------------------------------------------------------
# FWHD v3: SQLitestream Configuration
# -----------------------------------------------------------------------------
# Litestream config for SQLite replication to Tigris S3
COPY --chown=app:app litestream.yml ./litestream.yml

# Flyer config for FWHD package sync (S3 bucket, paths, timeouts)
COPY --chown=app:app flyer.conf ./flyer.conf

# Copy Litestream binary from build stage
COPY --from=elixir-build /usr/local/bin/litestream /usr/local/bin/litestream

# -----------------------------------------------------------------------------
# Environment (FWHD v3 Configuration)
# -----------------------------------------------------------------------------
ENV PORT=4000
ENV PHX_SERVER=true
ENV FASTIFY_PORT=6003
# FWHD: Worker path - static mode uses /app/workers/backend
# DistrWatcher mode (DISTR_WATCH_ENABLED=true) uses /app/packages/current
ENV WORKER_PATH=/app/workers/backend
ENV ENTRY_POINT=dist/index.js
# FWHD: DistrWatcher for Tigris S3 hot deployment (disabled by default)
# When enabled, flyer sync downloads packages before Echo starts
ENV DISTR_WATCH_ENABLED=false

# Expose ports (Echo:4000, Fastify API:6003)
EXPOSE 4000 6003

# Health check targets Echo
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:4000/health || exit 1

# Start Echo (which supervises Fastify workers)
CMD ["./start.sh"]
