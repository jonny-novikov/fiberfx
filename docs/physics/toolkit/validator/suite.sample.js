/* suite.sample.js — образцы toolkit: лендинг главы 1 + модуль 1.4 (калькулятор + квиз).
   BASE_URL="file:///home/claude/work/physics/site" node suite.sample.js */
const { Validator } = require('./validator');
(async () => {
  const v = new Validator({ baseUrl: process.env.BASE_URL });
  await v.start();

  // лендинг главы 1
  await v.open('/physics/tok/index.html');
  await v.title('Глава 1');
  await v.noKatexErrors();
  await v.noHorizontalOverflow();
  await v.expectCount('.section-nav a', '==', 3);
  await v.expectCount('.ch-tile', '==', 5);
  await v.expectCount('.ch-tile[href="/physics/tok/zakon-oma"]', '==', 1);
  await v.expectCount('a[href="/physics/tok/kviz"]', '>=', 1);

  // модуль 1.4 — калькулятор + квиз
  await v.open('/physics/tok/zakon-oma.html');
  await v.title('Закон Ома');
  await v.noKatexErrors();
  await v.noHorizontalOverflow();
  await v.expectCount('.section-nav a', '==', 4);
  await v.expectCount('.formula-box', '==', 1);
  // калькулятор закона Ома: U=12, R=4 -> I=3 А
  await v.fill('#om-u', '12');
  await v.fill('#om-r', '4');
  await v.click('#om-btn');
  await v.settle(150);
  await v.expectText('#om-res', 'I =');
  await v.expectText('#om-res', '3');
  await v.expectText('#om-res', 'Вт');
  // квиз модуля
  await v.expectCount('.quiz-q', '==', 5);
  await v.click('.quiz-q[data-q="0"] .q-opt[data-o="0"]');
  await v.settle(120);
  await v.expectText('#quiz-score', '1 / 5');
  await v.expectText('#qe-0', 'U, I');

  v.report();
  await v.stop();
  process.exit(v.fail ? 1 : 0);
})();
