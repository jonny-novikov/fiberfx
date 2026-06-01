#!/usr/bin/env bash
# checks.sh — единый ЛОКАЛЬНЫЙ прогон всех детерминированных гейтов курса «Право».
#
# Запускает по очереди: preflight.py (KaTeX/структура) · verify_numbers.py (арифметика)
# · audit_law.py (консистентность + дрифт) · suite.law.js (headless DOM, 0 скриншотов).
# Всё резолвится от расположения скрипта — работает из любой CWD (в т.ч. из вотчера).
#
# Запуск:
#   docs/law/toolkit/checks.sh                # весь живой каталог law/
#   docs/law/toolkit/checks.sh law/trud/index.html ...   # только указанные страницы
#
# Env:
#   NODE_PATH  — где лежит playwright (по умолчанию apps/e2e/node_modules)
#   SKIP_DOM=1 — не запускать браузерный suite (только python-гейты)
#   BASE_URL   — переопределить file://.../law
set -uo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SELF_DIR/../../.." && pwd)"
LAW_DIR="$ROOT/law"
PY="$SELF_DIR/law"                      # python-утилиты
VAL="$SELF_DIR/toolkit"                 # validator.js + suite.law.js
NODE_PATH="${NODE_PATH:-$ROOT/apps/e2e/node_modules}"
BASE_URL="${BASE_URL:-file://$LAW_DIR}"
export NODE_PATH BASE_URL

args=("$@")                             # опциональный список файлов

fail=0
run() {  # run "LABEL" cmd...
  local label="$1"; shift
  echo "──────── $label ────────"
  if "$@"; then echo "   ✅ $label: OK"; else echo "   ❌ $label: FAIL ($?)"; fail=1; fi
  echo
}

# 1) preflight (KaTeX strict + смешанные скрипты + структура). Без аргументов — весь law/.
if [ ${#args[@]} -gt 0 ]; then
  run "preflight" python3 "$PY/preflight.py" "${args[@]}"
else
  run "preflight" python3 "$PY/preflight.py"
fi

# 2) verify_numbers (арифметика калькуляторов — глобально, не по файлам).
run "verify_numbers" python3 "$PY/verify_numbers.py"

# 3) audit_law (консистентность + дрифт status↔fs). Принимает опц. список файлов.
if [ ${#args[@]} -gt 0 ]; then
  run "audit_law" python3 "$PY/audit_law.py" "${args[@]}"
else
  run "audit_law" python3 "$PY/audit_law.py"
fi

# 4) suite.law.js (headless DOM). Требует node + playwright; иначе аккуратно пропускаем.
if [ "${SKIP_DOM:-0}" = "1" ]; then
  echo "──────── suite.law (DOM) ──────── (пропущено: SKIP_DOM=1)"; echo
elif ! command -v node >/dev/null 2>&1; then
  echo "──────── suite.law (DOM) ──────── (пропущено: нет node)"; echo
elif ! node -e "require('playwright')" >/dev/null 2>&1; then
  echo "──────── suite.law (DOM) ──────── (пропущено: playwright не найден в NODE_PATH=$NODE_PATH)"
  echo "          установить: (cd apps/e2e && npx playwright install chromium)"; echo
else
  if [ ${#args[@]} -gt 0 ]; then
    run "suite.law (DOM)" node "$VAL/suite.law.js" "${args[@]}"
  else
    run "suite.law (DOM)" node "$VAL/suite.law.js"
  fi
fi

if [ "$fail" = 0 ]; then echo "✅ Все гейты пройдены."; else echo "❌ Есть проваленные гейты (см. выше)."; fi
exit $fail
