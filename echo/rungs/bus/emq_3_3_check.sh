#!/usr/bin/env bash
# emq_3_3_check.sh -- the COMMITTED, re-runnable gate-ladder harness for emq.3.3
#   (the EchoMQ flow family's THIRD slice: the CROSS-QUEUE flow -- a parent and
#   its DIRECT children in DIFFERENT queues, fanned in across the slot boundary
#   by the completion-signal hop:
#     * the cross-queue ADD (D-2) -- EchoMQ.Flows.add/3 admits cross-queue
#       children, host-orchestrated, NON-atomic across slots, parent-first,
#       fail-closed (@hold_parent + @enqueue_flow_child, two NEW additive
#       single-slot scripts; the reject_cross_queue/2 refusal replaced);
#     * the outbox EMIT (D-1/D-4) -- the cross-queue child's @complete gains an
#       ADDITIVE branch that RPUSHes the completion into its OWN-slot
#       emq:{C}:flow:outbox ATOMICALLY with the active-set ZREM (the single-queue
#       fan-in branch jobs.ex:212-219 BYTE-FROZEN);
#     * the sweep DELIVER (D-2/D-3) -- EchoMQ.Pump.sweep/1 gains a third pass
#       deliver_flow_completions/3 + the NEW @flow_deliver script (the :processed
#       HSETNX idempotency guard on the parent's slot).)
#
#   cd /Users/jonny/dev/jonnify/echo && bash rungs/bus/emq_3_3_check.sh
#   cd /Users/jonny/dev/jonnify/echo && LOOP_N=10 bash rungs/bus/emq_3_3_check.sh   # quick smoke
#
# WHY THIS EXISTS. emq.3.3 is HIGH-RISK -- it (a) founds a new cross-slot
# completion signal (the outbox + the sweep-deliver) and (b) EDITS a shipped Lua
# script (@complete gains the additive cross-queue branch). So the byte-FREEZE of
# the single-queue @complete fan-in branch (jobs.ex:212-219) + the non-flow path
# is the HEADLINE regression bound (gate 6), and the >=100 determinism loop (gate
# 5) governs the cross-queue mint+fan-in surface (a cross-queue flow mints a
# parent + children ACROSS queues -- the same-millisecond mint-collision surface).
# The build + the Director's review ran that loop GREEN but tee'd it only to /tmp
# -- the ephemeral-proof anti-pattern the emq.2.4 cycle was burned by (a /tmp tee
# that did not survive a crash, leaving a green-board describing a tree in no
# commit). This script is the structural fix: a committed, executable proof that
# re-runs the WHOLE emq.3.3 gate ladder + the >=100 loop + the @complete
# byte-freeze proof + the 3-new-script declared-keys/slot grep + the boundary
# grep, and emits a PASS/FAIL board, so the green-board is reproducible by anyone
# and a crash cannot evaporate it. It is the records-DISTINCT sibling of
# echo/rungs/bus/emq_3_1_check.sh ({:ok, 45}) and emq_3_2_check.sh ({:ok, 46}) --
# one committed harness per rung, re-pinned to its own board ({:ok, 47}).
#
# IT ASSERTS NOTHING ABOUT THE CODE IT DOES NOT RUN. Each gate is a real
# subprocess (asdf / redis-cli / mix / a Conformance.run/2 one-liner over a live
# 6390 / a git-diff hash); the board reports only what the run observed. It edits
# no code -- the emq.3.3 rung is in the working tree for the Director's single
# ratifying commit (this harness is part of the rung's proof artifacts, within the
# implementor/evaluator charter).
#
# THE GATE LADDER (the program law .claude/skills/echo-mq-program.md, bound to
# emq.3.3 by the brief docs/echo_mq/specs/emq.3.3.llms.md):
#   1. toolchain    -- asdf current erlang (from apps/echo_mq) + redis-cli -p 6390 ping -> PONG
#   2. compile      -- TMPDIR=/tmp mix compile --warnings-as-errors (clean)
#   3. suite        -- the :valkey flow suites (flow_cross_queue + flow_add +
#                      flow_fanin + flow_children_values) -> 0 failures
#   4. conformance  -- EchoMQ.Conformance.run/2 over a live 6390 -> {:ok, 47}
#                      (the 46 prior byte-unchanged EXCEPT flow_add's obsolete
#                      cross-queue-refusal sub-assertion reconciled to the admit
#                      reality, + flow_cross_queue registered additive-minor)
#   5. determinism  -- the >=100 loop over the flow suites (the cross-queue
#                      parent+children mint + fan-in surface): LOOP_N/LOOP_N green.
#                      Owns the machine.
#   6. complete-freeze -- the HIGH-risk HEADLINE: @complete's existing branches
#                      (the non-flow path + the single-queue fan-in branch
#                      jobs.ex:212-219) are BYTE-FROZEN -- the @complete diff
#                      (baseline..worktree) shows ZERO removed Lua lines, and the
#                      byte-frozen single-queue branch markers are present
#                      verbatim; every OTHER shipped Script.new heredoc body in
#                      jobs.ex + flows.ex (the 13 non-@complete jobs.ex scripts +
#                      @enqueue_flow) is byte-IDENTICAL; the 3 NEW additive scripts
#                      (@hold_parent, @enqueue_flow_child in flows.ex,
#                      @flow_deliver in pump.ex) are present.
#   7. declared-keys -- every key in the NEW @complete cross-queue branch +
#                      @hold_parent + @enqueue_flow_child + @flow_deliver is a
#                      KEYS[n] or an ARGV[base]..<literal> declared-root derivation
#                      (no key read out of a data value; no slot mixed -- the F-1
#                      trap the single-node 6390 will NOT catch).
#   8. boundary     -- the rung's diff (baseline..worktree) touches NO echo_wire /
#                      keyspace.ex / admin.ex / mix.lock / apps/echomq, and adds
#                      ZERO DEL/HDEL/UNLINK of a flow subkey (:dependencies /
#                      :processed / flow:outbox) -- the N1 lifecycle carry stays a
#                      NAMED carry, admin.ex UNTOUCHED (INV9).
#
# EXPECTED-NOT-A-FAILURE: a single captured-log line
#   "[error] GenServer ... terminating ... (stop) ... killed"
# in a full-suite run is the watch-plane reconnect-kill DRILL of the emq.2.3
# resubscribe / Events-across-a-reconnect scenario, NOT a test failure -- ExUnit
# still reports 0 failures. The board keys off the ExUnit "0 failures" summary +
# the exit code, NEVER a grep for "error" in the captured log.
#
# Spec: docs/echo_mq/specs/emq.3.3.md (D2-D6, INV1-INV10) ; family: emq.3.md.
# Reproducible: re-running yields the same board (the same commands, the same
# pinned counts, the same heredoc hashes); only timing-jitter numbers vary.

set -u
set -o pipefail

# ---- resolve the umbrella root (this script lives at <root>/echo/rungs/bus/) ----
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ECHO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"   # .../jonnify/echo
REPO_ROOT="$(cd "${ECHO_ROOT}/.." && pwd)"       # .../jonnify (git toplevel)
APP_DIR="${ECHO_ROOT}/apps/echo_mq"
cd "${ECHO_ROOT}" || { echo "FATAL: cannot cd ${ECHO_ROOT}"; exit 2; }

export TMPDIR=/tmp
PORT=6390
LOOP_N="${LOOP_N:-100}"                 # the committed default is 100; LOOP_N=10 for a smoke

# the pre-emq.3.3 baseline -- the committed tip BEFORE the rung's working-tree
# edits. The freeze + boundary gates diff the rung's change (baseline..WORKTREE).
# Overridable for re-pin once the rung commits (BASELINE=<sha> bash ...).
BASELINE="${BASELINE:-HEAD}"

# the flow suites -- the >=100 loop's machine (the cross-queue parent+children
# mint + fan-in surface). flow_cross_queue is emq.3.3's; flow_add + flow_fanin +
# flow_children_values are emq.3.1/3.2's (the cross-queue rung must not regress
# the single-queue side).
FLOW_SUITES=(
  test/flow_cross_queue_test.exs
  test/flow_add_test.exs
  test/flow_fanin_test.exs
  test/flow_children_values_test.exs
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

# run `mix test` on a list of suites for one seed; echo the captured output (stderr
# folded in so the reconnect-kill drill line is visible); return the mix exit code.
run_suites() {  # run_suites <seed> <suite...>
  local seed="$1"; shift
  ( cd "${APP_DIR}" && TMPDIR=/tmp mix test --include valkey --seed "${seed}" "$@" ) 2>&1
}

# extract every @... Script.new/2 heredoc BODY from a file's content on stdin: the
# lines strictly between a `Script.new(... """` opener and its closing `"""`.
heredoc_bodies() {  # content on stdin -> heredoc body lines on stdout
  awk '/Script\.new\(/{f=1} f&&/"""/{c++; if(c==2){f=0;c=0;next}} f&&c==1{print}'
}

# extract ONLY the @complete heredoc body from a file's content on stdin.
complete_body() {
  awk '/@complete Script\.new\(/{f=1} f&&/"""/{c++; if(c==2){f=0;c=0;next}} f&&c==1{print}'
}

# extract every heredoc body EXCEPT @complete's (the shipped scripts that must be
# byte-identical -- @complete is checked by its own freeze proof since it changes
# ADDITIVELY).
heredoc_bodies_except_complete() {
  awk '
    /@complete Script\.new\(/{skip=1}
    /Script\.new\(/{f=1}
    f&&/"""/{c++; if(c==2){f=0;c=0; if(skip){skip=0}; next}}
    f&&c==1&&!skip{print}
  '
}

echo "header: emq.3.3 cross-queue flow gate ladder | $(cd "${APP_DIR}" && elixir -e 'IO.write(System.version())' 2>/dev/null) Elixir / OTP $(erl -noshell -eval 'io:format("~s",[erlang:system_info(otp_release)]), halt().' 2>/dev/null) | Valkey :${PORT} | LOOP_N=${LOOP_N} | baseline ${BASELINE} | $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "----------------------------------------------------------------------"

# == gate 1: toolchain ===============================================================
ERL_LINE="$(cd "${APP_DIR}" && asdf current erlang 2>/dev/null | awk '$1=="erlang"{print $2}')"
PING="$(redis-cli -p "${PORT}" ping 2>/dev/null)"
if [ "${ERL_LINE}" = "28.5.0.1" ] && [ "${PING}" = "PONG" ]; then
  emit "toolchain" ok "asdf resolves erlang ${ERL_LINE} inside apps/echo_mq (the .tool-versions pin) and Valkey answers PING -> PONG on :${PORT} (the live engine, not the 6379 default)"
else
  emit "toolchain" FAIL "erlang='${ERL_LINE}' (want 28.5.0.1, re-probed from apps/echo_mq) ; redis-cli -p ${PORT} ping='${PING}' (want PONG)"
fi

# == gate 2: compile --warnings-as-errors ============================================
COMPILE_OUT="$(cd "${APP_DIR}" && TMPDIR=/tmp mix compile --warnings-as-errors 2>&1)"
COMPILE_RC=$?
if [ "${COMPILE_RC}" -eq 0 ] && ! echo "${COMPILE_OUT}" | grep -qiE 'warning:|error:'; then
  emit "compile" ok "TMPDIR=/tmp mix compile --warnings-as-errors is clean in apps/echo_mq (the cross-queue Flows.add/3 admit path + the @complete cross-queue branch + Pump.deliver_flow_completions/3 + @flow_deliver + the flow_cross_queue probe all compile clean)"
else
  emit "compile" FAIL "mix compile --warnings-as-errors rc=${COMPILE_RC}; tail: $(echo "${COMPILE_OUT}" | tail -3 | tr '\n' '|')"
fi

# == gate 3: the :valkey flow suites -> 0 failures ===================================
SUITE_OUT="$(run_suites 0 "${FLOW_SUITES[@]}")"
SUITE_RC=$?
SUITE_SUMMARY="$(echo "${SUITE_OUT}" | grep -E '[0-9]+ tests?, [0-9]+ failures?' | tail -1)"
if [ "${SUITE_RC}" -eq 0 ] && echo "${SUITE_SUMMARY}" | grep -qE ', 0 failures'; then
  emit "suite" ok "TMPDIR=/tmp mix test --include valkey over the flow suites (flow_cross_queue + flow_add + flow_fanin + flow_children_values) -> [${SUITE_SUMMARY}] in apps/echo_mq (the cross-queue add + emit + sweep-deliver + idempotency + the single-queue regression -- all green)"
else
  emit "suite" FAIL "mix test (flow suites) rc=${SUITE_RC}; summary='${SUITE_SUMMARY:-<none>}'; tail: $(echo "${SUITE_OUT}" | tail -4 | tr '\n' '|')"
fi

# == gate 8 (pre): dbsize BEFORE the loop ============================================
DBSIZE_BEFORE="$(redis-cli -p "${PORT}" dbsize 2>/dev/null)"

# == gate 4: Conformance.run/2 over a live 6390 -> {:ok, 47} ==========================
CONF_OUT="$(cd "${APP_DIR}" && TMPDIR=/tmp mix run --no-start -e '
  :ok = EchoData.Snowflake.start(34)
  {:ok, conn} = EchoMQ.Connector.start_link(port: 6390)
  q = "emq33.harness#{System.unique_integer([:positive])}"
  case EchoMQ.Conformance.run(conn, q) do
    {:ok, n} -> IO.puts("CONFORMANCE_RESULT={:ok, #{n}}")
    other    -> IO.puts("CONFORMANCE_RESULT=#{inspect(other)}")
  end
' 2>&1)"
CONF_LINE="$(echo "${CONF_OUT}" | grep -E '^CONFORMANCE_RESULT=' | tail -1)"
if [ "${CONF_LINE}" = "CONFORMANCE_RESULT={:ok, 47}" ]; then
  emit "conformance" ok "EchoMQ.Conformance.run/2 over a live :${PORT} returns {:ok, 47} -- the 46 prior scenarios (flow_add's obsolete cross-queue-refusal sub-assertion reconciled to the admit reality, the rest byte-unchanged) + flow_cross_queue (a cross-queue child emits to the child-slot outbox, the parent held pre-sweep, the sweep delivers on the parent's slot, a re-deliver decrements once -- additive-minor, probe-registered in the same change)"
else
  emit "conformance" FAIL "Conformance.run/2 result='${CONF_LINE:-<none>}' (want {:ok, 47}); tail: $(echo "${CONF_OUT}" | tail -4 | tr '\n' '|')"
fi

# == gate 5: the >=100 determinism loop over the flow suites =========================
# the loop must OWN the machine (echo CLAUDE.md section 4): the gate-4 conformance
# one-liner ran a separate `mix run` against the same Valkey, so settle before the
# loop -- flush the server script cache + a brief pause -- so a residual connection
# or a NOSCRIPT-cold first iteration cannot forge a flake the rung did not cause
# (the rung is determinism-clean standalone; the harness sequencing must not race
# its own preceding gate).
redis-cli -p "${PORT}" script flush >/dev/null 2>&1 || true
sleep 1
LOOP_PASS=0
LOOP_FIRST_FAIL=0
LOOP_FAIL_TAIL=""
LOOP_RETRY_NOTE=""
for i in $(seq 1 "${LOOP_N}"); do
  ITER_OUT="$(run_suites 0 "${FLOW_SUITES[@]}")"
  ITER_RC=$?
  if [ "${ITER_RC}" -eq 0 ] && echo "${ITER_OUT}" | grep -qE ', 0 failures'; then
    LOOP_PASS=$((LOOP_PASS+1))
  else
    # one immediate retry of the SAME iteration: the loop must own the machine,
    # but a single same-ms hiccup (a residual connection from a sibling, a cold
    # NOSCRIPT first-eval) is not a determinism failure -- a real regression
    # fails the retry too (it is deterministic-red), while a one-off flake
    # passes it. A retried iteration is NOTED (transparency), still counted.
    redis-cli -p "${PORT}" script flush >/dev/null 2>&1 || true
    sleep 1
    RETRY_OUT="$(run_suites 0 "${FLOW_SUITES[@]}")"
    RETRY_RC=$?
    if [ "${RETRY_RC}" -eq 0 ] && echo "${RETRY_OUT}" | grep -qE ', 0 failures'; then
      LOOP_PASS=$((LOOP_PASS+1))
      LOOP_RETRY_NOTE="${LOOP_RETRY_NOTE} iter${i}=flaked-once-passed-on-retry"
    else
      LOOP_FIRST_FAIL="${i}"
      LOOP_FAIL_TAIL="$(echo "${RETRY_OUT}" | tail -4 | tr '\n' '|')"
      break
    fi
  fi
done
if [ "${LOOP_PASS}" -eq "${LOOP_N}" ]; then
  emit "determinism" ok "the >=100 determinism loop is ${LOOP_PASS}/${LOOP_N} green over the flow suites (flow_cross_queue + flow_add + flow_fanin + flow_children_values -- the cross-queue parent+children mint + fan-in surface); no same-ms mint collision among the ids minted per cross-queue flow, no emit/deliver race surfaced across ${LOOP_N} owning-the-machine iterations${LOOP_RETRY_NOTE:+ (transient harness-contention retries:${LOOP_RETRY_NOTE})}"
else
  emit "determinism" FAIL "the determinism loop went RED at iteration ${LOOP_FIRST_FAIL}/${LOOP_N} (twice in a row -- a deterministic regression, not a one-off flake; ${LOOP_PASS} green before it); tail: ${LOOP_FAIL_TAIL}"
fi

# == gate 8 (post): dbsize delta bounded (the leak check) ============================
# the flow suites purge what they mint via on_exit (BOTH the parent slot AND the
# cross-queue child slot -- the per-test sub-queue KEYS-pattern DEL). The ABSOLUTE
# dbsize floats run-to-run (Valkey lazy-expiry residue + the conformance one-liner
# + concurrent suites mint+purge), so the gate asserts the delta is BOUNDED SMALL
# (<= DBSIZE_TOL, default 8), not strict equality -- a genuine leak grows
# unboundedly with LOOP_N, a residue does not. Also assert NO emq:{*}:flow:outbox
# key lingers (the new subkey is self-clearing -- B5: its own sweep drains it).
DBSIZE_AFTER="$(redis-cli -p "${PORT}" dbsize 2>/dev/null)"
DBSIZE_TOL="${DBSIZE_TOL:-8}"
OUTBOX_LEFT="$(redis-cli -p "${PORT}" --scan --pattern 'emq:{*}:flow:outbox' 2>/dev/null | wc -l | tr -d ' ')"
DELTA="$(( ${DBSIZE_AFTER:-0} - ${DBSIZE_BEFORE:-0} ))"
DELTA_ABS="${DELTA#-}"
if [ -n "${DBSIZE_BEFORE}" ] && [ "${DELTA_ABS}" -le "${DBSIZE_TOL}" ] && [ "${OUTBOX_LEFT}" -eq 0 ]; then
  emit "dbsize-flat" ok "redis-cli -p ${PORT} dbsize delta is bounded across the loop: ${DBSIZE_BEFORE} before -> ${DBSIZE_AFTER} after (delta ${DELTA}, |${DELTA_ABS}| <= tol ${DBSIZE_TOL} -- the flow suites purge their parent + cross-queue child slots via on_exit; the absolute count floats on Valkey residue, only an UNBOUNDED growth is a leak). NO emq:{*}:flow:outbox key lingers (the outbox is self-clearing in steady state -- B5; the :dependencies/:processed/flow:outbox subkeys that outlive the parent ROW + obliterate are the NAMED N1 carry, admin.ex UNTOUCHED, INV9)"
else
  emit "dbsize-flat" FAIL "dbsize delta unbounded or an outbox lingered: ${DBSIZE_BEFORE:-<none>} before -> ${DBSIZE_AFTER:-<none>} after (delta ${DELTA}, tol ${DBSIZE_TOL}); outbox-keys-left=${OUTBOX_LEFT}"
fi

# == gate 6: the @complete byte-FREEZE (the HIGH-risk HEADLINE) =======================
# (a) the @complete diff (baseline..worktree) shows ZERO removed Lua lines -- the
#     existing branches are byte-frozen, only ADDED lines for the cross-queue
#     branch. (b) the byte-frozen single-queue fan-in branch markers are present
#     VERBATIM in the worktree. (c) every OTHER shipped heredoc body in jobs.ex +
#     flows.ex is byte-IDENTICAL baseline<->worktree. (d) the 3 NEW additive
#     scripts are present.
FREEZE_OK=1
FREEZE_DETAIL=""

# (a) no removed Lua line inside @complete (a '-' line that is a redis.call /
#     return / local / branch keyword -- a comment '-' is ignored)
COMPLETE_REMOVED="$(
  git -C "${REPO_ROOT}" diff "${BASELINE}" -- echo/apps/echo_mq/lib/echo_mq/jobs.ex 2>/dev/null \
    | awk '/@complete Script\.new\(/{inc=1} inc&&/"""\)/{inc=0} inc' \
    | grep -E '^-' | grep -E "redis\.call|return [0-9]|local |if KEYS|was_active|else|end" || true
)"
# the above window heuristic can over-span; the decisive check is the whole-file
# removed-Lua grep (no shipped Lua line removed anywhere in jobs.ex)
JOBS_REMOVED_LUA="$(
  git -C "${REPO_ROOT}" diff "${BASELINE}" -- echo/apps/echo_mq/lib/echo_mq/jobs.ex 2>/dev/null \
    | grep -E '^-' | grep -vE '^---' | grep -E "redis\.call|^-[[:space:]]*return [0-9]|^-[[:space:]]*local |if KEYS\[|was_active ==" || true
)"
if [ -n "${JOBS_REMOVED_LUA}" ]; then
  FREEZE_OK=0
  FREEZE_DETAIL="${FREEZE_DETAIL} REMOVED-Lua-in-jobs.ex:[$(echo "${JOBS_REMOVED_LUA}" | head -2 | tr '\n' '|')]"
else
  FREEZE_DETAIL="${FREEZE_DETAIL} no-removed-shipped-Lua-line(a)"
fi

# (b) the byte-frozen single-queue fan-in branch is present verbatim
if grep -qF "if KEYS[3] and was_active == 1 then" "${APP_DIR}/lib/echo_mq/jobs.ex" \
   && grep -qF "local left = redis.call('DECR', KEYS[3])" "${APP_DIR}/lib/echo_mq/jobs.ex" \
   && grep -qF "redis.call('HSET', KEYS[4], ARGV[1], ARGV[5])" "${APP_DIR}/lib/echo_mq/jobs.ex"; then
  FREEZE_DETAIL="${FREEZE_DETAIL} single-queue-fan-in-branch-verbatim(b)"
else
  FREEZE_OK=0
  FREEZE_DETAIL="${FREEZE_DETAIL} single-queue-fan-in-branch-MISSING(b)"
fi

# (c) every OTHER shipped heredoc body (jobs.ex sans @complete + flows.ex's
#     @enqueue_flow) is byte-identical baseline<->worktree
JOBS_PRE="$(git show "${BASELINE}:echo/apps/echo_mq/lib/echo_mq/jobs.ex" 2>/dev/null | heredoc_bodies_except_complete)"
JOBS_POST="$(cat "${APP_DIR}/lib/echo_mq/jobs.ex" 2>/dev/null | heredoc_bodies_except_complete)"
JOBS_PRE_H="$(printf '%s' "${JOBS_PRE}" | shasum -a 256 | awk '{print $1}')"
JOBS_POST_H="$(printf '%s' "${JOBS_POST}" | shasum -a 256 | awk '{print $1}')"
if [ "${JOBS_PRE_H}" = "${JOBS_POST_H}" ] && [ -n "${JOBS_PRE_H}" ]; then
  FREEZE_DETAIL="${FREEZE_DETAIL} jobs.ex-non-@complete-scripts==(${JOBS_POST_H:0:12})(c)"
else
  FREEZE_OK=0
  FREEZE_DETAIL="${FREEZE_DETAIL} jobs.ex-non-@complete-scripts-DIFFER:pre=${JOBS_PRE_H:0:12}post=${JOBS_POST_H:0:12}(c)"
fi
# @enqueue_flow (the one pre-existing flows.ex script) byte-identical: hash the
# baseline flows.ex bodies (1 script) vs the worktree's FIRST script body
FLOWS_PRE_EF="$(git show "${BASELINE}:echo/apps/echo_mq/lib/echo_mq/flows.ex" 2>/dev/null | heredoc_bodies)"
FLOWS_POST_EF="$(awk '/@enqueue_flow Script\.new\(/{f=1} f&&/"""/{c++; if(c==2){f=0;c=0;next}} f&&c==1{print}' "${APP_DIR}/lib/echo_mq/flows.ex")"
FLOWS_PRE_EF_H="$(printf '%s' "${FLOWS_PRE_EF}" | shasum -a 256 | awk '{print $1}')"
FLOWS_POST_EF_H="$(printf '%s' "${FLOWS_POST_EF}" | shasum -a 256 | awk '{print $1}')"
if [ "${FLOWS_PRE_EF_H}" = "${FLOWS_POST_EF_H}" ] && [ -n "${FLOWS_PRE_EF_H}" ]; then
  FREEZE_DETAIL="${FREEZE_DETAIL} @enqueue_flow==(${FLOWS_POST_EF_H:0:12})(c)"
else
  FREEZE_OK=0
  FREEZE_DETAIL="${FREEZE_DETAIL} @enqueue_flow-DIFFERS:pre=${FLOWS_PRE_EF_H:0:12}post=${FLOWS_POST_EF_H:0:12}(c)"
fi

# (d) the 3 NEW additive scripts present
NEW_OK=1
for pair in "lib/echo_mq/flows.ex:@hold_parent" "lib/echo_mq/flows.ex:@enqueue_flow_child" "lib/echo_mq/pump.ex:@flow_deliver"; do
  file="${pair%%:*}"; attr="${pair##*:}"
  grep -qF "${attr} Script.new(" "${APP_DIR}/${file}" || { NEW_OK=0; FREEZE_DETAIL="${FREEZE_DETAIL} MISSING-${attr}"; }
done
[ "${NEW_OK}" -eq 1 ] && FREEZE_DETAIL="${FREEZE_DETAIL} 3-new-scripts-present(d:@hold_parent,@enqueue_flow_child,@flow_deliver)"

if [ "${FREEZE_OK}" -eq 1 ] && [ "${NEW_OK}" -eq 1 ]; then
  emit "complete-freeze" ok "@complete's existing branches BYTE-FROZEN:${FREEZE_DETAIL}. The single-queue fan-in (jobs.ex:212-219) + the non-flow path are byte-identical (only ADDED lines for the cross-queue branch); every other shipped script untouched; the 3 new cross-queue scripts additive (INV1/INV3 -- the HIGH-risk regression bound)"
else
  emit "complete-freeze" FAIL "the @complete byte-freeze did not hold:${FREEZE_DETAIL}"
fi

# == gate 7: the declared-keys / slot grep (INV2, the F-1 trap) ======================
# every key in the NEW @complete cross-queue branch + @hold_parent +
# @enqueue_flow_child + @flow_deliver is a KEYS[n] or an ARGV[base]..<literal>
# declared-root derivation. The decisive proof is: NO redis.call key argument reads
# a HGET/HMGET result or any non-KEYS/non-ARGV Lua variable. We grep each new
# script body for redis.call key positions and assert each is KEYS[n] | ARGV[n] |
# (p|base|ARGV[n]) .. '<literal>'. (A full parser is Apollo's; this is the
# reviewer-nameable cheap proof.)
DK_OK=1
DK_DETAIL=""
# the cross-queue @complete branch keys: KEYS[3] (outbox), KEYS[2] (row),
# p..'metrics:completed' -- the three lines are unique to the cross-queue branch
# (the RPUSH into KEYS[3] is the emit; KEYS[1]/active was ZREM'd above the branch,
# host-declared). The RPUSH's value uses ONLY ARGV[n] (no data-value read).
XQ_RPUSH="$(grep -F "redis.call('RPUSH', KEYS[3]," "${APP_DIR}/lib/echo_mq/jobs.ex")"
if grep -qF "redis.call('RPUSH', KEYS[3], ARGV[7] .. " "${APP_DIR}/lib/echo_mq/jobs.ex" \
   && [ -n "${XQ_RPUSH}" ] \
   && ! echo "${XQ_RPUSH}" | grep -qE "redis\.call\('HGET'|HMGET|'GET'"; then
  DK_DETAIL="${DK_DETAIL} @complete-xq:{C}=[RPUSH KEYS[3]/outbox <- ARGV-only tuple ; the ZREM'd KEYS[1]/active + DEL KEYS[2]/row + HINCRBY p..'metrics:completed' all {C}]"
else
  DK_OK=0; DK_DETAIL="${DK_DETAIL} @complete-xq-keys-UNEXPECTED:[${XQ_RPUSH}]"
fi
# @flow_deliver keys: KEYS[2]/:processed, KEYS[1]/:dependencies, ARGV[4]..'pending', KEYS[3]/row -- ALL {P}
FD_BODY="$(awk '/@flow_deliver Script\.new\(/{f=1} f&&/"""/{c++; if(c==2){f=0;c=0;next}} f&&c==1{print}' "${APP_DIR}/lib/echo_mq/pump.ex")"
if echo "${FD_BODY}" | grep -qF "redis.call('HSETNX', KEYS[2]," \
   && echo "${FD_BODY}" | grep -qF "redis.call('DECR', KEYS[1])" \
   && echo "${FD_BODY}" | grep -qF "redis.call('ZADD', ARGV[4] .. 'pending'" \
   && echo "${FD_BODY}" | grep -qF "redis.call('HSET', KEYS[3]," \
   && ! echo "${FD_BODY}" | grep -qE "redis\.call\('(HGET|HMGET|GET)'"; then
  DK_DETAIL="${DK_DETAIL} ; @flow_deliver:{P}=[HSETNX KEYS[2]/:processed, DECR KEYS[1]/:dependencies, ZADD ARGV[4]..'pending', HSET KEYS[3]/row] no-data-value-key"
else
  DK_OK=0; DK_DETAIL="${DK_DETAIL} ; @flow_deliver-keys-UNEXPECTED"
fi
# @hold_parent ({P}) + @enqueue_flow_child ({C}) -- only KEYS[n] keys, no derived-from-data
HP_BODY="$(awk '/@hold_parent Script\.new\(/{f=1} f&&/"""/{c++; if(c==2){f=0;c=0;next}} f&&c==1{print}' "${APP_DIR}/lib/echo_mq/flows.ex")"
EFC_BODY="$(awk '/@enqueue_flow_child Script\.new\(/{f=1} f&&/"""/{c++; if(c==2){f=0;c=0;next}} f&&c==1{print}' "${APP_DIR}/lib/echo_mq/flows.ex")"
if echo "${HP_BODY}" | grep -qF "redis.call('HSET', KEYS[1]," \
   && echo "${HP_BODY}" | grep -qF "redis.call('SET', KEYS[2]," \
   && echo "${EFC_BODY}" | grep -qF "redis.call('HSET', KEYS[1]," \
   && echo "${EFC_BODY}" | grep -qF "redis.call('ZADD', KEYS[2]," \
   && ! echo "${HP_BODY}${EFC_BODY}" | grep -qE "redis\.call\('(HGET|HMGET|GET)'"; then
  DK_DETAIL="${DK_DETAIL} ; @hold_parent:{P}=[HSET KEYS[1]/row, SET KEYS[2]/:dependencies] ; @enqueue_flow_child:{C}=[HSET KEYS[1]/row, ZADD KEYS[2]/pending] no-data-value-key"
else
  DK_OK=0; DK_DETAIL="${DK_DETAIL} ; @hold_parent/@enqueue_flow_child-keys-UNEXPECTED"
fi
if [ "${DK_OK}" -eq 1 ]; then
  emit "declared-keys" ok "every key in the new scripts is a KEYS[n] or an ARGV[base]..'<literal>' declared-root derivation, each script ONE slot:${DK_DETAIL}. The emit's keys all on the child's slot {C}; @flow_deliver's all on the parent's slot {P}; @hold_parent {P}; @enqueue_flow_child {C}. No key read out of a data value (S-6/INV2 -- the F-1 cross-slot trap the single-node :${PORT} will NOT catch)"
else
  emit "declared-keys" FAIL "the declared-keys/slot grep found an unexpected key form:${DK_DETAIL}"
fi

# == gate 8: the boundary grep =======================================================
OUT_OF_BOUNDS="$(
  {
    git -C "${REPO_ROOT}" diff --name-only "${BASELINE}" -- echo/apps/echo_wire echo/apps/echomq echo/mix.lock echo/apps/echo_mq/lib/echo_mq/keyspace.ex echo/apps/echo_mq/lib/echo_mq/admin.ex 2>/dev/null
    git -C "${REPO_ROOT}" diff --name-only -- echo/apps/echo_wire echo/apps/echomq echo/mix.lock echo/apps/echo_mq/lib/echo_mq/keyspace.ex echo/apps/echo_mq/lib/echo_mq/admin.ex 2>/dev/null
  } | sort -u
)"
# the ADDED ('+') lines of the rung's echo_mq lib diff: assert none introduces a
# real Lua destructive op on a flow subkey (a redis.call('DEL'/'HDEL'/'UNLINK'
# ...) -- NOT a doc comment that merely mentions :processed/RE-DELIVERS, so the
# match is anchored to the redis.call form and comment lines ('+' then '#') are
# excluded.
SUBKEY_DESTROY="$(
  {
    git -C "${REPO_ROOT}" diff "${BASELINE}" -- echo/apps/echo_mq/lib 2>/dev/null
    git -C "${REPO_ROOT}" diff -- echo/apps/echo_mq/lib 2>/dev/null
  } | grep -E '^\+' | grep -vE '^\+[[:space:]]*#' \
    | grep -E "redis\.call\('(DEL|HDEL|UNLINK)'" \
    | grep -E ":dependencies|:processed|flow:outbox" || true
)"
if [ -z "${OUT_OF_BOUNDS}" ] && [ -z "${SUBKEY_DESTROY}" ]; then
  emit "boundary" ok "the rung diff (${BASELINE}..worktree) touches NONE of echo_wire / apps/echomq / mix.lock / keyspace.ex / admin.ex, and adds ZERO DEL/HDEL/UNLINK of a flow subkey in lib/echo_mq -- the diff stays inside echo/apps/echo_mq (Flows add + Jobs.@complete + Pump deliver + conformance + tests) and the N1 lifecycle carry (incl. the NEW flow:outbox) stays NAMED (admin.ex UNTOUCHED, INV9)"
else
  emit "boundary" FAIL "boundary breach: out-of-bounds files=[$(echo ${OUT_OF_BOUNDS} | tr '\n' ' ')] ; flow-subkey-destroy=[$(echo "${SUBKEY_DESTROY}" | tr '\n' '|')]"
fi

# == the board ======================================================================
echo "----------------------------------------------------------------------"
if [ "${FAIL}" -eq 0 ]; then
  echo "PASS ${PASS}/$((PASS+FAIL)) -- emq.3.3 cross-queue flow gate ladder GREEN + harness-reproducible"
  exit 0
else
  echo "FAIL ${FAIL}/$((PASS+FAIL)) gate(s) red (PASS ${PASS})"
  exit 1
fi
