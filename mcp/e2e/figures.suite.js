/**
 * figures.suite.js — battle-test jonnify static figures for display flaws.
 *
 * For every page given, loads it head-less and asserts:
 *   • no horizontal page overflow;
 *   • every <svg> figure's labels FIT — no label overflows its box, no edge
 *     label overlaps a box, nothing spills outside the viewBox.
 *
 * Page selection (first that applies):
 *   1. CLI args  :  node figures.suite.js queues/atomic-state-machine/index.html …
 *   2. PAGES_FILE:  newline-delimited list of paths (the broad sweep)
 *   3. default   :  the known redis-patterns box-figure pages
 *
 * BASE_URL points at the served root, e.g.
 *   BASE_URL="file:///Users/jonny/dev/jonnify/html/redis-patterns" npm run figures
 */
const fs = require('fs');
const { Validator } = require('./validator');

function pages() {
  const args = process.argv.slice(2).filter((a) => !a.startsWith('-'));
  if (args.length) return args;
  if (process.env.PAGES_FILE) {
    return fs.readFileSync(process.env.PAGES_FILE, 'utf8')
      .split('\n').map((s) => s.trim()).filter(Boolean);
  }
  return [
    'queues/atomic-state-machine/index.html',
    'queues/atomic-state-machine/states-as-locations.html',
  ];
}

(async () => {
  if (!process.env.BASE_URL) {
    console.error('Set BASE_URL (e.g. file:///…/html/redis-patterns).');
    process.exit(2);
  }
  const v = new Validator({ baseUrl: process.env.BASE_URL });
  await v.start();
  for (const p of pages()) {
    try {
      await v.open(p);
      await v.noHorizontalOverflow();
      await v.svgFiguresFit();
    } catch (e) {
      v.check('page loads', false, String((e && e.message) || e));
    }
  }
  v.report();
  await v.stop();
  process.exit(v.fail > 0 ? 1 : 0);
})();
