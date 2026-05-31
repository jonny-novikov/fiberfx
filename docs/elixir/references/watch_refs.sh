#!/usr/bin/env bash
# watch_refs.sh — monitor the Elixir course pages and keep references current.
#
# Polls elixir/ recursively for NEW *.html pages. On each new page it:
#   1. (always, safe) regenerates the bibliography and re-mirrors offline copies.
#   2. (REFS_AI=1) spawns a scoped headless `claude -p` agent that, for that page's
#      module, deep-researches references if the module has none yet, then inserts a
#      gated A+ "References" block into the page — validated with `cms check`.
#
# Portable: no fswatch (polling), macOS bash 3.2 safe, no GNU `timeout`/`flock`.
#
# Commands:  start | stop | status | restart | once | queue | baseline
# Env:       INTERVAL=20  REFS_AI=0|1  MAX_AI_PER_HOUR=12  AI_TIMEOUT=1200
#
# Safety: only Created *.html under elixir/ (not references/, drafts/, *.part);
# single-flight lock; processed-dedupe; per-hour AI throttle (overflow -> queue);
# the agent run is scoped (one page) with an ephemeral --allowedTools allowlist —
# no project-settings change, no --dangerously-skip-permissions. Stop any time.
set -uo pipefail

ROOT="/Users/jonny/dev/jonnify"
SELF="$(cd "$(dirname "$0")" 2>/dev/null && pwd)/$(basename "$0")"
WATCH_DIR="$ROOT/elixir"
KB_DIR="$ROOT/docs/elixir/kb"
REF_DIR="$ROOT/docs/elixir/references"
CMS_DIR="$ROOT/apps/jonnify-cms"

STATE="$REF_DIR/.watch/state"        # last-seen page list
PROC="$REF_DIR/.watch/processed"     # pages already handled
QUEUE="$REF_DIR/.watch/queue"        # pages deferred (throttle / no claude)
RUNLOG="$REF_DIR/.watch/airuns"      # epoch timestamps of AI runs (throttle)
LOG="$REF_DIR/watch.log"
PIDFILE="$REF_DIR/.watch/pid"
LOCK="$REF_DIR/.watch/lock"          # mkdir-based single-flight lock

INTERVAL="${INTERVAL:-20}"
REFS_AI="${REFS_AI:-0}"
MAX_AI_PER_HOUR="${MAX_AI_PER_HOUR:-12}"
AI_TIMEOUT="${AI_TIMEOUT:-1200}"
CLAUDE="${CLAUDE:-claude}"

mkdir -p "$REF_DIR/.watch"
log() { echo "[$(date '+%F %T')] $*" >> "$LOG"; }

list_pages() {
  find "$WATCH_DIR" -type f -name '*.html' 2>/dev/null \
    | grep -v -e '/\.' -e '\.part$' | LC_ALL=C sort
}

sync_refs() {
  ( cd "$KB_DIR" && python3 _gen_refs_md.py ) >>"$LOG" 2>&1
  ( cd "$REF_DIR" && python3 fetch_refs.py ) >>"$LOG" 2>&1
  log "synced bibliography + offline mirror"
}

# run_with_timeout SECS cmd...   (portable; no GNU timeout)
run_with_timeout() {
  local t="$1"; shift
  "$@" & local cpid=$!
  ( sleep "$t"; kill -0 "$cpid" 2>/dev/null && kill "$cpid" 2>/dev/null ) & local wpid=$!
  wait "$cpid" 2>/dev/null; local rc=$?
  kill "$wpid" 2>/dev/null
  return $rc
}

ai_runs_last_hour() {
  local now cutoff; now=$(date +%s); cutoff=$((now - 3600))
  [ -f "$RUNLOG" ] || { echo 0; return; }
  awk -v c="$cutoff" '$1>=c{n++} END{print n+0}' "$RUNLOG"
}

ai_update() {
  local page="$1"
  if [ "$REFS_AI" != "1" ]; then echo "$page" >> "$QUEUE"; log "queued (sync mode): $page"; return; fi
  if ! command -v "$CLAUDE" >/dev/null 2>&1; then echo "$page" >> "$QUEUE"; log "queued (no claude): $page"; return; fi
  if [ "$(ai_runs_last_hour)" -ge "$MAX_AI_PER_HOUR" ]; then echo "$page" >> "$QUEUE"; log "queued (throttle $MAX_AI_PER_HOUR/h): $page"; return; fi

  local rel="${page#$ROOT/}"
  log "deep-research + integrate references for: $rel"
  date +%s >> "$RUNLOG"
  local prompt
  prompt="A new page was added to the Elixir course at $page. Do ONLY the reference work for THIS page; edit no other page.
1. Identify its module id + title from the manifest (docs/elixir/kb/build_page.py, or: cd apps/jonnify-cms && GOWORK=off ./bin/cms manifest).
2. If that module id has NO entry in docs/elixir/kb/_gen_refs_md.py REFS, use deep, web-verified research to find 2-4 authoritative primary sources (official Elixir/Erlang/Phoenix docs, primary papers, canonical books); adversarially confirm each URL resolves; add them to REFS keyed by the module id.
3. Regenerate: cd docs/elixir/kb && python3 _gen_refs_md.py ; then mirror: cd docs/elixir/references && python3 fetch_refs.py
4. Insert ONE gated 'References' block into $page per .claude/skills/elixir-technical-writer/references/references-section.md, sourced from docs/elixir/kb/elixir-references.md for that module; internal cross-links only to live/built routes.
5. Validate: cd apps/jonnify-cms && GOWORK=off ./bin/cms check $page — it MUST end STATUS: PASS, grade A+. Fix until it passes.
Keep prose impersonal: no first-person narration, no perceptual verbs with tool subjects, no hype/dismissive words."

  run_with_timeout "$AI_TIMEOUT" "$CLAUDE" -p "$prompt" \
    --permission-mode acceptEdits \
    --allowedTools "Read,Edit,Write,Grep,Glob,WebSearch,WebFetch,Skill,Bash" \
    --max-turns 60 >>"$LOG" 2>&1 \
    && log "done: $rel" || log "AI update failed/timed out: $rel (left for retry; re-queue manually if needed)"
}

scan_once() {
  if ! mkdir "$LOCK" 2>/dev/null; then return 0; fi
  trap 'rmdir "$LOCK" 2>/dev/null' RETURN
  local cur; cur="$(list_pages)"
  if [ ! -f "$STATE" ]; then printf '%s\n' "$cur" > "$STATE"; : > "$PROC"; printf '%s\n' "$cur" > "$PROC"; log "baselined $(printf '%s\n' "$cur" | grep -c . ) pages"; return 0; fi
  local newp; newp="$(LC_ALL=C comm -23 <(printf '%s\n' "$cur") "$STATE" 2>/dev/null)"
  printf '%s\n' "$cur" > "$STATE"
  [ -z "$newp" ] && return 0
  local did_sync=0
  printf '%s\n' "$newp" | while IFS= read -r p; do
    [ -z "$p" ] && continue
    grep -Fxq "$p" "$PROC" 2>/dev/null && continue
    log "NEW PAGE: ${p#$ROOT/}"
    if [ "$did_sync" = 0 ]; then sync_refs; did_sync=1; fi
    ai_update "$p"
    echo "$p" >> "$PROC"
  done
}

baseline() { local cur; cur="$(list_pages)"; printf '%s\n' "$cur" > "$STATE"; printf '%s\n' "$cur" > "$PROC"; : > "$QUEUE"; log "baselined $(printf '%s\n' "$cur" | grep -c .) pages (none will be treated as new)"; echo "baselined $(printf '%s\n' "$cur" | grep -c .) pages"; }

loop() { log "watcher loop start (interval ${INTERVAL}s, REFS_AI=$REFS_AI)"; while true; do scan_once; sleep "$INTERVAL"; done; }

is_running() { [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; }

case "${1:-}" in
  start)
    if is_running; then echo "already running (PID $(cat "$PIDFILE"))"; exit 0; fi
    [ -f "$STATE" ] || baseline >/dev/null
    echo "$REFS_AI" > "$REF_DIR/.watch/refs_ai"
    rmdir "$LOCK" 2>/dev/null || true
    REFS_AI="$REFS_AI" INTERVAL="$INTERVAL" MAX_AI_PER_HOUR="$MAX_AI_PER_HOUR" AI_TIMEOUT="$AI_TIMEOUT" \
      nohup "$SELF" loop >/dev/null 2>&1 &
    echo $! > "$PIDFILE"
    echo "started (PID $(cat "$PIDFILE")), interval ${INTERVAL}s, REFS_AI=$REFS_AI, log: $LOG" ;;
  stop)
    if is_running; then kill "$(cat "$PIDFILE")" 2>/dev/null; rm -f "$PIDFILE"; rmdir "$LOCK" 2>/dev/null || true; echo "stopped"; else echo "not running"; rm -f "$PIDFILE"; fi ;;
  restart) "$0" stop; sleep 1; "$0" start ;;
  status)
    mode="$(cat "$REF_DIR/.watch/refs_ai" 2>/dev/null || echo '?')"
    kn=0; [ -f "$STATE" ] && kn=$(grep -c . "$STATE" 2>/dev/null)
    pn=0; [ -f "$PROC" ] && pn=$(grep -c . "$PROC" 2>/dev/null)
    qn=0; [ -f "$QUEUE" ] && qn=$(grep -c . "$QUEUE" 2>/dev/null)
    if is_running; then echo "RUNNING (PID $(cat "$PIDFILE")), REFS_AI=$mode"; else echo "stopped"; fi
    echo "known: $kn | processed: $pn | queued: $qn | AI runs/last hour: $(ai_runs_last_hour)" ;;
  loop) loop ;;
  once) scan_once; echo "scan complete (see $LOG)" ;;
  baseline) baseline ;;
  queue) [ -f "$QUEUE" ] && cat "$QUEUE" || echo "(empty)" ;;
  *) echo "usage: $0 {start|stop|restart|status|once|baseline|queue}"; echo "env: INTERVAL REFS_AI(0/1) MAX_AI_PER_HOUR AI_TIMEOUT"; exit 1 ;;
esac
