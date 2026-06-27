import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import { resolve } from "node:path";

export default defineConfig({
  plugins: [react()],
  build: {
    target: "es2024",
    lib: {
      entry: resolve(__dirname, "src/index.ts"),
      formats: ["es"],
      fileName: () => "mercury-effector.js",
    },
    rollupOptions: {
      external: ["react", "react-dom", "react/jsx-runtime", "effector", "effector-react", "@mercury/ui"],
    },
  },
});
