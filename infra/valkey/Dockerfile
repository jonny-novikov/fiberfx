# syntax=docker/dockerfile:1
###############################################################################
# Valkey for Codemojex / EchoMQ — built from source with the bundled jemalloc
# (5.3.0 on the 8.x line, matching the benchmarking bench), tuned for a Fly
# shared-cpu-2x machine with 1 GB RAM.
#
# Two stages: compile valkey-server + valkey-cli, then ship them on a slim
# runtime with the tuned conf and an entrypoint that injects the password and
# any memory/port override from the environment.
###############################################################################

# Pin to a current stable tag from https://github.com/valkey-io/valkey/releases
ARG VALKEY_VERSION=9.1
ARG DEBIAN_TAG=bookworm-slim

# ---- build ------------------------------------------------------------------
FROM debian:${DEBIAN_TAG} AS build
ARG VALKEY_VERSION
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      build-essential git ca-certificates pkg-config \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/valkey
RUN git clone --depth 1 --branch "${VALKEY_VERSION}" https://github.com/valkey-io/valkey.git .
# MALLOC=jemalloc builds and statically links the bundled jemalloc (5.3.0 on
# 8.x). No TLS: the Fly 6PN private network is the trust boundary — add
# BUILD_TLS=yes (and libssl-dev above) only if Valkey is ever exposed publicly.
RUN make -j "$(nproc)" MALLOC=jemalloc \
 && make install PREFIX=/usr/local \
 && /usr/local/bin/valkey-server --version

# ---- runtime ----------------------------------------------------------------
FROM debian:${DEBIAN_TAG} AS runtime
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates libatomic1 \
 && rm -rf /var/lib/apt/lists/* \
 && groupadd --system valkey \
 && useradd --system --gid valkey --home-dir /data --shell /usr/sbin/nologin valkey \
 && mkdir -p /data /usr/local/etc/valkey \
 && chown -R valkey:valkey /data

COPY --from=build /usr/local/bin/valkey-server /usr/local/bin/valkey-server
COPY --from=build /usr/local/bin/valkey-cli    /usr/local/bin/valkey-cli
COPY conf/valkey.conf            /usr/local/etc/valkey/valkey.conf
COPY docker-entrypoint.sh        /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

USER valkey
WORKDIR /data

# The EchoMQ connector dials this port over the private network.
EXPOSE 6390

# Local/compose health (Fly uses the [checks] block in fly.toml instead).
HEALTHCHECK --interval=15s --timeout=3s --start-period=10s --retries=3 \
  CMD valkey-cli -p 6390 -a "$VALKEY_PASSWORD" --no-auth-warning ping | grep -q PONG || exit 1

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["valkey-server", "/usr/local/etc/valkey/valkey.conf"]
