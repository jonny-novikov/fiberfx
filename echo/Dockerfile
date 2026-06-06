# =============================================================================
# Portal release image (F6.8.2-D2). Built FROM docs/deploy/Dockerfile.template,
# version-corrected to this umbrella's toolchain (Elixir 1.18.4 / OTP 28.5.0.1) and
# de-Codemoji'd: the template's single-app `apps/echo` build is replaced by the
# umbrella-ROOT build of the three Portal apps (portal_web · portal · echo_data),
# `echo_bot` is EXCLUDED (the out-of-band F10 bot, its own release), and a slim
# runtime stage is added (the template ENDED at `mix release`). The release name is
# `portal` (the OTP artifact; INDEPENDENT of the Fly app `echo-portal`).
# -----------------------------------------------------------------------------
# Stage: Elixir Base (Debian for glibc compatibility with the runtime stage)
# Tag format: hexpm/elixir:1.18.4-erlang-28.5.0.1-debian-bookworm-20260518
#   (OPERATOR-PINNED, Docker-Hub-verified: there is NO 1.18.4-erlang-28.1 image; the
#    published 28.x tags jump 28.0.4 -> 28.5.0.1. Dev aligns via .tool-versions.)
# =============================================================================
ARG ELIXIR_VERSION=1.18.4
ARG OTP_VERSION=28.5.0.1
ARG DEBIAN_DATE=20260518

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

# =============================================================================
# Stage: Elixir Build (umbrella-root build of the Portal apps; echo_bot excluded)
# =============================================================================
FROM elixir-base AS elixir-build

# Copy the umbrella root manifest + lockfile + shared config (mix.lock + config live
# at the umbrella root, not under an app).
COPY mix.exs mix.lock ./
COPY config config

# Copy ONLY the Portal apps' mix.exs so dependency resolution sees the umbrella shape
# without dragging in apps/echo_bot.
COPY apps/portal/mix.exs apps/portal/
COPY apps/portal_web/mix.exs apps/portal_web/
COPY apps/echo_data/mix.exs apps/echo_data/

# Resolve + compile prod deps from the umbrella root.
RUN mix deps.get --only prod
RUN mix deps.compile

# Copy the Portal apps' source (lib + priv). apps/echo_bot is NOT copied — it is
# excluded from the Portal release (F6.8.2-INV6).
COPY apps/portal/lib apps/portal/lib
COPY apps/portal/priv apps/portal/priv
COPY apps/portal_web/lib apps/portal_web/lib
COPY apps/portal_web/priv apps/portal_web/priv
COPY apps/echo_data/lib apps/echo_data/lib

# Compile from the umbrella ROOT (NOT `cd apps/echo`), digest the static assets into
# priv/static/cache_manifest.json (prod.exs names it), then assemble the release.
RUN mix compile
RUN mix phx.digest
RUN mix release portal

# =============================================================================
# Stage: Runtime (slim Debian; only the release + its shared-object deps)
# =============================================================================
FROM debian:bookworm-slim AS runtime

# The OTP runtime needs these shared libraries (no build toolchain in this stage).
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    openssl \
    libstdc++6 \
    libncurses6 \
    locales \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen \
    && locale-gen

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    MIX_ENV=prod

WORKDIR /app

# Copy ONLY the assembled release from the build stage.
COPY --from=elixir-build /app/_build/prod/rel/portal ./

EXPOSE 4000

# The release binary; the deploy runs `bin/portal eval "Portal.Release.migrate()"`
# (release-native migration, F6.8.2-D5) BEFORE this start.
ENTRYPOINT ["bin/portal", "start"]
