#!/usr/bin/env bash
#
# edge-deploy.sh — promote (or roll back) the Codemoji React game on the edge bucket.
#
# Builds the content-hashed game bundle, uploads every hashed file to the dedicated
# Tigris edge bucket under a long immutable cache, then flips the root manifest.json
# pointer (short cache) that `Codemojex.Edge.game_url/0` reads. The bundle is uploaded
# BEFORE the pointer is flipped, so the pointer never names a file that isn't there.
# No `mix release`, no `fly deploy`, no socket drop. Rollback re-points the manifest at
# a previous (still-immutable) hash — no rebuild.
#
# Setup, the env vars below, and the boundary (this publishes to a live bucket — the
# Operator runs it): echo/docs/codemojex/edge-bucket-setup.md
#
# Usage:
#   scripts/edge-deploy.sh                       # build + upload + flip the pointer
#   scripts/edge-deploy.sh --dry-run             # build + show what WOULD upload/flip
#   scripts/edge-deploy.sh --rollback game-<hash>.js   # re-point manifest only, no rebuild
#
# Required env (source echo/.env first — mix/this script do NOT auto-load it):
#   TIGRIS_EDGE_BUCKET            the dedicated edge bucket name (e.g. codemojex-edge-prod)
#   TIGRIS_EDGE_ACCESS_KEY_ID     the bucket's keypair (from `fly storage create`)
#   TIGRIS_EDGE_SECRET_ACCESS_KEY
#   TIGRIS_EDGE_ENDPOINT_URL      the Tigris S3 endpoint (same as your AWS_ENDPOINT_URL_S3)
# Optional:
#   GAME_EDGE_HOST              public host (default edge.codemoji.games; Codemojex.Edge reads the same)
#   TIGRIS_EDGE_REGION           default "auto"
#
# Requires: aws CLI, node, npm, curl.

set -euo pipefail

# --- args ---
DRY_RUN=0
ROLLBACK=""
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run)  DRY_RUN=1 ;;
    --rollback) ROLLBACK="${2:?--rollback needs a game-<hash>.js filename}"; shift ;;
    -h|--help)  sed -n '2,40p' "$0"; exit 0 ;;
    *) echo "edge-deploy: unknown arg '$1' (try --help)" >&2; exit 2 ;;
  esac
  shift
done

# --- config from env ---
HOST="${GAME_EDGE_HOST:-edge.codemoji.games}"
BUCKET="s3://${TIGRIS_EDGE_BUCKET:?set TIGRIS_EDGE_BUCKET (see edge-bucket-setup.md)}"
ENDPOINT="${TIGRIS_EDGE_ENDPOINT_URL:?set TIGRIS_EDGE_ENDPOINT_URL (the Tigris S3 endpoint)}"

# Scope the AWS CLI to the EDGE bucket's keypair for this process only, so it never
# clobbers the account-level AWS_* creds used elsewhere.
export AWS_ACCESS_KEY_ID="${TIGRIS_EDGE_ACCESS_KEY_ID:?set TIGRIS_EDGE_ACCESS_KEY_ID}"
export AWS_SECRET_ACCESS_KEY="${TIGRIS_EDGE_SECRET_ACCESS_KEY:?set TIGRIS_EDGE_SECRET_ACCESS_KEY}"
export AWS_REGION="${TIGRIS_EDGE_REGION:-auto}"

for bin in aws node curl; do
  command -v "$bin" >/dev/null 2>&1 || { echo "edge-deploy: '$bin' not found on PATH" >&2; exit 1; }
done

s3() { aws s3 "$@" --endpoint-url "$ENDPOINT"; }

flip_pointer() { # $1 = game entry filename (game-<hash>.js)
  local url="https://${HOST}/$1"
  if [ "$DRY_RUN" = 1 ]; then echo "[dry-run] manifest.json -> {\"game\":\"$url\"}"; return; fi
  local tmp; tmp="$(mktemp)"; printf '{"game":"%s"}\n' "$url" > "$tmp"
  # short cache: the pointer is the only mutable object; everything it names is immutable
  s3 cp "$tmp" "$BUCKET/manifest.json" \
    --cache-control "public,max-age=10,must-revalidate" \
    --content-type "application/json"
  rm -f "$tmp"
  echo "pointer -> $url"
}

verify() {
  echo "--- verify ---"
  curl -fsS  "https://${HOST}/manifest.json" && echo
  curl -fsSI "https://${HOST}/$1" | head -1
  echo "Tip: set the per-deploy fallback -> fly secrets set GAME_ASSET_URL=https://${HOST}/$1"
}

# --- rollback: re-point only, no rebuild (old hashes are immutable + retained) ---
if [ -n "$ROLLBACK" ]; then
  echo "rollback: re-pointing manifest at $ROLLBACK"
  flip_pointer "$ROLLBACK"
  [ "$DRY_RUN" = 0 ] && verify "$ROLLBACK"
  exit 0
fi

# --- 1. build the content-hashed game bundle ---
cd "$(dirname "$0")/../assets"
echo "--- build (vite.config.ts -> ../priv/static/game) ---"
npm ci
npm run build
OUT="../priv/static/game"

ENTRY="$(node -e '
  const fs=require("fs"); const dir=process.argv[1];
  for (const p of [dir+"/.vite/manifest.json", dir+"/manifest.json"]) {
    if (fs.existsSync(p)) {
      const m=JSON.parse(fs.readFileSync(p,"utf8"));
      const e=Object.values(m).find(x=>x.isEntry) || m["src/index.tsx"];
      if (e && e.file) { process.stdout.write(e.file); process.exit(0); }
    }
  }
  process.exit(1);
' "$OUT")" || { echo "edge-deploy: could not read the game entry from the vite manifest" >&2; exit 1; }
echo "built game entry: $ENTRY"

# --- 2. upload every hashed file IMMUTABLY (the pointer is NOT touched yet) ---
echo "--- upload (immutable) ---"
shopt -s nullglob
for f in "$OUT"/game-*; do
  name="$(basename "$f")"
  case "$name" in
    *.js)  ct="application/javascript" ;;
    *.css) ct="text/css" ;;
    *.map) ct="application/json" ;;
    *.svg) ct="image/svg+xml" ;;
    *.png) ct="image/png" ;;
    *.woff2) ct="font/woff2" ;;
    *)     ct="application/octet-stream" ;;
  esac
  if [ "$DRY_RUN" = 1 ]; then echo "[dry-run] upload $name ($ct, immutable)"; continue; fi
  s3 cp "$f" "$BUCKET/$name" \
    --cache-control "public,max-age=31536000,immutable" \
    --content-type "$ct"
done

# --- 3. flip the pointer LAST ---
echo "--- flip pointer ---"
flip_pointer "$ENTRY"

# --- 4. verify ---
[ "$DRY_RUN" = 0 ] && verify "$ENTRY"
echo "done."
