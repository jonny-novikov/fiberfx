import { chromium } from 'playwright';

const b = await chromium.launch();
const out = {};

async function capture(name, url) {
  const p = await b.newPage({ viewport: { width: 1440, height: 1024 }, deviceScaleFactor: 2 });
  await p.goto(url, { waitUntil: 'networkidle' });
  await p.waitForTimeout(700); // let webfonts settle
  // hero only
  const hero = await p.$('section.hero');
  if (hero) await hero.screenshot({ path: `/tmp/${name}-hero.png` });
  // hero + first content section, to compare hero body text vs section prose
  await p.screenshot({ path: `/tmp/${name}-top.png`, clip: { x: 0, y: 0, width: 1440, height: 1024 } });
  // computed metrics
  out[name] = await p.evaluate(() => {
    const g = (sel) => {
      const el = document.querySelector(sel);
      if (!el) return null;
      const s = getComputedStyle(el);
      return { fontSize: s.fontSize, family: s.fontFamily.split(',')[0].replace(/["']/g, ''), color: s.color, weight: s.fontWeight };
    };
    return { h1: g('.hero h1'), lede: g('.hero .lede'), kicker: g('.hero .kicker'), sectionProse: g('#arc .prose p') };
  });
  await p.close();
}

await capture('algebra', 'http://localhost:8765/elixir/algebra');     // AFTER (edited)
await capture('functional', 'http://localhost:8765/elixir/functional'); // BEFORE reference (unchanged)
await b.close();
console.log(JSON.stringify(out, null, 2));
