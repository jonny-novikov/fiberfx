#!/usr/bin/env bash
# Step 7b — compile the umbrella (deps + apps). Surfaces any Elixir/OTP
# incompatibility loudly (e.g. postgrex needing Elixir >= 1.15 on a 1.14 toolchain).
set -uo pipefail
BENCH_HOME="${BENCH_HOME:-$HOME/.bcs-bench}"; [ -f "$BENCH_HOME/.bcs-env" ] && . "$BENCH_HOME/.bcs-env"
UMBRELLA="${UMBRELLA:-$REPO_ROOT/echo}"
export HEX_CACERTS_PATH="${HEX_CACERTS_PATH:-/etc/ssl/certs/ca-certificates.crt}"
[ -n "${MIX_REBAR3:-}" ] && export MIX_REBAR3
echo "== mix compile =="
cd "$UMBRELLA"
mix compile
echo "   compiled apps: $(ls _build/dev/lib 2>/dev/null | wc -l) in _build/dev/lib"
