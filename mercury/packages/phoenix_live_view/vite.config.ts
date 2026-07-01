import { defineConfig } from "vite";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";

// `LV_VSN` is a BUILD-TIME global: src/live_socket.ts `version()` returns the ambient
// `LV_VSN` (declared in src/global.d.ts so tsc trusts it — but a .d.ts emits no value).
// Upstream phoenix_live_view injects it via esbuild `define` from mix.exs; we mirror that
// from package.json. Without this `define` the bare identifier ships unresolved and
// `liveSocket.version()` throws ReferenceError at runtime.
const { version } = JSON.parse(
  readFileSync(resolve(__dirname, "package.json"), "utf8"),
) as { version: string };

// Library mode: modern ESM (ES2024), React externalized, single CSS bundle.
export default defineConfig({
  define: {
    LV_VSN: JSON.stringify(version),
  },
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
