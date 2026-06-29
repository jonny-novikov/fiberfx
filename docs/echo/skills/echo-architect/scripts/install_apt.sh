#!/usr/bin/env bash
# Step 3 — base toolchain from apt (out of the box, never from source): a C
# compiler, Python 3 + venv/pip, git/curl, and the headers a few hex deps want
# (libssl, ncurses) so deps.compile has them if you compile later. Idempotent —
# apt no-ops what is already current.
set -euo pipefail
SUDO=""; [ "$(id -u)" -ne 0 ] && SUDO="sudo"
export DEBIAN_FRONTEND=noninteractive

echo "== base toolchain (apt) =="
$SUDO apt-get update -qq
$SUDO apt-get install -y -qq \
  build-essential pkg-config \
  python3 python3-venv python3-pip \
  git curl ca-certificates unzip xz-utils \
  libssl-dev libncurses-dev

echo "   gcc:    $(gcc --version | head -1)"
echo "   python: $(python3 --version)"
echo "   git:    $(git --version)"
