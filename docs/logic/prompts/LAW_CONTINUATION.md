Я продолжаю работу над курсом II «Логика и принятие решений» (на русском). К сообщению приложен архив `logic-course-toolkit.zip` — это комплект, прогресс и дизайн курса. Курс уже опубликован.

## Шаг 0 — распаковать и прочитать (incrementally)
1. `README.md` — ориентир по архиву + живой адрес.
2. `logic-status.md` — текущее состояние, прогресс, дорожная карта.
3. `logic-course-design.md` — архитектура 6 глав × 6 модулей, поглавный разбор с интерактивами, палитра, паттерн навигации.
4. `course-build-playbook.md` — ОБЩИЕ механики (CSS-токены `:root`, шрифты, движок квиза, KaTeX-правила, Quality Gates). Не дублируй — бери оттуда.
5. `logic-references.md` — 18 реальных академических источников. `llms.txt` — карта всей серии jonnify (контекст).

## Публикация и контекст
Курс живёт на **https://jonnify.fly.dev/logic** — часть серии **jonnify** (девять курсов; карта — `llms.txt`, полный список — `/sitemap.xml`). Страницы в архиве — авторский исходник `/logic`; живой сайт — канон опубликованного состояния. Если понадобятся именно прод-версии страниц, сделай `web_search` по сайту, затем фетч нужных URL.

## Что это за курс
Тезис: школьная вероятность + логика + теория множеств — инструмент любого нетривиального решения. Одно предложение: «как не быть обманутым собственным мозгом». URL-namespace `/logic`. 6 глав × 6 модулей = 36. Главы и темы:
- Гл.1 `iskazheniya` (burgundy) — когнитивные искажения
- Гл.2 `veroyatnost` (gold) — вероятность и ценность
- Гл.3 `bayes` (blue) — байесовское обновление
- Гл.4 `igry` (plum) — теория игр для жизни
- Гл.5 `dannye` (slate) — чтение данных и статей
- Гл.6 `resheniya` (jade, капстоун) — фреймворки решений

Слаги модулей (пути `/logic/{глава}/{модуль}`):
- Гл.1: `sistemy, yakorenie, dostupnost, vyzhivshiy, potery, sintez`
- Гл.2: `osnovy, ozhidaemaya, klassy, dispersiya, kombinatorika, sintez`
- Гл.3: `myshlenie, formula, bazovaya-stavka, posledovatelnoe, sila-ulik, sintez`
- Гл.4: `osnovy, dilemma, povtoryayushchiesya, koordinatsiya, dilemmy-zhizni, sintez`
- Гл.5: `korrelyatsiya, p-value, interval, otnositelnyy, lovushki, sintez`
- Гл.6: `zachem, derevo, pravilo-101010, inversiya, predict-verify, sintez`

## Что уже готово (HTML 15, core-модулей 2/36)
- Главная `logic/index.html` (`/logic`); 6 лендингов глав `logic/{глава}/index.html`; 6 «Квиз главы» `logic/{глава}/kviz.html`.
- Модули Гл.1: `logic/iskazheniya/sistemy.html` (1.1 «Две системы мышления», интерактив — тест когнитивной рефлексии) и `yakorenie.html` (1.2 «Якорение», интерактив — «колесо фортуны»).

## Утилиты (в `logic/`)
- `verify_math.py` — **проверка всех формул** (EV/дисперсия, Байес, теория игр T>R>P>S + tit-for-tat, комбинаторика, доверительный интервал, дерево решений; Гл.1: bat&ball/машины/кувшинки, доля Африки в ООН, эффект якоря). Перед модулем с расчётом/интерактивом: проверь формулу здесь, потом зеркаль в JS. Запуск: `python3 logic/verify_math.py`.
- `build_chapter_quiz.py`, `build_chapter_landing.py` — генераторы. Генерируй в рабочую папку: `OUT_BASE=/home/claude/work/logic python3 logic/build_chapter_quiz.py`, затем `cp` в выдачу.
- `preflight.py` — скан: `python3 logic/preflight.py 'logic/*.html' 'logic/*/*.html'`.

## Рабочий цикл на каждый модуль/страницу (обязательно)
verify_math.py (если есть формула) → сборка → `preflight.py` → **toolkit-валидация** → синк в выдачу → `present_files` → обновить `logic-status.md` (+ запись в журнал).

## Валидация — 0 image budget (важно)
НЕ открывай PNG через `view` (бюджет изображений почти исчерпан). Проверяй headless-валидатором по DOM/`computedStyle` (stdout, без скриншотов):
```
BASE_URL="file:///abs/path/logic" NODE_PATH="<...>/node_modules" node suite.X.js
```
Класс `Validator` в `toolkit/validator.js`: `open/title/noKatexErrors/noHorizontalOverflow/expectText/expectTextEquals/expectCount(sel,op,n)/expectVisible/fill/click/computedStyle/expectStyle/settle/localStorage/report`. Пример — `toolkit/suite.example.js`. Playwright ставится при необходимости (`npm i -D playwright@1.56 && npx playwright install chromium`).

## Критичные правила (не нарушать)
- **KaTeX strict:** `strict:false, throwOnError:false`. Внутри `$...$` НЕЛЬЗЯ `№ « » " " „ … ₽` и нелатинскую текст-пунктуацию. Проценты: в HTML `\%`, в JS-литералах `\\%`; вне математики — слово или обычный «%». Запятая в числах — `{,}`. Юникод `≠ × ≈` — в обычном тексте. Перед сдачей — скан regex `\$[^$\n]+?\$` на запрещённые символы в HTML и JS-литералах.
- **Вложенные `<a>` запрещены:** карточки/тайлы с внутренними ссылками — `<div>`, не `<a>` (иначе браузер дублирует DOM). Проверяй: `.ch-card`/`.tile` должно быть ровно 6.
- **Десктоп-шрифт** на каждой странице: `@media (min-width:1024px){html{font-size:18px}body{font-size:18.5px}} @media (min-width:1440px){html{font-size:19px}}`.
- **Навигация:** дидактические модули — липкая `.section-nav` под топбаром (`top:72px`, подсветка активной секции через IntersectionObserver; секции `id="s1".."s6"` + `scroll-margin-top:126px`) + внизу `.nav-prev-next` и «↑ Наверх» (`<body id="top">`).
- **localStorage:** префикс ключей курса — `lg-...` (квизы `lg-c{N}-kviz`; модули `lg-c1-sistemy-*`, `lg-c1-yakorenie-*`). Каждому интерактиву/квизу — уникальный ключ.
- **Честность:** иллюстративные калькуляторы — с явным `.disclaimer`. Источники реальные (ссылки на поиск Scholar). Эпиграфы — формат «Принцип …», без выдуманных цитат реальным людям. Между-групповые эффекты (как якорение) помечать «один прогон не доказывает».
- **Окружение:** запись напрямую в выдачу иногда даёт OSError errno 5 — генерируй в `/home/claude/work/logic`, валидируй там, потом `cp`. `create_file` падает, если файл существует — сначала `rm`.

## Что делать дальше
Темп — **2 модуля на запрос** (я смотрю между итерациями). Дидактический модуль = hero → 6 секций `.sect` → интерактив `.task-block` (+`.disclaimer` если иллюстративный) → `.quote-block` → `.takeaway` (5 пунктов I–V) → `.quiz` (5) → `.references` (3 реальных) → нижняя навигация; сверху — навигация по секциям. Тема главы из палитры. Формулы — сперва в `verify_math.py`.

Начни с подтверждения, что прочитал `logic-status.md` и `logic-course-design.md`, кратко перечисли текущее состояние и предложи следующую пару модулей (по плану — **1.3 «Доступность» + 1.4 «Ошибка выжившего»** Главы 1; интерактивы — воспринимаемая vs реальная частота и визуализатор скрытых данных / «самолёты Вальда»). Жди моего «ок», затем строй.