# Руководство по созданию технических курсов

> **Playbook для Claude-агентов.** Этот документ описывает дизайн-систему, компоненты, правила и рабочий процесс, по которым строится курс «Здоровье как прикладная математика», и которые **переиспользуются** для любого технического курса той же школы. Цель — чтобы новый агент (или отложенная сессия) мог продолжить курс или собрать новый, не теряя единый стиль и качество.
>
> Стандарт качества — **A+ (Apollo-gate)**. Формат — Markdown, дружественный к Writerside. Язык контента курсов — русский.

---

## 0. Как пользоваться этим документом

1. Прочитайте разделы 1–5 (философия, архитектура, конвенции, визуальная система, KaTeX) — это инвариант.
2. Берите готовые скелеты из раздела 6 и интерактивы из 6.7.
3. Соблюдайте принципы честности и безопасности (раздел 7) — это не опционально.
4. Перед сдачей прогоните **все** Quality Gates (раздел 8): pre-flight скан + toolkit-валидацию.
5. Следуйте рабочему ритму (раздел 9) и рецепту модуля (раздел 10).
6. Для продолжения конкретного курса — раздел 11 (текущее состояние) и раздел 12 (какие файлы приложить).

**Канонические файлы-образцы** (прилагаются к этой сессии, копируйте из них верстку дословно):

| Роль образца | Файл |
|---|---|
| Лендинг главы | `health/plan.html` |
| Дидактический модуль (флагман) | `health/risk/bayes.html` |
| Worksheet-модуль (форма + трекер) | `health/plan/strategiya.html`, `health/plan/distsipliny.html` |
| Справочник с калькуляторами | `health/plan/instrumenty.html` |
| Лендинг главы (свежий) | `health/dolgoletie.html` |
| Живой трекер прогресса | `health-status.md` |
| Дизайн-документ курса | `health-course-design.md` |
| Источники по модулям | `health-references.md` |
| Валидатор без скриншотов | `toolkit/validator.js` |

---

## 1. Философия и концепция

**Ядро идеи:** школьные знания (биология, химия, физика, статистика, теория вероятностей) подаются как **прикладные инструменты взрослой жизни**. Курс — «навигатор» в предметной области, а не учебник. Каждая формула привязана к реальному решению.

Принципы подачи:

- **От «зачем» к «как».** Сначала зачем это нужно в жизни, потом механика.
- **Интерактив на каждый модуль.** Калькулятор/слайдер/визуализатор, который даёт читателю посчитать **своё**.
- **Математика без страха.** Формулы через KaTeX, с пояснением «на пальцах» и примером.
- **Честность важнее эффектности.** Иллюстративные модели маркируются дисклеймером; источники реальные.
- **Тёмная редакторская эстетика.** Премиальный «журнальный» вид, не «корпоративный лендинг».

Применимо к любой теме (финансы, право, инженерия, data science): меняется содержание и цвет главы — структура и компоненты те же.

---

## 2. Архитектура

**Курс = 8 глав × 6 модулей = 48 core-модулей** (число глав/модулей можно менять, но 8×6 — проверенный объём). Плюс опциональные «углубления» (deep-dives) для отдельных тем.

Три типа страниц:

1. **Лендинг главы** (`/{course}/{chapter}`) — hero, 3 intro-карты, 6 тайлов-модулей, цепочка глав, футер. Шаблон — раздел 6.1.
2. **Дидактический модуль** (`/{course}/{chapter}/{module}`) — 6 разделов с теорией, интерактив, цитата, takeaway (5 пунктов), **квиз**, **источники**, [баннер завершения, если модуль последний в главе], навигация. Шаблон — 6.2.
3. **Worksheet-модуль** (используется в финальной «проектной» главе) — теория + **заполняемая форма** (localStorage + печать), без квиза/источников (они ретрофитятся позже). Шаблон — 6.3.

Порядок блоков в дидактическом модуле строго: `разделы → срединная цитата → takeaway → квиз → источники → [баннер завершения] → навигация → футер`.

---

## 3. URL и файловые конвенции

- **Чистые URL без `.html`**: ссылки вида `/health/risk/bayes`, файл на диске — `bayes.html`.
- **Структура:** `/{course}/{chapter}.html` (лендинг), `/{course}/{chapter}/{module}.html` (модули).
- **Навигация:** кнопка «На главную» (не «К главной»); подстраницы возвращают к родительской главе («К Главе N»).
- **Рабочая директория** агента: `/home/claude/work/{course}/...`; готовое синхронизируется в `/mnt/user-data/outputs/{course}/...`. Файловая система между задачами сбрасывается — итог всегда копировать в `outputs`.
- **Snowflake ID** (предпочтение архитектора): целочисленный snowflake + брендированный ID с namespace-префиксом и base62, напр. `TSK0KHTOWnGLuC` (namespace `TSK`, snowflake `274557032793636864`). Применять, если курс генерирует сущности/идентификаторы в коде.

---

## 4. Визуальная система

### 4.1 Цветовые токены (`:root`)

Вставлять **полный** блок в каждый файл (база + все главы), чтобы цвета были доступны для кросс-ссылок:

```css
:root{
  --ink:#0a0e1a;--ink-2:#0e1322;--surface:#131826;--surface-2:#1a2138;
  --line:#2a3252;--line-soft:#1f2740;
  --cream:#ece4d0;--cream-soft:#d9cfb4;--muted:#a89a7a;--muted-2:#7d745f;
  --gold:#d4a85a;--gold-bright:#f0cd7f;--gold-deep:#a07f3a;       /* Гл.1 */
  --copper:#b8804a;--copper-bright:#d6a575;--copper-deep:#7e5a30; /* Гл.2 */
  --blue:#5a87c4;--blue-bright:#7aa8e0;--blue-deep:#3d6494;       /* Гл.3 */
  --burgundy:#c4504c;--burgundy-2:#e07672;--burgundy-deep:#8e3a37;/* Гл.4 */
  --slate:#5a8fa4;--slate-bright:#7aabc0;--slate-deep:#3e6680;    /* Гл.5 */
  --plum:#9b6fa0;--plum-bright:#bf99c3;--plum-deep:#6b4a70;       /* Гл.6 */
  --sage:#7ba387;--sage-bright:#9bc1a4;--sage-deep:#536f5d;       /* Гл.7 */
  --jade:#3d8a8e;--jade-bright:#5fb5b9;--jade-deep:#2a5e62;       /* Гл.8 */
  --serif:'Cormorant Garamond','PT Serif',Georgia,serif;
  --body:'PT Serif','Georgia',serif;
  --sans:'Manrope',system-ui,sans-serif;
  --mono:'JetBrains Mono',ui-monospace,monospace;
}
```

### 4.2 Карта цветов по главам

| Глава | Тема | Акцент | -bright | -deep |
|---|---|---|---|---|
| 1 | gold | `#d4a85a` | `#f0cd7f` | `#a07f3a` |
| 2 | copper | `#b8804a` | `#d6a575` | `#7e5a30` |
| 3 | blue | `#5a87c4` | `#7aa8e0` | `#3d6494` |
| 4 | burgundy | `#c4504c` | `#e07672` | `#8e3a37` |
| 5 | slate | `#5a8fa4` | `#7aabc0` | `#3e6680` |
| 6 | plum | `#9b6fa0` | `#bf99c3` | `#6b4a70` |
| 7 | sage | `#7ba387` | `#9bc1a4` | `#536f5d` |
| 8 | jade | `#3d8a8e` | `#5fb5b9` | `#2a5e62` |

Внутри модуля акцентный цвет берётся **из темы главы** (например, Гл.5 → `--slate*`). В верстке используйте `var(--slate)`, `var(--slate-bright)`, `var(--slate-deep)` — при новой главе достаточно заменить префикс цвета.

### 4.3 Шрифты, фон, общая эстетика

- **Заголовки** — Cormorant Garamond (serif, курсив для акцентов).
- **Текст** — PT Serif.
- **UI/подписи** — Manrope (sans).
- **Числа/формулы-инлайн** — JetBrains Mono.
- **Фон** — очень тёмный (`--ink`), радиальный градиент акцентного цвета в углу + тонкая «миллиметровка» (`body::before` grid 32px с радиальной маской).
- **Эстетика:** карточки с градиентом `--surface → --ink-2`, тонкие рамки `--line`, левый акцент-бордер для смысловых блоков, kicker-надписи капсом с лидирующей чертой.

Подключение шрифтов и KaTeX — в `<head>` (см. 5.1).

---

## 5. KaTeX — настройка и КРИТИЧЕСКИЕ правила

### 5.1 Подключение (в `<head>` каждого модуля с формулами)

```html
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/katex@0.16.9/dist/katex.min.css">
<script defer src="https://cdn.jsdelivr.net/npm/katex@0.16.9/dist/katex.min.js"></script>
<script defer src="https://cdn.jsdelivr.net/npm/katex@0.16.9/dist/contrib/auto-render.min.js"
  onload="renderMathInElement(document.body,{delimiters:[{left:'$$',right:'$$',display:true},{left:'$',right:'$',display:false}],throwOnError:false,strict:false});"></script>
```

**Тайминг:** инлайновый скрипт модуля выполняется синхронно **до** `defer` auto-render, поэтому квиз/динамика, отрисованные в DOM до этого момента (включая скрытые пояснения), будут обработаны глобальным авто-рендером один раз. Вручную перерисовывать (`rerenderMath`) нужно только то, что вставляется в DOM **после** загрузки (сброс квиза, обновление контекста калькулятора).

### 5.2 Правила strict-mode (нарушение = поломка рендера)

Режим `strict:false, throwOnError:false`. При этом:

1. **НИКОГДА** не помещать внутрь `$...$` или `$$...$$` следующие символы:
   ```
   №   ₽   «   »   "   "   „   …
   ```
   (а также любые не-ASCII «текстовые» символы валют/кавычек/многоточий). Рендерить их как обычный HTML / `<em>...</em>` **вне** математики.
2. **Проценты в JS-шаблонных литералах**: внутри `` `...` `` использовать `\\%` (не `\%`) для процента **внутри** `$...$`. Лучше — вообще не ставить `%` внутри math: выносить «%» в обычный текст после закрывающего `$`.
3. **Кириллица внутри math — допустима** при `strict:false`. Работает и в индексах (`$HR_{покоя}$`, `$T_{1/2}$`, `$VO_2max$`), и целыми словами (`$Результат = (1 + улучшение)^{дни}$`, `$BMR = 10 \cdot вес + 6{,}25 \cdot рост$`). Запятая в числах — через `{,}` (`6{,}25`).
4. **Никаких несбалансированных `$`.** Каждый открывающий `$` обязан иметь пару.
5. `<` внутри math писать как `&lt;` в HTML-исходнике — браузер декодирует в `<` до KaTeX, рендерится корректно (`$&lt;18{,}5$`).

### 5.3 Обязательный pre-flight скан (перед сдачей)

Скрипт ниже стрипит `<script>`/`<style>`, проверяет HTML-математику и JS-шаблоны на запрещённые символы и «голый» `%`, **и** ловит опечатки смешанных скриптов (кириллица+латиница в одном слове — реально ловил `обмen`, `обмen`). Прогонять на каждом файле:

```python
import re, os
files = ['path/to/module.html']   # список файлов
BAD = set('№«»""„₽…')
for f in files:
    h = open(f).read()
    # --- KaTeX: HTML-математика ---
    c = re.sub(r'<script>[\s\S]+?</script>', '', h)
    iss = []
    for m in re.finditer(r'\$\$[^$]+?\$\$|\$[^$\n]+?\$', c):
        if any(ch in BAD for ch in m.group(0)): iss.append(('HTML', m.group(0)[:50]))
    # --- KaTeX: JS-шаблонные литералы (симулируем \\% -> %) ---
    for sc in re.findall(r'<script>([\s\S]+?)</script>', h):
        for tpl in re.finditer(r'`[^`]*`', sc):
            sim = tpl.group(0).replace('\\\\', '\x00').replace('\\%', '%').replace('\x00', '\\')
            sim = re.sub(r'\$\{[^}]*\}', '0', sim)         # вырезаем ${...}
            for mm in re.finditer(r'(?<!\$)\$(?!\{)[^$\n]+?(?<!\$)\$(?!\{)', sim):
                if any(ch in BAD for ch in mm.group(0)): iss.append(('JS-BAD', mm.group(0)[:50]))
                if re.search(r'(?<!\\)%', mm.group(0)): iss.append(('JS-%', mm.group(0)[:50]))
    print(os.path.basename(f), 'KaTeX issues:', len(iss), iss[:8])
    # --- Смешанные скрипты (по тексту body, без script/style) ---
    body = re.sub(r'<script>[\s\S]+?</script>', '', h); body = re.sub(r'<style>[\s\S]+?</style>', '', body)
    mixed = [m for m in set(re.findall(r'[а-яё]+[a-z]+|[a-z]+[а-яё]+', body, re.I)) if len(m) > 2]
    print('  mixed-script:', mixed if mixed else 'clean')
```

Также проверять JS на синтаксис (`node -e "new Function(...)"`) и целостность кросс-ссылок (prev/next, тайлы, цепочка глав).

---

## 6. Библиотека компонентов

> Берите верстку **дословно** из канонических файлов (раздел 0). Ниже — скелеты и ключевые классы. Все компоненты тематизируются заменой цветового префикса (`--slate*` → `--sage*` и т.д.).

### 6.1 Лендинг главы

Образец: `health/plan.html`. Контейнер `max-width:1080px`.

```text
topbar (.brand-mark "ГN" / роман-цифра) →
hero (.hero-id "VII", .ch-badge | .finale-badge, h1, .hero-lead, .hero-quote) →
.intro-section (.intro-grid: 3× .intro-card → .ic-icon + h3 + p) →
.modules-section (.modules-head: kicker «Шесть модулей» + h2 + p;
   .tiles-grid: 6× <a class="module-tile" href="/{course}/{chapter}/{module}">
      .mt-head (.mt-num + .mt-status «Открыть»→) + .mt-body (h4 + p) + .mt-footer «Школа: <b>…</b>»;
      последний тайл — class="module-tile capstone") →
.synth-section (.synth-card: kicker + h2 + p + .chapter-chain) →
footer
```

Цепочка глав `.chapter-chain` — 8 ссылок; текущая глава — `<span class="chain-link cur">$N$</span>`, остальные `<a class="chain-link" href="/{course}/{chapter}">`.

### 6.2 Дидактический модуль (стандарт)

Образец: `health/risk/bayes.html`. Контейнер `max-width:920px`. Размер обычно 50–58 КБ.

```text
topbar (.brand-mark "N.M" + breadcrumb + back-link «К Главе N») →
hero (.hero-mark "N.M" + kicker + h1 + .hero-lead + .hero-quote) →
6× .sect (.sect-head: kicker + h2 + p.lead; .sect-block: ul/p; .formula-card с KaTeX) →
.task-block (интерактив; иллюстративные → с .disclaimer) →
.quote-block (срединная цитата) →
.takeaway-section → .takeaway (5× .takeaway-item с .ti-num $I$…$V$) →
.quiz (см. 6.4) →
.references (см. 6.5) →
[.completion-banner (см. 6.6), если модуль последний в главе] →
.nav-prev-next (2 карточки prev/next) →
.footer
```

### 6.3 Worksheet-модуль (проектная глава)

Образец: `health/plan/strategiya.html` (форма), `health/plan/distsipliny.html` (форма + трекер). Jade, `max-width:920px`. **Без квиза и источников** — они ретрофитятся в финальном проходе.

```text
topbar → hero → несколько .sect (теория) →
.worksheet (.ws-head .ws-tag «Форма N.M» + h4; .ws-intro;
   .ws-field (label + .ws-hint + textarea|input);
   [.tracker с сеткой переключателей];
   .ws-toolbar (.ws-status saved|editing + .ws-buttons: .ws-btn «Распечатать» + .ws-btn.ghost «Очистить»)) →
takeaway → nav → footer
```

`@media print` скрывает хром (`body::before, .topbar, .hero-quote, .nav-prev-next, .footer, .ws-buttons`) и делает фон белым.

### 6.4 Квиз (переиспользуемый движок)

Секция после `.takeaway`. Разметка-обёртка:

```html
<section class="quiz" id="quiz">
  <div class="quiz-head">
    <span class="quiz-tag">Проверь себя</span>
    <span class="quiz-score" id="quiz-score">0 / 5</span>
  </div>
  <p class="quiz-intro">Пять вопросов по ключевым идеям модуля…</p>
  <div id="quiz-root"></div>
  <div class="quiz-foot"><button class="quiz-reset" id="quiz-reset">Сбросить квиз</button></div>
</section>
```

Движок (вставлять в инлайновый `<script>`; `QUIZ` — 5 вопросов, `KEY` уникален на модуль):

```js
const QUIZ_KEY = 'hc-cN-slug-quiz';
const QUIZ = [
  { type:'single', q:'…?', options:['…','…','…','…'], correct:1, explain:'<b>…</b> …' },
  { type:'tf',     q:'Верно ли: «…»?', options:['Верно','Неверно'], correct:0, explain:'…' },
  { type:'calc',   q:'Посчитайте …', correct:50, tol:0, explain:'…' },
  // …5 вопросов всего
];
let quizState = {};
function saveQuiz(){ try{ localStorage.setItem(QUIZ_KEY, JSON.stringify(quizState)); }catch(e){} }
function loadQuiz(){ try{ const r = localStorage.getItem(QUIZ_KEY); if(r) quizState = JSON.parse(r); }catch(e){ quizState = {}; } }
function buildQuiz(){
  const root = document.getElementById('quiz-root'); let html = '';
  QUIZ.forEach((item, qi) => {
    html += `<div class="quiz-q" data-q="${qi}"><div class="q-text"><span class="q-num">${qi+1}</span><span>${item.q}</span></div>`;
    if (item.type === 'calc') html += `<div class="q-calc"><input type="text" inputmode="numeric" class="q-input" id="qi-${qi}" placeholder="число"><button class="q-check" data-q="${qi}">Проверить</button></div>`;
    else { html += `<div class="q-options">`; item.options.forEach((o, oi) => { html += `<button class="q-opt" data-q="${qi}" data-o="${oi}">${o}</button>`; }); html += `</div>`; }
    html += `<div class="q-explain" id="qe-${qi}">${item.explain}</div></div>`;
  });
  root.innerHTML = html;
  root.querySelectorAll('.q-opt').forEach(b => b.addEventListener('click', onOpt));
  root.querySelectorAll('.q-check').forEach(b => b.addEventListener('click', onCheck));
  Object.keys(quizState).forEach(qi => applyQ(Number(qi)));
}
function applyQ(qi){
  const item = QUIZ[qi], st = quizState[qi]; if (!st) return;
  const qEl = document.querySelector(`.quiz-q[data-q="${qi}"]`); if (!qEl) return;
  if (item.type === 'calc') {
    const inp = document.getElementById('qi-'+qi); inp.value = st.choice; inp.disabled = true;
    inp.classList.add(st.correct ? 'correct' : 'incorrect'); qEl.querySelector('.q-check').disabled = true;
  } else {
    qEl.querySelectorAll('.q-opt').forEach((b, oi) => { b.classList.add('disabled'); if (oi === item.correct) b.classList.add('correct'); else if (oi === st.choice) b.classList.add('incorrect'); });
  }
  document.getElementById('qe-'+qi).classList.add('show');
}
function onOpt(e){ const qi=Number(e.currentTarget.dataset.q), oi=Number(e.currentTarget.dataset.o); if (quizState[qi]) return; quizState[qi]={answered:true,correct:oi===QUIZ[qi].correct,choice:oi}; applyQ(qi); saveQuiz(); updateScore(); }
function onCheck(e){ const qi=Number(e.currentTarget.dataset.q); if (quizState[qi]) return; const inp=document.getElementById('qi-'+qi); const val=parseFloat(String(inp.value).replace(',','.')); const ok=isFinite(val)&&Math.abs(val-QUIZ[qi].correct)<=(QUIZ[qi].tol||0); quizState[qi]={answered:true,correct:ok,choice:inp.value}; applyQ(qi); saveQuiz(); updateScore(); }
function updateScore(){
  const ans=Object.keys(quizState).length, ok=Object.values(quizState).filter(s=>s.correct).length;
  const el=document.getElementById('quiz-score');
  if (ans===0){ el.textContent=`0 / ${QUIZ.length}`; return; }
  let t=`${ok} / ${QUIZ.length} верно`;
  if (ans===QUIZ.length) t += ok===QUIZ.length ? ' — отлично!' : (ok>=Math.ceil(QUIZ.length*0.6) ? ' — хорошо!' : ' — стоит перечитать модуль');
  el.textContent=t;
}
// init: loadQuiz(); buildQuiz(); updateScore();
// reset: quizState={}; localStorage.removeItem(QUIZ_KEY); buildQuiz(); updateScore(); rerenderMath(document.getElementById('quiz-root'));
```

**Строки квиза и KaTeX:** проценты — обычным текстом (не в `$...$`). `$...$` только для переменных без бэкслешей (`$PPV$`, `$NNT$`, `$TP$`, `$FP$`, `$ARR$`, `$NNH$`, `$VO_2max$`, `$HDL$`). Бэкслеши и `%` в JS-литералах избегать (исключение — `\\le` и подобные без `%`).

### 6.5 Блок «Источники»

После takeaway/квиза. **Только реальные** источники; ссылки — на поиск Google Scholar (всегда резолвятся, без выдуманных DOI). По 3 источника на модуль.

```html
<section class="references">
  <div class="ref-title">Источники</div>
  <ol class="ref-list">
    <li>Автор A.B. (Год). <em>Название.</em> Журнал/Издатель.
      <a href="https://scholar.google.com/scholar?q=ключевые+слова" target="_blank" rel="noopener">поиск источника</a></li>
    <!-- ещё 2 -->
  </ol>
  <p class="ref-note">Образовательный материал — не заменяет консультацию специалиста. Ссылки ведут на поиск источника; точные реквизиты сверяйте с оригиналом.</p>
</section>
```

Готовые списки источников по всем модулям курса «Здоровье» — в `health-references.md`.

### 6.6 Баннер завершения главы

Только в **последнем** модуле главы. 2px-рамка темы, ведёт к следующей главе (или к завершению курса в самом конце).

```html
<section class="completion-banner">
  <div class="completion-card">
    <div class="cmp-sym">★</div>
    <div class="cmp-tag">Глава N завершена</div>
    <h3>Вы освоили <span class="em">…</span></h3>
    <p>…краткий синтез…</p>
    <a class="cmp-next" href="/{course}/{next-chapter}">Глава N+1 · Название</a>
  </div>
</section>
```

### 6.7 Интерактивы

Все интерактивы — внутри `.task-block`. Иллюстративные/оценочные модели снабжать `.disclaimer` (см. раздел 7). Паттерны:

**(а) Калькулятор с localStorage** — слайдеры/seg-контролы → результат + контекст.

```js
const STORAGE_KEY = 'hc-cN-slug';
const state = { /* поля по умолчанию */ };
function save(){ try{ localStorage.setItem(STORAGE_KEY, JSON.stringify(state)); }catch(e){} }
function load(){ try{ const r=localStorage.getItem(STORAGE_KEY); if(r) Object.assign(state, JSON.parse(r)); }catch(e){} }
function rerenderMath(el){ if(window.renderMathInElement){ renderMathInElement(el,{delimiters:[{left:'$$',right:'$$',display:true},{left:'$',right:'$',display:false}],throwOnError:false,strict:false}); } }
function calc(){ /* пересчёт → обновить DOM; если контекст содержит $...$, вызвать rerenderMath(ctxEl) */ }
```

**(б) Seg-control (выбор из вариантов)** — кнопки `.seg button[data-val]`, активная `.active`.

```js
function wireSeg(id){
  const seg = document.getElementById(id), key = seg.dataset.key;
  seg.querySelectorAll('button').forEach(b => b.addEventListener('click', () => {
    state[key] = isNaN(Number(b.dataset.val)) ? b.dataset.val : Number(b.dataset.val);
    seg.querySelectorAll('button').forEach(x => x.classList.toggle('active', x === b));
    save(); calc();
  }));
  seg.querySelectorAll('button').forEach(b => b.classList.toggle('active', b.dataset.val === String(state[key])));
}
```

**(в) Слайдер** — `<input type="range">` + лейбл со значением; `oninput` → `state.x = Number(...)`, `save()`, `calc()`.

**(г) Чек-лист доверия** — N переключаемых критериев → счёт + вердикт (`health/risk/novosti.html`).

**(д) Фрейминг-флиппер** — один и тот же показатель в двух рамках + сетка 10×10 (`health/risk/oshibki.html`): демонстрирует эффект формулировки.

**(е) Недельный трекер** — сетка дисциплин × дни из кнопок-ячеек, состояние в localStorage (`health/plan/distsipliny.html`):

```js
// tracker[`${disciplineIndex}-${dayIndex}`] = bool;
// клик по .tr-cell: tracker[k]=!tracker[k]; b.classList.toggle('on', tracker[k]); b.textContent = tracker[k]?'✓':''; scheduleSave();
// save(): { fields:{…}, tracker }; «Сбросить неделю» очищает только tracker.
```

**(ж) Дерево/визуализатор** — например, дерево натуральных частот в Байесе (`health/risk/bayes.html`) — мощный способ показать вероятности «на 1000 человек».

**Авто-сохранение формы** (worksheet): debounce 500–600 мс на `input`, индикатор `.ws-status` (`editing` → `saved`).

---

## 7. Принципы честности и безопасности

Эти правила **обязательны** — нарушение опускает курс ниже A+.

1. **Иллюстративные модели — с дисклеймером.** Если калькулятор не является валидированным клиническим/юридическим/финансовым инструментом, добавлять явный `.disclaimer`: «образовательная иллюстрация, не <диагностика/совет>; для реального расчёта — официальный инструмент и специалист». Примеры: оценщик «возраста здоровья» (`biovozrast`), упрощённый ССС-риск (`score2` — **не** валидированный SCORE2).
2. **Реальные источники.** Никаких выдуманных DOI/ссылок. Ссылка — на поиск Google Scholar по ключевым словам (всегда резолвится). Реальные имена/работы — только там, где есть уверенность.
3. **Без фабрикации цитат.** Срединные цитаты и hero-цитаты атрибутировать как **принципы** («Принцип …»), а не приписывать реальным людям выдуманные слова. Реальная атрибуция (напр. Сенека, «О краткости жизни») — только для проверяемых, широко документированных цитат.
4. **Медицина/право/финансы.** В `.ref-note` и при чувствительных темах — оговорка, что материал образовательный и не заменяет специалиста. Не давать персональных предписаний.
5. **Безопасность.** Никакого контента, способного навредить. Для тем здоровья — не давать точных протоколов, которые можно использовать во вред; при темах питания/нагрузок избегать чисел-целей, провоцирующих расстройства.
6. **Числа проверяются заранее.** Любую формулу/модель интерактива прогонять в Python **до** верстки (несколько профилей, проверка монотонности и границ категорий), затем дублировать ту же формулу в JS. Так пойманы корректные значения BMR/TDEE/ИМТ/VO₂max/T½/NNT, Байеса (PPV), NNT и т.д.

---

## 8. Quality Gates (перед каждой сдачей)

### 8.1 Pre-flight скан (раздел 5.3)

KaTeX (HTML + JS-литералы), смешанные скрипты, целостность кросс-ссылок, синтаксис JS. Должно быть **0** проблем KaTeX и **0** смешанных слов.

### 8.2 Toolkit — валидация без скриншотов

Бюджет изображений в чате ограничен — **PNG не открывать** (`view`). Проверять через DOM/computed-style (текстовый stdout = 0 бюджета). Пакет — `toolkit/validator.js` (класс `Validator`).

API валидатора (основное):

```text
open(path) · title(sub) · noKatexErrors() · noHorizontalOverflow(tol=2) ·
expectText(sel, substr) · expectTextEquals(sel, text) · fill(sel, val) · click(sel) ·
computedStyle/expectStyle · count→expectCount(sel, op, n) · expectVisible(sel) ·
settle(ms) · localStorage/expectStored · report()
```

Шаблон сьюта (`suite.chN.js`):

```js
const { Validator } = require('/mnt/user-data/outputs/toolkit/validator.js');
(async () => {
  const v = new Validator({ baseUrl: process.env.BASE_URL });
  await v.start();
  await v.open('/chapter/module.html');
  await v.title('Название модуля');
  await v.noKatexErrors();
  await v.noHorizontalOverflow();
  // интерактив:
  await v.click('#seg-x button[data-val="…"]'); await v.settle(150);
  await v.expectText('#result', 'ожидаемое');
  // квиз:
  await v.click('.quiz-q[data-q="0"] .q-opt[data-o="1"]'); await v.settle(120);
  await v.expectVisible('#qe-0'); await v.expectText('#quiz-score', '1 / 5');
  // источники:
  await v.expectCount('.references .ref-list li', '==', 3);
  v.report(); await v.stop(); process.exit(v.fail ? 1 : 0);
})();
```

Запуск (Playwright установлен глобально; dev-зависимости pixelmatch/pngjs — в `toolkit-verify`):

```bash
BASE_URL="file:///home/claude/work/{course}" \
NODE_PATH="/home/claude/.npm-global/lib/node_modules:/home/claude/work/toolkit-verify/node_modules" \
node suite.chN.js
```

Цель — **N/N PASS, Images embedded: 0**. Типовые пары давали 20–24 проверки на пару модулей.

### 8.3 Что именно проверять

- `title`, отсутствие KaTeX-ошибок, отсутствие горизонтального переполнения.
- Интерактив: дефолтное значение + изменение хотя бы одного входа → ожидаемый результат (монотонность).
- Квиз: клик по верному варианту → раскрытие пояснения + счёт `1 / 5`.
- Кол-во `.references li` == 3; для последнего модуля — `.completion-banner` виден и ведёт в нужную главу.
- Лендинг: 6 `.module-tile`, 8 `.chain-link`, 1 `.chain-link.cur`.
- Worksheet: число полей/ячеек трекера, переключение ячейки, автосейв (`#ws-status-text` → «Сохранено»).

---

## 9. Рабочий ритм

- **2 модуля за запрос** (лендинг главы может идти вместе с первой парой). Между парами — ревью архитектора.
- Цикл на каждую пару: **построить → pre-flight → toolkit-валидация → синхронизировать в `outputs` → `present_files` → обновить `health-status.md`**.
- Синхронизация: `cp /home/claude/work/{course}/.../*.html /mnt/user-data/outputs/{course}/.../`.
- `present_files`: первым — самый важный файл (обычно новый модуль/лендинг), затем парный модуль и `health-status.md`.
- После сдачи — без длинных постскриптумов; коротко резюме и «что дальше».

---

## 10. Рецепт «как построить модуль»

1. **Определить тип** (дидактический / worksheet) и тему главы (цвет).
2. **Спроектировать интерактив** и проверить его математику в Python (несколько профилей, границы).
3. **Взять скелет** из канонического образца (раздел 0), заменить цветовой префикс на тему главы.
4. **Написать 6 разделов** теории (kicker + h2 + lead + sect-block; формулы в `.formula-card`).
5. **Собрать интерактив** (`.task-block`; иллюстративный → `.disclaimer`).
6. **Срединная цитата** (принцип) + **takeaway** (5 пунктов $I$…$V$).
7. **Квиз** (5 вопросов, движок из 6.4) + **источники** (3, реальные) [+ баннер завершения, если последний].
8. **Навигация** prev/next + футер.
9. **Pre-flight скан** (KaTeX + смешанные скрипты + ссылки + JS) → 0 проблем.
10. **Toolkit-сьют** → N/N PASS, 0 изображений.
11. **Синхронизировать → present_files → обновить статус-трекер** (счётчики, статус главы, журнал, финальный KaTeX-скан статус-файла).

---

## 11. Текущее состояние курса «Здоровье как прикладная математика»

> Источник истины — `health-status.md` (живой трекер). Здесь — срез на момент написания playbook.

- **Core-модулей:** 42 / 48. **Глав полностью завершено:** 6 / 8 (Гл. 1–6). **Страниц глав:** 8 / 8. **HTML-файлов:** 60 + лендинг.
- **Гл. 1 Энергобаланс** (gold) ★ — `kalorii, bmr, tdee, sostav, defitsit, adaptatsiya` (+ deep-dives). Без квиза/источников (ретрофит).
- **Гл. 2 Питание** (copper) ★ — `makro, mikro, gi, etiketki, voda, ritm` (+ deep-dive `dnevnik`).
- **Гл. 3 Сон** (blue) ★ — `arkhitektura, tsirkad, dolg, gigiena, zdorovie, spetsialist` (+ deep-dives).
- **Гл. 4 Активность** (burgundy) ★ — `zachem, zony, vo2max, sila, neat, period` (+ deep-dives).
- **Гл. 5 Риск** (slate) ★ **завершена 6/6** — `absolyut, testy, bayes, nnt, novosti, oshibki`. Источники во всех; квизы в 4 (bayes, nnt, novosti, oshibki); баннер завершения в `oshibki` → Гл. 6.
- **Гл. 6 Лекарства** (plum) ★ — `adme, kinetika, biodostup, cyp, pobochki, placebo` (+ deep-dives). Баннер `placebo` → Гл. 7.
- **Гл. 7 Долголетие** (sage) ◐ **2/6** — лендинг `dolgoletie.html` + `biovozrast` (7.1), `score2` (7.2, иллюстративный, не валидированный SCORE2). Оба с квизом и источниками. **Осталось:** `skrining` (7.3), `marshruty` (7.4), `dobavki-mify` (7.5), `sintez` (7.6 → баннер в Гл. 8).
- **Гл. 8 План** (jade) ◐ **4/6** — лендинг `plan.html` + `strategiya` (8.1), `karta` (8.2), `distsipliny` (8.3, форма + недельный трекер), `instrumenty` (8.4, 5 калькуляторов). Worksheet-паттерн (localStorage, печать), без квиза/источников. **Осталось:** `plan20` (8.5, прогноз HALE), `kalendar` (8.6 → завершение курса).

**Дорожная карта (по 2 модуля):**
- Гл. 8 → `plan20` (8.5) + `kalendar` (8.6, завершение курса) — закроет главу.
- Гл. 7 → `skrining` (7.3) + `marshruty` (7.4); затем `dobavki-mify` (7.5) + `sintez` (7.6).
- Финальный проход → ретрофит «Источников» + квизов в 34 ранних/worksheet-модуля (Гл. 1–4, 6, и worksheet-модули Гл. 8). Готовый контент источников — в `health-references.md`.

**Реализованные баннеры завершения:** Гл.1→2 (`adaptatsiya`), 2→3 (`ritm`), 3→4 (`spetsialist`), 4→5 (`period`), 5→6 (`oshibki`), 6→7 (`placebo`). Ожидаются: 7.6 `sintez`→Гл.8, 8.6 `kalendar`→завершение курса.

---

## 12. Файлы для отложенной сессии

Чтобы продолжить курс в **новой** сессии (файловая система сбрасывается), приложите к запросу:

**Обязательно:**
1. Этот playbook (`course-build-playbook.md`) — система и правила.
2. `health-status.md` — где остановились, счётчики, дорожная карта, журнал.

**Канонические образцы для копирования верстки:**
3. `health/plan.html` — лендинг главы.
4. `health/risk/bayes.html` — дидактический модуль-флагман (интерактив + квиз + источники).
5. `health/plan/strategiya.html` — worksheet-модуль (форма).
6. `health/plan/distsipliny.html` — worksheet + недельный трекер.
7. `health/plan/instrumenty.html` — справочник с калькуляторами.

**Справочные:**
8. `health-course-design.md` — полный дизайн-документ курса.
9. `health-references.md` — реальные источники по всем модулям + формат блока.
10. `toolkit/validator.js` — валидатор без скриншотов (+ при наличии `toolkit/visual.js`).

Стартовая реплика в новой сессии (пример): «Продолжаем курс “Здоровье”. По playbook и статусу: собери Гл. 8 — `plan20` (8.5) + `kalendar` (8.6, баннер завершения курса). Worksheet-паттерн, валидация toolkit, 0 изображений».

---

## 13. Чеклист A+ (Apollo gate) перед сдачей

- [ ] Тип модуля и цвет главы выдержаны; верстка скопирована из образца, префикс цвета заменён.
- [ ] 6 разделов теории; интерактив на месте; иллюстративный — с дисклеймером.
- [ ] Математика интерактива проверена в Python и совпадает с JS.
- [ ] Срединная цитата (принцип) + takeaway (5 пунктов).
- [ ] Дидактический: квиз (5 вопросов) + источники (3 реальных) [+ баннер, если последний].
- [ ] Worksheet: автосейв + печать; @media print скрывает хром.
- [ ] Чистые URL; навигация prev/next и breadcrumb корректны; «На главную».
- [ ] Pre-flight: 0 KaTeX-проблем (HTML + JS-литералы), 0 смешанных слов, JS парсится, ссылки целы.
- [ ] Toolkit: N/N PASS, Images embedded: 0.
- [ ] Синхронизировано в `outputs`; `present_files` вызван (важный файл — первым).
- [ ] `health-status.md` обновлён (счётчики, статус главы, журнал) и сам прошёл KaTeX-скан (0).
- [ ] Без фабрикации цитат/источников; безопасность и медицинские оговорки соблюдены.

---

*Документ описывает дизайн-систему и процесс, проверенные на курсе «Здоровье как прикладная математика». Для нового курса меняются содержание, набор глав и палитра; компоненты, правила KaTeX, движок квиза, интерактивы, принципы честности и Quality Gates переиспользуются без изменений.*

---

## Паттерн: двухколоночный блок «иллюстрация + цитата» (.quote-row)

Обновление дизайн-системы. Блок с принципом-цитатой теперь подаётся в **две колонки**:
слева — **интерактивный SVG**, иллюстрирующий идею модуля (показательный и, где
целесообразно, анимированный); справа — цитата-принцип. На мобиле (≤760px) две
колонки превращаются в **две строки** (SVG сверху, цитата снизу).

Назначение левой колонки — наглядно показать суть модуля вектором (не растром):
оптическая иллюзия для модулей про искажения, график для вероятности, схема для
процессов и т. п. SVG может иметь лёгкую CSS-анимацию и одну кнопку-переключатель
(«показать/измерить»), которая раскрывает суть. Никаких изображений-растров и эмодзи.

### Разметка

```html
<section class="quote-section">
  <div class="container">
    <div class="quote-row">
      <div class="quote-illus">
        <svg id="idea-svg" class="idea-svg" viewBox="0 0 300 170" role="img" aria-label="...">…</svg>
        <button class="illus-btn" id="idea-btn">Измерить</button>
      </div>
      <div class="quote-card">
        <p class="qc-text">Текст принципа…</p>
        <span class="qc-source">Принцип главы</span>
      </div>
    </div>
  </div>
</section>
```

### CSS

```css
.quote-row{display:grid;grid-template-columns:1fr 1fr;gap:22px;max-width:880px;margin:0 auto;align-items:stretch}
@media (max-width:760px){ .quote-row{grid-template-columns:1fr} }      /* мобайл: 2 строки */
.quote-illus{background:linear-gradient(165deg,var(--surface) 0%,var(--ink-2) 100%);border:1px solid var(--accent-deep);border-radius:3px;padding:20px;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:14px}
.quote-illus svg{width:100%;max-width:300px;height:auto}
.illus-btn{font-family:var(--sans);font-size:.74rem;font-weight:600;padding:7px 16px;border:1px solid var(--accent);border-radius:2px;background:rgba(var(--rgb),.14);color:var(--accent-bright);cursor:pointer;transition:.2s}
.illus-btn:hover{background:rgba(var(--rgb),.26)}
.quote-card{background:linear-gradient(165deg,var(--surface) 0%,var(--ink-2) 100%);border:1px solid var(--accent-deep);border-radius:3px;padding:28px 30px;display:flex;flex-direction:column;justify-content:center;position:relative}
.quote-card::before{content:'\201C';position:absolute;top:-6px;left:16px;font-family:var(--serif);font-size:4rem;color:var(--accent-bright);opacity:.5;line-height:1}
.quote-card .qc-text{font-family:var(--serif);font-style:italic;font-size:1.2rem;line-height:1.45;color:var(--cream);margin:0 0 12px}
.quote-card .qc-source{font-family:var(--sans);font-size:.7rem;letter-spacing:.14em;text-transform:uppercase;color:var(--accent-bright);font-weight:600}
```

### Анимация + интерактив (пример: иллюзия Мюллера-Лайера)

SVG показывает две равные линии, кажущиеся разными; направляющие равенства **пульсируют
по CSS-циклу** (демонстрация), а кнопка фиксирует измерение (интерактив):

```css
.idea-svg .ml-guides{animation:mlPulse 4.5s ease-in-out infinite}
@keyframes mlPulse{0%,100%{opacity:0}45%,55%{opacity:.7}}
.idea-svg.measured .ml-guides{animation:none;opacity:1}
.idea-svg .ml-badge{opacity:0;transition:opacity .25s}
.idea-svg.measured .ml-badge{opacity:1}
```

```js
const s=document.getElementById('idea-svg'), b=document.getElementById('idea-btn');
b.addEventListener('click',()=>{ b.textContent = s.classList.toggle('measured') ? 'Скрыть' : 'Измерить'; });
```

### Валидация (0 image budget)
`expectCount('.quote-row','>=',1)`, `expectCount('.idea-svg','>=',1)`; клик по `#idea-btn`,
затем `expectText('#idea-btn','Скрыть')` (переключатель сработал). SVG — вектор, бюджет
изображений не тратит; смотреть PNG не нужно.
