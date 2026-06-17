#!/usr/bin/env bash
# emq_3_1_check.sh -- the COMMITTED, re-runnable gate-ladder harness for emq.3.1
#   (the EchoMQ flow family's FIRST slice: the single-queue parent/child flow --
#   EchoMQ.Flows.add/3 + the @enqueue_flow atomic transition + the fan-in hook
#   folded into the shipped EchoMQ.Jobs.@complete).
#
#   cd /Users/jonny/dev/jonnify/echo && bash rungs/bus/emq_3_1_check.sh
#   cd /Users/jonny/dev/jonnify/echo && LOOP_N=10 bash rungs/bus/emq_3_1_check.sh   # quick smoke
#
# WHY THIS EXISTS. emq.3.1 is HIGH-RISK on two axes: it (a) edits the SHIPPED
# @complete (a regression there breaks the emq.2.x parity surface) and (b) mints
# N+1 branded JOB ids per Flows.add call (the same-millisecond mint-collision
# surface). The build + harden ran the >=100 determinism loop GREEN, but tee'd it
# only to /tmp -- the ephemeral-proof anti-pattern the emq.2.4 cycle was burned by
# (a /tmp tee that did not survive a mid-Stage-4 crash, leaving a committed
# green-board describing a tree state in no commit). This script is the structural
# fix the EVALUATOR authors (not the builder self-certifying): a committed,
# executable proof that re-runs the WHOLE emq.3.1 gate ladder + the >=100
# determinism loop over the flow suites + the two rung-specific invariant probes
# (the idempotent double-complete and the dead-child honest bound) and emits a
# PASS/FAIL board, so the green-board is reproducible by anyone and a crash cannot
# evaporate it. It is the records-DISTINCT sibling of echo/rungs/bus/emq_2_4_check.sh
# (which stays FROZEN to the emq.2.4 board: {:ok, 43} / 250 tests) -- one committed
# harness per parity rung, re-pinned to its own board.
#
# IT ASSERTS NOTHING ABOUT THE CODE IT DOES NOT RUN. Each gate is a real
# subprocess (asdf / redis-cli / mix / a Conformance.run/2 + a Flows.add round-trip
# one-liner over a live 6390); the board reports only what the run observed. It
# edits no code -- the emq.3.1 code is left in the working tree for the Director's
# single LAW-4 ratifying commit; this harness is a process/proof artifact, within
# the evaluator's charter.
#
# THE GATE LADDER (the program law .claude/skills/echo-mq-program.md, bound to
# emq.3.1):
#   1. toolchain    -- asdf current erlang (from apps/echo_mq) + redis-cli -p 6390 ping -> PONG
#   2. compile      -- TMPDIR=/tmp mix compile --warnings-as-errors (clean)
#   3. suite        -- TMPDIR=/tmp mix test --include valkey  (0 failures; 4 doctests / 265 tests)
#   4. conformance  -- EchoMQ.Conformance.run/2 over a live 6390 -> {:ok, 45}
#                      (the 43 prior byte-unchanged + flow_add + flow_fanin)
#   5. determinism  -- the >=100 loop over the flow suites (flow_add + flow_fanin --
#                      the N+1-mint + fan-in-across-completions surface): assert
#                      LOOP_N/LOOP_N green. Owns the machine.
#   6. seed sweep   -- seeds 0 1 42 312540 999999 over the flow suites (order-dependence
#                      catch; re-seeding does NOT reproduce a same-ms mint collision --
#                      that is gate 5's job).
#   7. idempotency  -- a LIVE double-complete of a flow child decrements the parent's
#                      :dependencies by EXACTLY 1 (the :gone row-retire layer, INV5):
#                      a second completion is refused :gone and the count holds.
#   8. dead-child   -- the HONEST BOUND (INV9): a flow child taken to `dead` does NOT
#                      decrement -- the parent stays awaiting_children (the failure
#                      policy is emq.3.4, named not papered over).
#
# EXPECTED-NOT-A-FAILURE: a single captured-log line
#   "[error] GenServer ... terminating ... (stop) ... killed"
# in gate 3 is the watch-plane reconnect-kill DRILL of the emq.2.3 resubscribe /
# Events-across-a-reconnect scenario, NOT a test failure -- ExUnit still reports 0
# failures. The board keys off the ExUnit "0 failures" summary + the exit code,
# never a grep for "error" in the captured log.
#
# Spec: docs/echo_mq/specs/emq.3.1.md (D2-D6, INV1-INV9) ; family: emq.3.md.
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

# the flow suites -- the >=100 loop's machine (the N+1-mint + fan-in surface) AND
# the multi-seed sweep's surface (the order-dependence complement).
FLOW_SUITES=(
  test/flow_add_test.exs
  test/flow_fanin_test.exs
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

echo "header: emq.3.1 single-queue flow gate ladder | $(cd "${APP_DIR}" && elixir -e 'IO.write(System.version())' 2>/dev/null) Elixir / OTP $(erl -noshell -eval 'io:format("~s",[erlang:system_info(otp_release)]), halt().' 2>/dev/null) | Valkey :${PORT} | LOOP_N=${LOOP_N} | $(date -u +%Y-%m-%dT%H:%M:%SZ)"
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
  emit "compile" ok "TMPDIR=/tmp mix compile --warnings-as-errors is clean in apps/echo_mq (no warning, no undefined verb -- the new EchoMQ.Flows + the @complete fan-in branch + the @state_lookup row-field branch all compile clean)"
else
  emit "compile" FAIL "mix compile --warnings-as-errors rc=${COMPILE_RC}; tail: $(echo "${COMPILE_OUT}" | tail -3 | tr '\n' '|')"
fi

# == gate 3: the full :valkey suite (+ the pure / wire column split) =================
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

# == gate 4: Conformance.run/2 over a live 6390 -> {:ok, 45} ==========================
# a direct one-liner (NOT via the pin test) -- the conformance run is its own gate
# beyond the unit suites; it drives the public surface and returns {:ok, n}. The 43
# prior scenarios byte-unchanged (incl. unknown_state -- the D4 regression risk) +
# flow_add + flow_fanin probe-registered.
CONF_OUT="$(cd "${APP_DIR}" && TMPDIR=/tmp mix run --no-start -e '
  :ok = EchoData.Snowflake.start(31)
  {:ok, conn} = EchoMQ.Connector.start_link(port: 6390)
  q = "emq31.harness#{System.unique_integer([:positive])}"
  case EchoMQ.Conformance.run(conn, q) do
    {:ok, n} -> IO.puts("CONFORMANCE_RESULT={:ok, #{n}}")
    other    -> IO.puts("CONFORMANCE_RESULT=#{inspect(other)}")
  end
' 2>&1)"
CONF_LINE="$(echo "${CONF_OUT}" | grep -E '^CONFORMANCE_RESULT=' | tail -1)"
if [ "${CONF_LINE}" = "CONFORMANCE_RESULT={:ok, 45}" ]; then
  emit "conformance" ok "EchoMQ.Conformance.run/2 over a live :${PORT} returns {:ok, 45} -- the 43 emq.2.4 scenarios byte-unchanged (incl. unknown_state, the D4 regression risk -- a row-in-no-set whose state field is not awaiting_children still reads :unknown) + flow_add + flow_fanin (the flow family's two probes, additive-minor, probe-registered in the same change)"
else
  emit "conformance" FAIL "Conformance.run/2 result='${CONF_LINE:-<none>}' (want {:ok, 45}); tail: $(echo "${CONF_OUT}" | tail -4 | tr '\n' '|')"
fi

# == gate 7 (pre): dbsize BEFORE the loop ============================================
DBSIZE_BEFORE="$(redis-cli -p "${PORT}" dbsize 2>/dev/null)"

# == gate 5: the >=100 determinism loop over the flow suites =========================
# the loop OWNS the machine. one green run is NOT proof and 20 is too few: a flow
# mints N+1 ids per call, so a same-millisecond branded-id mint collision is the
# collision-prone surface, and it flakes only ACROSS runs (echo/CLAUDE.md section 4).
# the loop re-runs the flow suites LOOP_N times; the FIRST red iteration breaks and
# is reported.
LOOP_PASS=0
LOOP_FIRST_FAIL=0
LOOP_FAIL_TAIL=""
for i in $(seq 1 "${LOOP_N}"); do
  ITER_OUT="$(run_suites 0 "${FLOW_SUITES[@]}")"
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
  emit "determinism" ok "the >=100 determinism loop is ${LOOP_PASS}/${LOOP_N} green over the flow suites (flow_add + flow_fanin -- the N+1-mint + fan-in-across-completions surface); no same-ms mint collision among the N+1 ids minted per flow, no fan-in race surfaced across ${LOOP_N} owning-the-machine iterations"
else
  emit "determinism" FAIL "the determinism loop went RED at iteration ${LOOP_FIRST_FAIL}/${LOOP_N} (${LOOP_PASS} green before it); tail: ${LOOP_FAIL_TAIL}"
fi

# == gate 7: dbsize AFTER == BEFORE (the leak check) =================================
DBSIZE_AFTER="$(redis-cli -p "${PORT}" dbsize 2>/dev/null)"
if [ -n "${DBSIZE_BEFORE}" ] && [ "${DBSIZE_BEFORE}" = "${DBSIZE_AFTER}" ]; then
  emit "leak" ok "redis-cli -p ${PORT} dbsize is FLAT across the loop: ${DBSIZE_BEFORE} before == ${DBSIZE_AFTER} after (the flow suites purge what they mint via on_exit -- the per-test sub-queue KEYS-pattern DEL). The absolute count floats run-to-run (Valkey residue); only the delta is asserted. NOTE: a flow's :dependencies/:processed subkeys outlive the parent ROW within a run -- the per-test purge sweeps them, the obliterate non-sweep is the named honest bound (Apollo T-9 / emq.3.2)"
else
  emit "leak" FAIL "dbsize drifted across the loop: ${DBSIZE_BEFORE:-<none>} before -> ${DBSIZE_AFTER:-<none>} after (a key leak: a suite minted keys its on_exit did not purge)"
fi

# == gate 6: the multi-seed sweep over the flow suites ===============================
# varies TEST ORDERING (catches order-dependent bugs); a complement to the loop,
# not a substitute (re-seeding does NOT re-create the same-ms mint collision).
SWEEP_PASS=0
SWEEP_FAIL_SEED=""
SWEEP_FAIL_TAIL=""
for s in "${SEEDS[@]}"; do
  SEED_OUT="$(run_suites "${s}" "${FLOW_SUITES[@]}")"
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
  emit "seed-sweep" ok "the multi-seed sweep is ${SWEEP_PASS}/${#SEEDS[@]} green over the flow suites (flow_add, flow_fanin) across seeds ${SEEDS[*]} -- no order-dependent bug in the flow add/fan-in round-trips"
else
  emit "seed-sweep" FAIL "the seed sweep went RED at seed ${SWEEP_FAIL_SEED} (${SWEEP_PASS}/${#SEEDS[@]} green before it); tail: ${SWEEP_FAIL_TAIL}"
fi

# == gate 7b: the idempotent double-complete (INV5) -- a LIVE Flows.add round-trip ====
# the headline HIGH-RISK property: a flow child completed TWICE decrements the
# parent's :dependencies by EXACTLY 1 (the row-retire makes the second completion
# :gone before the was_active==1 fan-in branch -- L-2). drives the public surface
# end to end (Flows.add -> claim -> complete -> complete-again).
IDEM_OUT="$(cd "${APP_DIR}" && TMPDIR=/tmp mix run --no-start -e '
  :ok = EchoData.Snowflake.start(32)
  {:ok, conn} = EchoMQ.Connector.start_link(port: 6390)
  alias EchoMQ.{Flows, Jobs, Keyspace, Connector}
  q = "emq31.harness.idem#{System.unique_integer([:positive])}"
  parent = EchoData.BrandedId.generate!("JOB")
  c1 = EchoData.BrandedId.generate!("JOB")
  {:ok, _} = Flows.add(conn, q, %{parent: %{id: parent, payload: "P"}, children: [%{id: c1, payload: "c1"}]})
  {:ok, {^c1, _, tok}} = Jobs.claim(conn, q, 60_000)
  :ok = Jobs.complete(conn, q, c1, tok)
  again = Jobs.complete(conn, q, c1, tok)            # a second completion of the same child
  {:ok, deps} = Connector.command(conn, ["GET", Keyspace.job_key(q, parent) <> ":dependencies"])
  {:ok, pend} = Connector.command(conn, ["ZSCORE", Keyspace.queue_key(q, "pending"), parent])
  released? = pend != nil                            # the parent IS a pending member (ZSCORE returns a float, not nil)
  IO.puts("IDEM_RESULT=again=#{inspect(again)} deps=#{inspect(deps)} parent_released=#{inspect(released?)}")
' 2>&1)"
IDEM_LINE="$(echo "${IDEM_OUT}" | grep -E '^IDEM_RESULT=' | tail -1)"
# the one child has fanned in: deps == "0" (the bare GET string), the parent IS
# released (a pending member -- ZSCORE returns a float, asserted not-nil), and the
# SECOND completion is refused :gone (decremented nothing further).
if echo "${IDEM_LINE}" | grep -qE 'again=\{:error, :gone\}' \
   && echo "${IDEM_LINE}" | grep -qE 'deps="0"' \
   && echo "${IDEM_LINE}" | grep -qE 'parent_released=true'; then
  emit "idempotency" ok "a flow child completed TWICE decrements the parent's :dependencies by EXACTLY 1 (INV5): the single child fans in to 0 and releases the parent (a pending member), and the SECOND completion is refused :gone -- the row-retire short-circuits before the was_active==1 fan-in branch, decrementing nothing further. [${IDEM_LINE}]"
else
  emit "idempotency" FAIL "the double-complete idempotency probe did not hold: [${IDEM_LINE:-<none>}] (want again={:error, :gone}, deps=\"0\", parent_released=true); tail: $(echo "${IDEM_OUT}" | tail -4 | tr '\n' '|')"
fi

# == gate 8: the dead-child honest bound (INV9) -- a LIVE round-trip ==================
# the named honest bound: a flow child taken to `dead` (retries exhausted) does NOT
# decrement -- the parent stays awaiting_children (the failure policy is emq.3.4).
# a 2-child flow, one child dead-lettered, the parent must hold at :dependencies 2.
DEAD_OUT="$(cd "${APP_DIR}" && TMPDIR=/tmp mix run --no-start -e '
  :ok = EchoData.Snowflake.start(33)
  {:ok, conn} = EchoMQ.Connector.start_link(port: 6390)
  alias EchoMQ.{Flows, Jobs, Keyspace, Connector, Metrics}
  q = "emq31.harness.dead#{System.unique_integer([:positive])}"
  parent = EchoData.BrandedId.generate!("JOB")
  c1 = EchoData.BrandedId.generate!("JOB")
  c2 = EchoData.BrandedId.generate!("JOB")
  {:ok, _} = Flows.add(conn, q, %{parent: %{id: parent, payload: "P"}, children: [%{id: c1, payload: "a"}, %{id: c2, payload: "b"}]})
  {:ok, {dead, _, tok}} = Jobs.claim(conn, q, 60_000)
  {:ok, :dead} = Jobs.retry(conn, q, dead, tok, 0, 1, "boom")   # max_attempts 1 -> dead now
  {:ok, deps} = Connector.command(conn, ["GET", Keyspace.job_key(q, parent) <> ":dependencies"])
  {:ok, st} = Metrics.get_job_state(conn, q, parent)
  IO.puts("DEAD_RESULT=deps=#{inspect(deps)} parent_state=#{inspect(st)}")   # deps is the bare GET string "2"
' 2>&1)"
DEAD_LINE="$(echo "${DEAD_OUT}" | grep -E '^DEAD_RESULT=' | tail -1)"
if echo "${DEAD_LINE}" | grep -qE 'deps="2"' \
   && echo "${DEAD_LINE}" | grep -qE 'parent_state=:awaiting_children'; then
  emit "dead-child" ok "the honest bound (INV9): a flow child taken to 'dead' (retries exhausted at max_attempts 1) does NOT decrement -- the parent's :dependencies holds at 2 and its state stays :awaiting_children (the failure policy is emq.3.4, named not papered over). [${DEAD_LINE}]"
else
  emit "dead-child" FAIL "the dead-child honest-bound probe did not hold: [${DEAD_LINE:-<none>}] (want deps=\"2\", parent_state=:awaiting_children); tail: $(echo "${DEAD_OUT}" | tail -4 | tr '\n' '|')"
fi

# == the board ======================================================================
echo "----------------------------------------------------------------------"
if [ "${FAIL}" -eq 0 ]; then
  echo "PASS ${PASS}/$((PASS+FAIL)) -- emq.3.1 single-queue flow gate ladder GREEN + harness-reproducible"
  exit 0
else
  echo "FAIL ${FAIL}/$((PASS+FAIL)) gate(s) red (PASS ${PASS})"
  exit 1
fi
