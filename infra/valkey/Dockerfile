# syntax=docker/dockerfile:1
#
# Codemojex / EchoMQ — Valkey 9.x for Fly shared-cpu-2x / 1 GB.
#
# The official image is already built with the bundled jemalloc, ships the
# current security patches, and its entrypoint chowns the mounted Fly volume
# and drops from root to the valkey user. So there is no from-source build here:
# pin the version, layer the tuned conf, expose the private port. Keep a
# separate from-source Dockerfile for the benchmarking bench, where pinning the
# jemalloc and Valkey build flags is the point.
#
# The password is NOT baked in. Inject it at boot as a Fly secret:
#   fly secrets set -a codemojex-valkey \
#     VALKEY_EXTRA_FLAGS="--requirepass $(openssl rand -hex 32)"
# The image entrypoint appends VALKEY_EXTRA_FLAGS after the config file, and a
# command-line flag overrides the file, so requirepass takes effect with the
# secret never present in any image layer.

ARG VALKEY_VERSION=9.1
FROM valkey/valkey:${VALKEY_VERSION}

COPY conf/valkey.conf /usr/local/etc/valkey/valkey.conf

EXPOSE 6390

CMD ["valkey-server", "/usr/local/etc/valkey/valkey.conf"]
