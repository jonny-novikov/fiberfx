import { defineConfig } from "vitest/config";
import react from "@vitejs/plugin-react";
import { fileURLToPath } from "node:url";

// `@` → mercury-ui/src, so package tests resolve the same alias as the build.
const mercuryUiSrc = fileURLToPath(new URL("./packages/mercury-ui/src", import.meta.url));

// One root config, two projects (vitest `test.projects`):
//   • node   — Fastify / @codemojex/* tests, run in-process via app.inject()
//   • jsdom  — the Mercury React component tests (plain vitest/DOM assertions)
// The per-project `environment` split is what lets the Fastify tests run under
// `node` and the React tests under `jsdom` in one `pnpm test` run.
export default defineConfig({
  test: {
    projects: [
      {
        test: {
          name: "node",
          environment: "node",
          include: [
            "codemojex-node/apps/*/test/**/*.test.ts",
            "codemojex-node/packages/*/test/**/*.test.ts",
          ],
        },
      },
      {
        plugins: [react()],
        resolve: { alias: { "@": mercuryUiSrc } },
        test: {
          name: "jsdom",
          environment: "jsdom",
          globals: true,
          include: [
            "packages/*/test/**/*.test.{ts,tsx}",
            "packages/*/src/**/*.test.{ts,tsx}",
            "apps/*/test/**/*.test.{ts,tsx}",
          ],
        },
      },
    ],
  },
});
