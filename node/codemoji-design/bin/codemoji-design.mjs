#!/usr/bin/env node
// @codemoji/design — extraction + theme CLI.
//   node bin/codemoji-design.mjs doctor             probe bridge + action surface
//   node bin/codemoji-design.mjs extract [nodeId]   extract a screen (default: current selection)
//   node bin/codemoji-design.mjs sortout <dir>      re-run sort on an existing extraction dir
//   node bin/codemoji-design.mjs theme              regenerate dist/theme.css from tokens (offline)
import { mkdirSync, writeFileSync, readFileSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';
import * as bridge from '../src/bridge.mjs';
import { boundedWalk, renderNodes, renderTargets, slug } from '../src/extract.mjs';
import { buildManifest, specMarkdown, tokensMarkdown } from '../src/sortout.mjs';
import { writeTheme } from '../src/theme.mjs';

const PKG_ROOT = dirname(dirname(fileURLToPath(import.meta.url)));
const FIGMA_DIR = join(PKG_ROOT, 'figma');

async function doctor() {
  const h = await bridge.health();
  console.log(`bridge ${bridge.BRIDGE_URL} ->`, JSON.stringify(h));
  console.log(`LIVE:     ${bridge.ACTION_SURFACE.live.join(', ')}`);
  for (const a of bridge.ACTION_SURFACE.dead) {
    try { await bridge.request(a, { nodeIds: ['0:0'] }); console.log(`  ${a}: responded (NOT dead?)`); }
    catch (e) { console.log(`  ${a}: ${e.message}`); }
  }
  console.log(`PROPOSED: ${bridge.ACTION_SURFACE.proposed.join(', ')}  (not yet backed by the plugin)`);
}

async function extract(nodeId) {
  const h = await bridge.health();
  if (!h.connected) throw new Error('bridge reachable but no Figma plugin connected');
  let id = nodeId ? bridge.normId(nodeId) : null;
  let name = null;
  if (!id) {
    const sel = await bridge.getSelection();           // Fork 5 / E2: selection-anchored default
    if (!sel || !sel.length) throw new Error('no nodeId given and nothing selected in Figma');
    id = sel[0].id; name = sel[0].name;
    console.log(`no nodeId -> current selection: ${id} "${name}"`);
  } else {
    name = (await bridge.getNode(id)).name;
  }
  const dir = join(FIGMA_DIR, slug(name).toLowerCase());
  mkdirSync(join(dir, 'structure'), { recursive: true });

  console.log(`walking ${id} "${name}" ...`);
  const { nodes, imageAssets, calls } = await boundedWalk(id, { depth: 3 });
  writeFileSync(join(dir, 'structure', 'summary.json'), JSON.stringify({ screen: id, nodes }, null, 2));

  const targets = renderTargets(nodes);
  console.log(`rendering ${targets.length} figures ...`);
  const renders = await renderNodes(targets, join(dir, 'reference'));
  writeFileSync(join(dir, 'structure', 'renders.json'), JSON.stringify(renders, null, 2));

  const manifest = buildManifest({ screen: { id, name }, nodes, renders, imageAssets, source: bridge.BRIDGE_URL, stamp: new Date().toISOString() });
  writeFileSync(join(dir, 'manifest.json'), JSON.stringify(manifest, null, 2));
  writeFileSync(join(dir, 'spec.md'), specMarkdown(manifest, nodes));
  writeFileSync(join(dir, 'tokens.md'), tokensMarkdown(nodes));

  const ok = renders.filter((r) => !r.error).length;
  console.log(`done: ${nodes.length} nodes (${calls} bridge calls), ${ok}/${renders.length} renders -> ${dir}`);
  if (renders.some((r) => r.error)) console.log('render errors:', JSON.stringify(renders.filter((r) => r.error).slice(0, 6)));
}

async function sortout(dir) {
  if (!dir) throw new Error('usage: sortout <extraction-dir>');
  const nodes = JSON.parse(readFileSync(join(dir, 'structure', 'summary.json'), 'utf8')).nodes;
  const renders = JSON.parse(readFileSync(join(dir, 'structure', 'renders.json'), 'utf8'));
  const screen = { id: nodes[0]?.id, name: dir.split('/').filter(Boolean).pop() };
  const manifest = buildManifest({ screen, nodes, renders, imageAssets: [], source: bridge.BRIDGE_URL, stamp: new Date().toISOString() });
  writeFileSync(join(dir, 'manifest.json'), JSON.stringify(manifest, null, 2));
  writeFileSync(join(dir, 'spec.md'), specMarkdown(manifest, nodes));
  writeFileSync(join(dir, 'tokens.md'), tokensMarkdown(nodes));
  console.log(`re-sorted ${dir}`);
}

// theme — regenerate dist/theme.css from tokens/tokens.mjs (offline, no bridge).
function theme() {
  const out = writeTheme();
  console.log(`wrote ${out}`);
  return Promise.resolve();
}

const [cmd, arg] = process.argv.slice(2);
const cmds = { doctor, extract: () => extract(arg), sortout: () => sortout(arg), theme };
const run = cmds[cmd || 'extract'];
if (!run) { console.error('usage: codemoji-design <doctor | extract [nodeId] | sortout <dir> | theme>'); process.exit(1); }
run().catch((e) => { console.error('ERROR:', e.message); process.exit(1); });
