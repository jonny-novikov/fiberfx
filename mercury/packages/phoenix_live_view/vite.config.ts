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
      fileName: () => "phoenix_live_view.js",
    },
    rollupOptions: {
      // Externalize phoenix → the single committed phoenix.js, resolved by the host
      // import map. live_socket.ts imports the Socket/Channel types and view.ts a
      // Channel type from "phoenix"; keeping it external guarantees exactly one
      // Socket/Channel class in the browser, never a second inlined copy. morphdom
      // (the only real runtime dep) stays BUNDLED.
      external: ["phoenix"],
    },
  },
});
