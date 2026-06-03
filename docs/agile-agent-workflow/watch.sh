#!/usr/bin/env bash
# agile-watcher — detect new/changed pages under html/agile-agent-workflow and
# emit ONE drift verdict line per page. This is the cheap, always-on half of the
# two-tier pattern (mirrors docs/elixir/references/watch_refs.sh): a read-only
# detector that NEVER edits. Conformance (relink + clamp-fix + verify) is done by
# a background Agent that the operator spawns on a DRIFT line. Keeping the watcher
# read-only is deliberate — it cannot race a concurrent IDE edit, and because a
# conformed page is A+ (no drift) it never re-signals its own fix.
#
# Output contract (one line per new/changed page; selective, so silence == no
# new/changed files):
#   BASELINE  <n> pages armed                       (once, at startup)
#   DRIFT     <relpath> status=<S> clamps=<n> svg=<n>   (actionable)
#   CLEAN     <relpath> status=PASS clamps=0 svg=<n>     (informational)
# A DRIFT line is the signal to spawn the conformance Agent for that page (the
# operator does that; the watcher itself never edits).
#
# State is a /tmp snapshot file (path<TAB>sha per line) — no bash-4 associative
# arrays, so it runs on the stock macOS bash 3.2.
set -uo pipefail

REPO="${REPO:-/Users/jonny/dev/jonnify}"
SECTION="$REPO/html/agile-agent-workflow"
MOUNT="${MOUNT:-/course/agile-agent-workflow}"   # canonical URL mount (NOT the dir name)
ROUTES="$MOUNT=$SECTION"                          # cms --routes-from mount=dir form
CMS="$REPO/apps/jonnify-cms/bin/cms"
INTERVAL="${INTERVAL:-5}"
STATE="${STATE:-/tmp/agile-watch.state}"
TAB="$(printf '\t')"

cd "$REPO" 2>/dev/null || { echo "FATAL repo not found: $REPO"; exit 1; }
[ -x "$CMS" ] || { echo "FATAL cms binary missing: $CMS (build it: cd apps/jonnify-cms && GOWORK=off go build -o bin/cms .)"; exit 1; }

snapshot() {
  find "$SECTION" -type f -name '*.html' | sort | while IFS= read -r f; do
    printf '%s%s%s\n' "$f" "$TAB" "$(shasum "$f" | awk '{print $1}')"
  done
}

# drift_line inspects one page and prints DRIFT (actionable) or CLEAN (informational).
# The cms check is route-aware (--routes-from mount=dir) so its STATUS is the
# authoritative link verdict; clamps and svg=0 are extra design-system signals.
drift_line() {
  f="$1"
  rel="${f#"$REPO"/}"
  clamps="$(grep -oE '[0-9](rem|em|vw|vh|px|ch|%)[+-][0-9.]' "$f" | wc -l | tr -d ' ')"
  svg="$(grep -oiE '<svg' "$f" | wc -l | tr -d ' ')"
  if "$CMS" check --routes-from "$ROUTES" "$f" >/dev/null 2>&1; then status=PASS; else status=FAIL; fi
  if [ "$status" = FAIL ] || [ "$clamps" -gt 0 ] || [ "$svg" -eq 0 ]; then
    echo "DRIFT $rel status=$status clamps=$clamps svg=$svg"
  else
    echo "CLEAN $rel status=PASS clamps=0 svg=$svg"
  fi
}

trap 'echo "agile-watcher stopped"; exit 0' INT TERM

rm -f "$STATE"
first=1
while true; do
  new="$(snapshot)"
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    f="${line%%"$TAB"*}"
    if [ "$first" = 1 ]; then
      # Baseline: surface pages already drifting, so arming reports the backlog.
      v="$(drift_line "$f")"; case "$v" in DRIFT*) echo "$v";; esac
    elif ! grep -qF "$line" "$STATE" 2>/dev/null; then
      # Steady state: a new or changed page — DRIFT (act) or CLEAN (resolved).
      drift_line "$f"
    fi
  done <<EOF
$new
EOF
  printf '%s\n' "$new" > "$STATE"
  if [ "$first" = 1 ]; then
    n="$(printf '%s\n' "$new" | grep -c .)"
    echo "BASELINE $n pages armed under html/agile-agent-workflow (read-only; DRIFT on new/changed, plus any pre-existing drift listed above)"
    first=0
  fi
  sleep "$INTERVAL"
done
