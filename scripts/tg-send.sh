#!/usr/bin/env bash
#
# tg-send.sh — send a Telegram message (text, or an image + caption) through a
# bot to one or more chats. Defaults to the Codemoji bot (@codemoji_bot).
#
# The bot token is read at runtime from an env file (default echo/.env.production)
# and NEVER printed. With an image it uses sendPhoto (caption = the text); without
# one, sendMessage. Multiple recipients are sent sequentially with a small throttle
# so a broadcast stays inside Telegram's ~30 msg/s limit. Each send reports OK (with
# the message_id) or FAIL (with Telegram's reason) — e.g. a user who never started
# the bot returns "Forbidden: bot can't initiate conversation with a user".
#
# Telegram has no "broadcast to all" API: a bot can only message a chat_id it
# already knows (one that started it / a channel it admins). Use --updates to
# discover chat_ids from recent messages, or feed your own list with --chats-file.
#
# Usage:
#   scripts/tg-send.sh -t "Игра скоро начнется!" 231711076
#   scripts/tg-send.sh -i echo/apps/codemojex/priv/static/assets/bot-hello.jpg \
#                      -t "⭐️ caption" 231711076 446859742
#   scripts/tg-send.sh -F note.txt --chats-file subscribers.txt
#   some-query | scripts/tg-send.sh -t "hi" --chats-file -      # ids from stdin
#   scripts/tg-send.sh --updates                                # discover chat_ids
#   scripts/tg-send.sh --dry-run -t "hi" 231711076             # show, send nothing
#
# Recipients (one or more, required unless --updates):
#   positional CHAT_ID ...        a numeric id, a -100… group/channel id, or @channelusername
#   --chats-file FILE             one recipient per line (# comments and blanks ignored; "-" = stdin)
#
# Message (required unless --updates):
#   -t, --text TEXT               message text, or the caption when --image is given
#   -F, --text-file FILE          read the text/caption from FILE ("-" = stdin)
#   -i, --image PATH              attach a local image (sendPhoto); path is relative to your CWD
#   -p, --parse-mode MODE         MarkdownV2 | HTML | Markdown (default: plain text, no parsing)
#
# Config / behavior:
#   -e, --env-file FILE           env file holding the token (default: <repo>/echo/.env.production)
#       --token-var NAME          token variable name (default: CODEMOJI_BOT_TOKEN)
#       --delay SECONDS           pause between sends (default: 0.05 ≈ 20/s, Telegram-safe)
#       --updates                 print recent chats (getUpdates) for chat_id discovery, then exit
#       --dry-run                 print what would be sent without sending
#   -h, --help                    this help
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# --- defaults ---------------------------------------------------------------
ENV_FILE="${TG_ENV_FILE:-$REPO_ROOT/echo/.env.production}"
TOKEN_VAR="CODEMOJI_BOT_TOKEN"
TEXT=""
TEXT_FILE=""
IMAGE=""
PARSE_MODE=""
DELAY="0.05"
DRY_RUN=0
UPDATES=0
declare -a RECIPIENTS=()

usage() { sed -nE 's/^# ?//; 2,/^set -euo/p' "${BASH_SOURCE[0]}" | sed '$d'; }

die() { echo "tg-send: $*" >&2; exit 1; }

# --- parse args -------------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    -t|--text)        TEXT="$2"; shift 2 ;;
    -F|--text-file)   TEXT_FILE="$2"; shift 2 ;;
    -i|--image)       IMAGE="$2"; shift 2 ;;
    -p|--parse-mode)  PARSE_MODE="$2"; shift 2 ;;
    -e|--env-file)    ENV_FILE="$2"; shift 2 ;;
    --token-var)      TOKEN_VAR="$2"; shift 2 ;;
    --delay)          DELAY="$2"; shift 2 ;;
    --chats-file)
      src="$2"; [[ "$src" == "-" ]] && src="/dev/stdin"
      [[ "$src" == "/dev/stdin" || -f "$src" ]] || die "chats-file not found: $2"
      while IFS= read -r line; do
        line="${line%%#*}"; line="$(printf '%s' "$line" | tr -d '[:space:]')"
        [[ -n "$line" ]] && RECIPIENTS+=("$line")
      done < "$src"
      shift 2 ;;
    --dry-run)        DRY_RUN=1; shift ;;
    --updates)        UPDATES=1; shift ;;
    -h|--help)        usage; exit 0 ;;
    --)               shift; while [[ $# -gt 0 ]]; do RECIPIENTS+=("$1"); shift; done ;;
    -*)               die "unknown option: $1 (try --help)" ;;
    *)                RECIPIENTS+=("$1"); shift ;;
  esac
done

# --- token (read once, never printed) --------------------------------------
[[ -f "$ENV_FILE" ]] || die "env file not found: $ENV_FILE"
TOKEN="$(/usr/bin/grep -hE "^${TOKEN_VAR}=" "$ENV_FILE" 2>/dev/null | head -1 \
         | sed -E 's/^[^=]+=//; s/^["'"'"']//; s/["'"'"']$//')"
[[ -n "$TOKEN" ]] || die "$TOKEN_VAR not found (or empty) in $ENV_FILE"
API="https://api.telegram.org/bot${TOKEN}"

# LC_ALL=C on grep/sed so an emoji/UTF-8 response body never trips "illegal byte sequence".
json_str()  { printf '%s' "$1" | LC_ALL=C sed -nE "s/.*\"$2\":\"([^\"]*)\".*/\1/p"; }
json_int()  { printf '%s' "$1" | LC_ALL=C grep -oE "\"$2\":-?[0-9]+" | head -1 | LC_ALL=C grep -oE -- '-?[0-9]+'; }
json_ok()   { printf '%s' "$1" | LC_ALL=C grep -q '"ok":true'; }

# --- --updates: discover chat_ids from recent messages ---------------------
if [[ "$UPDATES" -eq 1 ]]; then
  resp="$(curl -s "${API}/getUpdates")"
  if ! json_ok "$resp"; then
    die "getUpdates failed: $(json_str "$resp" description)"
  fi
  echo "Recent chats (chat_id — name):"
  # one line per update's chat object; dedupe by id
  printf '%s' "$resp" \
    | LC_ALL=C grep -oE '"chat":\{[^}]*\}' \
    | while IFS= read -r chat; do
        id="$(json_int "$chat" id)"
        name="$(json_str "$chat" username)"; [[ -z "$name" ]] && name="$(json_str "$chat" title)"
        first="$(json_str "$chat" first_name)"
        printf '  %s\t%s\n' "${id:-?}" "${name:-$first}"
      done | sort -u
  exit 0
fi

# --- validate send inputs ---------------------------------------------------
[[ -n "$TEXT_FILE" ]] && { f="$TEXT_FILE"; [[ "$f" == "-" ]] && f=/dev/stdin; TEXT="$(cat "$f")"; }
[[ -n "$TEXT" ]] || die "no message text — pass -t TEXT or -F FILE (or --updates)"
[[ -z "$IMAGE" || -f "$IMAGE" ]] || die "image not found: $IMAGE"
[[ "${#RECIPIENTS[@]}" -gt 0 ]] || die "no recipients — pass chat_id(s) and/or --chats-file"

# --- send -------------------------------------------------------------------
send_one() {
  local chat="$1" resp mid desc
  local -a args=(-s -X POST)
  if [[ -n "$IMAGE" ]]; then
    args+=("${API}/sendPhoto" -F "chat_id=${chat}" -F "photo=@${IMAGE}" -F "caption=${TEXT}")
    [[ -n "$PARSE_MODE" ]] && args+=(-F "parse_mode=${PARSE_MODE}")
  else
    args+=("${API}/sendMessage" --data-urlencode "chat_id=${chat}" --data-urlencode "text=${TEXT}")
    [[ -n "$PARSE_MODE" ]] && args+=(--data-urlencode "parse_mode=${PARSE_MODE}")
  fi
  resp="$(curl "${args[@]}")"
  if json_ok "$resp"; then
    mid="$(json_int "$resp" message_id)"
    echo "  ${chat} → OK (message_id ${mid:-?})"
    return 0
  fi
  desc="$(json_str "$resp" description)"
  echo "  ${chat} → FAIL: ${desc:-$resp}"
  return 1
}

method="$([[ -n "$IMAGE" ]] && echo sendPhoto || echo sendMessage)"
echo "${method} to ${#RECIPIENTS[@]} recipient(s)${IMAGE:+ with image $IMAGE}${DRY_RUN:+ (dry-run)}:"

sent=0; failed=0
for chat in "${RECIPIENTS[@]}"; do
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "  ${chat} → (dry-run) would ${method}"
    continue
  fi
  if send_one "$chat"; then sent=$((sent + 1)); else failed=$((failed + 1)); fi
  sleep "$DELAY"
done

[[ "$DRY_RUN" -eq 1 ]] || echo "Done: ${sent} sent, ${failed} failed (of ${#RECIPIENTS[@]})."
[[ "$failed" -eq 0 ]] || exit 1
