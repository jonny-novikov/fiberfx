import { defineConfig } from 'vitest/config';
import { resolve } from 'path';
import { createRequire } from 'module';

const { version } = createRequire(import.meta.url)('./package.json');

export default defineConfig({
  define: {
    // Build-time constant the LiveView client reads via LiveSocket.version().
    // The production build injects it as an esbuild `define`; mirror that here
    // so the suite exercises the real version-negotiation path.
    LV_VSN: JSON.stringify(version),
  },
  resolve: {
    alias: {
      '@': resolve(__dirname, './src'),
      phoenix_live_view: resolve(__dirname, './src'),
    },
  },
  test: {
    environment: 'jsdom',
    // Match the upstream test runner's `testURL` default (http://localhost/, no
    // port) so tests that assert document-relative static URLs (_track_static)
    // resolve exactly as they did under the original jsdom test environment.
    environmentOptions: { jsdom: { url: 'http://localhost/' } },
    globals: true,
    setupFiles: ['./test/setup.ts'],
    include: ['test/**/*.test.ts', 'test/**/*_test.ts', 'src/**/*.spec.ts'],
  },
});
