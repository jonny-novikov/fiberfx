#!/usr/bin/env bash
#
# fly-valkey.sh — connect to the production echo-valkey (Fly, private 6PN node)
# and run valkey-cli through a temporary `fly proxy` tunnel.
#
# echo-valkey is private-by-design: it has no public address and requires a
# password (`--requirepass`, shipped via the VALKEY_EXTRA_FLAGS secret). This
# script opens a short-lived `fly proxy` to its :6390, authenticates with the
# password from infra/valkey/.env.production, runs your valkey-cli command, and
# always tears the tunnel back down. The secret is read at runtime and never
# printed.
#
# Usage:
#   scripts/fly-valkey.sh                        # interactive valkey-cli
#   scripts/fly-valkey.sh PING                   # one-shot command
#   scripts/fly-valkey.sh GET '{emq}:version'    # read the EchoMQ wire fence
#
# Env overrides (all optional):
#   FLY_VALKEY_APP          (default: echo-valkey)
#   FLY_VALKEY_REMOTE_PORT  (default: 6390)
#   FLY_VALKEY_LOCAL_PORT   (default: 6399 — kept off the local dev :6390)
#   FLY_VALKEY_ENV          (default: <repo>/infra/valkey/.env.production)
#
set -euo pipefail

APP="${FLY_VALKEY_APP:-echo-valkey}"
REMOTE_PORT="${FLY_VALKEY_REMOTE_PORT:-6390}"
LOCAL_PORT="${FLY_VALKEY_LOCAL_PORT:-6399}"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${FLY_VALKEY_ENV:-$REPO_ROOT/infra/valkey/.env.production}"

[[ -f "$ENV_FILE" ]] || { echo "fly-valkey: env file not found: $ENV_FILE" >&2; exit 1; }

# Load creds (never echoed). VALKEY_PASSWORD wins; otherwise pull the password
# out of `--requirepass <pw>` inside VALKEY_EXTRA_FLAGS.
set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

PASS="${VALKEY_PASSWORD:-}"
if [[ -z "$PASS" && -n "${VALKEY_EXTRA_FLAGS:-}" ]]; then
  PASS="$(printf '%s' "$VALKEY_EXTRA_FLAGS" | sed -nE 's/.*--requirepass[[:space:]=]+([^[:space:]]+).*/\1/p')"
fi
[[ -n "$PASS" ]] || { echo "fly-valkey: no VALKEY_PASSWORD / --requirepass in $ENV_FILE" >&2; exit 1; }

# Bring the tunnel up in the background; always tear it down (and drop the log).
PROXY_LOG="$(mktemp -t fly-valkey-proxy.XXXXXX)"
fly proxy "${LOCAL_PORT}:${REMOTE_PORT}" -a "$APP" >"$PROXY_LOG" 2>&1 &
PROXY_PID=$!
cleanup() {
  kill "$PROXY_PID" 2>/dev/null || true
  wait "$PROXY_PID" 2>/dev/null || true
  rm -f "$PROXY_LOG"
}
trap cleanup EXIT INT TERM

# Wait (bounded) until the tunnel accepts an authenticated PING.
ready=0
for _ in $(seq 1 40); do
  if valkey-cli -p "$LOCAL_PORT" -a "$PASS" --no-auth-warning ping >/dev/null 2>&1; then
    ready=1
    break
  fi
  sleep 0.5
done
if [[ "$ready" -ne 1 ]]; then
  echo "fly-valkey: tunnel to ${APP}:${REMOTE_PORT} did not come up" >&2
  cat "$PROXY_LOG" >&2 || true
  exit 1
fi

# Run the requested command, or drop into an interactive CLI when none given.
# (No `exec`, so the EXIT trap still fires and reaps the proxy.)
valkey-cli -p "$LOCAL_PORT" -a "$PASS" --no-auth-warning "$@"
