/**
 * suite.example.js — Example validation suite. Copy & adapt the checks.
 * Every assertion reads the live DOM / computed styles — no screenshots.
 *
 * Run:
 *   BASE_URL="file:///abs/path/to/site" node suite.example.js
 *   BASE_URL="http://localhost:3000"    node suite.example.js
 */
const { Validator } = require('./validator');

(async () => {
  // BASE_URL env var wins; otherwise falls back to the string below.
  const v = new Validator({ baseUrl: process.env.BASE_URL || 'file:///path/to/site' });
  await v.start();

  // --- Page 1: a calculator -------------------------------------------------
  await v.open('/calc.html');
  await v.title('Calculator');
  await v.noKatexErrors();              // math rendered cleanly (0 .katex-error nodes)
  await v.noHorizontalOverflow();       // layout fits, no horizontal scroll
  await v.fill('#input-a', '92');
  await v.fill('#input-b', '80');
  await v.settle(750);                  // wait past any debounce before reading state
  await v.expectTextEquals('#result', '-12');         // exact, whitespace-insensitive
  await v.expectStored('app-state', 'a', '92');       // persisted to localStorage

  // --- Page 2: theme + chart ------------------------------------------------
  await v.open('/dashboard.html');
  await v.expectStyle('.brand', 'color', 'rgb(224, 118, 114)'); // accent color applied
  await v.expectCount('svg path', '>=', 1);                     // chart actually drawn
  await v.expectVisible('.chart');
  await v.expectText('.summary', 'total');                      // substring present

  // --- Page 3: an interactive widget with a control -------------------------
  await v.open('/widget.html');
  await v.click('#tab-advanced');       // switch a tab / toggle
  await v.settle(300);
  await v.expectVisible('#advanced-panel');

  v.report();
  await v.stop();
  process.exit(v.fail > 0 ? 1 : 0);     // CI-friendly: non-zero exit on any failure
})();
