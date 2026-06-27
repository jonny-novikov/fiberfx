#!/usr/bin/env bash
#
# kill.sh — stop the Mercury dev servers.
#
# Kills only the listeners on the fixed ports each app is pinned to (see the
# dev:* scripts in package.json). It deliberately does NOT `pkill vite`, which
# would also take down unrelated Vite servers elsewhere on the machine.
#
# Usage:
#   scripts/kill.sh            # stop the four Mercury apps (5173–5176)
#   scripts/kill.sh 5180 5181  # also stop these extra ports
#
set -euo pipefail

# showcase · catalogue · echomq · docs — kept in sync with package.json dev:* ports.
PORTS=(5173 5174 5175 5176 "$@")

killed=0
for port in "${PORTS[@]}"; do
  pids="$(lsof -ti "tcp:${port}" -sTCP:LISTEN 2>/dev/null || true)"
  if [ -n "${pids}" ]; then
    echo "• port ${port} → stopping PID(s): ${pids//$'\n'/ }"
    # shellcheck disable=SC2086 -- intentional word-split: one kill per PID
    kill ${pids} 2>/dev/null || true
    killed=$((killed + 1))
  fi
done

if [ "${killed}" -eq 0 ]; then
  echo "No Mercury dev servers were listening on ${PORTS[*]}."
else
  echo "Stopped ${killed} Mercury dev server(s)."
fi
