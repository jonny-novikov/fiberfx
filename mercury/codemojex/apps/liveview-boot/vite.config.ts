import { defineConfig } from "vite";
import { resolve } from "node:path";

// Library mode: build the LiveView boot to a single ESM module, externalizing the
// phoenix* client packages so the browser import map (CodemojexWeb.Layouts.root)
// supplies exactly ONE shared Socket — the boot stays a thin module, never a bundle.
// The built app.js is copied into echo's committed priv/static/assets by
// mercury/codemojex/apps/game/bin/phoenix-modules-build.sh (the ship-with tier).
export default defineConfig({
  build: {
    target: "es2024",
    lib: {
      entry: resolve(__dirname, "src/app.ts"),
      formats: ["es"],
      fileName: () => "app.js",
    },
    rollupOptions: {
      // Keep @echo/phoenix, @echo/phoenix_live_view and their transitive "phoenix"
      // import as bare specifiers → resolved by the host import map at runtime.
      external: [/^@echo\//, "phoenix"],
    },
  },
});
