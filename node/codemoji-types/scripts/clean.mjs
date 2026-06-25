#!/usr/bin/env node
/**
 * Clean build artifacts for @codemoji/types
 */

import { rmSync, existsSync } from 'node:fs';

const artifacts = ['dist'];

console.log('[CLEAN] Cleaning build artifacts...');

for (const path of artifacts) {
  if (existsSync(path)) {
    rmSync(path, { recursive: true, force: true });
    console.log(`   - Removed ${path}`);
  }
}

console.log('[DONE] Clean complete');
