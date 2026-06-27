// visual/reexport-references.mjs — re-export a screen's reference PNGs at Retina @2x.
//
//   node visual/reexport-references.mjs <screen>          # e.g. codemojies
//   node visual/reexport-references.mjs codemojies 1      # force 1× (revert)
//
// Reads figma/<screen>/manifest.json (the flattened figure list), re-exports every
// figure that has a `render` file at @2x via the figma-local bridge, and REPLACES the
// PNG in figma/<screen>/reference/ in place — same filename, doubled raster. Idempotent:
// re-running re-fetches the same @2x bytes and overwrites again (no accumulation, no
// duplicate files). Prints a per-file old→new dimension report so you can see the bump.
//
// NOTE: @2x only takes effect once the Windows Figma plugin has been reloaded. Until
// then the plugin ignores the scale param and returns 1× — this script will then
// report "no change" for every file, which PROVES the reload is the remaining step.
import * as bridge from '../src/bridge.mjs';
import { readFileSync, writeFileSync, existsSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const PKG_ROOT = dirname(dirname(fileURLToPath(import.meta.url)));

// PNG dimensions from the IHDR chunk (big-endian uint32 at byte 16 = width, 20 = height).
// Zero-dep so we never touch package.json. Returns null for a non-PNG / truncated file.
function pngSize(buf) {
  if (!buf || buf.length < 24) return null;
  // PNG signature: 89 50 4E 47 0D 0A 1A 0A
  if (buf[0] !== 0x89 || buf[1] !== 0x50 || buf[2] !== 0x4e || buf[3] !== 0x47) return null;
  return { w: buf.readUInt32BE(16), h: buf.readUInt32BE(20) };
}
const dim = (s) => (s ? `${s.w}×${s.h}` : '?×?');

async function main() {
  const [, , screenArg, scaleArg] = process.argv;
  if (!screenArg) {
    console.error('usage: node visual/reexport-references.mjs <screen> [scale=2]   (e.g. codemojies)');
    process.exit(2);
  }
  const scale = scaleArg === undefined ? 2 : (Number(scaleArg) || 1);
  const screenDir = join(PKG_ROOT, 'figma', screenArg);
  const manifestPath = join(screenDir, 'manifest.json');
  const refDir = join(screenDir, 'reference');
  if (!existsSync(manifestPath)) {
    console.error(`no manifest at ${manifestPath} — is "${screenArg}" an extracted screen under figma/?`);
    process.exit(1);
  }

  const manifest = JSON.parse(readFileSync(manifestPath, 'utf8'));
  const figures = Array.isArray(manifest.figures) ? manifest.figures.filter((f) => f && f.render) : [];
  if (!figures.length) {
    console.error(`manifest ${manifestPath} lists no figures with a render filename — nothing to re-export.`);
    process.exit(1);
  }

  // Fail fast (and clearly) if the bridge / plugin is not reachable, like the sibling scripts do.
  const h = await bridge.health().catch((e) => {
    console.error(`bridge ${bridge.BRIDGE_URL} unreachable: ${e.message}`);
    process.exit(1);
  });
  if (!h.connected) {
    console.error(`bridge ${bridge.BRIDGE_URL} reachable but no Figma plugin connected`);
    process.exit(1);
  }

  console.log(`re-exporting ${figures.length} figures @${scale}x for "${screenArg}" -> ${refDir}\n`);
  let ok = 0, failed = 0, unchanged = 0;
  for (const f of figures) {
    const dest = join(refDir, f.render);
    const before = existsSync(dest) ? pngSize(readFileSync(dest)) : null;
    try {
      // f.id carries the ":" form (incl. instance ids like "I21:382;21:241"); normId leaves those untouched.
      const res = await bridge.exportNode(f.id, 'PNG', scale);
      if (!res?.data) throw new Error('export-node returned no data');
      const buf = Buffer.from(res.data, 'base64');
      writeFileSync(dest, buf);
      const after = pngSize(buf);
      const same = before && after && before.w === after.w && before.h === after.h;
      if (same) unchanged++;
      ok++;
      console.log(
        `  ${same ? '=' : '↑'} ${f.render.padEnd(40)} ${dim(before)} → ${dim(after)}` +
        `  (plugin @${res.scale ?? '?'}x, ${Math.round(buf.length / 1024)} KB)`
      );
    } catch (e) {
      failed++;
      console.log(`  ✗ ${f.render.padEnd(40)} ${dim(before)} → FAILED: ${e.message}`);
    }
  }

  console.log(`\ndone: ${ok}/${figures.length} re-exported @${scale}x (${failed} failed) -> ${refDir}`);
  if (scale > 1 && ok > 0 && unchanged === ok) {
    console.log(
      `WARNING: every file came back unchanged at @${scale}x — the deployed Figma plugin is ignoring the\n` +
      `scale param. Reload the plugin on the Windows Figma machine, then re-run this command.`
    );
  }
  process.exit(failed > 0 ? 1 : 0);
}

main();
