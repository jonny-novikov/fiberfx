// visual/overlay.mjs — onion-skin + difference-blend overlay (the misalignment spotter).
//
//   node visual/overlay.mjs <figma.png> <live.png> [outPrefix]
//   node visual/overlay.mjs /tmp/figma-tabs.png /tmp/live-tabs.png /tmp/tabs
//
// compare.mjs gives you a % and a side-by-side; this gives you the two artifacts that
// make a SHIFT obvious to the eye. Both inputs are resized to a common width first (a
// live shot is deviceScaleFactor-2 at a 1000px viewport — a 375px card is a 750px PNG —
// while a Figma 1× export is the node's CSS size, so they must share a width before they
// can sit on top of each other), then:
//   <prefix>.overlay.png      — Figma opaque + live at 50% alpha over white. Edges that
//                               line up read as ONE edge; a shift reads as a ghosted
//                               double edge — you SEE the offset and its direction.
//   <prefix>.diff-blend.png   — per-channel |figma − live| (the Photoshop "Difference"
//                               blend). Aligned pixels go black; anything that moved or
//                               changed GLOWS. Reads structure, not a heat-map of AA.
//
// Resizing + compositing run in a headless Playwright canvas (ctx.drawImage scaled +
// getImageData) — no resampler dep added, same Chromium the other tools already use.
// Both inputs are cropped to their common top-left height (compare.mjs's convention) so
// a tall live scroll and a shorter Figma node still overlay from the same origin.
import { chromium } from 'playwright';
import { readFileSync, writeFileSync } from 'fs';
import { existsSync } from 'fs';

const [, , figmaPath, livePath, outArg] = process.argv;
if (!figmaPath || !livePath) {
  console.error('usage: node visual/overlay.mjs <figma.png> <live.png> [outPrefix]');
  process.exit(2);
}
for (const p of [figmaPath, livePath]) {
  if (!existsSync(p)) { console.error(`no such file: ${p}`); process.exit(2); }
}
const prefix = outArg || livePath.replace(/\.png$/i, '') || '/tmp/cm-overlay';

const toDataUrl = (p) => `data:image/png;base64,${readFileSync(p).toString('base64')}`;

const browser = await chromium.launch();
const page = await browser.newPage();
// Everything happens in-page: decode both PNGs, scale to a common width, then emit the
// onion-skin and the difference-blend as base64 PNGs handed back to Node to write.
const result = await page.evaluate(async ({ figUrl, liveUrl }) => {
  const load = (url) => new Promise((res, rej) => {
    const img = new Image();
    img.onload = () => res(img);
    img.onerror = () => rej(new Error('image decode failed'));
    img.src = url;
  });
  const [fig, live] = await Promise.all([load(figUrl), load(liveUrl)]);

  // Common width = the smaller natural width (downscale the bigger — never upscale, which
  // would only add blur). Each image keeps its aspect at that width; the shared canvas is
  // cropped to the smaller of the two scaled heights (common top-left).
  const commonW = Math.min(fig.naturalWidth, live.naturalWidth);
  const sh = (img) => Math.round(img.naturalHeight * (commonW / img.naturalWidth));
  const figH = sh(fig), liveH = sh(live);
  const commonH = Math.min(figH, liveH);

  const canvas = () => Object.assign(document.createElement('canvas'), { width: commonW, height: commonH });
  // Draw one image scaled-to-commonW onto a commonW×commonH canvas, return its RGBA.
  const rgba = (img, scaledH) => {
    const x = canvas().getContext('2d');
    x.drawImage(img, 0, 0, commonW, scaledH); // top-left; anything below commonH is clipped
    return x.getImageData(0, 0, commonW, commonH);
  };
  const figPx = rgba(fig, figH);
  const livePx = rgba(live, liveH);

  // (a) onion-skin: white base, Figma opaque, live ghosted at 50%.
  const oc = canvas();
  const ox = oc.getContext('2d');
  ox.fillStyle = '#fff';
  ox.fillRect(0, 0, commonW, commonH);
  ox.drawImage(fig, 0, 0, commonW, figH);
  ox.globalAlpha = 0.5;
  ox.drawImage(live, 0, 0, commonW, liveH);
  ox.globalAlpha = 1;

  // (b) difference-blend: per-channel absolute difference, opaque. 0 (aligned) = black.
  const dc = canvas();
  const dx = dc.getContext('2d');
  const diff = dx.createImageData(commonW, commonH);
  const a = figPx.data, b = livePx.data, d = diff.data;
  for (let i = 0; i < d.length; i += 4) {
    d[i] = Math.abs(a[i] - b[i]);
    d[i + 1] = Math.abs(a[i + 1] - b[i + 1]);
    d[i + 2] = Math.abs(a[i + 2] - b[i + 2]);
    d[i + 3] = 255;
  }
  dx.putImageData(diff, 0, 0);

  // toDataURL goes through the same readback that getImageData above already proved works
  // here (OffscreenCanvas.convertToBlob does not, in headless Chromium). Strip the prefix.
  const b64 = (c) => c.toDataURL('image/png').split(',')[1];
  return {
    overlay: b64(oc),
    diffBlend: b64(dc),
    commonW, commonH,
    fig: { w: fig.naturalWidth, h: fig.naturalHeight },
    live: { w: live.naturalWidth, h: live.naturalHeight },
  };
}, { figUrl: toDataUrl(figmaPath), liveUrl: toDataUrl(livePath) });

await browser.close();

const overlayPath = `${prefix}.overlay.png`;
const diffPath = `${prefix}.diff-blend.png`;
writeFileSync(overlayPath, Buffer.from(result.overlay, 'base64'));
writeFileSync(diffPath, Buffer.from(result.diffBlend, 'base64'));

console.log(`figma ${result.fig.w}×${result.fig.h}  live ${result.live.w}×${result.live.h}`);
console.log(`common ${result.commonW}×${result.commonH} (resized to a shared width)`);
console.log(`onion-skin     → ${overlayPath}`);
console.log(`difference-blend → ${diffPath}`);
