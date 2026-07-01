import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import { fileURLToPath } from "node:url";

// Builds the game island as a content-hashed ESM bundle into codemojex's committed
// priv/static/game (an ABSOLUTE echo path — the source reorg moved this config under
// mercury/, so a relative ../priv no longer resolves), with a vite manifest the
// edge-deploy script reads. This is the artifact uploaded to edge.codemoji.games and
// dynamic-imported by the EdgeReact hook. React is bundled (the game owns its runtime);
// the only outward contract is mount(el, props, bridge).

// Resolve a path relative to this config to an ABSOLUTE one — used for both the `@`
// alias and the entry. Absolute paths are file-resolved regardless of cwd or vite
// `root`, and can never be mistaken for a bare package specifier.
const r = (p: string) => fileURLToPath(new URL(p, import.meta.url));

export default defineConfig({
  plugins: [react()],
  resolve: {
    // `@mercury/effector` resolves from SOURCE (the economy precedent) — the game is a
    // self-contained pnpm workspace (excluded from mercury/'s), so it carries no
    // `@mercury/*` node_modules entry; the alias is the only resolution path. THREE `../`
    // reach mercury/packages (game sits at mercury/codemojex/apps/game).
    alias: {
      "@": r("./src"),
      "@mercury/effector": r("../../../packages/mercury-effector/src/index.ts"),
    },
    // The aliased `channel.ts` lives under mercury/packages while the island's own
    // `model.ts` imports `effector` directly — dedupe forces both to the game's single
    // copy so the Effector graph (sample over shared units) does not split across two
    // physical installs.
    dedupe: ["effector", "effector-react"],
  },
  build: {
    outDir: r("../../../../echo/apps/codemojex/priv/static/game"),
    emptyOutDir: true,
    manifest: true,
    target: "es2024",
    rollupOptions: {
      input: r("./src/index.tsx"),
      output: {
        format: "es",
        entryFileNames: "game-[hash].js",
        chunkFileNames: "game-[hash].js",
        assetFileNames: "game-[hash][extname]",
      },
    },
  },
});
