import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import { resolve } from "node:path";

// Apps run against library SOURCE via aliases, so `pnpm dev` needs no prebuild.
// NOTE: this app lives one level deeper than mercury/apps/* — THREE `../` to
// reach mercury/packages (two would resolve into codemojex-node/packages).
export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      "@mercury/ui": resolve(__dirname, "../../../packages/mercury-ui/src/index.ts"),
      "@mercury/effector": resolve(__dirname, "../../../packages/mercury-effector/src/index.ts"),
    },
  },
});
