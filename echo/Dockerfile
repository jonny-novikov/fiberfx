# =============================================================================
# Codemojex release image.
# Pinned to this umbrella's toolchain (Elixir 1.18.4 / OTP 28.5.0.1). Umbrella-ROOT
# build of the `codemojex` app (the Telegram Mini App Phoenix surface) plus its
# in-umbrella deps (echo_mq · echo_data · echo_wire); echo_bot, echo_store and
# echo_graft are EXCLUDED (each its own concern). A slim runtime stage is added on a
# node:*-bookworm-slim base — `node` is reserved for a forthcoming Node worker; the
# build itself is Elixir-only. The release name is `codemojex` (the OTP artifact;
# INDEPENDENT of the Fly app `codemoji-phoenix`).
# -----------------------------------------------------------------------------
# Stage: Elixir Base (Debian for glibc compatibility with the runtime stage)
# Tag format: hexpm/elixir:1.18.4-erlang-28.5.0.1-debian-bookworm-20260518
# =============================================================================
ARG ELIXIR_VERSION=1.18.4
ARG OTP_VERSION=28.5.0.1
ARG DEBIAN_DATE=20260518
# NODE_VERSION — the runtime stage's Node major. Declared as a GLOBAL ARG (before any FROM) carrying the
# default `22`; re-declared (bare `ARG NODE_VERSION`) just before the runtime stage so its value is in
# scope for `FROM node:${NODE_VERSION}-bookworm-slim` (multi-stage ARG scoping — a global ARG's value
# reaches a later FROM only through that bare re-declaration). The runtime base ships `node` so a
# forthcoming Node worker can run alongside the BEAM release; this build stays Elixir-only — there is no
# `npm`/`vite` step in this image (nothing JS is built or fetched here yet).
ARG NODE_VERSION=22

FROM hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-bookworm-${DEBIAN_DATE} AS elixir-base

WORKDIR /app
ENV MIX_ENV=prod

# Install build dependencies for echo_data's OPTIONAL native codec (built from its native/Makefile — it is
# NOT a mix/hex dep, so `mix compile` never triggers it; it must be `make`'d explicitly below).
# `build-essential` provides gcc + make for the `echo_native.c` NIF shim; `rustc` (Debian's crate-less
# compiler — branded_id.rs is `no_std` with no external crates, so no Cargo and no network) builds the
# Rust core `libbranded_rs.so`; `erl_nif.h` ships inside the hexpm image's ERTS so no header package is
# needed; `git` covers any git-sourced dep. The codec stays OPTIONAL at runtime — EchoData.Native falls
# back to pure Elixir if the .so is absent — but we build it here so the release ships the accelerated path.
# (To drop the rustc dependency, use the gcc-only C core: `make -C apps/echo_data/native c-core` below.)
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    rustc \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# =============================================================================
# Stage: Elixir Build (umbrella-root build of the codemojex app + its in-umbrella deps)
# =============================================================================
FROM elixir-base AS elixir-build

# Copy the umbrella root manifest + lockfile + shared config (mix.lock + config live
# at the umbrella root, not under an app).
COPY mix.exs mix.lock ./
COPY config config

# Copy ONLY the codemojex app + its in-umbrella deps' mix.exs so dependency resolution sees the umbrella
# shape. Excluding echo_store keeps its exqlite (a C-NIF dep) out of the resolved tree — the codemojex
# release does not need it.
COPY apps/codemojex/mix.exs apps/codemojex/
COPY apps/echo_mq/mix.exs apps/echo_mq/
COPY apps/echo_data/mix.exs apps/echo_data/
COPY apps/echo_wire/mix.exs apps/echo_wire/

# Resolve + compile prod deps from the umbrella root.
RUN mix deps.get --only prod
RUN mix deps.compile

# Copy the app + its in-umbrella deps' source. codemojex carries a priv/ (the Ecto migrations); echo_data
# carries native/ (the optional codec sources — branded_id.rs / echo_native.c / Makefile);
# echo_wire/echo_mq are lib-only.
COPY apps/echo_wire/lib apps/echo_wire/lib
COPY apps/echo_data/lib apps/echo_data/lib
COPY apps/echo_data/native apps/echo_data/native
COPY apps/echo_mq/lib apps/echo_mq/lib
COPY apps/codemojex/lib apps/codemojex/lib
COPY apps/codemojex/priv apps/codemojex/priv

# Compile from the umbrella ROOT (NOT `cd apps/codemojex`). No `mix phx.digest` step: the codemojex
# endpoint serves no static asset bundle (the Mini App is JSON + a `/socket` channel, with no Plug.Static),
# so there is nothing to digest.
RUN mix compile

# Build echo_data's native codec BEFORE assembling the release so `mix release` packs it. The default `all`
# target compiles branded_id.rs -> apps/echo_data/priv/libbranded_rs.so (rustc) and links echo_native.c ->
# apps/echo_data/priv/echo_native.so (gcc, against the ERTS headers, rpath $ORIGIN so the NIF finds the Rust
# cdylib beside it). Both .so live in echo_data's priv/, which the release packs; EchoData.Native loads
# echo_native at boot and BrandedId.self_check!/0 asserts the native + pure-Elixir paths agree.
RUN make -C apps/echo_data/native

RUN mix release codemojex

# Re-declare the global ARG NODE_VERSION (bare, no default — it inherits the global value `22`, or a
# `--build-arg`/fly.toml `[build.args]` override) so it is in scope for the runtime stage's `FROM` below.
# A global ARG declared before the first FROM does NOT carry into a later FROM without this bare
# re-declaration (multi-stage ARG scoping); the build-stage FROMs do not need it because
# ELIXIR_VERSION/OTP_VERSION/DEBIAN_DATE are consumed by the FIRST FROM.
ARG NODE_VERSION

# =============================================================================
# Stage: Runtime (slim Debian + Node; the release + its shared-object deps + node)
# =============================================================================
# Based on `node:${NODE_VERSION}-bookworm-slim` (rather than `debian:bookworm-slim`). The official
# `node:*-bookworm-slim` images ARE `debian:bookworm-slim` + a pinned Node — same Debian Bookworm userland
# and glibc, so the OTP release (built against bookworm) stays binary-compatible and the OTP apt libs below
# install unchanged. `node` is carried for a forthcoming Node worker that will run alongside the BEAM
# release; it is NOT a build toolchain (no npm/vite in this stage). This stage carries no Elixir toolchain
# (it stayed in the build stage).
FROM node:${NODE_VERSION}-bookworm-slim AS runtime

# The OTP runtime needs these shared libraries (no Elixir/Rust build toolchain in this stage; the
# node:*-bookworm-slim base supplies node + the Debian Bookworm userland, but NOT these OTP libs).
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
COPY --from=elixir-build /app/_build/prod/rel/codemojex ./

# File ERL_INETRC=/app/inetrc points at — Erlang's Fly IPv6 DNS resolver config
# (native -> file -> dns, with Fly's fdaa::3 nameserver). Copied AFTER `WORKDIR /app`
# so it lands at /app/inetrc, and AFTER the release COPY (a directory COPY merges and
# will not overwrite it). Runs as root — no --chown (this stage creates no `app` user),
# matching how the release itself is copied.
COPY infra/inetrc /app/inetrc

EXPOSE 4000

# The release binary. (Ecto migrations live in apps/codemojex/priv/repo/migrations; once a release
# migrate task exists they run via `bin/codemojex eval` before this start — none is defined yet.)
ENTRYPOINT ["bin/codemojex", "start"]
