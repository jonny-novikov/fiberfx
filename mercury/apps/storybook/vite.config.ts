import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import { resolve } from "node:path";

// The Storybook host runs against library SOURCE via aliases (the same block as
// the apps), so a package edit is live in a story with no prebuild.
// `@storybook/react-vite` auto-merges this config.
export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      "@mercury/ui": resolve(__dirname, "../../packages/mercury-ui/src/index.ts"),
      "@mercury/effector": resolve(__dirname, "../../packages/mercury-effector/src/index.ts"),
      "@mercury/core": resolve(__dirname, "../../packages/mercury-core/src/index.ts"),
    },
  },
});
