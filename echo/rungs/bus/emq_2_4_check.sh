#!/usr/bin/env bash
# emq_2_4_check.sh -- the COMMITTED, re-runnable gate-ladder harness for emq.2.4
#   (the EchoMQ parity-closer; the emq.2 cluster read->ops->watch->CLOSE rung).
#
#   cd /Users/jonny/dev/jonnify/echo && bash rungs/bus/emq_2_4_check.sh
#   cd /Users/jonny/dev/jonnify/echo && LOOP_N=10 bash rungs/bus/emq_2_4_check.sh   # quick smoke
#
# WHY THIS EXISTS. The prior emq.2.4 build cycle crashed mid-Stage-4 and the
# determinism proof EVAPORATED -- a hand-run `for i in $(seq 1 100)` tee'd to a
# /tmp file that did not survive the crash, leaving a committed green-board that
# described a tree state in no commit. The Operator's directive was "Harness
# required." This script is the structural fix: a committed, executable proof
# that re-runs the WHOLE emq.2.4 gate ladder + the >=100 determinism loop + the
# multi-seed sweep + the dbsize-flat leak check and emits a PASS/FAIL board, so
# the green-board is reproducible by anyone and a crash cannot evaporate it.
# It is the `<rung>_check` sibling of echo/rungs/bus/bcs_rung_3_5_check.exs and
# echo/rungs/exchange/trd_9_1_1_check.exs -- a shell harness (the convention
# permits one) because the determinism loop, the multi-seed sweep, and the
# dbsize-before/after are native shell constructs and the loop must OWN the
# machine (no parent BEAM holding _build / competing for memory with the 100
# suites under test).
#
# IT ASSERTS NOTHING ABOUT THE CODE IT DOES NOT RUN. Each gate is a real
# subprocess (asdf / redis-cli / mix / a Conformance.run/2 one-liner over a live
# 6390); the board reports only what the run observed. It edits no code -- the
# emq.2.4 code is already committed + Director-gate-verified GREEN (commits
# 92a8f042 obliterate-fix, 7c2f2405 docs, 3298e4bc closer).
#
# THE GATE LADDER (the program law .claude/skills/echo-mq-program.md, bound to
# emq.2.4):
#   1. toolchain    -- asdf current erlang (from apps/echo_mq) + redis-cli -p 6390 ping -> PONG
#   2. compile      -- TMPDIR=/tmp mix compile --warnings-as-errors (clean)
#   3. suite        -- TMPDIR=/tmp mix test --include valkey  (0 failures; 4 doctests / 250 tests)
#   4. conformance  -- EchoMQ.Conformance.run/2 over a live 6390 -> {:ok, 43}
#   5. determinism  -- the >=100 loop over the PROCESS-touching depth suites
#                      (watch_depth + admin_depth + conformance_run -- the timer/mint
#                      surface): assert LOOP_N/LOOP_N green. Owns the machine.
#   6. seed sweep   -- seeds 0 1 42 312540 999999 over the SYNCHRONOUS read/ops depth
#                      suites (metrics_depth, admin_depth, rate_consult, dedup_bound):
#                      assert all pass (order-dependence catch; re-seeding does NOT
#                      reproduce a same-ms mint collision -- that is gate 5's job).
#   7. leak         -- redis-cli -p 6390 dbsize before == after the loop (no key
#                      accumulation). The absolute number FLOATS run to run (Valkey
#                      residue); only the DELTA across this run is asserted flat.
#
# EXPECTED-NOT-A-FAILURE: a single captured-log line
#   "[error] GenServer ... terminating ... (stop) ... killed"
# in gate 3/5 is the reconnect-kill DRILL of the watch_depth :resubscribe / Events
# -across-a-reconnect scenario, NOT a test failure -- ExUnit still reports 0
# failures. The board keys off the ExUnit "0 failures" summary + the exit code,
# never a grep for "error" in the captured log.
#
# Spec: docs/echo_mq/specs/emq.2.4.md ; the green-board: docs/echo_mq/emq.testing.md.
# Reproducible: re-running yields the same board (the same commands, the same
# pinned counts); only timing-jitter numbers (wall seconds) vary.

set -u
set -o pipefail

# ---- resolve the umbrella root (this script lives at <root>/echo/rungs/bus/) ----
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ECHO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"   # .../jonnify/echo
APP_DIR="${ECHO_ROOT}/apps/echo_mq"
cd "${ECHO_ROOT}" || { echo "FATAL: cannot cd ${ECHO_ROOT}"; exit 2; }

export TMPDIR=/tmp
PORT=6390
LOOP_N="${LOOP_N:-100}"                 # the committed default is 100; LOOP_N=10 for a smoke
SEEDS=(0 1 42 312540 999999)

# the process-touching depth suites -- the >=100 loop's machine (timer/mint surface)
PROC_SUITES=(
  test/watch_depth_test.exs
  test/admin_depth_test.exs
  test/conformance_run_test.exs
)
# the synchronous read/ops depth suites -- the multi-seed sweep's surface
SYNC_SUITES=(
  test/metrics_depth_test.exs
  test/admin_depth_test.exs
  test/rate_consult_test.exs
  test/dedup_bound_test.exs
)

PASS=0
FAIL=0
declare -a BOARD=()

emit() {  # emit <tag> <ok|FAIL> <detail>
  local tag="$1" verdict="$2" detail="$3"
  if [ "${verdict}" = "ok" ]; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); fi
  printf '%-16s %-4s -- %s\n' "${tag}" "${verdict}" "${detail}"
  BOARD+=("${tag} ${verdict}")
}

# run `mix test` on a list of suites for one seed; echo the ExUnit summary line;
# return the mix exit code. stderr folded in so the captured-log drill is visible.
run_suites() {  # run_suites <seed> <suite...>
  local seed="$1"; shift
  ( cd "${APP_DIR}" && TMPDIR=/tmp mix test --include valkey --seed "${seed}" "$@" ) 2>&1
}

echo "header: emq.2.4 parity-closer gate ladder | $(cd "${APP_DIR}" && elixir -e 'IO.write(System.version())' 2>/dev/null) Elixir / OTP $(erl -noshell -eval 'io:format("~s",[erlang:system_info(otp_release)]), halt().' 2>/dev/null) | Valkey :${PORT} | LOOP_N=${LOOP_N} | $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "----------------------------------------------------------------------"

# == gate 1: toolchain ===============================================================
ERL_LINE="$(cd "${APP_DIR}" && asdf current erlang 2>/dev/null | awk '$1=="erlang"{print $2}')"
PING="$(redis-cli -p "${PORT}" ping 2>/dev/null)"
if [ "${ERL_LINE}" = "28.5.0.1" ] && [ "${PING}" = "PONG" ]; then
  emit "toolchain" ok "asdf resolves erlang ${ERL_LINE} inside apps/echo_mq (the .tool-versions pin, the build dir -- not the repo-root global) and Valkey answers PING -> PONG on :${PORT} (the live engine, not the 6379 default)"
else
  emit "toolchain" FAIL "erlang='${ERL_LINE}' (want 28.5.0.1, re-probed from apps/echo_mq) ; redis-cli -p ${PORT} ping='${PING}' (want PONG)"
fi

# == gate 2: compile --warnings-as-errors ============================================
COMPILE_OUT="$(cd "${APP_DIR}" && TMPDIR=/tmp mix compile --warnings-as-errors 2>&1)"
COMPILE_RC=$?
if [ "${COMPILE_RC}" -eq 0 ] && ! echo "${COMPILE_OUT}" | grep -qiE 'warning:|error:'; then
  emit "compile" ok "TMPDIR=/tmp mix compile --warnings-as-errors is clean in apps/echo_mq (no warning, no undefined same-app verb -- an INV2 floor: the 5 depth suites call no surface that does not compile)"
else
  emit "compile" FAIL "mix compile --warnings-as-errors rc=${COMPILE_RC}; tail: $(echo "${COMPILE_OUT}" | tail -3 | tr '\n' '|')"
fi

# == gate 3: the full :valkey suite (+ the pure / wire column split) =================
# the full suite is the --include valkey run; the two columns (pure = default, the
# :valkey suites excluded; wire = --only valkey) are captured in the same gate so the
# green-board's compile+suites table is fully harness-observed, never hand-typed.
SUITE_OUT="$(run_suites 0 )"          # no suite args == the whole app suite (--include valkey)
SUITE_RC=$?
SUITE_SUMMARY="$(echo "${SUITE_OUT}" | grep -E '[0-9]+ tests?, [0-9]+ failures?' | tail -1)"
PURE_SUMMARY="$( ( cd "${APP_DIR}" && TMPDIR=/tmp mix test 2>&1 ) | grep -E '[0-9]+ tests?, [0-9]+ failures?' | tail -1)"
WIRE_SUMMARY="$( ( cd "${APP_DIR}" && TMPDIR=/tmp mix test --only valkey 2>&1 ) | grep -E '[0-9]+ tests?, [0-9]+ failures?' | tail -1)"
if [ "${SUITE_RC}" -eq 0 ] \
   && echo "${SUITE_SUMMARY}" | grep -qE ', 0 failures' \
   && echo "${PURE_SUMMARY}"  | grep -qE ', 0 failures' \
   && echo "${WIRE_SUMMARY}"  | grep -qE ', 0 failures'; then
  emit "suite" ok "TMPDIR=/tmp mix test --include valkey -> [${SUITE_SUMMARY}] in apps/echo_mq (the lone captured-log GenServer-killed line is the watch-plane reconnect-kill drill, not a failure -- ExUnit still reports 0 failures). Pure column (no :valkey) [${PURE_SUMMARY}] ; wire column (--only valkey) [${WIRE_SUMMARY}]"
else
  emit "suite" FAIL "mix test rc=${SUITE_RC}; full='${SUITE_SUMMARY:-<none>}' pure='${PURE_SUMMARY:-<none>}' wire='${WIRE_SUMMARY:-<none>}'; tail: $(echo "${SUITE_OUT}" | tail -4 | tr '\n' '|')"
fi

# == gate 4: Conformance.run/2 over a live 6390 -> {:ok, 43} ==========================
# a direct one-liner (NOT via the pin test) -- the conformance run is its own gate
# beyond the unit suites; it drives the public surface and returns {:ok, n}.
CONF_OUT="$(cd "${APP_DIR}" && TMPDIR=/tmp mix run --no-start -e '
  :ok = EchoData.Snowflake.start(43)
  {:ok, conn} = EchoMQ.Connector.start_link(port: 6390)
  q = "emq24.harness#{System.unique_integer([:positive])}"
  case EchoMQ.Conformance.run(conn, q) do
    {:ok, n} -> IO.puts("CONFORMANCE_RESULT={:ok, #{n}}")
    other    -> IO.puts("CONFORMANCE_RESULT=#{inspect(other)}")
  end
' 2>&1)"
CONF_LINE="$(echo "${CONF_OUT}" | grep -E '^CONFORMANCE_RESULT=' | tail -1)"
if [ "${CONF_LINE}" = "CONFORMANCE_RESULT={:ok, 43}" ]; then
  emit "conformance" ok "EchoMQ.Conformance.run/2 over a live :${PORT} returns {:ok, 43} -- the 18 founding+emq.1 + 6 read + 8 ops + 5 watch + 5 emq.2.4 depth (unknown_state, rate_consult, dedup_release, extend_locks_batch, stalled_group) + obliterate_grouped (the emq.2.2 fix's proving scenario); the prior 37 byte-unchanged, the 6 new probe-registered"
else
  emit "conformance" FAIL "Conformance.run/2 result='${CONF_LINE:-<none>}' (want {:ok, 43}); tail: $(echo "${CONF_OUT}" | tail -4 | tr '\n' '|')"
fi

# == gate 7 (pre): dbsize BEFORE the loop ============================================
# captured here so the leak check brackets exactly the >=100 loop's mint/purge churn.
DBSIZE_BEFORE="$(redis-cli -p "${PORT}" dbsize 2>/dev/null)"

# == gate 5: the >=100 determinism loop over the process-touching depth suites =======
# the loop OWNS the machine. one green run is NOT proof and 20 is too few: a
# same-millisecond branded-id mint collision flakes only ACROSS runs (echo/CLAUDE.md
# section 4). the loop re-runs the timer/mint surface LOOP_N times; the FIRST red
# iteration breaks and is reported.
LOOP_PASS=0
LOOP_FIRST_FAIL=0
LOOP_FAIL_TAIL=""
for i in $(seq 1 "${LOOP_N}"); do
  ITER_OUT="$(run_suites 0 "${PROC_SUITES[@]}")"
  ITER_RC=$?
  if [ "${ITER_RC}" -eq 0 ] && echo "${ITER_OUT}" | grep -qE ', 0 failures'; then
    LOOP_PASS=$((LOOP_PASS+1))
  else
    LOOP_FIRST_FAIL="${i}"
    LOOP_FAIL_TAIL="$(echo "${ITER_OUT}" | tail -4 | tr '\n' '|')"
    break
  fi
done
if [ "${LOOP_PASS}" -eq "${LOOP_N}" ]; then
  emit "determinism" ok "the >=100 determinism loop is ${LOOP_PASS}/${LOOP_N} green over the process-touching depth suites (watch_depth + admin_depth + conformance_run -- the timer/mint surface); no same-ms mint collision, no timer flake, no order race surfaced across ${LOOP_N} owning-the-machine iterations"
else
  emit "determinism" FAIL "the determinism loop went RED at iteration ${LOOP_FIRST_FAIL}/${LOOP_N} (${LOOP_PASS} green before it); tail: ${LOOP_FAIL_TAIL}"
fi

# == gate 7: dbsize AFTER == BEFORE (the leak check) =================================
DBSIZE_AFTER="$(redis-cli -p "${PORT}" dbsize 2>/dev/null)"
if [ -n "${DBSIZE_BEFORE}" ] && [ "${DBSIZE_BEFORE}" = "${DBSIZE_AFTER}" ]; then
  emit "leak" ok "redis-cli -p ${PORT} dbsize is FLAT across the loop: ${DBSIZE_BEFORE} before == ${DBSIZE_AFTER} after (the depth suites purge what they mint; no key accumulation -- obliterate clears grouped rows, the locks/stalled/events keys are cleaned). The absolute count floats run-to-run (Valkey residue); only the delta is asserted"
else
  emit "leak" FAIL "dbsize drifted across the loop: ${DBSIZE_BEFORE:-<none>} before -> ${DBSIZE_AFTER:-<none>} after (a key leak: a suite minted keys it did not purge)"
fi

# == gate 6: the multi-seed sweep over the synchronous read/ops depth suites =========
# varies TEST ORDERING (catches order-dependent bugs); a complement to the loop,
# not a substitute (re-seeding does NOT re-create the same-ms mint collision).
SWEEP_PASS=0
SWEEP_FAIL_SEED=""
SWEEP_FAIL_TAIL=""
for s in "${SEEDS[@]}"; do
  SEED_OUT="$(run_suites "${s}" "${SYNC_SUITES[@]}")"
  SEED_RC=$?
  if [ "${SEED_RC}" -eq 0 ] && echo "${SEED_OUT}" | grep -qE ', 0 failures'; then
    SWEEP_PASS=$((SWEEP_PASS+1))
  else
    SWEEP_FAIL_SEED="${s}"
    SWEEP_FAIL_TAIL="$(echo "${SEED_OUT}" | tail -4 | tr '\n' '|')"
    break
  fi
done
if [ "${SWEEP_PASS}" -eq "${#SEEDS[@]}" ]; then
  emit "seed-sweep" ok "the multi-seed sweep is ${SWEEP_PASS}/${#SEEDS[@]} green over the synchronous read/ops depth suites (metrics_depth, admin_depth, rate_consult, dedup_bound) across seeds ${SEEDS[*]} -- no order-dependent bug in the deterministic round-trips"
else
  emit "seed-sweep" FAIL "the seed sweep went RED at seed ${SWEEP_FAIL_SEED} (${SWEEP_PASS}/${#SEEDS[@]} green before it); tail: ${SWEEP_FAIL_TAIL}"
fi

# == the board ======================================================================
echo "----------------------------------------------------------------------"
if [ "${FAIL}" -eq 0 ]; then
  echo "PASS ${PASS}/$((PASS+FAIL)) -- emq.2.4 gate ladder GREEN + harness-reproducible"
  exit 0
else
  echo "FAIL ${FAIL}/$((PASS+FAIL)) gate(s) red (PASS ${PASS})"
  exit 1
fi
