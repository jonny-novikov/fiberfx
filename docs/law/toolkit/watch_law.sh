#!/usr/bin/env bash
# watch_law.sh — вотчер консистентности курса «Право повседневной жизни» (/law).
#
# Назначение: держать курс согласованным и ПРОАКТИВНО ловить проблемы. Опрашивает
# живое дерево law/ (новые/изменённые *.html) и docs/law/law-status.md. На каждое
# изменение:
#   1. (всегда, детерминированно) полный аудит консистентности (audit_law.py:
#      честность/дисклеймеры, кросс-курсовые протечки, тема главы, целостность
#      ссылок, дрифт status↔fs) + гейты затронутых страниц через checks.sh
#      (preflight KaTeX + verify арифметики + headless DOM-suite, 0 скриншотов).
#   2. (LAW_AI=1) на странице с проваленными гейтами — запуск scoped `claude -p`,
#      который чинит ТОЛЬКО эту страницу и гоняет checks.sh до прохождения.
#
# Сепарация от elixir-вотчера: тот сторожит elixir/, этот — law/. Пересечение лишь
# в коммитах в master — этот вотчер НИЧЕГО не коммитит (только проверяет/логирует).
#
# Портативно: без fswatch (polling), bash 3.2 (macOS), без GNU timeout/flock.
# Команды:  start | stop | status | restart | once | audit | baseline | queue
# Env:      INTERVAL=20  LAW_AI=0|1  MAX_AI_PER_HOUR=8  AI_TIMEOUT=1200
#
# Безопасность: одноразовый mkdir-lock; почасовой троттл AI (overflis → очередь);
# scoped-агент с эфемерным --allowedTools (без правки настроек проекта, без
# --dangerously-skip-permissions); доверяем АРТЕФАКТУ (повторный checks.sh), не коду
# выхода. Останавливается в любой момент. AI-режим оператор включает САМ (LAW_AI=1).
set -uo pipefail

SELF="$(cd "$(dirname "$0")" 2>/dev/null && pwd)/$(basename "$0")"
TOOLKIT="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$TOOLKIT/../../.." && pwd)"
WATCH_DIR="$ROOT/law"
CHECKS="$TOOLKIT/checks.sh"
AUDIT="$TOOLKIT/law/audit_law.py"
STATUS_MD="$ROOT/docs/law/law-status.md"

WD="$TOOLKIT/.watch"
STATE="$WD/state"            # строки "MTIME\tPATH" по каждой странице
QUEUE="$WD/queue"            # страницы, ждущие починки (троттл / нет claude / fail)
RUNLOG="$WD/airuns"          # epoch-метки AI-прогонов (троттл)
LOG="$WD/watch.log"
FINDINGS="$WD/findings.txt"  # снимок последнего полного аудита
PIDFILE="$WD/pid"
LOCK="$WD/lock"
STATUS_STATE="$WD/status_mtime"
STATUS_CORE="$WD/status_core"  # последний записанный автоблок (без таймштампа) — для идемпотентности

# Маркеры автоблока мониторинга в law-status.md. audit_law.py отрезает ВСЁ от
# BEGIN перед парсингом дрифта → собственный вывод вотчера не зацикливает детект.
ST_BEGIN='<!-- LAW-WATCHER:BEGIN — автоблок вотчера watch_law.sh; НЕ редактировать вручную, перезапишется при следующем скане -->'
ST_END='<!-- LAW-WATCHER:END -->'

INTERVAL="${INTERVAL:-20}"
LAW_AI="${LAW_AI:-0}"
MAX_AI_PER_HOUR="${MAX_AI_PER_HOUR:-8}"
AI_TIMEOUT="${AI_TIMEOUT:-1200}"
CLAUDE="${CLAUDE:-claude}"

mkdir -p "$WD"
log() { echo "[$(date '+%F %T')] $*" >> "$LOG"; }
stat_mtime() { stat -f %m "$1" 2>/dev/null || stat -c %Y "$1" 2>/dev/null; }

list_pages() {
  find "$WATCH_DIR" -type f -name '*.html' 2>/dev/null \
    | grep -v -e '/\.' -e '\.part$' | LC_ALL=C sort
}
# snapshot: "MTIME\tPATH" по каждой странице (для детекта новых/изменённых).
snapshot() { local p; list_pages | while IFS= read -r p; do printf '%s\t%s\n' "$(stat_mtime "$p")" "$p"; done; }

# Полный детерминированный аудит консистентности — «проактивный» слой.
run_full_audit() {
  log "audit: полный прогон консистентности (audit_law.py)"
  python3 "$AUDIT" >"$FINDINGS" 2>&1
  local rc=$?
  local errs warns
  errs=$(grep -c '❌' "$FINDINGS" 2>/dev/null || echo 0)
  warns=$(grep -c '⚠️' "$FINDINGS" 2>/dev/null || echo 0)
  log "audit: $errs ERROR, $warns WARN (полный отчёт: $FINDINGS)"
  [ "$errs" -gt 0 ] && grep '❌' "$FINDINGS" | sed 's/^/    /' >> "$LOG"
  update_status_md          # отразить вердикт в law-status.md (видимый слой мониторинга)
  return $rc
}

# Записать раздел МОНИТОРИНГА в law-status.md (между маркерами ST_BEGIN/ST_END),
# сохранив рукописную часть файла ВЫШЕ маркера. Это «видимый» слой: пользователь
# смотрит law-status.md, а не .watch/. Содержимое — дайджест последнего аудита:
# охват, вердикт ERROR/WARN, сами ERROR-строки (дрифт), валидность ссылок (FWD-LINK)
# и таблица готовности по главам из файловой системы.
#
# Идемпотентность: пишем ТОЛЬКО когда содержимое (без строки таймштампа) изменилось —
# иначе no-op скан/рестарт плодил бы churn в git и дёргал детект status-mtime. После
# записи обновляем STATUS_STATE, чтобы наш собственный апдейт не считался «внешним
# изменением» статуса на следующем скане (иначе петля переаудита).
update_status_md() {
  [ -f "$STATUS_MD" ] || return 0
  [ -f "$FINDINGS" ]  || return 0

  local files chap land total fwd dead errs
  files="$(grep -m1 'Аудит консистентности' "$FINDINGS" 2>/dev/null | sed 's/^ *//;s/Аудит консистентности: //;s/ из .*//;s/ файлов//')"
  chap="$(grep -m1 'глав обнаружено'        "$FINDINGS" 2>/dev/null | sed 's/^ *//')"
  land="$(grep -m1 'лендингов:'             "$FINDINGS" 2>/dev/null | sed 's/^ *//')"
  total="$(grep -m1 'Итого'                 "$FINDINGS" 2>/dev/null | sed 's/^ *//')"
  # grep -c печатает 0 даже без совпадений, но выходит с кодом 1 → '|| true' (НЕ '|| echo 0',
  # иначе к нулю grep-а добавится второй ноль и получится "0\n0").
  fwd="$(grep -c 'FWD-LINK' "$FINDINGS" 2>/dev/null || true)"
  dead="$(grep -c 'DEADLINK' "$FINDINGS" 2>/dev/null || true)"
  errs="$(grep '❌' "$FINDINGS" 2>/dev/null | sed 's/^ *❌ */- /')"

  # Таблица готовности по главам — прямо из served-дерева law/ (источник истины).
  local rows='' d ch K M
  for d in "$WATCH_DIR"/*/; do
    [ -d "$d" ] && [ -f "${d}index.html" ] || continue
    ch="$(basename "$d")"
    if [ -f "${d}kviz.html" ]; then K='✓'; else K='—'; fi
    M="$(find "$d" -maxdepth 1 -type f -name '*.html' ! -name index.html ! -name kviz.html 2>/dev/null | grep -c .)"
    rows="${rows}| \`${ch}\` | ✓ | ${K} | ${M} |
"
  done

  local verdict
  if [ -n "$errs" ]; then
    verdict="**🔴 Требует действия (ERROR) — served-дерево \`law/\` расходится с заявленным статусом:**

$errs"
  else
    verdict="**🟢 ERROR нет** — served-дерево \`law/\` согласовано с заявленным статусом."
  fi

  local ts; ts="$(date '+%F %H:%M')"
  local block
  block="$ST_BEGIN
## 🔭 Мониторинг консистентности (автоблок)

> Раздел ведёт вотчер \`watch_law.sh\` автоматически при каждом изменении в \`law/\`. **Не редактируйте вручную** — он перезапишется при следующем скане. Полный отчёт: \`docs/law/toolkit/.watch/findings.txt\`; журнал: \`docs/law/toolkit/.watch/watch.log\`.

**Последний скан:** $ts · страниц под наблюдением: ${files:-?}
**${chap:-глав обнаружено: ?}**
**${land:-лендингов: ?}**

**Вердикт аудита:** ${total:-—}

$verdict

**🔗 Валидность ссылок:** битых ссылок на уже-построенные страницы — **$dead**; ссылок-вперёд на ещё-не-построенные страницы (FWD-LINK, норма на этапе сборки) — **$fwd** (перечень в findings.txt).

**Готовность по главам (served-дерево \`law/\`):**

| Глава | Лендинг | Квиз главы | Модулей |
|---|---|---|---|
${rows}
$ST_END"

  # Идемпотентность: сравниваем «ядро» (без строки таймштампа) с прошлой записью.
  local core
  core="$(printf '%s\n' "$block" | grep -v '^\*\*Последний скан:')"
  if [ -f "$STATUS_CORE" ] && printf '%s' "$core" | cmp -s - "$STATUS_CORE"; then
    return 0   # ничего по сути не изменилось — не трогаем файл (без churn в git)
  fi

  # Рукописная шапка = всё ДО маркера BEGIN (или весь файл, если маркера ещё нет).
  local head
  head="$(awk '/LAW-WATCHER:BEGIN/{exit} {print}' "$STATUS_MD")"
  printf '%s\n\n%s\n' "$head" "$block" > "$STATUS_MD.tmp" && mv "$STATUS_MD.tmp" "$STATUS_MD"
  printf '%s' "$core" > "$STATUS_CORE"
  stat_mtime "$STATUS_MD" > "$STATUS_STATE" 2>/dev/null   # наш апдейт ≠ внешнее изменение
  log "law-status.md: раздел мониторинга обновлён (${total:-—})"
}

# Гейты конкретных страниц (preflight + verify + audit + DOM-suite).
run_checks_on() {
  log "checks: $(printf '%s ' "${@#$ROOT/}")"
  ( bash "$CHECKS" "$@" ) >>"$LOG" 2>&1
}

run_with_timeout() {  # SECS cmd...  (портативно, без GNU timeout)
  local t="$1"; shift
  "$@" & local cpid=$!
  ( sleep "$t"; kill -0 "$cpid" 2>/dev/null && kill "$cpid" 2>/dev/null ) & local wpid=$!
  wait "$cpid" 2>/dev/null; local rc=$?
  kill "$wpid" 2>/dev/null
  return $rc
}

ai_runs_last_hour() {
  local now cutoff; now=$(date +%s); cutoff=$((now - 3600))
  [ -f "$RUNLOG" ] || { echo 0; return; }
  awk -v c="$cutoff" '$1>=c{n++} END{print n+0}' "$RUNLOG"
}

# AI-починка ОДНОЙ страницы с проваленными гейтами (LAW_AI=1).
ai_fix() {
  local page="$1" rel="${1#$ROOT/}"
  if [ "$LAW_AI" != "1" ]; then echo "$page" >> "$QUEUE"; log "queued (sync mode): $rel"; return; fi
  if ! command -v "$CLAUDE" >/dev/null 2>&1; then echo "$page" >> "$QUEUE"; log "queued (no claude): $rel"; return; fi
  if [ "$(ai_runs_last_hour)" -ge "$MAX_AI_PER_HOUR" ]; then echo "$page" >> "$QUEUE"; log "queued (throttle $MAX_AI_PER_HOUR/h): $rel"; return; fi

  log "AI-fix: $rel"
  date +%s >> "$RUNLOG"
  local prompt
  prompt="Страница курса «Право повседневной жизни» НЕ проходит гейты: $page
Почини ТОЛЬКО эту страницу, не редактируй другие файлы.
1. Прогон гейтов и диагностика: bash $CHECKS $page
2. Исправь найденное по правилам курса (docs/law/toolkit/course-build-playbook.md, law-course-design.md §6):
   - ЧЕСТНОСТЬ юр-курса: на странице обязателен дисклеймер «образовательный материал, не
     юридическая консультация; право РФ; сверяйте действующую редакцию». Только реальные
     кодексы (ГК/ТК/СК РФ, ЗоЗПП №2300-1, ГПК РФ) и порталы (pravo.gov.ru, КонсультантПлюс,
     Гарант). НЕ выдумывай номера статей. Калькуляторы — иллюстративные (.disclaimer).
   - KaTeX strict: внутри \$...\$ нельзя № « » \" \" „ … ₽; проценты \\% (JS) / \% (HTML);
     запятая в числах {,}; баланс \$.
   - Числа калькуляторов сверять с docs/law/toolkit/law/verify_numbers.py и зеркалить в JS.
   - localStorage-ключи только с префиксом law-c{N}-… (НИКОГДА lg-…). Никаких /logic/ /health/.
   - Вложенных <a> нет; тема главы = свой акцент (--accent:#hex из палитры); навигация
     модуля: id=\"top\", .section-nav, .nav-prev-next.
3. Повтори bash $CHECKS $page — он ДОЛЖЕН закончиться '✅ Все гейты пройдены'. Чини до прохождения.
Проза безличная: без перволичного повествования и хайпа."

  # --allowedTools — пробелами (claude -p падает на списке через запятую).
  run_with_timeout "$AI_TIMEOUT" "$CLAUDE" -p "$prompt" \
    --permission-mode acceptEdits \
    --allowedTools Read Edit Write Grep Glob Bash \
    --max-turns 50 >>"$LOG" 2>&1

  # Доверяем артефакту: страница «починена», только если checks.sh теперь зелёный.
  if ( bash "$CHECKS" "$page" ) >/dev/null 2>&1; then
    log "AI-fix OK: $rel (гейты зелёные)"
  else
    echo "$page" >> "$QUEUE"; log "AI-fix FAILED: $rel — гейты всё ещё красные; в очередь"
  fi
}

scan_once() {
  if ! mkdir "$LOCK" 2>/dev/null; then return 0; fi
  trap 'rmdir "$LOCK" 2>/dev/null' RETURN
  local cur; cur="$(snapshot)"
  if [ ! -f "$STATE" ]; then
    printf '%s\n' "$cur" > "$STATE"
    stat_mtime "$STATUS_MD" > "$STATUS_STATE" 2>/dev/null
    log "baselined $(printf '%s\n' "$cur" | grep -c .) pages"; return 0
  fi
  # Затронутые страницы = строки cur, которых нет в STATE (новые или с новым mtime).
  local touched
  touched="$(LC_ALL=C comm -23 <(printf '%s\n' "$cur" | LC_ALL=C sort) <(LC_ALL=C sort "$STATE") 2>/dev/null | cut -f2-)"
  # Удалённые страницы = пути, что были в STATE, но исчезли из cur. Сравниваем ТОЛЬКО
  # пути (не mtime), иначе изменённая страница попала бы и в «удалённые». Удаление тоже
  # меняет консистентность (висячие ссылки-вперёд, дрифт счётчиков) → нужен переаудит.
  local removed
  removed="$(LC_ALL=C comm -23 <(cut -f2- "$STATE" | LC_ALL=C sort -u) <(printf '%s\n' "$cur" | cut -f2- | LC_ALL=C sort -u) 2>/dev/null)"
  printf '%s\n' "$cur" > "$STATE"
  # Второй триггер: изменился law-status.md (мог поехать дрифт status↔fs).
  local sm_new sm_old status_changed=0
  sm_new="$(stat_mtime "$STATUS_MD")"; sm_old="$(cat "$STATUS_STATE" 2>/dev/null)"
  [ -n "$sm_new" ] && [ "$sm_new" != "$sm_old" ] && status_changed=1
  echo "$sm_new" > "$STATUS_STATE"

  [ -z "$touched" ] && [ -z "$removed" ] && [ "$status_changed" = 0 ] && return 0
  [ "$status_changed" = 1 ] && log "law-status.md изменился → переаудит"
  [ -n "$touched" ] && log "затронуто страниц: $(printf '%s\n' "$touched" | grep -c .)"
  [ -n "$removed" ] && log "удалено страниц: $(printf '%s\n' "$removed" | grep -c .) ($(printf '%s\n' "$removed" | sed "s|^$ROOT/||" | tr '\n' ' '))"

  # Проактивный слой: всегда полный аудит консистентности.
  run_full_audit

  # Гейты + (опц.) починка по каждой затронутой странице.
  printf '%s\n' "$touched" | while IFS= read -r p; do
    [ -z "$p" ] && continue; [ -f "$p" ] || continue
    log "TOUCHED: ${p#$ROOT/}"
    if run_checks_on "$p"; then
      log "OK: ${p#$ROOT/} (гейты зелёные)"
    else
      log "FAIL: ${p#$ROOT/} (гейты красные)"
      ai_fix "$p"
    fi
  done
}

baseline() {
  snapshot > "$STATE"; : > "$QUEUE"
  stat_mtime "$STATUS_MD" > "$STATUS_STATE" 2>/dev/null
  local n; n=$(grep -c . "$STATE" 2>/dev/null || echo 0)
  log "baselined $n pages (ни одна не считается изменённой)"; echo "baselined $n pages"
}

loop() {
  log "watcher loop start (interval ${INTERVAL}s, LAW_AI=$LAW_AI)"
  run_full_audit            # стартовый снимок: сразу заполнить findings + раздел мониторинга в law-status.md
  while true; do scan_once; sleep "$INTERVAL"; done
}
is_running() { [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; }

case "${1:-}" in
  start)
    if is_running; then echo "already running (PID $(cat "$PIDFILE"))"; exit 0; fi
    [ -f "$STATE" ] || baseline >/dev/null
    echo "$LAW_AI" > "$WD/law_ai"
    rmdir "$LOCK" 2>/dev/null || true
    LAW_AI="$LAW_AI" INTERVAL="$INTERVAL" MAX_AI_PER_HOUR="$MAX_AI_PER_HOUR" AI_TIMEOUT="$AI_TIMEOUT" \
      nohup "$SELF" loop >/dev/null 2>&1 &
    echo $! > "$PIDFILE"
    echo "started (PID $(cat "$PIDFILE")), interval ${INTERVAL}s, LAW_AI=$LAW_AI, log: $LOG" ;;
  stop)
    if is_running; then kill "$(cat "$PIDFILE")" 2>/dev/null; rm -f "$PIDFILE"; rmdir "$LOCK" 2>/dev/null || true; echo "stopped"; else echo "not running"; rm -f "$PIDFILE"; fi ;;
  restart) "$0" stop; sleep 1; "$0" start ;;
  status)
    mode="$(cat "$WD/law_ai" 2>/dev/null || echo '?')"
    kn=0; [ -f "$STATE" ] && kn=$(grep -c . "$STATE" 2>/dev/null)
    qn=0; [ -f "$QUEUE" ] && qn=$(grep -c . "$QUEUE" 2>/dev/null)
    if is_running; then echo "RUNNING (PID $(cat "$PIDFILE")), LAW_AI=$mode"; else echo "stopped"; fi
    echo "known: $kn | queued: $qn | AI runs/last hour: $(ai_runs_last_hour)"
    [ -f "$FINDINGS" ] && echo "последний аудит: $(grep -m1 'Итого' "$FINDINGS" 2>/dev/null)" ;;
  loop) loop ;;
  once) scan_once; echo "scan complete (см. $LOG)" ;;
  audit) run_full_audit; echo "── findings ──"; cat "$FINDINGS" ;;
  baseline) baseline ;;
  queue) [ -f "$QUEUE" ] && cat "$QUEUE" || echo "(empty)" ;;
  *) echo "usage: $0 {start|stop|restart|status|once|audit|baseline|queue}"; echo "env: INTERVAL LAW_AI(0/1) MAX_AI_PER_HOUR AI_TIMEOUT"; exit 1 ;;
esac
