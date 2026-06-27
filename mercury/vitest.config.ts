import { defineConfig } from "vitest/config";
import react from "@vitejs/plugin-react";

// One root config, two projects (vitest 3 `test.projects`):
//   • node   — Fastify / @codemojex/* tests, run in-process via app.inject()
//   • jsdom  — the Mercury React component tests, with @testing-library/jest-dom
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
        test: {
          name: "jsdom",
          environment: "jsdom",
          globals: true,
          setupFiles: ["./vitest.setup.ts"],
          include: [
            "packages/*/test/**/*.test.{ts,tsx}",
            "apps/*/test/**/*.test.{ts,tsx}",
          ],
        },
      },
    ],
  },
});
