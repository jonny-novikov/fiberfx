#!/usr/bin/env bash
# Step 4 — Valkey 9.1 + valkey-cli, OUT OF THE BOX. Detect-and-reuse first: if a
# valkey-server is already on PATH it is version-gated and kept (this is the common
# case — a distro/Homebrew/official-repo 9.1). Otherwise the system package manager
# installs it. This script NEVER builds Valkey from source; if no package is found
# it prints the official install path and stops, so a bench is never silently
# compiling an `unstable` checkout. EchoMQ speaks RESP3 to whatever this resolves.
set -uo pipefail
BENCH_HOME="${BENCH_HOME:-$HOME/.bcs-bench}"
[ -f "$BENCH_HOME/.bcs-env" ] && . "$BENCH_HOME/.bcs-env"
VALKEY_MIN="${VALKEY_MIN:-8}"; VALKEY_PREFERRED="${VALKEY_PREFERRED:-9.1}"

ver_of() { "$1" --version 2>/dev/null | grep -oE 'v=[0-9]+\.[0-9]+\.[0-9]+' | head -1 | cut -d= -f2; }
major()  { echo "${1%%.*}"; }

echo "== valkey (out of the box, never from source) =="

if command -v valkey-server >/dev/null 2>&1; then
  v="$(ver_of valkey-server)"; v="${v:-unknown}"
  echo "   found valkey-server $v on PATH — reuse"
else
  echo "   valkey-server not on PATH — trying the system package manager"
  SUDO=""; [ "$(id -u)" -ne 0 ] && SUDO="sudo"
  if command -v apt-get >/dev/null 2>&1; then
    export DEBIAN_FRONTEND=noninteractive
    $SUDO apt-get update -qq || true
    # Debian/Ubuntu split the cli into valkey-tools; try both, tolerate either name
    $SUDO apt-get install -y -qq valkey-server valkey-tools 2>/tmp/vk.err || \
      $SUDO apt-get install -y -qq valkey 2>>/tmp/vk.err || true
  elif command -v dnf >/dev/null 2>&1; then $SUDO dnf install -y valkey || true
  elif command -v pacman >/dev/null 2>&1; then $SUDO pacman -S --noconfirm valkey || true
  elif command -v brew >/dev/null 2>&1; then brew install valkey || true
  fi

  if ! command -v valkey-server >/dev/null 2>&1; then
    cat <<MSG
   NOTE: no Valkey package was available from the system package manager here, and
   this script does not build from source by design. Install Valkey $VALKEY_PREFERRED out of the
   box on your machine via your distro / the official package repo / Homebrew:
       https://valkey.io/download/      (OS packages, not a source build)
   Then re-run; detect-and-reuse will pick it up. If you already run $VALKEY_PREFERRED, point
   the EchoMQ connector at it (host {127,0,0,1}, port 6390; drills on 6391/6392).
MSG
    exit 3
  fi
  v="$(ver_of valkey-server)"; v="${v:-unknown}"
  echo "   installed valkey-server $v"
fi

# version gate (accept >= VALKEY_MIN; note if not the preferred 9.1)
if [ "$v" != "unknown" ]; then
  if [ "$(major "$v")" -lt "$VALKEY_MIN" ]; then
    echo "   ERROR: valkey-server $v is older than the $VALKEY_MIN.x floor"; exit 4
  fi
  [ "${v%.*}" = "$VALKEY_PREFERRED" ] || echo "   note: running $v (bench targets $VALKEY_PREFERRED — fine for dev/conformance)"
fi

# confirm a cli (valkey-cli preferred; redis-cli speaks the same wire if that is all there is)
if command -v valkey-cli >/dev/null 2>&1; then echo "   cli: $(valkey-cli --version)"
elif command -v redis-cli >/dev/null 2>&1; then echo "   cli: $(redis-cli --version)  (redis-cli — RESP-compatible)"
else echo "   note: no valkey-cli/redis-cli on PATH — install valkey-tools for the cli"; fi
