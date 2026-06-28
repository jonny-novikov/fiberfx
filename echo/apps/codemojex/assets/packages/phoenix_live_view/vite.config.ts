import { defineConfig } from "vite";
import { resolve } from "node:path";

// Library mode: modern ESM (ES2024), React externalized, single CSS bundle.
export default defineConfig({
  resolve: {
    alias: {
      "@": resolve(__dirname, "src"),
      $lib: resolve(__dirname, "src"),
    },
  },
  build: {
    target: "es2024",
    cssCodeSplit: false,
    lib: {
      entry: resolve(__dirname, "src/index.ts"),
      formats: ["es"],
      fileName: () => "phoenix.js",
    }
  },
});
