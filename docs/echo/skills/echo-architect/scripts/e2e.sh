#!/usr/bin/env bash
# Step 9b — FULL e2e: boot the app against Postgres + Valkey and drive a real game
# (seed -> free room -> funded player -> join -> submit -> async SCORED -> reads).
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BENCH_HOME="${BENCH_HOME:-$HOME/.bcs-bench}"; [ -f "$BENCH_HOME/.bcs-env" ] && . "$BENCH_HOME/.bcs-env"
UMBRELLA="${UMBRELLA:-$REPO_ROOT/echo}"; [ -n "${MIX_REBAR3:-}" ] && export MIX_REBAR3
export MIX_ENV="${MIX_ENV:-dev}" ELIXIR_ERL_OPTIONS="+fnu" LANG="${LANG:-C.UTF-8}"
cp "$HERE/e2e_game.exs" "$UMBRELLA/e2e_game.exs"
echo "== e2e game (boot + play) =="
cd "$UMBRELLA"
mix run e2e_game.exs </dev/null 2>/dev/null | grep '^>>' | tee "$BENCH_HOME/e2e.log"
rm -f "$UMBRELLA/e2e_game.exs"
