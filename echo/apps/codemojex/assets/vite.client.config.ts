import { defineConfig } from "vite";

// Builds the LiveView client (LiveSocket + the EdgeReact hook + app.css) into
// ../priv/static/assets. Run locally and COMMIT the output — the Engine image has no
// JS build step, so the machine serves these via Plug.Static. This bundle carries no
// game code; it only boots the socket and loads the edge game bundle at runtime.
export default defineConfig({
  build: {
    outDir: "../priv/static/assets",
    emptyOutDir: false,
    target: "es2020",
    rollupOptions: {
      input: "js/app.js",
      output: {
        format: "iife",
        entryFileNames: "app.js",
        assetFileNames: "app[extname]",
      },
    },
  },
});
