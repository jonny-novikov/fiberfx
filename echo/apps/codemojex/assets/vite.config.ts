import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import { fileURLToPath } from "node:url";

// Builds the board as a content-hashed ESM bundle into ../priv/static/board, with a
// vite manifest the edge-deploy script reads. This is the artifact uploaded to
// edge.codemoji.games and dynamic-imported by the EdgeReact hook. React is bundled
// (the board owns its runtime); the only outward contract is mount(el, props, bridge).
export default defineConfig({
  plugins: [react()],
  build: {
    outDir: "../priv/static/board",
    emptyOutDir: true,
    manifest: true,
    target: "es2020",
    rollupOptions: {
      // Absolute path, NOT the bare specifier "react/index.tsx": the entry dir is named
      // `react`, which collides with the npm `react` package, so a bare string is resolved
      // as a package subpath (→ "Missing ./index.tsx specifier in react"). fileURLToPath
      // forces file resolution regardless of cwd or vite `root`.
      input: fileURLToPath(new URL("./react/index.tsx", import.meta.url)),
      output: {
        format: "es",
        entryFileNames: "board-[hash].js",
        chunkFileNames: "board-[hash].js",
        assetFileNames: "board-[hash][extname]",
      },
    },
  },
});
