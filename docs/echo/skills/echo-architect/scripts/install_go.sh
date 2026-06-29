#!/usr/bin/env bash
# Step 5 — Go 1.25 from the official tarball (a prebuilt toolchain, not a source
# build). Resolves the newest 1.25.x from go.dev, installs to $GOROOT, and is
# idempotent: a matching go on PATH is kept. Go drives codemojex-bitmapist and the
# Gin/Svelte dashboard.
set -euo pipefail
BENCH_HOME="${BENCH_HOME:-$HOME/.bcs-bench}"
[ -f "$BENCH_HOME/.bcs-env" ] && . "$BENCH_HOME/.bcs-env"
GOROOT="${GOROOT:-/usr/local/go}"; GO_VERSION="${GO_VERSION:-1.25}"

echo "== go ($GO_VERSION line) =="
cur="$("$GOROOT/bin/go" version 2>/dev/null | grep -oE 'go[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1 || true)"
if [ -z "$cur" ]; then cur="$(go version 2>/dev/null | grep -oE 'go[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1 || true)"; fi
if [ -n "$cur" ] && [[ "$cur" == go"$GO_VERSION"* ]]; then
  echo "   $cur already installed — reuse"; exit 0
fi

arch="$(uname -m)"; case "$arch" in x86_64) garch=amd64;; aarch64|arm64) garch=arm64;; *) garch="$arch";; esac
# newest patch on the 1.25 line (fallback pinned)
latest="$(curl -fsSL 'https://go.dev/dl/?mode=json&include=all' \
  | grep -oE "\"go${GO_VERSION}(\.[0-9]+)?\"" | tr -d '"' | sort -V | tail -1 || true)"
ver="${latest:-go${GO_VERSION}.0}"
url="https://go.dev/dl/${ver}.linux-${garch}.tar.gz"

echo "   downloading $url"
tmp="$(mktemp -d)"; curl -fsSL -o "$tmp/go.tgz" "$url"
SUDO=""; [ "$(id -u)" -ne 0 ] && SUDO="sudo"
$SUDO rm -rf "$GOROOT"; $SUDO mkdir -p "$(dirname "$GOROOT")"
$SUDO tar -C "$(dirname "$GOROOT")" -xzf "$tmp/go.tgz"
rm -rf "$tmp"
echo "   installed: $("$GOROOT/bin/go" version)"
