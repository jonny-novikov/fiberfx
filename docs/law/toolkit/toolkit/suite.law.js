/**
 * suite.law.js — headless DOM-валидация курса «Право повседневной жизни».
 * Реальная (не «дымовая») проверка живых страниц law/: универсальные инварианты
 * на КАЖДОЙ странице + точечные функциональные проверки интерактивов.
 * 0 скриншотов (бюджет изображений = 0) — всё через DOM/computedStyle в stdout.
 *
 * Запуск (локально):
 *   BASE_URL="file:///Users/jonny/dev/jonnify/law" \
 *   NODE_PATH="/Users/jonny/dev/jonnify/apps/e2e/node_modules" \
 *   node suite.law.js [relpath ...]
 *
 * Без аргументов проверяет известный набор построенных страниц. Вотчер передаёт
 * список изменившихся страниц аргументами (валидируем только их).
 */
const { Validator } = require('./validator');

// Построенные на сегодня страницы (относительно BASE_URL = .../law).
const DEFAULT_PAGES = [
  'index.html',
  'nesovershennoletnie/index.html',
  'dogovor/index.html', 'dogovor/sila.html', 'dogovor/kviz.html',
  'potrebitel/index.html', 'trud/index.html',
  'semya/index.html', 'nasledstvo/index.html', 'pretenziya/index.html',
];

// Точечные функциональные проверки по конкретным страницам.
const TARGETED = {
  // Главная курса: ровно 6 карточек глав.
  'index.html': async (v) => {
    await v.expectCount('.ch-card', '==', 6);
  },
  // Гл.3 «Труд»: калькулятор сверхурочных. Формула из verify_numbers.py:
  // ставка 300 × 3ч = 900 (первые 2ч ×1,5) + 600 (далее ×2) = 1500.
  'trud/index.html': async (v) => {
    // Результат скрыт до первого расчёта — проверяем ПОСЛЕ клика.
    await v.fill('#otc-rate', '300');
    await v.fill('#otc-hours', '3');
    await v.click('#otc-btn');
    await v.settle(250);
    await v.expectVisible('#otc-result');
    await v.expectText('#otc-result', '1500');
  },
  // Модуль 1.1: липкая навигация + квиз на 5 + блок источников.
  'dogovor/sila.html': async (v) => {
    await v.expectVisible('.section-nav');
    await v.expectCount('.quiz-q', '>=', 5);
    await v.expectCount('.references li', '>=', 3);
  },
  // Квиз главы 1: движок отрисован (>=5 вопросов, счёт виден).
  'dogovor/kviz.html': async (v) => {
    await v.expectCount('.quiz-q', '>=', 5);
    await v.expectVisible('#quiz-score');
  },
};

(async () => {
  const pages = process.argv.slice(2).length ? process.argv.slice(2) : DEFAULT_PAGES;
  const v = new Validator({ baseUrl: process.env.BASE_URL });
  await v.start();
  for (const p of pages) {
    // Нормализуем путь к виду относительно BASE_URL (.../law): принимаем абсолютный
    // (/…/law/X), репо-относительный (law/X) и уже относительный (X).
    const rel = p.replace(/^.*\/law\//, '').replace(/^law\//, '').replace(/^\//, '');
    // Живое дерево меняется параллельно (контент-работа, вотчеры) — страница могла
    // исчезнуть/переехать между перечислением и проверкой. Не валим весь прогон.
    try {
      await v.open(rel);
    } catch (e) {
      v.check(`страница доступна: ${rel}`, false, String(e && e.message).slice(0, 80));
      continue;
    }
    // Универсальные инварианты — на каждой странице курса.
    const t = await v.text('title');
    v.check('title непустой', t.length > 0, t);
    await v.noKatexErrors();
    await v.noHorizontalOverflow();
    // Честность: дисклеймер присутствует — баннер/.disclaimer ЛИБО текст-маркер
    // (как в audit_law.py: оба чекера должны одинаково понимать «есть дисклеймер»).
    const elemDisc = (await v.count('.law-banner')) + (await v.count('.disclaimer'));
    const bodyTxt = await v.text('body');
    const hasDisc = elemDisc > 0 ||
      bodyTxt.includes('не юридическая консультация') || bodyTxt.includes('образовательн');
    v.check('дисклеймер присутствует', hasDisc, { elemDisc, textMarker: hasDisc });
    // Точечная проверка, если есть.
    if (TARGETED[rel]) await TARGETED[rel](v);
  }
  const { fail } = v.report();
  await v.stop();
  process.exit(fail > 0 ? 1 : 0);
})().catch((e) => { console.error('suite error:', e && e.message); process.exit(2); });
