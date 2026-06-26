#!/usr/bin/env node
// @codemoji/design — render the gameplay/manifest.json screens to gameplay/assets/.
//
// Reads ./manifest.json (the figma-id ↔ asset-filename contract), calls the
// figma-local bridge once per screen via the package's bridge wrapper, decodes
// the base64 PNG, and writes each to its manifest-named path. Image bytes flow
// bridge → here → disk; they never touch the agent's context (ADR-1).
//
// Usage:
//   node gameplay/render.mjs           # render every screen in manifest.screens
//   node gameplay/render.mjs <id>      # render one screen by figma id (e.g. 94:2974)
//
// Re-run any time the design or the manifest changes. Failures per-screen are
// reported but do not stop the run — mirrors get-batch-nodes semantics (ADR-3).

import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import * as bridge from '../src/bridge.mjs';

const here = dirname(fileURLToPath(import.meta.url));
const manifestPath = join(here, 'manifest.json');
const manifest = JSON.parse(readFileSync(manifestPath, 'utf8'));

const only = process.argv[2];
const targets = only
  ? manifest.screens.filter((s) => s.figma_id === only || bridge.normId(s.figma_id) === bridge.normId(only))
  : manifest.screens;

if (!targets.length) {
  console.error(`no screens matched (asked for "${only}"); manifest has ${manifest.screens.length}`);
  process.exit(2);
}

const t0 = Date.now();
console.log(`rendering ${targets.length}/${manifest.screens.length} screen(s) → ${resolve(here, 'assets')}/`);

const results = [];
let okCount = 0;
let errCount = 0;
for (const s of targets) {
  const outPath = join(here, s.asset);
  mkdirSync(dirname(outPath), { recursive: true });
  try {
    const t = Date.now();
    const res = await bridge.exportNode(s.figma_id, 'PNG');
    const buf = Buffer.from(res.data, 'base64');
    writeFileSync(outPath, buf);
    const ms = Date.now() - t;
    okCount++;
    console.log(`  ok   ${s.figma_id.padEnd(14)} → ${s.asset}  (${Math.round(buf.length / 1024)} KB, ${res.w}×${res.h}, ${ms}ms)`);
    results.push({ id: s.figma_id, asset: s.asset, ok: true, kb: Math.round(buf.length / 1024), w: res.w, h: res.h, ms });
  } catch (e) {
    errCount++;
    console.error(`  fail ${s.figma_id.padEnd(14)} → ${s.asset}: ${e.message || e}`);
    results.push({ id: s.figma_id, asset: s.asset, ok: false, error: String(e.message || e) });
  }
}

const dt = ((Date.now() - t0) / 1000).toFixed(1);
console.log(`\ndone: ${okCount} ok, ${errCount} fail in ${dt}s`);
process.exit(errCount === 0 ? 0 : 1);
