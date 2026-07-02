import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import { resolve } from "node:path";

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      "@mercury/ui": resolve(__dirname, "../../packages/mercury-ui/src/index.ts"),
      "@mercury/effector": resolve(__dirname, "../../packages/mercury-effector/src/index.ts"),
      "@mercury/core": resolve(__dirname, "../../packages/mercury-core/src/index.ts"),
      // 11 story files VALUE-import "storybook/test" (mx.8.2 fn() + play helpers);
      // resolve the bare specifier to app-local code — the showcase never runs play.
      "storybook/test": resolve(__dirname, "src/shims/storybook-test.ts"),
    },
  },
});
