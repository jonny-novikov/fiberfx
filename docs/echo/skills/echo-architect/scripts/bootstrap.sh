#!/usr/bin/env bash
# echo-mq-architect bootstrap — ALL STEPS run on the first call, in order. Each
# step is idempotent (detect-and-reuse / skip-if-present), so re-running is a fast
# verify. Tools install out of the box; Valkey is the one deliberate exception —
# it is BUILT FROM SOURCE at the pinned 9.1.0 (bundled jemalloc).
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "######################################################################"
echo "# echo-mq-architect :: bootstrap (all steps mandatory, idempotent)    #"
echo "######################################################################"

. "$HERE/setup_env.sh"            # 1  env (+ $REPO_ROOT)
bash "$HERE/clone_repo.sh"        # 2  git clone --branch echo_mq (ssh, https fallback)
bash "$HERE/install_apt.sh"       # 3  gcc + python + base
bash "$HERE/install_valkey.sh"    # 4  Valkey 9.1.0 FROM SOURCE + cli, started on :6390
bash "$HERE/install_postgres.sh"  # 4b PostgreSQL, started, dev role
bash "$HERE/install_go.sh"        # 5  go 1.25
bash "$HERE/install_node.sh"      # 6  node 22+ , corepack, pnpm
bash "$HERE/install_beam.sh"      # 6b elixir (>=1.15, pin 1.18.4) + erlang + rebar3 + hex
. "$BENCH_HOME/.bcs-env"          #    pick up any PATH/MIX_REBAR3 the beam step persisted
bash "$HERE/umbrella_deps.sh"     # 7  mix deps.get (mirror fallback on a blocking proxy)
bash "$HERE/compile.sh"           # 7b mix compile (whole umbrella incl codemojex)
bash "$HERE/migrate.sh"           # 7c ecto.create + migrate (codemojex_dev)
python3 "$HERE/verify.py" || true # 8  verify table (non-fatal; report records it)
bash "$HERE/boot_smoke.sh"        # 9  boot smoke: mint 6 namespaces + score (no services)
bash "$HERE/e2e.sh"               # 9b FULL e2e: boot app + play a game (Postgres + Valkey)
python3 "$HERE/report.py" --out "$REPO_ROOT/../bootstrap-report.md" \
        --smoke "$BENCH_HOME/smoke.log" --e2e "$BENCH_HOME/e2e.log"   # 10 MANDATORY md report

echo
echo "== ready =="
echo "   repo:     ${REPO_ROOT}"
echo "   umbrella: ${UMBRELLA}   (Postgres :5432, Valkey :6390)"
echo "   report:   ${REPO_ROOT}/../bootstrap-report.md   (attach this)"
