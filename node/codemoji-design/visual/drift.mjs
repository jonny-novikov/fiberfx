// visual/drift.mjs — one-command Figma-vs-live drift check.
//
//   node visual/drift.mjs <figmaNodeId> <storyId> [selector] [outDir]
//   node visual/drift.mjs 709:38903 board-board-tabs--leaderboard-active '#storybook-root' /tmp/tabs-drift
//
// Composes the three primitives end to end:
//   1. figma-export.mjs  — the master's pixels from the bridge        → <outDir>/figma.png
//   2. shoot.mjs         — the live Storybook render of the story      → <outDir>/live.png
//   3. compare.mjs       — pixel diff + side-by-side composite         → <outDir>/diff.png(.sxs.png)
//
// `pnpm build-storybook` must have produced storybook-static/ first (shoot serves it).
// The compare step's non-zero exit (>2% mismatch) is EXPECTED for a Figma-vs-live
// pair (font rendering differs) and does not fail the bundle — read the .sxs.png.
import { spawnSync } from 'child_process';
import { mkdirSync } from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const PKG = path.dirname(HERE);
const [, , node, story, selector = '#storybook-root', outDir = '/tmp/cm-drift'] = process.argv;
if (!node || !story) {
  console.error('usage: node visual/drift.mjs <figmaNodeId> <storyId> [selector] [outDir]');
  process.exit(2);
}
mkdirSync(outDir, { recursive: true });
const figma = path.join(outDir, 'figma.png');
const live = path.join(outDir, 'live.png');
const diff = path.join(outDir, 'diff.png');

// Run a step; abort the bundle if a CAPTURE step fails (compare is allowed to "fail").
const step = (label, args, { allowFail = false } = {}) => {
  console.log(`\n— ${label} —`);
  const r = spawnSync('node', args, { stdio: 'inherit', cwd: PKG });
  if (!allowFail && r.status !== 0) {
    console.error(`drift: ${label} failed (exit ${r.status}) — aborting.`);
    process.exit(r.status || 1);
  }
};

step('figma-export', [path.join(HERE, 'figma-export.mjs'), node, figma]);
step('shoot (live)', [path.join(HERE, 'shoot.mjs'), story, selector, live]);
step('compare', [path.join(HERE, 'compare.mjs'), figma, live, diff], { allowFail: true });

console.log(`\ndrift bundle → ${outDir}`);
console.log('  figma.png · live.png · diff.png · diff.sxs.png (open the side-by-side)');
