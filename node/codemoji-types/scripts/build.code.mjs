#!/usr/bin/env node
/**
 * Modern esbuild configuration for codemoji-types
 * Uses esbuild 0.24+ with Node.js 22 target
 * Matches the pattern used by codemoji-db and codemoji-backend
 */

import * as esbuild from 'esbuild';

const buildConfig = {
  entryPoints: [
    // Main entry
    'src/index.ts',
    // Subpath exports (matching package.json exports)
    'src/ids/index.ts',
    'src/constants/index.ts',
    'src/schemas/index.ts',
    'src/dtos/index.ts',
    'src/events/index.ts',
    'src/state/index.ts',
    'src/commands/index.ts',
    'src/auth/index.ts',
    'src/enums/index.ts',
    'src/branded.ts',
    'src/utils/index.ts',
    'src/utils/type-utils.ts',
    'src/utils/codemoji.utils.ts',
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
