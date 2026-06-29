#!/usr/bin/env bash
# Restricted-network fallback for `mix deps.get`. Some egress proxies serve curl but
# reset Erlang's TLS client to repo.hex.pm (you see `Unknown CA`, then `upstream
# connect error ... connection termination`). This builds a local Hex mirror from
# the exact bytes curl CAN fetch — /versions, each /packages/<name>, each
# /tarballs/<name>-<ver>.tar for the versions pinned in mix.lock — serves it on
# 127.0.0.1, and points Hex at it via HEX_MIRROR. Signatures still verify (identical
# bytes). Only needed when a plain `mix deps.get` is reset; harmless otherwise.
#
#   usage: hex_offline_mirror.sh            # builds mirror, runs deps.get, stops server
set -uo pipefail
BENCH_HOME="${BENCH_HOME:-$HOME/.bcs-bench}"
[ -f "$BENCH_HOME/.bcs-env" ] && . "$BENCH_HOME/.bcs-env"
UMBRELLA="${UMBRELLA:-$REPO_ROOT/echo}"
BASE="${HEX_UPSTREAM:-https://repo.hex.pm}"
PORT="${HEX_MIRROR_PORT:-8899}"
M="${HEX_MIRROR_DIR:-$BENCH_HOME/hexmirror}"

[ -f "$UMBRELLA/mix.lock" ] || { echo "   ERROR: no mix.lock at $UMBRELLA (run deps.get once to generate, or clone)"; exit 2; }
echo "== hex offline mirror (restricted-network fallback) =="
rm -rf "$M"; mkdir -p "$M/packages" "$M/tarballs"
curl -fsSL --retry 3 "$BASE/versions" -o "$M/versions" || { echo "   ERROR: cannot curl $BASE/versions either"; exit 3; }

# name + version from mix.lock :hex entries
grep -oE '"[a-z_]+": \{:hex, :[a-z_]+, "[0-9][^"]*"' "$UMBRELLA/mix.lock" \
  | sed -E 's/"([a-z_]+)": \{:hex, :([a-z_]+), "([^"]+)"/\2 \3/' | sort -u > "$M/.deps"
miss=0
while read -r name ver; do
  [ -z "$name" ] && continue
  curl -fsSL --retry 3 "$BASE/packages/$name"            -o "$M/packages/$name"            2>/dev/null || miss=1
  curl -fsSL --retry 3 "$BASE/tarballs/${name}-${ver}.tar" -o "$M/tarballs/${name}-${ver}.tar" 2>/dev/null || miss=1
done < "$M/.deps"
echo "   mirrored $(ls "$M/packages" | wc -l) packages / $(ls "$M/tarballs" | wc -l) tarballs (miss=$miss)"

python3 -m http.server "$PORT" --directory "$M" >/tmp/hexmirror.log 2>&1 &
SRV=$!; sleep 2
echo "   serving on http://127.0.0.1:$PORT (pid $SRV)"
cd "$UMBRELLA"
HEX_MIRROR="http://127.0.0.1:$PORT" HEX_CACERTS_PATH="${HEX_CACERTS_PATH:-/etc/ssl/certs/ca-certificates.crt}" \
  mix deps.get </dev/null
rc=$?
kill "$SRV" 2>/dev/null
echo "   deps now: $(ls deps 2>/dev/null | wc -l) packages (mix exit $rc)"
exit $rc
