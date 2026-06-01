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
- `law/build_chapter_quiz.py` — генератор «Квиз главы» (запуск: `OUT_BASE=. python3 law/build_chapter_quiz.py`)
- `law/build_chapter_landing.py` — генератор лендингов глав
- `law/preflight.py` — pre-flight скан (KaTeX/смешанные скрипты/ссылки/структура)
- `law/index.html` — главная курса; `law/{глава}/index.html` — лендинги (Гл.2–3 интерактивные);
  `law/{глава}/kviz.html` — квизы; `law/dogovor/sila.html` — модуль 1.1
- `toolkit/validator.js`, `toolkit/visual.js` — headless-валидация (0 изображений)

## Валидация (0 image budget)
```
BASE_URL="file:///abs/path/to/law" \
NODE_PATH="/path/to/node_modules" \
node suite.X.js
```
Проверяет DOM/computedStyle через stdout, без скриншотов. См. `toolkit/suite.example.js`.

## Состояние
Готово: главная `/law`, 6 лендингов глав (Гл.2 `potrebitel` и Гл.3 `trud` — интерактивные),
6 «Квиз главы», модуль 1.1 `dogovor/sila`. Core-модулей: 1/36.
Дальше: модули по 2 за раз. Следующая пара — 1.2 «Анатомия договора» + 1.3 «Красные флаги».
