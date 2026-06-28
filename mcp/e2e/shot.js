// Headless figure screenshotter — companion to figures.suite.js.
// Renders a page (file:// or served) and saves each figure element as a PNG so
// layout flaws the getBBox validator can't see (clipped-in-box text, orphaned
// connectors, floating labels) become visible.
//
//   BASE_URL="file:///…/html/redis-patterns" node shot.js production-operations/kernel-tuning/index.html …
//
// Output: /tmp/shots/<page-path-flattened>__fig<N>.png  (one per figure element)
const { chromium } = require('playwright');
const fs = require('fs');

(async () => {
  const base = (process.env.BASE_URL || '').replace(/\/$/, '');
  if (!base) { console.error('Set BASE_URL'); process.exit(2); }
  const pages = process.argv.slice(2).filter((a) => !a.startsWith('-'));
  const outDir = '/tmp/shots';
  fs.mkdirSync(outDir, { recursive: true });

  const browser = await chromium.launch();
  const ctx = await browser.newContext({ viewport: { width: 1120, height: 1700, deviceScaleFactor: 2 } });
  const page = await ctx.newPage();

  for (const p of pages) {
    await page.goto(base + '/' + p, { waitUntil: 'load' });
    await page.waitForTimeout(120);
    const stem = p.replace(/\.html$/, '').replace(/\//g, '__');
    // a "figure" = anything that wraps a teaching SVG: .anatomy, figure, .htabs, .bridge, or a lone svg with a viewBox
    const figs = page.locator('figure.anatomy, .anatomy, figure, .htabs');
    const n = await figs.count();
    if (n === 0) { console.log(`NO-FIG  ${p}`); continue; }
    let shot = 0;
    for (let i = 0; i < n; i++) {
      const f = figs.nth(i);
      // only shoot figures that actually contain an <svg> (skip prose figures)
      if ((await f.locator('svg').count()) === 0) continue;
      try {
        await f.scrollIntoViewIfNeeded();
        await f.screenshot({ path: `${outDir}/${stem}__fig${shot}.png` });
        console.log(`shot    ${stem}__fig${shot}.png`);
        shot++;
      } catch (e) { console.log(`skip    ${stem} #${i}: ${e.message}`); }
    }
    if (shot === 0) console.log(`NO-SVG  ${p}`);
  }
  await browser.close();
})();
