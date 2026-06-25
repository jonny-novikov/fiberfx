#!/usr/bin/env node
/**
 * Modern esbuild configuration for @codemoji/types
 * Uses esbuild 0.24+ with Node.js 22 target
 */

import * as esbuild from 'esbuild';

const buildConfig = {
  entryPoints: [
    // Main entry
    'src/index.ts',
    // Subpath exports (matching package.json exports)
    'src/dtos/index.ts',
    'src/types/index.ts'
  ],
  bundle: true,
  platform: 'node',
  target: 'node22',
  format: 'esm',
  outdir: 'dist',
  sourcemap: true,
  minify: false,

  // Externalize all node_modules (same as db package)
  packages: 'external',

  logLevel: 'info',
  color: true,
};

async function buildCode() {
  try {
    await esbuild.build(buildConfig);
    console.log('[DONE] Build completed successfully');
  } catch (error) {
    console.error('[ERROR] Build failed:', error);
    process.exit(1);
  }
}

buildCode();
