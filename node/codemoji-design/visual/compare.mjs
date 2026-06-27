// visual/compare.mjs — pixel-diff two PNGs (image comparison / visual regression).
//
//   node visual/compare.mjs <a.png> <b.png> [diff.png] [threshold]
//
// Crops both to their common top-left WxH (so a Figma reference and a live shot of
// slightly different size still compare), runs pixelmatch, writes a highlighted diff
// PNG, AND a side-by-side composite (<diff>.sxs.png: a | b at native size). For a
// Figma-vs-live check the side-by-side is the eyeball artifact — a raw pixel-diff is
// noisy across font anti-aliasing — while the % gates a same-engine baseline. Exit
// code is non-zero when the mismatch exceeds 2% so it can gate CI / a visual run.
import { PNG } from 'pngjs';
import pixelmatch from 'pixelmatch';
import { readFileSync, writeFileSync } from 'fs';

const [, , aPath, bPath, diffPath = '/tmp/cm-diff.png', thresholdArg] = process.argv;
if (!aPath || !bPath) {
  console.error('usage: node visual/compare.mjs <a.png> <b.png> [diff.png] [threshold]');
  process.exit(2);
}
const threshold = thresholdArg ? Number(thresholdArg) : 0.1;

const a = PNG.sync.read(readFileSync(aPath));
const b = PNG.sync.read(readFileSync(bPath));
const w = Math.min(a.width, b.width);
const h = Math.min(a.height, b.height);

// crop a source PNG to the common top-left w×h into a fresh RGBA buffer
const crop = (src) => {
  const dst = Buffer.alloc(w * h * 4);
  for (let y = 0; y < h; y++) {
    src.data.copy(dst, y * w * 4, (y * src.width) * 4, (y * src.width + w) * 4);
  }
  return dst;
};

const aBuf = crop(a);
const bBuf = crop(b);
const diff = new PNG({ width: w, height: h });
const mismatch = pixelmatch(aBuf, bBuf, diff.data, w, h, { threshold });
writeFileSync(diffPath, PNG.sync.write(diff));

// Side-by-side composite: a | b at native size on a white canvas, a GAP-px gutter
// between. The diff highlights pixel deltas; this lets the two be read together.
const GAP = 16;
const sxsW = a.width + GAP + b.width;
const sxsH = Math.max(a.height, b.height);
const sxs = new PNG({ width: sxsW, height: sxsH });
sxs.data.fill(0xff); // opaque white
const blit = (src, dx) => {
  for (let y = 0; y < src.height; y++) {
    for (let x = 0; x < src.width; x++) {
      const s = (y * src.width + x) * 4;
      const d = (y * sxsW + dx + x) * 4;
      src.data.copy(sxs.data, d, s, s + 4);
    }
  }
};
blit(a, 0);
blit(b, a.width + GAP);
const sxsPath = diffPath.replace(/\.png$/i, '') + '.sxs.png';
writeFileSync(sxsPath, PNG.sync.write(sxs));

const pct = (mismatch / (w * h)) * 100;
console.log(`compared ${w}×${h}  (a:${a.width}×${a.height}  b:${b.width}×${b.height})`);
console.log(`mismatch: ${mismatch} px = ${pct.toFixed(2)}%  → ${diffPath}`);
console.log(`side-by-side → ${sxsPath}`);
process.exit(pct > 2 ? 1 : 0);
