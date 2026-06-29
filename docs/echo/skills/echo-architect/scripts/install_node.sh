#!/usr/bin/env bash
# Step 6 — Node 22+ and pnpm. Detect-and-reuse a Node >= 22 (the runtime the
# codemojex image already pins); install via NodeSource only if missing/old. pnpm
# is activated through Corepack, which ships with Node — no global npm install.
set -uo pipefail
BENCH_HOME="${BENCH_HOME:-$HOME/.bcs-bench}"
[ -f "$BENCH_HOME/.bcs-env" ] && . "$BENCH_HOME/.bcs-env"
NODE_MIN="${NODE_MIN:-22}"

echo "== node ($NODE_MIN+) + pnpm =="
nmajor="$(node -v 2>/dev/null | sed -E 's/^v([0-9]+).*/\1/' || echo 0)"
if [ "${nmajor:-0}" -ge "$NODE_MIN" ]; then
  echo "   node $(node -v) — reuse"
else
  echo "   node missing or < $NODE_MIN — installing Node $NODE_MIN via NodeSource"
  SUDO=""; [ "$(id -u)" -ne 0 ] && SUDO="sudo"
  curl -fsSL "https://deb.nodesource.com/setup_${NODE_MIN}.x" | $SUDO -E bash - >/dev/null 2>&1 || true
  $SUDO apt-get install -y -qq nodejs || true
  echo "   node $(node -v 2>/dev/null || echo '??')"
fi

# pnpm via corepack (bundled with Node)
if command -v corepack >/dev/null 2>&1; then
  corepack enable >/dev/null 2>&1 || true
  corepack prepare pnpm@latest --activate >/dev/null 2>&1 || corepack enable pnpm >/dev/null 2>&1 || true
fi
if ! command -v pnpm >/dev/null 2>&1; then npm install -g pnpm >/dev/null 2>&1 || true; fi
echo "   pnpm: $(pnpm -v 2>/dev/null || echo 'not installed') (npm $(npm -v 2>/dev/null))"
