import { defineConfig } from "vitest/config";
import react from "@vitejs/plugin-react";
import { fileURLToPath } from "node:url";

// Vitest config for the @codemojex/edge game island. Separate from vite.config.ts (the
// production bundler) so the test run never touches the rollup library build. The `@`
// alias and the React JSX transform mirror the bundler; the run is scoped to this
// package's own src tests — the vendored Phoenix packages under packages/* keep their
// own configs and are explicitly excluded here so a root run can't pull them in.
const r = (p: string) => fileURLToPath(new URL(p, import.meta.url));

export default defineConfig({
  plugins: [react()],
  resolve: {
    // Mirror the bundler alias so the model test resolves `@mercury/effector` from source
    // (the game carries no `@mercury/*` node_modules entry — it is self-contained).
    alias: {
      "@": r("./src"),
      "@mercury/effector": r("../../../packages/mercury-effector/src/index.ts"),
    },
    // Single Effector copy across the aliased channel plug and the island's own model —
    // otherwise `sample` cannot connect units minted by two physical installs.
    dedupe: ["effector", "effector-react"],
  },
  test: {
    environment: "jsdom",
    globals: true,
    setupFiles: [r("./test/setup.ts")],
    include: ["src/**/*.test.{ts,tsx}"],
    exclude: ["packages/**", "node_modules/**", "dist/**", "../priv/**"],
  },
});
