// visual/compare.mjs — pixel-diff two PNGs (image comparison / visual regression).
//
//   node visual/compare.mjs <a.png> <b.png> [diff.png] [threshold]
//
// Crops both to their common top-left WxH (so a Figma reference and a live shot of
// slightly different size still compare), runs pixelmatch, writes a highlighted diff
// PNG, and prints the mismatched-pixel count + percentage. Exit code is non-zero when
// the mismatch exceeds 2% so it can gate CI / a visual test run.
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

const pct = (mismatch / (w * h)) * 100;
console.log(`compared ${w}×${h}  (a:${a.width}×${a.height}  b:${b.width}×${b.height})`);
console.log(`mismatch: ${mismatch} px = ${pct.toFixed(2)}%  → ${diffPath}`);
process.exit(pct > 2 ? 1 : 0);
