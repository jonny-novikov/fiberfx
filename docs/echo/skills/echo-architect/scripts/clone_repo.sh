#!/usr/bin/env bash
# Step 2 — source. Clone the echo_mq branch over SSH (your key), idempotent: an
# existing checkout is fetched + fast-forwarded instead of re-cloned. SSH is the
# documented primary; an HTTPS fallback keeps the step working on a keyless box
# (the repo is public). No archive download — a real working tree with .git so
# you can branch, commit, and rebase.
set -uo pipefail
BENCH_HOME="${BENCH_HOME:-$HOME/.bcs-bench}"
[ -f "$BENCH_HOME/.bcs-env" ] && . "$BENCH_HOME/.bcs-env"
REPO_ROOT="${REPO_ROOT:-$HOME/src/fiberfx}"

SSH_URL="git@github.com:jonny-novikov/fiberfx.git"
HTTPS_URL="https://github.com/jonny-novikov/fiberfx.git"
BRANCH="echo_mq"

echo "== clone ($BRANCH) =="
mkdir -p "$(dirname "$REPO_ROOT")"

if [ -d "$REPO_ROOT/.git" ]; then
  echo "   existing checkout at $REPO_ROOT — fetch + ff-only"
  git -C "$REPO_ROOT" fetch --quiet --all --prune || true
  git -C "$REPO_ROOT" checkout --quiet "$BRANCH" 2>/dev/null || true
  git -C "$REPO_ROOT" pull --quiet --ff-only 2>/dev/null || true
else
  echo "   git clone --branch $BRANCH (ssh) -> $REPO_ROOT"
  if git clone --branch "$BRANCH" --single-branch "$SSH_URL" "$REPO_ROOT" 2>/tmp/clone.err; then
    echo "   cloned over ssh"
  else
    echo "   ssh clone unavailable ($(tr -d '\n' </tmp/clone.err | tail -c 80)) — falling back to https"
    git clone --branch "$BRANCH" --single-branch "$HTTPS_URL" "$REPO_ROOT"
  fi
fi

test -f "$REPO_ROOT/echo/mix.exs" || { echo "   ERROR: $REPO_ROOT/echo/mix.exs missing after clone"; exit 1; }
echo "   HEAD: $(git -C "$REPO_ROOT" rev-parse --short HEAD)  on $(git -C "$REPO_ROOT" rev-parse --abbrev-ref HEAD)"
echo "   umbrella apps: $(ls "$REPO_ROOT"/echo/apps | tr '\n' ' ')"
