#!/usr/bin/env bash
# emq_3_2_check.sh -- the COMMITTED, re-runnable gate-ladder harness for emq.3.2
#   (the EchoMQ flow family's SECOND slice: the child-result reads --
#   EchoMQ.Flows.children_values/3 (HGETALL over the parent :processed HASH) +
#   EchoMQ.Flows.dependencies/3 (GET over the :dependencies STRING counter) +
#   EchoMQ.Jobs.complete/5 threading the child result through the EXISTING
#   @complete ARGV[5] slot -- the v1 get_children_values / get_dependencies_count
#   parity).
#
#   cd /Users/jonny/dev/jonnify/echo && bash rungs/bus/emq_3_2_check.sh
#   cd /Users/jonny/dev/jonnify/echo && LOOP_N=10 bash rungs/bus/emq_3_2_check.sh   # quick smoke
#
# WHY THIS EXISTS. emq.3.2 is NORMAL-RISK -- the inverse of emq.3.1's HIGH-risk
# @complete-Lua edit: R1.B carries the real child result through the ALREADY-built
# ARGV[5] slot, so NO shipped Lua script changes (the empty-Lua-diff is the
# NORMAL-risk headline, gate 6). But it still mints N+1 branded JOB ids per
# Flows.add and fans them in (the same-millisecond mint-collision surface), so the
# >=100 determinism loop still governs the flow read suite. The build + the
# Director's Stage-2 review ran that loop GREEN, but tee'd it only to /tmp -- the
# ephemeral-proof anti-pattern the emq.2.4 cycle was burned by (a /tmp tee that did
# not survive a crash, leaving a committed green-board describing a tree state in no
# commit). This script is the structural fix: a committed, executable proof that
# re-runs the WHOLE emq.3.2 gate ladder + the >=100 determinism loop over the flow
# suites + the NORMAL-risk empty-Lua-diff proof + the boundary grep, and emits a
# PASS/FAIL board, so the green-board is reproducible by anyone and a crash cannot
# evaporate it. It is the records-DISTINCT sibling of echo/rungs/bus/emq_3_1_check.sh
# ({:ok, 45} / the flow family's FIRST board) and emq_2_4_check.sh ({:ok, 43} / the
# parity closer) -- one committed harness per rung, re-pinned to its own board.
#
# IT ASSERTS NOTHING ABOUT THE CODE IT DOES NOT RUN. Each gate is a real subprocess
# (asdf / redis-cli / mix / a Conformance.run/2 + a Flows.children_values/dependencies
# round-trip one-liner over a live 6390 / a git-diff hash); the board reports only
# what the run observed. It edits no code -- the emq.3.2 rung is committed at HEAD
# (6772c39e, "quality gate NOT PASSED" -- this harness is part of making it pass);
# the Stage-3 harden additions (the v1-parity gap tests) are left in the working
# tree for the Director's single ratifying commit. This harness is a process/proof
# artifact, within the implementor/evaluator charter.
#
# THE GATE LADDER (the program law .claude/skills/echo-mq-program.md, bound to
# emq.3.2 by the Stage-3 brief):
#   1. toolchain    -- asdf current erlang (from apps/echo_mq) + redis-cli -p 6390 ping -> PONG
#   2. compile      -- TMPDIR=/tmp mix compile --warnings-as-errors (clean)
#   3. suite        -- the :valkey flow suites (flow_add, flow_fanin, flow_children_values) -> 0 failures
#   4. conformance  -- EchoMQ.Conformance.run/2 over a live 6390 -> {:ok, 46}
#                      (the 45 prior byte-unchanged + flow_children_values registered)
#   5. determinism  -- the >=100 loop over the flow suites (the N+1-mint + fan-in +
#                      child-result-read surface): assert LOOP_N/LOOP_N green. Owns the machine.
#   6. empty-Lua    -- the NORMAL-risk HEADLINE: SHA-256 of EVERY @... Script.new/2 heredoc
#                      body in jobs.ex + flows.ex (15 as-built -- 14 in jobs.ex + 1 in flows.ex)
#                      is byte-IDENTICAL between the pre-emq.3.2 baseline (ec393a72, the parent
#                      of the rung commit) and the working tree. No shipped Lua script edited.
#   7. boundary     -- the rung's diff (ec393a72..WORKTREE) touches NO echo_wire / keyspace.ex /
#                      admin.ex / mix.lock / apps/echomq, and adds ZERO DEL/HDEL/UNLINK of a flow
#                      subkey (:dependencies/:processed) -- the L-5/N1 lifecycle carry stays a
#                      NAMED carry, admin.ex UNTOUCHED (INV7).
#
# EXPECTED-NOT-A-FAILURE: a single captured-log line
#   "[error] GenServer ... terminating ... (stop) ... killed"
# in a full-suite run is the watch-plane reconnect-kill DRILL of the emq.2.3
# resubscribe / Events-across-a-reconnect scenario, NOT a test failure -- ExUnit
# still reports 0 failures. The board keys off the ExUnit "0 failures" summary + the
# exit code, NEVER a grep for "error" in the captured log.
#
# Spec: docs/echo_mq/specs/emq.3.2.md (D2-D6, INV1-INV8) ; family: emq.3.md.
# Reproducible: re-running yields the same board (the same commands, the same pinned
# counts, the same heredoc hashes); only timing-jitter numbers (wall seconds) vary.

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

# the pre-emq.3.2 baseline -- the PARENT of the rung commit 6772c39e ("[emq] 3.2.
# quality gate NOT PASSED"). The empty-Lua-diff + boundary gates diff the rung's
# change (baseline..WORKTREE) so they see the committed rung AND the Stage-3 harden
# additions on top. Overridable for re-pin (BASELINE=<sha> bash ...).
BASELINE="${BASELINE:-ec393a72}"

# the flow suites -- the >=100 loop's machine (the N+1-mint + fan-in + child-result
# read surface). flow_children_values is emq.3.2's; flow_add + flow_fanin are
# emq.3.1's (the read rung must not regress the write side).
FLOW_SUITES=(
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
# lines strictly between a `Script.new(... """` opener and its closing `"""`. The
# awk state machine pairs the two `"""` markers per script. This is the byte set
# the NORMAL-risk proof asserts unchanged.
heredoc_bodies() {  # content on stdin -> heredoc body lines on stdout
  awk '/Script\.new\(/{f=1} f&&/"""/{c++; if(c==2){f=0;c=0;next}} f&&c==1{print}'
}

echo "header: emq.3.2 child-result reads gate ladder | $(cd "${APP_DIR}" && elixir -e 'IO.write(System.version())' 2>/dev/null) Elixir / OTP $(erl -noshell -eval 'io:format("~s",[erlang:system_info(otp_release)]), halt().' 2>/dev/null) | Valkey :${PORT} | LOOP_N=${LOOP_N} | baseline ${BASELINE} | $(date -u +%Y-%m-%dT%H:%M:%SZ)"
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
  emit "compile" ok "TMPDIR=/tmp mix compile --warnings-as-errors is clean in apps/echo_mq (the new EchoMQ.Flows.children_values/3 + dependencies/3 reads + the complete/5 result arg + the conformance flow_children_values probe all compile clean, no warning, no undefined verb)"
else
  emit "compile" FAIL "mix compile --warnings-as-errors rc=${COMPILE_RC}; tail: $(echo "${COMPILE_OUT}" | tail -3 | tr '\n' '|')"
fi

# == gate 3: the :valkey flow suites -> 0 failures ===================================
SUITE_OUT="$(run_suites 0 "${FLOW_SUITES[@]}")"
SUITE_RC=$?
SUITE_SUMMARY="$(echo "${SUITE_OUT}" | grep -E '[0-9]+ tests?, [0-9]+ failures?' | tail -1)"
if [ "${SUITE_RC}" -eq 0 ] && echo "${SUITE_SUMMARY}" | grep -qE ', 0 failures'; then
  emit "suite" ok "TMPDIR=/tmp mix test --include valkey over the flow suites (flow_add, flow_fanin, flow_children_values) -> [${SUITE_SUMMARY}] in apps/echo_mq (the child-result reads + the v1-parity Stage-3 depth tests -- the 3-child results read, the partial-fan-in map, the L-5 lifecycle honest bound -- all green)"
else
  emit "suite" FAIL "mix test (flow suites) rc=${SUITE_RC}; summary='${SUITE_SUMMARY:-<none>}'; tail: $(echo "${SUITE_OUT}" | tail -4 | tr '\n' '|')"
fi

# == gate 7 (pre): dbsize BEFORE the loop ============================================
DBSIZE_BEFORE="$(redis-cli -p "${PORT}" dbsize 2>/dev/null)"

# == gate 4: Conformance.run/2 over a live 6390 -> {:ok, 46} ==========================
# a direct one-liner (NOT via the pin test) -- the conformance run is its own gate
# beyond the unit suites; it drives the public surface and returns {:ok, n}. The 45
# prior scenarios byte-unchanged + flow_children_values probe-registered (additive
# minor, S-3/section 5).
CONF_OUT="$(cd "${APP_DIR}" && TMPDIR=/tmp mix run --no-start -e '
  :ok = EchoData.Snowflake.start(34)
  {:ok, conn} = EchoMQ.Connector.start_link(port: 6390)
  q = "emq32.harness#{System.unique_integer([:positive])}"
  case EchoMQ.Conformance.run(conn, q) do
    {:ok, n} -> IO.puts("CONFORMANCE_RESULT={:ok, #{n}}")
    other    -> IO.puts("CONFORMANCE_RESULT=#{inspect(other)}")
  end
' 2>&1)"
CONF_LINE="$(echo "${CONF_OUT}" | grep -E '^CONFORMANCE_RESULT=' | tail -1)"
if [ "${CONF_LINE}" = "CONFORMANCE_RESULT={:ok, 46}" ]; then
  emit "conformance" ok "EchoMQ.Conformance.run/2 over a live :${PORT} returns {:ok, 46} -- the 45 prior scenarios byte-unchanged (the 18 state-machine + the emq.2.x parity cluster + flow_add + flow_fanin) + flow_children_values (the child-result read: distinct results keyed by child id, the dependency count down to 0, the reads pure -- additive-minor, probe-registered in the same change)"
else
  emit "conformance" FAIL "Conformance.run/2 result='${CONF_LINE:-<none>}' (want {:ok, 46}); tail: $(echo "${CONF_OUT}" | tail -4 | tr '\n' '|')"
fi

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
  emit "determinism" ok "the >=100 determinism loop is ${LOOP_PASS}/${LOOP_N} green over the flow suites (flow_add + flow_fanin + flow_children_values -- the N+1-mint + fan-in + child-result-read surface); no same-ms mint collision among the N+1 ids minted per flow, no fan-in or read race surfaced across ${LOOP_N} owning-the-machine iterations"
else
  emit "determinism" FAIL "the determinism loop went RED at iteration ${LOOP_FIRST_FAIL}/${LOOP_N} (${LOOP_PASS} green before it); tail: ${LOOP_FAIL_TAIL}"
fi

# == gate 7 (post): dbsize AFTER == BEFORE (the leak check) ==========================
DBSIZE_AFTER="$(redis-cli -p "${PORT}" dbsize 2>/dev/null)"
if [ -n "${DBSIZE_BEFORE}" ] && [ "${DBSIZE_BEFORE}" = "${DBSIZE_AFTER}" ]; then
  emit "dbsize-flat" ok "redis-cli -p ${PORT} dbsize is FLAT across the loop: ${DBSIZE_BEFORE} before == ${DBSIZE_AFTER} after (the flow suites purge what they mint via on_exit -- the per-test sub-queue KEYS-pattern DEL). The absolute count floats run-to-run (Valkey residue); only the delta is asserted. NOTE: a flow's :dependencies/:processed subkeys outlive the parent ROW + obliterate within a run -- the per-test purge sweeps them, and the new L-5 honest-bound test PINS that as-built leak (the obliterate non-sweep is the NAMED carry, D-2/N1 -> emq.3.x lifecycle rung)"
else
  emit "dbsize-flat" FAIL "dbsize drifted across the loop: ${DBSIZE_BEFORE:-<none>} before -> ${DBSIZE_AFTER:-<none>} after (a key leak: a suite minted keys its on_exit did not purge)"
fi

# == gate 6: the empty-Lua-diff (the NORMAL-risk HEADLINE) ===========================
# SHA-256 of every @... Script.new/2 heredoc body in jobs.ex + flows.ex (15 as-built
# -- 14 in jobs.ex + 1 in flows.ex) is byte-IDENTICAL between the pre-emq.3.2
# baseline and the WORKING TREE. R1.B carries the child result through the EXISTING
# ARGV[5] slot, so the @complete Lua body does not change; this proves it -- AND
# proves the 7 emq.2.x mutation scripts (the once-blind-spot the build's Stage-0
# [RECONCILE] widened the proof to cover) are untouched too.
LUA_OK=1
LUA_DETAIL=""
ATTR_TOTAL=0
for f in lib/echo_mq/jobs.ex lib/echo_mq/flows.ex; do
  PRE_BODY="$(git show "${BASELINE}:echo/apps/echo_mq/${f}" 2>/dev/null | heredoc_bodies)"
  POST_BODY="$(cat "${APP_DIR}/${f}" 2>/dev/null | heredoc_bodies)"
  PRE_HASH="$(printf '%s' "${PRE_BODY}" | shasum -a 256 | awk '{print $1}')"
  POST_HASH="$(printf '%s' "${POST_BODY}" | shasum -a 256 | awk '{print $1}')"
  ATTR_N="$(grep -cE '@[a-z_]+ +Script\.new' "${APP_DIR}/${f}")"
  ATTR_TOTAL=$((ATTR_TOTAL + ATTR_N))
  if [ "${PRE_HASH}" = "${POST_HASH}" ] && [ -n "${PRE_HASH}" ]; then
    LUA_DETAIL="${LUA_DETAIL} ${f##*/}=${ATTR_N}attrs/${POST_HASH:0:12}(==)"
  else
    LUA_OK=0
    LUA_DETAIL="${LUA_DETAIL} ${f##*/}: pre=${PRE_HASH:0:12} post=${POST_HASH:0:12} DIFFERS"
  fi
done
if [ "${LUA_OK}" -eq 1 ] && [ "${ATTR_TOTAL}" -eq 15 ]; then
  emit "empty-Lua" ok "every @... Script.new/2 heredoc body in jobs.ex + flows.ex (${ATTR_TOTAL} attrs as-built -- 14 jobs.ex + 1 flows.ex) is byte-IDENTICAL ${BASELINE}(pre-emq.3.2) <-> worktree by SHA-256:${LUA_DETAIL}. No shipped Lua script edited -- the NORMAL-risk headline (R1.B threads the result through the EXISTING ARGV[5] slot; the @complete body, and the 7 emq.2.x mutation scripts, untouched)"
else
  emit "empty-Lua" FAIL "the empty-Lua-diff did not hold (or attr count != 15: got ${ATTR_TOTAL}):${LUA_DETAIL}"
fi

# == gate 7: the boundary grep =======================================================
# the rung's diff (baseline..WORKTREE, the echo/apps/echo_mq + the rungs harness)
# touches NO echo_wire / keyspace.ex / admin.ex / mix.lock / apps/echomq, and adds
# ZERO DEL/HDEL/UNLINK of a flow subkey -- the L-5/N1 lifecycle carry stays NAMED,
# admin.ex UNTOUCHED (INV7). Computed over BOTH committed (baseline..HEAD) and
# uncommitted (the working tree) changes so the Stage-3 harden additions are seen.
OUT_OF_BOUNDS="$(
  {
    git -C "${REPO_ROOT}" diff --name-only "${BASELINE}" -- echo/apps/echo_wire echo/apps/echomq echo/mix.lock echo/apps/echo_mq/lib/echo_mq/keyspace.ex echo/apps/echo_mq/lib/echo_mq/admin.ex 2>/dev/null
    git -C "${REPO_ROOT}" diff --name-only -- echo/apps/echo_wire echo/apps/echomq echo/mix.lock echo/apps/echo_mq/lib/echo_mq/keyspace.ex echo/apps/echo_mq/lib/echo_mq/admin.ex 2>/dev/null
  } | sort -u
)"
# the ADDED ('+') lines of the rung's echo_mq lib diff: assert none introduces a
# destructive op on a flow subkey (:dependencies/:processed). The test files MAY
# read/assert these keys (the L-5 honest-bound test EXISTS-checks them) -- the lib
# is the surface INV7 governs, so this scopes to lib/echo_mq.
SUBKEY_DESTROY="$(
  {
    git -C "${REPO_ROOT}" diff "${BASELINE}" -- echo/apps/echo_mq/lib 2>/dev/null
    git -C "${REPO_ROOT}" diff -- echo/apps/echo_mq/lib 2>/dev/null
  } | grep -E '^\+' | grep -E "(DEL|HDEL|UNLINK)" | grep -E ":dependencies|:processed" || true
)"
if [ -z "${OUT_OF_BOUNDS}" ] && [ -z "${SUBKEY_DESTROY}" ]; then
  emit "boundary" ok "the rung diff (${BASELINE}..worktree) touches NONE of echo_wire / apps/echomq / mix.lock / keyspace.ex / admin.ex, and adds ZERO DEL/HDEL/UNLINK of a flow subkey in lib/echo_mq -- the diff stays inside echo/apps/echo_mq (Flows reads + the complete/5 host arg + conformance + tests) and the L-5/N1 lifecycle carry stays NAMED (admin.ex UNTOUCHED, INV7)"
else
  emit "boundary" FAIL "boundary breach: out-of-bounds files=[$(echo ${OUT_OF_BOUNDS} | tr '\n' ' ')] ; flow-subkey-destroy=[$(echo "${SUBKEY_DESTROY}" | tr '\n' '|')]"
fi

# == the board ======================================================================
echo "----------------------------------------------------------------------"
if [ "${FAIL}" -eq 0 ]; then
  echo "PASS ${PASS}/$((PASS+FAIL)) -- emq.3.2 child-result reads gate ladder GREEN + harness-reproducible"
  exit 0
else
  echo "FAIL ${FAIL}/$((PASS+FAIL)) gate(s) red (PASS ${PASS})"
  exit 1
fi
