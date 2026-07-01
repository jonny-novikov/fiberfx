import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import { resolve } from "node:path";

// Apps run against library SOURCE via aliases, so `pnpm dev` needs no prebuild.
// NOTE: this app lives one level deeper than mercury/apps/* — THREE `../` to
// reach mercury/packages (two would resolve into codemojex/packages). See economy.
export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      "@": resolve(__dirname, "./src"),
      "@mercury/ui": resolve(__dirname, "../../../packages/mercury-ui/src/index.ts"),
      "@mercury/effector": resolve(__dirname, "../../../packages/mercury-effector/src/index.ts"),
    },
  },
  // ruled admin.5-F2 (dev): same-origin base; the proxy forwards the admin read
  // plane to the admin service so the SPA reads the live gated API in dev (PORT 3000).
  server: {
    proxy: Object.fromEntries(
      ["/games", "/rooms", "/players", "/health"].map((p) => [
        p,
        process.env.VITE_ADMIN_PROXY_TARGET ?? "http://localhost:3000",
      ]),
    ),
  },
});
