#!/usr/bin/env bash
# Step 7 — echo/ umbrella dependencies: `mix deps.get`. Tries the normal fetch; if a
# TLS-intercepting egress proxy resets Erlang's client to repo.hex.pm, falls back to
# the local Hex mirror (hex_offline_mirror.sh) which serves curl-fetched bytes.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BENCH_HOME="${BENCH_HOME:-$HOME/.bcs-bench}"; [ -f "$BENCH_HOME/.bcs-env" ] && . "$BENCH_HOME/.bcs-env"
UMBRELLA="${UMBRELLA:-$REPO_ROOT/echo}"
[ -f "$UMBRELLA/mix.exs" ] || { echo "   ERROR: no umbrella at $UMBRELLA (clone step first)"; exit 2; }
[ -n "${MIX_REBAR3:-}" ] && export MIX_REBAR3
export HEX_CACERTS_PATH="${HEX_CACERTS_PATH:-/etc/ssl/certs/ca-certificates.crt}"
cd "$UMBRELLA"
mix local.hex --force >/dev/null 2>&1 || mix archive.install github hexpm/hex branch latest --force >/dev/null 2>&1 || true
mix local.rebar --force >/dev/null 2>&1 || true

echo "== umbrella deps (mix deps.get) =="
if mix deps.get </dev/null && [ "$(ls deps 2>/dev/null | wc -l)" -gt 0 ]; then
  echo "   deps fetched -> $(ls deps | wc -l) packages"
else
  echo "   direct fetch failed/empty (egress proxy?) — falling back to the local Hex mirror"
  bash "$HERE/hex_offline_mirror.sh"
fi
