// visual/shoot.mjs — screenshot a Storybook story from the built storybook-static/.
//
// Serves storybook-static/ on an ephemeral port (so absolute /assets/* URLs
// resolve), opens the story's iframe in headless Chromium, and screenshots the
// target element to a PNG you can eyeball or feed to compare.mjs.
//
//   pnpm build-storybook                 # produce storybook-static/ first
//   node visual/shoot.mjs <storyId> [selector] [outPath]
//   node visual/shoot.mjs screens-rooms-lobby--lobby figure /tmp/lobby-live.png
//
// Default selector "figure" = the first device frame (the LIVE pane of a drift view).
// Use "#storybook-root" to capture a whole story (e.g. a single component).
import { chromium } from 'playwright';
import http from 'http';
import { readFile } from 'fs/promises';
import { existsSync, statSync } from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const PKG = path.dirname(path.dirname(fileURLToPath(import.meta.url)));
const ROOT = path.join(PKG, 'storybook-static');
const MIME = {
  '.html': 'text/html', '.js': 'text/javascript', '.mjs': 'text/javascript',
  '.css': 'text/css', '.png': 'image/png', '.jpg': 'image/jpeg', '.json': 'application/json',
  '.svg': 'image/svg+xml', '.woff': 'font/woff', '.woff2': 'font/woff2', '.ttf': 'font/ttf',
};

if (!existsSync(ROOT)) {
  console.error('No storybook-static/ — run `pnpm build-storybook` first.');
  process.exit(2);
}

const server = http.createServer(async (req, res) => {
  let p = decodeURIComponent((req.url || '/').split('?')[0]);
  if (p === '/') p = '/index.html';
  const fp = path.join(ROOT, p);
  try {
    if (existsSync(fp) && statSync(fp).isFile()) {
      res.writeHead(200, { 'content-type': MIME[path.extname(fp)] || 'application/octet-stream' });
      res.end(await readFile(fp));
      return;
    }
  } catch {}
  res.writeHead(404);
  res.end('not found');
});
await new Promise((r) => server.listen(0, r));
const port = server.address().port;

const id = process.argv[2] || 'lobby-nav-phone-panel--default';
const selector = process.argv[3] || 'figure';
const out = process.argv[4] || `/tmp/cmshot-${id}.png`;

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 1000, height: 1600, deviceScaleFactor: 2 } });
await page.goto(`http://localhost:${port}/iframe.html?id=${id}&viewMode=story`, { waitUntil: 'networkidle' });
await page.waitForTimeout(500);
const el = page.locator(selector).first();
if ((await el.count()) === 0) {
  console.error(`selector "${selector}" not found in story ${id}`);
  process.exit(1);
}
// CLIP_H=<px> captures only the top N px of the element (useful for tall screens —
// the nav region — without a 3500px-tall shot); otherwise the whole element.
const clipH = process.env.CLIP_H ? Number(process.env.CLIP_H) : 0;
if (clipH > 0) {
  const box = await el.boundingBox();
  await page.screenshot({
    path: out,
    clip: { x: box.x, y: box.y, width: box.width, height: Math.min(box.height, clipH) },
  });
} else {
  await el.screenshot({ path: out });
}
console.log('shot →', out);
await browser.close();
server.close();
