#!/usr/bin/env bash
#
# cm-all.sh — run every Codemojex app concurrently, each pinned to a fixed port
# so they never collide. Ctrl-C tears all of them down; from another shell,
# `pnpm stop` (scripts/kill.sh) does the same by port.
#
# Sibling of dev-all.sh (the Mercury React apps): same contract — a static
# member list, a fixed port each, a process-group trap, then `wait`. The
# Codemojex family owns a port block that does NOT overlap the Mercury apps
# (5173–5177): the admin api keeps 3000, and the UIs live at 5180+
# (dashboard 5180 · economy 5181).
#
set -euo pipefail
cd "$(dirname "$0")/.."

# Kill the whole process group on exit / interrupt so no server is orphaned.
trap 'kill 0' EXIT INT TERM

# --- Codemojex apps (add one line per new member) ---------------------------
# @codemojex/admin is the Fastify API SERVICE (tsx, PORT 3000 from its .env);
# @codemojex/dashboard is the operator-console SPA whose Vite proxy reads it.
pnpm --filter @codemojex/admin dev &
pnpm --filter @codemojex/dashboard exec vite --port 5180 --strictPort &
pnpm --filter @codemojex/economy exec vite --port 5181 --strictPort &

echo ""
echo "Codemojex apps:"
echo "  admin api → http://localhost:3000  (health: /health)"
echo "  dashboard → http://localhost:5180"
echo "  economy   → http://localhost:5181"
echo "(Ctrl-C to stop all · or run \`pnpm stop\` from another shell)"
echo ""

wait
