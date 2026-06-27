#!/bin/bash
#
# code-download.sh — mirror Claude Code distributives for the `latest` and
# `stable` channels into a local dist folder.
#
# For each selected channel it resolves the channel's version from
#   ${DOWNLOAD_URL}/<channel>          (the endpoint returns a bare version, e.g. 2.1.195)
# then downloads that version's binaries for each selected platform:
#   ${DOWNLOAD_URL}/<version>/<platform>/<binary>
# into:
#   ${DOWNLOAD_FOLDER}/<channel>/<version>/<platform>/<binary>
#
# The darwin/linux binaries are made executable (chmod +x); the win32 binary
# keeps its .exe extension and is left as-is.
#
# With no flags it mirrors every channel × platform. Flags NARROW the set:
#   --latest --stable                      pick channel(s)        (default: all)
#   --darwin-x64 --linux-x64 --win32-x64   pick platform(s)       (default: all)
#   --dry-run                              HEAD-check only, download nothing
#   -h, --help                             usage
#
# Config is read from a `.env` sitting next to this script:
#   DOWNLOAD_URL     base release URL (…/claude-code-releases)
#   DOWNLOAD_FOLDER  output dir (relative paths resolve next to this script)
#   DOWNLOAD_BINARY  binary basename (e.g. `claude`)
#
# Re-runs are idempotent: a binary whose local size already matches the remote
# Content-Length is skipped.

set -euo pipefail

# --- locate ourselves so the script works from any CWD -----------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- selection state (empty array == "all"), filled by arg parsing -----------
SEL_CHANNELS=()
SEL_PLATFORMS=()
DRY_RUN="${DRY_RUN:-0}"

usage() {
  cat >&2 <<EOF
Usage: $(basename "$0") [CHANNELS] [PLATFORMS] [--dry-run]

Mirror Claude Code distributives into \$DOWNLOAD_FOLDER (config from .env next
to this script). With no channel/platform flags it mirrors every combination;
each flag narrows the selection.

Channels (repeatable; default: all):
  --latest          mirror the 'latest' channel
  --stable          mirror the 'stable' channel

Platforms (repeatable; default: all):
  --darwin-x64      macOS x64 binary   (chmod +x)
  --linux-x64       Linux x64 binary   (chmod +x)
  --win32-x64       Windows x64 binary (.exe)

Other:
  --dry-run         HEAD-check the URLs and report; download nothing
  -h, --help        show this help

Examples:
  $(basename "$0")                         # everything
  $(basename "$0") --stable                # stable channel, all platforms
  $(basename "$0") --latest --darwin-x64   # only latest/darwin-x64
  $(basename "$0") --stable --linux-x64 --win32-x64
EOF
}

# contains <needle> <haystack...> -> 0 if present
contains() {
  local needle="$1"; shift
  local x
  for x in "$@"; do [[ "$x" == "$needle" ]] && return 0; done
  return 1
}

# --- parse args (before sourcing .env so --help works without config) --------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --latest|--stable)                     SEL_CHANNELS+=("${1#--}") ;;
    --darwin-x64|--linux-x64|--win32-x64)  SEL_PLATFORMS+=("${1#--}") ;;
    --dry-run)                             DRY_RUN=1 ;;
    -h|--help)                             usage; exit 0 ;;
    *) echo "error: unknown argument: $1" >&2; usage; exit 2 ;;
  esac
  shift
done

# --- preflight ---------------------------------------------------------------
ENV_FILE="$SCRIPT_DIR/.env"
[[ -f "$ENV_FILE" ]] || { echo "error: $ENV_FILE not found" >&2; exit 1; }
command -v curl >/dev/null 2>&1 || { echo "error: curl is required" >&2; exit 1; }

# --- load config -------------------------------------------------------------
set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

: "${DOWNLOAD_URL:?DOWNLOAD_URL must be set in .env}"
: "${DOWNLOAD_FOLDER:?DOWNLOAD_FOLDER must be set in .env}"
: "${DOWNLOAD_BINARY:?DOWNLOAD_BINARY must be set in .env}"

BASE_URL="${DOWNLOAD_URL%/}"   # trim any trailing slash

# A relative DOWNLOAD_FOLDER resolves next to the script (so output is stable
# regardless of the caller's CWD); an absolute one is used verbatim.
case "$DOWNLOAD_FOLDER" in
  /*) OUT_ROOT="$DOWNLOAD_FOLDER" ;;
  *)  OUT_ROOT="$SCRIPT_DIR/$DOWNLOAD_FOLDER" ;;
esac

# All channels, and the platform catalog: "<platform>:<filename>:<make-exec?>"
# The win32 binary carries the .exe extension and is NOT chmod'd.
ALL_CHANNELS=(latest stable)
PLATFORMS=(
  "darwin-x64:${DOWNLOAD_BINARY}:yes"
  "linux-x64:${DOWNLOAD_BINARY}:yes"
  "win32-x64:${DOWNLOAD_BINARY}.exe:no"
)

failures=0

# remote_size <url> -> Content-Length on stdout (empty if unknown/unreachable)
remote_size() {
  curl -fsSL -I "$1" 2>/dev/null \
    | tr -d '\r' \
    | awk 'tolower($1) == "content-length:" { v=$2 } END { print v }'
}

# rel <path> -> path shown relative to the script dir for tidy logging
rel() { printf '%s' "${1#"$SCRIPT_DIR"/}"; }

for channel in "${ALL_CHANNELS[@]}"; do
  # empty selection == all; otherwise skip channels not picked
  if (( ${#SEL_CHANNELS[@]} )) && ! contains "$channel" "${SEL_CHANNELS[@]}"; then
    continue
  fi

  echo "==> channel: $channel"

  if ! version="$(curl -fsSL "$BASE_URL/$channel")"; then
    echo "    ! could not resolve a version from $BASE_URL/$channel" >&2
    failures=$((failures + 1))
    continue
  fi
  version="$(printf '%s' "$version" | tr -d '[:space:]')"
  if [[ -z "$version" ]]; then
    echo "    ! empty version returned for channel '$channel'" >&2
    failures=$((failures + 1))
    continue
  fi
  echo "    version: $version"

  for entry in "${PLATFORMS[@]}"; do
    IFS=':' read -r platform filename executable <<<"$entry"

    # empty selection == all; otherwise skip platforms not picked
    if (( ${#SEL_PLATFORMS[@]} )) && ! contains "$platform" "${SEL_PLATFORMS[@]}"; then
      continue
    fi

    url="$BASE_URL/$version/$platform/$filename"
    dest="$OUT_ROOT/$channel/$version/$platform/$filename"

    rsize="$(remote_size "$url" || true)"
    if [[ -z "$rsize" ]]; then
      echo "    ! unreachable: $url" >&2
      failures=$((failures + 1))
      continue
    fi

    if [[ "$DRY_RUN" != "0" ]]; then
      echo "    ~ would fetch $platform/$filename ($rsize bytes) -> $(rel "$dest")"
      continue
    fi

    # Idempotent skip: only when the local file is byte-complete.
    if [[ -f "$dest" ]]; then
      lsize="$(wc -c <"$dest" | tr -d '[:space:]')"
      if [[ "$lsize" == "$rsize" ]]; then
        echo "    = $platform/$filename (already complete, skipping)"
        continue
      fi
    fi

    mkdir -p "$(dirname "$dest")"
    if curl -fsSL -o "$dest" "$url"; then
      [[ "$executable" == "yes" ]] && chmod +x "$dest"
      echo "    ✓ $platform/$filename -> $(rel "$dest")"
    else
      echo "    ! download failed: $url" >&2
      rm -f "$dest"
      failures=$((failures + 1))
    fi
  done
done

echo
if [[ "$failures" -gt 0 ]]; then
  echo "done with $failures failure(s)" >&2
  exit 1
fi
echo "done — mirror up to date under $(rel "$OUT_ROOT")"
