import { defineConfig } from "vitest/config";

// Vitest config for @codemojex/liveview-boot. Kept separate from vite.config.ts (the
// rollup library bundler that emits the shipped app.js) so a test run never touches the
// lib build. jsdom supplies document/window for app.ts's module-load bootstrap
// (new LiveSocket(...).connect() + window.liveSocket) — inert here because the tests
// vi.mock both @echo/* client packages. The run is scoped to this package's own src
// tests; the __fixtures__ modules carry no `.test.` in their name so they are loaded
// (dynamic-imported by the GameIsland mount test) but never collected as suites.
export default defineConfig({
  test: {
    environment: "jsdom",
    include: ["src/**/*.test.ts"],
    exclude: ["node_modules/**", "dist/**"],
  },
});
