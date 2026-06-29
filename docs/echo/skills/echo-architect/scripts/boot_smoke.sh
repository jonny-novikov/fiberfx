#!/usr/bin/env bash
# Step 9 — boot smoke. Runs compiled engine code WITHOUT the supervision tree (no
# Postgres/Valkey needed): mint a branded id in every namespace and score a guess.
# Proves the build is runnable. Output goes to $BENCH_HOME/smoke.log (and stdout).
set -uo pipefail
BENCH_HOME="${BENCH_HOME:-$HOME/.bcs-bench}"; [ -f "$BENCH_HOME/.bcs-env" ] && . "$BENCH_HOME/.bcs-env"
UMBRELLA="${UMBRELLA:-$REPO_ROOT/echo}"
[ -n "${MIX_REBAR3:-}" ] && export MIX_REBAR3
export ELIXIR_ERL_OPTIONS="+fnu" LANG="${LANG:-C.UTF-8}"
echo "== boot smoke (no DB/Valkey) =="
cd "$UMBRELLA"
mix run --no-start -e '
  EchoData.Snowflake.start(1)
  for ns <- ~w(GAM ROM PLR SES JOB GES) do
    id = EchoData.BrandedId.generate!(ns)
    {:ok, got, _} = EchoData.BrandedId.parse(id)
    IO.puts(">> #{ns} -> #{id}  (parsed ns=#{got}, len=#{byte_size(id)})")
  end
  p = Codemojex.Scoring.score(~w(0000 0101 0202 0303 0404 0505), ~w(0000 0101 0202 0303 0404 0505))
  IO.puts(">> Scoring.score perfect: #{inspect(p)}")
' </dev/null 2>/dev/null | grep '^>>' | tee "$BENCH_HOME/smoke.log"
