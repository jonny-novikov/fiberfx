import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import { resolve } from "node:path";

// Library mode: modern ESM (ES2024), React externalized, single CSS bundle.
export default defineConfig({
  plugins: [react()],
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
