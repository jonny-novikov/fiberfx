#!/usr/bin/env bash
#
# cm-all.sh — run every Codemojex app concurrently, each pinned to a fixed port
# so they never collide. Ctrl-C tears all of them down; from another shell,
# `pnpm stop` (scripts/kill.sh) does the same by port.
#
# Sibling of dev-all.sh (the Mercury React apps): same contract — a static
# member list, a fixed port each, a process-group trap, then `wait`. The
# Codemojex family owns a port block that does NOT overlap the Mercury apps
# (5173–5177): the api keeps 3000, and 5180+ is reserved for a future
# Codemojex UI (e.g. the SP-2 AI app — see the commented line below).
#
set -euo pipefail
cd "$(dirname "$0")/.."

# Kill the whole process group on exit / interrupt so no server is orphaned.
trap 'kill 0' EXIT INT TERM

# --- Codemojex apps (add one line per new member) ---------------------------
pnpm --filter codemojex-api dev &
# pnpm --filter <codemoji-ai-name> exec vite --port 5180 --strictPort &   # SP-2 (proposed — app does not exist yet)

echo ""
echo "Codemojex apps:"
echo "  api  → http://localhost:3000  (health: /api/health · docs: /docs)"
# echo "  ai   → http://localhost:5180"   # SP-2 (proposed)
echo "(Ctrl-C to stop all · or run \`pnpm stop\` from another shell)"
echo ""

wait
