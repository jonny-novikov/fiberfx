/**
 * elixir.suite.js — Runtime validation for the Functional Programming in Elixir
 * course. The companion to jonnify-cms: cms proves the markup is right (static
 * gates); this proves each page actually WORKS in a browser — no JS errors, no
 * mobile overflow, the build stamp decodes, reveals un-hide, widgets respond.
 *
 * Self-adapting: it opens every page, feature-detects from the live DOM, and runs
 * only the checks that apply — so it covers the whole course and any new page.
 *
 * Run (no server needed — pages are opened via file://):
 *   npm install            # once: installs playwright + chromium
 *   npm run validate:elixir            # every page
 *   ELIXIR_SAMPLE=1 npm run validate:elixir   # one-per-type smoke (~8 pages)
 *   node elixir.suite.js path/to/page.html [more.html ...]   # specific pages
 *
 * Exit code 0 = all pass, 1 = at least one failure (CI-friendly).
 */
const fs = require('fs');
const path = require('path');
const { Validator } = require('./validator');

const ELIXIR = process.env.ELIXIR_DIR || path.resolve(__dirname, '../../elixir');
const INK = 'rgb(10, 14, 26)'; // #0a0e1a — the dark-editorial body background token

// A representative page per type, for a fast smoke.
const SAMPLE = [
  'index.html',                         // the contents directory
  'course/index.html',                  // an F0 chapter landing
  'algebra/functions.html',             // a leaf lesson (canvas/SVG widget)
  'functional/folds/index.html',        // a hub
  'functional/folds/reduce.html',       // a dive
  'functional/pipeline-lab/index.html', // a lab
  'language/index.html',                // the F3 chapter landing
  'language/match/index.html',          // a hub with subpages
];

function walk(dir) {
  let out = [];
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) out = out.concat(walk(p));
    else if (e.name.endsWith('.html')) out.push(p);
  }
  return out.sort();
}

function pageList() {
  const args = process.argv.slice(2);
  if (args.length) return args.map((a) => path.resolve(a));
  if (process.env.ELIXIR_SAMPLE) return SAMPLE.map((s) => path.join(ELIXIR, s)).filter(fs.existsSync);
  return walk(ELIXIR);
}

(async () => {
  const files = pageList();
  const v = new Validator({ settleMs: 800 });
  await v.start();

  const failedPages = [];
  for (const f of files) {
    const before = v.fail;
    await v.open('file://' + f);

    // Feature-detect what this page contains, so checks self-adapt.
    const feat = await v.page.evaluate(() => ({
      stamp: !!document.querySelector('.stamp, #stampId'),
      reveal: !!document.querySelector('.reveal'),
      katex: !!document.querySelector('.katex, link[href*="katex"], script[src*="katex"]'),
      toggle: !!document.querySelector('.solid-select'),
      svg: document.querySelectorAll('svg').length,
      pager: !!document.querySelector('.pager'),
      familyA: !!document.querySelector('.stamp'), // Family A = dark-editorial lesson system
    }));

    // Universal runtime contract.
    await v.title('jonnify');                 // brand in <title>
    await v.noJsErrors();                     // nothing threw on load
    await v.noHorizontalOverflow();           // fits at desktop (1280)
    await v.setViewport(390, 800);
    await v.noHorizontalOverflow();           // fits at mobile (~390px)
    await v.setViewport(1280, 900);
    if (feat.familyA) await v.expectBackground(INK);   // design tokens applied
    if (feat.svg >= 1) await v.expectCount('svg', '>=', 1);  // a visual is present

    // Conditional, content-aware checks.
    if (feat.katex) await v.noKatexErrors();
    if (feat.stamp) await v.stampDecodes();
    if (feat.reveal) await v.revealsVisible();
    if (feat.pager) await v.expectCount('.pager a', '>=', 1);
    if (feat.toggle) await v.toggleWorks('.solid-select');

    await v.noJsErrors();                     // interactions did not break the page

    if (v.fail > before) failedPages.push(path.relative(ELIXIR, f));
  }

  const r = v.report();
  console.log(`\nPages checked: ${files.length}  |  Pages with failures: ${failedPages.length}`);
  if (failedPages.length) console.log('  ' + failedPages.join('\n  '));
  await v.stop();
  process.exit(r.fail > 0 ? 1 : 0);
})();
