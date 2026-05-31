#!/usr/bin/env bash
# watch_health.sh — monitor the Health course pages and keep them consistent + cross-linked.
#
# Polls health/ recursively for NEW *.html module pages. On each new page it:
#   1. (always, safe) records the page and logs it.
#   2. (HEALTH_AI=1) spawns a scoped headless `claude -p` agent that makes THAT page
#      consistent with the course (standard module anatomy + a themed "Источники"
#      References block sourced from docs/health/health-references.md) and CROSS-LINKS it
#      (prev/next chain, parent chapter-hub tile, and the design-doc cross-references),
#      editing only that page + its immediate nav neighbours + the chapter hub.
#
# Sibling of docs/elixir/references/watch_refs.sh; same daemon mechanics. The Health
# course has NO cms/Apollo gate, so the agent self-validates structurally (links resolve,
# one references block, balanced KaTeX) instead of running `cms check`.
#
# Portable: no fswatch (polling), macOS bash 3.2 safe, no GNU `timeout`/`flock`.
#
# Commands:  start | stop | status | restart | once | baseline | queue
# Env:       INTERVAL=30  HEALTH_AI=0|1  MAX_AI_PER_HOUR=10  AI_TIMEOUT=1200
#
# Safety: only Created *.html under health/ (not chapter hubs index.html, not .watch,
# not *.part); single-flight lock; processed-dedupe; per-hour AI throttle (overflow ->
# queue); the agent run is scoped (one page) with an ephemeral --allowedTools allowlist —
# no project-settings change, no --dangerously-skip-permissions. Stop any time.
set -uo pipefail

ROOT="/Users/jonny/dev/jonnify"
SELF="$(cd "$(dirname "$0")" 2>/dev/null && pwd)/$(basename "$0")"
WATCH_DIR="$ROOT/health"
DOC_DIR="$ROOT/docs/health"

STATE="$DOC_DIR/.watch/state"        # last-seen page list
PROC="$DOC_DIR/.watch/processed"     # pages already handled
QUEUE="$DOC_DIR/.watch/queue"        # pages deferred (throttle / no claude / sync mode)
RUNLOG="$DOC_DIR/.watch/airuns"      # epoch timestamps of AI runs (throttle)
LOG="$DOC_DIR/watch.log"
PIDFILE="$DOC_DIR/.watch/pid"
LOCK="$DOC_DIR/.watch/lock"          # mkdir-based single-flight lock

INTERVAL="${INTERVAL:-30}"
HEALTH_AI="${HEALTH_AI:-0}"
MAX_AI_PER_HOUR="${MAX_AI_PER_HOUR:-10}"
AI_TIMEOUT="${AI_TIMEOUT:-1200}"
CLAUDE="${CLAUDE:-claude}"

mkdir -p "$DOC_DIR/.watch"
log() { echo "[$(date '+%F %T')] $*" >> "$LOG"; }

# Module pages only: exclude chapter hubs (index.html), hidden dirs, and partials.
list_pages() {
  find "$WATCH_DIR" -type f -name '*.html' 2>/dev/null \
    | grep -v -e '/\.' -e '\.part$' -e '/index\.html$' | LC_ALL=C sort
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
  if [ "$HEALTH_AI" != "1" ]; then echo "$page" >> "$QUEUE"; log "queued (sync mode): $page"; return; fi
  if ! command -v "$CLAUDE" >/dev/null 2>&1; then echo "$page" >> "$QUEUE"; log "queued (no claude): $page"; return; fi
  if [ "$(ai_runs_last_hour)" -ge "$MAX_AI_PER_HOUR" ]; then echo "$page" >> "$QUEUE"; log "queued (throttle $MAX_AI_PER_HOUR/h): $page"; return; fi

  local rel="${page#$ROOT/}"
  log "consistency + cross-link pass for: $rel"
  date +%s >> "$RUNLOG"
  local prompt
  prompt="A new page was added to the Health course (\"Здоровье как прикладная математика\") at $page. Make ONLY this page consistent with the course and correctly cross-linked; edit OTHER pages solely to wire navigation to/from this page (the prev/next chain and the parent chapter-hub tile). Touch no unrelated content.

Authoritative references:
- Design system, module anatomy, and the cross-reference scheme: docs/health/health-course-design.md
- Per-module citations: docs/health/health-references.md
- The canonical exemplar for module anatomy AND the house references format (boxed card + Google Scholar links): health/risk/bayes.html (Chapter 5, slate)

Do the following, then stop:
1. From the path health/<chapter>/<slug>.html and the design-doc table of contents, determine the chapter, the module slug, and the chapter theme colour token (gold / copper / blue / burgundy / slate / plum / sage / jade).
2. CONSISTENCY. Ensure the standard module anatomy is present: a sticky topbar (brand-mark + breadcrumb + a back-link to /health/<chapter>); a hero; numbered sections; a takeaway block; a themed References section; and a prev/next navigation strip. Match the chapter exemplar tokens. Leave anything already correct untouched.
3. REFERENCES (house format — match Chapter 5 exactly; exemplar health/risk/bayes.html). If the page has no <section class=\"references\">, add one. Copy the .references CSS from the exemplar — a boxed card (surface gradient, border, left border 3px in --<colour>-deep, mono counters in --<colour>-bright, dotted-underline links) — and retheme its slate tokens to this chapter's colour (for the burgundy chapter the bright token is --burgundy-2); insert it once immediately before </style>. Then insert the section immediately before <nav class=\"nav-prev-next\"> (or, for a deep-dive page with no prev/next strip, immediately before <footer class=\"footer\">), in this exact shape:
   <section class=\"references\">
     <div class=\"ref-title\">Источники</div>
     <ol class=\"ref-list\">
       <li>Author (year). <em>Title.</em> Source. <a href=\"https://scholar.google.com/scholar?q=URL+ENCODED+QUERY\" target=\"_blank\" rel=\"noopener\">поиск источника</a></li>
     </ol>
     <p class=\"ref-note\">Образовательный материал — не заменяет консультацию врача. Ссылки ведут на поиск источника; точные реквизиты сверяйте с оригиналом.</p>
   </section>
   Take this module's entries from docs/health/health-references.md: author and year plain, the work title in <em>, source plain, then a Google Scholar SEARCH link — a scholar.google.com/scholar?q= query built from the author + year + title keywords. Never fabricate a DOI or publisher landing URL; a Scholar search query is the only link form. Preserve every KaTeX math span (text between dollar-sign delimiters) exactly.
4. CROSS-LINK. Wire navigation:
   a. In health/<chapter>/index.html, make this module's tile a live anchor to /health/<chapter>/<slug> (status \"Открыть\"), not a locked or placeholder div.
   b. If the previous module in the chapter sequence exists on disk, ensure its prev/next strip's NEXT card is a live anchor to this page (unlock any \"готовится\" placeholder) and ensure this page's PREV card links back to it. Mirror this for the next module if it already exists.
   c. Apply any cross-reference from the design doc's cross-reference (\"Сквозные ссылки\") section that involves this module, linking the relevant phrase to the related module's /health route — only when that target page exists on disk.
5. VALIDATE (dependency-light pre-flight; the course has no per-page CLI gate, though a Playwright DOM toolkit exists at docs/validator/ for deeper manual checks). Confirm: exactly one references block on the page; the dollar-sign delimiters WITHIN the references block you added are balanced (even count — ignore JS template-literal dollars like \${...} elsewhere on the page, which are not KaTeX) and no « » № … characters appear inside any math span (KaTeX strict); and every /health/... link added or unlocked resolves to a file that exists on disk. Fix until all hold.

Keep all prose impersonal: no first-person narration, no perceptual verbs with tool subjects, no hype or dismissive words. Edit no page other than $page, its parent chapter hub, and the immediate prev/next neighbour modules."

  run_with_timeout "$AI_TIMEOUT" "$CLAUDE" -p "$prompt" \
    --permission-mode acceptEdits \
    --allowedTools "Read,Edit,Write,Grep,Glob,WebSearch,WebFetch,Skill,Bash" \
    --max-turns 60 >>"$LOG" 2>&1 \
    && log "done: $rel" || log "AI pass failed/timed out: $rel (left for retry; re-queue manually if needed)"
}

scan_once() {
  if ! mkdir "$LOCK" 2>/dev/null; then return 0; fi
  trap 'rmdir "$LOCK" 2>/dev/null' RETURN
  local cur; cur="$(list_pages)"
  if [ ! -f "$STATE" ]; then printf '%s\n' "$cur" > "$STATE"; : > "$PROC"; printf '%s\n' "$cur" > "$PROC"; log "baselined $(printf '%s\n' "$cur" | grep -c . ) pages"; return 0; fi
  local newp; newp="$(LC_ALL=C comm -23 <(printf '%s\n' "$cur") "$STATE" 2>/dev/null)"
  printf '%s\n' "$cur" > "$STATE"
  [ -z "$newp" ] && return 0
  printf '%s\n' "$newp" | while IFS= read -r p; do
    [ -z "$p" ] && continue
    grep -Fxq "$p" "$PROC" 2>/dev/null && continue
    log "NEW PAGE: ${p#$ROOT/}"
    ai_update "$p"
    echo "$p" >> "$PROC"
  done
}

baseline() { local cur; cur="$(list_pages)"; printf '%s\n' "$cur" > "$STATE"; printf '%s\n' "$cur" > "$PROC"; : > "$QUEUE"; log "baselined $(printf '%s\n' "$cur" | grep -c .) pages (none will be treated as new)"; echo "baselined $(printf '%s\n' "$cur" | grep -c .) module pages"; }

loop() { log "watcher loop start (interval ${INTERVAL}s, HEALTH_AI=$HEALTH_AI)"; while true; do scan_once; sleep "$INTERVAL"; done; }

is_running() { [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; }

case "${1:-}" in
  start)
    if is_running; then echo "already running (PID $(cat "$PIDFILE"))"; exit 0; fi
    [ -f "$STATE" ] || baseline >/dev/null
    echo "$HEALTH_AI" > "$DOC_DIR/.watch/health_ai"
    rmdir "$LOCK" 2>/dev/null || true
    HEALTH_AI="$HEALTH_AI" INTERVAL="$INTERVAL" MAX_AI_PER_HOUR="$MAX_AI_PER_HOUR" AI_TIMEOUT="$AI_TIMEOUT" \
      nohup "$SELF" loop >/dev/null 2>&1 &
    echo $! > "$PIDFILE"
    echo "started (PID $(cat "$PIDFILE")), interval ${INTERVAL}s, HEALTH_AI=$HEALTH_AI, log: $LOG" ;;
  stop)
    if is_running; then kill "$(cat "$PIDFILE")" 2>/dev/null; rm -f "$PIDFILE"; rmdir "$LOCK" 2>/dev/null || true; echo "stopped"; else echo "not running"; rm -f "$PIDFILE"; fi ;;
  restart) "$0" stop; sleep 1; "$0" start ;;
  status)
    mode="$(cat "$DOC_DIR/.watch/health_ai" 2>/dev/null || echo '?')"
    kn=0; [ -f "$STATE" ] && kn=$(grep -c . "$STATE" 2>/dev/null)
    pn=0; [ -f "$PROC" ] && pn=$(grep -c . "$PROC" 2>/dev/null)
    qn=0; [ -f "$QUEUE" ] && qn=$(grep -c . "$QUEUE" 2>/dev/null)
    if is_running; then echo "RUNNING (PID $(cat "$PIDFILE")), HEALTH_AI=$mode"; else echo "stopped"; fi
    echo "known: $kn | processed: $pn | queued: $qn | AI runs/last hour: $(ai_runs_last_hour)" ;;
  loop) loop ;;
  once) scan_once; echo "scan complete (see $LOG)" ;;
  baseline) baseline ;;
  queue) [ -f "$QUEUE" ] && cat "$QUEUE" || echo "(empty)" ;;
  *) echo "usage: $0 {start|stop|restart|status|once|baseline|queue}"; echo "env: INTERVAL HEALTH_AI(0/1) MAX_AI_PER_HOUR AI_TIMEOUT"; exit 1 ;;
esac
