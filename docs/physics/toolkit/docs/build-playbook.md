# Build-playbook — как собирать страницы курса `/physics`

Цикл и инструменты toolkit. Всё на чистом статическом HTML + KaTeX + JS, без сборщиков.

## Структура toolkit
```
(корень)
  style.py                 # дизайн-система: CSS, палитра PALETTE, head(), NAV_JS
  build_home.py            # Главная /physics
  build_chapter_landing.py # лендинг главы (CFG — образец Гл.1)
  build_module.py          # модуль: материалы + интерактив + квиз (CFG — образец 1.4)
  verify_physics.py        # проверка всех числовых примеров
  preflight.py             # KaTeX strict + вложенные <a> + целостность
validator/
  validator.js             # headless-проверки (DOM/computedStyle, 0 изображений)
  suite.home.js            # сьют Главной
  suite.sample.js          # сьют лендинга + модуля (калькулятор + квиз)
site/
  physics/index.html       # собранная Главная
  physics/tok/index.html   # образец лендинга
  physics/tok/zakon-oma.html # образец модуля
docs/                      # спецификация, оглавление, статус, источники, playbook
```

## Цикл сборки (строгая последовательность)
1. **Проверить математику:** добавить примеры в `verify_physics.py`, `python3 verify_physics.py` → все OK.
2. **Собрать:** заполнить CFG в нужном генераторе, `python3 build_module.py` (или landing/home).
3. **Преполёт:** `python3 preflight.py site/physics/<путь>.html` → 0 проблем.
4. **Валидатор:** добавить проверки в сьют, `BASE_URL="file:///abs/site" node validator/suite.*.js` → все PASS, 0 изображений.
5. **Показать** файлы.

## Дизайн-система (`style.py`)
- `head(title, desc, slug=None)` — целиком `<head>`; `slug` задаёт акцент главы (см. `PALETTE`).
- `NAV_JS` — полоса прогресса + scroll-spy; вставлять в `<script>` каждой страницы.
- Цвет главы — ключ из `PALETTE` (`tok`, `moshchnost`, `schet`, `bezopasnost`, `ustroystva`, `final`).

## Как добавить модуль
1. В `build_module.py → CFG` задать: `slug`, `chapter`, `pal`, `num`, `name`, `title/desc`, `kicker/h1/lead`, `secnav` (4–6 разделов), `sections` (HTML каждого раздела), `interactive_js` (если калькулятор), `takeaway` (3–5), `quiz` (массив `{q, options, correct, explain}`), `quiz_key` (`phys-<глава>-<модуль>-quiz`), `prev/nxt`.
2. Интерактив: переиспользовать паттерн калькулятора (`calc-grid`/`calc-btn`/`calc-result` + JS) или чек-листа (`audit-*`). Единицы — текстом вне `$...$`.
3. **Квиз обязателен** в каждом модуле.
4. preflight + сьют.

## Как добавить главу
1. `build_chapter_landing.py → CFG`: `slug/num/pal`, `kicker/h1/lead/intro`, `points`, `modules` (список плиток), `prev/nxt`.
2. Запустить → `site/physics/<слаг>/index.html`.
3. Лендинг ссылается на модули `/physics/<слаг>/<модуль>` и квиз главы `/physics/<слаг>/kviz`.

## Квиз главы и финальный квиз
- Тот же движок, что и в модуле (можно вынести в отдельный генератор `build_quiz.py` по образцу `QUIZ_JS` из `build_module.py`).
- Ключи: `phys-<глава>-kviz`, `phys-final-test`.

## Печатные материалы
- Страница `/physics/final/pechat` + блок `@media print` (скрыть topbar/nav/progress/footer; светлый фон). См. design §9.

## Правила (кратко)
- **Все ссылки root-relative** (`/physics/...`).
- **KaTeX strict:** никаких `№ ₽ « » · × ≤ ≥` и т. п. внутри `$...$`; единицы — HTML-текстом.
- **0 изображений** в сборке и в валидаторе.
- Нет вложенных `<a>` (карточки-ссылки — `<a>` без вложенных `<a>`).
