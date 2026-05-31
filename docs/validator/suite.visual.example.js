/**
 * suite.visual.example.js — Visual regression suite. Copy & adapt.
 *
 * First run creates baselines under __screenshots__/baseline/ (commit them).
 * Later runs compare and write __screenshots__/diff/ — results print as TEXT,
 * no images embedded.
 *
 * Run:
 *   BASE_URL="file:///abs/path/to/site" node suite.visual.example.js
 *   BASE_URL="http://localhost:3000"    node suite.visual.example.js
 *
 * Refresh baselines after an intentional UI change:
 *   UPDATE_SNAPSHOTS=1 BASE_URL="..." node suite.visual.example.js
 */
const { VisualTester } = require('./visual');

(async () => {
  const v = new VisualTester({
    baseUrl: process.env.BASE_URL || 'file:///path/to/site',
    snapshotDir: './__screenshots__',
    threshold: 0.001,   // allow up to 0.1% changed pixels (anti-alias jitter)
  });
  await v.start();

  // --- full-page visual regression ----------------------------------------
  await v.open('/index.html');
  await v.notBlank('index_page');            // render sanity (not white/black)
  await v.snapshot('index_full');            // full-page screenshot vs baseline

  // --- element-scoped visual regression ------------------------------------
  await v.open('/dashboard.html');
  await v.notBlank('dashboard_hero', { selector: '.hero' });
  await v.snapshot('dashboard_hero', { selector: '.hero' });
  await v.snapshot('dashboard_chart', { selector: '.chart', threshold: 0.005 });

  // You can mix DOM + visual checks freely (VisualTester extends Validator):
  await v.title('Dashboard');
  await v.noKatexErrors();
  await v.noHorizontalOverflow();

  v.report();
  await v.stop();
  process.exit(v.fail > 0 ? 1 : 0);
})();
