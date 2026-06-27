// visual/figma-export.mjs — export ONE Figma node → an image, via the figma-local bridge.
//
//   node visual/figma-export.mjs <nodeId> [out.png] [format=PNG|SVG|JPG] [scale=2]
//   node visual/figma-export.mjs 709:38903 /tmp/figma-tabs.png        # @2x (default)
//   node visual/figma-export.mjs 709:38903 /tmp/figma-tabs.png PNG 1  # explicit 1×
//
// The "capture the exported Figma" half of the drift loop. Pulls the master's pixels
// straight from the figma-local bridge — no API key, the same path bin/…extract uses
// (and the same egress the figma-local MCP proxies). Bytes flow bridge → here → disk,
// never through an agent's context. Pair with shoot.mjs (the live render) + compare.mjs.
//
// Scale defaults to 2 (Retina) for fidelity; pass a trailing 1 to force 1×. When the
// default output filename is used at @2x it is suffixed `@2x`. NOTE: scale>1 only
// produces a larger raster once the Windows Figma plugin has been reloaded (older
// deployed plugins ignore the scale param and silently return 1×).
import * as bridge from '../src/bridge.mjs';
import { writeFileSync } from 'fs';

const [, , nodeArg, outArg, fmtArg, scaleArg] = process.argv;
if (!nodeArg) {
  console.error('usage: node visual/figma-export.mjs <nodeId> [out.png] [format=PNG|SVG|JPG] [scale=2]');
  process.exit(2);
}
const format = (fmtArg || 'PNG').toUpperCase();
const scale = scaleArg === undefined ? 2 : (Number(scaleArg) || 1); // Retina default
const ext = format === 'JPG' ? 'jpg' : format.toLowerCase();
const id = bridge.normId(nodeArg);
// Only suffix @2x on the AUTO-generated default name — an explicit out path is left as the caller wrote it.
const suffix = scale === 2 ? '@2x' : '';
const out = outArg || `/tmp/figma-${id.replace(':', '-')}${suffix}.${ext}`;

const h = await bridge.health().catch((e) => {
  console.error(`bridge ${bridge.BRIDGE_URL} unreachable: ${e.message}`);
  process.exit(1);
});
if (!h.connected) {
  console.error(`bridge ${bridge.BRIDGE_URL} reachable but no Figma plugin connected`);
  process.exit(1);
}

// export-node returns { nodeId, format, scale, data: base64, w, h, byteLen } (bridge ADR-1).
const res = await bridge.exportNode(id, format, scale);
if (!res?.data) {
  console.error(`export-node returned no data for ${id}`);
  process.exit(1);
}
writeFileSync(out, Buffer.from(res.data, 'base64'));
// res.scale is what the plugin honored — if it comes back 1 while we asked for 2, the plugin needs a reload.
const got = res.scale ?? 1;
const note = scale > 1 && got < scale ? `  [asked @${scale}x, plugin returned @${got}x — reload the Figma plugin]` : '';
console.log(`figma ${id} → ${out}  (${res.w ?? '?'}×${res.h ?? '?'} @${got}x, ${res.byteLen ?? '?'} bytes)${note}`);
