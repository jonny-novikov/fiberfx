import { defineConfig } from "@playwright/test";

// The codemojex dev server. Override with CODEMOJEX_BASE_URL to point elsewhere.
const BASE_URL = process.env.CODEMOJEX_BASE_URL ?? "http://127.0.0.1:4000";

export default defineConfig({
  testDir: "./tests",
  // One server, shared competitive state in Valkey/Postgres -> run serially for
  // deterministic ordering and clean screenshots.
  fullyParallel: false,
  workers: 1,
  forbidOnly: !!process.env.CI,
  retries: 0,
  // The report surface the Operator opens: an HTML report with the trace viewer,
  // plus a terminal list. `npm run report` opens it.
  reporter: [["html", { open: "never" }], ["list"]],
  use: {
    baseURL: BASE_URL,
    // Every test captures a screenshot, a full trace, and video — all attached to
    // the HTML report so each story's visual + step state is inspectable.
    screenshot: "on",
    trace: "on",
    video: "on",
    // Telegram Mini App portrait viewport.
    viewport: { width: 420, height: 860 },
  },
  projects: [{ name: "chromium", use: { browserName: "chromium" } }],
  // Self-contained: boot the dev server with echo/.env sourced (mix does not load
  // .env itself). reuseExistingServer means an already-running :4000 is reused, so
  // this is a no-op when the server is up.
  webServer: {
    command:
      "bash -c 'cd /Users/jonny/dev/jonnify/echo/apps/codemojex && set -a && source /Users/jonny/dev/jonnify/echo/.env && set +a && TMPDIR=/tmp MIX_ENV=dev mix phx.server'",
    url: BASE_URL,
    reuseExistingServer: true,
    timeout: 120_000,
  },
});
