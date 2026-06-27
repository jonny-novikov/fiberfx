// visual/structure-diff.mjs — element-level structural drift (what a pixel diff misses).
//
//   node visual/structure-diff.mjs <screen> <storyId> [selector]
//   node visual/structure-diff.mjs codemojies screens-game-free--board figure
//
// compare.mjs/overlay.mjs answer "do the pixels match"; this answers "is each DESIGNED
// piece in the right PLACE at the right SIZE" — the drift a pixel diff drowns in font
// anti-aliasing. It reads figma/<screen>/manifest.json (the extracted figure bboxes, in
// the screen frame's CSS space, origin 0,0), screenshots nothing, and instead pulls every
// live DOM bounding box under [selector], maps each into the Figma coordinate space
// (made relative to the captured frame's origin, then scaled by figmaW / frameW — one
// uniform factor, both being portrait-phone), greedily matches figures ↔ live boxes by
// normalized bbox proximity, and prints the position/size deltas, largest first.
//
//   selector defaults to `figure` — the LIVE device pane of a drift-view story (the same
//   element shoot.mjs/drift.mjs capture). Pass a tighter selector (e.g. the inner content
//   div) to drop the device-bezel offset, or '#storybook-root' for a bare component story.
//
// Matching is greedy + exclusive (each figure and each live box used once); a figure whose
// best candidate is past STRUCT_MATCH_MAX (default 1.0, normalized) is logged UNMATCHED
// rather than force-paired. Reads the manifest only — never the bridge, never a PNG.
import { chromium } from 'playwright';
import http from 'http';
import { readFile } from 'fs/promises';
import { readFileSync, writeFileSync, existsSync, statSync } from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const PKG = path.dirname(path.dirname(fileURLToPath(import.meta.url)));
const ROOT = path.join(PKG, 'storybook-static');
const MIME = {
  '.html': 'text/html', '.js': 'text/javascript', '.mjs': 'text/javascript',
  '.css': 'text/css', '.png': 'image/png', '.jpg': 'image/jpeg', '.json': 'application/json',
  '.svg': 'image/svg+xml', '.woff': 'font/woff', '.woff2': 'font/woff2', '.ttf': 'font/ttf',
};

const screen = process.argv[2];
const storyId = process.argv[3];
const selector = process.argv[4] || 'figure';
if (!screen || !storyId) {
  console.error('usage: node visual/structure-diff.mjs <screen> <storyId> [selector]');
  process.exit(2);
}
const manifestPath = path.join(PKG, 'figma', screen, 'manifest.json');
if (!existsSync(manifestPath)) {
  console.error(`no manifest: ${manifestPath} — run \`pnpm extract <nodeId>\` for this screen first.`);
  process.exit(2);
}
if (!existsSync(ROOT)) {
  console.error('No storybook-static/ — run `pnpm build-storybook` first.');
  process.exit(2);
}
const matchMax = process.env.STRUCT_MATCH_MAX ? Number(process.env.STRUCT_MATCH_MAX) : 1.0;

const manifest = JSON.parse(readFileSync(manifestPath, 'utf8'));
const figures = (manifest.figures || []).filter((f) => f.w > 0 && f.h > 0);
if (figures.length === 0) {
  console.error('manifest has no sized figures.');
  process.exit(2);
}
// The Figma frame is the figures' own extent (origin 0,0 for a screen-relative export):
// width = widest figure, height = the furthest figure bottom. Internally consistent with
// the space the figures are expressed in — no dependence on the root render's export scale.
const figmaW = Math.max(...figures.map((f) => f.w));
const figmaH = Math.max(...figures.map((f) => f.y + f.h));

// --- serve storybook-static/ (so absolute /assets/* resolve), same as shoot.mjs ---
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

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 1000, height: 1600, deviceScaleFactor: 2 } });
await page.goto(`http://localhost:${port}/iframe.html?id=${storyId}&viewMode=story`, { waitUntil: 'networkidle' });
await page.waitForTimeout(500);

// Pull the frame rect + every meaningful descendant box, in viewport CSS px (document
// order, so the first occurrence of a shared box is the outermost/semantic container).
const live = await page.evaluate((sel) => {
  const frameEl = document.querySelector(sel);
  if (!frameEl) return { frame: null };
  const fr = frameEl.getBoundingClientRect();
  const seen = new Set();
  const boxes = [];
  for (const el of frameEl.querySelectorAll('*')) {
    const r = el.getBoundingClientRect();
    if (r.width < 6 || r.height < 6) continue; // skip hairlines / collapsed nodes
    const key = `${Math.round(r.x)},${Math.round(r.y)},${Math.round(r.width)},${Math.round(r.height)}`;
    if (seen.has(key)) continue; // dedupe wrapper chains sharing one box → keep the outer
    seen.add(key);
    boxes.push({
      tag: el.tagName.toLowerCase(),
      id: el.id || '',
      cls: (el.className && el.className.toString ? el.className.toString() : '').trim().split(/\s+/)[0] || '',
      text: (el.textContent || '').trim().replace(/\s+/g, ' ').slice(0, 24),
      x: r.x, y: r.y, w: r.width, h: r.height,
    });
  }
  return { frame: { x: fr.x, y: fr.y, w: fr.width, h: fr.height }, boxes };
}, selector);

await browser.close();
server.close();

if (!live.frame) {
  console.error(`selector "${selector}" not found in story ${storyId}`);
  process.exit(1);
}

// Map a live (viewport-space) box into Figma space: relative to the frame origin, then
// scaled by the single uniform factor figmaW / frameW.
const scale = figmaW / live.frame.w;
const mapped = live.boxes.map((b) => ({
  ...b,
  fx: (b.x - live.frame.x) * scale,
  fy: (b.y - live.frame.y) * scale,
  fw: b.w * scale,
  fh: b.h * scale,
}));

// Greedy + exclusive match. Score = sum of |center-delta| and |size-delta|, each axis
// normalized by the frame dimension (scale-free): 0 = perfect, larger = more drift.
const score = (f, m) => {
  const fcx = f.x + f.w / 2, fcy = f.y + f.h / 2;
  const mcx = m.fx + m.fw / 2, mcy = m.fy + m.fh / 2;
  return Math.abs(fcx - mcx) / figmaW + Math.abs(fcy - mcy) / figmaH
       + Math.abs(f.w - m.fw) / figmaW + Math.abs(f.h - m.fh) / figmaH;
};
const pairs = [];
figures.forEach((f, fi) => mapped.forEach((m, mi) => pairs.push({ fi, mi, s: score(f, m) })));
pairs.sort((a, b) => a.s - b.s);

const figMatch = new Array(figures.length).fill(null); // fi -> {mi, s}
const usedBox = new Set();
for (const p of pairs) {
  if (figMatch[p.fi] || usedBox.has(p.mi)) continue;
  figMatch[p.fi] = { mi: p.mi, s: p.s };
  usedBox.add(p.mi);
}

const r0 = (n) => Math.round(n);
const matched = [];
const unmatched = [];
figures.forEach((f, fi) => {
  const hit = figMatch[fi];
  if (!hit || hit.s > matchMax) {
    unmatched.push({ figure: f.name, type: f.type, box: `${r0(f.x)},${r0(f.y)} ${r0(f.w)}×${r0(f.h)}`, bestScore: hit ? +hit.s.toFixed(3) : null });
    return;
  }
  const m = mapped[hit.mi];
  const dx = r0(m.fx - f.x), dy = r0(m.fy - f.y); // live − figma, in Figma px
  const dw = r0(m.fw - f.w), dh = r0(m.fh - f.h);
  matched.push({
    figure: f.name, type: f.type,
    figPos: `${r0(f.x)},${r0(f.y)}`, figSize: `${r0(f.w)}×${r0(f.h)}`,
    'Δpos': `${dx >= 0 ? '+' : ''}${dx},${dy >= 0 ? '+' : ''}${dy}`,
    'Δsize': `${dw >= 0 ? '+' : ''}${dw},${dh >= 0 ? '+' : ''}${dh}`,
    drift: r0(Math.hypot(m.fx - f.x, m.fy - f.y)),
    matchedTo: `${m.tag}${m.id ? '#' + m.id : ''}${m.cls ? '.' + m.cls : ''}${m.text ? ' “' + m.text + '”' : ''}`.slice(0, 46),
    _s: +hit.s.toFixed(3),
  });
});
matched.sort((a, b) => b.drift - a.drift);

console.log(`\nstructure-diff  ${screen}  ↔  ${storyId}  (selector "${selector}")`);
console.log(`figma frame ${r0(figmaW)}×${r0(figmaH)} (figures extent)  ·  live frame ${r0(live.frame.w)}×${r0(live.frame.h)}  ·  scale ${scale.toFixed(3)}`);
console.log(`${figures.length} figures · ${mapped.length} live boxes · ${matched.length} matched · ${unmatched.length} unmatched\n`);

if (matched.length) {
  console.log('Matched figures — Δ in Figma px (live − figma), largest drift first:');
  console.table(matched.map(({ _s, ...row }) => row));
}
if (unmatched.length) {
  console.log('\nUnmatched figures (no live box within STRUCT_MATCH_MAX=' + matchMax + ' — likely missing, reflowed, or off-canvas in the export):');
  console.table(unmatched);
}

const outJson = `/tmp/cm-structure-${screen.replace(/[^\w.-]/g, '_')}.json`;
writeFileSync(outJson, JSON.stringify({
  screen, storyId, selector,
  figmaFrame: { w: figmaW, h: figmaH },
  liveFrame: live.frame, scale,
  matched, unmatched,
  liveBoxes: mapped.length,
}, null, 2));
console.log(`\nJSON dump → ${outJson}`);
