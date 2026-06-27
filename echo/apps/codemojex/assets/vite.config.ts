import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

// Builds the board as a content-hashed ESM bundle into ../priv/static/board, with a
// vite manifest the edge-deploy script reads. This is the artifact uploaded to
// static.codemoji.games and dynamic-imported by the EdgeReact hook. React is bundled
// (the board owns its runtime); the only outward contract is mount(el, props, bridge).
export default defineConfig({
  plugins: [react()],
  build: {
    outDir: "../priv/static/board",
    emptyOutDir: true,
    manifest: true,
    target: "es2020",
    rollupOptions: {
      input: "react/index.tsx",
      output: {
        format: "es",
        entryFileNames: "board-[hash].js",
        chunkFileNames: "board-[hash].js",
        assetFileNames: "board-[hash][extname]",
      },
    },
  },
});
