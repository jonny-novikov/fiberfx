#!/usr/bin/env bash
# Step 7c — create the dev database and run migrations (codemojex_dev).
set -uo pipefail
BENCH_HOME="${BENCH_HOME:-$HOME/.bcs-bench}"; [ -f "$BENCH_HOME/.bcs-env" ] && . "$BENCH_HOME/.bcs-env"
UMBRELLA="${UMBRELLA:-$REPO_ROOT/echo}"; [ -n "${MIX_REBAR3:-}" ] && export MIX_REBAR3
export MIX_ENV="${MIX_ENV:-dev}" ELIXIR_ERL_OPTIONS="+fnu" LANG="${LANG:-C.UTF-8}"
echo "== ecto.create + migrate =="
cd "$UMBRELLA"
mix ecto.create
mix ecto.migrate
