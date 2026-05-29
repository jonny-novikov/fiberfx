import { defineConfig, devices } from "@playwright/test";

/**
 * Playwright configuration for the jonnify mindmap landing-page e2e suite.
 *
 * The suite targets the local jonnify static server on port 8765. The
 * `webServer` block starts that server via the repo Makefile when no server is
 * already listening, and reuses a running instance otherwise.
 */
export default defineConfig({
  testDir: "./tests",
  // The suite drives one shared dev server and a GPU-light, continuously
  // animated page. Running spec files in parallel launches several heavy
  // pages at once and saturates the CPU, which stalls page loads and actions.
  // Serial execution keeps the suite deterministic on a single machine.
  fullyParallel: false,
  workers: 1,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  reporter: [
    ["list"],
    ["html", { open: "never" }],
    ["json", { outputFile: "test-results/results.json" }],
  ],
  use: {
    baseURL: process.env.E2E_BASE_URL || "http://localhost:8765",
    trace: "on-first-retry",
    screenshot: "only-on-failure",
    video: "retain-on-failure",
  },
  projects: [
    {
      name: "chromium",
      use: { ...devices["Desktop Chrome"] },
    },
  ],
  webServer: {
    command: "make -C ../.. start",
    url: "http://localhost:8765/health",
    reuseExistingServer: true,
    timeout: 60000,
  },
});
