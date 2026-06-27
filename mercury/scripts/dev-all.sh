#!/usr/bin/env bash
#
# dev-all.sh — run every Mercury app under apps/ concurrently, each pinned to a
# fixed port so they never collide. Ctrl-C tears all of them down; from another
# shell, `pnpm stop` (scripts/kill.sh) does the same by port.
#
set -euo pipefail
cd "$(dirname "$0")/.."

# Kill the whole process group on exit / interrupt so no Vite server is orphaned.
trap 'kill 0' EXIT INT TERM

pnpm --filter @mercury/showcase  exec vite --port 5173 --strictPort &
pnpm --filter @mercury/catalogue exec vite --port 5174 --strictPort &
pnpm --filter @mercury/echomq    exec vite --port 5175 --strictPort &
pnpm --filter @mercury/docs      exec vite --port 5176 --strictPort &
pnpm --filter @mercury/mobile    exec vite --port 5177 --strictPort &

echo ""
echo "Mercury apps:"
echo "  showcase   → http://localhost:5173"
echo "  catalogue  → http://localhost:5174"
echo "  echomq     → http://localhost:5175"
echo "  docs       → http://localhost:5176"
echo "  mobile     → http://localhost:5177"
echo "(Ctrl-C to stop all · or run \`pnpm stop\` from another shell)"
echo ""

wait
