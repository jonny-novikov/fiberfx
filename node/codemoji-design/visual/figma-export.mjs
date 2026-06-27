// visual/figma-export.mjs — export ONE Figma node → an image, via the figma-local bridge.
//
//   node visual/figma-export.mjs <nodeId> [out.png] [format=PNG|SVG|JPG]
//   node visual/figma-export.mjs 709:38903 /tmp/figma-tabs.png
//
// The "capture the exported Figma" half of the drift loop. Pulls the master's pixels
// straight from the figma-local bridge — no API key, the same path bin/…extract uses
// (and the same egress the figma-local MCP proxies). Bytes flow bridge → here → disk,
// never through an agent's context. Pair with shoot.mjs (the live render) + compare.mjs.
import * as bridge from '../src/bridge.mjs';
import { writeFileSync } from 'fs';

const [, , nodeArg, outArg, fmtArg] = process.argv;
if (!nodeArg) {
  console.error('usage: node visual/figma-export.mjs <nodeId> [out.png] [format=PNG|SVG|JPG]');
  process.exit(2);
}
const format = (fmtArg || 'PNG').toUpperCase();
const ext = format === 'JPG' ? 'jpg' : format.toLowerCase();
const id = bridge.normId(nodeArg);
const out = outArg || `/tmp/figma-${id.replace(':', '-')}.${ext}`;

const h = await bridge.health().catch((e) => {
  console.error(`bridge ${bridge.BRIDGE_URL} unreachable: ${e.message}`);
  process.exit(1);
});
if (!h.connected) {
  console.error(`bridge ${bridge.BRIDGE_URL} reachable but no Figma plugin connected`);
  process.exit(1);
}

// export-node returns { nodeId, format, data: base64, w, h, byteLen } (bridge ADR-1).
const res = await bridge.exportNode(id, format);
if (!res?.data) {
  console.error(`export-node returned no data for ${id}`);
  process.exit(1);
}
writeFileSync(out, Buffer.from(res.data, 'base64'));
console.log(`figma ${id} → ${out}  (${res.w ?? '?'}×${res.h ?? '?'}, ${res.byteLen ?? '?'} bytes)`);
