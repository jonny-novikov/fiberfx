#!/bin/sh
# Inject the password and any memory/port override from the environment, so
# nothing secret is baked into the image. CLI args override the conf file.
#
#   VALKEY_PASSWORD   required in production — sets requirepass
#   VALKEY_MAXMEMORY  optional — overrides the conf's maxmemory (bump with RAM)
#   VALKEY_PORT       optional — overrides the conf's port (default 6390)
set -eu

if [ "${1:-}" = "valkey-server" ]; then
  if [ -n "${VALKEY_PASSWORD:-}" ]; then
    set -- "$@" --requirepass "${VALKEY_PASSWORD}"
  fi
  if [ -n "${VALKEY_MAXMEMORY:-}" ]; then
    set -- "$@" --maxmemory "${VALKEY_MAXMEMORY}"
  fi
  if [ -n "${VALKEY_PORT:-}" ]; then
    set -- "$@" --port "${VALKEY_PORT}"
  fi
fi

exec "$@"
