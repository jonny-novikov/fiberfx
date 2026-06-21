#!/usr/bin/env bash
#
# ec.6.smoke.sh — the echo-courses production-cutover smoke battery.
#
# A BASE-parameterized curl battery for ec.6 (docs/echo_courses/echo-courses.6.md).
# It is a real GATE: any failed assertion prints FAIL and the script exits non-zero.
#
# Two phases, selected by MODE (default: echo):
#
#   MODE=echo  (pre-cutover / local) — assert the deployed echo-courses app is the
#              correct cutover target. Testable locally and against echo-courses.fly.dev.
#                BASE=http://127.0.0.1:1323   ./ec.6.smoke.sh        # local dev server
#                BASE=https://echo-courses.fly.dev ./ec.6.smoke.sh   # pre-cutover prod
#
#   MODE=jonnify  (post-cutover) — Operator-run AFTER the flip, against jonnify.fly.dev.
#              Assert `/` is now the echo index (the /static/app.<hash>.css fingerprint)
#              AND the deep-course roots + a couple of other sections STILL resolve 200
#              (the cutover did NOT shadow them).
#                MODE=jonnify BASE=https://jonnify.fly.dev ./ec.6.smoke.sh
#              NOTE: MODE=jonnify is meaningful ONLY against jonnify.fly.dev. Run against
#              the local/echo app it WILL fail on jonnify-only routes (/fsharp /art /mesh
#              /llms.txt) — those live in the jonnify app, not echo-courses. That is the
#              gate discriminating correctly, not a defect.
#
# NO-INVENT: every asserted route is a real echo-courses route (cmd/server/main.go) or a
# real jonnify route (go/Dockerfile COPY tree + html/sitemap.xml). The cutover fingerprint
# is the content-hash asset link (ec.5: /static/app.<hash8>.{css,js}); the legacy inline-CSS
# index does NOT carry it, so it is the only reliable "is this the echo render?" signal
# (both indexes share <title>Courses · jonnify</title>).
#
# Both phases resolve BOTH the advertised /static/app.<hash>.css AND .js (CSS missing =>
# unstyled; JS missing => renders but dead). MODE=jonnify ALSO guards the cross-app SEO
# defect (runbook §2.A.3): the echo render's <link rel=canonical> + og:url are built for the
# echo app's /courses, but jonnify has NO /courses route — so post-cutover the body must NOT
# carry https://jonnify.fly.dev/courses (it must have been rewritten to "/" before install).
#
# Usage:
#   [MODE=echo|jonnify] [BASE=<url>] ./ec.6.smoke.sh
# Defaults: MODE=echo, BASE=http://127.0.0.1:1323

set -u

MODE="${MODE:-echo}"
BASE="${BASE:-http://127.0.0.1:1323}"
BASE="${BASE%/}" # trim one trailing slash so path joins never double up

PASS=0
FAIL=0

red()   { printf '\033[31m%s\033[0m' "$1"; }
green() { printf '\033[32m%s\033[0m' "$1"; }

# status PATH EXPECTED — assert GET BASE+PATH returns EXPECTED status.
status() {
  local path="$1" want="$2" code
  code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 20 "${BASE}${path}")"
  if [ "$code" = "$want" ]; then
    PASS=$((PASS + 1)); printf '  [%s] %-34s %s\n' "$(green PASS)" "$path" "$code"
  else
    FAIL=$((FAIL + 1)); printf '  [%s] %-34s got %s, want %s\n' "$(red FAIL)" "$path" "$code" "$want"
  fi
}

# contains PATH REGEX LABEL — assert the body of GET BASE+PATH matches REGEX (egrep).
contains() {
  local path="$1" re="$2" label="$3" body
  body="$(curl -s --max-time 20 "${BASE}${path}")"
  if printf '%s' "$body" | grep -qE "$re"; then
    PASS=$((PASS + 1)); printf '  [%s] %-34s %s\n' "$(green PASS)" "$path" "$label"
  else
    FAIL=$((FAIL + 1)); printf '  [%s] %-34s MISSING: %s\n' "$(red FAIL)" "$path" "$label"
  fi
}

# lacks PATH REGEX LABEL — assert the body of GET BASE+PATH does NOT match REGEX.
# Used post-cutover to prove the cross-app canonical/og:url `/courses` 404 (runbook §2.A.3)
# was rewritten to `/` before installing the echo render at jonnify's `/`.
lacks() {
  local path="$1" re="$2" label="$3" body
  body="$(curl -s --max-time 20 "${BASE}${path}")"
  if printf '%s' "$body" | grep -qE "$re"; then
    FAIL=$((FAIL + 1)); printf '  [%s] %-34s LEAKED: %s\n' "$(red FAIL)" "$path" "$label"
  else
    PASS=$((PASS + 1)); printf '  [%s] %-34s %s\n' "$(green PASS)" "$path" "$label"
  fi
}

echo "ec.6 smoke — MODE=${MODE} BASE=${BASE}"
echo "------------------------------------------------------------"

if [ "$MODE" = "echo" ]; then
  # ===== ECHO-APP ASSERTIONS (pre-cutover; testable locally) =====
  # The deployed echo-courses app serves these (cmd/server/main.go).
  echo "Echo-app routes (the cutover target):"
  status /             200
  status /courses      200
  status /healthz      200
  status /sitemap.xml  200
  status /robots.txt   200

  echo
  echo "Echo-app index markers:"
  # The content-hash assets — the cutover fingerprint (ec.5 D-1). Match the PATTERN,
  # never a literal hash (it changes whenever the asset bytes change).
  contains / '/static/app\.[a-f0-9]+\.css' "content-hash CSS link (/static/app.<hash>.css)"
  contains / '/static/app\.[a-f0-9]+\.js'  "content-hash JS link (/static/app.<hash>.js)"
  contains / '<title>Courses · jonnify</title>' "index <title> = Courses · jonnify"
  # The five course cards link to the published deep-course paths.
  contains / 'href="/elixir"'                      "card → /elixir"
  contains / 'href="/redis-patterns"'              "card → /redis-patterns"
  contains / 'href="/echomq"'                       "card → /echomq"
  contains / 'href="/course/agile-agent-workflow"' "card → /course/agile-agent-workflow"
  contains / 'href="/bcs"'                          "card → /bcs"

  echo
  echo "Echo-app fingerprint assets 200 (resolve BOTH hashed assets the index links):"
  # Resolve whatever hashed CSS+JS the index actually advertises (no literal hash baked in).
  # BOTH matter: CSS missing => unstyled; JS missing => renders but dead (a 404 JS bundle).
  INDEX_BODY="$(curl -s --max-time 20 "${BASE}/")"
  CSS_PATH="$(printf '%s' "$INDEX_BODY" | grep -oE '/static/app\.[a-f0-9]+\.css' | head -1)"
  JS_PATH="$(printf '%s' "$INDEX_BODY" | grep -oE '/static/app\.[a-f0-9]+\.js' | head -1)"
  if [ -n "$CSS_PATH" ]; then status "$CSS_PATH" 200; else
    FAIL=$((FAIL + 1)); printf '  [%s] %-34s no /static/app.<hash>.css advertised on /\n' "$(red FAIL)" "(hashed css)"; fi
  if [ -n "$JS_PATH" ]; then status "$JS_PATH" 200; else
    FAIL=$((FAIL + 1)); printf '  [%s] %-34s no /static/app.<hash>.js advertised on /\n' "$(red FAIL)" "(hashed js)"; fi

elif [ "$MODE" = "jonnify" ]; then
  # ===== JONNIFY-CUTOVER ASSERTIONS (Operator-run AFTER the flip) =====
  # `/` is now the echo render: it must carry the content-hash fingerprint the legacy
  # inline-CSS index never had.
  echo "Post-cutover index is now the echo render:"
  status /  200
  contains / '/static/app\.[a-f0-9]+\.css' "cutover fingerprint present (/static/app.<hash>.css)"
  contains / '<title>Courses · jonnify</title>' "index <title> preserved"
  # Cross-app SEO guard (runbook §2.A.3): the echo render's canonical/og:url are built for
  # the echo app's /courses; jonnify has NO /courses route, so they must have been rewritten
  # to jonnify's real index URL ("/") before install. A leaked …/courses = a 404 canonical.
  lacks / 'https://jonnify\.fly\.dev/courses' "canonical/og:url NOT pointing at the 404 /courses (rewritten to /)"
  # Resolve BOTH advertised assets ON jonnify — the §2.A.2 asymmetry risk (vendor/rewrite the
  # CSS but forget the JS) only manifests here, post-cutover, on the live host.
  J_BODY="$(curl -s --max-time 20 "${BASE}/")"
  J_CSS="$(printf '%s' "$J_BODY" | grep -oE '/static/app\.[a-f0-9]+\.css' | head -1)"
  J_JS="$(printf '%s' "$J_BODY" | grep -oE '/static/app\.[a-f0-9]+\.js' | head -1)"
  if [ -n "$J_CSS" ]; then status "$J_CSS" 200; else
    FAIL=$((FAIL + 1)); printf '  [%s] %-34s no /static/app.<hash>.css on jonnify /\n' "$(red FAIL)" "(hashed css)"; fi
  if [ -n "$J_JS" ]; then status "$J_JS" 200; else
    FAIL=$((FAIL + 1)); printf '  [%s] %-34s no /static/app.<hash>.js on jonnify /\n' "$(red FAIL)" "(hashed js)"; fi

  echo
  echo "Deep-course roots STILL resolve (NOT shadowed by the cutover):"
  # The deep courses served by jonnify's OWN folder trees (go/Dockerfile COPY tree).
  status /elixir                      200
  status /redis-patterns             200
  status /echomq                      200
  status /bcs                         200
  status /fsharp                      200
  status /art                         200
  status /mesh                        200
  # Agile deep course: the Dockerfile serves it under /agile-agent-workflow/*, while the
  # courses card links /course/agile-agent-workflow. The jonnify server (out-of-VCS) maps
  # between them; assert the card path here and confirm both with the Operator (runbook §4).
  status /course/agile-agent-workflow 200

  echo
  echo "Other jonnify sections STILL resolve (cutover was index-only):"
  # A representative pair from html/sitemap.xml; extend freely.
  status /sitemap.xml 200
  status /llms.txt    200

else
  echo "unknown MODE='${MODE}' (use echo | jonnify)"; exit 2
fi

echo "------------------------------------------------------------"
printf 'RESULT: %s passed, %s failed\n' "$(green "$PASS")" "$( [ "$FAIL" -eq 0 ] && green 0 || red "$FAIL" )"
[ "$FAIL" -eq 0 ] || exit 1
