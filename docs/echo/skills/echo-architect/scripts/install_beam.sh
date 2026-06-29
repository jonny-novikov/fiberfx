#!/usr/bin/env bash
# Step 6b — the BEAM (Elixir + Erlang/OTP), rebar3, Hex. The umbrella pins
# 1.18.4 / OTP 28; the hard floor is Elixir >= 1.15, because postgrex 0.22 uses a
# 1.15 bitstring form (^var in construction) that is a CompileError on 1.14. So:
#   - reuse an Elixir >= 1.15 already present;
#   - else install the PINNED Elixir precompiled, matched to the available OTP major
#     (elixir-otp-<major>.zip runs on the OTP you already have, 25-27 supported) —
#     no OTP rebuild;
#   - if OTP itself is < 25 or absent, install a precompiled OTP (apt), or print the
#     asdf path for the exact pin.
# rebar3 (for the Erlang deps) and Hex come from the distro / GitHub so a blocked
# repo.hex.pm/installs endpoint never stops the build.
set -uo pipefail
BENCH_HOME="${BENCH_HOME:-$HOME/.bcs-bench}"
ENVFILE="$BENCH_HOME/.bcs-env"; [ -f "$ENVFILE" ] && . "$ENVFILE"
ELIXIR_MIN="${ELIXIR_MIN:-1.15}"; ELIXIR_PIN="${ELIXIR_PIN:-1.18.4}"; OTP_MIN="${OTP_MIN:-25}"
SUDO=""; [ "$(id -u)" -ne 0 ] && SUDO="sudo"; export DEBIAN_FRONTEND=noninteractive
persist() { grep -q "^export $1=" "$ENVFILE" 2>/dev/null && sed -i "s#^export $1=.*#export $1=\"$2\"#" "$ENVFILE" || echo "export $1=\"$2\"" >> "$ENVFILE"; export "$1"="$2"; }
ge() { [ "$(printf '%s\n%s' "$1" "$2" | sort -V | head -1)" = "$2" ]; }   # $1 >= $2 ?

echo "== beam (elixir >= $ELIXIR_MIN, pin $ELIXIR_PIN) + rebar3 + hex =="

# --- Erlang/OTP first (Elixir needs a matching OTP major) ---
otp="$(erl -eval 'io:format("~s",[erlang:system_info(otp_release)]),halt()' -noshell 2>/dev/null || true)"
if [ -z "$otp" ]; then
  echo "   erlang missing — installing precompiled erlang (apt)"
  $SUDO apt-get install -y -qq erlang-nox erlang-dev erlang-parsetools || true
  otp="$(erl -eval 'io:format("~s",[erlang:system_info(otp_release)]),halt()' -noshell 2>/dev/null || echo 0)"
else
  $SUDO apt-get install -y -qq erlang-dev erlang-parsetools >/dev/null 2>&1 || true   # headers for github-hex
fi
echo "   erlang/otp: $otp"
if [ "${otp:-0}" -lt "$OTP_MIN" ] 2>/dev/null; then
  cat <<MSG
   NOTE: OTP $otp is below $OTP_MIN, which Elixir $ELIXIR_PIN needs. Install a precompiled OTP
   >= $OTP_MIN (the pin is OTP 28). asdf is the simplest route to the exact pin:
       asdf plugin add erlang && asdf install erlang 28.5.0.1 && asdf global erlang 28.5.0.1
   or use Erlang Solutions' esl-erlang apt package. Then re-run this step.
MSG
fi

# --- Elixir: reuse >= floor, else install the pinned precompiled, OTP-matched ---
exv="$(elixir --version 2>/dev/null | grep -oE 'Elixir [0-9]+\.[0-9]+\.[0-9]+' | awk '{print $2}' || true)"
if [ -n "$exv" ] && ge "${exv%.*}" "$ELIXIR_MIN"; then
  echo "   reuse: Elixir $exv (>= $ELIXIR_MIN)"
else
  [ -n "$exv" ] && echo "   Elixir $exv is below $ELIXIR_MIN (postgrex 0.22 needs >=1.15) — installing pinned $ELIXIR_PIN"
  [ -z "$exv" ] && echo "   Elixir missing — installing pinned $ELIXIR_PIN (precompiled, OTP-matched)"
  dest="/opt/elixir-$ELIXIR_PIN"; $SUDO rm -rf "$dest"; $SUDO mkdir -p "$dest"
  got=""
  for build in "otp-${otp}" "otp-27" "otp-26" "otp-25"; do
    url="https://github.com/elixir-lang/elixir/releases/download/v${ELIXIR_PIN}/elixir-${build}.zip"
    if curl -fsSL -o /tmp/elixir.zip "$url" 2>/dev/null; then
      $SUDO unzip -q -o /tmp/elixir.zip -d "$dest" && got="$build" && break
    fi
  done
  [ -n "$got" ] || { echo "   ERROR: could not fetch a precompiled Elixir $ELIXIR_PIN build"; exit 5; }
  persist PATH "$dest/bin:${PATH}"
  echo "   installed Elixir $ELIXIR_PIN ($got) at $dest -> prepended to PATH in .bcs-env"
  echo "   now: $("$dest/bin/elixir" --version 2>/dev/null | tail -1)"
fi

# --- rebar3 (Erlang deps like telemetry/yamerl) ---
if command -v rebar3 >/dev/null 2>&1 && rebar3 version >/dev/null 2>&1; then
  echo "   rebar3: $(rebar3 version 2>&1 | head -1)"; persist MIX_REBAR3 "$(command -v rebar3)"
else
  $SUDO apt-get install -y -qq rebar3 >/dev/null 2>&1 || true
  if command -v rebar3 >/dev/null 2>&1 && rebar3 version >/dev/null 2>&1; then
    echo "   rebar3 (apt): $(rebar3 version 2>&1 | head -1)"; persist MIX_REBAR3 "$(command -v rebar3)"
  else
    echo "   rebar3 via apt unavailable — fetch a matching escript from github.com/erlang/rebar3/releases"
  fi
fi

# --- Hex (precompiled archive; GitHub compile fallback if repo.hex.pm/installs is blocked) ---
export PATH; [ -f "$ENVFILE" ] && . "$ENVFILE"
mix local.hex --force >/dev/null 2>&1 \
  || mix archive.install github hexpm/hex branch latest --force >/dev/null 2>&1 \
  || echo "   note: Hex not installed (repo.hex.pm/installs blocked and GitHub compile failed) — see hex_offline_mirror.sh"
mix local.rebar --force >/dev/null 2>&1 || true
echo "   hex + rebar ready"
