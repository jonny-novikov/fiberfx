import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import { resolve } from "node:path";

// Library mode: modern ESM (ES2024), React externalized, single CSS bundle.
export default defineConfig({
  plugins: [react()],
  // `@` is the import root for src — write `@/shared/date/types` instead of
  // `../../shared/date/types`. `$lib` is a compatibility shim for files still
  // mid-migration from the Svelte (bits-ui) port; migrate those to `@` and drop it.
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
      fileName: () => "mercury-ui.js",
    },
    rollupOptions: {
      external: ["react", "react-dom", "react/jsx-runtime"],
      output: { assetFileNames: "mercury-ui.[ext]" },
    },
  },
});
