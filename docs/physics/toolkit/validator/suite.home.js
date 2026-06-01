/* suite.home.js — валидация Главной страницы курса /physics.
   BASE_URL="file:///home/claude/work/physics/site" node suite.home.js */
const { Validator } = require('./validator');

(async () => {
  const v = new Validator({ baseUrl: process.env.BASE_URL });
  await v.start();

  await v.open('/physics/index.html');
  await v.title('Электричество и устройства');
  await v.noKatexErrors();
  await v.noHorizontalOverflow();

  // улучшенная навигация
  await v.expectCount('.progress-bar', '==', 1);
  await v.expectVisible('.section-nav');
  await v.expectCount('.section-nav a', '==', 4);
  await v.expectVisible('.hero');
  await v.expectVisible('.safety-banner');

  // секции для scroll-spy
  await v.expectVisible('#about');
  await v.expectVisible('#chapters');
  await v.expectVisible('#approach');
  await v.expectVisible('#project');

  // сетка глав: 5 глав + финальный проект, все ссылки корректны
  await v.expectCount('.ch-tile', '==', 6);
  await v.expectCount('.ch-tile[href="/physics/tok"]', '==', 1);
  await v.expectCount('.ch-tile[href="/physics/moshchnost"]', '==', 1);
  await v.expectCount('.ch-tile[href="/physics/schet"]', '==', 1);
  await v.expectCount('.ch-tile[href="/physics/bezopasnost"]', '==', 1);
  await v.expectCount('.ch-tile[href="/physics/ustroystva"]', '==', 1);
  await v.expectCount('.ch-tile.final[href="/physics/final"]', '==', 1);
  await v.expectCount('.ct-form', '==', 6);

  // подход и финальный проект
  await v.expectCount('.pillar', '==', 4);
  await v.expectCount('.project-cta a[href="/physics/final"]', '==', 1);
  await v.expectVisible('.footer');
  await v.expectVisible('.to-top');

  v.report();
  await v.stop();
  process.exit(v.fail ? 1 : 0);
})();
