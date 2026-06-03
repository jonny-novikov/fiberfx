#!/usr/bin/env bash
# reconcile.sh — apply the deterministic, route-verified repairs to agile-course
# pages and re-grade them, using the canonical /course/agile-agent-workflow mount.
# This is what the on-signal conformance Agent runs; it is also safe to run by
# hand. It wraps `cms check --fix --routes-from <mount>=<dir>`:
#   - clamp/calc spacing repair (the invalid "1.9rem+4.2vw" -> "1.9rem + 4.2vw")
#   - relink: normalize a shortened prefix onto the mount + swap an author chapter
#     slug for the page's real chapter dir
#   - then the nine Apollo gates.
# It ONLY rewrites a link to a route that EXISTS on disk, so it never invents a
# target: a page that links to not-yet-authored pages stays FAIL, surfacing the
# real gap instead of papering over it. With no args it reconciles every page.
set -uo pipefail

REPO="${REPO:-/Users/jonny/dev/jonnify}"
SECTION="$REPO/html/agile-agent-workflow"
MOUNT="${MOUNT:-/course/agile-agent-workflow}"
# Positional chapter slug -> semantic dir, for relink. Extend as chapters land.
ALIASES="${ALIASES:-a0=intro,a1=why}"
CMS="$REPO/apps/jonnify-cms/bin/cms"

cd "$REPO" 2>/dev/null || { echo "FATAL repo not found: $REPO"; exit 1; }
[ -x "$CMS" ] || { echo "FATAL cms binary missing: $CMS"; exit 1; }

files=()
if [ "$#" -eq 0 ]; then
  while IFS= read -r f; do files+=("$f"); done < <(find "$SECTION" -type f -name '*.html' | sort)
else
  files=("$@")
fi

exec "$CMS" check --fix --routes-from "$MOUNT=$SECTION" --chapter-alias "$ALIASES" --require-refs "${files[@]}"
