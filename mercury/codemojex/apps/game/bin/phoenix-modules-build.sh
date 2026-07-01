#!/usr/bin/env bash
#
# phoenix-modules-build.sh — build the committed "ship-with" phoenix* + boot ESM modules.
#
# Builds three standalone ESM modules ONCE in Mercury and copies them into codemojex's
# committed priv/static/assets/:
#   * @echo/phoenix, @echo/phoenix_live_view — the two vendored client libraries;
#   * @codemojex/liveview-boot — the LiveView boot (app.js), authored in TypeScript
#     (mercury/codemojex/apps/liveview-boot/src/app.ts) against the typed phoenix*
#     packages. It imports them via the <head> import map (CodemojexWeb.Layouts.root/1)
#     so the browser resolves ONE shared Socket. It is typechecked + vite-built here
#     (phoenix externalized) — NOT copied raw.
# The three outputs are committed to git (unlike the game island, which edge-deploy.sh
# pushes to Tigris).
#
# Run it after a phoenix / phoenix_live_view lib bump or a boot change, then commit:
#   echo/apps/codemojex/priv/static/assets/{phoenix.js, phoenix_live_view.js, app.js}
#
# Canonical home: mercury/codemojex/apps/game/bin/phoenix-modules-build.sh
# Design:         echo/docs/codemojex/frontend-delivery.design.md §1, §2, §4b
#
# Requires: pnpm (the Mercury workspace deps installed).

set -euo pipefail

# --- absolute paths (cwd-independent; the relative depths are VERIFIED on disk via
#     cd+pwd, never trusted — bin → repo root is the load-bearing hop) ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MERCURY_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"                                   # mercury/
ECHO_STATIC="$(cd "$SCRIPT_DIR/../../../../../echo/apps/codemojex/priv/static" && pwd)" # echo committed static
ASSETS_OUT="$ECHO_STATIC/assets"

PHX_DIST="$MERCURY_ROOT/packages/phoenix/dist/phoenix.js"
LV_DIST="$MERCURY_ROOT/packages/phoenix_live_view/dist/phoenix_live_view.js"
BOOT_DIST="$MERCURY_ROOT/codemojex/apps/liveview-boot/dist/app.js"

command -v pnpm >/dev/null 2>&1 || { echo "phoenix-modules-build: 'pnpm' not found on PATH" >&2; exit 1; }
[ -d "$ASSETS_OUT" ] || { echo "phoenix-modules-build: assets dir missing: $ASSETS_OUT" >&2; exit 1; }

# --- 1. typecheck the boot, then build all three ESM modules (each emits dist/<name>.js) ---
echo "--- typecheck @codemojex/liveview-boot (gate the boot on types before shipping) ---"
( cd "$MERCURY_ROOT" && pnpm --filter @codemojex/liveview-boot typecheck )

echo "--- build @echo/phoenix + @echo/phoenix_live_view + @codemojex/liveview-boot (ESM) ---"
( cd "$MERCURY_ROOT" && pnpm --filter @echo/phoenix build )
( cd "$MERCURY_ROOT" && pnpm --filter @echo/phoenix_live_view build )
( cd "$MERCURY_ROOT" && pnpm --filter @codemojex/liveview-boot build )

[ -f "$PHX_DIST" ]  || { echo "phoenix-modules-build: expected output missing: $PHX_DIST"  >&2; exit 1; }
[ -f "$LV_DIST" ]   || { echo "phoenix-modules-build: expected output missing: $LV_DIST"   >&2; exit 1; }
[ -f "$BOOT_DIST" ] || { echo "phoenix-modules-build: expected output missing: $BOOT_DIST" >&2; exit 1; }

# --- 2. copy the three dist modules into the committed home (§4b) ---
echo "--- copy phoenix* + boot modules -> $ASSETS_OUT ---"
cp "$PHX_DIST"  "$ASSETS_OUT/phoenix.js"
cp "$LV_DIST"   "$ASSETS_OUT/phoenix_live_view.js"
cp "$BOOT_DIST" "$ASSETS_OUT/app.js"

# --- 3. print the resulting byte sizes (for the commit message) ---
echo "--- committed sizes ---"
for f in phoenix.js phoenix_live_view.js app.js; do
  printf '  %-22s %8s bytes\n' "$f" "$(wc -c < "$ASSETS_OUT/$f" | tr -d ' ')"
done
echo "done."
