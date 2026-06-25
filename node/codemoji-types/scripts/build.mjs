#!/usr/bin/env node
/**
 * Build orchestrator for codemoji-types
 * Runs: clean -> build:code -> build:types
 */

import { execSync } from 'node:child_process';

const steps = ['clean', 'build:code', 'build:types'];

console.log('[BUILD] Building @fireheadz/codemoji-types\n');

for (const step of steps) {
  execSync(`pnpm run ${step}`, { stdio: 'inherit' });
}

console.log('\n[DONE] Build complete');
