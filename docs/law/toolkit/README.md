# Курс III «Право повседневной жизни» — toolkit

Стартовый комплект и текущее состояние курса в системе тёмно-редакторского дизайна.
Право РФ. **Образовательный материал, не юридическая консультация.**

## С чего начать (новая сессия)
1. Прочитать `law-status.md` — текущее состояние и дорожная карта.
2. Прочитать `law-course-design.md` — архитектура 6×6, поглавный разбор, §6 ЧЕСТНОСТЬ.
3. Общие механики (CSS-токены, шрифты, движок квиза, KaTeX-правила, Quality Gates,
   паттерн навигации) — в `course-build-playbook.md`.
4. Источники по главам — `law-references.md`.

## Содержимое
- `law-course-design.md`, `law-references.md`, `law-status.md` — спецификации
- `course-build-playbook.md` — общий гайд по сборке (разделяется всеми курсами)
- `law/verify_numbers.py` — арифметика калькуляторов + правовые константы (запуск: `python3 law/verify_numbers.py`)
- `law/build_chapter_quiz.py`, `law/build_chapter_landing.py` — генераторы; по умолчанию пишут
  в стейджинг `.gen/` (НЕ в живое дерево — лендинги Гл.2/3 допилены вручную). В живое дерево: `OUT_BASE=<repo>/law`.
- `law/preflight.py` — pre-flight скан (KaTeX/смешанные скрипты/ссылки/структура)
- `law/audit_law.py` — **аудит консистентности** (честность/дисклеймеры, кросс-курсовые протечки,
  тема главы, целостность ссылок, дрифт `status ↔ fs`). Постранично или по всему `law/`.
- `checks.sh` — **единый локальный прогон всех гейтов** (preflight + verify + audit + DOM-suite)
- `watch_law.sh` — **вотчер консистентности** (см. `WATCH.md`)
- `toolkit/validator.js`, `toolkit/suite.law.js` — headless DOM-валидация живого `law/` (0 изображений);
  `toolkit/visual.js` — визуальная регрессия (нужны `pngjs`+`pixelmatch`, локально не ставятся)
- `law/index.html` — главная курса; `law/{глава}/index.html` — лендинги (Гл.2–3 интерактивные);
  `law/{глава}/kviz.html` — квизы; `law/dogovor/sila.html` — модуль 1.1

## Локальный прогон (в jonnify-репо)
Всё резолвится от расположения скрипта — работает из любой CWD; playwright берётся из
`apps/e2e/node_modules`.
```bash
docs/law/toolkit/checks.sh                       # все гейты по всему law/
docs/law/toolkit/checks.sh law/trud/index.html   # только указанные страницы
docs/law/toolkit/watch_law.sh audit              # разовый полный аудит консистентности
LAW_AI=0 bash docs/law/toolkit/watch_law.sh start # запустить вотчер (см. WATCH.md)
```

## Валидация (0 image budget, прямой запуск)
```
BASE_URL="file:///Users/jonny/dev/jonnify/law" \
NODE_PATH="/Users/jonny/dev/jonnify/apps/e2e/node_modules" \
node toolkit/suite.law.js [relpath ...]
```
Проверяет DOM/computedStyle через stdout, без скриншотов. См. `toolkit/suite.law.js` (живой набор) и `toolkit/suite.example.js` (шаблон).

## Состояние
Готово: главная `/law`, 6 лендингов глав (Гл.2 `potrebitel` и Гл.3 `trud` — интерактивные),
6 «Квиз главы», модуль 1.1 `dogovor/sila`. Core-модулей: 1/36.
Дальше: модули по 2 за раз. Следующая пара — 1.2 «Анатомия договора» + 1.3 «Красные флаги».
