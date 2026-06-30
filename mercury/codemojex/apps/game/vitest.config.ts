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
    alias: { "@": r("./src") },
  },
  test: {
    environment: "jsdom",
    globals: true,
    setupFiles: [r("./test/setup.ts")],
    include: ["src/**/*.test.{ts,tsx}"],
    exclude: ["packages/**", "node_modules/**", "dist/**", "../priv/**"],
  },
});
